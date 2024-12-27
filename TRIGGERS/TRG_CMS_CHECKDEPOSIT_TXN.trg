CREATE OR REPLACE TRIGGER vmscms.trg_cms_checkdeposit_txn
   BEFORE INSERT OR UPDATE
   ON vmscms.cms_checkdeposit_transaction
   FOR EACH ROW
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
SHOW ERROR