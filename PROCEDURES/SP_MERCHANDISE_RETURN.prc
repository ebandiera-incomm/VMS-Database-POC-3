CREATE OR REPLACE PROCEDURE VMSCMS.SP_MERCHANDISE_RETURN(PRM_INSTCODE   IN NUMBER,
										PRM_RRN        IN VARCHAR2,
										PRM_TERMINALID IN VARCHAR2,
										PRM_STAN       IN VARCHAR2,
										PRM_TRANDATE   IN VARCHAR2,
										PRM_TRANTIME   IN VARCHAR2,
										PRM_ACCTNO     IN VARCHAR2, ---PAN
										-- prm_filename       IN       VARCHAR2,--not needed
										-- prm_remrk          IN       VARCHAR2,--not needed
										-- prm_resoncode      IN       NUMBER,--not needed
										PRM_AMOUNT IN NUMBER,
										-- prm_refno          IN       VARCHAR2,
										-- prm_paymentmode    IN       VARCHAR2,
										--prm_instrumentno   IN       VARCHAR2,
										-- prm_drawndate      IN       DATE,
										PRM_CURRCODE         IN VARCHAR2,
										PRM_LUPDUSER         IN NUMBER,
										PRM_MSG              IN VARCHAR2,
										PRM_TXN_CODE         VARCHAR2,
										PRM_TXN_MODE         VARCHAR2,
										PRM_DELIVERY_CHANNEL VARCHAR2,
										PRM_MBR_NUMB         IN VARCHAR2,
										PRM_RVSL_CODE        IN VARCHAR2,
										PRM_RESP_CODE        OUT VARCHAR2,
										PRM_ERRMSG           OUT VARCHAR2) AS
  V_CAP_PROD_CATG     CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  V_CAP_CARD_STAT     CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG   CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  V_CAP_APPL_CODE     CMS_APPL_PAN.CAP_APPL_CODE%TYPE;
  V_FIRSTTIME_TOPUP   CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_PROD_CODE         CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE         CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_PROFILE_CODE      CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  V_ERRMSG            VARCHAR2(300);
  V_VARPRODFLAG       CMS_PROD_MAST.CPM_VAR_FLAG%TYPE;
  V_CURRCODE          VARCHAR2(3);
  V_APPL_CODE         CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_RESONCODE         CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_RESPCODE          VARCHAR2(5);
  V_RESPMSG           VARCHAR2(500);
  V_CAPTURE_DATE      DATE;
  V_MBRNUMB           CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_TXN_CODE          CMS_FUNC_MAST.CFM_TXN_CODE%TYPE;
  V_TXN_MODE          CMS_FUNC_MAST.CFM_TXN_MODE%TYPE;
  V_DEL_CHANNEL       CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE;
  V_TXN_TYPE          CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_TOPUP_AUTH_ID     TRANSACTIONLOG.AUTH_ID%TYPE;
  V_MIN_MAX_LIMIT     VARCHAR2(50);
  V_ACCT_TXN_DTL      CMS_TOPUPTRANS_COUNT.CTC_TOTAVAIL_DAYS%TYPE;
  V_TOPUP_FREQ        VARCHAR2(50);
  V_TOPUP_FREQ_PERIOD VARCHAR2(50);
  V_END_LUPD_DATE     CMS_TOPUPTRANS_COUNT.CTC_LUPD_DATE%TYPE;
  V_ACCT_TXN_DTL_1    CMS_TOPUPTRANS_COUNT.CTC_TOTAVAIL_DAYS%TYPE;
  V_END_DAY_UPDATE    CMS_TOPUPTRANS_COUNT.CTC_LUPD_DATE%TYPE;
  V_MIN_LIMIT         VARCHAR2(50);
  V_MAX_LIMIT         VARCHAR2(50);
  V_RRN_COUNT         NUMBER;
  EXP_MAIN_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  V_HASH_PAN        CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN        CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_BUSINESS_DATE   DATE;
  V_TRAN_DATE       DATE;
  V_TOPUPREMRK      VARCHAR2(100);
  V_ACCT_BALANCE    NUMBER;
  V_TRAN_AMT        NUMBER;
  V_DELCHANNEL_CODE VARCHAR2(2);
  V_CARD_CURR       VARCHAR2(5);
  V_DATE            DATE;
  V_BASE_CURR       CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_LEDGER_BAL      NUMBER;
