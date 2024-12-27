CREATE OR REPLACE PROCEDURE VMSCMS.sp_elan_preauthcomp_txn (
   prm_card_no            IN       VARCHAR2,
   prm_mcc_code           IN       VARCHAR2,
   prm_curr_code          IN       VARCHAR2,
   prm_tran_datetime      IN       DATE,
   prm_tran_code          IN       VARCHAR2,
   prm_inst_code          IN       NUMBER,
   prm_tran_date          IN       VARCHAR2,
   prm_txn_amt            IN       VARCHAR2,
   prm_delivery_channel   IN       VARCHAR2,
--prm_delivery_channel variable Datatype changed from Number to varchar2  22092012 Dhiraj Gaikwad
   prm_merc_id            IN       VARCHAR2,                    -- need to add
   prm_country_code       IN       VARCHAR2,                    -- need to add
   prm_hold_amount        OUT      NUMBER,                      -- need to add
   prm_hold_days          OUT      NUMBER,                      -- need to add
   prm_err_code           OUT      VARCHAR2,
   prm_err_msg            OUT      VARCHAR2
)
IS
     /*******************************************************************************
       * Created Date     :  01-MAR-2013
       * Created By       :  Sagar m.
       * PURPOSE          :  To check for merchant level rule configuration 
                             dueing perauth completion transaction
       * Reviewer         :  Dhiraj
       * Reviewed Date    :  01-MAR-2013
       * Release Number   :  RI0023.2_B0011
       
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 09-AUG-2019.
     * Purpose          : VMS-1042 (Tip Tolerance Filter Enhancement: Transaction Filter Override)
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R09_B0002
   *************************************************************************************/
   v_rulecnt_card         NUMBER (3);
   v_rulecnt_product      NUMBER (3);
   v_rulecnt_cardtype     NUMBER (3);
   v_cap_prod_code        cms_appl_pan.cap_prod_code%TYPE;
   v_cap_card_type        cms_appl_pan.cap_card_type%TYPE;
   v_err_flag             VARCHAR2 (3);
   v_err_msg              VARCHAR2 (900);
    
   v_transactiongroupid   rule.transactiongroupid%TYPE;
    
   v_authtype             rule.authtype%TYPE;
    

   TYPE t_rulecodetype IS REF CURSOR;

   cur_rulecode           t_rulecodetype;
   v_sql_stmt             VARCHAR2 (500);
   v_rulegroupcode        pcms_card_excp_rulegroup.pcer_rulegroup_id%TYPE;
   v_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
   prm_goto_nextpre       NUMBER (2)                                     := 0;
                                       -- added by Dhiraj Gaikwad on 26092012

   CURSOR cur_rulegrpcode (p_rulgroup IN VARCHAR2)
   IS
      SELECT a.ruleid
        FROM rulecode_group a, rulegrouping b
       WHERE a.rulegroupid = p_rulgroup
         AND a.rulegroupid = b.rulegroupid
         AND b.activationstatus = 'Y';

   CURSOR cur_rule (p_ruleid IN VARCHAR2)
   IS
      SELECT ruleid, ruledesc, ruletype, authtype, mccgroupid, ccgroupid,
             usagetype, notransallowed, totalamountlimit, transcodegroupid,
             fromtime, totime, activationstatus, dateapplicable, fromdate,
             todate, act_lupd_date, act_inst_code, act_lupd_user,
             act_ins_date, act_ins_user
        FROM rule
       WHERE ruleid = p_ruleid AND activationstatus = 'Y';

