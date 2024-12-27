CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_merc( instcode IN  NUMBER ,
      merccatg IN  VARCHAR2,
      merccode IN  VARCHAR2,
      mercname IN  VARCHAR2,
      mercProdFlag IN VARCHAR2,
      lupduser IN  NUMBER ,
      errmsg  OUT  VARCHAR2)
AS
foreign_excp EXCEPTION;
PRAGMA EXCEPTION_INIT(foreign_excp,-2291);

BEGIN  --main begin
errmsg := 'OK';
 INSERT INTO CMS_MERC_MAST( CMM_INST_CODE ,
     CMM_MERC_CODE ,
     CMM_MERC_CATG ,
     CMM_MERC_NAME ,
     CMM_MERC_PROD_TYPE ,
     CMM_INS_USER ,
     CMM_LUPD_USER)
   VALUES ( instcode ,
     merccode ,
     merccatg ,
     UPPER(mercname) ,
     mercProdFlag ,
     lupduser ,
     lupduser );

EXCEPTION --excp of main
WHEN foreign_excp THEN
errmsg := 'No such merchant category code found.';
WHEN OTHERS THEN
errmsg := 'Main Excp --'||SQLERRM;
END;  --main begin ends
/
show error