CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_slabloyl (instcode  IN NUMBER ,
             loylcatg  IN NUMBER ,
             loyldesc  IN VARCHAR2 ,
             lupduser  IN NUMBER ,
             loylcode        OUT NUMBER ,
             slabcode        OUT NUMBER ,
             errmsg        OUT VARCHAR2)
AS
BEGIN   --Main begin
 --begin 1 block creates the loyalty codes
 BEGIN  --Begin 1
 SELECT cct_ctrl_numb
 INTO loylcode
 FROM CMS_CTRL_TABLE
 WHERE cct_ctrl_code = instcode
 AND  cct_ctrl_key = 'LOYL CODE'
 FOR UPDATE;

 UPDATE CMS_CTRL_TABLE
 SET  cct_ctrl_numb = cct_ctrl_numb+1,
   cct_lupd_user = lupduser
 WHERE cct_ctrl_code = instcode
 AND  cct_ctrl_key = 'LOYL CODE';
 errmsg := 'OK';
 EXCEPTION --Excp of begin 1
 WHEN NO_DATA_FOUND THEN
 loylcode := 1;
 INSERT INTO CMS_CTRL_TABLE ( CCT_CTRL_CODE ,
        CCT_CTRL_KEY  ,
        CCT_CTRL_NUMB  ,
        CCT_CTRL_DESC ,
        CCT_INS_USER  ,
        CCT_LUPD_USER   )
      VALUES( instcode  ,
        'LOYL CODE' ,
        2   ,
        'Latest Loyalty Code',
        lupduser  ,
        lupduser  ) ;
 errmsg := 'OK';
 WHEN OTHERS THEN
 errmsg := 'Excp 1 --'||SQLERRM||'.';
 END ; --End of begin 1


 IF errmsg = 'OK' THEN
 --begin 2 block creates the slab codes
 BEGIN  --Begin 2
 SELECT cct_ctrl_numb
 INTO slabcode
 FROM CMS_CTRL_TABLE
 WHERE cct_ctrl_code = instcode
 AND  cct_ctrl_key = 'SLAB CODE'
 FOR UPDATE;

 UPDATE CMS_CTRL_TABLE
 SET  cct_ctrl_numb = cct_ctrl_numb+1,
   cct_lupd_user = lupduser
 WHERE cct_ctrl_code = instcode
 AND  cct_ctrl_key = 'SLAB CODE';
 errmsg := 'OK';
 EXCEPTION --Excp of begin 2
 WHEN NO_DATA_FOUND THEN
 slabcode := 1;
 INSERT INTO CMS_CTRL_TABLE ( CCT_CTRL_CODE ,
        CCT_CTRL_KEY  ,
        CCT_CTRL_NUMB  ,
        CCT_CTRL_DESC ,
        CCT_INS_USER  ,
        CCT_LUPD_USER   )
      VALUES( instcode  ,
        'SLAB CODE' ,
        2   ,
        'Latest Slab Code',
        lupduser  ,
        lupduser  ) ;
 errmsg := 'OK';
 WHEN OTHERS THEN
 errmsg := 'Excp 2 --'||SQLERRM||'.';
 END ; --End of begin 2
 END IF;

 IF errmsg = 'OK' THEN
 --begin 3 block inserts rows into cms_loyl_mast and cms_slab_loyl
 BEGIN  --Begin 3
 INSERT INTO CMS_LOYL_MAST(    CLM_INST_CODE  ,
        CLM_LOYL_CATG  ,
        CLM_LOYL_CODE  ,
        CLM_LOYL_DESC  ,
        CLM_INS_USER  ,
        CLM_LUPD_USER  )
      VALUES(  instcode  ,
        loylcatg  ,
        loylcode  ,
        UPPER(loyldesc)  ,
        lupduser  ,
        lupduser  );

 INSERT INTO CMS_SLAB_LOYL  (CSL_INST_CODE  ,
        CSL_LOYL_CODE  ,
        CSL_SLAB_CODE  ,
        CSL_INS_USER  ,
        CSL_LUPD_USER )
      VALUES( instcode  ,
        loylcode  ,
        slabcode  ,
        lupduser  ,
        lupduser  );
 EXCEPTION --Excp of begin 3
 WHEN OTHERS THEN
 errmsg := 'Excp 3 --'||SQLERRM||'.';
 END;  --End of begin 3
 END IF;

EXCEPTION  --Excp of main begin
WHEN OTHERS THEN
errmsg := 'Main Excp --'||SQLERRM||'.' ;
END;   --Main begin ends
/


show error