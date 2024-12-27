create or replace
PROCEDURE       VMSCMS.SP_USER_AUTHENTICATION(
                          P_INST_CODE                IN  NUMBER ,
                          P_CUSTOMERID               IN  NUMBER,
                          P_PAN_CODE                 IN  VARCHAR2,
                          P_DELIVERY_CHANNEL         IN  VARCHAR2,
                          P_TXN_CODE                 IN  VARCHAR2,     
                          P_RRN                      IN  VARCHAR2,
                          P_USERNAME                 IN  VARCHAR2,
                          P_PASSWORD                 IN  VARCHAR2,
                          P_TXN_MODE                 IN  VARCHAR2,
                          P_TRAN_DATE                IN  VARCHAR2,
                          P_TRAN_TIME                IN  VARCHAR2,
                          P_IPADDRESS                IN  VARCHAR2,
                          P_CURR_CODE                IN  VARCHAR2,
                          P_RVSL_CODE                IN  VARCHAR2,
                          P_BANK_CODE                IN  VARCHAR2,
                          P_MSG                      IN  VARCHAR2,
                          P_APPL_ID                  IN  VARCHAR2,     
                          P_RESP_CODE                OUT VARCHAR2,
                          P_RESMSG                   OUT VARCHAR2,
                          P_STATUS                   OUT VARCHAR2,
                          P_SAVINGS_FLAG             OUT VARCHAR2,      
                          P_savingacct_creation_date out VARCHAR2       
                          )  

AS
/*****************************************************************************************
     * Created Date     : 04-Apr-2012
     * Created By       : Ramesh.A
     * PURPOSE          : User Authentication and Getting Customer using Username
     * Modified By      : B.Besky
     * Modified Date    : 08-nov-12
     * Modified Reason  : Logging Customer Account number in to transactionlog table.
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 19-nov-12
     * Release Number   : CMS3.5.1_RI0022_B0002

      * Modified By       : Sachin P.
       * Modified Date    : 26-Feb-2013
       *Modified for      : Defect 10503
       * Modified Reason  : Remove SQLERRM for proper error message
       * Reviewer         : Dhiraj
       * Reviewed Date    :
       * Build Number     : CMS3.5.1_RI0023.2_B0010
     
     * modified by       : RAVI N
     * modified Date     : 12-AUG-13
     * modified reason   : UserName  logging cms_transaction_log_dtl
     * modified reason   : FSS-1144
     * Reviewer          : Dhiraj
     * Reviewed Date     : 12-SEP-2013
     * Build Number      : RI0024.4_B0009 
     
     * Modified By       : Sai Prasad
     * Modified Date     : 11-Sep-2013
     * Modified For      : Mantis ID: 0012278 (JIRA FSS-1144)
     * Modified Reason   : IP Address is not logged in transactionlog table.
     * Reviewer          : Dhiraj
     * Reviewed Date     : 12-SEP-2013
     * Build Number      : RI0024.4_B0010 

     * Modified By      : Pankaj S.
     * Modified Date    : 12-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : 
       
     * Modified By      :Abdul Hameed M.A
     * Modified Date    : 02-Apr-2014
     * Modified Reason  : To return  saving acct creation date.
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 03-APR-2014
     * Build Number     : CMS3.5.1_RI0027.1.2_B0001
     
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
********************************************************************************************/

V_RRN_COUNT             NUMBER;
V_ERRMSG                TRANSACTIONLOG.ERROR_MSG%TYPE;
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_CUST_CODE             CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
V_HASH_PASSWORD         CMS_CUST_MAST.CCM_PASSWORD_HASH%TYPE;
V_CARD_EXPRY            VARCHAR2(20);
V_STAN                  CMS_TRANSACTION_LOG_DTL.CTD_SYSTEM_TRACE_AUDIT_NO%TYPE;
V_CAPTURE_DATE          TRANSACTIONLOG.DATE_TIME%TYPE;
V_TERM_ID               TRANSACTIONLOG.TERMINAL_ID%TYPE;
V_MCC_CODE              TRANSACTIONLOG.MCCODE%TYPE;
V_TXN_AMT               CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
V_ACCT_NUMBER           cms_appl_pan.cap_acct_no%TYPE;       
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_CUST_ID               CMS_CUST_MAST.CCM_CUST_ID%TYPE;
V_STARTERCARD_FLAG      CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE;
V_CARD_STAT             CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
V_COUNT                 NUMBER;
V_DR_CR_FLAG            CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;  
V_OUTPUT_TYPE           CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
V_TRAN_TYPE             CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
V_ACCT_TYPE             CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
V_SWITCH_ACCT_TYPE      CMS_ACCT_TYPE.CAT_SWITCH_TYPE%TYPE DEFAULT '22';
V_TRANS_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;     
V_HASHKEY_ID            CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; 
V_TIME_STAMP            TRANSACTIONLOG.TIME_STAMP%TYPE;                                  
v_prod_code             cms_appl_pan.cap_prod_code%type;
v_card_type             cms_appl_pan.cap_card_type%type;
v_acct_balance          cms_acct_mast.cam_acct_bal%TYPE;
v_ledger_bal            cms_acct_mast.cam_ledger_bal%TYPE;
v_resp_cde              transactionlog.response_id%TYPE;
V_ENCRYPT_ENABLE        CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
v_encr_username         cms_cust_mast.CCM_USER_NAME%type;
v_savingacct_creation_date  varchar2(8);                             
EXP_AUTH_REJECT_RECORD  EXCEPTION;
EXP_REJECT_RECORD       EXCEPTION;
v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991

