CREATE OR REPLACE TRIGGER vmscms.TRG_MRLIMITBREACH_MERCHANTNAME
   BEFORE INSERT OR UPDATE
   ON vmscms.cms_mrlimitbreach_merchantname
   FOR EACH ROW
BEGIN
   IF INSERTING
   THEN
      :NEW.cmm_lupd_date := SYSDATE;
      :NEW.cmm_ins_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.cmm_lupd_date := SYSDATE;
   END IF;
END;
/
show error