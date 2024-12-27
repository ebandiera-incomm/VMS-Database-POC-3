CREATE OR REPLACE TRIGGER VMSCMS.trg_prodcattypeloyl_std
	BEFORE INSERT OR UPDATE ON cms_prodcattype_loyl
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cpl_ins_date := sysdate	;
		:new.cpl_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.cpl_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


