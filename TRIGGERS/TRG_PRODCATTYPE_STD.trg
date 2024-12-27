CREATE OR REPLACE TRIGGER VMSCMS.trg_prodcattype_std
	BEFORE INSERT OR UPDATE ON VMSCMS.cms_prod_cattype
		FOR EACH ROW
BEGIN	--Trigger body begins
IF INSERTING THEN
	:new.cpc_ins_date := sysdate;
	:new.cpc_lupd_date := sysdate;
   IF  :NEW.cpc_startergpr_issue ='N'  THEN
     :new.cpc_startergpr_crdtype:=:new.cpc_card_type;
     END IF;
ELSIF UPDATING THEN
	:new.cpc_lupd_date := sysdate;
   IF  :NEW.cpc_startergpr_issue ='N'  THEN
     :new.cpc_startergpr_crdtype:=:new.cpc_card_type;
     END IF;
END IF;
END;	--Trigger body ends
/
SHOW ERROR


