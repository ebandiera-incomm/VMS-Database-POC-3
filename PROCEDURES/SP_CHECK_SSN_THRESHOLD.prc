create or replace
PROCEDURE          vmscms.SP_CHECK_SSN_THRESHOLD (
   p_instcode        IN       NUMBER,
   p_ssn             IN       VARCHAR2,
   P_PROD_CODE       IN       VARCHAR2,
   p_card_type       IN       VARCHAR2,
   p_strtogpr_flag   IN       VARCHAR2,
   p_carddtls        OUT      VARCHAR2,
   p_resp_code       OUT      VARCHAR2,
   p_resp_msg        OUT      VARCHAR2,
   p_fldob_key       IN       VARCHAR2 DEFAULT NULL,
   p_quantity        IN       NUMBER DEFAULT NULL
)
AS
/**************************************************************************
     * Created Date                 : 05_Feb_2013
     * Created By                   : Pankaj S.
     * Purpose                      : Checking No.Of Card generation/activation attempts against threshold
     * Reviewer                    :  Dhiraj
     * Reviewed Date              :
     * Release Number               :   RI0023.2_B0001

     * Modified Date                 : 04_Mar_2013
     * Modified By                   : Pankaj S.
     * Purpose                      : Mantis ID -10523
     * Reviewer                    :  Dhiraj
     * Release Number               :   RI0023.2_B0011

     * Modified by                  : MageshKumar S.
     * Modified Date                : 23-June-15
     * Modified For                 : MVCAN-77
     * Modified reason              : Canada account limit check
     * Reviewer                     : Spankaj
     * Build Number                 : VMSGPRHOSTCSD3.1_B0001

     * Modified by                  : Siva kumar
     * Modified Date                : 18-Mar-16
     * Modified For                 : MVHOST-1323
     * Modified reason              : ssn encription logic
     * Reviewer                     : saravana/pankaj
     * Build Number                 : VMSGPRHOSTCSD_4.0_B0006
     
     * Modified by                  : MageshKumar S.
     * Modified Date                : 19-June-16
     * Modified For                 : FSS-3927
     * Modified reason              : Canada account limit check
     * Reviewer                     : Saravanakumar/Spankaj
     * Build Number                 : VMSGPRHOSTCSD4.2_B0002
	 
	 * Modified by                  : Dhinakaran B
     * Modified Date                : 13-Jan-20
     * Modified For                 : VMS-1795
     * Modified reason              : Response code assign for decline case
     * Reviewer                     : Saravanakumar
     * Build Number                 : R24.1
****************************************************************************/
   v_errmsg            VARCHAR2 (300);
   v_no_crds_gen       NUMBER (5)                            := 0;
   v_cardstat_cnt      NUMBER (5)                            := 0;
   v_cardissu_cnt      NUMBER (5)                            := 0;
   v_cnt      NUMBER (5)                            := 0;
   v_threshold_limit   NUMBER (5);
   v_threshold_inst    cms_inst_param.cip_param_value%TYPE;
   v_cardstat_str      VARCHAR2 (4000);
   --v_cardissu_str      VARCHAR2 (4000);
   v_pandtls_str       VARCHAR2 (500);
   v_prfl_status       cms_bin_param.cbp_param_value%TYPE;
   v_check_status      NUMBER (3);
   exp_reject_record   EXCEPTION;
   v_base_curr              cms_bin_param.cbp_param_value%TYPE; --Added for MVCAN-77 of 3.1 release

   CURSOR c1 (c_prod_code IN VARCHAR2, c_ssn IN VARCHAR2)
   IS
      SELECT   cap_mask_pan, cap_acct_no, cam_acct_bal, ccs_stat_desc,
               cap_active_date
          FROM cms_appl_pan, cms_cust_mast, cms_acct_mast, cms_card_stat
         WHERE ccm_inst_code = cap_inst_code
           AND ccm_cust_code = cap_cust_code
           AND cam_inst_code = cap_inst_code
           AND cam_acct_no = cap_acct_no
           AND cap_inst_code = ccs_inst_code
           AND cap_card_stat = ccs_stat_code
           AND cap_card_stat IN (SELECT csc_card_stat
                                   FROM cms_ssn_cardstat
                                  WHERE csc_stat_flag = 'Y'
                                                           --ANDcsc_stat_type = '1'
               )
           AND cap_prod_code = c_prod_code
           AND cap_card_stat not in('0','9') -- Condition Added for  MantisId:16147
           --AND nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn) = c_ssn
           AND (ccm_ssn_encr=fn_emaps_main(c_ssn) or ccm_ssn=c_ssn)
      ORDER BY cap_active_date DESC;

   CURSOR c3 (c_ssn IN VARCHAR2)
   IS
      SELECT   cap_mask_pan, cap_acct_no, cam_acct_bal, ccs_stat_desc,
               cap_active_date
          FROM cms_appl_pan, cms_cust_mast, cms_acct_mast, cms_card_stat
         WHERE ccm_inst_code = cap_inst_code
           AND ccm_cust_code = cap_cust_code
           AND cam_inst_code = cap_inst_code
           AND cam_acct_no = cap_acct_no
           AND cap_inst_code = ccs_inst_code
           AND cap_card_stat = ccs_stat_code
           AND cap_card_stat IN (SELECT csc_card_stat
                                   FROM cms_ssn_cardstat
                                  WHERE csc_stat_flag = 'Y')
           AND cap_card_stat not in('0','9') -- Condition Added for  MantisId:16147
          --AND nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn) = c_ssn
           AND (ccm_ssn_encr=fn_emaps_main(c_ssn) or ccm_ssn=c_ssn)
      ORDER BY cap_active_date DESC;

   CURSOR c4 (c_custcode IN NUMBER)
   IS
      SELECT   cap_mask_pan, cap_acct_no, cam_acct_bal, ccs_stat_desc,
               cap_active_date
          FROM cms_appl_pan, cms_acct_mast, cms_card_stat
         WHERE cap_inst_code = p_instcode
           AND cap_cust_code = c_custcode
         --  AND cap_card_stat not in('0','9')
         AND cap_card_stat <> '9'
           AND cam_inst_code = cap_inst_code
           AND cam_acct_no = cap_acct_no
           AND cap_inst_code = ccs_inst_code
           AND cap_card_stat = ccs_stat_code
           AND cap_card_stat IN (SELECT csc_card_stat
                                   FROM cms_ssn_cardstat
                                  WHERE csc_stat_flag = 'Y')
      ORDER BY cap_active_date DESC;

   CURSOR c5 (c_custcode IN NUMBER, c_prod_code IN VARCHAR2)
   IS
      SELECT   cap_mask_pan, cap_acct_no, cam_acct_bal, ccs_stat_desc,
               cap_active_date
          FROM cms_appl_pan, cms_acct_mast, cms_card_stat
         WHERE cap_inst_code = p_instcode
           AND cap_cust_code = c_custcode
           AND cap_prod_code = c_prod_code
         --  AND cap_card_stat not in('0','9')
         AND cap_card_stat <> '9'
           AND cam_inst_code = cap_inst_code
           AND cam_acct_no = cap_acct_no
           AND cap_inst_code = ccs_inst_code
           AND cap_card_stat = ccs_stat_code
           AND cap_card_stat IN (SELECT csc_card_stat
                                   FROM cms_ssn_cardstat
                                  WHERE csc_stat_flag = 'Y')
      ORDER BY cap_active_date DESC;

