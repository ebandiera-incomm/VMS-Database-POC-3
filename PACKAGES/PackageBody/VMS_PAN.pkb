set define off;
create or replace
PACKAGE BODY                      VMSCMS.VMS_PAN
IS
   PROCEDURE get_card_status (p_inst_code_in            IN     NUMBER,
                              p_delivery_channel_in     IN     VARCHAR2,
                              p_txn_code_in             IN     VARCHAR2,
                              p_rrn_in                  IN     VARCHAR2,
                              p_cust_id_in              IN     VARCHAR2,
                              p_partner_id_in           IN     VARCHAR2,
                              p_trandate_in             IN     VARCHAR2,
                              p_trantime_in             IN     VARCHAR2,
                              p_curr_code_in            IN     VARCHAR2,
                              p_rvsl_code_in            IN     VARCHAR2,
                              p_msg_type_in             IN     VARCHAR2,
                              p_ip_addr_in              IN     VARCHAR2,
                              p_ani_in                  IN     VARCHAR2,
                              p_dni_in                  IN     VARCHAR2,
                              p_device_mob_no_in        IN     VARCHAR2,
                              p_device_id_in            IN     VARCHAR2,
                              p_pan_code_in             IN     VARCHAR2,
                              p_uuid_in                 IN     VARCHAR2,
                              p_os_name_in              IN     VARCHAR2,
                              p_os_version_in           IN     VARCHAR2,
                              p_gps_coordinates_in      IN     VARCHAR2,
                              p_display_resolution_in   IN     VARCHAR2,
                              p_physical_memory_in      IN     VARCHAR2,
                              p_app_name_in             IN     VARCHAR2,
                              p_app_version_in          IN     VARCHAR2,
                              p_session_id_in           IN     VARCHAR2,
                              p_device_country_in       IN     VARCHAR2,
                              p_device_region_in        IN     VARCHAR2,
                              p_ip_country_in           IN     VARCHAR2,
                              p_proxy_flag_in           IN     VARCHAR2,
                              p_resp_code_out              OUT VARCHAR2,
                              p_respmsg_out                OUT VARCHAR2,
                              p_card_stat_desc_out         OUT VARCHAR2,
                              p_replaced_card_out          OUT VARCHAR2,
                              p_previous_pan_out           OUT VARCHAR2)
   IS
    /************************************************************************************************
    * Modified By      : Venkata Naga Sai S
    * Modified Date    : 05-SEP-2019
    * Modified For     : VMS-1067
    * Reviewer         : Saravanakumar
    * Release Number   : R20
	
	
	* Modified By      : Mohan Kumar E
    * Modified Date    : 24-JULY-2023
    * Purpose          : VMS-7196 - Funding on Activation for Replacements
    * Reviewer         : Pankaj S.
    * Release Number   : R83
    ********************************************************************************************/


      l_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no           cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code         cms_appl_pan.cap_prod_code%TYPE;
      l_prod_cattype      cms_appl_pan.cap_card_type%TYPE;
      l_card_stat         cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date        cms_appl_pan.cap_expry_date%TYPE;
      l_active_date       cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
      l_comb_hash         pkg_limits_check.type_hash;
      l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp         TIMESTAMP;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
      l_acct_type         cms_acct_mast.cam_type_code%TYPE;
      l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type    transactionlog.feeattachtype%TYPE;
      l_tranfee_amt       transactionlog.tranfee_amt%TYPE;
      l_total_amt         cms_acct_mast.cam_acct_bal%TYPE;
      l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
      l_repl_flag         cms_appl_pan.cap_repl_flag%TYPE;
      l_errmsg            VARCHAR2 (500);
      exp_reject_record   EXCEPTION;
   BEGIN
      BEGIN
         p_resp_code_out := '00';
         p_respmsg_out := 'success';

         --Sn pan details procedure call
         BEGIN
            SELECT cap_pan_code,
                   cap_pan_code_encr,
                   cap_acct_no,
                   cap_card_stat,
                   cap_prod_code,
                   cap_card_type,
                   cap_expry_date,
                   cap_active_date,
                   cap_prfl_code,
                   cap_proxy_number,
                   nvl(cap_repl_flag,0)
              INTO l_hash_pan,
                   l_encr_pan,
                   l_acct_no,
                   l_card_stat,
                   l_prod_code,
                   l_prod_cattype,
                   l_expry_date,
                   l_active_date,
                   l_prfl_code,
                   l_proxynumber,
                   l_repl_flag
              FROM cms_appl_pan
             WHERE     cap_inst_code = p_inst_code_in
                   AND cap_pan_code = gethash (p_pan_code_in)
                   AND cap_mbr_numb = '000';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_resp_code_out := '21';
               l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                  'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En pan details procedure call
         IF l_card_stat = 0
         THEN
            IF l_active_date IS NULL
            THEN
               p_card_stat_desc_out := 'INACTIVE';
            ELSE
               p_card_stat_desc_out := 'BLOCKED';
            END IF;
         ELSE
            BEGIN
               SELECT ccs_stat_desc
                 INTO p_card_stat_desc_out
                 FROM cms_card_stat
                WHERE ccs_stat_code = l_card_stat;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code_out := '12';
                  l_errmsg :=
                     'Error while selcting card status description'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

         -- Sn Transaction Details  procedure call
         BEGIN
            vmscommon.get_transaction_details (p_inst_code_in,
                                               p_delivery_channel_in,
                                               p_txn_code_in,
                                               l_cr_dr_flag,
                                               l_txn_type,
                                               l_txn_desc,
                                               l_prfl_flag,
                                               l_preauth_flag,
                                               l_login_txn,
                                               l_preauth_type,
                                               l_dup_rrn_check,
                                               p_resp_code_out,
                                               l_errmsg);

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                  'Error from Transaction Details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En Transaction Details  procedure call

         -- Sn validating Date Time RRN
         IF l_dup_rrn_check = 'Y' THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out);

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                  'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         END IF;
         -- En validating Date Time RRN

         --SN : CMSAUTH check
         BEGIN
            vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
                                                  p_msg_type_in,
                                                  p_rrn_in,
                                                  p_delivery_channel_in,
                                                  p_txn_code_in,
                                                  0,
                                                  p_trandate_in,
                                                  p_trantime_in,
                                                  '00',
                                                  l_txn_type,
                                                  p_pan_code_in,
                                                  l_hash_pan,
                                                  l_encr_pan,
                                                  l_acct_no,
                                                  l_card_stat,
                                                  l_expry_date,
                                                  l_prod_code,
                                                  l_prod_cattype,
                                                  l_prfl_flag,
                                                  l_prfl_code,
                                                  l_txn_type,
                                                  p_curr_code_in,
                                                  l_preauth_flag,
                                                  l_txn_desc,
                                                  l_cr_dr_flag,
                                                  l_login_txn,
                                                  p_resp_code_out,
                                                  l_errmsg,
                                                  l_comb_hash,
                                                  l_auth_id,
                                                  l_fee_code,
                                                  l_fee_plan,
                                                  l_feeattach_type,
                                                  l_tranfee_amt,
                                                  l_total_amt,
                                                  l_preauth_type);

            IF l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                  'Error from authorize_nonfinancial_txn '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

    IF l_repl_flag <> 0 THEN

             p_replaced_card_out := 'true';

         BEGIN
            SELECT fn_dmaps_main (chr_pan_code_encr)
              INTO p_previous_pan_out
              FROM cms_htlst_reisu
             WHERE     chr_inst_code = p_inst_code_in
                   AND chr_new_pan = l_hash_pan
                   AND chr_reisu_cause = 'R'
                   AND chr_pan_code_encr IS NOT NULL;


         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_previous_pan_out := p_pan_code_in;

            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                  'Error while selecting old pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
    ELSE
      p_replaced_card_out := 'false';
    END IF;

         p_resp_code_out := '1';
      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE     cms_inst_code = p_inst_code_in
                AND cms_delivery_channel = p_delivery_channel_in
                AND cms_response_id = TO_NUMBER (p_resp_code_out);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_errmsg :=
                  'Problem while selecting respose code'
               || p_resp_code_out
               || ' is-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
      END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_channel_in
               || p_txn_code_in
               || p_pan_code_in
               || p_rrn_in
               || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
               'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN
         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_TYPE_CODE
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM CMS_ACCT_MAST
          WHERE CAM_INST_CODE = p_inst_code_in AND CAM_ACCT_NO = l_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card /Account ';
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg := 'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      IF p_resp_code_out <> '00'
      THEN
         p_card_stat_desc_out := '';
         p_replaced_card_out := '';
         p_previous_pan_out := '';
         p_respmsg_out := l_errmsg;
      END IF;

      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     NULL,
                                     NULL,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_prod_cattype,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
               'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   END get_card_status;

   PROCEDURE get_pin (p_inst_code_in            IN     NUMBER,
                      p_delivery_channel_in     IN     VARCHAR2,
                      p_txn_code_in             IN     VARCHAR2,
                      p_rrn_in                  IN     VARCHAR2,
                      p_cust_id_in              IN     VARCHAR2,
                      p_partner_id_in           IN     VARCHAR2,
                      p_trandate_in             IN     VARCHAR2,
                      p_trantime_in             IN     VARCHAR2,
                      p_curr_code_in            IN     VARCHAR2,
                      p_rvsl_code_in            IN     VARCHAR2,
                      p_msg_type_in             IN     VARCHAR2,
                      p_ip_addr_in              IN     VARCHAR2,
                      p_ani_in                  IN     VARCHAR2,
                      p_dni_in                  IN     VARCHAR2,
                      p_device_mob_no_in        IN     VARCHAR2,
                      p_device_id_in            IN     VARCHAR2,
                      p_pan_code_in             IN     VARCHAR2,
                      p_uuid_in                 IN     VARCHAR2,
                      p_os_name_in              IN     VARCHAR2,
                      p_os_version_in           IN     VARCHAR2,
                      p_gps_coordinates_in      IN     VARCHAR2,
                      p_display_resolution_in   IN     VARCHAR2,
                      p_physical_memory_in      IN     VARCHAR2,
                      p_app_name_in             IN     VARCHAR2,
                      p_app_version_in          IN     VARCHAR2,
                      p_session_id_in           IN     VARCHAR2,
                      p_device_country_in       IN     VARCHAR2,
                      p_device_region_in        IN     VARCHAR2,
                      p_ip_country_in           IN     VARCHAR2,
                      p_proxy_flag_in           IN     VARCHAR2,
                      p_resp_code_out              OUT VARCHAR2,
                      p_respmsg_out                OUT VARCHAR2,
                      p_ipin_offset_out            OUT VARCHAR2)
   IS
      l_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no           cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code         cms_appl_pan.cap_prod_code%TYPE;
      l_prod_cattype      cms_appl_pan.cap_card_type%TYPE;
      l_card_stat         cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date        cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
      l_comb_hash         pkg_limits_check.type_hash;
      l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp         TIMESTAMP;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
      l_acct_type         cms_acct_mast.cam_type_code%TYPE;
      l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type    transactionlog.feeattachtype%TYPE;
      l_tranfee_amt       transactionlog.tranfee_amt%TYPE;
      l_total_amt         cms_acct_mast.cam_acct_bal%TYPE;
      l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
      l_errmsg            VARCHAR2 (500);
      exp_reject_record   EXCEPTION;
   BEGIN
      BEGIN
         p_resp_code_out := '00';
         p_respmsg_out := 'success';

         --Sn find card detail
         BEGIN
            SELECT cap_pan_code,
                   cap_pan_code_encr,
                   cap_acct_no,
                   cap_card_stat,
                   cap_prod_code,
                   cap_card_type,
                   cap_expry_date,
                   cap_ipin_offset,
                   cap_prfl_code,
                   cap_proxy_number
              INTO l_hash_pan,
                   l_encr_pan,
                   l_acct_no,
                   l_card_stat,
                   l_prod_code,
                   l_prod_cattype,
                   l_expry_date,
                   p_ipin_offset_out,
                   l_prfl_code,
                   l_proxynumber
              FROM cms_appl_pan
             WHERE     cap_inst_code = p_inst_code_in
                   AND cap_pan_code = gethash (p_pan_code_in)
                   AND cap_mbr_numb = '000';

            IF p_ipin_offset_out IS NULL
            THEN
               p_resp_code_out := '101';
               l_errmsg := 'Pin Generation Process Not done';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN NO_DATA_FOUND
            THEN
               p_resp_code_out := '21';
               l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                  'Problem while selecting CMS_APPL_PAN  '
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

         --En find card detail


         -- Sn Transaction Details  procedure call
         BEGIN
            vmscommon.get_transaction_details (p_inst_code_in,
                                               p_delivery_channel_in,
                                               p_txn_code_in,
                                               l_cr_dr_flag,
                                               l_txn_type,
                                               l_txn_desc,
                                               l_prfl_flag,
                                               l_preauth_flag,
                                               l_login_txn,
                                               l_preauth_type,
                                               l_dup_rrn_check,
                                               p_resp_code_out,
                                               l_errmsg);

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                  'Error from Transaction Details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En Transaction Details  procedure call

         -- Sn validating Date Time RRN
         IF l_dup_rrn_check = 'Y' THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out);

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                  'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         END IF;
         -- En validating Date Time RRN

         --SN : authorize_nonfinancial_txn procedure call
         BEGIN
            vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
                                                  p_msg_type_in,
                                                  p_rrn_in,
                                                  p_delivery_channel_in,
                                                  p_txn_code_in,
                                                  0,
                                                  p_trandate_in,
                                                  p_trantime_in,
                                                  '00',
                                                  l_txn_type,
                                                  p_pan_code_in,
                                                  l_hash_pan,
                                                  l_encr_pan,
                                                  l_acct_no,
                                                  l_card_stat,
                                                  l_expry_date,
                                                  l_prod_code,
                                                  l_prod_cattype,
                                                  l_prfl_flag,
                                                  l_prfl_code,
                                                  l_txn_type,
                                                  p_curr_code_in,
                                                  l_preauth_flag,
                                                  l_txn_desc,
                                                  l_cr_dr_flag,
                                                  l_login_txn,
                                                  p_resp_code_out,
                                                  l_errmsg,
                                                  l_comb_hash,
                                                  l_auth_id,
                                                  l_fee_code,
                                                  l_fee_plan,
                                                  l_feeattach_type,
                                                  l_tranfee_amt,
                                                  l_total_amt,
                                                  l_preauth_type);

            IF l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                  'Error from authorize_nonfinancial_txn '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         p_resp_code_out := '1';
      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE     cms_inst_code = p_inst_code_in
                AND cms_delivery_channel = p_delivery_channel_in
                AND cms_response_id = TO_NUMBER (p_resp_code_out);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_errmsg :=
                  'Problem while selecting respose code'
               || p_resp_code_out
               || ' is-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
      END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_channel_in
               || p_txn_code_in
               || p_pan_code_in
               || p_rrn_in
               || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
               'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN
         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_TYPE_CODE
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM CMS_ACCT_MAST
          WHERE CAM_INST_CODE = p_inst_code_in AND CAM_ACCT_NO = l_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card /Account';
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg := 'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      IF p_resp_code_out <> '00'
      THEN
         p_ipin_offset_out := '';
         p_respmsg_out := l_errmsg;
      END IF;

      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     NULL,
                                     NULL,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_prod_cattype,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
               'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   END get_pin;

PROCEDURE update_card_status(p_inst_code_in             IN  NUMBER,
                             p_delivery_channel_in      IN  VARCHAR2,
                             p_txn_code_in              IN  VARCHAR2,
                             p_rrn_in                   IN  VARCHAR2,
                             p_cust_id_in               IN  VARCHAR2,
                             p_partner_id_in            IN  VARCHAR2,
                             p_trandate_in              IN  VARCHAR2,
                             p_trantime_in              IN  VARCHAR2,
                             p_curr_code_in             IN  VARCHAR2,
                             p_rvsl_code_in             IN  VARCHAR2,
                             p_msg_type_in              IN  VARCHAR2,
                             p_ip_addr_in               IN  VARCHAR2,
                             p_ani_in                   IN  VARCHAR2,
                             p_dni_in                   IN  VARCHAR2,
                             p_device_mob_no_in         IN  VARCHAR2,
                             p_device_id_in             IN  VARCHAR2,
                             p_uuid_in                  IN  VARCHAR2,
                             p_os_name_in               IN  VARCHAR2,
                             p_os_version_in            IN  VARCHAR2,
                             p_gps_coordinates_in       IN  VARCHAR2,
                             p_display_resolution_in    IN  VARCHAR2,
                             p_physical_memory_in       IN  VARCHAR2,
                             p_app_name_in              IN  VARCHAR2,
                             p_app_version_in           IN  VARCHAR2,
                             p_session_id_in            IN  VARCHAR2,
                             p_device_country_in        IN  VARCHAR2,
                             p_device_region_in         IN  VARCHAR2,
                             p_ip_country_in            IN  VARCHAR2,
                             p_proxy_flag_in            IN  VARCHAR2,
                             p_pan_code_in              IN  VARCHAR2,
                             p_card_status_in           IN  VARCHAR2,
                             p_resp_code_out            OUT VARCHAR2,
                             p_respmsg_out              OUT VARCHAR2
                             )
AS
      l_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no           cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code         cms_appl_pan.cap_prod_code%TYPE;
      l_prod_cattype      cms_appl_pan.cap_card_type%TYPE;
      l_card_stat         cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date        cms_appl_pan.cap_expry_date%TYPE;
      l_active_date       cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_comb_hash         pkg_limits_check.type_hash;
      l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp         TIMESTAMP;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
      l_acct_type         cms_acct_mast.cam_type_code%TYPE;
      l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type    transactionlog.feeattachtype%TYPE;
      l_tranfee_amt       transactionlog.tranfee_amt%TYPE;
      l_total_amt         cms_acct_mast.cam_acct_bal%TYPE;
      l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
      l_appl_code         cms_appl_pan.cap_appl_code%TYPE;
	  l_REMRK             VARCHAR2(100);
	  l_cap_prod_catg     cms_appl_pan.cap_prod_catg%TYPE;
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
      l_KYC_flag          CMS_CAF_INFO_ENTRY.CCI_KYC_FLAG%TYPE;
      l_txn_code_in       cms_transaction_mast.ctm_tran_code%TYPE;
      l_RESONCODE         CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
      l_dup_check         NUMBER(1);
      l_errmsg            VARCHAR2 (500);
      l_prod_type         cms_product_param.cpp_product_type%TYPE;
      exp_reject_record   EXCEPTION;

/********************************************************************************
    * Modified By      : Rajan Devakotta
    * Modified Date    : 27/Nov/2021
    * Purpose          : VMS-5361 - VMS Support Status Chnage from CHW(On Hold)
    * Reviewer         : Venkat Singamneni.
    * Release Number   : R55

 *********************************************************************************/
   BEGIN
      BEGIN
         p_resp_code_out := '00';
         p_respmsg_out := 'success';
		     l_REMRK    := 'Online Card Status Change';


         IF p_delivery_channel_in  IN( '07' , '10') THEN
            IF p_card_status_in   IN ( '2' , '3', '6' ) THEN
                l_txn_code_in := '05';
            ELSIF  p_card_status_in = '1' THEN
                l_txn_code_in := '06';
            END IF;
         ELSIF p_delivery_channel_in = '13' THEN
            IF p_card_status_in   IN ( '2' , '3' ) THEN
                l_txn_code_in := '73';
            ELSIF  p_card_status_in = '1' THEN
                l_txn_code_in := '74';
            END IF;
         END IF;

--Sn pan   details
         BEGIN
          SELECT cap_pan_code, cap_pan_code_encr,cap_acct_no,
                 cap_card_stat, cap_prod_code, cap_card_type,
                 cap_expry_date, cap_active_date, cap_prfl_code,
                 cap_proxy_number,cap_appl_code,cap_prod_catg
            INTO l_hash_pan, l_encr_pan, l_acct_no,
                 l_card_stat, l_prod_code, l_prod_cattype,
                 l_expry_date, l_active_date, l_prfl_code,
                 l_proxynumber,l_appl_code, l_cap_prod_catg
            FROM cms_appl_pan
           WHERE cap_inst_code = p_inst_code_in
             AND cap_mbr_numb = '000'
             AND cap_pan_code  = gethash(p_pan_code_in);
         EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' || gethash(p_pan_code_in);
                 RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

--Sn pan  details

-- Sn Transaction Details  procedure call
         BEGIN
            vmscommon.get_transaction_details (p_inst_code_in,
                                               p_delivery_channel_in,
                                               l_txn_code_in,
                                               l_cr_dr_flag,
                                               l_txn_type,
                                               l_txn_desc,
                                               l_prfl_flag,
                                               l_preauth_flag,
                                               l_login_txn,
                                               l_preauth_type,
                                               l_dup_rrn_check,
                                               p_resp_code_out,
                                               l_errmsg
                                              );
            IF (p_delivery_channel_in = '10' AND l_txn_code_in = '05' AND p_card_status_in = '6')
            THEN
               l_txn_desc := 'UPDATE CARD STATUS TO ON HOLD';
            END IF;
            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                  'Error from Transaction Details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En Transaction Details  procedure call

         -- Sn validating Date Time RRN
         IF l_dup_rrn_check = 'Y' THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out);

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                  'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         END IF;
         -- En validating Date Time RRN


	BEGIN
      IF l_card_stat = '3'
      THEN
         SELECT COUNT (1)
           INTO l_dup_check
           FROM cms_htlst_reisu
          WHERE chr_inst_code = p_inst_code_in
            AND chr_pan_code = l_hash_pan
            AND chr_reisu_cause = 'R'
            AND chr_new_pan IS NOT NULL;

         IF l_dup_check > 0
         THEN
            l_errmsg := 'Only closing operation allowed for damage card';
            SELECT DECODE (p_delivery_channel_in, '10', '159', '13', '159', '07', '160')
             INTO p_resp_code_out
             FROM DUAL;
            RAISE exp_reject_record;
         END IF;

      END IF;
   EXCEPTION

     WHEN exp_reject_record
     THEN
          RAISE exp_reject_record;

      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
               'Error while selecting damage card details '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
   END;


    IF l_card_stat = '4' THEN
     p_resp_code_out := '14';
     l_errmsg        := 'Card Restricted';
     RAISE EXP_REJECT_RECORD;
    END IF;

    -- do not allow on hold status update for Expired card  VMS-5361
    IF l_card_stat = '7' AND l_txn_code_in = '05' AND p_card_status_in = '6' THEN
     p_resp_code_out := '13';   
     l_errmsg        := 'Card is expired, further activity is not allowed';
     RAISE EXP_REJECT_RECORD;
    END IF;

   -- allow on hold status update for Lost card   VMS-5361
    IF l_card_stat = '2' AND l_txn_code_in <> '06' AND p_card_status_in <> '6' AND l_txn_code_in <> '74' THEN
     p_resp_code_out := '41';
     l_errmsg        := 'Lost Card';
     RAISE EXP_REJECT_RECORD;
    END IF;

    IF l_card_stat = '9' THEN
     p_resp_code_out := '46';
     l_errmsg        := 'Closed Card';
     RAISE EXP_REJECT_RECORD;
    END IF;

    -- allow on hold status update for inactive card VMS-5361
    IF ((l_txn_code_in = '05' AND p_card_status_in <> '6')  OR l_txn_code_in = '73') AND l_card_stat = '0'   THEN
     p_resp_code_out := '10';
     l_errmsg        := 'Card Already Blocked';
     RAISE EXP_REJECT_RECORD;
    END IF;

    IF( (l_txn_code_in = '06' AND l_card_stat = '1' ) or  (l_txn_code_in = '74' AND l_card_stat = '1' )) THEN
     p_resp_code_out := '9';
     l_errmsg        := 'Card Already Activated';
     RAISE EXP_REJECT_RECORD;
    END IF;


   IF l_txn_code_in = '05' OR l_txn_code_in = '73' THEN
     l_RESONCODE := 43;
    ELSE
     l_RESONCODE := 54;
    END IF;



         --SN : authorize_nonfinancial_txn check
         BEGIN
            vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
                                                  p_msg_type_in,
                                                  p_rrn_in,
                                                  p_delivery_channel_in,
                                                  l_txn_code_in,
                                                  0,
                                                  p_trandate_in,
                                                  p_trantime_in,
                                                  '00',
                                                  l_txn_type,
                                                  p_pan_code_in,
                                                  l_hash_pan,
                                                  l_encr_pan,
                                                  l_acct_no,
                                                  l_card_stat,
                                                  l_expry_date,
                                                  l_prod_code,
                                                  l_prod_cattype,
                                                  l_prfl_flag,
                                                  l_prfl_code,
                                                  l_txn_type,
                                                  p_curr_code_in,
                                                  l_preauth_flag,
                                                  l_txn_desc,
                                                  l_cr_dr_flag,
                                                  l_login_txn,
                                                  p_resp_code_out,
                                                  l_errmsg,
                                                  l_comb_hash,
                                                  l_auth_id,
                                                  l_fee_code,
                                                  l_fee_plan,
                                                  l_feeattach_type,
                                                  l_tranfee_amt,
                                                  l_total_amt,
                                                  l_preauth_type
                                                 );

            IF l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error from authorize_nonfinancial_txn '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
    --SN : authorize_nonfinancial_txn check


	BEGIN
           SELECT UPPER (NVL (cpp_product_type, 'O'))
             INTO l_prod_type
             FROM cms_product_param
            WHERE cpp_prod_code = l_prod_code AND cpp_inst_code = p_inst_code_in;
        EXCEPTION
           WHEN OTHERS
           THEN
              p_resp_code_out := '21';
              l_errmsg :=
                 'Error While selecting the product type' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
    END;


	IF l_card_stat = '1'  THEN

        BEGIN

            SELECT  CCI_KYC_FLAG
            INTO l_KYC_FLAG
            FROM  CMS_CAF_INFO_ENTRY
            WHERE CCI_INST_CODE = p_inst_code_in
            AND CCI_APPL_CODE = to_char(l_appl_code);


        EXCEPTION
          WHEN OTHERS THEN
           l_errmsg   := 'Error while selecting KYC flag ' ||
                       SUBSTR(SQLERRM, 1, 200);
            p_resp_code_out := '21';
            RAISE EXP_REJECT_RECORD;
        END;

        IF l_KYC_FLAG not in ('Y','P','O','I')
             AND l_prod_type<>'C'
        THEN

            l_card_stat := '13';

        END IF;


     END IF;



	BEGIN

    UPDATE CMS_APPL_PAN
      SET CAP_CARD_STAT = p_card_status_in,
      cap_active_date =decode(p_card_status_in,1,nvl(cap_active_date,sysdate),cap_active_date)
    WHERE CAP_INST_CODE = p_inst_code_in AND CAP_PAN_CODE = l_hash_pan AND
         CAP_MBR_NUMB = '000';

    IF SQL%ROWCOUNT != 1 THEN
     p_resp_code_out := '21';
     l_errmsg        := 'Problem in updation of status for pan ' || p_pan_code_in || '.';
     RAISE EXP_REJECT_RECORD;
    END IF;

    IF l_txn_code_in IN ('06', '74') THEN

       BEGIN
         UPDATE CMS_PIN_CHECK
            SET CPC_PIN_COUNT = 0,
                CPC_LUPD_DATE = TO_DATE(p_trandate_in, 'YYYY/MM/DD')
          WHERE CPC_INST_CODE = p_inst_code_in AND CPC_PAN_CODE = l_hash_pan;

         EXCEPTION
        WHEN OTHERS THEN
             p_resp_code_out := '21';
             l_errmsg   := 'Error ocurs while updating PIN_CHECK-- ' ||
                        SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
         END;

    END IF;
  EXCEPTION
    WHEN EXP_REJECT_RECORD
    THEN
     RAISE EXP_REJECT_RECORD;

    WHEN OTHERS THEN
     p_resp_code_out := '21';
     l_errmsg   := 'Error ocurs while updating card status-- ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;


  BEGIN
    INSERT INTO CMS_PAN_SPPRT
     (CPS_INST_CODE,
      CPS_PAN_CODE,
      CPS_MBR_NUMB,
      CPS_PROD_CATG,
      CPS_SPPRT_KEY,
      CPS_SPPRT_RSNCODE,
      CPS_FUNC_REMARK,
      CPS_INS_USER,
      CPS_LUPD_USER,
      CPS_CMD_MODE,
      CPS_PAN_CODE_ENCR)
    VALUES
     (p_inst_code_in,
      l_HASH_PAN,
      '000',
      l_CAP_PROD_CATG,
      DECODE(l_txn_code_in,
            '05',
            'BLOCK',
            '06',
            'DEBLOCK',
			'73',
			'BLOCK',
			'74',
			'DEBLOCK'
            ),
      l_RESONCODE,
      l_REMRK,
      '1',
      '1',
      0,
      l_ENCR_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     p_resp_code_out := '21';
     l_errmsg   := 'Error while inserting records into card support master' ||
                SUBSTR(SQLERRM, 1, 200);

     RAISE EXP_REJECT_RECORD;
  END;
  --En create a record in pan spprt

    BEGIN
              sp_log_cardstat_chnge (p_inst_code_in,
              l_HASH_PAN,
              l_ENCR_PAN ,
              l_auth_id,
              case when p_card_status_in= '2'
              then '48'
              when p_card_status_in= '3'
              then '41'
              when p_card_status_in= '6'
              then '74'
              when p_card_status_in= '1'
              then '01' end,
              p_rrn_in,
              p_trandate_in,
              p_trantime_in,
              p_resp_code_out,
              l_errmsg
              );

              IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
              THEN
                   RAISE EXP_REJECT_RECORD;
              END IF;

    EXCEPTION
          WHEN EXP_REJECT_RECORD
          THEN
                  RAISE;
          WHEN OTHERS
          THEN
                  p_resp_code_out := '21';
                  l_errmsg := 'Error while logging system initiated card status change '
                  || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
    END;


         p_resp_code_out := '1';
      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE     cms_inst_code = p_inst_code_in
                AND cms_delivery_channel = p_delivery_channel_in
                AND cms_response_id = TO_NUMBER (p_resp_code_out);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_errmsg :=
                  'Problem while selecting respose code'
               || p_resp_code_out
               || ' is-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
      END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_channel_in
               || l_txn_code_in
               || p_pan_code_in
               || p_rrn_in
               || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
               'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN
         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_TYPE_CODE
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM CMS_ACCT_MAST
          WHERE CAM_INST_CODE = p_inst_code_in AND CAM_ACCT_NO = l_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card /Account ';
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg := 'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      IF p_resp_code_out <> '00'
      THEN
          p_respmsg_out := l_errmsg;
      END IF;

      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     l_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_prod_cattype,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
               'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
END update_card_status;


PROCEDURE update_pin (
    p_inst_code_in            IN       NUMBER,
   p_delivery_chnl_in        IN       VARCHAR2,
   p_txn_code_in             IN       VARCHAR2,
   p_rrn_in                  IN       VARCHAR2,
   p_cust_id_in              IN       NUMBER,
   p_appl_id_in              IN       VARCHAR2,
   p_partner_id_in           IN       VARCHAR2,
   p_tran_date_in            IN       VARCHAR2,
   p_tran_time_in            IN       VARCHAR2,
   p_curr_code_in            IN       VARCHAR2,
   p_revrsl_code_in          IN       VARCHAR2,
   p_msg_type_in             IN       VARCHAR2,
   p_ip_addr_in              IN       VARCHAR2,
   p_ani_in                  IN       VARCHAR2,
   p_dni_in                  IN       VARCHAR2,
   p_device_mobno_in         IN       VARCHAR2,
   p_device_id_in            IN       VARCHAR2,
   p_uuid_in                 IN       VARCHAR2,
   p_osname_in               IN       VARCHAR2,
   p_osversion_in            IN       VARCHAR2,
   p_gps_coordinates_in      IN       VARCHAR2,
   p_display_resolution_in   IN       VARCHAR2,
   p_physical_memory_in      IN       VARCHAR2,
   p_appname_in              IN       VARCHAR2,
   p_appversion_in           IN       VARCHAR2,
   p_sessionid_in            IN       VARCHAR2,
   p_device_country_in       IN       VARCHAR2,
   p_device_region_in        IN       VARCHAR2,
   p_ipcountry_in            IN       VARCHAR2,
   p_proxy_flag_in           IN       VARCHAR2,
   p_pan_code_in             IN       VARCHAR2,
   p_last_four_pan           IN       VARCHAR2,
   p_pin_in                  IN       VARCHAR2,
   p_starter_pan_code_in     IN       VARCHAR2,
   p_gpr_pan_code_in         IN       VARCHAR2,
   p_gpr_pin_in              IN       VARCHAR2,
   p_call_log_id_in          IN       VARCHAR2,
   p_key_id_in               IN       VARCHAR2,
   p_gprkey_id_in            IN       VARCHAR2,
   p_stater_hash_pan_out     OUT      VARCHAR2,
   p_resp_code_out           OUT      VARCHAR2,
   p_resp_msg_out            OUT      VARCHAR2
)
AS
   l_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   l_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   l_acct_no                cms_acct_mast.cam_acct_no%TYPE;
   l_acct_bal               cms_acct_mast.cam_acct_bal%TYPE;
   l_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
   l_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   l_prod_cattype           cms_appl_pan.cap_card_type%TYPE;
   l_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   l_expry_date             cms_appl_pan.cap_expry_date%TYPE;
   l_active_date            cms_appl_pan.cap_expry_date%TYPE;
   l_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
   l_cr_dr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_txn_type               cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
   l_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_comb_hash              pkg_limits_check.type_hash;
   l_auth_id                cms_transaction_log_dtl.ctd_auth_id%TYPE;
   l_timestamp              TIMESTAMP;
   l_preauth_flag           cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   l_dup_rrn_check          cms_transaction_mast.ctm_rrn_check%TYPE;
   l_acct_type              cms_acct_mast.cam_type_code%TYPE;
   l_login_txn              cms_transaction_mast.ctm_login_txn%TYPE;
   l_fee_code               cms_fee_mast.cfm_fee_code%TYPE;
   l_fee_plan               cms_fee_feeplan.cff_fee_plan%TYPE;
   l_feeattach_type         transactionlog.feeattachtype%TYPE;
   l_tranfee_amt            transactionlog.tranfee_amt%TYPE;
   l_total_amt              cms_acct_mast.cam_acct_bal%TYPE;
   l_preauth_type           cms_transaction_mast.ctm_preauth_type%TYPE;
   l_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_proxynumber            cms_appl_pan.cap_proxy_number%TYPE;
   l_errmsg                 VARCHAR2 (500);
   l_appl_code              cms_appl_pan.cap_appl_code%TYPE;
   l_cust_code              cms_appl_pan.cap_cust_code%TYPE;
   l_pinchange_flag         cms_prod_cattype.cpc_pinchange_flag%TYPE;
   l_pin_off                cms_appl_pan.cap_pin_off%TYPE;
   l_evmprevalid_flag       cms_appl_pan.cap_emvprevalid_flag%TYPE;
   l_tran_reverse_flag      transactionlog.tran_reverse_flag%TYPE;
   l_actual_feecode         transactionlog.feecode%TYPE;
   l_curr_code              transactionlog.currencycode%TYPE;
   l_gl_upd_flag            transactionlog.gl_upd_flag%TYPE;
   l_totpup_pan_hash        transactionlog.topup_card_no%TYPE;
   l_fee_narration          cms_statements_log.csl_trans_narrration%TYPE;
   l_oldpin_offset          VARCHAR2 (10);
   l_txn_code               transactionlog.txn_code%TYPE;
   l_limit_profile_id       cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
   l_ssn                    cms_cust_mast.ccm_ssn%TYPE;
   l_fldob_hashkey_id       cms_cust_mast.ccm_flnamedob_hashkey%TYPE;
   v_ssn_crddtls            VARCHAR2 (1000);
   l_kyc_flag               cms_cust_mast.ccm_kyc_flag%TYPE;
   l_startercard_flag       cms_appl_pan.cap_startercard_flag%TYPE;
   l_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
   l_lmtprfl_level          NUMBER;
   l_from_card              VARCHAR2 (100);
   l_kyc_source             cms_cust_mast.ccm_kyc_source%TYPE;
   l_cip_card_stat          cms_card_stat.ccs_stat_code%TYPE;
   l_cip_tran_code          cms_card_stat.ccs_tran_code%TYPE;
   l_gpr_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   l_gpr_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
   l_gpr_pin_off            cms_appl_pan.cap_pin_off%TYPE;
   l_starter_pan            cms_appl_pan.cap_pan_code%TYPE;
   l_starter_pan_encr       cms_appl_pan.cap_pan_code_encr%TYPE;
   l_req_starter_pan        cms_appl_pan.cap_pan_code%TYPE;
   l_req_starter_pan_encr   cms_appl_pan.cap_pan_code_encr%TYPE;
   l_9_tran_code            cms_card_stat.ccs_tran_code%TYPE;
   l_1_tran_code            cms_card_stat.ccs_tran_code%TYPE;
   exp_reject_record        EXCEPTION;
   l_encrypt_enable         cms_prod_cattype.cpc_encrypt_enable%type;
   l_repl_flag  cms_appl_pan.cap_repl_flag%type;
   l_gPR_FIRST_PINUPDATE   NUMBER(1) :=0;
   l_panins_date cms_appl_pan.cap_ins_date%type;
   l_resp_id transactionlog.response_id%type;
   l_status_chk        			PLS_INTEGER;
   l_precheck_flag     			PLS_INTEGER;
   l_tran_amt          			cms_acct_mast.cam_acct_bal%TYPE;
   l_pvk_key                cms_appl_pan.cap_pvk_keyid%TYPE;
   l_mulkey_fn                cms_inst_param.cip_param_value%TYPE;

 /********************************************************************************
	* Modified By      : dhinakaran B
    * Modified Date    : 17/01/2019
    * Purpose          : VMS-716
    * Reviewer         : Saravanankumar A
    * Release Number   : R11

 *********************************************************************************/

 /********************************************************************************
	* Modified By      : Baskar Krishnan
    * Modified Date    : 13/11/2019
    * Purpose          : VMS-1388
    * Reviewer         : Saravanankumar A
    * Release Number   : R22


	* Modified By      : Dhinakaran B
    * Modified Date    : 13/01/2020
    * Purpose          : VMS-1795
    * Reviewer         : Saravanankumar A
    * Release Number   : R24.1

	* Modified By      : BAKSAR KRISHNAN
    * Modified Date    : 22/01/2020
    * Purpose          : VMS-1853
    * Reviewer         : Saravanankumar A
    * Release Number   : R25

	 * Modified Date    : 30-Nov-2020
     * Modified By      : Puvanesh.N/Ubaidur.H
     * Modified for     : VMS-3349 - IVR callLogId Validation
     * Modified reason  : IVR Call Log ID transaction - Blocking Session while fetching the account balance.
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 30-Nov-2020
     * Release Number   : R39 Build 2

     * Modified Date    : 01-JUL-2021
     * Modified By      : Baskar.K
     * Modified for     : VMS-4007 - Persist Key Id's at Card Level during PIN Set
     * Reviewer         : Saravanakumar A
     * Release Number   : R49 Build 1
 *********************************************************************************/

 BEGIN
   BEGIN
      p_resp_msg_out := 'success';

      BEGIN
         vmscommon.get_transaction_details (p_inst_code_in,
                                            p_delivery_chnl_in,
                                            p_txn_code_in,
                                            l_cr_dr_flag,
                                            l_txn_type,
                                            l_txn_desc,
                                            l_prfl_flag,
                                            l_preauth_flag,
                                            l_login_txn,
                                            l_preauth_type,
                                            l_dup_rrn_check,
                                            p_resp_code_out,
                                            l_errmsg
                                           );

         IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                 'Error from Transaction Details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no, cap_card_stat,
                cap_prod_code, cap_card_type, cap_expry_date,
                cap_active_date, cap_prfl_code, cap_proxy_number,
                cap_appl_code, cap_cust_code, cap_pin_off,
				--query was modified foe VMS-761
                NVL (cap_emvprevalid_flag, 'N'), cap_startercard_flag,nvl(cap_repl_flag,0),cap_ins_date,cap_pvk_keyid
           INTO l_hash_pan, l_encr_pan, l_acct_no, l_card_stat,
                l_prod_code, l_prod_cattype, l_expry_date,
                l_active_date, l_prfl_code, l_proxynumber,
                l_appl_code, l_cust_code, l_pin_off,
                l_evmprevalid_flag, l_startercard_flag,l_repl_flag,l_panins_date,l_pvk_key
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            AND cap_mbr_numb = '000';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting CMS_APPL_PAN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;


      BEGIN
          select cpc_encrypt_enable
          into l_encrypt_enable
          from cms_prod_cattype
          where cpc_inst_code=p_inst_code_in
          and cpc_prod_code=l_prod_code
          and cpc_card_type=l_prod_cattype;
      exception
          when others then
             p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting prod cattype'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN

         select cip_param_value
         into l_mulkey_fn
         from cms_inst_param
         where cip_param_key='MULTI_KEY_FUN';

        exception
          when others then
             p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting multikey functionaity from inst'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF l_dup_rrn_check = 'Y'
      THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_tran_date_in,
                                         p_tran_time_in,
                                         p_delivery_chnl_in,
                                         l_errmsg,
                                         p_resp_code_out
                                        );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                     'Error while validating DATE AND RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;


	 -- Modified for VMS-3349 Start

