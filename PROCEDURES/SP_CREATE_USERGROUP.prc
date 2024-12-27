CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_usergroup (instcode  IN NUMBER ,
            groupname IN VARCHAR2 ,
            accessflag IN VARCHAR2 ,
            lupduser  IN NUMBER ,
            errmsg  OUT  VARCHAR2  )
AS
groupcode NUMBER (3);


BEGIN  --Main Begin Block Starts Here
 BEGIN  --Begin 1 starts here


  SELECT cct_ctrl_numb
  INTO groupcode
  FROM CMS_CTRL_TABLE
  WHERE cct_ctrl_code = to_char(instcode)
  AND  cct_ctrl_key = 'USERGROUP CODE'
  AND  cct_inst_code = instcode
  FOR UPDATE;


   INSERT INTO CMS_USER_GROUP
     ( CUG_INST_CODE  ,
      CUG_GROUP_CODE ,
      CUG_GROUP_NAME ,
      CUG_ACCESS_FLAG ,
      CUG_INS_USER  ,
      CUG_LUPD_USER )
    VALUES( instcode  ,
      groupcode ,
      groupname ,
      accessflag ,
      lupduser  ,
      lupduser  );


   UPDATE CMS_CTRL_TABLE
   SET  cct_ctrl_numb  =  cct_ctrl_numb+1,
     cct_lupd_user  = lupduser
   WHERE cct_ctrl_code  = to_char(instcode)
   AND  cct_ctrl_key   = 'USERGROUP CODE'
   AND  cct_inst_code = instcode;

   errmsg := 'OK';

 EXCEPTION --Exception of Begin 1
  WHEN NO_DATA_FOUND THEN
   errmsg := 'Exception 1 '||'No Admin group exists for institution '||instcode||'.';
  WHEN OTHERS THEN
   errmsg := 'Exception 1 '||SQLCODE||'---'||SQLERRM;
 END;  --Begin 1 ends here

EXCEPTION --Main block Exception
 WHEN OTHERS THEN
 errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;  --Main Begin Block Ends Here
/
show error