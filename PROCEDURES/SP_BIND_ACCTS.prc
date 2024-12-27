CREATE OR REPLACE PROCEDURE VMSCMS.sp_bind_accts(	instcode	IN		NUMBER		,
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



PROCEDURE lp_create_holder
							       (instcode 		IN	NUMBER,
								custcode 	IN	NUMBER,
								acctid 		IN	NUMBER,
								acctname	IN	VARCHAR2,
								--billadd1		IN	number, shifted to account level from holder level
								lupduser		IN	NUMBER,
								holdposn		OUT NUMBER,
								errmsg		OUT VARCHAR2)
AS
uniq_excp EXCEPTION;
PRAGMA EXCEPTION_INIT(uniq_excp,-00001);

BEGIN		--Main Begin Block Starts Here
--this if condition commented on 20-06-02 to take in the incoming data in caf format for finacle
--IF instcode IS NOT NULL  AND custcode IS NOT NULL AND acctid IS NOT NULL  AND lupduser IS NOT NULL THEN
/*SELECT 	nvl(max(cca_hold_posn),0)+1
INTO	holdposn
FROM	cms_cust_acct
WHERE 	cca_inst_code = instcode
AND		cca_acct_id   = acctid ;*/
holdposn := 0;


INSERT INTO CMS_CUST_ACCT(	CCA_INST_CODE		,
							CCA_CUST_CODE	,
							CCA_ACCT_ID		,
							CCA_ACCT_NAME		,
							--CCA_BILL_ADDR1	,
							CCA_HOLD_POSN	,
							CCA_REL_STAT		,
							CCA_INS_USER		,
							CCA_LUPD_USER)
				     VALUES(	instcode				,
							custcode				,
							acctid				,
							acctname			,
							--billadd1				,
							holdposn				,
							'Y'					,--means that the relation is active
							lupduser				,
							lupduser				);
errmsg := 'OK';
--ELSE	--IF 1
--errmsg := 'sp_create_holders expected a not null parameter';
--END IF;	--IF 1
EXCEPTION	--Main block Exception
WHEN uniq_excp THEN
errmsg := 'DUP';
WHEN OTHERS THEN
errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;

END;		--Main Begin Block Ends Here




---1.
--local procedure for handling the account part
PROCEDURE lp_acct_part(cust IN NUMBER, addr IN NUMBER, brancode IN VARCHAR2, pancode IN NUMBER, branch IN VARCHAR2, acctno IN VARCHAR2, accttype IN VARCHAR2, acctstat IN VARCHAR2, acctid OUT VARCHAR2, lperr OUT VARCHAR2)
IS
BEGIN		--main begin local proc
dupflag	:=	'A';
	BEGIN		--begin lp1
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
	--dbms_output.put_line('Reached 1');
	IF lperr = 'OK' THEN
	--dbms_output.put_line('Reached 2 msg = '||lperr);
		lp_create_holder(instcode, cust, acctid, NULL, lupduser, holdposn, errmsg)	;
		IF errmsg != 'OK' THEN
			IF errmsg = 'DUP' THEN
			errmsg := 'OK';
			ELSE
			errmsg := 'From lp_create_holder '||lperr ||' for branch '|| branch||' and pan '|| pancode;
			END IF;
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
				  	pancode  IN VARCHAR2,mbrnumb IN VARCHAR2,cardstat IN VARCHAR2,custcode IN NUMBER	 ,dispname IN VARCHAR2	, limitamt  IN NUMBER
	,

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

IF SUBSTR(pancode,1,6) = '466706' AND SUBSTR(custcatg_in_var, 1, 3) = 'HNI' THEN
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
				adonstat		,	adonlink		,	'000'			,
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
PROCEDURE lp_insert_into_cms_pan_acct(cust IN NUMBER, acctid IN NUMBER,acctposn IN NUMBER, pancode IN VARCHAR2, mbrnumb IN VARCHAR2,
lupduser IN NUMBER, lperr3 OUT VARCHAR2)

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

			--FOR y IN c2(y.cci_fiid)	--loop 2, for cursor 2
			FOR y IN c2
			LOOP

			SELECT cap_cust_code, cap_bill_addr
			INTO   cust, addrcode
			FROM   CMS_APPL_PAN
			WHERE cap_pan_code = y.cci_pan_code
			AND   cap_mbr_numb = y.cci_mbr_numb;

				IF errmsg = 'OK' THEN		--account part
				BEGIN		--begin 1.3
				--call the local procedure which handles the account part

				lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num, y.cci_seg31_typ, y.cci_seg31_stat, acctid, errmsg) ;

				IF errmsg != 'OK' THEN
				errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and for primary accnt';
				sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
				END IF;

				EXCEPTION	--excp 1.3
				WHEN OTHERS THEN
				errmsg := 'Excp 1.3 -- '||SQLERRM||' for branch '|| y.cci_fiid||' and pan '|| y.cci_pan_code;
				sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
				END	;		--end begin 1.3
				END IF;



					IF errmsg = 'OK' THEN--ok if
					--create pan accts
					--for primary account
					lp_insert_into_cms_pan_acct(cust,acctid,1,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
						IF errmsg != 'OK' THEN
						errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and for primary accnt' ;

						sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
						END IF;
					--for attached account number 2
					IF y.cci_seg31_num1 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num1, y.cci_seg31_typ1, y.cci_seg31_stat1, acctid, errmsg) ;

							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 2';
							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,2,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 2';

							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 3
					IF y.cci_seg31_num2 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num2, y.cci_seg31_typ2, y.cci_seg31_stat2, acctid, errmsg) ;

							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 3';
							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,3,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 3';

							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 4
					IF y.cci_seg31_num3 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num3, y.cci_seg31_typ3, y.cci_seg31_stat3, acctid, errmsg) ;

							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 4';
							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,4,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 4';

							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 5
					IF y.cci_seg31_num4 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num4, y.cci_seg31_typ4, y.cci_seg31_stat4, acctid, errmsg) ;

							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 5';
							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,5,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 5';

							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 6
					IF y.cci_seg31_num5 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num5, y.cci_seg31_typ5, y.cci_seg31_stat5, acctid, errmsg) ;

							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 6';
							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,6,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 6';

							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 7
					IF y.cci_seg31_num6 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num6, y.cci_seg31_typ6, y.cci_seg31_stat6, acctid, errmsg) ;

							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 7';
							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,7,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 7';

							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 8
					IF y.cci_seg31_num7 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num7, y.cci_seg31_typ7, y.cci_seg31_stat7, acctid, errmsg) ;

							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 8';
							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,8,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 8';

							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 9
					IF y.cci_seg31_num8 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num8, y.cci_seg31_typ8, y.cci_seg31_stat8, acctid, errmsg) ;

							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 9';
							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,9,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 9';

							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					--for attached account number 10
					IF y.cci_seg31_num9 IS NOT NULL THEN
						lp_acct_part(cust, addrcode, y.cci_fiid , y.cci_pan_code, y.cci_fiid, y.cci_seg31_num9, y.cci_seg31_typ9, y.cci_seg31_stat9, acctid, errmsg) ;

							IF errmsg != 'OK' THEN
							errmsg := 'From lp_acct_part '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 10';
							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
						lp_insert_into_cms_pan_acct(cust,acctid,10,y.cci_pan_code,y.cci_mbr_numb,lupduser,errmsg);
							IF errmsg != 'OK' THEN
							errmsg := 'From lp_insert_into_cms_pan_acct '||errmsg ||' for branch '|| y.cci_fiid||' , pan '|| y.cci_pan_code||' and account count 10';

							sp_auton(y.cci_fiid,y.cci_pan_code	,errmsg);
							END IF;
					END IF;
					END IF;--ok if

			END LOOP;--end loop 2 for cursor 2

	EXCEPTION	--excp 1
	WHEN OTHERS THEN
	errmsg := 'Excp 1 -- '||SQLERRM;
	END;		--end begin 1

EXCEPTION	--excp main
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END;		--end main
/


