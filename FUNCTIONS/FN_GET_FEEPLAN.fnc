 CREATE OR REPLACE FUNCTION vmscms.fn_get_feeplan (
   prm_inst_code     IN   NUMBER,
   prm_card_number   IN   VARCHAR2
)
   RETURN VARCHAR2
IS
/***********************************************************************************************
     * Created Date                 : 11/Jul/2012.
     * Created By                   : Sagar m.
     * Purpose                      : To get fee plan attached for Card
     * Last Modification Done by    : Sagar M
     * Last Modification Date       : 22-Aug-2012
     * Mofication Reason            : change date format while fetching details from product level
                                      initially DD-MON-YYYY change to mm/dd/yyyy AND sysdate compared
                                      To fetch active fee plan
     * Build Number                 : RI0014.1_B0003

     * Modified By      : Dnyaneshwar J
     * Modified Date    : 02-04-2014
     * Modified For     : DFCCSD-101

     * Modified By      : MageshKumar S
     * Modified Date    : 12-Aug-2014
     * Modified For     : DFCCSD-359
     * Modified Reason  : Next Monthly Fee Date display
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.1_B0003
     
     * Modified By      : Dhinakaran B
     * Modified Date    : 01-Oct-2014
     * Modified For     : Mantis id- 15774
     * Reviewer         : Spankaj  
     * Build Number     : RI0027.4_B0002
*************************************************************************************************/
   v_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
   exp_reject_record      EXCEPTION;
   exp_noplan_found       EXCEPTION;
   v_prod_code            cms_appl_pan.cap_prod_code%TYPE;
   v_card_type            cms_appl_pan.cap_card_type%TYPE;
   exp_main               EXCEPTION;
   v_fee_plan             cms_fee_plan.cfp_plan_desc%TYPE;
   v_cafgen_date          cms_appl_pan.cap_cafgen_date%TYPE;
                       --Added by Dnyaneshwar J on 02 Apr 2014 for DFCCSD-101
   v_valid_from           VARCHAR2 (10);
   prm_error              VARCHAR2 (500);
   prm_feeplan_validfrm   VARCHAR2 (500);
   v_next_mb_date         cms_appl_pan.cap_next_mb_date%TYPE;
                                                      -- Added for DFCCSD-359
   v_acct_id              cms_appl_pan.cap_acct_id%TYPE;
                                                      -- Added for DFCCSD-359
   v_first_load_date      cms_acct_mast.cam_first_load_date%TYPE;
                                                      -- Added for DFCCSD-359
   v_date_assessment      cms_fee_mast.cfm_date_assessment%TYPE;
                                                      -- Added for DFCCSD-359
   v_actv_date            cms_appl_pan.cap_active_date%TYPE;
                                                      -- Added for DFCCSD-359
BEGIN
   prm_error := 'OK';

   BEGIN
      v_hash_pan := gethash (prm_card_number);
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_error :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RETURN prm_error;
   END;

   BEGIN
      SELECT cap_prod_code, cap_card_type, cap_cafgen_date,
                     --Modified by Dnyaneshwar J on 02 Apr 2014 for DFCCSD-101
             cap_next_mb_date, cap_acct_id,
             cap_active_date                           -- Added for DFCCSD-359
        INTO v_prod_code, v_card_type, v_cafgen_date,
                     --Modified by Dnyaneshwar J on 02 Apr 2014 for DFCCSD-101
             v_next_mb_date, v_acct_id,
             v_actv_date                               -- Added for DFCCSD-359
        FROM cms_appl_pan
       WHERE cap_inst_code = prm_inst_code AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_error := 'ERROR FROM PAN DATA SECTION =>' || SQLERRM;
         RETURN prm_error;
   END;

   BEGIN                                                            -- BEGIN 1
-----------------------------------------
--SN : Check fees attached at card level
-----------------------------------------
      SELECT cce_fee_plan, TO_CHAR (a.cce_valid_from, 'MM/DD/YYYY')
        INTO v_fee_plan, v_valid_from
        FROM cms_card_excpfee a, cms_appl_pan b, cms_fee_plan f
       WHERE cce_inst_code = prm_inst_code
         AND a.cce_pan_code = v_hash_pan
         AND a.cce_inst_code = b.cap_inst_code
         AND a.cce_pan_code = b.cap_pan_code
         AND a.cce_inst_code = f.cfp_inst_code
         AND a.cce_fee_plan = f.cfp_plan_id
         AND (   (    cce_valid_to IS NOT NULL
                  AND (TRUNC (SYSDATE) BETWEEN cce_valid_from AND cce_valid_to
                      )
                 )
              OR (cce_valid_to IS NULL AND TRUNC (SYSDATE) >= cce_valid_from)
             );            -- added by sagar to fetch active plan on 22Aug2012
   --ORDER BY a.cce_valid_from;

   -----------------------------------------