--Main Begin Block Starts Here
BEGIN
   V_TXN_TYPE := '1';
    V_TIME_STAMP :=SYSTIMESTAMP; 

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


  BEGIN
    SELECT CAP_ACCT_NO,
           cap_prod_code,cap_card_type,cap_card_stat,cap_cust_code   
    INTO V_ACCT_NUMBER,
         v_prod_code,v_card_type,v_card_stat,v_cust_code  
    FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '21';
     V_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
      RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21';
     V_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
     RAISE EXP_REJECT_RECORD;
  END;
        
  BEGIN
      SELECT upper(CPC_ENCRYPT_ENABLE)
        INTO V_ENCRYPT_ENABLE
        FROM CMS_PROD_CATTYPE
       WHERE CPC_INST_CODE = P_INST_CODE AND CPC_CARD_TYPE = V_CARD_TYPE AND
             CPC_PROD_CODE =v_prod_code;

    EXCEPTION
         WHEN NO_DATA_FOUND THEN
              P_RESP_CODE := '16'; 
              V_ERRMSG  := 'encrypt details not found for prod code and card type
	                      ' || v_prod_code ||'and ' ||v_card_type;
              RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
              P_RESP_CODE := '12';
              V_ERRMSG  := 'Problem while selecting card encrypting detail' ||
               SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
  END; 
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
       P_RESP_CODE := '12'; 
       V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '21'; 
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
	       V_ERRMSG  := 'Problem while selecting RRN Count from transactionlog ' ||
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

         --Sn Check Delivery Channel
          IF P_DELIVERY_CHANNEL NOT IN ('10') THEN
            V_ERRMSG  := 'Not a valid delivery channel  for ' ||
                 ' User Authentication';
            P_RESP_CODE := '21'; ---ISO MESSAGE FOR DATABASE ERROR
            RAISE EXP_REJECT_RECORD;
          END IF;
        --En Check Delivery Channel

          --Sn Check transaction code
          IF P_TXN_CODE NOT IN ('24') THEN
            V_ERRMSG  := 'Not a valid transaction code for ' ||
                 ' User Authentication';
            P_RESP_CODE := '21'; 
            RAISE EXP_REJECT_RECORD;
          END IF;
        --En check transaction code


       --Sn Get the HashPassword
       BEGIN
          V_HASH_PASSWORD := GETHASH(trim(P_PASSWORD));
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting password ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashPassword

     IF  v_encrypt_enable = 'Y' THEN
           v_encr_username:= fn_emaps_main(upper(trim(p_username)));
       ELSE
           v_encr_username:= upper(trim(p_username));
     END IF;

       BEGIN
       
       SELECT COUNT(1) INTO V_COUNT
       FROM CMS_CUST_MAST
       WHERE CCM_INST_CODE=P_INST_CODE
       AND CCM_CUST_CODE = V_CUST_CODE       
       AND UPPER(CCM_USER_NAME)=v_encr_username 
       AND CCM_PASSWORD_HASH=V_HASH_PASSWORD
       AND CCM_APPL_ID =P_APPL_ID  ;
       
--       WHERE UPPER(CCM_USER_NAME)=v_encr_username AND CCM_PASSWORD_HASH=V_HASH_PASSWORD
--       AND CCM_INST_CODE=P_INST_CODE
--       /* Start CR014 Changes Dhiraj GAikwad 04092012*/
--           AND CCM_APPL_ID =P_APPL_ID  ;
--           /* End CR014 Changes Dhiraj GAikwad 04092012*/
 

        IF V_COUNT = 0 THEN  
         P_RESP_CODE := '114';
         V_ERRMSG  := 'Invalid Username or Password ';  
          RAISE EXP_REJECT_RECORD;  
        END IF;

        EXCEPTION
         WHEN EXP_REJECT_RECORD THEN  
          RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error from while Authenticate user ' ||
                SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;

       END;
      --End User Authentication

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
                P_CURR_CODE,
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

    --St  User Authentication  whether the permanent GPR card has been activated or not.

     BEGIN

       SELECT 
       --CCM_CUST_CODE ,                
       CCM_CUST_ID 
       INTO 
       --V_CUST_CODE ,                   
       V_CUST_ID
       FROM CMS_CUST_MAST
       WHERE CCM_INST_CODE=P_INST_CODE
       AND CCM_CUST_CODE = V_CUST_CODE; 
       
