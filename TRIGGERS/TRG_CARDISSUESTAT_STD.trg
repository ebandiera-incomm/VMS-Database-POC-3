CREATE OR REPLACE TRIGGER VMSCMS.trg_cardissuestat_std
 BEFORE INSERT OR UPDATE ON cms_cardissuance_status
  FOR EACH ROW
DISABLE
BEGIN 
IF INSERTING THEN
 :new.CCS_INS_DATE := sysdate;
 :new.CCS_LUPD_DATE := sysdate;
ELSIF UPDATING THEN
 :new.CCS_LUPD_DATE := sysdate;
END IF;
end;
/


