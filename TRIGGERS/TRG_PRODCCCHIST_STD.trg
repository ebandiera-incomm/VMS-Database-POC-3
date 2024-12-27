CREATE OR REPLACE TRIGGER VMSCMS.trg_prodccchist_std
	BEFORE INSERT ON cms_prod_ccc_hist
		FOR EACH ROW
BEGIN	--Trigger body begins

	:new.cpc_ins_date := sysdate;

END;	--Trigger body ends
/


