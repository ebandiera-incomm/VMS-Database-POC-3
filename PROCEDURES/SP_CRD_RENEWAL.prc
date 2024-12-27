CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Crd_Renewal (	instcode IN NUMBER ,
				remark	IN VARCHAR2,
				indate	IN DATE,
				binlist IN VARCHAR2,
				frombran IN VARCHAR2,
				tobran	 IN VARCHAR2,
        		lupduser IN NUMBER,
        		errmsg OUT VARCHAR2)
AS
  --change history
  --1CH070303 Anup add an update stmt for renewal of expired cards
	v_expiryparam NUMBER;
	v_renew_param NUMBER;
	renew_cnt	  NUMBER := 0;
	v_rencaf_fname CMS_RENCAF_HEADER.crh_rencaf_fname%TYPE;
	v_pan CMS_APPL_PAN.cap_pan_code%TYPE;
	v_errmsg VARCHAR2(500) ;
	v_date1 DATE; --Added by Abhijit on 05-May-2005
	v_date2 DATE; --Added by Abhijit on 05-May-2005
	v_date3 DATE; --Added by Shyam on 05-May-2005

	v_binlist VARCHAR2(500);
	v_from_bran VARCHAR2(50);
	v_to_bran VARCHAR2(50);
	v_binflag VARCHAR2(1);
	v_branflag VARCHAR2(1);
	v_number_of_bins NUMBER;
	v_prod_code CMS_APPL_PAN.cap_prod_code%TYPE;

	start_point NUMBER;
	acctcnt NUMBER;
	dum NUMBER;
	v_filter	VARCHAR2(1);
	v_filter_count NUMBER; -- jimmy for duplicate check...

	v_hsm_mode		VARCHAR2(1);--Rahul 28 Sep 05
	v_emboss_flag		VARCHAR2(1);--Rahul 28 Sep 05

	NoAccountsException EXCEPTION;
	RenCafException EXCEPTION;
	filterpan	EXCEPTION;
	InactiveCards EXCEPTION;
--gets the cards that are expiring in the month on which this procedure is executed.
	CURSOR C1 (	p_date1 DATE,p_date2 DATE) IS
	SELECT	/*+INDEX(CMS_APPL_PAN INDX_EXPRYDATE)*/cap_pan_code,
		cap_mbr_numb,
		cap_prod_catg,
		cap_acct_no,
		cap_disp_name,
		cap_expry_date,
		cap_card_stat,
		cap_prod_code,
		cap_appl_bran
	FROM 	CMS_APPL_PAN
	WHERE 	cap_expry_date  >= p_date1    ----to_date('01-'||to_char(sysdate,'MON-YYYY')) AND last_day(sysdate) ;
	AND	cap_expry_date <= p_date2
	AND	cap_prod_catg = 'D';


BEGIN --1.1 --Main
	errmsg:='OK';
		-- Gets the Validity period from the Parameter table.

	-- Rahul 28 Sep 05
	BEGIN
		SELECT CIP_PARAM_VALUE
		INTO v_hsm_mode
		FROM CMS_INST_PARAM
		WHERE cip_param_key='HSM_MODE';

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

	SELECT	cip_param_value
	INTO		 v_expiryparam
	FROM	  CMS_INST_PARAM
	WHERE	cip_param_key = 'CARD EXPRY';

	SELECT	TO_NUMBER(cip_param_value)
	INTO	v_renew_param
	FROM	CMS_INST_PARAM
	WHERE	cip_param_key = 'RENEWCAF';

	--v_date1	:=TO_DATE('01-'||TO_CHAR(SYSDATE,'MON-YYYY'));	--Added by Abhijit on 05-May-2005
	v_date1 := indate; -- first day of selected month is passed by JSP
	v_date2	:= LAST_DAY(indate);--Added by Abhijit on 05-May-2005
	v_date3	:= LAST_DAY(ADD_MONTHS(indate, v_expiryparam));
	v_from_bran:=frombran;
	v_to_bran := tobran;
	v_binlist:= binlist;
	v_binflag:= 'N';



	IF(v_binlist != 'ALL') THEN
	v_number_of_bins:=LENGTH(v_binlist)/6;
	END IF;



	FOR x IN C1 (v_date1, v_date2)
		LOOP
					BEGIN --1.2

						  v_binflag:='N';
						  v_branflag:='N';
						  dum:=0;
--cr 146 start
	 	 	  			  				IF(v_binlist='ALL') THEN
									  					  v_binflag:='Y';
  										ELSE

										BEGIN
										start_point:=1;
										FOR i IN 1..v_number_of_bins
										LOOP

