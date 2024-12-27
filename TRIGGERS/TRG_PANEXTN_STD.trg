CREATE OR REPLACE TRIGGER VMSCMS.TRG_PANEXTN_STD
 BEFORE INSERT OR UPDATE ON VMSCMS.CMS_PAN_EXTN   FOR EACH ROW
BEGIN --Trigger body begins
 IF INSERTING THEN
  :new.CAE_ins_date := sysdate;
  :new.CAE_lupd_date := sysdate;
 ELSIF UPDATING THEN
  :new.CAE_lupd_date := sysdate;
 END IF;
END; --Trigger body ends
/


