CREATE OR REPLACE PROCEDURE VMSCMS.SP_MOB_VALIDATE_LOGON (
                          P_INST_CODE         IN   NUMBER ,
                          P_MSG               IN   VARCHAR2, 
                          P_RRN               IN   VARCHAR2,
                          P_DELIVERY_CHANNEL  IN   VARCHAR2,
                          P_TXN_CODE          IN   VARCHAR2,
                          P_TXN_MODE          IN   VARCHAR2,
                          P_TRAN_DATE         IN   VARCHAR2,
                          P_TRAN_TIME         IN   VARCHAR2,
                          P_PAN_CODE          IN   VARCHAR2, 
                          P_MBR_NUMB          IN   VARCHAR2,                         
                          P_RVSL_CODE         IN   VARCHAR2,
                          P_CUSTOMERID        IN   NUMBER,                                           
                          P_USERNAME          IN   VARCHAR2,
                          P_PASSWORD          IN   VARCHAR2,                     
                          P_CUST_CODE         IN   VARCHAR2,
                          P_CURR_CODE         IN   VARCHAR2,
                          P_MOBL_NO           IN   VARCHAR2,  
                          P_APPL_ID           IN   VARCHAR2,    
                          P_MOBILE_NO         IN   VARCHAR2,    
                          P_DEVICE_ID         IN   VARCHAR2,    
                          P_AUTH_ID           OUT  VARCHAR2, 
                          P_CUST_ID           OUT  NUMBER,   
                          P_RESP_CODE         OUT  VARCHAR2,
                          P_RESMSG            OUT  VARCHAR2,
                          P_ADDRESS_VERIFIED_FLAG OUT VARCHAR2, 
                          P_EXPIRY_DAYS       OUT VARCHAR2,    
                          P_SHIPPED_DATE      OUT VARCHAR2,    
                          P_logonmessage      OUT VARCHAR2,
                          P_SAVING_ACCT_INFO  OUT VARCHAR2,
                          P_STATUS            OUT VARCHAR2,
                          P_SPENDING_ACCT_NO  OUT VARCHAR2,
                          P_SAVINGSS_ACCT_NO  OUT VARCHAR2,
                          P_SPENDINGAVAILBAL  OUT VARCHAR2,
                          P_SAVAVAILBAL       OUT VARCHAR2,
                          P_TANDC_VERSION     OUT VARCHAR2,
                          P_TANDC_FLAG        OUT VARCHAR2,
                          P_SAVREOPEN_DATE    OUT varchar2,
                          p_AVAILED_TXN       OUT NUMBER,
                          p_AVAILABLE_TXN     OUT NUMBER						  
                          )

AS
/*************************************************
     * Created Date     :  12-July-2012
     * Created By       :  Deepa T
     * PURPOSE          :  UserName and Password validation.  
     * Modified Date     : 11-OCT-2012
     * Modified By       : Trivikram
     * Purpose           : for mobile number checks only for User Logon API for mantis 9327  
     * Reviewer        :   Saravanakumar
     * Reviewed Date    :   12-OCT-2012
     * Build Number     :   CMS3.5.1_RI0019
     
     * Modified Date     : 25-Mar-2013
     * Modified By       : Sachin P.
     * Modified For       : MOB-25  
     * Purpose           : Change in response message for Invalid Password and added new response message for Invalid phone number     
     * Reviewer          : Dhiraj
     * Reviewed Date     :   
     * Build Number      : CMS3.5.1_RI0024_B0008  
     
     * Modified by      : S Ramkumar
     * Modified Reason  : Mantis Id - 11357
     * Modified Date    : 25-Jun-2013
     * Reviewer         : Dhiraj 
     * Reviewed Date    : 26-Jun-13  
     * Build Number     : RI0024.2_B0009 
 
     * modified by       :  RAVI N
     * modified Date     :  09-AUG-13
     * modified reason   :  Adding new Input [P_MOB_NO,P_DEVICE_ID] parameters and logging cms_transaction_log_dtl
     * modified reason   :  FSS-1144
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  29-AUG-13
     * Build Number      :  RI0024.4_B0006 

     * Modified By      : Pankaj S.
     * Modified Date    : 19-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0027_B0003  
     
     * Modified By      : SivaKumar-Arcot 
     * Modified Date    : 19-Feb-2014
     * Modified Reason  : NCGPR-995
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-Feb-2014
     * Build Number     : RI0027.2_B0001
     
     * Modified By      : DINESH B.
     * Modified Date    : 18-Feb-2014
     * Modified Reason  : MVCSD-4121 and FWR-43 :Fetching address verified flag and expiry days and shipped date for the customer.
     * Reviewer         : Dhiraj
     * Reviewed Date    : 18-Feb-2014
     * Build Number     : RI0027.2_B0002
     
     * Modified By      : DINESH B.
     * Modified Date    : 25-Mar-2014
     * Modified Reason  : Review changes done for MVCSD-4121 and FWR-43 :Fetching address verified flag and expiry days and shipped date for the customer.
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 01-April-2014
     * Build Number     : RI0027.2_B0003
     
     * Modified by      : MAGESHKUMAR S.
     * Modified Date    : 03-FEB-2015
     * Modified For     : FSS-2075(2.4.2.4.1 null4.3.1 integration)
     * Reviewer         : PANKAJ S.
     * Build Number     : RI0027.5_B0006

     * Modified by      : Abdul Hameed M.A
     * Modified Date    : 02-Mar-15    
     * Modified For     : DFCTNM-30
     * Reviewer         : Spankaj
     * Build Number     : VMSGPRHOSTCSD_3.0_B0001
     
     * Modified by      : Siva Kumar M
     * Modified Date    : 06-Mar-15    
     * Modified For     : DFCTNM-35
     * Reviewer         : Saravanakumar A
     * Build Number     : VMSGPRHOSTCSD_3.0_B0001
     
       * Modified by      : Siva Kumar M
     * Modified Date    : 09-Mar-15    
     * Modified For     : Review changes
     * Reviewer         : Pankaj S
     * Build Number     : VMSGPRHOSTCSD_3.0_B0001
     
     * Modified by      : Siva Kumar M
     * Modified Date    : 24-Mar-15    
     * Modified For     : DFCTNM-35
     * Reviewer         : Pankaj S
     * Build Number     : VMSGPRHOSTCSD_3.0_B0002

     * Modified By      : Siva Kumar M
     * Modified Date    : 31-Mar-2015
     * Modified for     : DFCTNM-35(Aditional changes)
     * Reviewer         : Pankaj S
     * Reviewed Date    : 31-Mar-2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0003
     
          
     * Modified by      : Siva Kumar M
     * Modified for     : FSS-2279(Savings account changes)
     * Modified Date    : 31-Aug-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1.1_B0007
     
     * Modified by      : Siva Kumar
     * Modified Date    : 27-Oct-2015
     * Modified for     : FSS-3721
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1.1.1
	 
     * Modified by      : A.Sivakaminathan
     * Modified Date    : 31-Dec-2015
     * Modified for     : MVHOST-1253(additional response tags)
     * Reviewer         : Pankaj Salunkhe
     * Build Number     : VMSGPRHOSTCSD_3.3
     
     * Modified by      : Siva Kumar m
     * Modified Date    : 18-Aug-2016
     * Modified for     : VP-10
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_4.2
	 
   
    
   * Modified by       : SaravanaKumar A
   * Modified Date        : 17-Feb-17
   * Modified For         : Fss-5036_BR3
   * Reviewer             : Pankaj S 
   * Build Number         : VMSGPRHOST17.02
   
   	 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07
     
     
      * Modified By      : Akhil
      * Modified Date    : 24-jan-2018
      * Purpose          : VMS-162
      * Reviewer         : Saravanakumar
      * Build Number     : VMSGPRHOST_18.1
      
      * Modified By      : VINI PUSHKARAN
      * Modified Date    : 01-MAR-2019
      * Purpose          : VMS-809(Decline Request for Web-account Username if Username is Already Taken)
      * Reviewer         : Saravanakumar A
      * Build Number     : VMSGPRHOST_R13_B0002     

	  * Modified By      : SaravanaKumar
      * Modified Date    : 15-Nov-2019
      * Purpose          : VMS-4098
      * Reviewer         : Saravanakumar A
      * Build Number     : VMSGPRHOST_R54_B0002 

    * Modified By      : Karthick/Jey
    * Modified Date    : 05-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991 	  
      
*************************************************/