--SN Perform common validations
BEGIN
      sp_status_check_gpr (p_inst_code_in,
                           p_pan_code_in,
                           p_delivery_chnl_in,
                           l_expry_date,
                           l_card_stat,
                           p_txn_code_in,
                           '0',
                           l_prod_code,
                           l_prod_cattype,
                           p_msg_type_in,
                           p_tran_date_in,
                           p_tran_time_in,
                           NULL,
                           NULL,
                           NULL,
                           p_resp_code_out,
                           l_errmsg
                          );

      IF (   (p_resp_code_out <> '1' AND l_errmsg <> 'OK')
          OR (p_resp_code_out <> '0' AND l_errmsg <> 'OK'))  THEN
         RAISE exp_reject_record;
      ELSE
         l_status_chk := p_resp_code_out;
         p_resp_code_out := '1';
      END IF;
   EXCEPTION  WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS  THEN
         p_resp_code_out := '21';
         l_errmsg :=  'Error from GPR Card Status Check '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En GPR Card status check
   IF l_status_chk = '1'
   THEN
      -- Expiry Check
      BEGIN
         IF TO_DATE (p_tran_date_in, 'YYYYMMDD') >  LAST_DAY (l_expry_date)
         THEN
            p_resp_code_out := '13';
            l_errmsg := 'EXPIRED CARD';
            RAISE exp_reject_record ;
         END IF;
      EXCEPTION WHEN exp_reject_record THEN
               RAISE;
         WHEN OTHERS    THEN
            p_resp_code_out := '21';
            l_errmsg :='ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_reject_record;
      END;
      --Sn select authorization processe flag
      BEGIN
         SELECT ptp_param_value
           INTO l_precheck_flag
           FROM pcms_tranauth_param
          WHERE ptp_param_name = 'PRE CHECK' AND ptp_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS   THEN
            p_resp_code_out := '21';
            l_errmsg :=  'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      --Sn check for precheck
      IF l_precheck_flag = 1  THEN
         BEGIN
            sp_precheck_txn (p_inst_code_in,
                             p_pan_code_in,
                             p_delivery_chnl_in,
                             l_expry_date,
                             l_card_stat,
                             p_txn_code_in,
                             '0',
                             p_tran_date_in,
                             p_tran_time_in,
                             l_tran_amt,
                             NULL,
                             NULL,
                             p_resp_code_out,
                             l_errmsg
                            );

            IF (p_resp_code_out <> '1' OR l_errmsg <> 'OK') THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION WHEN exp_reject_record THEN
               RAISE;
            WHEN OTHERS   THEN
               p_resp_code_out := '21';
               l_errmsg := 'Error from precheck processes '  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;
   END IF;

--EN Perform common validations

/*
      BEGIN
         vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
                                               p_msg_type_in,
                                               p_rrn_in,
                                               p_delivery_chnl_in,
                                               p_txn_code_in,
                                               0,
                                               p_tran_date_in,
                                               p_tran_time_in,
                                               '00',
                                               l_txn_type,
                                               p_pan_code_in,
                                               l_hash_pan,
                                               l_encr_pan,
                                               l_acct_no,
                                               l_card_stat,
                                               l_expry_date,
                                               l_prod_code,
                                               l_prod_cattype,
                                               l_prfl_flag,
                                               l_prfl_code,
                                               l_txn_type,
                                               p_curr_code_in,
                                               l_preauth_flag,
                                               l_txn_desc,
                                               l_cr_dr_flag,
                                               l_login_txn,
                                               p_resp_code_out,
                                               l_errmsg,
                                               l_comb_hash,
                                               l_auth_id,
                                               l_fee_code,
                                               l_fee_plan,
                                               l_feeattach_type,
                                               l_tranfee_amt,
                                               l_total_amt,
                                               l_preauth_type
                                              );

         IF l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'ERROR FROM authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
*/
		-- Modified for VMS-3349 End

      BEGIN
         INSERT INTO cms_cardiss_pin_hist
                     (ccp_pan_code, ccp_mbr_numb, CCP_PIN_OFF,
                      ccp_call_logid, ccp_ins_date, ccp_rrn,
                      ccp_pan_code_encr,ccp_pvk_keyid
                     )
              VALUES (l_hash_pan, '000', l_pin_off,
                      p_call_log_id_in, SYSDATE, p_rrn_in,
                      l_encr_pan,l_pvk_key
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Problem while inserting into  PIN history table'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         UPDATE cms_appl_pan
            SET cap_pin_flag = 'N',
                cap_pin_off = p_pin_in,
                cap_pvk_keyid=p_key_id_in,
                CAP_OLD_PVK_KEYID=decode(l_mulkey_fn,'Y',cap_pvk_keyid,null),
                cap_old_pin_off=decode(l_mulkey_fn,'Y',cap_pin_off,null),
                cap_pingen_date = SYSDATE,
                cap_pingen_user = 1
          WHERE cap_pan_code = l_hash_pan AND cap_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Problem while updating cms_appl_pan'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      -----for gpr card----------
      IF p_gpr_pan_code_in IS NOT NULL AND p_gpr_pan_code_in <> '0'
      THEN
         BEGIN
            SELECT cap_pan_code, cap_pan_code_encr, cap_pin_off
              INTO l_gpr_hash_pan, l_gpr_encr_pan, l_gpr_pin_off
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
               AND cap_pan_code = gethash (p_gpr_pan_code_in)
               AND cap_mbr_numb = '000';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                        'Invalid GPR Card number ' || gethash (p_pan_code_in);
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while selecting CMS_APPL_PAN for GPR Card'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            INSERT INTO cms_cardiss_pin_hist
                        (ccp_pan_code, ccp_mbr_numb, CCP_PIN_OFF,
                         ccp_call_logid, ccp_ins_date, ccp_rrn,
                         ccp_pan_code_encr,ccp_pvk_keyid
                        )
                 VALUES (l_gpr_hash_pan, '000', l_gpr_pin_off,
                         p_call_log_id_in, SYSDATE, p_rrn_in,
                         l_gpr_encr_pan,p_gprkey_id_in
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Problem while inserting into  PIN history table for GPR card'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            UPDATE cms_appl_pan
               SET cap_pin_flag = 'N',
                   cap_pin_off = p_gpr_pin_in,
                   cap_pvk_keyid=p_key_id_in,
                   cap_pingen_date = SYSDATE,
                   cap_pingen_user = 1
             WHERE cap_pan_code = l_gpr_hash_pan
               AND cap_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Problem while updating cms_appl_pan'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

-----for gpr card----------
      BEGIN
         SELECT cpl_lmtprfl_id, 2
           INTO l_limit_profile_id, l_lmtprfl_level
           FROM cms_prdcattype_lmtprfl
          WHERE cpl_inst_code = p_inst_code_in
            AND cpl_prod_code = l_prod_code
            AND cpl_card_type = l_prod_cattype;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         BEGIN
            SELECT cpl_lmtprfl_id, 3
              INTO l_limit_profile_id, l_lmtprfl_level
              FROM cms_prod_lmtprfl
             WHERE cpl_inst_code = p_inst_code_in
               AND cpl_prod_code = l_prod_code;
              EXCEPTION   WHEN OTHERS
         THEN
         NULL;
         END;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Problem while getting limit profile'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT NVL (fn_dmaps_main (ccm_ssn_encr), ccm_ssn) ccm_ssn,
                gethash (decode(l_encrypt_enable,'Y',UPPER (fn_dmaps_main(ccm_first_name)),upper(ccm_first_name))
                         || decode(l_encrypt_enable,'Y',UPPER (fn_dmaps_main(ccm_last_name)),upper(ccm_last_name))
                         || ccm_birth_date
                        ),
                ccm_kyc_flag, ccm_kyc_source
           INTO l_ssn,
                l_fldob_hashkey_id,
                l_kyc_flag, l_kyc_source
           FROM cms_cust_mast
          WHERE ccm_inst_code = p_inst_code_in AND ccm_cust_code = l_cust_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                      'Problem while getting SSN' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
IF l_card_stat = '0' then
      BEGIN
         sp_check_ssn_threshold (p_inst_code_in,
                                 l_ssn,
                                 l_prod_code,
                                 l_prod_cattype,
                                 NULL,                   --Starter To GPR flag
                                 v_ssn_crddtls,
                                 p_resp_code_out,
                                 l_errmsg,
                                 l_fldob_hashkey_id
                                );

         IF l_errmsg <> 'OK'
         THEN
		             select decode(p_delivery_chnl_in,'13','144','10','157','07','158','89')
					into p_resp_code_out
					from dual ;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            l_errmsg := 'Error from SSN check- ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

 END IF;


        --to identify the First pin set for GPR card not for the replacement VMS-716
        if l_startercard_flag = 'N' AND l_repl_flag =0 and trunc(l_panins_date)=trunc(sysdate) AND p_delivery_chnl_in  <> '07'  THEN
            l_gPR_FIRST_PINUPDATE :=1;
        end if;


      IF UPPER (l_kyc_flag) IN ('Y', 'P', 'I', 'O')
      THEN
         FOR i IN (SELECT ccs_stat_code, ccs_tran_code
                     FROM cms_card_stat
                    WHERE ccs_stat_code IN ('9', '1'))
         LOOP
            IF i.ccs_stat_code = '9'
            THEN
               l_9_tran_code := i.ccs_tran_code;
            ELSIF i.ccs_stat_code = '1'
            THEN
               l_1_tran_code := i.ccs_tran_code;
            END IF;
         END LOOP;

          --dont close the startercard based on l_gPR_FIRST_PINUPDATE  VMS-716
         IF l_startercard_flag = 'N' and  l_gPR_FIRST_PINUPDATE=0
         THEN
            IF p_starter_pan_code_in IS NOT NULL
            THEN
               BEGIN

                  SELECT cap_pan_code, cap_pan_code_encr
                    INTO l_req_starter_pan, l_req_starter_pan_encr
                    FROM cms_appl_pan
                   WHERE cap_pan_code = gethash (p_starter_pan_code_in)
                     AND cap_mbr_numb = '000';

                  UPDATE cms_appl_pan
                     SET cap_card_stat = '9'
                   WHERE cap_pan_code = l_req_starter_pan
                     AND cap_mbr_numb = '000';


                  BEGIN
                     sp_log_cardstat_chnge (p_inst_code_in,
                                            l_req_starter_pan,
                                            l_req_starter_pan_encr,
                                            NULL,
                                            l_9_tran_code,
                                            p_rrn_in,
                                            p_tran_date_in,
                                            p_tran_time_in,
                                            p_resp_code_out,
                                            l_errmsg
                                           );

                     IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
                     THEN
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        p_resp_code_out := '21';
                        l_errmsg :=
                              'Error while logging system initiated card status change '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;

                  p_stater_hash_pan_out := l_req_starter_pan;
               EXCEPTION
                 WHEN exp_reject_record
                     THEN
                        RAISE;
                  WHEN OTHERS
                  THEN
                     p_resp_code_out := '21';
                     l_errmsg :=
                           'Error while updating the card status for req starter card'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END IF;

            BEGIN
               SELECT cap_pan_code, cap_pan_code_encr
                 INTO l_starter_pan, l_starter_pan_encr
                 FROM cms_appl_pan
                WHERE cap_acct_no = l_acct_no
                  AND cap_startercard_flag = 'Y'
                  AND cap_card_stat <> '9'
                  AND cap_inst_code = p_inst_code_in;
            EXCEPTION
               WHEN OTHERS
               THEN
                 NULL;
            END;

            IF l_starter_pan IS NOT NULL
            THEN
               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '9'
                   WHERE cap_pan_code = l_starter_pan AND cap_mbr_numb = '000';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_resp_code_out := '21';
                     l_errmsg :=
                           'Error while closing the starter card'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               BEGIN
                  sp_log_cardstat_chnge (p_inst_code_in,
                                         l_starter_pan,
                                         l_starter_pan_encr,
                                         NULL,
                                         l_9_tran_code,
                                         p_rrn_in,
                                         p_tran_date_in,
                                         p_tran_time_in,
                                         p_resp_code_out,
                                         l_errmsg
                                        );

                  IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
                  THEN
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     p_resp_code_out := '21';
                     l_errmsg :=
                           'Error while logging system initiated card status change '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END IF;

            FOR i IN (SELECT   cap_pan_code, cap_pan_code_encr
                          FROM cms_appl_pan
                         WHERE cap_inst_code = p_inst_code_in
                           AND cap_pan_code <> l_hash_pan
                           AND cap_acct_no = l_acct_no
                           AND cap_card_stat <> '9'
                           AND cap_startercard_flag = 'N'
                      ORDER BY cap_ins_date)
            LOOP
               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '9'
                   WHERE cap_pan_code = i.cap_pan_code
                         AND cap_mbr_numb = '000';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_resp_code_out := '21';
                     l_errmsg :=
                           'Error while updating cms_appl_pan '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               BEGIN
                  sp_log_cardstat_chnge (p_inst_code_in,
                                         i.cap_pan_code,
                                         i.cap_pan_code_encr,
                                         NULL,
                                         l_9_tran_code,
                                         p_rrn_in,
                                         p_tran_date_in,
                                         p_tran_time_in,
                                         p_resp_code_out,
                                         l_errmsg
                                        );

                  IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
                  THEN
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     p_resp_code_out := '21';
                     l_errmsg :=
                           'Error while logging system initiated card status change '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               IF p_stater_hash_pan_out IS null
               THEN
                  p_stater_hash_pan_out := i.cap_pan_code;
               END IF;
            END LOOP;

            IF p_starter_pan_code_in IS NOT NULL
            THEN
               l_from_card := p_starter_pan_code_in;
            ELSIF p_gpr_pan_code_in IS NOT NULL AND p_gpr_pan_code_in <> '0'
            THEN
               l_from_card := p_gpr_pan_code_in;
            END IF;
            IF l_from_card  IS NOT NULL THEN
            BEGIN
               vmscommon.trfr_alerts (p_inst_code_in,
                                      gethash (l_from_card),
                                      l_hash_pan,
                                      p_resp_code_out,
                                      l_errmsg
                                     );

               IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
               THEN
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                     'Error from alert transfer-' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
               END IF;
         END IF;
			--dont activate the GPR based on l_gPR_FIRST_PINUPDATE  VMS-716
         BEGIN
            IF l_card_stat <> '9' and l_gPR_FIRST_PINUPDATE=0
            THEN
               UPDATE cms_appl_pan
                  SET cap_card_stat = '1',
                      cap_active_date =SYSDATE,
                      cap_firsttime_topup =
                         (CASE
                             WHEN l_startercard_flag = 'N'
                                THEN 'Y'
                             ELSE cap_firsttime_topup
                          END
                         ),
                      cap_prfl_code =
                         (CASE
                             WHEN l_startercard_flag = 'N'
                                THEN l_limit_profile_id
                             ELSE cap_prfl_code
                          END
                         ),
                      cap_prfl_levl =
                         (CASE
                             WHEN l_startercard_flag = 'N'
                                THEN l_lmtprfl_level
                             ELSE cap_prfl_levl
                          END
                         )
                WHERE cap_pan_code = l_hash_pan
                  AND cap_inst_code = p_inst_code_in
                  AND cap_mbr_numb = '000'
				  and cap_active_date is  null;

                   --  VMS-1388 After Update PIN/Reset PIN posts an entry in CSD from Host Card Status updated to Active

			 IF SQL%ROWCOUNT > 0 then
               BEGIN
                  sp_log_cardstat_chnge (p_inst_code_in,
                                         l_hash_pan,
                                         l_encr_pan,
                                         NULL,
                                         l_1_tran_code,
                                         p_rrn_in,
                                         p_tran_date_in,
                                         p_tran_time_in,
                                         p_resp_code_out,
                                         l_errmsg
                                        );

                  IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
                  THEN
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     p_resp_code_out := '21';
                     l_errmsg :=
                           'Error while logging system initiated card status change '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
		  END If;
            ELSE
					--dont raise the exception the GPR based  on l_gPR_FIRST_PINUPDATE
              IF  l_gPR_FIRST_PINUPDATE  <> 1 THEN
               p_resp_code_out := '21';
               l_errmsg := 'Closed Card';
               RAISE exp_reject_record;
               END IF;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while updating cms_appl_pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
		 --dont card updation the GPR based  on l_gPR_FIRST_PINUPDATE
      ELSIF l_kyc_flag IN ('F', 'E') and l_gPR_FIRST_PINUPDATE=0
      THEN
         BEGIN
            SELECT vsp_cipcard_stat
              INTO l_cip_card_stat
              FROM vms_scorecard_prodcat_mapping
             WHERE vsp_inst_code = p_inst_code_in
               AND vsp_prod_code = l_prod_code
               AND vsp_card_type = l_prod_cattype
               AND vsp_delivery_channel =
                      (CASE
                          WHEN p_delivery_chnl_in = '10'
                             THEN '06'
                          WHEN p_delivery_chnl_in = '03'
                             THEN l_kyc_source
                          ELSE p_delivery_chnl_in
                       END
                      );

            UPDATE cms_appl_pan
               SET cap_card_stat = l_cip_card_stat
             WHERE cap_pan_code = l_hash_pan AND cap_mbr_numb = '000';

            SELECT ccs_tran_code
              INTO l_cip_tran_code
              FROM cms_card_stat
             WHERE ccs_stat_code = l_cip_card_stat;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while updating card stat '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            sp_log_cardstat_chnge (p_inst_code_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_auth_id,
                                   l_cip_tran_code,
                                   p_rrn_in,
                                   p_tran_date_in,
                                   p_tran_time_in,
                                   p_resp_code_out,
                                   l_errmsg
                                  );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while logging system initiated card status change '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      p_resp_code_out := '1';
   EXCEPTION                                            --<<Main Exception>>--
      WHEN exp_reject_record
      THEN
         ROLLBACK;
      WHEN OTHERS
      THEN
         ROLLBACK;
         l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
   END;

   BEGIN
      l_resp_id:=p_resp_code_out;
      SELECT cms_iso_respcde
        INTO p_resp_code_out
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code_in
         AND cms_delivery_channel = p_delivery_chnl_in
         AND cms_response_id = TO_NUMBER (p_resp_code_out);
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errmsg :=
               'Error while selecting respose code'
            || p_resp_code_out
            || ' is-'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '69';
   END;

   BEGIN

        SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO l_auth_id FROM DUAL;
   EXCEPTION
        WHEN OTHERS
            THEN
                l_errmsg :=
                    'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
                p_resp_code_out := '21';

   END;

   l_timestamp := SYSTIMESTAMP;

   BEGIN
      l_hashkey_id :=
         gethash (   p_delivery_chnl_in
                  || p_txn_code_in
                  || p_pan_code_in
                  || p_rrn_in
                  || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
            'Error while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
   END;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO l_acct_bal, l_ledger_bal, l_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code_in AND cam_acct_no = l_acct_no;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '21';
         l_errmsg := 'Invalid Card number '||l_errmsg;
      WHEN OTHERS
      THEN
         l_errmsg := '12';
         p_resp_msg_out :=
                       'ERROR IN account details' || SUBSTR (SQLERRM, 1, 200);
   END;

   IF p_resp_code_out <> '00'
   THEN
      p_stater_hash_pan_out := NULL;
      p_resp_msg_out := l_errmsg;
   END IF;

   BEGIN
      vms_log.log_transactionlog (p_inst_code_in,
                                  p_msg_type_in,
                                  p_rrn_in,
                                  p_delivery_chnl_in,
                                  p_txn_code_in,
                                  l_txn_type,
                                  0,
                                  p_tran_date_in,
                                  p_tran_time_in,
                                  '00',
                                  l_hash_pan,
                                  l_encr_pan,
                                  l_errmsg,
                                  p_ip_addr_in,
                                  l_card_stat,
                                  l_txn_desc,
                                  p_ani_in,
                                  p_dni_in,
                                  l_timestamp,
                                  l_acct_no,
                                  l_prod_code,
                                  l_prod_cattype,
                                  l_cr_dr_flag,
                                  l_acct_bal,
                                  l_ledger_bal,
                                  l_acct_type,
                                  l_proxynumber,
                                  l_auth_id,
                                  0,
                                  l_total_amt,
                                  l_fee_code,
                                  l_tranfee_amt,
                                  l_fee_plan,
                                  l_feeattach_type,
                                  l_resp_id,
                                  p_resp_code_out,
                                  p_curr_code_in,
                                  l_hashkey_id,
                                  p_uuid_in,
                                  p_osname_in,
                                  p_osversion_in,
                                  p_gps_coordinates_in,
                                  p_display_resolution_in,
                                  p_physical_memory_in,
                                  p_appname_in,
                                  p_appversion_in,
                                  p_sessionid_in,
                                  p_device_country_in,
                                  p_device_region_in,
                                  p_ipcountry_in,
                                  p_proxy_flag_in,
                                  p_partner_id_in,
                                  l_errmsg
                                 );

      IF l_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         p_resp_code_out := '69';
         p_resp_msg_out :=
               p_resp_msg_out
            || ' Error while inserting into transaction log  '
            || l_errmsg;
      WHEN OTHERS
      THEN
         p_resp_code_out := '69';
         p_resp_msg_out :=
               'Error while inserting into transaction log '
            || SUBSTR (SQLERRM, 1, 300);
   END;
END update_pin;

PROCEDURE update_pin_reversal (
                             p_inst_code_in            IN       NUMBER,
                             p_delivery_chnl_in        IN       VARCHAR2,
                             p_txn_code_in             IN       VARCHAR2,
                             p_rrn_in                  IN       VARCHAR2,
                             p_cust_id_in              IN       NUMBER,
                             p_appl_id_in              IN       VARCHAR2,
                             p_partner_id_in           IN       VARCHAR2,
                             p_tran_date_in            IN       VARCHAR2,
                             p_tran_time_in            IN       VARCHAR2,
                             p_curr_code_in            IN       VARCHAR2,
                             p_revrsl_code_in          IN       VARCHAR2,
                             p_msg_type_in             IN       VARCHAR2,
                             p_ip_addr_in              IN       VARCHAR2,
                             p_ani_in                  IN       VARCHAR2,
                             p_dni_in                  IN       VARCHAR2,
                             p_device_mobno_in         IN       VARCHAR2,
                             p_device_id_in            IN       VARCHAR2,
                             p_uuid_in                 IN       VARCHAR2,
                             p_osname_in               IN       VARCHAR2,
                             p_osversion_in            IN       VARCHAR2,
                             p_gps_coordinates_in      IN       VARCHAR2,
                             p_display_resolution_in   IN       VARCHAR2,
                             p_physical_memory_in      IN       VARCHAR2,
                             p_appname_in              IN       VARCHAR2,
                             p_appversion_in           IN       VARCHAR2,
                             p_sessionid_in            IN       VARCHAR2,
                             p_device_country_in       IN       VARCHAR2,
                             p_device_region_in        IN       VARCHAR2,
                             p_ipcountry_in            IN       VARCHAR2,
                             p_proxy_flag_in           IN       VARCHAR2,
                             p_pan_code_in             IN       VARCHAR2,
                             p_last_four_pan           IN       VARCHAR2,
                             p_call_log_id_in          IN       VARCHAR2,
                             p_original_rrn_in         IN       VARCHAR2,
                             p_resp_code_out           OUT      VARCHAR2,
                             p_resp_msg_out            OUT      VARCHAR2
                          )
AS
   l_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;
   l_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
   l_acct_no                    cms_acct_mast.cam_acct_no%TYPE;
   l_acct_bal                   cms_acct_mast.cam_acct_bal%TYPE;
   l_ledger_bal                 cms_acct_mast.cam_ledger_bal%TYPE;
   l_prod_code                  cms_appl_pan.cap_prod_code%TYPE;
   l_prod_cattype               cms_appl_pan.cap_card_type%TYPE;
   l_card_stat                  cms_appl_pan.cap_card_stat%TYPE;
   l_expry_date                 cms_appl_pan.cap_expry_date%TYPE;
   l_active_date                cms_appl_pan.cap_expry_date%TYPE;
   l_prfl_code                  cms_appl_pan.cap_prfl_code%TYPE;
   l_cr_dr_flag                 cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_txn_type                   cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_desc                   cms_transaction_mast.ctm_tran_desc%TYPE;
   l_prfl_flag                  cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_comb_hash                  pkg_limits_check.type_hash;
   l_auth_id                    cms_transaction_log_dtl.ctd_auth_id%TYPE;
   l_timestamp                  TIMESTAMP;
   l_preauth_flag               cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_trans_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
   l_dup_rrn_check              cms_transaction_mast.ctm_rrn_check%TYPE;
   l_acct_type                  cms_acct_mast.cam_type_code%TYPE;
   l_login_txn                  cms_transaction_mast.ctm_login_txn%TYPE;
   l_fee_code                   cms_fee_mast.cfm_fee_code%TYPE;
   l_fee_plan                   cms_fee_feeplan.cff_fee_plan%TYPE;
   l_feeattach_type             transactionlog.feeattachtype%TYPE;
   l_tranfee_amt                transactionlog.tranfee_amt%TYPE;
   l_total_amt                  cms_acct_mast.cam_acct_bal%TYPE;
   l_preauth_type               cms_transaction_mast.ctm_preauth_type%TYPE;
   l_hashkey_id                 cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_proxynumber                cms_appl_pan.cap_proxy_number%TYPE;
   l_errmsg                     VARCHAR2 (500);
   l_appl_code                  cms_appl_pan.cap_appl_code%TYPE;
   l_cust_code                  cms_appl_pan.cap_cust_code%TYPE;
   l_pinchange_flag             cms_prod_cattype.cpc_pinchange_flag%TYPE;
   l_ipin_offdata               cms_appl_pan.cap_ipin_offset%TYPE;
   l_evmprevalid_flag           cms_appl_pan.cap_emvprevalid_flag%TYPE;
   l_orgnl_delivery_channel     transactionlog.delivery_channel%TYPE;
   l_orgnl_resp_code            transactionlog.response_code%TYPE;
   l_orgnl_terminal_id          transactionlog.terminal_id%TYPE;
   l_orgnl_txn_code             transactionlog.txn_code%TYPE;
   l_orgnl_txn_type             transactionlog.txn_type%TYPE;
   l_orgnl_txn_mode             transactionlog.txn_mode%TYPE;
   l_orgnl_business_date        transactionlog.business_date%TYPE;
   l_orgnl_business_time        transactionlog.business_time%TYPE;
   l_orgnl_customer_card_no     transactionlog.customer_card_no%TYPE;
   l_orgnl_total_amount         transactionlog.amount%TYPE;
   l_reversal_amt               NUMBER (9, 2);
   l_orgnl_txn_feecode          cms_fee_mast.cfm_fee_code%TYPE;
   l_orgnl_txn_feeattachtype    transactionlog.feeattachtype%TYPE;
   l_orgnl_txn_totalfee_amt     transactionlog.tranfee_amt%TYPE;
   l_orgnl_txn_servicetax_amt   transactionlog.servicetax_amt%TYPE;
   l_orgnl_txn_cess_amt         transactionlog.cess_amt%TYPE;
   l_orgnl_transaction_type     transactionlog.cr_dr_flag%TYPE;
   l_orgnl_trandate             DATE;
   l_rvsl_trandate              DATE;
   l_orgnl_termid               transactionlog.terminal_id%TYPE;
   l_orgnl_mcccode              transactionlog.mccode%TYPE;
   l_orgnl_tranfee_amt          transactionlog.tranfee_amt%TYPE;
   l_orgnl_servicetax_amt       transactionlog.servicetax_amt%TYPE;
   l_orgnl_cess_amt             transactionlog.cess_amt%TYPE;
   l_orgnl_cr_dr_flag           transactionlog.cr_dr_flag%TYPE;
   l_orgnl_tranfee_cr_acctno    transactionlog.tranfee_cr_acctno%TYPE;
   l_orgnl_tranfee_dr_acctno    transactionlog.tranfee_dr_acctno%TYPE;
   l_orgnl_st_calc_flag         transactionlog.tran_st_calc_flag%TYPE;
   l_orgnl_cess_calc_flag       transactionlog.tran_cess_calc_flag%TYPE;
   l_orgnl_st_cr_acctno         transactionlog.tran_st_cr_acctno%TYPE;
   l_orgnl_st_dr_acctno         transactionlog.tran_st_dr_acctno%TYPE;
   l_orgnl_cess_cr_acctno       transactionlog.tran_cess_cr_acctno%TYPE;
   l_orgnl_cess_dr_acctno       transactionlog.tran_cess_dr_acctno%TYPE;
   l_orgnl_cardstatus           transactionlog.cardstatus%TYPE;
   l_tran_reverse_flag          transactionlog.tran_reverse_flag%TYPE;
   l_actual_feecode             transactionlog.feecode%TYPE;
   l_curr_code                  transactionlog.currencycode%TYPE;
   l_gl_upd_flag                transactionlog.gl_upd_flag%TYPE;
   l_totpup_pan_hash            transactionlog.topup_card_no%TYPE;
   l_fee_narration              cms_statements_log.csl_trans_narrration%TYPE;
   l_oldpin_offset              VARCHAR2 (10);
   l_txn_code                   transactionlog.txn_code%TYPE;
   l_limit_profile_id           cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
   l_ssn                        cms_cust_mast.ccm_ssn%TYPE;
   l_fldob_hashkey_id           cms_cust_mast.ccm_flnamedob_hashkey%TYPE;
   v_ssn_crddtls                VARCHAR2 (1000);
   l_status_chk        			PLS_INTEGER;
   l_precheck_flag     			PLS_INTEGER;
   l_tran_amt          			cms_acct_mast.cam_acct_bal%TYPE;
   exp_reject_record            EXCEPTION;
   l_pvk_keyid          		cms_cardiss_pin_hist.ccp_pvk_keyid%TYPE;
v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991

 /********************************************************************************
	 * Modified Date    : 30-Nov-2020
     * Modified By      : Puvanesh.N/Ubaidur.H
     * Modified for     : VMS-3349 - IVR callLogId Validation
     * Modified reason  : IVR Call Log ID transaction - Blocking Session while fetching the account balance.
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 30-Nov-2020
     * Release Number   : R39 Build 2

     * Modified Date    : 01-JUL-2021
     * Modified By      : Baskar.K
     * Modified for     : VMS-4007 - Persist Key Id's at Card Level during PIN Set
     * Reviewer         : Saravanakumar A
     * Release Number   : R49 Build 1
	 
	* Modified By      : venkat Singamaneni
    * Modified Date    : 05-12-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jey
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
 *********************************************************************************/

BEGIN
   BEGIN
      p_resp_msg_out := 'success';

      BEGIN
         vmscommon.get_transaction_details (p_inst_code_in,
                                            p_delivery_chnl_in,
                                            p_txn_code_in,
                                            l_cr_dr_flag,
                                            l_txn_type,
                                            l_txn_desc,
                                            l_prfl_flag,
                                            l_preauth_flag,
                                            l_login_txn,
                                            l_preauth_type,
                                            l_dup_rrn_check,
                                            p_resp_code_out,
                                            l_errmsg
                                           );

         IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                 'Error from Transaction Details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no, cap_card_stat,
                cap_prod_code, cap_card_type, cap_expry_date,
                cap_active_date, cap_prfl_code, cap_proxy_number,
                cap_appl_code, cap_cust_code, cap_ipin_offset,
                NVL (cap_emvprevalid_flag, 'N')
           INTO l_hash_pan, l_encr_pan, l_acct_no, l_card_stat,
                l_prod_code, l_prod_cattype, l_expry_date,
                l_active_date, l_prfl_code, l_proxynumber,
                l_appl_code, l_cust_code, l_ipin_offdata,
                l_evmprevalid_flag
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            AND cap_mbr_numb = '000';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting CMS_APPL_PAN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF l_dup_rrn_check = 'Y'
      THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_tran_date_in,
                                         p_tran_time_in,
                                         p_delivery_chnl_in,
                                         l_errmsg,
                                         p_resp_code_out
                                        );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                     'Error while validating DATE AND RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

	  -- Modified for VMS-3349 Start

--SN Perform common validations
BEGIN
      sp_status_check_gpr (p_inst_code_in,
                           p_pan_code_in,
                           p_delivery_chnl_in,
                           l_expry_date,
                           l_card_stat,
                           p_txn_code_in,
                           '0',
                           l_prod_code,
                           l_prod_cattype,
                           p_msg_type_in,
                           p_tran_date_in,
                           p_tran_time_in,
                           NULL,
                           NULL,
                           NULL,
                           p_resp_code_out,
                           l_errmsg
                          );

      IF (   (p_resp_code_out <> '1' AND l_errmsg <> 'OK')
          OR (p_resp_code_out <> '0' AND l_errmsg <> 'OK'))  THEN
         RAISE exp_reject_record;
      ELSE
         l_status_chk := p_resp_code_out;
         p_resp_code_out := '1';
      END IF;
   EXCEPTION  WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS  THEN
         p_resp_code_out := '21';
         l_errmsg :=  'Error from GPR Card Status Check '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En GPR Card status check
   IF l_status_chk = '1'
   THEN
      -- Expiry Check
      BEGIN
         IF TO_DATE (p_tran_date_in, 'YYYYMMDD') >  LAST_DAY (l_expry_date)
         THEN
            p_resp_code_out := '13';
            l_errmsg := 'EXPIRED CARD';
            RAISE exp_reject_record ;
         END IF;
      EXCEPTION WHEN exp_reject_record THEN
               RAISE;
         WHEN OTHERS    THEN
            p_resp_code_out := '21';
            l_errmsg :='ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_reject_record;
      END;
      --Sn select authorization processe flag
      BEGIN
         SELECT ptp_param_value
           INTO l_precheck_flag
           FROM pcms_tranauth_param
          WHERE ptp_param_name = 'PRE CHECK' AND ptp_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS   THEN
            p_resp_code_out := '21';
            l_errmsg :=  'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      --Sn check for precheck
      IF l_precheck_flag = 1  THEN
         BEGIN
            sp_precheck_txn (p_inst_code_in,
                             p_pan_code_in,
                             p_delivery_chnl_in,
                             l_expry_date,
                             l_card_stat,
                             p_txn_code_in,
                             '0',
                             p_tran_date_in,
                             p_tran_time_in,
                             l_tran_amt,
                             NULL,
                             NULL,
                             p_resp_code_out,
                             l_errmsg
                            );

            IF (p_resp_code_out <> '1' OR l_errmsg <> 'OK') THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION WHEN exp_reject_record THEN
               RAISE;
            WHEN OTHERS   THEN
               p_resp_code_out := '21';
               l_errmsg := 'Error from precheck processes '  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;
   END IF;

--EN Perform common validations


/*
      BEGIN
         vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
                                               p_msg_type_in,
                                               p_rrn_in,
                                               p_delivery_chnl_in,
                                               p_txn_code_in,
                                               0,
                                               p_tran_date_in,
                                               p_tran_time_in,
                                               '00',
                                               l_txn_type,
                                               p_pan_code_in,
                                               l_hash_pan,
                                               l_encr_pan,
                                               l_acct_no,
                                               l_card_stat,
                                               l_expry_date,
                                               l_prod_code,
                                               l_prod_cattype,
                                               l_prfl_flag,
                                               l_prfl_code,
                                               l_txn_type,
                                               p_curr_code_in,
                                               l_preauth_flag,
                                               l_txn_desc,
                                               l_cr_dr_flag,
                                               l_login_txn,
                                               p_resp_code_out,
                                               l_errmsg,
                                               l_comb_hash,
                                               l_auth_id,
                                               l_fee_code,
                                               l_fee_plan,
                                               l_feeattach_type,
                                               l_tranfee_amt,
                                               l_total_amt,
                                               l_preauth_type
                                              );

         IF l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'ERROR FROM authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
*/
		-- Modified for VMS-3349 End
      BEGIN
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
	  
         SELECT delivery_channel, terminal_id,
                response_code, txn_code, txn_type,
                txn_mode, business_date,
                business_time, customer_card_no,
                amount, feecode,
                feeattachtype, tranfee_amt,
                servicetax_amt, cess_amt,
                cr_dr_flag, terminal_id, mccode,
                feecode, tranfee_amt,
                servicetax_amt, cess_amt,
                tranfee_cr_acctno, tranfee_dr_acctno,
                tran_st_calc_flag, tran_cess_calc_flag,
                tran_st_cr_acctno, tran_st_dr_acctno,
                tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
                tran_reverse_flag, gl_upd_flag, topup_card_no,
                cardstatus
           INTO l_orgnl_delivery_channel, l_orgnl_terminal_id,
                l_orgnl_resp_code, l_orgnl_txn_code, l_orgnl_txn_type,
                l_orgnl_txn_mode, l_orgnl_business_date,
                l_orgnl_business_time, l_orgnl_customer_card_no,
                l_orgnl_total_amount, l_orgnl_txn_feecode,
                l_orgnl_txn_feeattachtype, l_orgnl_txn_totalfee_amt,
                l_orgnl_txn_servicetax_amt, l_orgnl_txn_cess_amt,
                l_orgnl_transaction_type, l_orgnl_termid, l_orgnl_mcccode,
                l_actual_feecode, l_orgnl_tranfee_amt,
                l_orgnl_servicetax_amt, l_orgnl_cess_amt,
                l_orgnl_tranfee_cr_acctno, l_orgnl_tranfee_dr_acctno,
                l_orgnl_st_calc_flag, l_orgnl_cess_calc_flag,
                l_orgnl_st_cr_acctno, l_orgnl_st_dr_acctno,
                l_orgnl_cess_cr_acctno, l_orgnl_cess_dr_acctno, l_curr_code,
                l_tran_reverse_flag, l_gl_upd_flag, l_totpup_pan_hash,
                l_orgnl_cardstatus
           FROM VMSCMS.TRANSACTIONLOG                            --Added for VMS-5735/FSP-991
          WHERE rrn = p_original_rrn_in
            -- AND business_date = l_orgnl_business_date
            -- AND business_time = l_orgnl_business_time
            AND customer_card_no = l_hash_pan
            AND delivery_channel = p_delivery_chnl_in
            AND instcode = p_inst_code_in
            AND response_code = '00';
			
	ELSE
	SELECT delivery_channel, terminal_id,
                response_code, txn_code, txn_type,
                txn_mode, business_date,
                business_time, customer_card_no,
                amount, feecode,
                feeattachtype, tranfee_amt,
                servicetax_amt, cess_amt,
                cr_dr_flag, terminal_id, mccode,
                feecode, tranfee_amt,
                servicetax_amt, cess_amt,
                tranfee_cr_acctno, tranfee_dr_acctno,
                tran_st_calc_flag, tran_cess_calc_flag,
                tran_st_cr_acctno, tran_st_dr_acctno,
                tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
                tran_reverse_flag, gl_upd_flag, topup_card_no,
                cardstatus
           INTO l_orgnl_delivery_channel, l_orgnl_terminal_id,
                l_orgnl_resp_code, l_orgnl_txn_code, l_orgnl_txn_type,
                l_orgnl_txn_mode, l_orgnl_business_date,
                l_orgnl_business_time, l_orgnl_customer_card_no,
                l_orgnl_total_amount, l_orgnl_txn_feecode,
                l_orgnl_txn_feeattachtype, l_orgnl_txn_totalfee_amt,
                l_orgnl_txn_servicetax_amt, l_orgnl_txn_cess_amt,
                l_orgnl_transaction_type, l_orgnl_termid, l_orgnl_mcccode,
                l_actual_feecode, l_orgnl_tranfee_amt,
                l_orgnl_servicetax_amt, l_orgnl_cess_amt,
                l_orgnl_tranfee_cr_acctno, l_orgnl_tranfee_dr_acctno,
                l_orgnl_st_calc_flag, l_orgnl_cess_calc_flag,
                l_orgnl_st_cr_acctno, l_orgnl_st_dr_acctno,
                l_orgnl_cess_cr_acctno, l_orgnl_cess_dr_acctno, l_curr_code,
                l_tran_reverse_flag, l_gl_upd_flag, l_totpup_pan_hash,
                l_orgnl_cardstatus
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE rrn = p_original_rrn_in
            -- AND business_date = l_orgnl_business_date
            -- AND business_time = l_orgnl_business_time
            AND customer_card_no = l_hash_pan
            AND delivery_channel = p_delivery_chnl_in
            AND instcode = p_inst_code_in
            AND response_code = '00';
END IF;	

         IF l_orgnl_resp_code <> '00'
         THEN
            p_resp_code_out := '23';
            l_errmsg := ' The original transaction was not successful';
            RAISE exp_reject_record;
         END IF;

         IF l_tran_reverse_flag = 'Y'
         THEN
            p_resp_code_out := '52';
            l_errmsg :=
                      'The reversal already done for the orginal transaction';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '53';
            l_errmsg := 'Matching transaction not found';
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'More than one matching record found in the master';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
               'Error while selecting master data'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF l_orgnl_customer_card_no <> l_hash_pan
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
            'Customer card number is not matching in reversal and orginal transaction';
         RAISE exp_reject_record;
      END IF;

      BEGIN
         IF l_auth_id IS NULL
         THEN
            l_auth_id := LPAD (seq_auth_id.NEXTVAL, 6, '0');
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
	  
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN

         SELECT csl_trans_narrration
           INTO l_fee_narration
           FROM VMSCMS.CMS_STATEMENTS_LOG                     --Added for VMS-5735/FSP-991
          WHERE csl_business_date = l_orgnl_business_date
            AND csl_business_time = l_orgnl_business_time
            AND csl_rrn = p_original_rrn_in
            AND csl_delivery_channel = p_delivery_chnl_in
            AND csl_txn_code = p_txn_code_in
            AND csl_pan_no = l_orgnl_customer_card_no
            AND csl_inst_code = p_inst_code_in
            AND txn_fee_flag = 'Y';
	ELSE
	
	  SELECT csl_trans_narrration
           INTO l_fee_narration
           FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
          WHERE csl_business_date = l_orgnl_business_date
            AND csl_business_time = l_orgnl_business_time
            AND csl_rrn = p_original_rrn_in
            AND csl_delivery_channel = p_delivery_chnl_in
            AND csl_txn_code = p_txn_code_in
            AND csl_pan_no = l_orgnl_customer_card_no
            AND csl_inst_code = p_inst_code_in
            AND txn_fee_flag = 'Y';
END IF;	
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_fee_narration := NULL;
         WHEN OTHERS
         THEN
            l_fee_narration := NULL;
      END;

      BEGIN
         l_rvsl_trandate :=
            TO_DATE (   SUBSTR (TRIM (p_tran_date_in), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_tran_time_in), 1, 10),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Problem while converting V_RVSL_TRANDATE date '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         sp_reverse_fee_amount (p_inst_code_in,
                                p_rrn_in,
                                p_delivery_chnl_in,
                                l_orgnl_terminal_id,
                                NULL,                             --P_MERC_ID,
                                p_txn_code_in,
                                l_rvsl_trandate,
                                NULL,                           -- P_TXN_MODE,
                                l_orgnl_tranfee_amt,
                                p_pan_code_in,
                                l_actual_feecode,
                                l_orgnl_tranfee_amt,
                                l_orgnl_tranfee_cr_acctno,
                                l_orgnl_tranfee_dr_acctno,
                                l_orgnl_st_calc_flag,
                                l_orgnl_servicetax_amt,
                                l_orgnl_st_cr_acctno,
                                l_orgnl_st_dr_acctno,
                                l_orgnl_cess_calc_flag,
                                l_orgnl_cess_amt,
                                l_orgnl_cess_cr_acctno,
                                l_orgnl_cess_dr_acctno,
                                p_original_rrn_in,
                                l_acct_no,
                                p_tran_date_in,
                                p_tran_time_in,
                                l_auth_id,
                                l_fee_narration,
                                NULL,                          --MERCHANT_NAME
                                NULL,                          --MERCHANT_CITY
                                NULL,                         --MERCHANT_STATE
                                p_resp_code_out,
                                l_errmsg
                               );

         IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while reversing the fee amount '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT *
           INTO l_oldpin_offset,l_pvk_keyid
           FROM (SELECT   ccp_pin_off,ccp_pvk_keyid
                     FROM cms_cardiss_pin_hist
                    WHERE ccp_pan_code = l_hash_pan
                      AND ccp_rrn = p_original_rrn_in
                      AND ccp_mbr_numb = '000'
                 ORDER BY ccp_ins_date DESC)
          WHERE ROWNUM = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_oldpin_offset := NULL;
         WHEN TOO_MANY_ROWS
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'More than one record found in repin hist detail ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while getting old pin offset '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         IF l_oldpin_offset IS NULL
         THEN
            UPDATE cms_appl_pan
               SET cap_firsttime_topup = 'N'
             WHERE cap_pan_code = l_hash_pan
               AND cap_card_stat IN ('1', '13')
               AND cap_startercard_flag = 'N'
               AND cap_inst_code = p_inst_code_in;

            UPDATE cms_appl_pan
               SET cap_pin_flag = 'Y',
                   cap_pin_off = NULL,
                   cap_pingen_date = NULL,
                   cap_pingen_user = NULL,
                   cap_card_stat = 0,
                   cap_active_date = NULL
             WHERE cap_pan_code = l_hash_pan
                   AND cap_inst_code = p_inst_code_in;

            IF SQL%ROWCOUNT = 0
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while updating old pin offset '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END IF;

            BEGIN
               sp_log_cardstat_chnge (p_inst_code_in,
                                      l_hash_pan,
                                      l_encr_pan,
                                      l_auth_id,
                                      '08',
                                      p_rrn_in,
                                      p_tran_date_in,
                                      p_tran_time_in,
                                      p_resp_code_out,
                                      l_errmsg
                                     );

               IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
               THEN
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                        'Error while updating card status in log table-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSE
            UPDATE cms_appl_pan
               SET cap_pin_off = l_oldpin_offset,
               cap_pvk_keyid=l_pvk_keyid
             WHERE cap_pan_code = l_hash_pan
                   AND cap_inst_code = p_inst_code_in;

            IF SQL%ROWCOUNT = 0
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while updating old pin offset '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END IF;

            IF l_orgnl_cardstatus = '0'
            THEN
               UPDATE cms_appl_pan
                  SET cap_firsttime_topup = 'N',
                      cap_card_stat = 0,
                      cap_active_date = NULL
                WHERE cap_pan_code = l_hash_pan
                  AND cap_card_stat IN ('1', '13')
                  AND cap_startercard_flag = 'N'
                  AND cap_inst_code = p_inst_code_in;

               IF SQL%ROWCOUNT = 1
               THEN
                  BEGIN
                     sp_log_cardstat_chnge (p_inst_code_in,
                                            l_hash_pan,
                                            l_encr_pan,
                                            l_auth_id,
                                            '08',
                                            p_rrn_in,
                                            p_tran_date_in,
                                            p_tran_time_in,
                                            p_resp_code_out,
                                            l_errmsg
                                           );

                     IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
                     THEN
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        p_resp_code_out := '21';
                        l_errmsg :=
                              'Error while updating card status in log table-'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while updating old pin offset '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         IF l_totpup_pan_hash IS NOT NULL
         THEN
            UPDATE cms_appl_pan
               SET cap_pin_flag = 'Y',
                   cap_pin_off = NULL,
                   cap_pvk_keyid=NULL,
                   cap_pingen_date = NULL,
                   cap_pingen_user = NULL
             WHERE cap_pan_code = l_totpup_pan_hash
               AND cap_inst_code = p_inst_code_in;

            IF SQL%ROWCOUNT = 0
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while updating old pin offset for GPR'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END IF;

            DELETE FROM cms_cardiss_pin_hist
                  WHERE ccp_pan_code = l_totpup_pan_hash
                    AND ccp_rrn = p_original_rrn_in
                    AND ccp_mbr_numb = '000';

            IF SQL%ROWCOUNT = 0
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while deleting old pinhist for GPR'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END IF;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while updating old pin offset gor GPR card'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
	  
	  
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
	  
         UPDATE VMSCMS.TRANSACTIONLOG                   --Added for VMS-5735/FSP-991
            SET tran_reverse_flag = 'Y'
          WHERE rrn = p_original_rrn_in
            AND business_date = l_orgnl_business_date
            AND business_time = l_orgnl_business_time
            AND customer_card_no = l_hash_pan
            AND instcode = p_inst_code_in;
	ELSE
	
	
         UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            SET tran_reverse_flag = 'Y'
          WHERE rrn = p_original_rrn_in
            AND business_date = l_orgnl_business_date
            AND business_time = l_orgnl_business_time
            AND customer_card_no = l_hash_pan
            AND instcode = p_inst_code_in;

