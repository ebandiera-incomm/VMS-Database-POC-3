CREATE OR REPLACE TRIGGER VMSCMS.trg_clawback_recovery
   BEFORE UPDATE OF cam_acct_bal
   ON VMSCMS.CMS_ACCT_MAST    FOR EACH ROW
DECLARE
   v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   v_clawback_amount    cms_acct_mast.cam_acct_bal%TYPE;
   v_narration          VARCHAR2 (300);
   v_rrn                VARCHAR2 (15);
   v_auth_id            transactionlog.auth_id%TYPE;
   v_errmsg             VARCHAR2 (300)                            := 'OK';
   exp_reject           EXCEPTION;
   v_pending_amnt       NUMBER (20, 3);
   v_cardno_fourdigit   VARCHAR2 (4);
   v_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
   v_business_date      VARCHAR2 (8);
   v_card_no            VARCHAR2 (19);
   v_card_curr          transactionlog.currencycode%TYPE;
   v_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_clawback_rrn       NUMBER (20);
   --Sn added by Pankaj S. for 10871
   v_timestamp          TIMESTAMP ( 3 );
   v_prod_code          cms_appl_pan.cap_prod_code%TYPE;
   v_card_type         cms_appl_pan.cap_card_type%TYPE;
   --En added by Pankaj S. for 10871
/*************************************************
     * Modified By      :  Deepa T
     * Modified Date    :  22--OCT-2012
     * Modified Reason  :  To log the Fee details in transactionlog,cms_tarnsaction_log_dtl table.
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 31-OCT-12
     * Build Number     : CMS3.5.1_RI0021
      
     * Modified by      :  Pankaj S.
     * Modified Reason  :  10871
     * Modified Date    :  19-Apr-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0024.1_B0013

   *************************************************/
