CREATE OR REPLACE TRIGGER VMSCMS.TRG_LOCCODE_ID
         BEFORE INSERT ON VMSCMS.PCMS_INVENTORY_LOCCODE         FOR EACH ROW
BEGIN      --Trigger body begins
      select SEQ_PIL_LOCCODE_ID.nextval into :new.LOC_CODE_ID from dual;
     END;       --Trigger body ends
/


