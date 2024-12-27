CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Preauthorize_Txn_bak
(prm_inst_code           IN					   	NUMBER,
 prm_card_no             IN					   	  VARCHAR2,
 prm_mcc_code		 IN  					   VARCHAR2,
 prm_curr_code		   IN					     VARCHAR2,
 prm_tran_datetime IN  						 DATE,
 prm_tran_amt	   	   IN					 NUMBER,
 prm_tran_code		   IN						 VARCHAR2,
 prm_delivery_chnnel   IN						 VARCHAR2,
 prm_err_code          OUT					 VARCHAR2,
 prm_err_msg  		     OUT       			   VARCHAR2
 )
IS
v_rulecnt_card  		 					   		   	      NUMBER(3);
v_rulecnt_cardtype 							   			 NUMBER(3);
v_prod_code  											 	 CMS_APPL_PAN.cap_prod_code%TYPE;
v_prod_cattype  											CMS_APPL_PAN.cap_card_type%TYPE;
v_err_flag													 		VARCHAR2(3);
v_err_msg														 VARCHAR2(900);
v_auth_type														 VARCHAR2(1);
v_usage_type												VARCHAR2(1);
v_from_time													   VARCHAR2(5);
v_to_time													      VARCHAR2(5);
v_from_date														  DATE;
v_to_date														  	 DATE;
v_tran_time														  DATE;
--v_usage_type													  RULE.usagetype%TYPE;
v_noof_transallowed												  NUMBER;
v_tot_amount													  NUMBER;
--v_noof_txn_allowed									  			  NUMBER;
TYPE t_rulecodetype IS REF CURSOR;
cur_rulecode  t_rulecodetype;
v_sql_stmt  VARCHAR2(500);
v_rulegroupcode  PCMS_CARD_EXCP_RULEGROUP.PCER_RULEGROUP_ID%TYPE ;
v_groupcode 	RULE.MCCGROUPID%TYPE;
CURSOR C(P_RULGROUP IN VARCHAR2)
 IS
SELECT 					RULEID
FROM     				  RULECODE_GROUP
WHERE RUL_INST_CODE = prm_inst_code AND RULEGROUPID = P_RULGROUP;

CURSOR C1 (P_RULEID IN VARCHAR2)
IS 	   	  		  SELECT * FROM RULE
WHERE ACT_INST_CODE=prm_inst_code AND RULEID = P_RULEID;

BEGIN    --<MAIN_BEGIN>>

