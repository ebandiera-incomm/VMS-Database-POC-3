CREATE OR REPLACE TRIGGER VMSCMS.trg_cmsmonthwiseloyl_Redeem
AFTER INSERT  ON VMSCMS.CMS_REDEEM_LOYL FOR EACH ROW
declare
BEGIN
	-- Trans which are Matching
	UPDATE cms_monthwise_loyl SET CML_REDEEM = CML_REDEEM + :new.CRL_LOYL_POINTS , cml_lupd_user = :new.CRL_INS_USER
	WHERE  CML_ACCT_NO = :new.CRL_ACCT_NO and cml_lock = 'N';
	IF sql%notfound then
		-- Transaction from previous months to insert new row in cms_monthwise_loyl considering open balance
		INSERT into cms_monthwise_loyl
			( CML_INST_CODE  ,CML_ACCT_NO  ,CML_TRAN_DATE ,CML_LOYLOPN_BAL ,CML_LOYL_POINTS ,CML_REDEEM,cml_lock ,CML_ins_USER,CML_LUPD_USER   )
			values (:NEW.CRL_INST_CODE ,:NEW.CRL_ACCT_NO,to_char(:NEW.CRL_INS_DATE,'YYYY-MM'),0,0,-:new.CRL_LOYL_POINTS,'N',:new.CRL_ins_user,:new.CRL_lupd_user);
	End IF;
EXCEPTION
WHEN OTHERS THEN
	dbms_output.put_line('In main excp of trigger '||SQLERRM);
END;--trigger body ends
/


