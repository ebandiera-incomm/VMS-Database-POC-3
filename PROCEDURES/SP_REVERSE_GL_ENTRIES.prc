CREATE OR REPLACE PROCEDURE vmscms.sp_reverse_gl_entries (
   prm_inst_code             NUMBER,
   prm_tran_date             DATE,
   prm_prod_code             VARCHAR2,
   prm_prod_cattype          VARCHAR2,
   prm_tran_amt              NUMBER,
   prm_func_code             VARCHAR2,
   prm_txn_code              VARCHAR2,
   prm_tran_type             VARCHAR2,
   prm_card_no               VARCHAR2,
   prm_fee_code              VARCHAR2,
   prm_fee_amt               NUMBER,
   prm_fee_cracct_no         VARCHAR2,
   prm_fee_dracct_no         VARCHAR2,
   prm_card_acct_no          NUMBER,
   prm_rvsl_code             NUMBER,
   prm_msg_typ               VARCHAR2,
   prm_delv_chnl             VARCHAR2,
   prm_resp_cde        OUT   VARCHAR2,
   prm_gl_upd_flag     OUT   VARCHAR2,
   prm_err_msg         OUT   VARCHAR2
)
IS
   v_orgnl_cr_gl_code         cms_func_prod.cfp_crgl_code%TYPE;
   v_orgnl_crgl_catg          cms_func_prod.cfp_crgl_catg%TYPE;
   v_orgnl_crsubgl_code       cms_func_prod.cfp_crsubgl_code%TYPE;
   v_orgnl_cracct_no          cms_func_prod.cfp_cracct_no%TYPE;
   v_rvsl_cracct_no           cms_func_prod.cfp_cracct_no%TYPE;
   v_orgnl_dr_gl_code         cms_func_prod.cfp_drgl_code%TYPE;
   v_orgnl_drgl_catg          cms_func_prod.cfp_drgl_catg%TYPE;
   v_orgnl_drsubgl_code       cms_func_prod.cfp_drsubgl_code%TYPE;
   v_orgnl_dracct_no          cms_func_prod.cfp_dracct_no%TYPE;
   v_rvsl_dracct_no           cms_func_prod.cfp_cracct_no%TYPE;
   v_fee_orgnl_cr_gl_code     cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_fee_orgnl_crgl_catg      cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_fee_orgnl_crsubgl_code   cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_fee_orgnl_cracct_no      cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_orgnl_dr_gl_code     cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_fee_orgnl_drgl_catg      cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_fee_orgnl_drsubgl_code   cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_fee_orgnl_dracct_no      cms_prodcattype_fees.cpf_dracct_no%TYPE;
   v_fee_rvsl_cracct_no       cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_rvsl_dracct_no       cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_gl_errmsg                VARCHAR2 (500);
   v_gl_upd_flag              transactionlog.gl_upd_flag%TYPE;
   v_rvsl_tran_code           cms_transaction_mast.ctm_tran_code%TYPE;
   v_fee_rvsl_tran_code       cms_transaction_mast.ctm_tran_code%TYPE;
   exp_rvsl_reject_record     EXCEPTION;
   v_cracct_customer          VARCHAR2 (1);
   v_dracct_customer          VARCHAR2 (1);
