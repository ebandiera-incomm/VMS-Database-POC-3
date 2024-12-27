create or replace
PROCEDURE                      VMSCMS.SP_ORDER_REISSUEPAN_CMS_R185 (
   p_hash_pan_in       IN     VARCHAR2,
   p_new_prodcode_in   IN     VARCHAR2,
   p_new_cardtype_in   IN     VARCHAR2,
   p_new_dispname_in   IN     VARCHAR2,
   p_cardpack_id_in    IN     VARCHAR2,
   p_pan_out           OUT    VARCHAR2,
   p_errmsg_out        OUT    VARCHAR2)
AS
   /*************************************************************************************
	* Created By       : Vini Pushkaran
    * Created Date     : 23-Jan-2019
    * Purpose          : VMS-742
    * Reviewer         : Saravanakumar
    * Release Number   : VMSGPRHOST_R11

   *************************************************************************************/

   v_asso_code               vmscms.cms_appl_pan.cap_asso_code%TYPE;
   v_inst_type               vmscms.cms_appl_pan.cap_inst_type%TYPE;
   v_prod_code               vmscms.cms_appl_pan.cap_prod_code%TYPE;
   v_appl_bran               vmscms.cms_appl_pan.cap_appl_bran%TYPE;
   v_cust_code               vmscms.cms_appl_pan.cap_cust_code%TYPE;
   v_card_type               vmscms.cms_appl_pan.cap_card_type%TYPE;
   v_cust_catg               vmscms.cms_appl_pan.cap_cust_catg%TYPE;
   v_disp_name               vmscms.cms_appl_pan.cap_disp_name%TYPE;
   v_expry_date              vmscms.cms_appl_pan.cap_expry_date%TYPE;
   v_addon_stat              vmscms.cms_appl_pan.cap_addon_stat%TYPE;
   v_tot_acct                vmscms.cms_appl_pan.cap_tot_acct%TYPE;
   v_chnl_code               vmscms.cms_appl_pan.cap_chnl_code%TYPE;
   v_limit_amt               vmscms.cms_appl_pan.cap_limit_amt%TYPE;
   v_use_limit               vmscms.cms_appl_pan.cap_use_limit%TYPE;
   v_bill_addr               vmscms.cms_appl_pan.cap_bill_addr%TYPE;
   v_cap_addon_link          vmscms.cms_appl_pan.cap_addon_link%TYPE;
   v_tmp_pan                 vmscms.cms_appl_pan.cap_pan_code%TYPE;
   v_adonlink                vmscms.cms_appl_pan.cap_pan_code%TYPE;
   v_mbrlink                 vmscms.cms_appl_pan.cap_mbr_numb%TYPE;
   v_card_stat               vmscms.cms_appl_pan.cap_card_stat%TYPE;
   v_pan                     vmscms.cms_appl_pan.cap_pan_code%TYPE;
   v_bin                     vmscms.cms_bin_mast.cbm_inst_bin%TYPE;
   v_errmsg                  vmscms.transactionlog.error_msg%TYPE;
   v_hsm_mode                vmscms.cms_inst_param.cip_param_value%TYPE;
   v_pingen_flag             VARCHAR2 (1);
   v_emboss_flag             VARCHAR2 (1);
   v_serial_no               NUMBER;
   v_check_digit             NUMBER;
   v_acct_id                 vmscms.cms_appl_pan.cap_acct_id%TYPE;
   v_acct_num                vmscms.cms_appl_pan.cap_acct_no%TYPE;
   v_prod_prefix             vmscms.cms_prod_cattype.cpc_prod_prefix%TYPE;
   v_cpm_catg_code           vmscms.cms_prod_mast.cpm_catg_code%TYPE;
   v_mbrnumb                 vmscms.cms_appl_pan.cap_mbr_numb%TYPE;
   v_next_bill_date          DATE;
   v_next_mb_date            DATE;
   v_cardtype_profile_code   cms_prod_cattype.cpc_profile_code%TYPE;
   v_check_custcarg          NUMBER (1);
   v_hash_new_pan            vmscms.cms_appl_pan.cap_pan_code%TYPE;
   v_encr_new_pan            vmscms.cms_appl_pan.cap_pan_code%TYPE;
   v_mask_pan                vmscms.cms_appl_pan.cap_mask_pan%TYPE;
   v_cpc_serl_flag           vmscms.cms_prod_cattype.cpc_serl_flag%TYPE;
   v_sweep_flag              vmscms.cms_prod_cattype.cpc_sweep_flag%TYPE;
   v_pan_inventory_flag      vmscms.cms_prod_cattype.cpc_pan_inventory_flag%TYPE;   
   v_prod_suffix             vmscms.cms_prod_cattype.cpc_prod_suffix%TYPE;
   v_card_start              vmscms.cms_prod_cattype.cpc_start_card_no%TYPE;
   v_card_end                vmscms.cms_prod_cattype.cpc_end_card_no%TYPE;
   v_prefix                  VARCHAR2(10);
   v_proxy_number            vmscms.cms_appl_pan.cap_proxy_number%TYPE;
   v_appl_code               vmscms.cms_appl_pan.cap_appl_code%TYPE;
   e_reject_record           EXCEPTION;

   PROCEDURE lp_pan_chkdig (l_tmppan IN VARCHAR2, l_checkdig OUT NUMBER)
   IS
      ceilable_sum   NUMBER := 0;
      ceiled_sum     NUMBER;
      temp_pan       NUMBER;
      len_pan        NUMBER (3);
      res            NUMBER (3);
      mult_ind       NUMBER (1);
      dig_sum        NUMBER (2);
      dig_len        NUMBER (1);
   BEGIN
      temp_pan := l_tmppan;
      len_pan := LENGTH (temp_pan);
      mult_ind := 2;

      FOR i IN REVERSE 1 .. len_pan
      LOOP
         res := SUBSTR (temp_pan, i, 1) * mult_ind;
         dig_len := LENGTH (res);

         IF dig_len = 2
         THEN
            dig_sum := SUBSTR (res, 1, 1) + SUBSTR (res, 2, 1);
         ELSE
            dig_sum := res;
         END IF;

         ceilable_sum := ceilable_sum + dig_sum;

         IF mult_ind = 2
         THEN
            mult_ind := 1;
         ELSE
            mult_ind := 2;
         END IF;
      END LOOP;

      ceiled_sum := ceilable_sum;

      IF MOD (ceilable_sum, 10) != 0
      THEN
         LOOP
            ceiled_sum := ceiled_sum + 1;
            EXIT WHEN MOD (ceiled_sum, 10) = 0;
         END LOOP;
      END IF;

      l_checkdig := ceiled_sum - ceilable_sum;
   END;

