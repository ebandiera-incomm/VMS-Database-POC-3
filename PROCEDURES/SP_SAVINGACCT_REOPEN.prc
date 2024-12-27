set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_SAVINGACCT_REOPEN(P_INST_CODE        IN NUMBER,
                                        P_PAN_CODE         IN NUMBER,
                                        P_SAVE_ACCT_NO     IN VARCHAR2,
                                        P_DELIVERY_CHANNEL IN VARCHAR2,
                                        P_TXN_CODE         IN VARCHAR2,
                                        P_RRN              IN VARCHAR2,
                                        P_TXN_MODE         IN VARCHAR2,
                                        P_TRAN_DATE        IN VARCHAR2,
                                        P_TRAN_TIME        IN VARCHAR2,
                                        P_ANI              IN VARCHAR2,
                                        P_DNI              IN VARCHAR2,
                                        P_IPADDRESS        IN VARCHAR2,
                                        P_BANK_CODE        IN VARCHAR2,
                                        P_CURR_CODE        IN VARCHAR2,
                                        P_RVSL_CODE        IN VARCHAR2,
                                        P_MSGTYPE          IN VARCHAR2,
                                        P_RESP_CODE        OUT VARCHAR2,
                                        P_ERR_MSG          OUT VARCHAR2) AS
  /*************************************************
    * Created Date     :  25-Apr-2012
    * Created By       :  Saravanakumar
    * PURPOSE          : For reopening saving account
    * modified by      : B.Besky
    * modified Date    : 06-NOV-12
    * modified reason  : Changes in Exception handling
    * Reviewer         : Saravanakumar
    * Reviewed Date    : 06-NOV-12
    * Build Number     :  CMS3.5.1_RI0021_B0003

    * Modified by      :  Pankaj S.
    * Modified Reason  :  DFCCSD-70
    * Modified Date    :  21-Aug-2013
    * Reviewer         :  Dhiraj
    * Reviewed Date    :  20-Aug-2013
    * Build Number     :  RI0024.4_B0006


    * Modified By      : Sagar More
    * Modified Date    : 26-Sep-2013
    * Modified For     : LYFEHOST-63
    * Modified Reason  : To fetch saving acct parameter based on product code
    * Reviewer         : Dhiraj
    * Reviewed Date    : 28-Sep-2013
    * Build Number     : RI0024.5_B0001

    * Modified By      : Sagar More
    * Modified Date    : 16-OCT-2013
    * Modified For     : review observation changes for LYFEHOST-63
    * Reviewer         : Dhiraj
    * Reviewed Date    : 16-OCT-2013
    * Build Number     : RI0024.6_B0001

    * Modified By      : Sagar More
    * Modified Date    : 22-OCT-2013
    * Modified For     : Defect 12797
    * Modified Reason  : To uncomment subquery used to fetch saving acct from cms_acct_mast
    * Reviewer         : Dhiraj
    * Reviewed Date    : 23-OCT-2013
    * Build Number     : RI0024.6_B0002

    * Modified by      : Pankaj S.
    * Modified for     : Transactionlog Functional Removal Phase-II changes
    * Modified Date    : 11-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOAT_3.1

        * Modified by       : Siva Kumar M
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-15-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991    

  *************************************************/
  V_HASH_PAN        CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN        CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_ACCT_TYPE       CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
  V_CUST_CODE       CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
  V_SAVING_ACCTNO   CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  V_ACCT_STATUS     CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
  V_LAST_UPDATEDATE CMS_ACCT_MAST.CAM_LUPD_DATE%TYPE;
  V_REOPEN_PERIOD   CMS_DFG_PARAM.CDP_PARAM_VALUE%TYPE;
  V_RRN_COUNT       NUMBER;
  V_COUNT           NUMBER;
  V_STATUS_CODE     CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
  V_CAPTURE_DATE    DATE;
  V_AUTH_ID         TRANSACTIONLOG.AUTH_ID%TYPE;
  V_SAVEPOINT       NUMBER := 1;
  EXP_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION; --Added by Ramesh.A on 22/05/2012

  V_DR_CR_FLAG  VARCHAR2(2);
  V_OUTPUT_TYPE VARCHAR2(2);
  V_TRAN_TYPE   VARCHAR2(2);
  V_TXN_TYPE    VARCHAR2(2);
  V_TRANS_DESC  CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812

  --Sn Added by Pankaj S. for DFCCSD-70 changes
  v_acct_number   cms_acct_mast.cam_acct_no%TYPE;
  v_avail_bal     cms_acct_mast.cam_acct_bal%TYPE;
  v_ledger_bal    cms_acct_mast.cam_acct_bal%TYPE;
  --En Added by Pankaj S. for DFCCSD-70 changes
  --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
  v_prod_code    cms_appl_pan.cap_prod_code%TYPE;
  v_card_type    cms_appl_pan.cap_card_type%TYPE;
  v_card_stat    cms_appl_pan.cap_card_stat%TYPE;
  v_resp_cde     transactionlog.response_id%TYPE;
  --En Added by Pankaj S. during DFCCSD-70(Review) changes

  v_date_chk      date;       -- Added as per review observation for LYFEHOST-63
    v_Retperiod  date; --Added for VMS-5733/FSP-991
    v_Retdate  date; --Added for VMS-5733/FSP-991

