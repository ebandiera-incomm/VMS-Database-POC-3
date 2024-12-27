CREATE OR REPLACE PROCEDURE VMSCMS.sp_upload_cardbase(	instcode	IN		NUMBER		,
						branchcode	IN		VARCHAR2	,
						lupduser	IN		NUMBER		,
						errmsg		OUT		VARCHAR2	)
AS
cnt NUMBER(5) := 0;

--cursor c1 picks up the branches from cms_branch_mast to be processed futher
/*CURSOR c1
IS
SELECT	distinct cci_fiid  cbm_bran_code
FROM	cms_caf_info_cardbase;*/



/*SELECT	cbm_bran_code
FROM	cms_bran_mast
WHERE	cbm_bran_code LIKE branchcode||'%';*/
--FOR	UPDATE		;



--cursor c2 picks up the actual data from cms_caf_info_cardbase for branches which are picked up from cursor c1
--CURSOR	c2(branch IN varchar2)
CURSOR	c2
IS
SELECT		cci_seg12_cardholder_title,cci_seg12_name_line1,	--custmast part
		cci_seg12_addr_line1,cci_seg12_addr_line2,cci_seg12_name_line2,cci_seg12_city,cci_seg12_state,cci_seg12_postal_code,cci_seg12_country_code,cci_seg12_open_text1,	--address part
		cci_fiid,cci_crd_typ,cci_pan_code,cci_mbr_numb,cci_exp_dat,cci_crd_stat,
		cci_seg12_branch_num,	 --customer category comes in this field
		cci_seg31_num,	cci_seg31_typ, cci_seg31_stat,	--primary account number for the card
		cci_seg31_num1,	cci_seg31_typ1,cci_seg31_stat1,--2nd account attached to the card
		cci_seg31_num2,	cci_seg31_typ2,cci_seg31_stat2,--3rd account attached to the card
		cci_seg31_num3,	cci_seg31_typ3,cci_seg31_stat3,--4th account attached to the card
		cci_seg31_num4,	cci_seg31_typ4,cci_seg31_stat4,--5th account attached to the card
		cci_seg31_num5,	cci_seg31_typ5,cci_seg31_stat5,--6th account attached to the card
		cci_seg31_num6,	cci_seg31_typ6,cci_seg31_stat6,--7th account attached to the card
		cci_seg31_num7,	cci_seg31_typ7,cci_seg31_stat7,--8th account attached to the card
		cci_seg31_num8,	cci_seg31_typ8,cci_seg31_stat8,--9th account attached to the card
		cci_seg31_num9,	cci_seg31_typ9,cci_seg31_stat9--10th account attached to the card
FROM		CMS_CAF_INFO_CARDBASE
WHERE		cci_inst_code		=	instcode;
--AND		cci_fiid		=	branch	;
--AND		cci_pan_code not in (select pan from to_be_dropped);




--variable declaration
cust				CMS_CUST_MAST.ccm_cust_code%TYPE	;
salutcode			CMS_CUST_MAST.ccm_salut_code%TYPE	;
v_gcm_cntry_code		GEN_CNTRY_MAST.gcm_cntry_code%TYPE	;
addrcode			CMS_ADDR_MAST.cam_addr_code%TYPE	;
acctid				CMS_ACCT_MAST.cam_acct_id%TYPE		;
holdposn			CMS_CUST_ACCT.cca_hold_posn%TYPE		;
v_cpb_prod_code			CMS_PROD_BIN	.cpb_prod_code%TYPE		;
applcode			CMS_APPL_MAST.cam_appl_code%TYPE	;
dupflag				CHAR(1);
v_cpm_interchange_code		CMS_PRODTYPE_MAP.cpm_interchange_code%TYPE;
v_ccc_catg_code			CMS_CUST_CATG.ccc_catg_code%TYPE;

v_cat_type_code			CMS_ACCT_TYPE.cat_type_code%TYPE		;
v_cas_stat_code			CMS_ACCT_STAT.cas_stat_code%TYPE		;

v_cci_seg31_acct_cnt		CMS_CAF_INFO_CARDBASE.cci_seg31_acct_cnt%TYPE	;
v_cci_seg31_typ			CMS_CAF_INFO_CARDBASE.cci_seg31_typ%TYPE		;
v_cci_seg31_num			CMS_CAF_INFO_CARDBASE.cci_seg31_num%TYPE	;
v_cci_seg31_stat		CMS_CAF_INFO_CARDBASE.cci_seg31_stat%TYPE	;