BEGIN
   --<< MAIN BEGIN >>
   p_errmsg_out := 'OK';

   BEGIN
      SELECT cip_param_value
        INTO v_hsm_mode
        FROM cms_inst_param
       WHERE cip_param_key = 'HSM_MODE' AND cip_inst_code = 1;

      IF v_hsm_mode = 'Y'
      THEN
         v_pingen_flag := 'Y';
         v_emboss_flag := 'Y';
      ELSE
         v_pingen_flag := 'N';
         v_emboss_flag := 'N';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_hsm_mode := 'N';
         v_pingen_flag := 'N';
         v_emboss_flag := 'N';
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while selecting hsm_mode ' || SUBSTR (SQLERRM, 1, 200);
         RAISE e_reject_record;
   END;

   BEGIN
      SELECT cap_asso_code,
             cap_inst_type,
             cap_prod_code,
             cap_appl_bran,
             cap_cust_code,
             cap_card_type,
             cap_cust_catg,
             cap_card_stat,
             cap_disp_name,
             cap_appl_bran,
             cap_expry_date,
             cap_addon_stat,
             cap_tot_acct,
             cap_chnl_code,
             cap_limit_amt,
             cap_use_limit,
             cap_bill_addr,
             cap_next_bill_date,
             cap_next_mb_date,
             cap_mbr_numb,
             cap_acct_no,
             cap_acct_id,
             cap_proxy_number,
             cap_appl_code
        INTO v_asso_code,
             v_inst_type,
             v_prod_code,
             v_appl_bran,
             v_cust_code,
             v_card_type,
             v_cust_catg,
             v_card_stat,
             v_disp_name,
             v_appl_bran,
             v_expry_date,
             v_addon_stat,
             v_tot_acct,
             v_chnl_code,
             v_limit_amt,
             v_use_limit,
             v_bill_addr,
             v_next_bill_date,
             v_next_mb_date,
             v_mbrnumb,
             v_acct_num,
             v_acct_id,
             v_proxy_number,
             v_appl_code
        FROM cms_appl_pan
       WHERE cap_pan_code = p_hash_pan_in AND cap_inst_code = 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting pan code from applpan'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE e_reject_record;
   END;

   IF TRIM (p_new_prodcode_in) IS NOT NULL
   THEN
      v_prod_code := TRIM (p_new_prodcode_in);
      v_card_type := TRIM (p_new_cardtype_in);
   END IF;

   IF TRIM (p_new_dispname_in) IS NOT NULL
   THEN
      v_disp_name := TRIM (p_new_dispname_in);
   END IF;

   BEGIN
      SELECT 1
        INTO v_check_custcarg
        FROM cms_prod_ccc
       WHERE     cpc_prod_code = v_prod_code
             AND cpc_card_type = v_card_type
             AND cpc_cust_catg = v_cust_catg
             AND cpc_inst_code = 1;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            sp_attach_custcatg (1,
                                v_cust_catg,
                                v_prod_code,
                                v_card_type,
                                1,
                                v_errmsg);

            IF v_errmsg <> 'OK'
            THEN
               RAISE e_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  'Error while creating a product and customer category relation '
                  || SUBSTR (SQLERRM, 1, 150);
               RAISE e_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting product and custcatg relationship'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE e_reject_record;
   END;

  
   BEGIN
      SELECT cpb_inst_bin
        INTO v_bin
        FROM cms_prod_bin
       WHERE     cpb_inst_code = 1
             AND cpb_prod_code = v_prod_code
             AND cpb_marc_prodbin_flag = 'N'
             AND cpb_active_bin = 'Y';

   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting bin from binmast'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE e_reject_record;
   END;

   BEGIN
      SELECT cpm_catg_code,
             cpc_prod_prefix,
             cpc_profile_code,
             cpc_serl_flag,
             NVL (cpc_sweep_flag, 'N'),
             NVL(cpc_pan_inventory_flag, 'N'), 
             cpc_prod_suffix,
             cpc_start_card_no,
             cpc_end_card_no   
        INTO v_cpm_catg_code,
             v_prod_prefix,
             v_cardtype_profile_code,
             v_cpc_serl_flag,
             v_sweep_flag,
             v_pan_inventory_flag,  
             v_prod_suffix,
             v_card_start,
             v_card_end
        FROM cms_prod_cattype, cms_prod_mast
       WHERE     cpc_inst_code = 1
             AND cpc_prod_code = v_prod_code
             AND cpc_card_type = v_card_type
             AND cpm_prod_code = cpc_prod_code;


      IF v_cardtype_profile_code IS NULL
      THEN
         v_errmsg := 'Profile is not attached to product cattype';

         RAISE e_reject_record;
      END IF;
   EXCEPTION
      WHEN e_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting Profile code ' || SUBSTR (SQLERRM, 1, 300);
         RAISE e_reject_record;
   END;

   IF v_prod_prefix IS NULL
   THEN
      BEGIN
         SELECT cip_param_value
           INTO v_prod_prefix
           FROM cms_inst_param
          WHERE cip_inst_code = 1
                AND cip_param_key = 'PANPRODCATPREFIX';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while selecting PAN Product Category Prefix from CMS_INST_PARAM '
               || SUBSTR (SQLERRM, 1, 300);
            RAISE e_reject_record;
      END;
   END IF;


 IF v_sweep_flag <> 'Y' THEN

   begin
            vmsfunutilities.get_expiry_date(1,v_prod_code,
            v_card_type,v_cardtype_profile_code,v_expry_date,v_errmsg);

            if v_errmsg<>'OK' then
               raise e_reject_record;
            END IF;

   EXCEPTION
            when e_reject_record then
                raise;
            when others then
                v_errmsg:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
         RAISE e_reject_record;
   END;
