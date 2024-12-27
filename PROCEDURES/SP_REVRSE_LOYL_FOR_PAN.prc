CREATE OR REPLACE PROCEDURE VMSCMS.sp_revrse_loyl_for_pan(	instcode	IN	NUMBER	,
							pancode		IN	VARCHAR2,
							mbrnumb		IN	VARCHAR2,
							dispamt		IN	NUMBER	,
							idcol		IN	NUMBER	,
							calcdate	IN	DATE	,
							loyltype	IN	NUMBER	,--0 for normal loyalty calc for transactions(first time),1 for chargeback loyl calc
							lupduser	IN	NUMBER	,
							errmsg		OUT	VARCHAR2)
AS
calc_ind		NUMBER(1);
yes_no			CHAR(1)	;
excp_flag		NUMBER(1);
pccc_flag		NUMBER(1);
v_clm_loyl_catg		NUMBER (3);
v_clm_loyl_catg_pccc	NUMBER (3);
v_clm_loyl_catg_excp	NUMBER (3);
excp_temp_loyl_code	NUMBER(3);
excp_temp_trans_amt	NUMBER	;
excp_temp_loyl_point	NUMBER	;
pccc_temp_loyl_code	NUMBER(3);
pccc_temp_trans_amt	NUMBER	;
pccc_temp_loyl_point	NUMBER	;
applicable_loyl_code	NUMBER(3);
applicable_trans_amt	NUMBER	;
applicable_loyl_point	NUMBER	;
applicable_slab_code	NUMBER (3);
calc_loyl_points	NUMBER (5);--calculated loyalty points
addon_for_insert	VARCHAR2(20);
mbr_for_addon		VARCHAR2(3);
excp_addon		VARCHAR2(20);
excp_mbr		VARCHAR2(3);
excp_slabout_code	NUMBER(3);
pccc_slabout_code	NUMBER(3);
slab_flag		CHAR(1)	;
v_mbrnumb		VARCHAR2(3);

pccc_temp_loyl_point_out NUMBER;
excp_temp_loyl_point_out NUMBER	;

CURSOR C2 IS
SELECT	ctd_id_col,ctd_disp_amt
FROM	CMS_TRANS_DISP
WHERE	ctd_inst_code	= instcode
AND	ctd_disp_code	IN(1,7);-- loyalty to be reversed only in the case of reversal and first chargeback


--main cursor which picks up the transactions to calculate loyalty points
CURSOR	C1(c_idcol IN NUMBER) IS
SELECT	cld_pan_code, cld_mbr_numb,cld_loyl_code, cld_addon_pan, cld_addon_mbr, cld_acct_no
FROM	CMS_LOYL_DTL
WHERE	cld_inst_code	= instcode
--AND	cld_pan_code	= pancode
--AND	cld_mbr_numb	= v_mbrnumb
AND	cld_id_col	= c_idcol;






--local procedures to find out the applicable loyalties

--0. local procedure to find out whether there is any loyalty based on customer category
PROCEDURE lp_find_custcatg_loyl(lp_loyl_code IN NUMBER,lp_yes_no OUT CHAR,lp_trans_amt OUT NUMBER,lp_loyl_point OUT NUMBER,lperr0 OUT VARCHAR2)
IS
BEGIN		--begin lp0
lperr0 := 'OK';
	SELECT 	ccl_trans_amt, ccl_loyl_point
	INTO	lp_trans_amt, lp_loyl_point
	FROM	CMS_CUSTCATG_LOYL
	WHERE	ccl_inst_code	=	instcode
	AND		ccl_loyl_code	=	lp_loyl_code;
	lp_yes_no := 'Y';
EXCEPTION	--excp lp0
	WHEN NO_DATA_FOUND THEN
	lperr0 := 'No loyalty found in customer category loyalty.';
	WHEN OTHERS THEN
	lperr0 := 'Excp LP0-1 --'||SQLERRM;
END;		--end lp0

