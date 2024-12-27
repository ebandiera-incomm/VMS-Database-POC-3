CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Card_To_Card_Transfer
(
 prm_inst_code	  				IN						NUMBER,
 prm_msg					IN 						VARCHAR2,
 prm_rrn											VARCHAR2,
 prm_delivery_channel										VARCHAR2,
 prm_term_id											VARCHAR2,
 prm_txn_code											VARCHAR2,
 prm_txn_mode											VARCHAR2,
 prm_tran_date											VARCHAR2 ,
prm_tran_time											VARCHAR2,
 prm_from_card_no										VARCHAR2,
 prm_from_card_expry										VARCHAR2,
 prm_bank_code											VARCHAR2,
 prm_txn_amt											NUMBER,
 prm_mcc_code											VARCHAR2,
 prm_curr_code											VARCHAR2 ,
 prm_atmname_loc										VARCHAR2,
 prm_to_card_no				   IN							VARCHAR2,
 prm_to_expry_date			   IN 							VARCHAR2 ,
 prm_stan				   IN							VARCHAR2 ,
  prm_lupd_user				   IN						NUMBER,
 prm_resp_code				   OUT		   					VARCHAR2 ,
 prm_resp_msg				   OUT 						 	VARCHAR2


   )
IS
v_from_card_exprydate			DATE;
v_to_card_exprydate			DATE;
v_check_card_from			NUMBER(2);
v_check_card_to				NUMBER(2);
v_resp_cde				VARCHAR2(3);
v_err_msg				VARCHAR(900);
v_total_amt				NUMBER;
v_txn_type				TRANSACTIONLOG.txn_type%TYPE;
v_curr_code				TRANSACTIONLOG.CURRENCYCODE%TYPE;
v_respmsg				VARCHAR2(900);
v_capture_date			DATE;
v_authmsg				VARCHAR2(900);
v_toacct_bal			CMS_ACCT_MAST.cam_acct_bal%TYPE;
v_dr_cr_flag			VARCHAR2(2);
v_ctoc_auth_id	   TRANSACTIONLOG.AUTH_ID%TYPE;
v_func_code		   		CMS_FUNC_MAST.cfm_func_code%TYPE;
v_from_prodcode			CMS_APPL_PAN.cap_prod_code%TYPE;
v_from_cardtype			CMS_APPL_PAN.cap_card_type%TYPE;
v_cracct_no				CMS_FUNC_PROD.cfp_cracct_no%TYPE;
v_dracct_no				CMS_FUNC_PROD.cfp_dracct_no%TYPE;
v_gl_upd_flag			VARCHAR2(1);
v_gl_errmsg				VARCHAR2(500);
v_tran_date				DATE;
v_terminal_indicator	CHAR(1);
v_from_card_curr        VARCHAR2(5);
v_to_card_curr			VARCHAR2(5);
v_resp_conc_msg			VARCHAR2(300);
EXP_REJECT_RECORD			EXCEPTION;
EXP_AUTH_REJECT_RECORD 		EXCEPTION;
v_ctoc_savepoint			NUMBER DEFAULT 1;
BEGIN					--<< MAIN BEGIN>>
	 v_curr_code := prm_curr_code;
	 v_txn_type  := '1';
	 SAVEPOINT 	 v_ctoc_savepoint;
