CREATE OR REPLACE TRIGGER VMSCMS.trg_chargedtl_std
	BEFORE INSERT OR UPDATE ON cms_charge_dtl
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.ccd_ins_date := sysdate;
	:new.ccd_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.ccd_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


