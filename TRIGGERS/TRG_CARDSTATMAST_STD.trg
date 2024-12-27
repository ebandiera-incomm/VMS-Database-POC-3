CREATE OR REPLACE TRIGGER VMSCMS.trg_cardstatmast_std
 BEFORE INSERT OR UPDATE ON cms_cardissuance_status_mast
  FOR EACH ROW
BEGIN 
IF INSERTING THEN
 :new.CCM_INS_DATE := sysdate;
 :new.CCM_LUPD_DATE := sysdate;
ELSIF UPDATING THEN
 :new.CCM_LUPD_DATE := sysdate;
END IF;
end;
/


