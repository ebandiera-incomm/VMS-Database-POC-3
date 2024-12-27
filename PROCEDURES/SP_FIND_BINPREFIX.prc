create or replace PROCEDURE        VMSCMS.sp_find_binprefix (
   p_instcode    IN       NUMBER,
   p_prod_code   IN       VARCHAR2,
   p_card_type            NUMBER,
   p_lupduser    IN       NUMBER,
   v_tmp_pan     OUT      VARCHAR2,
   p_errmsg      OUT      VARCHAR2
)
AS
   v_proxy_number            cms_appl_pan.cap_proxy_number%TYPE;
   v_inst_code               cms_appl_mast.cam_inst_code%TYPE;
   v_prod_code               cms_appl_mast.cam_prod_code%TYPE;
   v_card_type               cms_appl_mast.cam_card_type%TYPE;
   v_chnl_code               cms_appl_mast.cam_chnl_code%TYPE;
   v_bin                     cms_bin_mast.cbm_inst_bin%TYPE;
   v_profile_code            cms_prod_mast.cpm_profile_code%TYPE;
   v_cardtype_profile_code   cms_prod_cattype.cpc_profile_code%TYPE;
   v_errmsg                  VARCHAR2 (500);
   v_loop_cnt                NUMBER                                 DEFAULT 0;
   v_loop_max_cnt            NUMBER;
   v_ctrlnumb                NUMBER;
   v_max_serial_no           NUMBER;
   v_noof_pan_param          NUMBER;
   v_inst_bin                cms_prod_bin.cpb_inst_bin%TYPE;
   v_serial_index            NUMBER;
   v_serial_maxlength        NUMBER (2);
   v_serial_no               NUMBER;
   v_check_digit             NUMBER;
   v_pan                     cms_appl_pan.cap_pan_code%TYPE;
   v_appl_bran               cms_appl_mast.cam_appl_bran%TYPE:='0001';
   v_prod_prefix             cms_prod_cattype.cpc_prod_prefix%TYPE;
   v_card_stat               cms_appl_pan.cap_card_stat%TYPE;
   v_cpm_catg_code           cms_prod_mast.cpm_catg_code%TYPE;
   v_tran_code               cms_func_mast.cfm_txn_code%TYPE;
   v_tran_mode               cms_func_mast.cfm_txn_mode%TYPE;
   v_delv_chnl               cms_func_mast.cfm_delivery_channel%TYPE;
   v_tran_type               cms_func_mast.cfm_txn_type%TYPE;
   v_savepoint               NUMBER                                 DEFAULT 1;
   v_mbrnumb                 cms_appl_pan.cap_mbr_numb%TYPE;
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

   CURSOR c (v_profile_code IN VARCHAR2)
   IS
      SELECT   cpc_profile_code, cpc_field_name, cpc_start_from, cpc_length,
               cpc_start
          FROM cms_pan_construct
         WHERE cpc_profile_code = v_profile_code
               AND cpc_inst_code = p_instcode
      ORDER BY cpc_start_from DESC;

/*************************************************
     * Created Date       : 12/09/2012
     * Created By         : Dhiraj
     * PURPOSE            : 
     * Modified By:       : 
     * Modified Date      : 
     * Modified reason    : 
     * VERSION            : CMS3.5.1_RI0016_B0002
     * Reviewed by        : Saravanakumar
     * Reviewed Date      : 12/09/2012
   ***********************************************/
