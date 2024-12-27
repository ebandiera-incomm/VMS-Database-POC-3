CREATE OR REPLACE PROCEDURE vmscms.sp_csr_startercard_link (
   p_inst_code                NUMBER,
   p_mbr_numb                 VARCHAR2,
   p_msg_type                 VARCHAR2,
   p_curr_code                VARCHAR2,
   p_rrn                      VARCHAR2,
   p_stan                     VARCHAR2,
   p_gpr_card_no              VARCHAR2,
   p_starter_card_no          VARCHAR2,
   p_delivery_channel         VARCHAR2,
   p_txn_code                 VARCHAR2,
   p_txn_mode                 VARCHAR2,
   p_tran_date                VARCHAR2,
   p_tran_time                VARCHAR2,
   p_reason_code              NUMBER,
   p_remark                   VARCHAR2,
   p_call_id                  NUMBER,
   p_ipaddress 				  VARCHAR2, --added by amit on 06-Oct-2012
   p_ins_user                 NUMBER,
   p_resp_code          OUT   VARCHAR2,
   p_resp_msg           OUT   VARCHAR2
)
IS
/**********************************************************************************************
  * VERSION                    :  1.0
  * DATE OF CREATION          : 9/May/2012
  * PURPOSE                   : Call logging for starter card linking process
  * CREATED BY                : Sagar More
  * MODIFICATION REASON       : New parameter IP addrees and log ip address,remark in transactionlog table
  * LAST MODIFICATION DONE BY : Amit Sonar
  * LAST MODIFICATION DATE    : 06-Oct-2012
  * Build Number              : RI0019_B0008
**************************************************************************************************/
   v_table_list              VARCHAR2 (2000);
   v_colm_list               VARCHAR2 (2000);
   v_colm_qury               VARCHAR2 (4000);
   v_old_value               VARCHAR2 (4000);
   v_gprcard_old_value       VARCHAR2 (4000);
   v_startercard_old_value   VARCHAR2 (4000);
   v_new_value               VARCHAR2 (4000);
   v_value                   VARCHAR2 (4000);
   v_call_seq                NUMBER (3);
   v_resp_code               VARCHAR2 (3);
   v_resp_msg                VARCHAR2 (300);
   excp_rej_record           EXCEPTION;
   v_cap_acct_no             cms_appl_pan.cap_acct_no%TYPE;
   v_prod_code               cms_appl_pan.cap_prod_code%TYPE;
   v_prod_cattype            cms_appl_pan.cap_card_type%TYPE;
   v_proxynumber             cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_balance            cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal              cms_acct_mast.cam_ledger_bal%TYPE;
   v_new_detl_gpr_card       VARCHAR2 (2000);
   v_new_card_value          VARCHAR2 (2000);
   v_hash_starter_pan        cms_appl_pan.cap_pan_code%TYPE;
   v_hash_gpr_pan            cms_appl_pan.cap_pan_code%TYPE;
   v_encr_gpr_pan            cms_appl_pan.cap_pan_code_encr%TYPE;
   v_encr_starter_pan        cms_appl_pan.cap_pan_code_encr%TYPE;
   exp_reject_record         EXCEPTION;
   v_spnd_acctno             cms_appl_pan.cap_acct_no%TYPE;
                                              -- ADDED BY GANESH ON 19-JUL-12
