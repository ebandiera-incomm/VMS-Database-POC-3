CREATE OR REPLACE TRIGGER VMSCMS.trg_acctstat_std
	BEFORE INSERT OR UPDATE ON cms_acct_stat
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cas_ins_date	 := sysdate;
		:new.cas_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.cas_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


