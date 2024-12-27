CREATE OR REPLACE TRIGGER VMSCMS.trg_termmast_std
	BEFORE INSERT OR UPDATE ON cms_term_mast
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.ctm_ins_date := sysdate;
	:new.ctm_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.ctm_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


