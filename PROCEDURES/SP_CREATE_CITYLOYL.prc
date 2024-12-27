CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_cityloyl(	instcode		IN	NUMBER	,
													loylcatg		IN	NUMBER	,
													cntrycode	IN	NUMBER	,
													citycode		IN	NUMBER	,
													loyldesc		IN	VARCHAR2	,
													transamt		IN	NUMBER	,
													loylpoint		IN	NUMBER	,
													lupduser		IN	NUMBER	,
													loylcode	       OUT	NUMBER	,
													errmsg	       OUT	VARCHAR2)
AS
v_clc_catg_sname		CMS_LOYL_CATG.clc_catg_sname%TYPE;

BEGIN			--Main begin
errmsg := 'OK';

	BEGIN		--begin 0
	SELECT clc_catg_sname
	INTO	v_clc_catg_sname
	FROM	CMS_LOYL_CATG
	WHERE	clc_inst_code = instcode
	AND		clc_catg_code = loylcatg;

	IF v_clc_catg_sname != 'CITY' THEN
	errmsg := 'Allowed only for City based loyalty';
	END IF;

	EXCEPTION	--excp 0
	WHEN OTHERS THEN
	errmsg := 'Excp 0 -- '||SQLERRM;
	END;		--end 0

	--begin 1 block creates the loyalty codes
	IF errmsg = 'OK' THEN
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
	WHEN OTHERS THEN
	errmsg := 'Excp 1 --'||SQLERRM||'.';
	END	;	--End of begin 1
	END IF;

	IF errmsg = 'OK' THEN
	--begin 2 block inserts rows into cms_loyl_mast and cms_merccatg_loyl
	BEGIN		--Begin 2
	INSERT INTO CMS_LOYL_MAST(				CLM_INST_CODE		,
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

	INSERT INTO CMS_CITY_LOYL		(	CCL_INST_CODE		,
									CCL_LOYL_CODE		,
									CCL_CNTRY_CODE	,
									CCL_CITY_CODE		,
									CCL_TRANS_AMT		,
									CCL_LOYL_POINT		,
									CCL_INS_USER		,
									CCL_LUPD_USER  )
						VALUES(		instcode		,
									loylcode		,
									cntrycode	,
									citycode		,
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