--1.local procedure to find out whether there is any loyalty based on merchant category code
PROCEDURE lp_find_merccatg_loyl (lp_loyl_code IN NUMBER,lp_merccatg_code IN VARCHAR2,lp_yes_no OUT CHAR,lp_trans_amt OUT NUMBER,lp_loyl_point OUT NUMBER,lperr1 OUT VARCHAR2)
IS
v_cml_merc_catg	VARCHAR2(4);
BEGIN		--begin lp1
lperr1 := 'OK';
	SELECT	cml_merc_catg,cml_trans_amt,cml_loyl_point
	INTO	v_cml_merc_catg,lp_trans_amt ,lp_loyl_point
	FROM	CMS_MERCCATG_LOYL
	WHERE	cml_inst_code		=	instcode
	AND	cml_loyl_code		=	lp_loyl_code;
	IF v_cml_merc_catg = lp_merccatg_code THEN
	lp_yes_no := 'Y';
	ELSE
	lp_yes_no := 'N';
	END IF;
EXCEPTION	--excp of lp1
	WHEN NO_DATA_FOUND THEN
	lperr1 := 'No loyalty found in merchant categorywise loyalty master';
	WHEN OTHERS THEN
	lperr1 := 'Excp LP1-1 --'||SQLERRM;

END;		--end lp1

--2.local procedure to find out whether there is any loyalty based on merchant code
PROCEDURE lp_find_merc_loyl (lp_loyl_code IN NUMBER,lp_term_id IN VARCHAR2,lp_yes_no OUT CHAR,lp_trans_amt OUT NUMBER,lp_loyl_point OUT NUMBER,lperr2 OUT VARCHAR2)
IS
v_cml_merc_code	VARCHAR2(8);
v_ctm_merc_code VARCHAR2(8);

BEGIN
lperr2 := 'OK';
	BEGIN	--begin lp2.1
	SELECT	ctm_merc_code
	INTO	v_ctm_merc_code
	FROM	CMS_TERM_MAST
	WHERE	ctm_inst_code	= instcode
	AND	ctm_term_id	= lp_term_id;
	EXCEPTION	--excp of lp2.1
	WHEN NO_DATA_FOUND THEN
	lperr2 := 'No such Merchant found for terminal --'||lp_term_id;
	WHEN OTHERS THEN
	lperr2 := 'Excp LP2.1-1 --'||SQLERRM;
	END;		--end of lp2.1

IF lperr2 = 'OK' THEN
BEGIN		--begin lp2.2
	SELECT	cml_merc_code,cml_trans_amt,cml_loyl_point
	INTO	v_cml_merc_code,lp_trans_amt ,lp_loyl_point
	FROM	CMS_MERC_LOYL
	WHERE	cml_inst_code		=	instcode
	AND		cml_loyl_code		=	lp_loyl_code;
	IF v_ctm_merc_code = v_cml_merc_code THEN
	lp_yes_no := 'Y';
	--dbms_output.put_line('30-04-02In yes_no = Y');
	ELSE
	lp_yes_no := 'N';
	dbms_output.put_line('30-04-02In yes_no = N');
	END IF;
EXCEPTION	--excp of lp2.2
	WHEN NO_DATA_FOUND THEN
	--dbms_output.put_line('30-04-02In no data found');
	lperr2 := 'No loyalty found in merchant wise loyalty master';
	WHEN OTHERS THEN
	--dbms_output.put_line('30-04-02In when others');
	lperr2 := 'Excp LP2.2-1 --'||SQLERRM;
END;		--end lp2.2
END IF;
END;

