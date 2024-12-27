CREATE OR REPLACE TRIGGER VMSCMS.trg_closedaccts_std
	BEFORE INSERT OR UPDATE ON cms_closed_accts
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cca_ins_date	:= sysdate	;
		:new.cca_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.cca_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


