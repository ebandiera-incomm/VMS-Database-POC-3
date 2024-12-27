CREATE OR REPLACE TRIGGER VMSCMS.TRG_PINCTRL_STD BEFORE INSERT OR UPDATE ON VMSCMS.CMS_PIN_CTRL FOR EACH ROW
BEGIN --Trigger body begins
IF INSERTING THEN
:new.CPC_ins_date := sysdate;
:new.CPC_lupd_date := sysdate;
ELSIF UPDATING
THEN :new.CPC_lupd_date := sysdate;
END IF;
end;
/


