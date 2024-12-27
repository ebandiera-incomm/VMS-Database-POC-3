CREATE OR REPLACE PROCEDURE VMSCMS.SP_CREATE_ISSUANCE_GL_DATA (
   prm_instcode                NUMBER,
   prm_issuance_date           DATE,
   prm_tran_code               VARCHAR2,
   prm_tran_mode               VARCHAR2,
   prm_tran_type               VARCHAR2,
   prm_delv_chnl               VARCHAR2,
   prm_card_no                 VARCHAR2,
   prm_prod_code               VARCHAR2,
   prm_prod_cattype            VARCHAR2,
   prm_card_gl_code            VARCHAR2,
   prm_card_subgl_code         VARCHAR2,
   prm_card_amount             NUMBER,
   prm_lupd_user               NUMBER,
   prm_errmsg            OUT   VARCHAR2
)
IS
   v_errmsg               VARCHAR2 (500);
   v_dr_cr_flag           cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_output_type          cms_transaction_mast.ctm_output_type%TYPE;
   v_func_code            cms_func_mast.cfm_func_code%TYPE;
   v_fee_code             cms_fee_mast.cfm_fee_code%TYPE;
   v_fee_crgl_catg        cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_fee_crgl_code        cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_fee_crsubgl_code     cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_fee_cracct_no        cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_drgl_catg        cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_fee_drgl_code        cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_fee_drsubgl_code     cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_fee_dracct_no        cms_prodcattype_fees.cpf_dracct_no%TYPE;
   v_servicetax_percent   cms_inst_param.cip_param_value%TYPE;
   v_cess_percent         cms_inst_param.cip_param_value%TYPE;
   v_servicetax_amount    NUMBER;
   v_cess_amount          NUMBER;
   v_st_calc_flag         cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_cess_calc_flag       cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_st_cracct_no         cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_st_dracct_no         cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_cess_cracct_no       cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_cess_dracct_no       cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   v_waiv_percnt          cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_err_waiv             VARCHAR2 (300);
   v_log_actual_fee       NUMBER;
   v_log_waiver_amt       NUMBER;
   v_error                VARCHAR2 (500);
   v_fee_amt              NUMBER;
   v_total_fee            NUMBER;
   v_total_amt            NUMBER;
   v_resp_cde             VARCHAR2 (10);
   v_base_curr            VARCHAR2 (5);
   v_savepoint            NUMBER                                         := 0;
   v_gl_upd_flag          VARCHAR2 (1);
   v_gl_err_msg           VARCHAR2 (300);
   v_fee_attach_type      VARCHAR2 (1);
   exp_reject_record      EXCEPTION;
   v_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
   v_feeamnt_type         cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_per_fees             cms_fee_mast.cfm_per_fees%TYPE;
   v_flat_fees            cms_fee_mast.cfm_fee_amt%TYPE;
   v_clawback             cms_fee_mast.cfm_clawback_flag%TYPE;
   v_fee_plan             cms_fee_feeplan.cff_fee_plan%TYPE;
   v_freetxn_exceed       VARCHAR2 (1);
   v_duration             VARCHAR2 (20);
   v_fee_opening_bal      NUMBER;
   v_tran_desc            cms_transaction_mast.ctm_tran_desc%TYPE;
   v_feeattach_type       VARCHAR2 (2);
   v_acct_number          cms_appl_pan.cap_acct_no%TYPE;
   v_prod_code            cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype         cms_prod_cattype.cpc_card_type%TYPE;
   v_applpan_cardstat     cms_appl_pan.cap_card_stat%TYPE;
   v_cam_type_code        cms_acct_mast.cam_type_code%TYPE;
   v_timestamp            TIMESTAMP;
   v_cap_acct_id          cms_appl_pan.cap_acct_id%TYPE;
   v_cam_acct_bal         cms_acct_mast.cam_acct_bal%TYPE;
   v_cam_ledger_bal       cms_acct_mast.cam_ledger_bal%TYPE;
   v_fee_desc             cms_fee_mast.cfm_fee_desc%TYPE;
