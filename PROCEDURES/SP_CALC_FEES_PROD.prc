CREATE OR REPLACE PROCEDURE VMSCMS.sp_calc_fees_prod(	instcode	IN	NUMBER	,
						pccc		IN	VARCHAR2,--if all then calculate fees for all the combinations else calculate for the given combination(e.g. VD01,Red,HNI) only(will be a help if job fails)
						lupduser	IN	NUMBER	,
						errmsg		OUT	VARCHAR2)
AS
calcdate			DATE;
v_cfm_fee_amt	NUMBER(15,6);
v_cpw_waiv_prcnt	NUMBER(3);
v_cce_waiv_prcnt	NUMBER(3);
waivamt			NUMBER(15,6);
feeamt			NUMBER(15,6);
datecnt			NUMBER(5)	;
mesg			VARCHAR2(500);
days				NUMBER (5);
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure 6*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--local procedure which selects the parameter which speecifies the no of days after which the account should be hit for debiting the fees
PROCEDURE lp_select_param_value
AS
BEGIN
SELECT TO_NUMBER(cip_param_value)
INTO	days
FROM	CMS_INST_PARAM
WHERE	cip_inst_code		=	instcode
AND		cip_param_key	=	'HIT ACCT';
END;
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure 6*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure 5*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--this local procedure calculates as well as attaches the fees on the card exception level((fees falling under frequency annual))
PROCEDURE lp_attchfee_for_annual_excp(calcdate IN DATE,lperr5 OUT VARCHAR2)
AS
--Pick up the rows from the Card level of fees where the calculation date lies between from and to date for the fee
CURSOR lp5c1 IS
SELECT	 cce_pan_code,cce_mbr_numb,cce_fee_code
FROM	 CMS_CARD_EXCPFEE
WHERE	 cce_inst_code	=	instcode
AND		 TRUNC(calcdate) BETWEEN TRUNC(cce_valid_from) AND TRUNC(cce_valid_to)
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
				AND		cfm_fee_code = y.cce_fee_code;
					BEGIN     --begin lp5.1
						SELECT cce_waiv_prcnt
						INTO	v_cce_waiv_prcnt
						FROM	CMS_CARD_EXCPWAIV
						WHERE	cce_inst_code		=	instcode
						AND		cce_pan_code	=	y.cce_pan_code
						AND		cce_mbr_numb	=	y.cce_mbr_numb
						AND		cce_fee_code		=	y.cce_fee_code
						AND		calcdate BETWEEN TRUNC(cce_valid_from) AND TRUNC(cce_valid_to);
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
					AND		ccd_feetype_code	=	(SELECT cfm_feetype_code FROM CMS_FEE_MAST WHERE cfm_fee_code = y.cce_fee_code)
					--AND		ccd_fee_code		=	y.cce_fee_code
					AND		ccd_fee_freq		=	'A'
					AND		TRUNC(ccd_expcalc_date)		=	TRUNC(calcdate);
					IF SQL%ROWCOUNT = 1 THEN
						dbms_output.put_line('Updated pan-->'||y.cce_pan_code);
					END IF;
					IF SQL%NOTFOUND THEN
						dbms_output.put_line('Inserting pan-->'||y.cce_pan_code);
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
--
					END IF;
				EXIT WHEN lp5c1%NOTFOUND;
				END LOOP;
			EXCEPTION	--excp of	 begin lp5
			WHEN OTHERS THEN
			lperr5 := 'Main Excp lp5 --'||SQLERRM;
			END;		--end of begin lp5
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure 5*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure 4*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--this local procedure attaches the calculated fees(fees falling under frequency annual) on the PCCC level to the cards lying uder the PCCC level
PROCEDURE lp_attchfee_for_annual(prodcode IN VARCHAR2,cardtype IN NUMBER,custcatg IN NUMBER,feecode IN NUMBER, calcdate IN DATE,lperr4 OUT VARCHAR2)
AS
BEGIN	--begin lp4
dbms_output.put_line('called lp4 with calcdate-->'||calcdate||' for prod-->'||prodcode||' and card type -->'||cardtype||' and cust catg -->'||custcatg||' and fee code -->'||feecode );
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
							SELECT  a.cap_inst_code	,
									a.cap_pan_code	,
									a.cap_mbr_numb	,
									a.cap_cust_code	,
									a.cap_acct_id		,
									a.cap_acct_no	,
									'A'				,
									c.cfm_feetype_code,
									b.cpf_fee_code	 ,
									feeamt			,
									calcdate			,
									SYSDATE			,
									'N'				,
									SYSDATE+days		,
									lupduser			,
									lupduser
							FROM 	CMS_APPL_PAN a, CMS_PRODCCC_FEES b, CMS_FEE_MAST c, CMS_FEE_TYPES d
							WHERE	a.cap_inst_code	= 	b.cpf_inst_code
							AND		a.cap_prod_code	=	b.cpf_prod_code
							AND        a.cap_card_type	=	b.cpf_card_type
							AND        a.cap_cust_catg	=	b.cpf_cust_catg
							AND		a.cap_inst_code	=	instcode
							AND		a.cap_prod_code	=	prodcode
							AND		a.cap_card_type	=	cardtype
							AND		a.cap_cust_catg	=	custcatg
							AND		TRUNC(calcdate)   BETWEEN TRUNC(b.cpf_valid_from) AND TRUNC(b.cpf_valid_to)
							/*AND		(ADD_MONTHS(TRUNC(cap_active_date),0)	=	TRUNC(calcdate)
								OR	ADD_MONTHS(TRUNC(cap_active_date),12)	=	TRUNC(calcdate)
								OR	ADD_MONTHS(TRUNC(cap_active_date),24)	=	TRUNC(calcdate))*/
							AND		TRUNC(a.cap_next_bill_date)	=	TRUNC(calcdate)
							AND		b.cpf_fee_code	=	c.cfm_fee_code
							AND		b.cpf_fee_code	=	feecode
							AND		c.cfm_feetype_code =	d.cft_feetype_code
							AND		d.cft_fee_freq		=	'A'			;
