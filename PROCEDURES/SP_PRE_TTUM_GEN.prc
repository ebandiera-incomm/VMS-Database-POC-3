CREATE OR REPLACE PROCEDURE VMSCMS.sp_pre_ttum_gen	(	instcode		IN		NUMBER	,
							filename		IN		VARCHAR2	,
							fileinuse		IN		VARCHAR2	,
							rowcount		IN		NUMBER	,
							lupduser		IN		NUMBER	,
							errmsg		OUT		VARCHAR2	)

AS
trans_amt		NUMBER(15,2);
bank_tran_type		CHAR(1)	;
bank_acct		VARCHAR2(12);

BEGIN
errmsg := 'OK';
	/*SELECT	sum(decode(ctu_tran_type,'C',ctu_trans_amt,'D',(-1)*ctu_trans_amt))
	INTO	trans_amt
	FROM	cms_ttum_upload
	WHERE	ctu_inst_code	=	instcode
	AND	ctu_file_name =	filename;

	IF trans_amt < 0 THEN
		bank_tran_type := 'C';--means that the debit amount is more so bank entry will be a credit
	ELSE
		bank_tran_type := 'D';--means that the credit amount is more so bank entry will be a debit
	END IF;

	--select the bank pool account to be used
	bank_acct := 'BANK_ACCT';
	--dbms_output.put_line('amount------->'||RPAD(to_char(abs(trans_amt)),15,' '));
	--Now insert this bank entry into the cms_ttum_upload table
	INSERT INTO cms_ttum_upload(	CTU_INST_CODE		,
								CTU_FILE_NAME		,
								CTU_ROW_ID		,
								CTU_REC_SOURCE	,
								CTU_ACCT_NO		,
								CTU_CURR_CODE	,
								CTU_SOLID_CODE	,
								CTU_TRAN_TYPE		,
								CTU_TRANS_AMT		,
								CTU_PARTI_CULAR	,
								CTU_INS_USER		,
								CTU_LUPD_USER		)
						VALUES(	instcode				,
								filename				,
								rowcount+1			,
								'BANK'				,
								RPAD(bank_acct,16,' ')	,
								'INR'					,
								RPAD(substr(bank_acct,1,4),8,' ')	,
								bank_tran_type		,
								LPAD(to_char(abs(trans_amt)),15,' ')	,--01-08-02 amount converted to char to enable rpad
								RPAD('Bank Partuculars',83,' ')	,
								lupduser				,
								lupduser				);*/


	--Now update the cms_ttum_ctrl table for this file as file not in use anymore (if open for more entries)
	IF fileinuse = 'Y' THEN
	UPDATE CMS_TTUM_CTRL
	SET		ctc_file_inuse		=	'N',
			ctc_tot_rows		=	ctc_tot_rows+1,
			ctc_lupd_user		=	lupduser
	WHERE	ctc_inst_code		=	instcode
	AND		ctc_file_name		=	filename
	AND		ctc_file_inuse		=	'Y';


		IF SQL%ROWCOUNT != 1 THEN
		errmsg := 'Problem in updation of the file in use flag';
		END IF;
	ELSIF fileinuse = 'N' THEN
	UPDATE CMS_TTUM_CTRL
	SET		ctc_tot_rows		=	ctc_tot_rows+1,
			ctc_lupd_user		=	lupduser
	WHERE	ctc_inst_code		=	instcode
	AND		ctc_file_name		=	filename;
		IF SQL%ROWCOUNT != 1 THEN
		errmsg := 'Problem in updation of the file in use flag';
		END IF;
	END IF;


--errmsg flag if ok, tells the caller that the file is totally ready for actual generation

EXCEPTION
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END;
/
SHOW ERRORS

