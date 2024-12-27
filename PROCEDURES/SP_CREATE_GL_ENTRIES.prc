CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Gl_Entries (
   prm_inst_code            NUMBER,
   prm_tran_date            DATE,
   prm_prod_code            VARCHAR2,
   prm_prod_cattype         VARCHAR2,
   prm_tran_amt             NUMBER,
   prm_func_code            VARCHAR2,
   prm_txn_code             VARCHAR2,
   prm_tran_type            VARCHAR2,
   prm_card_no              VARCHAR2,
   prm_fee_code			VARCHAR2,
   prm_fee_amt				NUMBER,
  prm_fee_cracct_no VARCHAR2,
  prm_fee_dracct_no VARCHAR2,
  PRM_LUPD_USER NUMBER,
   prm_resp_cde       OUT   VARCHAR2,
   prm_gl_upd_flag    OUT   VARCHAR2,
   prm_err_msg        OUT   VARCHAR2
)
IS
   v_cr_gl_code         CMS_FUNC_PROD.cfp_crgl_code%TYPE;
   v_crgl_catg          CMS_FUNC_PROD.cfp_crgl_catg%TYPE;
   v_crsubgl_code       CMS_FUNC_PROD.cfp_crsubgl_code%TYPE;
   v_cracct_no          CMS_FUNC_PROD.cfp_cracct_no%TYPE;
   v_dr_gl_code         CMS_FUNC_PROD.cfp_drgl_code%TYPE;
   v_drgl_catg          CMS_FUNC_PROD.cfp_drgl_catg%TYPE;
   v_drsubgl_code       CMS_FUNC_PROD.cfp_drsubgl_code%TYPE;
   v_dracct_no          CMS_FUNC_PROD.cfp_dracct_no%TYPE;
   v_fee_cr_gl_code     CMS_PRODCATTYPE_FEES.cpf_crgl_code%TYPE;
   v_fee_crgl_catg      CMS_PRODCATTYPE_FEES.cpf_crgl_catg%TYPE;
   v_fee_crsubgl_code   CMS_PRODCATTYPE_FEES.cpf_crsubgl_code%TYPE;
   v_fee_cracct_no      CMS_PRODCATTYPE_FEES.cpf_cracct_no%TYPE;
   v_fee_dr_gl_code     CMS_PRODCATTYPE_FEES.cpf_drgl_code%TYPE;
   v_fee_drgl_catg      CMS_PRODCATTYPE_FEES.cpf_drgl_catg%TYPE;
   v_fee_drsubgl_code   CMS_PRODCATTYPE_FEES.cpf_drsubgl_code%TYPE;
   v_fee_dracct_no      CMS_PRODCATTYPE_FEES.cpf_dracct_no%TYPE;
   v_gl_errmsg          VARCHAR2 (500);
   v_gl_upd_flag        TRANSACTIONLOG.gl_upd_flag%TYPE;
   exp_reject_record											EXCEPTION;

   /*CURSOR c
   IS
      SELECT cfm_fee_code fee_code, cfm_fee_amt fee_amt, cpf_crgl_code,
             cpf_crgl_catg, cpf_crsubgl_code, cpf_cracct_no, cpf_drgl_code,
             cpf_drgl_catg, cpf_drsubgl_code, cpf_dracct_no
        FROM CMS_FEE_MAST, CMS_PRODCATTYPE_FEES
       WHERE cpf_func_code = prm_func_code
         AND cpf_prod_code = prm_prod_code
         AND cpf_card_type = prm_prod_cattype
         AND cfm_inst_code = cpf_inst_code
         AND cfm_fee_code = cpf_fee_code; */

