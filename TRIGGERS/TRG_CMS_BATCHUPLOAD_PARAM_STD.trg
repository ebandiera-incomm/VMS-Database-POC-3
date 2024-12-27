CREATE OR REPLACE TRIGGER VMSCMS.trg_cms_batchupload_param_std
   BEFORE INSERT OR UPDATE
   ON VMSCMS.cms_batchupload_param
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.cbp_ins_date := SYSDATE;
      :NEW.cbp_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.cbp_lupd_date := SYSDATE;
   END IF;
END;       
/
show error;