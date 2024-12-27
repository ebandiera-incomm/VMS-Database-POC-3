CREATE OR REPLACE TRIGGER VMSCMS.trg_accttype_std
	BEFORE INSERT OR UPDATE ON cms_acct_type
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cat_ins_date	:= sysdate	;
		:new.cat_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.cat_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


