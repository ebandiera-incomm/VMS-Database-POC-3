CREATE OR REPLACE TRIGGER VMSCMS.trg_merccatg_std
	BEFORE INSERT OR UPDATE ON cms_merc_catg
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cmc_ins_date := sysdate	;
		:new.cmc_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.cmc_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