BEGIN
   p_resp_msg := 'OK';
   p_resp_code := '00';

     -- Sn Added for MVCAN-77 of 3.1 release
    BEGIN
       SELECT TRIM (cbp_param_value)
         INTO v_base_curr
         FROM cms_bin_param
        WHERE cbp_param_name = 'Currency' AND cbp_inst_code = p_instcode
              AND cbp_profile_code IN
                     (select CPc_PROFILE_CODE
                        FROM cms_prod_cattype
                       where CPC_PROD_CODE = P_PROD_CODE
                       and cpc_card_type=p_card_type
                             AND cpc_inst_code = p_instcode);

       IF TRIM (v_base_curr) IS NULL THEN
          p_resp_code := '21';
          v_errmsg := 'Base currency cannot be null ';
          RAISE exp_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_reject_record THEN
          RAISE;
       WHEN NO_DATA_FOUND THEN
          p_resp_code := '21';
          v_errmsg := 'Base currency is not defined for the institution ';
          RAISE exp_reject_record;
       WHEN OTHERS THEN
          p_resp_code := '21';
          v_errmsg :='Error while selecting base currecy  ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
    -- En Added for MVCAN-77 of 3.1 release

   IF p_strtogpr_flag IN ('SG', 'EN')
   THEN
      --Sn get profile status of product
      BEGIN
         SELECT cbp_param_value
           into V_PRFL_STATUS
           FROM cms_prod_cattype, cms_bin_param
          WHERE cpc_inst_code = cbp_inst_code
            AND cpc_profile_code = cbp_profile_code
            AND cpc_inst_code = p_instcode
            and CPC_PROD_CODE = P_PROD_CODE
            and cpc_card_type=p_card_type
            AND UPPER (cbp_param_name) = 'STATUS';

         SELECT COUNT (1)
           INTO v_check_status
           FROM cms_ssn_cardstat
          WHERE csc_card_stat = v_prfl_status AND csc_stat_flag = 'Y';

         IF v_check_status = 0
         THEN
            RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            v_errmsg :=
                  'Error while selecting profile status -'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;
   --En get profile status of product
   END IF;

   --Sn Get threshold parameter(Institution Level)
   BEGIN
      SELECT cip_param_value
        INTO v_threshold_inst
        FROM cms_inst_param
       WHERE cip_inst_code = p_instcode
             AND cip_param_key = 'PRODUCT_THRESHOLD';
   EXCEPTION
      WHEN OTHERS
      THEN
         v_threshold_limit := 0;
   END;
   --En Get threshold parameter(Institution Level)

  IF v_base_curr='124' THEN
    FOR k in ( SELECT ccm_cust_code FROM cms_cust_mast
        WHERE  ccm_flnamedob_hashkey = p_fldob_key order by ccm_ins_date)
  LOOP
      FOR  i IN c4 (k.ccm_cust_code)
      LOOP
         v_cnt:=v_cnt+1;
         IF v_cnt <=10 THEN
            SELECT    i.cap_mask_pan
                   || ','
                   || i.cap_acct_no
                   || ','
                   || i.cam_acct_bal
                   || ','
                   || i.ccs_stat_desc
                   || ','
                   || TO_CHAR (i.cap_active_date, 'MM/DD/YYYY')
                   || '|'
              INTO v_pandtls_str
              FROM DUAL;

            v_cardstat_str := v_cardstat_str || v_pandtls_str;
         END IF;
      END LOOP;
  END LOOP;
     IF v_cnt + nvl(p_quantity,0) >= v_threshold_inst THEN
         v_errmsg := 'Institution multiple SSN / Other ID level check failed';
         RAISE exp_reject_record;
     END IF;
  ELSE
   --Sn check no .of cards generated for particular SSN/Otherid(institution level)
   BEGIN
      SELECT COUNT (1)
        INTO v_cardissu_cnt
        FROM cms_appl_pan, cms_cust_mast
       WHERE ccm_inst_code = cap_inst_code
         AND ccm_cust_code = cap_cust_code
         AND cap_card_stat IN (SELECT csc_card_stat
                                 FROM cms_ssn_cardstat
                                WHERE csc_stat_flag = 'Y')
         AND cap_card_stat not in('0','9') -- Condition Added for  MantisId:16147
        -- AND nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn) = p_ssn;
        AND (ccm_ssn_encr=fn_emaps_main(TRIM(p_ssn)) or ccm_ssn=TRIM(p_ssn));

      IF v_cardissu_cnt + nvl(p_quantity,0) >= v_threshold_inst
      THEN
         FOR i IN c3 (p_ssn)
         LOOP
            v_cnt:=v_cnt+1;
            SELECT    i.cap_mask_pan
                   || ','
                   || i.cap_acct_no
                   || ','
                   || i.cam_acct_bal
                   || ','
                   || i.ccs_stat_desc
                   || ','
                   || TO_CHAR (i.cap_active_date, 'MM/DD/YYYY')
                   || '|'
              INTO v_pandtls_str
              FROM DUAL;

            v_cardstat_str := v_cardstat_str || v_pandtls_str;
            EXIT WHEN v_cnt = 10;
         END LOOP;

         v_errmsg := 'Institution multiple SSN / Other ID level check failed';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code := '89';
         v_errmsg :=
               'Error while getting count of cards generated for particular SSN/ID  -'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;
  END IF;

   --En check no .of cards generated for particular SSN/Otherid(institution level)

   --Sn Get threshold parameter(Product Level)
   BEGIN
      SELECT VPT_PROD_THRESHOLD
        INTO v_threshold_limit
        FROM VMS_PRODCAT_THRESHOLD
       WHERE Vpt_inst_code = p_instcode AND vpt_prod_code = p_prod_code and vpt_card_type=to_number(p_card_type);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_threshold_limit := 0;
      WHEN OTHERS
      THEN
         p_resp_code := '89';
         v_errmsg :=
              'Error while selecting Threshold -' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;
   --En Get threshold parameter(Product Level)

  IF v_base_curr='124' THEN
      v_cardstat_str := NULL;
    FOR k in ( SELECT ccm_cust_code FROM cms_cust_mast
        WHERE  ccm_flnamedob_hashkey = p_fldob_key order by ccm_ins_date)
  LOOP
      FOR  i IN c5 (k.ccm_cust_code,p_prod_code)
      LOOP
         v_cardstat_cnt:=v_cardstat_cnt+1;
         IF v_cardstat_cnt <=10 THEN
            SELECT    i.cap_mask_pan
                   || ','
                   || i.cap_acct_no
                   || ','
                   || i.cam_acct_bal
                   || ','
                   || i.ccs_stat_desc
                   || ','
                   || TO_CHAR (i.cap_active_date, 'MM/DD/YYYY')
                   || '|'
              INTO v_pandtls_str
              FROM DUAL;

            v_cardstat_str := v_cardstat_str || v_pandtls_str;
         END IF;
      END LOOP;
  END LOOP;
     IF v_cardstat_cnt + nvl(p_quantity,0) >= v_threshold_limit THEN
         v_errmsg := 'Product multiple SSN / Other ID level check failed';
         RAISE exp_reject_record;
     END IF;
  ELSE
   --Sn Get count of cards generated for particular SSN/Otherid
   BEGIN
      SELECT COUNT (1)
        INTO v_no_crds_gen
        FROM cms_appl_pan, cms_cust_mast
       WHERE ccm_inst_code = cap_inst_code
         AND ccm_cust_code = cap_cust_code
         AND cap_card_stat IN (SELECT csc_card_stat
                                 FROM cms_ssn_cardstat
                                WHERE csc_stat_flag = 'Y')
         AND cap_card_stat not in('0','9') -- Condition Added for  MantisId:16147
         AND cap_prod_code = p_prod_code
      --   AND nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn) = p_ssn;
           AND (ccm_ssn_encr=fn_emaps_main(TRIM(p_ssn)) or  ccm_ssn= TRIM(p_ssn));

      --Sn Determine if the process is to be allowed or terminated based on Threshold
      IF    (v_no_crds_gen + nvl(p_quantity,0)>= v_threshold_limit)
         --OR ((p_strtogpr_flag = 'SG')AND (v_no_crds_gen + 1 >= v_threshold_limit))  --commented for Mantis ID -10523
      THEN
         v_cardstat_str := NULL;

         FOR i IN c1 (p_prod_code, p_ssn)
         LOOP
            v_cardstat_cnt := v_cardstat_cnt + 1;

            SELECT    i.cap_mask_pan
                   || ','
                   || i.cap_acct_no
                   || ','
                   || i.cam_acct_bal
                   || ','
                   || i.ccs_stat_desc
                   || ','
                   || TO_CHAR (i.cap_active_date, 'MM/DD/YYYY')
                   || '|'
              INTO v_pandtls_str
              FROM DUAL;

            v_cardstat_str := v_cardstat_str || v_pandtls_str;
            EXIT WHEN v_cardstat_cnt = 10;
         END LOOP;

         v_errmsg := 'Product multiple SSN / Other ID level check failed';
         RAISE exp_reject_record;
      END IF;
   --En Determine if the process is to be allowed or terminated based on Threshold\
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code := '89';
         v_errmsg :=
               'Error while selecting cards generated for particular SSN/ID- '
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;
  END IF;
--En Get count of cards generated for particular SSN/Other ID
EXCEPTION
   WHEN exp_reject_record
   THEN
      p_resp_msg := v_errmsg;
      p_carddtls := v_cardstat_str;                      --|| v_cardissu_str;

      IF p_strtogpr_flag IN ('SG', 'EN')
      THEN
         --Sn Get response code
         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_instcode
               AND (    cms_delivery_channel =
                                    DECODE (p_strtogpr_flag,
                                            'SG', '03',
                                            '06'
                                           )
                    AND cms_response_id =
                                      DECODE (p_strtogpr_flag,
                                              'SG', 158,
                                              144
                                             )
                   );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Problem while selecting data from response master '
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '89';
         END;
      --En Get select response code
	  ELSE 
	  p_resp_code :='89';
      END IF;
   WHEN OTHERS
   THEN
      p_resp_code :='89';
      p_resp_msg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/
show error