V_RRN_COUNT             NUMBER;
V_ERRMSG                TRANSACTIONLOG.ERROR_MSG%TYPE;
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_CUST_CODE             CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_CARDSTAT              CMS_APPL_PAN.CAP_CARD_STAT%TYPE; 
v_masking_char          VARCHAR2 (10) DEFAULT '**********';
V_DR_CR_FLAG            CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
V_OUTPUT_TYPE           CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
V_TRAN_TYPE             CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
V_CAPTURE_DATE          TRANSACTIONLOG.DATE_TIME%TYPE;
v_first                 VARCHAR2 (10);
v_encrypt               VARCHAR2 (30);
v_last                  VARCHAR2 (10);
v_length                NUMBER (30);
v_masked_pan            VARCHAR2 (40);
v_saving_acct_dtl       VARCHAR2(40);
v_spending_acct_dtl     VARCHAR2(40);
V_SAVING_TYPE_CODE      cms_acct_mast.cam_type_code%TYPE  DEFAULT '2';
V_RESP_CDE              transactionlog.response_id%TYPE;
V_TRANS_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;  
V_RENEWAL_DATE          cms_cardrenewal_hist.cch_renewal_date%TYPE;                                     
V_EXPIRY_DATE           cms_appl_pan.cap_expry_date%type;        
v_phy_cam_mobl_one      cms_addr_mast.cam_mobl_one%type;           
v_phy_cam_phone_one     cms_addr_mast.cam_phone_one%type;        
v_phy_cam_phone_two     cms_addr_mast.cam_phone_two%type;        
v_mail_cam_mobl_one     cms_addr_mast.cam_mobl_one%type;         
v_mail_cam_phone_one    cms_addr_mast.cam_phone_one%type;        
v_mail_cam_phone_two    cms_addr_mast.cam_phone_two%type;        
v_cap_cust_code         CMS_APPL_PAN.cap_cust_code%TYPE;         
V_HASHKEY_ID            CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; 
V_TIME_STAMP            transactionlog.time_stamp%TYPE;                                  
v_acct_number           cms_acct_mast.cam_acct_no%TYPE;
v_prod_code             cms_appl_pan.cap_prod_code%type;
v_card_type             cms_appl_pan.cap_card_type%type;
v_acct_balance          cms_acct_mast.cam_acct_bal%TYPE;
v_ledger_bal            cms_acct_mast.cam_ledger_bal%TYPE;
v_acct_type             cms_acct_mast.cam_type_code%TYPE;
v_wrng_count            CMS_CUST_MAST.CCM_WRONG_LOGINCNT%TYPE;
V_WRONG_PWDCUNT         CMS_PROD_CATTYPE.CPC_WRONG_LOGONCOUNT%TYPE;
V_UNLOCK_WAITTIME       CMS_PROD_CATTYPE.CPC_ACCTUNLOCK_DURATION%TYPE;
v_acctlock_flag         cms_cust_mast.CCM_ACCTLOCK_FLAG%TYPE;
v_time_diff             number;
v_gpresign_optinflag    cms_optin_status.COS_GPRESIGN_OPTINFLAG%TYPE;
V_MIN_TRAN_AMT          CMS_DFG_PARAM.CDP_PARAM_VALUE%TYPE;
V_CPP_TANDC_VERSION     CMS_PROD_CATTYPE.CPC_TANDC_VERSION%TYPE;
V_CCM_TANDC_VERSION     CMS_CUST_MAST.CCM_TANDC_VERSION%TYPE;
v_savings_statcode      cms_acct_mast.cam_stat_code%TYPE;
V_CAM_LUPD_DATE         CMS_ACCT_MAST.cam_lupd_date%TYPE;
V_STARTERCARD_FLAG      CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE;
V_CARD_STAT             CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
V_GPR_FLAG              NUMBER;
V_REOPEN_PERIOD         CMS_DFG_PARAM.CDP_PARAM_VALUE%TYPE;
v_max_svg_trns_limt     NUMBER(10);
V_HASH_PASSWORD         CMS_CUST_MAST.CCM_PASSWORD_HASH%TYPE;
v_user_name             cms_cust_mast.ccm_user_name%type;
v_encrypt_enable        cms_prod_cattype.cpc_encrypt_enable%type;
V_audit_flag		    cms_transaction_mast.ctm_txn_log_flag%TYPE;
EXP_AUTH_REJECT_RECORD  EXCEPTION;
EXP_REJECT_RECORD       EXCEPTION; 

v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991   
    
	--Sn Getting DFG Parameters 
    CURSOR c (p_prod_code cms_prod_mast.cpm_prod_code%type,p_card_type cms_appl_pan.cap_card_type%type) 
    IS
      SELECT cdp_param_key, cdp_param_value
        FROM cms_dfg_param
       WHERE cdp_inst_code = p_inst_code
       AND   cdp_prod_code = p_prod_code
      and   cdp_card_type = p_card_type
       and   cdp_param_key in ('InitialTransferAmount','MaxNoTrans','Saving account reopen period'); 
	--En Getting DFG Parameters
      
