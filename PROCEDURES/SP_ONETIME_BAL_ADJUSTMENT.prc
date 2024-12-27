CREATE OR REPLACE PROCEDURE VMSCMS.SP_ONETIME_BAL_ADJUSTMENT (
   p_instcode   IN       NUMBER,
   p_ins_user   IN       NUMBER,
   p_errmsg     OUT      VARCHAR2
)
AS
   CURSOR cur_1
   IS
      SELECT ROWID row_id, a.*
        FROM cms_batch_adjstment a
       WHERE a.cba_process_stat = 'N';

   v_transaction        NUMBER                                 DEFAULT 0;
   v_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
   v_business_date      VARCHAR2 (10);
   v_business_time      VARCHAR2 (10);
   v_rrn                transactionlog.rrn%TYPE;
   v_rrn_cnt            NUMBER                                 DEFAULT 0;
   v_errmsg             VARCHAR2 (300);
   v_excep              EXCEPTION;
   v_panno              VARCHAR2 (30);
   v_delivery_channel   transactionlog.delivery_channel%TYPE;
   v_txn_type           transactionlog.txn_type%TYPE;
   v_txn_code           transactionlog.txn_code%TYPE;
   v_txn_mode           cms_func_mast.cfm_txn_mode%TYPE        DEFAULT '0';
   v_msg                VARCHAR2 (2)                           DEFAULT '00';
   v_txn_amount         NUMBER (20, 3);
   v_upd_amt            NUMBER;
   v_upd_acct_bal       NUMBER;
   --Added by saravanakumar on 06-Mar-2014 for logging issue
   v_cap_card_stat      cms_appl_pan.cap_card_stat%TYPE;
   v_prod_code          cms_appl_pan.cap_prod_code%TYPE;
   v_card_type          cms_appl_pan.cap_card_type%TYPE;
   v_acct_number        cms_appl_pan.cap_acct_no%TYPE;
   v_func_code          cms_func_mast.cfm_func_code%TYPE;
   v_cracct_no          cms_func_prod.cfp_cracct_no%TYPE;
   v_dracct_no          cms_func_prod.cfp_dracct_no%TYPE;
   v_acct_type          cms_acct_type.cat_type_code%TYPE;
   v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   v_auth_id            transactionlog.auth_id%TYPE;
   v_narration          VARCHAR2 (300);
   v_commit_pnt         NUMBER (10)                            := 0;
   v_timestamp          TIMESTAMP;
   v_batch_seq          VARCHAR2 (6);
   exp_reject_batch     EXCEPTION;
   v_reason_count       NUMBER;
   v_reasondesc         cms_spprt_reasons.csr_reasondesc%TYPE;
