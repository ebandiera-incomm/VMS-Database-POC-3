create or replace
PROCEDURE        vmscms.SP_LOG_TRANSACTION(PRM_INST_CODE         IN NUMBER,
									  PRM_MSG               IN VARCHAR2,
									  PRM_RRN               IN VARCHAR2,
									  PRM_DELIVERY_CHANNEL  IN VARCHAR2,
									  PRM_TERM_ID           IN VARCHAR2,
									  PRM_TXN_CODE          IN VARCHAR2,
									  PRM_TXN_MODE          IN VARCHAR2,
									  PRM_TRAN_DATE         IN VARCHAR2,
									  PRM_TRAN_TIME         IN VARCHAR2,
									  PRM_CARD_NO           IN VARCHAR2,
									  PRM_BANK_CODE         IN VARCHAR2,
									  PRM_TXN_AMT           IN NUMBER,
									  PRM_RULE_INDICATOR    IN VARCHAR2,
									  PRM_RULEGRP_ID        IN VARCHAR2,
									  PRM_MCC_CODE          IN VARCHAR2,
									  PRM_CURR_CODE         IN VARCHAR2,
									  PRM_PROD_ID           IN VARCHAR2,
									  PRM_CATG_ID           IN VARCHAR2,
									  PRM_TIP_AMT           IN VARCHAR2,
									  PRM_DECLINE_RULEID    IN VARCHAR2,
									  PRM_ATMNAME_LOC       IN VARCHAR2,
									  PRM_MCCCODE_GROUPID   IN VARCHAR2,
									  PRM_CURRCODE_GROUPID  IN VARCHAR2,
									  PRM_TRANSCODE_GROUPID IN VARCHAR2,
									  PRM_RULES             IN VARCHAR2,
									  PRM_PREAUTH_DATE      IN DATE,
									  PRM_CONSODIUM_CODE    IN VARCHAR2,
									  PRM_PARTNER_CODE      IN VARCHAR2,
									  PRM_EXPRY_DATE        IN VARCHAR2,
									  PRM_STAN              IN VARCHAR2,
									  PRM_AUTH_ID           IN VARCHAR2, --OUT AUTH PARAM
									  PRM_RESPCODE          IN VARCHAR2, --OUT AUTH PARAM
									  PRM_RESPMSG           IN VARCHAR2, --OUT AUTH PARAM
									  PRM_BUSINESS_DATE     IN DATE, -- ADDED
									  PRM_ERRMSG            OUT VARCHAR2) AS

  V_ERRMSG VARCHAR2(300) := 'OK';
  EXC_ERROR EXCEPTION;
  V_RESP_CDE   VARCHAR2(3);
  V_DR_CR_FLAG CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
  V_TXN_TYPE   CHAR(1);
  V_NARRATION  CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
  V_HASH_PAN   CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN   CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_STAT_FLAG  VARCHAR2(1);
   V_ACCT_NUMBER              CMS_APPL_PAN.CAP_ACCT_NO%TYPE;

   /*****************************************************************************************    
      * Modified By      :  B.Besky
      * Modified Date    :  08-nov-12
      * Modified Reason  : Logging Customer Account number in to transactionlog table.
     * Reviewer         :  Saravanakumar
     * Reviewed Date    : 19-nov-12
     * Release Number     :  CMS3.5.1_RI0022_B0002

********************************************************************************************/

