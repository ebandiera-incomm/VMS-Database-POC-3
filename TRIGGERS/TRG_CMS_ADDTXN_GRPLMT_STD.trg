CREATE OR REPLACE TRIGGER VMSCMS.TRG_CMS_ADDTXN_GRPLMT_STD
   BEFORE INSERT OR UPDATE
   ON VMSCMS.CMS_ADDTXN_GRPLMT
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.cag_ins_date := SYSDATE;
      :NEW.cag_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.cag_lupd_date := SYSDATE;
   END IF;
END;                                                       --Trigger body ends
/
show error