--EN : Check fees attached at card level
-----------------------------------------
   EXCEPTION                                                    -- EXCEPTION 1
      WHEN NO_DATA_FOUND
      THEN
---------------------------------------------------
--SN : Check fees attached at product catagory level
---------------------------------------------------
         BEGIN                                                     -- BEGIN 2
            SELECT cpf_fee_plan, TO_CHAR (a.cpf_valid_from, 'mm/dd/yyyy')
              INTO v_fee_plan, v_valid_from
              FROM cms_prodcattype_fees a,
                   cms_prod_cattype g,
                   cms_prod_mast p,
                   cms_fee_plan h
             WHERE cpf_inst_code = prm_inst_code
               AND a.cpf_prod_code = v_prod_code
               AND a.cpf_card_type = v_card_type
               AND a.cpf_inst_code = g.cpc_inst_code
               AND a.cpf_prod_code = g.cpc_prod_code
               AND a.cpf_card_type = g.cpc_card_type
               AND p.cpm_prod_code = a.cpf_prod_code
               AND p.cpm_inst_code = a.cpf_inst_code
               AND a.cpf_inst_code = h.cfp_inst_code
               AND a.cpf_fee_plan = h.cfp_plan_id
               AND (   (    cpf_valid_to IS NOT NULL
                        AND (TRUNC (SYSDATE) BETWEEN cpf_valid_from
                                                 AND cpf_valid_to
                            )
                       )
                    OR (    cpf_valid_to IS NULL
                        AND TRUNC (SYSDATE) >= cpf_valid_from
                       )
                   );      -- added by sagar to fetch active plan on 22Aug2012
         --ORDER BY a.cpf_valid_from;

         ---------------------------------------------------
--EN : Check fees attached at product catagory level
---------------------------------------------------
         EXCEPTION                                              -- EXCEPTION 2
            WHEN NO_DATA_FOUND
            THEN
---------------------------------------------------
--SN : Check fees attached at product level
---------------------------------------------------
               BEGIN                                               -- BEGIN 3
                  SELECT cpf_fee_plan,
                         TO_CHAR (a.cpf_valid_from, 'mm/dd/yyyy')
                    INTO v_fee_plan,
                         v_valid_from
                    FROM cms_prod_fees a, cms_prod_mast b, cms_fee_plan e
                   WHERE cpf_inst_code = prm_inst_code
                     AND a.cpf_prod_code = v_prod_code
                     AND a.cpf_inst_code = b.cpm_inst_code
                     AND a.cpf_prod_code = b.cpm_prod_code
                     AND a.cpf_inst_code = e.cfp_inst_code
                     AND a.cpf_fee_plan = e.cfp_plan_id
                     AND UPPER (cpm_marc_prod_flag) = 'N'
                     AND (   (    cpf_valid_to IS NOT NULL
                              AND (TRUNC (SYSDATE) BETWEEN cpf_valid_from
                                                       AND cpf_valid_to
                                  )
                             )
                          OR (    cpf_valid_to IS NULL
                              AND TRUNC (SYSDATE) >= cpf_valid_from
                             )
                         );
                           -- added by sagar to fetch active plan on 22Aug2012
               --order by a.cpf_valid_from ;
               EXCEPTION                                     -- -- EXCEPTION 3
                  WHEN NO_DATA_FOUND
                  THEN
                     prm_error := 'No Fee Plan attached to this Card';
                     RETURN prm_error;
                  WHEN OTHERS
                  THEN
                     prm_error :=
                           'ERROR FROM MAIN 3 =>' || SUBSTR (SQLERRM, 1, 100);
                     RETURN prm_error;
               END;                                                   -- END 3
