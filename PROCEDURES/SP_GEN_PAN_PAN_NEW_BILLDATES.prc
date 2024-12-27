CREATE OR REPLACE PROCEDURE VMSCMS.SP_GEN_PAN_PAN_NEW_BILLDATES     (	pancode		IN	VARCHAR2	,
  											mbrnumb		IN	VARCHAR2	,
  											lupduser		IN	NUMBER	,
  											newdisp		IN	VARCHAR2	,
											newprodcode IN VARCHAR2		,-- shyamjith 05 jan 05 .. added new prodcode and new prodcat as parameters
											newprodcat IN VARCHAR2		,
  											pan			OUT VARCHAR2	,
  											errmsg 		OUT	 VARCHAR2)
  AS
  pan_bin				NUMBER (6)	;
  pan_branch			VARCHAR2 (6)	;
  pan_srno				VARCHAR2 (10)	;
  pan_chkdig			NUMBER (1)	;
  instcode				NUMBER (3)	;
  assocode				NUMBER (3)	;
  insttype				NUMBER (3)	;
  prodcode				VARCHAR2 (6)	;
  v_cpm_catg_code			VARCHAR2 (2);
  cardtype				NUMBER (5)	;
  custcatg				NUMBER (5)	;
  custcode				NUMBER (10)	;
  dispname				VARCHAR2(50)	;
  applbran				VARCHAR2 (6)	;
  actvdate				DATE			;
  exprydate				DATE			;
  adonstat				CHAR (1)		;
  v_cpa_addon_link		VARCHAR2(	20)	;
  adonlink				VARCHAR2 (20)	;
  acctid				NUMBER(10)	;
  acctno				VARCHAR2(20)	;
  totacct				NUMBER (3)	;
  chnlcode				NUMBER (3)	;
  mbrlink				VARCHAR2(3)	;
  v_mbrnumb			VARCHAR2(3)	;
  limitamt				NUMBER(15,6)	;
  uselimit				NUMBER(2)	;
  billaddr				NUMBER(7)	;

  nextbilldate			DATE		; -- added for the next bill date from old card to the new one...

  v_ccc_catg_sname	CMS_CUST_CATG.ccc_catg_sname%TYPE;
  expry_param		NUMBER(3);
  v_bin_stat CMS_BIN_MAST.cbm_bin_stat%TYPE; -- shyamjith 28 feb 05 - CR 138
  dum NUMBER(1);
  CURSOR c1(pan_code IN VARCHAR2) IS
  SELECT	cpa_acct_id,cpa_acct_posn
  FROM	CMS_PAN_ACCT
  WHERE	cpa_pan_code = pan_code ;
  --and cpa_mbr_numb = v_mbrnumb and
  --cpa_inst_code = 1;
  ---************************************************************************
  --	Local procedure to find out the BIN
  ---************************************************************************
  PROCEDURE	lp_pan_bin		(l_instcode IN NUMBER,  l_insttype IN NUMBER,l_prod_code IN VARCHAR2,  l_pan_bin OUT NUMBER, l_errmsg OUT VARCHAR2 )
  IS
  BEGIN
  	--dbms_output.put_line('chkpt2-->In local procedure lp_pan_bin');
  		/*SELECT  cip_inst_prfx
  		INTO	l_pan_bin
                  FROM	cms_inst_prfx
                  WHERE	cip_inst_code = l_instcode
  		AND		cip_prod_code = l_prod_code;*/
  		SELECT	cpb_inst_bin
  		INTO	l_pan_bin
  		FROM	CMS_PROD_BIN
  		WHERE	cpb_inst_code	=	l_instcode
  		AND	cpb_prod_code	=	l_prod_code
  		AND	cpb_active_bin	=	'Y';--added on 03-09-02
  		l_errmsg := 'OK';
  EXCEPTION
  		WHEN NO_DATA_FOUND THEN
  			l_errmsg := 'Excp1 LP1 -- No prefix  found for combination of Institution '||l_instcode||' and product '||l_prod_code ;
  		WHEN OTHERS THEN
  			l_errmsg := 'Excp1 LP1 -- '||SQLERRM;
  END;
  ---************************************************************************
  ---########################################################################
  --	Local procedure to find out the running serial number
  ---########################################################################
  PROCEDURE	lp_pan_srno		(l_instcode IN NUMBER, l_prodcode IN VARCHAR2, l_bin
   IN NUMBER, l_brancode IN VARCHAR2, l_custcatg IN NUMBER,
   l_lupduser IN NUMBER, l_srno OUT VARCHAR2, l_errmsg OUT VARCHAR2)
  IS
  BEGIN
  l_errmsg := 'OK';
  	SELECT	ccc_catg_sname
  	INTO	v_ccc_catg_sname
  	FROM	CMS_CUST_CATG
  	WHERE	ccc_inst_code		=	l_instcode
  	AND	ccc_catg_code	=	l_custcatg;
  	--Added by Christopher on 23jan04 for new bin 466731
  --IF substr(trim(v_ccc_catg_sname), 1, 3) = 'HNI'  AND pan_bin = '466706'  THEN	--and condition added specific for 466706 bin on 26-06-02
  --Ashwini CR 124  - 4 Feb 2005
  	--IF substr(trim(v_ccc_catg_sname), 1, 3) = 'HNI'  AND (pan_bin = '466706' OR pan_bin = '466731' OR pan_bin = '466730') THEN	--and condition added specific for 466706 bin on 26-06-02