END IF;	

         IF SQL%ROWCOUNT = 0
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Reverse flag is not updated ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while updating gl flag ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      FOR j IN (SELECT customer_card_no, customer_card_no_encr, cardstatus,
                       fn_dmaps_main (customer_card_no_encr) cardnumber
                  FROM VMSCMS.TRANSACTIONLOG_VW                        --Added for VMS-5735/FSP-991
                 WHERE delivery_channel = '05'
                   AND txn_code = '02'
                   AND instcode = p_inst_code_in
                   AND orgnl_rrn = p_original_rrn_in
                   AND business_date = l_orgnl_business_date
                   AND customer_acct_no = l_acct_no)
      LOOP
         BEGIN
            IF j.customer_card_no IS NOT NULL
            THEN
               UPDATE cms_appl_pan
                  SET cap_card_stat = j.cardstatus
                WHERE cap_pan_code = j.customer_card_no
                  AND cap_inst_code = p_inst_code_in;

               IF SQL%ROWCOUNT = 0
               THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                        'Error while updating old card status '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
               END IF;

               IF j.cardstatus = '0'
               THEN
                  l_txn_code := '08';
               ELSIF j.cardstatus = '1'
               THEN
                  l_txn_code := '01';
               ELSIF j.cardstatus = '8'
               THEN
                  l_txn_code := '04';
               ELSIF j.cardstatus = '12'
               THEN
                  l_txn_code := '03';
               ELSIF j.cardstatus = '3'
               THEN
                  l_txn_code := '41';
               END IF;

               BEGIN
                  sp_log_cardstat_chnge (p_inst_code_in,
                                         j.customer_card_no,
                                         j.customer_card_no_encr,
                                         l_auth_id,
                                         l_txn_code,
                                         p_rrn_in,
                                         p_tran_date_in,
                                         p_tran_time_in,
                                         p_resp_code_out,
                                         l_errmsg
                                        );

                  IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
                  THEN
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     p_resp_code_out := '21';
                     l_errmsg :=
                           'Error while updating card status in log table-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            -- p_old_card_number := j.cardnumber;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while selecting starter card details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END LOOP;

      p_resp_code_out := '1';
   EXCEPTION                                            --<<Main Exception>>--
      WHEN exp_reject_record
      THEN
         ROLLBACK;
      WHEN OTHERS
      THEN
         ROLLBACK;
         l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
   END;

   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code_out
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code_in
         AND cms_delivery_channel = p_delivery_chnl_in
         AND cms_response_id = TO_NUMBER (p_resp_code_out);
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errmsg :=
               'Error while selecting respose code'
            || p_resp_code_out
            || ' is-'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '69';
   END;

   BEGIN

        SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO l_auth_id FROM DUAL;
   EXCEPTION
        WHEN OTHERS
            THEN
                l_errmsg :=
                    'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
                p_resp_code_out := '21';
                RAISE EXP_REJECT_RECORD;
   END;

   l_timestamp := SYSTIMESTAMP;

   BEGIN
      l_hashkey_id :=
         gethash (   p_delivery_chnl_in
                  || p_txn_code_in
                  || p_pan_code_in
                  || p_rrn_in
                  || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
            'Error while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
   END;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO l_acct_bal, l_ledger_bal, l_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code_in AND cam_acct_no = l_acct_no;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '21';
         l_errmsg := 'Invalid Card number ';
      WHEN OTHERS
      THEN
         l_errmsg := '12';
         p_resp_msg_out :=
                       'ERROR IN account details' || SUBSTR (SQLERRM, 1, 200);
   END;

   IF p_resp_code_out <> '00'
   THEN
      p_resp_msg_out := l_errmsg;
   END IF;

   BEGIN
      vms_log.log_transactionlog (p_inst_code_in,
                                  p_msg_type_in,
                                  p_rrn_in,
                                  p_delivery_chnl_in,
                                  p_txn_code_in,
                                  l_txn_type,
                                  0,
                                  p_tran_date_in,
                                  p_tran_time_in,
                                  '00',
                                  l_hash_pan,
                                  l_encr_pan,
                                  l_errmsg,
                                  p_ip_addr_in,
                                  l_card_stat,
                                  l_txn_desc,
                                  p_ani_in,
                                  p_dni_in,
                                  l_timestamp,
                                  l_acct_no,
                                  l_prod_code,
                                  l_prod_cattype,
                                  l_cr_dr_flag,
                                  l_acct_bal,
                                  l_ledger_bal,
                                  l_acct_type,
                                  l_proxynumber,
                                  l_auth_id,
                                  0,
                                  l_total_amt,
                                  l_fee_code,
                                  l_tranfee_amt,
                                  l_fee_plan,
                                  l_feeattach_type,
                                  p_resp_code_out,
                                  p_resp_code_out,
                                  p_curr_code_in,
                                  l_hashkey_id,
                                  p_uuid_in,
                                  p_osname_in,
                                  p_osversion_in,
                                  p_gps_coordinates_in,
                                  p_display_resolution_in,
                                  p_physical_memory_in,
                                  p_appname_in,
                                  p_appversion_in,
                                  p_sessionid_in,
                                  p_device_country_in,
                                  p_device_region_in,
                                  p_ipcountry_in,
                                  p_proxy_flag_in,
                                  p_partner_id_in,
                                  l_errmsg
                                 );

      IF l_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         p_resp_code_out := '69';
         p_resp_msg_out :=
               p_resp_msg_out
            || ' Error while inserting into transaction log  '
            || l_errmsg;
      WHEN OTHERS
      THEN
         p_resp_code_out := '69';
         p_resp_msg_out :=
               'Error while inserting into transaction log '
            || SUBSTR (SQLERRM, 1, 300);
   END;
END update_pin_reversal;

PROCEDURE replace_card(p_inst_code_in             IN  NUMBER,
                             p_delivery_channel_in      IN  VARCHAR2,
                             p_txn_code_in              IN  VARCHAR2,
                             p_rrn_in                   IN  VARCHAR2,
                             p_cust_id_in               IN  VARCHAR2,
                             p_partner_id_in            IN  VARCHAR2,
                             p_trandate_in              IN  VARCHAR2,
                             p_trantime_in              IN  VARCHAR2,
                             p_curr_code_in             IN  VARCHAR2,
                             p_rvsl_code_in             IN  VARCHAR2,
                             p_msg_type_in              IN  VARCHAR2,
                             p_ip_addr_in               IN  VARCHAR2,
                             p_ani_in                   IN  VARCHAR2,
                             p_dni_in                   IN  VARCHAR2,
                             p_device_mob_no_in         IN  VARCHAR2,
                             p_device_id_in             IN  VARCHAR2,
                             p_uuid_in                  IN  VARCHAR2,
                             p_os_name_in               IN  VARCHAR2,
                             p_os_version_in            IN  VARCHAR2,
                             p_gps_coordinates_in       IN  VARCHAR2,
                             p_display_resolution_in    IN  VARCHAR2,
                             p_physical_memory_in       IN  VARCHAR2,
                             p_app_name_in              IN  VARCHAR2,
                             p_app_version_in           IN  VARCHAR2,
                             p_session_id_in            IN  VARCHAR2,
                             p_device_country_in        IN  VARCHAR2,
                             p_device_region_in         IN  VARCHAR2,
                             p_ip_country_in            IN  VARCHAR2,
                             p_proxy_flag_in            IN  VARCHAR2,
                             p_pan_code_in              IN  VARCHAR2,
                             p_is_expedited_in          IN  VARCHAR2,
                             p_activation_code          IN  VARCHAR2,
                             p_resp_code_out            OUT VARCHAR2,
                             p_respmsg_out              OUT VARCHAR2,
                             p_closed_card              OUT VARCHAR2,
                             p_closed_card_hash         OUT VARCHAR2
                             )
AS
      l_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no                cms_acct_mast.cam_acct_no%TYPE;
      l_cust_code              cms_appl_pan.cap_cust_code%TYPE;
      l_startercard_flag       cms_appl_pan.cap_startercard_flag%TYPE;
      l_disp_name              cms_appl_pan.cap_disp_name%TYPE;
      l_prfl_levl              cms_appl_pan.cap_prfl_levl%TYPE;
      l_acct_bal               cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code              cms_appl_pan.cap_prod_code%TYPE;
      l_prod_cattype           cms_appl_pan.cap_card_type%TYPE;
      l_card_stat              cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date             cms_appl_pan.cap_expry_date%TYPE;
      l_active_date            cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type               cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_comb_hash              pkg_limits_check.type_hash;
      l_auth_id                cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp              TIMESTAMP;
      l_preauth_flag           cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
      l_acct_type              cms_acct_mast.cam_type_code%TYPE;
      l_login_txn              cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code               cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan               cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type         transactionlog.feeattachtype%TYPE;
      l_tranfee_amt            transactionlog.tranfee_amt%TYPE;
      l_total_amt              cms_acct_mast.cam_acct_bal%TYPE;
      l_crdstat_cnt            VARCHAR2(10);
      l_cam_lupd_date          cms_addr_mast.cam_lupd_date%TYPE;
      l_preauth_type           cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber            cms_appl_pan.cap_proxy_number%TYPE;
      l_appl_code              cms_appl_pan.cap_appl_code%TYPE;
	  l_remrk                  VARCHAR2(100);
	  l_cap_prod_catg          cms_appl_pan.cap_prod_catg%TYPE;
      l_dup_rrn_check          cms_transaction_mast.ctm_rrn_check%TYPE;
      l_txn_code_in            cms_transaction_mast.ctm_tran_code%TYPE;
      l_resoncode              CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
      l_dup_check              NUMBER(1);
      l_errmsg                 VARCHAR2 (500);
      l_repl_flag              CMS_APPL_PAN.CAP_REPL_FLAG%type:=0;
      l_disable_repl_flag      CMS_PROD_CATTYPE.CPC_DISABLE_REPL_FLAG%type;
      l_replacement_option     cms_prod_cattype.cpc_renew_replace_option%TYPE;
      l_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
      l_new_product            CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
      l_new_cardtype           CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
      l_disable_repl_expdays   CMS_PROD_CATTYPE.CPC_DISABLE_REPL_EXPRYDAYS%type;
      l_disable_repl_minbal    CMS_PROD_CATTYPE.CPC_DISABLE_REPL_MINBAL%type;
      l_disable_repl_message   CMS_PROD_CATTYPE.CPC_DISABLE_REPL_MESSAGE%type;
      l_cro_oldcard_reissue_stat VARCHAR2(10);
      l_new_hash_pan           CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
      l_new_card_no            VARCHAR2(100);
      l_output_type            CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
      exp_reject_record        EXCEPTION;

   BEGIN

      BEGIN
         p_resp_code_out := '00';
         p_respmsg_out := 'success';

		 l_REMRK    := 'Online Order Replacement Card';

         l_txn_code_in := p_txn_code_in;
         IF upper(p_is_expedited_in) = 'TRUE' THEN

            IF p_delivery_channel_in  = '07' THEN
                l_txn_code_in := '48';
            ELSIF  p_delivery_channel_in = '10' THEN
                l_txn_code_in := '99';
            ELSIF p_delivery_channel_in = '13' THEN
                l_txn_code_in := '77';

            END IF;

         END IF;

--Sn pan   details
         BEGIN
          SELECT cap_pan_code, cap_pan_code_encr,cap_acct_no,cap_cust_code,
                 cap_card_stat, cap_prod_code, cap_card_type,cap_startercard_flag,
                 cap_expry_date, cap_active_date, cap_prfl_code,cap_disp_name,
                 cap_proxy_number,cap_appl_code,cap_prod_catg,cap_prfl_levl
            INTO l_hash_pan, l_encr_pan, l_acct_no, l_cust_code,
                 l_card_stat, l_prod_code, l_prod_cattype,l_startercard_flag,
                 l_expry_date, l_active_date, l_prfl_code,l_disp_name,
                 l_proxynumber,l_appl_code, l_cap_prod_catg,l_prfl_levl
            FROM cms_appl_pan
           WHERE cap_inst_code = p_inst_code_in
             AND cap_mbr_numb = '000'
             AND cap_pan_code  = gethash(p_pan_code_in);
         EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' || gethash(p_pan_code_in);
                 RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

--Sn pan  details

-- Sn Transaction Details  procedure call
         BEGIN
            vmscommon.get_transaction_details (p_inst_code_in,
                                               p_delivery_channel_in,
                                               l_txn_code_in,
                                               l_cr_dr_flag,
                                               l_txn_type,
                                               l_txn_desc,
                                               l_prfl_flag,
                                               l_preauth_flag,
                                               l_login_txn,
                                               l_preauth_type,
                                               l_dup_rrn_check,
                                               p_resp_code_out,
                                               l_errmsg
                                              );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                  'Error from Transaction Details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En Transaction Details  procedure call

         -- Sn validating Date Time RRN
         IF l_dup_rrn_check = 'Y' THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out);

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                  'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         END IF;
         -- En validating Date Time RRN

         --SN : authorize_nonfinancial_txn check
         BEGIN
            vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
                                                  p_msg_type_in,
                                                  p_rrn_in,
                                                  p_delivery_channel_in,
                                                  l_txn_code_in,
                                                  0,
                                                  p_trandate_in,
                                                  p_trantime_in,
                                                  '00',
                                                  l_txn_type,
                                                  p_pan_code_in,
                                                  l_hash_pan,
                                                  l_encr_pan,
                                                  l_acct_no,
                                                  l_card_stat,
                                                  l_expry_date,
                                                  l_prod_code,
                                                  l_prod_cattype,
                                                  l_prfl_flag,
                                                  l_prfl_code,
                                                  l_txn_type,
                                                  p_curr_code_in,
                                                  l_preauth_flag,
                                                  l_txn_desc,
                                                  l_cr_dr_flag,
                                                  l_login_txn,
                                                  p_resp_code_out,
                                                  l_errmsg,
                                                  l_comb_hash,
                                                  l_auth_id,
                                                  l_fee_code,
                                                  l_fee_plan,
                                                  l_feeattach_type,
                                                  l_tranfee_amt,
                                                  l_total_amt,
                                                  l_preauth_type
                                                 );

            IF l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error from authorize_nonfinancial_txn '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
    --SN : authorize_nonfinancial_txn check


	      if  l_startercard_flag = 'Y'   then
           p_resp_code_out := '156';
           l_errmsg  := 'Replacement Not Allowed For Starter Card '||fn_getmaskpan(p_pan_code_in);
           RAISE EXP_REJECT_RECORD;
        end if;


         BEGIN
             SELECT COUNT (1)
               INTO l_dup_check
               FROM cms_htlst_reisu
              WHERE chr_inst_code = p_inst_code_in
                AND chr_pan_code = l_hash_pan
                AND chr_reisu_cause = 'R'
                AND chr_new_pan IS NOT NULL;

             IF l_dup_check > 0
             THEN
                SELECT DECODE (p_delivery_channel_in, '10', '159', '13', '159', '07', '160')
                INTO p_resp_code_out
                FROM DUAL;
                l_errmsg := 'Card already Replaced';
                RAISE exp_reject_record;
             END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=  'Error selecting cms_htlst_reisu'  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


	     BEGIN
          SELECT CAM_LUPD_DATE
          INTO l_cam_lupd_date
          FROM CMS_ADDR_MAST
          WHERE CAM_INST_CODE=p_inst_code_in
          AND CAM_CUST_CODE=l_cust_code
          AND CAM_ADDR_FLAG='P';

          IF l_cam_lupd_date > sysdate-1 THEN
            l_errmsg  := 'Card replacement is not allowed to customer who changed address in last 24 hr';
             p_resp_code_out := '21';
             RAISE EXP_REJECT_RECORD;
          END IF;

        EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
        RAISE;
        WHEN OTHERS THEN
        l_errmsg  := 'Error while selecting customer address details' ||  SUBSTR(SQLERRM, 1, 200);
           p_resp_code_out := '21';
           RAISE EXP_REJECT_RECORD;
        END;



	BEGIN
         SELECT COUNT(*)
           INTO l_crdstat_cnt
           FROM CMS_REISSUE_VALIDSTAT
          WHERE CRV_INST_CODE = p_inst_code_in AND
               CRV_VALID_CRDSTAT = l_card_stat AND CRV_PROD_CATG IN ('P');
         IF l_crdstat_cnt = 0 THEN
           l_errmsg  := 'Not a valid card status. Card cannot be reissued';
           p_resp_code_out := '09';
           RAISE EXP_REJECT_RECORD;
         END IF;
    EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
    RAISE;
    WHEN OTHERS THEN
    l_errmsg  := 'Error while selecting l_crdstat_cnt' ||  SUBSTR(SQLERRM, 1, 200);
       p_resp_code_out := '21';
       RAISE EXP_REJECT_RECORD;
    END;


	BEGIN
           SELECT NVL (cpc_renew_replace_option, 'NP'),
                  cpc_profile_code,
                  CPC_RENEW_REPLACE_PRODCODE,
                  CPC_RENEW_REPLACE_CARDTYPE,
                  CPC_DISABLE_REPL_FLAG,
                  NVL(CPC_DISABLE_REPL_EXPRYDAYS,0),
                  NVL(CPC_DISABLE_REPL_MINBAL,0),
                  CPC_DISABLE_REPL_MESSAGE
             INTO l_replacement_option,
                  l_profile_code,
                  l_new_product,
                  l_new_cardtype,
                  l_disable_repl_flag,
                  l_disable_repl_expdays,
                  l_disable_repl_minbal,
                  l_disable_repl_message
             FROM cms_prod_cattype
            WHERE     cpc_inst_code = p_inst_code_in
                  AND cpc_prod_code = l_prod_code
                  AND cpc_card_type = l_prod_cattype;
        EXCEPTION
           WHEN OTHERS
           THEN
              l_errmsg :=
                 'Error while selecting replacement param '
                 || SUBSTR (SQLERRM, 1, 200);
              p_resp_code_out := '21';
              RAISE exp_reject_record;
        END;

         BEGIN
           SELECT CAM_ACCT_BAL
            INTO l_acct_bal
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO = l_acct_no AND
                  CAM_INST_CODE = p_inst_code_in;
         EXCEPTION
           WHEN OTHERS THEN
            l_acct_bal := 0;
            l_ledger_bal   := 0;
         end;

    BEGIN
        if l_disable_repl_flag = 'Y' then
          if sysdate between (l_expry_date-l_disable_repl_expdays) and l_expry_date then
            l_errmsg := l_disable_repl_message;
            p_resp_code_out := '269';
            RAISE EXP_REJECT_RECORD;
          ELSIF NVL(l_acct_bal,0) <= l_disable_repl_minbal  then
              l_errmsg := l_disable_repl_message;
              p_resp_code_out := '269';
              RAISE EXP_REJECT_RECORD;
          end if;
        end if;
    EXCEPTION
      WHEN exp_reject_record
        then
        RAISE;
       WHEN OTHERS
       THEN
          l_errmsg :=
             'Error while selecting replacement param '
             || SUBSTR (SQLERRM, 1, 200);
          p_resp_code_out := '21';
          RAISE EXP_REJECT_RECORD;
    END;

    IF (l_txn_code_in = '47' AND p_delivery_channel_in = '07') OR
        (l_txn_code_in = '11' AND p_delivery_channel_in = '10') OR
		 (l_txn_code_in = '76' AND p_delivery_channel_in = '13')
     THEN
              l_repl_flag := 6;
     ELSIF (l_txn_code_in = '48' AND p_delivery_channel_in = '07') OR
            (l_txn_code_in = '99' AND p_delivery_channel_in = '10') OR
			 (l_txn_code_in = '77' AND p_delivery_channel_in = '13')
     THEN
              l_repl_flag := 7;
     END IF;


	IF l_replacement_option = 'SP' AND l_card_stat <> '2' THEN
          IF l_profile_code IS NULL
          THEN
             l_errmsg := 'Profile is not Attached to Product CatType';
             p_resp_code_out := '21';
             RAISE exp_reject_record;
          END IF;

          BEGIN
            vmsfunutilities.get_expiry_date(p_inst_code_in,l_prod_code,
            l_prod_cattype,l_PROFILE_CODE,l_expry_date,l_errmsg);

            if l_errmsg<>'OK' then
                RAISE exp_reject_record;
             END IF;


          EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
                RAISE;
              WHEN OTHERS THEN
                l_errmsg:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
                RAISE exp_reject_record;
          END;


           BEGIN
             UPDATE cms_appl_pan
                SET cap_replace_exprydt = l_expry_date,
                        cap_repl_flag =  l_repl_flag,
                        cap_activation_code = NVL(cap_activation_code,p_activation_code)
              WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;

             IF SQL%ROWCOUNT <> 1
             THEN
                l_errmsg := 'Error while updating appl_pan ';
                p_resp_code_out := '21';
                RAISE exp_reject_record;
             END IF;
          EXCEPTION
             WHEN exp_reject_record
             THEN
                RAISE;
             WHEN OTHERS
             THEN
                l_errmsg :=
                   'Error while updating Expiry Date' || SUBSTR (SQLERRM, 1, 200);
                p_resp_code_out := '21';
                RAISE exp_reject_record;
          END;

          BEGIN
             UPDATE cms_cardissuance_status
                SET ccs_card_status = '20'
              WHERE ccs_inst_code = p_inst_code_in AND ccs_pan_code = l_hash_pan;

             IF SQL%ROWCOUNT <> 1
             THEN
                l_errmsg := 'Error while updating CMS_CARDISSUANCE_STATUS ';
                p_resp_code_out := '21';
                RAISE exp_reject_record;
             END IF;
          EXCEPTION
             WHEN exp_reject_record
             THEN
                RAISE;
             WHEN OTHERS
             THEN
                l_errmsg :=
                   'Error while updating Application Card Issuance Status'
                   || SUBSTR (SQLERRM, 1, 200);
                p_resp_code_out := '21';
                RAISE exp_reject_record;
          END;

     ELSE
          IF l_replacement_option='NPP' THEN
               l_prod_code:=l_new_product;
               l_prod_cattype:=l_new_cardtype;
          END IF;


        BEGIN
         SELECT CRO_OLDCARD_REISSUE_STAT
           INTO l_cro_oldcard_reissue_stat
           FROM CMS_REISSUE_OLDCARDSTAT
          WHERE CRO_INST_CODE = p_inst_code_in AND
               CRO_OLDCARD_STAT = l_card_stat AND CRO_SPPRT_KEY = 'R';
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_errmsg  := 'Default old card status nor defined for institution ' ||
                      p_inst_code_in;
           p_resp_code_out := '09';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           l_errmsg  := 'Error while getting default old card status for institution ' ||
                      p_inst_code_in;
           p_resp_code_out := '21';
           RAISE EXP_REJECT_RECORD;
        END;

        BEGIN

         UPDATE CMS_APPL_PAN
            SET CAP_CARD_STAT = l_cro_oldcard_reissue_stat,
               CAP_LUPD_USER = p_inst_code_in
          WHERE CAP_INST_CODE = p_inst_code_in AND CAP_PAN_CODE = l_HASH_PAN;
         IF SQL%ROWCOUNT != 1 THEN
           l_errmsg  := 'Problem in updation of status for pan ' ||
                      l_HASH_PAN;
           p_resp_code_out := '09';
           RAISE EXP_REJECT_RECORD;
         END IF;

         if l_cro_oldcard_reissue_stat='9' then
         p_closed_card := p_pan_code_in;
         p_closed_card_hash := l_hash_pan;
         end if;

        EXCEPTION
         WHEN OTHERS THEN
           l_errmsg  := 'Error while updating CMS_APPL_PAN' ||
                      SUBSTR(SQLERRM, 1, 200);
           p_resp_code_out := '21';
           RAISE EXP_REJECT_RECORD;
        END;


        IF l_cro_oldcard_reissue_stat='9' THEN

        BEGIN
           sp_log_cardstat_chnge (p_inst_code_in,
                                  l_hash_pan,
                                  l_encr_pan,
                                  l_auth_id,
                                  '02',
                                  p_rrn_in,
                                  p_trandate_in,
                                  p_trantime_in,
                                  p_resp_code_out,
                                  l_errmsg
                                 );

           IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
           THEN
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              p_resp_code_out := '21';
              l_errmsg :=
                    'Error while logging system initiated card status change '
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;

          END IF;


	 BEGIN
         SP_ORDER_REISSUEPAN_CMS(p_inst_code_in,
                            p_pan_code_in,
                            l_prod_code,
                            l_prod_cattype,
                            l_disp_name,
                            p_inst_code_in,
                            l_new_card_no,
                            l_errmsg);
         IF l_errmsg != 'OK' THEN
           l_errmsg  := 'From reissue pan generation process-- ' || l_errmsg;
           p_resp_code_out := '21';
           RAISE EXP_REJECT_RECORD;

         END IF;
        EXCEPTION WHEN EXP_REJECT_RECORD
        THEN
            RAISE;
         WHEN OTHERS THEN
           l_errmsg  := 'From reissue pan generation process-- ' || l_errmsg;
           p_resp_code_out := '21';
           RAISE EXP_REJECT_RECORD;

        END;

        BEGIN
         l_new_hash_pan := GETHASH(l_new_card_no);
        EXCEPTION
         WHEN OTHERS THEN
           l_errmsg := 'Error while converting new pan. into hash value ' ||fn_getmaskpan(l_new_card_no)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;


         BEGIN
           SELECT cap_expry_date
             INTO l_expry_date
             FROM cms_appl_pan
            WHERE cap_pan_code = l_new_hash_pan AND cap_inst_code = p_inst_code_in;
        EXCEPTION
           WHEN OTHERS
           THEN
              l_errmsg :=
                 'Error while selecting new expry date' || SUBSTR (SQLERRM, 1, 200);
              p_resp_code_out := '21';
              RAISE exp_reject_record;
        END;

            BEGIN
               UPDATE cms_appl_pan
                  SET cap_repl_flag = l_repl_flag,
                  cap_activation_code = p_activation_code
                WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = l_new_hash_pan;

               IF SQL%ROWCOUNT = 0
               THEN
                  l_errmsg :=
                        'Problem in updation of replacement flag for pan '
                     || fn_getmaskpan (l_new_card_no);
                  p_resp_code_out := '21';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
            WHEN EXP_REJECT_RECORD
                  THEN
                      RAISE;
               WHEN OTHERS
               THEN
                  l_errmsg :=
                          'Error while updating CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
                  p_resp_code_out := '21';
                  RAISE exp_reject_record;
            END;
	  BEGIN
              INSERT INTO CMS_CARD_EXCPFEE(CCE_INST_CODE,CCE_PAN_CODE,CCE_INS_DATE,cce_ins_user,CCE_LUPD_USER,CCE_LUPD_DATE,CCE_FEE_PLAN,CCE_FLOW_SOURCE,
              CCE_VALID_FROM,CCE_VALID_TO,CCE_PAN_CODE_ENCR,CCE_MBR_NUMB)
              (SELECT  CCE_INST_CODE,GETHASH(l_new_card_no),sysdate,cce_ins_user,CCE_LUPD_USER,sysdate,CCE_FEE_PLAN,CCE_FLOW_SOURCE,
              (case when cce_valid_from>=trunc(sysdate) then cce_valid_from else sysdate end)cce_valid_from,
               CCE_VALID_TO,FN_EMAPS_MAIN(l_new_card_no),CCE_MBR_NUMB
               FROM CMS_CARD_EXCPFEE WHERE CCE_PAN_CODE=GETHASH(p_pan_code_in) AND CCE_INST_CODE=p_inst_code_in
               AND ((CCE_VALID_TO IS NOT NULL AND (trunc(sysdate) between cce_valid_from and CCE_VALID_TO))
               OR (CCE_VALID_TO IS NULL AND trunc(sysdate) >= cce_valid_from)  or (cce_valid_from >=trunc(sysdate))));

      EXCEPTION
           WHEN OTHERS THEN
            l_errmsg  := 'Error while attaching fee plan to reissuue card ' ||SUBSTR(SQLERRM, 1, 200);
            p_resp_code_out := '21';
            RAISE EXP_REJECT_RECORD;
    END;

    IF l_errmsg = 'OK' THEN

         BEGIN
           INSERT INTO CMS_HTLST_REISU
            (CHR_INST_CODE,
             CHR_PAN_CODE,
             CHR_MBR_NUMB,
             CHR_NEW_PAN,
             CHR_NEW_MBR,
             CHR_REISU_CAUSE,
             CHR_INS_USER,
             CHR_LUPD_USER,
             CHR_PAN_CODE_ENCR,
             CHR_NEW_PAN_ENCR)
           VALUES
            (p_inst_code_in,
             l_hash_pan,
             '000',
             GETHASH(l_new_card_no),
             '000',
             'R',
             p_inst_code_in,
             p_inst_code_in,
             l_encr_pan,
             FN_EMAPS_MAIN(l_new_card_no));
         EXCEPTION
           WHEN OTHERS THEN
            l_errmsg  := 'Error while creating  reissuue record ' ||
                        SUBSTR(SQLERRM, 1, 200);
            p_resp_code_out := '21';
            RAISE EXP_REJECT_RECORD;
         END;

         BEGIN
           INSERT INTO CMS_CARDISSUANCE_STATUS
            (CCS_INST_CODE,
             CCS_PAN_CODE,
             CCS_CARD_STATUS,
             CCS_INS_USER,
             CCS_INS_DATE,
             CCS_PAN_CODE_ENCR,
             CCS_APPL_CODE
             )
           VALUES
            (p_inst_code_in,
             GETHASH(l_new_card_no),
             '2',
             p_inst_code_in,
             SYSDATE,
             FN_EMAPS_MAIN(l_new_card_no),
             l_APPL_CODE
             );
         EXCEPTION
           WHEN OTHERS THEN
            l_errmsg  := 'Error while Inserting CCF table ' ||
                        SUBSTR(SQLERRM, 1, 200);
            p_resp_code_out := '21';
            RAISE EXP_REJECT_RECORD;
         END;

         BEGIN
           INSERT INTO CMS_SMSANDEMAIL_ALERT
            (CSA_INST_CODE,
             CSA_PAN_CODE,
             CSA_PAN_CODE_ENCR,
             CSA_CELLPHONECARRIER,
             CSA_LOADORCREDIT_FLAG,
             CSA_LOWBAL_FLAG,
             CSA_LOWBAL_AMT,
             CSA_NEGBAL_FLAG,
             CSA_HIGHAUTHAMT_FLAG,
             CSA_HIGHAUTHAMT,
             CSA_DAILYBAL_FLAG,
             CSA_BEGIN_TIME,
             CSA_END_TIME,
             CSA_INSUFF_FLAG,
             CSA_INCORRPIN_FLAG,
             CSA_FAST50_FLAG,
             CSA_FEDTAX_REFUND_FLAG,
             CSA_DEPPENDING_FLAG,
             CSA_DEPACCEPTED_FLAG,
             CSA_DEPREJECTED_FLAG,
             CSA_INS_USER,
             CSA_INS_DATE,
             CSA_LUPD_USER,
             CSA_LUPD_DATE,
             csa_alert_lang_id)
            (SELECT p_inst_code_in,
                   GETHASH(l_new_card_no),
                   FN_EMAPS_MAIN(l_new_card_no),
                   NVL(CSA_CELLPHONECARRIER, 0),
                   CSA_LOADORCREDIT_FLAG,
                   CSA_LOWBAL_FLAG,
                   NVL(CSA_LOWBAL_AMT, 0),
                   CSA_NEGBAL_FLAG,
                   CSA_HIGHAUTHAMT_FLAG,
                   NVL(CSA_HIGHAUTHAMT, 0),
                   CSA_DAILYBAL_FLAG,
                   NVL(CSA_BEGIN_TIME, 0),
                   NVL(CSA_END_TIME, 0),
                   CSA_INSUFF_FLAG,
                   CSA_INCORRPIN_FLAG,
                   CSA_FAST50_FLAG,
                   CSA_FEDTAX_REFUND_FLAG,
                   CSA_DEPPENDING_FLAG,
                   CSA_DEPACCEPTED_FLAG,
                   CSA_DEPREJECTED_FLAG,
                   p_inst_code_in,
                   SYSDATE,
                   p_inst_code_in,
                   SYSDATE,
                   csa_alert_lang_id
               FROM CMS_SMSANDEMAIL_ALERT
              WHERE CSA_INST_CODE = p_inst_code_in AND CSA_PAN_CODE = l_hash_pan);
           IF SQL%ROWCOUNT != 1 THEN
            l_errmsg  := 'Error while Entering sms email alert detail 123' ||
                        SUBSTR(SQLERRM, 1, 200);
            p_resp_code_out := '21';
            RAISE EXP_REJECT_RECORD;
           END IF;
         EXCEPTION
		 WHEN DUP_VAL_ON_INDEX THEN null;
         WHEN EXP_REJECT_RECORD
              THEN
                  RAISE;
           WHEN OTHERS THEN
            l_errmsg  := 'Error while Entering sms email alert detail 234' ||
                        SUBSTR(SQLERRM, 1, 200);
            p_resp_code_out := '21';
            RAISE EXP_REJECT_RECORD;
         END;

       BEGIN
              SP_LOGAVQSTATUS(
              p_inst_code_in,
              p_delivery_channel_in,
              l_new_card_no,
              l_prod_code,
              l_cust_code,
              p_resp_code_out,
              l_errmsg,
              l_prod_cattype
              );
            IF l_errmsg != 'OK' THEN
               l_errmsg  := 'Exception while calling LOGAVQSTATUS-- ' || l_errmsg;
               p_resp_code_out := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
        EXCEPTION WHEN EXP_REJECT_RECORD
        THEN  RAISE;
        WHEN OTHERS THEN
           l_errmsg  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
           p_resp_code_out := '21';
           RAISE EXP_REJECT_RECORD;
        END;

        IF l_prfl_code IS NULL OR l_prfl_levl IS NULL
   THEN

      BEGIN
         SELECT cpl_lmtprfl_id
           INTO l_prfl_code
           FROM cms_prdcattype_lmtprfl
          WHERE cpl_inst_code = p_inst_code_in
            AND cpl_prod_code = l_prod_code
            AND cpl_card_type = l_prod_cattype;

         l_prfl_levl := 2;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT cpl_lmtprfl_id
                 INTO l_prfl_code
                 FROM cms_prod_lmtprfl
                WHERE cpl_inst_code = p_inst_code_in
                  AND cpl_prod_code = l_prod_code;

               l_prfl_levl := 3;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                        'Error while selecting Limit Profile At Product Level'||
                     SUBSTR(SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting Limit Profile At Product Catagory Level'
               || SUBSTR(SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

   IF l_prfl_code IS NOT NULL
   THEN
      BEGIN
         UPDATE cms_appl_pan
            SET cap_prfl_code = l_prfl_code,
                cap_prfl_levl = l_prfl_levl
         WHERE  cap_inst_code = p_inst_code_in AND cap_pan_code = l_new_hash_pan;

         IF SQL%ROWCOUNT = 0
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Limit Profile not updated for :' || l_hash_pan;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
               'Error while Limit profile Update '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;


    END IF;


	END IF;


    p_respmsg_out := l_new_card_no;

         BEGIN
           SELECT CSR_SPPRT_RSNCODE
            INTO l_resoncode
            FROM CMS_SPPRT_REASONS
            WHERE CSR_INST_CODE = p_inst_code_in AND CSR_SPPRT_KEY = 'REISSUE' AND
                ROWNUM < 2;

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            p_resp_code_out := '21';
            l_errmsg  := 'Order Replacement card reason code is present in master';
            RAISE EXP_REJECT_RECORD;
           WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg  := 'Error while selecting reason code from master' ||
                        SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
         END;

         BEGIN
           INSERT INTO CMS_PAN_SPPRT
            (CPS_INST_CODE,
             CPS_PAN_CODE,
             CPS_MBR_NUMB,
             CPS_PROD_CATG,
             CPS_SPPRT_KEY,
             CPS_SPPRT_RSNCODE,
             CPS_FUNC_REMARK,
             CPS_INS_USER,
             CPS_LUPD_USER,
             CPS_CMD_MODE,
             CPS_PAN_CODE_ENCR)
           VALUES
            (p_inst_code_in,
             l_hash_pan,
             '000',
             l_cap_prod_catg,
             'REISSUE',
             l_resoncode,
             l_REMRK,
             p_inst_code_in,
             p_inst_code_in,
             0,
             l_encr_pan);
         EXCEPTION
           WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg  := 'Error while inserting records into card support master' ||
                        SUBSTR(SQLERRM, 1, 200);

            RAISE EXP_REJECT_RECORD;
         END;

    p_resp_code_out := '1';
      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE     cms_inst_code = p_inst_code_in
                AND cms_delivery_channel = p_delivery_channel_in
                AND cms_response_id = TO_NUMBER (p_resp_code_out);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_errmsg :=
                  'Problem while selecting respose code'
               || p_resp_code_out
               || ' is-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
      END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_channel_in
               || l_txn_code_in
               || p_pan_code_in
               || p_rrn_in
               || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
               'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN
         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_TYPE_CODE
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM CMS_ACCT_MAST
          WHERE CAM_INST_CODE = p_inst_code_in AND CAM_ACCT_NO = l_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card /Account ';
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg := 'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      IF p_resp_code_out <> '00'
      THEN
          p_respmsg_out := l_errmsg;
      END IF;

      BEGIN
             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE
               INTO l_prod_code,
                    l_prod_cattype
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = p_inst_code_in AND CAP_PAN_CODE = l_HASH_PAN;
         EXCEPTION
         WHEN OTHERS THEN

         NULL;

         END;

      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     l_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_prod_cattype,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
               'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
END replace_card;

Procedure      activate_card ( p_inst_code_in            IN       NUMBER,
                                       p_delivery_chnl_in        IN       VARCHAR2,
                                       p_txn_code_in             IN       VARCHAR2,
                                       p_rrn_in                  IN       VARCHAR2,
                                       p_cust_id_in              IN       NUMBER,
                                       p_partner_id_in           IN       VARCHAR2,
                                       p_tran_date_in            IN       VARCHAR2,
                                       p_tran_time_in            IN       VARCHAR2,
                                       p_curr_code_in            IN       VARCHAR2,
                                       p_revrsl_code_in          IN       VARCHAR2,
                                       p_msg_type_in             IN       VARCHAR2,
                                       p_ip_addr_in              IN       VARCHAR2,
                                       p_ani_in                  IN       VARCHAR2,
                                       p_dni_in                  IN       VARCHAR2,
                                       p_device_mobno_in         IN       VARCHAR2,
                                       p_device_id_in            IN       VARCHAR2,
                                       p_uuid_in                 IN       VARCHAR2,
                                       p_osname_in               IN       VARCHAR2,
                                       p_osversion_in            IN       VARCHAR2,
                                       p_gps_coordinates_in      IN       VARCHAR2,
                                       p_display_resolution_in   IN       VARCHAR2,
                                       p_physical_memory_in      IN       VARCHAR2,
                                       p_appname_in              IN       VARCHAR2,
                                       p_appversion_in           IN       VARCHAR2,
                                       p_sessionid_in            IN       VARCHAR2,
                                       p_device_country_in       IN       VARCHAR2,
                                       p_device_region_in        IN       VARCHAR2,
                                       p_ipcountry_in            IN       VARCHAR2,
                                       p_proxy_flag_in           IN       VARCHAR2,
                                       p_pan_code_in             IN       VARCHAR2,
                                       p_resp_code_out           OUT      VARCHAR2,
                                       p_resp_msg_out            OUT      VARCHAR2 )
AS
   l_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   l_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
   l_acct_no            cms_acct_mast.cam_acct_no%TYPE;
   l_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
   l_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   l_prod_code          cms_appl_pan.cap_prod_code%TYPE;
   l_prod_cattype       cms_appl_pan.cap_card_type%TYPE;
   l_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   l_expry_date         cms_appl_pan.cap_expry_date%TYPE;
   l_active_date        cms_appl_pan.cap_active_date%TYPE;
   l_prfl_code          cms_appl_pan.cap_prfl_code%TYPE;
   l_cr_dr_flag         cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_txn_type           cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_desc           cms_transaction_mast.ctm_tran_desc%TYPE;
   l_prfl_flag          cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_comb_hash          pkg_limits_check.type_hash;
   l_auth_id            cms_transaction_log_dtl.ctd_auth_id%TYPE;
   l_timestamp          TIMESTAMP;
   l_preauth_flag       cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_trans_desc         cms_transaction_mast.ctm_tran_desc%TYPE;
   l_dup_rrn_check      cms_transaction_mast.ctm_rrn_check%TYPE;
   l_acct_type          cms_acct_mast.cam_type_code%TYPE;
   l_login_txn          cms_transaction_mast.ctm_login_txn%TYPE;
   l_fee_code           cms_fee_mast.cfm_fee_code%TYPE;
   l_fee_plan           cms_fee_feeplan.cff_fee_plan%TYPE;
   l_feeattach_type     transactionlog.feeattachtype%TYPE;
   l_tranfee_amt        transactionlog.tranfee_amt%TYPE;
   l_total_amt          cms_acct_mast.cam_acct_bal%TYPE;
   l_preauth_type       cms_transaction_mast.ctm_preauth_type%TYPE;
   l_hashkey_id         cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_proxynumber        cms_appl_pan.cap_proxy_number%TYPE;
   l_errmsg             VARCHAR2 (500);
   l_appl_code          cms_appl_pan.cap_appl_code%TYPE;
   l_cust_code          cms_appl_pan.cap_cust_code%TYPE;
   l_kyc_flag           cms_caf_info_entry.cci_kyc_flag%TYPE;
   L_User_Name          Cms_Cust_Mast.Ccm_User_Name%Type;
   L_Atmonline_Limit    Cms_Appl_Pan.Cap_Atm_Online_Limit%Type;
   L_posonline_Limit    Cms_Appl_Pan.Cap_Pos_Online_Limit%Type;
   L_Cap_Prod_Catg      Cms_Appl_Pan.Cap_Prod_Catg%Type;
   L_Cap_Cafgen_Flag    Cms_Appl_Pan.Cap_Cafgen_Flag%Type;
   L_Firsttime_Topup    Cms_Appl_Pan.Cap_Firsttime_Topup%Type;
   L_Mbrnumb            Cms_Appl_Pan.Cap_Mbr_Numb%Type;
   L_Pin_Offset         Cms_Appl_Pan.Cap_Pin_Off%Type;
   L_Inst_Code          Cms_Appl_Pan.Cap_Inst_Code%Type;
   L_Profile_Level      Cms_Appl_Pan.Cap_Prfl_Levl%Type;
   L_Starter_Card_Flag  Cms_Appl_Pan.Cap_Startercard_Flag%Type;
   L_Replace_Expdt      Cms_Appl_Pan.Cap_Replace_Exprydt%Type;
   L_Oldcrd             Cms_Htlst_Reisu.Chr_Pan_Code%Type;
   L_Oldcrd_Encr        Cms_Appl_Pan.Cap_Pan_Code_Encr%Type;
   l_ssn                cms_cust_mast.ccm_ssn%TYPE;
   l_FLDOB_HASHKEY_ID   CMS_CUST_MAST.CCM_FLNAMEDOB_HASHKEY%TYPE;
   l_chkcurr            cms_bin_param.cbp_param_value%TYPE;
   l_inil_authid        transactionlog.auth_id%TYPE;
   l_starter_card       cms_appl_pan.cap_pan_code%TYPE;
   l_starter_card_encr  cms_appl_pan.cap_pan_code_encr%TYPE;
   l_dup_check          NUMBER (3);
   l_crdstat_chnge      VARCHAR2(2):='N';
   l_resoncode          cms_spprt_reasons.csr_spprt_rsncode%type;
   L_Remrk              Varchar2 (100);
   L_Oldcardstat        Cms_Appl_Pan.Cap_Card_Stat%Type;
   l_ssn_crddtls        VARCHAR2 (400);
   l_closed_card        varchar2(20);
   Exp_Reject_Record    Exception;
 --l_b2bcard_status     CMS_PROD_CATTYPE.cpC_b2bcard_stat%type;
   L_RENEWAL_CARD_HASH  cms_appl_pan.cap_pan_code%TYPE;
   L_RENEWAL_CARD_ENCR  cms_appl_pan.CAP_PAN_CODE_ENCR%TYPE;
   L_oldcrd_clear       varchar2(30);
   l_prod_type          cms_product_param.cpp_product_type%type;
   l_user_type          CMS_PROD_CATTYPE.CPC_USER_IDENTIFY_TYPE%type;
   l_req_card_stat      cms_appl_pan.CAP_CARD_STAT%type;
   l_req_txn_code       cms_transaction_mast.ctm_tran_code%type;
   l_status_chnge       VARCHAR2(2):='N';
   l_card_closer_flag   varchar(2) :='Y';
   L_DEFUND_FLAG        	CMS_ACCT_MAST.CAM_DEFUND_FLAG%TYPE;
   L_ORDER_PROD_FUND    	VMS_ORDER_LINEITEM.VOL_PRODUCT_FUNDING%TYPE;
   L_LINEITEM_DENOM     	VMS_ORDER_LINEITEM.VOL_DENOMINATION%TYPE;
   L_PROD_FUND		     	CMS_PROD_CATTYPE.CPC_PRODUCT_FUNDING%TYPE;
   L_FUND_AMT           	CMS_PROD_CATTYPE.CPC_FUND_AMOUNT%TYPE;
   L_ORDER_FUND_AMT     	VMS_ORDER_LINEITEM.VOL_FUND_AMOUNT%TYPE;
   L_PROFILE_CODE       	CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
   L_INITIALLOAD_AMOUNT		CMS_ACCT_MAST.CAM_INITIALLOAD_AMT%TYPE;
   L_ACTIVECARD_COUNT		PLS_INTEGER;
   L_TXN_AMT             	NUMBER;
   L_REMARK                 TRANSACTIONLOG.REMARK%TYPE;
   L_REPL_ORDER             VMS_ORDER_LINEITEM.VOL_ORDER_ID%TYPE;
   L_PARAM_VALUE            CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
   L_TXN_CODE               cms_transaction_mast.CTM_TRAN_CODE%TYPE;--Added for VMS_7196
   L_TOGGLE_VALUE           cms_inst_param.cip_param_value%TYPE;--Added for VMS_7196
   L_OLD_PAN                CMS_APPL_PAN.CAP_PAN_CODE%TYPE; --Added for VMS_7196
   l_log_flag               VARCHAR2(1):='Y';
BEGIN
  BEGIN
         p_resp_code_out := '00';
         p_resp_msg_out := 'success';
		     l_REMRK    := 'Card Activation';
         l_errmsg :='OK';
		 L_TXN_AMT := 0;
       l_txn_code := p_txn_code_in;--Added for VMS_7196
      BEGIN
         vmscommon.get_transaction_details (p_inst_code_in,
                                            p_delivery_chnl_in,
                                            l_txn_code,
                                            l_cr_dr_flag,
                                            l_txn_type,
                                            l_txn_desc,
                                            l_prfl_flag,
                                            l_preauth_flag,
                                            l_login_txn,
                                            l_preauth_type,
                                            l_dup_rrn_check,
                                            p_resp_code_out,
                                            l_errmsg
                                           );

        IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
          THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error from Transaction Details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no, cap_card_stat,
                cap_prod_code, cap_card_type, cap_expry_date,
                Cap_Active_Date, Cap_Prfl_Code, Cap_Proxy_Number,
                Cap_Appl_Code, Cap_Cust_Code,Cap_Atm_Online_Limit, Cap_Pos_Online_Limit,
                Cap_Prod_Catg,Cap_Cafgen_Flag,Cap_Firsttime_Topup,
                Cap_Mbr_Numb,Cap_Pin_Off,Cap_Inst_Code,
                Cap_Prfl_Levl,Cap_Startercard_Flag,cap_replace_exprydt
           INTO l_hash_pan, l_encr_pan, l_acct_no, l_card_stat,
                L_Prod_Code, L_Prod_Cattype, L_Expry_Date,
                L_Active_Date, L_Prfl_Code, L_Proxynumber,
                l_appl_code, l_cust_code, l_atmonline_limit, L_posonline_Limit, l_cap_prod_catg,
             l_Cap_Cafgen_Flag,l_Firsttime_Topup,
             l_Mbrnumb, l_Pin_Offset,l_Inst_Code,l_Profile_Level, l_Starter_Card_Flag,
               l_replace_expdt
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            And Cap_Mbr_Numb = '000';
              dbms_output.put_line( 'l_replace_expdt ' || l_replace_expdt);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting CMS_APPL_PAN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;


BEGIN
          SELECT nvl(CPC_USER_IDENTIFY_TYPE,'0')
          INTO l_user_type
          FROM CMS_PROD_CATTYPE
          WHERE CPC_PROD_CODE = l_prod_code
          AND CPC_CARD_TYPE = L_Prod_Cattype
          AND CPC_INST_CODE=p_inst_code_in;
          EXCEPTION
          WHEN OTHERS THEN
           p_resp_code_out := '21';
           l_errmsg :='Error while getting Profile -' || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_reject_record;
          END;



      IF l_dup_rrn_check = 'Y' THEN
      BEGIN
         vmscommon.validate_date_rrn (p_inst_code_in,
                                      p_rrn_in,
                                      p_tran_date_in,
                                      p_tran_time_in,
                                      p_delivery_chnl_in,
                                      l_errmsg,
                                      p_resp_code_out
                                     );

         IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '22';
            l_errmsg :=
                  'Error while validating DATE AND RRN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      END IF;

		BEGIN
			SELECT  CAM_ACCT_BAL, CAM_LEDGER_BAL,NVL(CAM_DEFUND_FLAG,'N'),NVL(CAM_NEW_INITIALLOAD_AMT,CAM_INITIALLOAD_AMT)
            INTO L_ACCT_BAL, L_LEDGER_BAL,L_DEFUND_FLAG,L_INITIALLOAD_AMOUNT
            FROM CMS_ACCT_MAST
           WHERE CAM_ACCT_NO = L_ACCT_NO
             AND CAM_INST_CODE = P_INST_CODE_IN
             FOR UPDATE;
		EXCEPTION
		  WHEN OTHERS
		  THEN
			 P_RESP_CODE_OUT := '12';
			 L_ERRMSG :=
				   'ERROR WHILE SELECTING DATA FROM ACCOUNT MASTER FOR CARD NUMBER '
				|| L_HASH_PAN
				|| SUBSTR (SQLERRM, 1, 100);
			 RAISE EXP_REJECT_RECORD;
		END;

		BEGIN
			SELECT
				NVL(CIP_PARAM_VALUE,'N')
			INTO
				L_PARAM_VALUE
			FROM
				CMS_INST_PARAM
			WHERE
				CIP_PARAM_KEY = 'VMS_4727_TOGGLE'
				AND CIP_INST_CODE = 1;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				        L_PARAM_VALUE := 'N';
				WHEN OTHERS THEN
				        P_RESP_CODE_OUT := '12';
				        L_ERRMSG := 'Error while selecting data from inst param '|| SUBSTR (SQLERRM, 1, 100);
				 RAISE EXP_REJECT_RECORD;
		   END;

		   IF l_txn_code = '09' AND  L_ACTIVE_DATE IS NULL AND L_DEFUND_FLAG = 'Y' AND L_ACCT_BAL = 0 AND L_PARAM_VALUE = 'N'
		   THEN

				BEGIN
					  SELECT TO_NUMBER(NVL(LINEITEM.VOL_DENOMINATION,'0')),LINEITEM.VOL_PRODUCT_FUNDING,LINEITEM.VOL_FUND_AMOUNT,UPPER(SUBSTR(VOL_ORDER_ID,1,4))
					  INTO L_LINEITEM_DENOM,L_ORDER_PROD_FUND,L_ORDER_FUND_AMT,L_REPL_ORDER
					  FROM
						VMS_LINE_ITEM_DTL DETAIL,
						VMS_ORDER_LINEITEM LINEITEM
					  WHERE
					   DETAIL.VLI_ORDER_ID= LINEITEM.VOL_ORDER_ID
					  AND DETAIL.VLI_PARTNER_ID=LINEITEM.VOL_PARTNER_ID
					  AND DETAIL.VLI_LINEITEM_ID = LINEITEM.VOL_LINE_ITEM_ID
					  AND DETAIL.VLI_PAN_CODE  = L_HASH_PAN;

			  ---    v_order_prod_fund = 1 / 'Load on Order'
			  ---    v_order_prod_fund = 2 / 'Load on Activation'

							IF L_LINEITEM_DENOM = 0 AND L_REPL_ORDER = 'ROID' THEN

								SELECT
									COUNT(1)
								INTO
									L_ACTIVECARD_COUNT
								FROM
									CMS_APPL_PAN
								WHERE
									CAP_INST_CODE = P_INST_CODE_IN
									AND CAP_ACCT_NO = L_ACCT_NO
									AND CAP_ACTIVE_DATE IS NOT NULL;

								IF L_ACTIVECARD_COUNT = 0 THEN

								       L_LINEITEM_DENOM := L_INITIALLOAD_AMOUNT;
								ELSE
								       L_LINEITEM_DENOM := 0;
								END IF;

							END IF;

							 L_TXN_AMT := L_LINEITEM_DENOM;


			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					NULL;
				WHEN OTHERS
				THEN
					P_RESP_CODE_OUT := '12';
					L_ERRMSG := 'ERROR WHILE SELECTING DENOMINATION DETAILS -  ' || L_HASH_PAN || SUBSTR (SQLERRM, 1, 100);
					RAISE EXP_REJECT_RECORD;
				END;

			END IF;
--Sn added for VMS_7196
            BEGIN
                SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
                INTO l_toggle_value
                FROM vmscms.cms_inst_param
                    WHERE cip_inst_code = 1
                    AND cip_param_key = 'VMS_7196_TOGGLE';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                     l_toggle_value := 'Y';
            END;


            IF l_toggle_value = 'Y' THEN
                IF l_defund_flag='N' AND l_initialload_amount=0  THEN

                BEGIN
                    SELECT cap_pan_code
                      INTO l_old_pan
                      FROM (  SELECT cap_pan_code
                                FROM vmscms.cms_appl_pan
                               WHERE     cap_inst_code = 1
                                     AND cap_acct_no = l_acct_no
                                     AND cap_repl_flag = 0
                            ORDER BY cap_ins_date)
                     WHERE ROWNUM = 1;

                    SELECT TO_NUMBER (NVL (lineitem.vol_denomination, '0')),
                           lineitem.vol_fund_amount
                      INTO l_lineitem_denom, l_order_fund_amt
                      FROM vms_line_item_dtl detail, vms_order_lineitem lineitem
                     WHERE     detail.vli_order_id = lineitem.vol_order_id
                           AND detail.vli_partner_id = lineitem.vol_partner_id
                           AND detail.vli_lineitem_id = lineitem.vol_line_item_id
                           AND detail.vli_pan_code = l_old_pan;

                    IF l_order_fund_amt = 1 AND l_lineitem_denom>0 THEN
                        l_txn_amt := l_lineitem_denom;

                        IF p_delivery_chnl_in = '07' THEN
                            l_txn_code := '59';
                        ELSIF p_delivery_chnl_in = '10' THEN
                            l_txn_code := '71';
                        END IF;

                        BEGIN
                            vmscommon.get_transaction_details (p_inst_code_in,
                                                               p_delivery_chnl_in,
                                                               l_txn_code,
                                                               l_cr_dr_flag,
                                                               l_txn_type,
                                                               l_txn_desc,
                                                               l_prfl_flag,
                                                               l_preauth_flag,
                                                               l_login_txn,
                                                               l_preauth_type,
                                                               l_dup_rrn_check,
                                                               p_resp_code_out,
                                                               l_errmsg);

                            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
                            THEN
                                RAISE exp_reject_record;
                            END IF;
                        EXCEPTION
                            WHEN exp_reject_record
                            THEN
                                RAISE;
                            WHEN OTHERS
                            THEN
                                p_resp_code_out := '12';
                                l_errmsg :=
                                       'Error from Transaction Details'
                                    || SUBSTR (SQLERRM, 1, 200);
                                RAISE exp_reject_record;
                        END;
                    END IF;
                EXCEPTION
                    WHEN exp_reject_record
                    THEN
                        RAISE;
                    WHEN NO_DATA_FOUND
                    THEN
                        NULL;
                    WHEN OTHERS
                    THEN
                        p_resp_code_out := '12';
                        l_errmsg :=
                               'ERROR WHILE SELECTING FUND AMOUNT -  '
                            || l_hash_pan
                            || SUBSTR (SQLERRM, 1, 100);
                        RAISE exp_reject_record;
                END;

                END IF;
            END IF;

    IF    (p_delivery_chnl_in = '07' AND l_txn_code = '59')
       OR (p_delivery_chnl_in = '10' AND l_txn_code = '71')
    THEN
       BEGIN
            vmscommon.authorize_financial_txn (   p_inst_code_in,
                                                  p_msg_type_in,
                                                  p_rrn_in,
                                                  p_delivery_chnl_in,
                                                  null,   --p_terminal_id_in
                                                  l_txn_code,
                                                  0,
                                                  p_tran_date_in,
                                                  p_tran_time_in,
                                                  p_pan_code_in,
                                                  l_hash_pan,
                                                  l_encr_pan,
                                                  l_card_stat,
                                                  l_proxynumber,
                                                  l_acct_no,
                                                  l_expry_date,
                                                  l_prod_code,
                                                  l_prod_cattype,
                                                  l_prfl_flag,
                                                  l_prfl_code,
                                                  l_txn_type,
                                                  p_curr_code_in,
                                                  l_preauth_flag,
                                                  l_txn_desc,
                                                  l_cr_dr_flag,
                                                  l_login_txn,
                                                  null,  --ctm_amnt_transfer_flag
                                                  p_inst_code_in,
                                                  L_TXN_AMT,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  p_revrsl_code_in,
                                                  null,
                                                  null,
                                                  p_ip_addr_in,
                                                  p_ani_in,
                                                  p_dni_in,
                                                  p_device_mobno_in,
                                                  p_device_id_in,
                                                  p_uuid_in,
                                                  p_osname_in,
                                                  p_osversion_in,
                                                  p_gps_coordinates_in,
                                                  p_display_resolution_in,
                                                  p_physical_memory_in,
                                                  p_appname_in,
                                                  p_appversion_in,
                                                  p_sessionid_in,
                                                  p_device_country_in,
                                                  p_device_region_in,
                                                  null,
                                                  l_auth_id,
                                                  p_resp_code_out,
                                                  l_errmsg
                                                  );

             IF l_errmsg <> 'OK'
                 THEN
                  RAISE exp_reject_record;
             ELSE
                  l_log_flag:='N';
            END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'ERROR FROM authorize_financial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
    ELSE
    --En added for VMS_7196
      BEGIN
         vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
                                               p_msg_type_in,
                                               p_rrn_in,
                                               p_delivery_chnl_in,
                                                l_txn_code,
                                               0,
                                               p_tran_date_in,
                                               p_tran_time_in,
                                               '00',
                                               l_txn_type,
                                               p_pan_code_in,
                                               l_hash_pan,
                                               l_encr_pan,
                                               l_acct_no,
                                               l_card_stat,
                                               l_expry_date,
                                               l_prod_code,
                                               l_prod_cattype,
                                               l_prfl_flag,
                                               l_prfl_code,
                                               l_txn_type,
                                               p_curr_code_in,
                                               l_preauth_flag,
                                               l_txn_desc,
                                               l_cr_dr_flag,
                                               l_login_txn,
                                               p_resp_code_out,
                                               l_errmsg,
                                               l_comb_hash,
                                               l_auth_id,
                                               l_fee_code,
                                               l_fee_plan,
                                               l_feeattach_type,
                                               l_tranfee_amt,
                                               l_total_amt,
                                               l_preauth_type
                                              );

      IF l_errmsg <> 'OK'
         THEN
          RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'ERROR FROM authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
	    END IF;
if l_replace_expdt is not null then

 l_card_closer_flag :='N';


end if;


  IF l_replace_expdt is null THEN
			  IF l_active_date is not null THEN
				 p_resp_code_out := '27';
				 L_Errmsg := 'Card Activation Already Done';
				 dbms_output.put_line( 'L_Errmsg ' || L_Errmsg);
				 RAISE exp_reject_record;
			  End If;
   BEGIN
      SELECT chr_pan_code,chr_pan_code_encr,fn_dmaps_main(chr_pan_code_encr)
        INTO l_oldcrd,l_oldcrd_encr,l_oldcrd_clear
        FROM cms_htlst_reisu
       Where Chr_Inst_Code = p_inst_code_in
         AND chr_new_pan = l_hash_pan
         AND chr_reisu_cause = 'R'
         AND chr_pan_code IS NOT NULL;

         Select Count (1)
          INTO l_dup_check
          FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_acct_no = l_acct_no
           AND cap_startercard_flag='N'
           And Cap_Card_Stat In ('0', '1', '2', '5', '6', '8', '12');

        IF l_dup_check <> 1
         THEN
            l_errmsg := 'Card is not allowed for activation';
            p_resp_code_out := '89';
            RAISE exp_reject_record;
         END IF;
      BEGIN
         Select Cap_Card_Stat
          Into L_Oldcardstat
           From Cms_Appl_Pan
           Where Cap_Inst_Code = P_Inst_Code_In
           And Cap_Pan_Code = L_Oldcrd;

        IF l_oldcardstat = 3 or l_oldcardstat = 7 then--added for vms-453
           UPDATE cms_appl_pan
              SET cap_card_stat = '9'
            Where Cap_Inst_Code = P_Inst_Code_In And Cap_Pan_Code = L_Oldcrd;

           IF SQL%ROWCOUNT != 1
           THEN
              l_errmsg := 'Problem in updation of status for old damage card';
              p_resp_code_out := '89';
              RAISE exp_reject_record;
            END IF;
            L_Crdstat_Chnge:='Y';
            -- l_closed_card :=l_oldcrd_clear;
         End If;
         dbms_output.put_line( 'l_oldcardstat ' || l_errmsg);
       EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while selecting L_Oldcardstat '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
               'Error while selecting damage card details '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
   END;
 END IF;

  --Sn Check initial load
   IF L_Prfl_Code IS NULL OR l_profile_level IS NULL   THEN
      BEGIN
         SELECT cpl_lmtprfl_id
           INTO L_Prfl_Code
           FROM cms_prdcattype_lmtprfl
          WHERE cpl_inst_code = p_inst_code_in
            AND cpl_prod_code = l_prod_code
            AND cpl_card_type = l_prod_cattype;
         l_profile_level := 2;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT cpl_lmtprfl_id
                 INTO L_Prfl_Code
                 FROM cms_prod_lmtprfl
                WHERE cpl_inst_code = p_inst_code_in
                  AND cpl_prod_code = l_prod_code;
               l_profile_level := 3;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                        'Error while selecting Limit Profile At Product Level'
                     || SQLERRM;
                  RAISE exp_reject_record;
            END;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting Limit Profile At Product Catagory Level'
               || SQLERRM;
            RAISE exp_reject_record;
      END;
   END IF;


   IF l_firsttime_topup = 'Y' AND l_card_stat = '1'   THEN
      p_resp_code_out := '27';
      l_errmsg := 'Card Activation Already Done';
      RAISE exp_reject_record;
    ELSE
      IF TRIM (l_firsttime_topup) IS NULL   THEN
         p_resp_code_out := '27';
         l_errmsg := 'Invalid Card Activation ';
         RAISE exp_reject_record;
      END IF;
   END IF;
 --card status
   BEGIN
       IF l_card_stat IN (2, 3) AND  l_replace_expdt IS NULL  THEN
         p_resp_code_out := '41';
         l_errmsg := ' Lost Card ';
         RAISE exp_reject_record;
      ELSIF l_card_stat = 4
      THEN
         p_resp_code_out := '14';
         l_errmsg := ' Restricted Card ';
         RAISE exp_reject_record;
      ELSIF l_card_stat = 9  THEN
         p_resp_code_out := '46';
         l_errmsg := ' Closed Card ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record  THEN
        RAISE ;
      WHEN OTHERS   THEN
         p_resp_code_out := '21';
         l_errmsg := 'Error while checking l_card_stat';
         RAISE exp_reject_record;
   END;

   --card status

 IF  l_replace_expdt IS NULL THEN
   -- Expiry Check
   BEGIN
      If To_Date (P_Tran_Date_In, 'YYYYMMDD') >  LAST_DAY (TO_CHAR (l_expry_date, 'DD-MON-YY'))   THEN
         p_resp_code_out := '13';
         l_errmsg := 'EXPIRED CARD';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record    THEN
         RAISE;
      WHEN OTHERS  THEN
         p_resp_code_out := '21';
         l_errmsg := 'ERROR IN EXPIRY DATE CHECK : Tran Date - '|| p_tran_date_in|| ', Expiry Date - '|| l_expry_date|| ','|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
 END IF;


    BEGIN
               SELECT UPPER (NVL (cpp_product_type, 'O'))
                 INTO l_prod_type
                 FROM cms_product_param
                WHERE cpp_prod_code = l_prod_code AND cpp_inst_code = p_inst_code_in;

              if l_prod_type <> 'C' then
                if l_user_type in ('1','4') then
                    l_prod_type :='C';
                End if;
                END if;


            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                     'Error While selecting the product type' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
    END;




  begin
     vmsfunutilities.get_currency_code(l_prod_code,l_prod_cattype,p_inst_code_in,l_chkcurr,l_errmsg);

      IF l_errmsg<>'OK' then
            p_resp_code_out := '21';
               raise exp_reject_record;
      end if;

      IF l_chkcurr IS NULL THEN
              p_resp_code_out := '21';
              l_errmsg := 'Base currency cannot be null ';
              RAISE exp_reject_record;
     END IF;

        EXCEPTION
           WHEN exp_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              p_resp_code_out := '21';
              l_errmsg :='Error while selecting base currency -' || SUBSTR (SQLERRM, 1, 200);
              Raise Exp_Reject_Record;
  END ;

     IF l_chkcurr<>'124' THEN
   --Sn call procedure for multiple SSN check
   BEGIN
      SELECT nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn)
        INTO l_ssn
        FROM cms_cust_mast
       WHERE ccm_inst_code = p_inst_code_in AND ccm_cust_code = l_cust_code;

      sp_check_ssn_threshold (p_inst_code_in,
                              l_ssn,
                              l_prod_code,
                              l_prod_cattype,
                              NULL,
                              l_ssn_crddtls,
                              p_resp_code_out,
                              l_errmsg,
                              l_FLDOB_HASHKEY_ID
                             );

        IF l_errmsg <> 'OK'
      THEN
         p_resp_code_out := '157';
         l_errmsg := l_errmsg;
         RAISE exp_reject_record;
      END IF;

   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
     END;
   END IF;
     IF UPPER (l_starter_card_flag) = 'N'     THEN
          --Sn select Starter Card
          BEGIN
             SELECT cap_pan_code, cap_pan_code_encr
               INTO l_starter_card, l_starter_card_encr
               from (SELECT cap_pan_code, cap_pan_code_encr
               FROM cms_appl_pan
              WHERE cap_inst_code = p_inst_code_in
                AND cap_acct_no = l_acct_no
                AND cap_startercard_flag = 'Y'
                AND cap_card_stat NOT IN ('9')
                order by cap_pangen_date desc) where rownum=1;
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                NULL;
                WHEN OTHERS
             THEN
                p_resp_code_out := '21';
                l_errmsg :='Error while selecting Starter Card details for Account No '|| l_acct_no;
                RAISE exp_reject_record;
          END;
       --En select Starter Card
       END IF;

    BEGIN
       SELECT CCI_KYC_FLAG
       INTO l_kyc_flag
       FROM CMS_CAF_INFO_ENTRY
       WHERE CCI_INST_CODE=p_inst_code_in
       AND CCI_APPL_CODE=to_char(l_appl_code);

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
       p_resp_code_out := '21';
       l_errmsg   := 'KYC FLAG not found ';
       RAISE  exp_reject_record;
   WHEN OTHERS THEN
      p_resp_code_out := '21';
      l_errmsg   := 'Error while selecting data from caf_info ' ||SUBSTR(SQLERRM, 1, 200);
      RAISE  exp_reject_record;
   END;

   IF  l_kyc_flag IN ('Y','P','O','I') THEN
       BEGIN

         /*IF l_prod_type<>'C' THEN
                      if (l_user_type  in ('1','4')) then
                           l_req_card_stat := '1';
                            l_req_txn_code:='01';
                       else
               l_req_card_stat := '13';
                l_req_txn_code:='09';
                      END IF;
          else
             l_req_card_stat := '1';
              L_Req_Txn_Code:='01';
       END IF;*/
       l_req_card_stat := '1';
              L_Req_Txn_Code:='01';

           UPDATE CMS_APPL_PAN
             SET CAP_CARD_STAT = l_req_card_stat,--1,
                CAP_ACTIVE_DATE=nvl(CAP_ACTIVE_DATE,sysdate),CAP_FIRSTTIME_TOPUP = 'Y',
                cap_prfl_code = L_Prfl_Code,
                cap_prfl_levl = l_profile_level,
                 cap_expry_date = NVL(cap_replace_exprydt, cap_expry_date),
                 cap_replace_exprydt =NULL
           WHERE CAP_INST_CODE = p_inst_code_in
            AND CAP_PAN_CODE = l_hash_pan;

           IF SQL%ROWCOUNT = 0 THEN
             p_resp_code_out := '21';
              l_errmsg   := 'Activating GPR card ACTIVE DATE NOT UPDATED'|| l_hash_pan;
          RAISE exp_reject_record;
           END IF;
    l_status_chnge :='Y';
       EXCEPTION
       WHEN exp_reject_record THEN
        RAISE ;
         WHEN OTHERS THEN
          p_resp_code_out := '21';
          l_errmsg   := 'Error while Activating GPR card' || SUBSTR(SQLERRM, 1, 200);
          RAISE exp_reject_record;
       END;

  end if;

 --If(p_delivery_chnl_in= '10' Or p_delivery_chnl_in='13')   Then

     if   l_kyc_flag IN ('F','E','N') THEN
        IF l_prod_type<>'C' THEN
             if (l_kyc_flag='N' and l_user_type in ('1','4')) then
                           l_req_card_stat := '1';
                           l_req_txn_code:='01';
                        else
                        l_req_card_stat := '13';
                        l_req_txn_code :='09';
                      END IF;
          else
             l_req_card_stat := '1';
              l_req_txn_code:='01';
        END IF;

        BEGIN
          UPDATE CMS_APPL_PAN
             SET CAP_CARD_STAT = l_req_card_stat,--13,
             CAP_ACTIVE_DATE=sysdate,CAP_FIRSTTIME_TOPUP = 'Y',
             cap_expry_date = NVL(cap_replace_exprydt, cap_expry_date),cap_replace_exprydt =NULL,
                 cap_prfl_code = L_Prfl_Code,
                cap_prfl_levl = l_profile_level
                     WHERE CAP_INST_CODE = p_inst_code_in
            AND CAP_PAN_CODE = l_hash_pan;

           IF sql%rowcount = 0 then
           p_resp_code_out := '21';
           l_errmsg   := 'Activating GPR card not updated for :' ||l_HASH_PAN;
          RAISE exp_reject_record;
           end if;
      l_status_chnge :='Y';
       EXCEPTION
         when exp_reject_record then
         raise ;
         WHEN OTHERS THEN
          p_resp_code_out := '21';
          l_errmsg   := 'Error while Activating GPR card' ||SUBSTR(SQLERRM, 1, 200);
          RAISE exp_reject_record;
       END;
      -- Card Status logging  to Active UnRegistered
