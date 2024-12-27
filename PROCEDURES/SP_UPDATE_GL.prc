CREATE OR REPLACE PROCEDURE VMSCMS.SP_UPDATE_GL(PRM_INST_CODE   NUMBER,
								 PRM_INS_DATE    DATE,
								 PRM_ACCT_NO     VARCHAR2,
								 PRM_CARD_NO     VARCHAR2,
								 PRM_TXN_AMOUNT  NUMBER,
								 PRM_TXN_CODE    VARCHAR2,
								 PRM_TRAN_TYPE   VARCHAR2,
								 PRM_INS_USER    NUMBER,
								 PRM_GL_UPD_FLAG OUT VARCHAR2,
								 PRM_ERR_MSG     OUT VARCHAR2) IS
  V_GL_CODE       CMS_GL_ACCT_MAST.CGA_GL_CODE%TYPE;
  V_SUBGL_CODE    CMS_GL_ACCT_MAST.CGA_SUBGL_CODE%TYPE;
  V_GL_CURR_CODE  CMS_GL_MAST.CGM_CURR_CODE%TYPE;
  V_GL_DESC       CMS_GL_MAST.CGM_GL_DESC%TYPE;
  V_SUB_GL_DESC   CMS_SUB_GL_MAST.CSM_SUBGL_DESC%TYPE;
  V_ERR_MSG       VARCHAR2(500);
  V_GL_ERR_MSG    VARCHAR2(500);
  V_FLOAT_FLAG    CMS_GL_MAST.CGM_FLOAT_FLAG%TYPE;
  V_CARD_CURR     VARCHAR2(3);
  V_CHECK_APPLPAN NUMBER(1);
  EXP_REJECT_RECORD EXCEPTION;
