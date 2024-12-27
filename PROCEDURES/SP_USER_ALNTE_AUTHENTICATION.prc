CREATE OR REPLACE PROCEDURE VMSCMS.SP_USER_ALNTE_AUTHENTICATION (
                          P_INST_CODE         IN NUMBER ,
                          P_PAN_CODE          IN VARCHAR2,
                          P_DELIVERY_CHANNEL  IN  VARCHAR2,
                          P_TXN_CODE          IN VARCHAR2, --Updated  by Siva kumar as on 09/07/2012
                          P_RRN               IN  VARCHAR2,
                          P_TXN_MODE          IN   VARCHAR2,
                          P_TRAN_DATE         IN  VARCHAR2,
                          P_TRAN_TIME         IN   VARCHAR2,
                          P_IPADDRESS         IN  VARCHAR2,
                          P_CURR_CODE         IN   VARCHAR2,
                          P_RVSL_CODE         IN VARCHAR2,
                          P_BANK_CODE         IN  VARCHAR2,
                          P_MSG               IN VARCHAR2,
                          P_MOBILE_NO         IN VARCHAR2,
                          P_DEVICE_ID         IN VARCHAR2,
                          P_USERNAME          IN VARCHAR2,
                          P_RESP_CODE         OUT  VARCHAR2 ,
                          P_RESMSG            OUT VARCHAR2,
                         -- P_SRV_CODE          OUT VARCHAR2,
                         -- P_PIN_OFFSET        OUT VARCHAR2,
                          P_CARDSTATUS_OUT    OUT VARCHAR2,
                          P_CARDSTAT_DESC_OUT OUT VARCHAR2,
                          P_EXPIRY_DATE_OUT   OUT VARCHAR2,
                          P_LASTUSED_OUT      OUT VARCHAR2,
                          P_ACTIVE_DATE_OUT   OUT VARCHAR2,
                          P_LEDGER_BAL_OUT    OUT VARCHAR2,
                          P_ACCOUNT_BAL_OUT   OUT VARCHAR2,
                          P_INITIALLOAD_OUT   OUT VARCHAR2,
                          P_MAILING_ZIP_OUT   OUT VARCHAR2,
                          P_PHYSICAL_ZIP_OUT  OUT VARCHAR2
                          )

AS
/*************************************************
     * Created Date     :  04-Apr-2012
     * Created By       :  Ramesh.A
     * PURPOSE          :  Alternate User Authentication and Getting Customer using card no
     * modified by           :B.Besky
     * modified Date        : 06-NOV-12
     * modified reason      : Changes in Exception handling
     * Reviewer             : Saravanakumar
     * Reviewed Date        : 06-NOV-12
     * Build Number        :  CMS3.5.1_RI0021

     * Modified By      : Pankaj S.
     * Modified Date    : 12-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0027_B0003

     * Modified by       : A.Sivakaminathan
     * Modified Date     : 10-Jun-2016
     * Modified For      : closed loop product changes.
     * Reviewer          : Saravanakumar
     * Build Number      : VMSGPRHOSTCSD_4.2
     
     * Modified by      : MageshKumar
     * Modified Date    : 05-MAY-17
     * Modified For     : FSS-5103
     * Reviewer         : Saravanankumar/Spankaj
     * Build Number     : VMSGPRHOSTCSD17.05_B0001
     
     * Modified by      : MageshKumar
     * Modified Date    : 24-MAY-17
     * Modified For     : Mantis : 0016583
     * Reviewer         : Saravanankumar/Spankaj
     * Build Number     : VMSGPRHOSTCSD17.05_B0004
     
       * Modified by       :Akhil
       * Modified Date    : 18-Dec-17
       * Modified For     : VMS-127
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12
       
       * Modified by       :Vini
       * Modified Date    : 10-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12.1
       
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 21-FEB-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01 
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 5-02-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jay
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991

*************************************************/

