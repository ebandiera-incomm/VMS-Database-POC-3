CREATE OR REPLACE TRIGGER VMSCMS.trg_gifttrans_std
BEFORE INSERT OR UPDATE
ON cms_gift_trans
FOR EACH ROW
BEGIN --Trigger body begins
IF INSERTING THEN
 :new.cgt_ins_date  := sysdate ;
 :new.cgt_lupd_date := sysdate ;
ELSIF UPDATING THEN
 :new.cgt_lupd_date := sysdate ;
END IF;
END; --Trigger body ends
/