--       UPPER(CCM_USER_NAME)=v_encr_username AND CCM_PASSWORD_HASH=V_HASH_PASSWORD
--       AND CCM_INST_CODE=P_INST_CODE
--        /* Start CR014 Changes Dhiraj GAikwad 04092012*/
--           AND CCM_APPL_ID =P_APPL_ID  ;
--           /* End CR014 Changes Dhiraj GAikwad 04092012*/

      EXCEPTION
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error from while selecting customer id ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

     END;

    BEGIN
      SELECT COUNT(1)  --Updated by ramesh.a for checking flag
      INTO V_STARTERCARD_FLAG
      FROM CMS_APPL_PAN
      WHERE CAP_CUST_CODE=V_CUST_CODE AND UPPER(CAP_STARTERCARD_FLAG) = 'N'
      AND CAP_INST_CODE=P_INST_CODE AND CAP_CARD_STAT <>9;

     --St Added by ramesh.a for checking flag
      IF V_STARTERCARD_FLAG = '1' THEN

          SELECT CAP_CARD_STAT INTO V_CARD_STAT
          FROM CMS_APPL_PAN
          WHERE CAP_CUST_CODE=V_CUST_CODE AND UPPER(CAP_STARTERCARD_FLAG) = 'N'
          AND CAP_INST_CODE=P_INST_CODE AND CAP_CARD_STAT <>9;

      END IF;
      --En Added by ramesh.a for checking flag

       EXCEPTION
       WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'No data found while selecting STARTERCARD STATUS ' ||
              SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
         WHEN TOO_MANY_ROWS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'TOO MANY ROWS found while selecting STARTERCARD STATUS ' ||
              SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error from while selecting STARTERCARD STATUS ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;
    -- St For savings account flag
         --Sn select acct type
          BEGIN
            SELECT CAT_TYPE_CODE
            INTO V_ACCT_TYPE
            FROM CMS_ACCT_TYPE
            WHERE CAT_INST_CODE = P_INST_CODE AND
            CAT_SWITCH_TYPE = V_SWITCH_ACCT_TYPE;

             EXCEPTION
               WHEN NO_DATA_FOUND THEN
               P_RESP_CODE := '21';
               V_ERRMSG := 'Acct type not defined in master';
               RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
               P_RESP_CODE := '12';
               V_ERRMSG := 'Error while selecting accttype ' ||SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
          END;
        --En select acct type



         --Sn check whether the Saving Account already created or not
         BEGIN
           SELECT 
           to_char(CAM_CREATION_DATE,'MMDDYYYY') INTO v_savingacct_creation_date 
           FROM CMS_ACCT_MAST
           WHERE cam_acct_id in( SELECT cca_acct_id FROM CMS_CUST_ACCT
           where cca_cust_code=V_CUST_CODE and cca_inst_code=P_INST_CODE) and cam_type_code=V_ACCT_TYPE
           AND CAM_INST_CODE=P_INST_CODE;
            V_COUNT := 1;
            P_savingacct_creation_date:=v_savingacct_creation_date;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                V_COUNT:=0;
               WHEN OTHERS THEN
               P_RESP_CODE := '12';
               V_ERRMSG := 'Error while selecting acct  ' ||SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

         END;
      P_RESP_CODE := 1;
      V_ERRMSG := 'USER AUTHENTICATION SUCCESS';
      P_RESMSG := V_CUST_ID;
      P_SAVINGS_FLAG := V_COUNT; 

      IF V_STARTERCARD_FLAG = '0' THEN     --GPR Card not present  -- Modified by ramesh.a for checking 0 instead of 'Y'

       V_ERRMSG :=V_ERRMSG ||' GPR Card Not present ';
       P_STATUS := '2';

     ELSIF V_STARTERCARD_FLAG = '1' THEN  --GPR Card present  -- Modified by ramesh.a for checking 1 instead of 'N'

        IF V_CARD_STAT = '0' THEN --GPR Card not activated
          P_STATUS := '1';
          V_ERRMSG :=V_ERRMSG || ' status : '||V_CARD_STAT;

        ELSE        
 
         P_STATUS := '0';
         V_ERRMSG :=V_ERRMSG || ' status : '||V_CARD_STAT;

        END IF;

     ELSE
          P_RESP_CODE := '160';
          V_ERRMSG  := 'Customer have more than one GPR card';       
         RAISE EXP_REJECT_RECORD;

     END IF;
    -- End Modified by ramesh.a on 09/04/2012

    --En  User Authentication  whether the permanent GPR card has been activated or not.


     --ST Get responce code fomr master
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
          SET 
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               IPADDRESS = P_IPADDRESS -- Added for mantis id 0012278 (FSS-1144)
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
ELSE
		UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          SET 
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               IPADDRESS = P_IPADDRESS -- Added for mantis id 0012278 (FSS-1144)
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

    -- TransactionLog  has been removed by ramesh on 12/03/2012

           
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
              SET CTD_USER_NAME= v_encr_username
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE 
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
ELSE
			UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991
              SET CTD_USER_NAME= v_encr_username
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
        
   --End Updated transaction log  for regarding  FSS-1144           
 