--         BEGIN
--           sp_log_cardstat_chnge (p_inst_code_in,
--                                  l_hash_pan,
--                                  l_encr_pan,
--                                  l_auth_id,
--                                  l_req_txn_code,
--                                  p_rrn_in,
--                                  p_tran_date_in,
--                                  p_tran_time_in,
--                                  p_resp_code_out,
--                                  l_errmsg
--                                  );
--
--           IF p_resp_code_out <> '00' AND l_errmsg <> 'OK' THEN
--           RAISE exp_reject_record;
--           END IF;
--
--        EXCEPTION  WHEN exp_reject_record  THEN
--              RAISE;
--           WHEN OTHERS THEN
--              p_resp_code_out := '21';
--              l_errmsg:='Error while logging system initiated card status change to Active UnRegistered'|| SUBSTR (SQLERRM, 1, 200);
--              RAISE exp_reject_record;
--        END;

--  ELSIF   l_kyc_flag ='N' THEN
--              p_resp_code_out := '206';
--              l_errmsg:='KYC VERIFICATION  NOT DONE';
--              RAISE exp_reject_record;

  END IF;
--Sn close starter card
  -- End If;

--  IF p_delivery_chnl_in = '07'   THEN
--
--
----    BEGIN
----        SELECT cpC_b2bcard_stat
----          INTO l_b2bcard_status
----          FROM CMS_PROD_CATTYPE
----          WHERE CPC_PROD_CODE=l_prod_code AND
----          CPC_CARD_TYPE = l_prod_cattype
----          AND CPC_INST_CODE=p_inst_code_in;
----       EXCEPTION
----             WHEN OTHERS THEN
----                p_resp_code_out := '21';
----                l_errmsg  := 'Error while checking b2b card status configured' ||SUBSTR(SQLERRM, 1, 200);
----              RAISE exp_reject_record;
----           END;
--      IF  l_kyc_flag IN ('F','E','N') THEN  -- or (l_kyc_flag='N' and l_b2bcard_status is not null ) THEN
--         BEGIN
--
--         IF l_prod_type<>'C' THEN
--             if (l_kyc_flag='N' and l_user_type  = 1) then
--                           l_req_card_stat := '1';
--                           l_req_txn_code:='01';
--                        else
--                        l_req_card_stat := '13';
--                        l_req_txn_code :='09';
--                      END IF;
--          else
--              l_req_card_stat := '1';
--              l_req_txn_code:='01';
--        END IF;
--
--
--           UPDATE CMS_APPL_PAN
--              SET CAP_CARD_STAT = l_req_card_stat,--13,
--              CAP_ACTIVE_DATE=sysdate,
--               CAP_FIRSTTIME_TOPUP = 'Y',
--               cap_expry_date = NVL(cap_replace_exprydt, cap_expry_date),
--               ,cap_replace_exprydt =NULL,
--              cap_prfl_code = L_Prfl_Code,
--                cap_prfl_levl = l_profile_level
--                  WHERE CAP_INST_CODE = p_inst_code_in AND CAP_PAN_CODE = l_HASH_PAN;
--
--           IF sql%rowcount =0 THEN
--           p_resp_code_out := '21';
--           l_errmsg   := 'Activating GPR card not updated for :' || l_HASH_PAN;
--          RAISE exp_reject_record;
--           end if;
--           l_status_chnge :='Y';
--       EXCEPTION
--         when exp_reject_record then
--         raise ;
--         WHEN OTHERS THEN
--          p_resp_code_out := '21';
--          l_errmsg   := 'Error while Activating GPR card' ||SUBSTR(SQLERRM, 1, 200);
--          RAISE exp_reject_record;
--       END;
----       BEGIN
----         sp_log_cardstat_chnge (p_inst_code_in,
----                                  l_hash_pan,
----                                  l_encr_pan,
----                                  l_auth_id,
----                                  l_req_txn_code, -- '09',
----                                  P_RRN_in,
----                                  p_tran_date_in,
----                                  p_tran_time_in,
----                                  p_resp_code_out,
----                                  l_errmsg
----                                 );
----
----           IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
----           THEN
----            RAISE exp_reject_record;
----           END IF;
----        EXCEPTION
----           WHEN exp_reject_record   THEN
----              RAISE;
----           WHEN OTHERS  THEN
----              p_resp_code_out := '21';
----              l_errmsg:= 'Error while logging system initiated card status change to Active UnRegistered'|| SUBSTR (SQLERRM, 1, 200);
----              RAISE exp_reject_record;
----        END;
--   end if;
--
--  END IF;

 if l_status_chnge ='Y' then
  BEGIN
         sp_log_cardstat_chnge (p_inst_code_in,
                                  l_hash_pan,
                                  l_encr_pan,
                                  l_auth_id,
                                  l_req_txn_code, -- '09',
                                  P_RRN_in,
                                  p_tran_date_in,
                                  p_tran_time_in,
                                  p_resp_code_out,
                                  l_errmsg
                                 );

           IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
           THEN
            RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record   THEN
              RAISE;
           WHEN OTHERS  THEN
              p_resp_code_out := '21';
              l_errmsg:= 'Error while logging system initiated card status change to Active UnRegistered'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;

 end if;
 if  l_card_closer_flag ='Y' then
    BEGIN
     select CAP_PAN_CODE,clear_card,cap_pan_code_encr
      INTO L_STARTER_CARD,L_oldcrd_clear,L_STARTER_CARD_encr
    from (SELECT CAP_PAN_CODE,fn_dmaps_main(cap_pan_code_encr) as clear_card,cap_pan_code_encr
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = p_inst_code_in
    AND CAP_ACCT_NO = l_acct_no
    AND CAP_STARTERCARD_FLAG='Y'
    AND CAP_CARD_STAT NOT IN ('9')
    order by cap_pangen_date desc) where rownum=1;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    NULL;
    WHEN OTHERS THEN
      p_resp_code_out:='21';
     l_errmsg := 'Error while selecting Starter Card number for Account No ' || l_acct_no;
     RAISE exp_reject_record;
  END;

   if l_starter_card  is not null then
   BEGIN

      UPDATE CMS_APPL_PAN
         SET CAP_CARD_STAT = 9
       WHERE CAP_INST_CODE = p_inst_code_in
        AND CAP_PAN_CODE = l_starter_card;

         IF SQL%ROWCOUNT = 0 THEN
             p_resp_code_out := '21';
             l_errmsg := 'UPDATION OF STARTER CARD TO CLOSURE NOT HAPPENED'|| l_starter_card;
          RAISE exp_reject_record;
           END IF;
           l_crdstat_chnge:='Y';
           l_oldcrd:=l_STARTER_CARD;
           l_oldcrd_encr:=L_STARTER_CARD_encr;

   EXCEPTION
   WHEN exp_reject_record THEN
   RAISE ;
     WHEN OTHERS THEN
      p_resp_code_out := '21';
      l_errmsg   := 'Error while closing the status of starter card ' ||SUBSTR(SQLERRM, 1, 200);
      RAISE exp_reject_record;
   END;

   end if;
