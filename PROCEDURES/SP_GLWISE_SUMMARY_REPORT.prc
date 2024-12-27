CREATE OR REPLACE PROCEDURE VMSCMS.SP_GLWISE_SUMMARY_REPORT
(
PRM_ERR_MSG     OUT VARCHAR2
)
IS
V_GL_CALC_FLAG          NUMBER(2);
V_SUBGL_WISE_AMT	NUMBER;
CURSOR C IS SELECT
            CGM_GL_CODE, CGM_CATG_CODE, CGM_CURR_CODE
            FROM     CMS_GL_MAST
            WHERE    CGM_FLOAT_FLAG  = 'F' ;
CURSOR C1(P_GL_CODE IN VARCHAR2,
          P_GL_CATG_CODE IN VARCHAR2)
                IS SELECT CSM_GL_CODE,
                    CSM_GLCATG_CODE,
                    CSM_SUBGL_CODE
             FROM   CMS_SUB_GL_MAST
             WHERE  CSM_GLCATG_CODE = P_GL_CATG_CODE
             AND        CSM_GL_CODE   = P_GL_CODE ;
BEGIN           --<< MAIN_BEGIN>>
		PRM_ERR_MSG := 'OK';
        --Sn check summary gl is calculated for the previous day
        BEGIN
                SELECT cdg_gl_flag
                INTO   V_GL_CALC_FLAG
                FROM    CMS_DAYWISE_GL
                WHERE   TRUNC(cdg_gl_date) = TRUNC(SYSDATE -1 );
                IF  TRUNC(V_GL_CALC_FLAG) IS NULL OR V_GL_CALC_FLAG <> 1 THEN
                V_GL_CALC_FLAG := 0;
                END IF;
        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                V_GL_CALC_FLAG := 0;
        END;
        --En check summary gl is calculated for the previous day
        IF  V_GL_CALC_FLAG  = 1 THEN
        RETURN;
        ELSE
		 DELETE FROM CMS_TRANSACTION_SUMMARY WHERE TRUNC(CTS_TRAN_DATE) = TRUNC(SYSDATE - 1);
                FOR I IN C LOOP
                        BEGIN                   --<< LOOP I BEGIN>>
                                FOR I1 IN C1(I.CGM_GL_CODE,
                                             I.CGM_CATG_CODE)
                                                                LOOP			--<< LOOP I1 BEGIN>>
					                                BEGIN
															SELECT	NVL(SUM(CAM_ACCT_BAL),0)
															INTO    V_SUBGL_WISE_AMT
															FROM	CMS_ACCT_MAST, CMS_GL_ACCT_MAST
															WHERE   CAM_ACCT_NO = CGA_ACCT_CODE
															AND     CGA_GL_CODE     = I1.CSM_GL_CODE
															AND	CGA_SUBGL_CODE  = I1.CSM_SUBGL_CODE
															AND     CGA_GLCATG_CODE = I1.CSM_GLCATG_CODE;
                                				EXCEPTION						--<< LOOP I1 EXCEPTION>>
														WHEN NO_DATA_FOUND THEN
														V_SUBGL_WISE_AMT := 0;
														WHEN OTHERS THEN
														PRM_ERR_MSG := 'Error from select' || SUBSTR(SQLERRM,1,200);
														RETURN;
                               				 END ;							--<< END LOOP I1 >>
				--Sn insert into CMS_TRANSACTION_SUMMARY
				BEGIN
					INSERT INTO 	CMS_TRANSACTION_SUMMARY
					(CTS_TRAN_DATE,
					CTS_TRAN_HEAD,
					CTS_GL_CATGCODE,
					CTS_GL_CODE,
					CTS_SUBGL_CODE,
					CTS_SUBGL_BALANCE)
					VALUES
					(SYSDATE,
					 'L'|| I.CGM_CURR_CODE,
					  I1.CSM_GLCATG_CODE,
					  I1.CSM_GL_CODE,
					 I1.CSM_SUBGL_CODE,
					 V_SUBGL_WISE_AMT
					);
				EXCEPTION
				WHEN OTHERS THEN
					PRM_ERR_MSG := 'Error from INSERT' || SUBSTR(SQLERRM,1,200);
					RETURN;
				END;
				--En insert into CMS_TRANSACTION_SUMMARY
                                END LOOP;
                        EXCEPTION                --<< LOOP I EXCEPTION>>
			WHEN OTHERS THEN
			PRM_ERR_MSG := 'Error from loop1' || SUBSTR(SQLERRM,1,200);
			RETURN;
                        END;                    --<< LOOP I END>>
                END LOOP;                        --<< END LOOP I >>
		--Sn insert into CMS_DAYWISE_GL
			INSERT INTO CMS_DAYWISE_GL
			VALUES
			(SYSDATE,
			'1'
			);
		--En insert into  CMS_DAYWISE_GL
		END IF;
EXCEPTION       --<<MAIN EXCEPTION>>
WHEN OTHERS THEN
	PRM_ERR_MSG := 'Error from main' || SUBSTR(SQLERRM,1,200);
	RETURN;
END ;           --<<MAIN END>>
/


