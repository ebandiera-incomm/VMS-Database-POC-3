CREATE OR REPLACE TRIGGER VMSCMS.trg_branchregion_std
 BEFORE INSERT OR UPDATE ON CMS_branch_region
  FOR EACH ROW
BEGIN --Trigger body begins
 IF INSERTING THEN
  :NEW.cbr_ins_date := SYSDATE ;
  :NEW.cbr_lupd_date := SYSDATE ;
 ELSIF UPDATING THEN
  :NEW.cbr_lupd_date := SYSDATE ;
 END IF;
END; --Trigger body ends
/


