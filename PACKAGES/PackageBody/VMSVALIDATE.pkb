create or replace
PACKAGE BODY              VMSCMS.VMSVALIDATE
IS
   -- Private type declarations

   -- Private constant declarations


   -- Private variable declarations

   -- Function and procedure implementations
   PROCEDURE authenticate (p_inst_code_in             IN    NUMBER,
                           p_delivery_chnl_in         IN    VARCHAR2,
                           p_txn_code_in              IN    VARCHAR2,
                           p_rrn_in                   IN    VARCHAR2,
                           p_cust_id_in               IN    VARCHAR2,
                           p_appl_id_in               IN    VARCHAR2,   
                           p_partner_id_in            IN    VARCHAR2,
                           p_tran_date_in             IN    VARCHAR2,
                           p_tran_time_in             IN    VARCHAR2,
                           p_curr_code_in             IN    VARCHAR2,
                           p_revrsl_code_in           IN    VARCHAR2,
                           p_msg_type_in              IN    VARCHAR2,
                           p_ip_addr_in               IN    VARCHAR2,
                           p_ani_in                   IN    VARCHAR2,
                           p_dni_in                   IN    VARCHAR2,
                           p_device_mobno_in          IN    VARCHAR2,
                           p_device_id_in             IN    VARCHAR2,
                           p_uuid_in                  IN    VARCHAR2,
                           p_osname_in                IN    VARCHAR2,
                           p_osversion_in             IN    VARCHAR2,
                           p_gps_coordinates_in       IN    VARCHAR2,
                           p_display_resolution_in    IN    VARCHAR2,
                           p_physical_memory_in       IN    VARCHAR2,
                           p_appname_in               IN    VARCHAR2,
                           p_appversion_in            IN    VARCHAR2,
                           p_sessionid_in             IN    VARCHAR2,
                           p_device_country_in        IN    VARCHAR2,
                           p_device_region_in         IN    VARCHAR2,
                           p_ipcountry_in             IN    VARCHAR2,
                           p_proxy_flag_in            IN    VARCHAR2,
                           p_pan_code_in              IN    VARCHAR2,
                           p_expry_date_in            IN    VARCHAR2,
                           p_user_name_in             IN    VARCHAR2,
                           p_password_in              IN    VARCHAR2,
                           p_dob_in                   IN    VARCHAR2,
                           p_phone_no_in              IN    VARCHAR2,
                           p_id_numbr_in              IN    VARCHAR2,
                           p_zip_code_in              IN    VARCHAR2,
                           p_resp_code_out            OUT   VARCHAR2,
                           p_resp_msg_out             OUT   VARCHAR2,
                           p_cust_id_out              OUT   NUMBER,
                           p_loginAttempts_Left_out   OUT   VARCHAR2,
                           p_custid_type_out          OUT   VARCHAR2,
                           p_serial_num_out           OUT   VARCHAR2,
                           p_card_stat_out            OUT   VARCHAR2,
                           p_product_upc_out          OUT   VARCHAR2,
                           p_initial_load_amount_out  OUT   VARCHAR2,
						   p_replaced_card_out        OUT   VARCHAR2,
						   p_order_channel_out        OUT   VARCHAR2,
                           p_zip_code_out             OUT   VARCHAR2,
                           p_isAuthorizedDevice_out   OUT   VARCHAR2,
                           p_mobile_deliverymode_out  OUT   VARCHAR2,
                           p_email_deliverymode_out   OUT   VARCHAR2,
                           p_reason_code_out          OUT   VARCHAR2,  --Added for VMS-6617 Changes
                           p_allowredemptions_out     OUT VARCHAR2, --Added for VMS-8677
                           p_transactions_out         OUT   SYS_REFCURSOR)
   AS
   
   /*******************************************************************************
     * Modified by       : Sivakumar M
     * Modified Date     : 18-July-18
     * Modified For      : VMS-423
     * Reviewer          : Saravanakumar A
     * Build Number      : R04_B0001

     * Modified By      : ULAGAN A
     * Modified Date    : 12-AUG-2019
     * Purpose          : VMS 1053 - CSS: Web Alternative login restriction based on configuration.
     * Reviewer         : SaravanaKumar.A
     * Release Number   : VMSGPRHOST_R19

     * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 11-SEP-2019
     * Purpose          : VMS 1091 - Enhance Web login procedure to return info needed for OTP.
     * Reviewer         : SaravanaKumar.A
     * Release Number   : VMSGPRHOST_R20

     * Modified by                 : DHINAKARAN B
     * Modified Date               : 26-NOV-2019
     * Modified For                : VMS-1415
     * Reviewer                    : Saravana Kumar A
     * Build Number                : VMSGPRHOST_R23_B1

     * Modified by                 : Mageshkumar S
     * Modified Date               : 31-July-2020
     * Modified For                : VMS-2858
     * Reviewer                    : Saravana Kumar A
     * Build Number                : VMSGPRHOST_R34_B1

     * Modified by                 : Ubaidur Rahman.H
     * Modified Date               : 15-June-2021
     * Modified For                : VMS- 4624
     * Reviewer                    : Saravana Kumar A
     * Build Number                : VMSGPRHOST_R47_B1

     * Modified By                 : Pankaj S.
     * Modified For                : VMS-6617
     * Purpose                     : Fraud - ONHOLD cardstatus updates - Auth changes
     * Reviewer                    : Venkat S.
     * Release Number              : R70.2

     * Modified By                 : Pankaj S.
     * Modified For                : VMS-8677
     * Purpose                     : Enable Redemptions Upon Successful IVR or CHW Authentication
     * Reviewer                    : Venkat S.
     * Release Number              : R97

************************************************************************************/
      l_hash_pan           cms_appl_pan.cap_pan_code%TYPE; 
      l_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
      l_cust_code          cms_appl_pan.cap_cust_code%TYPE;
      l_proxunumber        cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_number        cms_appl_pan.cap_acct_no%TYPE;
      l_card_stat          cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date         cms_appl_pan.cap_expry_date%TYPE;
      l_replace_expry_date cms_appl_pan.cap_expry_date%TYPE;
      l_firsttime_topup    cms_appl_pan.cap_firsttime_topup%TYPE;
      l_prfl_code          cms_appl_pan.cap_prfl_code%TYPE;
      l_prod_code          cms_appl_pan.cap_prod_code%TYPE;
      l_card_type          cms_appl_pan.cap_card_type%TYPE;
      l_addr_code          cms_appl_pan.cap_bill_addr%TYPE;
      l_cust_id_type       cms_appl_pan.cap_user_identify_type%TYPE;
      l_acct_balance       cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type          cms_acct_mast.cam_type_code%TYPE;
      l_wrng_count         cms_cust_mast.ccm_wrong_logincnt%TYPE;
      l_appl_id            cms_cust_mast.ccm_appl_id%TYPE;
      l_user_name          cms_cust_mast.ccm_user_name%TYPE;
      l_passwrd_hash       cms_cust_mast.ccm_password_hash%TYPE;
      l_trans_desc         cms_transaction_mast.ctm_tran_desc%TYPE;
      l_dr_cr_flag         cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_tran_type          cms_transaction_mast.ctm_tran_type%TYPE;
      l_prfl_flag          cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_preauth_flag       cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_login_txn          cms_transaction_mast.ctm_login_txn%TYPE;
      l_preauth_type       cms_transaction_mast.ctm_preauth_type%TYPE;
      l_fee_code           transactionlog.feecode%TYPE;
      l_fee_plan           transactionlog.fee_plan%TYPE;
      l_feeattach_type     transactionlog.feeattachtype%TYPE;
      l_tranfee_amt        transactionlog.tranfee_amt%TYPE;
      l_total_amt          transactionlog.total_amount%TYPE;
      l_auth_id            transactionlog.auth_id%TYPE;
      l_hashkey_id         cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_comb_hash          pkg_limits_check.type_hash;
      l_tran_amt           cms_acct_mast.cam_acct_bal%TYPE := 0;
      l_idnum_last4digit   VARCHAR2 (5);
      l_active_date        cms_appl_pan.cap_active_date%TYPE;
      l_encrypt_enable     CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
      l_timestamp          TIMESTAMP;
      l_tran_date          DATE;
      l_dob                VARCHAR2 (20);
      l_txn_type           VARCHAR2 (2);
      l_rrn_count          NUMBER;
      l_resp_cde           VARCHAR2 (5);
      l_err_msg            VARCHAR2 (1000);
      l_repl_flag         cms_appl_pan.cap_repl_flag%TYPE;
      exp_reject_record    EXCEPTION;
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
         v_compl_fee varchar2(10);
   v_compl_feetxn_excd varchar2(10);
   v_compl_feecode varchar2(10);
   l_allow_redemption   cms_appl_pan.cap_allow_redemptions%TYPE;  --Added for VMS-8677

      TYPE t_address IS TABLE OF VARCHAR2 (50)
                           INDEX BY VARCHAR2 (50);

      l_paddress           t_address;
      l_maddress           t_address;
      l_otp_count          NUMBER;
   BEGIN
      BEGIN

        p_resp_msg_out:='success';
         --SN : Convert clear card number to hash and encryped format.
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Convert clear card number to hash and encryped format.

         --SN : Get transaction details from master
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_type,
                   ctm_tran_desc,
                   ctm_prfl_flag,
                   ctm_preauth_flag,
                   ctm_login_txn,
                   ctm_preauth_type
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type,
                   l_trans_desc,
                   l_prfl_flag,
                   l_preauth_flag,
                   l_login_txn,
                   l_preauth_type
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_chnl_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting transaction dtls from master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get transaction details from master

         --SN : Get card details
         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_card_stat,
                   cap_proxy_number,
                   cap_acct_no,
                   cap_prfl_code,
                   cap_firsttime_topup,
                   cap_expry_date,
                   cap_cust_code,
                   cap_bill_addr,
                   cap_serial_number,
                   cap_active_date,
                   cap_user_identify_type,
                   nvl(cap_repl_flag,0),
                   CAP_REPLACE_EXPRYDT,
                   cap_panmast_param5,  --Added for VMS-6617 Changes
                   cap_allow_redemptions --Added for VMS-8677 Changes 
              INTO l_prod_code,
                   l_card_type,
                   l_card_stat,
                   l_proxunumber,
                   l_acct_number,
                   l_prfl_code,
                   l_firsttime_topup,
                   l_expry_date,
                   l_cust_code,
                   l_addr_code,
                   p_serial_num_out,
                   l_active_date,
                   l_cust_id_type,
                   l_repl_flag,
                   l_replace_expry_date,
                   p_reason_code_out,   --Added for VMS-6617 Changes
                   l_allow_redemption   --Added for VMS-8677 Changes
              FROM cms_appl_pan
             WHERE     cap_pan_code = l_hash_pan
                   AND cap_mbr_numb = '000'
                   AND cap_inst_code = p_inst_code_in;

         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Problem while selecting card detail-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

           BEGIN
             SELECT  FN_DMAPS_MAIN(CAM_PIN_CODE),FN_DMAPS_MAIN(CAM_MOBL_ONE),FN_DMAPS_MAIN(CAM_EMAIL)
             INTO p_zip_code_out,p_mobile_deliverymode_out,p_email_deliverymode_out     -- Modified for VMS-1091
             FROM CMS_ADDR_MAST
             WHERE CAM_CUST_CODE=l_cust_code
             AND CAM_INST_CODE=p_inst_code_in
             AND CAM_ADDR_FLAG='P';

             if p_zip_code_out='*' then
              p_zip_code_out:=NULL;
             end if;

          EXCEPTION 
           WHEN OTHERS THEN
            l_resp_cde := '89';
               l_err_msg :='Problem while selecting zip code details -'|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
           END;




         --EN : Get card details
