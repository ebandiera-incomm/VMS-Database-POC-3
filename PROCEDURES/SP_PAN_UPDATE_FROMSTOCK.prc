CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Pan_Update_Fromstock     (	pancode		IN	VARCHAR2	,
  											mbrnumb		IN	VARCHAR2	,
  											lupduser		IN	NUMBER	,
  											newdisp		IN	VARCHAR2	,
											newprodcode IN VARCHAR2		,-- shyamjith 05 jan 05 .. added new prodcode and new prodcat as parameters
											newprodcat IN VARCHAR2		,
  											newpan			IN VARCHAR2	,
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
  billaddr				NUMBER(10)	;
  billdate				DATE; -- billing date to be carried forward to the re-issued card -- jimmy 2/7/05
  v_ccc_catg_sname	CMS_CUST_CATG.ccc_catg_sname%TYPE;
  expry_param		NUMBER(3);
  v_card_type NUMBER (5)	; --**
  dum NUMBER(1);
  v_hsm_mode		VARCHAR2(1);--Rahul 28 Sep 05
  v_pingen_flag		VARCHAR2(1);--Rahul 28 Sep 05
  v_emboss_flag		VARCHAR2(1);--Rahul 28 Sep 05
  --v_cap_last_mb_date DATE; commented by tejas bcs CR103B not on prod 3feb06-- Ashwini 8 Oct 05 CR-103B MoneyBack
  v_pin_flag CMS_APPL_PAN.CAP_PIN_FLAG%TYPE;
  v_embos_flag CMS_APPL_PAN.CAP_EMBOS_FLAG%TYPE;
  v_cafgen_flag CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  --atm and pos limits
  v_CAP_ATM_OFFLINE_LIMIT  CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  v_CAP_ATM_ONLINE_LIMIT   CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  v_CAP_POS_OFFLINE_LIMIT  CMS_APPL_PAN.CAP_POS_OFFLINE_LIMIT%TYPE;
  v_CAP_POS_ONLINE_LIMIT   CMS_APPL_PAN.CAP_POS_ONLINE_LIMIT%TYPE;
  v_CAP_ONLINE_AGGR_LIMIT  CMS_APPL_PAN.CAP_ONLINE_AGGR_LIMIT%TYPE;
  v_CAP_OFFLINE_AGGR_LIMIT CMS_APPL_PAN.CAP_OFFLINE_AGGR_LIMIT%TYPE;
 CURSOR c1(pan_code IN VARCHAR2) IS
 SELECT	cpa_acct_id,cpa_acct_posn
 FROM	CMS_PAN_ACCT
 WHERE	cpa_pan_code = pan_code 
 AND cpa_mbr_numb = mbrnumb AND
 cpa_inst_code = 1
 ORDER BY cpa_acct_posn;
  --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  BEGIN		--Main Begin Block Starts Here
   errmsg:='OK';
-- Rahul 28 Sep 05
	-- Jimmy to Check about emboss Flag..
/* The caf has already been generated for the stock card so pin and emboss flags need not be set here....   
	BEGIN
		SELECT CIP_PARAM_VALUE
		INTO v_hsm_mode
		FROM CMS_INST_PARAM
		WHERE cip_param_key='HSM_MODE';
		IF v_hsm_mode='Y' THEN
		   v_pingen_flag:='Y'; -- i.e. generate pin
		   v_emboss_flag:='Y'; -- i.e. generate embossa file.
		ELSE
		   v_pingen_flag:='N'; -- i.e. don't generate pin
		   v_emboss_flag:='N'; -- i.e. don't generate embossa file.
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		   v_hsm_mode:='N';
		   v_pingen_flag:='N'; -- i.e. don't generate pin
 	   	   v_emboss_flag:='N'; -- i.e. don't generate embossa file.
	END;
 */
 IF	mbrnumb IS NULL  THEN
  		errmsg := ' MEMBER NUMBER CANNOT BE NULL';
ELSE
		v_mbrnumb :=mbrnumb;
 END IF;
-- Get all details of the old card first....
     BEGIN		--Begin 1 Block Starts Here
-- product code, card type and expiry date will be maintained for the new 'bulk issue' card....
  DBMS_OUTPUT.PUT_LINE('Before selecting data from cms_appl_pan==pancode='||pancode);
  		SELECT cap_inst_code, cap_asso_code, cap_inst_type, cap_appl_bran, cap_cust_code, cap_cust_catg, cap_disp_name,cap_appl_bran,cap_active_date ,cap_addon_stat, cap_tot_acct, cap_chnl_code, -- cap_card_type,cap_prod_code,cap_expry_date ,  
  		cap_limit_amt, cap_use_limit, cap_bill_addr, cap_next_bill_date, --cap_last_mb_date,Commented by tejas bcs cr103B in not on prod --5 Nov 05 - Ashwini 8 Oct 05 CR-103B MoneyBack
  		CAP_ATM_OFFLINE_LIMIT ,	CAP_ATM_ONLINE_LIMIT,CAP_POS_OFFLINE_LIMIT,CAP_POS_ONLINE_LIMIT, CAP_ONLINE_AGGR_LIMIT,CAP_OFFLINE_AGGR_LIMIT
		INTO	instcode , assocode, insttype, pan_branch, custcode, custcatg, dispname,applbran,actvdate,adonstat,totacct, chnlcode, limitamt, uselimit, billaddr, billdate, --prodcode, cardtype,exprydate 
		--v_cap_last_mb_date ,commented by tejas bcs CR103B not on prod 3feb06 --5 Nov 05 --Ashwini 8 Oct 05 CR-103 MoneyBack
  		v_CAP_ATM_OFFLINE_LIMIT , v_CAP_ATM_ONLINE_LIMIT , v_CAP_POS_OFFLINE_LIMIT ,v_CAP_POS_ONLINE_LIMIT ,
		v_CAP_ONLINE_AGGR_LIMIT , v_CAP_OFFLINE_AGGR_LIMIT
		FROM	CMS_APPL_PAN
  		WHERE	cap_pan_code	=	pancode
  		AND		cap_mbr_numb	= 	v_mbrnumb;
  		actvdate := SYSDATE;	--added on 11/10/2002 ...to set the active date as sysdate for the newly gen pan
-- select the pin, emboss and caf gen flag of the new card to see if they have been generated or not...if not then throw error...if not do NOT go ahead
--pin flag = N 
--embos flag = N 
--cafgen flag = Y 
-- if not then make entry into the error table and mention the error in that table....  	
   	  BEGIN -- #3 
   	   SELECT CAP_PIN_FLAG, CAP_EMBOS_FLAG, CAP_CAFGEN_FLAG 
	   INTO	v_pin_flag, v_embos_flag,v_cafgen_flag
	   FROM CMS_APPL_PAN
	   WHERE CAP_PAN_CODE=newpan
	   AND CAP_MBR_NUMB= v_mbrnumb;
	   EXCEPTION -- #3 
	   				WHEN NO_DATA_FOUND THEN
					errmsg := 'EMBOSS AND PIN AND CAF NOT GENERATED FOR NEW PAN'||newpan;
  		END; -- #3 
		--dbms_output.put_line('chk1-------------->'||errmsg);
  DBMS_OUTPUT.PUT_LINE('Caf gen flag is first : '|| v_cafgen_flag);		
  DBMS_OUTPUT.PUT_LINE('After selecting data from cms_appl_pan');
		IF errmsg = 'OK' THEN 
  DBMS_OUTPUT.PUT_LINE('Caf gen flag is now : '|| v_cafgen_flag);
/*
		   		 IF  (v_embos_flag='Y') THEN  
					 errmsg:='Embos Not Generated For The Pan'||newpan;
				 ELSIF  (v_pin_flag='Y') THEN
					 errmsg:='Pin Not Generated For The Pan'||newpan;
				 ELSIF
*/				 
				  IF (v_cafgen_flag='N') THEN
					 errmsg:='Caf  Not Generated For The Pan '||newpan;
				 ELSE
					 errmsg:='OK';
				 END IF;
		END IF;
  DBMS_OUTPUT.PUT_LINE('dispname: '||dispname);
		--errmsg:='OK';----- to be removed immediately .. only for testing on 261205 
		--dbms_output.put_line('chk2-------------->'||errmsg);		
		IF newdisp IS NOT NULL THEN
  		dispname := newdisp;
  DBMS_OUTPUT.PUT_LINE('newdisp: '||newdisp);		
  		END IF;
--sandip 12jan05 customer category if not in prod_ccc add one--
  	v_card_type:= TO_NUMBER(newprodcat);
	IF errmsg = 'OK' THEN
	IF newprodcode IS NOT NULL AND v_card_type IS NOT NULL THEN
		--BEGIN
			 BEGIN
			 SELECT	1 INTO dum FROM	CMS_PROD_CCC
				WHERE cpc_prod_code = newprodcode
				AND cpc_card_type = v_card_type
				AND cpc_cust_catg = custcatg;
				IF dum != 1 THEN
				Sp_Create_Prodccc(instcode,custcatg,v_card_type,newprodcode,null,null,newprodcode||'_'||v_card_type||'_'||custcatg,lupduser,errmsg);
				IF errmsg != 'OK' THEN
				errmsg := 'Problem while attaching prod_cat_cust_catg for pan ';
			-- SN Shekar Jan.12.2006, error hadler to stop process on exception.
    			ROLLBACK;
         		RETURN;
			-- EN Shekar Jan.12.2006, error hadler to stop process on exception.				
				END IF;
				END IF;
			EXCEPTION
			    WHEN NO_DATA_FOUND THEN
				BEGIN -- [B4] 
				--Sp_Create_Prodccc(instcode,custcatg,NULL,v_card_type,newprodcode,lupduser,errmsg);
				Sp_Create_Prodccc(instcode,custcatg,v_card_type,newprodcode,null,null,newprodcode||'_'||v_card_type||'_'||custcatg,lupduser,errmsg);
				IF errmsg != 'OK' THEN
				errmsg := 'Problem while attaching prod_cat_cust_catg for pan ';
			-- SN Shekar Jan.12.2006, error hadler to stop process on exception.
    			ROLLBACK;
         		RETURN;
			-- EN Shekar Jan.12.2006, error hadler to stop process on exception.				
--				ROLLBACK;
				END IF;
				END; -- [E4]
				WHEN TOO_MANY_ROWS THEN
				errmsg := 'Duplicate Records found for Product ' || newprodcode || ' Prod Catg '|| v_card_type || 'Cust Catg '|| custcatg;
				WHEN OTHERS THEN
				errmsg := 'Exception while attaching Customer Category ';
			END;
		--END;
	END IF;
	END IF;		
--sandip 12jan05 customer category if not in prod_ccc add one--		
/* *
		--shyamjith 05 jan 05 .. if bin is changed--start
		v_card_type:= TO_NUMBER(newprodcat);
		IF newprodcode IS NOT NULL AND v_card_type IS NOT NULL THEN  -- ****  if
		BEGIN  -- [B1]
		IF prodcode != newprodcode OR cardtype!= v_card_type THEN
		BEGIN  -- [B2] 
			 BEGIN  -- [B3] 
			 SELECT	1 INTO dum FROM	CMS_PROD_CCC
--				select cpc_prodccc_code into prodccc_code from cms_prod_ccc
				WHERE cpc_prod_code = newprodcode
				AND cpc_card_type = v_card_type
				AND cpc_cust_catg = custcatg;
				IF dum != 1 THEN
				Sp_Create_Prodccc(instcode,custcatg,NULL,v_card_type,newprodcode,lupduser,errmsg);
				IF errmsg != 'OK' THEN
				errmsg := 'Problem while attaching prod_cat_cust_catg for pan ';
--				ROLLBACK;
				END IF;
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				BEGIN -- [B4] 
				Sp_Create_Prodccc(instcode,custcatg,NULL,v_card_type,newprodcode,lupduser,errmsg);
				IF errmsg != 'OK' THEN
				errmsg := 'Problem while attaching prod_cat_cust_catg for pan ';
--				ROLLBACK;
				END IF;
				END; -- [E4] 
				--errmsg := 'No Record found for Product ' || newprodcode || ' Product Catg '|| newprodcat || ' Cust Catg '|| custcatg;
				WHEN TOO_MANY_ROWS THEN
				errmsg := 'Duplicate Records found for Product ' || newprodcode || ' Prod Catg '|| v_card_type || 'Cust Catg '|| custcatg;
				WHEN OTHERS THEN
				errmsg := 'Exception from Product_CCC';
			END;-- [E3]
						prodcode := newprodcode;
						cardtype := v_card_type;
						--next_bill_date := null;         -- add_months(sysdate+12)
						--If product is same as of reissued cards then fees shud not charged
					--	v_fee_calc  := 'N' ;
						limitamt := 0;
						uselimit := 0;
		END; -- [E2]
		END IF;  
		END; -- [E1] /
		--dbms_output.put_line('chk2.5-------------->'||errmsg);		
		--shyamjith ...... end
  		SELECT	cip_param_value
  		INTO	expry_param
  		FROM	CMS_INST_PARAM
  		WHERE	cip_inst_code = instcode
  		AND	cip_param_key = 'CARD EXPRY';
  		--exprydate := add_months(sysdate,expry_param);
      exprydate := ADD_MONTHS(SYSDATE,expry_param-1); -- Ashwini -25 Jan 05-- Expry date is last day of the prev month after adding expry param
  			--lp_pan_bin(instcode, insttype, prodcode,pan_bin, errmsg)	;
			pan_bin := SUBSTR(newpan,1,6);
 END IF; **/
 pan_bin := SUBSTR(newpan,1,6);
  	EXCEPTION	--Exception of Begin 1 Block
  		WHEN NO_DATA_FOUND THEN
  		errmsg := 'No information found for '||pancode ;
  		WHEN OTHERS THEN
  		errmsg := 'Excp1 -- '||SQLERRM;		
  	END;		--Begin 1 Block Ends Here
  /*Commented bcs we are not checking the product category Tejas 5 Jan 06. 
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
		errmsg := 'Exceptin while getting Product category for product '||prodcode||'.';
  		--errmsg := 'Excp1.2 -- '||SQLERRM;
  		END;		--Begin 1.2 ends
  	END IF;   */
	--dbms_output.put_line('chk3-------------->'||errmsg);		
  		IF errmsg = 'OK' THEN
		  DBMS_OUTPUT.PUT_LINE('Before selecting data from cms_acct_mast');
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
  			errmsg := 'Excption while fetching Account Details';			
/*			-- SN Shekar 06.Jan.2006, error hadler to stop process on exception. 
			ROLLBACK;
			RETURN;
			-- EN Shekar 06.Jan.2006, error hadler to stop process on exception.
*/						
  			--errmsg := 'Excp 5 -- '||SQLERRM;
  			END;--begin 5 ends
  		END IF;
  --Now the pan is generated ...It has to be inserted into table cms_appl_pan and table cms_pan_acct and the table cms_appl_mast
  		--dbms_output.put_line('chk4-------------->'||errmsg);
-- SET  the STATUS of NEW PAN TO 1. --------------CR162					
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
  			errmsg :='Parent PAN not generated';
			--errmsg := 'Excp1.1 -- '||SQLERRM;
  			END;		--end of begin 1.1
  		ELSIF adonstat = 'P' THEN
  			adonlink	:=	newpan;
  			mbrlink	:=	v_mbrnumb ;
  		END IF;
		--dbms_output.put_line('chk5-------------->'||errmsg);		
		--shyamjith - 28 Feb 05 CR 138
		--Not reqd 1 Feb 2006
	/*	IF errmsg = 'OK' THEN
  			BEGIN --begin 5
			  DBMS_OUTPUT.PUT_LINE('pan bin is -->'|| pan_bin);
			SELECT cbm_bin_stat INTO v_bin_stat
			FROM CMS_BIN_MAST
			WHERE
			cbm_inst_bin = pan_bin;
  			EXCEPTION--excp of begin 5
  			WHEN OTHERS THEN
  			errmsg:='BIN STAT NOT FOUND';
			--errmsg := 'Excp 8 -- '||SQLERRM;
  			END;--begin 5 ends
  		END IF;*/
		--shyamjith - 28 Feb 05 Cr 138
  IF errmsg = 'OK' THEN
  				BEGIN	--Begin 4 starts
				  DBMS_OUTPUT.PUT_LINE('Before updating data into  cms_appl_pan for pan: '|| newpan);
				-- This has to be an update statement instead of insert
				-- because the new card is already present in appl_pan .....
				UPDATE  CMS_APPL_PAN SET 
--					CAP_INST_CODE =	  instcode ,      -- Not reqd 1 Feb 2006
--					CAP_ASSO_CODE =	 assocode ,		  -- Not reqd 1 Feb 2006
--					CAP_INST_TYPE =	 insttype ,		  -- Not reqd 1 Feb 2006
					-- CAP_PROD_CODE =  prodcode ,
					-- CAP_PROD_CATG =	 v_cpm_catg_code ,
					-- CAP_CARD_TYPE =  cardtype ,
					CAP_CUST_CATG =	 custcatg , 
					--CAP_PAN_CODE = newpan ,020206  pan code is being updatd
					--CAP_MBR_NUMB =  '000' , -- Not reqd 1 Feb 2006
					CAP_CARD_STAT =  1 ,   -- Should be 1
					CAP_CUST_CODE =  custcode ,
					CAP_DISP_NAME =  dispname ,
					CAP_LIMIT_AMT =	 limitamt ,
					CAP_USE_LIMIT =	 uselimit ,
					CAP_ACTIVE_DATE =  SYSDATE,    --020206 - active date will be sysdate ..
					--CAP_APPL_BRAN =  applbran ,010206 ----branch will not be updated      
					-- CAP_EXPRY_DATE =  exprydate ,
					CAP_ADDON_STAT =  adonstat ,
					CAP_ADDON_LINK = adonlink ,
					CAP_MBR_LINK = mbrlink ,
					CAP_ACCT_ID = acctid ,
					CAP_ACCT_NO = acctno ,
					CAP_TOT_ACCT =  totacct ,
					CAP_BILL_ADDR =	billaddr ,
					CAP_CHNL_CODE =	chnlcode ,
					--CAP_PANGEN_DATE = SYSDATE , -020206 - pan gen data will not be changed cnfrimed rahul-imran 
					--CAP_PANGEN_USER	= lupduser ,-020206 - pan gen user will not be changed cnfrimed rahul-imran 
					CAP_CAFGEN_FLAG = 'N' ,
--					CAP_PIN_FLAG =	'Y' ,
--					CAP_EMBOS_FLAG = 'Y' ,
					CAP_PHY_EMBOS =  'N' ,
					CAP_JOIN_FEECALC = 'N' ,
					CAP_NEXT_BILL_DATE = billdate , -- this will be as per the original date of the card...
					--CAP_INS_USER =	lupduser ,020206 -----------ins date will not be updated since the date is there 
					CAP_LUPD_USER =	 lupduser ,
					CAP_PBFGEN_FLAG = 'R' ,
					--CAP_LAST_MB_DATE =  v_cap_last_mb_date, commented by tejas bcs CR103B not on prod 3feb06
					-- atm, pos and other limit 
					CAP_ATM_OFFLINE_LIMIT =v_CAP_ATM_OFFLINE_LIMIT,
					CAP_ATM_ONLINE_LIMIT = v_CAP_ATM_ONLINE_LIMIT ,							 
					CAP_POS_OFFLINE_LIMIT= v_CAP_POS_OFFLINE_LIMIT ,							  
					CAP_POS_ONLINE_LIMIT=  v_CAP_POS_ONLINE_LIMIT,							 
					CAP_ONLINE_AGGR_LIMIT= v_CAP_ONLINE_AGGR_LIMIT ,							  
					CAP_OFFLINE_AGGR_LIMIT= v_CAP_OFFLINE_AGGR_LIMIT 
					WHERE CAP_PAN_CODE = newpan ;
  				errmsg := 'OK';
  				EXCEPTION	--Exception of Begin 4
  				WHEN OTHERS THEN
				DBMS_OUTPUT.PUT_LINE('Here in excp '||SQLCODE||' '||SQLERRM);
					 errmsg := 'Exception while Updating Pan Details  ';
  					--errmsg := 'Excp 4 -- '||SQLERRM;
  				END;	--End of Begin 4
  END IF;
  --dbms_output.put_line('chk5-------------->'||errmsg);		
 IF errmsg = 'OK' THEN  
  	 	    UPDATE CMS_APPL_PAN 
			SET CAP_CARD_STAT='1'
			WHERE	cap_pan_code = newpan;
-- SET  the STATUS of OLD PAN TO 9. --------------CR162			  			
			UPDATE CMS_APPL_PAN 
			SET CAP_CARD_STAT='9'
			WHERE	cap_pan_code = pancode;		
END IF;
  	IF errmsg = 'OK' THEN	--
  		FOR x IN c1(pancode)
  		LOOP
		-- This has to be updated, not inserted.....use the where condition of pan code = new pan       
		  DBMS_OUTPUT.PUT_LINE('Before updating  data CMS_PAN_ACCT');
  		   IF x.cpa_acct_posn = 1 THEN          --IF Account position is 1 then update the account dtls 
			   UPDATE CMS_PAN_ACCT SET 
--   				    CPA_INST_CODE= instcode , 									
					CPA_CUST_CODE= custcode ,	
					CPA_ACCT_ID= x.cpa_acct_id ,
					CPA_ACCT_POSN= x.cpa_acct_posn	,
--					CPA_PAN_CODE= newpan ,
--					CPA_MBR_NUMB= '000' ,
					CPA_INS_USER= lupduser ,
					CPA_LUPD_USER= lupduser
			   WHERE 
					CPA_PAN_CODE = newpan 
					AND cpa_acct_posn = 1;
			ELSE                                 --IF Account position is more than 1 then update the account dtls 
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
  											newpan			,
  											v_mbrnumb		,
  											lupduser		,
  											lupduser);
			END IF;	  		
			EXIT WHEN c1%NOTFOUND; 
  		END LOOP;
  		errmsg := 'OK';
  	END IF;
  EXCEPTION	--Main Block Exception
  	WHEN OTHERS THEN
	errmsg := 'Main Excp -- '||SQLERRM;
    DBMS_OUTPUT.PUT_LINE('chk7-------------->'||errmsg);
	errmsg := 'Error while Updating Pan Account Dtls';
	ROLLBACK;
  	--errmsg := 'Main Excp -- '||SQLERRM;
    --dbms_output.put_line('chk7-------------->'||errmsg);		
  END;		--Main Begin Block Ends Here
/
SHOW ERRORS

