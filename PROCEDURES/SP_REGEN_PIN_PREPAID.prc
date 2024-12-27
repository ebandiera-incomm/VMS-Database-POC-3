CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Regen_Pin_prepaid
	   	  		      (		prm_instcode		IN	NUMBER	,
						prm_pancode		IN	VARCHAR2	,
						prm_mbrnumb		IN	VARCHAR2	,
						prm_oldpinoff		IN	VARCHAR2	,
						prm_oldpindate		IN	DATE		,
						prm_rsncode		IN	NUMBER	,
						prm_remark		IN	VARCHAR2	,
						prm_lupduser		IN	NUMBER	,
						prm_workmode		IN	NUMBER ,
						prm_errmsg		OUT	VARCHAR2	)
AS
  v_mbrnumb									VARCHAR2(3)	;
  v_cap_prod_catg								VARCHAR2(2)	;
  v_cap_cafgen_flag								CHAR(1)		;
  pincnt									NUMBER(5)	;
  dum										NUMBER(1)	;
  issdate									DATE		;
  repindum									NUMBER(5)	;
  repindate									DATE		;
  reissuedum									NUMBER(5)	;
  reissuedate									DATE		;
  v_record_exist								CHAR(1):='Y'	;
  v_caffilegen_flag								CHAR(1):='N'	;
  v_issuestatus									VARCHAR2(3)	;
  v_pinmailer									VARCHAR2(3)	;
  v_cardcarrier									VARCHAR2(3)	;
  v_pinoffset									VARCHAR2(16)	;
  v_repin_gap									NUMBER		;
  v_rec_type									VARCHAR2(1)	;	-- Rahul 28 Sep 05
  v_hsm_mode									CHAR(1);		-- Rahul 05 oct 05
  v_rrn										VARCHAR2(200)	;
  v_delivery_channel								VARCHAR2(2)	;
  v_term_id									VARCHAR2(200)	;
  v_date_time									DATE;
  v_txn_code									VARCHAR2(2)	;
  v_txn_type									VARCHAR2(2)	;
  v_txn_mode									VARCHAR2(2)	;
  v_tran_date									VARCHAR2(200)	;
  v_tran_time									VARCHAR2(200)	;
  v_txn_amt									NUMBER		;
  v_card_no									CMS_APPL_PAN.cap_pan_code%TYPE;
  v_resp_code									VARCHAR2(200)	;
  v_resp_msg									VARCHAR2(200)	;
  v_errmsg											VARCHAR2(300);
  v_capture_date    DATE;
  exp_reject_record								EXCEPTION;