end if;

BEGIN

        select cap_pan_code,CAP_PAN_CODE_ENCR
        INTO L_RENEWAL_CARD_HASH ,L_RENEWAL_CARD_ENCR
        from cms_appl_pan ,cms_cardrenewal_hist
        where cap_inst_code=CCH_INST_CODE and cap_pan_code=CCH_PAN_CODE
        and cap_card_stat <>9 and cap_pan_code<>l_hash_pan
        and cap_acct_no = l_ACCT_no
        and cap_inst_code=p_inst_code_in;

       EXCEPTION
       WHEN NO_DATA_FOUND THEN
       NULL;
       WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg := 'Error while GETTING THE RENEWAL CARD DETAILS ' ||SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
END;

  IF L_RENEWAL_CARD_HASH IS NOT NULL THEN
   BEGIN

      UPDATE CMS_APPL_PAN
      SET CAP_CARD_STAT = 9
      WHERE CAP_INST_CODE = p_inst_code_in
       AND CAP_PAN_CODE = L_RENEWAL_CARD_HASH;

         IF SQL%ROWCOUNT = 0 THEN
              p_resp_code_out := '21';
              l_errmsg   := 'UPDATION OF RENEWAL CARD TO CLOSURE NOT HAPPENED'|| L_RENEWAL_CARD_HASH;
          RAISE exp_reject_record;
         END IF;

       -- p_closed_card :=v_starcard_clear;
            sp_log_cardstat_chnge (p_inst_code_in,
                                   L_RENEWAL_CARD_HASH,
                                   L_RENEWAL_CARD_ENCR,
                                   l_auth_id,
                                   '02',
                                  P_RRN_IN,
                                  p_tran_date_in,
                                  p_tran_time_in,
                                  p_resp_code_out,
                                  l_errmsg
                                 );

           IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
           THEN
            RAISE exp_reject_record;
           END IF;

       EXCEPTION
       WHEN exp_reject_record THEN
       RAISE;
       WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg   := 'Error while CLOSING THE RENEWAL CARD ' ||SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
    END;
   END IF;

 IF l_STARTER_CARD IS NOT NULL THEN

         VMSCOMMON.TRFR_ALERTS (p_inst_code_in,
                                 l_starter_card,
                                 l_hash_pan,
                                 p_resp_code_out,
                                 l_errmsg);

          IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
          THEN
             l_errmsg := l_errmsg;
             RAISE exp_reject_record;
          END IF;

     END IF;


