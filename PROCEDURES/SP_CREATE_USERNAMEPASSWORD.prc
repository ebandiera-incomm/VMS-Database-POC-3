create or replace PROCEDURE        VMSCMS.SP_CREATE_USERNAMEPASSWORD(
                          P_INST_CODE         IN   NUMBER ,
                          P_CUSTOMERID        IN   NUMBER,
                          P_PAN_CODE          IN   VARCHAR2,
                          P_DELIVERY_CHANNEL  IN   VARCHAR2,
                          P_TXN_CODE          IN   VARCHAR2,   --Modified by Srinivasu from Number to Varchar
                          P_RRN               IN   VARCHAR2,
                          P_USERNAME          IN   VARCHAR2,
                          P_PASSWORD          IN   VARCHAR2,
                          P_SECQUEST1         IN   VARCHAR2,
                          P_SECQUEST2         IN   VARCHAR2,
                          P_SECQUEST3         IN   VARCHAR2,
                          P_SECQUEST1ANS      IN   VARCHAR2,
                          P_SECQUEST2ANS      IN   VARCHAR2,
                          P_SECQUEST3ANS      IN   VARCHAR2,
                          P_TXN_MODE          IN   VARCHAR2,
                          P_TRAN_DATE         IN   VARCHAR2,
                          P_TRAN_TIME         IN   VARCHAR2,
                          P_IPADDRESS         IN   VARCHAR2,                             
                          P_CURR_CODE         IN   VARCHAR2,  
                          P_RVSL_CODE         IN   VARCHAR2, 
                          P_BANK_CODE         IN   VARCHAR2,
                          P_MSG               IN   VARCHAR2,
                          P_APPL_ID           IN   VARCHAR2 ,   --Added for CR014 Changes Dhiraj GAikwad 04092012
                          P_DEVICE_MOBILE_NO  IN   VARCHAR2,    --Added on 27-Mar-2014 by Dinesh B for MOB-62 
                          P_DEVICE_ID         IN   VARCHAR2,    --Added on 27-Mar-2014 by Dinesh B for MOB-62 
                          P_RESP_CODE         OUT  VARCHAR2 ,
                          P_RESMSG            OUT  VARCHAR2)

AS
/*************************************************
    * Created Date      :  30-Mar-2012
    * Created By        :  Ramesh.A
    * PURPOSE           :  Creating  Username & Pasword and Security Questions , Answers stored.      
    * modified by       :  B.Besky
    * modified Date     :  06-NOV-12
    * modified reason   :  Changes in Exception handling
    * Reviewer          :  Saravanakumar
    * Reviewed Date     :  06-NOV-12
    * Build Number      :  CMS3.5.1_RI0021

    * Modified by       :  Sachin P.
    * Modified for      :  MVHOST-474
    * Modified Reason   :  VMS Not Pulling Source IP Address                 
    * Modified Date     :  22-Jul-2013
    * Reviewer          :  Sagar
    * Reviewed Date     :  23-Jul-2013
    * Build Number      :  RI0024.3_B0006  
    
    * modified by       :  RAVI N
    * modified Date     :  09-AUG-13
    * modified reason   :  logging P_USERNAME in cms_transaction_log_dtl
    * modified reason   :  FSS-1144
    * Reviewer          :  Dhiraj
    * Reviewed Date     :  30-Aug-2013
    * Build Number      :  RI0024.4_B0006  
    
    * Modified Date    : 10-Dec-2013
    * Modified By      : Sagar More
    * Modified for     : Defect ID 13160
    * Modified reason  : To log below details in transactinlog if applicable
                         productcode,categoryid,dr_cr_dlag
    * Reviewer         : Dhiraj
    * Reviewed Date    : 10-Dec-2013
    * Release Number   : RI0024.7_B0001  
    
    * Modified Date    : 27-Mar-2014
    * Modified By      : DINESH B
    * Modified for     : MOB-62
    * Modified reason  : Logging mobile number and device id.
    * Reviewer         : Pankaj S
    * Reviewed Date    : 07-Apr-2014
    * Release Number   : RI0024.2_B0004
	
     * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
     
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01
     
     * Modified By      : VINI PUSHKARAN
     * Modified Date    : 01-MAR-2019
     * Purpose          : VMS-809 (Decline Request for Web-account Username if Username is Already Taken)
     * Reviewer         : Saravanakumar A 
     * Release Number   : VMSGPRHOST_R13_B0002   
     
     
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 09-JUL-2019
     * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
     * Reviewer         : Saravana Kumar.A
     * Release Number   : VMSGPRHOST_R18
    
*************************************************/

