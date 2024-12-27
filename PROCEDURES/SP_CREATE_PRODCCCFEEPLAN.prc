CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Prodcccfeeplan(
				instcode		IN	NUMBER	,
				custcatg		IN	NUMBER	,
				prodcode		IN	VARCHAR2,
				cardtype		IN	NUMBER	,
				plancode		IN	VARCHAR2	,
				validfrom		IN	DATE	,
				validto			IN	DATE	,
				flowsource		IN	VARCHAR2,
				--citycatg		IN	VARCHAR2,
				cardposn		IN	NUMBER  ,
				--custtype 		IN	NUMBER  ,
				lupduser		IN	NUMBER	,
				errmsg			OUT	 VARCHAR2)
IS
excp_feeplan_attach		EXCEPTION;
DUMMY				NUMBER := 0;
v_plan_code			CMS_FEEPLAN_MAST.CFM_PLAN_CODE%TYPE;
v_seq_id			CMS_PRODCCC_FEEPLAN.cpf_seq_id%TYPE;
CURSOR cur_fee_1 IS
	SELECT	cpf_seq_id
	FROM	CMS_PRODCCC_FEEPLAN
	WHERE	cpf_inst_code = instcode
	AND	cpf_prod_code = prodcode
	AND	cpf_card_type = cardtype
	AND	cpf_cust_catg =	custcatg
	--AND	CPF_CITY_CATG = citycatg
	AND	CPF_CARD_POSN = cardposn
	--AND 	CPF_CUST_TYPE = custtype
	AND	CPF_VALID_FROM < validfrom
	AND	CPF_VALID_TO >= validfrom;
