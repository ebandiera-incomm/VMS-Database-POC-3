create or replace
PROCEDURE               VMSCMS.SP_ORDER_REISSUEPAN_CMS_R306 (
   prm_instcode       IN     NUMBER,
   prm_pancode        IN     NUMBER,
   prm_new_prodcode   IN     VARCHAR2,
   prm_new_cardtype   IN     VARCHAR2,
   prm_new_dispname   IN     VARCHAR2,
   prm_lupduser       IN     NUMBER,
   prm_pan            OUT    VARCHAR2,
   prm_catg_code      OUT    VARCHAR2,
   prm_errmsg         OUT    VARCHAR2)
AS
   /*************************************************************************************
	* Modified By      : Ubaidur Rahman H
    * Modified Date    : 05-Jun-2020
    * Purpose          : Update activity 30.6
    * Reviewer         : Saravanakumar
   *************************************************************************************/

   v_inst_code               cms_appl_pan.cap_inst_code%TYPE;
   v_asso_code               cms_appl_pan.cap_asso_code%TYPE;
   v_inst_type               cms_appl_pan.cap_inst_type%TYPE;
   v_prod_code               cms_appl_pan.cap_prod_code%TYPE;
   v_appl_bran               cms_appl_pan.cap_appl_bran%TYPE;
   v_cust_code               cms_appl_pan.cap_cust_code%TYPE;
   v_card_type               cms_appl_pan.cap_card_type%TYPE;
   v_cust_catg               cms_appl_pan.cap_cust_catg%TYPE;
   v_disp_name               cms_appl_pan.cap_disp_name%TYPE;
   v_active_date             cms_appl_pan.cap_active_date%TYPE;
   v_expry_date              cms_appl_pan.cap_expry_date%TYPE;
   v_addon_stat              cms_appl_pan.cap_addon_stat%TYPE;
   v_tot_acct                cms_appl_pan.cap_tot_acct%TYPE;
   v_chnl_code               cms_appl_pan.cap_chnl_code%TYPE;
   v_limit_amt               cms_appl_pan.cap_limit_amt%TYPE;
   v_use_limit               cms_appl_pan.cap_use_limit%TYPE;
   v_bill_addr               cms_appl_pan.cap_bill_addr%TYPE;
   v_request_id              cms_appl_pan.cap_request_id%TYPE;
   v_cap_addon_link          cms_appl_pan.cap_addon_link%TYPE;
   v_tmp_pan                 cms_appl_pan.cap_pan_code%TYPE;
   v_adonlink                cms_appl_pan.cap_pan_code%TYPE;
   v_mbrlink                 cms_appl_pan.cap_mbr_numb%TYPE;
   v_card_stat               cms_appl_pan.cap_card_stat%TYPE;
   v_offline_atm_limit       cms_appl_pan.cap_atm_offline_limit%TYPE;
   v_online_atm_limit        cms_appl_pan.cap_atm_online_limit%TYPE;
   v_online_pos_limit        cms_appl_pan.cap_pos_online_limit%TYPE;
   v_offline_pos_limit       cms_appl_pan.cap_pos_offline_limit%TYPE;
   v_offline_aggr_limit      cms_appl_pan.cap_offline_aggr_limit%TYPE;
   v_online_aggr_limit       cms_appl_pan.cap_online_aggr_limit%TYPE;
   v_pan                     cms_appl_pan.cap_pan_code%TYPE;
   v_cap_firsttime_topup     cms_appl_pan.cap_firsttime_topup%TYPE;
   v_appl_stat               cms_appl_mast.cam_appl_stat%TYPE;
   v_bin                     cms_bin_mast.cbm_inst_bin%TYPE;
   v_profile_code            cms_prod_cattype.cpc_profile_code%TYPE;
   v_errmsg                  VARCHAR2 (500);
   v_hsm_mode                cms_inst_param.cip_param_value%TYPE;
   v_pingen_flag             VARCHAR2 (1);
   v_emboss_flag             VARCHAR2 (1);
   v_loop_cnt                NUMBER DEFAULT 0;
   v_loop_max_cnt            NUMBER;
   v_noof_pan_param          NUMBER;
   v_inst_bin                cms_prod_bin.cpb_inst_bin%TYPE;
   v_serial_index            NUMBER;
   v_serial_maxlength        NUMBER (2);
   v_serial_no               NUMBER;
   v_check_digit             NUMBER;
   v_acct_id                 cms_appl_pan.cap_acct_id%TYPE;
   v_acct_num                cms_appl_pan.cap_acct_no%TYPE;
   v_hold_count              cms_acct_mast.cam_hold_count%TYPE;
   v_curr_bran               cms_acct_mast.cam_curr_bran%TYPE;
   v_cam_bill_addr           cms_acct_mast.cam_bill_addr%TYPE;
   v_type_code               cms_acct_mast.cam_type_code%TYPE;
   v_stat_code               cms_acct_mast.cam_stat_code%TYPE;
   v_acct_bal                cms_acct_mast.cam_acct_bal%TYPE;
   v_cam_addon_link          cms_appl_mast.cam_addon_link%TYPE;
   v_prod_prefix             cms_prod_cattype.cpc_prod_prefix%TYPE;
   v_cpm_catg_code           cms_prod_mast.cpm_catg_code%TYPE;
   v_issueflag               VARCHAR2 (1);
   v_initial_topup_amount    cms_appl_mast.cam_initial_topup_amount%TYPE;
   v_func_code               cms_func_mast.cfm_func_code%TYPE;
   v_func_desc               cms_func_mast.cfm_func_desc%TYPE;
   v_cr_gl_code              cms_func_prod.cfp_crgl_code%TYPE;
   v_crgl_catg               cms_func_prod.cfp_crgl_catg%TYPE;
   v_crsubgl_code            cms_func_prod.cfp_crsubgl_code%TYPE;
   v_cracct_no               cms_func_prod.cfp_cracct_no%TYPE;
   v_dr_gl_code              cms_func_prod.cfp_drgl_code%TYPE;
   v_drgl_catg               cms_func_prod.cfp_drgl_catg%TYPE;
   v_drsubgl_code            cms_func_prod.cfp_drsubgl_code%TYPE;
   v_dracct_no               cms_func_prod.cfp_dracct_no%TYPE;
   v_gl_check                NUMBER (1);
   v_subgl_desc              VARCHAR2 (30);
   v_tran_code               cms_func_mast.cfm_txn_code%TYPE;
   v_tran_mode               cms_func_mast.cfm_txn_mode%TYPE;
   v_delv_chnl               cms_func_mast.cfm_delivery_channel%TYPE;
   v_tran_type               cms_func_mast.cfm_txn_type%TYPE;
   v_expryparam              cms_bin_param.cbp_param_value%TYPE;
   v_mbrnumb                 cms_appl_pan.cap_mbr_numb%TYPE;
   v_next_bill_date          DATE;
   v_pbfgen_flag             CHAR (1);
   v_next_mb_date            DATE;
   v_acctid_new              NUMBER;
   v_holdposn                NUMBER;
   v_host_proc               cms_inst_param.cip_param_value%TYPE;
   v_dup_flag                CHAR (1);
   v_old_gl_catg             cms_gl_acct_mast.cga_glcatg_code%TYPE;
   v_old_gl_code             cms_gl_acct_mast.cga_gl_code%TYPE;
   v_old_sub_gl_code         cms_gl_acct_mast.cga_subgl_code%TYPE;
   v_old_acct_desc           cms_gl_acct_mast.cga_acct_desc%TYPE;
   v_savepoint               NUMBER DEFAULT 1;
   v_acct_numb               cms_acct_mast.cam_acct_no%TYPE;
   v_cardtype_profile_code   cms_prod_cattype.cpc_profile_code%TYPE;
   v_appl_data               type_appl_rec_array;
   v_check_cardtype          NUMBER (1);
   v_check_custcarg          NUMBER (1);
   v_hash_pan                cms_appl_pan.cap_pan_code%TYPE;
   v_hash_new_pan            cms_appl_pan.cap_pan_code%TYPE;
   v_encr_new_pan            cms_appl_pan.cap_pan_code%TYPE;
   v_validity_period         cms_bin_param.cbp_param_value%TYPE;
   v_mask_pan                cms_appl_pan.cap_mask_pan%TYPE;
   v_cpc_serl_flag           cms_prod_cattype.cpc_serl_flag%TYPE;
   p_shflcntrl_no            NUMBER (9);
   v_exp_date_exemption      cms_prod_cattype.cpc_exp_date_exemption%TYPE;
   v_sweep_flag              cms_prod_cattype.cpc_sweep_flag%TYPE;
   v_pan_inventory_flag      cms_prod_cattype.cpc_pan_inventory_flag%TYPE; 
   v_prod_suffix             cms_prod_cattype.cpc_prod_suffix%TYPE;
   v_card_start              cms_prod_cattype.cpc_start_card_no%TYPE;
   v_card_end                cms_prod_cattype.cpc_end_card_no%TYPE;
   v_prodprefx_index         NUMBER;
   v_prefix                  VARCHAR2(10);
   exp_reject_record         EXCEPTION;
   v_proxy_number            cms_appl_pan.cap_proxy_number%TYPE;
   v_appl_code               cms_appl_pan.cap_appl_code%TYPE;

   CURSOR c (
      p_profile_code IN VARCHAR2)
   IS
        SELECT cpc_profile_code,
               cpc_field_name,
               cpc_start_from,
               cpc_length,
               cpc_start
          FROM cms_pan_construct
         WHERE cpc_profile_code = p_profile_code
               AND cpc_inst_code = prm_instcode
      ORDER BY cpc_start_from DESC;

   CURSOR c1
   IS
      SELECT cpa_acct_id, cpa_acct_posn
        FROM cms_pan_acct
       WHERE cpa_pan_code = v_hash_pan AND cpa_inst_code = prm_instcode;

   PROCEDURE lp_pan_bin (l_instcode    IN     NUMBER,
                         l_insttype    IN     NUMBER,
                         l_prod_code   IN     VARCHAR2,
                         l_pan_bin        OUT NUMBER,
                         l_errmsg         OUT VARCHAR2)
   IS
   BEGIN
      SELECT cpb_inst_bin
        INTO l_pan_bin
        FROM cms_prod_bin
       WHERE     cpb_inst_code = l_instcode
             AND cpb_prod_code = l_prod_code
             AND cpb_marc_prodbin_flag = 'N'
             AND cpb_active_bin = 'Y';

      l_errmsg := 'OK';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_errmsg :=
            'Excp1 LP1 -- No prefix  found for combination of Institution '
            || l_instcode
            || ' and product '
            || l_prod_code;
      WHEN OTHERS
      THEN
         l_errmsg := 'Excp1 LP1 -- ' || SQLERRM;
   END;

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
   prm_errmsg := 'OK';
   v_issueflag := 'Y';

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (prm_pancode);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cip_param_value
        INTO v_hsm_mode
        FROM cms_inst_param
       WHERE cip_param_key = 'HSM_MODE' AND cip_inst_code = prm_instcode;

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
   END;

   BEGIN
      SELECT cap_inst_code,
             cap_asso_code,
             cap_inst_type,
             cap_prod_code,
             cap_appl_bran,
             cap_cust_code,
             cap_card_type,
             cap_cust_catg,
             cap_card_stat,
             cap_disp_name,
             cap_appl_bran,
             cap_active_date,
             cap_expry_date,
             cap_addon_stat,
             cap_tot_acct,
             cap_chnl_code,
             cap_limit_amt,
             cap_use_limit,
             cap_bill_addr,
             cap_next_bill_date,
             cap_pbfgen_flag,
             cap_next_mb_date,
             cap_atm_offline_limit,
             cap_atm_online_limit,
             cap_pos_offline_limit,
             cap_pos_online_limit,
             cap_offline_aggr_limit,
             cap_online_aggr_limit,
             'N',
             cap_mbr_numb,
             type_appl_rec_array (cap_panmast_param1,
                                  cap_panmast_param2,
                                  cap_panmast_param3,
                                  cap_panmast_param4,
                                  cap_panmast_param5,
                                  cap_panmast_param6,
                                  cap_panmast_param7,
                                  cap_panmast_param8,
                                  cap_panmast_param9,
                                  cap_panmast_param10),
             cap_acct_no,
             cap_acct_id,
             cap_proxy_number,
             cap_appl_code
        INTO v_inst_code,
             v_asso_code,
             v_inst_type,
             v_prod_code,
             v_appl_bran,
             v_cust_code,
             v_card_type,
             v_cust_catg,
             v_card_stat,
             v_disp_name,
             v_appl_bran,
             v_active_date,
             v_expry_date,
             v_addon_stat,
             v_tot_acct,
             v_chnl_code,
             v_limit_amt,
             v_use_limit,
             v_bill_addr,
             v_next_bill_date,
             v_pbfgen_flag,
             v_next_mb_date,
             v_offline_atm_limit,
             v_online_atm_limit,
             v_offline_pos_limit,
             v_online_pos_limit,
             v_offline_aggr_limit,
             v_online_aggr_limit,
             v_cap_firsttime_topup,
             v_mbrnumb,
             v_appl_data,
             v_acct_num,
             v_acct_id,
             v_proxy_number,
             v_appl_code
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
            'No row found for pan code'
            || fn_getmaskpan (prm_pancode);
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting pan code from applpan'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   IF TRIM (prm_new_prodcode) IS NOT NULL
   THEN
      v_prod_code := TRIM (prm_new_prodcode);
      v_card_type := TRIM (prm_new_cardtype);
   END IF;

   IF TRIM (prm_new_dispname) IS NOT NULL
   THEN
      v_disp_name := TRIM (prm_new_dispname);
   END IF;

   BEGIN
      SELECT 1
        INTO v_check_cardtype
        FROM cms_prod_cattype
       WHERE     cpc_prod_code = v_prod_code
             AND cpc_card_type = v_card_type
             AND cpc_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Product is not related to cardtype';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting product and cardtype relationship'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT 1
        INTO v_check_custcarg
        FROM cms_prod_ccc
       WHERE     cpc_prod_code = v_prod_code
             AND cpc_card_type = v_card_type
             AND cpc_cust_catg = v_cust_catg
             AND cpc_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            sp_attach_custcatg (prm_instcode,
                                v_cust_catg,
                                v_prod_code,
                                v_card_type,
                                prm_lupduser,
                                v_errmsg);

            IF v_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  'Error while creating a product and customer category relation '
                  || SUBSTR (SQLERRM, 1, 150);
               RAISE exp_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting product and custcatg relationship'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      lp_pan_bin (v_inst_code,
                  v_inst_type,
                  v_prod_code,
                  v_bin,
                  v_errmsg);

      IF v_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting bin from binmast'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cpm_profile_code,
             cpm_catg_code,
             cpc_prod_prefix,
             cpc_profile_code,
             cpc_serl_flag,
             cpc_exp_date_exemption,
             NVL (cpc_sweep_flag, 'N'),
             NVL(cpc_pan_inventory_flag, 'N'),  
             cpc_prod_suffix,
             cpc_start_card_no,
             cpc_end_card_no   
        INTO v_profile_code,
             v_cpm_catg_code,
             v_prod_prefix,
             v_cardtype_profile_code,
             v_cpc_serl_flag,
             v_exp_date_exemption,
             v_sweep_flag,
             v_pan_inventory_flag,  
             v_prod_suffix,
             v_card_start,
             v_card_end
        FROM cms_prod_cattype, cms_prod_mast
       WHERE     cpc_inst_code = prm_instcode
             AND cpc_prod_code = v_prod_code
             AND cpc_card_type = v_card_type
             AND cpm_prod_code = cpc_prod_code;
			 
			 prm_catg_code:=v_cpm_catg_code;

      IF v_cardtype_profile_code IS NULL
      THEN
         v_errmsg := 'Profile is not attached to product cattype';

         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
               'Profile code not defined for product code '
            || v_prod_code
            || 'card type '
            || v_card_type;
         RAISE exp_reject_record;
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting Profile code ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   IF v_prod_prefix IS NULL
   THEN
      BEGIN
         SELECT cip_param_value
           INTO v_prod_prefix
           FROM cms_inst_param
          WHERE cip_inst_code = prm_instcode
                AND cip_param_key = 'PANPRODCATPREFIX';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while selecting PAN Product Category Prefix from CMS_INST_PARAM '
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;
   END IF;

 IF v_sweep_flag <> 'Y' THEN

   begin
            vmsfunutilities.get_expiry_date(prm_instcode,v_prod_code,
            v_card_type,v_cardtype_profile_code,v_expry_date,v_errmsg);

            if v_errmsg<>'OK' then
            raise exp_reject_record;
   END IF;

   EXCEPTION
            when exp_reject_record then
                raise;
            when others then
                v_errmsg:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
         RAISE exp_reject_record;
   END;
