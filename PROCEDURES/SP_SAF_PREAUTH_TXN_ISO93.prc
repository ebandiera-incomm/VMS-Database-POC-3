CREATE OR REPLACE PROCEDURE VMSCMS.sp_saf_preauth_txn_iso93 (
   p_inst_code            IN       NUMBER,
   p_msg                  IN       VARCHAR2,
   p_rrn                           VARCHAR2,
   p_delivery_channel              VARCHAR2,
   p_term_id                       VARCHAR2,
   p_txn_code                      VARCHAR2,
   p_txn_mode                      VARCHAR2,
   p_tran_date                     VARCHAR2,
   p_tran_time                     VARCHAR2,
   p_card_no                       VARCHAR2,
   p_bank_code                     VARCHAR2,
   p_txn_amt                       NUMBER,
   p_curr_code                     VARCHAR2,
   p_prod_id                       VARCHAR2,
   p_catg_id                       VARCHAR2,
   p_tip_amt                       VARCHAR2,
   p_decline_ruleid                VARCHAR2,
   p_atmname_loc                   VARCHAR2,
   p_mcccode_groupid               VARCHAR2,
   p_currcode_groupid              VARCHAR2,
   p_transcode_groupid             VARCHAR2,
   p_rules                         VARCHAR2,
   p_consodium_code       IN       VARCHAR2,
   p_partner_code         IN       VARCHAR2,
   p_expry_date           IN       VARCHAR2,
   p_stan                 IN       VARCHAR2,
   p_mbr_numb             IN       VARCHAR2,
   p_rvsl_code            IN       NUMBER,
   p_merc_id              IN       VARCHAR2,
   p_country_code         IN       VARCHAR2,
   p_network_id           IN       VARCHAR2,
   p_interchange_feeamt   IN       NUMBER,
   p_merchant_zip         IN       VARCHAR2,
   p_pos_verfication      IN       VARCHAR2,
   p_international_ind    IN       VARCHAR2,
   p_auth_id              OUT      VARCHAR2,
   p_resp_code            OUT      VARCHAR2,
   p_resp_msg             OUT      VARCHAR2,
   p_capture_date         OUT      DATE
)
IS
   /*************************************************

    * Created By      : Raja Gopal G
    * Created Date    : 20/02/2013
    * Created Reason  :  For Message Type 1120/1121
    * Modified By      : Ganesh S.
    * Modified Date    : 25-APR-2013
    * Modified Reason  : For defect id 10879
    * Reviewer         : Sachin
    * Reviewed Date    : 25-APR-2013
    * Build Number     : CMS3_5_1_RI0005_B0008

   *************************************************/
   v_err_msg                     VARCHAR2 (900)                       := 'OK';
   v_acct_balance                NUMBER;
   v_ledger_bal                  NUMBER;
   v_tran_amt                    NUMBER;
   v_auth_id                     VARCHAR2 (14);
   v_total_amt                   NUMBER;
   v_tran_date                   DATE;
   v_func_code                   cms_func_mast.cfm_func_code%TYPE;
   v_prod_code                   cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype                cms_prod_cattype.cpc_card_type%TYPE;
   v_fee_amt                     NUMBER;
   v_total_fee                   NUMBER;
   v_upd_amt                     NUMBER;
   v_upd_ledger_amt              NUMBER;
   v_narration                   VARCHAR2 (300);
   v_fee_opening_bal             NUMBER;
   v_resp_cde                    VARCHAR2 (3);
   v_expry_date                  DATE;
   v_dr_cr_flag                  VARCHAR2 (2);
   v_output_type                 VARCHAR2 (2);
   v_applpan_cardstat            cms_appl_pan.cap_card_stat%TYPE;
   v_atmonline_limit             cms_appl_pan.cap_atm_online_limit%TYPE;
   v_posonline_limit             cms_appl_pan.cap_atm_offline_limit%TYPE;
   v_precheck_flag               NUMBER;
   v_preauth_flag                NUMBER;
   v_gl_upd_flag                 transactionlog.gl_upd_flag%TYPE;
   v_gl_err_msg                  VARCHAR2 (500);
   v_savepoint                   NUMBER                                  := 0;
   v_tran_fee                    NUMBER;
   v_error                       VARCHAR2 (500);
   v_business_date_tran          DATE;
   v_business_time               VARCHAR2 (5);
   v_cutoff_time                 VARCHAR2 (5);
   v_card_curr                   VARCHAR2 (5);
   v_fee_code                    cms_fee_mast.cfm_fee_code%TYPE;
   v_fee_crgl_catg               cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_fee_crgl_code               cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_fee_crsubgl_code            cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_fee_cracct_no               cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_drgl_catg               cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_fee_drgl_code               cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_fee_drsubgl_code            cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_fee_dracct_no               cms_prodcattype_fees.cpf_dracct_no%TYPE;
   --st AND cess
   v_servicetax_percent          cms_inst_param.cip_param_value%TYPE;
   v_cess_percent                cms_inst_param.cip_param_value%TYPE;
   v_servicetax_amount           NUMBER;
   v_cess_amount                 NUMBER;
   v_st_calc_flag                cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_cess_calc_flag              cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_st_cracct_no                cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_st_dracct_no                cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_cess_cracct_no              cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_cess_dracct_no              cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   --
   v_waiv_percnt                 cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_err_waiv                    VARCHAR2 (300);
   v_log_actual_fee              NUMBER;
   v_log_waiver_amt              NUMBER;
   v_auth_savepoint              NUMBER                             DEFAULT 0;
   v_actual_exprydate            DATE;
   v_business_date               DATE;
   v_txn_type                    NUMBER (1);
   v_mini_totrec                 NUMBER (2);
   v_ministmt_errmsg             VARCHAR2 (500);
   v_ministmt_output             VARCHAR2 (900);
   exp_reject_record             EXCEPTION;
   v_atm_usageamnt               cms_translimit_check.ctc_atmusage_amt%TYPE;
   v_pos_usageamnt               cms_translimit_check.ctc_posusage_amt%TYPE;
   v_atm_usagelimit              cms_translimit_check.ctc_atmusage_limit%TYPE;
   v_pos_usagelimit              cms_translimit_check.ctc_posusage_limit%TYPE;
   v_preauth_date                DATE;
   v_preauth_hold                VARCHAR2 (1);
   v_preauth_period              NUMBER;
   v_preauth_usage_limit         NUMBER;
   v_card_acct_no                VARCHAR2 (20);
   v_hold_amount                 NUMBER;
   v_hash_pan                    cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                    cms_appl_pan.cap_pan_code_encr%TYPE;
   v_rrn_count                   NUMBER;
   v_tran_type                   VARCHAR2 (2);
   v_date                        DATE;
   v_time                        VARCHAR2 (10);
   v_max_card_bal                NUMBER;
   v_curr_date                   DATE;
   v_preauth_exp_period          VARCHAR2 (10);
   v_preauth_count               NUMBER;
   v_trantype                    VARCHAR2 (2);
   v_zip_code                    VARCHAR2 (20);
   v_acc_bal                     VARCHAR2 (15);
   v_international_ind           CHARACTER (1);
   v_addrvrify_flag              CHARACTER (1);
   v_proxunumber                 cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number                 cms_appl_pan.cap_acct_no%TYPE;
   v_trans_desc                  VARCHAR2 (50);
   v_auth_id_gen_flag            VARCHAR2 (1);
   v_status_chk                  NUMBER;
   v_tran_preauth_flag           cms_transaction_mast.ctm_preauth_flag%TYPE;
   v_product_preauth_expperiod   VARCHAR2 (15);
   v_hold_days                   cms_txncode_rule.ctr_hold_days%TYPE;
   p_hold_amount                 NUMBER;
   vt_preauth_hold               VARCHAR2 (1);
   vt_preauth_period             NUMBER;
   vp_preauth_exp_period         cms_prod_mast.cpm_pre_auth_exp_date%TYPE;
   vp_preauth_hold               VARCHAR2 (1);
   vp_preauth_period             NUMBER;
   vi_preauth_exp_period         cms_inst_param.cip_param_value%TYPE;
   vi_preauth_hold               VARCHAR2 (1);
   vi_preauth_period             NUMBER;
   v_feeamnt_type                cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_per_fees                    cms_fee_mast.cfm_per_fees%TYPE;
   v_flat_fees                   cms_fee_mast.cfm_fee_amt%TYPE;
   v_clawback                    cms_fee_mast.cfm_clawback_flag%TYPE;
   v_fee_plan                    cms_fee_feeplan.cff_fee_plan%TYPE;
   v_freetxn_exceed              VARCHAR2 (1);
   v_duration                    VARCHAR2 (20);
   v_feeattach_type              VARCHAR2 (2);
   v_cms_iso_respcde             cms_response_mast.cms_iso_respcde%TYPE;