BEGIN
   BEGIN
      SELECT LPAD (seq_batchupload_id.NEXTVAL, 6, '0')
        INTO v_batch_seq
        FROM DUAL;

      INSERT INTO vmscms.cms_batchupload_details
                  (cbd_inst_code, cbd_file_type, cbd_file_path,
                   cbd_file_name, cbd_batch_id, cbd_file_status,
                   cbd_upload_user, cbd_ins_user, cbd_ins_date
                  )
           VALUES (1, 3, 'Incomm' || v_batch_seq,
                   'Incomm' || v_batch_seq, 'Batch' || v_batch_seq, 3,
                   p_ins_user, p_ins_user, SYSDATE
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Error while generating Batch id:- Error msg '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_batch;
   END;
   COMMIT;
   FOR x IN cur_1
   LOOP
      BEGIN
         SAVEPOINT v_transaction;
         v_transaction := v_transaction + 1;
         v_commit_pnt := v_commit_pnt + 1;
         v_rrn_cnt := v_rrn_cnt + 1;
         v_errmsg := 'OK';

         BEGIN
            v_panno := fn_dmaps_main (x.cba_card_no_encr);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while converting pan encr-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE v_excep;
         END;

         BEGIN
            SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'),
                   TO_CHAR (SYSDATE, 'HH24MISS'),
                   TO_CHAR (SYSDATE, 'DDHH24MISS') || LPAD (v_rrn_cnt, 5, 0)
              INTO v_business_date,
                   v_business_time,
                   v_rrn
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting txn dtls-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE v_excep;
         END;

         IF x.cba_trans_amount = 0
         THEN
            v_errmsg := 'Transaction rejected for txn amount is zero';
            RAISE v_excep;
         ELSE
            v_delivery_channel := '05';
            v_txn_type := '1';

            IF x.cba_trans_type = 'CR'
            THEN
               v_txn_code := 20;
               v_txn_amount := ROUND (x.cba_trans_amount, 2);
            ELSIF x.cba_trans_type = 'DR'
            THEN
               v_txn_code := 19;
               v_txn_amount := ROUND (x.cba_trans_amount, 2);
            END IF;
         END IF;

         --** <Reason Code vaildation Starts>
         BEGIN
            SELECT csr_reasondesc
              INTO v_reasondesc
              FROM cms_spprt_reasons
             WHERE csr_inst_code = p_instcode
               AND csr_spprt_key = 'MANADJDRCR'
               AND csr_spprt_rsncode = x.cba_reason_code;

         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'Inavlid Reason code ';
               RAISE v_excep;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting reason code from master'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE v_excep;
         END;

         --** <Reason Code validation Endz>
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO v_cap_card_stat, v_prod_code, v_card_type, v_acct_number
              FROM cms_appl_pan
             WHERE cap_pan_code = x.cba_card_no AND cap_inst_code = p_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'Card Not Found In CMS';
               RAISE v_excep;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting card number-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE v_excep;
         END;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO v_acct_bal, v_ledger_bal, v_acct_type
              FROM cms_acct_mast
             WHERE cam_inst_code = p_instcode AND cam_acct_no = v_acct_number;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'Account Not Found In CMS';
               RAISE v_excep;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Problem while selecting acct dtls-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE v_excep;
         END;

         BEGIN
            SELECT cfm_func_code
              INTO v_func_code
              FROM cms_func_mast
             WHERE cfm_txn_code = v_txn_code
               AND cfm_txn_mode = v_txn_mode
               AND cfm_delivery_channel = v_delivery_channel
               AND cfm_inst_code = p_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                     'Function code not defined for txn code '
                  || v_txn_code
                  || ' '
                  || v_delivery_channel;
               RAISE v_excep;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting function code-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE v_excep;
         END;

         BEGIN
            SELECT cfp_cracct_no, cfp_dracct_no
              INTO v_cracct_no, v_dracct_no
              FROM cms_func_prod
             WHERE cfp_func_code = v_func_code
               AND cfp_prod_code = v_prod_code
               AND cfp_prod_cattype = v_card_type
               AND cfp_inst_code = p_instcode;

            IF TRIM (v_cracct_no) IS NULL AND TRIM (v_dracct_no) IS NULL
            THEN
               v_errmsg :=
                     'Both credit and debit account cannot be null for a Function code '
                  || v_func_code;
               RAISE v_excep;
            END IF;
         EXCEPTION
            WHEN v_excep
            THEN
               RAISE;
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'Function is not attached to card';
               RAISE v_excep;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting Gl details-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE v_excep;
         END;

         IF x.cba_trans_type = 'CR'
         THEN
            v_upd_amt := v_ledger_bal + v_txn_amount;
            --Modified by saravanakumar on 06-Mar-2014 for logging issue
            v_upd_acct_bal := v_acct_bal + v_txn_amount;
         --Added by saravanakumar on 06-Mar-2014 for logging issue
         ELSIF x.cba_trans_type = 'DR'
         THEN
            v_upd_amt := v_ledger_bal - v_txn_amount;
            --Modified by saravanakumar on 06-Mar-2014 for logging issue
            v_upd_acct_bal := v_acct_bal - v_txn_amount;
         --Added by saravanakumar on 06-Mar-2014 for logging issue
         END IF;

         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO v_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  'Error while generating authid-'
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE v_excep;
         END;

         BEGIN
            v_timestamp := SYSTIMESTAMP;

            IF x.cba_trans_type = 'CR'
            THEN
               IF TRIM (x.cba_trans_narration) IS NOT NULL
               THEN
                  v_narration := x.cba_trans_narration || '/';
               END IF;

               IF TRIM (v_auth_id) IS NOT NULL
               THEN
                  v_narration := v_narration || v_auth_id || '/';
               END IF;

               IF TRIM (v_acct_number) IS NOT NULL
               THEN
                  v_narration := v_narration || v_acct_number || '/';
               END IF;

               IF TRIM (v_business_date) IS NOT NULL
               THEN
                  v_narration := v_narration || v_business_date;
               END IF;

               BEGIN
                  UPDATE cms_acct_mast
                     SET cam_acct_bal = cam_acct_bal + v_txn_amount,
                         cam_ledger_bal = cam_ledger_bal + v_txn_amount
                   WHERE cam_inst_code = p_instcode
                     AND cam_acct_no = v_acct_number;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg :=
                                'No records updated in account master for CR';
                     RAISE v_excep;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error occurred while updating acct mast for CR-'
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE v_excep;
               END;

               BEGIN
                  sp_ins_eodupdate_acct_cmsauth (v_rrn,
                                                 NULL,
                                                 v_delivery_channel,
                                                 v_txn_code,
                                                 v_txn_mode,
                                                 TO_DATE (v_business_date,
                                                          'yyyymmdd'
                                                         ),
                                                 v_panno,
                                                 v_dracct_no,
                                                 v_txn_amount,
                                                 'D',
                                                 p_instcode,
                                                 v_errmsg
                                                );

                  IF v_errmsg <> 'OK'
                  THEN
                     RAISE v_excep;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error occurred while debiting gl for CR-'
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE v_excep;
               END;

               BEGIN
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal,
                               csl_trans_amount, csl_trans_type,
                               csl_trans_date,
                               csl_closing_balance, csl_trans_narrration,
                               csl_inst_code, csl_pan_no_encr, csl_rrn,
                               csl_business_date, csl_business_time,
                               csl_delivery_channel, csl_txn_code,
                               csl_auth_id, csl_ins_date, csl_ins_user,
                               csl_acct_no,
                               csl_panno_last4digit,
                               csl_to_acctno, csl_acct_type, csl_time_stamp,
                               csl_prod_code,csl_card_type
                              )
                       VALUES (x.cba_card_no, v_ledger_bal,
                               ----Modified by saravanakumar on 06-Mar-2014 for logging issue
                               v_txn_amount, x.cba_trans_type,
                               TO_DATE (v_business_date, 'yyyymmdd'),
                               v_upd_amt, v_narration,
                               p_instcode, x.cba_card_no_encr, v_rrn,
                               v_business_date, v_business_time,
                               v_delivery_channel, v_txn_code,
                               v_auth_id, SYSDATE, 1,
                               v_acct_number,

                               --Modified by saravanakumar on 06-Mar-2014 for logging issue
                               (SUBSTR (v_panno,
                                        LENGTH (v_panno) - 3,
                                        LENGTH (v_panno)
                                       )
                               ),
                               NULL, v_acct_type, v_timestamp,
                               --Modified by saravanakumar on 06-Mar-2014 for logging issue
                               v_prod_code,v_card_type
                              );

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg :=
                               'No records inserted in statements log for CR';
                     RAISE v_excep;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Problem while inserting into statement log for CR-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE v_excep;
               END;
            ELSIF x.cba_trans_type = 'DR'
            THEN
               IF TRIM (x.cba_trans_narration) IS NOT NULL
               THEN
                  v_narration := x.cba_trans_narration || '/';
               END IF;

               IF TRIM (v_auth_id) IS NOT NULL
               THEN
                  v_narration := v_narration || v_auth_id || '/';
               END IF;

               IF TRIM (v_cracct_no) IS NOT NULL
               THEN
                  v_narration := v_narration || v_cracct_no || '/';
               END IF;

               IF TRIM (v_business_date) IS NOT NULL
               THEN
                  v_narration := v_narration || v_business_date;
               END IF;

               BEGIN
                  UPDATE cms_acct_mast
                     SET cam_acct_bal = cam_acct_bal - v_txn_amount,
                         cam_ledger_bal = cam_ledger_bal - v_txn_amount
                   WHERE cam_inst_code = p_instcode
                     AND cam_acct_no = v_acct_number;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg :=
                                'No records updated in account master for DR';
                     RAISE v_excep;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error occurred while updating acct mast for DR-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE v_excep;
               END;

               BEGIN
                  sp_ins_eodupdate_acct_cmsauth (v_rrn,
                                                 NULL,
                                                 v_delivery_channel,
                                                 v_txn_code,
                                                 v_txn_mode,
                                                 TO_DATE (v_business_date,
                                                          'yyyymmdd'
                                                         ),
                                                 v_panno,
                                                 v_cracct_no,
                                                 v_txn_amount,
                                                 'C',
                                                 p_instcode,
                                                 v_errmsg
                                                );

                  IF v_errmsg <> 'OK'
                  THEN
                     RAISE v_excep;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error occurred while crediting gl for DR-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE v_excep;
               END;

               BEGIN
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal,
                               csl_trans_amount, csl_trans_type,
                               csl_trans_date,
                               csl_closing_balance, csl_trans_narrration,
                               csl_inst_code, csl_pan_no_encr, csl_rrn,
                               csl_business_date, csl_business_time,
                               csl_delivery_channel, csl_txn_code,
                               csl_auth_id, csl_ins_date, csl_ins_user,
                               csl_acct_no,
                               csl_panno_last4digit,
                               csl_to_acctno, csl_acct_type, csl_time_stamp,
                               csl_prod_code,csl_card_type
                              )
                       VALUES (x.cba_card_no, v_ledger_bal,
                               --Modified by saravanakumar on 06-Mar-2014 for logging issue
                               v_txn_amount, x.cba_trans_type,
                               TO_DATE (v_business_date, 'yyyymmdd'),
                               v_upd_amt, v_narration,
                               p_instcode, x.cba_card_no_encr, v_rrn,
                               v_business_date, v_business_time,
                               v_delivery_channel, v_txn_code,
                               v_auth_id, SYSDATE, 1,
                               v_acct_number,
                               (SUBSTR (v_panno,
                                        LENGTH (v_panno) - 3,
                                        LENGTH (v_panno)
                                       )
                               ),
                               NULL, v_acct_type, v_timestamp,
                               --Modified by saravanakumar on 06-Mar-2014 for logging issue
                               v_prod_code,v_card_type
                              );

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg :=
                               'No records inserted in statements log for DR';
                     RAISE v_excep;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Problem while inserting into statement log for DR-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE v_excep;
               END;
            ELSIF NVL (x.cba_trans_type, '0') NOT IN ('DR', 'CR')
            THEN
               v_errmsg := 'invalid debit/credit flag ';
               RAISE v_excep;
            END IF;
         END;

         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, date_time,
                         txn_code, txn_type, txn_mode, txn_status,
                         response_code, business_date, business_time,
                         customer_card_no, instcode, customer_card_no_encr,
                         customer_acct_no, error_msg, cardstatus,
                         amount,
                         bank_code,
                         total_amount,
                         currencycode, auth_id,
                         trans_desc, gl_upd_flag,
                         acct_balance,
                         ledger_balance,
                         response_id, add_ins_date, add_ins_user, productid,
                         categoryid, acct_type, time_stamp,
                         cr_dr_flag, reason
                        )
                 VALUES (v_msg, v_rrn, v_delivery_channel, SYSDATE,
                         v_txn_code, v_txn_type, v_txn_mode, 'C',
                         '00', v_business_date, v_business_time,
                         x.cba_card_no, p_instcode, x.cba_card_no_encr,
                         v_acct_number, v_errmsg, v_cap_card_stat,
                         TRIM (TO_CHAR (v_txn_amount, '99999999999999990.99')),
                         p_instcode,
                         TRIM (TO_CHAR (v_txn_amount, '99999999999999990.99')),
                         '840', v_auth_id,
                         substr(x.cba_trans_narration,1,50), 'N',
                         TRIM (TO_CHAR (v_upd_acct_bal,
                                        '99999999999999990.99')
                              ),
                         --Modified by saravanakumar on 06-Mar-2014 for logging issue
                         TRIM (TO_CHAR (v_upd_amt, '99999999999999990.99')),
                         '1', SYSDATE, 1, v_prod_code,
                         v_card_type, v_acct_type, v_timestamp,
                         x.cba_trans_type, v_reasondesc
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Exception while inserting to transaction log-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE v_excep;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                         ctd_rrn, ctd_inst_code, ctd_ins_date,
                         ctd_customer_card_no_encr, ctd_msg_type,
                         request_xml, ctd_cust_acct_number,
                         ctd_addr_verify_response, ctd_actual_amount,
                         ctd_txn_amount
                        )
                 VALUES (v_delivery_channel, v_txn_code, v_txn_type,
                         v_txn_mode, v_business_date, v_business_time,
                         x.cba_card_no, '840', NULL,
                         NULL, NULL,
                         NULL, 'Y', v_errmsg,
                         v_rrn, p_instcode, SYSDATE,
                         x.cba_card_no_encr, v_msg,
                         '', v_acct_number,
                         '', v_txn_amount,
                         v_txn_amount
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE v_excep;
         END;

         IF v_errmsg = 'OK'
         THEN
            --SN log the transaction detials in bal_adj_batch table
            BEGIN
               INSERT INTO cms_bal_adj_batch
                           (cbb_batch_id, cbb_pan_code,
                            cbb_pan_code_encr, cbb_txn_amt, cbb_forse_post,
                            cbb_reason_code, cbb_txn_desc,
                            cbb_before_ledg_bal, cbb_after_ledg_bal,
                            cbb_process_flag, cbb_process_msg, cbb_ins_user,
                            cbb_ins_date
                           )
                    VALUES ('Batch' || v_batch_seq, x.cba_card_no,
                            x.cba_card_no_encr, v_txn_amount, 'Yes',
                            x.cba_reason_code, v_narration,
                            v_ledger_bal, v_upd_amt,
                            'S', 'Success', 1,
                            SYSDATE    --TO_DATE (v_business_date, 'YYYYMMDD')
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem while inserting bal adj batch process Detail '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE v_excep;
            END;

            --EN log the transaction detials in bal_adj_batch table
            BEGIN
               UPDATE cms_batch_adjstment
                  SET cba_process_stat = 'Y',
                      cba_process_msg = 'Sucessful',
                      cba_process_date = SYSDATE,
                      cba_batch_id = 'Batch' || v_batch_seq
                WHERE ROWID = x.row_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem while updating Sucessful record'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE v_excep;
            END;
         END IF;
      EXCEPTION
         WHEN v_excep
         THEN
            ROLLBACK TO v_transaction;

            UPDATE cms_batch_adjstment
               SET cba_process_stat = 'E',
                   cba_process_msg = v_errmsg,
                   cba_process_date = SYSDATE,
                   cba_batch_id = 'Batch' || v_batch_seq
             WHERE ROWID = x.row_id;
         WHEN OTHERS
         THEN
            ROLLBACK TO v_transaction;
            v_errmsg := 'Main Excp-' || SUBSTR (SQLERRM, 1, 200);

            UPDATE cms_batch_adjstment
               SET cba_process_stat = 'E',
                   cba_process_msg = v_errmsg,
                   cba_process_date = SYSDATE,
                   cba_batch_id = 'Batch' || v_batch_seq
             WHERE ROWID = x.row_id;
      END;

      IF v_commit_pnt = 1
      THEN
         COMMIT;
         v_commit_pnt := 0;
      END IF;
   END LOOP;

   COMMIT;
   p_errmsg := 'OK';
EXCEPTION
   when exp_reject_batch then
       null;
   WHEN OTHERS
   THEN
      p_errmsg := ' Main Excp-' || SQLERRM;
END;

/

show error