--
lperr4 := 'OK';
EXCEPTION	--main excp of lp4
WHEN OTHERS THEN
lperr4 := 'Main Excp lp4 --'||SQLERRM;
END;	--end lp4
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure 4*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure3*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--this local procedure calculates as well as attaches the fees on the card exception level((fees falling under frequency once))
PROCEDURE lp_attchfee_for_once_excp(calcdate IN DATE,lperr3 OUT VARCHAR2)
AS
--Pick up the rows from the Card level of fees where the calculation date lies between from and to date for the fee
CURSOR lp3c1 IS
SELECT	 cce_pan_code,cce_mbr_numb,cce_fee_code
FROM	 CMS_CARD_EXCPFEE
WHERE	 cce_inst_code	=	instcode
AND		 TRUNC(calcdate) BETWEEN TRUNC(cce_valid_from) AND TRUNC(cce_valid_to)
ORDER BY cce_pan_code,cce_fee_code;
BEGIN		--begin lp3
lperr3 := 'OK';
				FOR y IN lp3c1
				LOOP
					IF	lperr3 != 'OK' THEN
					EXIT;
					END IF;
				SELECT cfm_fee_amt
				INTO	v_cfm_fee_amt
				FROM	CMS_FEE_MAST
				WHERE	cfm_inst_code = instcode
				AND		cfm_fee_code = y.cce_fee_code;
					BEGIN     --begin lp3.1
						SELECT cce_waiv_prcnt
						INTO	v_cce_waiv_prcnt
						FROM	CMS_CARD_EXCPWAIV
						WHERE	cce_inst_code		=	instcode
						AND		cce_pan_code	=	y.cce_pan_code
						AND		cce_mbr_numb	=	y.cce_mbr_numb
						AND		cce_fee_code		=	y.cce_fee_code
						AND		calcdate BETWEEN TRUNC(cce_valid_from) AND TRUNC(cce_valid_to);
						waivamt	:=	(v_cce_waiv_prcnt/100)*v_cfm_fee_amt;
						lperr3 := 'OK';
					EXCEPTION --excp of --begin lp3.1
						WHEN NO_DATA_FOUND THEN
						waivamt	 :=	0;
					WHEN OTHERS THEN
						lperr3 := 'Excp Lp3.1 -- '||SQLERRM;
					END;	--end of --begin lp3.1
					IF lperr3 = 'OK' THEN
					feeamt := v_cfm_fee_amt-waivamt	;
					END IF;
					--Now update the charges table, if update fails then insert with join fee calc = 'Y'
					UPDATE CMS_CHARGE_DTL
					SET		ccd_calc_amt		=	feeamt,
							ccd_fee_code		=	y.cce_fee_code
					WHERE	ccd_pan_code	=	y.cce_pan_code
					AND		ccd_mbr_numb	= 	y.cce_mbr_numb
					AND		ccd_feetype_code	=	(SELECT cfm_feetype_code FROM CMS_FEE_MAST WHERE cfm_fee_code = y.cce_fee_code)
					--AND		ccd_fee_code		=	y.cce_fee_code
					AND		ccd_fee_freq		=	'O'
					AND		TRUNC(ccd_expcalc_date)		=	TRUNC(calcdate);
					IF SQL%ROWCOUNT = 1 THEN
						dbms_output.put_line('Updated pan-->'||y.cce_pan_code);
					END IF;
					IF SQL%NOTFOUND THEN
						dbms_output.put_line('Inserting pan-->'||y.cce_pan_code);
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
												'O'				,
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
							AND		a.cap_pan_code	=	b.cce_pan_code
							AND        a.cap_mbr_numb	=	b.cce_mbr_numb
							AND		b.cce_fee_code	=	c.cfm_fee_code
							AND		c.cfm_feetype_code =	d.cft_feetype_code
							AND		a.cap_inst_code	=	instcode
							AND		d.cft_fee_freq		=	'O'
							AND		TRUNC(cap_active_date)=	calcdate
							AND		TRUNC(calcdate)   BETWEEN TRUNC(b.cce_valid_from) AND TRUNC(b.cce_valid_to)
							AND		a.cap_pan_code	=	y.cce_pan_code
							AND		a.cap_mbr_numb	=	y.cce_mbr_numb
							AND		b.cce_fee_code	=	y.cce_fee_code
							AND		a.cap_join_feecalc =	'N';