BEGIN
	BEGIN	--begin 1
		SELECT	1
		INTO	DUMMY
		FROM	CMS_FEEPLAN_MAST
		WHERE	cfm_inst_code =  instcode
		AND	cfm_plan_code  =  plancode;
	EXCEPTION	--excp of begin 1
		WHEN NO_DATA_FOUND THEN
			errmsg	:= 'No such Fee Plan exists in the system!!!';
			RAISE excp_feeplan_attach;
		WHEN OTHERS THEN
			errmsg := 'Excp 1 -- '||SQLERRM;
			RAISE excp_feeplan_attach;
		END;	--end of begin 1
	BEGIN	--begin 2
		SELECT	1
		INTO	DUMMY
		FROM	CMS_PROD_CCC
		WHERE	cpc_inst_code = instcode
		AND	cpc_prod_code = prodcode
		AND	cpc_card_type = cardtype
		AND	cpc_cust_catg =	custcatg
		AND ROWNUM =  1 ;                -- ONLY FOR VALIDATION OF PRODUCT AJIT 23 SEP 03
	EXCEPTION	--excp of begin 2
		WHEN NO_DATA_FOUND THEN
			--COMMENTED AND CHANGED BY CHRISTOPHER ON 16JUN04
			--errmsg	:= 'No such Product exists in the system !!!';
			errmsg	:= 'No such Interchange exists in the system !!!';
			RAISE excp_feeplan_attach;
		WHEN OTHERS THEN
			errmsg := 'Excp 2 -- '||SQLERRM;
			RAISE excp_feeplan_attach;
	END;	--end of begin 1
	BEGIN
		IF (validto < validfrom) THEN
			errmsg := 'TO DATE SHOULD BE GREATER THAN OR EQUAL TO FROM DATE !!!';
			RAISE excp_feeplan_attach;
		ELSIF (validfrom < TRUNC(SYSDATE)) THEN
			errmsg := 'FROM DATE ENTERED SHOULD BE GREATER THAN TODAYs DATE !!!';
			RAISE excp_feeplan_attach;
		END IF;
		INSERT INTO CMS_PRODCCC_FEEPLAN_HIST(
						CPF_INST_CODE  ,
						CPF_CUST_CATG  ,
						CPF_CARD_TYPE  ,
						CPF_PROD_CODE  ,
						CPF_PLAN_CODE  ,
						--CPF_CITY_CATG  ,
						CPF_CARD_POSN  ,
						CPF_VALID_FROM ,
						CPF_VALID_TO   ,
						CPF_FLOW_SOURCE,
						CPF_CUST_TYPE  ,
						CPF_INS_USER   ,
						CPF_INS_DATE   ,
						CPF_LUPD_USER  ,
						CPF_LUPD_DATE  ,
						CPF_SEQ_ID     ,
						CPF_RECORD_DATE)
					SELECT	CPF_INST_CODE  ,
						CPF_CUST_CATG  ,
						CPF_CARD_TYPE  ,
						CPF_PROD_CODE  ,
						CPF_PLAN_CODE  ,
						--CPF_CITY_CATG  ,
						CPF_CARD_POSN  ,
						CPF_VALID_FROM ,
						CPF_VALID_TO   ,
						CPF_FLOW_SOURCE,
						CPF_CUST_TYPE  ,
						CPF_INS_USER   ,
						CPF_INS_DATE   ,
						CPF_LUPD_USER  ,
						CPF_LUPD_DATE  ,
						CPF_SEQ_ID     ,
						SYSDATE
					FROM	CMS_PRODCCC_FEEPLAN
					WHERE	cpf_inst_code = instcode
					AND	cpf_prod_code = prodcode
					AND	cpf_card_type = cardtype
					AND	cpf_cust_catg =	custcatg
					--AND	CPF_CITY_CATG = citycatg
					AND	CPF_CARD_POSN = cardposn
					--AND	CPF_CUST_TYPE = custtype
					AND	validfrom <= CPF_VALID_FROM
					AND	validto	>= CPF_VALID_FROM;
			DELETE
			FROM	CMS_PRODCCC_FEEPLAN
			WHERE	cpf_inst_code = instcode
			AND	cpf_prod_code = prodcode
			AND	cpf_card_type = cardtype
			AND	cpf_cust_catg =	custcatg
			--AND	CPF_CITY_CATG = citycatg
			AND	CPF_CARD_POSN = cardposn
			--AND 	CPF_CUST_TYPE = custtype
			AND	validfrom <= CPF_VALID_FROM
			AND	validto	>= CPF_VALID_FROM;
		FOR x IN cur_fee_1 LOOP
			BEGIN
				UPDATE	CMS_PRODCCC_FEEPLAN
				SET	CPF_VALID_TO = validfrom - 1
				WHERE	CPF_SEQ_ID   = x.cpf_seq_id;
			EXCEPTION
			WHEN OTHERS THEN
				errmsg := 'PROBLEM IN RE-ARRANGING EARLIER FEE PLAN VALIDITY !!! '||SQLERRM;
				RAISE excp_feeplan_attach;
			END;
		END LOOP;
		SELECT	seq_feeplan_id.NEXTVAL
		INTO	v_seq_id
		FROM	dual;
		INSERT INTO CMS_PRODCCC_FEEPLAN(
				CPF_SEQ_ID     ,
				CPF_INST_CODE  ,
				CPF_CUST_CATG  ,
				CPF_CARD_TYPE  ,
				CPF_PROD_CODE  ,
				CPF_PLAN_CODE  ,
				--CPF_CITY_CATG  ,
				CPF_CARD_POSN  ,
				CPF_VALID_FROM ,
				CPF_VALID_TO   ,
				CPF_FLOW_SOURCE,
				--CPF_CUST_TYPE  ,
				CPF_INS_USER   ,
				CPF_INS_DATE   ,
				CPF_LUPD_USER  ,
				CPF_LUPD_DATE  )
			VALUES  (
				v_seq_id	,
				instcode	,
				custcatg	,
				cardtype	,
				prodcode	,
				plancode	,
				--citycatg	,
				cardposn	,
				validfrom	,
				validto		,
				flowsource	,
				--custtype 	,
				lupduser	,
				SYSDATE		,
				lupduser	,
				SYSDATE
				);
		errmsg := 'OK';
	EXCEPTION
	WHEN excp_feeplan_attach THEN
		RAISE;
	END;
EXCEPTION
	WHEN excp_feeplan_attach THEN
		NULL;
END;
/
show error