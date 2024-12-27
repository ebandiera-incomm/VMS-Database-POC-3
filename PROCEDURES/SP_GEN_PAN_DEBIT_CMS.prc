create or replace
PROCEDURE        vmscms.sp_gen_pan_debit_cms (
   prm_instcode          IN       NUMBER,
   prm_applcode          IN       NUMBER,
   prm_lupduser          IN       NUMBER,
   prm_pan               OUT      VARCHAR2,
   prm_applprocess_msg   OUT      VARCHAR2,
   prm_errmsg            OUT      VARCHAR2
)
AS
   v_inst_code               cms_appl_mast.cam_inst_code%TYPE;
   v_asso_code               cms_appl_mast.cam_asso_code%TYPE;
   v_inst_type               cms_appl_mast.cam_inst_type%TYPE;
   v_prod_code               cms_appl_mast.cam_prod_code%TYPE;
   v_appl_bran               cms_appl_mast.cam_appl_bran%TYPE;
   v_cust_code               cms_appl_mast.cam_cust_code%TYPE;
   v_card_type               cms_appl_mast.cam_card_type%TYPE;
   v_cust_catg               cms_appl_mast.cam_cust_catg%TYPE;
   v_disp_name               cms_appl_mast.cam_disp_name%TYPE;
   v_active_date             cms_appl_mast.cam_active_date%TYPE;
   v_expry_date              cms_appl_mast.cam_expry_date%TYPE;
   v_expiry_date             DATE;
   v_addon_stat              cms_appl_mast.cam_addon_stat%TYPE;
   v_tot_acct                cms_appl_mast.cam_tot_acct%TYPE;
   v_chnl_code               cms_appl_mast.cam_chnl_code%TYPE;
   v_limit_amt               cms_appl_mast.cam_limit_amt%TYPE;
   v_use_limit               cms_appl_mast.cam_use_limit%TYPE;
   v_bill_addr               cms_appl_mast.cam_bill_addr%TYPE;
   v_request_id              cms_appl_mast.cam_request_id%TYPE;
   v_appl_stat               cms_appl_mast.cam_appl_stat%TYPE;
   v_bin                     cms_bin_mast.cbm_inst_bin%TYPE;
   v_profile_code            cms_prod_mast.cpm_profile_code%TYPE;
   v_cardtype_profile_code   cms_prod_cattype.cpc_profile_code%TYPE;
   v_errmsg                  VARCHAR2 (500);
   v_hsm_mode                cms_inst_param.cip_param_value%TYPE;
   v_pingen_flag             VARCHAR2 (1);
   v_emboss_flag             VARCHAR2 (1);
   v_loop_cnt                NUMBER                                 DEFAULT 0;
   v_loop_max_cnt            NUMBER;
   v_tmp_pan                 cms_appl_pan.cap_pan_code%TYPE;
   v_noof_pan_param          NUMBER;
   v_inst_bin                cms_prod_bin.cpb_inst_bin%TYPE;
   v_serial_index            NUMBER;
   v_serial_maxlength        NUMBER (2);
   v_serial_no               NUMBER;
   v_check_digit             NUMBER;
   v_pan                     cms_appl_pan.cap_pan_code%TYPE;
   v_acct_id                 cms_acct_mast.cam_acct_id%TYPE;
   v_acct_num                cms_acct_mast.cam_acct_no%TYPE;
   v_adonlink                cms_appl_pan.cap_pan_code%TYPE;
   v_mbrlink                 cms_appl_pan.cap_mbr_numb%TYPE;
   v_cam_addon_link          cms_appl_mast.cam_addon_link%TYPE;
   v_prod_prefix             cms_prod_cattype.cpc_prod_prefix%TYPE;
   v_card_stat               cms_appl_pan.cap_card_stat%TYPE;
   v_offline_atm_limit       cms_appl_pan.cap_atm_offline_limit%TYPE;
   v_online_atm_limit        cms_appl_pan.cap_atm_online_limit%TYPE;
   v_online_pos_limit        cms_appl_pan.cap_pos_online_limit%TYPE;
   v_offline_pos_limit       cms_appl_pan.cap_pos_offline_limit%TYPE;
   v_online_ecom_limit       cms_appl_pan.cap_ecom_online_limit%TYPE;
   v_offline_ecom_limit      cms_appl_pan.cap_ecom_offline_limit%TYPE;
   v_offline_aggr_limit      cms_appl_pan.cap_offline_aggr_limit%TYPE;
   v_online_aggr_limit       cms_appl_pan.cap_online_aggr_limit%TYPE;
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
   v_savepoint               NUMBER                                 DEFAULT 1;
   v_emp_id                  cms_cust_mast.ccm_emp_id%TYPE;
   v_corp_code               cms_cust_mast.ccm_corp_code%TYPE;
   v_appl_data               type_appl_rec_array;
   v_caf_gen_flag            CHAR (1)                             DEFAULT 'N';
   v_ikit_flag               cms_appl_pan.cap_ikit_flag%TYPE;
   v_mbrnumb                 cms_appl_pan.cap_mbr_numb%TYPE;
   v_validity_period         cms_bin_param.cbp_param_value%TYPE;
   v_pin_applicable          cms_bin_param.cbp_param_value%TYPE;
   v_emboss_applicable       cms_bin_param.cbp_param_value%TYPE;
   v_cap_cardstat            cms_appl_pan.cap_card_stat%TYPE;
   v_file_gen                cms_caf_info.cci_file_gen%TYPE;
   v_emv_applicable          VARCHAR2 (1);
   v_proxy_number            cms_appl_pan.cap_proxy_number%TYPE;
   v_online_mmpos_limit      cms_appl_pan.cap_mmpos_online_limit%TYPE;
   v_offline_mmpos_limit     cms_appl_pan.cap_mmpos_offline_limit%TYPE;
   v_hash_pan                cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                cms_appl_pan.cap_pan_code_encr%TYPE;
   v_getseqno                VARCHAR2 (200);
   programid                 VARCHAR2 (4);
   seqno                     cms_program_id_cnt.cpi_sequence_no%TYPE;
   v_cpc_serl_flag           cms_prod_cattype.cpc_serl_flag%TYPE;
   v_cam_file_name           cms_appl_mast.cam_file_name%TYPE;
   v_donot_mark_error        NUMBER (10)                            DEFAULT 0;
   p_shflcntrl_no            NUMBER (9);

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

   CURSOR c1 (appl_code IN NUMBER)
   IS
      SELECT cad_acct_id, cad_acct_posn
        FROM cms_appl_det
       WHERE cad_appl_code = prm_applcode AND cad_inst_code = prm_instcode;

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
      excp_reject       EXCEPTION;
      resource_busy     EXCEPTION;
      PRAGMA EXCEPTION_INIT (resource_busy, -30006);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      l_errmsg := 'OK';

      SELECT     cpc_ctrl_numb, cpc_max_serial_no
            INTO v_ctrlnumb, v_max_serial_no
            FROM cms_pan_ctrl
           WHERE cpc_pan_prefix = l_tmp_pan AND cpc_inst_code = l_instcode
      FOR UPDATE WAIT 1;

      IF v_ctrlnumb > LPAD ('9', l_max_length, 9)
      THEN
         l_errmsg := 'Maximum serial number reached';
         RAISE excp_reject;
      END IF;

      l_srno := v_ctrlnumb;

      BEGIN
         UPDATE cms_pan_ctrl
            SET cpc_ctrl_numb = v_ctrlnumb + 1
          WHERE cpc_pan_prefix = l_tmp_pan AND cpc_inst_code = l_instcode;

         IF SQL%ROWCOUNT = 0
         THEN
            l_errmsg := 'Error while updating serial no';
            RAISE excp_reject;
         END IF;

         COMMIT;
      EXCEPTION
         WHEN excp_reject
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            l_errmsg := 'Error While Updating Serial Number ' || SQLERRM;
            RAISE excp_reject;
      END;
   EXCEPTION
      WHEN resource_busy
      THEN
         l_errmsg := 'PLEASE TRY AFTER SOME TIME';
         ROLLBACK;
      WHEN excp_reject
      THEN
         ROLLBACK;
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
         COMMIT;
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
      DBMS_OUTPUT.put_line ('In check digit gen logic');
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

   PROCEDURE lp_shuffle_srno (
      p_instcode       IN       NUMBER,
      p_prod_code               cms_appl_mast.cam_prod_code%TYPE,
      p_card_type               cms_appl_mast.cam_card_type%TYPE,
      p_lupduser       IN       NUMBER,
      p_shflcntrl_no   OUT      VARCHAR2,
      v_serial_no      OUT      NUMBER,
      p_errmsg         OUT      VARCHAR2
   )
   IS
      v_csc_shfl_cntrl   NUMBER    := 0;
      excp_reject        EXCEPTION;
      resource_busy      EXCEPTION;
      PRAGMA EXCEPTION_INIT (resource_busy, -30006);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      p_errmsg := 'OK';

      BEGIN
         SELECT     csc_shfl_cntrl
               INTO v_csc_shfl_cntrl
               FROM cms_shfl_cntrl
              WHERE csc_inst_code = p_instcode
                AND csc_prod_code = v_prod_code
                AND csc_card_type = v_card_type
         FOR UPDATE WAIT 1;

         BEGIN
            SELECT css_serl_numb
              INTO v_serial_no
              FROM cms_shfl_serl
             WHERE css_inst_code = p_instcode
               AND css_prod_code = v_prod_code
               AND css_prod_catg = v_card_type
               AND css_shfl_cntrl = v_csc_shfl_cntrl
               AND css_serl_flag = 0;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_errmsg :=
                  'Shuffle Serial Number Not Found For Product And Product Catagoryh ';
               RAISE excp_reject;
            WHEN OTHERS
            THEN
               p_errmsg :=
                      'Error While Finding Shuffle Serial Number ' || SQLERRM;
               RAISE excp_reject;
         END;

         BEGIN
            UPDATE cms_shfl_cntrl
               SET csc_shfl_cntrl = v_csc_shfl_cntrl + 1
             WHERE csc_inst_code = p_instcode
               AND csc_prod_code = v_prod_code
               AND csc_card_type = v_card_type;

            IF SQL%ROWCOUNT = 0
            THEN
               p_errmsg :=
                  'Shuffle Control Number Not Configuerd For Prodcut and Card Type';
               RAISE excp_reject;
               ROLLBACK;
            END IF;

            COMMIT;
         EXCEPTION
            WHEN excp_reject
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                    'Error While Updating Shuffle Control Number ' || SQLERRM;
               ROLLBACK;
               RAISE excp_reject;
         END;
      EXCEPTION
         WHEN excp_reject
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               INSERT INTO cms_shfl_cntrl
                           (csc_inst_code, csc_prod_code, csc_card_type,
                            csc_shfl_cntrl, csc_ins_user
                           )
                    VALUES (1, p_prod_code, p_card_type,
                            1, 1
                           );

               v_csc_shfl_cntrl := 1;
               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'While Inserting into CMS_SHFL_CNTRL  -- ' || SQLERRM;
                  ROLLBACK;
            END;

            BEGIN
               SELECT css_serl_numb
                 INTO v_serial_no
                 FROM cms_shfl_serl
                WHERE css_inst_code = p_instcode
                  AND css_prod_code = v_prod_code
                  AND css_prod_catg = v_card_type
                  AND css_shfl_cntrl = v_csc_shfl_cntrl
                  AND css_serl_flag = 0;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  p_errmsg :=
                     'Shuffle Serial Number Not Found For Product And Product Catagory ';
                  RAISE excp_reject;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                      'Error While Finding Shuffle Serial Number ' || SQLERRM;
                  RAISE excp_reject;
            END;
         WHEN resource_busy
         THEN
            p_errmsg := 'PLEASE TRY AFTER SOME TIME';
            RAISE excp_reject;
         WHEN OTHERS
         THEN
            p_errmsg :=
                    'Error While Fetching Shuffle Control Number ' || SQLERRM;
            RAISE excp_reject;
      END;

      p_shflcntrl_no := v_csc_shfl_cntrl;
   EXCEPTION
      WHEN excp_reject
      THEN
         p_errmsg := p_errmsg;
         ROLLBACK;
      WHEN OTHERS
      THEN
         p_errmsg := 'Main Exception From LP_SHUFFLE_SRNO ' || SQLERRM;
         ROLLBACK;
   END lp_shuffle_srno;
