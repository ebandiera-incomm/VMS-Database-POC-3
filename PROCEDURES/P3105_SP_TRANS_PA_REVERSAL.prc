CREATE OR REPLACE PROCEDURE VMSCMS.P3105_SP_TRANS_PA_REVERSAL(P_INST_CODE           IN NUMBER,
                                            P_MSG_TYP             IN VARCHAR2,
                                            P_RVSL_CODE           IN VARCHAR2,
                                            P_RRN                 IN VARCHAR2,
                                            P_DELV_CHNL           IN VARCHAR2,
                                            P_TERMINAL_ID         IN VARCHAR2,
                                            P_MERC_ID             IN VARCHAR2,
                                            P_TXN_CODE            IN VARCHAR2,
                                            P_TXN_TYPE            IN VARCHAR2,
                                            P_TXN_MODE            IN VARCHAR2,
                                            P_BUSINESS_DATE       IN VARCHAR2,
                                            P_BUSINESS_TIME       IN VARCHAR2,
                                            P_CARD_NO             IN VARCHAR2,
                                            P_ACTUAL_AMT          IN NUMBER,
                                            P_BANK_CODE           IN VARCHAR2,
                                            P_STAN                IN VARCHAR2,
                                            P_EXPRY_DATE          IN VARCHAR2,
                                            P_TOCUST_CARD_NO      IN VARCHAR2,
                                            P_TOCUST_EXPRY_DATE   IN VARCHAR2,
                                            P_ORGNL_BUSINESS_DATE IN VARCHAR2,
                                            P_ORGNL_BUSINESS_TIME IN VARCHAR2,
                                            P_ORGNL_RRN           IN VARCHAR2,
                                            P_MBR_NUMB            IN VARCHAR2,
                                            P_ORGNL_TERMINAL_ID   IN VARCHAR2,
                                            P_CURR_CODE           IN VARCHAR2,
                                            P_MERCHANT_NAME       IN VARCHAR2,
                                            P_MERCHANT_CITY       IN VARCHAR2,
                                            P_RESP_CDE            OUT VARCHAR2,
                                            P_RESP_MSG            OUT VARCHAR2,
                                            P_RESP_MSG_M24        OUT VARCHAR2) IS

 /*************************************************
     * Created Date     :  10-Dec-2012
     * Created By       :  Srinivasu
     * PURPOSE          :  For preauth reversal
   * Modified By      : B.Dhinakaran
     * Modified Reason  : Transaction detail report
     * Modified Date    : 22-Aug-2012
     * Reviewer         :  B.Besky Anand
     * Reviewed Date    :  28-Aug-2012
     * Build Number     :  CMS3.5.1_RI0015_B0009

 *************************************************/
  V_ORGNL_DELIVERY_CHANNEL   TRANSACTIONLOG.DELIVERY_CHANNEL%TYPE;
  V_ORGNL_RESP_CODE          TRANSACTIONLOG.RESPONSE_CODE%TYPE;
  V_ORGNL_TERMINAL_ID        TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_ORGNL_TXN_CODE           TRANSACTIONLOG.TXN_CODE%TYPE;
  V_ORGNL_TXN_TYPE           TRANSACTIONLOG.TXN_TYPE%TYPE;
  V_ORGNL_TXN_MODE           TRANSACTIONLOG.TXN_MODE%TYPE;
  V_ORGNL_BUSINESS_DATE      TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  V_ORGNL_BUSINESS_TIME      TRANSACTIONLOG.BUSINESS_TIME%TYPE;
  V_ORGNL_CUSTOMER_CARD_NO   TRANSACTIONLOG.CUSTOMER_CARD_NO%TYPE;
  V_ORGNL_TOTAL_AMOUNT       TRANSACTIONLOG.AMOUNT%TYPE;
  V_ACTUAL_AMT               NUMBER(9, 2);
  V_REVERSAL_AMT             NUMBER(9, 2);
  V_ORGNL_TXN_FEECODE        CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_ORGNL_TXN_FEEATTACHTYPE  VARCHAR2(1);
  V_ORGNL_TXN_TOTALFEE_AMT   TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  V_ORGNL_TXN_SERVICETAX_AMT TRANSACTIONLOG.SERVICETAX_AMT%TYPE;
  V_ORGNL_TXN_CESS_AMT       TRANSACTIONLOG.CESS_AMT%TYPE;
  V_ORGNL_TRANSACTION_TYPE   TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ACTUAL_DISPATCHED_AMT    TRANSACTIONLOG.AMOUNT%TYPE;
  V_RESP_CDE                 VARCHAR2(3);
  V_FUNC_CODE                CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_DR_CR_FLAG               TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ORGNL_TRANDATE           DATE;
  V_RVSL_TRANDATE            DATE;
  V_ORGNL_TERMID             TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_ORGNL_MCCCODE            TRANSACTIONLOG.MCCODE%TYPE;
  V_ERRMSG                   VARCHAR2(300);
  V_ACTUAL_FEECODE           TRANSACTIONLOG.FEECODE%TYPE;
  V_ORGNL_TRANFEE_AMT        TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  V_ORGNL_SERVICETAX_AMT     TRANSACTIONLOG.SERVICETAX_AMT%TYPE;
  V_ORGNL_CESS_AMT           TRANSACTIONLOG.CESS_AMT%TYPE;
  V_ORGNL_CR_DR_FLAG         TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ORGNL_TRANFEE_CR_ACCTNO  TRANSACTIONLOG.TRANFEE_CR_ACCTNO%TYPE;
  V_ORGNL_TRANFEE_DR_ACCTNO  TRANSACTIONLOG.TRANFEE_DR_ACCTNO%TYPE;
  V_ORGNL_ST_CALC_FLAG       TRANSACTIONLOG.TRAN_ST_CALC_FLAG%TYPE;
  V_ORGNL_CESS_CALC_FLAG     TRANSACTIONLOG.TRAN_CESS_CALC_FLAG%TYPE;
  V_ORGNL_ST_CR_ACCTNO       TRANSACTIONLOG.TRAN_ST_CR_ACCTNO%TYPE;
  V_ORGNL_ST_DR_ACCTNO       TRANSACTIONLOG.TRAN_ST_DR_ACCTNO%TYPE;
  V_ORGNL_CESS_CR_ACCTNO     TRANSACTIONLOG.TRAN_CESS_CR_ACCTNO%TYPE;
  V_ORGNL_CESS_DR_ACCTNO     TRANSACTIONLOG.TRAN_CESS_DR_ACCTNO%TYPE;
  V_PROD_CODE                CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE                CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_GL_UPD_FLAG              TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_TRAN_REVERSE_FLAG        TRANSACTIONLOG.TRAN_REVERSE_FLAG%TYPE;
  V_SAVEPOINT                NUMBER DEFAULT 1;
  V_CURR_CODE                TRANSACTIONLOG.CURRENCYCODE%TYPE;
  V_AUTH_ID                  TRANSACTIONLOG.AUTH_ID%TYPE;
  V_CUTOFF_TIME              VARCHAR2(5);
  V_BUSINESS_TIME            VARCHAR2(5);
  EXP_RVSL_REJECT_RECORD EXCEPTION;
  V_CARD_ACCT_NO        VARCHAR2(20);
  V_TRAN_SYSDATE        DATE;
  V_TRAN_CUTOFF         DATE;
  V_HASH_PAN            CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_TRAN_AMT            NUMBER;
  V_DELCHANNEL_CODE     VARCHAR2(2);
  V_CARD_CURR           VARCHAR2(5);
  V_RRN_COUNT           NUMBER;
  V_BASE_CURR           CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CURRCODE            VARCHAR2(3);
  V_ACCT_BALANCE        NUMBER;
  V_TRAN_DESC           CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
  V_PREAUTH_EXPIRY_FLAG CHARACTER(1);
  V_ATM_USAGEAMNT       CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT       CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  V_ATM_USAGELIMIT      CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT      CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_BUSINESS_DATE_TRAN  DATE;
  V_HOLD_AMOUNT         NUMBER;
  V_PREAUTH_USAGE_LIMIT NUMBER;
  V_MMPOS_USAGEAMNT     CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
  V_PROXUNUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_LEDGER_BAL          NUMBER;
  --V_AUTHID_DATE           VARCHAR2(8);
  V_MAX_CARD_BAL            NUMBER;
  V_ORGNL_DRACCT_NO    CMS_FUNC_PROD.CFP_DRACCT_NO%TYPE;
  V_LEDGE_BALANCE      NUMBER;
  V_TXN_NARRATION      CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_FEE_NARRATION      CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_TRAN_PREAUTH_FLAG     CMS_TRANSACTION_MAST.CTM_PREAUTH_FLAG%TYPE;
  V_TOT_FEE_AMOUNT      TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  V_TOT_AMOUNT          TRANSACTIONLOG.AMOUNT%TYPE;
   V_TXN_TYPE         NUMBER(1);
    --Added by Deepa for the changes to include Merchant name,city and state in statements log
  V_TXN_MERCHNAME      CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_FEE_MERCHNAME      CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_TXN_MERCHCITY      CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_FEE_MERCHCITY      CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_TXN_MERCHSTATE      CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;
  V_FEE_MERCHSTATE      CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;