IF l_oldcrd IS NOT NULL  THEN
          VMSCOMMON.TRFR_ALERTS (p_inst_code_in,
                                 l_oldcrd,
                                 l_hash_pan,
                                 p_resp_code_out,
                                 l_errmsg);

          IF p_resp_code_out <> '00' AND l_errmsg <> 'OK' THEN
             l_errmsg := l_errmsg;
             RAISE exp_reject_record;
          END IF;

  END IF;
    --En call to authorize txn
 IF l_errmsg='OK' and l_crdstat_chnge='Y' THEN
     begin
       sp_log_cardstat_chnge (p_inst_code_in,
                              l_oldcrd,
                              l_oldcrd_encr,
                              l_inil_authid,
                              '02',
                              p_rrn_in,
                              p_tran_date_in,
                              p_tran_time_in,
                              p_resp_code_out,
                              l_errmsg
                             );

       IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
       THEN
          l_errmsg := l_errmsg;
          RAISE exp_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_reject_record    THEN
          RAISE;
       WHEN OTHERS  THEN
          p_resp_code_out := '21';
          l_errmsg :='Error while logging system initiated card status change '|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
   END IF;

  --Sn Selecting Reason code for Online Order Replacement
   BEGIN
      SELECT csr_spprt_rsncode
        INTO l_resoncode
        FROM cms_spprt_reasons
       WHERE csr_inst_code = p_inst_code_in AND csr_spprt_key = 'ACTVTCARD';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '21';
         l_errmsg := 'Card Activation reason code is present in master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
               'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --Sn create a record in pan spprt
   BEGIN
      INSERT INTO cms_pan_spprt
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,
                   cps_pan_code_encr
                  )
           VALUES (p_inst_code_in, l_hash_pan, l_mbrnumb, L_Cap_Prod_Catg,
                   'ACTVTCARD', l_resoncode, l_remrk,
                   '1', '1', 0,
                   l_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF P_RESP_CODE_OUT = '00' AND L_ERRMSG = 'OK' THEN

    IF L_DEFUND_FLAG = 'Y' AND NVL(L_TXN_AMT,0) > 0 AND L_PARAM_VALUE = 'N' THEN

        L_REMARK := 'Activated and Loaded the Defunded Amount For the Account';

    SP_CARD_LOAD_DEFUND_AMOUNT(P_INST_CODE_IN,
								P_MSG_TYPE_IN,
                                P_RRN_IN,
                                P_DELIVERY_CHNL_IN,
                                '0',
                                l_txn_code,
                                0,
                                P_TRAN_DATE_IN,
                                P_TRAN_TIME_IN,
                                P_PAN_CODE_IN,
                                L_TXN_AMT,
                                NULL,
                                NULL,
                                NULL,
                                P_CURR_CODE_IN,
                                '000',
                                '0',
                                L_REMARK,
                                'CR',
                                '00',
                                P_ANI_IN,
                                P_DNI_IN,
                                P_RESP_CODE_OUT,
                                L_ERRMSG);

                  IF P_RESP_CODE_OUT <> '00' AND L_ERRMSG <> 'OK' THEN
                       RAISE Exp_Reject_Record;
                     END IF;
                END IF;
        END IF;

EXCEPTION                     --Main exception
      When Exp_Reject_Record
      Then
      P_Resp_Msg_Out := L_Errmsg;
	  l_log_flag:='Y';
         Rollback;

      WHEN OTHERS
      THEN
         l_log_flag:='Y';
		  ROLLBACK;
         l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
  end;
    BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code_in
            AND cms_delivery_channel = p_delivery_chnl_in
            AND cms_response_id = TO_NUMBER (p_resp_code_out);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_errmsg :=
                  'Error while selecting respose code'
               || p_resp_code_out
               || ' is-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
      END;
  l_timestamp := SYSTIMESTAMP;
   BEGIN
      l_hashkey_id :=
         gethash (   p_delivery_chnl_in
                   || l_txn_code
                  || p_pan_code_in
                  || p_rrn_in
                  || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
            'Error while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
   END;
  BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO l_acct_bal, l_ledger_bal, l_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code_in AND cam_acct_no = l_acct_no;
   EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card number ' ;
       WHEN OTHERS
      THEN
         p_resp_code_out := '12';
         p_resp_msg_out :=
                       'ERROR IN account details' || SUBSTR (SQLERRM, 1, 200);
   END;
   IF l_log_flag='Y' THEN --Added for VMS_7196

   BEGIN
      vms_log.log_transactionlog (p_inst_code_in,
                                  p_msg_type_in,
                                  p_rrn_in,
                                  p_delivery_chnl_in,
                                 l_txn_code,
                                  l_txn_type,
                                  0,
                                  p_tran_date_in,
                                  p_tran_time_in,
                                  '00',
                                  l_hash_pan,
                                  l_encr_pan,
                                  l_errmsg,
                                  p_ip_addr_in,
                                  l_card_stat,
                                  l_txn_desc,
                                  p_ani_in,
                                  p_dni_in,
                                  l_timestamp,
                                  l_acct_no,
                                  l_prod_code,
                                  l_prod_cattype,
                                  l_cr_dr_flag,
                                  l_acct_bal,
                                  l_ledger_bal,
                                  l_acct_type,
                                  l_proxynumber,
                                  l_auth_id,
                                  0,
                                  l_total_amt,
                                  l_fee_code,
                                  l_tranfee_amt,
                                  l_fee_plan,
                                  l_feeattach_type,
                                  p_resp_code_out,
                                  p_resp_code_out,
                                  p_curr_code_in,
                                  l_hashkey_id,
                                  p_uuid_in,
                                  p_osname_in,
                                  p_osversion_in,
                                  p_gps_coordinates_in,
                                  p_display_resolution_in,
                                  p_physical_memory_in,
                                  p_appname_in,
                                  p_appversion_in,
                                  p_sessionid_in,
                                  p_device_country_in,
                                  p_device_region_in,
                                  p_ipcountry_in,
                                  p_proxy_flag_in,
                                  p_partner_id_in,
                                  l_errmsg
                                 );

      IF l_errmsg <> 'OK'  THEN
         RAISE exp_reject_record;
      END IF;
   EXCEPTION  WHEN exp_reject_record THEN
         p_resp_code_out := '69';
         p_resp_msg_out :=
               p_resp_msg_out
            || ' Error while inserting into transaction log  '
            || l_errmsg;
      WHEN OTHERS THEN
         p_resp_code_out := '69';
         p_resp_msg_out :='Error while inserting into transaction log '|| SUBSTR (SQLERRM, 1, 300);
   End;
   END IF;
  END  activate_card;


PROCEDURE get_cards(p_inst_code_in             IN  NUMBER,
                     p_delivery_channel_in      IN  VARCHAR2,
                     p_txn_code_in              IN  VARCHAR2,
                     p_rrn_in                   IN  VARCHAR2,
                     p_cust_id_in               IN  VARCHAR2,
                     p_partner_id_in            IN  VARCHAR2,
                     p_trandate_in              IN  VARCHAR2,
                     p_trantime_in              IN  VARCHAR2,
                     p_curr_code_in             IN  VARCHAR2,
                     p_rvsl_code_in             IN  VARCHAR2,
                     p_msg_type_in              IN  VARCHAR2,
                     p_ip_addr_in               IN  VARCHAR2,
                     p_ani_in                   IN  VARCHAR2,
                     p_dni_in                   IN  VARCHAR2,
                     p_device_mob_no_in         IN  VARCHAR2,
                     p_device_id_in             IN  VARCHAR2,
                     p_pan_code_in              IN  VARCHAR2,
                     p_uuid_in                  IN  VARCHAR2,
                     p_os_name_in               IN  VARCHAR2,
                     p_os_version_in            IN  VARCHAR2,
                     p_gps_coordinates_in       IN  VARCHAR2,
                     p_display_resolution_in    IN  VARCHAR2,
                     p_physical_memory_in       IN  VARCHAR2,
                     p_app_name_in              IN  VARCHAR2,
                     p_app_version_in           IN  VARCHAR2,
                     p_session_id_in            IN  VARCHAR2,
                     p_device_country_in        IN  VARCHAR2,
                     p_device_region_in         IN  VARCHAR2,
                     p_ip_country_in            IN  VARCHAR2,
                     p_proxy_flag_in            IN  VARCHAR2,
                     p_resp_code_out            OUT VARCHAR2,
                     p_respmsg_out              OUT VARCHAR2,
                     p_cards_array_out          OUT VARCHAR2
                     )
AS
      l_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no           cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code         cms_appl_pan.cap_prod_code%TYPE;
      l_card_type         cms_appl_pan.cap_card_type%TYPE;
      l_card_stat         cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date        cms_appl_pan.cap_expry_date%TYPE;
      l_active_date       cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
      l_comb_hash         pkg_limits_check.type_hash;
      l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp         TIMESTAMP;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
      l_acct_type         cms_acct_mast.cam_type_code%TYPE;
      l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type    transactionlog.feeattachtype%TYPE;
      l_tranfee_amt       transactionlog.tranfee_amt%TYPE;
      l_total_amt         cms_acct_mast.cam_acct_bal%TYPE;
      l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
      l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
      l_card               VARCHAR2 (500);
      l_card_status         VARCHAR2 (300);
      l_card_stat_desc  VARCHAR2 (500);
      l_errmsg            VARCHAR2 (500);
      exp_reject_record   EXCEPTION;
      l_encrypt_enable    cms_prod_cattype.cpc_encrypt_enable%type;

   BEGIN
      BEGIN

         p_respmsg_out := 'success';

    --Sn pan  and customer details
    BEGIN
        SELECT cap_pan_code, cap_pan_code_encr,cap_acct_no,
               cap_card_stat, cap_prod_code, cap_card_type,
               cap_expry_date, cap_active_date, cap_prfl_code,
               cap_proxy_number,cap_cust_code
          INTO l_hash_pan, l_encr_pan,l_acct_no,
               l_card_stat, l_prod_code, l_card_type,
               l_expry_date, l_active_date, l_prfl_code,
               l_proxynumber,l_cust_code
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code_in
           AND cap_pan_code = gethash (p_pan_code_in)
           AND cap_mbr_numb = '000';

       EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' || gethash(p_pan_code_in);
                 RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

--Sn pan  and customer details
         -- Sn Transaction Details  procedure call
         begin
              select cpc_encrypt_enable
              into l_encrypt_enable
              from cms_prod_cattype
              where cpc_inst_code=p_inst_code_in
              and cpc_prod_code=l_prod_code
              and cpc_card_type=l_card_type;
         exception
            when others then
                p_resp_code_out := '12';
               l_errmsg :=
                   'Error in getting prod cattype' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         end;
         BEGIN
            vmscommon.get_transaction_details (p_inst_code_in,
                                               p_delivery_channel_in,
                                               p_txn_code_in,
                                               l_cr_dr_flag,
                                               l_txn_type,
                                               l_txn_desc,
                                               l_prfl_flag,
                                               l_preauth_flag,
                                               l_login_txn,
                                               l_preauth_type,
                                               l_dup_rrn_check,
                                               p_resp_code_out,
                                               l_errmsg
                                              );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                  'Error from Transaction Details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En Transaction Details  procedure call

         -- Sn validating Date Time RRN
         IF l_dup_rrn_check = 'Y' THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out
                                        );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                     'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         END IF;
         -- En validating Date Time RRN

         --SN : authorize_nonfinancial_txn check
         BEGIN
            vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
                                                  p_msg_type_in,
                                                  p_rrn_in,
                                                  p_delivery_channel_in,
                                                  p_txn_code_in,
                                                  0,
                                                  p_trandate_in,
                                                  p_trantime_in,
                                                  '00',
                                                  l_txn_type,
                                                  p_pan_code_in,
                                                  l_hash_pan,
                                                  l_encr_pan,
                                                  l_acct_no,
                                                  l_card_stat,
                                                  l_expry_date,
                                                  l_prod_code,
                                                  l_card_type,
                                                  l_prfl_flag,
                                                  l_prfl_code,
                                                  l_txn_type,
                                                  p_curr_code_in,
                                                  l_preauth_flag,
                                                  l_txn_desc,
                                                  l_cr_dr_flag,
                                                  l_login_txn,
                                                  p_resp_code_out,
                                                  l_errmsg,
                                                  l_comb_hash,
                                                  l_auth_id,
                                                  l_fee_code,
                                                  l_fee_plan,
                                                  l_feeattach_type,
                                                  l_tranfee_amt,
                                                  l_total_amt,
                                                  l_preauth_type
                                                 );

            IF l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error from authorize_nonfinancial_txn '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
    --SN : authorize_nonfinancial_txn check

    --SN : getting_card_details

       BEGIN
        FOR i IN (SELECT CAP_PAN_CODE_ENCR,CAP_CARD_STAT,cap_active_date
                  FROM CMS_APPL_PAN , CMS_CUST_MAST
                  WHERE CAP_INST_CODE=CCM_INST_CODE AND CAP_INST_CODE=p_inst_code_in
                  AND CAP_CUST_CODE=CCM_CUST_CODE AND CCM_CUST_ID=p_cust_id_in)
        LOOP
         IF  i.CAP_CARD_STAT = 0
         THEN
            IF i.cap_active_date IS NULL
            THEN
               l_card_stat_desc := 'INACTIVE';
            ELSE
               l_card_stat_desc := 'BLOCKED';
            END IF;
         ELSE
            BEGIN
               SELECT ccs_stat_desc
                 INTO l_card_stat_desc
                 FROM cms_card_stat
                WHERE ccs_stat_code = i.CAP_CARD_STAT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code_out := '12';
                  l_errmsg :=
                     'Error while selcting card status description'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;
                l_card :=fn_dmaps_main(i.CAP_PAN_CODE_ENCR);
                 p_cards_array_out := p_cards_array_out||l_card||'|'||l_card_stat_desc||',';
        END LOOP;
                      EXCEPTION
              WHEN OTHERS THEN
              p_resp_code_out := '21';
              l_errmsg  := 'Error in cards array'||SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;


      END;
       --EN : getting_card_details

     p_resp_code_out := '1';

       EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
       END;

        BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = TO_NUMBER (p_resp_code_out);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'Problem while selecting respose code'
                  || p_resp_code_out
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
         END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_hashkey_id :=
            gethash (   p_delivery_channel_in
                     || p_txn_code_in
                     || l_hash_pan
                     || p_rrn_in
                     || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN

          SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL,CAM_TYPE_CODE
          INTO   l_acct_bal,l_ledger_bal,l_acct_type
          FROM   CMS_ACCT_MAST
          WHERE  CAM_INST_CODE = p_inst_code_in
          AND    CAM_ACCT_NO = l_acct_no;

      EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' ;
        WHEN OTHERS
        THEN
           p_resp_code_out := '12';
           l_errmsg :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      IF p_resp_code_out <> '00' THEN
          p_respmsg_out  := l_errmsg;

      END IF;

      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_card_type,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg
                                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;

END get_cards;

PROCEDURE  CARD_TO_CARD_TRANSFER(
                                                p_inst_code_in               IN   VARCHAR2,
                                                p_del_channel_in             IN   VARCHAR2,
                                                p_txn_code_in                IN   VARCHAR2,
                                                p_rrn_in                     IN   VARCHAR2,
                                                p_src_app_in                 IN   VARCHAR2,
                                                p_partner_id_in              IN   VARCHAR2,
                                                p_business_date_in           IN   VARCHAR2,
                                                p_business_time_in           IN   VARCHAR2,
                                                p_curr_code_in               IN   VARCHAR2,
                                                p_reversal_code_in           IN   VARCHAR2,
                                                p_msg_type_in                IN   VARCHAR2,
                                                p_ip_addr_in                 IN   VARCHAR2,
                                                p_ani_in                     IN   VARCHAR2,
                                                p_dni_in                     IN   VARCHAR2,
                                                p_dev_mob_no_in              IN   VARCHAR2,
                                                p_device_id_in               IN   VARCHAR2,
                                                p_uuid_in                    IN   VARCHAR2,
                                                p_osname_in                  IN   VARCHAR2,
                                                p_osversion_in               IN   VARCHAR2,
                                                p_gpscoordinates_in          IN   VARCHAR2,
                                                p_displayresolution_in       IN   VARCHAR2,
                                                p_physicalmemory_in          IN   VARCHAR2,
                                                p_appname_in                 IN   VARCHAR2,
                                                p_appversion_in              IN   VARCHAR2,
                                                p_sessionid_in               IN   VARCHAR2,
                                                p_devicecountry_in           IN   VARCHAR2,
                                                p_deviceregion_in            IN   VARCHAR2,
                                                p_ipcountry_in               IN   VARCHAR2,
                                                p_proxy_in                   IN   VARCHAR2,
                                                p_cust_id_in                 IN   VARCHAR2,
                                                p_pan_code_in                IN   VARCHAR2,
                                                P_TERM_ID_in                 IN   VARCHAR2,
                                                P_TXN_MODE_in                IN   VARCHAR2,
                                                P_FROM_CARD_NO_in            IN   VARCHAR2,
                                                P_FROM_CARD_EXPRY_in    	   IN   VARCHAR2,
                                                P_TXN_AMT_in          		   IN   NUMBER,
                                                P_MCC_CODE_in        		     IN   VARCHAR2,
                                                P_TO_CARD_NO_in   		       IN   VARCHAR2,
                                                P_TO_EXPRY_DATE_in   		     IN   VARCHAR2,
                                                P_STAN_in            		     IN   VARCHAR2,
                                                P_ID_TYPE_in          		   IN   VARCHAR2 ,
                                                P_ID_NUMBER_in       		     IN   VARCHAR2,
                                                P_MOB_NO_in          		     IN   VARCHAR2,
                                                P_CTC_BINFLAG_in      		   IN   VARCHAR2,
                                                P_FEE_WAIVER_FLAGT_in  		   IN  VARCHAR2 ,
                                                p_resp_code_out              OUT  VARCHAR2,
                                                p_resp_msg_out               OUT  VARCHAR2,
                                                P_FEE_AMT_out          			 OUT  VARCHAR2

                                                ) IS

  l_FROM_CARD_EXPRYDATE DATE;
  l_TO_CARD_EXPRYDATE   DATE;
  l_RESP_CDE            CMS_RESPONSE_MAST.CMS_RESPONSE_ID%TYPE;
  l_ERR_MSG             VARCHAR2(900);
  l_TXN_TYPE            TRANSACTIONLOG.TXN_TYPE%TYPE;
  l_CURR_CODE           TRANSACTIONLOG.CURRENCYCODE%TYPE;
  l_RESPMSG             VARCHAR2(900);
  l_CAPTURE_DATE        DATE;
  --l_AUTHMSG             VARCHAR2(900);
  l_TOACCT_BAL          CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  l_DR_CR_FLAG          CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
  l_CTOC_AUTH_ID        TRANSACTIONLOG.AUTH_ID%TYPE;
  l_FROM_PRODCODE       CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  l_FROM_CARDTYPE       CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  l_TRAN_DATE           DATE;
  l_TERMINAL_INDICATOR  PCMS_TERMINAL_MAST.PTM_TERMINAL_INDICATOR%TYPE;
  l_FROM_CARD_CURR      TRANSACTIONLOG.CURRENCYCODE%TYPE;
  l_TO_CARD_CURR        TRANSACTIONLOG.CURRENCYCODE%TYPE;
  l_RESP_CONC_MSG       VARCHAR2(300);
  EXP_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  l_HASH_PAN_FROM  CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  l_ENCR_PAN_FROM  CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  l_HASH_PAN_TO    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  l_ENCR_PAN_TO    CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  l_ACCT_BALANCE   CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  l_TOCARDSTAT       CMS_APPL_PAN.cap_card_stat%type;
  l_FROMCARDSTAT     CMS_APPL_PAN.cap_card_stat%type;
  l_FROMCARDEXP      DATE;
  l_TOCARDEXP        DATE;
  l_RRN_COUNT      PLS_INTEGER;
 -- l_PROD_CODE      VARCHAR2(50);
  l_MAX_CARD_BAL   CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  l_ACCT_NUMBER    CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  l_COUNT          PLS_INTEGER;
  l_LEDGER_BALANCE  CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  l_NARRATION       CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  l_TOACCT_NO        CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  l_FROMACCT_NO      CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  l_TOPRODCODE       CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  l_TOCARDTYPE       CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  l_TOACCTNUMBER     CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  l_STATUS_CHK        PLS_INTEGER;
  l_PRECHECK_FLAG     PLS_INTEGER;
  l_ATMONLINE_LIMIT  CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  l_POSONLINE_LIMIT  CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  l_OUTPUT_TYPE       cms_transaction_mast.ctm_output_type%type;
  l_TRAN_TYPE         cms_transaction_mast.ctm_tran_type%type;
  l_comb_hash    pkg_limits_check.type_hash;
  l_PRFL_CODE   CMS_APPL_PAN.CAP_PRFL_CODE%type ;
  l_PRFL_FLAG     CMS_TRANSACTION_MAST.CTM_PRFL_FLAG%TYPE ;
  l_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
  l_from_pan     VARCHAR2(10);
  l_to_pan       VARCHAR2(10);
  l_TOLEDGER_BAL  CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
  --l_cam_type_code   cms_acct_mast.cam_type_code%type;
  l_FRMACCT_TYPE   CMS_ACCT_MAST.CAM_TYPE_CODE%TYPE;
  l_TOACCT_TYPE    CMS_ACCT_MAST.CAM_TYPE_CODE%TYPE;
  l_CUST_CODE      CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
  l_id_number      CMS_CUST_MAST.CCM_SSN%TYPE;
  --l_c2c_alt        PLS_INTEGER;
  l_mob_mail_flag  VARCHAR2(1);
 -- l_idtype_code    cms_idtype_mast.cim_idtype_code%type;
  l_email          cms_addr_mast.cam_email%type;
  l_mobl_one        cms_addr_mast.cam_mobl_one%type;
  --l_id_type         cms_cust_mast.ccm_id_type%type;
  l_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;
  l_TIME_STAMP   TIMESTAMP;
   l_enable_flag                VARCHAR2 (20)                          := 'Y';
   l_initialload_amt         cms_acct_mast.cam_new_initialload_amt%type;
   l_profile_code cms_prod_cattype.cpc_profile_code%type;
   l_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   l_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
  l_cnt       PLS_INTEGER;
  L_TXN_AMT   cms_statements_log.CSL_TRANS_AMOUNT%TYPE;
  l_ctc_bin_flag  cms_prod_mast.cpm_ctc_bin%TYPE;

  v_Retperiod  date;  --Added for VMS-5735/FSP-991
  v_Retdate  date; --Added for VMS-5735/FSP-991
  
  /********************************************************************************
    * Modified By      : Sivakumar M
    * Modified Date    : 12/06/2019
    * Purpose          : VMS-968
    * Reviewer         : Saravanankumar A
    * Release Number   : R17
	
	* Modified By      : venkat Singamaneni
    * Modified Date    : 05-12-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jey
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
 *********************************************************************************/
BEGIN
  l_CURR_CODE := p_curr_code_in;
  l_TXN_TYPE  := '1';
  P_FEE_AMT_out   :=0;
  l_TIME_STAMP :=SYSTIMESTAMP;
  L_TXN_AMT := ROUND (P_TXN_AMT_in, 2);
  BEGIN
    l_HASH_PAN_FROM := GETHASH(P_FROM_CARD_NO_in);
  EXCEPTION
    WHEN OTHERS THEN
     l_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    l_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_FROM_CARD_NO_in);
  EXCEPTION
    WHEN OTHERS THEN
     l_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    l_HASH_PAN_TO := GETHASH(P_TO_CARD_NO_in);
  EXCEPTION
    WHEN OTHERS THEN
     l_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    l_ENCR_PAN_TO := FN_EMAPS_MAIN(P_TO_CARD_NO_in);
  EXCEPTION
    WHEN OTHERS THEN
     l_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

       BEGIN
           l_HASHKEY_ID := GETHASH (p_del_channel_in||p_txn_code_in||P_FROM_CARD_NO_in||p_rrn_in||to_char(l_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        p_resp_code_out := '21';
        l_ERR_MSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;


    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,
           CTM_PRFL_FLAG,CTM_TRAN_DESC
       INTO l_DR_CR_FLAG, l_OUTPUT_TYPE, l_TXN_TYPE, l_TRAN_TYPE,
            l_PRFL_FLAG,l_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = p_txn_code_in AND
           CTM_DELIVERY_CHANNEL = p_del_channel_in AND
           CTM_INST_CODE = p_inst_code_in;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       l_RESP_CDE := '12';
       l_ERR_MSG  := 'Transflag  not defined for txn code ' ||
                  p_txn_code_in || ' and delivery channel ' ||
                  p_del_channel_in;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       l_RESP_CDE := '21';
       l_ERR_MSG  := 'Error while selecting transaction details';
       RAISE EXP_REJECT_RECORD;
    END;




  BEGIN
  --Added for VMS-5735/FSP-991
  
   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
   INTO   v_Retperiod 
   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
   WHERE  OPERATION_TYPE='ARCHIVE' 
   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
   
   v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');
   
   
  IF (v_Retdate>v_Retperiod) THEN                                       --Added for VMS-5735/FSP-991
	   
    SELECT COUNT(1)
     INTO l_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE RRN = p_rrn_in AND BUSINESS_DATE = p_business_date_in AND
         DELIVERY_CHANNEL = p_del_channel_in;
   ELSE
    
     SELECT COUNT(1)
     INTO l_RRN_COUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                           --Added for VMS-5735/FSP-991
     WHERE RRN = p_rrn_in AND BUSINESS_DATE = p_business_date_in AND
           DELIVERY_CHANNEL = p_del_channel_in;	
   

   END IF;   


    IF l_RRN_COUNT > 0 THEN
     l_RESP_CDE := '22';
     l_ERR_MSG  := 'Duplicate RRN on ' || p_business_date_in;
     RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
       l_RESP_CDE := '21';
       l_ERR_MSG  := 'Error while checking  duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    l_TRAN_DATE := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8) || ' ' ||
                      SUBSTR(TRIM(p_business_time_in), 1, 8),
                      'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    IF TRIM(P_FROM_CARD_EXPRY_in) IS NOT NULL THEN
     l_FROM_CARD_EXPRYDATE := LAST_DAY(TO_DATE('01' || P_FROM_CARD_EXPRY_in ||' 23:59:59','ddyymm hh24:mi:ss'));
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
     l_ERR_MSG  := 'Problem while converting from card expry date ' ||
                SUBSTR(SQLERRM, 1, 300);
     l_RESP_CDE := '22';
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    IF TRIM(P_TO_EXPRY_DATE_in) IS NOT NULL THEN
     l_TO_CARD_EXPRYDATE := LAST_DAY(TO_DATE('01' || P_TO_EXPRY_DATE_in ||
                                     ' 23:59:59',
                                     'ddyymm hh24:mi:ss'));
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
     l_ERR_MSG  := 'Problem while converting to card expry date ' ||
                SUBSTR(SQLERRM, 1, 300);
     l_RESP_CDE := '22';
     RAISE EXP_REJECT_RECORD;
  END;


  BEGIN
    SELECT CAP_CARD_STAT, CAP_EXPRY_DATE,
          CAP_PROD_CODE,CAP_CARD_TYPE, CAP_ACCT_NO,CAP_CUST_CODE
     INTO l_FROMCARDSTAT, l_FROMCARDEXP,
         l_FROM_PRODCODE,l_FROM_CARDTYPE, l_ACCT_NUMBER,l_CUST_CODE
     FROM CMS_APPL_PAN
    WHERE CAp_inst_code = p_inst_code_in AND CAP_PAN_CODE = l_HASH_PAN_FROM;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     l_RESP_CDE := '16';
     l_ERR_MSG  := 'Card number not found ' || l_HASH_PAN_FROM;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     l_RESP_CDE := '12';
     l_ERR_MSG  := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
    BEGIN
            select cpm_ctc_bin
            into l_ctc_bin_flag
            from cms_prod_mast
            where cpm_prod_code=l_FROM_PRODCODE
            and cpm_inst_code=p_inst_code_in;
            EXCEPTION
             WHEN OTHERS THEN
                 l_RESP_CDE := '12';
                 l_ERR_MSG  := 'Problem while selecting card to card transfer flag' ||
                            SUBSTR(SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;
        END;

 IF l_ctc_bin_flag = 'N' and ( LENGTH (P_FROM_CARD_NO_in) > 10) and ( LENGTH (P_TO_CARD_NO_in) > 10) THEN
   --IF( LENGTH (P_FROM_CARD_NO_in) > 10) and ( LENGTH (P_TO_CARD_NO_in) > 10) THEN

      l_from_pan := SUBSTR (P_FROM_CARD_NO_in, 1, 6);
      l_to_pan := SUBSTR (P_TO_CARD_NO_in, 1, 6);

       if l_from_pan <> l_to_pan then
         l_RESP_CDE := '140';
         l_ERR_MSG  := 'Both the card number should be in same BIN';
       RAISE EXP_REJECT_RECORD;
       end if;

  --  END IF;
  END IF;

  BEGIN

      vmsfunutilities.get_currency_code(l_FROM_PRODCODE,l_FROM_CARDTYPE,p_inst_code_in,l_FROM_CARD_CURR,l_ERR_MSG);

      if l_ERR_MSG<>'OK' then
           raise EXP_REJECT_RECORD;
      end if;

    IF l_FROM_CARD_CURR IS NULL THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'From Card currency cannot be null ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;
     WHEN OTHERS THEN
     l_ERR_MSG  := 'Error while selecting card currecy  ' ||
                SUBSTR(SQLERRM, 1, 200);
     l_RESP_CDE := '21';
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    SELECT CAP_CARD_STAT, CAP_EXPRY_DATE, CAP_PROD_CODE, CAP_CARD_TYPE, CAP_ACCT_NO,
           CAP_ATM_ONLINE_LIMIT,CAP_POS_ONLINE_LIMIT
     INTO l_TOCARDSTAT, l_TOCARDEXP, l_TOPRODCODE, l_TOCARDTYPE, l_TOACCTNUMBER,
     l_ATMONLINE_LIMIT,l_POSONLINE_LIMIT
     FROM CMS_APPL_PAN
    WHERE CAp_inst_code = p_inst_code_in AND CAP_PAN_CODE = l_HASH_PAN_TO;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     l_RESP_CDE := '16';
     l_ERR_MSG  := 'Card number not found ' || l_HASH_PAN_TO;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     l_RESP_CDE := '12';
     l_ERR_MSG  := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;


   IF l_HASH_PAN_TO = l_HASH_PAN_FROM THEN
    l_RESP_CDE := '91';
    l_ERR_MSG  := 'FROM AND TO CARD NUMBERS SHOULD NOT BE SAME';
    RAISE EXP_REJECT_RECORD;
  END IF;

    BEGIN
     SELECT PTP_PARAM_VALUE
       INTO l_PRECHECK_FLAG
       FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE CHECK' AND PTp_inst_code = p_inst_code_in;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       l_RESP_CDE := '21';
       l_ERR_MSG  := 'Master set up is not done for Authorization Process';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       l_RESP_CDE := '21';
       l_ERR_MSG  := 'Error while selecting precheck flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;


  BEGIN
      vmsfunutilities.get_currency_code(l_TOPRODCODE,l_TOCARDTYPE,p_inst_code_in,l_TO_CARD_CURR,l_ERR_MSG);

      if l_ERR_MSG<>'OK' then
           raise EXP_REJECT_RECORD;
      end if;

    IF l_TO_CARD_CURR IS NULL THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'To Card currency cannot be null ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;
      WHEN OTHERS THEN
     l_ERR_MSG  := 'Error while selecting card currecy  ' ||
                SUBSTR(SQLERRM, 1, 200);
     l_RESP_CDE := '21';
     RAISE EXP_REJECT_RECORD;
  END;


  IF l_TO_CARD_CURR <> l_FROM_CARD_CURR THEN
    l_ERR_MSG  := 'Both from card currency and to card currency are not same  ' ||
               SUBSTR(SQLERRM, 1, 200);
    l_RESP_CDE := '21';
    RAISE EXP_REJECT_RECORD;
  END IF;

  IF l_CURR_CODE <> l_FROM_CARD_CURR THEN
    l_ERR_MSG  := 'Both from card currency and txn currency are not same  ' ||
               SUBSTR(SQLERRM, 1, 200);
    l_RESP_CDE := '21';
    RAISE EXP_REJECT_RECORD;
  END IF;

  IF p_txn_code_in NOT IN ('56', '07','13','39')
   THEN
    l_ERR_MSG  := 'Not a valid transaction code for ' ||
               ' card to card transfer';
    l_RESP_CDE := '21';
    RAISE EXP_REJECT_RECORD;
  END IF;

if l_FROM_CARD_CURR <>'124' then
    BEGIN
       SELECT
             nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn)
         INTO l_id_number
         FROM cms_cust_mast
        WHERE ccm_inst_code = p_inst_code_in AND ccm_cust_code = l_CUST_CODE
        and NVL(ccm_id_type,'SSN')=P_ID_TYPE_in;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
         l_RESP_CDE := '195';
        l_ERR_MSG := 'Invalid ID type';
        RAISE exp_reject_record;

       WHEN OTHERS
       THEN
          l_RESP_CDE := '21';
          l_ERR_MSG := 'Problem while selecting id number--' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;

    IF nvl(P_ID_NUMBER_in,'*') <> nvl(l_id_number,'*') then
        l_RESP_CDE := '195';
        l_ERR_MSG := 'Invalid ID Number';
        RAISE exp_reject_record;

    END IF;

end if;

    BEGIN
       SELECT cam_email, cam_mobl_one
         INTO l_email, l_mobl_one
         FROM cms_addr_mast
        WHERE cam_inst_code = p_inst_code_in
          AND cam_cust_code = l_CUST_CODE
          AND cam_addr_flag = 'P';
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          l_RESP_CDE := '21';
          l_ERR_MSG :=
                      'Permanent  Address Not Defined for Customer=' || l_CUST_CODE;
          RAISE exp_reject_record;
       WHEN OTHERS
       THEN
          l_RESP_CDE := '21';
          l_ERR_MSG :=
             'Problem while selecting mobile/email--' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;


    IF (l_email is null) and (l_mobl_one is null)  THEN
      l_RESP_CDE := '201';
      l_ERR_MSG  :='Mobile and Email not configured.';
      RAISE exp_reject_record;
    ELSIF l_email is null then
      l_RESP_CDE := '202';
      l_ERR_MSG  :='Email not configured.';
      RAISE exp_reject_record;
    ELSIF l_mobl_one is null then
      l_RESP_CDE := '203';
      l_ERR_MSG  :='Mobile not configured.';
      RAISE exp_reject_record;
    END IF;



    BEGIN
       SELECT CASE
                 WHEN cme_chng_date > (SYSDATE - 1)
                    THEN 'Y'
                 ELSE 'N'
              END
         INTO l_mob_mail_flag
         FROM cms_mob_email_log
        WHERE cme_inst_code = p_inst_code_in AND cme_cust_code = l_CUST_CODE;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          l_mob_mail_flag := 'N';
       WHEN OTHERS
       THEN
          l_RESP_CDE := '21';
          l_ERR_MSG :=
                'Problem while selecting flag from cms_mob_email_log-'
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;

    IF l_mob_mail_flag = 'Y' THEN

      l_RESP_CDE := '197';
      l_ERR_MSG :='Mobile/Email address has been updated within last 24 hrs.';
      RAISE exp_reject_record;

    END IF;


  BEGIN
    SELECT CAM_ACCT_BAL
     INTO l_ACCT_BALANCE
     FROM CMS_ACCT_MAST
    WHERE CAM_INST_CODE = p_inst_code_in AND
         CAM_ACCT_NO =  l_ACCT_NUMBER
       FOR UPDATE NOWAIT;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     l_RESP_CDE := '17';
     l_ERR_MSG  := 'Invalid Account ';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                P_TO_CARD_NO_in || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;



  IF l_ACCT_BALANCE < P_TXN_AMT_in THEN
    l_RESP_CDE := '15';
    l_ERR_MSG  := 'Insufficient Fund ';
    RAISE EXP_REJECT_RECORD;
  END IF;
  IF L_TXN_AMT = 0 THEN
    l_RESP_CDE := '25';
    l_ERR_MSG  := 'INVALID AMOUNT ';
    RAISE EXP_REJECT_RECORD;
  END IF;


  BEGIN
    SELECT CAM_ACCT_BAL, CAM_ACCT_NO,CAM_LEDGER_BAL,
           CAM_TYPE_CODE,   nvl(cam_new_initialload_amt,cam_initialload_amt)
     INTO l_TOACCT_BAL, l_TOACCT_NO,l_TOLEDGER_BAL,
          l_TOACCT_TYPE,l_initialload_amt
     FROM CMS_ACCT_MAST
    WHERE CAM_INST_CODE = p_inst_code_in AND
         CAM_ACCT_NO =  l_TOACCTNUMBER;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     l_RESP_CDE := '26';
     l_RESPMSG  := 'Account number not found ' || P_TO_CARD_NO_in;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     l_RESP_CDE := '21';
     l_RESPMSG  := 'Problem while selecting acct balance ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  l_FROMACCT_NO:=l_ACCT_NUMBER;


  BEGIN
       SP_STATUS_CHECK_GPR( p_inst_code_in,
                            P_TO_CARD_NO_in,
                            p_del_channel_in,
                            l_TOCARDEXP,
                            l_TOCARDSTAT,
                            p_txn_code_in,
                            P_TXN_MODE_in,
                            l_TOPRODCODE,
                            l_TOCARDTYPE,
                            p_msg_type_in,
                            p_business_date_in,
                            p_business_time_in,
                            NULL,
                            NULL,
                            P_MCC_CODE_in,
                            l_RESP_CDE,
                            l_ERR_MSG
                           );

       IF ((l_RESP_CDE <> '1' AND l_ERR_MSG <> 'OK') OR (l_RESP_CDE <> '0' AND l_ERR_MSG <> 'OK')) THEN

         l_ERR_MSG := 'For TO CARD -- '||l_ERR_MSG;
         RAISE EXP_REJECT_RECORD;
     --  ELSE

       END IF;
       l_STATUS_CHK:=l_RESP_CDE;
       l_RESP_CDE:='1';

  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
   RAISE;
  WHEN OTHERS THEN
    l_RESP_CDE := '21';
    l_ERR_MSG  := 'Error from GPR Card Status Check for TO CARD' ||SUBSTR(SQLERRM, 1, 200);
  RAISE EXP_REJECT_RECORD;
  END;

  IF l_STATUS_CHK='1' THEN

     IF p_del_channel_in <> '11' THEN

         BEGIN

               IF TO_DATE(p_business_date_in, 'YYYYMMDD') >
                 LAST_DAY(TO_CHAR(l_TOCARDEXP, 'DD-MON-YY')) THEN

                l_RESP_CDE := '13';
                l_ERR_MSG  := 'TO CARD IS EXPIRED';
                RAISE EXP_REJECT_RECORD;

               END IF;

         EXCEPTION

           WHEN EXP_REJECT_RECORD THEN
            RAISE;

           WHEN OTHERS THEN
            l_RESP_CDE := '21';
            l_ERR_MSG  := 'ERROR IN EXPIRY DATE CHECK FOR TO CARD: Tran Date - ' ||
                        p_business_date_in || ', Expiry Date - ' || l_TOCARDEXP || ',' ||
                        SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;

         END;

    END IF;

        IF l_PRECHECK_FLAG = 1 THEN

             BEGIN
               SP_PRECHECK_TXN( p_inst_code_in,
                                P_TO_CARD_NO_in,
                                p_del_channel_in,
                                l_TOCARDEXP,
                                l_TOCARDSTAT,
                                p_txn_code_in,
                                P_TXN_MODE_in,
                                p_business_date_in,
                                p_business_time_in,
                                L_TXN_AMT,
                                l_ATMONLINE_LIMIT,
                                l_POSONLINE_LIMIT,
                                l_RESP_CDE,
                                l_ERR_MSG
                               );

               IF (l_RESP_CDE <> '1' OR l_ERR_MSG <> 'OK') THEN

                l_ERR_MSG := 'For TO CARD -- '||l_ERR_MSG;
                RAISE EXP_REJECT_RECORD;
               END IF;

             EXCEPTION
               WHEN EXP_REJECT_RECORD THEN
                RAISE;
               WHEN OTHERS THEN
                l_RESP_CDE := '21';
                l_ERR_MSG  := 'Error from precheck processes for TO CARD' ||SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
             END;

        END IF;

  END IF;

   BEGIN
    SP_AUTHORIZE_TXN_CMS_AUTH(p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_del_channel_in,
                        P_TERM_ID_in,
                        p_txn_code_in,
                        P_TXN_MODE_in,
                        p_business_date_in,
                        p_business_time_in,
                        P_FROM_CARD_NO_in,
                        1,
                        L_TXN_AMT,
                        NULL,
                        NULL,
                        P_MCC_CODE_in,
                        p_curr_code_in,
                        NULL,
                        NULL,
                        NULL,
                        l_TOACCT_NO,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        P_FROM_CARD_EXPRY_in,
                        P_STAN_in,
                        '000',
                        p_reversal_code_in,
                        L_TXN_AMT,
                        l_CTOC_AUTH_ID,
                        l_RESP_CDE,
                        l_RESPMSG,
                        l_CAPTURE_DATE,
                        CASE WHEN P_FEE_WAIVER_FLAGT_in='N' THEN
                            'Y'
                            WHEN P_FEE_WAIVER_FLAGT_in='Y' THEN
                            'N' END);
    IF l_RESP_CDE <> '00' AND l_RESPMSG <> 'OK' THEN
    -- l_AUTHMSG := l_RESPMSG;
     RAISE EXP_AUTH_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_AUTH_REJECT_RECORD THEN
     RAISE;

    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'Error from Card authorization' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

   BEGIN
      IF l_PRFL_FLAG = 'Y'
      THEN
         pkg_limits_check.sp_limits_check (NULL,
                                           l_HASH_PAN_FROM,
                                           l_HASH_PAN_TO,
                                           NULL,
                                           p_txn_code_in,
                                           l_TRAN_TYPE,
                                           NULL,
                                           NULL,
                                           p_inst_code_in,
                                           NULL,
                                           l_PRFL_CODE,
                                           L_TXN_AMT,
                                           p_del_channel_in,
                                           l_comb_hash,
                                           l_RESP_CDE,
                                           l_ERR_MSG
                                          );


      END IF;

      IF l_RESP_CDE <> '00' AND l_ERR_MSG <> 'OK'
      THEN
         l_ERR_MSG := 'Error from Limit Check Process ' || l_ERR_MSG;
         RAISE EXP_REJECT_RECORD;
      END IF;
   EXCEPTION
      WHEN EXP_REJECT_RECORD
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         l_RESP_CDE := '21';
         l_ERR_MSG :=
                'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
   END;

 begin
           SELECT cpc_profile_code,cpc_badcredit_flag,cpc_badcredit_transgrpid
           into l_profile_code,l_badcredit_flag,l_badcredit_transgrpid
            FROM cms_prod_cattype
            WHERE CPC_INST_CODE = p_inst_code_in
            and   cpc_prod_code = l_TOPRODCODE
            and   cpc_card_type = l_TOCARDTYPE;

          exception
              when others then
                   l_ERR_MSG  := 'Error while getting details from prod cattype';
            l_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          end;

  BEGIN


      SELECT TO_NUMBER(CBP_PARAM_VALUE)
     INTO l_MAX_CARD_BAL
     FROM CMS_BIN_PARAM
    WHERE CBp_inst_code = p_inst_code_in AND
         CBP_PARAM_NAME = 'Max Card Balance' AND
         CBP_PROFILE_CODE=l_profile_code;


  EXCEPTION
    WHEN OTHERS THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;


IF l_badcredit_flag = 'Y'
         THEN
            EXECUTE IMMEDIATE    'SELECT  count(*)
              FROM vms_group_tran_detl
              WHERE vgd_group_id ='
                              || l_badcredit_transgrpid
                              || '
              AND vgd_tran_detl LIKE
              (''%'
                              || p_del_channel_in
                              || ':'
                              || p_txn_code_in
                              || '%'')'
                         INTO l_cnt;

            IF l_cnt = 1
            THEN
               l_enable_flag := 'N';

               IF    ((l_TOACCT_BAL) > l_initialload_amt
                     )
                  OR ((l_TOACCT_BAL + L_TXN_AMT) > l_initialload_amt
                     )
               THEN
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = p_inst_code_in
                     AND cap_pan_code = l_HASH_PAN_TO;

                 BEGIN
         sp_log_cardstat_chnge (p_inst_code_in,
                                l_HASH_PAN_TO,
                                l_ENCR_PAN_TO,
                                l_CTOC_AUTH_ID,
                                '10',
                                p_rrn_in,
                                p_business_date_in,
                                p_business_time_in,
                                l_RESP_CDE,
                                l_ERR_MSG
                               );

         IF l_RESP_CDE <> '00' AND l_ERR_MSG <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            l_RESP_CDE := '21';
            l_ERR_MSG :=
                  'Error while logging system initiated card status change '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
               END IF;
            END IF;
         END IF;

         IF l_enable_flag = 'Y' and (l_TOACCT_BAL > l_MAX_CARD_BAL
               OR (l_TOACCT_BAL + L_TXN_AMT) > l_MAX_CARD_BAL)
         THEN

               l_RESP_CDE := '30';
               l_ERR_MSG := 'EXCEEDING MAXIMUM CARD BALANCE';
               RAISE exp_reject_record;

         END IF;

  BEGIN
    UPDATE CMS_ACCT_MAST
      SET CAM_ACCT_BAL   = CAM_ACCT_BAL + L_TXN_AMT,
         CAM_LEDGER_BAL = CAM_LEDGER_BAL + L_TXN_AMT
    WHERE CAM_INST_CODE = p_inst_code_in AND
         CAM_ACCT_NO =l_TOACCTNUMBER;

    IF SQL%ROWCOUNT = 0 THEN
     l_RESP_CDE := '21';
     l_RESPMSG  := 'Error while updating amount in to acct no ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
     l_RESP_CDE := '21';
     l_RESPMSG  := 'Error while amount in to acct no ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN


    IF TRIM(l_TRANS_DESC) IS NOT NULL THEN

     l_NARRATION := l_TRANS_DESC || '/';

    END IF;

    IF TRIM(l_CTOC_AUTH_ID) IS NOT NULL THEN

     l_NARRATION := l_NARRATION || l_CTOC_AUTH_ID || '/';

    END IF;

    IF TRIM(l_FROMACCT_NO) IS NOT NULL THEN

     l_NARRATION := l_NARRATION || l_FROMACCT_NO || '/';

    END IF;

    IF TRIM(p_business_date_in) IS NOT NULL THEN

     l_NARRATION := l_NARRATION || p_business_date_in;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

     l_RESP_CDE := '21';
     l_ERR_MSG  := 'Error in finding the narration ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;

  END;

  BEGIN
        
		--Added for VMS-5735/FSP-991  
         select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
         INTO   v_Retperiod 
         FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
         WHERE  OPERATION_TYPE='ARCHIVE' 
         AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
         v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');
		 
		IF (v_Retdate>v_Retperiod) THEN                                     --Added for VMS-5735/FSP-991 
  
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET
              CTD_MOBILE_NUMBER=P_MOB_NO_in,
              CTD_DEVICE_ID=p_device_id_in,
              CTD_HASHKEY_ID=l_HASHKEY_ID
              WHERE CTD_RRN=p_rrn_in AND CTD_BUSINESS_DATE=p_business_date_in
              AND CTD_BUSINESS_TIME=p_business_time_in
              AND CTD_DELIVERY_CHANNEL=p_del_channel_in
              AND CTD_TXN_CODE=p_txn_code_in
              AND CTD_MSG_TYPE=p_msg_type_in
              AND CTD_INST_CODE=p_inst_code_in;
			  
		ELSE
		    
			  UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST          --Added for VMS-5735/FSP-991                             
              SET
              CTD_MOBILE_NUMBER=P_MOB_NO_in,
              CTD_DEVICE_ID=p_device_id_in,
              CTD_HASHKEY_ID=l_HASHKEY_ID
              WHERE CTD_RRN=p_rrn_in AND CTD_BUSINESS_DATE=p_business_date_in
              AND CTD_BUSINESS_TIME=p_business_time_in
              AND CTD_DELIVERY_CHANNEL=p_del_channel_in
              AND CTD_TXN_CODE=p_txn_code_in
              AND CTD_MSG_TYPE=p_msg_type_in
              AND CTD_INST_CODE=p_inst_code_in;
		
		END IF;

             IF SQL%ROWCOUNT = 0 THEN
                l_RESPMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                p_resp_code_out := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                p_resp_code_out := '21';
                l_RESPMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;

  BEGIN
    l_DR_CR_FLAG := 'CR';


    INSERT INTO CMS_STATEMENTS_LOG
     (CSL_PAN_NO,
      CSL_OPENING_BAL,
      CSL_TRANS_AMOUNT,
      CSL_TRANS_TYPE,
      CSL_TRANS_DATE,
      CSL_CLOSING_BALANCE,
      CSL_TRANS_NARRRATION,
      CSL_PAN_NO_ENCR,
      CSL_RRN,
      CSL_AUTH_ID,
      CSL_BUSINESS_DATE,
      CSL_BUSINESS_TIME,
      TXN_FEE_FLAG,
      CSL_DELIVERY_CHANNEL,
      CSL_INST_CODE,
      CSL_TXN_CODE,
      CSL_ACCT_NO,
      CSL_INS_USER,
      CSL_INS_DATE,
      CSL_PANNO_LAST4DIGIT,
      CSL_ACCT_TYPE,
      CSL_TIME_STAMP,
      CSL_PROD_CODE,csl_card_type
      )
    VALUES
     (l_HASH_PAN_TO,
      l_TOLEDGER_BAL,
      L_TXN_AMT,
      'CR',
      l_TRAN_DATE,
      DECODE(l_DR_CR_FLAG,
            'DR',
            l_TOLEDGER_BAL - L_TXN_AMT,
            'CR',
            l_TOLEDGER_BAL + L_TXN_AMT,
            'NA',
            l_TOLEDGER_BAL),
      l_NARRATION,
      l_ENCR_PAN_TO,
      p_rrn_in,
      l_CTOC_AUTH_ID,
      p_business_date_in,
      p_business_time_in,
      'N',
      p_del_channel_in,
      p_inst_code_in,
      p_txn_code_in,
      l_TOACCT_NO,
      1,
      SYSDATE,
      (substr(P_TO_CARD_NO_in, length(P_TO_CARD_NO_in) -3,length(P_TO_CARD_NO_in))),
      l_TOACCT_TYPE,
      l_TIME_STAMP,
      l_TOPRODCODE,l_TOCARDTYPE
      );
  EXCEPTION
    WHEN OTHERS THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'Error creating entry in statement log ';
     RAISE EXP_REJECT_RECORD;

  END;


        Begin
		
			--Added for VMS-5735/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');
		   
		IF (v_Retdate>v_Retperiod) THEN                                  --Added for VMS-5735/FSP-991


          update cms_statements_log
          set csl_time_stamp = l_TIME_STAMP
          where csl_pan_no = l_HASH_PAN_FROM
          and   csl_rrn = p_rrn_in
          and   csl_delivery_channel=p_del_channel_in
          and   csl_txn_code = p_txn_code_in
          and   csl_business_date = p_business_date_in
          and   csl_business_time = p_business_time_in;
		  
		ELSE
		  
		  update VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST              --Added for VMS-5735/FSP-991
          set csl_time_stamp = l_TIME_STAMP
          where csl_pan_no = l_HASH_PAN_FROM
          and   csl_rrn = p_rrn_in
          and   csl_delivery_channel=p_del_channel_in
          and   csl_txn_code = p_txn_code_in
          and   csl_business_date = p_business_date_in
          and   csl_business_time = p_business_time_in;
		  
		END IF;
		  

          if sql%rowcount = 0
          then

             l_RESP_CDE := '21';
             l_ERR_MSG  := 'Timestamp not updated in statement log';
             RAISE EXP_REJECT_RECORD;

          end if;

        exception when EXP_REJECT_RECORD
        then
            raise;
        when others
        then

             l_RESP_CDE := '21';
             l_ERR_MSG  := 'Error while updating timestamp in statement log '||substr(sqlerrm,1,100);
             RAISE EXP_REJECT_RECORD;
        end;

  BEGIN
   
       --Added for VMS-5735/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');

   IF (v_Retdate>v_Retperiod) THEN                                          --Added for VMS-5735/FSP-991
   
    UPDATE TRANSACTIONLOG
      SET TOPUP_CARD_NO     = l_HASH_PAN_TO,
         TOPUP_CARD_NO_ENCR = l_ENCR_PAN_TO,
         TOPUP_ACCT_NO      =    l_TOACCTNUMBER,
           topup_acct_balance  = l_TOACCT_BAL+L_TXN_AMT,
          topup_ledger_balance =l_TOLEDGER_BAL+L_TXN_AMT,
          TOPUP_ACCT_TYPE     = l_TOACCT_TYPE,
         TIME_STAMP           = l_TIME_STAMP,
          uuid=p_uuid_in,
          os_name=p_osname_in,
          os_version=p_osversion_in,
          gps_coordinates=p_gpscoordinates_in,
          display_resolution=p_displayresolution_in,
          physical_memory=p_physicalmemory_in,
          app_name=p_appname_in,
          app_version=p_appversion_in,
          session_id=p_sessionid_in,
          device_country=p_devicecountry_in,
          device_region=p_deviceregion_in,
          ip_country=p_ipcountry_in,
          proxy_flag=p_proxy_in,
          REQ_PARTNER_ID=p_partner_id_in
    WHERE RRN = p_rrn_in AND DELIVERY_CHANNEL = p_del_channel_in AND
         TXN_CODE = p_txn_code_in AND BUSINESS_DATE = p_business_date_in AND
         BUSINESS_TIME = p_business_time_in AND
         CUSTOMER_CARD_NO = l_HASH_PAN_FROM;
		 
   ELSE
       
	   UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST          --Added for VMS-5733/FSP-991
       SET TOPUP_CARD_NO     = l_HASH_PAN_TO,
         TOPUP_CARD_NO_ENCR = l_ENCR_PAN_TO,
         TOPUP_ACCT_NO      =    l_TOACCTNUMBER,
           topup_acct_balance  = l_TOACCT_BAL+L_TXN_AMT,
          topup_ledger_balance =l_TOLEDGER_BAL+L_TXN_AMT,
          TOPUP_ACCT_TYPE     = l_TOACCT_TYPE,
         TIME_STAMP           = l_TIME_STAMP,
          uuid=p_uuid_in,
          os_name=p_osname_in,
          os_version=p_osversion_in,
          gps_coordinates=p_gpscoordinates_in,
          display_resolution=p_displayresolution_in,
          physical_memory=p_physicalmemory_in,
          app_name=p_appname_in,
          app_version=p_appversion_in,
          session_id=p_sessionid_in,
          device_country=p_devicecountry_in,
          device_region=p_deviceregion_in,
          ip_country=p_ipcountry_in,
          proxy_flag=p_proxy_in,
          REQ_PARTNER_ID=p_partner_id_in
    WHERE RRN = p_rrn_in AND DELIVERY_CHANNEL = p_del_channel_in AND
         TXN_CODE = p_txn_code_in AND BUSINESS_DATE = p_business_date_in AND
         BUSINESS_TIME = p_business_time_in AND
         CUSTOMER_CARD_NO = l_HASH_PAN_FROM;  
   
   END IF;

    IF SQL%ROWCOUNT <> 1 THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;

  END;
  BEGIN
  
  IF (v_Retdate>v_Retperiod) THEN                                          --Added for VMS-5735/FSP-991
  
    UPDATE TRANSACTIONLOG
      SET ANI = p_ani_in, DNI = p_dni_in, IPADDRESS = p_ip_addr_in,
    REMARK  = 'From Account No : ' || FN_MASK_ACCT(l_FROMACCT_NO) || ' ' ||
                   'To Account No : ' || FN_MASK_ACCT(l_TOACCTNUMBER),
                   uuid=p_uuid_in,
                  os_name=p_osname_in,
                  os_version=p_osversion_in,
                  gps_coordinates=p_gpscoordinates_in,
                  display_resolution=p_displayresolution_in,
                  physical_memory=p_physicalmemory_in,
                  app_name=p_appname_in,
                  app_version=p_appversion_in,
                  session_id=p_sessionid_in,
                  device_country=p_devicecountry_in,
                  device_region=p_deviceregion_in,
                  ip_country=p_ipcountry_in,
                  proxy_flag=p_proxy_in,
                  REQ_PARTNER_ID=p_partner_id_in
    WHERE RRN = p_rrn_in AND BUSINESS_DATE = p_business_date_in AND
         TXN_CODE = p_txn_code_in AND MSGTYPE = p_msg_type_in AND
         BUSINESS_TIME = p_business_time_in AND
         DELIVERY_CHANNEL = p_del_channel_in;
		 
  ELSE
  
      UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST               --Added for VMS-5735/FSP-991
      SET ANI = p_ani_in, DNI = p_dni_in, IPADDRESS = p_ip_addr_in,
    REMARK  = 'From Account No : ' || FN_MASK_ACCT(l_FROMACCT_NO) || ' ' ||
                   'To Account No : ' || FN_MASK_ACCT(l_TOACCTNUMBER),
                   uuid=p_uuid_in,
                  os_name=p_osname_in,
                  os_version=p_osversion_in,
                  gps_coordinates=p_gpscoordinates_in,
                  display_resolution=p_displayresolution_in,
                  physical_memory=p_physicalmemory_in,
                  app_name=p_appname_in,
                  app_version=p_appversion_in,
                  session_id=p_sessionid_in,
                  device_country=p_devicecountry_in,
                  device_region=p_deviceregion_in,
                  ip_country=p_ipcountry_in,
                  proxy_flag=p_proxy_in,
                  REQ_PARTNER_ID=p_partner_id_in
    WHERE RRN = p_rrn_in AND BUSINESS_DATE = p_business_date_in AND
         TXN_CODE = p_txn_code_in AND MSGTYPE = p_msg_type_in AND
         BUSINESS_TIME = p_business_time_in AND
         DELIVERY_CHANNEL = p_del_channel_in;
		 
  
  END IF;

          IF SQL%ROWCOUNT <> 1 THEN
         l_RESP_CDE := '21';
         l_ERR_MSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
          RAISE EXP_REJECT_RECORD;
          END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     l_RESP_CDE := '69';
     l_ERR_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                SUBSTR(SQLERRM, 1, 300);
      RAISE EXP_REJECT_RECORD;
  END;

  IF p_txn_code_in NOT IN ('07','13','39') THEN

    BEGIN
     SELECT PTM_TERMINAL_INDICATOR
       INTO l_TERMINAL_INDICATOR
       FROM PCMS_TERMINAL_MAST
      WHERE PTM_TERMINAL_ID = P_TERM_ID_in AND PTM_INST_CODE = p_inst_code_in;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       l_RESP_CDE := '21';
       l_ERR_MSG  := 'Terminal indicator is not declared for terminal id' ||
                  P_TERM_ID_in;
       RAISE EXP_REJECT_RECORD;

     WHEN OTHERS THEN
       l_RESP_CDE := '21';
       l_ERR_MSG  := 'Terminal indicator is not declared for terminal id' ||
                  SQLERRM || ' ' || SQLCODE;
       RAISE EXP_REJECT_RECORD;
    END;
  END IF;

  IF p_txn_code_in not in ('07','13','39') THEN
    BEGIN

     IF l_TERMINAL_INDICATOR IS NOT NULL AND l_CTOC_AUTH_ID IS NOT NULL AND
        l_RESP_CDE IS NOT NULL AND l_TOACCT_BAL IS NOT NULL THEN
       l_RESP_CONC_MSG := RPAD(P_FROM_CARD_NO_in, '19', ' ') ||
                      RPAD(l_TOACCT_BAL + L_TXN_AMT, '12', ' ') ||
                      RPAD(l_CTOC_AUTH_ID, '6', ' ') ||
                      RPAD(l_RESP_CDE, '2', ' ') ||
                      RPAD(l_TERMINAL_INDICATOR, '1', ' ');
       p_resp_msg_out      := l_RESP_CONC_MSG;
     ELSE
       l_RESP_CDE := '21';
       l_ERR_MSG  := ' Error while crating response message :- Either terminal indicator or authid is null ';
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       l_RESP_CDE := '21';
       l_ERR_MSG  := 'Exception while creating the response format' ||
                  SUBSTR(SQLERRM, 1, 200);

       RAISE EXP_REJECT_RECORD;
    END;
  END IF;

  p_resp_code_out := '00';
  IF p_resp_msg_out = 'OK' OR p_resp_msg_out IS NULL THEN
    BEGIN
     SELECT CAM_ACCT_BAL
       INTO l_TOACCT_BAL
       FROM CMS_ACCT_MAST
      WHERE CAM_INST_CODE = p_inst_code_in AND
           CAM_ACCT_NO =
           (SELECT CAP.CAP_ACCT_NO
             FROM CMS_APPL_PAN CAP
            WHERE CAP.CAP_PAN_CODE = l_HASH_PAN_FROM);
     p_resp_msg_out := l_TOACCT_BAL;
    EXCEPTION
     WHEN OTHERS THEN
       l_RESP_CDE := '21';
       l_ERR_MSG  := 'Error while selecting CMS_ACCT_MAST' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
  END IF;

   BEGIN
      IF l_PRFL_FLAG = 'Y'
      THEN
         pkg_limits_check.sp_limitcnt_reset (p_inst_code_in,
                                             NULL,
                                             L_TXN_AMT,
                                             l_comb_hash,
                                             l_RESP_CDE,
                                             l_ERR_MSG
                                            );
      END IF;

      IF l_RESP_CDE <> '00' AND l_ERR_MSG <> 'OK'
      THEN
         l_ERR_MSG := 'From Procedure sp_limitcnt_reset' || l_ERR_MSG;
         RAISE EXP_REJECT_RECORD;
      END IF;
   EXCEPTION
      WHEN EXP_REJECT_RECORD
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         l_RESP_CDE := '21';
         l_ERR_MSG :=
               'Error from Limit Reset Count Process '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
   END;

    BEGIN
        SELECT sum(CSL_TRANS_AMOUNT) INTO P_FEE_AMT_out
        FROM VMSCMS.CMS_STATEMENTS_LOG_VW                     --Added for VMS-5735/FSP-991
        WHERE TXN_FEE_FLAG='Y'
        AND CSL_DELIVERY_CHANNEL=p_del_channel_in
        AND CSL_TXN_CODE=p_txn_code_in
        AND CSL_PAN_NO= l_HASH_PAN_FROM
        AND CSL_RRN=p_rrn_in
        and csl_inst_code=p_inst_code_in;
    exception
        when no_data_found then
            P_FEE_AMT_out:=0;

        WHEN OTHERS  THEN
            l_RESP_CDE := '21';
            l_ERR_MSG :=  'Error while selecting CMS_STATEMENTS_LOG ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

EXCEPTION

  WHEN EXP_AUTH_REJECT_RECORD THEN
    p_resp_code_out := l_RESP_CDE;
    p_resp_msg_out  := l_RESPMSG;
  BEGIN
  
        --Added for VMS-5735/FSP-991
			   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			   INTO   v_Retperiod 
			   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
			   WHERE  OPERATION_TYPE='ARCHIVE' 
			   AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
			   
			   v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');
			   
		IF (v_Retdate>v_Retperiod)  THEN                             --Added for VMS-5735/FSP-991            
		
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET
              CTD_MOBILE_NUMBER=P_MOB_NO_in,
              CTD_DEVICE_ID=p_device_id_in
              WHERE CTD_RRN=p_rrn_in AND CTD_BUSINESS_DATE=p_business_date_in
              AND CTD_BUSINESS_TIME=p_business_time_in
              AND CTD_DELIVERY_CHANNEL=p_del_channel_in
              AND CTD_TXN_CODE=p_txn_code_in
              AND CTD_MSG_TYPE=p_msg_type_in
              AND CTD_INST_CODE=p_inst_code_in;
			  
	    ELSE 
		
		      UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST           --Added for VMS-5735/FSP-991
              SET
              CTD_MOBILE_NUMBER=P_MOB_NO_in,
              CTD_DEVICE_ID=p_device_id_in
              WHERE CTD_RRN=p_rrn_in AND CTD_BUSINESS_DATE=p_business_date_in
              AND CTD_BUSINESS_TIME=p_business_time_in
              AND CTD_DELIVERY_CHANNEL=p_del_channel_in
              AND CTD_TXN_CODE=p_txn_code_in
              AND CTD_MSG_TYPE=p_msg_type_in
              AND CTD_INST_CODE=p_inst_code_in;
		
		END IF;

             IF SQL%ROWCOUNT = 0 THEN
                l_RESPMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                p_resp_code_out := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                p_resp_code_out := '21';
                l_RESPMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;

  BEGIN
  
       --Added for VMS-5735/FSP-991
	   
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');

 IF (v_Retdate>v_Retperiod) THEN                                                 --Added for VMS-5735/FSP-991
 
    UPDATE TRANSACTIONLOG
      SET TOPUP_CARD_NO     = l_HASH_PAN_TO,
         TOPUP_CARD_NO_ENCR = l_ENCR_PAN_TO,
         TOPUP_ACCT_NO      = l_TOACCTNUMBER,
         topup_acct_balance  = l_TOACCT_BAL,
         topup_ledger_balance =l_TOLEDGER_BAL,
         TOPUP_ACCT_TYPE     = l_TOACCT_TYPE,
         TIME_STAMP           = l_TIME_STAMP,
       REMARK               = 'From Account No : ' ||
                             FN_MASK_ACCT(l_FROMACCT_NO) || ' ' ||
                             'To Account No : ' ||
                             FN_MASK_ACCT(l_TOACCTNUMBER),
                             uuid=p_uuid_in,
                            os_name=p_osname_in,
                            os_version=p_osversion_in,
                            gps_coordinates=p_gpscoordinates_in,
                            display_resolution=p_displayresolution_in,
                            physical_memory=p_physicalmemory_in,
                            app_name=p_appname_in,
                            app_version=p_appversion_in,
                            session_id=p_sessionid_in,
                            device_country=p_devicecountry_in,
                            device_region=p_deviceregion_in,
                            ip_country=p_ipcountry_in,
                            proxy_flag=p_proxy_in,
                            REQ_PARTNER_ID=p_partner_id_in
    WHERE RRN = p_rrn_in AND DELIVERY_CHANNEL = p_del_channel_in AND
         TXN_CODE = p_txn_code_in AND BUSINESS_DATE = p_business_date_in AND
         BUSINESS_TIME = p_business_time_in AND
         CUSTOMER_CARD_NO = l_HASH_PAN_FROM;
		 
 ELSE
  
      UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST                              --Added for VMS-5735/FSP-991
      SET TOPUP_CARD_NO     = l_HASH_PAN_TO,
         TOPUP_CARD_NO_ENCR = l_ENCR_PAN_TO,
         TOPUP_ACCT_NO      = l_TOACCTNUMBER,
         topup_acct_balance  = l_TOACCT_BAL,
         topup_ledger_balance =l_TOLEDGER_BAL,
         TOPUP_ACCT_TYPE     = l_TOACCT_TYPE,
         TIME_STAMP           = l_TIME_STAMP,
       REMARK               = 'From Account No : ' ||
                             FN_MASK_ACCT(l_FROMACCT_NO) || ' ' ||
                             'To Account No : ' ||
                             FN_MASK_ACCT(l_TOACCTNUMBER),
                             uuid=p_uuid_in,
                            os_name=p_osname_in,
                            os_version=p_osversion_in,
                            gps_coordinates=p_gpscoordinates_in,
                            display_resolution=p_displayresolution_in,
                            physical_memory=p_physicalmemory_in,
                            app_name=p_appname_in,
                            app_version=p_appversion_in,
                            session_id=p_sessionid_in,
                            device_country=p_devicecountry_in,
                            device_region=p_deviceregion_in,
                            ip_country=p_ipcountry_in,
                            proxy_flag=p_proxy_in,
                            REQ_PARTNER_ID=p_partner_id_in
    WHERE RRN = p_rrn_in AND DELIVERY_CHANNEL = p_del_channel_in AND
         TXN_CODE = p_txn_code_in AND BUSINESS_DATE = p_business_date_in AND
         BUSINESS_TIME = p_business_time_in AND
         CUSTOMER_CARD_NO = l_HASH_PAN_FROM;
 
 END IF;

    IF SQL%ROWCOUNT <> 1 THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
      WHEN OTHERS THEN
     l_RESP_CDE := '21';
     l_ERR_MSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;

  END;

  WHEN EXP_REJECT_RECORD THEN
    ROLLBACK ;
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code
       INTO l_ACCT_BALANCE, l_LEDGER_BALANCE,
            l_FRMACCT_TYPE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = l_HASH_PAN_FROM AND
                 CAp_inst_code = p_inst_code_in) AND
           CAM_INST_CODE = p_inst_code_in;
    EXCEPTION
     WHEN OTHERS THEN
       l_ACCT_BALANCE   := 0;
       l_LEDGER_BALANCE := 0;
    END;


 if l_TOACCTNUMBER is null
     then

         BEGIN

              SELECT CAP_ACCT_NO
                       INTO   l_TOACCTNUMBER
                   FROM   CMS_APPL_PAN
              WHERE  CAp_inst_code = p_inst_code_in
              AND    CAP_PAN_CODE  = l_HASH_PAN_TO;

         EXCEPTION WHEN OTHERS THEN
            null;

         END;

     END IF;


      BEGIN
        SELECT CAM_ACCT_BAL, CAM_ACCT_NO,CAM_LEDGER_BAL,
               CAM_TYPE_CODE
         INTO l_TOACCT_BAL, l_TOACCT_NO,l_TOLEDGER_BAL,
              l_TOACCT_TYPE
         FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = p_inst_code_in AND
             CAM_ACCT_NO =  l_TOACCTNUMBER;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        null;
        WHEN OTHERS THEN
        null;
      END;

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO p_resp_code_out
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = p_inst_code_in AND
           CMS_DELIVERY_CHANNEL = p_del_channel_in AND
           CMS_RESPONSE_ID = l_RESP_CDE;
     p_resp_msg_out := l_ERR_MSG;
    EXCEPTION
     WHEN OTHERS THEN
       p_resp_msg_out  := 'Problem while selecting data from response master ' ||
                   l_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       p_resp_code_out := '69';
         RETURN;
    END;

     if l_FROM_PRODCODE is null
     then

         BEGIN

              SELECT CAP_CARD_STAT,
                     CAP_PROD_CODE,
                     CAP_CARD_TYPE,
                     CAP_ACCT_NO
              INTO   l_FROMCARDSTAT,
                     l_FROM_PRODCODE,
                     l_FROM_CARDTYPE,
                     l_FROMACCT_NO
              FROM   CMS_APPL_PAN
              WHERE  CAp_inst_code = p_inst_code_in
              AND    CAP_PAN_CODE  = l_HASH_PAN_FROM;

         EXCEPTION WHEN OTHERS THEN
            null;

         END;

     end if;


     if l_DR_CR_FLAG is null
     then

        BEGIN

             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO l_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = p_txn_code_in
              AND   CTM_DELIVERY_CHANNEL = p_del_channel_in
              AND   CTM_INST_CODE = p_inst_code_in;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;


     BEGIN
       INSERT INTO TRANSACTIONLOG
        (MSGTYPE,
         RRN,
         DELIVERY_CHANNEL,
         TERMINAL_ID,
         DATE_TIME,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         TXN_STATUS,
         RESPONSE_CODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOPUP_CARD_NO,
         TOPUP_ACCT_NO,
         TOPUP_ACCT_TYPE,
         BANK_CODE,
         TOTAL_AMOUNT,
         CURRENCYCODE,
         ADDCHARGE,
         PRODUCTID,
         CATEGORYID,
         ATM_NAME_LOCATION,
         AUTH_ID,
         AMOUNT,
         PREAUTHAMOUNT,
         PARTIALAMOUNT,
         INSTCODE,
         CUSTOMER_CARD_NO_ENCR,
         TOPUP_CARD_NO_ENCR,
         PROXY_NUMBER,
         REVERSAL_CODE,
         CUSTOMER_ACCT_NO,
         ACCT_BALANCE,
         LEDGER_BALANCE,
         RESPONSE_ID,
         ANI,
         DNI,
         IPADDRESS,
         CARDSTATUS,
         TRANS_DESC,
         ERROR_MSG,
         topup_acct_balance ,
         topup_ledger_balance,
         ACCT_TYPE,
         TIME_STAMP,
         CR_DR_FLAG,
       REMARK,
       uuid,
      os_name,
      os_version,
      gps_coordinates,
      display_resolution,
      physical_memory,
      app_name,
      app_version,
      session_id,
      device_country,
      device_region,
      ip_country,
      proxy_flag,
      REQ_PARTNER_ID
         )
       VALUES
        ('0200',
         p_rrn_in,
         p_del_channel_in,
         0,
         TO_DATE(p_business_date_in, 'YYYY/MM/DD'),
         p_txn_code_in,
         l_TXN_TYPE,
         0,
         DECODE(p_resp_code_out, '00', 'C', 'F'),
         p_resp_code_out,
         p_business_date_in,
         SUBSTR(p_business_time_in, 1, 10),
         l_HASH_PAN_FROM,
         l_HASH_PAN_TO,
         l_TOACCTNUMBER,
         l_TOACCT_TYPE,
         p_inst_code_in,
         TRIM(TO_CHAR(nvl(L_TXN_AMT,0), '99999999999999990.99')),
         p_curr_code_in,
         NULL,
         l_FROM_PRODCODE,
         l_FROM_CARDTYPE,
         0,
         l_CTOC_AUTH_ID,
         TRIM(TO_CHAR(nvl(L_TXN_AMT,0), '99999999999999990.99')),
         '0.00',
         '0.00',
         p_inst_code_in,
         l_ENCR_PAN_FROM,
         l_ENCR_PAN_TO,
         '',
         0,
         l_ACCT_NUMBER,
         nvl(l_ACCT_BALANCE,0),
         nvl(l_LEDGER_BALANCE,0),
         l_RESP_CDE,
         p_ani_in,
         p_dni_in,
         p_ip_addr_in,
         l_FROMCARDSTAT,
         l_TRANS_DESC,
         l_ERR_MSG,
         nvl(l_TOACCT_BAL,0),
         nvl(l_TOLEDGER_BAL,0),
         l_FRMACCT_TYPE,
         l_TIME_STAMP,
         l_DR_CR_FLAG,
       'From Account No : ' || FN_MASK_ACCT(l_FROMACCT_NO) || ' ' ||
        'To Account No : ' || FN_MASK_ACCT(l_TOACCTNUMBER),
        p_uuid_in,
        p_osname_in,
        p_osversion_in,
        p_gpscoordinates_in,
        p_displayresolution_in,
        p_physicalmemory_in,
        p_appname_in,
        p_appversion_in,
        p_sessionid_in,
        p_devicecountry_in,
        p_deviceregion_in,
        p_ipcountry_in,
        p_proxy_in,
        p_partner_id_in
        );

     EXCEPTION
       WHEN OTHERS THEN

        p_resp_code_out := '89';
        p_resp_msg_out  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
            RETURN;
     END;

    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        CTD_ACTUAL_AMOUNT,
        CTD_FEE_AMOUNT,
        CTD_WAIVER_AMOUNT,
        CTD_SERVICETAX_AMOUNT,
        CTD_CESS_AMOUNT,
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_LUPD_DATE,
        CTD_INST_CODE,
        CTD_LUPD_USER,
        CTD_INS_DATE,
        CTD_INS_USER,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        REQUEST_XML,
        CTD_CUST_ACCT_NUMBER,
        CTD_ADDR_VERIFY_RESPONSE,
        CTD_MOBILE_NUMBER,CTD_DEVICE_ID,CTD_HASHKEY_ID
        )
     VALUES
       (p_del_channel_in,
        p_txn_code_in,
        l_TXN_TYPE,
        P_TXN_MODE_in,
        p_business_date_in,
        p_business_time_in,
        l_HASH_PAN_FROM,
        L_TXN_AMT,
        p_curr_code_in,
        L_TXN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        L_TXN_AMT,
        l_CURR_CODE,
        'E',
        l_ERR_MSG,
        p_rrn_in,
        P_STAN_in,
        SYSDATE,
        p_inst_code_in,
        1,
        SYSDATE,
        1,
        l_ENCR_PAN_FROM,
        '000',
        '',
        l_ACCT_NUMBER,
        '',P_MOB_NO_in,p_device_id_in,l_HASHKEY_ID
        );
     p_resp_msg_out := l_ERR_MSG;
    EXCEPTION
     WHEN OTHERS THEN
       p_resp_msg_out  := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       p_resp_code_out := '99';
       RETURN;
    END;
  WHEN OTHERS THEN
    ROLLBACK ;
    l_RESP_CDE := '69';
    l_ERR_MSG  := 'Error from transaction processing ' ||
               SUBSTR(SQLERRM, 1, 90);

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO p_resp_code_out
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = p_inst_code_in AND
           CMS_DELIVERY_CHANNEL = p_del_channel_in AND
           CMS_RESPONSE_ID = l_RESP_CDE;
     p_resp_msg_out := l_ERR_MSG;

     IF p_resp_code_out = '00' THEN
       SELECT CAM_ACCT_BAL
        INTO l_TOACCT_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = p_inst_code_in AND
            CAM_ACCT_NO =
            (SELECT CAP.CAP_ACCT_NO
               FROM CMS_APPL_PAN CAP
              WHERE CAP.CAP_PAN_CODE = l_HASH_PAN_FROM);
       p_resp_msg_out := l_TOACCT_BAL;
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       p_resp_msg_out  := 'Problem while selecting data from response master ' ||
                   l_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       p_resp_code_out := '99';
         RETURN;
    END;


      BEGIN
        SELECT CAM_ACCT_BAL, CAM_ACCT_NO,CAM_LEDGER_BAL,
               CAM_TYPE_CODE
         INTO l_TOACCT_BAL, l_TOACCT_NO,l_TOLEDGER_BAL,
              l_TOACCT_TYPE
         FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = p_inst_code_in AND
             CAM_ACCT_NO =  l_TOACCTNUMBER;


      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        null;
        WHEN OTHERS THEN
        null;
      END;



    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        CTD_ACTUAL_AMOUNT,
        CTD_FEE_AMOUNT,
        CTD_WAIVER_AMOUNT,
        CTD_SERVICETAX_AMOUNT,
        CTD_CESS_AMOUNT,
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_LUPD_DATE,
        CTD_INST_CODE,
        CTD_LUPD_USER,
        CTD_INS_DATE,
        CTD_INS_USER,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        REQUEST_XML,
        CTD_CUST_ACCT_NUMBER,
        CTD_ADDR_VERIFY_RESPONSE,
        CTD_MOBILE_NUMBER,CTD_DEVICE_ID,CTD_HASHKEY_ID
        )
     VALUES
       (p_del_channel_in,
        p_txn_code_in,
        l_TXN_TYPE,
        P_TXN_MODE_in,
        p_business_date_in,
        p_business_time_in,
        l_HASH_PAN_FROM,
        L_TXN_AMT,
        p_curr_code_in,
        L_TXN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        L_TXN_AMT,
        l_CURR_CODE,
        'E',
        l_ERR_MSG,
        p_rrn_in,
        P_STAN_in,
        SYSDATE,
        p_inst_code_in,
        1,
        SYSDATE,
        1,
        l_ENCR_PAN_FROM,
        '000',
        '',
        l_ACCT_NUMBER,
        '',P_MOB_NO_in,p_device_id_in,l_HASHKEY_ID
        );
    EXCEPTION
     WHEN OTHERS THEN
       p_resp_msg_out  := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       p_resp_code_out := '99';
       RETURN;
    END;

  
