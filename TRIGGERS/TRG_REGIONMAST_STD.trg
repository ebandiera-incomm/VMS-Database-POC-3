CREATE OR REPLACE TRIGGER VMSCMS.trg_regionmast_std
 BEFORE INSERT OR UPDATE ON VMSCMS.CMS_REGION_MAST   FOR EACH ROW
BEGIN --Trigger body begins
 IF INSERTING THEN
  :NEW.crm_ins_date := SYSDATE ;
  :NEW.crm_lupd_date := SYSDATE ;
 ELSIF UPDATING THEN
  :NEW.crm_lupd_date := SYSDATE ;
 END IF;
END; --Trigger body ends
/