/*										SELECT cpb_prod_code
										INTO v_prod_code
										FROM CMS_PROD_BIN
										WHERE cpb_inst_bin = TO_NUMBER(SUBSTR(v_binlist,start_point,6));*/

										IF((TO_NUMBER(SUBSTR(v_binlist,start_point,6)))=(TO_NUMBER(SUBSTR(x.cap_pan_code,1,6)))) THEN
											v_binflag := 'Y';
																		EXIT;
										END IF;

										start_point:=start_point+6;

										END LOOP;
										END;
										END IF;


									  IF (NVL(LENGTH(trim(v_from_bran)),0)=0 AND NVL(LENGTH(trim(v_to_bran)),0)=0) THEN
									  		v_branflag := 'Y';
									 END IF;

									 IF(NVL(LENGTH(trim(v_from_bran)),0)!=0 AND NVL(LENGTH(trim(v_to_bran)),0)=0) THEN
											BEGIN
											SELECT COUNT(1) INTO dum
											FROM CMS_BRANCH_REGION
											WHERE cbr_inst_code = instcode
											AND cbr_region_id = v_from_bran
											AND cbr_bran_code = x.cap_appl_bran;

											IF (dum=0) THEN
											   v_branflag := 'N';
											ELSE
											   v_branflag := 'Y';
										   END IF;
											END;
									 END IF;


									 IF((TO_NUMBER(x.cap_appl_bran) >= TO_NUMBER(v_from_bran)) AND (TO_NUMBER(x.cap_appl_bran) <= TO_NUMBER(v_to_bran))) THEN
									 		v_branflag := 'Y';
									END IF;

									IF(v_branflag = 'Y' AND v_binflag = 'Y') THEN
											IF(x.cap_card_stat!='1') THEN
														RAISE Inactivecards;
											END IF;

											IF renew_cnt = 0 THEN
		--generate new file here and store it in a variable and use the filename below
				   	   			 				dbms_output.put_line('SP_CREATE_RENEWCAFFNAME');
 				   	   			 	 			Sp_Create_Rencaffname(instcode,lupduser,v_rencaf_fname,errmsg);

															IF errmsg != 'OK' THEN
															    errmsg := 'Error while creating filename -- '||errmsg;
																			  RAISE RenCafException;
															END IF;

											END IF;

											BEGIN