v_cci_seg31_typ1		CMS_CAF_INFO_CARDBASE.cci_seg31_typ1%TYPE		;
v_cci_seg31_num1		CMS_CAF_INFO_CARDBASE.cci_seg31_num1%TYPE	;
v_cci_seg31_stat1		CMS_CAF_INFO_CARDBASE.cci_seg31_stat1%TYPE	;

v_cci_seg31_typ2		CMS_CAF_INFO_CARDBASE.cci_seg31_typ2%TYPE		;
v_cci_seg31_num2		CMS_CAF_INFO_CARDBASE.cci_seg31_num2%TYPE	;
v_cci_seg31_stat2		CMS_CAF_INFO_CARDBASE.cci_seg31_stat2%TYPE	;

v_cci_seg31_typ3		CMS_CAF_INFO_CARDBASE.cci_seg31_typ3%TYPE		;
v_cci_seg31_num3		CMS_CAF_INFO_CARDBASE.cci_seg31_num3%TYPE	;
v_cci_seg31_stat3		CMS_CAF_INFO_CARDBASE.cci_seg31_stat3%TYPE	;

v_cci_seg31_typ4		CMS_CAF_INFO_CARDBASE.cci_seg31_typ4%TYPE		;
v_cci_seg31_num4		CMS_CAF_INFO_CARDBASE.cci_seg31_num4%TYPE	;
v_cci_seg31_stat4		CMS_CAF_INFO_CARDBASE.cci_seg31_stat4%TYPE	;

v_cci_seg31_typ5		CMS_CAF_INFO_CARDBASE.cci_seg31_typ5%TYPE		;
v_cci_seg31_num5		CMS_CAF_INFO_CARDBASE.cci_seg31_num5%TYPE	;
v_cci_seg31_stat5		CMS_CAF_INFO_CARDBASE.cci_seg31_stat5%TYPE	;

v_cci_seg31_typ6		CMS_CAF_INFO_CARDBASE.cci_seg31_typ6%TYPE		;
v_cci_seg31_num6		CMS_CAF_INFO_CARDBASE.cci_seg31_num6%TYPE	;
v_cci_seg31_stat6		CMS_CAF_INFO_CARDBASE.cci_seg31_stat6%TYPE	;

v_cci_seg31_typ7		CMS_CAF_INFO_CARDBASE.cci_seg31_typ7%TYPE		;
v_cci_seg31_num7		CMS_CAF_INFO_CARDBASE.cci_seg31_num7%TYPE	;
v_cci_seg31_stat7		CMS_CAF_INFO_CARDBASE. cci_seg31_stat7%TYPE	;

v_cci_seg31_typ8		CMS_CAF_INFO_CARDBASE.cci_seg31_typ8%TYPE		;
v_cci_seg31_num8		CMS_CAF_INFO_CARDBASE.cci_seg31_num8%TYPE	;
v_cci_seg31_stat8		CMS_CAF_INFO_CARDBASE. cci_seg31_stat8%TYPE	;

v_cci_seg31_typ9		CMS_CAF_INFO_CARDBASE.cci_seg31_typ9%TYPE		;
v_cci_seg31_num9		CMS_CAF_INFO_CARDBASE.cci_seg31_num9%TYPE	;
v_cci_seg31_stat9		CMS_CAF_INFO_CARDBASE. cci_seg31_stat9%TYPE	;

expry_param			NUMBER(3);
dum NUMBER(1);
prodcattype	NUMBER(1);
---1.
--local procedure for handling the account part
PROCEDURE lp_acct_part(cust IN NUMBER, addr IN NUMBER, brancode IN VARCHAR2, pancode IN NUMBER, branch IN VARCHAR2, acctno IN VARCHAR2, accttype IN VARCHAR2, acctstat IN VARCHAR2, acctid OUT VARCHAR2, lperr OUT VARCHAR2)
IS
BEGIN		--main begin local proc
dupflag	:=	'A';
	BEGIN		--begin lp1
