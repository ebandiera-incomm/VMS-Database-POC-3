create or replace
PACKAGE BODY                             vmscms.VMSTOKENIZATION IS

   -- Private type declarations

   -- Private constant declarations

   -- Private variable declarations

   -- Function and procedure implementations
    PROCEDURE UPDATE_TOKEN_STATUS(
        P_TOKEN_IN     VARCHAR2,
        P_CARDNO_IN    VARCHAR2,
        P_TOKEN_STATUS_IN VARCHAR2,
        p_respmsg_out OUT VARCHAR2 )
    IS
    BEGIN
      IF trim(P_TOKEN_STATUS_in) NOT IN ('A','I','S','D') THEN
        p_respmsg_out       :='Invalid token status..';
        RETURN;
      END IF;
      BEGIN
        UPDATE VMS_TOKEN_INFO
        SET VTI_TOKEN_STAT = trim(P_TOKEN_STATUS_IN)
        WHERE vti_token    = trim(p_token_in)
        AND vti_token_pan  = p_cardno_in;
        IF SQL%ROWCOUNT    =0 THEN
          p_respmsg_out   :='Token Not found for status update';
          RETURN;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        p_respmsg_out:='Error while updating token staus-'||SQLERRM;
        RETURN;
      END;
    EXCEPTION
    WHEN OTHERS THEN
      p_respmsg_out:='Main Excp-'||sqlerrm;
    END update_token_status;
    
    
  PROCEDURE validate_pan_token(
        p_inst_code_in        IN NUMBER,
        p_token_in            IN VARCHAR2,
        P_CARDNO_IN           IN VARCHAR2,
        p_delivery_channel_in IN VARCHAR2,
        p_response_id_out     OUT VARCHAR2,
        p_respmsg_out         OUT VARCHAR2,
        p_token_staus_out     OUT VARCHAR2,
        p_reason_code_out     OUT VARCHAR2,
        p_token_reqid_out     OUT VARCHAR2,
        p_token_refid_out     OUT VARCHAR2)
    IS
	
	/****************************************************************
	 * Modified By      : Mohan E
     * Modified Date    : 17-Sep-2024
     * Purpose          : VMS_9121 Interim Solution: Enhance Tokenization Logic to Map Declines to a New Response Code
     * Reviewer         : Pankaj/Venkat
     * Release Number   : R103
	 ****************************************************************/
    
      l_approve_flag VMS_TOKEN_STATUS.VTS_APPROVE_FLAG%type;
      l_old_card_flag varchar2(1) default 'N';
      exp_reject_record      EXCEPTION;
      
    BEGIN
    IF p_token_in IS NOT NULL THEN
      BEGIN
        SELECT vti_token_stat,vti_token_requestor_id,vti_token_ref_id
        INTO p_token_staus_out,p_token_reqid_out,p_token_refid_out
        FROM vms_token_info
        WHERE vti_token   = trim(p_token_in)
        AND vti_token_pan = p_cardno_in;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
        SELECT vti_token_stat,vti_token_requestor_id,vti_token_ref_id
        INTO p_token_staus_out,p_token_reqid_out,p_token_refid_out
        FROM vms_token_info
        WHERE vti_token   = trim(p_token_in);
        l_old_card_flag:='Y';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        p_response_id_out := '5';
        p_respmsg_out     := 'Token Pending, Try Again at a Later Time';  --Modified for VMS_9121
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        p_response_id_out := '21';
        p_respmsg_out     := 'Problem while selecting token stat' || SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      WHEN OTHERS THEN
        p_response_id_out := '21';
        p_respmsg_out     := 'Problem while selecting token stat' || SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      
      IF p_delivery_channel_in='02' THEN
      
        BEGIN
          SELECT VTS_APPROVE_FLAG,VTS_REASON_CODE
          INTO l_approve_flag,p_reason_code_out
          FROM VMS_TOKEN_STATUS
          WHERE VTS_TOKEN_STAT = trim(p_token_staus_out);
          
          IF l_approve_flag  <> 'Y' OR l_old_card_flag='Y' THEN
            p_response_id_out := '119';
            p_respmsg_out     :='INVALID TOKEN STATUS' ;
            RAISE exp_reject_record;
          END IF;
          
          EXCEPTION
          WHEN exp_reject_record THEN
          RAISE;
          WHEN NO_DATA_FOUND THEN
            p_response_id_out := '119';
            p_respmsg_out     :='INVALID TOKEN STATUS' ;
            RAISE exp_reject_record;
            WHEN OTHERS THEN
            p_response_id_out := '21';
            p_respmsg_out     := 'Problem while selecting dtls from  VMS_TOKEN_STATUS'  || p_respmsg_out;
            RAISE exp_reject_record;
         
        END;
      END IF;
      END IF;

      p_response_id_out := '1';
      p_respmsg_out     := 'OK';
      
    EXCEPTION
    WHEN exp_reject_record THEN
    ROLLBACK;
    WHEN OTHERS THEN
      p_respmsg_out:='Main Excp-'||sqlerrm;
      ROLLBACK;
    END validate_pan_token;

    PROCEDURE  send_passcode_req (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_token_in   		              in  	varchar2,
          p_tran_amt_in                 in  	varchar2,
          p_curr_code_in                in  	varchar2,
          p_expry_date_in               in  	varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_cntry_code_in               in  	varchar2,
          p_verify_method_in            in  	varchar2,
          p_auth_id_out                 out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resmsg_out                  out 	varchar2,
          p_cell_no_out                 out   varchar2,
          p_email_id_out                out   varchar2,
          p_verify_method_out           out  	varchar2,
          p_action_code_out             out  	varchar2,
          p_error_code_out              out  	varchar2,
          p_resp_id_out                 out  	varchar2 --Added for sending to FSS (VMS-8018)
   )
   IS
      /************************************************************************************************************
       * Created Date     :  23-JUNE-2016
       * Created By       :  MageshKumar
       * Created For      :  VISA Tokenization
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD_4.3_B0001
	   
	   * Created Date     :  22-SEP-2016
       * Created By       :  MageshKumar
       * Created For      :  VISA Tokenization Additional Changes
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD_4.7.2_B0002
       
       * Modified Date     :  28-June-2017
       * Modified By       :  T.Narayanaswamy
       * Modified For      :  Validate token if exist
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  17.06
       * Modified Date     :  05-Sep-2017
       * Modified By       :  Siva Kumar M
       * Modified For      :  FSS-5199
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOST_17.08
       
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01
     
     * Modified By      : Areshka A.
     * Modified Date    : 03-Nov-2023
     * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
     * Reviewer         : 
     * Release Number   : 
     
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      l_login_txn            cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp          VARCHAR2 (500);
      l_preauth_type         cms_transaction_mast.ctm_preauth_type%TYPE;
      l_customer_id          cms_cust_mast.CCM_CUST_ID%type;
      l_method_identifier_customerid      cms_cust_mast.CCM_CUST_ID%type;
      l_method_identifier              VARCHAR2(20);
      l_token_staus vms_token_info.vti_token_stat%type;
      exp_reject_record      EXCEPTION;
      l_encrypt_enable     cms_prod_cattype.cpc_encrypt_enable%type;  
   BEGIN
      l_resp_cde := '1';
      l_err_msg:='OK';
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
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
         --End Generate HashKEY
         
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
               RAISE exp_reject_record;
         END;
         --En generate auth id  
         
    IF p_token_in IS NOT NULL THEN
      BEGIN
        SELECT vti_token_stat
        INTO l_token_staus
        FROM vms_token_info
        WHERE vti_token   = trim(p_token_in)
        AND vti_token_pan = l_hash_pan;
      EXCEPTION     
      WHEN NO_DATA_FOUND THEN
        l_resp_cde := '5';
        l_err_msg     := 'Token not Found';
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        l_resp_cde := '21';
        l_err_msg     := 'Problem while selecting token stat' || SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;     
     end if;
         BEGIN
         
         SELECT SUBSTR(p_verify_method_in,
                  1,
                  INSTR(p_verify_method_in,
                        '_',
                        1
                        ) -1),substr(p_verify_method_in,instr(p_verify_method_in,'_')+length('_'))
                        INTO l_method_identifier,l_method_identifier_customerid FROM DUAL; 
            EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '17';
               l_err_msg := 'Invalid OTP Identifier';
               RAISE exp_reject_record;
         END;
         
         IF (UPPER (TRIM (l_method_identifier))) = 'CELL' THEN
         p_verify_method_out := '1';
         ELSIF (UPPER (TRIM (l_method_identifier))) = 'EMAIL' THEN
         p_verify_method_out := '2';
         ELSIF (UPPER (TRIM (l_method_identifier))) <> 'CUSTOMER' THEN
          l_resp_cde := '17';
          l_err_msg := 'Invalid OTP Identifier';
          RAISE exp_reject_record;
         END IF;
         
             
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
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details'|| SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;
         --En find debit and credit flag
         
         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code,ccm_cust_id
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code,l_customer_id
              FROM cms_appl_pan,cms_cust_mast
             WHERE cap_cust_code = ccm_cust_code
             AND cap_inst_code = ccm_inst_code
             AND cap_inst_code = p_inst_code_in 
             AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
         BEGIN
            SELECT cpc_encrypt_enable
              INTO l_encrypt_enable
              FROM cms_prod_cattype
             WHERE cpc_prod_code = l_prod_code
             AND  cpc_card_type = l_card_type
             AND cpC_inst_code = p_inst_code_in; 
             
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'No data found for prod code and card type ' || l_prod_code || l_card_type;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting encrypt enable flag'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
         if l_customer_id <> NVL(l_method_identifier_customerid,0) then
               l_resp_cde := '3';
               l_err_msg := 'CUSTOMER ID NOT FOUND FOR CARD NUMBER' || l_method_identifier_customerid;
               RAISE exp_reject_record;
         end if;
        
         
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
                              p_tran_amt_in,
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
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
           -- FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14'; 
           l_err_msg  := 'Invalid Card ';
           RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

   BEGIN

           SELECT decode(l_encrypt_enable,'Y',fn_dmaps_main(CAM_MOBL_ONE),CAM_MOBL_ONE),
                  decode(l_encrypt_enable,'Y',fn_dmaps_main(CAM_EMAIL),CAM_EMAIL) 
            into p_cell_no_out,p_email_id_out
           FROM CMS_ADDR_MAST
           WHERE CAM_INST_CODE = p_inst_code_in
           AND CAM_CUST_CODE   = l_cust_code
           AND CAM_ADDR_FLAG   = 'P';
           
           EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   l_resp_cde := '21';
                   l_err_msg := 'cellphone no and email id not found for customer id';
                   RAISE exp_reject_record;
                 WHEN OTHERS THEN
                   l_resp_cde := '21';
                   l_err_msg := 'Error while selecting cellphone no and email id for physical address' || 
                   SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
           END;

        
         
         if p_cell_no_out IS NULL AND p_email_id_out IS NULL then
         l_resp_cde := '21';
                   l_err_msg := 'cellphone no and email id not found for customer id';
                   RAISE exp_reject_record;
         END IF;
         
     EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;
   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
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
               p_resp_id_out := '69'; --Added for VMS-8018
         END;
      --En Get responce code from master
      
      --Sn Get action code,error code from  token response master
         BEGIN
            SELECT vtr_action_code,vtr_error_code 
              INTO p_action_code_out,p_error_code_out
              FROM vms_token_response_mast
             WHERE vtr_inst_code = p_inst_code_in
               AND vtr_delivery_channel = p_delivery_channel_in
               AND vtr_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem while selecting data from token response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
               p_resp_id_out := '69'; --Added for VMS-8018
         END;
      --En Get action code,error code from  token response master
      
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
                        NULL,
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
                        p_tran_amt_in,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            p_tran_amt_in,
                            p_cell_no_out,
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
                            l_logdtl_resp,
                            p_email_id_out
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resp_id_out := '69'; --Added for VMS-8018
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;
    
    PROCEDURE  CardholderVerification (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_token_in   		              in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_token_type_in   		        in  	varchar2,
          p_token_status_in   		      in  	varchar2,
          p_token_assurance_level_in    in  	varchar2,
          p_token_requester_id_in   	  in  	varchar2,
          p_token_ref_id_in   		      in  	varchar2,
          p_token_expry_date_in         in  	varchar2,
          p_token_pan_ref_id_in         in  	varchar2,
          p_token_wpriskassessment_in   in  	varchar2,
          p_token_wpriskassess_ver_in in  	varchar2,
          p_token_wpdevice_score_in     in  	varchar2,
          p_token_wpaccount_score_in    in  	varchar2,
          p_token_wpreason_codes_in     in  	varchar2,
          p_token_wppan_source_in       in  	varchar2,
          p_token_wpacct_id_in          in  	varchar2,
          p_token_wpacct_email_in       in  	varchar2,
          p_token_device_type_in        in  	varchar2,
          p_token_device_langcode_in    in  	varchar2,
          p_token_device_id_in          in  	varchar2,
          p_token_device_no_in          in  	varchar2,
          p_token_device_name_in        in  	varchar2,
          p_token_device_loc_in         in  	varchar2,
          p_token_device_ip_in          in  	varchar2,
          p_token_device_secureeleid_in in  	varchar2,
          p_token_riskassess_score_in  in  	varchar2,
          p_token_provisioning_score_in in  	varchar2,
          p_curr_code_in                in    varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_stan_in                     in  	varchar2,
          P_NTW_SETTL_DATE              IN  	VARCHAR2,
          p_expry_date_in               in  	varchar2,          
          p_msg_reason_code_in          in    varchar2,
          p_contactless_usage_in        IN  	VARCHAR2,
          p_card_ecomm_usage_in         in  	varchar2,
          P_MOB_ECOMM_USAGE_IN_IN       IN  	VARCHAR2,
          p_wallet_identifier_in        IN  	VARCHAR2,
          p_storage_tech_in             IN  	VARCHAR2, 
          P_TOKEN_REQID13_IN            IN  	VARCHAR2,
          P_WP_REQID_IN                 IN  	VARCHAR2,
          P_WP_CONVID_IN                IN  	VARCHAR2,
          P_WALLET_ID_IN                IN  	VARCHAR2,
          P_TRAN_AMT_IN                 IN  	VARCHAR2,
          P_PAYMENT_APPPLNINSTANCEID_IN  in  	varchar2,
          p_auth_id_out                 out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resmsg_out                  out 	varchar2,
          p_action_code_out             out  	varchar2,
          p_error_code_out              out  	varchar2,
          p_de27response_out            out   varchar2,
          p_resp_id_out                 out   varchar2 --Added for sending to FSS (VMS-8018)
   )
   IS
      /************************************************************************************************************
       * Created Date     :  23-JUNE-2016
       * Created By       :  T.Narayanaswamy
       * Created For      :  VISA Tokenization
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD_4.3_B0001
       
       * Created Date     :  28-SEP-2016
       * Created By       :  MageshKumar
       * Created For      :  VISA Tokenization Additional Changes
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD_4.7.2_B0002
	   
       * Modified by      : T.Narayanaswamy/Dhinakar.B
       * Modified Date    : 27-September-2017
       * Modified reason  : FSS-5277 - Additional Tokenization Changes
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST_17.05.07
       
       * Modified Date     :  05-Sep-2017
       * Modified By       :  Siva Kumar M
       * Modified For      :  FSS-5199
       * Reviewer          :  Saravanakumar/SPankaj
       * Build Number      :  VMSGPRHOST_17.08
       
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01

     * Modified By      : Areshka A.
     * Modified Date    : 03-Nov-2023
     * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
     * Reviewer         : 
     * Release Number   : 
       
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      l_login_txn            cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp          VARCHAR2 (500);
      l_preauth_type         cms_transaction_mast.ctm_preauth_type%TYPE;
      exp_reject_record      exception;
      l_cell_no cms_addr_mast.cam_mobl_one%type;
      l_email_id cms_addr_mast.cam_email%type;
      l_de27_length number  default 0;
      l_de27_mobile varchar2(200):='';
      l_de27_email varchar2(200):='';
      l_customer_id    cms_cust_mast.CCM_CUST_ID%type;
      p_token_staus_out vms_token_info.vti_token_stat%type;
      p_reason_code_out VMS_TOKEN_STATUS.VTS_REASON_CODE%type;
      p_token_reqid_out vms_token_info.vti_token_requestor_id%type;
      p_token_refid_out vms_token_info.vti_token_ref_id%type;
      l_customer_cardnum  cms_prod_cattype.cpc_customer_care_num%type;
      l_de27_customercare_number  varchar2(200):='';
      l_encrypt_enable    cms_prod_cattype.cpc_encrypt_enable%type; 
	  l_otp_channel cms_prod_cattype.cpc_otp_channel%type;   --VMS-8262
      l_vms8262_toggle cms_inst_param.cip_param_value%type :='Y';  --VMS-8262
   BEGIN
      l_resp_cde := '1';
      l_err_msg:='OK';
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
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
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
               RAISE exp_reject_record;
         END;
         --End Generate HashKEY
         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code,ccm_cust_id
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code,l_customer_id
              from cms_appl_pan,cms_cust_mast
             where cap_inst_code=ccm_inst_code and cap_cust_code=ccm_cust_code and 
             cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --End Get the card details
         
         BEGIN
            SELECT cpc_encrypt_enable, decode(cpc_otp_channel,'0','N/A','1','SMS','2','EMAIL','3','SMS AND EMAIL','SMS AND EMAIL')
              INTO l_encrypt_enable,l_otp_channel
              FROM cms_prod_cattype
             WHERE cpc_prod_code = l_prod_code
             AND  cpc_card_type = l_card_type
             AND cpC_inst_code = p_inst_code_in; 
             
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'No data found for prod code and card type ' || l_prod_code || l_card_type;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting encrypt enable flag details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
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
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details'|| SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
         --En generate auth id

 
/*        BEGIN
      
      validate_pan_token(p_inst_code_in,
        p_token_in,
        l_hash_pan,
        p_delivery_channel_in,
        l_resp_cde,
        l_err_msg,
        p_token_staus_out,
        p_reason_code_out,
        p_token_reqid_out,
        p_token_refid_out);

       IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
            l_resp_cde := '5';
            l_err_msg :='Token not Found';
            RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '5';
               l_err_msg :=
                     'Error from  Token Validation Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               raise exp_reject_record;
         end;
 */ 
 
   if trim(p_token_in) is not null  then
            
               LP_TOKEN_CREATE_UPDATE(P_TOKEN_IN,
                L_HASH_PAN,
                P_TOKEN_TYPE_IN,
                'I',
                P_TOKEN_ASSURANCE_LEVEL_IN,
                P_TOKEN_REQUESTER_ID_IN,
                P_TOKEN_REF_ID_IN,
                P_TOKEN_EXPRY_DATE_IN,
                P_TOKEN_PAN_REF_ID_IN,
                P_TOKEN_WPPAN_SOURCE_IN,
                P_TOKEN_WPRISKASSESSMENT_IN,
                P_TOKEN_WPRISKASSESS_VER_IN,
                P_TOKEN_WPDEVICE_SCORE_IN,
                P_TOKEN_WPACCOUNT_SCORE_IN,
                P_TOKEN_WPREASON_CODES_IN,
                P_TOKEN_WPACCT_ID_IN,
                P_TOKEN_WPACCT_EMAIL_IN,
                P_TOKEN_DEVICE_TYPE_IN,
                P_TOKEN_DEVICE_LANGCODE_IN,
                P_TOKEN_DEVICE_ID_IN  ,
                P_TOKEN_DEVICE_NO_IN,
                P_TOKEN_DEVICE_NAME_IN,
                P_TOKEN_DEVICE_LOC_IN,
                P_TOKEN_DEVICE_IP_IN,
                P_TOKEN_DEVICE_SECUREELEID_IN,
                P_WALLET_IDENTIFIER_IN,
                P_STORAGE_TECH_IN,
                P_TOKEN_RISKASSESS_SCORE_IN,
                P_TOKEN_PROVISIONING_SCORE_IN,
                P_CONTACTLESS_USAGE_IN,
                P_CARD_ECOMM_USAGE_IN,
                P_MOB_ECOMM_USAGE_IN_IN,
                L_ACCT_NUMBER,
                L_CUST_CODE,
                P_INST_CODE_IN,
                P_TOKEN_REQID13_IN,
                P_WP_REQID_IN,
                P_WP_CONVID_IN,
                P_WALLET_ID_IN,
                P_PAYMENT_APPPLNINSTANCEID_IN,
                p_token_ref_id_in,
                L_RESP_CDE,
                l_err_msg
                );
              
              IF L_ERR_MSG <> 'OK' THEN
                  RAISE  EXP_REJECT_RECORD; 
              END IF;
         
         END IF;
         
         
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
                              p_tran_amt_in,
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
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
   
         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
           -- FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14'; 
           l_err_msg  := 'Invalid Card ';
           RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

       

          BEGIN
           
           SELECT decode(l_encrypt_enable,'Y',fn_dmaps_main(CAM_MOBL_ONE),CAM_MOBL_ONE),
                  decode(l_encrypt_enable,'Y',fn_dmaps_main(CAM_EMAIL),CAM_EMAIL)
            into l_cell_no,l_email_id
           FROM CMS_ADDR_MAST
           WHERE CAM_INST_CODE = p_inst_code_in
           AND CAM_CUST_CODE   = l_cust_code
           AND CAM_ADDR_FLAG   = 'P';
           
           EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   l_resp_cde := '21';
                   l_err_msg := 'cellphone no and email id not found for customer id';
                   RAISE exp_reject_record;
                 WHEN OTHERS THEN
                   l_resp_cde := '21';
                   l_err_msg := 'Error while selecting cellphone no and email id for physical address' ||
                   SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
           END;
           
           BEGIN
                Select CIP_PARAM_VALUE into l_vms8262_toggle from vmscms.cms_inst_param where cip_param_key='VMS_8262_TOGGLE';
           EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   l_vms8262_toggle:='Y';
                WHEN OTHERS THEN
                   l_resp_cde := '21';
                   l_err_msg := 'Error while selecting toggle value' ||
                   SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
           END;

       begin
       select CPC_CUSTOMER_CARE_NUM
            into  l_customer_cardnum 
            from cms_prod_cattype
          where cpc_prod_code=l_prod_code
              and cpc_card_type=l_card_type
              and cpc_inst_code=p_inst_code_in;
             EXCEPTION 
                   WHEN OTHERS THEN
                   l_resp_cde := '21';
                   l_err_msg := 'Error while selecting customer care number' || 
                   SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
       end;
       
         begin
        IF l_customer_cardnum IS NOT NULL THEN
			  l_de27_customercare_number:=rpad('CUSTOMER_SERVICE',32,' ')||rpad(l_customer_cardnum,64,' ')||rpad(('CUSTOMER_'||l_customer_id),32,' ')||rpad(' ',64,' ');
        END IF;
        IF L_CELL_NO IS NOT NULL THEN
				L_CELL_NO:=fn_mask(L_CELL_NO,'*',1,length(L_CELL_NO)-4);         
				l_de27_mobile:=rpad('CELL_PHONE',32,' ')||rpad(l_cell_no,64,' ')||rpad(('CELL_'||l_customer_id),32,' ')||rpad(' ',64,' ');
        END IF;
		
		IF L_EMAIL_ID IS NOT NULL THEN
			select (SELECT listagg (CHR, '') WITHIN GROUP (ORDER BY rnum)
			FROM (    SELECT CASE
			WHEN LEVEL > 1 AND LEVEL < INSTR (L_EMAIL_ID, '@') - 1 THEN '*'
			ELSE REGEXP_SUBSTR (L_EMAIL_ID, '.', LEVEL) END CHR,
			ROWNUM rnum
			FROM DUAL
			CONNECT BY LEVEL <= LENGTH (L_EMAIL_ID))) into L_EMAIL_ID from dual;  
			l_de27_email:=rpad('EMAIL',32,' ')||rpad(l_email_id,64,' ')||rpad(('EMAIL_'||l_customer_id),32,' ')||rpad(' ',64,' ');
		end if;
        
        if(l_vms8262_toggle = 'N') then
                if (l_de27_mobile is not null or l_de27_email is not null or l_de27_customercare_number is not null) then
                        p_de27response_out:='027'||length(l_de27_mobile||l_de27_email||l_de27_customercare_number)||
                        l_de27_mobile||l_de27_email||l_de27_customercare_number;
                else
                    P_DE27RESPONSE_OUT:='';
                    L_RESP_CDE := '21';
                    L_ERR_MSG := 'cellphone no and email id not found for customer id';
                    raise exp_reject_record;
                end if;
        else
                if (l_otp_channel = 'N/A' and l_de27_customercare_number is not null) then
                    p_de27response_out:='027'||length(l_de27_customercare_number)||l_de27_customercare_number;
                elsif (l_otp_channel = 'SMS' and (l_de27_mobile is not null or l_de27_customercare_number is not null)) then
                    p_de27response_out:='027'||length(l_de27_mobile||l_de27_customercare_number)||l_de27_mobile||l_de27_customercare_number;
                elsif  (l_otp_channel = 'EMAIL' and (l_de27_email is not null or l_de27_customercare_number is not null)) then
                    p_de27response_out:='027'||length(l_de27_email||l_de27_customercare_number)||l_de27_email||l_de27_customercare_number;
                elsif (l_otp_channel = 'SMS AND EMAIL')
                  and (l_de27_mobile is not null or l_de27_email is not null or l_de27_customercare_number is not null) then
                    p_de27response_out:='027'||length(l_de27_mobile||l_de27_email||l_de27_customercare_number)||
                    l_de27_mobile||l_de27_email||l_de27_customercare_number;
                else
                    P_DE27RESPONSE_OUT:='';
                    L_RESP_CDE := '21';
                    L_ERR_MSG := 'cellphone no and email id not found for customer id';
                    raise exp_reject_record;
                end if;
		end if;

        EXCEPTION
         WHEN exp_reject_record
            THEN
               RAISE;
         WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while CONSTRUCTING DE27 STRING '
                  || SUBSTR (SQLERRM, 1, 200);
               raise exp_reject_record;
         END;
         l_err_msg:='OK';
         l_resp_cde := '1';
     EXCEPTION
         WHEN exp_reject_record
         THEN
           -- ROLLBACK TO l_auth_savepoint;
           ROLLBACK;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
           -- ROLLBACK TO l_auth_savepoint;
           ROLLBACK;
      END;
   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
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
               p_resp_id_out := '69'; --Added for VMS-8018
         END;
      --En Get responce code from master
      
       --Sn Get action code,error code from  token response master
         BEGIN
            SELECT vtr_action_code,vtr_error_code 
              INTO p_action_code_out,p_error_code_out
              FROM vms_token_response_mast
             WHERE vtr_inst_code = p_inst_code_in
               AND vtr_delivery_channel = p_delivery_channel_in
               AND vtr_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem while selecting data from token response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '69';
         end;
      --En Get action code,error code from  token response master
      
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
                        NULL,
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
                        p_tran_amt_in,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            p_tran_amt_in,
                            l_cell_no,
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
                            l_logdtl_resp,
                            l_email_id
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resp_id_out := '69'; --Added for VMS-8018
         p_resmsg_out :=
            'Main exception from  authorization ' || substr (sqlerrm, 1, 300);
   END CARDHOLDERVERIFICATION;
 
PROCEDURE  check_eligibility(p_inst_code_in  in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_tran_amt_in                 in  	varchar2,
          p_curr_code_in                in  	varchar2, 
          P_EXPRY_DATE_IN               IN  	VARCHAR2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_cntry_code_in               in  	varchar2,
          p_stan_in                     in  	varchar2,
          p_auth_id_out                 out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2,
          P_ISSUERREF_ID_OUT            OUT   VARCHAR2,
          P_CARDART_ID_OUT              OUT   VARCHAR2,
          P_TANDC_ID_OUT                OUT   VARCHAR2,
          P_ACTION_CODE_OUT             OUT   VARCHAR2,
          p_error_code_out              OUT   VARCHAR2,
          p_resp_id_out                 OUT   VARCHAR2 --Added for sending to FSS (VMS-8018)
          )
IS
/************************************************************************************************************
 * Created Date     :  22-JUNE-2016
 * Created By       :  Siva Kumar M
 * Created For      :  VISA Tokenization
 * Reviewer         :  Saravanakumar/SPankaj
 * Build Number     :  VMSGPRHOSTCSD_4.4_B0002
 
     * Modified by      : Siva Kumar M
     * Modified For     : Mantis ID:16440
     * Modified Date    : 12-July-2016
     * Modified reason  : the provision count is not increasing in appl pan for that card 
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.5_B0003
     
     * Modified by      : T.Narayanaswamy
     * Modified For     : Token Provision retry count changes
     * Modified Date    : 28-December-2016
     * Modified reason  : Token Provision retry count changes
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.7

     * Modified by      : Areshka A.
     * Modified For     : VMS-8018
     * Modified Date    : 03-Nov-2023
     * Modified reason  : Added new out parameter (response id) for sending to FSS
     * Reviewer         : 
     * Build Number     : 

************************************************************************************************************/
      
      l_auth_savepoint       NUMBER                                 DEFAULT 0;
      l_err_msg              VARCHAR2 (500);
      l_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type             transactionlog.txn_type%TYPE;
      l_auth_id              transactionlog.auth_id%TYPE;
      exp_reject_record      EXCEPTION;
      l_dr_cr_flag           VARCHAR2 (2);
      l_tran_type            VARCHAR2 (2);
      l_tran_amt             NUMBER;
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      l_login_txn            cms_transaction_mast.ctm_login_txn%TYPE;
      L_LOGDTL_RESP          VARCHAR2 (500);
      L_PREAUTH_TYPE         CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
      L_TOKEN_PROVISION_RETRY_MAX   CMS_PROD_CATTYPE.CPC_TOKEN_PROVISION_RETRY_MAX%TYPE;
      L_MOB_MAIL_FLAG            CHAR(2);
	    L_TOKEN_ELIGIBILITY        CMS_PROD_CATTYPE.CPC_TOKEN_ELIGIBILITY%TYPE;
      L_KYC_FLAG                 CMS_CUST_MAST.CCM_KYC_FLAG %TYPE;
      L_TOKEN_CUST_UPD_DURATION  CMS_PROD_CATTYPE.CPC_TOKEN_CUST_UPD_DURATION%TYPE;
     -- L_TOKEN_CUST_UPD_FREQUENCY CMS_PROD_CATTYPE.CPC_TOKEN_CUST_UPD_FREQUENCY%TYPE;
      l_provisioning_attempt_cnt CMS_APPL_PAN.CAP_PROVISIONING_ATTEMPT_COUNT%TYPE;
      L_PROVISIONING_FLAG        CMS_APPL_PAN.CAP_PROVISIONING_FLAG%TYPE;
      L_DURATION_DIFF            NUMBER;
      L_CARDPACK_ID              CMS_APPL_PAN.CAP_CARDPACK_ID%TYPE;
   --   L_CAM_ACCT_BAL             CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
      EXP_TOKEN_REJECT_RECORD    EXCEPTION;
 
 