--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION
WHEN EXP_AUTH_REJECT_RECORD THEN  

P_RESMSG:=V_ERRMSG; 

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
	      SET CTD_USER_NAME= v_encr_username
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE 
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			  
ELSE
			 UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991
	      SET CTD_USER_NAME= v_encr_username
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
        
   --End Updated transaction log  for regarding  FSS-1144           

WHEN EXP_REJECT_RECORD THEN
 ROLLBACK;-- TO V_AUTH_SAVEPOINT;
 
     v_resp_cde:=P_RESP_CODE;
 
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
  
    
    IF v_prod_code IS NULL THEN
    BEGIN
        SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
          INTO v_card_stat, v_prod_code, v_card_type, v_acct_number
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
       WHEN OTHERS
       THEN
          v_acct_balance := 0;
          v_ledger_bal := 0;
    END;

    IF v_dr_cr_flag IS NULL THEN
    BEGIN
       SELECT ctm_credit_debit_flag,
           TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc
      INTO v_dr_cr_flag,
           v_txn_type, v_trans_desc
      FROM cms_transaction_mast
     WHERE ctm_tran_code = p_txn_code
       AND ctm_delivery_channel = p_delivery_channel
       AND ctm_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
    END IF; 

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
                     CARDSTATUS,
                     TRANS_DESC,
                     RESPONSE_id,
                     TIME_STAMP,  
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
                      V_ACCT_NUMBER,  
                     V_ERRMSG,
                     P_IPADDRESS,
                     SYSDATE,
                     1,
                     V_CARD_STAT,
                     V_TRANS_DESC,
                     v_resp_cde,
                     V_TIME_STAMP,   
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     v_acct_balance,
                     v_ledger_bal,
                     v_acct_type
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
              v_acct_number, 
              '',
              v_encr_username, 
              V_HASHKEY_ID 
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

--Sn Handle OTHERS Execption
 WHEN OTHERS THEN
      P_RESP_CODE := '21';
      V_ERRMSG := 'Main Exception '||SQLCODE||'---'||SQLERRM;
      ROLLBACK;-- TO V_AUTH_SAVEPOINT;
      v_resp_cde:=P_RESP_CODE; 
      
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
   
   --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)     
    IF v_prod_code IS NULL THEN
    BEGIN
        SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
          INTO v_card_stat, v_prod_code, v_card_type, v_acct_number
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
       WHEN OTHERS
       THEN
          v_acct_balance := 0;
          v_ledger_bal := 0;
    END;

    IF v_dr_cr_flag IS NULL THEN
    BEGIN
       SELECT ctm_credit_debit_flag,
           TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_desc
      INTO v_dr_cr_flag,
           v_txn_type, v_trans_desc
      FROM cms_transaction_mast
     WHERE ctm_tran_code = p_txn_code
       AND ctm_delivery_channel = p_delivery_channel
       AND ctm_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
    END IF; 
    --En Added by Pankaj S. for logging changes(Mantis ID-13160)  

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
                       CARDSTATUS,
                       TRANS_DESC,
                       RESPONSE_id,
                       TIME_STAMP,   
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
                      V_ACCT_NUMBER,  
                       V_ERRMSG,
                       P_IPADDRESS,
                       SYSDATE,
                       1,
                       V_CARD_STAT,
                       V_TRANS_DESC,
                       v_resp_cde,
                       V_TIME_STAMP,    
                       v_prod_code,
                       v_card_type,
                       v_dr_cr_flag,
                       v_acct_balance,
                       v_ledger_bal,
                       v_acct_type
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
              CTD_USER_NAME ,    
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
              v_acct_number, 
              '',
              v_encr_username,
              V_HASHKEY_ID                          
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
 --En Handle OTHERS Execption

END;
/
show error;