BEGIN				-- << MAIN BEGIN >>
prm_errmsg := 'OK';
	v_rrn			:= '654321';
	v_delivery_channel	:= '05';
	v_term_id		:= NULL;
	v_date_time		:= NULL;
	v_txn_code		:= 'SP';
	v_txn_type		:= '1';
	v_txn_mode		:= '0';
	v_tran_date		:=TO_CHAR ( SYSDATE , 'yyyymmdd')   ;   -- '20080723';
	v_tran_time		:= TO_CHAR( SYSDATE , 'HH24:MI:SS')  ;    --'16:21:10';
	v_card_no		:= prm_pancode ;
	v_txn_amt		:= 0;
	--Sn find the HSM parameter
	BEGIN
			  SELECT CIP_PARAM_VALUE
			  INTO v_hsm_mode
			  FROM CMS_INST_PARAM
			  WHERE CIP_PARAM_KEY='HSM_MODE';
	EXCEPTION
			  WHEN NO_DATA_FOUND THEN
			  v_hsm_mode:='N';
	END;
	--En find the HSM parameter
	IF	prm_mbrnumb IS NULL  THEN
		v_mbrnumb := '000';
	ELSE
		v_mbrnumb := prm_mbrnumb;
 	END IF;
	-- Sn Repin Gap Parameter From parameter table.
	BEGIN
	 SELECT  TO_NUMBER(cip_param_value)
	 INTO    v_repin_gap
	 FROM    CMS_INST_PARAM
	 WHERE   cip_inst_code = prm_instcode
	 AND     cip_param_key = 'PIN REGEN GAP';
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
	v_errmsg := 'Pin regen gap is not defined in the master';
	RAISE exp_reject_record;
	END;
     -- En Repin Gap Parameter From parameter table.
     --Sn select max regen date
	BEGIN
		SELECT	MAX(cph_new_pindate)
		INTO	repindate
		FROM 	CMS_PINREGEN_HIST
		WHERE	cph_pan_code = prm_pancode;
		 -- If There is no Last Repin Request select issuance date for this card
		 IF repindate IS NULL THEN
		     SELECT CAP_INS_DATE
			 INTO   issdate
			 FROM  CMS_APPL_PAN
			 WHERE CAP_PAN_CODE =  prm_pancode
			 AND CAP_MBR_NUMB = v_mbrnumb ;
		 END IF;
	END;
    --En select max regen date
    --Sn call to authorization
	Sp_Authorize_Txn ( V_RRN, V_DELIVERY_CHANNEL, V_TERM_ID, V_DATE_TIME,
				  		   		  					  V_TXN_CODE, V_TXN_TYPE, V_TXN_MODE, V_TRAN_DATE, V_TRAN_TIME,
				  									  V_CARD_NO, NULL, NULL, NULL,
				  									  NULL, V_TXN_AMT, NULL, NULL, NULL,
				  									  NULL, NULL, NULL, NULL, NULL, NULL,
				  									  NULL, NULL, NULL, NULL,
				  									  NULL, NULL, NULL, NULL,
				  									  NULL,NULL, V_RESP_CODE, V_RESP_MSG , v_capture_date  );
		IF  V_RESP_CODE <> '00' THEN
		v_errmsg := V_RESP_MSG;
		RAISE exp_reject_record;
		END IF;
    --En call to authorization
    IF ((TRUNC(SYSDATE) - TRUNC(repindate)) > v_repin_gap) OR
	   		((TRUNC(SYSDATE) - TRUNC(issdate)) > v_repin_gap) OR
			 (v_repin_gap=0) THEN --REPIN date IF
				-- Select Card Type for this card

				BEGIN		--begin 1 starts
					SELECT 	cap_prod_catg,
						cap_cafgen_flag
					INTO	v_cap_prod_catg,
						v_cap_cafgen_flag
					FROM	CMS_APPL_PAN
					WHERE	cap_pan_code = prm_pancode
					AND	cap_mbr_numb = v_mbrnumb;
				EXCEPTION	--excp of begin 1
					WHEN NO_DATA_FOUND THEN
						v_errmsg := 'No such PAN found.'||prm_pancode;
						RAISE exp_reject_record;
					WHEN OTHERS THEN
						v_errmsg := 'Excp 1 PAN -- '||prm_pancode||' '||SQLERRM;
						RAISE exp_reject_record;
				END;		--begin 1 ends

				-- IF First Time caf is also not generated for this card
				-- Reject the pin Regeneration Request else proceed.
				IF  v_cap_cafgen_flag = 'N' THEN	--cafgen if
					v_errmsg := 'CAF has to be generated atleast once for this pan'||prm_pancode;
					RAISE exp_reject_record;
				ELSE
						BEGIN		--begin 2 starts
						  -- Select Pin Generation Count For this Card,
						  SELECT cct_ctrl_numb
						  INTO	pincnt
						  FROM	CMS_CTRL_TABLE
						  WHERE	cct_ctrl_code	= prm_pancode||v_mbrnumb
						  AND	cct_ctrl_key	= 'REPIN'
						  FOR	UPDATE;
						  -- If Records is there in ctrl table means
						  -- it is not a first request
						  -- so Add Entry in History table for this Pin Request.
						  INSERT INTO CMS_PINREGEN_HIST(
							  CPH_INST_CODE	  ,CPH_PAN_CODE	   ,CPH_MBR_NUMB,
							  CPH_OLD_PINOFST ,CPH_OLD_PINDATE ,CPH_REGEN_CNT	,
							  CPH_NEW_PINDATE ,CPH_INS_USER	   ,CPH_LUPD_USER)
						  VALUES(
						  	  prm_instcode		  ,prm_pancode		   ,v_mbrnumb,
							  prm_oldpinoff		  ,prm_oldpindate	   ,pincnt,
						  	  SYSDATE		  ,prm_lupduser		   ,prm_lupduser);
			  			  -- update pan spprt
						  -- in cms_pan_spprt
						  UPDATE CMS_PAN_SPPRT
						  SET	cps_lupd_user = prm_lupduser ,
						  CPS_CMD_MODE	= prm_workmode
						  WHERE	cps_inst_code = prm_instcode
						  AND	cps_pan_code  = prm_pancode
						  AND	cps_mbr_numb  =	v_mbrnumb
						  AND	cps_spprt_key =	'REPIN';
			  			  -- Increment Repin Count by 1 in control table.
						  UPDATE CMS_CTRL_TABLE
						  SET	cct_ctrl_numb =	cct_ctrl_numb+1,
						  cct_lupd_user = prm_lupduser
						  WHERE	cct_ctrl_code = prm_pancode||v_mbrnumb
						  AND	cct_ctrl_key  = 'REPIN';
						EXCEPTION	--excp of begin 2
						  -- If no_data_found excpetion means there is no
						  -- entry in control table and this is first Repin Request
				  		  WHEN NO_DATA_FOUND THEN
						  	   -- Insert Entry if Histry Table.
							   INSERT INTO CMS_PINREGEN_HIST(
								CPH_INST_CODE		,
								CPH_PAN_CODE		,
								CPH_MBR_NUMB		,
								CPH_OLD_PINOFST	,
								CPH_OLD_PINDATE	,
								CPH_REGEN_CNT	,
								CPH_NEW_PINDATE	,
								CPH_INS_USER		,
								CPH_LUPD_USER		)
							  VALUES(prm_instcode		,
								prm_pancode		,
								v_mbrnumb	,
								prm_oldpinoff		,
								prm_oldpindate	,
								1	,
								SYSDATE		,
								prm_lupduser		,
								prm_lupduser	);
				 			  -- Insert New Entry in Cms_pan_spprt
							  INSERT INTO CMS_PAN_SPPRT(
								CPS_INST_CODE		,
								CPS_PAN_CODE		,
								CPS_MBR_NUMB		,
								CPS_PROD_CATG	,
								CPS_SPPRT_KEY		,
								CPS_SPPRT_RSNCODE,
								CPS_FUNC_REMARK	,
								CPS_INS_USER		,
								CPS_LUPD_USER,CPS_CMD_MODE		)
							  VALUES	(prm_instcode		,
								prm_pancode		,
								v_mbrnumb	,
								v_cap_prod_catg	,
								'REPIN'			,
								prm_rsncode		,
								prm_remark		,
								prm_lupduser		,
								prm_lupduser,
								prm_workmode);
							  -- Insert First Time Entry in Control Table.
							  INSERT INTO CMS_CTRL_TABLE(
								CCT_CTRL_CODE	,
								CCT_CTRL_KEY		,
								CCT_CTRL_NUMB		,
								CCT_CTRL_DESC	,
								CCT_INS_USER		,
								CCT_LUPD_USER)
							  VALUES (prm_pancode||v_mbrnumb				,
								'REPIN',
								2								,
								'Regen cnt for PAN'||prm_pancode			,
								prm_lupduser,
								prm_lupduser);
			  			WHEN OTHERS THEN
							v_errmsg := 'Error from pin gen ' || SUBSTR(SQLERRM,1,200);
							RAISE exp_reject_record;
						END;
				END IF;  --pankaj1

				IF v_errmsg = 'OK' THEN

				BEGIN		--Begin 3
										DELETE FROM CMS_CAF_INFO
										WHERE	cci_inst_code  =prm_instcode
										AND	cci_pan_code   =RPAD(prm_pancode,19,' ')
										AND	cci_mbr_numb   = v_mbrnumb;
										--call the procedure to insert into cafinfo
										Sp_Caf_Rfrsh(prm_instcode,prm_pancode,prm_mbrnumb,SYSDATE,'C',NULL,'REPIN',prm_lupduser,v_errmsg);
										-- Rahul 1 apr 05 Update caf_info only if record was exist earlier
										IF v_errmsg != 'OK' THEN
										   v_errmsg := 'From caf refresh -- '||v_errmsg;
										   			RAISE exp_reject_record;
											ELSIF v_errmsg='OK' THEN
						-- if hsm mode is on then just make pingen_flag in cms_appl_pan as 'Y' i.e. generate pin.......' -- rahul 01 oct 05
						   IF  v_hsm_mode='Y' THEN
							 UPDATE CMS_APPL_PAN SET cap_pin_flag='Y'
							 WHERE cap_inst_code= prm_instcode
							 AND cap_pan_code=prm_pancode
							 AND cap_mbr_numb= v_mbrnumb ;
							 IF SQL%rowcount = 0 THEN
								v_errmsg := 'No Record found in PAN master';
								RAISE exp_reject_record;
							 END IF;
						END IF;
					END IF;
				EXCEPTION	--Excp 3
				WHEN exp_reject_record THEN
				RAISE;
				WHEN OTHERS THEN
					v_errmsg := 'Error while inserting record in CAF ' || SUBSTR(SQLERRM,1,200);
					RAISE exp_reject_record;
				END;		--End of begin 3

		END IF ;	--cafgen if.


	ELSE -- Since Last Repin Date is less than gap parameter.
		v_errmsg := 'The Card should have a gap of '||v_repin_gap|| ' days from repin generation';
		RAISE exp_reject_record;
	END IF; --REPIN DATE IF
EXCEPTION			--<< MAIN EXCEPTION >>
WHEN exp_reject_record THEN
prm_errmsg := v_errmsg;
WHEN OTHERS THEN
	prm_errmsg := 'Main Exception -- '||SQLERRM;
END;				--<<MAIN END >>
/