BEGIN
  --<< MAIN BEGIN >>
  PRM_ERR_MSG := 'OK';

  --Sn find the gl detail of account
  BEGIN
    SELECT CGA_GL_CODE, CGA_SUBGL_CODE
	 INTO V_GL_CODE, V_SUBGL_CODE
	 FROM CMS_GL_ACCT_MAST
	WHERE CGA_ACCT_CODE = PRM_ACCT_NO AND CGA_INST_CODE = PRM_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	 PRM_ERR_MSG := 'Account is not related to any GL ';
	 -- RAISE exp_reject_record;
    WHEN OTHERS THEN
	 PRM_ERR_MSG := 'Error while selecting GL entries ' ||
				 SUBSTR(SQLERRM, 1, 300);
	 -- RAISE exp_reject_record;
  END;

  --En find the gl detail of account
  --Sn find  gl desc
  BEGIN
    SELECT CGM_GL_DESC, TRIM(CGM_CURR_CODE), CGM_FLOAT_FLAG
	 INTO V_GL_DESC, V_GL_CURR_CODE, V_FLOAT_FLAG
	 FROM CMS_GL_MAST
	WHERE CGM_GL_CODE = V_GL_CODE AND CGM_INST_CODE = PRM_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	 PRM_ERR_MSG := 'GL desc is not available ';
	 --  RAISE exp_reject_record;
    WHEN OTHERS THEN
	 PRM_ERR_MSG := 'Error while selecting GL desc ' ||
				 SUBSTR(SQLERRM, 1, 300);
	 --RAISE exp_reject_record;
  END;

  --En find  gl desc
  --Sn find  sub gl desc
  BEGIN
    SELECT CSM_SUBGL_DESC
	 INTO V_SUB_GL_DESC
	 FROM CMS_SUB_GL_MAST
	WHERE CSM_GL_CODE = V_GL_CODE AND CSM_SUBGL_CODE = V_SUBGL_CODE AND
		 CSM_INST_CODE = PRM_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	 PRM_ERR_MSG := 'GL desc is not available ';
	 -- RAISE exp_reject_record;
    WHEN OTHERS THEN
	 PRM_ERR_MSG := 'Error while selecting GL desc ' ||
				 SUBSTR(SQLERRM, 1, 300);
	 -- RAISE exp_reject_record;
  END;

  --En find  sub gl desc
  --Sn find currency of profile code attached to card
  BEGIN
    SELECT TRIM(CBP_PARAM_VALUE)
	 INTO V_CARD_CURR
	 FROM CMS_APPL_PAN, CMS_BIN_PARAM, CMS_PROD_MAST
	WHERE CAP_PROD_CODE = CPM_PROD_CODE
    AND CAP_PAN_CODE = GETHASH(PRM_CARD_NO)
     -- GETHASH(PRM_ACCT_NO) AND
	AND	 CBP_PARAM_NAME = 'Currency'
    AND CBP_PROFILE_CODE = CPM_PROFILE_CODE
    AND CBP_INST_CODE = PRM_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	 IF PRM_CARD_NO <> PRM_ACCT_NO THEN
	   BEGIN
		SELECT 1
		  INTO V_CHECK_APPLPAN
		  FROM CMS_APPL_PAN
		 WHERE CAP_PAN_CODE = GETHASH(PRM_CARD_NO) --gethash(prm_acct_no)
			  AND CAP_INST_CODE = PRM_INST_CODE;

		PRM_ERR_MSG := 'Currency is not defined for the acct ' ||
					PRM_ACCT_NO;
		-- RAISE exp_reject_record;
	   EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  V_CARD_CURR := V_GL_CURR_CODE;
		WHEN OTHERS THEN
		  PRM_ERR_MSG := 'Error while selecting curr code for acct ' ||
					  PRM_ACCT_NO;
		  --RAISE exp_reject_record;
	   END;
	 ELSE
	   PRM_ERR_MSG := 'Currency is not defined for the card ' ||
				   PRM_ACCT_NO;
	   -- RAISE exp_reject_record;
	 END IF;
    WHEN OTHERS THEN
	 PRM_ERR_MSG := 'Error while selecting currency for card ' ||
				 PRM_ACCT_NO;
	 -- RAISE exp_reject_record;
  END;

  --En find currency of profile code attached to card

  --Sn check card currency with Gl currency
  IF V_CARD_CURR <> V_GL_CURR_CODE THEN
    PRM_ERR_MSG := 'Both card and Gl currencies are not same ';
    RAISE EXP_REJECT_RECORD;
  END IF;

  --En check card currency with gL Currency

  --Sn create gl entries
  IF PRM_ERR_MSG = 'OK' THEN

    SP_POPULATE_FLOAT_DATA(PRM_INST_CODE,
					  V_GL_CURR_CODE,
					  V_GL_CODE,
					  V_GL_DESC,
					  V_SUBGL_CODE,
					  V_SUB_GL_DESC,
					  V_FLOAT_FLAG,
					  PRM_TRAN_TYPE,
					  PRM_INS_DATE,
					  PRM_INS_USER,
					  PRM_TXN_AMOUNT,
					  PRM_TXN_CODE,
					  V_ERR_MSG);
  END IF;

  IF V_ERR_MSG <> 'OK' THEN
    PRM_ERR_MSG := V_ERR_MSG;
    -- RAISE exp_reject_record;
  END IF;

  PRM_GL_UPD_FLAG := 'Y';
  --En create gl entries
EXCEPTION
  --<<MAIN EXCEPTION >>
  WHEN EXP_REJECT_RECORD THEN
    PRM_GL_UPD_FLAG := 'N';
    SP_CREATE_GL_ERRORLOG(PRM_ACCT_NO,
					 PRM_ERR_MSG,
					 PRM_INS_DATE,
					 PRM_INST_CODE,
					 V_GL_ERR_MSG

					 );
  WHEN OTHERS THEN
    PRM_GL_UPD_FLAG := 'N';
    PRM_ERR_MSG     := SUBSTR(SQLERRM, 1, 300);
    SP_CREATE_GL_ERRORLOG(PRM_ACCT_NO,
					 PRM_ERR_MSG,
					 PRM_INS_DATE,
					 PRM_INST_CODE,
					 V_GL_ERR_MSG

					 );
END; --<< MAIN END >>
/


