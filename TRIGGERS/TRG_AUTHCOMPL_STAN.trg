CREATE OR REPLACE TRIGGER vmscms.TRG_AUTHCOMPL_STAN 
BEFORE INSERT OR UPDATE ON vmscms.VMS_AUTHCOMPL_STAN 
FOR EACH ROW 
BEGIN 
    IF INSERTING 
    THEN 
        :NEW.vas_lupd_date := SYSDATE;
        :NEW.vas_ins_date := SYSDATE;
    ELSIF UPDATING THEN
        :NEW.vas_lupd_date := SYSDATE;
    END IF;
END;
/
show error
