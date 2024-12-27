CREATE OR REPLACE TRIGGER "VMSCMS"."TRG_PREAUTH_STD" 
	BEFORE INSERT OR UPDATE ON vmscms.cms_preauth_transaction
		FOR EACH ROW
BEGIN	--Trigger body begins
   IF :NEW.cpt_ins_date < SYSDATE - 1 THEN
      IF UPDATING THEN
         :NEW.cpt_lupd_date := SYSDATE;
      END IF;
   ELSE
	IF INSERTING THEN
		:new.cpt_ins_date := sysdate;
		:new.cpt_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.cpt_lupd_date := sysdate;
	END IF;
   END IF;	
END;	--Trigger body ends
/
