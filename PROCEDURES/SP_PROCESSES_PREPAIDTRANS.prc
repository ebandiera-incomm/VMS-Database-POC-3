CREATE OR REPLACE PROCEDURE VMSCMS.SP_PROCESSES_PREPAIDTRANS
                                                        (PRM_SEQ_NUM    VARCHAR2,
                                                         PRM_ERR_MSG   OUT VARCHAR2)
IS
v_rec_typ		  	REC_TLF_DATA.RTD_REC_TYP%TYPE;
v_t_cde			REC_TLF_DATA.RTD_TYP_CDE%TYPE;
v_resp_byte1		REC_TLF_DATA.RTD_RESP_BYTE1%TYPE;
v_resp_byte2		REC_TLF_DATA.RTD_RESP_BYTE2%TYPE;
v_from_acct			REC_TLF_DATA.RTD_FROM_ACCT%TYPE;
v_rvsl_rsn			REC_TLF_DATA.RTD_RVSL_RSN%TYPE;
v_apprv_flag		VARCHAR2(1);
v_dom_flag			VARCHAR2(1);
v_onus_type			REC_TLF_DATA.RTD_ONUS_TYPE%TYPE;
v_tran_amt			REC_TLF_DATA.RTD_AMT2%TYPE;
v_func_code			VARCHAR2(15);
v_credit_acct		CMS_FUNC_ACCT.CFA_CREDIT_ACCT%TYPE;
v_debit_acct		CMS_FUNC_ACCT.CFA_CREDIT_ACCT%TYPE;
v_processes_amt		CMS_FUNC_ACCT.CFA_PROCESSES_AMT%TYPE;
v_processes_typ		CMS_FUNC_ACCT.CFA_PROCESSES_TYP%TYPE;
v_req_cashamt		NUMBER;
v_req_balamt		NUMBER;
v_loop_cnt			NUMBER;
v_cnt				NUMBER DEFAULT 1;
TYPE REC_ACCT IS RECORD (
			cci_func_code		CMS_FUNC_ACCT.CFA_FUNC_CODE%TYPE,
                        cci_debit_acct		CMS_FUNC_ACCT.CFA_DEBIT_ACCT%TYPE,
                        cci_credit_acct		CMS_FUNC_ACCT.CFA_CREDIT_ACCT%TYPE,
			cfa_processes_amt	CMS_FUNC_ACCT.CFA_PROCESSES_AMT%TYPE,
			cfa_processes_typ	CMS_FUNC_ACCT.CFA_PROCESSES_TYP%TYPE
		      );
TYPE T_REC     IS TABLE OF  REC_ACCT INDEX BY BINARY_INTEGER;
v_func_acct		T_REC;
 stmt			VARCHAR2(300);
 V			VARCHAR2(50);
 v_process_type_cnt	NUMBER(3);
 TYPE C_TYP IS REF CURSOR;
 C C_TYP;

