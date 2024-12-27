CREATE OR REPLACE TRIGGER VMSCMS.TRG_bran_rfrsh_STD
BEFORE INSERT OR UPDATE ON cms_bran_refreshgrp
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
	:new.cbr_ins_date := sysdate;
		:new.cbr_lupd_date := sysdate;
	ELSIF UPDATING THEN
:new.cbr_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


