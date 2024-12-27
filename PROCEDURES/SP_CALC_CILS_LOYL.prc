CREATE OR REPLACE PROCEDURE VMSCMS.sp_calc_cils_loyl	(	instcode		IN		NUMBER	,
													pancode		IN		VARCHAR2	,
													mbrnumb		IN		VARCHAR2	,
													lupduser		IN		NUMBER	,
													errmsg		OUT		VARCHAR2	)
AS
v_mbrnumb			VARCHAR2(3)	;
v_cap_prod_code		CMS_APPL_PAN.cap_prod_code%TYPE;
v_cap_card_type		CMS_APPL_PAN.cap_card_type%TYPE;
v_cap_cust_catg		CMS_APPL_PAN.CAP_CUST_CATG%TYPE;
v_cpl_loyl_code		CMS_LOYL_MAST.clm_loyl_code%TYPE;
v_cce_loyl_code		CMS_LOYL_MAST.clm_loyl_code%TYPE;
v_cap_acct_no		CMS_APPL_PAN.cap_acct_no%TYPE;
v_cap_addon_stat		CMS_APPL_PAN.cap_addon_stat%TYPE;
v_cap_addon_link		CMS_APPL_PAN.cap_addon_link%TYPE;
v_cap_mbr_link		CMS_APPL_PAN.cap_mbr_link%TYPE;
applicable_loyl_code	CMS_LOYL_MAST.clm_loyl_code%TYPE;
calc_loyl_points		NUMBER (5)					;--calculated loyalty points

pan_to_insert			CMS_APPL_PAN.cap_pan_code%TYPE;
mbr_to_insert			CMS_APPL_PAN.cap_mbr_numb%TYPE;
addonlink_to_insert		CMS_APPL_PAN.cap_pan_code%TYPE;
mbrlink_to_insert		CMS_APPL_PAN.cap_mbr_numb%TYPE;

pccc_level_ind		NUMBER (1)		;
cardex_level_ind		NUMBER (1)		;
BEGIN		--main begin
errmsg	:=	'OK';
IF mbrnumb IS NULL THEN
v_mbrnumb := '000';
ELSE
v_mbrnumb := mbrnumb;
END IF;

	BEGIN		--begin 1
		SELECT cap_prod_code, cap_card_type, cap_cust_catg, cap_acct_no, cap_addon_stat, cap_addon_link, cap_mbr_link
		INTO	v_cap_prod_code, v_cap_card_type, v_cap_cust_catg, v_cap_acct_no, v_cap_addon_stat, v_cap_addon_link, v_cap_mbr_link
		FROM	CMS_APPL_PAN
		WHERE	cap_pan_code	=	pancode
		AND		cap_mbr_numb	=	v_mbrnumb;
	EXCEPTION	--excp 1
		WHEN NO_DATA_FOUND THEN
		errmsg	:= 'PAN not found, please enter a valid pan.';
		WHEN OTHERS THEN
		errmsg	:= 'Excp 1 -- '||SQLERRM;
	END		;	--end begin 2


	--now find out the CILS loyalty if any at the PCCC level
	IF errmsg = 'OK' THEN
		BEGIN		--begin 2
			SELECT	a.cpl_loyl_code
			INTO	v_cpl_loyl_code
			--, b.clm_loyl_catg, c.clc_catg_prior
			FROM	CMS_PRODCCC_LOYL a, CMS_LOYL_MAST b, CMS_LOYL_CATG c
			WHERE	a.cpl_inst_code	=	b.clm_inst_code
			AND	a.cpl_loyl_code	=	b.clm_loyl_code
			AND	b.clm_inst_code	=	c.clc_inst_code
			AND	b.clm_loyl_catg	=	c.clc_catg_code
			AND	a.cpl_inst_code	=	instcode
			AND	a.cpl_prod_code	=	v_cap_prod_code
			AND	a.cpl_card_type	=	v_cap_card_type
			AND	a.cpl_cust_catg	=	v_cap_cust_catg
			AND	c.clc_catg_code	=	9-->specific for CILS loyalty
			AND	TRUNC (SYSDATE) BETWEEN TRUNC(cpl_valid_from) AND TRUNC(cpl_valid_to);--sysdate taken so as the pan gets the CILS loyalty on the day it is generated

			pccc_level_ind	:=	1;
		EXCEPTION	--exception 2
			WHEN NO_DATA_FOUND THEN
			pccc_level_ind	:=	0;
			WHEN OTHERS THEN
			errmsg	:= 'Excp 2 -- '||SQLERRM;
		END;		--end begin 2
	END IF;

	--now find out the CILS loyalty if any at the Card Exceptional level
	IF errmsg = 'OK' THEN
		BEGIN		--begin 3
			SELECT	a.cce_loyl_code
			--, b.clm_loyl_catg, c.clc_catg_prior
			INTO	v_cce_loyl_code
			FROM	CMS_CARD_EXCPLOYL a, CMS_LOYL_MAST b, CMS_LOYL_CATG c
			WHERE	a.cce_inst_code	=	b.clm_inst_code
			AND	a.cce_loyl_code	=	b.clm_loyl_code
			AND	b.clm_inst_code	=	c.clc_inst_code
			AND	b.clm_loyl_catg	=	c.clc_catg_code
			AND	a.cce_inst_code	=	instcode
			AND	a.cce_pan_code	=	pancode
			AND	a.cce_mbr_numb	=	v_mbrnumb
			AND	c.clc_catg_code	=	9-->specific for CILS loyalty
			AND	TRUNC (SYSDATE) BETWEEN TRUNC(cce_valid_from) AND TRUNC(cce_valid_to);--sysdate taken so as the pan gets the CILS loyalty on the day it is generated

			cardex_level_ind	:=	1;
		EXCEPTION	--exception 3
			WHEN NO_DATA_FOUND THEN
			cardex_level_ind	:=	0;
			WHEN OTHERS THEN
			errmsg	:= 'Excp 3 -- '||SQLERRM;
		END;		--end begin 3
	END IF;


	IF errmsg = 'OK' THEN
		IF cardex_level_ind = 1	AND pccc_level_ind= 1 OR cardex_level_ind = 1 AND pccc_level_ind = 0 THEN
			--take the card exceptional level loyalty into consideration
			SELECT	ccl_loyl_point
			INTO	calc_loyl_points
			FROM	CMS_CILS_LOYL
			WHERE	ccl_inst_code	=	instcode
			AND		ccl_loyl_code	=	v_cce_loyl_code	;
			applicable_loyl_code	:=	v_cce_loyl_code	;
		ELSIF pccc_level_ind = 1 AND cardex_level_ind = 0 THEN
			--take the pccc level loyalty into consideration
			SELECT	ccl_loyl_point
			INTO	calc_loyl_points
			FROM	CMS_CILS_LOYL
			WHERE	ccl_inst_code	=	instcode
			AND		ccl_loyl_code	=	v_cpl_loyl_code	;
			applicable_loyl_code	:=	v_cpl_loyl_code	;
		ELSE	--both are 0
		calc_loyl_points := 0;
		END IF;
	END IF;