BEGIN
   prm_resp_cde := '1';
   prm_err_msg := 'OK';
  prm_gl_upd_flag  := 'Y';
   --Sn find tran type and update the concern acct for transaction amount
             --SN select gl entries
 IF prm_tran_type IN ('CR', 'DR') THEN
   BEGIN
      SELECT cfp_crgl_code, cfp_crgl_catg, cfp_crsubgl_code, cfp_cracct_no,
             cfp_drgl_code, cfp_drgl_catg, cfp_drsubgl_code, cfp_dracct_no
        INTO v_cr_gl_code, v_crgl_catg, v_crsubgl_code, v_cracct_no,
             v_dr_gl_code, v_drgl_catg, v_drsubgl_code, v_dracct_no
        FROM CMS_FUNC_PROD
       WHERE CFP_INST_CODE =prm_inst_code AND  cfp_func_code = prm_func_code
         AND cfp_prod_code = prm_prod_code
         AND cfp_prod_cattype = prm_prod_cattype;

      IF TRIM (v_cracct_no) IS NULL AND TRIM (v_dracct_no) IS NULL
      THEN
         prm_resp_cde := '99';
         prm_err_msg :=
               'Both credit and debit account cannot be null for a transaction code '
            || prm_txn_code
            || ' Function code '
            || prm_func_code;
			prm_gl_upd_flag := 'N';
         RETURN;
      END IF;

      IF TRIM (v_cracct_no) IS NULL
      THEN
         v_cracct_no := prm_card_no;
      END IF;

      IF TRIM (v_dracct_no) IS NULL
      THEN
         v_dracct_no := prm_card_no;
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

   --En select gl entries

      --SN CREDIT THE CONCERN ACCOUNT
      BEGIN
         --- Sn create gl entries
         Sp_Update_Gl (prm_inst_code,
                       prm_tran_date,
                       v_cracct_no,
					   prm_card_no,
					   prm_tran_amt    ,
					   prm_txn_code  ,
					   'CR',
					   PRM_LUPD_USER,
                       v_gl_upd_flag,
                       v_gl_errmsg
                      );

         IF v_gl_errmsg = 'OK'
         THEN
		 NULL;
		 ELSE
            v_gl_upd_flag := 'N';
            prm_gl_upd_flag := v_gl_upd_flag;
            prm_resp_cde := '21';
            prm_err_msg := v_gl_errmsg;
            RETURN;
         END IF;
      --En create gl entries
      END;

          --EN CREDIT THE CONCERN ACCOUNT
      --SN DEBIT THE  CONCERN ACCOUNT
      BEGIN
         --- Sn create gl entries
         Sp_Update_Gl (prm_inst_code,
                       prm_tran_date,
					   v_dracct_no,
					   prm_card_no,
					    prm_tran_amt    ,
					   prm_txn_code  ,
					    'DR',
						PRM_LUPD_USER,
                       v_gl_upd_flag,
                       v_gl_errmsg
                      );

         IF v_gl_errmsg <> 'OK'
         THEN
            v_gl_upd_flag := 'N';
            prm_gl_upd_flag := v_gl_upd_flag;
            prm_resp_cde := '21';
            prm_err_msg := v_gl_errmsg;
            RETURN;
         END IF;
      --En create gl entries
      END;
   --EN DEBIT THE  CONCERN ACCOUNT
   END IF;

   --En find tran type and update the concern acct for transaction amount
   --FOR i IN c
   --LOOP

  IF  prm_fee_amt		 <> 0 THEN

      BEGIN                                                --<< FEE  begin >>
         v_fee_cracct_no := prm_fee_cracct_no;
         v_fee_dracct_no := prm_fee_dracct_no;

         IF TRIM (v_fee_cracct_no) IS NULL AND TRIM (v_fee_dracct_no) IS NULL
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

         IF TRIM (v_fee_cracct_no) IS NULL
         THEN
            v_fee_cracct_no := prm_card_no;
         END IF;

         IF TRIM (v_fee_dracct_no) IS NULL
         THEN
            v_fee_dracct_no := prm_card_no;
         END IF;

         --SN DEBIT THE  CONCERN FEE  ACCOUNT
         BEGIN
            Sp_Update_Gl (prm_inst_code,
                          prm_tran_date,
                          v_fee_dracct_no,
						  prm_card_no,
						  prm_fee_amt  ,
					      '11'  ,
						  'DR',
						  PRM_LUPD_USER,
                          v_gl_upd_flag,
                          v_gl_errmsg
                         );

            IF v_gl_errmsg <> 'OK'
            THEN
               v_gl_upd_flag := 'N';
               prm_gl_upd_flag := v_gl_upd_flag;
               prm_resp_cde := '21';
               prm_err_msg := v_gl_errmsg;
               RETURN;
            END IF;
         END;

         --EN DEBIT THE  CONCERN FEE  ACCOUNT
         --SN CREDIT THE CONCERN FEE ACCOUNT
         BEGIN
            Sp_Update_Gl (prm_inst_code,
                          prm_tran_date,
                          v_fee_cracct_no,
						   prm_card_no,
						   prm_fee_amt   ,
					       '11'  ,
						   'CR',
						   PRM_LUPD_USER,
                          v_gl_upd_flag,
                          v_gl_errmsg
                         );

            IF v_gl_errmsg <> 'OK'
            THEN
               v_gl_upd_flag := 'N';
               prm_gl_upd_flag := v_gl_upd_flag;
               prm_resp_cde := '21';
               prm_err_msg := v_gl_errmsg;
               RETURN;
            END IF;
         END;
      --EN CREDIT THE CONCERN FEE ACCOUNT
      EXCEPTION                                         --<< FEE exception >>
         WHEN OTHERS
         THEN
            prm_resp_cde := '21';
            prm_err_msg := 'Problem while processing fee for transaction ';
			prm_gl_upd_flag := 'N';
			RETURN;
      END;                                                    --<< FEE end >>

	  END IF;
   --END LOOP;
--En check any fees attached if so credit or debit the acct
EXCEPTION
   WHEN OTHERS
   THEN
      prm_resp_cde := '21';
      prm_err_msg := 'Error main ' || 'Problem while processing amount ';
	  prm_gl_upd_flag := 'N';
END;
/