/*	SELECT		cci_seg31_acct_cnt,		cci_seg31_typ,			cci_seg31_num ,			cci_seg31_stat ,
			0cci_seg31_typ1,			cci_seg31_num1 ,		cci_seg31_stat1 ,
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
	FROM	cms_caf_info_cardbase
	WHERE	cci_fiid	= brancode
	AND	cci_pan_code	= pancode	;	*/

	--for primary account
	BEGIN
	SELECT cat_type_code
	INTO	v_cat_type_code
	FROM	CMS_ACCT_TYPE
	WHERE	cat_inst_code		=	instcode
	AND	cat_switch_type		=	accttype	;
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
	v_cat_type_code := 1;
	END;

	/*SELECT	a.cas_stat_code
	INTO	v_cas_stat_code
	FROM	cms_acct_stat a, cms_acct_stat_b24 b
	WHERE	a.cas_inst_code		=	b.cas_inst_code
	AND	a.cas_stat_code		=	b.cas_acct_stat
	AND	a.cas_inst_code		=	instcode
	AND	b.cas_acct_stat_b24	=	acctstat		;*/
	--select above commented and the new select as below is added on 19/09/2002 because now mapping is available
	SELECT	cas_stat_code
	INTO	v_cas_stat_code
	FROM	CMS_ACCT_STAT
	WHERE	cas_inst_code		= instcode
	AND	cas_switch_statcode	= acctstat;

	--now call the procedure for creating account(for primary account)
	sp_create_acct(instcode, acctno ,1, branch, addr, v_cat_type_code, v_cas_stat_code, lupduser, acctid, lperr)	;
	IF	lperr !=  'OK' THEN
		IF lperr  = 'Account No already in Master.' THEN
		lperr := 'OK';
		dupflag	:=	'D';--since the account creation has returned the account duplicate message
		--now update the holder count of the account (since the account is same)
		UPDATE CMS_ACCT_MAST
		SET		cam_hold_count	=	cam_hold_count+1,
				cam_lupd_user	=	lupduser
		WHERE		cam_inst_code	=	instcode
		AND		cam_acct_no	=	acctno;
		--AND		cam_acct_no	=	v_cci_seg31_num	;
		ELSE
		lperr := 'From sp_create_acct '||lperr||' for branch '|| branch||' and pan '|| pancode;
		END IF;
	END IF;

	--now attach the account to the customer(create holder)
	IF lperr = 'OK' THEN
		sp_create_holder(instcode, cust, acctid, NULL, lupduser, holdposn, lperr)	;
		IF errmsg != 'OK' THEN
		errmsg := 'From sp_create_holder '||lperr ||' for branch '|| branch||' and pan '|| pancode;
		END IF;
	END IF;


	EXCEPTION		--excp lp1
	WHEN OTHERS THEN
	lperr := 'Excp Lp1 -- '||SQLERRM;
	END;		--end lp1
EXCEPTION	--main excp of local proc
WHEN OTHERS THEN
lperr := 'Local Excp1 -- '||SQLERRM;
END;		--end main of local proc
--end local procedure 1

---2.
--local procedure to insert rows into the cms_appl_pan table
PROCEDURE lp_insert_into_cms_appl_pan(	custcatg_in_var IN VARCHAR2,
					prodcode IN VARCHAR2,custcatg  IN NUMBER	,
				  	pancode  IN VARCHAR2,mbrnumb IN VARCHAR2,cardstat IN VARCHAR2,custcode IN NUMBER	 ,dispname IN VARCHAR2	, limitamt  IN NUMBER	,
					uselimit IN NUMBER  ,applbran IN VARCHAR2,actvdate IN DATE	, exprydate IN DATE	,
					adonstat IN CHAR    ,adonlink IN VARCHAR2,acctno   IN VARCHAR2	, acctid    IN NUMBER	,
					billaddr IN NUMBER  ,chnlcode IN NUMBER	, lupduser IN NUMBER	, lperr2   OUT VARCHAR2  )

IS
v_cpm_catg_code	VARCHAR2 (2)	;
--acctidin	cms_acct_mast.cam_acct_id%TYPE;
BEGIN		--begin lp2
lperr2 := 'OK';
SELECT 	cpm_catg_code
INTO	v_cpm_catg_code
FROM	CMS_PROD_MAST
WHERE	cpm_inst_code	=	instcode
AND	cpm_prod_code	=	prodcode;

