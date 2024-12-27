CREATE OR REPLACE TRIGGER VMSCMS.trg_rencafheader_std
 BEFORE INSERT OR UPDATE ON cms_rencaf_header
  FOR EACH ROW
BEGIN --Trigger body begins
 IF INSERTING THEN
  :new.crh_ins_date := sysdate;
  :new.crh_lupd_date := sysdate;
 ELSIF UPDATING THEN
  :new.crh_lupd_date := sysdate;
 END IF;
END; --Trigger body ends
/


