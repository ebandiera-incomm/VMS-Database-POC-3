CREATE OR REPLACE TRIGGER VMSCMS.trg_ansr_std
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_ANSR_MAST         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CAM_INS_DATE := sysdate    ;
        :new.CAM_LUPD_DATE   := sysdate    ;
    ELSIF UPDATING THEN
        :new.CAM_LUPD_DATE   := sysdate    ;
    END IF;
END;    --Trigger body ends
/


