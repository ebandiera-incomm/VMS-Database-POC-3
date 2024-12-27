CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_usergroup_new_inst (instcode  IN NUMBER ,
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
  WHERE cct_ctrl_code = instcode
  AND  cct_ctrl_key = 'USERGROUP CODE'
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

	  
	--SN : Added on 23-Apr-2010, For Creating Default program Allocation For new Intitution's Default Admin user
	
	Insert into CMS_PROG_MAST
	(
	   CPM_INST_CODE, 
	   CPM_PROG_CODE, 
	   CPM_TAB_TYPE, 
	   CPM_MENU_LINK, 
	   CPM_PROG_NAME, 
	   CPM_MENU_PATH, 
	   CPM_MENU_DESC, 
	   CPM_PROG_ORDER, 
	   CPM_PROG_STAT, 
	   CPM_INS_USER, 
	   CPM_INS_DATE, 
	   CPM_LUPD_USER, 
	   CPM_LUPD_DATE, 
	   CPM_ADMIN_MENU
	)
	 Select DISTINCT instcode,
	   CPM_PROG_CODE, 
	   CPM_TAB_TYPE, 
	   CPM_MENU_LINK, 
	   CPM_PROG_NAME, 
	   CPM_MENU_PATH, 
	   CPM_MENU_DESC, 
	   CPM_PROG_ORDER, 
	   CPM_PROG_STAT, 
	   lupduser, 
	   SYSDATE, 
	   lupduser, 
	   SYSDATE,
	   CPM_ADMIN_MENU
	from cms_prog_mast
	where CPM_ADMIN_MENU = 'Y';
	
	
	INSERT INTO CMS_GROUP_PROG
	(
	    CGP_INST_CODE,
		CGP_GROUP_CODE,
		CGP_PROG_CODE,
		CGP_INS_USER,
		CGP_INS_DATE,
		CGP_LUPD_USER,
		CGP_LUPD_DATE
	)
	Select instcode,
	   groupcode,
	   CPM_PROG_CODE,
	   lupduser, 
	   SYSDATE,
	   lupduser, 
	   SYSDATE
	from cms_prog_mast
	where CPM_ADMIN_MENU = 'Y'
	AND CPM_INST_CODE = instcode;
	
	
	--EN : Added on 23-Apr-2010, For Creating Default program Allocation For new Intitution's Default Admin user


   UPDATE CMS_CTRL_TABLE
   SET  cct_ctrl_numb  =  cct_ctrl_numb+1,
     cct_lupd_user  = lupduser
   WHERE cct_ctrl_code  = instcode
   AND  cct_ctrl_key   = 'USERGROUP CODE';

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
SHOW ERROR