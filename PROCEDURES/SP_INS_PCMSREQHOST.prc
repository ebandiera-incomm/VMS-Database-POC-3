CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Ins_Pcmsreqhost(
	   PRO_ID         	IN      VARCHAR2,
	   TAN_TYP        	IN      VARCHAR2,
	   BRAN_NO        	IN		VARCHAR2,
	   REF_NO         	IN      VARCHAR2,
	   DR_ACCT        	IN      VARCHAR2,
	   CR_ACCT        	IN      VARCHAR2,
	   TRAN_AMT       	IN      VARCHAR2,
	   CURR_CODE      	IN      VARCHAR2,
	   STMT_NARR      	IN		VARCHAR2,
	   MSG_REC_REF_NO 	IN		VARCHAR2,
	   FILE_GEN       	IN		VARCHAR2,
	   SENT_COUNT     	IN		VARCHAR2,
	   FILE_NAME      	IN		NUMBER,
	   SOURCE_TYPE    	IN		VARCHAR2,
	   APPL_CODE      	IN		VARCHAR2,
	   RESP_ID        	IN		NUMBER,
	   PROCESS_FLAG     IN		VARCHAR2,
	   INS_USER		    IN	    NUMBER,
	   Errmsg			OUT		VARCHAR2)
AS
BEGIN
	 Errmsg := 'OK';
	  INSERT INTO PCMS_REQ_HOST (
		  	   PRH_REQ_ID		,
			   PRH_PRO_ID		,
			   PRH_TAN_TYP		,
			   PRH_BRAN_NO		,
			   PRH_REF_NO		,
			   PRH_DR_ACCT		,
			   PRH_CR_ACCT		,
			   PRH_TRAN_AMT		,
			   PRH_CURR_CODE	,
			   PRH_STMT_NARR	,
			   PRH_MSG_REC_REF_NO	,
			   PRH_FILE_GEN		,
			   PRH_SENT_COUNT	,
			   PRH_FILE_NAME	,
			   PRH_SOURCE_TYPE	,
			   PRH_APPL_CODE	,
			   PRH_RESP_ID		,
			   PRH_PROCESS_FLAG,
			   PRH_INS_USER,
			   PRH_LUPD_USER
			   )
			VALUES
			(
			  seq_REQ_ID.NEXTVAL	,
			  PRO_ID        	,
			  TAN_TYP       	,
			  BRAN_NO       	,
			  REF_NO        	,
			  DR_ACCT       	,
			  CR_ACCT       	,
			  TRAN_AMT      	,
			  CURR_CODE     	,
			  STMT_NARR     	,
			  MSG_REC_REF_NO	,
			  FILE_GEN      	,
			  SENT_COUNT    	,
			  FILE_NAME		,
			  SOURCE_TYPE   	,
			  APPL_CODE     	,
			  RESP_ID		,
			  PROCESS_FLAG,
			  INS_USER,
			  INS_USER
			  );

EXCEPTION
 WHEN OTHERS THEN
 Errmsg := 'Main excp --'||SQLERRM;
END;
/
SHOW ERRORS

