CREATE OR REPLACE TRIGGER VMSCMS.trg_custgroup_std
	BEFORE INSERT OR UPDATE ON cms_cust_group
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.ccg_ins_date := sysdate;
		:new.ccg_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.ccg_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


