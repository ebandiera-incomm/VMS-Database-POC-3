CREATE OR REPLACE TRIGGER VMSCMS.trg_instparam_std
	BEFORE INSERT OR UPDATE ON cms_inst_param
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cip_ins_date	 := sysdate;
		:new.cip_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.cip_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


