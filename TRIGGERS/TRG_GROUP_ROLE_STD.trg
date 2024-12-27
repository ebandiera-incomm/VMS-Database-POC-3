CREATE OR REPLACE TRIGGER VMSCMS.trg_group_role_std
    BEFORE INSERT ON VMSCMS.CMS_GROUP_ROLE         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CGR_INS_DATE := sysdate    ;
    END IF;
END;    --Trigger body ends
/


