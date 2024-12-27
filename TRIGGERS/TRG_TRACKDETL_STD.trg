CREATE OR REPLACE TRIGGER VMSCMS.trg_trackdetl_std
    BEFORE INSERT OR UPDATE ON VMSCMS.CMS_TRACKDETL_LGIN         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CTL_INS_DATE := sysdate    ;
        :new.CTL_LUPD_DATE   := sysdate    ;
    ELSIF UPDATING THEN
        :new.CTL_LUPD_DATE   := sysdate    ;
    END IF;
END;    --Trigger body ends
/


