CREATE OR REPLACE PROCEDURE VMSCMS.SP_PREAUTH_COMP(PRM_INST_CODE        IN NUMBER,
								    PRM_MSG              IN VARCHAR2,
								    PRM_RRN              VARCHAR2,
								    PRM_DELIVERY_CHANNEL VARCHAR2,
								    PRM_TERM_ID          VARCHAR2,
								    PRM_TXN_CODE         VARCHAR2,
								    PRM_TXN_MODE         VARCHAR2,
								    PRM_TRAN_DATE        VARCHAR2,
								    PRM_TRAN_TIME        VARCHAR2,
								    PRM_CARD_NO          VARCHAR2,
								    PRM_TXN_AMT          NUMBER,
								    PRM_MCC_CODE         VARCHAR2,
								    PRM_CURR_CODE        VARCHAR2,
								    PRM_PROD_ID          VARCHAR2,
								    PRM_CATG_ID          VARCHAR2,
								    PRM_ATMNAME_LOC      VARCHAR2,
								    PRM_CONSODIUM_CODE   IN VARCHAR2,
								    PRM_PARTNER_CODE     IN VARCHAR2,
								    PRM_EXPRY_DATE       IN VARCHAR2,
								    PRM_STAN             IN VARCHAR2,
								    PRM_MBR_NUMB         IN VARCHAR2,
								    PRM_RVSL_CODE        IN NUMBER,
								    PRM_ORGNL_CARDNO     IN VARCHAR2, --Card No of Preauth txn
								    PRM_ORGNL_RRN        IN VARCHAR2, --RRN of Preauth txn
								    PRM_ORGNL_TRANDATE   IN VARCHAR2, --Transaction date of Preauth txn
								    PRM_ORGNL_TRANTIME   IN VARCHAR2, --Transaction Time of Preauth txn
								    PRM_ORGNL_TERMID     IN VARCHAR2, --Terminal Id of Preauth txn
								    PRM_AUTH_ID          OUT VARCHAR2,
								    PRM_RESP_CODE        OUT VARCHAR2,
								    PRM_RESP_MSG         OUT VARCHAR2,
								    PRM_CAPTURE_DATE     OUT DATE) IS
  V_ERR_MSG            VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE       NUMBER;
  V_LEDGER_BAL         NUMBER;
  V_TRAN_AMT           NUMBER;
  V_AUTH_ID            VARCHAR2(6);
  V_TOTAL_AMT          NUMBER;
  V_TRAN_DATE          DATE;
  V_FUNC_CODE          CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_PROD_CODE          CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE       CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT            NUMBER;
  V_TOTAL_FEE          NUMBER;
  V_UPD_AMT            NUMBER;
  V_UPD_LEDGER_AMT     NUMBER;
  V_NARRATION          VARCHAR2(50);
  V_FEE_OPENING_BAL    NUMBER;
  V_RESP_CDE           VARCHAR2(3);
  V_EXPRY_DATE         DATE;
  V_DR_CR_FLAG         VARCHAR2(2);
  V_OUTPUT_TYPE        VARCHAR2(2);
  V_APPLPAN_CARDSTAT   VARCHAR2(1);
  PRM_ERR_MSG          VARCHAR2(500);
  V_PRECHECK_FLAG      NUMBER;
  V_PREAUTH_FLAG       NUMBER;
  V_AVAIL_PAN          CMS_AVAIL_TRANS.CAT_PAN_CODE%TYPE;
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
  V_FEE_ATTACH_TYPE  VARCHAR2(1);
  V_CHECK_MERCHANT   NUMBER(1);
  EXP_REJECT_RECORD EXCEPTION;
  V_TERMINAL_DOWNLOAD_IND VARCHAR2(1);
  V_TERMINAL_COUNT        NUMBER;
  V_ATMONLINE_LIMIT       CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT       CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_TEMP_EXPIRY           CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
  V_BIN_CODE              NUMBER(6);
  V_TERMINAL_BIN_COUNT    NUMBER;
  V_ATM_USAGEAMNT         CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT         CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  V_ATM_USAGELIMIT        CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT        CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_PREAUTH_AMOUNT        NUMBER;
  V_PREAUTH_TXNAMOUNT     NUMBER;
  V_PREAUTH_DATE          DATE;
  V_PREAUTH_VALID_FLAG    CHARACTER(1);
  V_PREAUTH_HOLD          VARCHAR2(1);
  V_PREAUTH_PERIOD        NUMBER;
  V_PREAUTH_USAGE_LIMIT   NUMBER;
  V_CARD_ACCT_NO          VARCHAR2(20);
  V_HOLD_AMOUNT           NUMBER;
  V_PREAUTH_EXP_DATE      DATE;
  V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN              CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_ORGNL_HASH_PAN        CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_RRN_COUNT             NUMBER;
  V_TRAN_TYPE             VARCHAR2(2);
  V_DATE                  DATE;
  V_TIME                  VARCHAR2(10);
  V_MAX_CARD_BAL          NUMBER;
  V_CURR_DATE             DATE;
