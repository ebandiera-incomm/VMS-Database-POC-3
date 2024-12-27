CREATE OR REPLACE TRIGGER VMSCMS.trg_ACH_Fileprocess
	BEFORE INSERT OR UPDATE ON cms_ach_fileprocess 		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.CAF_INST_DATE := sysdate;
		:new.CAF_LUPD_DATE := sysdate;
        :NEW.CAF_RETUNRRAN_DATE:= sysdate;
	ELSIF UPDATING THEN
		:new.CAF_LUPD_DATE := sysdate;
	END IF;
END;	--Trigger body ends
/


