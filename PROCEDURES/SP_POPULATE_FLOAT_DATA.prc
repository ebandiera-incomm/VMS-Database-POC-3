CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Populate_Float_Data (
		  PRM_INST_CODE  						   NUMBER,
          PRM_CURR_CODE  						   VARCHAR2,
          PRM_GL_CODE  							   VARCHAR2,
		  PRM_GL_DESC  							   VARCHAR2,
          PRM_SUBGL_CODE  						   VARCHAR2,  -- New
		  PRM_SUBGL_DESC  						   VARCHAR2,
          PRM_FLAOT_FLAG  						   VARCHAR2,
		  prm_orgnl_tran_type					   VARCHAR2,
          PRM_INS_DATE  DATE,
		  PRM_LUPD_USER NUMBER,
		  PRM_TXN_AMOUNT	 NUMBER,
		  PRM_TXN_CODE		 	 VARCHAR2,
	--	  PRM_TRAN_TYPE			 VARCHAR2,
          PRM_ERRMSG  OUT VARCHAR2
           )
IS
CURSOR C3 IS
SELECT DISTINCT CTD_TRAN_ID ,CTD_TRAN_DESC
--,CTD_TRAN_TYPE
FROM
CMS_TMODE_DTL
WHERE CTD_INST_CODE = PRM_INST_CODE
AND CTD_TRANHEAD_FLAG = 'L'
AND CTD_TRAN_CODE = PRM_TXN_CODE; -- modified the query to get the cursor records based on the transaction code.

