

create or replace
PROCEDURE               VMSCMS.SP_IVR_ALTERNATE_LOGIN (
   p_inst_code          IN       NUMBER,
   p_msg_type           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_ani                IN       VARCHAR2,
   p_dni                IN       VARCHAR2,
   p_zip_code           IN       VARCHAR2,
   p_id_number          IN       VARCHAR2,
   p_resp_code          OUT      VARCHAR2,
   p_resmsg             OUT      VARCHAR2,
   p_card_number        IN       VARCHAR,
   p_dob                IN       VARCHAR2,
   p_phone_number       IN       VARCHAR2   

)
AS
   v_auth_savepoint    NUMBER           DEFAULT 0;
   v_err_msg           VARCHAR2 (500);
   v_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_txn_type          transactionlog.txn_type%TYPE;
   v_auth_id           transactionlog.auth_id%TYPE;
   v_dr_cr_flag        VARCHAR2 (2);
   v_tran_type         VARCHAR2 (2);
   v_prod_code         cms_appl_pan.cap_prod_code%TYPE;
   v_card_type         cms_appl_pan.cap_card_type%TYPE;
   v_resp_cde          VARCHAR2 (5);
   v_matresp_cde          VARCHAR2 (5);
   v_time_stamp        TIMESTAMP;
   v_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
   v_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_rrn_count         NUMBER;
   v_acct_number       cms_appl_pan.cap_acct_no%TYPE;
   v_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
   v_card_stat         cms_appl_pan.cap_card_stat%TYPE;
   v_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   v_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type         cms_acct_mast.cam_type_code%TYPE;
   v_proxy_number      cms_appl_pan.cap_proxy_number%TYPE;
   v_expry_date        cms_appl_pan.cap_expry_date%TYPE;
   v_comb_hash         pkg_limits_check.type_hash;
   v_logdtl_resp       VARCHAR2 (500);
   v_pan_code          VARCHAR2 (19);
   v_mbr_numb          cms_appl_pan.CAP_MBR_NUMB%TYPE;
   V_MATCH_RULE        CHAR(1);
   V_COUNT             NUMBER;
   v_match_count       NUMBER;
   exp_reject_record   EXCEPTION;
   v_dob               VARCHAR2 (4);
   v_phone_number      VARCHAR2 (4);   
     v_Retperiod  date;  --Added for VMS-5735/FSP-991
   v_Retdate  date; --Added for VMS-5735/FSP-991

   /**********************************************************************************************
        * Created Date      : 01-September-2014
        * Created By        : MageshKumar S
        * PURPOSE           : MYVIVR-73
	* Build             : RI0027.4_B0001
        
        * Modified Date     : 01-October-2014
        * Created By        : MageshKumar S
        * PURPOSE           : MYVIVR-73 review comments incorporated
	* Build             : RI0027.4_B0002
	
        * Modified Date     : 12-Feb-2015
        * Created By        : SivaKumar M
        * PURPOSE           : MYVIVR-276
	* Build             : 
	 * Modified Date     : 19-Feb-2015
        * Created By        : SivaKumar M
        * PURPOSE           : Mantis id:16037
	* Build             : RI0027.5_B0008
	* reviewr           : S Pankaj
    
       * Modified by       :Siva kumar 
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006
       
       
       * Modified by       :Sai
       * Modified Date    : 24-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B007
       
       * Modified by       :MageshKumar
       * Modified Date    : 26-May-16
       * Modified For     : FSS-4365
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.1_B0002
	   
       * Modified by      : Ramesh A
       * Modified Date    : 14-Oct-16
       * Modified For     : FSS-4572
       * Reviewer         : Saravanakumar
       * Build Number     : VMSGPRHOSTCSD_4.10	   
	
	   * Modified by       :Vini
       * Modified Date    : 10-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12.1
	   
	   * Modified By      : Sreeja D
       * Modified Date    : 25/01/2018
       * Purpose          : VMS-162
       * Reviewer         : SaravanaKumar A/Vini Pushkaran
       * Release Number   : VMSGPRHOST18.01

  * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST62 for VMS-5735/FSP-991
	   
/**********************************************************************************************/
BEGIN
   v_resp_cde := '1';
   v_time_stamp := SYSTIMESTAMP;
   BEGIN

      SAVEPOINT v_auth_savepoint;
      
      
      IF p_card_number IS NOT NULL THEN
      
       BEGIN
       
        v_hash_pan := GETHASH(p_card_number);
        v_encr_pan := FN_EMAPS_MAIN(p_card_number);   
       EXCEPTION
    
      WHEN OTHERS THEN
       V_ERR_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
       
       END;
       
        BEGIN
         v_hashkey_id :=
            gethash (   p_delivery_channel
                     || p_txn_code
                     || p_card_number
                     || p_rrn
                     || TO_CHAR (v_time_stamp, 'YYYYMMDDHH24MISSFF5')
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while Generating  hashkey id data '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      
      ELSE
      --Start Generate HashKEY value
      BEGIN
         v_hashkey_id :=
            gethash (   p_delivery_channel
                     || p_txn_code
                     || v_pan_code
                     || p_rrn
                     || TO_CHAR (v_time_stamp, 'YYYYMMDDHH24MISSFF5')
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while Generating  hashkey id data '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      
      END IF;

     

     
      --Sn find debit and credit flag
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
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Transaction not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting transaction details';
            RAISE exp_reject_record;
      END;

      --En find debit and credit flag



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
            v_resp_cde := '21';                            -- Server Declined
            RAISE exp_reject_record;
      END;

      --En generate auth id

       --Sn Duplicate RRN Check
    BEGIN
--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE ), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod)
    THEN
        SELECT COUNT(1)
        INTO V_RRN_COUNT
        FROM TRANSACTIONLOG
        WHERE RRN         = P_RRN
        AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
        and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
 ELSE
   SELECT COUNT(1)
        INTO V_RRN_COUNT
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
        WHERE RRN         = P_RRN
        AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
        and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
