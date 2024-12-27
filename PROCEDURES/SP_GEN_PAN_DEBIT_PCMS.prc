CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Gen_Pan_Debit_Pcms (
   prm_instcode          IN       NUMBER,
   prm_applcode          IN       NUMBER,
   prm_lupduser          IN       NUMBER,
   prm_pan               OUT      VARCHAR2,
   prm_applprocess_msg   OUT      VARCHAR2,
   prm_errmsg            OUT      VARCHAR2
)
AS
   v_inst_code              CMS_APPL_MAST.cam_inst_code%TYPE;
   v_asso_code              CMS_APPL_MAST.cam_asso_code%TYPE;
   v_inst_type              CMS_APPL_MAST.cam_inst_type%TYPE;
   v_prod_code              CMS_APPL_MAST.cam_prod_code%TYPE;
   v_appl_bran              CMS_APPL_MAST.cam_appl_bran%TYPE;
   v_cust_code              CMS_APPL_MAST.cam_cust_code%TYPE;
   v_card_type              CMS_APPL_MAST.cam_card_type%TYPE;
   v_cust_catg              CMS_APPL_MAST.cam_cust_catg%TYPE;
   v_disp_name              CMS_APPL_MAST.cam_disp_name%TYPE;
   v_active_date            CMS_APPL_MAST.cam_active_date%TYPE;
   v_expry_date             CMS_APPL_MAST.cam_expry_date%TYPE;
   v_addon_stat             CMS_APPL_MAST.cam_addon_stat%TYPE;
   v_tot_acct               CMS_APPL_MAST.cam_tot_acct%TYPE;
   v_chnl_code              CMS_APPL_MAST.cam_chnl_code%TYPE;
   v_limit_amt              CMS_APPL_MAST.cam_limit_amt%TYPE;
   v_use_limit              CMS_APPL_MAST.cam_use_limit%TYPE;
   v_bill_addr              CMS_APPL_MAST.cam_bill_addr%TYPE;
   v_request_id             CMS_APPL_MAST.cam_request_id%TYPE;
   v_appl_stat              CMS_APPL_MAST.cam_appl_stat%TYPE;
   v_bin                    CMS_BIN_MAST.cbm_inst_bin%TYPE;
   v_profile_code           CMS_PROD_MAST.cpm_profile_code%TYPE;
   v_cardtype_profile_code  CMS_PROD_CATTYPE.cpc_profile_code%TYPE; 
   v_errmsg                 VARCHAR2 (500);
   v_hsm_mode               CMS_INST_PARAM.cip_param_value%TYPE;
   v_pingen_flag            VARCHAR2 (1);
   v_emboss_flag            VARCHAR2 (1);
   v_loop_cnt               NUMBER                                  DEFAULT 0;
   v_loop_max_cnt           NUMBER;
   v_tmp_pan                CMS_APPL_PAN.cap_pan_code%TYPE;
   v_noof_pan_param         NUMBER;
   v_inst_bin               CMS_PROD_BIN.cpb_inst_bin%TYPE;
   v_serial_index           NUMBER;
   v_serial_maxlength       NUMBER (2);
   v_serial_no              NUMBER;
   v_check_digit            NUMBER;
   v_pan                    CMS_APPL_PAN.cap_pan_code%TYPE;
   v_acct_id                CMS_ACCT_MAST.cam_acct_id%TYPE;
   v_acct_num               CMS_ACCT_MAST.cam_acct_no%TYPE;
   v_adonlink               CMS_APPL_PAN.cap_pan_code%TYPE;
   v_mbrlink                CMS_APPL_PAN.cap_mbr_numb%TYPE;
   v_cam_addon_link         CMS_APPL_MAST.cam_addon_link%TYPE;
   v_prod_prefix            CMS_PROD_CATTYPE.cpc_prod_prefix%TYPE;
   v_card_stat              CMS_APPL_PAN.cap_card_stat%TYPE;
   v_offline_atm_limit      CMS_APPL_PAN.cap_atm_offline_limit%TYPE;
   v_online_atm_limit       CMS_APPL_PAN.cap_atm_online_limit%TYPE;
   v_online_pos_limit       CMS_APPL_PAN.cap_pos_online_limit%TYPE;
   v_offline_pos_limit      CMS_APPL_PAN.cap_pos_offline_limit%TYPE;
   v_offline_aggr_limit     CMS_APPL_PAN.cap_offline_aggr_limit%TYPE;
   v_online_aggr_limit      CMS_APPL_PAN.cap_online_aggr_limit%TYPE;
   v_cpm_catg_code          CMS_PROD_MAST.cpm_catg_code%TYPE;
   v_issueflag              VARCHAR2 (1);
   v_initial_topup_amount   CMS_APPL_MAST.cam_initial_topup_amount%TYPE;
   v_func_code              CMS_FUNC_MAST.cfm_func_code%TYPE;
   v_func_desc              CMS_FUNC_MAST.cfm_func_desc%TYPE;
   v_cr_gl_code             CMS_FUNC_PROD.cfp_crgl_code%TYPE;
   v_crgl_catg              CMS_FUNC_PROD.cfp_crgl_catg%TYPE;
   v_crsubgl_code           CMS_FUNC_PROD.cfp_crsubgl_code%TYPE;
   v_cracct_no              CMS_FUNC_PROD.cfp_cracct_no%TYPE;
   v_dr_gl_code             CMS_FUNC_PROD.cfp_drgl_code%TYPE;
   v_drgl_catg              CMS_FUNC_PROD.cfp_drgl_catg%TYPE;
   v_drsubgl_code           CMS_FUNC_PROD.cfp_drsubgl_code%TYPE;
   v_dracct_no              CMS_FUNC_PROD.cfp_dracct_no%TYPE;
   v_gl_check               NUMBER (1);
   v_subgl_desc             VARCHAR2 (30);
   v_tran_code              CMS_FUNC_MAST.cfm_txn_code%TYPE;
   v_tran_mode              CMS_FUNC_MAST.cfm_txn_mode%TYPE;
   v_delv_chnl              CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
   v_tran_type              CMS_FUNC_MAST.cfm_txn_type%TYPE;
   v_expryparam             CMS_BIN_PARAM.cbp_param_value%TYPE;
   v_savepoint              NUMBER                                  DEFAULT 1;
   v_emp_id                 CMS_CUST_MAST.ccm_emp_id%TYPE;
   v_corp_code              CMS_CUST_MAST.ccm_corp_code%TYPE;
   v_caf_gen_flag   CHAR(1) DEFAULT 'N';
   TYPE rec_pan_construct IS RECORD (
      cpc_profile_code   CMS_PAN_CONSTRUCT.cpc_profile_code%TYPE,
      cpc_field_name     CMS_PAN_CONSTRUCT.cpc_field_name%TYPE,
      cpc_start_from     CMS_PAN_CONSTRUCT.cpc_start_from%TYPE,
      cpc_start          CMS_PAN_CONSTRUCT.cpc_start%TYPE,
      cpc_length         CMS_PAN_CONSTRUCT.cpc_length%TYPE,
      cpc_field_value    VARCHAR2 (30)
   );

   TYPE table_pan_construct IS TABLE OF rec_pan_construct
      INDEX BY BINARY_INTEGER;

   v_table_pan_construct    table_pan_construct;
   exp_reject_record        EXCEPTION;

   CURSOR c (p_profile_code IN VARCHAR2)
   IS
      SELECT   cpc_profile_code, cpc_field_name, cpc_start_from, cpc_length,
               cpc_start
          FROM CMS_PAN_CONSTRUCT
         WHERE cpc_profile_code = p_profile_code
      ORDER BY cpc_start_from DESC;

   CURSOR c1 (appl_code IN NUMBER)
   IS
      SELECT cad_acct_id, cad_acct_posn
        FROM CMS_APPL_DET
       WHERE cad_appl_code = prm_applcode;

   --SN   LOCAL PROCEDURES
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
        FROM CMS_PROD_BIN
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
   BEGIN
      l_errmsg := 'OK';

      SELECT cpc_ctrl_numb, cpc_max_serial_no
        INTO v_ctrlnumb, v_max_serial_no
        FROM CMS_PAN_CTRL
       WHERE cpc_pan_prefix = l_tmp_pan;

      IF v_ctrlnumb > v_max_serial_no
      THEN
         l_errmsg := 'Maximum serial number reached';
         RETURN;
      END IF;

      l_srno := v_ctrlnumb;

      UPDATE CMS_PAN_CTRL
         SET cpc_ctrl_numb = v_ctrlnumb + 1
       WHERE cpc_pan_prefix = l_tmp_pan;

      IF SQL%ROWCOUNT = 0
      THEN
         l_errmsg := 'Error while updating serial no';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO CMS_PAN_CTRL
                     (cpc_inst_code, cpc_pan_prefix, cpc_ctrl_numb,
                      cpc_max_serial_no
                     )
              VALUES (1, l_tmp_pan, 2,
                      LPAD ('9', l_max_length, 9)
                     );

         v_ctrlnumb := 1;
         l_srno := v_ctrlnumb;
      WHEN OTHERS
      THEN
         l_errmsg := 'Excp1 LP2 -- ' || SQLERRM;
   END;

   PROCEDURE lp_pan_chkdig (                               --l_prfx IN NUMBER,
                               -- l_prod_prefix IN VARCHAR2,
                            -- l_srno IN VARCHAR2,
                            l_tmppan IN VARCHAR2, l_checkdig OUT NUMBER)
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
      --temp_pan  := l_prfx||l_prod_prefix||l_srno ;
      --len_pan      := LENGTH(temp_pan);
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
         THEN                                                           --IF 2
            mult_ind := 1;
         ELSE                                                   --Else of If 2
            mult_ind := 2;
         END IF;                                                 --End of IF 2
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
   --dbms_output.put_line('FROM LOCAL CHK GEN---->'||l_checkdig);
   END;