BEGIN
   prm_resp_cde := '1';
   prm_err_msg := 'OK';
   prm_gl_upd_flag := 'Y';
   v_cracct_customer := 'N';
   v_dracct_customer := 'N';

   IF prm_tran_type IN ('CR', 'DR')
   THEN
      BEGIN
         SELECT cfp_crgl_code, cfp_crgl_catg, cfp_crsubgl_code,
                cfp_cracct_no, cfp_drgl_code, cfp_drgl_catg,
                cfp_drsubgl_code, cfp_dracct_no
           INTO v_orgnl_cr_gl_code, v_orgnl_crgl_catg, v_orgnl_crsubgl_code,
                v_orgnl_cracct_no, v_orgnl_dr_gl_code, v_orgnl_drgl_catg,
                v_orgnl_drsubgl_code, v_orgnl_dracct_no
           FROM cms_func_prod
          WHERE cfp_func_code = prm_func_code
            AND cfp_prod_code = prm_prod_code
            AND cfp_prod_cattype = prm_prod_cattype
            AND cfp_inst_code = prm_inst_code;

         IF TRIM (v_orgnl_cracct_no) IS NULL
            AND TRIM (v_orgnl_dracct_no) IS NULL
         THEN
            prm_resp_cde := '21';
            prm_err_msg :=
                  'Both credit and debit account cannot be null for a transaction code '
               || prm_txn_code
               || ' Function code '
               || prm_func_code;
            prm_gl_upd_flag := 'N';
            RETURN;
         END IF;

         IF TRIM (v_orgnl_cracct_no) IS NULL
         THEN
            v_orgnl_cracct_no := prm_card_acct_no;
         END IF;

         IF TRIM (v_orgnl_dracct_no) IS NULL
         THEN
            v_orgnl_dracct_no := prm_card_acct_no;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            prm_resp_cde := '21';
            prm_err_msg := 'DEBIT AND CREDIT GL not defined';
            prm_gl_upd_flag := 'N';
            RETURN;
         WHEN OTHERS
         THEN
            prm_resp_cde := '21';
            prm_err_msg := 'Problem while processing transaction amount';
            prm_gl_upd_flag := 'N';
            RETURN;
      END;

      v_rvsl_cracct_no := v_orgnl_dracct_no;
      v_rvsl_dracct_no := v_orgnl_cracct_no;

      IF v_rvsl_dracct_no = prm_card_acct_no
      THEN
         v_dracct_customer := 'Y';
      END IF;

      IF v_rvsl_cracct_no = prm_card_acct_no
      THEN
         v_cracct_customer := 'Y';
      END IF;

      BEGIN
         IF (v_cracct_customer = 'N')
         THEN
            sp_update_gl_cmsauth (prm_inst_code,
                                  prm_tran_date,
                                  v_rvsl_cracct_no,
                                  prm_card_no,
                                  prm_tran_amt,
                                  prm_txn_code,
                                  'CR',
                                  prm_rvsl_code,
                                  prm_msg_typ,
                                  prm_delv_chnl,
                                  v_gl_upd_flag,
                                  v_gl_errmsg
                                 );

            IF v_gl_errmsg = 'OK'
            THEN
               prm_gl_upd_flag := v_gl_upd_flag;
            ELSE
               v_gl_upd_flag := 'N';
               prm_gl_upd_flag := v_gl_upd_flag;
               prm_resp_cde := '21';
               prm_err_msg := v_gl_errmsg;
               RETURN;
            END IF;
         END IF;
      END;

      BEGIN
         IF (v_dracct_customer = 'N')
         THEN
            sp_update_gl_cmsauth (prm_inst_code,
                                  prm_tran_date,
                                  v_rvsl_dracct_no,
                                  prm_card_no,
                                  prm_tran_amt,
                                  prm_txn_code,
                                  'DR',
                                  prm_rvsl_code,
                                  prm_msg_typ,
                                  prm_delv_chnl,
                                  v_gl_upd_flag,
                                  v_gl_errmsg
                                 );

            IF v_gl_errmsg = 'OK'
            THEN
               prm_gl_upd_flag := v_gl_upd_flag;
            ELSE
               v_gl_upd_flag := 'N';
               prm_gl_upd_flag := v_gl_upd_flag;
               prm_resp_cde := '21';
               prm_err_msg := v_gl_errmsg;
               RETURN;
            END IF;
         END IF;
      END;
   END IF;

   v_cracct_customer := 'N';
   v_dracct_customer := 'N';

   IF prm_fee_amt <> 0
   THEN
      BEGIN
         v_fee_orgnl_cracct_no := prm_fee_cracct_no;
         v_fee_orgnl_dracct_no := prm_fee_dracct_no;

         IF     TRIM (v_fee_orgnl_cracct_no) IS NULL
            AND TRIM (v_fee_orgnl_dracct_no) IS NULL
         THEN
            prm_resp_cde := '21';
            prm_err_msg :=
                  'Both credit and debit account cannot be null for a fee '
               || prm_fee_code
               || ' Function code '
               || prm_func_code;
            prm_gl_upd_flag := 'N';
            RETURN;
         END IF;

         IF TRIM (v_fee_orgnl_cracct_no) IS NULL
         THEN
            v_fee_orgnl_cracct_no := prm_card_acct_no;
         END IF;

         IF TRIM (v_fee_orgnl_dracct_no) IS NULL
         THEN
            v_fee_orgnl_dracct_no := prm_card_acct_no;
         END IF;

         v_fee_rvsl_cracct_no := v_fee_orgnl_dracct_no;
         v_fee_rvsl_dracct_no := v_fee_orgnl_cracct_no;

         IF v_fee_rvsl_cracct_no = prm_card_acct_no
         THEN
            v_cracct_customer := 'Y';
         END IF;

         IF v_fee_rvsl_dracct_no = prm_card_acct_no
         THEN
            v_dracct_customer := 'Y';
         END IF;

         IF (v_cracct_customer = 'N')
         THEN
            sp_update_gl_cmsauth (prm_inst_code,
                                  prm_tran_date,
                                  v_fee_rvsl_cracct_no,
                                  prm_card_no,
                                  prm_fee_amt,
                                  prm_txn_code,
                                  'CR',
                                  prm_rvsl_code,
                                  prm_msg_typ,
                                  prm_delv_chnl,
                                  v_gl_upd_flag,
                                  v_gl_errmsg
                                 );

            IF v_gl_errmsg = 'OK'
            THEN
               prm_gl_upd_flag := v_gl_upd_flag;
            ELSE
               v_gl_upd_flag := 'N';
               prm_gl_upd_flag := v_gl_upd_flag;
               prm_resp_cde := '21';
               prm_err_msg := v_gl_errmsg;
               RETURN;
            END IF;
         END IF;

         IF (v_dracct_customer = 'N')
         THEN
            sp_update_gl_cmsauth (prm_inst_code,
                                  prm_tran_date,
                                  v_fee_rvsl_dracct_no,
                                  prm_card_no,
                                  prm_fee_amt,
                                  prm_txn_code,
                                  'DR',
                                  prm_rvsl_code,
                                  prm_msg_typ,
                                  prm_delv_chnl,
                                  v_gl_upd_flag,
                                  v_gl_errmsg
                                 );

            IF v_gl_errmsg = 'OK'
            THEN
               prm_gl_upd_flag := v_gl_upd_flag;
            ELSE
               v_gl_upd_flag := 'N';
               prm_gl_upd_flag := v_gl_upd_flag;
               prm_resp_cde := '21';
               prm_err_msg := v_gl_errmsg;
               RETURN;
            END IF;
         END IF;
      END;
   END IF;

   prm_resp_cde := '00';
   prm_gl_upd_flag := 'Y';
   prm_err_msg := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      prm_resp_cde := '21';
      prm_err_msg :=
               'Error main ' || 'Problem while processing amount ' || SQLERRM;
      prm_gl_upd_flag := 'N';
END;
/

SHOW ERROR