BEGIN		--<<MAIN_BEGIN>>
	PRM_ERR_MSG := 'OK';
	--SN FIND THE TYPE OF TRANSACTION
		BEGIN
			SELECT
				RTD_REC_TYP,
				RTD_T_CDE,
				RTD_RESP_BYTE1,
				RTD_RESP_BYTE2,
				RTD_FROM_ACCT,
				RTD_RVSL_RSN,
				RTD_ONUS_TYPE,
				RTD_AMT1
			INTO	v_rec_typ,
				v_t_cde,
				v_resp_byte1,
			        v_resp_byte2,
				v_from_acct,
				v_rvsl_rsn,
				v_onus_type,
				v_tran_amt
		         FROM   REC_TLF_DATA
			 WHERE	TO_NUMBER(RTD_SEQ_NUM) = TO_NUMBER(TRIM(PRM_SEQ_NUM));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			PRM_ERR_MSG := 'Record not defined in master for sequence number ' ||PRM_SEQ_NUM;
			RETURN;
			WHEN TOO_MANY_ROWS THEN
			PRM_ERR_MSG := 'More than one record found for sequence number  ' ||PRM_SEQ_NUM;
			RETURN;
		END;
	--EN FIND THE TYPE OF TRANSACTION
			--Sn find reversal flag
			IF V_RESP_BYTE1 || V_RESP_BYTE2 IN ('000','001') THEN
			   v_apprv_flag := 'A';
			ELSE
			   v_apprv_flag := 'R';   --ASK FOR DECLINE REASON
			END IF;
			--En find reversal flag
			--Sn find dom/int flag
			v_dom_flag:= 'D';
			--En find dom/int flag

			DBMS_OUTPUT.PUT_LINE('v_rec_typ ' ||     v_rec_typ );
            DBMS_OUTPUT.PUT_LINE('v_apprv_flag' || v_apprv_flag);
			DBMS_OUTPUT.PUT_LINE('v_typ_cde' || v_t_cde);
			DBMS_OUTPUT.PUT_LINE('v_rvsl_rsn' || v_rvsl_rsn);
			DBMS_OUTPUT.PUT_LINE('v_dom_flag' || v_dom_flag);
			DBMS_OUTPUT.PUT_LINE('v_onus_type'|| v_onus_type);





			--Sn select Function code
			BEGIN
			SELECT	cfm_func_code
			INTO	v_func_code
			FROM	CMS_FUNC_MAST_CRCH
			WHERE	CFM_FUNCIDENTF1_RECTYPE	= v_rec_typ
			AND		CFM_FUNCIDENTF2_RESPCDE	= v_apprv_flag
			AND 	CFM_FUNCIDENTF3_T_CDE   = v_t_cde
			AND		CFM_FUNCIDENTF4_RVSLRSN	= v_rvsl_rsn
			AND		CFM_FUNCIDENTF5_INTFLAG	= v_dom_flag
			AND		CFM_FUNCIDENTF6_TMODE	= v_onus_type;
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
			PRM_ERR_MSG := 'Function code is not defined in Master  for transaction sequence ' || PRM_SEQ_NUM;
			RETURN;
			WHEN TOO_MANY_ROWS THEN
			PRM_ERR_MSG := 'More than one function code for sequence number  ' ||PRM_SEQ_NUM;
			RETURN;
			WHEN OTHERS THEN
			PRM_ERR_MSG := 'Problem while selecting data from function master ';
			RETURN;
			END;
			--En select Function code
			--Sn find no of account of type  V for Function code
			BEGIN
			SELECT	COUNT(1)
			INTO	v_process_type_cnt
			FROM	CMS_FUNC_ACCT
			WHERE	cfa_func_code = v_func_code
			AND		cfa_processes_typ = 'V';
			IF	v_process_type_cnt > 1 THEN
			PRM_ERR_MSG := 'More than one acct having processes type  V';
			RETURN;
			END IF;
			EXCEPTION
			WHEN OTHERS THEN
			PRM_ERR_MSG := 'Error while selecting processs type for Function code '||  v_func_code || SUBSTR(SQLERRM,1,300);
			RETURN;
			END;
			--En find no of account of type V for Function code
		--Sn Find the function code dtl from Function Master
			--Sn select acct dtl  for Function code
			BEGIN
			stmt := ' SELECT	CFA_FUNC_CODE,
						CFA_CREDIT_ACCT,
						CFA_DEBIT_ACCT,
						CFA_PROCESSES_AMT,
						CFA_PROCESSES_TYP
				  FROM		CMS_FUNC_ACCT
				  WHERE		CFA_FUNC_CODE = ' ||''''|| v_func_code ||'''';
			--En select acct dtl statement for Function code
			--Sn Fetch acct dtl to pl/sql table
			OPEN C FOR stmt;
			LOOP
			FETCH C INTO v_func_code,
				     v_credit_acct,
				     v_debit_acct,
				     v_processes_amt,
				     v_processes_typ;
					 EXIT WHEN C%NOTFOUND;
				v_func_acct(V_CNT).cci_func_code	:= v_func_code;
				v_func_acct(V_CNT).cci_credit_acct	:= v_credit_acct;
				v_func_acct(V_CNT).cci_debit_acct	:= v_debit_acct;
				v_func_acct(V_CNT).cfa_processes_amt	:= v_processes_amt;
				v_func_acct(V_CNT).cfa_processes_typ	:= v_processes_typ;
				--IF processes_typ = 'V' variable   amount is null then replace the amount
				IF v_func_acct(V_CNT).cfa_processes_typ = 'V'  AND v_func_acct(V_CNT).cfa_processes_amt IS NULL THEN
				v_func_acct(V_CNT).cfa_processes_amt := v_tran_amt;
				END IF;
				--IF processes_typ = 'V' variable account is null then replace the account
				IF v_func_acct(V_CNT).cfa_processes_typ = 'V'  AND v_func_acct(V_CNT).cci_debit_acct IS NULL THEN
				v_func_acct(V_CNT).cci_debit_acct :=v_from_acct;
				END IF;
				--IF processes_typ <> 'V' and  account is null then replace the account with customer account
				IF v_func_acct(V_CNT).cfa_processes_typ <> 'V'  AND v_func_acct(V_CNT).cci_debit_acct IS NULL THEN
				v_func_acct(V_CNT).cci_debit_acct := v_from_acct;
				END IF;

			V_CNT :=  V_CNT + 1;
			END LOOP;
			CLOSE C;
			--En Fetch acct dtl to pl/sql table
		EXCEPTION
			WHEN OTHERS THEN
			PRM_ERR_MSG := 'Error while finding funcode dtl ' || SUBSTR(SQLERRM,1,300);
			RETURN;
		END;
	--En find the function code dtl from Function Master
	--Sn Display pl/sql contents
		v_loop_cnt	 := v_func_acct.COUNT;
		FOR I IN 1..v_loop_cnt	 LOOP
			DBMS_OUTPUT.PUT_LINE(v_func_acct(I).cci_func_code);
			DBMS_OUTPUT.PUT_LINE(v_func_acct(I).cci_credit_acct);
			DBMS_OUTPUT.PUT_LINE(v_func_acct(I).cci_debit_acct);
			DBMS_OUTPUT.PUT_LINE(v_func_acct(I).cfa_processes_amt);
			DBMS_OUTPUT.PUT_LINE(v_func_acct(I).cfa_processes_typ);
		END LOOP;
	--En Display pl/sql contents


EXCEPTION	--<<MAIN_EXCEPTION>>
	WHEN OTHERS THEN
	PRM_ERR_MSG := 'Error main exception ' || SUBSTR(SQLERRM,1,300);
	RETURN;
END;		--<<MAIN_END>>
/


