CREATE OR REPLACE PROCEDURE VMSCMS.SP_ATTACH_CUSTCATG
				(prm_instcode		IN	NUMBER,
				 prm_custcatgcode	IN	CMS_CUST_CATG.ccc_catg_code%type,
				 prm_prod_code		IN	CMS_PROD_MAST.cpm_prod_code%type,
				 prm_prod_cattype	IN	CMS_PROD_CATTYPE.cpc_card_type%type,
				 prm_ins_user		IN	NUMBER,
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
		--Sn create a record in prod ccc
			BEGIN
				INSERT INTO cms_prod_ccc
                                    (cpc_inst_code, cpc_cust_catg,
                                     cpc_card_type, cpc_prod_code,
                                     cpc_ins_user, cpc_ins_date,
                                     cpc_lupd_user, cpc_lupd_date,
                                     cpc_vendor, cpc_stock, cpc_prod_sname
                                    )
                             VALUES (prm_instcode, prm_custcatgcode,
                                     prm_prod_cattype,prm_prod_code,
                                     prm_ins_user, SYSDATE,
                                     prm_ins_user, SYSDATE,
                                     null, null, 'Default'
                                    );
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
				prm_err_msg := 'Duplicate record found while creating product and customer data';
				RETURN;
				WHEN OTHERS THEN
				prm_err_msg := 'Error while creating customer, product  relationship' || substr(sqlerrm,1,150);
				RETURN;
			END;
		--En create a record in prod ccc
	ELSE 
		prm_err_msg := 'Customer category is not attached to product';
		RETURN;
	END IF;
EXCEPTION		--<< MAIN EXCEPTION >> 
	WHEN OTHERS THEN
	prm_err_msg := 'Error while creating creating customer, product  relationship ' || substr(sqlerrm,1,150);
END;			--<< MAIN END>>
/


show error