BEGIN
   

   V_TIME_STAMP :=SYSTIMESTAMP; -- Added for regarding FSS-1144
       --Sn Get the HashPan
       BEGIN
          V_HASH_PAN := GETHASH(P_PAN_CODE);
        EXCEPTION
          WHEN OTHERS THEN
         V_RESP_CDE     := '12';
         V_ERRMSG := 'Error while converting hash pan ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashPan

      --Sn Create encr pan
        BEGIN
          V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_PAN_CODE);
          EXCEPTION
          WHEN OTHERS THEN
            V_RESP_CDE     := '12';
            V_ERRMSG := 'Error while converting encryption pan  ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;       
        
      --Start Generate HashKEY value for regarding FSS-1144   
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        V_RESP_CDE := '21';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
   
    --End Generate HashKEY value for regarding FSS-1144

       
        --Sn find debit and credit flag
       
    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,CTM_TRAN_DESC,nvl(ctm_txn_log_flag,'T')
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_TRANS_DESC,V_audit_flag
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '12'; --Ineligible Transaction
       V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '21'; --Ineligible Transaction
       V_ERRMSG  := 'Error while selecting transaction details';
       RAISE EXP_REJECT_RECORD;
    END;
        
    --En find debit and credit flag

       --Sn Duplicate RRN Check
        BEGIN
		
			  --Added for VMS-5739/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
		
         IF (v_Retdate>v_Retperiod) THEN                                                   --Added for VMS-5739/FSP-991
		 
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM TRANSACTIONLOG
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE                
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
		  
		ELSE
		
		  SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                   --Added for VMS-5739/FSP-991
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE                
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
		
		END IF;

          IF V_RRN_COUNT    > 0 THEN
            V_RESP_CDE     := '22';
            V_ERRMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
          END IF; 
		  
		  EXCEPTION
		  WHEN EXP_REJECT_RECORD THEN
		    RAISE EXP_REJECT_RECORD;
		  WHEN OTHERS THEN
			V_RESP_CDE := '21';
			V_ERRMSG  := 'Error while selecting RRN Count from transactionlog' ||
			SUBSTR(SQLERRM, 1, 200);
		  RAISE EXP_REJECT_RECORD;		  
        END;
       --En Duplicate RRN Check
      
     
        --Sn Get the card details
         BEGIN
              SELECT CAP_CARD_STAT,cap_cust_code,
                     cap_prod_code,cap_card_type , cap_expry_date,cap_cust_code,CAP_ACCT_NO 
                   INTO V_CARDSTAT,v_cap_cust_code,
                   v_prod_code,v_card_type, V_EXPIRY_DATE,V_CUST_CODE,v_acct_number 
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
              
                P_SPENDING_ACCT_NO :=v_acct_number;
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '16'; 
                V_ERRMSG  := 'Card number not found ' || P_PAN_CODE;
              RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                V_RESP_CDE := '12';
                V_ERRMSG  := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
          END;
      --End Get the card details     

    IF ((P_CUSTOMERID IS NULL) AND (P_USERNAME IS NOT NULL AND P_PASSWORD IS NOT NULL)) THEN

--       --Sn Get the HashPassword
       BEGIN
          V_HASH_PASSWORD := GETHASH(trim(P_PASSWORD));
        EXCEPTION
          WHEN OTHERS THEN
         V_RESP_CDE     := '12';
         V_ERRMSG := 'Error while converting password ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