V_COUNT1                PLS_INTEGER;
V_RRN_COUNT             PLS_INTEGER;
V_ERRMSG                TRANSACTIONLOG.ERROR_MSG%TYPE;
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_SPND_ACCT_NO          CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
V_CUST_NAME             CMS_CUST_MAST.CCM_USER_NAME%TYPE;
V_HASH_PASSWORD         CMS_CUST_MAST.CCM_PASSWORD_HASH%TYPE;
V_HASH_SQA1             CMS_SECURITY_QUESTIONS.CSQ_ANSWER_HASH%TYPE;
V_HASH_SQA2             CMS_SECURITY_QUESTIONS.CSQ_ANSWER_HASH%TYPE;
V_HASH_SQA3             CMS_SECURITY_QUESTIONS.CSQ_ANSWER_HASH%TYPE;
V_CARD_EXPRY            VARCHAR2(20);
V_STAN                  CMS_TRANSACTION_LOG_DTL.CTD_SYSTEM_TRACE_AUDIT_NO%TYPE;
V_CAPTURE_DATE          TRANSACTIONLOG.DATE_TIME%TYPE;
V_TERM_ID               TRANSACTIONLOG.TERMINAL_ID%TYPE;
V_MCC_CODE              TRANSACTIONLOG.MCCODE%TYPE;
V_TXN_AMT               CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
V_ACCT_NUMBER           CMS_STATEMENTS_LOG.CSL_TO_ACCTNO%TYPE;
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_CARDSTAT              CMS_APPL_PAN.CAP_CARD_STAT%TYPE;            --Added by ramesh.a on 10/04/2012
V_CURRCODE              cms_bin_param.cbp_param_value%type;
v_profile_code          cms_prod_cattype.cpc_profile_code%type;
V_DR_CR_FLAG            CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
V_OUTPUT_TYPE           CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
V_TRAN_TYPE             CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
V_TRANS_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;     --Added for transaction detail report on 210812
V_HASHKEY_ID            CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; -- Added  for regarding FSS-1144
V_TIME_STAMP            TRANSACTIONLOG.TIME_STAMP%TYPE;              -- Added  for regarding FSS-1144
v_prod_code             cms_appl_pan.cap_prod_code%type;
v_card_type             cms_appl_pan.cap_card_type%type;
v_acct_type             cms_acct_mast.cam_type_code%type;
v_cap_acct_no           cms_appl_pan.cap_acct_no%type;
v_acct_balance          cms_acct_mast.cam_acct_bal%type;
v_ledger_balance        cms_acct_mast.cam_ledger_bal%type;
V_ENCRYPT_ENABLE        cms_prod_cattype.cpc_ENCRYPT_ENABLE%type;
v_encr_username         cms_cust_mast.CCM_USER_NAME%type;
EXP_AUTH_REJECT_RECORD  EXCEPTION;
EXP_REJECT_RECORD       EXCEPTION;
v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991

BEGIN
   V_TXN_TYPE := '1';

   V_TIME_STAMP :=SYSTIMESTAMP; -- Added for regarding FSS-1144
   
       --Sn Get the HashPan
       BEGIN
          V_HASH_PAN := GETHASH(P_PAN_CODE);
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashPan

      --Sn Create encr pan
        BEGIN
          V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_PAN_CODE);
          EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE     := '12';
            V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;        
      --Start Generate HashKEY value for regarding FSS-1144   
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        P_RESP_CODE := '21';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
   
    --End Generate HashKEY value for regarding FSS-1144
    
    --Sn find debit and credit flag
       
    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,CTM_TRAN_DESC
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       P_RESP_CODE := '12'; --Ineligible Transaction
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
            P_RESP_CODE     := '22';
            V_ERRMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
          END IF; 
       EXCEPTION
	   WHEN EXP_REJECT_RECORD THEN
		   RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while selecting RRN Count from Transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;		  
        END;
       --En Duplicate RRN Check

