CREATE OR REPLACE FUNCTION VMSCMS.FN_AGING(tran_date IN VARCHAR2,last_ilf_date VARCHAR2)
RETURN NUMBER AS AGING NUMBER(4) ;


BEGIN

 begin
 AGING := trunc(to_date(last_ilf_date,'YYMMDD')) - trunc(to_date(tran_date,'YYMMDD'));

 EXCEPTION
 when others then
 AGING:=0;
 end;

 RETURN AGING;

END ;
/


show error