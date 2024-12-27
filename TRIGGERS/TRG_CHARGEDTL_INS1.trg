CREATE OR REPLACE TRIGGER VMSCMS.trg_chargedtl_ins1
	BEFORE INSERT ON cms_charge_dtl
		FOR EACH ROW
DECLARE
v_seq_fee_calc	number(9);
feetrans			number(13);

BEGIN
dbms_output.put_line('PLSQL pop Trigger called');
		SELECT seq_fee_calc.nextval
		INTO	v_seq_fee_calc
		FROM	dual;
		feetrans := to_char(sysdate,'YYYY')||lpad(v_seq_fee_calc,9,0);
		:new.ccd_fee_trans := feetrans;
dbms_output.put_line('feetrans generated--->'||feetrans);
--Now populate the plsql table
--the index is already instantiated to 1
/*dbms_output.put_line('PLSQL pop-- setting values for index'||gen_cms_pack.i);
gen_cms_pack.v_plsql_tab_feecalc(gen_cms_pack.i).instcode		:=	:new.ccd_inst_code;
gen_cms_pack.v_plsql_tab_feecalc(gen_cms_pack.i).pancode		:=	:new.ccd_pan_code;
gen_cms_pack.v_plsql_tab_feecalc(gen_cms_pack.i).mbrnumb	:=	:new.ccd_mbr_numb;
gen_cms_pack.v_plsql_tab_feecalc(gen_cms_pack.i).feetrans		:=	feetrans;
gen_cms_pack.v_plsql_tab_feecalc(gen_cms_pack.i).calcdate		:=	:new.ccd_expcalc_date;
gen_cms_pack.v_plsql_tab_feecalc(gen_cms_pack.i).feecode		:=	:new.ccd_fee_code	 ;
gen_cms_pack.i := gen_cms_pack.i+1;--increment the index by one*/

/*##Added on 11/10/2002  to update the next bill date as that after 12 months for annual fees*/
IF :new.ccd_fee_freq  = 'A' THEN
UPDATE	cms_appl_pan
SET	cap_next_bill_date = add_months(cap_next_bill_date,12)
WHERE	cap_pan_code	= :new.ccd_pan_code
AND	cap_mbr_numb	= :new.ccd_mbr_numb;
END IF;
/*##Added on 11/10/2002  to update the next bill date as that after 12 months for annual fees*/

/*##Added on 12/10/2002  to update the join feecalc = 'Y' so that next time it is not picked up for calc of join fees*/
IF :new.ccd_fee_freq  = 'O' THEN
UPDATE	cms_appl_pan
SET	cap_join_feecalc = 'Y'
WHERE	cap_pan_code	= :new.ccd_pan_code
AND	cap_mbr_numb	= :new.ccd_mbr_numb;
END IF;
/*##Added on 12/10/2002  to update the join feecalc = 'Y' so that next time it is not picked up for calc of join fees*/

EXCEPTION
WHEN OTHERS THEN
dbms_output.put_line('In main excp of trigger '||SQLERRM);
END;--trigger body ends
/