prm_err_code := '1';
prm_err_msg  := 'OK';
 --Sn find rules attached at card level or prodcattype level
 BEGIN
				 SELECT COUNT(1)
				 INTO   v_rulecnt_card
				 FROM   PCMS_CARD_EXCP_RULEGROUP
				 WHERE  PCER_INST_CODE =prm_inst_code AND PCER_PAN_CODE = prm_card_no
				 AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PCER_VALID_FROM)  AND  TRUNC(PCER_VALID_TO);

	 IF v_rulecnt_card = 0 THEN
		  --Sn rule may be attached at cardtype level
		  BEGIN
		   SELECT cap_prod_code,cap_card_type
		   INTO   v_prod_code,v_prod_cattype
		   FROM   CMS_APPL_PAN
		   WHERE CAP_INST_CODE = prm_inst_code AND  CAP_PAN_CODE = prm_card_no;
		  EXCEPTION
		   WHEN NO_DATA_FOUND THEN
		   prm_err_code := '16';
		   prm_err_msg := ' No record found for the card number ' ;
		   RETURN;
		  END;

		  BEGIN
		   SELECT COUNT(1)
		   INTO   v_rulecnt_cardtype
		   FROM   PCMS_PRODCATTYPE_RULEGROUP
		   WHERE  PPR_INST_CODE = prm_inst_code AND PPR_PROD_CODE = v_prod_code
		   AND    PPR_CARD_TYPE = v_prod_cattype
		   AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PPR_VALID_FROM ) AND    TRUNC( PPR_VALID_TO);
		  EXCEPTION
		   WHEN OTHERS THEN
		   prm_err_code := '21';
		   prm_err_msg := 'Error while selecting rulcnt from cardtype level';
		   RETURN;
		  END;
  --En rule may be attached at cardtype level
  	    END IF;
 EXCEPTION
  		  WHEN OTHERS THEN
  		  	   prm_err_msg := 'Error while selecting rulcnt from card level';
  			   RETURN;
 		  END;
 --En find rules attached at card level or prodcattype level

	 IF v_rulecnt_card = 0 AND v_rulecnt_cardtype = 0 THEN
	  --No rules attached at Card or Cardtype level
	  prm_err_msg := 'OK';
	  RETURN;
	 END IF;
 IF  v_rulecnt_card <> 0  THEN
  --Sn select rule from card
  	   	BEGIN
			   v_sql_stmt := 'SELECT PCER_RULEGROUP_ID FROM PCMS_CARD_EXCP_RULEGROUP
			     WHERE PCER_PAN_CODE = :j
				 AND   pcer_delete_flg = :m';
			   OPEN cur_rulecode FOR v_sql_stmt USING prm_card_no, 'N';

		 EXCEPTION
			 WHEN OTHERS THEN
			  prm_err_code := '21';
			  prm_err_msg := 'Error while selecting rulegroup  at  card level';
	  			   RETURN;
		  END;
 ELSE

			  IF v_rulecnt_cardtype <> 0 THEN
			  BEGIN
			  --Sn select rule from cardtype
					   v_sql_stmt := 'SELECT PPR_RULEGROUP_CODE FROM PCMS_PRODCATTYPE_RULEGROUP
					     WHERE PPR_PROD_CODE = :j
					     AND   PPR_CARD_TYPE = :M';
					   OPEN cur_rulecode FOR v_sql_stmt USING v_prod_code ,v_prod_cattype ;

				EXCEPTION
						 WHEN OTHERS THEN
						  prm_err_code := '21';
						  prm_err_msg := 'Error while selecting rulegroup  at  card level';
				  			   RETURN;
				END;
			END IF;

 END IF;

 --Sn open cursor and fetch records
  LOOP
   FETCH cur_rulecode INTO v_rulegroupcode;
    EXIT WHEN cur_rulecode%NOTFOUND;

		 --Sn find the rules attached to rulegroup
		 BEGIN
		 	  	   FOR I IN C(v_rulegroupcode) LOOP

		 		   	   	 					   --Sn find the rule detail
											   		FOR I1 IN C1(I.ruleid) LOOP

														   IF I1.ruletype = 0 AND ((prm_tran_code = '10' AND prm_delivery_chnnel = '02') OR(prm_tran_code = '10' AND prm_delivery_chnnel = '05')) THEN
														   --Sn merchant based
														   				 --Sn find merchant group
																		 BEGIN
																		 SELECT MCCGROUPID, AUTHTYPE
																		 INTO	    v_groupcode , v_auth_type
																		 FROM    RULE
																		 WHERE ACT_INST_CODE = prm_inst_code AND RULEID = I.ruleid;


																		 Sp_Check_Merchant
																		 (
 																		  					prm_inst_code,
																							v_groupcode ,
 																							prm_mcc_code	   ,
																							v_auth_type,
 																							v_err_flag	,
 																							v_err_msg
																		);

																		IF v_err_flag <> '1' AND v_err_msg <> 'OK' THEN
																		 prm_err_code := v_err_flag;
																		 prm_err_msg  := v_err_msg	;
																		 RETURN;
																		END IF;

																		EXCEPTION
																		WHEN NO_DATA_FOUND THEN
																		---SN merchant rule is not defined
																		NULL;
																		WHEN OTHERS THEN
																		prm_err_code     := '21';
																		prm_err_msg := 'Error while selecting rulcnt from cardtype level'  || SUBSTR(SQLERRM,1,300);
																		RETURN;
																		END;
																		 --En find merchant group
														   --En merchant based
														    ELSIF  I1.ruletype = 1  THEN
														   	  --Sn time basedbased

															  BEGIN
														      	   		SELECT   AUTHTYPE ,  FROMTIME, TOTIME  --, USAGETYPE,NOTRANSALLOWED
																		 INTO	     v_auth_type ,v_from_time	, v_to_time	 -- , v_usage_type , v_noof_txn_allowed
																		 FROM    RULE
																		 WHERE ACT_INST_CODE=prm_inst_code AND RULEID = I.ruleid;

																		  SELECT TO_DATE(TO_CHAR(SYSDATE , 'dd-mon-yy') || ' '|| v_from_time , 'dd-mon-yy hh24:mi')
																		  INTO	 	   v_from_date		 FROM dual;

																		  SELECT TO_DATE(TO_CHAR(SYSDATE , 'dd-mon-yy') || ' '|| v_to_time , 'dd-mon-yy hh24:mi')
																		  INTO	 	   v_to_date		 FROM dual;

																		  IF   v_auth_type = 'A'  THEN

																		   	   IF  (prm_tran_datetime BETWEEN v_from_date AND  v_to_date )  THEN

																			  			   prm_err_code := '1';
																			   			   prm_err_msg  := 'OK';
																				ELSE
																				 		   prm_err_code := '12';
																			              	prm_err_msg  := 'Invalid Transaction time ';
																							RETURN;

																		 		  END IF;

																	     END IF;

																		 IF   v_auth_type = 'D'  THEN

																		   	   IF  (prm_tran_datetime BETWEEN v_from_date AND  v_to_date )  THEN

																			  			   prm_err_code := '12';
																			              	prm_err_msg  := 'Invalid Transaction time ';
																							RETURN;
																				ELSE
																				 		   prm_err_code := '1';
																			   			   prm_err_msg  := 'OK';

																		 		  END IF;

																	     END IF;


														   EXCEPTION
														    WHEN OTHERS THEN
															prm_err_code := '21';
															prm_err_msg  := SUBSTR(SQLERRM, 1,300);
															RETURN;
														   END;
														     --En  time based

															 ELSIF  I1.ruletype = 2 THEN
															  --En  transaction  based
														   	 BEGIN
																		 SELECT TRANSCODEGROUPID  , AUTHTYPE
																		 INTO	    v_groupcode , v_auth_type
																		 FROM    RULE
																		 WHERE ACT_INST_CODE=prm_inst_code AND RULEID = I.ruleid;


																		 Sp_Check_Transaction
																		 (					 prm_inst_code,
																		 					 v_groupcode ,
 																							 prm_tran_code	   ,
																							 prm_delivery_chnnel,
																							 v_auth_type,
 																							v_err_flag	,
 																							v_err_msg
																		);

																		IF v_err_flag <> '1' AND v_err_msg <> 'OK' THEN
																		 prm_err_code := v_err_flag;
																		 prm_err_msg  := v_err_msg	;
																		 RETURN;
																		END IF;

																		 EXCEPTION
																		WHEN NO_DATA_FOUND THEN
																		---SN merchant rule is not defined
																		NULL;
																		WHEN OTHERS THEN
																		prm_err_code     := '21';
																		prm_err_msg := 'Error while selecting validating transaction rule'|| SUBSTR(SQLERRM,1,300);
																		END;

														     --En  transaction  based

															 ELSIF  I1.ruletype = 3  THEN

														   	  --Sn currency  based
														    BEGIN
																		 SELECT CCGROUPID ,  AUTHTYPE
																		 INTO	    v_groupcode , v_auth_type
																		 FROM    RULE
																		 WHERE ACT_INST_CODE=prm_inst_code AND RULEID = I.ruleid;


																		Sp_Check_Currency
																		 (				 prm_inst_code,
 																		  					v_groupcode ,
 																							prm_curr_code	   ,
																							v_auth_type,
 																							v_err_flag	,
 																							v_err_msg
																		);

																		IF v_err_flag <> '1' AND v_err_msg <> 'OK' THEN
																		 prm_err_code := v_err_flag;
																		 prm_err_msg  := v_err_msg	;
																		 RETURN;
																		END IF;

																		EXCEPTION
																		WHEN NO_DATA_FOUND THEN
																		---SN merchant rule is not defined
																		NULL;
																		WHEN OTHERS THEN
																		prm_err_code     := '21';
																		prm_err_msg := 'Error while selecting for currency group' || SUBSTR(SQLERRM,1,300);
																		END;
														     --En currency  based

															 ELSIF  I1.ruletype = 4 THEN -- usage based

															  		     --_err_code :='1';
																		-- prm_err_msg  := 'OK';
																BEGIN		
																		SELECT	   AUTHTYPE,
	   																			   DECODE(USAGETYPE,'0','D','1','W','2','M'),
	   																			   TO_NUMBER(NOTRANSALLOWED),
	   																			   TO_NUMBER(TOTALAMOUNTLIMIT)

																		INTO	   v_auth_type,
	  																			   v_usage_type,
	  																			   v_noof_transallowed,
	  																			   v_tot_amount
																		FROM      RULE
																		WHERE     ACT_INST_CODE=prm_inst_code 
																		AND 	  RULEID = I.ruleid;
																		
																		Sp_Check_Usage
     																				  (
     																				   prm_inst_code,
     																				   v_usage_type,  		  -- 'D'  --DAILY, 'W' WEEKLY  , 'M' monthly..
     																				   prm_card_no ,
     																				   prm_tran_datetime ,
     																				   v_noof_transallowed  ,  -- 'Total allowed transaction count '
     																				   v_tot_amount  ,
     																				   prm_tran_amt  ,
     																				   v_auth_type   ,
     																				   v_err_flag	,
 																					   v_err_msg																	
																					   );
																		IF v_err_flag <> '1' AND v_err_msg <> 'OK' THEN
																		 prm_err_code := v_err_flag;
																		 prm_err_msg  := v_err_msg	;
																		 RETURN;
																		END IF; 
																		
																		
																EXCEPTION
																		WHEN NO_DATA_FOUND THEN
																		
																		NULL;
																		WHEN OTHERS THEN
																		prm_err_code     := '21';
																		prm_err_msg := 'Error while selecting for usage type' || SUBSTR(SQLERRM,1,300);
																		
																
																END;
															   --Sn usage based
														   --NULL;

														     --En  usage based
															  ELSIF  I1.ruletype = 8 THEN
															   --Sn tipbased

														   NULL;
														     --En  tip based
															 ELSE
															 NULL;
															 END IF;



													END LOOP;

											   --En find the rule detail



		 	  	   END LOOP;


		 END;
		 --En find the rules attached to rulegroup





	DBMS_OUTPUT.PUT_LINE ('Rule group ' || v_rulegroupcode);
  END LOOP;
 --En open cursor and fetch records




EXCEPTION   --<MAIN_EXCEPTION>>
WHEN OTHERS THEN
prm_err_code := '21';
prm_err_msg := 'Error from main' || SUBSTR(SQLERRM,1,300);
END;    --<MAIN_END>>
/


