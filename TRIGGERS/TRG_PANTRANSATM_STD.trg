CREATE OR REPLACE TRIGGER VMSCMS.trg_pantransatm_std before insert or update on cms_pan_trans_atm for each row
BEGIN --Trigger body begins
 IF INSERTING THEN
  :new.cpt_ins_date := sysdate ;
  :new.cpt_lupd_date := sysdate ;
 ELSIF UPDATING THEN
  :new.cpt_lupd_date := sysdate ;
 END IF;
END; --Trigger body ends
/