IF NOT (pccc_level_ind = 0 AND cardex_level_ind = 0) THEN	--not if
	IF v_cap_addon_stat = 'P' THEN
			pan_to_insert		:= pancode	;
			mbr_to_insert		:= v_mbrnumb;
			addonlink_to_insert	:= NULL		;
			mbrlink_to_insert	:= NULL		;
	ELSIF v_cap_addon_stat = 'A' THEN
			pan_to_insert		:= v_cap_addon_link	;
			mbr_to_insert		:= v_cap_mbr_link		;
			addonlink_to_insert	:= pancode			;
			mbrlink_to_insert	:= v_mbrnumb			;
	END IF;

	IF errmsg = 'OK' THEN
		UPDATE CMS_LOYL_POINTS
		SET		clp_loyl_points		=	clp_loyl_points+calc_loyl_points,
				clp_lupd_user		=	lupduser
		WHERE	clp_inst_code		=	instcode
		AND		clp_pan_code		=	pan_to_insert
		AND		clp_mbr_numb	=	mbr_to_insert	;

		IF SQL%NOTFOUND THEN
			INSERT INTO CMS_LOYL_POINTS(	CLP_INST_CODE		,
										CLP_PAN_CODE		,
										CLP_MBR_NUMB		,
										CLP_LOYL_POINTS	,
										CLP_LAST_RDMDATE	,
										CLP_INS_USER		,
										CLP_LUPD_USER		)
							VALUES(	 	instcode			,
										pan_to_insert		,
										mbr_to_insert		,
										calc_loyl_points	,
										NULL				,
										lupduser			,
										lupduser			);
		END IF;

		INSERT INTO CMS_LOYL_DTL	(	CLD_INST_CODE		,
									CLD_PAN_CODE		,
									CLD_MBR_NUMB		,
									CLD_ACCT_NO		,
									CLD_LOYL_CODE		,
									CLD_TRANS_AMT		,
									CLD_LOYL_POINTS	,
									CLD_ADDON_PAN	,
									CLD_ADDON_MBR	,
									CLD_ID_COL			,
									CLD_INS_USER		,
									CLD_LUPD_USER		)
						VALUES(		instcode				,
									pan_to_insert			,
									mbr_to_insert			,
									v_cap_acct_no		,
									applicable_loyl_code	,
									0					,
									calc_loyl_points		,
									addonlink_to_insert		,
									mbrlink_to_insert		,
									NULL					,
									lupduser				,
									lupduser				);

		INSERT INTO CMS_LOYL_AUDIT(	CLA_INST_CODE    ,
						CLA_PAN_CODE     ,
						CLA_MBR_NUMB     ,
						CLA_ACCT_NO      ,
						CLA_LOYL_IND     ,
						CLA_LOYL_POINTS  ,
						CLA_OPRN_DATE    ,
						CLA_OPRN_DESC    ,
						CLA_INS_USER     ,
						CLA_LUPD_USER    )
					VALUES(	instcode	,
						pan_to_insert	,
						mbr_to_insert	,
						v_cap_acct_no	,
						'C'		,
						calc_loyl_points,
						SYSDATE		,
						'Card issuance loyalty points credit',
						lupduser	,
						lupduser	);
	END IF;
END IF;	--not if
EXCEPTION	--main excp
WHEN OTHERS THEN
errmsg := 'Main excp -- '||SQLERRM;
END;		--main begin ends
/


show error