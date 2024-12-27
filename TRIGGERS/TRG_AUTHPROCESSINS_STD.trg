CREATE OR REPLACE TRIGGER VMSCMS.trg_authprocessins_std
	BEFORE INSERT OR UPDATE ON cms_auth_process
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cap_ins_date := sysdate;
	END IF;
END;	--Trigger body ends
/