--      --Sn Get Tran date
--        BEGIN
--          V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
--                  SUBSTR(TRIM(P_TRAN_TIME), 1, 8),
--                  'yyyymmdd hh24:mi:ss');
--          EXCEPTION
--            WHEN OTHERS THEN
--           P_RESP_CODE := '21';
--           V_ERRMSG  := 'Problem while converting transaction date ' ||
--                SUBSTR(SQLERRM, 1, 200);
--           RAISE EXP_REJECT_RECORD;
--        END;
--       --En Get Tran date

        --Sn Get the card details
          BEGIN
              SELECT CAP_CARD_STAT,cap_prod_code,cap_card_type
              INTO V_CARDSTAT,v_prod_code,v_card_type
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '16'; --Ineligible Transaction
                V_ERRMSG  := 'Card number not found ' || P_PAN_CODE;
              RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                P_RESP_CODE := '12';
                V_ERRMSG  := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
          END;
      --End Get the card details    
      
      BEGIN
              SELECT upper(CPC_ENCRYPT_ENABLE),cpc_profile_code
              INTO V_ENCRYPT_ENABLE,v_profile_code
              FROM CMS_PROD_CATTYPE
              WHERE CPC_INST_CODE = P_INST_CODE AND CPC_CARD_TYPE = V_CARD_TYPE AND
              CPC_PROD_CODE =v_prod_code;

              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '16'; --Ineligible Transaction
                V_ERRMSG  := 'no details found for prod code and cardtype ' || v_prod_code ||V_CARD_TYPE;
              RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                P_RESP_CODE := '12';
                V_ERRMSG  := 'Problem while selecting card encrypting detail' ||
                SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
        END; 

        --Sn check whether the Username  already created or not
         BEGIN                     
           
           SELECT nvl(decode(v_encrypt_enable,'Y',fn_dmaps_main(ccm_user_name),ccm_user_name),0) INTO V_CUST_NAME 
           FROM CMS_CUST_MAST 
           WHERE CCM_CUST_ID= P_CUSTOMERID AND CCM_INST_CODE=P_INST_CODE ;
          

           IF V_CUST_NAME <> '0' THEN
           V_ERRMSG := 'Username already created for the customer  ';
           P_RESP_CODE := '112';
           RAISE EXP_REJECT_RECORD;
           END IF;
          
          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
            P_RESP_CODE := '21';
            V_ERRMSG  := 'Error from getting cust name' ||
            SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
         END;
      --En check whether the Username already created or not
      
      --Sn check whether the Username already exists or not
         BEGIN
         
