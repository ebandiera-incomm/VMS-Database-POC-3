CREATE OR REPLACE TRIGGER VMSCMS.trg_accsaudt_std
    BEFORE INSERT ON VMSCMS.CMS_ACCS_AUDT         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CAA_INS_DATE := sysdate    ;
    END IF;
END;    --Trigger body ends
/


