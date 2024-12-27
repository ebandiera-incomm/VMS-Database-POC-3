CREATE OR REPLACE TRIGGER VMSCMS.trg_ttumfailed_std
	BEFORE INSERT OR UPDATE ON cms_ttum_failed
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.ctf_ins_date	:= sysdate	;
		:new.ctf_lupd_date	:= sysdate	;
	ELSIF UPDATING THEN
		:new.ctf_lupd_date	:= sysdate	;
	END IF;
END;	--Trigger body ends
/


