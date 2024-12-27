CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Entry_Checklist
(	instcode IN NUMBER,
	lupduser IN NUMBER,
	errmsg OUT VARCHAR2)
AS
	PROCEDURE lp_create_branches
	IS
	err VARCHAR2(500);
	dum NUMBER(1);
	CURSOR c1 IS
	SELECT	DISTINCT cci_fiid  cbm_bran_code
	FROM	CMS_CAF_INFO_ENTRY
	--where	cci_approved = 'Y' --Commented By christopher on 1sep04
	WHERE	cci_approved = 'A'
	AND	cci_fiid NOT IN (SELECT cbm_bran_code FROM CMS_BRAN_MAST);
	BEGIN
		FOR x IN c1
		LOOP
			BEGIN
				SELECT	1
				INTO dum
				FROM	CMS_BRAN_MAST
				WHERE	cbm_bran_code = x.cbm_bran_code;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				Sp_Create_Branch(instcode,1,1,1,x.cbm_bran_code,x.cbm_bran_code,NULL,'BKC','BKC',NULL,NULL,'400001','6537694',NULL,NULL,'DHARMESH JOSHI' , NULL ,'joshid@icicibank.com','','','',0,0 ,'','','','','','',lupduser,err);
			END;
		END LOOP;
	END;
	PROCEDURE lp_create_countries
	IS
	err VARCHAR2(500);
	cntrycode NUMBER(3);
	CURSOR c1 IS
	SELECT DISTINCT cci_seg12_country_code
	FROM	CMS_CAF_INFO_ENTRY
--	where	cci_approved ='Y'
	WHERE	cci_approved ='A' --Commented by christopher on 1sep04
	AND	cci_seg12_country_code NOT IN(SELECT gcm_curr_code FROM GEN_CURR_MAST);
	BEGIN
		FOR x IN c1
		LOOP
		SELECT MAX(gcm_cntry_code)+1
		INTO cntrycode
		FROM GEN_CNTRY_MAST;
		INSERT INTO GEN_CURR_MAST(GCM_CURR_CODE ,
					GCM_CURR_NAME  ,
					GCM_CURR_DESC  ,
					GCM_LUPD_USER  )
				VALUES(	x.cci_seg12_country_code,
					x.cci_seg12_country_code||' - DFLT',
					'DEFAULT DESC',
					lupduser);
		INSERT INTO GEN_CNTRY_MAST(GCM_CNTRY_CODE,
					GCM_CURR_CODE  ,
					GCM_CNTRY_NAME,
					GCM_LUPD_USER  )
				VALUES(cntrycode,
					x.cci_seg12_country_code,
					x.cci_seg12_country_code||' - DFLT',
					lupduser);
		END LOOP;
	END;
	PROCEDURE lp_create_custcatgs
	IS
	errmsg VARCHAR2(500);
	catgoutcode NUMBER(5);
	CURSOR c1 IS
	SELECT	DISTINCT trim(cci_seg12_branch_num) catg FROM CMS_CAF_INFO_ENTRY
--	where	cci_approved	= 'Y' --commented by christopher on 1sep04
	WHERE	cci_approved	= 'A'
	MINUS
	SELECT ccc_catg_sname FROM CMS_CUST_CATG;
	BEGIN
--	dbms_output.enable(100000);
	FOR x IN c1
	LOOP
		Sp_Create_Custcatg(instcode, x.catg, 'CREATED DURING UPLOAD', lupduser,catgoutcode, errmsg);
--		dbms_output.put_line('Error = '||errmsg);
	END LOOP;
	END;
BEGIN	--main begin
errmsg := 'OK';
lp_create_branches;
lp_create_countries;
lp_create_custcatgs;
UPDATE CMS_CAF_INFO_ENTRY
SET cci_inst_code = 1
--where cci_approved = 'Y'; --commneted by christopher on 1sep04
WHERE cci_approved = 'A';
UPDATE CMS_CAF_INFO_ENTRY
SET cci_pan_code = trim(cci_pan_code)
--where cci_approved = 'Y';
WHERE cci_approved = 'A';
UPDATE CMS_CAF_INFO_ENTRY
SET cci_seg12_branch_num = trim(cci_seg12_branch_num)
--where cci_approved = 'Y';
WHERE cci_approved = 'A';
UPDATE CMS_CAF_INFO_ENTRY
-- SET cci_seg12_postal_code = RPAD(NVL(cci_seg12_postal_code,' '),9,' '),
SET cci_seg12_postal_code = RPAD(NVL(cci_seg12_postal_code,' '),15,' '), -- jimmy 4th Oct 2005 to take care of 15 char postal code thru single page
    cci_seg12_addr_line1  = RPAD(NVL(cci_seg12_addr_line1,' '),30,' ')
--where cci_approved = 'Y';
WHERE cci_approved = 'A';
EXCEPTION	--main excp
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||SQLERRM;
END;	--main end
/
SHOW ERRORS

