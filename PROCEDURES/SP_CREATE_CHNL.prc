CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_chnl ( instcode  IN NUMBER ,
            chnldesc   IN VARCHAR2 ,
            lupduser  IN NUMBER ,
            errmsg  OUT VARCHAR2)
AS
v_chnlcode NUMBER(3) ;
BEGIN  --Main begin starts
 BEGIN --Begin 1 starts
  SELECT cct_ctrl_numb
  INTO v_chnlcode
  FROM CMS_CTRL_TABLE
  WHERE cct_ctrl_code = instcode
  AND  cct_ctrl_key = 'CHANNEL'
  FOR UPDATE;

  INSERT INTO CMS_CHNL_MAST( CCM_INST_CODE   ,
         CCM_CHNL_CODE  ,
         CCM_CHNL_DESC  ,
         CCM_INS_USER   ,
         CCM_LUPD_USER         )
       VALUES( instcode  ,
         v_chnlcode ,
         chnldesc  ,
         lupduser  ,
         lupduser  );
  errmsg := 'OK';

  UPDATE CMS_CTRL_TABLE
  SET  cct_ctrl_numb = cct_ctrl_numb+1,
    cct_lupd_user = lupduser
  WHERE cct_ctrl_code = instcode
  AND  cct_ctrl_key = 'CHANNEL';
  IF SQL%ROWCOUNT != 1 THEN
   errmsg := 'Problem in updation of control number for channel';
  END IF;

 EXCEPTION
  WHEN NO_DATA_FOUND THEN
  INSERT INTO CMS_CHNL_MAST( CCM_INST_CODE   ,
         CCM_CHNL_CODE  ,
         CCM_CHNL_DESC  ,
         CCM_INS_USER   ,
         CCM_LUPD_USER         )
       VALUES( instcode  ,
         1   ,
         chnldesc  ,
         lupduser  ,
         lupduser  );

  INSERT INTO CMS_CTRL_TABLE  ( CCT_CTRL_CODE ,
         CCT_CTRL_KEY  ,
         CCT_CTRL_NUMB  ,
         CCT_CTRL_DESC ,
         CCT_INS_USER  ,
         CCT_LUPD_USER  )
       VALUES( instcode  ,
         'CHANNEL' ,
         2   ,
         'Latest Channel Code',
         lupduser  ,
         lupduser  ) ;
  errmsg := 'OK';

  WHEN OTHERS THEN
  errmsg := 'Excp 1 -- '||SQLERRM;
 END;--begin 1 ends

EXCEPTION --Excp of main begin
 WHEN OTHERS THEN
 errmsg := 'Main Exception -- '||SQLERRM;
END;  --Main begin ends
/


show error