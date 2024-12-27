CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Entry_Newcaf_Pcms_old(	instcode	IN		NUMBER		,
				lupduser	IN		NUMBER		,
				errmsg		OUT		VARCHAR2	)
AS

  	dup_check VARCHAR(1); -- jimmy CR 133 - to check applications entered on the same day

	--cursor c2 picks up the actual data from cms_caf_info_entry for filenames which are picked up from cursor c1
	CURSOR	c2
	IS
	SELECT		cci_row_id,cci_seg12_cardholder_title,cci_seg12_name_line1,	--custmast part
			cci_seg12_addr_line1,cci_seg12_addr_line2,cci_seg12_name_line2,cci_seg12_city
,cci_seg12_state,cci_seg12_postal_code,cci_seg12_country_code,cci_seg12_open_text1,	--address part
			cci_fiid,cci_crd_typ,cci_pan_code,cci_exp_dat, cci_approved , cci_ins_date ,
			cci_seg12_branch_num,	 --customer category comes in this field
			cci_card_type ,
			cci_seg31_num1,cci_seg31_typ1,cci_seg31_stat1,
			cci_seg31_num2,cci_seg31_typ2,cci_seg31_stat2,
			cci_seg31_num3,cci_seg31_typ3,cci_seg31_stat3,
			cci_seg31_num4,cci_seg31_typ4,cci_seg31_stat4,
			cci_remail, cci_rmobile, CCI_OADDR_LINE1,   CCI_OADDR_LINE2 ,CCI_OCITY , CCI_OSTATE ,CCI_OPOSTAL_CODE ,
			CCI_OCOUNTRY_CODE ,  CCI_OPHONE , CCI_OMOBILE , CCI_OEMAIL ,
			CCI_PROD_AMT ,  CCI_FEE_AMT , CCI_TOT_AMT  ,CCI_PAYMENT_MODE,   CCI_INSTRUMENT_NO  ,    CCI_INSTRUMENT_AMT,
			CCI_COMM_ADDR,cci_prefix,cci_iname, cci_appl_no,cci_payref_no
			,CCI_SSN ssn,CCI_MOTHER_NAME maidname,CCI_HOBBIES hobby  -- Added By Nachiketa , 24-02-08
	FROM		PCMS_CAF_INFO_ENTRY
	WHERE		cci_approved		= 'A'
	AND		cci_inst_code		=	instcode
	AND		cci_upld_stat		=	'P' ;--pending for processing
	--for update;
	y c2%ROWTYPE;
--variable declaration
cust				CMS_CUST_MAST.ccm_cust_code%TYPE	;
salutcode			CMS_CUST_MAST.ccm_salut_code%TYPE	;
v_gcm_cntry_code		GEN_CNTRY_MAST.gcm_cntry_code%TYPE	;
addrcode			CMS_ADDR_MAST.cam_addr_code%TYPE	;
acctid				CMS_ACCT_MAST.cam_acct_id%TYPE		;
holdposn			CMS_CUST_ACCT.cca_hold_posn%TYPE	;
v_cpb_prod_code			CMS_PROD_BIN.cpb_prod_code%TYPE		;
applcode			CMS_APPL_MAST.cam_appl_code%TYPE	;
dupflag				CHAR(1);
v_cpm_interchange_code		CMS_PRODTYPE_MAP.cpm_interchange_code%TYPE;
v_ccc_catg_code			CMS_CUST_CATG.ccc_catg_code%TYPE := 1	;
v_cat_type_code			CMS_ACCT_TYPE.cat_type_code%TYPE	;
v_cas_stat_code			CMS_ACCT_STAT.cas_stat_code%TYPE	;
v_cci_seg31_acct_cnt		CMS_CAF_INFO_ENTRY.cci_seg31_acct_cnt%TYPE	;
v_cci_seg31_typ			CMS_CAF_INFO_ENTRY.cci_seg31_typ%TYPE		;
v_cci_seg31_num			CMS_CAF_INFO_ENTRY.cci_seg31_num%TYPE	;
v_cci_seg31_stat		CMS_CAF_INFO_ENTRY.cci_seg31_stat%TYPE	;
v_cci_seg31_typ1		CMS_CAF_INFO_ENTRY.cci_seg31_typ1%TYPE		;
v_cci_seg31_num1		CMS_CAF_INFO_ENTRY.cci_seg31_num1%TYPE	;
v_cci_seg31_stat1		CMS_CAF_INFO_ENTRY.cci_seg31_stat1%TYPE	;
v_cci_seg31_typ2		CMS_CAF_INFO_ENTRY.cci_seg31_typ2%TYPE		;
v_cci_seg31_num2		CMS_CAF_INFO_ENTRY.cci_seg31_num2%TYPE	;
v_cci_seg31_stat2		CMS_CAF_INFO_ENTRY.cci_seg31_stat2%TYPE	;
v_cci_seg31_typ3		CMS_CAF_INFO_ENTRY.cci_seg31_typ3%TYPE		;
v_cci_seg31_num3		CMS_CAF_INFO_ENTRY.cci_seg31_num3%TYPE	;
v_cci_seg31_stat3		CMS_CAF_INFO_ENTRY.cci_seg31_stat3%TYPE	;
v_cci_seg31_typ4		CMS_CAF_INFO_ENTRY.cci_seg31_typ4%TYPE		;
v_cci_seg31_num4		CMS_CAF_INFO_ENTRY.cci_seg31_num4%TYPE	;
v_cci_seg31_stat4		CMS_CAF_INFO_ENTRY.cci_seg31_stat4%TYPE	;
v_cci_seg31_typ5		CMS_CAF_INFO_ENTRY.cci_seg31_typ5%TYPE		;
v_cci_seg31_num5		CMS_CAF_INFO_ENTRY.cci_seg31_num5%TYPE	;
v_cci_seg31_stat5		CMS_CAF_INFO_ENTRY.cci_seg31_stat5%TYPE	;
v_cci_seg31_typ6		CMS_CAF_INFO_ENTRY.cci_seg31_typ6%TYPE		;
v_cci_seg31_num6		CMS_CAF_INFO_ENTRY.cci_seg31_num6%TYPE	;
v_cci_seg31_stat6		CMS_CAF_INFO_ENTRY.cci_seg31_stat6%TYPE	;
v_cci_seg31_typ7		CMS_CAF_INFO_ENTRY.cci_seg31_typ7%TYPE		;
v_cci_seg31_num7		CMS_CAF_INFO_ENTRY.cci_seg31_num7%TYPE	;
v_cci_seg31_stat7		CMS_CAF_INFO_ENTRY. cci_seg31_stat7%TYPE	;
v_cci_seg31_typ8		CMS_CAF_INFO_ENTRY.cci_seg31_typ8%TYPE		;
v_cci_seg31_num8		CMS_CAF_INFO_ENTRY.cci_seg31_num8%TYPE	;
v_cci_seg31_stat8		CMS_CAF_INFO_ENTRY. cci_seg31_stat8%TYPE	;
v_cci_seg31_typ9		CMS_CAF_INFO_ENTRY.cci_seg31_typ9%TYPE		;
v_cci_seg31_num9		CMS_CAF_INFO_ENTRY.cci_seg31_num9%TYPE		;
v_cci_seg31_stat9		CMS_CAF_INFO_ENTRY. cci_seg31_stat9%TYPE		;
addrcode1			CMS_ADDR_MAST.cam_addr_code%TYPE	;
expry_param			NUMBER(3);
dum NUMBER(1);
dum1 NUMBER(1);
prodcattype	NUMBER(2);

