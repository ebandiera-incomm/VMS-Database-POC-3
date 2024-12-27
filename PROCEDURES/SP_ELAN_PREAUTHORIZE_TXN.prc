create or replace
PROCEDURE             VMSCMS.SP_ELAN_PREAUTHORIZE_TXN(
   prm_card_no            IN       VARCHAR2,
   prm_mcc_code           IN       VARCHAR2,
   prm_curr_code          IN       VARCHAR2,
   prm_tran_datetime      IN       DATE,
   prm_tran_code          IN       VARCHAR2,
   prm_inst_code          IN       NUMBER,
   prm_tran_date          IN       VARCHAR2,
   prm_txn_amt            IN       VARCHAR2,
   prm_delivery_channel   IN       VARCHAR2, --prm_delivery_channel variable Datatype changed from Number to varchar2  22092012 Dhiraj Gaikwad
   prm_merc_id            IN       VARCHAR2,                    -- need to add
   prm_country_code       IN       VARCHAR2,                    -- need to add
   prm_hold_amount        OUT      NUMBER,                      -- need to add
   prm_hold_days          OUT      NUMBER,                      -- need to add
   prm_err_code           OUT      VARCHAR2,
   prm_err_msg            OUT      VARCHAR2,
   prm_acqInstAlphaCntrycode      IN  VARCHAR2 DEFAULT NULL,
   prm_card_present_indicator	 IN  VARCHAR2 DEFAULT NULL		--Added for VMS_9272
)
IS
     /*************************************************
       * Created Date     :  31-MAY-2012
       * Created By       :  Dhiraj Gaikwad
       * PURPOSE          :  For ELAN  transaction
       * Modified By      :  Dhiraj Gaikwad
       * Modified Date    :  26-SEP-2012
       * Modified Reason  : Changes for Allowing Active rule group Validations only
       * Reviewer         :  B.Besky Anand
       * Reviewed Date    :  26-SEP-2012
       * Build Number     :  CMS3.5.1_RI0017.1

       * Modified By      :  Ramesh A
       * Modified Date    : 18/06/2013
       * Modified Reason  : Changes for MVHOST-392(MCC validation for product cattype)
       * Reviewer         :
       * Reviewed Date    :
       * Release Number   : RI0024.2_B0006

       * Modified By      :  Ramesh
       * Modified Date    :  04-JULY-2013
       * Modified Reason  :  11471
       * Reviewer         :  
       * Reviewed Date    : 
       * Build Number     : RI0024.3_B0003

       * Modified By      :  Sagar
       * Modified Date    :  07-Nov-2013
	   * Modified for     :  Defect :- 12956
       * Modified Reason  :  To ignore hardcoding of transaction code for preauth txns and to support 
                             preauth transaction for cash disbursement and ecommerce transaction
       * Reviewer         :  Dhiraj
       * Reviewed Date    :  08-Nov-2013
       * Build Number     : RI0027_B0003  

     * Modified By      : DHINAKARAN B
     * Modified Date    : 15-NOV-2018
     * Purpose          : VMS-619 (RULE)
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R08     

	 * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 09-AUG-2019.
     * Purpose          : VMS-1042 (Tip Tolerance Filter Enhancement: Transaction Filter Override)
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R09_B0002
	 
	 * Modified By      : Mohan E.
     * Modified Date    : 29-OCT-2024
     * Purpose          : VMS-9272 MCC Pre-Auths: Card Not Present (CNP) Rule Subset Creation
     * Reviewer         : Venkat
     * Release Number   : R105B3

   *************************************************/
   v_rulecnt_card         PLS_INTEGER;
   v_rulecnt_product      PLS_INTEGER;
   v_rulecnt_cardtype     PLS_INTEGER;
   v_cap_prod_code        cms_appl_pan.cap_prod_code%TYPE;
   v_cap_card_type        cms_appl_pan.cap_card_type%TYPE;
   v_err_flag             VARCHAR2 (3);
   v_err_msg              VARCHAR2 (900);
   v_from_date            DATE;
   v_to_date              DATE;

   v_merchantgroupid      rule.merchantgroupid%TYPE;
   v_mccgroupid           rule.mccgroupid%TYPE;
   v_countrygrpoupid      rule.countrygrpoupid%TYPE;
   v_transactiongroupid   rule.transactiongroupid%TYPE;

   v_authtype             rule.authtype%TYPE;
   v_fromtime             rule.fromtime%TYPE;
   v_totime               rule.totime%TYPE;


   --Added for MVHOST-392 on 18/06/2013

   v_rulegroup_code       pcms_prodcattype_rulegroup.PPR_RULEGROUP_CODE%type;
   v_check_mcc_cnt        PLS_INTEGER;


   --SN :- Added on 07-Nov-2013
   v_dr_cr_flag           CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
   v_tran_preauth_flag    CMS_TRANSACTION_MAST.CTM_PREAUTH_FLAG%TYPE;
   v_adjustment_flag      CMS_TRANSACTION_MAST.CTM_ADJUSTMENT_FLAG%TYPE;
   --EN :- Added on 07-Nov-2013    


   TYPE t_rulecodetype IS REF CURSOR;

   cur_rulecode           t_rulecodetype;
   v_sql_stmt             VARCHAR2 (500);
   v_rulegroupcode        pcms_card_excp_rulegroup.pcer_rulegroup_id%TYPE;
   v_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
   prm_goto_nextpre number (2):=0 ; -- added by Dhiraj Gaikwad on 26092012

    /*
    Commented by Dhiraj G on 25092012
      CURSOR cur_rulegrpcode (p_rulgroup IN VARCHAR2)
      IS
         SELECT ruleid
           FROM rulecode_group
          WHERE rulegroupid = p_rulgroup;
   */
   CURSOR cur_rulegrpcode (p_rulgroup IN VARCHAR2)
   IS
   SELECT a.ruleid
  FROM rulecode_group a, rulegrouping b
 WHERE a.rulegroupid = P_RULGROUP
   AND a.rulegroupid = b.rulegroupid
   AND b.activationstatus = 'Y' ;

   CURSOR cur_rule (p_ruleid IN VARCHAR2)
   IS
      SELECT ruleid, ruledesc, ruletype, authtype, mccgroupid, ccgroupid,
             usagetype, notransallowed, totalamountlimit, transcodegroupid,
             fromtime, totime, activationstatus, dateapplicable, fromdate,
             todate, act_lupd_date, act_inst_code, act_lupd_user,
             act_ins_date, act_ins_user
        FROM rule
       WHERE ruleid = p_ruleid AND activationstatus = 'Y';

