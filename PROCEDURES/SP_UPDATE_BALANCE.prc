CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Update_Balance(errmsg OUT VARCHAR2)
AS

CURSOR c1 IS
SELECT a.*,ROWID FROM
REC_TLF_DATA a
WHERE RTD_PROCESS_FLAG='N';

CURSOR c2 IS
SELECT a.*,ROWID
FROM REC_PTLF_DATA a
WHERE RPD_PROCESS_FLAG='N';

v_acct_id CMS_ACCT_MAST.CAM_ACCT_ID%TYPE;

  PROCEDURE	lp_update_balance(acct_id IN VARCHAR2,  amount   IN NUMBER , rvsl_flag  IN VARCHAR2 ,l_errmsg OUT VARCHAR2 )
  IS
  BEGIN
  	   l_errmsg := 'OK';

  	   IF rvsl_flag ='N' THEN -- Normal Leg
		   BEGIN
			 	   UPDATE CMS_ACCT_MAST
				   SET cam_acct_bal=cam_acct_bal-amount
				   WHERE cam_acct_id=acct_id;
		   END;
	   ELSIF rvsl_flag ='Y' THEN -- REVERSAL LEG ( FULL OR PARTIAL )
	   		 BEGIN
			 	   UPDATE CMS_ACCT_MAST
				   SET cam_acct_bal=cam_acct_bal+amount
				   WHERE cam_acct_no=acct_id;
			 END;
	   END  IF;

  EXCEPTION
  		WHEN OTHERS THEN
  			l_errmsg := 'Excp1 LP1 -- '||SQLERRM;
  END;


BEGIN

-- Start Loop For TLF Transaction
	 FOR x IN C1
	 LOOP
	 errmsg:='OK';
		    BEGIN
				  	 SELECT cam_acct_id
					 INTO v_acct_id
					 FROM CMS_ACCT_MAST
					 WHERE cam_acct_no=x.rtd_from_acct;

					 lp_update_balance(v_acct_id,
					 							 	   	     TO_NUMBER(X.RTD_AMT1)/100,
															 X.RTD_REV_FLAG,
															 errmsg);

				 	IF errmsg<> 'OK' THEN
					      UPDATE REC_TLF_DATA
    					  SET rtd_process_flag='U',rtd_err_msg=SUBSTR(errmsg,1,499)
					     WHERE ROWID=x.ROWID;
					END IF;
			EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 		 errmsg:='Account No: ' || x.rtd_from_acct  || ' Does Not Exist In  DCMS ';
				 	  UPDATE REC_TLF_DATA
					  SET rtd_process_flag='E' , rtd_err_msg=SUBSTR(errmsg,1,499)
					  WHERE ROWID=x.ROWID;
			 WHEN OTHERS THEN
			 		 errmsg:=' Error: ' || SQLERRM;
				 	  UPDATE REC_TLF_DATA
					  SET rtd_process_flag='X',rtd_err_msg=SUBSTR(errmsg,1,499)
					  WHERE ROWID=x.ROWID;
			END;
     END LOOP;
-- End Loop For TLF Transaction.


-- Start Loop For PTLF Transaction.
	 FOR y IN C2
	 LOOP
	 	 errmsg:='OK';
		    BEGIN
				  	 SELECT cam_acct_id
					 INTO v_acct_id
					 FROM CMS_ACCT_MAST
					 WHERE cam_acct_no=y.RPD_ACCT;

					 lp_update_balance(v_acct_id,
					 							  			 TO_NUMBER(y.rpd_amt_1)/100,
															 y.rpd_rev_flag,
															 errmsg);

				 	IF errmsg<> 'OK' THEN
					      UPDATE REC_PTLF_DATA
    					  SET rpd_process_flag='U',rpd_err_msg=SUBSTR(errmsg,1,499)
					      WHERE ROWID=y.ROWID;
					END IF;
			EXCEPTION
			 WHEN NO_DATA_FOUND THEN
 			 		  errmsg:='Account No: ' || y.rpd_acct  || ' Does Not Exist In  DCMS ';
				 	  UPDATE REC_PTLF_DATA
					  SET rpd_process_flag='E',rpd_err_msg=errmsg
					  WHERE ROWID=y.ROWID;
			 WHEN OTHERS THEN
			 		 errmsg:=' Error: ' || SQLERRM;
				 	  UPDATE REC_PTLF_DATA
					  SET rpd_process_flag='X',rpd_err_msg=SUBSTR(errmsg,1,499)
					  WHERE ROWID=y.ROWID;

			END;
     END LOOP;
-- End Loop For PTLF Transaction.

EXCEPTION
		 WHEN OTHERS THEN
		 errmsg:=' Unknown Error :'|| SQLERRM;

END;
/


