create or replace
PROCEDURE        VMSCMS.SP_CREATE_FEETYPES ( instcode IN NUMBER ,
       feetypedesc IN VARCHAR2,
       feefreq  IN VARCHAR2,
	   tranCode IN VARCHAR2,
       monthlyfeetype   IN VARCHAR2,--Added by Deepa
       lupduser IN NUMBER ,
       feetypecode OUT NUMBER ,
       errmsg  OUT VARCHAR2)
AS
/*************************************************
     * Modified By      :  Deepa
     * Modified Date    :  20-June-2012
     * Modified Reason  :  Fee changes
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  21-June-2012
     * Build Number     :  CMS3.5.1_RI0010_B0009
     
     * Modified By      :  Ramesh
     * Modified Date    :  08-AUG-2014
     * Modified Reason  :  Fee changes in FWR-48
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.3.1_B0003
     
     * Modified By      :  Ramesh
     * Modified Date    :  20-AUG-2014
     * Modified Reason  :  Fee changes in FWR-48
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.3.1_B0005
     
 *************************************************/

BEGIN  

 BEGIN  
  SELECT  cct_ctrl_numb
  INTO  feetypecode
  FROM  CMS_CTRL_TABLE
  WHERE  cct_ctrl_code = to_char(instcode)
  AND  cct_ctrl_key = 'FEE TYPE CODE'
  FOR  UPDATE;

  INSERT INTO CMS_FEE_TYPES( CFT_INST_CODE  ,
      CFT_FEETYPE_CODE ,
      CFT_FEETYPE_DESC ,
      CFT_FEE_FREQ  ,
	  CFT_TRAN_CODE,
      CFT_INS_USER  ,
      CFT_LUPD_USER,
      CFT_FEE_TYPE  )
     VALUES( instcode ,
      feetypecode ,
     -- UPPER(feetypedesc)||feetypecode, --Added feetypecode with fee desc for FWR-48 --Commented for FWR-48
     UPPER(feetypedesc), --Added for FWR-48
	   feefreq  ,
	  trim( tranCode),
      lupduser ,
      lupduser ,
      monthlyfeetype);
  UPDATE CMS_CTRL_TABLE
  SET cct_ctrl_numb  = cct_ctrl_numb+1,
   cct_lupd_user  = lupduser
  WHERE cct_ctrl_code  = to_char(instcode)
  AND cct_ctrl_key  = 'FEE TYPE CODE';
 errmsg := 'OK';

 EXCEPTION 
  WHEN NO_DATA_FOUND THEN
  feetypecode := 1;
  INSERT INTO CMS_FEE_TYPES( CFT_INST_CODE   ,
      CFT_FEETYPE_CODE  ,
      CFT_FEETYPE_DESC  ,
      CFT_FEE_FREQ   ,
	  CFT_TRAN_CODE,
      CFT_INS_USER   ,
      CFT_LUPD_USER  ,
      CFT_FEE_TYPE   )
     VALUES( instcode  ,
      feetypecode  ,
   --   UPPER(feetypedesc)||feetypecode , --Added feetypecode with fee desc for FWR-48 --Commented for FWR-48
   UPPER(feetypedesc), --Added for FWR-48
      feefreq   ,
	  trim( tranCode),
      lupduser  ,
      lupduser ,
      monthlyfeetype);
 INSERT INTO CMS_CTRL_TABLE ( CCT_CTRL_CODE,
     CCT_CTRL_KEY,
     CCT_CTRL_NUMB,
     CCT_CTRL_DESC,
     CCT_INS_USER,
     CCT_LUPD_USER)
   VALUES(  instcode   ,
     'FEE TYPE CODE' ,
     2   ,
     'Latest Fee Type Code for inst '||instcode||'.',
     lupduser  ,
     lupduser)  ;

  errmsg := 'OK';
  WHEN OTHERS THEN
  errmsg := 'Excp 1 '||SQLCODE||'---'||SQLERRM;
 END;  

EXCEPTION
 WHEN OTHERS THEN
 errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;
/
SHOW ERROR