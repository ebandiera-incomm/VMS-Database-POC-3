CREATE OR REPLACE TRIGGER VMSCMS.trg_usgpdetl_std
    BEFORE INSERT OR UPDATE ON VMSCMS.CMS_USGPDETL_MAST         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CUM_INS_DATE := sysdate    ;
        :new.CUM_LUPD_DATE   := sysdate    ;
    ELSIF UPDATING THEN
        :new.CUM_LUPD_DATE   := sysdate    ;
    END IF;
END;    --Trigger body ends
/