--3.local procedure to find out whether there is any loyalty based on city code
PROCEDURE lp_find_city_loyl (lp_loyl_code IN NUMBER,lp_term_id IN VARCHAR2,lp_yes_no OUT CHAR,lp_trans_amt OUT NUMBER,lp_loyl_point OUT NUMBER,lperr3 OUT VARCHAR2)
IS
v_ctm_cntry_code	NUMBER (3);
v_ctm_city_code	NUMBER (5);
v_ccl_cntry_code	NUMBER (3);
v_ccl_city_code	NUMBER (5);
BEGIN		--begin lp3
lperr3 := 'OK';
	BEGIN	--begin lp3.1
	SELECT ctm_cntry_code,ctm_city_code
	INTO	v_ctm_cntry_code,v_ctm_city_code
	FROM	CMS_TERM_MAST
	WHERE	ctm_inst_code =	instcode
	AND		ctm_term_id	=	lp_term_id;
	EXCEPTION	--excp of lp3.1
	WHEN NO_DATA_FOUND THEN
	lperr3 := 'No such terminal found --'||lp_term_id;
	WHEN OTHERS THEN
	lperr3 := 'Excp LP3-1 --'||SQLERRM;
	END;		--end of lp3.1

	IF	lperr3 = 'OK' THEN
	BEGIN		--begin lp3.2
	SELECT	ccl_cntry_code,ccl_city_code,ccl_trans_amt,ccl_loyl_point
	INTO	v_ccl_cntry_code,v_ccl_city_code,lp_trans_amt ,lp_loyl_point
	FROM	CMS_CITY_LOYL
	WHERE	ccl_inst_code		=	instcode
	AND	ccl_loyl_code		=	lp_loyl_code;
		IF v_ccl_cntry_code = v_ctm_cntry_code AND v_ccl_city_code = v_ctm_city_code THEN
		lp_yes_no := 'Y';
		ELSE
		lp_yes_no := 'N';
		END IF;
	EXCEPTION	--excp of lp3.2
	WHEN NO_DATA_FOUND THEN
	lperr3 := 'No loyalty found in city wiseloyalty master';
	WHEN OTHERS THEN
	lperr3 := 'Excp LP3-2 --'||SQLERRM;
	END;		--end of lp3.2
	END IF;

EXCEPTION	--excp of lp3
WHEN OTHERS THEN
lperr3 := 'Excp LP3 --'||SQLERRM;
END;		--end lp3

--4.local procedure to find out whether there is any monthwise loyalty
PROCEDURE lp_find_month_loyl (lp_loyl_code IN NUMBER,lp_transdate IN DATE,lp_yes_no OUT CHAR,lp_trans_amt OUT NUMBER,lp_loyl_point OUT NUMBER,lperr4 OUT VARCHAR2)
IS
v_cml_first_date	DATE;
v_cml_last_date	DATE;
BEGIN		--begin lp4
lperr4 := 'OK';
	SELECT	cml_first_date, cml_last_date,cml_trans_amt,cml_loyl_point
	INTO	v_cml_first_date, v_cml_last_date,lp_trans_amt ,lp_loyl_point
	FROM	CMS_MONTH_LOYL
	WHERE	cml_inst_code		=	instcode
	AND	cml_loyl_code		=	lp_loyl_code;
	IF TRUNC(lp_transdate) BETWEEN TRUNC(v_cml_first_date) AND TRUNC(v_cml_last_date) THEN
	lp_yes_no := 'Y';
	ELSE
	lp_yes_no := 'N';
	END IF;
EXCEPTION	--excp of lp4
	WHEN NO_DATA_FOUND THEN
	lperr4 := 'No loyalty found in month wise loyalty master';
	WHEN OTHERS THEN
	lperr4 := 'Excp LP4-1 --'||SQLERRM;
END;		--end lp4


--5.local procedure to find out whether there is any datewise loyalty
PROCEDURE lp_find_date_loyl (lp_loyl_code IN NUMBER,lp_transdate IN DATE,lp_yes_no OUT CHAR,lp_trans_amt OUT NUMBER,lp_loyl_point OUT NUMBER,lperr5 OUT VARCHAR2)
IS

v_cdl_date_oftrans	DATE;
BEGIN		--begin lp5
lperr5 := 'OK';
	SELECT	cdl_date_oftrans, cdl_trans_amt,cdl_loyl_point
	INTO	v_cdl_date_oftrans, lp_trans_amt ,lp_loyl_point
	FROM	CMS_DATE_LOYL
	WHERE	cdl_inst_code		=	instcode
	AND	cdl_loyl_code		=	lp_loyl_code;
	IF TRUNC(lp_transdate) = TRUNC(v_cdl_date_oftrans) THEN
	lp_yes_no := 'Y';
	ELSE
	lp_yes_no := 'N';
	END IF;
