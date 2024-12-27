CREATE OR REPLACE PROCEDURE VMSCMS.SP_CALC_ONETIMEFEES  (
					instcode	IN	NUMBER	,
					lupduser	IN	NUMBER	,
					Proid	OUT	 NUMBER ,
					errmsg		OUT	 VARCHAR2)
IS
NoPosnfound EXCEPTION ;
DUMMY			NUMBER(1) := 0;
v_cap_prod_code		CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
v_cap_card_type		CMS_APPL_PAN.cap_card_type%TYPE;
v_cap_cust_catg		CMS_APPL_PAN.cap_cust_catg%TYPE;
v_cap_active_date	DATE;
v_cap_acct_id		CMS_APPL_PAN.cap_acct_id%TYPE;
v_cap_acct_no		CMS_APPL_PAN.cap_acct_no%TYPE;
v_cap_cust_code		CMS_APPL_PAN.cap_cust_code%TYPE;
v_cap_appl_bran		CMS_APPL_PAN.cap_appl_bran%TYPE;
v_cpa_card_posn		CMS_PAN_ACCT.cpa_card_posn%TYPE;
v_cpf_plan_code		CMS_PRODCCC_FEEPLAN.cpf_plan_code%TYPE;
v_feetrans		CMS_CHARGE_DTL.ccd_fee_trans%TYPE;
--v_gcm_city_catg		GEN_CITY_MAST.gcm_city_catg%TYPE;
--v_ccm_catg_code	CMS_CUST_MAST.ccm_catg_code%TYPE;
excp_fee_calc		EXCEPTION;
v_cpc_cardtype_desc  CMS_PROD_CATTYPE.CPC_CARDTYPE_DESC%TYPE ;
 v_ccc_catg_sname  CMS_CUST_CATG.CCC_CATG_SNAME%TYPE ;
-- Ajit 24 sep 03
V_cnt    NUMBER(10);
excp_no_data_found  EXCEPTION ;
-- Ajit 24 sep 03
v_waivprcnt  NUMBER(10,2); -- AJIT 8 OCT 2003
DEBUG VARCHAR2(100);
v_max_waiv_posn   CMS_PRODCCC_FPWAIV.CPF_CARD_POSN%TYPE;
v_max_Fee_posn     CMS_PRODCCC_FEEPLAN.CPF_CARD_POSN%TYPE;
v_repin_reissue_cnt NUMBER(6); -- Ashwini 11 July 05

CURSOR cur_appl_pan IS
	SELECT	cap_pan_code, cap_mbr_numb
	FROM	CMS_APPL_PAN
	WHERE	cap_fee_calc = 'N';
CURSOR  cur_fee_dtls(feeplancode VARCHAR2) IS
	SELECT  FM.CFM_FEE_CODE feecode, FM.CFM_FEE_AMT feeamt, FF.CFF_FEE_FREQ feefreq
	FROM	CMS_FEEPLAN_MAST FP, CMS_FEEPLAN_DTL FD, CMS_FEE_MAST FM, CMS_FEE_TYPES FT, CMS_FEE_FREQ FF
	WHERE	FP.CFM_INST_CODE = FD.CFD_INST_CODE
	AND	FP.CFM_PLAN_CODE = FD.CFD_PLAN_CODE
	AND	FD.CFD_FEE_CODE  = FM.CFM_FEE_CODE
	--Added By Christopher on 26Oct2004 for Tuning-Change_Starts
	AND FM.CFM_INST_CODE = 1
	AND FT.CFT_INST_CODE = 1
	--Added By Christopher on 26Oct2004 for Tuning-Change Ends
		AND	FM.CFM_FEETYPE_CODE = FT.CFT_FEETYPE_CODE
	AND	FT.CFT_FREQ_KEY  = FF.CFF_FREQ_KEY
	AND	FP.CFM_PLAN_CODE = feeplancode
	AND	FF.CFF_FEE_FREQ	 = 0;
BEGIN		-- Main Begin
	-- Added By Ajit as on 8 Oct 03
	BEGIN	-- Begin 1
		SELECT 1 INTO v_cnt
		FROM	CMS_APPL_PAN
		WHERE	cap_fee_calc = 'N' AND  ROWNUM = 1;
	EXCEPTION	-- Exception 1
		WHEN NO_DATA_FOUND THEN
			errmsg := 'No Records Found For Fee Calculation';
			RAISE excp_no_data_found;
	END;	 -- End 1
        SELECT seq_fee_proid.NEXTVAL INTO proid  FROM dual;