--En pan details procedure call
         IF l_card_stat = 0
         THEN
            IF l_active_date IS NULL
            THEN
               p_card_stat_out := 'INACTIVE';
            ELSE
               p_card_stat_out := 'BLOCKED';
            END IF;
         ELSE
            BEGIN
               SELECT ccs_stat_desc
                 INTO p_card_stat_out
                 FROM cms_card_stat
                WHERE ccs_stat_code = l_card_stat;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_resp_cde := '12';
                  l_err_msg :=
                        'Error while selcting card status description'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

         --SN : Transaction date-time check
         BEGIN
            l_tran_date :=
               TO_DATE (SUBSTR (TRIM (p_tran_date_in), 1, 8), 'yyyymmdd');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '45';
               l_err_msg :=
                  'Problem while converting transaction date-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            l_tran_date :=
               TO_DATE (
                     SUBSTR (TRIM (p_tran_date_in), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_tran_time_in), 1, 10),
                  'yyyymmdd hh24:mi:ss');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '32';
               l_err_msg :=
                  'Problem while converting transaction time-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Transaction date-time check

         --SN: Duplicate RRN Check
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_desc,NVL(CTM_RRN_CHECK,'Y')
              INTO l_dr_cr_flag, l_txn_type, l_trans_desc,l_dup_rrn_check
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_chnl_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                  'Error while getting transaction details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         if l_dup_rrn_check='Y' then
         BEGIN
            SELECT COUNT (1)
              INTO l_rrn_count
              FROM transactionlog
             WHERE     rrn = p_rrn_in
                   AND business_date = p_tran_date_in
                   AND instcode = p_inst_code_in
                   AND delivery_channel = p_delivery_chnl_in;

            IF l_rrn_count > 0
            THEN
               l_resp_cde := '22';
               l_err_msg := 'Duplicate RRN on ' || p_tran_date_in;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Problem while selecting TRANSACTIONLOG '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
        end if;

         --EN: Duplicate RRN Check

          --SN : Get customer detls
         BEGIN	 
            SELECT NVL (ccm_wrong_logincnt, '0'),
                   TO_CHAR (ccm_birth_date, 'MM/YYYY'),
                   upper(fn_dmaps_main(ccm_user_name)),
                   ccm_password_hash,
                   ccm_appl_id,
                   ccm_cust_id,
                   SUBSTR (ccm_ssn, -4)
              INTO l_wrng_count,
                   l_dob,
                   l_user_name,
                   l_passwrd_hash,
                   l_appl_id,
                   p_cust_id_out,
                   l_idnum_last4digit
              FROM cms_cust_mast
             WHERE ccm_cust_code = l_cust_code
                   AND ccm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                  'Error while getting customer details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get customer detls

	 BEGIN
            SELECT DECODE (NVL(l_cust_id_type,cpc_user_identify_type),
                           1, 'Anonymous Gift',
                           2, 'Personalized',
                           3, 'KYC-Verified',
			   4, 'Personalized Gift'),
                   NVL(cpc_wrong_logoncount,'0') - l_wrng_count,CPC_PRODUCT_UPC,cpc_encrypt_enable
              INTO p_custid_type_out, p_loginAttempts_Left_out,p_product_upc_out, l_encrypt_enable
              FROM cms_prod_cattype
             WHERE     cpc_inst_code = p_inst_code_in
                   AND cpc_prod_code = l_prod_code
                   AND cpc_card_type = l_card_type;

         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                  'Error while getting prod_catg dtls-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;



         IF NVL (p_dob_in, l_dob) <> l_dob
         THEN
            l_resp_cde := '49';
            l_err_msg := 'Invalid Birth Date';
            RAISE exp_reject_record;
         END IF;

         IF NVL (p_id_numbr_in, l_idnum_last4digit) <> l_idnum_last4digit
         THEN
            l_resp_cde := '195';
            l_err_msg := 'Invalid ID Number';
            RAISE exp_reject_record;
         END IF;

         IF NVL (p_appl_id_in, l_appl_id) <> l_appl_id
         THEN
            l_resp_cde := '49';
            l_err_msg := 'Invalid Source App ID';
            RAISE exp_reject_record;
         END IF;

         IF p_expry_date_in IS NOT NULL 
         AND NOT ((p_expry_date_in = TO_CHAR(l_expry_date,'MMYY'))
         OR (l_replace_expry_date IS NOT NULL AND p_expry_date_in = TO_CHAR(l_replace_expry_date,'MMYY')))
         THEN
             l_resp_cde := '47';
             l_err_msg := 'Invalid Expiry Date';
             RAISE exp_reject_record;
         END IF;

         IF p_user_name_in IS NOT NULL
         THEN
            IF  UPPER (TRIM (p_user_name_in)) <> l_user_name
            THEN
               l_resp_cde := '119';
               l_err_msg := 'Invalid Username or Password';
               RAISE exp_reject_record;
            END IF;

            IF p_password_in IS NOT NULL
            AND gethash (p_password_in) <> l_passwrd_hash
            THEN
                  l_resp_cde := '119';
                  l_err_msg := 'Invalid Username or Password';
                  RAISE exp_reject_record;
            END IF;
         END IF;

         IF p_phone_no_in IS NOT NULL OR p_zip_code_in IS NOT NULL
         THEN
            FOR l_idx
               IN (SELECT decode(l_encrypt_enable,'Y', fn_dmaps_main(cam_phone_one),cam_phone_one)cam_phone_one, 
			              decode(l_encrypt_enable,'Y', fn_dmaps_main(cam_pin_code),cam_pin_code) cam_pin_code, cam_addr_code
                     FROM cms_addr_mast
                    WHERE cam_inst_code = p_inst_code_in
                          AND cam_cust_code = l_cust_code)
            LOOP
               l_paddress (l_idx.cam_phone_one) := l_idx.cam_addr_code;
               l_maddress (l_idx.cam_pin_code) := l_idx.cam_addr_code;
            END LOOP;

            IF p_phone_no_in IS NOT NULL
            THEN
               IF l_paddress.EXISTS (p_phone_no_in)
               THEN
                  NULL;
               ELSE
                  l_resp_cde := '49';
                  l_err_msg := 'Invalid Phone Number';
                  RAISE exp_reject_record;
               END IF;
            END IF;

            IF p_zip_code_in IS NOT NULL
            THEN
               IF l_maddress.EXISTS (p_zip_code_in)
               THEN
                  NULL;
               ELSE
                  l_resp_cde := '49';
                  l_err_msg := 'Invalid Zip Code';
                  RAISE exp_reject_record;
               END IF;
            END IF;
         END IF;

         --SN : CMSAUTH check
         BEGIN
            sp_cmsauth_check (p_inst_code_in,
                              p_msg_type_in,
                              p_rrn_in,
                              p_delivery_chnl_in,
                              p_txn_code_in,
                              '0',                             --p_txn_mode_in
                              p_tran_date_in,
                              p_tran_time_in,
                              '000',
                              p_revrsl_code_in,
                              l_tran_type,
                              p_curr_code_in,
                              l_tran_amt,                            --txn_amt
                              p_pan_code_in,
                              l_hash_pan,
                              l_encr_pan,
                              l_card_stat,
                              l_expry_date,
                              l_prod_code,
                              l_card_type,
                              l_prfl_flag,
                              l_prfl_code,
                              NULL,
                              NULL,
                              NULL,
                              l_resp_cde,
                              l_err_msg,
                              l_comb_hash);

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

     -- Start VMS-1091    
	   -- Start p_isAuthorizedDevice_out using p_cust_id_out and p_device_id_in
       BEGIN
            SELECT  
                decode (count(*), 1, 'true', 'false')  
            INTO 
    			p_isAuthorizedDevice_out 
            FROM 
    			VMS_OTP_TOKEN
            WHERE 
                vot_token_status = 'ACTIVATED'
    		AND vot_expiry_date > sysdate 
            AND vot_device_id = p_device_id_in 
            AND vot_customer_id = p_cust_id_out;
      EXCEPTION
      WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting device count balance from VMS_OTP_TOKEN-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
     END;


     -- End p_isAuthorizedDevice_out

	 -- start transaction names using product code/catg(derived using custid) and delivery_channel(p_delivery_chnl_in)
     BEGIN
        OPEN p_transactions_out FOR 
        SELECT
            tran_mast.ctm_tran_desc transactionname
        FROM
            vms_trans_configuration tran_config,
            cms_transaction_mast tran_mast
        WHERE
                tran_mast.ctm_tran_code = tran_config.vtc_tran_code
            AND
                tran_config.vtc_delivery_channel = tran_mast.ctm_delivery_channel
            AND tran_config.VTC_PROD_CODE = l_prod_code
            AND tran_config.VTC_CARD_TYPE= l_card_type
            AND tran_config.vtc_delivery_channel = p_delivery_chnl_in
            AND
                tran_config.vtc_inst_code = p_inst_code_in
            AND 
                tran_config.VTC_TRANS_CONF_CODE = 'O';

     EXCEPTION 
     WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while fetching p_transactions_out'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
     END;



      BEGIN
           SELECT count(*)
           INTO l_otp_count
            FROM
                vms_trans_configuration
            WHERE
                     VTC_TRANS_CONF_CODE = 'O'
                     AND VTC_PROD_CODE = l_prod_code
                     AND VTC_CARD_TYPE= l_card_type
                     AND vtc_delivery_channel = p_delivery_chnl_in
                     and vtc_inst_code = p_inst_code_in;

           IF l_otp_count = '0' THEN

           p_mobile_deliverymode_out := NULL;
           p_email_deliverymode_out  := NULL;

           END IF;

      EXCEPTION
      WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting VTC_TRANS_CONF_CODE from vms_trans_configuration-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
     END;

      ---p_mobile_deliverymode_out:= case when (L_TRANS_CONF_CODE,'O',p_mobile_deliverymode_out,null);



	-- End VMS-1091 --

         --EN : CMSAUTH check

         --SN : Get account balance details from acct master 
         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code,TRIM(TO_CHAR (nvl(CAM_NEW_INITIALLOAD_AMT,cam_initialload_amt), '99999999999999990.99'))
              INTO l_acct_balance, l_ledger_bal, l_acct_type,p_initial_load_amount_out
              FROM cms_acct_mast
             WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting account balance from acct master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get account balance details from acct master

        IF p_initial_load_amount_out = 0 THEN
        BEGIN
            SELECT TRIM(TO_CHAR(nvl(VOL_DENOMINATION,'0'),'99999999999999990.99'))
            INTO p_initial_load_amount_out
              FROM vms_line_item_dtl, vms_order_lineitem
              WHERE vli_pan_code  =l_hash_pan
              AND VLI_PARTNER_ID=VOL_PARTNER_ID
              AND VLI_ORDER_ID=VOL_ORDER_ID
              AND VOL_LINE_ITEM_ID=VLI_LINEITEM_ID;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
          p_initial_load_amount_out := '0.00';
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting account balance from acct master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
        END;
        END IF;
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO l_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while generating authid-'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

         l_timestamp := SYSTIMESTAMP;

         BEGIN
            sp_fee_calc (p_inst_code_in,
                         p_msg_type_in,
                         p_rrn_in,
                         p_delivery_chnl_in,
                         p_txn_code_in,
                         '0',                                 --p_txn_mode_in,
                         p_tran_date_in,
                         p_tran_time_in,
                         '000',
                         p_revrsl_code_in,
                         l_txn_type,
                         p_curr_code_in,
                         l_tran_amt,                                 --txn_amt
                         p_pan_code_in,
                         l_hash_pan,
                         l_encr_pan,
                         l_acct_number,
                         l_prod_code,
                         l_card_type,
                         l_preauth_flag,
                         NULL,
                         NULL,
                         NULL,
                         l_trans_desc,
                         l_dr_cr_flag,
                         l_acct_balance,
                         l_ledger_bal,
                         l_acct_type,
                         l_login_txn,
                         l_auth_id,
                         l_timestamp,
                         l_resp_cde,
                         l_err_msg,
                         l_fee_code,
                         l_fee_plan,
                         l_feeattach_type,
                         l_tranfee_amt,
                         l_total_amt,
                      v_compl_fee,
                      v_compl_feetxn_excd,
                      v_compl_feecode,                         
                         l_preauth_type);

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN: VMS-6617 Changes
         IF l_card_stat='6' AND p_reason_code_out='311' THEN
            BEGIN
                updt_cardstat_hld2actv (p_inst_code_in,
                                        l_hash_pan,
                                        l_encr_pan,
                                        l_acct_number,
                                        p_rrn_in,
                                        l_auth_id,
                                        l_card_stat,
                                        l_resp_cde,
                                        l_err_msg);
                                        
                IF l_err_msg <> 'OK' THEN
                   RAISE exp_reject_record;
                END IF;
                
                BEGIN
                   SELECT ccs_stat_desc
                     INTO p_card_stat_out
                     FROM cms_card_stat
                    WHERE ccs_stat_code = '1';
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      l_resp_cde := '12';
                      l_err_msg :=
                            'Error while selcting card status description'
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record;
                END; 
                
            EXCEPTION
             WHEN exp_reject_record THEN
                RAISE;
             WHEN OTHERS THEN
                l_resp_cde := '21';
                l_err_msg :='Error from updt_cardstat_hld2actv- '|| SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
            END;
         END IF;
         --EN: VMS-6617 Changes
		 
		p_allowredemptions_out:='False';  --Added for VMS-8798
		
