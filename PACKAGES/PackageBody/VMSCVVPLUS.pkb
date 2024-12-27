create or replace
PACKAGE BODY               vmscms.VMSCVVPLUS IS

   -- Private type declarations

   -- Private constant declarations

   -- Private variable declarations

   -- Function and procedure implementations
   
   
   PROCEDURE  registration (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_curr_code_in                in  	varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_ip_address_in               in    varchar2,
          p_mobile_no_in                in    varchar2,
          p_device_id_in                in    varchar2,
          p_auth_id_out                 out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2,
        --  p_cell_no_out                 out   varchar2,
        --  p_email_id_out                out   varchar2,
          p_processor_card_token_out    out   varchar2
          
   )
   IS
      /************************************************************************************************************
       * Created Date     :  19-April-2017
       * Created By       :  MageshKumar
       * Created For      :  CVV PLUS REGISTRATION
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD_17.04_B0003
  
      ************************************************************************************************************/
      l_auth_savepoint       NUMBER                                 DEFAULT 0;
      l_err_msg              VARCHAR2 (500);
      l_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type             transactionlog.txn_type%TYPE;
      l_dr_cr_flag           VARCHAR2 (2);
      l_tran_type            VARCHAR2 (2);
      l_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_card_type            cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde             VARCHAR2 (5);
      l_time_stamp           TIMESTAMP;
      l_hashkey_id           cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_trans_desc           cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag            cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_acct_number          cms_appl_pan.cap_acct_no%TYPE;
      l_prfl_code            cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat            cms_appl_pan.cap_card_stat%TYPE;
      l_cust_code            cms_appl_pan.cap_cust_code%TYPE;
      l_preauth_flag         cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type            cms_acct_mast.cam_type_code%TYPE;
      l_proxy_number         cms_appl_pan.cap_proxy_number%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      l_login_txn            cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp          VARCHAR2 (500);
      l_preauth_type         cms_transaction_mast.ctm_preauth_type%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_exp_reject_record      EXCEPTION;
      l_rrn_count            NUMBER;
      v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991


   BEGIN
      l_resp_cde := '1';
      l_err_msg := 'OK';
      l_time_stamp := SYSTIMESTAMP;
      BEGIN
         SAVEPOINT l_auth_savepoint;
       
         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE l_exp_reject_record;
         END;
         --En Get the HashPan
         --Sn Create encr pan
         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while converting emcrypted pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE l_exp_reject_record;
         END;
         ---En Create encr pan
         
         --Start Generate HashKEY value
         BEGIN
            l_hashkey_id :=
               gethash (   p_delivery_channel_in
                        || p_txn_code_in
                        || p_pan_code_in
                        || p_rrn_in
                        || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE l_exp_reject_record;
         END;
         --End Generate HashKEY
         
           
         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn, ctm_preauth_type
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag, l_login_txn, l_preauth_type
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE l_exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details'|| SUBSTR (SQLERRM, 1, 300);
               RAISE l_exp_reject_record;
         END;
         --En find debit and credit flag
         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO p_auth_id_out
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';                         -- Server Declined
               RAISE l_exp_reject_record;
         END;
         --En generate auth id
         
         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code
              FROM cms_appl_pan
             WHERE 
             cap_inst_code = p_inst_code_in 
             AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE l_exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE l_exp_reject_record;
         END;
         --End Get the card details
          BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14'; 
           l_err_msg  := 'Invalid Card ';
           RAISE l_exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE l_exp_reject_record;
         END;
         
          BEGIN
		  --Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date_in), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN
			 SELECT COUNT (1)
			   INTO l_rrn_count
			   FROM transactionlog
			  WHERE  rrn = p_rrn_in
				AND delivery_channel = p_delivery_channel_in
				 AND instcode = p_inst_code_in
				AND business_date = p_tran_date_in;
	ELSE
			SELECT COUNT (1)
			   INTO l_rrn_count
			   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
			  WHERE  rrn = p_rrn_in
				AND delivery_channel = p_delivery_channel_in
				 AND instcode = p_inst_code_in
				AND business_date = p_tran_date_in;
	END IF;			

         IF l_rrn_count > 0
         THEN
            l_resp_cde := '22';
            l_err_msg := 'Duplicate RRN found' || p_rrn_in;
            RAISE l_exp_reject_record;
         END IF;
      END;
         IF p_delivery_channel_in <> '06' THEN
     
          BEGIN
            sp_cmsauth_check (p_inst_code_in,
                              p_msg_type_in,
                              p_rrn_in,
                              p_delivery_channel_in,
                              p_txn_code_in,
                              p_txn_mode_in,
                              p_tran_date_in,
                              p_tran_time_in,
                              p_mbr_numb_in,
                              p_rvsl_code_in,
                              l_tran_type,
                              p_curr_code_in,
                              NULL,
                              p_pan_code_in,
                              l_hash_pan,
                              l_encr_pan,
                              l_card_stat,
                              l_expry_date,
                              l_prod_code,
                              l_card_type,
                              l_prfl_flag,
                              l_prfl_code,
                              NULL,
                              NULL,
                              NULL,
                              l_resp_cde,
                              l_err_msg,
                              l_comb_hash
                             );
            IF l_err_msg <> 'OK'
            THEN
               RAISE l_exp_reject_record;
            END IF;
         EXCEPTION
            WHEN l_exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE l_exp_reject_record;
         END;
         
         END IF;
         
        

     /* BEGIN

           SELECT CAM_MOBL_ONE,CAM_EMAIL into p_cell_no_out,p_email_id_out
           FROM CMS_ADDR_MAST
           WHERE CAM_INST_CODE = p_inst_code_in
           AND CAM_CUST_CODE   = l_cust_code
           AND CAM_ADDR_FLAG   = 'P';
           
           EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   l_resp_cde := '21';
                   l_err_msg := 'cellphone no and email id not found for customer id';
                   RAISE l_exp_reject_record;
                 WHEN OTHERS THEN
                   l_resp_cde := '21';
                   l_err_msg := 'Error while selecting cellphone no and email id for physical address' || 
                   SUBSTR (SQLERRM, 1, 200);
                   RAISE l_exp_reject_record;
           END;

        
         
         if p_cell_no_out IS NULL AND p_email_id_out IS NULL then
         l_resp_cde := '21';
                   l_err_msg := 'cellphone no and email id not found for customer id';
                   RAISE l_exp_reject_record;
         end if;*/
         
         BEGIN
         
         SELECT TO_CHAR (TO_CHAR (SYSDATE, 'YYMMDDHH24MISS')|| LPAD (SEQ_CVVPLUS_TOKEN.NEXTVAL, 3, '0')) INTO
         p_processor_card_token_out FROM DUAL;

         EXCEPTION 
         WHEN OTHERS THEN
         l_resp_cde := '21';
         l_err_msg := 'Error while getting processor card token';
         RAISE l_exp_reject_record;
         
         END;
         
         l_resp_cde := '1';
     EXCEPTION
         WHEN l_exp_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;
   --Sn Get responce code from  master
         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem while selecting data from response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
         END;
      --En Get responce code from master
      
      
      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
               AND cap_pan_code = gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_bal := 0;
            l_ledger_bal := 0;
      END;
      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
        --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        p_tran_date_in,
                        p_tran_time_in,
                        p_rvsl_code_in,
                        l_hash_pan,
                        l_encr_pan,
                        l_err_msg,
                        p_ip_address_in,
                        l_card_stat,
                        l_trans_desc,
                        NULL,
                        NULL,
                        l_time_stamp,
                        l_acct_number,
                        l_prod_code,
                        l_card_type,
                        l_dr_cr_flag,
                        l_acct_bal,
                        l_ledger_bal,
                        l_acct_type,
                        l_proxy_number,
                        p_auth_id_out,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            l_err_msg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;
      --En Inserting data in transactionlog
      --Sn Inserting data in transactionlog dtl
      BEGIN
         sp_log_txnlogdetl (p_inst_code_in,
                            p_msg_type_in,
                            p_rrn_in,
                            p_delivery_channel_in,
                            p_txn_code_in,
                            l_txn_type,
                            p_txn_mode_in,
                            p_tran_date_in,
                            p_tran_time_in,
                            l_hash_pan,
                            l_encr_pan,
                            l_err_msg,
                            l_acct_number,
                            p_auth_id_out,
                            NULL,
                            p_mobile_no_in,
                            p_device_id_in,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_resp_code_out,
                            NULL,
                            NULL,
                            NULL,
                            l_logdtl_resp,
                            --p_email_id_out
                            NULL
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;
   
   
   PROCEDURE  optout (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_processor_card_token_in   	in  	varchar2,
          p_accountId_in   	            in  	varchar2,
          p_ip_address_in               in    varchar2,
          p_mobile_no_in                in    varchar2,
          p_device_id_in                in    varchar2,
          p_auth_id_out                 out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2
   )
   IS
      /************************************************************************************************************
       * Created Date     :  19-April-2017
       * Created By       :  MageshKumar
       * Created For      :  CVV PLUS OPTOUT
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD_17.04_B0003
  
      ************************************************************************************************************/
      l_auth_savepoint       NUMBER                                 DEFAULT 0;
      l_err_msg              VARCHAR2 (500);
      l_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type             transactionlog.txn_type%TYPE;
      l_dr_cr_flag           VARCHAR2 (2);
      l_tran_type            VARCHAR2 (2);
      l_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_card_type            cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde             VARCHAR2 (5);
      l_time_stamp           TIMESTAMP;
      l_hashkey_id           cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_trans_desc           cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag            cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_acct_number          cms_appl_pan.cap_acct_no%TYPE;
      l_prfl_code            cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat            cms_appl_pan.cap_card_stat%TYPE;
      l_cust_code            cms_appl_pan.cap_cust_code%TYPE;
      l_preauth_flag         cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type            cms_acct_mast.cam_type_code%TYPE;
      l_proxy_number         cms_appl_pan.cap_proxy_number%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      l_login_txn            cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp          VARCHAR2 (500);
      l_preauth_type         cms_transaction_mast.ctm_preauth_type%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      
      
      l_exp_reject_record      EXCEPTION;
      
   BEGIN
      l_resp_cde := '1';
      l_err_msg := 'OK';
      l_time_stamp := SYSTIMESTAMP;
      BEGIN
         SAVEPOINT l_auth_savepoint;
       
         --Sn Get the HashPan
                  
         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn, ctm_preauth_type
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag, l_login_txn, l_preauth_type
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE l_exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details'|| SUBSTR (SQLERRM, 1, 300);
               RAISE l_exp_reject_record;
         END;
         --En find debit and credit flag
         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO p_auth_id_out
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';                         -- Server Declined
               RAISE l_exp_reject_record;
         END;
         --En generate auth id
         
         
         BEGIN
         
         SELECT VCI_CVVPLUS_ACCT_NO INTO l_acct_number FROM VMS_CVVPLUS_INFO
         WHERE (VCI_CVVPLUS_TOKEN = p_processor_card_token_in
         AND VCI_CVVPLUS_ACCOUNTID = p_accountId_in)
         OR (p_processor_card_token_in IS NULL AND VCI_CVVPLUS_ACCOUNTID = p_accountId_in )
         OR (p_accountId_in IS NULL AND VCI_CVVPLUS_TOKEN = p_processor_card_token_in);
         
       EXCEPTION
            
       WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '267';
               l_err_msg :='Customer Not Enrolled For CVV Plus';
               RAISE l_exp_reject_record;
        
          WHEN OTHERS THEN 
          l_resp_cde := '21';
          l_err_msg :='Problem while selecting CVV plus details '|| SUBSTR (SQLERRM, 1, 200);
          RAISE l_exp_reject_record;
        
         
         END;
         
          --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, 
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, 
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code
              FROM cms_appl_pan
             WHERE 
             cap_inst_code = p_inst_code_in 
             AND cap_acct_no = l_acct_number
             AND CAP_ACTIVE_DATE is not null
             AND cap_card_stat not in('9','2')
             ORDER BY CAP_ACTIVE_DATE desc;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
            
            BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, 
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, 
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code
              FROM cms_appl_pan
             WHERE 
             cap_inst_code = p_inst_code_in 
             AND cap_acct_no = l_acct_number
             AND ROWNUM=1
             ORDER BY CAP_PANGEN_DATE desc;
             
            EXCEPTION
              
             WHEN OTHERS THEN
             l_resp_cde := '16';
             l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
             RAISE l_exp_reject_record;
             
            END;
               
            WHEN OTHERS THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE l_exp_reject_record;
         END;
         --End Get the card details
         
         BEGIN

            UPDATE CMS_APPL_PAN SET CAP_CVVPLUS_REG_FLAG='N', CAP_CVVPLUS_ACTIVE_FLAG='N'
            WHERE CAP_INST_CODE=p_inst_code_in AND CAP_ACCT_NO=l_acct_number;

              IF SQL%ROWCOUNT =0 THEN
                 l_resp_cde := '21';
                 l_err_msg := 'Not updated registration status and active flag';
                RAISE l_exp_reject_record;
              END IF;

            EXCEPTION
             WHEN l_exp_reject_record THEN
              RAISE;
             WHEN OTHERS THEN
               l_resp_cde := '21';
               l_err_msg := 'Error while updating registration status and active flag ' || SUBSTR (SQLERRM, 1, 200);
              RAISE l_exp_reject_record;
        END;
             
         
         
         BEGIN
            SELECT  cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14'; 
           l_err_msg  := 'Invalid Card ';
           RAISE l_exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE l_exp_reject_record;
         END;

  
         
         l_resp_cde := '1';
         
     EXCEPTION
         WHEN l_exp_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;
   --Sn Get responce code from  master
         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem while selecting data from response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
         END;
      --En Get responce code from master
      
      
      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
               AND cap_acct_no = l_acct_number;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_bal := 0;
            l_ledger_bal := 0;
      END;
      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
        --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        p_tran_date_in,
                        p_tran_time_in,
                        NULL,
                        l_hash_pan,
                        l_encr_pan,
                        l_err_msg,
                        p_ip_address_in,
                        l_card_stat,
                        l_trans_desc,
                        NULL,
                        NULL,
                        l_time_stamp,
                        l_acct_number,
                        l_prod_code,
                        l_card_type,
                        l_dr_cr_flag,
                        l_acct_bal,
                        l_ledger_bal,
                        l_acct_type,
                        l_proxy_number,
                        p_auth_id_out,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        l_resp_cde,
                        p_resp_code_out,
                        NULL,
                        l_err_msg
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            l_err_msg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;
      --En Inserting data in transactionlog
      --Sn Inserting data in transactionlog dtl
      BEGIN
         sp_log_txnlogdetl (p_inst_code_in,
                            p_msg_type_in,
                            p_rrn_in,
                            p_delivery_channel_in,
                            p_txn_code_in,
                            l_txn_type,
                            p_txn_mode_in,
                            p_tran_date_in,
                            p_tran_time_in,
                            l_hash_pan,
                            l_encr_pan,
                            l_err_msg,
                            l_acct_number,
                            p_auth_id_out,
                            NULL,
                            p_mobile_no_in,
                            p_device_id_in,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_resp_code_out,
                            NULL,
                            NULL,
                            NULL,
                            l_logdtl_resp,
                            NULL
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;
          
          
END VMSCVVPLUS;
/
show error;