-----------------SN PROCESS  TXN ----------------------------------------------------

		 	--Sn get date
		BEGIN
		v_tran_date :=  TO_DATE (SUBSTR(TRIM(prm_tran_date),1,8) || ' '|| SUBSTR(TRIM(prm_tran_time),1,8) ,  'yyyymmdd hh24:mi:ss');
							/*IF TRIM(v_tran_date) IS NULL THEN
							prm_resp_code  := '999';
							prm_resp_msg:= 'Invalid transaction date' || SUBSTR(SQLERRM,1,300);
							RETURN;
							END IF;  */
		EXCEPTION
			WHEN OTHERS THEN
			v_resp_cde  := '21';
			v_err_msg  := 'Problem while converting transaction date ' || SUBSTR(SQLERRM,1 ,200);
			RAISE exp_reject_record;
			END;
			--En get date


	--Sn check from expry date
	BEGIN
		 IF TRIM(prm_from_card_expry) IS NOT NULL THEN
		 	v_from_card_exprydate := LAST_DAY(TO_DATE('01'||prm_from_card_expry || ' 23:59:59','ddyymm hh24:mi:ss'));
		 END IF;
	EXCEPTION
		 WHEN OTHERS THEN
		v_err_msg      	 := 'Problem while converting from card expry date '  || SUBSTR(SQLERRM,1,300);
		v_resp_cde    := '22';   ---ISO MESSAGE FOR DATABASE ERROR
		RAISE exp_reject_record; -- Sn changed
	END;
	--En check from expry date
	--Sn check to card expry
	BEGIN
		 IF TRIM(prm_to_expry_date) IS NOT NULL THEN
		 	v_to_card_exprydate := LAST_DAY(TO_DATE('01'||prm_to_expry_date || ' 23:59:59','ddyymm hh24:mi:ss'));
		 END IF;
	EXCEPTION
		 WHEN OTHERS THEN
		 v_err_msg     := 'Problem while converting to card expry date '  || SUBSTR(SQLERRM,1,300);
		 v_resp_cde    := '22';   ---ISO MESSAGE FOR DATABASE ERROR
		RAISE exp_reject_record; -- Sn changed
	END;
	--En check to  card expry

	-------------------Sn find from card currency ------
	 BEGIN
                  SELECT trim(CBP_PARAM_VALUE)
		  		  INTO	 v_from_card_curr
		  		  FROM	 CMS_APPL_PAN,
			 	  		 CMS_BIN_PARAM ,
                         CMS_PROD_CATTYPE
                  WHERE  CAP_PROD_CODE = CPC_PROD_CODE
		  		  AND 	 CAP_CARD_TYPE = CPC_CARD_TYPE
		  		  AND    CAP_PAN_CODE  = prm_from_card_no
		  		  AND    CBP_PARAM_NAME = 'Currency'
		  		  AND    CBP_PROFILE_CODE = CPC_PROFILE_CODE;
                  IF trim(v_from_card_curr) IS NULL THEN
				  	    v_resp_cde := '21';
                        v_err_msg := 'From Card currency cannot be null ';
                        RAISE   exp_reject_record;
                  END IF;

        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_err_msg  := 'card currency is not defined for the from card  ' ||prm_from_card_no;
				v_resp_cde := '21';
                RAISE   exp_reject_record;
				WHEN OTHERS THEN
				v_err_msg := 'Error while selecting card currecy  ' || SUBSTR(SQLERRM,1,200);
				v_resp_cde := '21';
                RAISE   exp_reject_record;
      END;


	-------------------En find from card currency ---------

	-------------------Sn find to card currency ----------
	 BEGIN
                  SELECT trim(CBP_PARAM_VALUE)
		  		  INTO	 v_to_card_curr
		  		  FROM	 CMS_APPL_PAN,
			 	  		 CMS_BIN_PARAM ,
                         CMS_PROD_CATTYPE
                  WHERE  CAP_PROD_CODE = CPC_PROD_CODE
		  		  AND 	 CAP_CARD_TYPE = CPC_CARD_TYPE
		  		  AND    CAP_PAN_CODE  =  prm_to_card_no
		  		  AND    CBP_PARAM_NAME = 'Currency'
		  		  AND    CBP_PROFILE_CODE = CPC_PROFILE_CODE;
                  IF trim(v_to_card_curr) IS NULL THEN
				  	    v_resp_cde := '21';
                        v_err_msg := 'To Card currency cannot be null ';
                        RAISE   exp_reject_record;
                  END IF;

        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_err_msg  := 'card currency is not defined for to card ' || prm_to_card_no;
				v_resp_cde := '21';
                RAISE   exp_reject_record;
				WHEN OTHERS THEN
				v_err_msg := 'Error while selecting card currecy  ' || SUBSTR(SQLERRM,1,200);
				v_resp_cde := '21';
                RAISE   exp_reject_record;
      END;

	-------------------En find to card currency ----------
	-------------------sn check both currency-----------

	IF v_to_card_curr <> v_from_card_curr THEN
	   			v_err_msg := 'Both from card currency and to card currency are not same  ' || SUBSTR(SQLERRM,1,200);
				v_resp_cde := '21';
                RAISE   exp_reject_record;
	END IF;
	------------------En check both currency ----------

	--Sn check card currency with txn currency --------
	IF v_curr_code <> v_from_card_curr THEN
	   			v_err_msg := 'Both from card currency and txn currency are not same  ' || SUBSTR(SQLERRM,1,200);
				v_resp_cde := '21';
                RAISE   exp_reject_record;
	END IF;
	--En check card currency with txn currency --------

	--Sn Check transaction code
		IF prm_txn_code <> '56' THEN
			v_err_msg         := 'Not a valid transaction code for ' || ' card to card transfer';
			v_resp_cde        := '21';   ---ISO MESSAGE FOR DATABASE ERROR
			RAISE exp_reject_record;
		END IF;
	--En check transaction code
	--Sn check card from and card to in database---------------------------
	BEGIN
		SELECT cap_prod_code, cap_card_type
		INTO   v_from_prodcode ,v_from_cardtype
		FROM   CMS_APPL_PAN
		WHERE  cap_pan_code = prm_from_card_no;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  v_resp_cde	    := '16';   --Ineligible Transaction
		  v_err_msg			:= 'Card number not found ' || prm_from_card_no;
		  RAISE exp_reject_record;  --Sn change
		 -- RETURN;
		WHEN OTHERS THEN
		 v_resp_cde		 := '21';
		 v_err_msg	     := 'Problem while selecting card detail' || SUBSTR(SQLERRM,1,200);
		RAISE exp_reject_record; -- Sn changed
	END;
	--En check card from and card to in database---------------------------

	--Sn check   card to in database---------------------------
	BEGIN
		SELECT COUNT(1)
		INTO   v_check_card_to
		FROM   CMS_APPL_PAN
		WHERE  cap_pan_code =  prm_to_card_no;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  v_resp_cde	  := '16';   --Ineligible Transaction
		  v_err_msg		  := 'Card number not found ' ||  prm_to_card_no;
		  RAISE exp_reject_record; -- Sn changed
		WHEN OTHERS THEN
		 v_resp_cde  	 := '21';
		 v_err_msg	     := 'Problem while selecting card detail' || SUBSTR(SQLERRM,1,200);
		RAISE exp_reject_record; -- Sn changed
	END;
	--En check card from and card to in database---------------------------



	--------------------SN SELECT THE function CODE -----------------------
	  BEGIN
                 SELECT     cfm_func_code
                 INTO       v_func_code
                 FROM       CMS_FUNC_MAST
                 WHERE      cfm_txn_code = prm_txn_code
                 AND        cfm_txn_mode = prm_txn_mode
		 AND        cfm_delivery_channel = prm_delivery_channel;
		 --TXN mode and delivery channel we need to attach
		 --bkz txn code may be same for all type of channels
        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_resp_cde := '21';   --Ineligible Transaction
                v_err_msg := 'Function code not defined for txn code ' || prm_txn_code;
		RAISE exp_reject_record;
                WHEN TOO_MANY_ROWS THEN
                v_resp_cde  := '21';
                v_err_msg := 'More than one function defined for txn code ' || prm_txn_code;
		RAISE exp_reject_record;
        END;


	--------------------EN SELECT THE function code ------------------------


	--------------------SN select the debit and credit gl-------------------
	BEGIN

	SELECT 	 cfp_cracct_no,
             cfp_dracct_no
        INTO v_cracct_no,
             v_dracct_no
        FROM CMS_FUNC_PROD
       WHERE cfp_func_code = v_func_code
         AND cfp_prod_code = v_from_prodcode
         AND cfp_prod_cattype = v_from_cardtype;

      IF TRIM (v_cracct_no) IS NULL AND TRIM (v_dracct_no) IS NULL
      THEN
         prm_resp_code := '99';
         prm_resp_msg :=
               'Both credit and debit account cannot be null for a transaction code '
            || prm_txn_code
            || ' Function code '
            || v_func_code;
			v_gl_upd_flag := 'N';
         RETURN;
      END IF;

	   EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_resp_cde := '21';   --Ineligible Transaction
                v_err_msg := v_func_code ||'  function is not attached to card ' || prm_from_card_no;
		RAISE exp_reject_record;
                WHEN TOO_MANY_ROWS THEN
                v_resp_cde  := '21';
                v_err_msg := 'More than one function defined for card number ' || prm_from_card_no;
		RAISE exp_reject_record;
			      WHEN OTHERS THEN
                v_resp_cde  := '21';
                v_err_msg := 'Error while selecting Gl detasil for card numer ' || prm_from_card_no;
				RAISE exp_reject_record;
		END;

	--------------------EN select the debit and credit gl-------------------



	--Sn call to authorize procedure
	BEGIN
	Sp_Authorize_Txn (
					prm_inst_code,
					prm_msg,
					prm_rrn	,
					prm_delivery_channel,
					prm_term_id,
					prm_txn_code,
					--v_txn_type,
					prm_txn_mode,
					prm_tran_date,
					prm_tran_time,
					prm_from_card_no,
					prm_bank_code,
					prm_txn_amt,
					NULL,
					NULL,
					prm_mcc_code,
					prm_curr_code,
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
					prm_from_card_expry,
					prm_stan,
					prm_lupd_user,
					SYSDATE,
					v_ctoc_auth_id,
					v_resp_cde,
					v_respmsg,
					v_capture_date
					);
			IF v_resp_cde <> '00' AND v_respmsg <> 'OK' THEN
				   v_authmsg :=  v_respmsg;
				--v_errmsg := 'Error from auth process' || v_respmsg;
				RAISE  exp_auth_reject_record ;
			END IF;
			EXCEPTION
			    WHEN exp_auth_reject_record THEN
				RAISE;

				WHEN EXP_REJECT_RECORD THEN
				RAISE;
				WHEN OTHERS THEN
				v_resp_cde  := '21';
				 v_err_msg := 'Error from Card authorization' || SUBSTR(SQLERRM,1,200);
				RAISE  EXP_REJECT_RECORD ;
			END;

	--En call to authorize procedure
	----------------------SN find the TO acct balance------------------------------------

	BEGIN
		 SELECT cam_acct_bal
		 INTO	v_toacct_bal
		 FROM   CMS_ACCT_MAST
		 WHERE	cam_inst_code = prm_inst_code
		 AND	cam_acct_no   = prm_to_card_no;

	EXCEPTION
		 WHEN NO_DATA_FOUND THEN
		  v_resp_cde := '26';   --Invalid account
		  v_respmsg  := 'Account number not found ' || prm_to_card_no;
		  RAISE  EXP_REJECT_RECORD ;
		WHEN OTHERS THEN
		 v_resp_cde  := '21';
		 v_respmsg   := 'Problem while selecting acct balance ' || SUBSTR(SQLERRM,1,200);
		 RAISE  EXP_REJECT_RECORD ;
	END;

	----------------------En find the TO acct balance------------------------------------




	----------------------Sn Update the To acct no-------------------------------------
	BEGIN
		 UPDATE CMS_ACCT_MAST
		 SET	cam_acct_bal  = cam_acct_bal + prm_txn_amt
		 WHERE	cam_inst_code = prm_inst_code
		 AND	cam_acct_no   = prm_to_card_no;

		 	IF SQL%ROWCOUNT = 0 THEN
				v_resp_cde := '21';
			    v_respmsg  := 'Error while updating amount in to acct no ';
			 	RAISE  EXP_REJECT_RECORD ;
			END IF;

	EXCEPTION
		 WHEN OTHERS THEN
		 v_resp_cde := '21';
		 v_respmsg  := 'Error while amount in to acct no ' || SUBSTR(SQLERRM,1,200);
		 RAISE  EXP_REJECT_RECORD ;
	END;

	----------------------En Update the to acct no-------------------------------------

	------------------SN  Add a record in statements lof for TO ACCT -----------------

	BEGIN
		 v_dr_cr_flag := 'CR';

	INSERT INTO CMS_STATEMENTS_LOG
		(
		CSL_PAN_NO,
		CSL_OPENING_BAL,
		CSL_TRANS_AMOUNT,
		CSL_TRANS_TYPE,
		CSL_TRANS_DATE,
		CSL_CLOSING_BALANCE,
		CSL_TRANS_NARRRATION
		)
		VALUES
		(
		prm_to_card_no,
		v_toacct_bal,
		prm_txn_amt,
		'CR',
		v_tran_date,
		DECODE(v_dr_cr_flag,'DR',v_toacct_bal - prm_txn_amt, 'CR',v_toacct_bal + prm_txn_amt,'NA',v_toacct_bal),
		'Fund transfer from acct ' ||prm_from_card_no
		);
	EXCEPTION
	WHEN OTHERS THEN
		 v_resp_cde := '21';
		 v_err_msg  := 'Error creating entry in statement log ';
		 RAISE  EXP_REJECT_RECORD ;

	END;

	------------------EN  Add a record in statements lof for TO ACCT -----------------

	------------------SN create a record in GL----------------------------------------

	--Sn create credit gl

	Sp_Update_Gl (prm_inst_code,
                       v_tran_date,
                       prm_to_card_no,
					   prm_to_card_no,
					   prm_txn_amt    ,
					   '57'  ,
					   'CR',
					   prm_lupd_user,
                       v_gl_upd_flag,
                       v_gl_errmsg
                      );

         IF v_gl_errmsg = 'OK'
         THEN
		 NULL;
		 ELSE
                v_gl_upd_flag  := 'N';
				v_resp_cde := '21';
	            v_err_msg  := v_gl_errmsg;
            	 RAISE  EXP_REJECT_RECORD ;
         END IF;
	--En create redit gl


	--Sn create  debit gl

	Sp_Update_Gl (	   prm_inst_code,
                       v_tran_date,
                       v_cracct_no,
					   prm_to_card_no,
					   prm_txn_amt    ,
					   prm_txn_code  ,
					   'DR',
					   prm_lupd_user,
                       v_gl_upd_flag,
                       v_gl_errmsg
                      );

         IF v_gl_errmsg = 'OK'
         THEN
		 NULL;
		 ELSE
            v_gl_upd_flag := 'N';
           	    v_resp_cde := '21';
	            v_err_msg  := v_gl_errmsg;
            	 RAISE  EXP_REJECT_RECORD ;
         END IF;
	--En create debit gl

	--Sn update topup card number in translog
	BEGIN

		 UPDATE TRANSACTIONLOG
		 SET	TOPUP_CARD_NO 	  = prm_to_card_no
		 		, TOPUP_ACCT_NO	  = prm_to_card_no
		 WHERE	RRN				  = prm_rrn
		 AND DELIVERY_CHANNEL	  = prm_delivery_channel
		 AND TERMINAL_ID		  = prm_term_id
		 AND TXN_CODE			  = prm_txn_code
		 AND BUSINESS_DATE		  =	prm_tran_date
		 AND BUSINESS_TIME		  = prm_tran_time
		 AND CUSTOMER_CARD_NO	  =	prm_from_card_no
		 AND SYSTEM_TRACE_AUDIT_NO = prm_stan;

		 IF SQL%rowcount <> 1 THEN
		 	v_resp_cde := '21';
	        v_err_msg  := 'Error while updating transactionlog ' || 'no valid records ';
			 RAISE  EXP_REJECT_RECORD ;
		 END IF;

	EXCEPTION
		 WHEN OTHERS THEN
		 v_resp_cde := '21';
	     v_err_msg  := 'Error while updating transactionlog ' || SUBSTR(SQLERRM,1,200);
		 RAISE  EXP_REJECT_RECORD ;

	END;

	--En update topup card number in translog

	------------------EN create a record in GL----------------------------------------

	--Sn terminal Indicator find
   BEGIN
      SELECT ptm_terminal_indicator
        INTO v_terminal_indicator
        FROM PCMS_TERMINAL_MAST
       WHERE ptm_terminal_id = prm_term_id
         AND ptm_inst_code = prm_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
	  	 v_resp_cde := '21';
         v_err_msg :=
               'Terminal indicator is not declared for terminal id'
            || prm_term_id;
		 RAISE  EXP_REJECT_RECORD ;

      WHEN OTHERS
      THEN
	  	 v_resp_cde := '21';
         v_err_msg :=
               'Terminal indicator is not declared for terminal id'
            || SQLERRM
            || ' '
            || SQLCODE;
		 RAISE  EXP_REJECT_RECORD ;
   END;
	 --En terminal Indicator find

	--Sn create the report format
	BEGIN

	IF v_terminal_indicator IS NOT NULL AND v_ctoc_auth_id IS NOT NULL AND v_resp_cde IS NOT NULL AND v_toacct_bal IS NOT NULL THEN
	  	 v_resp_conc_msg := RPAD (prm_from_card_no,'19', ' ')||RPAD (v_toacct_bal + prm_txn_amt,'12', ' ')
		 ||RPAD (v_ctoc_auth_id,'6', ' ')||RPAD (v_resp_cde,'2', ' ')||RPAD (v_terminal_indicator,'1', ' ');
		  prm_resp_msg	 := v_resp_conc_msg;
	ELSE
		v_resp_cde := '21';
		v_err_msg := ' Error while crating response message :- Either terminal indicator or authid is null ' ;
		RAISE EXP_REJECT_RECORD;
    END IF;
	EXCEPTION
	WHEN OTHERS
      THEN
	  	 v_resp_cde := '21';
         v_err_msg :=
               'Exception while creating the response format'
            || SUBSTR(SQLERRM,1,200);

		 RAISE  EXP_REJECT_RECORD ;
	END;

	--En create the report format
	prm_resp_code := '00';

