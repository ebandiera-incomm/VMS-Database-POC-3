CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Purge_Applpan
                                           (prm_instcode VARCHAR2,
                                            prm_errmsg OUT   VARCHAR2)
          IS
          CURSOR c IS SELECT
		  		   	  cpr_pan_code,
					  cpr_mbr_numb,
					  cpr_card_stat,
					  cpr_pangen_date,
					  ROWID R
					  FROM CMS_PURGE_REC
					  WHERE CPR_PURGE_FLAG = 'N'
					  AND   CPR_CARD_STAT  = 'Z';
			/*CPR_PAN_CODE,
			CPR_MBR_NUMB,
			cap_card_stat,
			rowid
		      FROM CMS_APPL_PAN
		      WHERE cap_card_stat = 'Z'
			  AND  CPR_PAN_CODE = '5046420004000431';
			  --AND   CPR_PAN_CODE =  '9812341234000054';*/
	  v_errmsg VARCHAR2(300);
	  v_savepoint NUMBER DEFAULT 1;
	  EXP_ERROR_RECORD	EXCEPTION;
          BEGIN         --<MAIN_BEGIN>>
		  prm_errmsg := 'OK';
	       FOR I IN C LOOP
	       BEGIN		--<<LOOP BEGIN>>
	          SAVEPOINT v_savepoint;
                --Sn delete from CMS_LOYL_DTL
					 BEGIN
					 DELETE FROM CMS_LOYL_DTL
					 WHERE  CLD_INST_CODE = prm_instcode
					 AND    CLD_PAN_CODE = I.cpr_pan_code;
					 EXCEPTION
					 WHEN OTHERS THEN
					 v_errmsg := 'ERROR WHEN DELETING FROM LOYL_DTL'||SUBSTR(SQLERRM,1,250);
			 		 RAISE EXP_ERROR_RECORD;
					END;
                --En delete from CMS_LOYL_DTL
                --Sn delete from CMS_LOYL_POINTS
				     BEGIN
					 DELETE FROM CMS_LOYL_POINTS
					 WHERE  CLP_PAN_CODE = I.cpr_pan_code
					 AND    CLP_MBR_NUMB = I.cpr_mbr_numb;
					 EXCEPTION
					 WHEN OTHERS THEN
					 v_errmsg := 'ERROR WHEN DELETING FROM LOYL_POINTS'||SUBSTR(SQLERRM,1,250);
			 		 RAISE EXP_ERROR_RECORD;
					END;
                --En delete from CMS_LOYL_POINTS
               --Sn delete from CMS_CARD_EXCPFEE
				    BEGIN
					 DELETE FROM CMS_CARD_EXCPFEE
					 WHERE  CCE_PAN_CODE = I.cpr_pan_code;
					 EXCEPTION
					 WHEN OTHERS THEN
					 v_errmsg := 'ERROR WHEN DELETING FROM CARD_EXCPFEE'||SUBSTR(SQLERRM,1,250);
			 		 RAISE EXP_ERROR_RECORD;
					END;  
                --En delete from CMS_CARD_EXCPFEE
              --Sn delete from CMS_CARD_EXCPLOYL
				    BEGIN
					 DELETE FROM CMS_CARD_EXCPLOYL
					 WHERE  CCE_PAN_CODE = I.cpr_pan_code;
					 EXCEPTION
					 WHEN OTHERS THEN
					 v_errmsg := 'ERROR WHEN DELETING FROM EXCPLOYL'||SUBSTR(SQLERRM,1,250);
			 		 RAISE EXP_ERROR_RECORD;
					END; 
                --En delete from CMS_CARD_EXCPLOYL
				--Sn delete from CMS_CHARGE_DTL
				    BEGIN
					 DELETE FROM CMS_CHARGE_DTL
					 WHERE  CCD_PAN_CODE = I.cpr_pan_code;
					 EXCEPTION
					 WHEN OTHERS THEN
					 v_errmsg := 'ERROR WHEN DELETING FROM CHARGE_DTL'||SUBSTR(SQLERRM,1,250);
			 		 RAISE EXP_ERROR_RECORD;
					END;
				--En delete from CMS_CHARGE_DTL
				--Sn delete from CMS_PAN_ACCT
		 		BEGIN
					 DELETE FROM  CMS_PAN_ACCT
					 WHERE  CPA_INST_CODE = prm_instcode
					 AND    CPA_PAN_CODE  = I.cpr_pan_code
					 AND    CPA_MBR_NUMB  = I.cpr_mbr_numb;
				EXCEPTION
				WHEN OTHERS THEN
				v_errmsg := 'ERROR FROM PAN_ACCT'||SUBSTR(SQLERRM,1,250);
			 	RAISE EXP_ERROR_RECORD;
				END;
				--En delete from CMS_PAN_ACCT
				--Sn delete from CMS_PAN_SPPRT
				BEGIN
					 DELETE FROM  CMS_PAN_SPPRT
					 WHERE CPS_PAN_CODE  = I.cpr_pan_code;
				/*IF SQL%ROWCOUNT = 0 THEN
				   v_errmsg := 'Problem in deleting records from PAN_SPPRT';
				   RAISE EXP_ERROR_RECORD;
				END IF;	*/
				EXCEPTION
				WHEN OTHERS THEN
				v_errmsg := 'ERROR FROM PAN_SPPRT'||SUBSTR(SQLERRM,1,250);
			 			RAISE EXP_ERROR_RECORD;
				END;
		--En delete from CMS_PAN_SPPRT
		--Sn delete from CMS_PINREGEN_HIST
			 BEGIN
			 DELETE FROM CMS_PINREGEN_HIST
			 WHERE	     CPH_PAN_CODE = I.cpr_pan_code;
			 EXCEPTION
				WHEN OTHERS THEN
				v_errmsg := 'ERROR FROM PINREGEN HIST '||SUBSTR(SQLERRM,1,250);
			 RAISE EXP_ERROR_RECORD;
			 END;
		--En delete from CMS_PINREGEN_HIST
		--Sn delete from CMS_APPL_PAN
		BEGIN
			DELETE FROM  CMS_APPL_PAN
			WHERE  CAP_PAN_CODE  = I.cpr_pan_code
		        AND    CAP_MBR_NUMB  = I.cpr_mbr_numb
			AND    CAP_CARD_STAT = 'Z';
				IF SQL%ROWCOUNT = 0 THEN
				   v_errmsg := 'Problem in deleting records from APPL_PAN';
				   RAISE EXP_ERROR_RECORD;
				END IF;
		EXCEPTION
		WHEN OTHERS THEN
		         IF v_errmsg = 'OK' THEN
			    v_errmsg := 'ERROR';
			 END IF;
			 v_errmsg := v_errmsg ||SUBSTR(SQLERRM,1,200);
			 RAISE EXP_ERROR_RECORD;
		END;
		--En delete from CMS_APPL_PAN
		--Sn update the successs flag
			 UPDATE CMS_PURGE_REC
			 SET    cpr_purge_date = SYSDATE,
			        cpr_purge_flag = 'Y',
					cpr_purge_msg  = 'Successful'
			 WHERE  ROWID = I.R;
			Sp_Set_Purgeflag(I.cpr_pan_code,I.cpr_card_stat,'Y',v_errmsg);
			 		IF v_errmsg <> 'OK' THEN
			 		prm_errmsg := 'Error from set purgeflag ' || v_errmsg ;
			 		RETURN;
			 		END IF;
		--En update the success flag
		v_savepoint := v_savepoint + 1;
		EXCEPTION	   			   --<<LOOP EXCEPTION>>
		WHEN exp_error_record THEN
		ROLLBACK TO v_savepoint;
		 			UPDATE CMS_PURGE_REC
			 	 	SET    cpr_purge_date = SYSDATE,
			        cpr_purge_flag = 'E',
					cpr_purge_msg  = v_errmsg
			 		WHERE  ROWID = I.R;
		--SP_INS_PURGE_ERRORLOG (prm_instcode,I.CPR_PAN_CODE,I.CPR_CARD_STAT,v_errmsg);
				Sp_Set_Purgeflag(I.cpr_pan_code,I.cpr_card_stat,'E',v_errmsg);
			 		IF v_errmsg <> 'OK' THEN
			 		prm_errmsg := 'Error from set purgeflag ' || v_errmsg ;
			 		RETURN;
			 		END IF;
		WHEN OTHERS THEN
		ROLLBACK TO v_savepoint;
		v_errmsg := SUBSTR(SQLERRM,1,250);
		--SP_INS_PURGE_ERRORLOG (prm_instcode,I.CPR_PAN_CODE,I.CPR_CARD_STAT,v_errmsg);
		     		UPDATE CMS_PURGE_REC
			 		 SET    cpr_purge_date = SYSDATE,
			         cpr_purge_flag = 'E',
					 cpr_purge_msg  = v_errmsg
			 		 WHERE  ROWID = I.R;
				Sp_Set_Purgeflag(I.cpr_pan_code,I.cpr_card_stat,'E',v_errmsg);
			 		IF v_errmsg <> 'OK' THEN
			 		prm_errmsg := 'Error from set purgeflag ' || v_errmsg ;
			 		RETURN;
			 		END IF;
		END;		--<<LOOP END>>
		END LOOP;
      EXCEPTION     --<MAIN_EXCEPTION>
	  WHEN OTHERS THEN
	  prm_errmsg := SUBSTR(SQLERRM,1,250);
	  END;          --<MAIN_END>
/


