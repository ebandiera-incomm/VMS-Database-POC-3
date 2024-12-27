CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Preuthorize_Txn
(
 prm_card_no             VARCHAR2,
 prm_err_msg  OUT       VARCHAR2
 )
IS
v_rulecnt_card  NUMBER(3);
v_rulecnt_cardtype NUMBER(3);
v_prod_code  CMS_APPL_PAN.cap_prod_code%TYPE;
v_prod_cattype  CMS_APPL_PAN.cap_card_type%TYPE;
TYPE t_rulecodetype IS REF CURSOR;
cur_rulecode  t_rulecodetype;
v_sql_stmt  VARCHAR2(500);
v_rulegroupcode  PCMS_CARD_EXCP_RULEGROUP.PCER_RULEGROUP_ID%TYPE ;
v_merchant_groupcode 	RULE.MCCGROUPID%TYPE;
CURSOR C( P_RULGROUP IN VARCHAR2)
 IS
SELECT 					RULEID
FROM     				  RULECODE_GROUP
WHERE  				   RULEGROUPID = P_RULGROUP;

CURSOR C1 (P_RULEID IN VARCHAR2 )
IS 	   	  		  SELECT * FROM RULE
WHERE   RULEID = P_RULEID;

BEGIN    --<MAIN_BEGIN>>
 --Sn find rules attached at card level or prodcattype level
 BEGIN
 SELECT COUNT(1)
 INTO   v_rulecnt_card
 FROM   PCMS_CARD_EXCP_RULEGROUP
 WHERE  PCER_PAN_CODE = prm_card_no
 AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PCER_VALID_FROM)  AND  TRUNC(PCER_VALID_TO);
 IF v_rulecnt_card = 0 THEN
  --Sn rule may be attached at cardtype level
  BEGIN
   SELECT cap_prod_code,cap_card_type
   INTO   v_prod_code,v_prod_cattype
   FROM   CMS_APPL_PAN
   WHERE  CAP_PAN_CODE = prm_card_no;
  EXCEPTION
   WHEN NO_DATA_FOUND THEN
   prm_err_msg := ' No record found for the card number ' ;
   RETURN;
  END;
  BEGIN
   SELECT COUNT(1)
   INTO   v_rulecnt_cardtype
   FROM   PCMS_PRODCATTYPE_RULEGROUP
   WHERE  PPR_PROD_CODE = v_prod_code
   AND    PPR_CARD_TYPE = v_prod_cattype
   AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PPR_VALID_FROM ) AND    TRUNC( PPR_VALID_TO);
  EXCEPTION
   WHEN OTHERS THEN
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
   v_sql_stmt := 'SELECT PCER_RULEGROUP_ID FROM PCMS_CARD_EXCP_RULEGROUP
     WHERE PCER_PAN_CODE = :j';
   OPEN cur_rulecode FOR v_sql_stmt USING prm_card_no;
 ELSE
  IF v_rulecnt_cardtype <> 0 THEN
  --Sn select rule from cardtype
   v_sql_stmt := 'SELECT PPR_RULEGROUP_CODE FROM PCMS_PRODCATTYPE_RULEGROUP
     WHERE PPR_PROD_CODE = :j
     AND   PPR_CARD_TYPE = :M';
   OPEN cur_rulecode FOR v_sql_stmt USING v_prod_code ,v_prod_cattype ;
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

														   IF I1.ruletype = 1 THEN
														   --Sn merchant based
														   				 --Sn find merchant group
																		 SELECT


																		 --En find merchant group





														   --En merchant based
														    ELSIF  I1.ruletype = 2  THEN
														   	  --Sn transaction based


														     --En  transaction based

															 ELSIF  I1.ruletype = 3 THEN

														   	  --Sn currency based


														     --En  currency based

															 ELSIF  I1.ruletype = 4  THEN

														   	  --Sn time based


														     --En  time based
															 ELSIF  I1.ruletype = 5 THEN
															   --Sn usage based


														     --En  usage based
															  ELSIF  I1.ruletype = 8 THEN
															   --Sn tipbased


														     --En  tip based
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
prm_err_msg := 'Error from main' || SUBSTR(SQLERRM,1,300);
END;    --<MAIN_END>>
/