--shyamjith 17 May 05 - cr 97 - for HNI custmers 421395 should be picked up if bin is 466706  and 466730 ---start
	IF SUBSTR(trim(v_ccc_catg_sname), 1, 3) = 'HNI' AND (pan_bin = '466706'  OR  pan_bin = '466730') THEN
	   pan_bin := '421395';
	END IF;
--shyamjith 17 May 05 - cr 97 - for HNI custmers 421395 should be picked up if bin is 466706  and 466730 ---end

   IF SUBSTR(trim(v_ccc_catg_sname), 1, 3) = 'HNI'  AND (pan_bin = '466706' OR pan_bin = '466731' OR pan_bin = '466730' OR pan_bin='421395') THEN
  		BEGIN
  		SELECT	'9'||LPAD(cpc_ctrl_numb,4,'0')
  		INTO	l_srno
  		FROM	CMS_PANGEN_CTRL
  		WHERE	cpc_inst_code		= l_instcode
  		--AND	cpc_ctrl_prod		= l_prodcode
  		AND	cpc_ctrl_bin		= l_bin
  		AND	cpc_ctrl_bran		= l_brancode
  		AND	cpc_ctrl_catg		= 'HNI'
  		FOR	UPDATE	;
  		IF TO_NUMBER(l_srno)>99999 THEN
  		l_errmsg := 'Serial number already reached the maximum.';
  		ELSE
  				UPDATE	CMS_PANGEN_CTRL
  				SET	cpc_ctrl_numb		= TO_NUMBER(cpc_ctrl_numb)+1,
  					cpc_lupd_user		= lupduser
  				WHERE	cpc_inst_code		= l_instcode
  				--AND	cpc_ctrl_prod		= l_prodcode
  				AND	cpc_ctrl_bin		= l_bin
  				AND	cpc_ctrl_bran		= l_brancode
  				AND	cpc_ctrl_catg		= 'HNI';
  		END IF;
  		EXCEPTION
  		WHEN NO_DATA_FOUND THEN
  			l_errmsg := 'Excp1 LP2.1-- Control data missing for branch '||l_brancode ||'. for HNI';
  		WHEN OTHERS THEN
  			l_errmsg := 'Excp1 LP2.1 for HNI -- '||SQLERRM;
  		END;
  	ELSIF pan_bin = '504642' AND l_brancode IN ('0024','0035') AND cardtype =  2 THEN --1CH210203
  		BEGIN
  		SELECT	cpc_ctrl_numb--no lpadding needed since we are directly storing the srno starting with 80000
  		INTO	l_srno
  		FROM	CMS_PANGEN_CTRL
  		WHERE	cpc_inst_code		= l_instcode
  		--AND	cpc_ctrl_prod		= l_prodcode
  		AND	cpc_ctrl_bin		= l_bin
  		AND	cpc_ctrl_bran		= l_brancode
  		AND	cpc_ctrl_catg		= 'OCTROI'
  		FOR	UPDATE	;
  		IF TO_NUMBER(l_srno)>89999 THEN
  		l_errmsg := 'Serial number already reached the maximum for Octroi for 0035.';
  		ELSE
  				UPDATE	CMS_PANGEN_CTRL
  				SET	cpc_ctrl_numb		= TO_NUMBER(cpc_ctrl_numb)+1,
  					cpc_lupd_user		= lupduser
  				WHERE	cpc_inst_code		= l_instcode
  				--AND	cpc_ctrl_prod		= l_prodcode
  				AND	cpc_ctrl_bin		= l_bin
  				AND	cpc_ctrl_bran		= l_brancode
  				AND	cpc_ctrl_catg		= 'OCTROI';
  		END IF;
  		EXCEPTION
  		WHEN NO_DATA_FOUND THEN
  		l_errmsg := 'Excp1 LP2.2-- Control data missing for branch '||l_brancode||' for Octroi.';
  		WHEN OTHERS THEN
  		l_errmsg := 'Excp1 LP2.2 for Octroi -- '||SQLERRM;
  		END;
  	ELSE
  		BEGIN
  		SELECT	LPAD(cpc_ctrl_numb,5,'0')
  		INTO	l_srno
  		FROM	CMS_PANGEN_CTRL
  		WHERE	cpc_inst_code		= l_instcode
  		--AND	cpc_ctrl_prod		= l_prodcode
  		AND	cpc_ctrl_bin		= l_bin
  		AND	cpc_ctrl_bran		= l_brancode
  		AND	cpc_ctrl_catg		= 'NORMAL'
  		FOR	UPDATE	;
  		IF l_bin = '504642' AND TO_NUMBER(l_srno) > 79999 THEN--to handle the serial number case...sr nos starting from 9 have already been used.
  			l_errmsg := 'Serial number already reached the maximum for 504642.';
  		ELSIF TO_NUMBER(l_srno)>89999 THEN
  			l_errmsg := 'Serial number already reached the maximum.';
  		ELSE
  				UPDATE	CMS_PANGEN_CTRL
  				SET	cpc_ctrl_numb		= TO_NUMBER(cpc_ctrl_numb)+1,
  					cpc_lupd_user		= lupduser
  				WHERE	cpc_inst_code		= l_instcode
  				--AND	cpc_ctrl_prod		= l_prodcode
  				AND	cpc_ctrl_bin		= l_bin
  				AND	cpc_ctrl_bran		= l_brancode
  				AND	cpc_ctrl_catg		= 'NORMAL';
  		END IF;
  		EXCEPTION
  		WHEN NO_DATA_FOUND THEN
  		l_errmsg := 'Excp1 LP2.2-- Control data missing for branch '||l_brancode||'.';
  		WHEN OTHERS THEN
  		l_errmsg := 'Excp1 LP2.2 -- '||SQLERRM;
  		END;
  	END IF;
  EXCEPTION
  	WHEN OTHERS THEN
  	l_errmsg := 'Excp1 LP2 -- '||SQLERRM;
  END;
  ---########################################################################
  --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  ----	Local procedure to find out the check digit
  --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  PROCEDURE	lp_pan_chkdig		(l_prfx IN NUMBER, l_brancode IN VARCHAR2, l_srno IN VARCHAR2, l_checkdig OUT NUMBER)
  IS
  ceilable_sum		NUMBER := 0;
  ceiled_sum		NUMBER	;
  temp_pan		NUMBER	;
  len_pan			NUMBER (3);
  res				NUMBER (3);
  mult_ind			NUMBER (1);
  dig_sum			NUMBER (2);
  dig_len			NUMBER (1);
  BEGIN
  --dbms_output.put_line('In check digit gen logic');
  	temp_pan	:= l_prfx||l_brancode||l_srno ;
  	len_pan		:= LENGTH(temp_pan);
  	mult_ind		:= 2;
  	FOR i IN REVERSE 1..len_pan
  	LOOP
  		res			:= SUBSTR(temp_pan,i,1)*mult_ind;
  		dig_len		:= LENGTH(	res);
  			IF	dig_len = 2 THEN
  				dig_sum := 	SUBSTR(res,1,1)+SUBSTR(res,2,1) ;
  			ELSE
  				dig_sum := res;
  			END IF;
  			ceilable_sum := ceilable_sum+dig_sum;
  				IF mult_ind = 2 THEN		--IF 2
  					mult_ind := 1;
  				ELSE	--Else of If 2
  					mult_ind := 2;
  				END IF;	--End of IF 2
  	END LOOP;
  		ceiled_sum := ceilable_sum;
  		IF MOD(ceilable_sum,10) !=0 THEN
  			LOOP
  				ceiled_sum := ceiled_sum+1;
  				EXIT WHEN MOD(ceiled_sum,10) = 0;
  			END LOOP;
  		END IF;
  		l_checkdig   :=  ceiled_sum-ceilable_sum;
  		--dbms_output.put_line('FROM LOCAL CHK GEN---->'||l_checkdig);
  END;
  --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  BEGIN		--Main Begin Block Starts Here
  IF	mbrnumb IS NULL  THEN
  	v_mbrnumb := '000';
  END IF;
  	BEGIN		--Begin 1 Block Starts Here
  		SELECT cap_inst_code, cap_asso_code, cap_inst_type, cap_prod_code, cap_appl_bran, cap_cust_code, cap_card_type, cap_cust_catg, cap_disp_name,cap_appl_bran,cap_active_date ,cap_expry_date ,cap_addon_stat, cap_tot_acct, cap_chnl_code,
  		cap_limit_amt, cap_use_limit, cap_bill_addr, cap_next_bill_date
		-- added cap_next_bill_date above 2 carry fwd the bill date of the old card to the new one..jimmy 20th June 2005
		--
  		INTO	instcode, assocode, insttype, prodcode, pan_branch, custcode, cardtype, custcatg, dispname,applbran,actvdate,exprydate,adonstat,totacct, chnlcode, limitamt, uselimit, billaddr, nextbilldate
  		FROM	CMS_APPL_PAN
  		WHERE	cap_pan_code	=	pancode
  		AND		cap_mbr_numb	= 	v_mbrnumb;
  		actvdate := SYSDATE;	--added on 11/10/2002 ...to set the active date as sysdate for the newly gen pan
  		IF newdisp IS NOT NULL THEN
  		dispname := newdisp;
  		END IF;

		--shyamjith 05 jan 05 .. if bin is changed--start
		IF newprodcode IS NOT NULL AND newprodcat IS NOT NULL THEN
		BEGIN
		IF prodcode != newprodcode OR cardtype!= newprodcat THEN
		BEGIN
			 BEGIN
			 SELECT	1 INTO	dum	FROM	CMS_PROD_CCC
