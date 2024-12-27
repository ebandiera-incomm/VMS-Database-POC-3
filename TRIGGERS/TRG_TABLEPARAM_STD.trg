CREATE OR REPLACE TRIGGER VMSCMS.TRG_TABLEPARAM_STD
 BEFORE INSERT OR UPDATE
 ON VMSCMS.CMS_TABLE_PARAM  REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
-- PL/SQL Block
BEGIN --Trigger body begins
 IF INSERTING THEN
  :new.ctp_ins_date  := sysdate;
  :new.ctp_lupd_date := sysdate;
 ELSIF UPDATING THEN
  :new.ctp_lupd_date := sysdate;
 END IF;
END; --Trigger body ends;
/


