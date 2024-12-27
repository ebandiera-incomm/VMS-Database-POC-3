CREATE OR REPLACE TRIGGER VMSCMS.trg_pinregenhist_std
	BEFORE INSERT OR UPDATE ON cms_pinregen_hist
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cph_ins_date := sysdate;
	:new.cph_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cph_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


