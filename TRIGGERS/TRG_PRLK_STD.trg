CREATE OR REPLACE TRIGGER VMSCMS.trg_prlk_std
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_PRLK_MAST         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CPM_INS_DATE := sysdate    ;
        :new.CPM_LUPD_DATE := sysdate    ;
    ELSIF UPDATING THEN
        :new.CPM_LUPD_DATE := sysdate    ;
    END IF;
END;    --Trigger body ends
/