BEGIN
  SAVEPOINT V_SAVEPOINT;

  BEGIN
    V_HASH_PAN := GETHASH(P_PAN_CODE);
  EXCEPTION
    WHEN OTHERS THEN
     P_RESP_CODE := '12';
     P_ERR_MSG   := 'Error while converting hashpan ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_PAN_CODE);
  EXCEPTION
    WHEN OTHERS THEN
     P_RESP_CODE := '12';
     P_ERR_MSG   := 'Error while converting encrpyt pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --Sn find debit and credit flag

  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_OUTPUT_TYPE,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
         CTM_TRAN_TYPE,
         CTM_TRAN_DESC
     INTO V_DR_CR_FLAG,
         V_OUTPUT_TYPE,
         V_TXN_TYPE,
         V_TRAN_TYPE,
         V_TRANS_DESC
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         CTM_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '12'; --Ineligible Transaction
     P_ERR_MSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                 ' and delivery channel ' || P_DELIVERY_CHANNEL;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Ineligible Transaction
     P_ERR_MSG   := 'Error while selecting transaction details '||substr(SQLERRM,1,100);-- Change in error message as per review observation for LYFEHOST-63
     RAISE EXP_REJECT_RECORD;
  END;

  --En find debit and credit flag

  --SN: Added as per review observation for LYFEHOST-63

   BEGIN

       SELECT to_Date(substr(P_TRAN_DATE,1,8),'yyyymmdd')
       INTO v_date_chk
       FROM dual;

   EXCEPTION WHEN others
   THEN
      P_RESP_CODE := '21';
      P_ERR_MSG := 'Invalid transaction date '||P_TRAN_DATE;
      RAISE EXP_REJECT_RECORD;

   END;

  --EN: Added as per review observation for LYFEHOST-63


  --Checking duplicate RRN
  BEGIN
  
         --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');
       