BEGIN
   prm_applprocess_msg := 'OK';
   prm_errmsg := 'OK';

   BEGIN
      SELECT seq_pangen_savepoint.NEXTVAL
        INTO v_savepoint
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error from sequence pangen ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   SAVEPOINT v_savepoint;

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
      SELECT cam_inst_code, cam_asso_code, cam_inst_type, cam_prod_code,
             cam_appl_bran, cam_cust_code, cam_card_type, cam_cust_catg,
             cam_disp_name, cam_active_date, cam_expry_date, cam_addon_stat,
             cam_tot_acct, cam_chnl_code, cam_limit_amt, cam_use_limit,
             cam_bill_addr, cam_request_id, cam_appl_stat,
             cam_initial_topup_amount, cam_ikit_flag,
             type_appl_rec_array (cam_appl_param1,
                                  cam_appl_param2,
                                  cam_appl_param3,
                                  cam_appl_param4,
                                  cam_appl_param5,
                                  cam_appl_param6,
                                  cam_appl_param7,
                                  cam_appl_param8,
                                  cam_appl_param9,
                                  cam_appl_param10
                                 ),
             cam_file_name
        INTO v_inst_code, v_asso_code, v_inst_type, v_prod_code,
             v_appl_bran, v_cust_code, v_card_type, v_cust_catg,
             v_disp_name, v_active_date, v_expry_date, v_addon_stat,
             v_tot_acct, v_chnl_code, v_limit_amt, v_use_limit,
             v_bill_addr, v_request_id, v_appl_stat,
             v_initial_topup_amount, v_ikit_flag,
             v_appl_data,
             v_cam_file_name
        FROM cms_appl_mast
       WHERE cam_appl_code = prm_applcode
         AND cam_appl_stat = 'A'
         AND cam_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'No row found for application code' || prm_applcode;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting applcode from applmast'
            || SUBSTR (SQLERRM, 1, 300);
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
             cpc_profile_code, cpc_program_id, cpc_serl_flag
        INTO v_profile_code, v_cpm_catg_code, v_prod_prefix,
             v_cardtype_profile_code, programid, v_cpc_serl_flag
        FROM cms_prod_cattype, cms_prod_mast
       WHERE cpc_inst_code = prm_instcode
         AND cpc_prod_code = v_prod_code
         AND cpc_card_type = v_card_type
         AND cpm_prod_code = cpc_prod_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
               'Profile code not defined for product code '
            || v_prod_code
            || 'card type '
            || v_card_type;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting applcode from applmast'
            || SUBSTR (SQLERRM, 1, 300);
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
         DBMS_OUTPUT.put_line (   'IFIELD NAME '
                               || i
                               || v_table_pan_construct (i).cpc_field_name
                              );

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
            DBMS_OUTPUT.put_line (' loop indicator ' || i);
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
      DBMS_OUTPUT.put_line ('  PRINT loop indicator ' || i);
      DBMS_OUTPUT.put_line (   'PRINT START FROM  I  '
                            || v_table_pan_construct (i).cpc_start_from
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD NAME I  '
                            || v_table_pan_construct (i).cpc_field_name
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD VALUE I  '
                            || v_table_pan_construct (i).cpc_field_value
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD LENGTH I  '
                            || v_table_pan_construct (i).cpc_length
                           );
   END LOOP;

   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      FOR j IN 1 .. v_loop_max_cnt
      LOOP
         DBMS_OUTPUT.put_line (   ' j start from '
                               || v_table_pan_construct (j).cpc_start_from
                              );

         IF     v_table_pan_construct (j).cpc_start_from = i
            AND v_table_pan_construct (j).cpc_field_name <> 'Serial Number'
         THEN
            DBMS_OUTPUT.put_line (   'FIELD VALUE I '
                                  || v_table_pan_construct (j).cpc_field_value
                                 );
            v_tmp_pan :=
                        v_tmp_pan || v_table_pan_construct (j).cpc_field_value;
            DBMS_OUTPUT.put_line (v_tmp_pan);
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
      DBMS_OUTPUT.put_line ('SERIAL MAX LENGTH ' || v_serial_maxlength);

      IF v_cpc_serl_flag = 1
      THEN
         BEGIN
            lp_shuffle_srno (prm_instcode,
                             v_prod_code,
                             v_card_type,
                             prm_lupduser,
                             p_shflcntrl_no,
                             v_serial_no,
                             v_errmsg
                            );

            IF v_errmsg <> 'OK'
            THEN
               v_donot_mark_error := 1;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while calling LP_SHUFFLE_SRNO '
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

         BEGIN
            UPDATE cms_shfl_serl
               SET css_serl_flag = 1
             WHERE css_serl_numb = v_serial_no
               AND css_inst_code = prm_instcode
               AND css_prod_code = v_prod_code
               AND css_prod_catg = v_card_type
               AND css_shfl_cntrl = p_shflcntrl_no
               AND css_serl_flag = 0;

            IF SQL%ROWCOUNT = 0
            THEN
               v_errmsg :=
                  'Error updating Serial  control data, record not updated successfully';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                   'Error updating control data ' || SUBSTR (SQLERRM, 1, 150);
               RAISE exp_reject_record;
         END;
      ELSE
         BEGIN
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
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while calling LP_PAN_SRNO '
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;
      END IF;

      v_table_pan_construct (v_serial_index).cpc_field_value :=
         LPAD (SUBSTR (TRIM (v_serial_no),
                       v_table_pan_construct (v_serial_index).cpc_start,
                       v_table_pan_construct (v_serial_index).cpc_length
                      ),
               v_table_pan_construct (v_serial_index).cpc_length,
               '0'
              );
      DBMS_OUTPUT.put_line
                        (   'SERIAL NO '
                         || v_table_pan_construct (v_serial_index).cpc_field_value
                        );
   END IF;

   DBMS_OUTPUT.put_line (v_tmp_pan);

   FOR i IN 1 .. v_loop_max_cnt
   LOOP
      DBMS_OUTPUT.put_line ('  PRINT loop indicator ' || i);
      DBMS_OUTPUT.put_line (   'PRINT START FROM  I  '
                            || v_table_pan_construct (i).cpc_start_from
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD NAME I  '
                            || v_table_pan_construct (i).cpc_field_name
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD VALUE I  '
                            || v_table_pan_construct (i).cpc_field_value
                           );
      DBMS_OUTPUT.put_line (   'PRINT FIELD LENGTH I  '
                            || v_table_pan_construct (i).cpc_length
                           );
   END LOOP;

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

   DBMS_OUTPUT.put_line ('v_tmp_pan' || v_tmp_pan);
   lp_pan_chkdig (v_tmp_pan, v_check_digit);
   v_pan := v_tmp_pan || v_check_digit;
   DBMS_OUTPUT.put_line (v_pan);

   BEGIN
      v_hash_pan := gethash (v_pan);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      v_encr_pan := fn_emaps_main (v_pan);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cam_acct_id, cam_acct_no
        INTO v_acct_id, v_acct_num
        FROM cms_acct_mast
       WHERE cam_inst_code = prm_instcode
         AND cam_acct_id =
                (SELECT cad_acct_id
                   FROM cms_appl_det
                  WHERE cad_appl_code = prm_applcode
                    AND cad_acct_posn = 1
                    AND cad_inst_code = prm_instcode);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
                 'No account primary  defined for appl code ' || prm_applcode;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting acct detail for pan '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF v_addon_stat = 'A'
   THEN
      BEGIN
         SELECT cam_addon_link
           INTO v_cam_addon_link
           FROM cms_appl_mast
          WHERE cam_appl_code = prm_applcode AND cam_inst_code = prm_instcode;

         SELECT cap_pan_code, cap_mbr_numb
           INTO v_adonlink, v_mbrlink
           FROM cms_appl_pan
          WHERE cap_appl_code = v_cam_addon_link
            AND cap_inst_code = prm_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Parent PAN not generated for ' || prm_applcode;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg := 'Excp1.1 -- ' || SQLERRM;
            RAISE exp_reject_record;
      END;
   ELSIF v_addon_stat = 'P'
   THEN
      v_adonlink := v_hash_pan;
      v_mbrlink := '000';
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
      SELECT cbp_param_value
        INTO v_offline_atm_limit
        FROM cms_bin_param
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Offline ATM Limit'
         AND cbp_inst_code = prm_instcode;

      IF v_offline_atm_limit IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT cbp_param_value
              INTO v_offline_atm_limit
              FROM cms_bin_param
             WHERE cbp_profile_code = v_profile_code
               AND cbp_param_name = 'Offline ATM Limit'
               AND cbp_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_offline_atm_limit := 0;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting cffline limit data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting offline ATM limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cbp_param_value
        INTO v_online_atm_limit
        FROM cms_bin_param
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Online ATM Limit'
         AND cbp_inst_code = prm_instcode;

      IF v_online_atm_limit IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT cbp_param_value
              INTO v_online_atm_limit
              FROM cms_bin_param
             WHERE cbp_profile_code = v_profile_code
               AND cbp_param_name = 'Online ATM Limit'
               AND cbp_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_online_atm_limit := 0;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting cnline ATM limit data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting online ATM limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cbp_param_value
        INTO v_online_pos_limit
        FROM cms_bin_param
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Online POS Limit'
         AND cbp_inst_code = prm_instcode;

      IF v_online_pos_limit IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT cbp_param_value
              INTO v_online_pos_limit
              FROM cms_bin_param
             WHERE cbp_profile_code = v_profile_code
               AND cbp_param_name = 'Online POS Limit'
               AND cbp_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_online_pos_limit := 0;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting cnline pos limit data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting online POS limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cbp_param_value
        INTO v_offline_pos_limit
        FROM cms_bin_param
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Offline POS Limit'
         AND cbp_inst_code = prm_instcode;

      IF v_offline_pos_limit IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT cbp_param_value
              INTO v_offline_pos_limit
              FROM cms_bin_param
             WHERE cbp_profile_code = v_profile_code
               AND cbp_param_name = 'Offline POS Limit'
               AND cbp_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_offline_pos_limit := 0;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting cffline pos limit data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting offline POS limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cbp_param_value
        INTO v_offline_mmpos_limit
        FROM cms_bin_param
       WHERE cbp_inst_code = prm_instcode
         AND cbp_profile_code = v_profile_code
         AND cbp_param_name = 'Offline MMPOS Limit';

      IF v_card_stat IS NULL
      THEN
         v_offline_mmpos_limit := 0;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_offline_mmpos_limit := 0;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting offline POS limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cbp_param_value
        INTO v_online_mmpos_limit
        FROM cms_bin_param
       WHERE cbp_inst_code = prm_instcode
         AND cbp_profile_code = v_profile_code
         AND cbp_param_name = 'Online MMPOS Limit';

      IF v_card_stat IS NULL
      THEN
         v_online_mmpos_limit := 0;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_online_mmpos_limit := 0;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting online POS limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cbp_param_value
        INTO v_online_ecom_limit
        FROM cms_bin_param
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Online Ecom Limit'
         AND cbp_inst_code = prm_instcode;

      IF v_online_ecom_limit IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT cbp_param_value
              INTO v_online_ecom_limit
              FROM cms_bin_param
             WHERE cbp_profile_code = v_profile_code
               AND cbp_param_name = 'Online Ecom Limit'
               AND cbp_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_online_ecom_limit := 0;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting cnline Ecom limit data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting online Ecom limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cbp_param_value
        INTO v_offline_ecom_limit
        FROM cms_bin_param
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Offline Ecom Limit'
         AND cbp_inst_code = prm_instcode;

      IF v_offline_ecom_limit IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT cbp_param_value
              INTO v_offline_ecom_limit
              FROM cms_bin_param
             WHERE cbp_profile_code = v_profile_code
               AND cbp_param_name = 'Offline Ecom Limit'
               AND cbp_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_offline_ecom_limit := 0;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting cffline Ecom limit data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting cffline Ecom  limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   v_offline_aggr_limit :=
             v_offline_atm_limit + v_offline_pos_limit + v_offline_mmpos_limit;
   v_online_aggr_limit :=
                v_online_atm_limit + v_online_pos_limit + v_online_mmpos_limit;

   BEGIN
      SELECT cbp_param_value
        INTO v_expryparam
        FROM cms_bin_param
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Validity'
         AND cbp_inst_code = prm_instcode;

      IF v_expryparam IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      ELSE
         BEGIN
            SELECT cbp_param_value
              INTO v_validity_period
              FROM cms_bin_param
             WHERE cbp_profile_code = v_cardtype_profile_code
               AND cbp_param_name = 'Validity Period'
               AND cbp_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                  'Validity period is not defined for product cattype profile ';
               RAISE exp_reject_record;
         END;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT cbp_param_value
              INTO v_expryparam
              FROM cms_bin_param
             WHERE cbp_profile_code = v_profile_code
               AND cbp_param_name = 'Validity'
               AND cbp_inst_code = prm_instcode;

            IF v_expryparam IS NULL
            THEN
               RAISE NO_DATA_FOUND;
            ELSE
               BEGIN
                  SELECT cbp_param_value
                    INTO v_validity_period
                    FROM cms_bin_param
                   WHERE cbp_profile_code = v_profile_code
                     AND cbp_param_name = 'Validity Period'
                     AND cbp_inst_code = prm_instcode;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                        'Validity period is not defined for product profile ';
                     RAISE exp_reject_record;
               END;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                  'No validity data found either product/product type profile ';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting validity data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting offline POS limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF v_validity_period = 'Hour'
   THEN
      v_expiry_date := SYSDATE + v_expryparam / 24;
   ELSIF v_validity_period = 'Day'
   THEN
      v_expiry_date := SYSDATE + v_expryparam;
   ELSIF v_validity_period = 'Week'
   THEN
      v_expiry_date := SYSDATE + (7 * v_expryparam);
   ELSIF v_validity_period = 'Month'
   THEN
      v_expiry_date := LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1));
   ELSIF v_validity_period = 'Year'
   THEN
      v_expiry_date :=
                      LAST_DAY (ADD_MONTHS (SYSDATE, (12 * v_expryparam) - 1));
   END IF;

   BEGIN
      SELECT cbp_param_value
        INTO v_emv_applicable
        FROM cms_bin_param
       WHERE cbp_profile_code = v_profile_code
         AND cbp_param_name = 'PAN Aplicable'
         AND cbp_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
                   'PAN applicable field is not defined for product profile ';
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cbp_param_value
        INTO v_emv_applicable
        FROM cms_bin_param
       WHERE cbp_profile_code = v_profile_code
         AND cbp_param_name = 'EMV'
         AND cbp_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
                   'EMV applicable field is not defined for product profile ';
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cbp_param_value
        INTO v_pin_applicable
        FROM cms_bin_param
       WHERE cbp_profile_code = v_profile_code
         AND cbp_param_name = 'PIN Aplicable'
         AND cbp_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
                   'Pin applicable field is not defined for product profile ';
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cbp_param_value
        INTO v_emboss_applicable
        FROM cms_bin_param
       WHERE cbp_profile_code = v_profile_code
         AND cbp_param_name = 'EMBOSS Aplicable'
         AND cbp_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
                'Emboss applicable field is not defined for product profile ';
         RAISE exp_reject_record;
   END;

   IF v_pin_applicable = 'N'
   THEN
      v_pingen_flag := 'N';
   END IF;

   IF v_emboss_applicable = 'N'
   THEN
      v_emboss_flag := 'N';
   END IF;

   IF v_request_id IS NOT NULL
   THEN
      v_issueflag := 'N';
   ELSE
      v_issueflag := 'Y';
   END IF;

   BEGIN
      SELECT ccm_emp_id, ccm_corp_code
        INTO v_emp_id, v_corp_code
        FROM cms_cust_mast
       WHERE ccm_inst_code = prm_instcode AND ccm_cust_code = v_cust_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Customer code not found in master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting customer code from master'
            || SUBSTR (SQLERRM, 1, 150);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cip_param_value
        INTO v_mbrnumb
        FROM cms_inst_param
       WHERE cip_inst_code = prm_instcode AND cip_param_key = 'MBR_NUMB';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'memeber number not defined in master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting memeber number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   sp_gen_get_cardstat (prm_instcode,
                        v_acct_num,
                        v_card_stat,
                        v_cap_cardstat,
                        v_errmsg
                       );

   IF v_errmsg <> 'OK'
   THEN
      RAISE exp_reject_record;
   END IF;

   BEGIN
      v_getseqno :=
            'SELECT CPI_SEQUENCE_NO FROM CMS_PROGRAM_ID_CNT WHERE CPI_PROGRAM_ID='
         || CHR (39)
         || programid
         || CHR (39)
         || 'AND CPI_INST_CODE='
         || prm_instcode;

      EXECUTE IMMEDIATE v_getseqno
                   INTO seqno;

