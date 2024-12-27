CREATE OR REPLACE TRIGGER VMSCMS.trg_groupprog_std
	BEFORE INSERT OR UPDATE ON cms_group_prog
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cgp_ins_date := sysdate;
	:new.cgp_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cgp_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


