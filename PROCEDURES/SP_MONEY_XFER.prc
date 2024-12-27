CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Money_Xfer ( prm_inst_code IN NUMBER,prm_seq_no IN NUMBER, prm_payer_no IN VARCHAR2, 
prm_payee_no IN VARCHAR2, prm_amt IN VARCHAR2,prm_lupduser IN NUMBER,  prm_errm OUT VARCHAR2)
IS

/**************************************************************************************************************************************
     * VERSION               :  1.1
     * DATE OF CREATION      : 24/MAY/2008
     * CREATED BY            : Sachin Nikam
     * PURPOSE               : PROCEDURE TO RECORD TRANSFER DETAILS DONE BETWEEN PAYER AND PAYEE
     * MODIFICATION REASON   :
     *
     *
     * LAST MODIFICATION DONE BY :
     * LAST MODIFICATION DATE    :
     *
**************************************************************************************************************************************/


v_acct_bal_payer CMS_ACCT_MAST.cam_acct_bal%TYPE	;
v_acct_bal_payee CMS_ACCT_MAST.cam_acct_bal%TYPE	;

v_errm	EXCEPTION	;

BEGIN

	prm_errm := 'OK'	;

	SELECT cam_acct_bal
	INTO   v_acct_bal_payer
	FROM   CMS_ACCT_MAST
	WHERE  cam_acct_no = prm_payer_no ;

	SELECT cam_acct_bal
	INTO   v_acct_bal_payee
	FROM   CMS_ACCT_MAST
	WHERE  cam_acct_no = prm_payee_no ;

	----------------------------------------------------
	-- SN: INSERT TRANSACTION DETAILS IN TRANSFER MASTER
	----------------------------------------------------
	BEGIN -- BEGIN 1

		INSERT INTO CMS_PAY_TRANSFER
		(cpt_transfer_no, cpt_payer_no, cpt_payee_no, cpt_transfer_amt, cpt_transfer_date, cpt_transfer_narration,
		CPT_LUPD_DATE, CPT_INST_CODE, CPT_LUPD_USER, CPT_INS_DATE, CPT_INS_USER)
		VALUES
		(prm_seq_no, prm_payer_no, prm_payee_no, prm_amt, SYSDATE, 'FUND TRNSFER',SYSDATE,prm_inst_code,prm_lupduser,SYSDATE,prm_lupduser
		);

	EXCEPTION

		WHEN OTHERS THEN

			prm_errm := 'ERROR FROM BEGIN1 : ' || SQLERRM	;

			RAISE v_errm	;
	END; -- END 1
	----------------------------------------------------
	-- EN: INSERT TRANSACTION DETAILS IN TRANSFER MASTER
	----------------------------------------------------

	-----------------------------------------
	-- SN: TO INSERT AMOUNT DETAILS FOR PAYER
	-----------------------------------------

	BEGIN -- BEGIN 2

		INSERT INTO CMS_STATEMENTS_LOG
		(csl_pan_no, csl_opening_bal, csl_trans_amount, csl_trans_type, csl_trans_date, csl_closing_balance, csl_trans_narrration,CSL_LUPD_DATE, CSL_INST_CODE, CSL_LUPD_USER, CSL_INS_DATE, CSL_INS_USER)
		VALUES
		(prm_payer_no, v_acct_bal_payer, prm_amt, 'DR', SYSDATE, v_acct_bal_payer - prm_amt, 'FUND TRANSFER TO ' || prm_payee_no,SYSDATE,prm_inst_code,prm_lupduser,SYSDATE,prm_lupduser);

	EXCEPTION

		WHEN OTHERS THEN

			prm_errm := 'ERROR FROM BEGIN2 : ' || SQLERRM	;

			RAISE v_errm	;

	END; -- END 2

	-----------------------------------------
	-- EN: TO INSERT AMOUNT DETAILS FOR PAYER
	-----------------------------------------

	------------------------------------------
	-- SN : UPDATE OF ACCOUNT MASTER FOR PAYER
	------------------------------------------

		UPDATE CMS_ACCT_MAST
		SET cam_acct_bal = v_acct_bal_payer - prm_amt
		WHERE CAM_INST_CODE = prm_inst_code AND cam_acct_no = prm_payer_no ;

	------------------------------------------
	-- EN : UPDATE OF ACCOUNT MASTER FOR PAYER
	------------------------------------------

	-----------------------------------------
	-- SN: TO INSERT AMOUNT DETAILS FOR PAYEE
	-----------------------------------------

	BEGIN -- BEGIN 3

		INSERT INTO CMS_STATEMENTS_LOG
		(csl_pan_no, csl_opening_bal, csl_trans_amount, csl_trans_type, csl_trans_date, csl_closing_balance, csl_trans_narrration,CSL_LUPD_DATE, CSL_INST_CODE, CSL_LUPD_USER, CSL_INS_DATE, CSL_INS_USER)
		VALUES
		(prm_payee_no, v_acct_bal_payee, prm_amt, 'CR', SYSDATE, v_acct_bal_payee + prm_amt, 'FUND TRANSFER FROM ' || prm_payer_no,SYSDATE,prm_inst_code,prm_lupduser,SYSDATE,prm_lupduser);

	EXCEPTION

		WHEN OTHERS THEN

			prm_errm := 'ERROR FROM BEGIN3 : ' || SQLERRM	;

			RAISE v_errm	;

	END; -- END 3

	-----------------------------------------
	-- EN: TO INSERT AMOUNT DETAILS FOR PAYEE
	-----------------------------------------

	------------------------------------------
	-- SN : UPDATE OF ACCOUNT MASTER FOR PAYEE
	------------------------------------------

		UPDATE CMS_ACCT_MAST
		SET cam_acct_bal = v_acct_bal_payee + prm_amt
		WHERE CAM_INST_CODE = prm_inst_code AND cam_acct_no = prm_payee_no ;

	------------------------------------------
	-- EN : UPDATE OF ACCOUNT MASTER FOR PAYEE
	------------------------------------------

EXCEPTION

	WHEN v_errm THEN

		prm_errm := prm_errm	;

	WHEN OTHERS THEN

		prm_errm := 'MAIN EXCPT : ' || SQLERRM	;

END ;
/
SHOW ERRORS