--														SELECT	'X' INTO	v_filter
--														FROM	CMS_REN_PAN_TEMP
--														WHERE	crp_pan_code = x.cap_pan_code;
--														RAISE filterpan;

														-- jimmy --> for duplicate check...
														-- This is for cases where one or more files have the same pan
														-- The count will indicate that this is the case....
														SELECT	COUNT(1) INTO	v_filter_count
														FROM	CMS_REN_PAN_TEMP
														WHERE	crp_pan_code = x.cap_pan_code;
														IF v_filter_count > 0 THEN
														RAISE filterpan;
														END IF;
														EXCEPTION
														WHEN NO_DATA_FOUND THEN
														 NULL;
											END;

											BEGIN
														SELECT	DISTINCT cpa_pan_code
														INTO	v_pan
														FROM	CMS_PAN_ACCT
														WHERE	cpa_inst_code = instcode
														AND	cpa_pan_code = x.cap_pan_code;
											EXCEPTION
														WHEN NO_DATA_FOUND THEN
														            	  RAISE NoAccountsException;
											END;
		--Renews the card by updating its Expiry date.

				 	 	  IF (v_hsm_mode = 'N') THEN
						  	 		  		UPDATE CMS_APPL_PAN
													  -- SET	cap_expry_date 		= last_day(add_months(sysdate , v_expiryparam)), --commented by shyam
											SET		  cap_expry_date		= v_date3,--- shyam
											 		  cap_next_bill_date 	= v_date2,
													  cap_lupd_date 		= SYSDATE
											WHERE  	cap_inst_code 	= instcode
											AND		cap_pan_code 	= x.cap_pan_code
											AND  	cap_mbr_numb 	= x.cap_mbr_numb ;
						 ELSE
									  		UPDATE CMS_APPL_PAN
													  -- SET	cap_expry_date 		= last_day(add_months(sysdate , v_expiryparam)), --commented by shyam
											SET		  cap_expry_date		= v_date3,--- shyam
											 		  cap_next_bill_date 	= v_date2,
													  cap_lupd_date 		= SYSDATE,
													  cap_embos_flag		= 'Y' -- shyam 03 oct 05 ...new emboss file for renewal
											WHERE  	cap_inst_code 	= instcode
											AND		cap_pan_code 	= x.cap_pan_code
											AND  	cap_mbr_numb 	= x.cap_mbr_numb ;
						END IF;

											INSERT INTO CMS_REN_TEMP
											VALUES(x.cap_pan_code,x.cap_appl_bran,x.cap_card_stat,SUBSTR(x.cap_pan_code,1,6),'Y',TO_CHAR(v_date1,'MON-YYYY'),
													SYSDATE,instcode,lupduser,SYSDATE,lupduser);
		--now log the support function into cms_pan_spprt

			  	  	  		  		   		INSERT INTO CMS_PAN_SPPRT(	CPS_INST_CODE,
												   									  			  					CPS_PAN_CODE		,
																													CPS_MBR_NUMB		,
																													CPS_PROD_CATG		,
																													CPS_SPPRT_KEY		,
																													CPS_SPPRT_RSNCODE	,
																													CPS_FUNC_REMARK		,
																													CPS_INS_USER		,
																													CPS_LUPD_USER		)
																							VALUES	(	instcode		,
																													x.cap_pan_code		,
																													x.cap_mbr_numb		,
																													x.cap_prod_catg		,
																													'RENEW'			,
																													1			,
																													remark			,
																													lupduser		,
																													lupduser		);
		--Before insert into into cms_caf_info, delete the row from cms_caf_info
				 			 		DELETE 	FROM CMS_CAF_INFO
									WHERE		 cci_pan_code 	= 	RPAD(x.cap_pan_code,19) --Rpad added by abhijit on 5-May-2005
									AND	cci_mbr_numb	=	x.cap_mbr_numb;

									Sp_Caf_Rfrsh(instcode,x.cap_pan_code,NULL,SYSDATE,'C',NULL,'RENEW',lupduser,errmsg);

													IF errmsg !='OK' THEN
															  errmsg:='From Caf Refresh -- '||errmsg;
													ELSE
															  renew_cnt := renew_cnt+1;
															  		  IF renew_cnt = v_renew_param THEN
																	  		    renew_cnt := 0;
																	  END IF;

																	   UPDATE	CMS_CAF_INFO
																	   SET		cci_file_name = v_rencaf_fname
  																				 --cci_file_gen  = 'R'--renewed pans filegen
																	   WHERE		cci_pan_code  = RPAD(x.cap_pan_code,19) --Rpad added by abhijit on 5-May-2005
  		  															   AND		cci_mbr_numb  = x.cap_mbr_numb;
													 END IF;
	END IF; -- cr 146 end
	EXCEPTION
		 WHEN InactiveCards THEN
	  	  v_errmsg:='The PAN is not in active state ...';
		  Sp_Cardrenewal_Errlog (	x.cap_pan_code ,
						x.cap_disp_name ,
						x.cap_acct_no ,
						x.cap_card_stat ,
						x.cap_expry_date ,
						x.cap_appl_bran,
						'E',
						v_errmsg ,
						lupduser );
		WHEN filterpan THEN
	  	  v_errmsg:='The PAN is filtered for the process ...';
		  Sp_Cardrenewal_Errlog (	x.cap_pan_code ,
						x.cap_disp_name ,
						x.cap_acct_no ,
						x.cap_card_stat ,
						x.cap_expry_date ,
						x.cap_appl_bran,
						'F',
						v_errmsg ,
						lupduser );
		WHEN NoAccountsException THEN
	  	  v_errmsg:='Account not Present in Masters';
		  Sp_Cardrenewal_Errlog (	x.cap_pan_code ,
						x.cap_disp_name ,
						x.cap_acct_no ,
						x.cap_card_stat ,
						x.cap_expry_date ,
						x.cap_appl_bran,
						'X',
						v_errmsg ,
						lupduser );
		WHEN RenCafException THEN
		  v_errmsg:='Problem in creating rencaf filename';
		  RAISE ;
		WHEN OTHERS THEN
		  v_errmsg := 'EXCP 1.2 '||SQLERRM ;
		  Sp_Cardrenewal_Errlog (	x.cap_pan_code ,
						x.cap_disp_name ,
						x.cap_acct_no ,
						x.cap_card_stat ,
						x.cap_expry_date ,
						x.cap_appl_bran,
						'X',
						v_errmsg  ,
						lupduser );
	END ; --1.2
	END LOOP;
	COMMIT;
EXCEPTION
      WHEN OTHERS THEN
        errmsg:= 'Main Excp -- '|| v_errmsg || SQLERRM;
	ROLLBACK;
END;
/