-- Ajit on 13 Nov 03 To achive following condition
-- exp date = sysdate + (prod validty months +1)   where exp dte is > 45 and billing is happening after 15 or equal
--	To be uncommented
	/*Begin
		update cms_appl_pan set CAP_EXPRY_DATE = add_months(sysdate,
		(select nvl(CPC_PAN_VALIDITY,0)+1 from cms_prod_ccc where
		 CPC_CUST_CATG = cap_cust_catg
		and CPC_CARD_TYPE = cap_card_type
		and cpc_prod_code = cap_prod_code
		and rownum =1) )
		where Round(CAP_EXPRY_DATE - sysdate ) > 45
		and  to_CHAR(sysdate,'dd') >= 15
		and cap_card_stat = '1' ;
	Exception
		when others then
		errmsg := 'Error in Updating Expiry Date.';
		raise excp_no_data_found;
	End ;*/
--	To be uncommented
-- Ajit on 13 Nov 03
	FOR x IN cur_appl_pan LOOP
		BEGIN	-- Begin 2
			BEGIN -- Begin 2.1
			SELECT	cap_prod_code, cap_card_type, cap_cust_catg, cap_active_date,
					cap_acct_id, cap_acct_no, cap_cust_code, cap_appl_bran,
					cpa_card_posn--, ccm_catg_code
			INTO
					v_cap_prod_code	, v_cap_card_type	, v_cap_cust_catg	, v_cap_active_date,
					v_cap_acct_id, v_cap_acct_no, v_cap_cust_code, v_cap_appl_bran,
					v_cpa_card_posn--, v_ccm_catg_code
			FROM    CMS_APPL_PAN, CMS_PAN_ACCT,CMS_CUST_MAST
			WHERE
			CPA_INST_CODE = 1 --Added By Christopher on 26Oct2004 for Tuning .
			AND cap_pan_code = cpa_pan_code
			AND	cap_mbr_numb = cpa_mbr_numb
			AND	cap_acct_id  = cpa_acct_id
			AND	cap_pan_code = x.cap_pan_code
			AND	cap_mbr_numb = x.cap_mbr_numb
         AND CAP_INST_CODE = CCM_INST_CODE -- Ashwini 19 July 2004 tunning
			AND cap_cust_code = ccm_cust_code;
			EXCEPTION -- Exception 2.1
				WHEN NO_DATA_FOUND	 THEN
				errmsg := 'No Combination Found Of Account and Customer For Pan' ;
				--raise excp_fee_calc;
				GOTO excp_fee_calc;
				WHEN OTHERS THEN
				errmsg := 'ERROR FOR THIS PAN !!! '||SQLERRM;
