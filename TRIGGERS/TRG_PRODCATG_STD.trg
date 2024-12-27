CREATE OR REPLACE TRIGGER VMSCMS.trg_prodcatg_std
	BEFORE INSERT OR UPDATE ON cms_prod_catg
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cpc_ins_date := sysdate;
	:new.cpc_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cpc_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