--***********************************************************************--
   PROCEDURE sp_check_preauthtransaction (
      prm_inst_code          IN       NUMBER,
      prm_txnrule_groupid    IN       VARCHAR2,
      --  prm_txn_type           IN       VARCHAR2,
      prm_tran_code          IN       VARCHAR2,
      prm_delivery_channel   IN       VARCHAR2,
   -- NUMBER, -- Changed datatype from NUMBER to VARCHAR2 on 25092012 Dhiraj G
      prm_mcc_code           IN       VARCHAR2,
      prm_merc_id            IN       VARCHAR2,
      prm_auth_type          IN       VARCHAR2,
      prm_tran_amt           IN       NUMBER,
      prm_hold_amt           OUT      NUMBER,
      prm_hold_days          OUT      NUMBER,
      prm_goto_nextpre       OUT      NUMBER,
                                       -- Added by Dhiraj Gaikwad  on 26092012
      prm_err_flag           OUT      VARCHAR2,
      prm_err_msg            OUT      VARCHAR2
   )
   IS
      v_check_cnt                NUMBER (1);
      excp_decline_transaction   EXCEPTION;
 
      v_ctr_fixedhold_amount     cms_txncode_rule.ctr_fixedhold_amount%TYPE;
      v_ctr_perhold_amount       cms_txncode_rule.ctr_perhold_amount%TYPE;
      v_ctr_hold_days            cms_txncode_rule.ctr_hold_days%TYPE;
  
      v_null_found               NUMBER (2)                              := 0;
                                                         -- Added on 21092012
   BEGIN
  							--- Added for VMS-1042 			
  FOR i IN (SELECT   b.ctr_fixedhold_amount,b.ctr_perhold_amount,
                            b.ctr_hold_days,b.ctr_mcc_code,b.ctr_merchant_groupid
                       FROM cms_txncode_rule b, cms_txncodegrp_txncode a
                      WHERE a.ctt_txnrule_grpcode = prm_txnrule_groupid
                        AND a.ctt_txnrule_id = b.ctr_txnrule_id
                        AND b.ctr_inst_code = prm_inst_code
                        AND b.ctr_txn_code = prm_tran_code
                        AND b.ctr_delv_chnl = prm_delivery_channel
                        AND b.ctr_merchant_groupid is not null
                   ORDER BY ctr_ins_date)
         LOOP
            BEGIN 

              SELECT 1
              INTO v_check_cnt
              FROM cms_mercidgrp_mercid
              WHERE cmm_merc_grpcode = i.ctr_merchant_groupid
              AND ((cmm_merc_id = prm_merc_id)
                    OR (cmm_merc_id = TRIM(prm_merc_id)) 
                    OR (LPAD(cmm_merc_id,15,'0') = prm_merc_id) 
                    OR (RPAD(cmm_merc_id,15,'0') = prm_merc_id));

           EXCEPTION
            WHEN NO_DATA_FOUND THEN
                    v_null_found := 2; 
                    prm_goto_nextpre:=v_null_found ;  
            WHEN OTHERS
               THEN
                  prm_err_flag := '21';
                  prm_err_msg :=
                        'Error while Transaction Rule validation merchant_groupid ' || SQLERRM;
                  RAISE excp_decline_transaction;
            END;

            IF v_check_cnt IS NOT NULL
            THEN
               v_ctr_fixedhold_amount := i.ctr_fixedhold_amount;
               v_ctr_perhold_amount := i.ctr_perhold_amount;
               v_ctr_hold_days := i.ctr_hold_days;
               v_null_found := 3;                         
               prm_goto_nextpre := v_null_found;
                                       
               EXIT;
            END IF;
         END LOOP;
         
           IF v_check_cnt IS  NULL
                    THEN
                    
         FOR i IN (SELECT   b.ctr_fixedhold_amount,b.ctr_perhold_amount,
                            b.ctr_hold_days,b.ctr_mcc_code
                       FROM cms_txncode_rule b, cms_txncodegrp_txncode a
                      WHERE a.ctt_txnrule_grpcode = prm_txnrule_groupid
                        AND a.ctt_txnrule_id = b.ctr_txnrule_id
                        AND b.ctr_inst_code = prm_inst_code
                        AND b.ctr_txn_code = prm_tran_code
                        AND b.ctr_delv_chnl = prm_delivery_channel
                        AND b.ctr_merchant_groupid is  null
                   ORDER BY ctr_ins_date)
         LOOP
            BEGIN
               SELECT 1
                 INTO v_check_cnt
                 FROM mccode_group
                WHERE mccodegroupid = i.ctr_mcc_code AND mccode = prm_mcc_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_null_found := 2;                     -- Added on 21092012
                  prm_goto_nextpre := v_null_found;
                                      -- Added by Dhiraj Gaikwad  on 26092012
               WHEN OTHERS
               THEN
                  prm_err_flag := '21';
                  prm_err_msg :=
                        'Error while Transaction Rule validation ' || SQLERRM;
                  RAISE excp_decline_transaction;
            END;

            IF v_check_cnt IS NOT NULL
            THEN
               v_ctr_fixedhold_amount := i.ctr_fixedhold_amount;
               v_ctr_perhold_amount := i.ctr_perhold_amount;
               v_ctr_hold_days := i.ctr_hold_days;
               v_null_found := 3;                        -- Added on 21092012
               prm_goto_nextpre := v_null_found;
                                      -- Added by Dhiraj Gaikwad  on 26092012
               EXIT;
            END IF;
         END LOOP;
   END IF;
         /* Start -- Added on 21092012  */
         IF v_null_found IN (2, 0)
         THEN
            prm_hold_amt := prm_txn_amt;
            prm_hold_days := 0;
            prm_err_flag := '1';
            prm_err_msg := 'OK';
            prm_goto_nextpre := v_null_found;
                                      -- Added by Dhiraj Gaikwad  on 26092012
            RETURN;
         END IF;

         BEGIN
            IF v_ctr_fixedhold_amount IS NOT NULL
            THEN
               prm_hold_amt := prm_tran_amt + v_ctr_fixedhold_amount;
            END IF;

            IF v_ctr_perhold_amount IS NOT NULL AND v_ctr_perhold_amount > 0
            THEN
               prm_hold_amt :=
                    prm_tran_amt
                  + (prm_tran_amt * (v_ctr_perhold_amount / 100));
            END IF;

            prm_hold_days := v_ctr_hold_days;
         EXCEPTION
            WHEN excp_decline_transaction
            THEN
               RAISE excp_decline_transaction;
            WHEN OTHERS
            THEN
               prm_err_flag := '21';
               prm_err_msg :=
                  'Error while Hold Amount /Hold Days Calculation '
                  || SQLERRM;
               RAISE excp_decline_transaction;
         END;

         prm_err_flag := '1';
         prm_err_msg := 'OK';

   EXCEPTION
      WHEN excp_decline_transaction
      THEN
         prm_err_flag := prm_err_flag;
         prm_err_msg := prm_err_msg;
      WHEN NO_DATA_FOUND
      THEN
         prm_err_flag := '70';
         prm_err_msg := 'Invalid Transaction code ';
      WHEN OTHERS
      THEN
         prm_err_flag := '21';
         prm_err_msg :=
                'Error while Country validation ' || SUBSTR (SQLERRM, 1, 300);
   END;


