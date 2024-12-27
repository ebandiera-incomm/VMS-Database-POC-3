CREATE OR REPLACE TRIGGER VMSCMS.trg_loylaudit_std
BEFORE INSERT OR UPDATE
ON cms_loyl_audit
FOR EACH ROW
BEGIN --Trigger body begins
IF INSERTING THEN
 :new.cla_ins_date  := sysdate ;
 :new.cla_lupd_date := sysdate ;
ELSIF UPDATING THEN
 :new.cla_lupd_date := sysdate ;
END IF;
END; --Trigger body ends
/


