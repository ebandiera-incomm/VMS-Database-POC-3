CREATE OR REPLACE PROCEDURE vmscms.sp_samecard_reissue (
   p_inst_code          IN       NUMBER,
   p_msg                IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_term_id            IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_card_no            IN       VARCHAR2,
   p_bank_code          IN       VARCHAR2,
   p_txn_amt            IN       NUMBER,
   p_mcc_code           IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_prod_id            IN       VARCHAR2,
   p_expry_date         IN       VARCHAR2,
   p_stan               IN       VARCHAR2,
   p_mbr_numb           IN       VARCHAR2,
   p_rvsl_code          IN       NUMBER,
   p_ipaddress          IN       VARCHAR2,
   p_ins_user           IN       NUMBER,
   p_merchant_name      IN       VARCHAR2,
   p_merchant_city      IN       VARCHAR2,
   p_consodium_code     IN       VARCHAR2,
   p_partner_code       IN       VARCHAR2,
   p_auth_id            OUT      VARCHAR2,
   p_resp_code          OUT      VARCHAR2,
   p_resp_msg           OUT      VARCHAR2,
   p_capture_date       OUT      DATE
)
IS
   v_acct_balance               NUMBER;
   v_ledger_bal                 NUMBER;
   v_tran_amt                   NUMBER;
   v_auth_id                    transactionlog.auth_id%TYPE;
   v_total_amt                  NUMBER;
   v_tran_date                  DATE;
   v_func_code                  cms_func_mast.cfm_func_code%TYPE;
   v_prod_code                  cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype               cms_prod_cattype.cpc_card_type%TYPE;
   v_fee_amt                    NUMBER;
   v_total_fee                  NUMBER;
   v_upd_amt                    NUMBER;
   v_upd_ledger_amt             NUMBER;
   v_narration                  VARCHAR2 (50);
   v_fee_opening_bal            NUMBER;
   v_resp_cde                   VARCHAR2 (5);
   v_expry_date                 DATE;
   v_dr_cr_flag                 VARCHAR2 (2);
   v_output_type                VARCHAR2 (2);
   v_applpan_cardstat           cms_appl_pan.cap_card_stat%TYPE;
   v_atmonline_limit            cms_appl_pan.cap_atm_online_limit%TYPE;
   v_posonline_limit            cms_appl_pan.cap_atm_offline_limit%TYPE;
   v_err_msg                    VARCHAR2 (500);
   v_precheck_flag              NUMBER;
   v_preauth_flag               NUMBER;
   v_avail_pan                  cms_avail_trans.cat_pan_code%TYPE;
   v_gl_upd_flag                transactionlog.gl_upd_flag%TYPE;
   v_gl_err_msg                 VARCHAR2 (500);
   v_savepoint                  NUMBER                                   := 0;
   v_tran_fee                   NUMBER;
   v_error                      VARCHAR2 (500);
   v_business_date_tran         DATE;
   v_business_time              VARCHAR2 (5);
   v_cutoff_time                VARCHAR2 (5);
   v_card_curr                  VARCHAR2 (5);
   v_fee_code                   cms_fee_mast.cfm_fee_code%TYPE;
   v_fee_crgl_catg              cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_fee_crgl_code              cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_fee_crsubgl_code           cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_fee_cracct_no              cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_drgl_catg              cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_fee_drgl_code              cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_fee_drsubgl_code           cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_fee_dracct_no              cms_prodcattype_fees.cpf_dracct_no%TYPE;
   v_servicetax_percent         cms_inst_param.cip_param_value%TYPE;
   v_cess_percent               cms_inst_param.cip_param_value%TYPE;
   v_servicetax_amount          NUMBER;
   v_cess_amount                NUMBER;
   v_st_calc_flag               cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_cess_calc_flag             cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_st_cracct_no               cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_st_dracct_no               cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_cess_cracct_no             cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_cess_dracct_no             cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   v_waiv_percnt                cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_err_waiv                   VARCHAR2 (300);
   v_log_actual_fee             NUMBER;
   v_log_waiver_amt             NUMBER;
   v_auth_savepoint             NUMBER                              DEFAULT 0;
   v_business_date              DATE;
   v_txn_type                   NUMBER (1);
   v_mini_totrec                NUMBER (2);
   v_ministmt_errmsg            VARCHAR2 (500);
   v_ministmt_output            VARCHAR2 (900);
   exp_reject_record            EXCEPTION;
   v_atm_usageamnt              cms_translimit_check.ctc_atmusage_amt%TYPE;
   v_pos_usageamnt              cms_translimit_check.ctc_posusage_amt%TYPE;
   v_atm_usagelimit             cms_translimit_check.ctc_atmusage_limit%TYPE;
   v_pos_usagelimit             cms_translimit_check.ctc_posusage_limit%TYPE;
   v_mmpos_usageamnt            cms_translimit_check.ctc_mmposusage_amt%TYPE;
   v_mmpos_usagelimit           cms_translimit_check.ctc_mmposusage_limit%TYPE;
   v_preauth_date               DATE;
   v_preauth_hold               VARCHAR2 (1);
   v_preauth_period             NUMBER;
   v_preauth_usage_limit        NUMBER;
   v_card_acct_no               VARCHAR2 (20);
   v_hold_amount                NUMBER;
   v_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
   v_rrn_count                  NUMBER;
   v_tran_type                  VARCHAR2 (2);
   v_date                       DATE;
   v_time                       VARCHAR2 (10);
   v_max_card_bal               NUMBER;
   v_curr_date                  DATE;
   v_preauth_exp_period         VARCHAR2 (10);
   v_international_flag         CHARACTER (1);
   v_proxunumber                cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number                cms_appl_pan.cap_acct_no%TYPE;
   crdstat_cnt                  VARCHAR2 (10);
   v_cro_oldcard_reissue_stat   VARCHAR2 (10);
   v_mbrnumb                    VARCHAR2 (10);
   new_dispname                 VARCHAR2 (50);
   new_card_no                  VARCHAR2 (100);
   v_cap_prod_catg              VARCHAR2 (100);
   v_cust_code                  VARCHAR2 (100);
   p_remrk                      VARCHAR2 (100);
   v_resoncode                  cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_authid_date                VARCHAR2 (8);
   v_status_chk                 NUMBER;
   v_cap_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   v_card_status                cms_bin_param.cbp_param_value%TYPE;
   v_profile_code               cms_prod_cattype.cpc_profile_code%TYPE;
   v_expryparam                 cms_bin_param.cbp_param_value%TYPE;
   v_cardtype_profile_code      cms_prod_cattype.cpc_profile_code%TYPE;
   v_validity_period            cms_bin_param.cbp_param_value%TYPE;
   v_ccs_card_status            cms_cardissuance_status.ccs_card_status%TYPE;
   v_card_type                  cms_appl_pan.cap_card_type%TYPE;
   v_cpm_catg_code              cms_prod_mast.cpm_catg_code%TYPE;
   v_prod_prefix                cms_prod_cattype.cpc_prod_prefix%TYPE;
   v_check_statcnt              NUMBER (1);
   v_acct_type                  cms_acct_mast.cam_type_code%TYPE;
