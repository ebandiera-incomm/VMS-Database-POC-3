CREATE OR REPLACE TRIGGER VMSCMS.trg_cardsumry_dwmy
   BEFORE INSERT OR UPDATE
   ON vmscms.cms_cardsumry_dwmy
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.ccd_ins_date := SYSDATE;
      :NEW.ccd_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.ccd_lupd_date := SYSDATE;
   END IF;
END;                                                       --Trigger body ends
/
SHOW ERROR;
