CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_merccatg( instcode IN NUMBER ,
      merccatg IN VARCHAR2,
      catgdesc IN VARCHAR2,
      lupduser IN NUMBER ,
      errmsg  OUT VARCHAR2)
AS

uniq_excp EXCEPTION ;
PRAGMA EXCEPTION_INIT(uniq_excp,-00001);

BEGIN  --main begin
errmsg := 'OK';

 BEGIN  --begin 1

 
 INSERT INTO MCCODE( ACT_INST_CODE,
     MCCODE ,
     MCCODEDESC ,
     ACT_INS_USER ,
     ACT_LUPD_USER,
     ACTIVATIONSTATUS )
   VALUES ( instcode ,
     merccatg ,
     UPPER(catgdesc) ,
     lupduser ,
     lupduser,
     'Y' );



 EXCEPTION --excp 1
 WHEN uniq_excp THEN
 errmsg := 'Duplicate Merchant category code';
 WHEN OTHERS THEN
 errmsg := 'Excp 1 --'||SQLERRM;
 END;  --end 1

EXCEPTION --excp of main
WHEN OTHERS THEN
errmsg := 'Main Excp --'||SQLERRM;
END;  --main begin ends
/
show error