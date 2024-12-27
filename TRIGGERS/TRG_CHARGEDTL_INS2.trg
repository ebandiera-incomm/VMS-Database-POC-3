CREATE OR REPLACE TRIGGER VMSCMS.trg_chargedtl_ins2
	AFTER INSERT ON cms_charge_dtl
DECLARE
v_cce_fee_code	number(3);
v_cfm_fee_amt	number(15,6);
v_cfm_waiv_prcnt	number(3);
waivamt			number(15,6);
feeamt			number(15,6);
err				number(1) := 0;
BEGIN
IF gen_cms_pack.v_plsql_tab_feecalc.count>0 THEN-- this if condition is because we dont want this trigger to be fired for each insert (for a combination of prod+prodcattype+custcatg)
dbms_output.put_line('Statement Level Trigger called');
--dbms_output.put_line('PLSQL table row count'||gen_cms_pack.v_plsql_tab_feecalc.count);
		FOR i IN 1..gen_cms_pack.v_plsql_tab_feecalc.count
		LOOP
		--First update the pan table for the joining fee calculated flag , this has to be done irrespective of whether the pan lies in exception or not
			BEGIN
			UPDATE cms_appl_pan
			SET		cap_join_feecalc	=	 'Y'
			WHERE	cap_inst_code		=	gen_cms_pack.v_plsql_tab_feecalc(i).instcode
			AND		cap_pan_code	=	gen_cms_pack.v_plsql_tab_feecalc(i).pancode
			AND		cap_mbr_numb	=	gen_cms_pack.v_plsql_tab_feecalc(i).mbrnumb;
			END ;

		--First Find whether the PAN lies in exceptional fees table
		BEGIN	--begin 1
		SELECT	 cce_fee_code
		INTO	 v_cce_fee_code
		FROM	 cms_card_excpfee
		WHERE	 cce_inst_code	=	gen_cms_pack.v_plsql_tab_feecalc(i).instcode
		AND		 cce_pan_code	=	gen_cms_pack.v_plsql_tab_feecalc(i).pancode
		AND		 cce_mbr_numb	=	gen_cms_pack.v_plsql_tab_feecalc(i).mbrnumb
		AND		 cce_fee_code	=	gen_cms_pack.v_plsql_tab_feecalc(i).feecode
		AND		 TRUNC(gen_cms_pack.v_plsql_tab_feecalc(i).calcdate) BETWEEN TRUNC(cce_valid_from) and TRUNC(cce_valid_to);
			SELECT cfm_fee_amt
			INTO	v_cfm_fee_amt
			FROM	cms_fee_mast
			WHERE	cfm_inst_code = gen_cms_pack.v_plsql_tab_feecalc(i).instcode
			AND		cfm_fee_code = gen_cms_pack.v_plsql_tab_feecalc(i).feecode;
		EXCEPTION	--excp of begin 1
		WHEN NO_DATA_FOUND THEN
		err := 1;
		END;		--end of begin 1

		IF	err = 0 THEN
		--Find the waiver if present during that time for the pan
		BEGIN	--begin 2
		SELECT cce_waiv_prcnt
		INTO	v_cfm_waiv_prcnt
		FROM	cms_card_excpwaiv
		WHERE	cce_inst_code		=	gen_cms_pack.v_plsql_tab_feecalc(i).instcode
		AND		cce_pan_code	=	gen_cms_pack.v_plsql_tab_feecalc(i).pancode
		AND		cce_mbr_numb	=	gen_cms_pack.v_plsql_tab_feecalc(i).mbrnumb
		AND		cce_fee_code		=	v_cce_fee_code
		AND		TRUNC(gen_cms_pack.v_plsql_tab_feecalc(i).calcdate) BETWEEN TRUNC(cce_valid_from) and TRUNC(cce_valid_to);
		waivamt	:=	(v_cfm_waiv_prcnt/100)*v_cfm_fee_amt;
		EXCEPTION	--excp of begin 2
		WHEN NO_DATA_FOUND THEN
		waivamt := 0;
		END;		--end of begin 2
		END IF;

		IF err = 0 THEN
		feeamt := v_cfm_fee_amt-waivamt	;
		END IF;
		IF err = 0 THEN
		--Now update the charge table for this pan and fee trans with the new fee amount
		UPDATE cms_charge_dtl
		SET		ccd_calc_amt		=	feeamt
		WHERE	ccd_fee_trans		=	gen_cms_pack.v_plsql_tab_feecalc(i).feetrans;
		END IF;

		END LOOP;
gen_cms_pack.v_plsql_tab_feecalc.delete;
END IF;

END;--trigger body ends
/


