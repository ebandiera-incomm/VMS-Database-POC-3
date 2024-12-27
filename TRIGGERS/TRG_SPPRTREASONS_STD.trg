CREATE OR REPLACE TRIGGER VMSCMS.trg_spprtreasons_std
	BEFORE INSERT OR UPDATE ON cms_spprt_reasons
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.csr_ins_date := sysdate;
		:new.csr_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.csr_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


