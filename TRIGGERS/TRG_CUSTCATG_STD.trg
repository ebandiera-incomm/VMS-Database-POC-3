CREATE OR REPLACE TRIGGER VMSCMS.trg_custcatg_std
	BEFORE INSERT OR UPDATE ON cms_cust_catg
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.ccc_ins_date := sysdate;
		:new.ccc_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.ccc_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