var_flag CHAR(1); --** Rama PrabhuR for cust catg for variable cards
--local procedure for handling the account part
PROCEDURE lp_acct_part(cust IN NUMBER, addr IN NUMBER,  frowid IN NUMBER,fcci_ins_date IN DATE, branch IN VARCHAR2, acctid OUT VARCHAR2, lperr OUT VARCHAR2)
IS
BEGIN		--main begin local proc
	dupflag	:=	'A';
	SELECT	cip_param_value	--added on 11/10/2002 ...gets the card validity period in months from parameter table
	INTO	expry_param
	FROM	CMS_INST_PARAM
	WHERE	cip_inst_code = instcode
	AND	cip_param_key = 'CARD EXPRY';
	BEGIN		--begin lp1
DBMS_OUTPUT.PUT_LINE('Selecting from account...');
DBMS_OUTPUT.PUT_LINE(frowid);
DBMS_OUTPUT.PUT_LINE(fcci_ins_date);

		SELECT		cci_seg31_acct_cnt,		cci_seg31_typ,			cci_seg31_num ,			cci_seg31_stat
 ,
				cci_seg31_typ1,			cci_seg31_num1 ,		cci_seg31_stat1 ,
				cci_seg31_typ2 ,		cci_seg31_num2 ,		cci_seg31_stat2 ,
				cci_seg31_typ3 ,		cci_seg31_num3 ,		cci_seg31_stat3 ,
				cci_seg31_typ4 ,		cci_seg31_num4,			cci_seg31_stat4 ,
				cci_seg31_typ5 ,		cci_seg31_num5 ,		cci_seg31_stat5 ,
				cci_seg31_typ6  ,		cci_seg31_num6  ,		cci_seg31_stat6 ,
				cci_seg31_typ7  ,		cci_seg31_num7  ,		cci_seg31_stat7 ,
				cci_seg31_typ8  ,		cci_seg31_num8  ,		cci_seg31_stat8 ,
				cci_seg31_typ9 ,		cci_seg31_num9 ,		cci_seg31_stat9
		INTO		v_cci_seg31_acct_cnt,		v_cci_seg31_typ,		v_cci_seg31_num ,			v_cci_seg31_stat ,
				v_cci_seg31_typ1,		v_cci_seg31_num1 ,		v_cci_seg31_stat1 ,
				v_cci_seg31_typ2 ,		v_cci_seg31_num2 ,		v_cci_seg31_stat2 ,
				v_cci_seg31_typ3 ,		v_cci_seg31_num3 ,		v_cci_seg31_stat3 ,
				v_cci_seg31_typ4 ,		v_cci_seg31_num4  ,		v_cci_seg31_stat4,
				v_cci_seg31_typ5 ,		v_cci_seg31_num5 ,		v_cci_seg31_stat5 ,
				v_cci_seg31_typ6  ,		v_cci_seg31_num6  ,		v_cci_seg31_stat6 ,
				v_cci_seg31_typ7  ,		v_cci_seg31_num7  ,		v_cci_seg31_stat7 ,
				v_cci_seg31_typ8  ,		v_cci_seg31_num8  ,		v_cci_seg31_stat8 ,
				v_cci_seg31_typ9 ,		v_cci_seg31_num9 ,		v_cci_seg31_stat9
		FROM	PCMS_CAF_INFO_ENTRY
		WHERE	cci_row_id	= frowid
		AND	TRUNC(cci_ins_date)	= TRUNC(fcci_ins_date);
		--for primary account
		/*SELECT cat_type_code
		INTO	v_cat_type_code
		FROM	CMS_ACCT_TYPE
		WHERE	cat_inst_code		=	instcode
		AND	cat_switch_type		=	v_cci_seg31_typ	;
		SELECT cas_stat_code
		INTO	v_cas_stat_code
		FROM	CMS_ACCT_STAT
		WHERE	cas_inst_code = instcode
		AND	cas_switch_statcode = v_cci_seg31_stat;*/
		--now call the procedure for creating account
