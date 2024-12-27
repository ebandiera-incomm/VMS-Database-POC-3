CREATE OR REPLACE TRIGGER VMSCMS.trg_ttumupld_std
	BEFORE INSERT OR UPDATE ON cms_ttum_upload
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.ctu_ins_date	:= sysdate	;
		:new.ctu_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.ctu_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


