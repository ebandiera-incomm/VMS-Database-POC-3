create or replace PACKAGE BODY   vmscms.VMSSPIL 
IS
   -- Private type declarations

   -- Private constant declarations

   -- Private variable declarations

   -- Function and procedure implementations
   
   
    /* Modified By      : Karthick
    * Modified Date    : 08-23-2022
    * Purpose          : Archival changes.
    * Reviewer         : venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991*/
	
	
   PROCEDURE card_redemption (p_inst_code_in            IN     NUMBER,
                              p_msg_typ_in              IN     VARCHAR2,
                              p_rrn_in                  IN     VARCHAR2,
                              p_delivery_channel_in     IN     VARCHAR2,
                              p_term_id_in              IN     VARCHAR2,
                              p_txn_code_in             IN     VARCHAR2,
                              p_txn_mode_in             IN     VARCHAR2,
                              p_business_date_in        IN     VARCHAR2,
                              p_business_time_in        IN     VARCHAR2,
                              p_card_no_in              IN     VARCHAR2,
                              p_txn_amt_in              IN     NUMBER,
                              p_merchant_name_in        IN     VARCHAR2,
                              p_curr_code_in            IN     VARCHAR2,
                              p_stan_in                 IN     VARCHAR2,
                              p_mbr_numb_in             IN     VARCHAR2,
                              p_rvsl_code_in            IN     VARCHAR2,
                              p_lupduser_in             IN     NUMBER,
                              p_store_id_in             IN     VARCHAR2,
                              p_product_id_in           IN     VARCHAR2,
                              p_fee_amt_in              IN     NUMBER,
                              p_upc_in                  IN     VARCHAR2,
                              p_mercrefnum_in           IN     VARCHAR2,
                              p_reqtimezone_in          IN     VARCHAR2,
                              p_localcountry_in         IN     VARCHAR2,
                              p_localcurrency_in        IN     VARCHAR2,
                              p_loclanguage_in          IN     VARCHAR2,
                              p_posentry_in             IN     VARCHAR2,
                              p_poscond_in              IN     VARCHAR2,
                              p_address1_in             IN     VARCHAR2,
                              p_address2_in             IN     VARCHAR2,
                              p_city_in                 IN     VARCHAR2,
                              p_state_in                IN     VARCHAR2,
                              p_zip_in                  IN     VARCHAR2,
                              p_resp_code_out              OUT VARCHAR2,
                              p_resp_msg_out               OUT VARCHAR2,
                              p_auth_id_out                OUT VARCHAR2,
                              p_autherized_amount_out      OUT VARCHAR2,
                              p_balance_out                OUT VARCHAR2,
                              p_curr_out                   OUT VARCHAR2)
   AS
      l_proxunumber             cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_number             cms_appl_pan.cap_acct_no%TYPE;
      l_hash_pan                cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                cms_appl_pan.cap_pan_code_encr%TYPE;
      l_card_stat               cms_appl_pan.cap_card_stat%TYPE;
      l_firsttime_topup         cms_appl_pan.cap_firsttime_topup%TYPE;
      l_prfl_code               cms_appl_pan.cap_prfl_code%TYPE;
      l_prod_code               cms_appl_pan.cap_prod_code%TYPE;
      l_card_type               cms_appl_pan.cap_card_type%TYPE;
      l_acct_balance            cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal              cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type               cms_acct_mast.cam_type_code%TYPE;
      l_tran_amt                cms_acct_mast.cam_acct_bal%TYPE;
      l_redemption_delay_flag   cms_acct_mast.cam_redemption_delay_flag%TYPE;
      l_default_partial_indr    cms_prod_cattype.cpc_default_partial_indr%TYPE;
      l_trans_desc              cms_transaction_mast.ctm_tran_desc%TYPE;
      l_dr_cr_flag              cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_tran_type               cms_transaction_mast.ctm_tran_type%TYPE;
      l_prfl_flag               cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_currcode                gen_curr_mast.gcm_curr_code%TYPE;
      l_comb_hash               pkg_limits_check.type_hash;
      l_dupchk_cardstat         transactionlog.cardstatus%TYPE;
      l_dupchk_acctbal          transactionlog.acct_balance%TYPE;
      l_delayed_amount          NUMBER (9, 2) := 0;
      l_dupchk_count            NUMBER;
      l_txn_type                VARCHAR2 (2);
      l_tran_date               DATE;
      l_capture_date            DATE;
      l_resp_cde                VARCHAR2 (5);
      l_card_curr               VARCHAR2 (5);
      l_err_msg                 VARCHAR2 (900) := 'OK';
      l_rrn_count               NUMBER (10);
      l_fee_amt                 NUMBER := 0;
      exp_reject_record         EXCEPTION;
	  v_Retperiod  date;  --Added for VMS-5739/FSP-991
      v_Retdate  date; --Added for VMS-5739/FSP-991
   BEGIN
      BEGIN
         --SN : Convert clear card number to hash and encryped format.
         BEGIN
            l_hash_pan := gethash (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            l_encr_pan := fn_emaps_main (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Convert clear card number to hash and encryped format.

         --SN : Get currency code
         BEGIN
            SELECT gcm_curr_code
              INTO l_currcode
              FROM gen_curr_mast
             WHERE gcm_inst_code = p_inst_code_in
                   AND gcm_curr_name = p_curr_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                     'Error while selecting the currency code for '
                  || p_curr_code_in
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get currency code

         --SN : Get transaction details from master
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_type,
                   ctm_tran_desc,
                   ctm_prfl_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type,
                   l_trans_desc,
                   l_prfl_flag
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting transaction dtls from master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN : Get transaction details from master

         --SN : Get card details
         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_card_stat,
                   cap_proxy_number,
                   cap_acct_no,
                   cap_prfl_code,
                   cap_firsttime_topup
              INTO l_prod_code,
                   l_card_type,
                   l_card_stat,
                   l_proxunumber,
                   l_acct_number,
                   l_prfl_code,
                   l_firsttime_topup
              FROM cms_appl_pan
             WHERE     cap_pan_code = l_hash_pan
                   AND cap_mbr_numb = p_mbr_numb_in
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

         --EN : Get card details

         --SN : Transaction date-time check
         BEGIN
            l_tran_date :=
               TO_DATE (SUBSTR (TRIM (p_business_date_in), 1, 8), 'yyyymmdd');
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
                     SUBSTR (TRIM (p_business_date_in), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_business_time_in), 1, 10),
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

         --SN : Duplicate RRN check
         BEGIN
            SELECT NVL (cardstatus, 0), acct_balance
              INTO l_dupchk_cardstat, l_dupchk_acctbal
              FROM (  SELECT cardstatus, acct_balance
                        FROM VMSCMS.TRANSACTIONLOG                        --Added for VMS-5739/FSP-991
                       WHERE     rrn = p_rrn_in
                             AND customer_card_no = l_hash_pan
                             AND delivery_channel = p_delivery_channel_in
                             AND acct_balance IS NOT NULL
                    ORDER BY add_ins_date DESC)
             WHERE ROWNUM = 1;
			 	 IF SQL%ROWCOUNT = 0 THEN
				   SELECT NVL (cardstatus, 0), acct_balance
              INTO l_dupchk_cardstat, l_dupchk_acctbal
              FROM (  SELECT cardstatus, acct_balance
                        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                       --Added for VMS-5739/FSP-991
                       WHERE     rrn = p_rrn_in
                             AND customer_card_no = l_hash_pan
                             AND delivery_channel = p_delivery_channel_in
                             AND acct_balance IS NOT NULL
                    ORDER BY add_ins_date DESC)
             WHERE ROWNUM = 1;
				 END IF;

            l_dupchk_count := 1;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_dupchk_count := 0;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while selecting card status and acct balance from txnlog-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN : Get account balance details from acct master
         BEGIN
            SELECT cam_acct_bal,
                   cam_ledger_bal,
                   cam_type_code,
                   NVL (cam_redemption_delay_flag, 'N')
              INTO l_acct_balance,
                   l_ledger_bal,
                   l_acct_type,
                   l_redemption_delay_flag
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

         --Check for Balance
         IF NVL (l_acct_balance, 0) <= 0
         THEN
            l_resp_cde := '15';
            l_err_msg := 'Insufficient Funds';
            RAISE exp_reject_record;
         END IF;

         IF l_dupchk_count = 1
         THEN
            IF l_dupchk_cardstat = l_card_stat
               AND l_dupchk_acctbal = l_acct_balance
            THEN
               l_resp_cde := '22';
               l_err_msg := 'Duplicate Incomm Reference Number-' || p_rrn_in;
               RAISE exp_reject_record;
            ELSE
               l_dupchk_count := 0;
            END IF;
         END IF;

         --EN : Duplicate RRN check

         BEGIN
            SELECT NVL (cpc_default_partial_indr, 'N')
              INTO l_default_partial_indr
              FROM cms_prod_cattype
             WHERE     cpc_inst_code = p_inst_code_in
                   AND cpc_prod_code = l_prod_code
                   AND cpc_card_type = l_card_type;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting default partital indicator--'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN : Convert currency amt
         IF (l_tran_type = 'F')
         THEN
            IF (p_txn_amt_in >= 0)
            THEN
               BEGIN
                  sp_convert_curr (p_inst_code_in,
                                   l_currcode,
                                   p_card_no_in,
                                   p_txn_amt_in,
                                   l_tran_date,
                                   l_tran_amt,
                                   l_card_curr,
                                   l_err_msg,
                                   l_prod_code,
                                   l_card_type);

                  IF l_err_msg <> 'OK'
                  THEN
                     l_resp_cde := '65';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '89';
                     l_err_msg :=
                        'Error from currency conversion '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            ELSE
               l_resp_cde := '43';
               l_err_msg := 'INVALID AMOUNT';
               RAISE exp_reject_record;
            END IF;

            IF l_redemption_delay_flag = 'Y'
            THEN
               vmsredemptiondelay.check_delayed_load (l_acct_number,
                                                      l_delayed_amount,
                                                      l_err_msg);

               IF l_err_msg <> 'OK'
               THEN
                  RAISE exp_reject_record;
               END IF;
            END IF;

            --Check for partial approval
            IF (l_tran_amt > l_acct_balance - l_delayed_amount)
            THEN
               IF l_default_partial_indr = 'Y'
               THEN
                  l_tran_amt := l_acct_balance - l_delayed_amount;
               ELSE
                  l_resp_cde := '15';
                  l_err_msg := 'Insufficient Balance';
                  RAISE exp_reject_record;
               END IF;
            END IF;
         END IF;

         --EN : Convert currency amt

         --SN : Transaction limits check
         BEGIN
            IF (l_prfl_code IS NOT NULL AND l_prfl_flag = 'Y')
            THEN
               pkg_limits_check.sp_limits_check (l_hash_pan,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 p_txn_code_in,
                                                 l_tran_type,
                                                 NULL,
                                                 NULL,
                                                 p_inst_code_in,
                                                 NULL,
                                                 l_prfl_code,
                                                 l_tran_amt,
                                                 p_delivery_channel_in,
                                                 l_comb_hash,
                                                 l_resp_cde,
                                                 l_err_msg);
            END IF;

            IF l_resp_cde <> '00' AND l_err_msg <> 'OK'
            THEN
               IF l_resp_cde = '127'
               THEN
                  l_resp_cde := '140';
               ELSE
                  l_resp_cde := l_resp_cde;
               END IF;

               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while limits check-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Transaction limits check

         --SN : Autherization process
         BEGIN
            spil_authorize_txn_cms_auth (p_inst_code_in,
                                         p_msg_typ_in,
                                         p_rrn_in,
                                         p_delivery_channel_in,
                                         p_term_id_in,
                                         p_txn_code_in,
                                         p_txn_mode_in,
                                         p_business_date_in,
                                         p_business_time_in,
                                         p_card_no_in,
                                         l_tran_amt,
                                         p_merchant_name_in,
                                         NULL,
                                         NULL,
                                         l_currcode,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         p_stan_in,
                                         p_mbr_numb_in,
                                         p_rvsl_code_in,
                                         l_tran_amt,
                                         l_tran_amt,
                                         p_auth_id_out,
                                         l_resp_cde,
                                         l_err_msg,
                                         l_capture_date);

            IF l_resp_cde <> '00' AND l_err_msg <> 'OK'
            THEN
               --SN : Set out parameters
               p_auth_id_out := 0;
               p_curr_out := p_curr_code_in;
               p_autherized_amount_out := '0.00';
               p_balance_out :=
                  TO_CHAR (l_acct_balance, '99999999999999990.99');
               p_resp_code_out := l_resp_cde;
               p_resp_msg_out := l_err_msg;
               --EN : Set out parameters
               RETURN;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error from Card authorization-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         p_autherized_amount_out := l_tran_amt;

         --EN : Autherization process

         --SN : Reset limit count
         IF (l_prfl_code IS NOT NULL AND l_prfl_flag = 'Y')
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

         --EN : Reset limit count

         BEGIN
		 
		 --Added for VMS-5739/FSP-991
		 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			   INTO   v_Retperiod 
			   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
			   WHERE  OPERATION_TYPE='ARCHIVE' 
			   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
			   
			   v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');


		IF (v_Retdate>v_Retperiod)                                          --Added for VMS-5739/FSP-991
			THEN
		
            UPDATE transactionlog
               SET store_id = p_store_id_in,
                   --acct_balance = l_acct_balance,
                   --ledger_balance = l_ledger_bal,
                   spil_prod_id = p_product_id_in,
                   spil_fee = p_fee_amt_in,
                   spil_upc = p_upc_in,
                   spil_merref_num = p_mercrefnum_in,
                   spil_req_tmzm = p_reqtimezone_in,
                   spil_loc_cntry = p_localcountry_in,
                   spil_loc_crcy = p_localcurrency_in,
                   spil_loc_lang = p_loclanguage_in,
                   spil_pos_entry = p_posentry_in,
                   spil_pos_cond = p_poscond_in
             --error_msg = 'Success'
             WHERE     instcode = p_inst_code_in
                   AND rrn = p_rrn_in
                   AND customer_card_no = l_hash_pan
                   AND business_date = p_business_date_in
                   AND business_time = p_business_time_in
                   AND txn_code = p_txn_code_in
                   AND delivery_channel = p_delivery_channel_in;
				   
	     ELSE
		             UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST             --Added for VMS-5739/FSP-991
               SET store_id = p_store_id_in,
                   --acct_balance = l_acct_balance,
                   --ledger_balance = l_ledger_bal,
                   spil_prod_id = p_product_id_in,
                   spil_fee = p_fee_amt_in,
                   spil_upc = p_upc_in,
                   spil_merref_num = p_mercrefnum_in,
                   spil_req_tmzm = p_reqtimezone_in,
                   spil_loc_cntry = p_localcountry_in,
                   spil_loc_crcy = p_localcurrency_in,
                   spil_loc_lang = p_loclanguage_in,
                   spil_pos_entry = p_posentry_in,
                   spil_pos_cond = p_poscond_in
             --error_msg = 'Success'
             WHERE     instcode = p_inst_code_in
                   AND rrn = p_rrn_in
                   AND customer_card_no = l_hash_pan
                   AND business_date = p_business_date_in
                   AND business_time = p_business_time_in
                   AND txn_code = p_txn_code_in
                   AND delivery_channel = p_delivery_channel_in;
		 
		 END IF;

            IF SQL%ROWCOUNT = 0
            THEN
               l_err_msg := 'StoreId not updated in Transactionlog table';
               l_resp_cde := '21';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while Updating StoreId in Transactionlog table'
                  || SUBSTR (SQLERRM, 1, 200);
               l_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
		 
		 --Added for VMS-5739/FSP-991
		 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			   INTO   v_Retperiod 
			   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
			   WHERE  OPERATION_TYPE='ARCHIVE' 
			   AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
			   
			   v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');


		IF (v_Retdate>v_Retperiod)                 --Added for VMS-5739/FSP-991
			THEN
		 
            UPDATE cms_transaction_log_dtl
               SET ctd_store_address1 = p_address1_in,
                   ctd_store_address2 = p_address2_in,
                   ctd_store_city = p_city_in,
                   ctd_store_state = p_state_in,
                   ctd_store_zip = p_zip_in
             WHERE     ctd_inst_code = p_inst_code_in
                   AND ctd_rrn = p_rrn_in
                   AND ctd_customer_card_no = l_hash_pan
                   AND ctd_business_date = p_business_date_in
                   AND ctd_business_time = p_business_time_in
                   AND ctd_txn_code = p_txn_code_in
                   AND ctd_delivery_channel = p_delivery_channel_in;
				   
		ELSE
		
		UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST               --Added for VMS-5739/FSP-991
               SET ctd_store_address1 = p_address1_in,
                   ctd_store_address2 = p_address2_in,
                   ctd_store_city = p_city_in,
                   ctd_store_state = p_state_in,
                   ctd_store_zip = p_zip_in
             WHERE     ctd_inst_code = p_inst_code_in
                   AND ctd_rrn = p_rrn_in
                   AND ctd_customer_card_no = l_hash_pan
                   AND ctd_business_date = p_business_date_in
                   AND ctd_business_time = p_business_time_in
                   AND ctd_txn_code = p_txn_code_in
                   AND ctd_delivery_channel = p_delivery_channel_in;
		
		END IF;

            IF SQL%ROWCOUNT = 0
            THEN
               l_err_msg :=
                  'Address details not updated in Transactionlog table';
               l_resp_cde := '21';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while updating Address details in Transactionlog table'
                  || SUBSTR (SQLERRM, 1, 200);
               l_resp_cde := '21';
               RAISE exp_reject_record;
         END;


         --SN : Get b24 responsse code from response master
         l_resp_cde := '1';

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE     cms_inst_code = p_inst_code_in
                   AND cms_delivery_channel = p_delivery_channel_in
                   AND cms_response_id = TO_NUMBER (l_resp_cde);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Problem while selecting data from response master for respose code-'
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 200);
               l_resp_cde := '89';
               RAISE exp_reject_record;
         END;

         --EN : Get b24 responsse code from response master

         --SN : Set out parameters
         p_curr_out := p_curr_code_in;
         p_autherized_amount_out :=
            TO_CHAR (NVL (p_autherized_amount_out, 0),
                     '99999999999999990.99');
         p_resp_msg_out := 'Success';

         BEGIN
            SELECT cam_acct_bal
              INTO p_balance_out
              FROM cms_acct_mast
             WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting account balance from acct master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Set out parameters
         RETURN;
      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;

            --SN : Set out parameters
            BEGIN
               p_auth_id_out := 0;
               p_curr_out := p_curr_code_in;
               p_autherized_amount_out := '0.00';
               p_resp_msg_out := l_err_msg;

               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_inst_code_in
                      AND cms_delivery_channel = p_delivery_channel_in
                      AND cms_response_id = TO_NUMBER (l_resp_cde);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg_out :=
                        'Problem while selecting data from response master '
                     || l_resp_cde
                     || ' is-'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code_out := '89';
            END;
         --EN : Set out parameters
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_err_msg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            l_resp_cde := '89';

            --SN : Set out parameters
            BEGIN
               p_auth_id_out := 0;
               p_curr_out := p_curr_code_in;
               p_autherized_amount_out := '0.00';
               p_resp_msg_out := l_err_msg;

               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_inst_code_in
                      AND cms_delivery_channel = p_delivery_channel_in
                      AND cms_response_id = TO_NUMBER (l_resp_cde);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg_out :=
                        'Problem while selecting data from response master '
                     || l_resp_cde
                     || ' is-'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code_out := '89';
            END;
      --EN : Set out parameters
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_desc
              INTO l_dr_cr_flag, l_txn_type, l_trans_desc
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

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
                   AND cap_mbr_numb = p_mbr_numb_in
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

      p_balance_out := TO_CHAR (l_acct_balance, '99999999999999990.99');

      --SN : Make entry in transactionlog

      BEGIN
         INSERT INTO transactionlog (msgtype,
                                     rrn,
                                     delivery_channel,
                                     terminal_id,
                                     date_time,
                                     txn_code,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     response_code,
                                     business_date,
                                     business_time,
                                     customer_card_no,
                                     bank_code,
                                     total_amount,
                                     currencycode,
                                     productid,
                                     categoryid,
                                     auth_id,
                                     trans_desc,
                                     amount,
                                     system_trace_audit_no,
                                     instcode,
                                     tranfee_amt,
                                     cr_dr_flag,
                                     customer_card_no_encr,
                                     proxy_number,
                                     reversal_code,
                                     customer_acct_no,
                                     acct_balance,
                                     ledger_balance,
                                     response_id,
                                     merchant_name,
                                     add_ins_user,
                                     error_msg,
                                     cardstatus,
                                     store_id,
                                     time_stamp,
                                     acct_type,
                                     spil_prod_id,
                                     spil_fee,
                                     spil_upc,
                                     spil_merref_num,
                                     spil_req_tmzm,
                                     spil_loc_cntry,
                                     spil_loc_crcy,
                                     spil_loc_lang,
                                     spil_pos_entry,
                                     spil_pos_cond)
              VALUES (
                        p_msg_typ_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_term_id_in,
                        TRUNC (SYSDATE),
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        DECODE (p_resp_code_out, '00', 'C', 'F'),
                        p_resp_code_out,
                        p_business_date_in,
                        p_business_time_in,
                        l_hash_pan,
                        p_inst_code_in,
                        TRIM (TO_CHAR (p_txn_amt_in, '99999999999999990.99')),
                        l_currcode,
                        l_prod_code,
                        l_card_type,
                        p_auth_id_out,
                        l_trans_desc,
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999990.99')),
                           p_txn_amt_in),
                        p_stan_in,
                        p_inst_code_in,
                        l_fee_amt,
                        l_dr_cr_flag,
                        l_encr_pan,
                        l_proxunumber,
                        p_rvsl_code_in,
                        l_acct_number,
                        l_acct_balance,
                        l_ledger_bal,
                        l_resp_cde,
                        p_merchant_name_in,
                        p_lupduser_in,
                        p_resp_msg_out,
                        l_card_stat,
                        p_store_id_in,
                        SYSTIMESTAMP,
                        l_acct_type,
                        p_product_id_in,
                        p_fee_amt_in,
                        p_upc_in,
                        p_mercrefnum_in,
                        p_reqtimezone_in,
                        p_localcountry_in,
                        p_localcurrency_in,
                        p_loclanguage_in,
                        p_posentry_in,
                        p_poscond_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_resp_code_out := '89';
            p_resp_msg_out :=
               'Problem while inserting data into transaction log- '
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --EN : Make entry in transactionlog

      --SN : Make entry in cms_transaction_log_dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                              ctd_txn_code,
                                              ctd_txn_type,
                                              ctd_msg_type,
                                              ctd_txn_mode,
                                              ctd_business_date,
                                              ctd_business_time,
                                              ctd_customer_card_no,
                                              ctd_txn_amount,
                                              ctd_txn_curr,
                                              ctd_actual_amount,
                                              ctd_fee_amount,
                                              ctd_bill_amount,
                                              ctd_bill_curr,
                                              ctd_process_flag,
                                              ctd_process_msg,
                                              ctd_rrn,
                                              ctd_system_trace_audit_no,
                                              ctd_inst_code,
                                              ctd_customer_card_no_encr,
                                              ctd_cust_acct_number,
                                              ctd_ins_user,
                                              ctd_ins_date,
                                              ctd_store_address1,
                                              ctd_store_address2,
                                              ctd_store_city,
                                              ctd_store_state,
                                              ctd_store_zip)
              VALUES (
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_msg_typ_in,
                        p_txn_mode_in,
                        p_business_date_in,
                        p_business_time_in,
                        l_hash_pan,
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999999.99')),
                           p_txn_amt_in),
                        l_currcode,
                        TO_CHAR (NVL (p_txn_amt_in, 0), '99999999999990.99'),
                        l_fee_amt,
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999999.99')),
                           p_txn_amt_in),
                        l_card_curr,
                        'E',
                        p_resp_msg_out,
                        p_rrn_in,
                        p_stan_in,
                        p_inst_code_in,
                        l_encr_pan,
                        l_acct_number,
                        p_lupduser_in,
                        SYSDATE,
                        p_address1_in,
                        p_address2_in,
                        p_city_in,
                        p_state_in,
                        p_zip_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  dtl-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
            ROLLBACK;
      END;
   --EN : Make entry in cms_transaction_log_dtl

   --      IF l_dupchk_count = 1
   --      THEN
   --         BEGIN
   --            SELECT response_code
   --              INTO p_resp_code_out
   --              FROM transactionlog a,
   --                   (SELECT MIN (add_ins_date) mindate
   --                      FROM transactionlog
   --                     WHERE rrn = p_rrn_in AND acct_balance IS NOT NULL) b
   --             WHERE     a.add_ins_date = mindate
   --                   AND rrn = p_rrn_in
   --                   AND acct_balance IS NOT NULL;
   --         EXCEPTION
   --            WHEN OTHERS
   --            THEN
   --               p_resp_msg_out :=
   --                  'Problem in selecting the response detail of Original transaction-'
   --                  || SUBSTR (SQLERRM, 1, 300);
   --               p_resp_code_out := '89';
   --               ROLLBACK;
   --         END;
   --      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '89';
         p_resp_msg_out := 'Main Excp- ' || SUBSTR (SQLERRM, 1, 300);
   END card_redemption;

   PROCEDURE card_redemption_reversal (
      p_inst_code_in            IN     NUMBER,
      p_msg_typ_in              IN     VARCHAR2,
      p_rvsl_code_in            IN     VARCHAR2,
      p_rrn_in                  IN     VARCHAR2,
      p_delivery_channel_in     IN     VARCHAR2,
      p_terminal_id_in          IN     VARCHAR2,
      p_merc_id_in              IN     VARCHAR2,
      p_txn_code_in             IN     VARCHAR2,
      p_txn_type_in             IN     VARCHAR2,
      p_txn_mode_in             IN     VARCHAR2,
      p_business_date_in        IN     VARCHAR2,
      p_business_time_in        IN     VARCHAR2,
      p_card_no_in              IN     VARCHAR2,
      p_actual_amt_in           IN     NUMBER,
      p_stan_in                 IN     VARCHAR2,
      p_mbr_numb_in             IN     VARCHAR2,
      p_curr_code_in            IN     VARCHAR2,
      p_merchant_name_in        IN     VARCHAR2,
      p_store_id_in             IN     VARCHAR2,
      p_lupduser_in             IN     NUMBER,
      p_product_id_in           IN     VARCHAR2,
      p_fee_amt_in              IN     NUMBER,
      p_upc_in                  IN     VARCHAR2,
      p_mercrefnum_in           IN     VARCHAR2,
      p_reqtimezone_in          IN     VARCHAR2,
      p_localcountry_in         IN     VARCHAR2,
      p_localcurrency_in        IN     VARCHAR2,
      p_loclanguage_in          IN     VARCHAR2,
      p_posentry_in             IN     VARCHAR2,
      p_poscond_in              IN     VARCHAR2,
      p_address1_in             IN     VARCHAR2,
      p_address2_in             IN     VARCHAR2,
      p_city_in                 IN     VARCHAR2,
      p_state_in                IN     VARCHAR2,
      p_zip_in                  IN     VARCHAR2,
      p_resp_code_out              OUT VARCHAR2,
      p_resp_msg_out               OUT VARCHAR2,
      p_auth_id_out                OUT VARCHAR2,
      p_autherized_amount_out      OUT VARCHAR2,
      p_balance_out                OUT VARCHAR2,
      p_curr_out                   OUT VARCHAR2)
   AS
      l_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no                    cms_appl_pan.cap_acct_no%TYPE;
      l_prod_code                  cms_appl_pan.cap_prod_code%TYPE;
      l_card_type                  cms_appl_pan.cap_card_type%TYPE;
      l_prfl_code                  cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat                  cms_appl_pan.cap_card_stat%TYPE;
      l_proxy_number               cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_balance               cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_balance             cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type                  cms_acct_mast.cam_type_code%TYPE;
      l_orgnl_delivery_channel     transactionlog.delivery_channel%TYPE;
      l_orgnl_resp_code            transactionlog.response_code%TYPE;
      l_orgnl_txn_code             transactionlog.txn_code%TYPE;
      l_orgnl_txn_type             transactionlog.txn_type%TYPE;
      l_orgnl_txn_mode             transactionlog.txn_mode%TYPE;
      l_orgnl_terminal_id          transactionlog.terminal_id%TYPE;
      l_orgnl_business_date        transactionlog.business_date%TYPE;
      l_orgnl_business_time        transactionlog.business_time%TYPE;
      l_orgnl_customer_card_no     transactionlog.customer_card_no%TYPE;
      l_orgnl_total_amount         transactionlog.amount%TYPE;
      l_orgnl_txn_fee_plan         transactionlog.fee_plan%TYPE;
      l_orgnl_txn_feecode          cms_fee_mast.cfm_fee_code%TYPE;
      l_orgnl_txn_feeattachtype    transactionlog.feeattachtype%TYPE;
      l_orgnl_txn_totalfee_amt     transactionlog.tranfee_amt%TYPE;
      l_orgnl_txn_servicetax_amt   transactionlog.servicetax_amt%TYPE;
      l_orgnl_txn_cess_amt         transactionlog.cess_amt%TYPE;
      l_orgnl_transaction_type     transactionlog.cr_dr_flag%TYPE;
      l_orgnl_termid               transactionlog.terminal_id%TYPE;
      l_orgnl_mcccode              transactionlog.mccode%TYPE;
      l_actual_dispatched_amt      transactionlog.amount%TYPE;
      l_actual_feecode             transactionlog.feecode%TYPE;
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
      l_tran_reverse_flag          transactionlog.tran_reverse_flag%TYPE;
      l_curr_code                  transactionlog.currencycode%TYPE;
      l_auth_id                    transactionlog.auth_id%TYPE;
      l_dr_cr_flag                 transactionlog.cr_dr_flag%TYPE;
      l_orgnl_txn_amnt             transactionlog.amount%TYPE;
      l_add_ins_date               transactionlog.add_ins_date%TYPE;
      l_prfl_flag                  cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_tran_type                  cms_transaction_mast.ctm_tran_type%TYPE;
      l_internation_ind_response   transactionlog.internation_ind_response%TYPE;
      l_pos_verification           transactionlog.pos_verification%TYPE;
      l_orgnl_auth_id              transactionlog.auth_id%TYPE;
      l_txn_narration              cms_statements_log.csl_trans_narrration%TYPE;
      l_fee_narration              cms_statements_log.csl_trans_narrration%TYPE;
      l_txn_merchname              cms_statements_log.csl_merchant_name%TYPE;
      l_fee_merchname              cms_statements_log.csl_merchant_name%TYPE;
      l_txn_merchcity              cms_statements_log.csl_merchant_city%TYPE;
      l_fee_merchcity              cms_statements_log.csl_merchant_city%TYPE;
      l_txn_merchstate             cms_statements_log.csl_merchant_state%TYPE;
      l_fee_merchstate             cms_statements_log.csl_merchant_state%TYPE;
      l_hashkey_id                 cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_base_curr                  cms_inst_param.cip_param_value%TYPE;
      l_tran_desc                  cms_transaction_mast.ctm_tran_desc%TYPE;
      l_fee_plan                   cms_fee_plan.cfp_plan_id%TYPE;
      l_feecap_flag                cms_fee_mast.cfm_feecap_flag%TYPE;
      l_orgnl_fee_amt              cms_fee_mast.cfm_fee_amt%TYPE;
      l_fee_code                   cms_fee_mast.cfm_fee_code%TYPE;
      l_max_card_bal               cms_bin_param.cbp_param_value%TYPE;
      l_feeattach_type             VARCHAR2 (2);
      l_reversal_amt               NUMBER (9, 2);
      l_resp_cde                   VARCHAR2 (5);
      l_rvsl_trandate              DATE;
      l_tran_amt                   NUMBER;
      l_card_curr                  VARCHAR2 (5);
      l_currcode                   VARCHAR2 (3);
      l_timestamp                  TIMESTAMP (3);
      l_fee_amt                    NUMBER (9, 2);
      l_txn_type                   NUMBER (1);
      l_dupl_indc                  NUMBER (5) := 0;
      l_succ_orgnl_cnt             NUMBER (5) := 0;
      l_errmsg                     VARCHAR2 (300);
      exp_rvsl_reject_record       EXCEPTION;
    l_profile_code               cms_prod_cattype.cpc_profile_code%type;
    l_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
    l_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
    l_debit_reversal             vms_group_tran_detl.VGD_DEBIT_REVERSAL%TYPE;
    l_cap_card_stat              cms_appl_pan.cap_card_stat%TYPE   := '12';
	
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
	v_Retdate  date; --Added for VMS-5739/FSP-991
   BEGIN
      BEGIN
         l_tran_amt := p_actual_amt_in;

         --SN : Convert clear card number to hash and encryped format.
         BEGIN
            l_hash_pan := gethash (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_errmsg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            l_encr_pan := fn_emaps_main (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_errmsg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Convert clear card number to hash and encryped format.

         BEGIN
            SELECT ctm_credit_debit_flag,
                   ctm_tran_desc,                            --|| ' REVERSAL',
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_type,
                   ctm_prfl_flag
              INTO l_dr_cr_flag,
                   l_tran_desc,
                   l_txn_type,
                   l_tran_type,
                   l_prfl_flag
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Problem while selecting transactions dtls from master- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_acct_no,
                   cap_prfl_code,
                   cap_card_stat,
                   cap_proxy_number
              INTO l_prod_code,
                   l_card_type,
                   l_acct_no,
                   l_prfl_code,
                   l_card_stat,
                   l_proxy_number
              FROM cms_appl_pan
             WHERE     cap_inst_code = p_inst_code_in
                   AND cap_mbr_numb = p_mbr_numb_in
                   AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while retriving card detail-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;


         BEGIN
            l_rvsl_trandate :=
               TO_DATE (SUBSTR (TRIM (p_business_date_in), 1, 8), 'yyyymmdd');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '45';
               l_errmsg :=
                  'Problem while converting transaction date-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;
         BEGIN
            SELECT cpc_profile_code,cpc_badcredit_flag,cpc_badcredit_transgrpid
            into l_profile_code,l_badcredit_flag,l_badcredit_transgrpid
            FROM cms_prod_cattype
             WHERE     cpc_inst_code = p_inst_code_in
               AND cpc_prod_code = l_prod_code
             AND cpc_card_type = l_card_type;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '45';
               l_errmsg :=
                  'Problem while selecting from cms_prod_cattype'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            l_rvsl_trandate :=
               TO_DATE (
                     SUBSTR (TRIM (p_business_date_in), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_business_time_in), 1, 8),
                  'yyyymmdd hh24:mi:ss');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '32';
               l_errmsg :=
                  'Problem while converting transaction Time-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            p_auth_id_out := LPAD (seq_auth_id.NEXTVAL, 6, '0');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                  'Error while generating authid-'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            SELECT gcm_curr_code
              INTO l_currcode
              FROM gen_curr_mast
             WHERE gcm_inst_code=p_inst_code_in AND gcm_curr_name = p_curr_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                     'Error while selecting the currency code for '
                  || p_curr_code_in
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF (p_msg_typ_in NOT IN ('0400', '0410', '0420', '0430', '1420'))
            OR (p_rvsl_code_in = '00')
         THEN
            l_resp_cde := '127';
            l_errmsg := 'Invalid Request';
            RAISE exp_rvsl_reject_record;
         END IF;

         --SN : Get original transaction details
         BEGIN
            FOR l_idx
               IN (  SELECT delivery_channel,
                            txn_code,
                            txn_mode,
                            terminal_id,
                            business_date,
                            business_time,
                            customer_card_no,
                            amount,
                            feecode,
                            fee_plan,
                            feeattachtype,
                            tranfee_amt,
                            servicetax_amt,
                            cess_amt,
                            cr_dr_flag,
                            mccode,
                            tranfee_cr_acctno,
                            tranfee_dr_acctno,
                            tran_st_calc_flag,
                            tran_cess_calc_flag,
                            tran_st_cr_acctno,
                            tran_st_dr_acctno,
                            tran_cess_cr_acctno,
                            tran_cess_dr_acctno,
                            currencycode,
                            NVL (tran_reverse_flag, 'N') tran_reverse_flag,
                            pos_verification,
                            internation_ind_response,
                            add_ins_date,
                            DECODE (txn_type,  '1', 'F',  '0', 'N') txntype,
                            auth_id
                       FROM VMSCMS.TRANSACTIONLOG_VW                               --Added for VMS-5739/FSP-991
                      WHERE     rrn = p_rrn_in
                            AND customer_card_no = l_hash_pan
                            AND instcode = p_inst_code_in
                            AND response_code = '00'
                            AND msgtype IN ('1200', '1220')
                            AND txn_code = p_txn_code_in
                            AND delivery_channel = p_delivery_channel_in
                   ORDER BY time_stamp)
            LOOP
               l_succ_orgnl_cnt := l_succ_orgnl_cnt + 1;

               IF l_idx.tran_reverse_flag = 'N'
               THEN
                  l_orgnl_delivery_channel := l_idx.delivery_channel;
                  l_orgnl_txn_code := l_idx.txn_code;
                  l_orgnl_txn_mode := l_idx.txn_mode;
                  l_orgnl_terminal_id := l_idx.terminal_id;
                  l_orgnl_business_date := l_idx.business_date;
                  l_orgnl_business_time := l_idx.business_time;
                  l_orgnl_customer_card_no := l_idx.customer_card_no;
                  l_orgnl_total_amount := l_idx.amount;
                  l_orgnl_txn_feecode := l_idx.feecode;
                  l_orgnl_txn_fee_plan := l_idx.fee_plan;
                  l_orgnl_txn_feeattachtype := l_idx.feeattachtype;
                  l_orgnl_txn_totalfee_amt := l_idx.tranfee_amt;
                  l_orgnl_txn_servicetax_amt := l_idx.servicetax_amt;
                  l_orgnl_txn_cess_amt := l_idx.cess_amt;
                  l_orgnl_transaction_type := l_idx.cr_dr_flag;
                  l_orgnl_mcccode := l_idx.mccode;
                  l_actual_feecode := l_idx.feecode;
                  l_orgnl_tranfee_amt := l_idx.tranfee_amt;
                  l_orgnl_servicetax_amt := l_idx.servicetax_amt;
                  l_orgnl_cess_amt := l_idx.cess_amt;
                  l_orgnl_tranfee_cr_acctno := l_idx.tranfee_cr_acctno;
                  l_orgnl_tranfee_dr_acctno := l_idx.tranfee_dr_acctno;
                  l_orgnl_st_calc_flag := l_idx.tran_st_calc_flag;
                  l_orgnl_cess_calc_flag := l_idx.tran_cess_calc_flag;
                  l_orgnl_st_cr_acctno := l_idx.tran_st_cr_acctno;
                  l_orgnl_st_dr_acctno := l_idx.tran_st_dr_acctno;
                  l_orgnl_cess_cr_acctno := l_idx.tran_cess_cr_acctno;
                  l_orgnl_cess_dr_acctno := l_idx.tran_cess_dr_acctno;
                  l_curr_code := l_idx.currencycode;
                  l_orgnl_txn_amnt := l_idx.amount;
                  l_pos_verification := l_idx.pos_verification;
                  l_internation_ind_response := l_idx.internation_ind_response;
                  l_add_ins_date := l_idx.add_ins_date;
                  l_tran_type := l_idx.txntype;
                  l_orgnl_auth_id := l_idx.auth_id;
               ELSE
                  l_dupl_indc := 1;
               END IF;
            END LOOP;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '69';
               l_errmsg :=
                  'Problem while checking for original transaction-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Get original transaction details

         IF l_succ_orgnl_cnt = 0
         THEN
            l_resp_cde := '53';
            l_errmsg := 'Original transaction not found';
            RAISE exp_rvsl_reject_record;
         ELSE
            IF l_dupl_indc = 1
            THEN
               l_resp_cde := '52';
               l_errmsg :=
                  'The reversal already done for the original transaction';
               RAISE exp_rvsl_reject_record;
            END IF;
         END IF;

         --SN : Convert currency amt

         IF (p_actual_amt_in >= 0)
         THEN
            BEGIN
               sp_convert_curr (p_inst_code_in,
                                l_currcode,
                                p_card_no_in,
                                p_actual_amt_in,
                                l_rvsl_trandate,
                                l_tran_amt,
                                l_card_curr,
                                l_errmsg,
                                l_prod_code,
                                l_card_type);

               IF l_errmsg <> 'OK'
               THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_errmsg :=
                     'Error from currency conversion-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         ELSE
            l_resp_cde := '43';
            l_errmsg := 'INVALID AMOUNT';
            RAISE exp_rvsl_reject_record;
         END IF;

         --EN : Convert currency amt

         IF p_actual_amt_in > l_orgnl_txn_amnt
         THEN
            l_resp_cde := '59';
            l_errmsg :=
               'Reversal amount exceeds the original transaction amount';
            RAISE exp_rvsl_reject_record;
         END IF;

         l_actual_dispatched_amt := NVL (l_tran_amt, 0);

         l_reversal_amt := l_orgnl_total_amount - l_actual_dispatched_amt;

         IF l_dr_cr_flag = 'NA'
         THEN
            l_resp_cde := '21';
            l_errmsg := 'Not a valid original transaction for reversal';
            RAISE exp_rvsl_reject_record;
         END IF;

         --EN : Original txn details validation

         --SN : Get account balance details from acct master
         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO l_acct_balance, l_ledger_balance, l_acct_type
              FROM cms_acct_mast
             WHERE cam_acct_no = l_acct_no AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_errmsg :=
                  'Error while selecting account balance from acct master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Get account balance details from acct master
         --SN Max card balance check
         BEGIN
            SELECT TO_NUMBER (cbp_param_value)
              INTO l_max_card_bal
              FROM cms_bin_param
             WHERE cbp_inst_code = p_inst_code_in
                   AND cbp_param_name = 'Max Card Balance'
                   AND cbp_profile_code=l_profile_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'NO CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF ( (l_acct_balance + l_reversal_amt) > l_max_card_bal)
            OR ( (l_ledger_balance + l_reversal_amt) > l_max_card_bal)
         THEN
            IF l_card_stat <> '12'
            THEN
              if l_badcredit_flag='Y' then
                select vgd_debit_reversal
                into l_debit_reversal
                from  vms_group_tran_detl
                where vgd_group_id=l_badcredit_transgrpid;
                
                if l_debit_reversal='Y' then
                   l_cap_card_stat:='18';
                end if;
            end if;
               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_card_stat = l_cap_card_stat
                   WHERE     cap_inst_code = p_inst_code_in
                         AND cap_mbr_numb = p_mbr_numb_in
                         AND cap_pan_code = l_hash_pan;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     l_errmsg :=
                        'Error while updating the card status as suspended CR';
                     l_resp_cde := '21';
                     RAISE exp_rvsl_reject_record;
                  ELSE
                     BEGIN
                        sp_log_cardstat_chnge (p_inst_code_in,
                                               l_hash_pan,
                                               l_encr_pan,
                                               p_auth_id_out,
                                               '03',
                                               p_rrn_in,
                                               p_business_date_in,
                                               p_business_time_in,
                                               l_resp_cde,
                                               l_errmsg);

                        IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
                        THEN
                           RAISE exp_rvsl_reject_record;
                        END IF;

                        l_resp_cde := '1';
                     EXCEPTION
                        WHEN exp_rvsl_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           l_resp_cde := '21';
                           l_errmsg :=
                              'Error while logging system initiated card status change '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_rvsl_reject_record;
                     END;
                  END IF;
               EXCEPTION
                  WHEN exp_rvsl_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_errmsg :=
                        'Error while updating cms_appl_pan-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END IF;
         END IF;

         --EN Max card balance check
         BEGIN
		 
		 --Added for VMS-5739/FSP-991
		 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			   INTO   v_Retperiod 
			   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
			   WHERE  OPERATION_TYPE='ARCHIVE' 
			   AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
			   
			   v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


		IF (v_Retdate>v_Retperiod)                     --Added for VMS-5739/FSP-991
			THEN
			
            SELECT csl_trans_narrration,
                   csl_merchant_name,
                   csl_merchant_city,
                   csl_merchant_state
              INTO l_txn_narration,
                   l_txn_merchname,
                   l_txn_merchcity,
                   l_txn_merchstate
              FROM cms_statements_log
             WHERE     csl_business_date = l_orgnl_business_date
                   AND csl_business_time = l_orgnl_business_time
                   AND csl_rrn = p_rrn_in
                   AND csl_delivery_channel = l_orgnl_delivery_channel
                   AND csl_txn_code = l_orgnl_txn_code
                   AND csl_pan_no = l_orgnl_customer_card_no
                   AND csl_auth_id = l_orgnl_auth_id
                   AND csl_inst_code = p_inst_code_in
                   AND txn_fee_flag = 'N';
				   
	    ELSE
		
		 SELECT csl_trans_narrration,
                   csl_merchant_name,
                   csl_merchant_city,
                   csl_merchant_state
              INTO l_txn_narration,
                   l_txn_merchname,
                   l_txn_merchcity,
                   l_txn_merchstate
              FROM VMSCMS_HISTORY.cms_statements_log_HIST         --Added for VMS-5739/FSP-991
             WHERE     csl_business_date = l_orgnl_business_date
                   AND csl_business_time = l_orgnl_business_time
                   AND csl_rrn = p_rrn_in
                   AND csl_delivery_channel = l_orgnl_delivery_channel
                   AND csl_txn_code = l_orgnl_txn_code
                   AND csl_pan_no = l_orgnl_customer_card_no
                   AND csl_auth_id = l_orgnl_auth_id
                   AND csl_inst_code = p_inst_code_in
                   AND txn_fee_flag = 'N';
		
		END IF;
		
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_txn_narration := NULL;
            WHEN OTHERS
            THEN
               l_txn_narration := NULL;
         END;

         --         IF l_orgnl_txn_totalfee_amt > 0
         --         THEN
         --            BEGIN
         --               SELECT csl_trans_narrration,
         --                      csl_merchant_name,
         --                      csl_merchant_city,
         --                      csl_merchant_state
         --                 INTO l_fee_narration,
         --                      l_fee_merchname,
         --                      l_fee_merchcity,
         --                      l_fee_merchstate
         --                 FROM cms_statements_log
         --                WHERE     csl_business_date = l_orgnl_business_date
         --                      AND csl_business_time = l_orgnl_business_time
         --                      AND csl_rrn = p_rrn_in
         --                      AND csl_delivery_channel = l_orgnl_delivery_channel
         --                      AND csl_txn_code = l_orgnl_txn_code
         --                      AND csl_pan_no = l_orgnl_customer_card_no
         --                      AND csl_auth_id = l_orgnl_auth_id
         --                      AND csl_inst_code = p_inst_code_in
         --                      AND txn_fee_flag = 'Y';
         --            EXCEPTION
         --               WHEN NO_DATA_FOUND
         --               THEN
         --                  l_fee_narration := NULL;
         --               WHEN OTHERS
         --               THEN
         --                  l_fee_narration := NULL;
         --            END;
         --         END IF;


         l_timestamp := SYSTIMESTAMP;

         BEGIN
            sp_reverse_card_amount (p_inst_code_in,
                                    NULL,
                                    p_rrn_in,
                                    p_delivery_channel_in,
                                    l_orgnl_terminal_id,
                                    p_merc_id_in,
                                    p_txn_code_in,
                                    l_rvsl_trandate,
                                    p_txn_mode_in,
                                    p_card_no_in,
                                    l_reversal_amt,
                                    p_rrn_in,
                                    l_acct_no,
                                    p_business_date_in,
                                    p_business_time_in,
                                    p_auth_id_out,
                                    l_txn_narration,
                                    l_orgnl_business_date,
                                    l_orgnl_business_time,
                                    l_txn_merchname,
                                    l_txn_merchcity,
                                    l_txn_merchstate,
                                    l_resp_cde,
                                    l_errmsg);

            IF l_resp_cde <> '00' OR l_errmsg <> 'OK'
            THEN
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while reversing the amount-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF l_orgnl_txn_totalfee_amt > 0 OR l_orgnl_txn_feecode IS NOT NULL
         THEN
            BEGIN
               SELECT cfm_feecap_flag, cfm_fee_amt
                 INTO l_feecap_flag, l_orgnl_fee_amt
                 FROM cms_fee_mast
                WHERE cfm_inst_code = p_inst_code_in
                      AND cfm_fee_code = l_orgnl_txn_feecode;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_feecap_flag := '';
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error in feecap flag fetch-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

            FOR i
               IN (SELECT csl_trans_narrration,
                          csl_merchant_name,
                          csl_merchant_city,
                          csl_merchant_state,
                          csl_trans_amount
                     FROM VMSCMS.CMS_STATEMENTS_LOG_VW                          --Added for VMS-5739/FSP-991
                    WHERE     csl_business_date = l_orgnl_business_date
                          AND csl_business_time = l_orgnl_business_time
                          AND csl_rrn = p_rrn_in
                          AND csl_delivery_channel = l_orgnl_delivery_channel
                          AND csl_txn_code = l_orgnl_txn_code
                          AND csl_pan_no = l_orgnl_customer_card_no
                          AND csl_auth_id = l_orgnl_auth_id
                          AND csl_inst_code = p_inst_code_in
                          AND txn_fee_flag = 'Y')
            LOOP
               l_fee_narration := i.csl_trans_narrration;
               l_fee_merchname := i.csl_merchant_name;
               l_fee_merchcity := i.csl_merchant_city;
               l_fee_merchstate := i.csl_merchant_state;
               l_orgnl_tranfee_amt := i.csl_trans_amount;

               IF l_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_revcapcheck (p_inst_code_in,
                                               l_acct_no,
                                               l_orgnl_business_date,
                                               l_orgnl_tranfee_amt,
                                               l_orgnl_fee_amt,
                                               l_orgnl_txn_fee_plan,
                                               l_orgnl_txn_feecode,
                                               l_errmsg);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_resp_cde := '21';
                        l_errmsg :=
                           'Error while reversing the fee Cap amount-'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_rvsl_reject_record;
                  END;
               END IF;

               BEGIN
                  sp_reverse_fee_amount (p_inst_code_in,
                                         p_rrn_in,
                                         p_delivery_channel_in,
                                         l_orgnl_terminal_id,
                                         p_merc_id_in,
                                         p_txn_code_in,
                                         l_rvsl_trandate,
                                         p_txn_mode_in,
                                         l_orgnl_txn_totalfee_amt,
                                         p_card_no_in,
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
                                         p_rrn_in,
                                         l_acct_no,
                                         p_business_date_in,
                                         p_business_time_in,
                                         p_auth_id_out,
                                         l_fee_narration,
                                         l_fee_merchname,
                                         l_fee_merchcity,
                                         l_fee_merchstate,
                                         l_resp_cde,
                                         l_errmsg);

                  IF l_resp_cde <> '00' OR l_errmsg <> 'OK'
                  THEN
                     RAISE exp_rvsl_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_rvsl_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_errmsg :=
                        'Error while reversing the fee amount-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END LOOP;
         END IF;

         --SN : Reversal txn fee calc
         BEGIN
            sp_tran_reversal_fees (p_inst_code_in,
                                   p_card_no_in,
                                   p_delivery_channel_in,
                                   l_orgnl_txn_mode,
                                   p_txn_code_in,
                                   p_curr_code_in,
                                   NULL,
                                   NULL,
                                   l_reversal_amt,
                                   p_business_date_in,
                                   p_business_time_in,
                                   NULL,
                                   NULL,
                                   l_resp_cde,
                                   p_msg_typ_in,
                                   p_mbr_numb_in,
                                   p_rrn_in,
                                   p_terminal_id_in,
                                   l_txn_merchname,
                                   l_txn_merchcity,
                                   p_auth_id_out,
                                   l_fee_merchstate,
                                   p_rvsl_code_in,
                                   l_txn_narration,
                                   l_txn_type,
                                   l_rvsl_trandate,
                                   l_errmsg,
                                   l_resp_cde,
                                   l_fee_amt,
                                   l_fee_plan,
                                   l_fee_code,
                                   l_feeattach_type);

            IF l_errmsg <> 'OK'
            THEN
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while tran_reversal_fees process-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Reversal txn fee calc

         --SN : Reverse free fee count
         IF l_orgnl_txn_totalfee_amt = 0 AND l_orgnl_txn_feecode IS NOT NULL
         THEN
            BEGIN
               vmsfee.fee_freecnt_reverse (l_acct_no,
                                           l_orgnl_txn_feecode,
                                           l_errmsg);

               IF l_errmsg <> 'OK'
               THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_errmsg :=
                     'Error while reversing freefee count-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;

         --EN : Reverse free fee count

         --SN : Reset limit count
         BEGIN
            IF     l_add_ins_date IS NOT NULL
               AND l_prfl_code IS NOT NULL
               AND l_prfl_flag = 'Y'
            THEN
               pkg_limits_check.sp_limitcnt_rever_reset (
                  p_inst_code_in,
                  NULL,
                  NULL,
                  l_orgnl_mcccode,
                  l_orgnl_txn_code,
                  l_tran_type,
                  l_internation_ind_response,
                  l_pos_verification,
                  l_prfl_code,
                  l_reversal_amt,
                  l_orgnl_txn_amnt,
                  p_delivery_channel_in,
                  l_hash_pan,
                  l_add_ins_date,
                  l_resp_cde,
                  l_errmsg);
            END IF;

            IF l_errmsg <> 'OK'
            THEN
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error from Limit count reveer Process-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Reset limit count

         BEGIN
		 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)                                         --Added for VMS-5739/FSP-991

    THEN

            UPDATE cms_statements_log
               SET csl_prod_code = l_prod_code,
                   csl_acct_type = l_acct_type,
                   csl_card_type = l_card_type,
                   csl_time_stamp = l_timestamp
             WHERE     csl_inst_code = p_inst_code_in
                   AND csl_pan_no = l_hash_pan
                   AND csl_rrn = p_rrn_in
                   AND csl_txn_code = p_txn_code_in
                   AND csl_delivery_channel = p_delivery_channel_in
                   AND csl_auth_id = p_auth_id_out
                   AND csl_business_date = p_business_date_in
                   AND csl_business_time = p_business_time_in;
				   
				   
				   ELSE
				   
				   UPDATE VMSCMS_HISTORY.cms_statements_log_HIST --Added for VMS-5739/FSP-991

               SET csl_prod_code = l_prod_code,
                   csl_acct_type = l_acct_type,
                   csl_card_type = l_card_type,
                   csl_time_stamp = l_timestamp
             WHERE     csl_inst_code = p_inst_code_in
                   AND csl_pan_no = l_hash_pan
                   AND csl_rrn = p_rrn_in
                   AND csl_txn_code = p_txn_code_in
                   AND csl_delivery_channel = p_delivery_channel_in
                   AND csl_auth_id = p_auth_id_out
                   AND csl_business_date = p_business_date_in
                   AND csl_business_time = p_business_time_in;
				   
				   END IF ;
				   

            IF SQL%ROWCOUNT = 0
            THEN
               NULL;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while updating timestamp in statementlog-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --SN : Update reversal flag for txn
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
		 
            UPDATE transactionlog
               SET tran_reverse_flag = 'Y'
             WHERE     rrn = p_rrn_in
                   AND business_date = l_orgnl_business_date
                   AND business_time = l_orgnl_business_time
                   AND response_code = '00'
                   AND customer_card_no = l_hash_pan
                   AND instcode = p_inst_code_in
                   AND auth_id = l_orgnl_auth_id
                   AND NVL (tran_reverse_flag, 'N') <> 'Y';
               ELSE    


                UPDATE   VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5739/FSP-991

               SET tran_reverse_flag = 'Y'
             WHERE     rrn = p_rrn_in
                   AND business_date = l_orgnl_business_date
                   AND business_time = l_orgnl_business_time
                   AND response_code = '00'
                   AND customer_card_no = l_hash_pan
                   AND instcode = p_inst_code_in
                   AND auth_id = l_orgnl_auth_id
                   AND NVL (tran_reverse_flag, 'N') <> 'Y';			   
			   
			   END IF;
			   
            IF SQL%ROWCOUNT = 0
            THEN
               l_resp_cde := '52';
               l_errmsg := 'Reversal/Deactivation already done';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while updating txn reversal flag- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Update reversal flag for txn

         --SN : Get b24 responsse code from response master
         l_resp_cde := '1';

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE     cms_inst_code = p_inst_code_in
                   AND cms_delivery_channel = p_delivery_channel_in
                   AND cms_response_id = TO_NUMBER (l_resp_cde);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                  'Problem while selecting data from response master for respose code'
                  || l_resp_cde
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '69';
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Get b24 responsse code from response master

         --SN : Set out parameters
         p_curr_out := p_curr_code_in;
         p_autherized_amount_out :=
            TO_CHAR (l_reversal_amt, '99999999999999990.99');
         p_resp_msg_out := 'OK';
         --EN : Set out parameters
         l_tran_amt := l_reversal_amt;
      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_rvsl_reject_record
         THEN
            ROLLBACK;

            --SN : Set out parameters
            p_auth_id_out := 0;
            p_curr_out := p_curr_code_in;
            p_autherized_amount_out := '0.00';
            p_resp_msg_out := l_errmsg;

            IF l_dupl_indc = 1
            THEN
               BEGIN
			   
                  SELECT response_code
                    INTO p_resp_code_out
                    FROM VMSCMS.TRANSACTIONLOG_VW a,
                         (SELECT MIN (add_ins_date) mindate                                    --Added for VMS-5739/FSP-991
                            FROM VMSCMS.TRANSACTIONLOG_VW
                           WHERE rrn = p_rrn_in AND acct_balance IS NOT NULL) b
                   WHERE     a.add_ins_date = mindate
                         AND rrn = p_rrn_in
                         AND acct_balance IS NOT NULL;
						
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_resp_msg_out :=
                        'Problem in selecting the response detail of Original transaction-'
                        || SUBSTR (SQLERRM, 1, 300);
                     p_resp_code_out := '89';
                     ROLLBACK;
               END;
            ELSE
               BEGIN
                  SELECT cms_iso_respcde
                    INTO p_resp_code_out
                    FROM cms_response_mast
                   WHERE     cms_inst_code = p_inst_code_in
                         AND cms_delivery_channel = p_delivery_channel_in
                         AND cms_response_id = TO_NUMBER (l_resp_cde);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_resp_msg_out :=
                        'Problem while selecting data from response master '
                        || l_resp_cde
                        || ' is-'
                        || SUBSTR (SQLERRM, 1, 300);
                     p_resp_code_out := '89';
               END;
            END IF;
         --EN : Set out parameters
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            l_resp_cde := '89';

            --SN : Set out parameters
            BEGIN
               p_auth_id_out := 0;
               p_curr_out := p_curr_code_in;
               p_autherized_amount_out := '0.00';
               p_resp_msg_out := l_errmsg;

               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_inst_code_in
                      AND cms_delivery_channel = p_delivery_channel_in
                      AND cms_response_id = TO_NUMBER (l_resp_cde);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg_out :=
                        'Problem while selecting data from response master '
                     || l_resp_cde
                     || ' is-'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code_out := '89';
            END;
      --EN : Set out parameters
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_desc
              INTO l_dr_cr_flag, l_txn_type, l_tran_desc
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

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
                   l_acct_no,
                   l_proxy_number
              FROM cms_appl_pan
             WHERE     cap_pan_code = l_hash_pan
                   AND cap_mbr_numb = p_mbr_numb_in
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
           INTO l_acct_balance, l_ledger_balance, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_no AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_balance := 0;
            l_ledger_balance := 0;
      END;

      --EN : Get balance details from acct master

      p_balance_out := TO_CHAR (l_acct_balance, '99999999999999990.99');

      --SN : Make entry in transactionlog
      BEGIN
         INSERT INTO transactionlog (msgtype,
                                     rrn,
                                     delivery_channel,
                                     terminal_id,
                                     date_time,
                                     txn_code,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     response_code,
                                     business_date,
                                     business_time,
                                     customer_card_no,
                                     bank_code,
                                     total_amount,
                                     currencycode,
                                     productid,
                                     categoryid,
                                     auth_id,
                                     trans_desc,
                                     amount,
                                     system_trace_audit_no,
                                     instcode,
                                     tranfee_amt,
                                     feecode,
                                     fee_plan,
                                     feeattachtype,
                                     cr_dr_flag,
                                     customer_card_no_encr,
                                     proxy_number,
                                     reversal_code,
                                     customer_acct_no,
                                     acct_balance,
                                     ledger_balance,
                                     response_id,
                                     merchant_name,
                                     add_ins_user,
                                     error_msg,
                                     cardstatus,
                                     store_id,
                                     time_stamp,
                                     acct_type,
                                     spil_prod_id,
                                     spil_fee,
                                     spil_upc,
                                     spil_merref_num,
                                     spil_req_tmzm,
                                     spil_loc_cntry,
                                     spil_loc_crcy,
                                     spil_loc_lang,
                                     spil_pos_entry,
                                     spil_pos_cond)
              VALUES (
                        p_msg_typ_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_terminal_id_in,
                        TRUNC (SYSDATE),
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        DECODE (p_resp_code_out, '00', 'C', 'F'),
                        p_resp_code_out,
                        p_business_date_in,
                        p_business_time_in,
                        l_hash_pan,
                        p_inst_code_in,
                        TRIM (
                           TO_CHAR (
                              DECODE (
                                 p_resp_code_out,
                                 '00', (l_reversal_amt
                                        + l_orgnl_txn_totalfee_amt),
                                 l_tran_amt),
                              '999999999999999990.99')),
                        l_currcode,
                        l_prod_code,
                        l_card_type,
                        p_auth_id_out,
                        l_tran_desc,
                        TRIM (
                           TO_CHAR (
                              DECODE (p_resp_code_out,
                                      '00', l_reversal_amt,
                                      l_tran_amt),
                              '999999999999999990.99')),
                        p_stan_in,
                        p_inst_code_in,
                        NVL (TO_CHAR (l_fee_amt, '99999999999999990.99'),
                             '0.00'),
                        l_fee_code,
                        l_fee_plan,
                        l_feeattach_type,
                        DECODE (l_dr_cr_flag,
                                'CR', 'DR',
                                'DR', 'CR',
                                l_dr_cr_flag),
                        l_encr_pan,
                        l_proxy_number,
                        p_rvsl_code_in,
                        l_acct_no,
                        l_acct_balance,
                        l_ledger_balance,
                        l_resp_cde,
                        p_merchant_name_in,
                        p_lupduser_in,
                        p_resp_msg_out,
                        l_card_stat,
                        p_store_id_in,
                        NVL (l_timestamp, SYSTIMESTAMP),
                        l_acct_type,
                        p_product_id_in,
                        p_fee_amt_in,
                        p_upc_in,
                        p_mercrefnum_in,
                        p_reqtimezone_in,
                        p_localcountry_in,
                        p_localcurrency_in,
                        p_loclanguage_in,
                        p_posentry_in,
                        p_poscond_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_resp_code_out := '89';
            p_resp_msg_out :=
               'Problem while inserting data into transaction log- '
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --EN : Make entry in transactionlog
      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_channel_in
               || p_txn_code_in
               || p_card_no_in
               || p_rrn_in
               || TO_CHAR (NVL (l_timestamp, SYSTIMESTAMP),
                           'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            p_resp_msg_out :=
               'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      --SN : Make entry in cms_transaction_log_dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                              ctd_txn_code,
                                              ctd_txn_type,
                                              ctd_msg_type,
                                              ctd_txn_mode,
                                              ctd_business_date,
                                              ctd_business_time,
                                              ctd_customer_card_no,
                                              ctd_txn_amount,
                                              ctd_txn_curr,
                                              ctd_actual_amount,
                                              ctd_fee_amount,
                                              ctd_bill_amount,
                                              ctd_bill_curr,
                                              ctd_process_flag,
                                              ctd_process_msg,
                                              ctd_rrn,
                                              ctd_system_trace_audit_no,
                                              ctd_inst_code,
                                              ctd_customer_card_no_encr,
                                              ctd_cust_acct_number,
                                              ctd_hashkey_id,
                                              ctd_ins_user,
                                              ctd_ins_date,
                                              ctd_store_address1,
                                              ctd_store_address2,
                                              ctd_store_city,
                                              ctd_store_state,
                                              ctd_store_zip)
              VALUES (
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_msg_typ_in,
                        p_txn_mode_in,
                        p_business_date_in,
                        p_business_time_in,
                        l_hash_pan,
                        TRIM (
                           TO_CHAR (NVL (l_tran_amt, p_actual_amt_in),
                                    '99999999999990.99')),
                        l_currcode,
                        TO_CHAR (NVL (l_reversal_amt, p_actual_amt_in),
                                 '99999999999990.99'),
                        NVL (TO_CHAR (l_fee_amt, '99999999999999990.99'),
                             '0.00'),
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999999.99')),
                           p_actual_amt_in),
                        l_card_curr,
                        DECODE (p_resp_code_out, '00', 'Y', 'E'),
                        DECODE (p_resp_code_out,
                                '00', 'Successful',
                                p_resp_msg_out),
                        p_rrn_in,
                        p_stan_in,
                        p_inst_code_in,
                        l_encr_pan,
                        l_acct_no,
                        l_hashkey_id,
                        p_lupduser_in,
                        SYSDATE,
                        p_address1_in,
                        p_address2_in,
                        p_city_in,
                        p_state_in,
                        p_zip_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  dtl-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
            ROLLBACK;
      END;

      --EN : Make entry in cms_transaction_log_dtl
      IF p_resp_msg_out = 'OK'
      THEN
         p_resp_msg_out := 'Success';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '89';
         p_resp_msg_out := 'Main Excp- ' || SUBSTR (SQLERRM, 1, 300);
   END card_redemption_reversal;

   PROCEDURE redemption_lock (p_inst_code_in            IN     NUMBER,
                              p_msg_typ_in              IN     VARCHAR2,
                              p_rrn_in                  IN     VARCHAR2,
                              p_delivery_channel_in     IN     VARCHAR2,
                              p_term_id_in              IN     VARCHAR2,
                              p_txn_code_in             IN     VARCHAR2,
                              p_txn_mode_in             IN     VARCHAR2,
                              p_business_date_in        IN     VARCHAR2,
                              p_business_time_in        IN     VARCHAR2,
                              p_card_no_in              IN     VARCHAR2,
                              p_txn_amt_in              IN     NUMBER,
                              p_merchant_name_in        IN     VARCHAR2,
                              p_mcc_code_in             IN     VARCHAR2,
                              p_curr_code_in            IN     VARCHAR2,
                              p_pos_verfication_in      IN     VARCHAR2,
                              p_stan_in                 IN     VARCHAR2,
                              p_rvsl_code_in            IN     VARCHAR2,
                              p_international_ind_in    IN     VARCHAR2,
                              p_store_id_in             IN     VARCHAR2,
                              p_product_id_in           IN     VARCHAR2,
                              p_fee_amt_in              IN     NUMBER,
                              p_upc_in                  IN     VARCHAR2,
                              p_mercrefnum_in           IN     VARCHAR2,
                              p_reqtimezone_in          IN     VARCHAR2,
                              p_localcountry_in         IN     VARCHAR2,
                              p_localcurrency_in        IN     VARCHAR2,
                              p_loclanguage_in          IN     VARCHAR2,
                              p_posentry_in             IN     VARCHAR2,
                              p_poscond_in              IN     VARCHAR2,
                              p_address1_in             IN     VARCHAR2,
                              p_address2_in             IN     VARCHAR2,
                              p_city_in                 IN     VARCHAR2,
                              p_state_in                IN     VARCHAR2,
                              p_zip_in                  IN     VARCHAR2,
                              p_resp_code_out              OUT VARCHAR2,
                              p_resp_msg_out               OUT VARCHAR2,
                              p_auth_id_out                OUT VARCHAR2,
                              p_autherized_amount_out      OUT VARCHAR2,
                              p_balance_out                OUT VARCHAR2,
                              p_proxyno_out                OUT VARCHAR2)
   AS
      l_proxunumber               cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_number               cms_appl_pan.cap_acct_no%TYPE;
      l_hash_pan                  cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                  cms_appl_pan.cap_pan_code_encr%TYPE;
      l_card_stat                 cms_appl_pan.cap_card_stat%TYPE;
      l_firsttime_topup           cms_appl_pan.cap_firsttime_topup%TYPE;
      l_prfl_code                 cms_appl_pan.cap_prfl_code%TYPE;
      l_prod_code                 cms_appl_pan.cap_prod_code%TYPE;
      l_card_type                 cms_appl_pan.cap_card_type%TYPE;
      l_expry_date                cms_appl_pan.cap_expry_date%TYPE;
      l_acct_balance              cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal                cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type                 cms_acct_mast.cam_type_code%TYPE;
      l_tran_amt                  cms_acct_mast.cam_acct_bal%TYPE;
      l_redemption_delay_flag     cms_acct_mast.cam_redemption_delay_flag%TYPE;
      l_default_partial_indr      cms_prod_cattype.cpc_default_partial_indr%TYPE;
      l_trans_desc                cms_transaction_mast.ctm_tran_desc%TYPE;
      l_dr_cr_flag                cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_tran_type                 cms_transaction_mast.ctm_tran_type%TYPE;
      l_prfl_flag                 cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_tran_preauth_flag         cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_login_txn                 cms_transaction_mast.ctm_login_txn%TYPE;
      l_preauth_type              cms_transaction_mast.ctm_preauth_type%TYPE;
      l_precheck_flag             pcms_tranauth_param.ptp_param_value%TYPE;
      l_preauth_flag              pcms_tranauth_param.ptp_param_value%TYPE;
      l_currcode                  gen_curr_mast.gcm_curr_code%TYPE;
      l_dupchk_cardstat           transactionlog.cardstatus%TYPE;
      l_dupchk_acctbal            transactionlog.acct_balance%TYPE;
      l_fee_plan                  transactionlog.fee_plan%TYPE;
      l_feeattach_type            transactionlog.feeattachtype%TYPE;
      l_tranfee_amt               transactionlog.tranfee_amt%TYPE;
      l_total_amt                 transactionlog.total_amount%TYPE;
      l_narration                 cms_statements_log.csl_trans_narrration%TYPE;
      l_comb_hash                 pkg_limits_check.type_hash;
      l_fee_code                  cms_fee_mast.cfm_fee_code%TYPE;
      l_preauth_exp_period        cms_prod_mast.cpm_pre_auth_exp_date%TYPE;
      l_fee_crgl_catg             cms_prodcattype_fees.cpf_crgl_catg%TYPE;
      l_fee_crgl_code             cms_prodcattype_fees.cpf_crgl_code%TYPE;
      l_fee_crsubgl_code          cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
      l_fee_cracct_no             cms_prodcattype_fees.cpf_cracct_no%TYPE;
      l_fee_drgl_catg             cms_prodcattype_fees.cpf_drgl_catg%TYPE;
      l_fee_drgl_code             cms_prodcattype_fees.cpf_drgl_code%TYPE;
      l_fee_drsubgl_code          cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
      l_fee_dracct_no             cms_prodcattype_fees.cpf_dracct_no%TYPE;
      l_st_calc_flag              cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
      l_cess_calc_flag            cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
      l_st_cracct_no              cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
      l_st_dracct_no              cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
      l_cess_cracct_no            cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
      l_cess_dracct_no            cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
      l_waiv_percnt               cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
      l_feeamnt_type              cms_fee_mast.cfm_feeamnt_type%TYPE;
      l_clawback                  cms_fee_mast.cfm_clawback_flag%TYPE;
      l_per_fees                  cms_fee_mast.cfm_per_fees%TYPE;
      l_flat_fees                 cms_fee_mast.cfm_fee_amt%TYPE;
      l_fee_desc                  cms_fee_mast.cfm_fee_desc%TYPE;
      l_servicetax_percent        cms_inst_param.cip_param_value%TYPE;
      l_cess_percent              cms_inst_param.cip_param_value%TYPE;
      l_comp_txn_code             cms_preauthcomp_txncode.cpt_compl_txncode%TYPE;
      l_comp_fee_code             cms_fee_mast.cfm_fee_code%TYPE;
      l_comp_fee_crgl_catg        cms_prodcattype_fees.cpf_crgl_catg%TYPE;
      l_comp_fee_crgl_code        cms_prodcattype_fees.cpf_crgl_code%TYPE;
      l_comp_fee_crsubgl_code     cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
      l_comp_fee_cracct_no        cms_prodcattype_fees.cpf_cracct_no%TYPE;
      l_comp_fee_drgl_catg        cms_prodcattype_fees.cpf_drgl_catg%TYPE;
      l_comp_fee_drgl_code        cms_prodcattype_fees.cpf_drgl_code%TYPE;
      l_comp_fee_drsubgl_code     cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
      l_comp_fee_dracct_no        cms_prodcattype_fees.cpf_dracct_no%TYPE;
      l_comp_servicetax_percent   cms_inst_param.cip_param_value%TYPE;
      l_comp_cess_percent         cms_inst_param.cip_param_value%TYPE;
      l_comp_st_calc_flag         cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
      l_comp_cess_calc_flag       cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
      l_comp_st_cracct_no         cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
      l_comp_st_dracct_no         cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
      l_comp_cess_cracct_no       cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
      l_comp_cess_dracct_no       cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
      l_comp_waiv_percnt          cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
      l_comp_feeamnt_type         cms_fee_mast.cfm_feeamnt_type%TYPE;
      l_comp_per_fees             cms_fee_mast.cfm_per_fees%TYPE;
      l_comp_flat_fees            cms_fee_mast.cfm_fee_amt%TYPE;
      l_comp_clawback             cms_fee_mast.cfm_clawback_flag%TYPE;
      l_comp_fee_desc             cms_fee_mast.cfm_fee_desc%TYPE;
      l_comp_fee_plan             cms_fee_feeplan.cff_fee_plan%TYPE;
      l_hashkey_id                cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_comp_fee_amt              NUMBER (9, 2);
      l_comp_total_fee            NUMBER (9, 2) := 0;
      l_comp_servicetax_amount    NUMBER (9, 2);
      l_comp_cess_amount          NUMBER (9, 2);
      l_comp_freetxn_exceed       VARCHAR2 (1);
      l_comp_duration             VARCHAR2 (20);
      l_comp_feeattach_type       VARCHAR2 (2);
      l_comlfree_flag             VARCHAR2 (1);
      l_preauth_hold              VARCHAR2 (2);
      l_preauth_date              DATE;
      l_preauth_period            NUMBER;
      l_fee_amt                   NUMBER (9, 2);
      l_total_fee                 NUMBER (9, 2);
      l_tot_hold_amt              NUMBER (9, 2);
      l_servicetax_amount         NUMBER (9, 2);
      l_cess_amount               NUMBER (9, 2);
      l_freetxn_exceed            VARCHAR2 (1);
      l_delayed_amount            NUMBER (9, 2) := 0;
      l_duration                  VARCHAR2 (20);
      l_dupchk_count              NUMBER;
      l_card_curr                 VARCHAR2 (5);
      l_txn_type                  VARCHAR2 (2);
      l_tran_date                 DATE;
      l_status_chk                NUMBER;
      l_time_stamp                TIMESTAMP;
      l_resp_cde                  VARCHAR2 (5);
      l_err_msg                   VARCHAR2 (900) := 'OK';
      exp_reject_record           EXCEPTION;
	  
	  
	  
   BEGIN
      BEGIN
         l_tran_amt := NVL (ROUND (p_txn_amt_in, 2), 0);

         --SN : Convert clear card number to hash and encryped format.
         BEGIN
            l_hash_pan := gethash (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            l_encr_pan := fn_emaps_main (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Convert clear card number to hash and encryped format.

         --SN : Get currency code
         BEGIN
            SELECT gcm_curr_code
              INTO l_currcode
              FROM gen_curr_mast
             WHERE gcm_inst_code = p_inst_code_in
                   AND gcm_curr_name = p_curr_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                     'Error while selecting the currency code for '
                  || p_curr_code_in
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get currency code

         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO p_auth_id_out
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
                   l_tran_preauth_flag,
                   l_login_txn,
                   l_preauth_type
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting transaction dtls from master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN : Get transaction details from master
         --SN : Get card details
         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_card_stat,
                   cap_proxy_number,
                   cap_acct_no,
                   cap_prfl_code,
                   cap_firsttime_topup,
                   cap_expry_date
              INTO l_prod_code,
                   l_card_type,
                   l_card_stat,
                   l_proxunumber,
                   l_acct_number,
                   l_prfl_code,
                   l_firsttime_topup,
                   l_expry_date
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


         p_proxyno_out := l_proxunumber;

         --EN : Get card details

         IF l_tran_amt <= 0
         THEN
            l_resp_cde := '43';
            l_err_msg := 'Invalid Amount';
            RAISE exp_reject_record;
         END IF;

         --SN : Transaction date-time check
         BEGIN
            l_tran_date :=
               TO_DATE (SUBSTR (TRIM (p_business_date_in), 1, 8), 'yyyymmdd');
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
                     SUBSTR (TRIM (p_business_date_in), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_business_time_in), 1, 10),
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

         --SN : Duplicate RRN check
         BEGIN
            SELECT NVL (cardstatus, 0), acct_balance
              INTO l_dupchk_cardstat, l_dupchk_acctbal
              FROM (  SELECT cardstatus, acct_balance
                        FROM VMSCMS.TRANSACTIONLOG                      --Added for VMS-5739/FSP-991
                       WHERE     rrn = p_rrn_in
                             AND customer_card_no = l_hash_pan
                             AND delivery_channel = p_delivery_channel_in
                             AND acct_balance IS NOT NULL
                    ORDER BY add_ins_date DESC)
             WHERE ROWNUM = 1;
			 IF SQL%ROWCOUNT = 0 THEN
			     SELECT NVL (cardstatus, 0), acct_balance
              INTO l_dupchk_cardstat, l_dupchk_acctbal
              FROM (  SELECT cardstatus, acct_balance
                        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                     --Added for VMS-5739/FSP-991
                       WHERE     rrn = p_rrn_in
                             AND customer_card_no = l_hash_pan
                             AND delivery_channel = p_delivery_channel_in
                             AND acct_balance IS NOT NULL
                    ORDER BY add_ins_date DESC)
             WHERE ROWNUM = 1;
			 END IF;

            l_dupchk_count := 1;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_dupchk_count := 0;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while selecting card status and acct balance from txnlog-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN : Get account balance details from acct master
         BEGIN
            SELECT cam_acct_bal,
                   cam_ledger_bal,
                   cam_type_code,
                   NVL (cam_redemption_delay_flag, 'N')
              INTO l_acct_balance,
                   l_ledger_bal,
                   l_acct_type,
                   l_redemption_delay_flag
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

         --Check for Balance
         IF NVL (l_acct_balance, 0) <= 0
         THEN
            l_resp_cde := '15';
            l_err_msg := 'Insufficient Funds';
            RAISE exp_reject_record;
         END IF;

         IF l_dupchk_count = 1
         THEN
            IF l_dupchk_cardstat = l_card_stat
               AND l_dupchk_acctbal = l_acct_balance
            THEN
               l_resp_cde := '22';
               l_err_msg := 'Duplicate Incomm Reference Number-' || p_rrn_in;
               RAISE exp_reject_record;
            ELSE
               l_dupchk_count := 0;
            END IF;
         END IF;

         BEGIN
            SELECT NVL (cpc_default_partial_indr, 'N')
              INTO l_default_partial_indr
              FROM cms_prod_cattype
             WHERE     cpc_inst_code = p_inst_code_in
                   AND cpc_prod_code = l_prod_code
                   AND cpc_card_type = l_card_type;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting redemption_locktype-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Duplicate RRN check

         --SN : Convert currency amt
         IF (l_tran_type = 'F' OR l_tran_preauth_flag = 'Y')
         THEN
            IF (p_txn_amt_in >= 0)
            THEN
               BEGIN
                  sp_convert_curr (p_inst_code_in,
                                   l_currcode,
                                   p_card_no_in,
                                   p_txn_amt_in,
                                   l_tran_date,
                                   l_tran_amt,
                                   l_card_curr,
                                   l_err_msg,
                                   l_prod_code,
                                   l_card_type);

                  IF l_err_msg <> 'OK'
                  THEN
                     l_resp_cde := '65';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '89';
                     l_err_msg :=
                        'Error from currency conversion '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            ELSE
               l_resp_cde := '43';
               l_err_msg := 'INVALID AMOUNT';
               RAISE exp_reject_record;
            END IF;

            IF l_redemption_delay_flag = 'Y'
            THEN
               vmsredemptiondelay.check_delayed_load (l_acct_number,
                                                      l_delayed_amount,
                                                      l_err_msg);

               IF l_err_msg <> 'OK'
               THEN
                  RAISE exp_reject_record;
               END IF;
            END IF;

            --Check for partial approval
            IF (l_tran_amt > l_acct_balance - l_delayed_amount)
            THEN
               IF l_default_partial_indr = 'Y'
               THEN
                  l_tran_amt := l_acct_balance - l_delayed_amount;
                  p_autherized_amount_out := l_tran_amt;
               ELSE
                  l_resp_cde := '15';
                  l_err_msg := 'Insufficient Balance';
                  RAISE exp_reject_record;
               END IF;
            ELSE
               p_autherized_amount_out := l_tran_amt;
            END IF;
         END IF;

         --SN : select authorization process  flag
         BEGIN
            SELECT ptp_param_value
              INTO l_precheck_flag
              FROM pcms_tranauth_param
             WHERE ptp_param_name = 'PRE CHECK'
                   AND ptp_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Master set up is not done for Authorization Process';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while selecting precheck flag-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT ptp_param_value
              INTO l_preauth_flag
              FROM pcms_tranauth_param
             WHERE ptp_param_name = 'PRE AUTH'
                   AND ptp_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Master set up is not done for Authorization Process';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while selecting preauth falg-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : select authorization process  flag

         --SN : GPR Card status check
         BEGIN
            sp_status_check_gpr (p_inst_code_in,
                                 p_card_no_in,
                                 p_delivery_channel_in,
                                 l_expry_date,
                                 l_card_stat,
                                 p_txn_code_in,
                                 p_txn_mode_in,
                                 l_prod_code,
                                 l_card_type,
                                 p_msg_typ_in,
                                 p_business_date_in,
                                 p_business_time_in,
                                 p_international_ind_in,
                                 p_pos_verfication_in,
                                 p_mcc_code_in,
                                 l_resp_cde,
                                 l_err_msg);

            IF ( (l_resp_cde <> '1' AND l_err_msg <> 'OK')
                OR (l_resp_cde <> '0' AND l_err_msg <> 'OK'))
            THEN
               RAISE exp_reject_record;
            ELSE
               l_status_chk := l_resp_cde;
               l_resp_cde := '1';
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error from GPR Card Status Check-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : GPR Card status check

         IF l_status_chk = '1'
         THEN
            --SN : Card expiry check
            BEGIN
               IF TO_DATE (p_business_date_in, 'YYYYMMDD') >
                     LAST_DAY (TO_CHAR (l_expry_date, 'DD-MON-YY'))
               THEN
                  l_resp_cde := '13';
                  l_err_msg := 'EXPIRED CARD';
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
                     'Error in expiry date check-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            --EN : Card expiry check
            --SN : check for precheck
            IF l_precheck_flag = 1
            THEN
               BEGIN
                  sp_precheck_txn (p_inst_code_in,
                                   p_card_no_in,
                                   p_delivery_channel_in,
                                   l_expry_date,
                                   l_card_stat,
                                   p_txn_code_in,
                                   p_txn_mode_in,
                                   p_business_date_in,
                                   p_business_time_in,
                                   l_tran_amt,
                                   NULL,
                                   NULL,
                                   l_resp_cde,
                                   l_err_msg);

                  IF (l_resp_cde <> '1' OR l_err_msg <> 'OK')
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
                        'Error from precheck processes-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END IF;
         --EN : check for precheck
         END IF;

         --SN : check for Preauth
         IF l_preauth_flag = 1
         THEN
            BEGIN
               sp_preauthorize_txn (p_card_no_in,
                                    p_mcc_code_in,
                                    p_curr_code_in,
                                    l_tran_date,
                                    p_txn_code_in,
                                    p_inst_code_in,
                                    p_business_date_in,
                                    l_tran_amt,
                                    p_delivery_channel_in,
                                    l_resp_cde,
                                    l_err_msg);

               IF (l_resp_cde <> '1' OR l_err_msg <> 'OK')
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
                     'Error from pre_auth process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

         --EN : check for preauth

         l_time_stamp := SYSTIMESTAMP;

         ---SN : dynamic fee calculation .
         BEGIN
            sp_tran_fees_cmsauth (p_inst_code_in,
                                  p_card_no_in,
                                  p_delivery_channel_in,
                                  l_txn_type,
                                  p_txn_mode_in,
                                  p_txn_code_in,
                                  p_curr_code_in,
                                  NULL,
                                  NULL,
                                  l_tran_amt,
                                  l_tran_date,
                                  p_international_ind_in,
                                  p_pos_verfication_in,
                                  l_resp_cde,
                                  p_msg_typ_in,
                                  p_rvsl_code_in,
                                  p_mcc_code_in,
                                  l_fee_amt,
                                  l_err_msg,
                                  l_fee_code,
                                  l_fee_crgl_catg,
                                  l_fee_crgl_code,
                                  l_fee_crsubgl_code,
                                  l_fee_cracct_no,
                                  l_fee_drgl_catg,
                                  l_fee_drgl_code,
                                  l_fee_drsubgl_code,
                                  l_fee_dracct_no,
                                  l_st_calc_flag,
                                  l_cess_calc_flag,
                                  l_st_cracct_no,
                                  l_st_dracct_no,
                                  l_cess_cracct_no,
                                  l_cess_dracct_no,
                                  l_feeamnt_type,
                                  l_clawback,
                                  l_fee_plan,
                                  l_per_fees,
                                  l_flat_fees,
                                  l_freetxn_exceed,
                                  l_duration,
                                  l_feeattach_type,
                                  l_fee_desc);

            IF l_err_msg <> 'OK'
            THEN
               l_resp_cde := '21';
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
                  'Error from fee calc process- ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         ---EN : dynamic fee calculation .

         --SN : calculate waiver on the fee
         BEGIN
            sp_calculate_waiver (p_inst_code_in,
                                 p_card_no_in,
                                 '000',
                                 l_prod_code,
                                 l_card_type,
                                 l_fee_code,
                                 l_fee_plan,
                                 l_tran_date,
                                 l_waiv_percnt,
                                 l_err_msg);

            IF l_err_msg <> 'OK'
            THEN
               l_resp_cde := '21';
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
                  'Error from waiver calc process- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : calculate waiver on the fee

         l_fee_amt :=
            ROUND (l_fee_amt - ( (l_fee_amt * l_waiv_percnt) / 100), 2);

         --SN : Get institution paramerters
         BEGIN
            FOR l_idx
               IN (SELECT cip_param_key, cip_param_value
                     FROM cms_inst_param
                    WHERE cip_param_key IN ('SERVICETAX', 'CESS')
                          AND cip_inst_code = p_inst_code_in)
            LOOP
               IF l_idx.cip_param_key = 'SERVICETAX'
               THEN
                  l_servicetax_percent := l_idx.cip_param_value;
               ELSIF l_idx.cip_param_key = 'CESS'
               THEN
                  l_cess_percent := l_idx.cip_param_value;
               END IF;
            END LOOP;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while selecting selection  institution parameters-'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

         --EN : Get institution paramerters

         --SN : Apply service tax and cess
         IF l_st_calc_flag = 1
         THEN
            l_servicetax_amount := (l_fee_amt * l_servicetax_percent) / 100;
         ELSE
            l_servicetax_amount := 0;
         END IF;

         IF l_cess_calc_flag = 1
         THEN
            l_cess_amount := (l_servicetax_amount * l_cess_percent) / 100;
         ELSE
            l_cess_amount := 0;
         END IF;

         l_total_fee :=
            ROUND (l_fee_amt + l_servicetax_amount + l_cess_amount, 2);

         --EN : Apply service tax and cess

         IF l_total_fee > 0
         THEN
            IF l_total_fee >= l_acct_balance
            THEN
               l_resp_cde := '15';
               l_err_msg := 'Insufficient Balance ';
               RAISE exp_reject_record;
            ELSIF l_tran_amt + l_total_fee > l_acct_balance
            THEN
               l_tran_amt := l_acct_balance - l_total_fee;
               p_autherized_amount_out := l_tran_amt;
            END IF;
         END IF;

         --SN : Completion fee calculation
         IF l_tran_amt = 0
         THEN
            l_comp_fee_amt := 0;
         ELSE
            BEGIN
               SELECT cpt_compl_txncode
                 INTO l_comp_txn_code
                 FROM cms_preauthcomp_txncode
                WHERE cpt_inst_code = p_inst_code_in
                      AND cpt_preauth_txncode = p_txn_code_in;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_comp_txn_code := '00';
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                     'Error while selecting completion transaction code-'
                     || SQLERRM;
                  RAISE exp_reject_record;
            END;

            BEGIN
               sp_tran_fees_cmsauth (p_inst_code_in,
                                     p_card_no_in,
                                     p_delivery_channel_in,
                                     '1',
                                     p_txn_mode_in,
                                     l_comp_txn_code,
                                     p_curr_code_in,
                                     NULL,
                                     NULL,
                                     l_tran_amt,
                                     l_tran_date,
                                     p_international_ind_in,
                                     p_pos_verfication_in,
                                     l_resp_cde,
                                     '1220',
                                     p_rvsl_code_in,
                                     p_mcc_code_in,
                                     l_comp_fee_amt,
                                     l_err_msg,
                                     l_comp_fee_code,
                                     l_comp_fee_crgl_catg,
                                     l_comp_fee_crgl_code,
                                     l_comp_fee_crsubgl_code,
                                     l_comp_fee_cracct_no,
                                     l_comp_fee_drgl_catg,
                                     l_comp_fee_drgl_code,
                                     l_comp_fee_drsubgl_code,
                                     l_comp_fee_dracct_no,
                                     l_comp_st_calc_flag,
                                     l_comp_cess_calc_flag,
                                     l_comp_st_cracct_no,
                                     l_comp_st_dracct_no,
                                     l_comp_cess_cracct_no,
                                     l_comp_cess_dracct_no,
                                     l_comp_feeamnt_type,
                                     l_comp_clawback,
                                     l_comp_fee_plan,
                                     l_comp_per_fees,
                                     l_comp_flat_fees,
                                     l_comp_freetxn_exceed,
                                     l_comp_duration,
                                     l_comp_feeattach_type,
                                     l_comp_fee_desc);

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
                     'Error from fee calc process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            BEGIN
               sp_calculate_waiver (p_inst_code_in,
                                    p_card_no_in,
                                    '000',
                                    l_prod_code,
                                    l_card_type,
                                    l_comp_fee_code,
                                    l_comp_fee_plan,
                                    l_tran_date,
                                    l_comp_waiv_percnt,
                                    l_err_msg);

               IF l_err_msg <> 'OK'
               THEN
                  l_resp_cde := '21';
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
                     'Error from waiver calc process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            --En calculate waiver on the fee

            --Sn apply waiver on fee amount
            l_comp_fee_amt :=
               ROUND (
                  l_comp_fee_amt
                  - ( (l_comp_fee_amt * l_comp_waiv_percnt) / 100),
                  2);

            --Sn apply service tax and cess
            IF l_comp_st_calc_flag = 1
            THEN
               l_comp_servicetax_amount :=
                  (l_comp_fee_amt * l_servicetax_percent) / 100;
            ELSE
               l_comp_servicetax_amount := 0;
            END IF;

            IF l_comp_cess_calc_flag = 1
            THEN
               l_comp_cess_amount :=
                  (l_comp_servicetax_amount * l_cess_percent) / 100;
            ELSE
               l_comp_cess_amount := 0;
            END IF;

            l_comp_total_fee :=
               ROUND (
                    l_comp_fee_amt
                  + l_comp_servicetax_amount
                  + l_comp_cess_amount,
                  2);

            IF l_comlfree_flag = 'Y'
            THEN
               l_comp_total_fee := 0;
            END IF;
         --En apply service tax and cess
         END IF;

         --EN : Completion fee calculation

         IF l_comp_total_fee > 0
         THEN
            IF (l_tran_amt + l_total_fee + l_comp_total_fee) >
                  (l_acct_balance - l_delayed_amount)
            THEN
               IF l_default_partial_indr = 'Y'
                  AND ( (l_acct_balance - l_delayed_amount) >
                          (l_total_fee + l_comp_total_fee))
               THEN
                  l_tran_amt :=
                     (l_acct_balance - l_delayed_amount)
                     - (l_total_fee + l_comp_total_fee);
                  l_tot_hold_amt := l_tran_amt + l_comp_total_fee;
                  p_autherized_amount_out := l_tran_amt;
               ELSE
                  l_resp_cde := '15';
                  l_err_msg := 'Insufficient Balance';
                  RAISE exp_reject_record;
               END IF;
            ELSE
               l_tot_hold_amt := l_tran_amt + l_comp_total_fee;
            END IF;
         ELSE
            l_tot_hold_amt := l_tran_amt;
         END IF;

         --SN : Transaction limits check
         BEGIN
            IF (l_prfl_code IS NOT NULL AND l_prfl_flag = 'Y')
            THEN
               pkg_limits_check.sp_limits_check (l_hash_pan,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 p_txn_code_in,
                                                 l_tran_type,
                                                 NULL,
                                                 NULL,
                                                 p_inst_code_in,
                                                 NULL,
                                                 l_prfl_code,
                                                 l_tran_amt,
                                                 p_delivery_channel_in,
                                                 l_comb_hash,
                                                 l_resp_cde,
                                                 l_err_msg);
            END IF;

            IF l_resp_cde <> '00' AND l_err_msg <> 'OK'
            THEN
               IF l_resp_cde = '127'
               THEN
                  l_resp_cde := '140';
               ELSE
                  l_resp_cde := l_resp_cde;
               END IF;

               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while limits check-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Transaction limits check

         BEGIN
            sp_upd_transaction_accnt_auth (p_inst_code_in,
                                           l_tran_date,
                                           l_prod_code,
                                           l_card_type,
                                           l_tot_hold_amt,
                                           NULL,
                                           p_txn_code_in,
                                           l_dr_cr_flag,
                                           p_rrn_in,
                                           p_term_id_in,
                                           p_delivery_channel_in,
                                           p_txn_mode_in,
                                           p_card_no_in,
                                           l_fee_code,
                                           l_total_fee,           --l_fee_amt,
                                           l_fee_cracct_no,
                                           l_fee_dracct_no,
                                           l_st_calc_flag,
                                           l_cess_calc_flag,
                                           l_servicetax_amount,
                                           l_st_cracct_no,
                                           l_st_dracct_no,
                                           l_cess_amount,
                                           l_cess_cracct_no,
                                           l_cess_dracct_no,
                                           l_acct_number,
                                           NULL,
                                           p_msg_typ_in,
                                           l_resp_cde,
                                           l_err_msg);

            IF (l_resp_cde <> '1' OR l_err_msg <> 'OK')
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
                  'Error from upd_transaction_accnt_auth-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            IF TRIM (l_trans_desc) IS NOT NULL
            THEN
               l_narration := l_trans_desc || '/';
            END IF;

            IF TRIM (p_merchant_name_in) IS NOT NULL
            THEN
               l_narration := l_narration || p_merchant_name_in || '/';
            END IF;

            IF TRIM (p_term_id_in) IS NOT NULL
            THEN
               l_narration := l_narration || p_term_id_in || '/';
            END IF;

            IF TRIM (p_business_date_in) IS NOT NULL
            THEN
               l_narration := l_narration || p_business_date_in || '/';
            END IF;

            l_narration := l_narration || p_auth_id_out;
         END;

         BEGIN
            IF l_total_fee <> 0 OR l_freetxn_exceed = 'N'
            THEN
               IF l_freetxn_exceed = 'N'
               THEN
                  INSERT INTO cms_statements_log (csl_pan_no,
                                                  csl_opening_bal,
                                                  csl_trans_amount,
                                                  csl_trans_type,
                                                  csl_trans_date,
                                                  csl_closing_balance,
                                                  csl_trans_narrration,
                                                  csl_inst_code,
                                                  csl_pan_no_encr,
                                                  csl_rrn,
                                                  csl_auth_id,
                                                  csl_business_date,
                                                  csl_business_time,
                                                  txn_fee_flag,
                                                  csl_delivery_channel,
                                                  csl_txn_code,
                                                  csl_acct_no,
                                                  csl_ins_user,
                                                  csl_ins_date,
                                                  csl_merchant_name,
                                                  csl_panno_last4digit,
                                                  csl_prod_code,
                                                  csl_card_type,
                                                  csl_acct_type,
                                                  csl_time_stamp)
                       VALUES (l_hash_pan,
                               l_ledger_bal,
                               l_total_fee,
                               'DR',
                               l_tran_date,
                               l_ledger_bal - l_total_fee,
                               l_fee_desc,
                               p_inst_code_in,
                               l_encr_pan,
                               p_rrn_in,
                               p_auth_id_out,
                               p_business_date_in,
                               p_business_time_in,
                               'Y',
                               p_delivery_channel_in,
                               p_txn_code_in,
                               l_acct_number,
                               1,
                               SYSDATE,
                               p_merchant_name_in,
                               SUBSTR (p_card_no_in, -4),
                               l_prod_code,
                               l_card_type,
                               l_acct_type,
                               l_time_stamp);
               ELSE
                  IF l_feeamnt_type = 'A'
                  THEN
                     l_flat_fees :=
                        ROUND (
                           l_flat_fees
                           - ( (l_flat_fees * l_waiv_percnt) / 100),
                           2);


                     l_per_fees :=
                        ROUND (
                           l_per_fees - ( (l_per_fees * l_waiv_percnt) / 100),
                           2);

                     --SN : Entry for flat  Fee
                     INSERT INTO cms_statements_log (csl_pan_no,
                                                     csl_opening_bal,
                                                     csl_trans_amount,
                                                     csl_trans_type,
                                                     csl_trans_date,
                                                     csl_closing_balance,
                                                     csl_trans_narrration,
                                                     csl_inst_code,
                                                     csl_pan_no_encr,
                                                     csl_rrn,
                                                     csl_auth_id,
                                                     csl_business_date,
                                                     csl_business_time,
                                                     txn_fee_flag,
                                                     csl_delivery_channel,
                                                     csl_txn_code,
                                                     csl_acct_no,
                                                     csl_ins_user,
                                                     csl_ins_date,
                                                     csl_merchant_name,
                                                     csl_panno_last4digit,
                                                     csl_prod_code,
                                                     csl_card_type,
                                                     csl_acct_type,
                                                     csl_time_stamp)
                          VALUES (l_hash_pan,
                                  l_ledger_bal,
                                  l_flat_fees,
                                  'DR',
                                  l_tran_date,
                                  l_ledger_bal - l_flat_fees,
                                  'Fixed Fee debited for ' || l_fee_desc,
                                  p_inst_code_in,
                                  l_encr_pan,
                                  p_rrn_in,
                                  p_auth_id_out,
                                  p_business_date_in,
                                  p_business_time_in,
                                  'Y',
                                  p_delivery_channel_in,
                                  p_txn_code_in,
                                  l_acct_number,
                                  1,
                                  SYSDATE,
                                  p_merchant_name_in,
                                  SUBSTR (p_card_no_in, -4),
                                  l_prod_code,
                                  l_card_type,
                                  l_acct_type,
                                  l_time_stamp);

                     --EN : Entry for flat  Fee
                     --SN : Entry for Percentage Fee
                     INSERT INTO cms_statements_log (csl_pan_no,
                                                     csl_opening_bal,
                                                     csl_trans_amount,
                                                     csl_trans_type,
                                                     csl_trans_date,
                                                     csl_closing_balance,
                                                     csl_trans_narrration,
                                                     csl_inst_code,
                                                     csl_pan_no_encr,
                                                     csl_rrn,
                                                     csl_auth_id,
                                                     csl_business_date,
                                                     csl_business_time,
                                                     txn_fee_flag,
                                                     csl_delivery_channel,
                                                     csl_txn_code,
                                                     csl_acct_no,
                                                     csl_ins_user,
                                                     csl_ins_date,
                                                     csl_merchant_name,
                                                     csl_panno_last4digit,
                                                     csl_prod_code,
                                                     csl_card_type,
                                                     csl_acct_type,
                                                     csl_time_stamp)
                          VALUES (
                                    l_hash_pan,
                                    (l_ledger_bal - l_flat_fees),
                                    l_per_fees,
                                    'DR',
                                    l_tran_date,
                                    (l_ledger_bal - l_flat_fees) - l_per_fees,
                                    'Percentage Fee debited for '
                                    || l_fee_desc,
                                    p_inst_code_in,
                                    l_encr_pan,
                                    p_rrn_in,
                                    p_auth_id_out,
                                    p_business_date_in,
                                    p_business_time_in,
                                    'Y',
                                    p_delivery_channel_in,
                                    p_txn_code_in,
                                    l_acct_number,
                                    1,
                                    SYSDATE,
                                    p_merchant_name_in,
                                    SUBSTR (p_card_no_in, -4),
                                    l_prod_code,
                                    l_card_type,
                                    l_acct_type,
                                    l_time_stamp);
                  --EN : Entry for Percentage Fee

                  ELSE
                     INSERT INTO cms_statements_log (csl_pan_no,
                                                     csl_opening_bal,
                                                     csl_trans_amount,
                                                     csl_trans_type,
                                                     csl_trans_date,
                                                     csl_closing_balance,
                                                     csl_trans_narrration,
                                                     csl_inst_code,
                                                     csl_pan_no_encr,
                                                     csl_rrn,
                                                     csl_auth_id,
                                                     csl_business_date,
                                                     csl_business_time,
                                                     txn_fee_flag,
                                                     csl_delivery_channel,
                                                     csl_txn_code,
                                                     csl_acct_no,
                                                     csl_ins_user,
                                                     csl_ins_date,
                                                     csl_merchant_name,
                                                     csl_panno_last4digit,
                                                     csl_prod_code,
                                                     csl_card_type,
                                                     csl_acct_type,
                                                     csl_time_stamp)
                          VALUES (l_hash_pan,
                                  l_ledger_bal,
                                  l_total_fee,
                                  'DR',
                                  l_tran_date,
                                  l_ledger_bal - l_total_fee,
                                  l_fee_desc,
                                  p_inst_code_in,
                                  l_encr_pan,
                                  p_rrn_in,
                                  p_auth_id_out,
                                  p_business_date_in,
                                  p_business_time_in,
                                  'Y',
                                  p_delivery_channel_in,
                                  p_txn_code_in,
                                  l_acct_number,
                                  1,
                                  SYSDATE,
                                  p_merchant_name_in,
                                  SUBSTR (p_card_no_in, -4),
                                  l_prod_code,
                                  l_card_type,
                                  l_acct_type,
                                  l_time_stamp);
                  END IF;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Problem while inserting into statement log for tran fee- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT NVL (cpm_pre_auth_exp_date, '000')
              INTO l_preauth_exp_period
              FROM cms_prod_mast
             WHERE cpm_inst_code = p_inst_code_in
                   AND cpm_prod_code = l_prod_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_preauth_exp_period := '000';
         END;

         IF l_preauth_exp_period = '000'
         THEN
            l_preauth_date := l_expry_date;
         ELSE
            l_preauth_hold := SUBSTR (TRIM (l_preauth_exp_period), 1, 1);
            l_preauth_period :=
               TO_NUMBER (SUBSTR (TRIM (l_preauth_exp_period), 2, 2));

            IF l_preauth_hold = '0'
            THEN
               l_preauth_date := l_tran_date + (l_preauth_period * (1 / 1440));
            END IF;

            IF l_preauth_hold = '1'
            THEN
               l_preauth_date := l_tran_date + (l_preauth_period * (1 / 24));
            END IF;

            IF l_preauth_hold = '2'
            THEN
               l_preauth_date := l_tran_date + l_preauth_period;
            END IF;
         END IF;

         BEGIN
            INSERT
              INTO cms_preauth_transaction (cpt_card_no,
                                            cpt_txn_amnt,
                                            cpt_expiry_date,
                                            cpt_sequence_no,
                                            cpt_preauth_validflag,
                                            cpt_inst_code,
                                            cpt_mbr_no,
                                            cpt_card_no_encr,
                                            cpt_completion_flag,
                                            cpt_approve_amt,
                                            cpt_rrn,
                                            cpt_txn_date,
                                            cpt_txn_time,
                                            cpt_terminalid,
                                            cpt_expiry_flag,
                                            cpt_totalhold_amt,
                                            cpt_transaction_flag,
                                            cpt_acct_no,
                                            cpt_mcc_code,
                                            cpt_delivery_channel,
                                            cpt_txn_code,
                                            cpt_merchant_name,
                                            cpt_pos_verification,
                                            cpt_internation_ind_response,
                                            cpt_completion_fee,
                                            cpt_complfree_flag,
                                            cpt_store_id)
            VALUES (
                      l_hash_pan,
                      ROUND (NVL (l_tran_amt, 0), 2),
                      l_preauth_date,
                      '1',
                      'Y',
                      p_inst_code_in,
                      '000',
                      l_encr_pan,
                      'N',
                      TRIM (
                         TO_CHAR (NVL (l_tran_amt, 0),
                                  '999999999999999990.99')),
                      p_rrn_in,
                      p_business_date_in,
                      p_business_time_in,
                      p_term_id_in,
                      'N',
                      TRIM (
                         TO_CHAR (NVL (l_tran_amt, 0),
                                  '999999999999999990.99')),
                      'N',
                      l_acct_number,
                      p_mcc_code_in,
                      p_delivery_channel_in,
                      p_txn_code_in,
                      p_merchant_name_in,
                      p_pos_verfication_in,
                      p_international_ind_in,
                      l_comp_total_fee,
                      CASE WHEN l_comp_freetxn_exceed = 'N' THEN 'Y' END,
                      p_store_id_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while inserting cms_preauth_transaction-'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

         BEGIN
            INSERT INTO cms_preauth_trans_hist (cph_card_no,
                                                cph_txn_amnt,
                                                cph_expiry_date,
                                                cph_sequence_no,
                                                cph_preauth_validflag,
                                                cph_inst_code,
                                                cph_mbr_no,
                                                cph_card_no_encr,
                                                cph_completion_flag,
                                                cph_approve_amt,
                                                cph_rrn,
                                                cph_txn_date,
                                                cph_terminalid,
                                                cph_expiry_flag,
                                                cph_transaction_flag,
                                                cph_totalhold_amt,
                                                cph_transaction_rrn,
                                                cph_merchant_name,
                                                cph_delivery_channel,
                                                cph_tran_code,
                                                cph_panno_last4digit,
                                                cph_acct_no,
                                                cph_completion_fee)
                 VALUES (
                           l_hash_pan,
                           NVL (l_tran_amt, 0),
                           l_preauth_date,
                           p_rrn_in,
                           'Y',
                           p_inst_code_in,
                           '000',
                           l_encr_pan,
                           'N',
                           TRIM (
                              TO_CHAR (NVL (l_tran_amt, 0),
                                       '999999999999999990.99')),
                           p_rrn_in,
                           p_business_date_in,
                           p_term_id_in,
                           'N',
                           'N',
                           TRIM (
                              TO_CHAR (NVL (l_tran_amt, 0),
                                       '999999999999999990.99')),
                           p_rrn_in,
                           p_merchant_name_in,
                           p_delivery_channel_in,
                           p_txn_code_in,
                           SUBSTR (p_card_no_in, -4),
                           l_acct_number,
                           l_comp_total_fee);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while inserting  cms_preauth_trans_hist-'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

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

         --SN : Get b24 responsse code from response master
         l_resp_cde := '1';

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE     cms_inst_code = p_inst_code_in
                   AND cms_delivery_channel = p_delivery_channel_in
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
               RAISE exp_reject_record;
         END;

         --EN : Get b24 responsse code from response master

         --SN : Set out parameters
         --p_curr_out := p_curr_code_in;
         p_autherized_amount_out :=
            TO_CHAR (p_autherized_amount_out, '99999999999999990.99');
         p_resp_msg_out := 'OK';
      --EN : Set out parameters
      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;

            --SN : Set out parameters
            BEGIN
               p_auth_id_out := 0;
               --p_curr_out := p_curr_code_in;
               p_autherized_amount_out := '0.00';
               p_resp_msg_out := l_err_msg;

               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_inst_code_in
                      AND cms_delivery_channel = p_delivery_channel_in
                      AND cms_response_id = TO_NUMBER (l_resp_cde);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg_out :=
                        'Problem while selecting data from response master '
                     || l_resp_cde
                     || ' is-'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code_out := '89';
            END;
         --EN : Set out parameters
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_err_msg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            l_resp_cde := '89';

            --SN : Set out parameters
            BEGIN
               p_auth_id_out := 0;
               --p_curr_out := p_curr_code_in;
               p_autherized_amount_out := '0.00';
               p_resp_msg_out := l_err_msg;

               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_inst_code_in
                      AND cms_delivery_channel = p_delivery_channel_in
                      AND cms_response_id = TO_NUMBER (l_resp_cde);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg_out :=
                        'Problem while selecting data from response master '
                     || l_resp_cde
                     || ' is-'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code_out := '89';
            END;
      --EN : Set out parameters
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_desc
              INTO l_dr_cr_flag, l_txn_type, l_trans_desc
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

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

      p_balance_out := TO_CHAR (l_acct_balance, '99999999999999990.99');

      --SN : Make entry in transactionlog

      BEGIN
         INSERT INTO transactionlog (msgtype,
                                     rrn,
                                     delivery_channel,
                                     terminal_id,
                                     date_time,
                                     txn_code,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     response_code,
                                     business_date,
                                     business_time,
                                     customer_card_no,
                                     bank_code,
                                     total_amount,
                                     currencycode,
                                     productid,
                                     categoryid,
                                     auth_id,
                                     trans_desc,
                                     amount,
                                     system_trace_audit_no,
                                     instcode,
                                     tranfee_amt,
                                     feecode,
                                     fee_plan,
                                     feeattachtype,
                                     cr_dr_flag,
                                     customer_card_no_encr,
                                     proxy_number,
                                     reversal_code,
                                     customer_acct_no,
                                     acct_balance,
                                     ledger_balance,
                                     response_id,
                                     merchant_name,
                                     add_ins_user,
                                     error_msg,
                                     cardstatus,
                                     store_id,
                                     time_stamp,
                                     acct_type,
                                     spil_prod_id,
                                     spil_fee,
                                     spil_upc,
                                     spil_merref_num,
                                     spil_req_tmzm,
                                     spil_loc_cntry,
                                     spil_loc_crcy,
                                     spil_loc_lang,
                                     spil_pos_entry,
                                     spil_pos_cond)
              VALUES (
                        p_msg_typ_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_term_id_in,
                        TRUNC (SYSDATE),
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        DECODE (p_resp_code_out, '00', 'C', 'F'),
                        p_resp_code_out,
                        p_business_date_in,
                        p_business_time_in,
                        l_hash_pan,
                        p_inst_code_in,
                        TRIM (TO_CHAR (l_tran_amt+l_fee_amt, '99999999999999990.99')),
                        l_currcode,
                        l_prod_code,
                        l_card_type,
                        p_auth_id_out,
                        l_trans_desc,
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999990.99')),
                           l_tran_amt),
                        p_stan_in,
                        p_inst_code_in,
                        l_fee_amt,
                        l_fee_code,
                        l_fee_plan,
                        l_feeattach_type,
                        l_dr_cr_flag,
                        l_encr_pan,
                        l_proxunumber,
                        p_rvsl_code_in,
                        l_acct_number,
                        l_acct_balance,
                        l_ledger_bal,
                        l_resp_cde,
                        p_merchant_name_in,
                        1,
                        p_resp_msg_out,
                        l_card_stat,
                        p_store_id_in,
                        NVL (l_time_stamp, SYSTIMESTAMP),
                        l_acct_type,
                        p_product_id_in,
                        p_fee_amt_in,
                        p_upc_in,
                        p_mercrefnum_in,
                        p_reqtimezone_in,
                        p_localcountry_in,
                        p_localcurrency_in,
                        p_loclanguage_in,
                        p_posentry_in,
                        p_poscond_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_resp_code_out := '89';
            p_resp_msg_out :=
               'Problem while inserting data into transaction log- '
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --EN : Make entry in transactionlog

      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_channel_in
               || p_txn_code_in
               || p_card_no_in
               || p_rrn_in
               || TO_CHAR (NVL (l_time_stamp, SYSTIMESTAMP),
                           'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            p_resp_msg_out :=
               'Error while generating haskkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      --SN : Make entry in cms_transaction_log_dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                              ctd_txn_code,
                                              ctd_txn_type,
                                              ctd_msg_type,
                                              ctd_txn_mode,
                                              ctd_business_date,
                                              ctd_business_time,
                                              ctd_customer_card_no,
                                              ctd_txn_amount,
                                              ctd_txn_curr,
                                              ctd_actual_amount,
                                              ctd_fee_amount,
                                              ctd_bill_amount,
                                              ctd_bill_curr,
                                              ctd_process_flag,
                                              ctd_process_msg,
                                              ctd_rrn,
                                              ctd_system_trace_audit_no,
                                              ctd_inst_code,
                                              ctd_customer_card_no_encr,
                                              ctd_cust_acct_number,
                                              ctd_ins_user,
                                              ctd_ins_date,
                                              ctd_completion_fee,
                                              ctd_compfee_code,
                                              ctd_compfeeattach_type,
                                              ctd_compfeeplan_id,
                                              ctd_hashkey_id,
                                              ctd_store_address1,
                                              ctd_store_address2,
                                              ctd_store_city,
                                              ctd_store_state,
                                              ctd_store_zip)
              VALUES (
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_msg_typ_in,
                        p_txn_mode_in,
                        p_business_date_in,
                        p_business_time_in,
                        l_hash_pan,
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999999.99')),
                           l_tran_amt),
                        l_currcode,
                        TO_CHAR (NVL (l_tran_amt, 0), '99999999999990.99'),
                        l_fee_amt,
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999999.99')),
                           l_tran_amt),
                        l_card_curr,
                        DECODE (p_resp_code_out, '00', 'Y', 'E'),
                        DECODE (p_resp_code_out,
                                '00', 'Successful',
                                p_resp_msg_out),
                        p_rrn_in,
                        p_stan_in,
                        p_inst_code_in,
                        l_encr_pan,
                        l_acct_number,
                        1,
                        SYSDATE,
                        l_comp_total_fee,
                        l_comp_fee_code,
                        l_comp_feeattach_type,
                        l_comp_fee_plan,
                        l_hashkey_id,
                        p_address1_in,
                        p_address2_in,
                        p_city_in,
                        p_state_in,
                        p_zip_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  dtl-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
            ROLLBACK;
      END;

      --EN : Make entry in cms_transaction_log_dtl
      IF p_resp_msg_out = 'OK'
      THEN
         p_resp_msg_out := 'Success';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '89';
         p_resp_msg_out := 'Main Excp- ' || SUBSTR (SQLERRM, 1, 300);
   END redemption_lock;

   PROCEDURE redemption_lock_reversal (
      p_inst_code_in            IN     NUMBER,
      p_msg_typ_in              IN     VARCHAR2,
      p_rvsl_code_in            IN     VARCHAR2,
      p_rrn_in                  IN     VARCHAR2,
      p_delivery_channel_in     IN     VARCHAR2,
      p_terminal_id_in          IN     VARCHAR2,
      p_merc_id_in              IN     VARCHAR2,
      p_txn_code_in             IN     VARCHAR2,
      p_txn_type_in             IN     VARCHAR2,
      p_txn_mode_in             IN     VARCHAR2,
      p_business_date_in        IN     VARCHAR2,
      p_business_time_in        IN     VARCHAR2,
      p_card_no_in              IN     VARCHAR2,
      p_actual_amt_in           IN     NUMBER,
      p_stan_in                 IN     VARCHAR2,
      p_curr_code_in            IN     VARCHAR2,
      p_merchant_name_in        IN     VARCHAR2,
      p_store_id_in             IN     VARCHAR2,
      p_product_id_in           IN     VARCHAR2,
      p_fee_amt_in              IN     NUMBER,
      p_upc_in                  IN     VARCHAR2,
      p_mercrefnum_in           IN     VARCHAR2,
      p_reqtimezone_in          IN     VARCHAR2,
      p_localcountry_in         IN     VARCHAR2,
      p_localcurrency_in        IN     VARCHAR2,
      p_loclanguage_in          IN     VARCHAR2,
      p_posentry_in             IN     VARCHAR2,
      p_poscond_in              IN     VARCHAR2,
      p_address1_in             IN     VARCHAR2,
      p_address2_in             IN     VARCHAR2,
      p_city_in                 IN     VARCHAR2,
      p_state_in                IN     VARCHAR2,
      p_zip_in                  IN     VARCHAR2,
      p_resp_code_out              OUT VARCHAR2,
      p_resp_msg_out               OUT VARCHAR2,
      p_auth_id_out                OUT VARCHAR2,
      p_autherized_amount_out      OUT VARCHAR2,
      p_balance_out                OUT VARCHAR2,
      p_proxyno_out                OUT VARCHAR2)
   AS
      l_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no                    cms_appl_pan.cap_acct_no%TYPE;
      l_prod_code                  cms_appl_pan.cap_prod_code%TYPE;
      l_card_type                  cms_appl_pan.cap_card_type%TYPE;
      l_prfl_code                  cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat                  cms_appl_pan.cap_card_stat%TYPE;
      l_proxy_number               cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_balance               cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_balance             cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type                  cms_acct_mast.cam_type_code%TYPE;
      l_hold_amount                cms_preauth_transaction.cpt_totalhold_amt%TYPE;
      l_preauth_expiry_flag        cms_preauth_transaction.cpt_expiry_flag%TYPE;
      l_completion_fee             cms_preauth_transaction.cpt_completion_fee%TYPE;
      l_complfree_flag             cms_preauth_transaction.cpt_complfree_flag%TYPE;
      l_orgnl_delivery_channel     transactionlog.delivery_channel%TYPE;
      l_orgnl_resp_code            transactionlog.response_code%TYPE;
      l_orgnl_txn_code             transactionlog.txn_code%TYPE;
      l_orgnl_txn_type             transactionlog.txn_type%TYPE;
      l_orgnl_txn_mode             transactionlog.txn_mode%TYPE;
      l_orgnl_terminal_id          transactionlog.terminal_id%TYPE;
      l_orgnl_business_date        transactionlog.business_date%TYPE;
      l_orgnl_business_time        transactionlog.business_time%TYPE;
      l_orgnl_customer_card_no     transactionlog.customer_card_no%TYPE;
      l_orgnl_total_amount         transactionlog.amount%TYPE;
      l_orgnl_txn_fee_plan         transactionlog.fee_plan%TYPE;
      l_orgnl_txn_feecode          cms_fee_mast.cfm_fee_code%TYPE;
      l_orgnl_txn_feeattachtype    transactionlog.feeattachtype%TYPE;
      l_orgnl_txn_totalfee_amt     transactionlog.tranfee_amt%TYPE;
      l_orgnl_txn_servicetax_amt   transactionlog.servicetax_amt%TYPE;
      l_orgnl_txn_cess_amt         transactionlog.cess_amt%TYPE;
      l_orgnl_transaction_type     transactionlog.cr_dr_flag%TYPE;
      l_orgnl_termid               transactionlog.terminal_id%TYPE;
      l_orgnl_mcccode              transactionlog.mccode%TYPE;
      l_actual_dispatched_amt      transactionlog.amount%TYPE;
      l_actual_feecode             transactionlog.feecode%TYPE;
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
      l_tran_reverse_flag          transactionlog.tran_reverse_flag%TYPE;
      l_curr_code                  transactionlog.currencycode%TYPE;
      l_auth_id                    transactionlog.auth_id%TYPE;
      l_dr_cr_flag                 transactionlog.cr_dr_flag%TYPE;
      l_orgnl_txn_amnt             transactionlog.amount%TYPE;
      l_add_ins_date               transactionlog.add_ins_date%TYPE;
      l_prfl_flag                  cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_tran_type                  cms_transaction_mast.ctm_tran_type%TYPE;
      l_internation_ind_response   transactionlog.internation_ind_response%TYPE;
      l_pos_verification           transactionlog.pos_verification%TYPE;
      l_orgnl_auth_id              transactionlog.auth_id%TYPE;
      l_txn_narration              cms_statements_log.csl_trans_narrration%TYPE;
      l_fee_narration              cms_statements_log.csl_trans_narrration%TYPE;
      l_txn_merchname              cms_statements_log.csl_merchant_name%TYPE;
      l_fee_merchname              cms_statements_log.csl_merchant_name%TYPE;
      l_txn_merchcity              cms_statements_log.csl_merchant_city%TYPE;
      l_fee_merchcity              cms_statements_log.csl_merchant_city%TYPE;
      l_txn_merchstate             cms_statements_log.csl_merchant_state%TYPE;
      l_fee_merchstate             cms_statements_log.csl_merchant_state%TYPE;
      l_tran_desc                  cms_transaction_mast.ctm_tran_desc%TYPE;
      l_hashkey_id                 cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_fee_plan                   cms_fee_plan.cfp_plan_id%TYPE;
      l_feecap_flag                cms_fee_mast.cfm_feecap_flag%TYPE;
      l_orgnl_fee_amt              cms_fee_mast.cfm_fee_amt%TYPE;
      l_fee_code                   cms_fee_mast.cfm_fee_code%TYPE;
      l_comp_fee_code              cms_fee_mast.cfm_fee_code%TYPE;
      l_max_card_bal               cms_bin_param.cbp_param_value%TYPE;
      l_feeattach_type             VARCHAR2 (2);
      l_reversal_amt               NUMBER (9, 2);
      l_resp_cde                   VARCHAR2 (5);
      l_rvsl_trandate              DATE;
      l_tran_amt                   NUMBER;
      l_card_curr                  VARCHAR2 (5);
      l_currcode                   VARCHAR2 (3);
      l_timestamp                  TIMESTAMP (3);
      l_fee_amt                    NUMBER (9, 2);
      l_txn_type                   NUMBER (1);
      l_dupl_indc                  NUMBER (5) := 0;
      l_succ_orgnl_cnt             NUMBER (5) := 0;
      l_errmsg                     VARCHAR2 (300);
      exp_rvsl_reject_record       EXCEPTION;
        l_profile_code   cms_prod_cattype.cpc_profile_code%type;
l_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   l_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
         l_debit_reversal       vms_group_tran_detl.VGD_DEBIT_REVERSAL%TYPE;
         l_cap_card_stat                  cms_appl_pan.cap_card_stat%TYPE   := '12';
		 
		 v_Retperiod  date;  --Added for VMS-5739/FSP-991
         v_Retdate  date; --Added for VMS-5739/FSP-991
   BEGIN
      BEGIN
         l_tran_amt := p_actual_amt_in;

         --SN : Convert clear card number to hash and encryped format.
         BEGIN
            l_hash_pan := gethash (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_errmsg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            l_encr_pan := fn_emaps_main (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_errmsg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Convert clear card number to hash and encryped format.

         BEGIN
            SELECT ctm_credit_debit_flag,
                   ctm_tran_desc,                           -- || ' REVERSAL',
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_type,
                   ctm_prfl_flag
              INTO l_dr_cr_flag,
                   l_tran_desc,
                   l_txn_type,
                   l_tran_type,
                   l_prfl_flag
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '67';
               l_errmsg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Problem while selecting transactions dtls from master- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_acct_no,
                   cap_prfl_code,
                   cap_card_stat,
                   cap_proxy_number
              INTO l_prod_code,
                   l_card_type,
                   l_acct_no,
                   l_prfl_code,
                   l_card_stat,
                   l_proxy_number
              FROM cms_appl_pan
             WHERE     cap_inst_code = p_inst_code_in
                   AND cap_mbr_numb = '000'
                   AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '21';
               l_errmsg := ' Invalid Card';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while retriving card detail-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         p_proxyno_out := l_proxy_number;

         BEGIN
            l_rvsl_trandate :=
               TO_DATE (SUBSTR (TRIM (p_business_date_in), 1, 8), 'yyyymmdd');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '45';
               l_errmsg :=
                  'Problem while converting transaction date-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;
         BEGIN
               SELECT cpc_profile_code,cpc_badcredit_flag,cpc_badcredit_transgrpid
               into l_profile_code,l_badcredit_flag,l_badcredit_transgrpid
                    FROM cms_prod_cattype
                      WHERE     cpc_inst_code = p_inst_code_in
                      AND cpc_prod_code = l_prod_code
                    AND cpc_card_type = l_card_type;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '45';
               l_errmsg :=
                  'Problem while selecting from prod cattype'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            l_rvsl_trandate :=
               TO_DATE (
                     SUBSTR (TRIM (p_business_date_in), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_business_time_in), 1, 8),
                  'yyyymmdd hh24:mi:ss');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '32';
               l_errmsg :=
                  'Problem while converting transaction Time-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            p_auth_id_out := LPAD (seq_auth_id.NEXTVAL, 6, '0');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                  'Error while generating authid-'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            SELECT gcm_curr_code
              INTO l_currcode
              FROM gen_curr_mast
             WHERE gcm_inst_code=p_inst_code_in AND gcm_curr_name = p_curr_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '65';
               l_errmsg := 'Invalid Currency Code';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                     'Error while selecting the currency code for '
                  || p_curr_code_in
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF p_msg_typ_in NOT IN ('1420') OR (p_rvsl_code_in = '00')
         THEN
            l_resp_cde := '15';
            l_errmsg := 'Invalid Request';
            RAISE exp_rvsl_reject_record;
         END IF;

         --SN : Get original transaction details
         BEGIN
            FOR l_idx
               IN (  SELECT delivery_channel,
                            txn_code,
                            txn_mode,
                            terminal_id,
                            business_date,
                            business_time,
                            customer_card_no,
                            amount,
                            feecode,
                            fee_plan,
                            feeattachtype,
                            tranfee_amt,
                            servicetax_amt,
                            cess_amt,
                            cr_dr_flag,
                            mccode,
                            tranfee_cr_acctno,
                            tranfee_dr_acctno,
                            tran_st_calc_flag,
                            tran_cess_calc_flag,
                            tran_st_cr_acctno,
                            tran_st_dr_acctno,
                            tran_cess_cr_acctno,
                            tran_cess_dr_acctno,
                            currencycode,
                            NVL (tran_reverse_flag, 'N') tran_reverse_flag,
                            pos_verification,
                            internation_ind_response,
                            add_ins_date,
                            DECODE (txn_type,  '1', 'F',  '0', 'N') txntype,
                            auth_id
                       FROM VMSCMS.TRANSACTIONLOG_VW 						--Added for VMS-5739/FSP-991
                      WHERE     rrn = p_rrn_in
                            AND customer_card_no = l_hash_pan
                            AND instcode = p_inst_code_in
                            AND response_code = '00'
                            AND msgtype = '1100'
                            AND txn_code = p_txn_code_in
                            AND delivery_channel = p_delivery_channel_in
                   ORDER BY time_stamp)
            LOOP
               l_succ_orgnl_cnt := l_succ_orgnl_cnt + 1;

               IF l_idx.tran_reverse_flag = 'N'
               THEN
                  l_orgnl_delivery_channel := l_idx.delivery_channel;
                  l_orgnl_txn_code := l_idx.txn_code;
                  l_orgnl_txn_mode := l_idx.txn_mode;
                  l_orgnl_terminal_id := l_idx.terminal_id;
                  l_orgnl_business_date := l_idx.business_date;
                  l_orgnl_business_time := l_idx.business_time;
                  l_orgnl_customer_card_no := l_idx.customer_card_no;
                  l_orgnl_total_amount := l_idx.amount;
                  l_orgnl_txn_feecode := l_idx.feecode;
                  l_orgnl_txn_fee_plan := l_idx.fee_plan;
                  l_orgnl_txn_feeattachtype := l_idx.feeattachtype;
                  l_orgnl_txn_totalfee_amt := l_idx.tranfee_amt;
                  l_orgnl_txn_servicetax_amt := l_idx.servicetax_amt;
                  l_orgnl_txn_cess_amt := l_idx.cess_amt;
                  l_orgnl_transaction_type := l_idx.cr_dr_flag;
                  l_orgnl_mcccode := l_idx.mccode;
                  l_actual_feecode := l_idx.feecode;
                  l_orgnl_tranfee_amt := l_idx.tranfee_amt;
                  l_orgnl_servicetax_amt := l_idx.servicetax_amt;
                  l_orgnl_cess_amt := l_idx.cess_amt;
                  l_orgnl_tranfee_cr_acctno := l_idx.tranfee_cr_acctno;
                  l_orgnl_tranfee_dr_acctno := l_idx.tranfee_dr_acctno;
                  l_orgnl_st_calc_flag := l_idx.tran_st_calc_flag;
                  l_orgnl_cess_calc_flag := l_idx.tran_cess_calc_flag;
                  l_orgnl_st_cr_acctno := l_idx.tran_st_cr_acctno;
                  l_orgnl_st_dr_acctno := l_idx.tran_st_dr_acctno;
                  l_orgnl_cess_cr_acctno := l_idx.tran_cess_cr_acctno;
                  l_orgnl_cess_dr_acctno := l_idx.tran_cess_dr_acctno;
                  l_curr_code := l_idx.currencycode;
                  l_orgnl_txn_amnt := l_idx.amount;
                  l_pos_verification := l_idx.pos_verification;
                  l_internation_ind_response := l_idx.internation_ind_response;
                  l_add_ins_date := l_idx.add_ins_date;
                  l_tran_type := l_idx.txntype;
                  l_orgnl_auth_id := l_idx.auth_id;
               ELSE
                  l_dupl_indc := 1;
               END IF;
            END LOOP;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '69';
               l_errmsg :=
                  'Problem while checking for original transaction-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Get original transaction details

         IF l_succ_orgnl_cnt = 0
         THEN
            l_resp_cde := '53';
            l_errmsg := 'Original transaction not found';
            RAISE exp_rvsl_reject_record;
         ELSE
            IF l_dupl_indc = 1
            THEN
               l_resp_cde := '52';
               l_errmsg :=
                  'The reversal already done for the original transaction';
               RAISE exp_rvsl_reject_record;
            END IF;
         END IF;

         --SN : Convert currency amt

         IF (p_actual_amt_in >= 0)
         THEN
            BEGIN
               sp_convert_curr (p_inst_code_in,
                                l_currcode,
                                p_card_no_in,
                                p_actual_amt_in,
                                l_rvsl_trandate,
                                l_tran_amt,
                                l_card_curr,
                                l_errmsg,
                                l_prod_code,
                                l_card_type);

               IF l_errmsg <> 'OK'
               THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_errmsg :=
                     'Error from currency conversion-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         ELSE
            l_resp_cde := '43';
            l_errmsg := 'INVALID AMOUNT';
            RAISE exp_rvsl_reject_record;
         END IF;

         --EN : Convert currency amt

         --SN : Original txn details validation
         IF p_actual_amt_in > l_orgnl_txn_amnt
         THEN
            l_resp_cde := '59';
            l_errmsg :=
               'Reversal amount exceeds the original transaction amount';
            RAISE exp_rvsl_reject_record;
         END IF;

         IF (l_tran_amt IS NULL OR l_tran_amt = 0)
         THEN
            l_actual_dispatched_amt := 0;
         ELSE
            l_actual_dispatched_amt := l_tran_amt;
         END IF;


         --EN : Original txn details validation
         BEGIN
		 --Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		INTO   v_Retperiod 
		FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
		WHERE  OPERATION_TYPE='ARCHIVE' 
		AND OBJECT_NAME='CMS_PREAUTH_TRANSACTION_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)							--Added for VMS-5739/FSP-991

    THEN
		
            SELECT cpt_totalhold_amt,
                   cpt_expiry_flag,
                   cpt_completion_fee,
                   NVL (cpt_complfree_flag, 'N')
              INTO l_hold_amount,
                   l_preauth_expiry_flag,
                   l_completion_fee,
                   l_complfree_flag
              FROM cms_preauth_transaction
             WHERE     cpt_rrn = p_rrn_in
                   AND cpt_txn_date = l_orgnl_business_date
                   AND cpt_txn_time = l_orgnl_business_time
                   AND cpt_inst_code = p_inst_code_in
                   AND cpt_mbr_no = '000'
                   AND cpt_card_no = l_hash_pan;
ELSE

			SELECT cpt_totalhold_amt,
                   cpt_expiry_flag,
                   cpt_completion_fee,
                   NVL (cpt_complfree_flag, 'N')
              INTO l_hold_amount,
                   l_preauth_expiry_flag,
                   l_completion_fee,
                   l_complfree_flag
              FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST --Added for VMS-5739/FSP-991
             WHERE     cpt_rrn = p_rrn_in
                   AND cpt_txn_date = l_orgnl_business_date
                   AND cpt_txn_time = l_orgnl_business_time
                   AND cpt_inst_code = p_inst_code_in
                   AND cpt_mbr_no = '000'
                   AND cpt_card_no = l_hash_pan;
			
END IF;				   
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '53';
               l_errmsg := 'Matching lock transaction not found';
               RAISE exp_rvsl_reject_record;
            WHEN TOO_MANY_ROWS
            THEN
               l_resp_cde := '21';
               l_errmsg := 'More than one record found ';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg := 'Error while selecting the redemption_lock dtls-';
               RAISE exp_rvsl_reject_record;
         END;

         IF l_hold_amount <= 0
         THEN
            l_resp_cde := '58';
            l_errmsg := 'There is no hold amount for reversal';
            RAISE exp_rvsl_reject_record;
         END IF;

         IF (l_hold_amount < l_actual_dispatched_amt)
         THEN
            l_resp_cde := '59';
            l_errmsg :=
               'Reversal amount exceeds the original transaction amount';
            RAISE exp_rvsl_reject_record;
         END IF;

         l_reversal_amt := l_hold_amount - l_actual_dispatched_amt;

         --SN : Get account balance details from acct master
         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO l_acct_balance, l_ledger_balance, l_acct_type
              FROM cms_acct_mast
             WHERE cam_acct_no = l_acct_no AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '56';
               l_errmsg := 'Account not found in acct master ';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_errmsg :=
                  'Error while selecting account balance from acct master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Get account balance details from acct master
         --SN Max card balance check
         BEGIN
            SELECT TO_NUMBER (cbp_param_value)
              INTO l_max_card_bal
              FROM cms_bin_param
             WHERE cbp_inst_code = p_inst_code_in
                   AND cbp_param_name = 'Max Card Balance'
                   AND cbp_profile_code=l_profile_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF ( (l_acct_balance + l_reversal_amt) > l_max_card_bal)
            OR ( (l_ledger_balance + l_reversal_amt) > l_max_card_bal)
         THEN
            IF l_card_stat <> '12'
            THEN
            if l_badcredit_flag='Y' then
                select vgd_debit_reversal
                into l_debit_reversal
                from  vms_group_tran_detl
                where vgd_group_id=l_badcredit_transgrpid;
                
                if l_debit_reversal='Y' then
                   l_cap_card_stat:='18';
                end if;
            end if;
               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_card_stat = l_cap_card_stat
                   WHERE     cap_inst_code = p_inst_code_in
                         AND cap_mbr_numb = '000'
                         AND cap_pan_code = l_hash_pan;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     l_errmsg :=
                        'Error while updating the card status as suspended CR';
                     l_resp_cde := '21';
                     RAISE exp_rvsl_reject_record;
                  ELSE
                     BEGIN
                        sp_log_cardstat_chnge (p_inst_code_in,
                                               l_hash_pan,
                                               l_encr_pan,
                                               p_auth_id_out,
                                               '03',
                                               p_rrn_in,
                                               p_business_date_in,
                                               p_business_time_in,
                                               l_resp_cde,
                                               l_errmsg);

                        IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
                        THEN
                           RAISE exp_rvsl_reject_record;
                        END IF;

                        l_resp_cde := '1';
                     EXCEPTION
                        WHEN exp_rvsl_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           l_resp_cde := '21';
                           l_errmsg :=
                              'Error while logging system initiated card status change '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_rvsl_reject_record;
                     END;
                  END IF;
               EXCEPTION
                  WHEN exp_rvsl_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_errmsg :=
                        'Error while updating cms_appl_pan-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END IF;
         END IF;

         --EN Max card balance check
         l_timestamp := SYSTIMESTAMP;

         IF l_complfree_flag = 'Y' AND l_completion_fee = 0
         THEN
		 --Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


      IF (v_Retdate>v_Retperiod)												--Added for VMS-5733/FSP-991
    THEN

            SELECT ctd_compfee_code
              INTO l_comp_fee_code
              FROM cms_transaction_log_dtl
             WHERE     ctd_rrn = p_rrn_in
                   AND ctd_business_date = l_orgnl_business_date
                   AND ctd_business_time = l_orgnl_business_time
                   AND ctd_customer_card_no = l_hash_pan
                   AND ctd_inst_code = p_inst_code_in
                   AND ctd_txn_code = l_orgnl_txn_code
                   AND ctd_auth_id = l_orgnl_auth_id
                   AND ctd_delivery_channel = l_orgnl_delivery_channel;
				   
	ELSE
	          SELECT ctd_compfee_code
              INTO l_comp_fee_code	
              FROM VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST                         --Added for VMS-5733/FSP-991
             WHERE  ctd_rrn = p_rrn_in
                   AND ctd_business_date = l_orgnl_business_date
                   AND ctd_business_time = l_orgnl_business_time
                   AND ctd_customer_card_no = l_hash_pan
                   AND ctd_inst_code = p_inst_code_in
                   AND ctd_txn_code = l_orgnl_txn_code
                   AND ctd_auth_id = l_orgnl_auth_id
                   AND ctd_delivery_channel = l_orgnl_delivery_channel;
	END IF;	

            BEGIN
               vmsfee.fee_freecnt_reverse (l_acct_no,
                                           l_comp_fee_code,
                                           l_errmsg);

               IF l_errmsg <> 'OK'
               THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_errmsg :=
                     'Error while reversing complfree count-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;

         BEGIN
		 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)  --Added for VMS-5733/FSP-991
    THEN
            SELECT csl_trans_narrration,
                   csl_merchant_name,
                   csl_merchant_city,
                   csl_merchant_state
              INTO l_txn_narration,
                   l_txn_merchname,
                   l_txn_merchcity,
                   l_txn_merchstate
              FROM cms_statements_log
             WHERE     csl_business_date = l_orgnl_business_date
                   AND csl_business_time = l_orgnl_business_time
                   AND csl_rrn = p_rrn_in
                   AND csl_delivery_channel = l_orgnl_delivery_channel
                   AND csl_txn_code = l_orgnl_txn_code
                   AND csl_pan_no = l_orgnl_customer_card_no
                   AND csl_inst_code = p_inst_code_in
                   AND csl_auth_id = l_orgnl_auth_id
                   AND txn_fee_flag = 'N';
		ELSE
			SELECT csl_trans_narrration,
                   csl_merchant_name,
                   csl_merchant_city,
                   csl_merchant_state
              INTO l_txn_narration,
                   l_txn_merchname,
                   l_txn_merchcity,
                   l_txn_merchstate
              FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
             WHERE     csl_business_date = l_orgnl_business_date
                   AND csl_business_time = l_orgnl_business_time
                   AND csl_rrn = p_rrn_in
                   AND csl_delivery_channel = l_orgnl_delivery_channel
                   AND csl_txn_code = l_orgnl_txn_code
                   AND csl_pan_no = l_orgnl_customer_card_no
                   AND csl_inst_code = p_inst_code_in
                   AND csl_auth_id = l_orgnl_auth_id
                   AND txn_fee_flag = 'N';
        END IF;		
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_txn_narration := NULL;
            WHEN OTHERS
            THEN
               l_txn_narration := NULL;
         END;

         --         IF l_orgnl_txn_totalfee_amt > 0
         --         THEN
         --            BEGIN
         --               SELECT csl_trans_narrration,
         --                      csl_merchant_name,
         --                      csl_merchant_city,
         --                      csl_merchant_state
         --                 INTO l_fee_narration,
         --                      l_fee_merchname,
         --                      l_fee_merchcity,
         --                      l_fee_merchstate
         --                 FROM cms_statements_log
         --                WHERE     csl_business_date = l_orgnl_business_date
         --                      AND csl_business_time = l_orgnl_business_time
         --                      AND csl_rrn = p_rrn_in
         --                      AND csl_delivery_channel = l_orgnl_delivery_channel
         --                      AND csl_txn_code = l_orgnl_txn_code
         --                      AND csl_pan_no = l_orgnl_customer_card_no
         --                      AND csl_auth_id = l_orgnl_auth_id
         --                      AND csl_inst_code = p_inst_code_in
         --                      AND txn_fee_flag = 'Y';
         --            EXCEPTION
         --               WHEN NO_DATA_FOUND
         --               THEN
         --                  l_fee_narration := NULL;
         --               WHEN OTHERS
         --               THEN
         --                  l_fee_narration := NULL;
         --            END;
         --         END IF;

         BEGIN
            sp_reverse_card_amount (p_inst_code_in,
                                    NULL,
                                    p_rrn_in,
                                    p_delivery_channel_in,
                                    l_orgnl_terminal_id,
                                    p_merc_id_in,
                                    p_txn_code_in,
                                    l_rvsl_trandate,
                                    p_txn_mode_in,
                                    p_card_no_in,
                                    l_reversal_amt + l_completion_fee,
                                    p_rrn_in,
                                    l_acct_no,
                                    p_business_date_in,
                                    p_business_time_in,
                                    p_auth_id_out,
                                    l_txn_narration,
                                    l_orgnl_business_date,
                                    l_orgnl_business_time,
                                    l_txn_merchname,
                                    l_txn_merchcity,
                                    l_txn_merchstate,
                                    l_resp_cde,
                                    l_errmsg);

            IF l_resp_cde <> '00' OR l_errmsg <> 'OK'
            THEN
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while reversing the amount-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF l_orgnl_txn_totalfee_amt > 0 OR l_orgnl_txn_feecode IS NOT NULL
         THEN
            BEGIN
               SELECT cfm_feecap_flag, cfm_fee_amt
                 INTO l_feecap_flag, l_orgnl_fee_amt
                 FROM cms_fee_mast
                WHERE cfm_inst_code = p_inst_code_in
                      AND cfm_fee_code = l_orgnl_txn_feecode;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_feecap_flag := '';
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error in feecap flag fetch-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

            FOR i
               IN (SELECT csl_trans_narrration,
                          csl_merchant_name,
                          csl_merchant_city,
                          csl_merchant_state,
                          csl_trans_amount
                     FROM VMSCMS.CMS_STATEMENTS_LOG_VW 								--Added for VMS-5739/FSP-991
                    WHERE     csl_business_date = l_orgnl_business_date
                          AND csl_business_time = l_orgnl_business_time
                          AND csl_rrn = p_rrn_in
                          AND csl_delivery_channel = l_orgnl_delivery_channel
                          AND csl_txn_code = l_orgnl_txn_code
                          AND csl_pan_no = l_orgnl_customer_card_no
                          AND csl_auth_id = l_orgnl_auth_id
                          AND csl_inst_code = p_inst_code_in
                          AND txn_fee_flag = 'Y')
            LOOP
               l_fee_narration := i.csl_trans_narrration;
               l_fee_merchname := i.csl_merchant_name;
               l_fee_merchcity := i.csl_merchant_city;
               l_fee_merchstate := i.csl_merchant_state;
               l_orgnl_tranfee_amt := i.csl_trans_amount;

               IF l_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_revcapcheck (p_inst_code_in,
                                               l_acct_no,
                                               l_orgnl_business_date,
                                               l_orgnl_tranfee_amt,
                                               l_orgnl_fee_amt,
                                               l_orgnl_txn_fee_plan,
                                               l_orgnl_txn_feecode,
                                               l_errmsg);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_resp_cde := '21';
                        l_errmsg :=
                           'Error while reversing the fee Cap amount-'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_rvsl_reject_record;
                  END;
               END IF;

               BEGIN
                  sp_reverse_fee_amount (p_inst_code_in,
                                         p_rrn_in,
                                         p_delivery_channel_in,
                                         l_orgnl_terminal_id,
                                         p_merc_id_in,
                                         p_txn_code_in,
                                         l_rvsl_trandate,
                                         p_txn_mode_in,
                                         l_orgnl_txn_totalfee_amt,
                                         p_card_no_in,
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
                                         p_rrn_in,
                                         l_acct_no,
                                         p_business_date_in,
                                         p_business_time_in,
                                         p_auth_id_out,
                                         l_fee_narration,
                                         l_fee_merchname,
                                         l_fee_merchcity,
                                         l_fee_merchstate,
                                         l_resp_cde,
                                         l_errmsg);

                  IF l_resp_cde <> '00' OR l_errmsg <> 'OK'
                  THEN
                     RAISE exp_rvsl_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_rvsl_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_errmsg :=
                        'Error while reversing the fee amount-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END LOOP;
         END IF;

         --SN : Reversal txn fee calc
         BEGIN
            sp_tran_reversal_fees (p_inst_code_in,
                                   p_card_no_in,
                                   p_delivery_channel_in,
                                   l_orgnl_txn_mode,
                                   p_txn_code_in,
                                   p_curr_code_in,
                                   NULL,
                                   NULL,
                                   l_reversal_amt,
                                   p_business_date_in,
                                   p_business_time_in,
                                   NULL,
                                   NULL,
                                   l_resp_cde,
                                   p_msg_typ_in,
                                   '000',
                                   p_rrn_in,
                                   p_terminal_id_in,
                                   l_txn_merchname,
                                   l_txn_merchcity,
                                   p_auth_id_out,
                                   l_txn_merchstate,
                                   p_rvsl_code_in,
                                   l_txn_narration,
                                   l_txn_type,
                                   l_rvsl_trandate,
                                   l_errmsg,
                                   l_resp_cde,
                                   l_fee_amt,
                                   l_fee_plan,
                                   l_fee_code,
                                   l_feeattach_type);

            IF l_errmsg <> 'OK'
            THEN
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while tran_reversal_fees process-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Reversal txn fee calc
         BEGIN
            INSERT INTO cms_preauth_trans_hist (cph_card_no,
                                                cph_mbr_no,
                                                cph_inst_code,
                                                cph_card_no_encr,
                                                cph_preauth_validflag,
                                                cph_completion_flag,
                                                cph_txn_amnt,
                                                cph_rrn,
                                                cph_txn_date,
                                                cph_txn_time,
                                                cph_orgnl_rrn,
                                                cph_orgnl_txn_date,
                                                cph_orgnl_txn_time,
                                                cph_orgnl_card_no,
                                                cph_terminalid,
                                                cph_orgnl_terminalid,
                                                cph_transaction_flag,
                                                cph_merchant_name,
                                                cph_delivery_channel,
                                                cph_tran_code,
                                                cph_panno_last4digit,
                                                cph_acct_no)
                 VALUES (l_hash_pan,
                         '000',
                         p_inst_code_in,
                         l_encr_pan,
                         'N',
                         'C',
                         p_actual_amt_in,
                         p_rrn_in,
                         p_business_date_in,
                         p_business_time_in,
                         p_rrn_in,
                         l_orgnl_business_date,
                         l_orgnl_business_time,
                         l_hash_pan,
                         p_terminal_id_in,
                         l_orgnl_terminal_id,
                         'R',
                         p_merchant_name_in,
                         p_delivery_channel_in,
                         p_txn_code_in,
                         SUBSTR (p_card_no_in, -4),
                         l_acct_no);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                  'Error while inserting  CMS_PREAUTH_TRANS_HIST'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
         END;

         IF l_preauth_expiry_flag = 'N'
         THEN
            BEGIN
			
			--Added for VMS-5739/FSP-991
			select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			INTO   v_Retperiod 
			FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
			WHERE  OPERATION_TYPE='ARCHIVE' 
			AND OBJECT_NAME='CMS_PREAUTH_TRANSACTION_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)														--Added for VMS-5739/FSP-991

    THEN
               UPDATE cms_preauth_transaction
                  SET cpt_totalhold_amt =
                         TRIM (
                            TO_CHAR (l_actual_dispatched_amt,
                                     '999999999999999990.99')),
                      cpt_transaction_rrn = p_rrn_in,
                      cpt_preauth_validflag =
                         DECODE (l_actual_dispatched_amt,
                                 0, 'N',
                                 cpt_preauth_validflag),
                      cpt_transaction_flag = 'R',
                      cpt_expiry_flag = 'Y'
                WHERE     cpt_rrn = p_rrn_in
                      AND cpt_txn_date = l_orgnl_business_date
                      AND cpt_txn_time = l_orgnl_business_time
                      AND cpt_terminalid = l_orgnl_terminal_id
                      AND cpt_mbr_no = '000'
                      AND cpt_inst_code = p_inst_code_in
                      AND cpt_card_no = l_hash_pan;
ELSE

				UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST				--Added for VMS-5739/FSP-991
                  SET cpt_totalhold_amt =
                         TRIM (
                            TO_CHAR (l_actual_dispatched_amt,
                                     '999999999999999990.99')),
                      cpt_transaction_rrn = p_rrn_in,
                      cpt_preauth_validflag =
                         DECODE (l_actual_dispatched_amt,
                                 0, 'N',
                                 cpt_preauth_validflag),
                      cpt_transaction_flag = 'R',
                      cpt_expiry_flag = 'Y'
                WHERE     cpt_rrn = p_rrn_in
                      AND cpt_txn_date = l_orgnl_business_date
                      AND cpt_txn_time = l_orgnl_business_time
                      AND cpt_terminalid = l_orgnl_terminal_id
                      AND cpt_mbr_no = '000'
                      AND cpt_inst_code = p_inst_code_in
                      AND cpt_card_no = l_hash_pan;
END IF;					  

               IF SQL%ROWCOUNT = 0
               THEN
                  l_errmsg := 'Record not updated in cms_preauth_transaction';
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE exp_rvsl_reject_record;
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error while updating  cms_preauth_transaction-'
                     || SUBSTR (SQLERRM, 1, 300);
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;

         --SN : Reverse free fee count
         IF l_orgnl_txn_totalfee_amt = 0 AND l_orgnl_txn_feecode IS NOT NULL
         THEN
            BEGIN
               vmsfee.fee_freecnt_reverse (l_acct_no,
                                           l_orgnl_txn_feecode,
                                           l_errmsg);

               IF l_errmsg <> 'OK'
               THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_errmsg :=
                     'Error while reversing freefee count-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;

         --EN : Reverse free fee count
         --SN : Reset limit count
         BEGIN
            IF     l_add_ins_date IS NOT NULL
               AND l_prfl_code IS NOT NULL
               AND l_prfl_flag = 'Y'
            THEN
               pkg_limits_check.sp_limitcnt_rever_reset (
                  p_inst_code_in,
                  NULL,
                  NULL,
                  l_orgnl_mcccode,
                  l_orgnl_txn_code,
                  l_tran_type,
                  l_internation_ind_response,
                  l_pos_verification,
                  l_prfl_code,
                  l_reversal_amt,
                  l_orgnl_txn_amnt,
                  p_delivery_channel_in,
                  l_hash_pan,
                  l_add_ins_date,
                  l_resp_cde,
                  l_errmsg);
            END IF;

            IF l_errmsg <> 'OK'
            THEN
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error from Limit count reveer Process-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Reset limit count
         BEGIN
		 
		--Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)											--Added for VMS-5739/FSP-991	
    THEN 
	
            UPDATE cms_statements_log
               SET csl_prod_code = l_prod_code,
                   csl_acct_type = l_acct_type,
                   csl_card_type = l_card_type,
                   csl_time_stamp = l_timestamp
             WHERE     csl_inst_code = p_inst_code_in
                   AND csl_pan_no = l_hash_pan
                   AND csl_rrn = p_rrn_in
                   AND csl_txn_code = p_txn_code_in
                   AND csl_delivery_channel = p_delivery_channel_in
                   AND csl_auth_id = p_auth_id_out
                   AND csl_business_date = p_business_date_in
                   AND csl_business_time = p_business_time_in;
ELSE
			UPDATE VMSCMS_HISTORY.cms_statements_log_HIST        	--Added for VMS-5739/FSP-991	
               SET csl_prod_code = l_prod_code,
                   csl_acct_type = l_acct_type,
                   csl_card_type = l_card_type,
                   csl_time_stamp = l_timestamp
             WHERE     csl_inst_code = p_inst_code_in
                   AND csl_pan_no = l_hash_pan
                   AND csl_rrn = p_rrn_in
                   AND csl_txn_code = p_txn_code_in
                   AND csl_delivery_channel = p_delivery_channel_in
                   AND csl_auth_id = p_auth_id_out
                   AND csl_business_date = p_business_date_in
                   AND csl_business_time = p_business_time_in;

END IF;
				   

            IF SQL%ROWCOUNT = 0
            THEN
               NULL;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while updating timestamp in statementlog-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --SN : Update reversal flag for txn
         BEGIN
		
		--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)										--Added for VMS-5739/FSP-991
    THEN
	
            UPDATE transactionlog
               SET tran_reverse_flag = 'Y'
             WHERE     rrn = p_rrn_in
                   AND business_date = l_orgnl_business_date
                   AND business_time = l_orgnl_business_time
                   AND response_code = '00'
                   AND customer_card_no = l_hash_pan
                   AND auth_id = l_orgnl_auth_id
                   AND instcode = p_inst_code_in
                   AND NVL (tran_reverse_flag, 'N') <> 'Y'
                   AND msgtype = '1100';
ELSE
			
			UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST        --Added for VMS-5739/FSP-991
               SET tran_reverse_flag = 'Y'
             WHERE     rrn = p_rrn_in
                   AND business_date = l_orgnl_business_date
                   AND business_time = l_orgnl_business_time
                   AND response_code = '00'
                   AND customer_card_no = l_hash_pan
                   AND auth_id = l_orgnl_auth_id
                   AND instcode = p_inst_code_in
                   AND NVL (tran_reverse_flag, 'N') <> 'Y'
                   AND msgtype = '1100';
END IF;				   

            IF SQL%ROWCOUNT = 0
            THEN
               l_resp_cde := '52';
               l_errmsg := 'Reversal/Deactivation already done';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while updating txn reversal flag- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Update reversal flag for txn
         --SN : Get b24 responsse code from response master
         l_resp_cde := '1';

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE     cms_inst_code = p_inst_code_in
                   AND cms_delivery_channel = p_delivery_channel_in
                   AND cms_response_id = TO_NUMBER (l_resp_cde);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                  'Problem while selecting data from response master for respose code'
                  || l_resp_cde
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '69';
               RAISE exp_rvsl_reject_record;
         END;

         --EN : Get b24 responsse code from response master
         --SN : Set out parameters
         --p_curr_out := p_curr_code_in;
         p_autherized_amount_out :=
            TO_CHAR (l_reversal_amt, '99999999999999990.99');
         p_resp_msg_out := 'OK';
         --EN : Set out parameters
         l_tran_amt := l_reversal_amt;
      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_rvsl_reject_record
         THEN
            ROLLBACK;
            --SN : Set out parameters
            p_auth_id_out := 0;
            --p_curr_out := p_curr_code_in;
            p_autherized_amount_out := '0.00';
            p_resp_msg_out := l_errmsg;

            IF l_dupl_indc = 1
            THEN
               BEGIN
		
                  SELECT response_code
                    INTO p_resp_code_out
                    FROM VMSCMS.TRANSACTIONLOG_VW a,									--Added for VMS-5739/FSP-991
                         (SELECT MIN (add_ins_date) mindate
                            FROM VMSCMS.TRANSACTIONLOG_VW 										--Added for VMS-5739/FSP-991		
                           WHERE rrn = p_rrn_in AND acct_balance IS NOT NULL) b
                   WHERE     a.add_ins_date = mindate
                         AND rrn = p_rrn_in
                         AND acct_balance IS NOT NULL;
						   
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_resp_msg_out :=
                        'Problem in selecting the response detail of Original transaction-'
                        || SUBSTR (SQLERRM, 1, 300);
                     p_resp_code_out := '89';
                     ROLLBACK;
               END;
            ELSE
               BEGIN
                  SELECT cms_iso_respcde
                    INTO p_resp_code_out
                    FROM cms_response_mast
                   WHERE     cms_inst_code = p_inst_code_in
                         AND cms_delivery_channel = p_delivery_channel_in
                         AND cms_response_id = TO_NUMBER (l_resp_cde);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_resp_msg_out :=
                        'Problem while selecting data from response master '
                        || l_resp_cde
                        || ' is-'
                        || SUBSTR (SQLERRM, 1, 300);
                     p_resp_code_out := '89';
               END;
            END IF;
         --EN : Set out parameters
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            l_resp_cde := '89';

            --SN : Set out parameters
            BEGIN
               p_auth_id_out := 0;
               --p_curr_out := p_curr_code_in;
               p_autherized_amount_out := '0.00';
               p_resp_msg_out := l_errmsg;

               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_inst_code_in
                      AND cms_delivery_channel = p_delivery_channel_in
                      AND cms_response_id = TO_NUMBER (l_resp_cde);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg_out :=
                        'Problem while selecting data from response master '
                     || l_resp_cde
                     || ' is-'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code_out := '89';
            END;
      --EN : Set out parameters
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_desc
              INTO l_dr_cr_flag, l_txn_type, l_tran_desc
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

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
                   l_acct_no,
                   l_proxy_number
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
           INTO l_acct_balance, l_ledger_balance, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_no AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_balance := 0;
            l_ledger_balance := 0;
      END;

      --EN : Get balance details from acct master
      p_balance_out := TO_CHAR (l_acct_balance, '99999999999999990.99');

      --SN : Make entry in transactionlog
      BEGIN
         INSERT INTO transactionlog (msgtype,
                                     rrn,
                                     delivery_channel,
                                     terminal_id,
                                     date_time,
                                     txn_code,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     response_code,
                                     business_date,
                                     business_time,
                                     customer_card_no,
                                     bank_code,
                                     total_amount,
                                     currencycode,
                                     productid,
                                     categoryid,
                                     auth_id,
                                     trans_desc,
                                     amount,
                                     system_trace_audit_no,
                                     instcode,
                                     tranfee_amt,
                                     feecode,
                                     fee_plan,
                                     feeattachtype,
                                     cr_dr_flag,
                                     customer_card_no_encr,
                                     proxy_number,
                                     reversal_code,
                                     customer_acct_no,
                                     acct_balance,
                                     ledger_balance,
                                     response_id,
                                     merchant_name,
                                     add_ins_user,
                                     error_msg,
                                     cardstatus,
                                     store_id,
                                     time_stamp,
                                     acct_type,
                                     spil_prod_id,
                                     spil_fee,
                                     spil_upc,
                                     spil_merref_num,
                                     spil_req_tmzm,
                                     spil_loc_cntry,
                                     spil_loc_crcy,
                                     spil_loc_lang,
                                     spil_pos_entry,
                                     spil_pos_cond)
              VALUES (
                        p_msg_typ_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_terminal_id_in,
                        TRUNC (SYSDATE),
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        DECODE (p_resp_code_out, '00', 'C', 'F'),
                        p_resp_code_out,
                        p_business_date_in,
                        p_business_time_in,
                        l_hash_pan,
                        p_inst_code_in,
                        TRIM (
                           TO_CHAR (
                              DECODE (
                                 p_resp_code_out,
                                 '00', (l_reversal_amt
                                        + l_orgnl_txn_totalfee_amt),
                                 l_tran_amt),
                              '999999999999999990.99')),
                        l_currcode,
                        l_prod_code,
                        l_card_type,
                        p_auth_id_out,
                        l_tran_desc,
                        TRIM (
                           TO_CHAR (
                              DECODE (p_resp_code_out,
                                      '00', l_reversal_amt,
                                      l_tran_amt),
                              '999999999999999990.99')),
                        p_stan_in,
                        p_inst_code_in,
                        NVL (TO_CHAR (l_fee_amt, '99999999999999990.99'),
                             '0.00'),
                        l_fee_code,
                        l_fee_plan,
                        l_feeattach_type,
                        DECODE (l_dr_cr_flag,
                                'CR', 'DR',
                                'DR', 'CR',
                                l_dr_cr_flag),
                        l_encr_pan,
                        l_proxy_number,
                        p_rvsl_code_in,
                        l_acct_no,
                        l_acct_balance,
                        l_ledger_balance,
                        l_resp_cde,
                        p_merchant_name_in,
                        1,
                        p_resp_msg_out,
                        l_card_stat,
                        p_store_id_in,
                        NVL (l_timestamp, SYSTIMESTAMP),
                        l_acct_type,
                        p_product_id_in,
                        p_fee_amt_in,
                        p_upc_in,
                        p_mercrefnum_in,
                        p_reqtimezone_in,
                        p_localcountry_in,
                        p_localcurrency_in,
                        p_loclanguage_in,
                        p_posentry_in,
                        p_poscond_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_resp_code_out := '89';
            p_resp_msg_out :=
               'Problem while inserting data into transaction log- '
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --EN : Make entry in transactionlog
      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_channel_in
               || p_txn_code_in
               || p_card_no_in
               || p_rrn_in
               || TO_CHAR (NVL (l_timestamp, SYSTIMESTAMP),
                           'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            p_resp_msg_out :=
               'Error while generating hashkey_id '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      --SN : Make entry in cms_transaction_log_dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                              ctd_txn_code,
                                              ctd_txn_type,
                                              ctd_msg_type,
                                              ctd_txn_mode,
                                              ctd_business_date,
                                              ctd_business_time,
                                              ctd_customer_card_no,
                                              ctd_txn_amount,
                                              ctd_txn_curr,
                                              ctd_actual_amount,
                                              ctd_fee_amount,
                                              ctd_bill_amount,
                                              ctd_bill_curr,
                                              ctd_process_flag,
                                              ctd_process_msg,
                                              ctd_rrn,
                                              ctd_system_trace_audit_no,
                                              ctd_inst_code,
                                              ctd_customer_card_no_encr,
                                              ctd_cust_acct_number,
                                              ctd_hashkey_id,
                                              ctd_ins_user,
                                              ctd_ins_date,
                                              ctd_store_address1,
                                              ctd_store_address2,
                                              ctd_store_city,
                                              ctd_store_state,
                                              ctd_store_zip)
              VALUES (
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_msg_typ_in,
                        p_txn_mode_in,
                        p_business_date_in,
                        p_business_time_in,
                        l_hash_pan,
                        TRIM (
                           TO_CHAR (NVL (l_tran_amt, p_actual_amt_in),
                                    '99999999999990.99')),
                        l_currcode,
                        TO_CHAR (NVL (l_reversal_amt, p_actual_amt_in),
                                 '99999999999990.99'),
                        NVL (TO_CHAR (l_fee_amt, '99999999999999990.99'),
                             '0.00'),
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999999.99')),
                           p_actual_amt_in),
                        l_card_curr,
                        DECODE (p_resp_code_out, '00', 'Y', 'E'),
                        DECODE (p_resp_code_out,
                                '00', 'Successful',
                                p_resp_msg_out),
                        p_rrn_in,
                        p_stan_in,
                        p_inst_code_in,
                        l_encr_pan,
                        l_acct_no,
                        l_hashkey_id,
                        1,
                        SYSDATE,
                        p_address1_in,
                        p_address2_in,
                        p_city_in,
                        p_state_in,
                        p_zip_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  dtl-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
            ROLLBACK;
      END;

      --EN : Make entry in cms_transaction_log_dtl
      IF p_resp_msg_out = 'OK'
      THEN
         p_resp_msg_out := 'Success';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '89';
         p_resp_msg_out := 'Main Excp- ' || SUBSTR (SQLERRM, 1, 300);
   END redemption_lock_reversal;

   PROCEDURE Store_credit (P_INST_CODE_IN          IN     NUMBER,
                           P_RRN_IN                IN     VARCHAR2,
                           P_TERMINALID_IN         IN     VARCHAR2,
                           P_STAN_IN               IN     VARCHAR2,
                           P_TRANDATE_IN           IN     VARCHAR2,
                           P_TRANTIME_IN           IN     VARCHAR2,
                           P_PAN_CODE_IN           IN     VARCHAR2,
                           P_AMOUNT_IN             IN     NUMBER,
                           P_CURRCODE_IN           IN     VARCHAR2,
                           P_MSG_TYPE_IN           IN     VARCHAR2,
                           P_TXN_CODE_IN           IN     VARCHAR2,
                           P_TXN_MODE_IN           IN     VARCHAR2,
                           P_DELIVERY_CHANNEL_IN   IN     VARCHAR2,
                           P_RVSL_CODE_IN          IN     VARCHAR2,
                           P_Merchant_Name_IN      IN     VARCHAR2,
                           P_STORE_ID_IN           IN     VARCHAR2,
                           P_SERIAL_NUMBER_IN      IN     VARCHAR2,
                           P_ADDRESS1_IN           IN     VARCHAR2,
                           P_ADDRESS2_IN           IN     VARCHAR2,
                           P_CITY_IN               IN     VARCHAR2,
                           P_STATE_IN              IN     VARCHAR2,
                           P_ZIP_IN                IN     VARCHAR2,
                           P_SPIL_PROD_ID_IN       IN     VARCHAR2,
                           P_SPIL_FEE_IN           IN     NUMBER,
                           P_SPIL_UPC_IN           IN     VARCHAR2,
                           P_SPIL_MERREF_NUM_IN    IN     VARCHAR2,
                           P_SPIL_REQ_TMZM_IN      IN     VARCHAR2,
                           P_SPIL_LOC_CNTRY_IN     IN     VARCHAR2,
                           P_SPIL_LOC_CRCY_IN      IN     VARCHAR2,
                           P_SPIL_LOC_LANG_IN      IN     VARCHAR2,
                           P_SPIL_POS_ENTRY_IN     IN     VARCHAR2,
                           P_SPIL_POS_COND_IN      IN     VARCHAR2,
                           P_RESP_CODE_OUT            OUT VARCHAR2,
                           P_ERRMSG_OUT               OUT VARCHAR2,
                           P_RESP_MSG_TYPE_OUT        OUT VARCHAR2,
                           P_ACCT_BAL_OUT             OUT VARCHAR2,
                           P_AUTH_ID_OUT              OUT VARCHAR2)
   AS
         		 /*************************************************
	  * Modified By      : Veneetha C
     * Modified Date    : 21-JAN-2019
     * Purpose          : VMS-622 Redemption delay for activations /reloads processed through ICGPRM
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST R11
*************************************************/ 
      l_CAP_CARD_STAT          CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
      l_FIRSTTIME_TOPUP        CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
      l_PROD_CODE              CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
      l_CARD_TYPE              CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
      l_PROFILE_CODE           CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
      l_VARPRODFLAG            cms_prod_cattype.CPC_RELOADABLE_FLAG%TYPE;
      l_CURRCODE               GEN_CURR_MAST.GCM_CURR_CODE%TYPE;
      l_RESPCODE               cms_response_mast.CMS_RESPONSE_ID%TYPE;
      l_RESPMSG                VARCHAR2 (500);
      l_CAPTURE_DATE           DATE;
      l_TXN_TYPE               CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
      l_HASH_PAN               CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
      l_ENCR_PAN               CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
      l_ACCT_BALANCE           NUMBER;
      l_LEDGER_BALANCE         NUMBER;
      l_TRAN_AMT               NUMBER;
      l_CARD_CURR              GEN_CURR_MAST.GCM_CURR_CODE%TYPE;
      l_PROXUNUMBER            CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
      l_ACCT_NUMBER            CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
      l_CARDTYPE_FLAG          CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE;
      l_STATERISSUSETYPE       CMS_PROD_CATTYPE.CPC_STARTERGPR_ISSUE%TYPE;
      l_DUPCHK_CARDSTAT        TRANSACTIONLOG.CARDSTATUS%TYPE;
      l_DUPCHK_ACCTBAL         TRANSACTIONLOG.ACCT_BALANCE%TYPE;
      l_DUPCHK_COUNT           NUMBER;
      l_count                  NUMBER;
      l_TRANS_DESC             CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
      l_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_acct_type              cms_acct_mast.cam_type_code%TYPE;
      l_comb_hash              pkg_limits_check.type_hash;
      l_tran_type              cms_transaction_mast.ctm_tran_type%TYPE;
      l_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
      l_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_redmption_delay_flag   cms_prod_cattype.cpc_redemption_delay_flag%TYPE;
      l_txn_redmption_flag     cms_transaction_mast.ctm_redemption_delay_flag%TYPE;
      l_CPC_PROD_DENO          CMS_PROD_CATTYPE.CPC_PROD_DENOM%TYPE;
      l_CPC_PDEN_MIN           CMS_PROD_CATTYPE.CPC_PDENOM_MIN%TYPE;
      l_CPC_PDEN_MAX           CMS_PROD_CATTYPE.CPC_PDENOM_MAX%TYPE;
      l_CPC_PDEN_FIX           CMS_PROD_CATTYPE.CPC_PDENOM_FIX%TYPE;
      EXP_MAIN_REJECT_RECORD   EXCEPTION;
      EXP_AUTH_REJECT_RECORD   EXCEPTION;
      EXP_DUPLICATE_REQUEST    EXCEPTION;
	  
	  v_Retperiod  date;  --Added for VMS-5739/FSP-991
      v_Retdate  date; --Added for VMS-5739/FSP-991
   BEGIN
      P_ERRMSG_OUT := 'OK';
      P_RESP_MSG_TYPE_OUT := 'Success';
      l_TRAN_AMT := P_AMOUNT_IN;

      BEGIN
         l_HASH_PAN := GETHASH (P_PAN_CODE_IN);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_RESPCODE := '21';
            P_ERRMSG_OUT :=
               'Error while converting hashpan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
      END;

      BEGIN
         l_ENCR_PAN := FN_EMAPS_MAIN (P_PAN_CODE_IN);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_RESPCODE := '21';
            P_ERRMSG_OUT :=
               'Error while converting encrpan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
      END;

      BEGIN
         SELECT CTM_TRAN_DESC,
                ctm_credit_debit_flag,
                TO_NUMBER (DECODE (CTM_TRAN_TYPE,  'N', '0',  'F', '1')),
                ctm_prfl_flag,
                ctm_tran_type,
                NVL (ctm_redemption_delay_flag, 'N')
           INTO l_TRANS_DESC,
                l_dr_cr_flag,
                l_TXN_TYPE,
                l_prfl_flag,
                l_tran_type,
                l_txn_redmption_flag
           FROM CMS_TRANSACTION_MAST
          WHERE     CTM_TRAN_CODE = P_TXN_CODE_IN
                AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
                AND CTM_INST_CODE = P_INST_CODE_IN;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_RESPCODE := '21';
            P_ERRMSG_OUT :=
               'Error while selecting transaction mast '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
      END;

      BEGIN
         SELECT CAP_CARD_STAT,
                CAP_FIRSTTIME_TOPUP,
                CAP_PROD_CODE,
                CAP_CARD_TYPE,
                CAP_PROXY_NUMBER,
                CAP_ACCT_NO,
                CAP_STARTERCARD_FLAG,
                cap_prfl_code
           INTO l_CAP_CARD_STAT,
                l_FIRSTTIME_TOPUP,
                l_PROD_CODE,
                l_CARD_TYPE,
                l_PROXUNUMBER,
                l_ACCT_NUMBER,
                l_CARDTYPE_FLAG,
                l_prfl_code
           FROM CMS_APPL_PAN
          WHERE     CAP_PAN_CODE = l_HASH_PAN
                AND CAP_Mbr_Numb = '000'
                AND CAP_INST_CODE = P_INST_CODE_IN;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_RESPCODE := '21';
            P_ERRMSG_OUT :=
               'Error while selecting card number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
      END;

      IF l_CARDTYPE_FLAG = 'N' AND l_FIRSTTIME_TOPUP = 'N'
      THEN
         l_RESPCODE := '8';
         P_ERRMSG_OUT :=
            'Store credit is applicable only after initial load for this acctno '
            || l_HASH_PAN;
         RAISE exp_main_reject_record;
      END IF;

      BEGIN
         SELECT NVL (CARDSTATUS, 0), ACCT_BALANCE
           INTO l_DUPCHK_CARDSTAT, l_DUPCHK_ACCTBAL
           FROM (  SELECT CARDSTATUS, ACCT_BALANCE
                     FROM VMSCMS.TRANSACTIONLOG							--Added for VMS-5739/FSP-991
                    WHERE     RRN = P_RRN_IN
                          AND CUSTOMER_CARD_NO = l_HASH_PAN
                          AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
                          AND ACCT_BALANCE IS NOT NULL
                 ORDER BY add_ins_date DESC)
          WHERE ROWNUM = 1;
		   IF SQL%ROWCOUNT = 0 THEN
		    SELECT NVL (CARDSTATUS, 0), ACCT_BALANCE
           INTO l_DUPCHK_CARDSTAT, l_DUPCHK_ACCTBAL
           FROM (  SELECT CARDSTATUS, ACCT_BALANCE
                     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST							--Added for VMS-5739/FSP-991
                    WHERE     RRN = P_RRN_IN
                          AND CUSTOMER_CARD_NO = l_HASH_PAN
                          AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
                          AND ACCT_BALANCE IS NOT NULL
                 ORDER BY add_ins_date DESC)
          WHERE ROWNUM = 1;
		   END IF;

         l_DUPCHK_COUNT := 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_DUPCHK_COUNT := 0;
         WHEN OTHERS
         THEN
            l_RESPCODE := '21';
            P_ERRMSG_OUT :=
               'Error while selecting card status and acct balance '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
      END;

      IF l_DUPCHK_COUNT = 1
      THEN
         BEGIN
            SELECT CAM_ACCT_BAL
              INTO l_ACCT_BALANCE
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO = l_ACCT_NUMBER
                   AND CAM_INST_CODE = P_INST_CODE_IN;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_RESPCODE := '12';
               P_ERRMSG_OUT :=
                  'Error while selecting acct balance '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_MAIN_REJECT_RECORD;
         END;

         l_DUPCHK_COUNT := 0;

         IF l_DUPCHK_CARDSTAT = l_CAP_CARD_STAT
            AND l_DUPCHK_ACCTBAL = l_ACCT_BALANCE
         THEN
            l_DUPCHK_COUNT := 1;
            l_RESPCODE := '22';
            P_ERRMSG_OUT := 'Duplicate Incomm Reference Number' || P_RRN_IN;
            RAISE EXP_DUPLICATE_REQUEST;
         END IF;
      END IF;

      IF P_SERIAL_NUMBER_IN IS NOT NULL
      THEN
         BEGIN
            SELECT COUNT (1)
              INTO l_COUNT
              FROM CMS_SPILSERIAL_LOGGING
             WHERE     CSL_INST_CODE = P_INST_CODE_IN
                   AND CSL_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
                   AND CSL_TXN_CODE = P_TXN_CODE_IN
                   AND CSL_MSG_TYPE = P_MSG_TYPE_IN
                   AND CSL_SERIAL_NUMBER = P_SERIAL_NUMBER_IN
                   AND CSL_RESPONSE_CODE = '00';

            IF l_COUNT > 0
            THEN
               l_RESPCODE := '215';
               P_ERRMSG_OUT := 'Duplicate Request';
               RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_MAIN_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_RESPCODE := '21';
               P_ERRMSG_OUT :=
                  'Error while validating serial number '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_MAIN_REJECT_RECORD;
         END;
      END IF;


      BEGIN
         SELECT CPC_RELOADABLE_FLAG,
                CPC_PROD_DENOM,
                CPC_PDENOM_MIN,
                CPC_PDENOM_MAX,
                CPC_PDENOM_FIX,
                CPC_PROFILE_CODE,
                CPC_STARTERGPR_ISSUE,
                NVL (cpc_redemption_delay_flag, 'N')
           INTO l_VARPRODFLAG,
                l_CPC_PROD_DENO,
                l_CPC_PDEN_MIN,
                l_CPC_PDEN_MAX,
                l_CPC_PDEN_FIX,
                l_PROFILE_CODE,
                l_STATERISSUSETYPE,
                l_redmption_delay_flag
           FROM cms_prod_cattype
          WHERE     cpc_prod_code = l_PROD_CODE
                AND cpc_card_type = l_CARD_TYPE
                AND cpc_inst_code = P_INST_CODE_IN;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_RESPCODE := '12';
            P_ERRMSG_OUT :=
               'Error while selecting data from CMS_PROD_CATTYPE for Product code'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;


      IF l_VARPRODFLAG = 'Y'
      THEN
         IF l_CPC_PROD_DENO = 1
         THEN
            IF l_TRAN_AMT NOT BETWEEN l_CPC_PDEN_MIN AND l_CPC_PDEN_MAX
            THEN
               l_RESPCODE := '43';
               P_ERRMSG_OUT := 'Invalid Amount';
               RAISE exp_main_reject_record;
            END IF;
         ELSIF l_CPC_PROD_DENO = 2
         THEN
            IF l_TRAN_AMT <> l_CPC_PDEN_FIX
            THEN
               l_RESPCODE := '43';
               P_ERRMSG_OUT := 'Invalid Amount';
               RAISE exp_main_reject_record;
            END IF;
         ELSIF l_CPC_PROD_DENO = 3
         THEN
            SELECT COUNT (*)
              INTO l_count
              FROM VMS_PRODCAT_DENO_MAST
             WHERE     VPD_INST_CODE = P_INST_CODE_IN
                   AND VPD_PROD_CODE = l_PROD_CODE
                   AND VPD_CARD_TYPE = l_CARD_TYPE
                   AND VPD_PDEN_VAL = l_TRAN_AMT;

            IF l_count = 0
            THEN
               l_RESPCODE := '43';
               P_ERRMSG_OUT := 'Invalid Amount';
               RAISE exp_main_reject_record;
            END IF;
         END IF;
      ELSE
         l_RESPCODE := '17';
         P_ERRMSG_OUT :=
            'Store credit is not applicable on this card number '
            || l_HASH_PAN;
         RAISE EXP_MAIN_REJECT_RECORD;
      END IF;


      BEGIN
         SELECT GCM_CURR_CODE
           INTO l_CURRCODE
           FROM GEN_CURR_MAST
          WHERE GCM_CURR_NAME = P_CURRCODE_IN
                AND GCM_INST_CODE = P_INST_CODE_IN;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_RESPCODE := '21';
            P_ERRMSG_OUT :=
               'Error while selecting the currency code for '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
      END;

      BEGIN
         IF (P_AMOUNT_IN >= 0)
         THEN
            l_TRAN_AMT := P_AMOUNT_IN;

            BEGIN
               SP_CONVERT_CURR (P_INST_CODE_IN,
                                l_CURRCODE,
                                P_PAN_CODE_IN,
                                P_AMOUNT_IN,
                                NULL,
                                l_TRAN_AMT,
                                l_CARD_CURR,
                                P_ERRMSG_OUT,
                                l_PROD_CODE,
                                l_CARD_TYPE);

               IF P_ERRMSG_OUT <> 'OK'
               THEN
                  l_RESPCODE := '21';
                  RAISE EXP_MAIN_REJECT_RECORD;
               END IF;
            EXCEPTION
               WHEN EXP_MAIN_REJECT_RECORD
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_RESPCODE := '69';
                  P_ERRMSG_OUT :=
                     'Error from currency conversion '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_MAIN_REJECT_RECORD;
            END;
         ELSE
            l_RESPCODE := '43';
            P_ERRMSG_OUT := 'INVALID AMOUNT';
            RAISE EXP_MAIN_REJECT_RECORD;
         END IF;
      END;


      IF l_prfl_code IS NOT NULL AND l_prfl_flag = 'Y'
      THEN
         BEGIN
            pkg_limits_check.sp_limits_check (l_HASH_PAN,
                                              NULL,
                                              NULL,
                                              NULL,
                                              P_TXN_CODE_IN,
                                              l_tran_type,
                                              NULL,
                                              NULL,
                                              P_INST_CODE_IN,
                                              NULL,
                                              l_prfl_code,
                                              l_TRAN_AMT,
                                              P_DELIVERY_CHANNEL_IN,
                                              l_comb_hash,
                                              l_RESPCODE,
                                              P_ERRMSG_OUT);

            IF P_ERRMSG_OUT <> 'OK'
            THEN
               --l_RESPCODE := '21';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_RESPCODE := '21';
               P_ERRMSG_OUT :=
                  'Error from Limit Check Process '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      END IF;

      BEGIN
         SP_AUTHORIZE_TXN_CMS_AUTH (P_INST_CODE_IN,
                                    P_MSG_TYPE_IN,
                                    P_RRN_IN,
                                    P_DELIVERY_CHANNEL_IN,
                                    P_TERMINALID_IN,
                                    P_TXN_CODE_IN,
                                    P_TXN_MODE_IN,
                                    P_TRANDATE_IN,
                                    P_TRANTIME_IN,
                                    P_PAN_CODE_IN,
                                    NULL,
                                    l_TRAN_AMT,
                                    P_Merchant_Name_IN,
                                    NULL,
                                    NULL,
                                    l_CURRCODE,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    P_STAN_IN,
                                    '000',
                                    P_RVSL_CODE_IN,
                                    l_TRAN_AMT,
                                    P_AUTH_ID_OUT,
                                    l_RESPCODE,
                                    l_RESPMSG,
                                    l_CAPTURE_DATE,
                                    'Y',
                                         'N',
                                         'N',
                                         NULL,
                                         p_zip_in--added for VMS-622 (redemption_delay zip code validation)
                                    );

         IF l_RESPCODE <> '00' AND l_RESPMSG <> 'OK'
         THEN
            --l_RESPCODE := '21';
            P_ERRMSG_OUT := l_RESPMSG;
            RAISE EXP_AUTH_REJECT_RECORD;
         END IF;
      EXCEPTION
         WHEN EXP_AUTH_REJECT_RECORD
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            l_RESPCODE := '21';
            P_ERRMSG_OUT :=
               'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
      END;

      l_RESPCODE := 1;


      BEGIN
         P_ERRMSG_OUT := P_ERRMSG_OUT;
         P_RESP_CODE_OUT := l_RESPCODE;

         SELECT CMS_ISO_RESPCDE
           INTO P_RESP_CODE_OUT
           FROM CMS_RESPONSE_MAST
          WHERE     CMS_INST_CODE = P_INST_CODE_IN
                AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
                AND CMS_RESPONSE_ID = l_RESPCODE;
      EXCEPTION
         WHEN OTHERS
         THEN
            P_ERRMSG_OUT :=
                  'Problem while selecting data from response master '
               || l_RESPCODE
               || SUBSTR (SQLERRM, 1, 300);
            P_RESP_CODE_OUT := '69';
            ROLLBACK;
      END;


      IF P_ERRMSG_OUT = 'OK'
      THEN
         BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
              INTO l_ACCT_BALANCE, l_LEDGER_BALANCE
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO = l_ACCT_NUMBER
                   AND CAM_INST_CODE = P_INST_CODE_IN;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_RESPCODE := '12';
               P_ERRMSG_OUT :=
                  'Error while selecting account master '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_MAIN_REJECT_RECORD;
         END;

         P_ACCT_BAL_OUT := l_ACCT_BALANCE;
      END IF;

      BEGIN
		
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRANDATE_IN), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)									--Added for VMS-5739/FSP-991	

    THEN
         UPDATE Transactionlog
            SET Store_Id = P_STORE_ID_IN,
                ACCT_BALANCE = l_ACCT_BALANCE,
                LEDGER_BALANCE = l_LEDGER_BALANCE,
                SPIL_PROD_ID = P_SPIL_PROD_ID_IN,
                SPIL_FEE = P_SPIL_FEE_IN,
                SPIL_UPC = P_SPIL_UPC_IN,
                SPIL_MERREF_NUM = P_SPIL_MERREF_NUM_IN,
                SPIL_REQ_TMZM = P_SPIL_REQ_TMZM_IN,
                SPIL_LOC_CNTRY = P_SPIL_LOC_CNTRY_IN,
                SPIL_LOC_CRCY = P_SPIL_LOC_CRCY_IN,
                SPIL_LOC_LANG = P_SPIL_LOC_LANG_IN,
                SPIL_POS_ENTRY = P_SPIL_POS_ENTRY_IN,
                SPIL_POS_COND = P_SPIL_POS_COND_IN
          --error_msg = 'Success'
          WHERE     Instcode = P_INST_CODE_IN
                AND Rrn = P_RRN_IN
                AND CUSTOMER_CARD_NO = l_HASH_PAN
                AND Business_Date = P_TRANDATE_IN
                AND TXN_CODE = P_TXN_CODE_IN
                AND delivery_channel = P_DELIVERY_CHANNEL_IN;
ELSE
			UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST 				--Added for VMS-5739/FSP-991
            SET Store_Id = P_STORE_ID_IN,
                ACCT_BALANCE = l_ACCT_BALANCE,
                LEDGER_BALANCE = l_LEDGER_BALANCE,
                SPIL_PROD_ID = P_SPIL_PROD_ID_IN,
                SPIL_FEE = P_SPIL_FEE_IN,
                SPIL_UPC = P_SPIL_UPC_IN,
                SPIL_MERREF_NUM = P_SPIL_MERREF_NUM_IN,
                SPIL_REQ_TMZM = P_SPIL_REQ_TMZM_IN,
                SPIL_LOC_CNTRY = P_SPIL_LOC_CNTRY_IN,
                SPIL_LOC_CRCY = P_SPIL_LOC_CRCY_IN,
                SPIL_LOC_LANG = P_SPIL_LOC_LANG_IN,
                SPIL_POS_ENTRY = P_SPIL_POS_ENTRY_IN,
                SPIL_POS_COND = P_SPIL_POS_COND_IN
          --error_msg = 'Success'
          WHERE     Instcode = P_INST_CODE_IN
                AND Rrn = P_RRN_IN
                AND CUSTOMER_CARD_NO = l_HASH_PAN
                AND Business_Date = P_TRANDATE_IN
                AND TXN_CODE = P_TXN_CODE_IN
                AND delivery_channel = P_DELIVERY_CHANNEL_IN;

END IF;
				

         IF SQL%ROWCOUNT = 0
         THEN
            P_ERRMSG_OUT :=
               'StoreId not updated in Transactionlog table'
               || P_TERMINALID_IN;
            l_RESPCODE := '21';
            RAISE Exp_Main_Reject_Record;
         END IF;
      EXCEPTION
         WHEN Exp_Main_Reject_Record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            P_ERRMSG_OUT :=
               'Error while Updating StoreId in Transactionlog table'
               || SUBSTR (SQLERRM, 1, 200);
            l_RESPCODE := '21';
            RAISE Exp_Main_Reject_Record;
      END;

      BEGIN
	  
		--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRANDATE_IN), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod) 												--Added for VMS-5739/FSP-991

    THEN
         UPDATE CMS_TRANSACTION_LOG_DTL
            SET CTD_STORE_ADDRESS1 = P_ADDRESS1_IN,
                CTD_STORE_ADDRESS2 = P_ADDRESS2_IN,
                CTD_STORE_CITY = P_CITY_IN,
                CTD_STORE_STATE = P_STATE_IN,
                CTD_STORE_ZIP = P_ZIP_IN
          WHERE     ctd_inst_code = P_INST_CODE_IN
                AND CTD_RRN = P_RRN_IN
                AND CTD_CUSTOMER_CARD_NO = l_HASH_PAN
                AND CTD_BUSINESS_DATE = P_TRANDATE_IN
                AND CTD_TXN_CODE = P_TXN_CODE_IN
                AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN;
				
ELSE
		
		UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST 					--Added for VMS-5739/FSP-991
            SET CTD_STORE_ADDRESS1 = P_ADDRESS1_IN,
                CTD_STORE_ADDRESS2 = P_ADDRESS2_IN,
                CTD_STORE_CITY = P_CITY_IN,
                CTD_STORE_STATE = P_STATE_IN,
                CTD_STORE_ZIP = P_ZIP_IN
          WHERE     ctd_inst_code = P_INST_CODE_IN
                AND CTD_RRN = P_RRN_IN
                AND CTD_CUSTOMER_CARD_NO = l_HASH_PAN
                AND CTD_BUSINESS_DATE = P_TRANDATE_IN
                AND CTD_TXN_CODE = P_TXN_CODE_IN
                AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN;
		
END IF;

         IF SQL%ROWCOUNT = 0
         THEN
            P_ERRMSG_OUT :=
               'Address details not updated in Transactionlog table'
               || P_TERMINALID_IN;
            l_RESPCODE := '21';
            RAISE Exp_Main_Reject_Record;
         END IF;
      EXCEPTION
         WHEN Exp_Main_Reject_Record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            P_ERRMSG_OUT :=
               'Error while updating Address details in Transactionlog table'
               || SUBSTR (SQLERRM, 1, 200);
            l_RESPCODE := '21';
            RAISE Exp_Main_Reject_Record;
      END;

      IF l_prfl_code IS NOT NULL AND l_prfl_flag = 'Y'
      THEN
         BEGIN
            pkg_limits_check.sp_limitcnt_reset (P_INST_CODE_IN,
                                                l_HASH_PAN,
                                                l_TRAN_AMT,
                                                l_comb_hash,
                                                l_RESPCODE,
                                                P_ERRMSG_OUT);

            IF P_ERRMSG_OUT <> 'OK'
            THEN
              -- l_RESPCODE := '21';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_RESPCODE := '21';
               P_ERRMSG_OUT :=
                  'Error from Limit Reset Count Process '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      END IF;

      IF l_txn_redmption_flag = 'Y' AND l_redmption_delay_flag = 'Y'
      THEN
         BEGIN
            vmsredemptiondelay.redemption_delay (l_ACCT_NUMBER,
                                                 P_RRN_IN,
                                                 P_DELIVERY_CHANNEL_IN,
                                                 P_TXN_CODE_IN,
                                                 l_TRAN_AMT,
                                                 l_PROD_CODE,
                                                 l_CARD_TYPE,
                                                 UPPER (P_Merchant_Name_IN),
                                                 P_ZIP_IN,--added for VMS-622 (redemption_delay zip code validation)
                                                 P_ERRMSG_OUT);

            IF P_ERRMSG_OUT <> 'OK'
            THEN
               l_RESPCODE := '21';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                  'Error while calling sp_log_delayed_load: '
                  || SUBSTR (SQLERRM, 1, 200);
               l_RESPCODE := '21';
               RAISE exp_main_reject_record;
         END;
      END IF;

      IF P_SERIAL_NUMBER_IN IS NOT NULL
      THEN
         BEGIN
            INSERT INTO CMS_SPILSERIAL_LOGGING (CSL_INST_CODE,
                                                CSL_DELIVERY_CHANNEL,
                                                CSL_TXN_CODE,
                                                CSL_MSG_TYPE,
                                                CSL_SERIAL_NUMBER,
                                                CSL_AUTH_ID,
                                                CSL_RESPONSE_CODE,
                                                CSL_PAN_CODE,
                                                CSL_RRN,
                                                CSL_TIME_STAMP)
                 VALUES (P_INST_CODE_IN,
                         P_DELIVERY_CHANNEL_IN,
                         P_TXN_CODE_IN,
                         P_MSG_TYPE_IN,
                         P_SERIAL_NUMBER_IN,
                         P_AUTH_ID_OUT,
                         P_RESP_CODE_OUT,
                         l_HASH_PAN,
                         P_RRN_IN,
                         SYSTIMESTAMP);
         EXCEPTION
            WHEN OTHERS
            THEN
               P_RESP_CODE_OUT := '21';
               P_ERRMSG_OUT :=
                  'Error while inserting CMS_SPILSERIAL_LOGGING '
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_main_reject_record;
         END;
      END IF;

      P_ERRMSG_OUT := 'Success';
   EXCEPTION
      --<< MAIN EXCEPTION >>
      WHEN EXP_AUTH_REJECT_RECORD
      THEN
         ROLLBACK;

         P_ERRMSG_OUT := P_ERRMSG_OUT;
         P_RESP_CODE_OUT := l_RESPCODE;
         P_RESP_MSG_TYPE_OUT := P_ERRMSG_OUT;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO l_ACCT_BALANCE, l_LEDGER_BALANCE, l_acct_type
              FROM cms_acct_mast
             WHERE cam_acct_no = l_ACCT_NUMBER
                   AND cam_inst_code = P_INST_CODE_IN;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_ACCT_BALANCE := 0;
               l_LEDGER_BALANCE := 0;
         END;

         P_ACCT_BAL_OUT := l_ACCT_BALANCE;

         BEGIN
            SELECT CMS_ISO_RESPCDE
              INTO P_RESP_CODE_OUT
              FROM cms_response_mast
             WHERE     cms_inst_code = P_INST_CODE_IN
                   AND cms_delivery_channel = P_DELIVERY_CHANNEL_IN
                   AND CMS_RESPONSE_ID = l_RESPCODE
                   AND ROWNUM < 2;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT cms_response_id
                    INTO l_RESPCODE
                    FROM cms_response_mast
                   WHERE     cms_inst_code = P_INST_CODE_IN
                         AND cms_delivery_channel = P_DELIVERY_CHANNEL_IN
                         AND cms_iso_respcde = P_RESP_CODE_OUT
                         AND ROWNUM < 2;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     P_ERRMSG_OUT :=
                        'Problem while selecting data from response master for card status '
                        || l_RESPCODE
                        || SUBSTR (SQLERRM, 1, 300);
                     P_RESP_CODE_OUT := '69';
               END;
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                     'Problem while selecting data from response master '
                  || l_RESPCODE
                  || SUBSTR (SQLERRM, 1, 300);
               P_RESP_CODE_OUT := '69';
               ROLLBACK;
         END;

         IF P_SERIAL_NUMBER_IN IS NOT NULL
         THEN
            BEGIN
               INSERT INTO CMS_SPILSERIAL_LOGGING (CSL_INST_CODE,
                                                   CSL_DELIVERY_CHANNEL,
                                                   CSL_TXN_CODE,
                                                   CSL_MSG_TYPE,
                                                   CSL_SERIAL_NUMBER,
                                                   CSL_AUTH_ID,
                                                   CSL_RESPONSE_CODE,
                                                   CSL_PAN_CODE,
                                                   CSL_RRN,
                                                   CSL_TIME_STAMP)
                    VALUES (P_INST_CODE_IN,
                            P_DELIVERY_CHANNEL_IN,
                            P_TXN_CODE_IN,
                            P_MSG_TYPE_IN,
                            P_SERIAL_NUMBER_IN,
                            P_AUTH_ID_OUT,
                            P_RESP_CODE_OUT,
                            l_HASH_PAN,
                            P_RRN_IN,
                            SYSTIMESTAMP);
            EXCEPTION
               WHEN OTHERS
               THEN
                  P_RESP_CODE_OUT := '21';
                  P_ERRMSG_OUT :=
                     'Error while inserting CMS_SPILSERIAL_LOGGING '
                     || SUBSTR (SQLERRM, 1, 300);
            END;
         END IF;


         BEGIN
            INSERT INTO TRANSACTIONLOG (MSGTYPE,
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
                                        BANK_CODE,
                                        TOTAL_AMOUNT,
                                        CURRENCYCODE,
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
                                        CARDSTATUS,
                                        TRANS_DESC,
                                        Merchant_Name,
                                        Error_Msg,
                                        STORE_ID,
                                        cr_dr_flag,
                                        acct_type,
                                        time_stamp,
                                        SPIL_PROD_ID,
                                        SPIL_FEE,
                                        SPIL_UPC,
                                        SPIL_MERREF_NUM,
                                        SPIL_REQ_TMZM,
                                        SPIL_LOC_CNTRY,
                                        SPIL_LOC_CRCY,
                                        SPIL_LOC_LANG,
                                        SPIL_POS_ENTRY,
                                        SPIL_POS_COND,
                                        MERCHANT_ZIP)--added for VMS-622 (redemption_delay zip code validation)
                 VALUES (
                           P_MSG_TYPE_IN,
                           P_RRN_IN,
                           P_DELIVERY_CHANNEL_IN,
                           P_TERMINALID_IN,
                           SYSDATE,
                           P_TXN_CODE_IN,
                           l_TXN_TYPE,
                           P_TXN_MODE_IN,
                           DECODE (P_RESP_CODE_OUT, '00', 'C', 'F'),
                           P_RESP_CODE_OUT,
                           P_TRANDATE_IN,
                           SUBSTR (P_TRANTIME_IN, 1, 10),
                           l_HASH_PAN,
                           P_INST_CODE_IN,
                           TRIM (
                              TO_CHAR (NVL (l_TRAN_AMT, 0),
                                       '999999999999999990.99')),
                           l_CURRCODE,
                           l_PROD_CODE,
                           l_CARD_TYPE,
                           P_TERMINALID_IN,
                           P_AUTH_ID_OUT,
                           TRIM (
                              TO_CHAR (NVL (l_TRAN_AMT, 0),
                                       '999999999999999990.99')),
                           '0.00',
                           '0.00',
                           P_INST_CODE_IN,
                           l_ENCR_PAN,
                           l_ENCR_PAN,
                           l_PROXUNUMBER,
                           P_RVSL_CODE_IN,
                           l_ACCT_NUMBER,
                           l_ACCT_BALANCE,
                           l_LEDGER_BALANCE,
                           l_RESPCODE,
                           l_CAP_CARD_STAT,
                           l_TRANS_DESC,
                           P_Merchant_Name_IN,
                           P_ERRMSG_OUT,
                           P_STORE_ID_IN,
                           l_dr_cr_flag,
                           l_acct_type,
                           SYSTIMESTAMP,
                           P_SPIL_PROD_ID_IN,
                           P_SPIL_FEE_IN,
                           P_SPIL_UPC_IN,
                           P_SPIL_MERREF_NUM_IN,
                           P_SPIL_REQ_TMZM_IN,
                           P_SPIL_LOC_CNTRY_IN,
                           P_SPIL_LOC_CRCY_IN,
                           P_SPIL_LOC_LANG_IN,
                           P_SPIL_POS_ENTRY_IN,
                           P_SPIL_POS_COND_IN,
                           P_ZIP_IN);--added for VMS-622 (redemption_delay zip code validation)
         EXCEPTION
            WHEN OTHERS
            THEN
               P_RESP_CODE_OUT := '69';
               P_ERRMSG_OUT :=
                  'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
         END;

         BEGIN
            INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_DELIVERY_CHANNEL,
                                                 CTD_TXN_CODE,
                                                 CTD_MSG_TYPE,
                                                 CTD_TXN_MODE,
                                                 CTD_BUSINESS_DATE,
                                                 CTD_BUSINESS_TIME,
                                                 CTD_CUSTOMER_CARD_NO,
                                                 CTD_TXN_AMOUNT,
                                                 CTD_TXN_CURR,
                                                 CTD_ACTUAL_AMOUNT,
                                                 CTD_PROCESS_FLAG,
                                                 CTD_PROCESS_MSG,
                                                 CTD_RRN,
                                                 CTD_INST_CODE,
                                                 CTD_CUSTOMER_CARD_NO_ENCR,
                                                 CTD_CUST_ACCT_NUMBER,
                                                 CTD_TXN_TYPE,
                                                 CTD_STORE_ADDRESS1,
                                                 CTD_STORE_ADDRESS2,
                                                 CTD_STORE_CITY,
                                                 CTD_STORE_STATE,
                                                 CTD_STORE_ZIP)
                 VALUES (P_DELIVERY_CHANNEL_IN,
                         P_TXN_CODE_IN,
                         P_MSG_TYPE_IN,
                         P_TXN_MODE_IN,
                         P_TRANDATE_IN,
                         P_TRANTIME_IN,
                         l_HASH_PAN,
                         P_AMOUNT_IN,
                         l_CURRCODE,
                         P_AMOUNT_IN,
                         'E',
                         P_ERRMSG_OUT,
                         P_RRN_IN,
                         P_INST_CODE_IN,
                         l_ENCR_PAN,
                         l_ACCT_NUMBER,
                         l_TXN_TYPE,
                         P_ADDRESS1_IN,
                         P_ADDRESS2_IN,
                         P_CITY_IN,
                         P_STATE_IN,
                         P_ZIP_IN);

            P_ERRMSG_OUT := P_ERRMSG_OUT;
            RETURN;
         EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                  'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               P_RESP_CODE_OUT := '22';
               ROLLBACK;
               RETURN;
         END;

         P_ERRMSG_OUT := P_ERRMSG_OUT;
      WHEN EXP_MAIN_REJECT_RECORD
      THEN
         ROLLBACK;

         IF l_dr_cr_flag IS NULL
         THEN
            BEGIN
               SELECT ctm_credit_debit_flag,
                      ctm_tran_desc,
                      TO_NUMBER (
                         DECODE (CTM_TRAN_TYPE,  'N', '0',  'F', '1'))
                 INTO l_dr_cr_flag, l_TRANS_DESC, l_TXN_TYPE
                 FROM cms_transaction_mast
                WHERE     ctm_tran_code = P_TXN_CODE_IN
                      AND ctm_delivery_channel = P_DELIVERY_CHANNEL_IN
                      AND ctm_inst_code = P_INST_CODE_IN;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         IF l_PROD_CODE IS NULL
         THEN
            BEGIN
               SELECT cap_prod_code,
                      cap_card_type,
                      cap_card_stat,
                      cap_acct_no
                 INTO l_PROD_CODE,
                      l_CARD_TYPE,
                      l_CAP_CARD_STAT,
                      l_ACCT_NUMBER
                 FROM cms_appl_pan
                WHERE cap_inst_code = P_INST_CODE_IN
                      AND cap_pan_code = l_HASH_PAN;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, cam_type_code
              INTO l_ACCT_BALANCE, l_LEDGER_BALANCE, l_acct_type
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO = l_ACCT_NUMBER
                   AND CAM_INST_CODE = P_INST_CODE_IN;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_ACCT_BALANCE := 0;
               l_LEDGER_BALANCE := 0;
         END;

         P_ACCT_BAL_OUT := l_ACCT_BALANCE;

         BEGIN
            SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0')
              INTO P_AUTH_ID_OUT
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_RESPCODE := '21';
         END;

         BEGIN
            P_ERRMSG_OUT := P_ERRMSG_OUT;
            P_RESP_CODE_OUT := l_RESPCODE;
            P_RESP_MSG_TYPE_OUT := P_ERRMSG_OUT;

            SELECT CMS_ISO_RESPCDE
              INTO P_RESP_CODE_OUT
              FROM CMS_RESPONSE_MAST
             WHERE     CMS_INST_CODE = P_INST_CODE_IN
                   AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
                   AND CMS_RESPONSE_ID = l_RESPCODE;
         EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                     'Problem while selecting data from response master '
                  || l_RESPCODE
                  || SUBSTR (SQLERRM, 1, 300);
               P_RESP_CODE_OUT := '69';
               ROLLBACK;
         END;


         IF P_SERIAL_NUMBER_IN IS NOT NULL
         THEN
            BEGIN
               INSERT INTO CMS_SPILSERIAL_LOGGING (CSL_INST_CODE,
                                                   CSL_DELIVERY_CHANNEL,
                                                   CSL_TXN_CODE,
                                                   CSL_MSG_TYPE,
                                                   CSL_SERIAL_NUMBER,
                                                   CSL_AUTH_ID,
                                                   CSL_RESPONSE_CODE,
                                                   CSL_PAN_CODE,
                                                   CSL_RRN,
                                                   CSL_TIME_STAMP)
                    VALUES (P_INST_CODE_IN,
                            P_DELIVERY_CHANNEL_IN,
                            P_TXN_CODE_IN,
                            P_MSG_TYPE_IN,
                            P_SERIAL_NUMBER_IN,
                            P_AUTH_ID_OUT,
                            P_RESP_CODE_OUT,
                            l_HASH_PAN,
                            P_RRN_IN,
                            SYSTIMESTAMP);
            EXCEPTION
               WHEN OTHERS
               THEN
                  P_RESP_CODE_OUT := '21';
                  P_ERRMSG_OUT :=
                     'Error while inserting CMS_SPILSERIAL_LOGGING '
                     || SUBSTR (SQLERRM, 1, 300);
            END;
         END IF;


         BEGIN
            INSERT INTO TRANSACTIONLOG (MSGTYPE,
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
                                        BANK_CODE,
                                        TOTAL_AMOUNT,
                                        CURRENCYCODE,
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
                                        CARDSTATUS,
                                        TRANS_DESC,
                                        Merchant_Name,
                                        Error_Msg,
                                        STORE_ID,
                                        cr_dr_flag,
                                        acct_type,
                                        time_stamp,
                                        SPIL_PROD_ID,
                                        SPIL_FEE,
                                        SPIL_UPC,
                                        SPIL_MERREF_NUM,
                                        SPIL_REQ_TMZM,
                                        SPIL_LOC_CNTRY,
                                        SPIL_LOC_CRCY,
                                        SPIL_LOC_LANG,
                                        SPIL_POS_ENTRY,
                                        SPIL_POS_COND,
                                        MERCHANT_ZIP)--added for VMS-622 (redemption_delay zip code validation)
                 VALUES (
                           P_MSG_TYPE_IN,
                           P_RRN_IN,
                           P_DELIVERY_CHANNEL_IN,
                           P_TERMINALID_IN,
                           SYSDATE,
                           P_TXN_CODE_IN,
                           l_TXN_TYPE,
                           P_TXN_MODE_IN,
                           DECODE (P_RESP_CODE_OUT, '00', 'C', 'F'),
                           P_RESP_CODE_OUT,
                           P_TRANDATE_IN,
                           SUBSTR (P_TRANTIME_IN, 1, 10),
                           l_HASH_PAN,
                           P_INST_CODE_IN,
                           TRIM (
                              TO_CHAR (NVL (l_TRAN_AMT, 0),
                                       '999999999999999990.99')),
                           l_CURRCODE,
                           l_PROD_CODE,
                           l_CARD_TYPE,
                           P_TERMINALID_IN,
                           P_AUTH_ID_OUT,
                           TRIM (
                              TO_CHAR (NVL (l_TRAN_AMT, 0),
                                       '999999999999999990.99')),
                           '0.00',
                           '0.00',
                           P_INST_CODE_IN,
                           l_ENCR_PAN,
                           l_ENCR_PAN,
                           l_PROXUNUMBER,
                           P_RVSL_CODE_IN,
                           l_ACCT_NUMBER,
                           l_ACCT_BALANCE,
                           l_LEDGER_BALANCE,
                           l_RESPCODE,
                           l_CAP_CARD_STAT,
                           l_TRANS_DESC,
                           P_Merchant_Name_IN,
                           P_ERRMSG_OUT,
                           P_STORE_ID_IN,
                           l_dr_cr_flag,
                           l_acct_type,
                           SYSTIMESTAMP,
                           P_SPIL_PROD_ID_IN,
                           P_SPIL_FEE_IN,
                           P_SPIL_UPC_IN,
                           P_SPIL_MERREF_NUM_IN,
                           P_SPIL_REQ_TMZM_IN,
                           P_SPIL_LOC_CNTRY_IN,
                           P_SPIL_LOC_CRCY_IN,
                           P_SPIL_LOC_LANG_IN,
                           P_SPIL_POS_ENTRY_IN,
                           P_SPIL_POS_COND_IN,
                           P_ZIP_IN);--added for VMS-622 (redemption_delay zip code validation)
         EXCEPTION
            WHEN OTHERS
            THEN
               P_RESP_CODE_OUT := '69';
               P_ERRMSG_OUT :=
                  'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
         END;

         BEGIN
            INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_DELIVERY_CHANNEL,
                                                 CTD_TXN_CODE,
                                                 CTD_MSG_TYPE,
                                                 CTD_TXN_MODE,
                                                 CTD_BUSINESS_DATE,
                                                 CTD_BUSINESS_TIME,
                                                 CTD_CUSTOMER_CARD_NO,
                                                 CTD_TXN_AMOUNT,
                                                 CTD_TXN_CURR,
                                                 CTD_ACTUAL_AMOUNT,
                                                 CTD_PROCESS_FLAG,
                                                 CTD_PROCESS_MSG,
                                                 CTD_RRN,
                                                 CTD_INST_CODE,
                                                 CTD_CUSTOMER_CARD_NO_ENCR,
                                                 CTD_CUST_ACCT_NUMBER,
                                                 CTD_TXN_TYPE,
                                                 CTD_STORE_ADDRESS1,
                                                 CTD_STORE_ADDRESS2,
                                                 CTD_STORE_CITY,
                                                 CTD_STORE_STATE,
                                                 CTD_STORE_ZIP)
                 VALUES (P_DELIVERY_CHANNEL_IN,
                         P_TXN_CODE_IN,
                         P_MSG_TYPE_IN,
                         P_TXN_MODE_IN,
                         P_TRANDATE_IN,
                         P_TRANTIME_IN,
                         l_HASH_PAN,
                         P_AMOUNT_IN,
                         l_CURRCODE,
                         P_AMOUNT_IN,
                         'E',
                         P_ERRMSG_OUT,
                         P_RRN_IN,
                         P_INST_CODE_IN,
                         l_ENCR_PAN,
                         l_ACCT_NUMBER,
                         l_TXN_TYPE,
                         P_ADDRESS1_IN,
                         P_ADDRESS2_IN,
                         P_CITY_IN,
                         P_STATE_IN,
                         P_ZIP_IN);

            P_ERRMSG_OUT := P_ERRMSG_OUT;
            RETURN;
         EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                  'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               P_RESP_CODE_OUT := '22';
               ROLLBACK;
               RETURN;
         END;

         P_ERRMSG_OUT := P_ERRMSG_OUT;
         P_RESP_MSG_TYPE_OUT := P_ERRMSG_OUT;
      WHEN EXP_DUPLICATE_REQUEST
      THEN
         ROLLBACK;

         IF l_dr_cr_flag IS NULL
         THEN
            BEGIN
               SELECT ctm_credit_debit_flag,
                      ctm_tran_desc,
                      TO_NUMBER (
                         DECODE (CTM_TRAN_TYPE,  'N', '0',  'F', '1'))
                 INTO l_dr_cr_flag, l_TRANS_DESC, l_TXN_TYPE
                 FROM cms_transaction_mast
                WHERE     ctm_tran_code = P_TXN_CODE_IN
                      AND ctm_delivery_channel = P_DELIVERY_CHANNEL_IN
                      AND ctm_inst_code = P_INST_CODE_IN;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         IF l_PROD_CODE IS NULL
         THEN
            BEGIN
               SELECT cap_prod_code,
                      cap_card_type,
                      cap_card_stat,
                      cap_acct_no
                 INTO l_PROD_CODE,
                      l_CARD_TYPE,
                      l_CAP_CARD_STAT,
                      l_ACCT_NUMBER
                 FROM cms_appl_pan
                WHERE cap_inst_code = P_INST_CODE_IN
                      AND cap_pan_code = l_HASH_PAN;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, cam_type_code
              INTO l_ACCT_BALANCE, l_LEDGER_BALANCE, l_acct_type
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO = l_ACCT_NUMBER
                   AND CAM_INST_CODE = P_INST_CODE_IN;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_ACCT_BALANCE := 0;
               l_LEDGER_BALANCE := 0;
         END;

         P_ACCT_BAL_OUT := l_ACCT_BALANCE;

         IF P_AUTH_ID_OUT IS NULL
         THEN
            BEGIN
               SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0')
                 INTO P_AUTH_ID_OUT
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         BEGIN
            P_ERRMSG_OUT := P_ERRMSG_OUT;
            P_RESP_CODE_OUT := l_RESPCODE;
            P_RESP_MSG_TYPE_OUT := P_ERRMSG_OUT;

            SELECT CMS_ISO_RESPCDE
              INTO P_RESP_CODE_OUT
              FROM CMS_RESPONSE_MAST
             WHERE     CMS_INST_CODE = P_INST_CODE_IN
                   AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
                   AND CMS_RESPONSE_ID = l_RESPCODE;
         EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                     'Problem while selecting data from response master '
                  || l_RESPCODE
                  || SUBSTR (SQLERRM, 1, 300);
               P_RESP_CODE_OUT := '69';
               ROLLBACK;
         END;


         IF P_SERIAL_NUMBER_IN IS NOT NULL
         THEN
            BEGIN
               INSERT INTO CMS_SPILSERIAL_LOGGING (CSL_INST_CODE,
                                                   CSL_DELIVERY_CHANNEL,
                                                   CSL_TXN_CODE,
                                                   CSL_MSG_TYPE,
                                                   CSL_SERIAL_NUMBER,
                                                   CSL_AUTH_ID,
                                                   CSL_RESPONSE_CODE,
                                                   CSL_PAN_CODE,
                                                   CSL_RRN,
                                                   CSL_TIME_STAMP)
                    VALUES (P_INST_CODE_IN,
                            P_DELIVERY_CHANNEL_IN,
                            P_TXN_CODE_IN,
                            P_MSG_TYPE_IN,
                            P_SERIAL_NUMBER_IN,
                            P_AUTH_ID_OUT,
                            P_RESP_CODE_OUT,
                            l_HASH_PAN,
                            P_RRN_IN,
                            SYSTIMESTAMP);
            EXCEPTION
               WHEN OTHERS
               THEN
                  P_RESP_CODE_OUT := '21';
                  P_ERRMSG_OUT :=
                     'Error while inserting CMS_SPILSERIAL_LOGGING '
                     || SUBSTR (SQLERRM, 1, 300);
            END;
         END IF;


         BEGIN
            INSERT INTO TRANSACTIONLOG (MSGTYPE,
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
                                        BANK_CODE,
                                        TOTAL_AMOUNT,
                                        CURRENCYCODE,
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
                                        CARDSTATUS,
                                        TRANS_DESC,
                                        Merchant_Name,
                                        Error_Msg,
                                        STORE_ID,
                                        cr_dr_flag,
                                        acct_type,
                                        time_stamp,
                                        SPIL_PROD_ID,
                                        SPIL_FEE,
                                        SPIL_UPC,
                                        SPIL_MERREF_NUM,
                                        SPIL_REQ_TMZM,
                                        SPIL_LOC_CNTRY,
                                        SPIL_LOC_CRCY,
                                        SPIL_LOC_LANG,
                                        SPIL_POS_ENTRY,
                                        SPIL_POS_COND,
                                        MERCHANT_ZIP)--added for VMS-622 (redemption_delay zip code validation)
                 VALUES (
                           P_MSG_TYPE_IN,
                           P_RRN_IN,
                           P_DELIVERY_CHANNEL_IN,
                           P_TERMINALID_IN,
                           SYSDATE,
                           P_TXN_CODE_IN,
                           l_TXN_TYPE,
                           P_TXN_MODE_IN,
                           DECODE (P_RESP_CODE_OUT, '00', 'C', 'F'),
                           P_RESP_CODE_OUT,
                           P_TRANDATE_IN,
                           SUBSTR (P_TRANTIME_IN, 1, 10),
                           l_HASH_PAN,
                           P_INST_CODE_IN,
                           TRIM (
                              TO_CHAR (NVL (l_TRAN_AMT, 0),
                                       '999999999999999990.99')),
                           l_CURRCODE,
                           l_PROD_CODE,
                           l_CARD_TYPE,
                           P_TERMINALID_IN,
                           P_AUTH_ID_OUT,
                           TRIM (
                              TO_CHAR (NVL (l_TRAN_AMT, 0),
                                       '999999999999999990.99')),
                           '0.00',
                           '0.00',
                           P_INST_CODE_IN,
                           l_ENCR_PAN,
                           l_ENCR_PAN,
                           l_PROXUNUMBER,
                           P_RVSL_CODE_IN,
                           l_ACCT_NUMBER,
                           l_ACCT_BALANCE,
                           l_LEDGER_BALANCE,
                           l_RESPCODE,
                           l_CAP_CARD_STAT,
                           l_TRANS_DESC,
                           P_Merchant_Name_IN,
                           P_ERRMSG_OUT,
                           P_STORE_ID_IN,
                           l_dr_cr_flag,
                           l_acct_type,
                           SYSTIMESTAMP,
                           P_SPIL_PROD_ID_IN,
                           P_SPIL_FEE_IN,
                           P_SPIL_UPC_IN,
                           P_SPIL_MERREF_NUM_IN,
                           P_SPIL_REQ_TMZM_IN,
                           P_SPIL_LOC_CNTRY_IN,
                           P_SPIL_LOC_CRCY_IN,
                           P_SPIL_LOC_LANG_IN,
                           P_SPIL_POS_ENTRY_IN,
                           P_SPIL_POS_COND_IN,
                           P_ZIP_IN);--added for VMS-622 (redemption_delay zip code validation)
         EXCEPTION
            WHEN OTHERS
            THEN
               P_RESP_CODE_OUT := '69';
               P_ERRMSG_OUT :=
                  'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
         END;

         BEGIN
            INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_DELIVERY_CHANNEL,
                                                 CTD_TXN_CODE,
                                                 CTD_MSG_TYPE,
                                                 CTD_TXN_MODE,
                                                 CTD_BUSINESS_DATE,
                                                 CTD_BUSINESS_TIME,
                                                 CTD_CUSTOMER_CARD_NO,
                                                 CTD_TXN_AMOUNT,
                                                 CTD_TXN_CURR,
                                                 CTD_ACTUAL_AMOUNT,
                                                 CTD_PROCESS_FLAG,
                                                 CTD_PROCESS_MSG,
                                                 CTD_RRN,
                                                 CTD_INST_CODE,
                                                 CTD_CUSTOMER_CARD_NO_ENCR,
                                                 CTD_CUST_ACCT_NUMBER,
                                                 CTD_TXN_TYPE,
                                                 CTD_STORE_ADDRESS1,
                                                 CTD_STORE_ADDRESS2,
                                                 CTD_STORE_CITY,
                                                 CTD_STORE_STATE,
                                                 CTD_STORE_ZIP)
                 VALUES (P_DELIVERY_CHANNEL_IN,
                         P_TXN_CODE_IN,
                         P_MSG_TYPE_IN,
                         P_TXN_MODE_IN,
                         P_TRANDATE_IN,
                         P_TRANTIME_IN,
                         l_HASH_PAN,
                         P_AMOUNT_IN,
                         l_CURRCODE,
                         P_AMOUNT_IN,
                         'E',
                         P_ERRMSG_OUT,
                         P_RRN_IN,
                         P_INST_CODE_IN,
                         l_ENCR_PAN,
                         l_ACCT_NUMBER,
                         l_TXN_TYPE,
                         P_ADDRESS1_IN,
                         P_ADDRESS2_IN,
                         P_CITY_IN,
                         P_STATE_IN,
                         P_ZIP_IN);

            P_ERRMSG_OUT := P_ERRMSG_OUT;
            RETURN;
         EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                  'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               P_RESP_CODE_OUT := '22';
               ROLLBACK;
               RETURN;
         END;

         BEGIN
            SELECT RESPONSE_CODE
              INTO P_RESP_CODE_OUT
              FROM VMSCMS.TRANSACTIONLOG_VW A,							--Added for VMS-5739/FSP-991
                   (SELECT MIN (ADD_INS_DATE) MINDATE
                      FROM VMSCMS.TRANSACTIONLOG_VW				--Added for VMS-5739/FSP-991			
                     WHERE RRN = P_RRN_IN AND ACCT_BALANCE IS NOT NULL) B
             WHERE     A.ADD_INS_DATE = MINDATE
                   AND RRN = P_RRN_IN
                   AND ACCT_BALANCE IS NOT NULL;
				   
         EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                  'Problem in selecting the response detail of Original transaction'
                  || SUBSTR (SQLERRM, 1, 300);
               P_RESP_CODE_OUT := '89';
               ROLLBACK;
               RETURN;
         END;
      WHEN OTHERS
      THEN
         P_ERRMSG_OUT := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
   END Store_credit;

   PROCEDURE Store_credit_reversal (
      p_inst_code_in            IN     NUMBER,
      p_msg_typ_in              IN     VARCHAR2,
      p_rvsl_code_in            IN     VARCHAR2,
      p_rrn_in                  IN     VARCHAR2,
      p_delivery_channel_in     IN     VARCHAR2,
      p_terminal_id_in          IN     VARCHAR2,
      p_merc_id_in              IN     VARCHAR2,
      p_txn_code_in             IN     VARCHAR2,
      p_txn_type_in             IN     VARCHAR2,
      p_txn_mode_in             IN     VARCHAR2,
      p_business_date_in        IN     VARCHAR2,
      p_business_time_in        IN     VARCHAR2,
      p_card_no_in              IN     VARCHAR2,
      p_actual_amt_in           IN     NUMBER,
      p_stan_in                 IN     VARCHAR2,
      p_curr_code_in            IN     VARCHAR2,
      p_merchant_name_in        IN     VARCHAR2,
      p_store_id_in             IN     VARCHAR2,
      P_serial_number_in        IN     VARCHAR2,
      P_ADDRESS1_IN             IN     VARCHAR2,
      P_ADDRESS2_IN             IN     VARCHAR2,
      P_CITY_IN                 IN     VARCHAR2,
      P_STATE_IN                IN     VARCHAR2,
      P_ZIP_IN                  IN     VARCHAR2,
      P_SPIL_PROD_ID_IN         IN     VARCHAR2,
      P_SPIL_FEE_IN             IN     NUMBER,
      P_SPIL_UPC_IN             IN     VARCHAR2,
      P_SPIL_MERREF_NUM_IN      IN     VARCHAR2,
      P_SPIL_REQ_TMZM_IN        IN     VARCHAR2,
      P_SPIL_LOC_CNTRY_IN       IN     VARCHAR2,
      P_SPIL_LOC_CRCY_IN        IN     VARCHAR2,
      P_SPIL_LOC_LANG_IN        IN     VARCHAR2,
      P_SPIL_POS_ENTRY_IN       IN     VARCHAR2,
      P_SPIL_POS_COND_IN        IN     VARCHAR2,
      p_resp_code_out              OUT VARCHAR2,
      p_resp_msg_out               OUT VARCHAR2,
      p_auth_id_out                OUT VARCHAR2,
      p_autherized_amount_out      OUT VARCHAR2,
      p_balance_out                OUT VARCHAR2,
      p_curr_out                   OUT VARCHAR2)
   AS
      l_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no                    cms_appl_pan.cap_acct_no%TYPE;
      l_prod_code                  cms_appl_pan.cap_prod_code%TYPE;
      l_card_type                  cms_appl_pan.cap_card_type%TYPE;
      l_prfl_code                  cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat                  cms_appl_pan.cap_card_stat%TYPE;
      l_proxy_number               cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_balance               cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_balance             cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type                  cms_acct_mast.cam_type_code%TYPE;
      l_orgnl_delivery_channel     transactionlog.delivery_channel%TYPE;
      l_orgnl_resp_code            transactionlog.response_code%TYPE;
      l_orgnl_txn_code             transactionlog.txn_code%TYPE;
      l_orgnl_txn_type             transactionlog.txn_type%TYPE;
      l_orgnl_txn_mode             transactionlog.txn_mode%TYPE;
      l_orgnl_terminal_id          transactionlog.terminal_id%TYPE;
      l_orgnl_business_date        transactionlog.business_date%TYPE;
      l_orgnl_business_time        transactionlog.business_time%TYPE;
      l_orgnl_customer_card_no     transactionlog.customer_card_no%TYPE;
      l_orgnl_total_amount         transactionlog.amount%TYPE;
      l_orgnl_txn_fee_plan         transactionlog.fee_plan%TYPE;
      l_orgnl_txn_feecode          cms_fee_mast.cfm_fee_code%TYPE;
      l_orgnl_txn_feeattachtype    transactionlog.feeattachtype%TYPE;
      l_orgnl_txn_totalfee_amt     transactionlog.tranfee_amt%TYPE;
      l_orgnl_txn_servicetax_amt   transactionlog.servicetax_amt%TYPE;
      l_orgnl_txn_cess_amt         transactionlog.cess_amt%TYPE;
      l_orgnl_transaction_type     transactionlog.cr_dr_flag%TYPE;
      l_orgnl_termid               transactionlog.terminal_id%TYPE;
      l_orgnl_mcccode              transactionlog.mccode%TYPE;
      l_actual_dispatched_amt      transactionlog.amount%TYPE;
      l_actual_feecode             transactionlog.feecode%TYPE;
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
      l_tran_reverse_flag          transactionlog.tran_reverse_flag%TYPE;
      l_curr_code                  transactionlog.currencycode%TYPE;
      l_auth_id                    transactionlog.auth_id%TYPE;
      l_dr_cr_flag                 transactionlog.cr_dr_flag%TYPE;
      l_orgnl_txn_amnt             transactionlog.amount%TYPE;
      l_add_ins_date               transactionlog.add_ins_date%TYPE;
      l_prfl_flag                  cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_tran_type                  cms_transaction_mast.ctm_tran_type%TYPE;
      l_internation_ind_response   transactionlog.internation_ind_response%TYPE;
      l_pos_verification           transactionlog.pos_verification%TYPE;
      l_orgnl_auth_id              transactionlog.auth_id%TYPE;
      l_txn_narration              cms_statements_log.csl_trans_narrration%TYPE;
      l_fee_narration              cms_statements_log.csl_trans_narrration%TYPE;
      l_txn_merchname              cms_statements_log.csl_merchant_name%TYPE;
      l_fee_merchname              cms_statements_log.csl_merchant_name%TYPE;
      l_txn_merchcity              cms_statements_log.csl_merchant_city%TYPE;
      l_fee_merchcity              cms_statements_log.csl_merchant_city%TYPE;
      l_txn_merchstate             cms_statements_log.csl_merchant_state%TYPE;
      l_fee_merchstate             cms_statements_log.csl_merchant_state%TYPE;
      l_hashkey_id                 cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_base_curr                  cms_inst_param.cip_param_value%TYPE;
      l_tran_desc                  cms_transaction_mast.ctm_tran_desc%TYPE;
      l_fee_plan                   cms_fee_plan.cfp_plan_id%TYPE;
      l_feecap_flag                cms_fee_mast.cfm_feecap_flag%TYPE;
      l_orgnl_fee_amt              cms_fee_mast.cfm_fee_amt%TYPE;
      l_fee_code                   cms_fee_mast.cfm_fee_code%TYPE;
      l_max_card_bal               cms_bin_param.cbp_param_value%TYPE;
      l_feeattach_type             VARCHAR2 (2);
      l_reversal_amt               NUMBER (9, 2);
      l_resp_cde                   VARCHAR2 (5);
      l_rvsl_trandate              DATE;
      l_tran_amt                   NUMBER;
      l_card_curr                  VARCHAR2 (5);
      l_currcode                   VARCHAR2 (3);
      l_timestamp                  TIMESTAMP (3);
      l_fee_amt                    NUMBER (9, 2);
      l_txn_type                   NUMBER (1);
      l_dupl_indc                  NUMBER (5) := 0;
      l_succ_orgnl_cnt             NUMBER (5) := 0;
      l_errmsg                     VARCHAR2 (300);
      exp_rvsl_reject_record       EXCEPTION;
	  
	  v_Retperiod  date;  --Added for VMS-5739/FSP-991
	  v_Retdate  date; --Added for VMS-5739/FSP-991


   BEGIN
      BEGIN
         l_tran_amt := p_actual_amt_in;

         BEGIN
            l_hash_pan := gethash (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_errmsg :=
                  'Error while converting hash pan-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            l_encr_pan := fn_emaps_main (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_errmsg :=
                  'Error while converting encr pan-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            SELECT ctm_credit_debit_flag,
                   ctm_tran_desc,                           -- || ' REVERSAL',
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_type,
                   ctm_prfl_flag
              INTO l_dr_cr_flag,
                   l_tran_desc,
                   l_txn_type,
                   l_tran_type,
                   l_prfl_flag
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Problem while selecting transactions dtls from master- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_acct_no,
                   cap_prfl_code,
                   cap_card_stat,
                   cap_proxy_number
              INTO l_prod_code,
                   l_card_type,
                   l_acct_no,
                   l_prfl_code,
                   l_card_stat,
                   l_proxy_number
              FROM cms_appl_pan
             WHERE     cap_inst_code = p_inst_code_in
                   AND cap_mbr_numb = '000'
                   AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while retriving card detail-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;


         BEGIN
            l_rvsl_trandate :=
               TO_DATE (SUBSTR (TRIM (p_business_date_in), 1, 8), 'yyyymmdd');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '45';
               l_errmsg :=
                  'Problem while converting transaction date-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            l_rvsl_trandate :=
               TO_DATE (
                     SUBSTR (TRIM (p_business_date_in), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_business_time_in), 1, 8),
                  'yyyymmdd hh24:mi:ss');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '32';
               l_errmsg :=
                  'Problem while converting transaction Time-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            p_auth_id_out := LPAD (seq_auth_id.NEXTVAL, 6, '0');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                  'Error while generating authid-'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            SELECT gcm_curr_code
              INTO l_currcode
              FROM gen_curr_mast
             WHERE gcm_inst_code=p_inst_code_in AND gcm_curr_name = p_curr_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                     'Error while selecting the currency code for '
                  || p_curr_code_in
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF (p_msg_typ_in NOT IN ('0400', '0410', '0420', '0430', '1420'))
            OR (p_rvsl_code_in = '00')
         THEN
            l_resp_cde := '127';
            l_errmsg := 'Invalid Request';
            RAISE exp_rvsl_reject_record;
         END IF;

         BEGIN
            FOR l_idx
               IN (  SELECT delivery_channel,
                            txn_code,
                            txn_mode,
                            terminal_id,
                            business_date,
                            business_time,
                            customer_card_no,
                            amount,
                            feecode,
                            fee_plan,
                            feeattachtype,
                            tranfee_amt,
                            servicetax_amt,
                            cess_amt,
                            cr_dr_flag,
                            mccode,
                            tranfee_cr_acctno,
                            tranfee_dr_acctno,
                            tran_st_calc_flag,
                            tran_cess_calc_flag,
                            tran_st_cr_acctno,
                            tran_st_dr_acctno,
                            tran_cess_cr_acctno,
                            tran_cess_dr_acctno,
                            currencycode,
                            NVL (tran_reverse_flag, 'N') tran_reverse_flag,
                            pos_verification,
                            internation_ind_response,
                            add_ins_date,
                            DECODE (txn_type,  '1', 'F',  '0', 'N') txntype,
                            auth_id
                       FROM VMSCMS.TRANSACTIONLOG_VW 						--Added for VMS-5739/FSP-991
                      WHERE     rrn = p_rrn_in
                            AND customer_card_no = l_hash_pan
                            AND instcode = p_inst_code_in
                            AND response_code = '00'
                            AND msgtype = '1200'
                            AND txn_code = p_txn_code_in
                            AND delivery_channel = p_delivery_channel_in
                   ORDER BY time_stamp)
            LOOP
               l_succ_orgnl_cnt := l_succ_orgnl_cnt + 1;

               IF l_idx.tran_reverse_flag = 'N'
               THEN
                  l_orgnl_delivery_channel := l_idx.delivery_channel;
                  l_orgnl_txn_code := l_idx.txn_code;
                  l_orgnl_txn_mode := l_idx.txn_mode;
                  l_orgnl_terminal_id := l_idx.terminal_id;
                  l_orgnl_business_date := l_idx.business_date;
                  l_orgnl_business_time := l_idx.business_time;
                  l_orgnl_customer_card_no := l_idx.customer_card_no;
                  l_orgnl_total_amount := l_idx.amount;
                  l_orgnl_txn_feecode := l_idx.feecode;
                  l_orgnl_txn_fee_plan := l_idx.fee_plan;
                  l_orgnl_txn_feeattachtype := l_idx.feeattachtype;
                  l_orgnl_txn_totalfee_amt := l_idx.tranfee_amt;
                  l_orgnl_txn_servicetax_amt := l_idx.servicetax_amt;
                  l_orgnl_txn_cess_amt := l_idx.cess_amt;
                  l_orgnl_transaction_type := l_idx.cr_dr_flag;
                  l_orgnl_mcccode := l_idx.mccode;
                  l_actual_feecode := l_idx.feecode;
                  l_orgnl_tranfee_amt := l_idx.tranfee_amt;
                  l_orgnl_servicetax_amt := l_idx.servicetax_amt;
                  l_orgnl_cess_amt := l_idx.cess_amt;
                  l_orgnl_tranfee_cr_acctno := l_idx.tranfee_cr_acctno;
                  l_orgnl_tranfee_dr_acctno := l_idx.tranfee_dr_acctno;
                  l_orgnl_st_calc_flag := l_idx.tran_st_calc_flag;
                  l_orgnl_cess_calc_flag := l_idx.tran_cess_calc_flag;
                  l_orgnl_st_cr_acctno := l_idx.tran_st_cr_acctno;
                  l_orgnl_st_dr_acctno := l_idx.tran_st_dr_acctno;
                  l_orgnl_cess_cr_acctno := l_idx.tran_cess_cr_acctno;
                  l_orgnl_cess_dr_acctno := l_idx.tran_cess_dr_acctno;
                  l_curr_code := l_idx.currencycode;
                  l_orgnl_txn_amnt := l_idx.amount;
                  l_pos_verification := l_idx.pos_verification;
                  l_internation_ind_response := l_idx.internation_ind_response;
                  l_add_ins_date := l_idx.add_ins_date;
                  l_tran_type := l_idx.txntype;
                  l_orgnl_auth_id := l_idx.auth_id;
               ELSE
                  l_dupl_indc := 1;
               END IF;
            END LOOP;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '69';
               l_errmsg :=
                  'Problem while checking for original transaction-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF l_succ_orgnl_cnt = 0
         THEN
            l_resp_cde := '53';
            l_errmsg := 'Original transaction not found';
            RAISE exp_rvsl_reject_record;
         ELSE
            IF l_dupl_indc = 1
            THEN
               l_resp_cde := '52';
               l_errmsg :=
                  'The reversal already done for the original transaction';
               RAISE exp_rvsl_reject_record;
            END IF;
         END IF;



         IF (p_actual_amt_in >= 0)
         THEN
            BEGIN
               sp_convert_curr (p_inst_code_in,
                                l_currcode,
                                p_card_no_in,
                                p_actual_amt_in,
                                l_rvsl_trandate,
                                l_tran_amt,
                                l_card_curr,
                                l_errmsg,
                                l_prod_code,
                                l_card_type);

               IF l_errmsg <> 'OK'
               THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_errmsg :=
                     'Error from sp_convert_curr-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         ELSE
            l_resp_cde := '43';
            l_errmsg := 'INVALID AMOUNT';
            RAISE exp_rvsl_reject_record;
         END IF;

         IF p_actual_amt_in > l_orgnl_txn_amnt
         THEN
            l_resp_cde := '59';
            l_errmsg :=
               'Reversal amount exceeds the original transaction amount';
            RAISE exp_rvsl_reject_record;
         END IF;

         l_actual_dispatched_amt := NVL (l_tran_amt, 0);
         l_reversal_amt := l_orgnl_total_amount - l_actual_dispatched_amt;

         IF l_dr_cr_flag = 'NA'
         THEN
            l_resp_cde := '21';
            l_errmsg := 'Not a valid original transaction for reversal';
            RAISE exp_rvsl_reject_record;
         END IF;



         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO l_acct_balance, l_ledger_balance, l_acct_type
              FROM cms_acct_mast
             WHERE cam_acct_no = l_acct_no AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_errmsg :=
                  'Error while selecting account balance from acct master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF l_ACCT_BALANCE < l_ORGNL_TXN_AMNT
         THEN
            l_resp_cde := '15';
            l_errmsg := 'Insufficient Funds';
            RAISE exp_rvsl_reject_record;
         END IF;

         BEGIN
		    
--Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod) 										--Added for VMS-5739/FSP-991

    THEN
            SELECT csl_trans_narrration,
                   csl_merchant_name,
                   csl_merchant_city,
                   csl_merchant_state
              INTO l_txn_narration,
                   l_txn_merchname,
                   l_txn_merchcity,
                   l_txn_merchstate
              FROM cms_statements_log
             WHERE     csl_business_date = l_orgnl_business_date
                   AND csl_business_time = l_orgnl_business_time
                   AND csl_rrn = p_rrn_in
                   AND csl_delivery_channel = l_orgnl_delivery_channel
                   AND csl_txn_code = l_orgnl_txn_code
                   AND csl_pan_no = l_orgnl_customer_card_no
                   AND csl_auth_id = l_orgnl_auth_id
                   AND csl_inst_code = p_inst_code_in
                   AND txn_fee_flag = 'N';
				   
ELSE
			SELECT csl_trans_narrration,
                   csl_merchant_name,
                   csl_merchant_city,
                   csl_merchant_state
              INTO l_txn_narration,
                   l_txn_merchname,
                   l_txn_merchcity,
                   l_txn_merchstate
              FROM VMSCMS_HISTORY.cms_statements_log_HIST 				--Added for VMS-5739/FSP-991
             WHERE     csl_business_date = l_orgnl_business_date
                   AND csl_business_time = l_orgnl_business_time
                   AND csl_rrn = p_rrn_in
                   AND csl_delivery_channel = l_orgnl_delivery_channel
                   AND csl_txn_code = l_orgnl_txn_code
                   AND csl_pan_no = l_orgnl_customer_card_no
                   AND csl_auth_id = l_orgnl_auth_id
                   AND csl_inst_code = p_inst_code_in
                   AND txn_fee_flag = 'N';

END IF;
				   
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_txn_narration := NULL;
            WHEN OTHERS
            THEN
               l_txn_narration := NULL;
         END;


         --         IF l_orgnl_txn_totalfee_amt > 0
         --         THEN
         --            BEGIN
         --               SELECT csl_trans_narrration,
         --                      csl_merchant_name,
         --                      csl_merchant_city,
         --                      csl_merchant_state
         --                 INTO l_fee_narration,
         --                      l_fee_merchname,
         --                      l_fee_merchcity,
         --                      l_fee_merchstate
         --                 FROM cms_statements_log
         --                WHERE     csl_business_date = l_orgnl_business_date
         --                      AND csl_business_time = l_orgnl_business_time
         --                      AND csl_rrn = p_rrn_in
         --                      AND csl_delivery_channel = l_orgnl_delivery_channel
         --                      AND csl_txn_code = l_orgnl_txn_code
         --                      AND csl_pan_no = l_orgnl_customer_card_no
         --                      AND csl_auth_id = l_orgnl_auth_id
         --                      AND csl_inst_code = p_inst_code_in
         --                      AND txn_fee_flag = 'Y';
         --            EXCEPTION
         --               WHEN NO_DATA_FOUND
         --               THEN
         --                  l_fee_narration := NULL;
         --               WHEN OTHERS
         --               THEN
         --                  l_fee_narration := NULL;
         --            END;
         --         END IF;

         l_timestamp := SYSTIMESTAMP;

         BEGIN
            sp_reverse_card_amount (p_inst_code_in,
                                    NULL,
                                    p_rrn_in,
                                    p_delivery_channel_in,
                                    l_orgnl_terminal_id,
                                    p_merc_id_in,
                                    p_txn_code_in,
                                    l_rvsl_trandate,
                                    p_txn_mode_in,
                                    p_card_no_in,
                                    l_reversal_amt,
                                    p_rrn_in,
                                    l_acct_no,
                                    p_business_date_in,
                                    p_business_time_in,
                                    p_auth_id_out,
                                    l_txn_narration,
                                    l_orgnl_business_date,
                                    l_orgnl_business_time,
                                    l_txn_merchname,
                                    l_txn_merchcity,
                                    l_txn_merchstate,
                                    l_resp_cde,
                                    l_errmsg);

            IF l_resp_cde <> '00' OR l_errmsg <> 'OK'
            THEN
               l_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while reversing the amount-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF l_orgnl_txn_totalfee_amt > 0 OR l_orgnl_txn_feecode IS NOT NULL
         THEN
            BEGIN
               SELECT cfm_feecap_flag, cfm_fee_amt
                 INTO l_feecap_flag, l_orgnl_fee_amt
                 FROM cms_fee_mast
                WHERE cfm_inst_code = p_inst_code_in
                      AND cfm_fee_code = l_orgnl_txn_feecode;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_feecap_flag := '';
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error in feecap flag fetch-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;

            FOR i
               IN (SELECT csl_trans_narrration,
                          csl_merchant_name,
                          csl_merchant_city,
                          csl_merchant_state,
                          csl_trans_amount
                     FROM  VMSCMS.CMS_STATEMENTS_LOG_VW 						--Added for VMS-5739/FSP-991
                    WHERE     csl_business_date = l_orgnl_business_date
                          AND csl_business_time = l_orgnl_business_time
                          AND csl_rrn = p_rrn_in
                          AND csl_delivery_channel = l_orgnl_delivery_channel
                          AND csl_txn_code = l_orgnl_txn_code
                          AND csl_pan_no = l_orgnl_customer_card_no
                          AND csl_auth_id = l_orgnl_auth_id
                          AND csl_inst_code = p_inst_code_in
                          AND txn_fee_flag = 'Y')
            LOOP
               l_fee_narration := i.csl_trans_narrration;
               l_fee_merchname := i.csl_merchant_name;
               l_fee_merchcity := i.csl_merchant_city;
               l_fee_merchstate := i.csl_merchant_state;
               l_orgnl_tranfee_amt := i.csl_trans_amount;

               IF l_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_revcapcheck (p_inst_code_in,
                                               l_acct_no,
                                               l_orgnl_business_date,
                                               l_orgnl_tranfee_amt,
                                               l_orgnl_fee_amt,
                                               l_orgnl_txn_fee_plan,
                                               l_orgnl_txn_feecode,
                                               l_errmsg);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_resp_cde := '21';
                        l_errmsg :=
                           'Error while reversing the fee Cap amount-'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_rvsl_reject_record;
                  END;
               END IF;

               BEGIN
                  sp_reverse_fee_amount (p_inst_code_in,
                                         p_rrn_in,
                                         p_delivery_channel_in,
                                         l_orgnl_terminal_id,
                                         p_merc_id_in,
                                         p_txn_code_in,
                                         l_rvsl_trandate,
                                         p_txn_mode_in,
                                         l_orgnl_txn_totalfee_amt,
                                         p_card_no_in,
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
                                         p_rrn_in,
                                         l_acct_no,
                                         p_business_date_in,
                                         p_business_time_in,
                                         p_auth_id_out,
                                         l_fee_narration,
                                         l_fee_merchname,
                                         l_fee_merchcity,
                                         l_fee_merchstate,
                                         l_resp_cde,
                                         l_errmsg);

                  IF l_resp_cde <> '00' OR l_errmsg <> 'OK'
                  THEN
                     l_resp_cde := '21';
                     RAISE exp_rvsl_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_rvsl_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_errmsg :=
                        'Error while reversing the fee amount-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END LOOP;
         END IF;

         BEGIN
            sp_tran_reversal_fees (p_inst_code_in,
                                   p_card_no_in,
                                   p_delivery_channel_in,
                                   l_orgnl_txn_mode,
                                   p_txn_code_in,
                                   p_curr_code_in,
                                   NULL,
                                   NULL,
                                   l_reversal_amt,
                                   p_business_date_in,
                                   p_business_time_in,
                                   NULL,
                                   NULL,
                                   l_resp_cde,
                                   p_msg_typ_in,
                                   '000',
                                   p_rrn_in,
                                   p_terminal_id_in,
                                   l_txn_merchname,
                                   l_txn_merchcity,
                                   p_auth_id_out,
                                   l_fee_merchstate,
                                   p_rvsl_code_in,
                                   l_txn_narration,
                                   l_txn_type,
                                   l_rvsl_trandate,
                                   l_errmsg,
                                   l_resp_cde,
                                   l_fee_amt,
                                   l_fee_plan,
                                   l_fee_code,
                                   l_feeattach_type);

            IF l_errmsg <> 'OK'
            THEN
               l_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while tran_reversal_fees process-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         IF l_orgnl_txn_totalfee_amt = 0 AND l_orgnl_txn_feecode IS NOT NULL
         THEN
            BEGIN
               vmsfee.fee_freecnt_reverse (l_acct_no,
                                           l_orgnl_txn_feecode,
                                           l_errmsg);

               IF l_errmsg <> 'OK'
               THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_errmsg :=
                     'Error while reversing freefee count-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;

         BEGIN
            IF     l_add_ins_date IS NOT NULL
               AND l_prfl_code IS NOT NULL
               AND l_prfl_flag = 'Y'
            THEN
               pkg_limits_check.sp_limitcnt_rever_reset (
                  p_inst_code_in,
                  NULL,
                  NULL,
                  l_orgnl_mcccode,
                  l_orgnl_txn_code,
                  l_tran_type,
                  l_internation_ind_response,
                  l_pos_verification,
                  l_prfl_code,
                  l_reversal_amt,
                  l_orgnl_txn_amnt,
                  p_delivery_channel_in,
                  l_hash_pan,
                  l_add_ins_date,
                  l_resp_cde,
                  l_errmsg);
            END IF;

            IF l_errmsg <> 'OK'
            THEN
               l_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error from Limit count reveer Process-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
		 --Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)									--Added for VMS-5739/FSP-991
    THEN
            UPDATE cms_statements_log
               SET csl_prod_code = l_prod_code,
                   csl_acct_type = l_acct_type,
                   csl_card_type = l_card_type,
                   csl_time_stamp = l_timestamp
             WHERE     csl_inst_code = p_inst_code_in
                   AND csl_pan_no = l_hash_pan
                   AND csl_rrn = p_rrn_in
                   AND csl_txn_code = p_txn_code_in
                   AND csl_delivery_channel = p_delivery_channel_in
                   AND csl_auth_id = p_auth_id_out
                   AND csl_business_date = p_business_date_in
                   AND csl_business_time = p_business_time_in;
ELSE

			UPDATE VMSCMS_HISTORY.cms_statements_log_HIST 			--Added for VMS-5739/FSP-991
               SET csl_prod_code = l_prod_code,
                   csl_acct_type = l_acct_type,
                   csl_card_type = l_card_type,
                   csl_time_stamp = l_timestamp
             WHERE     csl_inst_code = p_inst_code_in
                   AND csl_pan_no = l_hash_pan
                   AND csl_rrn = p_rrn_in
                   AND csl_txn_code = p_txn_code_in
                   AND csl_delivery_channel = p_delivery_channel_in
                   AND csl_auth_id = p_auth_id_out
                   AND csl_business_date = p_business_date_in
                   AND csl_business_time = p_business_time_in;
END IF;				   

            IF SQL%ROWCOUNT = 0
            THEN
               NULL;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while updating timestamp in statementlog-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --SN : Update reversal flag for txn
         BEGIN
		 
		 
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod) 						--Added for VMS-5739/FSP-991
    THEN
            UPDATE transactionlog
               SET tran_reverse_flag = 'Y'
             WHERE     rrn = p_rrn_in
                   AND business_date = l_orgnl_business_date
                   AND business_time = l_orgnl_business_time
                   AND response_code = '00'
                   AND customer_card_no = l_hash_pan
                   AND instcode = p_inst_code_in
                   AND auth_id = l_orgnl_auth_id
                   AND NVL (tran_reverse_flag, 'N') <> 'Y';
				   
ELSE
			UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST				 --Added for VMS-5739/FSP-991
               SET tran_reverse_flag = 'Y'
             WHERE     rrn = p_rrn_in
                   AND business_date = l_orgnl_business_date
                   AND business_time = l_orgnl_business_time
                   AND response_code = '00'
                   AND customer_card_no = l_hash_pan
                   AND instcode = p_inst_code_in
                   AND auth_id = l_orgnl_auth_id
                   AND NVL (tran_reverse_flag, 'N') <> 'Y';
END IF;				   

            IF SQL%ROWCOUNT = 0
            THEN
               l_resp_cde := '52';
               l_errmsg := 'Reversal/Deactivation already done';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_errmsg :=
                  'Error while updating txn reversal flag- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         l_resp_cde := '1';

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE     cms_inst_code = p_inst_code_in
                   AND cms_delivery_channel = p_delivery_channel_in
                   AND cms_response_id = TO_NUMBER (l_resp_cde);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                  'Problem while selecting data from response master for respose code'
                  || l_resp_cde
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '69';
               RAISE exp_rvsl_reject_record;
         END;

         p_curr_out := p_curr_code_in;
         p_autherized_amount_out :=
            TO_CHAR (l_reversal_amt, '99999999999999990.99');
         p_resp_msg_out := 'Success';
         l_tran_amt := l_reversal_amt;
      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_rvsl_reject_record
         THEN
            ROLLBACK;

            p_auth_id_out := 0;
            p_curr_out := p_curr_code_in;
            p_autherized_amount_out := '0.00';
            p_resp_msg_out := l_errmsg;

            IF l_dupl_indc = 1
            THEN
               BEGIN
                  SELECT response_code
                    INTO p_resp_code_out
                    FROM VMSCMS.TRANSACTIONLOG_VW a, 							--Added for VMS-5739/FSP-991
                         (SELECT MIN (add_ins_date) mindate
                            FROM VMSCMS.TRANSACTIONLOG_VW						--Added for VMS-5739/FSP-991
                           WHERE rrn = p_rrn_in AND acct_balance IS NOT NULL) b
                   WHERE     a.add_ins_date = mindate
                         AND rrn = p_rrn_in
                         AND acct_balance IS NOT NULL;
						  
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_resp_msg_out :=
                        'Problem in selecting the response detail of Original transaction-'
                        || SUBSTR (SQLERRM, 1, 300);
                     p_resp_code_out := '89';
                     ROLLBACK;
               END;
            ELSE
               BEGIN
                  SELECT cms_iso_respcde
                    INTO p_resp_code_out
                    FROM cms_response_mast
                   WHERE     cms_inst_code = p_inst_code_in
                         AND cms_delivery_channel = p_delivery_channel_in
                         AND cms_response_id = TO_NUMBER (l_resp_cde);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_resp_msg_out :=
                        'Problem while selecting data from response master '
                        || l_resp_cde
                        || ' is-'
                        || SUBSTR (SQLERRM, 1, 300);
                     p_resp_code_out := '89';
               END;
            END IF;
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            l_resp_cde := '89';

            BEGIN
               p_auth_id_out := 0;
               p_curr_out := p_curr_code_in;
               p_autherized_amount_out := '0.00';
               p_resp_msg_out := l_errmsg;

               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_inst_code_in
                      AND cms_delivery_channel = p_delivery_channel_in
                      AND cms_response_id = TO_NUMBER (l_resp_cde);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg_out :=
                        'Problem while selecting data from response master '
                     || l_resp_cde
                     || ' is-'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code_out := '89';
            END;
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_desc
              INTO l_dr_cr_flag, l_txn_type, l_tran_desc
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

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
                   l_acct_no,
                   l_proxy_number
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

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_balance, l_ledger_balance, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_no AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_balance := 0;
            l_ledger_balance := 0;
      END;


      p_balance_out := TO_CHAR (l_acct_balance, '99999999999999990.99');

      BEGIN
         INSERT INTO TRANSACTIONLOG (MSGTYPE,
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
                                     BANK_CODE,
                                     TOTAL_AMOUNT,
                                     CURRENCYCODE,
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
                                     CARDSTATUS,
                                     TRANS_DESC,
                                     Merchant_Name,
                                     Error_Msg,
                                     STORE_ID,
                                     cr_dr_flag,
                                     acct_type,
                                     time_stamp,
                                     tranfee_amt,
                                     SPIL_PROD_ID,
                                     SPIL_FEE,
                                     SPIL_UPC,
                                     SPIL_MERREF_NUM,
                                     SPIL_REQ_TMZM,
                                     SPIL_LOC_CNTRY,
                                     SPIL_LOC_CRCY,
                                     SPIL_LOC_LANG,
                                     SPIL_POS_ENTRY,
                                     SPIL_POS_COND)
              VALUES (
                        p_msg_typ_in,
                        P_RRN_IN,
                        P_DELIVERY_CHANNEL_IN,
                        p_terminal_id_in,
                        SYSDATE,
                        P_TXN_CODE_IN,
                        l_TXN_TYPE,
                        P_TXN_MODE_IN,
                        DECODE (P_RESP_CODE_OUT, '00', 'C', 'F'),
                        P_RESP_CODE_OUT,
                        p_business_date_in,
                        SUBSTR (p_business_time_in, 1, 10),
                        l_HASH_PAN,
                        P_INST_CODE_IN,
                        TRIM (
                           TO_CHAR (
                              DECODE (
                                 p_resp_code_out,
                                 '00', (l_reversal_amt
                                        + l_orgnl_txn_totalfee_amt),
                                 l_tran_amt),
                              '999999999999999990.99')),
                        l_currcode,--p_curr_code_in,
                        l_PROD_CODE,
                        l_CARD_TYPE,
                        p_terminal_id_in,
                        p_auth_id_out,
                        TRIM (
                           TO_CHAR (
                              DECODE (p_resp_code_out,
                                      '00', l_reversal_amt,
                                      l_tran_amt),
                              '999999999999999990.99')),
                        '0.00',
                        '0.00',
                        P_INST_CODE_IN,
                        l_ENCR_PAN,
                        l_ENCR_PAN,
                        l_PROXy_NUMBER,
                        P_RVSL_CODE_IN,
                        l_ACCT_No,
                        l_ACCT_BALANCE,
                        l_LEDGER_BALANCE,
                        l_resp_cde,
                        l_card_stat,
                        l_TRAN_DESC,
                        P_Merchant_Name_IN,
                        p_resp_msg_out,
                        P_STORE_ID_IN,
                        DECODE (l_dr_cr_flag,
                                'CR', 'DR',
                                'DR', 'CR',
                                l_dr_cr_flag),
                        l_acct_type,
                        SYSTIMESTAMP,
                        NVL (TO_CHAR (l_fee_amt, '99999999999999990.99'),
                             '0.00'),
                        P_SPIL_PROD_ID_IN,
                        P_SPIL_FEE_IN,
                        P_SPIL_UPC_IN,
                        P_SPIL_MERREF_NUM_IN,
                        P_SPIL_REQ_TMZM_IN,
                        P_SPIL_LOC_CNTRY_IN,
                        P_SPIL_LOC_CRCY_IN,
                        P_SPIL_LOC_LANG_IN,
                        P_SPIL_POS_ENTRY_IN,
                        P_SPIL_POS_COND_IN);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_resp_cde := '69';
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_channel_in
               || p_txn_code_in
               || p_card_no_in
               || p_rrn_in
               || TO_CHAR (NVL (l_timestamp, SYSTIMESTAMP),
                           'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            p_resp_msg_out :=
               'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN
         INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_DELIVERY_CHANNEL,
                                              CTD_TXN_CODE,
                                              CTD_MSG_TYPE,
                                              CTD_TXN_MODE,
                                              CTD_BUSINESS_DATE,
                                              CTD_BUSINESS_TIME,
                                              CTD_CUSTOMER_CARD_NO,
                                              CTD_TXN_AMOUNT,
                                              CTD_TXN_CURR,
                                              CTD_ACTUAL_AMOUNT,
                                              CTD_PROCESS_FLAG,
                                              CTD_PROCESS_MSG,
                                              CTD_RRN,
                                              CTD_INST_CODE,
                                              CTD_CUSTOMER_CARD_NO_ENCR,
                                              CTD_CUST_ACCT_NUMBER,
                                              CTD_TXN_TYPE,
                                              CTD_STORE_ADDRESS1,
                                              CTD_STORE_ADDRESS2,
                                              CTD_STORE_CITY,
                                              CTD_STORE_STATE,
                                              CTD_STORE_ZIP,
                                              ctd_hashkey_id)
              VALUES (
                        P_DELIVERY_CHANNEL_IN,
                        P_TXN_CODE_IN,
                        p_msg_typ_in,
                        P_TXN_MODE_IN,
                        p_business_date_in,
                        p_business_time_in,
                        l_HASH_PAN,
                        TRIM (
                           TO_CHAR (NVL (l_tran_amt, p_actual_amt_in),
                                    '99999999999990.99')),
                        l_currcode,--p_curr_code_in,
                        p_actual_amt_in,
                        DECODE (p_resp_code_out, '00', 'Y', 'E'),
                        DECODE (p_resp_code_out,
                                '00', 'Successful',
                                p_resp_msg_out),
                        P_RRN_IN,
                        P_INST_CODE_IN,
                        l_ENCR_PAN,
                        l_ACCT_No,
                        l_TXN_TYPE,
                        P_ADDRESS1_IN,
                        P_ADDRESS2_IN,
                        P_CITY_IN,
                        P_STATE_IN,
                        P_ZIP_IN,
                        l_hashkey_id);

         p_resp_msg_out := p_resp_msg_out;
         RETURN;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_resp_cde :=
               'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            P_RESP_CODE_OUT := '22';
            ROLLBACK;
            RETURN;
      END;

      IF p_resp_msg_out = 'OK'
      THEN
         p_resp_msg_out := 'Success';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         l_resp_cde := '89';
         p_resp_msg_out := 'Main Excp- ' || SUBSTR (SQLERRM, 1, 300);
   END Store_credit_reversal;

   PROCEDURE redemption_unlock (p_inst_code_in            IN     NUMBER,
                                p_msg_typ_in              IN     VARCHAR2,
                                p_rrn_in                  IN     VARCHAR2,
                                p_delivery_channel_in     IN     VARCHAR2,
                                p_term_id_in              IN     VARCHAR2,
                                p_txn_code_in             IN     VARCHAR2,
                                p_txn_mode_in             IN     VARCHAR2,
                                p_business_date_in        IN     VARCHAR2,
                                p_business_time_in        IN     VARCHAR2,
                                p_card_no_in              IN     VARCHAR2,
                                p_txn_amt_in              IN     NUMBER,
                                p_merchant_name_in        IN     VARCHAR2,
                                p_mcc_code_in             IN     VARCHAR2,
                                p_curr_code_in            IN     VARCHAR2,
                                p_stan_in                 IN     VARCHAR2,
                                p_rvsl_code_in            IN     VARCHAR2,
                                p_store_id_in             IN     VARCHAR2,
                                p_product_id_in           IN     VARCHAR2,
                                p_fee_amt_in              IN     NUMBER,
                                p_upc_in                  IN     VARCHAR2,
                                p_mercrefnum_in           IN     VARCHAR2,
                                p_reqtimezone_in          IN     VARCHAR2,
                                p_localcountry_in         IN     VARCHAR2,
                                p_localcurrency_in        IN     VARCHAR2,
                                p_loclanguage_in          IN     VARCHAR2,
                                p_posentry_in             IN     VARCHAR2,
                                p_poscond_in              IN     VARCHAR2,
                                p_address1_in             IN     VARCHAR2,
                                p_address2_in             IN     VARCHAR2,
                                p_city_in                 IN     VARCHAR2,
                                p_state_in                IN     VARCHAR2,
                                p_zip_in                  IN     VARCHAR2,
                                p_resp_code_out              OUT VARCHAR2,
                                p_resp_msg_out               OUT VARCHAR2,
                                p_auth_id_out                OUT VARCHAR2,
                                p_autherized_amount_out      OUT VARCHAR2,
                                p_balance_out                OUT VARCHAR2)
   AS
      l_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_number            cms_appl_pan.cap_acct_no%TYPE;
      l_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
      l_card_stat              cms_appl_pan.cap_card_stat%TYPE;
      l_firsttime_topup        cms_appl_pan.cap_firsttime_topup%TYPE;
      l_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
      l_prod_code              cms_appl_pan.cap_prod_code%TYPE;
      l_card_type              cms_appl_pan.cap_card_type%TYPE;
      l_expry_date             cms_appl_pan.cap_expry_date%TYPE;
      l_acct_balance           cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type              cms_acct_mast.cam_type_code%TYPE;
      l_tran_amt               cms_acct_mast.cam_acct_bal%TYPE;
      l_default_partial_indr   cms_prod_cattype.cpc_default_partial_indr%TYPE;
      l_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
      l_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_tran_type              cms_transaction_mast.ctm_tran_type%TYPE;
      l_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_tran_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_login_txn              cms_transaction_mast.ctm_login_txn%TYPE;
      l_preauth_type           cms_transaction_mast.ctm_preauth_type%TYPE;
      l_currcode               gen_curr_mast.gcm_curr_code%TYPE;
      l_dupchk_cardstat        transactionlog.cardstatus%TYPE;
      l_dupchk_acctbal         transactionlog.acct_balance%TYPE;
      l_preauth_flag           pcms_tranauth_param.ptp_param_value%TYPE;
      l_comb_hash              pkg_limits_check.type_hash;
      l_hold_amount            cms_preauth_transaction.cpt_totalhold_amt%TYPE;
      l_completion_fee         cms_preauth_transaction.cpt_completion_fee%TYPE;
      l_cpt_rrn                cms_preauth_transaction.cpt_rrn%TYPE;
      l_complfree_flag         cms_preauth_transaction.cpt_complfree_flag%TYPE;
      l_fee_plan               transactionlog.fee_plan%TYPE;
      l_feeattach_type         transactionlog.feeattachtype%TYPE;
      l_tranfee_amt            transactionlog.tranfee_amt%TYPE;
      l_total_amt              transactionlog.total_amount%TYPE;
      l_narration              cms_statements_log.csl_trans_narrration%TYPE;
      l_fee_code               cms_fee_mast.cfm_fee_code%TYPE;
      l_preauth_exp_period     cms_prod_mast.cpm_pre_auth_exp_date%TYPE;
      l_fee_crgl_catg          cms_prodcattype_fees.cpf_crgl_catg%TYPE;
      l_fee_crgl_code          cms_prodcattype_fees.cpf_crgl_code%TYPE;
      l_fee_crsubgl_code       cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
      l_fee_cracct_no          cms_prodcattype_fees.cpf_cracct_no%TYPE;
      l_fee_drgl_catg          cms_prodcattype_fees.cpf_drgl_catg%TYPE;
      l_fee_drgl_code          cms_prodcattype_fees.cpf_drgl_code%TYPE;
      l_fee_drsubgl_code       cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
      l_fee_dracct_no          cms_prodcattype_fees.cpf_dracct_no%TYPE;
      l_st_calc_flag           cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
      l_cess_calc_flag         cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
      l_st_cracct_no           cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
      l_st_dracct_no           cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
      l_cess_cracct_no         cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
      l_cess_dracct_no         cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
      l_waiv_percnt            cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
      l_feeamnt_type           cms_fee_mast.cfm_feeamnt_type%TYPE;
      l_clawback               cms_fee_mast.cfm_clawback_flag%TYPE;
      l_per_fees               cms_fee_mast.cfm_per_fees%TYPE;
      l_flat_fees              cms_fee_mast.cfm_fee_amt%TYPE;
      l_fee_desc               cms_fee_mast.cfm_fee_desc%TYPE;
      l_servicetax_percent     cms_inst_param.cip_param_value%TYPE;
      l_cess_percent           cms_inst_param.cip_param_value%TYPE;
      l_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_orgnl_business_date    cms_preauth_transaction.cpt_txn_date%TYPE;
      l_orgnl_business_time    cms_preauth_transaction.cpt_txn_time%TYPE;
      l_mbr_numb               VARCHAR2 (5) := '000';
      l_match_rule             VARCHAR2 (10);
      l_fee_opening_bal        NUMBER (9, 2);
      l_fee_reverse_amount     NUMBER (9, 2);
      l_comp_total_fee         NUMBER (9, 2);
      l_fee_amt                NUMBER (9, 2);
      l_total_fee              NUMBER (9, 2);
      l_tot_hold_amt           NUMBER (9, 2);
      l_servicetax_amount      NUMBER (9, 2);
      l_cess_amount            NUMBER (9, 2);
      l_freetxn_exceed         VARCHAR2 (1);
      l_duration               VARCHAR2 (20);
      l_lock_found             VARCHAR2 (2);
      l_rowid                  VARCHAR2 (40);
      l_txn_type               VARCHAR2 (2);
      l_tran_date              DATE;
      l_card_curr              VARCHAR2 (5);
      l_lock_amt               VARCHAR2 (20);
      l_dupchk_count           NUMBER;
      l_time_stamp             TIMESTAMP;
      l_resp_cde               VARCHAR2 (5);
      l_err_msg                VARCHAR2 (900) := 'OK';
      exp_reject_record        EXCEPTION;
	  
	  v_Retperiod  date;  --Added for VMS-5739/FSP-991
	  v_Retdate  date; --Added for VMS-5739/FSP-991
   BEGIN
      BEGIN
         l_tran_amt := NVL (ROUND (p_txn_amt_in, 2), 0);

         --SN : Convert clear card number to hash and encryped format.
         BEGIN
            l_hash_pan := gethash (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            l_encr_pan := fn_emaps_main (p_card_no_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while converting pan-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Convert clear card number to hash and encryped format.

         --SN : Get currency code
         BEGIN
            SELECT gcm_curr_code
              INTO l_currcode
              FROM gen_curr_mast
             WHERE gcm_inst_code = p_inst_code_in
                   AND gcm_curr_name = p_curr_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '65';
               l_err_msg := 'Invalid Currency Code';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                     'Error while selecting the currency code for '
                  || p_curr_code_in
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get currency code

         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO p_auth_id_out
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
                   l_tran_preauth_flag,
                   l_login_txn,
                   l_preauth_type
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '49';
               l_err_msg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting transaction dtls from master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN : Get transaction details from master
         --SN : Get card details
         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_card_stat,
                   cap_proxy_number,
                   cap_acct_no,
                   cap_prfl_code,
                   cap_firsttime_topup,
                   cap_expry_date
              INTO l_prod_code,
                   l_card_type,
                   l_card_stat,
                   l_proxunumber,
                   l_acct_number,
                   l_prfl_code,
                   l_firsttime_topup,
                   l_expry_date
              FROM cms_appl_pan
             WHERE     cap_pan_code = l_hash_pan
                   AND cap_mbr_numb = l_mbr_numb
                   AND cap_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '56';
               l_err_msg := 'Invalid Card';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Problem while selecting card detail-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get card details

         --SN : Transaction date-time check
         BEGIN
            l_tran_date :=
               TO_DATE (SUBSTR (TRIM (p_business_date_in), 1, 8), 'yyyymmdd');
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
                     SUBSTR (TRIM (p_business_date_in), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_business_time_in), 1, 10),
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

         --SN : Duplicate RRN check
         BEGIN
            SELECT NVL (cardstatus, 0), acct_balance
              INTO l_dupchk_cardstat, l_dupchk_acctbal
              FROM (  SELECT cardstatus, acct_balance
                        FROM  VMSCMS.TRANSACTIONLOG                                --Added for VMS-5739/FSP-991
                       WHERE     rrn = p_rrn_in
                             AND customer_card_no = l_hash_pan
                             AND delivery_channel = p_delivery_channel_in
                             AND acct_balance IS NOT NULL
                    ORDER BY add_ins_date DESC)
             WHERE ROWNUM = 1;
			 IF SQL%ROWCOUNT = 0 THEN
			    SELECT NVL (cardstatus, 0), acct_balance
              INTO l_dupchk_cardstat, l_dupchk_acctbal
              FROM (  SELECT cardstatus, acct_balance
                        FROM  VMSCMS_HISTORY.TRANSACTIONLOG_HIST                               --Added for VMS-5739/FSP-991
                       WHERE     rrn = p_rrn_in
                             AND customer_card_no = l_hash_pan
                             AND delivery_channel = p_delivery_channel_in
                             AND acct_balance IS NOT NULL
                    ORDER BY add_ins_date DESC)
             WHERE ROWNUM = 1;
			 END IF;

            l_dupchk_count := 1;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_dupchk_count := 0;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while selecting card status and acct balance from txnlog-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN : Get account balance details from acct master
         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO l_acct_balance, l_ledger_bal, l_acct_type
              FROM cms_acct_mast
             WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '56';
               l_err_msg := 'Account not found in acct master ';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting account balance from acct master-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Get account balance details from acct master

         --         --Check for Balance
         --         IF NVL (l_acct_balance, 0) <= 0
         --         THEN
         --            l_resp_cde := '75';
         --            l_err_msg := 'Insufficient Funds';
         --            RAISE exp_reject_record;
         --         END IF;

         IF l_dupchk_count = 1
         THEN
            IF l_dupchk_cardstat = l_card_stat
               AND l_dupchk_acctbal = l_acct_balance
            THEN
               l_resp_cde := '22';
               l_err_msg := 'Duplicate Incomm Reference Number-' || p_rrn_in;
               RAISE exp_reject_record;
            ELSE
               l_dupchk_count := 0;
            END IF;
         END IF;

         --EN : Duplicate RRN check

         IF (p_txn_amt_in >= 0)
         THEN
            BEGIN
               sp_convert_curr (p_inst_code_in,
                                l_currcode,
                                p_card_no_in,
                                p_txn_amt_in,
                                l_tran_date,
                                l_tran_amt,
                                l_card_curr,
                                l_err_msg,
                                l_prod_code,
                                l_card_type);

               IF l_err_msg <> 'OK'
               THEN
                  l_resp_cde := '65';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '89';
                  l_err_msg :=
                     'Error from currency conversion '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSE
            l_resp_cde := '43';
            l_err_msg := 'INVALID AMOUNT';
            RAISE exp_reject_record;
         END IF;

         BEGIN
            SELECT ptp_param_value
              INTO l_preauth_flag
              FROM pcms_tranauth_param
             WHERE ptp_param_name = 'PRE AUTH'
                   AND ptp_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Master set up is not done for Authorization Process';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while selecting preauth falg-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --SN : check for Preauth
         IF l_preauth_flag = 1
         THEN
            BEGIN
               sp_preauthorize_txn (p_card_no_in,
                                    p_mcc_code_in,
                                    p_curr_code_in,
                                    l_tran_date,
                                    p_txn_code_in,
                                    p_inst_code_in,
                                    p_business_date_in,
                                    l_tran_amt,
                                    p_delivery_channel_in,
                                    l_resp_cde,
                                    l_err_msg);

               IF (l_resp_cde <> '1' OR l_err_msg <> 'OK')
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
                     'Error from pre_auth process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

         --EN : check for preauth

         BEGIN
            SELECT rd,
                   hold_amt,
                   rrn,
                   completion_fee,
                   complfree_flag,
                   cpt_txn_date,
                   cpt_txn_time
              INTO l_rowid,
                   l_hold_amount,
                   l_cpt_rrn,
                   l_completion_fee,
                   l_complfree_flag,
                   l_orgnl_business_date,
                   l_orgnl_business_time
              FROM (  SELECT ROWID rd,
                             cpt_totalhold_amt hold_amt,
                             cpt_rrn rrn,
                             NVL (cpt_completion_fee, '0') completion_fee,
                             NVL (cpt_complfree_flag, 'N') complfree_flag,
                             cpt_txn_date,
                             cpt_txn_time
                        FROM VMSCMS.CMS_PREAUTH_TRANSACTION  			--Added for VMS-5739/FSP-991
                       WHERE     cpt_mbr_no = '000'
                             AND cpt_transaction_flag = 'N'
                             AND cpt_preauth_validflag <> 'N'
                             AND cpt_expiry_flag = 'N'
                             AND cpt_preauth_type = l_preauth_type
                             AND cpt_inst_code = p_inst_code_in
                             AND cpt_card_no = l_hash_pan
                             AND cpt_approve_amt = l_tran_amt
                             AND cpt_terminalid = p_term_id_in
                             AND cpt_store_id = p_store_id_in
                    ORDER BY cpt_ins_date DESC)
             WHERE ROWNUM = 1;
			 IF SQL%ROWCOUNT = 0 THEN
			 SELECT rd,
                   hold_amt,
                   rrn,
                   completion_fee,
                   complfree_flag,
                   cpt_txn_date,
                   cpt_txn_time
              INTO l_rowid,
                   l_hold_amount,
                   l_cpt_rrn,
                   l_completion_fee,
                   l_complfree_flag,
                   l_orgnl_business_date,
                   l_orgnl_business_time
              FROM (  SELECT ROWID rd,
                             cpt_totalhold_amt hold_amt,
                             cpt_rrn rrn,
                             NVL (cpt_completion_fee, '0') completion_fee,
                             NVL (cpt_complfree_flag, 'N') complfree_flag,
                             cpt_txn_date,
                             cpt_txn_time
                        FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST  			--Added for VMS-5739/FSP-991
                       WHERE     cpt_mbr_no = '000'
                             AND cpt_transaction_flag = 'N'
                             AND cpt_preauth_validflag <> 'N'
                             AND cpt_expiry_flag = 'N'
                             AND cpt_preauth_type = l_preauth_type
                             AND cpt_inst_code = p_inst_code_in
                             AND cpt_card_no = l_hash_pan
                             AND cpt_approve_amt = l_tran_amt
                             AND cpt_terminalid = p_term_id_in
                             AND cpt_store_id = p_store_id_in
                    ORDER BY cpt_ins_date DESC)
             WHERE ROWNUM = 1;
			 END IF;

            l_match_rule := 'Rule1';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT rd,
                         hold_amt,
                         rrn,
                         completion_fee,
                         complfree_flag,
                         cpt_txn_date,
                         cpt_txn_time
                    INTO l_rowid,
                         l_hold_amount,
                         l_cpt_rrn,
                         l_completion_fee,
                         l_complfree_flag,
                         l_orgnl_business_date,
                         l_orgnl_business_time
                    FROM (  SELECT ROWID rd,
                                   cpt_totalhold_amt hold_amt,
                                   cpt_rrn rrn,
                                   NVL (cpt_completion_fee, '0') completion_fee,
                                   NVL (cpt_complfree_flag, 'N') complfree_flag,
                                   cpt_txn_date,
                                   cpt_txn_time
                              FROM  VMSCMS.CMS_PREAUTH_TRANSACTION 			--Added for VMS-5739/FSP-991
                             WHERE     cpt_mbr_no = '000'
                                   AND cpt_transaction_flag = 'N'
                                   AND cpt_preauth_validflag <> 'N'
                                   AND cpt_expiry_flag = 'N'
                                   AND cpt_preauth_type = l_preauth_type
                                   AND cpt_inst_code = p_inst_code_in
                                   AND cpt_card_no = l_hash_pan
                                   AND cpt_terminalid = p_term_id_in
                                   AND cpt_store_id = p_store_id_in
                          ORDER BY cpt_ins_date DESC)
                   WHERE ROWNUM = 1;
				   	 IF SQL%ROWCOUNT = 0 THEN
					 SELECT rd,
                         hold_amt,
                         rrn,
                         completion_fee,
                         complfree_flag,
                         cpt_txn_date,
                         cpt_txn_time
                    INTO l_rowid,
                         l_hold_amount,
                         l_cpt_rrn,
                         l_completion_fee,
                         l_complfree_flag,
                         l_orgnl_business_date,
                         l_orgnl_business_time
                    FROM (  SELECT ROWID rd,
                                   cpt_totalhold_amt hold_amt,
                                   cpt_rrn rrn,
                                   NVL (cpt_completion_fee, '0') completion_fee,
                                   NVL (cpt_complfree_flag, 'N') complfree_flag,
                                   cpt_txn_date,
                                   cpt_txn_time
                              FROM  VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST 			--Added for VMS-5739/FSP-991
                             WHERE     cpt_mbr_no = '000'
                                   AND cpt_transaction_flag = 'N'
                                   AND cpt_preauth_validflag <> 'N'
                                   AND cpt_expiry_flag = 'N'
                                   AND cpt_preauth_type = l_preauth_type
                                   AND cpt_inst_code = p_inst_code_in
                                   AND cpt_card_no = l_hash_pan
                                   AND cpt_terminalid = p_term_id_in
                                   AND cpt_store_id = p_store_id_in
                          ORDER BY cpt_ins_date DESC)
                   WHERE ROWNUM = 1;
					 END IF;

                  l_match_rule := 'Rule2';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     BEGIN
                        SELECT rd,
                               hold_amt,
                               rrn,
                               completion_fee,
                               complfree_flag,
                               cpt_txn_date,
                               cpt_txn_time
                          INTO l_rowid,
                               l_hold_amount,
                               l_cpt_rrn,
                               l_completion_fee,
                               l_complfree_flag,
                               l_orgnl_business_date,
                               l_orgnl_business_time
                          FROM (  SELECT ROWID rd,
                                         cpt_totalhold_amt hold_amt,
                                         cpt_rrn rrn,
                                         NVL (cpt_completion_fee, '0')
                                            completion_fee,
                                         NVL (cpt_complfree_flag, 'N')
                                            complfree_flag,
                                         cpt_txn_date,
                                         cpt_txn_time
                                    FROM  VMSCMS.CMS_PREAUTH_TRANSACTION 				--Added for VMS-5739/FSP-991
                                   WHERE     cpt_mbr_no = '000'
                                         AND cpt_transaction_flag = 'N'
                                         AND cpt_preauth_validflag <> 'N'
                                         AND cpt_expiry_flag = 'N'
                                         AND cpt_preauth_type = l_preauth_type
                                         AND cpt_inst_code = p_inst_code_in
                                         AND cpt_card_no = l_hash_pan
                                         AND cpt_store_id = p_store_id_in
                                ORDER BY cpt_ins_date DESC)
                         WHERE ROWNUM = 1;
						 IF SQL%ROWCOUNT = 0 THEN
						 SELECT rd,
                               hold_amt,
                               rrn,
                               completion_fee,
                               complfree_flag,
                               cpt_txn_date,
                               cpt_txn_time
                          INTO l_rowid,
                               l_hold_amount,
                               l_cpt_rrn,
                               l_completion_fee,
                               l_complfree_flag,
                               l_orgnl_business_date,
                               l_orgnl_business_time
                          FROM (  SELECT ROWID rd,
                                         cpt_totalhold_amt hold_amt,
                                         cpt_rrn rrn,
                                         NVL (cpt_completion_fee, '0')
                                            completion_fee,
                                         NVL (cpt_complfree_flag, 'N')
                                            complfree_flag,
                                         cpt_txn_date,
                                         cpt_txn_time
                                    FROM  VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST 				--Added for VMS-5739/FSP-991
                                   WHERE     cpt_mbr_no = '000'
                                         AND cpt_transaction_flag = 'N'
                                         AND cpt_preauth_validflag <> 'N'
                                         AND cpt_expiry_flag = 'N'
                                         AND cpt_preauth_type = l_preauth_type
                                         AND cpt_inst_code = p_inst_code_in
                                         AND cpt_card_no = l_hash_pan
                                         AND cpt_store_id = p_store_id_in
                                ORDER BY cpt_ins_date DESC)
                         WHERE ROWNUM = 1;
						 END IF;

                        l_match_rule := 'Rule3';
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                                l_lock_found := 'N';
                                 l_match_rule := 'U';
                                 l_completion_fee := 0;
                                 l_hold_amount := 0;
                        WHEN OTHERS
                        THEN
                           l_resp_cde := '89';
                           l_err_msg :=
                              'Error while selecting identity the original Lock transaction-'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '89';
                     l_err_msg :=
                        'Error while selecting identity the original Lock transaction-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while selecting identity the original Lock transaction-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         IF l_match_rule <> 'U'
         THEN
            l_lock_found := 'Y';
         END IF;

         --SN : Transaction limits check
         BEGIN
            IF (l_prfl_code IS NOT NULL AND l_prfl_flag = 'Y')
            THEN
               pkg_limits_check.sp_limits_check (l_hash_pan,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 p_txn_code_in,
                                                 l_tran_type,
                                                 NULL,
                                                 NULL,
                                                 p_inst_code_in,
                                                 NULL,
                                                 l_prfl_code,
                                                 l_tran_amt,
                                                 p_delivery_channel_in,
                                                 l_comb_hash,
                                                 l_resp_cde,
                                                 l_err_msg);
            END IF;

            IF l_resp_cde <> '00' AND l_err_msg <> 'OK'
            THEN
               IF l_resp_cde = '127'
               THEN
                  l_resp_cde := '140';
               ELSE
                  l_resp_cde := l_resp_cde;
               END IF;

               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '89';
               l_err_msg :=
                  'Error while limits check-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : Transaction limits check

         l_time_stamp := SYSTIMESTAMP;

         ---SN : dynamic fee calculation .
         BEGIN
            sp_tran_fees_cmsauth (p_inst_code_in,
                                  p_card_no_in,
                                  p_delivery_channel_in,
                                  l_txn_type,
                                  p_txn_mode_in,
                                  p_txn_code_in,
                                  p_curr_code_in,
                                  NULL,
                                  NULL,
                                  l_tran_amt,
                                  l_tran_date,
                                  NULL,              --p_international_ind_in,
                                  NULL,                --p_pos_verfication_in,
                                  l_resp_cde,
                                  p_msg_typ_in,
                                  p_rvsl_code_in,
                                  p_mcc_code_in,
                                  l_fee_amt,
                                  l_err_msg,
                                  l_fee_code,
                                  l_fee_crgl_catg,
                                  l_fee_crgl_code,
                                  l_fee_crsubgl_code,
                                  l_fee_cracct_no,
                                  l_fee_drgl_catg,
                                  l_fee_drgl_code,
                                  l_fee_drsubgl_code,
                                  l_fee_dracct_no,
                                  l_st_calc_flag,
                                  l_cess_calc_flag,
                                  l_st_cracct_no,
                                  l_st_dracct_no,
                                  l_cess_cracct_no,
                                  l_cess_dracct_no,
                                  l_feeamnt_type,
                                  l_clawback,
                                  l_fee_plan,
                                  l_per_fees,
                                  l_flat_fees,
                                  l_freetxn_exceed,
                                  l_duration,
                                  l_feeattach_type,
                                  l_fee_desc,
                                  l_complfree_flag);

            IF l_err_msg <> 'OK'
            THEN
               l_resp_cde := '21';
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
                  'Error from fee calc process- ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         ---EN : dynamic fee calculation .

         --SN : calculate waiver on the fee
         BEGIN
            sp_calculate_waiver (p_inst_code_in,
                                 p_card_no_in,
                                 l_mbr_numb,
                                 l_prod_code,
                                 l_card_type,
                                 l_fee_code,
                                 l_fee_plan,
                                 l_tran_date,
                                 l_waiv_percnt,
                                 l_err_msg);

            IF l_err_msg <> 'OK'
            THEN
               l_resp_cde := '21';
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
                  'Error from waiver calc process- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --EN : calculate waiver on the fee

         l_fee_amt :=
            ROUND (l_fee_amt - ( (l_fee_amt * l_waiv_percnt) / 100), 2);

         --SN : Get institution paramerters
         BEGIN
            FOR l_idx
               IN (SELECT cip_param_key, cip_param_value
                     FROM cms_inst_param
                    WHERE cip_param_key IN ('SERVICETAX', 'CESS')
                          AND cip_inst_code = p_inst_code_in)
            LOOP
               IF l_idx.cip_param_key = 'SERVICETAX'
               THEN
                  l_servicetax_percent := l_idx.cip_param_value;
               ELSIF l_idx.cip_param_key = 'CESS'
               THEN
                  l_cess_percent := l_idx.cip_param_value;
               END IF;
            END LOOP;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while selecting selection  institution parameters-'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE exp_reject_record;
         END;

         --EN : Get institution paramerters

         --SN : Apply service tax and cess
         IF l_st_calc_flag = 1
         THEN
            l_servicetax_amount := (l_fee_amt * l_servicetax_percent) / 100;
         ELSE
            l_servicetax_amount := 0;
         END IF;

         IF l_cess_calc_flag = 1
         THEN
            l_cess_amount := (l_servicetax_amount * l_cess_percent) / 100;
         ELSE
            l_cess_amount := 0;
         END IF;

         l_total_fee :=
            ROUND (l_fee_amt + l_servicetax_amount + l_cess_amount, 2);

         --EN : Apply service tax and cess
         IF l_lock_found <> 'N'
         THEN
            IF l_total_fee = l_completion_fee
            THEN
               l_comp_total_fee := 0;
            ELSIF l_total_fee > l_completion_fee
            THEN
               l_comp_total_fee := l_total_fee - l_completion_fee;
            ELSIF l_total_fee < l_completion_fee
            THEN
               l_comp_total_fee := l_completion_fee - l_total_fee;
            END IF;
         END IF;

         IF l_lock_found = 'Y'
         THEN
            l_lock_amt := TO_NUMBER (l_hold_amount) || 'N' || 'L';
         ELSE
            l_lock_amt := '0';
         END IF;

         BEGIN
            sp_upd_transaction_accnt_auth (p_inst_code_in,
                                           l_tran_date,
                                           l_prod_code,
                                           l_card_type,
                                           l_tran_amt,
                                           NULL,
                                           p_txn_code_in,
                                           l_dr_cr_flag,
                                           p_rrn_in,
                                           p_term_id_in,
                                           p_delivery_channel_in,
                                           p_txn_mode_in,
                                           p_card_no_in,
                                           l_fee_code,
                                           l_total_fee,           --l_fee_amt,
                                           l_fee_cracct_no,
                                           l_fee_dracct_no,
                                           l_st_calc_flag,
                                           l_cess_calc_flag,
                                           l_servicetax_amount,
                                           l_st_cracct_no,
                                           l_st_dracct_no,
                                           l_cess_amount,
                                           l_cess_cracct_no,
                                           l_cess_dracct_no,
                                           l_acct_number,
                                           l_lock_amt,
                                           p_msg_typ_in,
                                           l_resp_cde,
                                           l_err_msg,
                                           l_completion_fee);

            IF (l_resp_cde <> '1' OR l_err_msg <> 'OK')
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
                  'Error from upd_transaction_accnt_auth-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            IF TRIM (l_trans_desc) IS NOT NULL
            THEN
               l_narration := l_trans_desc || '/';
            END IF;

            IF TRIM (p_merchant_name_in) IS NOT NULL
            THEN
               l_narration := l_narration || p_merchant_name_in || '/';
            END IF;

            IF TRIM (p_term_id_in) IS NOT NULL
            THEN
               l_narration := l_narration || p_term_id_in || '/';
            END IF;

            IF TRIM (p_business_date_in) IS NOT NULL
            THEN
               l_narration := l_narration || p_business_date_in || '/';
            END IF;

            l_narration := l_narration || p_auth_id_out;
         END;

         BEGIN
            INSERT INTO cms_statements_log (csl_pan_no,
                                            csl_opening_bal,
                                            csl_trans_amount,
                                            csl_trans_type,
                                            csl_trans_date,
                                            csl_closing_balance,
                                            csl_trans_narrration,
                                            csl_inst_code,
                                            csl_pan_no_encr,
                                            csl_rrn,
                                            csl_auth_id,
                                            csl_business_date,
                                            csl_business_time,
                                            txn_fee_flag,
                                            csl_delivery_channel,
                                            csl_txn_code,
                                            csl_acct_no,
                                            csl_ins_user,
                                            csl_ins_date,
                                            csl_merchant_name,
                                            csl_panno_last4digit,
                                            csl_prod_code,
                                            csl_card_type,
                                            csl_acct_type,
                                            csl_time_stamp)
                 VALUES (l_hash_pan,
                         l_ledger_bal,
                         l_tran_amt,
                         l_dr_cr_flag,
                         l_tran_date,
                         l_ledger_bal - l_tran_amt,
                         l_narration,
                         p_inst_code_in,
                         l_encr_pan,
                         p_rrn_in,
                         p_auth_id_out,
                         p_business_date_in,
                         p_business_time_in,
                         'N',
                         p_delivery_channel_in,
                         p_txn_code_in,
                         l_acct_number,
                         1,
                         SYSDATE,
                         p_merchant_name_in,
                         SUBSTR (p_card_no_in, -4),
                         l_prod_code,
                         l_card_type,
                         l_acct_type,
                         l_time_stamp);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Problem while inserting into statement log for tran amt '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            IF l_total_fee <> 0 OR l_freetxn_exceed = 'N'
            THEN
               l_fee_opening_bal := l_ledger_bal - l_tran_amt;

               IF l_freetxn_exceed = 'N'
               THEN
                  INSERT INTO cms_statements_log (csl_pan_no,
                                                  csl_opening_bal,
                                                  csl_trans_amount,
                                                  csl_trans_type,
                                                  csl_trans_date,
                                                  csl_closing_balance,
                                                  csl_trans_narrration,
                                                  csl_inst_code,
                                                  csl_pan_no_encr,
                                                  csl_rrn,
                                                  csl_auth_id,
                                                  csl_business_date,
                                                  csl_business_time,
                                                  txn_fee_flag,
                                                  csl_delivery_channel,
                                                  csl_txn_code,
                                                  csl_acct_no,
                                                  csl_ins_user,
                                                  csl_ins_date,
                                                  csl_merchant_name,
                                                  csl_panno_last4digit,
                                                  csl_prod_code,
                                                  csl_card_type,
                                                  csl_acct_type,
                                                  csl_time_stamp)
                       VALUES (l_hash_pan,
                               l_fee_opening_bal,
                               l_total_fee,
                               'DR',
                               l_tran_date,
                               l_fee_opening_bal - l_total_fee,
                               l_fee_desc,
                               p_inst_code_in,
                               l_encr_pan,
                               p_rrn_in,
                               p_auth_id_out,
                               p_business_date_in,
                               p_business_time_in,
                               'Y',
                               p_delivery_channel_in,
                               p_txn_code_in,
                               l_acct_number,
                               1,
                               SYSDATE,
                               p_merchant_name_in,
                               SUBSTR (p_card_no_in, -4),
                               l_prod_code,
                               l_card_type,
                               l_acct_type,
                               l_time_stamp);
               ELSE
                  IF l_feeamnt_type = 'A'
                  THEN
                     l_flat_fees :=
                        ROUND (
                           l_flat_fees
                           - ( (l_flat_fees * l_waiv_percnt) / 100),
                           2);


                     l_per_fees :=
                        ROUND (
                           l_per_fees - ( (l_per_fees * l_waiv_percnt) / 100),
                           2);

                     --SN : Entry for flat  Fee
                     INSERT INTO cms_statements_log (csl_pan_no,
                                                     csl_opening_bal,
                                                     csl_trans_amount,
                                                     csl_trans_type,
                                                     csl_trans_date,
                                                     csl_closing_balance,
                                                     csl_trans_narrration,
                                                     csl_inst_code,
                                                     csl_pan_no_encr,
                                                     csl_rrn,
                                                     csl_auth_id,
                                                     csl_business_date,
                                                     csl_business_time,
                                                     txn_fee_flag,
                                                     csl_delivery_channel,
                                                     csl_txn_code,
                                                     csl_acct_no,
                                                     csl_ins_user,
                                                     csl_ins_date,
                                                     csl_merchant_name,
                                                     csl_panno_last4digit,
                                                     csl_prod_code,
                                                     csl_card_type,
                                                     csl_acct_type,
                                                     csl_time_stamp)
                          VALUES (l_hash_pan,
                                  l_fee_opening_bal,
                                  l_flat_fees,
                                  'DR',
                                  l_tran_date,
                                  l_fee_opening_bal - l_flat_fees,
                                  'Fixed Fee debited for ' || l_fee_desc,
                                  p_inst_code_in,
                                  l_encr_pan,
                                  p_rrn_in,
                                  p_auth_id_out,
                                  p_business_date_in,
                                  p_business_time_in,
                                  'Y',
                                  p_delivery_channel_in,
                                  p_txn_code_in,
                                  l_acct_number,
                                  1,
                                  SYSDATE,
                                  p_merchant_name_in,
                                  SUBSTR (p_card_no_in, -4),
                                  l_prod_code,
                                  l_card_type,
                                  l_acct_type,
                                  l_time_stamp);

                     --EN : Entry for flat  Fee
                     --SN : Entry for Percentage Fee
                     INSERT INTO cms_statements_log (csl_pan_no,
                                                     csl_opening_bal,
                                                     csl_trans_amount,
                                                     csl_trans_type,
                                                     csl_trans_date,
                                                     csl_closing_balance,
                                                     csl_trans_narrration,
                                                     csl_inst_code,
                                                     csl_pan_no_encr,
                                                     csl_rrn,
                                                     csl_auth_id,
                                                     csl_business_date,
                                                     csl_business_time,
                                                     txn_fee_flag,
                                                     csl_delivery_channel,
                                                     csl_txn_code,
                                                     csl_acct_no,
                                                     csl_ins_user,
                                                     csl_ins_date,
                                                     csl_merchant_name,
                                                     csl_panno_last4digit,
                                                     csl_prod_code,
                                                     csl_card_type,
                                                     csl_acct_type,
                                                     csl_time_stamp)
                          VALUES (
                                    l_hash_pan,
                                    (l_fee_opening_bal - l_flat_fees),
                                    l_per_fees,
                                    'DR',
                                    l_tran_date,
                                    (l_fee_opening_bal - l_flat_fees)
                                    - l_per_fees,
                                    'Percentage Fee debited for '
                                    || l_fee_desc,
                                    p_inst_code_in,
                                    l_encr_pan,
                                    p_rrn_in,
                                    p_auth_id_out,
                                    p_business_date_in,
                                    p_business_time_in,
                                    'Y',
                                    p_delivery_channel_in,
                                    p_txn_code_in,
                                    l_acct_number,
                                    1,
                                    SYSDATE,
                                    p_merchant_name_in,
                                    SUBSTR (p_card_no_in, -4),
                                    l_prod_code,
                                    l_card_type,
                                    l_acct_type,
                                    l_time_stamp);
                  --EN : Entry for Percentage Fee

                  ELSE
                     INSERT INTO cms_statements_log (csl_pan_no,
                                                     csl_opening_bal,
                                                     csl_trans_amount,
                                                     csl_trans_type,
                                                     csl_trans_date,
                                                     csl_closing_balance,
                                                     csl_trans_narrration,
                                                     csl_inst_code,
                                                     csl_pan_no_encr,
                                                     csl_rrn,
                                                     csl_auth_id,
                                                     csl_business_date,
                                                     csl_business_time,
                                                     txn_fee_flag,
                                                     csl_delivery_channel,
                                                     csl_txn_code,
                                                     csl_acct_no,
                                                     csl_ins_user,
                                                     csl_ins_date,
                                                     csl_merchant_name,
                                                     csl_panno_last4digit,
                                                     csl_prod_code,
                                                     csl_card_type,
                                                     csl_acct_type,
                                                     csl_time_stamp)
                          VALUES (l_hash_pan,
                                  l_fee_opening_bal,
                                  l_total_fee,
                                  'DR',
                                  l_tran_date,
                                  l_fee_opening_bal - l_total_fee,
                                  l_fee_desc,
                                  p_inst_code_in,
                                  l_encr_pan,
                                  p_rrn_in,
                                  p_auth_id_out,
                                  p_business_date_in,
                                  p_business_time_in,
                                  'Y',
                                  p_delivery_channel_in,
                                  p_txn_code_in,
                                  l_acct_number,
                                  1,
                                  SYSDATE,
                                  p_merchant_name_in,
                                  SUBSTR (p_card_no_in, -4),
                                  l_prod_code,
                                  l_card_type,
                                  l_acct_type,
                                  l_time_stamp);
                  END IF;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Problem while inserting into statement log for tran fee- '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            INSERT INTO cms_preauth_trans_hist (cph_card_no,
                                                cph_mbr_no,
                                                cph_inst_code,
                                                cph_card_no_encr,
                                                cph_preauth_validflag,
                                                cph_completion_flag,
                                                cph_txn_amnt,
                                                cph_approve_amt,
                                                cph_rrn,
                                                cph_txn_date,
                                                cph_txn_time,
                                                cph_orgnl_rrn,
                                                cph_orgnl_txn_date,
                                                cph_orgnl_txn_time,
                                                cph_orgnl_card_no,
                                                cph_terminalid,
                                                cph_orgnl_terminalid,
                                                cph_comp_count,
                                                cph_transaction_flag,
                                                cph_totalhold_amt,
                                                cph_acct_no,
                                                cph_orgnl_mcccode,
                                                cph_match_rrn,
                                                cph_delivery_channel,
                                                cph_tran_code,
                                                cph_panno_last4digit,
                                                cph_completion_fee,
                                                cph_preauth_type)
                 VALUES (
                           l_hash_pan,
                           l_mbr_numb,
                           p_inst_code_in,
                           l_encr_pan,
                           'N',
                           'C',
                           l_tran_amt,
                           TRIM (
                              TO_CHAR (NVL (l_tran_amt, 0),
                                       '999999999999999990.99')),
                           p_rrn_in,
                           p_business_date_in,
                           p_business_time_in,
                           l_cpt_rrn,
                           l_orgnl_business_date,
                           l_orgnl_business_time,
                           l_hash_pan,
                           p_term_id_in,
                           p_term_id_in,
                           0,
                           'C',
                           '0.00',
                           l_acct_number,
                           NULL,
                           l_cpt_rrn,
                           p_delivery_channel_in,
                           p_txn_code_in,
                           SUBSTR (p_card_no_in, -4),
                           l_total_fee,
                           l_preauth_type);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Problem occured while inserting into preauth hist '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;

         IF l_lock_found = 'N'
         THEN
            BEGIN
               INSERT INTO cms_preauth_transaction (cpt_card_no,
                                                    cpt_txn_amnt,
                                                    cpt_expiry_date,
                                                    cpt_sequence_no,
                                                    cpt_preauth_validflag,
                                                    cpt_inst_code,
                                                    cpt_mbr_no,
                                                    cpt_card_no_encr,
                                                    cpt_completion_flag,
                                                    cpt_approve_amt,
                                                    cpt_rrn,
                                                    cpt_txn_date,
                                                    cpt_txn_time,
                                                    cpt_terminalid,
                                                    cpt_expiry_flag,
                                                    cpt_totalhold_amt,
                                                    cpt_transaction_flag,
                                                    cpt_acct_no,
                                                    cpt_completion_fee,
                                                    cpt_preauth_type,
                                                    cpt_store_id)
                    VALUES (
                              l_hash_pan,
                              l_tran_amt,
                              NULL,
                              p_rrn_in,
                              'N',
                              p_inst_code_in,
                              l_mbr_numb,
                              l_encr_pan,
                              'Y',
                              TRIM (
                                 TO_CHAR (NVL (l_tran_amt, 0),
                                          '999999999999999990.99')),
                              p_rrn_in,
                              p_business_date_in,
                              p_business_time_in,
                              p_term_id_in,
                              'Y',
                              '0.00',
                              'C',
                              l_acct_number,
                              l_total_fee,
                              l_preauth_type,
                              p_store_id_in);
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                     'Problem occured while inserting into preauth txn '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE exp_reject_record;
            END;
         ELSE
            BEGIN
               UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION								--Added for VMS-5739/FSP-991
                  SET cpt_totalhold_amt = '0.00',
                      cpt_transaction_flag = 'C',
                      cpt_preauth_validflag = 'N',
                      cpt_completion_flag = 'Y',
                      cpt_txn_amnt = l_tran_amt,
                      cpt_transaction_rrn = p_rrn_in,
                      cpt_match_rule = l_match_rule,
                      cpt_completion_fee = '0.00'
                WHERE ROWID = l_rowid AND cpt_preauth_validflag <> 'N';
				
				IF SQL%ROWCOUNT = 0 THEN
				UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST								--Added for VMS-5739/FSP-991
                  SET cpt_totalhold_amt = '0.00',
                      cpt_transaction_flag = 'C',
                      cpt_preauth_validflag = 'N',
                      cpt_completion_flag = 'Y',
                      cpt_txn_amnt = l_tran_amt,
                      cpt_transaction_rrn = p_rrn_in,
                      cpt_match_rule = l_match_rule,
                      cpt_completion_fee = '0.00'
                WHERE ROWID = l_rowid AND cpt_preauth_validflag <> 'N';

               IF SQL%ROWCOUNT = 0
               THEN
                  l_err_msg := 'Lock transaction not updated';
                  l_resp_cde := '21';
                  RAISE exp_reject_record;
               END IF;
		   END IF;	   
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                     'Problem occured while updating lock transaction- '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE exp_reject_record;
            END;
         END IF;

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

         --SN : Get b24 responsse code from response master
         l_resp_cde := '1';

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE     cms_inst_code = p_inst_code_in
                   AND cms_delivery_channel = p_delivery_channel_in
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
               RAISE exp_reject_record;
         END;

         --EN : Get b24 responsse code from response master

         --SN : Set out parameters
         p_autherized_amount_out :=
            TO_CHAR (l_tran_amt, '99999999999999990.99');
         p_resp_msg_out := 'OK';
      --EN : Set out parameters
      EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;

            --SN : Set out parameters
            BEGIN
               p_auth_id_out := 0;
               p_autherized_amount_out := '0.00';
               p_resp_msg_out := l_err_msg;

               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_inst_code_in
                      AND cms_delivery_channel = p_delivery_channel_in
                      AND cms_response_id = TO_NUMBER (l_resp_cde);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg_out :=
                        'Problem while selecting data from response master '
                     || l_resp_cde
                     || ' is-'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code_out := '89';
            END;
         --EN : Set out parameters
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_err_msg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            l_resp_cde := '89';

            --SN : Set out parameters
            BEGIN
               p_auth_id_out := 0;
               p_autherized_amount_out := '0.00';
               p_resp_msg_out := l_err_msg;

               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_inst_code_in
                      AND cms_delivery_channel = p_delivery_channel_in
                      AND cms_response_id = TO_NUMBER (l_resp_cde);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg_out :=
                        'Problem while selecting data from response master '
                     || l_resp_cde
                     || ' is-'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code_out := '89';
            END;
      --EN : Set out parameters
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_desc
              INTO l_dr_cr_flag, l_txn_type, l_trans_desc
              FROM cms_transaction_mast
             WHERE     ctm_inst_code = p_inst_code_in
                   AND ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

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
                   AND cap_mbr_numb = l_mbr_numb
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

      p_balance_out := TO_CHAR (l_acct_balance, '99999999999999990.99');

      --SN : Make entry in transactionlog

      BEGIN
         INSERT INTO transactionlog (msgtype,
                                     rrn,
                                     delivery_channel,
                                     terminal_id,
                                     date_time,
                                     txn_code,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     response_code,
                                     business_date,
                                     business_time,
                                     customer_card_no,
                                     topup_card_no,
                                     topup_acct_no,
                                     topup_acct_type,
                                     bank_code,
                                     total_amount,
                                     rule_indicator,
                                     rulegroupid,
                                     mccode,
                                     currencycode,
                                     addcharge,
                                     productid,
                                     categoryid,
                                     tips,
                                     decline_ruleid,
                                     atm_name_location,
                                     auth_id,
                                     trans_desc,
                                     amount,
                                     preauthamount,
                                     partialamount,
                                     mccodegroupid,
                                     currencycodegroupid,
                                     transcodegroupid,
                                     rules,
                                     preauth_date,
                                     gl_upd_flag,
                                     system_trace_audit_no,
                                     instcode,
                                     feecode,
                                     tranfee_amt,
                                     servicetax_amt,
                                     cess_amt,
                                     cr_dr_flag,
                                     tranfee_cr_acctno,
                                     tranfee_dr_acctno,
                                     tran_st_calc_flag,
                                     tran_cess_calc_flag,
                                     tran_st_cr_acctno,
                                     tran_st_dr_acctno,
                                     tran_cess_cr_acctno,
                                     tran_cess_dr_acctno,
                                     customer_card_no_encr,
                                     topup_card_no_encr,
                                     proxy_number,
                                     reversal_code,
                                     customer_acct_no,
                                     acct_balance,
                                     ledger_balance,
                                     internation_ind_response,
                                     response_id,
                                     network_id,
                                     interchange_feeamt,
                                     merchant_zip,
                                     fee_plan,
                                     pos_verification,
                                     feeattachtype,
                                     merchant_name,
                                     merchant_city,
                                     merchant_state,
                                     match_rule,
                                     add_ins_user,
                                     error_msg,
                                     cardstatus,
                                     store_id,
                                     time_stamp,
                                     acct_type,
                                     spil_prod_id,
                                     spil_fee,
                                     spil_upc,
                                     spil_merref_num,
                                     spil_req_tmzm,
                                     spil_loc_cntry,
                                     spil_loc_crcy,
                                     spil_loc_lang,
                                     spil_pos_entry,
                                     spil_pos_cond,
                                     network_settl_date)
              VALUES (
                        p_msg_typ_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_term_id_in,
                        TRUNC (SYSDATE),
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        DECODE (p_resp_code_out, '00', 'C', 'F'),
                        p_resp_code_out,
                        p_business_date_in,
                        p_business_time_in,
                        l_hash_pan,
                        NULL,
                        NULL,
                        NULL,
                        p_inst_code_in,
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt+l_fee_amt, '99999999999999990.99')),
                           p_txn_amt_in),
                        NULL,
                        NULL,
                        NULL,
                        l_currcode,
                        NULL,
                        l_prod_code,
                        l_card_type,
                        NULL,
                        NULL,
                        NULL,
                        p_auth_id_out,
                        l_trans_desc,
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999990.99')),
                           p_txn_amt_in),
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_stan_in,
                        p_inst_code_in,
                        NULL,
                        l_fee_amt,
                        NULL,
                        NULL,
                        l_dr_cr_flag,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        l_encr_pan,
                        NULL,
                        l_proxunumber,
                        p_rvsl_code_in,
                        l_acct_number,
                        l_acct_balance,
                        l_ledger_bal,
                        NULL,
                        l_resp_cde,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_merchant_name_in,
                        NULL,
                        NULL,
                        l_match_rule,
                        1,
                        p_resp_msg_out,
                        l_card_stat,
                        p_store_id_in,
                        NVL (l_time_stamp, SYSTIMESTAMP),
                        l_acct_type,
                        p_product_id_in,
                        p_fee_amt_in,
                        p_upc_in,
                        p_mercrefnum_in,
                        p_reqtimezone_in,
                        p_localcountry_in,
                        p_localcurrency_in,
                        p_loclanguage_in,
                        p_posentry_in,
                        p_poscond_in,
                        to_char(sysdate,'yyyymmdd'));
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_resp_code_out := '89';
            p_resp_msg_out :=
               'Problem while inserting data into transaction log- '
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --EN : Make entry in transactionlog

      BEGIN
         l_hashkey_id :=
            gethash (
                  p_delivery_channel_in
               || p_txn_code_in
               || p_card_no_in
               || p_rrn_in
               || TO_CHAR (NVL (l_time_stamp, SYSTIMESTAMP),
                           'YYYYMMDDHH24MISSFF5'));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            p_resp_msg_out :=
               'Error while generating haskkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      --SN : Make entry in cms_transaction_log_dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                              ctd_txn_code,
                                              ctd_txn_type,
                                              ctd_msg_type,
                                              ctd_txn_mode,
                                              ctd_business_date,
                                              ctd_business_time,
                                              ctd_customer_card_no,
                                              ctd_txn_amount,
                                              ctd_txn_curr,
                                              ctd_actual_amount,
                                              ctd_fee_amount,
                                              ctd_waiver_amount,
                                              ctd_servicetax_amount,
                                              ctd_cess_amount,
                                              ctd_bill_amount,
                                              ctd_bill_curr,
                                              ctd_process_flag,
                                              ctd_process_msg,
                                              ctd_rrn,
                                              ctd_system_trace_audit_no,
                                              ctd_inst_code,
                                              ctd_customer_card_no_encr,
                                              ctd_cust_acct_number,
                                              ctd_internation_ind_response,
                                              ctd_network_id,
                                              ctd_interchange_feeamt,
                                              ctd_merchant_zip,
                                              ctd_hashkey_id,
                                              ctd_ins_user,
                                              ctd_ins_date,
                                              ctd_completion_fee,
                                              ctd_complfee_increment_type,
                                              ctd_compfee_code,
                                              ctd_compfeeattach_type,
                                              ctd_compfeeplan_id,
                                              ctd_store_address1,
                                              ctd_store_address2,
                                              ctd_store_city,
                                              ctd_store_state,
                                              ctd_store_zip)
              VALUES (
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_msg_typ_in,
                        p_txn_mode_in,
                        p_business_date_in,
                        p_business_time_in,
                        l_hash_pan,
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999999.99')),
                           p_txn_amt_in),
                        l_currcode,
                        TO_CHAR (NVL (p_txn_amt_in, 0), '99999999999990.99'),
                        l_fee_amt,
                        NULL,
                        NULL,
                        NULL,
                        NVL (
                           TRIM (
                              TO_CHAR (l_tran_amt, '99999999999999999.99')),
                           p_txn_amt_in),
                        l_card_curr,
                        DECODE (p_resp_code_out, '00', 'Y', 'E'),
                        DECODE (p_resp_code_out,
                                '00', 'Successful',
                                p_resp_msg_out),
                        p_rrn_in,
                        p_stan_in,
                        p_inst_code_in,
                        l_encr_pan,
                        l_acct_number,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        l_hashkey_id,
                        1,
                        SYSDATE,
                        l_comp_total_fee,
                        NULL,
                        l_fee_code,
                        l_feeattach_type,
                        l_fee_plan,
                        p_address1_in,
                        p_address2_in,
                        p_city_in,
                        p_state_in,
                        p_zip_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  dtl-'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
            ROLLBACK;
      END;

      --EN : Make entry in cms_transaction_log_dtl
      IF p_resp_msg_out = 'OK'
      THEN
         p_resp_msg_out := 'Success';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '89';
         p_resp_msg_out := 'Main Excp- ' || SUBSTR (SQLERRM, 1, 300);
   END redemption_unlock;

   PROCEDURE spil_authorize_txn_cms_auth (
      p_inst_code           IN     NUMBER,
      p_msg                 IN     VARCHAR2,
      p_rrn                        VARCHAR2,
      p_delivery_channel           VARCHAR2,
      p_term_id                    VARCHAR2,
      p_txn_code                   VARCHAR2,
      p_txn_mode                   VARCHAR2,
      p_tran_date                  VARCHAR2,
      p_tran_time                  VARCHAR2,
      p_card_no                    VARCHAR2,
      p_txn_amt                    NUMBER,
      p_merchant_name              VARCHAR2,
      p_merchant_city              VARCHAR2,
      p_mcc_code                   VARCHAR2,
      p_curr_code                  VARCHAR2,
      p_tip_amt                    VARCHAR2,
      p_atmname_loc                VARCHAR2,
      p_mcccode_groupid            VARCHAR2,
      p_currcode_groupid           VARCHAR2,
      p_transcode_groupid          VARCHAR2,
      p_rules                      VARCHAR2,
      p_preauth_date               DATE,
      p_expry_date          IN     VARCHAR2,
      p_stan                IN     VARCHAR2,
      p_mbr_numb            IN     VARCHAR2,
      p_rvsl_code           IN     VARCHAR2,
      p_curr_convert_amnt   IN     VARCHAR2,
      p_partital_amt           OUT VARCHAR2,
      p_auth_id                OUT VARCHAR2,
      p_resp_code              OUT VARCHAR2,
      p_resp_msg               OUT VARCHAR2,
      p_capture_date           OUT DATE)
   IS
      v_err_msg                VARCHAR2 (900) := 'OK';
      v_acct_balance           NUMBER;
      v_tran_amt               NUMBER := 0;
      v_auth_id                transactionlog.auth_id%TYPE;
      v_total_amt              NUMBER;
      v_tran_date              DATE;
      v_func_code              cms_func_mast.cfm_func_code%TYPE;
      v_prod_code              cms_prod_mast.cpm_prod_code%TYPE;
      v_prod_cattype           cms_prod_cattype.cpc_card_type%TYPE;
      v_default_partial_indr   cms_prod_cattype.cpc_default_partial_indr%TYPE;
      v_fee_amt                NUMBER;
      v_total_fee              NUMBER;
      v_upd_amt                NUMBER;
      v_narration              VARCHAR2 (300);
      v_fee_opening_bal        NUMBER;
      v_resp_cde               VARCHAR2 (3);
      v_expry_date             DATE;
      v_dr_cr_flag             VARCHAR2 (2);
      v_output_type            VARCHAR2 (2);
      v_applpan_cardstat       cms_appl_pan.cap_card_stat%TYPE;
      v_precheck_flag          NUMBER;
      v_preauth_flag           NUMBER;
      v_savepoint              NUMBER := 0;
      v_tran_fee               NUMBER;
      v_error                  VARCHAR2 (500);
      v_business_date          DATE;
      v_business_time          VARCHAR2 (5);
      v_cutoff_time            VARCHAR2 (5);
      v_card_curr              VARCHAR2 (5);
      v_fee_code               cms_fee_mast.cfm_fee_code%TYPE;
      v_fee_crgl_catg          cms_prodcattype_fees.cpf_crgl_catg%TYPE;
      v_fee_crgl_code          cms_prodcattype_fees.cpf_crgl_code%TYPE;
      v_fee_crsubgl_code       cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
      v_fee_cracct_no          cms_prodcattype_fees.cpf_cracct_no%TYPE;
      v_fee_drgl_catg          cms_prodcattype_fees.cpf_drgl_catg%TYPE;
      v_fee_drgl_code          cms_prodcattype_fees.cpf_drgl_code%TYPE;
      v_fee_drsubgl_code       cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
      v_fee_dracct_no          cms_prodcattype_fees.cpf_dracct_no%TYPE;
      v_servicetax_percent     cms_inst_param.cip_param_value%TYPE;
      v_cess_percent           cms_inst_param.cip_param_value%TYPE;
      v_servicetax_amount      NUMBER;
      v_cess_amount            NUMBER;
      v_st_calc_flag           cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
      v_cess_calc_flag         cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
      v_st_cracct_no           cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
      v_st_dracct_no           cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
      v_cess_cracct_no         cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
      v_cess_dracct_no         cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
      v_waiv_percnt            cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
      v_err_waiv               VARCHAR2 (300);
      v_log_actual_fee         NUMBER;
      v_log_waiver_amt         NUMBER;
      v_auth_savepoint         NUMBER DEFAULT 0;
      v_actual_exprydate       DATE;
      v_txn_type               NUMBER (1);
      --v_mini_totrec          NUMBER (2);
      --v_ministmt_errmsg      VARCHAR2 (500);
      --v_ministmt_output      VARCHAR2 (900);
      v_fee_attach_type        VARCHAR2 (1);
      exp_reject_record        EXCEPTION;
      v_ledger_bal             NUMBER;
      v_card_acct_no           VARCHAR2 (20);
      v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
      v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
      v_max_card_bal           NUMBER;
      v_min_act_amt            NUMBER;
      v_curr_date              DATE;
      v_upd_ledger_bal         NUMBER;
      v_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
      v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
      v_trans_desc             VARCHAR2 (50);
      v_status_chk             NUMBER;
      v_toacct_no              cms_statements_log.csl_to_acctno%TYPE;
      v_login_txn              cms_transaction_mast.ctm_login_txn%TYPE;
      v_internation_ind        cms_fee_mast.cfm_intl_indicator%TYPE;
      v_pos_verfication        cms_fee_mast.cfm_pin_sign%TYPE;
      v_feeamnt_type           cms_fee_mast.cfm_feeamnt_type%TYPE;
      v_per_fees               cms_fee_mast.cfm_per_fees%TYPE;
      v_flat_fees              cms_fee_mast.cfm_fee_amt%TYPE;
      v_clawback               cms_fee_mast.cfm_clawback_flag%TYPE;
      v_fee_plan               cms_fee_feeplan.cff_fee_plan%TYPE;
      v_clawback_amnt          cms_fee_mast.cfm_fee_amt%TYPE;
      v_actual_fee_amnt        NUMBER;
      v_clawback_count         NUMBER;
      v_freetxn_exceed         VARCHAR2 (1);
      v_duration               VARCHAR2 (20);
      v_feeattach_type         VARCHAR2 (2);
      v_cam_type_code          cms_acct_mast.cam_type_code%TYPE;
      v_timestamp              TIMESTAMP;
      v_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      v_fee_desc               cms_fee_mast.cfm_fee_desc%TYPE;
      v_rrn_count              NUMBER;
      v_tot_clwbck_count       cms_fee_mast.cfm_clawback_count%TYPE;
      v_chrg_dtl_cnt           NUMBER;
      v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
         l_enable_flag                VARCHAR2 (20)                          := 'Y';
   l_initialload_amt         cms_acct_mast.cam_new_initialload_amt%type;
   l_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   l_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
     l_cnt       number;
	 
v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
	 
   BEGIN
      SAVEPOINT v_auth_savepoint;
      v_resp_cde := '1';
      p_resp_msg := 'OK';
      v_tran_amt := NVL (p_curr_convert_amnt, 0);
      v_timestamp := SYSTIMESTAMP;

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

         -- Start Generate HashKEY value for FSS-1144
         BEGIN
            v_hashkey_id :=
               gethash (
                     p_delivery_channel
                  || p_txn_code
                  || p_card_no
                  || p_rrn
                  || TO_CHAR (v_timestamp, 'YYYYMMDDHH24MISSFF5'));
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while converting master data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --End Generate HashKEY value for FSS-1144

         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   ctm_output_type,
                   TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
                   ctm_tran_desc,
                   ctm_login_txn
              INTO v_dr_cr_flag,
                   v_output_type,
                   v_txn_type,
                   v_trans_desc,
                   v_login_txn
              FROM cms_transaction_mast
             WHERE     ctm_tran_code = p_txn_code
                   AND ctm_delivery_channel = p_delivery_channel
                   AND ctm_inst_code = p_inst_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Transflag  not defined for txn code '
                  || p_txn_code
                  || ' and delivery channel '
                  || p_delivery_channel;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                  'Error while selecting transflag '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En find debit and credit flag

         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO v_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         --En generate auth id

         --Sn check txn currency
         BEGIN
            IF TRIM (p_curr_code) IS NULL
            THEN
               v_resp_cde := '21';
               v_err_msg := 'Transaction currency  cannot be null ';
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
                  'Error while selecting Transcurrency  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En check txn currency

         --Sn get date
         BEGIN
            v_tran_date :=
               TO_DATE (
                     SUBSTR (TRIM (p_tran_date), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_tran_time), 1, 10),
                  'yyyymmdd hh24:mi:ss');
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                  'Problem while converting transaction date '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En get date
         --Sn find service tax
         BEGIN
            SELECT cip_param_value
              INTO v_servicetax_percent
              FROM cms_inst_param
             WHERE cip_param_key = 'SERVICETAX'
                   AND cip_inst_code = p_inst_code;
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

         --Sn select authorization processe flag
         BEGIN
            SELECT ptp_param_value
              INTO v_precheck_flag
              FROM pcms_tranauth_param
             WHERE ptp_param_name = 'PRE CHECK'
                   AND ptp_inst_code = p_inst_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';                    --only for master setups
               v_err_msg :=
                  'Master set up is not done for Authorization Process';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';                    --only for master setups
               v_err_msg :=
                  'Error while selecting precheck flag'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En select authorization process    flag
         --Sn select authorization processe flag
         BEGIN
            SELECT ptp_param_value
              INTO v_preauth_flag
              FROM pcms_tranauth_param
             WHERE ptp_param_name = 'PRE AUTH'
                   AND ptp_inst_code = p_inst_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';                    --only for master setups
               v_err_msg :=
                  'Master set up is not done for Authorization Process';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';                    --only for master setups
               v_err_msg :=
                  'Error while selecting preauth flag'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En select authorization process    flag
         --Sn find card detail
         BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   TO_CHAR (cap_expry_date, 'DD-MON-YY'),
                   cap_card_stat,
                   cap_proxy_number,
                   cap_acct_no
              INTO v_prod_code,
                   v_prod_cattype,
                   v_expry_date,
                   v_applpan_cardstat,
                   v_proxunumber,
                   v_acct_number
              FROM cms_appl_pan
             WHERE     cap_inst_code = p_inst_code
                   AND cap_pan_code = v_hash_pan
                   AND cap_mbr_numb = p_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '16';
               v_err_msg := 'Card number not found ' || v_hash_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '12';
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
                                 NULL,
                                 NULL,
                                 p_mcc_code,
                                 v_resp_cde,
                                 v_err_msg,
                                 '1');         
                
            IF ( (v_resp_cde <> '1' AND v_err_msg <> 'OK')
                OR (v_resp_cde <> '0' AND v_err_msg <> 'OK'))
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
            IF p_delivery_channel <> '11'
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
                           'ERROR IN EXPIRY DATE CHECK : Tran Date - '
                        || p_tran_date
                        || ', Expiry Date - '
                        || v_expry_date
                        || ','
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END IF;

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
                                   NULL,
                                   NULL,
                                   v_resp_cde,
                                   v_err_msg);

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
         END IF;

         --En check for Precheck
         --Sn check for Preauth
         IF v_preauth_flag = 1
         THEN
            BEGIN
               sp_preauthorize_txn (p_card_no,
                                    p_mcc_code,
                                    p_curr_code,
                                    v_tran_date,
                                    p_txn_code,
                                    p_inst_code,
                                    p_tran_date,
                                    p_txn_amt,
                                    p_delivery_channel,
                                    v_resp_cde,
                                    v_err_msg);

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
                     'Error from pre_auth process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

         --En check for preauth

         --Get the card no
         BEGIN
            SELECT cam_acct_bal,
                   cam_ledger_bal,
                   cam_acct_no,
                   cam_type_code,
                   nvl(cam_new_initialload_amt,cam_initialload_amt)
              INTO v_acct_balance,
                   v_ledger_bal,
                   v_card_acct_no,
                   v_cam_type_code,
                   l_initialload_amt
              FROM cms_acct_mast
             WHERE cam_acct_no = v_acct_number
                   AND cam_inst_code = p_inst_code
            FOR UPDATE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '14';                    --Ineligible Transaction
               v_err_msg := 'Invalid Card ';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '12';
               v_err_msg :=
                  'Error while selecting data from card Master for card number ';
               RAISE exp_reject_record;
         END;

         v_timestamp := SYSTIMESTAMP;

         BEGIN
            v_hashkey_id :=
               gethash (
                     p_delivery_channel
                  || p_txn_code
                  || p_card_no
                  || p_rrn
                  || TO_CHAR (v_timestamp, 'YYYYMMDDHH24MISSFF5'));
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while converting master data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --         BEGIN
         --            sp_dup_rrn_check (v_hash_pan,
         --                              p_rrn,
         --                              p_tran_date,
         --                              p_delivery_channel,
         --                              p_msg,
         --                              p_txn_code,
         --                              v_err_msg);
         --
         --            IF v_err_msg <> 'OK'
         --            THEN
         --               v_resp_cde := '22';
         --               RAISE exp_reject_record;
         --            END IF;
         --         EXCEPTION
         --            WHEN exp_reject_record
         --            THEN
         --               RAISE;
         --            WHEN OTHERS
         --            THEN
         --               v_resp_cde := '22';
         --               v_err_msg :=
         --                  'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
         --               RAISE exp_reject_record;
         --         END;


         ---Sn dynamic fee calculation .
         BEGIN
            sp_tran_fees_cmsauth (p_inst_code,
                                  p_card_no,
                                  p_delivery_channel,
                                  v_txn_type,
                                  p_txn_mode,
                                  p_txn_code,
                                  p_curr_code,
                                  NULL,
                                  NULL,
                                  v_tran_amt,
                                  v_tran_date,
                                  v_internation_ind,
                                  v_pos_verfication,
                                  v_resp_cde,
                                  p_msg,
                                  p_rvsl_code,
                                  p_mcc_code,
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
                                  v_feeamnt_type,
                                  v_clawback,
                                  v_fee_plan,
                                  v_per_fees,
                                  v_flat_fees,
                                  v_freetxn_exceed,
                                  v_duration,
                                  v_feeattach_type,
                                  v_fee_desc);

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
                                 v_fee_plan,
                                 v_tran_date,
                                 v_waiv_percnt,
                                 v_err_waiv);

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
                  'Error from waiver calc process '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En calculate waiver on the fee

         --Sn apply waiver on fee amount
         v_log_actual_fee := v_fee_amt;
         v_fee_amt :=
            ROUND (v_fee_amt - ( (v_fee_amt * v_waiv_percnt) / 100), 2);
         v_log_waiver_amt := v_log_actual_fee - v_fee_amt;

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
         BEGIN
            SELECT cpc_profile_code, NVL (cpc_default_partial_indr, 'N'),
            cpc_badcredit_flag,CPC_BADCREDIT_TRANSGRPID
              INTO v_profile_code, v_default_partial_indr,
              l_badcredit_flag,l_badcredit_transgrpid
              FROM cms_prod_cattype
             WHERE     cpc_inst_code = p_inst_code
                   AND cpc_prod_code = v_prod_code
                   AND cpc_card_type = v_prod_cattype;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Profile code not defined for product code '
                  || v_prod_code
                  || 'card type '
                  || v_prod_cattype
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         IF v_total_fee >= v_acct_balance
         THEN
            v_resp_cde := '15';
            v_err_msg := 'Insufficient Balance ';
            RAISE exp_reject_record;
         ELSIF v_tran_amt + v_total_fee > v_acct_balance
         THEN
            IF v_default_partial_indr = 'Y'
            THEN
               v_tran_amt := v_acct_balance - v_total_fee;
            ELSE
               v_resp_cde := '15';
               v_err_msg := 'Insufficient Balance ';
               RAISE exp_reject_record;
            END IF;
         END IF;

         p_partital_amt := v_tran_amt;

         IF (p_txn_code IN ('26', '25') AND p_delivery_channel = '08')
         THEN
            BEGIN
               SELECT TO_NUMBER (cbp_param_value)
                 INTO v_min_act_amt
                 FROM cms_bin_param
                WHERE     cbp_inst_code = p_inst_code
                      AND cbp_param_name = 'Min Card Balance'
                      AND cbp_profile_code = v_profile_code;

               IF v_tran_amt < v_min_act_amt
               THEN
                  v_resp_cde := '39';
                  v_err_msg :=
                        'Amount should be = or > than '
                     || v_min_act_amt
                     || ' for Card Activation';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '39';
                  v_err_msg :=
                        'Amount should be = or > than '
                     || v_min_act_amt
                     || ' for Card Activation ';
                  RAISE exp_reject_record;
            END;
         END IF;

         IF (p_delivery_channel = '08' AND p_txn_code IN ('21', '23', '25'))
         THEN
            v_dr_cr_flag := 'CR';
            v_txn_type := '1';
         END IF;

         --Sn find total transaction amount
         IF v_dr_cr_flag = 'CR'
         THEN
            v_total_amt := v_tran_amt - v_total_fee;
            v_upd_amt := v_acct_balance + v_total_amt;
            v_upd_ledger_bal := v_ledger_bal + v_total_amt;
         ELSIF v_dr_cr_flag = 'DR'
         THEN
            v_total_amt := v_tran_amt + v_total_fee;
            v_upd_amt := v_acct_balance - v_total_amt;
            v_upd_ledger_bal := v_ledger_bal - v_total_amt;
         ELSIF v_dr_cr_flag = 'NA'
         THEN
            v_total_amt := v_total_fee;
            v_upd_amt := v_acct_balance - v_total_amt;
            v_upd_ledger_bal := v_ledger_bal - v_total_amt;
         ELSE
            v_resp_cde := '12';
            v_err_msg := 'Invalid transflag    txn code ' || p_txn_code;
            RAISE exp_reject_record;
         END IF;

         --En find total transaction    amout

         IF (v_dr_cr_flag = 'CR' AND p_rvsl_code = '00')
            OR (v_dr_cr_flag = 'DR' AND p_rvsl_code <> '00')
         THEN
            BEGIN
               SELECT TO_NUMBER (cbp_param_value)
                 INTO v_max_card_bal
                 FROM cms_bin_param
                WHERE     cbp_inst_code = p_inst_code
                      AND cbp_param_name = 'Max Card Balance'
                      AND cbp_profile_code = v_profile_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg := SQLERRM;
                  RAISE exp_reject_record;
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
                              || p_delivery_channel
                              || ':'
                              || p_txn_code
                              || '%'')'
                         INTO l_cnt;

            IF l_cnt = 1
            THEN
               l_enable_flag := 'N';

               IF    ((v_upd_amt) > l_initialload_amt
                     )                                     --initialloadamount
                  OR ((v_upd_ledger_bal) > l_initialload_amt
                     )
               THEN                                        --initialloadamount
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = p_inst_code
                     AND cap_pan_code = v_hash_pan;

                 BEGIN
       sp_log_cardstat_chnge (p_inst_code,
                              v_hash_pan,
                              v_encr_pan,
                              v_auth_id,
                              '10',
                              p_rrn,
                              p_tran_date,
                              p_tran_time,
                              v_resp_cde,
                              v_err_msg
                             );

       IF v_resp_cde <> '00' AND v_err_msg <> 'OK'
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
                'Error while logging system initiated card status change '
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
               END IF;
            END IF;
         END IF;

         IF l_enable_flag = 'Y'
         THEN
            IF    ((v_upd_amt) > v_max_card_bal)
               OR ((v_upd_ledger_bal) > v_max_card_bal)
            THEN
               v_resp_cde := '30';
               v_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
               RAISE exp_reject_record;
            END IF;
         END IF;
        
            --Sn check balance
--            IF (v_upd_ledger_bal > v_max_card_bal)
--               OR (v_upd_amt > v_max_card_bal)
--            THEN
--               v_resp_cde := '30';
--               v_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
--               RAISE exp_reject_record;
--            END IF;
         END IF;

         IF (p_delivery_channel = '08' AND p_txn_code IN ('21', '23', '25'))
            OR (p_delivery_channel = '11' AND p_txn_code IN ('23', '33'))
         THEN
            v_dr_cr_flag := 'NA';
            v_txn_type := '0';
         END IF;

         --Sn check balance
         IF (v_dr_cr_flag NOT IN ('NA', 'CR') OR (v_total_fee <> 0))
         THEN
            IF v_upd_amt < 0
            THEN
               --Sn IVR ClawBack amount updation
               IF v_login_txn = 'Y' AND v_clawback = 'Y'
               THEN
                  v_actual_fee_amnt := v_total_fee;

                  IF (v_acct_balance > 0)
                  THEN
                     v_clawback_amnt := v_total_fee - v_acct_balance;
                     v_fee_amt := v_acct_balance;
                  ELSE
                     v_clawback_amnt := v_total_fee;
                     v_fee_amt := 0;
                  END IF;

                  IF v_clawback_amnt > 0
                  THEN
                     BEGIN
                        SELECT cfm_clawback_count
                          INTO v_tot_clwbck_count
                          FROM cms_fee_mast
                         WHERE cfm_fee_code = v_fee_code;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_resp_cde := '12';
                           v_err_msg :=
                              'Clawback count not configured '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     BEGIN
                        SELECT COUNT (*)
                          INTO v_chrg_dtl_cnt
                          FROM cms_charge_dtl
                         WHERE     ccd_inst_code = p_inst_code
                               AND ccd_delivery_channel = p_delivery_channel
                               AND ccd_txn_code = p_txn_code
                               AND ccd_acct_no = v_card_acct_no
                               AND ccd_fee_code = v_fee_code
                               AND ccd_clawback = 'Y';
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_cde := '21';
                           v_err_msg :=
                              'Error occured while fetching count from cms_charge_dtl'
                              || SUBSTR (SQLERRM, 1, 100);
                           RAISE exp_reject_record;
                     END;

                     --Sn Clawback Details
                     BEGIN
                        SELECT COUNT (*)
                          INTO v_clawback_count
                          FROM cms_acctclawback_dtl
                         WHERE     cad_inst_code = p_inst_code
                               AND cad_delivery_channel = p_delivery_channel
                               AND cad_txn_code = p_txn_code
                               AND cad_pan_code = v_hash_pan
                               AND cad_acct_no = v_card_acct_no;

                        IF v_clawback_count = 0
                        THEN
                           INSERT
                             INTO cms_acctclawback_dtl (cad_inst_code,
                                                        cad_acct_no,
                                                        cad_pan_code,
                                                        cad_pan_code_encr,
                                                        cad_clawback_amnt,
                                                        cad_recovery_flag,
                                                        cad_ins_date,
                                                        cad_lupd_date,
                                                        cad_delivery_channel,
                                                        cad_txn_code,
                                                        cad_ins_user,
                                                        cad_lupd_user)
                           VALUES (p_inst_code,
                                   v_card_acct_no,
                                   v_hash_pan,
                                   v_encr_pan,
                                   ROUND (v_clawback_amnt, 2),
                                   'N',
                                   SYSDATE,
                                   SYSDATE,
                                   p_delivery_channel,
                                   p_txn_code,
                                   '1',
                                   '1');
                        ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count
                        THEN
                           UPDATE cms_acctclawback_dtl
                              SET cad_clawback_amnt =
                                     ROUND (
                                        cad_clawback_amnt + v_clawback_amnt,
                                        2),
                                  cad_recovery_flag = 'N',
                                  cad_lupd_date = SYSDATE
                            WHERE     cad_inst_code = p_inst_code
                                  AND cad_acct_no = v_card_acct_no
                                  AND cad_pan_code = v_hash_pan
                                  AND cad_delivery_channel =
                                         p_delivery_channel
                                  AND cad_txn_code = p_txn_code;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_cde := '21';
                           v_err_msg :=
                              'Error while inserting Account ClawBack details'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;
                  --En Clawback Details
                  END IF;
               ELSE
                  v_resp_cde := '15';
                  v_err_msg := 'Insufficient Balance ';
                  RAISE exp_reject_record;
               END IF;

               v_upd_amt := 0;
               v_upd_ledger_bal := 0;
               v_total_amt := v_tran_amt + v_fee_amt;
            END IF;
         END IF;

         --Sn create gl entries and acct update
         BEGIN
            sp_upd_transaction_accnt_auth (p_inst_code,
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
                                           '',
                                           p_msg,
                                           v_resp_cde,
                                           v_err_msg);

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
                  'Error from currency conversion '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En create gl entries and acct update

         IF TRIM (v_trans_desc) IS NOT NULL
         THEN
            v_narration := v_trans_desc || '/';
         END IF;

         IF TRIM (p_merchant_name) IS NOT NULL
         THEN
            v_narration := v_narration || p_merchant_name || '/';
         END IF;

         IF TRIM (p_merchant_city) IS NOT NULL
         THEN
            v_narration := v_narration || p_merchant_city || '/';
         END IF;

         IF TRIM (p_tran_date) IS NOT NULL
         THEN
            v_narration := v_narration || p_tran_date || '/';
         END IF;

         IF TRIM (v_auth_id) IS NOT NULL
         THEN
            v_narration := v_narration || v_auth_id;
         END IF;

         --Sn create a entry in statement log
         IF v_dr_cr_flag <> 'NA'
         THEN
            BEGIN
               IF (p_delivery_channel = '10' AND p_txn_code = '18')
                  AND v_tran_amt = 0
               THEN
                  NULL;
               ELSIF v_tran_amt <> 0
               THEN
                  INSERT INTO cms_statements_log (csl_pan_no,
                                                  csl_opening_bal,
                                                  csl_trans_amount,
                                                  csl_trans_type,
                                                  csl_trans_date,
                                                  csl_closing_balance,
                                                  csl_trans_narrration,
                                                  csl_pan_no_encr,
                                                  csl_rrn,
                                                  csl_auth_id,
                                                  csl_business_date,
                                                  csl_business_time,
                                                  txn_fee_flag,
                                                  csl_delivery_channel,
                                                  csl_inst_code,
                                                  csl_txn_code,
                                                  csl_ins_date,
                                                  csl_ins_user,
                                                  csl_acct_no,
                                                  csl_merchant_name,
                                                  csl_merchant_city,
                                                  csl_merchant_state,
                                                  csl_to_acctno,
                                                  csl_panno_last4digit,
                                                  csl_acct_type,
                                                  csl_time_stamp,
                                                  csl_prod_code,
                                                  csl_card_type)
                       VALUES (
                                 v_hash_pan,
                                 ROUND (v_ledger_bal, 2),
                                 ROUND (v_tran_amt, 2),
                                 v_dr_cr_flag,
                                 v_tran_date,
                                 ROUND (
                                    DECODE (v_dr_cr_flag,
                                            'DR', v_ledger_bal - v_tran_amt,
                                            'CR', v_ledger_bal + v_tran_amt,
                                            'NA', v_ledger_bal),
                                    2),
                                 v_narration,
                                 v_encr_pan,
                                 p_rrn,
                                 v_auth_id,
                                 p_tran_date,
                                 p_tran_time,
                                 'N',
                                 p_delivery_channel,
                                 p_inst_code,
                                 p_txn_code,
                                 SYSDATE,
                                 1,
                                 v_card_acct_no,
                                 p_merchant_name,
                                 p_merchant_city,
                                 p_atmname_loc,
                                 v_toacct_no,
                                 (SUBSTR (p_card_no,
                                          LENGTH (p_card_no) - 3,
                                          LENGTH (p_card_no))),
                                 v_cam_type_code,
                                 v_timestamp,
                                 v_prod_code,
                                 v_prod_cattype);
               END IF;
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
            BEGIN
               SELECT DECODE (v_dr_cr_flag,
                              'DR', v_ledger_bal - v_tran_amt,
                              'CR', v_ledger_bal + v_tran_amt,
                              'NA', v_ledger_bal)
                 INTO v_fee_opening_bal
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                     'Error while selecting data from card Master for card number ';

                  RAISE exp_reject_record;
            END;

            --En find fee opening balance
            IF v_freetxn_exceed = 'N'
            THEN
               BEGIN
                  INSERT INTO cms_statements_log (csl_pan_no,
                                                  csl_opening_bal,
                                                  csl_trans_amount,
                                                  csl_trans_type,
                                                  csl_trans_date,
                                                  csl_closing_balance,
                                                  csl_trans_narrration,
                                                  csl_pan_no_encr,
                                                  csl_rrn,
                                                  csl_auth_id,
                                                  csl_business_date,
                                                  csl_business_time,
                                                  txn_fee_flag,
                                                  csl_delivery_channel,
                                                  csl_inst_code,
                                                  csl_txn_code,
                                                  csl_ins_date,
                                                  csl_ins_user,
                                                  csl_acct_no,
                                                  csl_merchant_name,
                                                  csl_merchant_city,
                                                  csl_merchant_state,
                                                  csl_panno_last4digit,
                                                  csl_acct_type,
                                                  csl_time_stamp,
                                                  csl_prod_code,
                                                  csl_card_type)
                       VALUES (
                                 v_hash_pan,
                                 ROUND (v_fee_opening_bal, 2),
                                 ROUND (v_fee_amt, 2),
                                 'DR',
                                 v_tran_date,
                                 ROUND (v_fee_opening_bal - v_fee_amt, 2),
                                 v_fee_desc,
                                 v_encr_pan,
                                 p_rrn,
                                 v_auth_id,
                                 p_tran_date,
                                 p_tran_time,
                                 'Y',
                                 p_delivery_channel,
                                 p_inst_code,
                                 p_txn_code,
                                 SYSDATE,
                                 1,
                                 v_card_acct_no,
                                 p_merchant_name,
                                 p_merchant_city,
                                 p_atmname_loc,
                                 (SUBSTR (p_card_no,
                                          LENGTH (p_card_no) - 3,
                                          LENGTH (p_card_no))),
                                 v_cam_type_code,
                                 v_timestamp,
                                 v_prod_code,
                                 v_prod_cattype);
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
                  IF v_feeamnt_type = 'A' AND v_login_txn != 'Y'
                  THEN
                     v_flat_fees :=
                        ROUND (
                           v_flat_fees
                           - ( (v_flat_fees * v_waiv_percnt) / 100),
                           2);


                     v_per_fees :=
                        ROUND (
                           v_per_fees - ( (v_per_fees * v_waiv_percnt) / 100),
                           2);

                     --En Entry for Fixed Fee
                     INSERT INTO cms_statements_log (csl_pan_no,
                                                     csl_opening_bal,
                                                     csl_trans_amount,
                                                     csl_trans_type,
                                                     csl_trans_date,
                                                     csl_closing_balance,
                                                     csl_trans_narrration,
                                                     csl_inst_code,
                                                     csl_pan_no_encr,
                                                     csl_rrn,
                                                     csl_auth_id,
                                                     csl_business_date,
                                                     csl_business_time,
                                                     txn_fee_flag,
                                                     csl_delivery_channel,
                                                     csl_txn_code,
                                                     csl_acct_no,
                                                     csl_ins_user,
                                                     csl_ins_date,
                                                     csl_merchant_name,
                                                     csl_merchant_city,
                                                     csl_merchant_state,
                                                     csl_panno_last4digit,
                                                     csl_acct_type,
                                                     csl_time_stamp,
                                                     csl_prod_code,
                                                     csl_card_type)
                          VALUES (
                                    v_hash_pan,
                                    ROUND (v_fee_opening_bal, 2),
                                    ROUND (v_flat_fees, 2),
                                    'DR',
                                    v_tran_date,
                                    ROUND (v_fee_opening_bal - v_flat_fees,
                                           2),
                                    'Fixed Fee debited for ' || v_fee_desc,
                                    p_inst_code,
                                    v_encr_pan,
                                    p_rrn,
                                    v_auth_id,
                                    p_tran_date,
                                    p_tran_time,
                                    'Y',
                                    p_delivery_channel,
                                    p_txn_code,
                                    v_card_acct_no,
                                    1,
                                    SYSDATE,
                                    p_merchant_name,
                                    p_merchant_city,
                                    p_atmname_loc,
                                    (SUBSTR (p_card_no,
                                             LENGTH (p_card_no) - 3,
                                             LENGTH (p_card_no))),
                                    v_cam_type_code,
                                    v_timestamp,
                                    v_prod_code,
                                    v_prod_cattype);

                     v_fee_opening_bal := v_fee_opening_bal - v_flat_fees;

                     --Sn Entry for Percentage Fee

                     INSERT INTO cms_statements_log (csl_pan_no,
                                                     csl_opening_bal,
                                                     csl_trans_amount,
                                                     csl_trans_type,
                                                     csl_trans_date,
                                                     csl_closing_balance,
                                                     csl_trans_narrration,
                                                     csl_inst_code,
                                                     csl_pan_no_encr,
                                                     csl_rrn,
                                                     csl_auth_id,
                                                     csl_business_date,
                                                     csl_business_time,
                                                     txn_fee_flag,
                                                     csl_delivery_channel,
                                                     csl_txn_code,
                                                     csl_acct_no,
                                                     csl_ins_user,
                                                     csl_ins_date,
                                                     csl_merchant_name,
                                                     csl_merchant_city,
                                                     csl_merchant_state,
                                                     csl_panno_last4digit,
                                                     csl_acct_type,
                                                     csl_time_stamp,
                                                     csl_prod_code,
                                                     csl_card_type)
                          VALUES (
                                    v_hash_pan,
                                    ROUND (v_fee_opening_bal, 2),
                                    ROUND (v_per_fees, 2),
                                    'DR',
                                    v_tran_date,
                                    ROUND (v_fee_opening_bal - v_per_fees, 2),
                                    'Percentage Fee debited for '
                                    || v_fee_desc,
                                    p_inst_code,
                                    v_encr_pan,
                                    p_rrn,
                                    v_auth_id,
                                    p_tran_date,
                                    p_tran_time,
                                    'Y',
                                    p_delivery_channel,
                                    p_txn_code,
                                    v_card_acct_no,
                                    1,
                                    SYSDATE,
                                    p_merchant_name,
                                    p_merchant_city,
                                    p_atmname_loc,
                                    (SUBSTR (p_card_no,
                                             LENGTH (p_card_no) - 3,
                                             LENGTH (p_card_no))),
                                    v_cam_type_code,
                                    v_timestamp,
                                    v_prod_code,
                                    v_prod_cattype);
                  --En Entry for Percentage Fee

                  ELSE
                     INSERT INTO cms_statements_log (csl_pan_no,
                                                     csl_opening_bal,
                                                     csl_trans_amount,
                                                     csl_trans_type,
                                                     csl_trans_date,
                                                     csl_closing_balance,
                                                     csl_trans_narrration,
                                                     csl_pan_no_encr,
                                                     csl_rrn,
                                                     csl_auth_id,
                                                     csl_business_date,
                                                     csl_business_time,
                                                     txn_fee_flag,
                                                     csl_delivery_channel,
                                                     csl_inst_code,
                                                     csl_txn_code,
                                                     csl_ins_date,
                                                     csl_ins_user,
                                                     csl_acct_no,
                                                     csl_merchant_name,
                                                     csl_merchant_city,
                                                     csl_merchant_state,
                                                     csl_panno_last4digit,
                                                     csl_acct_type,
                                                     csl_time_stamp,
                                                     csl_prod_code,
                                                     csl_card_type)
                          VALUES (
                                    v_hash_pan,
                                    ROUND (v_fee_opening_bal, 2),
                                    ROUND (v_fee_amt, 2),
                                    'DR',
                                    v_tran_date,
                                    ROUND (v_fee_opening_bal - v_fee_amt, 2),
                                    v_fee_desc,
                                    v_encr_pan,
                                    p_rrn,
                                    v_auth_id,
                                    p_tran_date,
                                    p_tran_time,
                                    'Y',
                                    p_delivery_channel,
                                    p_inst_code,
                                    p_txn_code,
                                    SYSDATE,
                                    1,
                                    v_card_acct_no,
                                    p_merchant_name,
                                    p_merchant_city,
                                    p_atmname_loc,
                                    (SUBSTR (p_card_no,
                                             LENGTH (p_card_no) - 3,
                                             LENGTH (p_card_no))),
                                    v_cam_type_code,
                                    v_timestamp,
                                    v_prod_code,
                                    v_prod_cattype);


                     IF     v_login_txn = 'Y'
                        AND v_clawback_amnt > 0
                        AND v_chrg_dtl_cnt < v_tot_clwbck_count
                     THEN
                        BEGIN
                           INSERT INTO cms_charge_dtl (ccd_pan_code,
                                                       ccd_acct_no,
                                                       ccd_clawback_amnt,
                                                       ccd_gl_acct_no,
                                                       ccd_pan_code_encr,
                                                       ccd_rrn,
                                                       ccd_calc_date,
                                                       ccd_fee_freq,
                                                       ccd_file_status,
                                                       ccd_clawback,
                                                       ccd_inst_code,
                                                       ccd_fee_code,
                                                       ccd_calc_amt,
                                                       ccd_fee_plan,
                                                       ccd_delivery_channel,
                                                       ccd_txn_code,
                                                       ccd_debited_amnt,
                                                       ccd_mbr_numb,
                                                       ccd_process_msg,
                                                       ccd_feeattachtype)
                                VALUES (v_hash_pan,
                                        v_card_acct_no,
                                        ROUND (v_clawback_amnt, 2),
                                        v_fee_cracct_no,
                                        v_encr_pan,
                                        p_rrn,
                                        v_tran_date,
                                        'T',
                                        'C',
                                        v_clawback,
                                        p_inst_code,
                                        v_fee_code,
                                        ROUND (v_actual_fee_amnt, 2),
                                        v_fee_plan,
                                        p_delivery_channel,
                                        p_txn_code,
                                        ROUND (v_fee_amt, 2),
                                        p_mbr_numb,
                                        DECODE (v_err_msg, 'OK', 'SUCCESS'),
                                        v_feeattach_type);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_resp_cde := '21';
                              v_err_msg :=
                                 'Problem while inserting into CMS_CHARGE_DTL '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_record;
                        END;
                     END IF;
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
            INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                                 ctd_txn_code,
                                                 ctd_txn_type,
                                                 ctd_txn_mode,
                                                 ctd_business_date,
                                                 ctd_business_time,
                                                 ctd_customer_card_no,
                                                 ctd_txn_amount,
                                                 ctd_txn_curr,
                                                 ctd_actual_amount,
                                                 ctd_fee_amount,
                                                 ctd_waiver_amount,
                                                 ctd_servicetax_amount,
                                                 ctd_cess_amount,
                                                 ctd_bill_amount,
                                                 ctd_bill_curr,
                                                 ctd_process_flag,
                                                 ctd_process_msg,
                                                 ctd_rrn,
                                                 ctd_system_trace_audit_no,
                                                 ctd_customer_card_no_encr,
                                                 ctd_msg_type,
                                                 ctd_cust_acct_number,
                                                 ctd_inst_code,
                                                 ctd_hashkey_id)
                 VALUES (p_delivery_channel,
                         p_txn_code,
                         v_txn_type,
                         p_txn_mode,
                         p_tran_date,
                         p_tran_time,
                         v_hash_pan,
                         p_txn_amt,
                         p_curr_code,
                         v_tran_amt,
                         v_log_actual_fee,
                         v_log_waiver_amt,
                         v_servicetax_amount,
                         v_cess_amount,
                         v_total_amt,
                         v_card_curr,
                         'Y',
                         'Successful',
                         p_rrn,
                         p_stan,
                         v_encr_pan,
                         p_msg,
                         v_acct_number,
                         p_inst_code,
                         v_hashkey_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Problem while selecting data from response master '
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         --En create a entry for successful

         --Sn create detail for response message
         --        IF V_OUTPUT_TYPE = 'B'
         --        THEN
         --            --Balance Inquiry
         --            P_RESP_MSG := TO_CHAR (V_UPD_AMT);
         --        END IF;

         --En create detail fro response message
         --        --Sn mini statement
         --        IF V_OUTPUT_TYPE = 'M'
         --        THEN
         --            --Mini statement
         --            BEGIN
         --                SP_GEN_MINI_STMT (P_INST_CODE,
         --                                        P_CARD_NO,
         --                                        V_MINI_TOTREC,
         --                                        V_MINISTMT_OUTPUT,
         --                                        V_MINISTMT_ERRMSG);
         --
         --                IF V_MINISTMT_ERRMSG <> 'OK'
         --                THEN
         --                    V_ERR_MSG := V_MINISTMT_ERRMSG;
         --                    V_RESP_CDE := '21';
         --                    RAISE EXP_REJECT_RECORD;
         --                END IF;
         --
         --                P_RESP_MSG :=
         --                    LPAD (TO_CHAR (V_MINI_TOTREC), 2, '0') || V_MINISTMT_OUTPUT;
         --            EXCEPTION
         --                WHEN EXP_REJECT_RECORD
         --                THEN
         --                    RAISE;
         --                WHEN OTHERS
         --                THEN
         --                    V_ERR_MSG :=
         --                        'Problem while selecting data for mini statement '
         --                        || SUBSTR (SQLERRM, 1, 300);
         --                    V_RESP_CDE := '21';
         --                    RAISE EXP_REJECT_RECORD;
         --            END;
         --        END IF;

         --En mini statement
         v_resp_cde := '1';

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
                   AND cms_delivery_channel =
                          DECODE (TO_NUMBER (p_delivery_channel),
                                  17, 10,
                                  p_delivery_channel)
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

            IF v_prod_code IS NULL
            THEN
               BEGIN
                  SELECT cap_prod_code,
                         cap_card_type,
                         cap_card_stat,
                         cap_acct_no
                    INTO v_prod_code,
                         v_prod_cattype,
                         v_applpan_cardstat,
                         v_acct_number
                    FROM cms_appl_pan
                   WHERE cap_inst_code = p_inst_code
                         AND cap_pan_code = v_hash_pan;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            END IF;

            BEGIN
               SELECT cam_acct_bal,
                      cam_ledger_bal,
                      cam_acct_no,
                      cam_type_code
                 INTO v_acct_balance,
                      v_ledger_bal,
                      v_acct_number,
                      v_cam_type_code
                 FROM cms_acct_mast
                WHERE cam_acct_no = v_acct_number
                      AND cam_inst_code = p_inst_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_acct_balance := 0;
                  v_ledger_bal := 0;
            END;

            --Sn select response code and insert record into txn log dtl

            BEGIN
               SELECT cms_iso_respcde
                 INTO p_resp_code
                 FROM cms_response_mast
                WHERE cms_inst_code = p_inst_code
                      AND cms_delivery_channel =
                             DECODE (p_delivery_channel,
                                     '17', '10',
                                     p_delivery_channel)
                      AND cms_response_id = v_resp_cde;

               p_resp_msg := v_err_msg;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg :=
                        'Problem while selecting data from response master '
                     || v_resp_cde
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code := '89';
                  ROLLBACK;
            END;

            BEGIN
               INSERT
                 INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                               ctd_txn_code,
                                               ctd_txn_type,
                                               ctd_txn_mode,
                                               ctd_business_date,
                                               ctd_business_time,
                                               ctd_customer_card_no,
                                               ctd_txn_amount,
                                               ctd_txn_curr,
                                               ctd_actual_amount,
                                               ctd_fee_amount,
                                               ctd_waiver_amount,
                                               ctd_servicetax_amount,
                                               ctd_cess_amount,
                                               ctd_bill_amount,
                                               ctd_bill_curr,
                                               ctd_process_flag,
                                               ctd_process_msg,
                                               ctd_rrn,
                                               ctd_system_trace_audit_no,
                                               ctd_customer_card_no_encr,
                                               ctd_msg_type,
                                               ctd_cust_acct_number,
                                               ctd_inst_code,
                                               ctd_hashkey_id)
               VALUES (p_delivery_channel,
                       p_txn_code,
                       v_txn_type,
                       p_txn_mode,
                       p_tran_date,
                       p_tran_time,
                       v_hash_pan,
                       p_txn_amt,
                       p_curr_code,
                       v_tran_amt,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       v_total_amt,
                       v_card_curr,
                       'E',
                       v_err_msg,
                       p_rrn,
                       p_stan,
                       v_encr_pan,
                       p_msg,
                       v_acct_number,
                       p_inst_code,
                       v_hashkey_id);

               p_resp_msg := v_err_msg;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code := '99';
                  p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                     || SUBSTR (SQLERRM, 1, 300);
                  ROLLBACK;
                  RETURN;
            END;

            IF v_dr_cr_flag IS NULL
            THEN
               BEGIN
                  SELECT ctm_credit_debit_flag
                    INTO v_dr_cr_flag
                    FROM cms_transaction_mast
                   WHERE     ctm_tran_code = p_txn_code
                         AND ctm_delivery_channel = p_delivery_channel
                         AND ctm_inst_code = p_inst_code;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            END IF;
         WHEN OTHERS
         THEN
            ROLLBACK TO v_auth_savepoint;

            IF v_prod_code IS NULL
            THEN
               BEGIN
                  SELECT cap_prod_code,
                         cap_card_type,
                         cap_card_stat,
                         cap_acct_no
                    INTO v_prod_code,
                         v_prod_cattype,
                         v_applpan_cardstat,
                         v_acct_number
                    FROM cms_appl_pan
                   WHERE cap_inst_code = p_inst_code
                         AND cap_pan_code = v_hash_pan;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            END IF;

            BEGIN
               SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
                 INTO v_acct_balance, v_ledger_bal, v_cam_type_code
                 FROM cms_acct_mast
                WHERE cam_acct_no = v_acct_number
                      AND cam_inst_code = p_inst_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_acct_balance := 0;
                  v_ledger_bal := 0;
            END;

            --Sn select response code and insert record into txn log dtl

            BEGIN
               SELECT cms_iso_respcde
                 INTO p_resp_code
                 FROM cms_response_mast
                WHERE cms_inst_code = p_inst_code
                      AND cms_delivery_channel =
                             DECODE (p_delivery_channel,
                                     '17', '10',
                                     p_delivery_channel)
                      AND cms_response_id = v_resp_cde;

               p_resp_msg := v_err_msg;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg :=
                        'Problem while selecting data from response master '
                     || v_resp_cde
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code := '89';
                  ROLLBACK;
            END;

            BEGIN
               INSERT
                 INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                               ctd_txn_code,
                                               ctd_txn_type,
                                               ctd_txn_mode,
                                               ctd_business_date,
                                               ctd_business_time,
                                               ctd_customer_card_no,
                                               ctd_txn_amount,
                                               ctd_txn_curr,
                                               ctd_actual_amount,
                                               ctd_fee_amount,
                                               ctd_waiver_amount,
                                               ctd_servicetax_amount,
                                               ctd_cess_amount,
                                               ctd_bill_amount,
                                               ctd_bill_curr,
                                               ctd_process_flag,
                                               ctd_process_msg,
                                               ctd_rrn,
                                               ctd_system_trace_audit_no,
                                               ctd_customer_card_no_encr,
                                               ctd_msg_type,
                                               ctd_cust_acct_number,
                                               ctd_inst_code,
                                               ctd_hashkey_id)
               VALUES (p_delivery_channel,
                       p_txn_code,
                       v_txn_type,
                       p_txn_mode,
                       p_tran_date,
                       p_tran_time,
                       v_hash_pan,
                       p_txn_amt,
                       p_curr_code,
                       v_tran_amt,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       v_total_amt,
                       v_card_curr,
                       'E',
                       v_err_msg,
                       p_rrn,
                       p_stan,
                       v_encr_pan,
                       p_msg,
                       v_acct_number,
                       p_inst_code,
                       v_hashkey_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code := '99';
                  ROLLBACK;
                  RETURN;
            END;

            --En select response code and insert record into txn log dtl

            IF v_dr_cr_flag IS NULL
            THEN
               BEGIN
                  SELECT ctm_credit_debit_flag
                    INTO v_dr_cr_flag
                    FROM cms_transaction_mast
                   WHERE     ctm_tran_code = p_txn_code
                         AND ctm_delivery_channel = p_delivery_channel
                         AND ctm_inst_code = p_inst_code;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            END IF;
      END;


      --    IF P_TXN_CODE = '25'  AND P_DELIVERY_CHANNEL = '08'
      --    THEN
      --        V_UPD_AMT := 0;
      --        V_UPD_LEDGER_BAL := 0;
      --    END IF;

      --Sn create a entry in txn log
      BEGIN
         INSERT INTO transactionlog (msgtype,
                                     rrn,
                                     delivery_channel,
                                     terminal_id,
                                     date_time,
                                     txn_code,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     response_code,
                                     business_date,
                                     business_time,
                                     customer_card_no,
                                     topup_card_no,
                                     topup_acct_no,
                                     topup_acct_type,
                                     bank_code,
                                     total_amount,
                                     rule_indicator,
                                     rulegroupid,
                                     mccode,
                                     currencycode,
                                     addcharge,
                                     productid,
                                     categoryid,
                                     tips,
                                     decline_ruleid,
                                     atm_name_location,
                                     auth_id,
                                     trans_desc,
                                     amount,
                                     preauthamount,
                                     partialamount,
                                     mccodegroupid,
                                     currencycodegroupid,
                                     transcodegroupid,
                                     rules,
                                     preauth_date,
                                     gl_upd_flag,
                                     system_trace_audit_no,
                                     instcode,
                                     feecode,
                                     tranfee_amt,
                                     servicetax_amt,
                                     cess_amt,
                                     cr_dr_flag,
                                     tranfee_cr_acctno,
                                     tranfee_dr_acctno,
                                     tran_st_calc_flag,
                                     tran_cess_calc_flag,
                                     tran_st_cr_acctno,
                                     tran_st_dr_acctno,
                                     tran_cess_cr_acctno,
                                     tran_cess_dr_acctno,
                                     customer_card_no_encr,
                                     topup_card_no_encr,
                                     proxy_number,
                                     reversal_code,
                                     customer_acct_no,
                                     acct_balance,
                                     ledger_balance,
                                     response_id,
                                     add_ins_date,
                                     add_ins_user,
                                     cardstatus,
                                     fee_plan,
                                     csr_achactiontaken,
                                     error_msg,
                                     feeattachtype,
                                     merchant_name,
                                     merchant_city,
                                     merchant_state,
                                     acct_type,
                                     time_stamp)
              VALUES (
                        p_msg,
                        p_rrn,
                        p_delivery_channel,
                        p_term_id,
                        v_business_date,
                        p_txn_code,
                        v_txn_type,
                        p_txn_mode,
                        DECODE (p_resp_code, '00', 'C', 'F'),
                        p_resp_code,
                        p_tran_date,
                        SUBSTR (p_tran_time, 1, 10),
                        v_hash_pan,
                        NULL,
                        NULL,
                        NULL,
                        p_inst_code,
                        TRIM (
                           TO_CHAR (NVL (v_total_amt, 0),
                                    '99999999999999990.99')),
                        NULL,
                        NULL,
                        p_mcc_code,
                        p_curr_code,
                        NULL,
                        v_prod_code,
                        v_prod_cattype,
                        p_tip_amt,
                        NULL,
                        p_atmname_loc,
                        v_auth_id,
                        v_trans_desc,
                        TRIM (
                           TO_CHAR (NVL (v_tran_amt, 0),
                                    '999999999999999990.99')),
                        '0.00',
                        '0.00',
                        p_mcccode_groupid,
                        p_currcode_groupid,
                        p_transcode_groupid,
                        p_rules,
                        p_preauth_date,
                        NULL,
                        p_stan,
                        p_inst_code,
                        v_fee_code,
                        NVL (v_fee_amt, 0),
                        NVL (v_servicetax_amount, 0),
                        NVL (v_cess_amount, 0),
                        v_dr_cr_flag,
                        v_fee_cracct_no,
                        v_fee_dracct_no,
                        v_st_calc_flag,
                        v_cess_calc_flag,
                        v_st_cracct_no,
                        v_st_dracct_no,
                        v_cess_cracct_no,
                        v_cess_dracct_no,
                        v_encr_pan,
                        NULL,
                        v_proxunumber,
                        p_rvsl_code,
                        v_acct_number,
                        ROUND (
                           DECODE (p_resp_code,
                                   '00', v_upd_amt,
                                   v_acct_balance),
                           2),
                        ROUND (
                           DECODE (p_resp_code,
                                   '00', v_upd_ledger_bal,
                                   v_ledger_bal),
                           2),
                        v_resp_cde,
                        SYSDATE,
                        1,
                        v_applpan_cardstat,
                        v_fee_plan,
                        'N',
                        v_err_msg,
                        v_feeattach_type,
                        p_merchant_name,
                        p_merchant_city,
                        p_atmname_loc,
                        v_cam_type_code,
                        v_timestamp);

         p_capture_date := v_business_date;

         p_auth_id := v_auth_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_resp_code := '99';
            p_resp_msg :=
               'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;
   --En create a entry in txn log
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code := '99';
         p_resp_msg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   End Spil_Authorize_Txn_Cms_Auth;
     
    PROCEDURE lp_trans_details(p_instcode_in IN NUMBER,
                             P_Delivery_Channel_In In Varchar2,
                             p_txn_code_in IN VARCHAR2,
                             p_src_card_in IN VARCHAR2,
                             P_Rrn_In In Varchar2,
                             P_Time_Stamp_In In Timestamp,
                             P_Hashkey_Id_Out  Out Varchar2,
                             P_Dr_Cr_Flag_Out Out Varchar2,
                             P_Txn_Type_Out   Out Varchar2,
                             P_Tran_Type_Out  Out Varchar2,
                             p_prfl_flag_Out  out varchar2,
                             P_Trans_Desc_Out Out Varchar2,
                             P_Respcode_Out Out Varchar2,
                             p_errmsg_Out  out varchar2)
  is
  
  
   exp_main_reject_record  EXCEPTION;
   
 BEGIN
    p_errmsg_Out:='OK';
    Begin
	    P_Hashkey_Id_Out := gethash(p_delivery_channel_in || p_txn_code_in ||
              P_Src_Card_In || P_Rrn_In ||
              to_char(p_time_stamp_in, 'YYYYMMDDHH24MISSFF5'));
    EXCEPTION
	  WHEN OTHERS THEN
	    P_Respcode_Out := '89';
	    p_errmsg_Out        := 'ERROR WHILE CONVERTING MASTER DATA FOR SOURCE CARD ' ||
					  substr(SQLERRM, 1, 200);
	    RAISE exp_main_reject_record;
    END ;
    --En find debit and credit flag
    BEGIN

      SELECT ctm_credit_debit_flag, 
		         to_number(decode(ctm_tran_type, 'N', '0', 'F', '1')),
		         Ctm_Tran_Type, Ctm_Prfl_Flag, Ctm_Tran_Desc
	      Into P_Dr_Cr_Flag_Out, P_Txn_Type_Out, P_Tran_Type_Out,
		         p_prfl_flag_Out, p_trans_desc_Out
	      From Cms_Transaction_Mast
	     WHERE ctm_tran_code = p_txn_code_in AND
		         ctm_delivery_channel = p_delivery_channel_in AND
		         ctm_inst_code = p_instcode_in;
    EXCEPTION
	     When No_Data_Found Then
	      P_Respcode_Out := '12';
	      P_Errmsg_Out   := 'TRANSFLAG  NOT DEFINED FOR TXN CODE ' ||
            p_txn_code_in || ' AND DELIVERY CHANNEL ' ||
            p_delivery_channel_in;
	      RAISE exp_main_reject_record;
	     WHEN OTHERS THEN
        P_Respcode_Out := '89'; --ineligible transaction
        p_errmsg_Out := 'ERROR WHILE SELECTING TRANSACTION DETAILS' ||
              substr(SQLERRM, 1, 200);
        RAISE exp_main_reject_record;
    END;
 
end lp_trans_details; 
   
   PROCEDURE balance_transfer(p_instcode_in         IN NUMBER,
                 p_mbr_numb_in                  IN VARCHAR2,
                 p_msg_type_in                  IN VARCHAR2,
                 p_currcode_in                  IN VARCHAR2,
                 p_rrn_in                       IN VARCHAR2,
                 p_src_card_in                  IN VARCHAR2,
                 p_trg_card_in                  IN VARCHAR2,
                 p_delivery_channel_in          IN VARCHAR2,
                 p_txn_code_in                  IN VARCHAR2,
                 p_txn_mode_in                  IN VARCHAR2,
                 p_trandate_in                  IN VARCHAR2,
                 p_trantime_in                  IN VARCHAR2,
                 p_terminalid_in                IN VARCHAR2,
                 p_merchant_name_in             IN VARCHAR2,
                 p_rvsl_code_in                 IN VARCHAR2,
                 p_storeid_in                   IN VARCHAR2,
                 p_store_add1_in                IN VARCHAR2,
                 p_store_add2_in                IN VARCHAR2,
                 p_store_city_in                IN VARCHAR2,
                 p_store_state_in               IN VARCHAR2,
                 p_store_zip_in                 IN VARCHAR2,
                 p_trans_amt_in                 in varchar2,
                 P_Merchantid_In                In Varchar2,
                 p_locationId_in                in varchar2,
                 p_trgt_bal_amt_out             OUT VARCHAR2,
                 p_src_bal_amt_out              OUT VARCHAR2,
                 p_trgt_card_stat_out           OUT VARCHAR2,
                 p_src_card_stat_out            OUT VARCHAR2,
                 p_trg_proxy_no_out             OUT VARCHAR2,
                 p_auth_amnt_out                OUT VARCHAR2,
                 p_errmsg_out                   OUT VARCHAR2,
                 p_resp_code_out                OUT VARCHAR2) is

/*************************************************
     * Created  by      : Ubaid
     * Created For     : VMS-354
     * Created Date    : 03-July-2018
     * Reviewer         : Saravankumar
     * Build Number     : R03
     
     * Modified  by     : Tilak Thapa.
     * Modified For     : VMS-951
     * Modified Date    : 25-July-2019.
     * Reviewer         : Aparna
     * Build Number     : R18-B5 

*************************************************/
    l_auth_id               transactionlog.auth_id%TYPE;
    l_src_card_stat         cms_appl_pan.cap_card_stat%TYPE;
    l_currcode              cms_transaction_log_dtl.ctd_txn_curr%type;
    l_errmsg                VARCHAR2(500);
    l_respcode              CMS_RESPONSE_MAST.CMS_RESPONSE_ID%type;
    l_capture_date          DATE;
    exp_main_reject_record  EXCEPTION;
    l_txn_type              cms_func_mast.cfm_txn_type%TYPE;
    l_src_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
    l_src_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
    l_trg_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
    l_delchannel_code       cms_delchannel_mast.cdm_channel_code%type;
    l_base_curr             cms_inst_param.cip_param_value%TYPE;
    l_tran_date             DATE;
    l_tran_amt              CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;   
    L_SRC_ACCT_BALANCE      CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;   
    l_src_ledger_balance    CMS_ACCT_MAST.cam_ledger_bal%type;
    l_business_date         DATE;
    l_src_proxunumber       cms_appl_pan.cap_proxy_number%TYPE;
    l_src_acct_number       cms_appl_pan.cap_acct_no%TYPE;
    L_SRC_ACCT_ID           cms_appl_pan.cap_acct_id%TYPE;
    l_dr_cr_flag            cms_transaction_mast.ctm_credit_debit_flag%type;
    l_tran_type             cms_transaction_mast.ctm_tran_type%type;
    l_trans_desc            cms_transaction_mast.ctm_tran_desc%TYPE;
    l_comb_hash             pkg_limits_check.type_hash;
    l_prfl_flag             cms_transaction_mast.ctm_prfl_flag%TYPE;
    l_src_prod_code         cms_appl_pan.cap_prod_code%TYPE;
    l_src_card_type         cms_appl_pan.cap_card_type%TYPE;
    l_src_lmtprfl           cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
    l_src_profile_level     cms_appl_pan.cap_prfl_levl%TYPE;
    l_src_fee_plan_id       cms_card_excpfee.cce_fee_plan%TYPE;
    l_oldcrd                cms_htlst_reisu.chr_pan_code%TYPE;
    l_hashkey_id            cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
    l_time_stamp            TIMESTAMP;
    L_TRG_ACCT_ID           cms_cust_acct.cca_acct_id%TYPE;
    L_TRG_ACCT_NO           cms_acct_mast.cam_acct_no%TYPE;
    L_TRG_CARD_STATUS       cms_appl_pan.cap_card_stat%TYPE;
    L_TRG_ACTIVE_DATE       cms_appl_pan.cap_active_date%TYPE;
    L_TRG_PROD_CODE         cms_appl_pan.cap_prod_code%TYPE;
    L_TRG_CARD_TYPE         cms_appl_pan.cap_card_type%TYPE;
    L_TRG_CUST_CODE         cms_cust_mast.ccm_cust_code%TYPE;
    L_TRG_CUST_ID           CMS_CUST_MAST.CCM_CUST_ID%TYPE;
    L_SRC_BILL_ADDR         CMS_APPL_PAN.CAP_BILL_ADDR%TYPE;
    L_TRG_BILL_ADDR         CMS_APPL_PAN.CAP_BILL_ADDR%TYPE;
    L_DUPCHK_CARDSTAT       transactionlog.cardstatus%type;
    L_DUPCHK_ACCTBAL        transactionlog.acct_balance%type; 
    L_DUPCHK_COUNT          NUMBER; 
    L_INSTORE_REPLACEMENT   cms_prod_Cattype.cpc_INSTORE_REPLACEMENT%type;
    l_src_card_pck_id       cms_appl_pan.cap_card_id%type;
    l_trg_card_pck_id       cms_appl_pan.cap_card_id%type;
    l_trg_lmtprfl           cms_appl_pan.cap_prfl_code%type;
    L_src_CUST_CODE         cms_appl_pan.cap_cust_code%type; 
    l_trg_appl_code         cms_appl_pan.cap_appl_code%type;    
    l_trg_encr_pan          cms_appl_pan.cap_pan_code_encr%type; 
    L_SRC_MERCHANT_NAME     cms_appl_pan.CAP_MERCHANT_NAME%TYPE;
    L_SRC_STORE_ID          cms_appl_pan.CAP_STORE_ID%TYPE;
    L_SRC_TERMINAL_ID       cms_appl_pan.CAP_TERMINAL_ID%TYPE;
    L_NARRATION             CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
    L_PACKAGEID_CHECK       CMS_PROD_CATTYPE.CPC_PACKAGEID_CHECK%TYPE;
    l_oldcrd_encr           cms_appl_pan.cap_pan_code_encr%TYPE;
    l_trg_card_in NUMBER;
    
    l_txn_code             cms_transaction_mast.CTM_TRAN_CODE%TYPE;
    l_mallid_check         cms_prod_cattype.CPC_MALLID_CHECK%TYPE;
    l_malllocation_check   cms_prod_cattype.CPC_MALLLOCATION_CHECK%TYPE;
    
    l_src_merchant_id      cms_appl_pan.CAP_MERCHANT_ID%TYPE;
    l_trg_merchant_id      cms_appl_pan.cap_merchant_id%TYPE;
    l_src_location_id     cms_appl_pan.CAP_REPLACE_LOCATION_ID%TYPE;
    l_trg_location_id      cms_appl_pan.CAP_REPLACE_LOCATION_ID%TYPE;
    preauthCnt       NUMBER;
    l_trg_ledger_balance   CMS_ACCT_MAST.cam_ledger_bal%type;
    l_TOPUP_AVAIL_balance   CMS_ACCT_MAST.cam_acct_bal%type;
    l_TOPUP_ledger_balance  CMS_ACCT_MAST.cam_ledger_bal%type;
    l_remark     varchar2(200);          
    V_Txn_Amt    Cms_Statements_Log.Csl_Trans_Amount%Type;
    L_Max_Card_Bal   Cms_Bin_Param.Cbp_Param_Value%Type;     
    l_profile_code   Cms_Prod_Cattype.Cpc_Profile_Code%TYPE;
    l_trg_acct_bal   cms_acct_mast.Cam_Acct_Bal%TYPE;
	
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
    v_Retdate  date; --Added for VMS-5739/FSP-991
              

  BEGIN
      p_errmsg_out := 'Success';
      p_resp_code_out := '00';
      l_time_stamp := systimestamp;
      l_txn_code :=p_txn_code_in;
      V_TXN_AMT := ROUND (p_trans_amt_in,2);
    
    --Sn create hash pan
    BEGIN
      l_src_hash_pan := gethash(p_src_card_in);
    EXCEPTION
    WHEN OTHERS THEN
        l_errmsg := 'ERROR WHILE CONVERTING HASH PAN FOR SOURCE CARD ' ||
            substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
    --En create hash pan

    --Sn create encr pan
    BEGIN
      l_src_encr_pan := fn_emaps_main(p_src_card_in);
    EXCEPTION
    WHEN OTHERS THEN
      l_respcode := '12';
      l_errmsg   := 'ERROR WHILE CONVERTING ENCR PAN FOR SOURCE CARD ' ||
		    		  substr(SQLERRM, 1, 200);
      RAISE exp_main_reject_record;
    END;
    --En create encr pan

    --Sn create hash pan of Migration card
--    BEGIN
--      l_trg_hash_pan := gethash(p_trg_card_in);
--    EXCEPTION 
--	  WHEN OTHERS THEN
--	    l_errmsg := 'ERROR WHILE CONVERTING HASH PAN FOR TARGET CARD ' ||
--			  	substr(SQLERRM, 1, 200);
--	    RAISE exp_main_reject_record;
--    END;

     --sn transaction time check
    BEGIN
       l_tran_date := to_date(substr(TRIM(p_trandate_in), 1, 8) || ' ' ||
                  substr(TRIM(p_trantime_in), 1, 10),
                  'YYYYMMDD HH24:MI:SS');
    EXCEPTION
      WHEN OTHERS THEN
         l_respcode := '32';
         l_errmsg   := 'PROBLEM WHILE CONVERTING TRANSACTION TIME ' ||
              substr(SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
    END;

  -- call lp procedure
     begin
     Lp_Trans_Details(P_Instcode_In ,P_Delivery_Channel_In ,L_Txn_Code ,P_Src_Card_In,P_Rrn_In,L_Time_Stamp,L_Hashkey_Id,L_Dr_Cr_Flag ,L_Txn_Type ,L_Tran_Type,L_Prfl_Flag,L_Trans_Desc,L_Respcode ,L_Errmsg);
     If L_Errmsg <> 'OK' Then
     	raise exp_main_reject_record;
     end if;
     EXCEPTION 
     WHEN  exp_main_reject_record THEN
     RAISE;
     WHEN OTHERS THEN
      l_respcode := '89';
            l_errmsg   := 'ERROR WHILE SELECTING SOURCE CARD DETAILS ' ||
                    substr(SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
   end;
    --sn select pan detail
    BEGIN

       SELECT cap_card_stat,cap_proxy_number,cap_acct_no,cap_acct_id,
              cap_prfl_code,CAP_PROD_CODE, CAP_PRFL_LEVL, CAP_CARD_TYPE,
              Cap_Bill_Addr,Cap_Cardpack_Id,Cap_Cust_Code,
              CAP_MERCHANT_NAME,CAP_STORE_ID,CAP_TERMINAL_ID,CAP_MERCHANT_ID,CAP_LOCATION_ID
         INTO l_src_card_stat,l_src_proxunumber, l_src_acct_number, L_SRC_ACCT_ID,
              l_src_lmtprfl,l_src_prod_code, l_src_profile_level, l_src_card_type,
              L_SRC_BILL_ADDR,l_src_card_pck_id,L_src_CUST_CODE,
              L_SRC_MERCHANT_NAME,L_SRC_STORE_ID,L_SRC_TERMINAL_ID,l_src_merchant_id,l_src_location_id
         FROM cms_appl_pan, cms_cust_mast
        WHERE cap_inst_code = p_instcode_in AND
              cap_inst_code = ccm_inst_code AND
              cap_cust_code = ccm_cust_code AND cap_pan_code = l_src_hash_pan AND
              cap_mbr_numb = p_mbr_numb_in;

      EXCEPTION
	      WHEN no_data_found THEN
            l_respcode := '49';
            l_errmsg   := 'INVALID SOURCE CARD';
            RAISE exp_main_reject_record;
   	    WHEN OTHERS THEN
            l_respcode := '89';
            l_errmsg   := 'ERROR WHILE SELECTING TRANS DETAILS ' ||
                    substr(SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
        
      BEGIN
         SELECT CAP_ACCT_NO, CAP_ACCT_ID, CAP_CARD_STAT, CAP_CUST_CODE,
                CCM_CUST_ID,cap_bill_addr,CAP_PROD_CODE,cap_card_type,
                CAP_ACTIVE_DATE,cap_cardpack_id,cap_prfl_code,cap_appl_code,
                cap_pan_code_encr,cap_proxy_number,CAP_PAN_CODE,fn_dmaps_main(cap_pan_code_encr),CAP_MERCHANT_ID,CAP_LOCATION_ID              
           INTO L_TRG_ACCT_NO, L_TRG_ACCT_ID, L_TRG_CARD_STATUS,L_TRG_CUST_CODE,
                L_TRG_CUST_ID,L_TRG_BILL_ADDR,L_TRG_PROD_CODE,L_TRG_CARD_TYPE,
                L_TRG_ACTIVE_DATE,l_trg_card_pck_id,l_trg_lmtprfl,l_trg_appl_code,
                l_trg_encr_pan,p_trg_proxy_no_out ,l_trg_hash_pan, l_trg_card_in,l_trg_merchant_id,l_trg_location_id
           FROM cms_appl_pan, cms_cust_mast
          WHERE cap_cust_code = ccm_cust_code AND
                cap_inst_code = p_instcode_in AND
                cap_inst_code = ccm_inst_code AND
                 CAP_SERIAL_NUMBER=p_trg_card_in and CAP_FORM_FACTOR is null
               -- cap_pan_code = gethash(p_trg_card_in))
                 AND cap_mbr_numb=p_mbr_numb_in ;


  	  EXCEPTION
                WHEN no_data_found THEN
                BEGIN
                    SELECT CAP_ACCT_NO, CAP_ACCT_ID, CAP_CARD_STAT, CAP_CUST_CODE,
                    CCM_CUST_ID,cap_bill_addr,CAP_PROD_CODE,cap_card_type,
                    CAP_ACTIVE_DATE,cap_cardpack_id,cap_prfl_code,cap_appl_code,
                    cap_pan_code_encr,cap_proxy_number,CAP_PAN_CODE,fn_dmaps_main(cap_pan_code_encr),CAP_MERCHANT_ID,CAP_LOCATION_ID
                    INTO L_TRG_ACCT_NO, L_TRG_ACCT_ID, L_TRG_CARD_STATUS,L_TRG_CUST_CODE,
                    L_TRG_CUST_ID,L_TRG_BILL_ADDR,L_TRG_PROD_CODE,L_TRG_CARD_TYPE,
                    L_TRG_ACTIVE_DATE,l_trg_card_pck_id,l_trg_lmtprfl,l_trg_appl_code,
                    l_trg_encr_pan,p_trg_proxy_no_out ,l_trg_hash_pan, l_trg_card_in,l_trg_merchant_id,l_trg_location_id
                    FROM cms_appl_pan, cms_cust_mast
                    WHERE cap_cust_code = ccm_cust_code AND
                    cap_inst_code = p_instcode_in AND
                    cap_inst_code = ccm_inst_code AND
                    cap_pan_code = gethash(p_trg_card_in)
                    -- cap_pan_code = gethash(p_trg_card_in))
                    AND cap_mbr_numb=p_mbr_numb_in ;
                    EXCEPTION
                        when  no_data_found THEN 

                            l_respcode := '49';
                            l_errmsg   := 'Target Card Not Found';
                        RAISE exp_main_reject_record;
                    END;
   	    WHEN OTHERS THEN
            l_respcode := '89';
            l_errmsg   := 'ERROR WHILE SELECTING TARGET CARD DETAILS ' ||
                    substr(SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      

        if L_TRG_CARD_STATUS in (0,1,8) then
       
         if L_TRG_CARD_STATUS in (1,8) then
          l_txn_code :='43';


    BEGIN
          lp_trans_details(p_instcode_in ,p_delivery_channel_in ,l_txn_code ,p_src_card_in,p_rrn_in,l_time_stamp,l_hashkey_id,l_dr_cr_flag ,l_txn_type ,l_tran_type,l_prfl_flag,l_trans_desc,l_respcode ,l_errmsg);
                If L_Errmsg <> 'OK' Then
     	raise exp_main_reject_record;
     end if;
     EXCEPTION 
	   WHEN  exp_main_reject_record THEN
     RAISE;
     WHEN OTHERS THEN
      l_respcode := '89';
            l_errmsg   := 'ERROR WHILE SELECTING TRANS DETAILS ' ||
                    substr(SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
  END;
          end if;
      else 
        l_respcode :='295';
        l_errmsg := 'Invalid Target Card Status';
        RAISE exp_main_reject_record;
      end if;

        
       Begin
        Select Cpc_Profile_Code,Nvl(Cpc_Instore_Replacement,'0'),Nvl(Cpc_Packageid_Check,'0'),Nvl(Cpc_Mallid_Check,'0'),Nvl(Cpc_Malllocation_Check,'0')
          INTO l_profile_code,L_INSTORE_REPLACEMENT,L_PACKAGEID_CHECK,l_mallid_check,l_malllocation_check
          FROM cms_prod_cattype
          WHERE cpc_prod_code = l_src_prod_code 
              AND cpc_card_type = l_src_card_type 
              AND cpc_inst_code = p_instcode_in;
       EXCEPTION
        WHEN no_data_found THEN
           l_errmsg   := 'ERROR WHILE FETCHING INSTORE_REPLACEMENT FOR SOURCE PROD - No Data found';
           l_respcode := '89';
           RAISE exp_main_reject_record;
        WHEN OTHERS THEN
           l_errmsg   := 'ERROR WHILE FETCHING INSTORE_REPLACEMENT ' ||substr(SQLERRM, 1, 200);
           l_respcode := '89';
           RAISE exp_main_reject_record;
       END;


          IF l_src_prod_code <> l_trg_prod_code or l_src_card_type <> l_trg_card_type
           Then
               l_respcode:= '317';
               l_errmsg   := 'both cards are of different prod category type';
               raise exp_main_reject_record;
          END IF;

     IF L_INSTORE_REPLACEMENT = '0' 
        then        
           l_respcode:= '4';
           l_errmsg   := 'Balance Transfer Support is disabled at product level';
           raise exp_main_reject_record;
      END IF;


        IF ((L_PACKAGEID_CHECK in (1,3) and  l_txn_code='41') or (l_txn_code ='43' and L_PACKAGEID_CHECK in ('2','3'))) then
          IF l_trg_card_pck_id <> l_src_card_pck_id
           then
               l_respcode:= '4';
               l_errmsg   := 'both cards belongs to different packageid';
               raise exp_main_reject_record;
          END IF;
       END IF;

   
   If L_Trg_Merchant_Id Is Null And L_Trg_Location_Id Is Null Then
      L_Trg_Merchant_Id :=P_Merchantid_In;
      L_Trg_Location_Id :=P_Locationid_In;
      end if;


      If ((L_Mallid_Check In (1,3) And  L_Txn_Code='41') Or (L_Txn_Code ='43' And L_Mallid_Check in ('2','3') )) Then
              If L_Src_Merchant_Id Is Null  or (L_Trg_Merchant_Id is null and P_Merchantid_In is null ) Then
               L_Respcode:= '318';
               l_errmsg   := 'both cards belongs to different Merchants';
               Raise Exp_Main_Reject_Record;
              End If;
             if l_src_merchant_id <> l_trg_merchant_id then
               L_Respcode:= '318';
               l_errmsg   := 'both cards belongs to different Merchants';
               raise exp_main_reject_record;
          end if;
      end if;


      If  ((L_Malllocation_Check In (1,3) And  L_Txn_Code='41') Or (L_Txn_Code ='43' And L_Malllocation_Check in ('2','3'))) Then
              If (L_Src_Merchant_Id Is Null  or l_src_location_id is null) or (L_Trg_Merchant_Id is null and P_Merchantid_In is null) or (l_trg_location_id is null and P_Locationid_In is null ) Then
                L_Respcode:= '319';
               l_errmsg   := 'both cards belongs to different merchants and locations';
               raise exp_main_reject_record;
              End If;
       if  l_src_merchant_id <> l_trg_merchant_id or l_src_location_id <> l_trg_location_id then
               L_Respcode:= '319';
               l_errmsg   := 'both cards belongs to different merchants and locations';
               raise exp_main_reject_record;
          end if;
      end if;
  

  IF  L_TXN_CODE='43' THEN
    BEGIN
	

		select count(1) into preauthCnt from VMSCMS.CMS_PREAUTH_TRANSACTION        --Added for VMS-5739/FSP-991       
		where cpt_card_no=l_src_hash_pan
		and CPT_EXPIRY_FLAG='N'
		and  cpt_inst_code=p_instcode_in;
		IF SQL%ROWCOUNT = 0 THEN
		select count(1) into preauthCnt from VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST        --Added for VMS-5739/FSP-991       
		where cpt_card_no=l_src_hash_pan
		and CPT_EXPIRY_FLAG='N'
		and  cpt_inst_code=p_instcode_in;
		END IF;
		   
    if preauthCnt>0 then
           l_respcode:= '321';
           l_errmsg   := 'Balance transfer denied due to pending preauth on source card';
           raise exp_main_reject_record;
    end if;
    
    EXCEPTION when exp_main_reject_record then
       raise;
      WHEN OTHERS THEN
       l_respcode:='89';
               l_errmsg := 'ERROR WHILE SELECTING PREAUTH DETAILS FOR SOURCE CARD';
               RAISE exp_main_reject_record;
    
    END;
  
  END IF;

    BEGIN 
        SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO L_DUPCHK_CARDSTAT, L_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS.TRANSACTIONLOG       --Added for VMS-5739/FSP-991  
                WHERE RRN = P_RRN_IN AND CUSTOMER_CARD_NO = l_src_hash_pan AND
                DELIVERY_CHANNEL = p_delivery_channel_in
                and ACCT_BALANCE is not null
                order by add_ins_date desc)
        where rownum=1;
		  IF SQL%ROWCOUNT = 0 THEN
		    SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO L_DUPCHK_CARDSTAT, L_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST      --Added for VMS-5739/FSP-991  
                WHERE RRN = P_RRN_IN AND CUSTOMER_CARD_NO = l_src_hash_pan AND
                DELIVERY_CHANNEL = p_delivery_channel_in
                and ACCT_BALANCE is not null
                order by add_ins_date desc)
        where rownum=1;
		  END IF;
		  
        L_DUPCHK_COUNT:=1;
      EXCEPTION         
              WHEN NO_DATA_FOUND 
              THEN
              L_DUPCHK_COUNT:=0;

              WHEN OTHERS
              THEN 
               l_respcode:='89';
               l_errmsg := 'ERROR WHILE CHECKING CARD STATUS AND ACCOUNT BAL';
               RAISE exp_main_reject_record;
    END; 

    BEGIN
          SELECT CAM_ACCT_BAL
          INTO l_tran_amt
          FROM CMS_ACCT_MAST
          WHERE CAM_ACCT_NO = l_src_acct_number
          AND  CAM_INST_CODE = P_INSTCODE_IN;
          
        p_auth_amnt_out :=trim(to_char(l_tran_amt,'99999999999999990.99'));
        
      EXCEPTION
         WHEN OTHERS THEN
              l_respcode := '12';
              l_errmsg   := 'ERROR WHILE SELECTING SOURCE ACCOUNT BALANCE ' ||substr(sqlerrm,1,200);
              RAISE EXP_MAIN_REJECT_RECORD;
     END;

 
     IF l_tran_amt <= 0 then
        L_RESPCODE := '15';
        L_ERRMSG   := 'INSUFFICIENT FUNDS';
            RAISE EXP_MAIN_REJECT_RECORD;

     END IF;

   IF l_DUPCHK_COUNT =1 then

        L_DUPCHK_COUNT:=0;

            if L_DUPCHK_CARDSTAT= l_src_card_stat and L_DUPCHK_ACCTBAL=l_tran_amt 
            then

            L_DUPCHK_COUNT:=1;
            L_RESPCODE := '22';
            L_ERRMSG   := 'DUPLICATE INCOMM REFERENCE NUMBER' ||P_RRN_IN;
            RAISE EXP_MAIN_REJECT_RECORD;

            end if;

      END IF;
      BEGIN
            vmsfunutilities.get_currency_code(l_src_prod_code,l_src_card_type,p_instcode_in,l_base_curr,l_errmsg);
              if l_errmsg<>'OK' then
                   raise exp_main_reject_record;
              end if;

          IF TRIM(l_base_curr) IS NULL
          THEN
              l_respcode := '89';
              l_errmsg   := 'BASE CURRENCY CANNOT BE NULL ';
              RAISE exp_main_reject_record;
          END IF;

        l_currcode := l_base_curr;
        
          EXCEPTION
            WHEN exp_main_reject_record THEN
              RAISE exp_main_reject_record;
            WHEN OTHERS THEN
              l_respcode := '89';
              l_errmsg   := 'ERROR WHILE SELECTING BASE CURRECY  ' ||
                   substr(SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
      END;
	 --sn call to authorize txn
                      
             BEGIN
               Sp_Authorize_Txn_Cms_Auth(P_Instcode_In, P_Msg_Type_In, P_Rrn_In,
                          p_delivery_channel_in, p_terminalid_in,
                          l_txn_code, p_txn_mode_in,
                          p_trandate_in, p_trantime_in, p_src_card_in,
                          NULL, l_tran_amt, p_merchant_name_in,
                          Null, Null, L_Currcode, Null,
                          NULL, NULL,case when L_Txn_Code='43' then l_TRG_ACCT_NO  else null end, NULL, NULL, NULL, NULL,
                          NULL, NULL, NULL, NULL, NULL, NULL,
                          p_mbr_numb_in, p_rvsl_code_in, l_tran_amt,
                          l_auth_id, l_respcode, l_errmsg,
                          l_capture_date);

                     IF l_respcode <> '00' AND l_errmsg <> 'OK'
                     THEN
                     l_respcode := '294';
                     l_errmsg := l_errmsg;
                    RAISE exp_main_reject_record;
                     END IF;
             EXCEPTION
                 WHEN exp_main_reject_record THEN
                    RAISE;
                 WHEN OTHERS THEN
                    l_respcode := '89';
                    l_errmsg   := substr(SQLERRM, 'ERROR FROM CARD AUTHORIZATION' || 1,
                             200);
                    RAISE exp_main_reject_record;
             END;

If L_Txn_Code ='43' Then 
       
              BEGIN
             Select Cam_Acct_Bal
               INTO l_trg_acct_bal
               FROM cms_acct_mast
              WHERE cam_acct_no = L_TRG_ACCT_NO AND
                  cam_inst_code = p_instcode_in;
         EXCEPTION

             WHEN OTHERS THEN
                l_respcode := '12';
                l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                        SQLERRM;
                Raise exp_main_reject_record;
         END;  
       
       
         BEGIN
         Select To_Number(Cbp_Param_Value)       
           INTO l_MAX_CARD_BAL
           FROM CMS_BIN_PARAM
          WHERE CBP_INST_CODE = p_instcode_in AND
               CBP_PARAM_NAME = 'Max Card Balance' AND
               CBP_PROFILE_CODE=l_profile_code;
           
        EXCEPTION
          WHEN OTHERS THEN
           L_Respcode := '21';
           l_errmsg  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                      SUBSTR(SQLERRM, 1, 200);
           Raise exp_main_reject_record;
        END;

            If (L_Trg_Acct_Bal > l_Max_Card_Bal)
                      OR ((l_trg_acct_bal + l_tran_amt) > l_max_card_bal)
            THEN
               l_respcode := '322';
               l_errmsg := 'Maximum Balance Limitation';
           RAISE exp_main_reject_record;
          End If;
  end if;

    BEGIN
        SELECT chr_pan_code,chr_pan_code_encr
          INTO l_oldcrd,l_oldcrd_encr
          FROM cms_htlst_reisu
         WHERE chr_inst_code = p_instcode_in AND chr_new_pan = l_trg_hash_pan AND
                  chr_reisu_cause = 'R' AND chr_pan_code IS NOT NULL;
                  
       UPDATE cms_appl_pan
          SET cap_card_stat = '9'
        WHERE cap_inst_code = p_instcode_in AND cap_pan_code = l_oldcrd;

     BEGIN
          sp_log_cardstat_chnge(p_instcode_in,l_oldcrd,
                        l_oldcrd_encr, l_auth_id, '02',
                          p_rrn_in, p_trandate_in, p_trantime_in,
                          l_respcode, l_errmsg,'Closed through Balance Transfer');

                    IF l_respcode <> '00' AND l_errmsg <> 'OK'
                    THEN
                        l_respcode := '89';
                        RAISE exp_main_reject_record;
                    END IF;
     EXCEPTION
         WHEN exp_main_reject_record THEN
                      RAISE;
          WHEN OTHERS THEN
                l_respcode := '89';
                l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
                   substr(SQLERRM, 1, 200);
                RAISE exp_main_reject_record;
    END;        
    EXCEPTION
          WHEN no_data_found THEN
             NULL;
         WHEN OTHERS THEN
                 l_respcode := '89';
                 l_errmsg   := 'Error while selecting old card of target card ' ||
                      substr(SQLERRM, 1,200 
                      );
                 RAISE exp_main_reject_record;
    END;
 IF l_txn_code ='41' THEN
     --st updates the fee plan id to card
    BEGIN
         
    insert into cms_card_excpfee (cce_inst_code, cce_pan_code, cce_ins_date, cce_ins_user,
		   cce_lupd_user, cce_lupd_date, cce_fee_plan, cce_flow_source,
		   cce_crgl_catg, cce_crgl_code, cce_crsubgl_code, cce_cracct_no,
		   cce_drgl_catg, cce_drgl_code, cce_drsubgl_code, cce_dracct_no,
		   cce_valid_from, cce_valid_to, cce_st_crgl_catg,
		   cce_st_crgl_code, cce_st_crsubgl_code, cce_st_cracct_no,
		   cce_st_drgl_catg, cce_st_drgl_code, cce_st_drsubgl_code,
		   cce_st_dracct_no, cce_cess_crgl_catg, cce_cess_crgl_code,
		   cce_cess_crsubgl_code, cce_cess_cracct_no, cce_cess_drgl_catg,
		   cce_cess_drgl_code, cce_cess_drsubgl_code, cce_cess_dracct_no,
		   cce_st_calc_flag, cce_cess_calc_flag, cce_pan_code_encr)
        (select cce_inst_code, l_trg_hash_pan, cce_ins_date, cce_ins_user,
		   cce_lupd_user, cce_lupd_date, cce_fee_plan, cce_flow_source,
		   cce_crgl_catg, cce_crgl_code, cce_crsubgl_code, cce_cracct_no,
		   cce_drgl_catg, cce_drgl_code, cce_drsubgl_code, cce_dracct_no,
		   cce_valid_from, cce_valid_to, cce_st_crgl_catg,
		   cce_st_crgl_code, cce_st_crsubgl_code, cce_st_cracct_no,
		   cce_st_drgl_catg, cce_st_drgl_code, cce_st_drsubgl_code,
		   cce_st_dracct_no, cce_cess_crgl_catg, cce_cess_crgl_code,
		   cce_cess_crsubgl_code, cce_cess_cracct_no, cce_cess_drgl_catg,
		   cce_cess_drgl_code, cce_cess_drsubgl_code, cce_cess_dracct_no,
		   cce_st_calc_flag, cce_cess_calc_flag, l_trg_encr_pan from cms_card_excpfee 
           where cce_pan_code = l_src_hash_pan );
    EXCEPTION
 
	WHEN OTHERS THEN
	   l_errmsg   := 'ERROR WHILE UPDATING FEE PLAN ID ' ||
				  substr(SQLERRM, 1, 200);
	   l_respcode := '89';
	   RAISE exp_main_reject_record;
  END;


    if  L_TRG_CARD_STATUS <> '0' then
        l_respcode :='295';
        l_errmsg := 'Invalid Target Card Status';
        RAISE exp_main_reject_record;
	  END IF;
      
    IF L_TRG_CARD_STATUS ='0' and L_TRG_ACTIVE_DATE is not null
	  THEN
        l_respcode :='295';
        l_errmsg := 'Invalid Target Card Status';
               raise exp_main_reject_record;
    END IF;
END IF;
            --SN : Transaction limits check
         BEGIN

            IF (l_trg_lmtprfl IS NOT NULL AND l_prfl_flag = 'Y')
            THEN
               pkg_limits_check.sp_limits_check (l_trg_hash_pan,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 l_txn_code,
                                                 l_tran_type,
                                                 NULL,
                                                 NULL,
                                                 p_instcode_in,
                                                 NULL,
                                                 l_trg_lmtprfl,
                                                 l_tran_amt,
                                                 p_delivery_channel_in,
                                                 l_comb_hash,
                                                 l_respcode,
                                                 l_errmsg);
            END IF;

            IF l_respcode <> '00' AND l_errmsg <> 'OK'
            THEN
               IF l_respcode = '127'
               THEN
                  l_respcode := '140';
               ELSE
                  l_respcode := l_respcode;
               END IF;

               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_respcode := '89';
               l_errmsg :=
                  'Error while limits check-' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         --EN : Transaction limits check
  if  l_txn_code ='41' then
        BEGIN
             SELECT cam_ledger_bal
               INTO l_src_ledger_balance
               FROM cms_acct_mast
              WHERE cam_acct_no = l_src_acct_number AND
                  cam_inst_code = p_instcode_in;
         EXCEPTION

             WHEN OTHERS THEN
                l_respcode := '12';
                l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                        SQLERRM;
                RAISE exp_main_reject_record;
         END;  

       BEGIN
             UPDATE cms_acct_mast
                SET cam_acct_bal =cam_acct_bal+l_tran_amt, 
                    cam_ledger_bal =cam_ledger_bal+l_tran_amt
              WHERE cam_acct_no = l_src_acct_number AND
                    cam_inst_code = p_instcode_in;
         EXCEPTION

             WHEN OTHERS THEN
                l_respcode := '12';
                l_errmsg   := 'ERROR WHILE UPDATING BALANCE INTO TARGET ACCT ' ||
                        SQLERRM;
                RAISE exp_main_reject_record;
         END;

    ELSE
       
        BEGIN
             SELECT cam_ledger_bal
               INTO l_trg_ledger_balance
               FROM cms_acct_mast
              WHERE cam_acct_no = L_TRG_ACCT_NO AND
                  cam_inst_code = p_instcode_in;
         EXCEPTION

             WHEN OTHERS THEN
                l_respcode := '12';
                l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                        SQLERRM;
                RAISE exp_main_reject_record;
         END;  
       
       
      BEGIN
             UPDATE cms_acct_mast
                SET cam_acct_bal =cam_acct_bal+l_tran_amt, 
                    cam_ledger_bal =cam_ledger_bal+l_tran_amt
              WHERE cam_acct_no = L_TRG_ACCT_NO AND
                    cam_inst_code = p_instcode_in;
         EXCEPTION

             WHEN OTHERS THEN
                l_respcode := '12';
                l_errmsg   := 'ERROR WHILE UPDATING BALANCE INTO TARGET ACCT ' ||
                        SQLERRM;
                RAISE exp_main_reject_record;
         END;
    
      BEGIN
             SELECT cam_acct_bal,cam_ledger_bal
               INTO l_TOPUP_AVAIL_balance,l_TOPUP_ledger_balance
               FROM cms_acct_mast
              WHERE cam_acct_no = L_TRG_ACCT_NO AND
                  cam_inst_code = p_instcode_in;
         EXCEPTION

             WHEN OTHERS THEN
                l_respcode := '12';
                l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                        SQLERRM;
                RAISE exp_main_reject_record;
         END;  
    
    end if;
 BEGIN

        IF TRIM(l_trans_desc) IS NOT NULL THEN
    
         L_NARRATION := l_trans_desc || '/';   
    
        END IF;
        if trim(p_merchant_name_in) is not null then
          L_NARRATION :=L_NARRATION|| p_merchant_name_in || '/';
        end if;
        
        IF TRIM(p_trandate_in) IS NOT NULL THEN
    
         L_NARRATION := L_NARRATION || p_trandate_in||'/';
    
        END IF;
        
         IF TRIM(l_auth_id) IS NOT NULL THEN
    
         L_NARRATION := L_NARRATION || l_auth_id;
    
        END IF;

  EXCEPTION
    
    WHEN OTHERS THEN

     l_respcode := '21';
     l_errmsg  := 'Error in finding the narration ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE exp_main_reject_record;

  END;
  
 BEGIN
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
      CSL_TIME_STAMP,           
      CSL_PROD_CODE,csl_card_type,csl_acct_type             
      )
    VALUES
     (l_trg_hash_pan,
      decode(l_txn_code,'41',l_src_ledger_balance,l_trg_ledger_balance),     
      l_tran_amt,
      'CR',
      L_TRAN_DATE,
      decode(l_txn_code,'41',l_tran_amt + l_src_ledger_balance,l_trg_ledger_balance+l_tran_amt),
      L_NARRATION,
      l_trg_encr_pan,
      P_RRN_IN,
      l_auth_id,
      p_trandate_in,
      p_trantime_in,
      'N',
      P_DELIVERY_CHANNEL_IN,
      P_INSTCODE_IN,
      l_txn_code,
      decode(l_txn_code,'41',l_src_acct_number,L_TRG_ACCT_NO), 
      1,
      SYSDATE,
      --substr(p_trg_card_in,-4),   
      substr(l_trg_card_in,-4),
      systimestamp,       
      L_TRG_PROD_CODE,L_TRG_CARD_TYPE ,1       
      );
  EXCEPTION
    WHEN OTHERS THEN
     l_respcode := '89';
     l_errmsg  := 'Error while creating entry in statement log ';
     RAISE exp_main_reject_record;

  END;


        BEGIN
             SELECT cam_ledger_bal,cam_acct_bal
               INTO l_src_ledger_balance,l_src_acct_balance
               From Cms_Acct_Mast
              WHERE cam_acct_no = l_src_acct_number AND
                  cam_inst_code = p_instcode_in;
         EXCEPTION

             WHEN OTHERS THEN
                l_respcode := '12';
                l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                        SQLERRM;
                RAISE exp_main_reject_record;
         END;  
         
         

     P_Trgt_Bal_Amt_Out :=Trim(To_Char(l_TOPUP_ledger_balance,'99999999999999990.99'));
     p_src_bal_amt_out :='0.00';
          
          

if l_txn_code ='41' then 

    P_Trgt_Bal_Amt_Out :=Trim(To_Char(L_Src_Ledger_Balance,'99999999999999990.99'));

    BEGIN
       UPDATE cms_appl_pan
          SET cap_acct_no = l_src_acct_number,
              cap_acct_id = l_src_acct_id,
              cap_cust_code=l_src_cust_code,
              cap_bill_addr=l_src_bill_addr,
              cap_merchant_name=l_src_merchant_name,
              cap_store_id=l_src_store_id,
              cap_terminal_id=l_src_terminal_id,
              cap_firsttime_topup = 'Y', 
              cap_card_stat = 1,
              cap_active_date = SYSDATE,
              cap_prfl_code = l_src_lmtprfl,
              Cap_Prfl_Levl = L_Src_Profile_Level,
              Cap_Repl_Flag =7,
              Cap_Merchant_Id=P_Merchantid_In,
              cap_location_id=p_locationId_in
        WHERE cap_inst_code = p_instcode_in AND cap_pan_code = l_trg_hash_pan;

       UPDATE cms_appl_mast
          SET cam_cust_code = l_src_cust_code,
              cam_bill_addr=l_src_bill_addr
        WHERE cam_appl_code = l_trg_appl_code AND cam_inst_code = p_instcode_in;

       UPDATE cms_appl_det
          SET cad_acct_id = l_src_acct_id
        WHERE cad_appl_code = l_trg_appl_code AND cad_inst_code = p_instcode_in;

   EXCEPTION
	     WHEN OTHERS THEN
           l_respcode := '89';
           l_errmsg   := 'ERROR WHILE UPDATING TARGET ACCOUNT NUMBER ' ||
                substr(SQLERRM, 1, 100);
           RAISE exp_main_reject_record;
    END;
    
           BEGIN
              
         sp_log_cardstat_chnge(p_instcode_in, l_trg_hash_pan, l_trg_encr_pan,
                l_auth_id, '01', p_rrn_in, p_trandate_in,
                p_trantime_in, l_respcode, l_errmsg);

             IF l_respcode <> '00' AND l_errmsg <> 'OK'
                 THEN
                RAISE exp_main_reject_record;
             END IF;
       EXCEPTION
           WHEN exp_main_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              l_respcode := '89';
              l_errmsg   := 'ERROR WHILE LOGGING SYSTEM INITIATED CARD STATUS CHANGE ' ||
                      substr(SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
       END;
 
    BEGIN

	   UPDATE CMS_PAN_ACCT
	      SET cpa_acct_id = l_src_acct_id,
            cpa_cust_code=l_src_cust_code 
	    WHERE CPA_INST_CODE = P_INSTCODE_IN  AND CPA_ACCT_ID = L_TRG_ACCT_ID
        AND cpa_mbr_numb=p_mbr_numb_in AND cpa_pan_code=l_trg_hash_pan;

    EXCEPTION
        WHEN OTHERS THEN
         l_respcode := '89';
         l_errmsg   := 'ERROR WHILE UPDATING CMS_PAN_ACCT  ' ||
              substr(SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
    END;

    BEGIN
   	 
	   UPDATE cms_smsandemail_alert
	   SET  (csa_loadorcredit_flag, csa_lowbal_flag, csa_negbal_flag,
			csa_highauthamt_flag, csa_dailybal_flag, csa_insuff_flag,
			csa_incorrpin_flag, csa_fast50_flag, csa_fedtax_refund_flag,
			csa_cellphonecarrier, csa_lowbal_amt, csa_highauthamt,
			csa_c2c_flag, csa_alert_lang_id) = 
      (select csa_loadorcredit_flag, csa_lowbal_flag, csa_negbal_flag,
			csa_highauthamt_flag, csa_dailybal_flag, csa_insuff_flag,
			csa_incorrpin_flag, csa_fast50_flag, csa_fedtax_refund_flag,
			csa_cellphonecarrier, csa_lowbal_amt, csa_highauthamt,
			csa_c2c_flag, csa_alert_lang_id from cms_smsandemail_alert
      WHERE  csa_inst_code = p_instcode_in AND
			csa_pan_code = l_src_hash_pan) 
	   WHERE  csa_inst_code = p_instcode_in AND csa_pan_code = l_trg_hash_pan;
	 
	   IF SQL%ROWCOUNT = 0
	   THEN
          l_errmsg   := 'ERROR WHILE UPDATING ALERTS FROM PREVIOUS CARDS IN CMS_SMSANDEMAIL_ALERT' ||
                  substr(SQLERRM, 1, 200);
          l_respcode := '21';
		RAISE exp_main_reject_record;
    
	   END IF;
     
	 EXCEPTION
	   WHEN exp_main_reject_record THEN
		RAISE exp_main_reject_record;
	   WHEN OTHERS THEN
		l_errmsg   := 'ERROR WHILE UPDATING OPTIN_ALERTS IN CMS_SMSANDEMAIL_ALERT TABLE' ||
				    substr(SQLERRM, 1, 200);
		l_respcode := '21';
		RAISE exp_main_reject_record;
	 END;
   


 end if; 
   
 if  l_txn_code ='43' and  L_TRG_CARD_STATUS='8' then
  
   begin  
         update cms_appl_pan set cap_card_stat=nvl(CAP_OLD_CARDSTAT,'1') 
         where  cap_pan_code= l_trg_hash_pan 
              and cap_inst_code=p_instcode_in ;
              
   EXCEPTION
        WHEN OTHERS THEN
         l_respcode := '89';
         l_errmsg   := 'ERROR WHILE UPDATING cms_appl_pan target card status' ||
              substr(SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
  end;
  
    BEGIN
              
         sp_log_cardstat_chnge(p_instcode_in, l_trg_hash_pan, l_trg_encr_pan,
                l_auth_id, '05', p_rrn_in, p_trandate_in,
                p_trantime_in, l_respcode, l_errmsg);

             IF l_respcode <> '00' AND l_errmsg <> 'OK'
                 THEN
                RAISE exp_main_reject_record;
             END IF;
       EXCEPTION
           WHEN exp_main_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              l_respcode := '89';
              l_errmsg   := 'ERROR WHILE LOGGING SYSTEM INITIATED CARD STATUS CHANGE ' ||
                      substr(SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
       END;
  
  
  
  end if;

     p_trgt_card_stat_out:='Active';
 
      
   BEGIN
   
	 INSERT INTO cms_cardprofile_hist
	   (CCP_PAN_CODE, CCP_INST_CODE, 
      ccp_pan_code_encr, ccp_ins_date, ccp_lupd_date, ccp_mbr_numb,
	    CCP_RRN, CCP_STAN, CCP_BUSINESS_DATE, CCP_BUSINESS_TIME,
	    ccp_terminal_id, ccp_acct_no, ccp_acct_id,
	    CCP_CUST_CODE) 
	 VALUES
	   (L_TRG_HASH_PAN, P_INSTCODE_IN, 
      l_trg_encr_pan, SYSDATE, SYSDATE,p_mbr_numb_in, 
      P_RRN_IN, NULL, P_TRANDATE_IN, P_TRANTIME_IN,
	    p_terminalid_in, L_TRG_ACCT_NO, L_TRG_ACCT_ID, 
	    L_TRG_CUST_CODE); 
      
  EXCEPTION
	 WHEN no_data_found THEN
	   l_respcode := '21';
	   l_errmsg   := 'NO DATA FOUND IN ADDRMAST/CUSTMAST FOR' || '-' ||
				  L_TRG_CUST_CODE;
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR IN PROFILE UPDATE ' || substr(SQLERRM, 1, 300);
	   RAISE exp_main_reject_record;
    END;
 
    BEGIN
                sp_log_cardstat_chnge(p_instcode_in, l_src_hash_pan,
                          l_src_encr_pan, l_auth_id, '02',
                          p_rrn_in, p_trandate_in, p_trantime_in,
                          l_respcode, l_errmsg,'Closed through Balance Transfer');

                    IF l_respcode <> '00' AND l_errmsg <> 'OK'
                    THEN
                        l_respcode := '89';
                        RAISE exp_main_reject_record;
                    END IF;
              EXCEPTION
                  WHEN exp_main_reject_record THEN
                      RAISE;
                  WHEN OTHERS THEN
                      l_respcode := '89';
                      l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
                           substr(SQLERRM, 1, 200);
                      RAISE exp_main_reject_record;
              END;

              BEGIN
                UPDATE cms_appl_pan
                   SET cap_card_stat = '9'
                 WHERE cap_pan_code = l_src_hash_pan AND
                       cap_inst_code = p_instcode_in;

                              
                    IF SQL%ROWCOUNT = 0
                    THEN
                          l_respcode := '89';
                          l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS ' ||
                               substr(SQLERRM, 1, 200);
                          RAISE exp_main_reject_record;
                    END IF;
      p_src_card_stat_out :='Closed';

   EXCEPTION
        WHEN exp_main_reject_record THEN
            RAISE exp_main_reject_record;
        WHEN OTHERS THEN
            l_respcode := '89';
            l_errmsg   := 'ERROR WHILE SELECTING STARTER CARD DETAILS ' ||
                    substr(SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
	 END;
   
	 IF l_trg_lmtprfl IS NOT NULL AND l_prfl_flag = 'Y'
	 THEN
   BEGIN
                      
	   pkg_limits_check.sp_limitcnt_reset(p_instcode_in, l_trg_hash_pan,
								   l_tran_amt, l_comb_hash,
								   l_respcode, l_errmsg);
   
	 IF l_respcode <> '00' AND l_errmsg <> 'OK'
	 THEN
	   l_errmsg := 'FROM PROCEDURE SP_LIMITCNT_RESET' || l_errmsg;
	   RAISE exp_main_reject_record;
	 END IF;
   
   EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR FROM LIMIT RESET COUNT PROCESS ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;

 END IF;
         if l_txn_code ='43' then
           begin
		   --Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod) 										--Added for VMS-5739/FSP-991
    THEN
           update cms_statements_log 
		   set csl_to_acctno=L_TRG_ACCT_NO
           where csl_pan_NO=l_src_hash_pan
           and csl_inst_code=p_instcode_in
           and csl_rrn=p_rrn_in 
           and csl_delivery_channel=p_delivery_channel_in
           and csl_txn_code=l_txn_code
           and csl_business_date=p_trandate_in
           and csl_business_time=p_trantime_in;
ELSE
		  update VMSCMS_HISTORY.cms_statements_log_HIST			 --Added for VMS-5739/FSP-991 
		  set csl_to_acctno=L_TRG_ACCT_NO
           where csl_pan_NO=l_src_hash_pan
           and csl_inst_code=p_instcode_in
           and csl_rrn=p_rrn_in 
           and csl_delivery_channel=p_delivery_channel_in
           and csl_txn_code=l_txn_code
           and csl_business_date=p_trandate_in
           and csl_business_time=p_trantime_in;
END IF;		   
           
            IF SQL%ROWCOUNT = 0
           THEN
               p_errmsg_out := 'ERROR WHILE UPDATING STOREID IN TRANSACTIONLOG TABLE' ||
                      substr(SQLERRM, 1, 200);
               l_respcode   := '89';
               RAISE exp_main_reject_record;
            END IF;
           
          EXCEPTION  WHEN exp_main_reject_record  THEN 
          raise;
              WHEN OTHERS THEN
           l_respcode := '21';
             l_errmsg   := 'ERROR WHILE UPDATING STATEMENTS LOG' ||
                  substr(SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
           
           end;
           
           end if;
           
        begin
         select 'From Account No : '|| vmscms.fn_mask_acct(l_src_acct_number)||' '||'To Account No : ' ||vmscms.fn_mask_acct(L_TRG_ACCT_NO)
           into l_remark
           from dual;
           EXCEPTION 
                  WHEN OTHERS THEN
                      l_respcode := '89';
                      l_errmsg   := 'ERROR WHILE  format the remark-' ||
                           substr(SQLERRM, 1, 200);
                      RAISE exp_main_reject_record;
           end;
    
    BEGIN
	--Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod) 					--Added for VMS-5739/FSP-991

    THEN
         UPDATE transactionlog
            SET store_id = p_storeid_in,
                tran_reverse_flag = 'N',
                topup_card_no_encr=l_trg_encr_pan,
                Acct_Balance=L_Src_Acct_Balance,Ledger_Balance=L_Src_Ledger_Balance,
                topup_card_no=DECODE(l_txn_code,'43',l_trg_hash_pan,''),topup_acct_no=decode(l_txn_code,'43',L_TRG_ACCT_NO,''),topup_acct_type='1',bank_code=1,remark=decode(l_txn_code,'43',l_remark,''),
                topup_acct_balance=decode(l_txn_code,'43',l_TOPUP_AVAIL_balance,''),topup_ledger_balance=decode(l_txn_code,'43',l_TOPUP_ledger_balance,'')
          WHERE instcode = p_instcode_in AND rrn = p_rrn_in AND
                customer_card_no = l_src_hash_pan AND
                business_date = p_trandate_in AND txn_code = l_txn_code AND
                delivery_channel = p_delivery_channel_in;
ELSE
			UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST              --Added for VMS-5739/FSP-991
            SET store_id = p_storeid_in,
                tran_reverse_flag = 'N',
                topup_card_no_encr=l_trg_encr_pan,
                Acct_Balance=L_Src_Acct_Balance,Ledger_Balance=L_Src_Ledger_Balance,
                topup_card_no=DECODE(l_txn_code,'43',l_trg_hash_pan,''),topup_acct_no=decode(l_txn_code,'43',L_TRG_ACCT_NO,''),topup_acct_type='1',bank_code=1,remark=decode(l_txn_code,'43',l_remark,''),
                topup_acct_balance=decode(l_txn_code,'43',l_TOPUP_AVAIL_balance,''),topup_ledger_balance=decode(l_txn_code,'43',l_TOPUP_ledger_balance,'')
          WHERE instcode = p_instcode_in AND rrn = p_rrn_in AND
                customer_card_no = l_src_hash_pan AND
                business_date = p_trandate_in AND txn_code = l_txn_code AND
                delivery_channel = p_delivery_channel_in;
END IF;
				

           IF SQL%ROWCOUNT = 0
           THEN
               p_errmsg_out := 'ERROR WHILE UPDATING STOREID IN TRANSACTIONLOG TABLE' ||
                      substr(SQLERRM, 1, 200);
               l_respcode   := '89';
               RAISE exp_main_reject_record;
           END IF;
    EXCEPTION
       WHEN exp_main_reject_record THEN
           RAISE exp_main_reject_record;
    	 WHEN OTHERS THEN
           p_errmsg_out := 'ERROR WHILE UPDATING STOREID IN TRANSACTIONLOG TABLE' ||
                  substr(SQLERRM, 1, 200);
           l_respcode   := '89';
             RAISE exp_main_reject_record;
    END;
    
     BEGIN
	 --Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)                      --Added for VMS-5739/FSP-991

    THEN
       Update Cms_Transaction_Log_Dtl
          SET --ctd_location_id = p_terminalid_in,
              CTD_STORE_ADDRESS1 = p_store_add1_in,
              CTD_STORE_ADDRESS2 = p_store_add2_in,
              CTD_STORE_CITY     = p_store_city_in,
              CTD_STORE_STATE    = p_store_state_in,
              CTD_STORE_ZIP      = p_store_zip_in
        WHERE ctd_rrn = p_rrn_in AND ctd_business_date = p_trandate_in AND
              ctd_business_time = p_trantime_in AND
              ctd_delivery_channel = p_delivery_channel_in AND
              ctd_txn_code = l_txn_code AND ctd_msg_type = p_msg_type_in AND
              ctd_inst_code = p_instcode_in AND
              ctd_customer_card_no = l_src_hash_pan;
ELSE
		Update VMSCMS_HISTORY.cms_transaction_log_dtl_HIST                  --Added for VMS-5739/FSP-991
          SET --ctd_location_id = p_terminalid_in,
              CTD_STORE_ADDRESS1 = p_store_add1_in,
              CTD_STORE_ADDRESS2 = p_store_add2_in,
              CTD_STORE_CITY     = p_store_city_in,
              CTD_STORE_STATE    = p_store_state_in,
              CTD_STORE_ZIP      = p_store_zip_in
        WHERE ctd_rrn = p_rrn_in AND ctd_business_date = p_trandate_in AND
              ctd_business_time = p_trantime_in AND
              ctd_delivery_channel = p_delivery_channel_in AND
              ctd_txn_code = l_txn_code AND ctd_msg_type = p_msg_type_in AND
              ctd_inst_code = p_instcode_in AND
              ctd_customer_card_no = l_src_hash_pan;
END IF;			  

         IF SQL%ROWCOUNT = 0
         THEN
             p_errmsg_out := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
             l_respcode   := '89';
             RAISE exp_main_reject_record;
         END IF;
    EXCEPTION
         WHEN exp_main_reject_record THEN
             RAISE exp_main_reject_record;
         WHEN OTHERS THEN
             l_respcode   := '89';
             p_errmsg_out := 'PROBLEM ON UPDATED CMS_TRANSACTION_LOG_DTL ' ||
                    substr(SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
    END;

    
  EXCEPTION
    --<< main exception >>
 
    WHEN exp_main_reject_record THEN
  	 ROLLBACK;

    BEGIN 
	   -- assign the response code to the out parameter
	   SELECT cms_iso_respcde,cms_resp_desc
	   INTO   p_resp_code_out,p_errmsg_out
	   FROM   cms_response_mast
	   WHERE  cms_inst_code = p_instcode_in AND
			cms_delivery_channel = p_delivery_channel_in AND
			cms_response_id = l_respcode;
	 EXCEPTION
	   WHEN OTHERS THEN
		p_errmsg_out    := 'PROBLEM WHILE SELECTING DATA FROM RESPONSE MASTER ' ||
					    l_respcode || substr(SQLERRM, 1, 300);
		p_resp_code_out := '89';
		ROLLBACK;
		-- return;
	 END;

   
         BEGIN
             SELECT cam_acct_bal, cam_ledger_bal
               INTO L_SRC_ACCT_BALANCE, l_src_ledger_balance
               FROM cms_acct_mast
              WHERE cam_acct_no = l_src_acct_number AND
                  cam_inst_code = p_instcode_in;
         EXCEPTION

             WHEN OTHERS THEN
                l_respcode := '12';
                l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                        SQLERRM;
                RAISE exp_main_reject_record;
         END;


	 --sn create a entry in txn log
	 BEGIN
         INSERT INTO transactionlog
        (msgtype, rrn, delivery_channel, terminal_id, date_time, txn_code,
         txn_type, txn_mode, txn_status, response_code, business_date,
         business_time, customer_card_no, topup_card_no, topup_acct_no,
         topup_acct_type, bank_code, total_amount, currencycode, addcharge,
         productid, categoryid, atm_name_location, auth_id, amount,
         preauthamount, partialamount, instcode, customer_card_no_encr,
         topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
         acct_balance, ledger_balance, response_id, cardstatus, error_msg,
         trans_desc, merchant_name,merchant_state,
         ssn_fail_dtls, store_id, time_stamp, orgnl_card_no,
         tran_reverse_flag)
         VALUES
        (p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
         l_business_date, l_txn_code, l_txn_type, p_txn_mode_in,
         decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
         p_trandate_in, substr(p_trantime_in, 1, 10), l_src_hash_pan, DECODE(l_txn_code,'43',l_trg_hash_pan,''),
         decode(l_txn_code,'43',L_TRG_ACCT_NO,''), NULL, p_instcode_in,
         TRIM(to_char(decode(p_resp_code_out,'00',l_tran_amt,V_TXN_AMT), '99999999999999999.99')), l_currcode,
         NULL, l_src_prod_code, l_src_card_type, p_terminalid_in, l_auth_id,
         TRIM(to_char(decode(p_resp_code_out,'00',l_tran_amt,V_TXN_AMT), '99999999999999999.99')), NULL, NULL,
         p_instcode_in, l_src_encr_pan, l_trg_encr_pan, l_src_proxunumber,
         p_rvsl_code_in, l_src_acct_number, L_SRC_ACCT_BALANCE, l_src_ledger_balance,
         l_respcode, l_src_card_stat, l_errmsg, l_trans_desc,
         p_merchant_name_in,NULL,null,
         p_storeid_in, l_time_stamp, l_src_hash_pan, 'N');
	 EXCEPTION
	   WHEN OTHERS THEN
          p_resp_code_out := '89';
          p_errmsg_out    := 'PROBLEM WHILE INSERTING DATA INTO TRANSACTION LOG  DTL' ||
                    substr(SQLERRM, 1, 300);
	 END;

	 --en create a entry in txn log
	 BEGIN
         INSERT INTO cms_transaction_log_dtl
        (ctd_delivery_channel, ctd_txn_code, ctd_msg_type, ctd_txn_mode,
         ctd_business_date, ctd_business_time, ctd_customer_card_no,
         ctd_txn_amount, ctd_txn_curr, ctd_actual_amount, ctd_fee_amount,
         ctd_waiver_amount, ctd_servicetax_amount, ctd_cess_amount,
         ctd_bill_amount, ctd_bill_curr, ctd_process_flag, ctd_process_msg,
         ctd_rrn, ctd_inst_code, ctd_customer_card_no_encr,
         ctd_cust_acct_number, 
         ctd_location_id, ctd_hashkey_id)
         VALUES
        (p_delivery_channel_in, l_txn_code, p_msg_type_in,
         p_txn_mode_in, p_trandate_in, p_trantime_in, l_src_hash_pan,
         TRIM(to_char(decode(p_resp_code_out,'00',L_SRC_ACCT_BALANCE,V_TXN_AMT), '99999999999999999.99')), l_currcode, 
         TRIM(to_char(decode(p_resp_code_out,'00',L_SRC_ACCT_BALANCE,V_TXN_AMT), '99999999999999999.99')), NULL, NULL, NULL, NULL,
         NULL, NULL, 'E', l_errmsg, p_rrn_in, p_instcode_in, l_src_encr_pan,
         l_src_acct_number,  p_terminalid_in,l_hashkey_id);

       

	   RETURN;
	 EXCEPTION
	   WHEN OTHERS THEN
		l_errmsg        := 'PROBLEM WHILE INSERTING DATA INTO TRANSACTION LOG  DTL' ||
					    substr(SQLERRM, 1, 300);
		p_resp_code_out := '22'; -- server declined
		ROLLBACK;
		RETURN;
	 END;

	

  if  L_DUPCHK_COUNT =1    
    then 

  BEGIN
     SELECT RESPONSE_CODE
       INTO P_RESP_CODE_OUT
       FROM VMSCMS.TRANSACTIONLOG_VW  A,        --Added for VMS-5739/FSP-991
           (SELECT MIN(ADD_INS_DATE) MINDATE
             FROM VMSCMS.TRANSACTIONLOG_VW       --Added for VMS-5739/FSP-991
            WHERE RRN = P_RRN_IN and ACCT_BALANCE is not null) B
      WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN_IN and ACCT_BALANCE is not null;
	

    
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG_OUT    := 'PROBLEM WHILE SELECTING RESPONSE CODE OF ORIGINAL TRANSACTION' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE_OUT := '89'; -- Server Declined
       ROLLBACK;
       RETURN;
  END;

  END IF; 

    WHEN OTHERS THEN
       p_errmsg_out := ' ERROR FROM MAIN ' || substr(SQLERRM, 1, 200);
    
    l_respcode :='89';
     	 ROLLBACK;

    BEGIN 
	   -- assign the response code to the out parameter
	   SELECT cms_iso_respcde,cms_resp_desc
	   INTO   p_resp_code_out,p_errmsg_out
	   FROM   cms_response_mast
	   WHERE  cms_inst_code = p_instcode_in AND
			cms_delivery_channel = p_delivery_channel_in AND
			cms_response_id = l_respcode;
	 EXCEPTION
	   WHEN OTHERS THEN
		p_errmsg_out    := 'PROBLEM WHILE SELECTING DATA FROM RESPONSE MASTER ' ||
					    l_respcode || substr(SQLERRM, 1, 300);
		p_resp_code_out := '89';
		ROLLBACK;
		-- return;
	 END;

   
         BEGIN
             SELECT cam_acct_bal, cam_ledger_bal
               INTO L_SRC_ACCT_BALANCE, l_src_ledger_balance
               FROM cms_acct_mast
              WHERE cam_acct_no = l_src_acct_number AND
                  cam_inst_code = p_instcode_in;
         EXCEPTION

             WHEN OTHERS THEN
                l_respcode := '12';
                l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                        SQLERRM;
                RAISE exp_main_reject_record;
         END;


	 --sn create a entry in txn log
	 BEGIN
         INSERT INTO transactionlog
        (msgtype, rrn, delivery_channel, terminal_id, date_time, txn_code,
         txn_type, txn_mode, txn_status, response_code, business_date,
         business_time, customer_card_no, topup_card_no, topup_acct_no,
         topup_acct_type, bank_code, total_amount, currencycode, addcharge,
         productid, categoryid, atm_name_location, auth_id, amount,
         preauthamount, partialamount, instcode, customer_card_no_encr,
         topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
         acct_balance, ledger_balance, response_id, cardstatus, error_msg,
         trans_desc, merchant_name,merchant_state,
         ssn_fail_dtls, store_id, time_stamp, orgnl_card_no,
         tran_reverse_flag)
         VALUES
        (p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
         l_business_date, l_txn_code, l_txn_type, p_txn_mode_in,
         decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
         p_trandate_in, substr(p_trantime_in, 1, 10), l_src_hash_pan,DECODE(l_txn_code,'43',l_trg_hash_pan,''),
         decode(l_txn_code,'43',L_TRG_ACCT_NO,''), NULL, p_instcode_in,
         TRIM(to_char(decode(p_resp_code_out,'00',l_tran_amt,V_TXN_AMT), '99999999999999999.99')), l_currcode,
         NULL, l_src_prod_code, l_src_card_type, p_terminalid_in, l_auth_id,
         TRIM(to_char(decode(p_resp_code_out,'00',l_tran_amt,V_TXN_AMT), '99999999999999999.99')), NULL, NULL,
         p_instcode_in, l_src_encr_pan, l_trg_encr_pan, l_src_proxunumber,
         p_rvsl_code_in, l_src_acct_number, L_SRC_ACCT_BALANCE, l_src_ledger_balance,
         l_respcode, l_src_card_stat, l_errmsg, l_trans_desc,
         p_merchant_name_in,NULL,null,
         p_storeid_in, l_time_stamp, l_src_hash_pan, 'N');
	 EXCEPTION
	   WHEN OTHERS THEN
          p_resp_code_out := '89';
          p_errmsg_out    := 'PROBLEM WHILE INSERTING DATA INTO TRANSACTION LOG  DTL' ||
                    substr(SQLERRM, 1, 300);
	 END;

	 --en create a entry in txn log
	 BEGIN
         INSERT INTO cms_transaction_log_dtl
        (ctd_delivery_channel, ctd_txn_code, ctd_msg_type, ctd_txn_mode,
         ctd_business_date, ctd_business_time, ctd_customer_card_no,
         ctd_txn_amount, ctd_txn_curr, ctd_actual_amount, ctd_fee_amount,
         ctd_waiver_amount, ctd_servicetax_amount, ctd_cess_amount,
         ctd_bill_amount, ctd_bill_curr, ctd_process_flag, ctd_process_msg,
         ctd_rrn, ctd_inst_code, ctd_customer_card_no_encr,
         ctd_cust_acct_number, 
         ctd_location_id, ctd_hashkey_id)
         VALUES
        (p_delivery_channel_in, l_txn_code, p_msg_type_in,
         p_txn_mode_in, p_trandate_in, p_trantime_in, l_src_hash_pan,
         TRIM(to_char(decode(p_resp_code_out,'00',L_SRC_ACCT_BALANCE,V_TXN_AMT), '99999999999999999.99')), l_currcode,
         TRIM(to_char(decode(p_resp_code_out,'00',L_SRC_ACCT_BALANCE,V_TXN_AMT), '99999999999999999.99')), NULL, NULL, NULL, NULL,
         NULL, NULL, 'E', l_errmsg, p_rrn_in, p_instcode_in, l_src_encr_pan,
         l_src_acct_number,  p_terminalid_in,l_hashkey_id);

       

	   RETURN;
	 EXCEPTION
	   WHEN OTHERS THEN
		l_errmsg        := 'PROBLEM WHILE INSERTING DATA INTO TRANSACTION LOG  DTL' ||
					    substr(SQLERRM, 1, 300);
		p_resp_code_out := '22'; -- server declined
		ROLLBACK;
		RETURN;
	 END;
 
  END balance_transfer;


PROCEDURE BALANCE_TRANSFER_REVERSAL(p_instcode_in         IN NUMBER,
                 p_mbr_numb_in         IN VARCHAR2, 
                 p_msg_type_in         IN VARCHAR2,
                 p_currcode_in         IN VARCHAR2,
                 p_rrn_in              IN VARCHAR2,
                 p_src_card_in         IN VARCHAR2,
                 p_trg_card_in         IN VARCHAR2,
                 p_delivery_channel_in IN VARCHAR2,
                 p_txn_code_in         IN VARCHAR2,
                 p_txn_mode_in         IN VARCHAR2,
                 p_trandate_in         IN VARCHAR2,
                 p_trantime_in         IN VARCHAR2,
                 p_terminalid_in       IN VARCHAR2,
                 p_merchant_name_in    IN VARCHAR2,
                 p_rvsl_code_in        IN VARCHAR2,
                 p_storeid_in          IN VARCHAR2,
                 p_store_add1_in       IN VARCHAR2,
                 p_store_add2_in       IN VARCHAR2,
                 p_store_city_in       IN VARCHAR2,
                 p_store_state_in      IN VARCHAR2,
                 P_Store_Zip_In        In Varchar2,
                 p_trans_amt_in        in varchar2,
                 P_Merchantid_In       In Varchar2,
                 p_locationId_in       in varchar2,
                 p_trg_bal_amt_out     OUT VARCHAR2,
                 p_src_bal_amt_out     OUT VARCHAR2,
                 p_trgt_card_stat_out  OUT VARCHAR2,
                 p_src_card_stat_out   OUT VARCHAR2,
                 p_src_proxy_no_out    OUT VARCHAR2, 
                 p_auth_amnt_out       OUT VARCHAR2,
                 p_errmsg_out          OUT VARCHAR2,
                 p_resp_code_out       OUT VARCHAR2) is 
  
/*************************************************
     * Created  by      : Vini
     * Created For     : VMS-354
     * Created Date    : 04-July-2018
     * Reviewer         : Saravankumar
     * Build Number     : R03

*************************************************/    
    l_orgnl_delivery_channel   transactionlog.delivery_channel%TYPE;
    l_orgnl_resp_code          transactionlog.response_code%TYPE;
    l_orgnl_txn_code           transactionlog.txn_code%TYPE;
    l_orgnl_txn_mode           transactionlog.txn_mode%TYPE;
    l_orgnl_business_date      transactionlog.business_date%TYPE;
    l_orgnl_business_time      transactionlog.business_time%TYPE;
    l_orgnl_customer_card_no   transactionlog.customer_card_no%TYPE;
    l_orgnl_total_amount       transactionlog.amount%TYPE;
    l_reversal_amt             transactionlog.amount%TYPE;
    l_resp_cde                 cms_response_mast.cms_response_id%TYPE;
    l_func_code                cms_func_mast.cfm_func_code%TYPE;
    l_dr_cr_flag               transactionlog.cr_dr_flag%TYPE;
    l_rvsl_trandate            DATE;
    l_errmsg                   VARCHAR2(500);
    l_actual_feecode           transactionlog.feecode%TYPE;
    l_orgnl_tranfee_amt        transactionlog.tranfee_amt%TYPE;
    l_orgnl_servicetax_amt     transactionlog.servicetax_amt%TYPE;
    l_orgnl_cess_amt           transactionlog.cess_amt%TYPE;
    l_orgnl_tranfee_cr_acctno  transactionlog.tranfee_cr_acctno%TYPE;
    l_orgnl_tranfee_dr_acctno  transactionlog.tranfee_dr_acctno%TYPE;
    l_orgnl_st_calc_flag       transactionlog.tran_st_calc_flag%TYPE;
    l_orgnl_cess_calc_flag     transactionlog.tran_cess_calc_flag%TYPE;
    l_orgnl_st_cr_acctno       transactionlog.tran_st_cr_acctno%TYPE;
    l_orgnl_st_dr_acctno       transactionlog.tran_st_dr_acctno%TYPE;
    l_orgnl_cess_cr_acctno     transactionlog.tran_cess_cr_acctno%TYPE;
    l_orgnl_cess_dr_acctno     transactionlog.tran_cess_dr_acctno%TYPE;
    l_src_prod_code            cms_appl_pan.cap_prod_code%TYPE;
    l_trg_prod_code            cms_appl_pan.cap_prod_code%TYPE;
    l_src_card_type            cms_appl_pan.cap_card_type%TYPE;
    l_tran_reverse_flag        transactionlog.tran_reverse_flag%TYPE;
    l_curr_code                transactionlog.currencycode%TYPE;
    l_auth_id                  transactionlog.auth_id%TYPE;
    l_cutoff_time              VARCHAR2(5);
    exp_rvsl_reject_record     EXCEPTION;
    l_src_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
    l_trg_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
    l_src_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
    l_trg_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
    l_card_curr                cms_inst_param.cip_param_value%TYPE;
    l_base_curr                cms_inst_param.cip_param_value%TYPE;
    l_currcode                 cms_inst_param.cip_param_value%TYPE;
    l_acct_balance             cms_acct_mast.cam_acct_bal%TYPE;
    l_ledger_balance           cms_acct_mast.cam_ledger_bal%TYPE;
    l_src_ledger_balance       cms_acct_mast.cam_ledger_bal%TYPE;
    l_tran_desc                cms_transaction_mast.ctm_tran_desc%TYPE;
    l_trg_cust_code            cms_cust_mast.ccm_cust_code%TYPE;   
    l_trg_acct_no              cms_appl_pan.cap_acct_no%TYPE;
    l_trg_cap_acct_id          cms_appl_pan.cap_acct_id%type;
    l_trg_cust_no              cms_appl_pan.cap_cust_code%type;    
    l_trg_txn_business_date    transactionlog.business_date%TYPE;
    l_trg_txn_business_time    transactionlog.business_time%TYPE;
    l_trg_txn_rrn              transactionlog.rrn%TYPE;
    l_trg_txn_terminalid       transactionlog.terminal_id%TYPE;
    l_trg_oldcrd_encr          cms_appl_pan.cap_pan_code_encr%TYPE;
    l_trg_oldcrd               cms_appl_pan.cap_pan_code%TYPE;
    l_trg_old_stat             cms_appl_pan.cap_card_stat%TYPE; 
    l_trg_old_txn_code         transactionlog.txn_code%TYPE;
    l_src_old_stat             cms_appl_pan.cap_card_stat%TYPE; 
    l_src_old_txn_code         transactionlog.txn_code%TYPE;
    l_src_proxunumber          cms_appl_pan.cap_proxy_number%TYPE;
    l_src_acct_number          cms_appl_pan.cap_acct_no%TYPE;
    l_txn_narration            cms_statements_log.csl_trans_narrration%TYPE;
    l_fee_narration            cms_statements_log.csl_trans_narrration%TYPE;
    l_src_cardstat             transactionlog.cardstatus%TYPE;
    l_txn_merchname            cms_statements_log.csl_merchant_name%TYPE;
    l_fee_merchname            cms_statements_log.csl_merchant_name%TYPE;
    l_txn_merchcity            cms_statements_log.csl_merchant_city%TYPE;
    l_fee_merchcity            cms_statements_log.csl_merchant_city%TYPE;
    l_txn_merchstate           cms_statements_log.csl_merchant_state%TYPE;
    l_fee_merchstate           cms_statements_log.csl_merchant_state%TYPE;
    l_trg_appl_code            cms_appl_pan.cap_appl_code%TYPE;
    l_trg_acct_id              cms_appl_pan.cap_acct_id%TYPE;
    l_cam_type_code            cms_acct_mast.cam_type_code%TYPE;
    l_timestamp                TIMESTAMP;
    l_txn_type                 transactionlog.txn_type%TYPE;
    l_tran_date                DATE;
    l_fee_plan                 cms_fee_plan.cfp_plan_id%TYPE;
    l_fee_amt                  transactionlog.amount%TYPE;
    l_fee_code                 cms_fee_mast.cfm_fee_code%TYPE;
    l_feeattach_type           VARCHAR2(2);
    l_src_hashkey_id           cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
    l_trg_cardactive_dt        cms_appl_pan.cap_active_date%TYPE;
    l_txn_code                 cms_transaction_mast.ctm_tran_code%TYPE;
    L_Bill_Addr 			   Cms_Appl_Pan.Cap_Bill_Addr%Type; 
	  l_dupchk_count		       number;
    l_dupchk_cardstat          transactionlog.cardstatus%TYPE;   
    L_Dupchk_Acctbal           Transactionlog.Acct_Balance%Type; 
    L_Trg_Cler_Pan    Number;
    l_tran_type             cms_transaction_mast.ctm_tran_type%type;
    L_Prfl_Flag             Cms_Transaction_Mast.Ctm_Prfl_Flag%Type;
    
    L_Trg_Acct_Balance        Cms_Acct_Mast.Cam_Acct_Bal%Type; 
    l_trg_ledger_balance   Cms_Acct_Mast.Cam_Ledger_Bal%Type;
    l_remark     varchar2(200); 
  
    
   L_TRG_Prfl_Code        Cms_Appl_Pan.Cap_Prfl_Code%Type; 
 
   l_add_ins_date         transactionlog.add_ins_date %type;
   
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
  BEGIN
    p_resp_code_out := '00';
    l_errmsg := 'OK';
    p_errmsg_out := 'Success';
  
    l_timestamp := systimestamp;
  
  
  
    BEGIN
        l_src_hash_pan := gethash(p_src_card_in);
        EXCEPTION
         WHEN OTHERS THEN
           l_errmsg := 'Error while converting hash pan ' ||
              substr(SQLERRM, 1, 200);
           RAISE exp_rvsl_reject_record;
    END;
  
    --EN CREATE HASH PAN
  
    --SN create encr pan
    BEGIN
        l_src_encr_pan := fn_emaps_main(p_src_card_in);
        EXCEPTION
         WHEN OTHERS THEN
           l_errmsg := 'Error while converting encr pan ' ||
              substr(SQLERRM, 1, 200);
           RAISE exp_rvsl_reject_record;
    END;
  
    --EN create encr pan

--    BEGIN
--        l_trg_hash_pan := gethash(p_trg_card_in);
--        EXCEPTION
--         WHEN OTHERS THEN
--           l_errmsg := 'Error while converting hash pan ' ||
--              substr(SQLERRM, 1, 200);
--           RAISE exp_rvsl_reject_record;
--    END;
--
--
--    BEGIN
--        l_trg_encr_pan := fn_emaps_main(p_trg_card_in);
--        EXCEPTION
--         WHEN OTHERS THEN
--           l_errmsg := 'Error while converting encr pan ' ||
--              substr(SQLERRM, 1, 200);
--           RAISE exp_rvsl_reject_record;
--    END;

 -- call lp procedure
 
 l_txn_code  := p_txn_code_in;
     begin
     lp_trans_details(p_instcode_in ,p_delivery_channel_in ,l_txn_code ,p_src_card_in,p_rrn_in,l_timestamp,l_src_hashkey_id,l_dr_cr_flag ,l_txn_type ,l_tran_type,l_prfl_flag,l_tran_desc,l_resp_cde ,l_errmsg);
     If L_Errmsg <> 'OK' Then
     	raise exp_rvsl_reject_record;
     end if;
     EXCEPTION WHEN  exp_rvsl_reject_record THEN
     RAISE;
     WHEN OTHERS THEN
      l_resp_cde := '89';
            l_errmsg   := 'ERROR WHILE SELECTING SOURCE CARD DETAILS ' ||
                    substr(SQLERRM, 1, 200);
            Raise exp_rvsl_reject_record;
   end;


    
    --Sn get date
    BEGIN
        l_rvsl_trandate := to_date(substr(TRIM(p_trandate_in), 1, 8) || ' ' ||
                     substr(TRIM(p_trantime_in), 1, 8),
                     'yyyymmdd hh24:mi:ss');
        l_tran_date := l_rvsl_trandate;
    
        EXCEPTION
         WHEN OTHERS THEN
           l_resp_cde := '89';
           l_errmsg   := 'Problem while converting transaction date ' ||
                substr(SQLERRM, 1, 200);
           RAISE exp_rvsl_reject_record;
    END;
  
    --En get date
  
    --Sn generate auth id
    BEGIN
    
	    SELECT lpad(seq_auth_id.NEXTVAL, 6, '0') INTO l_auth_id FROM dual;
		
      EXCEPTION
       WHEN OTHERS THEN
         l_errmsg   := 'Error while generating authid ' ||
              substr(SQLERRM, 1, 300);
         l_resp_cde := '89';
         RAISE exp_rvsl_reject_record;
    END;
  
    BEGIN
        IF p_currcode_in IS NULL 
        THEN
           BEGIN
              SELECT cip_param_value
                INTO l_base_curr
                FROM cms_inst_param
               WHERE cip_inst_code = p_instcode_in 
                 AND cip_param_key = 'CURRENCY';
               
              IF TRIM(l_base_curr) IS NULL
              THEN
                l_errmsg := 'Base currency cannot be null ';
                RAISE exp_rvsl_reject_record;
              END IF;
              
              EXCEPTION
                  WHEN exp_rvsl_reject_record THEN
                    RAISE;
                  WHEN no_data_found THEN
                    l_errmsg := 'Base currency is not defined for the institution ';
                    RAISE exp_rvsl_reject_record;
                  WHEN OTHERS THEN
                    l_errmsg := 'Error while selecting base currency  ' ||
                        substr(SQLERRM, 1, 200);
                    RAISE exp_rvsl_reject_record;
           END;
           l_currcode := l_base_curr;
        ELSE
           l_currcode := p_currcode_in;
        END IF;
    END;
  
    BEGIN
        SELECT cap_proxy_number, cap_acct_no, 
               cap_card_stat, cap_prod_code,
               cap_card_type
          INTO l_src_proxunumber, l_src_acct_number, 
               l_src_cardstat, l_src_prod_code,
               l_src_card_type
          FROM cms_appl_pan
         WHERE cap_inst_code = p_instcode_in 
           AND cap_pan_code = l_src_hash_pan 
           AND cap_mbr_numb = p_mbr_numb_in;
        
        EXCEPTION
             WHEN exp_rvsl_reject_record THEN
               RAISE;
             WHEN no_data_found THEN
               l_errmsg   := 'Error while Fetching Prod Code  type - No Data found';
               l_resp_cde := '89';
               RAISE exp_rvsl_reject_record;
             WHEN OTHERS THEN
               l_errmsg   := 'Error while Fetching Prod Code  type ' ||
                    substr(SQLERRM, 1, 200);
               l_resp_cde := '89';
               RAISE exp_rvsl_reject_record;
    END;

   Begin
        SELECT CAP_PAN_CODE,cap_pan_code_encr,fn_dmaps_main(cap_pan_code_encr),cap_prfl_code
        INTO l_trg_hash_pan,l_trg_encr_pan,l_trg_cler_pan,L_TRG_Prfl_Code
        FROM CMS_APPL_PAN
        WHERE CAP_SERIAL_NUMBER=p_trg_card_in and CAP_FORM_FACTOR is null
        AND cap_mbr_numb=p_mbr_numb_in
        AND cap_inst_code = p_instcode_in;
       EXCEPTION
       WHEN no_data_found THEN
          Begin
            Select Cap_Pan_Code,Cap_Pan_Code_Encr,Fn_Dmaps_Main(Cap_Pan_Code_Encr),Cap_Prfl_Code
            INTO l_trg_hash_pan,l_trg_encr_pan,l_trg_cler_pan,L_TRG_Prfl_Code
            FROM CMS_APPL_PAN
            WHERE cap_pan_code=gethash(p_trg_card_in)
            AND cap_mbr_numb=p_mbr_numb_in
            AND cap_inst_code = p_instcode_in;
           EXCEPTION
            WHEN no_data_found THEN
            l_resp_cde := '49';
            l_errmsg   := 'Target Card Not Found';
            RAISE exp_rvsl_reject_record;
          END;
   	    WHEN OTHERS THEN
            l_resp_cde := '89';
            l_errmsg   := 'ERROR WHILE SELECTING TARGET CARD DETAILS ' ||
                    substr(SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      
      END;


    BEGIN
        SELECT z.ccp_business_time, z.ccp_business_date, 
               z.ccp_rrn, z.ccp_terminal_id,
               z.ccp_acct_no, z.ccp_acct_id,
               z.ccp_cust_code
          INTO l_trg_txn_business_time, l_trg_txn_business_date,
               l_trg_txn_rrn, l_trg_txn_terminalid,
               l_trg_acct_no, l_trg_acct_id, 
               l_trg_cust_no
          FROM (SELECT ccp_business_time, ccp_business_date, 
                       ccp_rrn, ccp_terminal_id,
                       ccp_acct_no,ccp_acct_id,ccp_cust_code
                  FROM cms_cardprofile_hist
                 WHERE ccp_pan_code = l_trg_hash_pan 
                   AND ccp_inst_code = p_instcode_in 
                   AND ccp_mbr_numb = p_mbr_numb_in
               ORDER BY ccp_ins_date DESC) z
         WHERE rownum = 1;
        EXCEPTION
             WHEN no_data_found THEN
               l_resp_cde := '53';
               l_errmsg   := 'No Balance transfer was done';
               RAISE exp_rvsl_reject_record;
             WHEN OTHERS THEN
               l_resp_cde := '89';
               l_errmsg   := 'Cannot get the Balance transfer details' || ' ' ||
                    substr(SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
    END;
  
 
    --Sn check orginal transaction    
   BEGIN
       SELECT delivery_channel, response_code, txn_code,
              txn_mode, business_date, business_time,
              customer_card_no, amount, feecode, 
              tranfee_amt, servicetax_amt, cess_amt,
              tranfee_cr_acctno, tranfee_dr_acctno, 
              tran_st_calc_flag, tran_cess_calc_flag, 
              tran_st_cr_acctno, tran_st_dr_acctno,
              tran_cess_cr_acctno, tran_cess_dr_acctno, 
              currencycode, tran_reverse_flag,add_ins_date
         INTO l_orgnl_delivery_channel, l_orgnl_resp_code, l_orgnl_txn_code, 
              l_orgnl_txn_mode, l_orgnl_business_date, l_orgnl_business_time,
              l_orgnl_customer_card_no, l_orgnl_total_amount, l_actual_feecode, 
              l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,l_orgnl_cess_amt, 
              l_orgnl_tranfee_cr_acctno, l_orgnl_tranfee_dr_acctno, 
              l_orgnl_st_calc_flag, l_orgnl_cess_calc_flag, 
              l_orgnl_st_cr_acctno, l_orgnl_st_dr_acctno, 
              L_Orgnl_Cess_Cr_Acctno, L_Orgnl_Cess_Dr_Acctno, 
              l_curr_code, l_tran_reverse_flag,l_add_ins_date
         FROM VMSCMS.TRANSACTIONLOG						--Added for VMS-5739/FSP-991
        WHERE rrn = p_rrn_in
          AND customer_card_no = l_src_hash_pan 
          AND instcode = p_instcode_in 
          And Delivery_Channel = P_Delivery_Channel_In
         -- AND txn_code = p_txn_code_in
          AND msgtype = '1200';
		  IF SQL%ROWCOUNT = 0 THEN
		  SELECT delivery_channel, response_code, txn_code,
              txn_mode, business_date, business_time,
              customer_card_no, amount, feecode, 
              tranfee_amt, servicetax_amt, cess_amt,
              tranfee_cr_acctno, tranfee_dr_acctno, 
              tran_st_calc_flag, tran_cess_calc_flag, 
              tran_st_cr_acctno, tran_st_dr_acctno,
              tran_cess_cr_acctno, tran_cess_dr_acctno, 
              currencycode, tran_reverse_flag,add_ins_date
         INTO l_orgnl_delivery_channel, l_orgnl_resp_code, l_orgnl_txn_code, 
              l_orgnl_txn_mode, l_orgnl_business_date, l_orgnl_business_time,
              l_orgnl_customer_card_no, l_orgnl_total_amount, l_actual_feecode, 
              l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,l_orgnl_cess_amt, 
              l_orgnl_tranfee_cr_acctno, l_orgnl_tranfee_dr_acctno, 
              l_orgnl_st_calc_flag, l_orgnl_cess_calc_flag, 
              l_orgnl_st_cr_acctno, l_orgnl_st_dr_acctno, 
              L_Orgnl_Cess_Cr_Acctno, L_Orgnl_Cess_Dr_Acctno, 
              l_curr_code, l_tran_reverse_flag,l_add_ins_date
         FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST 							--Added for VMS-5739/FSP-991
        WHERE rrn = p_rrn_in
          AND customer_card_no = l_src_hash_pan 
          AND instcode = p_instcode_in 
          And Delivery_Channel = P_Delivery_Channel_In
         -- AND txn_code = p_txn_code_in
          AND msgtype = '1200';
		  END IF;
        EXCEPTION
           WHEN no_data_found THEN
             l_resp_cde := '89';
             l_errmsg   := 'Matching transaction not found';
             RAISE exp_rvsl_reject_record;
           WHEN too_many_rows THEN
             l_resp_cde := '89';
             l_errmsg   := 'More than one matching record found in the master';
             RAISE exp_rvsl_reject_record;
           WHEN OTHERS THEN
             l_resp_cde := '89';
             l_errmsg   := 'Error while selecting master data' ||
                  substr(SQLERRM, 1, 200);
             RAISE exp_rvsl_reject_record;  
   End;
     If l_orgnl_txn_code ='43' then 
     l_txn_code :=l_orgnl_txn_code;
        begin
     lp_trans_details(p_instcode_in ,p_delivery_channel_in ,l_orgnl_txn_code ,p_src_card_in,p_rrn_in,l_timestamp,l_src_hashkey_id,l_dr_cr_flag ,l_txn_type ,l_tran_type,l_prfl_flag,l_tran_desc,l_resp_cde ,l_errmsg);
          If L_Errmsg <> 'OK' Then
     	raise exp_rvsl_reject_record;
     end if;
     EXCEPTION 
     WHEN  exp_rvsl_reject_record THEN
     RAISE;
     WHEN OTHERS THEN
      l_resp_cde := '89';
            l_errmsg   := 'ERROR WHILE SELECTING SOURCE CARD DETAILS ' ||
                    substr(SQLERRM, 1, 200);
            Raise Exp_Rvsl_Reject_Record;
   end;
   end if; 
       
   IF l_orgnl_resp_code <> '00'
   THEN
       l_resp_cde := '53';
       l_errmsg   := ' The original transaction was not successful';
       RAISE exp_rvsl_reject_record;
   END IF;
        
   IF l_tran_reverse_flag = 'Y'
   THEN
       BEGIN
          SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
            INTO l_dupchk_cardstat, l_dupchk_acctbal
            FROM (SELECT CARDSTATUS, ACCT_BALANCE  
                    FROM VMSCMS.TRANSACTIONLOG 										--Added for VMS-5739/FSP-991
                   WHERE RRN = p_rrn_in 
                     AND CUSTOMER_CARD_NO = l_src_hash_pan 
                     AND DELIVERY_CHANNEL = p_delivery_channel_in
                     AND ACCT_BALANCE IS NOT NULL
                ORDER BY add_ins_date DESC)
          WHERE ROWNUM = 1;
		    IF SQL%ROWCOUNT = 0 THEN
			  SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
            INTO l_dupchk_cardstat, l_dupchk_acctbal
            FROM (SELECT CARDSTATUS, ACCT_BALANCE  
                    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST										--Added for VMS-5739/FSP-991
                   WHERE RRN = p_rrn_in 
                     AND CUSTOMER_CARD_NO = l_src_hash_pan 
                     AND DELIVERY_CHANNEL = p_delivery_channel_in
                     AND ACCT_BALANCE IS NOT NULL
                ORDER BY add_ins_date DESC)
          WHERE ROWNUM = 1;
			END IF;
  
          l_DUPCHK_COUNT:=1;
          EXCEPTION
            WHEN no_data_found THEN
                l_DUPCHK_COUNT:=0;
            WHEN OTHERS THEN
                l_resp_cde := '89';
                l_errmsg   := 'Error while selecting card status and acct balance ' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_RVSL_REJECT_RECORD;
        END;

        IF l_DUPCHK_COUNT =1 THEN
            BEGIN
                SELECT CAM_ACCT_BAL
                  INTO l_ACCT_BALANCE
                  FROM CMS_ACCT_MAST
                 WHERE CAM_ACCT_NO = l_src_acct_number
                   AND CAM_INST_CODE = p_instcode_in;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        l_resp_cde := '12';
                        l_errmsg   := 'Error while selecting acct balance ' || SUBSTR(SQLERRM, 1, 200);
                        RAISE exp_rvsl_reject_record;
            END;
    
            L_DUPCHK_COUNT:=0;
                       
            IF l_DUPCHK_CARDSTAT= l_src_cardstat and l_DUPCHK_ACCTBAL=l_ACCT_BALANCE then
                l_DUPCHK_COUNT:=1;
                l_resp_cde := '52';
                l_errmsg   := 'Reversal already done';
                RAISE exp_rvsl_reject_record;
            END IF;
            
        END IF;
   END IF;
  
   
   BEGIN
      SELECT cap_active_date, cap_appl_code, 
             cap_cust_code, cap_prod_code,
             cap_acct_id
        INTO l_trg_cardactive_dt, l_trg_appl_code, 
             l_trg_cust_code, l_trg_prod_code,
             l_trg_cap_acct_id
        FROM cms_appl_pan
       WHERE cap_inst_code = p_instcode_in 
         AND cap_pan_code = l_trg_hash_pan 
         AND cap_mbr_numb = p_mbr_numb_in;
      
      IF l_trg_cardactive_dt IS NULL
      THEN
         l_resp_cde := '8';
         l_errmsg   := 'Balance transfer Reversal Cannot be done., Balance transfer Not done for this card';
         RAISE exp_rvsl_reject_record;
      END IF;
      
      EXCEPTION
         WHEN exp_rvsl_reject_record THEN
              RAISE;
         WHEN no_data_found THEN
              l_errmsg   := 'Error while Fetching Prod Code  type - No Data found';
              l_resp_cde := '89';
              RAISE exp_rvsl_reject_record;
         WHEN OTHERS THEN
              l_errmsg   := 'Error while Fetching Prod Code  type ' ||
                    substr(SQLERRM, 1, 200);
              l_resp_cde := '89';
              RAISE exp_rvsl_reject_record;
    END; 
    --En check orginal transaction
  
   BEGIN
       vmsfunutilities.get_currency_code(l_src_prod_code,l_src_card_type,p_instcode_in,l_card_curr,l_errmsg);
       IF l_errmsg <> 'OK' THEN
          l_resp_cde := '89';
          RAISE exp_rvsl_reject_record;
       END IF;
        
       EXCEPTION
          WHEN exp_rvsl_reject_record THEN
              RAISE;
          WHEN OTHERS THEN
              l_resp_cde := '69'; 
              l_errmsg   := 'Error from currency conversion ' ||
                      substr(SQLERRM, 1, 200);
              RAISE exp_rvsl_reject_record;
	 END;
     
   l_reversal_amt := l_orgnl_total_amount; 
  
    --Sn find the type of orginal txn (credit or debit)
          --   BEGIN
          --       SELECT ctm_credit_debit_flag, ctm_tran_desc,
          --              to_number(decode(ctm_tran_type, 'N', '0', 'F', '1'))
          --         INTO l_dr_cr_flag, l_tran_desc, l_txn_type
          --         FROM cms_transaction_mast
          --        WHERE ctm_tran_code = p_txn_code_in 
          --          AND ctm_delivery_channel = p_delivery_channel_in 
          --          AND ctm_inst_code = p_instcode_in;
          --          
          --        EXCEPTION
          --           WHEN no_data_found THEN
          --               l_resp_cde := '89';
          --               l_errmsg   := 'Transaction detail is not found in master for orginal txn code' ||
          --                    p_txn_code_in || 'delivery channel ' ||
          --                    p_delivery_channel_in;
          --               RAISE exp_rvsl_reject_record;
          --           WHEN OTHERS THEN
          --               l_resp_cde := '89';
          --               l_errmsg   := 'Problem while selecting debit/credit flag ' ||
          --                    substr(SQLERRM, 1, 200);
          --               RAISE exp_rvsl_reject_record;
          --    END;
  
    --En find the type of orginal txn (credit or debit)
    IF l_dr_cr_flag = 'NA' THEN
       l_resp_cde := '89';
       l_errmsg   := 'Not a valid orginal transaction for reversal';
       RAISE exp_rvsl_reject_record;
    END IF;
  
    ---Sn find cutoff time
    BEGIN
       SELECT cip_param_value
         INTO l_cutoff_time
         FROM cms_inst_param
        WHERE cip_param_key = 'CUTOFF' 
          AND cip_inst_code = p_instcode_in;
          
       EXCEPTION
           WHEN no_data_found THEN
                l_cutoff_time := 0;
                l_resp_cde    := '89';
                l_errmsg      := 'Cutoff time is not defined in the system';
                RAISE exp_rvsl_reject_record;
           WHEN OTHERS THEN
                l_resp_cde := '89';
                l_errmsg   := 'Error while selecting cutoff  dtl  from system ' || ' ' ||
                     substr(SQLERRM, 1, 200);
                RAISE exp_rvsl_reject_record;
    END;
  
    ---En find cutoff time
    BEGIN
       SELECT cam_type_code
         INTO l_cam_type_code
         FROM cms_acct_mast
        WHERE cam_acct_no = l_trg_acct_no 
          AND cam_inst_code = p_instcode_in;
       EXCEPTION
           WHEN no_data_found THEN
               l_resp_cde := '12';
               l_errmsg   := 'Invalid Card ';
               RAISE exp_rvsl_reject_record;
           WHEN OTHERS THEN
               l_resp_cde := '12';
               l_errmsg   := 'Error while selecting data from card Master for card number  ' || ' ' ||
                    substr(SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
    END;
    
    --Sn find narration
  
    BEGIN
	--Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)					--Added for VMS-5739/FSP-991

    THEN
       SELECT csl_trans_narrration, csl_merchant_name, 
              csl_merchant_city, csl_merchant_state
         INTO l_txn_narration, l_txn_merchname, 
              l_txn_merchcity, l_txn_merchstate
         FROM cms_statements_log
        WHERE csl_business_date = l_orgnl_business_date 
          AND csl_business_time = l_orgnl_business_time 
          AND csl_rrn = l_trg_txn_rrn 
          AND csl_delivery_channel = l_orgnl_delivery_channel 
          AND csl_txn_code = l_orgnl_txn_code 
          AND csl_pan_no = l_orgnl_customer_card_no 
          AND csl_inst_code = p_instcode_in 
          AND txn_fee_flag = 'N';
		  
ELSE
		SELECT csl_trans_narrration, csl_merchant_name, 
              csl_merchant_city, csl_merchant_state
         INTO l_txn_narration, l_txn_merchname, 
              l_txn_merchcity, l_txn_merchstate
         FROM VMSCMS_HISTORY.cms_statements_log_HIST 					--Added for VMS-5739/FSP-991
        WHERE csl_business_date = l_orgnl_business_date 
          AND csl_business_time = l_orgnl_business_time 
          AND csl_rrn = l_trg_txn_rrn 
          AND csl_delivery_channel = l_orgnl_delivery_channel 
          AND csl_txn_code = l_orgnl_txn_code 
          AND csl_pan_no = l_orgnl_customer_card_no 
          AND csl_inst_code = p_instcode_in 
          AND txn_fee_flag = 'N';
END IF;		  
       EXCEPTION
           WHEN no_data_found THEN
             l_txn_narration := NULL;
           WHEN OTHERS THEN
             l_txn_narration := NULL;
    END;
        
     IF l_orgnl_tranfee_amt > 0 THEN
        BEGIN
		--Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)							--Added for VMS-5739/FSP-991
    THEN
            SELECT csl_trans_narrration, csl_merchant_name,
                   csl_merchant_city, csl_merchant_state
              INTO l_fee_narration, l_fee_merchname, 
                   l_fee_merchcity, l_fee_merchstate
              FROM cms_statements_log
             WHERE csl_business_date = l_orgnl_business_date 
               AND csl_business_time = l_orgnl_business_time 
               AND csl_rrn = l_trg_txn_rrn 
               AND csl_delivery_channel = l_orgnl_delivery_channel 
               AND csl_txn_code = l_orgnl_txn_code 
               AND csl_pan_no = l_orgnl_customer_card_no 
               AND csl_inst_code = p_instcode_in 
               AND txn_fee_flag = 'Y';
ELSE
			
            SELECT csl_trans_narrration, csl_merchant_name,
                   csl_merchant_city, csl_merchant_state
              INTO l_fee_narration, l_fee_merchname, 
                   l_fee_merchcity, l_fee_merchstate
              FROM VMSCMS_HISTORY.cms_statements_log_HIST                   --Added for VMS-5739/FSP-991
             WHERE csl_business_date = l_orgnl_business_date 
               AND csl_business_time = l_orgnl_business_time 
               AND csl_rrn = l_trg_txn_rrn 
               AND csl_delivery_channel = l_orgnl_delivery_channel 
               AND csl_txn_code = l_orgnl_txn_code 
               AND csl_pan_no = l_orgnl_customer_card_no 
               AND csl_inst_code = p_instcode_in 
               AND txn_fee_flag = 'Y';

END IF;			   
             
             EXCEPTION
                WHEN no_data_found THEN
                    l_fee_narration := NULL;
                WHEN OTHERS THEN
                    l_fee_narration := NULL;
        END;
     END IF;
       
  
    --En find narration
  
    --Sn reverse the amount
     BEGIN
        sp_reverse_card_amount(p_instcode_in, l_func_code, p_rrn_in,
                               p_delivery_channel_in, l_trg_txn_terminalid, 
                               NULL, l_orgnl_txn_code, l_rvsl_trandate,
                               p_txn_mode_in, p_src_card_in, l_reversal_amt,
                               l_trg_txn_rrn, l_src_acct_number,
                               p_trandate_in, p_trantime_in,
                               l_auth_id, l_txn_narration,
                               l_orgnl_business_date, l_orgnl_business_time,
                               l_txn_merchname, l_txn_merchcity,
                               l_txn_merchstate, l_resp_cde, l_errmsg);
    
        IF l_resp_cde <> '00' OR l_errmsg <> 'OK' THEN
           RAISE exp_rvsl_reject_record;
        END IF;
        
        EXCEPTION
             WHEN exp_rvsl_reject_record THEN
               RAISE;
             WHEN OTHERS THEN
               l_resp_cde := '89';
               l_errmsg   := 'Error while reversing the amount ' ||
                    substr(SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
     END;
  
    --En reverse the amount
    --Sn reverse the fee
     BEGIN
    
         sp_reverse_fee_amount(p_instcode_in, p_rrn_in, p_delivery_channel_in,
                              l_trg_txn_terminalid, NULL, l_orgnl_txn_code,
                              l_rvsl_trandate, p_txn_mode_in,
                              l_orgnl_tranfee_amt, p_src_card_in,
                              l_actual_feecode, l_orgnl_tranfee_amt,
                              l_orgnl_tranfee_cr_acctno,
                              l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
                              l_orgnl_servicetax_amt, l_orgnl_st_cr_acctno,
                              l_orgnl_st_dr_acctno, l_orgnl_cess_calc_flag,
                              l_orgnl_cess_amt, l_orgnl_cess_cr_acctno,
                              l_orgnl_cess_dr_acctno, l_trg_txn_rrn,
                              l_src_acct_number, p_trandate_in,
                              p_trantime_in, l_auth_id, l_fee_narration,
                              l_fee_merchname, l_fee_merchcity,
                              l_fee_merchstate, l_resp_cde, l_errmsg);
          
         IF l_resp_cde <> '00' OR l_errmsg <> 'OK'
         THEN
            RAISE exp_rvsl_reject_record;
         END IF;
          
         EXCEPTION
             WHEN exp_rvsl_reject_record THEN
               RAISE;
             WHEN OTHERS THEN
               l_resp_cde := '89';
               l_errmsg   := 'Error while reversing the fee amount ' ||
                    substr(SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
    END;
  
   
   BEGIN    
      IF (L_TRG_Prfl_Code IS NOT NULL AND l_prfl_flag = 'Y')  THEN
               Pkg_Limits_Check.Sp_Limitcnt_Rever_Reset
                               (P_Instcode_In,
                                null,  
                                Null,
                                NULL,
                                l_txn_code,
                                L_Tran_Type,
                                NULL,
                                Null,
                                L_TRG_Prfl_Code,
                                l_reversal_amt,
                                l_reversal_amt,
                                P_Delivery_Channel_In,
                                L_Trg_Hash_Pan,
                                l_add_ins_date,
                                l_resp_cde,
                                l_errmsg
                              );
                              
      IF l_errmsg <> 'OK'
         THEN
             Raise Exp_Rvsl_Reject_Record;
         END IF;
 

     End If;
  EXCEPTION
             WHEN exp_rvsl_reject_record THEN
               RAISE;
             WHEN OTHERS THEN
               l_resp_cde := '89';
               l_errmsg   := 'Error while Sp_Limitcnt_Rever_Reset ' ||
                    substr(SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;

       END;
  
    --En reverse the fee    
    l_resp_cde := '1';
    BEGIN
      sp_tran_reversal_fees(p_instcode_in, p_src_card_in, p_delivery_channel_in,
                            l_orgnl_txn_mode, l_orgnl_txn_code, p_currcode_in,
                            NULL, NULL, l_reversal_amt, p_trandate_in,
                            p_trantime_in, NULL, NULL, l_resp_cde,
                            p_msg_type_in, p_mbr_numb_in, p_rrn_in,
                            p_terminalid_in, l_txn_merchname,
                            l_txn_merchcity, l_auth_id, l_fee_merchstate,
                            p_rvsl_code_in, l_txn_narration, l_txn_type,
                            l_tran_date, l_errmsg, l_resp_cde, l_fee_amt,
                            l_fee_plan, l_fee_code, l_feeattach_type);
    
         IF l_errmsg <> 'OK'
         THEN
             RAISE exp_rvsl_reject_record;
         END IF;
    END;
  
    BEGIN
         IF l_errmsg = 'OK' THEN
           INSERT INTO cms_transaction_log_dtl
          (ctd_delivery_channel, ctd_txn_code, ctd_txn_type, ctd_msg_type,
           ctd_txn_mode, ctd_business_date, ctd_business_time,
           ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
           ctd_actual_amount, ctd_bill_amount, ctd_bill_curr,
           ctd_process_flag, ctd_process_msg, ctd_rrn, ctd_inst_code,
           ctd_customer_card_no_encr, ctd_cust_acct_number, 
           ctd_hashkey_id, ctd_location_id, ctd_store_address1, ctd_store_address2, 
           ctd_store_city, ctd_store_state, ctd_store_zip)
           VALUES
          (p_delivery_channel_in, l_orgnl_txn_code, '1', p_msg_type_in,
           p_txn_mode_in, p_trandate_in, p_trantime_in,
           l_src_hash_pan, l_reversal_amt, l_currcode,
           l_reversal_amt, l_reversal_amt, l_card_curr,
           'Y', 'Successful', p_rrn_in, p_instcode_in, 
           l_src_encr_pan, l_src_acct_number, 
           l_src_hashkey_id, p_terminalid_in, p_store_add1_in, p_store_add2_in, 
           p_store_city_in, p_store_state_in, p_store_zip_in);
         END IF;
         EXCEPTION
             WHEN OTHERS THEN
                   l_errmsg   := 'Problem while inserting data in to CMS_TRANSACTION_LOG_DTL ' ||
                        substr(SQLERRM, 1, 300);
                   l_resp_cde := '89';
                   RAISE exp_rvsl_reject_record;
    END;
  
  
  If  L_Orgnl_Txn_Code ='41' Then
  
    BEGIN
        SELECT CAM_ADDR_CODE 
          INTO L_BILL_ADDR 
          FROM CMS_ADDR_MAST 
         WHERE CAM_CUST_CODE=l_trg_cust_no 
           AND CAM_ADDR_FLAG='P' 
           AND CAM_INST_CODE=p_instcode_in;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
              SELECT CAM_ADDR_CODE INTO L_BILL_ADDR FROM CMS_ADDR_MAST WHERE
              CAM_CUST_CODE=l_trg_cust_no AND CAM_ADDR_FLAG='O' AND CAM_INST_CODE=p_instcode_in;
            WHEN OTHERS THEN
              l_errmsg := 'Problem while updating billing address ' || SUBSTR(
              SQLERRM, 1, 100);
              l_resp_cde := '89';
              RAISE EXP_RVSL_REJECT_RECORD;
    END;
  
    BEGIN    
       UPDATE cms_smsandemail_alert
          SET csa_loadorcredit_flag = 0, csa_lowbal_flag = 0,
              csa_negbal_flag = 0, csa_highauthamt_flag = 0,
              csa_dailybal_flag = 0, csa_insuff_flag = 0,
              csa_incorrpin_flag = 0, csa_fast50_flag = 0,
              csa_fedtax_refund_flag = 0, csa_cellphonecarrier = 0,
              csa_c2c_flag = NULL, csa_lupd_date = SYSDATE,
              csa_lowbal_amt = NULL, csa_highauthamt = NULL,
              csa_alert_lang_id = NULL
        WHERE csa_inst_code = p_instcode_in 
          AND csa_pan_code = l_trg_hash_pan;
    
       UPDATE CMS_APPL_MAST
          SET cam_cust_code = l_trg_cust_no,cam_bill_addr = L_BILL_ADDR
        WHERE CAM_APPL_CODE = l_trg_appl_code 
          AND CAM_INST_CODE = p_instcode_in;
       
       UPDATE cms_appl_det
          SET cad_acct_id = l_trg_acct_id
        WHERE cad_appl_code = l_trg_appl_code 
          AND cad_inst_code = p_instcode_in;
        
       UPDATE CMS_PAN_ACCT
          SET cpa_acct_id = l_trg_acct_id, 
              cpa_cust_code=l_trg_cust_no
        WHERE cpa_inst_code = p_instcode_in  
          AND cpa_acct_id = l_trg_cap_acct_id 
          AND cpa_mbr_numb = p_mbr_numb_in 
          AND cpa_pan_code=l_trg_hash_pan;
    
      EXCEPTION
           WHEN exp_rvsl_reject_record THEN
               RAISE;
           WHEN OTHERS THEN
               l_resp_cde := '89';
               l_errmsg   := 'ERROR WHILE UPDATING REVERSING DETAILS' ||
                    substr(SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
    END;
    
	 BEGIN
      BEGIN
         sp_log_cardstat_chnge(p_instcode_in, l_trg_hash_pan, l_trg_encr_pan,
            l_auth_id, '08', p_rrn_in,
            p_trandate_in, p_trantime_in,
            l_resp_cde, l_errmsg);

          IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
          THEN
            l_resp_cde := '89';
            RAISE exp_rvsl_reject_record;
          END IF;
        EXCEPTION
          WHEN exp_rvsl_reject_record THEN
            RAISE;
          WHEN OTHERS THEN
            l_resp_cde := '89';
            l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
                 substr(SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      END;
    
      UPDATE cms_appl_pan
         SET cap_acct_no = l_trg_acct_no, 
             cap_acct_id = l_trg_acct_id,
             cap_cust_code=l_trg_cust_no,
             cap_card_stat = '0', 
             cap_firsttime_topup = 'N',
             CAP_ACTIVE_DATE = NULL, 
             CAP_PRFL_CODE = NULL,
             CAP_PRFL_LEVL = NULL,
             Cap_Bill_Addr=L_Bill_Addr,
             cap_repl_flag = 0
       WHERE cap_inst_code = p_instcode_in
         AND CAP_PAN_CODE = l_trg_hash_pan;	   
           
        IF SQL%ROWCOUNT = 0
        THEN
        
          l_errmsg   := 'Starer card not updated to inactive status';
          l_resp_cde := '89';
          RAISE exp_rvsl_reject_record;
        
        END IF;
	   
        EXCEPTION
            WHEN exp_rvsl_reject_record THEN
                 RAISE;
            
            WHEN OTHERS THEN
                l_errmsg   := 'Problem while updating starter card to inactive ' ||
                     substr(SQLERRM, 1, 100);
                l_resp_cde := '89';
                RAISE exp_rvsl_reject_record;
          
     END;

     BEGIN
        SELECT chr_pan_code, chr_pan_code_encr
          INTO l_trg_oldcrd, l_trg_oldcrd_encr
          FROM cms_htlst_reisu
         WHERE chr_inst_code = p_instcode_in 
           AND chr_new_pan = l_trg_hash_pan 
           AND chr_reisu_cause = 'R' 
           AND chr_pan_code IS NOT NULL;
                  
        UPDATE cms_appl_pan
           SET cap_card_stat = cap_old_cardstat
         WHERE cap_inst_code = p_instcode_in 
           AND cap_pan_code = l_trg_oldcrd
     RETURNING cap_card_stat INTO l_trg_old_stat;
     
       SELECT DECODE(l_trg_old_stat, 
                     '0', '08',
                     '1', '01',
                     '2',	'48',
                     '3',	'41',
                     '6',	'80',
                     '7',	'EX',
                     '8',	'04',
                     '11', 'SH',
                     '12', '03',
                     '13', '09',
                     '15', '74',
                     '17', '49',
                     '18', '10',
                     'SC') 
          INTO l_trg_old_txn_code 
          FROM DUAL;
     
        BEGIN
            sp_log_cardstat_chnge(p_instcode_in, l_trg_oldcrd, l_trg_oldcrd_encr,
                      l_auth_id, l_trg_old_txn_code, p_rrn_in,
                      p_trandate_in, p_trantime_in,
                      l_resp_cde, l_errmsg);
          
            IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
            THEN
              l_resp_cde := '89';
              RAISE exp_rvsl_reject_record;
            END IF;
            EXCEPTION
                WHEN exp_rvsl_reject_record THEN
                    RAISE;
                WHEN OTHERS THEN
                    l_resp_cde := '89';
                    l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
                         substr(SQLERRM, 1, 200);
                    RAISE exp_rvsl_reject_record;
        END;

        EXCEPTION
              WHEN no_data_found THEN
                   NULL;
              WHEN OTHERS THEN
                   l_resp_cde := '89';
                   l_errmsg   := 'Error while selecting old card of target card ' ||
                         substr(SQLERRM, 1, 100);
                   RAISE exp_rvsl_reject_record;
     END;
     
  end if;  
 
 
   Begin
         SELECT cam_ledger_bal
           INTO l_src_ledger_balance
           From Cms_Acct_Mast
          WHERE cam_acct_no = l_src_acct_number 
            AND cam_inst_code = p_instcode_in;
          
          EXCEPTION
             WHEN no_data_found THEN
                 l_resp_cde := '12';
                 l_errmsg   := 'Invalid Card ';
                 RAISE exp_rvsl_reject_record;
             WHEN OTHERS THEN
                 l_resp_cde := '12';
                 l_errmsg   := 'Error while selecting data from card Master for card number ' ||
                      SQLERRM;
                 RAISE exp_rvsl_reject_record;
     END;
     
 BEGIN
         SELECT cam_ledger_bal
           INTO l_trg_ledger_balance
           From Cms_Acct_Mast
          WHERE cam_acct_no = l_trg_acct_no 
            AND cam_inst_code = p_instcode_in;
          
          EXCEPTION
             WHEN no_data_found THEN
                 l_resp_cde := '12';
                 l_errmsg   := 'Invalid Card ';
                 RAISE exp_rvsl_reject_record;
             WHEN OTHERS THEN
                 l_resp_cde := '12';
                 l_errmsg   := 'Error while selecting data from card Master for card number ' ||
                      SQLERRM;
                 Raise Exp_Rvsl_Reject_Record;
     End;
     
    
     BEGIN
        UPDATE cms_appl_pan
               SET cap_card_stat = cap_old_cardstat
             WHERE cap_inst_code = p_instcode_in 
               AND cap_pan_code = l_src_hash_pan
         RETURNING cap_card_stat INTO l_src_old_stat;
     
       SELECT DECODE(l_src_old_stat, 
                     '0', '08',
                     '1', '01',
                     '2',	'48',
                     '3',	'41',
                     '6',	'80',
                     '7',	'EX',
                     '8',	'04',
                     '11', 'SH',
                     '12', '03',
                     '13', '09',
                     '15', '74',
                     '17', '49',
                     '18', '10',
                     'SC') 
          INTO l_src_old_txn_code 
          FROM DUAL;
     
     
        BEGIN
            sp_log_cardstat_chnge(p_instcode_in, l_src_hash_pan, l_src_encr_pan,
                      l_auth_id, l_src_old_txn_code, p_rrn_in,
                      p_trandate_in, p_trantime_in,
                      l_resp_cde, l_errmsg);
          
            IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
            THEN
              l_resp_cde := '89';
              RAISE exp_rvsl_reject_record;
            END IF;
            EXCEPTION
                WHEN exp_rvsl_reject_record THEN
                    RAISE;
                WHEN OTHERS THEN
                    l_resp_cde := '89';
                    l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
                         substr(SQLERRM, 1, 200);
                    RAISE exp_rvsl_reject_record;
        END;

        EXCEPTION
              WHEN OTHERS THEN
                   l_resp_cde := '89';
                   l_errmsg   := 'Error while updating source card ' ||
                         substr(SQLERRM, 1, 100);
                   Raise Exp_Rvsl_Reject_Record;
     END;
    
    
    
      
     BEGIN
        UPDATE cms_acct_mast
           SET cam_acct_bal = cam_acct_bal - l_reversal_amt,   
               cam_ledger_bal = cam_ledger_bal - l_reversal_amt
         Where Cam_Inst_Code = P_Instcode_In
           AND cam_acct_no = decode(l_orgnl_txn_code,'41',l_src_acct_number,l_trg_acct_no);
           
         EXCEPTION
              WHEN OTHERS THEN
                l_errmsg   := 'Problem while updating balances ' ||
                     substr(SQLERRM, 1, 100);
                l_resp_cde := '89';
                RAISE exp_rvsl_reject_record;
     END;
    
     BEGIN
          INSERT INTO cms_statements_log
                      (csl_pan_no, csl_opening_bal,
                       csl_trans_amount,
                       csl_trans_type, csl_trans_date,
                       csl_closing_balance,
                       csl_trans_narrration, csl_inst_code,
                       csl_pan_no_encr, csl_rrn, csl_auth_id,
                       csl_business_date, csl_business_time, txn_fee_flag,
                       csl_delivery_channel, csl_txn_code, csl_acct_no,
                       csl_ins_user, csl_ins_date, csl_merchant_name,
                       csl_panno_last4digit,
                       csl_prod_code, csl_acct_type, csl_time_stamp,csl_card_type
                      )
          Values      (L_Trg_Hash_Pan, decode(l_orgnl_txn_code,'41',L_Src_Ledger_Balance,l_trg_ledger_balance),
                       NVL (l_reversal_amt, 0),
                       'DR', To_Date(P_Trandate_In, 'YYYYMMDD'),
                       decode(l_orgnl_txn_code,'41',l_src_ledger_balance - l_reversal_amt,l_trg_ledger_balance-l_reversal_amt),
                       'RVSL-' || l_txn_narration, p_instcode_in,
                       l_trg_encr_pan, p_rrn_in, l_auth_id,
                       P_Trandate_In, P_Trantime_In, 'N',
                       p_delivery_channel_in, l_orgnl_txn_code, decode(l_orgnl_txn_code,'41',l_src_acct_number,l_trg_acct_no),
                       1, SYSDATE,p_merchant_name_in, 
                       --SUBSTR (p_trg_card_in, - 4), 
                       SUBSTR (l_trg_cler_pan, - 4),
                       l_src_prod_code, 1,systimestamp,l_src_card_type
                      );
             EXCEPTION
                  WHEN OTHERS THEN
                       l_resp_cde := '89';
                       l_errmsg := 'Error while inserting into CMS_STATEMENTS_LOG 1.0-'|| SUBSTR (SQLERRM, 1, 200);
                       RAISE exp_rvsl_reject_record;
     END;
    
      BEGIN
          SELECT ccs_stat_desc
            INTO p_src_card_stat_out
            FROM cms_card_stat
           WHERE ccs_stat_code = 
              ( SELECT cap_card_stat 
                  FROM cms_appl_pan 
                 WHERE cap_inst_code = p_instcode_in 
                   AND cap_pan_code = l_src_hash_pan 
                   AND cap_mbr_numb = p_mbr_numb_in);
          
          EXCEPTION
           WHEN exp_rvsl_reject_record THEN
             RAISE;
           WHEN no_data_found THEN
             l_errmsg   := 'Error while Fetching Card Status - No Data found';
             l_resp_cde := '89';
             RAISE exp_rvsl_reject_record;
           WHEN OTHERS THEN
             l_errmsg   := 'Error while Fetching card status ' ||
                  substr(SQLERRM, 1, 200);
             l_resp_cde := '89';
             RAISE exp_rvsl_reject_record;
      END;
  
  
   BEGIN
          SELECT ccs_stat_desc
            INTO p_trgt_card_stat_out
            FROM cms_card_stat
           WHERE ccs_stat_code = 
              ( SELECT cap_card_stat 
                  FROM cms_appl_pan 
                 WHERE cap_inst_code = p_instcode_in 
                   AND cap_pan_code = L_Trg_Hash_Pan 
                   AND cap_mbr_numb = p_mbr_numb_in);
          
          EXCEPTION
           WHEN no_data_found THEN
             l_errmsg   := 'Error while Fetching Card Status - No Data found';
             l_resp_cde := '89';
             RAISE exp_rvsl_reject_record;
           WHEN OTHERS THEN
             l_errmsg   := 'Error while Fetching card status ' ||
                  substr(SQLERRM, 1, 200);
             l_resp_cde := '89';
             RAISE exp_rvsl_reject_record;
      END;
  
        -- p_trgt_card_stat_out := 'INACTIVE';
       p_src_bal_amt_out :=trim(to_char(l_src_ledger_balance,'99999999999999990.99'));
       P_Auth_Amnt_Out :=L_Reversal_Amt;
         
        If L_Orgnl_Txn_Code ='41' Then
         p_src_bal_amt_out :=trim(to_char(l_src_ledger_balance - l_reversal_amt,'99999999999999990.99'));
         p_trg_bal_amt_out :='0.00';
         else
         
         BEGIN
         Select Cam_Acct_Bal, Cam_Ledger_Bal
           INTO l_trg_acct_balance, l_trg_ledger_balance
           From Cms_Acct_Mast
          WHERE cam_acct_no = l_trg_acct_no  
            AND cam_inst_code = p_instcode_in;
            
         EXCEPTION
           WHEN no_data_found THEN
               l_resp_cde := '12';
               l_errmsg   := 'Invalid Card ';
               RAISE exp_rvsl_reject_record;
           WHEN OTHERS THEN
               l_resp_cde := '12';
               l_errmsg   := 'Error while selecting data from card Master for card number ' ||
                    SQLERRM;
               RAISE exp_rvsl_reject_record;
          End;
                 
         P_Trg_Bal_Amt_Out :=L_Trg_Ledger_Balance;
    end if;
      
       p_src_proxy_no_out := l_src_proxunumber;
     

    --Sn generate response code
       l_resp_cde := '1';
  
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode_in 
            AND cms_delivery_channel = p_delivery_channel_in 
            AND cms_response_id = to_number(l_resp_cde);
          EXCEPTION
             WHEN OTHERS THEN
                 l_errmsg   := 'Problem while selecting data from response master for respose code' ||
                      l_resp_cde || substr(SQLERRM, 1, 300);
                 l_resp_cde := '69';
                 RAISE exp_rvsl_reject_record;
      END;
  
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO l_acct_balance, l_ledger_balance
           FROM cms_acct_mast
          WHERE cam_acct_no = l_src_acct_number 
            AND cam_inst_code = p_instcode_in;
            
         EXCEPTION
           WHEN no_data_found THEN
               l_resp_cde := '12';
               l_errmsg   := 'Invalid Card ';
               RAISE exp_rvsl_reject_record;
           WHEN OTHERS THEN
               l_resp_cde := '12';
               l_errmsg   := 'Error while selecting data from card Master for card number ' ||
                    SQLERRM;
               RAISE exp_rvsl_reject_record;
      END;
      
         begin
         select 'From Account No : '|| vmscms.fn_mask_acct(l_src_acct_number)||' '||'To Account No : ' ||vmscms.fn_mask_acct(L_TRG_ACCT_NO)
           into l_remark
           from dual;
           EXCEPTION 
                  WHEN OTHERS THEN
                      l_resp_cde := '89';
                      l_errmsg   := 'ERROR WHILE  format the remark-' ||
                           substr(SQLERRM, 1, 200);
                      Raise exp_rvsl_reject_record;
           end;
  
      BEGIN
         INSERT INTO transactionlog
           (msgtype, rrn, delivery_channel, terminal_id, 
            date_time, txn_code, txn_type, txn_mode, 
            txn_status, response_code, 
            business_date, business_time, customer_card_no,
            topup_acct_no, topup_acct_type, bank_code,
            total_amount, rule_indicator,
            rulegroupid, currencycode, productid, categoryid, tips,
            decline_ruleid, atm_name_location, auth_id, trans_desc,
            amount,
            preauthamount, partialamount, mccodegroupid, currencycodegroupid,
            transcodegroupid, rules, preauth_date, gl_upd_flag, instcode,
            feecode, feeattachtype, tran_reverse_flag, customer_card_no_encr,
            topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
            acct_balance,
            ledger_balance,
            response_id, cardstatus, acct_type, time_stamp, 
            Cr_Dr_Flag, 
            error_msg, store_id, fee_plan, tranfee_amt, merchant_name,topup_acct_balance,topup_ledger_balance,remark,topup_card_no,orgnl_card_no,orgnl_rrn,orgnl_business_date,orgnl_business_time)
         VALUES
           (p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
            l_rvsl_trandate, l_orgnl_txn_code, '1', p_txn_mode_in,
            decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
            P_Trandate_In, Substr(P_Trantime_In, 1, 6), L_Src_Hash_Pan,
             decode(l_orgnl_txn_code,'43',L_TRG_ACCT_NO,''), '1', p_instcode_in,
            TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')), NULL,
            NULL, l_curr_code, l_src_prod_code, l_src_card_type, '0.00',
            NULL, NULL, l_auth_id, l_tran_desc,
            TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
            '0.00', '0.00', NULL, NULL, 
            NULL, NULL, NULL, 'Y', p_instcode_in,
            l_fee_code, l_feeattach_type, 'N', l_src_encr_pan,
            l_trg_encr_pan, l_src_proxunumber, p_rvsl_code_in, l_src_acct_number,
            TRIM(to_char(nvl(l_acct_balance, 0), '99999999999999990.99')),
            TRIM(to_char(nvl(l_ledger_balance, 0), '99999999999999990.99')),
            l_resp_cde, l_src_old_stat, l_cam_type_code, l_timestamp,
            decode(p_delivery_channel_in, '04', l_dr_cr_flag,
            Decode(L_Dr_Cr_Flag, 'CR', 'DR', 'DR', 'CR', L_Dr_Cr_Flag)),
            L_Errmsg, P_Storeid_In, L_Fee_Plan, L_Fee_Amt, P_Merchant_Name_In,L_Trg_Acct_Balance,l_trg_ledger_balance,decode(l_orgnl_txn_code,'43',L_Remark,''),decode(l_orgnl_txn_code,'43',l_trg_hash_pan,''),l_orgnl_customer_card_no,l_trg_txn_rrn,L_Orgnl_Business_Date, L_Orgnl_Business_Time);
            
                        
         EXCEPTION
             WHEN exp_rvsl_reject_record THEN
                  RAISE;
             WHEN OTHERS THEN
                   l_resp_cde := '89';
                   l_errmsg   := 'Error while inserting records in transaction log ' ||
                        substr(SQLERRM, 1, 200);
                   RAISE exp_rvsl_reject_record;
      END;	
    
	 --Sn update reverse flag
     BEGIN
	 --Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_trg_txn_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod) 						--Added for VMS-5739/FSP-991
    THEN
         UPDATE transactionlog
            SET tran_reverse_flag = 'Y'
          WHERE rrn = l_trg_txn_rrn 
            AND business_date = l_trg_txn_business_date 
            AND business_time = l_trg_txn_business_time 
            AND customer_card_no = l_src_hash_pan 
            AND instcode = p_instcode_in;
ELSE
		UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST     --Added for VMS-5739/FSP-991
            SET tran_reverse_flag = 'Y'
          WHERE rrn = l_trg_txn_rrn 
            AND business_date = l_trg_txn_business_date 
            AND business_time = l_trg_txn_business_time 
            AND customer_card_no = l_src_hash_pan 
            AND instcode = p_instcode_in;
END IF;
 
         IF SQL%ROWCOUNT = 0
         THEN
            l_resp_cde := '89';
            l_errmsg   := 'Reverse flag is not updated ';
            RAISE exp_rvsl_reject_record;
         END IF;

       EXCEPTION
           WHEN exp_rvsl_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
                l_resp_cde := '89';
                l_errmsg   := 'Error while updating gl flag ' ||
                        substr(SQLERRM, 1, 200);
                RAISE exp_rvsl_reject_record;
     END;


		BEGIN
		  DELETE from  cms_card_excpfee
		   WHERE cce_inst_code = p_instcode_in 
         AND cce_pan_code = l_trg_hash_pan;

      EXCEPTION
        WHEN OTHERS THEN
          l_errmsg   := 'Error while Deleting from cms_card_excpfee ' ||
               substr(SQLERRM, 1, 200);
          l_resp_cde := '89';
          RAISE exp_rvsl_reject_record;
      END;
	   
	   IF l_errmsg <> 'OK' THEN
	      p_errmsg_out := l_errmsg;
     END IF;
   

    --En  create a entry in GL
  EXCEPTION
    -- << MAIN EXCEPTION>>
   WHEN exp_rvsl_reject_record THEN
       ROLLBACK;
       BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_balance, l_ledger_balance, l_cam_type_code
           FROM cms_acct_mast
          WHERE cam_acct_no = l_src_acct_number 
            AND cam_inst_code = p_instcode_in;
         EXCEPTION
            WHEN OTHERS THEN
                l_acct_balance   := 0;
                l_ledger_balance := 0;
       END;

       BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode_in 
            AND cms_delivery_channel = p_delivery_channel_in 
            AND cms_response_id = to_number(l_resp_cde);
       
         p_errmsg_out := l_errmsg;
         EXCEPTION
            WHEN OTHERS THEN
                p_errmsg_out := 'Problem while selecting data from response master ' ||
                         l_resp_cde || substr(SQLERRM, 1, 300);
                p_resp_code_out := '69';
       END;
    
       IF l_src_prod_code IS NULL
       THEN
          BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
              INTO l_src_prod_code, l_src_card_type, l_src_cardstat, l_src_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode_in 
               AND cap_pan_code = l_src_hash_pan;
            
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
          END;
       END IF;
    
       IF l_dr_cr_flag IS NULL
       THEN
           BEGIN
              SELECT ctm_credit_debit_flag
                INTO l_dr_cr_flag
                FROM cms_transaction_mast
               WHERE ctm_tran_code = l_txn_code 
                 AND ctm_delivery_channel = p_delivery_channel_in 
                 AND ctm_inst_code = p_instcode_in;
               
              EXCEPTION
                 WHEN OTHERS THEN
                     NULL;
           END;
       END IF;
    
       BEGIN
         INSERT INTO transactionlog
              (msgtype, rrn, delivery_channel, terminal_id, 
               date_time, txn_code, txn_type, txn_mode,
               txn_status, response_code, 
               business_date, business_time, customer_card_no,
               topup_card_no, topup_acct_no, topup_acct_type, 
               bank_code, total_amount,
               rule_indicator, rulegroupid, currencycode, productid, 
               categoryid, tips,decline_ruleid, atm_name_location,
               auth_id, trans_desc, amount,
               preauthamount, partialamount, mccodegroupid, currencycodegroupid,
               transcodegroupid, rules, preauth_date, gl_upd_flag, instcode,
               feecode, feeattachtype, tran_reverse_flag, customer_card_no_encr,
               topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
               acct_balance,
               ledger_balance, 
               response_id, cardstatus, error_msg, acct_type, 
               time_stamp, cr_dr_flag,
               store_id, fee_plan,tranfee_amt, merchant_name)
         VALUES
              (p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
               l_rvsl_trandate, l_txn_code, '1', p_txn_mode_in,
               decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
               p_trandate_in, substr(p_trantime_in, 1, 6), l_src_hash_pan,
               l_trg_hash_pan, NULL, NULL,
               p_instcode_in, TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
               NULL, NULL, l_curr_code, l_src_prod_code, 
               l_src_card_type, '0.00', NULL, NULL, 
               l_auth_id, l_tran_desc, TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
               '0.00', '0.00', NULL, NULL,
               NULL, NULL, NULL, 'Y', p_instcode_in,
               l_fee_code, l_feeattach_type, 'N', l_src_encr_pan,
               l_trg_encr_pan, l_src_proxunumber, p_rvsl_code_in, l_src_acct_number,
               TRIM(to_char(nvl(l_acct_balance, 0), '99999999999999990.99')),
               TRIM(to_char(nvl(l_ledger_balance, 0), '99999999999999990.99')),
               l_resp_cde, nvl(l_src_old_stat,l_src_cardstat), l_errmsg, l_cam_type_code,
               nvl(l_timestamp, systimestamp), decode(p_delivery_channel_in, '04', l_dr_cr_flag,
               decode(l_dr_cr_flag, 'CR', 'DR', 'DR', 'CR', l_dr_cr_flag)),
               p_storeid_in, l_fee_plan, l_fee_amt, p_merchant_name_in);
       EXCEPTION
         WHEN OTHERS THEN
                p_errmsg_out := 'Problem while inserting data into transaction log  dtl' ||
                         substr(SQLERRM, 1, 300);
                p_resp_code_out := '69'; -- Server Declined
                ROLLBACK;
                RETURN;
       END;
    
       BEGIN
           INSERT INTO cms_transaction_log_dtl
                (ctd_delivery_channel, ctd_txn_code, ctd_txn_type, ctd_msg_type,
                 ctd_txn_mode, ctd_business_date, ctd_business_time,
                 ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                 ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                 ctd_servicetax_amount, ctd_cess_amount, ctd_bill_amount,
                 ctd_bill_curr, ctd_process_flag, ctd_process_msg, ctd_rrn,
                 ctd_inst_code, ctd_customer_card_no_encr, ctd_cust_acct_number,
                 ctd_location_id, ctd_hashkey_id, ctd_store_address1, ctd_store_address2, 
                 ctd_store_city, ctd_store_state, ctd_store_zip)
           VALUES
                (p_delivery_channel_in, l_txn_code, '1', p_msg_type_in,
                 p_txn_mode_in, p_trandate_in, p_trantime_in, 
                 l_src_hash_pan, l_reversal_amt, l_currcode,
                 l_reversal_amt, NULL, NULL, 
                 NULL, NULL, l_reversal_amt, 
                 l_card_curr, 'E', l_errmsg, p_rrn_in, 
                 p_instcode_in, l_src_encr_pan, l_src_acct_number, 
                 p_terminalid_in, l_src_hashkey_id, p_store_add1_in, p_store_add2_in, 
                 p_store_city_in, p_store_state_in, p_store_zip_in);
         EXCEPTION
           WHEN OTHERS THEN
          p_errmsg_out := 'Problem while inserting data into transaction log  dtl' ||
                   substr(SQLERRM, 1, 300);
          p_resp_code_out := '69';
          ROLLBACK;
          RETURN;
	     END;
	 
       IF L_DUPCHK_COUNT = 1 then
           BEGIN
               SELECT RESPONSE_CODE
                 INTO p_resp_code_out 
                 FROM  VMSCMS.TRANSACTIONLOG_VW          A,                       --Added for VMS-5739/FSP-991
                    (SELECT MIN(ADD_INS_DATE) MINDATE
                       FROM  VMSCMS.TRANSACTIONLOG_VW                             --Added for VMS-5739/FSP-991
                      WHERE RRN = p_rrn_in 
                        AND ACCT_BALANCE IS NOT NULL) B
                WHERE A.ADD_INS_DATE = MINDATE 
                  AND RRN = p_rrn_in 
                  AND ACCT_BALANCE IS NOT NULL;
				 
                  
      
                EXCEPTION
                 WHEN OTHERS THEN
                   p_errmsg_out    := 'Problem in selecting the response detail of Original transaction' ||
                         SUBSTR(SQLERRM, 1, 300);
                   p_resp_code_out := '89'; 
                   ROLLBACK;
                   RETURN;
           END;
           
      BEGIN
         SELECT cam_ledger_bal
           INTO l_src_ledger_balance
           FROM cms_acct_mast
          WHERE cam_acct_no = l_src_acct_number 
            AND cam_inst_code = p_instcode_in;
          
          EXCEPTION
               When Others Then
                   p_errmsg_out    := 'Problem in selecting the ledger balance of source card' ||
                         SUBSTR(SQLERRM, 1, 300);
                   p_resp_code_out := '89'; 
                   ROLLBACK;
                   RETURN;
     End;
     
      BEGIN
         SELECT cam_ledger_bal
           INTO l_trg_ledger_balance
           FROM cms_acct_mast
          WHERE cam_acct_no = l_trg_acct_no   
            AND cam_inst_code = p_instcode_in;
          
          EXCEPTION
               When Others Then
                   p_errmsg_out    := 'Problem in selecting the ledger balance of target card.' ||
                         SUBSTR(SQLERRM, 1, 300);
                   p_resp_code_out := '89'; 
                   ROLLBACK;
                   RETURN;
     End;
      BEGIN
          SELECT ccs_stat_desc
            INTO p_trgt_card_stat_out
            FROM cms_card_stat
           WHERE ccs_stat_code = 
              ( SELECT cap_card_stat 
                  FROM cms_appl_pan 
                 WHERE cap_inst_code = p_instcode_in 
                   AND cap_pan_code = L_Trg_Hash_Pan 
                   AND cap_mbr_numb = p_mbr_numb_in);
          
          EXCEPTION
              When Others Then
                   p_errmsg_out    := 'Problem in selecting the card status description ' ||
                         SUBSTR(SQLERRM, 1, 300);
                   p_resp_code_out := '89'; 
                   ROLLBACK;
                   RETURN;
      END;
     
      -- p_trgt_card_stat_out := 'INACTIVE';
       P_Src_Bal_Amt_Out :=Trim(To_Char(L_Src_Ledger_Balance,'99999999999999990.99'));
       If L_Orgnl_Txn_Code ='43' Then
        P_Trg_Bal_Amt_Out := Trim(To_Char(l_trg_ledger_balance,'99999999999999990.99'));
       Else
        P_Trg_Bal_Amt_Out := '0.00';
       End If;
      
       P_Src_Proxy_No_Out := L_Src_Proxunumber;
       p_auth_amnt_out := l_orgnl_total_amount;
      
      BEGIN
          SELECT ccs_stat_desc
            INTO p_src_card_stat_out
            FROM cms_card_stat
           WHERE ccs_stat_code = 
              ( SELECT cap_card_stat 
                  FROM cms_appl_pan 
                 WHERE cap_inst_code = p_instcode_in 
                   AND cap_pan_code = l_src_hash_pan 
                   AND cap_mbr_numb = p_mbr_numb_in);
          
          EXCEPTION
           WHEN exp_rvsl_reject_record THEN
             RAISE;
           WHEN no_data_found THEN
             l_errmsg   := 'Error while Fetching Card Status - No Data found';
             l_resp_cde := '89';
             RAISE exp_rvsl_reject_record;
           WHEN OTHERS THEN
             l_errmsg   := 'Error while Fetching card status ' ||
                  substr(SQLERRM, 1, 200);
             l_resp_cde := '89';
             RAISE exp_rvsl_reject_record;
      END;
      
       END IF; 
          
     p_errmsg_out := l_errmsg;
     WHEN OTHERS THEN
      	 ROLLBACK;
         BEGIN
          SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
            INTO l_acct_balance, l_ledger_balance, l_cam_type_code
            FROM cms_acct_mast
           WHERE cam_acct_no = l_src_acct_number 
             AND cam_inst_code = p_instcode_in;
          EXCEPTION
             WHEN OTHERS THEN
                  l_acct_balance   := 0;
                  l_ledger_balance := 0;
         END;
    
         BEGIN
           SELECT cms_iso_respcde
             INTO p_resp_code_out
             FROM cms_response_mast
            WHERE cms_inst_code = p_instcode_in 
              AND cms_delivery_channel = p_delivery_channel_in 
              AND cms_response_id = to_number(l_resp_cde);
         
           p_errmsg_out := l_errmsg;
           EXCEPTION
             WHEN OTHERS THEN
                  p_errmsg_out := 'Problem while selecting data from response master ' ||
                           l_resp_cde || substr(SQLERRM, 1, 300);
                  p_resp_code_out := '69';
         END;
        
         IF l_src_prod_code IS NULL
         THEN
         
           BEGIN
              SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
                INTO l_src_prod_code, l_src_card_type, l_src_cardstat, l_src_acct_number
                FROM cms_appl_pan
               WHERE cap_inst_code = p_instcode_in 
                 AND cap_pan_code = l_src_hash_pan;
           EXCEPTION
              WHEN OTHERS THEN
                  NULL;
           END;
         END IF;
    
         IF l_dr_cr_flag IS NULL
         THEN
            BEGIN
                SELECT ctm_credit_debit_flag
                  INTO l_dr_cr_flag
                  FROM cms_transaction_mast
                 WHERE ctm_tran_code = l_txn_code 
                   AND ctm_delivery_channel = p_delivery_channel_in 
                   AND ctm_inst_code = p_instcode_in;
           
               EXCEPTION
                  WHEN OTHERS THEN
                      NULL;
           END;
         END IF;
         
    
         BEGIN
           INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, terminal_id,
                   date_time, txn_code,txn_type, txn_mode, 
                   txn_status, response_code,
                   business_date, business_time, customer_card_no,
                   topup_card_no, topup_acct_no, topup_acct_type, bank_code, 
                   total_amount,
                   rule_indicator, rulegroupid, currencycode, productid, categoryid, tips,
                   decline_ruleid, atm_name_location, auth_id, trans_desc,
                   amount,
                   preauthamount, partialamount, mccodegroupid, currencycodegroupid,
                   transcodegroupid, rules, preauth_date, gl_upd_flag, instcode,
                   feecode, feeattachtype, tran_reverse_flag, customer_card_no_encr,
                   topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
                   acct_balance, ledger_balance, response_id, 
                   cardstatus, error_msg, acct_type, 
                   time_stamp, cr_dr_flag,
                   store_id, fee_plan, tranfee_amt, merchant_name)
           VALUES
                  (p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
                   l_rvsl_trandate, l_txn_code, '1', p_txn_mode_in,
                   decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
                   p_trandate_in, substr(p_trantime_in, 1, 6), l_src_hash_pan,
                   l_trg_hash_pan, NULL, NULL, p_instcode_in,
                   TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
                   NULL, NULL, l_curr_code, l_src_prod_code, l_src_card_type, '0.00',
                   NULL, NULL, l_auth_id, l_tran_desc,
                   TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
                   '0.00', '0.00', NULL, NULL,
                   NULL, NULL, NULL, 'Y', p_instcode_in,
                   l_fee_code, l_feeattach_type, 'N', l_src_encr_pan, 
                   l_trg_encr_pan, l_src_proxunumber, p_rvsl_code_in, l_src_acct_number,
                   nvl(l_acct_balance, 0), nvl(l_ledger_balance, 0), l_resp_cde,
                   l_src_cardstat, l_errmsg, l_cam_type_code,
                   nvl(l_timestamp, systimestamp),
                   decode(p_delivery_channel_in, '04', l_dr_cr_flag,
                        decode(l_dr_cr_flag, 'CR', 'DR', 'DR', 'CR', l_dr_cr_flag)),
                   p_storeid_in, l_fee_plan, l_fee_amt, p_merchant_name_in);
             EXCEPTION
               WHEN OTHERS THEN
                    p_errmsg_out := 'Problem while inserting data into transaction log  dtl' ||
                             substr(SQLERRM, 1, 300);
                    p_resp_code_out := '69'; -- Server Declined
                    ROLLBACK;
                    RETURN;
         END;
    
         BEGIN
             INSERT INTO cms_transaction_log_dtl
                (ctd_delivery_channel, ctd_txn_code, ctd_txn_type, ctd_msg_type,
                 ctd_txn_mode, ctd_business_date, ctd_business_time,
                 ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                 ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                 ctd_servicetax_amount, ctd_cess_amount, ctd_bill_amount,
                 ctd_bill_curr, ctd_process_flag, ctd_process_msg, ctd_rrn,
                 ctd_inst_code, ctd_customer_card_no_encr, ctd_cust_acct_number,
                 ctd_location_id, ctd_hashkey_id, ctd_store_address1, ctd_store_address2, 
                 ctd_store_city, ctd_store_state, ctd_store_zip)
             VALUES
                (p_delivery_channel_in, l_txn_code, '1', p_msg_type_in,
                 p_txn_mode_in, p_trandate_in, p_trantime_in,
                 l_src_hash_pan, l_reversal_amt, l_currcode, 
                 l_reversal_amt, NULL, NULL, 
                 NULL, NULL, l_reversal_amt, 
                 l_card_curr, 'E', l_errmsg, p_rrn_in, 
                 p_instcode_in, l_src_encr_pan, l_src_acct_number,
                 p_terminalid_in, l_src_hashkey_id, p_store_add1_in, p_store_add2_in,
                 p_store_city_in, p_store_state_in, p_store_zip_in);
             EXCEPTION
               WHEN OTHERS THEN
                    p_errmsg_out := 'Problem while inserting data into transaction log  dtl' ||
                             substr(SQLERRM, 1, 300);
                    p_resp_code_out := '69';
                    ROLLBACK;
                    return;
         END;
  END BALANCE_TRANSFER_REVERSAL;
 
 PROCEDURE balance_transfer_virtual(p_instcode_in         IN NUMBER,
                  p_mbr_numb_in         IN VARCHAR2,
                  p_msg_type_in         IN VARCHAR2,
                  p_currcode_in         IN VARCHAR2,
                  p_rrn_in              IN VARCHAR2,
                  p_src_card_in         IN VARCHAR2,
                  p_trg_card_in         IN VARCHAR2,
                  p_delivery_channel_in IN VARCHAR2,
                  p_txn_code_in         IN VARCHAR2,
                  p_txn_mode_in         IN VARCHAR2,
                  p_trandate_in         IN VARCHAR2,
                  p_trantime_in         IN VARCHAR2,
                  p_terminalid_in       IN VARCHAR2,
                  p_merchant_name_in    IN VARCHAR2,
                  p_rvsl_code_in        IN VARCHAR2,
                  p_storeid_in          IN VARCHAR2,
                  p_store_add1_in       IN VARCHAR2,
                  p_store_add2_in       IN VARCHAR2,
                  p_store_city_in       IN VARCHAR2,
                  p_store_state_in      IN VARCHAR2,
                  p_store_zip_in        IN VARCHAR2,
                  p_trans_amt_in        in varchar2,
                  P_Merchantid_In       In Varchar2,
                  p_locationId_in       in varchar2,
                  p_trgt_bal_amt_out    OUT VARCHAR2,
                  p_src_bal_amt_out     OUT VARCHAR2,
                  p_trgt_card_stat_out  OUT VARCHAR2,
                  p_src_card_stat_out   OUT VARCHAR2,
                  p_trg_proxy_no_out    OUT VARCHAR2,
                  p_auth_amnt_out       OUT VARCHAR2,
                  p_errmsg_out          OUT VARCHAR2,
                  p_resp_code_out       OUT VARCHAR2) is

 /*************************************************
      * Created  by      : Tilak
      * Created For      : VMS-951
      * Created Date     : 26-July-2019
      * Reviewer         :
      * Build Number     : R18
      
      * Created  by      : Ubaidur Rahman H
      * Created For      : Performance Change
      * Created Date     : 23-Sep-2019
      * Reviewer         : Saravanakumar A
      * Build Number     : R20

 *************************************************/
     l_auth_id               transactionlog.auth_id%TYPE;
     l_src_card_stat         cms_appl_pan.cap_card_stat%TYPE;
     l_currcode              cms_transaction_log_dtl.ctd_txn_curr%type;
     l_errmsg                VARCHAR2(500);
     l_respcode              CMS_RESPONSE_MAST.CMS_RESPONSE_ID%type;
     l_capture_date          DATE;
     exp_main_reject_record  EXCEPTION;
     l_txn_type              cms_func_mast.cfm_txn_type%TYPE;
     l_src_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
     l_src_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
     l_trg_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
     l_delchannel_code       cms_delchannel_mast.cdm_channel_code%type;
     l_base_curr             cms_inst_param.cip_param_value%TYPE;
     l_tran_date             DATE;
     l_tran_amt              CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
     L_SRC_ACCT_BALANCE      CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
     l_src_ledger_balance    CMS_ACCT_MAST.cam_ledger_bal%type;
     l_business_date         DATE;
     l_src_proxunumber       cms_appl_pan.cap_proxy_number%TYPE;
     l_src_acct_number       cms_appl_pan.cap_acct_no%TYPE;
     L_SRC_ACCT_ID           cms_appl_pan.cap_acct_id%TYPE;
     l_dr_cr_flag            cms_transaction_mast.ctm_credit_debit_flag%type;
     l_tran_type             cms_transaction_mast.ctm_tran_type%type;
     l_trans_desc            cms_transaction_mast.ctm_tran_desc%TYPE;
     l_comb_hash             pkg_limits_check.type_hash;
     l_prfl_flag             cms_transaction_mast.ctm_prfl_flag%TYPE;
     l_src_prod_code         cms_appl_pan.cap_prod_code%TYPE;
     l_src_card_type         cms_appl_pan.cap_card_type%TYPE;
     l_src_lmtprfl           cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
     l_src_profile_level     cms_appl_pan.cap_prfl_levl%TYPE;
     l_src_fee_plan_id       cms_card_excpfee.cce_fee_plan%TYPE;
     l_oldcrd                cms_htlst_reisu.chr_pan_code%TYPE;
     l_hashkey_id            cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
     l_time_stamp            TIMESTAMP;
     L_TRG_ACCT_ID           cms_cust_acct.cca_acct_id%TYPE;
     L_TRG_ACCT_NO           cms_acct_mast.cam_acct_no%TYPE;
     L_TRG_CARD_STATUS       cms_appl_pan.cap_card_stat%TYPE;
     L_TRG_ACTIVE_DATE       cms_appl_pan.cap_active_date%TYPE;
     L_TRG_PROD_CODE         cms_appl_pan.cap_prod_code%TYPE;
     L_TRG_CARD_TYPE         cms_appl_pan.cap_card_type%TYPE;
     L_TRG_CUST_CODE         cms_cust_mast.ccm_cust_code%TYPE;
     L_TRG_CUST_ID           CMS_CUST_MAST.CCM_CUST_ID%TYPE;
     L_SRC_BILL_ADDR         CMS_APPL_PAN.CAP_BILL_ADDR%TYPE;
     L_TRG_BILL_ADDR         CMS_APPL_PAN.CAP_BILL_ADDR%TYPE;
     L_DUPCHK_CARDSTAT       transactionlog.cardstatus%type;
     L_DUPCHK_ACCTBAL        transactionlog.acct_balance%type;
     L_DUPCHK_COUNT          NUMBER;
     l_src_card_pck_id       cms_appl_pan.cap_card_id%type;
     l_trg_card_pck_id       cms_appl_pan.cap_card_id%type;
     l_trg_lmtprfl           cms_appl_pan.cap_prfl_code%type;
     L_src_CUST_CODE         cms_appl_pan.cap_cust_code%type;
     l_trg_appl_code         cms_appl_pan.cap_appl_code%type;
     l_trg_encr_pan          cms_appl_pan.cap_pan_code_encr%type;
     L_SRC_MERCHANT_NAME     cms_appl_pan.CAP_MERCHANT_NAME%TYPE;
     L_SRC_STORE_ID          cms_appl_pan.CAP_STORE_ID%TYPE;
     L_SRC_TERMINAL_ID       cms_appl_pan.CAP_TERMINAL_ID%TYPE;
     L_NARRATION             CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
     l_oldcrd_encr           cms_appl_pan.cap_pan_code_encr%TYPE;
     l_trg_card_in NUMBER;
     l_txn_code             cms_transaction_mast.CTM_TRAN_CODE%TYPE;
     l_src_merchant_id      cms_appl_pan.CAP_MERCHANT_ID%TYPE;
     l_trg_merchant_id      cms_appl_pan.cap_merchant_id%TYPE;
     l_src_location_id     cms_appl_pan.CAP_REPLACE_LOCATION_ID%TYPE;
     l_trg_location_id      cms_appl_pan.CAP_REPLACE_LOCATION_ID%TYPE;
     preauthCnt       NUMBER;
     l_trg_ledger_balance   CMS_ACCT_MAST.cam_ledger_bal%type;
     l_TOPUP_AVAIL_balance   CMS_ACCT_MAST.cam_acct_bal%type;
     l_TOPUP_ledger_balance  CMS_ACCT_MAST.cam_ledger_bal%type;
     l_remark     varchar2(200);
     V_Txn_Amt    Cms_Statements_Log.Csl_Trans_Amount%Type;
     L_Max_Card_Bal   Cms_Bin_Param.Cbp_Param_Value%Type;
     l_profile_code   Cms_Prod_Cattype.Cpc_Profile_Code%TYPE;
     l_trg_acct_bal   cms_acct_mast.Cam_Acct_Bal%TYPE;
     l_tran_code             cms_transaction_mast.CTM_TRAN_CODE%TYPE;
	 
	 v_Retperiod  date;  --Added for VMS-5739/FSP-991
     v_Retdate  date; --Added for VMS-5739/FSP-991


   BEGIN
       p_errmsg_out := 'Success';
       p_resp_code_out := '00';
       l_time_stamp := systimestamp;
       l_txn_code :=p_txn_code_in;
       V_TXN_AMT := ROUND (p_trans_amt_in,2);

     --Sn create hash pan
     BEGIN
       l_src_hash_pan := gethash(p_src_card_in);
     EXCEPTION
     WHEN OTHERS THEN
         l_errmsg := 'ERROR WHILE CONVERTING HASH PAN FOR SOURCE CARD ' ||
             substr(SQLERRM, 1, 200);
 	   RAISE exp_main_reject_record;
     END;
     --En create hash pan

     --Sn create encr pan
     BEGIN
       l_src_encr_pan := fn_emaps_main(p_src_card_in);
     EXCEPTION
     WHEN OTHERS THEN
       l_respcode := '12';
       l_errmsg   := 'ERROR WHILE CONVERTING ENCR PAN FOR SOURCE CARD ' ||
 		    		  substr(SQLERRM, 1, 200);
       RAISE exp_main_reject_record;
     END;


      --sn transaction time check
     BEGIN
        l_tran_date := to_date(substr(TRIM(p_trandate_in), 1, 8) || ' ' ||
                   substr(TRIM(p_trantime_in), 1, 10),
                   'YYYYMMDD HH24:MI:SS');
     EXCEPTION
       WHEN OTHERS THEN
          l_respcode := '32';
          l_errmsg   := 'PROBLEM WHILE CONVERTING TRANSACTION TIME ' ||
               substr(SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
     END;

   -- call lp procedure
      begin
      Lp_Trans_Details(P_Instcode_In ,P_Delivery_Channel_In ,L_Txn_Code ,P_Src_Card_In,P_Rrn_In,L_Time_Stamp,L_Hashkey_Id,L_Dr_Cr_Flag ,L_Txn_Type ,L_Tran_Type,L_Prfl_Flag,L_Trans_Desc,L_Respcode ,L_Errmsg);
      If L_Errmsg <> 'OK' Then
      	raise exp_main_reject_record;
      end if;
      EXCEPTION
      WHEN  exp_main_reject_record THEN
      RAISE;
      WHEN OTHERS THEN
       l_respcode := '89';
             l_errmsg   := 'ERROR WHILE SELECTING SOURCE CARD DETAILS ' ||
                     substr(SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
    end;
     --sn select pan detail
     BEGIN

        SELECT cap_card_stat,cap_proxy_number,cap_acct_no,cap_acct_id,
               cap_prfl_code,CAP_PROD_CODE, CAP_PRFL_LEVL, CAP_CARD_TYPE,
               Cap_Bill_Addr,Cap_Cardpack_Id,Cap_Cust_Code,
               CAP_MERCHANT_NAME,CAP_STORE_ID,CAP_TERMINAL_ID,CAP_MERCHANT_ID,CAP_LOCATION_ID
          INTO l_src_card_stat,l_src_proxunumber, l_src_acct_number, L_SRC_ACCT_ID,
               l_src_lmtprfl,l_src_prod_code, l_src_profile_level, l_src_card_type,
               L_SRC_BILL_ADDR,l_src_card_pck_id,L_src_CUST_CODE,
               L_SRC_MERCHANT_NAME,L_SRC_STORE_ID,L_SRC_TERMINAL_ID,l_src_merchant_id,l_src_location_id
          FROM cms_appl_pan, cms_cust_mast
         WHERE cap_inst_code = p_instcode_in AND
               cap_inst_code = ccm_inst_code AND
               cap_cust_code = ccm_cust_code AND cap_pan_code = l_src_hash_pan AND
               cap_mbr_numb = p_mbr_numb_in;

       EXCEPTION
 	      WHEN no_data_found THEN
             l_respcode := '49';
             l_errmsg   := 'INVALID SOURCE CARD';
             RAISE exp_main_reject_record;
    	    WHEN OTHERS THEN
             l_respcode := '89';
             l_errmsg   := 'ERROR WHILE SELECTING TRANS DETAILS ' ||
                     substr(SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
       END;

       BEGIN
          SELECT CAP_ACCT_NO, CAP_ACCT_ID, CAP_CARD_STAT, CAP_CUST_CODE,
                 CCM_CUST_ID,cap_bill_addr,CAP_PROD_CODE,cap_card_type,
                 CAP_ACTIVE_DATE,cap_cardpack_id,cap_prfl_code,cap_appl_code,
                 cap_pan_code_encr,cap_proxy_number,CAP_PAN_CODE,fn_dmaps_main(cap_pan_code_encr),CAP_MERCHANT_ID,CAP_LOCATION_ID
            INTO L_TRG_ACCT_NO, L_TRG_ACCT_ID, L_TRG_CARD_STATUS,L_TRG_CUST_CODE,
                 L_TRG_CUST_ID,L_TRG_BILL_ADDR,L_TRG_PROD_CODE,L_TRG_CARD_TYPE,
                 L_TRG_ACTIVE_DATE,l_trg_card_pck_id,l_trg_lmtprfl,l_trg_appl_code,
                 l_trg_encr_pan,p_trg_proxy_no_out ,l_trg_hash_pan, l_trg_card_in,l_trg_merchant_id,l_trg_location_id
            FROM cms_appl_pan, cms_cust_mast
           WHERE cap_cust_code = ccm_cust_code AND
                 cap_inst_code = p_instcode_in AND
                 cap_inst_code = ccm_inst_code AND
                  CAP_SERIAL_NUMBER=p_trg_card_in and CAP_FORM_FACTOR is null
                  AND cap_mbr_numb=p_mbr_numb_in ;


   	  EXCEPTION
                 WHEN no_data_found THEN
                 BEGIN
                     SELECT CAP_ACCT_NO, CAP_ACCT_ID, CAP_CARD_STAT, CAP_CUST_CODE,
                     CCM_CUST_ID,cap_bill_addr,CAP_PROD_CODE,cap_card_type,
                     CAP_ACTIVE_DATE,cap_cardpack_id,cap_prfl_code,cap_appl_code,
                     cap_pan_code_encr,cap_proxy_number,CAP_PAN_CODE,fn_dmaps_main(cap_pan_code_encr),CAP_MERCHANT_ID,CAP_LOCATION_ID
                     INTO L_TRG_ACCT_NO, L_TRG_ACCT_ID, L_TRG_CARD_STATUS,L_TRG_CUST_CODE,
                     L_TRG_CUST_ID,L_TRG_BILL_ADDR,L_TRG_PROD_CODE,L_TRG_CARD_TYPE,
                     L_TRG_ACTIVE_DATE,l_trg_card_pck_id,l_trg_lmtprfl,l_trg_appl_code,
                     l_trg_encr_pan,p_trg_proxy_no_out ,l_trg_hash_pan, l_trg_card_in,l_trg_merchant_id,l_trg_location_id
                     FROM cms_appl_pan, cms_cust_mast
                     WHERE cap_cust_code = ccm_cust_code AND
                     cap_inst_code = p_instcode_in AND
                     cap_inst_code = ccm_inst_code AND
                     cap_pan_code = gethash(p_trg_card_in)
                     AND cap_mbr_numb=p_mbr_numb_in ;
                     EXCEPTION
                         when  no_data_found THEN

                             l_respcode := '49';
                             l_errmsg   := 'Target Card Not Found';
                         RAISE exp_main_reject_record;
                     END;
    	    WHEN OTHERS THEN
             l_respcode := '89';
             l_errmsg   := 'ERROR WHILE SELECTING TARGET CARD DETAILS ' ||
                     substr(SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
       END;


        Begin
         Select Cpc_Profile_Code
           INTO l_profile_code
           FROM cms_prod_cattype
           WHERE cpc_prod_code = l_src_prod_code
               AND cpc_card_type = l_src_card_type
               AND cpc_inst_code = p_instcode_in;
        EXCEPTION
         WHEN no_data_found THEN
            l_errmsg   := 'ERROR WHILE FETCHING INSTORE_REPLACEMENT FOR SOURCE PROD - No Data found';
            l_respcode := '89';
            RAISE exp_main_reject_record;
         WHEN OTHERS THEN
            l_errmsg   := 'ERROR WHILE FETCHING INSTORE_REPLACEMENT ' ||substr(SQLERRM, 1, 200);
            l_respcode := '89';
            RAISE exp_main_reject_record;
        END;

     BEGIN
	 
     select count(1) into preauthCnt from VMSCMS.CMS_PREAUTH_TRANSACTION				--Added for VMS-5739/FSP-991
     where cpt_card_no=l_src_hash_pan
     and CPT_EXPIRY_FLAG='N'
     and  cpt_inst_code=p_instcode_in;
	  IF SQL%ROWCOUNT = 0 THEN
	     select count(1) into preauthCnt from VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST				--Added for VMS-5739/FSP-991
     where cpt_card_no=l_src_hash_pan
     and CPT_EXPIRY_FLAG='N'
     and  cpt_inst_code=p_instcode_in;
	  END IF;

     if preauthCnt>0 then
            l_respcode:= '321';
            l_errmsg   := 'Balance transfer denied due to pending preauth on source card';
            raise exp_main_reject_record;
     end if;

     EXCEPTION when exp_main_reject_record then
        raise;
       WHEN OTHERS THEN
        l_respcode:='89';
                l_errmsg := 'ERROR WHILE SELECTING PREAUTH DETAILS FOR SOURCE CARD';
                RAISE exp_main_reject_record;

     END;



     BEGIN
         SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
         INTO L_DUPCHK_CARDSTAT, L_DUPCHK_ACCTBAL
         from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS.TRANSACTIONLOG      --Added for VMS-5739/FSP-991
                 WHERE RRN = P_RRN_IN AND CUSTOMER_CARD_NO = l_src_hash_pan AND
                 DELIVERY_CHANNEL = p_delivery_channel_in
                 and ACCT_BALANCE is not null
                 order by add_ins_date desc)
         where rownum=1;
		 IF SQL%ROWCOUNT = 0 THEN
		          SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
         INTO L_DUPCHK_CARDSTAT, L_DUPCHK_ACCTBAL
         from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST      --Added for VMS-5739/FSP-991
                 WHERE RRN = P_RRN_IN AND CUSTOMER_CARD_NO = l_src_hash_pan AND
                 DELIVERY_CHANNEL = p_delivery_channel_in
                 and ACCT_BALANCE is not null
                 order by add_ins_date desc)
         where rownum=1;
		 END IF;
         L_DUPCHK_COUNT:=1;
       EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
               L_DUPCHK_COUNT:=0;

               WHEN OTHERS
               THEN
                l_respcode:='89';
                l_errmsg := 'ERROR WHILE CHECKING CARD STATUS AND ACCOUNT BAL';
                RAISE exp_main_reject_record;
     END;

     BEGIN
           SELECT CAM_ACCT_BAL
           INTO l_tran_amt
           FROM CMS_ACCT_MAST
           WHERE CAM_ACCT_NO = l_src_acct_number
           AND  CAM_INST_CODE = P_INSTCODE_IN;

         p_auth_amnt_out :=trim(to_char(l_tran_amt,'99999999999999990.99'));

       EXCEPTION
          WHEN OTHERS THEN
               l_respcode := '12';
               l_errmsg   := 'ERROR WHILE SELECTING SOURCE ACCOUNT BALANCE ' ||substr(sqlerrm,1,200);
               RAISE EXP_MAIN_REJECT_RECORD;
      END;


      IF l_tran_amt <= 0 then
         L_RESPCODE := '15';
         L_ERRMSG   := 'INSUFFICIENT FUNDS';
             RAISE EXP_MAIN_REJECT_RECORD;

      END IF;

    IF l_DUPCHK_COUNT =1 then

         L_DUPCHK_COUNT:=0;

             if L_DUPCHK_CARDSTAT= l_src_card_stat and L_DUPCHK_ACCTBAL=l_tran_amt
             then

             L_DUPCHK_COUNT:=1;
             L_RESPCODE := '22';
             L_ERRMSG   := 'DUPLICATE INCOMM REFERENCE NUMBER' ||P_RRN_IN;
             RAISE EXP_MAIN_REJECT_RECORD;

             end if;

       END IF;
       BEGIN
             vmsfunutilities.get_currency_code(l_src_prod_code,l_src_card_type,p_instcode_in,l_base_curr,l_errmsg);
               if l_errmsg<>'OK' then
                    raise exp_main_reject_record;
               end if;

           IF TRIM(l_base_curr) IS NULL
           THEN
               l_respcode := '89';
               l_errmsg   := 'BASE CURRENCY CANNOT BE NULL ';
               RAISE exp_main_reject_record;
           END IF;

         l_currcode := l_base_curr;

           EXCEPTION
             WHEN exp_main_reject_record THEN
               RAISE exp_main_reject_record;
             WHEN OTHERS THEN
               l_respcode := '89';
               l_errmsg   := 'ERROR WHILE SELECTING BASE CURRECY  ' ||
                    substr(SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
       END;
 	 --sn call to authorize txn

              BEGIN
                Sp_Authorize_Txn_Cms_Auth(P_Instcode_In, P_Msg_Type_In, P_Rrn_In,
                           p_delivery_channel_in, p_terminalid_in,
                           l_txn_code, p_txn_mode_in,
                           p_trandate_in, p_trantime_in, p_src_card_in,
                           NULL, l_tran_amt, p_merchant_name_in,
                           Null, Null, L_Currcode, Null,
                           NULL, NULL,case when L_Txn_Code='43' then l_TRG_ACCT_NO  else null end, NULL, NULL, NULL, NULL,
                           NULL, NULL, NULL, NULL, NULL, NULL,
                           p_mbr_numb_in, p_rvsl_code_in, l_tran_amt,
                           l_auth_id, l_respcode, l_errmsg,
                           l_capture_date);

                      IF l_respcode <> '00' AND l_errmsg <> 'OK'
                      THEN
                      l_respcode := '294';
                      l_errmsg := l_errmsg;
                     RAISE exp_main_reject_record;
                      END IF;
              EXCEPTION
                  WHEN exp_main_reject_record THEN
                     RAISE;
                  WHEN OTHERS THEN
                     l_respcode := '89';
                     l_errmsg   := substr(SQLERRM, 'ERROR FROM CARD AUTHORIZATION' || 1,
                              200);
                     RAISE exp_main_reject_record;
              END;



               BEGIN
              Select Cam_Acct_Bal
                INTO l_trg_acct_bal
                FROM cms_acct_mast
               WHERE cam_acct_no = L_TRG_ACCT_NO AND
                   cam_inst_code = p_instcode_in;
          EXCEPTION

              WHEN OTHERS THEN
                 l_respcode := '12';
                 l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                         SQLERRM;
                 Raise exp_main_reject_record;
          END;


          BEGIN
          Select To_Number(Cbp_Param_Value)
            INTO l_MAX_CARD_BAL
            FROM CMS_BIN_PARAM
           WHERE CBP_INST_CODE = p_instcode_in AND
                CBP_PARAM_NAME = 'Max Card Balance' AND
                CBP_PROFILE_CODE=l_profile_code;

         EXCEPTION
           WHEN OTHERS THEN
            L_Respcode := '21';
            l_errmsg  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                       SUBSTR(SQLERRM, 1, 200);
            Raise exp_main_reject_record;
         END;

             If (L_Trg_Acct_Bal > l_Max_Card_Bal)
                       OR ((l_trg_acct_bal + l_tran_amt) > l_max_card_bal)
             THEN
                l_respcode := '322';
                l_errmsg := 'Maximum Balance Limitation';
            RAISE exp_main_reject_record;
           End If;


     BEGIN
         SELECT chr_pan_code,chr_pan_code_encr
           INTO l_oldcrd,l_oldcrd_encr
           FROM cms_htlst_reisu
          WHERE chr_inst_code = p_instcode_in AND chr_new_pan = l_trg_hash_pan AND
                   chr_reisu_cause = 'R' AND chr_pan_code IS NOT NULL;

        UPDATE cms_appl_pan
           SET cap_card_stat = '9'
         WHERE cap_inst_code = p_instcode_in AND cap_pan_code = l_oldcrd;

      BEGIN
           sp_log_cardstat_chnge(p_instcode_in,l_oldcrd,
                         l_oldcrd_encr, l_auth_id, '02',
                           p_rrn_in, p_trandate_in, p_trantime_in,
                           l_respcode, l_errmsg,'Closed through Balance Transfer');

                     IF l_respcode <> '00' AND l_errmsg <> 'OK'
                     THEN
                         l_respcode := '89';
                         RAISE exp_main_reject_record;
                     END IF;
      EXCEPTION
          WHEN exp_main_reject_record THEN
                       RAISE;
           WHEN OTHERS THEN
                 l_respcode := '89';
                 l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
                    substr(SQLERRM, 1, 200);
                 RAISE exp_main_reject_record;
     END;
     EXCEPTION
           WHEN no_data_found THEN
              NULL;
          WHEN OTHERS THEN
                  l_respcode := '89';
                  l_errmsg   := 'Error while selecting old card of target card ' ||
                       substr(SQLERRM, 1,200
                       );
                  RAISE exp_main_reject_record;
     END;


     if  L_TRG_CARD_STATUS <> '0' then
         l_respcode :='295';
         l_errmsg := 'Invalid Target Card Status';
         RAISE exp_main_reject_record;
 	  END IF;

     IF L_TRG_CARD_STATUS ='0' and L_TRG_ACTIVE_DATE is not null
 	  THEN
         l_respcode :='295';
         l_errmsg := 'Invalid Target Card Status';
                raise exp_main_reject_record;
     END IF;

             --SN : Transaction limits check
          BEGIN

             IF (l_trg_lmtprfl IS NOT NULL AND l_prfl_flag = 'Y')
             THEN
                pkg_limits_check.sp_limits_check (l_trg_hash_pan,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  l_txn_code,
                                                  l_tran_type,
                                                  NULL,
                                                  NULL,
                                                  p_instcode_in,
                                                  NULL,
                                                  l_trg_lmtprfl,
                                                  l_tran_amt,
                                                  p_delivery_channel_in,
                                                  l_comb_hash,
                                                  l_respcode,
                                                  l_errmsg);
             END IF;

             IF l_respcode <> '00' AND l_errmsg <> 'OK'
             THEN
                IF l_respcode = '127'
                THEN
                   l_respcode := '140';
                ELSE
                   l_respcode := l_respcode;
                END IF;

                RAISE exp_main_reject_record;
             END IF;
          EXCEPTION
             WHEN exp_main_reject_record
             THEN
                RAISE;
             WHEN OTHERS
             THEN
                l_respcode := '89';
                l_errmsg :=
                   'Error while limits check-' || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_main_reject_record;
          END;

          --EN : Transaction limits check

         BEGIN
              SELECT cam_ledger_bal
                INTO l_trg_ledger_balance
                FROM cms_acct_mast
               WHERE cam_acct_no = L_TRG_ACCT_NO AND
                   cam_inst_code = p_instcode_in;
          EXCEPTION

              WHEN OTHERS THEN
                 l_respcode := '12';
                 l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                         SQLERRM;
                 RAISE exp_main_reject_record;
          END;


          BEGIN
              UPDATE cms_acct_mast
                 SET cam_acct_bal =cam_acct_bal+l_tran_amt,
                     cam_ledger_bal =cam_ledger_bal+l_tran_amt,
                     cam_funding_acct_no = l_src_acct_number
               WHERE cam_acct_no = l_trg_acct_no 
               AND cam_inst_code = p_instcode_in;
          EXCEPTION
              WHEN OTHERS THEN
                 l_respcode := '12';
                 l_errmsg   := 'ERROR WHILE UPDATING BALANCE INTO TARGET ACCT ' ||
                         SQLERRM;
                 RAISE exp_main_reject_record;
          END;
		  
		    BEGIN
              UPDATE cms_acct_mast
                 SET cam_funding_acct_no = l_trg_acct_no 
               WHERE cam_acct_no = l_src_acct_number 
               AND cam_inst_code = p_instcode_in;
        EXCEPTION
              WHEN OTHERS THEN
                 l_respcode := '12';
                 l_errmsg   := 'ERROR WHILE UPDATING FUNDING ACCOUNT NUMBER ' ||
                         SQLERRM;
                 RAISE exp_main_reject_record;
       END;

       BEGIN
              SELECT cam_acct_bal,cam_ledger_bal
                INTO l_TOPUP_AVAIL_balance,l_TOPUP_ledger_balance
                FROM cms_acct_mast
               WHERE cam_acct_no = L_TRG_ACCT_NO AND
                   cam_inst_code = p_instcode_in;
          EXCEPTION

              WHEN OTHERS THEN
                 l_respcode := '12';
                 l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                         SQLERRM;
                 RAISE exp_main_reject_record;
          END;


  BEGIN

         IF TRIM(l_trans_desc) IS NOT NULL THEN

          L_NARRATION := l_trans_desc || '/';

         END IF;
         if trim(p_merchant_name_in) is not null then
           L_NARRATION :=L_NARRATION|| p_merchant_name_in || '/';
         end if;

         IF TRIM(p_trandate_in) IS NOT NULL THEN

          L_NARRATION := L_NARRATION || p_trandate_in||'/';

         END IF;

          IF TRIM(l_auth_id) IS NOT NULL THEN

          L_NARRATION := L_NARRATION || l_auth_id;

         END IF;

   EXCEPTION

     WHEN OTHERS THEN

      l_respcode := '21';
      l_errmsg  := 'Error in finding the narration ' ||
                 SUBSTR(SQLERRM, 1, 200);
      RAISE exp_main_reject_record;

   END;

  BEGIN
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
       CSL_TIME_STAMP,
       CSL_PROD_CODE,csl_card_type,csl_acct_type
       )
     VALUES
      (l_trg_hash_pan,
       l_trg_ledger_balance,
       l_tran_amt,
       'CR',
       L_TRAN_DATE,
       l_trg_ledger_balance+l_tran_amt,
       L_NARRATION,
       l_trg_encr_pan,
       P_RRN_IN,
       l_auth_id,
       p_trandate_in,
       p_trantime_in,
       'N',
       P_DELIVERY_CHANNEL_IN,
       P_INSTCODE_IN,
       l_txn_code,
       L_TRG_ACCT_NO,
       1,
       SYSDATE,
       --substr(p_trg_card_in,-4),
       substr(l_trg_card_in,-4),
       systimestamp,
       L_TRG_PROD_CODE,L_TRG_CARD_TYPE ,1
       );
   EXCEPTION
     WHEN OTHERS THEN
      l_respcode := '89';
      l_errmsg  := 'Error while creating entry in statement log ';
      RAISE exp_main_reject_record;

   END;


         BEGIN
              SELECT cam_ledger_bal,cam_acct_bal
                INTO l_src_ledger_balance,l_src_acct_balance
                From Cms_Acct_Mast
               WHERE cam_acct_no = l_src_acct_number AND
                   cam_inst_code = p_instcode_in;
          EXCEPTION

              WHEN OTHERS THEN
                 l_respcode := '12';
                 l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                         SQLERRM;
                 RAISE exp_main_reject_record;
          END;



      P_Trgt_Bal_Amt_Out :=Trim(To_Char(l_TOPUP_ledger_balance,'99999999999999990.99'));
      p_src_bal_amt_out :='0.00';

  if  L_TRG_CARD_STATUS in('0','8') then

     if L_TRG_CARD_STATUS = '0' then
         l_tran_code := '01';
         else
         l_tran_code := '05';

     end if;


    begin
          update cms_appl_pan set cap_card_stat=nvl(CAP_OLD_CARDSTAT,'1'),
          cap_firsttime_topup = 'Y',
               cap_active_date = SYSDATE,
               cap_pin_off='0000'
          where  cap_pan_code= l_trg_hash_pan
               and cap_inst_code=p_instcode_in ;

    EXCEPTION
         WHEN OTHERS THEN
          l_respcode := '89';
          l_errmsg   := 'ERROR WHILE UPDATING cms_appl_pan target card status' ||
               substr(SQLERRM, 1, 100);
          RAISE exp_main_reject_record;
   end;

     BEGIN

          sp_log_cardstat_chnge(p_instcode_in, l_trg_hash_pan, l_trg_encr_pan,
                 l_auth_id, l_tran_code, p_rrn_in, p_trandate_in,
                 p_trantime_in, l_respcode, l_errmsg);

              IF l_respcode <> '00' AND l_errmsg <> 'OK'
                  THEN
                 RAISE exp_main_reject_record;
              END IF;
        EXCEPTION
            WHEN exp_main_reject_record THEN
               RAISE;
            WHEN OTHERS THEN
               l_respcode := '89';
               l_errmsg   := 'ERROR WHILE LOGGING SYSTEM INITIATED CARD STATUS CHANGE ' ||
                       substr(SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
        END;



   end if;

      p_trgt_card_stat_out:='Active';


    BEGIN

 	 INSERT INTO cms_cardprofile_hist
 	   (CCP_PAN_CODE, CCP_INST_CODE,
       ccp_pan_code_encr, ccp_ins_date, ccp_lupd_date, ccp_mbr_numb,
 	    CCP_RRN, CCP_STAN, CCP_BUSINESS_DATE, CCP_BUSINESS_TIME,
 	    ccp_terminal_id, ccp_acct_no, ccp_acct_id,
 	    CCP_CUST_CODE)
 	 VALUES
 	   (L_TRG_HASH_PAN, P_INSTCODE_IN,
       l_trg_encr_pan, SYSDATE, SYSDATE,p_mbr_numb_in,
       P_RRN_IN, NULL, P_TRANDATE_IN, P_TRANTIME_IN,
 	    p_terminalid_in, L_TRG_ACCT_NO, L_TRG_ACCT_ID,
 	    L_TRG_CUST_CODE);

   EXCEPTION
 	 WHEN no_data_found THEN
 	   l_respcode := '21';
 	   l_errmsg   := 'NO DATA FOUND IN ADDRMAST/CUSTMAST FOR' || '-' ||
 				  L_TRG_CUST_CODE;
 	   RAISE exp_main_reject_record;
 	 WHEN OTHERS THEN
 	   l_respcode := '21';
 	   l_errmsg   := 'ERROR IN PROFILE UPDATE ' || substr(SQLERRM, 1, 300);
 	   RAISE exp_main_reject_record;
     END;

     BEGIN
                 sp_log_cardstat_chnge(p_instcode_in, l_src_hash_pan,
                           l_src_encr_pan, l_auth_id, '02',
                           p_rrn_in, p_trandate_in, p_trantime_in,
                           l_respcode, l_errmsg,'Closed through Balance Transfer');

                     IF l_respcode <> '00' AND l_errmsg <> 'OK'
                     THEN
                         l_respcode := '89';
                         RAISE exp_main_reject_record;
                     END IF;
               EXCEPTION
                   WHEN exp_main_reject_record THEN
                       RAISE;
                   WHEN OTHERS THEN
                       l_respcode := '89';
                       l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
                            substr(SQLERRM, 1, 200);
                       RAISE exp_main_reject_record;
               END;

               BEGIN
                 UPDATE cms_appl_pan
                    SET cap_card_stat = '9'
                  WHERE cap_pan_code = l_src_hash_pan AND
                        cap_inst_code = p_instcode_in;


                     IF SQL%ROWCOUNT = 0
                     THEN
                           l_respcode := '89';
                           l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS ' ||
                                substr(SQLERRM, 1, 200);
                           RAISE exp_main_reject_record;
                     END IF;
       p_src_card_stat_out :='Closed';

    EXCEPTION
         WHEN exp_main_reject_record THEN
             RAISE exp_main_reject_record;
         WHEN OTHERS THEN
             l_respcode := '89';
             l_errmsg   := 'ERROR WHILE SELECTING STARTER CARD DETAILS ' ||
                     substr(SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
 	 END;

 	 IF l_trg_lmtprfl IS NOT NULL AND l_prfl_flag = 'Y'
 	 THEN
    BEGIN

 	   pkg_limits_check.sp_limitcnt_reset(p_instcode_in, l_trg_hash_pan,
 								   l_tran_amt, l_comb_hash,
 								   l_respcode, l_errmsg);

 	 IF l_respcode <> '00' AND l_errmsg <> 'OK'
 	 THEN
 	   l_errmsg := 'FROM PROCEDURE SP_LIMITCNT_RESET' || l_errmsg;
 	   RAISE exp_main_reject_record;
 	 END IF;

    EXCEPTION
 	 WHEN exp_main_reject_record THEN
 	   RAISE;
 	 WHEN OTHERS THEN
 	   l_respcode := '21';
 	   l_errmsg   := 'ERROR FROM LIMIT RESET COUNT PROCESS ' ||
 				  substr(SQLERRM, 1, 200);
 	   RAISE exp_main_reject_record;
     END;

  END IF;

            begin
			--Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate_in), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod) 				 --Added for VMS-5739/FSP-991
		THEN
				update cms_statements_log 
				set csl_to_acctno=L_TRG_ACCT_NO
				where csl_pan_NO=l_src_hash_pan
				and csl_inst_code=p_instcode_in
				and csl_rrn=p_rrn_in
				and csl_delivery_channel=p_delivery_channel_in
				and csl_txn_code=l_txn_code
				and csl_business_date=p_trandate_in
				and csl_business_time=p_trantime_in;
	ELSE
				update VMSCMS_HISTORY.cms_statements_log_HIST      --Added for VMS-5739/FSP-991 
				set csl_to_acctno=L_TRG_ACCT_NO
				where csl_pan_NO=l_src_hash_pan
				and csl_inst_code=p_instcode_in
				and csl_rrn=p_rrn_in
				and csl_delivery_channel=p_delivery_channel_in
				and csl_txn_code=l_txn_code
				and csl_business_date=p_trandate_in
				and csl_business_time=p_trantime_in;    
	END IF;			

             IF SQL%ROWCOUNT = 0
            THEN
                p_errmsg_out := 'ERROR WHILE UPDATING STOREID IN TRANSACTIONLOG TABLE' ||
                       substr(SQLERRM, 1, 200);
                l_respcode   := '89';
                RAISE exp_main_reject_record;
             END IF;

           EXCEPTION  WHEN exp_main_reject_record  THEN
           raise;
               WHEN OTHERS THEN
            l_respcode := '21';
              l_errmsg   := 'ERROR WHILE UPDATING STATEMENTS LOG' ||
                   substr(SQLERRM, 1, 200);
              RAISE exp_main_reject_record;

            end;



         begin
          select 'From Account No : '|| vmscms.fn_mask_acct(l_src_acct_number)||' '||'To Account No : ' ||vmscms.fn_mask_acct(L_TRG_ACCT_NO)
            into l_remark
            from dual;
            EXCEPTION
                   WHEN OTHERS THEN
                       l_respcode := '89';
                       l_errmsg   := 'ERROR WHILE  format the remark-' ||
                            substr(SQLERRM, 1, 200);
                       RAISE exp_main_reject_record;
            end;

     BEGIN
	 
--Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate_in), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)				--Added for VMS-5739/FSP-991
		THEN
			  UPDATE transactionlog
				 SET store_id = p_storeid_in,
					 tran_reverse_flag = 'N',
					 topup_card_no_encr=l_trg_encr_pan,
					 Acct_Balance=L_Src_Acct_Balance,Ledger_Balance=L_Src_Ledger_Balance,
					 topup_card_no=l_trg_hash_pan,topup_acct_no=L_TRG_ACCT_NO,topup_acct_type='1',bank_code=1,remark=l_remark,
					 topup_acct_balance=l_TOPUP_AVAIL_balance,topup_ledger_balance=l_TOPUP_ledger_balance
			   WHERE instcode = p_instcode_in AND rrn = p_rrn_in AND
					 customer_card_no = l_src_hash_pan AND
					 business_date = p_trandate_in AND txn_code = l_txn_code AND
					 delivery_channel = p_delivery_channel_in;
					 
	ELSE
				UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST    --Added for VMS-5739/FSP-991
				 SET store_id = p_storeid_in,
					 tran_reverse_flag = 'N',
					 topup_card_no_encr=l_trg_encr_pan,
					 Acct_Balance=L_Src_Acct_Balance,Ledger_Balance=L_Src_Ledger_Balance,
					 topup_card_no=l_trg_hash_pan,topup_acct_no=L_TRG_ACCT_NO,topup_acct_type='1',bank_code=1,remark=l_remark,
					 topup_acct_balance=l_TOPUP_AVAIL_balance,topup_ledger_balance=l_TOPUP_ledger_balance
			   WHERE instcode = p_instcode_in AND rrn = p_rrn_in AND
					 customer_card_no = l_src_hash_pan AND
					 business_date = p_trandate_in AND txn_code = l_txn_code AND
					 delivery_channel = p_delivery_channel_in;
	END IF;				 

            IF SQL%ROWCOUNT = 0
            THEN
                p_errmsg_out := 'ERROR WHILE UPDATING STOREID IN TRANSACTIONLOG TABLE' ||
                       substr(SQLERRM, 1, 200);
                l_respcode   := '89';
                RAISE exp_main_reject_record;
            END IF;
     EXCEPTION
        WHEN exp_main_reject_record THEN
            RAISE exp_main_reject_record;
     	 WHEN OTHERS THEN
            p_errmsg_out := 'ERROR WHILE UPDATING STOREID IN TRANSACTIONLOG TABLE' ||
                   substr(SQLERRM, 1, 200);
            l_respcode   := '89';
              RAISE exp_main_reject_record;
     END;

      BEGIN
	  
--Added for VMS-5739/FSP-991
	select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate_in), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)         --Added for VMS-5739/FSP-991
		THEN
			Update Cms_Transaction_Log_Dtl
			   SET --ctd_location_id = p_terminalid_in,
				   CTD_STORE_ADDRESS1 = p_store_add1_in,
				   CTD_STORE_ADDRESS2 = p_store_add2_in,
				   CTD_STORE_CITY     = p_store_city_in,
				   CTD_STORE_STATE    = p_store_state_in,
				   CTD_STORE_ZIP      = p_store_zip_in
			 WHERE ctd_rrn = p_rrn_in AND ctd_business_date = p_trandate_in AND
				   ctd_business_time = p_trantime_in AND
				   ctd_delivery_channel = p_delivery_channel_in AND
				   ctd_txn_code = l_txn_code AND ctd_msg_type = p_msg_type_in AND
				   ctd_inst_code = p_instcode_in AND
				   ctd_customer_card_no = l_src_hash_pan;
	ELSE
			Update VMSCMS_HISTORY.cms_transaction_log_dtl_HIST         --Added for VMS-5739/FSP-991
			   SET --ctd_location_id = p_terminalid_in,
				   CTD_STORE_ADDRESS1 = p_store_add1_in,
				   CTD_STORE_ADDRESS2 = p_store_add2_in,
				   CTD_STORE_CITY     = p_store_city_in,
				   CTD_STORE_STATE    = p_store_state_in,
				   CTD_STORE_ZIP      = p_store_zip_in
			 WHERE ctd_rrn = p_rrn_in AND ctd_business_date = p_trandate_in AND
				   ctd_business_time = p_trantime_in AND
				   ctd_delivery_channel = p_delivery_channel_in AND
				   ctd_txn_code = l_txn_code AND ctd_msg_type = p_msg_type_in AND
				   ctd_inst_code = p_instcode_in AND
				   ctd_customer_card_no = l_src_hash_pan;
	END IF;


			   

          IF SQL%ROWCOUNT = 0
          THEN
              p_errmsg_out := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
              l_respcode   := '89';
              RAISE exp_main_reject_record;
          END IF;
     EXCEPTION
          WHEN exp_main_reject_record THEN
              RAISE exp_main_reject_record;
          WHEN OTHERS THEN
              l_respcode   := '89';
              p_errmsg_out := 'PROBLEM ON UPDATED CMS_TRANSACTION_LOG_DTL ' ||
                     substr(SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
     END;


   EXCEPTION
     --<< main exception >>

     WHEN exp_main_reject_record THEN
   	 ROLLBACK;

     BEGIN
 	   -- assign the response code to the out parameter
 	   SELECT cms_iso_respcde,cms_resp_desc
 	   INTO   p_resp_code_out,p_errmsg_out
 	   FROM   cms_response_mast
 	   WHERE  cms_inst_code = p_instcode_in AND
 			cms_delivery_channel = p_delivery_channel_in AND
 			cms_response_id = l_respcode;
 	 EXCEPTION
 	   WHEN OTHERS THEN
 		p_errmsg_out    := 'PROBLEM WHILE SELECTING DATA FROM RESPONSE MASTER ' ||
 					    l_respcode || substr(SQLERRM, 1, 300);
 		p_resp_code_out := '89';
 		ROLLBACK;
 		-- return;
 	 END;


          BEGIN
              SELECT cam_acct_bal, cam_ledger_bal
                INTO L_SRC_ACCT_BALANCE, l_src_ledger_balance
                FROM cms_acct_mast
               WHERE cam_acct_no = l_src_acct_number AND
                   cam_inst_code = p_instcode_in;
          EXCEPTION

              WHEN OTHERS THEN
                 l_respcode := '12';
                 l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                         SQLERRM;
                 RAISE exp_main_reject_record;
          END;


 	 --sn create a entry in txn log
 	 BEGIN
          INSERT INTO transactionlog
         (msgtype, rrn, delivery_channel, terminal_id, date_time, txn_code,
          txn_type, txn_mode, txn_status, response_code, business_date,
          business_time, customer_card_no, topup_card_no, topup_acct_no,
          topup_acct_type, bank_code, total_amount, currencycode, addcharge,
          productid, categoryid, atm_name_location, auth_id, amount,
          preauthamount, partialamount, instcode, customer_card_no_encr,
          topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
          acct_balance, ledger_balance, response_id, cardstatus, error_msg,
          trans_desc, merchant_name,merchant_state,
          ssn_fail_dtls, store_id, time_stamp, orgnl_card_no,
          tran_reverse_flag)
          VALUES
         (p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
          l_business_date, l_txn_code, l_txn_type, p_txn_mode_in,
          decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
          p_trandate_in, substr(p_trantime_in, 1, 10), l_src_hash_pan, l_trg_hash_pan,
          L_TRG_ACCT_NO, NULL, p_instcode_in,
          TRIM(to_char(decode(p_resp_code_out,'00',l_tran_amt,V_TXN_AMT), '99999999999999999.99')), l_currcode,
          NULL, l_src_prod_code, l_src_card_type, p_terminalid_in, l_auth_id,
          TRIM(to_char(decode(p_resp_code_out,'00',l_tran_amt,V_TXN_AMT), '99999999999999999.99')), NULL, NULL,
          p_instcode_in, l_src_encr_pan, l_trg_encr_pan, l_src_proxunumber,
          p_rvsl_code_in, l_src_acct_number, L_SRC_ACCT_BALANCE, l_src_ledger_balance,
          l_respcode, l_src_card_stat, l_errmsg, l_trans_desc,
          p_merchant_name_in,NULL,null,
          p_storeid_in, l_time_stamp, l_src_hash_pan, 'N');
 	 EXCEPTION
 	   WHEN OTHERS THEN
           p_resp_code_out := '89';
           p_errmsg_out    := 'PROBLEM WHILE INSERTING DATA INTO TRANSACTION LOG  DTL' ||
                     substr(SQLERRM, 1, 300);
 	 END;

 	 --en create a entry in txn log
 	 BEGIN
          INSERT INTO cms_transaction_log_dtl
         (ctd_delivery_channel, ctd_txn_code, ctd_msg_type, ctd_txn_mode,
          ctd_business_date, ctd_business_time, ctd_customer_card_no,
          ctd_txn_amount, ctd_txn_curr, ctd_actual_amount, ctd_fee_amount,
          ctd_waiver_amount, ctd_servicetax_amount, ctd_cess_amount,
          ctd_bill_amount, ctd_bill_curr, ctd_process_flag, ctd_process_msg,
          ctd_rrn, ctd_inst_code, ctd_customer_card_no_encr,
          ctd_cust_acct_number,
          ctd_location_id, ctd_hashkey_id)
          VALUES
         (p_delivery_channel_in, l_txn_code, p_msg_type_in,
          p_txn_mode_in, p_trandate_in, p_trantime_in, l_src_hash_pan,
          TRIM(to_char(decode(p_resp_code_out,'00',L_SRC_ACCT_BALANCE,V_TXN_AMT), '99999999999999999.99')), l_currcode,
          TRIM(to_char(decode(p_resp_code_out,'00',L_SRC_ACCT_BALANCE,V_TXN_AMT), '99999999999999999.99')), NULL, NULL, NULL, NULL,
          NULL, NULL, 'E', l_errmsg, p_rrn_in, p_instcode_in, l_src_encr_pan,
          l_src_acct_number,  p_terminalid_in,l_hashkey_id);



 	   RETURN;
 	 EXCEPTION
 	   WHEN OTHERS THEN
 		l_errmsg        := 'PROBLEM WHILE INSERTING DATA INTO TRANSACTION LOG  DTL' ||
 					    substr(SQLERRM, 1, 300);
 		p_resp_code_out := '22'; -- server declined
 		ROLLBACK;
 		RETURN;
 	 END;



   if  L_DUPCHK_COUNT =1
     then

   BEGIN
      SELECT RESPONSE_CODE
        INTO P_RESP_CODE_OUT
        FROM VMSCMS.TRANSACTIONLOG_VW         A, 						--Added for VMS-5739/FSP-991
            (SELECT MIN(ADD_INS_DATE) MINDATE
              FROM VMSCMS.TRANSACTIONLOG_VW        						--Added for VMS-5739/FSP-991
             WHERE RRN = P_RRN_IN and ACCT_BALANCE is not null) B
       WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN_IN and ACCT_BALANCE is not null;
	   


     EXCEPTION
      WHEN OTHERS THEN
        P_ERRMSG_OUT    := 'PROBLEM WHILE SELECTING RESPONSE CODE OF ORIGINAL TRANSACTION' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE_OUT := '89'; -- Server Declined
        ROLLBACK;
        RETURN;
   END;

   END IF;

     WHEN OTHERS THEN
        p_errmsg_out := ' ERROR FROM MAIN ' || substr(SQLERRM, 1, 200);

     l_respcode :='89';
      	 ROLLBACK;

     BEGIN
 	   -- assign the response code to the out parameter
 	   SELECT cms_iso_respcde,cms_resp_desc
 	   INTO   p_resp_code_out,p_errmsg_out
 	   FROM   cms_response_mast
 	   WHERE  cms_inst_code = p_instcode_in AND
 			cms_delivery_channel = p_delivery_channel_in AND
 			cms_response_id = l_respcode;
 	 EXCEPTION
 	   WHEN OTHERS THEN
 		p_errmsg_out    := 'PROBLEM WHILE SELECTING DATA FROM RESPONSE MASTER ' ||
 					    l_respcode || substr(SQLERRM, 1, 300);
 		p_resp_code_out := '89';
 		ROLLBACK;
 		-- return;
 	 END;


          BEGIN
              SELECT cam_acct_bal, cam_ledger_bal
                INTO L_SRC_ACCT_BALANCE, l_src_ledger_balance
                FROM cms_acct_mast
               WHERE cam_acct_no = l_src_acct_number AND
                   cam_inst_code = p_instcode_in;
          EXCEPTION

              WHEN OTHERS THEN
                 l_respcode := '12';
                 l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
                         SQLERRM;
                 RAISE exp_main_reject_record;
          END;


 	 --sn create a entry in txn log
 	 BEGIN
          INSERT INTO transactionlog
         (msgtype, rrn, delivery_channel, terminal_id, date_time, txn_code,
          txn_type, txn_mode, txn_status, response_code, business_date,
          business_time, customer_card_no, topup_card_no, topup_acct_no,
          topup_acct_type, bank_code, total_amount, currencycode, addcharge,
          productid, categoryid, atm_name_location, auth_id, amount,
          preauthamount, partialamount, instcode, customer_card_no_encr,
          topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
          acct_balance, ledger_balance, response_id, cardstatus, error_msg,
          trans_desc, merchant_name,merchant_state,
          ssn_fail_dtls, store_id, time_stamp, orgnl_card_no,
          tran_reverse_flag)
          VALUES
         (p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
          l_business_date, l_txn_code, l_txn_type, p_txn_mode_in,
          decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
          p_trandate_in, substr(p_trantime_in, 1, 10), l_src_hash_pan,DECODE(l_txn_code,'43',l_trg_hash_pan,''),
          L_TRG_ACCT_NO, NULL, p_instcode_in,
          TRIM(to_char(decode(p_resp_code_out,'00',l_tran_amt,V_TXN_AMT), '99999999999999999.99')), l_currcode,
          NULL, l_src_prod_code, l_src_card_type, p_terminalid_in, l_auth_id,
          TRIM(to_char(decode(p_resp_code_out,'00',l_tran_amt,V_TXN_AMT), '99999999999999999.99')), NULL, NULL,
          p_instcode_in, l_src_encr_pan, l_trg_encr_pan, l_src_proxunumber,
          p_rvsl_code_in, l_src_acct_number, L_SRC_ACCT_BALANCE, l_src_ledger_balance,
          l_respcode, l_src_card_stat, l_errmsg, l_trans_desc,
          p_merchant_name_in,NULL,null,
          p_storeid_in, l_time_stamp, l_src_hash_pan, 'N');
 	 EXCEPTION
 	   WHEN OTHERS THEN
           p_resp_code_out := '89';
           p_errmsg_out    := 'PROBLEM WHILE INSERTING DATA INTO TRANSACTION LOG  DTL' ||
                     substr(SQLERRM, 1, 300);
 	 END;

 	 --en create a entry in txn log
 	 BEGIN
          INSERT INTO cms_transaction_log_dtl
         (ctd_delivery_channel, ctd_txn_code, ctd_msg_type, ctd_txn_mode,
          ctd_business_date, ctd_business_time, ctd_customer_card_no,
          ctd_txn_amount, ctd_txn_curr, ctd_actual_amount, ctd_fee_amount,
          ctd_waiver_amount, ctd_servicetax_amount, ctd_cess_amount,
          ctd_bill_amount, ctd_bill_curr, ctd_process_flag, ctd_process_msg,
          ctd_rrn, ctd_inst_code, ctd_customer_card_no_encr,
          ctd_cust_acct_number,
          ctd_location_id, ctd_hashkey_id)
          VALUES
         (p_delivery_channel_in, l_txn_code, p_msg_type_in,
          p_txn_mode_in, p_trandate_in, p_trantime_in, l_src_hash_pan,
          TRIM(to_char(decode(p_resp_code_out,'00',L_SRC_ACCT_BALANCE,V_TXN_AMT), '99999999999999999.99')), l_currcode,
          TRIM(to_char(decode(p_resp_code_out,'00',L_SRC_ACCT_BALANCE,V_TXN_AMT), '99999999999999999.99')), NULL, NULL, NULL, NULL,
          NULL, NULL, 'E', l_errmsg, p_rrn_in, p_instcode_in, l_src_encr_pan,
          l_src_acct_number,  p_terminalid_in,l_hashkey_id);



 	   RETURN;
 	 EXCEPTION
 	   WHEN OTHERS THEN
 		l_errmsg        := 'PROBLEM WHILE INSERTING DATA INTO TRANSACTION LOG  DTL' ||
 					    substr(SQLERRM, 1, 300);
 		p_resp_code_out := '22'; -- server declined
 		ROLLBACK;
 		RETURN;
 	 END;

   END balance_transfer_virtual;

   PROCEDURE balance_transfer_v_revrsl(p_instcode_in         IN NUMBER,
                    p_mbr_numb_in         IN VARCHAR2,
                    p_msg_type_in         IN VARCHAR2,
                    p_currcode_in         IN VARCHAR2,
                    p_rrn_in              IN VARCHAR2,
                    p_src_card_in         IN VARCHAR2,
                    p_trg_card_in         IN VARCHAR2,
                    p_delivery_channel_in IN VARCHAR2,
                    p_txn_code_in         IN VARCHAR2,
                    p_txn_mode_in         IN VARCHAR2,
                    p_trandate_in         IN VARCHAR2,
                    p_trantime_in         IN VARCHAR2,
                    p_terminalid_in       IN VARCHAR2,
                    p_merchant_name_in    IN VARCHAR2,
                    p_rvsl_code_in        IN VARCHAR2,
                    p_storeid_in          IN VARCHAR2,
                    p_store_add1_in       IN VARCHAR2,
                    p_store_add2_in       IN VARCHAR2,
                    p_store_city_in       IN VARCHAR2,
                    p_store_state_in      IN VARCHAR2,
                    P_Store_Zip_In        In Varchar2,
                    p_trans_amt_in        in varchar2,
                    P_Merchantid_In       In Varchar2,
                    p_locationId_in       in varchar2,
                    p_trg_bal_amt_out     OUT VARCHAR2,
                    p_src_bal_amt_out     OUT VARCHAR2,
                    p_trgt_card_stat_out  OUT VARCHAR2,
                    p_src_card_stat_out   OUT VARCHAR2,
                    p_src_proxy_no_out    OUT VARCHAR2,
                    p_auth_amnt_out       OUT VARCHAR2,
                    p_errmsg_out          OUT VARCHAR2,
                    p_resp_code_out       OUT VARCHAR2) is

   /*************************************************
        * Created  by      : Tilak
        * Created For     : VMS-951
        * Created Date    : 27-July-2019
        * Reviewer         :
        * Build Number     : R18
	
      * Created  by      : Ubaidur Rahman H
      * Created For      : Performance Change
      * Created Date     : 23-Sep-2019
      * Reviewer         : Saravanakumar A
      * Build Number     : R20

   *************************************************/
       l_orgnl_delivery_channel   transactionlog.delivery_channel%TYPE;
       l_orgnl_resp_code          transactionlog.response_code%TYPE;
       l_orgnl_txn_code           transactionlog.txn_code%TYPE;
       l_orgnl_txn_mode           transactionlog.txn_mode%TYPE;
       l_orgnl_business_date      transactionlog.business_date%TYPE;
       l_orgnl_business_time      transactionlog.business_time%TYPE;
       l_orgnl_customer_card_no   transactionlog.customer_card_no%TYPE;
       l_orgnl_total_amount       transactionlog.amount%TYPE;
       l_reversal_amt             transactionlog.amount%TYPE;
       l_resp_cde                 cms_response_mast.cms_response_id%TYPE;
       l_func_code                cms_func_mast.cfm_func_code%TYPE;
       l_dr_cr_flag               transactionlog.cr_dr_flag%TYPE;
       l_rvsl_trandate            DATE;
       l_errmsg                   VARCHAR2(500);
       l_actual_feecode           transactionlog.feecode%TYPE;
       l_orgnl_tranfee_amt        transactionlog.tranfee_amt%TYPE;
       l_orgnl_servicetax_amt     transactionlog.servicetax_amt%TYPE;
       l_orgnl_cess_amt           transactionlog.cess_amt%TYPE;
       l_orgnl_tranfee_cr_acctno  transactionlog.tranfee_cr_acctno%TYPE;
       l_orgnl_tranfee_dr_acctno  transactionlog.tranfee_dr_acctno%TYPE;
       l_orgnl_st_calc_flag       transactionlog.tran_st_calc_flag%TYPE;
       l_orgnl_cess_calc_flag     transactionlog.tran_cess_calc_flag%TYPE;
       l_orgnl_st_cr_acctno       transactionlog.tran_st_cr_acctno%TYPE;
       l_orgnl_st_dr_acctno       transactionlog.tran_st_dr_acctno%TYPE;
       l_orgnl_cess_cr_acctno     transactionlog.tran_cess_cr_acctno%TYPE;
       l_orgnl_cess_dr_acctno     transactionlog.tran_cess_dr_acctno%TYPE;
       l_src_prod_code            cms_appl_pan.cap_prod_code%TYPE;
       l_trg_prod_code            cms_appl_pan.cap_prod_code%TYPE;
       l_src_card_type            cms_appl_pan.cap_card_type%TYPE;
       l_tran_reverse_flag        transactionlog.tran_reverse_flag%TYPE;
       l_curr_code                transactionlog.currencycode%TYPE;
       l_auth_id                  transactionlog.auth_id%TYPE;
       l_cutoff_time              VARCHAR2(5);
       exp_rvsl_reject_record     EXCEPTION;
       l_src_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
       l_trg_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
       l_src_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
       l_trg_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
       l_card_curr                cms_inst_param.cip_param_value%TYPE;
       l_base_curr                cms_inst_param.cip_param_value%TYPE;
       l_currcode                 cms_inst_param.cip_param_value%TYPE;
       l_acct_balance             cms_acct_mast.cam_acct_bal%TYPE;
       l_ledger_balance           cms_acct_mast.cam_ledger_bal%TYPE;
       l_src_ledger_balance       cms_acct_mast.cam_ledger_bal%TYPE;
       l_tran_desc                cms_transaction_mast.ctm_tran_desc%TYPE;
       l_trg_cust_code            cms_cust_mast.ccm_cust_code%TYPE;
       l_trg_acct_no              cms_appl_pan.cap_acct_no%TYPE;
       l_trg_cap_acct_id          cms_appl_pan.cap_acct_id%type;
       l_trg_cust_no              cms_appl_pan.cap_cust_code%type;
       l_trg_txn_business_date    transactionlog.business_date%TYPE;
       l_trg_txn_business_time    transactionlog.business_time%TYPE;
       l_trg_txn_rrn              transactionlog.rrn%TYPE;
       l_trg_txn_terminalid       transactionlog.terminal_id%TYPE;
       l_trg_oldcrd_encr          cms_appl_pan.cap_pan_code_encr%TYPE;
       l_trg_oldcrd               cms_appl_pan.cap_pan_code%TYPE;
       l_trg_old_stat             cms_appl_pan.cap_card_stat%TYPE;
       l_trg_old_txn_code         transactionlog.txn_code%TYPE;
       l_src_old_stat             cms_appl_pan.cap_card_stat%TYPE;
       l_src_old_txn_code         transactionlog.txn_code%TYPE;
       l_src_proxunumber          cms_appl_pan.cap_proxy_number%TYPE;
       l_src_acct_number          cms_appl_pan.cap_acct_no%TYPE;
       l_txn_narration            cms_statements_log.csl_trans_narrration%TYPE;
       l_fee_narration            cms_statements_log.csl_trans_narrration%TYPE;
       l_src_cardstat             transactionlog.cardstatus%TYPE;
       l_txn_merchname            cms_statements_log.csl_merchant_name%TYPE;
       l_fee_merchname            cms_statements_log.csl_merchant_name%TYPE;
       l_txn_merchcity            cms_statements_log.csl_merchant_city%TYPE;
       l_fee_merchcity            cms_statements_log.csl_merchant_city%TYPE;
       l_txn_merchstate           cms_statements_log.csl_merchant_state%TYPE;
       l_fee_merchstate           cms_statements_log.csl_merchant_state%TYPE;
       l_trg_appl_code            cms_appl_pan.cap_appl_code%TYPE;
       l_trg_acct_id              cms_appl_pan.cap_acct_id%TYPE;
       l_cam_type_code            cms_acct_mast.cam_type_code%TYPE;
       l_timestamp                TIMESTAMP;
       l_txn_type                 transactionlog.txn_type%TYPE;
       l_tran_date                DATE;
       l_fee_plan                 cms_fee_plan.cfp_plan_id%TYPE;
       l_fee_amt                  transactionlog.amount%TYPE;
       l_fee_code                 cms_fee_mast.cfm_fee_code%TYPE;
       l_feeattach_type           VARCHAR2(2);
       l_src_hashkey_id           cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
       l_trg_cardactive_dt        cms_appl_pan.cap_active_date%TYPE;
       l_txn_code                 cms_transaction_mast.ctm_tran_code%TYPE;
       L_Bill_Addr 			   Cms_Appl_Pan.Cap_Bill_Addr%Type;
   	  l_dupchk_count		       number;
       l_dupchk_cardstat          transactionlog.cardstatus%TYPE;
       L_Dupchk_Acctbal           Transactionlog.Acct_Balance%Type;
       L_Trg_Cler_Pan    Number;
       l_tran_type             cms_transaction_mast.ctm_tran_type%type;
       L_Prfl_Flag             Cms_Transaction_Mast.Ctm_Prfl_Flag%Type;

       L_Trg_Acct_Balance        Cms_Acct_Mast.Cam_Acct_Bal%Type;
       l_trg_ledger_balance   Cms_Acct_Mast.Cam_Ledger_Bal%Type;
       l_remark     varchar2(200);


      L_TRG_Prfl_Code        Cms_Appl_Pan.Cap_Prfl_Code%Type;

      l_add_ins_date         transactionlog.add_ins_date %type;
	  
	  v_Retperiod  date;  --Added for VMS-5739/FSP-991
      v_Retdate  date; --Added for VMS-5739/FSP-991

     BEGIN
       p_resp_code_out := '00';
       l_errmsg := 'OK';
       p_errmsg_out := 'Success';

       l_timestamp := systimestamp;



       BEGIN
           l_src_hash_pan := gethash(p_src_card_in);
           EXCEPTION
            WHEN OTHERS THEN
              l_errmsg := 'Error while converting hash pan ' ||
                 substr(SQLERRM, 1, 200);
              RAISE exp_rvsl_reject_record;
       END;

       --EN CREATE HASH PAN

       --SN create encr pan
       BEGIN
           l_src_encr_pan := fn_emaps_main(p_src_card_in);
           EXCEPTION
            WHEN OTHERS THEN
              l_errmsg := 'Error while converting encr pan ' ||
                 substr(SQLERRM, 1, 200);
              RAISE exp_rvsl_reject_record;
       END;

       --EN create encr pan


    l_txn_code  := p_txn_code_in;
        begin
        lp_trans_details(p_instcode_in ,p_delivery_channel_in ,l_txn_code ,p_src_card_in,p_rrn_in,l_timestamp,l_src_hashkey_id,l_dr_cr_flag ,l_txn_type ,l_tran_type,l_prfl_flag,l_tran_desc,l_resp_cde ,l_errmsg);
        If L_Errmsg <> 'OK' Then
        	raise exp_rvsl_reject_record;
        end if;
        EXCEPTION WHEN  exp_rvsl_reject_record THEN
        RAISE;
        WHEN OTHERS THEN
         l_resp_cde := '89';
               l_errmsg   := 'ERROR WHILE SELECTING SOURCE CARD DETAILS ' ||
                       substr(SQLERRM, 1, 200);
               Raise exp_rvsl_reject_record;
      end;



       --Sn get date
       BEGIN
           l_rvsl_trandate := to_date(substr(TRIM(p_trandate_in), 1, 8) || ' ' ||
                        substr(TRIM(p_trantime_in), 1, 8),
                        'yyyymmdd hh24:mi:ss');
           l_tran_date := l_rvsl_trandate;

           EXCEPTION
            WHEN OTHERS THEN
              l_resp_cde := '89';
              l_errmsg   := 'Problem while converting transaction date ' ||
                   substr(SQLERRM, 1, 200);
              RAISE exp_rvsl_reject_record;
       END;

       --En get date

       --Sn generate auth id
       BEGIN

   	    SELECT lpad(seq_auth_id.NEXTVAL, 6, '0') INTO l_auth_id FROM dual;

         EXCEPTION
          WHEN OTHERS THEN
            l_errmsg   := 'Error while generating authid ' ||
                 substr(SQLERRM, 1, 300);
            l_resp_cde := '89';
            RAISE exp_rvsl_reject_record;
       END;

       BEGIN
           IF p_currcode_in IS NULL
           THEN
              BEGIN
                 SELECT cip_param_value
                   INTO l_base_curr
                   FROM cms_inst_param
                  WHERE cip_inst_code = p_instcode_in
                    AND cip_param_key = 'CURRENCY';

                 IF TRIM(l_base_curr) IS NULL
                 THEN
                   l_errmsg := 'Base currency cannot be null ';
                   RAISE exp_rvsl_reject_record;
                 END IF;

                 EXCEPTION
                     WHEN exp_rvsl_reject_record THEN
                       RAISE;
                     WHEN no_data_found THEN
                       l_errmsg := 'Base currency is not defined for the institution ';
                       RAISE exp_rvsl_reject_record;
                     WHEN OTHERS THEN
                       l_errmsg := 'Error while selecting base currency  ' ||
                           substr(SQLERRM, 1, 200);
                       RAISE exp_rvsl_reject_record;
              END;
              l_currcode := l_base_curr;
           ELSE
              l_currcode := p_currcode_in;
           END IF;
       END;

       BEGIN
           SELECT cap_proxy_number, cap_acct_no,
                  cap_card_stat, cap_prod_code,
                  cap_card_type
             INTO l_src_proxunumber, l_src_acct_number,
                  l_src_cardstat, l_src_prod_code,
                  l_src_card_type
             FROM cms_appl_pan
            WHERE cap_inst_code = p_instcode_in
              AND cap_pan_code = l_src_hash_pan
              AND cap_mbr_numb = p_mbr_numb_in;

           EXCEPTION
                WHEN exp_rvsl_reject_record THEN
                  RAISE;
                WHEN no_data_found THEN
                  l_errmsg   := 'Error while Fetching Prod Code  type - No Data found';
                  l_resp_cde := '89';
                  RAISE exp_rvsl_reject_record;
                WHEN OTHERS THEN
                  l_errmsg   := 'Error while Fetching Prod Code  type ' ||
                       substr(SQLERRM, 1, 200);
                  l_resp_cde := '89';
                  RAISE exp_rvsl_reject_record;
       END;

      Begin
           SELECT CAP_PAN_CODE,cap_pan_code_encr,fn_dmaps_main(cap_pan_code_encr),cap_prfl_code
           INTO l_trg_hash_pan,l_trg_encr_pan,l_trg_cler_pan,L_TRG_Prfl_Code
           FROM CMS_APPL_PAN
           WHERE CAP_SERIAL_NUMBER=p_trg_card_in and CAP_FORM_FACTOR is null
           AND cap_mbr_numb=p_mbr_numb_in
           AND cap_inst_code = p_instcode_in;
          EXCEPTION
          WHEN no_data_found THEN
             Begin
               Select Cap_Pan_Code,Cap_Pan_Code_Encr,Fn_Dmaps_Main(Cap_Pan_Code_Encr),Cap_Prfl_Code
               INTO l_trg_hash_pan,l_trg_encr_pan,l_trg_cler_pan,L_TRG_Prfl_Code
               FROM CMS_APPL_PAN
               WHERE cap_pan_code=gethash(p_trg_card_in)
               AND cap_mbr_numb=p_mbr_numb_in
               AND cap_inst_code = p_instcode_in;
              EXCEPTION
               WHEN no_data_found THEN
               l_resp_cde := '49';
               l_errmsg   := 'Target Card Not Found';
               RAISE exp_rvsl_reject_record;
             END;
      	    WHEN OTHERS THEN
               l_resp_cde := '89';
               l_errmsg   := 'ERROR WHILE SELECTING TARGET CARD DETAILS ' ||
                       substr(SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;

         END;


       BEGIN
           SELECT z.ccp_business_time, z.ccp_business_date,
                  z.ccp_rrn, z.ccp_terminal_id,
                  z.ccp_acct_no, z.ccp_acct_id,
                  z.ccp_cust_code
             INTO l_trg_txn_business_time, l_trg_txn_business_date,
                  l_trg_txn_rrn, l_trg_txn_terminalid,
                  l_trg_acct_no, l_trg_acct_id,
                  l_trg_cust_no
             FROM (SELECT ccp_business_time, ccp_business_date,
                          ccp_rrn, ccp_terminal_id,
                          ccp_acct_no,ccp_acct_id,ccp_cust_code
                     FROM cms_cardprofile_hist
                    WHERE ccp_pan_code = l_trg_hash_pan
                      AND ccp_inst_code = p_instcode_in
                      AND ccp_mbr_numb = p_mbr_numb_in
                  ORDER BY ccp_ins_date DESC) z
            WHERE rownum = 1;
           EXCEPTION
                WHEN no_data_found THEN
                  l_resp_cde := '53';
                  l_errmsg   := 'No Balance transfer was done';
                  RAISE exp_rvsl_reject_record;
                WHEN OTHERS THEN
                  l_resp_cde := '89';
                  l_errmsg   := 'Cannot get the Balance transfer details' || ' ' ||
                       substr(SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
       END;


       --Sn check orginal transaction
      BEGIN
          SELECT delivery_channel, response_code, txn_code,
                 txn_mode, business_date, business_time,
                 customer_card_no, amount, feecode,
                 tranfee_amt, servicetax_amt, cess_amt,
                 tranfee_cr_acctno, tranfee_dr_acctno,
                 tran_st_calc_flag, tran_cess_calc_flag,
                 tran_st_cr_acctno, tran_st_dr_acctno,
                 tran_cess_cr_acctno, tran_cess_dr_acctno,
                 currencycode, tran_reverse_flag,add_ins_date
            INTO l_orgnl_delivery_channel, l_orgnl_resp_code, l_orgnl_txn_code,
                 l_orgnl_txn_mode, l_orgnl_business_date, l_orgnl_business_time,
                 l_orgnl_customer_card_no, l_orgnl_total_amount, l_actual_feecode,
                 l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,l_orgnl_cess_amt,
                 l_orgnl_tranfee_cr_acctno, l_orgnl_tranfee_dr_acctno,
                 l_orgnl_st_calc_flag, l_orgnl_cess_calc_flag,
                 l_orgnl_st_cr_acctno, l_orgnl_st_dr_acctno,
                 L_Orgnl_Cess_Cr_Acctno, L_Orgnl_Cess_Dr_Acctno,
                 l_curr_code, l_tran_reverse_flag,l_add_ins_date
            FROM VMSCMS.TRANSACTIONLOG               --Added for VMS-5739/FSP-991
           WHERE rrn = p_rrn_in
             AND customer_card_no = l_src_hash_pan
             AND instcode = p_instcode_in
             And Delivery_Channel = P_Delivery_Channel_In
            -- AND txn_code = p_txn_code_in
             AND msgtype = '1200';
			  IF SQL%ROWCOUNT = 0 THEN
			  SELECT delivery_channel, response_code, txn_code,
                 txn_mode, business_date, business_time,
                 customer_card_no, amount, feecode,
                 tranfee_amt, servicetax_amt, cess_amt,
                 tranfee_cr_acctno, tranfee_dr_acctno,
                 tran_st_calc_flag, tran_cess_calc_flag,
                 tran_st_cr_acctno, tran_st_dr_acctno,
                 tran_cess_cr_acctno, tran_cess_dr_acctno,
                 currencycode, tran_reverse_flag,add_ins_date
            INTO l_orgnl_delivery_channel, l_orgnl_resp_code, l_orgnl_txn_code,
                 l_orgnl_txn_mode, l_orgnl_business_date, l_orgnl_business_time,
                 l_orgnl_customer_card_no, l_orgnl_total_amount, l_actual_feecode,
                 l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,l_orgnl_cess_amt,
                 l_orgnl_tranfee_cr_acctno, l_orgnl_tranfee_dr_acctno,
                 l_orgnl_st_calc_flag, l_orgnl_cess_calc_flag,
                 l_orgnl_st_cr_acctno, l_orgnl_st_dr_acctno,
                 L_Orgnl_Cess_Cr_Acctno, L_Orgnl_Cess_Dr_Acctno,
                 l_curr_code, l_tran_reverse_flag,l_add_ins_date
            FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST               --Added for VMS-5739/FSP-991
           WHERE rrn = p_rrn_in
             AND customer_card_no = l_src_hash_pan
             AND instcode = p_instcode_in
             And Delivery_Channel = P_Delivery_Channel_In
            -- AND txn_code = p_txn_code_in
             AND msgtype = '1200';
			  END IF;
			 
           EXCEPTION
              WHEN no_data_found THEN
                l_resp_cde := '89';
                l_errmsg   := 'Matching transaction not found';
                RAISE exp_rvsl_reject_record;
              WHEN too_many_rows THEN
                l_resp_cde := '89';
                l_errmsg   := 'More than one matching record found in the master';
                RAISE exp_rvsl_reject_record;
              WHEN OTHERS THEN
                l_resp_cde := '89';
                l_errmsg   := 'Error while selecting master data' ||
                     substr(SQLERRM, 1, 200);
                RAISE exp_rvsl_reject_record;
      End;


      IF l_orgnl_resp_code <> '00'
      THEN
          l_resp_cde := '53';
          l_errmsg   := ' The original transaction was not successful';
          RAISE exp_rvsl_reject_record;
      END IF;

      IF l_tran_reverse_flag = 'Y'
      THEN
          BEGIN
             SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
               INTO l_dupchk_cardstat, l_dupchk_acctbal
               FROM (SELECT CARDSTATUS, ACCT_BALANCE
                       FROM VMSCMS.TRANSACTIONLOG      --Added for VMS-5739/FSP-991
                      WHERE RRN = p_rrn_in
                        AND CUSTOMER_CARD_NO = l_src_hash_pan
                        AND DELIVERY_CHANNEL = p_delivery_channel_in
                        AND ACCT_BALANCE IS NOT NULL
                   ORDER BY add_ins_date DESC)
             WHERE ROWNUM = 1;
			  IF SQL%ROWCOUNT = 0 THEN
			       SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
               INTO l_dupchk_cardstat, l_dupchk_acctbal
               FROM (SELECT CARDSTATUS, ACCT_BALANCE
                       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST     --Added for VMS-5739/FSP-991
                      WHERE RRN = p_rrn_in
                        AND CUSTOMER_CARD_NO = l_src_hash_pan
                        AND DELIVERY_CHANNEL = p_delivery_channel_in
                        AND ACCT_BALANCE IS NOT NULL
                   ORDER BY add_ins_date DESC)
             WHERE ROWNUM = 1;
			  END IF;

             l_DUPCHK_COUNT:=1;
             EXCEPTION
               WHEN no_data_found THEN
                   l_DUPCHK_COUNT:=0;
               WHEN OTHERS THEN
                   l_resp_cde := '89';
                   l_errmsg   := 'Error while selecting card status and acct balance ' || SUBSTR(SQLERRM, 1, 200);
                   RAISE EXP_RVSL_REJECT_RECORD;
           END;

           IF l_DUPCHK_COUNT =1 THEN
               BEGIN
                   SELECT CAM_ACCT_BAL
                     INTO l_ACCT_BALANCE
                     FROM CMS_ACCT_MAST
                    WHERE CAM_ACCT_NO = l_src_acct_number
                      AND CAM_INST_CODE = p_instcode_in;

                   EXCEPTION
                       WHEN OTHERS THEN
                           l_resp_cde := '12';
                           l_errmsg   := 'Error while selecting acct balance ' || SUBSTR(SQLERRM, 1, 200);
                           RAISE exp_rvsl_reject_record;
               END;

               L_DUPCHK_COUNT:=0;

               IF l_DUPCHK_CARDSTAT= l_src_cardstat and l_DUPCHK_ACCTBAL=l_ACCT_BALANCE then
                   l_DUPCHK_COUNT:=1;
                   l_resp_cde := '52';
                   l_errmsg   := 'Reversal already done';
                   RAISE exp_rvsl_reject_record;
               END IF;

           END IF;
      END IF;


      BEGIN
         SELECT cap_active_date, cap_appl_code,
                cap_cust_code, cap_prod_code,
                cap_acct_id
           INTO l_trg_cardactive_dt, l_trg_appl_code,
                l_trg_cust_code, l_trg_prod_code,
                l_trg_cap_acct_id
           FROM cms_appl_pan
          WHERE cap_inst_code = p_instcode_in
            AND cap_pan_code = l_trg_hash_pan
            AND cap_mbr_numb = p_mbr_numb_in;

         IF l_trg_cardactive_dt IS NULL
         THEN
            l_resp_cde := '8';
            l_errmsg   := 'Balance transfer Reversal Cannot be done., Balance transfer Not done for this card';
            RAISE exp_rvsl_reject_record;
         END IF;

         EXCEPTION
            WHEN exp_rvsl_reject_record THEN
                 RAISE;
            WHEN no_data_found THEN
                 l_errmsg   := 'Error while Fetching Prod Code  type - No Data found';
                 l_resp_cde := '89';
                 RAISE exp_rvsl_reject_record;
            WHEN OTHERS THEN
                 l_errmsg   := 'Error while Fetching Prod Code  type ' ||
                       substr(SQLERRM, 1, 200);
                 l_resp_cde := '89';
                 RAISE exp_rvsl_reject_record;
       END;
       --En check orginal transaction

      BEGIN
          vmsfunutilities.get_currency_code(l_src_prod_code,l_src_card_type,p_instcode_in,l_card_curr,l_errmsg);
          IF l_errmsg <> 'OK' THEN
             l_resp_cde := '89';
             RAISE exp_rvsl_reject_record;
          END IF;

          EXCEPTION
             WHEN exp_rvsl_reject_record THEN
                 RAISE;
             WHEN OTHERS THEN
                 l_resp_cde := '69';
                 l_errmsg   := 'Error from currency conversion ' ||
                         substr(SQLERRM, 1, 200);
                 RAISE exp_rvsl_reject_record;
   	 END;

      l_reversal_amt := l_orgnl_total_amount;


       IF l_dr_cr_flag = 'NA' THEN
          l_resp_cde := '89';
          l_errmsg   := 'Not a valid orginal transaction for reversal';
          RAISE exp_rvsl_reject_record;
       END IF;

       ---Sn find cutoff time
       BEGIN
          SELECT cip_param_value
            INTO l_cutoff_time
            FROM cms_inst_param
           WHERE cip_param_key = 'CUTOFF'
             AND cip_inst_code = p_instcode_in;

          EXCEPTION
              WHEN no_data_found THEN
                   l_cutoff_time := 0;
                   l_resp_cde    := '89';
                   l_errmsg      := 'Cutoff time is not defined in the system';
                   RAISE exp_rvsl_reject_record;
              WHEN OTHERS THEN
                   l_resp_cde := '89';
                   l_errmsg   := 'Error while selecting cutoff  dtl  from system ' || ' ' ||
                        substr(SQLERRM, 1, 200);
                   RAISE exp_rvsl_reject_record;
       END;

       ---En find cutoff time
       BEGIN
          SELECT cam_type_code
            INTO l_cam_type_code
            FROM cms_acct_mast
           WHERE cam_acct_no = l_trg_acct_no
             AND cam_inst_code = p_instcode_in;
          EXCEPTION
              WHEN no_data_found THEN
                  l_resp_cde := '12';
                  l_errmsg   := 'Invalid Card ';
                  RAISE exp_rvsl_reject_record;
              WHEN OTHERS THEN
                  l_resp_cde := '12';
                  l_errmsg   := 'Error while selecting data from card Master for card number  ' || ' ' ||
                       substr(SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
       END;

       --Sn find narration

       BEGIN
	   
	   --Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)    --Added for VMS-5739/FSP-991
		THEN

			  SELECT csl_trans_narrration, csl_merchant_name,
					 csl_merchant_city, csl_merchant_state
				INTO l_txn_narration, l_txn_merchname,
					 l_txn_merchcity, l_txn_merchstate
				FROM cms_statements_log
			   WHERE csl_business_date = l_orgnl_business_date
				 AND csl_business_time = l_orgnl_business_time
				 AND csl_rrn = l_trg_txn_rrn
				 AND csl_delivery_channel = l_orgnl_delivery_channel
				 AND csl_txn_code = l_orgnl_txn_code
				 AND csl_pan_no = l_orgnl_customer_card_no
				 AND csl_inst_code = p_instcode_in
				 AND txn_fee_flag = 'N';
				 
	ELSE
				SELECT csl_trans_narrration, csl_merchant_name,
					 csl_merchant_city, csl_merchant_state
				INTO l_txn_narration, l_txn_merchname,
					 l_txn_merchcity, l_txn_merchstate
				FROM VMSCMS_HISTORY.cms_statements_log_HIST --Added for VMS-5739/FSP-991
			   WHERE csl_business_date = l_orgnl_business_date
				 AND csl_business_time = l_orgnl_business_time
				 AND csl_rrn = l_trg_txn_rrn
				 AND csl_delivery_channel = l_orgnl_delivery_channel
				 AND csl_txn_code = l_orgnl_txn_code
				 AND csl_pan_no = l_orgnl_customer_card_no
				 AND csl_inst_code = p_instcode_in
				 AND txn_fee_flag = 'N';
	END IF;
			 
          EXCEPTION
              WHEN no_data_found THEN
                l_txn_narration := NULL;
              WHEN OTHERS THEN
                l_txn_narration := NULL;
       END;

        IF l_orgnl_tranfee_amt > 0 THEN
           BEGIN
		   --Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)						--Added for VMS-5739/FSP-991
		THEN
				   SELECT csl_trans_narrration, csl_merchant_name,
						  csl_merchant_city, csl_merchant_state
					 INTO l_fee_narration, l_fee_merchname,
						  l_fee_merchcity, l_fee_merchstate
					 FROM cms_statements_log
					WHERE csl_business_date = l_orgnl_business_date
					  AND csl_business_time = l_orgnl_business_time
					  AND csl_rrn = l_trg_txn_rrn
					  AND csl_delivery_channel = l_orgnl_delivery_channel
					  AND csl_txn_code = l_orgnl_txn_code
					  AND csl_pan_no = l_orgnl_customer_card_no
					  AND csl_inst_code = p_instcode_in
					  AND txn_fee_flag = 'Y';
	ELSE
					SELECT csl_trans_narrration, csl_merchant_name,
						  csl_merchant_city, csl_merchant_state
					 INTO l_fee_narration, l_fee_merchname,
						  l_fee_merchcity, l_fee_merchstate
					 FROM VMSCMS_HISTORY.cms_statements_log_HIST        --Added for VMS-5739/FSP-991
					WHERE csl_business_date = l_orgnl_business_date
					  AND csl_business_time = l_orgnl_business_time
					  AND csl_rrn = l_trg_txn_rrn
					  AND csl_delivery_channel = l_orgnl_delivery_channel
					  AND csl_txn_code = l_orgnl_txn_code
					  AND csl_pan_no = l_orgnl_customer_card_no
					  AND csl_inst_code = p_instcode_in
					  AND txn_fee_flag = 'Y';
	END IF;

                EXCEPTION
                   WHEN no_data_found THEN
                       l_fee_narration := NULL;
                   WHEN OTHERS THEN
                       l_fee_narration := NULL;
           END;
        END IF;


       --En find narration

       --Sn reverse the amount
        BEGIN
           sp_reverse_card_amount(p_instcode_in, l_func_code, p_rrn_in,
                                  p_delivery_channel_in, l_trg_txn_terminalid,
                                  NULL, l_orgnl_txn_code, l_rvsl_trandate,
                                  p_txn_mode_in, p_src_card_in, l_reversal_amt,
                                  l_trg_txn_rrn, l_src_acct_number,
                                  p_trandate_in, p_trantime_in,
                                  l_auth_id, l_txn_narration,
                                  l_orgnl_business_date, l_orgnl_business_time,
                                  l_txn_merchname, l_txn_merchcity,
                                  l_txn_merchstate, l_resp_cde, l_errmsg);

           IF l_resp_cde <> '00' OR l_errmsg <> 'OK' THEN
              RAISE exp_rvsl_reject_record;
           END IF;

           EXCEPTION
                WHEN exp_rvsl_reject_record THEN
                  RAISE;
                WHEN OTHERS THEN
                  l_resp_cde := '89';
                  l_errmsg   := 'Error while reversing the amount ' ||
                       substr(SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
        END;

       --En reverse the amount
       --Sn reverse the fee
        BEGIN

            sp_reverse_fee_amount(p_instcode_in, p_rrn_in, p_delivery_channel_in,
                                 l_trg_txn_terminalid, NULL, l_orgnl_txn_code,
                                 l_rvsl_trandate, p_txn_mode_in,
                                 l_orgnl_tranfee_amt, p_src_card_in,
                                 l_actual_feecode, l_orgnl_tranfee_amt,
                                 l_orgnl_tranfee_cr_acctno,
                                 l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
                                 l_orgnl_servicetax_amt, l_orgnl_st_cr_acctno,
                                 l_orgnl_st_dr_acctno, l_orgnl_cess_calc_flag,
                                 l_orgnl_cess_amt, l_orgnl_cess_cr_acctno,
                                 l_orgnl_cess_dr_acctno, l_trg_txn_rrn,
                                 l_src_acct_number, p_trandate_in,
                                 p_trantime_in, l_auth_id, l_fee_narration,
                                 l_fee_merchname, l_fee_merchcity,
                                 l_fee_merchstate, l_resp_cde, l_errmsg);

            IF l_resp_cde <> '00' OR l_errmsg <> 'OK'
            THEN
               RAISE exp_rvsl_reject_record;
            END IF;

            EXCEPTION
                WHEN exp_rvsl_reject_record THEN
                  RAISE;
                WHEN OTHERS THEN
                  l_resp_cde := '89';
                  l_errmsg   := 'Error while reversing the fee amount ' ||
                       substr(SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
       END;


      BEGIN
         IF (L_TRG_Prfl_Code IS NOT NULL AND l_prfl_flag = 'Y')  THEN
                  Pkg_Limits_Check.Sp_Limitcnt_Rever_Reset
                                  (P_Instcode_In,
                                   null,
                                   Null,
                                   NULL,
                                   l_txn_code,
                                   L_Tran_Type,
                                   NULL,
                                   Null,
                                   L_TRG_Prfl_Code,
                                   l_reversal_amt,
                                   l_reversal_amt,
                                   P_Delivery_Channel_In,
                                   L_Trg_Hash_Pan,
                                   l_add_ins_date,
                                   l_resp_cde,
                                   l_errmsg
                                 );

         IF l_errmsg <> 'OK'
            THEN
                Raise Exp_Rvsl_Reject_Record;
            END IF;


        End If;
     EXCEPTION
                WHEN exp_rvsl_reject_record THEN
                  RAISE;
                WHEN OTHERS THEN
                  l_resp_cde := '89';
                  l_errmsg   := 'Error while Sp_Limitcnt_Rever_Reset ' ||
                       substr(SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;

          END;

       --En reverse the fee
       l_resp_cde := '1';
       BEGIN
         sp_tran_reversal_fees(p_instcode_in, p_src_card_in, p_delivery_channel_in,
                               l_orgnl_txn_mode, l_orgnl_txn_code, p_currcode_in,
                               NULL, NULL, l_reversal_amt, p_trandate_in,
                               p_trantime_in, NULL, NULL, l_resp_cde,
                               p_msg_type_in, p_mbr_numb_in, p_rrn_in,
                               p_terminalid_in, l_txn_merchname,
                               l_txn_merchcity, l_auth_id, l_fee_merchstate,
                               p_rvsl_code_in, l_txn_narration, l_txn_type,
                               l_tran_date, l_errmsg, l_resp_cde, l_fee_amt,
                               l_fee_plan, l_fee_code, l_feeattach_type);

            IF l_errmsg <> 'OK'
            THEN
                RAISE exp_rvsl_reject_record;
            END IF;
       END;

       BEGIN
            IF l_errmsg = 'OK' THEN
              INSERT INTO cms_transaction_log_dtl
             (ctd_delivery_channel, ctd_txn_code, ctd_txn_type, ctd_msg_type,
              ctd_txn_mode, ctd_business_date, ctd_business_time,
              ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
              ctd_actual_amount, ctd_bill_amount, ctd_bill_curr,
              ctd_process_flag, ctd_process_msg, ctd_rrn, ctd_inst_code,
              ctd_customer_card_no_encr, ctd_cust_acct_number,
              ctd_hashkey_id, ctd_location_id, ctd_store_address1, ctd_store_address2,
              ctd_store_city, ctd_store_state, ctd_store_zip)
              VALUES
             (p_delivery_channel_in, l_orgnl_txn_code, '1', p_msg_type_in,
              p_txn_mode_in, p_trandate_in, p_trantime_in,
              l_src_hash_pan, l_reversal_amt, l_currcode,
              l_reversal_amt, l_reversal_amt, l_card_curr,
              'Y', 'Successful', p_rrn_in, p_instcode_in,
              l_src_encr_pan, l_src_acct_number,
              l_src_hashkey_id, p_locationId_in, p_store_add1_in, p_store_add2_in,
              p_store_city_in, p_store_state_in, p_store_zip_in);
            END IF;
            EXCEPTION
                WHEN OTHERS THEN
                      l_errmsg   := 'Problem while inserting data in to CMS_TRANSACTION_LOG_DTL ' ||
                           substr(SQLERRM, 1, 300);
                      l_resp_cde := '89';
                      RAISE exp_rvsl_reject_record;
       END;


      Begin
            SELECT cam_ledger_bal
              INTO l_src_ledger_balance
              From Cms_Acct_Mast
             WHERE cam_acct_no = l_src_acct_number
               AND cam_inst_code = p_instcode_in;

             EXCEPTION
                WHEN no_data_found THEN
                    l_resp_cde := '12';
                    l_errmsg   := 'Invalid Card ';
                    RAISE exp_rvsl_reject_record;
                WHEN OTHERS THEN
                    l_resp_cde := '12';
                    l_errmsg   := 'Error while selecting data from card Master for card number ' ||
                         SQLERRM;
                    RAISE exp_rvsl_reject_record;
        END;

    BEGIN
            SELECT cam_ledger_bal
              INTO l_trg_ledger_balance
              From Cms_Acct_Mast
             WHERE cam_acct_no = l_trg_acct_no
               AND cam_inst_code = p_instcode_in;

             EXCEPTION
                WHEN no_data_found THEN
                    l_resp_cde := '12';
                    l_errmsg   := 'Invalid Card ';
                    RAISE exp_rvsl_reject_record;
                WHEN OTHERS THEN
                    l_resp_cde := '12';
                    l_errmsg   := 'Error while selecting data from card Master for card number ' ||
                         SQLERRM;
                    Raise Exp_Rvsl_Reject_Record;
        End;


        BEGIN
           UPDATE cms_appl_pan
                  SET cap_card_stat = cap_old_cardstat
                WHERE cap_inst_code = p_instcode_in
                  AND cap_pan_code = l_src_hash_pan
            RETURNING cap_card_stat INTO l_src_old_stat;

          SELECT DECODE(l_src_old_stat,
                        '0', '08',
                        '1', '01',
                        '2',	'48',
                        '3',	'41',
                        '6',	'80',
                        '7',	'EX',
                        '8',	'04',
                        '11', 'SH',
                        '12', '03',
                        '13', '09',
                        '15', '74',
                        '17', '49',
                        '18', '10',
                        'SC')
             INTO l_src_old_txn_code
             FROM DUAL;


           BEGIN
               sp_log_cardstat_chnge(p_instcode_in, l_src_hash_pan, l_src_encr_pan,
                         l_auth_id, l_src_old_txn_code, p_rrn_in,
                         p_trandate_in, p_trantime_in,
                         l_resp_cde, l_errmsg);

               IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
               THEN
                 l_resp_cde := '89';
                 RAISE exp_rvsl_reject_record;
               END IF;
               EXCEPTION
                   WHEN exp_rvsl_reject_record THEN
                       RAISE;
                   WHEN OTHERS THEN
                       l_resp_cde := '89';
                       l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
                            substr(SQLERRM, 1, 200);
                       RAISE exp_rvsl_reject_record;
           END;

           EXCEPTION
                 WHEN OTHERS THEN
                      l_resp_cde := '89';
                      l_errmsg   := 'Error while updating source card ' ||
                            substr(SQLERRM, 1, 100);
                      Raise Exp_Rvsl_Reject_Record;
        END;


        --Sn updating target card status

        BEGIN
           UPDATE cms_appl_pan
                  SET cap_card_stat = cap_old_cardstat,
                  cap_firsttime_topup = 'N',
                  CAP_ACTIVE_DATE = NULL,
                  cap_pin_off= NULL
                WHERE cap_inst_code = p_instcode_in
                  AND cap_pan_code = l_trg_hash_pan
            RETURNING cap_card_stat INTO l_trg_old_stat;

          SELECT DECODE(l_trg_old_stat,
                        '0', '08',
                        '1', '01',
                        '2',	'48',
                        '3',	'41',
                        '6',	'80',
                        '7',	'EX',
                        '8',	'04',
                        '11', 'SH',
                        '12', '03',
                        '13', '09',
                        '15', '74',
                        '17', '49',
                        '18', '10',
                        'SC')
             INTO l_trg_old_txn_code
             FROM DUAL;


           BEGIN
               sp_log_cardstat_chnge(p_instcode_in, l_trg_hash_pan, l_trg_encr_pan,
                         l_auth_id, l_trg_old_txn_code, p_rrn_in,
                         p_trandate_in, p_trantime_in,
                         l_resp_cde, l_errmsg);

               IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
               THEN
                 l_resp_cde := '89';
                 RAISE exp_rvsl_reject_record;
               END IF;
               EXCEPTION
                   WHEN exp_rvsl_reject_record THEN
                       RAISE;
                   WHEN OTHERS THEN
                       l_resp_cde := '89';
                       l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
                            substr(SQLERRM, 1, 200);
                       RAISE exp_rvsl_reject_record;
           END;

           EXCEPTION
                 WHEN OTHERS THEN
                      l_resp_cde := '89';
                      l_errmsg   := 'Error while updating source card ' ||
                            substr(SQLERRM, 1, 100);
                      Raise Exp_Rvsl_Reject_Record;
        END;



        BEGIN
           UPDATE cms_acct_mast
              SET cam_acct_bal = cam_acct_bal - l_reversal_amt,
                  cam_ledger_bal = cam_ledger_bal - l_reversal_amt,
                  cam_funding_acct_no = null
            WHERE Cam_Inst_Code = P_Instcode_In
              AND cam_acct_no = l_trg_acct_no;

        EXCEPTION
             WHEN OTHERS THEN
               l_errmsg   := 'Problem while updating balances ' ||
                    substr(SQLERRM, 1, 100);
               l_resp_cde := '89';
               RAISE exp_rvsl_reject_record;
        END;
		
       BEGIN
           UPDATE cms_acct_mast
              SET cam_funding_acct_no = null
            WHERE Cam_Inst_Code = P_Instcode_In
              AND cam_acct_no = l_src_acct_number;

       EXCEPTION
           WHEN OTHERS THEN
             l_errmsg   := 'Problem while updating funding account number ' ||
                  substr(SQLERRM, 1, 100);
             l_resp_cde := '89';
             RAISE exp_rvsl_reject_record;
        END;

        BEGIN
             INSERT INTO cms_statements_log
                         (csl_pan_no, csl_opening_bal,
                          csl_trans_amount,
                          csl_trans_type, csl_trans_date,
                          csl_closing_balance,
                          csl_trans_narrration, csl_inst_code,
                          csl_pan_no_encr, csl_rrn, csl_auth_id,
                          csl_business_date, csl_business_time, txn_fee_flag,
                          csl_delivery_channel, csl_txn_code, csl_acct_no,
                          csl_ins_user, csl_ins_date, csl_merchant_name,
                          csl_panno_last4digit,
                          csl_prod_code, csl_acct_type, csl_time_stamp,csl_card_type
                         )
             Values      (L_Trg_Hash_Pan, l_trg_ledger_balance,
                          NVL (l_reversal_amt, 0),
                          'DR', To_Date(P_Trandate_In, 'YYYYMMDD'),
                          l_trg_ledger_balance-l_reversal_amt,
                          'RVSL-' || l_txn_narration, p_instcode_in,
                          l_trg_encr_pan, p_rrn_in, l_auth_id,
                          P_Trandate_In, P_Trantime_In, 'N',
                          p_delivery_channel_in, l_orgnl_txn_code, l_trg_acct_no,
                          1, SYSDATE,p_merchant_name_in,
                          --SUBSTR (p_trg_card_in, - 4),
                          SUBSTR (l_trg_cler_pan, - 4),
                          l_src_prod_code, 1,systimestamp,l_src_card_type
                         );
                EXCEPTION
                     WHEN OTHERS THEN
                          l_resp_cde := '89';
                          l_errmsg := 'Error while inserting into CMS_STATEMENTS_LOG 1.0-'|| SUBSTR (SQLERRM, 1, 200);
                          RAISE exp_rvsl_reject_record;
        END;

         BEGIN
             SELECT ccs_stat_desc
               INTO p_src_card_stat_out
               FROM cms_card_stat
              WHERE ccs_stat_code =
                 ( SELECT cap_card_stat
                     FROM cms_appl_pan
                    WHERE cap_inst_code = p_instcode_in
                      AND cap_pan_code = l_src_hash_pan
                      AND cap_mbr_numb = p_mbr_numb_in);

             EXCEPTION
              WHEN exp_rvsl_reject_record THEN
                RAISE;
              WHEN no_data_found THEN
                l_errmsg   := 'Error while Fetching Card Status - No Data found';
                l_resp_cde := '89';
                RAISE exp_rvsl_reject_record;
              WHEN OTHERS THEN
                l_errmsg   := 'Error while Fetching card status ' ||
                     substr(SQLERRM, 1, 200);
                l_resp_cde := '89';
                RAISE exp_rvsl_reject_record;
         END;


      BEGIN
             SELECT ccs_stat_desc
               INTO p_trgt_card_stat_out
               FROM cms_card_stat
              WHERE ccs_stat_code =
                 ( SELECT cap_card_stat
                     FROM cms_appl_pan
                    WHERE cap_inst_code = p_instcode_in
                      AND cap_pan_code = L_Trg_Hash_Pan
                      AND cap_mbr_numb = p_mbr_numb_in);

             EXCEPTION
              WHEN no_data_found THEN
                l_errmsg   := 'Error while Fetching Card Status - No Data found';
                l_resp_cde := '89';
                RAISE exp_rvsl_reject_record;
              WHEN OTHERS THEN
                l_errmsg   := 'Error while Fetching card status ' ||
                     substr(SQLERRM, 1, 200);
                l_resp_cde := '89';
                RAISE exp_rvsl_reject_record;
         END;

           -- p_trgt_card_stat_out := 'INACTIVE';
          p_src_bal_amt_out :=trim(to_char(l_src_ledger_balance,'99999999999999990.99'));
          P_Auth_Amnt_Out :=L_Reversal_Amt;



            BEGIN
            Select Cam_Acct_Bal, Cam_Ledger_Bal
              INTO l_trg_acct_balance, l_trg_ledger_balance
              From Cms_Acct_Mast
             WHERE cam_acct_no = l_trg_acct_no
               AND cam_inst_code = p_instcode_in;

            EXCEPTION
              WHEN no_data_found THEN
                  l_resp_cde := '12';
                  l_errmsg   := 'Invalid Card ';
                  RAISE exp_rvsl_reject_record;
              WHEN OTHERS THEN
                  l_resp_cde := '12';
                  l_errmsg   := 'Error while selecting data from card Master for card number ' ||
                       SQLERRM;
                  RAISE exp_rvsl_reject_record;
             End;

            P_Trg_Bal_Amt_Out :=L_Trg_Ledger_Balance;


          p_src_proxy_no_out := l_src_proxunumber;


       --Sn generate response code
          l_resp_cde := '1';

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_instcode_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = to_number(l_resp_cde);
             EXCEPTION
                WHEN OTHERS THEN
                    l_errmsg   := 'Problem while selecting data from response master for respose code' ||
                         l_resp_cde || substr(SQLERRM, 1, 300);
                    l_resp_cde := '69';
                    RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO l_acct_balance, l_ledger_balance
              FROM cms_acct_mast
             WHERE cam_acct_no = l_src_acct_number
               AND cam_inst_code = p_instcode_in;

            EXCEPTION
              WHEN no_data_found THEN
                  l_resp_cde := '12';
                  l_errmsg   := 'Invalid Card ';
                  RAISE exp_rvsl_reject_record;
              WHEN OTHERS THEN
                  l_resp_cde := '12';
                  l_errmsg   := 'Error while selecting data from card Master for card number ' ||
                       SQLERRM;
                  RAISE exp_rvsl_reject_record;
         END;

            begin
            select 'From Account No : '|| vmscms.fn_mask_acct(L_TRG_ACCT_NO)||' '||'To Account No : ' ||vmscms.fn_mask_acct(l_src_acct_number)
              into l_remark
              from dual;
              EXCEPTION
                     WHEN OTHERS THEN
                         l_resp_cde := '89';
                         l_errmsg   := 'ERROR WHILE  format the remark-' ||
                              substr(SQLERRM, 1, 200);
                         Raise exp_rvsl_reject_record;
              end;

         BEGIN
            INSERT INTO transactionlog
              (msgtype, rrn, delivery_channel, terminal_id,
               date_time, txn_code, txn_type, txn_mode,
               txn_status, response_code,
               business_date, business_time, customer_card_no,
               topup_acct_no, topup_acct_type, bank_code,
               total_amount, rule_indicator,
               rulegroupid, currencycode, productid, categoryid, tips,
               decline_ruleid, atm_name_location, auth_id, trans_desc,
               amount,
               preauthamount, partialamount, mccodegroupid, currencycodegroupid,
               transcodegroupid, rules, preauth_date, gl_upd_flag, instcode,
               feecode, feeattachtype, tran_reverse_flag, customer_card_no_encr,
               topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
               acct_balance,
               ledger_balance,
               response_id, cardstatus, acct_type, time_stamp,
               Cr_Dr_Flag,
               error_msg, store_id, fee_plan, tranfee_amt, merchant_name,topup_acct_balance,topup_ledger_balance,remark,topup_card_no,orgnl_card_no,orgnl_rrn,orgnl_business_date,orgnl_business_time)
            VALUES
              (p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
               l_rvsl_trandate, l_orgnl_txn_code, '1', p_txn_mode_in,
               decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
               P_Trandate_In, Substr(P_Trantime_In, 1, 6), L_Src_Hash_Pan,
                L_TRG_ACCT_NO, '1', p_instcode_in,
               TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')), NULL,
               NULL, l_curr_code, l_src_prod_code, l_src_card_type, '0.00',
               NULL, NULL, l_auth_id, l_tran_desc,
               TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
               '0.00', '0.00', NULL, NULL,
               NULL, NULL, NULL, 'Y', p_instcode_in,
               l_fee_code, l_feeattach_type, 'N', l_src_encr_pan,
               l_trg_encr_pan, l_src_proxunumber, p_rvsl_code_in, l_src_acct_number,
               TRIM(to_char(nvl(l_acct_balance, 0), '99999999999999990.99')),
               TRIM(to_char(nvl(l_ledger_balance, 0), '99999999999999990.99')),
               l_resp_cde, l_src_old_stat, l_cam_type_code, l_timestamp,
               decode(p_delivery_channel_in, '04', l_dr_cr_flag,
               Decode(L_Dr_Cr_Flag, 'CR', 'DR', 'DR', 'CR', L_Dr_Cr_Flag)),
               L_Errmsg, P_Storeid_In, L_Fee_Plan, L_Fee_Amt, P_Merchant_Name_In,L_Trg_Acct_Balance,l_trg_ledger_balance,L_Remark,l_trg_hash_pan,l_orgnl_customer_card_no,l_trg_txn_rrn,L_Orgnl_Business_Date, L_Orgnl_Business_Time);


            EXCEPTION
                WHEN exp_rvsl_reject_record THEN
                     RAISE;
                WHEN OTHERS THEN
                      l_resp_cde := '89';
                      l_errmsg   := 'Error while inserting records in transaction log ' ||
                           substr(SQLERRM, 1, 200);
                      RAISE exp_rvsl_reject_record;
         END;

   	 --Sn update reverse flag
        BEGIN
		
		--Added for VMS-5739/FSP-991
		select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_trg_txn_business_date), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)  --Added for VMS-5739/FSP-991
		THEN
				UPDATE transactionlog
				   SET tran_reverse_flag = 'Y'
				 WHERE rrn = l_trg_txn_rrn
				   AND business_date = l_trg_txn_business_date
				   AND business_time = l_trg_txn_business_time
				   AND customer_card_no = l_src_hash_pan
				   AND instcode = p_instcode_in;
				   
	ELSE
				UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST      --Added for VMS-5739/FSP-991
				   SET tran_reverse_flag = 'Y'
				 WHERE rrn = l_trg_txn_rrn
				   AND business_date = l_trg_txn_business_date
				   AND business_time = l_trg_txn_business_time
				   AND customer_card_no = l_src_hash_pan
				   AND instcode = p_instcode_in;
	END IF;			   

            IF SQL%ROWCOUNT = 0
            THEN
               l_resp_cde := '89';
               l_errmsg   := 'Reverse flag is not updated ';
               RAISE exp_rvsl_reject_record;
            END IF;

          EXCEPTION
              WHEN exp_rvsl_reject_record THEN
                 RAISE;
              WHEN OTHERS THEN
                   l_resp_cde := '89';
                   l_errmsg   := 'Error while updating gl flag ' ||
                           substr(SQLERRM, 1, 200);
                   RAISE exp_rvsl_reject_record;
        END;


   		BEGIN
   		  DELETE from  cms_card_excpfee
   		   WHERE cce_inst_code = p_instcode_in
            AND cce_pan_code = l_trg_hash_pan;

         EXCEPTION
           WHEN OTHERS THEN
             l_errmsg   := 'Error while Deleting from cms_card_excpfee ' ||
                  substr(SQLERRM, 1, 200);
             l_resp_cde := '89';
             RAISE exp_rvsl_reject_record;
         END;

   	   IF l_errmsg <> 'OK' THEN
   	      p_errmsg_out := l_errmsg;
        END IF;


       --En  create a entry in GL
     EXCEPTION
       -- << MAIN EXCEPTION>>
      WHEN exp_rvsl_reject_record THEN
          ROLLBACK;
          BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO l_acct_balance, l_ledger_balance, l_cam_type_code
              FROM cms_acct_mast
             WHERE cam_acct_no = l_src_acct_number
               AND cam_inst_code = p_instcode_in;
            EXCEPTION
               WHEN OTHERS THEN
                   l_acct_balance   := 0;
                   l_ledger_balance := 0;
          END;

          BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_instcode_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = to_number(l_resp_cde);

            p_errmsg_out := l_errmsg;
            EXCEPTION
               WHEN OTHERS THEN
                   p_errmsg_out := 'Problem while selecting data from response master ' ||
                            l_resp_cde || substr(SQLERRM, 1, 300);
                   p_resp_code_out := '69';
          END;

          IF l_src_prod_code IS NULL
          THEN
             BEGIN
               SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
                 INTO l_src_prod_code, l_src_card_type, l_src_cardstat, l_src_acct_number
                 FROM cms_appl_pan
                WHERE cap_inst_code = p_instcode_in
                  AND cap_pan_code = l_src_hash_pan;

               EXCEPTION
                   WHEN OTHERS THEN
                       NULL;
             END;
          END IF;

          IF l_dr_cr_flag IS NULL
          THEN
              BEGIN
                 SELECT ctm_credit_debit_flag
                   INTO l_dr_cr_flag
                   FROM cms_transaction_mast
                  WHERE ctm_tran_code = l_txn_code
                    AND ctm_delivery_channel = p_delivery_channel_in
                    AND ctm_inst_code = p_instcode_in;

                 EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
              END;
          END IF;

          BEGIN
            INSERT INTO transactionlog
                 (msgtype, rrn, delivery_channel, terminal_id,
                  date_time, txn_code, txn_type, txn_mode,
                  txn_status, response_code,
                  business_date, business_time, customer_card_no,
                  topup_card_no, topup_acct_no, topup_acct_type,
                  bank_code, total_amount,
                  rule_indicator, rulegroupid, currencycode, productid,
                  categoryid, tips,decline_ruleid, atm_name_location,
                  auth_id, trans_desc, amount,
                  preauthamount, partialamount, mccodegroupid, currencycodegroupid,
                  transcodegroupid, rules, preauth_date, gl_upd_flag, instcode,
                  feecode, feeattachtype, tran_reverse_flag, customer_card_no_encr,
                  topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
                  acct_balance,
                  ledger_balance,
                  response_id, cardstatus, error_msg, acct_type,
                  time_stamp, cr_dr_flag,
                  store_id, fee_plan,tranfee_amt, merchant_name)
            VALUES
                 (p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
                  l_rvsl_trandate, l_txn_code, '1', p_txn_mode_in,
                  decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
                  p_trandate_in, substr(p_trantime_in, 1, 6), l_src_hash_pan,
                  l_trg_hash_pan, NULL, NULL,
                  p_instcode_in, TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
                  NULL, NULL, l_curr_code, l_src_prod_code,
                  l_src_card_type, '0.00', NULL, NULL,
                  l_auth_id, l_tran_desc, TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
                  '0.00', '0.00', NULL, NULL,
                  NULL, NULL, NULL, 'Y', p_instcode_in,
                  l_fee_code, l_feeattach_type, 'N', l_src_encr_pan,
                  l_trg_encr_pan, l_src_proxunumber, p_rvsl_code_in, l_src_acct_number,
                  TRIM(to_char(nvl(l_acct_balance, 0), '99999999999999990.99')),
                  TRIM(to_char(nvl(l_ledger_balance, 0), '99999999999999990.99')),
                  l_resp_cde, nvl(l_src_old_stat,l_src_cardstat), l_errmsg, l_cam_type_code,
                  nvl(l_timestamp, systimestamp), decode(p_delivery_channel_in, '04', l_dr_cr_flag,
                  decode(l_dr_cr_flag, 'CR', 'DR', 'DR', 'CR', l_dr_cr_flag)),
                  p_storeid_in, l_fee_plan, l_fee_amt, p_merchant_name_in);
          EXCEPTION
            WHEN OTHERS THEN
                   p_errmsg_out := 'Problem while inserting data into transaction log  dtl' ||
                            substr(SQLERRM, 1, 300);
                   p_resp_code_out := '69'; -- Server Declined
                   ROLLBACK;
                   RETURN;
          END;

          BEGIN
              INSERT INTO cms_transaction_log_dtl
                   (ctd_delivery_channel, ctd_txn_code, ctd_txn_type, ctd_msg_type,
                    ctd_txn_mode, ctd_business_date, ctd_business_time,
                    ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                    ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                    ctd_servicetax_amount, ctd_cess_amount, ctd_bill_amount,
                    ctd_bill_curr, ctd_process_flag, ctd_process_msg, ctd_rrn,
                    ctd_inst_code, ctd_customer_card_no_encr, ctd_cust_acct_number,
                    ctd_location_id, ctd_hashkey_id, ctd_store_address1, ctd_store_address2,
                    ctd_store_city, ctd_store_state, ctd_store_zip)
              VALUES
                   (p_delivery_channel_in, l_txn_code, '1', p_msg_type_in,
                    p_txn_mode_in, p_trandate_in, p_trantime_in,
                    l_src_hash_pan, l_reversal_amt, l_currcode,
                    l_reversal_amt, NULL, NULL,
                    NULL, NULL, l_reversal_amt,
                    l_card_curr, 'E', l_errmsg, p_rrn_in,
                    p_instcode_in, l_src_encr_pan, l_src_acct_number,
                    p_terminalid_in, l_src_hashkey_id, p_store_add1_in, p_store_add2_in,
                    p_store_city_in, p_store_state_in, p_store_zip_in);
            EXCEPTION
              WHEN OTHERS THEN
             p_errmsg_out := 'Problem while inserting data into transaction log  dtl' ||
                      substr(SQLERRM, 1, 300);
             p_resp_code_out := '69';
             ROLLBACK;
             RETURN;
   	     END;

          IF L_DUPCHK_COUNT = 1 then 
              BEGIN
                  SELECT RESPONSE_CODE
                    INTO p_resp_code_out
                    FROM VMSCMS.TRANSACTIONLOG_VW  A,           --Added for VMS-5739/FSP-991
                       (SELECT MIN(ADD_INS_DATE) MINDATE
                          FROM VMSCMS.TRANSACTIONLOG_VW        --Added for VMS-5739/FSP-991
                         WHERE RRN = p_rrn_in
                           AND ACCT_BALANCE IS NOT NULL) B
                   WHERE A.ADD_INS_DATE = MINDATE
                     AND RRN = p_rrn_in
                     AND ACCT_BALANCE IS NOT NULL;
					


                   EXCEPTION
                    WHEN OTHERS THEN
                      p_errmsg_out    := 'Problem in selecting the response detail of Original transaction' ||
                            SUBSTR(SQLERRM, 1, 300);
                      p_resp_code_out := '89';
                      ROLLBACK;
                      RETURN;
              END;

         BEGIN
            SELECT cam_ledger_bal
              INTO l_src_ledger_balance
              FROM cms_acct_mast
             WHERE cam_acct_no = l_src_acct_number
               AND cam_inst_code = p_instcode_in;

             EXCEPTION
                  When Others Then
                      p_errmsg_out    := 'Problem in selecting the ledger balance of source card' ||
                            SUBSTR(SQLERRM, 1, 300);
                      p_resp_code_out := '89';
                      ROLLBACK;
                      RETURN;
        End;

         BEGIN
            SELECT cam_ledger_bal
              INTO l_trg_ledger_balance
              FROM cms_acct_mast
             WHERE cam_acct_no = l_trg_acct_no
               AND cam_inst_code = p_instcode_in;

             EXCEPTION
                  When Others Then
                      p_errmsg_out    := 'Problem in selecting the ledger balance of target card.' ||
                            SUBSTR(SQLERRM, 1, 300);
                      p_resp_code_out := '89';
                      ROLLBACK;
                      RETURN;
        End;
         BEGIN
             SELECT ccs_stat_desc
               INTO p_trgt_card_stat_out
               FROM cms_card_stat
              WHERE ccs_stat_code =
                 ( SELECT cap_card_stat
                     FROM cms_appl_pan
                    WHERE cap_inst_code = p_instcode_in
                      AND cap_pan_code = L_Trg_Hash_Pan
                      AND cap_mbr_numb = p_mbr_numb_in);

             EXCEPTION
                 When Others Then
                      p_errmsg_out    := 'Problem in selecting the card status description ' ||
                            SUBSTR(SQLERRM, 1, 300);
                      p_resp_code_out := '89';
                      ROLLBACK;
                      RETURN;
         END;

         -- p_trgt_card_stat_out := 'INACTIVE';
          P_Src_Bal_Amt_Out :=Trim(To_Char(L_Src_Ledger_Balance,'99999999999999990.99'));

           P_Trg_Bal_Amt_Out := Trim(To_Char(l_trg_ledger_balance,'99999999999999990.99'));



          P_Src_Proxy_No_Out := L_Src_Proxunumber;
          p_auth_amnt_out := l_orgnl_total_amount;

         BEGIN
             SELECT ccs_stat_desc
               INTO p_src_card_stat_out
               FROM cms_card_stat
              WHERE ccs_stat_code =
                 ( SELECT cap_card_stat
                     FROM cms_appl_pan
                    WHERE cap_inst_code = p_instcode_in
                      AND cap_pan_code = l_src_hash_pan
                      AND cap_mbr_numb = p_mbr_numb_in);

             EXCEPTION
              WHEN exp_rvsl_reject_record THEN
                RAISE;
              WHEN no_data_found THEN
                l_errmsg   := 'Error while Fetching Card Status - No Data found';
                l_resp_cde := '89';
                RAISE exp_rvsl_reject_record;
              WHEN OTHERS THEN
                l_errmsg   := 'Error while Fetching card status ' ||
                     substr(SQLERRM, 1, 200);
                l_resp_cde := '89';
                RAISE exp_rvsl_reject_record;
         END;

          END IF;

        p_errmsg_out := l_errmsg;
        WHEN OTHERS THEN
         	 ROLLBACK;
            BEGIN
             SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
               INTO l_acct_balance, l_ledger_balance, l_cam_type_code
               FROM cms_acct_mast
              WHERE cam_acct_no = l_src_acct_number
                AND cam_inst_code = p_instcode_in;
             EXCEPTION
                WHEN OTHERS THEN
                     l_acct_balance   := 0;
                     l_ledger_balance := 0;
            END;

            BEGIN
              SELECT cms_iso_respcde
                INTO p_resp_code_out
                FROM cms_response_mast
               WHERE cms_inst_code = p_instcode_in
                 AND cms_delivery_channel = p_delivery_channel_in
                 AND cms_response_id = to_number(l_resp_cde);

              p_errmsg_out := l_errmsg;
              EXCEPTION
                WHEN OTHERS THEN
                     p_errmsg_out := 'Problem while selecting data from response master ' ||
                              l_resp_cde || substr(SQLERRM, 1, 300);
                     p_resp_code_out := '69';
            END;

            IF l_src_prod_code IS NULL
            THEN

              BEGIN
                 SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
                   INTO l_src_prod_code, l_src_card_type, l_src_cardstat, l_src_acct_number
                   FROM cms_appl_pan
                  WHERE cap_inst_code = p_instcode_in
                    AND cap_pan_code = l_src_hash_pan;
              EXCEPTION
                 WHEN OTHERS THEN
                     NULL;
              END;
            END IF;

            IF l_dr_cr_flag IS NULL
            THEN
               BEGIN
                   SELECT ctm_credit_debit_flag
                     INTO l_dr_cr_flag
                     FROM cms_transaction_mast
                    WHERE ctm_tran_code = l_txn_code
                      AND ctm_delivery_channel = p_delivery_channel_in
                      AND ctm_inst_code = p_instcode_in;

                  EXCEPTION
                     WHEN OTHERS THEN
                         NULL;
              END;
            END IF;


            BEGIN
              INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code,txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type, bank_code,
                      total_amount,
                      rule_indicator, rulegroupid, currencycode, productid, categoryid, tips,
                      decline_ruleid, atm_name_location, auth_id, trans_desc,
                      amount,
                      preauthamount, partialamount, mccodegroupid, currencycodegroupid,
                      transcodegroupid, rules, preauth_date, gl_upd_flag, instcode,
                      feecode, feeattachtype, tran_reverse_flag, customer_card_no_encr,
                      topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance, response_id,
                      cardstatus, error_msg, acct_type,
                      time_stamp, cr_dr_flag,
                      store_id, fee_plan, tranfee_amt, merchant_name)
              VALUES
                     (p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
                      l_rvsl_trandate, l_txn_code, '1', p_txn_mode_in,
                      decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
                      p_trandate_in, substr(p_trantime_in, 1, 6), l_src_hash_pan,
                      l_trg_hash_pan, NULL, NULL, p_instcode_in,
                      TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
                      NULL, NULL, l_curr_code, l_src_prod_code, l_src_card_type, '0.00',
                      NULL, NULL, l_auth_id, l_tran_desc,
                      TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
                      '0.00', '0.00', NULL, NULL,
                      NULL, NULL, NULL, 'Y', p_instcode_in,
                      l_fee_code, l_feeattach_type, 'N', l_src_encr_pan,
                      l_trg_encr_pan, l_src_proxunumber, p_rvsl_code_in, l_src_acct_number,
                      nvl(l_acct_balance, 0), nvl(l_ledger_balance, 0), l_resp_cde,
                      l_src_cardstat, l_errmsg, l_cam_type_code,
                      nvl(l_timestamp, systimestamp),
                      decode(p_delivery_channel_in, '04', l_dr_cr_flag,
                           decode(l_dr_cr_flag, 'CR', 'DR', 'DR', 'CR', l_dr_cr_flag)),
                      p_storeid_in, l_fee_plan, l_fee_amt, p_merchant_name_in);
                EXCEPTION
                  WHEN OTHERS THEN
                       p_errmsg_out := 'Problem while inserting data into transaction log  dtl' ||
                                substr(SQLERRM, 1, 300);
                       p_resp_code_out := '69'; -- Server Declined
                       ROLLBACK;
                       RETURN;
            END;

            BEGIN
                INSERT INTO cms_transaction_log_dtl
                   (ctd_delivery_channel, ctd_txn_code, ctd_txn_type, ctd_msg_type,
                    ctd_txn_mode, ctd_business_date, ctd_business_time,
                    ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                    ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                    ctd_servicetax_amount, ctd_cess_amount, ctd_bill_amount,
                    ctd_bill_curr, ctd_process_flag, ctd_process_msg, ctd_rrn,
                    ctd_inst_code, ctd_customer_card_no_encr, ctd_cust_acct_number,
                    ctd_location_id, ctd_hashkey_id, ctd_store_address1, ctd_store_address2,
                    ctd_store_city, ctd_store_state, ctd_store_zip)
                VALUES
                   (p_delivery_channel_in, l_txn_code, '1', p_msg_type_in,
                    p_txn_mode_in, p_trandate_in, p_trantime_in,
                    l_src_hash_pan, l_reversal_amt, l_currcode,
                    l_reversal_amt, NULL, NULL,
                    NULL, NULL, l_reversal_amt,
                    l_card_curr, 'E', l_errmsg, p_rrn_in,
                    p_instcode_in, l_src_encr_pan, l_src_acct_number,
                    p_terminalid_in, l_src_hashkey_id, p_store_add1_in, p_store_add2_in,
                    p_store_city_in, p_store_state_in, p_store_zip_in);
                EXCEPTION
                  WHEN OTHERS THEN
                       p_errmsg_out := 'Problem while inserting data into transaction log  dtl' ||
                                substr(SQLERRM, 1, 300);
                       p_resp_code_out := '69';
                       ROLLBACK;
                       return;
            END;
     END balance_transfer_v_revrsl;
  
  
END;
/
show error;