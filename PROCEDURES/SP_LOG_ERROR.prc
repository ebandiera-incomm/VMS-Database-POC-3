CREATE OR REPLACE PROCEDURE VMSCMS."SP_LOG_ERROR" (v_file_name IN VARCHAR2,v_row_id IN NUMBER, errmsg IN VARCHAR2, lupduser IN NUMBER,proid IN NUMBER)
AS
PRAGMA autonomous_transaction;
BEGIN


 INSERT INTO CMS_ERROR_LOG ( CEL_INST_CODE  ,
     CEL_FILE_NAME  ,
     CEL_ROW_ID     ,
     CEL_ERROR_MESG ,
     CEL_LUPD_USER  ,
     CEL_LUPD_DATE  ,
     CEL_PROB_ACTION ,
     CEL_PROCESS_ID )
   VALUES ( 1 ,
     v_file_name ,
     v_row_id ,
     errmsg  ,
     lupduser ,
     SYSDATE  ,
     'Contact Site Administrator',
       proid);

 COMMIT;

END;
/