IF (v_Retdate>v_Retperiod) THEN                                          --Added for VMS-5735/FSP-991

    SELECT COUNT(*)
     INTO l_COUNT
     FROM TRANSACTIONLOG
    WHERE INSTCODE = p_inst_code_in AND RRN = p_rrn_in AND
         BUSINESS_DATE = p_business_date_in AND BUSINESS_TIME = p_business_time_in;
		 
ELSE
   
    SELECT COUNT(*)
    INTO l_COUNT
    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                           --Added for VMS-5735/FSP-991
    WHERE INSTCODE = p_inst_code_in AND RRN = p_rrn_in AND
         BUSINESS_DATE = p_business_date_in AND BUSINESS_TIME = p_business_time_in;

END IF ;


    IF l_COUNT < 1 THEN

     if l_FROM_PRODCODE is null
     then

         BEGIN

              SELECT CAP_CARD_STAT,
                     CAP_PROD_CODE,
                     CAP_CARD_TYPE,
                     CAP_ACCT_NO
              INTO   l_FROMCARDSTAT,
                     l_FROM_PRODCODE,
                     l_FROM_CARDTYPE,
                     l_FROMACCT_NO
              FROM   CMS_APPL_PAN
              WHERE  CAp_inst_code= p_inst_code_in
              AND    CAP_PAN_CODE  = l_HASH_PAN_FROM;

         EXCEPTION WHEN OTHERS THEN
            null;

         END;

     end if;


     if l_DR_CR_FLAG is null
     then

        BEGIN

             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO l_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = p_txn_code_in
              AND   CTM_DELIVERY_CHANNEL = p_del_channel_in
              AND   CTM_INST_CODE = p_inst_code_in;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;


     BEGIN
       INSERT INTO TRANSACTIONLOG
        (MSGTYPE,
         RRN,
         DELIVERY_CHANNEL,
         TERMINAL_ID,
         DATE_TIME,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         TXN_STATUS,
         RESPONSE_CODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOPUP_CARD_NO,
         TOPUP_ACCT_NO,
         TOPUP_ACCT_TYPE,
         BANK_CODE,
         TOTAL_AMOUNT,
         CURRENCYCODE,
         ADDCHARGE,
         PRODUCTID,
         CATEGORYID,
         ATM_NAME_LOCATION,
         AUTH_ID,
         AMOUNT,
         PREAUTHAMOUNT,
         PARTIALAMOUNT,
         INSTCODE,
         CUSTOMER_CARD_NO_ENCR,
         TOPUP_CARD_NO_ENCR,
         PROXY_NUMBER,
         REVERSAL_CODE,
         CUSTOMER_ACCT_NO,
         ACCT_BALANCE,
         LEDGER_BALANCE,
         RESPONSE_ID,
         ANI,
         DNI,
         IPADDRESS,
         CARDSTATUS,
         TRANS_DESC,
         ERROR_MSG,
         topup_acct_balance ,
         topup_ledger_balance,
         ACCT_TYPE,
         TIME_STAMP,
         CR_DR_FLAG,
       REMARK,
       uuid,
      os_name,
      os_version,
      gps_coordinates,
      display_resolution,
      physical_memory,
      app_name,
      app_version,
      session_id,
      device_country,
      device_region,
      ip_country,
      proxy_flag,
      REQ_PARTNER_ID
         )
       VALUES
        ('0200',
         p_rrn_in,
         p_del_channel_in,
         0,
         TO_DATE(p_business_date_in, 'YYYY/MM/DD'),
         p_txn_code_in,
         l_TXN_TYPE,
         0,
         DECODE(p_resp_code_out, '00', 'C', 'F'),
         p_resp_code_out,
         p_business_date_in,
         SUBSTR(p_business_time_in, 1, 10),
         l_HASH_PAN_FROM,
          l_HASH_PAN_TO,
         l_TOACCTNUMBER,
         l_TOACCT_TYPE,
         p_inst_code_in,
         TRIM(TO_CHAR(nvl(L_TXN_AMT,0), '99999999999999990.99')),
         p_curr_code_in,
         NULL,
         l_FROM_PRODCODE,
         l_FROM_CARDTYPE,
         0,
         l_CTOC_AUTH_ID,
         TRIM(TO_CHAR(nvl(L_TXN_AMT,0), '99999999999999990.99')),
         '0.00',
         '0.00',
         p_inst_code_in,
         l_ENCR_PAN_FROM,
         l_ENCR_PAN_TO,
         '',
         0,
         l_ACCT_NUMBER,
         nvl(l_ACCT_BALANCE,0),
         nvl(l_LEDGER_BALANCE,0),
         l_RESP_CDE,
         p_ani_in,
         p_dni_in,
         p_ip_addr_in,
         l_FROMCARDSTAT,
         l_TRANS_DESC,
         l_ERR_MSG,
         nvl(l_TOACCT_BAL,0),
         nvl(l_TOLEDGER_BAL,0),
         l_FRMACCT_TYPE,
         l_TIME_STAMP,
         l_DR_CR_FLAG,
       'From Account No : ' || FN_MASK_ACCT(l_FROMACCT_NO) || ' ' ||
         'To Account No : ' || FN_MASK_ACCT(l_TOACCTNUMBER),
         p_uuid_in,
        p_osname_in,
        p_osversion_in,
        p_gpscoordinates_in,
        p_displayresolution_in,
        p_physicalmemory_in,
        p_appname_in,
        p_appversion_in,
        p_sessionid_in,
        p_devicecountry_in,
        p_deviceregion_in,
        p_ipcountry_in,
        p_proxy_in,
        p_partner_id_in
         );

     EXCEPTION
       WHEN OTHERS THEN

        p_resp_code_out := '89';
        p_resp_msg_out  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
            RETURN;
     END;
    END IF;


