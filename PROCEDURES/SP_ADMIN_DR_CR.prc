CREATE OR REPLACE PROCEDURE VMSCMS.SP_ADMIN_DR_CR(P_INST_CODE         IN NUMBER,
                                   P_MSG               IN VARCHAR2,
                                   P_RRN               VARCHAR2,
                                   P_DELIVERY_CHANNEL  VARCHAR2,
                                   P_TERM_ID           VARCHAR2,
                                   P_TXN_CODE          VARCHAR2,
                                   P_TXN_MODE          VARCHAR2,
                                   P_TRAN_DATE         VARCHAR2,
                                   P_TRAN_TIME         VARCHAR2,
                                   P_CARD_NO           VARCHAR2,
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
                                   P_MCCCODE_GROUPID   VARCHAR2,
                                   P_CURRCODE_GROUPID  VARCHAR2,
                                   P_TRANSCODE_GROUPID VARCHAR2,
                                   P_RULES             VARCHAR2,
                                   P_EXPRY_DATE        IN VARCHAR2,
                                   P_STAN              IN VARCHAR2,
                                   P_MBR_NUMB          IN VARCHAR2,
                                   P_RVSL_CODE         IN NUMBER,
                                   P_ADMINDRCR_IN      IN VARCHAR2,
                                   P_CONSODIUM_CODE    IN VARCHAR2,
                                   P_PARTNER_CODE      IN VARCHAR2,
                                   P_AUTH_ID           OUT VARCHAR2,
                                   P_RESP_CODE         OUT VARCHAR2,
                                   P_RESP_MSG          OUT VARCHAR2,
                                   P_CAPTURE_DATE      OUT DATE   --T.Narayanan Changed for Address Verification Indicator Changes.
                                   ) IS
/*************************************************
     * Modified By      :  Trivikram
     * Modified Date    :  20-Aug-2012
     * Modified Reason  : Added in Parameter for fee plan
      * Reviewer        : B.Besky Anand  
     * Reviewed Date    : 21-Aug-2012  
     * Build Number     :  CMS3.5.1_RI0015_B0001
 *************************************************/
  V_ERR_MSG          VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE     NUMBER;
  V_LEDGER_BAL       NUMBER;
  V_TRAN_AMT         NUMBER;
  V_AUTH_ID          VARCHAR2(6);
  V_TOTAL_AMT        NUMBER;
  V_TRAN_DATE        DATE;
  V_FUNC_CODE        CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_PROD_CODE        CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE     CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT          NUMBER;
  V_TOTAL_FEE        NUMBER;
  V_UPD_AMT          NUMBER;
  V_UPD_LEDGER_AMT   NUMBER;
  V_NARRATION        VARCHAR2(50);
  V_FEE_OPENING_BAL  NUMBER;
  V_RESP_CDE         VARCHAR2(3);
  V_EXPRY_DATE       DATE;
  V_DR_CR_FLAG       VARCHAR2(2);
  V_OUTPUT_TYPE      VARCHAR2(2);
  V_APPLPAN_CARDSTAT VARCHAR2(1);
  V_ATMONLINE_LIMIT  CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT  CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_PRECHECK_FLAG      NUMBER;
  V_PREAUTH_FLAG       NUMBER;
  V_GL_UPD_FLAG        TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_GL_ERR_MSG         VARCHAR2(500);
  V_SAVEPOINT          NUMBER := 0;
  V_TRAN_FEE           NUMBER;
  V_ERROR              VARCHAR2(500);
  V_BUSINESS_DATE_TRAN DATE;
  V_BUSINESS_TIME      VARCHAR2(5);
  V_CUTOFF_TIME        VARCHAR2(5);
  V_CARD_CURR          VARCHAR2(5);
  V_FEE_CODE           CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_CRGL_CATG      CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRGL_CODE      CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRSUBGL_CODE   CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO      CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG      CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE      CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE   CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO      CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  --st AND cess
  V_SERVICETAX_PERCENT CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CESS_PERCENT       CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_SERVICETAX_AMOUNT  NUMBER;
  V_CESS_AMOUNT        NUMBER;
  V_ST_CALC_FLAG       CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
  V_CESS_CALC_FLAG     CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
  V_ST_CRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
  V_ST_DRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
  V_CESS_CRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
  V_CESS_DRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
  --
  V_WAIV_PERCNT      CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  V_ERR_WAIV         VARCHAR2(300);
  V_LOG_ACTUAL_FEE   NUMBER;
  V_LOG_WAIVER_AMT   NUMBER;
  V_AUTH_SAVEPOINT   NUMBER DEFAULT 0;
  V_ACTUAL_EXPRYDATE DATE;
  V_BUSINESS_DATE    DATE;
  V_TXN_TYPE         NUMBER(1);
  V_MINI_TOTREC      NUMBER(2);
  V_MINISTMT_ERRMSG  VARCHAR2(500);
  V_MINISTMT_OUTPUT  VARCHAR2(900);
  EXP_REJECT_RECORD EXCEPTION;
  V_ATM_USAGEAMNT         CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT         CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  V_ATM_USAGELIMIT        CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT        CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_PREAUTH_USAGE_LIMIT   NUMBER;
  V_CARD_ACCT_NO          VARCHAR2(20);
  V_HOLD_AMOUNT           NUMBER;
  V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN              CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT             NUMBER;
  V_TRAN_TYPE             VARCHAR2(2);
  V_DATE                  DATE;
  V_TIME                  VARCHAR2(10);
  V_MAX_CARD_BAL          NUMBER;
  V_CURR_DATE             DATE;
  V_PREAUTH_EXP_PERIOD    VARCHAR2(10);
  V_PREAUTH_COUNT         NUMBER;
  V_TRANTYPE              VARCHAR2(2);
  V_ZIP_CODE              VARCHAR2(20);
  V_ACC_BAL               VARCHAR2(15);
  V_INTERNATIONAL_IND     CHARACTER(1);
  V_ADDRVRIFY_FLAG        CHARACTER(1);
   --Added by Deepa On June 19 2012 for Fees Changes
  V_FEEAMNT_TYPE          CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES              CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES             CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK              CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN              CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;  
 