--SN: VMS-8677 Changes
         IF NVL(l_allow_redemption,'NA') = 'N' AND (l_card_stat =1 OR p_card_stat_out='ACTIVE') THEN
            BEGIN
                UPDATE vmscms.cms_appl_pan
                   SET cap_allow_redemptions = 'Y',
                       cap_redemptions_enabled_timestamp = SYSDATE
                 WHERE cap_pan_code = l_hash_pan 
                   AND cap_mbr_numb = '000';
                   
                  p_allowredemptions_out:='True';
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_resp_cde := '21';
                    l_err_msg :='Error while enabling redemptions - ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
            END;
            
            END IF;
         --EN: VMS-8677 Changes
            
           /* IF NVL(l_allow_redemption,'NA') = 'Y' THEN 
            p_allowredemptions_out:='True';
         ELSE p_allowredemptions_out:='False';
         END IF;*/
         --EN: VMS-8677 Changes     
         

         --SN :Update limits
         IF l_prfl_code IS NOT NULL AND l_prfl_flag = 'Y'
         THEN
            BEGIN
               pkg_limits_check.sp_limitcnt_reset (p_inst_code_in,
                                                   l_hash_pan,
                                                   l_tran_amt,
                                                   l_comb_hash,
                                                   l_resp_cde,
                                                   l_err_msg);

               IF l_err_msg <> 'OK'
               THEN
                  l_err_msg :=
                     'From Procedure sp_limitcnt_reset-' || l_err_msg;
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                     'Error from Limit Reset Count Process-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

         --EN :Update limits