BEGIN
   BEGIN
      v_resp_msg := 'OK';
      v_resp_code := '00';

      BEGIN
         v_hash_gpr_pan := gethash (p_gpr_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while converting gpr pan into hash'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_hash_starter_pan := gethash (p_starter_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '120';
            v_resp_msg :=
                  'Error while converting starter pan into hash'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_encr_gpr_pan := fn_emaps_main (p_gpr_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                'Error while encrypting gpr pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_encr_starter_pan := fn_emaps_main (p_starter_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '120';
            v_resp_msg :=
                  'Error while encrypting starter pan '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      /*  call log info   start */
      BEGIN
         SELECT cut_table_list, cut_colm_list, cut_colm_qury
           INTO v_table_list, v_colm_list, v_colm_qury
           FROM cms_calllogquery_mast
          WHERE cut_inst_code = p_inst_code
            AND cut_devl_chnl = p_delivery_channel
            AND cut_txn_code = p_txn_code;

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
               'Error while fetching Column list '
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_code := '21';
            RAISE excp_rej_record;
      END;

      BEGIN
         EXECUTE IMMEDIATE v_colm_qury
                      INTO v_gprcard_old_value
                     USING p_inst_code, v_hash_gpr_pan;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_msg :=
                  'Error while selecting old values of gpr card -- '
               || '---'
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_code := '89';
            RAISE excp_rej_record;
      END;

      BEGIN
         EXECUTE IMMEDIATE v_colm_qury
                      INTO v_startercard_old_value
                     USING p_inst_code, v_hash_gpr_pan;

         v_old_value :=
               'GPRCARD DETAILS - '
            || v_gprcard_old_value
            || ' '
            || 'STARTERCARD DETAILS - '
            || v_startercard_old_value;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_msg :=
                  'Error while selecting old values of starter card -- '
               || '---'
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_code := '89';
            RAISE excp_rej_record;
      END;

      BEGIN
         sp_startercard_link_process (p_inst_code,
                                      p_mbr_numb,
                                      p_msg_type,
                                      p_curr_code,
                                      p_rrn,
                                      p_stan,
                                      p_gpr_card_no,
                                      p_starter_card_no,
                                      p_delivery_channel,
                                      p_txn_code,
                                      p_txn_mode,
                                      p_tran_date,
                                      p_tran_time,
                                      p_reason_code,
                                      p_remark,
                                      p_ins_user,
                                      p_resp_code,
                                      p_resp_msg
                                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '89';
            v_resp_msg :=
                  'while calling card linking process '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      IF p_resp_code = '00'
      THEN
         BEGIN
            EXECUTE IMMEDIATE v_colm_qury
                         INTO v_new_detl_gpr_card
                        USING p_inst_code, v_hash_gpr_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_msg :=
                     'Error while selecting new details of gpr card -- '
                  || '---'
                  || SUBSTR (SQLERRM, 1, 100);
               v_resp_code := '21';
               RAISE excp_rej_record;
         END;

         BEGIN
            EXECUTE IMMEDIATE v_colm_qury
                         INTO v_new_card_value
                        USING p_inst_code, v_hash_starter_pan;

            v_new_value :=
                  'GPRCARD DETAILS - '
               || v_new_detl_gpr_card
               || ' '
               || 'STARTERCARD DETAILS - '
               || v_new_card_value;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_msg :=
                     'Error while selecting values of starter card -- '
                  || '---'
                  || SUBSTR (SQLERRM, 1, 100);
               v_resp_code := '21';
               RAISE excp_rej_record;
         END;

-- SN : ADDED BY Ganesh on 18-JUL-12
         BEGIN
            SELECT cap_acct_no
              INTO v_spnd_acctno
              FROM cms_appl_pan
             WHERE cap_pan_code = v_hash_gpr_pan
               AND cap_inst_code = p_inst_code
               AND cap_mbr_numb = p_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                  'Spending Account Number Not Found For the Card in PAN Master ';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                     'Error While Selecting Spending account Number for Card '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;

-- EN : ADDED BY Ganesh on 18-JUL-12
         BEGIN
            BEGIN
               SELECT NVL (MAX (ccd_call_seq), 0) + 1
                 INTO v_call_seq
                 FROM cms_calllog_details
                WHERE ccd_inst_code = ccd_inst_code
                  AND ccd_call_id = p_call_id
                  AND ccd_pan_code = v_hash_gpr_pan;
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
                         ccd_call_seq, ccd_rrn, ccd_devl_chnl, ccd_txn_code,
                         ccd_tran_date, ccd_tran_time, ccd_tbl_names,
                         ccd_colm_name, ccd_old_value, ccd_new_value,
                         ccd_comments, ccd_ins_user, ccd_ins_date,
                         ccd_lupd_user, ccd_lupd_date,
                         ccd_acct_no
                                 -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                        )
                 VALUES (p_inst_code, p_call_id, v_hash_gpr_pan,
                         v_call_seq, p_rrn, p_delivery_channel, p_txn_code,
                         p_tran_date, p_tran_time, v_table_list,
                         v_colm_list, v_old_value, v_new_value,
                         p_remark, p_ins_user, SYSDATE,
                         p_ins_user, SYSDATE,
                         v_spnd_acctno
                               -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
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
	  
	  ---Sn to log ipaddress,lupduser and remark in transaction log table for successful record. added by amit on 06-Oct-2012 
		BEGIN 
         UPDATE transactionlog
            SET remark = p_remark,
			    ipaddress = p_ipaddress				
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_gpr_pan
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND business_time = p_tran_time
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code;

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                     'Txn not updated in transactiolog for remark,ipaddress';
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
   ---En to log ipaddress,lupduser and remark in transaction log table for successful record.
----------------------------------------------------------------------------------------------------------------------------------------------------
   EXCEPTION
      WHEN exp_reject_record
      THEN
         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_code;

            p_resp_msg := v_resp_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master1 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '89';
               ROLLBACK;
               RETURN;
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
                 VALUES (p_delivery_channel, p_txn_code, NULL,
                         p_txn_mode, p_tran_date, p_tran_time,
                         v_hash_gpr_pan, NULL, p_curr_code,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_resp_msg, p_rrn,
                         p_stan,
                         v_encr_gpr_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code, SYSDATE,
                         p_ins_user, SYSDATE, p_ins_user
                        );

            p_resp_msg := v_resp_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction_log_dtl1'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

         BEGIN
            SELECT cap_acct_no, cap_prod_code, cap_card_type,
                   cap_proxy_number
              INTO v_cap_acct_no, v_prod_code, v_prod_cattype,
                   v_proxynumber
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code
               AND cap_pan_code = v_hash_gpr_pan;
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
              INTO v_acct_balance, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status, response_code,
                         business_date, business_time, customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid, trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, add_lupd_date,
                         add_lupd_user, add_ins_date, add_ins_user,
						 remark,  --added by amit on 06-Oct-2012 to log remark in transactionlog table
						 ipaddress  --added by amit on 06-Oct-2012 to log ip address in transactionlog table
                        )
                 VALUES (p_msg_type, p_rrn, p_delivery_channel,
                         TO_DATE (p_tran_date || ' ' || p_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         p_txn_code, NULL, p_txn_mode,
                         DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                         p_tran_date, p_tran_time, v_hash_gpr_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         p_curr_code, v_prod_code, v_prod_cattype, p_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         p_stan, p_inst_code, 'NA',
                         v_encr_gpr_pan, v_proxynumber,
                         v_cap_acct_no, v_acct_balance, v_ledger_bal,
                         v_resp_code, v_resp_msg, SYSDATE,
                         p_ins_user, SYSDATE, p_ins_user,
						 p_remark, --added by amit on 06-Oct-2012 to log remark in transactionlog table
						 p_ipaddress --added by amit on 06-Oct-2012 to log ip address in transactionlog table
                        );

            p_resp_msg := v_resp_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transactionlog1 '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;
      WHEN OTHERS
      THEN
         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_code;

            p_resp_msg := v_resp_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master1 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '89';
               ROLLBACK;
               RETURN;
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
                 VALUES (p_delivery_channel, p_txn_code, NULL,
                         p_txn_mode, p_tran_date, p_tran_time,
                         v_hash_gpr_pan, NULL, p_curr_code,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_resp_msg, p_rrn,
                         p_stan,
                         v_encr_gpr_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code, SYSDATE,
                         p_ins_user, SYSDATE, p_ins_user
                        );

            p_resp_msg := v_resp_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction_log_dtl2'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

         BEGIN
            SELECT cap_acct_no, cap_prod_code, cap_card_type,
                   cap_proxy_number
              INTO v_cap_acct_no, v_prod_code, v_prod_cattype,
                   v_proxynumber
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code
               AND cap_pan_code = v_hash_gpr_pan;
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
              INTO v_acct_balance, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status, response_code,
                         business_date, business_time, customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid, trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, add_lupd_date,
                         add_lupd_user, add_ins_date, add_ins_user
                        )
                 VALUES (p_msg_type, p_rrn, p_delivery_channel,
                         TO_DATE (p_tran_date || ' ' || p_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         p_txn_code, NULL, p_txn_mode,
                         DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                         p_tran_date, p_tran_time, v_hash_gpr_pan,
                         TRIM (TO_CHAR (0, '99999999999999990.99')),
                         p_curr_code, v_prod_code, v_prod_cattype, p_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         p_stan, p_inst_code, 'NA',
                         v_encr_gpr_pan, v_proxynumber,
                         v_cap_acct_no, v_acct_balance, v_ledger_bal,
                         v_resp_code, v_resp_msg, SYSDATE,
                         p_ins_user, SYSDATE, p_ins_user
                        );

            p_resp_msg := v_resp_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transactionlog2 '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      p_resp_msg := 'Exception occured in mail ' || SUBSTR (SQLERRM, 1, 100);
      p_resp_code := '89';
END;
/