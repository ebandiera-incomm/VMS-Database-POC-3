CREATE OR REPLACE TRIGGER VMSCMS.trg_cafb24_std
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_CAF_B24 		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.ccb_ins_date := sysdate;
		:new.ccb_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.ccb_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


