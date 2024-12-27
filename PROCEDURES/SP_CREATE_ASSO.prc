CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_asso(	instcode		IN		NUMBER	,
												assodesc	IN		VARCHAR2	,
												lupduser		IN		NUMBER	,
												errmsg		OUT		VARCHAR2)
AS
assocode	NUMBER(3);
BEGIN

	SELECT MAX(cam_asso_code)+1
	INTO	assocode
	FROM	CMS_ASSO_MAST;

		INSERT INTO CMS_ASSO_MAST(	cam_asso_code,
									cam_asso_desc,
									cam_ins_user,
									cam_lupd_user)
						VALUES(		assocode	,
									assodesc	,
									lupduser		,
									lupduser)	;
		errmsg := 'OK';
		IF errmsg = 'OK' THEN
		INSERT INTO CMS_CBD_REL(	ccr_inst_code,
								ccr_asso_code,
								ccr_inst_type,
								ccr_map_code,
								ccr_inst_status,
								ccr_ins_user,
								ccr_lupd_user)
						VALUES(	instcode,
								assocode,
								1,
								instcode||'_'||assocode||'_'||'1',
								'Y',
								lupduser,
								lupduser);
		errmsg := 'OK';
		END IF;
EXCEPTION
	WHEN OTHERS THEN
	errmsg := 'Main Exception -- '||SQLERRM;
END;
/


show error