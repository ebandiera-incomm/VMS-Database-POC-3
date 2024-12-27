CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Authorize_Txnlog
(
 prm_inst_code			VARCHAR2,
 prm_delivery_channel		VARCHAR2,
 prm_txn_code			VARCHAR2,
 prm_txn_type			VARCHAR2,
 prm_txn_mode			VARCHAR2,
 prm_txn_amt			NUMBER,
 prm_card_no			VARCHAR2,
 prm_tran_date			VARCHAR2,
 prm_tran_time			VARCHAR2,
 prm_term_id			VARCHAR2,
 prm_rrn			VARCHAR2,
 prm_resp_msg		OUT	VARCHAR2,
 prm_err_msg		OUT	VARCHAR2
)
IS
v_err_msg                VARCHAR2(300);
v_acct_balance		 NUMBER;
v_total_amt		 NUMBER;
v_tran_date		 DATE;
v_func_code              CMS_FUNC_MAST.cfm_func_code%TYPE;
v_prod_code		 CMS_PROD_MAST.cpm_prod_code%TYPE;
v_prod_cattype		 CMS_PROD_CATTYPE.cpc_card_type%TYPE;
v_fee_amt		 NUMBER;
v_upd_amt		 NUMBER;
v_narration		 VARCHAR2(50);
v_fee_opening_bal	 NUMBER;
v_resp_cde		 NUMBER;
v_expry_date		 DATE;
v_dr_cr_flag		 VARCHAR2(2);
v_applpan_cardstat	 VARCHAR2(1);
exp_reject_record	 EXCEPTION;
CURSOR C IS
			SELECT cfm_fee_code fee_code,cfm_fee_amt fee_amt
			FROM	CMS_FEE_MAST,CMS_PRODCATTYPE_FEES_NEW
			WHERE	cpf_func_code = v_func_code
			AND	cpf_prod_code = v_prod_code
			AND	cpf_card_type = v_prod_cattype
			AND	cfm_inst_code  = cpf_inst_code
			AND	cfm_fee_code  = cpf_fee_code;
