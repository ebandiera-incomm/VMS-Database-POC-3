CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_loylcatg (instcode  IN NUMBER ,
             catgsname IN VARCHAR2 ,
             catgdesc  IN VARCHAR2 ,
             catgprior  IN NUMBER ,
             lupduser  IN NUMBER ,
             errmsg        OUT VARCHAR2)
AS
catgcode  NUMBER(3);
BEGIN   --Main begin

 BEGIN  --Begin 1
  SELECT cct_ctrl_numb
  INTO catgcode
  FROM CMS_CTRL_TABLE
  WHERE cct_ctrl_code = instcode
  AND  cct_ctrl_key = 'LOYL CATG'
  FOR UPDATE;

  INSERT INTO CMS_LOYL_CATG  ( CLC_INST_CODE  ,
         CLC_CATG_CODE ,
         CLC_CATG_SNAME ,
         CLC_CATG_DESC ,
         CLC_CATG_PRIOR ,
         CLC_INS_USER  ,
         CLC_LUPD_USER   )
       VALUES( instcode  ,
         catgcode  ,
         catgsname ,
         catgdesc  ,
         catgprior  ,
         lupduser  ,
         lupduser  );
  UPDATE CMS_CTRL_TABLE
  SET  cct_ctrl_numb  = cct_ctrl_numb+1,
    cct_lupd_user  = lupduser
  WHERE cct_ctrl_code  = instcode
  AND  cct_ctrl_key  = 'LOYL CATG';

  errmsg := 'OK';

 EXCEPTION --Excp of begin 1
  WHEN NO_DATA_FOUND THEN
    BEGIN  --Begin 2

    INSERT INTO CMS_LOYL_CATG  ( CLC_INST_CODE  ,
           CLC_CATG_CODE ,
           CLC_CATG_SNAME ,
           CLC_CATG_DESC ,
           CLC_CATG_PRIOR ,
           CLC_INS_USER  ,
           CLC_LUPD_USER   )
         VALUES( instcode  ,
           1   ,
           catgsname ,
           catgdesc  ,
           catgprior  ,
           lupduser  ,
           lupduser  );
    INSERT INTO CMS_CTRL_TABLE ( CCT_CTRL_CODE ,
           CCT_CTRL_KEY  ,
           CCT_CTRL_NUMB  ,
           CCT_CTRL_DESC ,
           CCT_INS_USER  ,
           CCT_LUPD_USER   )
         VALUES( instcode  ,
           'LOYL CATG' ,
           2   ,
           'Latest Loyalty Catg Code',
           lupduser  ,
           lupduser  ) ;
    errmsg := 'OK';

    EXCEPTION --Excp of begin 2
     WHEN OTHERS THEN
     errmsg := 'Excp 2 --'||SQLERRM||'.';
    END ;  --end of begin 2
  WHEN OTHERS THEN
  errmsg := 'Excp 1 --'||SQLERRM||'.';
 END ; --end of begin 1

EXCEPTION  --Excp of main begin
WHEN OTHERS THEN
errmsg := 'Main Excp --'||SQLERRM||'.' ;
END;   --Main begin ends
/


