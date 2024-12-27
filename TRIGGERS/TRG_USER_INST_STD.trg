CREATE OR REPLACE TRIGGER VMSCMS.trg_user_inst_std
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_USER_INST         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CUI_INS_DATE := sysdate    ;
        :new.CUI_LUPD_DATE := sysdate    ;
    ELSIF UPDATING THEN
        :new.CUI_LUPD_DATE := sysdate    ;
    END IF;
END;    --Trigger body ends
/