/*SELECT	cam_acct_id
INTO	acctid
FROM	cms_acct_mast
WHERE	cam_acct_no = acctno;*/

IF SUBSTR(pancode,1,6) = '466706' AND custcatg_in_var = 'HNI' THEN
prodcattype := 2;
ELSE
prodcattype := 1;
END IF;

INSERT INTO CMS_APPL_PAN(	CAP_APPL_CODE		,	CAP_INST_CODE		,	CAP_ASSO_CODE		,
				CAP_INST_TYPE		,	CAP_PROD_CODE		, 	CAP_PROD_CATG		,
				CAP_CARD_TYPE		,	CAP_CUST_CATG		,	CAP_PAN_CODE		,
				CAP_MBR_NUMB		,	CAP_CARD_STAT		,	CAP_CUST_CODE		,
				CAP_DISP_NAME		,	CAP_LIMIT_AMT		,	CAP_USE_LIMIT		,
				CAP_APPL_BRAN		,	CAP_ACTIVE_DATE		,  	CAP_EXPRY_DATE		,
				CAP_ADDON_STAT		,	CAP_ADDON_LINK		,	CAP_MBR_LINK		,
				CAP_ACCT_ID		,	CAP_ACCT_NO		,	CAP_TOT_ACCT		,
				CAP_BILL_ADDR		,	CAP_CHNL_CODE		,	CAP_PANGEN_DATE		,
				CAP_PANGEN_USER		,   	CAP_CAFGEN_FLAG		,	CAP_PIN_FLAG		,
				CAP_EMBOS_FLAG		,	CAP_PHY_EMBOS		,	CAP_JOIN_FEECALC	,
				CAP_INS_USER		,	CAP_LUPD_USER		)
		VALUES(		NULL			,	instcode		,	1			,
				1			,	prodcode		,	v_cpm_catg_code		,
/*decode(trim(custcatg_in_var),'HNI',1,1)*/prodcattype	,	custcatg		,	pancode			,
				mbrnumb			,	cardstat		,	custcode		,
				dispname		,	limitamt		,	uselimit		,
				applbran		,	actvdate		,	exprydate		,
				adonstat		,	adonlink		,	mbrnumb			,
				acctid			,	acctno			,	1			,--initially 1, will be updated if more accts are linked
				billaddr		,	chnlcode		,	SYSDATE			,
				lupduser		,	'N'			,	'N'			,
				'N'			,	'N'			,	'N'			,
				lupduser		,	lupduser		)	;
EXCEPTION	--excp lp2
WHEN OTHERS THEN
lperr2 := 'Local Excp2 -- '||SQLERRM;
END;		--end lp2

---3.
PROCEDURE lp_insert_into_cms_pan_acct(cust IN NUMBER, acctid IN NUMBER,acctposn IN NUMBER, pancode IN VARCHAR2, mbrnumb IN VARCHAR2,lupduser IN NUMBER, lperr3 OUT VARCHAR2)
IS
BEGIN			--begin lp3
lperr3 := 'OK';
INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
				CPA_CUST_CODE		,
				CPA_ACCT_ID		,
				CPA_ACCT_POSN		,
				CPA_PAN_CODE		,
				CPA_MBR_NUMB		,
				CPA_INS_USER		,
				CPA_LUPD_USER		)
		VALUES(		instcode	,
				cust		,
				acctid		,
				acctposn	,
				pancode		,
				mbrnumb		,
				lupduser	,
				lupduser	);
EXCEPTION
WHEN OTHERS THEN	--excp lp3
lperr3 := 'Local Excp3 -- '||SQLERRM;
END;		--end lp3




