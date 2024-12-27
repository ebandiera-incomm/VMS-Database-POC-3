CREATE OR REPLACE TRIGGER VMSCMS.trg_prodfees_std
    BEFORE INSERT OR UPDATE ON cms_prod_fees
        FOR EACH ROW
BEGIN    --Trigger body begins
IF INSERTING THEN
    :new.cpf_ins_date := sysdate;
    :new.cpf_lupd_date := sysdate;
ELSIF UPDATING THEN
    :new.cpf_lupd_date := sysdate;
END IF;
END;    --Trigger body ends
/


