CREATE OR REPLACE TRIGGER VMSCMS.TRG_CMS_GRPLMT_MAST_STD
   BEFORE INSERT
   ON VMSCMS.CMS_GRPLMT_MAST
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.cgm_ins_date := SYSDATE;
   END IF;
END;                                                       --Trigger body ends
/
show error