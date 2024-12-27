create or replace TRIGGER VMSCMS.TRG_PANSPPRT_STD 
	BEFORE INSERT OR UPDATE ON vmscms.cms_pan_spprt
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.cps_ins_date := sysdate	;
		:new.cps_lupd_date := sysdate	;
        :new.CPS_UNIQUE_ID := seq_pan_spprt_unique_id.NEXTVAL; 
	ELSIF UPDATING THEN
		:new.cps_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/
SHOW ERROR;






