create or replace
PACKAGE BODY        VMSCMS.VMSCSD
AS
   PROCEDURE rollback_card_status (
      p_instcode_in        IN       NUMBER,
      p_rrn_in             IN       VARCHAR2,
      p_pan_code_in        IN       VARCHAR2,
      p_lupduser_in        IN       NUMBER,
      p_txn_code_in        IN       VARCHAR2, 
      p_delivery_chnl_in   IN       VARCHAR2,
      p_msg_type_in        IN       VARCHAR2,
      p_revrsl_code_in     IN       VARCHAR2,
      p_txn_mode_in        IN       VARCHAR2,
      p_mbrnumb_in         IN       VARCHAR2,
      p_trandate_in        IN       VARCHAR2,
      p_trantime_in        IN       VARCHAR2,
      p_remark_in          IN       VARCHAR2,
      p_call_id_in         IN       VARCHAR2,
      p_ip_addr_in         IN       VARCHAR2,
      p_schd_flag_in       IN       VARCHAR2,
      p_curr_code_in       IN       VARCHAR2,
      p_resp_code_out      OUT      VARCHAR2,
      p_errmsg_out         OUT      VARCHAR2
   )
   AS
         /****************************************************************************************
          * Created Date      : 24-Aug-15
          * Created By        :  Abdul Hameed M.A
          * Purpose           : To rollback the old card status from CSR(FSS-3589)
          * Reviewer          : Spankaj
          * Reviewed Date     : 24-Aug-15
          * Build Number      : VMSGPRCSD3.1_B0005
          
          * Modified Date     : 10-Oct-17
          * Modified By       : Ramesh
          * Purpose           : FSS-5225(Consumed Card status)
          * Reviewer          : Saravanakumar
          * Reviewed Date     : 16-Oct-17
          * Build Number      : VMSGPRCSD17.10_B0002
          
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-4-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
      ******************************************************************************************/
      l_cap_prod_catg          cms_appl_pan.cap_prod_catg%TYPE;
      l_prod_code              cms_appl_pan.cap_prod_code%TYPE;
      l_card_type              cms_appl_pan.cap_card_type%TYPE;
      l_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
      l_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
      l_spprt_key              cms_spprt_reasons.csr_spprt_key%TYPE;
      l_errmsg                 VARCHAR2 (300);
      l_respcode               VARCHAR2 (5);
      exp_main_reject_record   EXCEPTION;
      l_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
      l_rrn_count              NUMBER;
      l_tran_date              DATE;
      l_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_number            cms_appl_pan.cap_acct_no%TYPE;
      l_acct_balance           NUMBER;
      l_ledger_balance         NUMBER;
      l_resp_cde               VARCHAR2 (2);
      l_new_value              VARCHAR2 (2000);
      l_call_seq               NUMBER (3);
      l_reason                 cms_spprt_reasons.csr_reasondesc%TYPE;
      l_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
      l_cr_dr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_auth_savepoint         NUMBER                               DEFAULT 0;
      l_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_auth_id                transactionlog.auth_id%TYPE;
      l_acct_type              cms_acct_mast.cam_type_code%TYPE;
      l_txn_type               transactionlog.txn_type%TYPE;
      l_time_stamp             TIMESTAMP;
      l_tran_type              VARCHAR2 (2);
      l_tran_amt               NUMBER;
      l_logdtl_resp            VARCHAR2 (500);
      v_Retperiod  date; --Added for VMS-5733/FSP-991
      v_Retdate  date; --Added for VMS-5733/FSP-991
   BEGIN
      l_respcode := '1';
      l_errmsg := 'OK';
      l_tran_amt := '0.00';
      l_time_stamp := SYSTIMESTAMP;

      BEGIN
         SAVEPOINT l_auth_savepoint;

         --SN CREATE HASH PAN
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_errmsg :=
                    'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         --EN CREATE HASH PAN
         --SN create encr pan
         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_errmsg :=
                    'Error while converting encr  pan ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         --EN create encr pan

         --Start Generate HashKEY value
         BEGIN
            l_hashkey_id :=
               gethash (   p_delivery_chnl_in
                        || p_txn_code_in
                        || p_pan_code_in
                        || p_rrn_in
                        || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_errmsg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         --End Generate HashKEY

         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc
              INTO l_cr_dr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_chnl_in
               AND ctm_inst_code = p_instcode_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_respcode := '12';
               l_errmsg :=
                     'Transflag  not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_chnl_in;
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_errmsg := 'Error while selecting transaction details';
               RAISE exp_main_reject_record;
         END;

         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO l_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_respcode := '21';                         -- Server Declined
               RAISE exp_main_reject_record;
         END;

         --En generate auth id

         --Sn Duplicate RRN Check
         BEGIN
         --Added for VMS-5733/FSP-991

v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate_in), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

