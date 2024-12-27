CREATE OR REPLACE TRIGGER VMSCMS.trg_gprcardstat_std
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_GPR_CARDSTAT 		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.CGS_INS_DATE := sysdate;
		:new.CGS_LUPD_DATE := sysdate;
	ELSIF UPDATING THEN
		:new.CGS_LUPD_DATE := sysdate;
	END IF;
END;	--Trigger body ends
/


