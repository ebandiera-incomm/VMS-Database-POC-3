CREATE OR REPLACE TRIGGER VMSCMS.trg_groupip_std
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_GROUPIP_MAST         FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CGM_INS_DATE := sysdate    ;
        :new.CGM_LUPD_DATE   := sysdate    ;
    ELSIF UPDATING THEN
        :new.CGM_LUPD_DATE   := sysdate    ;
    END IF;
END;    --Trigger body ends
/