BEGIN

  P_RESP_CDE := '00';
  P_RESP_MSG := 'OK';

  SAVEPOINT V_SAVEPOINT;

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --EN create encr pan
  
  
   --Sn find the type of orginal txn (credit or debit)
  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG, CTM_TRAN_DESC,CTM_PREAUTH_FLAG,
    TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1'))
     INTO V_DR_CR_FLAG, V_TRAN_DESC,V_TRAN_PREAUTH_FLAG,V_TXN_TYPE
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELV_CHNL AND
         CTM_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Transaction detail is not found in master for orginal txn code' ||
                P_TXN_CODE || 'delivery channel ' || P_DELV_CHNL;
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Problem while selecting debit/credit flag ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En find the type of orginal txn (credit or debit)

  --Sn generate auth id
  BEGIN
  --  SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

    SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
     INTO V_AUTH_ID
     FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while generating authid ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21'; -- Server Declined
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En generate auth id

  -- Sn txn date conversion(to check the txn date)

  BEGIN
    V_ORGNL_TRANDATE := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8),
                          'yyyymmdd');
    V_RVSL_TRANDATE  := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8),
                          'yyyymmdd');

  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '45';
     V_ERRMSG   := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  -- En  txn date conversion

  --Sn Txn date conversion

  BEGIN
    V_ORGNL_TRANDATE := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8) || ' ' ||
                          SUBSTR(TRIM(P_ORGNL_BUSINESS_TIME), 1, 8),
                          'yyyymmdd hh24:mi:ss');
    V_RVSL_TRANDATE  := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8) || ' ' ||
                          SUBSTR(TRIM(P_BUSINESS_TIME), 1, 8),
                          'yyyymmdd hh24:mi:ss');

  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '32';
     V_ERRMSG   := 'Problem while converting transaction Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En Txn date conversion

  --Sn Duplicate RRN Check

  BEGIN

    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE TERMINAL_ID = P_TERMINAL_ID AND RRN = P_RRN AND
         BUSINESS_DATE = P_BUSINESS_DATE
           and DELIVERY_CHANNEL = P_DELV_CHNL;--Added by ramkumar.Mk on 25 march 2012

    IF V_RRN_COUNT > 0 THEN

     V_RESP_CDE := '22';
     V_ERRMSG   := 'Duplicate RRN from the Treminal' || P_TERMINAL_ID || 'on' ||
                P_BUSINESS_DATE;
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

  END;

  --En Duplicate RRN Check

  --Select the Delivery Channel code of MM-POS
  BEGIN

    SELECT CDM_CHANNEL_CODE
     INTO V_DELCHANNEL_CODE
     FROM CMS_DELCHANNEL_MAST
    WHERE CDM_CHANNEL_DESC = 'MMPOS' AND CDM_INST_CODE = P_INST_CODE;
    --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr

    IF P_CURR_CODE IS NULL AND V_DELCHANNEL_CODE = P_DELV_CHNL THEN

     BEGIN
       SELECT CIP_PARAM_VALUE
        INTO V_BASE_CURR
        FROM CMS_INST_PARAM
        WHERE CIP_INST_CODE = P_INST_CODE AND CIP_PARAM_KEY = 'CURRENCY';

       IF TRIM(V_BASE_CURR) IS NULL THEN
        V_ERRMSG := 'Base currency cannot be null ';
        RAISE EXP_RVSL_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Base currency is not defined for the institution ';
        RAISE EXP_RVSL_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting bese currecy  ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_RVSL_REJECT_RECORD;
     END;

     V_CURRCODE := V_BASE_CURR;

    ELSE
     V_CURRCODE := P_CURR_CODE;

    END IF;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
         V_ERRMSG := 'DELIVERY CHANNEL DETAILS NOT AVAILABLE ';
        RAISE EXP_RVSL_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting bese currecy  ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --Sn check msg type
  IF V_DELCHANNEL_CODE <> P_DELV_CHNL THEN

    IF (P_MSG_TYP NOT IN ('0400', '0410', '0420', '0430')) OR
      (P_RVSL_CODE = '00') THEN
     V_RESP_CDE := '12';
     V_ERRMSG   := 'Not a valid CMS_INST_PARAM ';
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;
  END IF;
  --En check msg type

  --Sn check orginal transaction    (-- Amount is missing in reversal request)
  BEGIN
    SELECT DELIVERY_CHANNEL,
         TERMINAL_ID,
         RESPONSE_CODE,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         AMOUNT, --Transaction amount
         FEECODE,
         FEEATTACHTYPE, -- card level / prod cattype level
         TRANFEE_AMT, --Tranfee  Total    amount
         SERVICETAX_AMT, --Tran servicetax amount
         CESS_AMT, --Tran cess amount
         CR_DR_FLAG,
         TERMINAL_ID,
         MCCODE,
         FEECODE,
         TRANFEE_AMT,
         SERVICETAX_AMT,
         CESS_AMT,
         TRANFEE_CR_ACCTNO,
         TRANFEE_DR_ACCTNO,
         TRAN_ST_CALC_FLAG,
         TRAN_CESS_CALC_FLAG,
         TRAN_ST_CR_ACCTNO,
         TRAN_ST_DR_ACCTNO,
         TRAN_CESS_CR_ACCTNO,
         TRAN_CESS_DR_ACCTNO,
         CURRENCYCODE,
         TRAN_REVERSE_FLAG,
         GL_UPD_FLAG

     INTO V_ORGNL_DELIVERY_CHANNEL,
         V_ORGNL_TERMINAL_ID,
         V_ORGNL_RESP_CODE,
         V_ORGNL_TXN_CODE,
         V_ORGNL_TXN_TYPE,
         V_ORGNL_TXN_MODE,
         V_ORGNL_BUSINESS_DATE,
         V_ORGNL_BUSINESS_TIME,
         V_ORGNL_CUSTOMER_CARD_NO,
         V_ORGNL_TOTAL_AMOUNT,
         V_ORGNL_TXN_FEECODE,
         V_ORGNL_TXN_FEEATTACHTYPE,
         V_ORGNL_TXN_TOTALFEE_AMT,
         V_ORGNL_TXN_SERVICETAX_AMT,
         V_ORGNL_TXN_CESS_AMT,
         V_ORGNL_TRANSACTION_TYPE,
         V_ORGNL_TERMID,
         V_ORGNL_MCCCODE,
         V_ACTUAL_FEECODE,
         V_ORGNL_TRANFEE_AMT,
         V_ORGNL_SERVICETAX_AMT,
         V_ORGNL_CESS_AMT,
         V_ORGNL_TRANFEE_CR_ACCTNO,
         V_ORGNL_TRANFEE_DR_ACCTNO,
         V_ORGNL_ST_CALC_FLAG,
         V_ORGNL_CESS_CALC_FLAG,
         V_ORGNL_ST_CR_ACCTNO,
         V_ORGNL_ST_DR_ACCTNO,
         V_ORGNL_CESS_CR_ACCTNO,
         V_ORGNL_CESS_DR_ACCTNO,
         V_CURR_CODE,
         V_TRAN_REVERSE_FLAG,
         V_GL_UPD_FLAG
     FROM TRANSACTIONLOG
    WHERE RRN = P_ORGNL_RRN AND BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
         BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
         CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
         AND INSTCODE = P_INST_CODE AND
         TERMINAL_ID = P_ORGNL_TERMINAL_ID
          and DELIVERY_CHANNEL = P_DELV_CHNL;--Added by ramkumar.Mk on 25 march 2012

    IF V_ORGNL_RESP_CODE <> '00' THEN

     V_RESP_CDE := '23';
     V_ERRMSG   := ' The original transaction was not successful';
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

    IF V_TRAN_REVERSE_FLAG = 'Y' THEN

     V_RESP_CDE := '52';
     V_ERRMSG   := 'The reversal already done for the orginal transaction';
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '53';
     V_ERRMSG   := 'Matching transaction not found';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN TOO_MANY_ROWS THEN
    BEGIN
     select sum(TRANFEE_AMT),SUM(AMOUNT)
     INTO V_TOT_FEE_AMOUNT, V_TOT_AMOUNT
     FROM TRANSACTIONLOG
    WHERE RRN = P_ORGNL_RRN AND BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
         BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
         CUSTOMER_CARD_NO = V_HASH_PAN
         AND INSTCODE = P_INST_CODE AND
         TERMINAL_ID = P_ORGNL_TERMINAL_ID
         AND RESPONSE_CODE='00';
      EXCEPTION
      WHEN OTHERS THEN
         V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting TRANSACTIONLOG '||SUBSTR(SQLERRM,1,200);
     RAISE EXP_RVSL_REJECT_RECORD;
      END;
       IF (V_TOT_FEE_AMOUNT IS NULL) AND (V_TOT_AMOUNT IS NULL) THEN

            V_RESP_CDE := '21';
            V_ERRMSG   := 'More than one failure matching record found in the master';
            RAISE EXP_RVSL_REJECT_RECORD;

       ELSIF V_TOT_FEE_AMOUNT>0 THEN
          BEGIN
           SELECT DELIVERY_CHANNEL,
             TERMINAL_ID,
             RESPONSE_CODE,
             TXN_CODE,
             TXN_TYPE,
             TXN_MODE,
             BUSINESS_DATE,
             BUSINESS_TIME,
             CUSTOMER_CARD_NO,
             AMOUNT, --Transaction amount
             FEECODE,
             FEEATTACHTYPE, -- card level / prod cattype level
             TRANFEE_AMT, --Tranfee  Total    amount
             SERVICETAX_AMT, --Tran servicetax amount
             CESS_AMT, --Tran cess amount
             CR_DR_FLAG,
             TERMINAL_ID,
             MCCODE,
             FEECODE,
             TRANFEE_AMT,
             SERVICETAX_AMT,
             CESS_AMT,
             TRANFEE_CR_ACCTNO,
             TRANFEE_DR_ACCTNO,
             TRAN_ST_CALC_FLAG,
             TRAN_CESS_CALC_FLAG,
             TRAN_ST_CR_ACCTNO,
             TRAN_ST_DR_ACCTNO,
             TRAN_CESS_CR_ACCTNO,
             TRAN_CESS_DR_ACCTNO,
             CURRENCYCODE,
             TRAN_REVERSE_FLAG,
             GL_UPD_FLAG

         INTO V_ORGNL_DELIVERY_CHANNEL,
             V_ORGNL_TERMINAL_ID,
             V_ORGNL_RESP_CODE,
             V_ORGNL_TXN_CODE,
             V_ORGNL_TXN_TYPE,
             V_ORGNL_TXN_MODE,
             V_ORGNL_BUSINESS_DATE,
             V_ORGNL_BUSINESS_TIME,
             V_ORGNL_CUSTOMER_CARD_NO,
             V_ORGNL_TOTAL_AMOUNT,
             V_ORGNL_TXN_FEECODE,
             V_ORGNL_TXN_FEEATTACHTYPE,
             V_ORGNL_TXN_TOTALFEE_AMT,
             V_ORGNL_TXN_SERVICETAX_AMT,
             V_ORGNL_TXN_CESS_AMT,
             V_ORGNL_TRANSACTION_TYPE,
             V_ORGNL_TERMID,
             V_ORGNL_MCCCODE,
             V_ACTUAL_FEECODE,
             V_ORGNL_TRANFEE_AMT,
             V_ORGNL_SERVICETAX_AMT,
             V_ORGNL_CESS_AMT,
             V_ORGNL_TRANFEE_CR_ACCTNO,
             V_ORGNL_TRANFEE_DR_ACCTNO,
             V_ORGNL_ST_CALC_FLAG,
             V_ORGNL_CESS_CALC_FLAG,
             V_ORGNL_ST_CR_ACCTNO,
             V_ORGNL_ST_DR_ACCTNO,
             V_ORGNL_CESS_CR_ACCTNO,
             V_ORGNL_CESS_DR_ACCTNO,
             V_CURR_CODE,
             V_TRAN_REVERSE_FLAG,
             V_GL_UPD_FLAG
         FROM TRANSACTIONLOG
        WHERE RRN = P_ORGNL_RRN AND BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
             BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
             CUSTOMER_CARD_NO = V_HASH_PAN
             AND INSTCODE = P_INST_CODE AND
             TERMINAL_ID = P_ORGNL_TERMINAL_ID
             AND RESPONSE_CODE='00'
             AND DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
             AND TRANFEE_CR_ACCTNO IS NOT NULL AND rownum=1;

             V_ORGNL_TOTAL_AMOUNT:=V_TOT_AMOUNT;
             V_ORGNL_TXN_TOTALFEE_AMT:=V_TOT_FEE_AMOUNT;
             V_ORGNL_TRANFEE_AMT:=V_TOT_FEE_AMOUNT;

       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_RESP_CDE := '21';
         V_ERRMSG   := 'NO DATA IN TRANSACTIONLOG1 ';
     RAISE EXP_RVSL_REJECT_RECORD;
      WHEN OTHERS THEN
           V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting TRANSACTIONLOG1 '||SUBSTR(SQLERRM,1,200);
     RAISE EXP_RVSL_REJECT_RECORD;
      END;

      --Added to check the reversal already done or not for Incremental preauth by deepa
      IF V_TRAN_REVERSE_FLAG = 'Y' THEN

     V_RESP_CDE := '52';
     V_ERRMSG   := 'The reversal already done for the orginal transaction';
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

       ELSE
          BEGIN
           SELECT DELIVERY_CHANNEL,
             TERMINAL_ID,
             RESPONSE_CODE,
             TXN_CODE,
             TXN_TYPE,
             TXN_MODE,
             BUSINESS_DATE,
             BUSINESS_TIME,
             CUSTOMER_CARD_NO,
             AMOUNT, --Transaction amount
             FEECODE,
             FEEATTACHTYPE, -- card level / prod cattype level
             TRANFEE_AMT, --Tranfee  Total    amount
             SERVICETAX_AMT, --Tran servicetax amount
             CESS_AMT, --Tran cess amount
             CR_DR_FLAG,
             TERMINAL_ID,
             MCCODE,
             FEECODE,
             TRANFEE_AMT,
             SERVICETAX_AMT,
             CESS_AMT,
             TRANFEE_CR_ACCTNO,
             TRANFEE_DR_ACCTNO,
             TRAN_ST_CALC_FLAG,
             TRAN_CESS_CALC_FLAG,
             TRAN_ST_CR_ACCTNO,
             TRAN_ST_DR_ACCTNO,
             TRAN_CESS_CR_ACCTNO,
             TRAN_CESS_DR_ACCTNO,
             CURRENCYCODE,
             TRAN_REVERSE_FLAG,
             GL_UPD_FLAG

         INTO V_ORGNL_DELIVERY_CHANNEL,
             V_ORGNL_TERMINAL_ID,
             V_ORGNL_RESP_CODE,
             V_ORGNL_TXN_CODE,
             V_ORGNL_TXN_TYPE,
             V_ORGNL_TXN_MODE,
             V_ORGNL_BUSINESS_DATE,
             V_ORGNL_BUSINESS_TIME,
             V_ORGNL_CUSTOMER_CARD_NO,
             V_ORGNL_TOTAL_AMOUNT,
             V_ORGNL_TXN_FEECODE,
             V_ORGNL_TXN_FEEATTACHTYPE,
             V_ORGNL_TXN_TOTALFEE_AMT,
             V_ORGNL_TXN_SERVICETAX_AMT,
             V_ORGNL_TXN_CESS_AMT,
             V_ORGNL_TRANSACTION_TYPE,
             V_ORGNL_TERMID,
             V_ORGNL_MCCCODE,
             V_ACTUAL_FEECODE,
             V_ORGNL_TRANFEE_AMT,
             V_ORGNL_SERVICETAX_AMT,
             V_ORGNL_CESS_AMT,
             V_ORGNL_TRANFEE_CR_ACCTNO,
             V_ORGNL_TRANFEE_DR_ACCTNO,
             V_ORGNL_ST_CALC_FLAG,
             V_ORGNL_CESS_CALC_FLAG,
             V_ORGNL_ST_CR_ACCTNO,
             V_ORGNL_ST_DR_ACCTNO,
             V_ORGNL_CESS_CR_ACCTNO,
             V_ORGNL_CESS_DR_ACCTNO,
             V_CURR_CODE,
             V_TRAN_REVERSE_FLAG,
             V_GL_UPD_FLAG
         FROM TRANSACTIONLOG
        WHERE RRN = P_ORGNL_RRN AND BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
             BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
             CUSTOMER_CARD_NO = V_HASH_PAN
             AND INSTCODE = P_INST_CODE AND
             TERMINAL_ID = P_ORGNL_TERMINAL_ID
             AND RESPONSE_CODE='00'
             and DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
             AND rownum=1;

             V_ORGNL_TOTAL_AMOUNT:=V_TOT_AMOUNT;
             V_ORGNL_TXN_TOTALFEE_AMT:=V_TOT_FEE_AMOUNT;
             V_ORGNL_TRANFEE_AMT:=V_TOT_FEE_AMOUNT;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
          V_RESP_CDE := '21';
         V_ERRMSG   := 'NO DATA IN TRANSACTIONLOG2';
     RAISE EXP_RVSL_REJECT_RECORD;
     
      WHEN OTHERS THEN
           V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting TRANSACTIONLOG2 '||SUBSTR(SQLERRM,1,200);
     RAISE EXP_RVSL_REJECT_RECORD;
      END;
      --Added to check the reversal already done or not for Incremental preauth by deepa
      IF V_TRAN_REVERSE_FLAG = 'Y' THEN

     V_RESP_CDE := '52';
     V_ERRMSG   := 'The reversal already done for the orginal transaction';
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

       END IF;
      WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERRMSG   := 'Error while selecting master data' ||
                    SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En check orginal transaction

  ---Sn check card number

  IF V_ORGNL_CUSTOMER_CARD_NO <> V_HASH_PAN THEN

    V_RESP_CDE := '21';
    V_ERRMSG   := 'Customer card number is not matching in reversal and orginal transaction';
    RAISE EXP_RVSL_REJECT_RECORD;

  END IF;

  --En check card number

  --Sn find the converted tran amt
  V_TRAN_AMT := P_ACTUAL_AMT;

  IF (P_ACTUAL_AMT >= 0) THEN

    BEGIN
     SP_CONVERT_CURR(P_INST_CODE,
                  V_CURRCODE,
                  P_CARD_NO,
                  P_ACTUAL_AMT,
                  V_RVSL_TRANDATE,
                  V_TRAN_AMT,
                  V_CARD_CURR,
                  V_ERRMSG);

     IF V_ERRMSG <> 'OK' THEN
       V_RESP_CDE := '44';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '44'; -- Server Declined -220509
       V_ERRMSG   := 'Error from currency conversion ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
  ELSE
    -- If transaction Amount is zero - Invalid Amount -220509

    V_RESP_CDE := '13';
    V_ERRMSG   := 'INVALID AMOUNT';
    RAISE EXP_RVSL_REJECT_RECORD;

  END IF;

  --En find the  converted tran amt

  --Sn check amount with orginal transaction
  IF (V_TRAN_AMT IS NULL OR V_TRAN_AMT = 0) THEN

     V_ACTUAL_DISPATCHED_AMT := 0;
  ELSE
    V_ACTUAL_DISPATCHED_AMT := V_TRAN_AMT;
  END IF;
  --En check amount with orginal transaction

  --Sn Check PreAuth Completion txn

  BEGIN
    SELECT CPT_TOTALHOLD_AMT, CPT_EXPIRY_FLAG
     INTO V_HOLD_AMOUNT, V_PREAUTH_EXPIRY_FLAG
     FROM CMS_PREAUTH_TRANSACTION
    WHERE CPT_RRN = P_ORGNL_RRN AND
         CPT_TXN_DATE = P_ORGNL_BUSINESS_DATE AND
         CPT_INST_CODE = P_INST_CODE AND CPT_MBR_NO = P_MBR_NUMB AND
         CPT_CARD_NO = V_HASH_PAN;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '53';
     V_ERRMSG   := 'Matching transaction not found';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN TOO_MANY_ROWS THEN
     V_RESP_CDE := '21'; --Ineligible Transaction
     V_ERRMSG   := 'More than one record found ';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21'; --Ineligible Transaction
     V_ERRMSG   := 'Error while selecting the PreAuth details';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En Check PreAuth Completion txn

  BEGIN

    IF V_HOLD_AMOUNT <= 0 THEN

     V_RESP_CDE := '58';
     V_ERRMSG   := 'There is no hold amount for reversal';
     RAISE EXP_RVSL_REJECT_RECORD;

    ELSE

     IF (V_HOLD_AMOUNT < V_ACTUAL_DISPATCHED_AMT) THEN

       V_RESP_CDE := '59';
       V_ERRMSG   := 'Reversal amount exceeds the original transaction amount';
       RAISE EXP_RVSL_REJECT_RECORD;

     END IF;

    END IF;

    V_REVERSAL_AMT := V_HOLD_AMOUNT - V_ACTUAL_DISPATCHED_AMT;

  END;

 

  --Sn Check the Flag for Reversal transaction

  IF V_TRAN_PREAUTH_FLAG!='Y' THEN

    IF V_DR_CR_FLAG = 'NA' THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Not a valid orginal transaction for reversal';
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;

  END IF;

  --En Check the Flag for Reversal transaction

  --Sn Check the transaction type with Original txn type

  IF V_DR_CR_FLAG <> V_ORGNL_TRANSACTION_TYPE THEN
    V_RESP_CDE := '21';
    V_ERRMSG   := 'Orginal transaction type is not matching with actual transaction type';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;

  --En Check the transaction type

  --Sn find the orginal func code
  BEGIN
    SELECT CFM_FUNC_CODE
     INTO V_FUNC_CODE
     FROM CMS_FUNC_MAST
    WHERE CFM_TXN_CODE = V_ORGNL_TXN_CODE AND
         CFM_TXN_MODE = V_ORGNL_TXN_MODE AND
         CFM_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CFM_INST_CODE = P_INST_CODE;
    --TXN mode and delivery channel we need to attach
    --bkz txn code may be same for all type of channels
  EXCEPTION
    WHEN NO_DATA_FOUND THEN

     V_RESP_CDE := '69'; --Ineligible Transaction
     V_ERRMSG   := 'Function code not defined for txn code ' ||
                P_TXN_CODE;
     RAISE EXP_RVSL_REJECT_RECORD;

    WHEN TOO_MANY_ROWS THEN

     V_RESP_CDE := '69';
     V_ERRMSG   := 'More than one function defined for txn code ' ||
                P_TXN_CODE;
     RAISE EXP_RVSL_REJECT_RECORD;

    WHEN OTHERS THEN

     V_RESP_CDE := '69';
     V_ERRMSG   := 'Problem while selecting function code from function mast  ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En find the orginal func code

  ---Sn find cutoff time
  BEGIN
    SELECT CIP_PARAM_VALUE
     INTO V_CUTOFF_TIME
     FROM CMS_INST_PARAM
    WHERE CIP_PARAM_KEY = 'CUTOFF' AND CIP_INST_CODE = P_INST_CODE;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_CUTOFF_TIME := 0;
     V_RESP_CDE    := '21';
     V_ERRMSG      := 'Cutoff time is not defined in the system';
     RAISE EXP_RVSL_REJECT_RECORD;

    WHEN OTHERS THEN

     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting cutoff  dtl  from system ';
     RAISE EXP_RVSL_REJECT_RECORD;

  END;
  ---En find cutoff time

  BEGIN
    SELECT CAM_ACCT_NO,CAM_ACCT_BAL, CAM_LEDGER_BAL
     INTO V_CARD_ACCT_NO,V_ACCT_BALANCE, V_LEDGER_BAL
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_NO =
         (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
           WHERE CAP_PAN_CODE = V_HASH_PAN
                AND CAP_MBR_NUMB = P_MBR_NUMB AND
                CAP_INST_CODE = P_INST_CODE) AND
         CAM_INST_CODE = P_INST_CODE
      FOR UPDATE NOWAIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '14'; --Ineligible Transaction
     V_ERRMSG   := 'Invalid Card ';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                P_CARD_NO;
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

    --Sn get the product code
  BEGIN

    SELECT CAP_PROD_CODE, CAP_CARD_TYPE, CAP_PROXY_NUMBER, CAP_ACCT_NO
     INTO V_PROD_CODE, V_CARD_TYPE, V_PROXUNUMBER, V_ACCT_NUMBER
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := P_CARD_NO || ' Card no not in master';
     RAISE EXP_RVSL_REJECT_RECORD;

    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while retriving card detail ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

  END;

  --Sn Check for maximum card balance configured for the product profile.
  BEGIN

    SELECT TO_NUMBER(CBP_PARAM_VALUE)
     INTO V_MAX_CARD_BAL
     FROM CMS_BIN_PARAM
    WHERE CBP_INST_CODE = P_INST_CODE AND
         CBP_PARAM_NAME = 'Max Card Balance' AND
         CBP_PROFILE_CODE IN
         (SELECT CPM_PROFILE_CODE
            FROM CMS_PROD_MAST
           WHERE CPM_PROD_CODE = V_PROD_CODE);

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CDE := '21';
     V_ERRMSG   := 'NO CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

  END;
  -- En Check for maximum card balance configured for the product profile.

  IF ((V_ACCT_BALANCE + V_REVERSAL_AMT) > V_MAX_CARD_BAL) OR
    ((V_LEDGER_BAL + V_REVERSAL_AMT) > V_MAX_CARD_BAL) THEN
  BEGIN
    update cms_appl_pan set cap_card_stat='12'
                    where cap_pan_code =V_HASH_PAN
                    and cap_inst_code=P_INST_CODE;
                    IF SQL%ROWCOUNT = 0 THEN

                    V_ERRMSG := 'Error while updating the card status';
                    V_RESP_CDE := '21';
                    RAISE EXP_RVSL_REJECT_RECORD;
                   END IF;

     IF SQL%ROWCOUNT = 0 THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while updating cms_appl_pan ';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;


   EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while updating cms_appl_pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

  END;


  END IF;

   IF V_ORGNL_TXN_TOTALFEE_AMT > 0 THEN

    BEGIN

     SELECT csl_trans_narrration,CSL_MERCHANT_NAME,CSL_MERCHANT_CITY,CSL_MERCHANT_STATE
     INTO V_FEE_NARRATION,V_FEE_MERCHNAME,V_FEE_MERCHCITY,V_FEE_MERCHSTATE--Mofified by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
        FROM cms_statements_log
        WHERE csl_business_date = V_ORGNL_BUSINESS_DATE
        AND csl_business_time = V_ORGNL_BUSINESS_TIME
        AND csl_rrn = P_ORGNL_RRN
        AND csl_delivery_channel = V_ORGNL_DELIVERY_CHANNEL
        AND csl_txn_code = V_ORGNL_TXN_CODE
        AND csl_pan_no = V_ORGNL_CUSTOMER_CARD_NO
        AND csl_inst_code = P_INST_CODE
        AND TXN_FEE_FLAG='Y' AND rownum=1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            V_FEE_NARRATION:=NULL;
            WHEN OTHERS THEN
            V_FEE_NARRATION:=NULL;
    END;

   END IF;