--				select cpc_prodccc_code into prodccc_code from cms_prod_ccc
				WHERE cpc_prod_code = newprodcode
				AND cpc_card_type = newprodcat
				AND cpc_cust_catg = custcatg;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				BEGIN
				sp_create_prodccc(instcode,custcatg,NULL,newprodcat,newprodcode,lupduser,errmsg);
				IF errmsg != 'OK' THEN
				errmsg := 'Problem while attaching prod_cat_cust_catg for pan ';
				ROLLBACK;
				END IF;
				END;
				--errmsg := 'No Record found for Product ' || newprodcode || ' Product Catg '|| newprodcat || ' Cust Catg '|| custcatg;
				WHEN TOO_MANY_ROWS THEN
				errmsg := 'Duplicate Records found for Product ' || newprodcode || ' Prod Catg '|| newprodcat || 'Cust Catg '|| custcatg;
				WHEN OTHERS THEN
				errmsg := 'Exception from Product_CCC';
			END;

		--	IF errmsg = 'OK' THEN
			--		Begin
						prodcode := newprodcode;
						cardtype := newprodcat;
						--next_bill_date := null;         -- add_months(sysdate+12)
						--If product is same as of reissued cards then fees shud not charged
					--	v_fee_calc  := 'N' ;
						limitamt := 0;
						uselimit := 0;
				--	End;
		--	ELSE
			--		  errmsg := 'While Resetting Limits :'||errmsg ;
			--END IF ;

		END;
		END IF;
		END;
		END IF;


		--shyamjith ...... end

  		SELECT	cip_param_value
  		INTO	expry_param
  		FROM	CMS_INST_PARAM
  		WHERE	cip_inst_code = instcode
  		AND	cip_param_key = 'CARD EXPRY';
  		--exprydate := add_months(sysdate,expry_param);
      exprydate := ADD_MONTHS(SYSDATE,expry_param-1); -- Ashwini -25 Jan 05-- Expry date is last day of the prev month after adding expry param
  --dbms_output.put_line('chkpt1');
  			lp_pan_bin(instcode, insttype, prodcode,pan_bin, errmsg)	;
  --dbms_output.put_line('chkpt3-->'||errmsg);
  	EXCEPTION	--Exception of Begin 1 Block
  		WHEN NO_DATA_FOUND THEN
  		errmsg := 'No information found for '||pancode ;
  		WHEN OTHERS THEN
  		errmsg := 'Excp1 -- '||SQLERRM;
  	END;		--Begin 1 Block Ends Here
  	IF errmsg = 'OK' THEN
  		BEGIN		--Begin 1.2 starts
  		SELECT 	cpm_catg_code
  		INTO	v_cpm_catg_code
  		FROM	CMS_PROD_MAST
  		WHERE	cpm_inst_code	=	instcode
  		AND		cpm_prod_code	=	prodcode;
  		EXCEPTION	--Excp 1.2 starts
  		WHEN NO_DATA_FOUND THEN
  		errmsg := 'No Product category found for product '||prodcode||'.';
  		WHEN OTHERS THEN
  		errmsg := 'Excp1.2 -- '||SQLERRM;
  		END;		--Begin 1.2 ends
  	END IF;
  		IF errmsg  = 'OK' THEN
  			BEGIN		--Begin 2 Block Starts Here
  				lp_pan_srno(instcode,prodcode,pan_bin,pan_branch,custcatg,lupduser,pan_srno,errmsg);
  				--dbms_output.put_line('chk1-------------->'||errmsg);
  				--dbms_output.put_line('PAN serial num generated======>>>'||pan_srno);
  			EXCEPTION	--Exception of Begin 2 Block
  				WHEN OTHERS THEN
  				errmsg := 'Excp2 -- '||SQLERRM;
  			END;		--Begin 2 Block Ends Here
  		END IF;
  		IF errmsg = 'OK' THEN
  			BEGIN			--Begin 3 Block Starts Here
  			--	dbms_output.put_line('Input to check digit logic'||pan_bin||','||pan_branch||','||pan_srno);
  				lp_pan_chkdig(pan_bin,pan_branch,pan_srno,pan_chkdig);
  				--dbms_output.put_line('Check digit gen------->'||pan_chkdig);
  			EXCEPTION		--Exception of Begin 3 Block
  				WHEN OTHERS THEN
  				errmsg := 'Excp 3 -- '||SQLERRM;
  			END;			--Begin 3 Block Ends Here
  		END IF;
  	--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
  	/* pan := pan_bin||lpad(pan_branch,6,0)||pan_srno||pan_chkdig ;*/
  	/*--*/	 pan := pan_bin||pan_branch||pan_srno||pan_chkdig ; /*--*/
  	--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
  		IF errmsg = 'OK' THEN
  			BEGIN --begin 5
  			SELECT cam_acct_id,cam_acct_no
  			INTO	acctid,acctno
  			FROM	CMS_ACCT_MAST
  			WHERE	cam_inst_code = 1
  			AND	cam_acct_id = (	SELECT cpa_acct_id
  							FROM	CMS_PAN_ACCT
  							WHERE	cpa_pan_code	=	pancode
  							AND	cpa_mbr_numb	=	v_mbrnumb
                                                          AND     cpa_inst_code = 1
  							AND	cpa_acct_posn	=	1)	;
  			EXCEPTION--excp of begin 5
  			WHEN OTHERS THEN
  			errmsg := 'Excp 5 -- '||SQLERRM;
  			END;--begin 5 ends
  		END IF;
  --Now the pan is generated ...It has to be inserted into table cms_appl_pan and table cms_pan_acct and the table cms_appl_mast
  --dbms_output.put_line('chk2-------------->'||errmsg);
  		IF adonstat = 'A' THEN
  			BEGIN		--begin 1.1
  			SELECT cap_addon_link
  			INTO	v_cpa_addon_link
  			FROM	CMS_APPL_PAN
  			WHERE	cap_pan_code = pancode;
  			SELECT cap_pan_code,cap_mbr_numb
  			INTO	adonlink,mbrlink
  			FROM	CMS_APPL_PAN
  			WHERE	cap_pan_code = v_cpa_addon_link;
  			EXCEPTION	--excp 1.1
  			WHEN NO_DATA_FOUND THEN
  			errmsg := 'Parent PAN not generated for pan'||pancode;
  			WHEN OTHERS THEN
  			errmsg := 'Excp1.1 -- '||SQLERRM;
  			END;		--end of begin 1.1
  		ELSIF adonstat = 'P' THEN
  			adonlink	:=	pan;
  			mbrlink	:=	'000';
  		END IF;

		--shyamjith - 28 Feb 05 CR 138
		IF errmsg = 'OK' THEN
  			BEGIN --begin 5
			SELECT cbm_bin_stat INTO v_bin_stat
			FROM CMS_BIN_MAST
			WHERE
			cbm_inst_bin = pan_bin;
  			EXCEPTION--excp of begin 5
  			WHEN OTHERS THEN
  			errmsg := 'Excp 8 -- '||SQLERRM;
  			END;--begin 5 ends
  		END IF;
		--shyamjith - 28 Feb 05 Cr 138

  IF errmsg = 'OK' THEN
  				BEGIN	--Begin 4 starts
  				INSERT INTO CMS_APPL_PAN(	CAP_INST_CODE		,
  											CAP_ASSO_CODE	,
  											CAP_INST_TYPE		,
  											CAP_PROD_CODE	,
  											CAP_PROD_CATG	,
  											CAP_CARD_TYPE         ,
  											CAP_CUST_CATG		,
  											CAP_PAN_CODE		,
  											CAP_MBR_NUMB          ,
  											CAP_CARD_STAT		,
  											CAP_CUST_CODE       ,
  											CAP_DISP_NAME          ,
  											CAP_LIMIT_AMT		,
  											CAP_USE_LIMIT		,
  											CAP_APPL_BRAN         ,
  											CAP_ACTIVE_DATE      ,
  											CAP_EXPRY_DATE	,
  											CAP_ADDON_STAT	,
  											CAP_ADDON_LINK	,
  											CAP_MBR_LINK		,
  											CAP_ACCT_ID		,
  											CAP_ACCT_NO		,
  											CAP_TOT_ACCT		,
  											CAP_BILL_ADDR		,
  											CAP_CHNL_CODE	,
  											CAP_PANGEN_DATE	,
  											CAP_PANGEN_USER	,
  											CAP_CAFGEN_FLAG        ,
  											CAP_PIN_FLAG		,
  											CAP_EMBOS_FLAG	,
  											CAP_PHY_EMBOS             ,
  											CAP_JOIN_FEECALC	,
  											CAP_NEXT_BILL_DATE	,----added on 11/10/2002
  											CAP_INS_USER		,
  											CAP_LUPD_USER		,
  											CAP_PBFGEN_FLAG  )--,
                                 --, 		-- ADDED BY AJIT 7 OCT 03
