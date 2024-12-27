CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHW_ORDER_REPLACE_CSR
  (
    PRM_INST_CODE IN NUMBER,
    PRM_MSG       IN VARCHAR2,
    PRM_RRN              VARCHAR2,
    PRM_DELIVERY_CHANNEL VARCHAR2,
    PRM_TERM_ID          VARCHAR2,
    PRM_TXN_CODE         VARCHAR2,
    PRM_TXN_MODE         VARCHAR2,
    PRM_TRAN_DATE        VARCHAR2,
    PRM_TRAN_TIME        VARCHAR2,
    PRM_CARD_NO          VARCHAR2,
    PRM_BANK_CODE        VARCHAR2,
    PRM_TXN_AMT          NUMBER,
    PRM_MCC_CODE         VARCHAR2,
    PRM_CURR_CODE        VARCHAR2,
    PRM_PROD_ID          VARCHAR2,
    PRM_EXPRY_DATE IN VARCHAR2,
    PRM_STAN       IN VARCHAR2,
    PRM_MBR_NUMB   IN VARCHAR2,
    PRM_RVSL_CODE  IN NUMBER,
    PRM_AUTH_ID OUT VARCHAR2,
    PRM_RESP_CODE OUT VARCHAR2,
    PRM_RESP_MSG OUT VARCHAR2,
    PRM_CAPTURE_DATE OUT DATE)
                          IS


/**********************************************************************************************
  * DATE OF CREATION          : NA
  * PURPOSE                   : NA
  * CREATED BY                : NA
  * MODIFICATION REASON       : account number inserted in statements log table
  * LAST MODIFICATION DONE BY : Dhiraj G.
  * LAST MODIFICATION DATE    : 11-Apr-2012
  * Build Number              : RI0005 B00011
**************************************************************************************************/

  V_ERR_MSG      VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE NUMBER;
  V_LEDGER_BAL   NUMBER;
  V_TRAN_AMT     NUMBER;
  V_AUTH_ID      VARCHAR2(6);
  V_TOTAL_AMT    NUMBER;
  V_TRAN_DATE DATE;
  V_FUNC_CODE CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_PROD_CODE CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT         NUMBER;
  V_TOTAL_FEE       NUMBER;
  V_UPD_AMT         NUMBER;
  V_UPD_LEDGER_AMT  NUMBER;
  V_NARRATION       VARCHAR2(50);
  V_FEE_OPENING_BAL NUMBER;
  V_RESP_CDE        VARCHAR2(5);
  V_EXPRY_DATE DATE;
  V_DR_CR_FLAG       VARCHAR2(2);
  V_OUTPUT_TYPE      VARCHAR2(2);
  V_APPLPAN_CARDSTAT VARCHAR2(1);
  V_ATMONLINE_LIMIT CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  --prm_inst_code                        VARCHAR2(1);
  PRM_ERR_MSG     VARCHAR2(500);
  V_PRECHECK_FLAG NUMBER;
  V_PREAUTH_FLAG  NUMBER;
  V_AVAIL_PAN CMS_AVAIL_TRANS.CAT_PAN_CODE%TYPE;
  V_GL_UPD_FLAG TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_GL_ERR_MSG VARCHAR2(500);
  V_SAVEPOINT  NUMBER := 0;
  V_TRAN_FEE   NUMBER;
  V_ERROR      VARCHAR2(500);
  V_BUSINESS_DATE_TRAN DATE;
  V_BUSINESS_TIME VARCHAR2(5);
  V_CUTOFF_TIME   VARCHAR2(5);
  V_CARD_CURR     VARCHAR2(5);
  V_FEE_CODE CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_CRGL_CATG CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRGL_CODE CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRSUBGL_CODE CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  --st AND cess
  V_SERVICETAX_PERCENT CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CESS_PERCENT CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_SERVICETAX_AMOUNT NUMBER;
  V_CESS_AMOUNT       NUMBER;
  V_ST_CALC_FLAG CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
  V_CESS_CALC_FLAG CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
  V_ST_CRACCT_NO CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
  V_ST_DRACCT_NO CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
  V_CESS_CRACCT_NO CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
  V_CESS_DRACCT_NO CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
  --
  V_WAIV_PERCNT CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  V_ERR_WAIV       VARCHAR2(300);
  V_LOG_ACTUAL_FEE NUMBER;
  V_LOG_WAIVER_AMT NUMBER;
  V_AUTH_SAVEPOINT NUMBER DEFAULT 0;
  V_ACTUAL_EXPRYDATE DATE;
  V_BUSINESS_DATE DATE;
  V_TXN_TYPE              NUMBER(1);
  V_MINI_TOTREC           NUMBER(2);
  V_MINISTMT_ERRMSG       VARCHAR2(500);
  V_MINISTMT_OUTPUT       VARCHAR2(900);
  V_FEE_ATTACH_TYPE       VARCHAR2(1);
  V_CHECK_MERCHANT        NUMBER(1);
  EXP_REJECT_RECORD       EXCEPTION;
  V_TERMINAL_DOWNLOAD_IND VARCHAR2(1);
  V_TERMINAL_COUNT        NUMBER;
  V_TEMP_EXPIRY CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
  V_BIN_CODE           NUMBER(6);
  V_TERMINAL_BIN_COUNT NUMBER;
  V_ATM_USAGEAMNT CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  V_ATM_USAGELIMIT CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_MMPOS_USAGEAMNT CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
  V_MMPOS_USAGELIMIT CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
  V_PREAUTH_AMOUNT    NUMBER;
  V_PREAUTH_TXNAMOUNT NUMBER;
  V_PREAUTH_DATE DATE;
  V_PREAUTH_HOLD        VARCHAR2(1);
  V_PREAUTH_PERIOD      NUMBER;
  V_PREAUTH_USAGE_LIMIT NUMBER;
  V_CARD_ACCT_NO        VARCHAR2(20);
  V_HOLD_AMOUNT         NUMBER;
  V_PREAUTH_EXP_DATE DATE;
  V_HASH_PAN CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT NUMBER;
  V_TRAN_TYPE VARCHAR2(2);
  V_DATE DATE;
  V_TIME         VARCHAR2(10);
  V_MAX_CARD_BAL NUMBER;
  V_CURR_DATE DATE;
  V_PREAUTH_EXP_PERIOD VARCHAR2(10);
  V_INTERNATIONAL_FLAG CHARACTER(1);
  V_PROXUNUMBER CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_CAP_CARD_STAT            VARCHAR2(10);
  CRDSTAT_CNT                VARCHAR2(10);
  V_CRO_OLDCARD_REISSUE_STAT VARCHAR2(10);
  V_MBRNUMB                  VARCHAR2(10);
  NEW_DISPNAME               VARCHAR2(50);
  NEW_CARD_NO                VARCHAR2(100);
  V_CAP_PROD_CATG            VARCHAR2(100);
  V_CUST_CODE                VARCHAR2(100);
  PRM_REMRK                  VARCHAR2(100);
  V_RESONCODE CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
