CREATE OR REPLACE TRIGGER VMSCMS.trg_prodcatg_smsemail_alert
     BEFORE INSERT OR UPDATE ON VMSCMS.CMS_PRODCATG_SMSEMAIL_ALERTS          FOR EACH ROW
BEGIN    --Trigger body begins
 IF INSERTING THEN
     :new.CPS_INS_DATE := sysdate;
     :new.CPS_LUPD_DATE := sysdate;
 ELSIF UPDATING THEN
     :new.CPS_LUPD_DATE := sysdate;
 END IF;
 END;    --Trigger body ends
/