--                                 CAP_APPL_CODE ) -- Ashwini 24 JAN 2005
                                 -- appl_code value put as '88888888888888'
                                 -- it was going as 'null' during reissue
                                 -- so Index was not being used
  									VALUES(	instcode		,
  											assocode	,
  											insttype		,
  											prodcode		,
  											v_cpm_catg_code,
  											cardtype		,
  											custcatg		,
  											pan			,
  											'000'			,
  											v_bin_stat			,--shyamjith 28 feb 05 - Cr 138
  											custcode		,
  											dispname	,
  											limitamt		,
  											uselimit		,
  											applbran		,
  											actvdate		,
  											exprydate		,
  											adonstat		,
  											adonlink		,
  											mbrlink		,
  											acctid		,
  											acctno		,
  											totacct		,
  											billaddr		,
  											chnlcode		,
  											SYSDATE		,
  											lupduser		,
  											'N'			,
  											'N'			,
  											'N'			,
  											'N'			,
  											'N'			,
  											ADD_MONTHS(SYSDATE,12),--added on 11/10/2002... gotto confirm this -- jimmy
											  -- the date is set as that of 12 months after the regen date because the billing cycle for re issued pans will start from next yr
  											  --this is because regen is done for reissued i.e. for hotlisted cards
  											lupduser		,
  											lupduser		,
  											'R' );--,
                                 --, 		-- Ajit 7 oct 2003