END CARD_TO_CARD_TRANSFER;

Procedure      activate_card_reversal ( p_inst_code_in            IN       NUMBER,
                                       p_delivery_chnl_in        IN       VARCHAR2,
                                       p_txn_code_in             IN       VARCHAR2,
                                       p_rrn_in                  IN       VARCHAR2,
                                       p_cust_id_in              IN       NUMBER,
                                       p_partner_id_in           IN       VARCHAR2,
                                       p_tran_date_in            IN       VARCHAR2,
                                       p_tran_time_in            IN       VARCHAR2,
                                       p_curr_code_in            IN       VARCHAR2,
                                       p_revrsl_code_in          IN       VARCHAR2,
                                       p_msg_type_in             IN       VARCHAR2,
                                       p_ip_addr_in              IN       VARCHAR2,
                                       p_ani_in                  IN       VARCHAR2,
                                       p_dni_in                  IN       VARCHAR2,
                                       p_device_mobno_in         IN       VARCHAR2,
                                       p_device_id_in            IN       VARCHAR2,
                                       p_uuid_in                 IN       VARCHAR2,
                                       p_osname_in               IN       VARCHAR2,
                                       p_osversion_in            IN       VARCHAR2,
                                       p_gps_coordinates_in      IN       VARCHAR2,
                                       p_display_resolution_in   IN       VARCHAR2,
                                       p_physical_memory_in      IN       VARCHAR2,
                                       p_appname_in              IN       VARCHAR2,
                                       p_appversion_in           IN       VARCHAR2,
                                       p_sessionid_in            IN       VARCHAR2,
                                       p_device_country_in       IN       VARCHAR2,
                                       p_device_region_in        IN       VARCHAR2,
                                       p_ipcountry_in            IN       VARCHAR2,
                                       p_proxy_flag_in           IN       VARCHAR2,
                                       p_pan_code_in             IN       VARCHAR2,
                                       p_tran_mode_in            IN       VARCHAR2,
									                     p_orgirrn_in             IN       VARCHAR2,
                                       p_resp_code_out           OUT      VARCHAR2,
                                       p_resp_msg_out            OUT      VARCHAR2 )
AS
   l_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
   l_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
   l_acct_no           cms_appl_pan.cap_acct_no%TYPE;
   l_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
   l_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   l_prod_code         cms_appl_pan.cap_prod_code%TYPE;
   l_prod_cattype      cms_appl_pan.cap_card_type%TYPE;
   l_card_stat         cms_appl_pan.cap_card_stat%TYPE;
   l_expry_date        cms_appl_pan.cap_expry_date%TYPE;
   l_active_date       cms_appl_pan.cap_active_date%TYPE;
   l_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
   l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
   l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_comb_hash         pkg_limits_check.type_hash;
   l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
   l_timestamp         TIMESTAMP;
   l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
   l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
   l_acct_type         cms_acct_mast.cam_type_code%TYPE;
   l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
   l_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
   l_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
   l_feeattach_type    transactionlog.feeattachtype%TYPE;
   l_tranfee_amt       transactionlog.tranfee_amt%TYPE;
   l_total_amt         cms_acct_mast.cam_acct_bal%TYPE;
   l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
   l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
   l_errmsg            VARCHAR2 (500);
   l_appl_code         cms_appl_pan.cap_appl_code%TYPE;
   l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   l_kyc_flag          cms_caf_info_entry.cci_kyc_flag%TYPE;
   L_User_Name         Cms_Cust_Mast.Ccm_User_Name%Type;
     L_Cap_Prod_Catg     Cms_Appl_Pan.Cap_Prod_Catg%Type;
     L_Firsttime_Topup   Cms_Appl_Pan.Cap_Firsttime_Topup%Type;
   L_Mbrnumb           Cms_Appl_Pan.Cap_Mbr_Numb%Type;
     L_Inst_Code         Cms_Appl_Pan.Cap_Inst_Code%Type;
   L_Profile_Level     Cms_Appl_Pan.Cap_Prfl_Levl%Type;
   L_Starter_Card_Flag Cms_Appl_Pan.Cap_Startercard_Flag%Type;
     L_Card_Activation_Code Cms_Appl_Pan.Cap_Activation_Code%Type;
   L_Oldcrd             Cms_Htlst_Reisu.Chr_Pan_Code%Type;
   L_Oldcrd_Encr        Cms_Appl_Pan.Cap_Pan_Code_Encr%Type;
   l_ssn                cms_cust_mast.ccm_ssn%TYPE;
   l_FLDOB_HASHKEY_ID   CMS_CUST_MAST.CCM_FLNAMEDOB_HASHKEY%TYPE;
   l_chkcurr            cms_bin_param.cbp_param_value%TYPE;
   l_inil_authid        transactionlog.auth_id%TYPE;
   l_starter_card       cms_appl_pan.cap_pan_code%TYPE;
   l_starter_card_encr  cms_appl_pan.cap_pan_code_encr%TYPE;
   l_dup_check          NUMBER (3);
   l_crdstat_chnge      VARCHAR2(2):='N';
   l_resoncode          cms_spprt_reasons.csr_spprt_rsncode%type;
   l_exp_date           VARCHAR2 (10);
   l_srv_code           VARCHAR2 (5);
   L_Remrk              Varchar2 (100);
   L_Oldcardstat       Cms_Appl_Pan.Cap_Card_Stat%Type;
   l_ssn_crddtls         VARCHAR2 (400);
   l_closed_card        varchar2(20);
   Exp_Reject_Record   Exception;
   l_b2bcard_status     CMS_PROD_CATTYPE.cpC_b2bcard_stat%type;
   L_RENEWAL_CARD_HASH   cms_appl_pan.cap_pan_code%TYPE;
   L_RENEWAL_CARD_ENCR   cms_appl_pan.CAP_PAN_CODE_ENCR%TYPE;
   L_oldcrd_clear     varchar2(30);
   l_prod_type       cms_product_param.cpp_product_type%type;
   l_user_type      CMS_PROD_CATTYPE.CPC_USER_IDENTIFY_TYPE%type;
   l_req_card_stat   cms_appl_pan.CAP_CARD_STAT%type;
   l_old_cardstat  cms_appl_pan.cap_old_cardstat%type;
    L_oldcard_status  cms_appl_pan.cap_old_cardstat%type;
  l_ORGNL_DELIVERY_CHANNEL   TRANSACTIONLOG.DELIVERY_CHANNEL%TYPE;
  l_ORGNL_RESP_CODE          TRANSACTIONLOG.RESPONSE_CODE%TYPE;
  l_ORGNL_TERMINAL_ID        TRANSACTIONLOG.TERMINAL_ID%TYPE;
  l_ORGNL_TXN_CODE           TRANSACTIONLOG.TXN_CODE%TYPE;
  l_ORGNL_TXN_TYPE           TRANSACTIONLOG.TXN_TYPE%TYPE;
  l_ORGNL_TXN_MODE           TRANSACTIONLOG.TXN_MODE%TYPE;
  l_ORGNL_BUSINESS_DATE      TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  l_ORGNL_BUSINESS_TIME      TRANSACTIONLOG.BUSINESS_TIME%TYPE;
  l_ORGNL_CUSTOMER_CARD_NO   TRANSACTIONLOG.CUSTOMER_CARD_NO%TYPE;
  l_ORGNL_TOTAL_AMOUNT       TRANSACTIONLOG.AMOUNT%TYPE;
  l_ORGNL_TXN_FEECODE        CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  l_ORGNL_TXN_FEEATTACHTYPE  TRANSACTIONLOG.FEEATTACHTYPE%TYPE;
  l_ORGNL_TXN_TOTALFEE_AMT   TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  l_ORGNL_TXN_SERVICETAX_AMT TRANSACTIONLOG.SERVICETAX_AMT%TYPE;
  l_ORGNL_TXN_CESS_AMT       TRANSACTIONLOG.CESS_AMT%TYPE;
  l_ORGNL_TRANSACTION_TYPE   TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  l_ACTUAL_DISPATCHED_AMT    TRANSACTIONLOG.AMOUNT%TYPE;
  l_ORGNL_TRANDATE           DATE;
   l_ORGNL_TERMID             TRANSACTIONLOG.TERMINAL_ID%TYPE;
  l_ORGNL_MCCCODE            TRANSACTIONLOG.MCCODE%TYPE;
   l_ORGNL_TRANFEE_AMT        TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  l_ORGNL_SERVICETAX_AMT     TRANSACTIONLOG.SERVICETAX_AMT%TYPE;
  l_ORGNL_CESS_AMT           TRANSACTIONLOG.CESS_AMT%TYPE;
  l_ORGNL_CR_DR_FLAG         TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  l_ORGNL_TRANFEE_CR_ACCTNO  TRANSACTIONLOG.TRANFEE_CR_ACCTNO%TYPE;
  l_ORGNL_TRANFEE_DR_ACCTNO  TRANSACTIONLOG.TRANFEE_DR_ACCTNO%TYPE;
  l_ORGNL_ST_CALC_FLAG       TRANSACTIONLOG.TRAN_ST_CALC_FLAG%TYPE;
  l_ORGNL_CESS_CALC_FLAG     TRANSACTIONLOG.TRAN_CESS_CALC_FLAG%TYPE;
  l_ORGNL_ST_CR_ACCTNO       TRANSACTIONLOG.TRAN_ST_CR_ACCTNO%TYPE;
  l_ORGNL_ST_DR_ACCTNO       TRANSACTIONLOG.TRAN_ST_DR_ACCTNO%TYPE;
  l_ORGNL_CESS_CR_ACCTNO     TRANSACTIONLOG.TRAN_CESS_CR_ACCTNO%TYPE;
  l_ORGNL_CESS_DR_ACCTNO     TRANSACTIONLOG.TRAN_CESS_DR_ACCTNO%TYPE;
  l_ORGNL_TXN_FEE_PLAN     TRANSACTIONLOG.FEE_PLAN%TYPE;
  l_ACTUAL_FEECODE           TRANSACTIONLOG.FEECODE%TYPE;
   l_CURR_CODE                TRANSACTIONLOG.CURRENCYCODE%TYPE;
   L_TRAN_REVERSE_FLAG        TRANSACTIONLOG.TRAN_REVERSE_FLAG%TYPE;
    l_GL_UPD_FLAG              TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
    L_ORGNL_TXN_AMNT     TRANSACTIONLOG.AMOUNT%TYPE;
    l_pos_verification transactionlog.pos_verification%type;
    l_internation_ind_response transactionlog.internation_ind_response %type;
    l_add_ins_date          transactionlog.add_ins_date %type;
   l_cust_acct_no      cms_acct_mast.cam_acct_no%TYPE;
  l_topup_card_no     transactionlog.topup_card_no%TYPE;
  l_topup_acct_no     transactionlog.topup_acct_no%TYPE;
  l_topup_acct_type     transactionlog.topup_acct_type%TYPE;
  l_TOPUP_CARD_NO_ENCR   TRANSACTIONLOG.TOPUP_CARD_NO_ENCR%TYPE;

  l_TXN_NARRATION  CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%type;
  --L_FEEATTACH_TYPE     VARCHAR2(2);
  L_FEE_AMT   NUMBER;
  --L_FEE_PLAN  CMS_FEE_PLAN.CFP_PLAN_ID%TYPE;
  --L_TXN_TYPE  NUMBER(1);
  l_RVSL_TRANDATE date;
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
  BEGIN
         p_resp_code_out := '00';
         p_resp_msg_out := 'success';
		     l_REMRK    := 'Card Activation-reversal';
         l_errmsg :='OK';

         DBMS_OUTPUT.PUT_LINE('Card Activation-reversal 11111');
      BEGIN
         vmscommon.get_transaction_details (p_inst_code_in,
                                            p_delivery_chnl_in,
                                            p_txn_code_in,
                                            l_cr_dr_flag,
                                            l_txn_type,
                                            l_txn_desc,
                                            l_prfl_flag,
                                            l_preauth_flag,
                                            l_login_txn,
                                            l_preauth_type,
                                            l_dup_rrn_check,
                                            p_resp_code_out,
                                            l_errmsg
                                           );

        IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
          THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error from Transaction Details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
 DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -01');
      BEGIN
         SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no, cap_card_stat,
                cap_prod_code, cap_card_type, cap_expry_date,
                Cap_Active_Date, Cap_Prfl_Code, Cap_Proxy_Number,
                Cap_Appl_Code, Cap_Cust_Code,
                Cap_Prod_Catg,Cap_Firsttime_Topup,
                Cap_Prfl_Levl,Cap_Startercard_Flag,Cap_Mbr_Numb,cap_old_cardstat
           INTO l_hash_pan, l_encr_pan, l_acct_no, l_card_stat,
                L_Prod_Code, L_Prod_Cattype, L_Expry_Date,
                L_Active_Date, L_Prfl_Code, L_Proxynumber,
                l_appl_code, l_cust_code,l_cap_prod_catg,
                l_Firsttime_Topup,
                l_Profile_Level,l_Starter_Card_Flag,L_Mbrnumb,l_old_cardstat
                 FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            And Cap_Mbr_Numb = '000';
            DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -02   '||p_pan_code_in||' l_hash_pan '||l_hash_pan);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting CMS_APPL_PAN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;


	   BEGIN
       SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO L_AUTH_ID FROM DUAL;

     EXCEPTION
       WHEN OTHERS THEN
     L_ERRMSG   := 'Error while generating authid ' ||
                SUBSTR(SQLERRM, 1, 300);
     p_resp_code_out := '21';
     RAISE exp_reject_record;
  END;
  DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -03 l_dup_rrn_check'||l_dup_rrn_check);
   IF l_dup_rrn_check = 'Y' THEN
      BEGIN
         vmscommon.validate_date_rrn (p_inst_code_in,
                                      p_rrn_in,
                                      p_tran_date_in,
                                      p_tran_time_in,
                                      p_delivery_chnl_in,
                                      l_errmsg,
                                      p_resp_code_out
                                     );
dbms_output.put_line( 'p_rrn_in ' || l_errmsg);
         IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '22';
            l_errmsg :=
                  'Error while validating DATE AND RRN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      END IF;

    begin
   SELECT DELIVERY_CHANNEL,
         TERMINAL_ID,
         RESPONSE_CODE,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOTAL_AMOUNT,
         FEE_PLAN,
         FEECODE,
         FEEATTACHTYPE,
         TRANFEE_AMT,
         SERVICETAX_AMT,
         CESS_AMT,
         CR_DR_FLAG,
         TERMINAL_ID,
         MCCODE,
         FEECODE,
         TRANFEE_AMT,
         SERVICETAX_AMT,
         CESS_AMT,
         TRANFEE_CR_ACCTNO,
         TRANFEE_DR_ACCTNO,
         TRAN_ST_CALC_FLAG,
         TRAN_CESS_CALC_FLAG,
         TRAN_ST_CR_ACCTNO,
         TRAN_ST_DR_ACCTNO,
         TRAN_CESS_CR_ACCTNO,
         TRAN_CESS_DR_ACCTNO,
         CURRENCYCODE,
         TRAN_REVERSE_FLAG,
         GL_UPD_FLAG,
         AMOUNT,
         pos_verification,
         internation_ind_response,
         add_ins_date ,
         customer_acct_no,
         topup_card_no  ,
         Topup_Acct_No  ,
         Topup_Acct_Type,
         TOPUP_CARD_NO_ENCR
          INTO l_ORGNL_DELIVERY_CHANNEL,
         l_ORGNL_TERMINAL_ID,
         l_ORGNL_RESP_CODE,
         l_ORGNL_TXN_CODE,
         l_ORGNL_TXN_TYPE,
         l_ORGNL_TXN_MODE,
         l_ORGNL_BUSINESS_DATE,
         l_ORGNL_BUSINESS_TIME,
         l_ORGNL_CUSTOMER_CARD_NO,
         l_ORGNL_TOTAL_AMOUNT,
         l_ORGNL_TXN_FEE_PLAN,
         l_ORGNL_TXN_FEECODE,
         l_ORGNL_TXN_FEEATTACHTYPE,
         l_ORGNL_TXN_TOTALFEE_AMT,
         l_ORGNL_TXN_SERVICETAX_AMT,
         l_ORGNL_TXN_CESS_AMT,
         l_ORGNL_TRANSACTION_TYPE,
         l_ORGNL_TERMID,
         l_ORGNL_MCCCODE,
         l_ACTUAL_FEECODE,
         l_ORGNL_TRANFEE_AMT,
         l_ORGNL_SERVICETAX_AMT,
         l_ORGNL_CESS_AMT,
         l_ORGNL_TRANFEE_CR_ACCTNO,
         l_ORGNL_TRANFEE_DR_ACCTNO,
         l_ORGNL_ST_CALC_FLAG,
         l_ORGNL_CESS_CALC_FLAG,
         l_ORGNL_ST_CR_ACCTNO,
         l_ORGNL_ST_DR_ACCTNO,
         l_ORGNL_CESS_CR_ACCTNO,
         l_ORGNL_CESS_DR_ACCTNO,
         l_CURR_CODE,
         l_TRAN_REVERSE_FLAG,
         l_GL_UPD_FLAG,
         l_ORGNL_TXN_AMNT,
         l_pos_verification,
         l_internation_ind_response,
         l_add_ins_date ,
         l_cust_acct_no,
         l_topup_card_no ,
         l_Topup_Acct_No ,
         l_topup_acct_type,
         l_TOPUP_CARD_NO_ENCR
           FROM VMSCMS.TRANSACTIONLOG_VW                    --Added for VMS-5735/FSP-991
    WHERE RRN = p_orgirrn_in
         AND CUSTOMER_CARD_NO = l_HASH_PAN
         AND DELIVERY_CHANNEL = p_delivery_chnl_in
         AND INSTCODE = P_INST_CODE_in AND RESPONSE_CODE = '00';
   DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -04 l_ORGNL_RESP_CODE'||l_ORGNL_RESP_CODE);
    IF l_ORGNL_RESP_CODE <> '00' THEN
     p_resp_code_out := '23';
     L_ERRMSG   := ' The original transaction was not successful';
     RAISE Exp_Reject_Record;
    END IF;
    IF l_TRAN_REVERSE_FLAG = 'Y' THEN
     p_resp_code_out := '52';
     L_ERRMSG   := 'The reversal already done for the orginal transaction';
     RAISE Exp_Reject_Record;
    END IF;

    Exception
    WHEN Exp_Reject_Record THEN
     Raise;
    WHEN NO_DATA_FOUND THEN
     p_resp_code_out := '53';
     L_ERRMSG   := 'Matching transaction not found';
     RAISE Exp_Reject_Record;
    WHEN TOO_MANY_ROWS THEN
     p_resp_code_out := '21';
     L_ERRMSG   := 'More than one matching record found in the master';
     RAISE Exp_Reject_Record;
    WHEN OTHERS THEN
     p_resp_code_out := '21';
     L_ERRMSG   := 'Error while selecting master data' ||
                SUBSTR(SQLERRM, 1, 300);
     RAISE Exp_Reject_Record;
   end;

  BEGIN
  
  
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
  
   SELECT CSL_TRANS_NARRRATION
         INTO l_TXN_NARRATION
         FROM VMSCMS.CMS_STATEMENTS_LOG                              --Added for VMS-5735/FSP-991
     WHERE CSL_BUSINESS_DATE = l_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = l_ORGNL_BUSINESS_TIME AND
         CSL_RRN = p_orgirrn_in AND
         CSL_DELIVERY_CHANNEL = l_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = l_ORGNL_TXN_CODE AND
         CSL_PAN_NO = l_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE_in  AND TXN_FEE_FLAG = 'Y'
        and rownum=1;
	ELSE
	 
   SELECT CSL_TRANS_NARRRATION
         INTO l_TXN_NARRATION
         FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
     WHERE CSL_BUSINESS_DATE = l_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = l_ORGNL_BUSINESS_TIME AND
         CSL_RRN = p_orgirrn_in AND
         CSL_DELIVERY_CHANNEL = l_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = l_ORGNL_TXN_CODE AND
         CSL_PAN_NO = l_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE_in  AND TXN_FEE_FLAG = 'Y'
        and rownum=1;
END IF;	
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
     l_TXN_NARRATION := NULL;
     WHEN OTHERS THEN
     l_TXN_NARRATION := NULL;
  END;
   DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -05 l_TXN_NARRATION'||l_TXN_NARRATION);
  begin

   l_RVSL_TRANDATE  := TO_DATE(SUBSTR(TRIM(p_tran_date_in), 1, 8) || ' ' ||SUBSTR(TRIM(p_tran_time_in), 1, 8),'yyyymmdd hh24:mi:ss');
  EXCEPTION
     WHEN OTHERS THEN
    p_resp_code_out := '21';
     L_ERRMSG   := 'Error while converting transaction date ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE Exp_Reject_Record;

  end;

  DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -06 l_ORGNL_TXN_TOTALFEE_AMT'||l_ORGNL_TXN_TOTALFEE_AMT);
  if l_ORGNL_TXN_TOTALFEE_AMT>0 then

  BEGIN
        SP_REVERSE_FEE_AMOUNT(P_INST_CODE_in,
                          p_rrn_in,
                          p_delivery_chnl_in,
                          L_ORGNL_TERMINAL_ID,
                          null,--P_MERC_ID,
                          L_ORGNL_TXN_CODE,
                          l_RVSL_TRANDATE,
                          p_tran_mode_in,
                          l_ORGNL_TRANFEE_AMT,
                          p_pan_code_in,
                          l_ACTUAL_FEECODE,
                          l_ORGNL_TRANFEE_AMT,
                          l_ORGNL_TRANFEE_CR_ACCTNO,
                          l_ORGNL_TRANFEE_DR_ACCTNO,
                          l_ORGNL_ST_CALC_FLAG,
                          l_ORGNL_SERVICETAX_AMT,
                          l_ORGNL_ST_CR_ACCTNO,
                          l_ORGNL_ST_DR_ACCTNO,
                          l_ORGNL_CESS_CALC_FLAG,
                          l_ORGNL_CESS_AMT,
                          l_ORGNL_CESS_CR_ACCTNO,
                          l_ORGNL_CESS_DR_ACCTNO,
                          p_orgirrn_in,
                          l_acct_no,
                          p_tran_date_in,
                          p_tran_time_in,
                          l_AUTH_ID,
                          l_TXN_NARRATION,
                          null,--P_MERCHANT_NAME,
                          null,--P_MERCHANT_CITY,
                          null,--P_MERCHANT_STATE,
                          p_resp_code_out,
                          l_ERRMSG);

       -- l_FEE_NARRATION := C1.CSL_TRANS_NARRRATION;

        IF p_resp_code_out <> '00' OR L_ERRMSG <> 'OK' THEN
          RAISE Exp_Reject_Record;
        END IF;
DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -07 p_resp_code_out'||p_resp_code_out);
DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -08 l_acct_no'||l_acct_no);
       EXCEPTION
        WHEN Exp_Reject_Record THEN
          RAISE;

        WHEN OTHERS THEN
          p_resp_code_out := '21';
          L_ERRMSG   := 'Error while reversing the fee amount ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE Exp_Reject_Record;
       END;

BEGIN
    SP_TRAN_REVERSAL_FEES(P_INST_CODE_in,
                     p_pan_code_in,
                     p_delivery_chnl_in,
                     l_ORGNL_TXN_MODE,
                     p_txn_code_in,
                     p_curr_code_in,
                     NULL,
                     NULL,
                     '0',--l_REVERSAL_AMT,
                     p_tran_date_in,
                     p_tran_time_in,
                     l_internation_ind_response,
                     l_pos_verification,
                     p_resp_code_out,
                     p_msg_type_in,
                     '000',--P_MBR_NUMB,
                     P_RRN_in,
                     null,--P_TERMINAL_ID,
                     null,--P_MERCHANT_NAME,
                     null,--P_MERCHANT_CITY,
                     l_AUTH_ID,
                     null,--P_MERCHANT_STATE,
                     p_revrsl_code_in,
                     l_TXN_NARRATION,
                     l_TXN_TYPE,
                     l_RVSL_TRANDATE,
                     l_ERRMSG,
                     p_resp_code_out,
                     l_FEE_AMT,
                     l_FEE_PLAN,
                     l_FEE_CODE,
                     l_FEEATTACH_TYPE
                     );

        IF l_ERRMSG <> 'OK' THEN
         RAISE Exp_Reject_Record;
        END IF;

        DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -09 l_ERRMSG'||l_ERRMSG);
      END;
     end if;
 if  l_Starter_Card_Flag='N' THEN

	 begin

      select cap_old_cardstat,cap_pan_code,cap_pan_code_encr,fn_dmaps_main(cap_pan_code_encr)
       INTO  L_oldcard_status,l_oldcrd,l_oldcrd_encr,l_oldcrd_clear
       from cms_appl_pan
       where cap_inst_code=p_inst_code_in
       and cap_pan_code <>l_hash_pan
       and cap_acct_no=l_acct_no
       and cap_startercard_flag='Y'
      and to_char(cap_lupd_date,'YYYYMMDD')=p_tran_date_in;

     exception
      WHEN NO_DATA_FOUND   THEN
                begin
       select cap_old_cardstat,cap_pan_code,cap_pan_code_encr,fn_dmaps_main(cap_pan_code_encr)
       INTO  L_oldcard_status,l_oldcrd,l_oldcrd_encr,l_oldcrd_clear
       from cms_appl_pan
       where cap_inst_code=p_inst_code_in
       and cap_pan_code <>l_hash_pan
       and cap_startercard_flag='N'
       and cap_acct_no=l_acct_no
       and to_char(cap_lupd_date,'YYYYMMDD')=p_tran_date_in;
       exception when NO_DATA_FOUND   THEN
        null;
       WHEN OTHERS   THEN
         p_resp_code_out := '21';
         l_errmsg := 'Error while selecting  GPR card details '||l_hash_pan||' :: '|| SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
       end;
        when exp_reject_record then
      raise;
      WHEN OTHERS   THEN
         p_resp_code_out := '21';
         l_errmsg := 'Error while selecting  card details '|| SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;

   end;
   if l_oldcrd is not null and L_oldcard_status<>2 then
--   BEGIN
--     select cap_old_cardstat
--      INTO L_oldcard_status
--     FROM CMS_APPL_PAN
--    WHERE CAP_INST_CODE = p_inst_code_in and cap_pan_code=l_oldcrd
--	  And Cap_Mbr_Numb = '000';
--  EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--    NULL;
--    WHEN OTHERS THEN
--      p_resp_code_out:='21';
--     l_errmsg := 'Error while selecting Starter Card number for Account No ' || l_oldcrd;
--     RAISE exp_reject_record;
--  END;
  DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -10 l_oldcrd  '|| l_oldcrd);
   begin
   update cms_appl_pan set cap_card_stat=l_old_cardstat
              where cap_inst_code = p_inst_code_in
            AND cap_pan_code =l_oldcrd
            And Cap_Mbr_Numb = '000';

			   IF SQL%ROWCOUNT = 0 THEN
             p_resp_code_out := '21';
              l_errmsg   := 'Card Status reversal not happend for old card '|| l_oldcrd;
          RAISE exp_reject_record;
           END IF;

   EXCEPTION
       WHEN exp_reject_record THEN
        RAISE ;
         WHEN OTHERS THEN
          p_resp_code_out := '21';
          l_errmsg   := 'Error while updating card status for old card ' || SUBSTR(SQLERRM, 1, 200);
          RAISE exp_reject_record;

   end;
end if ;
 END IF;

 begin
   update cms_appl_pan set cap_card_stat=l_old_cardstat,
              -- cap_old_cardstat=0,
               CAP_ACTIVE_DATE=null,
               CAP_FIRSTTIME_TOPUP = 'N',
               cap_prfl_code = null,
               cap_prfl_levl = null
    where cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            And Cap_Mbr_Numb = '000';

			 IF SQL%ROWCOUNT = 0 THEN
             p_resp_code_out := '21';
              l_errmsg   := 'Card Status reversal not happend '|| l_hash_pan;
          RAISE exp_reject_record;
           END IF;

   EXCEPTION
       WHEN exp_reject_record THEN
        RAISE ;
         WHEN OTHERS THEN
          p_resp_code_out := '21';
          l_errmsg   := 'Error while updating card status ' || SUBSTR(SQLERRM, 1, 200);
          RAISE exp_reject_record;

   end;

   begin
   

	
     update VMSCMS.TRANSACTIONLOG set TRAN_REVERSE_FLAG='Y'             --Added for VMS-5735/FSP-991
     WHERE   RRN = p_orgirrn_in
         AND CUSTOMER_CARD_NO = l_HASH_PAN
         AND DELIVERY_CHANNEL = p_delivery_chnl_in
         AND INSTCODE = P_INST_CODE_in AND RESPONSE_CODE = '00';
		 
		   IF SQL%ROWCOUNT = 0 THEN
		     update VMSCMS_HISTORY.TRANSACTIONLOG_HIST set TRAN_REVERSE_FLAG='Y'             --Added for VMS-5735/FSP-991
     WHERE   RRN = p_orgirrn_in
         AND CUSTOMER_CARD_NO = l_HASH_PAN
         AND DELIVERY_CHANNEL = p_delivery_chnl_in
         AND INSTCODE = P_INST_CODE_in AND RESPONSE_CODE = '00';
		   END IF;

      IF SQL%ROWCOUNT = 0 THEN
             p_resp_code_out := '21';
              l_errmsg   := 'Reversal flag updation failed '|| l_oldcrd;
          RAISE exp_reject_record;
           END IF;

   end;

EXCEPTION                     --Main exception
      When Exp_Reject_Record
      Then
      P_Resp_Msg_Out := L_Errmsg;

         Rollback;

      WHEN OTHERS
      THEN
         ROLLBACK;
         P_Resp_Msg_Out := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
  end;
    BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code_in
            AND cms_delivery_channel = p_delivery_chnl_in
            AND cms_response_id = TO_NUMBER (p_resp_code_out);
      EXCEPTION
         WHEN OTHERS
         THEN
            P_Resp_Msg_Out :=
                  'Error while selecting respose code'
               || p_resp_code_out
               || ' is-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
      END;
  l_timestamp := SYSTIMESTAMP;
   BEGIN
      l_hashkey_id :=
         gethash (   p_delivery_chnl_in
                  || p_txn_code_in
                  || p_pan_code_in
                  || p_rrn_in
                  || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         P_Resp_Msg_Out :=
            'Error while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
   END;

   DBMS_OUTPUT.PUT_LINE('Card Activation-reversal -11 l_acct_no  '|| l_acct_no);

  BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO l_acct_bal, l_ledger_bal, l_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code_in AND CAM_ACCT_NO = l_acct_no;
   EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            P_Resp_Msg_Out := 'Invalid Card number fff ' ||l_acct_no||'p_pan_code_in'||p_pan_code_in;
       WHEN OTHERS
      THEN
         p_resp_code_out := '12';
         p_resp_msg_out :=
                       'ERROR IN account details' || SUBSTR (SQLERRM, 1, 200);
   END;
   BEGIN
      vms_log.log_transactionlog (p_inst_code_in,
                                  p_msg_type_in,
                                  p_rrn_in,
                                  p_delivery_chnl_in,
                                  p_txn_code_in,
                                  l_txn_type,
                                  0,
                                  p_tran_date_in,
                                  p_tran_time_in,
                                  '00',
                                  l_hash_pan,
                                  l_encr_pan,
                                  l_errmsg,
                                  p_ip_addr_in,
                                  l_card_stat,
                                  l_txn_desc,
                                  p_ani_in,
                                  p_dni_in,
                                  l_timestamp,
                                  l_acct_no,
                                  l_prod_code,
                                  l_prod_cattype,
                                  l_cr_dr_flag,
                                  l_acct_bal,
                                  l_ledger_bal,
                                  l_acct_type,
                                  l_proxynumber,
                                  l_auth_id,
                                  0,
                                  l_total_amt,
                                  l_fee_code,
                                  l_tranfee_amt,
                                  l_fee_plan,
                                  l_feeattach_type,
                                  p_resp_code_out,
                                  p_resp_code_out,
                                  p_curr_code_in,
                                  l_hashkey_id,
                                  p_uuid_in,
                                  p_osname_in,
                                  p_osversion_in,
                                  p_gps_coordinates_in,
                                  p_display_resolution_in,
                                  p_physical_memory_in,
                                  p_appname_in,
                                  p_appversion_in,
                                  p_sessionid_in,
                                  p_device_country_in,
                                  p_device_region_in,
                                  p_ipcountry_in,
                                  p_proxy_flag_in,
                                  p_partner_id_in,
                                  l_errmsg
                                 );

      IF l_errmsg <> 'OK'  THEN
         RAISE exp_reject_record;
      END IF;
   EXCEPTION  WHEN exp_reject_record THEN
         p_resp_code_out := '69';
         p_resp_msg_out :=
               p_resp_msg_out
            || ' Error while inserting into transaction log  '
            || l_errmsg;
      WHEN OTHERS THEN
         p_resp_code_out := '69';
         p_resp_msg_out :='Error while inserting into transaction log '|| SUBSTR (SQLERRM, 1, 300);
   End;
  END  activate_card_reversal;

END vms_pan;
 /
show error;