--           IF  v_encrypt_enable = 'Y' THEN 
--              v_encr_username:= fn_emaps_main(upper(trim(p_username)));
--           ELSE
--              v_encr_username:= upper(trim(p_username));
--           END IF;
            
            SELECT COUNT(1)
            INTO V_COUNT1
            FROM CMS_CUST_MAST
            WHERE (UPPER(CCM_USER_NAME)= fn_emaps_main(upper(trim(p_username))) -- Modified because of decline Request for Web-account Username if Username is Already Taken(VMS-809) 
            OR UPPER(CCM_USER_NAME)    = upper(trim(p_username)))
            AND CCM_INST_CODE          = P_INST_CODE -- Updated by Ramesh.A on 06/04/2012
            AND CCM_APPL_ID = P_APPL_ID ;  --Modified for CR014 Changes Dhiraj GAikwad 04092012

          
           
           IF V_COUNT1 <> 0 THEN
             V_ERRMSG := 'Username already exists For this Application ID '; --Message Change CR014 Changes Dhiraj GAikwad 04092012
             P_RESP_CODE := '113';
             RAISE EXP_REJECT_RECORD;
           END IF;

          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
            P_RESP_CODE := '21';
            V_ERRMSG  := 'Error from checking cust name' ||
            SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
         END;
      --En check whether the Username already Username or not
    
       --Sn Get the HashPassword
       BEGIN
          V_HASH_PASSWORD := GETHASH(trim(P_PASSWORD)); -- Updated by Ramesh.A on 06/04/2012
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting password ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashPassword 
      
       --Sn Get the HashSecuriyAnswerOne
       BEGIN
          V_HASH_SQA1 := GETHASH(trim(P_SECQUEST1ANS));  -- Updated by Ramesh.A on 06/04/2012
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting sequrity answer one ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashSecuriyAnswerOne
     
        --Sn Get the HashSecuriyAnswerTwo
       BEGIN
          V_HASH_SQA2 := GETHASH(trim(P_SECQUEST2ANS)); -- Updated by Ramesh.A on 06/04/2012
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting sequrity answer two ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashSecuriyAnswerTwo
     
       --Sn Get the HashSecuriyAnswerThree
       BEGIN
          V_HASH_SQA3 := GETHASH(trim(P_SECQUEST3ANS));
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting sequrity answer three ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashSecuriyAnswerThree
      
     --Added by Deepa on Apr-17-2012 to get the institution currency as currency code 
    --Sn Currency code    
    
    IF TRIM(P_CURR_CODE) IS NULL  THEN 
        BEGIN

            SELECT TRIM(cbp_param_value) 
			INTO V_CURRCODE 
			FROM cms_bin_param 
            WHERE cbp_param_name = 'Currency' AND cbp_inst_code= P_INST_CODE
            AND cbp_profile_code = v_profile_code;
         
           IF V_CURRCODE IS NULL THEN
            V_ERRMSG := 'Base currency cannot be null ';
            P_RESP_CODE     := '21';
            RAISE EXP_REJECT_RECORD;
           END IF;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            V_ERRMSG := 'Base currency is not defined for the bin profile ';
            P_RESP_CODE     := '21';
            RAISE EXP_REJECT_RECORD;
           WHEN OTHERS THEN
           P_RESP_CODE     := '21';
            V_ERRMSG := 'Error while selecting base currency for bin  ' ||
                      SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
         END;
         ELSE
        V_CURRCODE:= P_CURR_CODE;
    END IF;
        
    --En Currency code 
      --Sn call to authorize procedure
      BEGIN
        SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                P_MSG,
                P_RRN,
                P_DELIVERY_CHANNEL,
                V_TERM_ID,
                P_TXN_CODE,
                P_TXN_MODE,
                P_TRAN_DATE,
                P_TRAN_TIME,
                P_PAN_CODE,
                P_BANK_CODE,
                V_TXN_AMT,
                NULL,
                NULL,
                V_MCC_CODE,
                --   P_CURR_CODE,
                V_CURRCODE,--Modified to pass the institution currency
                NULL,
                NULL,
                NULL,
                V_ACCT_NUMBER,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                V_CARD_EXPRY,
                V_STAN,
                '000',
                P_RVSL_CODE,
                V_TXN_AMT,
                V_AUTH_ID,
                P_RESP_CODE,
                V_ERRMSG,
                V_CAPTURE_DATE);
        IF P_RESP_CODE <> '00' AND V_ERRMSG <> 'OK' THEN
         --P_RESP_CODE := '21';
         --V_ERRMSG := 'Error from auth process' || V_ERRMSG;       Commented by Besky on 06-nov-12
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

    --St Username & password with sequrity question link to the customerID
    
     BEGIN
     
            IF  v_encrypt_enable = 'Y' THEN 
               v_encr_username:= fn_emaps_main(upper(trim(p_username)));
             ELSE
               v_encr_username:= trim(p_username);
             END IF;
              
        UPDATE CMS_CUST_MAST 
           SET CCM_USER_NAME=v_encr_username,
               CCM_USER_NAME_ENCR = fn_emaps_main(upper(trim(p_username))),            
               CCM_PASSWORD_HASH=V_HASH_PASSWORD, -- Updated by Ramesh.A on 06/04/2012
               ccm_lupd_date=sysdate, ccm_lupd_user=1 ,     
               CCM_APPL_ID =P_APPL_ID                                               -- Added for CR014 Changes Dhiraj GAikwad 04092012
         WHERE CCM_INST_CODE=P_INST_CODE AND CCM_CUST_ID=P_CUSTOMERID;
      
        IF SQL%ROWCOUNT = 0 THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error while updating username and  password ';
         RAISE EXP_REJECT_RECORD;
        END IF;
         
      EXCEPTION       
       WHEN EXP_REJECT_RECORD THEN      
              RAISE EXP_REJECT_RECORD; 
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error from updating username and  password ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
     
     END;
     
     BEGIN
     
         INSERT INTO cms_security_questions(csq_inst_code,csq_cust_id,csq_question,csq_answer_hash)     
         VALUES(P_INST_CODE,P_CUSTOMERID,trim(P_SECQUEST1),V_HASH_SQA1);
                      
         INSERT INTO cms_security_questions(csq_inst_code,csq_cust_id,csq_question,csq_answer_hash)     
         VALUES(P_INST_CODE,P_CUSTOMERID,trim(P_SECQUEST2),V_HASH_SQA2);
                  
         INSERT INTO cms_security_questions(csq_inst_code,csq_cust_id,csq_question,csq_answer_hash)     
         VALUES(P_INST_CODE,P_CUSTOMERID,trim(P_SECQUEST3),V_HASH_SQA3);
         
      EXCEPTION             
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error from inserting security questions and answers ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
       
     END;
    
    P_RESP_CODE := 1;
    V_ERRMSG := 'Username and password created successfully'; -- Updated by Ramesh.A on 25/05/2012 raised issue on UAT(spelling changes)
    --En Username & password with sequrity question link to the customerID
    

     --ST Get responce code from master
        BEGIN
          SELECT CMS_ISO_RESPCDE
          INTO P_RESP_CODE
          FROM CMS_RESPONSE_MAST
          WHERE CMS_INST_CODE      = P_INST_CODE
          AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
          AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '21';
             V_ERRMSG := 'Responce code not found '||P_RESP_CODE;
             RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          P_RESP_CODE := '69'; ---ISO MESSAGE FOR DATABASE ERROR
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
        END;
      --En Get responce code fomr master
        --Sn Updtated transactionlog For regarding FSS-1144          
                      
            BEGIN
			
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
              UPDATE CMS_TRANSACTION_LOG_DTL               
              SET CTD_USER_NAME= v_encr_username,
              CTD_MOBILE_NUMBER=P_DEVICE_MOBILE_NO, --Added for MOB-62
              CTD_DEVICE_ID=P_DEVICE_ID --Added for MOB-62
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE 
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
ELSE
			UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991               
              SET CTD_USER_NAME= v_encr_username,
              CTD_MOBILE_NUMBER=P_DEVICE_MOBILE_NO, --Added for MOB-62
              CTD_DEVICE_ID=P_DEVICE_ID --Added for MOB-62
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
        --Sn Updtated transactionlog For regarding FSS-1144    
       --Sn update topup card number details in translog
        BEGIN
		--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
          UPDATE TRANSACTIONLOG
          SET  RESPONSE_ID=P_RESP_CODE,
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG =V_ERRMSG,
               IPADDRESS= P_IPADDRESS --Added on 22.07.2013 for MVHOST-474  
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
ELSE
		UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          SET  RESPONSE_ID=P_RESP_CODE,
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG =V_ERRMSG,
               IPADDRESS= P_IPADDRESS --Added on 22.07.2013 for MVHOST-474  
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
END IF;		   

          IF SQL%ROWCOUNT <> 1 THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
           RAISE EXP_REJECT_RECORD;
          END IF;

         EXCEPTION
         WHEN EXP_REJECT_RECORD THEN 
               RAISE EXP_REJECT_RECORD;    
          WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
        END;
     --En update topup card number details in translog

    -- TransactionLog & cms_transaction_log_dtl has been removed by ramesh on 12/03/2012
    P_RESMSG    := V_ERRMSG;
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
        AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '69';
     END;
  --En Get responce code fomr master
  
  --SN -Added for 13160
    
      if V_DR_CR_FLAG is null
      then
      
        BEGIN
         SELECT CTM_CREDIT_DEBIT_FLAG
           INTO V_DR_CR_FLAG
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE AND
               CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
               CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN OTHERS 
         THEN
                null;
        END;
      end if;  
      
      if V_CARDSTAT is null
      then
            
         BEGIN
         
              SELECT CAP_CARD_STAT,cap_prod_code,cap_card_type,cap_acct_no 
              INTO v_cardstat,v_prod_code,v_card_type,v_cap_acct_no
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
              

         EXCEPTION
         WHEN  OTHERS THEN
            null; 
        
         END;
         
      end if;     

            
     BEGIN
         
          select cam_type_code,cam_acct_bal,cam_ledger_bal
          into   v_acct_type,v_acct_balance,v_ledger_balance
          from cms_acct_mast
          where cam_inst_code = p_inst_code
          and   cam_acct_no = v_cap_acct_no;

     EXCEPTION
     WHEN  OTHERS THEN
        null; 
        
     END;
    

   --EN -Added for 13160

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
                     CUSTOMER_ACCT_NO,
                     ERROR_MSG,
                     IPADDRESS,
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                     TRANS_DESC,
                     RESPONSE_ID,
                     TIME_STAMP,   --Added for regarding FSS-1144
                     --added for 13160
                     productid,
                     categoryid,
                     acct_type,
                     cr_dr_flag,
                     acct_balance,
                     ledger_balance
                     --added for 13160
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
                     v_cap_acct_no,--V_SPND_ACCT_NO, modified for 13160
                     V_ERRMSG,
                     P_IPADDRESS,
                     SYSDATE,
                     1,
                     V_CARDSTAT, --Added CARDSTATUS insert in transactionlog by srinivasu.k
                     V_TRANS_DESC,
                     P_RESP_CODE,
                     V_TIME_STAMP,    --Added for regarding FSS-1144
                     --added for 13160
                     v_prod_code,
                     v_card_type,
                     v_acct_type,
                     v_dr_cr_flag,
                     v_acct_balance,
                     v_ledger_balance
                     --added for 13160
                     );
       EXCEPTION
      WHEN OTHERS THEN
        P_RESP_CODE := '12';
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
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,
                       CTD_USER_NAME,     --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144  
              CTD_HASHKEY_ID ,    --Added  by Ravi N for regarding Fss-1144
              CTD_MOBILE_NUMBER, --Added for MOB-62
              CTD_DEVICE_ID   --Added for MOB-62
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
              V_SPND_ACCT_NO,
              '',
             v_encr_username,--P_USERNAME,   --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
             V_HASHKEY_ID,  --Added  by Ravi N for regarding Fss-1144    
             P_DEVICE_MOBILE_NO,  --Added for MOB-62
             P_DEVICE_ID   --Added for MOB-62
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
          RETURN;
        END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption
