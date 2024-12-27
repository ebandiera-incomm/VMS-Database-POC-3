CREATE OR REPLACE TRIGGER VMSCMS.trg_PROD_ADHOCFEE_std
    BEFORE INSERT OR UPDATE ON VMSCMS.CMS_PROD_ADHOCFEE         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CPA_INS_DATE  := sysdate;
        :new.CPA_lupd_date := sysdate;
    ELSIF UPDATING THEN
        :new.CPA_lupd_date := sysdate;
    END IF;
END;    --Trigger body ends
/
SHOW ERRORS;


