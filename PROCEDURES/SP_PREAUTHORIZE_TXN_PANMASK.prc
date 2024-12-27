CREATE OR REPLACE PROCEDURE VMSCMS.sp_preauthorize_txn_panmask (
   prm_card_no         IN       VARCHAR2,
   prm_mcc_code        IN       VARCHAR2,
   prm_curr_code       IN       VARCHAR2,
   prm_tran_datetime   IN       DATE,
   prm_tran_code       IN       VARCHAR2,
   prm_inst_code       IN    NUMBER,
   prm_tran_date       IN    VARCHAR2,
   prm_txn_amt         IN       VARCHAR2,
   prm_delivery_channel   IN    NUMBER,
   prm_err_code        OUT      VARCHAR2,
   prm_err_msg         OUT      VARCHAR2
)
IS
   v_rulecnt_card       NUMBER (3);
   v_rulecnt_product    NUMBER (3);
   v_rulecnt_cardtype   NUMBER (3);
   v_prod_code          cms_appl_pan.cap_prod_code%TYPE;
   v_prod_cattype       cms_appl_pan.cap_card_type%TYPE;
   v_err_flag           VARCHAR2 (3);
   v_err_msg            VARCHAR2 (900);
   v_auth_type          VARCHAR2 (1);
   v_usage_type         VARCHAR2 (1);
   v_from_time          VARCHAR2 (5);
   v_to_time            VARCHAR2 (5);
   v_from_date          DATE;
   v_to_date            DATE;
   v_tran_time          DATE;
   v_noof_txn_allowed   NUMBER;
   v_total_amt_limit    VARCHAR2 (12);

   TYPE t_rulecodetype IS REF CURSOR;

   cur_rulecode         t_rulecodetype;
   v_sql_stmt           VARCHAR2 (500);
   v_rulegroupcode      pcms_card_excp_rulegroup.pcer_rulegroup_id%TYPE;
   v_groupcode          rule.mccgroupid%TYPE;
 v_hash_pan	CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
   CURSOR c (p_rulgroup IN VARCHAR2)
   IS
      SELECT ruleid
        FROM rulecode_group
       WHERE rulegroupid = p_rulgroup;

   CURSOR c1 (p_ruleid IN VARCHAR2)
   IS
      SELECT *
        FROM rule
       WHERE ruleid = p_ruleid;
BEGIN                                                          --<MAIN_BEGIN>>
   prm_err_code := '1';
   prm_err_msg := 'OK';


   --SN CREATE HASH PAN 
BEGIN
	v_hash_pan := Gethash(prm_card_no);