P_RESMSG    := V_ERRMSG;
--Sn Handle OTHERS Execption
WHEN EXP_AUTH_REJECT_RECORD THEN--Added by Deepa on Apr-17.For AUTH_REJECT eceptions no need of response code selection from response_mast
   --SN Added on 22.07.2013 for MVHOST-474
   BEGIN
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
   UPDATE TRANSACTIONLOG
          SET  ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,               
               IPADDRESS= P_IPADDRESS   
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
ELSE
UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          SET  ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,               
               IPADDRESS= P_IPADDRESS   
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
END IF;		   
           
       IF SQL%ROWCOUNT <> 1 THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                'no valid records ';           
       END IF;     
           
   EXCEPTION   
     WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog  ' ||
                SUBSTR(SQLERRM, 1, 200);       
   END;
   
    --Sn Updtated transactionlog For regarding FSS-1144          
                      
            BEGIN
			--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
              UPDATE CMS_TRANSACTION_LOG_DTL
             -- SET CTD_USER_NAME= P_USERNAME ,
                SET CTD_USER_NAME =v_encr_username,
              CTD_MOBILE_NUMBER=P_DEVICE_MOBILE_NO,--Added for MOB-62
              CTD_DEVICE_ID=P_DEVICE_ID ----Added for MOB-62
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE 
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
ELSE
			UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991
             -- SET CTD_USER_NAME= P_USERNAME ,
                SET CTD_USER_NAME =v_encr_username,
              CTD_MOBILE_NUMBER=P_DEVICE_MOBILE_NO,--Added for MOB-62
              CTD_DEVICE_ID=P_DEVICE_ID ----Added for MOB-62
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
        --Sn Updtated transactionlog For regarding FSS-1144  
   
    --EN Added on 22.07.2013 for MVHOST-474