--replacement flag block
  IF l_repl_flag <> 0 THEN

      p_replaced_card_out := 'true';
    ELSE
      p_replaced_card_out := 'false';
    END IF;

	--Get the order channel
    BEGIN

--    select vpi_order_channel INTO p_order_channel_out from vms_partner_id_mast where vpi_partner_id=(
--    select vli_partner_id from vms_line_item_dtl where vli_pan_code=l_hash_pan);
      select NVL(vod_channel,vpi_order_channel) INTO p_order_channel_out
      from VMS_ORDER_DETAILS,vms_line_item_dtl,vms_partner_id_mast
      where vli_pan_code=l_hash_pan
      and vod_order_id=VLI_ORDER_ID
      and vod_partner_id=VPI_PARTNER_ID
      and vod_partner_id=VLI_PARTNER_ID
      and  VLI_PARTNER_ID<>'Replace_Partner_ID';

     EXCEPTION
     WHEN NO_DATA_FOUND THEN
     p_order_channel_out := NULL;

        WHEN OTHERS THEN
           l_resp_cde := '12';
           l_err_msg :=  'Error while getting ORDER CHANNEL dtls-' || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_reject_record;

    END;
    --END the order channel
         l_resp_cde := '1';

      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;

         WHEN OTHERS
         THEN
            ROLLBACK;
            l_err_msg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            l_resp_cde := '89';
      END;

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE     cms_inst_code = p_inst_code_in
                   AND cms_delivery_channel = p_delivery_chnl_in
                   AND cms_response_id = TO_NUMBER (l_resp_cde);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Problem while selecting data from response master for respose code'
                  || l_resp_cde
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '69';
         END;


      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_card_stat,
                   cap_acct_no,
                   cap_proxy_number
              INTO l_prod_code,
                   l_card_type,
                   l_card_stat,
                   l_acct_number,
                   l_proxunumber
              FROM cms_appl_pan
             WHERE     cap_pan_code = l_hash_pan
                   AND cap_mbr_numb = '000'
                   AND cap_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      --SN : Get balance details from acct master
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code 
           INTO l_acct_balance, l_ledger_bal, l_acct_type 
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number
                AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_balance := 0;
            l_ledger_bal := 0;
      END;

      --EN : Get balance details from acct master

      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_chnl_in
               || p_txn_code_in
               || p_pan_code_in
               || p_rrn_in
               || TO_CHAR (NVL (l_timestamp, SYSTIMESTAMP),
                           'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_err_msg :=
               'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      IF p_resp_code_out <> '00'
      THEN
         p_cust_id_out := NULL;
         p_loginAttempts_Left_out := NULL;
         p_custid_type_out := NULL;
         p_serial_num_out := NULL;
         p_card_stat_out := NULL;
         p_resp_msg_out:=l_err_msg;
      END IF;

      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_chnl_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     '0',
                                     p_tran_date_in,
                                     p_tran_time_in,
                                     p_revrsl_code_in,
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_err_msg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_trans_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_number,
                                     l_prod_code,
                                     l_card_type,
                                     l_dr_cr_flag,
                                     l_acct_balance,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxunumber,
                                     l_auth_id,
                                     l_tran_amt,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     l_resp_cde,
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
                                     l_err_msg);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_msg_out :=
               'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '89';
         p_resp_msg_out := 'Main Excp- ' || SUBSTR (SQLERRM, 1, 300);
   END authenticate;

   PROCEDURE validate_pin(p_inst_code_in             IN NUMBER,
                          p_delivery_channel_in      IN VARCHAR2,
                          p_txn_code_in              IN VARCHAR2,
                          p_rrn_in                   IN VARCHAR2,
                          p_cust_id_in               IN VARCHAR2,
                          p_partner_id_in            IN VARCHAR2,
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
                          p_respmsg_out              OUT VARCHAR2
                          )
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
      l_tranfee_amt       NUMBER (10);
      l_total_amt         NUMBER (10);
      l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
      l_errmsg            VARCHAR2 (500);
      exp_reject_record   EXCEPTION;
   BEGIN
      BEGIN
         p_resp_code_out := '00';
         p_respmsg_out := 'success';