DBMS_OUTPUT.PUT_LINE('Creating new account...');
SELECT seq_acct_id.NEXTVAL
 INTO v_cci_seg31_num
 FROM  dual;
		Sp_Create_Acct_Pcms(instcode, v_cci_seg31_num ,1, branch, addr, 1, 8, lupduser, acctid, lperr)	;
		IF	lperr !=  'OK' THEN
			IF lperr  = 'Account No already in Master.' THEN
				BEGIN
					SELECT	DISTINCT 1-- this query is used to identify the relation between pan and acct .distinct 1 is used because it is possible that earlier the relation between 2pans and one acct might exist
					INTO	dum1
					FROM	CMS_PAN_ACCT,CMS_APPL_PAN
					WHERE	cpa_inst_code	=	instcode
					AND	cpa_acct_id	=	acctid
					AND	cap_pan_code	=	cpa_pan_code
					AND	cap_mbr_numb	=	cpa_mbr_numb
					AND	cap_card_stat	= '1' ; --  !='Z'; -- changed for CR 133, condition to be added for only open cards
					lperr := 'OK';
					dupflag := 'D';
				EXCEPTION
				WHEN NO_DATA_FOUND THEN
				-- if card not already present, check if an application has come through appl upload for the same day-- jimmy CR 133
				BEGIN -- dup begin -- jimmy CR 133
			DBMS_OUTPUT.PUT_LINE('Calling dup_check function...'); --
			  --	dup_check := FN_DUP_APPL_CHECK( 'S', v_cci_seg31_num );
			  dup_check := Fn_Dup_Appl_Check( v_cci_seg31_num,instcode );
			DBMS_OUTPUT.PUT_LINE('dup_check function over.Result is...'|| dup_check);
				/*  IF dup_check = 'T' THEN dupflag := 'D';
			   	  ELSE dupflag := 'A';
			  	  END IF;*/
				END; -- end of dup begin
				lperr := 'OK';
				-- dupflag := 'A';
				END;
				/*lperr := 'OK';
				dupflag	:=	'D';*/--since the account creation has returned the account duplicate message
				--now update the holder count of the account (since the account is same)
				UPDATE	CMS_ACCT_MAST
				SET	cam_hold_count	=	cam_hold_count+1,
					cam_lupd_user	=	lupduser
				WHERE	cam_inst_code	=	instcode
				AND	cam_acct_no	=	v_cci_seg31_num	;
			ELSE
				lperr := 'From sp_create_acct '||lperr||' for file '|| fcci_ins_date||' and row id '|| frowid;
			END IF;
		END IF;
	--now attach the account to the customer(create holder)
		IF lperr = 'OK' THEN
			Sp_Create_Holder(instcode, cust, acctid, NULL, lupduser, holdposn, lperr)	;
			IF errmsg != 'OK' THEN
				errmsg := 'From sp_create_holder '||lperr ||' for file '|| fcci_ins_date||' and row id '|| frowid;
			END IF;
		END IF;
	EXCEPTION		--excp lp1
	WHEN OTHERS THEN
	lperr := 'Excp Lp1 -- '||SQLERRM;
	END;		--end lp1
EXCEPTION	--main excp of local proc
WHEN OTHERS THEN
lperr := 'Local Excp -- '||SQLERRM;
END;		--end main of local proc
PROCEDURE lp_secondary_accts(cust IN NUMBER, acctno IN VARCHAR2, addr IN NUMBER, branch IN VARCHAR2,acct_typ IN VARCHAR2,acct_stat IN VARCHAR2 , acctid OUT VARCHAR2, lperr OUT VARCHAR2 )
IS
   BEGIN
		 SELECT cat_type_code
		INTO	v_cat_type_code
		FROM	CMS_ACCT_TYPE
		WHERE	cat_inst_code		=	instcode
		AND	cat_switch_type		=	acct_typ	;
		SELECT cas_stat_code
		INTO	v_cas_stat_code
		FROM	CMS_ACCT_STAT
		WHERE	cas_inst_code = instcode
		AND	cas_switch_statcode = acct_stat;
		--now call the procedure for creating account
		Sp_Create_Acct(instcode, acctno ,1, branch, addr, v_cat_type_code, v_cas_stat_code, lupduser, acctid, lperr)	;
		IF	lperr !=  'OK' THEN
			IF lperr  = 'Account No already in Master.' THEN
				UPDATE	CMS_ACCT_MAST
				SET	cam_hold_count	=	cam_hold_count+1,
					cam_lupd_user	=	lupduser
				WHERE	cam_inst_code	=	instcode
				AND	cam_acct_no	=	acctno	;
			ELSE
				lperr := 'From sp_create_acct '||lperr||' for file '|| ' '||' and row id '|| ' ';
			END IF;
		END IF;
		IF lperr = 'OK' THEN
			Sp_Create_Holder(instcode, cust, acctid, NULL, lupduser, holdposn, lperr)	;
			IF errmsg != 'OK' THEN
				errmsg := 'From sp_create_holder '||lperr ||' for file '|| ' '||' and row id '|| ' ';
			END IF;
		END IF;
 EXCEPTION
 WHEN OTHERS THEN
lperr := 'Local Excp -- '||SQLERRM;
 END ; -- Main Excp of Local Proc Secondary Acct .
