CREATE OR REPLACE PROCEDURE vmscms.sp_csr_renew_pan (
   prm_inst_code          IN       NUMBER,
   prm_msg                IN       VARCHAR2,
   prm_rrn                IN       VARCHAR2,
   prm_delivery_channel   IN       VARCHAR2,
   prm_term_id            IN       VARCHAR2,
   prm_txn_code           IN       VARCHAR2,
   prm_txn_mode           IN       VARCHAR2,
   prm_tran_date          IN       VARCHAR2,
   prm_tran_time          IN       VARCHAR2,
   prm_card_no            IN       VARCHAR2,
   prm_bank_code          IN       VARCHAR2,
   prm_txn_amt            IN       NUMBER,
   prm_mcc_code           IN       VARCHAR2,
   prm_curr_code          IN       VARCHAR2,
   prm_prod_id            IN       VARCHAR2,
   prm_expry_date         IN       VARCHAR2,
   prm_stan               IN       VARCHAR2,
   prm_mbr_numb           IN       VARCHAR2,
   prm_rvsl_code          IN       NUMBER,
   prm_ipaddress          IN       VARCHAR2,
   prm_call_id            IN       NUMBER,
   prm_ins_user           IN       NUMBER,
   prm_remark             IN       VARCHAR2,
   p_merchant_name        IN       VARCHAR2,
   p_merchant_city        IN       VARCHAR2,
   p_consodium_code       IN       VARCHAR2,
   p_partner_code         IN       VARCHAR2,
   prm_auth_id            OUT      VARCHAR2,
   prm_resp_code          OUT      VARCHAR2,
   prm_resp_msg           OUT      VARCHAR2,
   prm_capture_date       OUT      DATE
)
IS
   v_table_list       VARCHAR2 (2000);
   v_colm_list        VARCHAR2 (2000);
   v_colm_qury        VARCHAR2 (4000);
   v_old_value        VARCHAR2 (4000);
   v_new_value        VARCHAR2 (4000);
   v_value            VARCHAR2 (4000);
   v_call_seq         NUMBER (3);
   v_hash_pan         cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan         cms_appl_pan.cap_pan_code_encr%TYPE;
   v_resp_code        VARCHAR2 (3);
   v_resp_msg         VARCHAR2 (300);
   excp_rej_record    EXCEPTION;
   v_cap_acct_no      cms_appl_pan.cap_acct_no%TYPE;
   v_prod_code        cms_appl_pan.cap_prod_code%TYPE;
   v_prod_cattype     cms_appl_pan.cap_card_type%TYPE;
   v_proxynumber      cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_balance     cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_balance   cms_acct_mast.cam_ledger_bal%TYPE;
   v_spnd_acctno      cms_appl_pan.cap_acct_no%TYPE;
