CREATE OR REPLACE PROCEDURE VMSCMS.sp_elan_preauthorize_txn0906 (
   prm_card_no            IN       VARCHAR2,
   prm_mcc_code           IN       VARCHAR2,
   prm_curr_code          IN       VARCHAR2,
   prm_tran_datetime      IN       DATE,
   prm_tran_code          IN       VARCHAR2,
   prm_inst_code          IN       NUMBER,
   prm_tran_date          IN       VARCHAR2,
   prm_txn_amt            IN       VARCHAR2,
   prm_delivery_channel   IN       NUMBER,
   prm_merc_id            IN       VARCHAR2,                    -- need to add
   prm_country_code       IN       VARCHAR2,                    -- need to add
   prm_hold_amount        OUT      NUMBER,                      -- need to add
   prm_hold_days          OUT      NUMBER,                      -- need to add
   prm_err_code           OUT      VARCHAR2,
   prm_err_msg            OUT      VARCHAR2
)
IS

   /*************************************************
     * Created Date     :  31-MAY-2012
     * Created By       :  Dhiraj Gaikwad
     * PURPOSE          :  For ELAN  transaction
     * Modified By      :  Dhiraj Gaikwad
     * Modified Date    :  08-Jun-2012
     * Modified Reason  : For setting hold days and hold amount values when no rule is attached
     * Reviewer         :
     * Reviewed Date    :
     * Release Number     :R0009_B0008
 *************************************************/
   v_rulecnt_card         NUMBER (3);
   v_rulecnt_product      NUMBER (3);
   v_rulecnt_cardtype     NUMBER (3);
   v_cap_prod_code        cms_appl_pan.cap_prod_code%TYPE;
   v_cap_card_type        cms_appl_pan.cap_card_type%TYPE;
   v_err_flag             VARCHAR2 (3);
   v_err_msg              VARCHAR2 (900);
   v_from_date            DATE;
   v_to_date              DATE;
   v_tran_time            DATE;
   v_merchantgroupid      rule.merchantgroupid%TYPE;
   v_mccgroupid           rule.mccgroupid%TYPE;
   v_countrygrpoupid      rule.countrygrpoupid%TYPE;
   v_transactiongroupid   rule.transactiongroupid%TYPE;
   v_transcodegroupid     rule.transcodegroupid%TYPE;
   v_authtype             rule.authtype%TYPE;
   v_fromtime             rule.fromtime%TYPE;
   v_totime               rule.totime%TYPE;
   v_usagetype            rule.usagetype%TYPE;
   v_notransallowed       rule.notransallowed%TYPE;
   v_totalamountlimit     rule.totalamountlimit%TYPE;

   TYPE t_rulecodetype IS REF CURSOR;

   cur_rulecode           t_rulecodetype;
   v_sql_stmt             VARCHAR2 (500);
   v_rulegroupcode        pcms_card_excp_rulegroup.pcer_rulegroup_id%TYPE;
   v_hash_pan             cms_appl_pan.cap_pan_code%TYPE;

   CURSOR cur_rulegrpcode (p_rulgroup IN VARCHAR2)
   IS
      SELECT ruleid
        FROM rulecode_group
       WHERE rulegroupid = p_rulgroup;

   CURSOR cur_rule (p_ruleid IN VARCHAR2)
   IS
      SELECT ruleid, ruledesc, ruletype, authtype, mccgroupid, ccgroupid,
             usagetype, notransallowed, totalamountlimit, transcodegroupid,
             fromtime, totime, activationstatus, dateapplicable, fromdate,
             todate, act_lupd_date, act_inst_code, act_lupd_user,
             act_ins_date, act_ins_user
        FROM rule
       WHERE ruleid = p_ruleid;

