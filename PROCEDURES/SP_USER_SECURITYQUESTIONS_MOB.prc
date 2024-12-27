CREATE OR REPLACE PROCEDURE VMSCMS.SP_USER_SECURITYQUESTIONS_MOB(
                          P_INST_CODE         IN  NUMBER ,
                          P_PAN_CODE          IN  VARCHAR2,
                          P_DELIVERY_CHANNEL  IN  VARCHAR2,
                          P_TXN_CODE          IN  VARCHAR2, 
                          P_RRN               IN  VARCHAR2,
                          P_USERNAME          IN  VARCHAR2,
                          P_TXN_MODE          IN  VARCHAR2,
                          P_TRAN_DATE         IN  VARCHAR2,
                          P_TRAN_TIME         IN  VARCHAR2,
                          P_CURR_CODE         IN  VARCHAR2,
                          P_RVSL_CODE         IN  VARCHAR2,
                          P_BANK_CODE         IN  VARCHAR2, 
                          P_MSG               IN  VARCHAR2,
                          P_APPL_ID           IN  VARCHAR2, 
                          P_MOB_NO            IN  VARCHAR2, 
                          P_DEVICE_ID         IN  VARCHAR2, 
                           P_RESP_CODE        OUT VARCHAR2,
                          P_RESMSG            OUT VARCHAR2)

AS
/*************************************************
     * Created Date     :  22-Aug-2012
     * Created By       :  B.Dhinakaran
     * PURPOSE          :  Transaction detail report
     * Modified By      :  B.Besky
     * Modified Date    :  08-nov-12
     * Modified Reason  : Logging Customer Account number in to transactionlog table.
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  09-nov-12
     * Release Number   :  CMS3.5.1_RI0021_B0006
     
     * modified by       :  RAVI N
     * modified Date     :  09-AUG-13
     * modified reason   :  Adding new Input [P_MOB_NO,P_DEVICE_ID] parameters and logging cms_transaction_log_dtl
     * modified reason   :  FSS-1144
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  29-AUG-13
     * Build Number      :  RI0024.4_B0007
     
     * Modified By      : Pankaj S.
     * Modified Date    : 10-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0027_B0003
     
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

    * Modified By      : venkat Singamaneni
    * Modified Date    : 5-02-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jay
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991 

*************************************************/
V_RRN_COUNT             NUMBER;
V_ERRMSG                VARCHAR2(500);
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_CUST_CODE             CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
V_CARD_EXPRY            VARCHAR2(20);
V_STAN                  CMS_TRANSACTION_LOG_DTL.CTD_SYSTEM_TRACE_AUDIT_NO%TYPE;
V_CAPTURE_DATE          TRANSACTIONLOG.DATE_TIME%TYPE;
V_TERM_ID               TRANSACTIONLOG.TERMINAL_ID%TYPE;
V_MCC_CODE              TRANSACTIONLOG.MCCODE%TYPE;
V_TXN_AMT               CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
V_ACCT_NUMBER           cms_appl_pan.cap_acct_no%TYPE;
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_CUST_ID               CMS_CUST_MAST.CCM_CUST_ID%TYPE;
V_CARDSTAT              CMS_APPL_PAN.CAP_CARD_STAT%TYPE;                                   
V_CSQ_QUESTION          CMS_SECURITY_QUESTIONS.CSQ_ANSWER_HASH%TYPE;
V_DR_CR_FLAG            CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
V_OUTPUT_TYPE           CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
V_TRAN_TYPE             CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
V_TRANS_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;     
V_HASHKEY_ID            CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; 
V_TIME_STAMP            TRANSACTIONLOG.TIME_STAMP%TYPE;                                
v_prod_code             cms_appl_pan.cap_prod_code%type;
v_card_type             cms_appl_pan.cap_card_type%type;
v_acct_balance          cms_acct_mast.cam_acct_bal%TYPE;
v_ledger_bal            cms_acct_mast.cam_ledger_bal%TYPE;
v_acct_type             cms_acct_mast.cam_type_code%TYPE;
v_resp_cde              transactionlog.response_id%TYPE;
V_ENCRYPT_ENABLE        CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
v_encr_username         cms_cust_mast.CCM_USER_NAME%type;
EXP_AUTH_REJECT_RECORD  EXCEPTION;
EXP_REJECT_RECORD       EXCEPTION;
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991

 CURSOR C (CUST_ID NUMBER,INST_CODE NUMBER) IS
      SELECT CSQ_QUESTION,CSQ_ANSWER_HASH
      FROM CMS_SECURITY_QUESTIONS
      WHERE CSQ_CUST_ID=CUST_ID AND CSQ_INST_CODE=INST_CODE;

BEGIN
   V_TXN_TYPE := '1';
   SAVEPOINT V_AUTH_SAVEPOINT;
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

