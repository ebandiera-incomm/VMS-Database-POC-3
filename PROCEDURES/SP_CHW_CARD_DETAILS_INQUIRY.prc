CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHW_CARD_DETAILS_INQUIRY(P_INST_CODE         IN NUMBER,
                                             P_MSG               IN VARCHAR2,
                                             P_RRN               VARCHAR2,
                                             P_DELIVERY_CHANNEL  VARCHAR2,
                                             P_TERM_ID           VARCHAR2,
                                             P_TXN_CODE          VARCHAR2,
                                             P_TXN_MODE          VARCHAR2,
                                             P_TRAN_DATE         VARCHAR2,
                                             P_TRAN_TIME         VARCHAR2,
                                             P_CUSTOMER_ID       NUMBER,  --Modified varchar to number for FSS-1710
                                             P_BANK_CODE         VARCHAR2,
                                             P_TXN_AMT           NUMBER,
                                             P_RULE_INDICATOR    VARCHAR2,
                                             P_RULEGRP_ID        VARCHAR2,
                                             P_MCC_CODE          VARCHAR2,
                                             P_CURR_CODE         VARCHAR2,
                                             P_PROD_ID           VARCHAR2,
                                             P_CATG_ID           VARCHAR2,
                                             P_TIP_AMT           VARCHAR2,
                                             P_DECLINE_RULEID    VARCHAR2,
                                             P_ATMNAME_LOC       VARCHAR2,
                                             P_MCCCODE_GROUPID   VARCHAR2,
                                             P_CURRCODE_GROUPID  VARCHAR2,
                                             P_TRANSCODE_GROUPID VARCHAR2,
                                             P_RULES             VARCHAR2,
                                             P_PREAUTH_DATE      DATE,
                                             P_CONSODIUM_CODE    IN VARCHAR2,
                                             P_PARTNER_CODE      IN VARCHAR2,
                                             P_EXPRY_DATE        IN VARCHAR2,
                                             P_STAN              IN VARCHAR2,
                                             P_MBR_NUMB          IN VARCHAR2,
                                             P_PREAUTH_EXPPERIOD IN VARCHAR2,
                                             P_INTERNATIONAL_IND IN VARCHAR2,
                                             P_RVSL_CODE         IN NUMBER,
                                             P_TRAN_CNT          IN NUMBER,
                                             P_MONTH_YEAR        IN VARCHAR2,
                                             P_IPADDRESS         IN VARCHAR2,
                                             P_CARD_NUM          IN VARCHAR2, -- added by siva kumar m as on 25/10/2012.
                                             P_AUTH_ID           OUT VARCHAR2,
                                             P_RESP_CODE         OUT VARCHAR2,
                                             P_RESP_MSG          OUT CLOB,
                                             P_CARD_COUNT        OUT VARCHAR2) IS

  /*************************************************
      * Created By       :  Sivapragasam M
      * Created Date     :  15-May-2012
      * Created Reason   :  Added for CHW Card Details Inquiry Transaction
      * Modified By      :  siva kumar M
       * Modified Date   :  25-10-2012
      * Modified Reason  :  Modified for Appove and Decline transaction status.
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  25-OCT-2012
     * Release Number     :  CMS3.4.3_RI0020_B0007

      * Modified Date    : 10-Dec-2013
      * Modified By      : Sagar More
      * Modified for     : Defect ID 13160
      * Modified reason  : To log below details in transactinlog if applicable
                           Account Type,Timestamp,Error_msg
      * Reviewer         : Dhiraj
      * Reviewed Date    : 10-Dec-2013
      * Release Number   : RI0024.7_B0001

      * Modified Date    : 18-Jun-2014
      * Modified By      : Ramesh
      * Modified for     : FSS-1710 :Performance changes
      * Reviewer         : spankaj
      * Reviewed Date    : 19-Jun-2014
      * Release Number   : RI0027.1.9_B0001

      * Modified by      : MageshKumar S.
      * Modified Date    : 25-July-14
      * Modified For     : FWR-48
      * Modified reason  : GL Mapping removal changes
      * Reviewer         : Spankaj
      * Build Number     : RI0027.3.1_B0001
      
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-15-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991

  *************************************************/
  V_ERR_MSG            VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE       NUMBER;
  V_LEDGER_BAL         NUMBER;
  V_TRAN_AMT           NUMBER;
  V_AUTH_ID            TRANSACTIONLOG.AUTH_ID%TYPE;
  V_TOTAL_AMT          NUMBER;
  V_TRAN_DATE          DATE;
  --V_FUNC_CODE          CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE; --commented for fwr-48
  V_PROD_CODE          CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE       CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT            NUMBER;
  --V_TOTAL_FEE          NUMBER;
  --V_UPD_AMT            NUMBER;
 -- V_UPD_LEDGER_AMT     NUMBER;
  V_NARRATION          VARCHAR2(50);
  --V_FEE_OPENING_BAL    NUMBER;
  V_RESP_CDE           VARCHAR2(5);
  V_EXPRY_DATE         DATE;
  V_DR_CR_FLAG         VARCHAR2(2);
  V_OUTPUT_TYPE        VARCHAR2(2);
  V_APPLPAN_CARDSTAT   CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  --V_PRECHECK_FLAG      NUMBER;
  --V_PREAUTH_FLAG       NUMBER;
  --V_AVAIL_PAN          CMS_AVAIL_TRANS.CAT_PAN_CODE%TYPE;
  V_GL_UPD_FLAG        TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  --V_GL_ERR_MSG         VARCHAR2(500);
  --V_SAVEPOINT          NUMBER := 0;
  V_TRAN_FEE           NUMBER;
  V_ERROR              VARCHAR2(500);
  V_BUSINESS_DATE_TRAN DATE;
  V_BUSINESS_TIME      VARCHAR2(5);
  --V_CUTOFF_TIME        VARCHAR2(5);
  V_CARD_CURR          VARCHAR2(5);
  V_FEE_CODE           CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  --V_FEE_CRGL_CATG      CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  --V_FEE_CRGL_CODE      CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
 -- V_FEE_CRSUBGL_CODE   CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO      CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG      CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE      CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE   CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO      CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  --st AND cess
 -- V_SERVICETAX_PERCENT CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  --V_CESS_PERCENT       CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_SERVICETAX_AMOUNT  NUMBER;
  V_CESS_AMOUNT        NUMBER;
  V_ST_CALC_FLAG       CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
  V_CESS_CALC_FLAG     CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
  V_ST_CRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
  V_ST_DRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
  V_CESS_CRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
  V_CESS_DRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
  --V_WAIV_PERCNT        CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  --V_ERR_WAIV           VARCHAR2(300);
  --V_LOG_ACTUAL_FEE     NUMBER;
  --V_LOG_WAIVER_AMT     NUMBER;
  --V_AUTH_SAVEPOINT     NUMBER DEFAULT 0;
  --V_ACTUAL_EXPRYDATE   DATE;
  V_BUSINESS_DATE      DATE;
  V_TXN_TYPE           NUMBER(1);
  --V_MINI_TOTREC        NUMBER(2);
  --V_MINISTMT_ERRMSG    VARCHAR2(500);
  --V_MINISTMT_OUTPUT    VARCHAR2(900);
  EXP_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  --V_PREAUTH_DATE            DATE;
  --V_PREAUTH_HOLD            VARCHAR2(1);
  --V_PREAUTH_PERIOD          NUMBER;
  --V_PREAUTH_USAGE_LIMIT     NUMBER;
  --V_CARD_ACCT_NO            VARCHAR2(20);
  --V_HOLD_AMOUNT             NUMBER;
  V_RRN_COUNT               NUMBER;
  V_TRAN_TYPE               VARCHAR2(2);
 -- V_DATE                    DATE;
  V_TIME                    VARCHAR2(10);
  --V_MAX_CARD_BAL            NUMBER;
  --V_CURR_DATE               DATE;
  --V_PREAUTH_EXP_PERIOD      VARCHAR2(10);
  V_CARD_DETAIL_INQUIRY_RES CLOB;
  V_CARD_DETAIL_INQUIRY_VAL CLOB;
  --V_PRE_AUTH_DET            CLOB;
  --V_PRE_AUTH_DET_VAL        CLOB;
  --V_INTERNATIONAL_FLAG      CHARACTER(1);
  V_PROXUNUMBER             CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER             CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  --V_MONTH_YEAR              DATE;
  --V_MON_YEAR_TEMP           VARCHAR2(6);
  --V_MONTH_DET               CLOB;
  -- V_AUTHID_DATE             VARCHAR2(8);
  --V_STATUS_CHK NUMBER;
  --TCOUNT       VARCHAR2(3);

  -- St Added by siva kumar m as on 22/10/2012
   V_RESPCODE        VARCHAR2(5);
   V_RESPMSG         VARCHAR2(500);
   V_CAPTURE_DATE    DATE;
   V_INIL_AUTHID     TRANSACTIONLOG.AUTH_ID%TYPE;
   -- En Added by siva kumar m as on 22/10/2012

   --Added on 10-Dec-2013 for 13160
   v_timestamp timestamp(3);
   v_acct_type cms_acct_mast.cam_type_code%type;
   --Added on 10-Dec-2013 for 13160

   --SN Added for 13160
   v_card_type    CMS_APPL_PAN.cap_card_type%type;
   v_cardstat     CMS_APPL_PAN.cap_card_stat%type;
   v_acct_no      CMS_ACCT_MAST.cam_acct_no%type;
   --EN Added for 13160

   V_CARD_COUNT NUMBER DEFAULT 0; --Added for FSS-1710
   
     v_Retperiod  date; --Added for VMS-5733/FSP-991
     v_Retdate  date; --Added for VMS-5733/FSP-991

  CURSOR C_CARD_DETAIL_INQUIRY IS
    SELECT X.*
     FROM (SELECT FN_DMAPS_MAIN(CAP_PAN_CODE_ENCR) || '||' || CAP_CARD_STAT
            FROM CMS_APPL_PAN , CMS_CUST_MAST
           WHERE CAP_INST_CODE=CCM_INST_CODE AND CAP_INST_CODE=P_INST_CODE
           AND CAP_CUST_CODE=CCM_CUST_CODE AND CCM_CUST_ID=P_CUSTOMER_ID
          ) X;  --Modified for FSS-1710