--      --En Get the HashPassword

        
              
         begin
         
            select nvl(CCM_WRONG_LOGINCNT,'0'),
                   nvl(CCM_ACCTLOCK_FLAG,'N'),
                  ROUND((sysdate- nvl(ccm_last_logindate,sysdate))*24*60),
                  CCM_TANDC_VERSION
                  INTO v_wrng_count,
                  v_acctlock_flag,
                  v_time_diff,
                  V_CCM_TANDC_VERSION
                  FROM CMS_CUST_MAST 
                  WHERE ccm_cust_code=V_CUST_CODE   
                  AND ccm_inst_code=P_INST_CODE; 
         
           EXCEPTION 
           WHEN OTHERS THEN
           
               V_RESP_CDE     := '12';
               V_ERRMSG       := 'Error while getting customer details ' || SUBSTR(SQLERRM, 1, 200);
               
         RAISE EXP_REJECT_RECORD;
         
         end;
      
      
        BEGIN
         
         SELECT CPC_WRONG_LOGONCOUNT-1,
                CPC_ACCTUNLOCK_DURATION,
                CPC_TANDC_VERSION,
                cpc_encrypt_enable
                INTO V_WRONG_PWDCUNT,
                V_UNLOCK_WAITTIME,
                V_CPP_TANDC_VERSION,
                v_encrypt_enable
                FROM cms_prod_cattype
        WHERE     cpc_inst_code = p_inst_code
              AND cpc_prod_code = v_prod_code
              AND cpc_card_type = v_card_type;				
				
        EXCEPTION 
           WHEN OTHERS THEN
             P_RESP_CODE    := '12';
             V_ERRMSG       := 'Error while getting ACCT UNLOCK PARAMS ' || SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
         
        END;
        
        if v_encrypt_enable='Y' then
            v_user_name:=fn_emaps_main(UPPER(trim(P_USERNAME)));
        else
            v_user_name:=UPPER(trim(P_USERNAME));
        end if;
                
        IF  V_CCM_TANDC_VERSION = V_CPP_TANDC_VERSION THEN
        
        P_TANDC_FLAG :='0';
        
        ELSE
        
        P_TANDC_FLAG := '1';
        
        END IF;
        P_TANDC_VERSION :=V_CPP_TANDC_VERSION;
        
        if (v_acctlock_flag ='L' and  v_time_diff < V_UNLOCK_WAITTIME) AND  (V_WRONG_PWDCUNT is not null and  V_UNLOCK_WAITTIME is not  null) then 
          
              V_RESP_CDE := '224'; --new response code...
              V_ERRMSG  := 'User id is locked.Please try after'||V_UNLOCK_WAITTIME||' minutes';
              P_logonmessage  := (V_WRONG_PWDCUNT+1);
           
              RAISE EXP_REJECT_RECORD;
          
       end if;
       --Sn check whether the Username and Password is correct or not
         begin

           SELECT CCM_CUST_ID, CCM_ADDRVERIFY_FLAG
           INTO P_CUST_ID,P_ADDRESS_VERIFIED_FLAG
           FROM CMS_CUST_MAST
           WHERE CCM_INST_CODE = P_INST_CODE
           AND CCM_CUST_CODE = V_CUST_CODE
           AND UPPER(CCM_USER_NAME)=v_user_name 
           AND CCM_PASSWORD_HASH=V_HASH_PASSWORD           
           AND CCM_APPL_ID =P_APPL_ID ;




         exception
            WHEN NO_DATA_FOUND THEN
                          
                                    if V_WRONG_PWDCUNT is not null and  V_UNLOCK_WAITTIME is not  null then
            
            if  v_wrng_count < V_WRONG_PWDCUNT  and v_time_diff < V_UNLOCK_WAITTIME  then
                
                   BEGIN
                       
                                       
                        SP_UPDATE_USERID ( P_INST_CODE, V_CUST_CODE,v_acctlock_flag,'U', V_ERRMSG );
                   
                        IF   V_ERRMSG='OK' THEN
                            V_RESP_CDE := '114';
                           V_ERRMSG  := 'Invalid Username or Password '; 
                            p_logonmessage  := (V_WRONG_PWDCUNT - v_wrng_count);
                            RAISE EXP_REJECT_RECORD;     
                        
                      end if;
                             V_RESP_CDE := '21';
                             RAISE EXP_REJECT_RECORD;
                      
                      --end if;
                     
                       
                     EXCEPTION 
                  
                      WHEN EXP_REJECT_RECORD THEN
                  
                      RAISE;
                  
                      WHEN OTHERS THEN
                  
                       V_RESP_CDE := '21';
                       V_ERRMSG  := 'Error from while updating user wrong count,acct flag ' ||
                       SUBSTR(SQLERRM, 1, 200);
                       RAISE EXP_REJECT_RECORD;
                           
                  
                     END;
                     
                
                   
            elsif v_wrng_count = V_WRONG_PWDCUNT  and  v_time_diff < V_UNLOCK_WAITTIME  then
              
                        
                 BEGIN
                
                  SP_UPDATE_USERID ( P_INST_CODE, V_CUST_CODE,'L','U' ,V_ERRMSG );
                  
                  IF   V_ERRMSG='OK' THEN
                       V_RESP_CDE := '224';  
                     
                        V_ERRMSG  := 'User id is locked.Please try after'||V_UNLOCK_WAITTIME||' minutes'; 
                         P_logonmessage  := (V_WRONG_PWDCUNT+1);
                       RAISE EXP_REJECT_RECORD;  
                  end if; 
                       V_RESP_CDE := '21';
                       RAISE EXP_REJECT_RECORD;
                 
                  --end if; 
                 
                  
                 EXCEPTION 
                  
                  WHEN EXP_REJECT_RECORD THEN
                  
                  RAISE;
                  
                  WHEN OTHERS THEN
                  
                   V_RESP_CDE := '21';
                   V_ERRMSG   := 'Error from while updating user wrong count,acct flag ' ||
                        SUBSTR(SQLERRM, 1, 200);
                   RAISE EXP_REJECT_RECORD;
                   END;
            else                  
                    BEGIN
                     SP_UPDATE_USERID ( P_INST_CODE, V_CUST_CODE,'N','R', V_ERRMSG );
                    
                     IF V_ERRMSG='OK' THEN
                       V_RESP_CDE := '114';
                  
                         V_ERRMSG  := 'Invalid Username or Password '; 
                          P_logonmessage  := V_WRONG_PWDCUNT;
                       RAISE EXP_REJECT_RECORD;    
                   end if;  
                       V_RESP_CDE := '21';
                       RAISE EXP_REJECT_RECORD;
                  -- end if;
                 
                 EXCEPTION 
                  
                  WHEN EXP_REJECT_RECORD THEN
                  
                  RAISE;
                  
                  WHEN OTHERS THEN
                    V_RESP_CDE := '21';
                    V_ERRMSG   := 'Error from while updating user wrong count,acct flag ' ||
                               SUBSTR(SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;
                                     
                 END;
             end if;
             
          else
            V_RESP_CDE := '114';
            V_ERRMSG  := 'Invalid Username or Password '; 
            RAISE EXP_REJECT_RECORD;
          
          end if;
                          
              
         when EXP_REJECT_RECORD then
         
            raise;
            
         WHEN OTHERS THEN
                    V_RESP_CDE := '21';
                    V_ERRMSG  := 'Error from checking cust name' ||
                    SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
         END;

      -- END IF;
       
         IF V_WRONG_PWDCUNT is not null and  V_UNLOCK_WAITTIME is not  null THEN
     
          begin
                    
          update cms_cust_mast set CCM_WRONG_LOGINCNT=0,
                                   CCM_LAST_LOGINDATE='',
                                   CCM_ACCTLOCK_FLAG='N'
                                   where ccm_cust_code=V_CUST_CODE 
                                   and ccm_inst_code=P_INST_CODE;
                                   
                                   P_logonmessage := (V_WRONG_PWDCUNT+1); 
             
                IF SQL%ROWCOUNT = 0 THEN
               
                   V_RESP_CDE := '21';
                   V_ERRMSG  := 'Error while updating cust master ' ||SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
               
               end if;
           
           EXCEPTION 
             when exp_reject_record then
             raise;
             WHEN OTHERS THEN
                   V_RESP_CDE := '21';
                   V_ERRMSG  := 'Error from while Authenticate user ' ||
                        SUBSTR(SQLERRM, 1, 200);
                   RAISE EXP_REJECT_RECORD;
          
          end;
          
          END IF;
      
         IF (P_CUST_ID IS NOT NULL) AND P_TXN_CODE = '01' THEN 
         
                Begin
                    
                  SELECT decode(v_encrypt_enable,'Y',DECODE(LENGTH(fn_dmaps_main(cam_mobl_one)),10,fn_dmaps_main(cam_mobl_one),11,substr(fn_dmaps_main(cam_mobl_one),2,10),fn_dmaps_main(cam_mobl_one)),DECODE(LENGTH(cam_mobl_one),10,cam_mobl_one,11,substr(cam_mobl_one,2,10),cam_mobl_one)),--modified for NCGPR-995
                  decode(v_encrypt_enable,'Y',DECODE(LENGTH(fn_dmaps_main(cam_phone_one)),10,fn_dmaps_main(cam_phone_one),11,substr(fn_dmaps_main(cam_phone_one),2,10),fn_dmaps_main(cam_phone_one)),DECODE(LENGTH(cam_phone_one),10,cam_phone_one,11,substr(cam_phone_one,2,10),cam_phone_one)),--modified for NCGPR-995
                  DECODE(LENGTH(cam_phone_two),10,cam_phone_two,11,substr(cam_phone_two,2,10),cam_phone_two) --modified for NCGPR-995
                  into   v_phy_cam_mobl_one,    
                  v_phy_cam_phone_one,
                  v_phy_cam_phone_two
                  FROM cms_addr_mast
                  WHERE cam_cust_code = v_cap_cust_code
                   and   cam_addr_flag = 'P';
          
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      V_ERRMSG := 'Cust code not found in master for physical details'||v_cap_cust_code ;
                      V_RESP_CDE := '49';
                      RAISE EXP_REJECT_RECORD;
                    WHEN OTHERS THEN
                    V_RESP_CDE := '21';
                    V_ERRMSG  := 'Error while checking physical details' ||
                    SUBSTR(SQLERRM, 1, 200);
                    
                   RAISE EXP_REJECT_RECORD;
                   
                END;
                 
                Begin
                 
                 
                  SELECT decode(v_encrypt_enable,'Y',DECODE(LENGTH(fn_dmaps_main(cam_mobl_one)),10,fn_dmaps_main(cam_mobl_one),11,substr(fn_dmaps_main(cam_mobl_one),2,10),fn_dmaps_main(cam_mobl_one)),DECODE(LENGTH(cam_mobl_one),10,cam_mobl_one,11,substr(cam_mobl_one,2,10),cam_mobl_one)),--modified for NCGPR-995
                  decode(v_encrypt_enable,'Y',DECODE(LENGTH(fn_dmaps_main(cam_phone_one)),10,fn_dmaps_main(cam_phone_one),11,substr(fn_dmaps_main(cam_phone_one),2,10),fn_dmaps_main(cam_phone_one)),DECODE(LENGTH(cam_phone_one),10,cam_phone_one,11,substr(cam_phone_one,2,10),cam_phone_one)),--modified for NCGPR-995
                  DECODE(LENGTH(cam_phone_two),10,cam_phone_two,11,substr(cam_phone_two,2,10),cam_phone_two) --modified for NCGPR-995
                  into   v_mail_cam_mobl_one,   
                          v_mail_cam_phone_one,
                          v_mail_cam_phone_two
                   FROM cms_addr_mast
                   WHERE cam_cust_code = v_cap_cust_code
                   and   cam_addr_flag = 'O';  
                   
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                     null;
                    WHEN OTHERS THEN
                    V_RESP_CDE := '21';
                    V_ERRMSG  := 'Error while checking mailing details' ||
                    SUBSTR(SQLERRM, 1, 200);
                   RAISE EXP_REJECT_RECORD;
                   
                END;
         
         END IF;
         
      --En check whether the Username already Username or not
      ELSIF P_TXN_CODE = '36' then
      begin
           
          SELECT  CCM_ADDRVERIFY_FLAG
           INTO P_ADDRESS_VERIFIED_FLAG  
           FROM CMS_CUST_MAST
           WHERE CCM_CUST_ID =P_CUSTOMERID
           and CCM_INST_CODE=P_INST_CODE;
         --   and CCM_APPL_ID =P_APPL_ID  ;
            
            P_CUST_ID:=P_CUSTOMERID;
            
         EXCEPTION
            when NO_DATA_FOUND then
              V_ERRMSG := 'Invalid Customer ID';
              V_RESP_CDE := '118';
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERRMSG  := 'Error from Address Verify flag' ||
            SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
         END;
       
   END IF;
      --Sn call to authorize procedure
      BEGIN
        SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                P_MSG,
                P_RRN,
                P_DELIVERY_CHANNEL,
                NULL,
                P_TXN_CODE,
                P_TXN_MODE,
                P_TRAN_DATE,
                P_TRAN_TIME,
                P_PAN_CODE,
                P_INST_CODE,
                NULL,
                NULL,
                NULL,
                NULL,
                P_CURR_CODE,             
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                '000',
                P_RVSL_CODE,
                NULL,
                V_AUTH_ID,
                P_RESP_CODE,
                V_ERRMSG,
                V_CAPTURE_DATE);
        IF P_RESP_CODE <> '00' AND V_ERRMSG <> 'OK' THEN
        RAISE EXP_AUTH_REJECT_RECORD;
        END IF;
      EXCEPTION
        WHEN EXP_AUTH_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error from Card authorization' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      END;
    --En call to authorize procedure 
   
    
    IF P_ADDRESS_VERIFIED_FLAG ='1' THEN
        P_EXPIRY_DAYS  := TRUNC(V_EXPIRY_DATE - SYSDATE);
      END IF;
    IF P_ADDRESS_VERIFIED_FLAG ='0' THEN
    BEGIN
      SELECT cch_renewal_date
      INTO V_RENEWAL_DATE
      FROM cms_cardrenewal_hist
      WHERE CCH_INST_CODE= P_INST_CODE
      AND cch_pan_code   = V_HASH_PAN;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    NULL;
    WHEN OTHERS THEN
      P_RESP_CODE := '89';
      V_ERRMSG    := 'Error while selecting data from renewal history for card number'|| SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    END IF;
   
 
    IF P_ADDRESS_VERIFIED_FLAG ='0' AND V_RENEWAL_DATE IS NOT NULL THEN
    BEGIN
      SELECT ccs_shipped_date
      INTO P_SHIPPED_DATE
      FROM cms_cardissuance_status
      WHERE ccs_pan_code = V_HASH_PAN
      AND ccs_inst_code  = P_INST_CODE;
      
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '21';
             V_ERRMSG    := 'No data found while selecting SHIPPED DATE';
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
            P_RESP_CODE := '21';
            v_errmsg  := 'while selecting SHIPPED DATE'|| SUBSTR (SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
      END;
    END IF;
  
     --Sn Updtated transactionlog For regarding FSS-1144          
         IF V_AUDIT_FLAG = 'T' THEN          
            BEGIN
			
					  --Added for VMS-5739/FSP-991
					  
			   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			   INTO   v_Retperiod 
			   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
			   WHERE  OPERATION_TYPE='ARCHIVE' 
			   AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
               v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
			
            IF (v_Retdate>v_Retperiod) THEN		                                  --Added for VMS-5739/FSP-991
			
               UPDATE CMS_TRANSACTION_LOG_DTL
               SET CTD_USER_NAME=v_user_name,
              CTD_MOBILE_NUMBER=P_MOBILE_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE 
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			  
			ELSE
			
			   UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST             --Added for VMS-5739/FSP-991
               SET CTD_USER_NAME=v_user_name,
              CTD_MOBILE_NUMBER=P_MOBILE_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE 
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			
			END IF;
              
             IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;    
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN        
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END; 
END IF;
        
   --End Updated transaction log  for regarding  FSS-1144   
    
 IF LENGTH (P_PAN_CODE) > 10
         THEN
            v_first := SUBSTR (P_PAN_CODE, 1, 6);
            v_last := SUBSTR (P_PAN_CODE, -4, 4);
            v_length := (LENGTH (P_PAN_CODE) - LENGTH (v_first) - LENGTH (v_last));
            v_encrypt :=
               TRANSLATE (SUBSTR (P_PAN_CODE, 7, v_length),
                          '0123456789',
                          v_masking_char
                         );
            v_masked_pan := v_first || v_encrypt || v_last;
 ELSE
       V_RESP_CDE := '21';
       V_ERRMSG  := 'Invalid PAN Length';
    RAISE EXP_REJECT_RECORD;
 END IF;
 
 BEGIN
 
 
 
 SELECT '0~'||cam_acct_no ||'~ '||trim(to_char(cam_acct_bal,'99999999999990.00')),CAM_STAT_CODE,CAM_LUPD_DATE,cam_acct_no,cam_acct_bal  
         ,case when sysdate >CAM_SAVTOSPD_TFER_DATE then 0  else NVL(CAM_SAVTOSPD_TFER_COUNT,0) end
       INTO v_saving_acct_dtl,v_savings_statcode,V_CAM_LUPD_DATE,P_SAVINGSS_ACCT_NO,P_SAVAVAILBAL
       ,P_AVAILED_TXN	   
        FROM cms_acct_mast
       WHERE cam_acct_id IN (
                SELECT cca_acct_id
                  FROM cms_cust_acct
                 WHERE cca_cust_code = P_CUST_CODE
                   AND cca_inst_code = P_INST_CODE)
        AND cam_type_code = V_SAVING_TYPE_CODE
         AND cam_inst_code = P_INST_CODE;
         
EXCEPTION
WHEN NO_DATA_FOUND THEN
    v_saving_acct_dtl:=NULL;
WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG  := 'Error while selecting Savings Account Details'|| SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
END;

IF v_saving_acct_dtl IS NOT NULL THEN

V_ERRMSG:=v_masked_pan||'~'||v_saving_acct_dtl;

END IF;


BEGIN

SELECT '1~'||cam_acct_no ||'~ '|| trim(to_char(cam_acct_bal,'99999999999990.00')),cam_acct_bal
       INTO v_spending_acct_dtl,P_SPENDINGAVAILBAL
        FROM cms_acct_mast
       WHERE cam_acct_no=v_acct_number 
         AND cam_inst_code = P_INST_CODE;
EXCEPTION
WHEN NO_DATA_FOUND THEN
    v_spending_acct_dtl:=NULL;

 WHEN OTHERS THEN
        
       V_RESP_CDE := '21';
       V_ERRMSG  := 'Error while selecting Spending Account Details'|| SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
END;


   BEGIN
        V_MIN_TRAN_AMT :=0;
        v_max_svg_trns_limt :=0;
        V_REOPEN_PERIOD :=0;
   
      FOR i IN c (v_prod_code,v_card_type)  
      LOOP
         BEGIN
           IF i.cdp_param_key = 'InitialTransferAmount' THEN
               V_MIN_TRAN_AMT := i.cdp_param_value;
            ELSIF i.cdp_param_key = 'MaxNoTrans' THEN
               v_max_svg_trns_limt := i.cdp_param_value;
            ELSIF i.cdp_param_key = 'Saving account reopen period' THEN               
                V_REOPEN_PERIOD := i.cdp_param_value;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '21';
               v_errmsg :='Error while selecting Saving account parameters ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END LOOP;
      
       P_AVAILABLE_TXN :=v_max_svg_trns_limt - P_AVAILED_TXN;
   EXCEPTION      
      WHEN exp_reject_record THEN
        RAISE;     
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :='Error while opening cursor C ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;


 IF v_saving_acct_dtl IS NULL THEN
 
     BEGIN
    
        SELECT nvl(cos_gpresign_optinflag,'0')
        INTO  v_gpresign_optinflag
        FROM cms_optin_status
        WHERE  cos_cust_id=P_CUST_ID;
    
     EXCEPTION 
    
      WHEN  NO_DATA_FOUND THEN
      v_gpresign_optinflag :='0';
      
      WHEN  OTHERS THEN
      
          V_RESP_CDE := '21';
          V_ERRMSG  := 'Error from while selecting GPR T and C' ||
                  SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
    
     END;
 
 

  IF v_gpresign_optinflag = '0' OR  TO_NUMBER(P_SPENDINGAVAILBAL) < TO_NUMBER(V_MIN_TRAN_AMT) OR TO_NUMBER(V_MIN_TRAN_AMT) =0  THEN
                    
    P_SAVING_ACCT_INFO := 'NE';
    ELSE 
     -- customer is eligible for savings account ....
     P_SAVING_ACCT_INFO :='E';
                    
   END IF;
 
 ELSIF   v_savings_statcode = 2 THEN  -- savings acct is closed.
 
 P_SAVING_ACCT_INFO :='D';
 P_SAVREOPEN_DATE:=TO_CHAR(V_CAM_LUPD_DATE+V_REOPEN_PERIOD,'MM/DD/YYYY'); 
  
 
 
 ELSE  -- savings acct open
 
  P_SAVING_ACCT_INFO :='A'; 
 
 END IF;


     BEGIN
          SELECT COUNT(1),count(DISTINCT cap_prod_code)
          INTO V_STARTERCARD_FLAG,V_GPR_FLAG
          FROM CMS_APPL_PAN 
          WHERE CAP_CUST_CODE=V_CUST_CODE AND UPPER(CAP_STARTERCARD_FLAG) = 'N'
             AND CAP_INST_CODE=P_INST_CODE AND CAP_CARD_STAT NOT IN('3','9');  
          
       
    IF V_STARTERCARD_FLAG = '1' THEN
          
        SELECT CAP_CARD_STAT INTO V_CARD_STAT
            FROM CMS_APPL_PAN
            WHERE CAP_CUST_CODE=V_CUST_CODE AND UPPER(CAP_STARTERCARD_FLAG) = 'N'
             AND CAP_INST_CODE=P_INST_CODE AND CAP_CARD_STAT NOT IN('3','9'); 
              
          
          END IF;
           
          
     EXCEPTION       
       WHEN NO_DATA_FOUND THEN      
         V_RESP_CDE := '21';
         V_ERRMSG  := 'No data found while selecting STARTERCARD STATUS ';
         RAISE EXP_REJECT_RECORD; 
         WHEN TOO_MANY_ROWS THEN      
         V_RESP_CDE := '21';
         V_ERRMSG  := 'TOO MANY ROWS found while selecting STARTERCARD STATUS ';             
         RAISE EXP_REJECT_RECORD;      
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERRMSG  := 'Error from while selecting STARTERCARD STATUS ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
           
    END;
 
 
     IF V_STARTERCARD_FLAG = '0' THEN     --GPR Card not present   
            
       P_STATUS := '2';      
       
     ELSIF V_STARTERCARD_FLAG = '1' THEN  --GPR Card present  
     
        IF V_CARD_STAT = '0' THEN --GPR Card not activated
          P_STATUS := '1';         
        
        ELSIF v_gpresign_optinflag = '0' THEN
         
         P_STATUS := '3';   -- Active GPR Card and GPR T& C not accpted. 
        ELSE
         P_STATUS := '0';        
         
        END IF;
       
     ELSE
                
      IF V_GPR_FLAG > 1 THEN
      
          SELECT count(CAP_CARD_STAT) INTO V_CARD_STAT
          FROM CMS_APPL_PAN
          WHERE CAP_CUST_CODE=V_CUST_CODE AND UPPER(CAP_STARTERCARD_FLAG) = 'N'         
          AND CAP_INST_CODE=P_INST_CODE AND CAP_CARD_STAT ='0';
        
           IF V_CARD_STAT <> '0' THEN 
              P_STATUS := '1';        
                     
           ELSIF v_gpresign_optinflag = '0' THEN
         
           P_STATUS := '3';   -- Active GPR Card and GPR T& C not accpted. 
           ELSE                       
              P_STATUS := '0';   
           END IF;
      
      ELSE
      
         V_RESP_CDE := '160'; 
         V_ERRMSG  := 'Customer have more than one GPR card';      
         RAISE EXP_REJECT_RECORD;     
      
      END IF;
               
     END IF;



  



IF v_spending_acct_dtl IS NOT NULL THEN

IF v_saving_acct_dtl IS NOT NULL THEN

V_ERRMSG:=V_ERRMSG || '||' || v_masked_pan||'~'||v_spending_acct_dtl;

ELSE

V_ERRMSG:= v_masked_pan||'~'||v_spending_acct_dtl;

END IF;
END IF;


IF v_saving_acct_dtl IS NULL AND v_spending_acct_dtl IS NULL THEN

V_ERRMSG:=' ';

END IF; 
    
    V_RESP_CDE := 1;
     --ST Get responce code from master
        BEGIN
          SELECT CMS_ISO_RESPCDE
          INTO V_RESP_CDE
          FROM CMS_RESPONSE_MAST
          WHERE CMS_INST_CODE      = P_INST_CODE
          AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
          AND CMS_RESPONSE_ID      = V_RESP_CDE;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             V_RESP_CDE := '89';
             V_ERRMSG := 'Responce code not found '||P_RESP_CODE;
             RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          V_RESP_CDE := '89'; ---ISO MESSAGE FOR DATABASE ERROR
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 200);
        END;
      --En Get responce code fomr master

