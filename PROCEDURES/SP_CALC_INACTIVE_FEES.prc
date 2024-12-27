CREATE OR REPLACE PROCEDURE VMSCMS.SP_CALC_INACTIVE_FEES (
   p_instcode   IN       NUMBER,
   p_lupduser   IN       NUMBER,
   p_errmsg     OUT      VARCHAR2
)
AS

/* ***********************************************************************
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
	
********************************************************************** */	



 v_debit_amnt         NUMBER;
   v_fee_amount         cms_fee_mast.cfm_fee_amt%TYPE;
   v_err_msg            VARCHAR2 (900)                                := 'OK';
   exp_reject_record    EXCEPTION;
   v_inactive_cardcnt   NUMBER;
   v_waivamt            NUMBER;
   v_cpw_waiv_prcnt     NUMBER;
   v_feeamt             NUMBER;
   v_upd_rec_cnt        NUMBER                                           := 0;
   v_rrn1               NUMBER (10)                                 DEFAULT 0;
   v_rrn2               VARCHAR2 (15);
   v_cam_type_code      cms_acct_mast.cam_type_code%TYPE;
   v_timestamp          TIMESTAMP;
   v_dr_cr_flag         cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_card_cnt           NUMBER;
   v_prdcatg_cnt        NUMBER;

   CURSOR cardfee
   IS
      SELECT cfm_fee_code, cfm_fee_amt, cce_pan_code, cce_pan_code_encr,
             cce_crgl_catg, cce_crgl_code, cce_crsubgl_code, cce_cracct_no,
             cce_drgl_catg, cce_drgl_code, cce_drsubgl_code, cce_dracct_no,
             cff_fee_plan, cap_active_date, cap_card_stat, cfm_feecap_flag,
             cap_acct_no, cap_prod_code, cap_card_type, cfm_fee_desc
        FROM cms_fee_mast,
             cms_card_excpfee,
             cms_fee_types,
             cms_fee_feeplan,
             cms_appl_pan
       WHERE cfm_inst_code = p_instcode
         AND cfm_inst_code = cce_inst_code
         AND cce_fee_plan = cff_fee_plan
         AND cff_fee_code = cfm_fee_code
         AND (   (    cce_valid_to IS NOT NULL
                  AND (TRUNC (SYSDATE) BETWEEN cce_valid_from AND cce_valid_to
                      )
                 )
              OR (cce_valid_to IS NULL AND TRUNC (SYSDATE) >= cce_valid_from)
             )
         AND cfm_feetype_code = cft_feetype_code
         AND cft_inst_code = cfm_inst_code
         AND cap_card_stat = '8'
         AND cap_expry_date > SYSDATE
         AND cft_fee_freq = 'M'
         AND cft_fee_type = 'I'
         AND cap_pan_code = cce_pan_code
         AND ((TRUNC (cap_inactive_feecalc_date) <> TRUNC (SYSDATE))
              OR (cap_inactive_feecalc_date IS NULL) );

   CURSOR prodcatgfee
   IS
      SELECT cfm_fee_code, cfm_fee_amt, cpf_prod_code, cpf_card_type,
             cpf_crgl_catg, cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no,
             cpf_drgl_catg, cpf_drgl_code, cpf_drsubgl_code, cpf_dracct_no,
             cff_fee_plan, cap_pan_code, cap_pan_code_encr, cap_active_date,
             cap_card_stat, cfm_feecap_flag, cap_acct_no, cap_prod_code,
             cap_card_type, cfm_fee_desc
        FROM cms_fee_mast,
             cms_prodcattype_fees,
             cms_fee_types,
             cms_fee_feeplan,
             cms_appl_pan
       WHERE cfm_inst_code = p_instcode
         AND cfm_inst_code = cpf_inst_code
         AND cff_fee_plan = cpf_fee_plan
         AND cff_fee_code = cfm_fee_code
         AND (   (    cpf_valid_to IS NOT NULL
                  AND (TRUNC (SYSDATE) BETWEEN cpf_valid_from AND cpf_valid_to
                      )
                 )
              OR (cpf_valid_to IS NULL AND TRUNC (SYSDATE) >= cpf_valid_from)
             )
         AND cfm_feetype_code = cft_feetype_code
         AND cft_inst_code = cfm_inst_code
         AND cap_prod_code = cpf_prod_code
         AND cap_card_type = cpf_card_type
         AND cap_inst_code = cfm_inst_code
         AND cap_card_stat = '8'
         AND cap_expry_date > SYSDATE
         AND cft_fee_freq = 'M'
         AND cft_fee_type = 'I'
         AND (   (TRUNC (cap_inactive_feecalc_date) <> TRUNC (SYSDATE))
              OR (cap_inactive_feecalc_date IS NULL)
             );

   CURSOR prodfee
   IS
      SELECT cfm_fee_code, cfm_fee_amt, cpf_prod_code, cpf_crgl_catg,
             cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no, cpf_drgl_catg,
             cpf_drgl_code, cpf_drsubgl_code, cpf_dracct_no, cff_fee_plan,
             cap_pan_code, cap_pan_code_encr, cap_active_date, cap_card_stat,
             cfm_feecap_flag, cap_acct_no, cap_card_type, cap_prod_code,
             cfm_fee_desc
        FROM cms_fee_mast,
             cms_prod_fees,
             cms_fee_types,
             cms_fee_feeplan,
             cms_appl_pan
       WHERE cfm_inst_code = p_instcode
         AND cfm_inst_code = cpf_inst_code
         AND cff_fee_plan = cpf_fee_plan
         AND cff_fee_code = cfm_fee_code
         AND (   (    cpf_valid_to IS NOT NULL
                  AND (TRUNC (SYSDATE) BETWEEN cpf_valid_from AND cpf_valid_to
                      )
                 )
              OR (cpf_valid_to IS NULL AND TRUNC (SYSDATE) >= cpf_valid_from)
             )
         AND cfm_feetype_code = cft_feetype_code
         AND cft_inst_code = cfm_inst_code
         AND cap_prod_code = cpf_prod_code
         AND cap_inst_code = cpf_inst_code
         AND cap_card_stat = '8'
         AND cap_expry_date > SYSDATE
         AND cft_fee_freq = 'M'
         AND cft_fee_type = 'I'
         AND (   (TRUNC (cap_inactive_feecalc_date) <> TRUNC (SYSDATE))
              OR (cap_inactive_feecalc_date IS NULL)
             );

   PROCEDURE lp_transaction_log (
      p_instcode           IN   NUMBER,
      p_hashpan            IN   VARCHAR2,
      p_encrpan            IN   VARCHAR2,
      p_rrn                IN   VARCHAR2,
      p_delivery_channel   IN   VARCHAR2,
      p_business_date      IN   VARCHAR2,
      p_business_time      IN   VARCHAR2,
      p_acct_number        IN   VARCHAR2,
      p_acct_bal           IN   VARCHAR2,
      p_ledger_bal         IN   VARCHAR2,
      p_fee_amnt           IN   VARCHAR2,
      p_auth_id            IN   VARCHAR2,
      p_tran_desc          IN   VARCHAR2,
      p_tran_code          IN   VARCHAR2,
      p_response_id        IN   VARCHAR2,
      p_card_curr          IN   VARCHAR2,
      p_waiv_amnt          IN   NUMBER,
      p_fee_code           IN   VARCHAR2,
      p_fee_plan           IN   VARCHAR2,
      p_cr_acctno          IN   VARCHAR2,
      p_dr_acctno          IN   VARCHAR2,
      p_attach_type        IN   VARCHAR2,
      p_card_stat          IN   VARCHAR2,
      p_cam_type_code      IN   VARCHAR2,
      p_timestamp          IN   TIMESTAMP,
      p_prod_code          IN   VARCHAR2,
      p_prod_cattype       IN   VARCHAR2,
      p_dr_cr_flag         IN   VARCHAR2,
      p_err_msg            IN   VARCHAR2
   )
   AS
   BEGIN
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time,
                      txn_code, txn_type,
                      txn_status,
                      response_code,
                      business_date, business_time, customer_card_no,
                      bank_code,
                      total_amount,
                      auth_id, trans_desc, amount, instcode,
                      customer_card_no_encr, customer_acct_no, acct_balance,
                      ledger_balance, response_id, txn_mode, currencycode,
                      tranfee_amt,
                      feeattachtype, fee_plan, feecode, tranfee_cr_acctno,
                      tranfee_dr_acctno, cardstatus, acct_type,
                      time_stamp, productid, categoryid,
                      cr_dr_flag, error_msg
                     )
              VALUES ('0200', p_rrn, p_delivery_channel, SYSDATE,
                      p_tran_code, '1',
                      DECODE (p_response_id, '1', 'C', 'F'),
                      DECODE (p_response_id, '1', '00', '89'),
                      p_business_date, p_business_time, p_hashpan,
                      p_instcode,
                      TRIM (TO_CHAR (NVL (p_fee_amnt, 0)
                                     - NVL (p_waiv_amnt, 0),
                                     '99999999999999990.99'
                                    )
                           ),
                      p_auth_id, p_tran_desc, '0.00', p_instcode,
                      p_encrpan, p_acct_number, NVL (p_acct_bal, 0),
                      NVL (p_ledger_bal, 0), p_response_id, 0, p_card_curr,
                      TRIM (TO_CHAR (NVL (p_fee_amnt, 0)
                                     - NVL (p_waiv_amnt, 0),
                                     '99999999999999990.99'
                                    )
                           ),
                      p_attach_type, p_fee_plan, p_fee_code, p_cr_acctno,
                      p_dr_acctno, p_card_stat, p_cam_type_code,
                      p_timestamp, p_prod_code, p_prod_cattype,
                      p_dr_cr_flag, p_err_msg
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while insertg in transactionlog'
               || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no, ctd_txn_curr,
                      ctd_fee_amount, ctd_waiver_amount, ctd_bill_curr,
                      ctd_process_flag,
                      ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_customer_card_no_encr,
                      ctd_cust_acct_number
                     )
              VALUES (p_delivery_channel, p_tran_code, '1',
                      '0200', 0, p_business_date,
                      p_business_time, p_hashpan, p_card_curr,
                      p_fee_amnt, p_waiv_amnt, p_card_curr,
                      DECODE (p_response_id, '1', 'Y', 'F'),
                      DECODE (p_response_id, '1', 'Successful', p_errmsg),
                      p_rrn, p_instcode, p_encrpan,
                      p_acct_number
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while insertg in cms_transaction_log_dtl'
               || SUBSTR (SQLERRM, 1, 200);
      END;
   END lp_transaction_log;

   PROCEDURE lp_fee_update_log (
      p_instcode       IN       NUMBER,
      p_hashpan        IN       VARCHAR2,
      p_encrpan        IN       VARCHAR2,
      p_fee_code       IN       NUMBER,
      p_fee_amnt       IN       NUMBER,
      p_fee_plan       IN       VARCHAR2,
      p_cr_glcatg      IN       VARCHAR2,
      p_cr_glcode      IN       VARCHAR2,
      p_cr_subglcode   IN       VARCHAR2,
      p_cr_acctno      IN       VARCHAR2,
      p_dr_glcatg      IN       VARCHAR2,
      p_dr_glcode      IN       VARCHAR2,
      p_dr_subglcode   IN       VARCHAR2,
      p_dr_acctno      IN       VARCHAR2,
      p_waiv_amnt      IN       NUMBER,
      p_attach_type    IN       VARCHAR2,
      p_card_stat      IN       VARCHAR2,
      p_acct_no        IN       VARCHAR2,
      p_prod_code      IN       VARCHAR2,
      p_card_type      IN       NUMBER,
      p_cfm_fee_desc   IN       VARCHAR2,
      p_errmsg         OUT      VARCHAR2
   )
   AS
      v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
      v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
      v_acct_number        cms_appl_pan.cap_acct_no%TYPE;
      v_auth_id            transactionlog.auth_id%TYPE;
      v_business_date      VARCHAR2 (10);
      v_business_time      VARCHAR2 (10);
      v_txn_mode           cms_func_mast.cfm_txn_mode%TYPE        DEFAULT '0';
      v_delivery_channel   cms_func_mast.cfm_delivery_channel%TYPE
                                                                 DEFAULT '05';
      v_txn_code           cms_func_mast.cfm_txn_code%TYPE       DEFAULT '17';
      v_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      v_narration          cms_statements_log.csl_trans_narrration%TYPE;
      v_pan_code           VARCHAR2 (19);
      v_fee_amnt           cms_acct_mast.cam_acct_bal%TYPE;
      v_bin_curr            CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
      v_card_curr          transactionlog.currencycode%TYPE;

   BEGIN
      p_errmsg := 'OK';

      BEGIN
         SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'), TO_CHAR (SYSDATE, 'HH24MISS')
           INTO v_business_date, v_business_time
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                     'Error while selecting date' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      v_rrn1 := v_rrn1 + 1;
      v_rrn2 := 'IF' || v_business_date || v_rrn1;

      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no, cam_type_code
               INTO v_acct_bal, v_ledger_bal, v_acct_number, v_cam_type_code
               FROM cms_acct_mast
              WHERE cam_inst_code = p_instcode AND cam_acct_no = p_acct_no
         FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_err_msg := 'Account Details Not Found in Master';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while selecting data from Account Master'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      v_fee_amnt := p_fee_amnt - p_waiv_amnt;
      v_pan_code := fn_dmaps_main (p_encrpan);


      BEGIN
--         SELECT cip_param_value
--           INTO bin_curr
--           FROM cms_inst_param
--          WHERE cip_inst_code = p_instcode AND cip_param_key = 'CURRENCY';

         SELECT TRIM (cbp_param_value) 
	 INTO v_bin_curr 
	 FROM cms_bin_param 
	 WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
	 AND cbp_profile_code = (select  cpc_profile_code from 
	 cms_prod_cattype where cpc_prod_code = p_prod_code and
         cpc_card_type = p_card_type  and cpc_inst_code=p_instcode);	

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg := 'No Currency Found for the profile';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error in selecting BIN currency '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT ctm_tran_desc, ctm_credit_debit_flag
           INTO v_tran_desc, v_dr_cr_flag
           FROM cms_transaction_mast
          WHERE ctm_inst_code = p_instcode
            AND ctm_tran_code = v_txn_code
            AND ctm_delivery_channel = v_delivery_channel;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while selecting narration and CR/DR flag'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         sp_convert_curr (p_instcode,
                          v_bin_curr,
                          v_pan_code,
                          v_fee_amnt,
                          SYSDATE,
                          v_fee_amnt,
                          v_card_curr,
                          p_errmsg,
                          p_prod_code,
                          p_card_type
                         );

         IF p_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_errmsg :=
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF v_acct_bal > 0
      THEN
         IF (v_acct_bal > v_fee_amnt)
         THEN
            v_debit_amnt := v_fee_amnt;
         ELSE
            v_debit_amnt := v_acct_bal;
         END IF;
      ELSE
         v_debit_amnt := 0;
      END IF;

      IF v_debit_amnt > 0
      THEN
         BEGIN
            UPDATE cms_acct_mast
               SET cam_acct_bal = cam_acct_bal - v_debit_amnt,
                   cam_ledger_bal = cam_ledger_bal - v_debit_amnt
             WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_instcode;

            IF SQL%ROWCOUNT = 0
            THEN
               v_err_msg :=
                   'Error while updating balance' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_err_msg :=
                   'Error while updating balance' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO v_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         v_pan_code := fn_dmaps_main (p_encrpan);

         BEGIN
            v_narration := p_cfm_fee_desc;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting narration'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         v_timestamp := SYSTIMESTAMP;

         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_acct_no, csl_opening_bal,
                         csl_trans_amount, csl_trans_type, csl_trans_date,
                         csl_closing_balance, csl_trans_narrration,
                         csl_pan_no_encr, csl_rrn, csl_auth_id,
                         csl_business_date, csl_business_time, txn_fee_flag,
                         csl_delivery_channel, csl_inst_code, csl_txn_code,
                         csl_ins_date, csl_ins_user,
                         csl_panno_last4digit,
                         csl_acct_type, csl_time_stamp, csl_prod_code,csl_card_type
                        )
                 VALUES (p_hashpan, v_acct_number, v_ledger_bal,
                         v_debit_amnt, 'DR', SYSDATE,
                         v_ledger_bal - v_debit_amnt, v_narration,
                         p_encrpan, v_rrn2, v_auth_id,
                         v_business_date, v_business_time, 'Y',
                         v_delivery_channel, p_instcode, v_txn_code,
                         SYSDATE, 1,
                         (SUBSTR (v_pan_code,
                                  LENGTH (v_pan_code) - 3,
                                  LENGTH (v_pan_code)
                                 )
                         ),
                         v_cam_type_code, v_timestamp, p_prod_code,p_card_type
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error creating entry in statement log '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            sp_ins_eodupdate_acct_cmsauth (v_rrn2,
                                           NULL,
                                           v_delivery_channel,
                                           v_txn_code,
                                           v_txn_mode,
                                           SYSDATE,
                                           v_pan_code,
                                           p_cr_acctno,
                                           v_debit_amnt,
                                           'C',
                                           p_instcode,
                                           p_errmsg
                                          );

            IF p_errmsg <> 'OK'
            THEN
               p_errmsg :=
                     'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH'
                  || p_errmsg;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         v_upd_rec_cnt := v_upd_rec_cnt + 1;
      END IF;

      BEGIN
         INSERT INTO cms_inactivity_fee_det
                     (cfd_inst_code, cfd_pan_code, cfd_fee_code,
                      cfd_fee_amnt, cfd_dedited_amnt, cfd_ins_user,
                      cfd_ins_date, cfd_lupd_user, cfd_lupd_date,
                      cfd_process_msg, cfd_fee_plan
                     )
              VALUES (p_instcode, p_hashpan, p_fee_code,
                      p_fee_amnt, v_debit_amnt, p_lupduser,
                      SYSDATE, p_lupduser, SYSDATE,
                      DECODE (v_err_msg, 'OK', 'SUCCESS'), p_fee_plan
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while inserting Fee details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      lp_transaction_log (p_instcode,
                          p_hashpan,
                          p_encrpan,
                          v_rrn2,
                          v_delivery_channel,
                          v_business_date,
                          v_business_time,
                          v_acct_number,
                          v_acct_bal - v_debit_amnt,
                          v_ledger_bal - v_debit_amnt,
                          p_fee_amnt,
                          v_auth_id,
                          v_tran_desc,
                          v_txn_code,
                          1,
                          v_card_curr,
                          p_waiv_amnt,
                          p_fee_code,
                          p_fee_plan,
                          p_cr_acctno,
                          p_dr_acctno,
                          p_attach_type,
                          p_card_stat,
                          v_cam_type_code,
                          NVL (v_timestamp, SYSTIMESTAMP),
                          p_prod_code,
                          p_card_type,
                          v_dr_cr_flag,
                          p_errmsg
                         );
   EXCEPTION
      WHEN exp_reject_record
      THEN
         p_errmsg := 'Error in update account ' || SUBSTR (SQLERRM, 1, 200);

         BEGIN
            INSERT INTO cms_inactivity_fee_det
                        (cfd_inst_code, cfd_pan_code, cfd_fee_code,
                         cfd_ins_user, cfd_ins_date, cfd_lupd_user,
                         cfd_lupd_date, cfd_process_msg, cfd_fee_plan,
                         cfd_fee_amnt
                        )
                 VALUES (p_instcode, p_hashpan, p_fee_code,
                         p_lupduser, SYSDATE, p_lupduser,
                         SYSDATE, p_errmsg, p_fee_plan,
                         p_fee_amnt
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while inserting Fee details 1.0'
                  || SUBSTR (SQLERRM, 1, 200);
         END;

         IF v_dr_cr_flag IS NULL
         THEN
            BEGIN
               SELECT ctm_credit_debit_flag
                 INTO v_dr_cr_flag
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = v_txn_code
                  AND ctm_delivery_channel = v_delivery_channel
                  AND ctm_inst_code = p_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         lp_transaction_log (p_instcode,
                             p_hashpan,
                             p_encrpan,
                             v_rrn2,
                             v_delivery_channel,
                             v_business_date,
                             v_business_time,
                             v_acct_number,
                             v_acct_bal - v_debit_amnt,
                             v_ledger_bal - v_debit_amnt,
                             p_fee_amnt,
                             v_auth_id,
                             v_tran_desc,
                             v_txn_code,
                             21,
                             v_card_curr,
                             p_waiv_amnt,
                             p_fee_code,
                             p_fee_plan,
                             p_cr_acctno,
                             p_dr_acctno,
                             p_attach_type,
                             p_card_stat,
                             v_cam_type_code,
                             NVL (v_timestamp, SYSTIMESTAMP),
                             p_prod_code,
                             p_card_type,
                             v_dr_cr_flag,
                             p_errmsg
                            );
      WHEN OTHERS
      THEN
         p_errmsg := 'Error in update account ' || SUBSTR (SQLERRM, 1, 200);

         BEGIN
            INSERT INTO cms_inactivity_fee_det
                        (cfd_inst_code, cfd_pan_code, cfd_fee_code,
                         cfd_ins_user, cfd_ins_date, cfd_lupd_user,
                         cfd_lupd_date, cfd_process_msg, cfd_fee_plan,
                         cfd_fee_amnt
                        )
                 VALUES (p_instcode, p_hashpan, p_fee_code,
                         p_lupduser, SYSDATE, p_lupduser,
                         SYSDATE, p_errmsg, p_fee_plan,
                         p_fee_amnt
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while inserting into INACTIVITY_FEE_DET '
                  || SUBSTR (SQLERRM, 1, 200);
         END;

         IF v_dr_cr_flag IS NULL
         THEN
            BEGIN
               SELECT ctm_credit_debit_flag
                 INTO v_dr_cr_flag
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = v_txn_code
                  AND ctm_delivery_channel = v_delivery_channel
                  AND ctm_inst_code = p_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         lp_transaction_log (p_instcode,
                             p_hashpan,
                             p_encrpan,
                             v_rrn2,
                             v_delivery_channel,
                             v_business_date,
                             v_business_time,
                             v_acct_number,
                             v_acct_bal - v_debit_amnt,
                             v_ledger_bal - v_debit_amnt,
                             p_fee_amnt,
                             v_auth_id,
                             v_tran_desc,
                             v_txn_code,
                             21,
                             v_card_curr,
                             p_waiv_amnt,
                             p_fee_code,
                             p_fee_plan,
                             p_cr_acctno,
                             p_dr_acctno,
                             p_attach_type,
                             p_card_stat,
                             v_cam_type_code,
                             NVL (v_timestamp, SYSTIMESTAMP),
                             p_prod_code,
                             p_card_type,
                             v_dr_cr_flag,
                             p_errmsg
                            );
   END lp_fee_update_log;
BEGIN
   IF TRUNC (LAST_DAY (SYSDATE)) = TRUNC (SYSDATE)
   THEN
      BEGIN
         FOR c1 IN cardfee
         LOOP
            v_err_msg := 'OK';
            v_fee_amount := c1.cfm_fee_amt;

            IF c1.cfm_feecap_flag = 'Y'
            THEN
               BEGIN
                  sp_tran_fees_cap (p_instcode,
                                    c1.cap_acct_no,
                                    TRUNC (SYSDATE),
                                    v_fee_amount,
                                    c1.cff_fee_plan,
                                    c1.cfm_fee_code,
                                    v_err_msg
                                   );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            END IF;

            BEGIN
               SELECT cce_waiv_prcnt
                 INTO v_cpw_waiv_prcnt
                 FROM cms_card_excpwaiv
                WHERE cce_inst_code = p_instcode
                  AND cce_pan_code = c1.cce_pan_code
                  AND cce_fee_code = c1.cfm_fee_code
                  AND cce_fee_plan = c1.cff_fee_plan
                  AND (   (    cce_valid_to IS NOT NULL
                           AND (SYSDATE BETWEEN cce_valid_from AND cce_valid_to
                               )
                          )
                       OR (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from
                          )
                      );

               v_waivamt := (v_cpw_waiv_prcnt / 100) * v_fee_amount;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_waivamt := 0;
            END;

            lp_fee_update_log (p_instcode,
                               c1.cce_pan_code,
                               c1.cce_pan_code_encr,
                               c1.cfm_fee_code,
                               v_fee_amount,
                               c1.cff_fee_plan,
                               c1.cce_crgl_catg,
                               c1.cce_crgl_code,
                               c1.cce_crsubgl_code,
                               c1.cce_cracct_no,
                               c1.cce_drgl_catg,
                               c1.cce_drgl_code,
                               c1.cce_drsubgl_code,
                               c1.cce_dracct_no,
                               v_waivamt,
                               'C',
                               c1.cap_card_stat,
                               c1.cap_acct_no,
                               c1.cap_prod_code,
                               c1.cap_card_type,
                               c1.cfm_fee_desc,
                               v_err_msg
                              );

            BEGIN
               UPDATE cms_appl_pan
                  SET cap_inactive_feecalc_date = SYSDATE
                WHERE cap_pan_code = c1.cce_pan_code
                  AND cap_card_stat = '8'
                  AND cap_inst_code = p_instcode
                  AND cap_expry_date > SYSDATE;

               IF SQL%ROWCOUNT = 0
               THEN
                  p_errmsg := 'No Records Updated in APPL_PAN 1.0';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while updating APPL_PAN 1.0--'
                     || SUBSTR (SQLERRM, 1, 200);
            END;
         END LOOP;
      END;

      BEGIN
         FOR c2 IN prodcatgfee
         LOOP
            v_err_msg := 'OK';

            BEGIN
               SELECT COUNT
                         (CASE
                             WHEN (    cce_valid_to IS NOT NULL
                                   AND (TRUNC (SYSDATE) BETWEEN cce_valid_from
                                                            AND cce_valid_to
                                       )
                                  )
                              OR (    cce_valid_to IS NULL
                                  AND TRUNC (SYSDATE) >= cce_valid_from
                                 )
                                THEN 1
                          END
                         )
                 INTO v_card_cnt
                 FROM cms_card_excpfee
                WHERE cce_inst_code = p_instcode
                  AND cce_pan_code = c2.cap_pan_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_card_cnt := 0;
            END;

            IF v_card_cnt = 0
            THEN
               v_fee_amount := c2.cfm_fee_amt;

               IF c2.cfm_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_cap (p_instcode,
                                       c2.cap_acct_no,
                                       TRUNC (SYSDATE),
                                       v_fee_amount,
                                       c2.cff_fee_plan,
                                       c2.cfm_fee_code,
                                       v_err_msg
                                      );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_waivamt := 0;
                  END;
               END IF;

               BEGIN
                  SELECT cpw_waiv_prcnt
                    INTO v_cpw_waiv_prcnt
                    FROM cms_prodcattype_waiv
                   WHERE cpw_inst_code = p_instcode
                     AND cpw_prod_code = c2.cpf_prod_code
                     AND cpw_card_type = c2.cpf_card_type
                     AND cpw_fee_code = c2.cfm_fee_code
                     AND SYSDATE >= cpw_valid_from
                     AND SYSDATE <= cpw_valid_to;

                  v_waivamt := (v_cpw_waiv_prcnt / 100) * v_fee_amount;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_waivamt := 0;
               END;

               lp_fee_update_log (p_instcode,
                                  c2.cap_pan_code,
                                  c2.cap_pan_code_encr,
                                  c2.cfm_fee_code,
                                  v_fee_amount,
                                  c2.cff_fee_plan,
                                  c2.cpf_crgl_catg,
                                  c2.cpf_crgl_code,
                                  c2.cpf_crsubgl_code,
                                  c2.cpf_cracct_no,
                                  c2.cpf_drgl_catg,
                                  c2.cpf_drgl_code,
                                  c2.cpf_drsubgl_code,
                                  c2.cpf_dracct_no,
                                  v_waivamt,
                                  'PC',
                                  c2.cap_card_stat,
                                  c2.cap_acct_no,
                                  c2.cap_prod_code,
                                  c2.cap_card_type,
                                  c2.cfm_fee_desc,
                                  v_err_msg
                                 );

               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_inactive_feecalc_date = SYSDATE
                   WHERE cap_pan_code = c2.cap_pan_code
                     AND cap_card_stat = '8'
                     AND cap_inst_code = p_instcode
                     AND cap_expry_date > SYSDATE;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     p_errmsg := 'No Records Updated in APPL_PAN 1.1';
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_errmsg :=
                           'Error while updating APPL_PAN 1.1--'
                        || SUBSTR (SQLERRM, 1, 200);
               END;
            END IF;
         END LOOP;
      END;

      BEGIN
         FOR c3 IN prodfee
         LOOP
            v_err_msg := 'OK';

            BEGIN
               SELECT COUNT
                         (CASE
                             WHEN (    cce_valid_to IS NOT NULL
                                   AND (TRUNC (SYSDATE) BETWEEN cce_valid_from
                                                            AND cce_valid_to
                                       )
                                  )
                              OR (    cce_valid_to IS NULL
                                  AND TRUNC (SYSDATE) >= cce_valid_from
                                 )
                                THEN 1
                          END
                         )
                 INTO v_card_cnt
                 FROM cms_card_excpfee
                WHERE cce_inst_code = p_instcode
                  AND cce_pan_code = c3.cap_pan_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_card_cnt := 0;
            END;

            IF v_card_cnt = 0
            THEN
               BEGIN
                  SELECT COUNT
                            (CASE
                                WHEN ((    cpf_valid_to IS NOT NULL
                                       AND TRUNC (SYSDATE)
                                              BETWEEN cpf_valid_from
                                                  AND cpf_valid_to
                                      )
                                     )
                                 OR (    cpf_valid_to IS NULL
                                     AND TRUNC (SYSDATE) >= cpf_valid_from
                                    )
                                   THEN 1
                             END
                            )
                    INTO v_prdcatg_cnt
                    FROM cms_prodcattype_fees
                   WHERE cpf_inst_code = p_instcode
                     AND cpf_prod_code = c3.cpf_prod_code
                     AND cpf_card_type = c3.cap_card_type;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_prdcatg_cnt := 0;
               END;
            END IF;

            IF v_card_cnt = 0 AND v_prdcatg_cnt = 0
            THEN
               v_fee_amount := c3.cfm_fee_amt;

               IF c3.cfm_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_cap (p_instcode,
                                       c3.cap_acct_no,
                                       TRUNC (SYSDATE),
                                       v_fee_amount,
                                       c3.cff_fee_plan,
                                       c3.cfm_fee_code,
                                       v_err_msg
                                      );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_waivamt := 0;
                  END;
               END IF;

               BEGIN
                  SELECT cpw_waiv_prcnt
                    INTO v_cpw_waiv_prcnt
                    FROM cms_prodccc_waiv
                   WHERE cpw_inst_code = p_instcode
                     AND cpw_prod_code = c3.cpf_prod_code
                     AND cpw_fee_code = c3.cfm_fee_code
                     AND SYSDATE >= cpw_valid_from
                     AND SYSDATE <= cpw_valid_to;

                  v_waivamt := (v_cpw_waiv_prcnt / 100) * v_fee_amount;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_waivamt := 0;
               END;

               lp_fee_update_log (p_instcode,
                                  c3.cap_pan_code,
                                  c3.cap_pan_code_encr,
                                  c3.cfm_fee_code,
                                  v_fee_amount,
                                  c3.cff_fee_plan,
                                  c3.cpf_crgl_catg,
                                  c3.cpf_crgl_code,
                                  c3.cpf_crsubgl_code,
                                  c3.cpf_cracct_no,
                                  c3.cpf_drgl_catg,
                                  c3.cpf_drgl_code,
                                  c3.cpf_drsubgl_code,
                                  c3.cpf_dracct_no,
                                  v_waivamt,
                                  'P',
                                  c3.cap_card_stat,
                                  c3.cap_acct_no,
                                  c3.cap_prod_code,
                                  c3.cap_card_type,
                                  c3.cfm_fee_desc,
                                  v_err_msg
                                 );

               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_inactive_feecalc_date = SYSDATE
                   WHERE cap_pan_code = c3.cap_pan_code
                     AND cap_card_stat = '8'
                     AND cap_inst_code = p_instcode
                     AND cap_expry_date > SYSDATE;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     p_errmsg := 'No Records Updated in APPL_PAN 1.2';
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_errmsg :=
                           'Error while updating APPL_PAN 1.2--'
                        || SUBSTR (SQLERRM, 1, 200);
               END;
            END IF;
         END LOOP;
      END;

      p_errmsg := 'Inactivity Fee Calculated for ' || v_upd_rec_cnt || 'Cards';
   ELSE
      p_errmsg := 'Inactivity Fee can be Calculated only during Month End';
   END IF;
END sp_calc_inactive_fees;

/
SHOW ERROR;