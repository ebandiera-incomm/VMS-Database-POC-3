CREATE OR REPLACE TRIGGER VMSCMS.trg_loylmast_std
	BEFORE INSERT OR UPDATE ON cms_loyl_mast
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.clm_ins_date := sysdate	;
		:new.clm_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.clm_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


