CREATE OR REPLACE TRIGGER VMSCMS.trg_role_prog_std
    BEFORE INSERT ON VMSCMS.CMS_ROLE_PROG         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CRP_INS_DATE := sysdate    ;
    END IF;
END;    --Trigger body ends
/


