CREATE OR REPLACE TRIGGER VMSCMS.trg_giftcat_std
BEFORE INSERT OR UPDATE
ON cms_gift_catalogue
FOR EACH ROW
BEGIN --Trigger body begins
IF INSERTING THEN
 :new.cgc_ins_date  := sysdate ;
 :new.cgc_lupd_date := sysdate ;
ELSIF UPDATING THEN
 :new.cgc_lupd_date := sysdate ;
END IF;
END; --Trigger body ends
/


