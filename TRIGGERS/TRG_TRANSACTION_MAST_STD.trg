CREATE OR REPLACE TRIGGER VMSCMS.TRG_TRANSACTION_MAST_STD
    BEFORE INSERT OR UPDATE ON VMSCMS.CMS_TRANSACTION_MAST         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.ctm_ins_date := sysdate;
        :new.ctm_lupd_date := sysdate;
    ELSIF UPDATING THEN
        :new.ctm_lupd_date := sysdate;
    END IF;
END;    --Trigger body ends
/
SHOW ERRORS;


