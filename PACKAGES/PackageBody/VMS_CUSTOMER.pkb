set define off;
create or replace
PACKAGE BODY       VMSCMS.VMS_CUSTOMER AS

   -- Private constant declarations 
   PROCEDURE get_cust_acct_details (
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
      p_resp_code_out              OUT  VARCHAR2,
      p_resp_msg_out               OUT  VARCHAR2,
      p_sav_acct_status_out        OUT  VARCHAR2,
      p_is_sav_acc_elig_out        OUT  VARCHAR2,
      p_prod_desc_out              OUT  VARCHAR2,
      p_prod_catg_desc_out         OUT  VARCHAR2,
      p_fee_plan_id_out            OUT  VARCHAR2,
      p_spend_acct_no_out          OUT  VARCHAR2,
      p_spend_rout_no_out          OUT  VARCHAR2,
      p_spend_transit_no_out       OUT  VARCHAR2,
      p_spend_inst_id_out          OUT  VARCHAR2,
      p_spend_ledger_bal_out       OUT  VARCHAR2,
      p_spend_avail_bal_out        OUT  VARCHAR2,
      p_spend_fee_accrued_out      OUT  VARCHAR2,
      p_sav_acct_no_out            OUT  VARCHAR2,
      p_remain_transfer_out        OUT  VARCHAR2,
      p_availed_transfer_out       OUT  VARCHAR2,
      p_sav_ledger_bal_out         OUT  VARCHAR2,
      p_last_txn_date_out          OUT  VARCHAR2,
      p_daily_int_accrd_out        OUT  VARCHAR2,
      p_qtd_interest_out           OUT  VARCHAR2,
      p_ytd_interest_out           OUT  VARCHAR2,
      p_sav_acc_create_out         OUT  VARCHAR2,
      p_sav_acc_reopen_out         OUT  VARCHAR2,
      p_last_four_pan_out          OUT  VARCHAR2,
      p_card_status_out            OUT  VARCHAR2,
      p_active_date_out            OUT  VARCHAR2,
      p_expiry_date_out            OUT  VARCHAR2,
      p_shipped_date_out           OUT  VARCHAR2,
      p_last_used_date_out         OUT  VARCHAR2,
      p_initial_load_out           OUT  VARCHAR2,
      p_name_on_card_out           OUT  VARCHAR2,
      p_is_starter_out             OUT  VARCHAR2,
      p_serial_number_out          OUT  VARCHAR2,
      p_cvvplus_token_out          OUT  VARCHAR2,
      p_cvvplus_eligibile_out      OUT  VARCHAR2,
      p_cvvplus_registered_out     OUT  VARCHAR2,
      p_cvvplus_status_out         OUT  VARCHAR2,
      p_cvvplus_account_id_out     OUT  VARCHAR2,
      p_cvvplus_regid_out          OUT  VARCHAR2
   )
   AS
      
   /************************************************************************************************************
   * Modified by      : Raj Devkota
   * Modified Date    : 08/31/2020
   * Modified For     : VMS-2618
   * Reviewer         : Ubaidur
   * Build Number     : VMSR35_B0003 
   
   * Modified by      : Saravanakumar
   * Modified Date    : 11/15/2021
   * Modified For     : VMS-4098
   * Reviewer         : Saravanakumar
   * Build Number     : VMSR54_B0002 
   
   * Modified By      : venkat Singamaneni
    * Modified Date    : 05-11-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jay
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
   ***********************************************************************************************************
   */
      l_err_msg             transactionlog.error_msg%TYPE;
      l_txn_type            cms_transaction_mast.ctm_tran_type%TYPE;
      l_max_no_trans        cms_dfg_param.cdp_param_value%TYPE := 0;
      l_saving_reopen       cms_dfg_param.cdp_param_value%TYPE;
      l_savings_count       VARCHAR2(2);
      l_ytd_interest_hist   cms_interest_detl_hist.cid_interest_amount%TYPE;
      l_tran_date           DATE;
      l_hash_pan            cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan            cms_appl_pan.cap_pan_code_encr%TYPE;
      l_card_stat           cms_appl_pan.cap_card_stat%TYPE;
      l_prod_code           cms_appl_pan.cap_prod_code%TYPE;
      l_card_type           cms_appl_pan.cap_card_type%TYPE;
      l_expry_date          cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code           cms_appl_pan.cap_prfl_code%TYPE;
      l_proxy_number        cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_id             cms_appl_pan.cap_acct_id%TYPE;
      l_cr_dr_flag          cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_tran_desc           cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag           cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_preauth_flag        cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_login_txn           cms_transaction_mast.ctm_login_txn%TYPE;
      l_preauth_type        cms_transaction_mast.ctm_preauth_type%TYPE;
      l_dup_rrn_check       cms_transaction_mast.ctm_rrn_check%TYPE;
      l_acct_type           cms_acct_mast.cam_type_code%TYPE;
      l_savtospd_tfer_count cms_acct_mast.cam_savtospd_tfer_count%TYPE;
      l_sav_lupd_date       cms_acct_mast.cam_lupd_date%TYPE;
      l_stat_code           cms_acct_mast.cam_stat_code%TYPE;
      l_cust_code           cms_cust_mast.ccm_cust_code%TYPE;
      l_auth_id             transactionlog.auth_id%TYPE;
      l_fee_code            transactionlog.feecode%TYPE;
      l_fee_plan            transactionlog.fee_plan%TYPE;
      l_feeattach_type      transactionlog.feeattachtype%TYPE;
      l_tranfee_amt         transactionlog.tranfee_amt%TYPE;
      l_total_amt           cms_acct_mast.cam_acct_bal%TYPE;
      l_hashkey_id          cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_appl_code           cms_caf_info_entry.cci_appl_code%TYPE;
      l_comb_hash           pkg_limits_check.type_hash;
      l_timestamp           transactionlog.time_stamp%TYPE;
	  l_audit_flag		    cms_transaction_mast.ctm_txn_log_flag%TYPE;
      exp_reject_record     EXCEPTION;
	  l_DENOMINATION       vms_order_lineitem.vol_denomination%TYPE;
      l_PRODUCT_FUNDING    vms_order_lineitem.vol_product_funding%TYPE;
      l_FUND_AMOUNT        vms_order_lineitem.vol_FUND_AMOUNT%TYPE;
      l_b2b_flag           cms_prod_cattype.cpc_b2b_flag%TYPE;
      l_pan_inventory_flag cms_prod_cattype.cpc_pan_inventory_flag%TYPE;
      l_repl_flag           cms_appl_pan.cap_repl_flag%TYPE;
      l_pan_code            cms_appl_pan.cap_pan_code%type;
	  v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
   BEGIN
      BEGIN
        p_resp_msg_out :='success';

         BEGIN
            SELECT pan.cap_pan_code, pan.cap_pan_code_encr, pan.cap_acct_no,
                   pan.cap_card_stat, pan.cap_prod_code, pan.cap_card_type,
                   to_char(pan.cap_expry_date, 'YYYY-MM-DD'),
                   to_char(pan.cap_active_date, 'YYYY-MM-DD'), pan.cap_prfl_code,
                   pan.cap_proxy_number, decode(pan.cap_startercard_flag,'Y', 'true', 'false'),
                   pan.cap_serial_number, decode(pan.cap_cvvplus_reg_flag,'Y', 'true', 'false'),
                   decode(pan.cap_cvvplus_active_flag,'Y', 'Active', 'NotActive'),pan.cap_acct_id, to_char(pan.cap_last_txndate, 'YYYY-MM-DD'),pan.cap_appl_code,
                   to_char(cardissu.ccs_shipped_date, 'YYYY-MM-DD'),
                   prod.cpm_prod_desc, cattype.cpc_cardtype_desc, cattype.cpc_rout_num,
                   cattype.cpc_transit_number, decode(cattype.cpc_cvvplus_eligibility,'Y', 'true', 'false'),
                   cust.ccm_cust_code, decode(cattype.cpc_encrypt_enable,'Y',fn_dmaps_main(cust.ccm_first_name),cust.ccm_first_name),cattype.cpc_b2b_flag,cattype.cpc_pan_inventory_flag
                   , pan.cap_repl_flag
              INTO l_hash_pan, l_encr_pan, p_spend_acct_no_out,
                   l_card_stat, l_prod_code, l_card_type,
                   p_expiry_date_out, p_active_date_out, l_prfl_code,
                   l_proxy_number, p_is_starter_out,
                   p_serial_number_out, p_cvvplus_registered_out,
                   p_cvvplus_status_out,l_acct_id,
                   p_last_used_date_out, l_appl_code, p_shipped_date_out,
                   p_prod_desc_out, p_prod_catg_desc_out, p_spend_rout_no_out,
                   p_spend_transit_no_out, p_cvvplus_eligibile_out,
                    l_cust_code, p_name_on_card_out,l_b2b_flag,l_pan_inventory_flag, l_repl_flag
              FROM cms_appl_pan pan, cms_cardissuance_status cardissu,
                   cms_prod_mast prod, cms_prod_cattype cattype,
                   cms_cust_mast cust
             WHERE pan.cap_inst_code = p_inst_code_in
               AND pan.cap_pan_code  = gethash (p_pan_code_in)
               AND pan.cap_mbr_numb  = '000'
               AND pan.cap_pan_code  = cardissu.ccs_pan_code
               AND prod.cpm_inst_code = pan.cap_inst_code
               AND prod.cpm_prod_code = pan.cap_prod_code
               AND cattype.cpc_inst_code = prod.cpm_inst_code
               AND cattype.cpc_prod_code = pan.cap_prod_code
               AND cattype.cpc_card_type = pan.cap_card_type
               AND cust.ccm_inst_code = prod.cpm_inst_code
               AND cust.ccm_cust_code = pan.cap_cust_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  p_resp_code_out := '21';
                  l_err_msg := 'Invalid Card number ' || gethash (p_pan_code_in);
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_err_msg :=
                        'Problem while selecting CMS_APPL_PAN'
                        || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
         END;
		 
		 BEGIN  
                    
               SELECT nvl(ctm_txn_log_flag,'T')
                 INTO l_audit_flag
                 FROM cms_transaction_mast
                WHERE ctm_inst_code = 1
                  AND ctm_tran_code = p_txn_code_in
                  AND ctm_delivery_channel = p_del_channel_in;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code_out := '12';
                  l_err_msg :=
                        'Error while selcting txn log type'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
         END;

    p_last_four_pan_out := substr(p_pan_code_in, length(p_pan_code_in) - 3 );

        IF l_card_stat = 0
         THEN
            IF p_active_date_out IS NULL
            THEN
               p_card_status_out := 'INACTIVE';
            ELSE
               p_card_status_out := 'BLOCKED';
            END IF;
         ELSE
            BEGIN
               SELECT ccs_stat_desc
                 INTO p_card_status_out
                 FROM cms_card_stat
                WHERE ccs_stat_code = l_card_stat;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code_out := '12';
                  l_err_msg :=
                        'Error while selcting card status description'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

-- SN Get Transaction details
         BEGIN
            vmscommon.get_transaction_details (p_inst_code_in,
                                               p_del_channel_in,
                                               p_txn_code_in,
                                               l_cr_dr_flag,
                                               l_txn_type,
                                               l_tran_desc,
                                               l_prfl_flag,
                                               l_preauth_flag,
                                               l_login_txn,
                                               l_preauth_type,
                                               l_dup_rrn_check,
                                               p_resp_code_out,
                                               l_err_msg
                                              );

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
               p_resp_code_out := '21';
               l_err_msg :=
                     'Error while getting Transaction details  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

-- EN Get Transaction details

         -- SN Validate date and RRN
         IF l_dup_rrn_check = 'Y' AND l_audit_flag = 'T' THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_business_date_in,
                                         p_business_time_in,
                                         p_del_channel_in,
                                         l_err_msg,
                                         p_resp_code_out
                                        );

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
               p_resp_code_out := '21';
               l_err_msg :=
                     'Error while validating date and RRN  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         END IF;
-- EN Validate date and RRN

--SN Perform common validations
         BEGIN
            vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
                                                  p_msg_type_in,
                                                  p_rrn_in,
                                                  p_del_channel_in,
                                                  p_txn_code_in,
                                                  '0',
                                                  p_business_date_in,
                                                  p_business_time_in,
                                                  '00',
                                                  l_txn_type,
                                                  p_pan_code_in,
                                                  l_hash_pan,
                                                  l_encr_pan,
                                                  p_spend_acct_no_out,
                                                  l_card_stat,
                                                  l_expry_date,
                                                  l_prod_code,
                                                  l_card_type,
                                                  l_prfl_flag,
                                                  l_prfl_code,
                                                  l_txn_type,
                                                  p_curr_code_in,
                                                  l_preauth_flag,
                                                  l_tran_desc,
                                                  l_cr_dr_flag,
                                                  l_login_txn,
                                                  p_resp_code_out,
                                                  l_err_msg,
                                                  l_comb_hash,
                                                  l_auth_id,
                                                  l_fee_code,
                                                  l_fee_plan,
                                                  l_feeattach_type,
                                                  l_tranfee_amt,
                                                  l_total_amt,
                                                  l_preauth_type
                                                 );

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
               p_resp_code_out := '21';
               l_err_msg :=
                     'Error from authorize_nonfinancial_txn '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

--EN Perform common validations

-- SN Retrieve Fee plan ID
         BEGIN
            SELECT cce_fee_plan
              INTO p_fee_plan_id_out
              FROM cms_card_excpfee
             WHERE cce_pan_code = gethash (p_pan_code_in)
               AND (( CCE_VALID_TO IS NOT NULL AND (TRUNC(SYSDATE) between cce_valid_from and CCE_VALID_TO))
                  OR (CCE_VALID_TO IS NULL AND TRUNC(SYSDATE) >= cce_valid_from));
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                 BEGIN
                     SELECT cpf_fee_plan
                       INTO p_fee_plan_id_out
                       FROM cms_prodcattype_fees
                      WHERE cpf_prod_code = l_prod_code
                        AND cpf_card_type = l_card_type
                        AND cpf_inst_code = p_inst_code_in
                        AND ((cpf_valid_to IS NOT NULL AND (TRUNC(SYSDATE) between cpf_valid_from and cpf_valid_to))
                          OR (cpf_valid_to IS NULL AND TRUNC(SYSDATE) >= cpf_valid_from));
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                         BEGIN
                           SELECT cpf_fee_plan
                             INTO p_fee_plan_id_out
                             FROM cms_prod_fees
                            WHERE cpf_prod_code = l_prod_code
                              AND cpf_inst_code = p_inst_code_in
                              AND ((cpf_valid_to IS NOT NULL AND (TRUNC(SYSDATE) between cpf_valid_from and cpf_valid_to))
                                OR (cpf_valid_to IS NULL AND TRUNC(SYSDATE) >= cpf_valid_from));
                            EXCEPTION
                               WHEN NO_DATA_FOUND
                               THEN
                                   p_fee_plan_id_out := NULL;
                               WHEN OTHERS
                               THEN
                                   p_resp_code_out := '21';
                                   l_err_msg :=
                                          'Problem while selecting Fee plan from CMS_PROD_FEES'
                                            || SUBSTR (SQLERRM, 1, 200);
                                   RAISE exp_reject_record;
                         END;
                        WHEN OTHERS
                        THEN
                            p_resp_code_out := '21';
                            l_err_msg :=
                                'Problem while selecting Fee plan from CMS_PRODCATTYPE_FEES'
                                || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                 END;
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_err_msg :=
                        'Problem while selecting Fee plan from CMS_CARD_EXCPFEE'
                        || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;

         END;

-- EN Retrieve Fee plan ID

  -- SN Get Tran date
        BEGIN
          l_tran_date := TO_DATE(p_business_date_in || 235959, 'yyyymmdd hh24miss');
          EXCEPTION
             WHEN OTHERS
             THEN
                p_resp_code_out := '21';
                l_err_msg  := 'Problem while converting transaction date ' ||
                      SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
  -- EN Get Tran date

-- SN Calculate Fees Accrued for current month

        BEGIN
		--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := SUBSTR(TRIM(l_tran_date), 1, 9);


IF (v_Retdate>v_Retperiod)
    THEN

            SELECT TO_CHAR (NVL (SUM (DECODE (csl_trans_type,
                            'DR', csl_trans_amount,
                            'CR', -csl_trans_amount)),
                            0), '99999999999999990.99')
              INTO p_spend_fee_accrued_out
              FROM VMSCMS.CMS_STATEMENTS_LOG          --Added for VMS-5735/FSP-991
             WHERE csl_pan_no = l_hash_pan
               AND TXN_FEE_FLAG ='Y'
               AND csl_ins_date between trunc(l_tran_date,'MM') and l_tran_date;
	ELSE
			            SELECT TO_CHAR (NVL (SUM (DECODE (csl_trans_type,
                            'DR', csl_trans_amount,
                            'CR', -csl_trans_amount)),
                            0), '99999999999999990.99')
              INTO p_spend_fee_accrued_out
              FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST          --Added for VMS-5735/FSP-991
             WHERE csl_pan_no = l_hash_pan
               AND TXN_FEE_FLAG ='Y'
               AND csl_ins_date between trunc(l_tran_date,'MM') and l_tran_date;
END IF;	
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
               p_spend_fee_accrued_out:='0.00';
              WHEN OTHERS THEN
                  p_resp_code_out := '12';
                  l_err_msg :=
                          'Error while calculating Fees Accrued : ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
         END;
-- EN Calculate Fees Accrued for current month

-- SN Retreieve FIID
         BEGIN
            SELECT cci_fiid
              INTO p_spend_inst_id_out
              FROM cms_caf_info_entry
             WHERE cci_appl_code = l_appl_code
               AND cci_inst_code = p_inst_code_in;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                    p_spend_inst_id_out:=NULL;
               WHEN OTHERS THEN
                    p_resp_code_out := '12';
                    l_err_msg := 'Error while selecting FIID ' ||
                              SUBSTR(SQLERRM, 1, 200);
                    RAISE exp_reject_record;
         END;


-- SN Retreieve FIID

  -- SN Get CCVPlus Details
        IF  p_cvvplus_eligibile_out = 'true' AND p_cvvplus_registered_out = 'true' THEN
          BEGIN
            SELECT vci_cvvplus_token,
                   vci_cvvplus_accountid,
                   vci_cvvplus_registration_id
              INTO p_cvvplus_token_out,
                   p_cvvplus_account_id_out,
                   p_cvvplus_regid_out
              FROM vms_cvvplus_info
             WHERE vci_cvvplus_acct_no = p_spend_acct_no_out;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  p_resp_code_out := '21';
                  l_err_msg := 'No data for given Account number '|| p_spend_acct_no_out;
                  RAISE exp_reject_record;
               WHEN OTHERS THEN
                  p_resp_code_out := '12';
                  l_err_msg :=
                          'Error while selecting cvvplus_info : ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
          END;
        END IF;
  -- EN Get CCVPlus Details