BEGIN		--main begin
errmsg := 'OK';	--initial errmsg status
SELECT	cip_param_value	--added on 11/10/2002 ...gets the card validity period in months from parameter table
INTO	expry_param
FROM	CMS_INST_PARAM
WHERE	cip_inst_code = instcode
AND	cip_param_key = 'CARD EXPRY';

	BEGIN		--begin 1 encloses the loops 1 and 2
	/*FOR x IN c1	--loop 1, for cursor c1
	LOOP*/
	--COMMIT;
	--cnt := 0;

		/*IF errmsg != 'OK' THEN
		EXIT;	 --from c1
		END IF;*/

			--FOR y IN c2(y.cci_fiid)	--loop 2, for cursor 2
			FOR y IN c2
			LOOP
			--COMMIT;	commit at the first because if eror comes the the transaction is rolled back... but the error log table is filled so that has to be commited here
				--in other normal cases the record will get commited at the start of the next record

				/*IF errmsg != 'OK' THEN
				EXIT;		--from c2
				END IF;*/
			BEGIN		--begin 1.1 --customer part
			/*the sp_create cust looks like this
1			INSTCODE		NUMBER		IN
2			CUSTTYPE		NUMBER		IN
3			CORPCODE                NUMBER		IN
4			CUSTSTAT                CHAR		IN
5			SALUTCODE               VARCHAR2	IN
6			FIRSTNAME               VARCHAR2	IN
7			MIDNAME                 VARCHAR2	IN
8			LASTNAME                VARCHAR2	IN
9			DOB			DATE		IN
10			GENDER                  CHAR            IN
11			MARSTAT                 CHAR            IN
12			PERMID			NUMBER		IN
13			EMAIL1			VARCHAR2	IN
14			EMAIL2			VARCHAR2	IN
15			MOBL1			VARCHAR2	IN
16			MOBL2			VARCHAR2	IN
17			LUPDUSER                NUMBER		IN
18			CUSTCODE                NUMBER		OUT
19			ERRMSG                  VARCHAR2	OUT
			*/
				IF	y.cci_seg12_cardholder_title = '0'		THEN
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
				sp_create_cust(instcode,1,0,'Y',salutcode,
							NVL(y.cci_seg12_name_line1,RPAD(' ',25,' ')), NULL,' ',
							TO_DATE('15-AUG-1947','DD-MON-YYYY'),'M','Y',NULL,NULL,NULL,NULL,NULL,lupduser,cust,errmsg);
				IF errmsg != 'OK' THEN
				errmsg := 'From sp_create_cust '||errmsg ||' for branch '|| y.cci_fiid||' and pan '|| y.cci_pan_code;
				ROLLBACK;
				/*INSERT INTO cms_cardbase_err_log (CEL_INST_CODE  ,
								cel_branch_code  ,
								cel_pan_code     ,
								CEL_ERROR_MESG ,
								CEL_PROB_ACTION	)
						VALUES	(	instcode	,
								y.cci_fiid	,
								y.cci_pan_code	,
								errmsg		,
								'Contact Site Administrator');*/
				sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);

				END IF;
			EXCEPTION		--excp 1.1
			WHEN OTHERS THEN
			errmsg := 'Excp 1.1 -- '||SQLERRM;
			ROLLBACK;
			/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
							cel_branch_code  ,
							cel_pan_code     ,
							CEL_ERROR_MESG ,
							CEL_PROB_ACTION	)
					VALUES	(	instcode	,
							y.cci_fiid	,
							y.cci_pan_code	,
							errmsg		,
							'Contact Site Administrator');*/
			sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);

			END;		--end begin 1.1

				IF errmsg = 'OK' THEN	--address part
				BEGIN		--begin 1.2
				--the sp_create_addr looks like this
/*				INSTCODE			NUMBER		           IN
				CUSTCODE			NUMBER			   IN
				ADD1				VARCHAR2		   IN
				ADD2				VARCHAR2		   IN
				ADD3				VARCHAR2		   IN
				PINCODE				NUMBER                     IN
				PHON1				VARCHAR2                   IN
				PHON2				VARCHAR2                   IN
				CNTRYCODE			NUMBER                     IN
				CITYNAME			VARCHAR2                   IN
				SWITCHSTAT			VARCHAR2		   IN
				FAX1				VARCHAR2                   IN
				ADDRFLAG			CHAR			   IN
				LUPDUSER			NUMBER			   IN
				ADDRCODE			NUMBER                     OUT
				ERRMSG				VARCHAR2                   OUT	*/