EXCEPTION				--<< MAIN EXCEPTION>>

	WHEN EXP_AUTH_REJECT_RECORD THEN
		 prm_resp_code := v_resp_cde;
		 prm_resp_msg   := v_respmsg;

	WHEN EXP_REJECT_RECORD THEN
		 ROLLBACK TO v_ctoc_savepoint;
	BEGIN
		SELECT CMS_ISO_RESPCDE
		INTO   prm_resp_code
		FROM   CMS_RESPONSE_MAST
		WHERE  CMS_INST_CODE		= prm_inst_code
		AND    CMS_DELIVERY_CHANNEL	= prm_delivery_channel
		AND    CMS_RESPONSE_ID		= v_resp_cde;
		prm_resp_msg := v_err_msg ;
	EXCEPTION
		WHEN OTHERS THEN
		prm_resp_msg   := 'Problem while selecting data from response master ' ||v_resp_cde || SUBSTR(SQLERRM,1,300);
		prm_resp_code := '69';   ---ISO MESSAGE FOR DATABASE ERROR
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
        CTD_LUPD_DATE,
        CTD_INST_CODE,
        CTD_LUPD_USER,
        CTD_INS_DATE,
        CTD_INS_USER)
		VALUES
		(
		prm_delivery_channel,
		prm_txn_code,
		v_txn_type,
		prm_txn_mode,
		prm_tran_date,
		prm_tran_time,
		prm_from_card_no,
		 prm_txn_amt,
		 prm_curr_code,
		  prm_txn_amt,
		  NULL,
		  NULL,
		   NULL,
		  NULL,
		  prm_txn_amt ,
		    v_curr_code	,
		'E',
		v_err_msg,
		 prm_rrn,
		 prm_stan,
		 SYSDATE, prm_inst_code, prm_lupd_user, SYSDATE, prm_lupd_user
		);
		prm_resp_msg := v_err_msg ;
	EXCEPTION
		WHEN OTHERS THEN
		 prm_resp_msg := 'Problem while inserting data into transaction log  dtl' || SUBSTR(SQLERRM,1,300);
		 prm_resp_code	 := '99';
		 RETURN;
	END;
	WHEN OTHERS THEN
	ROLLBACK TO v_ctoc_savepoint;
			 v_resp_cde := '69';
		 v_err_msg  := 'Error from transaction processing ' || SUBSTR(SQLERRM,1,90);