V_TRAN_DATE             DATE;
V_AUTH_SAVEPOINT        NUMBER DEFAULT 0;
--V_RRN_COUNT             NUMBER;
V_ERRMSG                VARCHAR2(500);
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_CUST_CODE             CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
--V_SPND_ACCT_NO          CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
--V_CUST_NAME             CMS_CUST_MAST.CCM_USER_NAME%TYPE;
--V_HASH_PASSWORD         VARCHAR2(100);
--V_CARD_EXPRY            VARCHAR2(20);
--V_STAN                  VARCHAR2(20);
V_CAPTURE_DATE          DATE;
V_TERM_ID               VARCHAR2(20);
V_MCC_CODE              VARCHAR2(20);
V_TXN_AMT               NUMBER;
V_ACCT_NUMBER           cms_acct_mast.cam_acct_no%TYPE;
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_CUST_ID               CMS_CUST_MAST.CCM_CUST_ID%TYPE;
--V_STARTERCARD_FLAG      CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE;
--V_CARD_STAT             CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
--V_EXP_DATE            VARCHAR2(10);
--V_SRV_CODE            VARCHAR2(5);
--V_CARDSTAT            VARCHAR2(5); --Added by ramesh.a on 10/04/2012
--V_COUNT                 NUMBER;
BYPASS_FLAG  BOOLEAN := FALSE;

V_DR_CR_FLAG       VARCHAR2(2);
V_OUTPUT_TYPE      VARCHAR2(2);
V_TRAN_TYPE         VARCHAR2(2);

EXP_AUTH_REJECT_RECORD  EXCEPTION;
EXP_REJECT_RECORD       EXCEPTION;
V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812

 --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
   v_prod_code             cms_appl_pan.cap_prod_code%type;
   v_card_type             cms_appl_pan.cap_card_type%type;
   v_acct_balance          cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal            cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type             cms_acct_mast.cam_type_code%TYPE;
   v_resp_cde              transactionlog.response_id%TYPE;
   V_ENCRYPT_ENABLE        CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
   --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
  -- V_ZIPCODE               CMS_ADDR_MAST.CAM_PIN_CODE%TYPE;
  -- V_ZIPCODE_FLAG          CMS_ADDR_MAST.CAM_ADDR_FLAG%TYPE;
  
  v_encrypt_user_name         cms_transaction_log_dtl.ctd_user_name%type;
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991
CURSOR ZIPCODE (c_cust_code IN number, c_inst_code IN number)
   IS
    SELECT  NVL (CAM_PIN_CODE, ' ') ZIPCODE,CAM_ADDR_FLAG    
              FROM CMS_ADDR_MAST
              WHERE CAM_INST_CODE = c_inst_code
              AND CAM_CUST_CODE = c_cust_code;
