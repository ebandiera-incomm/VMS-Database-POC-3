CREATE OR REPLACE TRIGGER VMSCMS.trg_applmast_std
 BEFORE INSERT OR UPDATE ON cms_appl_mast
  FOR EACH ROW
BEGIN --Trigger body begins
 IF INSERTING THEN
  :new.cam_ins_date := sysdate;
  :new.cam_lupd_date := sysdate;
   IF trim(:new.cam_ikit_flag) IS NULL THEN
    :new.cam_ikit_flag := 'N';

   END IF;
 ELSIF UPDATING THEN
  :new.cam_lupd_date := sysdate;
 END IF;
END; --Trigger body ends
/