BEGIN
  --SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE := '1';
  P_RESP_MSG := 'OK';


    --SN CHECK INST CODE
    BEGIN
     IF P_INST_CODE IS NULL THEN
       V_RESP_CDE := '12'; -- Invalid Transaction
       V_ERR_MSG  := 'Institute code cannot be null ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '12'; -- Invalid Transaction
       V_ERR_MSG  := 'Institute code cannot be null ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --EN CHECK INST CODE

   /* BEGIN
     V_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '45'; -- Server Declined -220509
       V_ERR_MSG  := 'Problem while converting transaction date ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;*/

    BEGIN
     V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                        SUBSTR(TRIM(P_TRAN_TIME), 1, 10),
                        'yyyymmdd hh24:mi:ss');
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '32'; -- Server Declined -220509
       V_ERR_MSG  := 'Problem while converting transaction time ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --Sn find debit and credit flag
    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE ,CTM_TRAN_DESC     --review changes done for FSS-1710
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_NARRATION --review changes done for FSS-1710
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '12'; --Ineligible Transaction
       V_ERR_MSG  := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                  ' and delivery channel ' || P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; --Ineligible Transaction
       V_ERR_MSG  := 'Error while selecting transaction details';
       RAISE EXP_REJECT_RECORD;
    END;

    --En find debit and credit flag

    --Sn Duplicate RRN Check
    BEGIN
    
   --Added for VMS-5733/FSP-991
           select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');
      
  IF (v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     else
       SELECT COUNT(1)   --Added for VMS-5733/FSP-991
       INTO V_RRN_COUNT
       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     end if;      
     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERR_MSG  := 'Duplicate RRN from the Terminal ' || P_TERM_ID ||
                  ' on ' || P_TRAN_DATE;
       RAISE EXP_REJECT_RECORD;      
     END IF;
     
     EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
        RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; --Ineligible Transaction
       V_ERR_MSG  := 'Error while selecting RRN ';
       RAISE EXP_REJECT_RECORD;
    END;

    --En Duplicate RRN Check
    --Sn commented for fwr-48
    --Sn find function code attached to txn code
  /*  BEGIN
     SELECT CFM_FUNC_CODE
       INTO V_FUNC_CODE
       FROM CMS_FUNC_MAST
      WHERE CFM_TXN_CODE = P_TXN_CODE AND CFM_TXN_MODE = P_TXN_MODE AND
           CFM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CFM_INST_CODE = P_INST_CODE;
     --TXN mode and delivery channel we need to attach
     --bkz txn code may be same for all type of channels
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '69'; --Ineligible Transaction
       V_ERR_MSG  := 'Function code not defined for txn code ' ||
                  P_TXN_CODE;
       RAISE EXP_REJECT_RECORD;
     WHEN TOO_MANY_ROWS THEN
       V_RESP_CDE := '69';
       V_ERR_MSG  := 'More than one function defined for txn code ' ||
                  P_TXN_CODE;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '69';
       V_ERR_MSG  := 'Error while selecting CMS_FUNC_MAST ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;*/

    --En find function code attached to txn code

    --En commented for fwr-48

     --Sn call to authorize txn  added by siva kumar m as on 22/10/2012

    BEGIN
     SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                          '0200',
                          P_RRN,
                          P_DELIVERY_CHANNEL,
                          '0',
                          P_TXN_CODE,
                          0,
                          P_TRAN_DATE,
                          P_TRAN_TIME,
                          P_CARD_NUM,
                          NULL,
                          0,
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
                          '0', -- P_stan
                          '000', --Ins User
                          '00', --INS Date
                          0,
                          V_INIL_AUTHID,
                          V_RESP_CDE,
                          V_RESPMSG,
                          V_CAPTURE_DATE);

     IF V_RESP_CDE <> '00' AND V_RESPMSG <> 'OK' THEN
        V_ERR_MSG := V_RESPMSG;
       RAISE EXP_AUTH_REJECT_RECORD;
     END IF;

    EXCEPTION
     WHEN EXP_AUTH_REJECT_RECORD THEN
       RAISE;

     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG   := 'Error from Card authorization' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
    --En call to authorize txn

  /* Commented not not required(review changes) FSS-1710
    --Sn find narration
    BEGIN
     SELECT CTM_TRAN_DESC
       INTO V_NARRATION
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_NARRATION := 'Transaction type ' || P_TXN_CODE;
     WHEN OTHERS THEN
       V_NARRATION := 'Transaction type ' || P_TXN_CODE;
    END;

    --En find narration
  */
    --Sn for Card count select
  /* Commented for not required in FSS-1710
    BEGIN

     SELECT COUNT(*)
       INTO P_CARD_COUNT
       FROM CMS_APPL_PAN
      WHERE CAP_CUST_CODE IN
           (SELECT CCM_CUST_CODE
             FROM CMS_CUST_MAST
            WHERE CCM_CUST_ID = P_CUSTOMER_ID);

    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14';
       V_ERR_MSG  := 'CUSTOMER ID NOT FOUND ' || P_CUSTOMER_ID;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Problem while selecting card count for Customer Id' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
  */
    --En for Card count select

    IF P_TXN_CODE = '31' AND P_DELIVERY_CHANNEL = '10' THEN

     BEGIN

       OPEN C_CARD_DETAIL_INQUIRY;
       LOOP

        FETCH C_CARD_DETAIL_INQUIRY
          INTO V_CARD_DETAIL_INQUIRY_VAL;

        EXIT WHEN C_CARD_DETAIL_INQUIRY%NOTFOUND;

        IF V_CARD_DETAIL_INQUIRY_RES IS NULL THEN
          V_CARD_DETAIL_INQUIRY_RES := V_CARD_DETAIL_INQUIRY_VAL;
        ELSE
          V_CARD_DETAIL_INQUIRY_RES := V_CARD_DETAIL_INQUIRY_RES || '||' ||
                                 V_CARD_DETAIL_INQUIRY_VAL;
        END IF;

        V_CARD_COUNT := V_CARD_COUNT + 1; --Added for FSS-1710

       END LOOP;
       CLOSE C_CARD_DETAIL_INQUIRY;

       P_RESP_MSG :=V_CARD_DETAIL_INQUIRY_RES;
       P_CARD_COUNT := V_CARD_COUNT;  --Added for FSS-1710

     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Problem while opening cursor c_card_detail_inquiry' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
     /* IF (V_CARD_DETAIL_INQUIRY_RES IS NULL) THEN
       V_CARD_DETAIL_INQUIRY_RES := ' ';
      ELSE
       V_CARD_DETAIL_INQUIRY_RES := SUBSTR(V_CARD_DETAIL_INQUIRY_RES,
                            5,
                            LENGTH(V_CARD_DETAIL_INQUIRY_RES));
      END IF; */
    END IF;

  -- commented by siva kumar m as on 25/10/2012 for decline and approve transaction.
   /* --Sn create a entry for successful
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        CTD_ACTUAL_AMOUNT,
        CTD_FEE_AMOUNT,
        CTD_WAIVER_AMOUNT,
        CTD_SERVICETAX_AMOUNT,
        CTD_CESS_AMOUNT,
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_INST_CODE,
        CTD_CUST_ACCT_NUMBER)
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_MSG,
        P_TXN_MODE,
        P_TRAN_DATE,
        P_TRAN_TIME,
        P_TXN_AMT,
        P_CURR_CODE,
        V_TRAN_AMT,
        V_LOG_ACTUAL_FEE,
        V_LOG_WAIVER_AMT,
        V_SERVICETAX_AMOUNT,
        V_CESS_AMOUNT,
        V_TOTAL_AMT,
        V_CARD_CURR,
        'Y',
        'Successful',
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ACCT_NUMBER);
     --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while inserting data in to CMS_TRANSACTION_LOG_DTL' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END; */

    --En create a entry for successful
    -- commented by siva kumar m as on 25/10/2012 for decline and approve transaction.

    -- V_RESP_CDE := '1';

    ---En Updation of Usage limit and amount

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = 1; --TO_NUMBER(V_RESP_CDE);
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERR_MSG  := 'NO DATA IN response master for response code for delivery channel:' ||
                  P_DELIVERY_CHANNEL; --Modified by Ramkumarmk.on 28th May, spelling mistake
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master for response code' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --Commented by srinivasu already inserting is done for ipaddress fro Defect 7643 fix
    /*
    BEGIN
     UPDATE /*+RULE*/ /*TRANSACTIONLOG
          SET IPADDRESS = P_IPADDRESS
        WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
             TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
             BUSINESS_TIME = P_TRAN_TIME AND
             DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
         IF SQL%ROWCOUNT = 0 THEN
            P_RESP_CODE := '69';
            V_ERR_MSG  := 'Updating transaction log  dtl error for rrn:'||  P_RRN || '- '  ||P_TRAN_DATE || '- '  || P_TXN_CODE || '- '   || P_MSG || '- '   || P_TRAN_TIME  || '- '   || P_DELIVERY_CHANNEL ;
            RAISE EXP_REJECT_RECORD;
         END IF;
      EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
       RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
         P_RESP_CODE := '69';
         P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                      SUBSTR(SQLERRM, 1, 300);
                      RAISE EXP_REJECT_RECORD;
      END;*/
  EXCEPTION

  WHEN EXP_AUTH_REJECT_RECORD THEN

    P_RESP_MSG    := V_ERR_MSG;
    P_RESP_CODE := V_RESP_CDE;


    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     ROLLBACK ;--TO V_AUTH_SAVEPOINT;

     --Sn select response code and insert record into txn log dtl
     BEGIN
       -- P_RESP_CODE := V_RESP_CDE;
       -- P_RESP_MSG  := V_ERR_MSG;
       -- Assign the response code to the out parameter
       SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INST_CODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;
       P_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        P_RESP_MSG  := 'NO DATA from response master for delivery channel2:' ||
                    P_DELIVERY_CHANNEL || --Modified by Ramkumar.mk change the spelling mistate
                    V_RESP_CDE;
        P_RESP_CODE := '69';
        RETURN;
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while selecting data from response master2 ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69';
        ---ISO MESSAGE FOR DATABASE ERROR Server Declined
        -- ROLLBACK;
        RETURN;
     END;

     --SN : Added on 10-Dec-2013 for 13160

     if V_DR_CR_FLAG is null
      then

        BEGIN

         SELECT CTM_CREDIT_DEBIT_FLAG,CTM_TRAN_DESC,TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1'))  --review changes done for FSS-1710
           INTO V_DR_CR_FLAG,V_NARRATION,V_TXN_TYPE  --review changes done for FSS-1710
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE AND
               CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
               CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN OTHERS THEN
         null;
        END;

     end if;


    BEGIN

     SELECT cap_prod_code,cap_card_type,cap_card_stat,cap_acct_no
       INTO v_prod_code,v_card_type,v_applpan_cardstat,v_acct_number
       FROM CMS_APPL_PAN
      WHERE cap_inst_code = P_INST_CODE
      and   cap_pan_code = gethash(P_CARD_NUM);

    EXCEPTION
     WHEN OTHERS THEN
            null;
    END;
      --Added below code for review changes done for FSS-1710
       BEGIN

        select cam_type_code,cam_acct_bal,cam_ledger_bal
        into   v_acct_type,  v_acct_balance,v_ledger_bal
        from cms_acct_mast
        where cam_inst_code = P_INST_CODE
        and   cam_acct_no = v_acct_number;
      EXCEPTION
        WHEN  OTHERS THEN
        null;

      END;

    v_timestamp := systimestamp;

    --EN : Added on 10-Dec-2013  for 13160

     BEGIN
       INSERT INTO CMS_TRANSACTION_LOG_DTL
        (CTD_DELIVERY_CHANNEL,
         CTD_TXN_CODE,
         CTD_TXN_TYPE,
         CTD_MSG_TYPE,
         CTD_TXN_MODE,
         CTD_BUSINESS_DATE,
         CTD_BUSINESS_TIME,
         CTD_TXN_AMOUNT,
         CTD_TXN_CURR,
         CTD_ACTUAL_AMOUNT,
         CTD_FEE_AMOUNT,
         CTD_WAIVER_AMOUNT,
         CTD_SERVICETAX_AMOUNT,
         CTD_CESS_AMOUNT,
         CTD_BILL_AMOUNT,
         CTD_BILL_CURR,
         CTD_PROCESS_FLAG,
         CTD_PROCESS_MSG,
         CTD_RRN,
         CTD_SYSTEM_TRACE_AUDIT_NO,
         CTD_INST_CODE,
         CTD_CUST_ACCT_NUMBER)
       VALUES
        (P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_MSG,
         P_TXN_MODE,
         P_TRAN_DATE,
         P_TRAN_TIME,
         P_TXN_AMT,
         P_CURR_CODE,
         V_TRAN_AMT,
         NULL,
         NULL,
         NULL,
         NULL,
         V_TOTAL_AMT,
         V_CARD_CURR,
         'E',
         V_ERR_MSG,
         P_RRN,
         P_STAN,
         P_INST_CODE,
         V_ACCT_NUMBER);

       P_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        ROLLBACK;
        RETURN;
     END;
      --Sn create a entry in txn log
  BEGIN
    INSERT INTO TRANSACTIONLOG
     (MSGTYPE,
      RRN,
      DELIVERY_CHANNEL,
      TERMINAL_ID,
      DATE_TIME,
      TXN_CODE,
      TXN_TYPE,
      TXN_MODE,
      TXN_STATUS,
      RESPONSE_CODE,
      BUSINESS_DATE,
      BUSINESS_TIME,
      TOPUP_CARD_NO,
      TOPUP_ACCT_NO,
      TOPUP_ACCT_TYPE,
      BANK_CODE,
      TOTAL_AMOUNT,
      RULE_INDICATOR,
      RULEGROUPID,
      MCCODE,
      CURRENCYCODE,
      ADDCHARGE,
      PRODUCTID,
      CATEGORYID,
      TIPS,
      DECLINE_RULEID,
      ATM_NAME_LOCATION,
      AUTH_ID,
      TRANS_DESC,
      AMOUNT,
      PREAUTHAMOUNT,
      PARTIALAMOUNT,
      MCCODEGROUPID,
      CURRENCYCODEGROUPID,
      TRANSCODEGROUPID,
      RULES,
      PREAUTH_DATE,
      GL_UPD_FLAG,
      SYSTEM_TRACE_AUDIT_NO,
      INSTCODE,
      FEECODE,
      TRANFEE_AMT,
      SERVICETAX_AMT,
      CESS_AMT,
      CR_DR_FLAG,
      TRANFEE_CR_ACCTNO,
      TRANFEE_DR_ACCTNO,
      TRAN_ST_CALC_FLAG,
      TRAN_CESS_CALC_FLAG,
      TRAN_ST_CR_ACCTNO,
      TRAN_ST_DR_ACCTNO,
      TRAN_CESS_CR_ACCTNO,
      TRAN_CESS_DR_ACCTNO,
      TOPUP_CARD_NO_ENCR,
      PROXY_NUMBER,
      REVERSAL_CODE,
      CUSTOMER_ACCT_NO,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      RESPONSE_ID,
      IPADDRESS,
      CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
      --Added on 10-Dec-2013 for 13160
      acct_type,
      Time_stamp,
      error_msg
      --Added on 10-Dec-2013 for 13160
      )
    VALUES
     (P_MSG,
      P_RRN,
      P_DELIVERY_CHANNEL,
      P_TERM_ID,
      V_BUSINESS_DATE,
      P_TXN_CODE,
      V_TXN_TYPE,
      P_TXN_MODE,
      DECODE(P_RESP_CODE, '00', 'C', 'F'),
      P_RESP_CODE,
      P_TRAN_DATE,
      SUBSTR(P_TRAN_TIME, 1, 10),
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_BANK_CODE,
      TRIM(TO_CHAR(nvl(V_TOTAL_AMT,0), '99999999999999990.99')), --modified for 13160
      P_RULE_INDICATOR,
      P_RULEGRP_ID,
      P_MCC_CODE,
      P_CURR_CODE,
      NULL, -- P_add_charge,
      V_PROD_CODE,
      v_card_type,--V_PROD_CATTYPE, commented for 13160
      nvl(P_TIP_AMT,0),
      P_DECLINE_RULEID,
      P_ATMNAME_LOC,
      V_AUTH_ID,
      V_NARRATION,
      TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')), --modified for 13160
      '0.00',--NULL,     --modified for 13160
      '0.00',--NULL, -- Partial amount (will be given for partial txn) --modified for 13160
      P_MCCCODE_GROUPID,
      P_CURRCODE_GROUPID,
      P_TRANSCODE_GROUPID,
      P_RULES,
      P_PREAUTH_DATE,
      V_GL_UPD_FLAG,
      P_STAN,
      P_INST_CODE,
      V_FEE_CODE,
      nvl(V_FEE_AMT,0),             --modified for 13160
      nvl(V_SERVICETAX_AMOUNT,0),   --modified for 13160
      nvl(V_CESS_AMOUNT,0),         --modified for 13160
      V_DR_CR_FLAG,
      V_FEE_CRACCT_NO,
      V_FEE_DRACCT_NO,
      V_ST_CALC_FLAG,
      V_CESS_CALC_FLAG,
      V_ST_CRACCT_NO,
      V_ST_DRACCT_NO,
      V_CESS_CRACCT_NO,
      V_CESS_DRACCT_NO,
      NULL,
      V_PROXUNUMBER,
      P_RVSL_CODE,
      V_ACCT_NUMBER,
      NVL(V_ACCT_BALANCE,0),      --modified for 13160
      NVL(V_LEDGER_BAL,0),        --modified for 13160
      V_RESP_CDE,
      P_IPADDRESS,
      V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
      --Added on 10-Dec-2013 for 13160
      v_acct_type,
      v_timestamp,
      v_err_msg
      --Added on 10-Dec-2013 for 13160
      );

    P_AUTH_ID := V_AUTH_ID;
  EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK;
     P_RESP_CODE := '69'; -- Server Declione
     P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                 SUBSTR(SQLERRM, 1, 300);
     RETURN;
  END;

    WHEN OTHERS THEN
     ROLLBACK;-- TO V_AUTH_SAVEPOINT;

     --Sn select response code and insert record into txn log dtl
     BEGIN
       SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INST_CODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;

       P_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        -- ROLLBACK;
        P_RESP_MSG  := 'NO DATA from response master for delivery channel3:' ||
                    P_DELIVERY_CHANNEL || V_RESP_CDE;
        P_RESP_CODE := '69';
        RETURN;
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while selecting data from response master3 ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        -- ROLLBACK;
        RETURN;
     END;


    --SN : Added on 10-Dec-2013 for 13160

     if v_dr_cr_flag is null
      then

        BEGIN

         SELECT CTM_CREDIT_DEBIT_FLAG,CTM_TRAN_DESC,TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1'))  --review changes done for FSS-1710
           INTO V_DR_CR_FLAG,V_NARRATION,V_TXN_TYPE  --review changes done for FSS-1710
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE AND
               CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
               CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN OTHERS THEN
         null;
        END;

     end if;


    BEGIN

     SELECT cap_prod_code,cap_card_type,cap_card_stat,cap_acct_no
       INTO v_prod_code,v_card_type,v_applpan_cardstat,v_acct_number
       FROM CMS_APPL_PAN
      WHERE cap_inst_code = P_INST_CODE
      and   cap_pan_code = gethash(P_CARD_NUM);

    EXCEPTION
     WHEN OTHERS THEN
            null;
    END;
      --Added below code for review changes done for FSS-1710
      BEGIN

        select cam_type_code,cam_acct_bal,cam_ledger_bal
        into   v_acct_type,v_acct_balance,v_ledger_bal
        from cms_acct_mast
        where cam_inst_code = P_INST_CODE
        and   cam_acct_no =v_acct_number;

      EXCEPTION
        WHEN  OTHERS THEN
        null;

      END;

      v_timestamp := systimestamp;

    --EN : Added on 10-Dec-2013 for 13160

     BEGIN
       INSERT INTO CMS_TRANSACTION_LOG_DTL
        (CTD_DELIVERY_CHANNEL,
         CTD_TXN_CODE,
         CTD_TXN_TYPE,
         CTD_MSG_TYPE,
         CTD_TXN_MODE,
         CTD_BUSINESS_DATE,
         CTD_BUSINESS_TIME,
         CTD_TXN_AMOUNT,
         CTD_TXN_CURR,
         CTD_ACTUAL_AMOUNT,
         CTD_FEE_AMOUNT,
         CTD_WAIVER_AMOUNT,
         CTD_SERVICETAX_AMOUNT,
         CTD_CESS_AMOUNT,
         CTD_BILL_AMOUNT,
         CTD_BILL_CURR,
         CTD_PROCESS_FLAG,
         CTD_PROCESS_MSG,
         CTD_RRN,
         CTD_SYSTEM_TRACE_AUDIT_NO,
         CTD_INST_CODE,
         CTD_CUST_ACCT_NUMBER)
       VALUES
        (P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_MSG,
         P_TXN_MODE,
         P_TRAN_DATE,
         P_TRAN_TIME,
         P_TXN_AMT,
         P_CURR_CODE,
         V_TRAN_AMT,
         NULL,
         NULL,
         NULL,
         NULL,
         V_TOTAL_AMT,
         V_CARD_CURR,
         'E',
         V_ERR_MSG,
         P_RRN,
         P_STAN,
         P_INST_CODE,
         V_ACCT_NUMBER);
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Decline Response 220509
        ROLLBACK;
        RETURN;
     END;
     --En select response code and insert record into txn log dtl
      --Sn create a entry in txn log
  BEGIN
    INSERT INTO TRANSACTIONLOG
     (MSGTYPE,
      RRN,
      DELIVERY_CHANNEL,
      TERMINAL_ID,
      DATE_TIME,
      TXN_CODE,
      TXN_TYPE,
      TXN_MODE,
      TXN_STATUS,
      RESPONSE_CODE,
      BUSINESS_DATE,
      BUSINESS_TIME,
      TOPUP_CARD_NO,
      TOPUP_ACCT_NO,
      TOPUP_ACCT_TYPE,
      BANK_CODE,
      TOTAL_AMOUNT,
      RULE_INDICATOR,
      RULEGROUPID,
      MCCODE,
      CURRENCYCODE,
      ADDCHARGE,
      PRODUCTID,
      CATEGORYID,
      TIPS,
      DECLINE_RULEID,
      ATM_NAME_LOCATION,
      AUTH_ID,
      TRANS_DESC,
      AMOUNT,
      PREAUTHAMOUNT,
      PARTIALAMOUNT,
      MCCODEGROUPID,
      CURRENCYCODEGROUPID,
      TRANSCODEGROUPID,
      RULES,
      PREAUTH_DATE,
      GL_UPD_FLAG,
      SYSTEM_TRACE_AUDIT_NO,
      INSTCODE,
      FEECODE,
      TRANFEE_AMT,
      SERVICETAX_AMT,
      CESS_AMT,
      CR_DR_FLAG,
      TRANFEE_CR_ACCTNO,
      TRANFEE_DR_ACCTNO,
      TRAN_ST_CALC_FLAG,
      TRAN_CESS_CALC_FLAG,
      TRAN_ST_CR_ACCTNO,
      TRAN_ST_DR_ACCTNO,
      TRAN_CESS_CR_ACCTNO,
      TRAN_CESS_DR_ACCTNO,
      TOPUP_CARD_NO_ENCR,
      PROXY_NUMBER,
      REVERSAL_CODE,
      CUSTOMER_ACCT_NO,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      RESPONSE_ID,
      IPADDRESS,
      CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
      --Added on 10-Dec-2013 for 13160
      acct_type,
      Time_stamp,
      error_msg
      --Added on 10-Dec-2013 for 13160
      )
    VALUES
     (P_MSG,
      P_RRN,
      P_DELIVERY_CHANNEL,
      P_TERM_ID,
      V_BUSINESS_DATE,
      P_TXN_CODE,
      V_TXN_TYPE,
      P_TXN_MODE,
      DECODE(P_RESP_CODE, '00', 'C', 'F'),
      P_RESP_CODE,
      P_TRAN_DATE,
      SUBSTR(P_TRAN_TIME, 1, 10),
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_BANK_CODE,
      TRIM(TO_CHAR(nvl(V_TOTAL_AMT,0), '99999999999999990.99')), --modified for 13160
      P_RULE_INDICATOR,
      P_RULEGRP_ID,
      P_MCC_CODE,
      P_CURR_CODE,
      NULL, -- P_add_charge,
      V_PROD_CODE,
      v_card_type,--V_PROD_CATTYPE, -- Commented for 13160
      nvl(P_TIP_AMT,0),
      P_DECLINE_RULEID,
      P_ATMNAME_LOC,
      V_AUTH_ID,
      V_NARRATION,
      TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')),  --modified for 13160
      '0.00',--NULL,     --modified for 13160
      '0.00',--NULL, -- Partial amount (will be given for partial txn) --modified for 13160
      P_MCCCODE_GROUPID,
      P_CURRCODE_GROUPID,
      P_TRANSCODE_GROUPID,
      P_RULES,
      P_PREAUTH_DATE,
      V_GL_UPD_FLAG,
      P_STAN,
      P_INST_CODE,
      V_FEE_CODE,
      nvl(V_FEE_AMT,0),             --modified for 13160
      nvl(V_SERVICETAX_AMOUNT,0),   --modified for 13160
      nvl(V_CESS_AMOUNT,0),         --modified for 13160
      V_DR_CR_FLAG,
      V_FEE_CRACCT_NO,
      V_FEE_DRACCT_NO,
      V_ST_CALC_FLAG,
      V_CESS_CALC_FLAG,
      V_ST_CRACCT_NO,
      V_ST_DRACCT_NO,
      V_CESS_CRACCT_NO,
      V_CESS_DRACCT_NO,
      NULL,
      V_PROXUNUMBER,
      P_RVSL_CODE,
      V_ACCT_NUMBER,
      NVL(V_ACCT_BALANCE,0),    --modified for 13160
      NVL(V_LEDGER_BAL,0),      --modified for 13160
      V_RESP_CDE,
      P_IPADDRESS,
      V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
      --Added on 10-Dec-2013 for 13160
      v_acct_type,
      v_timestamp,
      v_err_msg
      --Added on 10-Dec-2013 for 13160
      );

    P_AUTH_ID := V_AUTH_ID;
  EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK;
     P_RESP_CODE := '69'; -- Server Declione
     P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                 SUBSTR(SQLERRM, 1, 300);
     RETURN;
  END;

END;
/
show error