V_TOTAMT   NUMBER;
V_CREDIT_AMT  NUMBER;
V_DEBIT_AMT   NUMBER;
v_cnt		  		 	  	NUMBER;
v_tran_type			VARCHAR2(2);

 BEGIN
      PRM_ERRMSG  := 'OK';

     IF PRM_FLAOT_FLAG = 'F' THEN

                FOR I3 IN C3 LOOP
                BEGIN    --<< LOOP BEGIN I3>>
                                       	 	-- 	BEGIN
											  v_tran_type :=NULL;
												V_TOTAMT :=   PRM_TXN_AMOUNT;
										--		v_tran_type :=  prm_tran_type;
      								   		 			/* SELECT  SUM(TOTAL_AMOUNT)
     										 			 INTO         V_TOTAMT
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
															      AND    CGA_GL_CODE     = TRIM(PRM_GL_CODE)
															      AND    CGA_SUBGL_CODE  = TRIM(PRM_SUBGL_CODE)
															      AND     RESPONSE_CODE = '00'; */

												  BEGIN
																  SELECT ctd_tran_type
																  INTO	 	  v_tran_type
																  FROM	    CMS_TMODE_DTL 		  			   	-- ISO TXN CODE
																  WHERE CTD_INST_CODE =  PRM_INST_CODE AND  CTD_TRAN_ID  =  I3.CTD_TRAN_ID
																  AND    CTD_TRAN_CODE = PRM_TXN_CODE;
																 -- AND	 CTD_TRAN_TYPE = prm_orgnl_tran_type;

																  EXCEPTION
																  WHEN NO_DATA_FOUND THEN
																  --PRM_ERRMSG := 'Error while selecting tran type';
																  v_tran_type := '';
																 -- RETURN;
																 NULL;
																   END;

																/*  IF  V_TOTAMT IS NULL THEN
																--  PRM_ERRMSG := 'Error while selecting data ';
																--  RETURN;
																V_TOTAMT := 0;
																  END IF; */

										 /*    EXCEPTION
										      WHEN OTHERS THEN
										      PRM_ERRMSG := 'Error from inner loop I3';
										      RETURN;
										     END; */

											 	 	 BEGIN

                                        	 	 	 SELECT
													       		   			  DECODE(v_tran_type,'CR',NVL(V_TOTAMT,0),0),
                             							   					  DECODE(v_tran_type,'DR',NVL(V_TOTAMT,0),0)
	                                 				INTO  			   V_CREDIT_AMT  ,
                             		 					  			   		  V_DEBIT_AMT
                                 				   FROM 		 	DUAL;
												   EXCEPTION
										      	   			WHEN OTHERS THEN
										      				PRM_ERRMSG := 'Error while selecting acct_type';
										      				RETURN;

										     		END;



													--Sn insert a record into float report
													--IF  V_CREDIT_AMT  = 0 AND V_DEBIT_AMT  = 0 THEN

													--NULL;
													--ELSE
													--IF prm_orgnl_tran_type = v_tran_type THEN

													BEGIN
																				INSERT INTO CMS_FLOAT_SUBGLWISE_DETAIL
									                        					   (
									                                                  CFSR_TRAN_DATE,
									                                                  CFSR_CURR_CODE,
									              									  CFSR_PARAM_KEY,
									                                                  CFSR_GL_CODE,
									                                                  CFSR_GL_DESC,
									              									  CFSR_SUBGL_CODE,
									              									  CFSR_SUBGL_DESC,
									                                                  CFSR_CREDIT_AMOUNT,
									                                                  CFSR_DEBIT_AMOUNT,
																					  CFS_LUPD_DATE,
																					  CFS_INST_CODE,
																					  CFS_LUPD_USER,
																					  CFS_INS_DATE,
																					  CFS_INS_USER
									      											   )
									                                          VALUES
									                                                ( TRUNC(PRM_INS_DATE ) ,
									                                                  PRM_CURR_CODE,
									              									  I3.CTD_TRAN_DESC,
									                                                 TRIM( PRM_GL_CODE),
									                                                  PRM_GL_DESC,
									              									 TRIM( PRM_SUBGL_CODE) ,
									                 								 PRM_SUBGL_DESC,
									                                                  V_CREDIT_AMT,
									                                                  V_DEBIT_AMT,
																					  PRM_INS_DATE,
																					  PRM_INST_CODE,
																					  PRM_LUPD_USER,
																					  PRM_INS_DATE,
																					  PRM_LUPD_USER
									                                                );
													EXCEPTION
													  WHEN OTHERS THEN
							  						  	   PRM_ERRMSG := 'Error while updating float data' || SUBSTR(SQLERRM, 1,300) ;
								 						   RETURN;
												    END;

													--END IF;



													--En insert a record into float report
								---commented to for insert for a txn
								/*	--Sn select gl entries from float report

									BEGIN
										 SELECT 1
										 INTO	   	 v_cnt
										 FROM      CMS_FLOAT_SUBGLWISE_REPORT
										 WHERE   TRUNC(CFSR_TRAN_DATE)  = TRUNC(PRM_INS_DATE)
										 AND  	 	   CFSR_CURR_CODE	  				= PRM_CURR_CODE
										 AND   		   CFSR_GL_CODE						  	 = TRIM(PRM_GL_CODE)
										 AND   		   CFSR_SUBGL_CODE                =  TRIM(PRM_SUBGL_CODE)
									    AND 		   CFSR_PARAM_KEY  				    =    I3.CTD_TRAN_DESC;

									    UPDATE CMS_FLOAT_SUBGLWISE_REPORT
										SET           CFSR_CREDIT_AMOUNT =  CFSR_CREDIT_AMOUNT + V_CREDIT_AMT ,
													  		CFSR_DEBIT_AMOUNT    =  CFSR_DEBIT_AMOUNT   +   V_DEBIT_AMT
										WHERE   TRUNC(CFSR_TRAN_DATE)  = TRUNC(PRM_INS_DATE)
										 AND  	 	   CFSR_CURR_CODE	  				= PRM_CURR_CODE
										 AND   		   CFSR_GL_CODE						  	 = TRIM(PRM_GL_CODE)
										 AND   		   CFSR_SUBGL_CODE                =  TRIM(PRM_SUBGL_CODE)
										 AND 		   CFSR_PARAM_KEY  				    =    I3.CTD_TRAN_DESC;

										 IF SQL%ROWCOUNT = 0 THEN
										 	PRM_ERRMSG := 'Error while updating float data';
										      RETURN;
										 END IF;


									EXCEPTION
									WHEN NO_DATA_FOUND THEN

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
                                                 TRIM( PRM_GL_CODE),
                                                  PRM_GL_DESC,
              									 TRIM( PRM_SUBGL_CODE) ,
                 								 PRM_SUBGL_DESC,
                                                  V_CREDIT_AMT,
                                                  V_DEBIT_AMT
                                                );
							  WHEN OTHERS THEN
							  	PRM_ERRMSG := 'Error while updating float data' || SUBSTR(SQLERRM, 1,300) ;
								 RETURN;
								END;
							--En select gl entries from float report */


   EXCEPTION  --<< LOOP exception  I3>>
                        WHEN OTHERS THEN
                        PRM_ERRMSG := 'Error from iner loop I3' || SUBSTR(SQLERRM,1,300);
                        RETURN;
   END;
   END LOOP;
   END IF;

       EXCEPTION
  WHEN OTHERS THEN
 PRM_ERRMSG := 'Error  main ' || SUBSTR(SQLERRM,1,300);
 END;
/


