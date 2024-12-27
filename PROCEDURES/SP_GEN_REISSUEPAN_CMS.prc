CREATE OR REPLACE PROCEDURE vmscms.sp_gen_reissuepan_cms (
   prm_instcode       IN       NUMBER,
   prm_pancode        IN       NUMBER,
   prm_new_prodcode   IN       VARCHAR2,
   prm_new_cardtype   IN       VARCHAR2,
   prm_new_dispname   IN       VARCHAR2,
   prm_lupduser       IN       NUMBER,
   prm_pan            OUT      VARCHAR2,
   prm_errmsg         OUT      VARCHAR2
)
AS
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
   v_loop_cnt                NUMBER                                 DEFAULT 0;
   v_loop_max_cnt            NUMBER;
   v_noof_pan_param          NUMBER;
   v_inst_bin                cms_prod_bin.cpb_inst_bin%TYPE;
   v_serial_index            NUMBER;
   v_serial_maxlength        NUMBER (2);
   v_serial_no               NUMBER;
   v_check_digit             NUMBER;
   v_acct_id                 cms_acct_mast.cam_acct_id%TYPE;
   v_acct_num                cms_acct_mast.cam_acct_no%TYPE;
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
   v_savepoint               NUMBER                                 DEFAULT 1;
   v_acct_numb               cms_acct_mast.cam_acct_no%TYPE;
   v_cardtype_profile_code   cms_prod_cattype.cpc_profile_code%TYPE;
   v_appl_data               type_appl_rec_array;
   v_check_cardtype          NUMBER (1);
   v_check_custcarg          NUMBER (1);
   v_hash_pan                cms_appl_pan.cap_pan_code%TYPE;
   v_hash_new_pan            cms_appl_pan.cap_pan_code%TYPE;
   v_encr_new_pan            cms_appl_pan.cap_pan_code%TYPE;

   TYPE rec_pan_construct IS RECORD (
      cpc_profile_code   cms_pan_construct.cpc_profile_code%TYPE,
      cpc_field_name     cms_pan_construct.cpc_field_name%TYPE,
      cpc_start_from     cms_pan_construct.cpc_start_from%TYPE,
      cpc_start          cms_pan_construct.cpc_start%TYPE,
      cpc_length         cms_pan_construct.cpc_length%TYPE,
      cpc_field_value    VARCHAR2 (30)
   );

   TYPE table_pan_construct IS TABLE OF rec_pan_construct
      INDEX BY BINARY_INTEGER;

   v_seg31acctnum_data       type_acct_rec_array;
   v_table_pan_construct     table_pan_construct;
   exp_reject_record         EXCEPTION;

   CURSOR c (p_profile_code IN VARCHAR2)
   IS
      SELECT   cpc_profile_code, cpc_field_name, cpc_start_from, cpc_length,
               cpc_start
          FROM cms_pan_construct
         WHERE cpc_profile_code = p_profile_code
           AND cpc_inst_code = prm_instcode
      ORDER BY cpc_start_from DESC;

   CURSOR c1 (pan_code IN NUMBER)
   IS
      SELECT cpa_acct_id, cpa_acct_posn
        FROM cms_pan_acct
       WHERE cpa_pan_code = v_hash_pan AND cpa_inst_code = prm_instcode;

   PROCEDURE lp_pan_bin (
      l_instcode    IN       NUMBER,
      l_insttype    IN       NUMBER,
      l_prod_code   IN       VARCHAR2,
      l_pan_bin     OUT      NUMBER,
      l_errmsg      OUT      VARCHAR2
   )
   IS
   BEGIN
      SELECT cpb_inst_bin
        INTO l_pan_bin
        FROM cms_prod_bin
       WHERE cpb_inst_code = l_instcode
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

   PROCEDURE lp_pan_srno (
      l_instcode     IN       NUMBER,
      l_lupduser     IN       NUMBER,
      l_tmp_pan      IN       VARCHAR2,
      l_max_length   IN       NUMBER,
      l_srno         OUT      VARCHAR2,
      l_errmsg       OUT      VARCHAR2
   )
   IS
      v_ctrlnumb        NUMBER;
      v_max_serial_no   NUMBER;
   BEGIN
      l_errmsg := 'OK';

      SELECT cpc_ctrl_numb, cpc_max_serial_no
        INTO v_ctrlnumb, v_max_serial_no
        FROM cms_pan_ctrl
       WHERE cpc_pan_prefix = l_tmp_pan AND cpc_inst_code = l_instcode;

      IF v_ctrlnumb > v_max_serial_no
      THEN
         l_errmsg := 'Maximum serial number reached';
         RETURN;
      END IF;

      l_srno := v_ctrlnumb;

      UPDATE cms_pan_ctrl
         SET cpc_ctrl_numb = v_ctrlnumb + 1
       WHERE cpc_pan_prefix = l_tmp_pan AND cpc_inst_code = l_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO cms_pan_ctrl
                     (cpc_inst_code, cpc_pan_prefix, cpc_ctrl_numb,
                      cpc_max_serial_no
                     )
              VALUES (l_instcode, l_tmp_pan, 2,
                      LPAD ('9', l_max_length, 9)
                     );

         v_ctrlnumb := 1;
         l_srno := v_ctrlnumb;
      WHEN OTHERS
      THEN
         l_errmsg := 'Excp1 LP2 -- ' || SQLERRM;
   END;

   PROCEDURE lp_pan_chkdig (l_tmppan IN VARCHAR2, l_checkdig OUT NUMBER)
   IS
      ceilable_sum   NUMBER     := 0;
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
   prm_errmsg := 'OK';
   v_issueflag := 'Y';

   BEGIN
      v_hash_pan := gethash (prm_pancode);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
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
      SELECT cap_inst_code, cap_asso_code, cap_inst_type, cap_prod_code,
             cap_appl_bran, cap_cust_code, cap_card_type, cap_cust_catg,
             cap_card_stat, cap_disp_name, cap_appl_bran, cap_active_date,
             cap_expry_date, cap_addon_stat, cap_tot_acct, cap_chnl_code,
             cap_limit_amt, cap_use_limit, cap_bill_addr,
             cap_next_bill_date, cap_pbfgen_flag, cap_next_mb_date,
             cap_atm_offline_limit, cap_atm_online_limit,
             cap_pos_offline_limit, cap_pos_online_limit,
             cap_offline_aggr_limit, cap_online_aggr_limit,
             cap_firsttime_topup, cap_mbr_numb,
             type_appl_rec_array (cap_panmast_param1,
                                  cap_panmast_param2,
                                  cap_panmast_param3,
                                  cap_panmast_param4,
                                  cap_panmast_param5,
                                  cap_panmast_param6,
                                  cap_panmast_param7,
                                  cap_panmast_param8,
                                  cap_panmast_param9,
                                  cap_panmast_param10
                                 )
        INTO v_inst_code, v_asso_code, v_inst_type, v_prod_code,
             v_appl_bran, v_cust_code, v_card_type, v_cust_catg,
             v_card_stat, v_disp_name, v_appl_bran, v_active_date,
             v_expry_date, v_addon_stat, v_tot_acct, v_chnl_code,
             v_limit_amt, v_use_limit, v_bill_addr,
             v_next_bill_date, v_pbfgen_flag, v_next_mb_date,
             v_offline_atm_limit, v_online_atm_limit,
             v_offline_pos_limit, v_online_pos_limit,
             v_offline_aggr_limit, v_online_aggr_limit,
             v_cap_firsttime_topup, v_mbrnumb,
             v_appl_data
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'No row found for pan code' || prm_pancode;
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
       WHERE cpc_prod_code = v_prod_code
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
       WHERE cpc_prod_code = v_prod_code
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
                                v_errmsg
                               );

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
      lp_pan_bin (v_inst_code, v_inst_type, v_prod_code, v_bin, v_errmsg);

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
      SELECT cpm_profile_code, cpm_catg_code, cpc_prod_prefix,
             cpc_profile_code
        INTO v_profile_code, v_cpm_catg_code, v_prod_prefix,
             v_cardtype_profile_code
        FROM cms_prod_cattype, cms_prod_mast
       WHERE cpc_inst_code = prm_instcode
         AND cpc_prod_code = v_prod_code
         AND cpc_card_type = v_card_type
         AND cpm_prod_code = cpc_prod_code;

      IF v_profile_code IS NULL
      THEN
         v_errmsg := 'Product profile is not attached to product';
         RAISE exp_reject_record;
      END IF;

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

   BEGIN
      v_loop_cnt := 0;

      FOR i IN c (v_profile_code)
      LOOP
         v_loop_cnt := v_loop_cnt + 1;

         SELECT i.cpc_profile_code,
                i.cpc_field_name,
                i.cpc_start_from,
                i.cpc_length,
                i.cpc_start
           INTO v_table_pan_construct (v_loop_cnt).cpc_profile_code,
                v_table_pan_construct (v_loop_cnt).cpc_field_name,
                v_table_pan_construct (v_loop_cnt).cpc_start_from,
                v_table_pan_construct (v_loop_cnt).cpc_length,
                v_table_pan_construct (v_loop_cnt).cpc_start
           FROM DUAL;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting profile detail from profile mast '
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   BEGIN
      v_loop_max_cnt := v_table_pan_construct.COUNT;
      v_tmp_pan := NULL;

      FOR i IN 1 .. v_loop_max_cnt
      LOOP
         IF v_table_pan_construct (i).cpc_field_name = 'Card Type'
         THEN
            v_table_pan_construct (i).cpc_field_value :=
               LPAD (SUBSTR (TRIM (v_card_type),
                             v_table_pan_construct (i).cpc_start,
                             v_table_pan_construct (i).cpc_length
                            ),
                     v_table_pan_construct (i).cpc_length,
                     '0'
                    );
         ELSIF v_table_pan_construct (i).cpc_field_name = 'Branch'
         THEN
            v_table_pan_construct (i).cpc_field_value :=
               LPAD (SUBSTR (TRIM (v_appl_bran),
                             v_table_pan_construct (i).cpc_start,
                             v_table_pan_construct (i).cpc_length
                            ),
                     v_table_pan_construct (i).cpc_length,
                     '0'
                    );
         ELSIF v_table_pan_construct (i).cpc_field_name = 'BIN / PREFIX'
         THEN
            v_table_pan_construct (i).cpc_field_value :=
               LPAD (SUBSTR (TRIM (v_bin),
                             v_table_pan_construct (i).cpc_start,
                             v_table_pan_construct (i).cpc_length
                            ),
                     v_table_pan_construct (i).cpc_length,
                     '0'
                    );
         ELSIF v_table_pan_construct (i).cpc_field_name =
                                                     'Product Category Prefix'
         THEN
            v_table_pan_construct (i).cpc_field_value :=
               LPAD (SUBSTR (TRIM (v_prod_prefix),
                             v_table_pan_construct (i).cpc_start,
                             v_table_pan_construct (i).cpc_length
                            ),
                     v_table_pan_construct (i).cpc_length,
                     '0'
                    );
         ELSE
            IF v_table_pan_construct (i).cpc_field_name <> 'Serial Number'
            THEN
               v_errmsg :=
                     'Pan construct '
                  || v_table_pan_construct (i).cpc_field_name
                  || ' not exist ';
               RAISE exp_reject_record;
            END IF;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg := 'Error from pangen process ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      FOR j IN 1 .. v_loop_max_cnt
      LOOP
         IF     v_table_pan_construct (j).cpc_start_from = i
            AND v_table_pan_construct (j).cpc_field_name <> 'Serial Number'
         THEN
            v_tmp_pan :=
                       v_tmp_pan || v_table_pan_construct (j).cpc_field_value;
            EXIT;
         END IF;
      END LOOP;
   END LOOP;

   FOR i IN 1 .. v_table_pan_construct.COUNT
   LOOP
      IF v_table_pan_construct (i).cpc_field_name = 'Serial Number'
      THEN
         v_serial_index := i;
      END IF;
   END LOOP;

   IF v_serial_index IS NOT NULL
   THEN
      v_serial_maxlength := v_table_pan_construct (v_serial_index).cpc_length;
      lp_pan_srno (prm_instcode,
                   prm_lupduser,
                   v_tmp_pan,
                   v_serial_maxlength,
                   v_serial_no,
                   v_errmsg
                  );

      IF v_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      END IF;

      v_table_pan_construct (v_serial_index).cpc_field_value :=
         LPAD (SUBSTR (TRIM (v_serial_no),
                       v_table_pan_construct (v_serial_index).cpc_start,
                       v_table_pan_construct (v_serial_index).cpc_length
                      ),
               v_table_pan_construct (v_serial_index).cpc_length,
               '0'
              );
   END IF;

   v_tmp_pan := NULL;

   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      FOR j IN 1 .. v_loop_max_cnt
      LOOP
         IF v_table_pan_construct (j).cpc_start_from = i
         THEN
            v_tmp_pan :=
                       v_tmp_pan || v_table_pan_construct (j).cpc_field_value;
            EXIT;
         END IF;
      END LOOP;
   END LOOP;

   IF v_tmp_pan IS NOT NULL
   THEN
      lp_pan_chkdig (v_tmp_pan, v_check_digit);
      v_pan := v_tmp_pan || v_check_digit;
      prm_pan := v_pan;

      BEGIN
         v_hash_new_pan := gethash (v_pan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_encr_new_pan := fn_emaps_main (v_pan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

   BEGIN
      SELECT cam_acct_id, cam_acct_no, cam_hold_count, cam_curr_bran,
             cam_bill_addr, cam_type_code, cam_stat_code, cam_acct_bal,
             type_acct_rec_array (cam_acct_param1,
                                  cam_acct_param2,
                                  cam_acct_param3,
                                  cam_acct_param4,
                                  cam_acct_param5,
                                  cam_acct_param6,
                                  cam_acct_param7,
                                  cam_acct_param8,
                                  cam_acct_param9,
                                  cam_acct_param10
                                 )
        INTO v_acct_id, v_acct_num, v_hold_count, v_curr_bran,
             v_cam_bill_addr, v_type_code, v_stat_code, v_acct_bal,
             v_seg31acctnum_data
        FROM cms_acct_mast
       WHERE cam_inst_code = prm_instcode
         AND cam_acct_id =
                (SELECT cpa_acct_id
                   FROM cms_pan_acct
                  WHERE cpa_pan_code = v_hash_pan
                    AND cpa_mbr_numb = v_mbrnumb
                    AND cpa_inst_code = prm_instcode
                    AND cpa_acct_posn = 1);
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         v_errmsg := 'Error while fetching data for pan code ' || prm_pancode;
         RAISE exp_reject_record;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
                   'No account primary  defined for pan code ' || prm_pancode;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting acct detail for pan '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF v_cpm_catg_code = 'P'
   THEN
      BEGIN
         v_acct_num := NULL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while selecting acctnum ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF v_errmsg = 'OK'
      THEN
         BEGIN
            sp_create_acct (prm_instcode,
                            v_acct_num,
                            v_hold_count,
                            v_curr_bran,
                            v_cam_bill_addr,
                            v_type_code,
                            v_stat_code,
                            prm_lupduser,
                            v_seg31acctnum_data,
                            v_bin,
                            v_cust_code,
                            v_dup_flag,
                            v_acctid_new,
                            v_errmsg
                           );

            IF v_errmsg != 'OK'
            THEN
               v_errmsg :=
                         'Problem while calling the sp_ceate_acct' || SQLERRM;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_errmsg := 'Problem while creating acct' || SQLERRM;
               RAISE exp_reject_record;
         END;
      END IF;

      IF v_errmsg = 'OK'
      THEN
         BEGIN
            sp_create_holder (prm_instcode,
                              v_cust_code,
                              v_acctid_new,
                              NULL,
                              prm_lupduser,
                              v_holdposn,
                              v_errmsg
                             );

            IF v_errmsg != 'OK'
            THEN
               v_errmsg := 'Problem while calling the sp_ceate_holder';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       'Problem while calling the sp_ceate_holder' || SQLERRM;
               RAISE exp_reject_record;
         END;
      END IF;
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
            v_errmsg := 'Parent PAN not generated for ' || prm_pancode;
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
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Status'
         AND cbp_inst_code = prm_instcode;

      IF v_card_stat IS NULL
      THEN
         v_errmsg := 'Status is null for profile code ' || v_profile_code;
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT cbp_param_value
              INTO v_card_stat
              FROM cms_bin_param
             WHERE cbp_profile_code = v_profile_code
               AND cbp_param_name = 'Status'
               AND cbp_inst_code = prm_instcode;

            IF v_card_stat IS NULL
            THEN
               v_errmsg :=
                         'Status is null for profile code ' || v_profile_code;
               RAISE NO_DATA_FOUND;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                  'Status is not defined for either product or product type profile code ';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting carad status data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting card status for product profile '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      IF v_cpm_catg_code = 'P'
      THEN
         INSERT INTO cms_appl_pan
                     (cap_inst_code, cap_asso_code, cap_inst_type,
                      cap_prod_code, cap_prod_catg, cap_card_type,
                      cap_cust_catg, cap_pan_code, cap_mbr_numb,
                      cap_card_stat, cap_cust_code, cap_disp_name,
                      cap_limit_amt, cap_use_limit, cap_appl_bran,
                      cap_active_date, cap_expry_date, cap_addon_stat,
                      cap_addon_link, cap_mbr_link, cap_acct_id,
                      cap_acct_no, cap_tot_acct, cap_bill_addr,
                      cap_chnl_code, cap_pangen_date, cap_pangen_user,
                      cap_cafgen_flag, cap_pin_flag, cap_embos_flag,
                      cap_phy_embos, cap_join_feecalc, cap_next_bill_date,
                      cap_ins_user, cap_lupd_user, cap_pbfgen_flag,
                      cap_next_mb_date, cap_atm_offline_limit,
                      cap_atm_online_limit, cap_pos_offline_limit,
                      cap_pos_online_limit, cap_offline_aggr_limit,
                      cap_online_aggr_limit, cap_firsttime_topup,
                      cap_issue_flag, cap_panmast_param1,
                      cap_panmast_param2, cap_panmast_param3,
                      cap_panmast_param4, cap_panmast_param5,
                      cap_panmast_param6, cap_panmast_param7,
                      cap_panmast_param8, cap_panmast_param9,
                      cap_panmast_param10, cap_pan_code_encr
                     )
              VALUES (prm_instcode, v_asso_code, v_inst_type,
                      v_prod_code, v_cpm_catg_code, v_card_type,
                      v_cust_catg, v_hash_new_pan, v_mbrnumb,
                      v_card_stat, v_cust_code, v_disp_name,
                      v_limit_amt, v_use_limit, v_appl_bran,
                      SYSDATE, v_expry_date, v_addon_stat,
                      v_adonlink, v_mbrlink, v_acctid_new,
                      v_pan, v_tot_acct, v_bill_addr,
                      v_chnl_code, SYSDATE, prm_lupduser,
                      'Y', v_pingen_flag, v_emboss_flag,
                      'N', 'N', v_next_bill_date,
                      prm_lupduser, prm_lupduser, 'R',
                      v_next_mb_date, v_offline_atm_limit,
                      v_online_atm_limit, v_offline_pos_limit,
                      v_online_pos_limit, v_offline_aggr_limit,
                      v_online_aggr_limit, 'Y',
                      v_issueflag, v_appl_data (1),
                      v_appl_data (2), v_appl_data (3),
                      v_appl_data (4), v_appl_data (5),
                      v_appl_data (6), v_appl_data (7),
                      v_appl_data (8), v_appl_data (9),
                      v_appl_data (10), v_encr_new_pan
                     );
      END IF;

      IF v_cpm_catg_code IN ('D', 'A')
      THEN
         INSERT INTO cms_appl_pan
                     (cap_inst_code, cap_asso_code, cap_inst_type,
                      cap_prod_code, cap_prod_catg, cap_card_type,
                      cap_cust_catg, cap_pan_code, cap_mbr_numb,
                      cap_card_stat, cap_cust_code, cap_disp_name,
                      cap_limit_amt, cap_use_limit, cap_appl_bran,
                      cap_active_date, cap_expry_date, cap_addon_stat,
                      cap_addon_link, cap_mbr_link, cap_acct_id,
                      cap_acct_no, cap_tot_acct, cap_bill_addr,
                      cap_chnl_code, cap_pangen_date, cap_pangen_user,
                      cap_cafgen_flag, cap_pin_flag, cap_embos_flag,
                      cap_phy_embos, cap_join_feecalc, cap_next_bill_date,
                      cap_ins_user, cap_lupd_user, cap_pbfgen_flag,
                      cap_next_mb_date, cap_atm_offline_limit,
                      cap_atm_online_limit, cap_pos_offline_limit,
                      cap_pos_online_limit, cap_offline_aggr_limit,
                      cap_online_aggr_limit, cap_firsttime_topup,
                      cap_issue_flag, cap_panmast_param1,
                      cap_panmast_param2, cap_panmast_param3,
                      cap_panmast_param4, cap_panmast_param5,
                      cap_panmast_param6, cap_panmast_param7,
                      cap_panmast_param8, cap_panmast_param9,
                      cap_panmast_param10, cap_pan_code_encr
                     )
              VALUES (prm_instcode, v_asso_code, v_inst_type,
                      v_prod_code, v_cpm_catg_code, v_card_type,
                      v_cust_catg, v_hash_new_pan, v_mbrnumb,
                      v_card_stat, v_cust_code, v_disp_name,
                      v_limit_amt, v_use_limit, v_appl_bran,
                      SYSDATE, v_expry_date, v_addon_stat,
                      v_adonlink, v_mbrlink, v_acct_id,
                      v_acct_num, v_tot_acct, v_bill_addr,
                      v_chnl_code, SYSDATE, prm_lupduser,
                      'Y', v_pingen_flag, v_emboss_flag,
                      'N', 'N', v_next_bill_date,
                      prm_lupduser, prm_lupduser, 'R',
                      v_next_mb_date, v_offline_atm_limit,
                      v_online_atm_limit, v_offline_pos_limit,
                      v_online_pos_limit, v_offline_aggr_limit,
                      v_online_aggr_limit, 'Y',
                      v_issueflag, v_appl_data (1),
                      v_appl_data (2), v_appl_data (3),
                      v_appl_data (4), v_appl_data (5),
                      v_appl_data (6), v_appl_data (7),
                      v_appl_data (8), v_appl_data (9),
                      v_appl_data (10), v_encr_new_pan
                     );
      END IF;
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         v_errmsg :=
               'Pan '
            || v_pan
            || ' Error while inserting records into pan master  VALUE_ERROR';
         RAISE exp_reject_record;
      WHEN DUP_VAL_ON_INDEX
      THEN
         v_errmsg :=
                   'Pan ' || v_pan || ' is already present in the Pan_master';
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
      FOR x IN c1 (prm_pancode)
      LOOP
         BEGIN
            INSERT INTO cms_pan_acct
                        (cpa_inst_code, cpa_cust_code, cpa_acct_id,
                         cpa_acct_posn, cpa_pan_code, cpa_mbr_numb,
                         cpa_ins_user, cpa_lupd_user, cpa_pan_code_encr
                        )
                 VALUES (prm_instcode, v_cust_code, x.cpa_acct_id,
                         x.cpa_acct_posn, v_hash_new_pan, v_mbrnumb,
                         prm_lupduser, prm_lupduser, v_encr_new_pan
                        );

            EXIT WHEN c1%NOTFOUND;
         EXCEPTION
            WHEN VALUE_ERROR
            THEN
               v_errmsg :=
                     'Duplicate record exist  in pan acct master for pan  VALUE_ERROR'
                  || v_pan
                  || 'acct id '
                  || x.cpa_acct_id;
               RAISE exp_reject_record;
            WHEN DUP_VAL_ON_INDEX
            THEN
               v_errmsg :=
                     'Duplicate record exist  in pan acct master for pan  '
                  || v_pan
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
         INSERT INTO cms_pan_acct
                     (cpa_inst_code, cpa_cust_code, cpa_acct_id,
                      cpa_acct_posn, cpa_pan_code, cpa_mbr_numb,
                      cpa_ins_user, cpa_lupd_user, cpa_pan_code_encr
                     )
              VALUES (prm_instcode, v_cust_code, v_acctid_new,
                      1, v_hash_new_pan, v_mbrnumb,
                      prm_lupduser, prm_lupduser, v_encr_new_pan
                     );
      EXCEPTION
         WHEN VALUE_ERROR
         THEN
            v_errmsg :=
                  'Duplicate record exist  in pan acct master for pan  VALUE_ERROR'
               || v_pan
               || 'acct id '
               || v_acctid_new;
            RAISE exp_reject_record;
         WHEN DUP_VAL_ON_INDEX
         THEN
            v_errmsg :=
                  'Duplicate record exist  in pan acct master for pan  '
               || v_pan
               || 'acct id '
               || v_acctid_new;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting records into pan acct  master '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

   BEGIN
      BEGIN
         SELECT cip_param_value
           INTO v_host_proc
           FROM cms_inst_param
          WHERE cip_inst_code = prm_instcode
            AND cip_param_key = 'REQ_HOST_PROC';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_host_proc := 'N';
         WHEN OTHERS
         THEN
            v_host_proc := 'N';
      END;

      BEGIN
         IF v_cpm_catg_code = 'P'
         THEN
            IF v_host_proc = 'Y'
            THEN
               UPDATE cms_acct_mast
                  SET cam_acct_no = v_pan
                WHERE cam_inst_code = prm_instcode
                  AND cam_acct_id = v_acctid_new;
            ELSE
               UPDATE cms_acct_mast
                  SET cam_acct_no = v_pan,
                      cam_acct_bal = v_acct_bal
                WHERE cam_inst_code = prm_instcode
                  AND cam_acct_id = v_acctid_new;
            END IF;
         END IF;

         IF SQL%ROWCOUNT = 0
         THEN
            v_errmsg := 'Error while updating account number ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN VALUE_ERROR
         THEN
            v_errmsg := 'Error while updating acct bal and no.' || SQLERRM;
            RAISE exp_reject_record;
      END;
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         v_errmsg := 'Error while updating account number ';
         RAISE exp_reject_record;
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating record in Acct_mast '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF v_cpm_catg_code = 'P'
   THEN
      BEGIN
         SELECT cga_glcatg_code, cga_gl_code, cga_subgl_code,
                cga_acct_desc
           INTO v_old_gl_catg, v_old_gl_code, v_old_sub_gl_code,
                v_old_acct_desc
           FROM cms_gl_acct_mast
          WHERE cga_acct_code = prm_pancode AND cga_inst_code = prm_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Error while selecting old card GL detail '
               || ' card not found';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting old card GL detail '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         INSERT INTO cms_gl_acct_mast
                     (cga_inst_code, cga_glcatg_code, cga_gl_code,
                      cga_subgl_code, cga_acct_code, cga_acct_desc,
                      cga_tran_amt, cga_ins_date, cga_lupd_user,
                      cga_lupd_date
                     )
              VALUES (prm_instcode, v_old_gl_catg, v_old_gl_code,
                      v_old_sub_gl_code, v_pan, v_old_acct_desc,
                      0, SYSDATE, prm_lupduser,
                      SYSDATE
                     );
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            v_errmsg :=
                  'Error while inserting record in gl_acct_mast '
               || ' Duplicate record found';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting record in gl_acct_mast '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

   prm_errmsg := 'OK';
EXCEPTION
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

SHOW ERROR