--
					END IF;
				EXIT WHEN lp3c1%NOTFOUND;
				END LOOP;
			EXCEPTION	--excp of	 begin lp3
			WHEN OTHERS THEN
			lperr3 := 'Main Excp lp3 --'||SQLERRM;
			END;		--end of begin lp3
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure3*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure2*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--this local procedure attaches the calculated fees(fees falling under frequence once) on the PCCC level to the cards lying uder the PCCC level
PROCEDURE lp_attchfee_for_once(prodcode IN VARCHAR2,cardtype IN NUMBER,custcatg IN NUMBER,feecode IN NUMBER, calcdate IN DATE,lperr2 OUT VARCHAR2)
AS
BEGIN	--begin lp2
--dbms_output.put_line('Check point 3 - called lp2 with calcdate-->'||calcdate||' for prod-->'||prodcode||' and card type -->'||cardtype||' and cust catg -->'||custcatg);
		/*SELECT seq_fee_calc.nextval
		INTO	v_seq_fee_calc
		FROM	dual;
		feetrans := to_char(sysdate,'YYYY')||lpad(v_seq_fee_calc,9,0);*/--commented on 16-03-02...this code is shifted to the on insert trigger because the sequence is to be generated for each row inserted
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
							SELECT  a.cap_inst_code	,
									a.cap_pan_code	,
									a.cap_mbr_numb	,
									a.cap_cust_code	,
									a.cap_acct_id		,
									a.cap_acct_no	,
									'O'				,
									c.cfm_feetype_code,
									b.cpf_fee_code	 ,
									feeamt			,
									calcdate			,
									SYSDATE			,
									'N'				,
									SYSDATE+days		,
									lupduser			,
									lupduser
							FROM 	CMS_APPL_PAN a, CMS_PRODCCC_FEES b, CMS_FEE_MAST c, CMS_FEE_TYPES d
							WHERE	a.cap_inst_code	= 	b.cpf_inst_code
							AND		a.cap_prod_code	=	b.cpf_prod_code
							AND        a.cap_card_type	=	b.cpf_card_type
							AND        a.cap_cust_catg	=	b.cpf_cust_catg
							AND		b.cpf_fee_code	=	c.cfm_fee_code
							AND		c.cfm_feetype_code =	d.cft_feetype_code
							AND		a.cap_inst_code	=	instcode
							AND		d.cft_fee_freq		= 'O'
							AND		TRUNC(cap_active_date)=	calcdate
							AND		TRUNC(calcdate)   BETWEEN TRUNC(b.cpf_valid_from) AND TRUNC(b.cpf_valid_to)
							AND		a.cap_prod_code	=	prodcode
							AND		a.cap_card_type	=	cardtype
							AND		a.cap_cust_catg	=	custcatg
							AND		b.cpf_fee_code	=	feecode
							AND		a.cap_join_feecalc =	'N';
