CREATE OR REPLACE PACKAGE VMSCMS.Gen_Cms_Pack
AS

TYPE plsql_tab_single_column IS TABLE OF VARCHAR2(4000)
INDEX BY BINARY_INTEGER;

-------------------------for fee calc---------------------------
TYPE rec_feecalc IS RECORD
(instcode  cms_charge_dtl.ccd_inst_code%TYPE,
feetrans  cms_charge_dtl.ccd_fee_trans%TYPE,
pancode  cms_charge_dtl.ccd_pan_code%TYPE,
mbrnumb  cms_charge_dtl.ccd_mbr_numb%TYPE,
feecode  cms_charge_dtl.ccd_fee_code%TYPE,
calcdate  DATE);

TYPE plsql_tab_feecalc IS TABLE OF rec_feecalc
INDEX BY BINARY_INTEGER;
v_plsql_tab_feecalc Gen_Cms_Pack.plsql_tab_feecalc;--this is instanciated hereitself because the same variable has to be used in both the row level as  well as the statement level trigger on cms_charge_dtl
i NUMBER := 1;
-------------------------for fee calc---------------------------

-------------------------for loyalty calc---------------------------
--declare  package variables for priority
v_card_level_prior NUMBER(5) := 10000;
v_pccc_level_prior NUMBER(5) := 10000;
-------------------------for loyalty calc---------------------------

END;--end package specs
/


