CREATE OR REPLACE TRIGGER VMSCMS.trg_loyldtl_std
	BEFORE INSERT OR UPDATE ON cms_loyl_dtl
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cld_ins_date := sysdate	;
		:new.cld_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.cld_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


