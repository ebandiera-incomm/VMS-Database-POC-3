CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Regen_Pin_Debit (
   prm_instcode     IN       NUMBER,
   prm_pancode      IN       VARCHAR2,
   prm_mbrnumb      IN       VARCHAR2,
   prm_oldpinoff    IN       VARCHAR2,
   prm_oldpindate   IN       DATE,
   prm_remark       IN       VARCHAR2,
   prm_rsncode      IN       NUMBER,
   prm_workmode     IN       NUMBER,
   prm_pinprocess   IN       VARCHAR2,
   prm_lupduser     IN       NUMBER,
   prm_errmsg       OUT      VARCHAR2
)
AS
   --v_mbrnumb           VARCHAR2 (3);
   v_cap_prod_catg     VARCHAR2 (2);
   v_cap_cafgen_flag   CHAR (1);
   v_pincnt            NUMBER (5);
   dum                 NUMBER (1);
   issdate             DATE;
   repindum            NUMBER (5);
   v_repindate           DATE;
   reissuedum          NUMBER (5);
   reissuedate         DATE;
   --v_record_exist      CHAR (1)  := 'Y';
   v_caffilegen_flag   CHAR (1)  := 'N';
   v_issuestatus       VARCHAR2 (3);
   v_pinmailer         VARCHAR2 (3);
   v_cardcarrier       VARCHAR2 (3);
   v_pinoffset         VARCHAR2 (16);
   v_repin_gap         NUMBER;
   v_rec_type          VARCHAR2 (1);                       
   v_hsm_mode          CHAR (1);                           
   v_cardstat          CHAR (1);                                    
   v_cafrecord_exist   VARCHAR2(1) DEFAULT 'Y';
   dum1                 NUMBER;
   v_tran_code	        VARCHAR2(2);
   v_tran_mode	        VARCHAR2(1);
   v_tran_type	        VARCHAR2(1);
   v_delv_chnl	        VARCHAR2(2);
   v_feetype_code	      CMS_FEE_MAST.cfm_feetype_code%TYPE;
   v_fee_code		        CMS_FEE_MAST.cfm_fee_code%TYPE;
   v_fee_amt		        NUMBER(4);
   v_cust_code		      CMS_CUST_MAST.ccm_cust_code%TYPE;
   v_acct_id		        CMS_APPL_PAN.cap_acct_id%TYPE;
   v_acct_no		        CMS_APPL_PAN.cap_acct_no%TYPE;
   v_issue_date		      CMS_APPL_PAN.cap_ins_date%TYPE;
   v_card_stat		      CMS_APPL_PAN.cap_card_stat%type;
   v_pinflag_update	    CHAR(1);
   v_insta_check             CMS_INST_PARAM.cip_param_value%type;
 v_hash_pan	CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan	CMS_APPL_PAN.cap_pan_code_encr%TYPE;   
   
BEGIN			--<< MAIN BEGIN >>
	 prm_errmsg:= 'OK';
   
