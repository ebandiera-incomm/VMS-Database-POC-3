CREATE OR REPLACE TRIGGER VMSCMS.trg_prodcattypewaiv_std
	BEFORE INSERT OR UPDATE ON cms_prodcattype_waiv
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cpw_ins_date := sysdate;
	:new.cpw_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cpw_lupd_date := sysdate;
END IF;
END;
/


