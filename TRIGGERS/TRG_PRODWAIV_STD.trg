CREATE OR REPLACE TRIGGER VMSCMS.trg_prodwaiv_std
	BEFORE INSERT OR UPDATE ON cms_prod_waiv
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cpw_ins_date := sysdate;
	:new.cpw_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cpw_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


