CREATE OR REPLACE PROCEDURE VMSCMS.sp_usergroup_combi (instcode  IN NUMBER ,
            groupcode IN NUMBER ,
            usercode  IN VARCHAR2 ,
            userstat  IN CHAR  ,
            lupduser  IN NUMBER ,
            errmsg  OUT  VARCHAR2  )
AS

BEGIN  --Main Begin Block Starts Here

   INSERT INTO CMS_USER_GROUPMAST
     ( CUG_INST_CODE  ,
      CUG_GROUP_CODE ,
      CUG_USER_CODE ,
      CUG_USER_STAT  ,
      CUG_INS_USER  ,
      CUG_LUPD_USER )
    VALUES( instcode  ,
      groupcode ,
      usercode   ,
      userstat  ,
      lupduser  ,
      lupduser  );
    errmsg := 'OK';

EXCEPTION --Main block Exception
 WHEN DUP_VAL_ON_INDEX THEN
 	   errmsg:= 'user and group combination already exist '||usercode;
 WHEN OTHERS THEN
 errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;  --Main Begin Block Ends Here
/

SHOW ERRORS