--EN  LOCAL PROCEDURES
BEGIN                                                       --<< MAIN BEGIN >>
   prm_applprocess_msg := 'OK';
   prm_errmsg := 'OK';

   --Sn generate savepoint number
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

   --En generate savepoint number
   SAVEPOINT v_savepoint;

   --Sn find hsm mode
   BEGIN
      SELECT cip_param_value
        INTO v_hsm_mode
        FROM CMS_INST_PARAM
       WHERE cip_param_key = 'HSM_MODE';

      IF v_hsm_mode = 'Y'
      THEN
         v_pingen_flag := 'Y';                           -- i.e. generate pin
         v_emboss_flag := 'Y';
   --v_caf_gen_flag   := 'N';               -- i.e. generate embossa file.
      ELSE
         v_pingen_flag := 'N';                     -- i.e. don't generate pin
         v_emboss_flag := 'N';
   -- v_caf_gen_flag   := 'Y';         -- i.e. don't generate embossa file.
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_hsm_mode := 'N';
         v_pingen_flag := 'N';                     -- i.e. don't generate pin
         v_emboss_flag := 'N';           -- i.e. don't generate embossa file.
    --v_caf_gen_flag   := 'Y';
   END;

   --En find hsm mode
   --Sn fetch all details from appl_mast
   BEGIN                                           --Begin 1 Block Starts Here
      SELECT cam_inst_code, cam_asso_code, cam_inst_type, cam_prod_code,
             cam_appl_bran, cam_cust_code, cam_card_type, cam_cust_catg,
             cam_disp_name, cam_active_date, cam_expry_date, cam_addon_stat,
             cam_tot_acct, cam_chnl_code, cam_limit_amt, cam_use_limit,
             cam_bill_addr, cam_request_id, cam_appl_stat,
             cam_initial_topup_amount
        INTO v_inst_code, v_asso_code, v_inst_type, v_prod_code,
             v_appl_bran, v_cust_code, v_card_type, v_cust_catg,
             v_disp_name, v_active_date, v_expry_date, v_addon_stat,
             v_tot_acct, v_chnl_code, v_limit_amt, v_use_limit,
             v_bill_addr, v_request_id, v_appl_stat,
             v_initial_topup_amount
        FROM CMS_APPL_MAST
       WHERE cam_appl_code = prm_applcode AND cam_appl_stat = 'A';
   EXCEPTION                                      --Exception of Begin 1 Block
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

             --En fetch all details from  appl_mast
   --Sn find the bin for the product code
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

   --En find the bin for the product code
             --Sn find profile code attached to cardtype
   BEGIN
      SELECT cpm_profile_code, cpm_catg_code, cpc_prod_prefix, cpc_profile_code
        INTO v_profile_code, v_cpm_catg_code, v_prod_prefix,v_cardtype_profile_code
        FROM CMS_PROD_CATTYPE, CMS_PROD_MAST
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

   --En find profile code attached to cardtype
   --Sn find pan construct details based on profile code
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

   --En find pan construct details based on profile code
      --Sn built the pan gen logic based on the value (except serial no)
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

   --En built the pan gen logic based on the value
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

   --Sn generate the serial no
   FOR i IN 1 .. v_loop_max_cnt
   LOOP                                                         --<< i loop >>
      FOR j IN 1 .. v_loop_max_cnt
      LOOP                                                    --<< j  loop >>
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
      END LOOP;                                            --<< j  end loop >>
   END LOOP;                                                --<< i end loop >>

   --Sn get  index value of serial no from PL/SQL table
   FOR i IN 1 .. v_table_pan_construct.COUNT
   LOOP
      IF v_table_pan_construct (i).cpc_field_name = 'Serial Number'
      THEN
         v_serial_index := i;
      END IF;
   END LOOP;

   --En get  index value of serial no from PL/SQL table
   IF v_serial_index IS NOT NULL
   THEN
      v_serial_maxlength := v_table_pan_construct (v_serial_index).cpc_length;
      DBMS_OUTPUT.put_line ('SERIAL MAX LENGTH ' || v_serial_maxlength);
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
      DBMS_OUTPUT.put_line
                        (   'SERIAL NO '
                         || v_table_pan_construct (v_serial_index).cpc_field_value
                        );
   END IF;

   --En generate the serial no
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

   --Sn generate temp pan for check digit
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

   --En generate temp pan for check digit
   DBMS_OUTPUT.put_line (v_tmp_pan);
   --Sn generate for check digit
   lp_pan_chkdig (v_tmp_pan, v_check_digit);
   v_pan := v_tmp_pan || v_check_digit;
   DBMS_OUTPUT.put_line (v_pan);

   --En generate for check digit

   -- Sn find primary acct no for the pan
   BEGIN
      SELECT cam_acct_id, cam_acct_no
        INTO v_acct_id, v_acct_num
        FROM CMS_ACCT_MAST
       WHERE cam_inst_code = prm_instcode
         AND cam_acct_id =
                   (SELECT cad_acct_id
                      FROM CMS_APPL_DET
                     WHERE cad_appl_code = prm_applcode AND cad_acct_posn = 1);
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

   --En find primary acct no for the pan

   --Sn entry for addon stat
   IF v_addon_stat = 'A'
   THEN
      BEGIN                                                       --begin 1.1
         SELECT cam_addon_link
           INTO v_cam_addon_link
           FROM CMS_APPL_MAST
          WHERE cam_appl_code = prm_applcode;

         SELECT cap_pan_code, cap_mbr_numb
           INTO v_adonlink, v_mbrlink
           FROM CMS_APPL_PAN
          WHERE cap_appl_code = v_cam_addon_link;
      EXCEPTION                                                     --excp 1.1
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Parent PAN not generated for ' || prm_applcode;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg := 'Excp1.1 -- ' || SQLERRM;
            RAISE exp_reject_record;
      END;                                                  --end of begin 1.1
   ELSIF v_addon_stat = 'P'
   THEN
      v_adonlink := v_pan;
      v_mbrlink := '000';
   END IF;

   --En entry for addon stat


   --Sn find card status and limit parameter for the profile
   BEGIN
      SELECT cbp_param_value
        INTO v_card_stat
        FROM CMS_BIN_PARAM
       WHERE cbp_profile_code = v_cardtype_profile_code AND cbp_param_name = 'Status';

      IF v_card_stat IS NULL
      THEN
         v_errmsg := 'Status is null for profile code ' || v_profile_code;
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION

      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND THEN
  BEGIN
  SELECT  cbp_param_value
  INTO v_card_stat
  FROM CMS_BIN_PARAM
  WHERE   cbp_profile_code = v_profile_code AND cbp_param_name = 'Status';

  IF v_card_stat IS NULL
        THEN
  v_errmsg := 'Status is null for profile code ' || v_profile_code;
  RAISE NO_DATA_FOUND;
  END IF;


  EXCEPTION
  WHEN NO_DATA_FOUND
   THEN
    v_errmsg :=
    'Status is not defined for either product or product type profile code '  ;
    RAISE exp_reject_record;
   WHEN OTHERS THEN
   v_errmsg := 'Error while selecting carad status data ' || substr(sqlerrm,1,200);
   RAISE exp_reject_record;
        END;
        WHEN OTHERS
        THEN
    v_errmsg :=
        'Error while selecting card status for product profile ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;

   --En find card status and limit parameter for the profile

   --Sn atm off  line limit
   BEGIN
      SELECT cbp_param_value
        INTO v_offline_atm_limit
        FROM CMS_BIN_PARAM
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Offline ATM Limit';

      IF v_offline_atm_limit IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      BEGIN
 SELECT cbp_param_value
        INTO   v_offline_atm_limit
        FROM   CMS_BIN_PARAM
        WHERE  cbp_profile_code =  v_profile_code
        AND    cbp_param_name   = 'Offline ATM Limit';

      EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
       v_offline_atm_limit := 0;
       WHEN OTHERS THEN
       v_errmsg := 'Error while selecting cffline limit data ' || substr(sqlerrm,1,200);
       RAISE exp_reject_record;
      END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting offline ATM limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En atm off  line limit
    --Sn atm on  line limit
   BEGIN
      SELECT cbp_param_value
        INTO v_online_atm_limit
        FROM CMS_BIN_PARAM
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Online ATM Limit';

      IF v_online_atm_limit IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
       BEGIN
 SELECT cbp_param_value
        INTO   v_online_atm_limit
        FROM   CMS_BIN_PARAM
        WHERE  cbp_profile_code =  v_profile_code
        AND    cbp_param_name   = 'Online ATM Limit';

      EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
       v_online_atm_limit := 0;
       WHEN OTHERS THEN
       v_errmsg := 'Error while selecting cnline ATM limit data ' || substr(sqlerrm,1,200);
       RAISE exp_reject_record;
      END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting online ATM limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En atm on  line limit
    --Sn pos  on  line limit
   BEGIN
      SELECT cbp_param_value
        INTO v_online_pos_limit
        FROM CMS_BIN_PARAM
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Online POS Limit';

      IF v_online_pos_limit IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
  BEGIN
  SELECT cbp_param_value
  INTO   v_online_pos_limit
  FROM   CMS_BIN_PARAM
  WHERE  cbp_profile_code =  v_profile_code
  AND    cbp_param_name   = 'Online POS Limit';

       EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
        v_online_pos_limit := 0;
        WHEN OTHERS THEN
        v_errmsg := 'Error while selecting cnline pos limit data ' || substr(sqlerrm,1,200);
        RAISE exp_reject_record;
       END;
      WHEN OTHERS
      THEN
   v_errmsg :=
         'Error while selecting online POS limit '
      || SUBSTR (SQLERRM, 1, 200);
   RAISE exp_reject_record;
   END;

   --En pos on  line limit

   --Sn pos off  line limit
   BEGIN
      SELECT cbp_param_value
        INTO v_offline_pos_limit
        FROM CMS_BIN_PARAM
       WHERE cbp_profile_code = v_cardtype_profile_code
         AND cbp_param_name = 'Offline POS Limit';

      IF v_offline_pos_limit IS NULL
      THEN
         RAISE NO_DATA_FOUND;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
  SELECT cbp_param_value
  INTO   v_offline_pos_limit
  FROM   CMS_BIN_PARAM
  WHERE  cbp_profile_code =  v_profile_code
  AND    cbp_param_name   = 'Offline POS Limit';

       EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
        v_offline_pos_limit := 0;
        WHEN OTHERS THEN
        v_errmsg := 'Error while selecting cffline pos limit data ' || substr(sqlerrm,1,200);
        RAISE exp_reject_record;
       END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting offline POS limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En pos  off  line limit
   v_offline_aggr_limit := v_offline_pos_limit + v_offline_pos_limit;
   v_online_aggr_limit := v_online_atm_limit + v_online_pos_limit;

   --Sn get validity from profile
   BEGIN
        SELECT cbp_param_value
        INTO   v_expryparam
        FROM   CMS_BIN_PARAM
        WHERE  cbp_profile_code = v_cardtype_profile_code 
 AND    cbp_param_name = 'Validity';

 IF v_expryparam IS NULL THEN

 RAISE NO_DATA_FOUND;

 END IF;

      v_expry_date := LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1));

   EXCEPTION

      WHEN NO_DATA_FOUND THEN
      BEGIN
 SELECT cbp_param_value
        INTO v_expryparam
        FROM CMS_BIN_PARAM
       WHERE cbp_profile_code = v_profile_code AND cbp_param_name = 'Validity';

 IF v_expryparam IS NULL THEN

  RAISE NO_DATA_FOUND;

 END IF;

 v_expry_date := LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1));
      EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
         v_errmsg := 'No validity data found either product/product type profile '  ;
         RAISE exp_reject_record;
       WHEN OTHERS THEN
        v_errmsg := 'Error while selecting cffline pos limit data ' || substr(sqlerrm,1,200);
        RAISE exp_reject_record;
      END;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting offline POS limit '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En get validity from profile
   IF v_request_id IS NOT NULL
   THEN
      v_issueflag := 'N';
   ELSE
      v_issueflag := 'Y';
   END IF;

   -- If card is corporate then we need emp id  and corp id from cust_mast.
   BEGIN
      SELECT ccm_emp_id, ccm_corp_code
        INTO v_emp_id, v_corp_code
        FROM CMS_CUST_MAST
       WHERE ccm_inst_code = prm_instcode AND ccm_cust_code = v_cust_code;
   END;

   --Sn create a record in appl_pan
   BEGIN
      INSERT INTO CMS_APPL_PAN
                  (cap_appl_code, cap_inst_code, cap_asso_code,
                   cap_inst_type, cap_prod_code, cap_prod_catg,
                   cap_card_type, cap_cust_catg, cap_pan_code, cap_mbr_numb,
                   cap_card_stat, cap_cust_code, cap_disp_name,
                   cap_limit_amt, cap_use_limit, cap_appl_bran,
                   cap_active_date, cap_expry_date, cap_addon_stat,
                   cap_addon_link, cap_mbr_link, cap_acct_id, cap_acct_no,
                   cap_tot_acct, cap_bill_addr, cap_chnl_code,
                   cap_pangen_date, cap_pangen_user, cap_cafgen_flag,
                   cap_pin_flag, cap_embos_flag, cap_phy_embos,
                   cap_join_feecalc, cap_next_bill_date, --added on 11/10/2002
                                                        cap_request_id,
                   cap_issue_flag, cap_ins_user, cap_lupd_user,
                   cap_atm_offline_limit, cap_atm_online_limit,
                   cap_pos_offline_limit, cap_pos_online_limit,
                   cap_offline_aggr_limit, cap_online_aggr_limit,
                   cap_emp_id, cap_firsttime_topup
                  )
           VALUES (prm_applcode, prm_instcode, v_asso_code,
                   v_inst_type, v_prod_code, v_cpm_catg_code,
                   v_card_type, v_cust_catg, v_pan, '000',
                   v_card_stat, v_cust_code, v_disp_name,
                   v_limit_amt, v_use_limit, v_appl_bran,
                   v_active_date, v_expry_date, v_addon_stat,
                   v_adonlink, v_mbrlink, v_acct_id, v_acct_num,
                   v_tot_acct, v_bill_addr, v_chnl_code,
                   SYSDATE, prm_lupduser, v_caf_gen_flag,
                   v_pingen_flag,                                  -- PIN FLAG
                                 v_emboss_flag,                 -- EMBOSS FLAG
                                               'N',
                   'N', SYSDATE, v_request_id,
                   v_issueflag, prm_lupduser, prm_lupduser,
                   v_offline_atm_limit, v_online_atm_limit,
                   v_offline_pos_limit, v_online_pos_limit,
                   v_offline_aggr_limit, v_online_aggr_limit,
                   v_emp_id, NULL
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

   --En create a record in appl_pan

   --Sn create record in pan_acct
   FOR x IN c1 (prm_applcode)
   LOOP
      BEGIN
         INSERT INTO CMS_PAN_ACCT
                     (cpa_inst_code, cpa_cust_code, cpa_acct_id,
                      cpa_acct_posn, cpa_pan_code, cpa_mbr_numb,
                      cpa_ins_user, cpa_lupd_user
                     )
              VALUES (prm_instcode, v_cust_code, x.cad_acct_id,
                      x.cad_acct_posn, v_pan, '000',
                      prm_lupduser, prm_lupduser
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

   --En create record in pan_acct

   --Sn update acct_mast for  pan
   BEGIN
      UPDATE CMS_ACCT_MAST
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

   --En update acct_mast for pan

   --Sn Caf Refresh
   IF v_errmsg = 'OK'
   THEN
      BEGIN
         Sp_Caf_Rfrsh (prm_instcode,
                       v_pan,
                       NULL,
                       SYSDATE,
                       'A',
                       NULL,
                       'NEW',
                       prm_lupduser,
                       v_errmsg
                      );

         IF v_errmsg != 'OK'
         THEN
            v_errmsg := 'From caf refresh -- ' || v_errmsg;
            RAISE exp_reject_record;
         ELSIF v_errmsg = 'OK'
         THEN
            UPDATE CMS_CAF_INFO
               SET cci_pin_ofst = LPAD (' ', 16, ' ')
             WHERE cci_inst_code = prm_instcode
               AND cci_pan_code = DECODE(LENGTH(V_PAN), 16,V_PAN || '   ',
                      19,V_PAN)
               AND cci_mbr_numb = '000';

            IF SQL%ROWCOUNT != 1
            THEN
               v_errmsg := 'Problem in updation of pin as blank in cafinfio';
               RAISE exp_reject_record;
            END IF;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
           -- v_errmsg := 'Excp  for pin updation in SP_GEN_PAN-- ' || SQLERRM;
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg := 'Excp  for pin updation in SP_GEN_PAN-- ' || SQLERRM;
      END;
   END IF;

     --Sn caf referesh
   --Sn update flag in appl_mast
   BEGIN
      UPDATE CMS_APPL_MAST
         SET cam_appl_stat = 'O',
             cam_lupd_user = prm_lupduser,
             cam_process_msg = 'SUCCESSFUL'
       WHERE cam_appl_code = prm_applcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating records in appl mast  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En update flag in appl_mast
   prm_errmsg := 'OK';
   prm_applprocess_msg := 'OK';
EXCEPTION                                               --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      ROLLBACK TO v_savepoint;
      prm_errmsg := v_errmsg;

      UPDATE CMS_APPL_MAST
         SET cam_appl_stat = 'E',
             cam_process_msg = v_errmsg,
             cam_lupd_user = prm_lupduser
       WHERE cam_appl_code = prm_applcode;

      prm_applprocess_msg := v_errmsg;
      prm_errmsg := 'OK';
   WHEN OTHERS
   THEN
      ROLLBACK TO v_savepoint;
      -- prm_errmsg := 'Error while processing application for pan gen ' || SUBSTR(SQLERRM,1,200);
      prm_applprocess_msg :=
            'Error while processing application for pan gen '
         || SUBSTR (SQLERRM, 1, 200);
      v_errmsg :=
            'Error while processing application for pan gen '
         || SUBSTR (SQLERRM, 1, 200);

      UPDATE CMS_APPL_MAST
         SET cam_appl_stat = 'E',
             cam_process_msg = v_errmsg,
             cam_lupd_user = prm_lupduser
       WHERE cam_appl_code = prm_applcode;

      prm_errmsg := 'OK';
END;                                                           --<< MAIN END>>
/