--				raise excp_fee_calc;
				GOTO excp_fee_calc;
			END;	-- end 2.1
			BEGIN
				 SELECT  CPC_CARDTYPE_DESC
				 INTO	 v_cpc_cardtype_desc
				 FROM CMS_PROD_CATTYPE
				 WHERE CPC_INST_CODE  = instcode
				 AND CPC_PROD_CODE = v_cap_prod_code
				 AND CPC_CARD_TYPE = v_cap_card_type ;
			--DBMS_OUTPUT.PUT_LINE('CHK :8 ') ;
			EXCEPTION
			  WHEN NO_DATA_FOUND THEN
			    Errmsg := 'For the Pan : '||x.cap_pan_code||' card type : '||v_cap_card_type||' product code : '||v_cap_prod_code||' combination not found in Masters';
				GOTO excp_fee_calc;
				WHEN OTHERS THEN
				Errmsg := 'Error While getting Card type :'||SQLERRM ;
				GOTO excp_fee_calc;
			END  ;
			BEGIN
				 SELECT  CCC_CATG_SNAME
				 INTO	 v_ccc_catg_sname
				 FROM CMS_CUST_CATG
				 WHERE CCC_INST_CODE  = instcode
				 AND CCC_CATG_CODE = v_cap_cust_catg  ;
			--DBMS_OUTPUT.PUT_LINE('CHK :9 ') ;
			EXCEPTION
			  WHEN NO_DATA_FOUND THEN
			    Errmsg := 'For the Pan : '||x.cap_pan_code||' Customer category : '||v_cap_cust_catg||' not found in Masters'  ;
				GOTO excp_fee_calc;
				WHEN OTHERS THEN
				Errmsg := 'Error While getting Customer Category :'||SQLERRM ;
				GOTO excp_fee_calc;
			END  ;
			/*BEGIN -- begin 2.2
				SELECT  gcm_city_catg
				INTO	v_gcm_city_catg
				FROM	CMS_BRAN_MAST, GEN_CITY_MAST
				WHERE	cbm_city_code = gcm_city_code
				AND CBM_INST_CODE = 1 --Added By christopher on 26Oct2004 for Tuning
				AND	cbm_bran_code = v_cap_appl_bran;
			EXCEPTION -- Exception 2.2
			WHEN NO_DATA_FOUND THEN
				errmsg := 'No City Category Found for the PANs Branch :' ||v_cap_appl_bran;
--				raise excp_fee_calc;
				GOTO excp_fee_calc;
			WHEN OTHERS THEN
				errmsg := 'ERROR FOR THIS PAN !!! '||SQLERRM;
--				raise excp_fee_calc;
				GOTO excp_fee_calc;
			END; -- End 2.2*/
			BEGIN -- Begin 2.3
				SELECT  MAX(CPF_CARD_POSN) INTO v_max_Fee_posn
				FROM	CMS_PRODCCC_FEEPLAN
				WHERE	CPF_INST_CODE = instcode
				AND	CPF_PROD_CODE = v_cap_prod_code
				AND	CPF_CARD_TYPE = v_cap_card_type
				AND	CPF_CUST_CATG = v_cap_cust_catg
				--AND CPF_CITY_CATG = v_gcm_city_catg         -- AJIT 24 SEP 03
				--AND CPF_CUST_TYPE =v_ccm_catg_code	-- ajit 8 nov 03
				AND	TRUNC(v_cap_active_date) BETWEEN TRUNC(CPF_VALID_FROM ) AND TRUNC(CPF_VALID_TO);
				IF v_max_Fee_posn IS NULL THEN
				   RAISE  NoPosnfound ;
				ELSE
						IF  v_cpa_card_posn > v_max_Fee_posn   AND v_cpa_card_posn > 3 THEN
							v_cpa_card_posn :=  v_max_Fee_posn ;
						END IF;
				END IF ;
			EXCEPTION -- Eception 2.3
				WHEN NoPosnfound THEN
				Errmsg := 'No Card Position in the feeplan  For Pan : '||x.cap_pan_code||' with product code : '||v_cap_prod_code ||
				            ' and Card type : '||v_cpc_cardtype_desc||' and Customer Category : '|| v_ccc_catg_sname || ' and City Catg : ' ||--v_gcm_city_catg ||
							/*' and ethnic code : '|| v_ccm_catg_code ||*/' and active date : '||v_cap_active_date ;
--				raise excp_fee_calc;
				GOTO excp_fee_calc;
			END; -- End 2.3
			BEGIN -- Begin 2.4
				SELECT  cpf_plan_code
				INTO	v_cpf_plan_code
				FROM	CMS_PRODCCC_FEEPLAN
				WHERE	CPF_INST_CODE = instcode
				AND	CPF_PROD_CODE = v_cap_prod_code
				AND	CPF_CARD_TYPE = v_cap_card_type
				AND	CPF_CUST_CATG = v_cap_cust_catg
				--AND CPF_CITY_CATG = v_gcm_city_catg         -- AJIT 24 SEP 03
				AND CPF_CARD_POSN = v_cpa_card_posn    -- AJIT 24 SEP 03
				--AND CPF_CUST_TYPE =v_ccm_catg_code	-- ajit 8 nov 03
				AND	TRUNC(v_cap_active_date) BETWEEN TRUNC(CPF_VALID_FROM ) AND TRUNC(CPF_VALID_TO);
			EXCEPTION -- Excp 2.4
				WHEN NO_DATA_FOUND THEN
					--Errmsg := 'No Fee Plan Found For Pan ';
					Errmsg := 'No Fee Plan Found For Pan'||x.cap_pan_code||' with '||' Product Code : '||V_cap_prod_code||' and Card Type : '||
					           v_cpc_cardtype_desc||' and Customer category : '||v_ccc_catg_sname/*||' and City Category : '||v_gcm_city_catg*/||' and card Position :'||v_cpa_card_posn||' and Active date : '||v_cap_active_date;
					GOTO excp_fee_calc;
				WHEN TOO_MANY_ROWS THEN
					--errmsg := 'TOO MANY FEE PLANS ACTIVE FOR THIS PAN !!!';
					errmsg := 'TOO MANY FEE PLANS ACTIVE FOR THIS PAN '||x.cap_pan_code||' with '||' Product Code : '||V_cap_prod_code||' and Card Type : '||
					           v_cpc_cardtype_desc||' and Customer category : '||v_ccc_catg_sname/*||' and City Category : '||v_gcm_city_catg*/||
							   ' and card Position :'||v_cpa_card_posn||' and Active date : '||v_cap_active_date;
