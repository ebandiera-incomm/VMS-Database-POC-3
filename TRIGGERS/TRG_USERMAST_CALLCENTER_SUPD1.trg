CREATE OR REPLACE TRIGGER VMSCMS.trg_usermast_callcenter_supd1
 BEFORE INSERT OR UPDATE OF cum_valid_frdt ON cms_user_mast_callcenter
  FOR EACH ROW
BEGIN --Trigger body begins
 IF trunc(:new.cum_valid_frdt) < trunc(sysdate) THEN
  RAISE_APPLICATION_ERROR(-20001,' Valid from date for user password cannot be less than todays date');
 END IF;
END; -- Trigger body ends
/