BEGIN
   SAVEPOINT v_auth_savepoint;
   v_resp_cde := '1';
   v_err_msg := 'OK';
   p_resp_msg := 'OK';
   p_remrk := 'Online Order Replacement Card';

   BEGIN
      BEGIN
         v_hash_pan := gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_encr_pan := fn_emaps_main (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      BEGIN
         IF p_inst_code IS NULL
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                 'Institute code cannot be null ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                 'Institute code cannot be null ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_date := TO_DATE (SUBSTR (TRIM (p_tran_date), 1, 8), 'yyyymmdd');
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '45';
            v_err_msg :=
                  'Problem while converting transaction date '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_tran_date :=
            TO_DATE (   SUBSTR (TRIM (p_tran_date), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_tran_time), 1, 10),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '32';
            v_err_msg :=
                  'Problem while converting transaction time '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE rrn = p_rrn
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel;

         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_err_msg := 'Duplicate RRN from the Treminal on' || p_tran_date;
            RAISE exp_reject_record;
         END IF;
      END;

      BEGIN
         SELECT ctm_credit_debit_flag, ctm_output_type,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc
           INTO v_dr_cr_flag, v_output_type,
                v_txn_type,
                v_tran_type, v_narration
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Transflag  not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting transaction details';
            RAISE exp_reject_record;
      END;

      IF ((v_tran_type = 'F') OR (p_msg = '0100'))
      THEN
         IF (p_txn_amt >= 0)
         THEN
            v_tran_amt := p_txn_amt;

            BEGIN
               sp_convert_curr (p_inst_code,
                                p_curr_code,
                                p_card_no,
                                p_txn_amt,
                                v_tran_date,
                                v_tran_amt,
                                v_card_curr,
                                v_err_msg
                               );

               IF v_err_msg <> 'OK'
               THEN
                  v_resp_cde := '44';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_resp_cde := '69';
                  v_err_msg :=
                        'Error from currency conversion '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSE
            v_resp_cde := '43';
            v_err_msg := 'INVALID AMOUNT';
            RAISE exp_reject_record;
         END IF;
      END IF;

      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_expry_date,
                cap_card_stat, cap_atm_online_limit, cap_pos_online_limit,
                cap_proxy_number, cap_acct_no, cap_card_type, cap_prod_catg,
                cap_cust_code
           INTO v_cap_card_stat, v_prod_code, v_prod_cattype, v_expry_date,
                v_applpan_cardstat, v_atmonline_limit, v_atmonline_limit,
                v_proxunumber, v_acct_number, v_card_type, v_cap_prod_catg,
                v_cust_code
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';
            v_err_msg := 'CARD NOT FOUND ' || v_hash_pan;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT ccs_card_status
           INTO v_ccs_card_status
           FROM cms_cardissuance_status
          WHERE ccs_pan_code = v_hash_pan;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            v_err_msg :=
                    'Card Number Not Found In CardIssuence :- ' || v_hash_pan;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while selecting card number from CardIssuence  '
               || v_hash_pan
               || ' '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF v_ccs_card_status <> '15'
      THEN
         v_resp_cde := '49';
         v_err_msg := 'Card application status should be shipped ';
         RAISE exp_reject_record;
      END IF;

      BEGIN
         sp_status_check_gpr (p_inst_code,
                              p_card_no,
                              p_delivery_channel,
                              v_expry_date,
                              v_applpan_cardstat,
                              p_txn_code,
                              p_txn_mode,
                              v_prod_code,
                              v_prod_cattype,
                              p_msg,
                              p_tran_date,
                              p_tran_time,
                              NULL,
                              NULL,
                              p_mcc_code,
                              v_resp_cde,
                              v_err_msg
                             );

         IF (   (v_resp_cde <> '1' AND v_err_msg <> 'OK')
             OR (v_resp_cde <> '0' AND v_err_msg <> 'OK')
            )
         THEN
            RAISE exp_reject_record;
         ELSE
            v_status_chk := v_resp_cde;
            v_resp_cde := '1';
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Error from GPR Card Status Check '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF v_status_chk = '1'
      THEN
         BEGIN
            IF TO_DATE (p_tran_date, 'YYYYMMDD') >
                               LAST_DAY (TO_CHAR (v_expry_date, 'DD-MON-YY'))
            THEN
               v_resp_cde := '13';
               v_err_msg := 'EXPIRED CARD';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                    'ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT COUNT (1)
              INTO v_check_statcnt
              FROM pcms_valid_cardstat
             WHERE pvc_inst_code = p_inst_code
               AND pvc_card_stat = v_cap_card_stat
               AND pvc_tran_code = p_txn_code
               AND pvc_delivery_channel = p_delivery_channel;

            IF v_check_statcnt = 0
            THEN
               v_resp_cde := '10';
               v_err_msg := 'Invalid Card Status';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while selecting card stat '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no
               INTO v_acct_balance, v_ledger_bal, v_card_acct_no
               FROM cms_acct_mast
              WHERE cam_acct_no =
                       (SELECT cap_acct_no
                          FROM cms_appl_pan
                         WHERE cap_pan_code = v_hash_pan
                           AND cap_mbr_numb = p_mbr_numb
                           AND cap_inst_code = p_inst_code)
                AND cam_inst_code = p_inst_code
         FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';
            v_err_msg := 'Invalid Card ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Error while selecting data from card Master for card number '
               || SQLERRM;
            RAISE exp_reject_record;
      END;

      BEGIN
         sp_authorize_txn_cms_auth (p_inst_code,
                                    p_msg,
                                    p_rrn,
                                    p_delivery_channel,
                                    NULL,
                                    p_txn_code,
                                    p_txn_mode,
                                    p_tran_date,
                                    p_tran_time,
                                    p_card_no,
                                    p_inst_code,
                                    0,
                                    p_merchant_name,
                                    p_merchant_city,
                                    NULL,
                                    p_curr_code,
                                    p_prod_id,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    p_consodium_code,
                                    p_partner_code,
                                    v_expry_date,
                                    p_stan,
                                    p_mbr_numb,
                                    p_rvsl_code,
                                    NULL,
                                    v_auth_id,
                                    p_resp_code,
                                    v_err_msg,
                                    p_capture_date
                                   );

         IF p_resp_code <> '00' AND v_err_msg <> 'OK'
         THEN
            p_resp_code := '21';
            v_err_msg := 'Error from auth process' || v_err_msg;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code := '21';
            v_err_msg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT TO_NUMBER (cbp_param_value)
           INTO v_max_card_bal
           FROM cms_bin_param
          WHERE cbp_inst_code = p_inst_code
            AND cbp_param_name = 'Max Card Balance'
            AND cbp_profile_code IN (SELECT cpm_profile_code
                                       FROM cms_prod_mast
                                      WHERE cpm_prod_code = v_prod_code);
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF (v_upd_ledger_amt > v_max_card_bal) OR (v_upd_amt > v_max_card_bal)
      THEN
         v_resp_cde := '30';
         v_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE / BAD CREDIT STATUS';
         RAISE exp_reject_record;
      END IF;

      BEGIN
         SELECT cpm_profile_code, cpm_catg_code, cpc_prod_prefix,
                cpc_profile_code
           INTO v_profile_code, v_cpm_catg_code, v_prod_prefix,
                v_cardtype_profile_code
           FROM cms_prod_cattype, cms_prod_mast
          WHERE cpc_inst_code = p_inst_code
            AND cpc_prod_code = v_prod_code
            AND cpc_card_type = v_card_type
            AND cpm_prod_code = cpc_prod_code;

         IF v_profile_code IS NULL
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Product profile is not attached to product';
            RAISE exp_reject_record;
         END IF;

         IF v_cardtype_profile_code IS NULL
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Profile is not attached to product cattype';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_err_msg :=
                  'Profile code not defined for product code '
               || v_prod_code
               || 'card type '
               || v_card_type;
            v_resp_cde := '21';
            RAISE exp_reject_record;
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while selecting Profile code '
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cbp_param_value
           INTO v_expryparam
           FROM cms_bin_param
          WHERE cbp_profile_code = v_cardtype_profile_code
            AND cbp_param_name = 'Validity'
            AND cbp_inst_code = p_inst_code;

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
                  AND cbp_inst_code = p_inst_code;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE exp_reject_record;
               WHEN NO_DATA_FOUND
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                     'Validity period is not defined for product cattype profile ';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_err_msg :=
                        'Error while selecting Validity peroid 1'
                     || SUBSTR (SQLERRM, 1, 300);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
            END;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT cbp_param_value
                 INTO v_expryparam
                 FROM cms_bin_param
                WHERE cbp_profile_code = v_profile_code
                  AND cbp_param_name = 'Validity'
                  AND cbp_inst_code = p_inst_code;

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
                        AND cbp_inst_code = p_inst_code;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN NO_DATA_FOUND
                     THEN
                        v_resp_cde := '21';
                        v_err_msg :=
                           'Validity period is not defined for product profile ';
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while selecting Validity peroid 2 '
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE exp_reject_record;
               WHEN NO_DATA_FOUND
               THEN
                  v_err_msg :=
                     'No validity data found either product/product type profile ';
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_err_msg :=
                        'Error while selecting validity data 3'
                     || SUBSTR (SQLERRM, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
            END;
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while selecting validity or validity period for profile '
               || SUBSTR (SQLERRM, 1, 200);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      IF v_validity_period = 'Hour'
      THEN
         v_expry_date := SYSDATE + v_expryparam / 24;
      ELSIF v_validity_period = 'Day'
      THEN
         v_expry_date := SYSDATE + v_expryparam;
      ELSIF v_validity_period = 'Week'
      THEN
         v_expry_date := SYSDATE + (7 * v_expryparam);
      ELSIF v_validity_period = 'Month'
      THEN
         v_expry_date := LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1));
      ELSIF v_validity_period = 'Year'
      THEN
         v_expry_date :=
                      LAST_DAY (ADD_MONTHS (SYSDATE, (12 * v_expryparam) - 1));
      END IF;

      BEGIN
         SELECT cbp_param_value
           INTO v_card_status
           FROM cms_prod_mast, cms_bin_param
          WHERE cpm_inst_code = p_inst_code
            AND cpm_prod_code = v_prod_code
            AND cbp_profile_code = cpm_profile_code
            AND cbp_param_name = 'Status';
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN NO_DATA_FOUND
         THEN
            v_err_msg := 'Card Status not defined for the Profile';
            v_resp_cde := '21';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg := 'Error while selecting card status for profile ';
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      BEGIN
         UPDATE cms_appl_pan
            SET cap_card_stat = v_card_status,
                cap_expry_date = v_expry_date
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT = 0
         THEN
            v_err_msg :=
                  'Problem in updation of status for pan in appl pan  '
               || p_card_no;
            v_resp_cde := '09';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg :=
                'Error while updating appl pan  ' || SUBSTR (SQLERRM, 1, 200);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      IF v_err_msg = 'OK'
      THEN
         BEGIN
            UPDATE cms_cardissuance_status
               SET ccs_card_status = '2'
             WHERE ccs_inst_code = p_inst_code AND ccs_pan_code = v_hash_pan;

            IF SQL%ROWCOUNT = 0
            THEN
               v_err_msg :=
                     'Problem in updation of status for pan in card issuence '
                  || p_card_no;
               v_resp_cde := '09';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Error while updating card issuence '
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;
      END IF;

      BEGIN
         BEGIN
            IF p_txn_code = '11' AND p_msg = '0100'
            THEN
               IF NULL IS NULL
               THEN
                  SELECT cpm_pre_auth_exp_date
                    INTO v_preauth_exp_period
                    FROM cms_prod_mast
                   WHERE cpm_prod_code = v_prod_code;

                  IF v_preauth_exp_period IS NULL
                  THEN
                     SELECT cip_param_value
                       INTO v_preauth_exp_period
                       FROM cms_inst_param
                      WHERE cip_inst_code = p_inst_code
                        AND cip_param_key = 'PRE-AUTH EXP PERIOD';

                     v_preauth_hold :=
                                    SUBSTR (TRIM (v_preauth_exp_period), 1, 1);
                     v_preauth_period :=
                                    SUBSTR (TRIM (v_preauth_exp_period), 2, 2);
                  ELSE
                     v_preauth_hold :=
                                   SUBSTR (TRIM (v_preauth_exp_period), 1, 1);
                     v_preauth_period :=
                                   SUBSTR (TRIM (v_preauth_exp_period), 2, 2);
                  END IF;
               ELSE
                  IF v_preauth_period = '00'
                  THEN
                     SELECT cpm_pre_auth_exp_date
                       INTO v_preauth_exp_period
                       FROM cms_prod_mast
                      WHERE cpm_prod_code = v_prod_code;

                     IF v_preauth_exp_period IS NULL
                     THEN
                        SELECT cip_param_value
                          INTO v_preauth_exp_period
                          FROM cms_inst_param
                         WHERE cip_inst_code = p_inst_code
                           AND cip_param_key = 'PRE-AUTH EXP PERIOD';

                        v_preauth_hold :=
                                    SUBSTR (TRIM (v_preauth_exp_period), 1, 1);
                        v_preauth_period :=
                                    SUBSTR (TRIM (v_preauth_exp_period), 2, 2);
                     ELSE
                        v_preauth_hold :=
                                   SUBSTR (TRIM (v_preauth_exp_period), 1, 1);
                        v_preauth_period :=
                                   SUBSTR (TRIM (v_preauth_exp_period), 2, 2);
                     END IF;
                  ELSE
                     v_preauth_hold := v_preauth_hold;
                     v_preauth_period := v_preauth_period;
                  END IF;
               END IF;

               IF v_preauth_hold = '0'
               THEN
                  v_preauth_date :=
                                v_tran_date
                                + (v_preauth_period * (1 / 1440));
               END IF;

               IF v_preauth_hold = '1'
               THEN
                  v_preauth_date :=
                                  v_tran_date
                                  + (v_preauth_period * (1 / 24));
               END IF;

               IF v_preauth_hold = '2'
               THEN
                  v_preauth_date := v_tran_date + v_preauth_period;
               END IF;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while inserting preauth transaction details'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

         IF v_resp_cde = '1'
         THEN
            BEGIN
               SELECT     cam_acct_bal
                     INTO v_acct_balance
                     FROM cms_acct_mast
                    WHERE cam_acct_no =
                             (SELECT cap_acct_no
                                FROM cms_appl_pan
                               WHERE cap_pan_code = v_hash_pan
                                 AND cap_mbr_numb = p_mbr_numb
                                 AND cap_inst_code = p_inst_code)
                      AND cam_inst_code = p_inst_code
               FOR UPDATE NOWAIT;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE exp_reject_record;
               WHEN NO_DATA_FOUND
               THEN
                  v_resp_cde := '14';
                  v_err_msg := 'Invalid Card ';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_resp_cde := '12';
                  v_err_msg :=
                        'Error while selecting data from card Master for card number '
                     || SQLERRM;
                  RAISE exp_reject_record;
            END;

            IF v_output_type = 'N'
            THEN
               NULL;
            END IF;
         END IF;

         BEGIN
            SELECT csr_spprt_rsncode
              INTO v_resoncode
              FROM cms_spprt_reasons
             WHERE csr_inst_code = p_inst_code
               AND csr_spprt_key = 'RENEW'
               AND ROWNUM < 2;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                    'Order Replacement card reason code is present in master';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Error while selecting reason code from master'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            INSERT INTO cms_pan_spprt
                        (cps_inst_code, cps_pan_code, cps_mbr_numb,
                         cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                         cps_func_remark, cps_ins_user, cps_lupd_user,
                         cps_cmd_mode, cps_pan_code_encr
                        )
                 VALUES (p_inst_code, v_hash_pan, p_mbr_numb,
                         v_cap_prod_catg, 'RENEW', v_resoncode,
                         p_remrk, p_ins_user, p_ins_user,
                         0, v_encr_pan
                        );
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Error while inserting records into card support master'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT ctc_atmusage_amt, ctc_posusage_amt, ctc_atmusage_limit,
                   ctc_posusage_limit, ctc_business_date,
                   ctc_preauthusage_limit, ctc_mmposusage_amt,
                   ctc_mmposusage_limit
              INTO v_atm_usageamnt, v_pos_usageamnt, v_atm_usagelimit,
                   v_pos_usagelimit, v_business_date_tran,
                   v_preauth_usage_limit, v_mmpos_usageamnt,
                   v_mmpos_usagelimit
              FROM cms_translimit_check
             WHERE ctc_inst_code = p_inst_code
               AND ctc_pan_code = v_hash_pan
               AND ctc_mbr_numb = p_mbr_numb;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN NO_DATA_FOUND
            THEN
               v_err_msg :=
                     'Cannot get the Transaction Limit Details of the Card'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Error while selecting 1 CMS_TRANSLIMIT_CHECK'
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            IF p_delivery_channel = '01'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  IF p_txn_amt IS NULL
                  THEN
                     v_atm_usageamnt :=
                                   TRIM (TO_CHAR (0, '99999999999999999.99'));
                  ELSE
                     v_atm_usageamnt :=
                          TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99'));
                  END IF;

                  v_atm_usagelimit := 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_atmusage_amt = v_atm_usageamnt,
                            ctc_atmusage_limit = v_atm_usagelimit,
                            ctc_posusage_amt = 0,
                            ctc_posusage_limit = 0,
                            ctc_preauthusage_limit = 0,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       ),
                            ctc_mmposusage_amt = 0,
                            ctc_mmposusage_limit = 0
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 1 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  IF p_txn_amt IS NULL
                  THEN
                     v_atm_usageamnt :=
                          v_atm_usageamnt
                        + TRIM (TO_CHAR (0, '99999999999999999.99'));
                  ELSE
                     v_atm_usageamnt :=
                          v_atm_usageamnt
                        + TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99'));
                  END IF;

                  v_atm_usagelimit := v_atm_usagelimit + 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_atmusage_amt = v_atm_usageamnt,
                            ctc_atmusage_limit = v_atm_usagelimit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 2 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;

            IF p_delivery_channel = '02'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  IF p_txn_amt IS NULL
                  THEN
                     v_pos_usageamnt :=
                                   TRIM (TO_CHAR (0, '99999999999999999.99'));
                  ELSE
                     v_pos_usageamnt :=
                          TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99'));
                  END IF;

                  v_pos_usagelimit := 1;

                  IF p_txn_code = '11' AND p_msg = '0100'
                  THEN
                     v_preauth_usage_limit := 1;
                     v_pos_usageamnt := 0;
                  ELSE
                     v_preauth_usage_limit := 0;
                  END IF;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_amt = v_pos_usageamnt,
                            ctc_posusage_limit = v_pos_usagelimit,
                            ctc_atmusage_amt = 0,
                            ctc_atmusage_limit = 0,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       ),
                            ctc_preauthusage_limit = v_preauth_usage_limit,
                            ctc_mmposusage_amt = 0,
                            ctc_mmposusage_limit = 0
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 3 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_pos_usagelimit := v_pos_usagelimit + 1;

                  IF p_txn_code = '11' AND p_msg = '0100'
                  THEN
                     v_preauth_usage_limit := v_preauth_usage_limit + 1;
                     v_pos_usageamnt := v_pos_usageamnt;
                  ELSE
                     IF p_txn_amt IS NULL
                     THEN
                        v_pos_usageamnt :=
                             v_pos_usageamnt
                           + TRIM (TO_CHAR (0, '99999999999999999.99'));
                     ELSE
                        IF v_dr_cr_flag = 'CR'
                        THEN
                           v_pos_usageamnt := v_pos_usageamnt;
                        ELSE
                           v_pos_usageamnt :=
                                v_pos_usageamnt
                              + TRIM (TO_CHAR (v_tran_amt,
                                               '99999999999999999.99'
                                              )
                                     );
                        END IF;
                     END IF;
                  END IF;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_amt = v_pos_usageamnt,
                            ctc_posusage_limit = v_pos_usagelimit,
                            ctc_preauthusage_limit = v_preauth_usage_limit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 4 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;

            IF p_delivery_channel = '04'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  IF p_txn_amt IS NULL
                  THEN
                     v_mmpos_usageamnt :=
                                   TRIM (TO_CHAR (0, '99999999999999999.99'));
                  ELSE
                     v_mmpos_usageamnt :=
                          TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99'));
                  END IF;

                  v_mmpos_usagelimit := 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_mmposusage_amt = v_mmpos_usageamnt,
                            ctc_mmposusage_limit = v_mmpos_usagelimit,
                            ctc_atmusage_amt = 0,
                            ctc_atmusage_limit = 0,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       ),
                            ctc_preauthusage_limit = 0,
                            ctc_posusage_amt = 0,
                            ctc_posusage_limit = 0
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 5 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

                  IF p_txn_amt IS NULL
                  THEN
                     v_mmpos_usageamnt :=
                          v_mmpos_usageamnt
                        + TRIM (TO_CHAR (0, 999999999999999));
                  ELSE
                     v_mmpos_usageamnt :=
                          v_mmpos_usageamnt
                        + TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99'));
                  END IF;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_mmposusage_amt = v_mmpos_usageamnt,
                            ctc_mmposusage_limit = v_mmpos_usagelimit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 6 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         END;
      END;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = TO_NUMBER (v_resp_cde);
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Problem while selecting data from response master for respose code'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         p_resp_msg := v_err_msg;
         ROLLBACK TO v_auth_savepoint;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO v_acct_balance, v_ledger_bal, v_acct_type
              FROM cms_acct_mast
             WHERE cam_acct_no =
                      (SELECT cap_acct_no
                         FROM cms_appl_pan
                        WHERE cap_pan_code = v_hash_pan
                          AND cap_inst_code = p_inst_code)
               AND cam_inst_code = p_inst_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
         END;

         BEGIN
            UPDATE transactionlog
               SET ipaddress = p_ipaddress
             WHERE rrn = p_rrn
               AND business_date = p_tran_date
               AND txn_code = p_txn_code
               AND msgtype = p_msg
               AND business_time = p_tran_time
               AND delivery_channel = p_delivery_channel;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '69';
               v_err_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
         END;

         BEGIN
            SELECT ctc_atmusage_limit, ctc_posusage_limit,
                   ctc_business_date, ctc_preauthusage_limit,
                   ctc_mmposusage_limit
              INTO v_atm_usagelimit, v_pos_usagelimit,
                   v_business_date_tran, v_preauth_usage_limit,
                   v_mmpos_usagelimit
              FROM cms_translimit_check
             WHERE ctc_inst_code = p_inst_code
               AND ctc_pan_code = v_hash_pan
               AND ctc_mbr_numb = p_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err_msg :=
                     'Cannot get the Transaction Limit Details of the Card'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Error while selecting 2 CMS_TRANSLIMIT_CHECK'
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            IF p_delivery_channel = '01'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  v_atm_usageamnt := 0;
                  v_atm_usagelimit := 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_atmusage_amt = v_atm_usageamnt,
                            ctc_atmusage_limit = v_atm_usagelimit,
                            ctc_posusage_amt = 0,
                            ctc_posusage_limit = 0,
                            ctc_preauthusage_limit = 0,
                            ctc_mmposusage_amt = 0,
                            ctc_mmposusage_limit = 0,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       )
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 7 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_atm_usagelimit := v_atm_usagelimit + 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_atmusage_limit = v_atm_usagelimit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 8 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;

            IF p_delivery_channel = '02'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  v_pos_usageamnt := 0;
                  v_pos_usagelimit := 1;
                  v_preauth_usage_limit := 0;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_amt = v_pos_usageamnt,
                            ctc_posusage_limit = v_pos_usagelimit,
                            ctc_atmusage_amt = 0,
                            ctc_atmusage_limit = 0,
                            ctc_mmposusage_amt = 0,
                            ctc_mmposusage_limit = 0,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       ),
                            ctc_preauthusage_limit = v_preauth_usage_limit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 9 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_pos_usagelimit := v_pos_usagelimit + 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_limit = v_pos_usagelimit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 10 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;

            IF p_delivery_channel = '04'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  v_mmpos_usageamnt := 0;
                  v_mmpos_usagelimit := 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_amt = 0,
                            ctc_posusage_limit = 0,
                            ctc_atmusage_amt = 0,
                            ctc_atmusage_limit = 0,
                            ctc_mmposusage_amt = v_mmpos_usageamnt,
                            ctc_mmposusage_limit = v_mmpos_usagelimit,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       ),
                            ctc_preauthusage_limit = 0
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 11 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_mmposusage_limit = v_mmpos_usagelimit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 12 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         END;

         BEGIN
            p_resp_code := v_resp_cde;
            p_resp_msg := v_err_msg;

            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';
               ROLLBACK;
         END;

         BEGIN
            IF v_rrn_count > 0
            THEN
               IF TO_NUMBER (p_delivery_channel) = 8
               THEN
                  BEGIN
                     SELECT response_code
                       INTO v_resp_cde
                       FROM transactionlog a,
                            (SELECT MIN (add_ins_date) mindate
                               FROM transactionlog
                              WHERE rrn = p_rrn) b
                      WHERE a.add_ins_date = mindate AND rrn = p_rrn;

                     p_resp_code := v_resp_cde;

                     SELECT     cam_acct_bal
                           INTO v_acct_balance
                           FROM cms_acct_mast
                          WHERE cam_acct_no =
                                   (SELECT cap_acct_no
                                      FROM cms_appl_pan
                                     WHERE cap_pan_code = v_hash_pan
                                       AND cap_mbr_numb = p_mbr_numb
                                       AND cap_inst_code = p_inst_code)
                            AND cam_inst_code = p_inst_code
                     FOR UPDATE NOWAIT;

                     v_err_msg := TO_CHAR (v_acct_balance);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Problem in selecting the response detail of Original transaction'
                           || SUBSTR (SQLERRM, 1, 300);
                        p_resp_code := '89';
                        ROLLBACK;
                        RETURN;
                  END;
               END IF;
            END IF;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_msg_type, ctd_txn_mode, ctd_business_date,
                         ctd_business_time, ctd_customer_card_no,
                         ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                         ctd_fee_amount, ctd_waiver_amount,
                         ctd_servicetax_amount, ctd_cess_amount,
                         ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                         ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no, ctd_inst_code,
                         ctd_customer_card_no_encr, ctd_cust_acct_number,
                         ctd_lupd_date, ctd_lupd_user, ctd_ins_date,
                         ctd_ins_user
                        )
                 VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                         p_msg, p_txn_mode, p_tran_date,
                         p_tran_time, v_hash_pan,
                         p_txn_amt, p_curr_code, v_tran_amt,
                         NULL, NULL,
                         NULL, NULL,
                         v_total_amt, v_card_curr, 'E',
                         v_err_msg, p_rrn,
                         p_stan, p_inst_code,
                         v_encr_pan, v_acct_number,
                         SYSDATE, p_ins_user, SYSDATE,
                         p_ins_user
                        );

            p_resp_msg := v_err_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';
               ROLLBACK;
               RETURN;
         END;

         IF v_dr_cr_flag IS NULL
         THEN
            BEGIN
               SELECT ctm_credit_debit_flag,
                      TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                      ctm_tran_desc
                 INTO v_dr_cr_flag,
                      v_txn_type,
                      v_narration
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = p_txn_code
                  AND ctm_delivery_channel = p_delivery_channel
                  AND ctm_inst_code = p_inst_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         IF v_prod_code IS NULL
         THEN
            BEGIN
               SELECT cap_prod_code, cap_card_type, cap_card_stat,
                      cap_acct_no
                 INTO v_prod_code, v_prod_cattype, v_applpan_cardstat,
                      v_acct_number
                 FROM cms_appl_pan
                WHERE cap_inst_code = p_inst_code
                  AND cap_pan_code = gethash (p_card_no)
                  AND cap_mbr_numb = p_mbr_numb;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, terminal_id,
                         date_time, txn_code, txn_type,
                         txn_mode, txn_status,
                         response_code, business_date,
                         business_time, customer_card_no, topup_card_no,
                         topup_acct_no, topup_acct_type, bank_code,
                         total_amount,
                         rule_indicator, rulegroupid, mccode, currencycode,
                         addcharge, productid, categoryid, tips,
                         decline_ruleid, atm_name_location, auth_id,
                         trans_desc,
                         amount,
                         preauthamount, partialamount, mccodegroupid,
                         currencycodegroupid, transcodegroupid, rules,
                         preauth_date, gl_upd_flag, system_trace_audit_no,
                         instcode, feecode, tranfee_amt,
                         servicetax_amt,
                         cess_amt, cr_dr_flag,
                         tranfee_cr_acctno, tranfee_dr_acctno,
                         tran_st_calc_flag, tran_cess_calc_flag,
                         tran_st_cr_acctno, tran_st_dr_acctno,
                         tran_cess_cr_acctno, tran_cess_dr_acctno,
                         customer_card_no_encr, topup_card_no_encr,
                         proxy_number, reversal_code, customer_acct_no,
                         acct_balance, ledger_balance, response_id,
                         ipaddress, cardstatus, add_lupd_date,
                         add_lupd_user, add_ins_date, add_ins_user,
                         error_msg, processes_flag, acct_type, time_stamp
                        )
                 VALUES (p_msg, p_rrn, p_delivery_channel, p_term_id,
                         v_business_date, p_txn_code, v_txn_type,
                         p_txn_mode, DECODE (p_resp_code, '00', 'C', 'F'),
                         p_resp_code, p_tran_date,
                         SUBSTR (p_tran_time, 1, 10), v_hash_pan, NULL,
                         NULL, NULL, p_bank_code,
                         TRIM (TO_CHAR (NVL (v_total_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         '', '', p_mcc_code, p_curr_code,
                         NULL, v_prod_code, v_prod_cattype, '0.00',
                         '', '', v_auth_id,
                         v_narration,
                         TRIM (TO_CHAR (NVL (v_tran_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         '0.00', '0.00', '',
                         '', '', '',
                         '', v_gl_upd_flag, p_stan,
                         p_inst_code, v_fee_code, NVL (v_fee_amt, 0),
                         NVL (v_servicetax_amount, 0),
                         NVL (v_cess_amount, 0), v_dr_cr_flag,
                         v_fee_cracct_no, v_fee_dracct_no,
                         v_st_calc_flag, v_cess_calc_flag,
                         v_st_cracct_no, v_st_dracct_no,
                         v_cess_cracct_no, v_cess_dracct_no,
                         v_encr_pan, NULL,
                         v_proxunumber, p_rvsl_code, v_acct_number,
                         v_acct_balance, v_ledger_bal, v_resp_cde,
                         p_ipaddress, v_applpan_cardstat, SYSDATE,
                         p_ins_user, SYSDATE, p_ins_user,
                         v_err_msg, 'E', v_acct_type, SYSTIMESTAMP
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '69';
               p_resp_msg :=
                     'Problem while inserting data into transaction log  '
                  || SUBSTR (SQLERRM, 1, 300);
         END;
      WHEN OTHERS
      THEN
         ROLLBACK TO v_auth_savepoint;

         BEGIN
            SELECT ctc_atmusage_limit, ctc_posusage_limit,
                   ctc_business_date, ctc_preauthusage_limit,
                   ctc_mmposusage_limit
              INTO v_atm_usagelimit, v_pos_usagelimit,
                   v_business_date_tran, v_preauth_usage_limit,
                   v_mmpos_usagelimit
              FROM cms_translimit_check
             WHERE ctc_inst_code = p_inst_code
               AND ctc_pan_code = v_hash_pan
               AND ctc_mbr_numb = p_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err_msg :=
                     'Cannot get the Transaction Limit Details of the Card'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Error while selecting 3 CMS_TRANSLIMIT_CHECK'
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            IF p_delivery_channel = '01'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  v_atm_usageamnt := 0;
                  v_atm_usagelimit := 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_atmusage_amt = v_atm_usageamnt,
                            ctc_atmusage_limit = v_atm_usagelimit,
                            ctc_posusage_amt = 0,
                            ctc_posusage_limit = 0,
                            ctc_preauthusage_limit = 0,
                            ctc_mmposusage_amt = 0,
                            ctc_mmposusage_limit = 0,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       )
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 13 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_atm_usagelimit := v_atm_usagelimit + 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_atmusage_limit = v_atm_usagelimit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 14 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;

            IF p_delivery_channel = '02'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  v_pos_usageamnt := 0;
                  v_pos_usagelimit := 1;
                  v_preauth_usage_limit := 0;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_amt = v_pos_usageamnt,
                            ctc_posusage_limit = v_pos_usagelimit,
                            ctc_atmusage_amt = 0,
                            ctc_atmusage_limit = 0,
                            ctc_mmposusage_amt = 0,
                            ctc_mmposusage_limit = 0,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       ),
                            ctc_preauthusage_limit = v_preauth_usage_limit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 15 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_pos_usagelimit := v_pos_usagelimit + 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_limit = v_pos_usagelimit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 16 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;

            IF p_delivery_channel = '04'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  v_mmpos_usageamnt := 0;
                  v_mmpos_usagelimit := 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_amt = 0,
                            ctc_posusage_limit = 0,
                            ctc_atmusage_amt = 0,
                            ctc_atmusage_limit = 0,
                            ctc_mmposusage_amt = v_mmpos_usageamnt,
                            ctc_mmposusage_limit = v_mmpos_usagelimit,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       ),
                            ctc_preauthusage_limit = 0
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 17 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_pos_usagelimit := v_pos_usagelimit + 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_limit = v_pos_usagelimit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 18 CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         END;

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;

            p_resp_msg := v_err_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';
               ROLLBACK;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_msg_type, ctd_txn_mode, ctd_business_date,
                         ctd_business_time, ctd_customer_card_no,
                         ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                         ctd_fee_amount, ctd_waiver_amount,
                         ctd_servicetax_amount, ctd_cess_amount,
                         ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                         ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no, ctd_inst_code,
                         ctd_customer_card_no_encr, ctd_cust_acct_number,
                         ctd_lupd_date, ctd_lupd_user, ctd_ins_date,
                         ctd_ins_user
                        )
                 VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                         p_msg, p_txn_mode, p_tran_date,
                         p_tran_time, v_hash_pan,
                         p_txn_amt, p_curr_code, v_tran_amt,
                         NULL, NULL,
                         NULL, NULL,
                         v_total_amt, v_card_curr, 'E',
                         v_err_msg, p_rrn,
                         p_stan, p_inst_code,
                         v_encr_pan, v_acct_number,
                         SYSDATE, p_ins_user, SYSDATE,
                         p_ins_user
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';
               ROLLBACK;
               RETURN;
         END;

         IF v_dr_cr_flag IS NULL
         THEN
            BEGIN
               SELECT ctm_credit_debit_flag,
                      TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                      ctm_tran_desc
                 INTO v_dr_cr_flag,
                      v_txn_type,
                      v_narration
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = p_txn_code
                  AND ctm_delivery_channel = p_delivery_channel
                  AND ctm_inst_code = p_inst_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         IF v_prod_code IS NULL
         THEN
            BEGIN
               SELECT cap_prod_code, cap_card_type, cap_card_stat,
                      cap_acct_no
                 INTO v_prod_code, v_prod_cattype, v_applpan_cardstat,
                      v_acct_number
                 FROM cms_appl_pan
                WHERE cap_inst_code = p_inst_code
                  AND cap_pan_code = gethash (p_card_no)
                  AND cap_mbr_numb = p_mbr_numb;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         IF v_acct_type IS NULL
         THEN
            BEGIN
               SELECT     cam_type_code
                     INTO v_acct_type
                     FROM cms_acct_mast
                    WHERE cam_acct_no = v_acct_number
                      AND cam_inst_code = p_inst_code
               FOR UPDATE NOWAIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, terminal_id,
                         date_time, txn_code, txn_type,
                         txn_mode, txn_status,
                         response_code, business_date,
                         business_time, customer_card_no, topup_card_no,
                         topup_acct_no, topup_acct_type, bank_code,
                         total_amount,
                         rule_indicator, rulegroupid, mccode, currencycode,
                         addcharge, productid, categoryid, tips,
                         decline_ruleid, atm_name_location, auth_id,
                         trans_desc,
                         amount,
                         preauthamount, partialamount, mccodegroupid,
                         currencycodegroupid, transcodegroupid, rules,
                         preauth_date, gl_upd_flag, system_trace_audit_no,
                         instcode, feecode, tranfee_amt,
                         servicetax_amt,
                         cess_amt, cr_dr_flag,
                         tranfee_cr_acctno, tranfee_dr_acctno,
                         tran_st_calc_flag, tran_cess_calc_flag,
                         tran_st_cr_acctno, tran_st_dr_acctno,
                         tran_cess_cr_acctno, tran_cess_dr_acctno,
                         customer_card_no_encr, topup_card_no_encr,
                         proxy_number, reversal_code, customer_acct_no,
                         acct_balance, ledger_balance, response_id,
                         ipaddress, cardstatus, add_lupd_date,
                         add_lupd_user, add_ins_date, add_ins_user,
                         error_msg, processes_flag, acct_type, time_stamp
                        )
                 VALUES (p_msg, p_rrn, p_delivery_channel, p_term_id,
                         v_business_date, p_txn_code, v_txn_type,
                         p_txn_mode, DECODE (p_resp_code, '00', 'C', 'F'),
                         p_resp_code, p_tran_date,
                         SUBSTR (p_tran_time, 1, 10), v_hash_pan, NULL,
                         NULL, NULL, p_bank_code,
                         TRIM (TO_CHAR (NVL (v_total_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         '', '', p_mcc_code, p_curr_code,
                         NULL, v_prod_code, v_prod_cattype, '0.00',
                         '', '', v_auth_id,
                         v_narration,
                         TRIM (TO_CHAR (NVL (v_tran_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         '0.00', '0.00', '',
                         '', '', '',
                         '', v_gl_upd_flag, p_stan,
                         p_inst_code, v_fee_code, NVL (v_fee_amt, 0),
                         NVL (v_servicetax_amount, 0),
                         NVL (v_cess_amount, 0), v_dr_cr_flag,
                         v_fee_cracct_no, v_fee_dracct_no,
                         v_st_calc_flag, v_cess_calc_flag,
                         v_st_cracct_no, v_st_dracct_no,
                         v_cess_cracct_no, v_cess_dracct_no,
                         v_encr_pan, NULL,
                         v_proxunumber, p_rvsl_code, v_acct_number,
                         v_acct_balance, v_ledger_bal, v_resp_cde,
                         p_ipaddress, v_applpan_cardstat, SYSDATE,
                         p_ins_user, SYSDATE, p_ins_user,
                         v_err_msg, 'E', v_acct_type, SYSTIMESTAMP
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '69';
               p_resp_msg :=
                     'Problem while inserting data into transaction log  '
                  || SUBSTR (SQLERRM, 1, 300);
         END;
   END;

   p_auth_id := v_auth_id;

   BEGIN
      SELECT TO_CHAR (SYSDATE, 'YYYYMMDD')
        INTO v_authid_date
        FROM DUAL;

      SELECT v_authid_date || LPAD (seq_auth_id.NEXTVAL, 6, '0')
        INTO v_auth_id
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
         ROLLBACK;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code := '69';
      p_resp_msg :=
            'Main exception from  authorization '
         || p_resp_msg
         || '---'
         || SUBSTR (SQLERRM, 1, 300);
END;
/

SHOW ERROR