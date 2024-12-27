CREATE OR REPLACE PROCEDURE VMSCMS.sp_card_renewal
			  (
				prm_inst_code	  NUMBER,
				prm_ins_date	  DATE,
				prm_bin_list	  renew_bin_array,
				prm_branch_list	  renew_branch_array,
				prm_lupd_user	  NUMBER,
				prm_errmsg	  OUT VARCHAR2
			   )
IS
v_bran_cnt					NUMBER;
v_bin_cnt					NUMBER;
v_hsm_mode					CMS_INST_PARAM.cip_param_value%type;
v_renew_param				CMS_INST_PARAM.cip_param_value%type;
v_expiryparam				CMS_INST_PARAM.cip_param_value%type;
v_from_date					DATE;
v_to_date					DATE;
v_expry_date				DATE;
v_emboss_flag				CMS_APPL_PAN.cap_embos_flag%type;
v_renew_reccnt				NUMBER			DEFAULT 0;
v_check_failed_rec			NUMBER;
v_renew_cnt					NUMBER;
v_rencaf_fname				VARCHAR2(90);
v_errmsg					VARCHAR2(300);
v_pan_code					CMS_PAN_ACCT.cpa_pan_code%type;
v_savepoint					NUMBER default 0;
v_remark					VARCHAR2(300) DEFAULT 'Renew';
v_branch_code				varchar2(30);
v_bin_code					number(6);
v_branch_cnt				number;
v_bin_count					number;
exp_reject_record			EXCEPTION;


CURSOR	c_renew_rec
		   (
		    p_inst_code		NUMBER,
		    p_bran_code		VARCHAR2,
		    p_bin_code		NUMBER,
		    p_from_date		DATE,
		    p_to_date		DATE)
	IS	    
	SELECT
		cap_pan_code,
		cap_card_stat,
		cap_prod_catg,
		cap_mbr_numb,
		cap_disp_name,
		cap_appl_bran,
		cap_expry_date,
		cap_acct_no
		
	FROM	CMS_APPL_PAN
	WHERE	cap_inst_code		 =    p_inst_code
	and		cap_expry_date			 >=  p_from_date
	AND		cap_expry_date			 <=  p_to_date
	AND		cap_appl_bran		 	 =  p_bran_code
	AND		substr(cap_pan_code,1,6) =  p_bin_code 
	and		cap_prod_catg 			 = 'D';