BEGIN
  --<<MAIN BEGIN >>
  PRM_ERRMSG   := 'OK';
  V_TOPUPREMRK := 'Online Card Topup';
  /* IF prm_remrk IS NULL
  THEN
     v_errmsg := 'Please enter appropriate remrk';
     RAISE exp_main_reject_record;
  END IF;*/

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(PRM_ACCTNO);
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(PRM_ACCTNO);
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN create encr pan

  ------------Sn check topup amount -------------------
  /*IF prm_amount < 200 OR prm_amount > 1000 THEN

   v_errmsg := 'Invalid amount for TOPUP : should be between 200 and 1000';
   RAISE exp_main_reject_record;

  END IF;*/

  ------------En check topup amount -------------------

  --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return

  BEGIN

    SELECT COUNT(1)
	 INTO V_RRN_COUNT
	 FROM TRANSACTIONLOG
	WHERE TERMINAL_ID = PRM_TERMINALID AND RRN = PRM_RRN AND
		 BUSINESS_DATE = PRM_TRANDATE;

    IF V_RRN_COUNT > 0 THEN
	 V_RESPCODE := '22';
	 V_ERRMSG   := 'Duplicate RRN from the Treminal' || PRM_TERMINALID || 'on' ||
				PRM_TRANDATE;
	 RAISE EXP_MAIN_REJECT_RECORD;

    END IF;

  END;

  --En Duplicate RRN Check

  --Sn select Pan detail
  BEGIN
    SELECT CAP_CARD_STAT,
		 CAP_PROD_CATG,
		 CAP_CAFGEN_FLAG,
		 CAP_APPL_CODE,
		 CAP_FIRSTTIME_TOPUP,
		 CAP_MBR_NUMB,
		 CAP_PROD_CODE,
		 CAP_CARD_TYPE
	 INTO V_CAP_CARD_STAT,
		 V_CAP_PROD_CATG,
		 V_CAP_CAFGEN_FLAG,
		 V_APPL_CODE,
		 V_FIRSTTIME_TOPUP,
		 V_MBRNUMB,
		 V_PROD_CODE,
		 V_CARD_TYPE
	 FROM CMS_APPL_PAN
	WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = PRM_INSTCODE;

  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En select Pan detail

  --Sn check the min and max limit for topup
  BEGIN

    --Profile Code of Product

    SELECT CPM_PROFILE_CODE
	 INTO V_PROFILE_CODE
	 FROM CMS_PROD_MAST
	WHERE CPM_PROD_CODE = V_PROD_CODE AND CPM_INST_CODE = PRM_INSTCODE;

  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'profile_code not defined ' || V_PROFILE_CODE;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'profile_code not defined ' || V_PROFILE_CODE;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --Sn select variable type detail
  BEGIN
    SELECT CPM_VAR_FLAG
	 INTO V_VARPRODFLAG
	 FROM CMS_PROD_MAST A, CMS_APPL_PAN B
	WHERE CAP_PAN_CODE = V_HASH_PAN --prm_acctno
		 AND CPM_INST_CODE = CAP_INST_CODE AND
		 CPM_PROD_CODE = CAP_PROD_CODE;

    IF V_VARPRODFLAG <> 'V' THEN
	 V_RESPCODE := '17';
	 V_ERRMSG   := 'Top up is not applicable on this card number ' ||
				PRM_ACCTNO;
	 RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Card type (fixed/variable ) not defined for the card ' ||
				PRM_ACCTNO;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Error while selecting card number ' || PRM_ACCTNO;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En  select variable type detail
  --Sn Check initial load
  IF V_FIRSTTIME_TOPUP = 'N' THEN
    V_RESPCODE := '21';
    V_ERRMSG   := 'Topup is applicable only after initial load for this acctno ' ||
			   PRM_ACCTNO;
    RAISE EXP_MAIN_REJECT_RECORD;
  END IF;

  --En Check initial load

  BEGIN

    SELECT CDM_CHANNEL_CODE
	 INTO V_DELCHANNEL_CODE
	 FROM CMS_DELCHANNEL_MAST
	WHERE CDM_CHANNEL_DESC = 'MMPOS' AND CDM_INST_CODE = PRM_INSTCODE;
    --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr

    IF V_DELCHANNEL_CODE = PRM_DELIVERY_CHANNEL THEN

	 BEGIN
	   SELECT CIP_PARAM_VALUE
		INTO V_BASE_CURR
		FROM CMS_INST_PARAM
	    WHERE CIP_INST_CODE = PRM_INSTCODE AND CIP_PARAM_KEY = 'CURRENCY';

	   IF TRIM(V_BASE_CURR) IS NULL THEN
		V_ERRMSG := 'Base currency cannot be null ';
		RAISE EXP_MAIN_REJECT_RECORD;
	   END IF;
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		V_ERRMSG := 'Base currency is not defined for the institution ';
		RAISE EXP_MAIN_REJECT_RECORD;
	   WHEN OTHERS THEN
		V_ERRMSG := 'Error while selecting bese currecy  ' ||
				  SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_MAIN_REJECT_RECORD;
	 END;

	 V_CURRCODE := V_BASE_CURR;

    ELSE
	 V_CURRCODE := PRM_CURRCODE;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while selecting the Delivery Channel of MMPOS  ' ||
			   SUBSTR(SQLERRM, 1, 200);
	 RAISE EXP_MAIN_REJECT_RECORD;

  END;

  --Currency Conversion
  BEGIN

    V_DATE := TO_DATE(SUBSTR(TRIM(PRM_TRANDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
    WHEN OTHERS THEN
	 V_RESPCODE := '45'; -- Server Declined -220509
	 V_ERRMSG   := 'Problem while converting transaction date ' ||
				SUBSTR(SQLERRM, 1, 200);
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN

    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(PRM_TRANDATE), 1, 8) || ' ' ||
					  SUBSTR(TRIM(PRM_TRANTIME), 1, 10),
					  'yyyymmdd hh24:mi:ss');

  EXCEPTION
    WHEN OTHERS THEN
	 V_RESPCODE := '32'; -- Server Declined -220509
	 V_ERRMSG   := 'Problem while converting transaction time ' ||
				SUBSTR(SQLERRM, 1, 200);
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;
  BEGIN

    IF (PRM_AMOUNT > 0) THEN
	 V_TRAN_AMT := PRM_AMOUNT;

	 BEGIN
	   SP_CONVERT_CURR(PRM_INSTCODE,
				    V_CURRCODE,
				    PRM_ACCTNO,
				    PRM_AMOUNT,
				    V_TRAN_DATE,
				    V_TRAN_AMT,
				    V_CARD_CURR,
				    V_ERRMSG);

	   IF V_ERRMSG <> 'OK' THEN
		V_RESPCODE := '21';
		RAISE EXP_MAIN_REJECT_RECORD;
	   END IF;
	 EXCEPTION
	   WHEN EXP_MAIN_REJECT_RECORD THEN
		RAISE;
	   WHEN OTHERS THEN
		V_RESPCODE := '69'; -- Server Declined -220509
		V_ERRMSG   := 'Error from currency conversion ' ||
				    SUBSTR(SQLERRM, 1, 200);
		RAISE EXP_MAIN_REJECT_RECORD;
	 END;

    END IF;

  END;

  BEGIN
    SELECT COUNT(1)
	 INTO V_MIN_MAX_LIMIT
	 FROM CMS_BIN_PARAM A, CMS_BIN_PARAM B
	WHERE A.CBP_PROFILE_CODE = V_PROFILE_CODE AND
		 A.CBP_PROFILE_CODE = B.CBP_PROFILE_CODE AND
		 A.CBP_PARAM_TYPE = 'Topup Parameter' AND
		 A.CBP_PARAM_TYPE = B.CBP_PARAM_TYPE AND
		 A.CBP_INST_CODE = PRM_INSTCODE AND
		 A.CBP_INST_CODE = B.CBP_INST_CODE AND
		 A.CBP_PARAM_NAME = 'Min Topup Limit' AND
		 B.CBP_PARAM_NAME = 'Max Topup Limit' AND
		 V_TRAN_AMT BETWEEN A.CBP_PARAM_VALUE AND B.CBP_PARAM_VALUE;

    IF V_MIN_MAX_LIMIT = 0 THEN
	 SELECT A.CBP_PARAM_VALUE, B.CBP_PARAM_VALUE
	   INTO V_MIN_LIMIT, V_MAX_LIMIT
	   FROM CMS_BIN_PARAM A, CMS_BIN_PARAM B
	  WHERE A.CBP_PROFILE_CODE = V_PROFILE_CODE AND
		   A.CBP_PROFILE_CODE = B.CBP_PROFILE_CODE AND
		   A.CBP_PARAM_TYPE = 'Topup Parameter' AND
		   A.CBP_PARAM_TYPE = B.CBP_PARAM_TYPE AND
		   A.CBP_INST_CODE = PRM_INSTCODE AND
		   A.CBP_INST_CODE = B.CBP_INST_CODE AND
		   A.CBP_PARAM_NAME = 'Min Topup Limit' AND
		   B.CBP_PARAM_NAME = 'Max Topup Limit';

	 V_ERRMSG   := 'Topup Limit Exceeded.Limit is between' || V_MIN_LIMIT ||
				' TO ' || V_MAX_LIMIT;
	 V_RESPCODE := '34';
	 RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Topup Amount is out of range ' || V_MIN_LIMIT ||
				' TO ' || V_MAX_LIMIT;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Topup Amount is out of range ' || V_MIN_LIMIT ||
				' TO ' || V_MAX_LIMIT;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En check the min and max limit for topup

  --Sn select transaction code,mode and del channel
  /*BEGIN
     SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
       INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
       FROM CMS_FUNC_MAST
      WHERE cfm_func_code = 'TOP UP' AND cfm_inst_code=prm_instcode;
  EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       v_respcode :='21';
        v_errmsg := 'Support function Initial Load not defined in master';
        RAISE exp_main_reject_record;
     WHEN OTHERS
     THEN
        v_errmsg :=
              'Error while selecting support function detail '
           || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_main_reject_record;
  END;*/

  --En select transaction code,mode and del channel

  ----------------------------------------------------------------------------------------------------------

  --Sn Check The transaction availibillity in table
  BEGIN
    SELECT A.CBP_PARAM_VALUE, B.CBP_PARAM_VALUE
	 INTO V_TOPUP_FREQ, V_TOPUP_FREQ_PERIOD
	 FROM CMS_BIN_PARAM A, CMS_BIN_PARAM B
	WHERE A.CBP_PROFILE_CODE = V_PROFILE_CODE AND
		 A.CBP_PROFILE_CODE = B.CBP_PROFILE_CODE AND
		 A.CBP_PARAM_TYPE = 'Topup Parameter' AND
		 A.CBP_PARAM_TYPE = B.CBP_PARAM_TYPE AND
		 A.CBP_INST_CODE = PRM_INSTCODE AND
		 A.CBP_INST_CODE = B.CBP_INST_CODE AND
		 A.CBP_PARAM_NAME = 'Topup Freq Amount' AND
		 B.CBP_PARAM_NAME = 'Topup Freq Period';
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Freq and period is not defined ' || V_TOPUP_FREQ;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Freq and period is not defined  ' ||
				V_TOPUP_FREQ_PERIOD;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --------------------------------
  BEGIN
    SELECT COUNT(1)
	 INTO V_ACCT_TXN_DTL
	 FROM CMS_TOPUPTRANS_COUNT
	WHERE CTC_ACCT_NO = PRM_ACCTNO AND CTC_INST_CODE = PRM_INSTCODE;

    IF V_ACCT_TXN_DTL = 0 THEN
	 INSERT INTO CMS_TOPUPTRANS_COUNT
	 VALUES
	   (PRM_INSTCODE,
	    PRM_ACCTNO,
	    0,
	    PRM_LUPDUSER,
	    SYSDATE,
	    PRM_LUPDUSER,
	    SYSDATE);
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Topup Transaction Days are not specifid  ' ||
				V_ACCT_TXN_DTL;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Topup Transaction Days are not specifid  ' ||
				V_ACCT_TXN_DTL;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --------------------------------
  BEGIN
    SELECT CTC_TOTAVAIL_DAYS
	 INTO V_ACCT_TXN_DTL_1
	 FROM CMS_TOPUPTRANS_COUNT
	WHERE CTC_ACCT_NO = PRM_ACCTNO AND CTC_INST_CODE = PRM_INSTCODE;

    IF V_ACCT_TXN_DTL_1 >= V_TOPUP_FREQ THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Topup Transaction Days are over ' || V_ACCT_TXN_DTL_1;
	 RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Topup Transaction Days are not specifid  ' ||
				V_ACCT_TXN_DTL_1;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_RESPCODE := '21';
	 V_ERRMSG   := 'Topup Transaction Days are not specifid  ' ||
				V_ACCT_TXN_DTL_1;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --------------------------------

  --En Check The transaction availibillity in table
  ----------------------------------------------------------------------------------------------------------

  --------------Sn For Debit Card No need using authorization -----------------------------------
  IF V_CAP_PROD_CATG = 'P' THEN

    --Sn call to authorize txn
    BEGIN

	 SP_AUTHORIZE_TXN_CMS_AUTH(PRM_INSTCODE,
						  PRM_MSG,
						  PRM_RRN,
						  PRM_DELIVERY_CHANNEL,
						  PRM_TERMINALID,
						  PRM_TXN_CODE,
						  --v_txn_type,
						  PRM_TXN_MODE,
						  PRM_TRANDATE,
						  PRM_TRANTIME,
						  PRM_ACCTNO,
						  NULL,
						  PRM_AMOUNT,
						  NULL,
						  NULL,
						  NULL,
						  V_CURRCODE,
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
						  --NULL,
						  NULL,
						  NULL,
						  PRM_STAN, -- prm_stan
						  PRM_MBR_NUMB, --Ins User
						  PRM_RVSL_CODE, --INS Date
						  V_TRAN_AMT,
						  V_TOPUP_AUTH_ID,
						  V_RESPCODE,
						  V_RESPMSG,
						  V_CAPTURE_DATE);

	 IF V_RESPCODE <> '00' AND V_RESPMSG <> 'OK' THEN
	   V_ERRMSG := V_RESPMSG;
	   RAISE EXP_AUTH_REJECT_RECORD;
	 END IF;
    EXCEPTION
	 WHEN EXP_AUTH_REJECT_RECORD THEN
	   RAISE;
	 WHEN EXP_MAIN_REJECT_RECORD THEN
	   RAISE;
	 WHEN OTHERS THEN
	   V_ERRMSG := 'Error from Card authorization' ||
				SUBSTR(SQLERRM, 1, 200);
	   RAISE EXP_MAIN_REJECT_RECORD;
    END;
  END IF;
  --------------------------En
  --En call to authorize txn

  --Sn create a record in pan spprt
  BEGIN
    SELECT CSR_SPPRT_RSNCODE
	 INTO V_RESONCODE
	 FROM CMS_SPPRT_REASONS
	WHERE CSR_SPPRT_KEY = 'TOP UP' AND CSR_INST_CODE = PRM_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	 V_ERRMSG   := 'Top up reason code is present in master';
	 V_RESPCODE := '21';
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_ERRMSG   := 'Error while selecting reason code from master' ||
				SUBSTR(SQLERRM, 1, 200);
	 V_RESPCODE := '21';
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    INSERT INTO CMS_PAN_SPPRT
	 (CPS_INST_CODE,
	  CPS_PAN_CODE,
	  CPS_MBR_NUMB,
	  CPS_PROD_CATG,
	  CPS_SPPRT_KEY,
	  CPS_SPPRT_RSNCODE,
	  CPS_FUNC_REMARK,
	  CPS_INS_USER,
	  CPS_LUPD_USER,
	  CPS_CMD_MODE,
	  CPS_PAN_CODE_ENCR)
    VALUES
	 (PRM_INSTCODE, --prm_acctno
	  V_HASH_PAN,
	  V_MBRNUMB,
	  V_CAP_PROD_CATG,
	  'TOP',
	  V_RESONCODE,
	  V_TOPUPREMRK,
	  PRM_LUPDUSER,
	  PRM_LUPDUSER,
	  0,
	  V_ENCR_PAN);
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG   := 'Error while inserting records into card support master' ||
				SUBSTR(SQLERRM, 1, 200);
	 V_RESPCODE := '21';
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En create a record in pan spprt

  ----------------------------------------------------------------------------------------------------------
  -- Sn Transaction availdays Count update
  BEGIN
    UPDATE CMS_TOPUPTRANS_COUNT
	  SET CTC_TOTAVAIL_DAYS = CTC_TOTAVAIL_DAYS + 1
	WHERE CTC_ACCT_NO = PRM_ACCTNO AND CTC_INST_CODE = PRM_INSTCODE;
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG   := 'Error while inserting records into card support master' ||
				SUBSTR(SQLERRM, 1, 200);
	 V_RESPCODE := '21';
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  -- En Transaction availdays Count update

  --Sn Last Day Process Call
  BEGIN
    --Sn Week end Process Call
    IF V_TOPUP_FREQ_PERIOD = 'Week' THEN
	 SELECT NEXT_DAY(TRUNC(CTC_LUPD_DATE), 'SUNDAY')
	   INTO V_END_DAY_UPDATE
	   FROM CMS_TOPUPTRANS_COUNT
	  WHERE CTC_ACCT_NO = PRM_ACCTNO AND CTC_INST_CODE = PRM_INSTCODE;

	 IF TRUNC(SYSDATE) = (V_END_DAY_UPDATE) - 1 THEN
	   UPDATE CMS_TOPUPTRANS_COUNT
		 SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
	    WHERE CTC_ACCT_NO = PRM_ACCTNO AND CTC_INST_CODE = PRM_INSTCODE;
	 END IF;

	 --------THINK ON THAT----------------
	 SELECT TRUNC(CTC_LUPD_DATE)
	   INTO V_END_LUPD_DATE
	   FROM CMS_TOPUPTRANS_COUNT
	  WHERE CTC_ACCT_NO = PRM_ACCTNO AND CTC_INST_CODE = PRM_INSTCODE;
	 IF (TRUNC(SYSDATE) - TRUNC(V_END_LUPD_DATE)) > 7 THEN
	   UPDATE CMS_TOPUPTRANS_COUNT
		 SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
	    WHERE CTC_ACCT_NO = PRM_ACCTNO AND CTC_INST_CODE = PRM_INSTCODE;
	 END IF;
    END IF;
    --------THINK ON THAT----------------
    --Sn Month end Process Call
    IF V_TOPUP_FREQ_PERIOD = 'Month' THEN
	 SELECT LAST_DAY(TRUNC(CTC_LUPD_DATE))
	   INTO V_END_DAY_UPDATE
	   FROM CMS_TOPUPTRANS_COUNT
	  WHERE CTC_ACCT_NO = PRM_ACCTNO AND CTC_INST_CODE = PRM_INSTCODE;

	 IF TRUNC(SYSDATE) = (V_END_DAY_UPDATE) THEN
	   UPDATE CMS_TOPUPTRANS_COUNT
		 SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
	    WHERE CTC_ACCT_NO = PRM_ACCTNO AND CTC_INST_CODE = PRM_INSTCODE;
	 END IF;
    END IF;

    --Sn Year end Process Call
    IF V_TOPUP_FREQ_PERIOD = 'Year' THEN

	 IF TRUNC(SYSDATE) = TO_DATE('12/31/2009', 'MM/DD/YYYY') THEN
	   UPDATE CMS_TOPUPTRANS_COUNT
		 SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
	    WHERE CTC_ACCT_NO = PRM_ACCTNO AND CTC_INST_CODE = PRM_INSTCODE;
	 END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG   := 'Error while Updating records into cms_topuptrans_count' ||
				SUBSTR(SQLERRM, 1, 200);
	 V_RESPCODE := '21';
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Last Day Process Call
  -------------------------------------------------------------------------------------------------------------

  V_RESPCODE := 1; --Response code for successful txn

  --Sn select response code and insert record into txn log dtl

  BEGIN
    PRM_ERRMSG    := V_ERRMSG;
    PRM_RESP_CODE := V_RESPCODE;
    -- Assign the response code to the out parameter

    SELECT CMS_ISO_RESPCDE
	 INTO PRM_RESP_CODE
	 FROM CMS_RESPONSE_MAST
	WHERE CMS_INST_CODE = PRM_INSTCODE AND
		 CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL AND
		 CMS_RESPONSE_ID = V_RESPCODE;
  EXCEPTION
    WHEN OTHERS THEN
	 PRM_ERRMSG    := 'Problem while selecting data from response master ' ||
				   V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
	 PRM_RESP_CODE := '69';
	 ---ISO MESSAGE FOR DATABASE ERROR Server Declined
	 ROLLBACK;

  END;

  --En select response code and insert record into txn log dtl

  --IF errmsg is OK then balance amount will be returned

  IF PRM_ERRMSG = 'OK' THEN

    --Sn of Getting  the Acct Balannce
    BEGIN
	 SELECT CAM_ACCT_BAL
	   INTO V_ACCT_BALANCE
	   FROM CMS_ACCT_MAST
	  WHERE CAM_ACCT_NO =
		   (SELECT CAP_ACCT_NO
			 FROM CMS_APPL_PAN
			WHERE CAP_PAN_CODE = V_HASH_PAN --prm_card_no
				 AND CAP_MBR_NUMB = PRM_MBR_NUMB AND
				 CAP_INST_CODE = PRM_INSTCODE) AND
		   CAM_INST_CODE = PRM_INSTCODE
	    FOR UPDATE NOWAIT;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	   V_RESPCODE := '14'; --Ineligible Transaction
	   V_ERRMSG   := 'Invalid Card ';
	   RAISE EXP_MAIN_REJECT_RECORD;
	 WHEN OTHERS THEN
	   V_RESPCODE := '12';
	   V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
				  V_HASH_PAN;
	   RAISE EXP_MAIN_REJECT_RECORD;
    END;

    --En of Getting  the Acct Balannce

    PRM_ERRMSG := TO_CHAR(V_ACCT_BALANCE);
  END IF;

EXCEPTION
  --<< MAIN EXCEPTION >>
  WHEN EXP_AUTH_REJECT_RECORD THEN
    ROLLBACK;

    PRM_ERRMSG    := V_ERRMSG;
    PRM_RESP_CODE := V_RESPCODE;
    --Sn select response code and insert record into txn log dtl
    /*   BEGIN

                          -- Assign the response code to the out parameter

    SELECT cms_iso_respcde
           INTO prm_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = prm_instcode
            AND cms_delivery_channel = prm_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_code := '69';
                          ---ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
           -- RETURN;
      END;*/

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
	    CURRENCYCODE,
	    ADDCHARGE,
	    PRODUCTID,
	    CATEGORYID,
	    ATM_NAME_LOCATION,
	    AUTH_ID,
	    AMOUNT,
	    PREAUTHAMOUNT,
	    PARTIALAMOUNT,
	    INSTCODE,
	    CUSTOMER_CARD_NO_ENCR,
	    TOPUP_CARD_NO_ENCR,
	    RESPONSE_ID,
	    ACCT_BALANCE,
	    LEDGER_BALANCE)
	 VALUES
	   (PRM_MSG,
	    PRM_RRN,
	    PRM_DELIVERY_CHANNEL,
	    PRM_TERMINALID,
	    V_BUSINESS_DATE,
	    PRM_TXN_CODE,
	    V_TXN_TYPE,
	    PRM_TXN_MODE,
	    DECODE(PRM_RESP_CODE, '00', 'C', 'F'),
	    PRM_RESP_CODE,
	    PRM_TRANDATE,
	    SUBSTR(PRM_TRANTIME, 1, 10),
	    V_HASH_PAN,
	    NULL,
	    NULL,
	    NULL,
	    PRM_INSTCODE,
	    TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99')),
	    PRM_CURRCODE,
	    NULL,
	    V_PROD_CODE,
	    V_CARD_TYPE,
	    PRM_TERMINALID,
	    V_TOPUP_AUTH_ID,
	    TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99')),
	    NULL,
	    NULL,
	    PRM_INSTCODE,
	    V_ENCR_PAN,
	    V_ENCR_PAN,
	    V_RESPCODE,
	    V_ACCT_BALANCE,
	    V_LEDGER_BAL);

    EXCEPTION
	 WHEN OTHERS THEN

	   PRM_RESP_CODE := '69';
	   PRM_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
					SUBSTR(SQLERRM, 1, 300);
    END;
    --En create a entry in txn log
    BEGIN

	 INSERT INTO CMS_TRANSACTION_LOG_DTL
	   (CTD_DELIVERY_CHANNEL,
	    CTD_TXN_CODE,
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
	    CTD_INST_CODE,
	    CTD_CUSTOMER_CARD_NO_ENCR)
	 VALUES
	   (PRM_DELIVERY_CHANNEL,
	    PRM_TXN_CODE,
	    PRM_MSG,
	    PRM_TXN_MODE,
	    PRM_TRANDATE,
	    PRM_TRANTIME,
	    --prm_card_no
	    V_HASH_PAN,
	    PRM_AMOUNT,
	    PRM_CURRCODE,
	    PRM_AMOUNT,
	    NULL,
	    NULL,
	    NULL,
	    NULL,
	    NULL,
	    NULL,
	    'E',
	    PRM_ERRMSG,
	    PRM_RRN,
	    PRM_INSTCODE,
	    V_ENCR_PAN);

	 PRM_ERRMSG := V_ERRMSG;
	 RETURN;
    EXCEPTION
	 WHEN OTHERS THEN
	   V_ERRMSG      := 'Problem while inserting data into transaction log  dtl' ||
					SUBSTR(SQLERRM, 1, 300);
	   PRM_RESP_CODE := '22'; -- Server Declined
	   ROLLBACK;
	   RETURN;
    END;

    PRM_ERRMSG := V_ERRMSG;

  WHEN EXP_MAIN_REJECT_RECORD THEN
    ROLLBACK;
    BEGIN
	 SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
	   INTO V_ACCT_BALANCE, V_LEDGER_BAL
	   FROM CMS_ACCT_MAST
	  WHERE CAM_ACCT_NO =
		   (SELECT CAP_ACCT_NO
			 FROM CMS_APPL_PAN
			WHERE CAP_PAN_CODE = V_HASH_PAN AND
				 CAP_INST_CODE = PRM_INSTCODE) AND
		   CAM_INST_CODE = PRM_INSTCODE;
    EXCEPTION
	 WHEN OTHERS THEN
	   V_ACCT_BALANCE := 0;
	   V_LEDGER_BAL   := 0;
    END;
    --Sn select response code and insert record into txn log dtl
    BEGIN
	 PRM_ERRMSG    := V_ERRMSG;
	 PRM_RESP_CODE := V_RESPCODE;
	 -- Assign the response code to the out parameter

	 SELECT CMS_ISO_RESPCDE
	   INTO PRM_RESP_CODE
	   FROM CMS_RESPONSE_MAST
	  WHERE CMS_INST_CODE = PRM_INSTCODE AND
		   CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL AND
		   CMS_RESPONSE_ID = V_RESPCODE;
    EXCEPTION
	 WHEN OTHERS THEN
	   PRM_ERRMSG    := 'Problem while selecting data from response master ' ||
					V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
	   PRM_RESP_CODE := '69';
	   ---ISO MESSAGE FOR DATABASE ERROR Server Declined
	   ROLLBACK;
	   -- RETURN;
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
	    CUSTOMER_CARD_NO,
	    TOPUP_CARD_NO,
	    TOPUP_ACCT_NO,
	    TOPUP_ACCT_TYPE,
	    BANK_CODE,
	    TOTAL_AMOUNT,
	    CURRENCYCODE,
	    ADDCHARGE,
	    PRODUCTID,
	    CATEGORYID,
	    ATM_NAME_LOCATION,
	    AUTH_ID,
	    AMOUNT,
	    PREAUTHAMOUNT,
	    PARTIALAMOUNT,
	    INSTCODE,
	    CUSTOMER_CARD_NO_ENCR,
	    TOPUP_CARD_NO_ENCR,
	    RESPONSE_ID,
	    ACCT_BALANCE,
	    LEDGER_BALANCE)
	 VALUES
	   (PRM_MSG,
	    PRM_RRN,
	    PRM_DELIVERY_CHANNEL,
	    PRM_TERMINALID,
	    V_BUSINESS_DATE,
	    PRM_TXN_CODE,
	    V_TXN_TYPE,
	    PRM_TXN_MODE,
	    DECODE(PRM_RESP_CODE, '00', 'C', 'F'),
	    PRM_RESP_CODE,
	    PRM_TRANDATE,
	    SUBSTR(PRM_TRANTIME, 1, 10),
	    V_HASH_PAN,
	    NULL,
	    NULL,
	    NULL,
	    PRM_INSTCODE,
	    TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99')),
	    PRM_CURRCODE,
	    NULL,
	    V_PROD_CODE,
	    V_CARD_TYPE,
	    PRM_TERMINALID,
	    V_TOPUP_AUTH_ID,
	    TRIM(TO_CHAR(V_TRAN_AMT, '99999999999999999.99')),
	    NULL,
	    NULL,
	    PRM_INSTCODE,
	    V_ENCR_PAN,
	    V_ENCR_PAN,
	    V_RESPCODE,
	    V_ACCT_BALANCE,
	    V_LEDGER_BAL);

    EXCEPTION
	 WHEN OTHERS THEN

	   PRM_RESP_CODE := '69';
	   PRM_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
					SUBSTR(SQLERRM, 1, 300);
    END;
    --En create a entry in txn log

    --Sn create a entry in cms_transaction_log_dtl
    BEGIN

	 INSERT INTO CMS_TRANSACTION_LOG_DTL
	   (CTD_DELIVERY_CHANNEL,
	    CTD_TXN_CODE,
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
	    CTD_INST_CODE,
	    CTD_CUSTOMER_CARD_NO_ENCR)
	 VALUES
	   (PRM_DELIVERY_CHANNEL,
	    PRM_TXN_CODE,
	    PRM_MSG,
	    PRM_TXN_MODE,
	    PRM_TRANDATE,
	    PRM_TRANTIME,
	    --prm_card_no
	    V_HASH_PAN,
	    PRM_AMOUNT,
	    PRM_CURRCODE,
	    PRM_AMOUNT,
	    NULL,
	    NULL,
	    NULL,
	    NULL,
	    NULL,
	    NULL,
	    'E',
	    PRM_ERRMSG,
	    PRM_RRN,
	    PRM_INSTCODE,
	    V_ENCR_PAN);

	 PRM_ERRMSG := V_ERRMSG;
	 RETURN;
    EXCEPTION
	 WHEN OTHERS THEN
	   V_ERRMSG      := 'Problem while inserting data into transaction log  dtl' ||
					SUBSTR(SQLERRM, 1, 300);
	   PRM_RESP_CODE := '22'; -- Server Declined
	   ROLLBACK;
	   RETURN;
    END;

    PRM_ERRMSG := V_ERRMSG;

  WHEN OTHERS THEN
    PRM_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);

END; --<< MAIN END;>>
/