BEGIN                           --<< MAIN BEGIN>>
	--Sn find debit and credit flag
	BEGIN
		SELECT  ctm_credit_debit_flag
		INTO	v_dr_cr_flag
		FROM	CMS_TRANSACTION_MAST
		WHERE	CTM_TRAN_CODE	= prm_txn_code
		AND	CTM_DELIVERY_CHANNEL = prm_delivery_channel;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		v_resp_cde := '12';   --Ineligible Transaction
                v_err_msg := 'Function code not defined for txn code ' || prm_txn_code;
		RAISE exp_reject_record;
	END;
	--En find debit and credit flag
        --Sn find function code attached to txn code
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
                v_resp_cde := '12';   --Ineligible Transaction
                v_err_msg := 'Function code not defined for txn code ' || prm_txn_code;
		RAISE exp_reject_record;
                WHEN TOO_MANY_ROWS THEN
                prm_resp_msg := '12';
                v_err_msg := 'More than one function defined for txn code ' || prm_txn_code;
		RAISE exp_reject_record;
        END;
        --En find function code attached to txn code
	--Sn find prod code and card type and available balance for the card number
         BEGIN
		SELECT	cap_prod_code,cap_card_type ,cam_acct_bal,cap_expry_date , cap_card_stat
		INTO	v_prod_code,v_prod_cattype,v_acct_balance,v_expry_date , v_applpan_cardstat
		FROM	CMS_APPL_PAN ,CMS_ACCT_MAST
		WHERE   cap_pan_code	=  prm_card_no
		AND	cap_inst_code	=  cam_inst_code
		AND	cap_acct_no	=  cam_acct_no;
         EXCEPTION
		WHEN NO_DATA_FOUND THEN
		prm_resp_msg := '003';
                v_err_msg := 'Product code and card type not defined for card number ' || prm_card_no;
		RAISE exp_reject_record;
		WHEN OTHERS THEN
		prm_resp_msg := '003';
                v_err_msg := 'Error while selecting data from card Master for card number ' || prm_card_no;
		RAISE exp_reject_record;
         END;
	--En find prod code and card type for the card number
		IF v_expry_date < SYSDATE THEN
		 v_resp_cde := '13';   --Ineligible Transaction
                 v_err_msg := 'Expry Card ';
		RAISE exp_reject_record;
		END IF;
		IF v_applpan_cardstat <> '1'	THEN
			v_resp_cde := '14';   --Ineligible Transaction
			v_err_msg := 'Invalid Card ';
			RAISE exp_reject_record;
		END IF;
        --Sn find fees amount attaced to func code, prod_code and card type
	BEGIN
		SELECT	SUM(NVL(CFM_FEE_AMT,0))
		INTO	v_fee_amt
		FROM	CMS_FEE_MAST,CMS_PRODCATTYPE_FEES_NEW
		WHERE	cpf_func_code = v_func_code
		AND	cpf_prod_code = v_prod_code
		AND	cpf_card_type = v_prod_cattype
		AND	cfm_inst_code  = cpf_inst_code
		AND	cfm_fee_code  = cpf_fee_code;
	EXCEPTION
		WHEN OTHERS THEN
		prm_resp_msg := '999';
                v_err_msg := 'Error while selecting data from fee master for card number ' ||  SUBSTR(SQLERRM,1,300);
		RAISE exp_reject_record;
	END;
        --En find fees amount attached to func code, prod code and card type
	--Sn find total transaction	amount
	IF v_dr_cr_flag = 'CR' THEN
	v_total_amt := prm_txn_amt - v_fee_amt;
	v_upd_amt   := v_acct_balance + v_total_amt;
	ELSE
		IF v_dr_cr_flag = 'DR' THEN
		v_total_amt := prm_txn_amt + v_fee_amt;
		v_upd_amt   := v_acct_balance - v_total_amt;
		END IF;
	END IF;
	--En find total transaction	amout
	--Sn check balance
	IF v_upd_amt < 0 THEN
		v_resp_cde := '15';   --Ineligible Transaction
		v_err_msg := 'Insufficent Balance ';
		RAISE exp_reject_record;
	END IF;
	--En check balance
	--Sn update in acct_mast
	BEGIN
		UPDATE CMS_ACCT_MAST
		SET    cam_acct_bal = v_upd_amt
		WHERE  cam_inst_code = prm_inst_code
		AND    cam_acct_no   = prm_card_no;
		IF SQL%ROWCOUNT = 0 THEN
		prm_resp_msg := '003';
		v_err_msg := 'Problem while updating in account master ';
		RAISE exp_reject_record;
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
		prm_resp_msg := '003';
		v_err_msg := 'Problem while updating in account master ' || SUBSTR(SQLERRM,1 ,200);
		RAISE exp_reject_record;
	END;
	--En update in acct_mast
	--Sn convert tran date
	BEGIN
	v_tran_date :=  TO_DATE (SUBSTR(TRIM(prm_tran_date	),1,8) || ' '|| SUBSTR(TRIM(prm_tran_time),1,4) ,  'yyyymmdd hh24:mi');
	EXCEPTION
	WHEN OTHERS THEN
	prm_resp_msg := '003';
	v_err_msg := 'Problem while converting transaction date ' || SUBSTR(SQLERRM,1 ,200);
	RAISE exp_reject_record;
	END;
	--En convert tran date
	--Sn find narration
	BEGIN
		SELECT	ctm_tran_desc
		INTO	v_narration
		FROM	CMS_TRANSACTION_MAST
		WHERE	ctm_tran_code = prm_txn_code ;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		v_narration := 'Transaction type ' || prm_txn_code;
	END;
	--En find narration
	--Sn create a entry in statement log
	BEGIN
		INSERT INTO CMS_STATEMENT_LOG
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
		prm_card_no,
		v_acct_balance,
		prm_txn_amt,
		v_dr_cr_flag,
		v_tran_date,
		v_upd_amt,
		v_narration
		);
	EXCEPTION
	WHEN OTHERS THEN
		prm_resp_msg := '003';
		v_err_msg := 'Problem while inserting into statement log for tran amt ' || SUBSTR(SQLERRM,1 ,200);
		RAISE exp_reject_record;
	END;
	--En create a entry in statement log
	--Sn create entries for FEES attached
	FOR I IN C LOOP
	BEGIN
		v_fee_opening_bal := v_upd_amt;
		v_upd_amt := v_upd_amt - i.fee_amt;
		INSERT INTO CMS_STATEMENT_LOG
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
		prm_card_no,
		v_fee_opening_bal,
		i.fee_amt,
		'DR',
		v_tran_date,
		v_upd_amt,
		'Fee debitted for ' || v_narration
		);
	EXCEPTION
	WHEN OTHERS THEN
		prm_resp_msg := '003';
		v_err_msg := 'Problem while inserting into statement log for tran fee ' || SUBSTR(SQLERRM,1, 200);
		RAISE exp_reject_record;
	END;
	END LOOP;
	--En create entries for FEES attached
	--Sn create a entry for successful
	--En create a entry for successful
	--Sn create a entry in txn log
	--En create a entry in txn log
