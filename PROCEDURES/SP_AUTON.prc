CREATE OR REPLACE PROCEDURE VMSCMS.sp_auton(brancode IN VARCHAR2,pan IN VARCHAR2,err IN VARCHAR2)
AS
PRAGMA autonomous_transaction;
BEGIN
INSERT INTO CMS_CARDBASE_ERR_LOG ( CEL_INST_CODE  ,
     cel_branch_code  ,
     cel_pan_code     ,
     CEL_ERROR_MESG ,
     CEL_PROB_ACTION )
   VALUES ( 1,
     brancode,
     pan,
     err  ,
     'Contact Site Administrator');
COMMIT;
END;
/


show error