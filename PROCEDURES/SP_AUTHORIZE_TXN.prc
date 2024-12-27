CREATE OR REPLACE PROCEDURE VMSCMS.SP_AUTHORIZE_TXN(P_INST_CODE         IN NUMBER,
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
									P_INS_USER          IN NUMBER,
									P_INS_DATE          IN DATE,
									P_AUTH_ID           OUT VARCHAR2,
									P_RESP_CODE         OUT VARCHAR2,
									P_RESP_MSG          OUT VARCHAR2,
									P_CAPTURE_DATE      OUT DATE) IS
  /*************************************************
     * Modified By      :  Narayanan
      * Modified Date    :  14-07-2012
      * Modified Reason  :  To decrease the length of authid
      * Reviewer         :  B.Besky Anand.
      * Reviewed Date    :  14-07-2012
      * Build Number     :  CMS3.5.1_RI0011_B0011 
  *************************************************/
  V_ERR_MSG          VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE     NUMBER;
  V_TRAN_AMT         NUMBER := 0;
  V_AUTH_ID          TRANSACTIONLOG.AUTH_ID%TYPE;
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
  P_ERR_MSG          VARCHAR2(500);
  V_PRECHECK_FLAG    NUMBER;
  V_PREAUTH_FLAG     NUMBER;
  --V_AVAIL_PAN        CMS_AVAIL_TRANS.CAT_PAN_CODE%TYPE;
  V_GL_UPD_FLAG      TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_GL_ERR_MSG       VARCHAR2(500);
  V_SAVEPOINT        NUMBER := 0;
  V_TRAN_FEE         NUMBER;
  V_ERROR            VARCHAR2(500);
  V_BUSINESS_DATE    DATE;
  V_BUSINESS_TIME    VARCHAR2(5);
  V_CUTOFF_TIME      VARCHAR2(5);
  V_CARD_CURR        VARCHAR2(5);
  V_FEE_CODE         CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_CRGL_CATG    CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRGL_CODE    CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRSUBGL_CODE CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO    CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG    CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE    CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO    CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  V_FUNC_CHECK       NUMBER(1);
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
  V_WAIV_PERCNT        CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  V_ERR_WAIV           VARCHAR2(300);
  V_LOG_ACTUAL_FEE     NUMBER;
  V_LOG_WAIVER_AMT     NUMBER;
  V_AUTH_SAVEPOINT     NUMBER DEFAULT 0;
  V_ACTUAL_EXPRYDATE   DATE;
  V_TXN_TYPE           NUMBER(1);
  V_MINI_TOTREC        NUMBER(2);
  V_MINISTMT_ERRMSG    VARCHAR2(500);
  V_MINISTMT_OUTPUT    VARCHAR2(900);
  EXP_REJECT_RECORD EXCEPTION;
  V_HASH_PAN    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN    CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_PROXUNUMBER CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_AUTHID_DATE VARCHAR2(8);

