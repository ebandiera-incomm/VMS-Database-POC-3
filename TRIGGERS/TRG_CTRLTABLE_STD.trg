CREATE OR REPLACE TRIGGER VMSCMS.trg_ctrltable_std
	BEFORE INSERT OR UPDATE ON cms_ctrl_table
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cct_ins_date := sysdate;
		:new.cct_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.cct_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