--      v_proxy_number :=
--         fn_proxy_no (SUBSTR (v_pan, 1, 6),
--                      LPAD (v_card_type, 2, 0),
--                      programid,
--                      NVL (seqno, 0),
--                      prm_instcode,
--                      prm_lupduser
--                     );
--
--      IF v_proxy_number = '0'
--      THEN
--         v_errmsg :=
--                  'Error while gen Proxy number ' || SUBSTR (SQLERRM, 1, 200);
--         RAISE exp_reject_record;
--      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while Proxy number ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      INSERT INTO cms_appl_pan
                  (cap_appl_code, cap_inst_code, cap_asso_code,
                   cap_inst_type, cap_prod_code, cap_prod_catg,
                   cap_card_type, cap_cust_catg, cap_pan_code, cap_mbr_numb,
                   cap_card_stat, cap_cust_code, cap_disp_name,
                   cap_limit_amt, cap_use_limit, cap_appl_bran,
                   cap_expry_date, cap_addon_stat, cap_addon_link,
                   cap_mbr_link, cap_acct_id, cap_acct_no, cap_tot_acct,
                   cap_bill_addr, cap_chnl_code, cap_pangen_date,
                   cap_pangen_user, cap_cafgen_flag, cap_pin_flag,
                   cap_embos_flag, cap_phy_embos, cap_join_feecalc,
                   cap_next_bill_date, cap_next_mb_date, cap_request_id,
                   cap_issue_flag, cap_ins_user, cap_lupd_user,
                   cap_atm_offline_limit, cap_atm_online_limit,
                   cap_pos_offline_limit, cap_pos_online_limit,
                   cap_ecom_online_limit, cap_ecom_offline_limit,
                   cap_offline_aggr_limit, cap_online_aggr_limit,
                   cap_emp_id, cap_firsttime_topup, cap_ikit_flag,
                   cap_panmast_param1, cap_panmast_param2,
                   cap_panmast_param3, cap_panmast_param4,
                   cap_panmast_param5, cap_panmast_param6,
                   cap_panmast_param7, cap_panmast_param8,
                   cap_panmast_param9, cap_panmast_param10,
                   cap_pan_code_encr, cap_proxy_number,
                   cap_mmpos_online_limit, cap_mmpos_offline_limit
                  )
           VALUES (prm_applcode, prm_instcode, v_asso_code,
                   v_inst_type, v_prod_code, v_cpm_catg_code,
                   v_card_type, v_cust_catg, v_hash_pan, v_mbrnumb,
                   v_cap_cardstat, v_cust_code, v_disp_name,
                   v_limit_amt, v_use_limit, v_appl_bran,
                   v_expry_date, v_addon_stat, v_adonlink,
                   v_mbrlink, v_acct_id, v_acct_num, v_tot_acct,
                   v_bill_addr, v_chnl_code, SYSDATE,
                   prm_lupduser, v_caf_gen_flag, v_pingen_flag,
                   v_emboss_flag, 'N', 'N',
                   NULL, NULL, v_request_id,
                   v_issueflag, prm_lupduser, prm_lupduser,
                   v_offline_atm_limit, v_online_atm_limit,
                   v_offline_pos_limit, v_online_pos_limit,
                   v_online_ecom_limit, v_offline_ecom_limit,
                   v_offline_aggr_limit, v_online_aggr_limit,
                   v_emp_id, NULL, v_ikit_flag,
                   v_appl_data (1), v_appl_data (2),
                   v_appl_data (3), v_appl_data (4),
                   v_appl_data (5), v_appl_data (6),
                   v_appl_data (7), v_appl_data (8),
                   v_appl_data (9), v_appl_data (10),
                   v_encr_pan, v_proxy_number,
                   v_online_mmpos_limit, v_offline_mmpos_limit
                  );
   EXCEPTION
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

   BEGIN
      INSERT INTO cms_smsandemail_alert
                  (csa_inst_code, csa_pan_code, csa_pan_code_encr,
                   csa_loadorcredit_flag, csa_lowbal_flag, csa_negbal_flag,
                   csa_highauthamt_flag, csa_dailybal_flag, csa_insuff_flag,
                   csa_incorrpin_flag, csa_fast50_flag,
                   csa_fedtax_refund_flag, csa_deppending_flag,
                   csa_depaccepted_flag, csa_deprejected_flag, csa_ins_user,
                   csa_ins_date
                  )
           VALUES (prm_instcode, v_hash_pan, v_encr_pan,
                   0, 0, 0,
                   0, 0, 0,
                   0, 0,
                   0, 0,
                   0, 0, prm_lupduser,
                   SYSDATE
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into SMS_EMAIL ALERT '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   FOR x IN c1 (prm_applcode)
   LOOP
      BEGIN
         INSERT INTO cms_pan_acct
                     (cpa_inst_code, cpa_cust_code, cpa_acct_id,
                      cpa_acct_posn, cpa_pan_code, cpa_mbr_numb,
                      cpa_ins_user, cpa_lupd_user, cpa_pan_code_encr
                     )
              VALUES (prm_instcode, v_cust_code, x.cad_acct_id,
                      x.cad_acct_posn, v_hash_pan, v_mbrnumb,
                      prm_lupduser, prm_lupduser, v_encr_pan
                     );

         EXIT WHEN c1%NOTFOUND;
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            v_errmsg :=
                  'Duplicate record exist  in pan acct master for pan  '
               || v_pan
               || 'acct id '
               || x.cad_acct_id;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting records into pan acct  master '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END LOOP;

   BEGIN
      UPDATE cms_acct_mast
         SET cam_acct_no = v_acct_num
       WHERE cam_inst_code = prm_instcode AND cam_acct_no = v_acct_num;

      IF SQL%ROWCOUNT = 0
      THEN
         v_errmsg := 'Error while updating account number ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
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

   IF v_errmsg = 'OK'
   THEN
      BEGIN
         sp_caf_rfrsh (prm_instcode,
                       v_pan,
                       v_mbrnumb,
                       SYSDATE,
                       'A',
                       NULL,
                       'NEW',
                       prm_lupduser,
                       v_encr_pan,
                       v_errmsg
                      );

         IF v_errmsg != 'OK'
         THEN
            v_errmsg := 'From caf refresh -- ' || v_errmsg;
            RAISE exp_reject_record;
         ELSIF v_errmsg = 'OK'
         THEN
            IF (v_pingen_flag = 'N' AND v_emboss_flag = 'N')
            THEN
               v_file_gen := 'N';
            ELSIF (v_pingen_flag = 'N' AND v_emboss_flag = 'Y')
            THEN
               v_file_gen := 'E';
            ELSIF (v_pingen_flag = 'Y' AND v_emboss_flag = 'N')
            THEN
               v_file_gen := 'P';
            ELSIF (v_pingen_flag = 'Y' AND v_emboss_flag = 'Y')
            THEN
               IF v_emv_applicable = 'P'
               THEN
                  v_file_gen := 'P';
               ELSE
                  v_file_gen := 'E';
               END IF;
            END IF;

            UPDATE cms_caf_info
               SET cci_pin_ofst = LPAD (' ', 16, ' '),
                   cci_file_gen = v_file_gen
             WHERE cci_inst_code = prm_instcode
               AND cci_pan_code = v_hash_pan
               AND cci_mbr_numb = v_mbrnumb;

            IF SQL%ROWCOUNT != 1
            THEN
               v_errmsg :=
                     'Problem in updation of pin as blank in cafinfio for pan '
                  || v_pan
                  || 'Member number '
                  || v_mbrnumb
                  || '   instcode '
                  || prm_instcode;
               RAISE exp_reject_record;
            END IF;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg := 'Excp  for pin updation in SP_GEN_PAN-- ' || SQLERRM;
      END;
   END IF;

   BEGIN
      UPDATE cms_appl_mast
         SET cam_appl_stat = 'O',
             cam_lupd_user = prm_lupduser,
             cam_process_msg = 'SUCCESSFUL'
       WHERE cam_appl_code = prm_applcode AND cam_inst_code = prm_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating records in appl mast  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      INSERT INTO cms_audit_log_process
                  (cal_inst_code, cal_appl_no, cal_acct_no, cal_pan_no,
                   cal_prod_code,
                   cal_prg_name, cal_action,
                   cal_status,
                   cal_ref_tab_name, cal_ref_tab_rowid, cal_pan_encr,
                   cal_ins_user, cal_ins_date
                  )
           VALUES (prm_instcode, prm_applcode, v_acct_num, v_hash_pan,
                   (SELECT cpm.cpm_prod_desc
                      FROM cms_prod_mast cpm
                     WHERE cpm.cpm_prod_code = v_prod_code),
                   'PAN GENERATION', 'INSERT',
                   DECODE (v_errmsg, 'OK', 'SUCCESS', 'FAILURE'),
                   'CMS_APPL_PAN', '', fn_emaps_main (v_pan),
                   prm_lupduser, SYSDATE
                  );
   END;

   prm_errmsg := 'OK';
   prm_applprocess_msg := 'OK';
EXCEPTION
   WHEN exp_reject_record
   THEN
      ROLLBACK TO v_savepoint;
      prm_errmsg := v_errmsg;

      IF v_donot_mark_error <> 1
      THEN
         UPDATE cms_appl_mast
            SET cam_appl_stat = 'E',
                cam_process_msg = v_errmsg,
                cam_lupd_user = prm_lupduser
          WHERE cam_appl_code = prm_applcode AND cam_inst_code = prm_instcode;
      ELSIF v_donot_mark_error = 1
      THEN
         INSERT INTO cms_serl_error
                     (cse_inst_code, cse_prod_code, cse_prod_catg,
                      cse_ordr_rfrno, cse_err_mseg
                     )
              VALUES (prm_instcode, v_prod_code, v_card_type,
                      v_cam_file_name, v_errmsg
                     );
      END IF;

      prm_applprocess_msg := v_errmsg;
      prm_errmsg := 'OK';
   WHEN OTHERS
   THEN
      ROLLBACK TO v_savepoint;
      prm_applprocess_msg :=
            'Error while processing application for pan gen '
         || SUBSTR (SQLERRM, 1, 200);
      v_errmsg :=
            'Error while processing application for pan gen '
         || SUBSTR (SQLERRM, 1, 200);

      UPDATE cms_appl_mast
         SET cam_appl_stat = 'E',
             cam_process_msg = v_errmsg,
             cam_lupd_user = prm_lupduser
       WHERE cam_appl_code = prm_applcode AND cam_inst_code = prm_instcode;

      prm_errmsg := 'OK';
END;
/
show error