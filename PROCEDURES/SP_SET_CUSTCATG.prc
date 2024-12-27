CREATE OR REPLACE PROCEDURE VMSCMS.SP_SET_CUSTCATG
				(prm_instcode	IN	NUMBER,
				 prm_custcatg	IN	VARCHAR2,
				 prm_ins_user	IN	NUMBER,
				 prm_catg_code	OUT	CMS_CUST_CATG.ccc_catg_code%type,
				 prm_err_msg	OUT	VARCHAR2
				)
IS
v_autoinsert_check	CMS_INST_PARAM.cip_param_value%type;
v_catgcode		CMS_CUST_CATG.ccc_catg_code%type;
v_custcatg_errmsg	VARCHAR2(300);
BEGIN			--<< MAIN BEGIN >>


				prm_err_msg := 'OK';
	--Sn check auto insert in inst mast
	BEGIN
		SELECT cip_param_value
		INTO   v_autoinsert_check
		FROM   CMS_INST_PARAM
		WHERE  cip_inst_code = prm_instcode
		AND    cip_param_key = 'ADD AUTO CUSTCATG';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_autoinsert_check := 'N';
		WHEN OTHERS THEN
			prm_err_msg := 'Error while creating customer catg data ' || substr(sqlerrm,1,150);
			RETURN;
	END;
	--Sn check auto insert in inst mast
	IF v_autoinsert_check = 'Y' THEN
		sp_create_custcatg 
				(	
					prm_instcode	,
					prm_custcatg    ,
					prm_custcatg    ,
					prm_ins_user	,
					v_catgcode	,
					v_custcatg_errmsg
				);
		IF v_custcatg_errmsg <> 'OK' THEN
		   prm_err_msg := 'Error while creating cust category ' || v_custcatg_errmsg;
		   RETURN;
		END IF;
		prm_catg_code := v_catgcode;
	ELSE 
		prm_err_msg := 'Customer category not present in master';
		RETURN;
	END IF;
EXCEPTION		--<< MAIN EXCEPTION >> 
	WHEN OTHERS THEN
	prm_err_msg := 'Error while creating customer catg data ' || substr(sqlerrm,1,150);
END;			--<< MAIN END>>
/


