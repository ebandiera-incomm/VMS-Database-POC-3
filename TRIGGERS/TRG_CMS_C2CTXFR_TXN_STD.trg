CREATE OR REPLACE TRIGGER VMSCMS.trg_cms_c2ctxfr_txn_std
   BEFORE INSERT OR UPDATE
   ON VMSCMS.CMS_C2CTXFR_TRANSACTION    FOR EACH ROW
BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.cct_ins_date := SYSDATE;
      :NEW.cct_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.cct_lupd_date := SYSDATE;
   END IF;
END;                                                       --Trigger body ends
/
SHOW ERRORS;


