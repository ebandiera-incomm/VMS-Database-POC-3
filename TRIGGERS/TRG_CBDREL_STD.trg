CREATE OR REPLACE TRIGGER VMSCMS.trg_cbdrel_std
	BEFORE INSERT OR UPDATE ON cms_cbd_rel
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.ccr_ins_date := sysdate;
		:new.ccr_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.ccr_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


