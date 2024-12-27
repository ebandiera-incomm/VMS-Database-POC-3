CREATE OR REPLACE TRIGGER VMSCMS.trg_Key_update
    BEFORE   UPDATE ON cms_key_master
        FOR EACH ROW
BEGIN    --Trigger body begins
IF INSERTING THEN
    :new.CKM_INS_DATE := sysdate;
    :new.CKM_LUPD_DATE := sysdate;
ELSIF UPDATING THEN
    :new.CKM_LUPD_DATE := sysdate;
END IF;
END;    --Trigger body ends
/