--SN CREATE HASH PAN 
BEGIN
	v_hash_pan := Gethash(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
	RETURN;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
	v_encr_pan := Fn_Emaps_Main(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
	RETURN;
END;
--EN create encr pan
  
	--Sn select HSM parameter
	BEGIN
		SELECT	cip_param_value
		INTO	v_hsm_mode
		FROM	CMS_INST_PARAM
		WHERE	cip_param_key = 'HSM_MODE'
		AND		cip_inst_code = prm_instcode;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		v_hsm_mode := 'N';
		WHEN OTHERS THEN       
		prm_errmsg := 'Error while selecting HSM detail ' || substr(sqlerrm,1,200);
		RETURN;
	END;
	--En select HSM parameter
	--Sn get tansaction detail
	BEGIN
		SELECT		cfm_txn_code, 
				cfm_txn_mode, 
				cfm_delivery_channel, 
				cfm_txn_type
		INTO		v_tran_code, 
				v_tran_mode, 
				v_delv_chnl, 
				v_tran_type
		FROM		CMS_FUNC_MAST
	       WHERE		cfm_func_code = 'REPIN'
	       AND		cfm_inst_code = prm_instcode;
      EXCEPTION
	      WHEN OTHERS
	      THEN
		 prm_errmsg :=
			   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
		 RETURN;
      END;
      --En get tansaction detail
	--Sn get PAN parameters
	BEGIN
		SELECT	cap_card_stat,
			cap_prod_catg, 
			cap_cafgen_flag,
			cap_cust_code,
			cap_acct_no,
			cap_ins_date
		INTO	v_card_stat,
			v_cap_prod_catg, 
			v_cap_cafgen_flag,
			v_cust_code,
			v_acct_no,
			v_issue_date
		FROM	CMS_APPL_PAN
		WHERE	cap_inst_code = prm_instcode
		AND	cap_pan_code  = v_hash_pan ; --prm_pancode;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		prm_errmsg := 'Card number not found in master';
		RETURN;
		WHEN OTHERS THEN
		prm_errmsg := 'Error while selecting card detail ' || substr(sqlerrm,1,200);
		RETURN;
	END;
	--En get PAN parameters
	--Sn check card status
	IF v_card_stat <> '1' THEN
		prm_errmsg := 'Invalid card status for repin ';
		RETURN;
	END IF;
  
  ----------Sn start insta card check----------  /*added by amit on 24 Sep'10 for not to allow any supprt func on insta card.*/
   BEGIN 
     select cip_param_value
     into v_insta_check
     from cms_inst_param
     where cip_param_key='INSTA_CARD_CHECK'
     and cip_inst_code=prm_instcode;
   
   IF v_insta_check ='Y' THEN
      sp_gen_insta_check(
                        v_acct_no,
                        v_card_stat,
                        prm_errmsg
                      );
      IF prm_errmsg <>'OK' THEN
         RETURN;
      END IF;
    END IF;
   
   EXCEPTION WHEN OTHERS THEN
   prm_errmsg:='Error while checking the instant card validation. '||substr(sqlerrm,1,200);
   return;
   END;
  ----------En start insta card check----------  
  
	 IF  v_cap_cafgen_flag = 'N'
            THEN                                                   --cafgen if
               prm_errmsg:='CAF has to be generated atleast once for this pan'|| prm_pancode;
	       RETURN;
	 END IF;
	--En check card status
	--Sn find regeneration gap
	 BEGIN
		SELECT  TO_NUMBER (cip_param_value)
		INTO	v_repin_gap
		FROM	CMS_INST_PARAM
		WHERE	cip_inst_code = prm_instcode 
		AND	cip_param_key = 'PIN REGEN GAP';
        EXCEPTION 
        WHEN NO_DATA_FOUND THEN
		prm_errmsg:='Repin gap parameter not found';
		RETURN;
        WHEN OTHERS THEN
		prm_errmsg:='Error while selecting repin gap parameter'||substr(SQLERRM,1,200);
		RETURN;
        END;
	--En find regeneration gap
	--Sn find last repin date
	BEGIN
		SELECT	MAX (cph_new_pindate)
		INTO	v_repindate
		FROM	CMS_PINREGEN_HIST
		WHERE	cph_pan_code  = v_hash_pan --prm_pancode 
		AND	cph_inst_code = prm_instcode;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          	 v_repindate := NULL;
        WHEN OTHERS THEN
		prm_errmsg:='Error while selecting repin date'||substr(SQLERRM,1,200);
		RETURN;
        end;
	--En find last repin date
	 IF prm_pinprocess = 'S'
         THEN
            v_repin_gap := 0;
         END IF;
	--Sn repin gap with last repin gen date
	  IF										--Calc fee If
		((TRUNC (SYSDATE) - TRUNC (v_repindate )) > v_repin_gap)
		OR ((TRUNC (SYSDATE) - TRUNC (v_issue_date)) > v_repin_gap)
		OR (v_repin_gap = 0)
         THEN    
		--Sn calculate fees
			Sp_Calc_Fees_Offline_Debit
			      (
			       prm_instcode    ,
			       prm_pancode,
			       v_tran_code ,
			       v_tran_mode ,
			       v_delv_chnl ,
			       v_tran_type ,
			       v_feetype_code,
			       v_fee_code,
			       v_fee_amt,
			       prm_errmsg
			       );
		 IF  prm_errmsg <> 'OK' THEN
                   RETURN;
		 END IF; 
		--En calculate fees
		--Sn fee amt > 0
		IF  v_fee_amt > 0 THEN
			--Sn INSERT A RECORD INTO CMS_CHARGE_DTL
				BEGIN
					 INSERT INTO CMS_CHARGE_DTL
					 			 (
						  CCD_INST_CODE     ,
						  CCD_FEE_TRANS     ,
						  CCD_PAN_CODE      ,
						  CCD_MBR_NUMB      ,
						  CCD_CUST_CODE     ,
						  CCD_ACCT_ID       ,
						  CCD_ACCT_NO       , 
						  CCD_FEE_FREQ      ,
						  CCD_FEETYPE_CODE  ,
						  CCD_FEE_CODE      ,
						  CCD_CALC_AMT      ,
						  CCD_EXPCALC_DATE  ,
						  CCD_CALC_DATE     ,
						  CCD_FILE_DATE     ,
						  CCD_FILE_NAME     ,
						  CCD_FILE_STATUS   ,
						  CCD_INS_USER      ,
						  CCD_INS_DATE      ,
						  CCD_LUPD_USER     ,
						  CCD_LUPD_DATE     ,
						  CCD_PROCESS_ID    ,
						  CCD_PLAN_CODE   ,
              CCD_PAN_CODE_encr
						 )
					VALUES
						(  
						prm_instcode,
						NULL,
						--prm_pancode
                        v_hash_pan,
						prm_mbrnumb,
						v_cust_code,
						v_acct_id,
						v_acct_no,
						'R',
						v_feetype_code,
						v_fee_code,
						v_fee_amt,
						SYSDATE,
						SYSDATE,
						NULL,
						NULL,
						NULL,
						prm_lupduser,
						SYSDATE,
						prm_lupduser,
						SYSDATE,
						NULL,
						NULL,
            v_encr_pan
								);
			EXCEPTION
				WHEN OTHERS THEN				
				 prm_errmsg:= ' Error while inserting into charge detail ' || SUBSTR(SQLERRM,1,200);
				RETURN;
			END;				
		 --En INSERT A RECORD INTO CMS_CHARGE_DTL
		  --En fee amt > 0
		END IF;
		--SN FIND PIN COUNT 
		BEGIN                                       
			SELECT     cct_ctrl_numb
                        INTO	   v_pincnt
                        FROM	   CMS_CTRL_TABLE
                        WHERE	   cct_ctrl_code = prm_pancode || prm_mbrnumb
                        AND        cct_ctrl_key = 'REPIN'
                        AND	   cct_inst_code = prm_instcode
			FOR UPDATE;
			--Sn update control number
				BEGIN
					UPDATE	CMS_CTRL_TABLE
					SET	cct_ctrl_numb = cct_ctrl_numb + 1,
						cct_lupd_user = prm_lupduser
					WHERE	cct_ctrl_code = prm_pancode || prm_mbrnumb
					AND	cct_ctrl_key = 'REPIN'
					AND	cct_inst_code = prm_instcode;
					IF sql%rowcount = 0 THEN
						prm_errmsg:= ' Error while updating record in pin gen count master  ' || SUBSTR(SQLERRM,1,200);
						RETURN;
					END IF;
				EXCEPTION
				WHEN OTHERS THEN				
					prm_errmsg:= ' Error while updating record in pin gen count master  ' || SUBSTR(SQLERRM,1,200);
					RETURN;
				END;
			--En update control number
                EXCEPTION
			WHEN NO_DATA_FOUND THEN
			v_pincnt := 1;
			INSERT INTO CMS_CTRL_TABLE(
			    CCT_INST_CODE,
				CCT_CTRL_CODE	,
				CCT_CTRL_KEY	,
				CCT_CTRL_NUMB	,
				CCT_CTRL_DESC	,
				CCT_INS_USER	,
				CCT_LUPD_USER)
			VALUES (
			     prm_instcode,
				 prm_pancode||prm_mbrnumb,
				'REPIN',
				 2,
				'Regen cnt for PAN'||prm_pancode,
				 PRM_LUPDUSER,
				 PRM_LUPDUSER
				);
			WHEN OTHERS THEN
			prm_errmsg:= ' Error while creating record in pin gen cnt master ' || SUBSTR(SQLERRM,1,200);
			RETURN;
		END;
		--En FIND PIN COUNT
		--Sn create a record in pan support
		 BEGIN
                        INSERT INTO CMS_PAN_SPPRT
					(cps_inst_code, 
					 cps_pan_code,
					 cps_mbr_numb, 
					 cps_prod_catg,
					 cps_spprt_key, 
					 cps_spprt_rsncode,
					 cps_func_remark, 
					 cps_ins_user,
					 cps_lupd_user, 
					 cps_cmd_mode,
           cps_pan_code_encr
                                    )
                             VALUES (	 prm_instcode, 
					-- prm_pancode
           v_hash_pan,
					 prm_mbrnumb, 
					 v_cap_prod_catg,
					 'REPIN', 
					 prm_rsncode,
					 prm_remark, 
					 prm_lupduser,
					 prm_lupduser, 
					 prm_workmode,
                        v_encr_pan            );
                  EXCEPTION 
                       when others then
                        prm_errmsg:='Error while creating data in card support master'||substr(SQLERRM,1,200);
                        return;
                  END;
		--En create a record in pan support
		--Sn create record in history table
		  BEGIN
                        INSERT INTO CMS_PINREGEN_HIST
						(cph_inst_code, 
						 cph_pan_code,
						 cph_mbr_numb, 
						 cph_old_pinofst,
						 cph_old_pindate, 
						 cph_regen_cnt,
						 cph_new_pindate, 
						 cph_ins_user,
						 cph_lupd_user,
             cph_pan_code_encr
						)
				VALUES		(prm_instcode, 
						 --prm_pancode
             v_hash_pan,
						 prm_mbrnumb, 
						 prm_oldpinoff,
						 prm_oldpindate, 
						 v_pincnt,
						 SYSDATE, 
						 prm_lupduser,
						 prm_lupduser,
             v_encr_pan
						);
                   EXCEPTION 
                       WHEN OTHERS THEN
                        prm_errmsg:='Error while inserting data in PINREGEN HIST'||substr(SQLERRM,1,200);
                        return;
                   END;
		--En create a record in history table
		--Sn get pin update flag
		   BEGIN
			sp_get_upd_pinflag
				(
				prm_instcode ,
				v_pinflag_update,
				prm_errmsg
				);
			IF prm_errmsg <> 'OK' THEN
				RETURN;
			END IF;
		  EXCEPTION
		  WHEN OTHERS THEN
			 prm_errmsg:='Error while getting PIN update flag'||substr(SQLERRM,1,200);
                         return;
		  END;
		--En get pin update flag
		 IF  v_hsm_mode='Y' AND v_pinflag_update = 'Y' THEN 
		 BEGIN
			 UPDATE CMS_APPL_PAN 
			 SET	cap_pin_flag='Y'
			 WHERE	cap_inst_code= prm_instcode
			 AND	cap_pan_code = v_hash_pan --prm_pancode
             AND    cap_mbr_numb = prm_mbrnumb ;
            IF SQL%rowcount = 0 THEN
            prm_errmsg := 'No Record found in PAN master';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
            prm_errmsg := 'Error while updating PIN generation flag ' || substr(sqlerrm,1,200);
            RETURN;
        END;
        END IF;
        -- Sn create CAF
        v_cafrecord_exist := 'Y';
             BEGIN
            SELECT    cci_crd_stat
                        INTO    v_cardstat
                        FROM    CMS_CAF_INFO
                        WHERE    cci_inst_code = prm_instcode
                        AND    cci_pan_code = v_hash_pan --DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                                       --19,prm_pancode)
                    AND    cci_mbr_numb = prm_mbrnumb
                        AND    cci_file_gen = 'N';                   
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_cafrecord_exist := 'N';
                     END;
             BEGIN
            DELETE FROM CMS_CAF_INFO
                        WHERE cci_inst_code = prm_instcode
                        AND cci_pan_code    = v_hash_pan --DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                                         -- 19,prm_pancode)
                        AND cci_mbr_numb = prm_mbrnumb;
             EXCEPTION
            WHEN OTHERS THEN
            prm_errmsg := 'Error while deleting CAF data ' || substr(sqlerrm,1,200);
            RETURN;
             END;
             BEGIN
            Sp_Caf_Rfrsh (prm_instcode,
                                  -- prm_pancode,
                                   prm_pancode,
                                   prm_mbrnumb,
                                   SYSDATE,
                                   'C',
                                   NULL,
                                   'REPIN',
                                   prm_lupduser,
                                   prm_pancode,
                                   prm_errmsg
                                  );
            IF prm_errmsg <> 'OK' THEN
                RETURN;
            END IF;
            EXCEPTION
            WHEN OTHERS THEN
            prm_errmsg := 'Error while generating CAF data ' || substr(sqlerrm,1,200);
            RETURN;
            END;
        --En create CAF
        --Sn update CAF
         IF v_cafrecord_exist = 'Y'
                     THEN
                        UPDATE CMS_CAF_INFO
                           SET cci_crd_stat = v_cardstat
                         WHERE cci_inst_code = prm_instcode
                           AND cci_pan_code = v_hash_pan-- DECODE(LENGTH(prm_pancode), 16,prm_pancode || '   ',
                                          -- 19,prm_pancode)
                           AND cci_mbr_numb = prm_mbrnumb;
                 END IF;
        --En update CAF
    ELSE                                        --Calc fee Else                                    
    prm_errmsg:=
                  'The Card should have a gap of '
                        || v_repin_gap
                        || ' days from last repin generation';
          END IF;                                        --Calc fee End if
    --En repin gap with last repin gen date 
EXCEPTION        --<< MAIN EXCEPTION >>
    WHEN OTHERS THEN
    prm_errmsg:= 'Error from main' || substr(sqlerrm,1,200);
    RETURN;
END;            --<< MAIN END >>
/


SHOW ERRORS