--				dbms_output.put_line('Before select =====>'||y.cci_seg12_country_code||'==='||y.cci_pan_code);

				SELECT gcm_cntry_code
				INTO	v_gcm_cntry_code
				FROM	GEN_CNTRY_MAST
				WHERE	gcm_curr_code	=	y.cci_seg12_country_code	;
				/*IF y.cci_pan_code = '4667060001079417' then
				dbms_output.put_line('Before calling addr proc');
				dbms_output.put_line('Instcode= '||instcode);
				dbms_output.put_line('Customer code = '||cust||'^');
				dbms_output.put_line('Addr one = '||y.cci_seg12_addr_line1||'^');
				dbms_output.put_line('Addr two = '||y.cci_seg12_addr_line2||'^');
				dbms_output.put_line('Addr three = '||y.cci_seg12_name_line2||'^');
				dbms_output.put_line('Pin code = '||y.cci_seg12_postal_code||'^');
				dbms_output.put_line('Open text = '||y.cci_seg12_open_text1||'^');
				dbms_output.put_line('Country code = '||v_gcm_cntry_code||'^');
				dbms_output.put_line('City = '||y.cci_seg12_city||'^');
				dbms_output.put_line('State = '||y.cci_seg12_state||'^');
				END IF;*/
				sp_create_addr(	instcode, cust, NVL(y.cci_seg12_addr_line1,RPAD(' ',25,' ')),y.cci_seg12_addr_line2,y.cci_seg12_name_line2,NVL(y.cci_seg12_postal_code,RPAD(' ',8,' ')),
				y.cci_seg12_open_text1,NULL,v_gcm_cntry_code,NVL(y.cci_seg12_city,RPAD(' ',25,' ')),y.cci_seg12_state,NULL,'P',lupduser,addrcode,errmsg);
