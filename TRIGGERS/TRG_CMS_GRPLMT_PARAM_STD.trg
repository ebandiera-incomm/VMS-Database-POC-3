CREATE OR REPLACE TRIGGER VMSCMS.TRG_CMS_GRPLMT_PARAM_STD
   BEFORE INSERT OR UPDATE
   ON VMSCMS.CMS_GRPLMT_PARAM
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.cgp_ins_date := SYSDATE;
      :NEW.cgp_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.cgp_lupd_date := SYSDATE;
   END IF;
END;                                                       --Trigger body ends
/
show error