--                                 '88888888888888' ); -- Ashwini 24 JAN 2005
                                 -- appl_code value put as '88888888888888'
                                 -- it was going as 'null' during reissue
                                 -- so Index was not being used
  				/*UPDATE cms_appl_mast
  				SET		cam_appl_stat = 'P',
  						cam_lupd_user = lupduser
  				WHERE	cam_appl_code = applcode;*/
  				errmsg := 'OK';
  				EXCEPTION	--Exception of Begin 4
  				WHEN OTHERS THEN
  					errmsg := 'Excp 4 -- '||SQLERRM;
  				END;	--End of Begin 4
  END IF;
  	IF errmsg = 'OK' THEN	--
  		FOR x IN c1(pancode)
  		LOOP
  			INSERT INTO CMS_PAN_ACCT(		CPA_INST_CODE		,
  											CPA_CUST_CODE	,
  											CPA_ACCT_ID		,
  											CPA_ACCT_POSN	,
  											CPA_PAN_CODE		,
  											CPA_MBR_NUMB		,
  											CPA_INS_USER		,
  											CPA_LUPD_USER  )
  									VALUES(	instcode		,
  											custcode		,
  											x.cpa_acct_id	,
  											x.cpa_acct_posn,
  											pan			,
  											'000'			,
  											lupduser		,
  											lupduser);
  		EXIT WHEN c1%NOTFOUND;
  		END LOOP;
  		errmsg := 'OK';
  	END IF;
  EXCEPTION	--Main Block Exception
  	WHEN OTHERS THEN
  	errmsg := 'Main Excp -- '||SQLERRM;
  END;		--Main Begin Block Ends Here
/


