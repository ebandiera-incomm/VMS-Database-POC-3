CREATE OR REPLACE TRIGGER VMSCMS."TRG_REMM"
    BEFORE INSERT OR UPDATE ON VMSCMS.cms_pan_ctrl
        FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CPC_INS_DATE := sysdate;
        :new.CPC_LUPD_DATE := sysdate;
	ELSIF UPDATING THEN
		:new.CPC_LUPD_DATE := sysdate;
	END IF;
END;	--Trigger body ends
/
SHOW ERRORS;


