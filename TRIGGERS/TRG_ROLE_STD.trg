CREATE OR REPLACE TRIGGER VMSCMS.trg_ROLE_std
    BEFORE INSERT OR UPDATE ON VMSCMS.CMS_ROLE_MAST         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CRM_INS_DATE := sysdate    ;
        :new.CRM_LUPD_DATE   := sysdate    ;
    ELSIF UPDATING THEN
        :new.CRM_LUPD_DATE   := sysdate    ;
    END IF;
END;    --Trigger body ends
/


