CREATE OR REPLACE TRIGGER VMSCMS.TRG_CMS_GROUP_LIMIT_STD
   BEFORE INSERT OR UPDATE
   ON VMSCMS.CMS_GROUP_LIMIT
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.cgl_ins_date := SYSDATE;
      :NEW.cgl_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.cgl_lupd_date := SYSDATE;
   END IF;
END;                                                       --Trigger body ends
/
show error