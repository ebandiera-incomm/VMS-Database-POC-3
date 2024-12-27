CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_defloyl		(instcode		IN	NUMBER	,
													loylcatg		IN	NUMBER	,
													loyldesc		IN	VARCHAR2	,
													transamt		IN	NUMBER	,
													loylpoint		IN	NUMBER	,
													lupduser		IN	NUMBER	,
													loylcode	       OUT	NUMBER	,
													errmsg	       OUT	VARCHAR2)
AS
BEGIN			--Main begin
	--begin 1 block creates the loyalty codes
	BEGIN		--Begin 1
	SELECT cct_ctrl_numb
	INTO	loylcode
	FROM	CMS_CTRL_TABLE
	WHERE	cct_ctrl_code	=	instcode
	AND		cct_ctrl_key	=	'LOYL CODE'
	FOR	UPDATE;

	UPDATE CMS_CTRL_TABLE
	SET		cct_ctrl_numb =	cct_ctrl_numb+1,
			cct_lupd_user	=	lupduser
	WHERE	cct_ctrl_code	=	instcode
	AND		cct_ctrl_key	=	'LOYL CODE';
	errmsg := 'OK';
	EXCEPTION	--Excp of begin 1
	WHEN NO_DATA_FOUND THEN
	loylcode := 1;
	INSERT INTO	CMS_CTRL_TABLE (	CCT_CTRL_CODE	,
								CCT_CTRL_KEY		,
								CCT_CTRL_NUMB		,
								CCT_CTRL_DESC	,
								CCT_INS_USER		,
								CCT_LUPD_USER   )
						VALUES(	instcode		,
								'LOYL CODE'	,
								2			,
								'Latest Loyalty Code',
								lupduser		,
								lupduser		)	;
	errmsg := 'OK';
	WHEN OTHERS THEN
	errmsg := 'Excp 1 --'||SQLERRM||'.';
	END	;	--End of begin 1

	IF errmsg = 'OK' THEN
	--begin 2 block inserts rows into cms_loyl_mast and cms_ldef_loyl
	BEGIN		--Begin 2
	INSERT INTO CMS_LOYL_MAST(	CLM_INST_CODE		,
								CLM_LOYL_CATG		,
								CLM_LOYL_CODE		,
								CLM_LOYL_DESC		,
								CLM_INS_USER		,
								CLM_LUPD_USER		)
						VALUES(		instcode		,
								loylcatg		,
								loylcode		,
								UPPER(loyldesc)		,
								lupduser		,
								lupduser		);
	INSERT INTO CMS_DEF_LOYL	(	CDL_INST_CODE		,
								CDL_LOYL_CODE		,
								CDL_TRANS_AMT		,
								CDL_LOYL_POINT		,
								CDL_INS_USER		,
								CDL_LUPD_USER )
						VALUES( instcode		,
								loylcode		,
								transamt		,
								loylpoint		,
								lupduser		,
								lupduser		);
	EXCEPTION	--Excp of begin 2
	WHEN OTHERS THEN
	errmsg := 'Excp 2 --'||SQLERRM||'.';
	END;		--End of begin 2
	END IF;

EXCEPTION		--Excp of main begin
WHEN OTHERS THEN
errmsg	:=	'Main Excp --'||SQLERRM||'.'	;
END;			--Main begin ends
/


show error