-- Added by Dhiraj Gaikwad on 12062012 as we need to apply only the rule which are active

   --***********************************************************************--
   PROCEDURE sp_check_merchantid (
      prm_merchant_groupid   IN       VARCHAR2,
      prm_merc_id            IN       VARCHAR2,
      prm_auth_type          IN       VARCHAR2,
      prm_err_flag           OUT      VARCHAR2,
      prm_err_msg            OUT      VARCHAR2
   )
   IS
      v_check_cnt   PLS_INTEGER;
   BEGIN
      SELECT COUNT (*)
        INTO v_check_cnt
        FROM cms_mercidgrp_mercid
       WHERE cmm_merc_grpcode = prm_merchant_groupid
         AND cmm_merc_id = prm_merc_id;

      IF (v_check_cnt = 1 AND prm_auth_type = 'A') OR (v_check_cnt = 0
                                                                      --AND prm_auth_type = 'D'  --Commented by Dhiraj on 14092012
                                                      )
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
         prm_err_flag := '1';
         prm_err_msg := 'OK';
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
      v_check_cnt   PLS_INTEGER;
   BEGIN
      SELECT COUNT (*)
        INTO v_check_cnt
        FROM mccode_group
       WHERE mccodegroupid = prm_merchantgroup_code AND mccode = prm_mcc_code;

      IF (v_check_cnt = 1 AND prm_auth_type = 'A') OR (v_check_cnt = 0
                                                                      --AND prm_auth_type = 'D' --Commented by Dhiraj on 14092012
                                                      )
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
         prm_err_flag := '1';
         prm_err_msg := 'OK';
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
      Prm_Cntry_CODE        IN       VARCHAR2, 
      prm_err_flag          OUT      VARCHAR2,
      prm_err_msg           OUT      VARCHAR2
   )
   IS
    v_check_cnt PLS_INTEGER;
  type type_cntrycode is table of VARCHAR2(50);
  t_cntrycodes type_cntrycode;
