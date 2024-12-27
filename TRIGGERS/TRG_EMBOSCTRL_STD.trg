CREATE OR REPLACE TRIGGER VMSCMS.trg_embosctrl_std
 BEFORE INSERT OR UPDATE ON cms_embos_ctrl
  FOR EACH ROW
BEGIN --Trigger body begins
IF INSERTING THEN
 :new.cec_ins_date := sysdate;
 :new.cec_lupd_date := sysdate;
ELSIF UPDATING THEN
 :new.cec_lupd_date := sysdate;
END IF;
end;
/