EXCEPTION	--excp of lp5
	WHEN NO_DATA_FOUND THEN
	lperr5 := 'No loyalty found in date wise loyalty master';
	WHEN OTHERS THEN
	lperr5 := 'Excp LP5-1 --'||SQLERRM;
END;		--end lp5


--6.local procedure to find out the whether there is any default loyalty
PROCEDURE lp_find_def_loyl (lp_loyl_code IN NUMBER,lp_yes_no OUT CHAR,lp_trans_amt OUT NUMBER,lp_loyl_point OUT NUMBER,lperr6 OUT VARCHAR2)
IS
BEGIN		--begin lp6
lperr6 := 'OK';
	SELECT	cdl_trans_amt,cdl_loyl_point
	INTO	lp_trans_amt ,lp_loyl_point
	FROM	CMS_DEF_LOYL
	WHERE	cdl_inst_code		=	instcode
	AND	cdl_loyl_code		=	lp_loyl_code;
	lp_yes_no := 'Y';
EXCEPTION	--excp of lp6
	WHEN NO_DATA_FOUND THEN
	lperr6 := 'No loyalty found in default loyalty master';
	WHEN OTHERS THEN
	lperr6 := 'Excp LP6-1 --'||SQLERRM;
END;		--end lp6

--7.local procedure to find out the whether there is any slabwise loyalty
PROCEDURE lp_find_slab_loyl(lp_loyl_code IN NUMBER, lp_yes_no OUT CHAR,slabout_code OUT NUMBER,lperr7 OUT VARCHAR2)
IS
BEGIN		--begin lp7
lperr7 := 'OK';
	SELECT csl_slab_code
	INTO	slabout_code
	FROM	CMS_SLAB_LOYL
	WHERE	csl_inst_code		=	instcode
	AND	csl_loyl_code		=	lp_loyl_code;
	lp_yes_no := 'Y';
EXCEPTION	--excp lp7
	WHEN NO_DATA_FOUND THEN
	lperr7 := 'No loyalty found in Slab loyalty master';
	WHEN OTHERS THEN
	lperr7 := 'Excp LP7-1 --'||SQLERRM;
END;		--end lp7

--8. local procedure to calculate the slabwise loyalty points
PROCEDURE lp_calc_slab_loyl_points(slabcode IN NUMBER,trans_amt IN NUMBER,calc_loyl_points OUT NUMBER,lperr8 OUT VARCHAR2)
IS

lp_trans_amt	NUMBER;
slab_amt		NUMBER;
lp_calc_loyl_points	NUMBER;
CURSOR lpc1 IS
SELECT  csd_from_amt,csd_to_amt,csd_trans_amt,csd_loyl_point
FROM	CMS_SLABLOYL_DTL
WHERE	csd_inst_code		= instcode
AND	csd_slab_code	= slabcode
ORDER BY csd_from_amt;
BEGIN		--begin lp8
lperr8	:=	'OK';
lp_trans_amt		:= trans_amt;
calc_loyl_points	:= 0;
		FOR a IN lpc1
		LOOP
				IF a.csd_from_amt = 0 THEN
				slab_amt := a.csd_to_amt-a.csd_from_amt	;
				ELSE
				slab_amt := a.csd_to_amt-(a.csd_from_amt-1)	;
				END IF;

				IF slab_amt >lp_trans_amt THEN
					SELECT ROUND(NVL(lp_trans_amt,0)/a.csd_trans_amt)*a.csd_loyl_point
					INTO	lp_calc_loyl_points
					FROM	dual;
					EXIT;
					calc_loyl_points := calc_loyl_points+lp_calc_loyl_points;
				ELSIF slab_amt <= lp_trans_amt THEN
					lp_trans_amt := lp_trans_amt-slab_amt;
					SELECT ROUND(NVL(slab_amt,0)/a.csd_trans_amt)*a.csd_loyl_point
					INTO	lp_calc_loyl_points
					FROM	dual;
					calc_loyl_points := calc_loyl_points+lp_calc_loyl_points;
				END IF;



		EXIT WHEN lpc1%NOTFOUND;
		END LOOP;
