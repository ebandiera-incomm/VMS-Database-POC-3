CREATE OR REPLACE PROCEDURE VMSCMS.sp_sms_ins(Errmsg OUT VARCHAR2)
AS
c_Tran_Dat  DATE ;
c_dt_val    NUMBER(5);
c_FileName  VARCHAR2(20);
BEGIN
Errmsg := 'OK';

	-- Added by ajit as on date 13-jun-03
	INSERT INTO REC_SMS_ILF_TEMP
	(
		RSI_RECON			 ,RSI_PROCESS_DATE                ,RSI_FILE_TYPE                   ,RSI_FILE_NAME
		,RSI_REC_TYP                     ,RSI_TRAN_TYP	                  ,RSI_RESP_CDE                    ,RSI_RVSL_CDE
		,RSI_POST_DAT                    ,RSI_ACQ_INST_ID_NUM             ,RSI_TERM_ID                     ,RSI_TERM_NAME_LOC
		,RSI_TERM_OWNER_NAME             ,RSI_TERM_CITY                   ,RSI_TERM_ST_X                   ,RSI_TERM_CNTRY_X
		,RSI_SEQ_NUM                     ,RSI_INVOICE_NUM                 ,RSI_RETL_ID                     ,RSI_TRAN_CDE
		,RSI_RESPONDER                   ,RSI_PAN                         ,RSI_MBR_NUM                     ,RSI_AMT1
		,RSI_AMT2                        ,RSI_SETL_CRNCY_CDE              ,RSI_SETL_CONV_RATE              ,RSI_TRAN_DAT
		,RSI_TRAN_TIM                    ,RSI_PT_SRV_COND_CDE             ,RSI_PT_SRV_ENTRY_MDE            ,RSI_FROM_ACCT_TYP
		,RSI_FROM_ACCT                   ,RSI_ORIG_CRNCY_CDE              ,RSI_RESP                        ,RSI_MAT_CAT_CODE
		,RSI_UPLD_FILE                   ,RSI_TRACE_NUM
		,RSI_RRN
	)
	(
	SELECT
		RSI_RECON			 ,RSI_PROCESS_DATE                ,RSI_FILE_TYPE                   ,RSI_FILE_NAME
		,RSI_REC_TYP                     ,'0210'	                  ,RSI_RESP_CDE                    ,RSI_RVSL_CDE
		,RSI_POST_DAT                    ,RSI_ACQ_INST_ID_NUM             ,RSI_TERM_ID                     ,RSI_TERM_NAME_LOC
		,RSI_TERM_OWNER_NAME             ,RSI_TERM_CITY                   ,RSI_TERM_ST_X                   ,RSI_TERM_CNTRY_X
		,RSI_SEQ_NUM                     ,RSI_INVOICE_NUM                 ,RSI_RETL_ID                     ,RSI_TRAN_CDE
		,RSI_RESPONDER                   ,RSI_PAN                         ,RSI_MBR_NUM                     ,RSI_AMT1
		,RSI_AMT2                        ,RSI_SETL_CRNCY_CDE              ,RSI_SETL_CONV_RATE              ,RSI_TRAN_DAT
		,RSI_TRAN_TIM                    ,RSI_PT_SRV_COND_CDE             ,RSI_PT_SRV_ENTRY_MDE            ,RSI_FROM_ACCT_TYP
		,RSI_FROM_ACCT                   ,RSI_ORIG_CRNCY_CDE              ,RSI_RESP                        ,RSI_MAT_CAT_CODE
		,RSI_UPLD_FILE                   ,DECODE(RSI_TRAN_TYP,'0220' ,SUBSTR(rsi_rrn,7),   RSI_TRACE_NUM)
		,RSI_RRN
	FROM REC_SMS_ILF_TEMP
	WHERE RSI_TRAN_TYP = '0420' OR RSI_TRAN_TYP = '0220'
				);


	SELECT COUNT(*) INTO c_dt_val FROM REC_SMS_ILF ;
	IF c_dt_val > 0 THEN
		SELECT MAX(FN_CONV_CHAR_TO_DATE(A.RSI_TRAN_DAT ,A.RSI_TRAN_TIM ) )  INTO c_Tran_Dat FROM REC_SMS_ILF A		 ;

		SELECT DISTINCT B.RSI_FILE_NAME INTO c_FileName FROM REC_SMS_ILF B
		WHERE FN_CONV_CHAR_TO_DATE(B.RSI_TRAN_DAT ,B.RSI_TRAN_TIM ) = c_Tran_Dat;

		-- delete PreV days Trans Or reconsile trans
		DELETE FROM REC_SMS_ILF WHERE RSI_FILE_NAME != c_FileName  OR RSI_RECON = 1 ;

		INSERT INTO REC_SMS_ILF(
			RSI_RECON              ,RSI_PROCESS_DATE       ,RSI_FILE_TYPE          ,RSI_FILE_NAME
			,RSI_REC_TYP            ,RSI_TRAN_TYP           ,RSI_RESP_CDE           ,RSI_RVSL_CDE
			,RSI_POST_DAT           ,RSI_ACQ_INST_ID_NUM    ,RSI_TERM_ID            ,RSI_TERM_NAME_LOC
			,RSI_TERM_OWNER_NAME    ,RSI_TERM_CITY          ,RSI_TERM_ST_X          ,RSI_TERM_CNTRY_X
			,RSI_SEQ_NUM            ,RSI_INVOICE_NUM        ,RSI_RETL_ID            ,RSI_TRAN_CDE
			,RSI_RESPONDER          ,RSI_PAN                ,RSI_MBR_NUM            ,RSI_AMT1
			,RSI_AMT2               ,RSI_SETL_CRNCY_CDE     ,RSI_SETL_CONV_RATE     ,RSI_TRAN_DAT
			,RSI_TRAN_TIM           ,RSI_PT_SRV_COND_CDE    ,RSI_PT_SRV_ENTRY_MDE   ,RSI_FROM_ACCT_TYP
			,RSI_FROM_ACCT          ,RSI_ORIG_CRNCY_CDE     ,RSI_RESP               ,RSI_MAT_CAT_CODE
			,RSI_UPLD_FILE          ,RSI_TRACE_NUM          ,RSI_RRN
					)
		SELECT
			RSI_RECON              ,RSI_PROCESS_DATE       ,RSI_FILE_TYPE          ,RSI_FILE_NAME
			,RSI_REC_TYP            ,RSI_TRAN_TYP           ,RSI_RESP_CDE           ,RSI_RVSL_CDE
			,RSI_POST_DAT           ,RSI_ACQ_INST_ID_NUM    ,RSI_TERM_ID            ,RSI_TERM_NAME_LOC
			,RSI_TERM_OWNER_NAME    ,RSI_TERM_CITY          ,RSI_TERM_ST_X          ,RSI_TERM_CNTRY_X
			,RSI_SEQ_NUM            ,RSI_INVOICE_NUM        ,RSI_RETL_ID            ,RSI_TRAN_CDE
			,RSI_RESPONDER          ,RSI_PAN                ,RSI_MBR_NUM            ,RSI_AMT1
			,RSI_AMT2               ,RSI_SETL_CRNCY_CDE     ,RSI_SETL_CONV_RATE     ,RSI_TRAN_DAT
			,RSI_TRAN_TIM           ,RSI_PT_SRV_COND_CDE    ,RSI_PT_SRV_ENTRY_MDE   ,RSI_FROM_ACCT_TYP
			,RSI_FROM_ACCT          ,RSI_ORIG_CRNCY_CDE     ,RSI_RESP               ,RSI_MAT_CAT_CODE
			,RSI_UPLD_FILE          ,RSI_TRACE_NUM          ,RSI_RRN
		FROM	REC_SMS_ILF_TEMP A
		WHERE	FN_CONV_CHAR_TO_DATE(A.RSI_TRAN_DAT ,A.RSI_TRAN_TIM ) > c_Tran_Dat;
	ELSE
		INSERT INTO REC_SMS_ILF(
			RSI_RECON              ,RSI_PROCESS_DATE       ,RSI_FILE_TYPE          ,RSI_FILE_NAME
			,RSI_REC_TYP            ,RSI_TRAN_TYP           ,RSI_RESP_CDE           ,RSI_RVSL_CDE
			,RSI_POST_DAT           ,RSI_ACQ_INST_ID_NUM    ,RSI_TERM_ID            ,RSI_TERM_NAME_LOC
			,RSI_TERM_OWNER_NAME    ,RSI_TERM_CITY          ,RSI_TERM_ST_X          ,RSI_TERM_CNTRY_X
			,RSI_SEQ_NUM            ,RSI_INVOICE_NUM        ,RSI_RETL_ID            ,RSI_TRAN_CDE
			,RSI_RESPONDER          ,RSI_PAN                ,RSI_MBR_NUM            ,RSI_AMT1
			,RSI_AMT2               ,RSI_SETL_CRNCY_CDE     ,RSI_SETL_CONV_RATE     ,RSI_TRAN_DAT
			,RSI_TRAN_TIM           ,RSI_PT_SRV_COND_CDE    ,RSI_PT_SRV_ENTRY_MDE   ,RSI_FROM_ACCT_TYP
			,RSI_FROM_ACCT          ,RSI_ORIG_CRNCY_CDE     ,RSI_RESP               ,RSI_MAT_CAT_CODE
			,RSI_UPLD_FILE          ,RSI_TRACE_NUM          ,RSI_RRN
					)
		SELECT
			RSI_RECON              ,RSI_PROCESS_DATE       ,RSI_FILE_TYPE          ,RSI_FILE_NAME
			,RSI_REC_TYP            ,RSI_TRAN_TYP           ,RSI_RESP_CDE           ,RSI_RVSL_CDE
			,RSI_POST_DAT           ,RSI_ACQ_INST_ID_NUM    ,RSI_TERM_ID            ,RSI_TERM_NAME_LOC
			,RSI_TERM_OWNER_NAME    ,RSI_TERM_CITY          ,RSI_TERM_ST_X          ,RSI_TERM_CNTRY_X
			,RSI_SEQ_NUM            ,RSI_INVOICE_NUM        ,RSI_RETL_ID            ,RSI_TRAN_CDE
			,RSI_RESPONDER          ,RSI_PAN                ,RSI_MBR_NUM            ,RSI_AMT1
			,RSI_AMT2               ,RSI_SETL_CRNCY_CDE     ,RSI_SETL_CONV_RATE     ,RSI_TRAN_DAT
			,RSI_TRAN_TIM           ,RSI_PT_SRV_COND_CDE    ,RSI_PT_SRV_ENTRY_MDE   ,RSI_FROM_ACCT_TYP
			,RSI_FROM_ACCT          ,RSI_ORIG_CRNCY_CDE     ,RSI_RESP               ,RSI_MAT_CAT_CODE
			,RSI_UPLD_FILE          ,RSI_TRACE_NUM          ,RSI_RRN
		FROM	REC_SMS_ILF_TEMP A;


	END IF;

EXCEPTION
	WHEN OTHERS THEN
	Errmsg := 'Main excp --'||SQLERRM;

END;
/