END IF;
   
IF v_pan_inventory_flag='N' THEN  
       BEGIN
    vmscard.get_pan_srno (prm_instcode,
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
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       
       WHEN EXP_REJECT_RECORD THEN
       RAISE;
       
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while calling get_pan_srno ' ||
                  SUBSTR(SQLERRM, 1, 300);
        RAISE EXP_REJECT_RECORD;
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
                    AND cpc_inst_code = PRM_INSTCODE
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
      prm_pan := v_pan;

 ELSE
       vmscard.get_card_no (v_prod_code,
                            v_card_type,
                            v_pan,
                            v_errmsg);

       IF v_errmsg <> 'OK' THEN
          v_errmsg := 'Error from get_card_no-' || v_errmsg;
          RAISE exp_reject_record;
       END IF;
 END IF;
 

      --SN CREATE HASH PAN
      BEGIN
         v_hash_new_pan := gethash (v_pan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
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
            RAISE exp_reject_record;
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
            RAISE exp_reject_record;
      END;
   END IF;

   IF v_addon_stat = 'A'
   THEN
      BEGIN
         SELECT cap_addon_link
           INTO v_cap_addon_link
           FROM cms_appl_pan
          WHERE cap_appl_code = v_hash_pan AND cap_inst_code = prm_instcode;

         SELECT cap_pan_code, cap_mbr_numb
           INTO v_adonlink, v_mbrlink
           FROM cms_appl_pan
          WHERE cap_pan_code = v_cap_addon_link
                AND cap_inst_code = prm_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
               'Parent PAN not generated for '
               || fn_getmaskpan (prm_pancode);
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while selecting addon detail '
               || SUBSTR (SQLERRM, 1, 150);
            RAISE exp_reject_record;
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
       WHERE     cbp_inst_code = prm_instcode
             AND cbp_profile_code = v_cardtype_profile_code
             AND cbp_param_name = 'Status';
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting carad status data '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      IF v_cpm_catg_code = 'P'
      THEN
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
                                   cap_atm_offline_limit,
                                   cap_atm_online_limit,
                                   cap_pos_offline_limit,
                                   cap_pos_online_limit,
                                   cap_offline_aggr_limit,
                                   cap_online_aggr_limit,
                                   cap_firsttime_topup,
                                   cap_issue_flag,
                                   cap_panmast_param1,
                                   cap_panmast_param2,
                                   cap_panmast_param3,
                                   cap_panmast_param4,
                                   cap_panmast_param5,
                                   cap_panmast_param6,
                                   cap_panmast_param7,
                                   cap_panmast_param8,
                                   cap_panmast_param9,
                                   cap_panmast_param10,
                                   cap_pan_code_encr,
                                   cap_proxy_number,
                                   cap_appl_code,
                                   cap_mask_pan,
                                   cap_proxy_msg)
              VALUES (prm_instcode,
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
                      prm_lupduser,
                      'Y',
                      v_pingen_flag,
                      v_emboss_flag,
                      'N',
                      'N',
                      v_next_bill_date,
                      prm_lupduser,
                      prm_lupduser,
                      'R',
                      v_next_mb_date,
                      v_offline_atm_limit,
                      v_online_atm_limit,
                      v_offline_pos_limit,
                      v_online_pos_limit,
                      v_offline_aggr_limit,
                      v_online_aggr_limit,
                      'N',
                      v_issueflag,
                      v_appl_data (1),
                      v_appl_data (2),
                      v_appl_data (3),
                      v_appl_data (4),
                      v_appl_data (5),
                      v_appl_data (6),
                      v_appl_data (7),
                      v_appl_data (8),
                      v_appl_data (9),
                      v_appl_data (10),
                      v_encr_new_pan,
                      v_proxy_number,
                      v_appl_code,
                      v_mask_pan,
                      'Success');

         
      END IF;

      IF v_cpm_catg_code IN ('D', 'A')
      THEN
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
                                   cap_atm_offline_limit,
                                   cap_atm_online_limit,
                                   cap_pos_offline_limit,
                                   cap_pos_online_limit,
                                   cap_offline_aggr_limit,
                                   cap_online_aggr_limit,
                                   cap_firsttime_topup,
                                   cap_issue_flag,
                                   cap_panmast_param1,
                                   cap_panmast_param2,
                                   cap_panmast_param3,
                                   cap_panmast_param4,
                                   cap_panmast_param5,
                                   cap_panmast_param6,
                                   cap_panmast_param7,
                                   cap_panmast_param8,
                                   cap_panmast_param9,
                                   cap_panmast_param10,
                                   cap_pan_code_encr,
                                   cap_proxy_number,
                                   cap_appl_code,
                                   cap_mask_pan,
                                   cap_proxy_msg)
              VALUES (prm_instcode,
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
                      prm_lupduser,
                      'Y',
                      v_pingen_flag,
                      v_emboss_flag,
                      'N',
                      'N',
                      v_next_bill_date,
                      prm_lupduser,
                      prm_lupduser,
                      'R',
                      v_next_mb_date,
                      v_offline_atm_limit,
                      v_online_atm_limit,
                      v_offline_pos_limit,
                      v_online_pos_limit,
                      v_offline_aggr_limit,
                      v_online_aggr_limit,
                      'Y',
                      v_issueflag,
                      v_appl_data (1),
                      v_appl_data (2),
                      v_appl_data (3),
                      v_appl_data (4),
                      v_appl_data (5),
                      v_appl_data (6),
                      v_appl_data (7),
                      v_appl_data (8),
                      v_appl_data (9),
                      v_appl_data (10),
                      v_encr_new_pan,
                      v_proxy_number,
                      v_appl_code,
                      v_mask_pan,
                      'Success');

        
      END IF;
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         v_errmsg :=
               'Pan '
            || fn_getmaskpan (v_pan)
            || ' Error while inserting records into pan master  VALUE_ERROR';
         RAISE exp_reject_record;
      WHEN DUP_VAL_ON_INDEX
      THEN
         v_errmsg :=
               'Pan '
            || fn_getmaskpan (v_pan)
            || ' is already present in the Pan_master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while inserting records into pan master '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF v_cpm_catg_code IN ('D', 'A')
   THEN
      FOR x IN c1
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
                 VALUES (prm_instcode,
                         v_cust_code,
                         v_acct_id,
                         x.cpa_acct_posn,
                         v_hash_new_pan,
                         v_mbrnumb,
                         prm_lupduser,
                         prm_lupduser,
                         v_encr_new_pan);

            EXIT WHEN c1%NOTFOUND;
         EXCEPTION
            WHEN VALUE_ERROR
            THEN
               v_errmsg :=
                  'Duplicate record exist  in pan acct master for pan  VALUE_ERROR'
                  || fn_getmaskpan (v_pan)
                  || 'acct id '
                  || x.cpa_acct_id;
               RAISE exp_reject_record;
            WHEN DUP_VAL_ON_INDEX
            THEN
               v_errmsg :=
                     'Duplicate record exist  in pan acct master for pan  '
                  || fn_getmaskpan (v_pan)
                  || 'acct id '
                  || x.cpa_acct_id;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                  'Error while inserting records into pan acct  master '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
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
              VALUES (prm_instcode,
                      v_cust_code,
                      v_acct_id,
                      1,
                      v_hash_new_pan,
                      v_mbrnumb,
                      prm_lupduser,
                      prm_lupduser,
                      v_encr_new_pan);
      EXCEPTION
         WHEN VALUE_ERROR
         THEN
            v_errmsg :=
               'Duplicate record exist  in pan acct master for pan  VALUE_ERROR'
               || fn_getmaskpan (v_pan)
               || 'acct id '
               || v_acct_id;
            RAISE exp_reject_record;
         WHEN DUP_VAL_ON_INDEX
         THEN
            v_errmsg :=
                  'Duplicate record exist  in pan acct master for pan  '
               || fn_getmaskpan (v_pan)
               || 'acct id '
               || v_acct_id;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while inserting records into pan acct  master '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

   prm_errmsg := 'OK';
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      prm_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg :=
         'Error while processing application for pan gen '
         || SUBSTR (SQLERRM, 1, 200);
END;
/
show error
