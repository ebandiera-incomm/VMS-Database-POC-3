CREATE OR REPLACE TRIGGER VMSCMS.trg_branfiid_std 
	BEFORE INSERT OR UPDATE ON VMSCMS.CMS_BRAN_FIID 
		FOR EACH ROW
BEGIN	--Trigger body begins 
	IF INSERTING THEN 
		:new.cbf_ins_date := sysdate; 
		:new.cbf_lupd_date := sysdate; 
	ELSIF UPDATING THEN 
		:new.cbf_lupd_date := sysdate; 
	END IF; 
END;	--Trigger body ends
/