--end local procedure
BEGIN		--main begin
errmsg := 'OK';	--initial errmsg status
	BEGIN		--begin 1 encloses the loops 1 and 2
		--call the sp_upload_checklist procedure for the file x.cuc_file_name
		--dbms_output.put_line('Before calling the checklist');
		-- This Proc used To Ctreat the branch Master , Cust Cat Based on data of table cms_caf_info_entry
		Sp_Entry_Checklist(instcode,lupduser,errmsg);
		--dbms_output.put_line('After calling the checklist errmesg is :'||errmsg);
		IF errmsg = 'OK' THEN
			COMMIT;
			FOR y IN c2	--loop 2 for cursor 2
			LOOP
					DBMS_OUTPUT.PUT_LINE('After entering the second loop');
			COMMIT;	--commit at the first because if eror comes the the transaction is rolled back... but the error log table is filled so that has to be commited here
				--in other normal cases the record will get commited at the start of the next record
			--				dum := 0;
				BEGIN		--begin 1.1 --customer part
					IF	y.cci_seg12_cardholder_title = '0'	THEN
						salutcode	 := NULL;
					ELSIF y.cci_seg12_cardholder_title = '1'	THEN
						salutcode	 := 'Mr.'	;
					ELSIF y.cci_seg12_cardholder_title = '2'	THEN
						salutcode	 := 'Mrs.'	;
					ELSIF y.cci_seg12_cardholder_title = '3'	THEN
						salutcode	 := 'Miss'	;
					ELSIF y.cci_seg12_cardholder_title = '4'	THEN
						salutcode	 := 'Ms.'	;
					ELSIF y.cci_seg12_cardholder_title = '5'	THEN
						salutcode	 := 'Dr.'	;
					ELSE
						salutcode	 := NULL;
					END IF	;
					--dbms_output.put_line('ckpt 1');
					Sp_Create_Cust(instcode,1,0,'Y',salutcode,
								y.cci_iname, NULL,' ',
								TO_DATE('15-AUG-1947','DD-MON-YYYY'),'M','Y',NULL,NULL,NULL,NULL,NULL,lupduser,y.ssn,y.maidname,y.hobby,cust,errmsg);
					--dbms_output.put_line('ckpt 2' || errmsg);
					IF errmsg != 'OK' THEN
						errmsg := 'From sp_create_cust '||errmsg ||' for file '|| ' '||' and row id '|| y.cci_row_id;
						ROLLBACK;
						--dbms_output.put_line ('err' || instcode	|| ' '	||	substr(y.cci_row_id,1,5) || errmsg || lupduser  || sysdate || 'Contact Site Administrator'	);
						INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
										CEL_FILE_NAME  ,
										CEL_ROW_ID     ,
										CEL_ERROR_MESG ,
										CEL_LUPD_USER  ,
										CEL_LUPD_DATE  ,
										CEL_PROB_ACTION	)
								VALUES	(	instcode	,
										' '	,
										SUBSTR(y.cci_row_id,1,5)	,
										errmsg		,
										lupduser	,
										SYSDATE		,
										'Contact Site Administrator');
					UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
					END IF;
				EXCEPTION		--excp 1.1
					WHEN OTHERS THEN
					errmsg := 'Excp 1.1 -- '||SQLERRM;
					ROLLBACK;
					--dbms_output.put_line ('err' || instcode	|| ' '	||	substr(y.cci_row_id,1,5) || errmsg || lupduser  || sysdate || 'Contact Site Administrator'	);
					INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
									CEL_FILE_NAME  ,
									CEL_ROW_ID     ,
									CEL_ERROR_MESG ,
									CEL_LUPD_USER  ,
									CEL_LUPD_DATE  ,
									CEL_PROB_ACTION	)
							VALUES	(	instcode	,
									' '	,
									SUBSTR(y.cci_row_id,1,5)	,
									errmsg		,
									lupduser	,
									SYSDATE		,
									'Contact Site Administrator');
					UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
				END;		--end begin 1.1
				IF errmsg = 'OK' THEN	--address part
					BEGIN		--begin 1.2
					DBMS_OUTPUT.PUT_LINE('Before select =====>'||y.cci_seg12_country_code||'==='||y.cci_row_id);
					SELECT gcm_cntry_code
					INTO	v_gcm_cntry_code
					FROM	GEN_CNTRY_MAST
					WHERE	gcm_curr_code	=	y.cci_seg12_country_code	;
					DBMS_OUTPUT.PUT_LINE('after select =====>'||y.cci_seg12_country_code||'==='||y.cci_row_id);
					DBMS_OUTPUT.PUT_LINE('Before calling addr proc');

					IF y.cci_comm_addr = '0' THEN

					Sp_Create_Addr(	instcode, cust, y.cci_seg12_addr_line1,y.cci_seg12_addr_line2,y.cci_seg12_name_line2,y.cci_seg12_postal_code,
					y.cci_seg12_open_text1,y.cci_rmobile ,y.cci_remail,v_gcm_cntry_code,y.cci_seg12_city,y.cci_seg12_state,NULL,'P',lupduser,addrcode,errmsg);

					ELSE

					Sp_Create_Addr(	instcode, cust, 'test' ,'test' ,y.cci_seg12_name_line2,y.cci_opostal_code,
					y.cci_ophone,y.cci_omobile ,y.cci_oemail,v_gcm_cntry_code,'mumbai','mah',NULL,'P',lupduser,addrcode,errmsg);

					END IF;

					IF errmsg != 'OK' THEN
						errmsg := 'From sp_create_addr '||errmsg ||' for file '|| ' '||' and row id '|| y.cci_row_id;
						ROLLBACK;
						DBMS_OUTPUT.PUT_LINE ('err' || instcode	|| ' '	||	SUBSTR(y.cci_row_id,1,5) || errmsg || lupduser  || SYSDATE || 'Contact Site Administrator'	);
						INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
										CEL_FILE_NAME  ,
										CEL_ROW_ID     ,
										CEL_ERROR_MESG ,
										CEL_LUPD_USER  ,
										CEL_LUPD_DATE  ,
										CEL_PROB_ACTION	)
								VALUES	(	instcode	,
										' '		,
										SUBSTR(y.cci_row_id,1,5)	,
										errmsg		,
										lupduser	,
										SYSDATE		,
										'Contact Site Administrator');
						UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
					END IF;


