CREATE OR REPLACE TRIGGER VMSCMS.trg_redeemloyl_std
	BEFORE INSERT OR UPDATE ON cms_redeem_loyl
		FOR EACH ROW
BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.crl_ins_date := sysdate	;
		:new.crl_lupd_date := sysdate	;
	ELSIF UPDATING THEN
		:new.crl_lupd_date := sysdate	;
	END IF;
END;	--Trigger body ends
/