BEGIN
  --<< MAIN BEGIN>>
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE   := '1';
  PRM_ERR_MSG  := 'OK';
  PRM_RESP_MSG := 'OK';
  PRM_REMRK    := 'Online Order Replacement Card';
  --RAISE_APPLICATION_ERROR(-20001,'PRM_TRAN_DATE= '|| PRM_TRAN_DATE || 'PRM_TRAN_TIME= '|| PRM_TRAN_TIME||'PRM_EXPRY_DATE= '||PRM_EXPRY_DATE);
  BEGIN
    --SN CREATE HASH PAN
    --Gethash is used to hash the original Pan no
    BEGIN
      V_HASH_PAN := GETHASH(PRM_CARD_NO);
    EXCEPTION
    WHEN OTHERS THEN
      PRM_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    --EN CREATE HASH PAN
    --SN create encr pan
    --Fn_Emaps_Main is used for Encrypt the original Pan no
    BEGIN
      V_ENCR_PAN := FN_EMAPS_MAIN(PRM_CARD_NO);
    EXCEPTION
    WHEN OTHERS THEN
      PRM_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    --EN create encr pan
    --sN CHECK INST CODE
    BEGIN
      IF PRM_INST_CODE IS NULL THEN
        V_RESP_CDE     := '12'; -- Invalid Transaction
        PRM_ERR_MSG    := 'Institute code cannot be null ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      V_RESP_CDE  := '12'; -- Invalid Transaction
      PRM_ERR_MSG := 'Institute code cannot be null ' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    --eN CHECK INST CODE
    --Sn check txn currency
    /* BEGIN
    IF TRIM (prm_curr_code) IS NULL
    THEN
    v_resp_cde := '21';
    PRM_ERR_MSG :='Transaction currency  cannot be null ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
    END IF;
    EXCEPTION
    WHEN exp_reject_record
    THEN
    RAISE;
    WHEN OTHERS
    THEN
    v_resp_cde := '21';
    PRM_ERR_MSG :='Transcurrency cannot be null ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
    END;*/
    --En check txn currency
    BEGIN
      V_DATE := TO_DATE(SUBSTR(TRIM(PRM_TRAN_DATE), 1, 8), 'yyyymmdd');
    EXCEPTION
    WHEN OTHERS THEN
      V_RESP_CDE  := '45'; -- Server Declined -220509
      PRM_ERR_MSG := 'Problem while converting transaction date ' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    BEGIN
      V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(PRM_TRAN_DATE), 1, 8) || ' ' || SUBSTR(TRIM(PRM_TRAN_TIME), 1, 10), 'yyyymmdd hh24:mi:ss');
    EXCEPTION
    WHEN OTHERS THEN
      V_RESP_CDE  := '32'; -- Server Declined -220509
      PRM_ERR_MSG := 'Problem while converting transaction time ' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    --En get date
    --Sn Duplicate RRN Check
    BEGIN
      SELECT COUNT(1)
      INTO V_RRN_COUNT
      FROM TRANSACTIONLOG
      WHERE RRN = PRM_RRN
      AND --Changed for admin dr cr.
        BUSINESS_DATE = PRM_TRAN_DATE;
      IF V_RRN_COUNT  > 0 THEN
        V_RESP_CDE   := '22';
        PRM_ERR_MSG  := 'Duplicate RRN from the Treminal on' || PRM_TRAN_DATE;
        RAISE EXP_REJECT_RECORD;
      END IF;
    END;
    --En Duplicate RRN Check
    --Sn find service tax
    BEGIN
      SELECT CIP_PARAM_VALUE
      INTO V_SERVICETAX_PERCENT
      FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'SERVICETAX'
      AND CIP_INST_CODE   = PRM_INST_CODE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'Service Tax is  not defined in the system';
      RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'Error while selecting service tax from system ';
      RAISE EXP_REJECT_RECORD;
    END;
    --En find service tax
    BEGIN
      SELECT CIP_PARAM_VALUE
      INTO V_CESS_PERCENT
      FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'CESS'
      AND CIP_INST_CODE   = PRM_INST_CODE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'Cess is not defined in the system';
      RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'Error while selecting cess from system ';
      RAISE EXP_REJECT_RECORD;
    END;
    --En find cess
    ---Sn find cutoff time
    BEGIN
      SELECT CIP_PARAM_VALUE
      INTO V_CUTOFF_TIME
      FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'CUTOFF'
      AND CIP_INST_CODE   = PRM_INST_CODE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_CUTOFF_TIME := 0;
      V_RESP_CDE    := '21';
      PRM_ERR_MSG   := 'Cutoff time is not defined in the system';
      RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'Error while selecting cutoff  dtl  from system ';
      RAISE EXP_REJECT_RECORD;
    END;
    ---En find cutoff time
    --Sn find debit and credit flag
    BEGIN
      SELECT CTM_CREDIT_DEBIT_FLAG,
        CTM_OUTPUT_TYPE,
        TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
        CTM_TRAN_TYPE
      INTO V_DR_CR_FLAG,
        V_OUTPUT_TYPE,
        V_TXN_TYPE,
        V_TRAN_TYPE
      FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE      = PRM_TXN_CODE
      AND CTM_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL
      AND CTM_INST_CODE        = PRM_INST_CODE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CDE  := '12'; --Ineligible Transaction
      PRM_ERR_MSG := 'Transflag  not defined for txn code ' || PRM_TXN_CODE || ' and delivery channel ' || PRM_DELIVERY_CHANNEL;
      RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
      V_RESP_CDE  := '21'; --Ineligible Transaction
      PRM_ERR_MSG := 'Error while selecting transaction details';
      RAISE EXP_REJECT_RECORD;
    END;
    --En find debit and credit flag
    --Sn find the tran amt
    IF ((V_TRAN_TYPE   = 'F') OR (PRM_MSG = '0100')) THEN
      IF (PRM_TXN_AMT >= 0) THEN
        V_TRAN_AMT    := PRM_TXN_AMT;
        BEGIN
          SP_CONVERT_CURR(PRM_INST_CODE, PRM_CURR_CODE, PRM_CARD_NO, PRM_TXN_AMT, V_TRAN_DATE, V_TRAN_AMT, V_CARD_CURR, PRM_ERR_MSG);
          IF PRM_ERR_MSG <> 'OK' THEN
            V_RESP_CDE   := '44';
            RAISE EXP_REJECT_RECORD;
          END IF;
        EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
          V_RESP_CDE  := '69'; -- Server Declined -220509
          PRM_ERR_MSG := 'Error from currency conversion ' || SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
        END;
      ELSE
        -- If transaction Amount is zero - Invalid Amount -220509
        V_RESP_CDE  := '43';
        PRM_ERR_MSG := 'INVALID AMOUNT';
        RAISE EXP_REJECT_RECORD;
      END IF;
    END IF;
    --En find the tran amt
    --Sn select authorization processe flag
    BEGIN
      SELECT PTP_PARAM_VALUE
      INTO V_PRECHECK_FLAG
      FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE CHECK'
      AND PTP_INST_CODE    = PRM_INST_CODE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CDE  := '21'; --only for master setups
      PRM_ERR_MSG := 'Master set up is not done for Authorization Process';
      RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
      V_RESP_CDE  := '21'; --only for master setups
      PRM_ERR_MSG := 'Error while selecting precheck flag' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    --En select authorization process   flag
    --Sn select authorization processe flag
    BEGIN
      SELECT PTP_PARAM_VALUE
      INTO V_PREAUTH_FLAG
      FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE AUTH'
      AND PTP_INST_CODE    = PRM_INST_CODE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'Master set up is not done for Authorization Process';
      RAISE EXP_REJECT_RECORD;
    END;
    --En select authorization process   flag
    --Sn find card detail
    BEGIN
      SELECT CAP_PROD_CODE,
        CAP_CARD_TYPE,
        CAP_EXPRY_DATE,
        CAP_CARD_STAT,
        CAP_ATM_ONLINE_LIMIT,
        CAP_POS_ONLINE_LIMIT,
        CAP_PROXY_NUMBER,
        CAP_ACCT_NO
      INTO V_PROD_CODE,
        V_PROD_CATTYPE,
        V_EXPRY_DATE,
        V_APPLPAN_CARDSTAT,
        V_ATMONLINE_LIMIT,
        V_ATMONLINE_LIMIT,
        V_PROXUNUMBER,
        V_ACCT_NUMBER
      FROM CMS_APPL_PAN
      WHERE CAP_PAN_CODE = V_HASH_PAN -- prm_card_no
      AND CAP_INST_CODE  = PRM_INST_CODE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CDE  := '14';
      PRM_ERR_MSG := 'CARD NOT FOUND ' || V_HASH_PAN;
      RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'Problem while selecting card detail' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    --En find card detail
    -- Expiry Check
    BEGIN
      --SELECT SYSDATE INTO V_CURR_DATE FROM DUAL;
      IF TO_DATE(PRM_TRAN_DATE, 'YYYYMMDD') > LAST_DAY(TO_CHAR(V_EXPRY_DATE, 'DD-MON-YY')) THEN
        V_RESP_CDE                         := '13';
        PRM_ERR_MSG                        := 'EXPIRED CARD';
        RAISE EXP_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'ERROR IN EXPIRY DATE CHECK ' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    -- End Expiry Check
    --Sn check for precheck
    IF V_PRECHECK_FLAG = 1 THEN
      BEGIN
        SP_PRECHECK_TXN(PRM_INST_CODE, PRM_CARD_NO, PRM_DELIVERY_CHANNEL, V_EXPRY_DATE, V_APPLPAN_CARDSTAT, PRM_TXN_CODE, PRM_TXN_MODE, PRM_TRAN_DATE, PRM_TRAN_TIME, V_TRAN_AMT, V_ATMONLINE_LIMIT, V_POSONLINE_LIMIT, V_RESP_CDE, PRM_ERR_MSG);
        IF (V_RESP_CDE <> '1' OR PRM_ERR_MSG <> 'OK') THEN
          RAISE EXP_REJECT_RECORD;
        END IF;
      EXCEPTION
      WHEN EXP_REJECT_RECORD THEN
        RAISE;
      WHEN OTHERS THEN
        V_RESP_CDE  := '21';
        PRM_ERR_MSG := 'Error from precheck processes ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
      END;
    END IF;
    --En check for Precheck
    --Sn check for Preauth
    IF V_PREAUTH_FLAG = 1 THEN
      BEGIN
        SP_PREAUTHORIZE_TXN(PRM_CARD_NO, PRM_MCC_CODE, PRM_CURR_CODE, V_TRAN_DATE, PRM_TXN_CODE, PRM_INST_CODE, PRM_TRAN_DATE, V_TRAN_AMT, PRM_DELIVERY_CHANNEL, V_RESP_CDE, PRM_ERR_MSG);
        IF (V_RESP_CDE  <> '1' OR TRIM(PRM_ERR_MSG) <> 'OK') THEN
          IF (V_RESP_CDE = '70' OR TRIM(PRM_ERR_MSG) <> 'OK') THEN
            V_RESP_CDE  := '70';
            RAISE EXP_REJECT_RECORD;
          ELSE
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          END IF;
        END IF;
      EXCEPTION
      WHEN EXP_REJECT_RECORD THEN
        RAISE;
      WHEN OTHERS THEN
        V_RESP_CDE  := '21';
        PRM_ERR_MSG := 'Error from pre_auth process ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
      END;
    END IF;
    --En check for preauth
    --Sn find function code attached to txn code
    BEGIN
      SELECT CFM_FUNC_CODE
      INTO V_FUNC_CODE
      FROM CMS_FUNC_MAST
      WHERE CFM_TXN_CODE       = PRM_TXN_CODE
      AND CFM_TXN_MODE         = PRM_TXN_MODE
      AND CFM_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL
      AND CFM_INST_CODE        = PRM_INST_CODE;
      --TXN mode and delivery channel we need to attach
      --bkz txn code may be same for all type of channels
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CDE  := '12'; --Ineligible Transaction
      PRM_ERR_MSG := 'Function code not defined for txn code ' || PRM_TXN_CODE;
      RAISE EXP_REJECT_RECORD;
    WHEN TOO_MANY_ROWS THEN
      V_RESP_CDE  := '12';
      PRM_ERR_MSG := 'More than one function defined for txn code ' || PRM_TXN_CODE;
      RAISE EXP_REJECT_RECORD;
    END;
    --En find function code attached to txn code
    --Sn find prod code and card type and available balance for the card number
    BEGIN
      SELECT CAM_ACCT_BAL,
        CAM_LEDGER_BAL,
        CAM_ACCT_NO
      INTO V_ACCT_BALANCE,
        V_LEDGER_BAL,
        V_CARD_ACCT_NO
      FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
        (SELECT CAP_ACCT_NO
        FROM CMS_APPL_PAN
        WHERE CAP_PAN_CODE = V_HASH_PAN --prm_card_no
        AND CAP_MBR_NUMB   = PRM_MBR_NUMB
        AND CAP_INST_CODE  = PRM_INST_CODE
        )
      AND CAM_INST_CODE = PRM_INST_CODE FOR UPDATE NOWAIT;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CDE  := '14'; --Ineligible Transaction
      PRM_ERR_MSG := 'Invalid Card ';
      RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
      V_RESP_CDE  := '12';
      PRM_ERR_MSG := 'Error while selecting data from card Master for card number ' || SQLERRM;
      RAISE EXP_REJECT_RECORD;
    END;
    --En find prod code and card type for the card number
    BEGIN
      SP_TRAN_FEES_CMSAUTH(PRM_INST_CODE, PRM_CARD_NO, PRM_DELIVERY_CHANNEL, V_TXN_TYPE, PRM_TXN_MODE, PRM_TXN_CODE, PRM_CURR_CODE, '', '', V_TRAN_AMT, V_TRAN_DATE, V_FEE_AMT, V_ERROR, V_FEE_CODE, V_FEE_CRGL_CATG, V_FEE_CRGL_CODE, V_FEE_CRSUBGL_CODE, V_FEE_CRACCT_NO, V_FEE_DRGL_CATG, V_FEE_DRGL_CODE, V_FEE_DRSUBGL_CODE, V_FEE_DRACCT_NO, V_ST_CALC_FLAG, V_CESS_CALC_FLAG, V_ST_CRACCT_NO, V_ST_DRACCT_NO, V_CESS_CRACCT_NO, V_CESS_DRACCT_NO
      --,
      --v_fee_attach_type
      );
      IF V_ERROR    <> 'OK' THEN
        V_RESP_CDE  := '21';
        PRM_ERR_MSG := V_ERROR;
        RAISE EXP_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'Error from fee calc process ' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    ---En dynamic fee calculation .
    --Sn calculate waiver on the fee
    BEGIN
      SP_CALCULATE_WAIVER(PRM_INST_CODE, PRM_CARD_NO, '000', V_PROD_CODE, V_PROD_CATTYPE, V_FEE_CODE, V_WAIV_PERCNT, V_ERR_WAIV);
      IF V_ERR_WAIV <> 'OK' THEN
        V_RESP_CDE  := '21';
        PRM_ERR_MSG := V_ERR_WAIV;
        RAISE EXP_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'Error from waiver calc process ' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    --En calculate waiver on the fee
    --Sn apply waiver on fee amount
    V_LOG_ACTUAL_FEE := V_FEE_AMT; --only used to log in log table
    V_FEE_AMT        := ROUND(V_FEE_AMT  -
    ((V_FEE_AMT                          * V_WAIV_PERCNT) / 100), 2);
    V_LOG_WAIVER_AMT := V_LOG_ACTUAL_FEE - V_FEE_AMT;
    --only used to log in log table
    --En apply waiver on fee amount
    --Sn apply service tax and cess
    IF V_ST_CALC_FLAG      = 1 THEN
      V_SERVICETAX_AMOUNT := (V_FEE_AMT * V_SERVICETAX_PERCENT) / 100;
    ELSE
      V_SERVICETAX_AMOUNT := 0;
    END IF;
    IF V_CESS_CALC_FLAG = 1 THEN
      V_CESS_AMOUNT    := (V_SERVICETAX_AMOUNT * V_CESS_PERCENT) / 100;
    ELSE
      V_CESS_AMOUNT := 0;
    END IF;
    V_TOTAL_FEE := ROUND(V_FEE_AMT + V_SERVICETAX_AMOUNT + V_CESS_AMOUNT, 2);
    --v_fee_amt :=
    --En apply service tax and cess
    --En find fees amount attached to func code, prod code and card type
    --Sn find total transaction    amount
    IF V_DR_CR_FLAG       = 'CR' THEN
      V_TOTAL_AMT        := V_TRAN_AMT     - V_TOTAL_FEE;
      V_UPD_AMT          := V_ACCT_BALANCE + V_TOTAL_AMT;
      V_UPD_LEDGER_AMT   := V_LEDGER_BAL   + V_TOTAL_AMT;
    ELSIF V_DR_CR_FLAG    = 'DR' THEN
      V_TOTAL_AMT        := V_TRAN_AMT     + V_TOTAL_FEE;
      V_UPD_AMT          := V_ACCT_BALANCE - V_TOTAL_AMT;
      V_UPD_LEDGER_AMT   := V_LEDGER_BAL   - V_TOTAL_AMT;
    ELSIF V_DR_CR_FLAG    = 'NA' THEN
      IF PRM_TXN_CODE     = '11' AND PRM_MSG = '0100' THEN
        V_TOTAL_AMT      := V_TRAN_AMT     + V_TOTAL_FEE;
        V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
        V_UPD_LEDGER_AMT := V_LEDGER_BAL   - V_TOTAL_AMT;
      ELSE
        IF V_TOTAL_FEE = 0 THEN
          V_TOTAL_AMT := 0;
        ELSE
          V_TOTAL_AMT := V_TOTAL_FEE;
        END IF;
        -- v_total_amt :=  0 ;
        V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
        V_UPD_LEDGER_AMT := V_LEDGER_BAL   - V_TOTAL_AMT;
      END IF;
    ELSE
      V_RESP_CDE  := '12'; --Ineligible Transaction
      PRM_ERR_MSG := 'Invalid transflag    txn code ' || PRM_TXN_CODE;
      RAISE EXP_REJECT_RECORD;
    END IF;
    --En find total transaction    amout
    --Sn check balance
    IF V_DR_CR_FLAG NOT IN ('NA', 'CR') AND PRM_TXN_CODE <> '93' -- For credit transaction or Non-Financial transaction Insufficient Balance Check is not required. -- 29th June 2011
      THEN
      IF V_UPD_AMT   < 0 THEN
        V_RESP_CDE  := '15'; --Ineligible Transaction
        PRM_ERR_MSG := 'Insufficent Balance ';
        RAISE EXP_REJECT_RECORD;
      END IF;
    END IF;
    --En check balance
    -- Check for maximum card balance configured for the product profile.
    --Sn create gl entries and acct update
    BEGIN
      SP_UPD_TRANSACTION_ACCNT_AUTH(PRM_INST_CODE, V_TRAN_DATE, V_PROD_CODE, V_PROD_CATTYPE, V_TRAN_AMT, V_FUNC_CODE, PRM_TXN_CODE, V_DR_CR_FLAG, PRM_RRN, PRM_TERM_ID, PRM_DELIVERY_CHANNEL, PRM_TXN_MODE, PRM_CARD_NO, V_FEE_CODE, V_FEE_AMT, V_FEE_CRACCT_NO, V_FEE_DRACCT_NO, V_ST_CALC_FLAG, V_CESS_CALC_FLAG, V_SERVICETAX_AMOUNT, V_ST_CRACCT_NO, V_ST_DRACCT_NO, V_CESS_AMOUNT, V_CESS_CRACCT_NO, V_CESS_DRACCT_NO, V_CARD_ACCT_NO,
      ---Card's account no has been passed instead of card no(For Debit card acct_no will be different)
      V_HOLD_AMOUNT, --For PreAuth Completion transaction
      PRM_MSG, V_RESP_CDE, PRM_ERR_MSG);
      IF (V_RESP_CDE <> '1' OR PRM_ERR_MSG <> 'OK') THEN
        V_RESP_CDE   := '21';
        RAISE EXP_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'Error from currency conversion ' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    BEGIN
      SELECT TO_NUMBER(CBP_PARAM_VALUE)
      INTO V_MAX_CARD_BAL
      FROM CMS_BIN_PARAM
      WHERE CBP_INST_CODE   = PRM_INST_CODE
      AND CBP_PARAM_NAME    = 'Max Card Balance'
      AND CBP_PROFILE_CODE IN
        (SELECT CPM_PROFILE_CODE FROM CMS_PROD_MAST WHERE CPM_PROD_CODE = V_PROD_CODE
        );
    EXCEPTION
    WHEN OTHERS THEN
      V_RESP_CDE  := '21';
      PRM_ERR_MSG := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' || SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    --Sn check balance
    IF (V_UPD_LEDGER_AMT > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL) THEN
      V_RESP_CDE        := '30';
      PRM_ERR_MSG       := 'EXCEEDING MAXIMUM CARD BALANCE / BAD CREDIT STATUS';
      RAISE EXP_REJECT_RECORD;
    END IF;
    --En check balance
    IF PRM_TXN_CODE = '11' AND PRM_DELIVERY_CHANNEL = '03' THEN
      BEGIN
        SELECT CAP_PROD_CATG,
          CAP_CARD_STAT,
          CAP_ACCT_NO,
          CAP_CUST_CODE
        INTO V_CAP_PROD_CATG,
          V_CAP_CARD_STAT,
          V_ACCT_NUMBER,
          V_CUST_CODE
        FROM CMS_APPL_PAN
        WHERE CAP_PAN_CODE = V_HASH_PAN
        AND CAP_INST_CODE  = PRM_INST_CODE;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        PRM_ERR_MSG := 'Pan not found in master';
        V_RESP_CDE  := '21';
        RAISE EXP_REJECT_RECORD;
      END;
      BEGIN
        SELECT COUNT(*)
        INTO CRDSTAT_CNT
        FROM CMS_REISSUE_VALIDSTAT
        WHERE CRV_INST_CODE   = PRM_INST_CODE
        AND CRV_VALID_CRDSTAT = V_CAP_CARD_STAT
        AND CRV_PROD_CATG    IN ('P');
        IF CRDSTAT_CNT        = 0 THEN
          PRM_ERR_MSG        := 'Not a valid card status. Card cannot be reissued';
          V_RESP_CDE         := '09';
          RAISE EXP_REJECT_RECORD;
        END IF;
      END;
      BEGIN
        SELECT CRO_OLDCARD_REISSUE_STAT
        INTO V_CRO_OLDCARD_REISSUE_STAT
        FROM CMS_REISSUE_OLDCARDSTAT
        WHERE CRO_INST_CODE  = PRM_INST_CODE
        AND CRO_OLDCARD_STAT = V_CAP_CARD_STAT
        AND CRO_SPPRT_KEY    = 'R';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        PRM_ERR_MSG := 'Default old card status nor defined for institution ' || PRM_INST_CODE;
        V_RESP_CDE  := '09';
        RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
        PRM_ERR_MSG := 'Error while getting default old card status for institution ' || PRM_INST_CODE;
        V_RESP_CDE  := '21';
        RAISE EXP_REJECT_RECORD;
      END;
      BEGIN
        --begin 5 starts
        UPDATE CMS_APPL_PAN
        SET CAP_CARD_STAT   = V_CRO_OLDCARD_REISSUE_STAT,
          CAP_LUPD_USER     = PRM_BANK_CODE
        WHERE CAP_INST_CODE = PRM_INST_CODE
        AND CAP_PAN_CODE    = V_HASH_PAN;
        IF SQL%ROWCOUNT    != 1 THEN
          PRM_ERR_MSG      := 'Problem in updation of status for pan ' || V_HASH_PAN;
          V_RESP_CDE       := '09';
          RAISE EXP_REJECT_RECORD;
        END IF;
      END;
      --Sn find member number
      BEGIN
        SELECT CIP_PARAM_VALUE
        INTO V_MBRNUMB
        FROM CMS_INST_PARAM
        WHERE CIP_INST_CODE = PRM_INST_CODE
        AND CIP_PARAM_KEY   = 'MBR_NUMB';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        PRM_ERR_MSG := 'Member number not defined for the institute';
        V_RESP_CDE  := '21';
        RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
        PRM_ERR_MSG := 'Error while selecting member number from institute';
        V_RESP_CDE  := '21';
        RAISE EXP_REJECT_RECORD;
      END;
      SELECT CAP_DISP_NAME
      INTO NEW_DISPNAME
      FROM CMS_APPL_PAN
      WHERE CAP_INST_CODE = PRM_INST_CODE
      AND CAP_PAN_CODE    = V_HASH_PAN;
      BEGIN
        SP_ORDER_REISSUEPAN_CMS(PRM_INST_CODE, PRM_CARD_NO, V_PROD_CODE, V_PROD_CATTYPE, NEW_DISPNAME, PRM_BANK_CODE, NEW_CARD_NO, PRM_ERR_MSG);
        IF PRM_ERR_MSG != 'OK' THEN
          PRM_ERR_MSG  := 'From reissue pan generation process-- ' || PRM_ERR_MSG;
          V_RESP_CDE   := '21';
          RAISE EXP_REJECT_RECORD;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        PRM_ERR_MSG := 'From reissue pan generation process-- ' || PRM_ERR_MSG;
        V_RESP_CDE  := '21';
        RAISE EXP_REJECT_RECORD;
      END;
      IF PRM_ERR_MSG = 'OK' THEN
        BEGIN
          INSERT
          INTO CMS_HTLST_REISU
            (
              CHR_INST_CODE,
              CHR_PAN_CODE,
              CHR_MBR_NUMB,
              CHR_NEW_PAN,
              CHR_NEW_MBR,
              CHR_REISU_CAUSE,
              CHR_INS_USER,
              CHR_LUPD_USER,
              CHR_PAN_CODE_ENCR,
              CHR_NEW_PAN_ENCR
            )
            VALUES
            (
              PRM_INST_CODE,
              V_HASH_PAN,
              V_MBRNUMB,
              GETHASH(NEW_CARD_NO),
              V_MBRNUMB,
              'R',
              PRM_BANK_CODE,
              PRM_BANK_CODE,
              V_ENCR_PAN,
              FN_EMAPS_MAIN(NEW_CARD_NO)
            );
        EXCEPTION
          --excp of begin 4
        WHEN OTHERS THEN
          PRM_ERR_MSG := 'Error while creating  reissuue record ' || SUBSTR
          (
            SQLERRM, 1, 200
          )
          ;
          V_RESP_CDE := '21';
          RAISE EXP_REJECT_RECORD;
        END;
        BEGIN
          INSERT
          INTO CMS_CARDISSUANCE_STATUS
            (
              CCS_INST_CODE,
              CCS_PAN_CODE,
              CCS_CARD_STATUS,
              CCS_INS_USER,
              CCS_INS_DATE,
              CCS_PAN_CODE_ENCR
            )
            VALUES
            (
              PRM_INST_CODE,
              GETHASH(NEW_CARD_NO),
              '2',
              PRM_BANK_CODE,
              SYSDATE,
              FN_EMAPS_MAIN(NEW_CARD_NO)
            );
        EXCEPTION
        WHEN OTHERS THEN
          PRM_ERR_MSG := 'Error while Inserting CCF table ' || SUBSTR
          (
            SQLERRM, 1, 200
          )
          ;
          V_RESP_CDE := '21';
          RAISE EXP_REJECT_RECORD;
        END;
        BEGIN
            INSERT INTO CMS_SMSANDEMAIL_ALERT
            (CSA_INST_CODE,
            CSA_PAN_CODE,
            CSA_PAN_CODE_ENCR,
            CSA_CELLPHONECARRIER,
            CSA_LOADORCREDIT_FLAG,
            CSA_LOWBAL_FLAG,
            CSA_LOWBAL_AMT,
            CSA_NEGBAL_FLAG,
            CSA_HIGHAUTHAMT_FLAG,
            CSA_HIGHAUTHAMT,
            CSA_DAILYBAL_FLAG,
            CSA_BEGIN_TIME,
            CSA_END_TIME,
            CSA_INSUFF_FLAG,
            CSA_INCORRPIN_FLAG,
            CSA_INS_USER,
            CSA_INS_DATE,
            CSA_LUPD_USER,
            CSA_LUPD_DATE)
            (SELECT PRM_INST_CODE,
            GETHASH(NEW_CARD_NO),
            FN_EMAPS_MAIN(NEW_CARD_NO),
            NVL(CSA_CELLPHONECARRIER, 0),
            CSA_LOADORCREDIT_FLAG,
            CSA_LOWBAL_FLAG,
            NVL(CSA_LOWBAL_AMT, 0),
            CSA_NEGBAL_FLAG,
            CSA_HIGHAUTHAMT_FLAG,
            NVL(CSA_HIGHAUTHAMT, 0),
            CSA_DAILYBAL_FLAG,
            NVL(CSA_BEGIN_TIME, 0),
            NVL(CSA_END_TIME, 0),
            CSA_INSUFF_FLAG,
            CSA_INCORRPIN_FLAG,
            PRM_BANK_CODE,
            SYSDATE,
            PRM_BANK_CODE,
            SYSDATE
            FROM CMS_SMSANDEMAIL_ALERT
            WHERE CSA_INST_CODE = PRM_INST_CODE AND CSA_PAN_CODE = V_HASH_PAN);

          IF SQL%ROWCOUNT != 1 THEN
            PRM_ERR_MSG   := 'Error while Entering sms email alert detail ' || SUBSTR
            (
              SQLERRM, 1, 200
            )
            ;
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          PRM_ERR_MSG := 'Error while Entering sms email alert detail ' || SUBSTR
          (
            SQLERRM, 1, 200
          )
          ;
          V_RESP_CDE := '21';
          RAISE EXP_REJECT_RECORD;
        END;
      END IF;
      PRM_RESP_MSG := NEW_CARD_NO;
    END IF;
    --En create gl entries and acct update
    --Sn find narration
    BEGIN
      SELECT CTM_TRAN_DESC
      INTO V_NARRATION
      FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE      = PRM_TXN_CODE
      AND CTM_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL
      AND CTM_INST_CODE        = PRM_INST_CODE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_NARRATION := 'Transaction type ' || PRM_TXN_CODE;
    END;
    --En find narration
    --Sn create a entry in statement log
    IF V_DR_CR_FLAG <> 'NA' THEN
      BEGIN
        INSERT
        INTO CMS_STATEMENTS_LOG
          (
            CSL_PAN_NO,
            CSL_OPENING_BAL,
            CSL_TRANS_AMOUNT,
            CSL_TRANS_TYPE,
            CSL_TRANS_DATE,
            CSL_CLOSING_BALANCE,
            CSL_TRANS_NARRRATION,
            CSL_INST_CODE,
            CSL_PAN_NO_ENCR,
            CSL_INS_DATE,   -- Added by DHIRAJ MG on 11/04/2012
         CSL_INS_USER,   -- Added by DHIRAJ MG on 11/04/2012
         CSL_ACCT_NO     --Added by DHIRAJ MG on 11/04/2012  to log the account number
          )
          VALUES
          ( --prm_card_no
            V_HASH_PAN,
            V_ACCT_BALANCE,
            V_TRAN_AMT,
            V_DR_CR_FLAG,
            V_TRAN_DATE,
            DECODE(V_DR_CR_FLAG, 'DR', V_ACCT_BALANCE - V_TRAN_AMT, 'CR', V_ACCT_BALANCE + V_TRAN_AMT, 'NA', V_ACCT_BALANCE),
            V_NARRATION,
            PRM_INST_CODE,
            V_ENCR_PAN,
            sysdate,           -- Added by DHIRAJ MG on 11/04/2012
        1,-- Added by DHIRAJ MG on 11/04/2012
        V_ACCT_NUMBER--Added by DHIRAJ MG on 11/04/2012  to log the account number
          );
      EXCEPTION
      WHEN OTHERS THEN
        V_RESP_CDE  := '21';
        PRM_ERR_MSG := 'Problem while inserting into statement log for tran amt ' || SUBSTR
        (
          SQLERRM, 1, 200
        )
        ;
        RAISE EXP_REJECT_RECORD;
      END;
    END IF;
    --En create a entry in statement log
    --Sn find fee opening balance
    IF V_TOTAL_FEE <> 0 THEN
      BEGIN
        SELECT DECODE(V_DR_CR_FLAG, 'DR', V_ACCT_BALANCE - V_TRAN_AMT, 'CR', V_ACCT_BALANCE + V_TRAN_AMT, 'NA', V_ACCT_BALANCE)
        INTO V_FEE_OPENING_BAL
        FROM DUAL;
      EXCEPTION
      WHEN OTHERS THEN
        V_RESP_CDE  := '12';
        PRM_ERR_MSG := 'Error while selecting data from card Master for card number ' || PRM_CARD_NO;
        RAISE EXP_REJECT_RECORD;
      END;
      --En find fee opening balance
      --Sn create entries for FEES attached
      --FOR I IN C LOOP
      BEGIN
        --v_fee_opening_bal := v_upd_amt;
        --v_upd_amt := v_upd_amt - i.fee_amt;
        INSERT
        INTO CMS_STATEMENTS_LOG
          (
            CSL_PAN_NO,
            CSL_OPENING_BAL,
            CSL_TRANS_AMOUNT,
            CSL_TRANS_TYPE,
            CSL_TRANS_DATE,
            CSL_CLOSING_BALANCE,
            CSL_TRANS_NARRRATION,
            CSL_INST_CODE,
            CSL_PAN_NO_ENCR,
             CSL_INS_DATE,   -- Added by DHIRAJ MG on 11/04/2012
         CSL_INS_USER,   -- Added by DHIRAJ MG on 11/04/2012
         CSL_ACCT_NO     --Added by DHIRAJ MG on 11/04/2012  to log the account number
          )
          VALUES
          ( --prm_card_no
            V_HASH_PAN,
            V_FEE_OPENING_BAL,
            V_TOTAL_FEE,
            'DR',
            V_TRAN_DATE,
            V_FEE_OPENING_BAL - V_TOTAL_FEE,
            'Fee debited for '
            || V_NARRATION,
            PRM_INST_CODE,
            V_ENCR_PAN,
             sysdate,           -- Added by DHIRAJ MG on 11/04/2012
        1,-- Added by DHIRAJ MG on 11/04/2012
        V_ACCT_NUMBER--Added by DHIRAJ MG on 11/04/2012  to log the account number
          );
        --v_fee_opening_bal  := v_fee_opening_bal - i.fee_amt;
      EXCEPTION
      WHEN OTHERS THEN
        V_RESP_CDE  := '21';
        PRM_ERR_MSG := 'Problem while inserting into statement log for tran fee ' || SUBSTR
        (
          SQLERRM, 1, 200
        )
        ;
        RAISE EXP_REJECT_RECORD;
      END;
    END IF;
    --END LOOP;
    --En create entries for FEES attached
    --Sn create a entry for successful
    BEGIN
      INSERT
      INTO CMS_TRANSACTION_LOG_DTL
        (
          CTD_DELIVERY_CHANNEL,
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
          CTD_CUST_ACCT_NUMBER
        )
        VALUES
        (
          PRM_DELIVERY_CHANNEL,
          PRM_TXN_CODE,
          V_TXN_TYPE,
          PRM_MSG,
          PRM_TXN_MODE,
          PRM_TRAN_DATE,
          PRM_TRAN_TIME,
          -- prm_card_no
          V_HASH_PAN,
          PRM_TXN_AMT,
          PRM_CURR_CODE,
          V_TRAN_AMT,
          V_LOG_ACTUAL_FEE,
          V_LOG_WAIVER_AMT,
          V_SERVICETAX_AMOUNT,
          V_CESS_AMOUNT,
          V_TOTAL_AMT,
          V_CARD_CURR,
          'Y',
          'Successful',
          PRM_RRN,
          PRM_STAN,
          PRM_INST_CODE,
          V_ENCR_PAN,
          V_ACCT_NUMBER
        );
      --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
    EXCEPTION
    WHEN OTHERS THEN
      PRM_ERR_MSG := 'Problem while selecting data from response master ' || SUBSTR
      (
        SQLERRM, 1, 300
      )
      ;
      V_RESP_CDE := '21';
      RAISE EXP_REJECT_RECORD;
    END;
    --En create a entry for successful
    ---Sn update daily and weekly transcounter  and amount
    BEGIN
      SELECT CAT_PAN_CODE
      INTO V_AVAIL_PAN
      FROM CMS_AVAIL_TRANS
      WHERE CAT_PAN_CODE = V_HASH_PAN --prm_card_no
      AND CAT_TRAN_CODE  = PRM_TXN_CODE
      AND CAT_TRAN_MODE  = PRM_TXN_MODE;
      UPDATE CMS_AVAIL_TRANS
      SET CAT_MAXDAILY_TRANCNT = DECODE(CAT_MAXDAILY_TRANCNT, 0, CAT_MAXDAILY_TRANCNT, CAT_MAXDAILY_TRANCNT   - 1),
        CAT_MAXDAILY_TRANAMT   = DECODE(V_DR_CR_FLAG, 'DR', CAT_MAXDAILY_TRANAMT                              - V_TRAN_AMT, CAT_MAXDAILY_TRANAMT),
        CAT_MAXWEEKLY_TRANCNT  = DECODE(CAT_MAXWEEKLY_TRANCNT, 0, CAT_MAXWEEKLY_TRANCNT, CAT_MAXDAILY_TRANCNT - 1),
        CAT_MAXWEEKLY_TRANAMT  = DECODE(V_DR_CR_FLAG, 'DR', CAT_MAXWEEKLY_TRANAMT                             - V_TRAN_AMT, CAT_MAXWEEKLY_TRANAMT)
      WHERE CAT_INST_CODE      = PRM_INST_CODE
      AND CAT_PAN_CODE         = V_HASH_PAN --prm_card_no
      AND CAT_TRAN_CODE        = PRM_TXN_CODE
      AND CAT_TRAN_MODE        = PRM_TXN_MODE;
      IF SQL%ROWCOUNT          = 0 THEN
        PRM_ERR_MSG           := 'Problem while updating data in avail trans ' || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE            := '21';
        RAISE EXP_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      PRM_RESP_MSG := PRM_ERR_MSG;
      RAISE;
    WHEN NO_DATA_FOUND THEN
      NULL;
    WHEN OTHERS THEN
      PRM_ERR_MSG := 'Problem while selecting data from avail trans ' || SUBSTR(SQLERRM, 1, 300);
      V_RESP_CDE  := '21';
      RAISE EXP_REJECT_RECORD;
    END;
    --En update daily and weekly transaction counter and amount
    --Sn create detail for response message
    -- added for mini statement
    -- added for mini statement
    --En create detail fro response message
    --Sn mini statement
    BEGIN
      --Add for PreAuth Transaction of CMSAuth;
      --Sn creating entries for preauth txn
      --if incoming message not contains checking for prod preauth expiry period
      --if preauth expiry period is not configured checking for instution expirty period
      BEGIN
        IF PRM_TXN_CODE = '11' AND PRM_MSG = '0100' THEN
          IF NULL      IS NULL THEN
            SELECT CPM_PRE_AUTH_EXP_DATE
            INTO V_PREAUTH_EXP_PERIOD
            FROM CMS_PROD_MAST
            WHERE CPM_PROD_CODE      = V_PROD_CODE;
            IF V_PREAUTH_EXP_PERIOD IS NULL THEN
              SELECT CIP_PARAM_VALUE
              INTO V_PREAUTH_EXP_PERIOD
              FROM CMS_INST_PARAM
              WHERE CIP_INST_CODE = PRM_INST_CODE
              AND CIP_PARAM_KEY   = 'PRE-AUTH EXP PERIOD';

              V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
              V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
            ELSE
              V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
              V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
            END IF;
          ELSE
            --    V_PREAUTH_HOLD   := SUBSTR(TRIM(PRM_PREAUTH_EXPPERIOD), 1, 1);
            --    V_PREAUTH_PERIOD := SUBSTR(TRIM(PRM_PREAUTH_EXPPERIOD), 2, 2);
            IF V_PREAUTH_PERIOD = '00' THEN
              --test
              SELECT CPM_PRE_AUTH_EXP_DATE
              INTO V_PREAUTH_EXP_PERIOD
              FROM CMS_PROD_MAST
              WHERE CPM_PROD_CODE      = V_PROD_CODE;
              IF V_PREAUTH_EXP_PERIOD IS NULL THEN
                SELECT CIP_PARAM_VALUE
                INTO V_PREAUTH_EXP_PERIOD
                FROM CMS_INST_PARAM
                WHERE CIP_INST_CODE = PRM_INST_CODE
                AND CIP_PARAM_KEY   = 'PRE-AUTH EXP PERIOD';

                V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
                V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
              ELSE
                V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
                V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
              END IF;
            ELSE
              V_PREAUTH_HOLD   := V_PREAUTH_HOLD;
              V_PREAUTH_PERIOD := V_PREAUTH_PERIOD;
            END IF; --end
          END IF;
          /*
          preauth period will be added with transaction date based on preauth_hold
          IF v_preauth_hold is '0'--'Minute'
          '1'--'Hour'
          '2'--'Day'
          */
          IF V_PREAUTH_HOLD = '0' THEN
            V_PREAUTH_DATE := V_TRAN_DATE + (V_PREAUTH_PERIOD * (1 / 1440));
          END IF;
          IF V_PREAUTH_HOLD = '1' THEN
            V_PREAUTH_DATE := V_TRAN_DATE + (V_PREAUTH_PERIOD * (1 / 24));
          END IF;
          IF V_PREAUTH_HOLD = '2' THEN
            V_PREAUTH_DATE := V_TRAN_DATE + V_PREAUTH_PERIOD;
          END IF;
          --This procedure is not used for preauth txn
          /*
          BEGIN
          insert into cms_preauth_transaction
          (cpt_card_no,CPT_TXN_AMNT,cpt_expiry_date,
          cpt_sequence_no,cpt_preauth_validflag,cpt_inst_code,cpt_mbr_no,CPT_CARD_NO_ENCR,CPT_COMPLETION_FLAG,CPT_APPROVE_AMT,CPT_RRN,CPT_TXN_DATE,CPT_TXN_TIME,CPT_TERMINALID,CPT_EXPIRY_FLAG)
          values(--prm_card_no
          v_hash_pan,v_total_amt,v_preauth_date,prm_preauth_seqno,'Y',prm_inst_code,prm_mbr_numb,v_encr_pan,'I',v_total_amt,prm_preauth_seqno,prm_tran_date,prm_tran_time,prm_term_id,'N');
          EXCEPTION
          WHEN OTHERS
          THEN
          v_resp_cde := '21';                            -- Server Declione
          PRM_ERR_MSG :=
          'Problem while inserting preauth transaction details' || SUBSTR (SQLERRM, 1, 300);
          RAISE exp_reject_record;
          END;*/
          --End This procedure is not used for preauth txn
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        V_RESP_CDE  := '21'; -- Server Declione
        PRM_ERR_MSG := 'Problem while inserting preauth transaction details' || SUBSTR(SQLERRM, 1, 300);
        RAISE EXP_REJECT_RECORD;
      END;
      IF V_RESP_CDE = '1' THEN
        --SAVEPOINT v_savepoint;
        --Sn find business date
        --  v_business_date
        -- v_cutoff_time
        V_BUSINESS_TIME   := TO_CHAR(V_TRAN_DATE, 'HH24:MI');
        IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
          V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
        ELSE
          V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
        END IF;
        PRM_RESP_MSG := NEW_CARD_NO;
        --En find businesses date
        BEGIN
          SP_CREATE_GL_ENTRIES_CMSAUTH(PRM_INST_CODE, V_BUSINESS_DATE, V_PROD_CODE, V_PROD_CATTYPE, V_TRAN_AMT, V_FUNC_CODE, PRM_TXN_CODE, V_DR_CR_FLAG, PRM_CARD_NO, V_FEE_CODE, V_TOTAL_FEE, V_FEE_CRACCT_NO, V_FEE_DRACCT_NO, V_CARD_ACCT_NO, PRM_RVSL_CODE, PRM_MSG, PRM_DELIVERY_CHANNEL, V_RESP_CDE, V_GL_UPD_FLAG, V_GL_ERR_MSG);
          IF V_GL_ERR_MSG <> 'OK' OR V_GL_UPD_FLAG <> 'Y' THEN
            -- ROLLBACK TO v_savepoint;
            V_GL_UPD_FLAG := 'N';
            PRM_RESP_CODE := V_RESP_CDE;
            -- prm_resp_msg := v_gl_err_msg;
            PRM_ERR_MSG := V_GL_ERR_MSG;
            RAISE EXP_REJECT_RECORD;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          -- ROLLBACK TO v_savepoint;
          V_GL_UPD_FLAG := 'N';
          PRM_RESP_CODE := V_RESP_CDE;
          -- prm_resp_msg := v_gl_err_msg;
          PRM_ERR_MSG := V_GL_ERR_MSG;
          RAISE EXP_REJECT_RECORD;
        END;
        --Sn find prod code and card type and available balance for the card number
        BEGIN
          SELECT CAM_ACCT_BAL
          INTO V_ACCT_BALANCE
          FROM CMS_ACCT_MAST
          WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN --prm_card_no
            AND CAP_MBR_NUMB   = PRM_MBR_NUMB
            AND CAP_INST_CODE  = PRM_INST_CODE
            )
          AND CAM_INST_CODE = PRM_INST_CODE FOR UPDATE NOWAIT;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_RESP_CDE  := '14'; --Ineligible Transaction
          PRM_ERR_MSG := 'Invalid Card ';
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          V_RESP_CDE  := '12';
          PRM_ERR_MSG := 'Error while selecting data from card Master for card number ' || SQLERRM;
          RAISE EXP_REJECT_RECORD;
        END;
        --En find prod code and card type for the card number
        IF V_OUTPUT_TYPE = 'N' THEN
          NULL;
        END IF;
      END IF;
      --En create GL ENTRIES
      --Sn create a record in pan spprt
      --Sn Selecting Reason code for Initial Load
      BEGIN
        SELECT CSR_SPPRT_RSNCODE
        INTO V_RESONCODE
        FROM CMS_SPPRT_REASONS
        WHERE CSR_INST_CODE = PRM_INST_CODE
        AND CSR_SPPRT_KEY   = 'REISSUE'
        AND ROWNUM          < 2;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_RESP_CDE  := '21';
        PRM_ERR_MSG := 'Order Replacement card reason code is present in master';
        RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
        V_RESP_CDE  := '21';
        PRM_ERR_MSG := 'Error while selecting reason code from master' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
      END;
      BEGIN
        INSERT
        INTO CMS_PAN_SPPRT
          (
            CPS_INST_CODE,
            CPS_PAN_CODE,
            CPS_MBR_NUMB,
            CPS_PROD_CATG,
            CPS_SPPRT_KEY,
            CPS_SPPRT_RSNCODE,
            CPS_FUNC_REMARK,
            CPS_INS_USER,
            CPS_LUPD_USER,
            CPS_CMD_MODE,
            CPS_PAN_CODE_ENCR
          )
          VALUES
          (
            PRM_INST_CODE, --prm_acctno
            V_HASH_PAN,
            PRM_MBR_NUMB,
            V_CAP_PROD_CATG,
            'REISSUE',
            V_RESONCODE,
            PRM_REMRK,
            PRM_BANK_CODE,
            PRM_BANK_CODE,
            0,
            V_ENCR_PAN
          );
      EXCEPTION
      WHEN OTHERS THEN
        V_RESP_CDE  := '21';
        PRM_ERR_MSG := 'Error while inserting records into card support master' || SUBSTR
        (
          SQLERRM, 1, 200
        )
        ;
        RAISE EXP_REJECT_RECORD;
      END;
      --En create a record in pan spprt
      ---Sn Updation of Usage limit and amount
      BEGIN
        SELECT CTC_ATMUSAGE_AMT,
          CTC_POSUSAGE_AMT,
          CTC_ATMUSAGE_LIMIT,
          CTC_POSUSAGE_LIMIT,
          CTC_BUSINESS_DATE,
          CTC_PREAUTHUSAGE_LIMIT,
          CTC_MMPOSUSAGE_AMT,
          CTC_MMPOSUSAGE_LIMIT
        INTO V_ATM_USAGEAMNT,
          V_POS_USAGEAMNT,
          V_ATM_USAGELIMIT,
          V_POS_USAGELIMIT,
          V_BUSINESS_DATE_TRAN,
          V_PREAUTH_USAGE_LIMIT,
          V_MMPOS_USAGEAMNT,
          V_MMPOS_USAGELIMIT
        FROM CMS_TRANSLIMIT_CHECK
        WHERE CTC_INST_CODE = PRM_INST_CODE
        AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
        AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        PRM_ERR_MSG := 'Cannot get the Transaction Limit Details of the Card' || V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE  := '21';
        RAISE EXP_REJECT_RECORD;
      END;
      BEGIN
        IF PRM_DELIVERY_CHANNEL = '01' THEN
          IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
            IF PRM_TXN_AMT     IS NULL THEN
              V_ATM_USAGEAMNT  := TRIM(TO_CHAR(0, '99999999999999999.99'));
            ELSE
              V_ATM_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99'));
            END IF;
            V_ATM_USAGELIMIT := 1;
            UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_ATMUSAGE_AMT     = V_ATM_USAGEAMNT,
              CTC_ATMUSAGE_LIMIT     = V_ATM_USAGELIMIT,
              CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_BUSINESS_DATE      = TO_DATE(PRM_TRAN_DATE
              || '23:59:59', 'yymmdd'
              || 'hh24:mi:ss'),
              CTC_MMPOSUSAGE_AMT   = 0,
              CTC_MMPOSUSAGE_LIMIT = 0
            WHERE CTC_INST_CODE    = PRM_INST_CODE
            AND CTC_PAN_CODE       = V_HASH_PAN --prm_card_no
            AND CTC_MBR_NUMB       = PRM_MBR_NUMB;
          ELSE
            IF PRM_TXN_AMT    IS NULL THEN
              V_ATM_USAGEAMNT := V_ATM_USAGEAMNT + TRIM(TO_CHAR(0, '99999999999999999.99'));
            ELSE
              V_ATM_USAGEAMNT := V_ATM_USAGEAMNT + TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99'));
            END IF;
            V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;
            UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_ATMUSAGE_AMT = V_ATM_USAGEAMNT,
              CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
              --ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
            WHERE CTC_INST_CODE = PRM_INST_CODE
            AND CTC_PAN_CODE    = V_HASH_PAN -- prm_card_no
            AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
          END IF;
        END IF;
        IF PRM_DELIVERY_CHANNEL = '02' THEN
          IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
            IF PRM_TXN_AMT     IS NULL THEN
              V_POS_USAGEAMNT  := TRIM(TO_CHAR(0, '99999999999999999.99'));
            ELSE
              V_POS_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99'));
            END IF;
            V_POS_USAGELIMIT        := 1;
            IF PRM_TXN_CODE          = '11' AND PRM_MSG = '0100' THEN
              V_PREAUTH_USAGE_LIMIT := 1;
              V_POS_USAGEAMNT       := 0;
            ELSE
              V_PREAUTH_USAGE_LIMIT := 0;
            END IF;
            UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_POSUSAGE_AMT = V_POS_USAGEAMNT,
              CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
              CTC_ATMUSAGE_AMT   = 0,
              CTC_ATMUSAGE_LIMIT = 0,
              CTC_BUSINESS_DATE  = TO_DATE(PRM_TRAN_DATE
              || '23:59:59', 'yymmdd'
              || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
            WHERE CTC_INST_CODE      = PRM_INST_CODE
            AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
            AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
          ELSE
            V_POS_USAGELIMIT        := V_POS_USAGELIMIT + 1;
            IF PRM_TXN_CODE          = '11' AND PRM_MSG = '0100' THEN
              V_PREAUTH_USAGE_LIMIT := V_PREAUTH_USAGE_LIMIT + 1;
              V_POS_USAGEAMNT       := V_POS_USAGEAMNT;
            ELSE
              IF PRM_TXN_AMT    IS NULL THEN
                V_POS_USAGEAMNT := V_POS_USAGEAMNT + TRIM(TO_CHAR(0, '99999999999999999.99'));
              ELSE
                IF V_DR_CR_FLAG    = 'CR' THEN
                  V_POS_USAGEAMNT := V_POS_USAGEAMNT;
                ELSE
                  V_POS_USAGEAMNT := V_POS_USAGEAMNT + TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99'));
                END IF;
              END IF;
            END IF;
            UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_POSUSAGE_AMT = V_POS_USAGEAMNT,
              CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
              -- ctc_business_date =TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
            WHERE CTC_INST_CODE      = PRM_INST_CODE
            AND CTC_PAN_CODE         = V_HASH_PAN --prm_card_no
            AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
          END IF;
        END IF;
        --Sn Usage limit and amount updation for MMPOS
        IF PRM_DELIVERY_CHANNEL  = '04' THEN
          IF V_TRAN_DATE         > V_BUSINESS_DATE_TRAN THEN
            IF PRM_TXN_AMT      IS NULL THEN
              V_MMPOS_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999999.99'));
            ELSE
              V_MMPOS_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99'));
            END IF;
            V_MMPOS_USAGELIMIT := 1;
            UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_MMPOSUSAGE_AMT = V_MMPOS_USAGEAMNT,
              CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
              CTC_ATMUSAGE_AMT     = 0,
              CTC_ATMUSAGE_LIMIT   = 0,
              CTC_BUSINESS_DATE    = TO_DATE(PRM_TRAN_DATE
              || '23:59:59', 'yymmdd'
              || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0
            WHERE CTC_INST_CODE      = PRM_INST_CODE
            AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
            AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
          ELSE
            V_MMPOS_USAGELIMIT  := V_MMPOS_USAGELIMIT + 1;
            IF PRM_TXN_AMT      IS NULL THEN
              V_MMPOS_USAGEAMNT := V_MMPOS_USAGEAMNT + TRIM(TO_CHAR(0, 999999999999999));
            ELSE
              V_MMPOS_USAGEAMNT := V_MMPOS_USAGEAMNT + TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99'));
            END IF;
            UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_MMPOSUSAGE_AMT = V_MMPOS_USAGEAMNT,
              CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
            WHERE CTC_INST_CODE    = PRM_INST_CODE
            AND CTC_PAN_CODE       = V_HASH_PAN --prm_card_no
            AND CTC_MBR_NUMB       = PRM_MBR_NUMB;
          END IF;
        END IF;
        --En Usage limit and amount updation for MMPOS
      END;
    END;
    ---En Updation of Usage limit and amount
    BEGIN
      SELECT CMS_ISO_RESPCDE
      INTO PRM_RESP_CODE
      FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE      = PRM_INST_CODE
      AND CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL
      AND CMS_RESPONSE_ID      = TO_NUMBER(V_RESP_CDE);
    EXCEPTION
    WHEN OTHERS THEN
      PRM_ERR_MSG := 'Problem while selecting data from response master for respose code' || V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
      V_RESP_CDE  := '21';
      RAISE EXP_REJECT_RECORD;
    END;
    ---
  EXCEPTION
    --<< MAIN EXCEPTION >>
  WHEN EXP_REJECT_RECORD THEN
    PRM_RESP_MSG := PRM_ERR_MSG;
    ROLLBACK TO V_AUTH_SAVEPOINT;
    BEGIN
      SELECT CTC_ATMUSAGE_LIMIT,
        CTC_POSUSAGE_LIMIT,
        CTC_BUSINESS_DATE,
        CTC_PREAUTHUSAGE_LIMIT,
        CTC_MMPOSUSAGE_LIMIT
      INTO V_ATM_USAGELIMIT,
        V_POS_USAGELIMIT,
        V_BUSINESS_DATE_TRAN,
        V_PREAUTH_USAGE_LIMIT,
        V_MMPOS_USAGELIMIT
      FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = PRM_INST_CODE
      AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
      AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PRM_ERR_MSG := 'Cannot get the Transaction Limit Details of the Card' || V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
      V_RESP_CDE  := '21';
      RAISE EXP_REJECT_RECORD;
    END;
    BEGIN
      IF PRM_DELIVERY_CHANNEL = '01' THEN
        IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
          V_ATM_USAGEAMNT    := 0;
          V_ATM_USAGELIMIT   := 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_ATMUSAGE_AMT     = V_ATM_USAGEAMNT,
            CTC_ATMUSAGE_LIMIT     = V_ATM_USAGELIMIT,
            CTC_POSUSAGE_AMT       = 0,
            CTC_POSUSAGE_LIMIT     = 0,
            CTC_PREAUTHUSAGE_LIMIT = 0,
            CTC_MMPOSUSAGE_AMT     = 0,
            CTC_MMPOSUSAGE_LIMIT   = 0,
            CTC_BUSINESS_DATE      = TO_DATE(PRM_TRAN_DATE
            || '23:59:59', 'yymmdd'
            || 'hh24:mi:ss')
          WHERE CTC_INST_CODE = PRM_INST_CODE
          AND CTC_PAN_CODE    = V_HASH_PAN ---prm_card_no
          AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
        ELSE
          V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
            --ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
          WHERE CTC_INST_CODE = PRM_INST_CODE
          AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
          AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
        END IF;
      END IF;
      IF PRM_DELIVERY_CHANNEL    = '02' THEN
        IF V_TRAN_DATE           > V_BUSINESS_DATE_TRAN THEN
          V_POS_USAGEAMNT       := 0;
          V_POS_USAGELIMIT      := 1;
          V_PREAUTH_USAGE_LIMIT := 0;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_POSUSAGE_AMT   = V_POS_USAGEAMNT,
            CTC_POSUSAGE_LIMIT   = V_POS_USAGELIMIT,
            CTC_ATMUSAGE_AMT     = 0,
            CTC_ATMUSAGE_LIMIT   = 0,
            CTC_MMPOSUSAGE_AMT   = 0,
            CTC_MMPOSUSAGE_LIMIT = 0,
            CTC_BUSINESS_DATE    = TO_DATE(PRM_TRAN_DATE
            || '23:59:59', 'yymmdd'
            || 'hh24:mi:ss'),
            CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
          WHERE CTC_INST_CODE      = PRM_INST_CODE
          AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
          AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
            --  ctc_business_date =TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
          WHERE CTC_INST_CODE = PRM_INST_CODE
          AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
          AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
        END IF;
      END IF;
      --Sn Usage limit updation for MMPOS
      IF PRM_DELIVERY_CHANNEL = '04' THEN
        IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
          V_MMPOS_USAGEAMNT  := 0;
          V_MMPOS_USAGELIMIT := 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_POSUSAGE_AMT   = 0,
            CTC_POSUSAGE_LIMIT   = 0,
            CTC_ATMUSAGE_AMT     = 0,
            CTC_ATMUSAGE_LIMIT   = 0,
            CTC_MMPOSUSAGE_AMT   = V_MMPOS_USAGEAMNT,
            CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
            CTC_BUSINESS_DATE    = TO_DATE(PRM_TRAN_DATE
            || '23:59:59', 'yymmdd'
            || 'hh24:mi:ss'),
            CTC_PREAUTHUSAGE_LIMIT = 0
          WHERE CTC_INST_CODE      = PRM_INST_CODE
          AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
          AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
        ELSE
          V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
            --  ctc_business_date =TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
          WHERE CTC_INST_CODE = PRM_INST_CODE
          AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
          AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
        END IF;
      END IF;
      --En Usage limit updation for MMPOS
    END;
    --Sn select response code and insert record into txn log dtl
    BEGIN
      PRM_RESP_CODE := V_RESP_CDE;
      PRM_RESP_MSG  := PRM_ERR_MSG;
      -- Assign the response code to the out parameter
      SELECT CMS_ISO_RESPCDE
      INTO PRM_RESP_CODE
      FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE      = PRM_INST_CODE
      AND CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL
      AND CMS_RESPONSE_ID      = V_RESP_CDE;
    EXCEPTION
    WHEN OTHERS THEN
      PRM_RESP_MSG  := 'Problem while selecting data from response master ' || V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
      PRM_RESP_CODE := '69';
      ---ISO MESSAGE FOR DATABASE ERROR Server Declined
      ROLLBACK;
      -- RETURN;
    END;
    BEGIN
      IF V_RRN_COUNT                       > 0 THEN
        IF TO_NUMBER(PRM_DELIVERY_CHANNEL) = 8 THEN
          BEGIN
            SELECT RESPONSE_CODE
            INTO V_RESP_CDE
            FROM TRANSACTIONLOG A,
              (SELECT MIN(ADD_INS_DATE) MINDATE FROM TRANSACTIONLOG WHERE RRN = PRM_RRN
              ) B
            WHERE A.ADD_INS_DATE = MINDATE
            AND RRN              = PRM_RRN;

            PRM_RESP_CODE := V_RESP_CDE;
            SELECT CAM_ACCT_BAL
            INTO V_ACCT_BALANCE
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
              (SELECT CAP_ACCT_NO
              FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN --prm_card_no
              AND CAP_MBR_NUMB   = PRM_MBR_NUMB
              AND CAP_INST_CODE  = PRM_INST_CODE
              )
            AND CAM_INST_CODE = PRM_INST_CODE FOR UPDATE NOWAIT;

            PRM_ERR_MSG := TO_CHAR(V_ACCT_BALANCE);
          EXCEPTION
          WHEN OTHERS THEN
            PRM_ERR_MSG   := 'Problem in selecting the response detail of Original transaction' || SUBSTR(SQLERRM, 1, 300);
            PRM_RESP_CODE := '89'; -- Server Declined
            ROLLBACK;
            RETURN;
          END;
        END IF;
      END IF;
    END;
    BEGIN
      INSERT
      INTO CMS_TRANSACTION_LOG_DTL
        (
          CTD_DELIVERY_CHANNEL,
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
          CTD_CUST_ACCT_NUMBER
        )
        VALUES
        (
          PRM_DELIVERY_CHANNEL,
          PRM_TXN_CODE,
          V_TXN_TYPE,
          PRM_MSG,
          PRM_TXN_MODE,
          PRM_TRAN_DATE,
          PRM_TRAN_TIME,
          --prm_card_no
          V_HASH_PAN,
          PRM_TXN_AMT,
          PRM_CURR_CODE,
          V_TRAN_AMT,
          NULL,
          NULL,
          NULL,
          NULL,
          V_TOTAL_AMT,
          V_CARD_CURR,
          'E',
          PRM_ERR_MSG,
          PRM_RRN,
          PRM_STAN,
          PRM_INST_CODE,
          V_ENCR_PAN,
          V_ACCT_NUMBER
        );

      PRM_RESP_MSG := PRM_ERR_MSG;
    EXCEPTION
    WHEN OTHERS THEN
      PRM_RESP_MSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
      (
        SQLERRM, 1, 300
      )
      ;
      PRM_RESP_CODE := '69'; -- Server Declined
      ROLLBACK;
      RETURN;
    END;
  WHEN OTHERS THEN
    ROLLBACK TO V_AUTH_SAVEPOINT;
    BEGIN
      SELECT CTC_ATMUSAGE_LIMIT,
        CTC_POSUSAGE_LIMIT,
        CTC_BUSINESS_DATE,
        CTC_PREAUTHUSAGE_LIMIT,
        CTC_MMPOSUSAGE_LIMIT
      INTO V_ATM_USAGELIMIT,
        V_POS_USAGELIMIT,
        V_BUSINESS_DATE_TRAN,
        V_PREAUTH_USAGE_LIMIT,
        V_MMPOS_USAGELIMIT
      FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = PRM_INST_CODE
      AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
      AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PRM_ERR_MSG := 'Cannot get the Transaction Limit Details of the Card' || V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
      V_RESP_CDE  := '21';
      RAISE EXP_REJECT_RECORD;
    END;
    BEGIN
      IF PRM_DELIVERY_CHANNEL = '01' THEN
        IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
          V_ATM_USAGEAMNT    := 0;
          V_ATM_USAGELIMIT   := 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_ATMUSAGE_AMT     = V_ATM_USAGEAMNT,
            CTC_ATMUSAGE_LIMIT     = V_ATM_USAGELIMIT,
            CTC_POSUSAGE_AMT       = 0,
            CTC_POSUSAGE_LIMIT     = 0,
            CTC_PREAUTHUSAGE_LIMIT = 0,
            CTC_MMPOSUSAGE_AMT     = 0,
            CTC_MMPOSUSAGE_LIMIT   = 0,
            CTC_BUSINESS_DATE      = TO_DATE(PRM_TRAN_DATE
            || '23:59:59', 'yymmdd'
            || 'hh24:mi:ss')
          WHERE CTC_INST_CODE = PRM_INST_CODE
          AND CTC_PAN_CODE    = V_HASH_PAN ---prm_card_no
          AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
        ELSE
          V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
            --ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
          WHERE CTC_INST_CODE = PRM_INST_CODE
          AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
          AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
        END IF;
      END IF;
      IF PRM_DELIVERY_CHANNEL    = '02' THEN
        IF V_TRAN_DATE           > V_BUSINESS_DATE_TRAN THEN
          V_POS_USAGEAMNT       := 0;
          V_POS_USAGELIMIT      := 1;
          V_PREAUTH_USAGE_LIMIT := 0;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_POSUSAGE_AMT   = V_POS_USAGEAMNT,
            CTC_POSUSAGE_LIMIT   = V_POS_USAGELIMIT,
            CTC_ATMUSAGE_AMT     = 0,
            CTC_ATMUSAGE_LIMIT   = 0,
            CTC_MMPOSUSAGE_AMT   = 0,
            CTC_MMPOSUSAGE_LIMIT = 0,
            CTC_BUSINESS_DATE    = TO_DATE(PRM_TRAN_DATE
            || '23:59:59', 'yymmdd'
            || 'hh24:mi:ss'),
            CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
          WHERE CTC_INST_CODE      = PRM_INST_CODE
          AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
          AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
            --  ctc_business_date =TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
          WHERE CTC_INST_CODE = PRM_INST_CODE
          AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
          AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
        END IF;
      END IF;
      --Sn Usage limit updation for MMPOS
      IF PRM_DELIVERY_CHANNEL = '04' THEN
        IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
          V_MMPOS_USAGEAMNT  := 0;
          V_MMPOS_USAGELIMIT := 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_POSUSAGE_AMT   = 0,
            CTC_POSUSAGE_LIMIT   = 0,
            CTC_ATMUSAGE_AMT     = 0,
            CTC_ATMUSAGE_LIMIT   = 0,
            CTC_MMPOSUSAGE_AMT   = V_MMPOS_USAGEAMNT,
            CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
            CTC_BUSINESS_DATE    = TO_DATE(PRM_TRAN_DATE
            || '23:59:59', 'yymmdd'
            || 'hh24:mi:ss'),
            CTC_PREAUTHUSAGE_LIMIT = 0
          WHERE CTC_INST_CODE      = PRM_INST_CODE
          AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
          AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
            --  ctc_business_date =TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
          WHERE CTC_INST_CODE = PRM_INST_CODE
          AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
          AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
        END IF;
      END IF;
      --En Usage limit updation for MMPOS
    END;
    --Sn select response code and insert record into txn log dtl
    BEGIN
      SELECT CMS_ISO_RESPCDE
      INTO PRM_RESP_CODE
      FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE      = PRM_INST_CODE
      AND CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL
      AND CMS_RESPONSE_ID      = V_RESP_CDE;

      PRM_RESP_MSG := PRM_ERR_MSG;
    EXCEPTION
    WHEN OTHERS THEN
      PRM_RESP_MSG  := 'Problem while selecting data from response master ' || V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
      PRM_RESP_CODE := '69'; -- Server Declined
      ROLLBACK;
      -- RETURN;
    END;
    BEGIN
      INSERT
      INTO CMS_TRANSACTION_LOG_DTL
        (
          CTD_DELIVERY_CHANNEL,
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
          CTD_CUST_ACCT_NUMBER
        )
        VALUES
        (
          PRM_DELIVERY_CHANNEL,
          PRM_TXN_CODE,
          V_TXN_TYPE,
          PRM_MSG,
          PRM_TXN_MODE,
          PRM_TRAN_DATE,
          PRM_TRAN_TIME,
          --prm_card_no
          V_HASH_PAN,
          PRM_TXN_AMT,
          PRM_CURR_CODE,
          V_TRAN_AMT,
          NULL,
          NULL,
          NULL,
          NULL,
          V_TOTAL_AMT,
          V_CARD_CURR,
          'E',
          PRM_ERR_MSG,
          PRM_RRN,
          PRM_STAN,
          PRM_INST_CODE,
          V_ENCR_PAN,
          V_ACCT_NUMBER
        );
    EXCEPTION
    WHEN OTHERS THEN
      PRM_RESP_MSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
      (
        SQLERRM, 1, 300
      )
      ;
      PRM_RESP_CODE := '69'; -- Server Decline Response 220509
      ROLLBACK;
      RETURN;
    END;
    --En select response code and insert record into txn log dtl
  END;
  --- Sn create GL ENTRIES
  --Sn generate auth id
  BEGIN
    SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
  EXCEPTION
  WHEN OTHERS THEN
    PRM_RESP_MSG  := 'Error while generating authid ' || SUBSTR(SQLERRM, 1, 300);
    PRM_RESP_CODE := '69'; -- Server Declined
    ROLLBACK;
    -- RETURN;
  END;
  --En generate auth id
  --Sn create a entry in txn log
  BEGIN
    INSERT
    INTO TRANSACTIONLOG
      (
        MSGTYPE,
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
        ADDCHARGE,
        PRODUCTID,
        CATEGORYID,
        --TXN_FEE,
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
        -- FEEATTACHTYPE,
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
        CUSTOMER_CARD_NO_ENCR,
        TOPUP_CARD_NO_ENCR,
        --TXN_AMOUNT,
        PROXY_NUMBER,
        REVERSAL_CODE,
        CUSTOMER_ACCT_NO,
        ACCT_BALANCE,
        LEDGER_BALANCE
      )
      VALUES
      (
        PRM_MSG,
        PRM_RRN,
        PRM_DELIVERY_CHANNEL,
        PRM_TERM_ID,
        V_BUSINESS_DATE,
        PRM_TXN_CODE,
        V_TXN_TYPE,
        PRM_TXN_MODE,
        DECODE(PRM_RESP_CODE, '00', 'C', 'F'),
        PRM_RESP_CODE,
        PRM_TRAN_DATE,
        SUBSTR(PRM_TRAN_TIME, 1, 10),
        --prm_card_no
        V_HASH_PAN,
        NULL,
        --prm_topup_cardno,
        NULL, --prm_topup_acctno    ,
        NULL, --prm_topup_accttype,
        PRM_BANK_CODE,
        TRIM(TO_CHAR(V_TOTAL_AMT, '99999999999999999.99')),
        '',
        '',
        PRM_MCC_CODE,
        PRM_CURR_CODE,
        NULL, -- prm_add_charge,
        V_PROD_CODE,
        V_PROD_CATTYPE,
        --V_TOTAL_FEE,
        '',
        '',
        '',
        V_AUTH_ID,
        V_NARRATION,
        TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99')),
        NULL,
        --- PRE AUTH AMOUNT
        NULL, -- Partial amount (will be given for partial txn)
        '',
        '',
        '',
        '',
        '',
        V_GL_UPD_FLAG,
        PRM_STAN,
        PRM_INST_CODE,
        V_FEE_CODE,
        -- v_fee_attach_type,
        V_FEE_AMT,
        V_SERVICETAX_AMOUNT,
        V_CESS_AMOUNT,
        V_DR_CR_FLAG,
        V_FEE_CRACCT_NO,
        V_FEE_DRACCT_NO,
        V_ST_CALC_FLAG,
        V_CESS_CALC_FLAG,
        V_ST_CRACCT_NO,
        V_ST_DRACCT_NO,
        V_CESS_CRACCT_NO,
        V_CESS_DRACCT_NO,
        V_ENCR_PAN,
        NULL,
        --PRM_TXN_AMT,
        V_PROXUNUMBER,
        PRM_RVSL_CODE,
        V_ACCT_NUMBER,
        V_UPD_AMT,
        V_UPD_LEDGER_AMT
      );

    DBMS_OUTPUT.PUT_LINE
    (
      'AFTER INSERT IN TRANSACTIONLOG'
    )
    ;
    PRM_CAPTURE_DATE := V_BUSINESS_DATE;
    PRM_AUTH_ID      := V_AUTH_ID;
  EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    PRM_RESP_CODE := '69'; -- Server Declione
    PRM_RESP_MSG  := 'Problem while inserting data into transaction log  ' || SUBSTR
    (
      SQLERRM, 1, 300
    )
    ;
  END;
  --En create a entry in txn log
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  PRM_RESP_CODE := '69'; -- Server Declined
  PRM_RESP_MSG  := 'Main exception from  authorization ' || SUBSTR
  (
    SQLERRM, 1, 300
  )
  ;
END; --<< MAIN END >>
/