IF (v_Retdate>v_Retperiod)    --Added for VMS-5733/FSP-991
    THEN
    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
   else
            SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
    END IF;     

    IF V_RRN_COUNT > 0 THEN
     P_RESP_CODE := '22';
     P_ERR_MSG   := 'Duplicate RRN on ' || P_TRAN_DATE;
     RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '22';
     P_ERR_MSG   := 'Error in RRN count check ' || P_RRN ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
     -- Added Exception by Ramesh.A on 21/05/2012 for defect id : 7631 ,7630
  END;

  --Fetching account type for saving account
  BEGIN
    SELECT CAT_TYPE_CODE
     INTO V_ACCT_TYPE
     FROM CMS_ACCT_TYPE
    WHERE CAT_INST_CODE = P_INST_CODE AND CAT_SWITCH_TYPE = '22';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '21';
     P_ERR_MSG   := 'Acct type is not defined for saving account';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21';
     P_ERR_MSG   := 'Error while selecting account type ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --Fetching customer code for this card
  BEGIN
    SELECT CAP_CUST_CODE,
           cap_prod_code,cap_card_type,cap_card_stat,cap_acct_no  --Added by Pankaj S. during DFCCSD-70(Review) changes
     INTO V_CUST_CODE,
          v_prod_code,v_card_type,v_card_stat,v_acct_number   --Added by Pankaj S. during DFCCSD-70(Review) changes
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '21';
     P_ERR_MSG   := 'Customer code is not defined for this card';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '12';
     P_ERR_MSG   := 'Error while getting  cust code from master ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --Sn Commented here & handled in below query during DFCCSD-70(Review) changes by Pankaj S.
  --Checking saving account is already exist for this customer
  /*BEGIN
    SELECT COUNT(1)
     INTO V_COUNT
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_ID IN
         (SELECT CCA_ACCT_ID
            FROM CMS_CUST_ACCT
           WHERE CCA_CUST_CODE = V_CUST_CODE AND
                CCA_INST_CODE = P_INST_CODE) AND
         CAM_TYPE_CODE = V_ACCT_TYPE AND CAM_INST_CODE = P_INST_CODE;

    IF V_COUNT = 0 THEN
     P_ERR_MSG   := 'Savings account not created for this card';
     P_RESP_CODE := '105';
     RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21';
     P_ERR_MSG   := 'Error while selecting cms_acct_mast ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;*/
  --En Commented here & handled in below query during DFCCSD-70(Review) changes by Pankaj S.

  --Checking account number is valid
  BEGIN
    SELECT CAM_ACCT_NO
     INTO V_SAVING_ACCTNO
     FROM CMS_ACCT_MAST
    --Sn Modified by Pankaj S. during DFCCSD-70(Review) changes
    WHERE --cam_acct_no=p_save_acct_no                            -- Condition commented on 22-oct-2013 Defect 12797
         CAM_ACCT_ID IN                                           -- SubQuery uncommented on 22-oct-2013 Defect 12797
         (SELECT CCA_ACCT_ID
            FROM CMS_CUST_ACCT
           WHERE CCA_CUST_CODE = V_CUST_CODE AND
                CCA_INST_CODE = P_INST_CODE) AND
         CAM_TYPE_CODE = V_ACCT_TYPE
         AND CAM_INST_CODE = P_INST_CODE;
    --En Modified by Pankaj S. during DFCCSD-70(Review) changes

    IF V_SAVING_ACCTNO <> P_SAVE_ACCT_NO THEN
     P_ERR_MSG   := 'Invalid Savings account number '||P_SAVE_ACCT_NO; -- P_SAVE_ACCT_NO appended on 22-oct-2013
     P_RESP_CODE := '109';
     RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE EXP_REJECT_RECORD;
    --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
    WHEN NO_DATA_FOUND THEN
     P_ERR_MSG   := 'Savings account not created for this card';
     P_RESP_CODE := '105';
     RAISE EXP_REJECT_RECORD;
    --En Added by Pankaj S. during DFCCSD-70(Review) changes
    WHEN OTHERS THEN
     P_RESP_CODE := '21';
     P_ERR_MSG   := 'Error while selecting cms_acct_mast 1 ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --Fetching status code for saving account
  BEGIN
    SELECT CAS_STAT_CODE
     INTO V_ACCT_STATUS
     FROM CMS_ACCT_STAT
    WHERE CAS_INST_CODE = P_INST_CODE AND CAS_SWITCH_STATCODE = '8';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '21';
     P_ERR_MSG   := 'Status code is not defined for saving account';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21';
     P_ERR_MSG   := 'Error while selecting cms_acct_stat ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --Fetching last updated date
  BEGIN
    SELECT CAM_STAT_CODE, CAM_LUPD_DATE
     INTO V_STATUS_CODE, V_LAST_UPDATEDATE
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_NO = V_SAVING_ACCTNO AND CAM_INST_CODE = P_INST_CODE;

    IF V_ACCT_STATUS = V_STATUS_CODE THEN
     P_ERR_MSG   := 'Saving account is already in open status';
     P_RESP_CODE := '122';
     RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21';
     P_ERR_MSG   := 'Error while selecting cms_acct_mast 2  ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --Fetching reopen period
  BEGIN
    SELECT CDP_PARAM_VALUE
     INTO V_REOPEN_PERIOD
     FROM CMS_DFG_PARAM
    WHERE CDP_PARAM_KEY = 'Saving account reopen period'
    AND   cdp_inst_code = p_inst_code                    -- Added for LYFEHOST-63
    AND   cdp_prod_code = v_prod_code                   -- Added for LYFEHOST-63
    AND   cdp_card_type = v_card_type;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '21';
     P_ERR_MSG   := 'Reopen period is not defined for product ' ||v_prod_code||' and card type '||v_card_type ||' and instcode '||p_inst_code;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21';
     P_ERR_MSG   := 'Error while selecting cms_dfg_param for product ' ||v_prod_code||' and card type '||v_card_type||' and instcode '||p_inst_code||' '||
                 SUBSTR(SQLERRM, 1, 200);         -- chnage in error messgae for LYFEHOST-63
     RAISE EXP_REJECT_RECORD;
  END;

  IF SYSDATE - V_LAST_UPDATEDATE > V_REOPEN_PERIOD THEN
    BEGIN
     SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                          P_MSGTYPE,
                          P_RRN,
                          P_DELIVERY_CHANNEL,
                          NULL,
                          P_TXN_CODE,
                          P_TXN_MODE,
                          P_TRAN_DATE,
                          P_TRAN_TIME,
                          P_PAN_CODE,
                          P_BANK_CODE,
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
                          P_ERR_MSG,
                          V_CAPTURE_DATE);

     IF P_RESP_CODE <> '00' AND P_ERR_MSG <> 'OK' THEN
       RAISE EXP_AUTH_REJECT_RECORD; --updated by Ramesh.A on 22/05/2012
     END IF;
    EXCEPTION
     WHEN EXP_AUTH_REJECT_RECORD THEN
       --Added by Ramesh.A on 22/05/2012
       RAISE;
     WHEN OTHERS THEN
       P_RESP_CODE := '21';
       P_ERR_MSG   := 'Error while calling SP_AUTHORIZE_TXN_CMS_AUTH' ||
                   SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --Updating reopen status
    BEGIN
     UPDATE CMS_ACCT_MAST
        SET CAM_STAT_CODE     = V_ACCT_STATUS,
           CAM_CREATION_DATE = SYSDATE,
           CAM_LUPD_DATE     = SYSDATE,
           CAM_LUPD_USER     = 1,
           cam_acct_crea_tnfr_date=sysdate --Added  for Transactionlog Functional Removal Phase-II changes
      WHERE CAM_ACCT_NO = V_SAVING_ACCTNO AND CAM_TYPE_CODE = V_ACCT_TYPE AND
           CAM_INST_CODE = P_INST_CODE;

     IF SQL%ROWCOUNT = 0 THEN
       P_RESP_CODE := '21';
       P_ERR_MSG   := 'Reopen status is not updated ';
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '12';
       P_ERR_MSG   := 'Error while updating reopen status ' ||
                   SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    P_RESP_CODE := '1';

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = P_RESP_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       P_RESP_CODE := '12';
       P_ERR_MSG   := 'Responce code is not found ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '69';
       P_ERR_MSG   := 'Error while selecting cms_response_mast ' ||
                   SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
    --Added for VMS-5733/FSP-991
    IF (v_Retdate>v_Retperiod)
    THEN
     UPDATE TRANSACTIONLOG
        SET --RESPONSE_ID   = P_RESP_CODE,   --Commented by Pankaj S. during DFCCSD-70(Review) changes
           ADD_LUPD_DATE = SYSDATE,
           ADD_LUPD_USER = 1,
           ERROR_MSG     = P_ERR_MSG
      WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND MSGTYPE = P_MSGTYPE AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INST_CODE;
       ELSE
            UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
        SET --RESPONSE_ID   = P_RESP_CODE,   --Commented by Pankaj S. during DFCCSD-70(Review) changes
           ADD_LUPD_DATE = SYSDATE,
           ADD_LUPD_USER = 1,
           ERROR_MSG     = P_ERR_MSG
      WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND MSGTYPE = P_MSGTYPE AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INST_CODE;
  END IF;
     --Sn Un-commented by Pankaj S. during DFCCSD-70(Review) changes
     IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         p_err_msg := 'transactionlog is not updated ';
         RAISE exp_reject_record;
     END IF;
     --En Un-commented by Pankaj S. during DFCCSD-70(Review) changes
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '21';
       P_ERR_MSG   := 'Error while updating transactionlog ' ||
                   SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
 ELSE
    P_RESP_CODE := '123';
    P_ERR_MSG   := 'Savings Account Re-Open Duration is not completed';
    RAISE EXP_REJECT_RECORD;
 END IF;

  V_SAVEPOINT := V_SAVEPOINT + 1;
