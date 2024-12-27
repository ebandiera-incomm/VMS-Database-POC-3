CREATE OR REPLACE TRIGGER VMSCMS.trg_ttumctrl_std
	BEFORE INSERT OR UPDATE ON cms_ttum_ctrl
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.ctc_ins_date	:= sysdate	;
		:new.ctc_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.ctc_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


