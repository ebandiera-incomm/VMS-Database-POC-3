CREATE OR REPLACE TRIGGER VMSCMS.trg_monthloyl_std
	BEFORE INSERT OR UPDATE ON cms_month_loyl
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cml_ins_date := sysdate	;
		:new.cml_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.cml_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


