CREATE OR REPLACE PROCEDURE VMSCMS.sp_login_track
AS

   v_inst_code          NUMBER;
   v_flag               CHAR (1);
   v_errmsg             VARCHAR2 (300);
   v_param_value        VARCHAR2 (50);
   v_param_value_days   VARCHAR2 (50);
   exp_reject_record    EXCEPTION;
   CURSOR cur_inst_mast IS SELECT CIM_INST_CODE FROM CMS_INST_MAST;
   
BEGIN
   
   FOR i IN cur_inst_mast
   LOOP
   	   v_errmsg := 'OK';
   
			   BEGIN
			   		BEGIN
						SELECT CIP_PARAM_VALUE
						INTO v_param_value
						FROM CMS_INST_PARAM
						WHERE CIP_PARAM_KEY = 'NINTEYDAYDISABLE'
						AND CIP_INST_CODE = i.CIM_INST_CODE;
						EXCEPTION
						WHEN exp_reject_record
						THEN
							 v_errmsg := 'No Reecord Found for NINTEY DAY DISABLE flag in param table';
							RAISE;
						WHEN NO_DATA_FOUND 
						THEN
						 	 v_errmsg := 'No Reecord Found for NINTEY DAY DISABLE flag in param table';
							RAISE exp_reject_record;
						WHEN OTHERS THEN
						 	 v_errmsg := 'No Reecord Found for NINTEY DAY DISABLE flag in param table';
							RAISE exp_reject_record;
					END;
										  IF v_param_value = 'Y'
									      THEN
										  
												         BEGIN		   	 --Sn Begin 1 
														 		
																SELECT CIP_PARAM_VALUE
																INTO v_param_value_days
																FROM CMS_INST_PARAM
																WHERE CIP_PARAM_KEY = 'INACTIVEACCOUNT'
																AND CIP_INST_CODE = i.CIM_INST_CODE;
												
														            IF v_param_value_days IS NOT NULL
														            THEN
																		BEGIN
																		UPDATE CMS_USER_MAST
																		SET CUM_USER_SUSP = 'S',
																		CUM_LUPD_USER = 1
																		WHERE CUM_INST_CODE = i.CIM_INST_CODE  AND CUM_USER_PIN IN (
																		SELECT CTL_USER_PIN
																		FROM CMS_TRACK_LOGIN
																		WHERE (SYSDATE - CTL_LOGIN_DATE) > v_param_value_days)
																		AND CUM_USER_SUSP <> 'S';
																		EXCEPTION
																		WHEN exp_reject_record
																					THEN 
																						 v_errmsg :=
																		                          'Error While Update cms_user_mast'||SUBSTR (SQLERRM, 1, 100);
																						 RAISE;
																		WHEN OTHERS 													 
																		THEN
																		    v_errmsg := 'Error While Update cms_user_mast'||SUBSTR (SQLERRM, 1, 100);
																			RAISE exp_reject_record;
																		END;
																               IF SQL%ROWCOUNT > 0
																               THEN
																			   	    BEGIN
																					INSERT INTO cms_loginjob_track
																					(clt_user_pin, clt_flag, clt_schedule_date,
																					clt_message)
																					SELECT cum_user_pin, 'S', TO_CHAR (SYSDATE,'YY/MM/DD HH24:MI:SS PM'), v_errmsg
																					FROM cms_user_mast
																					WHERE cum_user_pin IN (
																					SELECT ctl_user_pin
																					FROM cms_track_login
																					WHERE (SYSDATE - ctl_login_date) >
																					v_param_value_days) AND cum_user_susp <> 'S';
																					EXCEPTION
																					WHEN exp_reject_record
																					THEN 
																						 v_errmsg :=
																		                          'Error While Insert in mps_loginjob_track'||SUBSTR (SQLERRM, 1, 100);
																						 RAISE;
																					WHEN OTHERS THEN
																						 v_errmsg := 'Error While Insert in mps_loginjob_track'||SUBSTR (SQLERRM, 1, 100); 
																						 RAISE exp_reject_record;
																					END; 
																               ELSE
																			   
																                  v_errmsg := 'No record for updations';
																				  
																               END IF;
																	   
														            END IF;
												         EXCEPTION
														    WHEN exp_reject_record
															THEN 
																 v_errmsg :=
												                          'Inactive Account date is not found in Param Table';
																 RAISE;
												            WHEN NO_DATA_FOUND
												            THEN
												               v_errmsg :=
												                          'Inactive Account date is not found in Param Table';
												               RAISE exp_reject_record;
												            WHEN OTHERS
												            THEN
												               v_errmsg := v_errmsg||'Error While fatching record from Param table'
												                  || SUBSTR (SQLERRM, 1, 100);
												               RAISE exp_reject_record;
												         END;
											 
									      ELSE
								  
												         v_errmsg :=
												                'NINTEY DAY DISABLE flag in param table is ' || v_param_value;
												         RAISE exp_reject_record;
									      END IF;
				  
			   EXCEPTION
			   	  WHEN exp_reject_record
  			      THEN
				  	  v_errmsg := v_errmsg;
			               -- 'No Reecord Found for NINTEY DAY DISABLE flag in param table';
			   	   	  RAISE;
			      WHEN NO_DATA_FOUND
			      THEN
			         v_errmsg :=
			                'No Reecord Found for NINTEY DAY DISABLE flag in param table';
			         RAISE exp_reject_record;
			      WHEN OTHERS
			      THEN
			         v_errmsg :=  v_errmsg||'Error While '|| SQLERRM|| SQLCODE;
			         RAISE exp_reject_record;
			   END; --En Begin 2 
END LOOP;
EXCEPTION
   WHEN exp_reject_record
   THEN
      INSERT INTO cms_loginjob_track
                  (clt_flag, clt_schedule_date, clt_message
                  )
           VALUES ('E', TO_CHAR (SYSDATE,'YY/MM/DD HH24:MI:SS PM'), v_errmsg
                  );
   WHEN OTHERS
   THEN
      v_errmsg := 'Main_exception' || SUBSTR (SQLERRM, 1, 100);

      INSERT INTO cms_loginjob_track
                  (clt_flag, clt_schedule_date, clt_message
                  )
           VALUES ('E', TO_CHAR (SYSDATE,'YY/MM/DD HH24:MI:SS PM'), v_errmsg
                  );
END;
/
SHOW ERRORS