--Sn select response code and insert record into txn log dtl
	BEGIN
		SELECT CMS_ISO_RESPCDE
		INTO   prm_resp_code
		FROM   CMS_RESPONSE_MAST
		WHERE  CMS_INST_CODE		= prm_inst_code
		AND    CMS_DELIVERY_CHANNEL	= prm_delivery_channel
		AND    CMS_RESPONSE_ID		= v_resp_cde;
		prm_resp_msg := v_err_msg ;
	EXCEPTION
		WHEN OTHERS THEN
		prm_resp_msg  := 'Problem while selecting data from response master ' || v_resp_cde ||SUBSTR(SQLERRM,1,300);
		prm_resp_code := '99';
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
        CTD_LUPD_DATE,
        CTD_INST_CODE,
        CTD_LUPD_USER,
        CTD_INS_DATE,
        CTD_INS_USER)
		VALUES
		(
		prm_delivery_channel,
		prm_txn_code,
		v_txn_type,
		prm_txn_mode,
		prm_tran_date,
		prm_tran_time,
		prm_from_card_no,
		 prm_txn_amt,
		 prm_curr_code,
		  prm_txn_amt,
		  NULL,
		  NULL,
		   NULL,
		  NULL,
		  prm_txn_amt ,
		   v_curr_code	,
		'E',
		v_err_msg,
		 prm_rrn,
		 prm_stan,SYSDATE, prm_inst_code, prm_lupd_user, SYSDATE, prm_lupd_user
		);
	EXCEPTION
		WHEN OTHERS THEN
		 prm_resp_msg := 'Problem while inserting data into transaction log  dtl' || SUBSTR(SQLERRM,1,300);
		 prm_resp_code	 := '99';
		 RETURN;
	END;
END;					--<< MAIN END >>
/


