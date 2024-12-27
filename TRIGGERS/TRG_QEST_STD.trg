CREATE OR REPLACE TRIGGER VMSCMS.trg_QEST_std
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_QEST_MAST         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CQM_INS_DATE := sysdate    ;
        :new.CQM_LUPD_DATE := sysdate    ;
    ELSIF UPDATING THEN
        :new.CQM_LUPD_DATE := sysdate    ;
    END IF;
END;    --Trigger body ends
/