BEGIN
  --<<MAIN>>
  -------------------------------------------------------------------------

  PRM_ERRMSG := 'OK';
  V_RESP_CDE := PRM_RESPCODE;
  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(PRM_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
	 RAISE EXC_ERROR;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(PRM_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
	 RAISE EXC_ERROR;
  END;
  --EN create encr pan

    BEGIN
    SELECT
        CAP_ACCT_NO
    INTO
        V_ACCT_NUMBER

    FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = PRM_BANK_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	 V_RESP_CDE := '21';
	 V_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
	  RAISE EXC_ERROR;
    WHEN OTHERS THEN
	 V_RESP_CDE := '21';
	 V_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
	 RAISE EXC_ERROR;
  END;

  --Sn find debit and credit flag
  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
		 TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
		 CTM_TRAN_DESC
	 INTO V_DR_CR_FLAG, V_TXN_TYPE, V_NARRATION
	 FROM CMS_TRANSACTION_MAST
	WHERE CTM_TRAN_CODE = PRM_TXN_CODE AND
		 CTM_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL AND
		 CTM_INST_CODE = PRM_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	 V_RESP_CDE := '21';
	 V_ERRMSG   := 'Transflag  not defined for txn code ' || PRM_TXN_CODE ||
				' and delivery channel ' || PRM_DELIVERY_CHANNEL;
	 --RAISE EXC_ERROR;
  END;
  --En find debit and credit flag

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
	  --          FEECODE,
	  --          TRANFEE_AMT,
	  --          SERVICETAX_AMT,
	  --          CESS_AMT,
	  CR_DR_FLAG --,
	  --          TRANFEE_CR_ACCTNO,
	  --          TRANFEE_DR_ACCTNO,
	  --          TRAN_ST_CALC_FLAG,
	  --          TRAN_CESS_CALC_FLAG,
	  --          TRAN_ST_CR_ACCTNO,
	  --          TRAN_ST_DR_ACCTNO,
	  --          TRAN_CESS_CR_ACCTNO,
	  --          TRAN_CESS_DR_ACCTNO
	 ,
	  CUSTOMER_CARD_NO_ENCR,
	  RESPONSE_ID,
          CUSTOMER_ACCT_NO   --Added by Besky on 09-nov-12
          )
    VALUES
	 (PRM_MSG,
	  PRM_RRN,
	  PRM_DELIVERY_CHANNEL,
	  PRM_TERM_ID,
	  PRM_BUSINESS_DATE,
	  PRM_TXN_CODE,
	  V_TXN_TYPE,
	  PRM_TXN_MODE,
	  DECODE(PRM_RESPCODE, '00', 'C', 'F'),
	  V_RESP_CDE,
	  PRM_TRAN_DATE,
	  PRM_TRAN_TIME,
	  -- prm_card_no
	  V_HASH_PAN,
	  NULL,
	  NULL, --prm_topup_acctno,
	  NULL, --prm_topup_accttype,
	  PRM_BANK_CODE,
	  PRM_TXN_AMT,
	  PRM_RULE_INDICATOR,
	  PRM_RULEGRP_ID,
	  PRM_MCC_CODE,
	  PRM_CURR_CODE,
	  NULL, -- prm_add_charge,
	  PRM_PROD_ID,
	  PRM_CATG_ID,
	  PRM_TIP_AMT,
	  PRM_DECLINE_RULEID,
	  PRM_ATMNAME_LOC,
	  PRM_AUTH_ID,
	  V_NARRATION,
	  PRM_TXN_AMT,
	  NULL, --- PRE AUTH AMOUNT
	  NULL, -- Partial amount (will be given for partial txn)
	  PRM_MCCCODE_GROUPID,
	  PRM_CURRCODE_GROUPID,
	  PRM_TRANSCODE_GROUPID,
	  PRM_RULES,
	  PRM_PREAUTH_DATE,
	  'N',
	  PRM_STAN,
	  PRM_INST_CODE,
	  --         v_fee_code,
	  --         v_fee_amt,
	  --         v_servicetax_amount,
	  --         v_cess_amount,
	  V_DR_CR_FLAG --,
	  --         v_fee_cracct_no,
	  --         v_fee_dracct_no ,
	  --         v_st_calc_flag  ,
	  --         v_cess_calc_flag,
	  --         v_st_cracct_no  ,
	  --         v_st_dracct_no  ,
	  --         v_cess_cracct_no,
	  --        v_cess_dracct_no
	 ,
	  V_ENCR_PAN,
	  V_RESP_CDE,
          V_ACCT_NUMBER   --Added by Besky on 09-nov-12
          );
  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while inserting in transaction log' ||
			   SUBSTR(SQLERRM, 1, 200);
	 RAISE EXC_ERROR;
  END;

  BEGIN

    IF PRM_RESPCODE <> '00' THEN

	 V_STAT_FLAG := 'Y';

    ELSE

	 V_STAT_FLAG := 'E';
    END IF;
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
	 (PRM_DELIVERY_CHANNEL,
	  PRM_TXN_CODE,
	  V_TXN_TYPE,
	  PRM_TXN_MODE,
	  PRM_TRAN_DATE,
	  PRM_TRAN_TIME,
	  --prm_card_no
	  V_HASH_PAN,
	  PRM_TXN_AMT,
	  PRM_CURR_CODE,
	  PRM_TXN_AMT,
	  NULL,
	  NULL,
	  NULL,
	  NULL,
	  NULL,
	  NULL,
	  V_STAT_FLAG,
	  PRM_RESPMSG,
	  PRM_RRN,
	  PRM_STAN,
	  V_ENCR_PAN);

  EXCEPTION
    WHEN OTHERS THEN
	 V_ERRMSG := 'Error while inserting in transaction log detail' ||
			   SUBSTR(SQLERRM, 1, 200);
	 RAISE EXC_ERROR;
  END;

  -------------------------------------------------------------------------
EXCEPTION
  --<<MAIN EXCEPTION>>
  WHEN EXC_ERROR THEN
    PRM_ERRMSG := V_ERRMSG;
  WHEN OTHERS THEN
    PRM_ERRMSG := 'Error from log transaction ' || SUBSTR(SQLERRM, 1, 200);
END; --<<MAIN END>>
/
show error;