--***********************************************************************--
   PROCEDURE sp_check_merchantid (
      prm_merchant_groupid   IN       VARCHAR2,
      prm_merc_id            IN       VARCHAR2,
      prm_auth_type          IN       VARCHAR2,
      prm_err_flag           OUT      VARCHAR2,
      prm_err_msg            OUT      VARCHAR2
   )
   IS
      v_check_cnt   NUMBER (1);
   BEGIN
      SELECT COUNT (*)
        INTO v_check_cnt
        FROM cms_mercidgrp_mercid
       WHERE cmm_merc_grpcode = prm_merchant_groupid
         AND cmm_merc_id = prm_merc_id;

      IF    (v_check_cnt = 1 AND prm_auth_type = 'A')
         OR (v_check_cnt = 0 AND prm_auth_type = 'D')
      THEN
         prm_err_flag := '1';
         prm_err_msg := 'OK';
      ELSE
         prm_err_flag := '70';
         prm_err_msg := 'Invalid Merchant code';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_flag := '70';
         prm_err_msg := 'Invalid Merchant code ';
      WHEN OTHERS
      THEN
         prm_err_flag := '21';
         prm_err_msg :=
               'Error while Merchant validation ' || SUBSTR (SQLERRM, 1, 300);
   END;

--***********************************************************************--
   PROCEDURE sp_check_merchant (
      prm_merchantgroup_code   IN       VARCHAR2,
      prm_mcc_code             IN       VARCHAR2,
      prm_auth_type            IN       VARCHAR2,
      prm_err_flag             OUT      VARCHAR2,
      prm_err_msg              OUT      VARCHAR2
   )
   IS
      v_check_cnt   NUMBER (1);
   BEGIN
      SELECT COUNT (*)
        INTO v_check_cnt
        FROM mccode_group
       WHERE mccodegroupid = prm_merchantgroup_code AND mccode = prm_mcc_code;

      IF    (v_check_cnt = 1 AND prm_auth_type = 'A')
         OR (v_check_cnt = 0 AND prm_auth_type = 'D')
      THEN
         prm_err_flag := '1';
         prm_err_msg := 'OK';
      ELSE
         prm_err_flag := '70';
         prm_err_msg := 'Invalid merchant code';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_flag := '70';
         prm_err_msg := 'Invalid merchant code ';
      WHEN OTHERS
      THEN
         prm_err_flag := '21';
         prm_err_msg :=
               'Error while merchant validation ' || SUBSTR (SQLERRM, 1, 300);
   END;

--***********************************************************************--
   PROCEDURE sp_check_country (
      prm_country_groupid   IN       VARCHAR2,
      prm_country_code      IN       VARCHAR2,
      prm_auth_type         IN       VARCHAR2,
      prm_err_flag          OUT      VARCHAR2,
      prm_err_msg           OUT      VARCHAR2
   )
   IS
      v_check_cnt   NUMBER (1);
   BEGIN
      SELECT COUNT (*)
        INTO v_check_cnt
        FROM cms_cntrygrp_cntrycode
       WHERE ccc_cntry_grpcode = prm_country_groupid
         AND ccc_cntry_code = prm_country_code;

      IF    (v_check_cnt = 1 AND prm_auth_type = 'A')
         OR (v_check_cnt = 0 AND prm_auth_type = 'D')
      THEN
         prm_err_flag := '1';
         prm_err_msg := 'OK';
      ELSE
         prm_err_flag := '70';
         prm_err_msg := 'Invalid Country code';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_flag := '70';
         prm_err_msg := 'Invalid Country code ';
      WHEN OTHERS
      THEN
         prm_err_flag := '21';
         prm_err_msg :=
                'Error while Country validation ' || SUBSTR (SQLERRM, 1, 300);
   END;

--***********************************************************************--
   PROCEDURE sp_check_preauthtransaction (
      prm_inst_code          IN       NUMBER,
      prm_txnrule_groupid    IN       VARCHAR2,
      --  prm_txn_type           IN       VARCHAR2,
      prm_tran_code          IN       VARCHAR2,
      prm_delivery_channel   IN       NUMBER,
      prm_mcc_code           IN       VARCHAR2,
      prm_merc_id            IN       VARCHAR2,
      prm_auth_type          IN       VARCHAR2,
      prm_tran_amt           IN       NUMBER,
      prm_hold_amt           OUT      NUMBER,
      prm_hold_days          OUT      NUMBER,
      prm_err_flag           OUT      VARCHAR2,
      prm_err_msg            OUT      VARCHAR2
   )
   IS
