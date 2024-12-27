CREATE OR REPLACE TRIGGER VMSCMS.trg_usergroup_std
	BEFORE INSERT OR UPDATE ON cms_user_group
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cug_ins_date := sysdate;
	:new.cug_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cug_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