--				dbms_output.put_line('After calling addr proc');
				IF errmsg != 'OK' THEN
				errmsg := 'From sp_create_addr '||errmsg ||' for branch '|| y.cci_fiid||' and pan '|| y.cci_pan_code;
				ROLLBACK;
				/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
								cel_branch_code  ,
								cel_pan_code     ,
								CEL_ERROR_MESG ,
								CEL_PROB_ACTION	)
						VALUES	(	instcode	,
								y.cci_fiid	,
								y.cci_pan_code	,
								errmsg		,
								'Contact Site Administrator');*/
				sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);

				END IF;

				EXCEPTION	--excp 1.2
				WHEN NO_DATA_FOUND THEN
				errmsg := 'No country found in country master for branch '|| y.cci_fiid||' and row id '|| y.cci_pan_code;
				ROLLBACK;
				/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
								cel_branch_code  ,
								cel_pan_code     ,
								CEL_ERROR_MESG ,
								CEL_PROB_ACTION	)
						VALUES	(	instcode	,
								y.cci_fiid	,
								y.cci_pan_code	,
								errmsg		,
								'Contact Site Administrator');*/
								sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
				WHEN OTHERS THEN
				errmsg := 'Excp 1.2 -- '||SQLERRM||' for branch '|| y.cci_fiid||' and pan '|| y.cci_pan_code;
				ROLLBACK;
				/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
								cel_branch_code  ,
								cel_pan_code     ,
								CEL_ERROR_MESG ,
								CEL_PROB_ACTION	)
						VALUES	(	instcode	,
								y.cci_fiid	,
								y.cci_pan_code	,
								errmsg		,
								'Contact Site Administrator');*/
								sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
				END;		--end begin 1.2
				END IF;


				IF errmsg = 'OK' THEN		--account part
				BEGIN		--begin 1.3
				--call the local procedure which handles the account part
				lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num, y.cci_seg31_typ, y.cci_seg31_stat, acctid, errmsg) ;

				IF errmsg != 'OK' THEN
				errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and for primary accnt';
				ROLLBACK;
				/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
								cel_branch_code  ,
								cel_pan_code     ,
								CEL_ERROR_MESG ,
								CEL_PROB_ACTION	)
						VALUES	(	instcode	,
								y.cci_fiid	,
								y.cci_pan_code	,
								errmsg		,
								'Contact Site Administrator');*/
								sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
				END IF;

				EXCEPTION	--excp 1.3
				WHEN OTHERS THEN
				errmsg := 'Excp 1.3 -- '||SQLERRM||' for branch '|| y.cci_fiid||' and pan '|| y.cci_pan_code;
				ROLLBACK;
				/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
								cel_branch_code  ,
								cel_pan_code     ,
								CEL_ERROR_MESG ,
								CEL_PROB_ACTION	)
						VALUES	(	instcode	,
								y.cci_fiid	,
								y.cci_pan_code	,
								errmsg		,
								'Contact Site Administrator');*/
								sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
				END	;		--end begin 1.3
				END IF;

				IF	errmsg = 'OK' THEN	--application part
				BEGIN		--begin 1.4
				SELECT	cpm_interchange_code
				INTO	v_cpm_interchange_code
				FROM	CMS_PRODTYPE_MAP
				WHERE	cpm_inst_code	=	instcode
				AND	cpm_prod_b24	=	y.cci_crd_typ;

				SELECT	cpb_prod_code
				INTO 	v_cpb_prod_code
				FROM	CMS_PROD_BIN
				WHERE	cpb_inst_code		=	instcode
				AND	cpb_inst_bin		=	SUBSTR(y.cci_pan_code,1,6)
				AND	cpb_interchange_code	=	v_cpm_interchange_code;

				BEGIN		--begin 1.4.1
				SELECT	ccc_catg_code
				INTO	v_ccc_catg_code
				FROM	CMS_CUST_CATG
				WHERE	ccc_inst_code		=	instcode
				AND	ccc_catg_sname		=	y.cci_seg12_branch_num	;

				EXCEPTION	--excp of begin 1.4.1
				WHEN NO_DATA_FOUND THEN
				IF trim(y.cci_seg12_branch_num) IN('*',NULL) THEN	--cust catg comes as '*   ' or '    ' in the infile
					v_ccc_catg_code := 1;--default customer category
				END IF;
				END;		--end begin 1.4.1
					/*sp_create_custcatg(instcode, trim(y.cci_seg12_branch_num), 'CREATED DURING UPLOAD', lupduser,v_ccc_catg_code, errmsg);*/
						/*added on 20/11/02 by anup --*/
						BEGIN
						SELECT	1
						INTO	dum
						FROM	CMS_PROD_CCC
						WHERE	cpc_inst_code	=	instcode
						AND	cpc_cust_catg	=	v_ccc_catg_code
						AND	cpc_prod_code	=	v_cpb_prod_code
						AND	cpc_card_type	=	1		;--for default
						EXCEPTION
						WHEN NO_DATA_FOUND THEN
						/*--#Anup 18/11/02  added a call to sp_create_prodccc to create a relation between default product category and the cust catg just created*/
						sp_create_prodccc(instcode,v_ccc_catg_code,NULL,1,v_cpb_prod_code,lupduser,errmsg);
							IF errmsg != 'OK' THEN
								errmsg := 'Problem while attaching cust catg for pan '||y.cci_pan_code;
								ROLLBACK;
								/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
												cel_branch_code  ,
												cel_pan_code     ,
												CEL_ERROR_MESG ,
												CEL_PROB_ACTION	)
										VALUES	(	instcode	,
												y.cci_fiid	,
												y.cci_pan_code	,
												errmsg		,
												'Contact Site Administrator');*/
												sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						WHEN OTHERS THEN
						ROLLBACK;
						/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
						END;



				--call the local procedure which inserts rows into cms_appl_pan table
				--dbms_output.put_line('error point 0');
				IF errmsg = 'OK' THEN
					lp_insert_into_cms_appl_pan(
					y.cci_seg12_branch_num,--added on 19/11/02
					v_cpb_prod_code	,	--product code
					v_ccc_catg_code ,	--cust catg
				  	y.cci_pan_code  ,	--pan
					y.cci_mbr_numb	,	--mbr number
					y.cci_crd_stat	,	--card status
					cust		,	--cust code
					SUBSTR(y.cci_seg12_name_line1,1,30),--display name
					0		,--limit amount
					NULL		,--usage limit
					y.cci_fiid	,--appl branch
					ADD_MONTHS(TO_DATE(y.cci_exp_dat,'YYMM'),-(expry_param)),	--active date
					TO_DATE(y.cci_exp_dat,'YYMM'),			--expiry date
					'P'		,--addon status always a primary
					y.cci_pan_code	,--addon link same as primary pan in case of addon status = 'P'
					y.cci_seg31_num	,--account number
					acctid		,
					addrcode	,--billing address
					NULL		,--channel code
					lupduser	,
					errmsg		);
