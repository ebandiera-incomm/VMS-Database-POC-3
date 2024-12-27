CREATE OR REPLACE PROCEDURE VMSCMS.Sp_tip_process      (
				  				   lupduser IN NUMBER,
				   errmsg OUT VARCHAR2)  IS
v_tipamt     VARCHAR2(20);
v_balanceamt     VARCHAR2(20);
v_acq_inst_id_num VARCHAR2(11);
v_resp_cde VARCHAR2(3);
v_tran_tim VARCHAR2(8);

CURSOR C1 IS
SELECT CTT_CRD_NUM,CTT_AMT,CTT_TERM_ID,CTT_MER_NAME_LOC,CTT_RRN_SEQ_NUM,CTT_TRAN_DAT,ROWID
FROM CMS_TIP_TEMP
WHERE CTT_DONE_FLAG = 'N';

BEGIN

--Sn process tip
	FOR x IN c1
  		LOOP
				SAVEPOINT TIP_SVPT ;
		v_tipamt :=0;
		errmsg :='OK';
    v_acq_inst_id_num :='';
    v_resp_cde :='';
    v_tran_tim :='';

			--Sn get the tip amt
			 BEGIN
				 SELECT  X.CTT_AMT - CPT_AMT,CPT_ACQ_INST_ID_NUM,CPT_RESP_CDE,CPT_TRAN_TIM
				 INTO   v_tipamt,v_acq_inst_id_num,v_resp_cde,v_tran_tim
				 FROM   CMS_PTLF_TIP_TRANS
				 WHERE  CPT_CRD_NUM = X.CTT_CRD_NUM AND CPT_TERM_ID = X.CTT_TERM_ID AND CPT_RRN_SEQ_NUM =  X.CTT_RRN_SEQ_NUM AND CPT_TRAN_DAT = X.CTT_TRAN_DAT;
			 EXCEPTION
			  WHEN NO_DATA_FOUND THEN
			  errmsg :='No Transaction Found';
			  WHEN OTHERS THEN
			  errmsg := 'Error while calculating tip amount ' || SUBSTR(SQLERRM,1,200);
			   END;
			--En get the tip amt

			if errmsg = 'OK' THEN
			--Sn get the balance amt
			 BEGIN
				 SELECT CAM_ACCT_BAL
				 INTO   v_balanceamt
				 FROM   CMS_ACCT_MAST
				 WHERE  CAM_ACCT_NO= X.CTT_CRD_NUM;
			 EXCEPTION
			  WHEN NO_DATA_FOUND THEN
			  errmsg :='Acct not Found';
			  WHEN OTHERS THEN
			  errmsg := 'Error while calculating balance amount ' || SUBSTR(SQLERRM,1,200);
			   END;
			--En get the balance amt
		  	END IF ;

			if errmsg = 'OK' then
				if  to_number(v_balanceamt)-to_number(v_tipamt) >= 0  THEN
			--Sn update the balance amt
			 BEGIN
			UPDATE CMS_ACCT_MAST
			SET CAM_ACCT_BAL = (v_balanceamt - v_tipamt)
			WHERE CAM_ACCT_NO =X.CTT_CRD_NUM;

			IF SQL%ROWCOUNT = 1
			THEN
			errmsg := 'OK';
			ELSE
			errmsg := 'No record found for update the balance amt';
			END IF;
			EXCEPTION
			WHEN OTHERS
			THEN
			errmsg := 'Error while updating balance amount ' || SUBSTR(SQLERRM,1,200);
			 END;
			--En update the balance amt
			Else
			errmsg := 'Not Enough Balance [' ||v_balanceamt || '] to deduct tip Amount [' ||v_tipamt || '] ';
		  	END IF ;
			end if;

			if errmsg = 'OK' THEN
			--Sn update the PBF flag status
			 BEGIN
			UPDATE  CMS_APPL_PAN SET cap_pbfgen_flag ='T' , cap_lupd_date = SYSDATE ,CAP_LUPD_USER =lupduser		   				WHERE CAP_PAN_CODE =X.CTT_CRD_NUM;

			IF SQL%ROWCOUNT = 1
			THEN
			errmsg := 'OK';
			ELSE
    			errmsg := 'No record found for update the PBF Flag';
			END IF;
			EXCEPTION
			WHEN OTHERS
			THEN
			errmsg := 'Error while updating PBF Flag' || SUBSTR(SQLERRM,1,200);
						   END;
			--En update the PBF flag status
		  	END IF ;



			if errmsg = 'OK' THEN
			--Sn insert the tip transaction into Cms_ptlf_tip_trans
			 BEGIN
			Insert into cms_ptlf_tip_trans(CPT_CRD_NUM,CPT_AMT,CPT_TERM_ID,CPT_MER_NAME_LOC,CPT_RRN_SEQ_NUM
			,CPT_TRAN_DAT,CPT_TIP_FLAG,CPT_INS_USER,CPT_INS_DATE,CPT_LUPD_USER,CPT_LUPD_DATE,CPT_ACQ_INST_ID_NUM,CPT_RESP_CDE,CPT_TRAN_TIM)
			values
			(
				X.CTT_CRD_NUM,v_tipamt,X.CTT_TERM_ID,X.CTT_MER_NAME_LOC,X.CTT_RRN_SEQ_NUM,X.CTT_TRAN_DAT
				,'T',lupduser,SYSDATE,lupduser,SYSDATE,v_acq_inst_id_num,v_resp_cde,v_tran_tim
			);
			IF SQL%ROWCOUNT = 1
			THEN
			errmsg := 'OK';
			ELSE
    			errmsg := 'No record inserted into Cms_ptlf_tip_trans ';
			END IF;

			EXCEPTION
			WHEN OTHERS
			THEN
			errmsg := 'Error while insert the tip transaction into Cms_ptlf_tip_trans ' || SUBSTR(SQLERRM,1,200);
			  END;
			--En insert the tip transaction into Cms_ptlf_tip_trans
		  	END IF ;


			if errmsg = 'OK' THEN
			--Sn update the tip flag status in Cms_ptlf_tip_trans
			 BEGIN

				 UPDATE   CMS_PTLF_TIP_TRANS SET  CPT_TIP_FLAG ='Y',CPT_LUPD_USER=lupduser,CPT_LUPD_DATE=SYSDATE
				 WHERE  CPT_CRD_NUM = X.CTT_CRD_NUM AND CPT_TERM_ID = X.CTT_TERM_ID AND CPT_RRN_SEQ_NUM = X.CTT_RRN_SEQ_NUM AND CPT_TRAN_DAT = X.CTT_TRAN_DAT AND CPT_TIP_FLAG ='N';

			IF SQL%ROWCOUNT = 1
			THEN
			errmsg := 'OK';
			ELSE
    			errmsg := 'tip flag status not updated in Cms_ptlf_tip_trans';
			END IF;
			EXCEPTION
			WHEN OTHERS
			THEN
			errmsg := 'Error while insert the tip transaction into Cms_ptlf_tip_trans ' || SUBSTR(SQLERRM,1,200);
			  END;
			--En update the tip flag status in Cms_ptlf_tip_trans
		  	END IF ;



		--Sn update the process status in Cms_tip_temp

				Begin
				if errmsg = 'OK' THEN
			   		  UPDATE CMS_TIP_TEMP
					  SET ctt_done_flag = 'Y',ctt_process_date=sysdate,
					  ctt_process_result = 'Successfully Processed' --errmsg
					  WHERE ROWID = x.ROWID ; -- End
				Else
        ROLLBACK TO TIP_SVPT;
			   		  UPDATE CMS_TIP_TEMP
					  SET ctt_done_flag = 'E',ctt_process_date=sysdate,
					  ctt_process_result = errmsg --errmsg
					  WHERE ROWID = x.ROWID ;
				End if;
					Exception
				 WHEN OTHERS THEN
                 ROLLBACK TO TIP_SVPT;
				 	  errmsg := 'Error while Updating '||SQLERRM ;
			   		  UPDATE CMS_TIP_TEMP
					  SET ctt_done_flag = 'E',ctt_process_date=sysdate,
					  ctt_process_result = errmsg --errmsg
					  WHERE ROWID = x.ROWID ;
				End;

		END LOOP;
--En process tip

-- Insert unmatches and exception records to cms_unrecon_tip_trans
INSERT INTO CMS_UNRECON_TIP_TRANS (SELECT CTT_CRD_NUM,CTT_AMT,CTT_TERM_ID,CTT_MER_NAME_LOC,CTT_RRN_SEQ_NUM,CTT_TRAN_DAT,CTT_INS_DATE,CTT_INS_USER,CTT_PROCESS_DATE,CTT_PROCESS_RESULT FROM CMS_TIP_TEMP WHERE CTT_DONE_FLAG ='E');
errmsg :='OK';
EXCEPTION
	 WHEN OTHERS THEN
	errmsg := 'Main Excp -- '||SQLERRM;
END;
/


