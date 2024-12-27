CREATE OR REPLACE PROCEDURE VMSCMS.sp_rem_branreg (instcode  IN NUMBER ,
            brancode IN VARCHAR2,
            regcode  IN VARCHAR2 ,
            lupduser  IN NUMBER ,
            errmsg  OUT  VARCHAR2  )
AS

BEGIN  --Main Begin Block Starts Here

DELETE FROM CMS_BRANCH_REGION
WHERE cbr_inst_code = instcode
AND cbr_region_id = regcode
AND cbr_bran_code = brancode;

errmsg := 'OK';

EXCEPTION --Main block Exception
 WHEN OTHERS THEN
 errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;  --Main Begin Block Ends Here
/


SHOW ERRORS