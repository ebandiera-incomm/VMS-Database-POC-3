CREATE OR REPLACE TRIGGER VMSCMS.trg_mercmast_std
	BEFORE INSERT OR UPDATE ON cms_merc_mast
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cmm_ins_date := sysdate	;
		:new.cmm_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.cmm_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


