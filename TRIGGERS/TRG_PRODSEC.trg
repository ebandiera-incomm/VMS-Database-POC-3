CREATE OR REPLACE TRIGGER VMSCMS.trg_prodsec
    BEFORE INSERT OR UPDATE ON  CMS_PROD_CATSEC         FOR EACH ROW
BEGIN    --Trigger body begins
IF INSERTING THEN
    :new.cpc_ins_date := sysdate;
    :new.cpc_lupd_date := sysdate;

END IF;
IF UPDATING THEN

    :new.cpc_lupd_date := sysdate;

END IF;

END;    --Trigger body ends
/


