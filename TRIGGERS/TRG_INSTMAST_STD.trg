CREATE OR REPLACE TRIGGER VMSCMS.trg_instmast_std
	BEFORE INSERT OR UPDATE ON cms_inst_mast
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cim_ins_date := sysdate;
	:new.cim_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cim_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


