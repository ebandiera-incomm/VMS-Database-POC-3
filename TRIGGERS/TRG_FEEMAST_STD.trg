CREATE OR REPLACE TRIGGER VMSCMS.trg_feemast_std
	BEFORE INSERT OR UPDATE ON cms_fee_mast
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cfm_ins_date := sysdate;
	:new.cfm_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cfm_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