BEGIN
   prm_err_code := '1';
   prm_err_msg := 'OK';

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (prm_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   --EN CREATE HASH PAN
   --Sn find rules attached at card level or prodcattype level
   BEGIN
      SELECT COUNT (1)
        INTO v_rulecnt_card
        FROM pcms_card_excp_rulegroup
       WHERE pcer_pan_code = v_hash_pan
         AND TRUNC (prm_tran_datetime) BETWEEN TRUNC (pcer_valid_from)
                                           AND TRUNC (pcer_valid_to);

      IF v_rulecnt_card = 0
      THEN
         --Sn rule may be attached at cardtype level
         BEGIN
            SELECT cap_prod_code, cap_card_type
              INTO v_cap_prod_code, v_cap_card_type
              FROM cms_appl_pan
             WHERE cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               prm_err_code := '21';
               prm_err_msg := ' No record found for the card number ';
               RETURN;
            WHEN OTHERS
            THEN
               prm_err_code := '21';
               prm_err_msg :=
                     ' Error while selecting CMS_APPL_PAN  '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

         BEGIN
            SELECT COUNT (1)
              INTO v_rulecnt_cardtype
              FROM pcms_prodcattype_rulegroup
             WHERE ppr_prod_code = v_cap_prod_code
               AND ppr_card_type = v_cap_card_type
               AND TRUNC (prm_tran_datetime) BETWEEN TRUNC (ppr_valid_from)
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
                 FROM pcms_prod_rulegroup
                WHERE ppr_prod_code = v_cap_prod_code
                  AND TRUNC (prm_tran_datetime) BETWEEN TRUNC (ppr_valid_from)
                                                    AND TRUNC (ppr_valid_to);
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_err_code := '21';
                  prm_err_msg := 'Error while selecting rulcnt from product';
                  RETURN;
            END;

            --En rule may be attached at product
            IF v_rulecnt_product = 0
            THEN
               --No rules attached at Card or product or Cardtype level
               prm_err_msg := 'OK';

               IF     prm_delivery_channel IN ('02', '01')
                  AND prm_tran_code = '11'
               THEN
                  prm_hold_amount := prm_txn_amt;
                  prm_hold_days := 0;
               END IF;

               RETURN;
            ELSE
               BEGIN
                  --Sn select rule from cardtype
                  v_sql_stmt :=
                     'SELECT PPR_RULEGROUP_CODE FROM PCMS_PROD_RULEGROUP
                  WHERE PPR_PROD_CODE = :j AND
              TRUNC(:M) BETWEEN TRUNC(PPR_VALID_FROM) AND
              TRUNC(PPR_VALID_TO)';

                  OPEN cur_rulecode FOR v_sql_stmt
                  USING v_cap_prod_code, prm_tran_datetime;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     prm_err_code := '21';
                     prm_err_msg :=
                               'Error while selecting rulegroup for product ';
                     RETURN;
               END;
            END IF;
         ELSE
            BEGIN
               --Sn select rule from cardtype
               v_sql_stmt :=
                  'SELECT PPR_RULEGROUP_CODE FROM PCMS_PRODCATTYPE_RULEGROUP
                   WHERE PPR_PROD_CODE = :j
                   AND   PPR_CARD_TYPE = :M AND
            TRUNC(:N) BETWEEN TRUNC(PPR_VALID_FROM) AND
            TRUNC(PPR_VALID_TO)';

               OPEN cur_rulecode FOR v_sql_stmt
               USING v_cap_prod_code, v_cap_card_type, prm_tran_datetime;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_err_code := '21';
                  prm_err_msg :=
                            'Error while selecting rulegroup  at  card level';
                  RETURN;
            END;
         END IF;
      ELSE
         --Sn select rule from card
         BEGIN
            v_sql_stmt :=
               'SELECT PCER_RULEGROUP_ID FROM PCMS_CARD_EXCP_RULEGROUP
            WHERE PCER_PAN_CODE = :j AND TRUNC(:M) BETWEEN TRUNC(PCER_VALID_FROM) AND
         TRUNC(PCER_VALID_TO)';

            OPEN cur_rulecode FOR v_sql_stmt USING v_hash_pan,
            prm_tran_datetime;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_err_code := '21';
               prm_err_msg :=
                            'Error while selecting rulegroup  at  card level';
               RETURN;
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_err_msg := 'Error while selecting rulcnt from card level';
         RETURN;
   END;

   --Sn open cursor and fetch records
   LOOP
      FETCH cur_rulecode
       INTO v_rulegroupcode;

      EXIT WHEN cur_rulecode%NOTFOUND;

      --Sn find the rules attached to rulegroup
      BEGIN
         FOR i IN cur_rulegrpcode (v_rulegroupcode)
         LOOP
            --Sn find the rule detail
            FOR i1 IN cur_rule (i.ruleid)
            LOOP
               
               IF i1.ruletype = 5
               THEN
                 
                  IF prm_goto_nextpre <> 3
                  THEN                    
                     BEGIN
                        SELECT transactiongroupid, authtype
                          INTO v_transactiongroupid, v_authtype
                          FROM rule
                         WHERE ruleid = i.ruleid;

                        sp_check_preauthtransaction
                           (prm_inst_code,
                            v_transactiongroupid,
                            prm_tran_code,
                            prm_delivery_channel,
                            prm_mcc_code,
                            prm_merc_id,
                            v_authtype,
                            prm_txn_amt,
                            prm_hold_amount,
                            prm_hold_days,
                            prm_goto_nextpre,
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
                        WHEN OTHERS
                        THEN
                           prm_err_code := '21';
                           prm_err_msg :=
                                 'Error while selecting validating transaction rule'
                              || SUBSTR (SQLERRM, 1, 300);
                           RETURN;
                     END;
                  END IF;                
               
               END IF;
            END LOOP;
         --En find the rule detail
         END LOOP;
      END;
   --En find the rules attached to rulegroup
   END LOOP;
--En open cursor and fetch records
EXCEPTION
   WHEN OTHERS
   THEN
      prm_err_code := '21';
      prm_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error;