v_check_cnt                NUMBER (1);
      excp_decline_transaction   EXCEPTION;
      v_ctr_inst_code            cms_txncode_rule.ctr_inst_code%TYPE;
      v_ctr_txn_code             cms_txncode_rule.ctr_txn_code%TYPE;
      v_ctr_delv_chnl            cms_txncode_rule.ctr_delv_chnl%TYPE;
      v_ctr_txn_type             cms_txncode_rule.ctr_txn_type%TYPE;
      v_ctr_fixedhold_amount     cms_txncode_rule.ctr_fixedhold_amount%TYPE;
      v_ctr_perhold_amount       cms_txncode_rule.ctr_perhold_amount%TYPE;
      v_ctr_hold_days            cms_txncode_rule.ctr_hold_days%TYPE;
      v_ctr_mcc_code             cms_txncode_rule.ctr_mcc_code%TYPE;
   BEGIN
      IF prm_delivery_channel IN ('02', '01') AND prm_tran_code = '11'
      -- onlly for Elan channel and transaction code 11
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO v_check_cnt
              FROM cms_txncode_rule b, cms_txncodegrp_txncode a
             WHERE a.ctt_txnrule_grpcode = prm_txnrule_groupid
               AND a.ctt_txnrule_id = b.ctr_txnrule_id
               AND b.ctr_mcc_code = prm_mcc_code
               AND b.ctr_inst_code = prm_inst_code
               AND b.ctr_txn_code = prm_tran_code
               AND b.ctr_delv_chnl = prm_delivery_channel;
         --  AND b.ctr_txn_type = prm_txn_type;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_err_flag := '21';
               prm_err_msg :=
                        'Error while Transaction Rule validation ' || SQLERRM;
               RAISE excp_decline_transaction;
         END;

         IF    (v_check_cnt = 1 AND prm_auth_type = 'A')
            OR (v_check_cnt = 0 AND prm_auth_type = 'D')
         THEN
            BEGIN
               SELECT ctr_fixedhold_amount, ctr_perhold_amount,
                      ctr_hold_days
                 INTO v_ctr_fixedhold_amount, v_ctr_perhold_amount,
                      v_ctr_hold_days
                 FROM cms_txncode_rule b, cms_txncodegrp_txncode a
                WHERE a.ctt_txnrule_grpcode = prm_txnrule_groupid
                  AND a.ctt_txnrule_id = b.ctr_txnrule_id
                  AND b.ctr_mcc_code = prm_mcc_code
                  AND b.ctr_inst_code = prm_inst_code
                  AND b.ctr_txn_code = prm_tran_code
                  AND b.ctr_delv_chnl = prm_delivery_channel;
            -- AND b.ctr_txn_type = prm_txn_type;
            EXCEPTION
               WHEN excp_decline_transaction
               THEN
                  RAISE excp_decline_transaction;
               WHEN NO_DATA_FOUND
               THEN
                  prm_err_flag := '70';
                  prm_err_msg := 'Invalid Transaction Rule code ';
                  RAISE excp_decline_transaction;
               WHEN OTHERS
               THEN
                  prm_err_flag := '21';
                  prm_err_msg :=
                        'Error while Transaction Rule validation ' || SQLERRM;
                  RAISE excp_decline_transaction;
            END;

            BEGIN
               IF v_ctr_fixedhold_amount IS NOT NULL
               THEN
                  prm_hold_amt := prm_tran_amt + v_ctr_fixedhold_amount;
               END IF;

               IF v_ctr_perhold_amount IS NOT NULL
                  AND v_ctr_perhold_amount > 0
               THEN
                  prm_hold_amt :=
                       prm_tran_amt
                     + (prm_tran_amt * (v_ctr_perhold_amount / 100));
               END IF;

                --IF prm_hold_days > v_ctr_hold_days
               -- THEN
               --    prm_hold_days := prm_hold_days;
               -- ELSE
               prm_hold_days := v_ctr_hold_days;
            --  END IF;
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
         ELSE
            prm_err_flag := '70';
            prm_err_msg := 'Invalid Transaction Rule code ';
            RAISE excp_decline_transaction;
         END IF;
      ELSE
         BEGIN
            SELECT COUNT (*)
              INTO v_check_cnt
              FROM cms_txncode_rule b, cms_txncodegrp_txncode a
             WHERE a.ctt_txnrule_grpcode = prm_txnrule_groupid
               AND a.ctt_txnrule_id = b.ctr_txnrule_id
               AND b.ctr_inst_code = prm_inst_code
               AND b.ctr_txn_code = prm_tran_code
               AND b.ctr_delv_chnl = prm_delivery_channel;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_err_flag := '21';
               prm_err_msg :=
                        'Error while Transaction Rule validation ' || SQLERRM;
               RAISE excp_decline_transaction;
         END;

         IF    (v_check_cnt = 1 AND prm_auth_type = 'A')
            OR (v_check_cnt = 0 AND prm_auth_type = 'D')
         THEN
            prm_err_flag := '1';
            prm_err_msg := 'OK';
         ELSE
            prm_err_flag := '70';
            prm_err_msg := 'Invalid Transaction Rule code ';
         END IF;
      END IF;
   EXCEPTION
      WHEN excp_decline_transaction
      THEN
         prm_err_flag := prm_err_flag;
         prm_err_msg := prm_err_msg;
      WHEN NO_DATA_FOUND
      THEN
         prm_err_flag := '70';
         prm_err_msg := 'Invalid Country code ';
      WHEN OTHERS
      THEN
         prm_err_flag := '21';
         prm_err_msg :=
                'Error while Country validation ' || SUBSTR (SQLERRM, 1, 300);
   END;

