CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Reg( instcode IN  NUMBER ,
      regcode IN  VARCHAR2,
      regname IN  VARCHAR2,
      lupduser IN  NUMBER ,
      errmsg  OUT  VARCHAR2)
AS
BEGIN  --main begin
errmsg := 'OK';
 INSERT INTO CMS_REGION_MAST( CRM_INST_CODE ,
     CRM_REGION_ID ,
     CRM_REGION_NAME ,
     CRM_INS_USER ,
     CRM_LUPD_USER)
   VALUES ( instcode ,
     UPPER(regcode) ,
     UPPER(regname) ,
     lupduser ,
     lupduser );
EXCEPTION --excp of main
WHEN OTHERS THEN
errmsg := 'Main Excp --'||SQLERRM;
END;  --main begin ends
/


show error