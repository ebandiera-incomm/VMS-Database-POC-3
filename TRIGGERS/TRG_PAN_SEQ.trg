CREATE OR REPLACE TRIGGER VMSCMS.TRG_PAN_SEQ
AFTER INSERT
ON VMSCMS.CMS_PROD_CATTYPE REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
errmsg VARCHAR2(500);
BEGIN --trigger body begins
 Sp_Create_Panctrl_Data(:NEW.cpc_inst_code,:NEW.CPC_PROD_CODE,:NEW.CPC_PROD_PREFIX,'PRODCATTYPE',:NEW.cpc_lupd_user,errmsg);

 IF errmsg != 'OK' THEN
  RAISE_APPLICATION_ERROR(-20001,'Error on Trigger on cms_prod_cattype master -- '||errmsg) ;
 END IF;

EXCEPTION  --Exception of Trigger Body Begin
WHEN OTHERS THEN
 RAISE_APPLICATION_ERROR(-20001,'Main Execption -- '||SQLERRM || errmsg) ;
END;  --trigger body ends
/