END IF;

IF v_pan_inventory_flag='N' THEN  
    BEGIN
    vmscard.get_pan_srno (1,
                          v_prod_code,
                          v_card_type,
                          v_prod_prefix,
                          v_prod_suffix,
                          v_card_start,  
                          v_card_end,
                          v_cpc_serl_flag,
                          v_prefix,
                          v_serial_no,
                          v_errmsg);

       IF V_ERRMSG <> 'OK' THEN
        RAISE e_reject_record;
       END IF;
     EXCEPTION
       WHEN e_reject_record THEN
       RAISE;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while calling get_pan_srno ' ||
                  SUBSTR(SQLERRM, 1, 300);
        RAISE e_reject_record;
    END;
     
    V_TMP_PAN := NULL;
     
    BEGIN
	 FOR I
         IN (SELECT cpc_profile_code,
                    cpc_field_name,
                    cpc_start_from,
                    cpc_length,
                    cpc_start
               FROM cms_pan_construct
              WHERE cpc_profile_code = v_cardtype_profile_code
                    AND cpc_inst_code = 1
                    order by cpc_start_from)
      LOOP
         IF i.cpc_field_name = 'Card Type'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_CARD_TYPE), I.CPC_START, I.CPC_LENGTH), I.CPC_LENGTH,'0');
         ELSIF i.cpc_field_name = 'Branch'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_APPL_BRAN), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
         ELSIF i.cpc_field_name = 'BIN / PREFIX'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_BIN), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
         ELSIF i.cpc_field_name = 'PAN Product Category Prefix'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_PREFIX), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
         ELSIF i.cpc_field_name = 'Serial Number'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_SERIAL_NO), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_ERRMSG :=
            'Error while getting temp PAN:' || SUBSTR (SQLERRM, 1, 200);
   END;
   
   IF v_tmp_pan IS NOT NULL
   THEN
      lp_pan_chkdig (v_tmp_pan, v_check_digit);
      v_pan := v_tmp_pan || v_check_digit;
  ELSE
       vmscard.get_card_no (v_prod_code,
                            v_card_type,
                            v_pan,
                            v_errmsg);

       IF v_errmsg <> 'OK' THEN
          v_errmsg := 'Error from get_card_no-' || v_errmsg;
          RAISE e_reject_record;
       END IF;
 END IF;
 
       p_pan_out := v_pan;

      --SN CREATE HASH PAN
      BEGIN
         v_hash_new_pan := gethash (v_pan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE e_reject_record;
      END;

      --EN CREATE HASH PAN

      --SN create encr pan
      BEGIN
         v_encr_new_pan := fn_emaps_main (v_pan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE e_reject_record;
      END;

      --EN create encr pan

      --SN create Mask PAN   
      BEGIN
         v_mask_pan :=
            fn_getmaskpan (v_pan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while converting into mask pan '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE e_reject_record;
      END;
   END IF;

   IF v_addon_stat = 'A'
   THEN
      BEGIN
         SELECT cap_addon_link
           INTO v_cap_addon_link
           FROM cms_appl_pan
          WHERE cap_appl_code = p_hash_pan_in AND cap_inst_code = 1;

         SELECT cap_pan_code, cap_mbr_numb
           INTO v_adonlink, v_mbrlink
           FROM cms_appl_pan
          WHERE cap_pan_code = v_cap_addon_link
                AND cap_inst_code = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while selecting addon detail '
               || SUBSTR (SQLERRM, 1, 150);
            RAISE e_reject_record;
      END;
   ELSIF v_addon_stat = 'P'
   THEN
      v_adonlink := v_hash_new_pan;
      v_mbrlink := v_mbrnumb;
   END IF;

   BEGIN
      SELECT cbp_param_value
        INTO v_card_stat
        FROM cms_bin_param
       WHERE     cbp_inst_code = 1
             AND cbp_profile_code = v_cardtype_profile_code
             AND cbp_param_name = 'Status';
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting carad status data '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE e_reject_record;
   END;

   BEGIN
         INSERT INTO cms_appl_pan (cap_inst_code,
                                   cap_asso_code,
                                   cap_inst_type,
                                   cap_prod_code,
                                   cap_prod_catg,
                                   cap_card_type,
                                   cap_cust_catg,
                                   cap_pan_code,
                                   cap_mbr_numb,
                                   cap_card_stat,
                                   cap_cust_code,
                                   cap_disp_name,
                                   cap_limit_amt,
                                   cap_use_limit,
                                   cap_appl_bran,
                                   cap_expry_date,
                                   cap_addon_stat,
                                   cap_addon_link,
                                   cap_mbr_link,
                                   cap_acct_id,
                                   cap_acct_no,
                                   cap_tot_acct,
                                   cap_bill_addr,
                                   cap_chnl_code,
                                   cap_pangen_date,
                                   cap_pangen_user,
                                   cap_cafgen_flag,
                                   cap_pin_flag,
                                   cap_embos_flag,
                                   cap_phy_embos,
                                   cap_join_feecalc,
                                   cap_next_bill_date,
                                   cap_ins_user,
                                   cap_lupd_user,
                                   cap_pbfgen_flag,
                                   cap_next_mb_date,
                                   cap_firsttime_topup,
                                   cap_issue_flag,
                                   cap_pan_code_encr,
                                   cap_proxy_number,
                                   cap_appl_code,
                                   cap_mask_pan,
                                   cap_proxy_msg,
                                   cap_cardpack_id)
              VALUES (1,
                      v_asso_code,
                      v_inst_type,
                      v_prod_code,
                      v_cpm_catg_code,
                      v_card_type,
                      v_cust_catg,
                      v_hash_new_pan,
                      v_mbrnumb,
                      v_card_stat,
                      v_cust_code,
                      v_disp_name,
                      v_limit_amt,
                      v_use_limit,
                      v_appl_bran,
                      v_expry_date,
                      v_addon_stat,
                      v_adonlink,
                      v_mbrlink,
                      v_acct_id,
                      v_acct_num,
                      v_tot_acct,
                      v_bill_addr,
                      v_chnl_code,
                      SYSDATE,
                      1,
                      'Y',
                      v_pingen_flag,
                      v_emboss_flag,
                      'N',
                      'N',
                      v_next_bill_date,
                      1,
                      1,
                      'R',
                      v_next_mb_date,
                      case when v_cpm_catg_code = 'P' then 'N'
                      else 'Y' end,
                      'Y',
                      v_encr_new_pan,
                      v_proxy_number,
                      v_appl_code,
                      v_mask_pan,
                      'Success',
                      p_cardpack_id_in);
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         v_errmsg :=
               'Pan '
            || fn_getmaskpan (v_pan)
            || ' is already present in the Pan_master';
         RAISE e_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while inserting records into pan master '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE e_reject_record;
   END;

   IF v_cpm_catg_code IN ('D', 'A')
   THEN
      FOR x IN (SELECT cpa_acct_id, cpa_acct_posn
            FROM cms_pan_acct
           WHERE cpa_pan_code = p_hash_pan_in AND cpa_inst_code = 1)
      LOOP
         BEGIN
            INSERT INTO cms_pan_acct (cpa_inst_code,
                                      cpa_cust_code,
                                      cpa_acct_id,
                                      cpa_acct_posn,
                                      cpa_pan_code,
                                      cpa_mbr_numb,
                                      cpa_ins_user,
                                      cpa_lupd_user,
                                      cpa_pan_code_encr)
                 VALUES (1,
                         v_cust_code,
                         v_acct_id,
                         x.cpa_acct_posn,
                         v_hash_new_pan,
                         v_mbrnumb,
                         1,
                         1,
                         v_encr_new_pan);

         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               v_errmsg :=
                     'Duplicate record exist  in pan acct master for pan  '
                  || fn_getmaskpan (v_pan)
                  || 'acct id '
                  || x.cpa_acct_id;
               RAISE e_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                  'Error while inserting records into pan acct  master '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE e_reject_record;
         END;
      END LOOP;
   ELSIF v_cpm_catg_code = 'P'
   THEN
      BEGIN
         INSERT INTO cms_pan_acct (cpa_inst_code,
                                   cpa_cust_code,
                                   cpa_acct_id,
                                   cpa_acct_posn,
                                   cpa_pan_code,
                                   cpa_mbr_numb,
                                   cpa_ins_user,
                                   cpa_lupd_user,
                                   cpa_pan_code_encr)
              VALUES (1,
                      v_cust_code,
                      v_acct_id,
                      1,
                      v_hash_new_pan,
                      v_mbrnumb,
                      1,
                      1,
                      v_encr_new_pan);
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            v_errmsg :=
                  'Duplicate record exist  in pan acct master for pan  '
               || fn_getmaskpan (v_pan)
               || 'acct id '
               || v_acct_id;
            RAISE e_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while inserting records into pan acct  master '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE e_reject_record;
      END;
   END IF;

   p_errmsg_out := 'OK';
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN e_reject_record
   THEN
      p_errmsg_out := v_errmsg;
   WHEN OTHERS
   THEN
      p_errmsg_out :=
         'Error while processing application for pan gen '
         || SUBSTR (SQLERRM, 1, 200);
END;
/
show error