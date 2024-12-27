CREATE OR REPLACE TRIGGER VMSCMS.trg_usermast_corporate_std
 BEFORE INSERT OR UPDATE ON VMSCMS.CMS_USER_MAST_CORPORATE   FOR EACH ROW
BEGIN --Trigger body begins
IF INSERTING THEN
 :NEW.cum_ins_date := SYSDATE;
 :NEW.cum_lupd_date := SYSDATE;
ELSIF UPDATING THEN
 :NEW.cum_lupd_date := SYSDATE;
END IF;
END; --Trigger body end
/