BEGIN
   BEGIN
      prm_resp_msg := 'OK';
      prm_resp_code := '00';

      BEGIN
         v_hash_pan := gethash (prm_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '89';
            v_resp_msg :=
                  'Error while converting pan into hash'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      BEGIN
         v_encr_pan := fn_emaps_main (prm_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '89';
            v_resp_msg :=
                  'Error while converting pan into encr '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      BEGIN
         SELECT cut_table_list, cut_colm_list, cut_colm_qury
           INTO v_table_list, v_colm_list, v_colm_qury
           FROM cms_calllogquery_mast
          WHERE cut_inst_code = prm_inst_code
            AND cut_devl_chnl = prm_delivery_channel
            AND cut_txn_code = prm_txn_code;

         DBMS_OUTPUT.put_line (v_colm_qury);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_code := '49';
            v_resp_msg := 'Column list not found in cms_calllogquery_mast ';
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            v_resp_msg :=
               'Error while finding Column list ' || SUBSTR (SQLERRM, 1, 100);
            v_resp_code := '21';
            RAISE excp_rej_record;
      END;

      BEGIN
         EXECUTE IMMEDIATE v_colm_qury
                      INTO v_old_value
                     USING prm_inst_code, v_hash_pan;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_msg :=
                  'Error while selecting old values -- '
               || '---'
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_code := '89';
            RAISE excp_rej_record;
      END;

      BEGIN
         sp_samecard_reissue (prm_inst_code,
                              prm_msg,
                              prm_rrn,
                              prm_delivery_channel,
                              prm_term_id,
                              prm_txn_code,
                              prm_txn_mode,
                              prm_tran_date,
                              prm_tran_time,
                              prm_card_no,
                              prm_bank_code,
                              prm_txn_amt,
                              prm_mcc_code,
                              prm_curr_code,
                              prm_prod_id,
                              prm_expry_date,
                              prm_stan,
                              prm_mbr_numb,
                              prm_rvsl_code,
                              prm_ipaddress,
                              prm_ins_user,
                              p_merchant_name,
                              p_merchant_city,
                              p_consodium_code,
                              p_partner_code,
                              prm_auth_id,
                              prm_resp_code,
                              prm_resp_msg,
                              prm_capture_date
                             );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '89';
            v_resp_msg :=
                 'while calling reissue process ' || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      IF prm_resp_code = '00'
      THEN
         BEGIN
            EXECUTE IMMEDIATE v_colm_qury
                         INTO v_new_value
                        USING prm_inst_code, v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_msg :=
                     'Error while selecting new values -- '
                  || '---'
                  || SUBSTR (SQLERRM, 1, 100);
               v_resp_code := '89';
               RAISE excp_rej_record;
         END;

         BEGIN
            SELECT cap_acct_no
              INTO v_spnd_acctno
              FROM cms_appl_pan
             WHERE cap_pan_code = v_hash_pan
               AND cap_inst_code = prm_inst_code
               AND cap_mbr_numb = prm_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                  'Spending Account Number Not Found For the Card in PAN Master ';
               RAISE excp_rej_record;
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                     'Error While Selecting Spending account Number for Card '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE excp_rej_record;
         END;

         BEGIN
            BEGIN
               SELECT NVL (MAX (ccd_call_seq), 0) + 1
                 INTO v_call_seq
                 FROM cms_calllog_details
                WHERE ccd_inst_code = ccd_inst_code
                  AND ccd_call_id = prm_call_id
                  AND ccd_pan_code = v_hash_pan;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_resp_msg :=
                             'record is not present in cms_calllog_details  ';
                  v_resp_code := '49';
                  RAISE excp_rej_record;
               WHEN OTHERS
               THEN
                  v_resp_msg :=
                        'Error while selecting frmo cms_calllog_details '
                     || SUBSTR (SQLERRM, 1, 100);
                  v_resp_code := '21';
                  RAISE excp_rej_record;
            END;

            INSERT INTO cms_calllog_details
                        (ccd_inst_code, ccd_call_id, ccd_pan_code,
                         ccd_call_seq, ccd_rrn, ccd_devl_chnl,
                         ccd_txn_code, ccd_tran_date, ccd_tran_time,
                         ccd_tbl_names, ccd_colm_name, ccd_old_value,
                         ccd_new_value, ccd_comments, ccd_ins_user,
                         ccd_ins_date, ccd_lupd_user, ccd_lupd_date,
                         ccd_acct_no
                        )
                 VALUES (prm_inst_code, prm_call_id, v_hash_pan,
                         v_call_seq, prm_rrn, prm_delivery_channel,
                         prm_txn_code, prm_tran_date, prm_tran_time,
                         v_table_list, v_colm_list, v_old_value,
                         v_new_value, prm_remark, prm_ins_user,
                         SYSDATE, prm_ins_user, SYSDATE,
                         v_spnd_acctno
                        );
         EXCEPTION
            WHEN excp_rej_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                     ' Error while inserting into cms_calllog_details '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE excp_rej_record;
         END;
      END IF;

      BEGIN
         UPDATE transactionlog
            SET remark = prm_remark,
                ipaddress = prm_ipaddress,
                add_lupd_user = prm_ins_user
          WHERE instcode = prm_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND business_date = prm_tran_date
            AND business_time = prm_tran_time
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code;

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                     'Txn not updated in transactiolog for remark and reason';
            RAISE excp_rej_record;
         END IF;
      EXCEPTION
         WHEN excp_rej_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while updating into transactiolog '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_rej_record;
      END;
   EXCEPTION
      WHEN excp_rej_record
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_channel
               AND cms_response_id = v_resp_code;

            prm_resp_msg := v_resp_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_msg :=
                     'Problem while selecting data from response master2 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         BEGIN
            SELECT cap_acct_no, cap_prod_code, cap_card_type,
                   cap_proxy_number
              INTO v_cap_acct_no, v_prod_code, v_prod_cattype,
                   v_proxynumber
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_inst_code AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_cap_acct_no := NULL;
               v_prod_code := NULL;
               v_prod_cattype := NULL;
               v_proxynumber := NULL;
         END;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_balance
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code
               AND cam_acct_no = v_cap_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := NULL;
               v_ledger_balance := NULL;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_customer_card_no_encr, ctd_msg_type,
                         ctd_cust_acct_number, ctd_inst_code, ctd_lupd_date,
                         ctd_lupd_user, ctd_ins_date, ctd_ins_user
                        )
                 VALUES (prm_delivery_channel, prm_txn_code, NULL,
                         prm_txn_mode, prm_tran_date, prm_tran_time,
                         v_hash_pan, NULL, prm_curr_code,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_resp_msg, prm_rrn,
                         prm_stan,
                         v_encr_pan, prm_msg,
                         v_cap_acct_no, prm_inst_code, SYSDATE,
                         prm_ins_user, SYSDATE, prm_ins_user
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log1  dtl'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         auth_id, trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, add_lupd_date,
                         add_lupd_user, add_ins_date, add_ins_user,
                         ipaddress, remark
                        )
                 VALUES (prm_msg, prm_rrn, prm_delivery_channel,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,
                                  'yyyymmdd hh24:mi:ss'
                                 ),
                         prm_txn_code, NULL, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_tran_date, prm_tran_time,
                         v_hash_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         prm_curr_code, v_prod_code, v_prod_cattype,
                         prm_auth_id, prm_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         prm_stan, prm_inst_code, 'NA',
                         v_encr_pan, v_proxynumber, '00',
                         v_cap_acct_no, v_acct_balance, v_ledger_balance,
                         v_resp_code, prm_resp_msg, SYSDATE,
                         prm_ins_user, SYSDATE, prm_ins_user,
                         prm_ipaddress, prm_remark
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log3 '
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
      WHEN OTHERS
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_channel
               AND cms_response_id = '21';

            prm_resp_msg :=
                    'Error from others exception ' || SUBSTR (SQLERRM, 1, 100);
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_msg :=
                     'Problem while selecting data from response master3 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         BEGIN
            SELECT cap_acct_no, cap_prod_code, cap_card_type,
                   cap_proxy_number
              INTO v_cap_acct_no, v_prod_code, v_prod_cattype,
                   v_proxynumber
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_inst_code AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_cap_acct_no := NULL;
               v_prod_code := NULL;
               v_prod_cattype := NULL;
               v_proxynumber := NULL;
         END;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_balance
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code
               AND cam_acct_no = v_cap_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := NULL;
               v_ledger_balance := NULL;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_customer_card_no_encr, ctd_msg_type,
                         ctd_cust_acct_number, ctd_inst_code, ctd_lupd_date,
                         ctd_lupd_user, ctd_ins_date, ctd_ins_user
                        )
                 VALUES (prm_delivery_channel, prm_txn_code, NULL,
                         prm_txn_mode, prm_tran_date, prm_tran_time,
                         v_hash_pan, NULL, prm_curr_code,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_resp_msg, prm_rrn,
                         prm_stan,
                         v_encr_pan, prm_msg,
                         v_cap_acct_no, prm_inst_code, SYSDATE,
                         prm_ins_user, SYSDATE, prm_ins_user
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log1  dtl'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         auth_id, trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, add_lupd_date,
                         add_lupd_user, add_ins_date, add_ins_user,
                         ipaddress, remark
                        )
                 VALUES (prm_msg, prm_rrn, prm_delivery_channel,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,
                                  'yyyymmdd hh24:mi:ss'
                                 ),
                         prm_txn_code, NULL, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_tran_date, prm_tran_time,
                         v_hash_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         prm_curr_code, v_prod_code, v_prod_cattype,
                         prm_auth_id, prm_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         prm_stan, prm_inst_code, 'NA',
                         v_encr_pan, v_proxynumber, '00',
                         v_cap_acct_no, v_acct_balance, v_ledger_balance,
                         v_resp_code, prm_resp_msg, SYSDATE,
                         prm_ins_user, SYSDATE, prm_ins_user,
                         prm_ipaddress, prm_remark
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log3 '
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
   END;

   DBMS_OUTPUT.put_line (prm_resp_msg);
EXCEPTION
   WHEN OTHERS
   THEN
      prm_resp_code := '89';
      prm_resp_msg := ' Error from mail' || SUBSTR (SQLERRM, 1, 100);
      RETURN;
END;
/

SHOW ERROR