--
lperr2 := 'OK';
EXCEPTION	--main excp of lp2
WHEN OTHERS THEN
lperr2 := 'Main Excp lp2 --'||SQLERRM;
END;	--end lp2
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure2*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure1*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--this local procedure calculates the fees on the PCCC level
PROCEDURE lp_calc_on_pccc(calcdate IN DATE,lperr1 OUT VARCHAR2)
IS
CURSOR lp1c1 IS
--Pick up the rows from the 3rd level of fees where the calculation date lies between from and to date for the fee
SELECT	 cpf_prod_code, cpf_card_type, cpf_cust_catg, cpf_fee_code
FROM	 CMS_PRODCCC_FEES
WHERE	 cpf_inst_code = instcode
AND		 calcdate BETWEEN TRUNC(cpf_valid_from) AND TRUNC(cpf_valid_to)
ORDER BY cpf_prod_code, cpf_card_type, cpf_cust_catg, cpf_fee_code;
BEGIN		--begin lp1
lperr1 := 'OK';
	FOR x IN lp1c1
	LOOP
		IF	lperr1 != 'OK' THEN
		EXIT;
		END IF;
--		dbms_output.put_line('Check point 2 - called lp1 with calcdate-->'||calcdate||' for prod-->'||x.cpf_prod_code||' and card type -->'||x.cpf_card_type||' and cust catg -->'||x.cpf_cust_catg||' and fee code ---> '||x.cpf_fee_code);
		SELECT cfm_fee_amt
		INTO	v_cfm_fee_amt
		FROM	CMS_FEE_MAST
		WHERE	cfm_inst_code = instcode
		AND		cfm_fee_code = x.cpf_fee_code;
			BEGIN     --begin lp1.1
			SELECT cpw_waiv_prcnt
			INTO	v_cpw_waiv_prcnt
			FROM	CMS_PRODCCC_WAIV
			WHERE	cpw_inst_code	=	instcode
			AND		cpw_prod_code	=	x.cpf_prod_code
			AND		cpw_card_type	=	x.cpf_card_type
			AND		cpw_cust_catg	=	x.cpf_cust_catg
			AND		cpw_fee_code		=	x.cpf_fee_code
			AND		calcdate BETWEEN TRUNC(cpw_valid_from) AND TRUNC(cpw_valid_to);
			waivamt	:=	(v_cpw_waiv_prcnt/100)*v_cfm_fee_amt;
			lperr1 := 'OK';
			EXCEPTION --excp of --begin lp1.1
			WHEN NO_DATA_FOUND THEN
			waivamt	 :=	0;
			WHEN OTHERS THEN
			lperr1 := 'Excp Lp1.1 -- '||SQLERRM;
			END;	--end of --begin lp1.1
		IF lperr1 = 'OK' THEN
		feeamt := v_cfm_fee_amt-waivamt	;
		END IF;
		--this is the fee amount for the PCCC level, now attach this amount to all the cards falling under the present PCCC level
		IF lperr1 = 'OK' THEN
			lp_attchfee_for_once(x.cpf_prod_code,x.cpf_card_type,x.cpf_cust_catg,x.cpf_fee_code,calcdate,mesg)		;
			IF mesg != 'OK' THEN
			lperr1 := 'From lp_attachfee_for_once -'||mesg;
			END IF;
		END IF;
		IF lperr1 = 'OK' THEN
			lp_attchfee_for_annual(x.cpf_prod_code,x.cpf_card_type,x.cpf_cust_catg,x.cpf_fee_code,calcdate,mesg)		;
			IF mesg != 'OK' THEN
			lperr1 := 'From lp_attchfee_for_annual - '||mesg;
			END IF;
		END IF;
	--now reset the plsql table index to 1 so that it can be used for other row of  c1
	--gen_cms_pack.i := 1;
	--dbms_output.put_line('value of index after resetting--'||gen_cms_pack.i);
	EXIT WHEN lp1c1%NOTFOUND;
	END LOOP;
