CREATE OR REPLACE TRIGGER VMSCMS.trg_slabloyl_std
	BEFORE INSERT OR UPDATE ON cms_slab_loyl
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.csl_ins_date := sysdate;
	:new.csl_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.csl_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


