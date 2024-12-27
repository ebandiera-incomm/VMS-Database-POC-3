CREATE OR REPLACE TRIGGER VMSCMS.TRG_ITEMMAST_STD
BEFORE INSERT OR UPDATE ON VMSCMS.CMS_ITEM_MAST FOR EACH ROW
BEGIN --Trigger body begins
  IF INSERTING THEN
   :new.cim_ins_date := sysdate;
   :new.cim_lupd_date := sysdate;
  ELSIF UPDATING THEN
   :new.cim_lupd_date := sysdate;
 END IF;END; --Trigger body ends
/