EXCEPTION	--main excp in lp1
WHEN OTHERS THEN
lperr1 := 'Main Excp lp1 --'||SQLERRM;
END;		--end lp1
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Local procedure1*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Main Procedure*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
BEGIN		--Main begin starts
--call the local procedure which selects the parameter which speecifies the no of days after which the account should be hit for debiting the fees
lp_select_param_value;
		BEGIN		--begin 1
				SELECT NVL(MAX(TRUNC(cpc_last_runfordate)),'01-JAN-1947')
				INTO	calcdate
				FROM	CMS_PROC_CTRL
				WHERE	cpc_proc_name	=	'FEE CALC'
				AND		cpc_succ_flag		=	'Y';
				errmsg := 'OK';
		EXCEPTION	--excp of begin 1
		WHEN OTHERS THEN
		errmsg := 'Excp 1 --'||SQLERRM;
		END;		--end of begin 1
	IF errmsg = 'OK'  THEN --if a
		SELECT	NVL(TRUNC(SYSDATE)-MAX(TRUNC(cpc_last_runfordate)),0)
		INTO	datecnt
		FROM	CMS_PROC_CTRL
		WHERE	cpc_proc_name = 'FEE CALC'
		AND		cpc_succ_flag = 'Y';
		IF	datecnt = 0 THEN-- means that either its the first time for which fee is being calculated or the proc is run successfully previously but is being run again
			 IF TRUNC(SYSDATE) = calcdate THEN
			 	errmsg := 'Procedure already run successfully on '||SYSDATE;
				dbms_output.put_line('Log point 1');
 			 ELSE
				calcdate := TRUNC(SYSDATE);
				dbms_output.put_line('Check point 1');
				 lp_calc_on_pccc(calcdate, mesg);
					IF mesg != 'OK' THEN
					errmsg := '1.From lp_calc_on_pccc -- '||mesg;
					END IF;
			 END IF;
		ELSE
		FOR i IN 1..datecnt
			LOOP
				IF errmsg != 'OK' THEN
				EXIT;
				END IF;
			calcdate := calcdate+1;
			dbms_output.put_line('Calc date before calling-=-=-=-=>>>'||calcdate);
			lp_calc_on_pccc(calcdate, mesg);
			IF mesg != 'OK' THEN
					errmsg := '2.From lp_calc_on_pccc -- '||mesg;
			END IF;
			IF errmsg = 'OK' THEN
			--now call the local proc which calculates the fees and waiver on card exceptional level(for fees falling under freq once)
			lp_attchfee_for_once_excp(calcdate,mesg);
			IF mesg != 'OK' THEN
				errmsg := '3. From lp_attchfee_for_once_excp --'||mesg;
			END IF;
			END IF;
			--now call the local proc which calculates the fees and waiver on card exceptional level(for fees falling under freq annual)
			IF errmsg = 'OK' THEN
			lp_attchfee_for_annual_excp(calcdate,mesg);
				IF mesg != 'OK' THEN
				errmsg := '4. From lp_attchfee_for_annual_excp --'||mesg;
				END IF;
			END IF;
			--insert a row in proc_ctrl for calcdate
			INSERT INTO CMS_PROC_CTRL	 (	CPC_PROC_NAME		,
								CPC_LAST_RUNDATE	,
								CPC_SUCC_FLAG		,
								CPC_LAST_RUNFORDATE	)
						VALUES(		'FEE CALC'	,
								SYSDATE		,
								'Y'		,
								calcdate	);
			END LOOP;
		END IF;
	END IF;--if a
	--now the population of the table from which the ttum file will be generated
	IF errmsg = 'OK' THEN
	sp_pop_ttum(1,'F',1,errmsg);
		IF errmsg != 'OK' THEN
		errmsg := 'From sp_pop_ttum -- '||errmsg;
		END IF;
	END IF;
EXCEPTION	--Excp of main begin
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END;		--Main begin ends
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-Main Procedure*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
/


show error