CREATE OR REPLACE PROCEDURE VMSCMS.lp_attchfee_for_annual_excp(calcdate IN DATE, lperr5 OUT VARCHAR2)
AS
--Pick up the rows from the Card level of fees where the calculation date lies between from and to date for the fee
CURSOR	lp5c1 IS
SELECT	cce_pan_code,
		cce_mbr_numb,
		cce_fee_code
FROM	CMS_CARD_EXCPFEE
WHERE	cce_inst_code = instcode
AND		calcdate >= cce_valid_from AND calcdate <= cce_valid_to
ORDER BY cce_pan_code,cce_fee_code;
BEGIN		--begin lp3
lperr5 := 'OK';
FOR y IN lp5c1
LOOP
	IF	lperr5 != 'OK' THEN
		EXIT;
	END IF;
	SELECT cfm_fee_amt
	INTO	v_cfm_fee_amt
	FROM	CMS_FEE_MAST
	WHERE	cfm_inst_code = instcode
	AND	cfm_fee_code = y.cce_fee_code;
	BEGIN     --begin lp5.1
		SELECT cce_waiv_prcnt
		INTO	v_cce_waiv_prcnt
		FROM	CMS_CARD_EXCPWAIV
		WHERE	cce_inst_code		=	instcode
		AND	cce_pan_code	=	y.cce_pan_code
		AND	cce_mbr_numb	=	y.cce_mbr_numb
		AND	cce_fee_code		=	y.cce_fee_code
		AND	calcdate >= cce_valid_from AND calcdate <= cce_valid_to;
		waivamt	:=	(v_cce_waiv_prcnt/100)*v_cfm_fee_amt;
		lperr5 := 'OK';
	EXCEPTION --excp of --begin lp5.1
		WHEN NO_DATA_FOUND THEN
			waivamt	 :=	0;
		WHEN OTHERS THEN
			lperr5 := 'Excp Lp5.1 -- '||SQLERRM;
	END;	--end of --begin lp5.1
	IF lperr5 = 'OK' THEN
		feeamt := v_cfm_fee_amt-waivamt	;
	END IF;
	--Now update the charges table, if update fails then insert with join fee calc = 'Y'
	UPDATE CMS_CHARGE_DTL
	SET		ccd_calc_amt		=	feeamt,
	ccd_fee_code		=	y.cce_fee_code
	WHERE	ccd_pan_code	=	y.cce_pan_code
	AND		ccd_mbr_numb	= 	y.cce_mbr_numb
	AND		ccd_feetype_code	=
	(SELECT cfm_feetype_code FROM CMS_FEE_MAST WHERE cfm_fee_code = y.cce_fee_code)
	--AND		ccd_fee_code		=	y.cce_fee_code
	AND		ccd_fee_freq		=	'A'
	AND		TRUNC(ccd_expcalc_date)		=	TRUNC(calcdate);
	IF SQL%NOTFOUND THEN
	--	dbms_output.put_line('Inserting pan-->'||y.cce_pan_code);
		INSERT INTO CMS_CHARGE_DTL(	CCD_INST_CODE		,
						CCD_PAN_CODE		,
						CCD_MBR_NUMB		,
												CCD_CUST_CODE	,
												CCD_ACCT_ID		,
												CCD_ACCT_NO		,
												CCD_FEE_FREQ		,
												CCD_FEETYPE_CODE ,
												CCD_FEE_CODE		,
												CCD_CALC_AMT		,
												CCD_EXPCALC_DATE	,
												CCD_CALC_DATE		,
												CCD_FILE_NAME		,
												CCD_FILE_DATE		,
												CCD_INS_USER		,
												CCD_LUPD_USER	)
										SELECT  instcode			,
												y.cce_pan_code	,
												y.cce_mbr_numb	,
												a.cap_cust_code	,
												a.cap_acct_id		,
												a.cap_acct_no	,
												'A'				,
												c.cfm_feetype_code,
												b.cce_fee_code	 ,
												feeamt			,
												calcdate			,
												SYSDATE			,
												'N'				,
												SYSDATE+days		,
												lupduser			,
												lupduser
							FROM 	CMS_APPL_PAN a, CMS_CARD_EXCPFEE b, CMS_FEE_MAST c, CMS_FEE_TYPES d
							WHERE	a.cap_inst_code	= 	b.cce_inst_code
							AND	a.cap_pan_code	=	b.cce_pan_code
							AND     a.cap_mbr_numb	=	b.cce_mbr_numb
							AND	b.cce_fee_code	=	c.cfm_fee_code
							AND	c.cfm_feetype_code =	d.cft_feetype_code
							AND	a.cap_inst_code	=	instcode
							AND	d.cft_fee_freq		=	'A'
							/*AND		(ADD_MONTHS(TRUNC(cap_active_date),0)	=	TRUNC(calcdate)
								OR	ADD_MONTHS(TRUNC(cap_active_date),12)	=	TRUNC(calcdate)
								OR	ADD_MONTHS(TRUNC(cap_active_date),24)	=	TRUNC(calcdate))*/
							AND	TRUNC(a.cap_next_bill_date)	=	TRUNC(calcdate)
							AND	TRUNC(calcdate)   BETWEEN TRUNC(b.cce_valid_from) AND TRUNC(b.cce_valid_to)
							AND	a.cap_pan_code	=	y.cce_pan_code
							AND	a.cap_mbr_numb	=	y.cce_mbr_numb
							AND	b.cce_fee_code	=	y.cce_fee_code;
	END IF;
	EXIT WHEN lp5c1%NOTFOUND;
END LOOP;
EXCEPTION	--excp of	 begin lp5
			WHEN OTHERS THEN
			lperr5 := 'Main Excp lp5 --'||SQLERRM;
END;		--end of begin lp5
/