EXCEPTION                       --<< MAIN EXCEPTION >>
WHEN exp_reject_record THEN
--Sn select response code and insert record into txn log dtl
	BEGIN
		SELECT CMS_B24_RESPCDE
		INTO   prm_resp_msg
		FROM   CMS_RESPONSE_MAST
		WHERE  CMS_INST_CODE		= prm_inst_code
		AND    CMS_DELIVERY_CHANNEL	= prm_delivery_channel
		AND    CMS_RESPONSE_ID		= v_resp_cde;
	EXCEPTION
		WHEN OTHERS THEN
		prm_err_msg := 'Problem while selecting data from response master ' || SUBSTR(SQLERRM,1,300);
		prm_resp_msg := '999';
	END;
	BEGIN
		INSERT INTO CMS_TRANSACTION_LOG_DTL
		VALUES
		(
		prm_txn_code,
		prm_txn_mode,
		prm_txn_mode,
		prm_tran_date,
		prm_tran_time,
		prm_card_no,
		prm_txn_amt,
		'E',
		v_err_msg
		);
	EXCEPTION
		WHEN OTHERS THEN
		prm_err_msg := 'Problem while inserting data into transaction log ' || SUBSTR(SQLERRM,1,300);
		prm_resp_msg := '999';
	END;
WHEN OTHERS THEN
--Sn select response code and insert record into txn log dtl
	BEGIN
		SELECT CMS_B24_RESPCDE
		INTO   prm_resp_msg
		FROM   CMS_RESPONSE_MAST
		WHERE  CMS_INST_CODE		= prm_inst_code
		AND    CMS_DELIVERY_CHANNEL	= prm_delivery_channel
		AND    CMS_RESPONSE_ID		= v_resp_cde;
	EXCEPTION
		WHEN OTHERS THEN
		prm_err_msg := 'Problem while selecting data from response master ' || SUBSTR(SQLERRM,1,300);
		prm_resp_msg := '999';
	END;
	BEGIN
		INSERT INTO CMS_TRANSACTION_LOG_DTL
		VALUES
		(
		prm_txn_code,
		prm_txn_mode,
		prm_txn_mode,
		prm_tran_date,
		prm_tran_time,
		prm_card_no,
		prm_txn_amt,
		'E',
		v_err_msg
		);
	EXCEPTION
		WHEN OTHERS THEN
		prm_err_msg := 'Problem while inserting data into transaction log ' || SUBSTR(SQLERRM,1,300);
		prm_resp_msg := '999';
	END;
--En select response code and insert record into txn log dtl
END;                            --<< MAIN END >>
/