--					raise excp_fee_calc;
					GOTO excp_fee_calc;
				WHEN OTHERS THEN
					errmsg := 'ERROR FOR THIS PAN !!! '||SQLERRM;
--					raise excp_fee_calc;
					GOTO excp_fee_calc;
			END ;	 -- End 2.4
			BEGIN -- Begin 2.5
			SELECT  COUNT(1) INTO v_cnt
			FROM	CMS_FEEPLAN_MAST FP, CMS_FEEPLAN_DTL FD, CMS_FEE_MAST FM, CMS_FEE_TYPES FT, CMS_FEE_FREQ FF
			WHERE	FP.CFM_INST_CODE = FD.CFD_INST_CODE
			AND	FP.CFM_PLAN_CODE = FD.CFD_PLAN_CODE
			AND	FD.CFD_FEE_CODE  = FM.CFM_FEE_CODE
			--Added By Christopher on 26Oct2004 for Tuning-Change_Starts
						AND FM.CFM_INST_CODE = 1
						AND FT.CFT_INST_CODE = 1
				--Added By Christopher on 26Oct2004 for Tuning-Change Ends
			AND	FM.CFM_FEETYPE_CODE = FT.CFT_FEETYPE_CODE
			AND	FT.CFT_FREQ_KEY  = FF.CFF_FREQ_KEY
			AND	FP.CFM_PLAN_CODE = v_cpf_plan_code
			AND	FF.CFF_FEE_FREQ	 = 0;
			IF V_cnt = 0 THEN
				--Errmsg := 'For combination of fee plan and pan no data found';
				Errmsg := 'No Fee details For  fee plan '||v_cpf_plan_code;
