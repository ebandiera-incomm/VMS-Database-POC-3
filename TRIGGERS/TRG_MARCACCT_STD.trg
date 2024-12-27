CREATE OR REPLACE TRIGGER VMSCMS.trg_marcacct_std 
	BEFORE INSERT OR UPDATE ON VMSCMS.PCMS_MARC_ACCT 
		FOR EACH ROW
BEGIN	--Trigger body begins 
	IF INSERTING THEN 
		:NEW.pma_ins_date := SYSDATE	; 
		:NEW.pma_lupd_date := SYSDATE	; 
	ELSIF UPDATING THEN 
		:NEW.pma_lupd_date := SYSDATE	; 
	END IF; 
END;	--Trigger body ends
/


