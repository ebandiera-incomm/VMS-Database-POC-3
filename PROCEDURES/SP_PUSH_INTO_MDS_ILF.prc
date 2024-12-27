CREATE OR REPLACE PROCEDURE VMSCMS.sp_push_into_mds_ilf(instcode IN 	NUMBER,
						 errmsg	  OUT	VARCHAR2)
AS
BEGIN	--main begin
errmsg := 'OK';
--Changed by christopher on 25aug04 for resetting invalid amounts
--change starts
UPDATE REC_ILF_TEMP
SET RIT_AMT1 = 0
WHERE FN_ISNUMERIC(RIT_AMT1) = 0 ;
UPDATE REC_ILF_TEMP
SET RIT_EXTERNAL_DUMP_AMT = 0
WHERE FN_ISNUMERIC(RIT_EXTERNAL_DUMP_AMT) = 0 ;
UPDATE REC_ILF_TEMP
SET RIT_SAVE_AREA_AMT = 0
WHERE FN_ISNUMERIC(RIT_SAVE_AREA_AMT) = 0 ;
--change ends
BEGIN	--begin 1
INSERT INTO REC_MDS_ILF
(RMI_INST_CODE		,RMI_RECO_FLAG		,RMI_FILE_NAME				,RMI_REC_TYP
,RMI_TRAN_TYP        	,RMI_RESP_CDE		,RMI_RVSL_CDE				,RMI_POST_DAT
,RMI_ACQ_INST_ID_NUM	,RMI_TERM_ID         	,RMI_TERM_NAME_LOC			,RMI_TERM_OWNER_NAME
,RMI_TERM_CITY		,RMI_TERM_ST_X		,RMI_TERM_CNTRY_X   			,RMI_SEQ_NUM
,RMI_INVOICE_NUM	,RMI_RETL_ID		,RMI_TRAN_CDE				,RMI_RESPONDER
,RMI_PAN		,RMI_MBR_NUM		,RMI_TRACE_NUMB				,RMI_ILF_AMT
,RMI_SETL_CRNCY_CDE     ,RMI_SETL_CONV_RATE	,RMI_TRAN_DAT				,RMI_INTL_FLAG
,RMI_TRAN_TIM		,RMI_PT_SRV_COND_CDE 	,RMI_PT_SRV_ENTRY_MDE			,RMI_FROM_ACCT_TYP
,RMI_FROM_ACCT		,RMI_TO_ACCT_TYP	,RMI_TO_ACCT   				,RMI_ORIG_CRNCY_CDE
,RMI_RESP		,RMI_MAT_CAT_CODE	,RMI_PRODUCT_TYPE			,RMI_PROCESSOR
,RmI_ex92_PROCESSING_CODE ,RmI_ISO_RESPONSE_CODE)
SELECT
instcode		,'0'			,RIT_FILE_NAME				,RIT_REC_TYP
,RIT_TRAN_TYP		,RIT_RESP_CDE		,RIT_RVSL_CDE				,RIT_POST_DAT
,RIT_ACQ_INST_ID_NUM	,RIT_TERM_ID		,RIT_TERM_NAME_LOC 			,RIT_TERM_OWNER_NAME
,RIT_TERM_CITY     	,RIT_TERM_ST_X     	,RIT_TERM_CNTRY_X  			,RIT_SEQ_NUM
,RIT_INVOICE_NUM   	,RIT_RETL_ID       	,RIT_TRAN_CDE      			,RIT_RESPONDER
,RIT_PAN           	,RIT_MBR_NUM       	,RIT_TRACE_NUMB	  			,DECODE(rit_tran_typ,'0420','000000000000',DECODE(rit_tran_cde,'12',rit_external_dump_amt,DECODE(UPPER(rit_term_cntry_x),'IN',rit_amt1,rit_save_area_amt)))
,RIT_SETL_CRNCY_CDE	,RIT_SETL_CONV_RATE	,DECODE(RIT_PROCESSOR,'A',RIT_ISS_ICHG_SETL_DAT,'I',RIT_ACQ_ICHG_SETL_DAT),DECODE(UPPER(rit_term_cntry_x),'IN','DOM','INT')--identification of international or domestic to be changed...
,RIT_TRAN_TIM      	,RIT_PT_SRV_COND_CDE	,RIT_PT_SRV_ENTRY_MDE			,RIT_FROM_ACCT_TYP
,RIT_FROM_ACCT       	,RIT_TO_ACCT_TYP     	,RIT_TO_ACCT         			,RIT_ORIG_CRNCY_CDE
,RIT_RESP            	,RIT_MAT_CAT_CODE   	,RIT_PRODUCT_TYPE			,RIT_PROCESSOR
,rsp_mast_proc_code	,RIT_ISO_RESPONSE_CODE
FROM		REC_ILF_TEMP,
		REC_SWITCH_TO_MAST_PROCMAP
WHERE		rit_rec_typ					=	rsp_rec_type
AND		SUBSTR(rit_tran_cde||rit_from_acct_typ,1,2)	=	SUBSTR(rsp_switch_proc_code,1,2)
--AND		rit_iso_response_code		=	'00'	;--00 means approved transactions
AND		rit_tran_cde != '11';
EXCEPTION	--excp of begin 1
WHEN OTHERS THEN
errmsg := 'EXCP 1 -- '||SQLERRM;
END;		--begin 1 ends
--now find rmr_iso_resp_cde from rec_mast_to_switch_respmap for each value of rmr_resp_cde
/*UPDATE	rec_mds_reco a
SET	a.rmr_iso_resp_code =(	SELECT	rmr_switch_respcode
				FROM	rec_mast_to_switch_respmap
				WHERE	rmr_mast_respcode	=	a.rmr_resp_cde);*/
--now delete from the table rec_mds_ilf rows which were just pushed
	IF errmsg = 'OK' THEN
		BEGIN		--begin 2
		DELETE FROM REC_ILF_TEMP;
		EXCEPTION	--excp of begin 2
		WHEN OTHERS THEN
		errmsg := 'EXCP 2 -- '||SQLERRM;
		END;		--end begin 2
	END IF;
EXCEPTION	--main excp
WHEN OTHERS THEN
errmsg := 'MAIN EXCP -- '||SQLERRM;
END;		--main end
/


