CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Attach_Gl_Newpan
(
prm_inst_code           NUMBER,
prm_screen_code         VARCHAR2,
prm_card_number         VARCHAR2,
prm_card_amt            NUMBER,
prm_issue_date		DATE,
prm_ins_user		VARCHAR2,
prm_err_flag           OUT  VARCHAR2,
prm_err_msg         OUT    VARCHAR2
)
IS
v_func_code             CMS_FUNC_MAST.cfm_func_code%TYPE;
v_func_desc		CMS_FUNC_MAST.cfm_func_desc%TYPE;
v_prod_code             CMS_APPL_PAN.cap_prod_code%TYPE;
v_prod_cattype          CMS_APPL_PAN.cap_card_type%TYPE;
v_cr_gl_code            CMS_FUNC_PROD.cfp_crgl_code%TYPE;
v_crgl_catg             CMS_FUNC_PROD.cfp_crgl_catg%TYPE;
v_crsubgl_code          CMS_FUNC_PROD.cfp_crsubgl_code%TYPE;
v_cracct_no             CMS_FUNC_PROD.cfp_cracct_no%TYPE;
v_dr_gl_code            CMS_FUNC_PROD.cfp_drgl_code%TYPE;
v_drgl_catg             CMS_FUNC_PROD.cfp_drgl_catg%TYPE;
v_drsubgl_code          CMS_FUNC_PROD.cfp_drsubgl_code%TYPE;
v_dracct_no             CMS_FUNC_PROD.cfp_dracct_no%TYPE;
v_acct_desc		CMS_SUB_GL_MAST.csm_subgl_desc%TYPE;
v_txn_code		CMS_FUNC_MAST.cfm_txn_code%TYPE;
v_txn_mode		CMS_FUNC_MAST.cfm_txn_mode%TYPE;
v_delivery_channel	CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
v_fee_cr_gl_code	CMS_PRODCATTYPE_FEES.cpf_crgl_code%TYPE;
v_fee_crgl_catg		CMS_PRODCATTYPE_FEES.cpf_crgl_catg%TYPE;
v_fee_crsubgl_code	CMS_PRODCATTYPE_FEES.cpf_crsubgl_code%TYPE;
v_fee_cracct_no		CMS_PRODCATTYPE_FEES.cpf_cracct_no%TYPE;
v_fee_dr_gl_code	CMS_PRODCATTYPE_FEES.cpf_drgl_code%TYPE;
v_fee_drgl_catg		CMS_PRODCATTYPE_FEES.cpf_drgl_catg%TYPE;
v_fee_drsubgl_code	CMS_PRODCATTYPE_FEES.cpf_drsubgl_code%TYPE;
v_fee_dracct_no		CMS_PRODCATTYPE_FEES.cpf_dracct_no%TYPE;
v_resp_cde		 											   		VARCHAR2(3);
v_dr_cr_flag		 												 VARCHAR2(2);
v_gl_upd_flag														TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
v_gl_err_msg														VARCHAR2(300);
v_fee_opening_bal 											NUMBER;
v_fee_amt		NUMBER;
v_totamt		NUMBER;
v_narration		VARCHAR2(90);
exp_reject_record       EXCEPTION;
CURSOR C(p_func_code	VARCHAR2,
	 p_prod_code	VARCHAR2,
	 p_prod_cattype	VARCHAR2
	)
	IS

				SELECT  cfm_fee_code fee_code,cfm_fee_amt fee_amt,
				cpf_crgl_code,cpf_crgl_catg,cpf_crsubgl_code,cpf_cracct_no,
				cpf_drgl_code,cpf_drgl_catg,cpf_drsubgl_code,cpf_dracct_no
			FROM	CMS_FEE_MAST,CMS_PRODCATTYPE_FEES
			WHERE	cpf_func_code = p_func_code
			AND	cpf_prod_code = p_prod_code
			AND	cpf_card_type = p_prod_cattype
			AND	cfm_inst_code  = cpf_inst_code
			AND	cfm_fee_code  = cpf_fee_code;