BEGIN
  --<< MAIN BEGIN>>
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE   := '1';
  PRM_ERR_MSG  := 'OK';
  PRM_RESP_MSG := 'OK';

  BEGIN

    --SN CREATE HASH PAN
    BEGIN

	 V_HASH_PAN := GETHASH(PRM_CARD_NO);

    EXCEPTION
	 WHEN OTHERS THEN
	   V_RESP_CDE  := '21'; -- added by chinmaya
	   PRM_ERR_MSG := 'Error while converting pan ' ||
				   SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;

    --EN CREATE HASH PAN

    --SN CREATE Original HASH PAN
    BEGIN

	 V_ORGNL_HASH_PAN := GETHASH(PRM_ORGNL_CARDNO);

    EXCEPTION
	 WHEN OTHERS THEN
	   V_RESP_CDE  := '21'; -- added by chinmaya
	   PRM_ERR_MSG := 'Error while converting pan ' ||
				   SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;

    --EN CREATE Original HASH PAN

    --SN create encr pan
    BEGIN
	 V_ENCR_PAN := FN_EMAPS_MAIN(PRM_CARD_NO);
    EXCEPTION
	 WHEN OTHERS THEN
	   V_RESP_CDE  := '21'; -- added by chinmaya
	   PRM_ERR_MSG := 'Error while converting pan ' ||
				   SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;

    --EN create encr pan

    --Sn Transaction Date Check

    BEGIN

	 V_DATE := TO_DATE(SUBSTR(TRIM(PRM_TRAN_DATE), 1, 8), 'yyyymmdd');
    EXCEPTION
	 WHEN OTHERS THEN
	   V_RESP_CDE := '45'; -- Server Declined -220509
	   V_ERR_MSG  := 'Problem while converting transaction date ' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;
    --En Transaction Date Check

    --Sn Date Conversion

    BEGIN

	 V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(PRM_TRAN_DATE), 1, 8) || ' ' ||
					    SUBSTR(TRIM(PRM_TRAN_TIME), 1, 10),
					    'yyyymmdd hh24:mi:ss');
    EXCEPTION
	 WHEN OTHERS THEN
	   V_RESP_CDE := '32'; -- Server Declined -220509
	   V_ERR_MSG  := 'Problem while converting transaction time ' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;

    --Sn Date Conversion

    --Sn Duplicate RRN Check

    BEGIN

	 SELECT COUNT(1)
	   INTO V_RRN_COUNT
	   FROM TRANSACTIONLOG
	  WHERE TERMINAL_ID = PRM_TERM_ID AND RRN = PRM_RRN AND
		   BUSINESS_DATE = PRM_TRAN_DATE;

	 IF V_RRN_COUNT > 0 THEN
	   V_RESP_CDE := '22';
	   V_ERR_MSG  := 'Duplicate RRN from the Treminal' || PRM_TERM_ID || 'on' ||
				  PRM_TRAN_DATE;
	   RAISE EXP_REJECT_RECORD;

	 END IF;

    END;

    --En Duplicate RRN Check

    --Sn find service tax
    BEGIN
	 SELECT CIP_PARAM_VALUE
	   INTO V_SERVICETAX_PERCENT
	   FROM CMS_INST_PARAM
	  WHERE CIP_PARAM_KEY = 'SERVICETAX' AND CIP_INST_CODE = PRM_INST_CODE;
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
	  WHERE CIP_PARAM_KEY = 'CESS' AND CIP_INST_CODE = PRM_INST_CODE;
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
	  WHERE CIP_PARAM_KEY = 'CUTOFF' AND CIP_INST_CODE = PRM_INST_CODE;
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
	  WHERE CTM_TRAN_CODE = PRM_TXN_CODE AND
		   CTM_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL AND
		   CTM_INST_CODE = PRM_INST_CODE;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_RESP_CDE := '12'; --Ineligible Transaction
	   V_ERR_MSG  := 'Transflag  not defined for txn code ' ||
				  PRM_TXN_CODE || ' and delivery channel ' ||
				  PRM_DELIVERY_CHANNEL;
	   RAISE EXP_REJECT_RECORD;

	 WHEN TOO_MANY_ROWS THEN
	   V_RESP_CDE := '12'; --Ineligible Transaction
	   V_ERR_MSG  := 'More than one transaction defined for txn code ';
	   RAISE EXP_REJECT_RECORD;

	 WHEN OTHERS THEN
	   V_RESP_CDE := '12'; --Ineligible Transaction
	   V_ERR_MSG  := 'Error while selecting the details fromtransaction ';
	   RAISE EXP_REJECT_RECORD;
    END;

    --En find debit and credit flag

    --Sn find the  Currency Converted txn amnt

    IF (PRM_TXN_AMT >= 0) THEN
	 V_TRAN_AMT := PRM_TXN_AMT;

	 BEGIN
	   SP_CONVERT_CURR(PRM_INST_CODE,
				    PRM_CURR_CODE,
				    PRM_CARD_NO,
				    PRM_TXN_AMT,
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

    --Sn find the  Currency Converted txn amnt

    --Sn select authorization processe flag
    BEGIN
	 SELECT PTP_PARAM_VALUE
	   INTO V_PRECHECK_FLAG
	   FROM PCMS_TRANAUTH_PARAM
	  WHERE PTP_PARAM_NAME = 'PRE CHECK' AND PTP_INST_CODE = PRM_INST_CODE;
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
	  WHERE PTP_PARAM_NAME = 'PRE AUTH' AND PTP_INST_CODE = PRM_INST_CODE;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_RESP_CDE := '21';
	   V_ERR_MSG  := 'Master set up is not done for Authorization Process';
	   RAISE EXP_REJECT_RECORD;
	 WHEN OTHERS THEN
	   V_RESP_CDE := '21'; --only for master setups
	   V_ERR_MSG  := 'Error while selecting precheck flag' ||
				  SUBSTR(SQLERRM, 1, 200);
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
	  WHERE CAP_PAN_CODE = V_HASH_PAN -- prm_card_no
		   AND CAP_INST_CODE = PRM_INST_CODE;
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

	 --SELECT SYSDATE INTO V_CURR_DATE FROM DUAL;

	 IF TO_DATE(PRM_TRAN_DATE, 'YYYYMMDD') >
	    LAST_DAY(TO_DATE(V_EXPRY_DATE, 'DD-MON-YY')) THEN

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

    --Sn check for Preauth
    IF V_PREAUTH_FLAG = 1 THEN
	 BEGIN
	   SP_PREAUTHORIZE_TXN(PRM_CARD_NO,
					   PRM_MCC_CODE,
					   PRM_CURR_CODE,
					   V_TRAN_DATE,
					   PRM_TXN_CODE,
					   PRM_INST_CODE,
					   PRM_TRAN_DATE,
					   V_TRAN_AMT,
					   PRM_DELIVERY_CHANNEL,
					   V_RESP_CDE,
					   V_ERR_MSG);

	   IF (V_RESP_CDE <> '1' OR TRIM(V_ERR_MSG) <> 'OK') THEN
		V_RESP_CDE := '21';
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
	  WHERE CFM_TXN_CODE = PRM_TXN_CODE AND CFM_TXN_MODE = PRM_TXN_MODE AND
		   CFM_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL AND
		   CFM_INST_CODE = PRM_INST_CODE;

	 --TXN mode and delivery channel we need to attach
	 --bkz txn code may be same for all type of channels
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_RESP_CDE := '69'; --Ineligible Transaction
	   V_ERR_MSG  := 'Function code not defined for txn code ' ||
				  PRM_TXN_CODE;
	   RAISE EXP_REJECT_RECORD;

	 WHEN TOO_MANY_ROWS THEN
	   V_RESP_CDE := '69';
	   V_ERR_MSG  := 'More than one function defined for txn code ' ||
				  PRM_TXN_CODE;
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
			WHERE CAP_PAN_CODE = V_HASH_PAN --prm_card_no
				 AND CAP_MBR_NUMB = PRM_MBR_NUMB AND
				 CAP_INST_CODE = PRM_INST_CODE) AND
		   CAM_INST_CODE = PRM_INST_CODE
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

    --Sn Check PreAuth Completion txn

    BEGIN
	 IF PRM_TXN_CODE = '12' AND PRM_MSG = '0200' THEN

	   BEGIN
		SELECT CPT_TXN_AMNT, CPT_PREAUTH_VALIDFLAG, CPT_APPROVE_AMT
		  INTO V_PREAUTH_AMOUNT, V_PREAUTH_VALID_FLAG, V_HOLD_AMOUNT
		  FROM CMS_PREAUTH_TRANSACTION
		 WHERE CPT_RRN = PRM_ORGNL_RRN AND
			  CPT_TXN_DATE = PRM_ORGNL_TRANDATE AND
			  CPT_TXN_TIME = PRM_ORGNL_TRANTIME AND
			  CPT_TERMINALID = PRM_ORGNL_TERMID AND
			  CPT_COMPLETION_FLAG = 'I' AND CPT_MBR_NO = PRM_MBR_NUMB AND
			  CPT_INST_CODE = PRM_INST_CODE AND
			  CPT_CARD_NO = V_ORGNL_HASH_PAN;

	   EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  V_RESP_CDE := '56';
		  V_ERR_MSG  := 'No PreAuth Transaction found for the Completion';
		  RAISE EXP_REJECT_RECORD;
		WHEN TOO_MANY_ROWS THEN
		  V_RESP_CDE := '21'; --Ineligible Transaction
		  V_ERR_MSG  := 'More than one record found ';
		  RAISE EXP_REJECT_RECORD;
		WHEN OTHERS THEN
		  V_RESP_CDE := '21'; --Ineligible Transaction
		  V_ERR_MSG  := 'Error while selecting the PreAuth details';
		  RAISE EXP_REJECT_RECORD;
	   END;

	   IF V_PREAUTH_VALID_FLAG != 'Y' THEN

		V_RESP_CDE := '57';
		V_ERR_MSG  := 'PreAuth Completion has already done';

	   END IF;

	 END IF;

    END;

    --En Check PreAuth Completion txn

    BEGIN
	 SP_TRAN_FEES_CMSAUTH(PRM_INST_CODE,
					  PRM_CARD_NO,
					  PRM_DELIVERY_CHANNEL,
					  V_TXN_TYPE,
					  PRM_TXN_MODE,
					  PRM_TXN_CODE,
					  PRM_CURR_CODE,
					  PRM_CONSODIUM_CODE,
					  PRM_PARTNER_CODE,
					  V_TRAN_AMT,
					  V_TRAN_DATE,
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
					  V_CESS_DRACCT_NO
					  --,
					  --v_fee_attach_type
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
	 SP_CALCULATE_WAIVER(PRM_INST_CODE,
					 PRM_CARD_NO,
					 '000',
					 V_PROD_CODE,
					 V_PROD_CATTYPE,
					 V_FEE_CODE,
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

    --v_fee_amt :=
    --En apply service tax and cess

    --En find fees amount attached to func code, prod code and card type

    --Sn find total transaction    amount
    IF V_DR_CR_FLAG = 'CR' THEN
	 V_TOTAL_AMT := V_TRAN_AMT - V_TOTAL_FEE;
	 -- v_total_amt :=  0 ;
	 V_UPD_AMT := V_ACCT_BALANCE + V_TOTAL_AMT;
	 --v_upd_ledger_amt := v_ledger_bal + v_total_amt;

    ELSIF V_DR_CR_FLAG = 'DR' THEN

	 IF PRM_TXN_CODE = '12' AND PRM_MSG = '0200' THEN

	   V_TOTAL_AMT := V_TRAN_AMT + V_TOTAL_FEE;
	   V_UPD_AMT   := (V_HOLD_AMOUNT + V_ACCT_BALANCE) - V_TOTAL_AMT;

	 ELSE

	   V_TOTAL_AMT := V_TRAN_AMT + V_TOTAL_FEE;
	   V_UPD_AMT   := V_ACCT_BALANCE - V_TOTAL_AMT;

	 END IF;

    ELSIF V_DR_CR_FLAG = 'NA' THEN

	 IF V_TOTAL_FEE = 0 THEN

	   V_TOTAL_AMT := 0;

	 ELSE
	   V_TOTAL_AMT := V_TOTAL_FEE;
	 END IF;
	 -- v_total_amt :=  0 ;

	 V_UPD_AMT := V_ACCT_BALANCE - V_TOTAL_AMT;

    ELSE
	 V_RESP_CDE := '12'; --Ineligible Transaction
	 V_ERR_MSG  := 'Invalid transflag    txn code ' || PRM_TXN_CODE;
	 RAISE EXP_REJECT_RECORD;
    END IF;

    --En find total transaction    amout

    --Sn create gl entries and acct update
    BEGIN
	 SP_UPD_TRANSACTION_ACCNT_AUTH(PRM_INST_CODE,
							 V_TRAN_DATE,
							 V_PROD_CODE,
							 V_PROD_CATTYPE,
							 V_TRAN_AMT,
							 V_FUNC_CODE,
							 PRM_TXN_CODE,
							 V_DR_CR_FLAG,
							 PRM_RRN,
							 PRM_TERM_ID,
							 PRM_DELIVERY_CHANNEL,
							 PRM_TXN_MODE,
							 PRM_CARD_NO,
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
							 V_CARD_ACCT_NO, ---Card's account no has been passed instead of card no(For Debit card acct_no will be different)
							 V_HOLD_AMOUNT, --For PreAuth Completion transaction
							 PRM_MSG,
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
	  WHERE CTM_TRAN_CODE = PRM_TXN_CODE AND
		   CTM_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL AND
		   CTM_INST_CODE = PRM_INST_CODE;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_NARRATION := 'Transaction type ' || PRM_TXN_CODE;
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
		 CSL_PAN_NO_ENCR)
	   VALUES
		( --prm_card_no
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
		 PRM_INST_CODE,
		 V_ENCR_PAN);
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
    IF V_TOTAL_FEE <> 0 THEN
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
				    PRM_CARD_NO;
		RAISE EXP_REJECT_RECORD;
	 END;

	 --En find fee opening balance
	 --Sn create entries for FEES attached
	 --FOR I IN C LOOP
	 BEGIN
	   --v_fee_opening_bal := v_upd_amt;
	   --v_upd_amt := v_upd_amt - i.fee_amt;
	   INSERT INTO CMS_STATEMENTS_LOG
		(CSL_PAN_NO,
		 CSL_OPENING_BAL,
		 CSL_TRANS_AMOUNT,
		 CSL_TRANS_TYPE,
		 CSL_TRANS_DATE,
		 CSL_CLOSING_BALANCE,
		 CSL_TRANS_NARRRATION,
		 CSL_INST_CODE,
		 CSL_PAN_NO_ENCR)
	   VALUES
		( --prm_card_no
		 V_HASH_PAN,
		 V_FEE_OPENING_BAL,
		 V_TOTAL_FEE,
		 'DR',
		 V_TRAN_DATE,
		 V_FEE_OPENING_BAL - V_TOTAL_FEE,
		 'Fee debited for ' || V_NARRATION,
		 PRM_INST_CODE,
		 V_ENCR_PAN);
	   --v_fee_opening_bal  := v_fee_opening_bal - i.fee_amt;
	 EXCEPTION
	   WHEN OTHERS THEN
		V_RESP_CDE := '21';
		V_ERR_MSG  := 'Problem while inserting into statement log for tran fee ' ||
				    SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;
    END IF;

    --END LOOP;
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
	   (PRM_DELIVERY_CHANNEL,
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

    V_RESP_CDE := '1';

    IF PRM_TXN_CODE = '12' AND PRM_MSG = '0200' THEN

	 BEGIN
	   INSERT INTO CMS_PREAUTH_TRANSACTION
		(CPT_CARD_NO,
		 CPT_MBR_NO,
		 CPT_INST_CODE,
		 CPT_CARD_NO_ENCR,
		 CPT_PREAUTH_VALIDFLAG,
		 CPT_COMPLETION_FLAG,
		 CPT_TXN_AMNT,
		 CPT_APPROVE_AMT,
		 CPT_RRN,
		 CPT_TXN_DATE,
		 CPT_TXN_TIME,
		 CPT_ORGNL_RRN,
		 CPT_ORGNL_TXN_DATE,
		 CPT_ORGNL_TXN_TIME,
		 CPT_ORGNL_CARD_NO,
		 CPT_TERMINALID,
		 CPT_ORGNL_TERMINALID)
	   VALUES
		(V_HASH_PAN,
		 PRM_MBR_NUMB,
		 PRM_INST_CODE,
		 V_ENCR_PAN,
		 'N',
		 'C',
		 PRM_TXN_AMT,
		 V_TOTAL_AMT,
		 PRM_RRN,
		 PRM_TRAN_DATE,
		 PRM_TRAN_TIME,
		 PRM_ORGNL_RRN,
		 PRM_ORGNL_TRANDATE,
		 PRM_ORGNL_TRANTIME,
		 V_ORGNL_HASH_PAN,
		 PRM_TERM_ID,
		 PRM_ORGNL_TERMID);

	   UPDATE CMS_PREAUTH_TRANSACTION
		 SET CPT_PREAUTH_VALIDFLAG = 'N'
	    WHERE CPT_CARD_NO = PRM_ORGNL_CARDNO AND
			CPT_TXN_DATE = PRM_ORGNL_TRANDATE AND
			CPT_TXN_TIME = PRM_ORGNL_TRANTIME AND
			CPT_RRN = PRM_ORGNL_RRN AND
			CPT_TERMINALID = PRM_ORGNL_TERMID AND
			CPT_PREAUTH_VALIDFLAG = 'Y' AND CPT_COMPLETION_FLAG = 'I' AND
			CPT_INST_CODE = PRM_INST_CODE;

	 EXCEPTION
	   WHEN OTHERS THEN
		V_ERR_MSG  := 'Problem While Updating the Pre-Auth Completion transaction details of the card' ||
				    SUBSTR(SQLERRM, 1, 300);
		V_RESP_CDE := '21';
		RAISE EXP_REJECT_RECORD;

	 END;

    END IF;
    --Sn Updation of Usage limit and amount
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
	  WHERE CTC_INST_CODE = PRM_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN --prm_card_no
		   AND CTC_MBR_NUMB = PRM_MBR_NUMB;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
				  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
	   V_RESP_CDE := '21';
	   RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
	 IF PRM_DELIVERY_CHANNEL = '01' THEN
	   IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
		IF PRM_TXN_AMT IS NULL THEN
		  V_ATM_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999999.99'));
		ELSE
		  V_ATM_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
								    '99999999999999999.99'));
		END IF;

		V_ATM_USAGELIMIT := 1;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_ATMUSAGE_AMT       = V_ATM_USAGEAMNT,
			  CTC_ATMUSAGE_LIMIT     = V_ATM_USAGELIMIT,
			  CTC_POSUSAGE_AMT       = 0,
			  CTC_POSUSAGE_LIMIT     = 0,
			  CTC_PREAUTHUSAGE_LIMIT = 0,
			  CTC_BUSINESS_DATE      = TO_DATE(PRM_TRAN_DATE ||
										'23:59:59',
										'yymmdd' || 'hh24:mi:ss')
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN --prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   ELSE
		IF PRM_TXN_AMT IS NULL THEN
		  V_ATM_USAGEAMNT := V_ATM_USAGEAMNT +
						 TRIM(TO_CHAR(0, '99999999999999999.99'));
		ELSE
		  V_ATM_USAGEAMNT := V_ATM_USAGEAMNT +
						 TRIM(TO_CHAR(V_TRAN_AMT,
								    '99999999999999999.99'));
		END IF;

		V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_ATMUSAGE_AMT   = V_ATM_USAGEAMNT,
			  CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
		--ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN -- prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   END IF;
	 END IF;

	 IF PRM_DELIVERY_CHANNEL = '02' THEN
	   IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
		IF PRM_TXN_AMT IS NULL THEN
		  V_POS_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999999.99'));
		ELSE
		  V_POS_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
								    '99999999999999999.99'));
		END IF;

		V_POS_USAGELIMIT := 1;

		IF PRM_TXN_CODE = '11' AND PRM_MSG = '0100' THEN
		  V_PREAUTH_USAGE_LIMIT := 1;
		  V_POS_USAGEAMNT       := 0;
		ELSE
		  V_PREAUTH_USAGE_LIMIT := 0;
		END IF;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_POSUSAGE_AMT       = V_POS_USAGEAMNT,
			  CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
			  CTC_ATMUSAGE_AMT       = 0,
			  CTC_ATMUSAGE_LIMIT     = 0,
			  CTC_BUSINESS_DATE      = TO_DATE(PRM_TRAN_DATE ||
										'23:59:59',
										'yymmdd' || 'hh24:mi:ss'),
			  CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN -- prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   ELSE
		V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

		IF PRM_TXN_CODE = '11' AND PRM_MSG = '0100' THEN
		  V_PREAUTH_USAGE_LIMIT := V_PREAUTH_USAGE_LIMIT + 1;
		  V_POS_USAGEAMNT       := V_POS_USAGEAMNT;
		ELSE
		  IF PRM_TXN_AMT IS NULL THEN
		    V_POS_USAGEAMNT := V_POS_USAGEAMNT +
						   TRIM(TO_CHAR(0, '99999999999999999.99'));
		  ELSE
		    V_POS_USAGEAMNT := V_POS_USAGEAMNT +
						   TRIM(TO_CHAR(V_TRAN_AMT,
									 '99999999999999999.99'));
		  END IF;
		END IF;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_POSUSAGE_AMT   = V_POS_USAGEAMNT,
			  CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
			  -- ctc_business_date =TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss'),
			  CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN --prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   END IF;
	 END IF;
    END;
  END;

  BEGIN
    SELECT CMS_ISO_RESPCDE
	 INTO PRM_RESP_CODE
	 FROM CMS_RESPONSE_MAST
	WHERE CMS_INST_CODE = PRM_INST_CODE AND
		 CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL AND
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
	  WHERE CTC_INST_CODE = PRM_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN --prm_card_no
		   AND CTC_MBR_NUMB = PRM_MBR_NUMB;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
				  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
	   V_RESP_CDE := '21';
	   RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
	 IF PRM_DELIVERY_CHANNEL = '01' THEN
	   IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
		V_ATM_USAGEAMNT  := 0;
		V_ATM_USAGELIMIT := 1;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_ATMUSAGE_AMT       = V_ATM_USAGEAMNT,
			  CTC_ATMUSAGE_LIMIT     = V_ATM_USAGELIMIT,
			  CTC_POSUSAGE_AMT       = 0,
			  CTC_POSUSAGE_LIMIT     = 0,
			  CTC_PREAUTHUSAGE_LIMIT = 0,
			  CTC_BUSINESS_DATE      = TO_DATE(PRM_TRAN_DATE ||
										'23:59:59',
										'yymmdd' || 'hh24:mi:ss')
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN ---prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   ELSE
		V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
		--ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN --prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   END IF;
	 END IF;

	 IF PRM_DELIVERY_CHANNEL = '02' THEN
	   IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
		V_POS_USAGEAMNT       := 0;
		V_POS_USAGELIMIT      := 1;
		V_PREAUTH_USAGE_LIMIT := 0;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_POSUSAGE_AMT       = V_POS_USAGEAMNT,
			  CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
			  CTC_ATMUSAGE_AMT       = 0,
			  CTC_ATMUSAGE_LIMIT     = 0,
			  CTC_BUSINESS_DATE      = TO_DATE(PRM_TRAN_DATE ||
										'23:59:59',
										'yymmdd' || 'hh24:mi:ss'),
			  CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN -- prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   ELSE
		V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
		--  ctc_business_date =TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN --prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   END IF;
	 END IF;
    END;

    --Sn select response code and insert record into txn log dtl
    BEGIN
	 PRM_RESP_MSG  := V_ERR_MSG;
	 PRM_RESP_CODE := V_RESP_CDE;

	 -- Assign the response code to the out parameter
	 SELECT CMS_ISO_RESPCDE
	   INTO PRM_RESP_CODE
	   FROM CMS_RESPONSE_MAST
	  WHERE CMS_INST_CODE = PRM_INST_CODE AND
		   CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL AND
		   CMS_RESPONSE_ID = V_RESP_CDE;
    EXCEPTION
	 WHEN OTHERS THEN
	   PRM_RESP_MSG  := 'Problem while selecting data from response master ' ||
					V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
	   PRM_RESP_CODE := '69';
	   ---ISO MESSAGE FOR DATABASE ERROR Server Declined
	   ROLLBACK;
	   -- RETURN;
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
	   (PRM_DELIVERY_CHANNEL,
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
	    V_ERR_MSG,
	    PRM_RRN,
	    PRM_STAN,
	    PRM_INST_CODE,
	    V_ENCR_PAN);

	 PRM_RESP_MSG := V_ERR_MSG;
    EXCEPTION
	 WHEN OTHERS THEN
	   PRM_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
					SUBSTR(SQLERRM, 1, 300);
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
		   CTC_PREAUTHUSAGE_LIMIT
	   INTO V_ATM_USAGELIMIT,
		   V_POS_USAGELIMIT,
		   V_BUSINESS_DATE_TRAN,
		   V_PREAUTH_USAGE_LIMIT
	   FROM CMS_TRANSLIMIT_CHECK
	  WHERE CTC_INST_CODE = PRM_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN -- prm_card_no
		   AND CTC_MBR_NUMB = PRM_MBR_NUMB;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
				  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
	   V_RESP_CDE := '21';
	   RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
	 IF PRM_DELIVERY_CHANNEL = '01' THEN
	   IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
		V_ATM_USAGEAMNT  := 0;
		V_ATM_USAGELIMIT := 1;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_ATMUSAGE_AMT       = V_ATM_USAGEAMNT,
			  CTC_ATMUSAGE_LIMIT     = V_ATM_USAGELIMIT,
			  CTC_POSUSAGE_AMT       = 0,
			  CTC_POSUSAGE_LIMIT     = 0,
			  CTC_PREAUTHUSAGE_LIMIT = 0,
			  CTC_BUSINESS_DATE      = TO_DATE(PRM_TRAN_DATE ||
										'23:59:59',
										'yymmdd' || 'hh24:mi:ss')
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN --prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   ELSE
		V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
		-- ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN --prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   END IF;
	 END IF;

	 IF PRM_DELIVERY_CHANNEL = '02' THEN
	   IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
		V_POS_USAGEAMNT       := 0;
		V_POS_USAGELIMIT      := 1;
		V_PREAUTH_USAGE_LIMIT := 0;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_POSUSAGE_AMT       = V_POS_USAGEAMNT,
			  CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
			  CTC_ATMUSAGE_AMT       = 0,
			  CTC_ATMUSAGE_LIMIT     = 0,
			  CTC_BUSINESS_DATE      = TO_DATE(PRM_TRAN_DATE ||
										'23:59:59',
										'yymmdd' || 'hh24:mi:ss'),
			  CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN --prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   ELSE
		V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

		UPDATE CMS_TRANSLIMIT_CHECK
		   SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
		--  ctc_business_date =TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
		 WHERE CTC_INST_CODE = PRM_INST_CODE AND
			  CTC_PAN_CODE = V_HASH_PAN -- prm_card_no
			  AND CTC_MBR_NUMB = PRM_MBR_NUMB;
	   END IF;
	 END IF;
    END;

    --Sn select response code and insert record into txn log dtl
    BEGIN
	 SELECT CMS_ISO_RESPCDE
	   INTO PRM_RESP_CODE
	   FROM CMS_RESPONSE_MAST
	  WHERE CMS_INST_CODE = PRM_INST_CODE AND
		   CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL AND
		   CMS_RESPONSE_ID = V_RESP_CDE;

	 PRM_RESP_MSG := V_ERR_MSG;
    EXCEPTION
	 WHEN OTHERS THEN
	   PRM_RESP_MSG  := 'Problem while selecting data from response master ' ||
					V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
	   PRM_RESP_CODE := '69'; -- Server Declined
	   ROLLBACK;
	   -- RETURN;
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
	   (PRM_DELIVERY_CHANNEL,
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
	    V_ERR_MSG,
	    PRM_RRN,
	    PRM_STAN,
	    PRM_INST_CODE,
	    V_ENCR_PAN);
    EXCEPTION
	 WHEN OTHERS THEN
	   PRM_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
					SUBSTR(SQLERRM, 1, 300);
	   PRM_RESP_CODE := '69'; -- Server Decline Response 220509
	   ROLLBACK;
	   RETURN;
    END;
    --En select response code and insert record into txn log dtl
END;
/


