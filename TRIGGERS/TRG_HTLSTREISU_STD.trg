CREATE OR REPLACE TRIGGER VMSCMS.trg_htlstreisu_std
	BEFORE INSERT OR UPDATE ON cms_htlst_reisu
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.chr_ins_date	 := sysdate;
		:new.chr_lupd_date := sysdate;
	ELSIF UPDATING THEN
		:new.chr_lupd_date := sysdate;
	END IF;
END;	--Trigger body ends
/