END IF;

        IF V_RRN_COUNT    > 0 THEN
            v_resp_cde     := '22';
            v_err_msg      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
        END IF;
    EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
            RAISE;
        WHEN OTHERS THEN
            v_resp_cde := '21';
            v_err_msg  := 'Error while checking duplicate rrn ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;
    --En Duplicate RRN Check

      IF p_id_number IS NOT NULL THEN
      --Sn Get the card details
      BEGIN
      
      IF p_card_number IS NOT NULL AND p_dob IS NULL AND p_phone_number IS NULL THEN
      
      BEGIN
      
        select
        fn_dmaps_main(cap_pan_code_encr),cap_pan_code,
        cap_pan_code_encr,cap_card_stat,cap_prod_code,
        cap_card_type,cap_acct_no,cap_prfl_code,
        cap_expry_date,cap_proxy_number,cap_cust_code
        INTO
        v_pan_code,v_hash_pan,v_encr_pan,
        v_card_stat,v_prod_code,v_card_type,
        v_acct_number,v_prfl_code,
        v_expry_date,v_proxy_number,v_cust_code
        FROM cms_appl_pan, cms_cust_mast
        WHERE cap_inst_code = ccm_inst_code
         AND cap_cust_code = ccm_cust_code
         AND SUBSTR (ccm_ssn, LENGTH (ccm_ssn) - 3) = p_id_number
         AND cap_inst_code = p_inst_code
         AND cap_pan_code = v_hash_pan
         AND cap_card_stat <> '9';
         
        v_match_count := '1'; 
        
    EXCEPTION 
                
       WHEN OTHERS THEN
                    v_resp_cde := '210';
                    v_err_msg :='SSN/Other ID and CardNumber combination not found';
              RAISE exp_reject_record;
                 
      END;
      
      

    ELSIF p_zip_code IS NOT NULL THEN
	
	
        
	     
        select
        fn_dmaps_main(cap_pan_code_encr),cap_pan_code,
        cap_pan_code_encr,cap_card_stat,cap_prod_code,
        cap_card_type,cap_acct_no,cap_prfl_code,
        cap_expry_date,cap_proxy_number,cap_cust_code
        INTO
        v_pan_code,v_hash_pan,v_encr_pan,
        v_card_stat,v_prod_code,v_card_type,
        v_acct_number,v_prfl_code,
        v_expry_date,v_proxy_number,v_cust_code
        FROM cms_appl_pan, cms_cust_mast, cms_addr_mast
        WHERE cap_inst_code = ccm_inst_code
         AND cap_cust_code = ccm_cust_code
         AND ccm_inst_code = cam_inst_code
         AND ccm_cust_code = cam_cust_code
         AND SUBSTR (ccm_ssn, LENGTH (ccm_ssn) - 3) = p_id_number
         AND cam_inst_code = p_inst_code
         AND (cam_pin_code = p_zip_code or cam_pin_code = fn_emaps_main(p_zip_code))
         AND cam_addr_flag = 'P'
         AND cap_card_stat <> '9'
         AND cap_active_date IS NOT NULL
         AND ROWNUM = 1;

  -- added for MYVIR-276
                BEGIN
                
                
                  select
                    count(1) into v_match_count
                    FROM cms_appl_pan, cms_cust_mast, cms_addr_mast
                    WHERE cap_inst_code = ccm_inst_code
                     AND cap_cust_code = ccm_cust_code
                     AND ccm_inst_code = cam_inst_code
                     AND ccm_cust_code = cam_cust_code
                     AND SUBSTR (ccm_ssn, LENGTH (ccm_ssn) - 3) = p_id_number
                     AND cam_inst_code = p_inst_code
                     AND (cam_pin_code = p_zip_code or cam_pin_code = fn_emaps_main(p_zip_code))
                     AND cam_addr_flag = 'P'
                     AND cap_card_stat <> '9'
                     AND cap_active_date IS NOT NULL;
                                               
                EXCEPTION 
                
                 WHEN OTHERS THEN
                              v_resp_cde := '21';
                              v_err_msg :=
                                 'Problem while selecting match count '
                                 || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                 
                END;
        
        END IF;
              
       EXCEPTION
                                           
        WHEN NO_DATA_FOUND THEN

         BEGIN

          SELECT COUNT(1) INTO V_COUNT FROM CMS_CUST_MAST
          WHERE CCM_INST_CODE=P_INST_CODE
          AND substr(CCM_SSN,length(CCM_SSN)-3)=P_ID_NUMBER;

          IF V_COUNT = 0 THEN
          V_MATCH_RULE :='N';
          v_resp_cde := '210';
          --  v_err_msg := 'SSN/Other ID and ZipCode combination not found - ' || P_RRN;
          v_err_msg := 'SSN/Other ID and ZipCode combination not found';
          RAISE exp_reject_record;
          elsif V_COUNT > 0 THEN
          V_MATCH_RULE :='S';
          v_resp_cde := '210';
           -- v_err_msg := 'SSN/Other ID and ZipCode combination not found - ' || P_RRN;
          v_err_msg := 'SSN/Other ID and ZipCode combination not found';
          RAISE exp_reject_record;
          end if;
          exception
          when exp_reject_record then
          raise;

          WHEN OTHERS THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Problem while selecting SSN details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;


        END;

        when exp_reject_record then
          raise;

      WHEN OTHERS THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Problem while selecting card details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      --End Get the card details
        END IF;
		
		
	 
		
	IF p_card_number IS NOT NULL AND p_dob IS NOT NULL AND p_phone_number IS NOT NULL THEN
	    BEGIN
		v_dob := SUBSTR (p_dob, LENGTH (p_dob) - 3);
		v_phone_number := SUBSTR (p_phone_number, LENGTH (p_phone_number) - 3);
		
		
        select
        fn_dmaps_main(cap_pan_code_encr),cap_pan_code,
        cap_pan_code_encr,cap_card_stat,cap_prod_code,
        cap_card_type,cap_acct_no,cap_prfl_code,
        cap_expry_date,cap_proxy_number,cap_cust_code
        INTO
        v_pan_code,v_hash_pan,v_encr_pan,
        v_card_stat,v_prod_code,v_card_type,
        v_acct_number,v_prfl_code,
        v_expry_date,v_proxy_number,v_cust_code
        FROM cms_appl_pan, cms_cust_mast, cms_addr_mast
        WHERE cap_inst_code = ccm_inst_code
         AND cap_pan_code = GETHASH(p_card_number)	 		
         AND cap_cust_code = ccm_cust_code
         AND ccm_inst_code = cam_inst_code
         AND ccm_cust_code = cam_cust_code
		 AND TO_CHAR(ccm_birth_date,'YYYY') = v_dob		 
         AND cam_inst_code = p_inst_code
         AND cam_addr_flag = 'P'
         AND (cam_phone_one IS NULL OR SUBSTR (cam_phone_one, LENGTH (cam_phone_one) - 3) = v_phone_number or
         SUBSTR (fn_dmaps_main(cam_phone_one), LENGTH(fn_dmaps_main(cam_phone_one)) - 3) = v_phone_number)
         AND cap_card_stat <> '9';

        v_match_count := '1'; 
        
    EXCEPTION 
                
		WHEN NO_DATA_FOUND THEN
                    v_resp_cde := '264';
                    v_err_msg :='DOB/PhoneNumber and CardNumber combination not found';
              RAISE exp_reject_record;
		WHEN OTHERS THEN			  
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting DOB/PhoneNumber and CardNumber combination '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;                 
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
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting Account  detail '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
-- added for MYVIVR-276
       IF v_match_count =1  then
       
          v_resp_cde := 1;
          v_err_msg := 'SUCCESS';
          
       else 
       
          v_resp_cde := 2;
          v_matresp_cde :=2;
          v_err_msg := 'SUCCESS';
          
          end if;
       

   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK TO v_auth_savepoint;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
         ROLLBACK TO v_auth_savepoint;
   END;

   --Sn Get responce code from master
   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = v_resp_cde;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while selecting data from response master '
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
   END;
 -- added for Mantis id:16037
    IF v_match_count > 1 AND v_matresp_cde IS NOT NULL then
        p_resp_code :='00';
        
    END IF;

   --En Get responce code from master
   
   --Sn MYVIVR-73 REVIEW CHANGES
   
 /*  IF v_prod_code IS NULL
   THEN
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code
            AND cap_pan_code = gethash (v_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF; */
   
   --En MYVIVR-73 REVIEW CHANGES

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
                     0,
                     v_hash_pan,
                     v_encr_pan,
                     v_err_msg,
                     NULL,
                     v_card_stat,
                     v_trans_desc,
                     p_ani,
                     p_dni,
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
                     null,
                     null,
                     null,
                     null,
                     null,
                     null,
                     v_resp_cde,
                     p_resp_code,
                     p_curr_code,
                     v_err_msg,
                     null,
                     v_match_rule
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '89';
         v_err_msg :=
               'Exception while inserting to transaction log '
            || SQLCODE
            || '---'
            || SQLERRM;
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
                         null,
                         null,
                         null,
                         v_hashkey_id,
                         null,
                         null,
                         null,
                         null,
                         p_resp_code,
                         NULL,
                         NULL,
                         NULL,
                         v_logdtl_resp
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
   END;

--Sn Inserting data in transactionlog dtl
   --Assign output variable
    -- added for Mantis id:16037
    IF v_match_count > 1 AND v_matresp_cde IS NOT NULL then
        p_resp_code :=v_matresp_cde;
        
    END IF;
   p_resmsg := v_err_msg;

EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code := '69';                                 -- Server Declined
      p_resmsg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;

/
show error;