--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

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
			V_ERRMSG  := 'Error while selecting RRN count from Transactionlog ' ||
			SUBSTR(SQLERRM, 1, 200);
			RAISE EXP_REJECT_RECORD;
        END;
       --En Duplicate RRN Check


        --Sn Get the card details
         BEGIN
              SELECT CAP_CARD_STAT,CAP_ACCT_NO,    
                     cap_prod_code,cap_card_type,cap_cust_code 
              INTO V_CARDSTAT, V_ACCT_NUMBER,   
                   v_prod_code,v_card_type,v_cust_code  
              FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                P_RESP_CODE := '16'; 
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
      SELECT upper(CPC_ENCRYPT_ENABLE)
        INTO V_ENCRYPT_ENABLE
        FROM CMS_PROD_CATTYPE
       WHERE CPC_INST_CODE = P_INST_CODE AND CPC_CARD_TYPE = V_CARD_TYPE AND
             CPC_PROD_CODE =v_prod_code;

    EXCEPTION
         WHEN NO_DATA_FOUND THEN
              P_RESP_CODE := '21'; 
              V_ERRMSG  := 'encrypt details not found for prod code' || v_prod_code
	                      || 'and card type' ||v_card_type;
              RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
              P_RESP_CODE := '12';
              V_ERRMSG  := 'Problem while selecting card encrypting detail' ||
               SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
  END; 

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
          P_RESMSG:= 'Error from auth process' || V_ERRMSG;
        RAISE EXP_AUTH_REJECT_RECORD;
        END IF;
      EXCEPTION
        WHEN EXP_AUTH_REJECT_RECORD THEN
          RAISE EXP_AUTH_REJECT_RECORD;
        WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error from Card authorization' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      END;
    --En call to authorize procedure

    --St Get the questions using username

     BEGIN
     
     IF  v_encrypt_enable = 'Y' THEN 
           v_encr_username:= fn_emaps_main(upper(trim(p_username)));
       ELSE
           v_encr_username:= upper(trim(p_username));
     END IF;
     
         
      SELECT CCM_CUST_ID INTO V_CUST_ID
      FROM CMS_CUST_MAST
      WHERE CCM_INST_CODE = P_INST_CODE
      AND CCM_CUST_CODE = V_CUST_CODE; --Modified for Decline Request for Web-account Username if Username is Already Taken(VMS-809)
      
--      UPPER(CCM_USER_NAME)= v_encr_username AND CCM_INST_CODE=P_INST_CODE
--      /* Start CR014 Changes Dhiraj GAikwad 04092012*/
--           AND CCM_APPL_ID =P_APPL_ID  ;
--           /* End CR014 Changes Dhiraj GAikwad 04092012*/

--      FOR I IN C(V_CUST_ID,P_INST_CODE) LOOP
      SELECT CSQ_QUESTION INTO V_CSQ_QUESTION
      FROM CMS_SECURITY_QUESTIONS
      WHERE CSQ_CUST_ID=V_CUST_ID AND CSQ_INST_CODE=1 AND ROWNUM=1;

      IF P_RESMSG IS NULL THEN
          P_RESMSG :=V_CSQ_QUESTION;
      ELSE
          P_RESMSG :=P_RESMSG || '||' || V_CSQ_QUESTION;
      END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '21';
         V_ERRMSG := 'Cust Id not Found ';
         RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error from while selecting customer id and questions' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

     END;

      P_RESP_CODE := 1;
      V_ERRMSG := 'SUCCESS';

    --En Get the questions using username
     --Sn Updtated transactionlog For regarding FSS-1144          
                      
            BEGIN
            
            --Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN    
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET CTD_USER_NAME= v_encr_username,                                      
              CTD_MOBILE_NUMBER=P_MOB_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE 
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
      ELSE
                UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST --Added for VMS-5733/FSP-991
              SET CTD_USER_NAME= v_encr_username,                                      
              CTD_MOBILE_NUMBER=P_MOB_NO,
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
        
   --End Updated transaction log  for regarding  FSS-1144  

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
          P_RESP_CODE := '69'; 
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
        END;
      --En Get responce code fomr master
EXCEPTION
WHEN EXP_AUTH_REJECT_RECORD THEN  

     BEGIN
     
                 --Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN        
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET CTD_USER_NAME= v_encr_username,                                      
              CTD_MOBILE_NUMBER=P_MOB_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE 
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
         ELSE
                        UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST --Added for VMS-5733/FSP-991
              SET CTD_USER_NAME= v_encr_username,                                      
              CTD_MOBILE_NUMBER=P_MOB_NO,
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
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,
                     TRANS_DESC,
                     TIME_STAMP,  
                     response_id,
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
                      V_ACCT_NUMBER ,  
                     V_ERRMSG,
                     SYSDATE,
                     1,
                     V_CARDSTAT, 
                     V_TRANS_DESC,
                     V_TIME_STAMP ,  
                     v_resp_cde,
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
              v_acct_number,
              '',
              P_MOB_NO,   
              P_DEVICE_ID, 
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
     P_RESMSG:=V_ERRMSG; 

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
                       ADD_INS_DATE,
                       ADD_INS_USER,
                       CARDSTATUS,
                       TRANS_DESC,
                       TIME_STAMP, 
                       response_id,
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
                       V_ACCT_NUMBER , 
                       V_ERRMSG,
                       SYSDATE,
                       1,
                       V_CARDSTAT,
                       V_TRANS_DESC,
                       V_TIME_STAMP,   
                       v_resp_cde,
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
               v_acct_number,
              '',
              P_MOB_NO,    
              P_DEVICE_ID,
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
show error