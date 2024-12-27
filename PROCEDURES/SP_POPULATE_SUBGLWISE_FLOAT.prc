CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Populate_Subglwise_Float (PRM_INST_CODE NUMBER,
					     PRM_CURR_CODE VARCHAR2,
					     PRM_GL_CODE   VARCHAR2,
					     PRM_INS_DATE  DATE,
					     PRM_ERRMSG  OUT  VARCHAR2
				       )
IS
CURSOR C(P_GL_CODE IN VARCHAR2,p_currmode IN VARCHAR2) IS     SELECT
				    CSM_GL_CODE,
					CGM_GL_DESC,
				    CSM_SUBGL_CODE,
				    CSM_SUBGL_DESC
                FROM    CMS_GL_MAST,CMS_SUB_GL_MAST
		WHERE
		        CSM_GL_CODE    = CGM_GL_CODE
		AND     CGM_GL_CODE    = P_GL_CODE
		AND     CGM_FLOAT_FLAG = 'F'
		AND     CGM_CURR_CODE =  p_currmode;
CURSOR C3 IS
SELECT DISTINCT CTD_TRAN_ID ,CTD_TRAN_DESC,CTD_TRAN_TYPE FROM
CMS_TMODE_DTL
WHERE CTD_TRANHEAD_FLAG = 'L';
V_TOTAMT	  NUMBER;
V_CREDIT_AMT  NUMBER;
V_DEBIT_AMT   NUMBER;
 BEGIN
 	    PRM_ERRMSG  := 'OK';
        FOR I IN C(PRM_GL_CODE,PRM_CURR_CODE) LOOP
        BEGIN
                FOR I3 IN C3 LOOP
                BEGIN
                                       BEGIN
                                        SELECT  SUM(TOTAL_AMOUNT)
					INTO    V_TOTAMT
					FROM    TRANSACTIONLOG ,
                                                CMS_APPL_PAN ,
                                                CMS_BIN_PARAM ,
                                                CMS_PROD_MAST,
                                                CMS_TMODE_DTL,
                                                CMS_GL_ACCT_MAST
					WHERE  CAP_PROD_CODE = CPM_PROD_CODE
					AND    CAP_PAN_CODE  = CUSTOMER_CARD_NO
					AND     TRUNC(DATE_TIME) = TRUNC(PRM_INS_DATE)
					AND    CBP_PARAM_NAME = 'Currency'
					AND    CBP_PROFILE_CODE = CPM_PROFILE_CODE
					AND    CAP_PROD_CODE = CPM_PROD_CODE
					AND    CBP_PARAM_VALUE = PRM_CURR_CODE
					AND    CTD_TRAN_CODE   = TXN_CODE
					AND    CTD_TRAN_ID     = I3.CTD_TRAN_ID
					AND    CAP_PAN_CODE    = CGA_ACCT_CODE
					AND    CGA_GL_CODE     = TRIM(I.CSM_GL_CODE)
					AND    CGA_SUBGL_CODE  = TRIM(I.CSM_SUBGL_CODE)
					AND     RESPONSE_CODE = '00';
                    EXCEPTION
					WHEN OTHERS THEN
					PRM_ERRMSG := 'Error from inner loop I3';
					RETURN;
				        END;
                                      SELECT
												DECODE(I3.CTD_TRAN_TYPE,'CR',NVL(V_TOTAMT,0),0),
	 		                        			DECODE(I3.CTD_TRAN_TYPE,'DR',NVL(V_TOTAMT,0),0)
	                                INTO		V_CREDIT_AMT  ,
	 		                        			V_DEBIT_AMT
	                                FROM DUAL;
                                        INSERT INTO CMS_FLOAT_SUBGLWISE_REPORT
   		  	                (
                                                  CFSR_TRAN_DATE,
                                                  CFSR_CURR_CODE,
												  CFSR_PARAM_KEY,
                                                  CFSR_GL_CODE,
                                                  CFSR_GL_DESC,
												  CFSR_SUBGL_CODE,
												  CFSR_SUBGL_DESC,
                                                  CFSR_CREDIT_AMOUNT,
                                                  CFSR_DEBIT_AMOUNT
							)
                                          VALUES
                                                ( TRUNC(PRM_INS_DATE ) ,
                                                  PRM_CURR_CODE,
												  I3.CTD_TRAN_DESC,
                                                  I.CSM_GL_CODE,
                                                  I.CGM_GL_DESC,
												  I.CSM_SUBGL_CODE,
				    							  I.CSM_SUBGL_DESC,
                                                  V_CREDIT_AMT,
                                                  V_DEBIT_AMT
                                                );
                        EXCEPTION
                        WHEN OTHERS THEN
                        PRM_ERRMSG := 'Error from iner loop I3' || SUBSTR(SQLERRM,1,300);
                        RETURN;
                        END;
                END LOOP;
         EXCEPTION --< EXCEPTION LOOP I>>
        WHEN OTHERS THEN
        PRM_ERRMSG := 'Error from iner loop I2';
        RETURN;
        END;
        END LOOP;       --<< END LOOP I>>
       EXCEPTION
  WHEN OTHERS THEN
 PRM_ERRMSG := 'Error  main ' || SUBSTR(SQLERRM,1,300);
 END;
/


