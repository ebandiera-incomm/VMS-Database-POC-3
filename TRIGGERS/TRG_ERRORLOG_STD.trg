CREATE OR REPLACE TRIGGER VMSCMS.trg_errorlog_std
	BEFORE INSERT OR UPDATE ON cms_error_log
		FOR EACH ROW
BEGIN	--Trigger body begins
	:new.cel_lupd_date := sysdate;
END;	--Trigger body ends
/