EXCEPTION	--excp lp8
	WHEN OTHERS THEN
	lperr8 := 'Excp LP8-1 --'||SQLERRM;
END;		--end lp8

/*---------Main Procedure starts*/
BEGIN		--Main begin starts
--first reset the global vairables
gen_cms_pack.v_card_level_prior		:= 10000;
gen_cms_pack.v_pccc_level_prior	:= 10000;
errmsg := 'OK';
--IF mbrnumb IS null THEN
--v_mbrnumb := '000';
--END IF;
--dbms_output.put_line('Initial loyalty priority--->'||gen_cms_pack.v_card_level_prior);
FOR y IN c2
LOOP

FOR x IN c1(y.ctd_id_col)
LOOP

			applicable_loyl_code := x.cld_loyl_code;


			BEGIN		--begin 2 starts
				SELECT clm_loyl_catg
				INTO	v_clm_loyl_catg
				FROM	CMS_LOYL_MAST
				WHERE clm_loyl_code = applicable_loyl_code;
				IF v_clm_loyl_catg = 8 THEN
				slab_flag := 'Y'	 ;
				ELSE
				slab_flag := 'N'	 ;
				END IF;
			EXCEPTION	--excp of begin 2
				WHEN NO_DATA_FOUND THEN
				errmsg := 'No Data found in loyalty master for code --'||applicable_loyl_code;
				WHEN OTHERS THEN
				errmsg := 'Excp 2 --'||SQLERRM;
			END;		--begin 2 ends
IF	v_clm_loyl_catg = 1 THEN
	--query the default loyalty table
	SELECT	cdl_trans_amt,cdl_loyl_point
	INTO	applicable_trans_amt, applicable_loyl_point
	FROM	CMS_DEF_LOYL
	WHERE	cdl_inst_code	=	instcode
	AND	cdl_loyl_code	=	applicable_loyl_code;
ELSIF	v_clm_loyl_catg = 2 THEN
	--query the date loyalty table
	SELECT	cdl_trans_amt,cdl_loyl_point
	INTO	applicable_trans_amt,applicable_loyl_point
	FROM	CMS_DATE_LOYL
	WHERE	cdl_inst_code	=	instcode
	AND	cdl_loyl_code	=	applicable_loyl_code;
ELSIF	v_clm_loyl_catg = 3 THEN
	--query the month loyalty table
	SELECT	cml_trans_amt,cml_loyl_point
	INTO	applicable_trans_amt,applicable_loyl_point
	FROM	CMS_MONTH_LOYL
	WHERE	cml_inst_code	=	instcode
	AND	cml_loyl_code	=	applicable_loyl_code;
ELSIF	v_clm_loyl_catg = 4 THEN
	--query the month customer category loyalty table
	SELECT	ccl_trans_amt,ccl_loyl_point
	INTO	applicable_trans_amt,applicable_loyl_point
	FROM	CMS_CUSTCATG_LOYL
	WHERE	ccl_inst_code	=	instcode
	AND	ccl_loyl_code	=	applicable_loyl_code;
ELSIF	v_clm_loyl_catg = 5 THEN
	--query the merchant category loyalty table
	SELECT	cml_trans_amt,cml_loyl_point
	INTO	applicable_trans_amt,applicable_loyl_point
	FROM	CMS_MERCCATG_LOYL
	WHERE	cml_inst_code	=	instcode
	AND	cml_loyl_code	=	applicable_loyl_code;
ELSIF	v_clm_loyl_catg = 6 THEN
	--query the merchant category loyalty table
	SELECT	cml_trans_amt,cml_loyl_point
	INTO	applicable_trans_amt,applicable_loyl_point
	FROM	CMS_MERCCATG_LOYL
	WHERE	cml_inst_code	=	instcode
	AND	cml_loyl_code	=	applicable_loyl_code;
ELSIF	v_clm_loyl_catg = 7 THEN
	--query the city loyalty table
	SELECT	ccl_trans_amt,ccl_loyl_point
	INTO	applicable_trans_amt,applicable_loyl_point
	FROM	CMS_CITY_LOYL
	WHERE	ccl_inst_code	=	instcode
	AND	ccl_loyl_code	=	applicable_loyl_code;