P_RESP_CODE := V_RESP_CDE;
     
    P_RESMSG    := V_ERRMSG;
   P_AUTH_ID    := V_AUTH_ID;
--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION

WHEN EXP_REJECT_RECORD THEN
ROLLBACK;-- TO V_AUTH_SAVEPOINT;
    
   --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = V_RESP_CDE;

        EXCEPTION     
        
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '89';
     END;
  --En Get responce code fomr master

     --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      IF v_prod_code IS NULL THEN
        BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO v_cardstat, v_prod_code, v_card_type, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (p_pan_code);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;
      
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_balance, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;      
      


      IF v_dr_cr_flag IS NULL THEN
        BEGIN
        SELECT ctm_credit_debit_flag,
               TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_type,
               ctm_tran_desc
          INTO v_dr_cr_flag,
               v_txn_type, v_tran_type,
               v_trans_desc
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;        
      --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
	  
IF V_audit_flag = 'T' THEN 
      
  --Sn Inserting data in transactionlog
    BEGIN

        INSERT INTO TRANSACTIONLOG(MSGTYPE,
                     RRN,
                     DELIVERY_CHANNEL,
                     DATE_TIME,
                     TXN_CODE,
                     TXN_TYPE,
                     TXN_MODE,
                     TXN_STATUS,
                     RESPONSE_CODE,
                     BUSINESS_DATE,
                     BUSINESS_TIME,
                     CUSTOMER_CARD_NO,
                     INSTCODE,
                     CUSTOMER_CARD_NO_ENCR,
                     ERROR_MSG,
                      ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                     TRANS_DESC,
                     RESPONSE_id,
                     TIME_STAMP, -- Added for regarding FSS-1144
                      productid,
                     categoryid,
                     cr_dr_flag,
                     acct_balance,
                     ledger_balance,
                     acct_type
                     )
              VALUES(P_MSG,
                     P_RRN,
                     P_DELIVERY_CHANNEL,
                     SYSDATE,
                     P_TXN_CODE,
                     V_TXN_TYPE,
                     P_TXN_MODE,
                     'F',
                     P_RESP_CODE,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN,
                     P_INST_CODE,
                     V_ENCR_PAN_FROM,
                     V_ERRMSG,
                      SYSDATE,
                     1,
                     V_CARDSTAT, --Added CARDSTATUS insert in transactionlog by srinivasu.k
                     V_TRANS_DESC ,
                      V_RESP_CDE,
                     V_TIME_STAMP, --Added for regarding FSS-1144
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     v_acct_balance,
                     v_ledger_bal,
                     v_acct_type
                     );
       EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE := '89';
        V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
        RAISE EXP_REJECT_RECORD;
     END;
  --En Inserting data in transactionlog

  --Sn Inserting data in transactionlog dtl
     BEGIN

          INSERT INTO CMS_TRANSACTION_LOG_DTL
            (
              CTD_DELIVERY_CHANNEL,
              CTD_TXN_CODE,
              CTD_TXN_TYPE,
              CTD_TXN_MODE,
              CTD_BUSINESS_DATE,
              CTD_BUSINESS_TIME,
              CTD_CUSTOMER_CARD_NO,
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_INS_USER,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
               CTD_ADDR_VERIFY_RESPONSE,
                      CTD_MOBILE_NUMBER, 
                      CTD_DEVICE_ID,     
              CTD_USER_NAME,      
              CTD_HASHKEY_ID        
            )
            VALUES
            (
              P_DELIVERY_CHANNEL,
              P_TXN_CODE,
              V_TXN_TYPE,
              P_TXN_MODE,
              P_TRAN_DATE,
              P_TRAN_TIME,
              V_HASH_PAN,
              NULL,
              NULL,
              NULL,
              NULL,
              'E',
              V_ERRMSG,
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              1,
              V_ENCR_PAN_FROM,
              '000',
              '',
              '',
               P_MOBILE_NO,    
             P_DEVICE_ID, 
             v_user_name,              
             V_HASHKEY_ID     
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 200
          )
          ;
          P_RESP_CODE := '89';
          RETURN;
        END;
		
	ELSIF V_audit_flag = 'A'
      THEN 
	
		BEGIN
         
		 VMSCMS.VMS_LOG.LOG_TRANSACTIONLOG_AUDIT(P_MSG,
												 P_RRN,
												 P_DELIVERY_CHANNEL,
												 P_TXN_CODE,                                     
												 '0',   
												 P_TRAN_DATE,    
												 P_TRAN_TIME,   
												 '00',  
												 P_PAN_CODE,
												 V_ERRMSG,
												 0,
												 NULL,
												 P_RESP_CODE,
												 P_CURR_CODE,
												 NULL,
												 NULL,   
												 P_RESMSG,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 CASE WHEN P_RESP_CODE = '00' THEN  'C' ELSE 'F' END,
                                                 NULL,
                                                 NULL);
			 EXCEPTION
				 WHEN OTHERS
				 THEN
					P_RESP_CODE := '69';
					V_ERRMSG :=
						  'Erorr while inserting to audit transaction log '
					   || SUBSTR (SQLERRM, 1, 300);
      END; 
		END IF;

