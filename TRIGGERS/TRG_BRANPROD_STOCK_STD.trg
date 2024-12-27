CREATE OR REPLACE TRIGGER VMSCMS.trg_branprod_stock_std
 BEFORE INSERT OR UPDATE ON VMSCMS.CMS_BRANPROD_STOCK   FOR EACH ROW
BEGIN --Trigger body begins
 IF INSERTING THEN
  :new.CBS_INS_DATE := sysdate;
  :new.CBS_LUPD_DATE := sysdate;
 ELSIF UPDATING THEN
  :new.CBS_LUPD_DATE := sysdate;
 END IF;
END; --Trigger body ends
/


