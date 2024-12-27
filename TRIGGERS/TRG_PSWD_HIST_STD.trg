CREATE OR REPLACE TRIGGER VMSCMS.trg_pswd_hist_std
    BEFORE INSERT ON VMSCMS.CMS_PSWD_HIST         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CPH_INS_DATE := sysdate    ;
    END IF;
END;    --Trigger body ends
/


