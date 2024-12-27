CREATE OR REPLACE TRIGGER VMSCMS.trg_sopfailure_std
    BEFORE INSERT OR UPDATE ON cms_sopfailure_dtl 
        FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CSD_INS_DATE := sysdate;
        :new.CSD_LUPD_DATE := sysdate;
    ELSIF UPDATING THEN
        :new.CSD_LUPD_DATE := sysdate;
    END IF;
END;    --Trigger body ends
/


