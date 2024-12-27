CREATE OR REPLACE PROCEDURE VMSCMS.sp_get_upd_pinflag
			(
			prm_instcode	IN	NUMBER,
			prm_upd_flag	OUT	VARCHAR2,
			prm_err_msg	OUT	VARCHAR2
			)
IS
v_inst_code	CMS_INST_MAST.cim_inst_code%type;
BEGIN
	prm_err_msg := 'OK';
	--Sn get institute code
	BEGIN
		SELECT  cim_inst_code
		INTO	v_inst_code
		FROM	CMS_INST_MAST
		WHERE	cim_inst_name  like '%CANADA%';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		NULL;
		WHEN TOO_MANY_ROWS THEN
		prm_err_msg := 'More then one record found for the institute CANADA';
		RETURN;
		WHEN OTHERS THEN
		prm_err_msg := 'Error while getting CAF details'|| substr(sqlerrm,1,200);
		RETURN;
	END;
	--En get institute code
	IF v_inst_code = prm_instcode THEN
		prm_upd_flag := 'N';
	ELSE
		prm_upd_flag := 'Y';
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		prm_err_msg := 'Error while setting caf update flag';
		RETURN;
END;
/
SHOW ERRORS