BEGIN
   prm_errmsg := 'OK';
   v_errmsg := 'OK';

   BEGIN
      v_hash_pan := gethash (prm_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      v_encr_pan := fn_emaps_main (prm_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no,
             cap_acct_id
        INTO v_prod_code, v_prod_cattype, v_applpan_cardstat, v_acct_number,
             v_cap_acct_id
        FROM cms_appl_pan
       WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Invalid Card number ' || v_hash_pan;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while selecting card number ' || v_hash_pan;
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cam_type_code, cam_acct_bal, cam_ledger_bal
        INTO v_cam_type_code, v_cam_acct_bal, v_cam_ledger_bal
        FROM cms_acct_mast
       WHERE cam_inst_code = prm_instcode AND cam_acct_id = v_cap_acct_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '14';
         v_errmsg := 'Invalid Card details';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting data from acct Master for card number '
            || fn_mask (prm_card_no, 'X', 7, 6)
            || ' '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT ctm_credit_debit_flag, ctm_output_type, ctm_tran_desc
        INTO v_dr_cr_flag, v_output_type, v_tran_desc
        FROM cms_transaction_mast
       WHERE ctm_inst_code = prm_instcode
         AND ctm_tran_code = prm_tran_code
         AND ctm_delivery_channel = prm_delv_chnl;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Transflag  not defined for txn code ' || prm_tran_code;
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cip_param_value
        INTO v_servicetax_percent
        FROM cms_inst_param
       WHERE cip_inst_code = prm_instcode AND cip_param_key = 'SERVICETAX';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Service Tax is  not defined in the system';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while selecting service tax from system ';
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cip_param_value
        INTO v_cess_percent
        FROM cms_inst_param
       WHERE cip_inst_code = prm_instcode AND cip_param_key = 'CESS';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Cess is not defined in the system';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while selecting cess from system ';
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cip_param_value
        INTO v_base_curr
        FROM cms_inst_param
       WHERE cip_inst_code = prm_instcode AND cip_param_key = 'CURRENCY';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Currency  is not defined in the system';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while selecting cess from system ';
         RAISE exp_reject_record;
   END;

   IF prm_card_amount > 0
   THEN
      sp_tran_fees_cmsauth (prm_instcode,
                            prm_card_no,
                            prm_delv_chnl,
                            prm_tran_type,
                            prm_tran_mode,
                            prm_tran_code,
                            v_base_curr,
                            NULL,
                            NULL,
                            prm_card_amount,
                            prm_issuance_date,
                            NULL,
                            NULL,
                            v_resp_cde,
                            0200,
                            00,
                            NULL,
                            v_fee_amt,
                            v_error,
                            v_fee_code,
                            v_fee_crgl_catg,
                            v_fee_crgl_code,
                            v_fee_crsubgl_code,
                            v_fee_cracct_no,
                            v_fee_drgl_catg,
                            v_fee_drgl_code,
                            v_fee_drsubgl_code,
                            v_fee_dracct_no,
                            v_st_calc_flag,
                            v_cess_calc_flag,
                            v_st_cracct_no,
                            v_st_dracct_no,
                            v_cess_cracct_no,
                            v_cess_dracct_no,
                            v_feeamnt_type,
                            v_clawback,
                            v_fee_plan,
                            v_per_fees,
                            v_flat_fees,
                            v_freetxn_exceed,
                            v_duration,
                            v_feeattach_type,
                            v_fee_desc
                           );

      IF v_error <> 'OK'
      THEN
         v_errmsg := v_error;
         RAISE exp_reject_record;
      END IF;

      sp_calculate_waiver (prm_instcode,
                           prm_card_no,
                           '000',
                           prm_prod_code,
                           prm_prod_cattype,
                           v_fee_code,
                           v_fee_plan,
                           prm_issuance_date,
                           v_waiv_percnt,
                           v_err_waiv
                          );

      IF v_err_waiv <> 'OK'
      THEN
         v_errmsg := v_err_waiv;
         RAISE exp_reject_record;
      END IF;

      v_log_actual_fee := v_fee_amt;
      v_fee_amt := ROUND (v_fee_amt - ((v_fee_amt * v_waiv_percnt) / 100), 2);
      v_log_waiver_amt := v_log_actual_fee - v_fee_amt;

      IF v_st_calc_flag = 1
      THEN
         v_servicetax_amount := (v_fee_amt * v_servicetax_percent) / 100;
      ELSE
         v_servicetax_amount := 0;
      END IF;

      IF v_cess_calc_flag = 1
      THEN
         v_cess_amount := (v_servicetax_amount * v_cess_percent) / 100;
      ELSE
         v_cess_amount := 0;
      END IF;

      v_total_fee :=
                    ROUND (v_fee_amt + v_servicetax_amount + v_cess_amount, 2);
      v_total_amt := prm_card_amount - v_total_fee;

      IF v_total_amt < 0
      THEN
         v_errmsg :=
               'Insufficient amount '
            || ' The initial  top up amount is ( '
            || prm_card_amount
            || '- fee amount  '
            || v_total_fee
            || ' ) '
            || ' = '
            || v_total_amt;
         RAISE exp_reject_record;
      END IF;

      BEGIN
         sp_update_transaction_account (prm_instcode,
                                        prm_issuance_date,
                                        prm_prod_code,
                                        prm_prod_cattype,
                                        prm_card_amount,
                                        v_func_code,
                                        prm_tran_code,
                                        v_dr_cr_flag,
                                        'Issuance',
                                        NULL,
                                        prm_delv_chnl,
                                        prm_tran_mode,
                                        prm_card_no,
                                        v_fee_code,
                                        v_fee_amt,
                                        v_fee_cracct_no,
                                        v_fee_dracct_no,
                                        v_st_calc_flag,
                                        v_cess_calc_flag,
                                        v_servicetax_amount,
                                        v_st_cracct_no,
                                        v_st_dracct_no,
                                        v_cess_amount,
                                        v_cess_cracct_no,
                                        v_cess_dracct_no,
                                        prm_lupd_user,
                                        v_resp_cde,
                                        v_errmsg
                                       );

         IF (v_resp_cde <> '1' OR v_errmsg <> 'OK')
         THEN
            RAISE exp_reject_record;
         END IF;
      END;

      BEGIN
         UPDATE cms_appl_pan
            SET cap_firsttime_topup = 'Y'
          WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while updating appl_pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      v_timestamp := SYSTIMESTAMP;

      IF v_dr_cr_flag <> 'NA'
      THEN
         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_opening_bal, csl_trans_amount,
                         csl_trans_type, csl_trans_date,
                         csl_closing_balance, csl_trans_narrration,
                         csl_pan_no_encr, csl_acct_type, csl_time_stamp,
                         csl_prod_code,csl_card_type
                        )
                 VALUES (v_hash_pan, 0, prm_card_amount,
                         'CR', prm_issuance_date,
                         prm_card_amount, 'Issuance load',
                         v_encr_pan, v_cam_type_code, v_timestamp,
                         v_prod_code,v_prod_cattype
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Problem while inserting into statement log for tran amt '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      IF v_total_fee <> 0 OR v_freetxn_exceed = 'N'
      THEN
         BEGIN
            SELECT DECODE (v_dr_cr_flag, 'CR', 0 + prm_card_amount, 'NA', 0)
              INTO v_fee_opening_bal
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '12';
               v_errmsg :=
                     'Error while selecting data from card Master for card number '
                  || prm_card_no;
               RAISE exp_reject_record;
         END;

         IF v_freetxn_exceed = 'N'
         THEN
            BEGIN
               INSERT INTO cms_statements_log
                           (csl_inst_code, csl_pan_no, csl_opening_bal,
                            csl_trans_amount, csl_trans_type,
                            csl_trans_date,
                            csl_closing_balance, csl_trans_narrration,
                            csl_pan_no_encr, csl_acct_type, csl_time_stamp,
                            csl_prod_code,csl_card_type
                           )
                    VALUES (prm_instcode, v_hash_pan, v_fee_opening_bal,
                            v_total_fee, 'DR',
                            prm_issuance_date,
                            v_fee_opening_bal - v_total_fee, v_fee_desc,
                            v_encr_pan, v_cam_type_code, v_timestamp,
                            v_prod_code,v_prod_cattype
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem while inserting into statement log for tran fee '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSE
            BEGIN
               IF v_feeamnt_type = 'A'
               THEN
                  v_flat_fees :=
                     ROUND (  v_flat_fees
                            - ((v_flat_fees * v_waiv_percnt) / 100),
                            2
                           );
                  v_per_fees :=
                     ROUND (v_per_fees - ((v_per_fees * v_waiv_percnt) / 100),
                            2
                           );

                  INSERT INTO cms_statements_log
                              (csl_inst_code, csl_pan_no, csl_opening_bal,
                               csl_trans_amount, csl_trans_type,
                               csl_trans_date,
                               csl_closing_balance,
                               csl_trans_narrration,
                               csl_pan_no_encr, csl_acct_type,
                               csl_time_stamp, csl_prod_code,csl_card_type
                              )
                       VALUES (prm_instcode, v_hash_pan, v_fee_opening_bal,
                               v_flat_fees, 'DR',
                               prm_issuance_date,
                               v_fee_opening_bal - v_flat_fees,
                               'Fixed Fee debited for ' || v_fee_desc,
                               v_encr_pan, v_cam_type_code,
                               v_timestamp, v_prod_code,v_prod_cattype
                              );

                  INSERT INTO cms_statements_log
                              (csl_inst_code, csl_pan_no, csl_opening_bal,
                               csl_trans_amount, csl_trans_type,
                               csl_trans_date,
                               csl_closing_balance,
                               csl_trans_narrration,
                               csl_pan_no_encr, csl_acct_type,
                               csl_time_stamp, csl_prod_code,csl_card_type
                              )
                       VALUES (prm_instcode, v_hash_pan, prm_card_amount,
                               v_per_fees, 'DR',
                               prm_issuance_date,
                               v_fee_opening_bal - v_per_fees,
                               'Percentage Fee debited for ' || v_fee_desc,
                               v_encr_pan, v_cam_type_code,
                               v_timestamp, v_prod_code,v_prod_cattype
                              );
               ELSE
                  INSERT INTO cms_statements_log
                              (csl_inst_code, csl_pan_no, csl_opening_bal,
                               csl_trans_amount, csl_trans_type,
                               csl_trans_date,
                               csl_closing_balance, csl_trans_narrration,
                               csl_pan_no_encr, csl_acct_type,
                               csl_time_stamp, csl_prod_code,csl_card_type
                              )
                       VALUES (prm_instcode, v_hash_pan, v_fee_opening_bal,
                               v_total_fee, 'DR',
                               prm_issuance_date,
                               prm_card_amount - v_total_fee, v_fee_desc,
                               v_encr_pan, v_cam_type_code,
                               v_timestamp, v_prod_code,v_prod_cattype
                              );
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem while inserting into statement log for tran fee '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;
      END IF;

      SAVEPOINT v_savepoint;

      IF v_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat,
                   cap_acct_no
              INTO v_prod_code, v_prod_cattype, v_applpan_cardstat,
                   v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         BEGIN
            SELECT     cam_type_code
                  INTO v_cam_type_code
                  FROM cms_acct_mast
                 WHERE cam_inst_code = prm_instcode
                   AND cam_acct_id = v_cap_acct_id
            FOR UPDATE NOWAIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag
              INTO v_dr_cr_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = prm_tran_code
               AND ctm_delivery_channel = prm_delv_chnl
               AND ctm_inst_code = prm_instcode;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type,
                      txn_mode, txn_status, response_code,
                      business_date,
                      business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type,
                      bank_code,
                      total_amount,
                      rule_indicator, rulegroupid, mccode, currencycode,
                      addcharge, productid, categoryid, tips,
                      decline_ruleid, atm_name_location, auth_id,
                      trans_desc,
                      amount,
                      preauthamount, partialamount, mccodegroupid,
                      currencycodegroupid, transcodegroupid, rules,
                      preauth_date, gl_upd_flag, instcode, feecode,
                      feeattachtype, tranfee_amt,
                      servicetax_amt, cess_amt,
                      cr_dr_flag, customer_card_no_encr, response_id,
                      customer_acct_no, cardstatus, acct_type,
                      time_stamp, acct_balance,
                      ledger_balance, error_msg
                     )
              VALUES ('210', 'Issuance', prm_delv_chnl, NULL,
                      prm_issuance_date, prm_tran_code, prm_tran_type,
                      prm_tran_mode, 'C', '00',
                      TO_CHAR (prm_issuance_date, 'YYYYMMDD'),
                      TO_CHAR (prm_issuance_date, 'HH:MI'), v_hash_pan,
                      NULL, NULL, NULL,
                      NULL,
                      TRIM (TO_CHAR (NVL (v_total_amt, 0),
                                     '99999999999999990.99'
                                    )
                           ),
                      NULL, NULL, NULL, v_base_curr,
                      NULL, prm_prod_code, prm_prod_cattype, 0,
                      NULL, NULL, NULL,
                      v_tran_desc,
                      TRIM (TO_CHAR (NVL (prm_card_amount, 0),
                                     '99999999999999990.99'
                                    )
                           ),
                      '0.00', '0.00', NULL,
                      NULL, NULL, NULL,
                      NULL, v_gl_upd_flag, prm_instcode, v_fee_code,
                      v_feeattach_type, NVL (v_fee_amt, 0),
                      NVL (v_servicetax_amount, 0), NVL (v_cess_amount, 0),
                      v_dr_cr_flag, v_encr_pan, v_resp_cde,
                      v_acct_number, v_applpan_cardstat, v_cam_type_code,
                      NVL (v_timestamp, SYSTIMESTAMP), v_cam_acct_bal,
                      v_cam_ledger_bal, v_errmsg
                     );
      END;
   ELSE
      BEGIN
         UPDATE cms_appl_pan
            SET cap_firsttime_topup = 'N'
          WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while updating appl_pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;
EXCEPTION
   WHEN exp_reject_record
   THEN
      prm_errmsg := v_errmsg;
END;

/

show error