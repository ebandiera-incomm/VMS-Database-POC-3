create or replace PROCEDURE        vmscms.sp_mmpos_get_txnstatus (
   p_inst_code          IN       NUMBER,
   p_msg_type           IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_pan_code           IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_tran_amount        IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_orgnl_rrn          IN       VARCHAR2,
   p_reason_code        IN       VARCHAR2,
   p_res_code           OUT      VARCHAR2,
   p_res_msg            OUT      VARCHAR2
)
AS
   v_auth_savepoint     NUMBER                                      DEFAULT 0;
   v_err_msg            VARCHAR2 (500);
   v_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
   v_txn_type           transactionlog.txn_type%TYPE;
   v_auth_id            transactionlog.auth_id%TYPE;
   exp_reject_record    EXCEPTION;
   v_dr_cr_flag         VARCHAR2 (2);
   v_tran_type          VARCHAR2 (2);
   v_tran_amt           NUMBER;
   v_prod_code          cms_appl_pan.cap_prod_code%TYPE;
   v_card_type          cms_appl_pan.cap_card_type%TYPE;
   v_resp_cde           VARCHAR2 (5);
   v_time_stamp         TIMESTAMP;
   v_hashkey_id         cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_trans_desc         cms_transaction_mast.ctm_tran_desc%TYPE;
   v_prfl_flag          cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_acct_number        cms_appl_pan.cap_acct_no%TYPE;
   v_prfl_code          cms_appl_pan.cap_prfl_code%TYPE;
   v_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_preauth_flag       cms_transaction_mast.ctm_preauth_flag%TYPE;
   v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type          cms_acct_mast.cam_type_code%TYPE;
   v_proxy_number       cms_appl_pan.cap_proxy_number%TYPE;
   v_fee_code           transactionlog.feecode%TYPE;
   v_fee_plan           transactionlog.fee_plan%TYPE;
   v_feeattach_type     transactionlog.feeattachtype%TYPE;
   v_tranfee_amt        transactionlog.tranfee_amt%TYPE;
   v_total_amt          transactionlog.total_amount%TYPE;
   v_expry_date         cms_appl_pan.cap_expry_date%TYPE;
   v_comb_hash          pkg_limits_check.type_hash;
   v_pendingrrn_count   NUMBER;
   v_login_txn          cms_transaction_mast.ctm_login_txn%TYPE;
   v_logdtl_resp        VARCHAR2 (500);
   v_cap_mbrno          cms_appl_pan.cap_mbr_numb%TYPE;
   v_rrn_count          NUMBER;
   v_txnresp_msg        transactionlog.error_msg%TYPE;
   txn_hashkey_id       cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_cur_hashkey        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_compl_fee varchar2(10);
   v_compl_feetxn_excd varchar2(10);
   v_compl_feecode varchar2(10);
   