--En find narration

--Added by Deepa on 09-May-2012 for statement changes with merchant details
--Sn getting the Merchant details of Original txn
 BEGIN
    select CPH_MERCHANT_NAME,CPH_MERCHANT_CITY,CPH_MERCHANT_STATE
    INTO V_TXN_MERCHNAME,V_TXN_MERCHCITY,V_TXN_MERCHSTATE
     From CMS_PREAUTH_TRANS_HIST
     where CPH_RRN=P_ORGNL_RRN
     AND CPH_CARD_NO=V_HASH_PAN
     and CPH_MBR_NO=P_MBR_NUMB
     and CPH_TXN_DATE=P_ORGNL_BUSINESS_DATE
     AND CPH_INST_CODE=P_INST_CODE
     AND CPH_TRANSACTION_FLAG IN('N','I') AND rownum=1;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     NULL;
    WHEN OTHERS THEN
    NULL;
  END;
  --En getting the Merchant details of Original txn

  BEGIN
    SP_REVERSE_CARD_AMOUNT(P_INST_CODE,
                      V_FUNC_CODE,
                      P_RRN,
                      P_DELV_CHNL,
                      P_ORGNL_TERMINAL_ID,
                      P_MERC_ID,
                      P_TXN_CODE,
                      V_RVSL_TRANDATE,
                      P_TXN_MODE,
                      P_CARD_NO,
                      V_REVERSAL_AMT,
                      P_ORGNL_RRN,
                      V_CARD_ACCT_NO,
                      P_BUSINESS_DATE,
                      P_BUSINESS_TIME,
                      V_AUTH_ID,
                      V_TXN_NARRATION,
                      P_ORGNL_BUSINESS_DATE,
                      P_ORGNL_BUSINESS_TIME,
                      V_TXN_MERCHNAME,--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                      V_TXN_MERCHCITY,
                      V_TXN_MERCHSTATE,
                      V_RESP_CDE,
                      V_ERRMSG);
    IF V_RESP_CDE <> '00' OR V_ERRMSG <> 'OK' THEN
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while reversing the amount ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En reverse the amount
  --Sn reverse the fee

  BEGIN
    SP_REVERSE_FEE_AMOUNT(P_INST_CODE,
                     P_RRN,
                     P_DELV_CHNL,
                     P_ORGNL_TERMINAL_ID,
                     P_MERC_ID,
                     P_TXN_CODE,
                     V_RVSL_TRANDATE,
                     P_TXN_MODE,
                     V_ORGNL_TXN_TOTALFEE_AMT,
                     P_CARD_NO,
                     V_ACTUAL_FEECODE,
                     V_ORGNL_TRANFEE_AMT,
                     V_ORGNL_TRANFEE_CR_ACCTNO,
                     V_ORGNL_TRANFEE_DR_ACCTNO,
                     V_ORGNL_ST_CALC_FLAG,
                     V_ORGNL_SERVICETAX_AMT,
                     V_ORGNL_ST_CR_ACCTNO,
                     V_ORGNL_ST_DR_ACCTNO,
                     V_ORGNL_CESS_CALC_FLAG,
                     V_ORGNL_CESS_AMT,
                     V_ORGNL_CESS_CR_ACCTNO,
                     V_ORGNL_CESS_DR_ACCTNO,
                     P_ORGNL_RRN,
                     V_CARD_ACCT_NO,
                     P_BUSINESS_DATE,
                     P_BUSINESS_TIME,
                     V_AUTH_ID,
                     V_FEE_NARRATION,
                     V_FEE_MERCHNAME,--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                     V_FEE_MERCHCITY,
                     V_FEE_MERCHSTATE,
                     V_RESP_CDE,
                     V_ERRMSG);

    IF V_RESP_CDE <> '00' OR V_ERRMSG <> 'OK' THEN
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;

    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while reversing the fee amount ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En reverse the fee


  IF V_GL_UPD_FLAG = 'Y' THEN

    --Sn find business date
    V_BUSINESS_TIME := TO_CHAR(V_RVSL_TRANDATE, 'HH24:MI');
    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_RVSL_TRANDATE := TRUNC(V_RVSL_TRANDATE) + 1;
    ELSE
     V_RVSL_TRANDATE := TRUNC(V_RVSL_TRANDATE);
    END IF;
    --En find businesses date
  BEGIN
    SP_REVERSE_GL_ENTRIES(P_INST_CODE,
                     V_RVSL_TRANDATE,
                     V_PROD_CODE,
                     V_CARD_TYPE,
                     V_REVERSAL_AMT,
                     V_FUNC_CODE,
                     P_TXN_CODE,
                     V_DR_CR_FLAG,
                     P_CARD_NO,
                     V_ACTUAL_FEECODE,
                     V_ORGNL_TXN_TOTALFEE_AMT,
                     V_ORGNL_TRANFEE_CR_ACCTNO,
                     V_ORGNL_TRANFEE_DR_ACCTNO,
                     V_CARD_ACCT_NO,
                     P_RVSL_CODE,
                     P_MSG_TYP,
                     P_DELV_CHNL,
                     V_RESP_CDE,
                     V_GL_UPD_FLAG,
                     V_ERRMSG);
    IF V_GL_UPD_FLAG <> 'Y' THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := V_ERRMSG || 'Error while retriving gl detail ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while calling SP_REVERSE_GL_ENTRIES ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  END IF;
  --En reverse the GL entries
  --Sn create a entry for successful
  BEGIN

    IF V_ERRMSG = 'OK' THEN

     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        CTD_ACTUAL_AMOUNT,
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER)
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
         V_TXN_TYPE ,
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        P_ACTUAL_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        V_REVERSAL_AMT,
        V_CARD_CURR,
        'Y',
        'Successful',
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER);
    END IF;

    --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Problem while selecting data from response master ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En create a entry for successful

  --Sn generate response code

  V_RESP_CDE := '1';
  BEGIN
    INSERT INTO CMS_PREAUTH_TRANS_HIST
     (CPH_CARD_NO,
      CPH_MBR_NO,
      CPH_INST_CODE,
      CPH_CARD_NO_ENCR,
      CPH_PREAUTH_VALIDFLAG,
      CPH_COMPLETION_FLAG,
      CPH_TXN_AMNT,
      CPH_RRN,
      CPH_TXN_DATE,
      CPH_TXN_TIME,
      CPH_ORGNL_RRN,
      CPH_ORGNL_TXN_DATE,
      CPH_ORGNL_TXN_TIME,
      CPH_ORGNL_CARD_NO,
      CPH_TERMINALID,
      CPH_ORGNL_TERMINALID,
      CPH_TRANSACTION_FLAG,
      cph_merchant_name,--Added by Deepa on May-09-2012 for statement changes
      cph_merchant_city,
      cph_merchant_state,
      CPH_DELIVERY_CHANNEL,
      CPH_TRAN_CODE,
      CPH_PANNO_LAST4DIGIT)--Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
    VALUES
     (V_HASH_PAN,
      P_MBR_NUMB,
      P_INST_CODE,
      V_ENCR_PAN,
      'N',
      'C',
      P_ACTUAL_AMT,
      P_RRN,
      P_BUSINESS_DATE,
      P_BUSINESS_TIME,
      P_ORGNL_RRN,
      P_ORGNL_BUSINESS_DATE,
      P_ORGNL_BUSINESS_TIME,
      V_HASH_PAN,
      P_TERMINAL_ID,
      P_ORGNL_TERMINAL_ID,
      'R',
      V_FEE_MERCHNAME,--Added by Deepa on May-09-2012 for statement changes
      V_FEE_MERCHCITY,
      V_FEE_MERCHSTATE,
      P_DELV_CHNL,
      P_TXN_CODE,
      (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))));--Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while inserting  CMS_PREAUTH_TRANS_HIST' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  BEGIN

    IF V_PREAUTH_EXPIRY_FLAG = 'N' THEN

        IF V_ACTUAL_DISPATCHED_AMT=0 THEN
    BEGIN
     UPDATE CMS_PREAUTH_TRANSACTION
        SET CPT_TOTALHOLD_AMT    = V_ACTUAL_DISPATCHED_AMT,
           CPT_TRANSACTION_RRN  = P_RRN, -- updating the last completion RRN or reversal RRN in this column.
           CPT_PREAUTH_VALIDFLAG = 'N',
           CPT_TRANSACTION_FLAG = 'R'
      WHERE CPT_RRN = P_ORGNL_RRN AND
           CPT_TXN_DATE = P_ORGNL_BUSINESS_DATE AND
           CPT_TXN_TIME = P_ORGNL_BUSINESS_TIME AND
           CPT_TERMINALID = P_ORGNL_TERMINAL_ID AND
           CPT_MBR_NO = P_MBR_NUMB AND CPT_INST_CODE = P_INST_CODE AND
           CPT_CARD_NO = V_HASH_PAN;

             IF SQL%ROWCOUNT = 0 THEN
                 V_ERRMSG   := 'RECORD NOT UPDATED IN CMS_PREAUTH_TRANSACTION';
                 V_RESP_CDE := '21';
                 RAISE EXP_RVSL_REJECT_RECORD;
             END IF;
        EXCEPTION
        WHEN EXP_RVSL_REJECT_RECORD THEN
         RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while updating  CMS_PREAUTH_TRANSACTION' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

      ELSE
     BEGIN
      UPDATE CMS_PREAUTH_TRANSACTION
        SET CPT_TOTALHOLD_AMT    = V_ACTUAL_DISPATCHED_AMT,
           CPT_TRANSACTION_RRN  = P_RRN, -- updating the last completion RRN or reversal RRN in this column.
           CPT_TRANSACTION_FLAG = 'R'
      WHERE CPT_RRN = P_ORGNL_RRN AND
           CPT_TXN_DATE = P_ORGNL_BUSINESS_DATE AND
           CPT_TXN_TIME = P_ORGNL_BUSINESS_TIME AND
           CPT_TERMINALID = P_ORGNL_TERMINAL_ID AND
           CPT_MBR_NO = P_MBR_NUMB AND CPT_INST_CODE = P_INST_CODE AND
           CPT_CARD_NO = V_HASH_PAN;
           
           IF SQL%ROWCOUNT = 0 THEN
                 V_ERRMSG   := 'RECORD NOT UPDATED IN CMS_PREAUTH_TRANSACTION1';
                 V_RESP_CDE := '21';
                 RAISE EXP_RVSL_REJECT_RECORD;
             END IF;

        EXCEPTION
        WHEN EXP_RVSL_REJECT_RECORD THEN
        RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while updating  CMS_PREAUTH_TRANSACTION1 ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

      END IF;



     IF SQL%ROWCOUNT = 0 THEN
       V_RESP_CDE := '53';
       V_ERRMSG := 'Invalid Reversal Request';

       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;

    END IF;

  END;

  BEGIN
    SELECT CMS_ISO_RESPCDE
     INTO P_RESP_CDE
     FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE = P_INST_CODE AND
         CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
         CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN 
     V_ERRMSG   := 'Data not available for in  response master for respose code'||P_RESP_CDE;
     V_RESP_CDE := '69';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG   := 'Problem while selecting data from response master for respose code' ||
                V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '69';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En generate response code
  BEGIN
    SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
     INTO V_ACCT_BALANCE, V_LEDGER_BAL
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_NO =
         (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
           WHERE CAP_PAN_CODE = V_HASH_PAN AND
                CAP_INST_CODE = P_INST_CODE) AND
         CAM_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN OTHERS THEN
     V_ACCT_BALANCE := 0;
     V_LEDGER_BAL   := 0;
  END;

  -- Sn create a entry in GL
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
      CUSTOMER_CARD_NO,
      TOPUP_CARD_NO,
      TOPUP_ACCT_NO,
      TOPUP_ACCT_TYPE,
      BANK_CODE,
      TOTAL_AMOUNT,
      RULE_INDICATOR,
      RULEGROUPID,
      MCCODE,
      CURRENCYCODE,
      PRODUCTID,
      CATEGORYID,
      TRANFEE_AMT,
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
      FEEATTACHTYPE,
      TRAN_REVERSE_FLAG,
      CUSTOMER_CARD_NO_ENCR,
      TOPUP_CARD_NO_ENCR,
      ORGNL_CARD_NO,
      ORGNL_RRN,
      ORGNL_BUSINESS_DATE,
      ORGNL_BUSINESS_TIME,
      ORGNL_TERMINAL_ID,
      PROXY_NUMBER,
      REVERSAL_CODE,
      CUSTOMER_ACCT_NO,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      RESPONSE_ID 
      
      )
    VALUES
     (P_MSG_TYP,
      P_RRN,
      P_DELV_CHNL,
      P_TERMINAL_ID,
      V_RVSL_TRANDATE,
      P_TXN_CODE,
      V_TXN_TYPE ,
      P_TXN_MODE,
      DECODE(P_RESP_CDE, '00', 'C', 'F'),
      P_RESP_CDE,
      P_BUSINESS_DATE,
      SUBSTR(P_BUSINESS_TIME, 1, 6),
      V_HASH_PAN,
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_INST_CODE,
      TRIM(TO_CHAR((V_REVERSAL_AMT+V_ORGNL_TXN_TOTALFEE_AMT), '99999999999999999.99'))
     ,
      NULL,
      NULL,
      P_MERC_ID,
      V_CURR_CODE,
      V_PROD_CODE,
      V_CARD_TYPE,
      0,
      0,
      NULL,
      NULL,
      V_AUTH_ID,
      V_TRAN_DESC,
      TRIM(TO_CHAR(V_REVERSAL_AMT, '99999999999999999.99')), -- reversal amount will be passed in the table as the same is used in the recon report.
      NULL, --- PRE AUTH AMOUNT
      NULL, -- Partial amount (will be given for partial txn)
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      'Y',
      P_STAN,
      P_INST_CODE,
      NULL,
      NULL,
      'N',
      V_ENCR_PAN,
      NULL,
      V_ENCR_PAN,
      P_ORGNL_RRN,
      P_ORGNL_BUSINESS_DATE,
      P_ORGNL_BUSINESS_TIME,
      P_ORGNL_TERMINAL_ID,
      V_PROXUNUMBER,
      P_RVSL_CODE,
      V_ACCT_NUMBER,
      V_ACCT_BALANCE,
      V_LEDGER_BAL,
      V_RESP_CDE
       
      );
    --Sn update reverse flag
    BEGIN
     UPDATE TRANSACTIONLOG
        SET TRAN_REVERSE_FLAG = 'Y'
      WHERE RRN = P_ORGNL_RRN AND
           BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
           BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
           CUSTOMER_CARD_NO = V_HASH_PAN
           AND INSTCODE = P_INST_CODE AND
           TERMINAL_ID = P_ORGNL_TERMINAL_ID;

     IF SQL%ROWCOUNT = 0 THEN

       V_RESP_CDE := '21';
       V_ERRMSG   := 'Reverse flag is not updated ';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while updating gl flag ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_RVSL_REJECT_RECORD;

    END;
    --En update reverse flag

    BEGIN

     SELECT CTC_ATMUSAGE_AMT,
           CTC_POSUSAGE_AMT,
           CTC_BUSINESS_DATE,
           CTC_MMPOSUSAGE_AMT
       INTO V_ATM_USAGEAMNT,
           V_POS_USAGEAMNT,
           V_BUSINESS_DATE_TRAN,
           V_MMPOS_USAGEAMNT
       FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN
           AND CTC_MBR_NUMB = P_MBR_NUMB;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting CMS_TRANSLIMIT_CHECK 1 ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;

    BEGIN

     --Sn Limit and amount check for POS

     IF P_DELV_CHNL = '02' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND
              CTC_PAN_CODE = V_HASH_PAN
              AND CTC_MBR_NUMB = P_MBR_NUMB;
       ELSE
        IF P_ORGNL_BUSINESS_DATE = P_BUSINESS_DATE THEN

          IF V_REVERSAL_AMT IS NULL THEN
            V_POS_USAGEAMNT := V_POS_USAGEAMNT;

          ELSE
            V_POS_USAGEAMNT := V_POS_USAGEAMNT -
                           TRIM(TO_CHAR(V_REVERSAL_AMT,
                                     '999999999999.99'));
          END IF;

          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_POSUSAGE_AMT = V_POS_USAGEAMNT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;
        END IF;
       END IF;
     END IF;

     IF SQL%ROWCOUNT = 0 THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while updating  CMS_PREAUTH_TRANSACTION 1';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;


     --En Limit and amount check for POS
     EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
       V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK 1 ' ||SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;

    IF V_ERRMSG = 'OK' THEN

     --Sn find prod code and card type and available balance for the card number
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN
                   AND CAP_MBR_NUMB = P_MBR_NUMB AND
                   CAP_INST_CODE = P_INST_CODE) AND
            CAM_INST_CODE = P_INST_CODE
         FOR UPDATE NOWAIT;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_RESP_CDE := '14'; --Ineligible Transaction
        V_ERRMSG   := 'Invalid Card ';
        RAISE EXP_RVSL_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                    SQLERRM;
        RAISE EXP_RVSL_REJECT_RECORD;
     END;

     --En find prod code and card type for the card number
     P_RESP_MSG := TO_CHAR(V_ACCT_BALANCE);

    ELSE

     P_RESP_MSG := V_ERRMSG;

    END IF;


  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;

    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while inserting records in transaction log ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En  create a entry in GL

