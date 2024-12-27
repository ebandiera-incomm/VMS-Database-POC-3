CREATE OR REPLACE TRIGGER VMSCMS.TRG_BATCHPIN_STD  BEFORE INSERT on CMS_BATCH_PIN  FOR EACH ROW
BEGIN --Trigger body begins
 IF INSERTING THEN
  :new.cbp_ins_date := sysdate ;
 END IF;
END; --Trigger body ends
/