IF (v_Retdate>v_Retperiod)
    THEN
            SELECT COUNT (1)
              INTO l_rrn_count
              FROM transactionlog
             WHERE instcode = p_instcode_in
               AND customer_card_no = l_hash_pan
               AND rrn = p_rrn_in
               AND delivery_channel = p_delivery_chnl_in
               AND txn_code = p_txn_code_in
               AND business_date = p_trandate_in
               AND business_time = p_trantime_in;
             ELSE
                    SELECT COUNT (1)
              INTO l_rrn_count
              FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
             WHERE instcode = p_instcode_in
               AND customer_card_no = l_hash_pan
               AND rrn = p_rrn_in
               AND delivery_channel = p_delivery_chnl_in
               AND txn_code = p_txn_code_in
               AND business_date = p_trandate_in
               AND business_time = p_trantime_in;
            END IF;   
               

            IF l_rrn_count > 0
            THEN
               l_respcode := '22';
               l_errmsg := 'Duplicate RRN ' || p_rrn_in;
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'while cheking for duplicate RRN '
                  || p_rrn_in
                  || ' '
                  || SUBSTR (SQLERRM, 1, 100);
               l_respcode := '32';
               RAISE exp_main_reject_record;
         END;

         --En Duplicate RRN Check
         BEGIN
            l_tran_date :=
               TO_DATE (   SUBSTR (TRIM (p_trandate_in), 1, 8)
                        || ' '
                        || SUBSTR (TRIM (p_trantime_in), 1, 10),
                        'yyyymmdd hh24:mi:ss'
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_respcode := '32';
               l_errmsg :=
                     'Problem while converting transaction Time '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         --Sn select Pan detail
         BEGIN
            SELECT cap_prod_catg, cap_card_stat, cap_prod_code,
                   cap_card_type, cap_proxy_number, cap_acct_no,CAP_OLD_CARDSTAT
              INTO l_cap_prod_catg, l_cap_card_stat, l_prod_code,
                   l_card_type, l_proxunumber, l_acct_number,l_new_value
              FROM cms_appl_pan
             WHERE cap_pan_code = l_hash_pan
               AND cap_inst_code = p_instcode_in
               AND cap_mbr_numb = p_mbrnumb_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_respcode := '16';
               l_errmsg := 'Card not found in master ' || l_hash_pan;
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_errmsg :=
                     'Error while selecting card number '
                  || l_hash_pan
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_main_reject_record;
         END;

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_balance, l_ledger_balance, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_instcode_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_errmsg :=
                     'Problem while selecting Account  detail '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_main_reject_record;
         END;

         BEGIN
            SELECT DECODE (l_new_value,
                           '2', 'HTLST',
                           '3', 'HTLST',
                           '7', 'CARDEXPIRED',
                           '14', 'SPENDDOWN',
                           '0', 'CARDINACTIVE',
                           '6', 'BLOCK',
                           '9', 'CARDCLOSE',
                           '1', 'CARDACTIVE',
                           '5', 'MONITORED',
                           '11', 'HOTCARDED',
                           '16', 'RETMAIL',
                           '4', 'RESTRICT',
                                 '12','SUSPCREDIT',
                                 '13','ACTUNREG',
                                 '8','PASSIVE',
                     '15','FRAUDHOLD' ,
                     '17','CONSUMED' --Added for FSS-5225(Consumed Card status)
                          )
              INTO l_spprt_key
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_errmsg :=
                     'Error while selecting spprt key   for txn code'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         BEGIN
            SELECT csr_spprt_rsncode, csr_reasondesc
              INTO l_resoncode, l_reason
              FROM cms_spprt_reasons
             WHERE csr_spprt_key = l_spprt_key
               AND csr_inst_code = p_instcode_in
               AND ROWNUM < 2;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_respcode := '21';
               l_errmsg := 'Change status reason code not present in master';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_errmsg :=
                     'Error while selecting reason code from master'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         IF p_schd_flag_in = 'N'
         THEN
            BEGIN
               BEGIN
                  SELECT NVL (MAX (ccd_call_seq), 0) + 1
                    INTO l_call_seq
                    FROM cms_calllog_details
                   WHERE ccd_inst_code = p_instcode_in
                     AND ccd_call_id = p_call_id_in
                     AND ccd_pan_code = l_hash_pan;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     l_errmsg :=
                             'record is not present in cms_calllog_details  ';
                     l_respcode := '16';
                     RAISE exp_main_reject_record;
                  WHEN OTHERS
                  THEN
                     l_errmsg :=
                           'Error while selecting frmo cms_calllog_details '
                        || SUBSTR (SQLERRM, 1, 100);
                     l_respcode := '21';
                     RAISE exp_main_reject_record;
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
                    VALUES (p_instcode_in, p_call_id_in, l_hash_pan,
                            l_call_seq, p_rrn_in, p_delivery_chnl_in,
                            p_txn_code_in, p_trandate_in, p_trantime_in,
                            'CMS_APPL_PAN', 'CAP_CARD_STAT', l_cap_card_stat,
                            NULL, p_remark_in, p_lupduser_in,
                            SYSDATE, p_lupduser_in, SYSDATE,
                            l_acct_number
                           );
            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_respcode := '21';
                  l_errmsg :=
                        ' Error while inserting into cms_calllog_details '
                     || SQLERRM;
                  RAISE exp_main_reject_record;
            END;
         /*  call log info   END */
         END IF;

         BEGIN
            UPDATE cms_appl_pan
               SET cap_card_stat = cap_old_cardstat
             WHERE cap_inst_code = p_instcode_in
               AND cap_pan_code = l_hash_pan
               AND cap_mbr_numb = p_mbrnumb_in;

            IF SQL%ROWCOUNT != 1
            THEN
               l_respcode := '21';
               l_errmsg :=
                     'Problem In Updation Of Status For Pan '
                  || fn_mask (p_pan_code_in, 'X', 7, 6)
                  || '.';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_errmsg :=
                     'Error ocurs while updating card status-- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         IF l_errmsg = 'OK' AND l_new_value = '9'
         THEN
            BEGIN
               sp_log_cardstat_chnge (p_instcode_in,
                                      l_hash_pan,
                                      l_encr_pan,
                                      l_auth_id,
                                      '02',
                                      p_rrn_in,
                                      p_trandate_in,
                                      p_trantime_in,
                                      l_respcode,
                                      l_errmsg
                                     );

               IF l_respcode <> '00' AND l_errmsg <> 'OK'
               THEN
                  RAISE exp_main_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_respcode := '21';
                  l_errmsg :=
                        'Error while logging system initiated card status change '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;
         END IF;

         BEGIN
            INSERT INTO cms_pan_spprt
                        (cps_inst_code, cps_pan_code, cps_mbr_numb,
                         cps_prod_catg,
                         cps_spprt_key,
                         cps_spprt_rsncode, cps_func_remark, cps_ins_user,
                         cps_lupd_user, cps_cmd_mode, cps_pan_code_encr
                        )
                 VALUES (p_instcode_in, l_hash_pan, p_mbrnumb_in,
                         l_cap_prod_catg,
                         DECODE (l_new_value,
                                 '2', 'HTLST',
                                 '3', 'HTLST',
                                 '7', 'CEXPIRED',
                                 '14', 'SPENDDOWN',
                                 '0', 'INACTIVE',
                                 '6', 'BLOCK',
                                 '9', 'CARDCLOSE',
                                 '1', 'CARDACTIVE',
                                 '5', 'MONITORED',
                                 '11', 'HOTCARDED',
                                 '16', 'RETMAIL',
                                 '4', 'RESTRICT',
                                 '12','SUSPCREDIT',
                                 '13','ACTUNREG',
                                 '8','PASSIVE',
                                 '15','FRAUDHOLD',
                                 '17','CONSUMED' --Added for FSS-5225(Consumed Card status)
                                ),
                         l_resoncode, p_remark_in, p_lupduser_in,
                         p_lupduser_in, 0, l_encr_pan
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_respcode := '21';
               l_errmsg :=
                     'Error while inserting records into card support master'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         BEGIN
            UPDATE cms_calllog_details
               SET ccd_new_value = l_new_value
             WHERE ccd_inst_code = ccd_inst_code
               AND ccd_call_id = p_call_id_in
               AND ccd_pan_code = l_hash_pan
               AND ccd_rrn = p_rrn_in;

            IF SQL%ROWCOUNT = 0
            THEN
               l_errmsg :=
                       'call log details is not updated for ' || p_call_id_in;
               l_respcode := '16';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'Error while updating call log details   '
                  || SUBSTR (SQLERRM, 1, 100);
               l_respcode := '21';
               RAISE exp_main_reject_record;
         END;

         l_respcode := '1';
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_respcode := '21';
            l_errmsg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;

      --Sn get record for successful transaction
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode_in
            AND cms_delivery_channel = p_delivery_chnl_in
            AND cms_response_id = l_respcode;
      --   p_errmsg_out := l_errmsg;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_errmsg :=
                  'Problem while selecting data from response master1 '
               || l_resp_cde
               || SUBSTR (SQLERRM, 1, 100);
            p_resp_code_out := '89';
      END;

      --En Get responce code fomr master
      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO l_cap_card_stat, l_prod_code, l_card_type, l_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode_in
               AND cap_pan_code = gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_balance, l_ledger_balance, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number AND cam_inst_code = p_instcode_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_balance := 0;
            l_ledger_balance := 0;
      END;

      IF l_cr_dr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc
              INTO l_cr_dr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_chnl_in
               AND ctm_inst_code = p_instcode_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_instcode_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_chnl_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        p_trandate_in,
                        p_trantime_in,
                        p_revrsl_code_in,
                        l_hash_pan,
                        l_encr_pan,
                        l_errmsg,
                        p_ip_addr_in,
                        l_cap_card_stat,
                        l_trans_desc,
                        NULL,
                        NULL,
                        l_time_stamp,
                        l_acct_number,
                        l_prod_code,
                        l_card_type,
                        l_cr_dr_flag,
                        l_acct_balance,
                        l_ledger_balance,
                        l_acct_type,
                        l_proxunumber,
                        l_auth_id,
                        l_tran_amt,
                        '0.00',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        l_respcode,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_errmsg,
                        NULL,
                        NULL,
                        p_remark_in,
                        l_reason,
                        p_lupduser_in,
                        p_lupduser_in
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            l_errmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         sp_log_txnlogdetl (p_instcode_in,
                            p_msg_type_in,
                            p_rrn_in,
                            p_delivery_chnl_in,
                            p_txn_code_in,
                            l_txn_type,
                            p_txn_mode_in,
                            p_trandate_in,
                            p_trantime_in,
                            l_hash_pan,
                            l_encr_pan,
                            l_errmsg,
                            l_acct_number,
                            l_auth_id,
                            l_tran_amt,
                            NULL,
                            NULL,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_resp_code_out,
                            NULL,
                            NULL,
                            NULL,
                            l_logdtl_resp
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      p_errmsg_out := l_errmsg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_errmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;
END VMSCSD;
/
show error