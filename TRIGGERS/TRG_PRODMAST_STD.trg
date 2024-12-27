CREATE OR REPLACE TRIGGER VMSCMS.trg_prodmast_std
	BEFORE INSERT OR UPDATE ON cms_prod_mast
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cpm_ins_date := sysdate;
	:new.cpm_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cpm_lupd_date := sysdate;
END IF;
END;	--Trig
/