V_FREETXN_EXCEED VARCHAR2(1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions 
V_DURATION VARCHAR2(20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions

  
BEGIN
   SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE   := '1';
  P_RESP_MSG := 'OK';

  BEGIN
    --SN CREATE HASH PAN
    BEGIN
     V_HASH_PAN := GETHASH(P_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --EN CREATE HASH PAN

    --SN create encr pan
    BEGIN
     V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --EN create encr pan

    --sN CHECK INST CODE
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

    BEGIN
     V_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '45'; -- Server Declined -220509
       V_ERR_MSG  := 'Problem while converting transaction date ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

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

    --En get date

    --Check for Duplicate rrn for Pre-Auth if pre-auth is expire or valid flag is N
    --checking for inccremental pre-auth

    --Sn Getting BIN Level Configuration details

    BEGIN

     SELECT CBL_INTERNATIONAL_CHECK, CBL_ADDR_VER_CHECK
       INTO V_INTERNATIONAL_IND, V_ADDRVRIFY_FLAG
       FROM CMS_BIN_LEVEL_CONFIG
      WHERE CBL_INST_BIN = SUBSTR(P_CARD_NO, 1, 6) AND
           CBL_INST_CODE = P_INST_CODE;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN

       V_INTERNATIONAL_IND := 'Y';
       V_ADDRVRIFY_FLAG    := 'Y';

     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while seelcting BIN level Configuration';
       RAISE EXP_REJECT_RECORD;

    END;

    --En Getting BIN Level Configuration details

    --Sn find service tax
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_SERVICETAX_PERCENT
       FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'SERVICETAX' AND CIP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Service Tax is  not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting service tax from system ';
       RAISE EXP_REJECT_RECORD;
    END;

    --En find service tax

    --Sn find cess
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_CESS_PERCENT
       FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'CESS' AND CIP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Cess is not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting cess from system ';
       RAISE EXP_REJECT_RECORD;
    END;

    --En find cess

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
       V_ERR_MSG     := 'Cutoff time is not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting cutoff  dtl  from system ';
       RAISE EXP_REJECT_RECORD;
    END;

    ---En find cutoff time

    --Sn find debit and credit flag
    BEGIN   
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;    
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '12'; --Ineligible Transaction
       V_ERR_MSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12'; --Ineligible Transaction
       V_ERR_MSG  := 'Error while selecting CMS_TRANSACTION_MAST  ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En find debit and credit flag

    --Sn find the tran amt
    IF ((V_TRAN_TYPE = 'F') OR (P_MSG = '0100')) THEN
     IF (P_TXN_AMT >= 0) THEN
       V_TRAN_AMT := P_TXN_AMT;

       BEGIN
        SP_CONVERT_CURR(P_INST_CODE,
                     P_CURR_CODE,
                     P_CARD_NO,
                     P_TXN_AMT,
                     V_TRAN_DATE,
                     V_TRAN_AMT,
                     V_CARD_CURR,
                     V_ERR_MSG);

        IF V_ERR_MSG <> 'OK' THEN
          V_RESP_CDE := '44';
          RAISE EXP_REJECT_RECORD;
        END IF;

       EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
          V_RESP_CDE := '69'; -- Server Declined -220509
          V_ERR_MSG  := 'Error from currency conversion ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
       END;
     ELSE
       -- If transaction Amount is zero - Invalid Amount -220509
       V_RESP_CDE := '43';
       V_ERR_MSG  := 'INVALID AMOUNT';
       RAISE EXP_REJECT_RECORD;
     END IF;
    END IF;

    --En find the tran amt

    --Sn select authorization processe flag
    BEGIN
     SELECT PTP_PARAM_VALUE
       INTO V_PRECHECK_FLAG
       FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE CHECK' AND PTP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21'; --only for master setups
       V_ERR_MSG  := 'Master set up is not done for Authorization Process';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; --only for master setups
       V_ERR_MSG  := 'Error while selecting precheck flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En select authorization process   flag
    --Sn select authorization processe flag
    BEGIN
     SELECT PTP_PARAM_VALUE
       INTO V_PREAUTH_FLAG
       FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE AUTH' AND PTP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Master set up is not done for Authorization Process';
       RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting PCMS_TRANAUTH_PARAM '||SUBSTR(SQLERRM,1,200);
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
           CAP_POS_ONLINE_LIMIT
       INTO V_PROD_CODE,
           V_PROD_CATTYPE,
           V_EXPRY_DATE,
           V_APPLPAN_CARDSTAT,
           V_ATMONLINE_LIMIT,
           V_ATMONLINE_LIMIT
       FROM CMS_APPL_PAN
      WHERE CAP_PAN_CODE = V_HASH_PAN
           AND CAP_INST_CODE = P_INST_CODE;    
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14';
       V_ERR_MSG  := 'CARD NOT FOUND ' || V_HASH_PAN;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12';
       V_ERR_MSG  := 'Problem while selecting card detail' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En find card detail

    -- Expiry Check
    BEGIN
     IF TO_DATE(P_TRAN_DATE, 'YYYYMMDD') >
        LAST_DAY(TO_CHAR(V_EXPRY_DATE, 'DD-MON-YY')) THEN
       V_RESP_CDE := '13';
       V_ERR_MSG  := 'EXPIRED CARD';
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'ERROR IN EXPIRY DATE CHECK ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    -- End Expiry Check

    --Sn check for precheck
    IF V_PRECHECK_FLAG = 1 THEN
     BEGIN
       SP_PRECHECK_TXN(P_INST_CODE,
                    P_CARD_NO,
                    P_DELIVERY_CHANNEL,
                    V_EXPRY_DATE,
                    V_APPLPAN_CARDSTAT,
                    P_TXN_CODE,
                    P_TXN_MODE,
                    P_TRAN_DATE,
                    P_TRAN_TIME,
                    V_TRAN_AMT,
                    V_ATMONLINE_LIMIT,
                    V_POSONLINE_LIMIT,
                    V_RESP_CDE,
                    V_ERR_MSG);

       IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Error from precheck processes ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    END IF;

    --En check for Precheck

    --Sn check for Preauth
    IF V_PREAUTH_FLAG = 1 THEN
     BEGIN
       SP_PREAUTHORIZE_TXN(P_CARD_NO,
                       P_MCC_CODE,
                       P_CURR_CODE,
                       V_TRAN_DATE,
                       P_TXN_CODE,
                       P_INST_CODE,
                       P_TRAN_DATE,
                       V_TRAN_AMT,
                       P_DELIVERY_CHANNEL,
                       V_RESP_CDE,
                       V_ERR_MSG);

       IF (V_RESP_CDE <> '1' OR TRIM(V_ERR_MSG) <> 'OK') THEN
        --V_RESP_CDE := '21';--Modified by Deepa on Apr-30-2012 for the response code change
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Error from pre_auth process ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    END IF;

    --En check for preauth

    --Sn find function code attached to txn code
    BEGIN
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
       V_ERR_MSG  := 'Error while selecting CMS_FUNC_MAST ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;
   END;

    --En find function code attached to txn code
    --Sn find prod code and card type and available balance for the card number
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO
       INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO
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
       V_ERR_MSG  := 'Invalid Card ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12';
       V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;

    --En find prod code and card type for the card number    

    --En Check PreAuth Completion txn
    BEGIN
     SP_TRAN_FEES_CMSAUTH(P_INST_CODE,
                      P_CARD_NO,
                      P_DELIVERY_CHANNEL,
                      V_TXN_TYPE,
                      P_TXN_MODE,
                      P_TXN_CODE,
                      P_CURR_CODE,
                      P_CONSODIUM_CODE,
                      P_PARTNER_CODE,
                      V_TRAN_AMT,
                      V_TRAN_DATE,
                      null,--Added by Deepa for Fees Changes
                      null,--Added by Deepa for Fees Changes
                      V_RESP_CDE,--Added by Deepa for Fees Changes
                      P_MSG,--Added by Deepa for Fees Changes
                      P_RVSL_CODE,--Added by Deepa on June 25 2012 for Reversal txn Fee
                      V_FEE_AMT,
                      V_ERROR,
                      V_FEE_CODE,
                      V_FEE_CRGL_CATG,
                      V_FEE_CRGL_CODE,
                      V_FEE_CRSUBGL_CODE,
                      V_FEE_CRACCT_NO,
                      V_FEE_DRGL_CATG,
                      V_FEE_DRGL_CODE,
                      V_FEE_DRSUBGL_CODE,
                      V_FEE_DRACCT_NO,
                      V_ST_CALC_FLAG,
                      V_CESS_CALC_FLAG,
                      V_ST_CRACCT_NO,
                      V_ST_DRACCT_NO,
                      V_CESS_CRACCT_NO,
                      V_CESS_DRACCT_NO,
                      V_FEEAMNT_TYPE,--Added by Deepa for Fees Changes
                      V_CLAWBACK,--Added by Deepa for Fees Changes
                      V_FEE_PLAN,--Added by Deepa for Fees Changes
                      V_PER_FEES, --Added by Deepa for Fees Changes
                      V_FLAT_FEES, --Added by Deepa for Fees Changes
                      V_FREETXN_EXCEED, -- Added by Trivikram for logging fee of free transaction
                      V_DURATION -- Added by Trivikram for logging fee of free transaction
                      );

     IF V_ERROR <> 'OK' THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := V_ERROR;
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error from fee calc process ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    ---En dynamic fee calculation .

    --Sn calculate waiver on the fee
    BEGIN
     SP_CALCULATE_WAIVER(P_INST_CODE,
                     P_CARD_NO,
                     '000',
                     V_PROD_CODE,
                     V_PROD_CATTYPE,
                     V_FEE_CODE,
                     V_FEE_PLAN, -- Added by Trivikram on 21/aug/2012
                     V_WAIV_PERCNT,
                     V_ERR_WAIV);

     IF V_ERR_WAIV <> 'OK' THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := V_ERR_WAIV;
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error from waiver calc process ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En calculate waiver on the fee

    --Sn apply waiver on fee amount
    V_LOG_ACTUAL_FEE := V_FEE_AMT; --only used to log in log table
    V_FEE_AMT        := ROUND(V_FEE_AMT -
                        ((V_FEE_AMT * V_WAIV_PERCNT) / 100),
                        2);
    V_LOG_WAIVER_AMT := V_LOG_ACTUAL_FEE - V_FEE_AMT;

    --only used to log in log table

    --En apply waiver on fee amount

    --Sn apply service tax and cess
    IF V_ST_CALC_FLAG = 1 THEN
     V_SERVICETAX_AMOUNT := (V_FEE_AMT * V_SERVICETAX_PERCENT) / 100;
    ELSE
     V_SERVICETAX_AMOUNT := 0;
    END IF;

    IF V_CESS_CALC_FLAG = 1 THEN
     V_CESS_AMOUNT := (V_SERVICETAX_AMOUNT * V_CESS_PERCENT) / 100;
    ELSE
     V_CESS_AMOUNT := 0;
    END IF;

    V_TOTAL_FEE := ROUND(V_FEE_AMT + V_SERVICETAX_AMOUNT + V_CESS_AMOUNT, 2);

     --En apply service tax and cess

    --En find fees amount attached to func code, prod code and card type

    --Sn find total transaction    amount
    IF TO_NUMBER(P_ADMINDRCR_IN) = 01 THEN
     V_TOTAL_AMT      := V_TRAN_AMT - V_TOTAL_FEE;
     V_UPD_AMT        := V_ACCT_BALANCE + V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := V_LEDGER_BAL + V_TOTAL_AMT;
     V_DR_CR_FLAG     := 'CR';
    ELSIF TO_NUMBER(P_ADMINDRCR_IN) = 02 THEN
     V_TOTAL_AMT      := V_TRAN_AMT + V_TOTAL_FEE;
     V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := V_LEDGER_BAL - V_TOTAL_AMT;
     V_DR_CR_FLAG     := 'DR';
    ELSE
     V_RESP_CDE := '12'; --Ineligible Transaction
     V_ERR_MSG  := 'Invalid transflag    txn code ' || P_TXN_CODE;
     RAISE EXP_REJECT_RECORD;
    END IF;

    --En find total transaction    amout

    --Sn check balance

    IF V_UPD_AMT < 0 THEN
     V_RESP_CDE := '15'; --Ineligible Transaction
     V_ERR_MSG  := 'Insufficent Balance ';
     RAISE EXP_REJECT_RECORD;

    END IF;

    --En check balance

    -- Check for maximum card balance configured for the product profile.
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
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --Sn check balance
    IF (V_UPD_LEDGER_AMT > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL) THEN
     V_RESP_CDE := '30';
     V_ERR_MSG  := 'EXCEEDING MAXIMUM CARD BALANCE';
     RAISE EXP_REJECT_RECORD;
    END IF;

    --En check balance

    --Sn create gl entries and acct update
    BEGIN
     SP_UPD_TRANSACTION_ACCNT_AUTH(P_INST_CODE,
                             V_TRAN_DATE,
                             V_PROD_CODE,
                             V_PROD_CATTYPE,
                             V_TRAN_AMT,
                             V_FUNC_CODE,
                             P_TXN_CODE,
                             V_DR_CR_FLAG,
                             P_RRN,
                             P_TERM_ID,
                             P_DELIVERY_CHANNEL,
                             P_TXN_MODE,
                             P_CARD_NO,
                             V_FEE_CODE,
                             V_FEE_AMT,
                             V_FEE_CRACCT_NO,
                             V_FEE_DRACCT_NO,
                             V_ST_CALC_FLAG,
                             V_CESS_CALC_FLAG,
                             V_SERVICETAX_AMOUNT,
                             V_ST_CRACCT_NO,
                             V_ST_DRACCT_NO,
                             V_CESS_AMOUNT,
                             V_CESS_CRACCT_NO,
                             V_CESS_DRACCT_NO,
                             V_CARD_ACCT_NO,
                             ---Card's account no has been passed instead of card no(For Debit card acct_no will be different)
                             V_HOLD_AMOUNT, --For PreAuth Completion transaction
                             P_MSG,
                             V_RESP_CDE,
                             V_ERR_MSG);

     IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error from currency conversion ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En create gl entries and acct update
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
    --Sn create a entry in statement log
    IF V_DR_CR_FLAG <> 'NA' THEN
     BEGIN
       INSERT INTO CMS_STATEMENTS_LOG
        (CSL_PAN_NO,
         CSL_OPENING_BAL,
         CSL_TRANS_AMOUNT,
         CSL_TRANS_TYPE,
         CSL_TRANS_DATE,
         CSL_CLOSING_BALANCE,
         CSL_TRANS_NARRRATION,
         CSL_INST_CODE,
         CSL_PAN_NO_ENCR,
         CSL_RRN,
         CSL_AUTH_ID,
         CSL_BUSINESS_DATE,
         CSL_BUSINESS_TIME,
         TXN_FEE_FLAG,
         CSL_DELIVERY_CHANNEL,
         csl_txn_code,
         CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         CSL_INS_USER,
         CSL_INS_DATE,
         CSL_PANNO_LAST4DIGIT)--Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
     
       VALUES
        (
         V_HASH_PAN,
         V_ACCT_BALANCE,
         V_TRAN_AMT,
         V_DR_CR_FLAG,
         V_TRAN_DATE,
         DECODE(V_DR_CR_FLAG,
               'DR',
               V_ACCT_BALANCE - V_TRAN_AMT,
               'CR',
               V_ACCT_BALANCE + V_TRAN_AMT,
               'NA',
               V_ACCT_BALANCE),
         V_NARRATION,
         P_INST_CODE,
         V_ENCR_PAN,
         P_RRN,
         V_AUTH_ID,
         P_TRAN_DATE,
         P_TRAN_TIME,
         'N',
         P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_CARD_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         1,
         sysdate,
         (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))));--Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number

     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Problem while inserting into statement log for tran amt ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    END IF;

    --En create a entry in statement log

    --Sn find fee opening balance
    IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N' THEN -- Modified by Trivikram on 26-July-2012 for logging fee of free transaction
     BEGIN
       SELECT DECODE(V_DR_CR_FLAG,
                  'DR',
                  V_ACCT_BALANCE - V_TRAN_AMT,
                  'CR',
                  V_ACCT_BALANCE + V_TRAN_AMT,
                  'NA',
                  V_ACCT_BALANCE)
        INTO V_FEE_OPENING_BAL
        FROM DUAL;
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '12';
        V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                    P_CARD_NO;
        RAISE EXP_REJECT_RECORD;
     END;
        
     -- Added by Trivikram on 27-July-2012 for logging complementary transaction
     IF V_FREETXN_EXCEED = 'N' THEN
        BEGIN
       INSERT INTO CMS_STATEMENTS_LOG
        (CSL_PAN_NO,
         CSL_OPENING_BAL,
         CSL_TRANS_AMOUNT,
         CSL_TRANS_TYPE,
         CSL_TRANS_DATE,
         CSL_CLOSING_BALANCE,
         CSL_TRANS_NARRRATION,
         CSL_INST_CODE,
         CSL_PAN_NO_ENCR,
         CSL_RRN,
         CSL_AUTH_ID,
         CSL_BUSINESS_DATE,
         CSL_BUSINESS_TIME,
         TXN_FEE_FLAG,
         CSL_DELIVERY_CHANNEL,
         csl_txn_code,
         CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         CSL_INS_USER,
         CSL_INS_DATE,
         CSL_PANNO_LAST4DIGIT)--Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
       VALUES
        (
         V_HASH_PAN,
         V_FEE_OPENING_BAL,
         V_TOTAL_FEE,
         'DR',
         V_TRAN_DATE,
         V_FEE_OPENING_BAL - V_TOTAL_FEE,
         'Complimentary ' || V_DURATION ||' '|| V_NARRATION, -- Modified by Trivikram  on 27-July-2012
         P_INST_CODE,
         V_ENCR_PAN,
         P_RRN,
         V_AUTH_ID,
         P_TRAN_DATE,
         P_TRAN_TIME,
         'Y',
         P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_CARD_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         1,
         sysdate,
         (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))));--Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Problem while inserting into statement log for tran fee ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END; 
      
     ELSE 
        BEGIN
     --En find fee opening balance
     IF V_FEEAMNT_TYPE='A' THEN
    
     --En Entry for Fixed Fee
     INSERT INTO CMS_STATEMENTS_LOG
        (CSL_PAN_NO,
         CSL_OPENING_BAL,
         CSL_TRANS_AMOUNT,
         CSL_TRANS_TYPE,
         CSL_TRANS_DATE,
         CSL_CLOSING_BALANCE,
         CSL_TRANS_NARRRATION,
         CSL_INST_CODE,
         CSL_PAN_NO_ENCR,
         CSL_RRN,
         CSL_AUTH_ID,
         CSL_BUSINESS_DATE,
         CSL_BUSINESS_TIME,
         TXN_FEE_FLAG,
         CSL_DELIVERY_CHANNEL,
         CSL_TXN_CODE,
         CSL_ACCT_NO,
         CSL_INS_USER,
         CSL_INS_DATE,       
         CSL_PANNO_LAST4DIGIT)
       VALUES
        (                     
         V_HASH_PAN,
         V_FEE_OPENING_BAL,
         V_FLAT_FEES,
         'DR',
         V_TRAN_DATE,
         V_FEE_OPENING_BAL - V_FLAT_FEES,
         'Fixed Fee debited for ' || V_NARRATION,
         P_INST_CODE,
         V_ENCR_PAN,
         P_RRN,
         V_AUTH_ID,
         P_TRAN_DATE,
         P_TRAN_TIME,
         'Y',
         P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_CARD_ACCT_NO,
         1,
         sysdate,         
         (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))));
         --En Entry for Fixed Fee
         V_FEE_OPENING_BAL:=V_FEE_OPENING_BAL - V_FLAT_FEES;
         --Sn Entry for Percentage Fee
         
          INSERT INTO CMS_STATEMENTS_LOG
        (CSL_PAN_NO,
         CSL_OPENING_BAL,
         CSL_TRANS_AMOUNT,
         CSL_TRANS_TYPE,
         CSL_TRANS_DATE,
         CSL_CLOSING_BALANCE,
         CSL_TRANS_NARRRATION,
         CSL_INST_CODE,
         CSL_PAN_NO_ENCR,
         CSL_RRN,
         CSL_AUTH_ID,
         CSL_BUSINESS_DATE,
         CSL_BUSINESS_TIME,
         TXN_FEE_FLAG,
         CSL_DELIVERY_CHANNEL,
         CSL_TXN_CODE,
         CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         CSL_INS_USER,
         CSL_INS_DATE,         
         CSL_PANNO_LAST4DIGIT)--Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
       VALUES
        (
         V_HASH_PAN,
         V_FEE_OPENING_BAL,
         V_PER_FEES,
         'DR',
         V_TRAN_DATE,
         V_FEE_OPENING_BAL - V_PER_FEES,
         'Percetage Fee debited for ' || V_NARRATION,
         P_INST_CODE,
         V_ENCR_PAN,
         P_RRN,
         V_AUTH_ID,
         P_TRAN_DATE,
         P_TRAN_TIME,
         'Y',
         P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_CARD_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         1,
         sysdate,         
         (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))));
         
         --En Entry for Percentage Fee
    
    ELSE
     --Sn create entries for FEES attached
    
       INSERT INTO CMS_STATEMENTS_LOG
        (CSL_PAN_NO,
         CSL_OPENING_BAL,
         CSL_TRANS_AMOUNT,
         CSL_TRANS_TYPE,
         CSL_TRANS_DATE,
         CSL_CLOSING_BALANCE,
         CSL_TRANS_NARRRATION,
         CSL_INST_CODE,
         CSL_PAN_NO_ENCR,
         CSL_RRN,
         CSL_AUTH_ID,
         CSL_BUSINESS_DATE,
         CSL_BUSINESS_TIME,
         TXN_FEE_FLAG,
         CSL_DELIVERY_CHANNEL,
         csl_txn_code,
         CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         CSL_INS_USER,
         CSL_INS_DATE,
         CSL_PANNO_LAST4DIGIT)--Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
       VALUES
        (
         V_HASH_PAN,
         V_FEE_OPENING_BAL,
         V_TOTAL_FEE,
         'DR',
         V_TRAN_DATE,
         V_FEE_OPENING_BAL - V_TOTAL_FEE,
         'Fee debited for ' || V_NARRATION,
         P_INST_CODE,
         V_ENCR_PAN,
         P_RRN,
         V_AUTH_ID,
         P_TRAN_DATE,
         P_TRAN_TIME,
         'Y',
         P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_CARD_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         1,
         sysdate,
         (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))));--Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
     END IF;
   EXCEPTION
     WHEN OTHERS THEN
      V_RESP_CDE := '21';
      V_ERR_MSG  := 'Problem while inserting into statement log for tran fee ' ||
                  SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
      END;
    END IF; 
    END IF;

    --En create entries for FEES attached
    --Sn create a entry for successful
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
        CTD_CUSTOMER_CARD_NO_ENCR)
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_MSG,
        P_TXN_MODE,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
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
        V_ENCR_PAN);
     --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --En create a entry for successful
    ---Sn update daily and weekly transcounter  and amount
    BEGIN
     /*SELECT CAT_PAN_CODE
       INTO V_AVAIL_PAN
       FROM CMS_AVAIL_TRANS
      WHERE CAT_PAN_CODE = V_HASH_PAN
           AND CAT_TRAN_CODE = P_TXN_CODE AND
           CAT_TRAN_MODE = P_TXN_MODE;*/

     UPDATE CMS_AVAIL_TRANS
        SET CAT_MAXDAILY_TRANCNT  = DECODE(CAT_MAXDAILY_TRANCNT,
                                    0,
                                    CAT_MAXDAILY_TRANCNT,
                                    CAT_MAXDAILY_TRANCNT - 1),
           CAT_MAXDAILY_TRANAMT  = DECODE(V_DR_CR_FLAG,
                                    'DR',
                                    CAT_MAXDAILY_TRANAMT - V_TRAN_AMT,
                                    CAT_MAXDAILY_TRANAMT),
           CAT_MAXWEEKLY_TRANCNT = DECODE(CAT_MAXWEEKLY_TRANCNT,
                                    0,
                                    CAT_MAXWEEKLY_TRANCNT,
                                    CAT_MAXDAILY_TRANCNT - 1),
           CAT_MAXWEEKLY_TRANAMT = DECODE(V_DR_CR_FLAG,
                                    'DR',
                                    CAT_MAXWEEKLY_TRANAMT -
                                    V_TRAN_AMT,
                                    CAT_MAXWEEKLY_TRANAMT)
      WHERE CAT_INST_CODE = P_INST_CODE AND CAT_PAN_CODE = V_HASH_PAN
           AND CAT_TRAN_CODE = P_TXN_CODE AND
           CAT_TRAN_MODE = P_TXN_MODE;
