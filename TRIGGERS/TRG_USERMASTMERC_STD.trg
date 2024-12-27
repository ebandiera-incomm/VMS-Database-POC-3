CREATE OR REPLACE TRIGGER VMSCMS.trg_usermastmerc_std
	BEFORE INSERT OR UPDATE ON cms_user_mast_merchant
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cum_ins_date := sysdate;
	:new.cum_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cum_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


