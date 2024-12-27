CREATE OR REPLACE TRIGGER VMSCMS.trg_seccode_mast
    BEFORE INSERT OR UPDATE ON  CMS_SECCODE_MAST         FOR EACH ROW
BEGIN    --Trigger body begins
IF INSERTING THEN
    :new.CSM_INS_DATE := sysdate;
    :new.CSM_LUPD_DATE := sysdate;

END IF;
IF UPDATING THEN

    :new.CSM_LUPD_DATE := sysdate;

END IF;

END;    --Trigger body ends
/


