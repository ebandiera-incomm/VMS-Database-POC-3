CREATE OR REPLACE TRIGGER VMSCMS.trg_prodcccfees_std
	BEFORE INSERT OR UPDATE ON cms_prodccc_fees
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cpf_ins_date := sysdate;
	:new.cpf_lupd_date := sysdate;
ELSIF UPDATING THEN
	:new.cpf_lupd_date := sysdate;
END IF;
END;	--Trigger body ends
/


