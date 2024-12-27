CREATE OR REPLACE FUNCTION VMSCMS.FN_txndtchk(business_date IN VARCHAR2,business_time IN VARCHAR2)
RETURN NUMBER AS resp number(4);

 busidt date;
BEGIN

 begin
 busidt:=TO_DATE (business_date || business_time, 'yyyymmddhh24miss');
  resp:=1;
 EXCEPTION
 when others then
    resp:=0;
 end;

 RETURN resp;

END ;
/