--Sn pan details procedure call
         BEGIN
          SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no,
                cap_card_stat, cap_prod_code, cap_card_type,
                cap_expry_date,  cap_prfl_code,
                cap_proxy_number
           INTO l_hash_pan, l_encr_pan, l_acct_no,
                l_card_stat, l_prod_code, l_prod_cattype,
                l_expry_date,  l_prfl_code,
                l_proxynumber
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            AND cap_mbr_numb = '000';

         EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
                 RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


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

         p_resp_code_out := '1';

       EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;
            p_respmsg_out:=l_errmsg;
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_respmsg_out := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
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
               p_respmsg_out :=
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
                     || p_pan_code_in
                     || p_rrn_in
                     || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            p_respmsg_out :=
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
                 p_respmsg_out := 'Invalid Card /Account ' ;
        WHEN OTHERS
        THEN
           p_resp_code_out := '12';
           p_respmsg_out :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

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
   END validate_pin;

 PROCEDURE        validate_security_questions (
   p_inst_code_in            IN       NUMBER,
   p_delivery_chnl_in        IN       VARCHAR2,
   p_txn_code_in             IN       VARCHAR2,
   p_rrn_in                  IN       VARCHAR2,
   p_appl_id_in              IN       VARCHAR2,
   p_partner_id_in           IN       VARCHAR2,
   p_tran_date_in            IN       VARCHAR2,
   p_tran_time_in            IN       VARCHAR2,
   p_curr_code_in            IN       VARCHAR2,
   p_revrsl_code_in          IN       VARCHAR2,
   p_msg_type_in             IN       VARCHAR2,
   p_user_name_in            IN       VARCHAR2,
   p_security_qus_in         IN       VARCHAR2,
   p_security_qus_ans_in     IN       VARCHAR2,
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
   p_resp_msg_out            OUT      VARCHAR2
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
   l_tranfee_amt       NUMBER (10);
   l_total_amt         NUMBER (10);
   l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
   l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
   l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
   l_errmsg            VARCHAR2 (500);
   l_appl_code         cms_appl_pan.cap_appl_code%TYPE;
   l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   l_cust_id           cms_cust_mast.ccm_cust_id%TYPE;
   l_user_name         cms_cust_mast.ccm_user_name%TYPE;
   l_appl_id           cms_cust_mast.ccm_appl_id%TYPE;
   l_num               NUMBER;
   l_cnt               NUMBER;
   l_email             cms_addr_mast.cam_email%TYPE;
   l_qus               cms_security_questions.csq_question%TYPE;
   l_ans               VARCHAR2 (1000);
   exp_reject_record   EXCEPTION;
   l_encrypt_enable    cms_prod_cattype.cpc_encrypt_enable%type;
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
                cap_appl_code, cap_cust_code
           INTO l_hash_pan, l_encr_pan, l_acct_no, l_card_stat,
                l_prod_code, l_prod_cattype, l_expry_date,
                l_active_date, l_prfl_code, l_proxynumber,
                l_appl_code, l_cust_code
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
         SELECT cpc_encrypt_enable
           INTO l_encrypt_enable
           FROM cms_prod_cattype
          WHERE cpc_inst_code = p_inst_code_in
            AND cpc_prod_code = l_prod_code
            AND cpc_card_type = l_prod_cattype;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Encrypt details not found for ' || l_prod_code || l_prod_cattype;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting encrypt details for product'
               || SUBSTR (SQLERRM, 1, 200);
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
                  'Error from authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT decode(l_encrypt_enable,'Y',fn_dmaps_main(ccm_user_name),ccm_user_name),
		 ccm_appl_id, ccm_cust_id
           INTO l_user_name, l_appl_id, l_cust_id
           FROM cms_cust_mast
          WHERE ccm_cust_code = l_cust_code AND ccm_inst_code = p_inst_code_in;

         IF     UPPER (l_user_name) = UPPER (TRIM (p_user_name_in))
            AND l_appl_id = p_appl_id_in
         THEN
            NULL;
         ELSE
            BEGIN
               SELECT decode(l_encrypt_enable,'Y',fn_dmaps_main(cam_email),cam_email)
                 INTO l_email
                 FROM cms_addr_mast
                WHERE cam_inst_code = p_inst_code_in
                  AND cam_cust_code = l_cust_code
                  AND cam_addr_flag = 'P';
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code_out := '12';
                  l_errmsg :=
                        'Error while getting details from cms_addr_mast '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            IF     UPPER (l_email) = UPPER (TRIM (p_user_name_in))
               AND l_appl_id = p_appl_id_in
            THEN
               NULL;
            ELSE
               p_resp_code_out := '21';
               l_errmsg := 'Invalid User Name or password';
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
                  'Error while getting cust id from cust_mast '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         l_num := 1;

         LOOP
            l_qus := REGEXP_SUBSTR (p_security_qus_in, '[^||]+', 1, l_num);
            l_ans :=
                    REGEXP_SUBSTR (p_security_qus_ans_in, '[^||]+', 1, l_num);

            SELECT COUNT (1)
              INTO l_cnt
              FROM cms_security_questions
             WHERE csq_cust_id = l_cust_id
               AND csq_inst_code = p_inst_code_in
               AND csq_question = TRIM (l_qus)
               AND csq_answer_hash = gethash (l_ans);

            IF l_qus IS NULL
            THEN
               EXIT;
            END IF;

            IF l_cnt = 0
            THEN
               p_resp_code_out := '117';
               l_errmsg := 'Invalid Security Question/Answer';
               RAISE exp_reject_record;
            END IF;

            l_num := l_num + 1;
         END LOOP;

		  IF l_num = 1
            THEN
               p_resp_code_out := '117';
               l_errmsg := 'Invalid Security Question/Answer';
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
                  'Error while validating security Question/Anser '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      p_resp_code_out := '1';

   EXCEPTION                                            --<<Main Exception>>--
      WHEN exp_reject_record
      THEN
         ROLLBACK;
         p_resp_msg_out := l_errmsg;
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_msg_out := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
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
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            p_resp_msg_out := 'Invalid Card/ Account ' ;
       WHEN OTHERS
      THEN
         p_resp_msg_out :=
               'Error while selecting from response master '
            || p_resp_msg_out
            || p_resp_code_out
            || ' IS-'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
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
         p_resp_msg_out :=
            'Error while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
   END;

--dbms_output.put_line(l_acct_no);
   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO l_acct_bal, l_ledger_bal, l_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code_in AND cam_acct_no = l_acct_no;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '12';
         p_resp_msg_out :=
               'Error while getting account details'
            || SUBSTR (SQLERRM, 1, 200)
            || l_errmsg;
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
                                  case when p_resp_code_out='00' then '1' else p_resp_code_out end,
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

          update cms_transaction_log_dtl
          set CTD_DEVICE_ID= p_device_id_in,
          CTD_USER_NAME= p_user_name_in
          where CTD_HASHKEY_ID=l_hashkey_id;

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
            || ' Error while inserting into transactionlog  '
            || l_errmsg;
      WHEN OTHERS
      THEN
         p_resp_code_out := '69';
         p_resp_msg_out :=
               'Error while inserting into transactionlog '
            || SUBSTR (SQLERRM, 1, 300);
   END;
END validate_security_questions;

PROCEDURE Validate_calllog_id   (p_inst_code_in             IN NUMBER,
                                 p_delivery_channel_in      IN VARCHAR2,
                                 p_txn_code_in              IN VARCHAR2,
                                 p_rrn_in                   IN VARCHAR2,
                                 p_cust_id_in               IN VARCHAR2,
                                 p_partner_id_in            IN VARCHAR2,
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
                                 p_call_logid_in            IN  VARCHAR2,
                                 p_resp_code_out            OUT VARCHAR2,
                                 p_respmsg_out              OUT VARCHAR2)
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
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
      l_acct_type         cms_acct_mast.cam_type_code%TYPE;
      l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type    transactionlog.feeattachtype%TYPE;
      l_tranfee_amt       NUMBER (10);
      l_total_amt         NUMBER (10);
      l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
      l_call_status       cms_calllog_mast.ccm_call_status%TYPE;
 	  l_status_chk        PLS_INTEGER;
	  l_precheck_flag	  PLS_INTEGER;
	  l_tran_amt          cms_acct_mast.cam_acct_bal%TYPE;
      l_errmsg            VARCHAR2 (500);
      exp_reject_record   EXCEPTION;

	/********************************************************************************
	 * Modified Date    : 30-Nov-2020
     * Modified By      : Puvanesh.N/Ubaidur.H
     * Modified for     : VMS-3349 - IVR callLogId Validation
     * Modified reason  : IVR Call Log ID transaction - Blocking Session while fetching the account balance.
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 30-Nov-2020
     * Release Number   : R39 Build 2
	*********************************************************************************/
   BEGIN
      BEGIN
         p_respmsg_out := 'success';

--Sn pan details
        BEGIN
          SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no,
                 cap_card_stat, cap_prod_code, cap_card_type,
                 cap_expry_date, cap_active_date, cap_prfl_code,
                 cap_proxy_number
           INTO l_hash_pan, l_encr_pan, l_acct_no,
                l_card_stat, l_prod_code, l_prod_cattype,
                l_expry_date, l_active_date, l_prfl_code,
                l_proxynumber
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            AND cap_mbr_numb = '000';

         EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
                  RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
--En pan details

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

		 -- Modified for VMS-3349 Start

/*         --SN : authorize_nonfinancial_txn check
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
    --EN : authorize_nonfinancial_txn check
*/


BEGIN
      sp_status_check_gpr (p_inst_code_in,
                           p_pan_code_in,
                           p_delivery_channel_in,
                           l_expry_date,
                           l_card_stat,
                           p_txn_code_in,
                           '0',--p_txn_mode_in',
                           l_prod_code,
                           l_prod_cattype,
                           p_msg_type_in,
                           p_trandate_in,
                           p_trantime_in,
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
         IF TO_DATE (p_trandate_in, 'YYYYMMDD') >  LAST_DAY (l_expry_date)
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
                             p_delivery_channel_in,
                             l_expry_date,
                             l_card_stat,
                             p_txn_code_in,
                             '0',--p_txn_mode_in,
                             p_trandate_in,
                             p_trantime_in,
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

        --SN callLogId Validation
		-- Modified for VMS-3349 End
        BEGIN
            SELECT CCM_CALL_STATUS INTO l_CALL_STATUS  FROM CMS_CALLLOG_MAST
            WHERE  CCM_INST_CODE= p_inst_code_in
            AND CCM_CALL_ID = p_call_logid_in
            AND CCM_ACCT_NO= l_acct_no;

            IF l_CALL_STATUS <> 'O' THEN
                 p_resp_code_out := '139';
                 l_errmsg := 'Call Status is invalid ';
                 RAISE EXP_REJECT_RECORD;
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 p_resp_code_out := '138';
                 l_errmsg := 'Invalid Call Log ID ';
                 RAISE EXP_REJECT_RECORD;
            WHEN EXP_REJECT_RECORD THEN
                 RAISE;
            WHEN OTHERS THEN
                 p_resp_code_out := '12';
                 l_errmsg := 'Error while selecting CMS_CALLLOG_MAST 11'|| l_CALL_STATUS || '---'|| SUBSTR(SQLERRM, 1, 300);
                 RAISE EXP_REJECT_RECORD;
        END;
         --SN callLogId Validation


       p_resp_code_out := '1';

       EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            p_respmsg_out  := l_errmsg;
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

	 BEGIN

            SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO l_auth_id FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
                p_respmsg_out :=
                    'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
                p_resp_code_out := '21';    
         END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_hashkey_id :=
            gethash (   p_delivery_channel_in
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
        WHEN OTHERS
        THEN
           p_resp_code_out := '12';
           l_errmsg :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;


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
                                     l_errmsg
                                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            l_errmsg :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;

END Validate_calllog_id;

   PROCEDURE virtualcard_authenticate (p_inst_code_in                IN NUMBER,
                                       p_delivery_chnl_in            IN VARCHAR2,
                                       p_txn_code_in                 IN VARCHAR2,
                                       p_rrn_in                      IN VARCHAR2,
                                       p_cust_id_in                  IN VARCHAR2,
                                       p_partner_id_in               IN VARCHAR2,
                                       p_tran_date_in                IN VARCHAR2,
                                       p_tran_time_in                IN VARCHAR2,
                                       p_curr_code_in                IN VARCHAR2,
                                       p_revrsl_code_in              IN VARCHAR2,
                                       p_msg_type_in                 IN VARCHAR2,
                                       p_ip_addr_in                  IN VARCHAR2,
                                       p_ani_in                      IN VARCHAR2,
                                       p_dni_in                      IN VARCHAR2,
                                       p_device_mobno_in             IN VARCHAR2,
                                       p_device_id_in                IN VARCHAR2,
                                       p_uuid_in                     IN VARCHAR2,
                                       p_osname_in                   IN VARCHAR2,
                                       p_osversion_in                IN VARCHAR2,
                                       p_gps_coordinates_in          IN VARCHAR2,
                                       p_display_resolution_in       IN VARCHAR2,
                                       p_physical_memory_in          IN VARCHAR2,
                                       p_appname_in                  IN VARCHAR2,
                                       p_appversion_in               IN VARCHAR2,
                                       p_sessionid_in                IN VARCHAR2,
                                       p_device_country_in           IN VARCHAR2,
                                       p_device_region_in            IN VARCHAR2,
                                       p_ipcountry_in                IN VARCHAR2,
                                       p_proxy_flag_in               IN VARCHAR2,
                                       p_pan_code_in                 IN VARCHAR2,
                                       p_resp_code_out               OUT VARCHAR2,
                                       p_resp_msg_out                OUT VARCHAR2,
                                       p_cust_id_out                 OUT NUMBER,
                                       p_exp_date_out                OUT VARCHAR2,
                                       p_card_stat_out               OUT VARCHAR2,
                                       p_product_upc_out             OUT VARCHAR2,
                                       p_initial_load_amount_out     OUT VARCHAR2,
                                       p_zip_code_out                OUT VARCHAR2,
                                       p_status_out                  OUT VARCHAR2,
                                       p_reason_code_out             OUT VARCHAR2)  --Added for VMS-6617 Changes
   AS

   /*******************************************************************************
     * Modified by       : Divya Bhaskaran
     * Modified Date     : 22-Aug-18
     * Modified For      : VMS-465
     * Reviewer          : Saravanakumar A
     * Build Number      : R05_B0004

     * Modified by       : Dhinakaran B
     * Modified Date     : 27-May-21
     * Modified For      : VMS-4426
     * Reviewer          : Saravanakumar A
     * Build Number      : R47 Build 2

     * Modified By       : Pankaj S.
     * Modified For      : VMS-6617
     * Purpose           : Fraud - ONHOLD cardstatus updates - Virtual Auth changes
     * Reviewer          : Venkat S.
     * Release Number    : R70.2
************************************************************************************/
      l_hash_pan           cms_appl_pan.cap_pan_code%TYPE; 
      l_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
      l_cust_code          cms_appl_pan.cap_cust_code%TYPE;
      l_proxunumber        cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_number        cms_appl_pan.cap_acct_no%TYPE;
      l_card_stat          cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date         cms_appl_pan.cap_expry_date%TYPE;
      l_replace_expry_date cms_appl_pan.cap_expry_date%TYPE;
      l_firsttime_topup    cms_appl_pan.cap_firsttime_topup%TYPE;
      l_prfl_code          cms_appl_pan.cap_prfl_code%TYPE;
      l_prod_code          cms_appl_pan.cap_prod_code%TYPE;
      l_card_type          cms_appl_pan.cap_card_type%TYPE;
      l_addr_code          cms_appl_pan.cap_bill_addr%TYPE;
      l_cust_id_type       cms_appl_pan.cap_user_identify_type%TYPE;
      l_acct_balance       cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type          cms_acct_mast.cam_type_code%TYPE;
      l_trans_desc         cms_transaction_mast.ctm_tran_desc%TYPE;
      l_dr_cr_flag         cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_tran_type          cms_transaction_mast.ctm_tran_type%TYPE;
      l_prfl_flag          cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_preauth_flag       cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_login_txn          cms_transaction_mast.ctm_login_txn%TYPE;
      l_preauth_type       cms_transaction_mast.ctm_preauth_type%TYPE;
      l_fee_code           transactionlog.feecode%TYPE;
      l_fee_plan           transactionlog.fee_plan%TYPE;
      l_feeattach_type     transactionlog.feeattachtype%TYPE;
      l_tranfee_amt        transactionlog.tranfee_amt%TYPE;
      l_total_amt          transactionlog.total_amount%TYPE;
      l_auth_id            transactionlog.auth_id%TYPE;
      l_hashkey_id         cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_comb_hash          pkg_limits_check.type_hash;
      l_tran_amt           cms_acct_mast.cam_acct_bal%TYPE := 0;  
      l_active_date        cms_appl_pan.cap_active_date%TYPE;
      l_timestamp          TIMESTAMP;
      l_tran_date          DATE;
      l_txn_type           cms_transaction_mast.ctm_tran_type%TYPE;
      l_rrn_count          NUMBER;
      l_resp_cde           transactionlog.response_id%TYPE;
      l_err_msg            VARCHAR2 (1000);
      l_repl_flag         cms_appl_pan.cap_repl_flag%TYPE;
      exp_reject_record    EXCEPTION;
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
   v_compl_fee varchar2(10);
   v_compl_feetxn_excd varchar2(10);
   v_compl_feecode varchar2(10);

   l_appl_code         cms_appl_pan.cap_appl_code%TYPE;
   l_kyc_flag          cms_caf_info_entry.cci_kyc_flag%TYPE;
   l_user_name         cms_cust_mast.ccm_user_name%TYPE;   
   l_user_identity CMS_PROD_CATTYPE.CPC_USER_IDENTIFY_TYPE%type;
   BEGIN
      BEGIN

        p_resp_msg_out:='Success';
         --SN : Convert clear card number to hash and encryped format.
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Convert clear card number to hash and encryped format.

         --SN : Get transaction details from master
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_type,
                   ctm_tran_desc,
                   ctm_prfl_flag,
                   ctm_preauth_flag,
                   ctm_login_txn,
                   ctm_preauth_type
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type,
                   l_trans_desc,
                   l_prfl_flag,
                   l_preauth_flag,
                   l_login_txn,
                   l_preauth_type
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_chnl_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting transaction dtls from master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get transaction details from master

         --SN : Get card details
         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_card_stat,
                   cap_proxy_number,
                   cap_acct_no,
                   cap_prfl_code,
                   cap_firsttime_topup,
                   cap_expry_date,
                   cap_cust_code,
                   cap_bill_addr,
                   cap_active_date,
                   cap_user_identify_type,
                   nvl(cap_repl_flag,0),
                   CAP_REPLACE_EXPRYDT,
                   cap_Appl_code,
                   cap_panmast_param5  --Added for VMS-6617 Changes
              INTO l_prod_code,
                   l_card_type,
                   l_card_stat,
                   l_proxunumber,
                   l_acct_number,
                   l_prfl_code,
                   l_firsttime_topup,
                   l_expry_date,
                   l_cust_code,
                   l_addr_code,
                   l_active_date,
                   l_cust_id_type,
                   l_repl_flag,
                   l_replace_expry_date,
                   l_appl_code,
                   p_reason_code_out   --Added for VMS-6617 Changes
              FROM cms_appl_pan
             WHERE     cap_pan_code = l_hash_pan
                   AND cap_mbr_numb = '000'
                   AND cap_inst_code = p_inst_code_in;

         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Problem while selecting card detail-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

           BEGIN
             SELECT  FN_DMAPS_MAIN(CAM_PIN_CODE)       
             INTO p_zip_code_out
             FROM CMS_ADDR_MAST
             WHERE CAM_CUST_CODE=l_cust_code
             AND CAM_INST_CODE=p_inst_code_in
             AND CAM_ADDR_FLAG='P';

             if p_zip_code_out='*' then
              p_zip_code_out:='';
             end if;

          EXCEPTION 
           WHEN OTHERS THEN
            l_resp_cde := '89';
               l_err_msg :='Problem while selecting zip code details -'|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
           END;


         --EN : Get card details
           BEGIN
               SELECT ccs_stat_desc
                 INTO p_card_stat_out
                 FROM cms_card_stat
                WHERE ccs_stat_code = l_card_stat;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_resp_cde := '12';
                  l_err_msg :=
                        'Error while selcting card status description'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

         --SN : Transaction date-time check
         BEGIN
            l_tran_date :=
               TO_DATE (SUBSTR (TRIM (p_tran_date_in), 1, 8), 'yyyymmdd');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '45';
               l_err_msg :=
                  'Problem while converting transaction date-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            l_tran_date :=
               TO_DATE (
                     SUBSTR (TRIM (p_tran_date_in), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_tran_time_in), 1, 10),
                  'yyyymmdd hh24:mi:ss');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '32';
               l_err_msg :=
                  'Problem while converting transaction time-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Transaction date-time check

         --SN: Duplicate RRN Check
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_desc,NVL(CTM_RRN_CHECK,'Y')
              INTO l_dr_cr_flag, l_txn_type, l_trans_desc,l_dup_rrn_check
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_chnl_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                  'Error while getting transaction details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         if l_dup_rrn_check='Y' then
         BEGIN
            SELECT COUNT (1)
              INTO l_rrn_count
              FROM transactionlog
             WHERE     rrn = p_rrn_in
                   AND business_date = p_tran_date_in
                   AND instcode = p_inst_code_in
                   AND delivery_channel = p_delivery_chnl_in;

            IF l_rrn_count > 0
            THEN
               l_resp_cde := '22';
               l_err_msg := 'Duplicate RRN on ' || p_tran_date_in;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Problem while selecting TRANSACTIONLOG '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
        end if;

         --EN: Duplicate RRN Check

         BEGIN
            SELECT CPC_PRODUCT_UPC,CPC_USER_IDENTIFY_TYPE
              INTO p_product_upc_out,l_user_identity
              FROM cms_prod_cattype
             WHERE     cpc_inst_code = p_inst_code_in
                   AND cpc_prod_code = l_prod_code
                   AND cpc_card_type = l_card_type;

         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                  'Error while getting prod_catg dtls-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

	         --SN : Get customer detls
         BEGIN	 
            SELECT ccm_cust_id
              INTO p_cust_id_out
              FROM cms_cust_mast
             WHERE ccm_cust_code = l_cust_code
                   AND ccm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                  'Error while getting customer details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get customer detls

           BEGIN
          p_exp_date_out := to_char(l_expry_date, 'YYYY-MM-DD');
          EXCEPTION
             WHEN OTHERS
             THEN
                p_resp_code_out := '21';
                l_err_msg  := 'Problem while converting expiry date ' ||
                      SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

         --SN : CMSAUTH check
         BEGIN
            sp_cmsauth_check (p_inst_code_in,
                              p_msg_type_in,
                              p_rrn_in,
                              p_delivery_chnl_in,
                              p_txn_code_in,
                              '0',                             --p_txn_mode_in
                              p_tran_date_in,
                              p_tran_time_in,
                              '000',
                              p_revrsl_code_in,
                              l_tran_type,
                              p_curr_code_in,
                              l_tran_amt,                            --txn_amt
                              p_pan_code_in,
                              l_hash_pan,
                              l_encr_pan,
                              l_card_stat,
                              l_expry_date,
                              l_prod_code,
                              l_card_type,
                              l_prfl_flag,
                              l_prfl_code,
                              NULL,
                              NULL,
                              NULL,
                              l_resp_cde,
                              l_err_msg,
                              l_comb_hash);

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : CMSAUTH check


    BEGIN
         SELECT cci_kyc_flag
           INTO l_kyc_flag
           FROM cms_caf_info_entry
          WHERE cci_inst_code = p_inst_code_in
            AND cci_appl_code = TO_CHAR (l_appl_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
               'Error while selecting the kyc flag'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

       BEGIN
         SELECT NVL (fn_dmaps_main(ccm_user_name), 0)
           INTO l_user_name
           FROM cms_cust_mast
          WHERE ccm_inst_code = p_inst_code_in AND ccm_cust_code = l_cust_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                  'Error while selecting username '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
    -- 2 => KYC product
    -- 3 => Personalized
   if l_user_identity in ('2', '3')
   then
        -- Y = ID SUCCESS, P = IQ SUCCESS, O = KYC OVERRIDE
      IF UPPER (l_kyc_flag) NOT IN ('P', 'Y', 'O')
      THEN
         p_status_out := 'NOT_REGISTERED';
      ELSE
         IF l_user_name = '0'
         THEN
            p_status_out := 'REGISTERED_USERNAME_NOT_CREATED';
         ELSE
            p_status_out := 'REGISTERED_USERNAME_CREATED';
         END IF;
      END IF;
   else
       -- KYC disabled, other than Personalized product
       -- 0 : User not created
       IF l_user_name = '0'
       THEN
           p_status_out := 'NOT_ENROLLED';
       ELSE
           p_status_out := 'ENROLLED';
       END IF;
   end if;

         --SN : Get account balance details from acct master 
         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code,TRIM(TO_CHAR (nvl(CAM_NEW_INITIALLOAD_AMT,cam_initialload_amt), '99999999999999990.99'))
              INTO l_acct_balance, l_ledger_bal, l_acct_type,p_initial_load_amount_out
              FROM cms_acct_mast
             WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting account balance from acct master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get account balance details from acct master

        IF p_initial_load_amount_out = 0 THEN
        BEGIN
            SELECT TRIM(TO_CHAR(nvl(VOL_DENOMINATION,'0'),'99999999999999990.99'))
            INTO p_initial_load_amount_out
              FROM vms_line_item_dtl, vms_order_lineitem
              WHERE vli_pan_code  =l_hash_pan
              AND VLI_PARTNER_ID=VOL_PARTNER_ID
              AND VLI_ORDER_ID=VOL_ORDER_ID
              AND VOL_LINE_ITEM_ID=VLI_LINEITEM_ID;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
          p_initial_load_amount_out := '0.00';
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting account balance from acct master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
        END;
        END IF;

         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO l_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while generating authid-'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

         l_timestamp := SYSTIMESTAMP;

         BEGIN
            sp_fee_calc (p_inst_code_in,
                         p_msg_type_in,
                         p_rrn_in,
                         p_delivery_chnl_in,
                         p_txn_code_in,
                         '0',                                 --p_txn_mode_in,
                         p_tran_date_in,
                         p_tran_time_in,
                         '000',
                         p_revrsl_code_in,
                         l_txn_type,
                         p_curr_code_in,
                         l_tran_amt,                                 --txn_amt
                         p_pan_code_in,
                         l_hash_pan,
                         l_encr_pan,
                         l_acct_number,
                         l_prod_code,
                         l_card_type,
                         l_preauth_flag,
                         NULL,
                         NULL,
                         NULL,
                         l_trans_desc,
                         l_dr_cr_flag,
                         l_acct_balance,
                         l_ledger_bal,
                         l_acct_type,
                         l_login_txn,
                         l_auth_id,
                         l_timestamp,
                         l_resp_cde,
                         l_err_msg,
                         l_fee_code,
                         l_fee_plan,
                         l_feeattach_type,
                         l_tranfee_amt,
                         l_total_amt,
                           v_compl_fee,
                      v_compl_feetxn_excd,
                      v_compl_feecode,
                         l_preauth_type);

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN: VMS-6617 Changes
         IF l_card_stat='6' AND p_reason_code_out='311' THEN
            BEGIN
                updt_cardstat_hld2actv (p_inst_code_in,
                                        l_hash_pan,
                                        l_encr_pan,
                                        l_acct_number,
                                        p_rrn_in,
                                        l_auth_id,
                                        l_card_stat,
                                        l_resp_cde,
                                        l_err_msg);
                                        
                IF l_err_msg <> 'OK' THEN
                   RAISE exp_reject_record;
                END IF; 

               BEGIN
                   SELECT ccs_stat_desc
                     INTO p_card_stat_out
                     FROM cms_card_stat
                    WHERE ccs_stat_code = '1';
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      l_resp_cde := '12';
                      l_err_msg :=
                            'Error while selcting card status description'
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record;
                END;                
            EXCEPTION
             WHEN exp_reject_record THEN
                RAISE;
             WHEN OTHERS THEN
                l_resp_cde := '21';
                l_err_msg :='Error from updt_cardstat_hld2actv- '|| SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
            END;
         END IF;
         --EN: VMS-6617 Changes

	        l_resp_cde := '1';

      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;

         WHEN OTHERS
         THEN
            ROLLBACK;
            l_err_msg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            l_resp_cde := '89';
      END;

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE     cms_inst_code = p_inst_code_in
                   AND cms_delivery_channel = p_delivery_chnl_in
                   AND cms_response_id = TO_NUMBER (l_resp_cde);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Problem while selecting data from response master for respose code'
                  || l_resp_cde
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '69';
         END;


      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_card_stat,
                   cap_acct_no,
                   cap_proxy_number
              INTO l_prod_code,
                   l_card_type,
                   l_card_stat,
                   l_acct_number,
                   l_proxunumber
              FROM cms_appl_pan
             WHERE     cap_pan_code = l_hash_pan
                   AND cap_mbr_numb = '000'
                   AND cap_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      --SN : Get balance details from acct master
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code,TRIM(TO_CHAR (nvl(CAM_NEW_INITIALLOAD_AMT,cam_initialload_amt), '99999999999999990.99'))
           INTO l_acct_balance, l_ledger_bal, l_acct_type,p_initial_load_amount_out
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number
                AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_balance := 0;
            l_ledger_bal := 0;
      END;

      --EN : Get balance details from acct master

      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_chnl_in
               || p_txn_code_in
               || p_pan_code_in
               || p_rrn_in
               || TO_CHAR (NVL (l_timestamp, SYSTIMESTAMP),
                           'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_err_msg :=
               'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      IF p_resp_code_out <> '00'
      THEN
         p_cust_id_out := '';
         p_card_stat_out := '';
         p_exp_date_out := '';
         p_product_upc_out := '';
         p_initial_load_amount_out := '';
         p_zip_code_out := '';
         p_resp_msg_out:=l_err_msg;
      END IF;

      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_chnl_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     '0',
                                     p_tran_date_in,
                                     p_tran_time_in,
                                     p_revrsl_code_in,
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_err_msg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_trans_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_number,
                                     l_prod_code,
                                     l_card_type,
                                     l_dr_cr_flag,
                                     l_acct_balance,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxunumber,
                                     l_auth_id,
                                     l_tran_amt,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     l_resp_cde,
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
                                     l_err_msg);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_msg_out :=
               'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '89';
         p_resp_msg_out := 'Main Excp- ' || SUBSTR (SQLERRM, 1, 300);
   END virtualcard_authenticate;

   PROCEDURE updt_cardstat_hld2actv (
        p_inst_code_in          NUMBER,
        p_card_no_in            VARCHAR2,
        p_cardencr_in           VARCHAR2,
        p_acctno_in             VARCHAR2,
        p_rrn_in                VARCHAR2,
        p_auth_id_in            VARCHAR2,
        p_crdstat_in            VARCHAR2,
        p_resp_code_out  OUT    VARCHAR2,
        p_resp_msg_out   OUT    VARCHAR2
    ) AS
        l_call_id      cms_calllog_mast.ccm_call_id%TYPE;  
        l_remark       cms_calllog_details.ccd_comments%TYPE := 'Your account has been updated to active from an on-hold status. It was put in a fraud prevention hold due to inactivity and is now active and ready to use.';
   BEGIN
       p_resp_msg_out := 'OK';
       p_resp_code_out := '00';
       
       BEGIN
           UPDATE vmscms.cms_appl_pan
              SET cap_card_stat = '1',
                  cap_panmast_param5 = NULL
            WHERE cap_pan_code = p_card_no_in
              AND cap_mbr_numb = '000'
              AND cap_card_stat = p_crdstat_in;

           IF SQL%rowcount = 1 THEN
               sp_log_cardstat_chnge(
                                    p_inst_code_in,
                                    p_card_no_in,
                                    p_cardencr_in,
                                    p_auth_id_in,
                                    '01',
                                    p_rrn_in,
                                    NULL,
                                    NULL,
                                    p_resp_code_out,
                                    p_resp_msg_out,
                                    l_remark );

               IF p_resp_code_out <> '00' AND p_resp_msg_out <> 'OK' THEN
                  RETURN;
               END IF;

              BEGIN
                 SELECT seq_call_id.NEXTVAL
                   INTO l_call_id
                   FROM DUAL;
              EXCEPTION
                 WHEN OTHERS THEN
                    p_resp_code_out := '21';
                    p_resp_msg_out := 'Error while generating call id  ' || substr(sqlerrm,1,200);
                    RETURN;
              END;

              BEGIN
                 INSERT INTO cms_calllog_mast
                             (ccm_inst_code, ccm_call_id, ccm_call_catg, ccm_pan_code,
                              ccm_callstart_date, ccm_callend_date, ccm_ins_user,
                              ccm_ins_date, ccm_lupd_user, ccm_lupd_date,
                              ccm_acct_no,ccm_call_status)
                      VALUES (p_inst_code_in, l_call_id, 1, p_card_no_in,
                              sysdate, null, 1, sysdate, 1, sysdate,
                              p_acctno_in,'C');
              EXCEPTION
                 WHEN OTHERS THEN
                    p_resp_code_out := '21';
                    p_resp_msg_out :='Error while inserting into cms_calllog_mast ' || substr(sqlerrm,1,200);
                    RETURN;
              END;

              BEGIN
                 INSERT INTO cms_calllog_details
                             (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                              ccd_rrn, ccd_devl_chnl, ccd_txn_code, ccd_tran_date,
                              ccd_tran_time, ccd_tbl_names, ccd_colm_name, 
                              ccd_old_value, ccd_new_value, ccd_comments, ccd_ins_user, 
                              ccd_ins_date, ccd_lupd_user, ccd_lupd_date, ccd_acct_no)
                      VALUES (p_inst_code_in, l_call_id, p_card_no_in, 1,
                              NULL, '05', '01', TO_CHAR (SYSDATE, 'yyyymmdd'), 
                              TO_CHAR (SYSDATE, 'hh24miss'), NULL, NULL, 
                              NULL, NULL, l_remark, 1, 
                              SYSDATE, 1, SYSDATE, p_acctno_in);
              EXCEPTION
                 WHEN OTHERS THEN
                    p_resp_code_out := '21';
                    p_resp_msg_out :='Error while inserting into cms_calllog_details ' || substr(sqlerrm,1,200);
                    RETURN;
              END;
           END IF;
       EXCEPTION
           WHEN OTHERS THEN
               p_resp_code_out := '21';
               p_resp_msg_out := 'Error in update cardstatus(On-Hold to active)-'|| substr(sqlerrm,1,200);
               RETURN;
       END;
   EXCEPTION
       WHEN OTHERS THEN
           p_resp_code_out := '21';
           p_resp_msg_out := 'Main excp updt_cardstat_hld2actv-'||substr(sqlerrm,1,200);
   END updt_cardstat_hld2actv;  
END;
/
show error