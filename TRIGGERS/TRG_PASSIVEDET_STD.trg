CREATE OR REPLACE TRIGGER VMSCMS.trg_passivedet_std
    BEFORE INSERT OR UPDATE ON VMSCMS.CMS_PASSIVECARD_DETAILS         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CPD_INS_DATE := sysdate;
        :new.CPD_LUPD_DATE := sysdate;
    ELSIF UPDATING THEN
        :new.CPD_LUPD_DATE := sysdate;
    END IF;
END;    --Trigger body ends
/


