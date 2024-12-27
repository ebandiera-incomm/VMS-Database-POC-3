CREATE OR REPLACE PROCEDURE VMSCMS.sp_ttum_failed_process( inst_code IN NUMBER ,
file_name IN VARCHAR2 ,
lupduser IN NUMBER ,
errmsg OUT VARCHAR2 )
AS

file_type CHAR(1);
fail_count CMS_TTUM_CTRL.ctc_fail_rows%TYPE;
resend_count CMS_TTUM_FAILED.ctf_resend_cnt%TYPE;
resend_limit CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;

CURSOR cur_ttum_failed IS
SELECT ctf_inst_code, ctf_fee_trans, ctf_parti_cular, ctf_trans_amt,
ctf_acct_no, ctf_status
FROM CMS_TTUM_FAILED_TEMP
WHERE ctf_inst_code = inst_code
AND ctf_file_name = file_name
AND ctf_status = 'N';


BEGIN --Main begin starts
errmsg := 'OK' ;

file_type := SUBSTR(file_name, 0, 1);

IF file_type = 'N' THEN

	/* Process reversal of normal file */

	FOR x IN cur_ttum_failed
	LOOP

	INSERT INTO CMS_TTUM_FAILED (
	CTF_INST_CODE ,
	CTF_FILE_NAME ,
	CTF_ROW_ID ,
	CTF_REC_SOURCE ,
	CTF_ACCT_NO ,
	CTF_CURR_CODE ,
	CTF_SOLID_CODE ,
	CTF_TRAN_TYPE ,
	CTF_TRANS_AMT ,
	CTF_PARTI_CULAR ,
	CTF_FEE_TRANS ,
	CTF_RESEND_CNT ,
	CTF_STATUS ,
	CTF_INS_USER ,
	CTF_LUPD_USER)
	SELECT
	CTU_INST_CODE ,
	CTU_FILE_NAME ,
	CTU_ROW_ID ,
	CTU_REC_SOURCE ,
	CTU_ACCT_NO ,
	CTU_CURR_CODE ,
	CTU_SOLID_CODE ,
	CTU_TRAN_TYPE ,
	CTU_TRANS_AMT ,
	CTU_PARTI_CULAR ,
	CTU_FEE_TRANS ,
	1 ,
	'N' ,
	lupduser ,
	lupduser
	FROM CMS_TTUM_UPLOAD
	WHERE CTU_INST_CODE = x.ctf_inst_code
	AND CTU_FEE_TRANS = x.ctf_fee_trans
	--and CTU_FILE_NAME = file_name
	--and CTU_ROW_ID = x.ctf_row_id
	;
	END LOOP;

ELSE

	/* Process reversal of pending file */

	FOR x IN cur_ttum_failed
	LOOP


	SELECT NVL(MAX(ctf_resend_cnt), 0)
	INTO resend_count
	FROM CMS_TTUM_FAILED
	WHERE CTF_INST_CODE = x.ctf_inst_code
	AND CTF_FEE_TRANS = x.ctf_fee_trans
	AND CTF_NEW_FILE = SUBSTR(file_name,1,INSTR(file_name,'.'))||'ttum';
	--and CTF_ROW_ID = x.ctf_row_id


	SELECT cip_param_value
	INTO resend_limit
	FROM CMS_INST_PARAM
	WHERE cip_param_key = 'TTUM FAIL';




		IF resend_count < resend_limit THEN


		INSERT INTO CMS_TTUM_FAILED (
		CTF_INST_CODE ,
		CTF_FILE_NAME ,
		CTF_ROW_ID ,
		CTF_REC_SOURCE ,
		CTF_ACCT_NO ,
		CTF_CURR_CODE ,
		CTF_SOLID_CODE ,
		CTF_TRAN_TYPE ,
		CTF_TRANS_AMT ,
		CTF_PARTI_CULAR ,
		CTF_FEE_TRANS ,
		CTF_RESEND_CNT ,
		CTF_STATUS ,
		CTF_INS_USER ,
		CTF_LUPD_USER )
		SELECT DISTINCT
		CTF_INST_CODE ,
		CTF_FILE_NAME ,
		CTF_ROW_ID ,
		CTF_REC_SOURCE ,
		CTF_ACCT_NO ,
		CTF_CURR_CODE ,
		CTF_SOLID_CODE ,
		CTF_TRAN_TYPE ,
		CTF_TRANS_AMT ,
		CTF_PARTI_CULAR ,
		CTF_FEE_TRANS ,
		resend_count + 1 ,
		'N' ,
		lupduser ,
		lupduser
		FROM CMS_TTUM_FAILED
		WHERE CTF_INST_CODE = x.ctf_inst_code
		AND CTF_FEE_TRANS = x.ctf_fee_trans
		--and CTF_FILE_NAME = file_name
		--and CTU_ROW_ID = x.ctf_row_id
		;

		ELSE

		UPDATE CMS_TTUM_FAILED
		SET ctf_status = 'F',
		ctf_lupd_user = lupduser
		WHERE CTF_INST_CODE = x.ctf_inst_code
		AND CTF_FEE_TRANS = x.ctf_fee_trans
		AND CTF_NEW_FILE = SUBSTR(file_name,1,INSTR(file_name,'.'))||'ttum'
		--and CTF_ROW_ID = x.ctf_row_id
		AND CTF_RESEND_CNT = resend_limit;

		END IF;

	END LOOP;

END IF;

	SELECT COUNT(ROWID)
	INTO fail_count
	FROM CMS_TTUM_FAILED_TEMP
	WHERE ctf_inst_code = inst_code
	AND ctf_file_name = file_name;

	UPDATE CMS_TTUM_CTRL
	SET ctc_file_gen = 'P',
	ctc_fail_rows = fail_count,
	ctc_fail_procdate = SYSDATE,
	ctc_lupd_user = lupduser
	WHERE ctc_inst_code = inst_code
	AND ctc_file_name = SUBSTR(file_name,1,INSTR(file_name,'.'))||'ttum';

	UPDATE CMS_TTUM_FAILED_TEMP
	SET ctf_status = 'Y',
	ctf_lupd_user = lupduser
	WHERE ctf_inst_code = inst_code
	AND ctf_file_name = file_name
	AND ctf_status = 'N';

EXCEPTION --Exception of main begin
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END; --Main begin ends
/


SHOW ERRORS