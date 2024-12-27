CREATE OR REPLACE PROCEDURE vmscms.sp_update_gl_cmsauth (
   prm_inst_code                NUMBER,
   prm_ins_date                 DATE,
   prm_acct_no                  VARCHAR2,
   prm_card_no                  VARCHAR2,
   prm_txn_amount               NUMBER,
   prm_txn_code                 VARCHAR2,
   prm_tran_type                VARCHAR2,
   prm_rvsl_code                NUMBER,
   prm_msg_typ                  VARCHAR2,
   prm_delivery_channel         VARCHAR2,
   prm_gl_upd_flag        OUT   VARCHAR2,
   prm_err_msg            OUT   VARCHAR2
)
IS
   v_gl_code           cms_gl_acct_mast.cga_gl_code%TYPE;
   v_subgl_code        cms_gl_acct_mast.cga_subgl_code%TYPE;
   v_gl_curr_code      cms_gl_mast.cgm_curr_code%TYPE;
   v_gl_desc           cms_gl_mast.cgm_gl_desc%TYPE;
   v_sub_gl_desc       cms_sub_gl_mast.csm_subgl_desc%TYPE;
   v_err_msg           VARCHAR2 (500);
   v_gl_err_msg        VARCHAR2 (500);
   v_float_flag        cms_gl_mast.cgm_float_flag%TYPE;
   v_card_curr         VARCHAR2 (3);
   v_check_applpan     NUMBER (1);
   exp_reject_record   EXCEPTION;
   v_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
BEGIN
   prm_err_msg := 'OK';

   BEGIN
      v_hash_pan := gethash (prm_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cga_gl_code, cga_subgl_code
        INTO v_gl_code, v_subgl_code
        FROM cms_gl_acct_mast
       WHERE cga_acct_code = prm_acct_no;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_msg := 'Account is not related to any GL ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         prm_err_msg :=
              'Error while selecting GL entries ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cgm_gl_desc, TRIM (cgm_curr_code), cgm_float_flag
        INTO v_gl_desc, v_gl_curr_code, v_float_flag
        FROM cms_gl_mast
       WHERE cgm_gl_code = v_gl_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_msg := 'GL desc is not available ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         prm_err_msg :=
                 'Error while selecting GL desc ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT csm_subgl_desc
        INTO v_sub_gl_desc
        FROM cms_sub_gl_mast
       WHERE csm_gl_code = v_gl_code AND csm_subgl_code = v_subgl_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_err_msg := 'GL desc is not available ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         prm_err_msg :=
                 'Error while selecting GL desc ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT TRIM (cbp_param_value)
        INTO v_card_curr
        FROM cms_bin_param
       WHERE cbp_param_name = 'Currency'
         AND (cbp_inst_code, cbp_profile_code) IN (
                SELECT cpm_inst_code, cpm_profile_code
                  FROM cms_appl_pan, cms_prod_mast
                 WHERE cpm_inst_code = cap_inst_code
                   AND cap_prod_code = cpm_prod_code
                   AND cap_pan_code = v_hash_pan);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         IF prm_card_no <> prm_acct_no
         THEN
            BEGIN
               SELECT 1
                 INTO v_check_applpan
                 FROM cms_appl_pan
                WHERE cap_pan_code = prm_acct_no;

               prm_err_msg :=
                        'Currency is not defined for the acct ' || prm_acct_no;
               RAISE exp_reject_record;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_card_curr := v_gl_curr_code;
               WHEN OTHERS
               THEN
                  prm_err_msg :=
                        'Error while selecting curr code for acct '
                     || prm_acct_no;
                  RAISE exp_reject_record;
            END;
         ELSE
            prm_err_msg :=
                       'Currency is not defined for the card ' || prm_acct_no;
            RAISE exp_reject_record;
         END IF;
      WHEN OTHERS
      THEN
         prm_err_msg :=
                    'Error while selecting currency for card ' || prm_acct_no;
         RAISE exp_reject_record;
   END;

   IF v_card_curr <> v_gl_curr_code
   THEN
      prm_err_msg := 'Both card and Gl currencies are not same ';
      RAISE exp_reject_record;
   END IF;

   IF prm_err_msg = 'OK'
   THEN
      sp_populate_float_data_cmsauth (prm_inst_code,
                                      v_gl_curr_code,
                                      v_gl_code,
                                      v_gl_desc,
                                      v_subgl_code,
                                      v_sub_gl_desc,
                                      v_float_flag,
                                      prm_tran_type,
                                      prm_ins_date,
                                      prm_txn_amount,
                                      prm_txn_code,
                                      prm_rvsl_code,
                                      prm_msg_typ,
                                      prm_delivery_channel,
                                      v_err_msg
                                     );
   END IF;

   IF v_err_msg <> 'OK'
   THEN
      prm_err_msg := v_err_msg;
      RAISE exp_reject_record;
   END IF;

   prm_gl_upd_flag := 'Y';
EXCEPTION
   WHEN exp_reject_record
   THEN
      prm_gl_upd_flag := 'N';
      sp_create_gl_errorlog (prm_acct_no,
                             prm_err_msg,
                             prm_ins_date,
                             prm_inst_code,
                             v_gl_err_msg
                            );
   WHEN OTHERS
   THEN
      prm_gl_upd_flag := 'N';
      prm_err_msg := SUBSTR (SQLERRM, 1, 300);
      sp_create_gl_errorlog (prm_acct_no,
                             prm_err_msg,
                             prm_ins_date,
                             prm_inst_code,
                             v_gl_err_msg
                            );
END;
/

SHOW ERROR