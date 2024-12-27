CREATE OR REPLACE TRIGGER VMSCMS.trg_login_audt_std
    BEFORE INSERT ON VMSCMS.CMS_LOGIN_AUDT         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CLA_INS_DATE := sysdate    ;
    END IF;
END;    --Trigger body ends
/


