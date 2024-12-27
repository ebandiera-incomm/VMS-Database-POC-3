CREATE OR REPLACE TRIGGER VMSCMS.trg_feetypes_std
	BEFORE INSERT OR UPDATE ON cms_fee_types
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cft_ins_date := sysdate;
	:new.cft_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cft_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