--shyam
					IF errmsg = 'OK' THEN

					IF y.cci_comm_addr = '0' THEN
					IF trim(y.CCI_OADDR_LINE1) != '' OR y.CCI_OADDR_LINE1 IS NOT NULL THEN
					Sp_Create_Addr(	instcode, cust, y.CCI_OADDR_LINE1 ,y.CCI_OADDR_LINE2 ,y.cci_seg12_name_line2,y.cci_opostal_code,
					y.cci_ophone,y.cci_omobile ,y.cci_oemail,v_gcm_cntry_code,y.cci_ocity,y.cci_ostate,NULL,'O',lupduser,addrcode1,errmsg);
					END IF;
					ELSE
					IF trim(y.cci_seg12_addr_line1) !='' OR y.cci_seg12_addr_line1 IS NOT NULL THEN
					Sp_Create_Addr(	instcode, cust, y.cci_seg12_addr_line1,y.cci_seg12_addr_line2,y.cci_seg12_name_line2,y.cci_seg12_postal_code,
					y.cci_seg12_open_text1,y.cci_rmobile ,y.cci_remail,v_gcm_cntry_code,y.cci_seg12_city,y.cci_seg12_state,NULL,'O',lupduser,addrcode1,errmsg);
					END IF;

					END IF;

					DBMS_OUTPUT.PUT_LINE('After calling addr proc'||errmsg);
					IF errmsg != 'OK' THEN
						errmsg := 'From sp_create_addr '||errmsg ||' for file '|| ' '||' and row id '|| y.cci_row_id;
						ROLLBACK;
						DBMS_OUTPUT.PUT_LINE ('err' || instcode	|| ' '	||	SUBSTR(y.cci_row_id,1,5) || errmsg || lupduser  || SYSDATE || 'Contact Site Administrator'	);
						INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
										CEL_FILE_NAME  ,
										CEL_ROW_ID     ,
										CEL_ERROR_MESG ,
										CEL_LUPD_USER  ,
										CEL_LUPD_DATE  ,
										CEL_PROB_ACTION	)
								VALUES	(	instcode	,
										' '		,
										SUBSTR(y.cci_row_id,1,5)	,
										errmsg		,
										lupduser	,
										SYSDATE		,
										'Contact Site Administrator');
						UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
					END IF;
					END IF;
					EXCEPTION	--excp 1.2
					WHEN NO_DATA_FOUND THEN
						errmsg := 'No country found in country master for file '|| ' '||' and row id '|| y.cci_row_id;
						ROLLBACK;
						INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
										CEL_FILE_NAME  ,
										CEL_ROW_ID     ,
										CEL_ERROR_MESG ,
										CEL_LUPD_USER  ,
										CEL_LUPD_DATE  ,
										CEL_PROB_ACTION	)
								VALUES	(	instcode	,
										' '		,
										SUBSTR(y.cci_row_id,1,5),
										errmsg		,
										lupduser	,
										SYSDATE		,
										'Contact Site Administrator');
							--		dbms_output.put_line('insrt com');
						UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
					WHEN OTHERS THEN
						errmsg := 'Excp 1.2 -- '||SQLERRM||' for file '|| ' '||' and row id '|| y.cci_row_id;
						ROLLBACK;
						INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
									CEL_FILE_NAME  ,
									CEL_ROW_ID     ,
									CEL_ERROR_MESG ,
									CEL_LUPD_USER  ,
									CEL_LUPD_DATE  ,
									CEL_PROB_ACTION	)
							VALUES	(	instcode	,
									' '		,
									SUBSTR(y.cci_row_id,1,5)	,
									errmsg		,
									lupduser	,
									SYSDATE		,
									'Contact Site Administrator');
						UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
					END;		--end begin 1.2
				END IF;
				IF errmsg = 'OK' THEN		--account part
					BEGIN		--begin 1.3
					--call the local procedure which handles the account part
					DBMS_OUTPUT.PUT_LINE('acct fethc start');
					lp_acct_part(cust, addrcode,  y.cci_row_id, y.cci_ins_date , y.cci_fiid, acctid, errmsg) ;
					IF errmsg != 'OK' THEN
						errmsg := 'From lp_acct_part '||errmsg ||' for file '|| ' ' ||' and row id '|| y.cci_row_id;
						ROLLBACK;
						INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
									CEL_FILE_NAME  ,
									CEL_ROW_ID     ,
									CEL_ERROR_MESG ,
									CEL_LUPD_USER  ,
									CEL_LUPD_DATE  ,
									CEL_PROB_ACTION	)
								VALUES	(	instcode	,
									' '		,
									SUBSTR(y.cci_row_id,1,5)	,
									errmsg		,
									lupduser	,
									SYSDATE		,
									'Contact Site Administrator');
						UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
					END IF;
					EXCEPTION	--excp 1.3
					WHEN OTHERS THEN
						errmsg := 'Excp 1.3 -- '||SQLERRM||' for file '|| ' '||' and row id '|| y.cci_row_id;
						ROLLBACK;
						INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
									CEL_FILE_NAME  ,
									CEL_ROW_ID     ,
									CEL_ERROR_MESG ,
									CEL_LUPD_USER  ,
									CEL_LUPD_DATE  ,
									CEL_PROB_ACTION	)
							VALUES	(	instcode	,
									' '		,
									SUBSTR(y.cci_row_id,1,5)	,
									errmsg		,
									lupduser	,
									SYSDATE		,
									'Contact Site Administrator');
							UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
					END	;		--end begin 1.3
				END IF;
				IF	errmsg = 'OK' THEN	--application part
					BEGIN		--begin 1.4
						SELECT	cpm_interchange_code
						INTO	v_cpm_interchange_code
						FROM	CMS_PRODTYPE_MAP
						WHERE	cpm_inst_code	=	instcode
						AND	cpm_prod_b24	=		DECODE(trim(y.cci_crd_typ),'VD','VD','ND','PD','NA','P','MD','MD','VP','VP','MP','MP');
						DBMS_OUTPUT.PUT_LINE('After inter') ;
						v_cpb_prod_code:=y.cci_prefix;
						/*SELECT	cpb_prod_code
						INTO 	v_cpb_prod_code
						FROM	CMS_PROD_BIN
						WHERE	cpb_inst_code		=	instcode
						AND	cpb_inst_bin		=	y.cci_pan_code
						AND	cpb_interchange_code	=	v_cpm_interchange_code
						AND	cpb_active_bin		=	'Y';	--added on 17/09/2002*/

						DBMS_OUTPUT.PUT_LINE ('PROD AMOUNT ' || y.cci_prod_amt );
						IF y.cci_prod_amt ='*' OR y.cci_prod_amt IS NULL THEN	--cust catg comes as '*   ' or '    ' in the infile
							v_ccc_catg_code := 10;--custom
						ELSE
						BEGIN
							SELECT	ccc_catg_code
							INTO	v_ccc_catg_code
							FROM	CMS_CUST_CATG
							WHERE	ccc_inst_code		=	instcode
							AND	ccc_catg_sname		=	trim(y.cci_prod_amt	);
						EXCEPTION
						WHEN NO_DATA_FOUND THEN
							v_ccc_catg_code := 10;--custom
						END;
						END IF;
						DBMS_OUTPUT.PUT_LINE('After 11') ;
						/* IF y.cci_pan_code = '466706' and y.cci_seg12_branch_num = 'HNI' then
							prodcattype := 2;
						ELSE
							--1CH210203
							IF y.cci_pan_code = '504642' AND y.cci_fiid = '0035' THEN--by this we mean that its a domestic debit card for octoroi card category
							prodcattype := 2;
							ELSE
							prodcattype := 1;
							END IF;
						END IF; */
						prodcattype := y.cci_card_type;
						/*BEGIN	--begin new 1.4.1
							SELECT	1
							INTO	dum
							FROM	CMS_PROD_CCC
							WHERE	cpc_inst_code	=	instcode
							AND	cpc_cust_catg	=	v_ccc_catg_code
							AND	cpc_prod_code	=	v_cpb_prod_code
							AND	cpc_card_type	=	prodcattype	;
							EXCEPTION	--excp of new 1.4.1
							WHEN NO_DATA_FOUND THEN
							--call the procedure which creates applications
							--Sp_Create_Prodccc(instcode,v_ccc_catg_code,NULL,prodcattype,v_cpb_prod_code,lupduser,errmsg);
							IF errmsg != 'OK' THEN
								errmsg := 'Problem while attaching cust catg for pan '||y.cci_row_id;
								ROLLBACK;
								INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
												CEL_FILE_NAME  ,
												CEL_ROW_ID     ,
												CEL_ERROR_MESG ,
												CEL_LUPD_USER  ,
												CEL_LUPD_DATE  ,
												CEL_PROB_ACTION	)
										VALUES	(	instcode	,
												' '		,
												SUBSTR(y.cci_row_id,1,5)	,
												errmsg		,
												lupduser	,
												SYSDATE		,
												'Contact Site Administrator');
							UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
							END IF;
						END;	*/--end of new 1.4.1


						--shyam 08 sep 05 cr 138 - card expry--start
						BEGIN	--begin new 1.4.11
  						SELECT	cpm_validity_period,cpm_var_flag
  						INTO	 expry_param,var_flag --** Rama prabhuR checking var flag for cust catg
  						FROM	CMS_PROD_MAST
  						WHERE	cpm_inst_code	=	instcode
  						AND	cpm_prod_code	=	v_cpb_prod_code;
						IF var_flag ='V' THEN
						v_ccc_catg_code := 10;--custom
						END IF;
  						EXCEPTION	--excp of new 1.4.1
  						WHEN NO_DATA_FOUND THEN
							expry_param:=120;
  						END;	--end of new 1.4.11