BEGIN
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE := '1';
  P_ERR_MSG  := 'OK';
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
	   V_RESP_CDE := '21';
	   V_ERR_MSG  := 'Institute code cannot be null ' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
	 END IF;
    EXCEPTION
	 WHEN EXP_REJECT_RECORD THEN
	   RAISE;
	 WHEN OTHERS THEN
	   V_RESP_CDE := '21';
	   V_ERR_MSG  := 'Institute code cannot be null ' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;
  
    --eN CHECK INST CODE
  
    --Sn check txn currency
    BEGIN
	 IF TRIM(P_CURR_CODE) IS NULL THEN
	   V_RESP_CDE := '21';
	   V_ERR_MSG  := 'Transaction currency  cannot be null ' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
	 END IF;
    EXCEPTION
	 WHEN EXP_REJECT_RECORD THEN
	   RAISE;
	 WHEN OTHERS THEN
	   V_RESP_CDE := '21';
	   V_ERR_MSG  := 'Transcurrency cannot be null ' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;
  
    --En check txn currency
  
    --Sn check Merchant
  
    --En check Merchant
  
    --Sn get date
    BEGIN
	 V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
					    SUBSTR(TRIM(P_TRAN_TIME), 1, 10),
					    'yyyymmdd hh24:mi:ss');
    EXCEPTION
	 WHEN OTHERS THEN
	   V_RESP_CDE := '21';
	   V_ERR_MSG  := 'Problem while converting transaction date ' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;
  
    --En get date
    --Sn find service tax
    BEGIN
	 SELECT CIP_PARAM_VALUE
	   INTO V_SERVICETAX_PERCENT
	   FROM CMS_INST_PARAM
	  WHERE CIP_INST_CODE = P_INST_CODE AND CIP_PARAM_KEY = 'SERVICETAX';
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
	  WHERE CIP_INST_CODE = P_INST_CODE AND CIP_PARAM_KEY = 'CESS';
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
	  WHERE CIP_INST_CODE = P_INST_CODE AND CIP_PARAM_KEY = 'CUTOFF';
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
  
    --Sn find the tran amt
    IF P_TXN_AMT <> 0 THEN
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
    END IF;
  
    --En find the tran amt
  
    --Sn select authorization processe flag
    BEGIN
	 SELECT PTP_PARAM_VALUE
	   INTO V_PRECHECK_FLAG
	   FROM PCMS_TRANAUTH_PARAM
	  WHERE PTP_INST_CODE = P_INST_CODE AND PTP_PARAM_NAME = 'PRE CHECK';
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
	  WHERE PTP_INST_CODE = P_INST_CODE AND PTP_PARAM_NAME = 'PRE AUTH';
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_RESP_CDE := '21'; --only for master setups
	   V_ERR_MSG  := 'Master set up is not done for Authorization Process';
	   RAISE EXP_REJECT_RECORD;
	 WHEN OTHERS THEN
	   V_RESP_CDE := '21'; --only for master setups
	   V_ERR_MSG  := 'Error while selecting PCMS_TRANAUTH_PARAM' ||
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
	  WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_RESP_CDE := '16'; --Ineligible Transaction
	   V_ERR_MSG  := 'Card number not found ' || P_TXN_CODE;
	   RAISE EXP_REJECT_RECORD;
	 WHEN OTHERS THEN
	   V_RESP_CDE := '12';
	   V_ERR_MSG  := 'Problem while selecting card detail' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;
  
    --En find card detail
    --Sn check expry date
    BEGIN
	 IF TRIM(P_EXPRY_DATE) IS NOT NULL THEN
	   V_EXPRY_DATE := LAST_DAY(TO_DATE('01' || P_EXPRY_DATE ||
								 ' 23:59:59',
								 'ddyymm hh24:mi:ss'));
	 END IF;
    EXCEPTION
	 WHEN OTHERS THEN
	   V_ERR_MSG  := 'Problem while converting expry date ' ||
				  SUBSTR(SQLERRM, 1, 300);
	   V_RESP_CDE := '23'; ---ISO MESSAGE FOR DATABASE ERROR
	   RAISE EXP_REJECT_RECORD;
    END;
  
    --En check expry date
  
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
					   P_TXN_AMT,
					   P_DELIVERY_CHANNEL,
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
		V_ERR_MSG  := 'Error from pre_auth process ' ||
				    SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;
    END IF;
  
    --En check for preauth
  
    --Sn find debit and credit flag
    BEGIN
	 SELECT CTM_CREDIT_DEBIT_FLAG,
		   CTM_OUTPUT_TYPE,
		   TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1'))
	   INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE
	   FROM CMS_TRANSACTION_MAST
	  WHERE CTM_INST_CODE = P_INST_CODE AND CTM_TRAN_CODE = P_TXN_CODE AND
		   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_RESP_CDE := '21'; --Ineligible Transaction
	   V_ERR_MSG  := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
				  ' and delivery channel ' || P_DELIVERY_CHANNEL;
	   RAISE EXP_REJECT_RECORD;
	 WHEN OTHERS THEN
	   V_RESP_CDE := '21'; --Ineligible Transaction
	   V_ERR_MSG  := 'Error while selecting transflag ' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;
  
    --En find debit and credit flag
    --Sn find function code attached to txn code
    BEGIN
	 SELECT CFM_FUNC_CODE
	   INTO V_FUNC_CODE
	   FROM CMS_FUNC_MAST
	  WHERE CFM_INST_CODE = P_INST_CODE AND CFM_TXN_CODE = P_TXN_CODE AND
		   CFM_TXN_MODE = P_TXN_MODE AND
		   CFM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
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
	   V_ERR_MSG  := 'Error while selecting func code' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;
  
    --En find function code attached to txn code
    BEGIN
	 SELECT 1
	   INTO V_FUNC_CHECK
	   FROM CMS_FUNC_PROD
	  WHERE CFP_INST_CODE = P_INST_CODE AND CFP_PROD_CODE = V_PROD_CODE AND
		   CFP_FUNC_CODE = V_FUNC_CODE AND
		   CFP_PROD_CATTYPE = V_PROD_CATTYPE;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_RESP_CDE := '21'; --Ineligible Transaction
	   V_ERR_MSG  := 'Function code ' || V_FUNC_CODE ||
				  ' not attached to product ' || V_PROD_CODE ||
				  ' and card type ' || V_PROD_CATTYPE;
	   RAISE EXP_REJECT_RECORD;
	 WHEN TOO_MANY_ROWS THEN
	   V_RESP_CDE := '21';
	   V_ERR_MSG  := 'Error while selecting func prod detail from master ' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
	 WHEN OTHERS THEN
	   V_RESP_CDE := '21';
	   V_ERR_MSG  := 'Error while selecting func prod detail from master ' ||
				  SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;
  
    --Sn find prod code and card type and available balance for the card number
    BEGIN
	 SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
	   INTO V_ACCT_BALANCE, V_UPD_LEDGER_AMT
	   FROM CMS_ACCT_MAST
	  WHERE CAM_INST_CODE = P_INST_CODE AND
		   CAM_ACCT_NO =
		   (SELECT CAP.CAP_ACCT_NO
			 FROM CMS_APPL_PAN CAP
			WHERE CAP.CAP_PAN_CODE = GETHASH(P_CARD_NO))
	    FOR UPDATE NOWAIT;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_RESP_CDE := '24'; --Ineligible Transaction
	   V_ERR_MSG  := 'Invalid Account ';
	   RAISE EXP_REJECT_RECORD;
	 WHEN OTHERS THEN
	   V_RESP_CDE := '21';
	   V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
				  P_CARD_NO || SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_REJECT_RECORD;
    END;
  
    --En find prod code and card type for the card number
    --Sn find fees amount attaced to func code, prod_code and card type
  
    ---Sn dynamic fee calculation .
    BEGIN
	 SP_TRAN_FEES(P_INST_CODE,
			    P_CARD_NO,
			    P_DELIVERY_CHANNEL,
			    V_TXN_TYPE,
			    P_TXN_MODE,
			    P_TXN_CODE,
			    P_CURR_CODE,
			    P_CONSODIUM_CODE,
			    P_PARTNER_CODE,
			    V_TRAN_AMT,
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
			    V_CESS_DRACCT_NO);
    
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
  
    --Sn find total transaction   amount
    IF V_DR_CR_FLAG = 'CR' THEN
	 V_TOTAL_AMT      := V_TRAN_AMT - V_TOTAL_FEE;
	 V_UPD_AMT        := V_ACCT_BALANCE + V_TOTAL_AMT;
	 V_UPD_LEDGER_AMT := V_UPD_LEDGER_AMT + V_TOTAL_AMT;
    ELSIF V_DR_CR_FLAG = 'DR' THEN
	 V_TOTAL_AMT      := V_TRAN_AMT + V_TOTAL_FEE;
	 V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
	 V_UPD_LEDGER_AMT := V_UPD_LEDGER_AMT - V_TOTAL_AMT;
    ELSIF V_DR_CR_FLAG = 'NA' THEN
	 V_TOTAL_AMT      := V_TOTAL_FEE;
	 V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
	 V_UPD_LEDGER_AMT := V_UPD_LEDGER_AMT - V_TOTAL_AMT;
    ELSE
	 V_RESP_CDE := '12'; --Ineligible Transaction
	 V_ERR_MSG  := 'Invalid transflag    txn code ' || P_TXN_CODE;
	 RAISE EXP_REJECT_RECORD;
    END IF;
  
    --En find total transaction   amout
    --Sn check balance
    IF V_UPD_AMT < 0 THEN
	 V_RESP_CDE := '25'; --Ineligible Transaction
	 V_ERR_MSG  := 'Insufficent Balance ';
	 RAISE EXP_REJECT_RECORD;
    END IF;
  
    --En check balance
    --Sn create gl entries and acct update
    BEGIN
	 SP_UPDATE_TRANSACTION_ACCOUNT(P_INST_CODE,
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
							 P_INS_USER,
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
	  WHERE CTM_INST_CODE = P_INST_CODE AND CTM_TRAN_CODE = P_TXN_CODE AND
		   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
    EXCEPTION
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
		 CSL_LUPD_DATE,
		 CSL_INST_CODE,
		 CSL_LUPD_USER,
		 CSL_INS_DATE,
		 CSL_INS_USER,
		 CSL_PAN_NO_ENCR,
		 CSL_PANNO_LAST4DIGIT) --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
	   
	   VALUES
		(V_HASH_PAN,
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
		 P_INS_DATE,
		 P_INST_CODE,
		 P_INS_USER,
		 P_INS_DATE,
		 P_INS_USER,
		 V_ENCR_PAN,
		 (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO)))); --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
	 EXCEPTION
	   WHEN OTHERS THEN
		V_RESP_CDE := '21';
		V_ERR_MSG  := 'Problem while inserting into statement log for tran amt ' ||
				    SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	 END;
    
	 BEGIN
	   SP_DAILY_BIN_BAL(P_CARD_NO,
					V_TRAN_DATE,
					V_TRAN_AMT,
					V_DR_CR_FLAG,
					P_INST_CODE,
					P_BANK_CODE,
					V_ERR_MSG);
	   IF V_ERR_MSG <> 'OK' THEN
		V_RESP_CDE := '21';
		V_ERR_MSG  := 'Problem while calling SP_DAILY_BIN_BAL ' ||
				    SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_REJECT_RECORD;
	   END IF;
	 EXCEPTION
	   WHEN OTHERS THEN
		V_RESP_CDE := '21';
		V_ERR_MSG  := 'Problem while calling SP_DAILY_BIN_BAL ' ||
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
		V_RESP_CDE := '21';
		V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
				    P_CARD_NO;
		RAISE EXP_REJECT_RECORD;
	 END;
    
	 --En find fee opening balance
	 --Sn create entries for FEES attached
	 --FOR I IN C LOOP
	 BEGIN
	   INSERT INTO CMS_STATEMENTS_LOG
		(CSL_PAN_NO,
		 CSL_OPENING_BAL,
		 CSL_TRANS_AMOUNT,
		 CSL_TRANS_TYPE,
		 CSL_TRANS_DATE,
		 CSL_CLOSING_BALANCE,
		 CSL_TRANS_NARRRATION,
		 CSL_LUPD_DATE,
		 CSL_INST_CODE,
		 CSL_LUPD_USER,
		 CSL_INS_DATE,
		 CSL_INS_USER,
		 CSL_PAN_NO_ENCR,
		 CSL_PANNO_LAST4DIGIT) --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
	   VALUES
		(V_HASH_PAN,
		 V_FEE_OPENING_BAL,
		 V_TOTAL_FEE,
		 'DR',
		 V_TRAN_DATE,
		 V_FEE_OPENING_BAL - V_TOTAL_FEE,
		 'Fee debited for ' || V_NARRATION,
		 P_INS_DATE,
		 P_INST_CODE,
		 P_INS_USER,
		 P_INS_DATE,
		 P_INS_USER,
		 V_ENCR_PAN,
		 (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO)))); --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
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
	    CTD_CUSTOMER_CARD_NO_ENCR)
	 VALUES
	   (P_DELIVERY_CHANNEL,
	    P_TXN_CODE,
	    V_TXN_TYPE,
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
	    V_ENCR_PAN);
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
	 /* SELECT CAT_PAN_CODE
       INTO V_AVAIL_PAN
       FROM CMS_AVAIL_TRANS
      WHERE CAT_INST_CODE = P_INST_CODE AND CAT_PAN_CODE = V_HASH_PAN
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
	  WHERE CAT_INST_CODE = P_INST_CODE AND CAT_PAN_CODE = V_HASH_PAN AND
		   CAT_TRAN_CODE = P_TXN_CODE AND CAT_TRAN_MODE = P_TXN_MODE;
    
	 /*IF SQL%ROWCOUNT = 0 THEN
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
	 --Balance Inquiry
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
    ---
  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
	 ROLLBACK TO V_AUTH_SAVEPOINT;
	 BEGIN
	   SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
		INTO V_ACCT_BALANCE, V_UPD_LEDGER_AMT
		FROM CMS_ACCT_MAST
	    WHERE CAM_ACCT_NO =
			(SELECT CAP_ACCT_NO
			   FROM CMS_APPL_PAN
			  WHERE CAP_PAN_CODE = V_HASH_PAN AND
				   CAP_INST_CODE = P_INST_CODE) AND
			CAM_INST_CODE = P_INST_CODE;
	 EXCEPTION
	   WHEN OTHERS THEN
		V_ACCT_BALANCE   := 0;
		V_UPD_LEDGER_AMT := 0;
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
		P_RESP_CODE := '99'; ---ISO MESSAGE FOR DATABASE ERROR
		ROLLBACK TO V_AUTH_SAVEPOINT;
		RETURN;
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
		 CTD_CUSTOMER_CARD_NO_ENCR)
	   VALUES
		(P_DELIVERY_CHANNEL,
		 P_TXN_CODE,
		 V_TXN_TYPE,
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
		 V_ENCR_PAN);
	 
	   P_RESP_MSG := V_ERR_MSG;
	 EXCEPTION
	   WHEN OTHERS THEN
		P_RESP_CODE := '99';
		P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
					SUBSTR(SQLERRM, 1, 300);
		ROLLBACK TO V_AUTH_SAVEPOINT;
		RETURN;
	 END;
    WHEN OTHERS THEN
	 ROLLBACK TO V_AUTH_SAVEPOINT;
    
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
		P_RESP_CODE := '99';
		ROLLBACK TO V_AUTH_SAVEPOINT;
		RETURN;
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
		 CTD_CUSTOMER_CARD_NO_ENCR)
	   VALUES
		(P_DELIVERY_CHANNEL,
		 P_TXN_CODE,
		 V_TXN_TYPE,
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
		 V_ENCR_PAN);
	 EXCEPTION
	   WHEN OTHERS THEN
		P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
					SUBSTR(SQLERRM, 1, 300);
		P_RESP_CODE := '99';
		ROLLBACK TO V_AUTH_SAVEPOINT;
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
	 SP_CREATE_GL_ENTRIES(P_INST_CODE,
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
					  P_INS_USER,
					  V_RESP_CDE,
					  V_GL_UPD_FLAG,
					  V_GL_ERR_MSG);
    
	 IF V_GL_ERR_MSG <> 'OK' OR V_GL_UPD_FLAG <> 'Y' THEN
	   ROLLBACK TO V_SAVEPOINT;
	   V_GL_UPD_FLAG := 'N';
	 END IF;
    EXCEPTION
	 WHEN OTHERS THEN
	   ROLLBACK TO V_SAVEPOINT;
	   V_GL_UPD_FLAG := 'N';
    END;
  END IF;

  --En create GL ENTRIES
  --Sn generate auth id
  BEGIN
    --    SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;
  
    --   SELECT V_AUTHID_DATE || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
    SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
  EXCEPTION
    WHEN OTHERS THEN
	 P_RESP_MSG  := 'Error while generating authid ' ||
				 SUBSTR(SQLERRM, 1, 300);
	 P_RESP_CODE := '21';
	 ROLLBACK TO V_SAVEPOINT; --changed on 230909
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
	  ADD_LUPD_DATE,
	  ADD_LUPD_USER,
	  ADD_INS_DATE,
	  ADD_INS_USER,
	  TRAN_CURR,
	  CUSTOMER_CARD_NO_ENCR,
	  TOPUP_CARD_NO_ENCR,
	  PROXY_NUMBER,
	  REVERSAL_CODE,
	  CUSTOMER_ACCT_NO,
	  ACCT_BALANCE,
	  LEDGER_BALANCE,
	  RESPONSE_ID,
	  CARDSTATUS --Added cardstatus insert in transactionlog by srinivasu.k
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
	  NULL, --P_topup_acctno ,
	  NULL, --P_topup_accttype,
	  P_BANK_CODE,
	  V_TOTAL_AMT,
	  P_RULE_INDICATOR,
	  P_RULEGRP_ID,
	  P_MCC_CODE,
	  P_CURR_CODE,
	  NULL,
	  V_PROD_CODE,
	  V_PROD_CATTYPE,
	  P_TIP_AMT,
	  P_DECLINE_RULEID,
	  P_ATMNAME_LOC,
	  V_AUTH_ID,
	  V_NARRATION,
	  V_TRAN_AMT,
	  NULL, --- PRE AUTH AMOUNT
	  NULL,
	  -- Partial amount (will be given for partial txn)
	  P_MCCCODE_GROUPID,
	  P_CURRCODE_GROUPID,
	  P_TRANSCODE_GROUPID,
	  P_RULES,
	  P_PREAUTH_DATE,
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
	  P_INS_DATE,
	  P_INS_USER,
	  P_INS_DATE,
	  P_INS_USER,
	  P_CURR_CODE,
	  V_ENCR_PAN,
	  NULL,
	  V_PROXUNUMBER,
	  0,
	  V_ACCT_NUMBER,
	  V_UPD_AMT,
	  V_UPD_LEDGER_AMT,
	  P_RESP_CODE,
	  V_APPLPAN_CARDSTAT --Added cardstatus insert in transactionlog by srinivasu.k
	  );
  
    DBMS_OUTPUT.PUT_LINE('AFTER INSERT IN TRANSACTIONLOG');
    P_CAPTURE_DATE := V_BUSINESS_DATE;
    P_AUTH_ID      := V_AUTH_ID;
  EXCEPTION
    WHEN OTHERS THEN
	 ROLLBACK TO V_SAVEPOINT; --changed on 230909;
	 P_RESP_CODE := '99';
	 P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
				 SUBSTR(SQLERRM, 1, 300);
  END;
  --En create a entry in txn log
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO V_SAVEPOINT; --changed on 230909;
    P_RESP_CODE := '99';
    P_RESP_MSG  := 'Main exception from  authorization ' ||
			    SUBSTR(SQLERRM, 1, 300);
END;
/
SHOW ERROR;
