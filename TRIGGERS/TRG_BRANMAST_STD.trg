CREATE OR REPLACE TRIGGER VMSCMS.trg_branmast_std
	BEFORE INSERT OR UPDATE ON cms_bran_mast
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cbm_ins_date := sysdate;
		:new.cbm_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.cbm_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