BEGIN
   BEGIN
      SELECT cpm_profile_code, cpm_catg_code, cpc_prod_prefix, cpc_serl_flag
        INTO v_profile_code, v_cpm_catg_code, v_prod_prefix, v_cpc_serl_flag
        FROM cms_prod_cattype, cms_prod_mast
       WHERE cpc_inst_code = p_instcode
         AND cpc_inst_code = cpm_inst_code
         AND cpc_prod_code = p_prod_code
         AND cpc_card_type = p_card_type
         AND cpm_prod_code = cpc_prod_code;
         
         DBMS_OUTPUT.PUT_LINE('Profile_Code -------'||v_profile_code) ;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
               'Profile code not defined for product code '
            || p_prod_code
            || 'card type '
            || p_card_type;
         RETURN;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting applcode from applmast'
            || SUBSTR (SQLERRM, 1, 300);
         RETURN;
   END;
   BEGIN 
    SELECT CPB_INST_BIN
     INTO V_BIN
     FROM CMS_PROD_BIN
    WHERE CPB_INST_CODE = P_INSTCODE AND CPB_PROD_CODE = P_PROD_CODE
          AND CPB_ACTIVE_BIN = 'Y';

   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     v_errmsg := 'Excp1 LP1 -- No prefix  found for combination of Institution ' ||
               P_INSTCODE || ' and product ' || P_PROD_CODE;
    WHEN OTHERS THEN
     v_errmsg := 'Excp1 LP1 -- ' || SQLERRM;
  END;
   
   
   IF v_prod_prefix IS NULL
   THEN
      BEGIN
         SELECT cip_param_value
           INTO v_prod_prefix
           FROM cms_inst_param
          WHERE cip_inst_code = p_instcode
            AND cip_param_key = 'PANPRODCATPREFIX';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting PAN Product Category Prefix from CMS_INST_PARAM '
               || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;
   END IF;

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
               'ERROR WHILE SELECTING PROFILE DETAIL FROM PROFILE MAST '
            || SUBSTR (SQLERRM, 1, 300);
         RETURN;
   END;

   BEGIN
      v_loop_max_cnt := v_table_pan_construct.COUNT;
      v_tmp_pan := NULL;

      FOR i IN 1 .. v_loop_max_cnt
      LOOP
         IF v_table_pan_construct (i).cpc_field_name = 'Card Type'
         THEN
            v_table_pan_construct (i).cpc_field_value :=
               LPAD (SUBSTR (TRIM (p_card_type),
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
                                                 'PAN Product Category Prefix'
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
               RETURN;
            END IF;
         END IF;
         
         DBMS_OUTPUT.PUT_LINE('RRRRRRRRRRRR-----'|| v_table_pan_construct (i).cpc_field_name  ||' Field VAlue --'|| v_table_pan_construct (i).cpc_field_value) ;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg := 'Error from pangen process ' || SUBSTR (SQLERRM, 1, 300);
         RETURN;
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
                       DBMS_OUTPUT.PUT_LINE('OOOOOOOOOO-----'|| v_tmp_pan ) ;
                       
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

   v_serial_maxlength := v_table_pan_construct (v_serial_index).cpc_length;

   IF v_serial_index IS NULL
   THEN
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
   END IF;
 DBMS_OUTPUT.PUT_LINE('BIN/PREFIX----444444-'|| V_TMP_PAN) ;
   BEGIN
      SELECT     cpc_ctrl_numb, cpc_max_serial_no
            INTO v_ctrlnumb, v_max_serial_no
            FROM cms_pan_ctrl
           WHERE cpc_pan_prefix = v_tmp_pan AND cpc_inst_code = p_instcode
      FOR UPDATE;

      IF v_ctrlnumb > LPAD ('9', v_serial_maxlength, 9)
      THEN
         p_errmsg := 'MAXIMUM SERIAL NUMBER REACHED';
         RETURN;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN;
      WHEN OTHERS
      THEN
         p_errmsg :=
                  'ERROR WHILE SELECTING RECORD FROM CMS_PAN_CTRL' || SQLERRM;
         RETURN;
   END;

   BEGIN
      INSERT INTO cms_serl_cntrl
                  (csc_inst_code, csc_prod_code, csc_prod_catg,
                   csc_totl_cnt, csc_serl_strt, csc_serl_end, csc_lupd_date,
                   csc_lupd_user, csc_ins_date, csc_ins_user
                  )
           VALUES (p_instcode, p_prod_code, p_card_type,
                   v_ctrlnumb - 1, 1, v_ctrlnumb - 1, SYSDATE,
                   p_lupduser, SYSDATE, p_lupduser
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
               'ERROR WHILE INSERTING RECORD INTO CMS_SERL_CNTRL ' || SQLERRM;
         RETURN;
   END;

   BEGIN
      UPDATE cms_prod_cattype
         SET cpc_serl_flag = 1
       WHERE cpc_inst_code = p_instcode
         AND cpc_prod_code = p_prod_code
         AND cpc_card_type = p_card_type;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
             'ERROR WHILE UPDATING  RECORD INTO CMS_PROD_CATTYPE ' || SQLERRM;
         RETURN;
   END;
END; 
/
show error;