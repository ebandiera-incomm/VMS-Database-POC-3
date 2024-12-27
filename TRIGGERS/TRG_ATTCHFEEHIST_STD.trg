CREATE OR REPLACE TRIGGER VMSCMS.trg_attchfeehist_std
	BEFORE INSERT OR UPDATE ON cms_attchfee_hist
		FOR EACH ROW
BEGIN	--Trigger body begins
		:new.cah_change_date := sysdate	;
END;	--Trigger body ends
/


