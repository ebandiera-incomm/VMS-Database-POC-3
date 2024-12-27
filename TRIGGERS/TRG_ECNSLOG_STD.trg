CREATE OR REPLACE TRIGGER vmscms.trg_ecnslog_std
   BEFORE INSERT OR UPDATE
   ON vmscms.cms_ecns_log
   FOR EACH ROW
BEGIN
   IF INSERTING
   THEN
      :NEW.cel_ins_date := SYSDATE;
      :NEW.cel_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.cel_lupd_date := SYSDATE;
   END IF;
END;
/
show error