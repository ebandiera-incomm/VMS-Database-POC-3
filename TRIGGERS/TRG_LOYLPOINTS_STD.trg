CREATE OR REPLACE TRIGGER VMSCMS.trg_loylpoints_std
	BEFORE INSERT OR UPDATE ON cms_loyl_points
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.clp_ins_date := sysdate	;
		:new.clp_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.clp_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


