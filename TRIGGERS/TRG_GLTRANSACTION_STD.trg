CREATE OR REPLACE TRIGGER VMSCMS.trg_gltransaction_std
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_GL_TRANSACTIONS 		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:NEW.cgt_inst_date := SYSDATE;
	:NEW.cgt_lupd_date := SYSDATE;
ELSIF UPDATING THEN
	:NEW.cgt_lupd_date := SYSDATE;
END IF;
END;	--Trigger body ends
/