/*
     IF SQL%ROWCOUNT = 0 THEN
       V_ERR_MSG  := 'Problem while updating data in avail trans ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
     END IF;
     */
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from avail trans ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --En update daily and weekly transaction counter and amount
    --Sn create detail for response message
    IF V_OUTPUT_TYPE = 'B' THEN
     P_RESP_MSG := TO_CHAR(V_UPD_AMT);
    END IF;

    --En create detail fro response message
    --Sn mini statement
    IF V_OUTPUT_TYPE = 'M' THEN
     --Mini statement
     BEGIN
       SP_GEN_MINI_STMT(P_INST_CODE,
                    P_CARD_NO,
                    V_MINI_TOTREC,
                    V_MINISTMT_OUTPUT,
                    V_MINISTMT_ERRMSG);

       IF V_MINISTMT_ERRMSG <> 'OK' THEN
        V_ERR_MSG  := V_MINISTMT_ERRMSG;
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       END IF;

       P_RESP_MSG := LPAD(TO_CHAR(V_MINI_TOTREC), 2, '0') ||
                    V_MINISTMT_OUTPUT;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_ERR_MSG  := 'Problem while selecting data for mini statement ' ||
                    SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;
    END IF;

    --En mini statement
    V_RESP_CDE := '1';

    BEGIN
     --Add for PreAuth Transaction of CMSAuth;
     --Sn creating entries for preauth txn
     --if incoming message not contains checking for prod preauth expiry period
     --if preauth expiry period is not configured checking for instution expirty period

     BEGIN
       SELECT CTC_ATMUSAGE_AMT,
            CTC_POSUSAGE_AMT,
            CTC_ATMUSAGE_LIMIT,
            CTC_POSUSAGE_LIMIT,
            CTC_BUSINESS_DATE,
            CTC_PREAUTHUSAGE_LIMIT
        INTO V_ATM_USAGEAMNT,
            V_POS_USAGEAMNT,
            V_ATM_USAGELIMIT,
            V_POS_USAGELIMIT,
            V_BUSINESS_DATE_TRAN,
            V_PREAUTH_USAGE_LIMIT
        FROM CMS_TRANSLIMIT_CHECK
        WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN
            AND CTC_MBR_NUMB = P_MBR_NUMB;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS  THEN
        V_ERR_MSG  := 'Error while selecting CMS_TRANSLIMIT_CHECK' || SUBSTR(SQLERRM, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN
       IF P_DELIVERY_CHANNEL = '01' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          IF P_TXN_AMT IS NULL THEN
            V_ATM_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999999.99'));
          ELSE
            V_ATM_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
                                     '99999999999999999.99'));
          END IF;

          V_ATM_USAGELIMIT := 1;
BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_ATMUSAGE_AMT       = V_ATM_USAGEAMNT,
                CTC_ATMUSAGE_LIMIT     = V_ATM_USAGELIMIT,
                CTC_POSUSAGE_AMT       = 0,
                CTC_POSUSAGE_LIMIT     = 0,
                CTC_PREAUTHUSAGE_LIMIT = 0,
                CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                          '23:59:59',
                                          'yymmdd' || 'hh24:mi:ss')
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

           IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 1 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 1 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        ELSE
          IF P_TXN_AMT IS NULL THEN
            V_ATM_USAGEAMNT := V_ATM_USAGEAMNT +
                           TRIM(TO_CHAR(0, '99999999999999999.99'));
          ELSE
            V_ATM_USAGEAMNT := V_ATM_USAGEAMNT +
                           TRIM(TO_CHAR(V_TRAN_AMT,
                                     '99999999999999999.99'));
          END IF;

          V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;
          BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_ATMUSAGE_AMT   = V_ATM_USAGEAMNT,
                CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

           IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 2 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 2 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        END IF;
       END IF;

       IF P_DELIVERY_CHANNEL = '02' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          IF P_TXN_AMT IS NULL THEN
            V_POS_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999999.99'));
          ELSE
            V_POS_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
                                     '99999999999999999.99'));
          END IF;

          V_POS_USAGELIMIT := 1;

          IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
            V_PREAUTH_USAGE_LIMIT := 1;
            V_POS_USAGEAMNT       := 0;
          ELSE
            V_PREAUTH_USAGE_LIMIT := 0;
          END IF;
          BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_POSUSAGE_AMT       = V_POS_USAGEAMNT,
                CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
                CTC_ATMUSAGE_AMT       = 0,
                CTC_ATMUSAGE_LIMIT     = 0,
                CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                          '23:59:59',
                                          'yymmdd' || 'hh24:mi:ss'),
                CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

           IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 3 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 3 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

          IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
            V_PREAUTH_USAGE_LIMIT := V_PREAUTH_USAGE_LIMIT + 1;
            V_POS_USAGEAMNT       := V_POS_USAGEAMNT +
                                TRIM(TO_CHAR(V_TRAN_AMT,
                                          '99999999999999999.99'));
          ELSE
            IF P_TXN_AMT IS NULL THEN
             V_POS_USAGEAMNT := V_POS_USAGEAMNT +
                            TRIM(TO_CHAR(0, '99999999999999999.99'));
            ELSE
             V_POS_USAGEAMNT := V_POS_USAGEAMNT +
                            TRIM(TO_CHAR(V_TRAN_AMT,
                                       '99999999999999999.99'));
            END IF;
          END IF;
          BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_POSUSAGE_AMT   = V_POS_USAGEAMNT,
                CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
                CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

           IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 4 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 4 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        END IF;
       END IF;
     END;
    END;

    ---En Updation of Usage limit and amount
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master for respose code' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;  
  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;

     BEGIN
       SELECT CTC_ATMUSAGE_LIMIT,
            CTC_POSUSAGE_LIMIT,
            CTC_BUSINESS_DATE,
            CTC_PREAUTHUSAGE_LIMIT
        INTO V_ATM_USAGELIMIT,
            V_POS_USAGELIMIT,
            V_BUSINESS_DATE_TRAN,
            V_PREAUTH_USAGE_LIMIT
        FROM CMS_TRANSLIMIT_CHECK
        WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN
            AND CTC_MBR_NUMB = P_MBR_NUMB;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERR_MSG  := 'Error while selecting CMS_TRANSLIMIT_CHECK ' ||SUBSTR(SQLERRM, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN
       IF P_DELIVERY_CHANNEL = '01' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          V_ATM_USAGELIMIT := 1;
          BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET
                CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT,
                CTC_POSUSAGE_LIMIT     = 0,
                CTC_PREAUTHUSAGE_LIMIT = 0,
                CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                          '23:59:59',
                                          'yymmdd' || 'hh24:mi:ss')
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

           IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 5 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 5 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        ELSE
          V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;

        BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

        IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 6 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 6 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        END IF;
       END IF;

       IF P_DELIVERY_CHANNEL = '02' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN

          V_POS_USAGELIMIT := 1;
          IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
            V_PREAUTH_USAGE_LIMIT := 1;
          ELSE
            V_PREAUTH_USAGE_LIMIT := 0;
          END IF;
          BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET
                CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
                CTC_ATMUSAGE_LIMIT     = 0,
                CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                          '23:59:59',
                                          'yymmdd' || 'hh24:mi:ss'),
                CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

           IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 7 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 7 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

          IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
            V_PREAUTH_USAGE_LIMIT := V_PREAUTH_USAGE_LIMIT + 1;
          END IF;
          BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET
                CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
                CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN --P_card_no
                AND CTC_MBR_NUMB = P_MBR_NUMB;

           IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 8 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 8 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        END IF;
       END IF;
     END;

     --Sn select response code and insert record into txn log dtl
     BEGIN
       P_RESP_MSG  := V_ERR_MSG;
       P_RESP_CODE := V_RESP_CDE;

       -- Assign the response code to the out parameter
       SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INST_CODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                      V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69';
        ---ISO MESSAGE FOR DATABASE ERROR Server Declined
        ROLLBACK;
     END;

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
         CTD_CUSTOMER_CARD_NO_ENCR)
       VALUES
        (P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_MSG,
         P_TXN_MODE,
         P_TRAN_DATE,
         P_TRAN_TIME,
         V_HASH_PAN,
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
         V_ENCR_PAN);

       P_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                      SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        ROLLBACK;
        RETURN;
     END;
    WHEN OTHERS THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO
        INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN
                   AND CAP_MBR_NUMB = P_MBR_NUMB AND
                   CAP_INST_CODE = P_INST_CODE) AND
            CAM_INST_CODE = P_INST_CODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;
     END;
     BEGIN
       SELECT CTC_ATMUSAGE_LIMIT,
            CTC_POSUSAGE_LIMIT,
            CTC_BUSINESS_DATE,
            CTC_PREAUTHUSAGE_LIMIT
        INTO V_ATM_USAGELIMIT,
            V_POS_USAGELIMIT,
            V_BUSINESS_DATE_TRAN,
            V_PREAUTH_USAGE_LIMIT
        FROM CMS_TRANSLIMIT_CHECK
        WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN
            AND CTC_MBR_NUMB = P_MBR_NUMB;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERR_MSG  := 'Error while selecting 1 CMS_TRANSLIMIT_CHECK ' ||SUBSTR(SQLERRM, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN
       IF P_DELIVERY_CHANNEL = '01' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          V_ATM_USAGELIMIT := 1;
          BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET
                CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT,
                CTC_POSUSAGE_LIMIT     = 0,
                CTC_PREAUTHUSAGE_LIMIT = 0,
                CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                          '23:59:59',
                                          'yymmdd' || 'hh24:mi:ss')
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

           IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 9 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 9 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        ELSE
          V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;

    BEGIN
              UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

          IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 10 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 10 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        END IF;
       END IF;

       IF P_DELIVERY_CHANNEL = '02' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          V_POS_USAGEAMNT       := 0;
          V_POS_USAGELIMIT      := 1;
          V_PREAUTH_USAGE_LIMIT := 0;
          BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET
                CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
                CTC_ATMUSAGE_LIMIT     = 0,
                CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                          '23:59:59',
                                          'yymmdd' || 'hh24:mi:ss'),
                CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

           IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 11 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 11 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;
          BEGIN
          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN
                AND CTC_MBR_NUMB = P_MBR_NUMB;

           IF SQL%ROWCOUNT=0 THEN
             V_ERR_MSG   := 'Error while updating 12 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
           END IF;

    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG   := 'Error while updating 12 CMS_TRANSLIMIT_CHECK' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
    END;
        END IF;
       END IF;
     END;

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
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                      V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        ROLLBACK;
     END;

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
         CTD_CUSTOMER_CARD_NO_ENCR)
       VALUES
        (P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_MSG,
         P_TXN_MODE,
         P_TRAN_DATE,
         P_TRAN_TIME,
         V_HASH_PAN,
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
         V_ENCR_PAN);
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                      SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Decline Response 220509
        ROLLBACK;
        RETURN;
     END;
     --En select response code and insert record into txn log dtl
  END;

  --- Sn create GL ENTRIES
  IF V_RESP_CDE = '1' THEN
    SAVEPOINT V_SAVEPOINT;
    --Sn find business date
     V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
    ELSE
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
    END IF;

    --En find businesses date
    BEGIN
     SP_CREATE_GL_ENTRIES_CMSAUTH(P_INST_CODE,
                            V_BUSINESS_DATE,
                            V_PROD_CODE,
                            V_PROD_CATTYPE,
                            V_TRAN_AMT,
                            V_FUNC_CODE,
                            P_TXN_CODE,
                            V_DR_CR_FLAG,
                            P_CARD_NO,
                            V_FEE_CODE,
                            V_TOTAL_FEE,
                            V_FEE_CRACCT_NO,
                            V_FEE_DRACCT_NO,
                            V_CARD_ACCT_NO,
                            P_RVSL_CODE,
                            P_MSG,
                            P_DELIVERY_CHANNEL,
                            V_RESP_CDE,
                            V_GL_UPD_FLAG,
                            V_GL_ERR_MSG);

     IF V_GL_ERR_MSG <> 'OK' OR V_GL_UPD_FLAG <> 'Y' THEN
       ROLLBACK TO V_SAVEPOINT;
       V_GL_UPD_FLAG := 'N';
       P_RESP_CODE := V_RESP_CDE;
       P_RESP_MSG  := V_GL_ERR_MSG;
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       ROLLBACK TO V_SAVEPOINT;
       V_GL_UPD_FLAG := 'N';
       P_RESP_CODE := V_RESP_CDE;
       P_RESP_MSG  := V_GL_ERR_MSG;
    END;

    --Sn find prod code and card type and available balance for the card number
    BEGIN
     SELECT CAM_ACCT_BAL
       INTO V_ACCT_BALANCE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN --P_card_no
                 AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE
        FOR UPDATE NOWAIT;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14'; --Ineligible Transaction
       V_ERR_MSG  := 'Invalid Card ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12';
       V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;

    --En find prod code and card type for the card number
    IF V_OUTPUT_TYPE = 'N' THEN
     --Balance Inquiry
     P_RESP_MSG := TO_CHAR(V_UPD_AMT);
    END IF;
  END IF;

  --En create GL ENTRIES

  --Sn generate auth id
  BEGIN
    SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
  EXCEPTION
    WHEN OTHERS THEN
     P_RESP_MSG  := 'Error while generating authid ' ||
                   SUBSTR(SQLERRM, 1, 300);
     P_RESP_CODE := '69'; -- Server Declined
     ROLLBACK;
  END;

  --En generate auth id

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
      CUSTOMER_CARD_NO_ENCR,
      TOPUP_CARD_NO_ENCR,
      RESPONSE_ID,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
      FEE_PLAN 
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
      V_HASH_PAN,
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_BANK_CODE,
      TRIM(TO_CHAR(V_TOTAL_AMT, '99999999999999999.99')),
      P_RULE_INDICATOR,
      P_RULEGRP_ID,
      P_MCC_CODE,
      P_CURR_CODE,
      NULL,
      V_PROD_CODE,
      V_PROD_CATTYPE,
      P_TIP_AMT,
      P_DECLINE_RULEID,
      NULL,
      V_AUTH_ID,
      V_NARRATION,
      TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99')),
      NULL,
      NULL, -- Partial amount (will be given for partial txn)
      P_MCCCODE_GROUPID,
      P_CURRCODE_GROUPID,
      P_TRANSCODE_GROUPID,
      P_RULES,
      NULL,
      V_GL_UPD_FLAG,
      P_STAN,
      P_INST_CODE,
      V_FEE_CODE,
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
      V_RESP_CDE,
      V_ACCT_BALANCE,
      V_LEDGER_BAL,
      V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
      V_FEE_PLAN--Added by Deepa for Fee Plan on June 10 2012
      );

    --DBMS_OUTPUT.PUT_LINE('AFTER INSERT IN TRANSACTIONLOG');
    P_CAPTURE_DATE := V_BUSINESS_DATE;
    P_AUTH_ID      := V_AUTH_ID;
  EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK;
     P_RESP_CODE := '69'; -- Server Declione
     P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                   SUBSTR(SQLERRM, 1, 300);
  END;
  --En create a entry in txn log
  
 
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    P_RESP_CODE := '69'; -- Server Declined
    P_RESP_MSG  := 'Main exception from  authorization ' ||
                 SUBSTR(SQLERRM, 1, 300);
END;
/
show error;