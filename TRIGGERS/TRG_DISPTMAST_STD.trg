CREATE OR REPLACE TRIGGER VMSCMS.trg_disptmast_std
	BEFORE INSERT OR UPDATE ON cms_disp_mast
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cdm_ins_date := sysdate	;
		:new.cdm_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.cdm_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


