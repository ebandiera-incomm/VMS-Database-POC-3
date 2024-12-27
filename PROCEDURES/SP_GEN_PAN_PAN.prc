CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Gen_Pan_Pan (	pancode		IN	VARCHAR2	,
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
  acctbal_old          CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  billdate				DATE; -- billing date to be carried forward to the re-issued card -- jimmy 2/7/05

  v_ccc_catg_sname	CMS_CUST_CATG.ccc_catg_sname%TYPE;
  expry_param		NUMBER(3);
  v_card_type NUMBER (5)	; --**
  v_bin_stat CMS_BIN_MAST.cbm_bin_stat%TYPE; -- shyamjith 28 feb 05 - CR 138
  dum NUMBER(1);

 v_hsm_mode		VARCHAR2(1);--Rahul 28 Sep 05
  v_pingen_flag		VARCHAR2(1);--Rahul 28 Sep 05
  v_emboss_flag		VARCHAR2(1);--Rahul 28 Sep 05

   v_cap_next_mb_date DATE; -- Ashwini 8 Oct 05 CR-103B MoneyBack
  v_prod_prefix VARCHAR2(2); -- Rahul 1 Dec 05

   v_atm_offline_limit    NUMBER (10);
   v_atm_online_limit     NUMBER (10);
   v_pos_offline_limit    NUMBER (10);
   v_pos_online_limit     NUMBER (10);
   v_offline_aggr_limit   NUMBER (10);
   v_online_aggr_limit    NUMBER (10);
   holdcount              NUMBER;
   currbran               VARCHAR2(5);
   v_host_proc           VARCHAR(20);
   --added by rashmi on 120707
   accttype NUMBER;
   acctstat NUMBER;
   acctid_new NUMBER;
   holdposn  NUMBER;


v_rulegroupid NUMBER;
v_flowprocess VARCHAR2(5);
v_ruleindicator NUMBER;
  v_profile_code 	VARCHAR2(4); -- Prajakta Patil 30-07-07


   --** Rama PrabhuR 3rd Feb 07 - For generic pan construct
   tmp_pan                VARCHAR2 (20);
   ctrlnumb               NUMBER (10);
   pan_length             NUMBER (2) := 16;
   starttime              TIMESTAMP;
   endtime                TIMESTAMP;
   j                      NUMBER (3);
   i                      NUMBER (3);
   v_panacctno            VARCHAR2 (20);
   v_pancardtype          VARCHAR2 (2);

   TYPE rec_pantype IS RECORD (
      cpc_inst_bin     NUMBER (2),
      cpc_field_name   VARCHAR2 (30),
      cpc_value        VARCHAR2 (20),
      cpc_start_from   NUMBER (2),
      cpc_start        NUMBER (2),
      cpc_length       NUMBER (2)
   );

   TYPE plsql_tab_pan_type IS TABLE OF rec_pantype
      INDEX BY BINARY_INTEGER;

   pantypetabvar          plsql_tab_pan_type;



  CURSOR c1(pan_code IN VARCHAR2) IS
  SELECT	cpa_acct_id,cpa_acct_posn
  FROM	CMS_PAN_ACCT
  WHERE	cpa_pan_code = pan_code ;


   --CURSOR c2 (pan_bin IN NUMBER)
   CURSOR c2(v_profile_code IN VARCHAR2)
   IS                  --** Rama PrabhuR 3rd Feb 07 - For generic pan construc
      SELECT   *
          FROM CMS_PAN_CONSTRUCT
--         WHERE cpc_inst_bin = pan_bin
  WHERE cpc_profile_code = v_profile_code
      ORDER BY cpc_order_by;
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
--  Local procedure to find out the running serial number
---########################################################################
   PROCEDURE lp_pan_srno (
      l_instcode   IN       NUMBER,
      l_prefix     IN       VARCHAR2,
      l_bin        IN       NUMBER,
      l_lupduser   IN       NUMBER,
	    l_proiflecode IN      VARCHAR2,
      l_srno       OUT      VARCHAR2,
      l_errmsg     OUT      VARCHAR2
   )
   IS
   BEGIN
      l_errmsg := 'OK';

      BEGIN
         tmp_pan := '';
         DBMS_OUTPUT.put_line ('chkpt1');
         i := 1;

         FOR x IN c2 (l_proiflecode)
         LOOP
            pantypetabvar (i).cpc_field_name := x.cpc_field_name;
            pantypetabvar (i).cpc_value := x.cpc_value;
            pantypetabvar (i).cpc_start_from := x.cpc_start_from;
            pantypetabvar (i).cpc_start := x.cpc_start;
            pantypetabvar (i).cpc_length := x.cpc_length;
            DBMS_OUTPUT.put_line ('insideloop');
            DBMS_OUTPUT.put_line (   'FIELD NAME'
                                  || pantypetabvar (i).cpc_field_name
                                 );

            IF pantypetabvar (i).cpc_field_name = 'BIN'
            THEN
               pantypetabvar (i).cpc_value :=
                  SUBSTR (l_bin,
                          pantypetabvar (i).cpc_start,
                          pantypetabvar (i).cpc_length
                         );
               DBMS_OUTPUT.put_line (   l_bin
                                     || ' '
                                     || TO_CHAR (pantypetabvar (i).cpc_start)
                                     || ' '
                                     || TO_CHAR (pantypetabvar (i).cpc_length)
                                    );
               tmp_pan := tmp_pan || pantypetabvar (i).cpc_value;
            ELSIF pantypetabvar (i).cpc_field_name = 'BRANCH'
            THEN
               pantypetabvar (i).cpc_value :=
                  SUBSTR (pan_branch,
                          pantypetabvar (i).cpc_start,
                          pantypetabvar (i).cpc_length
                         );
               DBMS_OUTPUT.put_line (   pan_branch
                                     || ' '
                                     || TO_CHAR (pantypetabvar (i).cpc_start)
                                     || ' '
                                     || TO_CHAR (pantypetabvar (i).cpc_length)
                                    );
               tmp_pan := tmp_pan || pantypetabvar (i).cpc_value;
            ELSIF pantypetabvar (i).cpc_field_name = 'CARD TYPE'
            THEN
               DBMS_OUTPUT.put_line (cardtype);

               SELECT cpc_prod_prefix
                 INTO v_pancardtype
                 FROM CMS_PROD_CATTYPE
                WHERE cpc_inst_code = instcode
                  AND cpc_prod_code = prodcode
                  AND cpc_card_type = cardtype;

               pantypetabvar (i).cpc_value :=
                  SUBSTR (v_pancardtype,
                          pantypetabvar (i).cpc_start,
                          pantypetabvar (i).cpc_length
                         );
               tmp_pan := tmp_pan || pantypetabvar (i).cpc_value;
            END IF;

            DBMS_OUTPUT.put_line ('insideloop' || i);
            i := i + 1;
         END LOOP;

         BEGIN
            SELECT cpc_ctrl_numb
              INTO ctrlnumb
              FROM CMS_PAN_CTRL
             WHERE cpc_pan_prefix = tmp_pan;

            UPDATE CMS_PAN_CTRL
               SET cpc_ctrl_numb = ctrlnumb + 1
             WHERE cpc_pan_prefix = tmp_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               INSERT INTO CMS_PAN_CTRL
                           (cpc_inst_code, cpc_pan_prefix, cpc_ctrl_numb
                           )
                    VALUES (1, tmp_pan, 2
                           );

               ctrlnumb := 1;
--  l_errmsg := 'CTRL DATA NOT DEFINED';
         END;

         tmp_pan :=
            tmp_pan
            || LPAD (ctrlnumb, (pan_length - 1) - LENGTH (tmp_pan), '0');
         DBMS_OUTPUT.put_line (tmp_pan);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_errmsg := 'Excp1 LP2.1 -- ' || SQLERRM;
         WHEN OTHERS
         THEN
            l_errmsg := 'Excp1 LP2.2 -- ' || SQLERRM;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errmsg := 'Excp1 LP2 -- ' || SQLERRM;
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
  	--temp_pan	:= l_prfx||l_brancode||l_srno ;
  	--len_pan		:= LENGTH(temp_pan);

	temp_pan := tmp_pan;
    len_pan := LENGTH (temp_pan);

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

   errmsg:='OK';

-- Rahul 28 Sep 05
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


 IF	mbrnumb IS NULL  THEN
  		v_mbrnumb := '000';
ELSE
		v_mbrnumb :=mbrnumb;
 END IF;


  	BEGIN		--Begin 1 Block Starts Here
  		SELECT cap_inst_code, cap_asso_code, cap_inst_type, cap_prod_code, cap_appl_bran, cap_cust_code, cap_card_type, cap_cust_catg, cap_disp_name,cap_appl_bran,cap_active_date ,cap_expry_date ,cap_addon_stat, cap_tot_acct, cap_chnl_code,
  		cap_limit_amt, cap_use_limit, cap_bill_addr, cap_next_bill_date, cap_next_mb_date, --Ashwini 8 Oct 05 CR-103B MoneyBack
	    cap_atm_offline_limit,cap_atm_online_limit, cap_pos_offline_limit, cap_pos_online_limit, cap_offline_aggr_limit,cap_online_aggr_limit,
		CAP_RULE_INDICATOR, CAP_RULEGROUP_CODE
  		INTO	instcode, assocode, insttype, prodcode, pan_branch, custcode, cardtype, custcatg, dispname,applbran,actvdate,exprydate,adonstat,totacct, chnlcode, limitamt, uselimit, billaddr, billdate,
      v_cap_next_mb_date, --Ashwini 8 Oct 05 CR-103 MoneyBack
	  v_atm_offline_limit,v_atm_online_limit, v_pos_offline_limit,v_pos_online_limit, v_offline_aggr_limit,v_online_aggr_limit,v_ruleindicator,v_rulegroupid
  		FROM	CMS_APPL_PAN
  		WHERE	cap_pan_code	=	pancode
  		AND		cap_mbr_numb	= 	v_mbrnumb;
  		actvdate := SYSDATE;	--added on 11/10/2002 ...to set the active date as sysdate for the newly gen pan


  		IF newdisp IS NOT NULL THEN
  		dispname := newdisp;
  		END IF;


		--shyamjith 05 jan 05 .. if bin is changed--start
					v_card_type:= TO_NUMBER(newprodcat);


		IF newprodcode IS NOT NULL AND v_card_type IS NOT NULL THEN
		BEGIN
		IF prodcode != newprodcode OR cardtype!= v_card_type THEN
		BEGIN
			 BEGIN
			 SELECT	1 INTO dum FROM	CMS_PROD_CCC
--				select cpc_prodccc_code into prodccc_code from cms_prod_ccc
				WHERE cpc_prod_code = newprodcode
				AND cpc_card_type = v_card_type
				AND cpc_cust_catg = custcatg;

				--START BY RASHMI
				BEGIN
				SELECT PPR_RULEGROUP_CODE,PPR_FLOW_SOURCE
				INTO  v_rulegroupid,v_flowprocess
				FROM PCMS_PRODCATTYPE_RULEGROUP
				WHERE PPR_PROD_CODE=newprodcode
				AND PPR_CARD_TYPE=v_card_type;

				IF  v_flowprocess='P'
				THEN
				v_ruleindicator:=1;
				ELSE
				v_ruleindicator:=2;
				END IF;
				EXCEPTION
				WHEN NO_DATA_FOUND THEN
				v_ruleindicator:=NULL;
				v_rulegroupid:=NULL;

				END;



				--END BY RASHMI


				IF dum != 1 THEN
				--**Sp_Create_Prodccc(instcode,custcatg,NULL,v_card_type,newprodcode,lupduser,errmsg);
				 Sp_Create_Prodccc ( instcode , custcatg , v_card_type , newprodcode ,'A' , 'A' ,newprodcode||'_' || newprodcat || '_' || custcatg , lupduser , errmsg ) ;
				IF errmsg != 'OK' THEN
				errmsg := 'Problem while attaching prod_cat_cust_catg for pan ';
--				ROLLBACK;
				END IF;
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				BEGIN
				--**Sp_Create_Prodccc(instcode,custcatg,NULL,v_card_type,newprodcode,lupduser,errmsg);
				--** Sp_Create_Prodccc ( instcode , custcatg , v_card_type , newprodcode ,'A' , 'A' , lupduser , errmsg ) ;
				IF errmsg != 'OK' THEN
				errmsg := 'Problem while attaching prod_cat_cust_catg for pan ';
--				ROLLBACK;
				END IF;
				END;
				--errmsg := 'No Record found for Product ' || newprodcode || ' Product Catg '|| newprodcat || ' Cust Catg '|| custcatg;
				WHEN TOO_MANY_ROWS THEN
				errmsg := 'Duplicate Records found for Product ' || newprodcode || ' Prod Catg '|| v_card_type || 'Cust Catg '|| custcatg;
				WHEN OTHERS THEN
				errmsg := 'Exception from Product_CCC';
			END;
						prodcode := newprodcode;
						cardtype := v_card_type;
						--next_bill_date := null;         -- add_months(sysdate+12)
						--If product is same as of reissued cards then fees shud not charged
					--	v_fee_calc  := 'N' ;
						limitamt := 0;
						uselimit := 0;
		END;
		END IF;
		END;


		--shyamjith ...... end

  		SELECT	cip_param_value
  		INTO	expry_param
  		FROM	CMS_INST_PARAM
  		WHERE	cip_inst_code = instcode
  		AND	cip_param_key = 'CARD EXPRY';
  		--exprydate := add_months(sysdate,expry_param);
      exprydate := ADD_MONTHS(SYSDATE,expry_param-1); -- Ashwini -25 Jan 05-- Expry date is last day of the prev month after adding expry param

  			lp_pan_bin(instcode, insttype, prodcode,pan_bin, errmsg)	;

 END IF;--**
  	EXCEPTION	--Exception of Begin 1 Block
  		WHEN NO_DATA_FOUND THEN
  		errmsg := 'No information found for '||pancode ;
  		WHEN OTHERS THEN
  		errmsg := 'Excp1 -- '||SQLERRM;
  	END;		--Begin 1 Block Ends Here

	-- rahul 01 Dec 05
	BEGIN
		 SELECT CPC_PROD_PREFIX
		 INTO v_prod_prefix
		 FROM CMS_PROD_CATTYPE
		 WHERE CPC_PROD_CODE=prodcode
		 AND CPC_CARD_TYPE=cardtype;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN
		 ERRMSG:='SDFDF';
	END;
-- Rahul changes end;


  	IF errmsg = 'OK' THEN
  		BEGIN		--Begin 1.2 starts
  		SELECT 	cpm_catg_code,cpm_profile_code
  		INTO	v_cpm_catg_code,v_profile_code
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
				--lp_pan_srno(instcode,prodcode,pan_bin,pan_branch,custcatg,lupduser,pan_srno,errmsg);
				lp_pan_srno(instcode,v_prod_prefix,pan_bin,lupduser,v_profile_code,pan_srno,errmsg); -- Rahul 1 Dec 05
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
	  	-- pan := pan_bin||v_prod_prefix||pan_srno||pan_chkdig ;  -- Rahul 1 Dec 05
		pan := tmp_pan || pan_chkdig;
  	--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--
  		IF errmsg = 'OK' THEN
  			BEGIN --begin 5
  			SELECT cam_acct_id,cam_acct_no,cam_hold_count,cam_curr_bran,cam_bill_addr,
			 cam_type_code,cam_stat_code,cam_acct_bal--added by rashmi on 120707
  			INTO	acctid,acctno,holdcount,currbran,billaddr,accttype,acctstat,acctbal_old
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
		--start by rashmi
        BEGIN
		IF errmsg = 'OK' THEN
  			BEGIN

  			Sp_Create_Acct(1,pan,holdcount,currbran,billaddr,accttype ,acctstat,
            lupduser,acctid_new,errmsg);
		     IF errmsg != 'OK' THEN
				errmsg := 'Problem while calling the sp_ceate_acct';

  		     END IF;
		   END;
        END IF;

			IF errmsg = 'OK' THEN
  			BEGIN

  			Sp_Create_Holder(1,custcode,acctid_new,NULL,lupduser,holdposn,errmsg);
		     IF errmsg != 'OK' THEN
				errmsg := 'Problem while calling the sp_ceate_holder';

  		     END IF;
		   END;
        END IF;




		   IF errmsg = 'OK' THEN
				 		  --** Rama PrabhuR 28th May 07 -- for updating balance in acct mast - start
		BEGIN
         SELECT cip_param_value
           INTO v_host_proc
           FROM CMS_INST_PARAM
          WHERE cip_inst_code = instcode AND cip_param_key = 'REQ_HOST_PROC';
		EXCEPTION WHEN NO_DATA_FOUND THEN
		  v_host_proc:='N';
		END;
		END IF;



         IF v_host_proc = 'Y'
         THEN
            UPDATE CMS_ACCT_MAST
               SET cam_acct_no = pan
             WHERE cam_inst_code = 1 AND cam_acct_id = acctid_new;
         ELSE

            UPDATE CMS_ACCT_MAST
               SET cam_acct_no = pan,
                   cam_acct_bal = acctbal_old
             WHERE cam_inst_code = 1 AND cam_acct_id = acctid_new;
         END IF;




      --** Rama PrabhuR 28th May 07 -- for updating balance in acct mast - end
		EXCEPTION
				 WHEN OTHERS THEN
				 errmsg:=' Exception while updating Account Master with AcctId ' || acctid || ' WITH Pan Code' || pan ||' :- ' ||SQLERRM;
		END;



		--end by rashmi

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
  											CAP_BILL_ADDR	,
  											CAP_CHNL_CODE	,
  											CAP_PANGEN_DATE	,
  											CAP_PANGEN_USER	,
  											CAP_CAFGEN_FLAG ,
  											CAP_PIN_FLAG	,
  											CAP_EMBOS_FLAG	,
  											CAP_PHY_EMBOS             ,
  											CAP_JOIN_FEECALC	,
  											CAP_NEXT_BILL_DATE	,----added on 11/10/2002
  											CAP_INS_USER		,
  											CAP_LUPD_USER		,
  											CAP_PBFGEN_FLAG,
                                			CAP_NEXT_MB_DATE ,
								 		    CAP_ATM_OFFLINE_LIMIT,
                      						CAP_ATM_ONLINE_LIMIT,
											CAP_POS_OFFLINE_LIMIT,
                      						CAP_POS_ONLINE_LIMIT,
											CAP_OFFLINE_AGGR_LIMIT,
                      						CAP_ONLINE_AGGR_LIMIT,
											CAP_RULE_INDICATOR,
											CAP_RULEGROUP_CODE)--, Ashwini CR-103B MoneyBack
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
  											acctid_new		,
  											--acctno		,
  											pan,
											totacct		,
  											billaddr		,
  											chnlcode		,
  											SYSDATE		,
  											lupduser		,
  											'N'		   ,
  											v_pingen_flag 	, -- PIN FLAG -- rahul 28 sep 05
  											v_emboss_flag	, -- EMBOSS FLAG -- rahul 28 sep 05
  											'N'			,
  											'N'			,
--  											add_months(sysdate,12),--added on 11/10/2002  ...the date is set as that of 12 months after the regen date because the billing cycle for re issued pans will start from next yr
										 	billdate,  -- the bill date will be carried forward to the re-issued card -- jimmy 2nd July 2005
  													--this is because regen is donr for reissue i.e. for hotlisted cards
  											lupduser		,
  											lupduser		,
  											'R' ,
                                 v_cap_next_mb_date,
								 			v_atm_offline_limit,
                      						v_atm_online_limit,
											v_pos_offline_limit,
                      						v_pos_online_limit,
											v_offline_aggr_limit,
                      						v_online_aggr_limit,
											v_ruleindicator,
											v_rulegroupid
											);--, Ashwini CR-103B MoneyBack
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
  											acctid_new	,
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


