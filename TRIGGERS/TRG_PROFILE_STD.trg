CREATE OR REPLACE TRIGGER VMSCMS.TRG_profile_STD
	BEFORE INSERT OR UPDATE ON cms_profile_mast
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:NEW.cpm_ins_date := SYSDATE;
		:NEW.cpm_lupd_date := SYSDATE;
	ELSIF UPDATING THEN
		:NEW.cpm_lupd_date := SYSDATE;
	END IF;
END;
/


