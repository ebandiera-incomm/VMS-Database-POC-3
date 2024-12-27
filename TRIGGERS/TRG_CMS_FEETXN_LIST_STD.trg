CREATE OR REPLACE TRIGGER vmscms.trg_cms_feetxn_list_std
   BEFORE INSERT OR UPDATE
   ON vmscms.cms_feetxn_list
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.cfl_ins_date := SYSDATE;
      :NEW.cfl_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.cfl_lupd_date := SYSDATE;
   END IF;
END;
/
SHOW ERROR