BEGIN				--<< MAIN BEGIN >>
	--Sn get no of records in branch array 
	
		v_bran_cnt := prm_branch_list.count;
		DBMS_OUTPUT.PUT_LINE('Branch count ' || v_bran_cnt);
		
	--En get no of records in branch array
	
	--Sn get no of records in BIN atrray
	
		v_bin_cnt  :=  prm_bin_list.count;
		DBMS_OUTPUT.PUT_LINE('Bin count ' || v_bin_cnt);
		
	--En get no of records in BIN array
	--Sn get HSM detail
	-- Rahul 28 Sep 05
	BEGIN
		SELECT 	CIP_PARAM_VALUE
		INTO 	v_hsm_mode
		FROM 	CMS_INST_PARAM
		WHERE 	cip_param_key='HSM_MODE';

		IF v_hsm_mode='Y' THEN
		   v_emboss_flag:='Y'; -- i.e. generate embossa file.
		ELSE
		   v_emboss_flag:='N'; -- i.e. don't generate embossa file.
		END IF;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   v_hsm_mode:='N';
 	   	   v_emboss_flag:='N'; -- i.e. don't generate embossa file.

	END;
	
	--En get HSM detail
	--Sn get expiry parameter
	BEGIN
		SELECT	cip_param_value
		INTO	v_expiryparam
		FROM	CMS_INST_PARAM
		WHERE	cip_param_key = 'CARD EXPRY';
	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		prm_errmsg := 'Expiry parameter not defined in master';
		RETURN;
		
		WHEN OTHERS THEN
		prm_errmsg := 'Error while selecting expry parameter from master' || substr(sqlerrm,1,150);
		RETURN;
	END;
	--En get expiry parameter
	
	--Sn get expiry parameter
	BEGIN
		SELECT	cip_param_value
		INTO	v_renew_param
		FROM	CMS_INST_PARAM
		WHERE	cip_param_key = 'RENEWCAF';
	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		prm_errmsg := 'No of parameter for renewal CAF not defined in master';
		RETURN;
		
		WHEN OTHERS THEN
		prm_errmsg := 'Error while selecting renewal CAF parameter from master' || substr(sqlerrm,1,150);
		RETURN;
	END;
	--En get expiry parameter
	
	--Sn set date
	
	v_from_date  :=  last_day(add_months(prm_ins_date , -1)) + 1;
	v_to_date	 :=  last_day(prm_ins_date);
	v_expry_date :=  LAST_DAY(ADD_MONTHS(prm_ins_date, v_expiryparam));
	
	--En set date
	
	--Sn Loop for branch
	
		FOR I IN 1 .. v_bran_cnt LOOP
			DBMS_OUTPUT.PUT_LINE('Branch No ' || prm_branch_list(i));
			
		--Sn loop for BIN
		
			FOR J IN 1..v_bin_cnt LOOP
			DBMS_OUTPUT.PUT_LINE('BIN No ' || prm_bin_list(j));
			
			v_branch_code := prm_branch_list(i);
			v_bin_code	  := prm_bin_list(j);
			v_branch_cnt  := length(prm_branch_list(i));
			v_bin_cnt	  := length(prm_bin_list(j));
			
				--Sn loop for no of cards
				
				FOR K IN  c_renew_rec(prm_inst_code,
					  	  			  prm_branch_list(i),
									  prm_bin_list(j),
					  	  			  v_from_date,
									  v_to_date
									  )
				LOOP
				
				BEGIN				  --<<CARD WISE LOOP>>
									  
						v_savepoint := v_savepoint + 1;
						savepoint v_savepoint;
						DBMS_OUTPUT.PUT_LINE('Pan code ' || K.cap_pan_code);
						
						v_errmsg := 'OK';
						prm_errmsg := 'OK';
												
						--Sn generate a renewcaf file name
						
						IF v_renew_reccnt = 0 THEN
						 
					   	   
	 				   	   			Sp_Create_Rencaffname(prm_inst_code,prm_lupd_user,v_rencaf_fname,v_errmsg);
	
									IF v_errmsg != 'OK' THEN
									prm_errmsg := 'Error while creating filename -- '||v_errmsg;
									RETURN;
									END IF;
	
						END IF;
						--En generate a renewcaf file name
						--Sn check card status
						IF K.cap_card_stat <> '1' THEN
						v_errmsg := 'Card is in not active ';
						RAISE exp_reject_record;
						END IF;
						--En check card status
						
						
						--Sn check failed records for duplicate processing
						BEGIN
							 SELECT COUNT(*)
							 INTO	v_check_failed_rec
							 FROM	CMS_CARDRENEWAL_ERRLOG 
							 WHERE	cce_pan_code  = k.cap_pan_code
							 AND	cce_inst_code = prm_inst_code;
							 
							IF v_check_failed_rec > 0 THEN
							v_errmsg := 'Record alredy failed in renew process ';
							RAISE exp_reject_record;
							END IF;
						EXCEPTION
						WHEN exp_reject_record THEN
						RAISE;
						WHEN OTHERS THEN
						v_errmsg := 'Error while checking record in history table' || substr(sqlerrm,1,150);
						RAISE exp_reject_record;
						END;						
						--En check failed record for duplicate processing
						
						--Sn check account information
						BEGIN
							 SELECT DISTINCT 
							 		CPA_PAN_CODE
							 INTO	v_pan_code
							 FROM	CMS_PAN_ACCT
							 WHERE  cpa_inst_code = prm_inst_code
							 AND	cpa_pan_code  = k.cap_pan_code;
						
						
						EXCEPTION
							WHEN NO_DATA_FOUND THEN
							v_errmsg := 'Account not found in master ';
							RAISE exp_reject_record;
							WHEN OTHERS THEN
							v_errmsg := 'Error while selecting acct details '|| substr(sqlerrm,1,200);
							RAISE exp_reject_record;
						END;
					  --En check account information
					  
					  --Sn update expry date
					   IF (v_hsm_mode = 'N') THEN
						  	 		  		UPDATE 	 CMS_APPL_PAN
											SET	     cap_expry_date			= v_expry_date, 
											 	     cap_next_bill_date 	= v_to_date,
												     cap_lupd_date 			= SYSDATE
											WHERE  	 cap_inst_code 	    	= prm_inst_code
											AND		 cap_pan_code 	    	= k.cap_pan_code
											AND  	 cap_mbr_numb 	    	= k.cap_mbr_numb ;
						 ELSE
									  		UPDATE    CMS_APPL_PAN
											SET		  cap_expry_date		= v_expry_date, 
											 		  cap_next_bill_date 	= v_to_date,
													  cap_lupd_date 		= SYSDATE,
													  cap_embos_flag		= 'Y'  
											WHERE  	  cap_inst_code 	    = prm_inst_code
											AND		  cap_pan_code 	        = k.cap_pan_code
											AND  	  cap_mbr_numb 	        = k.cap_mbr_numb ;
						END IF;

					  --En update expry date
					  IF SQL%rowcount = 0 THEN
					  	 			  
					  		v_errmsg := 'Error while updating expry date ';
							RAISE exp_reject_record;
					  END IF;
					  --Sn create a record in CAF
					  DELETE 	FROM CMS_CAF_INFO
					  WHERE		 cci_pan_code 	 	= 	DECODE(LENGTH(k.cap_pan_code),
					  			 											    16,k.cap_pan_code || '   ',
                                      											19,k.cap_pan_code) 
					  AND	     cci_mbr_numb	    =	k.cap_mbr_numb;

								 					Sp_Caf_Rfrsh(prm_inst_code,k.cap_pan_code,NULL,SYSDATE,'C',NULL,'RENEW',prm_lupd_user,v_errmsg);

													IF v_errmsg !='OK' THEN
															  v_errmsg:='Error while creating CAF record -- '||v_errmsg;
															  RAISE exp_reject_record;
															  
													ELSE
														v_renew_reccnt := v_renew_reccnt+1;
															  		  IF v_renew_reccnt = v_renew_param THEN
																	     v_renew_reccnt := 0;
																	  END IF;

														UPDATE	CMS_CAF_INFO
														SET		cci_file_name = v_rencaf_fname
  																				 
														WHERE		cci_pan_code  = DECODE(LENGTH(k.cap_pan_code),
					  			 											      				 16,k.cap_pan_code || '   ',
                                      															 19,k.cap_pan_code) 
  		  												AND		    cci_mbr_numb  = k.cap_mbr_numb
														AND         cci_inst_code = prm_inst_code;
														
														IF SQL%ROWCOUNT = 0 THEN
														v_errmsg := 'Error while updating renewcaf file name' ;
														RAISE exp_reject_record;
														END IF;
																									
													 END IF;
					 --En create a record in CAF
					 
					 --Sn create a record for successful record
					 	  --Sn insert  record in ren tmp
						  BEGIN
						  
						  	   INSERT INTO 
							   		  CMS_REN_TEMP
							   VALUES(k.cap_pan_code,
							   		  k.cap_appl_bran,
									  k.cap_card_stat,
									  SUBSTR(k.cap_pan_code,1,6),
									  'Y',
									  TO_CHAR(v_from_date,'MON-YYYY'),
									  SYSDATE,
									  prm_inst_code,
									  prm_lupd_user,
									  SYSDATE,
									  prm_lupd_user,
									  v_remark
									  );
						  
						  
						  EXCEPTION
						  	WHEN OTHERS THEN
							v_errmsg := 'Error while inserting record in renewal temp'|| substr(sqlerrm,1,200) ;
							RAISE exp_reject_record;
							
						  END;
					   --En insert a record in ren tmp
					   
					   --Sn create a record in pan support
					   
					   
					   
					   
					   --En create a record in pan support
					   BEGIN
					   		INSERT INTO CMS_PAN_SPPRT
								   		(	CPS_INST_CODE,
											CPS_PAN_CODE		,
											CPS_MBR_NUMB		,
											CPS_PROD_CATG		,
											CPS_SPPRT_KEY		,
											CPS_SPPRT_RSNCODE	,
											CPS_FUNC_REMARK		,
											CPS_INS_USER		,
											CPS_LUPD_USER		
										)
							VALUES		(	prm_inst_code,
											k.cap_pan_code		,
											k.cap_mbr_numb		,
											k.cap_prod_catg		,
											'RENEW'			,
											1			,
											v_remark			,
											prm_lupd_user		,
											prm_lupd_user		
										);
					   
					   EXCEPTION
					      WHEN OTHERS THEN
							v_errmsg := 'Error while inserting record in pan support'|| substr(sqlerrm,1,200) ;
							RAISE exp_reject_record;
					   END;
					 --En create a record for successful record
					 
					 --Sn create a record in renew detail
					 BEGIN
				   INSERT INTO CMS_RENEW_DETAIL
			                        (crd_inst_code, crd_card_no, crd_file_name,
			                         crd_remarks, crd_msg24_flag, crd_process_flag,
			                         crd_process_msg, crd_process_mode, crd_ins_user,
			                         crd_ins_date, crd_lupd_user, crd_lupd_date
			                        )
			                 VALUES (prm_inst_code, 
							 		 k.cap_pan_code, NULL,
			                         v_remark, 'N', 'S',
			                         'Success', 'G', prm_lupd_user,
			                         SYSDATE, prm_lupd_user, SYSDATE
			                        );
					  EXCEPTION
					      WHEN OTHERS THEN
							v_errmsg := 'Error while inserting record in renew detail'|| substr(sqlerrm,1,200) ;
							RAISE exp_reject_record;
					   END;
					 
					 
					 --En create a record in renew detail
					 
					 --Sn create a record in audit log
					 BEGIN														 --8.
		         	 	INSERT INTO PROCESS_AUDIT_LOG
		                     (pal_card_no, 
							  pal_activity_type, 
							  pal_transaction_code,
		                      pal_delv_chnl,
							  pal_tran_amt, pal_source,
							  pal_process_msg,
		                      pal_success_flag,pal_inst_code, pal_ins_user, pal_ins_date
		                     )
		              VALUES (k.cap_pan_code,
					  		  'Renew', 
							  NULL,
		                      NULL, 
							  0, 
							  'HOST',
							  'Success',
		                      'S', 
							  prm_inst_code,
							  prm_lupd_user,
							   SYSDATE
		                     );
		      	    EXCEPTION
		         			 WHEN OTHERS
		         			 	  THEN
		            			  v_errmsg := 'Error while inserting record in audit detail'|| substr(sqlerrm,1,200) ;
							RAISE exp_reject_record;
		      		END;	
					 --En create a record in audit log
					  
				
				EXCEPTION	   		--<<CARD WISE LOOP EXCEPTION>>
				WHEN exp_reject_record THEN
				rollback to v_savepoint;
				 Sp_Cardrenewal_Errlog (	
				        prm_inst_code,
				        k.cap_pan_code ,
						k.cap_disp_name ,
						k.cap_acct_no ,
						k.cap_card_stat ,
						k.cap_expry_date ,
						k.cap_appl_bran,
						'X',
						v_errmsg ,
						prm_lupd_user );
				WHEN OTHERS THEN
					  Sp_Cardrenewal_Errlog (	
					    prm_inst_code,
					    k.cap_pan_code ,
						k.cap_disp_name ,
						k.cap_acct_no ,
						k.cap_card_stat ,
						k.cap_expry_date ,
						k.cap_appl_bran,
						'X',
						v_errmsg ,
						prm_lupd_user );
				
				END;				--<<CARD WISE LOOP END>>
				--En generate a renewcaf file name
				END LOOP;
				
				--En loop for no of cards
				
			END LOOP;
		--En loop for BIN
		
		END LOOP;
		prm_errmsg := 'OK';
	--En loop for branch
	
EXCEPTION			--<< MAIN EXCEPTION >>
WHEN OTHERS THEN
prm_errmsg := 'Error from main ' || substr(sqlerrm,1,200);
END;				--<< MAIN END>>
/


