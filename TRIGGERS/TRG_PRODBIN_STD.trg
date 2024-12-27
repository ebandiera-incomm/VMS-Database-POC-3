CREATE OR REPLACE TRIGGER VMSCMS.trg_prodbin_std
	BEFORE INSERT OR UPDATE ON cms_prod_bin
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cpb_ins_date := sysdate;
	:new.cpb_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cpb_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