ELSIF	v_clm_loyl_catg = 8 THEN
	--query the slab loyalty table
	SELECT	csl_slab_code
	INTO	applicable_slab_code
	FROM	CMS_SLAB_LOYL
	WHERE	csl_inst_code	=	instcode
	AND	csl_loyl_code	=	applicable_loyl_code;
END IF;


			IF slab_flag != 'Y' THEN
				dbms_output.put_line('Dispute amount,here the transaction amount ----->'||y.ctd_disp_amt);
				dbms_output.put_line('Defined transaction amount ----->'||y.ctd_disp_amt);
				dbms_output.put_line('Applicable loyalty points----->'||applicable_loyl_point);
				SELECT ROUND(NVL(y.ctd_disp_amt,0)/applicable_trans_amt)*applicable_loyl_point
				INTO	calc_loyl_points
				FROM	dual;
				dbms_output.put_line('Calculated loyalty points----->'||calc_loyl_points);
			ELSE
					dbms_output.put_line('Test point 4 ');
				--call the local procedure to calculate slabwise loyalty for this transaction,it will directly return the calculated loyalty points
				lp_calc_slab_loyl_points(applicable_slab_code,y.ctd_disp_amt,calc_loyl_points,errmsg);
				IF errmsg != 'OK' THEN
					errmsg := 'From LP-8 ---'||errmsg;
				END IF;

			END IF;
		IF errmsg = 'OK' THEN --errmsg = ok if

			IF loyltype = 1 THEN --charge back transaction
			calc_ind	:= -1;--multiplying factor set to minus
			ELSE
			calc_ind	:= 1;
			END IF;
		dbms_output.put_line('Calculator indicator----->'||calc_ind);
		UPDATE	CMS_LOYL_POINTS
		SET	clp_loyl_points		=	clp_loyl_points+(calc_loyl_points*calc_ind),
			clp_lupd_user		=	lupduser
		WHERE	clp_inst_code		=	instcode
		AND	clp_pan_code		=	x.cld_pan_code
		AND	clp_mbr_numb		=	x.cld_mbr_numb;

		/*IF SQL%NOTFOUND THEN
			IF loyltype != 0 THEN	--which means that the loyalty point calc is being done for transaction other that the normal transaction i.e. for charge back, representment etc
								--so a row shud be present earlier in cms_loyl_points and the SQL%notfound condition shud not arise.else some error is there
				INSERT INTO cms_loyl_points	(CLP_INST_CODE		,
								CLP_PAN_CODE		,
								CLP_MBR_NUMB		,
								CLP_LOYL_POINTS		,
								CLP_LAST_RDMDATE	,
								CLP_INS_USER		,
								CLP_LUPD_USER		)
							VALUES(	instcode	,
								x.cld_pan_code	,
								x.cld_mbr_numb	,
								calc_loyl_points,
								null		,
								lupduser	,
								lupduser	);

			END IF;
		END IF;*/

		INSERT INTO CMS_LOYL_DTL	(			CLD_INST_CODE		,
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
						VALUES(			instcode		,
									x.cld_pan_code		,
									x.cld_mbr_numb		,
									x.cld_acct_no		,
									applicable_loyl_code	,
									y.ctd_disp_amt		,
									calc_loyl_points*calc_ind,
									x.cld_addon_pan		,
									x.cld_addon_mbr		,
									y.ctd_id_col		,
									lupduser		,
									lupduser		);


	--now update the  row for which loyalty is calculated
	/*UPDATE cms_pan_trans
	SET		cpt_loyl_calc = 'Y'
	WHERE CURRENT OF c1;*/
	dbms_output.put_line(SQL%ROWCOUNT);
	END IF;--errmsg = ok if
--EXIT WHEN c1%NOTFOUND;
END LOOP; --loop of cursor c1

END LOOP;--loop of cursor c2


EXCEPTION	--Excp of main begin
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END;		--Main begin ends
/


SHOW ERRORS