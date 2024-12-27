CREATE OR REPLACE TRIGGER VMSCMS.trg_pantrans_std
	BEFORE INSERT OR UPDATE ON cms_pan_trans
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cpt_ins_date := sysdate	;
		:new.cpt_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.cpt_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


