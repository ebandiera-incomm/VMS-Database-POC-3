CREATE OR REPLACE PROCEDURE VMSCMS.lp_attchfee_for_annual(prodcode IN VARCHAR2,
				cardtype IN NUMBER,
				custcatg IN NUMBER,
				feecode IN NUMBER,
				calcdate IN DATE,
				lperr4 OUT VARCHAR2)
AS
v_check_ctrl          NUMBER;
V_CHECK_ME_FIRST      NUMBER;
stop_proc EXCEPTION;
BEGIN	--begin lp4
--LOOP
	DBMS_OUTPUT.PUT_LINE(CALCDATE);
	SELECT	COUNT(1)
	INTO	v_check_ctrl
	FROM	CMS_APPL_PAN
	WHERE	TRUNC(cap_next_bill_date) = TRUNC(calcdate);
--	and cap_prod_code = prodcode; -- *** ??
--
	DBMS_OUTPUT.PUT_LINE('ANNUAL '||V_CHECK_CTRL);
	--EXIT WHEN v_check_ctrl = 0;
	IF v_check_ctrl > 0 THEN
	   DBMS_OUTPUT.PUT_LINE('BEFORE INSERTING INTO CHARGE DTL for date :' || calcdate);
		INSERT INTO CMS_CHARGE_DTL(
			   		CCD_INST_CODE		,
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
					CCD_LUPD_USER,
					CCD_FILE_STATUS)
		SELECT			a.cap_inst_code	,
					a.cap_pan_code	,
					a.cap_mbr_numb	,
					a.cap_cust_code	,
					a.cap_acct_id		,
					a.cap_acct_no	,
					'A'				,
					c.cfm_feetype_code,
					b.cpf_fee_code	 ,
					99			,
					calcdate			,
					SYSDATE			,
					'N'				,
					SYSDATE+0	,
					1			,
					1,
					'N'
		FROM 			CMS_APPL_PAN a,
					CMS_PRODCCC_FEES b,
					CMS_FEE_MAST c,
					CMS_FEE_TYPES d
		WHERE			a.cap_inst_code	= 	b.cpf_inst_code
		AND			a.cap_prod_code	=	b.cpf_prod_code
		AND			a.cap_card_type	=	b.cpf_card_type
		AND     		a.cap_cust_catg	=	b.cpf_cust_catg
		AND			a.cap_inst_code	=	1
		AND			a.cap_prod_code	=	prodcode
		AND			a.cap_card_type	=	cardtype
		AND			a.cap_cust_catg	=	custcatg
		AND			calcdate  >= b.cpf_valid_from AND calcdate <= b.cpf_valid_to
		AND			TRUNC(a.cap_next_bill_date)	=	TRUNC(calcdate)
		AND			b.cpf_fee_code	=	c.cfm_fee_code
		AND			b.cpf_fee_code	=	feecode
		AND			c.cfm_feetype_code =	d.cft_feetype_code
		AND			d.cft_fee_freq		=	'A'
		AND			ROWNUM < 1000;
--	    DBMS_OUTPUT.PUT_LINE('COMPLETED INSERTION INTO CHARGE DTL');
		COMMIT; -- aDDED 04-AUG-2005
  	    DBMS_OUTPUT.PUT_LINE('BEFORE UPDATING NEXT BILL DATE  ');
		IF SQL%rowcount > 0 THEN
   		 UPDATE	CMS_APPL_PAN
		 SET		cap_next_bill_date = ADD_MONTHS(cap_next_bill_date, 12)
		 WHERE	cap_pan_code IN (SELECT	ccd_pan_code FROM	CMS_CHARGE_DTL
							 	WHERE	ccd_file_status = 'N');
--		 and trunc(cap_next_bill_date) = TRUNC(calcdate);
			IF SQL%rowcount = 0 THEN
				DBMS_OUTPUT.PUT_LINE('Error in updation of next bill date');
	    	END IF;
		 UPDATE	CMS_CHARGE_DTL
		 SET	ccd_file_status = 'Y'
		 WHERE	ccd_file_status = 'N';
			 IF SQL%rowcount = 0 THEN
				DBMS_OUTPUT.PUT_LINE('Error in updation of next bill date');
	    	 END IF;
	    END IF;
/*
		UPDATE	cms_appl_pan
		set		cap_next_bill_date = add_months(cap_next_bill_date, 12)
		WHERE	cap_pan_code in (SELECT	ccd_pan_code FROM	cms_charge_dtl
							 	WHERE	ccd_file_status = 'N');
		if sql%rowcount = 0 then
		 DBMS_OUTPUT.PUT_LINE('Error in updation of next bill date');
	    end if;
	    DBMS_OUTPUT.PUT_LINE('AFTER UPDATE1 ANNUAL');
    	DBMS_OUTPUT.PUT_LINE('BEFORE UPDATE2 ANNUAL');
		UPDATE	cms_charge_dtl
		SET	ccd_file_status = 'Y'
		WHERE	ccd_file_status = 'N';
		DBMS_OUTPUT.PUT_LINE('AFTER UPDATE2 ANNUAL');
		if sql%rowcount = 0 then
		 DBMS_OUTPUT.PUT_LINE('Error in updation of charge dtl table');
	    end if;
		--commit;
*/
		COMMIT;
		SELECT	cip_param_value
		INTO	v_check_me_first
		FROM	CMS_INST_PARAM
		WHERE	cip_param_key = 'CHECK_PROC';
		DBMS_OUTPUT.PUT_LINE(v_check_me_first);
		IF	v_check_me_first = '0' THEN
			RAISE STOP_PROC;
		END IF;
	END IF;
--END LOOP;
lperr4 := 'OK';
EXCEPTION	--main excp of lp4
	WHEN NO_DATA_FOUND THEN
		lperr4 := 'Main Excp lp5 --'||SQLERRM;
	WHEN STOP_PROC THEN
		RAISE;
	WHEN OTHERS THEN
		lperr4 := 'Main Excp lp4 --'||SQLERRM;
END;	--end lp4
/


show error