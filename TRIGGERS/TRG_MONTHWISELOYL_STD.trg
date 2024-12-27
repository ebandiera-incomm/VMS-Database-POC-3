CREATE OR REPLACE TRIGGER VMSCMS.trg_monthwiseloyl_std
BEFORE INSERT OR UPDATE ON VMSCMS.CMS_MONTHWISE_LOYL FOR EACH ROW
BEGIN
 IF INSERTING THEN
  :new.cml_ins_date := sysdate;
  :new.cml_lupd_date := sysdate;
 ELSIF UPDATING THEN
  :new.cml_lupd_date := sysdate;
 END IF;
 END;
/