EXCEPTION
  -- << MAIN EXCEPTION>>
  WHEN EXP_RVSL_REJECT_RECORD THEN
    ROLLBACK TO V_SAVEPOINT;
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BAL
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE := 0;
       V_LEDGER_BAL   := 0;
    END;
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CDE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
     P_RESP_MSG := V_ERRMSG;
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while selecting data from response master ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69';
    END;

    BEGIN

     SELECT CTC_ATMUSAGE_AMT,
           CTC_POSUSAGE_AMT,
           CTC_BUSINESS_DATE,
           CTC_MMPOSUSAGE_AMT
       INTO V_ATM_USAGEAMNT,
           V_POS_USAGEAMNT,
           V_BUSINESS_DATE_TRAN,
           V_MMPOS_USAGEAMNT
       FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN
           AND CTC_MBR_NUMB = P_MBR_NUMB;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting CMS_TRANSLIMIT_CHECK2 ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;

    BEGIN
     --Sn limit update for POS

     IF P_DELV_CHNL = '02' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND
              CTC_PAN_CODE = V_HASH_PAN
              AND CTC_MBR_NUMB = P_MBR_NUMB;

         IF SQL%ROWCOUNT = 0 THEN
           V_RESP_CDE := '21';
           V_ERRMSG   := 'Error while updating  CMS_PREAUTH_TRANSACTION';
           RAISE EXP_RVSL_REJECT_RECORD;
         END IF;

       END IF;
     END IF;
     EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK2 ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
    --Sn create a entry in txn log
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BAL
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE := 0;
       V_LEDGER_BAL   := 0;
    END;
 IF V_RESP_CDE NOT IN ('45','32') THEN--Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time
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
        CUSTOMER_CARD_NO,
        TOPUP_CARD_NO,
        TOPUP_ACCT_NO,
        TOPUP_ACCT_TYPE,
        BANK_CODE,
        TOTAL_AMOUNT,
        CURRENCYCODE,
        ADDCHARGE,
        CATEGORYID,
        ATM_NAME_LOCATION,
        AUTH_ID,
        AMOUNT,
        PREAUTHAMOUNT,
        PARTIALAMOUNT,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        TOPUP_CARD_NO_ENCR,
        ORGNL_CARD_NO,
        ORGNL_RRN,
        ORGNL_BUSINESS_DATE,
        ORGNL_BUSINESS_TIME,
        ORGNL_TERMINAL_ID,
        PROXY_NUMBER,
        REVERSAL_CODE,
        CUSTOMER_ACCT_NO,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        RESPONSE_ID,
        TRANS_DESC
        )
     VALUES
       (P_MSG_TYP,
        P_RRN,
        P_DELV_CHNL,
        P_TERMINAL_ID,
        V_RVSL_TRANDATE,
        P_TXN_CODE,
         V_TXN_TYPE ,
        P_TXN_MODE,
        DECODE(P_RESP_CDE, '00', 'C', 'F'),
        P_RESP_CDE,
        P_BUSINESS_DATE,
        SUBSTR(P_BUSINESS_TIME, 1, 10),
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        P_INST_CODE,
        TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99')),
        V_CURRCODE,
        NULL,
        NULL,
        P_TERMINAL_ID,
        V_AUTH_ID,
        TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99')),
        NULL,
        NULL,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_ENCR_PAN,
        P_ORGNL_RRN,
        P_ORGNL_BUSINESS_DATE,
        P_ORGNL_BUSINESS_TIME,
        P_ORGNL_TERMINAL_ID,
        V_PROXUNUMBER,
        P_RVSL_CODE,
        V_ACCT_NUMBER,
        V_ACCT_BALANCE,
        V_LEDGER_BAL,
        V_RESP_CDE,
        V_TRAN_DESC
        );

    EXCEPTION
     WHEN OTHERS THEN

       P_RESP_CDE := '89';
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
    END;
    END IF;
    --En create a entry in txn log

    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
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
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER)
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
         V_TXN_TYPE ,
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        P_ACTUAL_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        P_ACTUAL_AMT,
        V_CARD_CURR,
        'E',
        V_ERRMSG,
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER);
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69'; -- Server Decline Response 220509
       ROLLBACK;
       RETURN;
    END;

    P_RESP_MSG := V_ERRMSG;
  WHEN OTHERS THEN
    ROLLBACK TO V_SAVEPOINT;
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CDE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
     P_RESP_MSG := V_ERRMSG;
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while selecting data from response master ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69';
     END;

    BEGIN

     SELECT CTC_ATMUSAGE_AMT,
           CTC_POSUSAGE_AMT,
           CTC_BUSINESS_DATE,
           CTC_MMPOSUSAGE_AMT
       INTO V_ATM_USAGEAMNT,
           V_POS_USAGEAMNT,
           V_BUSINESS_DATE_TRAN,
           V_MMPOS_USAGEAMNT
       FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN
           AND CTC_MBR_NUMB = P_MBR_NUMB;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting CMS_TRANSLIMIT_CHECK3 ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;

    BEGIN
     --Sn limit update for POS

     IF P_DELV_CHNL = '02' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND
              CTC_PAN_CODE = V_HASH_PAN
              AND CTC_MBR_NUMB = P_MBR_NUMB;
       END IF;
     END IF;

     IF SQL%ROWCOUNT = 0 THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while updating  CMS_TRANSLIMIT_CHECK3';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;

     EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK3 ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;

    END;
    --Sn create a entry in txn log
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BAL
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE := 0;
       V_LEDGER_BAL   := 0;
    END;
 IF V_RESP_CDE NOT IN ('45','32') THEN--Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time
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
        CUSTOMER_CARD_NO,
        TOPUP_CARD_NO,
        TOPUP_ACCT_NO,
        TOPUP_ACCT_TYPE,
        BANK_CODE,
        TOTAL_AMOUNT,
        CURRENCYCODE,
        ADDCHARGE,
        CATEGORYID,
        ATM_NAME_LOCATION,
        AUTH_ID,
        AMOUNT,
        PREAUTHAMOUNT,
        PARTIALAMOUNT,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        TOPUP_CARD_NO_ENCR,
        ORGNL_CARD_NO,
        ORGNL_RRN,
        ORGNL_BUSINESS_DATE,
        ORGNL_BUSINESS_TIME,
        ORGNL_TERMINAL_ID,
        PROXY_NUMBER,
        REVERSAL_CODE,
        CUSTOMER_ACCT_NO,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        RESPONSE_ID,
        TRANS_DESC
        )
     VALUES
       (P_MSG_TYP,
        P_RRN,
        P_DELV_CHNL,
        P_TERMINAL_ID,
        V_RVSL_TRANDATE,
        P_TXN_CODE,
         V_TXN_TYPE ,
        P_TXN_MODE,
        DECODE(P_RESP_CDE, '00', 'C', 'F'),
        P_RESP_CDE,
        P_BUSINESS_DATE,
        SUBSTR(P_BUSINESS_TIME, 1, 10),
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        P_INST_CODE,
        TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99')),
        V_CURRCODE,
        NULL,
        NULL,
        P_TERMINAL_ID,
        V_AUTH_ID,
        TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99')),
        NULL,
        NULL,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_ENCR_PAN,
        P_ORGNL_RRN,
        P_ORGNL_BUSINESS_DATE,
        P_ORGNL_BUSINESS_TIME,
        P_ORGNL_TERMINAL_ID,
        V_PROXUNUMBER,
        P_RVSL_CODE,
        V_ACCT_NUMBER,
        V_ACCT_BALANCE,
        V_LEDGER_BAL,
        V_RESP_CDE,
        V_TRAN_DESC
        );

    EXCEPTION
     WHEN OTHERS THEN

       P_RESP_CDE := '89';
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
    END;
    END IF;
    --En create a entry in txn log
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
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
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER)
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
         V_TXN_TYPE ,
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        P_ACTUAL_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        P_ACTUAL_AMT,
        V_CARD_CURR,
        'E',
        V_ERRMSG,
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER);
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69'; -- Server Decline Response 220509
       ROLLBACK;
       RETURN;
    END;
    P_RESP_MSG_M24 := V_ERRMSG;
END;
/
show error;