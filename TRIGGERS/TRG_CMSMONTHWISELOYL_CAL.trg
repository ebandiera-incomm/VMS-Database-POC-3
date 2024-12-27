CREATE OR REPLACE TRIGGER VMSCMS.trg_cmsmonthwiseloyl_cal
AFTER INSERT  ON CMS_LOYL_Dtl
FOR EACH ROW
declare
c_loylbal	NUMBER(5);
BEGIN
	-- Trans which are that month only
	UPDATE cms_monthwise_loyl SET cml_loyl_points = cml_loyl_points + :new.CLD_LOYL_POINTS , cml_lupd_user = :new.cld_ins_user
	WHERE cml_tran_date = to_char(:new.cld_tran_date,'YYYY-MM') and CML_ACCT_NO = :new.CLD_ACCT_NO and cml_lock = 'N';
	IF sql%notfound then
		-- Transaction from previous months
		UPDATE	cms_monthwise_loyl  SET cml_loyl_points = cml_loyl_points + :new.CLD_LOYL_POINTS ,cml_lupd_user = :new.cld_ins_user
		WHERE	cml_tran_date > to_char(:new.cld_tran_date,'yyyy-MM' )
		AND	CML_ACCT_NO = :new.CLD_ACCT_NO and cml_lock = 'N';
		IF sql%notfound then
			BEGIN
				-- First insertion for particuler month make prev trans loked
				SELECT CML_LOYLOPN_BAL + CML_LOYL_POINTS - CML_REDEEM  into c_loylbal from cms_monthwise_loyl
				WHERE CML_ACCT_NO = :NEW.CLD_ACCT_NO AND cml_tran_date =
				(select max(cml_tran_date) from cms_monthwise_loyl
					where CML_ACCT_NO = :new.CLD_ACCT_NO );
				UPDATE CMS_MONTHWISE_LOYL SET CML_LOCK = 'Y' ,cml_lupd_user = :new.cld_ins_user WHERE CML_ACCT_NO = :new.CLD_ACCT_NO;
				insert into cms_monthwise_loyl
				( CML_INST_CODE  ,CML_ACCT_NO  ,CML_TRAN_DATE ,CML_LOYLOPN_BAL ,CML_LOYL_POINTS ,CML_REDEEM,cml_lock ,CML_ins_USER,CML_LUPD_USER   )
				values (:NEW.CLD_INST_CODE ,:NEW.CLD_ACCT_NO,to_char(:NEW.CLD_TRAN_DATE,'YYYY-MM'),c_loylbal,:new.CLD_LOYL_POINTS,0,'N',:new.cld_ins_user,:new.cld_lupd_user);
			EXCEPTION
			WHEN NO_DATA_FOUND then
				-- Totaly New Transaction
				INSERT into cms_monthwise_loyl
				( CML_INST_CODE  ,CML_ACCT_NO  ,CML_TRAN_DATE ,CML_LOYLOPN_BAL ,CML_LOYL_POINTS ,CML_REDEEM,cml_lock ,CML_ins_USER,CML_LUPD_USER  )
				values (:new.CLD_INST_CODE ,:new.CLD_ACCT_NO,to_char(:NEW.CLD_TRAN_DATE,'YYYY-MM'),0,:new.CLD_LOYL_POINTS,0,'N',:new.cld_ins_user,:new.cld_lupd_user);
			END;
		end if;
	end if;
EXCEPTION
WHEN OTHERS THEN
dbms_output.put_line('In main excp of trigger '||SQLERRM);
END;--trigger body ends
/


