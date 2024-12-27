CREATE OR REPLACE TRIGGER VMSCMS.TRG_INSTSERVER_STD
    BEFORE INSERT OR UPDATE ON VMSCMS.CSR_SERVER_DETAIL         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CSD_ins_date     := sysdate;
        :new.CSD_lupd_date := sysdate;
    ELSIF UPDATING THEN
        :new.CSD_lupd_date := sysdate;
    END IF;
END;    --Trigger body ends
/


