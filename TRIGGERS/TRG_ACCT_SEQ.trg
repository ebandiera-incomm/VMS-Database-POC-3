CREATE OR REPLACE TRIGGER VMSCMS.TRG_ACCT_SEQ
AFTER INSERT
ON VMSCMS.CMS_BRAN_MAST REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
errmsg VARCHAR2(500);
BEGIN --trigger body begins
 Sp_Create_Acctctrl_Data(:NEW.cbm_inst_code,:NEW.CBM_BRAN_CODE,:NEW.CBM_INS_USER,:NEW.CBM_INS_DATE,:NEW.cbm_lupd_user,:NEW.cbm_lupd_date,errmsg);

 IF errmsg != 'OK' THEN
  RAISE_APPLICATION_ERROR(-20001,'Error on Trigger on cms_bran_mast master -- '||errmsg) ;
 END IF;

EXCEPTION  --Exception of Trigger Body Begin
WHEN OTHERS THEN
 RAISE_APPLICATION_ERROR(-20001,'Main Execption -- '||SQLERRM || errmsg) ;
END;  --trigger body ends
/