P_RESMSG    := V_ERRMSG;
--Sn Handle OTHERS Execption
WHEN EXP_AUTH_REJECT_RECORD THEN
    P_RESMSG    := V_ERRMSG;
IF v_audit_flag = 'T' THEN
     BEGIN
	 
			    --Added for VMS-5739/FSP-991
			   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			   INTO   v_Retperiod 
			   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
			   WHERE  OPERATION_TYPE='ARCHIVE' 
			   AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
               v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
		
		IF (v_Retdate>v_Retperiod) THEN	                                              --Added for VMS-5739/FSP-991
		
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET CTD_USER_NAME=v_user_name,
              CTD_MOBILE_NUMBER=P_MOBILE_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE 
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			  
		ELSE
		
		      UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST                   --Added for VMS-5739/FSP-991
              SET CTD_USER_NAME=v_user_name,
              CTD_MOBILE_NUMBER=P_MOBILE_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE 
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
		
		
		END IF;
              
             IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
             END IF;    
             EXCEPTION
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
            END; 
END IF;
       --En Updtated transactionlog For regarding FSS-1144

 WHEN OTHERS THEN
     V_RESP_CDE := '21';
      V_ERRMSG := 'Main Exception '||SQLCODE||'---'||SUBSTR(SQLERRM, 1, 200);
      ROLLBACK;-- TO V_AUTH_SAVEPOINT;

    --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = V_RESP_CDE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 200);
          P_RESP_CODE := '89';
     END;
   --En Get responce code fomr master
   

      IF v_prod_code IS NULL THEN
        BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO v_cardstat, v_prod_code, v_card_type, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (p_pan_code);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;
      
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_balance, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;      
      

      IF v_dr_cr_flag IS NULL THEN
        BEGIN
        SELECT ctm_credit_debit_flag,
               TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_type,
               ctm_tran_desc
          INTO v_dr_cr_flag,
               v_txn_type, v_tran_type,
               v_trans_desc
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;        
      --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
	  