--shyam 08 sep 05 cr 138 - card expry--end



						--dbms_output.put_line('error point 0');

						IF errmsg = 'OK' THEN
						DBMS_OUTPUT.PUT_LINE('ckpt 3 prod  :  '||v_cpb_prod_code);
						DBMS_OUTPUT.PUT_LINE('prodcarstype  : '||prodcattype);
						DBMS_OUTPUT.PUT_LINE('Cust catg : '||v_ccc_catg_code);

						Sp_Create_Appl(	instcode,
								1,
								1,
								y.cci_appl_no,
								SYSDATE,
								SYSDATE,
								cust,
								y.cci_fiid,
								v_cpb_prod_code,
								prodcattype,--(normal or blue depending upon hni or others cust catg)
								v_ccc_catg_code,	--customer category
								SYSDATE, -- last_day(add_months(to_date(y.cci_exp_dat,'YYMM'),-(expry_param))), -- Ashwini -25 Jan 05----  to be written as code refered frm hdfc ,
                           -- Expry date is last day of the prev month after adding expry param
								LAST_DAY(ADD_MONTHS(SYSDATE,expry_param-1)), --last_day(to_date(y.cci_exp_dat,'YYMM')), -- Ashwini-25 Jan 05 ----  to be written as code refered frm hdfc --
								SUBSTR(y.cci_seg12_name_line1,1,30),
								0,
								'N',
								NULL,
								1,--total account count  = 1 since in upload a card is associated with only one account
								'P'	,--addon status always a primary application
								0	,--addon link 0 means that the appln is for promary pan
								addrcode	 ,--billing address
								NULL	,--channel code
								NULL ,
								y.cci_payref_no,
								lupduser	,
								lupduser	,
								applcode	,--out param
								errmsg);
								DBMS_OUTPUT.PUT_LINE('ckpt 4 here errmsg = '||errmsg);
								DBMS_OUTPUT.PUT_LINE('error point 1');



								IF errmsg != 'OK' THEN
									errmsg := 'From sp_create_appl '||errmsg ||' for file '|| ' '||' and row id '|| y.cci_row_id;
									ROLLBACK;
									INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
												CEL_FILE_NAME  ,
												CEL_ROW_ID     ,
												CEL_ERROR_MESG ,
												CEL_LUPD_USER  ,
												CEL_LUPD_DATE  ,
												CEL_PROB_ACTION	)
										VALUES	(	instcode	,
												' '		,
												SUBSTR(y.cci_row_id,1,5)	,
												errmsg		,
												lupduser	,
												SYSDATE		,
												'Contact Site Administrator');
								END IF;
						END IF;

						IF errmsg = 'OK' THEN
						Sp_Create_Payment_Pcms(instcode,applcode,cust,y.cci_payment_mode,y.cci_instrument_no,y.cci_instrument_amt,lupduser,SYSDATE,errmsg);
						END IF;

						IF errmsg != 'OK' THEN
							errmsg := 'From sp_create_appldet '||errmsg ||' for file '|| ' '||' and row id '|| y.cci_row_id;
							ROLLBACK;
							INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
										CEL_FILE_NAME  ,
										CEL_ROW_ID     ,
										CEL_ERROR_MESG ,
										CEL_LUPD_USER  ,
										CEL_LUPD_DATE  ,
										CEL_PROB_ACTION	)
								VALUES	(	instcode	,
										' '	,
										SUBSTR(y.cci_row_id,1,5)	,
										errmsg		,
										lupduser	,
										SYSDATE		,
										'Contact Site Administrator');
							UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
						END IF;

						IF errmsg = 'OK' THEN
							--call the procedure which creates appldets
							DBMS_OUTPUT.PUT_LINE('ckpt 5');
							Sp_Create_Appldet(instcode, applcode, acctid, 1, lupduser, errmsg)	;
							DBMS_OUTPUT.PUT_LINE('ckpt 6');
						END IF;
						IF errmsg != 'OK' THEN
							errmsg := 'From sp_create_appldet '||errmsg ||' for file '|| ' '||' and row id '|| y.cci_row_id;
							ROLLBACK;
							INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
										CEL_FILE_NAME  ,
										CEL_ROW_ID     ,
										CEL_ERROR_MESG ,
										CEL_LUPD_USER  ,
										CEL_LUPD_DATE  ,
										CEL_PROB_ACTION	)
								VALUES	(	instcode	,
										' '	,
										SUBSTR(y.cci_row_id,1,5)	,
										errmsg		,
										lupduser	,
										SYSDATE		,
										'Contact Site Administrator');
							UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
						ELSIF errmsg = 'OK' THEN
						/*UPDATE cms_appl_mast
						SET		cam_appl_stat	=	dupflag
						WHERE	cam_inst_code	=	instcode
						AND		cam_appl_code	=	applcode;*/
						-- Added by Christopher for  Secondary Accounts
						   IF  y.cci_seg31_num1 IS NOT NULL AND LENGTH(trim(y.cci_seg31_num1)) > 0 THEN -- 1st Secondary Acct IF
							--lp_secondary_accts(cust IN number, addr IN number, branch IN varchar2,acct_typ IN varchar2,acct_stat IN varchar2 , acctid OUT varchar2, lperr OUT varchar2 )
							lp_secondary_accts  (cust,y.cci_seg31_num1 , addrcode,  y.cci_fiid,y.cci_seg31_typ1,y.cci_seg31_stat1,acctid, errmsg)   ;
							IF errmsg != 'OK' THEN
						             errmsg := 'From lp_secondary_accts '||errmsg ||' for file '|| ' ' ||' and row id '|| y.cci_row_id ||' '||y.cci_seg31_num1;
						             ROLLBACK;
						             INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
									CEL_FILE_NAME  ,
									CEL_ROW_ID     ,
									CEL_ERROR_MESG ,
									CEL_LUPD_USER  ,
									CEL_LUPD_DATE  ,
									CEL_PROB_ACTION	)
								VALUES	(	instcode	,
									' '		,
									SUBSTR(y.cci_row_id,1,5)	,
									errmsg		,
									lupduser	,
									SYSDATE		,
									'Contact Site Administrator');
								UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
							END IF;
							IF errmsg = 'OK' THEN
								Sp_Create_Appldet(instcode, applcode, acctid, 2, lupduser, errmsg);
								IF errmsg != 'OK' THEN
									errmsg := 'From sp_create_appldet in secondary acct 1'||errmsg ||' for file '|| ' '||' and row id '|| y.cci_row_id;
									ROLLBACK;
									INSERT INTO CMS_ERROR_LOG(	cel_file_name       ,
													cel_row_id          ,
													cel_error_mesg      ,
													cel_lupd_user,
													cel_lupd_date)
												VALUES(' '	,
													y.cci_row_id	,
													errmsg		,
													lupduser,
													SYSDATE);
									UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
								 END IF;
							END IF ;
						   END IF ;  -- 1st Secondary Acct IF
						   IF  y.cci_seg31_num2 IS NOT NULL AND LENGTH(trim(y.cci_seg31_num2)) > 0 THEN -- 2nd Secondary Acct IF
							--lp_secondary_accts(cust IN number, addr IN number, branch IN varchar2,acct_typ IN varchar2,acct_stat IN varchar2 , acctid OUT varchar2, lperr OUT varchar2 )
							lp_secondary_accts  (cust,y.cci_seg31_num2 , addrcode,  y.cci_fiid,y.cci_seg31_typ2,y.cci_seg31_stat2,acctid, errmsg)   ;
							IF errmsg != 'OK' THEN
						             errmsg := 'From lp_secondary_accts for secondary acct2 '||errmsg ||' for file '|| ' ' ||' and row id '|| y.cci_row_id;
						             ROLLBACK;
						             INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
									CEL_FILE_NAME  ,
									CEL_ROW_ID     ,
									CEL_ERROR_MESG ,
									CEL_LUPD_USER  ,
									CEL_LUPD_DATE  ,
									CEL_PROB_ACTION	)
								VALUES	(	instcode	,
									' '		,
									SUBSTR(y.cci_row_id,1,5)	,
									errmsg		,
									lupduser	,
									SYSDATE		,
									'Contact Site Administrator');
								UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
							END IF;
							IF errmsg = 'OK' THEN
								Sp_Create_Appldet(instcode, applcode, acctid, 3, lupduser, errmsg);
								IF errmsg != 'OK' THEN
									errmsg := 'From sp_create_appldet in secondary acct 1'||errmsg ||' for file '|| ' '||' and row id '|| y.cci_row_id;
									ROLLBACK;
									INSERT INTO CMS_ERROR_LOG(	cel_file_name       ,
													cel_row_id          ,
													cel_error_mesg      ,
													cel_lupd_user,
													cel_lupd_date)
												VALUES(	' '	,
													y.cci_row_id	,
													errmsg		,
													lupduser,
													SYSDATE);
									UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
								 END IF;
							END IF ;
						   END IF ;  -- 2nd Secondary Acct IF
		  IF  y.cci_seg31_num3 IS NOT NULL AND LENGTH(trim(y.cci_seg31_num3)) > 0 THEN -- 3nd Secondary Acct IF
							--lp_secondary_accts(cust IN number, addr IN number, branch IN varchar2,acct_typ IN varchar2,acct_stat IN varchar2 , acctid OUT varchar2, lperr OUT varchar2 )
							lp_secondary_accts  (cust,y.cci_seg31_num3 , addrcode,  y.cci_fiid,y.cci_seg31_typ3,y.cci_seg31_stat3,acctid, errmsg)   ;
							IF errmsg != 'OK' THEN
						             errmsg := 'From lp_secondary_accts for secondary acct3 '||errmsg ||' for file '|| ' ' ||' and row id '|| y.cci_row_id;
						             ROLLBACK;
						             INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
									CEL_FILE_NAME  ,
									CEL_ROW_ID     ,
									CEL_ERROR_MESG ,
									CEL_LUPD_USER  ,
									CEL_LUPD_DATE  ,
									CEL_PROB_ACTION	)
								VALUES	(	instcode	,
									' '		,
									SUBSTR(y.cci_row_id,1,5)	,
									errmsg		,
									lupduser	,
									SYSDATE		,
									'Contact Site Administrator');
								UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
							END IF;
							IF errmsg = 'OK' THEN
								Sp_Create_Appldet(instcode, applcode, acctid, 4, lupduser, errmsg);
								IF errmsg != 'OK' THEN
									errmsg := 'From sp_create_appldet in secondary acct 3'||errmsg ||' for file '|| ' '||' and row id '|| y.cci_row_id;
									ROLLBACK;
									INSERT INTO CMS_ERROR_LOG(	cel_file_name       ,
													cel_row_id          ,
													cel_error_mesg      ,
													cel_lupd_user,
													cel_lupd_date)
												VALUES(	' '	,
													y.cci_row_id	,
													errmsg		,
													lupduser,
													SYSDATE);
									UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
								 END IF;
							END IF ;
						   END IF ;  -- 3nd Secondary Acct IF
			  IF  y.cci_seg31_num4 IS NOT NULL AND LENGTH(trim(y.cci_seg31_num4)) > 0 THEN -- 4th Secondary Acct IF
							--lp_secondary_accts(cust IN number, addr IN number, branch IN varchar2,acct_typ IN varchar2,acct_stat IN varchar2 , acctid OUT varchar2, lperr OUT varchar2 )
							lp_secondary_accts  (cust,y.cci_seg31_num4 , addrcode,  y.cci_fiid,y.cci_seg31_typ4,y.cci_seg31_stat4,acctid, errmsg)   ;
							IF errmsg != 'OK' THEN
						             errmsg := 'From lp_secondary_accts for secondary acct4 '||errmsg ||' for file '|| ' ' ||' and row id '|| y.cci_row_id;
						             ROLLBACK;
						             INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
									CEL_FILE_NAME  ,
									CEL_ROW_ID     ,
									CEL_ERROR_MESG ,
									CEL_LUPD_USER  ,
									CEL_LUPD_DATE  ,
									CEL_PROB_ACTION	)
								VALUES	(	instcode	,
									' '		,
									SUBSTR(y.cci_row_id,1,5)	,
									errmsg		,
									lupduser	,
									SYSDATE		,
									'Contact Site Administrator');
								UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
							END IF;
							IF errmsg = 'OK' THEN
								Sp_Create_Appldet(instcode, applcode, acctid, 5, lupduser, errmsg);
								IF errmsg != 'OK' THEN
									errmsg := 'From sp_create_appldet in secondary acct 4'||errmsg ||' for file '|| ' '||' and row id '|| y.cci_row_id;
									ROLLBACK;
									INSERT INTO CMS_ERROR_LOG(	cel_file_name       ,
													cel_row_id          ,
													cel_error_mesg      ,
													cel_lupd_user,
													cel_lupd_date)
												VALUES(	' '	,
													y.cci_row_id	,
													errmsg		,
													lupduser,
													SYSDATE);
									UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
								 END IF;
							END IF ;
						   END IF ;  -- 4th Secondary Acct IF
						/*   IF errmsg = 'OK' THEN
						UPDATE CMS_APPL_MAST
							SET		cam_appl_stat	=	dupflag
							WHERE	cam_inst_code	=	instcode
							AND		cam_appl_code	=	applcode;
						   END IF ;*/
						END IF;
					EXCEPTION	--excp 1.4
					WHEN OTHERS THEN
						errmsg := 'Excp 1.4 -- '||SQLERRM||' for file '|| ' '||' and row id '|| y.cci_row_id;
						ROLLBACK;
						INSERT INTO CMS_ERROR_LOG (	CEL_INST_CODE  ,
										CEL_FILE_NAME  ,
										CEL_ROW_ID     ,
										CEL_ERROR_MESG ,
										CEL_LUPD_USER  ,
										CEL_LUPD_DATE  ,
										CEL_PROB_ACTION	)
							VALUES	(	instcode	,
									' '		,
									SUBSTR(y.cci_row_id,1,5)	,
									errmsg		,
									lupduser	,
									SYSDATE		,
									'Contact Site Administrator');
					UPDATE PCMS_CAF_INFO_ENTRY SET cci_approved = 'E' WHERE cci_row_id = y.cci_row_id AND cci_ins_date = y.cci_ins_date;
					END;		--end 1.4
				END IF	;

				IF errmsg = 'OK' THEN
		 		       Sp_Ins_Pcmsreqhost(
               NULL,
               NULL,
               y.CCI_FIID,
               y.CCI_PAYREF_NO,
               NULL,
               NULL,
              y. CCI_PROD_AMT,
               NULL,
               NULL,
               NULL,
               'N',
               NULL,
               NULL,
               'IM',
               applcode,
               NULL,
               'P',
               lupduser,
               ERRMSG);
		 		END IF;

				IF errmsg = 'OK' THEN
					UPDATE	PCMS_CAF_INFO_ENTRY
					SET	cci_upld_stat	= 'O'--processing Over
					WHERE	cci_row_id	= y.cci_row_id;
				END IF;
			--dbms_output.put_line('loop ends here');
			END LOOP;--end loop 2 for cursor 2
		ELSE
			errmsg := 'From sp_upload_checklist for file -- '||' '||' '||errmsg;
		END IF;
	EXCEPTION	--excp 1
	WHEN OTHERS THEN
	errmsg := 'Excp 1 -- '||SQLERRM;
	END;		--end begin 1
EXCEPTION	--excp main
WHEN OTHERS THEN
NULL;
errmsg := 'Main Excp -- '||SQLERRM;
END;		--end mai
/