--Main Begin Block Starts Here
BEGIN
   V_TXN_TYPE := '1';
   SAVEPOINT V_AUTH_SAVEPOINT;

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
     /*   BEGIN
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM TRANSACTIONLOG
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;

          IF V_RRN_COUNT    > 0 THEN
            P_RESP_CODE     := '22';
            V_ERRMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
          END IF;
        END;*/--Unwanted code removed
       --En Duplicate RRN Check

      --Sn Get Tran date
        BEGIN
          V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                  SUBSTR(TRIM(P_TRAN_TIME), 1, 8),
                  'yyyymmdd hh24:mi:ss');
          EXCEPTION
            WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
       --En Get Tran date

         --Sn Check Delivery Channel
          IF P_DELIVERY_CHANNEL NOT IN ('10','13') THEN
            V_ERRMSG  := 'Not a valid delivery channel  for ' ||
                 ' Alternate User Authentication';
            P_RESP_CODE := '21'; ---ISO MESSAGE FOR DATABASE ERROR
            RAISE EXP_REJECT_RECORD;
          END IF;
        --En Check Delivery Channel

          --Sn Check transaction code
          IF P_TXN_CODE NOT IN ('25','56') THEN
            V_ERRMSG  := 'Not a valid transaction code for ' ||
                  ' Alternate  User Authentication';
            P_RESP_CODE := '21'; ---ISO MESSAGE FOR DATABASE ERROR
            RAISE EXP_REJECT_RECORD;
          END IF;
        --En check transaction code

      --Sn Expiry date, service code
        BEGIN
       /*   SELECT TO_CHAR(CAP_EXPRY_DATE, 'MMYY'), CBP_PARAM_VALUE ,CAP_PIN_OFF, CAP_CARD_STAT,
                 cap_acct_no,cap_prod_code,cap_card_type    --Added by Pankaj S. for logging changes(Mantis ID-13160)
         INTO V_EXP_DATE, V_SRV_CODE ,P_PIN_OFFSET , V_CARDSTAT,
               v_spnd_acct_no,v_prod_code,v_card_type --Added by Pankaj S. for logging changes(Mantis ID-13160)
         FROM CMS_APPL_PAN, CMS_BIN_PARAM, CMS_PROD_MAST
        WHERE CBP_PROFILE_CODE = CPM_PROFILE_CODE AND
           CPM_INST_CODE = CAP_INST_CODE AND CPM_PROD_CODE = CAP_PROD_CODE AND
           CBP_PARAM_NAME = 'Service Code' AND CAP_PAN_CODE = V_HASH_PAN;*/--Unwanted code removed
        SELECT TO_CHAR(CAP_EXPRY_DATE, 'MM/YY'), CAP_CARD_STAT,
                 cap_acct_no,cap_prod_code,cap_card_type,    --Added by Pankaj S. for logging changes(Mantis ID-13160)
            TO_CHAR(CAP_ACTIVE_DATE, 'MM/DD/YYYY HH24MISS'),TO_CHAR(CAP_LAST_TXNDATE, 'MM/DD/YYYY'),CAP_CUST_CODE
         INTO P_EXPIRY_DATE_OUT, P_CARDSTATUS_OUT,
               V_ACCT_NUMBER,v_prod_code,v_card_type, --Added by Pankaj S. for logging changes(Mantis ID-13160)
               P_ACTIVE_DATE_OUT,P_LASTUSED_OUT,V_CUST_CODE
         FROM CMS_APPL_PAN
        WHERE 
           CAP_INST_CODE = P_INST_CODE  AND CAP_PAN_CODE = V_HASH_PAN;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '16'; --Ineligible Transaction
         V_ERRMSG   := 'Card number not found' || P_TXN_CODE;
         RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
         P_RESP_CODE := '12';
         V_ERRMSG   := 'Problem while selecting card detail' ||
              SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;

        END;
    --En  Expiry date, service code
    
        
    BEGIN
         SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL, CAM_INITIALLOAD_AMT
           INTO P_ACCOUNT_BAL_OUT, P_LEDGER_BAL_OUT, P_INITIALLOAD_OUT
           FROM CMS_ACCT_MAST
          WHERE CAM_ACCT_NO = v_acct_number AND CAM_INST_CODE = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            P_ACCOUNT_BAL_OUT := 0;
            P_LEDGER_BAL_OUT := 0;
            P_INITIALLOAD_OUT := 0;
      END;

     BEGIN
        SELECT CPC_ENCRYPT_ENABLE
          INTO V_ENCRYPT_ENABLE
          FROM CMS_PROD_CATTYPE
         WHERE CPC_INST_CODE = P_INST_CODE 
           AND CPC_PROD_CODE = V_PROD_CODE
           AND CPC_CARD_TYPE = V_CARD_TYPE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '16'; --Ineligible Transaction
         V_ERRMSG   := 'Invalid Prod Code & Card Type ' || P_TXN_CODE;
         RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
         P_RESP_CODE := '12';
         V_ERRMSG   := 'Problem while selecting product category details' ||
              SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;

        END;
	
	
     IF v_encrypt_enable = 'Y' then
   
         v_encrypt_user_name:=fn_emaps_main(p_username);     
   
     else
   
         v_encrypt_user_name:=p_username;     
   
    END IF;   
   
     --Added by ramesh.a on 11/04/2012
     --Sn Get the PIN OFFSET
     /*   BEGIN
          SELECT CAP_PIN_OFF
         INTO P_PIN_OFFSET
         FROM CMS_APPL_PAN
        WHERE  CAP_INST_CODE=P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '52';
         V_ERRMSG   := 'Pin Generation not Done.' || P_TXN_CODE;
         RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
         P_RESP_CODE := '12';
         V_ERRMSG   := 'Problem while selecting card pin detail' ||
              SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;

        END; */-- Unwanted code commented
    --En Get the PIN OFFSET

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
                P_EXPIRY_DATE_OUT,
                null,
                '000',
                P_RVSL_CODE,
                V_TXN_AMT,
                V_AUTH_ID,
                P_RESP_CODE,
                V_ERRMSG,
                V_CAPTURE_DATE);
        IF P_RESP_CODE <> '00' AND V_ERRMSG <> 'OK' THEN
         --P_RESP_CODE := '21'; Commented by Besky on 06-nov-12
         --V_ERRMSG := 'Error from auth process' || V_ERRMSG;
         P_RESMSG := 'Error from auth process' || V_ERRMSG;  -- Added by Besky on 06-nov-12
         BYPASS_FLAG := TRUE; --RETURN;
        --RAISE EXP_AUTH_REJECT_RECORD;
        END IF;
      EXCEPTION
        /*WHEN EXP_AUTH_REJECT_RECORD THEN   Commented by Besky on 06-nov-12
          RAISE EXP_REJECT_RECORD;*/
        WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error from Card authorization' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      END;
    --En call to authorize procedure

    --St  Alternate User Authentication and getting customer id

     BEGIN

      -- Updated by ramesh.a on 12/04/2012
       SELECT nvl(CCM_CUST_ID,0) INTO V_CUST_ID FROM CMS_CUST_MAST WHERE  CCM_INST_CODE=P_INST_CODE AND CCM_CUST_CODE=V_CUST_CODE;--(
      -- SELECT CAP_CUST_CODE FROM CMS_APPL_PAN WHERE CAP_INST_CODE=P_INST_CODE AND CAP_PAN_CODE=GETHASH(P_PAN_CODE));

      --St: Added by ramesh.a on 12/04/2012
      IF V_CUST_ID = '0' THEN
         P_RESP_CODE := '21';
         V_ERRMSG := 'Cust Id not Found ';
         RAISE EXP_REJECT_RECORD;
      END IF;
      --End: Added by ramesh.a on 12/04/2012

      EXCEPTION
      WHEN EXP_REJECT_RECORD THEN   --Added by ramesh.a on 12/04/2012
          RAISE EXP_REJECT_RECORD;
      WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '21';
         V_ERRMSG := 'Cust Id not Found ';
         RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error from while selecting customer id ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

     END;
     
     
      BEGIN
    
      SELECT CCS_STAT_DESC INTO P_CARDSTAT_DESC_OUT FROM CMS_CARD_STAT WHERE  CCS_STAT_CODE=P_CARDSTATUS_OUT;
     
      EXCEPTION
      WHEN EXP_REJECT_RECORD THEN   
          RAISE EXP_REJECT_RECORD;
      WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '21';
         V_ERRMSG := 'Card Status Not Found ';
         RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error from while selecting card status desc ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

     END;
     
     BEGIN
     
     FOR l_row_indx IN ZIPCODE (V_CUST_CODE, P_INST_CODE)
         
         LOOP
         
         IF l_row_indx.cam_addr_flag IS NOT NULL AND l_row_indx.cam_addr_flag = 'P' THEN
         
            IF V_ENCRYPT_ENABLE = 'Y' THEN
               P_PHYSICAL_ZIP_OUT := fn_dmaps_main(l_row_indx.ZIPCODE);
            ELSE
               P_PHYSICAL_ZIP_OUT := l_row_indx.ZIPCODE;
            END IF;
           
         ELSIF l_row_indx.cam_addr_flag IS NOT NULL AND l_row_indx.cam_addr_flag = 'O' THEN
         
            IF V_ENCRYPT_ENABLE = 'Y' THEN
               P_MAILING_ZIP_OUT := fn_dmaps_main(l_row_indx.ZIPCODE);
            ELSE
               P_MAILING_ZIP_OUT := l_row_indx.ZIPCODE;
            END IF;
         
         END IF;
           
         END LOOP;
         
         EXCEPTION 
         
         WHEN OTHERS THEN
         
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error while selecting ZIP Code ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
         
      END;


            BEGIN