v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
/**********************************************************************************************
               * Created Date     :20-August-2014
               * Created By       :Dhinakaran B
               * PURPOSE          : JH=3005

               * Modified Date     :20-August-2014
               * Modified By       :Dhinakaran B
               * Modified PURPOSE  : Addind the response code for 89.
			   
			    * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
/**********************************************************************************************/
BEGIN
   v_resp_cde := '1';
   v_time_stamp := SYSTIMESTAMP;

   BEGIN
      SAVEPOINT v_auth_savepoint;

      --Sn Get the HashPan
      BEGIN
         v_hash_pan := gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
               'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get the HashPan

      --Sn Create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Error while converting encrypted pan '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --Start Generate HashKEY value
      BEGIN
         v_hashkey_id :=
            gethash (   p_delivery_channel
                     || p_txn_code
                     || p_pan_code
                     || p_rrn
                     || TO_CHAR (v_time_stamp, 'YYYYMMDDHH24MISSFF5')
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while converting hashkey id data '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Generate HashKEY

      --Sn find debit and credit flag
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                ctm_preauth_flag, ctm_login_txn
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag,
                v_preauth_flag, v_login_txn
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Transflag  not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting transaction details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En find debit and credit flag

      --Sn Get the card details
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                cap_proxy_number, cap_mbr_numb
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number,
                v_proxy_number, v_cap_mbrno
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Card number not found ' || v_encr_pan;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Get the card details

      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      --En generate auth id

      --Sn Duplicate RRN Check.
      BEGIN
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)

    THEN
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE instcode = p_inst_code
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel;
ELSE
 SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE instcode = p_inst_code
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel;
END IF;
			

         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_err_msg := 'Duplicate RRN ' || ' on ' || p_tran_date;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while duplicate rrn check  '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Duplicate RRN Check
      BEGIN
         sp_cmsauth_check (p_inst_code,
                           p_msg_type,
                           p_rrn,
                           p_delivery_channel,
                           p_txn_code,
                           p_txn_mode,
                           p_tran_date,
                           p_tran_time,
                           v_cap_mbrno,
                           p_rvsl_code,
                           v_tran_type,
                           p_curr_code,
                           v_tran_amt,
                           p_pan_code,
                           v_hash_pan,
                           v_encr_pan,
                           v_card_stat,
                           v_expry_date,
                           v_prod_code,
                           v_card_type,
                           v_prfl_flag,
                           v_prfl_code,
                           NULL,
                           NULL,
                           NULL,
                           v_resp_cde,
                           v_err_msg,
                           v_comb_hash
                          );

         IF v_err_msg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error from  cmsauth Check Procedure '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_bal, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting Account  detail '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         sp_fee_calc (p_inst_code,
                      p_msg_type,
                      p_rrn,
                      p_delivery_channel,
                      p_txn_code,
                      p_txn_mode,
                      p_tran_date,
                      p_tran_time,
                      v_cap_mbrno,
                      p_rvsl_code,
                      v_txn_type,
                      p_curr_code,
                      v_tran_amt,
                      p_pan_code,
                      v_hash_pan,
                      v_encr_pan,
                      v_acct_number,
                      v_prod_code,
                      v_card_type,
                      v_preauth_flag,
                      NULL,
                      NULL,
                      NULL,
                      v_trans_desc,
                      v_dr_cr_flag,
                      v_acct_bal,
                      v_ledger_bal,
                      v_acct_type,
                      v_login_txn,
                      v_auth_id,
                      v_time_stamp,
                      v_resp_cde,
                      v_err_msg,
                      v_fee_code,
                      v_fee_plan,
                      v_feeattach_type,
                      v_tranfee_amt,
                      v_total_amt,
                      v_compl_fee,
                      v_compl_feetxn_excd,
                      v_compl_feecode
                     );

         IF v_err_msg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                       'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --Get the responsecode,and error message
      BEGIN
	  
         SELECT ctd_hashkey_id
           INTO txn_hashkey_id
           FROM VMSCMS.CMS_TRANSACTION_LOG_DTL			--Added for VMS-5733/FSP-991
          WHERE ctd_delivery_channel = p_delivery_channel
            AND ctd_customer_card_no = v_hash_pan
            AND ctd_reason_code = p_reason_code
            AND ctd_rrn = p_orgnl_rrn;
			IF SQL%ROWCOUNT = 0 THEN 
			 SELECT ctd_hashkey_id
           INTO txn_hashkey_id
           FROM VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST			--Added for VMS-5733/FSP-991
          WHERE ctd_delivery_channel = p_delivery_channel
            AND ctd_customer_card_no = v_hash_pan
            AND ctd_reason_code = p_reason_code
            AND ctd_rrn = p_orgnl_rrn;
			END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '97';
            v_err_msg := 'Original Not found, Retry  ';
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            BEGIN
               SELECT ctd_hashkey_id
                 INTO txn_hashkey_id
                 FROM VMSCMS.CMS_TRANSACTION_LOG_DTL		--Added for VMS-5733/FSP-991
                WHERE ctd_delivery_channel = p_delivery_channel
                  AND ctd_customer_card_no = v_hash_pan
                  AND ctd_reason_code = p_reason_code
                  AND ctd_rrn = p_orgnl_rrn
                  AND ctd_process_flag = 'Y';
				  IF SQL%ROWCOUNT = 0 THEN 
				  
				  SELECT ctd_hashkey_id
                 INTO txn_hashkey_id
                 FROM VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST		--Added for VMS-5733/FSP-991
                WHERE ctd_delivery_channel = p_delivery_channel
                  AND ctd_customer_card_no = v_hash_pan
                  AND ctd_reason_code = p_reason_code
                  AND ctd_rrn = p_orgnl_rrn
                  AND ctd_process_flag = 'Y';
				  END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  SELECT z.ctd_hashkey_id
                    INTO txn_hashkey_id
                    FROM (SELECT   ctd_hashkey_id
                              FROM VMSCMS.CMS_TRANSACTION_LOG_DTL			--Added for VMS-5733/FSP-991
                             WHERE ctd_delivery_channel = p_delivery_channel
                               AND ctd_customer_card_no = v_hash_pan
                               AND ctd_reason_code = p_reason_code
                               AND ctd_rrn = p_orgnl_rrn
                          ORDER BY ctd_ins_date DESC) z
                   WHERE ROWNUM = 1;
				   IF SQL%ROWCOUNT = 0 THEN 
				   SELECT z.ctd_hashkey_id
                    INTO txn_hashkey_id
                    FROM (SELECT   ctd_hashkey_id
                              FROM VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST			--Added for VMS-5733/FSP-991
                             WHERE ctd_delivery_channel = p_delivery_channel
                               AND ctd_customer_card_no = v_hash_pan
                               AND ctd_reason_code = p_reason_code
                               AND ctd_rrn = p_orgnl_rrn
                          ORDER BY ctd_ins_date DESC) z
                   WHERE ROWNUM = 1;
				   END IF;
               WHEN TOO_MANY_ROWS
               THEN
                  SELECT z.ctd_hashkey_id
                    INTO txn_hashkey_id
                    FROM (SELECT   ctd_hashkey_id
                              FROM VMSCMS.CMS_TRANSACTION_LOG_DTL			--Added for VMS-5733/FSP-991
                             WHERE ctd_delivery_channel = p_delivery_channel
                               AND ctd_customer_card_no = v_hash_pan
                               AND ctd_reason_code = p_reason_code
                               AND ctd_rrn = p_orgnl_rrn
                               AND ctd_process_flag = 'Y'
                          ORDER BY ctd_ins_date DESC) z
                   WHERE ROWNUM = 1;
				   IF SQL%ROWCOUNT = 0 THEN 
				     SELECT z.ctd_hashkey_id
                    INTO txn_hashkey_id
                    FROM (SELECT   ctd_hashkey_id
                              FROM VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST			--Added for VMS-5733/FSP-991
                             WHERE ctd_delivery_channel = p_delivery_channel
                               AND ctd_customer_card_no = v_hash_pan
                               AND ctd_reason_code = p_reason_code
                               AND ctd_rrn = p_orgnl_rrn
                               AND ctd_process_flag = 'Y'
                          ORDER BY ctd_ins_date DESC) z
                   WHERE ROWNUM = 1;
				   END IF;
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Error while  getting the response code and error mesage '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  ' Error while  getting the reason code and original rrn matching  '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --Get the responsecode,and error message
      BEGIN
         SELECT response_id
           INTO v_resp_cde
           FROM VMSCMS.TRANSACTIONLOG --Added for VMS-5733/FSP-991
          WHERE customer_card_no = v_hash_pan
            AND rrn = p_orgnl_rrn
            AND gethash (   delivery_channel
                         || txn_code
                         || p_pan_code
                         || rrn
                         || TO_CHAR (time_stamp, 'YYYYMMDDHH24MISSFF5')
                        ) = txn_hashkey_id;
						
						IF SQL%ROWCOUNT = 0 THEN 
						SELECT response_id
           INTO v_resp_cde
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE customer_card_no = v_hash_pan
            AND rrn = p_orgnl_rrn
            AND gethash (   delivery_channel
                         || txn_code
                         || p_pan_code
                         || rrn
                         || TO_CHAR (time_stamp, 'YYYYMMDDHH24MISSFF5')
                        ) = txn_hashkey_id;
						END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '97';
            v_err_msg := 'Original Not found, Retry ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while  getting the response code and error mesage '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End for responsecode,and error message

      --Sn Get responce code fomr master
      BEGIN
         SELECT DECODE (cms_iso_respcde,
                        '00', '00',
                        '01', '01',
                        '89', '05',
                        '04'
                       ),
                DECODE (cms_iso_respcde,
                        '00', 'Original Transaction Success',
                        '01', cms_resp_desc,
                        '89', 'Network Unreachable or Time Out',
                        'Original Transaction Failed, Retry'
                       )
           INTO p_res_code,
                p_res_msg
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Problem while selecting data from response master '
               || p_res_code
               || SUBSTR (SQLERRM, 1, 300);
            p_res_code := '89';
      END;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         p_res_msg := v_err_msg;
         ROLLBACK TO v_auth_savepoint;

         --Sn Get responce code fomr master
         BEGIN
            SELECT cms_iso_respcde
              INTO p_res_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Problem while selecting data from response master '
                  || p_res_code
                  || SUBSTR (SQLERRM, 1, 300);
               p_res_code := '89';
         END;
      WHEN OTHERS
      THEN
         p_res_code := '21';
         p_res_msg :=
                v_err_msg || 'Main Exception ' || SQLCODE || '---' || SQLERRM;
         ROLLBACK TO v_auth_savepoint;
   END;

   IF v_prod_code IS NULL
   THEN
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code
            AND cap_pan_code = gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO v_acct_bal, v_ledger_bal, v_acct_type
        FROM cms_acct_mast
       WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_acct_bal := 0;
         v_ledger_bal := 0;
   END;

   IF v_dr_cr_flag IS NULL
   THEN
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;

   --Sn Inserting data in transactionlog
   BEGIN
      sp_log_txnlog (p_inst_code,
                     p_msg_type,
                     p_rrn,
                     p_delivery_channel,
                     p_txn_code,
                     v_tran_type,
                     p_txn_mode,
                     p_tran_date,
                     p_tran_time,
                     p_rvsl_code,
                     v_hash_pan,
                     v_encr_pan,
                     v_err_msg,
                     NULL,
                     v_card_stat,
                     v_trans_desc,
                     NULL,
                     NULL,
                     v_time_stamp,
                     v_acct_number,
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     v_acct_bal,
                     v_ledger_bal,
                     v_acct_type,
                     v_proxy_number,
                     v_auth_id,
                     v_tran_amt,
                     v_total_amt,
                     v_fee_code,
                     v_tranfee_amt,
                     v_fee_plan,
                     v_feeattach_type,
                     v_resp_cde,
                     p_res_code,
                     p_curr_code,
                     v_err_msg,
                     p_orgnl_rrn
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_res_code := '89';
         v_err_msg :=
                   'Exception while inserting to transaction log ' || SQLERRM;
   END;

   --En Inserting data in transactionlog

   --Sn Inserting data in transactionlog dtl
   BEGIN
      sp_log_txnlogdetl (p_inst_code,
                         p_msg_type,
                         p_rrn,
                         p_delivery_channel,
                         p_txn_code,
                         v_txn_type,
                         p_txn_mode,
                         p_tran_date,
                         p_tran_time,
                         v_hash_pan,
                         v_encr_pan,
                         v_err_msg,
                         v_acct_number,
                         v_auth_id,
                         v_tran_amt,
                         NULL,
                         NULL,
                         v_hashkey_id,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         p_res_code,
                         NULL,
                         p_reason_code,
                         NULL,
                         v_logdtl_resp
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_res_code := '89';
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_res_code := '69';                                  -- Server Declined
      p_res_msg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error;