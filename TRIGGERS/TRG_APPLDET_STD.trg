CREATE OR REPLACE TRIGGER VMSCMS.trg_appldet_std
	BEFORE INSERT OR UPDATE ON cms_appl_det
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cad_ins_date := sysdate;
		:new.cad_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.cad_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


