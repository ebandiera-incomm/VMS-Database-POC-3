CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_reasons( instcode  IN NUMBER ,
             intercode  IN VARCHAR2 ,
             dispcode  IN NUMBER ,
             reasoncode IN VARCHAR2 ,
             reasondesc IN VARCHAR2 ,
             days   IN NUMBER ,
             lupduser  IN NUMBER ,
             errmsg  OUT  VARCHAR2  )
AS

BEGIN  --main begin
errmsg := 'OK';
 INSERT INTO CMS_REASON_MAST (CRM_INST_CODE   ,
        CRM_INTERCHANGE_CODE ,
        CRM_DISP_CODE    ,
        CRM_REASON_CODE   ,
        CRM_DAYS_LIMT    ,
        CRM_REASON_DESC   ,
        CRM_INS_USER    ,
        CRM_LUPD_USER   )
      VALUES( instcode  ,
        intercode  ,
        dispcode  ,
        reasoncode ,
        days   ,
        reasondesc ,
        lupduser  ,
        lupduser  );
EXCEPTION --main excp
 WHEN OTHERS THEN
 errmsg := 'Main Excp -- '||SQLERRM ;
END;  --end main
/


show error