--***********************************************************************--
   PROCEDURE sp_check_currency (
      prm_currencygroup_code   IN       VARCHAR2,
      prm_currency_code        IN       VARCHAR2,
      prm_auth_type            IN       VARCHAR2,
      prm_err_flag             OUT      VARCHAR2,
      prm_err_msg              OUT      VARCHAR2
   )
   IS
      v_check_cnt   NUMBER (1);
   BEGIN
      SELECT COUNT (*)
        INTO v_check_cnt
        FROM currencycode_group
       WHERE currencycodegroupid = prm_currencygroup_code
         AND currencycode = prm_currency_code;

      IF    (v_check_cnt = 1 AND prm_auth_type = 'A')
         OR (v_check_cnt = 0 AND prm_auth_type = 'D')
      THEN
         prm_err_flag := '1';
         prm_err_msg := 'OK';
      ELSE
         prm_err_flag := '70';
         prm_err_msg := 'Invalid transaction currency';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_flag := '70';
         prm_err_msg := 'Invalid transaction currency ';
      WHEN OTHERS
      THEN
         prm_err_flag := '21';
         prm_err_msg :=
               'Error while currency validation ' || SUBSTR (SQLERRM, 1, 300);
   END;
--***********************************************************************--
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
                  prm_hold_days:=0 ;
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
               IF i1.ruletype = 1
               THEN
                  IF     prm_merc_id IS NOT NULL
                     AND prm_delivery_channel IN ('02', '01')
                  THEN
                     --Sn Merchant Id Based
                     BEGIN
                        SELECT merchantgroupid, authtype
                          INTO v_merchantgroupid, v_authtype
                          FROM rule
                         WHERE ruleid = i.ruleid;

                        sp_check_merchantid (v_merchantgroupid,
                                             prm_merc_id,
                                             v_authtype,
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
                                 'Error while selecting rulcnt from cardtype level'
                              || SUBSTR (SQLERRM, 1, 300);
                           RETURN;
                     END;
                  END IF;
               --En Merchant Id Based
               ELSIF i1.ruletype = 2
               THEN
                  --Sn find merchant group
                  IF prm_delivery_channel = '02'
                  THEN
                     BEGIN
                        SELECT mccgroupid, authtype
                          INTO v_mccgroupid, v_authtype
                          FROM rule
                         WHERE ruleid = i.ruleid;

                        sp_check_merchant (v_mccgroupid,
                                           prm_mcc_code,
                                           v_authtype,
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
                                 'Error while selecting rulcnt from cardtype level'
                              || SUBSTR (SQLERRM, 1, 300);
                           RETURN;
                     END;
                  END IF;
               --En find merchant group
               ELSIF i1.ruletype = 3
               THEN
                  IF     prm_country_code IS NOT NULL
                     AND prm_delivery_channel IN ('02', '01')
                  THEN
                     --Sn Country Group
                     BEGIN
                        SELECT countrygrpoupid, authtype
                          INTO v_countrygrpoupid, v_authtype
                          FROM rule
                         WHERE ruleid = i.ruleid;

                        sp_check_country (v_countrygrpoupid,
                                          prm_country_code,
                                          v_authtype,
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
                                 'Error while selecting rulcnt from cardtype level'
                              || SUBSTR (SQLERRM, 1, 300);
                           RETURN;
                     END;
                  END IF;
               --En Country Group
               ELSIF i1.ruletype = 4
               THEN
                  --Sn time basedbased
                  BEGIN
                     SELECT authtype, fromtime, totime
                       INTO v_authtype, v_fromtime, v_totime
                       FROM rule
                      WHERE ruleid = i.ruleid;

                     SELECT TO_DATE (   SUBSTR (TRIM (prm_tran_date), 1, 8)
                                     || ' '
                                     || v_fromtime,
                                     'yyyymmdd hh24:mi'
                                    )
                       INTO v_from_date
                       FROM DUAL;

                     SELECT TO_DATE (   SUBSTR (TRIM (prm_tran_date), 1, 8)
                                     || ' '
                                     || v_totime,
                                     'yyyymmdd hh24:mi'
                                    )
                       INTO v_to_date
                       FROM DUAL;

                     IF v_authtype = 'A'
                     THEN
                        IF (prm_tran_datetime BETWEEN v_from_date AND v_to_date
                           )
                        THEN
                           prm_err_code := '1';
                           prm_err_msg := 'OK';
                        ELSE
                           prm_err_code := '70';
                           prm_err_msg := 'Invalid Transaction time ';
                           RETURN;
                        END IF;
                     END IF;

                     IF v_authtype = 'D'
                     THEN
                        IF (prm_tran_datetime BETWEEN v_from_date AND v_to_date
                           )
                        THEN
                           prm_err_code := '70';
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
               ELSIF i1.ruletype = 5
               THEN
                  --En  transaction  based
                  BEGIN
                     SELECT transactiongroupid, authtype
                       INTO v_transactiongroupid, v_authtype
                       FROM rule
                      WHERE ruleid = i.ruleid;

                     sp_check_preauthtransaction (prm_inst_code,
                                                  v_transactiongroupid,
                                                  prm_tran_code,
                                                  prm_delivery_channel,
                                                  prm_mcc_code,
                                                  prm_merc_id,
                                                  v_authtype,
                                                  prm_txn_amt,
                                                  prm_hold_amount,
                                                  prm_hold_days,
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
               --En  transaction  based
               ELSIF i1.ruletype = 6
               THEN
                  --Sn currency  based
                  BEGIN
                     SELECT ccgroupid, authtype
                       INTO v_mccgroupid, v_authtype
                       FROM rule
                      WHERE ruleid = i.ruleid;

                     sp_check_currency (v_mccgroupid,
                                        prm_curr_code,
                                        v_authtype,
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
                              'Error while selecting for currency group'
                           || SUBSTR (SQLERRM, 1, 300);
                        RETURN;
                  END;
               --En currency  based
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