EXCEPTION
WHEN OTHERS THEN
prm_err_msg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN CREATE HASH PAN

   --Sn find rules attached at card level or prodcattype level
   BEGIN
      SELECT COUNT (1)
        INTO v_rulecnt_card
        FROM pcms_card_excp_rulegroup
       WHERE pcer_pan_code = v_hash_pan --prm_card_no
         AND TRUNC (SYSDATE) BETWEEN TRUNC (pcer_valid_from)
                                 AND TRUNC (pcer_valid_to);

      IF v_rulecnt_card = 0
      THEN
         --Sn rule may be attached at cardtype level
         BEGIN
            SELECT cap_prod_code, cap_card_type
              INTO v_prod_code, v_prod_cattype
              FROM cms_appl_pan
             WHERE cap_pan_code = v_hash_pan ; -- prm_card_no;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               prm_err_code := '16';
               prm_err_msg := ' No record found for the card number ';
               RETURN;
         END;
              
           BEGIN
              SELECT COUNT (1)
                INTO v_rulecnt_cardtype
                FROM pcms_prodcattype_rulegroup
               WHERE ppr_prod_code = v_prod_code
                 AND ppr_card_type = v_prod_cattype
                 AND TRUNC (SYSDATE) BETWEEN TRUNC (ppr_valid_from)
                                       AND TRUNC (ppr_valid_to);
           EXCEPTION
              WHEN OTHERS
              THEN
                 prm_err_code := '21';
                 prm_err_msg :=
                             'Error while selecting rulcnt from cardtype level';
                 RETURN;
           END;
             --En rule may be attached at cardtype level    
         
           IF v_rulecnt_cardtype = 0
           THEN         
                  
            --Sn rule may be attached at product
                       
           BEGIN
           SELECT COUNT (1)
             INTO v_rulecnt_product
             FROM PCMS_PROD_RULEGROUP
            WHERE ppr_prod_code = v_prod_code
              AND TRUNC (SYSDATE) BETWEEN TRUNC (ppr_valid_from)
                                      AND TRUNC (ppr_valid_to);
           EXCEPTION
           WHEN OTHERS
           THEN
              prm_err_code := '21';
              prm_err_msg :=
                          'Error while selecting rulcnt from product';
              RETURN;
           END;
             --En rule may be attached at product
           ------
           
           END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_err_msg := 'Error while selecting rulcnt from card level';
         RETURN;
   END;

   --En find rules attached at card level or prodcattype level
   IF v_rulecnt_card = 0 AND v_rulecnt_cardtype = 0 AND v_rulecnt_product = 0 
   THEN
      --No rules attached at Card or product or Cardtype level
      prm_err_msg := 'OK';
      RETURN;
   END IF;

   IF v_rulecnt_card <> 0
   THEN
      --Sn select rule from card
      BEGIN
         v_sql_stmt :=
            'SELECT PCER_RULEGROUP_ID FROM PCMS_CARD_EXCP_RULEGROUP
                 WHERE PCER_PAN_CODE = :j';

         OPEN cur_rulecode FOR v_sql_stmt USING v_hash_pan ; --prm_card_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_err_code := '21';
            prm_err_msg := 'Error while selecting rulegroup  at  card level';
            RETURN;
      END;
   ELSE
         IF v_rulecnt_product <> 0
         THEN
            BEGIN
              --Sn select rule from cardtype
              v_sql_stmt :=
                 'SELECT PPR_RULEGROUP_CODE FROM PCMS_PROD_RULEGROUP
                           WHERE PPR_PROD_CODE = :j';

              OPEN cur_rulecode FOR v_sql_stmt USING v_prod_code;
            EXCEPTION
              WHEN OTHERS
              THEN
                 prm_err_code := '21';
                 prm_err_msg :=
                              'Error while selecting rulegroup for product ';
                 RETURN;
            END;
         Else
            IF v_rulecnt_cardtype <> 0
            THEN
               BEGIN
                 --Sn select rule from cardtype
                 v_sql_stmt :=
                    'SELECT PPR_RULEGROUP_CODE FROM PCMS_PRODCATTYPE_RULEGROUP
                            WHERE PPR_PROD_CODE = :j
                            AND   PPR_CARD_TYPE = :M';
 
                 OPEN cur_rulecode FOR v_sql_stmt USING v_prod_code,
                  v_prod_cattype;
               EXCEPTION
                 WHEN OTHERS
                 THEN
                   prm_err_code := '21';
                   prm_err_msg :=
                               'Error while selecting rulegroup  at  card level';
                   RETURN;
               END;
            END IF;
         END IF;
   END IF;

   --Sn open cursor and fetch records
   LOOP
      FETCH cur_rulecode
       INTO v_rulegroupcode;

      EXIT WHEN cur_rulecode%NOTFOUND;

      --Sn find the rules attached to rulegroup
      BEGIN
         FOR i IN c (v_rulegroupcode)
         LOOP
            --Sn find the rule detail
            FOR i1 IN c1 (i.ruleid)
            LOOP
               IF i1.ruletype = 0
               THEN
                  --Sn merchant based
                 --Sn find merchant group
                 IF prm_delivery_channel = '2' THEN
                 
                  BEGIN
                     SELECT mccgroupid, authtype
                       INTO v_groupcode, v_auth_type
                       FROM rule
                      WHERE ruleid = i.ruleid;

                     sp_check_merchant (v_groupcode,
                                        prm_mcc_code,
                                        v_auth_type,
                                        v_err_flag,
                                        v_err_msg
                                       );

                     IF v_err_flag <> '1' AND v_err_msg <> 'OK'
                     THEN
                        prm_err_code := v_err_flag;
                        prm_err_msg := v_err_msg;
                        RETURN;
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        ---SN merchant rule is not defined
                        NULL;
                     WHEN OTHERS
                     THEN
                        prm_err_code := '21';
                        prm_err_msg :=
                              'Error while selecting rulcnt from cardtype level'
                           || SUBSTR (SQLERRM, 1, 300);
                        RETURN;
                  END;
                END IF;        
                         --En find merchant group
               --En merchant based
               ELSIF i1.ruletype = 1
               THEN
                  --Sn time basedbased
                  /**Changed the sysdate to transaction date since for foreign transactions
                     Transaction date and server date will be different.The transaction date 
                     is appended with the Time Based Rule's Time limit and the Transaction Date
                     is checked wtith this limits  
                  **/
                  BEGIN
                     SELECT authtype, fromtime,
                            totime                --, USAGETYPE,NOTRANSALLOWED
                       INTO v_auth_type, v_from_time,
                            v_to_time   -- , v_usage_type , v_noof_txn_allowed
                       FROM rule
                      WHERE ruleid = i.ruleid;

                     SELECT TO_DATE ( SUBSTR (TRIM (prm_tran_date), 1, 8)
                                     || ' '
                                     || v_from_time,
                                     'yyyymmdd hh24:mi'
                                    )
                       INTO v_from_date
                       FROM DUAL;

                     SELECT TO_DATE ( SUBSTR (TRIM (prm_tran_date), 1, 8)
                                     || ' '
                                     || v_to_time,
                                     'yyyymmdd hh24:mi'
                                    )
                       INTO v_to_date
                       FROM DUAL;
                      
                     IF v_auth_type = 'A'
                     THEN
                        IF (prm_tran_datetime BETWEEN v_from_date AND v_to_date
                           )
                        THEN
                           prm_err_code := '1';
                           prm_err_msg := 'OK';
                        ELSE
                           prm_err_code := '12';
                           prm_err_msg := 'Invalid Transaction time ';
                           RETURN;
                        END IF;
                     END IF;

                     IF v_auth_type = 'D'
                     THEN
                        IF (prm_tran_datetime BETWEEN v_from_date AND v_to_date
                           )
                        THEN
                           prm_err_code := '12';
                           prm_err_msg := 'Invalid Transaction time ';
                           RETURN;
                        ELSE
                           prm_err_code := '1';
                           prm_err_msg := 'OK';
                        END IF;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        prm_err_code := '21';
                        prm_err_msg := SUBSTR (SQLERRM, 1, 300);
                        RETURN;
                  END;
               --En  time based
               ELSIF i1.ruletype = 2
               THEN
                  --En  transaction  based
                  BEGIN
                     SELECT transcodegroupid, authtype
                       INTO v_groupcode, v_auth_type
                       FROM rule
                      WHERE ruleid = i.ruleid;

                     sp_check_transaction (v_groupcode,
                                           prm_tran_code,
                                           v_auth_type,
                                           v_err_flag,
                                           v_err_msg
                                          );

                     IF v_err_flag <> '1' AND v_err_msg <> 'OK'
                     THEN
                        prm_err_code := v_err_flag;
                        prm_err_msg := v_err_msg;
                        RETURN;
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        ---SN merchant rule is not defined
                        NULL;
                     WHEN OTHERS
                     THEN
                        prm_err_code := '21';
                        prm_err_msg :=
                              'Error while selecting validating transaction rule'
                           || SUBSTR (SQLERRM, 1, 300);
                  END;
               --En  transaction  based
               ELSIF i1.ruletype = 3
               THEN
                  --Sn currency  based
                  BEGIN
                     SELECT ccgroupid, authtype
                       INTO v_groupcode, v_auth_type
                       FROM rule
                      WHERE ruleid = i.ruleid;

                     sp_check_currency (v_groupcode,
                                        prm_curr_code,
                                        v_auth_type,
                                        v_err_flag,
                                        v_err_msg
                                       );

                     IF v_err_flag <> '1' AND v_err_msg <> 'OK'
                     THEN
                        prm_err_code := v_err_flag;
                        prm_err_msg := v_err_msg;
                        RETURN;
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        ---SN merchant rule is not defined
                        NULL;
                     WHEN OTHERS
                     THEN
                        prm_err_code := '21';
                        prm_err_msg :=
                              'Error while selecting for currency group'
                           || SUBSTR (SQLERRM, 1, 300);
                  END;
               --En currency  based
               ELSIF i1.ruletype = 4
               THEN
                  --Sn usage based
                  BEGIN
                     SELECT USAGETYPE, NOTRANSALLOWED, TOTALAMOUNTLIMIT, authtype
                       INTO v_usage_type, v_noof_txn_allowed, v_total_amt_limit, v_auth_type
                       FROM rule
                      WHERE ruleid = i.ruleid; 
                      
                      Sp_Check_Usage(prm_inst_code,
                                       v_usage_type,
                                     prm_card_no,
                                     TO_DATE(prm_tran_date, 'yyyymmdd'),
                                     v_noof_txn_allowed,
                                     v_total_amt_limit,
                                     prm_txn_amt,
                                     v_auth_type,
                                     v_err_flag,
                                     v_err_msg);
                      
                       
                  IF v_err_flag <> '1' AND v_err_msg <> 'OK'
                     THEN
                        prm_err_code := v_err_flag;
                        prm_err_msg := v_err_msg;
                        RETURN;
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        ---SN usage type rule is not defined
                        NULL;
                     WHEN OTHERS
                     THEN
                        prm_err_code := '21';
                        prm_err_msg :=
                              'Error while selecting usage type rule'
                           || SUBSTR (SQLERRM, 1, 300);
                  END;
               --En  usage based
               ELSIF i1.ruletype = 8
               THEN
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
      DBMS_OUTPUT.put_line ('Rule group ' || v_rulegroupcode);
   END LOOP;
--En open cursor and fetch records
EXCEPTION                                                  --<MAIN_EXCEPTION>>
   WHEN OTHERS
   THEN
      prm_err_code := '21';
      prm_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 300);
END;                                                             --<MAIN_END>>
/