-- SN Check if savings account is eligible

         BEGIN
             SELECT COUNT(1)
               INTO l_savings_count
               FROM cms_dfg_param
              WHERE cdp_inst_code = p_inst_code_in
                AND cdp_prod_code = l_prod_code
                AND cdp_card_type = l_card_type;

            IF l_savings_count = 0 THEN
               p_is_sav_acc_elig_out := 'false';
            ELSE
               BEGIN
                  p_is_sav_acc_elig_out := 'true';
                -- SN Retrieve Max No of transactions
                 BEGIN
                  SELECT cdp_param_value
                    INTO l_max_no_trans
                    FROM cms_dfg_param
                   WHERE cdp_inst_code = p_inst_code_in
                     AND cdp_prod_code = l_prod_code
                     AND cdp_card_type = l_card_type
                    AND cdp_param_key = 'MaxNoTrans';
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        p_resp_code_out := '21';
                        l_err_msg := 'No data for selecting MaxNoTrans  '|| l_prod_code || l_card_type ;
                        RAISE exp_reject_record;
                     WHEN OTHERS THEN
                        p_resp_code_out := '12';
                        l_err_msg := 'Error while selecting MaxNoTrans ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                 END;
               -- EN Retrieve Max No of transactions

               -- SN Retrieve Savings Account Reopen Period

                 BEGIN
                  SELECT cdp_param_value
                    INTO l_saving_reopen
                    FROM cms_dfg_param
                   WHERE cdp_inst_code = p_inst_code_in
                     AND cdp_prod_code = l_prod_code
                     AND cdp_card_type = l_card_type
                     AND cdp_param_key = 'Saving account reopen period';
                  EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        p_resp_code_out := '21';
                        l_err_msg := 'No data for selecting Saving account reopen period  '|| l_prod_code || l_card_type ;
                        RAISE exp_reject_record;
                    WHEN OTHERS THEN
                        p_resp_code_out := '12';
                        l_err_msg := 'Error while selecting Saving account reopen period ' ||
                                     SUBSTR(SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                 END;
               -- EN Retrieve Savings Account Reopen Period

               END;
            END IF;
            EXCEPTION
               WHEN OTHERS THEN
                  p_resp_code_out := '12';
                  l_err_msg := 'Error while Checking if savings account is Eligible ' ||
                               SUBSTR(SQLERRM, 1, 200);
                  RAISE exp_reject_record;
         END;
-- EN Check if savings account is eligible

-- SN Get Saving Account details
   IF p_is_sav_acc_elig_out = 'true' THEN
         BEGIN
            SELECT cam_acct_no, NVL(cam_savtospd_tfer_count,0),
                   TRIM(TO_CHAR (cam_ledger_bal, '99999999999999990.99')),
                   TRIM(TO_CHAR (cam_interest_amount, '99999999999999990.99')), cam_stat_code,
                   to_char(cam_creation_date, 'YYYY-MM-DD'), cam_lupd_date,
                   case when sysdate > CAM_SAVTOSPD_TFER_DATE then 0  else NVL(CAM_SAVTOSPD_TFER_COUNT,0) end
              INTO p_sav_acct_no_out, l_savtospd_tfer_count,
                   p_sav_ledger_bal_out,p_daily_int_accrd_out, l_stat_code,
                   p_sav_acc_create_out, l_sav_lupd_date,
                   p_availed_transfer_out
              FROM cms_acct_mast
             WHERE cam_acct_id IN ( SELECT cca_acct_id FROM cms_cust_acct
                          WHERE cca_cust_code = l_cust_code AND cca_inst_code = p_inst_code_in)
               AND cam_type_code = '2'
               AND cam_inst_code = p_inst_code_in;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  p_sav_acct_no_out := NULL;
                  p_sav_acct_status_out := 'NOT_OPEN';
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_err_msg :=
                        'Problem while selecting Saving CMS_ACCT_MAST'
                        || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;

         END;
   END IF;

    IF p_sav_acct_no_out IS NOT NULL THEN

      IF l_stat_code <> 2 THEN
          p_sav_acct_status_out := 'OPEN';
       ELSIF l_stat_code = 2 THEN
           p_sav_acc_reopen_out := TO_CHAR(l_sav_lupd_date + l_saving_reopen,'YYYY-MM-DD');
           IF TO_CHAR(SYSDATE,'YYYY-MM-DD') > p_sav_acc_reopen_out THEN
              p_sav_acct_status_out := 'CLOSED_CANNOT_REOPEN';
           ELSE
              p_sav_acct_status_out := 'CLOSED_CAN_REOPEN';
           END IF;
       END IF;

       p_remain_transfer_out := l_max_no_trans - l_savtospd_tfer_count;


  -- SN Get Quarterly Interest accrued
        BEGIN
            SELECT nvl(sum(cid_interest_amount),'0')
              INTO p_qtd_interest_out
              FROM cms_interest_detl
             WHERE cid_inst_code = p_inst_code_in
               AND cid_acct_no   = p_sav_acct_no_out;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  p_qtd_interest_out := '0.00';
               WHEN OTHERS THEN
                  p_resp_code_out := '12';
                  l_err_msg := 'Error while retrieving Quarterly Interest accrued ' ||
                               SUBSTR(SQLERRM, 1, 200);
                  RAISE exp_reject_record;

        END;
  -- EN Get Quarterly Interest accrued

  -- SN Get Yearly Interest accrued
        BEGIN
            SELECT nvl(sum(cid_interest_amount),'0')
              INTO l_ytd_interest_hist
              FROM cms_interest_detl_hist
             WHERE cid_inst_code = p_inst_code_in
               AND cid_acct_no = p_sav_acct_no_out
               AND cid_ins_date between trunc(l_tran_date,'year') and l_tran_date;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_ytd_interest_hist := '0.00';
               WHEN OTHERS THEN
                  p_resp_code_out := '12';
                  l_err_msg := 'Error while retrieving Yearly Interest accrued ' ||
                               SUBSTR(SQLERRM, 1, 200);
                  RAISE exp_reject_record;
        END;

        p_ytd_interest_out := to_number(l_ytd_interest_hist) + to_number(p_qtd_interest_out);
        p_ytd_interest_out:=TO_CHAR (p_ytd_interest_out,'99999999999999990.99');
        p_qtd_interest_out:=TO_CHAR (p_qtd_interest_out,'99999999999999990.99');
  -- EN Get Yearly Interest accrued



  -- SN Calculate last transaction date for savings account
IF l_audit_flag = 'T' THEN
        BEGIN

            SELECT to_char(max(add_ins_date), 'YYYY-MM-DD')
              INTO p_last_txn_date_out
              FROM VMSCMS.TRANSACTIONLOG_VW                   --Added for VMS-5735/FSP-991
             WHERE customer_card_no = l_hash_pan
               AND customer_acct_no = p_sav_acct_no_out;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  p_resp_code_out := '21';
                  l_err_msg := 'No transaction done on savings account ';
                  RAISE exp_reject_record;
               WHEN OTHERS THEN
                  p_resp_code_out := '12';
                  l_err_msg :=
                          'Error while retrieving last used date: ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;

        END;

END IF;

  -- EN Calculate last transaction date for savings account


    ELSE
        p_remain_transfer_out := 0;
        p_availed_transfer_out := 0;
        p_sav_ledger_bal_out := '0.00';
        p_last_txn_date_out := NULL;
        p_daily_int_accrd_out := '0.00';
        p_qtd_interest_out := '0.00';
        p_ytd_interest_out :='0.00';
        p_sav_acc_create_out := NULL;
        p_sav_acc_reopen_out := NULL;
    END IF;

         p_resp_code_out := '1';


     EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
               p_resp_msg_out            := l_err_msg;

         WHEN OTHERS
         THEN
            p_resp_msg_out := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_del_channel_in
               AND cms_response_id = TO_NUMBER (p_resp_code_out);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                     'Problem while selecting data from response master for respose code'
                  || p_resp_code_out
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
      END;

     BEGIN
         l_hashkey_id :=
            gethash (   p_del_channel_in
                     || p_txn_code_in
                     || p_pan_code_in
                     || p_rrn_in
                     || TO_CHAR (NVL (l_timestamp, SYSTIMESTAMP),
                                 'YYYYMMDDHH24MISSFF5'
                                )
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            p_resp_msg_out :=
                  'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN

      SELECT  TRIM(TO_CHAR (cam_acct_bal, '99999999999999990.99')),
                   TRIM(TO_CHAR (cam_ledger_bal, '99999999999999990.99')),
                    CAM_TYPE_CODE,DECODE(NVL(cam_initialload_amt,0),0,'Not Available',TRIM(TO_CHAR(cam_initialload_amt,'99999999999999990.99')))
      INTO   p_spend_avail_bal_out, p_spend_ledger_bal_out,l_acct_type,p_initial_load_out
          FROM   CMS_ACCT_MAST
          WHERE  CAM_INST_CODE = p_inst_code_in
          AND    CAM_ACCT_NO = p_spend_acct_no_out;

 if l_repl_flag != 0 and  p_initial_load_out = 'Not Available' then
        select * into l_pan_code from ( select fn_dmaps_main(CAP_PAN_CODE_ENCR)
        from cms_appl_pan
        where cap_inst_code=1 and cap_repl_flag=0
        and CAP_ACCT_NO = p_spend_acct_no_out
        order by CAP_INS_DATE) where rownum=1;
    else
        l_pan_code := p_pan_code_in;
    end if;

      if
      l_b2b_flag='Y' and l_pan_inventory_flag ='Y' and p_initial_load_out = 'Not Available'
      then
          select DECODE(NVL(b.vol_DENOMINATION,0),0,'Not Available',TRIM(TO_CHAR(b.vol_DENOMINATION,'99999999999999990.99'))),
          b.vol_product_funding, b.vol_fund_amount
          into l_DENOMINATION, l_PRODUCT_FUNDING  ,  l_FUND_AMOUNT
          from vms_line_item_dtl a, vms_order_lineitem b
          where a.vli_pan_code = gethash( l_pan_code)
          and a.vli_partner_id=b.vol_partner_id
          and a.vli_order_id = b.vol_order_id
          and a.vli_lineitem_id = b.vol_line_item_id;
          if
              l_PRODUCT_FUNDING = '2' and l_FUND_AMOUNT  = '1'
              then
              p_initial_load_out := l_DENOMINATION;
          end if;
      END IF;
	  
      EXCEPTION
           WHEN NO_DATA_FOUND
                     THEN
                        p_resp_code_out := '21';
                        p_resp_msg_out := 'Invalid Card/Account  ' ;
          WHEN OTHERS
        THEN
           p_resp_code_out := '112';
           p_resp_msg_out :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

	 IF l_audit_flag = 'T'
	 THEN 
	 
-- SN Log into transaction log and cms_transaction_log_dtl
      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_del_channel_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     '0',                          -- txn_mode
                                     p_business_date_in,
                                     p_business_time_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     p_resp_msg_out,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_tran_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     p_spend_acct_no_out,
                                     l_prod_code,
                                     l_card_type,
                                     l_cr_dr_flag,
                                     p_spend_avail_bal_out,
                                     p_spend_ledger_bal_out,
                                     l_acct_type,
                                     l_proxy_number,
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
                                     p_partner_id_in,
                                     l_err_msg
                                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_msg_out :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
	  
	  ELSIF l_audit_flag = 'A'
      THEN 
	  
	  BEGIN
         
		 VMSCMS.VMS_LOG.LOG_TRANSACTIONLOG_AUDIT(p_msg_type_in,
												 p_rrn_in,
												 p_del_channel_in,
												 p_txn_code_in,                                     
												 '0',   
												 p_business_date_in,    
												 p_business_time_in,   
												 '00',  
												 p_pan_code_in,
												 p_resp_msg_out,
												 0,
												 l_total_amt,
												 p_resp_code_out,
												 p_curr_code_in,
												 p_partner_id_in,
												 NULL,   
												 l_err_msg,
                                                 NULL,
                                                 p_ip_addr_in,
                                                 NULL,
                                                 CASE WHEN p_resp_code_out = '00' THEN  'C' ELSE 'F' END,
                                                 P_ANI_IN,
                                                 P_DNI_IN,
                                                 null,
                                                 null,
                                                 null,
                                                 null,
                                                 null,
                                                 null,
                                                 null,
                                                 l_fee_code,
                                                 l_tranfee_amt,
                                                 l_fee_plan,
                                                 l_feeattach_type
                                                 );
		
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_msg_out :=
                  'Erorr while inserting to audit transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END; 
	  
	  END IF;

      IF p_resp_code_out <> '00' THEN
         p_sav_acct_status_out     := NULL;
         p_is_sav_acc_elig_out     := NULL;
         p_prod_desc_out           := NULL;
         p_prod_catg_desc_out      := NULL;
         p_fee_plan_id_out         := NULL;
         p_spend_acct_no_out       := NULL;
         p_spend_rout_no_out       := NULL;
         p_spend_transit_no_out    := NULL;
         p_spend_inst_id_out       := NULL;
         p_spend_ledger_bal_out    := NULL;
         p_spend_avail_bal_out     := NULL;
         p_spend_fee_accrued_out   := NULL;
         p_sav_acct_no_out         := NULL;
         p_remain_transfer_out     := NULL;
         p_availed_transfer_out    := NULL;
         p_sav_ledger_bal_out      := NULL;
         p_last_txn_date_out       := NULL;
         p_daily_int_accrd_out     := NULL;
         p_qtd_interest_out        := NULL;
         p_ytd_interest_out        := NULL;
         p_sav_acc_create_out      := NULL;
         p_sav_acc_reopen_out      := NULL;
         p_last_four_pan_out       := NULL;
         p_card_status_out         := NULL;
         p_active_date_out         := NULL;
         p_expiry_date_out         := NULL;
         p_shipped_date_out        := NULL;
         p_last_used_date_out      := NULL;
         p_initial_load_out        := NULL;
         p_name_on_card_out        := NULL;
         p_is_starter_out          := NULL;
         p_serial_number_out       := NULL;
         p_cvvplus_token_out       := NULL;
         p_cvvplus_eligibile_out   := NULL;
         p_cvvplus_registered_out  := NULL;
         p_cvvplus_status_out      := NULL;
         p_cvvplus_account_id_out  := NULL;
         p_cvvplus_regid_out       := NULL;
      END IF;

-- EN Log into transaction log and cms_transaction_log_dtl
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '89';
         p_resp_msg_out := 'Main Excp- ' || SUBSTR (SQLERRM, 1, 300);
   END get_cust_acct_details;

PROCEDURE        get_registration_status (
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
                                       p_resp_code_out           OUT      VARCHAR2,
                                       p_resp_msg_out            OUT      VARCHAR2,
                                       p_status_out              OUT      VARCHAR2,
                                       p_cust_id_out              OUT      VARCHAR2
                                    )
AS
     
/*
     * Modified by       : Dhinakaran B
     * Modified Date     : 27-May-21
     * Modified For      : VMS-4426
     * Reviewer          : Saravanakumar A
     * Build Number      : R47 Build 2
*/

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
   l_timestamp         transactionlog.time_stamp%TYPE;
   l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
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
   l_errmsg            transactionlog.error_msg%TYPE;
   l_appl_code         cms_appl_pan.cap_appl_code%TYPE;
   l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   l_kyc_flag          cms_caf_info_entry.cci_kyc_flag%TYPE;
   l_user_name         cms_cust_mast.ccm_user_name%TYPE;
   l_encrypt_enable    cms_prod_cattype.cpc_encrypt_enable%type;
   l_user_identity CMS_PROD_CATTYPE.CPC_USER_IDENTIFY_TYPE%type;
   exp_reject_record   EXCEPTION;
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
                  'Error from Transaction Details'
               || SUBSTR (SQLERRM, 1, 200);
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

      begin
           select cpc_encrypt_enable, CPC_USER_IDENTIFY_TYPE
           into l_encrypt_enable, l_user_identity
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
      end;


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
                  'ERROR FROM authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cci_kyc_flag
           INTO l_kyc_flag
           FROM cms_caf_info_entry
          WHERE cci_inst_code = p_inst_code_in
            AND cci_appl_code = TO_CHAR (l_appl_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
               'Error while selecting the kyc flag'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT NVL (decode(l_encrypt_enable,'Y',fn_dmaps_main(ccm_user_name),ccm_user_name), 0),ccm_cust_id
            INTO l_user_name,p_cust_id_out
           FROM cms_cust_mast
          WHERE ccm_inst_code = p_inst_code_in AND ccm_cust_code = l_cust_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting username '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

   -- VMS-3545 Changes +++++++++++++++
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
   -- VMS-3545 Changes +++++++++++++++

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
            l_errmsg := 'Invalid Card number ' ;
       WHEN OTHERS
      THEN
         l_errmsg := '12';
         p_resp_msg_out :=
                       'ERROR IN account details' || SUBSTR (SQLERRM, 1, 200);
   END;

   IF p_resp_code_out <> '00'
   THEN
      p_status_out := NULL;
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
END get_registration_status;

PROCEDURE        get_security_questions (
                                     p_inst_code_in             IN       NUMBER,
                                     p_delivery_chnl_in         IN       VARCHAR2,
                                     p_txn_code_in              IN       VARCHAR2,
                                     p_rrn_in                   IN       VARCHAR2,
                                     p_appl_id_in               IN       VARCHAR2,
                                     p_partner_id_in            IN       VARCHAR2,
                                     p_tran_date_in             IN       VARCHAR2,
                                     p_tran_time_in             IN       VARCHAR2,
                                     p_curr_code_in             IN       VARCHAR2,
                                     p_revrsl_code_in           IN       VARCHAR2,
                                     p_msg_type_in              IN       VARCHAR2,
                                     p_ip_addr_in               IN       VARCHAR2,
                                     p_ani_in                   IN       VARCHAR2,
                                     p_dni_in                   IN       VARCHAR2,
                                     p_device_mobno_in          IN       VARCHAR2,
                                     p_device_id_in             IN       VARCHAR2,
                                     p_uuid_in                  IN       VARCHAR2,
                                     p_osname_in                IN       VARCHAR2,
                                     p_osversion_in             IN       VARCHAR2,
                                     p_gps_coordinates_in       IN       VARCHAR2,
                                     p_display_resolution_in    IN       VARCHAR2,
                                     p_physical_memory_in       IN       VARCHAR2,
                                     p_appname_in               IN       VARCHAR2,
                                     p_appversion_in            IN       VARCHAR2,
                                     p_sessionid_in             IN       VARCHAR2,
                                     p_device_country_in        IN       VARCHAR2,
                                     p_device_region_in         IN       VARCHAR2,
                                     p_ipcountry_in             IN       VARCHAR2,
                                     p_proxy_flag_in            IN       VARCHAR2,
                                     p_pan_code_in              IN       VARCHAR2,
                                     p_user_name_in             IN       VARCHAR2,
                                     p_resp_code_out            OUT      VARCHAR2,
                                     p_resp_msg_out             OUT      VARCHAR2,
                                     p_security_questions_out   OUT      sys_refcursor
                                  )
AS

/********************************************************************************************
     * Modified By      : VINI PUSHKARAN
     * Modified Date    : 01-MAR-2019
     * Purpose          : VMS-809(Decline Request for Web-account Username if Username is Already Taken)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R13_B0002       
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
   l_comb_hash         pkg_limits_check.type_hash;
   l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
   l_timestamp         transactionlog.time_stamp%TYPE;
   l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
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
   l_errmsg            transactionlog.error_msg%TYPE;
   l_appl_code         cms_appl_pan.cap_appl_code%TYPE;
   l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   l_cust_id           cms_cust_mast.ccm_cust_id%TYPE;
   exp_reject_record   EXCEPTION;
  -- l_encrypt_enable   cms_prod_cattype.cpc_encrypt_enable%type;
  -- l_user_name        cms_cust_mast.ccm_user_name%type;
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
                  'Error from Transaction Details'
               || SUBSTR (SQLERRM, 1, 200);
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


--      begin
--          select cpc_encrypt_enable
--          into l_encrypt_enable
--          from cms_prod_cattype
--          where cpc_inst_code=p_inst_code_in
--          and cpc_prod_code=l_prod_code
--          and cpc_card_type=l_prod_cattype;
--      exception
--          when others then
--               p_resp_code_out := '21';
--            l_errmsg :=
--                  'Error while selecting prod cattype'
--               || SUBSTR (SQLERRM, 1, 200);
--            RAISE exp_reject_record;
--      end;
      
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
            l_errmsg :=
               'Error from authorize_nonfinancial_txn ' || l_errmsg;
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

--      if l_encrypt_enable='Y' then
--          l_user_name:=fn_emaps_main(UPPER (TRIM (p_user_name_in)));
--      else
--          l_user_name:=UPPER (TRIM (p_user_name_in));
--      end if;

      BEGIN
         SELECT ccm_cust_id
           INTO l_cust_id
           FROM cms_cust_mast
          WHERE ccm_inst_code = p_inst_code_in
          AND ccm_cust_code = l_cust_code;  -- Modified for Decline Request for Web-account Username if Username is Already Taken(VMS-809)
          
--          UPPER (ccm_user_name) = l_user_name
--            AND ccm_inst_code = p_inst_code_in
--            AND ccm_appl_id = p_appl_id_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid User Name ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while getting cust id from cust_mast '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN

         OPEN p_security_questions_out FOR SELECT csq_question
              FROM cms_security_questions
             WHERE csq_cust_id = l_cust_id
               AND csq_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'ERROR WHILE fetching SECURITY questions '
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
         WHEN OTHERS
         THEN
            l_errmsg :=
                  'Error WHILE selecting respose code'
               || p_resp_code_out
               || ' IS-'
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
         l_errmsg :=
            'ERROR while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
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
         l_errmsg := 'Error while getting account details' || SUBSTR (SQLERRM, 1, 200)||l_errmsg;
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
END get_security_questions;

PROCEDURE get_savings_account_settings (
                                   p_inst_code_in                   IN       NUMBER,
                                   p_delivery_chnl_in               IN       VARCHAR2,
                                   p_txn_code_in                    IN       VARCHAR2,
                                   p_rrn_in                         IN       VARCHAR2,
                                   p_cust_id_in                     IN       NUMBER,
                                   p_appl_id_in                     IN       VARCHAR2,
                                   p_partner_id_in                  IN       VARCHAR2,
                                   p_tran_date_in                   IN       VARCHAR2,
                                   p_tran_time_in                   IN       VARCHAR2,
                                   p_curr_code_in                   IN       VARCHAR2,
                                   p_revrsl_code_in                 IN       VARCHAR2,
                                   p_msg_type_in                    IN       VARCHAR2,
                                   p_ip_addr_in                     IN       VARCHAR2,
                                   p_ani_in                         IN       VARCHAR2,
                                   p_dni_in                         IN       VARCHAR2,
                                   p_device_mobno_in                IN       VARCHAR2,
                                   p_device_id_in                   IN       VARCHAR2,
                                   p_uuid_in                        IN       VARCHAR2,
                                   p_osname_in                      IN       VARCHAR2,
                                   p_osversion_in                   IN       VARCHAR2,
                                   p_gps_coordinates_in             IN       VARCHAR2,
                                   p_display_resolution_in          IN       VARCHAR2,
                                   p_physical_memory_in             IN       VARCHAR2,
                                   p_appname_in                     IN       VARCHAR2,
                                   p_appversion_in                  IN       VARCHAR2,
                                   p_sessionid_in                   IN       VARCHAR2,
                                   p_device_country_in              IN       VARCHAR2,
                                   p_device_region_in               IN       VARCHAR2,
                                   p_ipcountry_in                   IN       VARCHAR2,
                                   p_proxy_flag_in                  IN       VARCHAR2,
                                   p_pan_code_in                    IN       VARCHAR2,
                                   p_min_spnd_to_sng_tnfr_amt_out   OUT      NUMBER,
                                   p_max_spnd_to_sng_tnfr_amt_out   OUT      NUMBER,
                                   p_min_svng_to_snd_tnfr_amt_out   OUT      NUMBER,
                                   p_max_trnfs_out                  OUT      NUMBER,
                                   p_min_svng_acct_bal_out          OUT      NUMBER,
                                   p_savings_interest_rate_out      OUT      NUMBER,
                                   P_LoadTimeTransfer_out           OUT      VARCHAR2,
                                   P_LoadTimeTransfer_Amt_out       OUT      VARCHAR2,
                                   P_FirstMonthTransfer_out         OUT      VARCHAR2,
                                   P_FirstMonthTransfer_Amt_out     OUT      VARCHAR2,
                                   P_FifteenMonthTransfer_out       OUT      VARCHAR2,
                                   P_FifteenMonthTransfer_Amt_out   OUT      VARCHAR2,
                                   p_weeklytransfer_flag_out        OUT      VARCHAR2,
                                   p_weeklytransfer_amount_out      OUT      VARCHAR2,
                                   p_biweeklytransfer_flag_out      OUT      VARCHAR2,
                                   p_biweeklytransfer_amt_out       OUT      VARCHAR2,
                                   p_dayofmonthtrns_flag_out        OUT      VARCHAR2,
                                   p_dayofmonth_out                 OUT      VARCHAR2,
                                   p_dayofmonthtrns_amt_out         OUT      VARCHAR2,
                                   p_minreload_amnt_out             OUT      varchar2,
                                   p_resp_code_out                  OUT      VARCHAR2,
                                   p_resp_msg_out                   OUT      VARCHAR2
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
   l_timestamp         transactionlog.time_stamp%TYPE;
   l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
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
   l_errmsg            transactionlog.error_msg%TYPE;
   l_appl_code         cms_appl_pan.cap_appl_code%TYPE;
   l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   l_saving_acctno     cms_acct_mast.cam_acct_no%TYPE;
   exp_reject_record   EXCEPTION;
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
                  'ERROR FROM authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         FOR i IN
            (SELECT cdp_param_value, cdp_param_key
               FROM cms_dfg_param
                where  cdp_inst_code = p_inst_code_in
                 and cdp_param_key IN
                       ('MaxNoTrans', 'MaxSpendingParam', 'MinSavingParam',
                        'MinSpendingParam', 'Saving account Interest rate',
                        'InitialTransferAmount')
                AND cdp_prod_code = l_prod_code
                AND cdp_card_type = l_prod_cattype)
         LOOP
            IF i.cdp_param_key = 'MaxNoTrans'
            THEN
               p_max_trnfs_out := TO_NUMBER (i.cdp_param_value);
            ELSIF i.cdp_param_key = 'MaxSpendingParam'
            THEN
               p_max_spnd_to_sng_tnfr_amt_out :=
                                                TO_NUMBER (i.cdp_param_value);
            ELSIF i.cdp_param_key = 'MinSavingParam'
            THEN
               p_min_svng_to_snd_tnfr_amt_out :=
                                                TO_NUMBER (i.cdp_param_value);
            ELSIF i.cdp_param_key = 'MinSpendingParam'
            THEN
               p_min_spnd_to_sng_tnfr_amt_out :=
                                                TO_NUMBER (i.cdp_param_value);
            ELSIF i.cdp_param_key = 'Saving account Interest rate'
            THEN
               p_savings_interest_rate_out := TO_NUMBER (i.cdp_param_value);
            ELSIF i.cdp_param_key = 'InitialTransferAmount'
            THEN
               p_min_svng_acct_bal_out := TO_NUMBER (i.cdp_param_value);
            END IF;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'ERROR while getting savings account details '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

       BEGIN
           SELECT cam_acct_no INTO l_SAVING_ACCTNO  FROM CMS_ACCT_MAST
           WHERE cam_acct_id IN( SELECT cca_acct_id FROM CMS_CUST_ACCT
           WHERE cca_cust_code=l_cust_code AND cca_inst_code=P_INST_CODE_in) AND cam_type_code=2
           AND CAM_INST_CODE=p_inst_code_in;

         EXCEPTION
         WHEN NO_DATA_FOUND  THEN
            p_resp_code_out := '105';
            l_errmsg :='Savings account not created for this card';
            RAISE exp_reject_record;
          WHEN OTHERS  THEN
            p_resp_code_out := '12';
            l_errmsg :='Problem while selecting account details' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
         END;

      BEGIN
               SELECT cam_loadtime_transfer , cam_loadtime_transferamt, nvl(cam_firstmonth_transfer,0), cam_firstmonth_transferamt,
              cam_fifteenmonth_transfer, cam_fifteenmonth_transferamt,nvl(CAM_WEEKLYTRANSFER_FLAG,0),nvl(CAM_WEEKLYTRANSFER_AMOUNT,0),nvl(CAM_BIWEEKLYTRANSFER_FLAG,0),nvl(CAM_BIWEEKLYTRANSFER_AMOUNT,0)
              ,nvl(CAM_ANYDAYMONTHTRANSFER_FLAG,0),nvl(CAM_DAYOFTRANSFER_MONTH,0),nvl(CAM_MONTLYTRANSFER_AMOUNT,0),nvl(CAM_MINRELOAD_AMOUNT,0)
              INTO
              p_loadtimetransfer_out ,p_loadtimetransfer_amt_out,p_firstmonthtransfer_out,p_firstmonthtransfer_amt_out,
              p_fifteenmonthtransfer_out,p_fifteenmonthtransfer_amt_out,p_weeklytransfer_flag_out,p_weeklytransfer_amount_out,
              p_biweeklytransfer_flag_out,p_biweeklytransfer_amt_out,p_dayofmonthtrns_flag_out,
               p_dayofmonth_out,p_dayofmonthtrns_amt_out,p_minreload_amnt_out
       FROM cms_acct_mast
       WHERE cam_inst_code=P_INST_CODE_in AND cam_acct_no=l_SAVING_ACCTNO;

      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'ERROR while getting savings account settings '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

       IF p_loadtimetransfer_out IS NULL AND p_firstmonthtransfer_out IS NULL AND p_fifteenmonthtransfer_out IS NULL THEN

       P_RESP_CODE_out := '137';
       l_ERRMSG := 'Savings Account Automatic Settings not found';
       RAISE EXP_REJECT_RECORD;

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
      p_min_spnd_to_sng_tnfr_amt_out := NULL;
      p_max_spnd_to_sng_tnfr_amt_out := NULL;
      p_min_svng_to_snd_tnfr_amt_out := NULL;
      p_max_trnfs_out := NULL;
      p_min_svng_acct_bal_out := NULL;
      p_savings_interest_rate_out := NULL;
      P_LoadTimeTransfer_out  := NULL;
      P_LoadTimeTransfer_Amt_out    := NULL;
      P_FirstMonthTransfer_out      := NULL;
      P_FirstMonthTransfer_Amt_out  := NULL;
      P_FifteenMonthTransfer_out    := NULL;
      P_FifteenMonthTransfer_Amt_out  := NULL;
      p_weeklytransfer_flag_out     := NULL;
      p_weeklytransfer_amount_out   := NULL;
      p_biweeklytransfer_flag_out   := NULL;
      p_biweeklytransfer_amt_out    := NULL;
      p_dayofmonthtrns_flag_out    := NULL;
      p_dayofmonth_out             := NULL;
      p_dayofmonthtrns_amt_out     := NULL;
      p_minreload_amnt_out         := NULL;
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
END get_savings_account_settings;

PROCEDURE get_customer_product_details(p_inst_code_in             IN  NUMBER,
                                   p_delivery_channel_in      IN  VARCHAR2,
                                   p_txn_code_in              IN  VARCHAR2,
                                   p_rrn_in                   IN  VARCHAR2,
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
                                   p_cust_id_in               IN  VARCHAR2,
                                   p_resp_code_out            OUT VARCHAR2,
                                   p_respmsg_out              OUT VARCHAR2,
                                   p_prod_code_out            OUT VARCHAR2,
                                   p_prod_desc_out            OUT VARCHAR2,
                                   p_prodcat_id_out           OUT VARCHAR2,
                                   p_prodcat_name_out         OUT VARCHAR2,
                                   p_prodcat_desc_out         OUT VARCHAR2,
                                   p_package_id_out           OUT VARCHAR2,
                                   p_srcapp_out               OUT VARCHAR2,
                                   p_fee_plan_out             OUT sys_refcursor,
                                   p_fee_details_out          OUT sys_refcursor
                                   )
AS
      l_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no           cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code         cms_appl_pan.cap_prod_code%TYPE;
      l_prod_cattype      cms_prod_cattype.cpc_product_id%TYPE;
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
      l_timestamp         transactionlog.time_stamp%TYPE;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
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
      l_feedetails_query  VARCHAR2 (4000);
      l_errmsg            transactionlog.error_msg%TYPE;
	  --initializing variable for VMS-756
      l_feeplan_id        cms_fee_plan.cfp_plan_id%TYPE;
      l_feeplan_desc      cms_fee_plan.cfp_plan_desc%TYPE;
	  l_audit_flag		    cms_transaction_mast.ctm_txn_log_flag%TYPE;
      l_feeplan_is_active VARCHAR2 (50); 
      l_feeplan_start_date VARCHAR2 (50);
      l_feeplan_end_date VARCHAR2 (50);
      exp_reject_record   EXCEPTION;	  
      /****************************************************************
      
  * Modified By                  : Sivakumar M.
  * Modified Date                : 10-Jan-2019
  * Modified Reason              : VMS-728
  * Build Number                 : VMSGPRHOST_R11_B0001
  * Reviewer                     : Saravanakumar A.
  * Reviewed Date                : 10-Jan-2019
  
  * Modified By                  : DHINAKARAN B
  * Modified Date                : 21-Jan-2019
  * Modified Reason              : VMS-756
  * Build Number                 : VMSGPRHOST_R11_
  * Reviewer                     : Saravanakumar A.
  * Reviewed Date                : 
  
      *****************************************************************/
   BEGIN
      BEGIN
         p_respmsg_out := 'success';

--Sn pan  and customer product details
         BEGIN
          SELECT pan.cap_pan_code, pan.cap_pan_code_encr,pan.cap_acct_no,
                 pan.cap_card_stat, pan.cap_prod_code, cpc_product_id,cpc_card_type,
                 pan.cap_expry_date, pan.cap_active_date, pan.cap_prfl_code,
                 pan.cap_proxy_number,prod.cpm_prod_desc,
                 cattype.cpc_cardtype_desc,cattype.cpc_cardtype_sname,cattype.cpc_package_id,cattype.cpc_src_app
            INTO l_hash_pan, l_encr_pan, l_acct_no,
                 l_card_stat, l_prod_code,p_prodcat_id_out, l_prod_cattype,
                 l_expry_date, l_active_date, l_prfl_code,
                 l_proxynumber, p_prod_desc_out,
                 p_prodcat_desc_out, p_prodcat_name_out,p_package_id_out,p_srcapp_out
            FROM cms_appl_pan pan,cms_prod_mast prod,cms_prod_cattype cattype
           WHERE prod.cpm_inst_code = cattype.cpc_inst_code
             AND prod.cpm_prod_code = pan.cap_prod_code
             AND cattype.cpc_prod_code = prod.cpm_prod_code
             AND cattype.cpc_card_type = pan.cap_card_type
             AND pan.cap_inst_code = p_inst_code_in
             AND pan.cap_mbr_numb = '000'
             AND pan.cap_pan_code  = gethash(p_pan_code_in);

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
		 
	 BEGIN  
                    
               SELECT nvl(ctm_txn_log_flag,'T')
                 INTO l_audit_flag
                 FROM cms_transaction_mast
                WHERE ctm_inst_code = 1
                  AND ctm_tran_code = p_txn_code_in
                  AND ctm_delivery_channel = p_delivery_channel_in;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code_out := '12';
                  l_errmsg :=
                        'Error while selcting txn log type'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

--Sn pan  and customer product details

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
         IF l_dup_rrn_check = 'Y' AND l_audit_flag = 'T' THEN
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

             p_prod_code_out := l_prod_code;
--           p_prodcat_id_out := l_prod_cattype;
      

--query was modified for VMS-756	  
BEGIN
  SELECT feeplan.cfp_plan_id fee_plan ,
    feeplan.cfp_plan_desc fee_plan_desc,
    'true' is_active,
    TO_CHAR(cardfee.cce_valid_from,'YYYY-MM-DD') start_date,
    TO_CHAR(cardfee.cce_valid_to,'YYYY  -MM-DD') end_date
  INTO l_feeplan_id,
    l_feeplan_desc,
    l_feeplan_is_active,
    l_feeplan_start_date,
    l_feeplan_end_date
  FROM cms_card_excpfee cardfee,
    cms_fee_plan feeplan
  WHERE cardfee.cce_inst_code = p_inst_code_in
  AND cardfee.cce_pan_code    = gethash(p_pan_code_in)
  AND cardfee.cce_inst_code   = feeplan.cfp_inst_code
  AND cardfee.cce_fee_plan    =feeplan.cfp_plan_id
  AND feeplan.cfp_plan_id    IN
    (SELECT cfm_plan_id
    FROM cms_feeplan_prod_mapg
    WHERE cfm_prod_code = l_prod_code
    )
    AND ((cardfee.cce_valid_to IS NOT NULL
      AND TRUNC(SYSDATE) BETWEEN cardfee.cce_valid_from AND cardfee.cce_valid_to)
      OR (cardfee.cce_valid_to   IS NULL
      AND TRUNC(SYSDATE) >= cardfee.cce_valid_from));
EXCEPTION
WHEN NO_DATA_FOUND THEN
  BEGIN
    SELECT feeplan.cfp_plan_id fee_plan,
      feeplan.cfp_plan_desc fee_plan_desc,
      'true' is_active,
      TO_CHAR(catfee.cpf_valid_from,'YYYY-MM-DD') start_date,
      TO_CHAR(catfee.cpf_valid_to,'YYYY  -MM-DD') end_date
    INTO l_feeplan_id,
      l_feeplan_desc,
      l_feeplan_is_active,
      l_feeplan_start_date,
      l_feeplan_end_date
    FROM cms_prodcattype_fees catfee,
      cms_fee_plan feeplan
    WHERE catfee.cpf_inst_code = p_inst_code_in
    AND catfee.cpf_prod_code   = l_prod_code
    AND catfee.cpf_card_type   = l_prod_cattype
    AND catfee.cpf_inst_code   = feeplan.cfp_inst_code
    AND catfee.cpf_fee_plan    = feeplan.cfp_plan_id
    AND feeplan.cfp_plan_id    IN
      (SELECT cfm_plan_id
      FROM cms_feeplan_prod_mapg
      WHERE cfm_prod_code = l_prod_code
      )
      AND ((catfee.cpf_valid_to IS NOT NULL
        AND TRUNC(SYSDATE) BETWEEN catfee.cpf_valid_from AND catfee.cpf_valid_to)
        OR (catfee.cpf_valid_to   IS NULL
        AND TRUNC(SYSDATE) >= catfee.cpf_valid_from));
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    BEGIN
      SELECT feeplan.cfp_plan_id fee_plan,
        feeplan.cfp_plan_desc fee_plan_desc,
        'true' is_active,
        TO_CHAR(prodfee.cpf_valid_from,'YYYY-MM-DD') start_date,
        TO_CHAR(prodfee.cpf_valid_to,'YYYY  -MM-DD') end_date
      INTO l_feeplan_id,
        l_feeplan_desc,
        l_feeplan_is_active,
        l_feeplan_start_date,
        l_feeplan_end_date
      FROM cms_prod_fees prodfee,
        cms_fee_plan feeplan
      WHERE prodfee.cpf_inst_code = p_inst_code_in
      AND prodfee.cpf_prod_code   = l_prod_code
      AND prodfee.cpf_inst_code   = feeplan.cfp_inst_code
      AND prodfee.cpf_fee_plan    = feeplan.cfp_plan_id
      AND feeplan.cfp_plan_id    IN
        (SELECT cfm_plan_id
        FROM cms_feeplan_prod_mapg
        WHERE cfm_prod_code = l_prod_code
        )
       AND ((prodfee.cpf_valid_to IS NOT NULL
          AND TRUNC(SYSDATE) BETWEEN prodfee.cpf_valid_from AND prodfee.cpf_valid_to)
          OR (prodfee.cpf_valid_to   IS NULL
          AND TRUNC(SYSDATE) >= prodfee.cpf_valid_from)) ;
    EXCEPTION
    WHEN OTHERS THEN
       p_resp_code_out := '12';
            l_errmsg :=
                  'Error while getting fee plan  details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
    END;
  WHEN OTHERS THEN
     p_resp_code_out := '12';
            l_errmsg :=
                  'Error while getting prod cat fee plan  details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
  END ;
WHEN OTHERS THEN
  p_resp_code_out := '21';
               l_errmsg :=
                     'Error while executing card fee plan details query '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
END ;

   -- SN Open cursor to execute fee plan select query
         BEGIN
            OPEN p_fee_plan_out FOR SELECT l_feeplan_id fee_plan,
            l_feeplan_desc fee_plan_desc, l_feeplan_is_active is_active, 
            l_feeplan_start_date start_date, l_feeplan_end_date end_date FROM dual;
         
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while executing fee plan query '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

   -- EN Close cursor to fee plan select query

     -- SN Generate fee details select query
     -- Modified the below query to fetch Monthly fee details for vms-728.
         Begin
            l_feedetails_query := 'SELECT DISTINCT a.cff_fee_plan fee_id,
                                  Cfm_Fee_Code Fee_Code,
                                  nvl(cfl_other_param,cfm_fee_desc) fee_type,
                                  cfm_fee_desc fee_desc,
                                  trim(TO_CHAR(NVL(cfm_fee_amt, 0), ''99999999999999990.99'')) fee_amt,
                                  trim(TO_CHAR(NVL(cfm_per_fees, 0), ''99999999999999990.99'')) per_fees,
                                  trim(TO_CHAR(NVL(cfm_min_fees, 0), ''99999999999999990.99'')) min_fees,
				                  DECODE(UPPER(cfm_clawback_flag),''Y'',''true'',''false'') clawback_flag,
                                  -- VMS-2618 add fee start days
                                  NVL(cfm_assessed_days, 0) fee_start_days
                                FROM Cms_Fee_Mast,
                                  cms_fee_types,
                                  Cms_Feetxn_List,
                                  (SELECT cff_fee_code,
                                    cff_fee_plan,
                                    cff_inst_code
                                  FROM cms_fee_feeplan,
                                    cms_feeplan_prod_mapg
                                  WHERE cff_fee_plan = cfm_plan_id
                                  AND Cff_Inst_Code  = Cfm_Inst_Code
                                  AND cfm_prod_code  = :l_prod_code
                                  ) a
                                WHERE cfm_inst_code      =:p_inst_code_in
                                AND Cfm_Fee_Code         = A.Cff_Fee_Code
                                AND cfm_inst_code        =a.cff_inst_code
                                AND a.cff_inst_code      =cft_inst_code
                                --AND cft_inst_code        = cfl_inst_code
                                AND Cfm_Feetype_Code     = Cft_Feetype_Code
                                AND Cfl_Dlvr_Chnl(+)        =Cfm_Delivery_Channel
                                AND Cfl_tran_code(+)        =Cfm_tran_code
                                AND Cfl_Inst_Code (+)      =Cfm_Inst_Code
                                AND cfl_other_param_key(+) = NVL(Cfm_Delivery_Channel,''NA'')
                                    ||'',''
                                    ||NVL(Cfm_Tran_Code,''NA'')
                                    ||'',''
                                    ||NVL(Cfm_Intl_Indicator,''NA'')
                                    ||'',''
                                    ||NVL(Cfm_Pin_Sign,''NA'')
                                    ||'',''
                                    ||NVL(Cfm_Merc_Code,''NA'')
                                    ||'',''
                                    ||NVL(Cfm_Normal_Rvsl,''NA'')
                                    ||'',''
                                    ||NVL(CFM_APPROVE_STATUS,''NA'')
                                ORDER BY fee_id';

           END;

   -- EN Generate  fee details select query

   -- SN Open cursor to execute fee details select query
         BEGIN
            OPEN p_fee_details_out FOR l_feedetails_query
            USING l_prod_code, p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while executing fee details query '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

   -- EN Close cursor to fee details select query


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
       WHEN NO_DATA_FOUND
        THEN
           p_resp_code_out := '21';
         l_errmsg := 'Invalid Card number ';
      WHEN OTHERS
        THEN
           p_resp_code_out := '12';
           l_errmsg :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      IF p_resp_code_out <> '00' THEN
          p_respmsg_out  :=l_errmsg;
          p_prod_code_out  :=null;
          p_prod_desc_out   :=null;
          p_prodcat_id_out    :=null;
          p_prodcat_name_out    :=null;
          p_prodcat_desc_out    :=null;
          p_package_id_out      :=null;
       END IF;
	   
	   
	 IF l_audit_flag = 'T'
	 THEN 
	 
-- SN Log into transaction log and cms_transaction_log_dtl
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
	  
	  ELSIF l_audit_flag = 'A'
      THEN 
	  
	  BEGIN
         
		 VMSCMS.VMS_LOG.LOG_TRANSACTIONLOG_AUDIT(p_msg_type_in,
												 p_rrn_in,
												 p_delivery_channel_in,
												 p_txn_code_in,                                     
												 '0',   
												 p_trandate_in,    
												 p_trantime_in,   
												 '00',  
												 p_pan_code_in,
												 p_respmsg_out,
												 0,
												 l_total_amt,
												 p_resp_code_out,
												 p_curr_code_in,
												 p_partner_id_in,
												 NULL,   
												 l_errmsg,
                                                 NULL,
                                                 p_ip_addr_in,
                                                 NULL,
                                                 CASE WHEN p_resp_code_out = '00' THEN  'C' ELSE 'F' END,
                                                 P_ANI_IN,
                                                 P_DNI_IN,
                                                 null,
                                                 null,
                                                 null,
                                                 null,
                                                 null,
                                                 null,
                                                 null,
                                                 l_fee_code,
                                                 l_tranfee_amt,
                                                 l_fee_plan,
                                                 l_feeattach_type
                                                 );
		
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
                  'Erorr while inserting to audit transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END; 
	  
	  END IF;


END get_customer_product_details;

PROCEDURE get_customer_profile_details(p_inst_code_in             IN  NUMBER,
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
                                   p_customer_id_out          OUT VARCHAR2,
                                   p_first_name_out           OUT VARCHAR2,
                                   p_middle_name_out          OUT VARCHAR2,
                                   p_last_name_out            OUT VARCHAR2,
                                   p_DOB_out                  OUT VARCHAR2,
                                   p_business_Name_out        OUT VARCHAR2,
                                   p_email_out                OUT VARCHAR2,
                                   p_mobile_out               OUT VARCHAR2,
                                   p_landline_out             OUT VARCHAR2,
                                   p_address_out              OUT sys_refcursor,
                                   p_proxy_no_out             OUT VARCHAR2,
                                   p_address_verf_flag_out    OUT VARCHAR2,
                                   p_SMS_alerts_conf_out      OUT VARCHAR2,
                                   p_email_alerts_conf_out    OUT VARCHAR2,
                                   p_latest_TandC_Ver_out     OUT VARCHAR2,
                                   p_TandC_accepted_out       OUT VARCHAR2,
                                   p_occupation_type_out      OUT VARCHAR2,
                                   p_occupation_out           OUT VARCHAR2
                                   )
AS

/****************************************************************
      
  * Modified By                  : Ubaidur Rahman.H
  * Modified Date                : 22-OCT-2021
  * Modified Reason              : VMS-4100
  * Build Number                 : Remove Personal Info Enquiry Txn logging from Transactionlog
  * Reviewer                     : Saravanakumar A.
  * Reviewed Date                : 22-Oct-2021
  
  
  * Modified By                  : Ubaidur Rahman.H
  * Modified Date                : 26-NOV-2021
  * Modified Reason              : VMS-5253 - Do not pass system Generated Profile from VMS to CCA
  * Build Number                 : R55 B3
  * Reviewer                     : Saravanakumar A.
  * Reviewed Date                : 26-Nov-2021
  
*****************************************************************/
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
      l_timestamp         transactionlog.time_stamp%TYPE;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
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
      l_cust_code         cms_cust_mast.ccm_cust_code%TYPE;
      l_alert_lang_id     CMS_SMSANDEMAIL_ALERT.CSA_ALERT_LANG_ID%TYPE;
      l_value             NUMBER;
      l_errmsg            transactionlog.error_msg%TYPE;
      l_addr_select_query VARCHAR2 (4000);
      l_cpp_tandc_version cms_product_param.cpp_tandc_version%TYPE;
      l_encrypt_enable    CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
      l_audit_flag		    cms_transaction_mast.ctm_txn_log_flag%TYPE;
      l_system_generated_profile  cms_cust_mast.ccm_system_generated_profile%TYPE;
      exp_reject_record   EXCEPTION;
   BEGIN
      BEGIN
         p_resp_code_out := '00';
         p_respmsg_out := 'success';
         p_SMS_alerts_conf_out := 'false';
         p_email_alerts_conf_out := 'false';
         p_TandC_accepted_out := 'false';

--Sn pan  and customer details
         BEGIN
          SELECT cap_pan_code, cap_pan_code_encr,cap_acct_no,
                cap_card_stat, cap_prod_code, cap_card_type,
                cap_expry_date, cap_active_date, cap_prfl_code,
                cap_proxy_number,cap_cust_code,
                decode(cpc_encrypt_enable,'Y',fn_dmaps_main(ccm_first_name),ccm_first_name),
                decode(cpc_encrypt_enable,'Y',fn_dmaps_main(ccm_mid_name),ccm_mid_name),
                decode(cpc_encrypt_enable,'Y',fn_dmaps_main(ccm_last_name),ccm_last_name) ,
                to_char(ccm_birth_date, 'YYYY-MM-DD'),
                ccm_business_name,  ccm_addrverify_flag,
                ccm_tandc_version,ccm_occupation,DECODE(NVL(ccm_occupation,'00'),'00',CCM_OCCUPATION_OTHERS,(select VOM_OCCU_NAME from VMS_OCCUPATION_MAST where
			          VOM_OCCU_CODE = ccm_occupation))  ,
                ccm_cust_code,nvl(ccm_system_generated_profile,'N')
           INTO l_hash_pan, l_encr_pan,l_acct_no,
                l_card_stat, l_prod_code, l_prod_cattype,
                l_expry_date, l_active_date, l_prfl_code,
                l_proxynumber,l_cust_code,p_first_name_out,
                p_middle_name_out,p_last_name_out ,p_DOB_out,
                p_business_name_out ,  p_address_verf_flag_out,
                p_latest_TandC_Ver_out,p_occupation_type_out,p_occupation_out,
                l_cust_code,l_system_generated_profile
           FROM cms_appl_pan , cms_cust_mast,cms_prod_cattype
          WHERE cap_inst_code = ccm_inst_code
          and cap_inst_code=cpc_inst_code
          and cap_prod_code=cpc_prod_code
          and cap_card_type=cpc_card_type
            AND cap_cust_code = ccm_cust_code
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

--Sn pan  and customer details
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
         --- VMS-4100 - Added for Remove Personal Info Enquiry Txn logging from Transactionlog		
         BEGIN  
                    
               SELECT nvl(ctm_txn_log_flag,'T')
                 INTO l_audit_flag
                 FROM cms_transaction_mast
                WHERE ctm_inst_code = 1
                  AND ctm_tran_code = p_txn_code_in
                  AND ctm_delivery_channel = p_delivery_channel_in;
         EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code_out := '12';
                  l_errmsg :=
                        'Error while selcting txn log type'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
          END;

         -- Sn validating Date Time RRN
         IF l_dup_rrn_check = 'Y' AND l_audit_flag = 'T' THEN  		 	--- Modified for VMS-4100 -  Remove Personal Info Enquiry Txn logging 
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

    --Sn check if Encrypt Enabled
      BEGIN
       SELECT  CPC_ENCRYPT_ENABLE
         INTO  L_ENCRYPT_ENABLE
         FROM  CMS_PROD_CATTYPE
        WHERE CPC_INST_CODE = p_inst_code_in
          AND CPC_PROD_CODE = l_prod_code
          AND CPC_CARD_TYPE = l_prod_cattype;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_resp_code_out := '16';
            l_errmsg   := 'Invalid Prod Code Card Type ' || l_prod_code || ' ' || l_prod_cattype;
            RAISE exp_reject_record;
        WHEN OTHERS THEN
            p_resp_code_out := '12';
            l_errmsg   := 'Problem while selecting product category details' || SUBSTR(SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
    --En check if Encrypt Enabled

    --SN : authorize_nonfinancial_txn check

       p_customer_id_out := p_cust_id_in;
       p_proxy_no_out  := l_proxynumber;

    --SN SMS and EMAIL Alert

    BEGIN
      SELECT CSA_ALERT_LANG_ID
      INTO l_alert_lang_id
      FROM CMS_SMSANDEMAIL_ALERT
      WHERE CSA_PAN_CODE=l_hash_pan;
   EXCEPTION
     WHEN OTHERS THEN
      p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting SMS and Email alerts '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
     END;

   BEGIN
    FOR i IN (select * from CMS_SMSEMAIL_ALERT_DET det,CMS_PRODCATG_SMSEMAIL_ALERTS alert
    WHERE nvl(dbms_lob.substr( alert.cps_alert_msg,1,1),0) <>0
    AND alert.cps_alert_id=det.cad_alert_id
    AND alert.CPS_PROD_CODE = l_prod_code
    AND alert.CPS_CARD_TYPE = l_prod_cattype
    AND alert.CPS_INST_CODE= p_inst_code_in
    AND alert.cps_alert_lang_id = l_alert_lang_id )
      LOOP
      BEGIN
        EXECUTE IMMEDIATE 'SELECT '|| i.CAD_COLUMN_NAME||' FROM CMS_SMSANDEMAIL_ALERT WHERE CSA_PAN_CODE= :l_hash_pan'
        INTO l_value USING l_hash_pan ;
        IF l_value=3 THEN
            p_SMS_alerts_conf_out:='true';
            p_email_alerts_conf_out:='true';
        ELSIF l_value =1 THEN
            p_SMS_alerts_conf_out:='true';
        ELSIF l_value =2 THEN
            p_email_alerts_conf_out:='true';
        END IF;
		
        EXIT WHEN p_SMS_alerts_conf_out='true' AND p_email_alerts_conf_out='true' ;
     EXCEPTION
         WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting SMS and Email alerts '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
     END;
    END LOOP;
     EXCEPTION
     WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error in main loop '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
    END;

    --SN SMS and EMAIL Alert

    --SN TandC Accepted
    BEGIN
        SELECT CPP_TANDC_VERSION
        INTO l_CPP_TANDC_VERSION
        FROM CMS_PRODUCT_PARAM
        WHERE CPP_INST_CODE = p_inst_code_in
        AND   CPP_PROD_CODE = l_prod_code;

       IF  l_cpp_tandc_version = p_latest_TandC_Ver_out
       THEN
           p_TandC_accepted_out := 'true';
       END IF;

    EXCEPTION
    WHEN OTHERS THEN
        p_resp_code_out := '21';
        l_errmsg := 'Error while checking TandC accepted flag'
        || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;

    END;
    --EN TandC Accepted

   BEGIN
         SELECT  decode(l_encrypt_enable,'Y',fn_dmaps_main(cam_mobl_one),cam_mobl_one) ,
         decode(l_encrypt_enable,'Y',fn_dmaps_main(cam_phone_one),cam_phone_one),
         decode(l_encrypt_enable,'Y',fn_dmaps_main(cam_email),cam_email)
         INTO p_mobile_out, p_landline_out,p_email_out
         FROM CMS_ADDR_MAST
         WHERE CAM_INST_CODE =  p_inst_code_in
         AND CAM_CUST_CODE = l_cust_code
         AND CAM_ADDR_FLAG = 'P';

     EXCEPTION
     WHEN OTHERS THEN
        p_resp_code_out := '21';
        l_errmsg :=
                  'Error while selecting Phone Number '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
     END;

    -- SN Generate ADDRESS select query		 --- Modified for VMS-5253
         BEGIN
            l_addr_select_query :=
                              '(SELECT (CASE cam_addr_flag
                                        WHEN ''P'' THEN
                                           ''PHYSICAL''
                                        ELSE
                                           ''MAILING''
                                        END) address_type,
                                  decode(:l_system_generated_profile,''N'',decode(:l_encrypt_enable,''Y'',fn_dmaps_main(cam_add_one),cam_add_one)) address1,
                                  decode(:l_system_generated_profile,''N'',decode(:l_encrypt_enable,''Y'',fn_dmaps_main(cam_add_two),cam_add_two)) address2,
                                  decode(:l_system_generated_profile,''N'',decode(:l_encrypt_enable,''Y'',fn_dmaps_main(cam_city_name),cam_city_name)) city,
                                  decode(:l_system_generated_profile,''N'',(SELECT upper(gs.gsm_switch_state_code)
                                     FROM gen_state_mast gs
                                    WHERE gs.gsm_inst_code = cam_inst_code
                                      AND gs.gsm_state_code = cam_state_code
                                      AND gs.gsm_cntry_code = cam_cntry_code)) state,
                                  decode(:l_system_generated_profile,''N'',decode(:l_encrypt_enable,''Y'', fn_dmaps_main(cam_pin_code),cam_pin_code)) zip,
                                  decode(:l_system_generated_profile,''N'',(SELECT upper(gcm.gcm_switch_cntry_code)
                                     FROM gen_cntry_mast gcm
                                    WHERE gcm.gcm_inst_code = cam_inst_code
                                      AND gcm.gcm_cntry_code = cam_cntry_code)) cntry
                                  FROM cms_addr_mast
                                  WHERE cam_inst_code = :p_inst_code_in
                                  AND cam_cust_code = :l_cust_code)';

           END;
   -- EN Generate ADDRESS select query

   -- SN Open cursor to execute address select query    --- Modified for VMS-5253
         BEGIN
           
           OPEN p_address_out FOR l_addr_select_query
           USING 
                 l_system_generated_profile,l_encrypt_enable,
                 l_system_generated_profile,l_encrypt_enable,
                 l_system_generated_profile,l_encrypt_enable,
                 l_system_generated_profile,
                 l_system_generated_profile,l_encrypt_enable,
                 l_system_generated_profile,
           p_inst_code_in, l_cust_code;  
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while executing Address query '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

   -- EN Close cursor to address select query

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
        WHEN NO_DATA_FOUND
        THEN
           p_resp_code_out := '21';
         l_errmsg := 'Invalid Card number ';
      WHEN OTHERS
        THEN
           p_resp_code_out := '12';
           l_errmsg :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      IF p_resp_code_out <> '00' THEN
          p_respmsg_out  :=l_errmsg;
          p_customer_id_out :=null;
          p_first_name_out    :=null;
          p_middle_name_out   :=null;
          p_last_name_out     :=null;
          p_DOB_out           :=null;
          p_business_Name_out   :=null;
          p_email_out          :=null;
          p_mobile_out        :=null;
          p_landline_out       :=null;
          p_proxy_no_out      :=null;
          p_address_verf_flag_out   :=null;
          p_SMS_alerts_conf_out     :=null;
          p_email_alerts_conf_out :=null;
          p_latest_TandC_Ver_out   :=null;
          p_TandC_accepted_out   :=null;

      END IF;
      
      IF l_audit_flag = 'T'		      --- Modified for VMS-4100 -  Remove Personal Info Enquiry Txn logging from Transactionlog		
      THEN 
      
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
      
      ELSIF l_audit_flag = 'A'
      THEN
      
      BEGIN
         
		 VMSCMS.VMS_LOG.LOG_TRANSACTIONLOG_AUDIT(p_msg_type_in,
						 p_rrn_in,
						 p_delivery_channel_in,
						 p_txn_code_in,                                     
						 '0',   
						 p_trandate_in,    
						 p_trantime_in,   
						 '00',  
						 p_pan_code_in,
						 l_errmsg,
						 0,
						 NULL,
						 CASE WHEN p_resp_code_out = '00' THEN  '1' ELSE p_resp_code_out END,
						 p_curr_code_in,
						 p_partner_id_in,
		  				 NULL,   
						 l_errmsg,
                                                 NULL,
                                                 p_ip_addr_in,
                                                 NULL,
                                                 CASE WHEN p_resp_code_out = '00' THEN  'C' ELSE 'F' END,
                                                 P_ANI_IN,
                                                 P_DNI_IN);
                                                 
                                                 
		
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            l_errmsg :=
                  'Erorr while inserting to audit transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END; 
	  
      END IF;
      
      

END get_customer_profile_details;

PROCEDURE get_products_details (
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
                             p_prod_info_out           OUT      sys_refcursor,
                             p_prod_catg_info_out      OUT      sys_refcursor,
                             p_fee_plan_info_out       OUT      sys_refcursor,
                             p_fee_info_out            OUT      sys_refcursor,
                             p_resp_code_out           OUT      VARCHAR2,
                             p_resp_msg_out            OUT      VARCHAR2)
AS
   l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
   l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
   l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
   l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
   l_errmsg            transactionlog.error_msg%TYPE;
   l_prod_info         VARCHAR2 (32767);
   l_prod_catg_info    VARCHAR2 (32767);
   l_fee_plan_info     VARCHAR2 (32767);
   l_fee_info          VARCHAR2 (32767);
  l_cnt  number;
   exp_reject_record   EXCEPTION;
      /****************************************************************
      
  * Modified By                  : Sivakumar M.
  * Modified Date                : 10-Jan-2019
  * Modified Reason              : VMS-728
  * Build Number                 : VMSGPRHOST_R11_B0001
  * Reviewer                     : Saravanakumar A.
  * Reviewed Date                : 10-Jan-2019
  
      *****************************************************************/
BEGIN
   BEGIN
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
                  'Error while validating DATE and RRN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      END IF;

      begin
       select count(1)
       into l_cnt
       from Vms_Groupid_Partnerid_Map
       where vgp_partner_id=p_partner_id_in;

       if l_cnt=0 then
            p_resp_code_out := '89';
            l_errmsg :='Invalid Partner ID';
            RAISE exp_reject_record;
       end if;
    exception
    when exp_reject_record then
            RAISE ;
    when others then
        p_resp_code_out := '89';
            l_errmsg :='Error while getting partner details '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;

   end;

      BEGIN
         l_prod_info :=
            'select distinct vpg_prod_code prod_code,cpm_prod_desc prod_desc
          from cms_prod_mast,Vms_Groupid_Partnerid_Map,Vms_Prod_Groupaccess_Map
          where vgp_group_access_name=vpg_prod_group_name
          and vpg_prod_code=cpm_prod_code
          and vgp_partner_id=:p_partner_id_in';

         OPEN p_prod_info_out FOR l_prod_info USING p_partner_id_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while getting product details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         l_prod_catg_info :=
            'select cpc_prod_code prod_code,cpc_card_type card_type,cpc_product_id product_id
            ,cpc_cardtype_desc cardtype_desc,cpc_cardtype_sname cardtype_sname,cpc_src_app srcapp
from cms_prod_cattype,Vms_Groupid_Partnerid_Map,Vms_Prod_Groupaccess_Map
                where vgp_group_access_name=vpg_prod_group_name
                and vpg_prod_code=cpc_prod_code
                and vpg_card_type=cpc_card_type
                and vgp_partner_id=:p_partner_id_in';

         OPEN p_prod_catg_info_out FOR l_prod_catg_info USING p_partner_id_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while getting product category details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
          l_fee_plan_info :=
            'SELECT product_code, card_type, fee_plan_id, fee_plan_desc,
            to_char(start_date,''YYYY-MM-DD'') start_date,
            to_char(end_date,''YYYY-MM-DD'') end_date,
       (CASE
           WHEN (    end_date IS NOT NULL
                 AND TRUNC (SYSDATE) BETWEEN start_date AND end_date
                )
            OR (end_date IS NULL AND TRUNC (SYSDATE) >= start_date)
              THEN ''true''
           ELSE ''false''
        END
       ) is_active
  FROM (SELECT cpf_prod_code product_code,cpf_card_type card_type, cfp_plan_id fee_plan_id,
               cfp_plan_desc fee_plan_desc, cpf_valid_from start_date,
               cpf_valid_to end_date
          FROM cms_fee_plan, cms_prodcattype_fees,
          Vms_Groupid_Partnerid_Map,Vms_Prod_Groupaccess_Map,cms_feeplan_prod_mapg
          where vgp_group_access_name=vpg_prod_group_name
           AND cpf_prod_code = vpg_prod_code
           and cpf_card_type=vpg_card_type
           AND cpf_inst_code = cfp_inst_code
           AND cpf_fee_plan = cfp_plan_id
           AND vgp_partner_id = :p_partner_id_in
           AND cfp_plan_id=cfm_plan_id
           AND cfm_prod_code=vpg_prod_code
        UNION
       SELECT cpf_prod_code product_code,cpc_card_type card_type, cfp_plan_id fee_plan_id,
               cfp_plan_desc fee_plan_desc, cpf_valid_from start_date,
               cpf_valid_to end_date
          FROM cms_fee_plan, cms_prod_fees,cms_feeplan_prod_mapg,
          cms_prod_cattype,Vms_Groupid_Partnerid_Map,Vms_Prod_Groupaccess_Map
          where vgp_group_access_name=vpg_prod_group_name
         and cpf_prod_code = vpg_prod_code
         and cpc_card_type=vpg_card_type
           AND cpf_fee_plan = cfp_plan_id
           AND vgp_partner_id =:p_partner_id_in
           AND cfp_plan_id=cfm_plan_id
           AND cfm_prod_code=vpg_prod_code
           and cfm_prod_code=cpc_prod_code)';

         OPEN p_fee_plan_info_out FOR l_fee_plan_info USING p_partner_id_in,p_partner_id_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while getting fee plan  details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
	  
   -- Modified the below query to fetch Monthly fee details for vms-728.
      BEGIN
         l_fee_info :='SELECT distinct a.cff_fee_plan fee_id,
                        cfm_fee_code fee_code,
                        nvl(cfl_other_param,cfm_fee_desc) fee_type,
                        cfm_fee_desc fee_desc,
                        trim(to_char(nvl(cfm_fee_amt, 0), ''99999999999999990.99'')) fee_amt,
                        trim(to_char(nvl(cfm_per_fees, 0), ''99999999999999990.99'')) per_fees,
                        trim(to_char(nvl(cfm_min_fees, 0), ''99999999999999990.99'')) min_fees,
                        decode(UPPER(cfm_clawback_flag),''Y'',''true'',''false'') clawback_flag
                        FROM cms_fee_mast,cms_fee_types,Cms_Feetxn_List,
                             (SELECT cff_fee_code, cff_fee_plan
                                FROM cms_fee_feeplan,cms_feeplan_prod_mapg,Vms_Groupid_Partnerid_Map,
                                Vms_Prod_Groupaccess_Map
                                where vgp_group_access_name=vpg_prod_group_name
                               and cff_fee_plan = cfm_plan_id
                                 and cfm_prod_code=vpg_prod_code
                                 and vgp_partner_id=:p_partner_id_in
                                 AND cff_inst_code = cfm_inst_code
                                 ) a
                        WHERE cfm_inst_code =:p_inst_code_in
                        AND cfm_fee_code = a.cff_fee_code
                        and cfm_feetype_code = cft_feetype_code
                        --AND cft_inst_code        = cfl_inst_code
                        AND Cfl_Dlvr_Chnl(+)        =Cfm_Delivery_Channel
                        AND Cfl_tran_code (+)       =Cfm_tran_code
                        AND Cfl_Inst_Code (+)        =Cfm_Inst_Code
                        AND cfl_other_param_key(+) = NVL(Cfm_Delivery_Channel,''NA'')
                            ||'',''
                            ||NVL(Cfm_Tran_Code,''NA'')
                            ||'',''
                            ||NVL(Cfm_Intl_Indicator,''NA'')
                            ||'',''
                            ||NVL(Cfm_Pin_Sign,''NA'')
                            ||'',''
                            ||NVL(Cfm_Merc_Code,''NA'')
                            ||'',''
                            ||NVL(Cfm_Normal_Rvsl,''NA'')
                            ||'',''
                            ||NVL(CFM_APPROVE_STATUS,''NA'')
                        ORDER BY fee_id';

         OPEN p_fee_info_out FOR l_fee_info USING p_partner_id_in,p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                'Error while getting fee details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      p_resp_code_out := '1';
      p_resp_msg_out := 'success';
   EXCEPTION                                            --<<Main Exception>>--
      WHEN exp_reject_record
      THEN
         ROLLBACK;
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
      WHEN OTHERS
      THEN
         l_errmsg :=l_errmsg||
               'Error while selecting from response master '
            || p_resp_msg_out
            || p_resp_code_out
            || ' IS-'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
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
                                  NULL,
                                  NULL,
                                  l_errmsg,
                                  p_ip_addr_in,
                                  NULL,
                                  l_txn_desc,
                                  p_ani_in,
                                  p_dni_in,
                                  SYSTIMESTAMP,
                                  NULL,
                                  NULL,
                                  NULL,
                                  l_cr_dr_flag,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  p_resp_code_out,
                                  p_resp_code_out,
                                  p_curr_code_in,
                                  NULL,
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
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '69';
         p_resp_msg_out :=
               'Exception while inserting to transaction log '
            || SUBSTR (SQLERRM, 1, 300);
   END;
END get_products_details;

PROCEDURE get_alerts(p_inst_code_in             IN  NUMBER,
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
                     p_email_out                OUT VARCHAR2,
                     p_phone_out                OUT VARCHAR2,
                     p_lang_out                 OUT VARCHAR2,
                     p_alerts_array_out         OUT VARCHAR2
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
      l_timestamp         transactionlog.time_stamp%TYPE;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
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
      l_alert_lang_id     cms_smsandemail_alert.csa_alert_lang_id%TYPE;
      l_value             VARCHAR2(100);
      l_amount            VARCHAR2(100);
      l_type              VARCHAR2(100);
      l_errmsg            transactionlog.error_msg%TYPE;
      exp_reject_record   EXCEPTION;
      l_encrypt_enable cms_prod_cattype.cpc_encrypt_enable%type;

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

   -- SN - Retrieve Language ID
   BEGIN
       SELECT csa_alert_lang_id
         INTO l_alert_lang_id
         FROM cms_smsandemail_alert
        WhERE csa_pan_code= gethash(p_pan_code_in) ;
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           p_resp_code_out := '21';
           l_errmsg  := 'No Alert detail set for PAN ';
        RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
           p_resp_code_out := '21';
           l_errmsg  := 'Error while Selecting Alert Details of Card'||SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
    END;

        IF l_alert_lang_id IS NULL THEN
      BEGIN
            SELECT cps_alert_lang_id
                   INTO l_alert_lang_id
              FROM cms_prodcatg_smsemail_alerts
             WHERE cps_inst_code = p_inst_code_in
               AND cps_prod_code = l_prod_code
               AND cps_card_type = l_card_type
               AND CPS_DEFALERT_LANG_FLAG='Y'
               and rownum=1;
                EXCEPTION
        WHEN NO_DATA_FOUND THEN
           p_resp_code_out := '21';
           l_errmsg  := 'No Alert detail set for product level ';
        RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
           p_resp_code_out := '21';
           l_errmsg  := 'Error while Selecting Alert Details of Card'||SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
        END;
        END IF;
   -- EN - Retrieve Language ID
        BEGIN
         SELECT decode(l_encrypt_enable,'Y',fn_dmaps_main(CAM_MOBL_ONE),CAM_MOBL_ONE),
         decode(l_encrypt_enable,'Y',fn_dmaps_main(CAM_EMAIL),CAM_EMAIL)
         INTO p_phone_out,p_email_out
         FROM CMS_ADDR_MAST WHERE CAM_CUST_CODE=l_cust_code
         AND CAM_INST_CODE=p_inst_code_in
         AND cam_addr_flag = 'P';
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
         p_resp_code_out := '21';
         l_errmsg   := 'Customer Details Not Found';
         RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg   := 'Error while selecting CMS_ADDR_MAST '||substr(sqlerrm,1,200);
         RAISE EXP_REJECT_RECORD;

         END;

   --SN Alert Language
   BEGIN

      SELECT vas_alert_lang
        INTO p_lang_out
        FROM VMS_ALERTS_SUPPORTLANG
       WHERE vas_alert_lang_id = l_alert_lang_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           p_resp_code_out := '21';
           l_errmsg  := 'Invalid Alert Language ID ';
        RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
           p_resp_code_out := '21';
           l_errmsg  := 'Error while retrieving language'||SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
    END;
  --EN Alert Language

    BEGIN
    FOR i IN (select * from CMS_SMSEMAIL_ALERT_DET det,CMS_PRODCATG_SMSEMAIL_ALERTS alert
    WHERE nvl(dbms_lob.substr( alert.cps_alert_msg,1,1),0) !=0
    AND alert.cps_alert_id=det.cad_alert_id
    AND alert.CPS_PROD_CODE = l_prod_code
    AND alert.CPS_CARD_TYPE = l_card_type
    AND alert.CPS_INST_CODE= p_inst_code_in
    AND alert.cps_alert_lang_id = l_alert_lang_id )
      LOOP
      BEGIN
        IF i.cad_alert_id IN (10,16) THEN
            EXECUTE IMMEDIATE 'SELECT '|| i.CAD_COLUMN_NAME||','||I.CAD_ALERT_AMNT_COLUMN||' FROM CMS_SMSANDEMAIL_ALERT WHERE CSA_PAN_CODE= :l_hash_pan'
            INTO l_value,l_amount USING l_hash_pan ;
        ELSE
            EXECUTE IMMEDIATE 'SELECT '|| i.CAD_COLUMN_NAME||' FROM CMS_SMSANDEMAIL_ALERT WHERE CSA_PAN_CODE= :l_hash_pan'
            INTO l_value USING l_hash_pan ;
            l_amount:=null;
        END IF;
        IF l_value=3 THEN
            l_type:='BOTH';
        ELSIF l_value =1 THEN
            l_type:='MOBILE';
        ELSIF l_value =2 THEN
            l_type:='EMAIL';
         ELSE
            l_type:='OFF';
        END IF;
         p_alerts_array_out := p_alerts_array_out||i.cad_alert_id||'|'||i.cad_alert_name||'|'||i.cad_alert_desc||'|'||l_amount ||'|'||l_type ||':';
     EXCEPTION
         WHEN OTHERS THEN
           p_resp_code_out := '21';
           l_errmsg  := 'Error in Alerts array'||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
     END;
    END LOOP;


     EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
      RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN

         p_resp_code_out := '21';
         l_errmsg  := 'Error in Alerts info'||SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
    END;

    --EN Alert info


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
          p_email_out  :=null;
          p_phone_out     :=null;
          p_lang_out     :=null;
          p_alerts_array_out    :=null;
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

END get_alerts;

PROCEDURE update_alerts(p_inst_code_in          IN  NUMBER,
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
                     p_email_in                 IN  VARCHAR2,
                     p_phone_in                 IN  VARCHAR2,
                     p_lang_in                  IN  VARCHAR2,
                     p_alerts_array_in          IN  VARCHAR2,
                     p_resp_code_out            OUT VARCHAR2,
                     p_respmsg_out              OUT VARCHAR2,
                     p_optin_flag_out           OUT VARCHAR2
                     )
AS

   /*************************************************
    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
  *************************************************/
  
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
      l_timestamp         transactionlog.time_stamp%TYPE;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
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
      l_alert_lang_id     cms_smsandemail_alert.csa_alert_lang_id%TYPE;
      l_value             VARCHAR2(100);
      l_amount            VARCHAR2(100);
      l_type              VARCHAR2(100);
      l_errmsg            transactionlog.error_msg%TYPE;
      l_num               number:=1;
      l_alert_detail      VARCHAR2 (1000);
      l_alert_id          CMS_SMSEMAIL_ALERT_DET.cad_alert_id%TYPE;
      l_mobile_alert      number :=0;
      l_email_alert       number :=0;
      exp_reject_record   EXCEPTION;
      l_count             number;
      l_cust_id           cms_cust_mast.ccm_cust_id%type;
      l_col_name         CMS_SMSEMAIL_ALERT_DET.CAD_COLUMN_NAME%type;
      l_amount_col_name  CMS_SMSEMAIL_ALERT_DET.CAD_ALERT_AMNT_COLUMN%type;
      l_alert_name     CMS_SMSEMAIL_ALERT_DET.cad_alert_name%type;
      l_encrypt_enable cms_prod_cattype.cpc_encrypt_enable%type;
      l_phone cms_addr_mast.cam_phone_one%type;
      l_email cms_addr_mast.cam_email%type;
      V_Decr_Cellphn       Cms_Addr_Mast.Cam_Mobl_One%Type;
      V_Cam_Mobl_One       Cms_Addr_Mast.Cam_Mobl_One%Type;
      L_OptinAlert_Lang_Id     Cms_Smsandemail_Alert.Csa_Alert_Lang_Id%Type;
      V_Doptin_Flag Number;
     v_loadcredit_flag        CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%TYPE;
   v_lowbal_flag            CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%TYPE;
   v_negativebal_flag       CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%TYPE;
   v_highauthamt_flag       CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%TYPE;
   v_dailybal_flag          CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%TYPE;
   V_Insuffund_Flag         Cms_Smsandemail_Alert.Csa_Insuff_Flag%Type;
   V_Incorrectpin_Flag      CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%Type;
   V_Fast50_Flag  Cms_Smsandemail_Alert.Csa_Fast50_Flag%Type;
   v_federal_state_flag  CMS_SMSANDEMAIL_ALERT.CSA_FEDTAX_REFUND_FLAG%Type;

   v_new_loadcredit_flag        CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%TYPE;
   v_new_lowbal_flag            CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%TYPE;
   v_new_negativebal_flag       CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%TYPE;
   v_new_highauthamt_flag       CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%TYPE;
   v_new_dailybal_flag          CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%TYPE;
   V_new_Insuffund_Flag         Cms_Smsandemail_Alert.Csa_Insuff_Flag%Type;
   V_new_Incorrectpin_Flag      CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%Type;
   V_new_Fast50_Flag            Cms_Smsandemail_Alert.Csa_Fast50_Flag%Type;
   v_new_federal_state_flag     CMS_SMSANDEMAIL_ALERT.CSA_FEDTAX_REFUND_FLAG%Type;
     Type CurrentAlert_Collection Is Table Of Varchar2(30);
     CurrentAlert CurrentAlert_Collection;
     Type Previousalert_Collection Is Table Of Varchar2(30);
     Previousalert Previousalert_Collection;
   BEGIN
      BEGIN

         p_respmsg_out := 'success';
         p_optin_flag_out := 'Y';
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
        begin
            select ccm_cust_id into l_cust_id
            from cms_cust_mast
            where ccm_cust_code=l_cust_code
            and ccm_inst_code=p_inst_code_in;
       EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :='Error in getting Customer Details' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
--Sn pan  and customer details
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


  if p_lang_in is not null then
      --SN Alert Language
       BEGIN

          SELECT vas_alert_lang_id
            INTO l_alert_lang_id
            FROM VMS_ALERTS_SUPPORTLANG
           WHERE upper(vas_alert_lang) = upper(p_lang_in);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
               p_resp_code_out := '21';
               l_errmsg  := 'Unsupported Language';
            RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
               p_resp_code_out := '21';
               l_errmsg  := 'Error while retrieving language'||SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;
      --EN Alert Language  -- SN - Retrieve Language ID
    else
         BEGIN
                  SELECT cps_alert_lang_id
                         INTO l_alert_lang_id
                    FROM cms_prodcatg_smsemail_alerts
                   WHERE cps_inst_code = p_inst_code_in
                     AND cps_prod_code = l_prod_code
                     AND cps_card_type = l_card_type
                     AND CPS_DEFALERT_LANG_FLAG='Y'
                     and rownum=1;
                      EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 p_resp_code_out := '21';
                 l_errmsg  := 'Unsupported Language  ';
              RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                 p_resp_code_out := '21';
                 l_errmsg  := 'Error while Selecting Alert Details of Card'||SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
              END;
      end if;


			BEGIN
			  UPDATE CMS_SMSANDEMAIL_ALERT
			  SET CSA_ALERT_LANG_ID = l_alert_lang_id
			  WHERE CSA_PAN_CODE    = l_hash_pan;

			EXCEPTION
			WHEN OTHERS THEN
			  p_resp_code_out := '21';
			  l_errmsg        := 'Error in Updating language Id in CMS_SMAANDEMAIL_ALERT' || SUBSTR (SQLERRM, 1, 200);
			  RAISE exp_reject_record;
			END;

   BEGIN
        Select Csa_Alert_Lang_Id,Csa_Loadorcredit_Flag,Csa_Lowbal_Flag,Csa_Negbal_Flag,Csa_Highauthamt_Flag,Csa_Dailybal_Flag,Csa_Insuff_Flag, Csa_Fedtax_Refund_Flag, Csa_Fast50_Flag,Csa_Incorrpin_Flag
        Into L_Optinalert_Lang_Id,V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag
        From Cms_Smsandemail_Alert Where Csa_Pan_Code=Gethash (P_Pan_Code_In)   And Csa_Inst_Code=P_Inst_Code_In;
     	EXCEPTION
			WHEN OTHERS THEN
			  P_Resp_Code_Out := '21';
			  l_errmsg        := 'Error while selecting data from CMS_SMAANDEMAIL_ALERT' || SUBSTR (SQLERRM, 1, 200);
			  Raise Exp_Reject_Record;
			END;

      LOOP
          BEGIN
              l_alert_detail := REGEXP_SUBSTR (p_alerts_array_in, '[^:]+', 1, l_num);

              EXIT WHEN l_alert_detail IS NULL ;

              l_alert_id:= substr(l_alert_detail,1,instr(l_alert_detail,'|',1,1)-1) ;
              l_alert_detail:=substr(l_alert_detail,instr(l_alert_detail,'|',1,3)+1);
              l_amount:= substr(l_alert_detail,1,instr(l_alert_detail,'|',1,1)-1) ;
              l_type:=substr(l_alert_detail,instr(l_alert_detail,'|',1,1)+1);


              /*l_alert_id:= REGEXP_SUBSTR (l_alert_detail, '[^|]+', 1, 1);
              l_amount:= REGEXP_SUBSTR (l_alert_detail, '[^|]+', 1, 4);
              l_type:= REGEXP_SUBSTR (l_alert_detail, '[^|]+', 1, 5);*/

              l_num := l_num + 1;

              begin
                    select det.CAD_COLUMN_NAME,det.CAD_ALERT_AMNT_COLUMN,det.cad_alert_name
                    into l_col_name,l_amount_col_name,l_alert_name
                    from CMS_SMSEMAIL_ALERT_DET det,CMS_PRODCATG_SMSEMAIL_ALERTS alert
                    WHERE nvl(dbms_lob.substr( alert.cps_alert_msg,1,1),0) <>0
                    AND alert.cps_alert_id=det.cad_alert_id
                    AND alert.CPS_PROD_CODE = l_prod_code
                    AND alert.CPS_CARD_TYPE = l_card_type
                    AND alert.CPS_INST_CODE= p_inst_code_in
                    AND alert.cps_alert_lang_id = l_alert_lang_id
                    and det.cad_alert_id=l_alert_id;
              exception
              when no_data_found then
                  p_resp_code_out := '300';
                  l_errmsg  := 'Invalid Alert Id';
                  RAISE EXP_REJECT_RECORD;
              when others then
                   p_resp_code_out := '21';
                  l_errmsg  := 'Error while selecting alert details '||SUBSTR(SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
              end;


              If upper(l_type) not in ('BOTH','MOBILE','EMAIL','OFF') then
                   p_resp_code_out := '301';
                  l_errmsg  := 'Invalid Alert Type';
                  RAISE EXP_REJECT_RECORD;
              end if;

              If upper(l_type)='BOTH' then
                  l_value:=3;
                  l_mobile_alert  :=l_mobile_alert+1;
                  l_email_alert  :=l_email_alert+1;
              elsif upper(l_type)='MOBILE' then
                  l_value:=1;
                  l_mobile_alert  :=l_mobile_alert+1;
              elsif upper(l_type)='EMAIL' then
                  l_value:=2;
                  l_email_alert  :=l_email_alert+1;
              else
                  l_value:=0;
              end if;


              BEGIN

                  IF l_alert_id IN (10,16) THEN
                      if l_amount is null then
                          p_resp_code_out := '21';
                          l_errmsg  := 'Amount should be Mandatory for '||l_alert_name;
                          RAISE EXP_REJECT_RECORD;
                      end if;

                      EXECUTE IMMEDIATE 'update CMS_SMSANDEMAIL_ALERT set '|| l_col_name||' = '||l_value ||' , '||l_amount_col_name
                      ||' = '||l_amount ||' WHERE CSA_PAN_CODE= :l_hash_pan' USING l_hash_pan ;
                  ELSE
                      EXECUTE IMMEDIATE 'update CMS_SMSANDEMAIL_ALERT set '||l_col_name||' = '||l_value ||' WHERE CSA_PAN_CODE= :l_hash_pan'
                      USING l_hash_pan ;
                  END IF;

                  if sql%rowcount=0 then
                      p_resp_code_out := '21';
                      l_errmsg  := 'Error while updating CMS_SMSANDEMAIL_ALERT '||SUBSTR(SQLERRM, 1, 200);
                      RAISE EXP_REJECT_RECORD;
                  end if;

              EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
                  RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                      p_resp_code_out := '21';
                      l_errmsg  := 'Error while updating CMS_SMSANDEMAIL_ALERT '||SUBSTR(SQLERRM, 1, 200);
                      RAISE EXP_REJECT_RECORD;
              END;


          EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
                  RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                  p_resp_code_out := '21';
                  l_errmsg  := 'Error in Alerts info'||SUBSTR(SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
              END;
      END LOOP;
  begin
     select count(1) into v_doptin_flag from CMS_PRODCATG_SMSEMAIL_ALERTS
    Where Nvl(Dbms_Lob.Substr( Cps_Alert_Msg,1,1),0) <>0
    And Cps_Prod_Code = l_Prod_Code
    And Cps_Card_Type = l_card_type
    and cps_alert_id=33
    And Cps_Inst_Code= p_inst_code_in
    And ( Cps_Alert_Lang_Id = L_Optinalert_Lang_Id or (L_Optinalert_Lang_Id is null and CPS_DEFALERT_LANG_FLAG = 'Y'));

      If(v_doptin_flag = 1)
      Then
            Select Csa_Loadorcredit_Flag,Csa_Lowbal_Flag,Csa_Negbal_Flag,Csa_Highauthamt_Flag,Csa_Dailybal_Flag,Csa_Insuff_Flag, Csa_Fedtax_Refund_Flag, Csa_Fast50_Flag,Csa_Incorrpin_Flag
            Into V_new_Loadcredit_Flag,V_new_Lowbal_Flag,V_new_Negativebal_Flag,V_new_Highauthamt_Flag,V_new_Dailybal_Flag,V_new_Insuffund_Flag, V_new_Federal_State_Flag, V_new_Fast50_Flag,V_new_Incorrectpin_Flag
            From Cms_Smsandemail_Alert Where Csa_Pan_Code=Gethash (P_Pan_Code_In)   And Csa_Inst_Code=P_Inst_Code_In;

          Previousalert := Previousalert_Collection(V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag);
          Currentalert:= Currentalert_Collection(V_new_Loadcredit_Flag,V_new_Lowbal_Flag,V_new_Negativebal_Flag,V_new_Highauthamt_Flag,V_new_Dailybal_Flag,V_new_Insuffund_Flag, V_new_Federal_State_Flag, V_new_Fast50_Flag,V_new_Incorrectpin_Flag);
              If (1 Member Of Previousalert Or 3 Member Of Previousalert )
               Then
              p_optin_flag_out:='N';
            Else
                if(1  Member Of Currentalert or 3  Member Of Currentalert)
                Then
                p_optin_flag_out:='Y';
                 Else
               p_optin_flag_out:='N';
            End If;
        End If;
      Else
       P_Optin_Flag_Out:='N';
     End If;
     	EXCEPTION
			WHEN OTHERS THEN
			  P_Resp_Code_Out := '21';
			  l_errmsg        := 'Error while selecting data from CMS_PRODCATG_SMSEMAIL_ALERTS' || SUBSTR (SQLERRM, 1, 200);
			  Raise Exp_Reject_Record;
			END;

      if l_email_alert <> 0 and p_email_in is null then
          p_resp_code_out := '125';
          l_errmsg  := 'For Enabling EMail alert EMail ID should be Mandatory ';
          RAISE EXP_REJECT_RECORD;
      end if;

      if l_mobile_alert <> 0 and p_phone_in is null then
          p_resp_code_out := '124';
          l_errmsg  := 'For Enabling SMS alert Mobile Number should be Mandatory';
          RAISE EXP_REJECT_RECORD;
      end if;

      l_timestamp:=SYSTIMESTAMP;

      BEGIN
          SELECT COUNT (*)
          INTO l_count
          FROM cms_optin_status
          WHERE cos_inst_code = p_inst_code_in AND cos_cust_id = l_cust_id;

          IF l_count > 0   THEN
                UPDATE cms_optin_status
                SET cos_sms_optinflag = decode(l_mobile_alert,0,0,1),
                cos_sms_optintime =decode(l_mobile_alert,'0',null,l_timestamp),
                cos_sms_optouttime =decode(l_mobile_alert,'0',l_timestamp,null),
                cos_email_optinflag = decode(l_email_alert,0,0,1),
                cos_email_optintime =decode(l_email_alert,'0',null,l_timestamp),
                cos_email_optouttime = decode(l_email_alert,'0',l_timestamp,null)
                WHERE cos_inst_code = p_inst_code_in AND cos_cust_id = l_cust_id;
          ELSE
                INSERT INTO cms_optin_status
                            (cos_inst_code,
                            cos_cust_id,
                            cos_sms_optinflag,
                            cos_sms_optintime,
                            cos_sms_optouttime,
                            cos_email_optinflag,
                            cos_email_optintime,
                            cos_email_optouttime
                            )
                VALUES     (p_inst_code_in,
                            l_cust_id,
                            decode(l_mobile_alert,0,0,1),
                            decode(l_mobile_alert,'0',null,l_timestamp),
                            decode(l_mobile_alert,'0',l_timestamp,null),
                            decode(l_email_alert,0,0,1),
                            decode(l_email_alert,'0',null,l_timestamp),
                            decode(l_email_alert,'0',l_timestamp,null)
                            );
          END IF;
      EXCEPTION
      WHEN OTHERS
      THEN
      p_resp_code_out := '21';
      l_errmsg :=     'ERROR IN INSERTING RECORDS IN CMS_OPTIN_STATUS' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
      END;
    --EN Alert info
      if l_encrypt_enable='Y' then
          l_phone:=fn_emaps_main(p_phone_in);
          l_email:=fn_emaps_main(p_email_in);
      else
          l_phone:=p_phone_in;
          l_email:=p_email_in;
      end if;

      BEGIN
      --If(v_doptin_flag = 1)
      --Then
      If(v_doptin_flag = 1 and P_Optin_Flag_Out = 'N' And ('1' Member Of Currentalert Or '3' Member Of Currentalert))
        Then
            Select Cam_Mobl_One Into V_Cam_Mobl_One From Cms_Addr_Mast
            Where Cam_Cust_Code=L_Cust_Code And Cam_Addr_Flag='P' And Cam_Inst_Code=p_inst_code_in;

          If(l_encrypt_enable = 'Y') Then
            V_Decr_Cellphn :=Fn_Dmaps_Main(V_Cam_Mobl_One);
            Else
            V_Decr_Cellphn := V_Cam_Mobl_One;
          End If;
            If(V_Decr_Cellphn <> l_phone)
            Then
                p_optin_flag_out :='Y';
                End If;
          End If;
      --End If;
      EXCEPTION
        WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg :='Error while selecting mobile number ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      END;

      BEGIN
          update CMS_ADDR_MAST
          set CAM_MOBL_ONE=nvl(l_phone,CAM_MOBL_ONE),
          CAM_EMAIL =nvl(l_email,CAM_EMAIL),
		  CAM_EMAIL_ENCR = nvl(fn_emaps_main(p_email_in),CAM_EMAIL_ENCR)
          WHERE CAM_CUST_CODE=l_cust_code
          AND CAM_INST_CODE=p_inst_code_in
          AND cam_addr_flag = 'P';
      EXCEPTION
          WHEN OTHERS THEN
          p_resp_code_out := '21';
          l_errmsg   := 'Error while updating CMS_ADDR_MAST '||substr(sqlerrm,1,200);
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

END update_alerts;

PROCEDURE  UPDATE_PROFILE (
                     p_inst_code_in            IN       NUMBER,
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
                     p_phy_add_line_one_in     IN       VARCHAR2,
                     p_phy_add_line_two_in     IN       VARCHAR2,
                     p_phy_city_in             IN       VARCHAR2,
                     p_phy_zip_in              IN       VARCHAR2,
                     p_phy_state_in            IN       VARCHAR2,
                     p_phy_country_code_in     IN       VARCHAR2,
                     p_add_line_one_in         IN       VARCHAR2,
                     p_add_line_two_in         IN       VARCHAR2,
                     p_city_in                 IN       VARCHAR2,
                     p_zip_in                  IN       VARCHAR2,
                     p_phonenum_in             IN       VARCHAR2,
                     p_otherphone_in           IN       VARCHAR2,
                     p_state_in                IN       VARCHAR2,
                     p_country_code_in         IN       VARCHAR2,
                     p_email_in                IN       VARCHAR2,
                     p_resp_code_out           OUT      VARCHAR2,
                     p_resp_msg_out            OUT      VARCHAR2,
                     p_optin_flag_out          OUT      VARCHAR2
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
   l_timestamp                  transactionlog.time_stamp%TYPE;
   l_preauth_flag               cms_transaction_mast.ctm_preauth_flag%TYPE;
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
   l_errmsg                     transactionlog.error_msg%TYPE;
   l_appl_code                  cms_appl_pan.cap_appl_code%TYPE;
   l_curr_code                  gen_cntry_mast.gcm_curr_code%TYPE ;
   l_cust_code                  CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
   l_mailing_switch_state_code   cms_addr_mast.cam_state_switch%TYPE ;
   l_phys_switch_state_code      cms_addr_mast.cam_state_switch%TYPE ;
   l_offaddrcount               NUMBER;
   l_cust_id                    CMS_CUST_MAST.CCM_CUST_ID%TYPE;
   l_full_name                  CMS_CUST_MAST.CCM_FIRST_NAME%TYPE;
   l_mailaddr_lineone           cms_addr_mast.cam_add_one%TYPE; 
   l_mailaddr_linetwo           cms_addr_mast.cam_add_two%TYPE; 
   l_mailaddr_city              cms_addr_mast.cam_city_name%TYPE;
   l_mailaddr_zip               cms_addr_mast.cam_pin_code%TYPE;
   l_gprhash_pan                CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
   l_gprencr_pan                CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
   l_avq_status                 VARCHAR2(1);
   l_phy_cntry_code            gen_cntry_mast.gcm_cntry_code%TYPE ;
   l_mail_cntry_code           gen_cntry_mast.gcm_cntry_code%TYPE ;
   L_STATE_CODE                gen_STATE_mast.GSM_STATE_CODE%TYPE ;
   L_MAIL_STATE_CODE           gen_STATE_mast.GSM_STATE_CODE%TYPE ;
   l_encrypt_enable            cms_prod_cattype.cpc_encrypt_enable%type;
   l_PHY_ADD_LINE_ONE          cms_addr_mast.cam_add_one%type;
   l_PHY_ADD_LINE_TWO          cms_addr_mast.cam_add_two%type;
   l_PHY_CITY                  cms_addr_mast.cam_city_name%type;
   l_PHY_ZIP                   cms_addr_mast.cam_pin_code%type;
   l_PHONENUM                  cms_addr_mast.cam_phone_one%type;
   l_OTHERPHONE                cms_addr_mast.cam_mobl_one%type;
   l_EMAIL                     cms_addr_mast.cam_email%type;
   l_ADD_LINE_ONE              cms_addr_mast.cam_add_one%type;
   l_ADD_LINE_TWO              cms_addr_mast.cam_add_two%type;
   l_CITY                      cms_addr_mast.cam_city_name%type;
   l_ZIP                       cms_addr_mast.cam_pin_code%type;
   l_encr_full_name            CMS_AVQ_STATUS.CAS_CUST_NAME%TYPE;
   V_Decr_Cellphn              Cms_Addr_Mast.Cam_Mobl_One%Type;
   V_Cam_Mobl_One              Cms_Addr_Mast.Cam_Mobl_One%Type;
   L_Alert_Lang_Id             Cms_Smsandemail_Alert.Csa_Alert_Lang_Id%Type;
   V_Doptin_Flag                Number;
   v_loadcredit_flag           CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%TYPE;
   v_lowbal_flag               CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%TYPE;
   v_negativebal_flag          CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%TYPE;
   v_highauthamt_flag          CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%TYPE;
   v_dailybal_flag             CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%TYPE;
   V_Insuffund_Flag            Cms_Smsandemail_Alert.Csa_Insuff_Flag%Type;
   V_Incorrectpin_Flag         CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%Type;
   V_Fast50_Flag               Cms_Smsandemail_Alert.Csa_Fast50_Flag%Type;
   v_federal_state_flag        CMS_SMSANDEMAIL_ALERT.CSA_FEDTAX_REFUND_FLAG%Type;
   exp_reject_record           EXCEPTION;
   
   Type CurrentAlert_Collection Is Table Of Varchar2(30);
   CurrentAlert                 CurrentAlert_Collection;
   /****************************************************************
      
  * Modified By                  : Venkatasai
  * Modified Date                : 10-Jan-2019
  * Modified Reason              : VMS-706
  * Build Number                 : VMSGPRHOST_R11_B0001
  * Reviewer                     : Saravanakumar A.
  * Reviewed Date                : 10-Jan-2019
  
      
  * Modified By                  : Baskar Krishnan
  * Modified Date                : 21-Jan-2019
  * Modified Reason              : VMS-760
  * Build Number                 : VMSGPRHOST_R11_B0003
  * Reviewer                     : Saravanakumar A.
  * Reviewed Date                : 21-Jan-2019
  
  * Modified By      :  Ubaidur Rahman.H
  * Modified Date    :  03-Dec-2021
  * Modified Reason  :  VMS-5253 / 5372 - Do not pass sytem generated value from VMS to CCA.
  * Reviewer         :  Saravanakumar
  * Build Number     :  VMSGPRHOST_R55_RELEASE
  
  *****************************************************************/
   
BEGIN
   BEGIN

    p_resp_msg_out := 'success';
    p_optin_flag_out :='N';
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

      begin
            select cpc_encrypt_enable
            into l_encrypt_enable
            from cms_prod_cattype
            where cpc_inst_code=p_inst_code_in
            and cpc_prod_code=l_prod_code
            and cpc_card_type=l_prod_cattype;
      exception
          when others then
              l_errmsg :=
                  'Error while selecting prod cattype'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      end;
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
                  'ERROR FROM authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

     IF P_PHY_COUNTRY_CODE_IN IS NOT NULL THEN
      BEGIN
                SELECT GCM_CURR_CODE,GCM_CNTRY_CODE
                INTO l_curr_code,l_phy_cntry_code
                FROM GEN_CNTRY_MAST
                WHERE GCM_ALPHA_CNTRY_CODE = P_PHY_COUNTRY_CODE_IN
                AND GCM_INST_CODE = p_inst_code_in;
      EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
             p_resp_code_out := '168';
             l_errmsg  := 'Invalid Data for Country Code' || P_PHY_COUNTRY_CODE_IN;
             RAISE  exp_reject_record;
       WHEN OTHERS THEN
        p_resp_code_out := '21';
         l_errmsg := 'Error while selecting currency code ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
      END;

        IF P_PHY_STATE_IN IS NOT NULL THEN

           BEGIN
               SELECT GSM_SWITCH_STATE_CODE,GSM_STATE_CODE
               INTO l_phys_switch_state_code,L_STATE_CODE
               FROM  GEN_STATE_MAST
               WHERE  GSM_SWITCH_STATE_CODE = P_PHY_STATE_IN
               AND GSM_ALPHA_CNTRY_CODE = P_PHY_COUNTRY_CODE_IN
               AND GSM_INST_CODE = p_inst_code_in;
            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                p_resp_code_out := '167';
                 l_errmsg := 'Invalid Data for Physical Address State' || P_PHY_STATE_IN;
                 RAISE exp_reject_record;
            WHEN OTHERS THEN
             p_resp_code_out := '21';
             l_errmsg := 'Error while selecting switch state code ' || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
          END;
         END IF;
      END IF;



      BEGIN
        INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
             VALUES (p_rrn_in, p_delivery_chnl_in, p_txn_code_in, l_cust_code,1);
        EXCEPTION
          WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
       END;
     if l_encrypt_enable='Y' then
         l_PHY_ADD_LINE_ONE:=fn_emaps_main(P_PHY_ADD_LINE_ONE_IN);
         l_PHY_ADD_LINE_TWO:=fn_emaps_main(P_PHY_ADD_LINE_TWO_IN);
         l_PHY_CITY:=fn_emaps_main(P_PHY_CITY_IN);
         l_PHY_ZIP:=fn_emaps_main(P_PHY_ZIP_IN);
         l_PHONENUM:=fn_emaps_main(P_PHONENUM_IN);
         l_OTHERPHONE:=fn_emaps_main(P_OTHERPHONE_IN);
         l_EMAIL:=fn_emaps_main(P_EMAIL_IN);
     else
          l_PHY_ADD_LINE_ONE:=P_PHY_ADD_LINE_ONE_IN;
          l_PHY_ADD_LINE_TWO:=P_PHY_ADD_LINE_TWO_IN;
          l_PHY_CITY:=P_PHY_CITY_IN;
          l_PHY_ZIP:=P_PHY_ZIP_IN;
          l_PHONENUM:=P_PHONENUM_IN;
          l_OTHERPHONE:=P_OTHERPHONE_IN;
          l_EMAIL:=P_EMAIL_IN;
     end if;

   IF l_PHY_ADD_LINE_ONE is not null and  l_PHY_CITY is not null and l_PHY_ZIP is not null and L_STATE_CODE is not null
     and l_phy_cntry_code is not null then
      BEGIN
           UPDATE CMS_ADDR_MAST
          SET CAM_ADD_ONE    = l_PHY_ADD_LINE_ONE,
         CAM_ADD_TWO    = l_PHY_ADD_LINE_TWO,   -- removed NVL check for nonmanditory Address field 2
         CAM_CITY_NAME  = l_PHY_CITY,
         CAM_PIN_CODE   = l_PHY_ZIP,
         CAM_STATE_CODE = L_STATE_CODE,
         CAM_CNTRY_CODE = l_phy_cntry_code,
         cam_state_switch = l_phys_switch_state_code,
		 CAM_ADD_ONE_ENCR = fn_emaps_main(P_PHY_ADD_LINE_ONE_IN),
		 CAM_ADD_TWO_ENCR = fn_emaps_main(P_PHY_ADD_LINE_TWO_IN),
		 CAM_CITY_NAME_ENCR = fn_emaps_main(P_PHY_CITY_IN),
		 CAM_PIN_CODE_ENCR = fn_emaps_main(P_PHY_ZIP_IN)
         WHERE CAM_INST_CODE = p_inst_code_in
         AND CAM_CUST_CODE = l_cust_code
         AND CAM_ADDR_FLAG = 'P';


         IF SQL%ROWCOUNT = 0 THEN
           p_resp_code_out := '21';
           l_errmsg := 'ERROR WHILE UPDATING CMS_ADDR_MAST ';
           RAISE exp_reject_record;
         END IF;
		 
		 --- Added for VMS-5253 / VMS-5372
		 
		 BEGIN 
			 
			 UPDATE CMS_CUST_MAST 
			 	SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
				WHERE CCM_INST_CODE = 1
				AND CCM_CUST_CODE = l_cust_code;

			 EXCEPTION
					WHEN OTHERS THEN
					 p_resp_code_out := '21';
					 l_errmsg   := 'ERROR WHILE UPDATING CCM_SYSTEM_GENERATED_PROFILE -PHYSICAL CONTACT INFORMATION  ' ||SUBSTR(SQLERRM, 1, 300);
					 RAISE;
			 END;
		 

         EXCEPTION
           WHEN exp_reject_record THEN
            RAISE exp_reject_record;
           WHEN OTHERS THEN
             p_resp_code_out := '21';
             l_errmsg := 'Problem on updated CMS_ADDR_MAST ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
    end if;

    begin
           Select Csa_Alert_Lang_Id,Csa_Loadorcredit_Flag,Csa_Lowbal_Flag,Csa_Negbal_Flag,Csa_Highauthamt_Flag,Csa_Dailybal_Flag,Csa_Insuff_Flag, Csa_Fedtax_Refund_Flag, Csa_Fast50_Flag,Csa_Incorrpin_Flag
          Into L_Alert_Lang_Id,V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag
          From Cms_Smsandemail_Alert Where Csa_Pan_Code= gethash (p_pan_code_in)   and CSA_INST_CODE=p_inst_code_in;

        Currentalert := Currentalert_Collection(V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag);

        select count(1) into v_doptin_flag from CMS_PRODCATG_SMSEMAIL_ALERTS
          WHERE nvl(dbms_lob.substr( cps_alert_msg,1,1),0) <>0
          And Cps_Prod_Code = l_Prod_Code
          AND CPS_CARD_TYPE = l_prod_cattype
          And Cps_Inst_Code= p_inst_code_in
          And Cps_Alert_Id=33
          And Cps_Alert_Lang_Id = l_alert_lang_id;

            
         If(v_doptin_flag = 1 and P_Optin_Flag_Out = 'N' And ('1' Member Of Currentalert Or '3' Member Of Currentalert))
        Then
             Select Cam_Mobl_One Into V_Cam_Mobl_One From Cms_Addr_Mast
             Where Cam_Cust_Code=l_cust_code And Cam_Addr_Flag='P' And Cam_Inst_Code=p_inst_code_in;
            If(l_encrypt_enable = 'Y') Then
                V_Decr_Cellphn :=Fn_Dmaps_Main(V_Cam_Mobl_One);
                Else
                V_Decr_Cellphn := V_Cam_Mobl_One;
              End If;

             If(V_Decr_Cellphn <> l_OTHERPHONE)
             Then
              p_optin_flag_out :='Y';
              End If;
        End If;
       
        EXCEPTION
         WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg := 'Error while selecting optin flag ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;

   --if l_PHONENUM is not null or l_OTHERPHONE is not null then --clearing telephone number if not coming from payload
      begin
       UPDATE CMS_ADDR_MAST
       set  CAM_PHONE_ONE  = l_PHONENUM, --removed NVL check
         CAM_MOBL_ONE   = NVL(l_OTHERPHONE,CAM_MOBL_ONE)
          WHERE CAM_INST_CODE = p_inst_code_in
         AND CAM_CUST_CODE = l_cust_code
         AND CAM_ADDR_FLAG = 'P';
         IF SQL%ROWCOUNT = 0 THEN
         p_resp_code_out := '21';
         l_errmsg := 'ERROR WHILE UPDATING CMS_ADDR_MAST PHONE DETAILS ';
         RAISE exp_reject_record;
         END IF;

        EXCEPTION
         WHEN exp_reject_record THEN
         RAISE exp_reject_record;
         WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg := 'Problem on updated CMS_ADDR_MAST phone details ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
    --  end if;

      if l_EMAIL is not null then
      begin
       UPDATE CMS_ADDR_MAST
       set CAM_EMAIL      = l_EMAIL,
			CAM_EMAIL_ENCR = fn_emaps_main(P_EMAIL_IN)
        WHERE CAM_INST_CODE = p_inst_code_in
         AND CAM_CUST_CODE = l_cust_code
         AND CAM_ADDR_FLAG = 'P';
         IF SQL%ROWCOUNT = 0 THEN
         p_resp_code_out := '21';
         l_errmsg := 'ERROR WHILE UPDATING CMS_ADDR_MAST EMAIL';
         RAISE exp_reject_record;
         END IF;
         EXCEPTION
         WHEN exp_reject_record THEN
         RAISE exp_reject_record;
         WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg := 'Problem on updated CMS_ADDR_MAST  email' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      end if;

      IF P_COUNTRY_CODE_IN IS NOT NULL THEN
            BEGIN

                SELECT GCM_CURR_CODE,GCM_CNTRY_CODE
                INTO l_curr_code,l_mail_cntry_code
                FROM GEN_CNTRY_MAST
                WHERE GCM_ALPHA_CNTRY_CODE = P_COUNTRY_CODE_IN
                AND GCM_INST_CODE = p_inst_code_in;

               EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
               p_resp_code_out := '6';
               l_errmsg := 'Invalid Data for Mailing Address Country Code' || P_COUNTRY_CODE_IN;
               RAISE  exp_reject_record;
               WHEN OTHERS THEN
                p_resp_code_out := '21';
                l_errmsg := 'Error while selecting mailing country code ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
             END;

         IF  P_STATE_IN IS NOT NULL THEN

            BEGIN

              SELECT GSM_SWITCH_STATE_CODE,GSM_STATE_CODE
              INTO l_mailing_switch_state_code,L_MAIL_STATE_CODE
              FROM  GEN_STATE_MAST
              WHERE  GSM_SWITCH_STATE_CODE = P_STATE_IN
              AND GSM_ALPHA_CNTRY_CODE = P_COUNTRY_CODE_IN
              AND GSM_INST_CODE = p_inst_code_in;

            EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
              p_resp_code_out := '169';
              l_errmsg := 'Invalid Data for Mailing Address State' || P_STATE_IN;
              RAISE exp_reject_record;
              WHEN OTHERS THEN
              p_resp_code_out := '21';
              l_errmsg := 'Error while selecting mailing switch state code ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
            END;
         END IF;
      END IF;


     BEGIN
       SELECT COUNT(*)
        INTO L_OFFADDRCOUNT
        FROM CMS_ADDR_MAST
        WHERE CAM_INST_CODE = p_inst_code_in AND CAM_CUST_CODE = l_cust_code AND
           CAM_ADDR_FLAG = 'O';

       EXCEPTION
         WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg := 'Error while selecting mailing address count ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
      END;

	if l_encrypt_enable='Y' then
         l_ADD_LINE_ONE:=fn_emaps_main(P_ADD_LINE_ONE_IN);
         l_ADD_LINE_TWO:=fn_emaps_main(P_ADD_LINE_TWO_IN);
         l_CITY:=fn_emaps_main(P_CITY_IN);
         l_ZIP:=fn_emaps_main(P_ZIP_IN);
     else
          l_ADD_LINE_ONE:=P_ADD_LINE_ONE_IN;
          l_ADD_LINE_TWO:=P_ADD_LINE_TWO_IN;
          l_CITY:=P_CITY_IN;
          l_ZIP:=P_ZIP_IN;
     end if;

     if l_offaddrcount > 0 then
        IF P_ADD_LINE_ONE_IN IS NOT NULL AND P_COUNTRY_CODE_IN IS NOT NULL AND P_CITY_IN IS NOT NULL  THEN   -- check whether addess details come or not 
       BEGIN
              UPDATE cms_addr_mast
               SET cam_add_one = l_ADD_LINE_ONE, 
                   cam_add_two = l_ADD_LINE_TWO, -- removed NVL check for nonmanditory Address field 2
                   cam_city_name = l_CITY,
                   cam_pin_code = NVL(l_ZIP,cam_pin_code),
                   cam_phone_one = l_PHONENUM,--removed NVL check
                   cam_mobl_one = NVL (l_OTHERPHONE, cam_mobl_one),--Keeping existing value if mobile number received as null
                   cam_state_code = NVL(L_MAIL_STATE_CODE,cam_state_code),
                   cam_cntry_code = NVL(l_mail_cntry_code,cam_cntry_code),
                   cam_state_switch = NVL(l_mailing_switch_state_code,cam_state_switch),
                   CAM_ADD_ONE_ENCR = fn_emaps_main(P_ADD_LINE_ONE_IN),
                   CAM_ADD_TWO_ENCR = fn_emaps_main(P_ADD_LINE_TWO_IN),
                   CAM_CITY_NAME_ENCR = fn_emaps_main(P_CITY_IN),
                   CAM_PIN_CODE_ENCR = NVL(fn_emaps_main(P_ZIP_IN),CAM_PIN_CODE_ENCR)
              WHERE cam_inst_code = p_inst_code_in
                AND cam_cust_code = l_cust_code
                AND cam_addr_flag = 'O';
           EXCEPTION
            WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg   := 'ERROR IN  UPDATE MAIL CONTACT INFORMATION ' ||SUBSTR(SQLERRM, 1, 300);
            RAISE exp_reject_record;
        end;
        
        
        	 	--- Added for VMS-5253 / VMS-5372
	 BEGIN 
			 
	 	UPDATE CMS_CUST_MAST 
                SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
                WHERE CCM_INST_CODE = 1
                AND CCM_CUST_CODE = l_cust_code;

	 EXCEPTION
	 	WHEN OTHERS THEN
		p_resp_code_out := '21';
		l_errmsg   := 'ERROR WHILE UPDATING CCM_SYSTEM_GENERATED_PROFILE -MAILING CONTACT INFORMATION - 1  ' ||SUBSTR(SQLERRM, 1, 300);
		RAISE exp_reject_record;
	 END;
        
      end if;
      ELSE

        IF P_ADD_LINE_ONE_IN IS NOT NULL AND P_COUNTRY_CODE_IN IS NOT NULL AND P_CITY_IN IS NOT NULL  THEN

            BEGIN
                   INSERT INTO CMS_ADDR_MAST
                    (CAM_INST_CODE,
                     CAM_CUST_CODE,
                     CAM_ADDR_CODE,
                     CAM_ADD_ONE,
                     CAM_ADD_TWO,
                     CAM_PIN_CODE,
                     CAM_PHONE_ONE,
                     CAM_MOBL_ONE,
                     CAM_CNTRY_CODE,
                     CAM_CITY_NAME,
                     CAM_ADDR_FLAG,
                     CAM_STATE_CODE,
                     CAM_COMM_TYPE,
                     CAM_INS_USER,
                     CAM_INS_DATE,
                     CAM_LUPD_USER,
                     CAM_LUPD_DATE,
                     cam_state_switch,
					 CAM_ADD_ONE_ENCR,
					 CAM_ADD_TWO_ENCR,
					 CAM_CITY_NAME_ENCR,
					 CAM_PIN_CODE_ENCR
					 )
                   VALUES
                    (p_inst_code_in,
                     l_cust_code,
                     SEQ_ADDR_CODE.NEXTVAL,
                     l_ADD_LINE_ONE,
                     l_ADD_LINE_TWO,
                     l_ZIP,
                     l_PHONENUM,
                     l_OTHERPHONE,
                     l_mail_cntry_code,--P_COUNTRY_CODE_IN,
                     l_CITY,
                     'O',
                     L_MAIL_STATE_CODE,--P_STATE_IN,
                     'R',
                     1,
                     SYSDATE,
                     1,
                     SYSDATE,
                     l_mailing_switch_state_code,
					 fn_emaps_main(P_ADD_LINE_ONE_IN),
					 fn_emaps_main(P_ADD_LINE_TWO_IN),
					 fn_emaps_main(P_CITY_IN),
					 fn_emaps_main(P_ZIP_IN)
					 );
                EXCEPTION
                WHEN OTHERS THEN
                 p_resp_code_out := '21';
                 l_errmsg   := 'ERROR IN  INSERTING PHYSICAL CONTACT INFORMATION ' ||SUBSTR(SQLERRM, 1, 300);
                 RAISE exp_reject_record;
              END;

         else

          BEGIN
                   INSERT INTO CMS_ADDR_MAST
                    (CAM_INST_CODE,
                     CAM_CUST_CODE,
                     CAM_ADDR_CODE,
                     CAM_ADD_ONE,
                     CAM_ADD_TWO,
                     CAM_PIN_CODE,
                     CAM_PHONE_ONE,
                     CAM_MOBL_ONE,
                     CAM_CNTRY_CODE,
                     CAM_CITY_NAME,
                     CAM_ADDR_FLAG,
                     CAM_STATE_CODE,
                     CAM_COMM_TYPE,
                     CAM_INS_USER,
                     CAM_INS_DATE,
                     CAM_LUPD_USER,
                     CAM_LUPD_DATE,
                     cam_state_switch,
					 CAM_ADD_ONE_ENCR,
					 CAM_ADD_TWO_ENCR,
					 CAM_CITY_NAME_ENCR,
					 CAM_PIN_CODE_ENCR)
                   VALUES
                    (p_inst_code_in,
                     l_cust_code,
                     SEQ_ADDR_CODE.NEXTVAL,
                     l_PHY_ADD_LINE_ONE,
                     l_PHY_ADD_LINE_TWO,
                     l_PHY_ZIP,
                     l_PHONENUM,
                     l_OTHERPHONE,
                     l_phy_cntry_code,--P_PHY_COUNTRY_CODE_IN,
                     l_PHY_CITY,
                     'O',
                     L_STATE_CODE,--P_PHY_STATE_IN,
                     'O',
                     1,
                     SYSDATE,
                     1,
                     SYSDATE,
                     l_phys_switch_state_code,
					 fn_emaps_main(P_PHY_ADD_LINE_ONE_IN),
					 fn_emaps_main(P_PHY_ADD_LINE_TWO_IN),
					 fn_emaps_main(P_PHY_CITY_IN),
					 fn_emaps_main(P_PHY_ZIP_IN));
                EXCEPTION
                WHEN OTHERS THEN
                 p_resp_code_out := '21';
                 l_errmsg   := 'ERROR IN  INSERTING MAILING CONTACT INFORMATION ' ||SUBSTR(SQLERRM, 1, 300);
                 RAISE exp_reject_record;
              END;

         END IF;
		 
		 	--- Added for VMS-5253 / VMS-5372
	 BEGIN 
			 
	 	UPDATE CMS_CUST_MAST 
                SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
                WHERE CCM_INST_CODE = 1
                AND CCM_CUST_CODE = l_cust_code;

	 EXCEPTION
	 	WHEN OTHERS THEN
		p_resp_code_out := '21';
		l_errmsg   := 'ERROR WHILE UPDATING CCM_SYSTEM_GENERATED_PROFILE -MAILING CONTACT INFORMATION - 2 ' ||SUBSTR(SQLERRM, 1, 300);
		RAISE exp_reject_record;
	 END;
		 
		 
    END IF;

     BEGIN

          SELECT cust.ccm_cust_id,
          decode(cat.cpc_encrypt_enable,'Y',fn_dmaps_main(cust.ccm_first_name),cust.ccm_first_name)
          ||' '||decode(cat.cpc_encrypt_enable,'Y',fn_dmaps_main(cust.ccm_last_name),cust.ccm_last_name),
           addr.cam_add_one, addr.cam_add_two, addr.cam_city_name,
           addr.cam_state_switch, addr.cam_pin_code
           INTO L_CUST_ID,L_FULL_NAME,L_MAILADDR_LINEONE,L_MAILADDR_LINETWO,
           L_MAILADDR_CITY,l_mailing_switch_state_code,L_MAILADDR_ZIP
           FROM CMS_CUST_MAST cust,cms_addr_mast addr,cms_prod_cattype cat
           WHERE addr.cam_inst_code = cust.ccm_inst_code
           and cust.ccm_inst_code=cat.cpc_inst_code
           and cust.ccm_prod_code=cat.cpc_prod_code
           and cust.ccm_card_type=cat.cpc_card_type
           AND addr.cam_cust_code = cust.ccm_cust_code
           AND cust.CCM_INST_CODE = p_inst_code_in
           AND cust.CCM_CUST_CODE = l_cust_code
           and addr.cam_addr_flag='O';

       EXCEPTION
         WHEN NO_DATA_FOUND THEN
         p_resp_code_out := '21';
         l_errmsg := 'Mailing Addess Not Found';
          RAISE exp_reject_record;
         WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg := 'Error while selecting mailing address ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;

      END;

      BEGIN

          SELECT COUNT(1) INTO l_avq_status
          FROM CMS_AVQ_STATUS
          WHERE CAS_INST_CODE=p_inst_code_in AND CAS_CUST_ID=L_CUST_ID AND CAS_AVQ_FLAG='P';

            IF l_avq_status = 1 THEN
                                -- removed all NVL check 
                UPDATE CMS_AVQ_STATUS
                      SET CAS_ADDR_ONE=L_MAILADDR_LINEONE,
                          CAS_ADDR_TWO=L_MAILADDR_LINETWO,
                          CAS_CITY_NAME =L_MAILADDR_CITY,
                          CAS_STATE_NAME=l_mailing_switch_state_code,
                          cas_postal_code =l_mailaddr_zip,
                          CAS_LUPD_USER=1,
                          CAS_LUPD_DATE=sysdate
                WHERE CAS_INST_CODE=p_inst_code_in AND CAS_CUST_ID=L_CUST_ID AND CAS_AVQ_FLAG='P';

            else

                BEGIN
                  SELECT COUNT(1) INTO l_avq_status
                  FROM CMS_AVQ_STATUS
                  WHERE CAS_INST_CODE=p_inst_code_in AND CAS_CUST_ID=L_CUST_ID AND CAS_AVQ_FLAG='F';

                  IF l_avq_status <> 0 THEN

                      BEGIN
                         SELECT pan.cap_pan_code ,pan.cap_pan_code_encr
                           INTO l_gprhash_pan ,l_gprencr_pan
                           FROM cms_appl_pan pan , cms_cardissuance_status issustat
                          WHERE pan.cap_appl_code = issustat.ccs_appl_code
                            AND pan.cap_pan_code = issustat.ccs_pan_code
                            AND pan.cap_inst_code = issustat.ccs_inst_code
                            AND pan.cap_inst_code = p_inst_code_in
                            AND issustat.ccs_card_status='17'
                            and pan.cap_card_stat <> '9'
                            AND pan.cap_cust_code =l_cust_code
                            AND pan.cap_startercard_flag = 'N';
                      EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        NULL;
                         WHEN OTHERS
                         THEN
                            p_resp_code_out := '21';
                            l_errmsg := 'Error while selecting (gpr card)details from appl_pan :'
                               || SUBSTR (SQLERRM, 1, 200);
                            RAISE exp_reject_record;
                      end;

					  IF l_encrypt_enable = 'Y' THEN
                         l_encr_full_name := fn_emaps_main(L_FULL_NAME);
					  ELSE
					      l_encr_full_name := L_FULL_NAME;
					  END IF;


             IF(l_gprhash_pan IS NOT NULL) THEN
                      INSERT INTO CMS_AVQ_STATUS
                      (CAS_INST_CODE,
                       CAS_AVQSTAT_ID,
                       CAS_CUST_ID,
                       CAS_PAN_CODE,
                       CAS_PAN_ENCR,
                       CAS_CUST_NAME,
                       CAS_ADDR_ONE,
                       CAS_ADDR_TWO,
                       CAS_CITY_NAME,
                       CAS_STATE_NAME,
                       CAS_POSTAL_CODE,
                       CAS_AVQ_FLAG,
                       CAS_INS_USER,
                       CAS_INS_DATE)
                      VALUES
                      (p_inst_code_in,
                       AVQ_SEQ.NEXTVAL,
                       L_CUST_ID,
                       l_gprhash_pan,
                       l_gprencr_pan,
                       l_encr_full_name,
                       L_MAILADDR_LINEONE,
                       L_MAILADDR_LINETWO,
                       L_MAILADDR_CITY,
                       l_mailing_switch_state_code,
                       L_MAILADDR_ZIP,
                       'P',
                       1,
                       SYSDATE);
                  END IF;
                  END IF;
                 EXCEPTION
         when exp_reject_record then
                 raise;
                  WHEN OTHERS THEN
                   p_resp_code_out := '21';
                   l_errmsg := 'Exception while Inserting in CMS_AVQ_STATUS Table ' ||
                             SUBSTR(SQLERRM, 1, 200);
                   RAISE exp_reject_record;
              END;

            END IF;
          EXCEPTION
             WHEN exp_reject_record THEN
              RAISE;
             WHEN OTHERS THEN
               p_resp_code_out := '21';
               l_errmsg := 'Error while updating mailing address(AVQ) ' || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
      END;

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
            l_errmsg := 'Invalid Card number ' ;
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

END UPDATE_PROFILE;

PROCEDURE optIn_Settings(p_inst_code_in            IN     NUMBER,
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
                          p_pan_code_in             IN     VARCHAR2,
                          p_action_in               IN     VARCHAR2,
                          p_optin_array_in          IN     VARCHAR2,
                          p_resp_code_out           OUT    VARCHAR2,
                          p_respmsg_out             OUT    VARCHAR2,
                          p_saving_acct_info_out    OUT    VARCHAR2,
                          p_tandc_version_out       OUT    VARCHAR2,
                          p_tandc_flag_out          OUT    VARCHAR2
                          )
   IS
      l_hash_pan                 cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                 cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no                  cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal                 cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal               cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code                cms_appl_pan.cap_prod_code%TYPE;
      l_prod_cattype             cms_appl_pan.cap_card_type%TYPE;
      l_card_stat                cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date               cms_appl_pan.cap_expry_date%TYPE;
      l_active_date              cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code                cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag               cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type                 cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag                cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_dup_rrn_check            cms_transaction_mast.ctm_rrn_check%TYPE;
      l_comb_hash                pkg_limits_check.type_hash;
      l_auth_id                  cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp                transactionlog.time_stamp%TYPE;
      l_preauth_flag             cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_type                cms_acct_mast.cam_type_code%TYPE;
      l_login_txn                cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code                 cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan                 cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type           transactionlog.feeattachtype%TYPE;
      l_tranfee_amt              transactionlog.tranfee_amt%TYPE;
      l_total_amt                cms_acct_mast.cam_acct_bal%TYPE;
      l_preauth_type             cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id               cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber              cms_appl_pan.cap_proxy_number%TYPE;
      l_repl_flag                cms_appl_pan.cap_repl_flag%TYPE;
      l_tandc_version            cms_prod_cattype.cpc_tandc_version%TYPE;
      l_ccm_tandc_version        cms_cust_mast.ccm_tandc_version%TYPE;
      l_cust_code                cms_cust_mast.ccm_cust_code%TYPE;
      l_savings_statcode         cms_acct_mast.cam_stat_code%TYPE;
      l_min_tran_amt             cms_dfg_param.cdp_param_value%TYPE;
      l_sms_optinflag            cms_optin_status.cos_sms_optinflag%TYPE;
      l_email_optinflag          cms_optin_status.cos_email_optinflag%TYPE;
      l_markmsg_optinflag        cms_optin_status.cos_markmsg_optinflag%TYPE;
      l_gpresign_optinflag       cms_optin_status.cos_gpresign_optinflag%TYPE;
      l_savingsesign_optinflag   cms_optin_status.cos_savingsesign_optinflag%TYPE;
      l_cust_id                  cms_cust_mast.ccm_cust_id%TYPE;
      l_saving_acct_dtl          cms_acct_mast.cam_acct_no%TYPE;
      l_optin_type               VARCHAR2(200);
      l_optin                    VARCHAR2(200);
      l_comma_pos                NUMBER;
      l_comma_pos1               NUMBER;
      l_count                    NUMBER;
      l_optin_array              VARCHAR2(2000);
      l_errmsg                   transactionlog.error_msg%TYPE;
      i                          NUMBER:=1;
      exp_reject_record          EXCEPTION;
   BEGIN
      BEGIN
         p_resp_code_out := '00';
         p_respmsg_out := 'success';

         --Sn pan details procedure call
         BEGIN
            SELECT pan.cap_pan_code,
                   pan.cap_pan_code_encr,
                   pan.cap_acct_no,
                   pan.cap_card_stat,
                   pan.cap_prod_code,
                   pan.cap_card_type,
                   pan.cap_expry_date,
                   pan.cap_active_date,
                   pan.cap_prfl_code,
                   pan.cap_proxy_number,
                   pan.cap_repl_flag,
                   cust.ccm_tandc_version,
                   cust.ccm_cust_code,
                   cust.ccm_cust_id
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
                   l_repl_flag,
                   l_ccm_tandc_version,
                   l_cust_code,
                   l_cust_id
              FROM cms_appl_pan pan,cms_cust_mast cust
             WHERE pan.cap_inst_code = p_inst_code_in
               AND pan.cap_inst_code = cust.ccm_inst_code
               AND pan.cap_cust_code = cust.ccm_cust_code
               AND pan.cap_pan_code = gethash (p_pan_code_in)
               AND pan.cap_mbr_numb = '000';
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
    --EN:



    -- Sn -- Modified for  Modified for consolidated FSAPI requirement
          BEGIN

              loop

                  l_comma_pos:= instr(p_optin_array_in,',',1,i);

                  if i=1 and l_comma_pos=0 then
                      l_optin_array:=p_optin_array_in;
                  elsif i<>1 and l_comma_pos=0 then
                      l_comma_pos1:= instr(p_optin_array_in,',',1,i-1);
                      l_optin_array:=substr(p_optin_array_in,l_comma_pos1+1);
                  elsif i<>1 and l_comma_pos<>0 then
                      l_comma_pos1:= instr(p_optin_array_in,',',1,i-1);
                      l_optin_array:=substr(p_optin_array_in,l_comma_pos1+1,l_comma_pos-l_comma_pos1-1);
                  elsif i=1 and l_comma_pos<>0 then
                      l_optin_array:=substr(p_optin_array_in,1,l_comma_pos-1);
                  end if;

                  i:=i+1;

                  l_optin_type:=substr(l_optin_array,1,instr(l_optin_array,':',1,1)-1);
                  l_optin:=substr(l_optin_array,instr(l_optin_array,':',1,1)+1);

                  BEGIN
                      IF l_optin_type IS NOT NULL AND l_optin_type = '1'
                      THEN
                          l_sms_optinflag := l_optin;
                      ELSIF l_optin_type IS NOT NULL AND l_optin_type = '2'
                      THEN
                          l_email_optinflag := l_optin;
                      ELSIF l_optin_type IS NOT NULL AND l_optin_type = '3'
                      THEN
                          l_markmsg_optinflag := l_optin;
                      ELSIF l_optin_type IS NOT NULL AND l_optin_type = '4'
                      THEN
                          l_gpresign_optinflag := l_optin;

                          IF l_gpresign_optinflag = '1' THEN
                              BEGIN

                                  UPDATE cms_cust_mast
                                  set ccm_tandc_version=l_tandc_version
                                  WHERE ccm_cust_id=l_cust_id;

                                  IF  SQL%ROWCOUNT =0 THEN
                                      p_resp_code_out := '21';
                                      l_errmsg :=
                                      'Error while updating t and c version '|| SUBSTR (SQLERRM, 1, 200);
                                       RAISE exp_reject_record;
                                  END IF;
                              EXCEPTION
                                  WHEN exp_reject_record THEN
                                      RAISE ;
                                  WHEN others THEN
                                      p_resp_code_out := '21';
                                      l_errmsg :=
                                      'Error while updating t and c version '
                                      || SUBSTR (SQLERRM, 1, 200);
                                      RAISE exp_reject_record;
                              END;

                          END IF;
                      ELSIF l_optin_type IS NOT NULL AND l_optin_type = '5'
                      THEN
                          l_savingsesign_optinflag := l_optin;
                      END IF;
                  EXCEPTION
                      WHEN others THEN
                          p_resp_code_out := '21';
                          l_errmsg :=
                          'Error while checking optin type'
                          || SUBSTR (SQLERRM, 1, 200);
                          RAISE exp_reject_record;
                  END;

                  BEGIN
                      SELECT COUNT (*)
                      INTO l_count
                      FROM cms_optin_status
                      WHERE cos_inst_code = p_inst_code_in AND cos_cust_id = l_cust_id;

                      IF l_count > 0
                      THEN
                          UPDATE cms_optin_status
                          SET cos_sms_optinflag =  NVL (l_sms_optinflag, cos_sms_optinflag),
                          cos_sms_optintime =  NVL (DECODE (l_sms_optinflag, '1', SYSTIMESTAMP, NULL),cos_sms_optintime ),
                          cos_sms_optouttime = NVL (DECODE (l_sms_optinflag, '0', SYSTIMESTAMP, NULL), cos_sms_optouttime),
                          cos_email_optinflag = NVL (l_email_optinflag, cos_email_optinflag),
                          cos_email_optintime = NVL (DECODE (l_email_optinflag,'1', SYSTIMESTAMP,NULL),cos_email_optintime),
                          cos_email_optouttime = NVL (DECODE (l_email_optinflag,'0', SYSTIMESTAMP, NULL),cos_email_optouttime),
                          cos_markmsg_optinflag =NVL (l_markmsg_optinflag, cos_markmsg_optinflag),
                          cos_markmsg_optintime = NVL (DECODE (l_markmsg_optinflag,'1', SYSTIMESTAMP,NULL),cos_markmsg_optintime),
                          cos_markmsg_optouttime =NVL (DECODE (l_markmsg_optinflag,'0', SYSTIMESTAMP, NULL), cos_markmsg_optouttime),
                          cos_gpresign_optinflag =NVL (l_gpresign_optinflag, cos_gpresign_optinflag),
                          cos_gpresign_optintime = NVL (DECODE (l_gpresign_optinflag,'1', SYSTIMESTAMP, NULL),cos_gpresign_optintime),
                          cos_gpresign_optouttime = NVL (DECODE (l_gpresign_optinflag,'0', SYSTIMESTAMP, NULL), cos_gpresign_optouttime ),
                          cos_savingsesign_optinflag = NVL (l_savingsesign_optinflag,cos_savingsesign_optinflag),
                          cos_savingsesign_optintime =NVL (DECODE (l_savingsesign_optinflag,'1', SYSTIMESTAMP, NULL), cos_savingsesign_optintime),
                          cos_savingsesign_optouttime =NVL (DECODE (l_savingsesign_optinflag,'0', SYSTIMESTAMP, NULL ),cos_savingsesign_optouttime)
                          WHERE cos_inst_code = p_inst_code_in AND cos_cust_id = l_cust_id;
                      ELSE
                          INSERT INTO cms_optin_status
                                            (cos_inst_code, cos_cust_id, cos_sms_optinflag,
                                            cos_sms_optintime,
                                            cos_sms_optouttime,
                                            cos_email_optinflag,
                                            cos_email_optintime,
                                            cos_email_optouttime,
                                            cos_markmsg_optinflag,
                                            cos_markmsg_optintime,
                                            cos_markmsg_optouttime,
                                            cos_gpresign_optinflag,
                                            cos_gpresign_optintime,
                                            cos_gpresign_optouttime,
                                            cos_savingsesign_optinflag,
                                            cos_savingsesign_optintime,
                                            cos_savingsesign_optouttime
                                            )
                                          VALUES (p_inst_code_in, l_cust_id, l_sms_optinflag,
                                          DECODE (l_sms_optinflag, '1', SYSTIMESTAMP, NULL),
                                          DECODE (l_sms_optinflag, '0', SYSTIMESTAMP, NULL),
                                          l_email_optinflag,
                                          DECODE (l_email_optinflag, '1', SYSTIMESTAMP, NULL),
                                          DECODE (l_email_optinflag, '0', SYSTIMESTAMP, NULL),
                                          l_markmsg_optinflag,
                                          DECODE (l_markmsg_optinflag, '1', SYSTIMESTAMP, NULL),
                                          DECODE (l_markmsg_optinflag,'0', SYSTIMESTAMP, NULL),
                                          l_gpresign_optinflag,
                                          DECODE (l_gpresign_optinflag,'1', SYSTIMESTAMP,NULL ),
                                          DECODE (l_gpresign_optinflag,'0', SYSTIMESTAMP, NULL),
                                          l_savingsesign_optinflag,
                                          DECODE (l_savingsesign_optinflag,'1', SYSTIMESTAMP, NULL),
                                          DECODE (l_savingsesign_optinflag,'0', SYSTIMESTAMP, NULL) );
                      END IF;
                  EXCEPTION
                  WHEN OTHERS
                  THEN
                      p_resp_code_out := '21';
                      l_errmsg :=
                      'ERROR IN INSERTING RECORDS IN CMS_OPTIN_STATUS'
                      || SUBSTR (SQLERRM, 1, 300);
                      RAISE exp_reject_record;
                  END;

                  exit when l_comma_pos=0 ;
              END LOOP;

          EXCEPTION
              WHEN OTHERS
              THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                  'ERROR IN loop'
                  || SUBSTR (SQLERRM, 1, 300);
                  RAISE exp_reject_record;
          END;

  -- En -- Modified for consolidated FSAPI


          BEGIN
              SELECT CPC_TANDC_VERSION
              INTO l_tandc_version
              FROM CMS_PROD_CATTYPE
              WHERE CPC_PROD_CODE=l_prod_code
              AND CPC_CARD_TYPE= l_prod_cattype
              AND CPC_INST_CODE=p_inst_code_in;
          EXCEPTION
              WHEN others THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                  'Error from  featching the t and c version '
                  || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
          END;

          IF  l_ccm_tandc_version = l_tandc_version THEN
              p_tandc_flag_out :='USER_ACCEPTED_TC';
          ELSE
              p_tandc_flag_out := 'USER_NOT_YET_ACCEPTED_TC';
          END IF;

          p_tandc_version_out :=l_tandc_version;



          BEGIN
              SELECT cam_acct_no,cam_stat_code
              INTO l_saving_acct_dtl,l_savings_statcode
              FROM cms_acct_mast
              WHERE cam_acct_id IN (
                                  SELECT cca_acct_id
                                  FROM cms_cust_acct
                                  WHERE cca_cust_code = l_cust_code
                                  AND cca_inst_code = p_inst_code_in)
                                  AND cam_type_code = 2
                                  AND cam_inst_code = p_inst_code_in;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  l_saving_acct_dtl:=NULL;
              WHEN OTHERS THEN
                  p_resp_code_out  := '21';
                  l_errmsg         := 'Error while selecting Savings Account Details'|| SUBSTR(SQLERRM, 1, 200);
              RAISE exp_reject_record;
          END;


          BEGIN
              SELECT  cdp_param_value
              INTO  l_min_tran_amt
              FROM cms_dfg_param
              WHERE cdp_param_key = 'InitialTransferAmount'
              AND  cdp_inst_code = p_inst_code_in
              AND cdp_prod_code =l_prod_code
              and cdp_card_type= l_prod_cattype;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  l_min_tran_amt :='0';
              WHEN OTHERS THEN
                  p_resp_code_out:= '12';
                  l_errmsg := 'Error while selecting min Initial Tran amt ' ||
                  SUBSTR(SQLERRM, 1, 200);
                  RAISE exp_reject_record;
          END;

          IF l_acct_no IS NULL THEN
              IF l_gpresign_optinflag = '0' OR  l_acct_bal < TO_NUMBER(l_min_tran_amt) OR TO_NUMBER(l_min_tran_amt) =0  THEN
                  p_saving_acct_info_out := 'NOT ELIGIBLE'; -- Not eligible Minimum balance requirement for savings is not met OR e-Sign declined
              ELSE
                  p_saving_acct_info_out :='ELIGIBLE'; -- Eligible for Savings Account
              END IF;
          ELSIF l_savings_statcode = 2 THEN
              p_saving_acct_info_out :='DISABLED'; -- Savings Account disabled due to the 7th transfer rule
          ELSE
              p_saving_acct_info_out :='ACTIVE'; -- Savings Account exists
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
   END optIn_Settings;


PROCEDURE update_zip(p_inst_code_in           IN     NUMBER,
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
                    p_pan_code_in             IN     VARCHAR2,
                    p_action_in               IN     VARCHAR2,
                    p_zipcode_in              IN     VARCHAR2,
                    p_resp_code_out           OUT    VARCHAR2,
                    p_respmsg_out             OUT    VARCHAR2
                          )
   IS
   
   /*************************************************
    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
  *************************************************/
  
      l_hash_pan                 cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                 cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no                  cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal                 cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal               cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code                cms_appl_pan.cap_prod_code%TYPE;
      l_prod_cattype             cms_appl_pan.cap_card_type%TYPE;
      l_card_stat                cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date               cms_appl_pan.cap_expry_date%TYPE;
      l_active_date              cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code                cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag               cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type                 cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag                cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_dup_rrn_check            cms_transaction_mast.ctm_rrn_check%TYPE;
      l_comb_hash                pkg_limits_check.type_hash;
      l_auth_id                  cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp                transactionlog.time_stamp%TYPE;
      l_preauth_flag             cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_type                cms_acct_mast.cam_type_code%TYPE;
      l_login_txn                cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code                 cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan                 cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type           transactionlog.feeattachtype%TYPE;
      l_tranfee_amt              transactionlog.tranfee_amt%TYPE;
      l_total_amt                cms_acct_mast.cam_acct_bal%TYPE;
      l_preauth_type             cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id               cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber              cms_appl_pan.cap_proxy_number%TYPE;
      l_repl_flag                cms_appl_pan.cap_repl_flag%TYPE;
      l_cust_code                cms_cust_mast.ccm_cust_code%TYPE;
      l_addr_code                cms_appl_pan.cap_bill_addr%TYPE;
      l_errmsg                   transactionlog.error_msg%TYPE;
      l_encrypt_enable           cms_prod_cattype.cpc_encrypt_enable%type;
      l_pin_code                 cms_addr_mast.cam_pin_code%type;
      exp_reject_record          EXCEPTION;
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
                   cap_repl_flag,
                   cap_cust_code,
                   cap_bill_addr
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
                   l_repl_flag,
                   l_cust_code,
                   l_addr_code
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
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

         -- Sn Transaction Details  procedure call
         begin
            select cpc_encrypt_enable
            into l_encrypt_enable
            from cms_prod_cattype
            where cpc_inst_code=p_inst_code_in
            and cpc_prod_code=l_prod_code
            and cpc_card_type=l_prod_cattype;

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
    --EN: CMSAUTH check

    BEGIN
       INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
            VALUES (p_rrn_in, p_delivery_channel_in, p_txn_code_in, l_cust_code,1);
    EXCEPTION
       WHEN OTHERS THEN
          p_resp_code_out := '21';
          l_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;

    if l_encrypt_enable='Y' then
          l_pin_code:=fn_emaps_main(P_ZIPCODE_IN);
    else
        l_pin_code:=P_ZIPCODE_IN;
    end if;

     BEGIN
        UPDATE CMS_ADDR_MAST SET CAM_PIN_CODE=NVL(l_pin_code,CAM_PIN_CODE),
				CAM_PIN_CODE_ENCR = NVL(fn_emaps_main(P_ZIPCODE_IN),CAM_PIN_CODE_ENCR)
        WHERE CAM_INST_CODE=p_inst_code_in
        AND   CAM_ADDR_CODE=l_addr_code;

        IF SQL%ROWCOUNT =0 THEN
            p_resp_code_out := '12';
            l_errmsg   := 'Zipcode is not updated properly' ;
            RAISE EXP_REJECT_RECORD;
        END IF;
    EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
            RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
            p_resp_code_out := '12';
            l_errmsg   := 'Error while updating CMS_ADDR_MAST' || SUBSTR(SQLERRM, 1, 200);
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
   END update_zip;


PROCEDURE update_saving_account_setting (
                                   p_inst_code_in                   IN       NUMBER,
                                   p_delivery_chnl_in               IN       VARCHAR2,
                                   p_txn_code_in                    IN       VARCHAR2,
                                   p_rrn_in                         IN       VARCHAR2,
                                   p_cust_id_in                     IN       NUMBER,
                                   p_appl_id_in                     IN       VARCHAR2,
                                   p_partner_id_in                  IN       VARCHAR2,
                                   p_tran_date_in                   IN       VARCHAR2,
                                   p_tran_time_in                   IN       VARCHAR2,
                                   p_curr_code_in                   IN       VARCHAR2,
                                   p_revrsl_code_in                 IN       VARCHAR2,
                                   p_msg_type_in                    IN       VARCHAR2,
                                   p_ip_addr_in                     IN       VARCHAR2,
                                   p_ani_in                         IN       VARCHAR2,
                                   p_dni_in                         IN       VARCHAR2,
                                   p_device_mobno_in                IN       VARCHAR2,
                                   p_device_id_in                   IN       VARCHAR2,
                                   p_uuid_in                        IN       VARCHAR2,
                                   p_osname_in                      IN       VARCHAR2,
                                   p_osversion_in                   IN       VARCHAR2,
                                   p_gps_coordinates_in             IN       VARCHAR2,
                                   p_display_resolution_in          IN       VARCHAR2,
                                   p_physical_memory_in             IN       VARCHAR2,
                                   p_appname_in                     IN       VARCHAR2,
                                   p_appversion_in                  IN       VARCHAR2,
                                   p_sessionid_in                   IN       VARCHAR2,
                                   p_device_country_in              IN       VARCHAR2,
                                   p_device_region_in               IN       VARCHAR2,
                                   p_ipcountry_in                   IN       VARCHAR2,
                                   p_proxy_flag_in                  IN       VARCHAR2,
                                   p_pan_code_in                    IN       VARCHAR2,
                                   p_loadimetransfer_in             IN       VARCHAR2,
                                   p_loadtimetransfer_amt_in        IN       VARCHAR2,
                                   p_firstmonthtransfer_in          IN       VARCHAR2,
                                   p_firstmonthtransfer_amt_in      IN       VARCHAR2,
                                   p_fifteenmonthtransfer_in        IN       VARCHAR2,
                                   p_fifteenmonthtransfer_amt_in    IN       VARCHAR2,
                                   p_weeklytransfer_flag_in         IN       VARCHAR2,
                                   p_weeklytransfer_amount_in       IN       VARCHAR2,
                                   p_biweeklytransfer_flag_in       IN       VARCHAR2,
                                   p_biweeklytransfer_amt_in        IN       VARCHAR2,
                                   p_dayofmonthtrns_flag_in         IN       VARCHAR2,
                                   p_dayofmonth_in                  IN       VARCHAR2,
                                   p_dayofmonthtrns_amt_in          IN       VARCHAR2,
                                   p_minreload_amnt_in              IN       VARCHAR2,
                                   p_resp_code_out                  OUT      VARCHAR2,
                                   p_resp_msg_out                   OUT      VARCHAR2
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
   l_timestamp         transactionlog.time_stamp%TYPE;
   l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
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
   l_errmsg            transactionlog.error_msg%TYPE;
   l_appl_code         cms_appl_pan.cap_appl_code%type;
   l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   L_SAVING_ACCTNO     cms_acct_mast.cam_acct_no%TYPE;
   l_min_svg_lmt       NUMBER;
   l_max_svg_lmt       NUMBER;
   l_max_spend_amt     cms_dfg_param.cdp_param_key%TYPE;
   l_min_spend_amt     cms_dfg_param.cdp_param_key%TYPE;
   l_dfg_cnt           NUMBER(10);
   exp_reject_record   exception;
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
                  'ERROR FROM authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      end;

       BEGIN
           SELECT cam_acct_no INTO L_SAVING_ACCTNO  FROM CMS_ACCT_MAST
           where cam_acct_id in( select cca_acct_id from cms_cust_acct
           WHERE cca_cust_code=l_cust_code AND cca_inst_code=p_inst_code_in) AND cam_type_code=2
           AND CAM_INST_CODE=p_inst_code_in;
         EXCEPTION
         WHEN NO_DATA_FOUND  THEN
            p_resp_code_out := '105';
            l_errmsg :='Savings account not created for this card';
            RAISE exp_reject_record;
         WHEN OTHERS  THEN
            p_resp_code_out := '12';
            l_errmsg :='Problem while selecting account details' || substr (sqlerrm, 1, 200);
            raise exp_reject_record;
       END;

      l_dfg_cnt:=0;

       FOR i IN (SELECT cdp_param_value, cdp_param_key
                   FROM cms_dfg_param
                  WHERE cdp_param_key IN
                           ('MinSavingParam','MaxSavingParam','MinSpendingParam','MaxSpendingParam')
                   AND cdp_inst_code = p_inst_code_in
                   AND cdp_prod_code = l_prod_code
                   AND CDP_CARD_TYPE = l_prod_cattype)
       LOOP
       BEGIN
          IF i.cdp_param_key = 'MinSavingParam'
          THEN
             l_dfg_cnt:=l_dfg_cnt+1;
             l_min_svg_lmt := i.cdp_param_value;
          ELSIF i.cdp_param_key = 'MaxSavingParam'
          THEN
             l_dfg_cnt:=l_dfg_cnt+1;
             l_max_svg_lmt := i.cdp_param_value;
          ELSIF i.cdp_param_key = 'MinSpendingParam'
          THEN
             l_dfg_cnt:=l_dfg_cnt+1;
             l_min_spend_amt := i.cdp_param_value;
          ELSIF i.cdp_param_key = 'MaxSpendingParam'
          THEN
             l_dfg_cnt:=l_dfg_cnt+1;
             l_max_spend_amt := i.cdp_param_value;
          END IF;
       EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while selecting saving account parameters '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
       END;
       END LOOP;

       IF l_dfg_cnt=0 THEN
        p_resp_code_out := '21';
        l_errmsg:='saving account parameters is not defined for product '||l_prod_code;
        RAISE exp_reject_record;
       END IF;

       IF l_min_svg_lmt IS NULL
       THEN

            p_resp_code_out := '21';
            l_errmsg := 'No data for selecting min Savings amt for product code '||l_prod_code ||' and instcode '||p_inst_code_in||' '||p_resp_code_out;
            RAISE exp_reject_record;

       ELSIF l_max_svg_lmt IS NULL
       THEN

            p_resp_code_out := '21';
            l_errmsg := 'No data for selecting max savings acct bal for product code '||l_prod_code ||' and instcode '||p_inst_code_in||' '||p_resp_code_out;
            RAISE exp_reject_record;

       ELSIF l_min_spend_amt IS NULL
       THEN

            p_resp_code_out := '21';
            l_errmsg := 'No data for selecting min spending amt for product code '||l_prod_code ||' and instcode '||p_inst_code_in;
            RAISE exp_reject_record;

       ELSIF l_max_spend_amt IS NULL
       THEN

            p_resp_code_out := '21';
            l_errmsg := 'No data for selecting max spending amt for product code '||l_prod_code ||' and instcode '||p_resp_code_out;
            RAISE exp_reject_record;
      END IF;

      IF p_loadimetransfer_in = 1 THEN
        IF p_loadtimetransfer_amt_in IS NULL THEN
          p_resp_code_out := '49';
          l_errmsg  := 'Data Element Name LoadTimeTransferAmount is Invalid. Value is :'||p_loadtimetransfer_amt_in;
          RAISE EXP_REJECT_RECORD;
        END IF;
           IF p_loadtimetransfer_amt_in < l_min_svg_lmt  OR p_loadtimetransfer_amt_in < l_min_spend_amt THEN

             p_resp_code_out := '103';
             l_errmsg := 'Amount should not below the Minimum configured amount';
             RAISE exp_reject_record;

           ELSIF p_loadtimetransfer_amt_in > l_max_svg_lmt OR p_loadtimetransfer_amt_in > l_max_spend_amt THEN

            p_resp_code_out := '104';
            l_errmsg := 'Amount should not exceed the Maximum configured amount';
            RAISE exp_reject_record;
           END IF;
       -- END IF;
      END IF;
      IF p_firstmonthtransfer_in = 1 THEN
         IF  p_firstmonthtransfer_amt_in IS NULL THEN
          p_resp_code_out := '49';
          l_errmsg  := 'Data Element Name FirstMonthTransferAmount is Invalid. Value is :'||p_firstmonthtransfer_amt_in;
          RAISE EXP_REJECT_RECORD;
        END IF;
           IF p_firstmonthtransfer_amt_in < l_min_svg_lmt OR p_firstmonthtransfer_amt_in < l_min_spend_amt THEN --Added for CR - 40 in release 23.1.1

             p_resp_code_out := '103';
             l_errmsg := 'Amount should not below the Minimum configured amount';
             RAISE exp_reject_record;

           ELSIF p_firstmonthtransfer_amt_in > l_max_svg_lmt OR  p_firstmonthtransfer_amt_in > l_max_spend_amt THEN --Added for CR - 40 in release 23.1.1

            p_resp_code_out := '104';
            l_errmsg := 'Amount should not exceed the Maximum configured amount';
            raise exp_reject_record;
           END IF;
        --end if;
      END IF;
      IF p_fifteenmonthtransfer_in = 1 THEN
        IF  p_fifteenmonthtransfer_amt_in IS NULL THEN
          p_resp_code_out := '49';
          l_errmsg  := 'Data Element Name FifteenMontTransferAmount is Invalid. Value is :'||p_fifteenmonthtransfer_amt_in;
          RAISE EXP_REJECT_RECORD;
        END IF;
           IF p_fifteenmonthtransfer_amt_in < l_min_svg_lmt OR  p_fifteenmonthtransfer_amt_in < l_min_spend_amt THEN
             p_resp_code_out := '103';
             l_errmsg := 'Amount should not below the Minimum configured amount';
             RAISE exp_reject_record;
           ELSIF p_fifteenmonthtransfer_amt_in > l_max_svg_lmt OR p_fifteenmonthtransfer_amt_in > l_max_spend_amt THEN
             p_resp_code_out := '104';
             l_errmsg := 'Amount should not exceed the Maximum configured amount';
             raise exp_reject_record;
           end if;
         --end if;
       END IF;

       IF  p_weeklytransfer_flag_in =1  THEN

          IF  p_weeklytransfer_amount_in IS NULL THEN
            p_resp_code_out := '49';
            l_errmsg  := 'Data Element Name WeeklyTransferAmount is Invalid. Value is :'||p_weeklytransfer_amount_in;
            RAISE EXP_REJECT_RECORD;
           END IF;
           IF p_weeklytransfer_amount_in < l_min_svg_lmt OR  p_weeklytransfer_amount_in < l_min_spend_amt THEN
               p_resp_code_out := '103';
               l_errmsg := 'Amount should not below the Minimum configured amount';
               RAISE exp_reject_record;
            elsif p_weeklytransfer_amount_in > l_max_svg_lmt or p_weeklytransfer_amount_in > l_max_spend_amt then
               p_resp_code_out := '104';
               l_errmsg := 'Amount should not exceed the Maximum configured amount';
               RAISE exp_reject_record;
             END IF;
           --END IF;
       END IF;

       IF p_biweeklytransfer_flag_in =1  THEN

        IF  p_biweeklytransfer_amt_in IS NULL THEN
          p_resp_code_out := '49';
          l_errmsg  := 'Data Element Name Bi-WeeklyTransferAmount is Invalid. Value is :'||p_biweeklytransfer_amt_in;
          RAISE EXP_REJECT_RECORD;
        END IF;
          IF p_biweeklytransfer_amt_in < l_min_svg_lmt OR  p_biweeklytransfer_amt_in < l_min_spend_amt THEN
             p_resp_code_out := '103';
             l_errmsg := 'Amount should not below the Minimum configured amount';
             RAISE exp_reject_record;
          ELSIF p_biweeklytransfer_amt_in > l_max_svg_lmt OR p_biweeklytransfer_amt_in > l_max_spend_amt THEN
             p_resp_code_out := '104';
             l_errmsg := 'Amount should not exceed the Maximum configured amount';
             RAISE exp_reject_record;
            END IF;
         --END IF;

       END IF;

       IF p_dayofmonthtrns_flag_in = 1 THEN
         IF p_dayofmonth_in < 1   OR  p_dayofmonth_in  > 31   THEN
          p_resp_code_out := '49';
          l_errmsg  := 'Data Element Name DayofTransfer is Invalid. Value is :'||p_dayofmonth_in;
          RAISE EXP_REJECT_RECORD;
         END IF;

          IF  p_dayofmonthtrns_amt_in IS NULL THEN
            p_resp_code_out := '49';
            l_errmsg  := 'Data Element Name MontlyTransferAmount is Invalid. Value is :'||p_dayofmonthtrns_amt_in;
            RAISE EXP_REJECT_RECORD;
          END IF;
            IF p_dayofmonthtrns_amt_in < l_min_svg_lmt OR  p_dayofmonthtrns_amt_in < l_min_spend_amt THEN
                   p_resp_code_out := '103';
                   l_errmsg := 'Amount should not below the Minimum configured amount';
                   RAISE exp_reject_record;
            ELSIF p_dayofmonthtrns_amt_in > l_max_svg_lmt OR p_dayofmonthtrns_amt_in > l_max_spend_amt THEN
                  p_resp_code_out := '104';
                  l_errmsg := 'Amount should not exceed the Maximum configured amount';
                  raise exp_reject_record;
             END IF;
           --END IF;

        END IF;

   BEGIN
        UPDATE CMS_ACCT_MAST SET
        CAM_LOADTIME_TRANSFER= p_loadimetransfer_in,
        CAM_LOADTIME_TRANSFERAMT= decode(p_loadimetransfer_in,1,p_loadtimetransfer_amt_in,CAM_LOADTIME_TRANSFERAMT),
        CAM_FIRSTMONTH_TRANSFER= p_firstmonthtransfer_in,
        CAM_FIRSTMONTH_TRANSFERAMT= decode(p_firstmonthtransfer_in,1,p_firstmonthtransfer_amt_in,CAM_FIRSTMONTH_TRANSFERAMT),
        CAM_FIFTEENMONTH_TRANSFER= p_fifteenmonthtransfer_in,
        CAM_FIFTEENMONTH_TRANSFERAMT= decode(p_fifteenmonthtransfer_in,1,p_fifteenmonthtransfer_amt_in,CAM_FIFTEENMONTH_TRANSFERAMT),
        CAM_WEEKLYTRANSFER_FLAG = p_weeklytransfer_flag_in,
        CAM_WEEKLYTRANSFER_AMOUNT= decode(p_weeklytransfer_flag_in,1,p_weeklytransfer_amount_in,CAM_WEEKLYTRANSFER_AMOUNT),
        CAM_BIWEEKLYTRANSFER_FLAG=p_biweeklytransfer_flag_in,
        CAM_BIWEEKLYTRANSFER_AMOUNT= decode(p_biweeklytransfer_flag_in,1,p_biweeklytransfer_amt_in,CAM_BIWEEKLYTRANSFER_AMOUNT),
        CAM_ANYDAYMONTHTRANSFER_FLAG=p_dayofmonthtrns_flag_in,
        CAM_DAYOFTRANSFER_MONTH=p_dayofmonth_in,
        CAM_MONTLYTRANSFER_AMOUNT= decode(p_dayofmonthtrns_flag_in,1,p_dayofmonthtrns_amt_in,CAM_MONTLYTRANSFER_AMOUNT),
        CAM_MINRELOAD_AMOUNT = p_minreload_amnt_in
       WHERE CAM_INST_CODE=p_inst_code_in
        AND CAM_ACCT_NO=L_SAVING_ACCTNO;

      IF SQL%ROWCOUNT = 0 THEN
        l_errmsg  := 'Problem while updating data in ACCT MAST ' ||
                   SUBSTR(SQLERRM, 1, 200);
        p_resp_code_out := '21';
        RAISE EXP_REJECT_RECORD;
      END IF;

      EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg  := 'Error from while updating savings acct settings ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
   END;

   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK;
         p_resp_msg_out := l_errmsg;
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
   end;
END update_saving_account_setting;

PROCEDURE  CREATE_USER_ACCOUNT(
                                       p_inst_code_in            IN       NUMBER,
                                       p_delivery_chnl_in        IN       VARCHAR2,
                                       p_txn_code_in             IN       VARCHAR2,
                                       p_rrn_in                  IN       VARCHAR2,
                                         p_cust_id_in              IN       VARCHAR2,
                                       p_appl_id_in              IN       VARCHAR2,
                                       p_appl_flag_in            IN       VARCHAR2,
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
                                       p_username_in             IN       VARCHAR2,
                                       p_password_in             IN       VARCHAR2,
                                       p_secquest1_in            IN       VARCHAR2,
                                       p_secquest2_in            IN       VARCHAR2,
                                       p_secquest3_in            IN       VARCHAR2,
                                       p_secquest1ans_in         IN       VARCHAR2,
                                       p_secquest2ans_in         IN       VARCHAR2,
                                       p_secquest3ans_in         IN       VARCHAR2,
                                       p_resp_code_out           OUT      VARCHAR2,
                                       p_resp_msg_out            OUT      VARCHAR2
                                    )
                                    AS
/********************************************************************************************				    
     * Modified By      : VINI PUSHKARAN
     * Modified Date    : 01-MAR-2019
     * Purpose          : VMS-809(Decline Request for Web-account Username if Username is Already Taken)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R13_B0002    
     
    
    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
	
	* Modified By      : venkat Singamaneni
    * Modified Date    : 05-11-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jay
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991

  
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
   l_comb_hash         pkg_limits_check.type_hash;
   l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
   l_timestamp         transactionlog.time_stamp%TYPE;
   l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
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
   l_errmsg            transactionlog.error_msg%TYPE;
   l_appl_code         cms_appl_pan.cap_appl_code%TYPE;
   l_cust_code         CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
   l_hash_password     cms_cust_mast.ccm_password_hash%TYPE;
   l_hash_sqa1         cms_security_questions.csq_answer_hash%TYPE;
   l_hash_sqa2         cms_security_questions.csq_answer_hash%TYPE;
   l_hash_sqa3         cms_security_questions.csq_answer_hash%TYPE;
   l_cust_name         CMS_CUST_MAST.CCM_USER_NAME%TYPE;
   l_count1            NUMBER;
   l_encrypt_enable    cms_prod_cattype.cpc_encrypt_enable%type;
   l_user_name         cms_cust_mast.ccm_user_name%type;
    l_cust_id           cms_cust_mast.ccm_cust_id%type;
   exp_reject_record   EXCEPTION;

BEGIN
   BEGIN

    p_resp_msg_out := 'success';
	 l_cust_id := to_number(p_cust_id_in);
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


      begin
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
      end;
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
                  'ERROR FROM authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;


              --Sn check whether the Username  already created or not
       BEGIN

           SELECT nvl(decode(l_encrypt_enable,'Y',fn_dmaps_main(ccm_user_name),ccm_user_name),0) INTO l_cust_name
           FROM CMS_CUST_MAST
             WHERE CCM_CUST_ID= l_cust_id AND CCM_INST_CODE=p_inst_code_in ;


           IF l_cust_name <> '0' THEN
               l_errmsg := 'Username already created for the customer  ';
               p_resp_code_out := '112';
               RAISE EXP_REJECT_RECORD;
           END IF;

          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg  := 'Error from getting cust name' ||
            SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
      END;
      --En check whether the Username already created or not

      --Sn check whether the Username already exists or not

      if l_encrypt_enable='Y' then
            l_user_name:=fn_emaps_main(UPPER(trim(p_username_in)));
      else
          l_user_name:=UPPER(trim(p_username_in));
      end if;

       BEGIN
           SELECT COUNT(1)
           INTO l_count1
           FROM CMS_CUST_MAST
           WHERE (UPPER(CCM_USER_NAME) =  fn_emaps_main(UPPER(trim(p_username_in)))   --Modified for Decline Request for Web-account Username if Username is Already Taken(VMS-809)
	         OR UPPER(CCM_USER_NAME)= UPPER(trim(p_username_in)))
           AND CCM_INST_CODE=p_inst_code_in
           AND CCM_APPL_ID =p_appl_id_in  ;

           IF l_count1 <> 0 THEN
              l_errmsg := 'Username already exists For this Application ID ';
              p_resp_code_out := '113';
             RAISE EXP_REJECT_RECORD;
           END IF;

          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg  := 'Error from checking cust name' ||
            SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
      END;
      --En check whether the Username already Username or not


       --Sn Get the HashPassword
     BEGIN
          l_hash_password := GETHASH(trim(p_password_in));
        EXCEPTION
          WHEN OTHERS THEN
         p_resp_code_out     := '12';
         l_errmsg := 'Error while converting password ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
     END;
      --En Get the HashPassword

      --Sn Get the HashSecuriyAnswerOne
     BEGIN
          l_hash_sqa1 := GETHASH(trim(p_secquest1ans_in));
        EXCEPTION
          WHEN OTHERS THEN
         p_resp_code_out     := '12';
         l_errmsg := 'Error while converting sequrity answer one ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
     END;
      --En Get the HashSecuriyAnswerOne

        --Sn Get the HashSecuriyAnswerTwo
      BEGIN
          l_hash_sqa2 := GETHASH(trim(p_secquest2ans_in));
        EXCEPTION
          WHEN OTHERS THEN
         p_resp_code_out     := '12';
         l_errmsg := 'Error while converting sequrity answer two ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
     END;
      --En Get the HashSecuriyAnswerTwo


      --Sn Get the HashSecuriyAnswerThree
     BEGIN
          l_hash_sqa3 := GETHASH(trim(p_secquest3ans_in));
        EXCEPTION
          WHEN OTHERS THEN
         p_resp_code_out     := '12';
         l_errmsg := 'Error while converting sequrity answer three ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
     END;
      --En Get the HashSecuriyAnswerThree

       --St Username & password with sequrity question link to the customerID

     BEGIN

        UPDATE CMS_CUST_MAST
           SET CCM_USER_NAME=l_user_name ,
			   CCM_PASSWORD_HASH=l_hash_password,
               ccm_lupd_date=sysdate, ccm_lupd_user=1 ,
               CCM_APPL_ID =p_appl_id_in,
			   CCM_USER_NAME_ENCR = fn_emaps_main(UPPER(trim(p_username_in)))
          WHERE CCM_INST_CODE=p_inst_code_in AND CCM_CUST_ID=l_cust_id;

        IF SQL%ROWCOUNT = 0 THEN
           p_resp_code_out := '21';
           l_errmsg  := 'Error while updating username and  password ';
           RAISE EXP_REJECT_RECORD;
        END IF;

      EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
              RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg  := 'Error from updating username and  password ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

     END;

     BEGIN

         INSERT INTO cms_security_questions(csq_inst_code,csq_cust_id,csq_question,csq_answer_hash)
         VALUES(p_inst_code_in,l_cust_id,trim(p_secquest1_in),l_hash_sqa1);

         INSERT INTO cms_security_questions(csq_inst_code,csq_cust_id,csq_question,csq_answer_hash)
         VALUES(p_inst_code_in,l_cust_id,trim(p_secquest2_in),l_hash_sqa2);

         INSERT INTO cms_security_questions(csq_inst_code,csq_cust_id,csq_question,csq_answer_hash)
         VALUES(p_inst_code_in,l_cust_id,trim(p_secquest3_in),l_hash_sqa3);

      EXCEPTION
        WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg  := 'Error from inserting security questions and answers ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

     END;

  --St Update the src app flag in product category table of flag is N
    IF p_appl_flag_in = 'N' THEN
     BEGIN
        UPDATE cms_prod_cattype
           SET cpc_src_app_flag='Y',
               cpc_lupd_date=sysdate, cpc_lupd_user=1
         WHERE cpc_prod_code=l_prod_code and cpc_card_type=l_prod_cattype
         and cpc_src_app=p_appl_id_in and cpc_inst_code=p_inst_code_in;
        IF SQL%ROWCOUNT = 0 THEN
           p_resp_code_out := '21';
           l_errmsg  := 'Error while updating src app flag ';
           RAISE EXP_REJECT_RECORD;
        END IF;
      EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
              RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg  := 'Error from updating  src app flag ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
     END;
  END IF;
    p_resp_code_out := 1;

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
            l_errmsg := 'Invalid Card number ' ;
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

          update VMSCMS.CMS_TRANSACTION_LOG_DTL                --Added for VMS-5735/FSP-991
          set CTD_DEVICE_ID= p_device_id_in,
          CTD_USER_NAME= p_username_in,
          CTD_MOBILE_NUMBER=p_device_mobno_in
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
            || ' Error while inserting into transaction log  '
            || l_errmsg;
      WHEN OTHERS
      THEN
         p_resp_code_out := '69';
         p_resp_msg_out :=
               'Error while inserting into transaction log '
            || SUBSTR (SQLERRM, 1, 300);
   END;

END CREATE_USER_ACCOUNT;

PROCEDURE        update_password (
   p_inst_code_in            IN       NUMBER,
   p_delivery_chnl_in        IN       VARCHAR2,
   p_txn_code_in             IN       VARCHAR2,
   p_rrn_in                  IN       VARCHAR2,
 --p_appl_id_in              IN       VARCHAR2,
   p_partner_id_in           IN       VARCHAR2,
   p_tran_date_in            IN       VARCHAR2,
   p_tran_time_in            IN       VARCHAR2,
   p_curr_code_in            IN       VARCHAR2,
   p_revrsl_code_in          IN       VARCHAR2,
   p_msg_type_in             IN       VARCHAR2,
-- p_user_name_in            IN       VARCHAR2,
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
   p_orgRRN_in               IN       VARCHAR2,
   p_old_password_in         IN       VARCHAR2,
   p_new_password_in         IN       VARCHAR2,
   p_resp_code_out           OUT      VARCHAR2,
   p_resp_msg_out            OUT      VARCHAR2
)

/*****************************************************************************************************
    * Modified By      : venkat Singamaneni
    * Modified Date    : 05-11-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jay
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
*****************************************************************************************************/
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
   l_timestamp         transactionlog.time_stamp%TYPE;
   l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_acct_type         cms_acct_mast.cam_type_code%TYPE;
   l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
   l_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
   l_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
   l_feeattach_type    transactionlog.feeattachtype%TYPE;
   l_tranfee_amt       transactionlog.tranfee_amt%TYPE;
   l_total_amt         cms_acct_mast.cam_acct_bal%TYPE;
   l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
   l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
   l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
   l_errmsg            transactionlog.error_msg%TYPE;
   l_appl_code         cms_appl_pan.cap_appl_code%TYPE;
   l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   l_HASH_PASSWORD     cms_cust_mast.ccm_password_hash%TYPE;
   l_HASH_OLDPASSWORD  cms_cust_mast.ccm_password_hash%TYPE;
   l_WRNG_COUNT        cms_cust_mast.ccm_wrong_logincnt%TYPE;
   l_WRONG_PWDCUNT         CMS_PROD_CATTYPE.CPC_WRONG_LOGONCOUNT%TYPE;
   l_UNLOCK_WAITTIME       CMS_PROD_CATTYPE.CPC_ACCTUNLOCK_DURATION%TYPE;
   l_ACCTLOCK_FLAG         CMS_CUST_MAST.CCM_ACCTLOCK_FLAG%TYPE;
   l_TIME_DIFF             NUMBER;
   l_OLDPWDHASH            cms_cust_mast.CCM_PASSWORD_HASH%type;
   l_TRAN_REVERSE_FLAG     TRANSACTIONLOG.TRAN_REVERSE_FLAG%type;
   exp_reject_record       EXCEPTION;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
   BEGIN
   p_resp_msg_out := 'success';
   p_resp_code_out :='00';
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
  if  p_orgRRN_in IS NOT NULL and p_msg_type_in ='0400' then
  l_txn_desc :=l_txn_desc||'-Reversal';
  end if;
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
          l_HASH_PASSWORD := GETHASH(trim(p_new_password_in));
        EXCEPTION
          WHEN OTHERS THEN
         p_resp_code_out     := '12';
         l_errmsg := 'Error while converting password ' || SUBSTR(SQLERRM, 1, 200);
         RAISE exp_reject_record;
       END;
     --En Get the hash password
      --Sn Get the hash old password
       BEGIN
          l_HASH_OLDPASSWORD := GETHASH(trim(p_old_password_in));
        EXCEPTION
          WHEN OTHERS THEN
         p_resp_code_out   := '12';
         l_errmsg := 'Error while converting old password ' || SUBSTR(SQLERRM, 1, 200);
         RAISE exp_reject_record;
       END;
     --En Get the hash old password
	  -- original transaction details
	  if  p_orgRRN_in IS NOT NULL and p_msg_type_in ='0400' then
	   BEGIN
	   

			SELECT TRAN_REVERSE_FLAG
			  INTO  l_TRAN_REVERSE_FLAG
			 FROM VMSCMS.TRANSACTIONLOG                       --Added for VMS-5735/FSP-991
			WHERE RRN = p_orgRRN_in  --AND BUSINESS_DATE = p_tran_date_in
         --AND BUSINESS_TIME = p_tran_time_in
         AND CUSTOMER_CARD_NO = gethash (p_pan_code_in)
				 AND DELIVERY_CHANNEL = p_delivery_chnl_in
				 AND INSTCODE = P_INST_CODE_in AND RESPONSE_CODE = '00';
	
	if SQL%ROWCOUNT=0
	then 
			SELECT TRAN_REVERSE_FLAG
			  INTO  l_TRAN_REVERSE_FLAG
			 FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                       --Added for VMS-5735/FSP-991
			WHERE RRN = p_orgRRN_in  --AND BUSINESS_DATE = p_tran_date_in
         --AND BUSINESS_TIME = p_tran_time_in
         AND CUSTOMER_CARD_NO = gethash (p_pan_code_in)
				 AND DELIVERY_CHANNEL = p_delivery_chnl_in
				 AND INSTCODE = P_INST_CODE_in AND RESPONSE_CODE = '00';
	END IF;	

	  IF l_TRAN_REVERSE_FLAG = 'Y' THEN
		 p_resp_code_out := '52';
		 l_errmsg   := 'The reversal already done for the orginal transaction';
		 RAISE exp_reject_record;
    END IF;
EXCEPTION
    WHEN exp_reject_record THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     p_resp_code_out := '53';
     l_errmsg   := 'Matching transaction not found';
     RAISE exp_reject_record;
    WHEN TOO_MANY_ROWS THEN
     p_resp_code_out := '21';
     l_errmsg   := 'More than one matching record found in the master';
     RAISE exp_reject_record;
    WHEN OTHERS THEN
     p_resp_code_out := '21';
     l_errmsg   := 'Error while selecting master data' ||
                SUBSTR(SQLERRM, 1, 300);
     RAISE exp_reject_record;
   END;
	  end if;
	     begin
      SELECT CCM_PASSWORD_HASH INTO l_OLDPWDHASH
        FROM CMS_CUST_MAST
        WHERE  ccm_cust_code=l_cust_code AND CCM_INST_CODE=P_INST_CODE_in ;
       EXCEPTION
          WHEN OTHERS THEN
         p_resp_code_out     := '12';
         l_errmsg := 'Error while getting the old password ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
      END;
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

IF p_msg_type_in ='0200' THEN
        IF l_OLDPWDHASH<>l_HASH_OLDPASSWORD THEN
	              p_resp_code_out := '114';
                  l_errmsg  := 'Invalid old Password ';
                 RAISE EXP_REJECT_RECORD;
	  END IF;
      BEGIN
        SELECT CPC_WRONG_LOGONCOUNT-1,
                CPC_ACCTUNLOCK_DURATION
                INTO l_WRONG_PWDCUNT,
                l_UNLOCK_WAITTIME
                FROM CMS_PROD_CATTYPE
                 WHERE CPC_PROD_CODE=l_prod_code
				AND CPC_CARD_TYPE= l_prod_cattype
				AND CPC_INST_CODE=P_INST_CODE_in;
        EXCEPTION
           WHEN OTHERS THEN
             p_resp_code_out    := '12';
             l_errmsg       := 'Error while getting ACCT UNLOCK PARAMS ' || SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
        END;
            BEGIN

            select nvl(CCM_WRONG_LOGINCNT,'0'),
                   nvl(CCM_ACCTLOCK_FLAG,'N'),
                 ROUND((sysdate- nvl(ccm_last_logindate,sysdate))*24*60)
                 INTO l_wrng_count,
                      l_acctlock_flag,
                      l_time_diff
                  FROM CMS_CUST_MAST CCM
                  WHERE ccm_cust_code=l_cust_code
                  AND ccm_inst_code=P_INST_CODE_in;
            EXCEPTION
           WHEN OTHERS THEN

                  p_resp_code_out := '12';
               l_errmsg := 'Error while getting customer details ' || SUBSTR(SQLERRM, 1, 200);

                  RAISE exp_reject_record;
            END;
          if  (l_acctlock_flag ='L' and  l_time_diff < l_UNLOCK_WAITTIME) and (l_WRONG_PWDCUNT is not null and  l_UNLOCK_WAITTIME is not  null)   then
              p_resp_code_out := '224';
              l_errmsg  := 'User id is locked.Please try after'||l_UNLOCK_WAITTIME||' minutes';
             -- P_logonmessage  := (l_WRONG_PWDCUNT+1);
              RAISE EXP_REJECT_RECORD;
          else

             --St User Authentication
               BEGIN
              IF l_OLDPWDHASH  <> l_HASH_OLDPASSWORD THEN
                if l_WRONG_PWDCUNT is not null and  l_UNLOCK_WAITTIME is not  null then
                  if  l_wrng_count < l_WRONG_PWDCUNT  and l_time_diff < l_UNLOCK_WAITTIME  then
                       BEGIN
                            SP_UPDATE_USERID ( P_INST_CODE_in, l_cust_code,l_acctlock_flag,'U', l_errmsg );
                            IF   l_errmsg='OK' THEN
                                p_resp_code_out := '114';
                                  l_errmsg  := 'Invalid Username or Password ';
                                 -- p_logonmessage  := (l_WRONG_PWDCUNT - l_wrng_count);
                                RAISE EXP_REJECT_RECORD;
            END IF;
               p_resp_code_out := '21';
               RAISE exp_reject_record;
            --END IF;
                         EXCEPTION
                               WHEN EXP_REJECT_RECORD THEN
                                              RAISE;
                          WHEN OTHERS THEN
                           p_resp_code_out := '21';
                           l_errmsg  := 'Error from while updating user wrong count,acct flag ' ||SUBSTR(SQLERRM, 1, 200);
                           RAISE EXP_REJECT_RECORD;
                         END;
                elsif l_wrng_count = l_WRONG_PWDCUNT  and  l_time_diff < l_UNLOCK_WAITTIME  then
                 BEGIN
                   SP_UPDATE_USERID ( P_INST_CODE_in, l_cust_code,'L','U' ,l_errmsg );
                  IF   l_ERRMSG='OK' THEN
                        p_resp_code_out := '224';
                        l_errmsg  := 'User id is locked.Please try after'||l_UNLOCK_WAITTIME||' minutes';
                        -- P_logonmessage  := (l_WRONG_PWDCUNT+1);
                       RAISE EXP_REJECT_RECORD;
                  end if;
                       p_resp_code_out := '21';
                       RAISE EXP_REJECT_RECORD;
         --END IF;
      EXCEPTION

                  WHEN EXP_REJECT_RECORD THEN
            RAISE;
                  WHEN OTHERS THEN

            p_resp_code_out := '21';
                   l_errmsg  := 'Error from while updating user wrong count,acct flag ' ||
                        SUBSTR(SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
                else -- customer has given invlaid user crendenital even after the waitting time ....
      BEGIN

                         SP_UPDATE_USERID ( P_INST_CODE_in, l_cust_code,'N','R', l_errmsg );
                         IF l_errmsg='OK' THEN
                          p_resp_code_out := '114';
                             l_errmsg  := 'Invalid Username or Password ';
                                                 --   l_logonmessage  :=  l_WRONG_PWDCUNT;
                           RAISE EXP_REJECT_RECORD;
                         end if;

                           p_resp_code_out := '21';
                           --V_ERRMSG  := 'Error while updating cust master ' ||SUBSTR(SQLERRM, 1, 200);
                           RAISE EXP_REJECT_RECORD;
                       --end if;
                        EXCEPTION

                      WHEN EXP_REJECT_RECORD THEN

                      RAISE;

                      WHEN OTHERS THEN
                       p_resp_code_out := '21';
                       l_errmsg  := 'Error from while updating user wrong count,acct flag ' ||
                            SUBSTR(SQLERRM, 1, 200);
                      RAISE EXP_REJECT_RECORD;
                      END;
            END IF;
        else

                 p_resp_code_out := '114';
                  l_errmsg  := 'Invalid  Password ';
               RAISE exp_reject_record;
            END IF;
                 end if;
              EXCEPTION
               WHEN EXP_REJECT_RECORD THEN
                 RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
                   p_resp_code_out := '21';
                   l_errmsg  := 'Error from while Authenticate user ' ||
                        SUBSTR(SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;
               END;
           end if;
          --End User Authentication
      -- if user authentication is success..
       IF l_WRONG_PWDCUNT is not null and  l_UNLOCK_WAITTIME is not  null THEN
          begin
          --update cms_cust_mast set CCM_WRONG_LOGINCNT=0,CCM_LAST_LOGINDATE='',CCM_ACCTLOCK_FLAG='N',ccm_password_hash=l_HASH_PASSWORD
		   update cms_cust_mast set CCM_WRONG_LOGINCNT=0,CCM_LAST_LOGINDATE='',CCM_ACCTLOCK_FLAG='N'
              where  ccm_cust_code=l_cust_code
              and ccm_inst_code=P_INST_CODE_in;
            --   l_logonmessage := (l_WRONG_PWDCUNT+1);
            IF SQL%ROWCOUNT = 0 THEN
               p_resp_code_out := '21';
               l_errmsg  := 'Error while updating cust master ' ||SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
           end if;
      EXCEPTION
            when EXP_REJECT_RECORD then
            RAISE;
             WHEN OTHERS THEN
               p_resp_code_out := '21';
                   l_errmsg  := 'Error from while Authenticate user ' ||SUBSTR(SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;
          end;
      END IF;
	 BEGIN
      UPDATE CMS_CUST_MAST SET CCM_PASSWORD_HASH = l_HASH_PASSWORD
      where  ccm_cust_code=l_cust_code
              and ccm_inst_code=P_INST_CODE_in;
       IF SQL%ROWCOUNT = 0 THEN
            p_resp_code_out := '21';
       l_errmsg  := 'Not udpated new password ';
       RAISE EXP_REJECT_RECORD;
       END IF;
      EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
         RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg  := 'Error from while updating new password ' ||
              SUBSTR(SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
 END IF;
 IF p_msg_type_in ='0400' THEN
 BEGIN
         UPDATE CMS_CUST_MAST SET CCM_PASSWORD_HASH = l_HASH_OLDPASSWORD
             where  ccm_cust_code=l_cust_code
              and ccm_inst_code=P_INST_CODE_in;
       IF SQL%ROWCOUNT = 0 THEN
       p_resp_code_out := '21';
       l_errmsg  := 'Not udpated new password ';
       RAISE EXP_REJECT_RECORD;
       END IF;

      EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
         RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         p_resp_code_out := '21';
         l_errmsg  := 'Error from while updating new password ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
     END;

      end if;
  if  p_orgRRN_in IS NOT NULL and p_msg_type_in ='0400' and  p_resp_code_out='00' then

      BEGIN
            update VMSCMS.TRANSACTIONLOG set TRAN_REVERSE_FLAG='Y'        --Added for VMS-5735/FSP-991   
                WHERE RRN = p_orgRRN_in  AND
               CUSTOMER_CARD_NO = gethash (p_pan_code_in)
               AND DELIVERY_CHANNEL = p_delivery_chnl_in
               AND INSTCODE = P_INST_CODE_in AND RESPONSE_CODE = '00';
			   
			   		IF SQL%ROWCOUNT = 0 THEN
			UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST		
			set TRAN_REVERSE_FLAG='Y'        --Added for VMS-5735/FSP-991   
                WHERE RRN = p_orgRRN_in  AND
               CUSTOMER_CARD_NO = gethash (p_pan_code_in)
               AND DELIVERY_CHANNEL = p_delivery_chnl_in
               AND INSTCODE = P_INST_CODE_in AND RESPONSE_CODE = '00';
			   
          IF SQL%ROWCOUNT = 0 THEN
              p_resp_code_out := '21';
             l_errmsg  := 'Reversal flag updation fails';
              RAISE exp_reject_record;
          END IF;
	END IF;  
     EXCEPTION
          WHEN exp_reject_record THEN
            RAISE;
          WHEN OTHERS THEN
            p_resp_code_out := '21';
           l_errmsg   := 'Error while updating original transaction in transactionlog' ||
                      SUBSTR(SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;
       end if;

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
            || l_acct_no;
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

--          update cms_transaction_log_dtl
--          set CTD_DEVICE_ID= p_device_id_in,
--          CTD_USER_NAME= p_user_name_in,
--          CTD_MOBILE_NUMBER=p_device_mobno_in
--          where CTD_HASHKEY_ID=l_hashkey_id;

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
END update_password;

PROCEDURE customer_locator (p_inst_code_in            IN     NUMBER,
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
                              p_returned_type_in        IN     VARCHAR2,
                              p_resp_code_out           OUT    VARCHAR2,
                              p_respmsg_out             OUT    VARCHAR2,
                              p_return_locator_out      OUT    VARCHAR2)
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
      l_active_date       cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
      l_comb_hash         pkg_limits_check.type_hash;
      l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp         transactionlog.time_stamp%TYPE;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
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
      l_errmsg            transactionlog.error_msg%TYPE;
      L_CUSTOMER_ID       CMS_CUST_MAST.CCM_CUST_ID%TYPE;
      exp_reject_record   EXCEPTION;
   BEGIN
      BEGIN
         p_resp_code_out := '00';
         p_respmsg_out := 'success';

         --Sn pan details procedure call
         BEGIN
            SELECT pan.cap_pan_code,
                   pan.cap_pan_code_encr,
                   pan.cap_acct_no,
                   pan.cap_card_stat,
                   pan.cap_prod_code,
                   pan.cap_card_type,
                   pan.cap_expry_date,
                   pan.cap_active_date,
                   pan.cap_prfl_code,
                   pan.cap_proxy_number,
                   pan.cap_repl_flag,
                   cust.ccm_cust_id
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
                   L_REPL_FLAG,
                   L_CUSTOMER_ID
              FROM cms_appl_pan pan,cms_cust_mast cust
             WHERE
                   pan.CAP_CUST_CODE = cust.CCM_CUST_CODE
                   AND pan.CAP_INST_CODE = cust.CCM_INST_CODE
                   AND pan.cap_inst_code = p_inst_code_in
                   AND pan.cap_pan_code = gethash (p_pan_code_in)
                   AND pan.cap_mbr_numb = '000';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
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

         --En pan details procedure call

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

          IF p_returned_type_in=0 THEN
             p_return_locator_out:=p_pan_code_in;

          ELSIF p_returned_type_in=1 THEN
             p_return_locator_out:=l_proxynumber;

          ELSIF p_returned_type_in=2 THEN
             p_return_locator_out := L_CUSTOMER_ID;

 ELSIF p_returned_type_in=3 THEN
            p_return_locator_out := l_acct_no;
          ELSE
          p_return_locator_out := NULL;
          l_errmsg := 'Invalid Returned Locator Type';
          p_resp_code_out := '299';
          RAISE EXP_REJECT_RECORD;

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
   END customer_locator;

PROCEDURE update_occupation (p_inst_code_in           IN     NUMBER,
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
                    p_pan_code_in             IN     VARCHAR2,
                    p_action_in               IN     VARCHAR2,
                    p_occupation_type_in      IN     VARCHAR2,
                    p_occupation_in           IN     VARCHAR2,
                    p_resp_code_out           OUT    VARCHAR2,
                    p_respmsg_out             OUT    VARCHAR2
                          )
   IS
      l_hash_pan                 cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                 cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no                  cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal                 cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal               cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code                cms_appl_pan.cap_prod_code%TYPE;
      l_prod_cattype             cms_appl_pan.cap_card_type%TYPE;
      l_card_stat                cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date               cms_appl_pan.cap_expry_date%TYPE;
      l_active_date              cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code                cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag               cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type                 cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag                cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_dup_rrn_check            cms_transaction_mast.ctm_rrn_check%TYPE;
      l_comb_hash                pkg_limits_check.type_hash;
      l_auth_id                  cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp                transactionlog.time_stamp%TYPE;
      l_preauth_flag             cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_type                cms_acct_mast.cam_type_code%TYPE;
      l_login_txn                cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code                 cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan                 cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type           transactionlog.feeattachtype%TYPE;
      l_tranfee_amt              transactionlog.tranfee_amt%TYPE;
      l_total_amt                cms_acct_mast.cam_acct_bal%TYPE;
      l_preauth_type             cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id               cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber              cms_appl_pan.cap_proxy_number%TYPE;
      l_repl_flag                cms_appl_pan.cap_repl_flag%TYPE;
      l_cust_code                cms_cust_mast.ccm_cust_code%TYPE;
      l_addr_code                cms_appl_pan.cap_bill_addr%TYPE;
      l_appl_code                cms_caf_info_entry.cci_appl_code%TYPE;
      l_errmsg                   transactionlog.error_msg%TYPE;
      exp_reject_record          EXCEPTION;
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
                   cap_repl_flag,
                   cap_cust_code,
                   cap_bill_addr,
                   cap_appl_code
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
                   l_repl_flag,
                   l_cust_code,
                   l_addr_code,
                   l_appl_code
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
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
    --EN: CMSAUTH check

    BEGIN
       INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
            VALUES (p_rrn_in, p_delivery_channel_in, p_txn_code_in, l_cust_code,1);
    EXCEPTION
       WHEN OTHERS THEN
          p_resp_code_out := '21';
          l_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;


    BEGIN
--       UPDATE CMS_CUST_MAST
--          SET CCM_OCCUPATION_OTHERS =  NVL(p_occupation_in,CCM_OCCUPATION_OTHERS),
--              CCM_OCCUPATION = NVL(p_occupation_type_in,CCM_OCCUPATION)
--              WHERE  ccm_cust_code = l_CUST_CODE
--              AND ccm_inst_code = p_inst_code_in;
      UPDATE CMS_CUST_MAST 
        set CCM_OCCUPATION_OTHERS= decode(p_occupation_type_in,'00', p_occupation_in),
            CCM_OCCUPATION = NVL(p_occupation_type_in,CCM_OCCUPATION)
      WHERE ccm_cust_code = l_CUST_CODE
        AND ccm_inst_code = p_inst_code_in;
      
           IF SQL%ROWCOUNT = 0 THEN
              p_resp_code_out := '21';
              l_errmsg :='Occupation is not updated properly';
               RAISE EXP_REJECT_RECORD;
           END IF;
           EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
                        RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                 p_resp_code_out := '21';
                 l_errmsg :='Error while upadating CMS_CUST_MAST' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
     END;

     BEGIN
--       UPDATE CMS_CAF_INFO_ENTRY
--          SET CCI_OCCUPATION_OTHERS = NVL(p_occupation_in,CCI_OCCUPATION_OTHERS),
--              CCI_OCCUPATION = NVL(p_occupation_type_in,CCI_OCCUPATION)
--              WHERE  cci_appl_code = l_appl_code
--              AND cci_inst_code = p_inst_code_in;
       UPDATE CMS_CAF_INFO_ENTRY 
          set CCI_OCCUPATION_OTHERS= decode(p_occupation_type_in,'00', p_occupation_in),
              CCI_OCCUPATION = NVL(p_occupation_type_in,CCI_OCCUPATION)
       WHERE  cci_appl_code = l_appl_code
         AND cci_inst_code = p_inst_code_in;

           IF SQL%ROWCOUNT = 0 THEN
              p_resp_code_out := '21';
              l_errmsg :='Occupation is not updated properly';
               RAISE EXP_REJECT_RECORD;
           END IF;
           EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
                        RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                 p_resp_code_out := '21';
                 l_errmsg :='Error while upadating CMS_CAF_INFO_ENTRY' || SUBSTR (SQLERRM, 1, 200);
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
   END update_occupation;

PROCEDURE get_occupation_list(
                             p_inst_code_in            IN       NUMBER,
                             p_delivery_channel_in     IN       VARCHAR2,
                             p_txn_code_in             IN       VARCHAR2,
                             p_rrn_in                  IN       VARCHAR2,
                             p_partner_id_in           IN       VARCHAR2,
                             p_trandate_in             IN       VARCHAR2,
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
                             p_resp_code_out           OUT      VARCHAR2,
                             p_respmsg_out             OUT      VARCHAR2,
                             p_occupation_array_out    OUT      VARCHAR2
                     )
AS
   l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
   l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
   l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
   l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
   l_timestamp         transactionlog.time_stamp%TYPE;
   l_occupation        vms_occupation_mast.vom_occu_name%TYPE;
   l_occupation_code   vms_occupation_mast.vom_occu_code%TYPE;
   l_errmsg            transactionlog.error_msg%TYPE;
   exp_reject_record   EXCEPTION;

   BEGIN
      BEGIN

         p_respmsg_out := 'success';
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
                                         p_tran_time_in,
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


    --SN : getting_occupation_details

       BEGIN
        FOR i IN (SELECT VOM_OCCU_NAME,VOM_OCCU_CODE from VMS_OCCUPATION_MAST)
        LOOP
                l_occupation :=i.VOM_OCCU_NAME;
                l_occupation_code :=i.VOM_OCCU_CODE;
                p_occupation_array_out := p_occupation_array_out||l_occupation_code||'|'||l_occupation||',';
        END LOOP;
                      EXCEPTION
              WHEN OTHERS THEN
              p_resp_code_out := '21';
              l_errmsg  := 'Error in Occupation array'||SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;


      END;
       --EN : getting_occupation_details

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
                                  p_tran_time_in,
                                  '00',
                                  NULL,
                                  NULL,
                                  l_errmsg,
                                  p_ip_addr_in,
                                  NULL,
                                  l_txn_desc,
                                  p_ani_in,
                                  p_dni_in,
                                  SYSTIMESTAMP,
                                  NULL,
                                  NULL,
                                  NULL,
                                  l_cr_dr_flag,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  p_resp_code_out,
                                  p_resp_code_out,
                                  p_curr_code_in,
                                  NULL,
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
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;

END get_occupation_list;

PROCEDURE get_identification_type(
    p_inst_code_in          	IN  NUMBER,
    p_delivery_channel_in   	IN  VARCHAR2,
    p_txn_code_in           	IN  VARCHAR2,
    p_rrn_in                	IN  VARCHAR2,
    p_partner_id_in         	IN  VARCHAR2,
    p_trandate_in           	IN  VARCHAR2,
    p_tran_time_in          	IN  VARCHAR2,
    p_curr_code_in          	IN  VARCHAR2,
    p_revrsl_code_in        	IN  VARCHAR2,
    p_msg_type_in           	IN  VARCHAR2,
    p_ip_addr_in            	IN  VARCHAR2,
    p_ani_in                	IN  VARCHAR2,
    p_dni_in                	IN  VARCHAR2,
    p_device_mobno_in       	IN  VARCHAR2,
    p_device_id_in          	IN  VARCHAR2,
    p_uuid_in               	IN  VARCHAR2,
    p_osname_in             	IN  VARCHAR2,
    p_osversion_in          	IN  VARCHAR2,
    p_gps_coordinates_in    	IN  VARCHAR2,
    p_display_resolution_in 	IN  VARCHAR2,
    p_physical_memory_in    	IN  VARCHAR2,
    p_appname_in            	IN  VARCHAR2,
    p_appversion_in         	IN  VARCHAR2,
    p_sessionid_in          	IN  VARCHAR2,
    p_device_country_in     	IN  VARCHAR2,
    p_device_region_in      	IN  VARCHAR2,
    p_ipcountry_in          	IN  VARCHAR2,
    p_proxy_flag_in         	IN  VARCHAR2,
    p_resp_code_out             OUT VARCHAR2,
    p_respmsg_out               OUT VARCHAR2,
    p_identification_array_out  OUT VARCHAR2 )
AS
  l_cr_dr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
  l_txn_type               cms_transaction_mast.ctm_tran_type%TYPE;
  l_txn_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
  l_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
  l_preauth_flag           cms_transaction_mast.ctm_preauth_flag%TYPE;
  l_login_txn              cms_transaction_mast.ctm_login_txn%TYPE;
  l_preauth_type           cms_transaction_mast.ctm_preauth_type%TYPE;
  l_dup_rrn_check          cms_transaction_mast.ctm_rrn_check%TYPE;
  l_timestamp              transactionlog.time_stamp%TYPE;
  l_identification_type    cms_idtype_mast.cim_idtype_code%TYPE;
  l_identification_desc    cms_idtype_mast.cim_idtype_desc%TYPE;
  l_identification_country VARCHAR2(50);
  l_errmsg                 transactionlog.error_msg%TYPE;
  exp_reject_record        EXCEPTION;
BEGIN
  BEGIN
    p_respmsg_out := 'success';
    BEGIN
      vmscommon.get_transaction_details (p_inst_code_in, p_delivery_channel_in, p_txn_code_in, l_cr_dr_flag, l_txn_type, l_txn_desc, l_prfl_flag, l_preauth_flag, l_login_txn, l_preauth_type, l_dup_rrn_check, p_resp_code_out, l_errmsg );
      IF p_resp_code_out <> '00' AND l_errmsg <> 'OK' THEN
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      p_resp_code_out := '12';
      l_errmsg        := 'Error from Transaction Details' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    -- En Transaction Details  procedure call
    -- Sn validating Date Time RRN
    IF l_dup_rrn_check = 'Y' THEN
      BEGIN
        vmscommon.validate_date_rrn (p_inst_code_in, p_rrn_in, p_trandate_in, p_tran_time_in, p_delivery_channel_in, l_errmsg, p_resp_code_out );
        IF p_resp_code_out <> '00' AND l_errmsg <> 'OK' THEN
          RAISE exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        p_resp_code_out := '22';
        l_errmsg        := 'Error while validating DATE and RRN' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
    END IF;
    -- En validating Date Time RRN
    --SN : getting_occupation_details
    BEGIN
      FOR i IN
      (SELECT cim_idtype_code ,
        cim_idtype_desc description,
        DECODE(cim_idtype_flag, 'U', 'USA','C','CANADA') country
      FROM cms_idtype_mast
      )
      LOOP
        l_identification_type    :=i.cim_idtype_code;
        l_identification_desc    :=i.description;
        l_identification_country :=i.country;
        p_identification_array_out   := p_identification_array_out||l_identification_type||'|'||l_identification_desc||'|'||l_identification_country||',';
      END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
      p_resp_code_out := '21';
      l_errmsg        := 'Error in Occupation array'||SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    --EN : getting_occupation_details
    p_resp_code_out := '1';
  EXCEPTION
  WHEN exp_reject_record THEN
    ROLLBACK;
  WHEN OTHERS THEN
    ROLLBACK;
    l_errmsg        := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
    p_resp_code_out := '89';
  END;
  BEGIN
    SELECT cms_iso_respcde
    INTO p_resp_code_out
    FROM cms_response_mast
    WHERE cms_inst_code      = p_inst_code_in
    AND cms_delivery_channel = p_delivery_channel_in
    AND cms_response_id      = TO_NUMBER (p_resp_code_out);
  EXCEPTION
  WHEN OTHERS THEN
    l_errmsg        := 'Problem while selecting respose code' || p_resp_code_out || ' is-' || SUBSTR (SQLERRM, 1, 300);
    p_resp_code_out := '69';
  END;
  l_timestamp        := SYSTIMESTAMP;
  IF p_resp_code_out <> '00' THEN
    p_respmsg_out    := l_errmsg;
  END IF;
  BEGIN
    vms_log.log_transactionlog (p_inst_code_in, p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_txn_code_in, l_txn_type, 0, p_trandate_in, p_tran_time_in, '00', NULL, NULL, l_errmsg, p_ip_addr_in, NULL, l_txn_desc, p_ani_in, p_dni_in, SYSTIMESTAMP, NULL, NULL, NULL, l_cr_dr_flag, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, p_resp_code_out, p_resp_code_out, p_curr_code_in, NULL, p_uuid_in, p_osname_in, p_osversion_in, p_gps_coordinates_in, p_display_resolution_in, p_physical_memory_in, p_appname_in, p_appversion_in, p_sessionid_in, p_device_country_in, p_device_region_in, p_ipcountry_in, p_proxy_flag_in, p_partner_id_in, l_errmsg );
  EXCEPTION
  WHEN OTHERS THEN
    p_resp_code_out := '69';
    p_respmsg_out        := 'Exception while inserting to transaction log ' || SUBSTR (SQLERRM, 1, 300);
  END;
END get_identification_type;


PROCEDURE  peer_to_peer_transfer (
                                  p_i_inst_code          IN       NUMBER,
                                  p_i_msg_type           IN       VARCHAR2,
                                  p_i_rrn                IN       VARCHAR2,
                                  p_i_delivery_channel   IN       VARCHAR2,
                                  p_i_txn_code           IN       VARCHAR2,
                                  p_i_txn_mode           IN       VARCHAR2,
                                  p_i_tran_date          IN       VARCHAR2,
                                  p_i_tran_time          IN       VARCHAR2,
                                  p_i_mbr_numb           IN       VARCHAR2,
                                  p_i_rvsl_code          IN       VARCHAR2,
                                  p_i_txn_amt            IN       NUMBER,
                                  p_i_cust_id            IN       NUMBER,
                                  p_i_pan_code           IN       VARCHAR2,
                                  p_i_hash_pan_code      IN       VARCHAR2,
                                  p_i_encr_pan_code      IN       VARCHAR2,
                                  p_i_proxy_number       IN       VARCHAR2,
                                  p_i_expry_date         IN       VARCHAR2,
                                  p_i_prod_code          IN       VARCHAR2,
                                  p_i_card_type          IN       VARCHAR2,
                                  p_i_card_stat          IN       VARCHAR2,
                                  p_i_acct_no            IN       VARCHAR2,
                                  p_i_profile_code       IN       VARCHAR2,
                                  p_i_curr_code          IN       VARCHAR2,
                                  p_i_partner_id         IN       VARCHAR2,
                                  p_i_remarks            IN       VARCHAR2,
                                  p_i_mobile_no          IN       VARCHAR2,
                                  p_i_device_id          IN       VARCHAR2,
                                  p_i_first_name         IN       VARCHAR2,
                                  p_i_last_name          IN       VARCHAR2,
                                  p_i_address_one        IN       VARCHAR2,
                                  p_i_city               IN       VARCHAR2,
                                  p_i_state              IN       VARCHAR2,
                                  p_i_postalCode         IN       VARCHAR2,
                                  p_i_countryCode        IN       VARCHAR2,
                                  p_i_transactionid      IN       VARCHAR2,
                                  p_o_resp_code          OUT      VARCHAR2,
                                  p_o_resmsg             OUT      VARCHAR2,
                                  p_o_balance            OUT      VARCHAR2
                                  )
       IS
      /************************************************************************************************************
       * Created Date     :  15-NOV-2018
       * Created By       :  VENEETHA C
       * Created For      :  VMS-630
       * Reviewer         :  Saravanakumar
       * Build Number     :  VMSGPRHOST_R08_B0002
	   
       * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
      ************************************************************************************************************/

      v_varchar2_txn_type              transactionlog.txn_type%TYPE;
      v_varchar2_auth_id               transactionlog.auth_id%TYPE;
      v_varchar2_dr_cr_flag            cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      v_varchar2_tran_type             cms_transaction_mast.ctm_tran_type%TYPE;
      v_number_tran_amt                cms_acct_mast.cam_acct_bal%TYPE;
      v_varchar2_hashkey_id            cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      v_varchar2_trans_desc            cms_transaction_mast.ctm_tran_desc%TYPE;
      v_char_prfl_flag                 cms_transaction_mast.ctm_prfl_flag%TYPE;
      v_varchar2_preauth_flag          cms_transaction_mast.ctm_preauth_flag%TYPE;
      v_number_acct_bal                cms_acct_mast.cam_acct_bal%TYPE;
      v_number_ledger_bal              cms_acct_mast.cam_ledger_bal%TYPE;
      v_number_acct_type               cms_acct_mast.cam_type_code%TYPE;
      v_varchar2_fee_code              transactionlog.feecode%TYPE;
      v_number_fee_plan                transactionlog.fee_plan%TYPE;
      v_varchar2_feeattach_type        transactionlog.feeattachtype%TYPE;
      v_number_tranfee_amt             transactionlog.tranfee_amt%TYPE;
      v_number_total_amt               cms_acct_mast.cam_acct_bal%TYPE;
      v_varchar2_comb_hash             pkg_limits_check.type_hash;
      v_varchar2_login_txn             cms_transaction_mast.ctm_login_txn%TYPE;
      v_varchar2_preauth_type          cms_transaction_mast.ctm_preauth_type%TYPE;
      v_date_expry_date                cms_appl_pan.cap_expry_date%TYPE;
      v_varchar2_dup_rrn_check         cms_transaction_mast.ctm_rrn_check%TYPE;
      v_varchar2_card_curr             pcms_exchangerate_mast.pem_curr_code%TYPE;
      v_date_tran_date                 DATE;
      v_varchar2_resp_cde              cms_response_mast.cms_response_id%TYPE;
      v_varchar2_err_msg               transactionlog.error_msg%TYPE;
      v_timestamp_time_stamp           transactionlog.time_stamp%TYPE;
      e_reject_record                  EXCEPTION;
         v_compl_fee varchar2(10);
   v_compl_feetxn_excd varchar2(10);
   v_compl_feecode varchar2(10);
     
   BEGIN
      v_varchar2_resp_cde := '1';
      v_timestamp_time_stamp := SYSTIMESTAMP;

      BEGIN

         --Start Generate HashKEY value
         BEGIN
            v_varchar2_hashkey_id :=
               gethash (   p_i_delivery_channel
                        || p_i_txn_code
                        || p_i_pan_code
                        || p_i_rrn
                        || TO_CHAR (v_timestamp_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_varchar2_resp_cde := '21';
               v_varchar2_err_msg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE e_reject_record;
         END;

         --End Generate HashKEY

         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn, ctm_preauth_type,ctm_rrn_check
              INTO v_varchar2_dr_cr_flag,
                   v_varchar2_txn_type,
                   v_varchar2_tran_type, v_varchar2_trans_desc, v_char_prfl_flag,
                   v_varchar2_preauth_flag, v_varchar2_login_txn, v_varchar2_preauth_type,v_varchar2_dup_rrn_check
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_i_txn_code
               AND ctm_delivery_channel = p_i_delivery_channel
               AND ctm_inst_code = p_i_inst_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_varchar2_resp_cde := '21';
               v_varchar2_err_msg := 'Error while selecting transaction details';
               RAISE e_reject_record;
         END;
         
        IF v_varchar2_dup_rrn_check = 'Y' THEN
            BEGIN
                vmscommon.validate_date_rrn (p_i_inst_code, 
                                             p_i_rrn,
                                             p_i_tran_date, 
                                             p_i_tran_time, 
                                             p_i_delivery_channel, 
                                             v_varchar2_err_msg, 
                                             v_varchar2_resp_cde );
                
                IF v_varchar2_resp_cde <> '00' AND v_varchar2_err_msg <> 'OK' 
                THEN
                    RAISE e_reject_record;
                END IF;
                
            EXCEPTION
            WHEN e_reject_record THEN
                RAISE;
            WHEN OTHERS THEN
                v_varchar2_resp_cde := '22';
                v_varchar2_err_msg        := 'Error while validating DATE and RRN' || SUBSTR (SQLERRM, 1, 200);
                RAISE e_reject_record;
            END;
        END IF;
    
         --En find debit and credit flag
    
         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO v_varchar2_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_varchar2_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               v_varchar2_resp_cde := '21';                        
               RAISE e_reject_record;
         END;

         --En generate auth id
         BEGIN
            v_date_tran_date :=
               TO_DATE (   SUBSTR (TRIM (p_i_tran_date), 1, 8)
                        || ' '
                        || SUBSTR (TRIM (p_i_tran_time), 1, 10),
                        'yyyymmdd hh24:mi:ss'
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_varchar2_resp_cde := '21';
               v_varchar2_err_msg :=
                     'Problem while converting transaction date '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE e_reject_record;
         END;

         -- To Convert Currency
         IF p_i_txn_amt IS NOT NULL
         THEN
            IF (p_i_txn_amt > 0)
            THEN
               v_number_tran_amt := p_i_txn_amt;

               BEGIN
                  sp_convert_curr (p_i_inst_code,
                                   p_i_curr_code,
                                   p_i_pan_code,
                                   p_i_txn_amt,
                                   v_date_tran_date,
                                   v_number_tran_amt,
                                   v_varchar2_card_curr,
                                   v_varchar2_err_msg,
                                   p_i_prod_code,
                                   p_i_card_type
                                  );

                  IF v_varchar2_err_msg <> 'OK'
                  THEN
                     v_varchar2_resp_cde := '21';
                     RAISE e_reject_record;
                  END IF;
               EXCEPTION
                  WHEN e_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_varchar2_resp_cde := '21';
                     v_varchar2_err_msg :=
                           'Error from currency conversion '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE e_reject_record;
               END;
            ELSE
               v_varchar2_resp_cde := '25';
               v_varchar2_err_msg := 'INVALID AMOUNT';
               RAISE e_reject_record;
            END IF;
         END IF;
         
         v_date_expry_date := to_date(substr(p_i_expry_date,1,10),'YYYY-MM-DD');

         -- End  Convert Currency
         
           BEGIN
            sp_cmsauth_check (p_i_inst_code,
                              p_i_msg_type,
                              p_i_rrn,
                              p_i_delivery_channel,
                              p_i_txn_code,
                              p_i_txn_mode,
                              p_i_tran_date,
                              p_i_tran_time,
                              p_i_mbr_numb,
                              p_i_rvsl_code,
                              v_varchar2_tran_type,
                              p_i_curr_code,
                              v_number_tran_amt,
                              p_i_pan_code,
                              p_i_hash_pan_code,
                              p_i_encr_pan_code,
                              p_i_CARD_STAT,
                              v_date_expry_date,
                              p_i_prod_code,
                              p_i_card_type,
                              v_char_prfl_flag,
                              p_i_profile_code,
                              NULL,
                              NULL,
                              NULL,
                              v_varchar2_resp_cde,
                              v_varchar2_err_msg,
                              v_varchar2_comb_hash
                             );

            IF v_varchar2_err_msg <> 'OK'
            THEN
               RAISE e_reject_record;
            END IF;
         EXCEPTION
            WHEN e_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_varchar2_resp_cde := '21';
               v_varchar2_err_msg :=
                     'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE e_reject_record;
         END;
        
         BEGIN
              SELECT cam_acct_bal,
                cam_ledger_bal,
                cam_type_code
              INTO v_number_acct_bal,
                v_number_ledger_bal,
                v_number_acct_type
              FROM cms_acct_mast
              WHERE cam_acct_no = p_i_acct_no
              AND cam_inst_code = p_i_inst_code FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_varchar2_resp_cde := '21';
               v_varchar2_err_msg :=
                     'Problem while selecting Account  detail '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE e_reject_record;
         END;

         BEGIN
            sp_fee_calc (p_i_inst_code,
                         p_i_msg_type,
                         p_i_rrn,
                         p_i_delivery_channel,
                         p_i_txn_code,
                         p_i_txn_mode,
                         p_i_tran_date,
                         p_i_tran_time,
                         p_i_mbr_numb,
                         p_i_rvsl_code,
                         v_varchar2_txn_type,
                         p_i_curr_code,
                         v_number_tran_amt,
                         p_i_pan_code,
                         p_i_hash_pan_code,
                         p_i_encr_pan_code,
                         p_i_acct_no,
                         p_i_prod_code,
                         p_i_card_type,
                         v_varchar2_preauth_flag,
                         NULL,
                         NULL,
                         NULL,
                         v_varchar2_trans_desc,
                         v_varchar2_dr_cr_flag,
                         v_number_acct_bal,
                         v_number_ledger_bal,
                         v_number_acct_type,
                         v_varchar2_login_txn,
                         v_varchar2_auth_id,
                         v_timestamp_time_stamp,
                         v_varchar2_resp_cde,
                         v_varchar2_err_msg,
                         v_varchar2_fee_code,
                         v_number_fee_plan,
                         v_varchar2_feeattach_type,
                         v_number_tranfee_amt,
                         v_number_total_amt,
                      v_compl_fee,
                      v_compl_feetxn_excd,
                      v_compl_feecode,
                         v_varchar2_preauth_type,
                         p_i_card_stat,
                         NULL
                        );

            IF v_varchar2_err_msg <> 'OK'
            THEN
               RAISE e_reject_record;
            END IF;
         EXCEPTION
            WHEN e_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_varchar2_resp_cde := '21';
               v_varchar2_err_msg :=
                       'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
               RAISE e_reject_record;
         END;
         
         IF p_i_profile_code IS NOT NULL AND v_char_prfl_flag = 'Y'
         THEN
            BEGIN
               pkg_limits_check.sp_limitcnt_reset (p_i_inst_code,
                                                   p_i_hash_pan_code,
                                                   v_number_tran_amt,
                                                   v_varchar2_comb_hash,
                                                   v_varchar2_resp_cde,
                                                   v_varchar2_err_msg
                                                  );

               IF v_varchar2_err_msg <> 'OK'
               THEN
                  v_varchar2_err_msg :=
                              'From Procedure sp_limitcnt_reset' || v_varchar2_err_msg;
                  RAISE e_reject_record;
               END IF;
            EXCEPTION
               WHEN e_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_varchar2_resp_cde := '21';
                  v_varchar2_err_msg :=
                        'Error from Limit Reset Count Process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE e_reject_record;
            END;
         END IF;
         
         BEGIN
              Insert into CMS_PAYMENT_INFO (CPI_INST_CODE,
                                            CPI_AUTH_ID,
                                            CPI_PAN_CODE,
                                            CPI_PAN_ENCR,
                                            CPI_RRN,
                                            CPI_PAYMENT_TYPE,
                                            CPI_UNIQUE_RN,
                                            CPI_SPU_ID,
                                            CPI_SP_ADD,
                                            CPI_ADD_SI,
                                            CPI_PAYER_ID,
                                            CPI_PAYER_ADD,
                                            CPI_PAYER_CITY,
                                            CPI_PAYER_STATE,
                                            CPI_PAYER_COUN,
                                            CPI_PAYER_ZIP,
                                            CPI_PAYER_DOB,
                                            CPI_REQ_DATE,
                                            CPI_REP_NAME,
                                            CPI_ADDIT_TRACNUM,
                                            CPI_FIRST_NAME,
                                            CPI_LAST_NAME) 
                                    values (p_i_inst_code,
                                            v_varchar2_auth_id,
                                            p_i_hash_pan_code,
                                            p_i_encr_pan_code,
                                            p_i_rrn,
                                            'C07',
                                            p_i_transactionid,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            p_i_address_one,
                                            p_i_city,
                                            p_i_state,
                                            p_i_countryCode,
                                            p_i_postalCode,
                                            NULL,
                                            null,
                                            NULL,
                                            NULL,
                                            p_i_first_name,
                                            p_i_last_name);
          EXCEPTION
             WHEN OTHERS
             THEN
                v_varchar2_err_msg :=
                      'Problem while inserting into CMS_PAYMENT_INFO '
                   || v_varchar2_resp_cde
                   || SUBSTR (SQLERRM, 1, 300);
                p_o_resp_code := '89';
          END;

         v_varchar2_resp_cde := '1';
         
      EXCEPTION
         WHEN e_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
            v_varchar2_resp_cde := '21';
            v_varchar2_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK;
      END;
      
    

      BEGIN
         SELECT cms_iso_respcde
           INTO p_o_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_i_inst_code
            AND cms_delivery_channel = p_i_delivery_channel
            AND cms_response_id = v_varchar2_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_varchar2_err_msg :=
                  'Problem while selecting data from response master '
               || v_varchar2_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_o_resp_code := '89';
      END;

       BEGIN
            SELECT TRIM(TO_CHAR (cam_acct_bal, '99999999999999990.99')),
              TRIM(TO_CHAR (cam_ledger_bal, '99999999999999990.99')),
              cam_type_code
            INTO v_number_acct_bal,
              v_number_ledger_bal,
              v_number_acct_type
            FROM cms_acct_mast
            WHERE cam_acct_no = p_i_acct_no
            AND cam_inst_code = p_i_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_number_acct_bal := 0;
            v_number_ledger_bal := 0;
      END;
      p_o_resmsg := v_varchar2_err_msg;
      p_o_balance := v_number_acct_bal;
  
      --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_i_inst_code,
                        p_i_msg_type,
                        p_i_rrn,
                        p_i_delivery_channel,
                        p_i_txn_code,
                        v_varchar2_txn_type,
                        p_i_txn_mode,
                        p_i_tran_date,
                        p_i_tran_time,
                        p_i_rvsl_code,
                        p_i_hash_pan_code,
                        p_i_encr_pan_code,
                        v_varchar2_err_msg,
                        NULL,
                        p_i_card_stat,
                        v_varchar2_trans_desc,
                        NULL,
                        NULL,
                        v_timestamp_time_stamp,
                        p_i_acct_no,
                        p_i_prod_code,
                        p_i_card_type,
                        v_varchar2_dr_cr_flag,
                        v_number_acct_bal,
                        v_number_ledger_bal,
                        v_number_acct_type,
                        p_i_proxy_number,
                        v_varchar2_auth_id,
                        v_number_tran_amt,
                        v_number_total_amt,
                        v_varchar2_fee_code,
                        v_number_tranfee_amt,
                        v_number_fee_plan,
                        v_varchar2_feeattach_type,
                        v_varchar2_resp_cde,
                        p_o_resp_code,
                        p_i_curr_code,
                        v_varchar2_err_msg,
                        NULL,
                        NULL,
                        p_i_remarks,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_i_partner_id
                       );
                       
      IF v_varchar2_err_msg <> 'OK'
      THEN
          p_o_resmsg :=v_varchar2_err_msg;
      END IF;
      
      EXCEPTION
         WHEN OTHERS
         THEN
            p_o_resp_code := '89';
            p_o_resmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         sp_log_txnlogdetl (p_i_inst_code,
                            p_i_msg_type,
                            p_i_rrn,
                            p_i_delivery_channel,
                            p_i_txn_code,
                            v_varchar2_txn_type,
                            p_i_txn_mode,
                            p_i_tran_date,
                            p_i_tran_time,
                            p_i_hash_pan_code,
                            p_i_encr_pan_code,
                            v_varchar2_err_msg,
                            p_i_acct_no,
                            v_varchar2_auth_id,
                            v_number_tran_amt,
                            p_i_mobile_no,
                            p_i_device_id,
                            v_varchar2_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_o_resp_code,
                            NULL,
                            NULL,
                            NULL,
                            v_varchar2_err_msg
                           );
                           
              IF v_varchar2_err_msg <> 'OK'
              THEN
                  p_o_resmsg :=v_varchar2_err_msg;
              END IF;               
      EXCEPTION
         WHEN OTHERS
         THEN
            p_o_resmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_o_resp_code := '89';
      END;

   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_o_resp_code := '69';                             
         p_o_resmsg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;

PROCEDURE  peer_to_peer_transfer_rvsl (
                                    p_i_inst_code          IN       NUMBER,
                                    p_i_msg_type           IN       VARCHAR2,
                                    p_i_rrn                IN       VARCHAR2,
                                    p_i_delivery_channel   IN       VARCHAR2,
                                    p_i_txn_code           IN       VARCHAR2,
                                    p_i_txn_mode           IN       VARCHAR2,
                                    p_i_tran_date          IN       VARCHAR2,
                                    p_i_tran_time          IN       VARCHAR2,
                                    p_i_mbr_numb           IN       VARCHAR2,
                                    p_i_rvsl_code          IN       VARCHAR2,
                                    p_i_txn_amt            IN       NUMBER,
                                    p_i_cust_id            IN       NUMBER,
                                    p_i_pan_code           IN       VARCHAR2,
                                    p_i_hash_pan_code      IN       VARCHAR2,
                                    p_i_encr_pan_code      IN       VARCHAR2,
                                    p_i_proxy_number       IN       VARCHAR2,
                                    p_i_expry_date         IN       VARCHAR2,
                                    p_i_prod_code          IN       VARCHAR2,
                                    p_i_card_type          IN       VARCHAR2,
                                    p_i_card_stat          IN       VARCHAR2,
                                    p_i_acct_no            IN       VARCHAR2,
                                    p_i_profile_code       IN       VARCHAR2,
                                    p_i_curr_code          IN       VARCHAR2,
                                    p_i_partner_id         IN       VARCHAR2,
                                    p_i_remarks            IN       VARCHAR2,
                                    p_i_mobile_no          IN       VARCHAR2,
                                    p_i_device_id          IN       VARCHAR2,
                                    p_i_first_name         IN       VARCHAR2,
                                    p_i_last_name          IN       VARCHAR2,
                                    p_i_address_one        IN       VARCHAR2,
                                    p_i_city               IN       VARCHAR2,
                                    p_i_state              IN       VARCHAR2,
                                    p_i_postalCode         IN       VARCHAR2,
                                    p_i_countryCode        IN       VARCHAR2,
				                    p_i_original_rrn       IN       VARCHAR2,
                                    p_i_transactionid      IN       VARCHAR2,
                                    p_o_resp_code          OUT      VARCHAR2,
                                    p_o_resmsg             OUT      VARCHAR2,
                                    p_o_balance            OUT      VARCHAR2
   )
   
   /******************************************************************************************
     * Modified By      : venkat Singamaneni
    * Modified Date    : 5-11-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jey
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
   *******************************************************************************************/
   
   IS
    
      v_var_err_msg                   transactionlog.error_msg%TYPE;
      v_var_txn_type                  transactionlog.txn_type%TYPE;
      v_var_auth_id                   transactionlog.auth_id%TYPE;
      v_num_tran_amt                  transactionlog. ACCT_BALANCE%TYPE;
      v_var_resp_cde                  cms_response_mast.cms_response_id%type;
      v_var_hashkey_id                cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      v_var_trans_desc                cms_transaction_mast.ctm_tran_desc%TYPE;
      v_char_prfl_flag                cms_transaction_mast.ctm_prfl_flag%TYPE;
      v_var_preauth_flag              cms_transaction_mast.ctm_preauth_flag%TYPE;
      v_num_acct_bal                  cms_acct_mast.cam_acct_bal%TYPE;
      v_num_ledger_bal                cms_acct_mast.cam_ledger_bal%TYPE;
      v_num_acct_type                 cms_acct_mast.cam_type_code%TYPE;
      v_var_fee_code                  transactionlog.feecode%TYPE;
      v_num_fee_plan                  transactionlog.fee_plan%TYPE;
      v_var_feeattach_type            transactionlog.feeattachtype%TYPE;
      v_num_tranfee_amt               transactionlog.tranfee_amt%TYPE;
      v_var_login_txn                 cms_transaction_mast.ctm_login_txn%TYPE;
      v_var_logdtl_resp               cms_transaction_log_dtl.ctd_req_resp_code%TYPE;
      v_date_tran_date                DATE;
      v_var_orgnl_del_chnl            transactionlog.delivery_channel%TYPE;
      v_var_orgnl_resp_code           transactionlog.response_code%TYPE;
      v_var_orgnl_txn_code            transactionlog.txn_code%TYPE;
      v_var_orgnl_txn_mode            transactionlog.txn_mode%TYPE;
      v_date_orgnl_business_date      transactionlog.business_date%TYPE;
      v_time_orgnl_business_time      transactionlog.business_time%TYPE;
      v_var_customer_card_no          transactionlog.customer_card_no%TYPE;
      v_var_orgnl_txn_feecode         cms_fee_mast.cfm_fee_code%TYPE;
      v_num_orgnltxn_totalfeeamt      transactionlog.tranfee_amt%TYPE;
      v_var_orgnl_txn_type            transactionlog.cr_dr_flag%TYPE;
      v_var_dr_cr_flag                transactionlog.cr_dr_flag%TYPE;
      v_date_rvsl_trandate            DATE;
      v_var_actual_feecode            transactionlog.feecode%TYPE;
      v_var_orgnl_tranfee_amt         transactionlog.tranfee_amt%TYPE;
      v_var_orgnl_srvtax_amt          transactionlog.servicetax_amt%TYPE;
      v_var_orgnl_cess_amt            transactionlog.cess_amt%TYPE;
      v_var_orgnl_trnfecr_actno       transactionlog.tranfee_cr_acctno%TYPE;
      v_var_orgnl_trnfedr_actno       transactionlog.tranfee_dr_acctno%TYPE;
      v_var_orgnl_st_calc_flag        transactionlog.tran_st_calc_flag%TYPE;
      v_var_orgnl_cesscalc_flag       transactionlog.tran_cess_calc_flag%TYPE;
      v_var_orgnl_st_cr_acctno        transactionlog.tran_st_cr_acctno%TYPE;
      v_var_orgnl_st_dr_acctno        transactionlog.tran_st_dr_acctno%TYPE;
      v_var_orgnl_cess_cractno        transactionlog.tran_cess_cr_acctno%TYPE;
      v_var_orgnl_cess_dractno        transactionlog.tran_cess_dr_acctno%TYPE;
      v_var_gl_upd_flag               transactionlog.gl_upd_flag%TYPE;
      v_var_tran_reverse_flag         transactionlog.tran_reverse_flag%TYPE;
      v_var_fee_narration             cms_statements_log.csl_trans_narrration%TYPE;
      v_var_tot_fee_amount            transactionlog.tranfee_amt%TYPE;
      v_var_tot_amount                transactionlog.amount%TYPE;
      v_var_orgnl_txn_fee_plan        transactionlog.fee_plan%TYPE;
      v_num_orgnl_fee_amt             cms_fee_mast.cfm_fee_amt%TYPE;
      v_var_tran_type                 cms_transaction_mast.ctm_tran_type%TYPE;
      v_date_add_ins_date             transactionlog.add_ins_date%TYPE;
      v_var_original_amnt             transactionlog.amount%TYPE;
      v_var_dup_rrn_check             cms_transaction_mast.ctm_rrn_check%TYPE;
      v_time_cutoff_time              cms_inst_param.cip_param_value% type;
      v_time_business_time            VARCHAR2(5);
      v_var_card_curr                 cms_bin_param.cbp_param_value%TYPE;
      v_var_max_card_bal              cms_acct_mast.cam_acct_bal%TYPE;
      v_timestamp_time_stamp          cms_statements_log.csl_time_stamp%TYPE;
      v_var_feecap_flag               cms_fee_mast.cfm_feecap_flag%type;
      exp_rvsl_reject_record          EXCEPTION;
	  
	  v_Retperiod  date;  --Added for VMS-5735/FSP-991
      v_Retdate  date; --Added for VMS-5735/FSP-991

       
      CURSOR v_cur_stmnts_log
      IS
         SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
                csl_merchant_state, csl_trans_amount
           FROM VMSCMS.CMS_STATEMENTS_LOG_VW                       --Added for VMS-5735/FSP-991
          WHERE csl_business_date = v_date_orgnl_business_date
            AND csl_rrn = p_i_rrn
            AND csl_delivery_channel = v_var_orgnl_del_chnl
            AND csl_txn_code = v_var_orgnl_txn_code
            AND csl_pan_no = v_var_customer_card_no
            AND csl_inst_code = p_i_inst_code
            AND txn_fee_flag = 'Y';
   BEGIN
      v_var_resp_cde := '1';
      v_timestamp_time_stamp := SYSTIMESTAMP;

      BEGIN
         --SAVEPOINT v_num_auth_savepoint;

         --Start Generate HashKEY value
         BEGIN
            v_var_hashkey_id :=
               gethash (   p_i_delivery_channel
                        || p_i_txn_code
                        || p_i_pan_code
                        || p_i_rrn
                        || TO_CHAR (v_timestamp_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --End Generate HashKEY

         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn,ctm_rrn_check
              INTO v_var_dr_cr_flag,
                   v_var_txn_type,
                   v_var_tran_type, v_var_trans_desc, v_char_prfl_flag,
                   v_var_preauth_flag, v_var_login_txn,v_var_dup_rrn_check
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_i_txn_code
               AND ctm_delivery_channel = p_i_delivery_channel
               AND ctm_inst_code = p_i_inst_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_var_resp_cde := '12';
               v_var_err_msg :=
                     'Transaction not defined for txn code '
                  || p_i_txn_code
                  || ' and delivery channel '
                  || p_i_delivery_channel;
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg := 'Error while selecting transaction details';
               RAISE exp_rvsl_reject_record;
         END;
     --En find debit and credit flag
     --Sn duplicate rrn 
  IF v_var_dup_rrn_check = 'Y' THEN
            BEGIN
                vmscommon.validate_date_rrn (p_i_inst_code, 
                                             p_i_rrn,
                                             p_i_tran_date, 
                                             p_i_tran_time, 
                                             p_i_delivery_channel, 
                                             v_var_err_msg, 
                                             v_var_resp_cde );
                
                IF v_var_resp_cde <> '00' AND v_var_err_msg <> 'OK' 
                THEN
                    RAISE exp_rvsl_reject_record;
                END IF;
                
            EXCEPTION
            WHEN exp_rvsl_reject_record THEN
                RAISE;
            WHEN OTHERS THEN
                v_var_resp_cde := '22';
                v_var_err_msg        := 'Error while validating DATE and RRN' || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_rvsl_reject_record;
            END;
        END IF;
     --En duplicate rrn
         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO v_var_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_var_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               v_var_resp_cde := '21';                        
               RAISE exp_rvsl_reject_record;
         END;

         --En generate auth id
         BEGIN
            v_date_rvsl_trandate :=
               TO_DATE (   SUBSTR (TRIM (p_i_tran_date), 1, 8)
                        || ' '
                        || SUBSTR (TRIM (p_i_tran_time), 1, 8),
                        'yyyymmdd hh24:mi:ss'
                       );
            v_date_tran_date := v_date_rvsl_trandate;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg :=
                     'Problem while converting transaction date '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Sn check msg type
         IF (p_i_msg_type <> '0400') OR (p_i_rvsl_code = '00')
         THEN
            v_var_resp_cde := '12';
            v_var_err_msg := 'Not a valid reversal request';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En check msg type
         
          --En check orginal transaction
              --Sn find the converted tran amt
         v_num_tran_amt := p_i_txn_amt;

         IF (p_i_txn_amt >= 0)
         THEN
         --Sn check orginal transaction
          BEGIN
            SELECT delivery_channel, response_code,
                   txn_code, txn_mode,
                   business_date, business_time,
                   customer_card_no, feecode,
                   fee_plan, tranfee_amt,
                   cr_dr_flag, feecode,
                   tranfee_amt, servicetax_amt,
                   cess_amt, tranfee_cr_acctno,
                   tranfee_dr_acctno, tran_st_calc_flag,
                   tran_cess_calc_flag, tran_st_cr_acctno,
                   tran_st_dr_acctno, tran_cess_cr_acctno,
                   tran_cess_dr_acctno, tran_reverse_flag,
                   gl_upd_flag, add_ins_date,AMOUNT
              INTO v_var_orgnl_del_chnl, v_var_orgnl_resp_code,
                   v_var_orgnl_txn_code, v_var_orgnl_txn_mode,
                   v_date_orgnl_business_date, v_time_orgnl_business_time,
                   v_var_customer_card_no, v_var_orgnl_txn_feecode,
                   v_var_orgnl_txn_fee_plan, v_num_orgnltxn_totalfeeamt,
                   v_var_orgnl_txn_type, v_var_actual_feecode,
                   v_var_orgnl_tranfee_amt, v_var_orgnl_srvtax_amt,
                   v_var_orgnl_cess_amt, v_var_orgnl_trnfecr_actno,
                   v_var_orgnl_trnfedr_actno, v_var_orgnl_st_calc_flag,
                   v_var_orgnl_cesscalc_flag, v_var_orgnl_st_cr_acctno,
                   v_var_orgnl_st_dr_acctno, v_var_orgnl_cess_cractno,
                   v_var_orgnl_cess_dractno, v_var_tran_reverse_flag,
                   v_var_gl_upd_flag, v_date_add_ins_date,v_var_original_amnt
              FROM VMSCMS.TRANSACTIONLOG_VW                              --Added for VMS-5735/FSP-991
             WHERE rrn = p_i_original_rrn
             --  AND AMOUNT = v_num_tran_amt
               AND customer_card_no = p_i_hash_pan_code
               AND instcode = p_i_inst_code
               AND delivery_channel = p_i_delivery_channel
               AND txn_code = p_i_txn_code
               AND msgtype='0200';


            IF v_var_orgnl_resp_code <> '00'
            THEN
               v_var_resp_cde := '23';
               v_var_err_msg := ' The original transaction was not successful';
               RAISE exp_rvsl_reject_record;
            END IF;


              if v_var_original_amnt <> v_num_tran_amt
              then
               v_var_resp_cde := '25';
              v_var_err_msg := 'INVALID AMOUNT';
            RAISE exp_rvsl_reject_record;
         END IF;
              
            IF v_var_tran_reverse_flag = 'Y'
            THEN
               v_var_resp_cde := '52';
               v_var_err_msg :=
                      'The reversal already done for the orginal transaction';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN NO_DATA_FOUND
            THEN
               v_var_resp_cde := '53';
               v_var_err_msg := 'Matching transaction not found';
               RAISE exp_rvsl_reject_record;
            WHEN TOO_MANY_ROWS
            THEN
               BEGIN
                  SELECT SUM (tranfee_amt), SUM (amount)
                    INTO v_var_tot_fee_amount, v_var_tot_amount
                    FROM VMSCMS.TRANSACTIONLOG_VW                  --Added for VMS-5735/FSP-991
                   WHERE rrn = p_i_original_rrn
                     AND customer_card_no = p_i_hash_pan_code
                     AND instcode = p_i_inst_code
                     AND response_code = '00';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_var_resp_cde := '21';
                     v_var_err_msg :=
                           'Error while selecting TRANSACTIONLOG '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;

               IF (v_var_tot_fee_amount IS NULL) AND (v_var_tot_amount IS NULL)
               THEN
                  v_var_resp_cde := '21';
                  v_var_err_msg :=
                     'More than one failure matching record found in the master';
                  RAISE exp_rvsl_reject_record;
                 END IF;
                  BEGIN
                     SELECT delivery_channel, response_code,
                            txn_code, txn_mode,
                            business_date, business_time,
                            customer_card_no, feecode,
                            fee_plan, tranfee_amt,
                            cr_dr_flag, feecode,
                            tranfee_amt, servicetax_amt,
                            cess_amt, tranfee_cr_acctno,
                            tranfee_dr_acctno, tran_st_calc_flag,
                            tran_cess_calc_flag, tran_st_cr_acctno,
                            tran_st_dr_acctno, tran_cess_cr_acctno,
                            tran_cess_dr_acctno, tran_reverse_flag,
                            gl_upd_flag, add_ins_date,AMOUNT
                       INTO v_var_orgnl_del_chnl, v_var_orgnl_resp_code,
                            v_var_orgnl_txn_code, v_var_orgnl_txn_mode,
                            v_date_orgnl_business_date, v_time_orgnl_business_time,
                            v_var_customer_card_no, v_var_orgnl_txn_feecode,
                            v_var_orgnl_txn_fee_plan, v_num_orgnltxn_totalfeeamt,
                            v_var_orgnl_txn_type, v_var_actual_feecode,
                            v_var_orgnl_tranfee_amt, v_var_orgnl_srvtax_amt,
                            v_var_orgnl_cess_amt, v_var_orgnl_trnfecr_actno,
                            v_var_orgnl_trnfedr_actno, v_var_orgnl_st_calc_flag,
                            v_var_orgnl_cesscalc_flag, v_var_orgnl_st_cr_acctno,
                            v_var_orgnl_st_dr_acctno, v_var_orgnl_cess_cractno,
                            v_var_orgnl_cess_dractno, v_var_tran_reverse_flag,
                            v_var_gl_upd_flag, v_date_add_ins_date,v_var_original_amnt
                      
					  FROM VMSCMS.TRANSACTIONLOG_VW                          --Added for VMS-5735/FSP-991
                      
					  WHERE rrn = p_i_original_rrn
                        AND customer_card_no = p_i_hash_pan_code
                        AND instcode = p_i_inst_code
                        AND response_code = '00'
                        AND delivery_channel = p_i_delivery_channel
                        AND txn_code = p_i_txn_code
                        AND msgtype='0200'
                        AND ROWNUM = 1;

                     v_num_orgnltxn_totalfeeamt := v_var_tot_fee_amount;
                     v_var_orgnl_tranfee_amt := v_var_tot_fee_amount;
                   EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_var_resp_cde := '21';
                        v_var_err_msg := 'NO DATA IN TRANSACTIONLOG2';
                        RAISE exp_rvsl_reject_record;
                     WHEN OTHERS
                     THEN
                        v_var_resp_cde := '21';
                        v_var_err_msg :=
                              'Error while selecting TRANSACTIONLOG2 '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_rvsl_reject_record;
                  END;

                  --Added to check the reversal already done
                  IF v_var_tran_reverse_flag = 'Y'
                  THEN
                     v_var_resp_cde := '52';
                     v_var_err_msg :=
                        'The reversal already done for the orginal transaction';
                     RAISE exp_rvsl_reject_record;
                  END IF;
               --END IF;
            WHEN OTHERS
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg :=
                     'Error while selecting master data'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

        
          ---Sn check card number
         IF v_var_customer_card_no <> p_i_hash_pan_code
         THEN
            v_var_resp_cde := '21';
            v_var_err_msg :=
               'Customer card number is not matching in reversal and orginal transaction';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En check card number
         

         --Sn Check the Flag for Reversal transaction
         
            IF v_var_dr_cr_flag = 'NA'
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg := 'Not a valid orginal transaction for reversal';
               RAISE exp_rvsl_reject_record;
            END IF;
         

         --En Check the Flag for Reversal transaction
          --Sn Check the transaction type with Original txn type
         IF v_var_dr_cr_flag <> v_var_orgnl_txn_type
         THEN
            v_var_resp_cde := '21';
            v_var_err_msg :=
               'Orginal transaction type is not matching with actual transaction type';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En Check the transaction type
         
            BEGIN
               sp_convert_curr (p_i_inst_code,
                                p_i_curr_code,
                                p_i_pan_code,
                                p_i_txn_amt,
                                v_date_rvsl_trandate,
                                v_num_tran_amt,
                                v_var_card_curr,
                                v_var_err_msg,
						        p_i_prod_code,
						        p_i_card_type
                               );

               IF v_var_err_msg <> 'OK'
               THEN
                  v_var_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_var_resp_cde := '21';              
                  v_var_err_msg :=
                        'Error from currency conversion '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         ELSE
            v_var_resp_cde := '25';
            v_var_err_msg := 'INVALID AMOUNT';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En find the  converted tran amt
         
         
        
         ---Sn find cutoff time
         BEGIN
            SELECT cip_param_value
              INTO v_time_cutoff_time
              FROM cms_inst_param
             WHERE cip_param_key = 'CUTOFF' AND cip_inst_code = p_i_inst_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_time_cutoff_time := 0;
               v_var_resp_cde := '21';
               v_var_err_msg := 'Cutoff time is not defined in the system';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg := 'Error while selecting cutoff  dtl  from system ';
               RAISE exp_rvsl_reject_record;
         END;

         ---En find cutoff time
         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO v_num_acct_bal, v_num_ledger_bal, v_num_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = p_i_acct_no
                   AND cam_inst_code = p_i_inst_code
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg :=
                     'Problem while selecting Account detail '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Sn Check for maximum card balance configured for the product profile.
         
        IF v_var_dr_cr_flag = 'DR' AND p_i_rvsl_code <>0 THEN 
         
         BEGIN
            SELECT TO_NUMBER (cbp_param_value)
              INTO v_var_max_card_bal
              FROM cms_bin_param
             WHERE cbp_inst_code = p_i_inst_code
               AND cbp_param_name = 'Max Card Balance'
               AND cbp_profile_code IN (
                      SELECT cpc_profile_code
                        FROM cms_prod_cattype
                       WHERE cpc_inst_code = p_i_inst_code
                         AND cpc_prod_code = p_i_prod_code
                         AND cpc_card_type = p_i_card_type);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg :=
                     'NO CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg :=
                     'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;
         
        

     IF ((v_num_acct_bal + (p_i_txn_amt + v_num_orgnltxn_totalfeeamt)) >v_var_max_card_bal) OR
        ((v_num_ledger_bal + (p_i_txn_amt + v_num_orgnltxn_totalfeeamt)) >v_var_max_card_bal) THEN
        
         v_var_resp_cde := '30';
         v_var_err_msg :='Exceeding Maximum Card Balance '|| SUBSTR (SQLERRM, 1, 200);
              
        RAISE exp_rvsl_reject_record;
         
         END IF;
         
  END IF;

         -- En Check for maximum card balance configured for the product profile.
      
      
            BEGIN
               sp_reverse_card_amount (p_i_inst_code,
                                       NULL,
                                       p_i_rrn,
                                       p_i_delivery_channel,
                                       NULL,
                                       NULL,
                                       p_i_txn_code,
                                       v_date_rvsl_trandate,
                                       p_i_txn_mode,
                                       p_i_pan_code,
                                       p_i_txn_amt,
                                       p_i_original_rrn,
                                       p_i_acct_no,
                                       p_i_tran_date,
                                       p_i_tran_time,
                                       v_var_auth_id,
                                       v_var_trans_desc,
                                       v_date_orgnl_business_date,
                                       v_time_orgnl_business_time,
                                       NULL,
                                       NULL,
                                       NULL,
                                       v_var_resp_cde,
                                       v_var_err_msg
                                      );

               IF v_var_resp_cde <> '00' OR v_var_err_msg <> 'OK'
               THEN
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_var_resp_cde := '21';
                  v_var_err_msg :=
                        'Error while reversing the amount '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         --En reverse the amount
       

         --Added For Reversal Fees

            IF v_num_orgnltxn_totalfeeamt > 0
               OR v_var_orgnl_txn_feecode IS NOT NULL
            THEN
               BEGIN
                  SELECT cfm_feecap_flag, cfm_fee_amt
                    INTO v_var_feecap_flag, v_num_orgnl_fee_amt
                    FROM cms_fee_mast
                   WHERE cfm_inst_code = p_i_inst_code
                     AND cfm_fee_code = v_var_orgnl_txn_feecode;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_var_feecap_flag := NULL;
                  WHEN OTHERS
                  THEN
                     v_var_err_msg :=
                           'Error in feecap flag fetch '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;

               BEGIN
                  FOR v_row_idx IN v_cur_stmnts_log
                  LOOP
                     v_var_orgnl_tranfee_amt := v_row_idx.csl_trans_amount;

                     IF v_var_feecap_flag = 'Y'
                     THEN
                        BEGIN
                           sp_tran_fees_revcapcheck (p_i_inst_code,
                                                     p_i_acct_no,
                                                     v_date_orgnl_business_date,
                                                     v_var_orgnl_tranfee_amt,
                                                     v_num_orgnl_fee_amt,
                                                     v_var_orgnl_txn_fee_plan,
                                                     v_var_orgnl_txn_feecode,
                                                     v_var_err_msg
                                                    );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_var_resp_cde := '21';
                              v_var_err_msg :=
                                    'Error while reversing the fee Cap amount '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_rvsl_reject_record;
                        END;
                     END IF;

                     BEGIN
                        sp_reverse_fee_amount (p_i_inst_code,
                                               p_i_rrn,
                                               p_i_delivery_channel,
                                               NULL,
                                               NULL,
                                               p_i_txn_code,
                                               v_date_rvsl_trandate,
                                               p_i_txn_mode,
                                               v_var_orgnl_tranfee_amt,
                                               p_i_pan_code,
                                               v_var_actual_feecode,
                                               v_var_orgnl_tranfee_amt,
                                               v_var_orgnl_trnfecr_actno,
                                               v_var_orgnl_trnfedr_actno,
                                               v_var_orgnl_st_calc_flag,
                                               v_var_orgnl_srvtax_amt,
                                               v_var_orgnl_st_cr_acctno,
                                               v_var_orgnl_st_dr_acctno,
                                               v_var_orgnl_cesscalc_flag,
                                               v_var_orgnl_cess_amt,
                                               v_var_orgnl_cess_cractno,
                                               v_var_orgnl_cess_dractno,
                                               p_i_original_rrn,
                                               p_i_acct_no,
                                               p_i_tran_date,
                                               p_i_tran_time,
                                               v_var_auth_id,
                                               v_row_idx.csl_trans_narrration,
                                               NULL,
                                               NULL,
                                               NULL,
                                               v_var_resp_cde,
                                               v_var_err_msg
                                              );
                        v_var_fee_narration := v_row_idx.csl_trans_narrration;

                        IF v_var_resp_cde <> '00' OR v_var_err_msg <> 'OK'
                        THEN
                           RAISE exp_rvsl_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_rvsl_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_var_resp_cde := '21';
                           v_var_err_msg :=
                                 'Error while reversing the fee amount '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_rvsl_reject_record;
                     END;
                  END LOOP;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_var_fee_narration := NULL;
                  WHEN OTHERS
                  THEN
                     v_var_fee_narration := NULL;
               END;


            --Added For Reversal Fees
            IF v_var_fee_narration IS NULL
            THEN
               IF v_var_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_revcapcheck (p_i_inst_code,
                                               p_i_acct_no,
                                               v_date_orgnl_business_date,
                                               v_var_orgnl_tranfee_amt,
                                               v_num_orgnl_fee_amt,
                                               v_var_orgnl_txn_fee_plan,
                                               v_var_orgnl_txn_feecode,
                                               v_var_err_msg
                                              );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_var_resp_cde := '21';
                        v_var_err_msg :=
                              'Error while reversing the fee Cap amount '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_rvsl_reject_record;
                  END;
               END IF;

               BEGIN
                  sp_reverse_fee_amount (p_i_inst_code,
                                         p_i_rrn,
                                         p_i_delivery_channel,
                                         NULL,
                                         NULL,
                                         p_i_txn_code,
                                         v_date_rvsl_trandate,
                                         p_i_txn_mode,
                                         v_num_orgnltxn_totalfeeamt,
                                         p_i_pan_code,
                                         v_var_actual_feecode,
                                         v_var_orgnl_tranfee_amt,
                                         v_var_orgnl_trnfecr_actno,
                                         v_var_orgnl_trnfedr_actno,
                                         v_var_orgnl_st_calc_flag,
                                         v_var_orgnl_srvtax_amt,
                                         v_var_orgnl_st_cr_acctno,
                                         v_var_orgnl_st_dr_acctno,
                                         v_var_orgnl_cesscalc_flag,
                                         v_var_orgnl_cess_amt,
                                         v_var_orgnl_cess_cractno,
                                         v_var_orgnl_cess_dractno,
                                         p_i_original_rrn,
                                         p_i_acct_no,
                                         p_i_tran_date,
                                         p_i_tran_time,
                                         v_var_auth_id,
                                         v_var_fee_narration,
                                         NULL,
                                         NULL,
                                         NULL,
                                         v_var_resp_cde,
                                         v_var_err_msg
                                        );

                  IF v_var_resp_cde <> '00' OR v_var_err_msg <> 'OK'
                  THEN
                     RAISE exp_rvsl_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_rvsl_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_var_resp_cde := '21';
                     v_var_err_msg :=
                           'Error while reversing the fee amount '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END IF;
         END IF;

         --En reverse the fee
         IF v_var_gl_upd_flag = 'Y'
         THEN
            --Sn find business date
            v_time_business_time := TO_CHAR (v_date_rvsl_trandate, 'HH24:MI');

            IF v_time_business_time > v_time_cutoff_time
            THEN
               v_date_rvsl_trandate := TRUNC (v_date_rvsl_trandate) + 1;
            ELSE
               v_date_rvsl_trandate := TRUNC (v_date_rvsl_trandate);
            END IF;
         --En find businesses date
         END IF;

         v_var_resp_cde := '1';

         BEGIN
		 
		    --Added for VMS-5735/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_i_tran_date), 1, 8), 'yyyymmdd');
		 
		 IF (v_Retdate>v_Retperiod) THEN                                --Added for VMS-5735/FSP-991
		 
            UPDATE cms_statements_log
               SET csl_prod_code = p_i_prod_code,
                    csl_card_type=p_i_card_type,
                   csl_acct_no = p_i_acct_no,
                   csl_time_stamp = v_timestamp_time_stamp
             WHERE csl_inst_code = p_i_inst_code
               AND csl_pan_no = p_i_hash_pan_code
               AND csl_rrn = p_i_rrn
               AND csl_txn_code = p_i_txn_code
               AND csl_delivery_channel = p_i_delivery_channel
               AND csl_business_date = p_i_tran_date
               AND csl_business_time = p_i_tran_time;
			   
	    ELSE
		        UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST         --Added for VMS-5735/FSP-991
                SET csl_prod_code = p_i_prod_code,
                    csl_card_type=p_i_card_type,
                    csl_acct_no = p_i_acct_no,
                    csl_time_stamp = v_timestamp_time_stamp
                WHERE csl_inst_code = p_i_inst_code
                AND csl_pan_no = p_i_hash_pan_code
                AND csl_rrn = p_i_rrn
                AND csl_txn_code = p_i_txn_code
                AND csl_delivery_channel = p_i_delivery_channel
                AND csl_business_date = p_i_tran_date
                AND csl_business_time = p_i_tran_time;
		
		END IF;

         EXCEPTION
            WHEN OTHERS
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg :=
                     'Error while updating timestamp in statementlog-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Sn update reverse flag
         BEGIN
		 
		 
				 --Added for VMS-5735/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(v_date_orgnl_business_date), 1, 8), 'yyyymmdd');
		   
		   
        IF (v_Retdate>v_Retperiod) THEN                        --Added for VMS-5735/FSP-991
		
            UPDATE transactionlog
               SET tran_reverse_flag = 'Y'
             WHERE rrn = p_i_original_rrn
               AND business_date = v_date_orgnl_business_date
               AND business_time = v_time_orgnl_business_time
               AND customer_card_no = p_i_hash_pan_code
               AND instcode = p_i_inst_code;
	    
		ELSE 
               UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST     --Added for VMS-5735/FSP-991
               SET tran_reverse_flag = 'Y'
               WHERE rrn = p_i_original_rrn
               AND business_date = v_date_orgnl_business_date
               AND business_time = v_time_orgnl_business_time
               AND customer_card_no = p_i_hash_pan_code
               AND instcode = p_i_inst_code;		
		
		
	    END IF;

            IF SQL%ROWCOUNT = 0
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg := 'Reverse flag is not updated ';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_var_resp_cde := '21';
               v_var_err_msg :=
                  'Error while updating gl flag ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

          --En update reverse flag
          
          IF v_num_orgnltxn_totalfeeamt=0 AND v_var_orgnl_txn_feecode IS NOT NULL THEN
            BEGIN
               vmsfee.fee_freecnt_reverse (p_i_acct_no, v_var_orgnl_txn_feecode, v_var_err_msg);
            
               IF v_var_err_msg <> 'OK' THEN
                  v_var_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record THEN
                  RAISE;
               WHEN OTHERS THEN
                  v_var_resp_cde := '21';
                  v_var_err_msg :='Error while reversing freefee count-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
          END IF;          
         --Sn Added  for enabling limit validation
         IF     v_date_add_ins_date IS NOT NULL
            AND p_i_profile_code IS NOT NULL
            AND v_char_prfl_flag = 'Y'
         THEN
            BEGIN
               pkg_limits_check.sp_limitcnt_rever_reset (p_i_inst_code,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         p_i_txn_code,
                                                         v_var_tran_type,
                                                         NULL,
                                                         NULL,
                                                         p_i_profile_code,
                                                         v_num_tran_amt,
                                                         v_num_tran_amt,
                                                         p_i_delivery_channel,
                                                         p_i_hash_pan_code,
                                                         v_date_add_ins_date,
                                                         v_var_resp_cde,
                                                         v_var_err_msg
                                                        );

               IF v_var_err_msg <> 'OK'
               THEN
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_var_resp_cde := '21';
                  v_var_err_msg :=
                        'Error from Limit count rever Process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;
         
      --START Condition added for Mantis id:0016259
      IF v_var_dr_cr_flag = 'CR' THEN
      v_var_dr_cr_flag := 'DR';
      ELSE
      v_var_dr_cr_flag := 'CR';
      END IF;
      --END Condition Added for Mantis id:0016259
      
      
         
         BEGIN
              Insert into CMS_PAYMENT_INFO (CPI_INST_CODE,
                                            CPI_AUTH_ID,
                                            CPI_PAN_CODE,
                                            CPI_PAN_ENCR,
                                            CPI_RRN,
                                            CPI_PAYMENT_TYPE,
                                            CPI_UNIQUE_RN,
                                            CPI_SPU_ID,
                                            CPI_SP_ADD,
                                            CPI_ADD_SI,
                                            CPI_PAYER_ID,
                                            CPI_PAYER_ADD,
                                            CPI_PAYER_CITY,
                                            CPI_PAYER_STATE,
                                            CPI_PAYER_COUN,
                                            CPI_PAYER_ZIP,
                                            CPI_PAYER_DOB,
                                            CPI_REQ_DATE,
                                            CPI_REP_NAME,
                                            CPI_ADDIT_TRACNUM,
                                            CPI_FIRST_NAME,
                                            CPI_LAST_NAME) 
                                    values (p_i_inst_code,
                                            v_var_auth_id,
                                            p_i_hash_pan_code,
                                            p_i_encr_pan_code,
                                            p_i_rrn,
                                            'C07',
                                            p_i_transactionid,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            p_i_address_one,
                                            p_i_city,
                                            p_i_state,
                                            p_i_countryCode,
                                            p_i_postalCode,
                                            NULL,
                                            null,
                                            NULL,
                                            NULL,
                                            p_i_first_name,
                                            p_i_last_name);
          EXCEPTION
             WHEN OTHERS
             THEN
                v_var_err_msg :=
                      'Problem while inserting into CMS_PAYMENT_INFO '
                   || v_var_resp_cde
                   || SUBSTR (SQLERRM, 1, 300);
                p_o_resp_code := '89';
          END;

  
      EXCEPTION
         WHEN exp_rvsl_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
            v_var_resp_cde := '21';
            v_var_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK;
      END;

      --Sn Get responce code from master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_o_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_i_inst_code
            AND cms_delivery_channel = p_i_delivery_channel
            AND cms_response_id = v_var_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_var_err_msg :=
                  'Problem while selecting data from response master '
               || v_var_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_o_resp_code := '89';
      END;


      BEGIN
         SELECT TRIM(TO_CHAR (cam_acct_bal, '99999999999999990.99')),
              TRIM(TO_CHAR (cam_ledger_bal, '99999999999999990.99')), cam_type_code
           INTO v_num_acct_bal, v_num_ledger_bal, v_num_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = p_i_acct_no AND cam_inst_code = p_i_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_num_acct_bal := 0;
            v_num_ledger_bal := 0;
      END;
      p_o_resmsg :=v_var_err_msg;
      p_o_balance := v_num_acct_bal;
      
      IF v_var_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag
              INTO v_var_dr_cr_flag,
                   v_var_txn_type,
                   v_var_tran_type, v_var_trans_desc, v_char_prfl_flag,
                   v_var_preauth_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_i_txn_code
               AND ctm_delivery_channel = p_i_delivery_channel
               AND ctm_inst_code = p_i_inst_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
 
      --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_i_inst_code,
                        p_i_msg_type,
                        p_i_rrn,
                        p_i_delivery_channel,
                        p_i_txn_code,
                        v_var_txn_type,
                        p_i_txn_mode,
                        p_i_tran_date,
                        p_i_tran_time,
                        p_i_rvsl_code,
                        p_i_hash_pan_code,
                        p_i_encr_pan_code,
                        v_var_err_msg,
                        NULL,
                        p_i_card_stat,
                        v_var_trans_desc,
                        NULL,
                        NULL,
                        v_timestamp_time_stamp,
                        p_i_acct_no,
                        p_i_prod_code,
                        p_i_card_type,
                        v_var_dr_cr_flag,
                        v_num_acct_bal,
                        v_num_ledger_bal,
                        v_num_acct_type,
                        p_i_proxy_number,
                        v_var_auth_id,
                        v_num_tran_amt,
                        v_num_tran_amt
                        + NVL (v_num_orgnltxn_totalfeeamt, 0),
                        v_var_fee_code,
                        v_num_tranfee_amt,
                        v_num_fee_plan,
                        v_var_feeattach_type,
                        v_var_resp_cde,
                        p_o_resp_code,
                        p_i_curr_code,
                        v_var_err_msg,
                        p_i_original_rrn,
                        NULL,
                        p_i_remarks,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_i_partner_id
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_o_resp_code := '89';
            v_var_err_msg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --En Inserting data in transactionlog
      --Sn Inserting data in transactionlog dtl
      BEGIN
         sp_log_txnlogdetl (p_i_inst_code,
                            p_i_msg_type,
                            p_i_rrn,
                            p_i_delivery_channel,
                            p_i_txn_code,
                            v_var_txn_type,
                            p_i_txn_mode,
                            p_i_tran_date,
                            p_i_tran_time,
                            p_i_hash_pan_code,
                            p_i_encr_pan_code,
                            v_var_err_msg,
                            p_i_acct_no,
                            v_var_auth_id,
                             v_num_tran_amt,
                            p_i_mobile_no,
                            p_i_device_id,
                            v_var_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_o_resp_code,
                            NULL,
                            NULL,
                            NULL,
                            v_var_logdtl_resp
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_var_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_o_resp_code := '89';
      END;

    p_o_resmsg := v_var_err_msg;
      
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_o_resp_code := '69';                              -- Server Declined
         p_o_resmsg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END peer_to_peer_transfer_rvsl;
   

PROCEDURE        reset_password (
   p_i_inst_code            IN       NUMBER,
   p_i_delivery_chnl        IN       VARCHAR2,
   p_i_txn_code             IN       VARCHAR2,
   p_i_rrn                  IN       VARCHAR2,
   p_i_partner_id           IN       VARCHAR2,
   p_i_tran_date            IN       VARCHAR2,
   p_i_tran_time            IN       VARCHAR2,
   p_i_curr_code            IN       VARCHAR2,
   p_i_revrsl_code          IN       VARCHAR2,
   p_i_msg_type             IN       VARCHAR2,
   p_i_ip_addr              IN       VARCHAR2,
   p_i_ani                  IN       VARCHAR2,
   p_i_dni                  IN       VARCHAR2,
   p_i_device_mobno         IN       VARCHAR2,
   p_i_device_id            IN       VARCHAR2,
   p_i_uuid                 IN       VARCHAR2,
   p_i_osname               IN       VARCHAR2,
   p_i_osversion            IN       VARCHAR2,
   p_i_gps_coordinates      IN       VARCHAR2,
   p_i_display_resolution   IN       VARCHAR2,
   p_i_physical_memory      IN       VARCHAR2,
   p_i_appname              IN       VARCHAR2,
   p_i_appversion           IN       VARCHAR2,
   p_i_sessionid            IN       VARCHAR2,
   p_i_device_country       IN       VARCHAR2,
   p_i_device_region        IN       VARCHAR2,
   p_i_ipcountry            IN       VARCHAR2,
   p_i_proxy_flag           IN       VARCHAR2,
   p_i_pan_code             IN       VARCHAR2,
   p_i_orgRRN               IN       VARCHAR2,
   p_i_password             IN       VARCHAR2,
   p_o_resp_code            OUT      VARCHAR2,
   p_o_resp_msg             OUT      VARCHAR2
)
AS
   v_var_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
   v_var_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_var_acct_no           cms_acct_mast.cam_acct_no%TYPE;
   v_num_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
   v_num_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   v_var_prod_code         cms_appl_pan.cap_prod_code%TYPE;
   v_var_prod_cattype      cms_appl_pan.cap_card_type%TYPE;
   v_var_card_stat         cms_appl_pan.cap_card_stat%TYPE;
   v_date_expry_date        cms_appl_pan.cap_expry_date%TYPE;
   v_date_active_date       cms_appl_pan.cap_expry_date%TYPE;
   v_var_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
   v_var_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_var_tran_type          cms_transaction_mast.ctm_tran_type%TYPE;
   v_var_trans_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
   v_char_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_var_comb_hash         pkg_limits_check.type_hash;
   v_var_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
   v_var_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
   v_num_acct_type         cms_acct_mast.cam_type_code%TYPE;
   v_var_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
   v_var_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
   v_num_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
   v_var_feeattach_type    transactionlog.feeattachtype%TYPE;
   v_num_tranfee_amt       transactionlog.tranfee_amt%TYPE;
   v_num_total_amt         cms_acct_mast.cam_acct_bal%TYPE;
   v_var_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
   v_var_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_var_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
   v_var_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
   v_var_appl_code         cms_appl_pan.cap_appl_code%TYPE;
   v_var_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   v_timestamp_time_stamp  transactionlog.time_stamp%TYPE;
   v_var_errmsg            transactionlog.error_msg%TYPE;
   v_var_hash_password     cms_cust_mast.ccm_password_hash%TYPE;
   exp_reject_record        EXCEPTION;
   
BEGIN
  BEGIN
     p_o_resp_msg := 'success';
     p_o_resp_code :='00';
          
      BEGIN             
         vmscommon.get_transaction_details (p_i_inst_code,
                                            p_i_delivery_chnl,
                                            p_i_txn_code,
                                            v_var_cr_dr_flag,
                                            v_var_tran_type,
                                            v_var_trans_desc,
                                            v_char_prfl_flag,
                                            v_var_preauth_flag,
                                            v_var_login_txn,
                                            v_var_preauth_type,
                                            v_var_dup_rrn_check,
                                            p_o_resp_code,
                                            v_var_errmsg
                                           );
            IF p_o_resp_code <> '00' AND v_var_errmsg <> 'OK'
               THEN
               RAISE exp_reject_record;
            END IF;
          EXCEPTION
           WHEN exp_reject_record
           THEN
            RAISE;
           WHEN OTHERS
           THEN
            p_o_resp_code := '12';
            v_var_errmsg :=
                 'Error from Transaction Details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
            
      END;
             
      BEGIN
      
         SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no, cap_card_stat,
                cap_prod_code, cap_card_type, cap_expry_date,
                cap_active_date, cap_prfl_code, cap_proxy_number,
                cap_appl_code, cap_cust_code
           INTO v_var_hash_pan, v_var_encr_pan, v_var_acct_no, v_var_card_stat,
                v_var_prod_code, v_var_prod_cattype, v_date_expry_date,
                v_date_active_date, v_var_prfl_code, v_var_proxynumber,
                v_var_appl_code, v_var_cust_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_i_inst_code
            AND cap_pan_code = gethash (p_i_pan_code)
            AND cap_mbr_numb = '000';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_o_resp_code := '21';
            v_var_errmsg := 'Invalid Card number ' || gethash (p_i_pan_code);
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_o_resp_code := '21';
            v_var_errmsg :=
                  'Error while selecting CMS_APPL_PAN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      
     IF v_var_dup_rrn_check = 'Y' THEN
      BEGIN
         vmscommon.validate_date_rrn (p_i_inst_code,
                                      p_i_rrn,
                                      p_i_tran_date,
                                      p_i_tran_time,
                                      p_i_delivery_chnl,
                                      v_var_errmsg,
                                      p_o_resp_code
                                     );

         IF p_o_resp_code <> '00' AND v_var_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_o_resp_code := '22';
            v_var_errmsg :=
                  'Error while validating DATE AND RRN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      END IF;
      
      BEGIN
          v_var_hash_password := GETHASH(p_i_password);
        EXCEPTION
          WHEN OTHERS THEN
         p_o_resp_code     := '12';
         v_var_errmsg := 'Error while converting password ' || SUBSTR(SQLERRM, 1, 200);
         RAISE exp_reject_record;
       END;
       
      BEGIN

         vmscommon.authorize_nonfinancial_txn (p_i_inst_code,
                                               p_i_msg_type,
                                               p_i_rrn,
                                               p_i_delivery_chnl,
                                               p_i_txn_code,
                                               0,
                                               p_i_tran_date,
                                               p_i_tran_time,
                                               '00',
                                               v_var_tran_type,
                                               p_i_pan_code,
                                               v_var_hash_pan,
                                               v_var_encr_pan,
                                               v_var_acct_no,
                                               v_var_card_stat,
                                               v_date_expry_date,
                                               v_var_prod_code,
                                               v_var_prod_cattype,
                                               v_char_prfl_flag,
                                               v_var_prfl_code,
                                               v_var_tran_type,
                                               p_i_curr_code,
                                               v_var_preauth_flag,
                                               v_var_trans_desc,
                                               v_var_cr_dr_flag,
                                               v_var_login_txn,
                                               p_o_resp_code,
                                               v_var_errmsg,
                                               v_var_comb_hash,
                                               v_var_auth_id,
                                               v_var_fee_code,
                                               v_num_fee_plan,
                                               v_var_feeattach_type,
                                               v_num_tranfee_amt,
                                               v_num_total_amt,
                                               v_var_preauth_type
                                              );


         IF v_var_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_o_resp_code := '21';
            v_var_errmsg :=
                  'Error from authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
            
      END;

  IF p_i_msg_type ='0200' AND  v_var_hash_password is not null THEN
  
   BEGIN
            UPDATE CMS_CUST_MAST SET CCM_PASSWORD_HASH = v_var_hash_password,CCM_WRONG_LOGINCNT=0,CCM_ACCTLOCK_FLAG='N'
            where  ccm_cust_code=v_var_cust_code
                    and ccm_inst_code=p_i_inst_code;
             IF SQL%ROWCOUNT = 0 THEN
                  p_o_resp_code := '21';
             v_var_errmsg  := 'Not updated new password ';
             RAISE EXP_REJECT_RECORD;
             END IF;
             
            EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
               RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
               p_o_resp_code := '21';
               v_var_errmsg  := 'Error from while updating new password ' ||
                    SUBSTR(SQLERRM, 1, 200);
                  RAISE exp_reject_record;
    END;
  
 

  END IF;
  
  EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
            ROLLBACK;
            v_var_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            p_o_resp_code := '89';
  END;
    
  BEGIN
      SELECT cms_iso_respcde
        INTO p_o_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_i_inst_code
         AND cms_delivery_channel = p_i_delivery_chnl
         AND cms_response_id = TO_NUMBER (p_o_resp_code);
   EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_o_resp_code := '21';
            p_o_resp_msg := 'Invalid Card/ Account ' ;
       WHEN OTHERS
      THEN
         p_o_resp_msg :=
               'Error while selecting from response master '
            || p_o_resp_msg
            || p_o_resp_code
            || ' IS-'
            || SUBSTR (SQLERRM, 1, 300);
         p_o_resp_code := '89';
   END;
  
  v_timestamp_time_stamp := SYSTIMESTAMP;

   BEGIN
      v_var_hashkey_id :=
         gethash (   p_i_delivery_chnl
                  || p_i_txn_code
                  || p_i_pan_code
                  || p_i_rrn
                  || TO_CHAR (v_timestamp_time_stamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_o_resp_code := '21';
         p_o_resp_msg :=
            'Error while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
   END;
  
   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO v_num_acct_bal, v_num_ledger_bal, v_num_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_i_inst_code AND cam_acct_no = v_var_acct_no;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_o_resp_code := '12';
         p_o_resp_msg :=
               'Error while getting account details'
            || SUBSTR (SQLERRM, 1, 200)
            || v_var_acct_no;
   END;
   
    IF p_o_resp_code <> '00'
      THEN
         p_o_resp_msg := v_var_errmsg;
      END IF;
          
  BEGIN
      vms_log.log_transactionlog (p_i_inst_code,
                                  p_i_msg_type,
                                  p_i_rrn,
                                  p_i_delivery_chnl,
                                  p_i_txn_code,
                                  v_var_tran_type,
                                  0,
                                  p_i_tran_date,
                                  p_i_tran_time,
                                  '00',
                                  v_var_hash_pan,
                                  v_var_encr_pan,
                                  v_var_errmsg,
                                  p_i_ip_addr,
                                  v_var_card_stat,
                                  v_var_trans_desc,
                                  p_i_ani,
                                  p_i_dni,
                                  v_timestamp_time_stamp,
                                  v_var_acct_no,
                                  v_var_prod_code,
                                  v_var_prod_cattype,
                                  v_var_cr_dr_flag,
                                  v_num_acct_bal,
                                  v_num_ledger_bal,
                                  v_num_acct_type,
                                  v_var_proxynumber,
                                  v_var_auth_id,
                                  0,
                                  v_num_total_amt,
                                  v_var_fee_code,
                                  v_num_tranfee_amt,
                                  v_num_fee_plan,
                                  v_var_feeattach_type,
                                  p_o_resp_code,
                                  p_o_resp_code,
                                  p_i_curr_code,
                                  v_var_hashkey_id,
                                  p_i_uuid,
                                  p_i_osname,
                                  p_i_osversion,
                                  p_i_gps_coordinates,
                                  p_i_display_resolution,
                                  p_i_physical_memory,
                                  p_i_appname,
                                  p_i_appversion,
                                  p_i_sessionid,
                                  p_i_device_country,
                                  p_i_device_region,
                                  p_i_ipcountry,
                                  p_i_proxy_flag,
                                 p_i_partner_id,
                                  v_var_errmsg
                                 );

      IF v_var_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      END IF;
   
      
   EXCEPTION
      WHEN exp_reject_record
      THEN
         p_o_resp_code := '69';
         p_o_resp_msg :=
               p_o_resp_msg
            || ' Error while inserting into transactionlog  '
            || v_var_errmsg;
      WHEN OTHERS
      THEN
         p_o_resp_code := '69';
         p_o_resp_msg :=
               'Error while inserting into transactionlog '
            || SUBSTR (SQLERRM, 1, 300);
   END;
   
END reset_password;
END VMS_CUSTOMER;
/
show error;