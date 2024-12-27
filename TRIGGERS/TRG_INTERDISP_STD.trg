CREATE OR REPLACE TRIGGER VMSCMS.trg_interdisp_std
	BEFORE INSERT OR UPDATE ON cms_inter_disp
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cid_ins_date := sysdate	;
		:new.cid_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.cid_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


