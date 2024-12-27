CREATE OR REPLACE PROCEDURE VMSCMS.SP_TOPUP_PAN(PRM_INSTCODE     IN NUMBER,
								 PRM_RRN          IN VARCHAR2,
								 PRM_TERMINALID   IN VARCHAR2,
								 PRM_STAN         IN VARCHAR2,
								 PRM_TRANDATE     IN VARCHAR2,
								 PRM_TRANTIME     IN VARCHAR2,
								 PRM_ACCTNO       IN VARCHAR2,
								 PRM_FILENAME     IN VARCHAR2,
								 PRM_REMRK        IN VARCHAR2,
								 PRM_RESONCODE    IN NUMBER,
								 PRM_AMOUNT       IN NUMBER,
								 PRM_REFNO        IN VARCHAR2,
								 PRM_PAYMENTMODE  IN VARCHAR2,
								 PRM_INSTRUMENTNO IN VARCHAR2,
								 PRM_DRAWNDATE    IN DATE,
								 PRM_CURRCODE     IN VARCHAR2,
								 PRM_LUPDUSER     IN NUMBER,
								 PRM_AUTH_MESSAGE OUT VARCHAR2,
								 PRM_ERRMSG       OUT VARCHAR2) AS
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
  V_AUTHMSG           VARCHAR2(500);
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
  EXP_MAIN_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  V_HASH_PAN CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