---------------------------------------------------
--EN : Check fees attached at product level
---------------------------------------------------
            WHEN OTHERS
            THEN
               prm_error :=
                           'ERROR FROM MAIN 2 =>' || SUBSTR (SQLERRM, 1, 100);
               RETURN prm_error;
         END;                                                         -- END 2
      WHEN OTHERS
      THEN
         prm_error := 'ERROR FROM MAIN 1 =>' || SUBSTR (SQLERRM, 1, 100);
         RETURN prm_error;
   END;

   --SN - Added for DFCCSD-359
   IF v_next_mb_date IS NOT NULL
   THEN
      v_next_mb_date := v_next_mb_date;
   ELSIF     v_next_mb_date IS NULL
         AND v_fee_plan IS NOT NULL
         AND v_actv_date IS NOT NULL
   THEN
      BEGIN
         SELECT cfm_date_assessment
           INTO v_date_assessment
           FROM cms_fee_mast, cms_fee_types, cms_fee_feeplan
          WHERE cfm_inst_code = prm_inst_code
            AND cff_fee_code = cfm_fee_code
            AND cfm_feetype_code = cft_feetype_code
            AND cft_inst_code = cfm_inst_code
            AND cff_inst_code = cfm_inst_code
            AND cff_fee_plan = v_fee_plan
            AND cff_fee_freq = cft_fee_freq
            AND cft_fee_freq = 'M'
            AND cft_fee_type = 'M';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            prm_error := 'FEE PLAN NOT FOUND FOR THE FEE PLAN ID';
         --return prm_error;
         WHEN OTHERS
         THEN
            prm_error := 'ERROR FROM MAIN 4 =>' || SUBSTR (SQLERRM, 1, 100);
      --return prm_error;
      END;

      IF v_date_assessment = 'AD'
      THEN
         IF TRUNC (v_actv_date) < TRUNC (SYSDATE)
         THEN
            IF TRUNC (ADD_MONTHS (v_actv_date, 2)) >= TRUNC (SYSDATE)
            THEN
               v_next_mb_date := ADD_MONTHS (v_actv_date, 2);
            ELSE
               v_next_mb_date := ADD_MONTHS (v_actv_date, 1);
            END IF;
         ELSE
            v_next_mb_date := ADD_MONTHS (SYSDATE, 1);
         END IF;
      ELSIF v_date_assessment = 'FD'
      THEN
         IF TRUNC (v_actv_date) < TRUNC (SYSDATE)
         THEN
            IF TRUNC (LAST_DAY (ADD_MONTHS (v_actv_date, 1)) + 1) >=
                                                              TRUNC (SYSDATE)
            THEN
               v_next_mb_date := LAST_DAY (ADD_MONTHS (v_actv_date, 1)) + 1;
            ELSE
               v_next_mb_date := LAST_DAY (v_actv_date) + 1;
            END IF;
         ELSE
            v_next_mb_date := LAST_DAY (SYSDATE) + 1;
         END IF;
      ELSIF v_date_assessment = 'AL'
      THEN
         BEGIN
            SELECT cam_first_load_date
              INTO v_first_load_date
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code AND cam_acct_id = v_acct_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_first_load_date := v_actv_date;
               prm_error := 'Acct not found -' || v_acct_id;
            WHEN OTHERS
            THEN
               prm_error :=
                     'Error occured while fetching acct dtls  -'
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         IF TRUNC (v_first_load_date) < TRUNC (SYSDATE)
         THEN
            IF TRUNC (ADD_MONTHS (v_first_load_date, 2)) >= TRUNC (SYSDATE)
            THEN
               v_next_mb_date := ADD_MONTHS (v_first_load_date, 2);
            ELSE
               v_next_mb_date := ADD_MONTHS (v_first_load_date, 1);
            END IF;
         ELSE
            v_next_mb_date := ADD_MONTHS (SYSDATE, 1);
         END IF;
     -- ELSE
       --  v_next_mb_date := 'NA'; --Commented for Mantis id- 15774
      END IF;
   --ELSE
     -- v_next_mb_date := 'NA';
   --En -- Added for DFCCSD-359
   END IF;

   IF v_cafgen_date IS NULL
   THEN           --sn:Modified by Dnyaneshwar J on 02 Apr 2014 for DFCCSD-101
      prm_feeplan_validfrm :=
         v_fee_plan || '|' || v_valid_from  || '|' || 'NA' || '|'
         || NVL (TO_CHAR (v_next_mb_date, 'MM/DD/YYYY'), 'NA');                        -- Modified for DFCCSD-359
   ELSE
      prm_feeplan_validfrm :=
            v_fee_plan
         || '|'
         || v_valid_from
         || '|'
         || TO_CHAR (v_cafgen_date, 'MM/DD/YYYY')
         || '|'     --Commented for Mantis id- 15774
         || NVL (TO_CHAR (v_next_mb_date, 'MM/DD/YYYY'), 'NA');                         -- Modified for DFCCSD-359
   END IF;        --en:Modified by Dnyaneshwar J on 02 Apr 2014 for DFCCSD-101

   RETURN prm_feeplan_validfrm;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_error := 'Main error ' || SUBSTR (SQLERRM, 1, 100);
      RETURN prm_error;
END;
/
SHOW ERROR