IF V_audit_flag = 'T' THEN 

   --Sn Inserting data in transactionlog
      BEGIN
          INSERT INTO TRANSACTIONLOG(MSGTYPE,
                       RRN,
                       DELIVERY_CHANNEL,
                       DATE_TIME,
                       TXN_CODE,
                       TXN_TYPE,
                       TXN_MODE,
                       TXN_STATUS,
                       RESPONSE_CODE,
                       BUSINESS_DATE,
                       BUSINESS_TIME,
                       CUSTOMER_CARD_NO,
                       INSTCODE,
                       CUSTOMER_CARD_NO_ENCR,
                        ERROR_MSG,
                       ADD_INS_DATE,
                       ADD_INS_USER,
                       CARDSTATUS,
                       TRANS_DESC,
                       RESPONSE_id,
                       TIME_STAMP,  -- Added for regarding FSS-1144
                       productid,
                       categoryid,
                       cr_dr_flag,
                       acct_balance,
                       ledger_balance,
                       acct_type
                       )
                VALUES(P_MSG,
                       P_RRN,
                       P_DELIVERY_CHANNEL,
                       SYSDATE,
                       P_TXN_CODE,
                       V_TXN_TYPE,
                       P_TXN_MODE,
                       'F',
                       P_RESP_CODE,
                       P_TRAN_DATE,
                       P_TRAN_TIME,
                       V_HASH_PAN,
                       P_INST_CODE,
                       V_ENCR_PAN_FROM,
                       V_ERRMSG,
                       SYSDATE,
                       1,
                       V_CARDSTAT,
                       V_TRANS_DESC,
                        V_RESP_CDE,
                       V_TIME_STAMP, -- Added  for regarding FSS-1144
                        v_prod_code,
                       v_card_type,
                       v_dr_cr_flag,
                       v_acct_balance,
                       v_ledger_bal,
                       v_acct_type
                       );
         EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE := '89';
            V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
         END;
     --En Inserting data in transactionlog

     --Sn Inserting data in transactionlog dtl
       BEGIN
          INSERT  INTO CMS_TRANSACTION_LOG_DTL
            (
              CTD_DELIVERY_CHANNEL,
              CTD_TXN_CODE,
              CTD_TXN_TYPE,
              CTD_TXN_MODE,
              CTD_BUSINESS_DATE,
              CTD_BUSINESS_TIME,
              CTD_CUSTOMER_CARD_NO,
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_INS_USER,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
              CTD_ADDR_VERIFY_RESPONSE,
              CTD_MOBILE_NUMBER, 
                       CTD_DEVICE_ID,     
                      CTD_USER_NAME ,     
                CTD_HASHKEY_ID     --Added  by Ravi N for regarding Fss-1144
            )
            VALUES
            (
              P_DELIVERY_CHANNEL,
              P_TXN_CODE,
              V_TXN_TYPE,
              P_TXN_MODE,
              P_TRAN_DATE,
              P_TRAN_TIME,
              V_HASH_PAN,
              NULL,
              NULL,
              NULL,
              NULL,
             'E',
              V_ERRMSG,
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              1,
              V_ENCR_PAN_FROM,
              '000',
              '',
              '',
                       P_MOBILE_NO,    
             P_DEVICE_ID, 
            v_user_name,
             V_HASHKEY_ID  
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 200
          )
          ;
          P_RESP_CODE := '89';
          RETURN;
      END;
	  ELSIF V_audit_flag = 'A'
      THEN 
	
		BEGIN
         
		 VMSCMS.VMS_LOG.LOG_TRANSACTIONLOG_AUDIT(P_MSG,
												 P_RRN,
												 P_DELIVERY_CHANNEL,
												 P_TXN_CODE,                                     
												 '0',   
												 P_TRAN_DATE,    
												 P_TRAN_TIME,   
												 '00',  
												 P_PAN_CODE,
												 V_ERRMSG,
												 0,
												 NULL,
												 P_RESP_CODE,
												 P_CURR_CODE,
												 NULL,
												 NULL,   
												 P_RESMSG,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 CASE WHEN P_RESP_CODE = '00' THEN  'C' ELSE 'F' END,
                                                 NULL,
                                                 NULL);
			 EXCEPTION
				 WHEN OTHERS
				 THEN
					P_RESP_CODE := '69';
					V_ERRMSG :=
						  'Erorr while inserting to audit transaction log '
					   || SUBSTR (SQLERRM, 1, 300);
      END; 
		END IF;
      P_RESMSG    := V_ERRMSG;
    --En Inserting data in transactionlog dtl
 --En Handle OTHERS Execption

END;
/
show error