BEGIN
   FOR i IN (SELECT   cad_clawback_amnt, cad_delivery_channel, cad_txn_code
                 FROM cms_acctclawback_dtl
                WHERE cad_acct_no = :NEW.cam_acct_no
                  AND cad_inst_code = :NEW.cam_inst_code
                  AND cad_recovery_flag = 'N'
                  AND cad_clawback_amnt > 0
             ORDER BY cad_clawback_amnt)
   LOOP
      FOR j IN (SELECT   ccd_clawback_amnt, ccd_pan_code, ccd_gl_acct_no,
                         ccd_pan_code_encr, ccd_rrn, ccd_calc_date,
                         ccd_feeattachtype, ccd_fee_plan, ccd_fee_code
                    FROM cms_charge_dtl
                   WHERE ccd_file_status = 'C'
                     AND ccd_clawback = 'Y'
                     AND ccd_inst_code = :NEW.cam_inst_code
                     AND ccd_acct_no = :NEW.cam_acct_no
                     AND ccd_delivery_channel = i.cad_delivery_channel
                     AND ccd_txn_code = i.cad_txn_code
                ORDER BY ccd_clawback_amnt)
      LOOP
         v_timestamp := SYSTIMESTAMP;          --added by Pankaj S. for 10871

         IF :NEW.cam_acct_bal > 0 AND j.ccd_clawback_amnt > 0
         THEN
            v_acct_bal := :NEW.cam_ledger_bal;
           --cam_acct_bal replaced by Pankaj S. with cam_ledger_bal for 10871

            IF :NEW.cam_acct_bal >= j.ccd_clawback_amnt
            THEN
               :NEW.cam_acct_bal := :NEW.cam_acct_bal - j.ccd_clawback_amnt;
               :NEW.cam_ledger_bal :=
                                    :NEW.cam_ledger_bal - j.ccd_clawback_amnt;
               v_clawback_amount := j.ccd_clawback_amnt;
            ELSE
               :NEW.cam_ledger_bal := :NEW.cam_ledger_bal - :NEW.cam_acct_bal;
               v_clawback_amount := :NEW.cam_acct_bal;
               :NEW.cam_acct_bal := 0;
            END IF;

            BEGIN
               SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0'),
                      TO_CHAR (SYSDATE, 'YYYYMMDD')
                 INTO v_auth_id,
                      v_business_date
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while generating authid '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            BEGIN
               SELECT csl_trans_narrration, csl_panno_last4digit
                 INTO v_narration, v_cardno_fourdigit
                 FROM cms_statements_log
                WHERE csl_pan_no = j.ccd_pan_code
                  AND csl_rrn = j.ccd_rrn
                  AND csl_inst_code = :NEW.cam_inst_code
                  AND csl_acct_no = :NEW.cam_acct_no;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     SELECT ctm_tran_desc
                       INTO v_tran_desc
                       FROM cms_transaction_mast
                      WHERE ctm_tran_code = i.cad_txn_code
                        AND ctm_delivery_channel = i.cad_delivery_channel
                        AND ctm_inst_code = :NEW.cam_inst_code;

                     IF TRIM (v_tran_desc) IS NOT NULL
                     THEN
                        v_narration := v_tran_desc || '/';
                     END IF;

                     IF TRIM (v_auth_id) IS NOT NULL
                     THEN
                        v_narration := v_narration || v_auth_id || '/';
                     END IF;

                     IF TRIM (:NEW.cam_acct_no) IS NOT NULL
                     THEN
                        v_narration := v_narration || :NEW.cam_acct_no || '/';
                     END IF;

                     IF TRIM (v_business_date) IS NOT NULL
                     THEN
                        v_narration := v_narration || v_business_date;
                     END IF;

                     v_card_no := fn_dmaps_main (j.ccd_pan_code_encr);
                     v_cardno_fourdigit :=
                        SUBSTR (v_card_no,
                                LENGTH (v_card_no) - 3,
                                LENGTH (v_card_no)
                               );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while narration creation'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject;
                  END;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in narration selection'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            BEGIN
               SELECT cap_prod_code, cap_card_type, cap_card_stat
                 INTO v_prod_code, v_card_type, v_card_stat
                 FROM cms_appl_pan
                WHERE cap_pan_code = j.ccd_pan_code
                  AND cap_inst_code = :NEW.cam_inst_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Card Details Not Found';
                  RAISE exp_reject;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     'While getting card details' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            SELECT seq_clawback_rrn.NEXTVAL
              INTO v_clawback_rrn
              FROM DUAL;

            v_rrn := 'CBK' || v_business_date || v_clawback_rrn;
            v_pending_amnt := j.ccd_clawback_amnt - v_clawback_amount;

            BEGIN
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_acct_no, csl_opening_bal,
                            csl_trans_amount, csl_trans_type,
                            csl_trans_date, csl_closing_balance,
                            csl_trans_narrration, csl_pan_no_encr,
                            csl_rrn, csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_inst_code,
                            csl_txn_code, csl_ins_date, csl_ins_user,
                            csl_panno_last4digit, 
                            csl_prod_code,csl_acct_type,csl_time_stamp      --added by Pankaj S. for 10871
                           )
                    VALUES (j.ccd_pan_code, :NEW.cam_acct_no, v_acct_bal,
                            v_clawback_amount, 'DR',
                            SYSDATE, v_acct_bal - v_clawback_amount,
                            'CLAWBACK-' || v_narration, j.ccd_pan_code_encr,
                            v_rrn, v_auth_id, v_business_date,
                            TO_CHAR (SYSDATE, 'hh24miss'), 'Y',
                            i.cad_delivery_channel, :NEW.cam_inst_code,
                            i.cad_txn_code, SYSDATE, 1,
                            v_cardno_fourdigit, 
                            v_prod_code,:OLD.cam_type_code,v_timestamp         --added by Pankaj S. for 10871
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error creating entry in statement log '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            BEGIN
               INSERT INTO cms_eodupdate_acct
                           (ceu_rrn, ceu_terminal_id, ceu_delivery_channel,
                            ceu_txn_code, ceu_txn_mode, ceu_tran_date,
                            ceu_customer_card_no, ceu_upd_acctno,
                            ceu_upd_amount, ceu_upd_flag, ceu_process_flag,
                            ceu_process_msg, ceu_inst_code,
                            ceu_customer_card_no_encr
                           )
                    VALUES (v_rrn, NULL, i.cad_delivery_channel,
                            i.cad_txn_code, '0', SYSDATE,
                            j.ccd_pan_code, j.ccd_gl_acct_no,
                            v_clawback_amount, 'C', 'N',
                            NULL, :NEW.cam_inst_code,
                            j.ccd_pan_code_encr
                           );

               IF SQL%ROWCOUNT <> 1
               THEN
                  v_errmsg := 'Error while inseting GL details';
                  RAISE exp_reject;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in GL details insertion'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            BEGIN
               UPDATE cms_charge_dtl
                  SET ccd_file_status = DECODE (v_pending_amnt, 0, 'Y', 'C'),
                      ccd_clawback_amnt = v_pending_amnt,
                      ccd_clawback = DECODE (v_pending_amnt, 0, 'N', 'Y'),
                      ccd_debited_amnt = ccd_debited_amnt + v_clawback_amount
                WHERE ccd_file_status = 'C'
                  AND ccd_clawback = 'Y'
                  AND ccd_inst_code = :NEW.cam_inst_code
                  AND ccd_acct_no = :NEW.cam_acct_no
                  AND ccd_rrn = j.ccd_rrn
                  AND ccd_pan_code = j.ccd_pan_code
                  AND ccd_calc_date = j.ccd_calc_date
                  AND ccd_delivery_channel = i.cad_delivery_channel
                  AND ccd_txn_code = i.cad_txn_code;

               IF SQL%ROWCOUNT <> 1
               THEN
                  v_errmsg :=
                        'Error while updating cms_charge_dtl'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
               END IF;

               UPDATE cms_acctclawback_dtl
                  SET cad_clawback_amnt =
                                         cad_clawback_amnt - v_clawback_amount,
                      cad_recovery_flag =
                         DECODE (cad_clawback_amnt - v_clawback_amount,
                                 0, 'Y',
                                 'N'
                                )
                WHERE cad_delivery_channel = i.cad_delivery_channel
                  AND cad_txn_code = i.cad_txn_code
                  AND cad_acct_no = :NEW.cam_acct_no
                  AND cad_inst_code = :NEW.cam_inst_code
                  AND cad_recovery_flag = 'N';

               IF SQL%ROWCOUNT <> 1
               THEN
                  v_errmsg :=
                        'Error while updating cms_acctclawback_dtl and cms_acctclawback_dtl'
                     || SUBSTR (SQLERRM, 1, 200);
                  --RAISE exp_reject;
               END IF;
            EXCEPTION
                WHEN exp_reject THEN
                    RAISE exp_reject;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in updating cms_charge_dtl'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            BEGIN
               SELECT TRIM (cbp_param_value)
                 INTO v_card_curr
                 FROM cms_appl_pan, cms_bin_param, cms_prod_mast
                WHERE cap_inst_code = cbp_inst_code
                  AND cpm_inst_code = cbp_inst_code
                  AND cap_prod_code = cpm_prod_code
                  AND cpm_profile_code = cbp_profile_code
                  AND cbp_param_name = 'Currency'
                  AND cap_pan_code = j.ccd_pan_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in selecting card Currency'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            /*BEGIN

            SELECT cap_card_stat
              INTO v_card_stat
              FROM cms_appl_pan
             WHERE cap_pan_code = j.ccd_pan_code AND cap_inst_code = :NEW.cam_inst_code;

            EXCEPTION
            WHEN NO_DATA_FOUND THEN
            v_errmsg:='Card Details Not Found';
            RAISE exp_reject;
            WHEN OTHERS THEN
            v_errmsg:='While getting card details'|| SUBSTR(SQLERRM, 1, 200);
            RAISE exp_reject;
            END;*/
            BEGIN
               INSERT INTO transactionlog
                           (msgtype, rrn, delivery_channel, date_time,
                            txn_code, txn_type, txn_status, response_code,
                            business_date, business_time,
                            customer_card_no, bank_code,
                            total_amount,
                            auth_id, trans_desc, instcode,
                            customer_card_no_encr, customer_acct_no,
                            acct_balance,
                            ledger_balance,
                            response_id, txn_mode,
                            tranfee_amt,
                            feeattachtype, fee_plan,
                            feecode, tranfee_cr_acctno,
                            tranfee_dr_acctno, currencycode, cardstatus,
                            clawback_indicator,
                            productid,categoryid,acct_type,time_stamp  --added by Pankaj S. for 10871
                           )
                    VALUES ('0200', v_rrn, i.cad_delivery_channel, SYSDATE,
                            i.cad_txn_code, '1', 'C', '00',
                            v_business_date, TO_CHAR (SYSDATE, 'hh24miss'),
                            j.ccd_pan_code, :NEW.cam_inst_code,
                            TRIM (TO_CHAR (v_clawback_amount,
                                           '999999999999999990.99'  --Formatted for 10871
                                          )
                                 ),
                            v_auth_id, v_tran_desc, :NEW.cam_inst_code,
                            j.ccd_pan_code_encr, :NEW.cam_acct_no,
                            TRIM (TO_CHAR (:NEW.cam_acct_bal,
                                           '99999999999999999.99'
                                          )
                                 ),
                            TRIM (TO_CHAR (:NEW.cam_ledger_bal,
                                           '99999999999999999.99'
                                          )
                                 ),
                            1, 0,
                            TRIM (TO_CHAR (v_clawback_amount,
                                           '999999999999999990.99'   --Formatted for 10871
                                          )
                                 ),
                            j.ccd_feeattachtype, j.ccd_fee_plan,
                            j.ccd_fee_code, j.ccd_gl_acct_no,
                            :NEW.cam_acct_no, v_card_curr, v_card_stat,
                            'Y',
                            v_prod_code,v_card_type,:OLD.cam_type_code,v_timestamp  --added by Pankaj S. for 10871
                           );

               IF SQL%ROWCOUNT <> 1
               THEN
                  v_errmsg :=
                        'Error while inserting details in transactionlog'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in inserting transactionlog'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;

            BEGIN
               INSERT INTO cms_transaction_log_dtl
                           (ctd_delivery_channel, ctd_txn_code,
                            ctd_txn_type, ctd_msg_type, ctd_txn_mode,
                            ctd_business_date, ctd_business_time,
                            ctd_customer_card_no,
                            ctd_fee_amount,
                            ctd_process_flag, ctd_process_msg, ctd_rrn,
                            ctd_inst_code, ctd_customer_card_no_encr,
                            ctd_cust_acct_number, ctd_txn_curr
                           )
                    VALUES (i.cad_delivery_channel, i.cad_txn_code,
                            '1', '0200', 0,
                            v_business_date, TO_CHAR (SYSDATE, 'hh24miss'),
                            j.ccd_pan_code,
                            TRIM (TO_CHAR (v_clawback_amount,
                                           '99999999999999999.99'
                                          )
                                 ),
                            'Y', 'Successful', v_rrn,
                            :NEW.cam_inst_code, j.ccd_pan_code_encr,
                            :NEW.cam_acct_no, v_card_curr
                           );

               IF SQL%ROWCOUNT <> 1
               THEN
                  v_errmsg :=
                        'Error while inserting details in cms_transaction_log_dtl'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error in inserting cms_transaction_log_dtl'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject;
            END;
         END IF;
      END LOOP;
   END LOOP;
END;
/
SHOW ERRORS;