--dbms_output.put_line('error point 1');
					IF errmsg != 'OK' THEN
					errmsg := 'From lp_insert_into_cms_appl_pan '||errmsg ||' for branch '|| y.cci_fiid||' and pan '|| y.cci_pan_code;
					ROLLBACK;
					/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
									cel_branch_code  ,
									cel_pan_code     ,
									CEL_ERROR_MESG ,
									CEL_PROB_ACTION	)
							VALUES	(	instcode	,
									y.cci_fiid	,
									y.cci_pan_code	,
									errmsg		,
									'Contact Site Administrator');	*/
									sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
					END IF;
				END IF;

					IF errmsg = 'OK' THEN--ok if
					--create pan accts
					--for primary account
					lp_insert_into_cms_pan_acct(cust,acctid,1,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
						IF errmsg != 'OK' THEN
						errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and for primary accnt' ;
						ROLLBACK;
						/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
										cel_branch_code  ,
										cel_pan_code     ,
										CEL_ERROR_MESG ,
										CEL_PROB_ACTION	)
								VALUES	(	instcode	,
										y.cci_fiid	,
										y.cci_pan_code	,
										errmsg		,
										'Contact Site Administrator');*/
										sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
						END IF;
					--for attached account number 2
					IF y.cci_seg31_num1 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num1, y.cci_seg31_typ1, y.cci_seg31_stat1, acctid, errmsg) ;
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 2';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,2,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 2';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');	*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 3
					IF y.cci_seg31_num2 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num2, y.cci_seg31_typ2, y.cci_seg31_stat2, acctid, errmsg) ;
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 3';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,3,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 3';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 4
					IF y.cci_seg31_num3 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num3, y.cci_seg31_typ3, y.cci_seg31_stat3, acctid, errmsg) ;
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 4';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,4,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 4';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 5
					IF y.cci_seg31_num4 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num4, y.cci_seg31_typ4, y.cci_seg31_stat4, acctid, errmsg) ;
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 5';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,5,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 5';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 6
					IF y.cci_seg31_num5 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num5, y.cci_seg31_typ5, y.cci_seg31_stat5, acctid, errmsg) ;
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 6';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,6,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 6';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 7
					IF y.cci_seg31_num6 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num6, y.cci_seg31_typ6, y.cci_seg31_stat6, acctid, errmsg) ;
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 7';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,7,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 7';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 8
					IF y.cci_seg31_num7 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num7, y.cci_seg31_typ7, y.cci_seg31_stat7, acctid, errmsg) ;
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 8';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,8,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 8';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 9
					IF y.cci_seg31_num8 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num8, y.cci_seg31_typ8, y.cci_seg31_stat8, acctid, errmsg) ;
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 9';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,9,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 9';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 10
					IF y.cci_seg31_num9 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num9, y.cci_seg31_typ9, y.cci_seg31_stat9, acctid, errmsg) ;
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 10';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,10,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 10';
							ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					END IF;--ok if

--dbms_output.put_line('error point 2');

				EXCEPTION	--excp 1.4
				WHEN OTHERS THEN
				errmsg := 'Excp 1.4 -- '||SQLERRM||' for branch '|| y.cci_fiid||' and pan '|| y.cci_pan_code;
				ROLLBACK;
							/*INSERT INTO cms_cardbase_err_log (	CEL_INST_CODE  ,
											cel_branch_code  ,
											cel_pan_code     ,
											CEL_ERROR_MESG ,
											CEL_PROB_ACTION	)
									VALUES	(	instcode	,
											y.cci_fiid	,
											y.cci_pan_code	,
											errmsg		,
											'Contact Site Administrator');*/
											sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
				END;		--end 1.4
				END IF	;
			/*cnt := cnt+1;
			IF cnt = 1000 THEN
				COMMIT;
				cnt := 0;
			END IF;*/
			COMMIT;
			END LOOP;--end loop 2 for cursor 2

	--END LOOP;--end loop 1 for cursor 1

	COMMIT;

	EXCEPTION	--excp 1
	WHEN OTHERS THEN
	errmsg := 'Excp 1 -- '||SQLERRM;
	END;		--end begin 1

EXCEPTION	--excp main
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END;		--end main
/


