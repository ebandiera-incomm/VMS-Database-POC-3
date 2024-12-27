CREATE OR REPLACE TRIGGER VMSCMS.trg_msgtypemap_std
	BEFORE INSERT OR UPDATE ON cms_msgtypmap_spil
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cms_ins_date := sysdate;
		:new.cms_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.cms_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