--				raise excp_fee_calc;
				GOTO excp_fee_calc;
			END IF;
			END; -- End 2.5
			FOR y IN cur_fee_dtls(v_cpf_plan_code) LOOP
				SELECT	seq_fee_trans.NEXTVAL
				INTO	v_feetrans
				FROM	dual;
				-- Added By Ajit on 8 oct 2003
				BEGIN -- begin 2.6
					BEGIN -- begin 2.6.1
						SELECT  NVL(MAX(CPF_CARD_POSN),0) INTO v_max_waiv_posn
						FROM CMS_PRODCCC_FPWAIV
						WHERE CPF_PROD_CODE  = v_cap_prod_code
						AND CPF_PLAN_CODE  = v_cpf_plan_code
						AND CPF_CARD_TYPE  = v_cap_card_type
						AND CPF_CUST_CATG  = v_cap_cust_catg
						AND CPF_FEE_CODE     =  y.feecode
						--AND CPF_CITY_CATG  =v_gcm_city_catg
						--AND CPF_CUST_TYPE = v_ccm_catg_code -- 8 nov 03
						AND	TRUNC(v_cap_active_date ) BETWEEN TRUNC(CPF_VALID_FROM ) AND TRUNC(CPF_VALID_TO);
						IF  v_cpa_card_posn > v_max_waiv_posn   AND v_cpa_card_posn > 3 THEN
							v_cpa_card_posn :=  v_max_waiv_posn ;
						END IF;
					EXCEPTION -- exception 2.6.1
						WHEN NO_DATA_FOUND THEN
							NULL;
					END; -- end 2.6.1
					SELECT  CPF_WAIV_PRCNT
					INTO v_waivprcnt
					FROM CMS_PRODCCC_FPWAIV
					WHERE CPF_PROD_CODE  = v_cap_prod_code
					AND CPF_PLAN_CODE  = v_cpf_plan_code
					AND CPF_CARD_TYPE  = v_cap_card_type
					AND CPF_CUST_CATG  = v_cap_cust_catg
					AND CPF_FEE_CODE     =  y.feecode
					--AND CPF_CITY_CATG  =v_gcm_city_catg
					AND CPF_CARD_POSN = v_cpa_card_posn
					--AND CPF_CUST_TYPE = v_ccm_catg_code -- 8 nov 03
					AND	TRUNC(v_cap_active_date ) BETWEEN TRUNC(CPF_VALID_FROM ) AND TRUNC(CPF_VALID_TO);
				EXCEPTION --exception 2.6
				WHEN OTHERS THEN
					v_waivprcnt := 0;
				END; --end 2.6
				-- Added By Ajit on 8 oct 2003
				INSERT INTO CMS_CHARGE_DTL(
					CCD_INST_CODE  ,
					CCD_PAN_CODE   ,
					CCD_MBR_NUMB   ,
					CCD_CUST_CODE  ,
					CCD_ACCT_NO    ,
					CCD_FEE_CODE   ,
					CCD_CALC_AMT   ,
					CCD_CALC_DATE  ,
					CCD_ACCT_ID    ,
					CCD_FEE_TRANS  ,
					CCD_PLAN_CODE  ,
					CCD_LUPD_USER  ,
					CCD_PROCESS_ID)
				VALUES (
					instcode,
					x.cap_pan_code,
					x.cap_mbr_numb,
					v_cap_cust_code,
					v_cap_acct_no,
					y.feecode,
					y.feeamt*(1-v_waivprcnt/100),     --y.feeamt,   Ajit as on 8 oct 2003
					SYSDATE,
					v_cap_acct_id,
					v_feetrans,
					v_cpf_plan_code,
					lupduser,
					 proid        );
				UPDATE	CMS_APPL_PAN
				SET	cap_fee_calc = 'Y' , cap_next_bill_date = ADD_MONTHS(SYSDATE, 12) -- Ajit 18 Nov 03
				WHERE	cap_pan_code = x.cap_pan_code
				AND	cap_mbr_numb = x.cap_mbr_numb;
			END LOOP;
--		EXCEPTION -- Exception 2
--		WHEN excp_fee_calc THEN
<<excp_fee_calc>>
IF errmsg != 'OK' THEN
			INSERT INTO CMS_FEEERROR_LOG (
					 CFL_INST_CODE  ,
					 CFL_PAN_CODE   ,
					 CFL_MBR_NUMB   ,
					 CFL_ACTIVE_DATE,
					 CFL_PROD_CODE	,
					 CFL_CARD_TYPE	,
					 CFL_CUST_CATG	,
					 CFL_ACCT_ID	,
					 CFL_ACCT_NO	,
					 CFL_ERROR_MESG ,
					 CFL_RUN_USER   ,
					 CFL_RUN_DATE   ,
					 CFL_PROCESS_ID ,
 					 cfl_freq_key)  -- ajit 24 sep 03
				VALUES (
					instcode,
					x.cap_pan_code,
					x.cap_mbr_numb,
					v_cap_active_date,
					v_cap_prod_code,
					v_cap_card_type,
					v_cap_cust_catg,
					v_cap_acct_id,
					v_cap_acct_no,
					'ONETIME FEES '||errmsg,
					lupduser,
					SYSDATE,
					proid ,
					'O'  ); -- ajit 24 sep 03
		END IF;
		Errmsg := 'OK';
		END; -- End 2
	END LOOP;
	errmsg  := 'OK' ;
EXCEPTION
-- ajit 24 sep 03
	WHEN excp_no_data_found THEN -- Ashwini 11 July 05 - start
   BEGIN
      SELECT COUNT(*) INTO v_repin_reissue_cnt
      FROM CMS_SPPRT_FEE
      WHERE CSF_SPPRT_KEY IN ( 'REPIN', 'REISU' );

      IF v_repin_reissue_cnt > 0 THEN
         errmsg := 'OK';
      END IF;
   EXCEPTION WHEN OTHERS THEN
      errmsg := 'ONETIME FEES '||'Error in Repin and Reissue Count ! '||SQLERRM;
   END; -- Ashwini 11 July 05  - end
	--null;
	WHEN OTHERS THEN
		errmsg := 'ONETIME FEES '||'Error in Fee Calculation Process !!! '||SQLERRM;
END;
/


