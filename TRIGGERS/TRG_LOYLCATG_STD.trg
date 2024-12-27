CREATE OR REPLACE TRIGGER VMSCMS.trg_loylcatg_std
	BEFORE INSERT OR UPDATE ON cms_loyl_catg
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.clc_ins_date := sysdate	;
		:new.clc_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.clc_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