BEGIN                                   --<< MAIN BEGIN>>
        prm_err_msg     := 'OK';
        prm_err_flag    := 'Y' ;
        --Sn find function code from the screen code
           BEGIN
                SELECT  cfm_func_code ,cfm_func_desc, cfm_txn_code, cfm_txn_mode, cfm_delivery_channel
                INTO    v_func_code , v_func_desc,v_txn_code,v_txn_mode,v_delivery_channel
                FROM    CMS_FUNC_MAST
                WHERE   CFM_SCREEN_CODE = prm_screen_code;
           EXCEPTION
                WHEN NO_DATA_FOUND THEN
                        prm_err_flag    := 'N';
                        prm_err_msg := 'No function code is defined for the screen code ' || prm_screen_code ;
                        RAISE   exp_reject_record;
                WHEN TOO_MANY_ROWS THEN
                        prm_err_flag    := 'N';
                        prm_err_msg := 'More than one  function code is defined for the screen code ' || prm_screen_code ;
                        RAISE   exp_reject_record;
                WHEN OTHERS THEN
                        prm_err_flag    := 'N';
                        prm_err_msg := 'Error while selecting function code from master ' || SUBSTR(SQLERRM,1 , 300);
                        RAISE   exp_reject_record;
           END;
        --En find function code from the screen code
        --Sn find the product code and card type for the card number
        BEGIN
             SELECT     cap_prod_code, cap_card_type
             INTO       v_prod_code , v_prod_cattype
             FROM       CMS_APPL_PAN
             WHERE      CAP_PAN_CODE = prm_card_number;
        EXCEPTION
              WHEN NO_DATA_FOUND THEN
                        prm_err_flag    := 'N';
                        prm_err_msg := 'Card not found in Master ';
                        RAISE   exp_reject_record;
              WHEN OTHERS THEN
                        prm_err_flag    := 'N';
                        prm_err_msg := 'Error while selecting pan from master ' || SUBSTR(SQLERRM,1 , 300);
                        RAISE   exp_reject_record;
        END;
        --En find the product code and card type for the card number.
	--Sn get the credit and debit gl entries.
	BEGIN
	     SELECT
			CFP_DRGL_CATG,
			CFP_DRGL_CODE,
			CFP_DRSUBGL_CODE,
			CFP_DRACCT_NO,
			CFP_CRGL_CATG,
			CFP_CRGL_CODE,
			CFP_CRSUBGL_CODE
			--,
			--			CFP_CRACCT_NO
	     INTO	v_drgl_catg,
			v_dr_gl_code,
			v_drsubgl_code,
			v_dracct_no,
			v_crgl_catg,
			v_cr_gl_code,
			v_crsubgl_code
	     FROM	CMS_FUNC_PROD
	     WHERE	CFP_FUNC_CODE		= v_func_code
			AND    CFP_PROD_CODE		= v_prod_code
			AND     CFP_PROD_CATTYPE	= v_prod_cattype;
		v_cracct_no := prm_card_number;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
                        prm_err_flag    := 'N';
                        prm_err_msg := 'GL detail is not defined for  function   ' ||v_func_desc || ' ,  product code ' || v_prod_code || ' and prod category  ' ||  v_prod_cattype ;
                        RAISE   exp_reject_record;
                WHEN TOO_MANY_ROWS THEN
                        prm_err_flag    := 'N';
                        prm_err_msg := 'More than one  GL entries is defined for the ' ||v_func_desc || ' ,  product code ' || v_prod_code || ' and prod category  ' ||  v_prod_cattype ;
                        RAISE   exp_reject_record;
                WHEN OTHERS THEN
                        prm_err_flag    := 'N';
                        prm_err_msg := 'Error while selecting GL detail from  master ' || SUBSTR(SQLERRM,1 , 300);
                        RAISE   exp_reject_record;
	END;
	--En get the credit and debit gl entries.
	    --Sn find fees amount attaced to func code, prod_code and card type
	BEGIN
		SELECT	NVL(SUM(NVL(CFM_FEE_AMT,0)), 0)
		INTO	v_fee_amt
		FROM	CMS_FEE_MAST,CMS_PRODCATTYPE_FEES   --- SET GL DETAIL TO NOT NULL(PENDING)
		WHERE	cpf_func_code = v_func_code
		AND	cpf_prod_code = v_prod_code
		AND	cpf_card_type = v_prod_cattype
		AND	cfm_inst_code  = cpf_inst_code
		AND	cfm_fee_code  = cpf_fee_code;
	EXCEPTION
		WHEN OTHERS THEN
                prm_err_msg := 'Error while selecting data from fee master for card number ' ||  SUBSTR(SQLERRM,1,300);
		RAISE exp_reject_record;
	END;
        --En find fees amount attached to func code, prod code and card type
	--Sn get tot amt
	v_totamt := prm_card_amt - v_fee_amt;
	--En get tot amt
	--Sn update credit and debit  issuance amount
	IF v_totamt > 0 THEN
		--Sn  debit acct
			UPDATE CMS_ACCT_MAST
			SET    CAM_ACCT_BAL = CAM_ACCT_BAL - prm_card_amt
			WHERE  cam_inst_code = prm_inst_code
			AND    cam_acct_no   = v_dracct_no;
			IF SQL%ROWCOUNT = 0 THEN
			prm_err_flag    := 'N';
                        prm_err_msg := 'Error while updating debit acct ' || SUBSTR(SQLERRM, 1,250) ;
                        RAISE   exp_reject_record;
			END IF;
		--En debit acct
		--Sn credit acct
			UPDATE CMS_ACCT_MAST
			SET    CAM_ACCT_BAL  = CAM_ACCT_BAL + prm_card_amt
			WHERE  cam_inst_code = prm_inst_code
			AND    cam_acct_no   = prm_card_number;
			IF SQL%ROWCOUNT = 0 THEN
			prm_err_flag    := 'N';
                        prm_err_msg := 'Error while updating credit acct ' || SUBSTR(SQLERRM, 1,250) ;
                        RAISE   exp_reject_record;
			END IF;
		--En credit acct
		--Sn get the GL DESC
		BEGIN
			SELECT CSM_SUBGL_DESC || 'ACCT'
			INTO   v_acct_desc
			FROM   CMS_SUB_GL_MAST
			WHERE  CSM_GL_CODE = v_cr_gl_code
			AND    CSM_SUBGL_CODE = v_crsubgl_code;
		EXCEPTION
			 WHEN OTHERS THEN
                        prm_err_flag    := 'N';
                        prm_err_msg := 'Error while selecting SUB GL detail from  master ' || SUBSTR(SQLERRM,1 , 300);
                        RAISE   exp_reject_record;
		END;
		--En get the GL DESC
		-- Sn create a entry in statement log
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
				prm_card_number,
				0,
				prm_card_amt,
				'CR',
				prm_issue_date,
				prm_card_amt,
				'Issuance Top Up '
				);
		--En create a entry in statement log
	ELSE
			prm_err_flag    := 'N';
                        prm_err_msg := 'Invalid txn || total amount is < 0';
                        RAISE   exp_reject_record;
	END IF;
	--En update credit and debit issuance amount
	IF v_totamt > 0 THEN
	v_fee_opening_bal  := prm_card_amt;
	--Sn update credit and debit  issuance fee amount
	FOR I IN C (v_func_code , v_prod_code ,v_prod_cattype )  LOOP
		BEGIN		--<< loop begin >>
			v_fee_cracct_no := I.cpf_cracct_no;
			v_fee_dracct_no := I.cpf_dracct_no;
				IF trim(v_fee_cracct_no) IS NULL AND trim(v_fee_dracct_no) IS NULL THEN
				prm_err_flag    := 'N';
				prm_err_msg := 'Both credit and debit account cannot be null for a fee ' || I.fee_code || ' Function code ' || v_func_code;
				RAISE   exp_reject_record;
                END IF;

                IF TRIM(v_fee_cracct_no) IS NULL THEN
				        v_fee_cracct_no := prm_card_number;
				END IF;
				IF  TRIM(v_fee_dracct_no) IS NULL THEN
					v_fee_dracct_no :=  prm_card_number ;
				END IF;
				--SN DEBIT THE  CONCERN FEE  ACCOUNT
				BEGIN
							UPDATE CMS_ACCT_MAST
							SET    cam_acct_bal  = cam_acct_bal - I.fee_amt
							WHERE  cam_inst_code = prm_inst_code
							AND    cam_acct_no   =v_fee_dracct_no ;
							IF SQL%ROWCOUNT = 0 THEN
							prm_err_flag    := 'N';
							prm_err_msg := 'Problem while updating in account master for transaction  '  ;
							RAISE   exp_reject_record;
							END IF;
				END;
				--CREATE ENTRY IN STATEMENTS LOG
				BEGIN
				v_narration := 'Issuance';
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
				v_fee_dracct_no,
				v_fee_opening_bal,
				i.fee_amt,
				'DR',
				prm_issue_date,
				 v_fee_opening_bal - i.fee_amt ,
				'Fee debited for ' || v_narration
				);
				v_fee_opening_bal  := v_fee_opening_bal - i.fee_amt;
				EXCEPTION
					WHEN OTHERS THEN
						prm_err_flag    := 'N';
						prm_err_msg := 'Problem while populating statement log for fee ';
						RAISE exp_reject_record;

				END;
				--CREATE A ENTRY IN STATEMENT LOG
				--EN DEBIT THE  CONCERN FEE  ACCOUNT
				--SN CREDIT THE CONCERN FEE ACCOUNT
                  BEGIN
                                UPDATE CMS_ACCT_MAST
				SET    cam_acct_bal  = cam_acct_bal + I.fee_amt
				WHERE  cam_inst_code = prm_inst_code
			        AND    cam_acct_no   =   v_fee_cracct_no;
				IF SQL%ROWCOUNT = 0 THEN
				prm_err_flag    := 'N';
				prm_err_msg := 'Problem while updating in account master for transaction  '  ;
				RAISE   exp_reject_record;
				END IF;
				 END;
				--EN CREDIT THE CONCERN FEE ACCOUNT

		EXCEPTION	--<< loop exception >>
			WHEN OTHERS THEN
			prm_err_flag    := 'N';
			prm_err_msg := 'Problem while processing fee for transaction ';
			RAISE   exp_reject_record;
		END;		--<< loop end >>
	END LOOP;
	END IF;
	--Sn check any fees attached if so credit or debit the acct
	--Sn create a entry in GL acct mast
	BEGIN
		INSERT INTO
		CMS_GL_ACCT_MAST
		(CGA_INST_CODE,
		 CGA_GLCATG_CODE,
		 CGA_GL_CODE,
		 CGA_SUBGL_CODE,
		 CGA_ACCT_CODE,
		 CGA_ACCT_DESC,
		 CGA_TRAN_AMT,
		 CGA_INS_DATE,
		 CGA_LUPD_USER,
		 CGA_LUPD_DATE
		)
		VALUES
		(
		prm_inst_code,
		v_crgl_catg,
		v_cr_gl_code,
		v_crsubgl_code,
		prm_card_number,
		v_acct_desc,
		0,
		prm_issue_date,
		prm_ins_user,
		prm_issue_date
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
		prm_err_flag    := 'N';
                prm_err_msg := 'Duplicate record is in master ';
                RAISE   exp_reject_record;
		WHEN OTHERS THEN
		 prm_err_flag    := 'N';
                 prm_err_msg := 'Error while inserting record in GL ACCT mast '|| SUBSTR(SQLERRM,1 , 300);
                 RAISE   exp_reject_record;
	END;
	--En create a entry in GL acct mast

	--Sn get dr cr  flag
	BEGIN
		SELECT  ctm_credit_debit_flag
		INTO	v_dr_cr_flag
		FROM	CMS_TRANSACTION_MAST					   		  	 				  		---iso transaction code
		WHERE	CTM_TRAN_CODE	=  v_txn_code
		AND	CTM_DELIVERY_CHANNEL = v_delivery_channel;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		prm_err_flag    := 'N';
                prm_err_msg := 'Transaction detail is not defined for txn code ' ||  v_txn_code  || ' for delivery channel ' || v_delivery_channel ;
                RAISE   exp_reject_record;
	END;

	--En get dr cr  flag

	---Sn insert float data
	--- Sn create GL ENTRIES
SAVEPOINT	  v_savepoint;
			  Sp_Create_Gl_Entries
				(
				 					prm_inst_code	,
									prm_issue_date,
									v_prod_code,
									v_prod_cattype,
									 prm_card_amt  ,
									  v_func_code,
									  v_txn_code,
									   v_dr_cr_flag ,
									     prm_card_number   ,
										 v_resp_cde,
										 v_gl_upd_flag,
										v_gl_err_msg
				);
				IF v_gl_err_msg	 <> 'OK' OR v_gl_upd_flag <> 'Y' THEN
				ROLLBACK TO v_savepoint;
				prm_err_flag    := 'N';
                prm_err_msg :=v_gl_err_msg	 ;
                RAISE   exp_reject_record;
				END IF;


--En create GL ENTRIES


	--En insert float data
	--Sn create a entry in txn log
	BEGIN
		 INSERT INTO TRANSACTIONLOG
		 (  		 		  MSGTYPE,
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
						  TXN_FEE,
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
						   GL_UPD_FLAG
	)
	VALUES
		  (
		   				  '210',
						  NULL,
 						  v_delivery_channel,
 						  NULL,
						  prm_issue_date,
 						  v_txn_code,
 						  '1',
 						  v_txn_mode,
						  'C',
 						   '00',
 						  TO_CHAR(prm_issue_date, 'YYYYMMDD'),
 						  TO_CHAR(prm_issue_date, 'HH24:MI:'),
 						  prm_card_number,
						  NULL,
						  NULL	,
						  NULL ,
						  NULL ,
						  v_totamt,
						  NULL,
						  NULL	,
						  NULL ,
						  NULL ,
						  NULL,
						  v_prod_code,
						  v_prod_cattype,
						  NULL,
						  NULL	,
						  NULL ,
						  NULL ,
 						  NULL	,
						  'Card Issuance',
						  prm_card_amt,
						  NULL,		 		 	  --- PRE AUTH AMOUNT
						  NULL,					  -- Partial amount (will be given for partial txn)
						  NULL	,
						  NULL ,
						  NULL ,
 						  NULL,
						  NULL,
						  'Y'
		  );
	EXCEPTION
		WHEN OTHERS THEN
		  prm_err_flag    := 'N';
		 prm_err_msg := 'Error while inserting record in transactionlog '|| SUBSTR(SQLERRM,1 , 300);
          RAISE   exp_reject_record;
	END;
	--En create a entry in txn log
EXCEPTION                               --<< MAIN EXCEPTION >>
WHEN  exp_reject_record THEN
NULL;
WHEN OTHERS THEN
 prm_err_flag    := 'N';
 prm_err_msg	 := 'Error main '|| SUBSTR(SQLERRM,1 , 300);
 RAISE   exp_reject_record;
END;                                    --<< MAIN END>>
/


