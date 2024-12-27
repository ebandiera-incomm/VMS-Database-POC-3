CREATE OR REPLACE TRIGGER VMSCMS."TRG_APPLPAN_STD" 
    BEFORE INSERT OR UPDATE ON cms_appl_pan
        FOR EACH ROW
BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.cap_ins_date := sysdate;
        :new.cap_lupd_date := sysdate;
        :new.cap_card_id := LPAD(seq_card_id.nextval,12,'0');
    ELSIF UPDATING THEN
        :new.cap_lupd_date := sysdate;
    END IF;
END;    --Trigger body ends
/
show error