BEGIN
 
     L_ERR_MSG :='OK';
     l_time_stamp := SYSTIMESTAMP;
 BEGIN 
  savepoint l_auth_savepoint;
 --Sn Get the HashPan
      BEGIN
          L_HASH_PAN := GETHASH (P_PAN_CODE_IN);
             EXCEPTION  WHEN OTHERS    THEN
               l_resp_cde := '12';
               l_err_msg :='Error while converting hash pan '|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
      END;
 --En Get the HashPan
     --Sn Create encr pan
      BEGIN
          L_ENCR_PAN := FN_EMAPS_MAIN (P_PAN_CODE_IN);
            EXCEPTION  WHEN OTHERS  THEN
             l_resp_cde := '12';
             L_ERR_MSG :='Error while converting emcrypted pan ' || SUBSTR (SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
      END;
        --Start Generate HashKEY value
      --Start Generate HashKEY value
             BEGIN
             l_hashkey_id :=gethash (p_delivery_channel_in
                            || p_txn_code_in
                            || p_pan_code_in
                            || p_rrn_in
                            || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5'));
              EXCEPTION  WHEN OTHERS  THEN
                   l_resp_cde := '21';
                   l_err_msg :=  'Error while Generating  hashkey id data '  || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
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
                   AND CTM_INST_CODE = P_INST_CODE_IN;
             EXCEPTION WHEN NO_DATA_FOUND THEN
                   l_resp_cde := '12';
                   l_err_msg :='Transaction not defined for txn code ' || p_txn_code_in|| ' and delivery channel '|| p_delivery_channel_in;
                   RAISE exp_reject_record;
                WHEN OTHERS
                THEN
                   l_resp_cde := '21';
                   l_err_msg := 'Error while selecting transaction details'||p_txn_code_in||p_delivery_channel_in||P_INST_CODE_IN|| SUBSTR (SQLERRM, 1, 300);
                   RAISE exp_reject_record;
             END;
  --En find debit and credit flag
  --Sn generate auth id
              BEGIN
                  SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
                          INTO p_auth_id_out
                          FROM DUAL;
                EXCEPTION  WHEN OTHERS THEN
                           l_err_msg := 'Error while generating authid '|| SUBSTR (SQLERRM, 1, 300);
                           l_resp_cde := '21';                        
                           RAISE exp_reject_record;
              END;
  --En generate auth id
      --Sn Get the card details
             BEGIN
                    SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                           cap_prfl_code, cap_expry_date, cap_proxy_number,
                           cap_cust_code,nvl(CAP_PROVISIONING_ATTEMPT_COUNT,0),CAP_PROVISIONING_FLAG,CAP_CARDPACK_ID
                      INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                           l_prfl_code, l_expry_date, l_proxy_number,
                           l_cust_code,l_provisioning_attempt_cnt,l_provisioning_flag,L_CARDPACK_ID
                      FROM cms_appl_pan
                     WHERE CAP_INST_CODE = P_INST_CODE_IN AND CAP_PAN_CODE = L_HASH_PAN;
             EXCEPTION  
                   WHEN NO_DATA_FOUND  THEN
                       l_resp_cde := '16';
                       l_err_msg := 'Card number not found ';
                       RAISE EXP_REJECT_RECORD;
                    WHEN OTHERS THEN
                       l_resp_cde := '21';
                       l_err_msg :='Problem while selecting card detail'|| SUBSTR (SQLERRM, 1, 200);
                       RAISE exp_reject_record;
            END;
  --End Get the card details
     --SN  Eligibity flag and Provisitioning retry count
          BEGIN
            SELECT CPC_TOKEN_ELIGIBILITY,CPC_TOKEN_PROVISION_RETRY_MAX,CPC_TOKEN_CUST_UPD_DURATION
             INTO l_TOKEN_ELIGIBILITY,L_TOKEN_PROVISION_RETRY_MAX,L_TOKEN_CUST_UPD_DURATION
             FROM CMS_PROD_CATTYPE
             WHERE CPC_PROD_CODE=L_PROD_CODE
             AND CPC_CARD_TYPE= L_CARD_TYPE
             AND CPC_INST_CODE =P_INST_CODE_IN;
          
            IF L_TOKEN_ELIGIBILITY ='N' THEN
             L_ERR_MSG :='Product Ineligible for Tokenization';
               l_resp_cde :='915';--'21';
            RAISE EXP_REJECT_RECORD;
            END IF;
          EXCEPTION  
               WHEN EXP_REJECT_RECORD THEN
               RAISE;
               WHEN  OTHERS  THEN
               L_ERR_MSG :='Error while getting  Eligibility check and Provisioning Retry count' ||SUBSTR(SQLERRM,1,200);
               l_resp_cde :='21';
            RAISE EXP_REJECT_RECORD;
          END;
     --EN  Eligibity flag and  Provisioning retry count 
 
         BEGIN
            IF l_provisioning_flag is not null and l_provisioning_flag ='N' THEN
             L_ERR_MSG :='Velocity Rule Failure';
             l_resp_cde :='921'; --'21';
          RAISE exp_reject_record;--EXP_TOKEN_REJECT_RECORD;
          END IF;
         EXCEPTION 
                  WHEN exp_reject_record THEN
                  RAISE;
                  WHEN  OTHERS THEN
                    l_resp_cde := '21';
                   L_ERR_MSG := 'Error while Provisioning check '||SUBSTR(SQLERRM,1,200);
                   RAISE exp_reject_record;
          END;
    
    --  SN Kyc Status check
    BEGIN
       SELECT CCM_KYC_FLAG 
       INTO L_KYC_FLAG
       FROM CMS_CUST_MAST
       WHERE CCM_CUST_CODE =L_CUST_CODE
       AND CCM_INST_CODE=P_INST_CODE_IN;
          IF L_KYC_FLAG NOT IN ('P','O','Y','I') THEN
               l_resp_cde :='917';
               L_ERR_MSG :='KYC Check failed';
           RAISE EXP_TOKEN_REJECT_RECORD;
          END IF;
    EXCEPTION 
      WHEN EXP_TOKEN_REJECT_RECORD THEN
         RAISE;
      WHEN OTHERS THEN
           L_RESP_CDE := '12';
           L_ERR_MSG :='Error while selecting kyc details'|| SUBSTR (SQLERRM, 1, 200);
           RAISE exp_reject_record;
    END;
 
     -- EN Kyc  Status check  
       -- expiry date check 
     BEGIN
     IF L_EXPRY_DATE IS NOT NULL THEN
       IF to_char(L_EXPRY_DATE,'YYMM') <> P_EXPRY_DATE_IN  THEN
           L_RESP_CDE := '918';
           L_ERR_MSG :='Incorrect Expiry / CVV2';
           RAISE EXP_TOKEN_REJECT_RECORD;
       END IF;
       END IF;  
      EXCEPTION WHEN EXP_TOKEN_REJECT_RECORD THEN
         RAISE;
           WHEN OTHERS THEN
               l_resp_cde := '12';
               L_ERR_MSG := 'Error while checking Expiry date';
               RAISE EXP_REJECT_RECORD;             
      END;
     
      -- SN  Account Balance
      BEGIN
        SELECT CAM_ACCT_BAL,cam_ledger_bal
           INTO l_acct_bal,l_ledger_bal
          FROM CMS_ACCT_MAST
         WHERE CAM_ACCT_NO=L_ACCT_NUMBER
       AND CAM_INST_CODE=P_INST_CODE_IN;
           
         IF l_acct_bal<0 THEN
         l_resp_cde :='919';
         L_ERR_MSG :='Card Balance Validation Failure';
         RAISE EXP_TOKEN_REJECT_RECORD;
         END IF;
         
      EXCEPTION
      WHEN EXP_TOKEN_REJECT_RECORD THEN
      RAISE;
      WHEN OTHERS THEN
           L_RESP_CDE := '12';
           L_ERR_MSG :='Error while selecting acct balance'|| SUBSTR (SQLERRM, 1, 200);
           RAISE exp_reject_record;
      END;
      
     -- EN  Account Balance
     
      -- SN  contact info updation check 
     BEGIN
       SELECT floor(((SYSDATE-CME_CHNG_DATE)*24)*60)
             INTO  L_DURATION_DIFF 
              FROM  cms_mob_email_log
              WHERE cme_inst_code = P_INST_CODE_IN
              AND CME_CUST_CODE = L_CUST_CODE;

       IF  L_DURATION_DIFF < L_TOKEN_CUST_UPD_DURATION THEN
         l_resp_cde  := '21';
         l_err_msg :='Mobile/Email address has been updated within last '|| L_DURATION_DIFF ||'Minutes';
         RAISE EXP_TOKEN_REJECT_RECORD;
      END IF;

        EXCEPTION  
         WHEN  EXP_TOKEN_REJECT_RECORD  THEN
           RAISE;
         WHEN NO_DATA_FOUND THEN
            NULL;
         WHEN OTHERS  THEN
             l_resp_cde := '21';
             l_err_msg :='Problem while selecting flag from cms_mob_email_log-'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
 
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
                                      p_tran_amt_in,
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
                    if l_resp_cde = '10' then 
                      l_resp_cde := '916';
                      l_err_msg :='Invalid Card Status';
                    end if;
                    IF l_err_msg <> 'OK'
                    THEN
                       RAISE EXP_TOKEN_REJECT_RECORD;
                    END IF;
                 EXCEPTION
                    WHEN EXP_TOKEN_REJECT_RECORD
                    THEN
                       RAISE;
                    WHEN OTHERS
                    THEN
                       l_resp_cde := '21';
                       l_err_msg :=
                             'Error from  cmsauth Check Procedure  '
                          || SUBSTR (SQLERRM, 1, 200);
                       RAISE EXP_REJECT_RECORD;
                 END;
  

         l_resp_cde := '1';
         l_err_msg:='OK';
      IF l_err_msg ='OK' THEN
        BEGIN
           SELECT  CPC_ISSUER_GUID,CPC_ART_GUID,CPC_TC_GUID
            INTO  P_ISSUERREF_ID_OUT,P_CARDART_ID_OUT,P_TANDC_ID_OUT
            FROM CMS_PRODCAT_CARDPACK 
           WHERE CPC_PROD_CODE=l_prod_code
            AND CPC_CATG_CODE=l_card_type
            AND CPC_CARD_ID=L_CARDPACK_ID
            AND CPC_INST_CODE=P_INST_CODE_IN;
        EXCEPTION   
               WHEN OTHERS THEN
              l_resp_cde := '21';
              l_err_msg := 'Problem while selecting card GUID detail ' ||SUBSTR(SQLERRM,1,200); 
              RAISE  exp_reject_record; 
        END;
       
        BEGIN
           UPDATE CMS_APPL_PAN 
           SET   CAP_PROVISIONING_FLAG ='Y', CAP_PROVISIONING_ATTEMPT_COUNT=0
          WHERE CAP_INST_CODE = P_INST_CODE_IN AND CAP_PAN_CODE = L_HASH_PAN;
          EXCEPTION  
                    WHEN  OTHERS THEN
              l_resp_cde := '21';
              l_err_msg := 'Exception While updating provisioning count TO 0 and flag TO Y ' ||substr(SQLERRM,1,200); 
              RAISE  exp_reject_record; 
         END;
      END IF;
EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
              ROLLBACK TO l_auth_savepoint;
        IF L_ERR_MSG ='Incorrect Expiry / CVV2' THEN
         IF L_TOKEN_PROVISION_RETRY_MAX = l_provisioning_attempt_cnt+1 THEN
           BEGIN
              UPDATE CMS_APPL_PAN
              SET CAP_PROVISIONING_FLAG ='N',CAP_PROVISIONING_ATTEMPT_COUNT  =  nvl(CAP_PROVISIONING_ATTEMPT_COUNT,0)+1
              WHERE CAP_INST_CODE = P_INST_CODE_IN AND CAP_PAN_CODE = L_HASH_PAN;
           EXCEPTION 
                   WHEN OTHERS  THEN
               l_resp_cde := '21';
                l_err_msg := 'Exception While updating provisioning count and flag TO N ' ||substr(SQLERRM,1,200);
            END;
             ELSE 
           BEGIN
              UPDATE CMS_APPL_PAN
              SET CAP_PROVISIONING_ATTEMPT_COUNT  = nvl(CAP_PROVISIONING_ATTEMPT_COUNT,0)+1
              WHERE CAP_INST_CODE = P_INST_CODE_IN AND CAP_PAN_CODE = L_HASH_PAN;
            EXCEPTION  
                    WHEN OTHERS THEN
              l_resp_cde := '21';
              l_err_msg := 'Exception While updating provisioning count and flag ' ||substr(SQLERRM,1,200);   
            END;
         END IF;
         END IF;

WHEN exp_reject_record   THEN
            ROLLBACK TO l_auth_savepoint;
WHEN OTHERS   THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO L_AUTH_SAVEPOINT;
END;

   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
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
               p_resp_id_out := '69'; --Added for VMS-8018
         END;
      --En Get responce code from master
 --Sn Get action code,error code from  token response master
         BEGIN
            SELECT vtr_elg_action_code,vtr_error_code
              INTO p_action_code_out,p_error_code_out
              FROM vms_token_response_mast
             WHERE vtr_inst_code = p_inst_code_in
               AND vtr_delivery_channel = p_delivery_channel_in
               AND vtr_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem while selecting data from token response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '69';
         END;
      --En Get action code,error code from  token response master
      
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
                        NULL,
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
                        p_tran_amt_in,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_stan_in
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            P_TRAN_AMT_IN,
                            NULL,--l_cell_no,
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
                            L_LOGDTL_RESP,
                            NULL,--l_email_id
                            null,
                            p_stan_in
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;

END check_eligibility;

 PROCEDURE  TokenServiceAdvice (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_token_in   		              in  	varchar2,
          p_tran_amt_in                 in  	varchar2,
          p_curr_code_in                in  	varchar2,
          p_expry_date_in               in  	varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_cntry_code_in               in  	varchar2,
          p_response_code_in            in  	varchar2,
          p_stan_in                     in  	varchar2,
          p_ntw_settl_date              IN  	VARCHAR2,          
          p_activation_result           in  	varchar2,
          p_token_type_in   		        in  	varchar2,
          p_token_status_in   		      in  	varchar2,
          p_token_assurance_level_in    in  	varchar2,
          p_token_requester_id_in   	  in  	varchar2,
          p_token_ref_id_in   		      in  	varchar2,
          p_token_expry_date_in         in  	varchar2,
          p_token_pan_ref_id_in         in  	varchar2,
          p_token_wpriskassessment_in   in  	varchar2,
          p_token_wpriskassess_ver_in in  	varchar2,
          p_token_wpdevice_score_in     in  	varchar2,
          p_token_wpaccount_score_in    in  	varchar2,
          p_token_wpreason_codes_in     in  	varchar2,
          p_token_wppan_source_in       in  	varchar2,
          p_token_wpacct_id_in          in  	varchar2,
          p_token_wpacct_email_in       in  	varchar2,
          p_token_device_type_in        in  	varchar2,
          p_token_device_langcode_in    in  	varchar2,
          p_token_device_id_in          in  	varchar2,
          p_token_device_no_in          in  	varchar2,
          p_token_device_name_in        in  	varchar2,
          p_token_device_loc_in         in  	varchar2,
          p_token_device_ip_in          in  	varchar2,
          p_token_device_secureeleid_in in  	varchar2,
          P_TOKEN_RISKASSESS_SCORE_IN  IN  	VARCHAR2,
          P_TOKEN_PROVISIONING_SCORE_IN IN  	VARCHAR2,
          p_msg_reason_code_in          in    varchar2,
          p_contactless_usage_in        IN  	VARCHAR2,
          p_card_ecomm_usage_in         in  	varchar2,
          P_MOB_ECOMM_USAGE_IN_IN       IN  	VARCHAR2,
          p_wallet_identifier_in        IN  	VARCHAR2,
          p_storage_tech_in             IN  	VARCHAR2, 
          P_TOKEN_REQID13_IN            IN  	VARCHAR2,
          P_WP_REQID_IN                 IN  	VARCHAR2,
          P_WP_CONVID_IN                IN  	VARCHAR2,
          P_WALLET_ID_IN                IN  	VARCHAR2,
          P_PAYMENT_APPPLNINSTANCEID_IN  IN  	VARCHAR2,
          p_auth_id_out                 out 	varchar2,
          p_resp_code_out               out 	varchar2,
          P_ISO_RESP_CODE_OUT           OUT 	VARCHAR2,
          p_resmsg_out                  out 	varchar2,
          P_ACTION_CODE_OUT             OUT  	VARCHAR2,
          p_error_code_out              out  	varchar2,
          P_TOKEN_ACT_FLAG_OUT           out   varchar2,
          p_resp_id_out                  out   varchar2 --Added for sending to FSS (VMS-8018)
          
   )
   IS
      /************************************************************************************************************
       * Created Date     :  23-JUNE-2016
       * Created By       :  T.Narayanaswamy
       * Created For      :  VISA Tokenization
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD_4.4_B0001
	   
	   * Created Date     :  06-JUNE-2016
       * Created By       :  MAGESHKUMAR S
       * Created For      :  VISA Tokenization
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD_4.4_B0002
	   
       * Modified by      : T.Narayanaswamy/Dhinakar.B
       * Modified Date    : 27-September-2017
       * Modified reason  : FSS-5277 - Additional Tokenization Changes
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST_17.05.07

       * Modified by      : Areshka A.
       * Modified Date    : 03-Nov-2023
       * Modified reason  : VMS-8018: Added new out parameter (response id) for sending to FSS
       * Reviewer         : 
       * Build Number     : 
	   
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      L_LOGIN_TXN            CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;
      L_LOGDTL_RESP          VARCHAR2 (500);
      L_PREAUTH_TYPE         CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
      EXP_REJECT_RECORD      EXCEPTION;
      L_TOKEN_STATUS         vms_token_info.vti_token_stat%type;  -- VARCHAR2 (1);
      L_TOKEN_OLD_STATUS      vms_token_info.vti_token_stat%type;--  VARCHAR2 (1);
      

      l_customer_id    cms_cust_mast.CCM_CUST_ID%type;
   BEGIN
      l_resp_cde := '1';
      l_err_msg:='OK';
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
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
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
               RAISE exp_reject_record;
         END;
         --End Generate HashKEY
         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code,ccm_cust_id
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code,l_customer_id
              from cms_appl_pan,cms_cust_mast
             where cap_inst_code=ccm_inst_code and cap_cust_code=ccm_cust_code and 
             cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --End Get the card details
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
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details'|| SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
         --En generate auth id
         
     BEGIN
      SELECT
        trim(VTI_TOKEN_STAT)
      INTO
        l_token_old_status
      FROM
        vms_token_info
      WHERE
        vti_token       = trim(p_token_in)
      AND vti_token_pan = l_hash_pan for update;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --l_resp_cde := '5';
     -- l_err_msg     := 'Token not Found';
     -- RAISE exp_reject_record;
     NULL;
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg     := 'Problem while selecting token stat1' || SUBSTR(SQLERRM, 1,
      200);
      RAISE EXP_REJECT_RECORD;
    END;
  
    BEGIN
      SELECT
        trim(VTT_TOKEN_NEW_STATUS) INTO L_TOKEN_STATUS
      FROM
        VMS_TOKEN_TXN_MAPPING
      WHERE
        VTT_DELIVERY_CHANNEL =P_DELIVERY_CHANNEL_IN
      AND VTT_TRAN_CODE      =P_TXN_CODE_IN
      AND VTT_TOKEN_STATUS=L_TOKEN_OLD_STATUS;
       EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;     
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg     := 'Problem while selecting token stat2' || SUBSTR(SQLERRM, 1,
      200);
      RAISE EXP_REJECT_RECORD;
    END;
    
     if trim(p_token_in) is not null  then            
               LP_TOKEN_CREATE_UPDATE(P_TOKEN_IN,
                L_HASH_PAN,
                P_TOKEN_TYPE_IN,
                'I',
                P_TOKEN_ASSURANCE_LEVEL_IN,
                P_TOKEN_REQUESTER_ID_IN,
                P_TOKEN_REF_ID_IN,
                P_TOKEN_EXPRY_DATE_IN,
                P_TOKEN_PAN_REF_ID_IN,
                P_TOKEN_WPPAN_SOURCE_IN,
                P_TOKEN_WPRISKASSESSMENT_IN,
                P_TOKEN_WPRISKASSESS_VER_IN,
                P_TOKEN_WPDEVICE_SCORE_IN,
                P_TOKEN_WPACCOUNT_SCORE_IN,
                P_TOKEN_WPREASON_CODES_IN,
                P_TOKEN_WPACCT_ID_IN,
                P_TOKEN_WPACCT_EMAIL_IN,
                P_TOKEN_DEVICE_TYPE_IN,
                P_TOKEN_DEVICE_LANGCODE_IN,
                P_TOKEN_DEVICE_ID_IN  ,
                P_TOKEN_DEVICE_NO_IN,
                P_TOKEN_DEVICE_NAME_IN,
                P_TOKEN_DEVICE_LOC_IN,
                P_TOKEN_DEVICE_IP_IN,
                P_TOKEN_DEVICE_SECUREELEID_IN,
                P_WALLET_IDENTIFIER_IN,
                P_STORAGE_TECH_IN,
                P_TOKEN_RISKASSESS_SCORE_IN,
                P_TOKEN_PROVISIONING_SCORE_IN,
                P_CONTACTLESS_USAGE_IN,
                P_CARD_ECOMM_USAGE_IN,
                P_MOB_ECOMM_USAGE_IN_IN,
                L_ACCT_NUMBER,
                L_CUST_CODE,
                P_INST_CODE_IN,
                P_TOKEN_REQID13_IN,
                P_WP_REQID_IN,
                P_WP_CONVID_IN,
                P_WALLET_ID_IN,
                P_PAYMENT_APPPLNINSTANCEID_IN,
                p_token_ref_id_in,
                L_RESP_CDE,
                l_err_msg
                );
              
              IF L_ERR_MSG <> 'OK' THEN
                  RAISE  EXP_REJECT_RECORD; 
              END IF;  
				 IF p_txn_code_in = '10' THEN
                BEGIN
                    UPDATE vms_token_info
                    SET
                        vti_token_stat = 'A',
                        vti_token_old_status = 'D'
                    WHERE
                        vti_token = TRIM(p_token_in)
                        AND vti_token_pan = l_hash_pan
                        AND vti_token_stat = 'D';    
                EXCEPTION
                    WHEN OTHERS THEN
                  RAISE  EXP_REJECT_RECORD; 
                END;
              END IF;   
         END IF; 
		 

    IF p_txn_code_in in('09','10') THEN
    
    IF p_response_code_in < '100'  THEN
    l_token_status := 'A';
    ELSE
    l_token_status := 'I';
    END IF;
    
    END IF;
    BEGIN 
  IF p_txn_code_in = '10' THEN
     if p_activation_result = '1' then     
      update_token_status( p_token_in, l_hash_pan, 'A', L_ERR_MSG);
      IF l_err_msg <> 'OK' THEN
        RAISE exp_reject_record;
      END IF;
    end if;    
  ELSE
    IF L_TOKEN_STATUS IS NOT NULL THEN
      update_token_status( p_token_in, l_hash_pan, l_token_status, L_ERR_MSG);
      IF l_err_msg <> 'OK' THEN
        RAISE exp_reject_record;
      END IF;
    END IF;
  End IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      l_resp_cde := '119';
      l_err_msg  := 'Error from  Token Validation Procedure  ' || SUBSTR (SQLERRM,
      1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
       
    LP_GET_TOKEN_STATUS(
                      P_TOKEN_IN,
                      l_hash_pan,
                      L_TOKEN_OLD_STATUS,
                      P_TOKEN_ACT_FLAG_OUT);
    
    IF p_txn_code_in not in('09','10') THEN
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
                              p_tran_amt_in,
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
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         END IF;
         
         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
           -- FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14'; 
           l_err_msg  := 'Invalid Card ';
           RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
/*         BEGIN
            sp_fee_calc (p_inst_code_in,
                         p_msg_type_in,
                         p_rrn_in,
                         p_delivery_channel_in,
                         p_txn_code_in,
                         p_txn_mode_in,
                         p_tran_date_in,
                         p_tran_time_in,
                         p_mbr_numb_in,
                         p_rvsl_code_in,
                         l_txn_type,
                         p_curr_code_in,
                         p_tran_amt_in,
                         p_pan_code_in,
                         l_hash_pan,
                         l_encr_pan,
                         l_acct_number,
                         l_prod_code,
                         l_card_type,
                         l_preauth_flag,
                         NULL,
                         NULL,
                         NULL,
                         l_trans_desc,
                         l_dr_cr_flag,
                         l_acct_bal,
                         l_ledger_bal,
                         l_acct_type,
                         l_login_txn,
                         p_auth_id_out,
                         l_time_stamp,
                         l_resp_cde,
                         l_err_msg,
                         l_fee_code,
                         l_fee_plan,
                         l_feeattach_type,
                         l_tranfee_amt,
                         l_total_amt,
                         l_preauth_type
                        );
            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                       'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;*/
         l_resp_cde := '1';
         l_err_msg:='OK';
     EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;
   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
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
               p_resp_id_out := '69'; --Added for VMS-8018
         END;
      --En Get responce code from master
      
       IF p_txn_code_in not in('09','10') THEN
         --Sn Get action code,error code from  token response master
         BEGIN
            SELECT vtr_action_code,vtr_servadv_errcode
              INTO p_action_code_out,p_error_code_out
              FROM vms_token_response_mast
             WHERE vtr_inst_code = p_inst_code_in
               AND vtr_delivery_channel = p_delivery_channel_in
               AND vtr_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem while selecting data from token response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '69';
         end;
      --En Get action code,error code from  token response master
      end if;

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
                        NULL,
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
                        p_tran_amt_in,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_stan_in,
                        p_ntw_settl_date
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            p_tran_amt_in,
                            null,
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
                            L_LOGDTL_RESP,
                            null,
                            p_response_code_in,
                            p_stan_in
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;
      
      
      
      
      
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resp_id_out := '69'; --Added for VMS-8018
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END TokenServiceAdvice;

  
   PROCEDURE  TokenCreateAdvice (
         p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_token_in   		              in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_token_type_in   		        in  	varchar2,
          p_token_status_in   		      in  	varchar2,
          p_token_assurance_level_in    in  	varchar2,
          p_token_requester_id_in   	  in  	varchar2,
          p_token_ref_id_in   		      in  	varchar2,
          p_token_expry_date_in         in  	varchar2,
          p_token_pan_ref_id_in         in  	varchar2,
          p_token_wpriskassessment_in   in  	varchar2,
          p_token_wpriskassess_ver_in in  	varchar2,
          p_token_wpdevice_score_in     in  	varchar2,
          p_token_wpaccount_score_in    in  	varchar2,
          p_token_wpreason_codes_in     in  	varchar2,
          p_token_wppan_source_in       in  	varchar2,
          p_token_wpacct_id_in          in  	varchar2,
          p_token_wpacct_email_in       in  	varchar2,
          p_token_device_type_in        in  	varchar2,
          p_token_device_langcode_in    in  	varchar2,
          p_token_device_id_in          in  	varchar2,
          p_token_device_no_in          in  	varchar2,
          p_token_device_name_in        in  	varchar2,
          p_token_device_loc_in         in  	varchar2,
          p_token_device_ip_in          in  	varchar2,
          p_token_device_secureeleid_in in  	varchar2,
          p_token_riskassess_score_in  in  	varchar2,
          p_token_provisioning_score_in in  	varchar2,
          p_curr_code_in                in    varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_stan_in                     in  	varchar2,
          p_ntw_settl_date              in  	varchar2,
          p_expry_date_in               IN  	VARCHAR2,
          p_msg_reason_code_in          in    varchar2,
          p_contactless_usage_in        IN  	VARCHAR2,
          p_card_ecomm_usage_in         in  	varchar2,
          p_mob_ecomm_usage_in_in       IN  	VARCHAR2,
          p_wallet_identifier_in       IN  	VARCHAR2,
          p_storage_tech_in             IN  	VARCHAR2,     
          p_rule_response               IN  	VARCHAR2,
          p_auth_id_out                 out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2,
          p_de27response_out            out   varchar2
          ,p_token_reqid13_in         in  	varchar2 default null
          ,p_wp_reqid_in              in  	varchar2 default null
          ,P_WP_CONVID_IN             IN  	VARCHAR2 DEFAULT NULL
          ,P_WALLET_ID_IN             IN  	VARCHAR2 DEFAULT NULL
          ,P_TOKEN_ACT_FLAG_OUT           out   varchar2
          ,p_resp_id_out                  out   varchar2 --Added for sending to FSS (VMS-8018)
          )
   IS
      /************************************************************************************************************
       * Created Date     :  05-JULY-2016
       * Created By       : Saravanakumar
       * Created For      :  VISA Tokenization
       * Reviewer         :  SPankaj
       * Build Number     :  VMSGPRHOSTCSD_4.5_B0001
       
       * Modified by      : T.Narayanaswamy
       * Modified For     : Token Provision retry count changes
       * Modified Date    : 28-December-2016
       * Modified reason  : Token Provision retry count changes
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST4.7
       
       * Modified by      : T.Narayanaswamy
       * Modified For     : Master card Tokenization changes
       * Modified Date    : 12-May-2017
       * Modified reason  : Master card Tokenization changes
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST_17.05
	   
       * Modified by      : T.Narayanaswamy/Dhinakar.B
       * Modified Date    : 27-September-2017
       * Modified reason  : FSS-5277 - Additional Tokenization Changes
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST_17.05.07
       
       * Modified Date     :  05-Sep-2017
       * Modified By       :  Siva Kumar M
       * Modified For      :  FSS-5199
       * Reviewer          :  Saravanakumar/SPankaj
       * Build Number      :  VMSGPRHOST_17.08
	   * Modified by      : T.Narayanaswamy
       * Modified Date    : 01-November-2017
       * Modified reason  : DE-27 should be send only for Yellow Cases.
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST_17.09.03
       
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01
	 
     * Modified By      : BASKAR KRISHNAN
     * Modified Date    : 07-FEB-2019
     * Purpose          : VMS-511 (Permanent Fraud Override Support)
     * Reviewer         : Saravanakumar
     * Release Number   : VMSR12_B0003
     
     * Modified By      : MageshKumar
     * Modified Date    : 21-Aug-2020
     * Purpose          : VMS-2981
     * Reviewer         : Saravanakumar
     * Release Number   : VMSGPRHOST_R35_B0001

     * Modified By      : Areshka A.
     * Modified Date    : 03-Nov-2023
     * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
     * Reviewer         : 
     * Release Number   : 
       
      ************************************************************************************************************/
      
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      L_LOGIN_TXN            CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;
      L_LOGDTL_RESP          VARCHAR2 (500);
      L_PREAUTH_TYPE         CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
      EXP_REJECT_RECORD      EXCEPTION;
      L_TOKEN_STATUS        VARCHAR2 (1);    
      L_DURATION_DIFF            NUMBER;
      L_CARDPACK_ID              CMS_APPL_PAN.CAP_CARDPACK_ID%TYPE;
      l_customer_id    cms_cust_mast.CCM_CUST_ID%type;            
      l_cell_no cms_addr_mast.cam_mobl_one%type;
      l_email_id cms_addr_mast.cam_email%type;
      l_de27_length number  default 0;
      l_de27_mobile varchar2(200):='';
      L_DE27_EMAIL VARCHAR2(200):='';
      L_RULE_RESPONSE varchar2(20);
      L_RULE_COUNT NUMBER(5);
      L_WALLET_ID VARCHAR2(200);
      L_TOKEN_OLD_STATUS      VMS_TOKEN_INFO.VTI_TOKEN_STAT%TYPE;   	 
     l_rule_bybass             cms_appl_pan.cap_rule_bypass%TYPE;
     l_remarks            varchar2(200);
     l_customer_cardnum  cms_prod_cattype.cpc_customer_care_num%type;
     l_de27_customercare_number  varchar2(200):='';
     l_encrypt_enable         cms_prod_cattype.cpc_encrypt_enable%type;
	 l_otp_channel cms_prod_cattype.cpc_otp_channel%type;   --VMS-8262
     l_vms8262_toggle cms_inst_param.cip_param_value%type :='Y';  --VMS-8262

   BEGIN
      l_resp_cde := '1';
      l_err_msg :='OK';
      p_resmsg_out:='OK';
      l_time_stamp := SYSTIMESTAMP;
      BEGIN

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
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
               RAISE exp_reject_record;
         END;
         --End Generate HashKEY

         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   CAP_PRFL_CODE, CAP_EXPRY_DATE, CAP_PROXY_NUMBER,
                   cap_cust_code,ccm_cust_id,CAP_CARDPACK_ID,cap_rule_bypass
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   L_PRFL_CODE, L_EXPRY_DATE, L_PROXY_NUMBER,
                   l_cust_code,l_customer_id,L_CARDPACK_ID,l_rule_bybass
              from cms_appl_pan,cms_cust_mast
             where cap_inst_code=ccm_inst_code and cap_cust_code=ccm_cust_code and
             cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --End Get the card details  
         
         BEGIN
            SELECT cpc_encrypt_enable, decode(cpc_otp_channel,'0','N/A','1','SMS','2','EMAIL','3','SMS AND EMAIL','SMS AND EMAIL')
              INTO l_encrypt_enable, l_otp_channel
              FROM cms_prod_cattype
             WHERE cpc_prod_code = l_prod_code
             AND  cpc_card_type = l_card_type
             AND cpC_inst_code = p_inst_code_in; 
             
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'No data found for prod code and card type ' || l_prod_code || l_card_type;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting encrypt enable flag details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
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
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details '||substr(sqlerrm,1,200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
         --En generate auth id

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
           -- FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14';
           l_err_msg  := 'Invalid Card ';
           RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
		 
		 BEGIN
      SELECT
        trim(VTI_TOKEN_STAT)
      INTO
        l_token_old_status
      FROM
        vms_token_info
      WHERE
        vti_token       = trim(p_token_in)
      AND vti_token_pan = l_hash_pan;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --l_resp_cde := '5';
     -- l_err_msg     := 'Token not Found';
     -- RAISE exp_reject_record;
     NULL;
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg     := 'Problem while selecting token stat1' || SUBSTR(SQLERRM, 1,
      200);
      RAISE EXP_REJECT_RECORD;
    END;
         
         
        BEGIN
        select decode(p_msg_reason_code_in,'0259',p_wallet_identifier_in,p_token_requester_id_in)  into l_wallet_id from dual;
         
         IF  P_TXN_CODE_IN IN ('04','09') THEN        
         
          SELECT VTR_RULE_RESPONSE INTO L_RULE_RESPONSE 
          FROM VMS_TOKEN_RULE_RESPLOG WHERE VTR_PAN_CODE=L_HASH_PAN AND
          VTR_WALLET_ID=l_wallet_id  AND VTR_DEVICE_ID=p_token_device_id_in;      
               
         elsif p_txn_code_in='11' THEN
            L_RULE_RESPONSE:='Y';
          END IF;
              
         EXCEPTION       
         WHEN NO_DATA_FOUND THEN
         L_RULE_RESPONSE:='G';
        
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting VMS_TOKEN_TRANSACTIONLOG details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
         
         LP_GET_TOKEN_STATUS(
                      P_TOKEN_IN,
                      l_hash_pan,
                      L_TOKEN_OLD_STATUS,
                      P_TOKEN_ACT_FLAG_OUT);
    
 
  if trim(p_token_in) is not null  then
          
          
          LP_TOKEN_CREATE_UPDATE(P_TOKEN_IN,
          L_HASH_PAN,
          P_TOKEN_TYPE_IN,
          L_RULE_RESPONSE,
          P_TOKEN_ASSURANCE_LEVEL_IN,
          P_TOKEN_REQUESTER_ID_IN,
          P_TOKEN_REF_ID_IN,
          P_TOKEN_EXPRY_DATE_IN,
          P_TOKEN_PAN_REF_ID_IN,
          P_TOKEN_WPPAN_SOURCE_IN,
          P_TOKEN_WPRISKASSESSMENT_IN,
          P_TOKEN_WPRISKASSESS_VER_IN,
          P_TOKEN_WPDEVICE_SCORE_IN,
          P_TOKEN_WPACCOUNT_SCORE_IN,
          P_TOKEN_WPREASON_CODES_IN,
          P_TOKEN_WPACCT_ID_IN,
          P_TOKEN_WPACCT_EMAIL_IN,
          P_TOKEN_DEVICE_TYPE_IN,
          P_TOKEN_DEVICE_LANGCODE_IN,
          P_TOKEN_DEVICE_ID_IN  ,
          P_TOKEN_DEVICE_NO_IN,
          P_TOKEN_DEVICE_NAME_IN,
          P_TOKEN_DEVICE_LOC_IN,
          P_TOKEN_DEVICE_IP_IN,
          P_TOKEN_DEVICE_SECUREELEID_IN,
          P_WALLET_IDENTIFIER_IN,
          P_STORAGE_TECH_IN,
          P_TOKEN_RISKASSESS_SCORE_IN,
          P_TOKEN_PROVISIONING_SCORE_IN,
          P_CONTACTLESS_USAGE_IN,
          P_CARD_ECOMM_USAGE_IN,
          P_MOB_ECOMM_USAGE_IN_IN,
          L_ACCT_NUMBER,
          L_CUST_CODE,
          P_INST_CODE_IN,
          P_TOKEN_REQID13_IN,
          P_WP_REQID_IN,
          P_WP_CONVID_IN,
          P_WALLET_ID_IN,
          null,
          p_token_ref_id_in,
          L_RESP_CDE,
          l_err_msg
          );
        
        IF L_ERR_MSG <> 'OK' THEN
            RAISE  EXP_REJECT_RECORD; 
        END IF;
		IF p_txn_code_in in ('04','09') THEN
            BEGIN
                UPDATE vms_token_info
                SET
                    vti_token_stat = 'A',
                    vti_token_old_status = 'D'
                WHERE
                    vti_token = TRIM(p_token_in)
                    AND vti_token_pan = l_hash_pan
                    AND vti_token_stat = 'D';    
            EXCEPTION
                WHEN OTHERS THEN
                RAISE exp_reject_record;
            END;
        END IF;
     END IF;
         
         
   if p_txn_code_in='11' THEN      
         BEGIN
           update cms_appl_pan 
           set   cap_provisioning_flag ='Y', cap_provisioning_attempt_count=0,cap_rule_bypass=decode(l_rule_bybass,'P',cap_rule_bypass,'N')
          WHERE CAP_INST_CODE = P_INST_CODE_IN AND CAP_PAN_CODE = L_HASH_PAN;
          EXCEPTION  
                    WHEN  OTHERS THEN
              l_resp_cde := '21';
              l_err_msg := 'Exception While updating provisioning count TO 0 and flag TO Y ' ||substr(SQLERRM,1,200); 
              RAISE  exp_reject_record; 
         END;
         
      BEGIN
       TOKEN_LOG_RULE_RESPONSE(
          P_INST_CODE_IN ,
          p_pan_code_in,
          l_wallet_id,
          p_rule_response,
          p_rrn_in ,
          p_token_in,
          p_token_device_id_in,
          l_resp_cde,
          l_err_msg);   
        EXCEPTION  
        WHEN  OTHERS THEN
        l_resp_cde := '21';
        l_err_msg := 'Exception While loging rule response ' ||substr(SQLERRM,1,200); 
        RAISE  exp_reject_record; 
        END;
        
--IF P_RULE_RESPONSE='Y' AND p_msg_reason_code_in = '0259' THEN 
      BEGIN
  SELECT
    decode(l_encrypt_enable,'Y',fn_dmaps_main(CAM_MOBL_ONE),CAM_MOBL_ONE),
                  decode(l_encrypt_enable,'Y',fn_dmaps_main(CAM_EMAIL),CAM_EMAIL)
  INTO
    l_cell_no,
    l_email_id
  FROM
    CMS_ADDR_MAST
  WHERE
    CAM_INST_CODE   = p_inst_code_in
  AND CAM_CUST_CODE = l_cust_code
  AND CAM_ADDR_FLAG = 'P';
EXCEPTION
--WHEN NO_DATA_FOUND THEN
 -- l_resp_cde := '21';
 -- l_err_msg  := 'cellphone no and email id not found for customer id';
 -- RAISE exp_reject_record;
WHEN OTHERS THEN
  l_resp_cde := '21';
  l_err_msg  :=
  'Error while selecting cellphone no and email id for physical address' ||
  SUBSTR (SQLERRM, 1, 200);
  RAISE exp_reject_record;
END;

BEGIN
       select CPC_CUSTOMER_CARE_NUM
            into  l_customer_cardnum 
            from cms_prod_cattype
          where cpc_prod_code=l_prod_code
              and cpc_card_type=l_card_type
              and cpc_inst_code=p_inst_code_in;
             EXCEPTION 
	--				WHEN NO_DATA_FOUND THEN
	--				NULL;
                   WHEN OTHERS THEN
                   l_resp_cde := '21';
                   l_err_msg := 'Error while selecting customer care number' || 
                   SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
       end;
       
       BEGIN
                Select CIP_PARAM_VALUE into l_vms8262_toggle from vmscms.cms_inst_param where cip_param_key='VMS_8262_TOGGLE';
       EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   l_vms8262_toggle:='Y';
                WHEN OTHERS THEN
                   l_resp_cde := '21';
                   l_err_msg := 'Error while selecting toggle value' ||
                   SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
        END;
          
BEGIN
  IF L_CELL_NO   IS NOT NULL THEN  
    L_CELL_NO    :=fn_mask(L_CELL_NO,'*',1,LENGTH(L_CELL_NO)-4);
    
    if p_msg_reason_code_in = '0259' THEN
     l_de27_mobile:=rpad('CELL_PHONE',32,' ')||rpad(l_cell_no,64,' ')||rpad(' ',32,' ')||rpad(' ',64,' ');
    ELSE
      l_de27_mobile:=rpad('CELL_PHONE',32,' ')||rpad(l_cell_no,64,' ')||rpad(('CELL_'||l_customer_id),32,' ')||rpad(' ',64,' ');
    end if;
    
  END IF;
  IF l_customer_cardnum IS NOT NULL THEN
    if p_msg_reason_code_in = '0259' THEN
     l_de27_customercare_number:=rpad('CUSTOMER_SERVICE',32,' ')||rpad(l_customer_cardnum,64,' ')||rpad(' ',32,' ')||rpad(' ',64,' ');
    ELSE
			  l_de27_customercare_number:=rpad('CUSTOMER_SERVICE',32,' ')||rpad(l_customer_cardnum,64,' ')||rpad(('CUSTOMER_'||l_customer_id),32,' ')||rpad(' ',64,' ');
    end if;
  END IF; 

  IF L_EMAIL_ID IS NOT NULL THEN
    SELECT
      (
        SELECT
          listagg (CHR, '') WITHIN GROUP (
        ORDER BY
          rnum)
        FROM
          (
            SELECT
              CASE
                WHEN LEVEL > 1
                AND LEVEL  < INSTR (L_EMAIL_ID, '@') - 1
                THEN '*'
                ELSE REGEXP_SUBSTR (L_EMAIL_ID, '.', LEVEL)
              END CHR,
              ROWNUM rnum
            FROM
              DUAL
              CONNECT BY LEVEL <= LENGTH (L_EMAIL_ID)
          )
      )
    INTO
      L_EMAIL_ID
    FROM
      dual;
   
    IF p_msg_reason_code_in = '0259' THEN
      l_de27_email:=rpad('EMAIL',32,' ')||rpad(l_email_id,64,' ')||rpad(' ',32,' ')||rpad(' ',64,' ');
    ELSE
      l_de27_email:=rpad('EMAIL',32,' ')||rpad(l_email_id,64,' ')||rpad(('EMAIL_'||l_customer_id),32,' ')||rpad(' ',64,' ');
    END IF;
    
  END IF;

        if(l_vms8262_toggle = 'N') then
                if (l_de27_mobile is not null or l_de27_email is not null or l_de27_customercare_number is not null) then
                        p_de27response_out:='027'||length(l_de27_mobile||l_de27_email||l_de27_customercare_number)||
                        l_de27_mobile||l_de27_email||l_de27_customercare_number;
                else
                    P_DE27RESPONSE_OUT:='';
                    --L_RESP_CDE := '21';
                    --L_ERR_MSG := 'cellphone no and email id not found for customer id';
                    --raise exp_reject_record;                                      
                end if;
        else
                if (l_otp_channel = 'N/A' and l_de27_customercare_number is not null) then
                    p_de27response_out:='027'||length(l_de27_customercare_number)||l_de27_customercare_number;
                elsif (l_otp_channel = 'SMS' and (l_de27_mobile is not null or l_de27_customercare_number is not null)) then
                    p_de27response_out:='027'||length(l_de27_mobile||l_de27_customercare_number)||l_de27_mobile||l_de27_customercare_number;
                elsif  (l_otp_channel = 'EMAIL' and (l_de27_email is not null or l_de27_customercare_number is not null)) then
                    p_de27response_out:='027'||length(l_de27_email||l_de27_customercare_number)||l_de27_email||l_de27_customercare_number;
                elsif (l_otp_channel = 'SMS AND EMAIL')
                  and (l_de27_mobile is not null or l_de27_email is not null or l_de27_customercare_number is not null) then
                    p_de27response_out:='027'||length(l_de27_mobile||l_de27_email||l_de27_customercare_number)||
                    l_de27_mobile||l_de27_email||l_de27_customercare_number;
                else
                    P_DE27RESPONSE_OUT:='';
                    --L_RESP_CDE := '21';
                    --L_ERR_MSG := 'cellphone no and email id not found for customer id';
                    --raise exp_reject_record;
                end if;
		end if;
END;
--END IF;
end if;


        LP_GET_TOKEN_STATUS(
                      P_TOKEN_IN,
                      l_hash_pan,
                      L_TOKEN_OLD_STATUS,
                      P_TOKEN_ACT_FLAG_OUT);
      
     EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK ;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK ;
      END;
      
   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
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
               p_resp_id_out := '69'; --Added for VMS-8018
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
      begin
	  select decode(NVL(l_rule_bybass,'N'),'Y','Rule Bypass Flag Enabled','P','Rule Bypass Flag Enabled',NULL) INTO l_remarks from dual;
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
                        NULL,
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
                        0,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        l_remarks,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_stan_in,
                        p_ntw_settl_date
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            0,
                            null,
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
                            L_LOGDTL_RESP,
                            null,
                            null,
                            p_stan_in
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resp_id_out := '69'; --Added for VMS-8018
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   end tokencreateadvice;

   

--BEGIN
   -- Initialization
  -- NULL;
--END;



PROCEDURE  Token_STIPAdvice(p_inst_code_in  in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_tran_amt_in                 in  	varchar2,
          p_curr_code_in                in  	varchar2,
          P_EXPRY_DATE_IN               IN  	VARCHAR2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_cntry_code_in               in  	varchar2,
          p_stan_in                     in  	varchar2,
          p_adj_resp_cod_in             in    varchar2,
          p_auth_id_out                 out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2,
          p_resp_id_out                 out 	varchar2 --Added for sending to FSS (VMS-8018)
          )
IS
/************************************************************************************************************
     * Modified by      : Siva Kumar M
     * Modified For     : FSS-4423
     * Modified Date    : 07-July-2016
     * Modified reason  : Tokenization Changes
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.5_B0002
     
     * Modified by      : Siva Kumar M
     * Modified For     : FSS-4423
     * Modified Date    : 11-July-2016
     * Modified reason  : Tokenization Changes
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.5_B0003
     
     * Modified by      : Areshka A.
     * Modified For     : VMS-8018
     * Modified Date    : 03-Nov-2023
     * Modified reason  : Added new out parameter (response id) for sending to FSS
     * Reviewer         : 
     * Build Number     : 
     
************************************************************************************************************/
      
      l_auth_savepoint       NUMBER          DEFAULT 0;
      l_err_msg              VARCHAR2 (500);
      l_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type             transactionlog.txn_type%TYPE;
      l_auth_id              transactionlog.auth_id%TYPE;
      exp_reject_record      EXCEPTION;
      l_dr_cr_flag           VARCHAR2 (2);
      l_tran_type            VARCHAR2 (2);
      l_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_card_type            cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde             VARCHAR2 (5);
      l_time_stamp           TIMESTAMP;
      l_hashkey_id           cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_trans_desc           cms_transaction_mast.ctm_tran_desc%TYPE;
      l_acct_number          cms_appl_pan.cap_acct_no%TYPE;
      l_card_stat            cms_appl_pan.cap_card_stat%TYPE;
      l_preauth_flag         cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type            cms_acct_mast.cam_type_code%TYPE;
      l_proxy_number         cms_appl_pan.cap_proxy_number%TYPE;
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
       l_comb_hash            pkg_limits_check.type_hash;
      l_login_txn            cms_transaction_mast.ctm_login_txn%TYPE;
      L_LOGDTL_RESP          VARCHAR2 (500);
      L_PREAUTH_TYPE         CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
 
BEGIN
 
     L_ERR_MSG :='OK';
 BEGIN 
  savepoint l_auth_savepoint;
 --Sn Get the HashPan
      BEGIN
          L_HASH_PAN := GETHASH (P_PAN_CODE_IN);
             EXCEPTION  WHEN OTHERS    THEN
               l_resp_cde := '12';
               l_err_msg :='Error while converting hash pan '|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
      END;
 --En Get the HashPan
     --Sn Create encr pan
      BEGIN
          L_ENCR_PAN := FN_EMAPS_MAIN (P_PAN_CODE_IN);
            EXCEPTION  WHEN OTHERS  THEN
             l_resp_cde := '12';
             L_ERR_MSG :='Error while converting emcrypted pan ' || SUBSTR (SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
      END;
        --Start Generate HashKEY value
      --Start Generate HashKEY value
             BEGIN
             l_hashkey_id :=gethash (p_delivery_channel_in
                            || p_txn_code_in
                            || p_pan_code_in
                            || p_rrn_in
                            || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5'));
              EXCEPTION  WHEN OTHERS  THEN
                   l_resp_cde := '21';
                   l_err_msg :=  'Error while Generating  hashkey id data '  || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
             END;
        --End Generate HashKEY
      
 --Sn find debit and credit flag
             BEGIN
                SELECT ctm_credit_debit_flag,
                       TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                       ctm_tran_type, ctm_tran_desc, 
                       ctm_preauth_flag, ctm_login_txn, ctm_preauth_type
                  INTO l_dr_cr_flag,
                       l_txn_type,
                       l_tran_type, l_trans_desc,
                       l_preauth_flag, l_login_txn, l_preauth_type
                  FROM cms_transaction_mast
                 WHERE ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in
                   AND CTM_INST_CODE = P_INST_CODE_IN;
             EXCEPTION WHEN NO_DATA_FOUND THEN
                   l_resp_cde := '12';
                   l_err_msg :='Transaction not defined for txn code ' || p_txn_code_in|| ' and delivery channel '|| p_delivery_channel_in||SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
                WHEN OTHERS
                THEN
                   l_resp_cde := '21';
                   l_err_msg := 'Error while selecting transaction details'||p_txn_code_in||p_delivery_channel_in||P_INST_CODE_IN||SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
             END;
  --En find debit and credit flag
  --Sn generate auth id
              BEGIN
                  SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
                          INTO p_auth_id_out
                          FROM DUAL;
                EXCEPTION  WHEN OTHERS THEN
                           l_err_msg := 'Error while generating authid '|| SUBSTR (SQLERRM, 1, 200);
                           l_resp_cde := '21';                        
                           RAISE exp_reject_record;
              END;
  --En generate auth id
     --Sn Get the card details
             BEGIN
                    SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,cap_proxy_number
                     INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,l_proxy_number
                     FROM cms_appl_pan
                     WHERE CAP_INST_CODE = P_INST_CODE_IN 
                     AND CAP_PAN_CODE = L_HASH_PAN;
             EXCEPTION  
                     WHEN NO_DATA_FOUND  THEN
                       l_resp_cde := '16';
                       l_err_msg := 'Card number not found ' || L_HASH_PAN;
                       RAISE EXP_REJECT_RECORD;
                     WHEN OTHERS THEN
                       l_resp_cde := '21';
                       l_err_msg :='Problem while selecting card detail'|| SUBSTR (SQLERRM, 1, 200);
                       RAISE exp_reject_record;
            END;
     --End Get the card details

         IF p_adj_resp_cod_in >= 100
            THEN
               l_resp_cde := '1';
               l_err_msg := ' STIP Advice transaction';
               RAISE exp_reject_record;
            END IF;
  
      l_resp_cde := '1';
     
EXCEPTION
    WHEN exp_reject_record   THEN
            ROLLBACK TO l_auth_savepoint;
WHEN OTHERS   THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO L_AUTH_SAVEPOINT;
END;

   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
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
               p_resp_id_out := '69'; --Added for VMS-8018
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
                   ctm_tran_type, ctm_tran_desc,ctm_preauth_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc,l_preauth_flag
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
                        NULL,
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
                        p_tran_amt_in,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_stan_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            P_TRAN_AMT_IN,
                            NULL,--l_cell_no,
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
                            L_LOGDTL_RESP,
                            NULL,--l_email_id
                            p_adj_resp_cod_in,--null,
                            p_stan_in
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;

END Token_STIPAdvice;

    PROCEDURE cleanup_suspend_tokens(p_job_id_in  IN NUMBER, p_respmsg_out OUT VARCHAR2 )
    IS
      l_count                NUMBER;
      l_rrn VMS_TOKEN_STATUS_SYNC_DTLS.vts_rrn%TYPE;
      l_stan VMS_TOKEN_STATUS_SYNC_DTLS.vts_stan%TYPE;
      cursor updt_token_cur
      IS
        SELECT token.ROWID rd, token.vti_token tokenno, token.vti_token_pan cardno, VTI_TOKEN_TYPE,
        token.vti_token_requestor_id token_requestor_id, token.vti_token_ref_id token_ref_id,panmast.CAP_PAN_CODE_ENCR pan_encr,
        token.VTI_TOKEN_STAT token_status,to_char(panmast.cap_expry_date,'MMYY') exprydate,panmast.cap_card_stat,panmast.cap_acct_no
        FROM vms_token_info token, cms_appl_pan panmast, cms_prod_cattype prodcattype
        WHERE token.vti_token_stat = DECODE(p_job_id_in,52,'S',53,'I')
        AND panmast.cap_inst_code              = token.vti_inst_code
        AND panmast.cap_pan_code               = token.vti_token_pan
        AND prodcattype.cpc_inst_code          = panmast.cap_inst_code
        AND prodcattype.cpc_prod_code          = panmast.cap_prod_code
        AND prodcattype.cpc_card_type          = panmast.cap_card_type
        AND ((p_job_id_in=52 AND prodcattype.cpc_token_retain_period< ROUND( (CAST(systimestamp AS DATE) - CAST(token.vti_lupd_date AS DATE)) * 24 * 60 ))
        OR (p_job_id_in=53 AND prodcattype.CPC_INACTIVETOKEN_RETAINPERIOD< ROUND( (CAST(systimestamp AS DATE) - CAST(token.vti_lupd_date AS DATE)) * 24 * 60 )));
    BEGIN
      p_respmsg_out:='OK';
      FOR l_idx    IN updt_token_cur
      LOOP
        BEGIN
          UPDATE vms_token_info SET vti_token_status_sync_flag = 'P' WHERE rowid = l_idx.rd;
        EXCEPTION
        WHEN OTHERS THEN
          p_respmsg_out :='Error While Updating Token Stat-'||SUBSTR(sqlerrm,100);
          RETURN;
        END;
       BEGIN
        SELECT COUNT(*)
        INTO l_count FROM vms_token_status_sync_dtls
              WHERE vts_card_no=l_idx.cardno
              AND vts_token_no=l_idx.tokenno
              AND vts_reason_code='3701';
       EXCEPTION
        WHEN OTHERS THEN
        p_respmsg_out :='Error While select count from token_status_sync_dtls-'||SUBSTR(sqlerrm,100);
        RETURN;
        END;
       IF l_count=0 THEN        
       BEGIN
       l_rrn  := LPAD(seq_auth_rrn.NEXTVAL,12,'0');
       l_stan := LPAD(seq_auth_stan.NEXTVAL,6,'0');
        INSERT
        INTO vms_token_status_sync_dtls
          ( vts_card_no, vts_token_no, vts_token_ref_id,
            vts_token_requestor_id, vts_reason_code, vts_ins_date,VTS_PAN_CODE_ENCR,VTS_TOKEN_STATUS_FLAG,vts_rrn,
            vts_stan,vts_expry_date,vts_acct_no,VTS_CARD_STAT,vts_token_type)
          VALUES
          ( l_idx.cardno, l_idx.tokenno, l_idx.token_ref_id,
            l_idx.token_requestor_id, '3701', systimestamp,l_idx.pan_encr,l_idx.token_status,
            l_rrn,l_stan,l_idx.exprydate,l_idx.cap_acct_no,l_idx.cap_card_stat,l_idx.VTI_TOKEN_TYPE);
       EXCEPTION
        WHEN OTHERS THEN
        p_respmsg_out :='Error While inserting into token_status_sync_dtls-'||SUBSTR(sqlerrm,100);
        RETURN;
       END;    
      END IF; 	   
      COMMIT;
      END LOOP;      
    EXCEPTION
    WHEN OTHERS THEN
      p_respmsg_out:='Main Excp-'||sqlerrm;
    END cleanup_suspend_tokens;  
    
    
   PROCEDURE delete_sync_tokens(
    p_token_in  VARCHAR2,
    p_cardno_in VARCHAR2,
    p_newcard_in    IN VARCHAR2,
    p_reasonCode_in IN VARCHAR2,
    p_acctno_in     IN VARCHAR2,
    p_resp_code_in  IN VARCHAR2,
    p_inst_code_in  IN VARCHAR2,
    p_card_stat_in  IN VARCHAR2,
    p_encr_pan_in   IN VARCHAR2,
    p_rrn_in        IN VARCHAR2,
    p_ccaflag_in    IN VARCHAR2 default 'Y',
    p_respmsg_out OUT VARCHAR2 )
AS
  l_token_stat vms_token_info.vti_token_stat%TYPE;
  l_txn_desc cms_transaction_mast.ctm_tran_desc%TYPE;
  l_txn_code cms_transaction_mast.ctm_tran_code%TYPE;
  l_acct_balance cms_acct_mast.cam_acct_bal%TYPE;
  l_ledger_balance cms_acct_mast.cam_ledger_bal%TYPE;
  l_encr_pan cms_appl_pan.cap_pan_code_encr%TYPE;
BEGIN
  p_respmsg_out:='OK';
  BEGIN
    l_encr_pan := FN_EMAPS_MAIN (p_encr_pan_in);
  EXCEPTION
  WHEN OTHERS THEN
    p_respmsg_out :='Error while converting emcrypted pan ' || SUBSTR (SQLERRM, 1, 200);
    RETURN;
  END;
  IF p_reasonCode_in = '3721' THEN
    l_txn_code      := '66';
  ELSIF  p_reasonCode_in = '3720' THEN
    l_txn_code      := '65';
  ELSE
    BEGIN
      SELECT vts_token_stat,
        vts_host_txncode
      INTO l_token_stat,
        l_txn_code
      FROM vms_token_status
      WHERE vts_reason_code = p_reasonCode_in;
    EXCEPTION
    WHEN OTHERS THEN
      p_respmsg_out:='Error while getting token status'||SQLERRM;
      RETURN;
    END;
  END IF;
  IF p_resp_code_in = '00' THEN
    DELETE
    FROM vms_token_status_sync_dtls
    WHERE NVL(vts_token_no,'N') =NVL(p_token_in,'N')
    AND vts_acct_no             = p_acctno_in
    AND vts_reason_code         = p_reasonCode_in
    AND vts_rrn= p_rrn_in;
    IF SQL%ROWCOUNT             =0 THEN
      p_respmsg_out            :='Invalid token dtls';
    ELSE
      IF p_ccaflag_in = 'Y' THEN 
      IF p_reasonCode_in = '3721' THEN
       UPDATE vms_token_info
        SET vti_token_pan            = p_newcard_in,
          vti_token_status_sync_flag = 'S'
        WHERE vti_token_pan          =p_cardno_in;
     ELSIF p_reasonCode_in = '3720' THEN
       UPDATE vms_token_info
        SET vti_token_status_sync_flag = 'S'
        WHERE vti_token_pan          =p_cardno_in; 
      ELSE
         UPDATE vms_token_info
        SET vti_token_stat           = l_token_stat,
          vti_token_status_sync_flag = 'S'
        WHERE vti_token              =p_token_in;
        
      END IF;
    END IF;
    END IF;
  END IF;
  BEGIN
    SELECT cam_acct_bal,
      cam_ledger_bal
    INTO l_acct_balance,
      l_ledger_balance
    FROM cms_acct_mast
    WHERE cam_acct_no = p_acctno_in
    AND cam_inst_code = p_inst_code_in;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_respmsg_out := 'Invalid Card ';
    RETURN;
  WHEN OTHERS THEN
    p_respmsg_out := 'Error while selecting acct details-' || SUBSTR (SQLERRM, 1, 200);
    RETURN;
  END;
  BEGIN
    SELECT ctm_tran_desc
    INTO l_txn_desc
    FROM cms_transaction_mast
    WHERE ctm_inst_code      = p_inst_code_in
    AND ctm_tran_code        = l_txn_code
    AND ctm_delivery_channel = '05';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_respmsg_out := 'Txn not defined for txn_code-' || l_txn_code;
    RETURN;
  WHEN OTHERS THEN
    p_respmsg_out :='Error while selecting txn details-' || SUBSTR (SQLERRM, 1, 200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO transactionlog
      (
        msgtype,
        rrn,
        delivery_channel,
        txn_code,
        trans_desc,
        customer_card_no,
        customer_card_no_encr,
        business_date,
        business_time,
        txn_status,
        response_code,
        instcode,
        add_ins_date,
        response_id,
        date_time,
        customer_acct_no,
        acct_balance,
        ledger_balance,
        cardstatus
      )
      VALUES
      (
        '0200',
        p_rrn_in,
        '05',
        l_txn_code,
        l_txn_desc,
        p_cardno_in,
        l_encr_pan,
        TO_CHAR (SYSDATE, 'yyyymmdd'),
        TO_CHAR (SYSDATE, 'hh24miss'),
        DECODE(p_resp_code_in,'00','C','F'),
        DECODE(p_resp_code_in,'00','00','89'),
        1,
        SYSDATE,
        DECODE(p_resp_code_in,'00','1','89'),
        SYSDATE,
        p_acctno_in,
        l_acct_balance,
        l_ledger_balance,
        p_card_stat_in
      );
  EXCEPTION
  WHEN OTHERS THEN
    p_respmsg_out := 'Error while logging into txnlog '|| SUBSTR (SQLERRM, 1, 200);
  END;
  BEGIN
    INSERT
    INTO cms_transaction_log_dtl
      (
        ctd_delivery_channel,
        ctd_txn_code,
        ctd_txn_type,
        ctd_msg_type,
        ctd_txn_mode,
        ctd_business_date,
        ctd_business_time,
        ctd_customer_card_no,
        ctd_process_flag,
        ctd_process_msg,
        ctd_rrn,
        ctd_inst_code,
        ctd_customer_card_no_encr,
        ctd_cust_acct_number
      )
      VALUES
      (
        '05',
        l_txn_code,
        '0',
        '0200',
        0,
        TO_CHAR (SYSDATE, 'YYYYMMDD'),
        TO_CHAR (SYSDATE, 'hh24miss'),
        p_cardno_in,
        DECODE(p_resp_code_in,'00','Y','E'),
        DECODE(p_resp_code_in,'00','Successful','Failed'),
        p_rrn_in,
        p_inst_code_in,
        l_encr_pan,
        p_acctno_in
      );
  EXCEPTION
  WHEN OTHERS THEN
    p_respmsg_out := 'Error in inserting cms_transaction_log_dtl' || SUBSTR (SQLERRM, 1, 200);
    RETURN;
  END;
EXCEPTION
WHEN OTHERS THEN
  p_respmsg_out:='Main Excp from delete_sync_tokens-'||sqlerrm;
END delete_sync_tokens; 
    
    PROCEDURE cardno_tokens_sync (p_cardno_in IN VARCHAR2,p_respmsg_out OUT VARCHAR2 )
    IS
      l_count                NUMBER;		
      cursor ins_token_cur
      IS
        SELECT token.vti_token tokenno, token.vti_token_pan cardno, token.VTI_TOKEN_TYPE tokenType,
        token.vti_token_requestor_id token_requestor_id, token.vti_token_ref_id token_ref_id,pan.cap_pan_code_encr pan_encr
        FROM vms_token_info token,cms_appl_pan pan
       WHERE  token.vti_token_pan=pan.CAP_PAN_CODE  AND  token.vti_token_pan = p_cardno_in
        AND token.vti_token_stat <>'D';
    BEGIN
      p_respmsg_out:='OK';
      FOR l_idx    IN ins_token_cur
      LOOP
       BEGIN
        SELECT COUNT(*)
        INTO l_count FROM vms_token_status_sync_dtls
              WHERE vts_card_no=l_idx.cardno
              AND vts_token_no=l_idx.tokenno
              AND vts_reason_code='3701';
       EXCEPTION
        WHEN OTHERS THEN
        p_respmsg_out :='Error While select count from token_status_sync_dtls-'||SUBSTR(sqlerrm,100);
        RETURN;
        END;
       IF l_count=0 THEN        
       BEGIN
        INSERT
        INTO vms_token_status_sync_dtls
          ( vts_card_no, vts_token_no, vts_token_ref_id,
            vts_token_requestor_id, vts_reason_code, vts_ins_date,VTS_PAN_CODE_ENCR,vts_token_type )
          VALUES
          ( l_idx.cardno, l_idx.tokenno, l_idx.token_ref_id,
            l_idx.token_requestor_id, '3701', systimestamp,l_idx.pan_encr,l_idx.tokenType);
       EXCEPTION
        WHEN OTHERS THEN
        p_respmsg_out :='Error While inserting into token_status_sync_dtls-'||SUBSTR(sqlerrm,100);
        RETURN;
       END;
       END IF; 	   
      COMMIT;
      END LOOP;      
    EXCEPTION
    WHEN OTHERS THEN
      p_respmsg_out:='Main Excp-'||sqlerrm;
    END cardno_tokens_sync;
    
    PROCEDURE TOKEN_STATUS_NOTIFY(
    P_CARDNO_IN       IN VARCHAR2,
    P_EXPRY_DATE_IN   IN VARCHAR2,
    P_CLOSEDCARDNO_IN IN VARCHAR2,
    P_NEWCARDNO_IN    IN VARCHAR2,
    P_RRN_IN          IN VARCHAR2,
    P_ACCT_NO_IN      IN VARCHAR2,
    p_prod_code_in    IN VARCHAR2,
    p_card_type_in    IN VARCHAR2,
    p_card_status_in  IN VARCHAR2,
    p_replaced_expry_date_in IN VARCHAR2,
    P_VALID_ACTION OUT VARCHAR2,
    P_REC_COUNT OUT NUMBER,
    P_RESPMSG_OUT OUT VARCHAR2)
IS
  l_hash_pan cms_appl_pan.cap_pan_code%TYPE;
  l_encr_pan cms_appl_pan.cap_pan_code_encr%TYPE;
  l_card_stat cms_appl_pan.cap_card_type%TYPE;
  l_expiry_date     VARCHAR2 (100);
  l_new_expiry_date VARCHAR2 (100);
  l_err_msg         VARCHAR2 (500);
  exp_reject_record EXCEPTION;
  l_count           NUMBER;
  ref_cur_token sys_refcursor;
  l_token VMS_TOKEN_INFO.vti_token%TYPE;
  l_token_pan VMS_TOKEN_INFO.vti_token_pan%TYPE;
  l_old_token_stat VMS_TOKEN_INFO.vti_token_old_status%TYPE;
  l_TOKEN_PAN_REF_ID VMS_TOKEN_INFO.VTI_TOKEN_PAN_REF_ID%TYPE;
  l_token_pan_encr CMS_APPL_PAN.cap_pan_code_encr%TYPE;
  l_message_ReasonCode VARCHAR2 (10);
  l_rrn VMS_TOKEN_STATUS_SYNC_DTLS.vts_rrn%TYPE;
  l_stan VMS_TOKEN_STATUS_SYNC_DTLS.vts_stan%TYPE;
  l_new_pan VMS_TOKEN_STATUS_SYNC_DTLS.vts_new_pan%TYPE;
  l_new_pan_encr VMS_TOKEN_STATUS_SYNC_DTLS.vts_newpan_encr%TYPE;
  l_old_pan VMS_TOKEN_STATUS_SYNC_DTLS.vts_new_pan%TYPE;
  l_old_pan_encr VMS_TOKEN_STATUS_SYNC_DTLS.vts_newpan_encr%TYPE;
  l_token_type VMS_TOKEN_STATUS_SYNC_DTLS.vts_token_type%TYPE;
  exp_rollback_record EXCEPTION;
  l_query CLOB;
  l_first_rec NUMBER DEFAULT 0;
  V_REPLACE_PROVISION_FLAG CMS_PROD_CATTYPE.CPC_REPLACEMENT_PROVISION_FLAG%TYPE;
  v_interchange_code cms_prod_mast.cpm_interchange_code%type;
TYPE token_reasoncode_rec
IS
  TABLE OF NUMBER INDEX BY VARCHAR2(10);
  token_reasoncode_dtls token_reasoncode_rec;
BEGIN
  P_VALID_ACTION := 'Y';
  P_RESPMSG_OUT  := 'OK';
  P_REC_COUNT    :=0;
  --Sn Get the HashPan
  BEGIN
    l_hash_pan := gethash (P_CARDNO_IN);
  EXCEPTION
  WHEN OTHERS THEN
    l_err_msg := 'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  BEGIN
    l_encr_pan := fn_emaps_main (P_CARDNO_IN);
  EXCEPTION
  WHEN OTHERS THEN
    l_err_msg := 'Error while encrypting the pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  --En Get the HashPan
  BEGIN
    SELECT NVL(CPC_REPLACEMENT_PROVISION_FLAG,'N')
    INTO V_REPLACE_PROVISION_FLAG
    FROM CMS_PROD_CATTYPE
    WHERE cpc_prod_code=p_prod_code_in
    AND cpc_card_type  =p_card_type_in;
  EXCEPTION
  WHEN OTHERS THEN
    l_err_msg := 'Error while selecting provision flag ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  IF V_REPLACE_PROVISION_FLAG ='Y' THEN
    IF p_closedcardno_in     IS NOT NULL THEN
      IF p_closedcardno_in    = P_CARDNO_IN THEN
        IF P_NEWCARDNO_IN    IS NOT NULL THEN
          BEGIN
            l_new_pan := gethash (P_NEWCARDNO_IN);
          EXCEPTION
          WHEN OTHERS THEN
            l_err_msg := 'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
          END;
          BEGIN
            l_new_pan_encr := fn_emaps_main (P_NEWCARDNO_IN);
          EXCEPTION
          WHEN OTHERS THEN
            l_err_msg := 'Error while encrypting the pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
          END;
          BEGIN
            SELECT TO_CHAR(cap_expry_date,'MMYY')
            INTO l_new_expiry_date
            FROM cms_appl_pan
            WHERE cap_pan_code = l_new_pan;
          EXCEPTION
          WHEN OTHERS THEN
            l_err_msg := 'Error while selecting new card expiry date '|| SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
          END;
          l_old_pan           := l_hash_pan;
          l_old_pan_encr      := l_encr_pan;
          l_expiry_date       := P_EXPRY_DATE_IN;
          P_VALID_ACTION      := 'R';
          l_message_ReasonCode:='3721';
        ELSE
          P_VALID_ACTION      := 'D';
          l_old_pan           := l_hash_pan;
          l_old_pan_encr      := l_encr_pan;
          l_expiry_date       := P_EXPRY_DATE_IN;
          l_message_ReasonCode:='3701';
        END IF;
      ELSE
        BEGIN
          SELECT chr_pan_code,
            CHR_PAN_CODE_ENCR
          INTO l_old_pan,
            l_old_pan_encr
          FROM cms_htlst_reisu
          WHERE CHR_NEW_PAN = l_hash_pan ;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
        
        NULL;
        WHEN OTHERS THEN
          l_err_msg := 'Error while selecting replaced card details '|| SUBSTR (SQLERRM, 1, 300);
          RAISE exp_reject_record;
        END;
        
        BEGIN
          SELECT cap_card_stat
          INTO l_card_stat
          FROM cms_appl_pan
          WHERE cap_pan_code = l_hash_pan;
        EXCEPTION
        WHEN OTHERS THEN
          l_err_msg := 'Error while selecting replaced card card status '|| SUBSTR (SQLERRM, 1, 300);
          RAISE exp_reject_record;
        END;
        IF NVL(l_card_stat,0) =1 AND l_old_pan IS NOT NULL THEN
          BEGIN
            SELECT TO_CHAR(cap_expry_date,'MMYY')
            INTO l_expiry_date
            FROM cms_appl_pan
            WHERE cap_pan_code = l_old_pan;
          EXCEPTION
          WHEN OTHERS THEN
            l_err_msg := 'Error while selecting new card expiry date '|| SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
          END;
          P_VALID_ACTION      := 'RU';
          l_new_pan           := l_hash_pan;
          l_new_pan_encr      := l_encr_pan;
          l_new_expiry_date   := P_EXPRY_DATE_IN;
          l_message_ReasonCode:='3721';
        ELSE
          P_VALID_ACTION      := 'R';
          l_new_pan           := l_hash_pan;
          l_new_pan_encr      := l_encr_pan;
          l_new_expiry_date   := P_EXPRY_DATE_IN;
          l_message_ReasonCode:='3721';
          BEGIN
            l_old_pan := gethash (p_closedcardno_in);
          EXCEPTION
          WHEN OTHERS THEN
            l_err_msg := 'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
          END;
          BEGIN
            l_old_pan_encr := fn_emaps_main (p_closedcardno_in);
          EXCEPTION
          WHEN OTHERS THEN
            l_err_msg := 'Error while encrypting the pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
          END;
          BEGIN
            SELECT TO_CHAR(cap_expry_date,'MMYY')
            INTO l_expiry_date
            FROM cms_appl_pan
            WHERE cap_pan_code = l_old_pan;
          EXCEPTION
          WHEN OTHERS THEN
            l_err_msg := 'Error while selecting new card expiry date '|| SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
          END;
        END IF;
      END IF;
    ELSE   
     BEGIN
        SELECT cap_card_stat
        INTO l_card_stat
        FROM cms_appl_pan
        WHERE cap_pan_code = l_hash_pan;
      EXCEPTION
      WHEN OTHERS THEN
        l_err_msg := 'Error while selecting replaced card card status '|| SUBSTR (SQLERRM, 1, 300);
        RAISE exp_reject_record;
      END;
      IF  NVL(l_card_stat,0) =1 AND NVL(p_replaced_expry_date_in ,'0')!='0' AND p_card_status_in = 3 THEN
        P_VALID_ACTION   := 'UE';
        l_old_pan      := l_hash_pan;
        l_old_pan_encr := l_encr_pan;
        l_expiry_date  := P_EXPRY_DATE_IN;
        l_new_pan        := l_hash_pan;
        l_new_pan_encr   := l_encr_pan;
        l_new_expiry_date:= p_replaced_expry_date_in;
      ELSE
      BEGIN
        SELECT chr_pan_code,
          CHR_PAN_CODE_ENCR
        INTO l_old_pan,
          l_old_pan_encr
        FROM cms_htlst_reisu
        WHERE CHR_NEW_PAN = l_hash_pan ;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        l_err_msg := 'Error while selecting replaced card details '|| SUBSTR (SQLERRM, 1, 300);
        RAISE exp_reject_record;
      END;
     
      IF NVL(l_card_stat,0) =1 AND p_card_status_in = 0 AND l_old_pan IS NOT NULL THEN
        BEGIN
          SELECT TO_CHAR(cap_expry_date,'MMYY')
          INTO l_expiry_date
          FROM cms_appl_pan
          WHERE cap_pan_code = l_old_pan;
        EXCEPTION
        WHEN OTHERS THEN
          l_err_msg := 'Error while selecting new card expiry date '|| SUBSTR (SQLERRM, 1, 300);
          RAISE exp_reject_record;
        END;
        P_VALID_ACTION   := 'U';

        l_old_pan      := l_hash_pan;
        l_old_pan_encr := l_encr_pan;
        l_expiry_date  := P_EXPRY_DATE_IN;
      ELSE
        P_VALID_ACTION := 'Y';
        l_old_pan      := l_hash_pan;
        l_old_pan_encr := l_encr_pan;
        l_expiry_date  := P_EXPRY_DATE_IN;
        BEGIN
          SELECT CCS_TOKEN_STAT,
            vts_reason_code
          INTO P_VALID_ACTION,
            l_message_ReasonCode
          FROM CMS_CARD_STAT,
            vms_token_status
          WHERE CCS_STAT_CODE = l_card_stat
          AND CCS_TOKEN_STAT  = vts_token_stat;
        EXCEPTION
        WHEN OTHERS THEN
          l_err_msg := 'Error while selecting token status '|| SUBSTR (SQLERRM, 1, 300);
          RAISE exp_reject_record;
        END;
      END IF;
    END IF;
  END IF;
  ELSE
    IF p_closedcardno_in IS NOT NULL AND p_closedcardno_in <> P_CARDNO_IN THEN
      BEGIN
        SELECT chr_pan_code,
          CHR_PAN_CODE_ENCR
        INTO l_old_pan,
          l_old_pan_encr
        FROM cms_htlst_reisu
        WHERE CHR_NEW_PAN = l_hash_pan ;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       BEGIN
          select cap_pan_code,CAP_PAN_CODE_ENCR
          into l_old_pan,l_old_pan_encr from 
          (SELECT cap_pan_code,
            CAP_PAN_CODE_ENCR
          FROM cms_appl_pan
          WHERE cap_acct_no       = P_ACCT_NO_IN
          AND cap_startercard_flag='Y' order by CAP_PANGEN_DATE desc) where rownum=1;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          l_err_msg := 'Error while selecting replaced card details '|| SUBSTR (SQLERRM, 1, 300);
          RAISE exp_reject_record;
        END;
      WHEN OTHERS THEN
        l_err_msg := 'Error while selecting replaced card details '|| SUBSTR (SQLERRM, 1, 300);
        RAISE exp_reject_record;
      END;
      BEGIN
        SELECT cap_card_stat,
          TO_CHAR(cap_expry_date,'MMYY')
        INTO l_card_stat,
          l_expiry_date
        FROM cms_appl_pan
        WHERE cap_pan_code = l_old_pan;
      EXCEPTION
      WHEN OTHERS THEN
        l_err_msg := 'Error while selecting replaced card card status '|| SUBSTR (SQLERRM, 1, 300);
        RAISE exp_reject_record;
      END;
      P_VALID_ACTION      :='D';
      l_message_ReasonCode:='3701';
    ELSE
      BEGIN
        SELECT cap_card_stat
        INTO l_card_stat
        FROM cms_appl_pan
        WHERE cap_pan_code = l_hash_pan;
      EXCEPTION
      WHEN OTHERS THEN
        l_err_msg := 'Error while selecting replaced card card status '|| SUBSTR (SQLERRM, 1, 300);
        RAISE exp_reject_record;
      END;
      IF  NVL(l_card_stat,0) =1 AND NVL(p_replaced_expry_date_in ,'0')!='0' AND p_card_status_in = 3 THEN
      P_VALID_ACTION   := 'UE';
      l_old_pan      := l_hash_pan;
      l_old_pan_encr := l_encr_pan;
      l_expiry_date  := P_EXPRY_DATE_IN;
      l_new_pan        := l_hash_pan;
      l_new_pan_encr   := l_encr_pan;
      l_new_expiry_date:= p_replaced_expry_date_in;
      ELSE
      P_VALID_ACTION := 'Y';
      l_old_pan      := l_hash_pan;
      l_old_pan_encr := l_encr_pan;
      l_expiry_date  := P_EXPRY_DATE_IN;
      BEGIN
        SELECT CCS_TOKEN_STAT,
          vts_reason_code
        INTO P_VALID_ACTION,
          l_message_ReasonCode
        FROM CMS_CARD_STAT,
          vms_token_status
        WHERE CCS_STAT_CODE = l_card_stat
        AND CCS_TOKEN_STAT  = vts_token_stat;
      EXCEPTION
      WHEN OTHERS THEN
        l_err_msg := 'Error while selecting token status '|| SUBSTR (SQLERRM, 1, 300);
        RAISE exp_reject_record;
      END;
     END IF; 
    END IF;
  END IF;
  BEGIN
       FOR l_idx IN
      ( SELECT vts_token_stat,vts_reason_code FROM vms_token_status
      )
      LOOP
        token_reasoncode_dtls (l_idx.vts_token_stat):=l_idx.vts_reason_code;
      END LOOP;
      
	BEGIN
	  SELECT cpm_interchange_code
	  INTO v_interchange_code
	  FROM cms_prod_mast,
		cms_appl_pan
	  WHERE cap_prod_code =cpm_prod_code
	  AND cap_pan_code    =l_old_pan
	  AND cap_inst_code   =cpm_inst_code;
	EXCEPTION
	WHEN OTHERS THEN
	  v_interchange_code :='';
	END;      
    IF P_VALID_ACTION     = 'R' THEN
      l_query            := 'SELECT vti_token,vti_token_pan,'''||l_old_pan_encr||''',vti_token_pan_ref_id,'''',vti_token_type
                            FROM vms_token_info  WHERE  vti_token_pan = '''||l_old_pan||'''                                                                                                                                      
                            AND vti_token_stat <>''D'' ';
      IF v_interchange_code <>'A' THEN
          l_query            :=l_query||' AND ROWNUM=1';
      END IF;
                            
    ELSIF P_VALID_ACTION IN ('A','D') THEN
      l_query            := 'SELECT vti_token,vti_token_pan,'''||l_old_pan_encr||''','''',''''  ,vti_token_type  
                            FROM vms_token_info  WHERE  vti_token_pan = '''||l_old_pan||'''  
                            AND vti_token_stat <>''D''';
    ELSIF P_VALID_ACTION ='S' THEN
      l_query            := 'SELECT vti_token,vti_token_pan,'''||l_old_pan_encr||''','''',''''  ,vti_token_type
                            FROM vms_token_info  WHERE  vti_token_pan = '''||l_old_pan||'''
							AND vti_token_stat NOT IN (''D'',''I'')';                            
							
    ELSIF P_VALID_ACTION IN ('RU','UE') THEN
      l_query            := 'SELECT vti_token,vti_token_pan,'''||l_old_pan_encr||''',vti_token_pan_ref_id,nvl(vti_token_old_status,vti_token_stat),vti_token_type
                            FROM vms_token_info  WHERE  vti_token_pan = '''||l_old_pan||'''     
                            AND vti_token_stat <>''D''';
   ELSIF P_VALID_ACTION ='U' THEN
      l_query            := 'SELECT vti_token,vti_token_pan,'''||l_old_pan_encr||''',vti_token_pan_ref_id,nvl(vti_token_old_status,vti_token_stat),vti_token_type
                            FROM vms_token_info  WHERE  vti_token_pan = '''||l_old_pan||'''     
                            AND vti_token_stat <>''D''';



    END IF;
	
	
	
	
    OPEN ref_cur_token FOR l_query;
    LOOP
      FETCH ref_cur_token
      INTO l_token,
        l_token_pan,
        l_token_pan_encr,
        l_token_pan_ref_id,
        l_old_token_stat,
        l_token_type;
      IF P_VALID_ACTION     IN ('U','RU','UE') THEN
        l_message_ReasonCode:=token_reasoncode_dtls(l_old_token_stat);
        IF l_first_rec       > 0 OR P_VALID_ACTION ='U' THEN
          l_new_pan         :='';
          l_new_pan_encr    :='';
          l_new_expiry_date :='';
          l_token_pan_ref_id:='';
        END IF;
      END IF;
      EXIT
    WHEN ref_cur_token%NOTFOUND;
      IF P_VALID_ACTION IN ('RU','UE') AND l_first_rec=0 THEN
      /*  BEGIN
          SELECT COUNT(*)
          INTO l_count
          FROM vms_token_status_sync_dtls
          WHERE vts_acct_no  =p_acct_no_in
          AND vts_reason_code=DECODE(P_VALID_ACTION,'RU','3721','UE','3720');
        EXCEPTION
        WHEN OTHERS THEN
          l_err_msg :='Error While select count from token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
          RAISE exp_rollback_record;
        END;
        IF l_count=0 THEN*/
          BEGIN
            l_rrn  := LPAD(seq_auth_rrn.NEXTVAL,12,'0');
            l_stan := LPAD(seq_auth_stan.NEXTVAL,6,'0');
            INSERT
            INTO vms_token_status_sync_dtls
              (
                vts_card_no,
                vts_token_no,
                vts_reason_code,
                vts_ins_date,
                vts_pan_code_encr,
                vts_tran_rrn,
                vts_rrn,
                vts_stan,
                vts_expry_date,
                vts_token_pan_ref_id,
                vts_new_pan,
                vts_newpan_encr,
                vts_newexpry_date,
                vts_acct_no,
                vts_card_stat
                ,vts_token_type
              )
              VALUES
              (
                l_token_pan,
                DECODE(v_interchange_code,'A',l_token,''),
                DECODE(P_VALID_ACTION,'RU','3721','UE','3720'),
                systimestamp,
                l_token_pan_encr,
                p_rrn_in,
                l_rrn,
                l_stan,
                l_expiry_date,
                l_token_pan_ref_id,
                l_new_pan,
                l_new_pan_encr,
                l_new_expiry_date,
                P_ACCT_NO_IN,
                p_card_status_in
                ,l_token_type
              );
            P_REC_COUNT := P_REC_COUNT+1;
          EXCEPTION
          WHEN OTHERS THEN
            l_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
            RAISE exp_rollback_record;
          END;
     /*   ELSE
          P_REC_COUNT := P_REC_COUNT+1;
        END IF;*/
        l_first_rec:=l_first_rec+1;
      END IF;
      IF l_message_ReasonCode NOT IN ('3721','3720') THEN
        l_new_pan         :='';
        l_new_pan_encr    :='';
        l_new_expiry_date :='';
        l_token_pan_ref_id:='';
      END IF;
   /*   BEGIN
        SELECT COUNT(*)
        INTO l_count
        FROM vms_token_status_sync_dtls
        WHERE vts_card_no  =l_token_pan
        AND vts_token_no   =l_token
        AND vts_reason_code=l_message_ReasonCode;
      EXCEPTION
      WHEN OTHERS THEN
        l_err_msg :='Error While select count from token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
        RAISE exp_rollback_record;
      END;
      IF l_count=0 THEN */
	  IF l_message_ReasonCode is not null THEN
        BEGIN
          l_rrn  := LPAD(seq_auth_rrn.NEXTVAL,12,'0');
          l_stan := LPAD(seq_auth_stan.NEXTVAL,6,'0');
          INSERT
          INTO vms_token_status_sync_dtls
            (
              vts_card_no,
              vts_token_no,
              vts_reason_code,
              vts_ins_date,
              vts_pan_code_encr,
              vts_tran_rrn,
              vts_rrn,
              vts_stan,
              vts_expry_date,
              vts_token_pan_ref_id,
              vts_new_pan,
              vts_newpan_encr,
              vts_newexpry_date,
              vts_acct_no,
              vts_card_stat
              ,vts_token_type
            )
            VALUES
            (
              l_token_pan,
              l_token,
              l_message_ReasonCode,
              systimestamp,
              l_token_pan_encr,
              p_rrn_in,
              l_rrn,
              l_stan,
              l_expiry_date,
              l_token_pan_ref_id,
              l_new_pan,
              l_new_pan_encr,
              l_new_expiry_date,
              P_ACCT_NO_IN,
              p_card_status_in
              ,l_token_type
            );
          P_REC_COUNT := P_REC_COUNT+1;
        EXCEPTION
        WHEN OTHERS THEN
          l_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
          RAISE exp_rollback_record;
        END;
		END IF;    
   /*   ELSE
        P_REC_COUNT := P_REC_COUNT+1;
      END IF; */
    END LOOP;
  IF P_VALID_ACTION IN ('RU','UE')  THEN
     UPDATE vms_token_status_sync_dtls
     SET vts_ins_date=systimestamp
     where vts_tran_rrn=p_rrn_in
          and vts_acct_no=P_ACCT_NO_IN
          and vts_reason_code in ('3721','3720');
   END IF;
  EXCEPTION
  WHEN exp_reject_record THEN
    RAISE;
  WHEN exp_rollback_record THEN
    RAISE;
  WHEN OTHERS THEN
    l_err_msg := 'ERROR WHILE PROCESSING ref_cur_token ' || SUBSTR (SQLERRM, 1, 300);
    RAISE EXP_REJECT_RECORD;
  END;
EXCEPTION
WHEN exp_rollback_record THEN
  P_VALID_ACTION := 'N';
  P_RESPMSG_OUT  := l_err_msg;
  IF P_REC_COUNT  >0 THEN
    ROLLBACK;
  END IF;
WHEN exp_reject_record THEN
  P_VALID_ACTION := 'N';
  P_RESPMSG_OUT  := l_err_msg;
WHEN OTHERS THEN
  P_VALID_ACTION := 'N';
  p_respmsg_out  :='Main Excp-'|| SUBSTR (SQLERRM, 1, 300);
END TOKEN_STATUS_NOTIFY;   

PROCEDURE  TokenCompleteNotification (
         p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_token_in   		              in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_token_type_in   		        in  	varchar2,
          p_token_status_in   		      in  	varchar2,
          p_token_assurance_level_in    in  	varchar2,
          p_token_requester_id_in   	  in  	varchar2,
          p_token_ref_id_in   		      in  	varchar2,
          p_token_expry_date_in         in  	varchar2,
          p_token_pan_ref_id_in         in  	varchar2,
          p_token_wpriskassessment_in   in  	varchar2,
          p_token_wpriskassess_ver_in in  	varchar2,
          p_token_wpdevice_score_in     in  	varchar2,
          p_token_wpaccount_score_in    in  	varchar2,
          p_token_wpreason_codes_in     in  	varchar2,
          p_token_wppan_source_in       in  	varchar2,
          p_token_wpacct_id_in          in  	varchar2,
          p_token_wpacct_email_in       in  	varchar2,
          p_token_device_type_in        in  	varchar2,
          p_token_device_langcode_in    in  	varchar2,
          p_token_device_id_in          in  	varchar2,
          p_token_device_no_in          in  	varchar2,
          p_token_device_name_in        in  	varchar2,
          p_token_device_loc_in         in  	varchar2,
          p_token_device_ip_in          in  	varchar2,
          p_token_device_secureeleid_in in  	varchar2,
          p_token_riskassess_score_in  in  	varchar2,
          p_token_provisioning_score_in in  	varchar2,
          p_curr_code_in                in    varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_stan_in                     in  	varchar2,
          p_ntw_settl_date              in  	varchar2,
          p_expry_date_in               IN  	VARCHAR2,          
          p_msg_reason_code_in          in    varchar2,
          p_contactless_usage_in        IN  	VARCHAR2,
          p_card_ecomm_usage_in         in  	varchar2,
          p_mob_ecomm_usage_in_in       IN  	VARCHAR2,
          p_wallet_identifier_in       IN  	VARCHAR2,
          p_storage_tech_in             IN  	VARCHAR2,   
          p_auth_id_out                 out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2 
          ,p_token_reqid13_in         in  	varchar2 default null
          ,p_wp_reqid_in              in  	varchar2 default null
          ,p_wp_convid_in             in  	varchar2 default null
          ,p_wallet_id_in             in  	varchar2 default null
          ,p_correlation_id_in             in  	varchar2 default null
          ,p_payment_appplninstanceid_in     in  	varchar2 default null
          ,p_resp_id_out                 out   varchar2 --Added for sending to FSS (VMS-8018)
          )
   IS
      /************************************************************************************************************
          
       * Created by      : T.Narayanaswamy
       * Created For     : Token Complete Notification (TCN) 
       * Created Date    : 05-April-2017
       * Created reason  : Token Complete Notification (TCN)  changes
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST 17.05
       
       * Modified Date    :  03-Nov-2023
       * Modified By      :  Areshka A.
       * Modified For     :  VMS-8018: Added new out parameter (response id) for sending to FSS
       * Reviewer         :  
       * Build Number     :         
       
      ************************************************************************************************************/
      l_err_msg              VARCHAR2 (500) DEFAULT 'OK';
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      L_LOGIN_TXN            CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;
      L_LOGDTL_RESP          VARCHAR2 (500);
      L_PREAUTH_TYPE         CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
      EXP_REJECT_RECORD      EXCEPTION;
      L_TOKEN_STATUS        VARCHAR2 (1);
      L_TOKEN_OLD_STATUS        VARCHAR2 (1);      
      L_CARDPACK_ID              CMS_APPL_PAN.CAP_CARDPACK_ID%TYPE;
      l_customer_id    cms_cust_mast.CCM_CUST_ID%type;
      
   BEGIN
      l_resp_cde := '1';
      l_err_msg:='OK';
      l_time_stamp := SYSTIMESTAMP;
      BEGIN

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
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
               RAISE exp_reject_record;
         END;
         --End Generate HashKEY

         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   CAP_PRFL_CODE, CAP_EXPRY_DATE, CAP_PROXY_NUMBER,
                   cap_cust_code,ccm_cust_id,CAP_CARDPACK_ID
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   L_PRFL_CODE, L_EXPRY_DATE, L_PROXY_NUMBER,
                   l_cust_code,l_customer_id,L_CARDPACK_ID
              from cms_appl_pan,cms_cust_mast
             where cap_inst_code=ccm_inst_code and cap_cust_code=ccm_cust_code and
             cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --End Get the card details
 
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
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details '||substr(sqlerrm,1,200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
         --En generate auth id

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
            --FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14';
           l_err_msg  := 'Invalid Card ';
           RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

    if trim(p_token_in) is not null  then
            
          LP_TOKEN_CREATE_UPDATE(P_TOKEN_IN,
          L_HASH_PAN,
          P_TOKEN_TYPE_IN,
          'G',
          P_TOKEN_ASSURANCE_LEVEL_IN,
          P_TOKEN_REQUESTER_ID_IN,
          P_TOKEN_REF_ID_IN,
          P_TOKEN_EXPRY_DATE_IN,
          P_TOKEN_PAN_REF_ID_IN,
          P_TOKEN_WPPAN_SOURCE_IN,
          P_TOKEN_WPRISKASSESSMENT_IN,
          P_TOKEN_WPRISKASSESS_VER_IN,
          P_TOKEN_WPDEVICE_SCORE_IN,
          P_TOKEN_WPACCOUNT_SCORE_IN,
          P_TOKEN_WPREASON_CODES_IN,
          P_TOKEN_WPACCT_ID_IN,
          P_TOKEN_WPACCT_EMAIL_IN,
          P_TOKEN_DEVICE_TYPE_IN,
          P_TOKEN_DEVICE_LANGCODE_IN,
          P_TOKEN_DEVICE_ID_IN  ,
          P_TOKEN_DEVICE_NO_IN,
          P_TOKEN_DEVICE_NAME_IN,
          P_TOKEN_DEVICE_LOC_IN,
          P_TOKEN_DEVICE_IP_IN,
          P_TOKEN_DEVICE_SECUREELEID_IN,
          P_WALLET_IDENTIFIER_IN,
          P_STORAGE_TECH_IN,
          P_TOKEN_RISKASSESS_SCORE_IN,
          P_TOKEN_PROVISIONING_SCORE_IN,
          P_CONTACTLESS_USAGE_IN,
          P_CARD_ECOMM_USAGE_IN,
          P_MOB_ECOMM_USAGE_IN_IN,
          L_ACCT_NUMBER,
          L_CUST_CODE,
          P_INST_CODE_IN,
          P_TOKEN_REQID13_IN,
          P_WP_REQID_IN,
          P_WP_CONVID_IN,
          P_WALLET_ID_IN,
          p_payment_appplninstanceid_in,
          p_correlation_id_in ,
          L_RESP_CDE,
          l_err_msg
          );
        
        IF L_ERR_MSG <> 'OK' THEN
            RAISE  EXP_REJECT_RECORD; 
        END IF;
         
         END IF;
         
         l_resp_cde := '1';
         l_err_msg := 'OK'; 
         
     EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK ;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK ;
      END;
   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
               AND cms_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               L_ERR_MSG :=
                     'Problem while selecting data from response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
               p_resp_id_out := '69'; --Added for VMS-8018
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
                        NULL,
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
                        0,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_stan_in,
                        p_ntw_settl_date
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            0,
                            null,
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
                            L_LOGDTL_RESP,
                            null,
                            null,
                            p_stan_in
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resp_id_out := '69'; --Added for VMS-8018
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   end TokenCompleteNotification;
   
  PROCEDURE  TokenActivationNotification (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_token_in   		              in  	varchar2,
          p_tran_amt_in                 in  	varchar2,
          p_curr_code_in                in  	varchar2,
          p_expry_date_in               in  	varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_cntry_code_in               IN  	VARCHAR2,
          p_verify_method_in            in  	varchar2,
          p_auth_id_out                 out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resmsg_out                  out 	VARCHAR2,
          p_cell_no_out                 out   VARCHAR2,
          p_email_id_out                out   VARCHAR2,
          p_verify_method_out           out  	varchar2,
          p_resp_id_out                 out  	varchar2 --Added for sending to FSS (VMS-8018)
   )
   IS
      /************************************************************************************************************          
       * Created by      : T.Narayanaswamy
       * Created For     : Token Activation Notification (ACN) 
       * Created Date    : 05-April-2017
       * Created reason  : Token Activation Notification (ACN)  changes
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST 17.05
       
       * Modified Date     :  05-Sep-2017
       * Modified By       :  Siva Kumar M
       * Modified For      :  FSS-5199
       * Reviewer          :  Saravanakumar/SPankaj
       * Build Number      :  VMSGPRHOST_17.08
       
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01
     
     * Modified By      : Areshka A.
     * Modified Date    : 03-Nov-2023
     * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
     * Reviewer         : 
     * Release Number   :    
     
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      l_login_txn            cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp          VARCHAR2 (500);
      l_preauth_type         cms_transaction_mast.ctm_preauth_type%TYPE;      
      l_customer_id          cms_cust_mast.CCM_CUST_ID%TYPE;
      l_method_identifier NUMBER(5)  DEFAULT 0;
      l_method_id_email NUMBER(5)  DEFAULT 0;
      l_method_id_cell number(5)  DEFAULT 0;
      exp_reject_record      EXCEPTION;
      l_encrypt_enable         cms_prod_cattype.cpc_encrypt_enable%type;
   BEGIN
      l_resp_cde := '1';
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
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details'|| SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
         --En generate auth id
         
         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code,ccm_cust_id
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code,l_customer_id
              FROM cms_appl_pan,cms_cust_mast
             WHERE cap_cust_code = ccm_cust_code
             AND cap_inst_code = ccm_inst_code
             AND cap_inst_code = p_inst_code_in 
             AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
        
        BEGIN
            SELECT cpc_encrypt_enable
              INTO l_encrypt_enable
              FROM cms_prod_cattype
             WHERE cpc_prod_code = l_prod_code
             AND  cpc_card_type = l_card_type
             AND cpC_inst_code = p_inst_code_in; 
             
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'No data found for prod code and card type ' || l_prod_code || l_card_type;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting encrypt enable flag details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
        
        BEGIN        
      
         SELECT INSTR(UPPER(p_verify_method_in),'CELL_PHONE')
                        INTO l_method_id_cell FROM DUAL; 
         IF l_method_id_cell>0 THEN
          l_method_identifier:='1';
         END IF;
         
         SELECT INSTR(UPPER(p_verify_method_in),'EMAIL')
                        INTO l_method_id_email FROM DUAL; 
          IF l_method_id_email>0 THEN     
            IF l_method_identifier=1 THEN
              l_method_identifier:=3;
            ELSE 
              l_method_identifier:=2;
            END IF;           
          END IF;
           IF l_method_identifier>0 THEN
              p_verify_method_out:=l_method_identifier;
            ELSE
               SELECT INSTR(UPPER(p_verify_method_in),'CUSTOMER_SERVICE')
                          INTO l_method_id_cell FROM DUAL; 
             IF l_method_id_cell <> 1 THEN
             l_resp_cde := '17';
             l_err_msg := 'Invalid OTP Identifier';
             RAISE exp_reject_record;
              END IF;
          END IF;
            EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '17';
               l_err_msg := 'Invalid OTP Identifier';
               RAISE exp_reject_record;
         END;
         
         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
            --FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14'; 
           l_err_msg  := 'Invalid Card ';
           RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

   BEGIN

           SELECT decode(l_encrypt_enable,'Y',fn_dmaps_main(CAM_MOBL_ONE),CAM_MOBL_ONE),
                  decode(l_encrypt_enable,'Y',fn_dmaps_main(CAM_EMAIL),CAM_EMAIL)
           into p_cell_no_out,p_email_id_out
           FROM CMS_ADDR_MAST
           WHERE CAM_INST_CODE = p_inst_code_in
           AND CAM_CUST_CODE   = l_cust_code
           AND CAM_ADDR_FLAG   = 'P';
           
           EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   l_resp_cde := '21';
                   l_err_msg := 'cellphone no and email id not found for customer id';
                   RAISE exp_reject_record;
                 WHEN OTHERS THEN
                   l_resp_cde := '21';
                   l_err_msg := 'Error while selecting cellphone no and email id for physical address' || 
                   SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
           END;

        
         
         if p_cell_no_out IS NULL AND p_email_id_out IS NULL then
         l_resp_cde := '21';
                   l_err_msg := 'cellphone no and email id not found for customer id';
                   RAISE exp_reject_record;
         end if;
         
         l_resp_cde := '1';
         l_err_msg:='OK';
     EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;
   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
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
               p_resp_id_out := '69'; --Added for VMS-8018
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
                        NULL,
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
                        p_tran_amt_in,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            p_tran_amt_in,
                            p_cell_no_out,
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
                            l_logdtl_resp,
                            p_email_id_out
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resp_id_out := '69'; --Added for VMS-8018
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END TokenActivationNotification;
   
PROCEDURE  TokenEventNotification (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_tran_amt_in                 in  	varchar2,
          p_curr_code_in                in  	varchar2,
          p_expry_date_in               in  	varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_cntry_code_in               IN  	VARCHAR2,  
          p_token_event_ind_in          IN  	VARCHAR2,  
          p_token_in                    in  	varchar2,
          p_token_type_in               IN  	VARCHAR2,
          p_token_status_in             IN  	VARCHAR2,
          p_token_assurance_level_in    in  	varchar2,
          p_token_requester_id_in       in  	varchar2,
          p_token_expry_date_in         in  	varchar2,
          p_token_device_type_in        in  	varchar2,
          p_token_device_langcode_in    in  	varchar2,
          p_token_device_id_in          in  	varchar2,
          p_token_device_no_in          in  	varchar2,
          p_token_device_name_in        in  	varchar2,
          p_token_device_loc_in         IN  	VARCHAR2,
          p_token_device_ip_in          IN  	VARCHAR2, 
          p_token_event_req_in          IN  	VARCHAR2,  
          p_auth_id_out                 out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resmsg_out                  out 	varchar2,
          p_resp_id_out                 out 	varchar2 --Added for sending to FSS (VMS-8018)
          )
   IS
      /************************************************************************************************************
          
       * Created by      : T.Narayanaswamy
       * Created For     : Token Event Notification (ACN) 
       * Created Date    : 05-April-2017
       * Created reason  : Token Event Notification (ACN)  changes
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST 17.05
	   
	   * Modified by      : Sai Prasad
       * Modified For     :  FSS-5238
       * Modified Date    : 29-Aug-2017
       * Modified reason  : Remarks logging changes
       * Reviewer         : Saravankumar
       * Build Number     : VMSGPRHOST 17.05.4
       
	   * Modified by      : Areshka A.
       * Modified For     : VMS-8018
       * Modified Date    : 03-Nov-2023
       * Modified reason  : Added new out parameter (response id) for sending to FSS
       * Reviewer         : 
       * Build Number     : 
       
      ************************************************************************************************************/
      l_err_msg              VARCHAR2 (500) DEFAULT 'OK';
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      L_LOGIN_TXN            CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;
      L_LOGDTL_RESP          VARCHAR2 (500);
      L_PREAUTH_TYPE         CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
      EXP_REJECT_RECORD      EXCEPTION;
      L_TOKEN_STATUS        VARCHAR2 (1);
      L_TOKEN_OLD_STATUS        VARCHAR2 (1);      
      L_CARDPACK_ID              CMS_APPL_PAN.CAP_CARDPACK_ID%TYPE;
      l_customer_id    cms_cust_mast.CCM_CUST_ID%TYPE;
      l_event_req_desc varchar2(200);
   BEGIN
      l_resp_cde := '1';
      l_err_msg:='OK';
      l_time_stamp := SYSTIMESTAMP;
      BEGIN

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
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
               RAISE exp_reject_record;
         END;
         --End Generate HashKEY

         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   CAP_PRFL_CODE, CAP_EXPRY_DATE, CAP_PROXY_NUMBER,
                   cap_cust_code,ccm_cust_id,CAP_CARDPACK_ID
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   L_PRFL_CODE, L_EXPRY_DATE, L_PROXY_NUMBER,
                   l_cust_code,l_customer_id,L_CARDPACK_ID
              from cms_appl_pan,cms_cust_mast
             where cap_inst_code=ccm_inst_code and cap_cust_code=ccm_cust_code and
             cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --End Get the card details
         
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
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details '||substr(sqlerrm,1,200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
         --En generate auth id

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
           -- FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14';
           l_err_msg  := 'Invalid Card ';
           RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
        BEGIN
        
          UPDATE VMS_TOKEN_INFO
          SET VTI_TOKEN_STAT = decode(p_token_event_ind_in,'3','D','6','S','7','A',VTI_TOKEN_STAT)
          WHERE vti_token    = trim(p_token_in)
          AND vti_token_pan  = l_hash_pan;
          IF SQL%ROWCOUNT    =0 THEN
            l_resp_cde := '21';
            l_err_msg   :='Token Not found for status update';
          END IF;
          EXCEPTION
          WHEN OTHERS THEN
            l_resp_cde := '21';
            l_err_msg:='Error while updating token staus-'||SQLERRM;
        END;
         
         
         l_resp_cde := '1';
         l_err_msg := 'OK'; 
         
     EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK ;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK ;
      END;
   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
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
               p_resp_id_out := '69'; --Added for VMS-8018
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
                   L_PREAUTH_FLAG
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
      
      BEGIN
	  --Modified for FSS-5238
     SELECT  decode(p_token_event_ind_in,'3','Token Deleted - ','6','Token Suspended - ','7','Token Resumed - ','') 
      ||  CIP_PARAM_DESC 
      INTO L_EVENT_REQ_DESC FROM CMS_INST_PARAM WHERE CIP_PARAM_KEY='EVENT_REQUESTOR_' ||TRIM(p_token_event_req_in)
      AND CIP_INST_CODE=P_INST_CODE_IN;
       EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
      END;
      
      
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
                        NULL,
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
                        0,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        l_event_req_desc,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        null
                        
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            0,
                            null,
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
                            L_LOGDTL_RESP,
                            null,
                            null,
                            null
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resp_id_out := '69'; --Added for VMS-8018
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   end TokenEventNotification;  
   
PROCEDURE TOKEN_AUTHORISE_PRECHECK(
    P_INST_CODE_IN        IN VARCHAR2,
    P_DELIVERY_CHANNEL_IN IN VARCHAR2,
    P_TRAN_CODE_IN        IN VARCHAR2,
    P_TRAN_MODE_IN        IN VARCHAR2,
    P_MSG_TYPE_IN         IN VARCHAR2,
    P_TRAN_DATE_IN        IN VARCHAR2,
    P_TRAN_TIME_IN        IN VARCHAR2,
    P_CARD_NUMBER_IN      IN VARCHAR2,
    P_EXPRY_DATE_IN       IN VARCHAR2,
    P_token_in               in varchar2,
    p_correlationid_in     in varchar2,
    P_RRN_IN               in varchar2,
    P_CVV2_FLAG_OUT       OUT VARCHAR2,
    p_rule_bypass         out varchar2,
    P_RETURN_CODE_OUT          OUT VARCHAR2,
    P_RESP_CODE_OUT       OUT VARCHAR2,
    p_resmsg_out          out varchar2
    )
IS

      /************************************************************************************************************
       
       * Modified by      : T.Narayanaswamy
       * Modified Date    : 17-October-2017
       * Modified reason  : FSS-5292 - Tokenization: Override both Velocity  Checks
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST_17.10 Build II

       
      ************************************************************************************************************/
	  
	  
  l_err_msg  VARCHAR2 (500);
  l_resp_cde VARCHAR2 (5);
  l_hash_pan cms_appl_pan.cap_pan_code%TYPE;
  l_encr_pan cms_appl_pan.cap_pan_code_encr%TYPE;
  l_prod_code cms_prod_mast.cpm_prod_code%TYPE;
  l_card_type cms_prod_cattype.cpc_card_type%TYPE;
  l_card_stat cms_appl_pan.cap_card_stat%TYPE;
  l_exp_date cms_appl_pan.CAP_EXPRY_DATE%TYPE;
  l_cust_code cms_appl_pan.CAP_cust_code%TYPE;
  L_ACCT_NUMBER cms_appl_pan.CAP_acct_no%TYPE;
  L_KYC_FLAG CMS_CUST_MAST.CCM_KYC_FLAG %TYPE;
  EXP_TOKEN_REJECT_RECORD               EXCEPTION;
  L_PROVISIONING_FLAG CMS_APPL_PAN.CAP_PROVISIONING_FLAG%TYPE;
  L_TOKEN_PROVISION_RETRY_MAX CMS_PROD_CATTYPE.CPC_TOKEN_PROVISION_RETRY_MAX%TYPE;
  L_TOKEN_ELIGIBILITY CMS_PROD_CATTYPE.CPC_TOKEN_ELIGIBILITY%TYPE;
  l_provisioning_attempt_cnt CMS_APPL_PAN.CAP_PROVISIONING_ATTEMPT_COUNT%TYPE;
  l_acct_bal cms_acct_mast.cam_acct_bal%TYPE;
  l_status_chk NUMBER;
  l_prdcat_kyc_flag CMS_PROD_CATTYPE.CPC_KYC_FLAG%TYPE;
  l_prdcat_expdate_flag CMS_PROD_CATTYPE.CPC_EXPIRY_DATE_CHECK_FLAG%TYPE;
  l_prdcat_acct_bal_flag CMS_PROD_CATTYPE.CPC_ACCT_BALANCE_CHECK_FLAG%TYPE;
  l_prdcat_acct_bal_type CMS_PROD_CATTYPE.CPC_ACCT_BAL_CHECK_TYPE%TYPE;
  l_prdcat_acct_bal_val CMS_PROD_CATTYPE.CPC_ACCT_BAL_CHECK_VALUE%TYPE;
  l_prdcat_consumed_flag CMS_PROD_CATTYPE.CPC_CONSUMED_FLAG%TYPE;
  l_prdcat_consumed_stat NUMBER;
  l_rule_fail VARCHAR2(1) :='N';
  l_acc_bal_check_fail VARCHAR2(1) :='N';
  L_TOKEN_CUST_UPD_DURATION  CMS_PROD_CATTYPE.CPC_TOKEN_CUST_UPD_DURATION%TYPE;
  L_DURATION_DIFF            NUMBER;
  l_rule_bypass cms_appl_pan.cap_rule_bypass%type;
  l_return_cde                       transactionlog.response_id%TYPE;
BEGIN
  l_err_msg :='OK';
  l_resp_cde:=1;
   l_return_cde:='00';
  BEGIN
    l_hash_pan := gethash (P_CARD_NUMBER_IN);
  EXCEPTION
  WHEN OTHERS THEN
    l_resp_cde := '12';
    l_err_msg := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
  BEGIN
    SELECT
      cap_prod_code,
      cap_card_type,
      cap_card_stat,
      CAP_EXPRY_DATE,
      CAP_cust_code,
      CAP_acct_no,
      CAP_PROVISIONING_FLAG,
      nvl(CAP_PROVISIONING_ATTEMPT_COUNT,0),
      NVL(CAP_RULE_BYPASS,'N')
    INTO
      l_prod_code,
      l_card_type,
      l_card_stat,
      l_exp_date,
      l_cust_code,
      L_ACCT_NUMBER,
      l_provisioning_flag,
      l_provisioning_attempt_cnt,
      L_RULE_BYPASS
    FROM
      cms_appl_pan
    WHERE
      cap_pan_code    = l_hash_pan
    AND cap_inst_code = P_INST_CODE_IN;
    
    P_RULE_BYPASS:=L_RULE_BYPASS;
  EXCEPTION
  WHEN OTHERS THEN
	P_RULE_BYPASS:='N';
	  l_resp_cde := '12';
    l_err_msg  := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
  BEGIN
    SELECT
      NVL(CPC_KYC_FLAG,'N'),
      DECODE(L_RULE_BYPASS,'Y','N',NVL(CPC_CVV2_VERIFICATION_FLAG,'N')),
      NVL(CPC_EXPIRY_DATE_CHECK_FLAG,'N'),
      NVL(CPC_ACCT_BALANCE_CHECK_FLAG,'N'),
      CPC_ACCT_BAL_CHECK_TYPE,
      NVL(CPC_ACCT_BAL_CHECK_VALUE,0),
      NVL(CPC_CONSUMED_FLAG,'N'),
      CPC_CONSUMED_CARD_STAT,
      NVL(CPC_TOKEN_ELIGIBILITY,'N'),
      NVL(CPC_TOKEN_PROVISION_RETRY_MAX,0),
      NVL(CPC_TOKEN_CUST_UPD_DURATION,0)
    INTO
      l_prdcat_kyc_flag,
      P_CVV2_FLAG_OUT,
      l_prdcat_expdate_flag,
      l_prdcat_acct_bal_flag,
      l_prdcat_acct_bal_type,
      l_prdcat_acct_bal_val,
      l_prdcat_consumed_flag,
      l_prdcat_consumed_stat,
      l_TOKEN_ELIGIBILITY,
      L_TOKEN_PROVISION_RETRY_MAX,
      L_TOKEN_CUST_UPD_DURATION
    FROM
      cms_prod_cattype
    WHERE
      cpc_prod_code   = l_prod_code
    AND cpc_card_type = l_card_type
    AND cpc_inst_code =P_INST_CODE_IN;
  EXCEPTION
  WHEN OTHERS THEN
    l_resp_cde := '12';
    l_err_msg  := 'Error while fetching in Product Category details' || SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
  
  
 /*  BEGIN
    IF L_TOKEN_ELIGIBILITY ='N' THEN
      l_err_msg           :='Product is not Eligibile for Tokenization';
      l_resp_cde          :='23';--'21';
      RAISE EXP_TOKEN_REJECT_RECORD;
    END IF;
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_err_msg :=
    'Error while getting  Eligibility check and Provisioning Retry count' ||
    SUBSTR(SQLERRM,1,200);
    l_resp_cde :='21';
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;*/
  
  IF NVL(L_RULE_BYPASS,'N') <> 'Y' THEN
  --EN  Eligibity flag and  Provisioning retry count
   BEGIN
    IF l_provisioning_flag IS NOT NULL AND l_provisioning_flag ='N' THEN
      l_err_msg            :='Velocity Rule Failure';
      l_resp_cde           :='921';
      RAISE EXP_TOKEN_REJECT_RECORD;
    END IF;
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_resp_cde := '21';
    l_err_msg  := 'Error while Provisioning check '||SUBSTR(SQLERRM,1,200);
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;  
  
 
           -- SN  contact info updation check 
     BEGIN
       SELECT floor(((SYSDATE-CME_CHNG_DATE)*24)*60)
             INTO  L_DURATION_DIFF 
              FROM  cms_mob_email_log
              WHERE cme_inst_code = P_INST_CODE_IN
              AND CME_CUST_CODE = L_CUST_CODE;

       if  l_duration_diff < l_token_cust_upd_duration then
       
              insert into vms_rulecheck_results(vrr_rrn,vrr_token,vrr_correlation_id,vrr_rule_name,vrr_rule_desc,vrr_rule_result,vrr_execution_time)
              values(P_RRN_IN,P_token_in,p_correlationid_in,'Profile Updates','','FALSE',sysdate);
         l_resp_cde  := '12';
         l_err_msg :='Mobile/Email address has been updated within last '|| L_DURATION_DIFF ||'Minutes';
         raise exp_token_reject_record; 
         
      ELSE 
         
           insert into vms_rulecheck_results(vrr_rrn,vrr_token,vrr_correlation_id,vrr_rule_name,vrr_rule_desc,vrr_rule_result,vrr_execution_time)
              values(P_RRN_IN,P_token_in,p_correlationid_in,'Profile Updates','','TRUE',sysdate);
         
        
      end if;
      
        EXCEPTION  
         WHEN  EXP_TOKEN_REJECT_RECORD  THEN
           RAISE;
         WHEN NO_DATA_FOUND THEN
            NULL;
         WHEN OTHERS  THEN
             l_resp_cde := '21';
             l_err_msg :='Problem while selecting flag from cms_mob_email_log-'|| SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_TOKEN_REJECT_RECORD;
        END;

  
 BEGIN 
   IF l_prdcat_consumed_flag='N' THEN
    IF l_card_stat=0 THEN
      l_resp_cde    :='916';
      l_err_msg     :='Invalid Card Status';
      RAISE EXP_TOKEN_REJECT_RECORD;
    END IF; 
   ELSIF l_prdcat_consumed_flag='Y' THEN
     IF l_card_stat=0 THEN
      BEGIN 
       UPDATE CMS_APPL_PAN SET CAP_CARD_STAT=l_prdcat_consumed_stat WHERE CAP_PAN_CODE= l_hash_pan
        and cap_inst_code = p_inst_code_in;
        
        insert into vms_rulecheck_results(vrr_rrn,vrr_token,vrr_correlation_id,vrr_rule_name,vrr_rule_desc,vrr_rule_result,vrr_execution_time)
              values(P_RRN_IN,P_token_in,p_correlationid_in,'Consumed Status','','FALSE',sysdate);
        l_resp_cde    :='916';
        l_err_msg     :='Invalid Card Status';
        l_return_cde:='16';
        RAISE EXP_TOKEN_REJECT_RECORD;
         EXCEPTION
        WHEN EXP_TOKEN_REJECT_RECORD THEN
        RAISE;
        WHEN OTHERS THEN
          l_resp_cde := '21';
          l_err_msg  := 'Error while Updating consumed flag '||SUBSTR(SQLERRM,1,200);
          RAISE EXP_TOKEN_REJECT_RECORD;
        END;
    ELSE 
       
         insert into vms_rulecheck_results(vrr_rrn,vrr_token,vrr_correlation_id,vrr_rule_name,vrr_rule_desc,vrr_rule_result,vrr_execution_time)
              values(P_RRN_IN,P_token_in,p_correlationid_in,'Consumed Status','','TRUE',sysdate);
        
     END IF;    
    END IF;  
    
    sp_status_check_gpr (P_INST_CODE_IN, P_CARD_NUMBER_IN,
    P_DELIVERY_CHANNEL_IN, l_exp_date, L_card_stat, P_TRAN_CODE_IN,
    P_TRAN_MODE_IN, l_prod_code, l_card_type, P_MSG_TYPE_IN, P_TRAN_DATE_IN,
    P_TRAN_TIME_IN, NULL, --p_international_ind,
    NULL,                 --p_pos_verfication,
    NULL,                 --p_mcc_code,
    l_resp_cde, l_err_msg);
    IF ( (l_resp_cde <> '1' AND l_err_msg <> 'OK') OR
      (
        l_resp_cde <> '0' AND l_err_msg <> 'OK'
      )
      ) then
      l_resp_cde    :='916';
      l_err_msg     :='Invalid Card Status';
      RAISE EXP_TOKEN_REJECT_RECORD;
    ELSE
      l_status_chk := l_resp_cde;
      l_resp_cde   := '1';
    END IF;
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_resp_cde := '21';
    l_err_msg  := 'Error from GPR Card Status Check ' || SUBSTR (SQLERRM, 1,
    200) || l_resp_cde;
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
  --En GPR Card status check
  IF l_status_chk = '1' THEN
    -- Expiry Check
    BEGIN
      IF TO_DATE (P_TRAN_DATE_IN, 'YYYYMMDD') > LAST_DAY (TO_CHAR (l_exp_date,
        'DD-MON-YY')) THEN
        l_resp_cde := '13';
        l_err_msg  := 'EXPIRED CARD';
        RAISE EXP_TOKEN_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_TOKEN_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg  := 'ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_TOKEN_REJECT_RECORD;
    END;
  END IF;
  
  --  SN Kyc Status check
IF l_prdcat_kyc_flag='Y' THEN
  BEGIN  
    SELECT
      CCM_KYC_FLAG
    INTO
      L_KYC_FLAG
    FROM
      CMS_CUST_MAST
    WHERE
      CCM_CUST_CODE  =L_CUST_CODE
    AND CCM_INST_CODE=P_INST_CODE_IN;
    IF L_KYC_FLAG NOT IN ('P','O','Y','I') THEN
      l_rule_fail:='Y';
      l_resp_cde    :='917';
      l_err_msg     :='KYC Check failed';
      RAISE EXP_TOKEN_REJECT_RECORD;
    END IF;   
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_resp_cde := '12';
    l_err_msg  :='Error while selecting kyc details'|| SUBSTR (SQLERRM, 1, 200)
    ;
    RAISE EXP_TOKEN_REJECT_RECORD;
  END; 
END IF;
  -- expiry date check
IF l_prdcat_expdate_flag='Y' THEN
  BEGIN
 
    IF l_exp_date                   IS NOT NULL THEN
      IF TO_CHAR(l_exp_date,'YYMM') <> P_EXPRY_DATE_IN THEN
        l_rule_fail:='Y';
        l_resp_cde             := '918';
        l_err_msg                :='Incorrect Expiry / CVV2';
        RAISE EXP_TOKEN_REJECT_RECORD;
      END IF;
    END IF;
  
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_resp_cde := '12';
    l_err_msg  := 'Error while checking Expiry date';
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
END IF;
 
  -- SN  Account Balance
  IF l_prdcat_acct_bal_flag='Y' THEN
  BEGIN  
    SELECT
      CAM_ACCT_BAL
    INTO
      l_acct_bal
    FROM
      CMS_ACCT_MAST
    WHERE
      CAM_ACCT_NO    =L_ACCT_NUMBER
    AND CAM_INST_CODE=P_INST_CODE_IN;
    
    IF l_prdcat_acct_bal_type='<' THEN
      IF l_acct_bal   < to_number(l_prdcat_acct_bal_val) THEN
         l_acc_bal_check_fail:='Y';
      END IF;
    ELSIF l_prdcat_acct_bal_type='>' THEN
      IF l_acct_bal   > to_number(l_prdcat_acct_bal_val) THEN
        l_acc_bal_check_fail:='Y';
      END IF;  
    ELSIF l_prdcat_acct_bal_type='=' THEN
      IF l_acct_bal   = to_number(l_prdcat_acct_bal_val) THEN
        l_acc_bal_check_fail:='Y';
      END IF;  
    ELSIF l_prdcat_acct_bal_type='>=' THEN
      IF l_acct_bal   >= to_number(l_prdcat_acct_bal_val) THEN
        l_acc_bal_check_fail:='Y';
      END IF;  
    ELSIF l_prdcat_acct_bal_type='<=' THEN
      IF l_acct_bal   <= to_number(l_prdcat_acct_bal_val) THEN
        l_acc_bal_check_fail:='Y';    
      END IF;
    END IF;  
    
    if l_acc_bal_check_fail='Y' then
      l_rule_fail:='Y';
      l_resp_cde    :='919';
      l_err_msg     :='Card Balance Validation Failure';
      RAISE EXP_TOKEN_REJECT_RECORD;
    END IF;
   
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_resp_cde := '12';
    l_err_msg  :='Error while selecting acct balance'|| SUBSTR (SQLERRM, 1, 200
    );
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
END IF;
 END IF; 
 
 
  P_RESMSG_OUT   :=l_err_msg;
  p_resp_code_out:=l_resp_cde;
  P_RETURN_CODE_OUT:=l_return_cde;
EXCEPTION
WHEN EXP_TOKEN_REJECT_RECORD THEN
  --ROLLBACK;
  IF l_rule_fail='Y' THEN
    IF L_TOKEN_PROVISION_RETRY_MAX = l_provisioning_attempt_cnt+1 THEN
      BEGIN
        UPDATE
          CMS_APPL_PAN
        SET
          CAP_PROVISIONING_FLAG          ='N',
          CAP_PROVISIONING_ATTEMPT_COUNT = NVL(CAP_PROVISIONING_ATTEMPT_COUNT,0)+1
        WHERE
          CAP_INST_CODE  = P_INST_CODE_IN
        AND CAP_PAN_CODE = L_HASH_PAN;
      EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE_OUT := '21';
        P_RESMSG_OUT    :=
        'Exception While updating provisioning count and flag TO N ' ||SUBSTR(
        SQLERRM,1,200);
      END;
    ELSE
      BEGIN
        UPDATE
          CMS_APPL_PAN
        SET
          CAP_PROVISIONING_ATTEMPT_COUNT = NVL(CAP_PROVISIONING_ATTEMPT_COUNT,0)+1
        WHERE
          CAP_INST_CODE  = P_INST_CODE_IN
        AND CAP_PAN_CODE = L_HASH_PAN;
      EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE_OUT := '21';
        P_RESMSG_OUT    :=
        'Exception While updating provisioning count and flag ' ||SUBSTR(
        SQLERRM,1,200);
      END;
    END IF;
  END IF;
    P_RESMSG_OUT   :=l_err_msg;
    p_resp_code_out:=l_resp_cde;
    P_RETURN_CODE_OUT:=l_return_cde;
WHEN OTHERS THEN
  P_RESP_CODE_OUT:=l_resp_cde;
  P_RESMSG_OUT := 'Problem while checking preverifications: '||l_err_msg || SUBSTR (SQLERRM, 1, 200);
END;

PROCEDURE TOKEN_LOG_RULE_RESPONSE(
    P_INST_CODE_IN     IN VARCHAR2,
    P_CARD_NUMBER_IN   IN VARCHAR2,
    P_TOKEN_REQUESTER_ID_IN    IN VARCHAR2,
    p_rule_response               IN  	VARCHAR2,
    p_rrn_in                      IN  	varchar2,
    p_token_in   		              IN  	varchar2,
    p_token_device_id_in    IN VARCHAR2,
    P_RESP_CODE_OUT OUT VARCHAR2,
    P_RESMSG_OUT OUT VARCHAR2)
IS
  l_err_msg  VARCHAR2 (500);
  l_resp_cde VARCHAR2 (5);
  l_hash_pan cms_appl_pan.cap_pan_code%TYPE;
  l_encr_pan cms_appl_pan.cap_pan_code_encr%TYPE;  
  l_rule_count number(5);
  EXP_REJECT_RECORD      EXCEPTION;
  
BEGIN
  l_err_msg :='OK';
  L_RESP_CDE:=1;
  
    BEGIN
      l_hash_pan := gethash (P_CARD_NUMBER_IN);
    EXCEPTION
    WHEN OTHERS THEN
      l_resp_cde := '12';
      L_ERR_MSG := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
  
   --Sn Create encr pan
     BEGIN
        l_encr_pan := fn_emaps_main (P_CARD_NUMBER_IN);
     EXCEPTION
        WHEN OTHERS
        THEN
           l_err_msg :=
                 'Error while converting emcrypted pan '
              || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_reject_record;
     END; 
  
          IF p_token_requester_id_in IS NOT NULL AND p_token_device_id_in IS NOT NULL THEN
          BEGIN
          SELECT COUNT(*) INTO l_rule_count FROM VMS_TOKEN_RULE_RESPLOG WHERE VTR_PAN_CODE=l_hash_pan
          AND VTR_WALLET_ID=p_token_requester_id_in AND 
          VTR_DEVICE_ID=p_token_device_id_in;
        
          IF L_RULE_COUNT>0 THEN
            UPDATE VMS_TOKEN_RULE_RESPLOG SET VTR_RULE_RESPONSE=p_rule_response,VTR_LUPD_DATE=SYSDATE,VTR_RRN=P_RRN_IN WHERE 
            VTR_PAN_CODE=L_HASH_PAN
            and VTR_WALLET_ID=P_TOKEN_REQUESTER_ID_IN and 
            VTR_DEVICE_ID=P_TOKEN_DEVICE_ID_IN;
          ELSE
            insert into VMS_TOKEN_RULE_RESPLOG (VTR_PAN_CODE,
            VTR_PAN_CODE_ENCR,
            VTR_TOKEN,
            VTR_RRN,
            VTR_WALLET_ID,
            VTR_DEVICE_ID,
            VTR_RULE_RESPONSE,
            VTR_INS_DATE,
            VTR_LUPD_DATE) values(L_HASH_PAN,L_ENCR_PAN,P_TOKEN_IN,P_RRN_IN,P_TOKEN_REQUESTER_ID_IN,
            P_TOKEN_DEVICE_ID_IN,p_rule_response,sysdate,sysdate);
          END IF;       
          
          EXCEPTION  
          WHEN  OTHERS THEN
          l_resp_cde := '21';
          l_err_msg := 'Exception While logging rule response ' ||substr(SQLERRM,1,200); 
          RAISE  EXP_REJECT_RECORD; 
        END;
     END IF;   
        P_RESP_CODE_OUT:=L_RESP_CDE;
        P_RESMSG_OUT:=l_err_msg;
        EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
      --  ROLLBACK;
         P_RESP_CODE_OUT := '21';
        P_RESMSG_OUT := 'Exception While logging rule response ' ||substr(SQLERRM,1,200); 
        END;
        
 PROCEDURE LP_TOKEN_CREATE_UPDATE(
    P_TOKEN_IN                    IN VARCHAR2,
    P_HASH_PAN_IN                 IN VARCHAR2,
    P_TOKEN_TYPE_IN               IN VARCHAR2,
    P_RULE_RESPONSE               IN VARCHAR2,
    P_TOKEN_ASSURANCE_LEVEL_IN    IN VARCHAR2,
    P_TOKEN_REQUESTER_ID_IN       IN VARCHAR2,
    P_TOKEN_REF_ID_IN             IN VARCHAR2,
    P_TOKEN_EXPRY_DATE_IN         IN VARCHAR2,
    P_TOKEN_PAN_REF_ID_IN         IN VARCHAR2,
    P_TOKEN_WPPAN_SOURCE_IN       IN VARCHAR2,
    P_TOKEN_WPRISKASSESSMENT_IN   IN VARCHAR2,
    P_TOKEN_WPRISKASSESS_VER_IN   IN VARCHAR2,
    P_TOKEN_WPDEVICE_SCORE_IN     IN VARCHAR2,
    P_TOKEN_WPACCOUNT_SCORE_IN    IN VARCHAR2 ,
    P_TOKEN_WPREASON_CODES_IN     IN VARCHAR2,
    P_TOKEN_WPACCT_ID_IN          IN VARCHAR2,
    P_TOKEN_WPACCT_EMAIL_IN       IN VARCHAR2,
    P_TOKEN_DEVICE_TYPE_IN        IN VARCHAR2,
    P_TOKEN_DEVICE_LANGCODE_IN    IN VARCHAR2,
    P_TOKEN_DEVICE_ID_IN          IN VARCHAR2,
    P_TOKEN_DEVICE_NO_IN          IN VARCHAR2,
    P_TOKEN_DEVICE_NAME_IN        IN VARCHAR2,
    P_TOKEN_DEVICE_LOC_IN         IN VARCHAR2,
    P_TOKEN_DEVICE_IP_IN          IN VARCHAR2,
    P_TOKEN_DEVICE_SECUREELEID_IN IN VARCHAR2,
    P_WALLET_IDENTIFIER_IN        IN VARCHAR2,
    P_STORAGE_TECH_IN             IN VARCHAR2,
    P_TOKEN_RISKASSESS_SCORE_IN   IN VARCHAR2,
    P_TOKEN_PROVISIONING_SCORE_IN IN VARCHAR2,
    P_CONTACTLESS_USAGE_IN        IN VARCHAR2,
    P_CARD_ECOMM_USAGE_IN         IN VARCHAR2,
    P_MOB_ECOMM_USAGE_IN_IN       IN VARCHAR2,
    P_ACCT_NUMBER_IN              IN VARCHAR2,
    P_CUST_CODE_IN                IN VARCHAR2,
    P_INST_CODE_IN                IN VARCHAR2,
    P_TOKEN_REQID13_IN            IN VARCHAR2,
    P_WP_REQID_IN                 IN VARCHAR2,
    P_WP_CONVID_IN                IN VARCHAR2,
    P_WALLET_ID_IN                IN VARCHAR2,
    p_payment_appplninstanceid_in IN VARCHAR2,
    p_de62_uid_in In VARCHAR2,
    P_RESP_CDE_OUT OUT VARCHAR2,
    P_resp_MSG_OUT OUT VARCHAR2)
IS
  l_DE62_003_TOKENREQUESTORID vms_de62_dtl.VDD_DE62_003_TOKENREQUESTORID%TYPE;
  l_DE62_013_TOKENREQUESTORID vms_de62_dtl.VDD_DE62_013_TOKENREQUESTORID%TYPE;
  l_DE62_014_WPREQUESTID vms_de62_dtl.VDD_DE62_014_WPREQUESTID%TYPE;
  l_DE62_015_WPCONVERSIONID vms_de62_dtl.VDD_DE62_015_WPCONVERSIONID%TYPE;
  l_DE62_031_DEVICETYPE vms_de62_dtl.VDD_DE62_031_DEVICETYPE%TYPE;
  l_DE62_032_DEVICELANGCDE vms_de62_dtl.VDD_DE62_032_DEVICELANGCDE%TYPE;
  l_DE62_033_DEVICEID vms_de62_dtl.VDD_DE62_033_DEVICEID%TYPE;
  l_DE62_034_DEVICENUMBER vms_de62_dtl.VDD_DE62_034_DEVICENUMBER%TYPE;
  l_DE62_035_DEVICENAME vms_de62_dtl.VDD_DE62_035_DEVICENAME%TYPE;
  l_DE62_036_DEVICELOCATION vms_de62_dtl.VDD_DE62_036_DEVICELOCATION%TYPE;
  l_DE62_037_IPADDRESS vms_de62_dtl.VDD_DE62_037_IPADDRESS%TYPE;
  l_DE62_038_SECUREELEMENTID vms_de62_dtl.VDD_DE62_038_SECUREELEMENTID%TYPE;
  l_de62_039_walletidentifier vms_de62_dtl.vdd_de62_039_walletidentifier%type;
  l_DE62_041_WPRISKASSMENT vms_de62_dtl.VDD_DE62_041_WPRISKASSESSMENT%type;
  l_DE62_042_WPRISKASSMENTVER vms_de62_dtl.VDD_DE62_042_WPRISKASSMENTVER%TYPE;
  l_DE62_043_WPDEVICESCORE vms_de62_dtl.VDD_DE62_043_WPDEVICESCORE%TYPE;
  l_DE62_044_WPACCOUNTSCORE vms_de62_dtl.VDD_DE62_044_WPACCOUNTSCORE%TYPE;
  l_DE62_045_WPREASONCODES vms_de62_dtl.VDD_DE62_045_WPREASONCODES%TYPE;
  l_DE62_046_ACCOUNTEMAILADDR vms_de62_dtl.VDD_DE62_046_ACCOUNTEMAILADDR%TYPE;
  l_de62_074_walletid vms_de62_dtl.vdd_de62_074_walletid%type;
  l_de62_075_storagetechnology vms_de62_dtl.vdd_de62_075_storagetechnology%type
  ;
  l_de62_046_accountemailid vms_de62_dtl.vdd_de62_046_accountemailid%type;
  l_DE62_007_TOKENTYPE vms_de62_dtl.vdd_DE62_007_TOKENTYPE%type;
  L_DE62_066_PANSOURCE VMS_DE62_DTL.VDD_DE62_066_PANSOURCE%TYPE;
  L_DE62_068_WPACCOUNTID VMS_DE62_DTL.VDD_DE62_068_WPACCOUNTID%TYPE;
  l_DE62_077_PAYAPPLID vms_de62_dtl.VDD_DE62_077_PAYAPPLID%type;
  --EXP_REJECT_RECORD      EXCEPTION;
  
       /************************************************************************************************************
	  
	   * Created by      : T.Narayanaswamy/Dhinakar.B
       * Created Date    : 27-September-2017
       * Created reason  : FSS-5277 - Additional Tokenization Changes
       * Reviewer         : Saravankumar/Spankaj
       * Build Number     : VMSGPRHOST_17.05.07
       
      ************************************************************************************************************/
BEGIN
      P_RESP_MSG_OUT:='OK';
      P_RESP_CDE_OUT :='1';
  BEGIN
    SELECT
      vdd_de62_003_tokenrequestorid,
      vdd_de62_013_tokenrequestorid,
      VDD_DE62_014_WPREQUESTID,
      VDD_DE62_015_WPCONVERSIONID,
      VDD_DE62_031_DEVICETYPE,
      VDD_DE62_032_DEVICELANGCDE,
      VDD_DE62_033_DEVICEID,
      VDD_DE62_034_DEVICENUMBER,
      VDD_DE62_035_DEVICENAME,
      VDD_DE62_036_DEVICELOCATION,
      VDD_DE62_037_IPADDRESS,
      VDD_DE62_038_SECUREELEMENTID,
      vdd_de62_039_walletidentifier,
      VDD_DE62_041_WPRISKASSESSMENT,
      VDD_DE62_042_WPRISKASSMENTVER,
      VDD_DE62_043_WPDEVICESCORE,
      VDD_DE62_044_WPACCOUNTSCORE,
      VDD_DE62_045_WPREASONCODES,
      vdd_de62_046_accountemailaddr,
      vdd_DE62_046_ACCOUNTEMAILID,
      vdd_de62_074_walletid,
      vdd_de62_075_storagetechnology,
      vdd_de62_007_tokentype,
      VDD_DE62_066_PANSOURCE,
      VDD_DE62_068_WPACCOUNTID,
      vdd_de62_077_payapplid
    INTO
      l_de62_003_tokenrequestorid,
      l_DE62_013_TOKENREQUESTORID,
      l_DE62_014_WPREQUESTID,
      l_DE62_015_WPCONVERSIONID,
      l_DE62_031_DEVICETYPE,
      l_DE62_032_DEVICELANGCDE,
      l_DE62_033_DEVICEID,
      l_DE62_034_DEVICENUMBER,
      l_de62_035_devicename,
      l_DE62_036_DEVICELOCATION,
      l_DE62_037_IPADDRESS,
      l_DE62_038_SECUREELEMENTID,
      l_de62_039_walletidentifier,
      l_DE62_041_WPRISKASSMENT,
      l_DE62_042_WPRISKASSMENTVER,
      l_DE62_043_WPDEVICESCORE,
      l_DE62_044_WPACCOUNTSCORE,
      l_DE62_045_WPREASONCODES,
      l_de62_046_accountemailaddr,
      l_DE62_046_ACCOUNTEMAILID,
      l_DE62_074_WALLETID,
      l_de62_075_storagetechnology,
      l_de62_007_tokentype,
      l_de62_066_pansource,
      L_DE62_068_WPACCOUNTID,
      l_de62_077_payapplid
    FROM
      vms_de62_dtl
    WHERE
      vdd_de62_id    =p_de62_uid_in
    AND vdd_pan_code =P_HASH_PAN_IN;
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END;
  BEGIN
    INSERT
    INTO
      VMS_TOKEN_INFO
      (
        VTI_TOKEN,
        VTI_TOKEN_PAN,
        VTI_TOKEN_TYPE,
        VTI_TOKEN_STAT,
        VTI_TOKEN_ASSURANCE_LEVEL,
        VTI_TOKEN_REQUESTOR_ID,
        VTI_TOKEN_REF_ID,
        VTI_TOKEN_EXPIRY_DATE,
        VTI_TOKEN_PAN_REF_ID ,
        VTI_TOKEN_WPPAN_SOURCE ,
        VTI_TOKEN_WPRISKASSESSMENT,
        vti_token_wpriskassessment_ver,
        vti_token_wpdevice_score,
        vti_token_wpaccount_score,
        vti_token_wpreason_codes,
        vti_token_wpacct_id ,
        vti_token_wpacct_email,
        VTI_TOKEN_DEVICE_TYPE ,
        VTI_TOKEN_DEVICE_LANGCODE ,
        VTI_TOKEN_DEVICE_ID ,
        VTI_TOKEN_DEVICE_NO ,
        VTI_TOKEN_DEVICE_NAME ,
        VTI_TOKEN_DEVICE_LOC ,
        VTI_TOKEN_DEVICE_IP ,
        vti_token_device_secureeleid ,
        VTI_WALLET_IDENTIFIER,
        VTI_STORAGE_TECHNOLOGY,
        VTI_TOKEN_RISKASSESSMENT_SCORE ,
        VTI_TOKEN_PROVISIONING_SCORE ,
        VTI_CONTACTLESS_USAGE,
        VTI_CARD_ECOMM_USAGE,
        VTI_MOB_WALLET_ECOMM_USAGE,
        VTI_ACCT_NO,
        VTI_CUST_CODE,
        VTI_INST_CODE,
        vti_ins_date,
        VTI_LUPD_DATE ,
        vti_de62013_tokenrequestorid ,
        vti_de62013_wprequestid ,
        VTI_de62013_wpconversionid ,
        VTI_DE62054_WALLETID,
        VTI_PAYMENTAPPLN_INSTANCEID,
	VTI_DE62_CORRELATION_ID
      )
      VALUES
      (
        trim(p_token_in) ,
        P_HASH_PAN_IN ,
        NVL( P_TOKEN_TYPE_IN,l_DE62_007_TOKENTYPE) ,
        DECODE(P_RULE_RESPONSE,'G','A','I'),
        p_token_assurance_level_in ,
        NVL(p_token_requester_id_in,l_de62_003_tokenrequestorid) ,
        p_token_ref_id_in ,
        p_token_expry_date_in ,
        p_token_pan_ref_id_in ,
        NVL(p_token_wppan_source_in,l_de62_066_pansource) ,
        NVL(p_token_wpriskassessment_in,l_DE62_041_WPRISKASSMENT),
        NVL(p_token_wpriskassess_ver_in,l_de62_042_wpriskassmentver),
        NVL(p_token_wpdevice_score_in,l_DE62_043_WPDEVICESCORE),
        NVL(p_token_wpaccount_score_in,l_de62_044_wpaccountscore),
        NVL(p_token_wpreason_codes_in,l_de62_045_wpreasoncodes),
        NVL( p_token_wpacct_id_in,l_DE62_068_WPACCOUNTID),
        NVL(p_token_wpacct_email_in ,l_de62_046_accountemailaddr),
        NVL(p_token_device_type_in ,l_de62_031_devicetype) ,
        NVL(p_token_device_langcode_in ,l_de62_032_devicelangcde) ,
        NVL(p_token_device_id_in,l_de62_033_deviceid) ,
        NVL(p_token_device_no_in ,l_de62_034_devicenumber) ,
        NVL(p_token_device_name_in ,l_de62_035_devicename) ,
        NVL(p_token_device_loc_in ,l_de62_036_devicelocation) ,
        NVL(p_token_device_ip_in ,l_de62_037_ipaddress) ,
        NVL(p_token_device_secureeleid_in ,l_de62_038_secureelementid) ,
        NVL(p_wallet_identifier_in,l_DE62_039_WALLETIDENTIFIER),
        NVL(p_storage_tech_in,l_DE62_075_STORAGETECHNOLOGY),
        p_token_riskassess_score_in ,
        p_token_provisioning_score_in ,
        p_contactless_usage_in,
        p_card_ecomm_usage_in,
        p_mob_ecomm_usage_in_in,
        P_ACCT_NUMBER_IN,
        P_CUST_CODE_IN,
        p_inst_code_in,
        sysdate,
        sysdate ,
        NVL(p_token_reqid13_in,l_de62_013_tokenrequestorid) ,
        NVL(p_wp_reqid_in,l_de62_014_wprequestid) ,
        NVL(p_wp_convid_in,l_de62_015_wpconversionid) ,
        NVL(p_wallet_id_in,l_DE62_074_WALLETID),
        NVL(p_payment_appplninstanceid_in,l_DE62_077_PAYAPPLID),
	p_de62_uid_in
      );
  EXCEPTION
  WHEN dup_val_on_index THEN
    UPDATE
      VMS_TOKEN_INFO
    SET
      VTI_TOKEN     =NVL(VTI_TOKEN,trim(p_token_in)),
      vti_token_pan =NVL(vti_token_pan,P_HASH_PAN_IN),
      VTI_TOKEN_TYPE=COALESCE(VTI_TOKEN_TYPE,P_TOKEN_TYPE_IN,
      l_DE62_007_TOKENTYPE),
      VTI_TOKEN_STAT =DECODE(VTI_TOKEN_STAT,'A','A','D','D',DECODE(P_RULE_RESPONSE,'G','A','I')),
      vti_token_assurance_level=NVL(vti_token_assurance_level,
      p_token_assurance_level_in),
      VTI_TOKEN_REQUESTOR_ID=COALESCE(VTI_TOKEN_REQUESTOR_ID,
      p_token_requester_id_in,l_de62_003_tokenrequestorid),
      vti_de62013_tokenrequestorid=COALESCE(vti_de62013_tokenrequestorid,
      p_token_reqid13_in,l_de62_013_tokenrequestorid),
      vti_de62013_wprequestid=COALESCE(vti_de62013_wprequestid,p_wp_reqid_in,
      l_de62_014_wprequestid),
      vti_de62013_wpconversionid=COALESCE(vti_de62013_wpconversionid,
      p_wp_convid_in,l_de62_015_wpconversionid),
      vti_de62054_walletid=COALESCE(vti_de62054_walletid,p_wallet_id_in,
      l_de62_074_walletid),
      vti_storage_technology=COALESCE(vti_storage_technology,p_storage_tech_in,
      l_de62_075_storagetechnology),
      vti_token_device_type=COALESCE(vti_token_device_type,
      p_token_device_type_in,l_de62_031_devicetype),
      vti_token_device_langcode=COALESCE(vti_token_device_langcode,
      p_token_device_langcode_in,l_de62_032_devicelangcde),
      vti_token_device_id=COALESCE(vti_token_device_id,p_token_device_id_in,
      l_de62_033_deviceid),
      vti_token_device_no=COALESCE(vti_token_device_no,p_token_device_no_in,
      l_de62_034_devicenumber),
      vti_token_device_name=COALESCE(vti_token_device_name,
      p_token_device_name_in,l_de62_035_devicename),
      vti_token_device_loc=COALESCE(vti_token_device_loc,p_token_device_loc_in,
      l_de62_036_devicelocation),
      vti_token_device_ip=COALESCE(vti_token_device_ip,p_token_device_ip_in,
      l_de62_037_ipaddress),
      vti_token_device_secureeleid=COALESCE(vti_token_device_secureeleid,
      p_token_device_secureeleid_in,l_de62_038_secureelementid),
      vti_wallet_identifier=COALESCE(vti_wallet_identifier,
      p_wallet_identifier_in,l_de62_039_walletidentifier),
      vti_token_wpriskassessment=COALESCE(vti_token_wpriskassessment,
      p_token_wpriskassessment_in,l_DE62_041_WPRISKASSMENT),
      VTI_TOKEN_WPRISKASSESSMENT_VER=COALESCE(VTI_TOKEN_WPRISKASSESSMENT_VER,
      p_token_wpriskassess_ver_in,l_de62_042_wpriskassmentver),
      vti_token_wpdevice_score=COALESCE(vti_token_wpdevice_score,
      p_token_wpdevice_score_in,l_de62_043_wpdevicescore),
      vti_token_wpaccount_score=COALESCE(vti_token_wpaccount_score,
      p_token_wpaccount_score_in,l_de62_044_wpaccountscore),
      vti_token_wpreason_codes=COALESCE(vti_token_wpreason_codes,
      p_token_wpreason_codes_in,l_de62_045_wpreasoncodes),
      vti_token_wpacct_email=COALESCE(vti_token_wpacct_email,
      p_token_wpacct_email_in,l_de62_046_accountemailaddr),
      vti_token_wpacct_id=COALESCE(vti_token_wpacct_id,p_token_wpacct_id_in,
      l_DE62_068_WPACCOUNTID),
      VTI_TOKEN_REF_ID      =NVL(VTI_TOKEN_REF_ID,p_token_ref_id_in),
      VTI_TOKEN_EXPIRY_DATE =NVL(VTI_TOKEN_EXPIRY_DATE,p_token_expry_date_in),
      VTI_TOKEN_PAN_REF_ID  =NVL(VTI_TOKEN_PAN_REF_ID,p_token_pan_ref_id_in) ,
      vti_token_wppan_source=COALESCE(vti_token_wppan_source,
      p_token_wppan_source_in,l_de62_066_pansource),
      VTI_TOKEN_RISKASSESSMENT_SCORE=NVL(VTI_TOKEN_RISKASSESSMENT_SCORE,
      p_token_riskassess_score_in),
      VTI_TOKEN_PROVISIONING_SCORE=NVL(VTI_TOKEN_PROVISIONING_SCORE,
      p_token_provisioning_score_in),
      VTI_CONTACTLESS_USAGE     =NVL(VTI_CONTACTLESS_USAGE,p_contactless_usage_in),
      VTI_CARD_ECOMM_USAGE      =NVL(VTI_CARD_ECOMM_USAGE,p_card_ecomm_usage_in),
      vti_mob_wallet_ecomm_usage=NVL(vti_mob_wallet_ecomm_usage,
      p_mob_ecomm_usage_in_in),
      VTI_ACCT_NO                =NVL(VTI_ACCT_NO,P_ACCT_NUMBER_IN),
      VTI_CUST_CODE              =NVL(VTI_CUST_CODE,P_CUST_CODE_IN),
      VTI_INST_CODE              =NVL(VTI_INST_CODE,P_INST_CODE_IN),
      VTI_INS_DATE               =NVL(VTI_INS_DATE,SYSDATE),
      VTI_LUPD_DATE              =sysdate,
      vti_paymentappln_instanceid=COALESCE(vti_paymentappln_instanceid,
      p_payment_appplninstanceid_in,l_de62_077_payapplid),
      VTI_DE62_CORRELATION_ID=p_de62_uid_in
    WHERE
      VTI_TOKEN       =trim(p_token_in)
    AND vti_token_pan = P_HASH_PAN_IN;
  WHEN OTHERS THEN
    P_resp_CDE_OUT := '21';
    P_resp_MSG_OUT := 'Error While inserting VMS_TOKEN_INFO  ' || SUBSTR (
    SQLERRM, 1, 200);
  END;
END;

 PROCEDURE LP_GET_TOKEN_STATUS(
 P_TOKEN_IN IN VARCHAR2,
 P_HASHCARD_IN IN VARCHAR2,
 P_TOKEN_OLD_STATUS_IN IN VARCHAR2,
 P_TOKEN_STAT_OUT OUT VARCHAR2) IS

   /************************************************************************************************************
  
   * Created by      : T.Narayanaswamy/Dhinakar.B
   * Created Date    : 27-September-2017
   * Created reason  : FSS-5277 - Additional Tokenization Changes
   * Reviewer         : Saravankumar/Spankaj
   * Build Number     : VMSGPRHOST_17.05.07
   
  ************************************************************************************************************/
 
 BEGIN
      P_TOKEN_STAT_OUT:='N';
     
 
        IF nvl(P_TOKEN_OLD_STATUS_IN,'N') <> 'A' THEN
          SELECT
          DECODE(trim(VTI_TOKEN_STAT),'A','Y','N')
          INTO
          P_TOKEN_STAT_OUT
          FROM
          vms_token_info
          WHERE
          vti_token       = trim(p_token_in)
          AND vti_token_pan = P_HASHCARD_IN;
          ELSE
          P_TOKEN_STAT_OUT :='N';
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
      P_TOKEN_STAT_OUT :='N';
  END;

PROCEDURE  AMEXTokenCreateAdvice (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_token_in   		              in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_token_type_in   		        in  	varchar2,
          p_token_status_in   		      in  	varchar2,
          p_token_assurance_level_in    in  	varchar2,
          p_token_requester_id_in   	  in  	varchar2,
          p_token_ref_id_in   		      in  	varchar2,
          p_token_expry_date_in         in  	varchar2,
          p_token_pan_ref_id_in         in  	varchar2,
          p_token_wpriskassessment_in   in  	varchar2,
          p_token_wpriskassess_ver_in   in  	varchar2,
          p_token_wpdevice_score_in     in  	varchar2,
          p_token_wpaccount_score_in    in  	varchar2,
          p_token_wpreason_codes_in     in  	varchar2,
          p_token_wppan_source_in       in  	varchar2,
          p_token_wpacct_id_in          in  	varchar2,
          p_token_wpacct_email_in       in  	varchar2,
          p_token_device_type_in        in  	varchar2,
          p_token_device_langcode_in    in  	varchar2,
          p_token_device_id_in          in  	varchar2,
          p_token_device_no_in          in  	varchar2,
          p_token_device_name_in        in  	varchar2,
          p_token_device_loc_in         in  	varchar2,
          p_token_device_ip_in          in  	varchar2,
          p_token_device_secureeleid_in in  	varchar2,
          p_token_riskassess_score_in   in  	varchar2,
          p_token_provisioning_score_in in  	varchar2,
          p_curr_code_in                in    varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_stan_in                     in  	varchar2,
          p_ntw_settl_date              in  	varchar2,
          p_expry_date_in               IN  	VARCHAR2,
          p_msg_reason_code_in          in    varchar2,
          p_contactless_usage_in        IN  	VARCHAR2,
          p_card_ecomm_usage_in         in  	varchar2,
          p_mob_ecomm_usage_in_in       IN  	VARCHAR2,
          p_wallet_identifier_in        IN  	VARCHAR2,
          p_storage_tech_in             IN  	VARCHAR2,     
          p_rule_response               IN  	VARCHAR2,
          p_token_reqid13_in            in  	varchar2,
          p_wp_reqid_in                 in  	varchar2,
          P_WP_CONVID_IN                IN  	VARCHAR2,
          P_WALLET_ID_IN                IN  	VARCHAR2,
          P_ZIP_CODE_IN                 IN    VARCHAR2,
          P_ADDRVRIFY_FLAG_IN           IN    VARCHAR2,
          p_networkid_switch_IN         IN    VARCHAR2,
          P_cust_addr_IN                IN    VARCHAR2   DEFAULT NULL ,
          p_auth_id_out                 out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2,
          p_de27response_out            out   varchar2,
          P_TOKEN_ACT_FLAG_OUT          out   varchar2,
          P_ADDR_VERFY_RESPONSE_OUT     OUT   VARCHAR2,
          p_resp_id_out                 OUT   VARCHAR2 --Added for sending to FSS (VMS-8018)
          )
   IS
      /************************************************************************************************************
       * Created Date     :  28-June-2018
       * Created By       :  Baskar K
       * Created For      :  AMEX Tokenization
       * Reviewer         :  Saravanakumar
       * Build Number     :  VMSR03_B0002
	   
	  * Modified By      : BASKAR KRISHNAN
     * Modified Date    : 07-FEB-2019
     * Purpose          : VMS-511 (Permanent Fraud Override Support)
     * Reviewer         : Saravanakumar
     * Release Number   : VMSR12_B0003

	   * Modified By      :  Areshka A.
       * Modified Date    :  03-Nov-2023
       * Purpose          :  VMS-8018: Added new out parameter (response id) for sending to FSS
       * Reviewer         :  
       * Build Number     :  
       
      ************************************************************************************************************/
      
      l_err_msg              VARCHAR2 (500);
      l_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type             transactionlog.txn_type%TYPE;
      l_dr_cr_flag           cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_tran_type            cms_transaction_mast.ctm_tran_type%TYPE;
      l_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_card_type            cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde             transactionlog.response_id%TYPE;
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      L_LOGIN_TXN            CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;
      L_LOGDTL_RESP          VARCHAR2 (500);
      L_PREAUTH_TYPE         CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
      EXP_REJECT_RECORD      EXCEPTION;
      L_CARDPACK_ID          CMS_APPL_PAN.CAP_CARDPACK_ID%TYPE;
      l_customer_id          cms_cust_mast.CCM_CUST_ID%type;            
      l_cell_no              cms_addr_mast.cam_mobl_one%type;
      l_email_id             cms_addr_mast.cam_email%type;
      L_RULE_RESPONSE        VMS_TOKEN_RULE_RESPLOG.VTR_RULE_RESPONSE%type;
      L_WALLET_ID            VMS_TOKEN_RULE_RESPLOG.VTR_WALLET_ID%type;
      L_TOKEN_OLD_STATUS     VMS_TOKEN_INFO.VTI_TOKEN_STAT%TYPE;   	 
      l_rule_bybass          cms_appl_pan.cap_rule_bypass%TYPE;
      l_remarks              transactionlog.remark%TYPE;
      l_customer_cardnum     cms_prod_cattype.cpc_customer_care_num%type;
	 
   BEGIN
      l_resp_cde := '1';
      l_err_msg :='OK';
      p_resmsg_out:='OK';
      l_time_stamp := SYSTIMESTAMP;
      BEGIN

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
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
               RAISE exp_reject_record;
         END;
         --End Generate HashKEY

         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   CAP_PRFL_CODE, CAP_EXPRY_DATE, CAP_PROXY_NUMBER,
                   cap_cust_code,ccm_cust_id,CAP_CARDPACK_ID,cap_rule_bypass
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   L_PRFL_CODE, L_EXPRY_DATE, L_PROXY_NUMBER,
                   l_cust_code,l_customer_id,L_CARDPACK_ID,l_rule_bybass
              from cms_appl_pan,cms_cust_mast
             where cap_inst_code=ccm_inst_code and cap_cust_code=ccm_cust_code and
             cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --End Get the card details  
         
           
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
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details '||substr(sqlerrm,1,200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
         --En generate auth id

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14';
           l_err_msg  := 'Invalid Card ';
           RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
        BEGIN
            AVS_CHECK (p_inst_code_in,
                       l_prod_code,
                       l_card_type,
                       P_ZIP_CODE_IN,
                       P_ADDRVRIFY_FLAG_IN,
                       p_networkid_switch_IN,
                       l_cust_code,
                       P_cust_addr_IN,
                       l_resp_cde,
                       l_err_msg,
                       P_ADDR_VERFY_RESPONSE_OUT);
                       
            IF l_err_msg <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error from  avs Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
         END;
		 
		 BEGIN
      SELECT
        trim(VTI_TOKEN_STAT)
      INTO
        l_token_old_status
      FROM
        vms_token_info
      WHERE
        vti_token       = trim(p_token_in)
      AND vti_token_pan = l_hash_pan;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
     NULL;
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg     := 'Problem while selecting token stat1' || SUBSTR(SQLERRM, 1,
      200);
      RAISE EXP_REJECT_RECORD;
    END;
         
         
        BEGIN
        select decode(p_msg_reason_code_in,'0259',p_wallet_identifier_in,p_token_requester_id_in)  into l_wallet_id from dual;
         
         IF  P_TXN_CODE_IN IN ('04','09') THEN        
         
          SELECT VTR_RULE_RESPONSE INTO L_RULE_RESPONSE 
          FROM VMS_TOKEN_RULE_RESPLOG WHERE VTR_PAN_CODE=L_HASH_PAN AND
          VTR_WALLET_ID=l_wallet_id  AND VTR_DEVICE_ID=p_token_device_id_in;      
               
         elsif p_txn_code_in='16' THEN
            L_RULE_RESPONSE:='Y';
          END IF;
              
         EXCEPTION       
         WHEN NO_DATA_FOUND THEN
         L_RULE_RESPONSE:='G';
        
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting VMS_TOKEN_TRANSACTIONLOG details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
         
         LP_GET_TOKEN_STATUS(
                      P_TOKEN_IN,
                      l_hash_pan,
                      L_TOKEN_OLD_STATUS,
                      P_TOKEN_ACT_FLAG_OUT);
    
 
  if trim(p_token_in) is not null  then
          
          
          LP_TOKEN_CREATE_UPDATE(P_TOKEN_IN,
          L_HASH_PAN,
          P_TOKEN_TYPE_IN,
          L_RULE_RESPONSE,
          P_TOKEN_ASSURANCE_LEVEL_IN,
          P_TOKEN_REQUESTER_ID_IN,
          P_TOKEN_REF_ID_IN,
          P_TOKEN_EXPRY_DATE_IN,
          P_TOKEN_PAN_REF_ID_IN,
          P_TOKEN_WPPAN_SOURCE_IN,
          P_TOKEN_WPRISKASSESSMENT_IN,
          P_TOKEN_WPRISKASSESS_VER_IN,
          P_TOKEN_WPDEVICE_SCORE_IN,
          P_TOKEN_WPACCOUNT_SCORE_IN,
          P_TOKEN_WPREASON_CODES_IN,
          P_TOKEN_WPACCT_ID_IN,
          P_TOKEN_WPACCT_EMAIL_IN,
          P_TOKEN_DEVICE_TYPE_IN,
          P_TOKEN_DEVICE_LANGCODE_IN,
          P_TOKEN_DEVICE_ID_IN  ,
          P_TOKEN_DEVICE_NO_IN,
          P_TOKEN_DEVICE_NAME_IN,
          P_TOKEN_DEVICE_LOC_IN,
          P_TOKEN_DEVICE_IP_IN,
          P_TOKEN_DEVICE_SECUREELEID_IN,
          P_WALLET_IDENTIFIER_IN,
          P_STORAGE_TECH_IN,
          P_TOKEN_RISKASSESS_SCORE_IN,
          P_TOKEN_PROVISIONING_SCORE_IN,
          P_CONTACTLESS_USAGE_IN,
          P_CARD_ECOMM_USAGE_IN,
          P_MOB_ECOMM_USAGE_IN_IN,
          L_ACCT_NUMBER,
          L_CUST_CODE,
          P_INST_CODE_IN,
          P_TOKEN_REQID13_IN,
          P_WP_REQID_IN,
          P_WP_CONVID_IN,
          P_WALLET_ID_IN,
          null,
          p_token_ref_id_in,
          L_RESP_CDE,
          l_err_msg
          );
        
        IF L_ERR_MSG <> 'OK' THEN
            RAISE  EXP_REJECT_RECORD; 
        END IF;
     END IF;
         
         
   if p_txn_code_in='16' THEN      
         BEGIN
           UPDATE CMS_APPL_PAN 
           SET   CAP_PROVISIONING_FLAG ='Y', CAP_PROVISIONING_ATTEMPT_COUNT=0,CAP_RULE_BYPASS=decode(l_rule_bybass,'P',CAP_RULE_BYPASS,'N')
          WHERE CAP_INST_CODE = P_INST_CODE_IN AND CAP_PAN_CODE = L_HASH_PAN;
          EXCEPTION  
                    WHEN  OTHERS THEN
              l_resp_cde := '21';
              l_err_msg := 'Exception While updating provisioning count TO 0 and flag TO Y ' ||substr(SQLERRM,1,200); 
              RAISE  exp_reject_record; 
         END;
         
      BEGIN
       TOKEN_LOG_RULE_RESPONSE(
          P_INST_CODE_IN ,
          p_pan_code_in,
          l_wallet_id,
          p_rule_response,
          p_rrn_in ,
          p_token_in,
          p_token_device_id_in,
          l_resp_cde,
          l_err_msg);   
        EXCEPTION  
        WHEN  OTHERS THEN
        l_resp_cde := '21';
        l_err_msg := 'Exception While loging rule response ' ||substr(SQLERRM,1,200); 
        RAISE  exp_reject_record; 
        END;
        

end if;


        LP_GET_TOKEN_STATUS(
                      P_TOKEN_IN,
                      l_hash_pan,
                      L_TOKEN_OLD_STATUS,
                      P_TOKEN_ACT_FLAG_OUT);
      
     EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK ;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK ;
      END;
      
   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
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
               p_resp_id_out := '69'; --Added for VMS-8018
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
      begin
	  select decode(NVL(l_rule_bybass,'N'),'Y','Rule Bypass Flag Enabled','P','Rule Bypass Flag Enabled',NULL) INTO l_remarks from dual;
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
                        NULL,
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
                        0,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        l_remarks,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_stan_in,
                        p_ntw_settl_date
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            0,
                            null,
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
                            L_LOGDTL_RESP,
                            null,
                            null,
                            p_stan_in
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resp_id_out := '69'; --Added for VMS-8018
         p_resmsg_out :=
            'Main exception from  authorization ' || substr (sqlerrm, 1, 300);
   end AMEXtokencreateadvice;
   
   PROCEDURE AMEX_TOKEN_AUTHORISE_PRECHECK(
    P_INST_CODE_IN        IN VARCHAR2,
    P_DELIVERY_CHANNEL_IN IN VARCHAR2,
    P_TRAN_CODE_IN        IN VARCHAR2,
    P_TRAN_MODE_IN        IN VARCHAR2,
    P_MSG_TYPE_IN         IN VARCHAR2,
    P_TRAN_DATE_IN        IN VARCHAR2,
    P_TRAN_TIME_IN        IN VARCHAR2,
    P_CARD_NUMBER_IN      IN VARCHAR2,
    P_EXPRY_DATE_IN       IN VARCHAR2,
    P_token_in               in varchar2,
    p_correlationid_in     in varchar2,
    P_RRN_IN               in varchar2,
    P_CVV2_FLAG_OUT       OUT VARCHAR2,
    P_RULE_BYPASS         OUT VARCHAR2,
    P_RESP_CODE_OUT       OUT VARCHAR2,
    p_resmsg_out          out varchar2,
    P_RETURN_CODE_OUT     out varchar2,
    p_consumedstat_code_out   OUT varchar2)
IS

      /************************************************************************************************************
       
       * Created Date     :  09-July-2018
       * Created By       :  Baskar K
       * Created For      :  AMEX Tokenization
       * Reviewer         :  Saravanakumar
       * Build Number     :  VMSR03_B0003
              
      ************************************************************************************************************/
	  
	  
  l_err_msg                          VARCHAR2 (500);
  l_resp_cde                         transactionlog.response_id%TYPE;
  l_return_cde                       transactionlog.response_id%TYPE;
  l_hash_pan                         cms_appl_pan.cap_pan_code%TYPE;
  l_encr_pan                         cms_appl_pan.cap_pan_code_encr%TYPE;
  l_prod_code                        cms_prod_mast.cpm_prod_code%TYPE;
  l_card_type                        cms_prod_cattype.cpc_card_type%TYPE;
  l_card_stat                        cms_appl_pan.cap_card_stat%TYPE;
  l_exp_date                         cms_appl_pan.CAP_EXPRY_DATE%TYPE;
  l_cust_code                        cms_appl_pan.CAP_cust_code%TYPE;
  L_ACCT_NUMBER                      cms_appl_pan.CAP_acct_no%TYPE;
  L_KYC_FLAG                         CMS_CUST_MAST.CCM_KYC_FLAG %TYPE;
  EXP_TOKEN_REJECT_RECORD            EXCEPTION;
  L_PROVISIONING_FLAG                CMS_APPL_PAN.CAP_PROVISIONING_FLAG%TYPE;
  L_TOKEN_PROVISION_RETRY_MAX        CMS_PROD_CATTYPE.CPC_TOKEN_PROVISION_RETRY_MAX%TYPE;
  L_TOKEN_ELIGIBILITY                CMS_PROD_CATTYPE.CPC_TOKEN_ELIGIBILITY%TYPE;
  l_provisioning_attempt_cnt         CMS_APPL_PAN.CAP_PROVISIONING_ATTEMPT_COUNT%TYPE;
  l_acct_bal                         cms_acct_mast.cam_acct_bal%TYPE;
  l_status_chk                       NUMBER;
  l_prdcat_kyc_flag                  CMS_PROD_CATTYPE.CPC_KYC_FLAG%TYPE;
  l_prdcat_expdate_flag              CMS_PROD_CATTYPE.CPC_EXPIRY_DATE_CHECK_FLAG%TYPE;
  l_prdcat_acct_bal_flag             CMS_PROD_CATTYPE.CPC_ACCT_BALANCE_CHECK_FLAG%TYPE;
  l_prdcat_acct_bal_type             CMS_PROD_CATTYPE.CPC_ACCT_BAL_CHECK_TYPE%TYPE;
  l_prdcat_acct_bal_val              CMS_PROD_CATTYPE.CPC_ACCT_BAL_CHECK_VALUE%TYPE;
  l_prdcat_consumed_flag             CMS_PROD_CATTYPE.CPC_CONSUMED_FLAG%TYPE;
  l_prdcat_consumed_stat             cms_prod_cattype.CPC_CONSUMED_CARD_STAT%TYPE;
  l_rule_fail                        VARCHAR2(1) :='N';
  l_acc_bal_check_fail               VARCHAR2(1) :='N';
  L_TOKEN_CUST_UPD_DURATION          CMS_PROD_CATTYPE.CPC_TOKEN_CUST_UPD_DURATION%TYPE;
  L_DURATION_DIFF                    NUMBER;
  L_RULE_BYPASS                      cms_appl_pan.CAP_RULE_BYPASS%TYPE;
  
begin
  l_err_msg :='OK';
  l_return_cde:='00';
  l_resp_cde:=1;
  
  BEGIN
    l_hash_pan := gethash (P_CARD_NUMBER_IN);
  EXCEPTION
  WHEN OTHERS THEN
    l_resp_cde := '12';
    l_err_msg := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
  BEGIN
    SELECT
      cap_prod_code,
      cap_card_type,
      cap_card_stat,
      CAP_EXPRY_DATE,
      CAP_cust_code,
      CAP_acct_no,
      CAP_PROVISIONING_FLAG,
      nvl(CAP_PROVISIONING_ATTEMPT_COUNT,0),
      NVL(CAP_RULE_BYPASS,'N')
    INTO
      l_prod_code,
      l_card_type,
      l_card_stat,
      l_exp_date,
      l_cust_code,
      L_ACCT_NUMBER,
      l_provisioning_flag,
      l_provisioning_attempt_cnt,
      L_RULE_BYPASS
    FROM
      cms_appl_pan
    WHERE
      cap_pan_code    = l_hash_pan
    AND cap_inst_code = P_INST_CODE_IN
    AND cap_mbr_numb='000';
    
    P_RULE_BYPASS:=L_RULE_BYPASS;
  EXCEPTION
  WHEN OTHERS THEN
	P_RULE_BYPASS:='N';
	  l_resp_cde := '12';
    l_err_msg  := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
  BEGIN
    SELECT
      NVL(CPC_KYC_FLAG,'N'),
      DECODE(L_RULE_BYPASS,'Y','N',NVL(CPC_CVV2_VERIFICATION_FLAG,'N')),
      NVL(CPC_EXPIRY_DATE_CHECK_FLAG,'N'),
      NVL(CPC_ACCT_BALANCE_CHECK_FLAG,'N'),
      CPC_ACCT_BAL_CHECK_TYPE,
      NVL(CPC_ACCT_BAL_CHECK_VALUE,0),
      NVL(CPC_CONSUMED_FLAG,'N'),
      CPC_CONSUMED_CARD_STAT,
      NVL(CPC_TOKEN_ELIGIBILITY,'N'),
      NVL(CPC_TOKEN_PROVISION_RETRY_MAX,0),
      NVL(CPC_TOKEN_CUST_UPD_DURATION,0)
    INTO
      l_prdcat_kyc_flag,
      P_CVV2_FLAG_OUT,
      l_prdcat_expdate_flag,
      l_prdcat_acct_bal_flag,
      l_prdcat_acct_bal_type,
      l_prdcat_acct_bal_val,
      l_prdcat_consumed_flag,
      l_prdcat_consumed_stat,
      l_TOKEN_ELIGIBILITY,
      L_TOKEN_PROVISION_RETRY_MAX,
      L_TOKEN_CUST_UPD_DURATION
    FROM
      cms_prod_cattype
    WHERE
      cpc_prod_code   = l_prod_code
    AND cpc_card_type = l_card_type
    AND cpc_inst_code =P_INST_CODE_IN;
  EXCEPTION
  WHEN OTHERS THEN
    l_resp_cde := '12';
    l_err_msg  := 'Error while fetching in Product Category details' || SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
  
 
  IF NVL(L_RULE_BYPASS,'N') <> 'Y' THEN
  --EN  Eligibity flag and  Provisioning retry count
   BEGIN
    IF l_provisioning_flag IS NOT NULL AND l_provisioning_flag ='N' THEN
      l_err_msg            :='Velocity Rule Failure';
      l_resp_cde           :='921';
	  l_return_cde:='18';
      RAISE EXP_TOKEN_REJECT_RECORD;
    END IF;
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_resp_cde := '21';
	l_return_cde:='18';
    l_err_msg  := 'Error while Provisioning check '||SUBSTR(SQLERRM,1,200);
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;  
  
 
           -- SN  contact info updation check 
     BEGIN
       SELECT floor(((SYSDATE-CME_CHNG_DATE)*24)*60)
             INTO  L_DURATION_DIFF 
              FROM  cms_mob_email_log
              WHERE cme_inst_code = P_INST_CODE_IN
              AND CME_CUST_CODE = L_CUST_CODE;

       IF  L_DURATION_DIFF < L_TOKEN_CUST_UPD_DURATION THEN
         insert into vms_rulecheck_results(vrr_rrn,vrr_token,vrr_correlation_id,vrr_rule_name,vrr_rule_desc,vrr_rule_result,vrr_execution_time)
              values(P_RRN_IN,P_token_in,p_correlationid_in,'Profile Updates','','FALSE',sysdate);
         l_resp_cde  := '12';
         l_err_msg :='Mobile/Email address has been updated within last '|| L_DURATION_DIFF ||'Minutes';
         RAISE EXP_TOKEN_REJECT_RECORD;
        ELSE 
         
           insert into vms_rulecheck_results(vrr_rrn,vrr_token,vrr_correlation_id,vrr_rule_name,vrr_rule_desc,vrr_rule_result,vrr_execution_time)
              values(P_RRN_IN,P_token_in,p_correlationid_in,'Profile Updates','','TRUE',sysdate);
      END IF;

        EXCEPTION  
         WHEN  EXP_TOKEN_REJECT_RECORD  THEN
           RAISE;
         WHEN NO_DATA_FOUND THEN
            NULL;
         WHEN OTHERS  THEN
             l_resp_cde := '21';
             l_err_msg :='Problem while selecting flag from cms_mob_email_log-'|| SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_TOKEN_REJECT_RECORD;
        END;

  
 BEGIN 
   IF l_prdcat_consumed_flag='N' THEN
    IF l_card_stat=0 THEN
      l_resp_cde    :='916';
      l_err_msg     :='Invalid Card Status';
      l_return_cde:='13';
      RAISE EXP_TOKEN_REJECT_RECORD;
    END IF; 
   ELSIF l_prdcat_consumed_flag='Y' THEN
     IF l_card_stat=0 THEN
      BEGIN 
         insert into vms_rulecheck_results(vrr_rrn,vrr_token,vrr_correlation_id,vrr_rule_name,vrr_rule_desc,vrr_rule_result,vrr_execution_time)
              values(p_rrn_in,p_token_in,p_correlationid_in,'Consumed Status','','FALSE',sysdate);
              
       UPDATE CMS_APPL_PAN SET CAP_CARD_STAT=l_prdcat_consumed_stat WHERE CAP_PAN_CODE= l_hash_pan
        AND cap_inst_code = P_INST_CODE_IN;
        l_resp_cde    :='916';
        l_err_msg     :='Invalid Card Status';
        l_return_cde:='16';
	    p_consumedstat_code_out:=l_prdcat_consumed_stat;
        RAISE EXP_TOKEN_REJECT_RECORD;
         EXCEPTION
        WHEN EXP_TOKEN_REJECT_RECORD THEN
        RAISE;
        WHEN OTHERS THEN
          l_resp_cde := '21';
          l_return_cde:='16';
          l_err_msg  := 'Error while Updating consumed flag '||SUBSTR(SQLERRM,1,200);
          RAISE EXP_TOKEN_REJECT_RECORD;
        END;
    ELSE 
       
         insert into vms_rulecheck_results(vrr_rrn,vrr_token,vrr_correlation_id,vrr_rule_name,vrr_rule_desc,vrr_rule_result,vrr_execution_time)
              values(p_rrn_in,p_token_in,p_correlationid_in,'Consumed Status','','TRUE',sysdate);
        
     END IF;    
    END IF;  
    
    sp_status_check_gpr (P_INST_CODE_IN, P_CARD_NUMBER_IN,
    P_DELIVERY_CHANNEL_IN, l_exp_date, L_card_stat, P_TRAN_CODE_IN,
    P_TRAN_MODE_IN, l_prod_code, l_card_type, P_MSG_TYPE_IN, P_TRAN_DATE_IN,
    P_TRAN_TIME_IN, NULL, --p_international_ind,
    NULL,                 --p_pos_verfication,
    NULL,                 --p_mcc_code,
    l_resp_cde, l_err_msg);
    IF ( (l_resp_cde <> '1' AND l_err_msg <> 'OK') OR
      (
        l_resp_cde <> '0' AND l_err_msg <> 'OK'
      )
      ) then
      l_resp_cde:='916';
      l_err_msg:='Invalid Card Status';
      l_return_cde:='13';
      RAISE EXP_TOKEN_REJECT_RECORD;
    ELSE
      l_status_chk := l_resp_cde;
      l_resp_cde   := '1';
    END IF;
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_resp_cde := '21';
    l_return_cde:='13';
    l_err_msg  := 'Error from GPR Card Status Check ' || SUBSTR (SQLERRM, 1,
    200) || l_resp_cde;
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
  --En GPR Card status check
  IF l_status_chk = '1' THEN
    -- Expiry Check
    BEGIN
      IF TO_DATE (P_TRAN_DATE_IN, 'YYYYMMDD') > LAST_DAY (TO_CHAR (l_exp_date,
        'DD-MON-YY')) THEN
        l_resp_cde := '13';
        l_err_msg  := 'EXPIRED CARD';
        l_return_cde:='13';
        RAISE EXP_TOKEN_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_TOKEN_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_return_cde:='13';
      l_err_msg  := 'ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_TOKEN_REJECT_RECORD;
    END;
  END IF;
  
  --  SN Kyc Status check
IF l_prdcat_kyc_flag='Y' THEN
  BEGIN  
    SELECT
      CCM_KYC_FLAG
    INTO
      L_KYC_FLAG
    FROM
      CMS_CUST_MAST
    WHERE
      CCM_CUST_CODE  =L_CUST_CODE
    AND CCM_INST_CODE=P_INST_CODE_IN;
    IF L_KYC_FLAG NOT IN ('P','O','Y','I') THEN
      l_rule_fail:='Y';
      l_resp_cde    :='917';
      l_err_msg     :='KYC Check failed';
      RAISE EXP_TOKEN_REJECT_RECORD;
    END IF;   
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_resp_cde := '12';
    l_err_msg  :='Error while selecting kyc details'|| SUBSTR (SQLERRM, 1, 200)
    ;
    RAISE EXP_TOKEN_REJECT_RECORD;
  END; 
END IF;
  -- expiry date check
IF l_prdcat_expdate_flag='Y' THEN
  begin
 
    if l_exp_date                   is not null then
    if p_expry_date_in is NULL or   TO_CHAR(l_exp_date,'YYMM') <> P_EXPRY_DATE_IN THEN
     -- IF TO_CHAR(l_exp_date,'YYMM') <> P_EXPRY_DATE_IN THEN
        l_rule_fail:='Y';
        l_resp_cde:= '918';
        l_err_msg:='Incorrect Expiry / CVV2';
        l_return_cde:='14';
        RAISE EXP_TOKEN_REJECT_RECORD;
      END IF;
    END IF;
  
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_resp_cde := '12';
    l_err_msg  := 'Error while checking Expiry date';
    l_return_cde:='14';
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
END IF;
 
  -- SN  Account Balance
  IF l_prdcat_acct_bal_flag='Y' THEN
  BEGIN  
    SELECT
      CAM_ACCT_BAL
    INTO
      l_acct_bal
    FROM
      CMS_ACCT_MAST
    WHERE
      CAM_ACCT_NO    =L_ACCT_NUMBER
    AND CAM_INST_CODE=P_INST_CODE_IN;
    
    IF l_prdcat_acct_bal_type='<' THEN
      IF l_acct_bal   < to_number(l_prdcat_acct_bal_val) THEN
         l_acc_bal_check_fail:='Y';
      END IF;
    ELSIF l_prdcat_acct_bal_type='>' THEN
      IF l_acct_bal   > to_number(l_prdcat_acct_bal_val) THEN
        l_acc_bal_check_fail:='Y';
      END IF;  
    ELSIF l_prdcat_acct_bal_type='=' THEN
      IF l_acct_bal   = to_number(l_prdcat_acct_bal_val) THEN
        l_acc_bal_check_fail:='Y';
      END IF;  
    ELSIF l_prdcat_acct_bal_type='>=' THEN
      IF l_acct_bal   >= to_number(l_prdcat_acct_bal_val) THEN
        l_acc_bal_check_fail:='Y';
      END IF;  
    ELSIF l_prdcat_acct_bal_type='<=' THEN
      IF l_acct_bal   <= to_number(l_prdcat_acct_bal_val) THEN
        l_acc_bal_check_fail:='Y';    
      END IF;
    END IF;  
    
    if l_acc_bal_check_fail='Y' then
      l_rule_fail:='Y';
      l_resp_cde    :='919';
      l_err_msg     :='Card Balance Validation Failure';
      l_return_cde:='15';
      RAISE EXP_TOKEN_REJECT_RECORD;
    END IF;
   
  EXCEPTION
  WHEN EXP_TOKEN_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    l_resp_cde := '12';
     l_return_cde:='15';
    l_err_msg  :='Error while selecting acct balance'|| substr (sqlerrm, 1, 200
   
    );
    RAISE EXP_TOKEN_REJECT_RECORD;
  END;
END IF;
 END IF; 
 
 
  P_RESMSG_OUT   :=l_err_msg;
  p_resp_code_out:=l_resp_cde;
  P_RETURN_CODE_OUT:=l_return_cde;
  p_consumedstat_code_out:=l_prdcat_consumed_stat;
EXCEPTION
WHEN EXP_TOKEN_REJECT_RECORD THEN
  --ROLLBACK;
  IF l_rule_fail='Y' THEN
    IF L_TOKEN_PROVISION_RETRY_MAX = l_provisioning_attempt_cnt+1 THEN
      BEGIN
        UPDATE
          CMS_APPL_PAN
        SET
          CAP_PROVISIONING_FLAG          ='N',
          CAP_PROVISIONING_ATTEMPT_COUNT = NVL(CAP_PROVISIONING_ATTEMPT_COUNT,0)+1
        WHERE
          CAP_INST_CODE  = P_INST_CODE_IN
        AND CAP_PAN_CODE = L_HASH_PAN;
      EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE_OUT := '21';
        P_RESMSG_OUT    :=
        'Exception While updating provisioning count and flag TO N ' ||SUBSTR(
        SQLERRM,1,200);
      END;
    ELSE
      BEGIN
        UPDATE
          CMS_APPL_PAN
        SET
          CAP_PROVISIONING_ATTEMPT_COUNT = NVL(CAP_PROVISIONING_ATTEMPT_COUNT,0)+1
        WHERE
          CAP_INST_CODE  = P_INST_CODE_IN
        AND CAP_PAN_CODE = L_HASH_PAN;
      EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE_OUT := '21';
        P_RESMSG_OUT    :=
        'Exception While updating provisioning count and flag ' ||SUBSTR(
        SQLERRM,1,200);
      END;
    END IF;
  END IF;
    P_RESMSG_OUT   :=l_err_msg;
    p_resp_code_out:=l_resp_cde;
    P_RETURN_CODE_OUT:=l_return_cde;
    p_consumedstat_code_out:=l_prdcat_consumed_stat;
WHEN OTHERS THEN
  P_RESP_CODE_OUT:=l_resp_cde;
  p_resmsg_out := 'Problem while checking preverifications: '||l_err_msg || substr (sqlerrm, 1, 200);
END;

PROCEDURE  AMEXTokenCompleteNotification (
          p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_token_in   		              in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          p_token_type_in   		        in  	varchar2,
          p_token_status_in   		      in  	varchar2,
          p_token_assurance_level_in    in  	varchar2,
          p_token_requester_id_in   	  in  	varchar2,
          p_token_ref_id_in   		      in  	varchar2,
          p_token_expry_date_in         in  	varchar2,
          p_token_pan_ref_id_in         in  	varchar2,
          p_token_wpriskassessment_in   in  	varchar2,
          p_token_wpriskassess_ver_in   in  	varchar2,
          p_token_wpdevice_score_in     in  	varchar2,
          p_token_wpaccount_score_in    in  	varchar2,
          p_token_wpreason_codes_in     in  	varchar2,
          p_token_wppan_source_in       in  	varchar2,
          p_token_wpacct_id_in          in  	varchar2,
          p_token_wpacct_email_in       in  	varchar2,
          p_token_device_type_in        in  	varchar2,
          p_token_device_langcode_in    in  	varchar2,
          p_token_device_id_in          in  	varchar2,
          p_token_device_no_in          in  	varchar2,
          p_token_device_name_in        in  	varchar2,
          p_token_device_loc_in         in  	varchar2,
          p_token_device_ip_in          in  	varchar2,
          p_token_device_secureeleid_in in  	varchar2,
          p_token_riskassess_score_in   in  	varchar2,
          p_token_provisioning_score_in in  	varchar2,
          p_curr_code_in                in    varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_stan_in                     in  	varchar2,
          p_ntw_settl_date              in  	varchar2,
          p_expry_date_in               IN  	VARCHAR2,          
          p_msg_reason_code_in          in    varchar2,
          p_contactless_usage_in        IN  	VARCHAR2,
          p_card_ecomm_usage_in         in  	varchar2,
          p_mob_ecomm_usage_in_in       IN  	VARCHAR2,
          p_wallet_identifier_in        IN  	VARCHAR2,
          p_storage_tech_in             IN  	VARCHAR2,
          p_token_reqid13_in            in  	varchar2,
          p_wp_reqid_in                 in  	varchar2,
          p_wp_convid_in                in  	varchar2,
          p_wallet_id_in                in  	varchar2,
          p_correlation_id_in           in  	varchar2,
          p_payment_appplninstanceid_in in  	varchar2,
          p_req_respcode                in    varchar2,
          p_rsncode_desc                in    varchar2,
          p_auth_id_out                 out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2,
          p_resp_id_out                 OUT 	VARCHAR2 --Added for sending to FSS (VMS-8018)
          )
   IS
      /************************************************************************************************************
          
       * Created by      : Divya Bhaskaran
       * Created For     : AMEX Tokenization 
       * Created Date    : 28-June-2018
       * Reviewer        : Saravankumar
       * Build Number    : VMSR03_B0002
       
       * Modified Date    :  03-Nov-2023
       * Modified By      :  Areshka A.
       * Modified For     :  VMS-8018: Added new out parameter (response id) for sending to FSS
       * Reviewer         :  
       * Build Number     :         
       
      ************************************************************************************************************/
      l_err_msg              VARCHAR2 (500) DEFAULT 'OK';
      l_resp_cde             transactionlog.response_id%TYPE;
      l_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type             transactionlog.txn_type%TYPE;
      l_dr_cr_flag           cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_tran_type            cms_transaction_mast.ctm_tran_type%TYPE;
      l_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_card_type            cms_appl_pan.cap_card_type%TYPE;
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      L_LOGIN_TXN            CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;
      L_LOGDTL_RESP          VARCHAR2 (500);
      L_PREAUTH_TYPE         CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
      EXP_REJECT_RECORD      EXCEPTION;     
      L_CARDPACK_ID          CMS_APPL_PAN.CAP_CARDPACK_ID%TYPE;
      l_customer_id          cms_cust_mast.CCM_CUST_ID%type;
      l_token_status         vms_token_info.vti_token_stat%type;
      
   BEGIN
      l_resp_cde := '1';
      l_err_msg:='OK';
      l_time_stamp := SYSTIMESTAMP;
      BEGIN

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
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
               RAISE exp_reject_record;
         END;
         --End Generate HashKEY

         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   CAP_PRFL_CODE, CAP_EXPRY_DATE, CAP_PROXY_NUMBER,
                   cap_cust_code,ccm_cust_id,CAP_CARDPACK_ID
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   L_PRFL_CODE, L_EXPRY_DATE, L_PROXY_NUMBER,
                   l_cust_code,l_customer_id,L_CARDPACK_ID
              from cms_appl_pan,cms_cust_mast
             where cap_inst_code=ccm_inst_code and cap_cust_code=ccm_cust_code and
             cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan AND cap_mbr_numb='000';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --End Get the card details
 
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
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details '||substr(sqlerrm,1,200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
         --En generate auth id

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
            --FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14';
           l_err_msg  := 'Invalid Card ';
           RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
    
    if trim(p_token_in) is not null and p_req_respcode in ('000','001') then
            
          AMEX_TOKEN_CREATE_UPDATE(P_TOKEN_IN,
          L_HASH_PAN,
          P_TOKEN_TYPE_IN,
          'G',
          P_TOKEN_ASSURANCE_LEVEL_IN,
          P_TOKEN_REQUESTER_ID_IN,
          P_TOKEN_REF_ID_IN,
          P_TOKEN_EXPRY_DATE_IN,
          P_TOKEN_PAN_REF_ID_IN,
          P_TOKEN_WPPAN_SOURCE_IN,
          P_TOKEN_WPRISKASSESSMENT_IN,
          P_TOKEN_WPRISKASSESS_VER_IN,
          P_TOKEN_WPDEVICE_SCORE_IN,
          P_TOKEN_WPACCOUNT_SCORE_IN,
          P_TOKEN_WPREASON_CODES_IN,
          P_TOKEN_WPACCT_ID_IN,
          P_TOKEN_WPACCT_EMAIL_IN,
          P_TOKEN_DEVICE_TYPE_IN,
          P_TOKEN_DEVICE_LANGCODE_IN,
          P_TOKEN_DEVICE_ID_IN  ,
          P_TOKEN_DEVICE_NO_IN,
          P_TOKEN_DEVICE_NAME_IN,
          P_TOKEN_DEVICE_LOC_IN,
          P_TOKEN_DEVICE_IP_IN,
          P_TOKEN_DEVICE_SECUREELEID_IN,
          P_WALLET_IDENTIFIER_IN,
          P_STORAGE_TECH_IN,
          P_TOKEN_RISKASSESS_SCORE_IN,
          P_TOKEN_PROVISIONING_SCORE_IN,
          P_CONTACTLESS_USAGE_IN,
          P_CARD_ECOMM_USAGE_IN,
          P_MOB_ECOMM_USAGE_IN_IN,
          L_ACCT_NUMBER,
          L_CUST_CODE,
          P_INST_CODE_IN,
          P_TOKEN_REQID13_IN,
          P_WP_REQID_IN,
          P_WP_CONVID_IN,
          P_WALLET_ID_IN,
          p_payment_appplninstanceid_in,
          P_WP_CONVID_IN ,
          p_token_status_in,
          L_RESP_CDE,
          l_err_msg
          );
        
        IF L_ERR_MSG <> 'OK' THEN
            RAISE  EXP_REJECT_RECORD; 
        END IF;
         
         END IF;
         
         l_resp_cde := '1';
         l_err_msg := 'OK'; 
         
     EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK ;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK ;
      END;
   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
               AND cms_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               L_ERR_MSG :=
                     'Problem while selecting data from response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
               p_resp_id_out := '69'; --Added for VMS-8018
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
                        NULL,
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
                        0,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        p_rsncode_desc,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_stan_in,
                        p_ntw_settl_date
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            0,
                            null,
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
                            L_LOGDTL_RESP,
                            null,
                            p_req_respcode,
                            p_stan_in
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resp_id_out := '69'; --Added for VMS-8018
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   end AMEXTokenCompleteNotification;
   
   PROCEDURE AMEX_TOKEN_CREATE_UPDATE(
    P_TOKEN_IN                    IN VARCHAR2,
    P_HASH_PAN_IN                 IN VARCHAR2,
    P_TOKEN_TYPE_IN               IN VARCHAR2,
    P_RULE_RESPONSE               IN VARCHAR2,
    P_TOKEN_ASSURANCE_LEVEL_IN    IN VARCHAR2,
    P_TOKEN_REQUESTER_ID_IN       IN VARCHAR2,
    P_TOKEN_REF_ID_IN             IN VARCHAR2,
    P_TOKEN_EXPRY_DATE_IN         IN VARCHAR2,
    P_TOKEN_PAN_REF_ID_IN         IN VARCHAR2,
    P_TOKEN_WPPAN_SOURCE_IN       IN VARCHAR2,
    P_TOKEN_WPRISKASSESSMENT_IN   IN VARCHAR2,
    P_TOKEN_WPRISKASSESS_VER_IN   IN VARCHAR2,
    P_TOKEN_WPDEVICE_SCORE_IN     IN VARCHAR2,
    P_TOKEN_WPACCOUNT_SCORE_IN    IN VARCHAR2 ,
    P_TOKEN_WPREASON_CODES_IN     IN VARCHAR2,
    P_TOKEN_WPACCT_ID_IN          IN VARCHAR2,
    P_TOKEN_WPACCT_EMAIL_IN       IN VARCHAR2,
    P_TOKEN_DEVICE_TYPE_IN        IN VARCHAR2,
    P_TOKEN_DEVICE_LANGCODE_IN    IN VARCHAR2,
    P_TOKEN_DEVICE_ID_IN          IN VARCHAR2,
    P_TOKEN_DEVICE_NO_IN          IN VARCHAR2,
    P_TOKEN_DEVICE_NAME_IN        IN VARCHAR2,
    P_TOKEN_DEVICE_LOC_IN         IN VARCHAR2,
    P_TOKEN_DEVICE_IP_IN          IN VARCHAR2,
    P_TOKEN_DEVICE_SECUREELEID_IN IN VARCHAR2,
    P_WALLET_IDENTIFIER_IN        IN VARCHAR2,
    P_STORAGE_TECH_IN             IN VARCHAR2,
    P_TOKEN_RISKASSESS_SCORE_IN   IN VARCHAR2,
    P_TOKEN_PROVISIONING_SCORE_IN IN VARCHAR2,
    P_CONTACTLESS_USAGE_IN        IN VARCHAR2,
    P_CARD_ECOMM_USAGE_IN         IN VARCHAR2,
    P_MOB_ECOMM_USAGE_IN_IN       IN VARCHAR2,
    P_ACCT_NUMBER_IN              IN VARCHAR2,
    P_CUST_CODE_IN                IN VARCHAR2,
    P_INST_CODE_IN                IN VARCHAR2,
    P_TOKEN_REQID13_IN            IN VARCHAR2,
    P_WP_REQID_IN                 IN VARCHAR2,
    P_WP_CONVID_IN                IN VARCHAR2,
    P_WALLET_ID_IN                IN VARCHAR2,
    p_payment_appplninstanceid_in IN VARCHAR2,
    p_de62_uid_in                 IN VARCHAR2,
    p_token_stat_in               IN VARCHAR2,
    P_RESP_CDE_OUT                OUT VARCHAR2,
    P_resp_MSG_OUT                OUT VARCHAR2)
IS
  l_DE62_003_TOKENREQUESTORID      vms_de62_dtl.VDD_DE62_003_TOKENREQUESTORID%TYPE;
  l_DE62_013_TOKENREQUESTORID      vms_de62_dtl.VDD_DE62_013_TOKENREQUESTORID%TYPE;
  l_DE62_014_WPREQUESTID           vms_de62_dtl.VDD_DE62_014_WPREQUESTID%TYPE;
  l_DE62_015_WPCONVERSIONID        vms_de62_dtl.VDD_DE62_015_WPCONVERSIONID%TYPE;
  l_DE62_031_DEVICETYPE            vms_de62_dtl.VDD_DE62_031_DEVICETYPE%TYPE;
  l_DE62_032_DEVICELANGCDE         vms_de62_dtl.VDD_DE62_032_DEVICELANGCDE%TYPE;
  l_DE62_033_DEVICEID              vms_de62_dtl.VDD_DE62_033_DEVICEID%TYPE;
  l_DE62_034_DEVICENUMBER          vms_de62_dtl.VDD_DE62_034_DEVICENUMBER%TYPE;
  l_DE62_035_DEVICENAME            vms_de62_dtl.VDD_DE62_035_DEVICENAME%TYPE;
  l_DE62_036_DEVICELOCATION        vms_de62_dtl.VDD_DE62_036_DEVICELOCATION%TYPE;
  l_DE62_037_IPADDRESS             vms_de62_dtl.VDD_DE62_037_IPADDRESS%TYPE;
  l_DE62_038_SECUREELEMENTID       vms_de62_dtl.VDD_DE62_038_SECUREELEMENTID%TYPE;
  l_de62_039_walletidentifier      vms_de62_dtl.vdd_de62_039_walletidentifier%type;
  l_DE62_041_WPRISKASSMENT         vms_de62_dtl.VDD_DE62_041_WPRISKASSESSMENT%type;
  l_DE62_042_WPRISKASSMENTVER      vms_de62_dtl.VDD_DE62_042_WPRISKASSMENTVER%TYPE;
  l_DE62_043_WPDEVICESCORE         vms_de62_dtl.VDD_DE62_043_WPDEVICESCORE%TYPE;
  l_DE62_044_WPACCOUNTSCORE        vms_de62_dtl.VDD_DE62_044_WPACCOUNTSCORE%TYPE;
  l_DE62_045_WPREASONCODES         vms_de62_dtl.VDD_DE62_045_WPREASONCODES%TYPE;
  l_DE62_046_ACCOUNTEMAILADDR      vms_de62_dtl.VDD_DE62_046_ACCOUNTEMAILADDR%TYPE;
  l_de62_074_walletid              vms_de62_dtl.vdd_de62_074_walletid%type;
  l_de62_075_storagetechnology     vms_de62_dtl.vdd_de62_075_storagetechnology%type;
  l_de62_046_accountemailid        vms_de62_dtl.vdd_de62_046_accountemailid%type;
  l_DE62_007_TOKENTYPE             vms_de62_dtl.vdd_DE62_007_TOKENTYPE%type;
  L_DE62_066_PANSOURCE             VMS_DE62_DTL.VDD_DE62_066_PANSOURCE%TYPE;
  L_DE62_068_WPACCOUNTID           VMS_DE62_DTL.VDD_DE62_068_WPACCOUNTID%TYPE;
  l_DE62_077_PAYAPPLID             vms_de62_dtl.VDD_DE62_077_PAYAPPLID%type;
  
       /************************************************************************************************************
	  
	     * Created by      : Divya Bhaskaran
       * Created Date    : 28-June-2018
       * Created reason  : AMEX Tokenization
       * Reviewer        : Saravankumar
       * Build Number    : VMSR03_B0002
       
      ************************************************************************************************************/
BEGIN
      P_RESP_MSG_OUT:='OK';
      P_RESP_CDE_OUT :='1';
  BEGIN
    SELECT
      vdd_de62_003_tokenrequestorid,
      vdd_de62_013_tokenrequestorid,
      VDD_DE62_014_WPREQUESTID,
      VDD_DE62_015_WPCONVERSIONID,
      VDD_DE62_031_DEVICETYPE,
      VDD_DE62_032_DEVICELANGCDE,
      VDD_DE62_033_DEVICEID,
      VDD_DE62_034_DEVICENUMBER,
      VDD_DE62_035_DEVICENAME,
      VDD_DE62_036_DEVICELOCATION,
      VDD_DE62_037_IPADDRESS,
      VDD_DE62_038_SECUREELEMENTID,
      vdd_de62_039_walletidentifier,
      VDD_DE62_041_WPRISKASSESSMENT,
      VDD_DE62_042_WPRISKASSMENTVER,
      VDD_DE62_043_WPDEVICESCORE,
      VDD_DE62_044_WPACCOUNTSCORE,
      VDD_DE62_045_WPREASONCODES,
      vdd_de62_046_accountemailaddr,
      vdd_DE62_046_ACCOUNTEMAILID,
      vdd_de62_074_walletid,
      vdd_de62_075_storagetechnology,
      vdd_de62_007_tokentype,
      VDD_DE62_066_PANSOURCE,
      VDD_DE62_068_WPACCOUNTID,
      vdd_de62_077_payapplid
    INTO
      l_de62_003_tokenrequestorid,
      l_DE62_013_TOKENREQUESTORID,
      l_DE62_014_WPREQUESTID,
      l_DE62_015_WPCONVERSIONID,
      l_DE62_031_DEVICETYPE,
      l_DE62_032_DEVICELANGCDE,
      l_DE62_033_DEVICEID,
      l_DE62_034_DEVICENUMBER,
      l_de62_035_devicename,
      l_DE62_036_DEVICELOCATION,
      l_DE62_037_IPADDRESS,
      l_DE62_038_SECUREELEMENTID,
      l_de62_039_walletidentifier,
      l_DE62_041_WPRISKASSMENT,
      l_DE62_042_WPRISKASSMENTVER,
      l_DE62_043_WPDEVICESCORE,
      l_DE62_044_WPACCOUNTSCORE,
      l_DE62_045_WPREASONCODES,
      l_de62_046_accountemailaddr,
      l_DE62_046_ACCOUNTEMAILID,
      l_DE62_074_WALLETID,
      l_de62_075_storagetechnology,
      l_de62_007_tokentype,
      l_de62_066_pansource,
      L_DE62_068_WPACCOUNTID,
      l_de62_077_payapplid
    FROM
      vms_de62_dtl
    WHERE
      vdd_de62_id    =p_de62_uid_in
    AND vdd_pan_code =P_HASH_PAN_IN;
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END;
  BEGIN
    MERGE INTO VMS_TOKEN_INFO 
                    USING (SELECT trim(p_token_in) token,P_HASH_PAN_IN pan FROM dual) a
                    ON ( VTI_TOKEN       =token  AND vti_token_pan =pan)
                    WHEN MATCHED THEN  
                    UPDATE SET    
      VTI_TOKEN_TYPE=COALESCE(VTI_TOKEN_TYPE,P_TOKEN_TYPE_IN,
      l_DE62_007_TOKENTYPE),
      VTI_TOKEN_STAT =nvl(p_token_stat_in,VTI_TOKEN_STAT),
      vti_token_assurance_level=NVL(vti_token_assurance_level,
      p_token_assurance_level_in),
      VTI_TOKEN_REQUESTOR_ID=COALESCE(VTI_TOKEN_REQUESTOR_ID,
      p_token_requester_id_in,l_de62_003_tokenrequestorid),
      vti_de62013_tokenrequestorid=COALESCE(vti_de62013_tokenrequestorid,
      p_token_reqid13_in,l_de62_013_tokenrequestorid),
      vti_de62013_wprequestid=COALESCE(vti_de62013_wprequestid,p_wp_reqid_in,
      l_de62_014_wprequestid),
      vti_de62013_wpconversionid=COALESCE(vti_de62013_wpconversionid,
      p_wp_convid_in,l_de62_015_wpconversionid),
      vti_de62054_walletid=COALESCE(vti_de62054_walletid,p_wallet_id_in,
      l_de62_074_walletid),
      vti_storage_technology=COALESCE(vti_storage_technology,p_storage_tech_in,
      l_de62_075_storagetechnology),
      vti_token_device_type=COALESCE(vti_token_device_type,
      p_token_device_type_in,l_de62_031_devicetype),
      vti_token_device_langcode=COALESCE(vti_token_device_langcode,
      p_token_device_langcode_in,l_de62_032_devicelangcde),
      vti_token_device_id=COALESCE(vti_token_device_id,p_token_device_id_in,
      l_de62_033_deviceid),
      vti_token_device_no=COALESCE(vti_token_device_no,p_token_device_no_in,
      l_de62_034_devicenumber),
      vti_token_device_name=COALESCE(vti_token_device_name,
      p_token_device_name_in,l_de62_035_devicename),
      vti_token_device_loc=COALESCE(vti_token_device_loc,p_token_device_loc_in,
      l_de62_036_devicelocation),
      vti_token_device_ip=COALESCE(vti_token_device_ip,p_token_device_ip_in,
      l_de62_037_ipaddress),
      vti_token_device_secureeleid=COALESCE(vti_token_device_secureeleid,
      p_token_device_secureeleid_in,l_de62_038_secureelementid),
      vti_wallet_identifier=COALESCE(vti_wallet_identifier,
      p_wallet_identifier_in,l_de62_039_walletidentifier),
      vti_token_wpriskassessment=COALESCE(vti_token_wpriskassessment,
      p_token_wpriskassessment_in,l_DE62_041_WPRISKASSMENT),
      VTI_TOKEN_WPRISKASSESSMENT_VER=COALESCE(VTI_TOKEN_WPRISKASSESSMENT_VER,
      p_token_wpriskassess_ver_in,l_de62_042_wpriskassmentver),
      vti_token_wpdevice_score=COALESCE(vti_token_wpdevice_score,
      p_token_wpdevice_score_in,l_de62_043_wpdevicescore),
      vti_token_wpaccount_score=COALESCE(vti_token_wpaccount_score,
      p_token_wpaccount_score_in,l_de62_044_wpaccountscore),
      vti_token_wpreason_codes=COALESCE(vti_token_wpreason_codes,
      p_token_wpreason_codes_in,l_de62_045_wpreasoncodes),
      vti_token_wpacct_email=COALESCE(vti_token_wpacct_email,
      p_token_wpacct_email_in,l_de62_046_accountemailaddr),
      vti_token_wpacct_id=COALESCE(vti_token_wpacct_id,p_token_wpacct_id_in,
      l_DE62_068_WPACCOUNTID),
      VTI_TOKEN_REF_ID      =NVL(VTI_TOKEN_REF_ID,p_token_ref_id_in),
      VTI_TOKEN_EXPIRY_DATE =NVL(VTI_TOKEN_EXPIRY_DATE,p_token_expry_date_in),
      VTI_TOKEN_PAN_REF_ID  =NVL(VTI_TOKEN_PAN_REF_ID,p_token_pan_ref_id_in) ,
      vti_token_wppan_source=COALESCE(vti_token_wppan_source,
      p_token_wppan_source_in,l_de62_066_pansource),
      VTI_TOKEN_RISKASSESSMENT_SCORE=NVL(VTI_TOKEN_RISKASSESSMENT_SCORE,
      p_token_riskassess_score_in),
      VTI_TOKEN_PROVISIONING_SCORE=NVL(VTI_TOKEN_PROVISIONING_SCORE,
      p_token_provisioning_score_in),
      VTI_CONTACTLESS_USAGE     =NVL(VTI_CONTACTLESS_USAGE,p_contactless_usage_in),
      VTI_CARD_ECOMM_USAGE      =NVL(VTI_CARD_ECOMM_USAGE,p_card_ecomm_usage_in),
      vti_mob_wallet_ecomm_usage=NVL(vti_mob_wallet_ecomm_usage,
      p_mob_ecomm_usage_in_in),
      VTI_ACCT_NO                =NVL(VTI_ACCT_NO,P_ACCT_NUMBER_IN),
      VTI_CUST_CODE              =NVL(VTI_CUST_CODE,P_CUST_CODE_IN),
      VTI_INST_CODE              =NVL(VTI_INST_CODE,P_INST_CODE_IN),
      VTI_INS_DATE               =NVL(VTI_INS_DATE,SYSDATE),
      VTI_LUPD_DATE              =sysdate,
      vti_paymentappln_instanceid=COALESCE(vti_paymentappln_instanceid,
      p_payment_appplninstanceid_in,l_de62_077_payapplid),
      VTI_TOKEN_ACTIVE_DATE=case when VTI_TOKEN_STAT<>'A' and p_token_stat_in='A' then
                               sysdate else VTI_TOKEN_ACTIVE_DATE end,
      VTI_DE62_CORRELATION_ID=p_de62_uid_in
    WHEN NOT MATCHED THEN
   INSERT  (
        VTI_TOKEN,
        VTI_TOKEN_PAN,
        VTI_TOKEN_TYPE,
        VTI_TOKEN_STAT,
        VTI_TOKEN_ASSURANCE_LEVEL,
        VTI_TOKEN_REQUESTOR_ID,
        VTI_TOKEN_REF_ID,
        VTI_TOKEN_EXPIRY_DATE,
        VTI_TOKEN_PAN_REF_ID ,
        VTI_TOKEN_WPPAN_SOURCE ,
        VTI_TOKEN_WPRISKASSESSMENT,
        vti_token_wpriskassessment_ver,
        vti_token_wpdevice_score,
        vti_token_wpaccount_score,
        vti_token_wpreason_codes,
        vti_token_wpacct_id ,
        vti_token_wpacct_email,
        VTI_TOKEN_DEVICE_TYPE ,
        VTI_TOKEN_DEVICE_LANGCODE ,
        VTI_TOKEN_DEVICE_ID ,
        VTI_TOKEN_DEVICE_NO ,
        VTI_TOKEN_DEVICE_NAME ,
        VTI_TOKEN_DEVICE_LOC ,
        VTI_TOKEN_DEVICE_IP ,
        vti_token_device_secureeleid ,
        VTI_WALLET_IDENTIFIER,
        VTI_STORAGE_TECHNOLOGY,
        VTI_TOKEN_RISKASSESSMENT_SCORE ,
        VTI_TOKEN_PROVISIONING_SCORE ,
        VTI_CONTACTLESS_USAGE,
        VTI_CARD_ECOMM_USAGE,
        VTI_MOB_WALLET_ECOMM_USAGE,
        VTI_ACCT_NO,
        VTI_CUST_CODE,
        VTI_INST_CODE,
        vti_ins_date,
        VTI_LUPD_DATE ,
        vti_de62013_tokenrequestorid ,
        vti_de62013_wprequestid ,
        VTI_de62013_wpconversionid ,
        VTI_DE62054_WALLETID,
        VTI_PAYMENTAPPLN_INSTANCEID,
        VTI_TOKEN_ACTIVE_DATE,
	VTI_DE62_CORRELATION_ID
      )
      VALUES
      (
        trim(p_token_in) ,
        P_HASH_PAN_IN ,
        NVL( P_TOKEN_TYPE_IN,l_DE62_007_TOKENTYPE) ,
        p_token_stat_in,
        p_token_assurance_level_in ,
        NVL(p_token_requester_id_in,l_de62_003_tokenrequestorid) ,
        p_token_ref_id_in ,
        p_token_expry_date_in ,
        p_token_pan_ref_id_in ,
        NVL(p_token_wppan_source_in,l_de62_066_pansource) ,
        NVL(p_token_wpriskassessment_in,l_DE62_041_WPRISKASSMENT),
        NVL(p_token_wpriskassess_ver_in,l_de62_042_wpriskassmentver),
        NVL(p_token_wpdevice_score_in,l_DE62_043_WPDEVICESCORE),
        NVL(p_token_wpaccount_score_in,l_de62_044_wpaccountscore),
        NVL(p_token_wpreason_codes_in,l_de62_045_wpreasoncodes),
        NVL( p_token_wpacct_id_in,l_DE62_068_WPACCOUNTID),
        NVL(p_token_wpacct_email_in ,l_de62_046_accountemailaddr),
        NVL(p_token_device_type_in ,l_de62_031_devicetype) ,
        NVL(p_token_device_langcode_in ,l_de62_032_devicelangcde) ,
        NVL(p_token_device_id_in,l_de62_033_deviceid) ,
        NVL(p_token_device_no_in ,l_de62_034_devicenumber) ,
        NVL(p_token_device_name_in ,l_de62_035_devicename) ,
        NVL(p_token_device_loc_in ,l_de62_036_devicelocation) ,
        NVL(p_token_device_ip_in ,l_de62_037_ipaddress) ,
        NVL(p_token_device_secureeleid_in ,l_de62_038_secureelementid) ,
        NVL(p_wallet_identifier_in,l_DE62_039_WALLETIDENTIFIER),
        NVL(p_storage_tech_in,l_DE62_075_STORAGETECHNOLOGY),
        p_token_riskassess_score_in ,
        p_token_provisioning_score_in ,
        p_contactless_usage_in,
        p_card_ecomm_usage_in,
        p_mob_ecomm_usage_in_in,
        P_ACCT_NUMBER_IN,
        P_CUST_CODE_IN,
        p_inst_code_in,
        sysdate,
        sysdate ,
        NVL(p_token_reqid13_in,l_de62_013_tokenrequestorid) ,
        NVL(p_wp_reqid_in,l_de62_014_wprequestid) ,
        NVL(p_wp_convid_in,l_de62_015_wpconversionid) ,
        NVL(p_wallet_id_in,l_DE62_074_WALLETID),
        NVL(p_payment_appplninstanceid_in,l_DE62_077_PAYAPPLID),
        DECODE(p_token_stat_in,'A',sysdate),
	p_de62_uid_in
      );	
 exception
  WHEN OTHERS THEN
    P_resp_CDE_OUT := '21';
    P_resp_MSG_OUT := 'Error While inserting VMS_TOKEN_INFO  ' || SUBSTR (
    SQLERRM, 1, 200);
  END;
END;

  PROCEDURE   AVS_CHECK (
                         P_INST_CODE_IN             IN    NUMBER,
                         P_PROD_CODE_IN             IN    VARCHAR2,
                         P_PROD_CATG_IN             IN    VARCHAR2,
                         P_ZIP_CODE_IN              IN    VARCHAR2,
                         P_ADDRVRIFY_FLAG_IN        IN    VARCHAR2,
                         P_NETWORKID_SWITCH_IN      IN    VARCHAR2,
                         P_CAP_CUST_CODE_IN         IN    VARCHAR2,
                         P_CUST_ADDR_IN             IN    VARCHAR2,
                         P_RESP_CODE_OUT            OUT   VARCHAR2,
                         P_RESP_MSG_OUT             OUT   VARCHAR2,
                         P_ADDR_VERFY_RESPONSE_OUT  OUT VARCHAR2
                         ) IS
       
  L_RESP_CDE                        CMS_RESPONSE_MAST.cms_response_id%type;      
  L_ZIP_CODE_TRIMMED                CMS_ADDR_MAST.cam_pin_code%type;
  L_ADDRVERIFICATION_FLAG           TRANSACTIONLOG.ADDR_VERIFY_INDICATOR%TYPE;
  L_ADDRVRIFY_FLAG                  CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_CHECK%TYPE;
  L_ENCRYPT_ENABLE                  CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  L_ADDR_ONE                        CMS_ADDR_MAST.CAM_ADD_ONE%type;
  L_ADDR_TWO                        CMS_ADDR_MAST.CAM_ADD_TWO%type;
  L_REMOVESPACECHAR_ADDRONECUST     CMS_ADDR_MAST.CAM_ADD_ONE%type;
  L_REMOVESPACE_TXN                 CMS_ADDR_MAST.cam_pin_code%type;
  L_REMOVESPACE_CUST                CMS_ADDR_MAST.cam_pin_code%type; 
  L_FIRST3_CUSTZIP                  CMS_ADDR_MAST.cam_pin_code%type; 
  L_NUMERIC_ZIP                     CMS_ADDR_MAST.cam_pin_code%type;
  L_ZIP_CODE                        CMS_ADDR_MAST.cam_pin_code%type;
  L_REMOVESPACENUM_TXN              CMS_ADDR_MAST.cam_pin_code%type;
  L_REMOVESPACENUM_CUST             CMS_ADDR_MAST.cam_pin_code%type;
  L_REMOVESPACECHAR_TXN             CMS_ADDR_MAST.cam_pin_code%type;
  L_REMOVESPACECHAR_CUST            CMS_ADDR_MAST.cam_pin_code%type;
  L_ADDRVERIFY_RESP                 CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_RESPONSE%TYPE;
  L_INPUTZIP_LENGTH                 NUMBER; 
  L_TXN_NONNUMERIC_CHK              VARCHAR2 (2);  
  L_CUST_NONNUMERIC_CHK             VARCHAR2 (2); 
  L_REMOVESPACE_ADDRCUST            VARCHAR2(100);
  L_REMOVESPACE_ADDRTXN             VARCHAR2(100);
  L_REMOVESPACECHAR_ADDRCUST        VARCHAR2(100);
  L_REMOVESPACECHAR_ADDRTXN         VARCHAR2(20);
  L_ADDR_VERFY                      NUMBER;
  L_ERR_MSG                         VARCHAR2(900) := 'OK';
  
  EXP_REJECT_RECORD EXCEPTION;
  
  /************************************************************************************************************
	  
	     * Created by      : MAGESH KUMAR.S
       * Created Date    : 09-JULY-2018
       * Created reason  : AMEX Tokenization
       * Reviewer        : Saravanakumar
       * Build Number    : VMSR03_B0004
       
      ************************************************************************************************************/
  
 BEGIN
 
    BEGIN
  
      SELECT  CPC_ADDR_VERIFICATION_CHECK, 
              CPC_ENCRYPT_ENABLE,
              NVL(CPC_ADDR_VERIFICATION_RESPONSE, 'U')
         INTO  L_ADDRVRIFY_FLAG, 
               L_ENCRYPT_ENABLE,
               L_ADDRVERIFY_RESP
         FROM CMS_PROD_CATTYPE
        WHERE CPC_INST_CODE = P_INST_CODE_IN AND
              CPC_PROD_CODE = P_PROD_CODE_IN AND
              CPC_CARD_TYPE =  P_PROD_CATG_IN;
  
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
         L_ADDRVRIFY_FLAG    := 'Y';
       WHEN OTHERS THEN
  
         L_RESP_CDE := '21';
         L_ERR_MSG  := 'Error while selecting Product Category level Configuration' || SUBSTR(SQLERRM,1,200);
         RAISE EXP_REJECT_RECORD;
  
      END;

     L_ZIP_CODE_TRIMMED:=TRIM(P_ZIP_CODE_IN); 


     IF UPPER (TRIM (P_NETWORKID_SWITCH_IN)) = 'VISANET' and
                                TRIM (P_ADDRVRIFY_FLAG_IN) IS NULL and TRIM (P_ZIP_CODE_IN) IS NOT NULL  THEN
          L_ADDRVERIFICATION_FLAG :='2';
     ELSE
          L_ADDRVERIFICATION_FLAG :=P_ADDRVRIFY_FLAG_IN;
     END IF;

        IF L_ADDRVRIFY_FLAG = 'Y' AND L_ADDRVERIFICATION_FLAG in('2','3') then

            if P_ZIP_CODE_IN is null then --tag not present
                    L_RESP_CDE := '105';
                    L_ERR_MSG  := 'Required Property Not Present : ZIP';
                    RAISE EXP_REJECT_RECORD;

            ELSIF trim(P_ZIP_CODE_IN) is null then   --tag present but value empty or space

               P_ADDR_VERFY_RESPONSE_OUT := 'U';

        ELSE

           BEGIN

          SELECT decode(L_ENCRYPT_ENABLE,'Y', fn_dmaps_main(CAM_PIN_CODE),CAM_PIN_CODE),
					trim(decode(L_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_one),cam_add_one)),
					trim(decode(L_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_two),cam_add_two))
				INTO 
					L_ZIP_CODE,
					L_ADDR_ONE,
					L_ADDR_TWO
                FROM CMS_ADDR_MAST
                WHERE CAM_INST_CODE = P_INST_CODE_IN AND CAM_CUST_CODE = P_CAP_CUST_CODE_IN
                AND CAM_ADDR_FLAG = 'P';

                   L_FIRST3_CUSTZIP := SUBSTR(L_ZIP_CODE,1,3);

             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   L_RESP_CDE := '21';
                   L_ERR_MSG  := 'No data found in CMS_ADDR_MAST ' ;
                   RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
                   L_RESP_CDE := '21';
                   L_ERR_MSG  := 'Error while seelcting CMS_ADDR_MAST ' ||SUBSTR(SQLERRM, 1, 200);
                   RAISE EXP_REJECT_RECORD;
             END;

             SELECT REGEXP_instr(P_ZIP_CODE_IN,'([A-Z,a-z])') 
             into L_TXN_NONNUMERIC_CHK
             FROM dual;

             SELECT REGEXP_instr(L_ZIP_CODE,'([A-Z,a-z])') 
             into L_CUST_NONNUMERIC_CHK
             FROM dual;

                if  L_TXN_NONNUMERIC_CHK = '0' and L_CUST_NONNUMERIC_CHK = '0' then -- It Means txn and cust zip code is numeric

                    IF SUBSTR (L_ZIP_CODE_TRIMMED, 1, 5) = SUBSTR (L_ZIP_CODE, 1, 5) then 
                           P_ADDR_VERFY_RESPONSE_OUT := 'W';
                    else
                           P_ADDR_VERFY_RESPONSE_OUT := 'N';
                    end if;

                elsif L_TXN_NONNUMERIC_CHK <> '0' and L_CUST_NONNUMERIC_CHK = '0' then -- It Means txn zip code is aplhanumeric and cust zip code is numeric

                    if  L_ZIP_CODE_TRIMMED = L_ZIP_CODE then
                          P_ADDR_VERFY_RESPONSE_OUT := 'W';
                    else
                          P_ADDR_VERFY_RESPONSE_OUT := 'N';
                    end if;

                elsif L_TXN_NONNUMERIC_CHK = '0' and L_CUST_NONNUMERIC_CHK <> '0' then -- It Means txn zip code is numeric and cust zip code is alphanumeric

                    SELECT REGEXP_REPLACE(L_ZIP_CODE,'([A-Z ,a-z ])', '') into L_NUMERIC_ZIP FROM dual;

                    if  L_ZIP_CODE_TRIMMED = L_NUMERIC_ZIP then

                          P_ADDR_VERFY_RESPONSE_OUT := 'W';
                    else
                          P_ADDR_VERFY_RESPONSE_OUT := 'N';
                    end if;

                elsif L_TXN_NONNUMERIC_CHK <> '0' and L_CUST_NONNUMERIC_CHK <> '0' then -- It Means txn zip code and cust zip code is alphanumeric

                     L_INPUTZIP_LENGTH := length(p_zip_code_IN);

                     if L_INPUTZIP_LENGTH = length(L_ZIP_CODE) then  -- both txn and cust zip length is equal

                         if  L_ZIP_CODE_TRIMMED = L_ZIP_CODE then

                                 P_ADDR_VERFY_RESPONSE_OUT := 'W';
                           else
                                 P_ADDR_VERFY_RESPONSE_OUT := 'N';

                           end if;

                      else

                 SELECT REGEXP_REPLACE(p_zip_code_IN,'([ ])', '') into L_REMOVESPACE_TXN from dual;
                 
                 SELECT REGEXP_REPLACE(L_ZIP_CODE,'([ ])', '') into L_REMOVESPACE_CUST from dual;

                if L_REMOVESPACE_TXN =  L_REMOVESPACE_CUST then

                    P_ADDR_VERFY_RESPONSE_OUT := 'W';
                    
                elsif length(L_REMOVESPACE_TXN) >=3 then 

                if substr(L_REMOVESPACE_TXN,1,3) = substr(L_REMOVESPACE_CUST,1,3) then  

                    P_ADDR_VERFY_RESPONSE_OUT := 'W';
					 
                  ELSIF L_INPUTZIP_LENGTH >= 6 THEN 
                                                
                         select REGEXP_REPLACE (P_ZIP_CODE_IN, '([0-9 ])', '')
                          INTO L_REMOVESPACENUM_TXN
                          FROM DUAL;

                         select REGEXP_REPLACE (L_ZIP_CODE, '([0-9 ])', '')
                          into L_REMOVESPACENUM_CUST
                          FROM DUAL;

                         select REGEXP_REPLACE (P_ZIP_CODE_IN, '([a-zA-Z ])', '')
                          INTO L_REMOVESPACECHAR_TXN
                          FROM DUAL;

                         select REGEXP_REPLACE (L_ZIP_CODE, '([a-zA-Z ])', '')
                          into L_REMOVESPACECHAR_CUST
                          FROM DUAL;
                            
                          IF SUBSTR (L_REMOVESPACENUM_TXN, 1, 3) =
                                  SUBSTR (L_REMOVESPACENUM_CUST, 1, 3)
                          then                     --Added for defect : 13297 on 26/12/13
                              P_ADDR_VERFY_RESPONSE_OUT := 'W';
                          ELSIF  SUBSTR (L_REMOVESPACECHAR_TXN, 1, 3) =
                                  SUBSTR (L_REMOVESPACECHAR_CUST, 1, 3)
                                  then
                                  P_ADDR_VERFY_RESPONSE_OUT := 'W';
                          ELSE
                              P_ADDR_VERFY_RESPONSE_OUT := 'N';
                          end if;
                            
                 else
                          P_ADDR_VERFY_RESPONSE_OUT := 'N';

                 end if;


                  else  
                  
                  P_ADDR_VERFY_RESPONSE_OUT := 'N'; 

               end if;
               
               end if;
               
       else
             P_ADDR_VERFY_RESPONSE_OUT := 'N';
             
      end if;

      end if;

    ELSE

         IF L_ADDRVERIFICATION_FLAG in('2','3') THEN

           P_ADDR_VERFY_RESPONSE_OUT := L_ADDRVERIFY_RESP;

         ELSE

           P_ADDR_VERFY_RESPONSE_OUT := 'NA';

         END IF;

    END IF;

        

      select REGEXP_REPLACE (L_ADDR_ONE||L_ADDR_TWO,'[^[:digit:]]')
           INTO L_REMOVESPACECHAR_ADDRCUST
          FROM DUAL;

        select REGEXP_REPLACE (L_ADDR_ONE,'[^[:digit:]]')
           into L_REMOVESPACECHAR_ADDRONECUST
          FROM DUAL;

        select REGEXP_REPLACE (P_CUST_ADDR_IN,'[^[:digit:]]')
             INTO L_REMOVESPACECHAR_ADDRTXN
             from DUAL;

          SELECT REGEXP_REPLACE (P_CUST_ADDR_IN, '([ ])', '')
           INTO L_REMOVESPACE_ADDRTXN
           from DUAL;
           
          SELECT REGEXP_REPLACE (L_ADDR_ONE||L_ADDR_TWO, '([ ])', '')
           INTO L_REMOVESPACE_ADDRCUST
           from DUAL;
           
  IF L_ADDRVRIFY_FLAG = 'Y' then
  
    if(P_ADDR_VERFY_RESPONSE_OUT  ='W') then

      if(L_REMOVESPACE_ADDRCUST is not null) then

		if(L_REMOVESPACE_ADDRCUST=SUBSTR(L_REMOVESPACE_ADDRTXN,1,length(L_REMOVESPACE_ADDRCUST))) then
     
			L_ADDR_VERFY:=1;
     
		elsif(L_REMOVESPACECHAR_ADDRCUST=L_REMOVESPACECHAR_ADDRTXN) then
			L_ADDR_VERFY:=1;
        
		ELSIF(L_REMOVESPACECHAR_ADDRONECUST=L_REMOVESPACECHAR_ADDRTXN) then
			L_ADDR_VERFY:=1;
        
	  else
		L_ADDR_VERFY:=-1;
		
	end if;


        IF(L_ADDR_VERFY          =1) THEN
          P_ADDR_VERFY_RESPONSE_OUT := 'Y';
        ELSE
          P_ADDR_VERFY_RESPONSE_OUT := 'Z';
        END IF;
        ELSE
        P_ADDR_VERFY_RESPONSE_OUT := 'Z';
        end if;
		
    END IF;
	
      if (UPPER (TRIM(P_NETWORKID_SWITCH_IN)) = 'BANKNET' and P_ADDR_VERFY_RESPONSE_OUT = 'Y') then
          P_ADDR_VERFY_RESPONSE_OUT := 'Z';
      end if;
	  
end if;

      P_RESP_MSG_OUT :=L_ERR_MSG;
      Exception
      when EXP_REJECT_RECORD then
      P_RESP_MSG_OUT :=L_ERR_MSG;
      
End;
PROCEDURE AMEXTokenEventNotification(
    p_inst_code_in        IN NUMBER,
    p_msg_type_in         IN VARCHAR2,
    p_rrn_in              IN VARCHAR2,
    p_delivery_channel_in IN VARCHAR2,
    p_txn_code_in         IN VARCHAR2,
    p_txn_mode_in         IN VARCHAR2,
    p_tran_date_in        IN VARCHAR2,
    p_tran_time_in        IN VARCHAR2,
    p_tran_amt_in         IN VARCHAR2,
    p_rvsl_code_in        IN VARCHAR2,
    p_notify_type_in      IN VARCHAR2,
    p_tracking_id_in      IN VARCHAR2,
    p_pan_code_in         IN VARCHAR2,
    p_pan_seqno_in        IN VARCHAR2,
    p_token_in            IN VARCHAR2,
    p_token_refno_in      IN VARCHAR2,
    p_expry_date_in       IN VARCHAR2,
    p_effec_date_in       IN VARCHAR2,
    p_token_oldsts_in     IN VARCHAR2,
    p_device_id_in        IN VARCHAR2,
    p_wallet_id_in        IN VARCHAR2,
    p_visible_deviceid_in IN VARCHAR2,
    p_device_model_in     IN VARCHAR2,
    p_device_type_in      IN VARCHAR2,
    p_device_manu_in      IN VARCHAR2,
    p_reason_in           IN VARCHAR2,
    p_status_in           IN VARCHAR2,
    p_event_time_in       IN VARCHAR2,
    p_event_originator_in IN VARCHAR2,
    p_auth_id_out OUT VARCHAR2,
    p_resp_code_out OUT VARCHAR2,
    p_iso_resp_code_out OUT VARCHAR2,
    p_resmsg_out OUT VARCHAR2 )
IS
  /************************************************************************************************************
  * Created by      : DHINAKARAN/DIVYA
  * Created For     : AMEX TOKEN EVENT
  * Created Date    : 18-07-2018
  * Reviewer         : Saravankumar
  * Build Number     :
  ************************************************************************************************************/
  l_err_msg VARCHAR2 (500) DEFAULT 'Success';
  l_hash_pan cms_appl_pan.cap_pan_code%TYPE;
  l_encr_pan cms_appl_pan.cap_pan_code_encr%TYPE;
  l_txn_type transactionlog.txn_type%TYPE;
  l_dr_cr_flag cms_transaction_mast.CTM_CREDIT_DEBIT_FLAG%TYPE;
  l_tran_type  cms_transaction_mast.ctm_tran_type%TYPE;
  l_prod_code cms_appl_pan.cap_prod_code%TYPE;
  l_card_type cms_appl_pan.cap_card_type%TYPE;
  l_resp_cde cms_response_mast.cms_response_id%TYPE;
  l_time_stamp TIMESTAMP;
  l_hashkey_id cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
  l_trans_desc cms_transaction_mast.ctm_tran_desc%TYPE;
  l_prfl_flag cms_transaction_mast.ctm_prfl_flag%TYPE;
  l_acct_number cms_appl_pan.cap_acct_no%TYPE;
  l_prfl_code cms_appl_pan.cap_prfl_code%TYPE;
  l_card_stat cms_appl_pan.cap_card_stat%TYPE;
  l_cust_code cms_appl_pan.cap_cust_code%TYPE;
  l_preauth_flag cms_transaction_mast.ctm_preauth_flag%TYPE;
  l_acct_bal cms_acct_mast.cam_acct_bal%TYPE;
  l_ledger_bal cms_acct_mast.cam_ledger_bal%TYPE;
  l_acct_type cms_acct_mast.cam_type_code%TYPE;
  l_proxy_number cms_appl_pan.cap_proxy_number%TYPE;
  l_fee_code transactionlog.feecode%TYPE;
  l_fee_plan transactionlog.fee_plan%TYPE;
  l_feeattach_type transactionlog.feeattachtype%TYPE;
  l_tranfee_amt transactionlog.tranfee_amt%TYPE;
  l_total_amt transactionlog.total_amount%TYPE;
  l_expry_date cms_appl_pan.cap_expry_date%TYPE;
  l_comb_hash pkg_limits_check.type_hash;
  EXP_REJECT_RECORD  EXCEPTION; 
  l_customer_id cms_cust_mast.CCM_CUST_ID%TYPE;
  l_token_event vms_AMEX_token_status.VTS_TOKEN_STAT%TYPE;
  l_token_updateflag vms_AMEX_token_status.VTS_TOKEN_UPDATEFLAG%TYPE;
  L_Corr_Cnt Number;
  L_Corr_Chk Vms_Amex_Token_Status.Vts_Correlation_Check%Type;
  L_LOGDTL_RESP VARCHAR2 (500);
  l_remarks  transactionlog.remark%type;
BEGIN
  l_resp_cde   := '1';
  l_err_msg    := 'Success';
  l_time_stamp := SYSTIMESTAMP;
  BEGIN
    --Sn Get the HashPan
    BEGIN
      l_hash_pan := gethash (p_pan_code_in);
    EXCEPTION
    WHEN OTHERS THEN
      l_err_msg := 'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En Get the HashPan
    --Sn Create encr pan
    BEGIN
      l_encr_pan := fn_emaps_main (p_pan_code_in);
    EXCEPTION
    WHEN OTHERS THEN
      l_err_msg := 'Error while converting emcrypted pan ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --Start Generate HashKEY value
    BEGIN
      l_hashkey_id := gethash ( p_delivery_channel_in || p_txn_code_in || p_pan_code_in || p_rrn_in || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5') );
    EXCEPTION
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg  := 'Error while Generating  hashkey id data ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --End Generate HashKEY
    
     --Sn find debit and credit flag
    BEGIN
      SELECT ctm_credit_debit_flag,
        TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
        ctm_tran_type,
        ctm_tran_desc,
        ctm_prfl_flag,
        ctm_preauth_flag
      INTO l_dr_cr_flag,
        l_txn_type,
        l_tran_type,
        l_trans_desc,
        l_prfl_flag,
        l_preauth_flag
      FROM cms_transaction_mast
      WHERE ctm_tran_code      = p_txn_code_in
      AND ctm_delivery_channel = p_delivery_channel_in
      AND ctm_inst_code        = p_inst_code_in;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      l_resp_cde := '12';
      l_err_msg  := 'Transaction not defined for txn code ' || p_txn_code_in || ' and delivery channel ' || p_delivery_channel_in;
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      l_resp_cde := '12';
      l_err_msg  := 'Error while selecting transaction details '||SUBSTR(sqlerrm,1,200);
      RAISE exp_reject_record;
    END;
    --En find debit and credit flag
    --Sn Get the card details
    BEGIN
      SELECT cap_card_stat,
        cap_prod_code,
        cap_card_type,
        cap_acct_no,
        CAP_PRFL_CODE,
        CAP_EXPRY_DATE,
        CAP_PROXY_NUMBER,
        cap_cust_code,
        ccm_cust_id        
      INTO l_card_stat,
        l_prod_code,
        l_card_type,
        l_acct_number,
        L_PRFL_CODE,
        L_EXPRY_DATE,
        L_PROXY_NUMBER,
        l_cust_code,
        l_customer_id
      FROM cms_appl_pan,
        cms_cust_mast
      WHERE cap_inst_code=ccm_inst_code
      AND cap_cust_code  =ccm_cust_code
      AND cap_inst_code  = p_inst_code_in
      AND cap_pan_code   = l_hash_pan;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      l_resp_cde := '16';
      l_err_msg  := 'CARD NOT FOUND ' || l_hash_pan;
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg  := 'Problem while selecting card detailS' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --End Get the card details
   
    --Sn generate auth id
    BEGIN
      SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0') INTO p_auth_id_out FROM DUAL;
    EXCEPTION
    WHEN OTHERS THEN
      l_err_msg  := 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
      l_resp_cde := '21'; -- Server Declined
      RAISE exp_reject_record;
    END;
    --En generate auth id
    BEGIN
      SELECT VTS_TOKEN_STAT
      INTO l_token_event
      FROM vms_AMEX_token_status
      WHERE VTS_STATUS_DESC=p_notify_type_in
      AND rownum =1;
    EXCEPTION
    WHEN OTHERS THEN
      l_token_event:='';
    END;
    BEGIN
      SELECT VTS_TOKEN_UPDATEFLAG,
        VTS_CORRELATION_CHECK
      Into L_Token_Updateflag,
        l_corr_chk
      FROM vms_AMEX_token_status
      WHERE VTS_REASON_CODE  =p_status_in
      AND VTS_EVENT_ORIGINATOR=p_event_originator_in;
    EXCEPTION
    WHEN OTHERS THEN
      l_token_updateflag :='N';
      L_Corr_Chk         :='N';
    END;
    BEGIN
      IF l_token_updateflag='Y' AND l_corr_chk='Y' THEN
        BEGIN
          SELECT COUNT(1)
          INTO l_corr_cnt
          FROM VMS_AMEXTOKENLCM_LOG
          WHERE VAl_CORRELATION_ID=p_tracking_id_in;
          IF l_corr_cnt           >0 THEN
            l_token_updateflag   :='N';
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          l_token_updateflag :='N';
        END;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      l_token_updateflag :='N';
    END;
    BEGIN
      IF l_token_updateflag='Y' THEN
        UPDATE VMS_TOKEN_INFO
         SET VTI_TOKEN_STAT = case when l_token_event='A' then 
                      decode(VTI_TOKEN_STAT,'S',l_token_event,VTI_TOKEN_STAT) 
                      else
                      nvl(l_token_event,VTI_TOKEN_STAT)
                      end
        WHERE vti_token    = trim(p_token_in)
        AND vti_token_pan  = l_hash_pan;
        IF SQL%ROWCOUNT    =0 THEN
          l_resp_cde      := '21';
          l_err_msg       :='Token Not found for status update';
		  RAISE exp_reject_record;
        END IF;
      END IF;
    EXCEPTION
	WHEN exp_reject_record THEN
     RAISE;
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg  :='Error while updating token staus-'||SQLERRM;
    END;
    l_resp_cde := '1';
    l_err_msg  := 'Success';
  EXCEPTION
  WHEN exp_reject_record THEN
    ROLLBACK ;
  When Others Then
    l_resp_cde := '21';
    l_err_msg  := ' Exception ' || SQLCODE || '---' || SQLERRM;
    ROLLBACK ;
  END;
  --Sn Get responce code from  master
  BEGIN
    SELECT cms_b24_respcde,
      cms_iso_respcde
    INTO p_iso_resp_code_out,
      p_resp_code_out
    FROM cms_response_mast
    WHERE cms_inst_code      = p_inst_code_in
    AND cms_delivery_channel = p_delivery_channel_in
    AND cms_response_id      = l_resp_cde;
  EXCEPTION
  WHEN OTHERS THEN
    l_err_msg       := 'Problem while selecting data from response master ' || l_resp_cde || SUBSTR (SQLERRM, 1, 300);
    p_resp_code_out := '69';
  END;
  --En Get responce code from master
 
  BEGIN
    SELECT cam_acct_bal,
      cam_ledger_bal,
      cam_type_code
    INTO l_acct_bal,
      l_ledger_bal,
      l_acct_type
    FROM cms_acct_mast
    WHERE cam_acct_no = l_acct_number
    AND cam_inst_code = p_inst_code_in;
  EXCEPTION
  WHEN OTHERS THEN
    l_acct_bal   := 0;
    l_ledger_bal := 0;
  END;
  IF l_dr_cr_flag IS NULL THEN
    BEGIN
      SELECT ctm_credit_debit_flag,
        TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
        ctm_tran_type,
        ctm_tran_desc,
        ctm_prfl_flag,
        ctm_preauth_flag
      INTO l_dr_cr_flag,
        l_txn_type,
        l_tran_type,
        l_trans_desc,
        l_prfl_flag,
        L_PREAUTH_FLAG
      FROM cms_transaction_mast
      WHERE ctm_tran_code      = p_txn_code_in
      AND ctm_delivery_channel = p_delivery_channel_in
      AND ctm_inst_code        = p_inst_code_in;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  --Sn Inserting data in transactionlog
  Begin
    l_remarks :=p_notify_type_in||'-'||p_reason_in;
    sp_log_txnlog (p_inst_code_in, p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_txn_code_in, l_txn_type, p_txn_mode_in, p_tran_date_in, p_tran_time_in, p_rvsl_code_in, l_hash_pan, l_encr_pan, l_err_msg, NULL, l_card_stat, l_trans_desc, NULL, NULL, l_time_stamp, l_acct_number, l_prod_code, l_card_type, l_dr_cr_flag, l_acct_bal, l_ledger_bal, l_acct_type, l_proxy_number, p_auth_id_out, 0, l_total_amt, l_fee_code, l_tranfee_amt, l_fee_plan, l_feeattach_type, l_resp_cde, p_resp_code_out, NULL, l_err_msg, NULL, NULL, l_remarks, l_remarks, NULL, NULL, NULL, NULL, NULL, NULL );
  EXCEPTION
  WHEN OTHERS THEN
    p_resp_code_out := '69';
    l_err_msg       := 'Exception while inserting to transaction log ' || SUBSTR (SQLERRM, 1, 300);
  END;
  --En Inserting data in transactionlog
  --Sn Inserting data in transactionlog dtl
  BEGIN
    sp_log_txnlogdetl (p_inst_code_in, p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_txn_code_in, l_txn_type, p_txn_mode_in, p_tran_date_in, p_tran_time_in, l_hash_pan, l_encr_pan, l_err_msg, l_acct_number, p_auth_id_out, 0, NULL, NULL, l_hashkey_id, NULL, NULL, NULL, NULL, p_resp_code_out, NULL, NULL, NULL, L_LOGDTL_RESP, NULL, NULL, NULL );
  EXCEPTION
  WHEN OTHERS THEN
    l_err_msg       := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
    p_resp_code_out := '69';
  END;
  BEGIN
    INSERT
    INTO VMS_AMEX_TOKENNOTIFY
      (
        VAT_CARD_no ,
        VAT_CARDNO_ENCR ,
        VAT_ACCT_SEQNO ,
        VAT_TOKEN_NO ,
        VAT_TOKEN_NOTIFY ,
        VAT_TOKEN_REFNO ,
        VAT_TOKEN_EXPDATE ,
        VAT_TOKEN_EFFDATE ,
        VAT_TOKEN_STATUS ,
        VAT_TOKEN_deviceid ,
        VAT_TOKEN_walletid ,
        VAT_TOKEN_visibleDid ,
        VAT_TOKEN_devicemodel ,
        VAT_TOKEN_devicetype ,
        VAT_TOKEN_devicemanu ,
        VAT_TOKEN_eventrsn ,
        VAT_TOKEN_eventsts ,
        VAT_TOKEN_eventtime ,
        VAT_TOKEN_eventorg,
        VAT_TRACKING_ID,
		VAT_TXN_RRN,
		VAT_TIME_STAMP
      )
      VALUES
      (
        l_hash_pan,
        l_encr_pan,
        p_pan_seqno_in,
        p_token_in,
        p_notify_type_in,
        p_token_refno_in,
        p_expry_date_in,
        p_effec_date_in,
        p_token_oldsts_in,
        p_device_id_in,
        p_wallet_id_in,
        p_visible_deviceid_in,
        p_device_model_in,
        p_device_type_in,
        p_device_manu_in,
        p_reason_in,
        p_status_in,
        p_event_time_in,
        p_event_originator_in,
        p_tracking_id_in,
		p_rrn_in,
		systimestamp
		
      );
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END;
  --Assign output variable
  p_resmsg_out := l_err_msg;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  p_resp_code_out := '69'; -- Server Declined
  p_resmsg_out    := 'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END AMEXTokenEventNotification;

Procedure  Tokenexpiryupdateadvice (
         p_inst_code_in                in    number,
          p_msg_type_in                 in 	  varchar2,
          p_rrn_in                      in  	varchar2,
          p_delivery_channel_in         in  	varchar2,
          p_txn_code_in                 in  	varchar2,
          p_txn_mode_in                 in  	varchar2,
          p_tran_date_in                in  	varchar2,
          p_tran_time_in                in  	varchar2,
          p_token_in   		              in  	varchar2,
          p_pan_code_in   		          in  	varchar2,
          P_Token_Type_In   		        In  	Varchar2,
          p_token_expry_date_in   		  in  	varchar2,   
          P_Curr_Code_In                In    Varchar2,
          p_mbr_numb_in                 in  	varchar2,
          p_rvsl_code_in                in  	varchar2,
          p_stan_in                     in  	varchar2,
          p_ntw_settl_date              in  	varchar2,
          p_expry_date_in               IN  	VARCHAR2,          
          P_Req_Respcode                In    Varchar2,
          p_rsncode_desc                in    varchar2,
          p_auth_id_out                 out 	varchar2,
          p_iso_resp_code_out           out 	varchar2,
          p_resp_code_out               out 	varchar2,
          p_resmsg_out                  out 	varchar2,
          p_resp_id_out                 out 	varchar2 --Added for sending to FSS (VMS-8018)
          )
   IS
      /************************************************************************************************************
          
       * Created by      : Veneetha C
       * Created For     : TokenExpiryUpdateAdvice 
       * Created Date    : 24-Sep-2018
       * Reviewer        : Saravankumar
       * Build Number    : VMSR06_B0003
       
	   * Modified by      : Areshka A.
       * Modified For     : VMS-8018
       * Modified Date    : 03-Nov-2023
       * Modified reason  : Added new out parameter (response id) for sending to FSS
       * Reviewer         : 
       * Build Number     :        
       
      ************************************************************************************************************/
      L_Err_Msg              Varchar2 (500) Default 'OK';
     l_resp_cde             transactionlog.response_id%TYPE;
      l_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type             transactionlog.txn_type%TYPE;
      l_dr_cr_flag           cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_tran_type            cms_transaction_mast.ctm_tran_type%TYPE;
      l_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_card_type            cms_appl_pan.cap_card_type%TYPE;
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
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      L_LOGIN_TXN            CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;
      L_LOGDTL_RESP          VARCHAR2 (500);
      L_PREAUTH_TYPE         CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
      EXP_REJECT_RECORD      EXCEPTION;     
     
      
   BEGIN
      l_resp_cde := '1';
      l_time_stamp := SYSTIMESTAMP;
      BEGIN

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
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
               RAISE exp_reject_record;
         END;
         --End Generate HashKEY

         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   CAP_PRFL_CODE, CAP_EXPRY_DATE, CAP_PROXY_NUMBER,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   L_PRFL_CODE, L_EXPRY_DATE, L_PROXY_NUMBER,
                   l_cust_code
              from cms_appl_pan
             where  cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan AND cap_mbr_numb='000';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'CARD NOT FOUND ' || l_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting card detailS'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --End Get the card details
 
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
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg := 'Error while selecting transaction details '||substr(sqlerrm,1,200);
               RAISE exp_reject_record;
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
               RAISE exp_reject_record;
         END;
         --En generate auth id

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
            --FOR UPDATE;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_resp_cde := '14';
           l_err_msg  := 'Invalid Card ';
           RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
    If P_Token_In Is Not Null   Then
            
       if P_Token_Expry_Date_In Is Not Null then
          Begin
          UPDATE VMS_TOKEN_INFO
          SET Vti_Token_Expiry_Date = p_token_expry_date_in
          WHERE vti_token    = p_token_in
          AND vti_token_pan  = l_hash_pan;
          If Sql%Rowcount    =0 Then
            L_Resp_Cde := '5';
            l_err_msg   :='Invalid Token';
             Raise  Exp_Reject_Record; 
          End If;
        EXCEPTION
         WHEN exp_reject_record
        THEN
           Raise  Exp_Reject_Record ;
        WHEN OTHERS
        THEN
         l_resp_cde := '21';
           l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            Raise  Exp_Reject_Record ;
         END;
        
        Else
         L_Resp_Cde := '316';
         L_Err_Msg := 'Token Expiry Date Not Received'; 
          Raise  Exp_Reject_Record; 
         end if; 
         
     Else
        L_Resp_Cde := '5';
        L_Err_Msg   :='Invalid Token';
         Raise  Exp_Reject_Record; 
    END IF;
   EXCEPTION
         WHEN exp_reject_record
        THEN
          null ;
       WHEN OTHERS
        THEN
         l_resp_cde := '21';
           l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            END;
   --Sn Get responce code from  master
         p_resp_id_out := l_resp_cde; --Added for VMS-8018
         BEGIN
            SELECT cms_b24_respcde,cms_iso_respcde
              INTO p_iso_resp_code_out,p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
               AND cms_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               L_ERR_MSG :=
                     'Problem while selecting data from response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
               p_resp_id_out := '69'; --Added for VMS-8018
         END;
      --En Get responce code from master


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
                        NULL,
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
                        0,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_stan_in,
                        p_ntw_settl_date
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
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
                            0,
                            null,
                            NULL,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            Null,
                            p_resp_code_out,
                            NULL,
                            NULL,
                            NULL,
                            L_LOGDTL_RESP,
                            null,
                            p_req_respcode,
                            p_stan_in
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            p_resp_id_out := '69'; --Added for VMS-8018
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resp_id_out := '69'; --Added for VMS-8018
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   End Tokenexpiryupdateadvice;

END VMSTOKENIZATION;
/
show error;