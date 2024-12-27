CREATE OR REPLACE TRIGGER VMSCMS.trg_sms_serial
    BEFORE INSERT OR UPDATE ON cms_sms_serial
        FOR EACH ROW
BEGIN    --Trigger body begins
IF UPDATING THEN
    :new.CSS_SMS_DATE := sysdate;
END IF;
END;	--Trigger body ends
/


