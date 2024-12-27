CREATE OR REPLACE TRIGGER VMSCMS.trg_transdisp_std
	BEFORE INSERT OR UPDATE ON cms_trans_disp
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.ctd_ins_date := sysdate	;
		:new.ctd_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.ctd_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