EXCEPTION
  WHEN EXP_AUTH_REJECT_RECORD THEN
  NULL;
    --Added by Ramesh.A on 22/05/2012
    /*ROLLBACK TO V_SAVEPOINT;  --Commented by Besky on 06-nov-12

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = P_RESP_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERR_MSG   := 'Error while selecting cms_response_mast 1' ||
                   SUBSTR(SQLERRM, 1, 200);
       P_RESP_CODE := '69';
    END;

    BEGIN
     INSERT INTO TRANSACTIONLOG
       (MSGTYPE,
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
        IPADDRESS,
        ANI,
        DNI,
        TRANS_DESC,
        RESPONSE_ID,
        CUSTOMER_ACCT_NO -- FOR Transaction detail report issue
        )
     VALUES
       (P_MSGTYPE,
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
        V_ENCR_PAN,
        P_ERR_MSG,
        P_IPADDRESS,
        P_ANI,
        P_DNI,
        V_TRANS_DESC,
        P_RESP_CODE,
        V_SAVING_ACCTNO -- FOR Transaction detail report issue
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '12';
       P_ERR_MSG   := 'Error while inserting TRANSACTIONLOG 1' ||
                   SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_INST_CODE,
        CTD_INS_DATE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        CTD_CUST_ACCT_NUMBER)
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        'E',
        P_ERR_MSG,
        P_RRN,
        P_INST_CODE,
        SYSDATE,
        V_ENCR_PAN,
        P_MSGTYPE,
        V_SAVING_ACCTNO);
    EXCEPTION
     WHEN OTHERS THEN
       P_ERR_MSG   := 'Error while inserting cms_transaction_log_dt l' ||
                   SUBSTR(SQLERRM, 1, 200);
       P_RESP_CODE := '69';
       RETURN;
    END;*/
  WHEN EXP_REJECT_RECORD THEN
    ROLLBACK TO V_SAVEPOINT;

    v_resp_cde:= P_RESP_CODE;  --Added by Pankaj S. during DFCCSD-70(Review) changes

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = P_RESP_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERR_MSG   := 'Error while selecting cms_response_mast 1' ||
                   SUBSTR(SQLERRM, 1, 200);
       P_RESP_CODE := '69';
    END;

    --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
    IF v_dr_cr_flag IS NULL THEN
    BEGIN
       SELECT ctm_credit_debit_flag,
              TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
              ctm_tran_desc
         INTO v_dr_cr_flag,
              v_txn_type,
              v_trans_desc
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

    IF v_prod_code IS NULL THEN
    BEGIN
       SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
         INTO v_prod_code, v_card_type, v_card_stat,v_acct_number
         FROM cms_appl_pan
        WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS
       THEN
          NULL;
    END;
    END IF;
    --En Added by Pankaj S. during DFCCSD-70(Review) changes

    --Sn Added by Pankaj S. for DFCCSD-70 changes
    BEGIN
       SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
         INTO v_avail_bal, v_ledger_bal, v_acct_type
         FROM cms_acct_mast
        WHERE cam_inst_code = p_inst_code
          AND cam_acct_no =v_acct_number;
    EXCEPTION
       WHEN OTHERS THEN
          v_avail_bal := 0;
          v_ledger_bal := 0;
    END;
    --En Added by Pankaj S. for DFCCSD-70 changes

    BEGIN
     INSERT INTO TRANSACTIONLOG
       (MSGTYPE,
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
        IPADDRESS,
        ANI,
        DNI,
        TRANS_DESC,
        RESPONSE_ID,
        CUSTOMER_ACCT_NO, -- FOR Transaction detail report issue
        --Sn Added by Pankaj S. for DFCCSD-70 changes
        acct_balance,
        ledger_balance,
        acct_type,
        --En Added by Pankaj S. for DFCCSD-70 changes
        --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
        cr_dr_flag,
        productid,
        categoryid,
        cardstatus,
        time_stamp
        --En Added by Pankaj S. during DFCCSD-70(Review) changes
        )
     VALUES
       (P_MSGTYPE,
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
        V_ENCR_PAN,
        P_ERR_MSG,
        P_IPADDRESS,
        P_ANI,
        P_DNI,
        V_TRANS_DESC,
        v_resp_cde, --P_RESP_CODE,  --Modified by Pankaj S. during DFCCSD-70(Review) changes
        --V_SAVING_ACCTNO -- FOR Transaction detail report issue
        --Sn Added by Pankaj S. for DFCCSD-70 changes
        v_acct_number,
        v_avail_bal,
        v_ledger_bal,
        v_acct_type,
        --En Added by Pankaj S. for DFCCSD-70 changes
        --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
        v_dr_cr_flag,
        v_prod_code,
        v_card_type,
        v_card_stat,
        systimestamp
        --En Added by Pankaj S. during DFCCSD-70(Review) changes
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '12';
       P_ERR_MSG   := 'Error while inserting TRANSACTIONLOG 1' ||
                   SUBSTR(SQLERRM, 1, 200);
       --RAISE EXP_REJECT_RECORD;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
    END;

    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_INST_CODE,
        CTD_INS_DATE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        CTD_CUST_ACCT_NUMBER)
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        'E',
        P_ERR_MSG,
        P_RRN,
        P_INST_CODE,
        SYSDATE,
        V_ENCR_PAN,
        P_MSGTYPE,
        v_acct_number--V_SAVING_ACCTNO  --Modified by Pankaj S. for DFCCSD-70 changes
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_ERR_MSG   := 'Error while inserting cms_transaction_log_dt l' ||
                   SUBSTR(SQLERRM, 1, 200);
       P_RESP_CODE := '69';
       RETURN;
    END;

  WHEN OTHERS THEN
    P_RESP_CODE := '21';
    P_ERR_MSG   := 'Main Exception ' || SUBSTR(SQLERRM, 1, 200);
    ROLLBACK TO V_SAVEPOINT;
    v_resp_cde:= P_RESP_CODE;  --Added by Pankaj S. during DFCCSD-70(Review) changes

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = P_RESP_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERR_MSG   := 'Error while selecting cms_response_mast 1' ||
                   SUBSTR(SQLERRM, 1, 200);
       P_RESP_CODE := '69';
    END;

    --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
    IF v_dr_cr_flag IS NULL THEN
    BEGIN
       SELECT ctm_credit_debit_flag,
              TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
              ctm_tran_desc
         INTO v_dr_cr_flag,
              v_txn_type,
              v_trans_desc
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

    IF v_prod_code IS NULL THEN
    BEGIN
       SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
         INTO v_prod_code, v_card_type, v_card_stat,v_acct_number
         FROM cms_appl_pan
        WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS
       THEN
          NULL;
    END;
    END IF;
    --En Added by Pankaj S. during DFCCSD-70(Review) changes

    --Sn Added by Pankaj S. for DFCCSD-70 changes
    BEGIN
       SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
         INTO v_avail_bal, v_ledger_bal, v_acct_type
         FROM cms_acct_mast
        WHERE cam_inst_code = p_inst_code
          AND cam_acct_no =v_acct_number;
    EXCEPTION
       WHEN OTHERS THEN
          v_avail_bal := 0;
          v_ledger_bal := 0;
    END;
    --En Added by Pankaj S. for DFCCSD-70 changes

    BEGIN
     INSERT INTO TRANSACTIONLOG
       (MSGTYPE,
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
        IPADDRESS,
        ANI,
        DNI,
        TRANS_DESC,
        RESPONSE_ID,
        CUSTOMER_ACCT_NO, -- FOR Transaction detail report issue
        --Sn Added by Pankaj S. for DFCCSD-70 changes
        acct_balance,
        ledger_balance,
        acct_type,
        --En Added by Pankaj S. for DFCCSD-70 changes
        --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
        cr_dr_flag,
        productid,
        categoryid,
        cardstatus,
        time_stamp
        --En Added by Pankaj S. during DFCCSD-70(Review) changes
        )
     VALUES
       (P_MSGTYPE,
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
        V_ENCR_PAN,
        P_ERR_MSG,
        P_IPADDRESS,
        P_ANI,
        P_DNI,
        V_TRANS_DESC,
        v_resp_cde, --P_RESP_CODE,  --Modified by Pankaj S. during DFCCSD-70(Review) changes
        --V_SAVING_ACCTNO -- FOR Transaction detail report issue
        --Sn Added by Pankaj S. for DFCCSD-70 changes
        v_acct_number,
        v_avail_bal,
        v_ledger_bal,
        v_acct_type,
        --En Added by Pankaj S. for DFCCSD-70 changes
        --Sn Added by Pankaj S. during DFCCSD-70(Review) changes
        v_dr_cr_flag,
        v_prod_code,
        v_card_type,
        v_card_stat,
        systimestamp
        --En Added by Pankaj S. during DFCCSD-70(Review) changes
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '12';
       P_ERR_MSG   := 'Error while inserting TRANSACTIONLOG 2' ||
                   SUBSTR(SQLERRM, 1, 200);
       --RAISE EXP_REJECT_RECORD;  --Commented by Pankaj S. during DFCCSD-70(Review) changes
    END;

    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_INST_CODE,
        CTD_INS_DATE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        CTD_CUST_ACCT_NUMBER)
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        'E',
        P_ERR_MSG,
        P_RRN,
        P_INST_CODE,
        SYSDATE,
        V_ENCR_PAN,
        P_MSGTYPE,
        v_acct_number --V_SAVING_ACCTNO  --Modified by Pankaj S. for DFCCSD-70 changes
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_ERR_MSG   := 'Error while inserting cms_transaction_log_dt 2' ||
                   SUBSTR(SQLERRM, 1, 200);
       P_RESP_CODE := '69';
       RETURN;
    END;
END;
/
show error