BEGIN
  --<<MAIN BEGIN >>
  PRM_ERRMSG       := 'OK';
  PRM_AUTH_MESSAGE := 'OK';

  IF PRM_REMRK IS NULL THEN
    V_ERRMSG := 'Please enter appropriate remrk';
    RAISE EXP_MAIN_REJECT_RECORD;
  END IF;

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
	WHERE CAP_PAN_CODE = V_HASH_PAN --prm_acctno 
		 AND CAP_INST_CODE = PRM_INSTCODE;
    /*
          IF v_cap_cafgen_flag = 'N'
          THEN
             v_errmsg := 'CAF has to be generated atleast once for this pan ';
             RAISE exp_main_reject_record;
          END IF;
    */
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_ERRMSG := 'Invalid Card number ' || PRM_ACCTNO;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while selecting card number ' || PRM_ACCTNO;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En select Pan detail

  --Sn check the min and max limit for topup
  BEGIN
    SELECT CPC_PROFILE_CODE
	 INTO V_PROFILE_CODE
	 FROM CMS_PROD_CATTYPE
	WHERE CPC_PROD_CODE = V_PROD_CODE AND CPC_CARD_TYPE = V_CARD_TYPE AND
		 CPC_INST_CODE = PRM_INSTCODE;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_ERRMSG := 'profile_code not defined ' || V_PROFILE_CODE;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_ERRMSG := 'profile_code not defined ' || V_PROFILE_CODE;
	 RAISE EXP_MAIN_REJECT_RECORD;
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
		 PRM_AMOUNT BETWEEN A.CBP_PARAM_VALUE AND B.CBP_PARAM_VALUE;
  
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
	 V_ERRMSG := 'Topup Amount is out of range ' || V_MIN_LIMIT || ' TO ' ||
			   V_MAX_LIMIT;
	 RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_ERRMSG := 'Topup Amount is out of range ' || V_MIN_LIMIT || ' TO ' ||
			   V_MAX_LIMIT;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_ERRMSG := 'Topup Amount is out of range ' || V_MIN_LIMIT || ' TO ' ||
			   V_MAX_LIMIT;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En check the min and max limit for topup

  --Sn select variable type detail
  BEGIN
    SELECT CPM_VAR_FLAG
	 INTO V_VARPRODFLAG
	 FROM CMS_PROD_MAST A, CMS_APPL_PAN B
	WHERE CAP_PAN_CODE = V_HASH_PAN --prm_acctno
		 AND CPM_INST_CODE = CAP_INST_CODE AND
		 CPM_PROD_CODE = CAP_PROD_CODE;
  
    IF V_VARPRODFLAG <> 'V' THEN
	 V_ERRMSG := 'Top up is not applicable on this card number ' ||
			   PRM_ACCTNO;
	 RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_ERRMSG := 'Card type (fixed/variable ) not defined for the card ' ||
			   PRM_ACCTNO;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while selecting card number ' || PRM_ACCTNO;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En  select variable type detail
  --Sn Check initial load
  IF V_FIRSTTIME_TOPUP = 'N' THEN
    V_ERRMSG := 'Topup is applicable only after initial load for this acctno ' ||
			 PRM_ACCTNO;
    RAISE EXP_MAIN_REJECT_RECORD;
  END IF;

  --En Check initial load

  --Sn select transaction code,mode and del channel
  BEGIN
    SELECT CFM_TXN_CODE, CFM_TXN_MODE, CFM_DELIVERY_CHANNEL, CFM_TXN_TYPE
	 INTO V_TXN_CODE, V_TXN_MODE, V_DEL_CHANNEL, V_TXN_TYPE
	 FROM CMS_FUNC_MAST
	WHERE CFM_FUNC_CODE = 'TOP UP' AND CFM_INST_CODE = PRM_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	 V_ERRMSG := 'Support function Initial Load not defined in master';
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while selecting support function detail ' ||
			   SUBSTR(SQLERRM, 1, 200);
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

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
	 V_ERRMSG := 'Freq and period is not defined ' || V_TOPUP_FREQ;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_ERRMSG := 'Freq and period is not defined  ' || V_TOPUP_FREQ_PERIOD;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --------------------------------
  BEGIN
    SELECT COUNT(1)
	 INTO V_ACCT_TXN_DTL
	 FROM CMS_TOPUPTRANS_COUNT
	WHERE CTC_ACCT_NO = PRM_ACCTNO;
  
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
	 V_ERRMSG := 'Topup Transaction Days are not specifid  ' ||
			   V_ACCT_TXN_DTL;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_ERRMSG := 'Topup Transaction Days are not specifid  ' ||
			   V_ACCT_TXN_DTL;
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --------------------------------
  BEGIN
    SELECT CTC_TOTAVAIL_DAYS
	 INTO V_ACCT_TXN_DTL_1
	 FROM CMS_TOPUPTRANS_COUNT
	WHERE CTC_ACCT_NO = PRM_ACCTNO;
  
    IF V_ACCT_TXN_DTL_1 >= V_TOPUP_FREQ THEN
	 V_ERRMSG := 'Topup Transaction Days are over ' || V_ACCT_TXN_DTL_1;
	 RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
	 RAISE;
    WHEN NO_DATA_FOUND THEN
	 V_ERRMSG := 'Topup Transaction Days are not specifid  ' ||
			   V_ACCT_TXN_DTL_1;
	 RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
	 V_ERRMSG := 'Topup Transaction Days are not specifid  ' ||
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
	 V_CURRCODE := PRM_CURRCODE;
	 SP_AUTHORIZE_TXN(PRM_INSTCODE,
				   '210',
				   PRM_RRN,
				   V_DEL_CHANNEL,
				   PRM_TERMINALID,
				   V_TXN_CODE,
				   --v_txn_type,
				   V_TXN_MODE,
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
				   PRM_LUPDUSER, --Ins User
				   SYSDATE, --INS Date
				   V_TOPUP_AUTH_ID,
				   V_RESPCODE,
				   V_RESPMSG,
				   V_CAPTURE_DATE);
    
	 IF V_RESPCODE <> '00' AND V_RESPMSG <> 'OK' THEN
	   V_AUTHMSG := V_RESPMSG;
	   --v_errmsg := 'Error from auth process' || v_respmsg;
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
  /*--Sn create a record in pan spprt
  BEGIN
     SELECT   CSR_SPPRT_RSNCODE
     INTO  v_resonCode
     FROM  CMS_SPPRT_REASONS
     WHERE csr_spprt_key='TOP UP';
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
     v_errmsg := 'Top up reason code is present in master';
     RAISE  exp_main_reject_record ;
     WHEN OTHERS THEN
     v_errmsg := 'Error while selecting reason code from master'|| SUBSTR(SQLERRM,1,200);
     RAISE  exp_main_reject_record ;
  END;*/
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
	  PRM_RESONCODE,
	  PRM_REMRK,
	  PRM_LUPDUSER,
	  PRM_LUPDUSER,
	  0,
	  V_ENCR_PAN);
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while inserting records into card support master' ||
			   SUBSTR(SQLERRM, 1, 200);
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En create a record in pan spprt

  ----------------------------------------------------------------------------------------------------------
  -- Sn Transaction availdays Count update
  BEGIN
    UPDATE CMS_TOPUPTRANS_COUNT
	  SET CTC_TOTAVAIL_DAYS = CTC_TOTAVAIL_DAYS + 1
	WHERE CTC_ACCT_NO = PRM_ACCTNO;
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while inserting records into card support master' ||
			   SUBSTR(SQLERRM, 1, 200);
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
	  WHERE CTC_ACCT_NO = PRM_ACCTNO;
    
	 IF TRUNC(SYSDATE) = (V_END_DAY_UPDATE) - 1 THEN
	   UPDATE CMS_TOPUPTRANS_COUNT
		 SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
	    WHERE CTC_ACCT_NO = PRM_ACCTNO;
	 END IF;
    
	 --------THINK ON THAT----------------
	 SELECT TRUNC(CTC_LUPD_DATE)
	   INTO V_END_LUPD_DATE
	   FROM CMS_TOPUPTRANS_COUNT
	  WHERE CTC_ACCT_NO = PRM_ACCTNO;
	 IF (TRUNC(SYSDATE) - TRUNC(V_END_LUPD_DATE)) > 7 THEN
	   UPDATE CMS_TOPUPTRANS_COUNT
		 SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
	    WHERE CTC_ACCT_NO = PRM_ACCTNO;
	 END IF;
    END IF;
    --------THINK ON THAT----------------
    --Sn Month end Process Call
    IF V_TOPUP_FREQ_PERIOD = 'Month' THEN
	 SELECT LAST_DAY(TRUNC(CTC_LUPD_DATE))
	   INTO V_END_DAY_UPDATE
	   FROM CMS_TOPUPTRANS_COUNT
	  WHERE CTC_ACCT_NO = PRM_ACCTNO;
    
	 IF TRUNC(SYSDATE) = (V_END_DAY_UPDATE) THEN
	   UPDATE CMS_TOPUPTRANS_COUNT
		 SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
	    WHERE CTC_ACCT_NO = PRM_ACCTNO;
	 END IF;
    END IF;
  
    --Sn Year end Process Call
    IF V_TOPUP_FREQ_PERIOD = 'Year' THEN
	 IF TRUNC(SYSDATE) = TO_DATE('12/31/2009', 'MM/DD/YYYY') THEN
	   UPDATE CMS_TOPUPTRANS_COUNT
		 SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
	    WHERE CTC_ACCT_NO = PRM_ACCTNO;
	 END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while Updating records into cms_topuptrans_count' ||
			   SUBSTR(SQLERRM, 1, 200);
	 RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Last Day Process Call
  -------------------------------------------------------------------------------------------------------------
  /*
  --Sn create a record in charge detail
  Sp_Charge_Support(prm_instcode, prm_acctno, 'TOP',prm_lupduser,v_errmsg);
  IF v_errmsg <> 'OK' THEN
     v_errmsg := 'Error while creating a record in charge detail';
     RAISE  exp_main_reject_record ;
  END IF;
  --En create a reocrd in charge detail
  */
EXCEPTION
  --<< MAIN EXCEPTION >>
  WHEN EXP_AUTH_REJECT_RECORD THEN
    PRM_AUTH_MESSAGE := V_AUTHMSG;
    PRM_ERRMSG       := 'OK';
  WHEN EXP_MAIN_REJECT_RECORD THEN
    PRM_ERRMSG       := V_ERRMSG;
    PRM_AUTH_MESSAGE := V_ERRMSG;
  WHEN OTHERS THEN
    PRM_ERRMSG       := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
    PRM_AUTH_MESSAGE := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
END; --<< MAIN END;>>
/