BEGIN

  t_cntrycodes := type_cntrycode (prm_country_code,Prm_Cntry_CODE);

  FOR i IN 1..t_cntrycodes.count 
  LOOP
    BEGIN
      SELECT COUNT (*)
      INTO v_check_cnt
      FROM cms_cntrygrp_cntrycode
      WHERE CCC_CNTRY_GRPCODE = prm_country_groupid
      AND CCC_CNTRY_CODE      = t_cntrycodes(i);
      IF (v_check_cnt         = 1 AND prm_auth_type = 'A') OR (v_check_cnt = 0 ) THEN
        prm_err_flag         := '1';
        prm_err_msg          := 'OK';
      ELSE
        prm_err_flag := '70';
        prm_err_msg  := 'Invalid Country Code';
        EXIT;
      END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      prm_err_flag := '70';
      prm_err_msg  := 'Invalid Country Code';
      EXIT;
    WHEN OTHERS THEN
      prm_err_flag := '21';
      prm_err_msg  := 'Error while Merchant ID validation '||t_cntrycodes(i) || SUBSTR (SQLERRM, 1, 300);
      EXIT;
    END;
  END LOOP;
END;

--***********************************************************************--
   PROCEDURE sp_check_preauthtransaction (
      prm_inst_code          IN       NUMBER,
      prm_txnrule_groupid    IN       VARCHAR2,
      --  prm_txn_type           IN       VARCHAR2,
      prm_tran_code          IN       VARCHAR2,
      prm_delivery_channel   IN       VARCHAR2,   -- NUMBER, -- Changed datatype from NUMBER to VARCHAR2 on 25092012 Dhiraj G
      prm_mcc_code           IN       VARCHAR2,
      prm_merc_id            IN       VARCHAR2,
      prm_auth_type          IN       VARCHAR2,
      prm_tran_amt           IN       NUMBER,
      prm_hold_amt           OUT      NUMBER,
      prm_hold_days          OUT      NUMBER,
      prm_goto_nextpre          OUT      NUMBER ,-- Added by Dhiraj Gaikwad  on 26092012
      prm_err_flag           OUT      VARCHAR2,
      prm_err_msg            OUT      VARCHAR2,
      prm_card_present_indicator IN  VARCHAR2 DEFAULT NULL		--Added for VMS_9272
   )
   IS
      v_check_cnt                PLS_INTEGER;
      excp_decline_transaction   EXCEPTION;

      v_ctr_fixedhold_amount     cms_txncode_rule.ctr_fixedhold_amount%TYPE;
      v_ctr_perhold_amount       cms_txncode_rule.ctr_perhold_amount%TYPE;
      v_ctr_hold_days            cms_txncode_rule.ctr_hold_days%TYPE;

      v_null_found               NUMBER (2)                              := 0; -- Added on 21092012
      V_PARAM_VALUE              VARCHAR2(20);      --Added for VMS_9272
   BEGIN


      --IF prm_delivery_channel IN ('02', '01') AND prm_tran_code = '11'     --Commented on 07-Nov-2013 
 
		BEGIN
             SELECT CIP_PARAM_VALUE
               INTO V_PARAM_VALUE
               FROM CMS_INST_PARAM
              WHERE CIP_PARAM_KEY = 'VMS_9272_TOGGLE' AND CIP_INST_CODE = PRM_INST_CODE;			--Added for VMS_9272
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               V_PARAM_VALUE := 'Y'; 
            WHEN OTHERS THEN
               prm_err_flag := '21';
               prm_err_msg  := 'Error while selecting param value ';
              RETURN;
        END;
		
      IF prm_delivery_channel IN ('02', '01') AND  v_dr_cr_flag='NA' AND  v_tran_preauth_flag='Y' AND v_adjustment_flag='N' --Added on 07-Nov-2013
      -- onlly for Elan channel and transaction code 11
      THEN
         FOR i IN (SELECT   b.ctr_fixedhold_amount,b.ctr_perhold_amount,
                            b.ctr_hold_days,b.ctr_mcc_code,b.ctr_merchant_groupid,
                            b.ctr_fixedhold_amount_cnp, b.ctr_perhold_amount_cnp, b.ctr_hold_days_cnp,   --Added for VMS_9272
                            b.ctr_fixedhold_amount_cp, b.ctr_perhold_amount_cp, b.ctr_hold_days_cp,      --Added for VMS_9272
                            b.ctr_authorization_type_cnp, b.ctr_authorization_type_cp                    --Added for VMS_9272
                       FROM cms_txncode_rule b, cms_txncodegrp_txncode a
                      WHERE a.ctt_txnrule_grpcode = prm_txnrule_groupid
                        AND a.ctt_txnrule_id = b.ctr_txnrule_id
                        AND b.ctr_inst_code = prm_inst_code
                        AND b.ctr_txn_code = prm_tran_code
                        AND b.ctr_delv_chnl = prm_delivery_channel
                        AND b.ctr_merchant_groupid is not null
                   ORDER BY ctr_ins_date)
         LOOP

            --- Added for VMS-1042 (Tip Tolerance Filter Enhancement: Transaction Filter Override)
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
            IF   prm_card_present_indicator = '0' and i.ctr_authorization_type_cnp = 'N' and V_PARAM_VALUE = 'Y' then       --Added for VMS_9272
               v_ctr_fixedhold_amount := i.ctr_fixedhold_amount_cnp;
               v_ctr_perhold_amount := i.ctr_perhold_amount_cnp;
               v_ctr_hold_days := i.ctr_hold_days_cnp;
            ELSIF  prm_card_present_indicator = '1' and i.ctr_authorization_type_cp = 'Y' and V_PARAM_VALUE = 'Y'then       --Added for VMS_9272
               v_ctr_fixedhold_amount := i.ctr_fixedhold_amount_cp;
               v_ctr_perhold_amount := i.ctr_perhold_amount_cp;
               v_ctr_hold_days := i.ctr_hold_days_cp;
            ELSE
               v_ctr_fixedhold_amount := i.ctr_fixedhold_amount;
               v_ctr_perhold_amount := i.ctr_perhold_amount;
               v_ctr_hold_days := i.ctr_hold_days;
            END IF;
              v_null_found := 3; -- Added on 21092012
              prm_goto_nextpre:=v_null_found ; -- Added by Dhiraj Gaikwad  on 26092012
               EXIT;
            END IF;
         END LOOP;

         IF v_check_cnt IS  NULL
                    THEN
            FOR i IN (SELECT   b.ctr_fixedhold_amount,b.ctr_perhold_amount,
                            b.ctr_hold_days,b.ctr_mcc_code,b.ctr_merchant_groupid,
                             b.ctr_fixedhold_amount_cnp, b.ctr_perhold_amount_cnp, b.ctr_hold_days_cnp, --Added for VMS_9272
                             b.ctr_fixedhold_amount_cp, b.ctr_perhold_amount_cp, b.ctr_hold_days_cp,    --Added for VMS_9272
                             b.ctr_authorization_type_cnp,  b.ctr_authorization_type_cp                 --Added for VMS_9272
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
                WHEN NO_DATA_FOUND THEN
                    v_null_found := 2; 
                    prm_goto_nextpre:=v_null_found ;  
                WHEN OTHERS THEN
                    prm_err_flag := '21';
                    prm_err_msg := 'Error while Transaction Rule validation ' || SQLERRM;
                    RAISE excp_decline_transaction;
                END;

            IF v_check_cnt IS NOT NULL
            THEN
             IF   prm_card_present_indicator = '0' and i.ctr_authorization_type_cnp = 'N' and V_PARAM_VALUE = 'Y' then       --Added for VMS_9272
               v_ctr_fixedhold_amount := i.ctr_fixedhold_amount_cnp;
               v_ctr_perhold_amount := i.ctr_perhold_amount_cnp;
               v_ctr_hold_days := i.ctr_hold_days_cnp;               
            ELSIF  prm_card_present_indicator = '1' and i.ctr_authorization_type_cp = 'Y' and V_PARAM_VALUE = 'Y' then    --Added for VMS_9272
               v_ctr_fixedhold_amount := i.ctr_fixedhold_amount_cp;
               v_ctr_perhold_amount := i.ctr_perhold_amount_cp;
               v_ctr_hold_days := i.ctr_hold_days_cp;
            ELSE
               v_ctr_fixedhold_amount := i.ctr_fixedhold_amount;
               v_ctr_perhold_amount := i.ctr_perhold_amount;
               v_ctr_hold_days := i.ctr_hold_days;
            END IF;
              v_null_found := 3; -- Added on 21092012
              prm_goto_nextpre:=v_null_found ; -- Added by Dhiraj Gaikwad  on 26092012
               EXIT;
            END IF;
         END LOOP;
        end if;
         /* Start -- Added on 21092012  */
         IF v_null_found in( 2 ,0)
         THEN
            prm_hold_amt := prm_txn_amt;
            prm_hold_days := 0;
            prm_err_flag := '1';
            prm_err_msg := 'OK';
             prm_goto_nextpre:=v_null_found ; -- Added by Dhiraj Gaikwad  on 26092012
            RETURN;
         END IF;
/* End -- Added on 21092012  */
         IF prm_auth_type = 'A'
         THEN
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
         ELSE
            prm_err_flag := '70';
            prm_err_msg := 'Invalid Transaction Rule code ';
            RAISE excp_decline_transaction;
         END IF;
/*
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
            EXCEPTION
               WHEN excp_decline_transaction
               THEN
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
         ELSE
            prm_err_flag := '70';
            prm_err_msg := 'Invalid Transaction Rule code ';
            RAISE excp_decline_transaction;
         END IF; */
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
            WHEN NO_DATA_FOUND
            THEN
               prm_err_flag := '1';
               prm_err_msg := 'OK';
               RETURN;
            WHEN OTHERS
            THEN
               prm_err_flag := '21';
               prm_err_msg :=
                        'Error while Transaction Rule validation ' || SQLERRM;
               RAISE excp_decline_transaction;
         END;

         IF (v_check_cnt = 1 AND prm_auth_type = 'A') OR (v_check_cnt = 0
                                                                         --AND prm_auth_type = 'D' --Commented by Dhiraj on 14092012
                                                         )
         THEN
            prm_err_flag := '1';
            prm_err_msg := 'OK';
             v_null_found := 3; -- Added on 21092012
              prm_goto_nextpre:=v_null_found ; -- Added by Dhiraj Gaikwad  on 26092012
         ELSE
            prm_err_flag := '70';
            prm_err_msg := 'Invalid Transaction Rule code ';
            v_null_found := 3; -- Added on 21092012
            prm_goto_nextpre:=v_null_found ; -- Added by Dhiraj Gaikwad  on 26092012
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
         prm_err_msg := 'Invalid Transaction code ';
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
      v_check_cnt   PLS_INTEGER;
   BEGIN
      SELECT COUNT (*)
        INTO v_check_cnt
        FROM currencycode_group
       WHERE currencycodegroupid = prm_currencygroup_code
         AND currencycode = prm_currency_code;

      IF (v_check_cnt = 1 AND prm_auth_type = 'A') OR (v_check_cnt = 0
                                                                      --AND prm_auth_type = 'D' --Commented by Dhiraj on 14092012
                                                      )
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
         prm_err_flag := '1';
         prm_err_msg := 'OK';
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

    --SN :- Added on 07-Nov-2013

     BEGIN

           select ctm_credit_debit_flag,
                  ctm_preauth_flag,
                  ctm_adjustment_flag
           into   v_dr_cr_flag,
                  v_tran_preauth_flag,
                  v_adjustment_flag   
           from cms_transaction_mast
           where ctm_inst_code = prm_inst_code
           and   ctm_delivery_channel = prm_delivery_channel
           and   ctm_tran_code = prm_tran_code;

     Exception when no_data_found
     then

         prm_err_code := '70';
         prm_err_msg := 'Invalid Transaction code '||prm_tran_code||' and delivery channel '||prm_delivery_channel;
         RETURN;

     WHEN OTHERS
     THEN
         prm_err_code := '21';
         prm_err_msg :='Error while fetching flag values from tran master ' || SUBSTR (SQLERRM, 1, 100);
         RETURN;

     END;

    --EN :- Added on 07-Nov-2013


   --ST: Added for MVHOST-392 on 18/06/2013
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
     IF PRM_DELIVERY_CHANNEL = '02' THEN
      BEGIN
            SELECT PPR_RULEGROUP_CODE
              INTO v_rulegroup_code
              FROM pcms_prodcattype_rulegroup
             WHERE ppr_prod_code = v_cap_prod_code
               AND ppr_card_type = v_cap_card_type and PPR_ACTIVE_FLAG='Y' 
               and PPR_PERMRULE_FLAG='Y'; --Added for defect id: 11471 on 04/07/2013

         EXCEPTION
         WHEN NO_DATA_FOUND
          THEN
             NULL;
            WHEN OTHERS
            THEN
               prm_err_code := '21';
               prm_err_msg :=
                           'Error while selecting rulcnt from cardtype level'||SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;

      IF v_rulegroup_code is not null then

            BEGIN
               --Sn select rule from cardtype
              select count(*) into v_check_mcc_cnt from rulecode_group a, rulegrouping b,rule c, mccode_group d
              where  a.rulegroupid = b.rulegroupid AND b.activationstatus = 'Y'
              and a.ruleid =c.ruleid and c.mccgroupid= d.mccodegroupid and c.authtype='A'
              and a.rulegroupid=v_rulegroup_code  AND d.mccode = prm_mcc_code;


            IF v_check_mcc_cnt = 1  THEN
                prm_err_code := '1';
                prm_err_msg := 'OK';
            ELSE
                prm_err_code := '70';
                prm_err_msg := 'Invalid merchant code';
                RETURN;
            END IF;

            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_err_code := '21';
                  prm_err_msg :=
                            'Error while selecting rulegroup  at  card level'||SUBSTR (SQLERRM, 1, 300);
                  RETURN;
            END;
         END IF;
      END IF;
   --END: Added for MVHOST-392 on 18/06/2013

   --Sn find rules attached at card level or prodcattype level
   BEGIN
      SELECT COUNT (1)
        INTO v_rulecnt_card
        FROM pcms_card_excp_rulegroup
       WHERE pcer_pan_code = v_hash_pan
         AND TRUNC (prm_tran_datetime) BETWEEN TRUNC (pcer_valid_from)
                                           AND TRUNC (pcer_valid_to)  ;

      IF v_rulecnt_card = 0
      THEN
      --Commented for MVHOST-392 on 18/06/2013
      /*
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
         */

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

               IF  prm_delivery_channel IN ('02', '01')
                   AND v_dr_cr_flag = 'NA'               --Modified on 07-Nov-2013
                   AND v_tran_preauth_flag ='Y'               
                   AND  v_adjustment_flag = 'N'            
                   --AND prm_tran_code = '11'           --Commented on 07-Nov-2013

               THEN
                  prm_hold_amount := prm_txn_amt;
                  prm_hold_days := 0;
               END IF;

               RETURN;
            ELSE
               BEGIN
                  --Sn select rule from cardtype
                  --Order by clause added by Dhiraj Gaikwad on 26092012
                  v_sql_stmt :=
                     'SELECT PPR_RULEGROUP_CODE FROM PCMS_PROD_RULEGROUP
                  WHERE PPR_PROD_CODE = :j AND
              TRUNC(:M) BETWEEN TRUNC(PPR_VALID_FROM) AND
              TRUNC(PPR_VALID_TO) ORDER BY PPR_INS_DATE';

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
                 --Order by clause added by Dhiraj Gaikwad on 26092012
               v_sql_stmt :=
                  'SELECT PPR_RULEGROUP_CODE FROM PCMS_PRODCATTYPE_RULEGROUP
                   WHERE PPR_PROD_CODE = :j
                   AND   PPR_CARD_TYPE = :M AND
            TRUNC(:N) BETWEEN TRUNC(PPR_VALID_FROM) AND
            TRUNC(PPR_VALID_TO) ORDER BY PPR_INS_DATE ';

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
           --Order by clause added by Dhiraj Gaikwad on 26092012
            v_sql_stmt :=
               'SELECT PCER_RULEGROUP_ID FROM PCMS_CARD_EXCP_RULEGROUP
            WHERE PCER_PAN_CODE = :j AND TRUNC(:M) BETWEEN TRUNC(PCER_VALID_FROM) AND
         TRUNC(PCER_VALID_TO) ORDER BY PCER_INS_DATE ';

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
                  IF     (prm_country_code IS NOT NULL OR prm_acqInstAlphaCntrycode IS NOT NULL)
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
                                          prm_acqInstAlphaCntrycode,
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
                   -- IF     prm_delivery_channel IN ('02', '01')
                   --    AND prm_tran_code = '11'
                  --  THEN
                       --En  transaction  based

                if prm_goto_nextpre<>3 then  -- Added by Dhiraj Gaikwad 26092012


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
                                                  prm_goto_nextpre ,-- Added by Dhiraj Gaikwad  on 26092012
                                                  v_err_flag,
                                                  v_err_msg,
                                                  prm_card_present_indicator  --Added for VMS_9272
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

                END IF  ; -- Added by Dhiraj Gaikwad 26092012
               --   END IF;
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
show error