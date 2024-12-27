CREATE OR REPLACE TRIGGER VMSCMS.trg_insttype_std
	BEFORE INSERT OR UPDATE ON cms_inst_type
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cit_ins_date := sysdate;
	:new.cit_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cit_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