--Added by Besky on 15/03/13 for defect id 10576
BEGIN
   SAVEPOINT v_auth_savepoint;
   v_resp_cde := '1';
   p_resp_msg := 'OK';

   BEGIN
      --SN CREATE HASH PAN
      BEGIN
         v_hash_pan := gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN CREATE HASH PAN

      --SN create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN create encr pan

      --Sn find narration

      --Sn find debit and credit flag
      BEGIN
         SELECT ctm_credit_debit_flag, ctm_output_type,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_preauth_flag, ctm_tran_desc
           INTO v_dr_cr_flag, v_output_type,
                v_txn_type,
                v_tran_type, v_tran_preauth_flag, v_trans_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '12';                      --Ineligible Transaction
            v_err_msg :=
                  'Transflag  not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';                      --Ineligible Transaction
            v_err_msg :=
                  'Error while selecting  CMS_TRANSACTION_MAST'
               || SUBSTR (SQLERRM, 1, 200)
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
      END;

      --En find debit and credit flag
      --Sn generate auth id
      BEGIN
         --     SELECT TO_CHAR(SYSDATE, 'YYYYMMDD')  || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;

         v_auth_id_gen_flag := 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';                            -- Server Declined
            RAISE exp_reject_record;
      END;

      --En generate auth id

      --SN CHECK INST CODE
      BEGIN
         IF p_inst_code IS NULL
         THEN
            v_resp_cde := '12';                        -- Invalid Transaction
            v_err_msg :=
                 'Institute code cannot be null ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';                        -- Invalid Transaction
            v_err_msg :=
                 'Institute code cannot be null ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --eN CHECK INST CODE

      --En check txn currency
      BEGIN
         v_date := TO_DATE (SUBSTR (TRIM (p_tran_date), 1, 8), 'yyyymmdd');
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '45';                    -- Server Declined -220509
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
            v_resp_cde := '32';                    -- Server Declined -220509
            v_err_msg :=
                  'Problem while converting transaction time '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --Sn Duplicate RRN Check
      BEGIN
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE rrn = p_rrn
            AND                                     --Changed for admin dr cr.
                business_date = p_tran_date
            AND delivery_channel = p_delivery_channel;

         --Added by ramkumar.Mk on 25 march 2012
         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_err_msg :=
                  'Duplicate RRN from the Terminal'
               || p_term_id
               || 'on'
               || p_tran_date;
            RAISE exp_reject_record;
         END IF;
      END;

      --En get date

      --Check for Duplicate rrn for Pre-Auth if pre-auth is expire or valid flag is N
      --checking for inccremental pre-auth

      --Sn Getting BIN Level Configuration details
      BEGIN
         SELECT cbl_international_check, cbl_addr_ver_check
           INTO v_international_ind, v_addrvrify_flag
           FROM cms_bin_level_config
          WHERE cbl_inst_bin = SUBSTR (p_card_no, 1, 6)
            AND cbl_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_international_ind := 'Y';
            v_addrvrify_flag := 'Y';
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while seelcting BIN level Configuration';
            RAISE exp_reject_record;
      END;

      --En Getting BIN Level Configuration details

      --Sn International Indicator check

      --En Address Verificationflag check based on BIN level configuration

      --Sn find service tax
      BEGIN
         SELECT cip_param_value
           INTO v_servicetax_percent
           FROM cms_inst_param
          WHERE cip_param_key = 'SERVICETAX' AND cip_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Service Tax is  not defined in the system';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting service tax from system ';
            RAISE exp_reject_record;
      END;

      --En find service tax

      --Sn find cess
      BEGIN
         SELECT cip_param_value
           INTO v_cess_percent
           FROM cms_inst_param
          WHERE cip_param_key = 'CESS' AND cip_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Cess is not defined in the system';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting cess from system ';
            RAISE exp_reject_record;
      END;

      --En find cess

      ---Sn find cutoff time
      BEGIN
         SELECT cip_param_value
           INTO v_cutoff_time
           FROM cms_inst_param
          WHERE cip_param_key = 'CUTOFF' AND cip_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_cutoff_time := 0;
            v_resp_cde := '21';
            v_err_msg := 'Cutoff time is not defined in the system';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting cutoff  dtl  from system ';
            RAISE exp_reject_record;
      END;

      ---En find cutoff time

      --Sn find the tran amt
      IF ((v_tran_type = 'F') OR (v_tran_preauth_flag = 'Y'))
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
                  v_err_msg := 'ERROR WHILE EXECUTING CONVERT CURRENCY';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_resp_cde := '44';
                  v_err_msg := 'ERROR WHILE CALLING CONVERT CURRENCY';
                  RAISE exp_reject_record;
            END;
         ELSE
            -- If transaction Amount is zero - Invalid Amount -220509
            v_resp_cde := '43';
            v_err_msg := 'INVALID AMOUNT';
            RAISE exp_reject_record;
         END IF;
      END IF;

      --En find the tran amt

      --Sn select authorization processe flag
      BEGIN
         SELECT ptp_param_value
           INTO v_precheck_flag
           FROM pcms_tranauth_param
          WHERE ptp_param_name = 'PRE CHECK' AND ptp_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';                      --only for master setups
            v_err_msg :=
                        'Master set up is not done for Authorization Process';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';                      --only for master setups
            v_err_msg :=
                  'Error while selecting precheck flag'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En select authorization process   flag
      --Sn select authorization processe flag
      BEGIN
         SELECT ptp_param_value
           INTO v_preauth_flag
           FROM pcms_tranauth_param
          WHERE ptp_param_name = 'PRE AUTH' AND ptp_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                        'Master set up is not done for Authorization Process';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting PCMS_TRANAUTH_PARAM'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En select authorization process   flag

      --Sn find card detail
      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_expry_date,
                cap_card_stat, cap_atm_online_limit, cap_pos_online_limit,
                cap_proxy_number, cap_acct_no
           INTO v_prod_code, v_prod_cattype, v_expry_date,
                v_applpan_cardstat, v_atmonline_limit, v_atmonline_limit,
                v_proxunumber, v_acct_number
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
      EXCEPTION
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

      --En find card detail

      --Sn GPR Card status check
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
                              p_international_ind,
                              p_pos_verfication,
--Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                              NULL,
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

      --En GPR Card status check
      IF v_status_chk = '1'
      THEN
         -- Expiry Check
         BEGIN
            IF TO_DATE (p_tran_date, 'YYYYMMDD') >
                             LAST_DAY (TO_CHAR (v_expry_date, 'DD-MON-YYYY'))
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

         -- End Expiry Check

         --Sn check for precheck
         IF v_precheck_flag = 1
         THEN
            BEGIN
               sp_precheck_txn (p_inst_code,
                                p_card_no,
                                p_delivery_channel,
                                v_expry_date,
                                v_applpan_cardstat,
                                p_txn_code,
                                p_txn_mode,
                                p_tran_date,
                                p_tran_time,
                                v_tran_amt,
                                v_atmonline_limit,
                                v_posonline_limit,
                                v_resp_cde,
                                v_err_msg
                               );

               IF (v_resp_cde <> '1' OR v_err_msg <> 'OK')
               THEN
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
                        'Error from precheck processes '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;
      --En check for Precheck
      END IF;

      --Sn check for Preauth
      IF v_preauth_flag = 1
      THEN
         BEGIN
            sp_elan_preauthorize_txn (p_card_no,
                                      NULL,                   --   P_MCC_CODE,
                                      p_curr_code,
                                      v_tran_date,
                                      p_txn_code,
                                      p_inst_code,
                                      p_tran_date,
                                      v_tran_amt,
                                      p_delivery_channel,
                                      p_merc_id,
                                      p_country_code,
                                      p_hold_amount,
                                      v_hold_days,
                                      v_resp_cde,
                                      v_err_msg
                                     );

            /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
            IF (v_resp_cde <> '1' OR TRIM (v_err_msg) <> 'OK')
            THEN
               IF p_delivery_channel IN ('01', '02') AND p_txn_code = '11'
               THEN
                  IF p_hold_amount != NULL
                  THEN
                     v_tran_amt := p_hold_amount;
                  ELSE
                     v_tran_amt := v_tran_amt;
                  END IF;
               END IF;

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
                   'Error from pre_auth process ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      --En check for preauth

      --Sn find function code attached to txn code
      BEGIN
         SELECT cfm_func_code
           INTO v_func_code
           FROM cms_func_mast
          WHERE cfm_txn_code = p_txn_code
            AND cfm_txn_mode = p_txn_mode
            AND cfm_delivery_channel = p_delivery_channel
            AND cfm_inst_code = p_inst_code;
      --TXN mode and delivery channel we need to attach
      --bkz txn code may be same for all type of channels
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '69';                      --Ineligible Transaction
            v_err_msg :=
                      'Function code not defined for txn code ' || p_txn_code;
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            v_resp_cde := '69';
            v_err_msg :=
                 'More than one function defined for txn code ' || p_txn_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '69';
            v_err_msg :=
                  'Error while selecting CMS_FUNC_MAST'
               || SUBSTR (SQLERRM, 1, 200)
               || p_txn_code;
            RAISE exp_reject_record;
      END;

      --En find function code attached to txn code
      --Sn find prod code and card type and available balance for the card number
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no
               INTO v_acct_balance, v_ledger_bal, v_card_acct_no
               FROM cms_acct_mast
              WHERE cam_acct_no = v_acct_number
         FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';                      --Ineligible Transaction
            v_err_msg := 'Invalid Card ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting data from card Master for card number '
               || SQLERRM;
            RAISE exp_reject_record;
      END;

      --En find prod code and card type for the card number

      --En Check PreAuth Completion txn
      BEGIN
         sp_tran_fees_cmsauth
                       (p_inst_code,
                        p_card_no,
                        p_delivery_channel,
                        v_txn_type,
                        p_txn_mode,
                        p_txn_code,
                        p_curr_code,
                        p_consodium_code,
                        p_partner_code,
                        v_tran_amt,
                        v_tran_date,
                        p_international_ind, --Added by Deepa for Fees Changes
                        p_pos_verfication,   --Added by Deepa for Fees Changes
                        v_resp_cde,          --Added by Deepa for Fees Changes
                        p_msg,               --Added by Deepa for Fees Changes
                        p_rvsl_code,
                        --Added by Deepa on June 25 2012 for Reversal txn Fee
                        NULL,  --P_MCC_CoDe Added by Trivinkram on 05-sep-2012
                        v_fee_amt,
                        v_error,
                        v_fee_code,
                        v_fee_crgl_catg,
                        v_fee_crgl_code,
                        v_fee_crsubgl_code,
                        v_fee_cracct_no,
                        v_fee_drgl_catg,
                        v_fee_drgl_code,
                        v_fee_drsubgl_code,
                        v_fee_dracct_no,
                        v_st_calc_flag,
                        v_cess_calc_flag,
                        v_st_cracct_no,
                        v_st_dracct_no,
                        v_cess_cracct_no,
                        v_cess_dracct_no,
                        v_feeamnt_type,      --Added by Deepa for Fees Changes
                        v_clawback,          --Added by Deepa for Fees Changes
                        v_fee_plan,          --Added by Deepa for Fees Changes
                        v_per_fees,          --Added by Deepa for Fees Changes
                        v_flat_fees,         --Added by Deepa for Fees Changes
                        v_freetxn_exceed,
                        -- Added by Trivikram for logging fee of free transaction
                        v_duration,
                        -- Added by Trivikram for logging fee of free transaction
                        v_feeattach_type  -- Added by Trivikram on Sep 05 2012
                       );

         IF v_error <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := v_error;
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
                   'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      ---En dynamic fee calculation .

      --Sn calculate waiver on the fee
      BEGIN
         sp_calculate_waiver (p_inst_code,
                              p_card_no,
                              '000',
                              v_prod_code,
                              v_prod_cattype,
                              v_fee_code,
                              v_fee_plan, -- Added by Trivikram on 21/aug/2012
                              v_tran_date,
                              --Added Trivikam on Aug-23-2012 to calculate the waiver based on tran date
                              v_waiv_percnt,
                              v_err_waiv
                             );

         IF v_err_waiv <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := v_err_waiv;
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
                'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En calculate waiver on the fee

      --Sn apply waiver on fee amount
      v_log_actual_fee := v_fee_amt;           --only used to log in log table
      v_fee_amt := ROUND (v_fee_amt - ((v_fee_amt * v_waiv_percnt) / 100), 2);
      v_log_waiver_amt := v_log_actual_fee - v_fee_amt;

      --only used to log in log table

      --En apply waiver on fee amount

      --Sn apply service tax and cess
      IF v_st_calc_flag = 1
      THEN
         v_servicetax_amount := (v_fee_amt * v_servicetax_percent) / 100;
      ELSE
         v_servicetax_amount := 0;
      END IF;

      IF v_cess_calc_flag = 1
      THEN
         v_cess_amount := (v_servicetax_amount * v_cess_percent) / 100;
      ELSE
         v_cess_amount := 0;
      END IF;

      v_total_fee :=
                    ROUND (v_fee_amt + v_servicetax_amount + v_cess_amount, 2);

      --En apply service tax and cess

      --En find fees amount attached to func code, prod code and card type
      /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      IF p_delivery_channel IN ('01', '02') AND p_txn_code = '11'
      THEN
         IF p_hold_amount IS NOT NULL
         THEN
            v_tran_amt := p_hold_amount;
         END IF;
      END IF;

      /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */

      --Sn find total transaction    amount
      IF v_dr_cr_flag = 'CR'
      THEN
         v_total_amt := v_tran_amt - v_total_fee;
         v_upd_amt := v_acct_balance + v_total_amt;
         v_upd_ledger_amt := v_ledger_bal + v_total_amt;
      ELSIF v_dr_cr_flag = 'DR'
      THEN
         v_total_amt := v_tran_amt + v_total_fee;
         v_upd_amt := v_acct_balance - v_total_amt;
         v_upd_ledger_amt := v_ledger_bal - v_total_amt;
      ELSIF v_dr_cr_flag = 'NA'
      THEN
         IF v_tran_preauth_flag = 'Y'
         THEN
            v_total_amt := v_tran_amt + v_total_fee;
         ELSE
            v_total_amt := v_total_fee;
         END IF;

         v_upd_amt := v_acct_balance - v_total_amt;
         v_upd_ledger_amt := v_ledger_bal;             -- - V_TOTAL_AMT; srini
      ELSE
         v_resp_cde := '12';                         --Ineligible Transaction
         v_err_msg := 'Invalid transflag    txn code ' || p_txn_code;
         RAISE exp_reject_record;
      END IF;

      --En find total transaction    amout

      -- Check for maximum card balance configured for the product profile.
      IF    (v_dr_cr_flag = 'CR' AND p_rvsl_code = '00')
         OR (v_dr_cr_flag = 'DR' AND p_rvsl_code <> '00'
            )                                     --Added by Besky on 26/03/13
      THEN
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
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'CARD BALANCE CONFIGURATION NOT AVAILABLE FOR THE PRODUCT PROFILE '
                  || v_prod_code;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --Sn check balance
         IF    (v_upd_ledger_amt > v_max_card_bal)
            OR (v_upd_amt > v_max_card_bal)
         THEN
            v_resp_cde := '30';
            v_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
            RAISE exp_reject_record;
         END IF;
      END IF;

      --En check balance

      --Sn create gl entries and acct update
      BEGIN
         sp_upd_transaction_accnt_auth
                          (p_inst_code,
                           v_tran_date,
                           v_prod_code,
                           v_prod_cattype,
                           v_tran_amt,
                           v_func_code,
                           p_txn_code,
                           v_dr_cr_flag,
                           p_rrn,
                           p_term_id,
                           p_delivery_channel,
                           p_txn_mode,
                           p_card_no,
                           v_fee_code,
                           v_fee_amt,
                           v_fee_cracct_no,
                           v_fee_dracct_no,
                           v_st_calc_flag,
                           v_cess_calc_flag,
                           v_servicetax_amount,
                           v_st_cracct_no,
                           v_st_dracct_no,
                           v_cess_amount,
                           v_cess_cracct_no,
                           v_cess_dracct_no,
                           v_card_acct_no,
                           ---Card's account no has been passed instead of card no(For Debit card acct_no will be different)
                           v_hold_amount, --For PreAuth Completion transaction
                           p_msg,
                           v_resp_cde,
                           v_err_msg
                          );

         IF (v_resp_cde <> '1' OR v_err_msg <> 'OK')
         THEN
            v_resp_cde := '21';
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
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En create gl entries and acct update

      --Sn find narration
      BEGIN
         IF TRIM (v_trans_desc) IS NOT NULL
         THEN
            v_narration := v_trans_desc || '/';
         END IF;

         IF TRIM (p_tran_date) IS NOT NULL
         THEN
            v_narration := v_narration || p_tran_date || '/';
         END IF;

         IF TRIM (v_auth_id) IS NOT NULL
         THEN
            v_narration := v_narration || v_auth_id;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En find narration
      --Sn create a entry in statement log
      IF v_dr_cr_flag <> 'NA'
      THEN
         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_opening_bal, csl_trans_amount,
                         csl_trans_type, csl_trans_date,
                         csl_closing_balance,
                         csl_trans_narrration, csl_inst_code,
                         csl_pan_no_encr, csl_rrn, csl_auth_id,
                         csl_business_date, csl_business_time, txn_fee_flag,
                         csl_delivery_channel, csl_txn_code, csl_acct_no,
                         --Added by Deepa to log the account number ,INS_DATE and INS_USER
                         csl_ins_user, csl_ins_date, csl_merchant_name,
                         --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                         csl_merchant_city, csl_merchant_state,
                         csl_panno_last4digit
                        )
                 --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
            VALUES      (v_hash_pan, v_acct_balance, v_tran_amt,
                         v_dr_cr_flag, v_tran_date,
                         DECODE (v_dr_cr_flag,
                                 'DR', v_acct_balance - v_tran_amt,
                                 'CR', v_acct_balance + v_tran_amt,
                                 'NA', v_acct_balance
                                ),
                         v_narration, p_inst_code,
                         v_encr_pan, p_rrn, v_auth_id,
                         p_tran_date, p_tran_time, 'N',
                         p_delivery_channel, p_txn_code, v_card_acct_no,
                         --Added by Deepa to log the account number ,INS_DATE and INS_USER
                         1, SYSDATE, NULL,
                         --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                         NULL, p_atmname_loc,
                         (SUBSTR (p_card_no,
                                  LENGTH (p_card_no) - 3,
                                  LENGTH (p_card_no)
                                 )
                         )
                        );
         --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while inserting into statement log for tran amt '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      --En create a entry in statement log

      --Sn find fee opening balance
      IF v_total_fee <> 0 OR v_freetxn_exceed = 'N'
      THEN
         -- Modified by Trivikram on 26-July-2012 for logging fee of free transaction
         BEGIN
            SELECT DECODE (v_dr_cr_flag,
                           'DR', v_acct_balance - v_tran_amt,
                           'CR', v_acct_balance + v_tran_amt,
                           'NA', v_acct_balance
                          )
              INTO v_fee_opening_bal
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '12';
               v_err_msg :=
                     'Error in acct balance calculation based on transflag'
                  || v_dr_cr_flag;
               RAISE exp_reject_record;
         END;

         -- Added by Trivikram on 27-July-2012 for logging complementary transaction
         IF v_freetxn_exceed = 'N'
         THEN
            BEGIN
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_opening_bal, csl_trans_amount,
                            csl_trans_type, csl_trans_date,
                            csl_closing_balance,
                            csl_trans_narrration,
                            csl_inst_code, csl_pan_no_encr, csl_rrn,
                            csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_txn_code, csl_acct_no,
                            --Added by Deepa to log the account number ,INS_DATE and INS_USER
                            csl_ins_user, csl_ins_date, csl_merchant_name,
                            --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                            csl_merchant_city, csl_merchant_state,
                            csl_panno_last4digit
                           )
                    --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
               VALUES      (v_hash_pan, v_fee_opening_bal, v_total_fee,
                            'DR', v_tran_date,
                            v_fee_opening_bal - v_total_fee,
                            'Complimentary ' || v_duration || ' '
                            || v_narration,
                            -- Modified by Trivikram  on 27-July-2012
                            p_inst_code, v_encr_pan, p_rrn,
                            v_auth_id, p_tran_date,
                            p_tran_time, 'Y',
                            p_delivery_channel, p_txn_code, v_card_acct_no,
                            --Added by Deepa to log the account number ,INS_DATE and INS_USER
                            1, SYSDATE, NULL,
                            --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                            NULL, p_atmname_loc,
                            SUBSTR (p_card_no,
                                    LENGTH (p_card_no) - 3,
                                    LENGTH (p_card_no)
                                   )
                           );
            --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Problem while inserting into statement log for tran fee '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSE
            BEGIN
               --En find fee opening balance
               IF v_feeamnt_type = 'A'
               THEN
                  -- Added by Trivikram on 23/aug/2012 for logged fixed fee and percentage fee with waiver
                  v_flat_fees :=
                     ROUND (  v_flat_fees
                            - ((v_flat_fees * v_waiv_percnt) / 100),
                            2
                           );
                  v_per_fees :=
                     ROUND (v_per_fees - ((v_per_fees * v_waiv_percnt) / 100),
                            2
                           );

                  --En Entry for Fixed Fee
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal, csl_trans_amount,
                               csl_trans_type, csl_trans_date,
                               csl_closing_balance,
                               csl_trans_narrration,
                               csl_inst_code, csl_pan_no_encr, csl_rrn,
                               csl_auth_id, csl_business_date,
                               csl_business_time, txn_fee_flag,
                               csl_delivery_channel, csl_txn_code,
                               csl_acct_no, csl_ins_user, csl_ins_date,
                               csl_merchant_name, csl_merchant_city,
                               csl_merchant_state,
                               csl_panno_last4digit
                              )
                       VALUES (v_hash_pan, v_fee_opening_bal, v_flat_fees,
                               'DR', v_tran_date,
                               v_fee_opening_bal - v_flat_fees,
                               'Fixed Fee debited for ' || v_narration,
                               p_inst_code, v_encr_pan, p_rrn,
                               v_auth_id, p_tran_date,
                               p_tran_time, 'Y',
                               p_delivery_channel, p_txn_code,
                               v_card_acct_no, 1, SYSDATE,
                               NULL, NULL,
                               p_atmname_loc,
                               (SUBSTR (p_card_no,
                                        LENGTH (p_card_no) - 3,
                                        LENGTH (p_card_no)
                                       )
                               )
                              );

                  --En Entry for Fixed Fee
                  v_fee_opening_bal := v_fee_opening_bal - v_flat_fees;

                  --Sn Entry for Percentage Fee
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal, csl_trans_amount,
                               csl_trans_type, csl_trans_date,
                               csl_closing_balance,
                               csl_trans_narrration,
                               csl_inst_code, csl_pan_no_encr, csl_rrn,
                               csl_auth_id, csl_business_date,
                               csl_business_time, txn_fee_flag,
                               csl_delivery_channel, csl_txn_code,
                               csl_acct_no,
                                           --Added by Deepa to log the account number ,INS_DATE and INS_USER
                                           csl_ins_user, csl_ins_date,
                               csl_merchant_name,
                                                 --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                                 csl_merchant_city,
                               csl_merchant_state,
                               csl_panno_last4digit
                              )
                       --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                  VALUES      (v_hash_pan, v_fee_opening_bal, v_per_fees,
                               'DR', v_tran_date,
                               v_fee_opening_bal - v_per_fees,
                               'Percetage Fee debited for ' || v_narration,
                               p_inst_code, v_encr_pan, p_rrn,
                               v_auth_id, p_tran_date,
                               p_tran_time, 'Y',
                               p_delivery_channel, p_txn_code,
                               v_card_acct_no,
                                              --Added by Deepa to log the account number ,INS_DATE and INS_USER
                               1, SYSDATE,
                               NULL,
                                    --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                               NULL,
                               p_atmname_loc,
                               (SUBSTR (p_card_no,
                                        LENGTH (p_card_no) - 3,
                                        LENGTH (p_card_no)
                                       )
                               )
                              );
               --En Entry for Percentage Fee
               ELSE
                  --Sn create entries for FEES attached
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal,
                               csl_trans_amount, csl_trans_type,
                               csl_trans_date, csl_closing_balance,
                               csl_trans_narrration,
                               csl_inst_code, csl_pan_no_encr, csl_rrn,
                               csl_auth_id, csl_business_date,
                               csl_business_time, txn_fee_flag,
                               csl_delivery_channel, csl_txn_code,
                               csl_acct_no,
                                           --Added by Deepa to log the account number ,INS_DATE and INS_USER
                                           csl_ins_user, csl_ins_date,
                               csl_merchant_name,
                                                 --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                                 csl_merchant_city,
                               csl_merchant_state,
                               csl_panno_last4digit
                              )
                       --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                  VALUES      (v_hash_pan, v_fee_opening_bal,
                               v_total_fee, 'DR',
                               v_tran_date, v_fee_opening_bal - v_total_fee,
                               'Fee debited for ' || v_narration,
                               p_inst_code, v_encr_pan, p_rrn,
                               v_auth_id, p_tran_date,
                               p_tran_time, 'Y',
                               p_delivery_channel, p_txn_code,
                               v_card_acct_no,
                                              --Added by Deepa to log the account number ,INS_DATE and INS_USER
                               1, SYSDATE,
                               NULL,
                                    --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                               NULL,
                               p_atmname_loc,
                               SUBSTR (p_card_no,
                                       LENGTH (p_card_no) - 3,
                                       LENGTH (p_card_no)
                                      )
                              );
               --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Problem while inserting into statement log for tran fee '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;
      END IF;

      --En create entries for FEES attached
      --Sn create a entry for successful
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                      ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_system_trace_audit_no,
                      ctd_inst_code, ctd_customer_card_no_encr,
                      ctd_cust_acct_number, ctd_addr_verify_response,
                      ctd_internation_ind_response,
                                                   /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                                   ctd_network_id,
                      ctd_interchange_feeamt, ctd_merchant_zip,
                      ctd_merchant_id, ctd_country_code
                                                       /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         ,            ctd_ins_user,
                      ctd_ins_date -- Added for defect id 10879 on 25-APR-2013
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_msg, p_txn_mode, p_tran_date,
                      p_tran_time, v_hash_pan,
                      p_txn_amt, p_curr_code, v_tran_amt,
                      v_log_actual_fee, v_log_waiver_amt,
                      v_servicetax_amount, v_cess_amount,
                      v_total_amt, v_card_curr, 'Y',
                      'Successful', p_rrn, p_stan,
                      p_inst_code, v_encr_pan,
                      v_acct_number, NULL,
                      NULL,
                           /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                           p_network_id,
                      p_interchange_feeamt, p_merchant_zip,
                      p_merc_id, p_country_code
                                               /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         ,            1,
                      SYSDATE      -- Added for defect id 10879 on 25-APR-2013
                     );
      --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Problem while inserting in CMS_TRANSACTION_LOG_DTL '
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      --En create a entry for successful
      ---Sn update daily and weekly transcounter  and amount
      BEGIN
         UPDATE cms_avail_trans
            SET cat_maxdaily_trancnt =
                   DECODE (cat_maxdaily_trancnt,
                           0, cat_maxdaily_trancnt,
                           cat_maxdaily_trancnt - 1
                          ),
                cat_maxdaily_tranamt =
                   DECODE (v_dr_cr_flag,
                           'DR', cat_maxdaily_tranamt - v_tran_amt,
                           cat_maxdaily_tranamt
                          ),
                cat_maxweekly_trancnt =
                   DECODE (cat_maxweekly_trancnt,
                           0, cat_maxweekly_trancnt,
                           cat_maxdaily_trancnt - 1
                          ),
                cat_maxweekly_tranamt =
                   DECODE (v_dr_cr_flag,
                           'DR', cat_maxweekly_tranamt - v_tran_amt,
                           cat_maxweekly_tranamt
                          )
          WHERE cat_inst_code = p_inst_code
            AND cat_pan_code = v_hash_pan
            AND cat_tran_code = p_txn_code
            AND cat_tran_mode = p_txn_mode;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Problem while selecting data from avail trans '
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      --En update daily and weekly transaction counter and amount
      --Sn create detail for response message
      IF v_output_type = 'B'
      THEN
         --Balance Inquiry
         p_resp_msg := TO_CHAR (v_upd_amt);
      END IF;

      --En create detail fro response message
      --Sn mini statement
      IF v_output_type = 'M'
      THEN
         --Mini statement
         BEGIN
            sp_gen_mini_stmt (p_inst_code,
                              p_card_no,
                              v_mini_totrec,
                              v_ministmt_output,
                              v_ministmt_errmsg
                             );

            IF v_ministmt_errmsg <> 'OK'
            THEN
               v_err_msg := v_ministmt_errmsg;
               v_resp_cde := '21';
               RAISE exp_reject_record;
            END IF;

            p_resp_msg :=
                    LPAD (TO_CHAR (v_mini_totrec), 2, '0')
                    || v_ministmt_output;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Problem while selecting data for mini statement '
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;
      END IF;

      --En mini statement
      v_resp_cde := '1';

      BEGIN
         BEGIN
            IF v_tran_preauth_flag = 'Y'
            THEN
               /* IF V_PRODUCT_PREAUTH_EXPPERIOD IS NULL THEN
                 BEGIN
                   SELECT CPM_PRE_AUTH_EXP_DATE
                    INTO V_PREAUTH_EXP_PERIOD
                    FROM CMS_PROD_MAST
                   WHERE CPM_PROD_CODE = V_PROD_CODE;
                 EXCEPTION
                   WHEN OTHERS THEN
                    V_ERR_MSG  := 'Error while selecting  CMS_PROD_MAST ' ||
                               SUBSTR(SQLERRM, 1, 300);
                    V_RESP_CDE := '21';
                    RAISE EXP_REJECT_RECORD;
                 END;
                 IF V_PREAUTH_EXP_PERIOD IS NULL THEN
                   BEGIN
                    SELECT CIP_PARAM_VALUE
                      INTO V_PREAUTH_EXP_PERIOD
                      FROM CMS_INST_PARAM
                     WHERE CIP_INST_CODE = P_INST_CODE AND
                          CIP_PARAM_KEY = 'PRE-AUTH EXP PERIOD';
                   EXCEPTION
                    WHEN OTHERS THEN
                      V_ERR_MSG  := 'Error while selecting  CMS_INST_PARAM ' ||
                                 SUBSTR(SQLERRM, 1, 300);
                      V_RESP_CDE := '21';
                      RAISE EXP_REJECT_RECORD;
                   END;

                   V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
                   V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
                 ELSE
                   V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
                   V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
                 END IF;
               ELSE
                 V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PRODUCT_PREAUTH_EXPPERIOD),
                                       1,
                                       1);
                 V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PRODUCT_PREAUTH_EXPPERIOD),
                                       2,
                                       2);

                 IF V_PREAUTH_PERIOD = '00' THEN
                   BEGIN
                    SELECT CPM_PRE_AUTH_EXP_DATE
                      INTO V_PREAUTH_EXP_PERIOD
                      FROM CMS_PROD_MAST
                     WHERE CPM_PROD_CODE = V_PROD_CODE;
                   EXCEPTION
                    WHEN OTHERS THEN
                      V_ERR_MSG  := 'Error while selecting  CMS_PROD_MAST1 ' ||
                                 SUBSTR(SQLERRM, 1, 300);
                      V_RESP_CDE := '21';
                      RAISE EXP_REJECT_RECORD;
                   END;

                   IF V_PREAUTH_EXP_PERIOD IS NULL THEN
                    BEGIN
                      SELECT CIP_PARAM_VALUE
                       INTO V_PREAUTH_EXP_PERIOD
                       FROM CMS_INST_PARAM
                       WHERE CIP_INST_CODE = P_INST_CODE AND
                           CIP_PARAM_KEY = 'PRE-AUTH EXP PERIOD';
                    EXCEPTION
                      WHEN OTHERS THEN
                       V_ERR_MSG  := 'Error while selecting  CMS_INST_PARAM1 ' ||
                                   SUBSTR(SQLERRM, 1, 300);
                       V_RESP_CDE := '21';
                       RAISE EXP_REJECT_RECORD;
                    END;

                    V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
                    V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
                   ELSE
                    V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
                    V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
                   END IF;
                 ELSE
                   V_PREAUTH_HOLD   := V_PREAUTH_HOLD;
                   V_PREAUTH_PERIOD := V_PREAUTH_PERIOD;
                 END IF;
               END IF;
               */
               /* Start Added by Dhiraj G on 06112012  for Pre -Auth Hold days changes */
               vt_preauth_hold :=
                  TO_NUMBER (SUBSTR (TRIM (NVL (v_preauth_exp_period, '000')),
                                     1,
                                     1
                                    )
                            );
               vt_preauth_period :=
                  TO_NUMBER (SUBSTR (TRIM (NVL (v_preauth_exp_period, '000')),
                                     2,
                                     2
                                    )
                            );

               BEGIN
                  SELECT NVL (cpm_pre_auth_exp_date, '000')
                    INTO vp_preauth_exp_period
                    FROM cms_prod_mast
                   WHERE cpm_prod_code = v_prod_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     vp_preauth_exp_period := '000';
                  WHEN OTHERS
                  THEN
                     vp_preauth_exp_period := '000';
               END;

               vp_preauth_hold :=
                       TO_NUMBER (SUBSTR (TRIM (vp_preauth_exp_period), 1, 1));
               vp_preauth_period :=
                       TO_NUMBER (SUBSTR (TRIM (vp_preauth_exp_period), 2, 2));

               IF vt_preauth_hold = vp_preauth_hold
               THEN
                  v_preauth_hold := vt_preauth_hold;

                  SELECT GREATEST (vt_preauth_period, vp_preauth_period)
                    INTO v_preauth_period
                    FROM DUAL;
               ELSE
                  IF vt_preauth_hold > vp_preauth_hold
                  THEN
                     v_preauth_hold := vt_preauth_hold;
                     v_preauth_period := vt_preauth_period;
                  ELSIF vt_preauth_hold < vp_preauth_hold
                  THEN
                     v_preauth_hold := vp_preauth_hold;
                     v_preauth_period := vp_preauth_period;
                  END IF;
               END IF;

               /*Comparing greatest from both with institution peroid Txn Peroid and product peroid  */
               BEGIN
                  SELECT NVL (cip_param_value, '000')
                    INTO vi_preauth_exp_period
                    FROM cms_inst_param
                   WHERE cip_inst_code = p_inst_code
                     AND cip_param_key = 'PRE-AUTH EXP PERIOD';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     vi_preauth_exp_period := '000';
                  WHEN OTHERS
                  THEN
                     vi_preauth_exp_period := '000';
               END;

               vi_preauth_hold :=
                       TO_NUMBER (SUBSTR (TRIM (vi_preauth_exp_period), 1, 1));
               --01122012
               vi_preauth_period :=
                       TO_NUMBER (SUBSTR (TRIM (vi_preauth_exp_period), 2, 2));

               --01122012
               IF v_preauth_hold = vi_preauth_hold
               THEN
                  v_preauth_hold := v_preauth_hold;

                  SELECT GREATEST (v_preauth_period, vi_preauth_period)
                    INTO v_preauth_period
                    FROM DUAL;
               ELSE
                  IF v_preauth_hold > vi_preauth_hold
                  THEN
                     v_preauth_hold := v_preauth_hold;
                     v_preauth_period := v_preauth_period;
                  ELSIF v_preauth_hold < vi_preauth_hold
                  THEN
                     v_preauth_hold := vi_preauth_hold;
                     v_preauth_period := vi_preauth_period;
                  END IF;
               END IF;

               /* End  Added by Dhiraj G on 06112012  for Pre -Auth Hold days changes */
               /*
                  preauth period will be added with transaction date based on preauth_hold
                  IF v_preauth_hold is '0'--'Minute'
                  '1'--'Hour'
                  '2'--'Day'
                 */
               /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */

               /*   --Commented on 21092012 Dhiraj Gaikwad
               IF P_DELIVERY_CHANNEL IN ('01', '02') AND P_TXN_CODE = '11' THEN
                 IF V_HOLD_DAYS IS NOT NULL THEN
                   IF V_HOLD_DAYS > V_PREAUTH_PERIOD THEN
                    V_PREAUTH_PERIOD := V_HOLD_DAYS;
                   END IF;
                 END IF;
               END IF; */
               IF p_delivery_channel IN ('01', '02') AND p_txn_code = '11'
               THEN
                  IF v_hold_days IS NOT NULL
                  THEN
                     IF v_preauth_hold IN ('0', '1')
                     THEN
                        v_preauth_period := v_hold_days;
                        v_preauth_hold := '2';
                     ELSIF v_preauth_hold = '2'
                     THEN
                        IF v_hold_days > v_preauth_period
                        THEN
                           v_preauth_period := v_hold_days;
                           v_preauth_hold := '2';
                        END IF;
                     END IF;
                  END IF;
               END IF;

               /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
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

               BEGIN
                  BEGIN
                     INSERT INTO cms_preauth_transaction
                                 (cpt_card_no, cpt_txn_amnt,
                                  cpt_expiry_date, cpt_sequence_no,
                                  cpt_preauth_validflag, cpt_inst_code,
                                  cpt_mbr_no, cpt_card_no_encr,
                                  cpt_completion_flag, cpt_approve_amt,
                                  cpt_rrn, cpt_txn_date, cpt_txn_time,
                                  cpt_terminalid, cpt_expiry_flag,
                                  cpt_totalhold_amt, cpt_transaction_flag,
                                  cpt_acct_no
                                 )
--Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                     VALUES      (v_hash_pan, v_tran_amt,
                                  v_preauth_date, '1',
                                  'Y', p_inst_code,
                                  p_mbr_numb, v_encr_pan,
                                  'N', v_tran_amt,
                                  p_rrn, p_tran_date, p_tran_time,
                                  p_term_id, 'N',
                                  v_tran_amt, 'N',
                                  v_acct_number
                                 );
--Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while inserting  CMS_PREAUTH_TRANSACTION '
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;

                  BEGIN
                     INSERT INTO cms_preauth_trans_hist
                                 (cph_card_no, cph_txn_amnt,
                                  cph_expiry_date, cph_sequence_no,
                                  cph_preauth_validflag, cph_inst_code,
                                  cph_mbr_no, cph_card_no_encr,
                                  cph_completion_flag, cph_approve_amt,
                                  cph_rrn, cph_txn_date, cph_terminalid,
                                  cph_expiry_flag, cph_transaction_flag,
                                  cph_totalhold_amt, cph_transaction_rrn,
                                  cph_acct_no
                                 )
--Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                     VALUES      (v_hash_pan, v_tran_amt,
--V_TOTAL_AMT,    -- Changed by Ganesh on 12-JAN-2013 for integrating openloop defect id 10122
                                  v_preauth_date, 1,
                                  'Y', p_inst_code,
                                  p_mbr_numb, v_encr_pan,
                                  'N', v_total_amt,
                                  p_rrn, p_tran_date, p_term_id,
                                  'N', v_trantype,
                                  v_tran_amt, p_rrn,
                                  v_acct_number
                                 );
--Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while inserting  CMS_PREAUTH_TRANS_HIST '
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';                   -- Server Declione
                     v_err_msg :=
                           'Problem while inserting preauth transaction details'
                        || SUBSTR (SQLERRM, 1, 300);
                     RAISE exp_reject_record;
               END;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';                         -- Server Declione
               v_err_msg :=
                     'Problem while inserting preauth transaction details'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

         ---Sn Updation of Usage limit and amount
         BEGIN
            SELECT ctc_atmusage_amt, ctc_posusage_amt, ctc_atmusage_limit,
                   ctc_posusage_limit, ctc_business_date,
                   ctc_preauthusage_limit
              INTO v_atm_usageamnt, v_pos_usageamnt, v_atm_usagelimit,
                   v_pos_usagelimit, v_business_date_tran,
                   v_preauth_usage_limit
              FROM cms_translimit_check
             WHERE ctc_inst_code = p_inst_code
               AND ctc_pan_code = v_hash_pan                       --P_card_no
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
                     'Error while selecting CMS_TRANSLIMIT_CHECK'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
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

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                                 'Error while updating CMS_TRANSLIMIT_CHECK1';
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating CMS_TRANSLIMIT_CHECK1'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
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

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                                 'Error while updating CMS_TRANSLIMIT_CHECK2';
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating CMS_TRANSLIMIT_CHECK2'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
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

                  IF v_tran_preauth_flag = 'Y'
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
                            ctc_mmposusage_amt = 0,
                            ctc_mmposusage_limit = 0,
                            ctc_preauthusage_limit = v_preauth_usage_limit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan
                        AND ctc_mbr_numb = p_mbr_numb;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                                 'Error while updating CMS_TRANSLIMIT_CHECK3';
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating CMS_TRANSLIMIT_CHECK3'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_pos_usagelimit := v_pos_usagelimit + 1;

                  IF v_tran_preauth_flag = 'Y'
                  THEN
                     v_preauth_usage_limit := v_preauth_usage_limit + 1;
                     v_pos_usageamnt :=
                          v_pos_usageamnt
                        + TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99'));
                  ELSE
                     IF p_txn_amt IS NULL
                     THEN
                        v_pos_usageamnt :=
                             v_pos_usageamnt
                           + TRIM (TO_CHAR (0, '99999999999999999.99'));
                     ELSE
                        v_pos_usageamnt :=
                             v_pos_usageamnt
                           + TRIM (TO_CHAR (v_tran_amt,
                                            '99999999999999999.99')
                                  );
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

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                                 'Error while updating CMS_TRANSLIMIT_CHECK4';
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating CMS_TRANSLIMIT_CHECK4'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Error while updating CMS_TRANSLIMIT_CHECK -  INNER LOOP'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while updating CMS_TRANSLIMIT_CHECK -  MAIN'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      ---En Updation of Usage limit and amount
      BEGIN
         SELECT cms_b24_respcde, cms_iso_respcde
--Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
         INTO   p_resp_code, v_cms_iso_respcde
           --Added by Besky on 15/03/13 for defect id 10576
         FROM   cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = TO_NUMBER (v_resp_cde);
      EXCEPTION
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
      --<< MAIN EXCEPTION >>
      WHEN exp_reject_record
      THEN
         ROLLBACK TO v_auth_savepoint;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_bal
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
            SELECT ctc_atmusage_limit, ctc_posusage_limit,
                   ctc_business_date, ctc_preauthusage_limit
              INTO v_atm_usagelimit, v_pos_usagelimit,
                   v_business_date_tran, v_preauth_usage_limit
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
                     'Error while selecting CMS_TRANSLIMIT_CHECK3'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
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
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating CMS_TRANSLIMIT_CHECK4'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
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
                              'Error while updating CMS_TRANSLIMIT_CHECK5'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         END;

         --Sn select response code and insert record into txn log dtl
         BEGIN
            p_resp_msg := v_err_msg;
            p_resp_code := v_resp_cde;

            -- Assign the response code to the out parameter
            SELECT cms_b24_respcde, cms_iso_respcde
--Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
            INTO   p_resp_code, v_cms_iso_respcde
              --Added by Besky on 15/03/13 for defect id 10576
            FROM   cms_response_mast
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
               ---ISO MESSAGE FOR DATABASE ERROR Server Declined
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
                         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                         ctd_network_id, ctd_interchange_feeamt,
                         ctd_merchant_zip, ctd_merchant_id,
                         ctd_country_code
                                         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
            ,            ctd_ins_user,
                         ctd_ins_date
                                   -- Added for defect id 10879 on 25-APR-2013
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
                         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                         p_network_id, p_interchange_feeamt,
                         p_merchant_zip, p_merc_id,
                         p_country_code
                                       /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
            ,            1,
                         SYSDATE   -- Added for defect id 10879 on 25-APR-2013
                        );

            p_resp_msg := v_err_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';                         -- Server Declined
               ROLLBACK;
               RETURN;
         END;
      WHEN OTHERS
      THEN
         ROLLBACK TO v_auth_savepoint;

         BEGIN
            SELECT ctc_atmusage_limit, ctc_posusage_limit,
                   ctc_business_date, ctc_preauthusage_limit
              INTO v_atm_usagelimit, v_pos_usagelimit,
                   v_business_date_tran, v_preauth_usage_limit
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
                     'Error while selecting CMS_TRANSLIMIT_CHECK4'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
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
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating CMS_TRANSLIMIT_CHECK6'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
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
                              'Error while updating CMS_TRANSLIMIT_CHECK7'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         END;

         --Sn select response code and insert record into txn log dtl
         BEGIN
            SELECT cms_b24_respcde, cms_iso_respcde
--Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
            INTO   p_resp_code, v_cms_iso_respcde
              --Added by Besky on 15/03/13 for defect id 10576
            FROM   cms_response_mast
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
               p_resp_code := '69';                         -- Server Declined
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
                         ctd_addr_verify_response,
                         ctd_internation_ind_response,
                                                      /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                                      ctd_network_id,
                         ctd_interchange_feeamt, ctd_merchant_zip,
                         ctd_merchant_id, ctd_country_code
                                                          /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
            ,            ctd_ins_user,
                         ctd_ins_date
                                   -- Added for defect id 10879 on 25-APR-2013
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
                         NULL,
                         NULL,
                              /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                              p_network_id,
                         p_interchange_feeamt, p_merchant_zip,
                         p_merc_id, p_country_code
                                                  /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
            ,            1,
                         SYSDATE   -- Added for defect id 10879 on 25-APR-2013
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';          -- Server Decline Response 220509
               ROLLBACK;
               RETURN;
         END;
   --En select response code and insert record into txn log dtl
   END;

   --- Sn create GL ENTRIES
   IF v_resp_cde = '1'
   THEN
      SAVEPOINT v_savepoint;
      --Sn find business date
      v_business_time := TO_CHAR (v_tran_date, 'HH24:MI');

      IF v_business_time > v_cutoff_time
      THEN
         v_business_date := TRUNC (v_tran_date) + 1;
      ELSE
         v_business_date := TRUNC (v_tran_date);
      END IF;

      --En find businesses date

      --Sn find prod code and card type and available balance for the card number
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
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';                      --Ineligible Transaction
            v_err_msg := 'Invalid Card ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting data from card Master for card number '
               || SQLERRM;
            RAISE exp_reject_record;
      END;

      --En find prod code and card type for the card number
      IF v_output_type = 'N'
      THEN
         --Balance Inquiry
         p_resp_msg := TO_CHAR (v_upd_amt);
      END IF;
   END IF;

   --En create GL ENTRIES

   --Sn create a entry in txn log
   BEGIN
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, terminal_id,
                   date_time, txn_code, txn_type, txn_mode,
                   txn_status,
                   response_code, business_date, business_time,
                   customer_card_no, topup_card_no, topup_acct_no,
                   topup_acct_type, bank_code,
                   total_amount,
                   rule_indicator, rulegroupid, mccode, currencycode,
                   addcharge, productid, categoryid, tips,
                   decline_ruleid, atm_name_location, auth_id, trans_desc,
                   amount,
                   preauthamount, partialamount, mccodegroupid,
                   currencycodegroupid, transcodegroupid, rules,
                   preauth_date, gl_upd_flag, system_trace_audit_no,
                   instcode, feecode, tranfee_amt, servicetax_amt,
                   cess_amt, cr_dr_flag, tranfee_cr_acctno,
                   tranfee_dr_acctno, tran_st_calc_flag,
                   tran_cess_calc_flag, tran_st_cr_acctno,
                   tran_st_dr_acctno, tran_cess_cr_acctno,
                   tran_cess_dr_acctno, customer_card_no_encr,
                   topup_card_no_encr, addr_verify_response, proxy_number,
                   reversal_code, customer_acct_no, acct_balance,
                   ledger_balance, internation_ind_response, response_id,
                   cardstatus,
                              --Added cardstatus insert in transactionlog by srinivasu.k
                                        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                              network_id, interchange_feeamt,
                   merchant_zip, merchant_id, country_code,
                                                           /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                                           fee_plan,
                   pos_verification,
                   --Added by Deepa on July 03 2012 to log the verification of POS
                   feeattachtype          -- Added by Trivikram on 05-Sep-2012
                                ,
                   add_ins_user,
                   error_msg       -- Added for defect id 10879 on 25-APR-2013
                  )
           VALUES (p_msg, p_rrn, p_delivery_channel, p_term_id,
                   v_business_date, p_txn_code, v_txn_type, p_txn_mode,
                   DECODE (v_cms_iso_respcde, '00', 'C', 'F'),
                   v_cms_iso_respcde,
                                     --Modified by Besky on 15/03/13 for defect id 10576
                                     p_tran_date, p_tran_time,
                   v_hash_pan, NULL, NULL,               --P_topup_acctno    ,
                   NULL,                                   --P_topup_accttype,
                        p_bank_code,
                   TRIM (TO_CHAR (v_total_amt, '99999999999999999.99')),
                   NULL, NULL, NULL, p_curr_code,
                   NULL,                                      -- P_add_charge,
                        v_prod_code, v_prod_cattype, p_tip_amt,
                   p_decline_ruleid, p_atmname_loc, v_auth_id, v_trans_desc,
                   TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99')),
                   NULL, NULL,
                              -- Partial amount (will be given for partial txn)
                              p_mcccode_groupid,
                   p_currcode_groupid, p_transcode_groupid, p_rules,
                   NULL, v_gl_upd_flag, p_stan,
                   p_inst_code, v_fee_code, v_fee_amt, v_servicetax_amount,
                   v_cess_amount, v_dr_cr_flag, v_fee_cracct_no,
                   v_fee_dracct_no, v_st_calc_flag,
                   v_cess_calc_flag, v_st_cracct_no,
                   v_st_dracct_no, v_cess_cracct_no,
                   v_cess_dracct_no, v_encr_pan,
                   NULL, NULL, v_proxunumber,
                   p_rvsl_code, v_acct_number, v_acct_balance,
                   v_ledger_bal, p_international_ind,
                                                     --Added by Deepa on July 03 2012 to log International Indicator
                                                     v_resp_cde,
                   v_applpan_cardstat,
                                      --Added cardstatus insert in transactionlog by srinivasu.k
                                                        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                      p_network_id, p_interchange_feeamt,
                   p_merchant_zip, p_merc_id, p_country_code,
                                                             /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                                             v_fee_plan,
                   --Added by Deepa for Fee Plan on June 10 2012
                   p_pos_verfication,
                   --Added by Deepa on July 03 2012 to log the verification of POS
                   v_feeattach_type       -- Added by Trivikram on 05-Sep-2012
                                   ,
                   1,
                   v_err_msg       -- Added for defect id 10879 on 25-APR-2013
                  );

      p_capture_date := v_business_date;
      p_auth_id := v_auth_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code := '69';                              -- Server Declione
         p_resp_msg :=
               'Problem while inserting data into transaction log  '
            || SUBSTR (SQLERRM, 1, 300);
   END;
--En create a entry in txn log
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code := '69';                                 -- Server Declined
      p_resp_msg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error;