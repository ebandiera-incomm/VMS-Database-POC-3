CREATE OR REPLACE PROCEDURE VMSCMS.sp_gen_pan_pcms_14May2010(prm_instcode				IN	NUMBER	,
								prm_applcode		        IN	NUMBER	,
								prm_lupduser		        IN	NUMBER	,
								prm_pan			        	OUT	VARCHAR2,
								prm_applprocess_msg			OUT	VARCHAR2,
								prm_errmsg 					OUT	VARCHAR2)
AS

v_inst_code  CMS_APPL_MAST.cam_inst_code%TYPE;
v_prod_code CMS_APPL_MAST.cam_prod_code%TYPE;
v_card_type CMS_APPL_MAST.cam_card_type%TYPE;
--v_errmsg VARCHAR2(300);
v_profile_code CMS_PROD_CATTYPE.cpc_profile_code%TYPE;
v_cpm_catg_code  CMS_PROD_MAST.cpm_catg_code%TYPE;
v_prod_prefix CMS_PROD_CATTYPE.cpc_prod_prefix%TYPE;
exp_reject_record EXCEPTION;

BEGIN
	prm_errmsg :='OK';
     BEGIN		--Begin 1 Block Starts Here
  			SELECT	cam_inst_code, 
				    cam_prod_code, 
				    cam_card_type
	  		INTO    v_inst_code, 
				    v_prod_code, 
				    v_card_type
      		FROM   CMS_APPL_MAST
  			WHERE CAM_INST_CODE = prm_instcode
			and cam_appl_code  = prm_applcode 
			AND	   cam_appl_stat  = 'A';
			
  		EXCEPTION	--Exception of Begin 1 Block
  			WHEN NO_DATA_FOUND THEN
  			prm_errmsg := 'No row found for application code'||prm_applcode ;
			RAISE	exp_reject_record;
  			WHEN OTHERS THEN
  			prm_errmsg := 'Error while selecting applcode from applmast'|| SUBSTR(SQLERRM,1,300);
			RAISE	exp_reject_record;
  		END;
		
			
	 BEGIN
	 	   IF v_prod_code IS NOT NULL AND v_card_type IS NOT NULL THEN
				SELECT	 cpm_catg_code 
				INTO	v_cpm_catg_code  
				FROM	CMS_PROD_CATTYPE , CMS_PROD_MAST
				WHERE	CPC_INST_CODE = prm_instcode
				and CPC_INST_CODE = CPM_INST_CODE
				AND	CPC_PROD_CODE = v_prod_code
				AND	CPC_CARD_TYPE = v_card_type
				AND cpm_prod_code = cpc_prod_code;
		   END IF;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
  			prm_errmsg := 'Catg code code not defined for product code '||v_prod_code || 'card type ' || v_card_type;
			RAISE	exp_reject_record;
  			WHEN OTHERS THEN
  			prm_errmsg := 'Error while selecting Catg code from CMS_PROD_MAST'|| SUBSTR(SQLERRM,1,300);
			RAISE	exp_reject_record;
		END;
		
		IF v_cpm_catg_code = 'D'
		THEN   
		 	   Sp_Gen_Pan_debit_Pcms(prm_instcode,
								prm_applcode,
								prm_lupduser,
								prm_pan,
								prm_applprocess_msg,
								prm_errmsg);
		ELSIF v_cpm_catg_code = 'P'
		THEN
				Sp_Gen_Pan_Prpid_Pcms(prm_instcode,
										prm_applcode,
										prm_lupduser,
										prm_pan,
										prm_applprocess_msg,
										prm_errmsg);  
		END IF;
		IF prm_errmsg != 'OK' THEN
		    RAISE exp_reject_record;
		END IF;
		
EXCEPTION 
WHEN exp_reject_record THEN 
	 prm_errmsg := prm_errmsg;
	 WHEN OTHERS THEN 
	 prm_errmsg :='Main Exception'||SUBSTR(SQLERRM,1,100);
END;
/


