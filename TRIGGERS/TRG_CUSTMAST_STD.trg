CREATE OR REPLACE TRIGGER VMSCMS.TRG_CUSTMAST_STD 
	BEFORE INSERT OR UPDATE ON VMSCMS.cms_cust_mast
		FOR EACH ROW

BEGIN	--Trigger body begins
	IF INSERTING THEN
		:new.ccm_ins_date := sysdate;
		:new.ccm_lupd_date := sysdate;
        :new.ccm_ssn := trim(:new.ccm_ssn); 
	ELSIF UPDATING THEN
		:new.ccm_lupd_date := sysdate;
        :new.ccm_ssn := trim(:new.ccm_ssn); 
	END IF;
END;
/