--En Handle EXP_REJECT_RECORD execption
P_RESMSG    := V_ERRMSG;
 WHEN OTHERS THEN
      P_RESP_CODE := '21';
      V_ERRMSG := 'Main Exception '||SQLCODE||'---'||SQLERRM;
      ROLLBACK;-- TO V_AUTH_SAVEPOINT;

    --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '69';
     END;
   --En Get responce code fomr master
   

--SN -Added for 13160
    
      if V_DR_CR_FLAG is null
      then
      
        BEGIN
         SELECT CTM_CREDIT_DEBIT_FLAG
           INTO V_DR_CR_FLAG
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE AND
               CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
               CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN OTHERS 
         THEN
                null;
        END;
      end if;  
      
      if V_CARDSTAT is null
      then
            
         BEGIN
         
              SELECT CAP_CARD_STAT,cap_prod_code,cap_card_type,cap_acct_no
              INTO v_cardstat,v_prod_code,v_card_type,v_cap_acct_no
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

         EXCEPTION
         WHEN  OTHERS THEN
            null; 
        
         END;
         
      end if;       
      
            
     BEGIN
         
          select cam_type_code,cam_acct_bal,cam_ledger_bal
          into   v_acct_type,v_acct_balance,v_ledger_balance
          from cms_acct_mast
          where cam_inst_code = p_inst_code
          and   cam_acct_no = v_cap_acct_no;

     EXCEPTION
     WHEN  OTHERS THEN
        null; 
        
     END;      

   --EN -Added for 13160
   
   

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
                       CUSTOMER_ACCT_NO,
                       ERROR_MSG,
                       IPADDRESS,
                       ADD_INS_DATE,
                       ADD_INS_USER,
                       CARDSTATUS,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                       TRANS_DESC,
                       RESPONSE_ID,
                       TIME_STAMP,   --Added for regarding FSS-1144
                       --added for 13160
                       productid,
                       categoryid,
                       acct_type,
                       cr_dr_flag,
                       acct_balance,
                       ledger_balance
                      --added for 13160
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
                       v_cap_acct_no,--V_SPND_ACCT_NO, modified for 13160
                       V_ERRMSG,
                       P_IPADDRESS,
                       SYSDATE,
                       1,
                       V_CARDSTAT,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                       V_TRANS_DESC,
                       P_RESP_CODE,
                       V_TIME_STAMP,    --Added for regarding FSS-1144
                        --added for 13160
                        v_prod_code,
                        v_card_type,
                        v_acct_type,
                        v_dr_cr_flag,
                        v_acct_balance,
                        v_ledger_balance
                        --added for 13160
                       );
         EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE := '12';
            V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
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
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,
                       CTD_USER_NAME,     --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144 
              CTD_HASHKEY_ID,     --Added  by Ravi N for regarding Fss-1144
              CTD_MOBILE_NUMBER, --Added for MOB-62
              CTD_DEVICE_ID --Added for MOB-62  
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
              V_SPND_ACCT_NO,
              '',
             v_encr_username,-- P_USERNAME,   --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144  
              V_HASHKEY_ID,  --Added  by Ravi N for regarding Fss-1144    
              P_DEVICE_MOBILE_NO,  --Added for MOB-62
              P_DEVICE_ID   --Added for MOB-62
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
          RETURN;
      END;
      P_RESMSG    := V_ERRMSG;
    --En Inserting data in transactionlog dtl
 --En Handle OTHERS Execption

END;
/
show error;