--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET CTD_USER_NAME= v_encrypt_user_name,
              CTD_MOBILE_NUMBER=P_MOBILE_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
ELSE
    UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST --Added for VMS-5733/FSP-991
              SET CTD_USER_NAME= v_encrypt_user_name,
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
      IF BYPASS_FLAG THEN
		RETURN;
      END IF;
      P_RESP_CODE := 1;
      V_ERRMSG := 'USER AUTHENTICATION SUCCESS';
      P_RESMSG := V_CUST_ID;
     -- P_EXPIRY_DATE_OUT := V_EXP_DATE;
     -- P_SRV_CODE := V_SRV_CODE;
    --En  Alternate User Authentication and getting customer id


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

--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
          UPDATE TRANSACTIONLOG
          SET  --RESPONSE_ID=P_RESP_CODE,  --Modified by Pankaj S. for Logging changes(Mantis ID-13160)
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
    ELSE
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          SET  --RESPONSE_ID=P_RESP_CODE,  --Modified by Pankaj S. for Logging changes(Mantis ID-13160)
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG
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

--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION
WHEN EXP_REJECT_RECORD THEN
 ROLLBACK TO V_AUTH_SAVEPOINT;

     v_resp_cde:=P_RESP_CODE;  --Added by Pankaj S. for Logging changes(Mantis ID-13160)

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
          INTO P_CARDSTATUS_OUT, v_prod_code, v_card_type, V_ACCT_NUMBER
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
        WHERE cam_acct_no = V_ACCT_NUMBER AND cam_inst_code = p_inst_code;
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
                     CARDSTATUS,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                     TRANS_DESC,
                     response_id,
                     --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
                     productid,
                     categoryid,
                     cr_dr_flag,
                     acct_balance,
                     ledger_balance,
                     acct_type,
                     time_stamp
                     --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
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
                    P_CARDSTATUS_OUT, --Added CARDSTATUS insert in transactionlog by srinivasu.k
                    V_TRANS_DESC ,
                    v_resp_cde,--P_RESP_CODE --Modified by Pankaj S. for Logging changes(Mantis ID-13160)
                    --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
                    v_prod_code,
                    v_card_type,
                    v_dr_cr_flag,
                    v_acct_balance,
                    v_ledger_bal,
                    v_acct_type,
                    systimestamp
                    --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
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
              CTD_MOBILE_NUMBER,
              CTD_DEVICE_ID,
			  CTD_USER_NAME
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
              V_ACCT_NUMBER,
              '',
              P_MOBILE_NO,
              P_DEVICE_ID,
              v_encrypt_user_name
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
      ROLLBACK TO V_AUTH_SAVEPOINT;
      v_resp_cde:=P_RESP_CODE;  --Added by Pankaj S. for Logging changes(Mantis ID-13160)

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
          INTO P_CARDSTATUS_OUT, v_prod_code, v_card_type, V_ACCT_NUMBER
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
        WHERE cam_acct_no = V_ACCT_NUMBER AND cam_inst_code = p_inst_code;
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
                       CARDSTATUS,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                       TRANS_DESC,
                       --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
                       response_id,
                       productid,
                       categoryid,
                       cr_dr_flag,
                       acct_balance,
                       ledger_balance,
                       acct_type,
                       time_stamp
                       --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
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
                       P_CARDSTATUS_OUT, --Added CARDSTATUS insert in transactionlog by srinivasu.k
                       V_TRANS_DESC,
                       --Sn Added by Pankaj S. for Logging changes(Mantis ID-13160)
                       v_resp_cde,
                       v_prod_code,
                       v_card_type,
                       v_dr_cr_flag,
                       v_acct_balance,
                       v_ledger_bal,
                       v_acct_type,
                       systimestamp
                       --En Added by Pankaj S. for Logging changes(Mantis ID-13160)
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
              CTD_MOBILE_NUMBER,
              CTD_DEVICE_ID,
			  CTD_USER_NAME
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
              V_ACCT_NUMBER,
              '',
              P_MOBILE_NO,
              P_DEVICE_ID,
              v_encrypt_user_name
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
show error