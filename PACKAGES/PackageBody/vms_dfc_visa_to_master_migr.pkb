CREATE OR REPLACE PACKAGE BODY VMSCMS.VMS_DFC_VISA_TO_MASTER_MIGR IS
  PROCEDURE activate_intial_load_migr(p_instcode_in         IN NUMBER,
							   p_rrn_in              IN VARCHAR2,
							   p_terminalid_in       IN VARCHAR2,
							   p_trandate_in         IN VARCHAR2,
							   p_trantime_in         IN VARCHAR2,
							   p_card_no_in          IN VARCHAR2,
							   p_migrcard_in         IN VARCHAR2,
							   p_amount_in           IN NUMBER,
							   p_currcode_in         IN VARCHAR2,
							   p_lupduser_in         IN NUMBER,
							   p_msg_type_in         IN VARCHAR2,
							   p_txn_code_in         IN VARCHAR2,
							   p_txn_mode_in         IN VARCHAR2,
							   p_delivery_channel_in IN VARCHAR2,
							   p_mbr_numb_in         IN VARCHAR2,
							   p_rvsl_code_in        IN VARCHAR2,
							   p_prod_id_in          IN VARCHAR2,
							   p_merchant_name_in    IN VARCHAR2,
							   p_merchant_city_in    IN VARCHAR2,
							   p_fee_plan_id_in      IN VARCHAR2,
							   p_storeid_in          IN VARCHAR2,
							   p_optin_in            IN VARCHAR2,
							   p_taxprepareid_in     IN VARCHAR2,
							   p_reason_code_in      IN VARCHAR2,
							   p_gpr_optin_in        IN VARCHAR2,
							   p_optin_list_in       IN VARCHAR2,
							   p_resp_code_out       OUT VARCHAR2,
							   p_errmsg_out          OUT VARCHAR2,
							   p_dda_number_out      OUT VARCHAR2) IS
  
    /********************************************************************************************       
		* CREATED  BY     : T.NARAYANASWAMY
		* CREATED DATE    : 04 - FEB - 16
		* CREATED FOR     : FSS-4129 - DFC MOMENTUM VISA TO MASTERCARD MIGRATION
		* REVIEWER        : SARAVANANKUMAR
		* BUILD NUMBER    : VMSGPRHOST_4.0_B0001
        
        
        * Modified by     : Siva kumar 
        * Modified Date   : 22-Mar-16
        * Modified For    : MVHOST-1323
        * Reviewer        : Saravanankumar/Pankaj
        * Build Number    : VMSGPRHOSTCSD_4.0_B006
       
        * Modified by     : T.NARAYANASWAMY
        * Modified Date   : 31-Oct-16
        * Modified For    : FSS-4898
        * Reviewer        : Saravanankumar/Pankaj
        * Build Number    : VMSGPRHOST_4.10
		
		* Modified by     : T.NARAYANASWAMY
        * Modified Date   : 13-March-17
        * Modified For    : Mantis_0016486
        * Reviewer        : Saravanankumar/Pankaj
        * Build Number    : VMSGPRHOST_17.03
        
            * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
	
		* Modified By      : Vini Pushkaran
    * Modified Date    : 14-MAY-2018
    * Purpose          : VMS 207 - Added new field to VMS_AUDITTXN_DTLS.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST_R01

    ************************************************************************************************/
  
    l_cap_prod_catg   cms_appl_pan.cap_prod_catg%TYPE;
    l_cap_card_stat   cms_appl_pan.cap_card_stat%TYPE;
    l_cap_cafgen_flag cms_appl_pan.cap_cafgen_flag%TYPE;
    l_firsttime_topup cms_appl_pan.cap_firsttime_topup%TYPE;
    l_errmsg          VARCHAR2(300);
    l_currcode        VARCHAR2(3);
    l_appl_code       cms_caf_info_entry.cci_appl_code%TYPE; -- added    on 13-jan-2014 
    l_resoncode       cms_spprt_reasons.csr_spprt_rsncode%TYPE;
    l_respcode        VARCHAR2(5);
    l_respmsg         VARCHAR2(500);
    l_authmsg         VARCHAR2(500);
    l_capture_date    DATE;
    l_mbrnumb         cms_appl_pan.cap_mbr_numb%TYPE;
    l_txn_type        cms_func_mast.cfm_txn_type%TYPE;
    l_inil_authid     transactionlog.auth_id%TYPE;
    exp_main_reject_record EXCEPTION;
    exp_auth_reject_record EXCEPTION;
    l_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
    l_migr_hash_pan     cms_appl_pan.cap_pan_code%TYPE;
    l_remrk             VARCHAR2(100);
    l_delchannel_code   VARCHAR2(2);
    l_base_curr         cms_inst_param.cip_param_value%TYPE;
    l_tran_date         DATE;
    l_tran_amt          NUMBER;
    l_card_curr         VARCHAR2(5);
    l_acct_balance      NUMBER;
    l_ledger_balance    NUMBER;
    l_business_date     DATE;
    l_cust_code         cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code_count   VARCHAR2(5);
    l_proxunumber       cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_number       cms_appl_pan.cap_acct_no%TYPE;
    l_acct_id           cms_appl_pan.cap_acct_id%TYPE;
    l_dr_cr_flag        VARCHAR2(2);
    l_output_type       VARCHAR2(2);
    l_tran_type         VARCHAR2(2);
    l_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
    l_comb_hash         pkg_limits_check.type_hash;
    l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
    l_prod_code         cms_appl_pan.cap_prod_code%TYPE;
    l_card_type         cms_appl_pan.cap_card_type%TYPE;
    l_inst_code         cms_appl_pan.cap_inst_code%TYPE;
    l_lmtprfl           cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
    l_profile_level     cms_appl_pan.cap_prfl_levl%TYPE;
    l_fee_plan_desc     cms_fee_plan.cfp_plan_desc%TYPE;
    l_fee_plan_id       cms_card_excpfee.cce_fee_plan%TYPE;
    l_flow_source       cms_card_excpfee.cce_flow_source%TYPE;
    l_crgl_catg         cms_card_excpfee.cce_crgl_catg%TYPE;
    l_crgl_code         cms_card_excpfee.cce_crgl_code%TYPE;
    l_crsubgl_code      cms_card_excpfee.cce_crsubgl_code%TYPE;
    l_cracct_no         cms_card_excpfee.cce_cracct_no%TYPE;
    l_drgl_catg         cms_card_excpfee.cce_drgl_catg%TYPE;
    l_drgl_code         cms_card_excpfee.cce_drgl_code%TYPE;
    l_drsubgl_code      cms_card_excpfee.cce_drsubgl_code%TYPE;
    l_dracct_no         cms_card_excpfee.cce_dracct_no%TYPE;
    l_valid_from        cms_card_excpfee.cce_valid_from%TYPE;
    l_valid_to          cms_card_excpfee.cce_valid_to%TYPE;
    l_st_crgl_catg      cms_card_excpfee.cce_st_crgl_catg%TYPE;
    l_st_crgl_code      cms_card_excpfee.cce_st_crgl_code%TYPE;
    l_st_crsubgl_code   cms_card_excpfee.cce_st_crsubgl_code%TYPE;
    l_st_cracct_no      cms_card_excpfee.cce_st_cracct_no%TYPE;
    l_st_drgl_catg      cms_card_excpfee.cce_st_drgl_catg%TYPE;
    l_st_drgl_code      cms_card_excpfee.cce_st_drgl_code%TYPE;
    l_st_drsubgl_code   cms_card_excpfee.cce_st_drsubgl_code%TYPE;
    l_st_dracct_no      cms_card_excpfee.cce_st_dracct_no%TYPE;
    l_cess_crgl_catg    cms_card_excpfee.cce_cess_crgl_catg%TYPE;
    l_cess_crgl_code    cms_card_excpfee.cce_cess_crgl_code%TYPE;
    l_cess_crsubgl_code cms_card_excpfee.cce_cess_crsubgl_code%TYPE;
    l_cess_cracct_no    cms_card_excpfee.cce_cess_cracct_no%TYPE;
    l_cess_drgl_catg    cms_card_excpfee.cce_cess_drgl_catg%TYPE;
    l_cess_drgl_code    cms_card_excpfee.cce_cess_drgl_code%TYPE;
    l_cess_drsubgl_code cms_card_excpfee.cce_cess_drsubgl_code%TYPE;
    l_cess_dracct_no    cms_card_excpfee.cce_cess_dracct_no%TYPE;
    l_st_calc_flag      cms_card_excpfee.cce_st_calc_flag%TYPE;
    l_cess_calc_flag    cms_card_excpfee.cce_cess_calc_flag%TYPE;
    l_cardfee_id        cms_card_excpfee.cce_cardfee_id%TYPE;
    l_cap_appl_code     cms_appl_pan.cap_appl_code%TYPE;
    l_ssn_crddtls       VARCHAR2(4000);
    l_dup_check         NUMBER(3);
    l_oldcrd            cms_htlst_reisu.chr_pan_code%TYPE;
    l_update_excp EXCEPTION;
    l_feeplan_count           NUMBER;
    l_hashkey_id              cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
    l_time_stamp              TIMESTAMP;
    l_stan                    VARCHAR2(12);
    l_loadcredit_flag         cms_prodcatg_smsemail_alerts.cps_loadcredit_flag%TYPE;
    l_lowbal_flag             cms_prodcatg_smsemail_alerts.cps_lowbal_flag%TYPE;
    l_negativebal_flag        cms_prodcatg_smsemail_alerts.cps_negativebal_flag%TYPE;
    l_highauthamt_flag        cms_prodcatg_smsemail_alerts.cps_highauthamt_flag%TYPE;
    l_dailybal_flag           cms_prodcatg_smsemail_alerts.cps_dailybal_flag%TYPE;
    l_insuffund_flag          cms_prodcatg_smsemail_alerts.cps_insuffund_flag%TYPE;
    l_incorrectpin_flag       cms_prodcatg_smsemail_alerts.cps_incorrectpin_flag%TYPE;
    l_cellphonecarrier        CHAR(1);
    l_lowbal_amt              NUMBER(15, 2);
    l_highauthamt             NUMBER(15, 2);
    l_c2c_flag                CHAR(1);
    l_cmm_merprodcat_id       cms_merinv_merpan.cmm_merprodcat_id%TYPE;
    l_fast50_flag             cms_prodcatg_smsemail_alerts.cps_fast50_flag%TYPE;
    l_federal_flag            cms_prodcatg_smsemail_alerts.cps_fedtax_refund_flag%TYPE;
    l_loccheck_flg            cms_prod_cattype.cpc_loccheck_flag%TYPE;
    l_cmm_mer_id              cms_merinv_merpan.cmm_mer_id%TYPE;
    l_cmm_location_id         cms_merinv_merpan.cmm_location_id%TYPE;
    l_actl_flag               cms_prod_cattype.cpc_invcheck_flag%TYPE;
    l_dup_timeperiod          cms_product_param.cpp_dup_timeperiod%TYPE;
    l_dup_timeunt             cms_product_param.cpp_dup_timeunt%TYPE;
    l_days_diff               cms_product_param.cpp_dup_timeperiod%TYPE;
    l_weeks_diff              cms_product_param.cpp_dup_timeperiod%TYPE;
    l_months_diff             cms_product_param.cpp_dup_timeperiod%TYPE;
    l_years_diff              cms_product_param.cpp_dup_timeperiod%TYPE;
    l_active_date             cms_appl_pan.cap_active_date%TYPE;
    l_new_registrition        VARCHAR2(1);
    l_cardactive_dt           cms_appl_pan.cap_active_date%TYPE;
    l_alert_lang_id           cms_prodcatg_smsemail_alerts.cps_alert_lang_id%TYPE;
    l_optin                   VARCHAR2(1);
    l_sms_optinflag           cms_optin_status.cos_sms_optinflag%TYPE;
    l_sms_optintime           cms_optin_status.cos_sms_optintime%TYPE;
    l_sms_optouttime          cms_optin_status.cos_sms_optouttime%TYPE;
    l_email_optinflag         cms_optin_status.cos_email_optinflag%TYPE;
    l_email_optintime         cms_optin_status.cos_email_optintime%TYPE;
    l_email_optouttime        cms_optin_status.cos_email_optouttime%TYPE;
    l_markmsg_optinflag       cms_optin_status.cos_markmsg_optinflag%TYPE;
    l_markmsg_optintime       cms_optin_status.cos_markmsg_optintime%TYPE;
    l_markmsg_optouttime      cms_optin_status.cos_markmsg_optouttime%TYPE;
    l_gpresign_optinflag      cms_optin_status.cos_gpresign_optinflag%TYPE;
    l_gpresign_optintime      cms_optin_status.cos_gpresign_optintime%TYPE;
    l_gpresign_optouttime     cms_optin_status.cos_gpresign_optouttime%TYPE;
    l_savingsesign_optinflag  cms_optin_status.cos_savingsesign_optinflag%TYPE;
    l_savingsesign_optintime  cms_optin_status.cos_savingsesign_optintime%TYPE;
    l_savingsesign_optouttime cms_optin_status.cos_savingsesign_optouttime%TYPE;
    l_optin_flag              VARCHAR2(10) DEFAULT 'N';
    l_optin_type              cms_optin_status.cos_sms_optinflag%TYPE;
    l_optin_split             cms_optin_status.cos_sms_optinflag%TYPE;
    l_optin_list              VARCHAR2(1000);
    l_comma_pos               NUMBER;
    l_comma_pos1              NUMBER;
    i                         NUMBER := 1;
    l_tandc_version           cms_product_param.cpp_tandc_version%TYPE;
    l_cust_id                 cms_cust_mast.ccm_cust_id%TYPE;
    l_count                   NUMBER;
    L_COUNT_MIGR              NUMBER;
    --SN: Commented for 4.0.3 changes
    /*l_addr_lineone            VARCHAR2(50);
    l_addr_linetwo            VARCHAR2(50);
    l_city_name               VARCHAR2(25);
    l_pin_code                VARCHAR2(15);
    l_phone_no                VARCHAR2(40);
    l_mobl_no                 VARCHAR2(40);
    l_email                   VARCHAR2(50);
    l_state_code              NUMBER(3);
    l_state_switch            VARCHAR2(3);
    l_ctnry_code              NUMBER(3);
    l_ssn                     VARCHAR2(10);
    l_birth_date              DATE;
    l_first_name              VARCHAR2(40);
    l_mid_name                VARCHAR2(30);
    l_last_name               VARCHAR2(30);*/
    --EN: Commented for 4.0.3 changes
    l_partner_id              cms_cust_mast.ccm_partner_id%TYPE;
    l_store_count             NUMBER;
    l_mailing_addr_count      NUMBER(3);
    l_saving_acct_exist       VARCHAR2(1) DEFAULT 'Y';
  
    -- AddrMast    
    l_migr_p_add_one      cms_addr_mast.cam_add_one%TYPE;
    l_migr_p_add_two      cms_addr_mast.cam_add_two%TYPE;
    l_migr_p_pin_code     cms_addr_mast.cam_pin_code%TYPE;
    l_migr_p_phone_one    cms_addr_mast.cam_phone_one%TYPE;
    l_migr_p_cntry_code   cms_addr_mast.cam_cntry_code%TYPE;
    l_migr_p_city_name    cms_addr_mast.cam_city_name%TYPE;
    l_migr_p_state_switch cms_addr_mast.cam_state_switch%TYPE;
    l_migr_p_email        cms_addr_mast.cam_email%TYPE;
    l_migr_p_mobl_one     cms_addr_mast.cam_mobl_one%TYPE;
    l_migr_p_state_code   cms_addr_mast.cam_state_code%TYPE;
  
    l_migr_m_add_one      cms_addr_mast.cam_add_one%TYPE;
    l_migr_m_add_two      cms_addr_mast.cam_add_two%TYPE;
    l_migr_m_pin_code     cms_addr_mast.cam_pin_code%TYPE;
    l_migr_m_phone_one    cms_addr_mast.cam_phone_one%TYPE;
    l_migr_m_cntry_code   cms_addr_mast.cam_cntry_code%TYPE;
    l_migr_m_city_name    cms_addr_mast.cam_city_name%TYPE;
    l_migr_m_state_switch cms_addr_mast.cam_state_switch%TYPE;
    l_migr_m_email        cms_addr_mast.cam_email%TYPE;
    l_migr_m_mobl_one     cms_addr_mast.cam_mobl_one%TYPE;
    l_migr_m_state_code   cms_addr_mast.cam_state_code%TYPE;
  
    -- CustMast
    l_migr_first_name         cms_cust_mast.ccm_first_name%TYPE;
    l_migr_mid_name           cms_cust_mast.ccm_mid_name%TYPE;
    l_migr_last_name          cms_cust_mast.ccm_last_name%TYPE;
    l_migr_birth_date         cms_cust_mast.ccm_birth_date%TYPE;
    l_migr_gender_type        cms_cust_mast.ccm_gender_type%TYPE;
    l_migr_ssn                cms_cust_mast.ccm_ssn%TYPE;
    l_migr_ssn_encr           cms_cust_mast.ccm_ssn_encr%TYPE;
    l_migr_mother_name        cms_cust_mast.ccm_mother_name%TYPE;
    l_migr_user_name          cms_cust_mast.ccm_user_name%TYPE;
    l_migr_password_hash      cms_cust_mast.ccm_password_hash%TYPE;
    l_migr_kyc_flag           cms_cust_mast.ccm_kyc_flag%TYPE;
    l_migr_kyc_source         cms_cust_mast.ccm_kyc_source%TYPE;
    l_migr_appl_id            cms_cust_mast.ccm_appl_id%TYPE;
    l_migr_ofac_fail_flag     cms_cust_mast.ccm_ofac_fail_flag%TYPE;
    l_migr_id_type            cms_cust_mast.ccm_id_type%TYPE;
    l_migr_id_issuer          cms_cust_mast.ccm_id_issuer%TYPE;
    l_migr_idissuence_date    cms_cust_mast.ccm_idissuence_date%TYPE;
    l_migr_idexpry_date       cms_cust_mast.ccm_idexpry_date%TYPE;
    l_migr_optinoptout_status cms_cust_mast.ccm_optinoptout_status%TYPE;
    l_migr_addrverify_flag    cms_cust_mast.ccm_addrverify_flag%TYPE;
    l_migr_addverify_date     cms_cust_mast.ccm_addverify_date%TYPE;
    l_migr_avfset_channel     cms_cust_mast.ccm_avfset_channel%TYPE;
    l_migr_avfset_txncode     cms_cust_mast.ccm_avfset_txncode%TYPE;
    l_migr_auth_user          cms_cust_mast.ccm_auth_user%TYPE;
    l_migr_wrong_logincnt     cms_cust_mast.ccm_wrong_logincnt%TYPE;
    l_migr_acctlock_flag      cms_cust_mast.ccm_acctlock_flag%TYPE;
    l_migr_last_logindate     cms_cust_mast.ccm_last_logindate%TYPE;
    l_migr_acctunlock_date    cms_cust_mast.ccm_acctunlock_date%TYPE;
    l_migr_acctunlock_user    cms_cust_mast.ccm_acctunlock_user%TYPE;
    l_migr_gpr_optin          cms_cust_mast.ccm_gpr_optin%TYPE;
    l_migr_partner_id         cms_cust_mast.ccm_partner_id%TYPE;
    l_saving_acct_id          cms_cust_acct.cca_acct_id%TYPE;
    l_saving_acct_no          cms_acct_mast.cam_acct_no%TYPE;
    l_spend_acct_id           cms_cust_acct.cca_acct_id%TYPE;
    l_spend_acct_no           cms_acct_mast.cam_acct_no%TYPE;
    l_spend_card_status       cms_appl_pan.cap_card_stat%TYPE;
    l_migr_cust_code          cms_cust_mast.ccm_cust_code%TYPE;
    L_MIGR_CUST_ID            CMS_CUST_MAST.CCM_CUST_ID%TYPE;
    L_CONCURRENT_COUNT        NUMBER(1);
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
    
    --FSS-4898 CSDesktop account statement is not working for migrated momentum MasterCard Cards beg
    L_BILL_ADDR CMS_APPL_PAN.CAP_BILL_ADDR%TYPE; 
    L_MIGR_BILL_ADDR CMS_APPL_PAN.CAP_BILL_ADDR%TYPE;
    --FSS-4898 CSDesktop account statement is not working for migrated momentum MasterCard Cards end
  
    CURSOR l_cur_alert_config(p_instcode IN VARCHAR2, p_prod_code IN VARCHAR2, p_card_type IN VARCHAR2, p_alert_lang_id IN VARCHAR2) IS
	 SELECT cps_config_flag, substr(cps_alert_msg, 1, 1) alert_flag,
		   cps_alert_id
	 FROM   cms_prodcatg_smsemail_alerts
	 WHERE  cps_inst_code = p_instcode AND cps_prod_code = p_prod_code AND
		   cps_card_type = p_card_type AND
		   cps_alert_lang_id = p_alert_lang_id;
  
  BEGIN
    p_errmsg_out := 'OK';
    l_remrk      := 'MIGRATION CARD ACTIVATION WITH PROFILE';
    l_time_stamp := systimestamp;
  
    l_new_registrition := 'N';
    --sn create hash pan
    BEGIN
	 l_hash_pan := gethash(p_card_no_in);
    EXCEPTION
	 WHEN OTHERS THEN
	   l_errmsg := 'ERROR WHILE CONVERTING HASH PAN ' ||
				substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    --en create hash pan
  
    --sn create encr pan
    BEGIN
	 l_encr_pan := fn_emaps_main(p_card_no_in);
    EXCEPTION
	 WHEN OTHERS THEN
	   l_respcode := '12';
	   l_errmsg   := 'ERROR WHILE CONVERTING ENCR PAN ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
    --en create encr pan
  
    --sn create hash pan of Migration card
    BEGIN
	 l_migr_hash_pan := gethash(p_migrcard_in);
    EXCEPTION
	 WHEN OTHERS THEN
	   l_errmsg := 'ERROR WHILE CONVERTING MIGRATION HASH PAN ' ||
				substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 l_hashkey_id := gethash(p_delivery_channel_in || p_txn_code_in ||
						p_card_no_in || p_rrn_in ||
						to_char(l_time_stamp, 'YYYYMMDDHH24MISSFF5'));
    EXCEPTION
	 WHEN OTHERS THEN
	   p_resp_code_out := '21';
	   l_errmsg        := 'ERROR WHILE CONVERTING MASTER DATA ' ||
					  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    --sn find debit and credit flag
    BEGIN
    
	 SELECT ctm_credit_debit_flag, ctm_output_type,
		   to_number(decode(ctm_tran_type, 'N', '0', 'F', '1')),
		   ctm_tran_type, ctm_prfl_flag, ctm_tran_desc
	 INTO   l_dr_cr_flag, l_output_type, l_txn_type, l_tran_type,
		   l_prfl_flag, l_trans_desc
	 FROM   cms_transaction_mast
	 WHERE  ctm_tran_code = p_txn_code_in AND
		   ctm_delivery_channel = p_delivery_channel_in AND
		   ctm_inst_code = p_instcode_in;
    EXCEPTION
	 WHEN no_data_found THEN
	   l_respcode := '12';
	   l_errmsg   := 'TRANSFLAG  NOT DEFINED FOR TXN CODE ' ||
				  p_txn_code_in || ' AND DELIVERY CHANNEL ' ||
				  p_delivery_channel_in;
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21'; --ineligible transaction
	   l_respcode := 'ERROR WHILE SELECTING TRANSACTION DETAILS' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 SELECT vrm_reason_desc
	 INTO   l_trans_desc
	 FROM   vms_reason_mast
	 WHERE  vrm_reason_code = upper(p_reason_code_in);
    
    EXCEPTION
	 WHEN no_data_found THEN
	   BEGIN
		SELECT vrm_reason_desc
		INTO   l_trans_desc
		FROM   vms_reason_mast
		WHERE  vrm_reason_code = upper(substr(p_reason_code_in, 1, 1));
	   
	   EXCEPTION
		WHEN no_data_found THEN
		  l_trans_desc := l_trans_desc;
		WHEN OTHERS THEN
		  l_respcode := '21';
		  l_errmsg   := 'ERROR WHILE TRANSACTION DESCRIPTION ' ||
					 substr(SQLERRM, 1, 200);
		  RAISE exp_main_reject_record;
		
	   END;
	 
	 WHEN exp_main_reject_record THEN
	   RAISE;
	 
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'PROBLEM ON GENERATING TRANSACTION DESCRIPTION  ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 SELECT REPLACE(l_trans_desc, '<<AMNT>>', p_amount_in)
	 INTO   l_trans_desc
	 FROM   dual;
    EXCEPTION
	 WHEN no_data_found THEN
	   l_trans_desc := l_trans_desc;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE TRANSACTION DESCRIPTION ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    --sn transaction date check
    BEGIN
	 l_tran_date := to_date(substr(TRIM(p_trandate_in), 1, 8), 'YYYYMMDD');
    EXCEPTION
	 WHEN OTHERS THEN
	   l_respcode := '45';
	   l_errmsg   := 'PROBLEM WHILE CONVERTING TRANSACTION DATE ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
    --en transaction date check
  
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
  
    --sn select pan detail
    BEGIN
    
   --FSS-4898 CSDesktop account statement is not working for migrated momentum MasterCard Cards beg 
	 SELECT cap_card_stat, cap_prod_catg, cap_cafgen_flag, cap_appl_code,
		   cap_firsttime_topup, cap_mbr_numb, cap_cust_code,
		   cap_proxy_number, cap_acct_no, cap_acct_id, cap_prfl_code,
		   CAP_APPL_CODE, CAP_PROD_CODE, CAP_PRFL_LEVL, CAP_CARD_TYPE,
		   cap_inst_code, cap_active_date, ccm_cust_id,cap_BILL_ADDR
	 INTO   l_cap_card_stat, l_cap_prod_catg, l_cap_cafgen_flag,
		   l_appl_code, l_firsttime_topup, l_mbrnumb, l_cust_code,
		   l_proxunumber, l_acct_number, l_acct_id, l_lmtprfl,
		   l_cap_appl_code, l_prod_code, l_profile_level, l_card_type,
		   l_inst_code, l_cardactive_dt, l_cust_id,L_BILL_ADDR
	 FROM   cms_appl_pan, cms_cust_mast
	 WHERE  cap_inst_code = p_instcode_in AND
		   cap_inst_code = ccm_inst_code AND
		   cap_cust_code = ccm_cust_code AND cap_pan_code = l_hash_pan AND
		   cap_mbr_numb = p_mbr_numb_in;
    
	 BEGIN
	   --SPENDING ACCOUNT details
	   SELECT CAP_ACCT_NO, CAP_ACCT_ID, CAP_CARD_STAT, CAP_CUST_CODE,
			CCM_CUST_ID,cap_bill_addr
	   INTO   L_SPEND_ACCT_NO, L_SPEND_ACCT_ID, L_SPEND_CARD_STATUS,
			L_MIGR_CUST_CODE, L_MIGR_CUST_ID,l_migr_bill_addr
	   FROM   cms_appl_pan, cms_cust_mast
	   WHERE  cap_cust_code = ccm_cust_code AND
			cap_inst_code = p_instcode_in AND
       cap_inst_code = ccm_inst_code AND
			cap_pan_code = l_migr_hash_pan;
	 --FSS-4898 CSDesktop account statement is not working for migrated momentum MasterCard Cards end
	 EXCEPTION
	   WHEN no_data_found THEN
		l_respcode := '49';
		l_errmsg   := 'INVALID MIGRATION PROXY NUMBER';
		RAISE exp_main_reject_record;
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := 'ERROR WHILE SELECTING SPENDING ACCOUNT DETAILS ' ||
				    substr(SQLERRM, 1, 200);
		RAISE exp_main_reject_record;
	 END;
    
	--SN: Commented for 4.0.3 changes
  /* BEGIN
	   --SAVINGS ACCOUNT   details       
	   SELECT cam_acct_no, cam_acct_id
	   INTO   l_saving_acct_no, l_saving_acct_id
	   FROM   cms_acct_mast, cms_cust_acct, cms_acct_type
	   WHERE  cca_acct_id = cam_acct_id AND cam_type_code = cat_type_code AND
			cat_type_desc = 'SAVINGS ACCOUNT' AND
			cam_inst_code = p_instcode_in AND
			cca_cust_code = l_migr_cust_code;
	 
	 EXCEPTION
	   WHEN no_data_found THEN
		l_saving_acct_exist := 'N';
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := 'ERROR WHILE SELECTING SAVING ACCOUNT DETAILS ' ||
				    substr(SQLERRM, 1, 200);
		RAISE exp_main_reject_record;
	 END;*/
   --EN: Commented for 4.0.3 changes
   
    
	 --sn activation check
	 IF l_firsttime_topup = 'Y' AND l_cap_card_stat = '1'
	 THEN
	   l_respcode := '27';
	   l_errmsg   := 'CARD ACTIVATION WITH PROFILE ALREADY DONE';
	   RAISE exp_main_reject_record;
	 ELSIF TRIM(l_firsttime_topup) IS NULL
	 THEN
	   l_errmsg := 'INVALID CARD ACTIVATION WITH PROFILE PARAMETER';
	   RAISE exp_main_reject_record;
	 ELSIF l_cardactive_dt IS NOT NULL
	 THEN
	   l_respcode := '27';
	   l_errmsg   := 'CARD ACTIVATION ALREADY DONE FOR THIS CARD ';
	   RAISE exp_main_reject_record;
	 END IF;
    
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN no_data_found THEN
	   l_errmsg := 'INVALID CARD NUMBER';
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_errmsg := 'ERROR WHILE SELECTING CARD NUMBER' ||
				substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    --en select pan detail
    -- sn moved down for fwr-70
    BEGIN
	 SELECT cdm_channel_code
	 INTO   l_delchannel_code
	 FROM   cms_delchannel_mast
	 WHERE  cdm_channel_desc = 'MMPOS' AND cdm_inst_code = p_instcode_in;
    
	 IF l_delchannel_code = p_delivery_channel_in
	 THEN
	   BEGIN
--		SELECT TRIM(cbp_param_value)
--		INTO   l_base_curr
--		FROM   cms_bin_param
--		WHERE  cbp_param_name = 'Currency' AND
--			  cbp_inst_code = p_instcode_in AND
--			  cbp_profile_code IN
--        (SELECT CPC_PROFILE_CODE
--			   FROM   CMS_PROD_CATTYPE
--			   WHERE  CPC_PROD_CODE = l_prod_code AND CPC_CARD_TYPE=l_card_type AND
--					CPC_INST_CODE = p_instcode_in);
          
          
      vmsfunutilities.get_currency_code(l_prod_code,l_card_type,p_instcode_in,l_base_curr,l_errmsg);
      
      if l_errmsg<>'OK' then
           raise exp_main_reject_record;
      end if;
	   
		IF TRIM(l_base_curr) IS NULL
		THEN
		  l_respcode := '21';
		  l_errmsg   := 'BASE CURRENCY CANNOT BE NULL ';
		  RAISE exp_main_reject_record;
		END IF;
	   EXCEPTION
		WHEN exp_main_reject_record THEN
		  RAISE exp_main_reject_record;
		WHEN OTHERS THEN
		  l_respcode := '21';
		  l_errmsg   := 'ERROR WHILE SELECTING BESE CURRECY  ' ||
					 substr(SQLERRM, 1, 200);
		  RAISE exp_main_reject_record;
	   END;
	 
	   l_currcode := l_base_curr;
	 ELSE
	   l_currcode := p_currcode_in;
	 END IF;
    EXCEPTION
	 WHEN OTHERS THEN
	   l_errmsg := 'ERROR WHILE SELECTING THE DELIVERY CHANNEL OF MMPOS  ' ||
				substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 concurrent_txncheck(p_instcode_in, l_hash_pan, l_migr_hash_pan,
					 p_txn_code_in, p_delivery_channel_in,
					 p_msg_type_in, p_trandate_in, l_concurrent_count);
    
	 IF (l_concurrent_count > 0)
	 THEN
	   l_respcode := '261';
	   l_errmsg   := 'Concurrent Transaction in Process';
	   RAISE exp_main_reject_record;
	 ELSE
	   current_txnlog(p_instcode_in, l_hash_pan, l_migr_hash_pan,
				   p_txn_code_in, p_delivery_channel_in, p_msg_type_in,
				   p_trandate_in);
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE;
	 WHEN OTHERS THEN
	   l_respcode := '12';
	   l_errmsg   := 'Concurrent check Failed' || substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
    
	 SELECT cpp_dup_timeperiod, cpp_dup_timeunt
	 INTO   l_dup_timeperiod, l_dup_timeunt
	 FROM   cms_product_param
	 WHERE  cpp_prod_code = l_prod_code AND cpp_inst_code = p_instcode_in;
    
    EXCEPTION
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE SELECTING PRODUCT DETLS ' || l_prod_code;
	   RAISE exp_main_reject_record;
	 
    END;
  
    IF l_new_registrition <> 'Y'
    THEN
    
	 IF l_dup_timeunt = 'D'
	 THEN
	   -- days
	 
	   BEGIN
	   
		SELECT round(SYSDATE - l_active_date, 2)
		INTO   l_days_diff
		FROM   dual;
	   
	   EXCEPTION
		WHEN OTHERS THEN
		
		  l_respcode := '21';
		  l_errmsg   := 'ERROR WHILE GETTING DAY DIFF' ||
					 substr(SQLERRM, 1, 200);
		  RAISE exp_main_reject_record;
		
	   END;
	 
	   IF l_days_diff <= l_dup_timeperiod
	   THEN
	   
		l_respcode := '232';
		l_errmsg   := 'CARDHOLDER HAS A RECENT EXISTING ACCOUNT';
		RAISE exp_main_reject_record;
	   
	   END IF;
	 
	 ELSIF l_dup_timeunt = 'W'
	 THEN
	   -- weeks
	 
	   BEGIN
	   
		SELECT ceil((trunc(SYSDATE) - trunc(l_active_date)) / 7)
		INTO   l_weeks_diff
		FROM   dual;
	   
	   EXCEPTION
		WHEN OTHERS THEN
		  l_respcode := '21';
		  l_errmsg   := 'ERROR WHILE GETTING WEEKLY DIFF' ||
					 substr(SQLERRM, 1, 200);
		  RAISE exp_main_reject_record;
	   END;
	 
	   IF l_weeks_diff <= l_dup_timeperiod
	   THEN
	   
		l_respcode := '232';
		l_errmsg   := 'CARDHOLDER HAS A RECENT EXISTING ACCOUNT';
		RAISE exp_main_reject_record;
	   
	   END IF;
	 
	 ELSIF l_dup_timeunt = 'M'
	 THEN
	   -- months
	 
	   BEGIN
	   
		SELECT ceil(months_between(to_date(to_char(SYSDATE, 'MM-DD-YYYY'),
									 'MM-DD-YYYY'),
							   to_date(to_char(l_active_date,
											'MM-DD-YYYY'),
									  'MM-DD-YYYY')))
		INTO   l_months_diff
		FROM   dual;
	   
	   EXCEPTION
		WHEN OTHERS THEN
		
		  l_respcode := '21';
		  l_errmsg   := 'ERROR WHILE GETTING MONTHLY DIFF' ||
					 substr(SQLERRM, 1, 200);
		  RAISE exp_main_reject_record;
		
	   END;
	 
	   IF l_months_diff <= l_dup_timeperiod
	   THEN
	   
		l_respcode := '232';
		l_errmsg   := 'CARDHOLDER HAS A RECENT EXISTING ACCOUNT';
		RAISE exp_main_reject_record;
	   
	   END IF;
	 
	 ELSIF l_dup_timeunt = 'Y'
	 THEN
	   -- years
	 
	   BEGIN
	   
		SELECT floor(months_between(to_date(to_char(SYSDATE, 'MM-DD-YYYY'),
									  'MM-DD-YYYY'),
							    to_date(to_char(l_active_date,
											 'MM-DD-YYYY'),
									   'MM-DD-YYYY')) / 12)
		INTO   l_years_diff
		FROM   dual;
	   
	   EXCEPTION
		WHEN OTHERS THEN
		
		  l_respcode := '21';
		  l_errmsg   := 'ERROR WHILE GETTING YEARLY DIFF' ||
					 substr(SQLERRM, 1, 200);
		  RAISE exp_main_reject_record;
		
	   END;
	 
	   IF l_years_diff <= l_dup_timeperiod
	   THEN
	   
		l_respcode := '232';
		l_errmsg   := 'CARDHOLDER HAS A RECENT EXISTING ACCOUNT';
		RAISE exp_main_reject_record;
	   
	   END IF;
	 
	 END IF;
    END IF;
  
    BEGIN
	 SELECT cpc_loccheck_flag, cpc_invcheck_flag
	 INTO   l_loccheck_flg, l_actl_flag
	 FROM   cms_prod_cattype
	 WHERE  cpc_prod_code = l_prod_code AND cpc_card_type = l_card_type AND
		   cpc_inst_code = p_instcode_in;
    
    EXCEPTION
	 WHEN no_data_found THEN
	   l_errmsg   := 'ERROR WHILE FETCHING LOCATION CHECK FROM PRODCATTYPE - NO DATA FOUND';
	   l_respcode := '21';
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_errmsg   := 'ERROR WHILE FETCHING LOCATION CHECK FROM PRODCATTYPE ' ||
				  substr(SQLERRM, 1, 200);
	   l_respcode := '21';
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 IF l_loccheck_flg = 'Y'
	 THEN
	   SELECT COUNT(*)
	   INTO   l_store_count
	   FROM   cms_caf_info_entry
	   WHERE  cci_appl_code = l_appl_code AND
			cci_store_id = p_terminalid_in;
	 
	   IF l_store_count = 0
	   THEN
		l_respcode := '40';
		l_errmsg   := 'STORE ID MISMATCH';
		RAISE exp_main_reject_record;
	   END IF;
	 END IF;
    END;
  
    BEGIN
	 SELECT cfp_plan_desc
	 INTO   l_fee_plan_desc
	 FROM   cms_fee_plan
	 WHERE  cfp_plan_id = p_fee_plan_id_in AND
		   cfp_inst_code = p_instcode_in;
    EXCEPTION
	 WHEN no_data_found THEN
	   l_respcode := '131';
	   l_errmsg   := 'INVALID FEE PLAN ID ' || '--' || p_fee_plan_id_in;
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE SELECTING FEE PLAN ID ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 SELECT COUNT(*)
	 INTO   l_feeplan_count
	 FROM   cms_feeplan_prod_mapg
	 WHERE  cfm_plan_id = p_fee_plan_id_in AND cfm_prod_code = l_prod_code AND
		   cfm_inst_code = p_instcode_in;
    
	 IF l_feeplan_count = 0
	 THEN
	   l_respcode := '166';
	   l_errmsg   := 'FEE PLAN ID NOT LINKED TO PRODUCT' || '--' ||
				  p_fee_plan_id_in || '--' || l_prod_code;
	   RAISE exp_main_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE SELECTING FEE PLAN ID ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 SELECT chr_pan_code
	 INTO   l_oldcrd
	 FROM   cms_htlst_reisu
	 WHERE  chr_inst_code = p_instcode_in AND chr_new_pan = l_hash_pan AND
		   chr_reisu_cause = 'R' AND chr_pan_code IS NOT NULL;
    
	 BEGIN
	   SELECT COUNT(1)
	   INTO   l_dup_check
	   FROM   cms_appl_pan
	   WHERE  cap_inst_code = p_instcode_in AND
			cap_acct_no = l_acct_number AND
			cap_card_stat IN ('0', '1', '2', '5', '6', '8', '12');
	 
	   IF l_dup_check <> 1
	   THEN
		l_errmsg   := 'CARD IS NOT ALLOWED FOR ACTIVATION';
		l_respcode := '89';
		RAISE exp_main_reject_record;
	   END IF;
	 END;
    
	 BEGIN
	   UPDATE cms_appl_pan
	   SET    cap_card_stat = '9'
	   WHERE  cap_inst_code = p_instcode_in AND cap_pan_code = l_oldcrd;
	 
	   IF SQL%ROWCOUNT = 0
	   THEN
		l_errmsg   := 'PROBLEM IN UPDATION OF STATUS FOR OLD DAMAGE CARD';
		l_respcode := '89';
		RAISE exp_main_reject_record;
	   END IF;
	 END;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE;
	 WHEN no_data_found THEN
	   NULL;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE SELECTING DAMAGE CARD DETAILS ' ||
				  substr(SQLERRM, 1, 100);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 IF (to_number(p_amount_in) >= 0)
	 THEN
	   l_tran_amt := p_amount_in;
	 
	   BEGIN
		sp_convert_curr(p_instcode_in, l_currcode, p_card_no_in,
					 p_amount_in, l_tran_date, l_tran_amt, l_card_curr,
					 l_errmsg,l_prod_code,l_card_type);
	   
		IF l_errmsg <> 'OK'
		THEN
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
		END IF;
	   EXCEPTION
		WHEN exp_main_reject_record THEN
		  RAISE;
		WHEN OTHERS THEN
		  l_respcode := '21';
		  l_errmsg   := 'ERROR FROM CURRENCY CONVERSION ' ||
					 substr(SQLERRM, 1, 200);
		  RAISE exp_main_reject_record;
	   END;
	 ELSE
	   l_respcode := '43';
	   l_errmsg   := 'INVALID AMOUNT';
	   RAISE exp_main_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE;
	 WHEN invalid_number THEN
	   l_respcode := '43';
	   l_errmsg   := 'INVALID AMOUNT';
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR IN CONVERT CURRENCY ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    --st updates the fee plan id to card
    BEGIN
	 SELECT cce_fee_plan
	 INTO   l_fee_plan_id
	 FROM   cms_card_excpfee
	 WHERE  cce_inst_code = p_instcode_in AND cce_pan_code = l_hash_pan AND
		   ((cce_valid_to IS NOT NULL AND
		   (l_tran_date BETWEEN cce_valid_from AND cce_valid_to)) --added by ramesh.a on 11/10/2012 for defect 9332
		   OR (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from));
    
	 UPDATE cms_card_excpfee
	 SET    cce_fee_plan = p_fee_plan_id_in, cce_lupd_user = 1,
		   cce_lupd_date = SYSDATE
	 WHERE  cce_inst_code = p_instcode_in AND cce_pan_code = l_hash_pan AND
		   ((cce_valid_to IS NOT NULL AND
		   (l_tran_date BETWEEN cce_valid_from AND cce_valid_to)) --added by ramesh.a on 11/10/2012 for defect 9332
		   OR (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from));
    
	 IF SQL%ROWCOUNT = 0
	 THEN
	   l_errmsg   := 'UPDATING FEE PLAN ID IS NOT HAPPENED';
	   l_respcode := '21';
	   RAISE exp_main_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN no_data_found THEN
	   BEGIN
		SELECT cpf_fee_plan, cpf_flow_source, cpf_crgl_catg, cpf_crgl_code,
			  cpf_crsubgl_code, cpf_cracct_no, cpf_drgl_catg,
			  cpf_drgl_code, cpf_drsubgl_code, cpf_dracct_no,
			  cpf_valid_from, cpf_valid_to, cpf_st_crgl_catg,
			  cpf_st_crgl_code, cpf_st_crsubgl_code, cpf_st_cracct_no,
			  cpf_st_drgl_catg, cpf_st_drgl_code, cpf_st_drsubgl_code,
			  cpf_st_dracct_no, cpf_cess_crgl_catg, cpf_cess_crgl_code,
			  cpf_cess_crsubgl_code, cpf_cess_cracct_no,
			  cpf_cess_drgl_catg, cpf_cess_drgl_code,
			  cpf_cess_drsubgl_code, cpf_cess_dracct_no, cpf_st_calc_flag,
			  cpf_cess_calc_flag
		INTO   l_fee_plan_id, l_flow_source, l_crgl_catg, l_crgl_code,
			  l_crsubgl_code, l_cracct_no, l_drgl_catg, l_drgl_code,
			  l_drsubgl_code, l_dracct_no, l_valid_from, l_valid_to,
			  l_st_crgl_catg, l_st_crgl_code, l_st_crsubgl_code,
			  l_st_cracct_no, l_st_drgl_catg, l_st_drgl_code,
			  l_st_drsubgl_code, l_st_dracct_no, l_cess_crgl_catg,
			  l_cess_crgl_code, l_cess_crsubgl_code, l_cess_cracct_no,
			  l_cess_drgl_catg, l_cess_drgl_code, l_cess_drsubgl_code,
			  l_cess_dracct_no, l_st_calc_flag, l_cess_calc_flag
		FROM   cms_prodcattype_fees
		WHERE  cpf_inst_code = p_instcode_in AND
			  cpf_prod_code = l_prod_code AND
			  cpf_card_type = l_card_type AND
			  ((cpf_valid_to IS NOT NULL AND
			  (l_tran_date BETWEEN cpf_valid_from AND cpf_valid_to)) OR
			  (cpf_valid_to IS NULL AND SYSDATE >= cpf_valid_from));
	   
		INSERT INTO cms_card_excpfee
		  (cce_inst_code, cce_pan_code, cce_ins_date, cce_ins_user,
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
		VALUES
		  (p_instcode_in, l_hash_pan, SYSDATE, p_lupduser_in,
		   p_lupduser_in, SYSDATE, p_fee_plan_id_in, l_flow_source,
		   l_crgl_catg, l_crgl_code, l_crsubgl_code, l_cracct_no,
		   l_drgl_catg, l_drgl_code, l_drsubgl_code, l_dracct_no,
		   l_valid_from, l_valid_to, l_st_crgl_catg, l_st_crgl_code,
		   l_st_crsubgl_code, l_st_cracct_no, l_st_drgl_catg,
		   l_st_drgl_code, l_st_drsubgl_code, l_st_dracct_no,
		   l_cess_crgl_catg, l_cess_crgl_code, l_cess_crsubgl_code,
		   l_cess_cracct_no, l_cess_drgl_catg, l_cess_drgl_code,
		   l_cess_drsubgl_code, l_cess_dracct_no, l_st_calc_flag,
		   l_cess_calc_flag, l_encr_pan);
	   
		SELECT cce_cardfee_id
		INTO   l_cardfee_id
		FROM   cms_card_excpfee
		WHERE  cce_pan_code = l_hash_pan AND
			  cce_inst_code = p_instcode_in AND
			  ((cce_valid_to IS NOT NULL AND
			  (l_tran_date BETWEEN cce_valid_from AND cce_valid_to)) OR
			  (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from));
	   
		--- for history table
		INSERT INTO cms_card_excpfee_hist
		  (cce_inst_code, cce_pan_code, cce_ins_date, cce_ins_user,
		   cce_lupd_user, cce_lupd_date, cce_fee_plan, cce_flow_source,
		   cce_crgl_catg, cce_crgl_code, cce_crsubgl_code, cce_cracct_no,
		   cce_drgl_catg, cce_drgl_code, cce_drsubgl_code, cce_dracct_no,
		   cce_valid_from, cce_valid_to, cce_st_crgl_catg,
		   cce_st_crgl_code, cce_st_crsubgl_code, cce_st_cracct_no,
		   cce_st_drgl_catg, cce_st_drgl_code, cce_st_drsubgl_code,
		   cce_st_dracct_no, cce_cess_crgl_catg, cce_cess_crgl_code,
		   cce_cess_crsubgl_code, cce_cess_cracct_no, cce_cess_drgl_catg,
		   cce_cess_drgl_code, cce_cess_drsubgl_code, cce_cess_dracct_no,
		   cce_st_calc_flag, cce_cess_calc_flag, cce_pan_code_encr,
		   cce_cardfee_id, cce_mbr_numb) --added by ramesh.a on 31/07/2012
		VALUES
		  (p_instcode_in, l_hash_pan, SYSDATE, p_lupduser_in,
		   p_lupduser_in, SYSDATE, l_fee_plan_id, l_flow_source,
		   l_crgl_catg, l_crgl_code, l_crsubgl_code, l_cracct_no,
		   l_drgl_catg, l_drgl_code, l_drsubgl_code, l_dracct_no,
		   l_valid_from, l_valid_to, l_st_crgl_catg, l_st_crgl_code,
		   l_st_crsubgl_code, l_st_cracct_no, l_st_drgl_catg,
		   l_st_drgl_code, l_st_drsubgl_code, l_st_dracct_no,
		   l_cess_crgl_catg, l_cess_crgl_code, l_cess_crsubgl_code,
		   l_cess_cracct_no, l_cess_drgl_catg, l_cess_drgl_code,
		   l_cess_drsubgl_code, l_cess_dracct_no, l_st_calc_flag,
		   l_cess_calc_flag, l_encr_pan, l_cardfee_id, '000');
	   
		-- end history table
		IF SQL%ROWCOUNT = 0
		THEN
		  l_errmsg   := 'INSERTING FEE PLAN ID IS NOT HAPPENED';
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
		END IF;
	   EXCEPTION
		WHEN exp_main_reject_record THEN
		  RAISE exp_main_reject_record;
		WHEN no_data_found THEN
		  BEGIN
		    SELECT cpf_fee_plan, cpf_flow_source, cpf_crgl_catg,
				 cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no,
				 cpf_drgl_catg, cpf_drgl_code, cpf_drsubgl_code,
				 cpf_dracct_no, cpf_valid_from, cpf_valid_to,
				 cpf_st_crgl_catg, cpf_st_crgl_code, cpf_st_crsubgl_code,
				 cpf_st_cracct_no, cpf_st_drgl_catg, cpf_st_drgl_code,
				 cpf_st_drsubgl_code, cpf_st_dracct_no,
				 cpf_cess_crgl_catg, cpf_cess_crgl_code,
				 cpf_cess_crsubgl_code, cpf_cess_cracct_no,
				 cpf_cess_drgl_catg, cpf_cess_drgl_code,
				 cpf_cess_drsubgl_code, cpf_cess_dracct_no,
				 cpf_st_calc_flag, cpf_cess_calc_flag
		    INTO   l_fee_plan_id, l_flow_source, l_crgl_catg, l_crgl_code,
				 l_crsubgl_code, l_cracct_no, l_drgl_catg, l_drgl_code,
				 l_drsubgl_code, l_dracct_no, l_valid_from, l_valid_to,
				 l_st_crgl_catg, l_st_crgl_code, l_st_crsubgl_code,
				 l_st_cracct_no, l_st_drgl_catg, l_st_drgl_code,
				 l_st_drsubgl_code, l_st_dracct_no, l_cess_crgl_catg,
				 l_cess_crgl_code, l_cess_crsubgl_code, l_cess_cracct_no,
				 l_cess_drgl_catg, l_cess_drgl_code, l_cess_drsubgl_code,
				 l_cess_dracct_no, l_st_calc_flag, l_cess_calc_flag
		    FROM   cms_prod_fees
		    WHERE  cpf_inst_code = p_instcode_in AND
				 cpf_prod_code = l_prod_code AND
				 ((cpf_valid_to IS NOT NULL AND
				 (l_tran_date BETWEEN cpf_valid_from AND cpf_valid_to)) OR
				 (cpf_valid_to IS NULL AND SYSDATE >= cpf_valid_from));
		  
		    INSERT INTO cms_card_excpfee
			 (cce_inst_code, cce_pan_code, cce_ins_date, cce_ins_user,
			  cce_lupd_user, cce_lupd_date, cce_fee_plan, cce_flow_source,
			  cce_crgl_catg, cce_crgl_code, cce_crsubgl_code,
			  cce_cracct_no, cce_drgl_catg, cce_drgl_code,
			  cce_drsubgl_code, cce_dracct_no, cce_valid_from,
			  cce_valid_to, cce_st_crgl_catg, cce_st_crgl_code,
			  cce_st_crsubgl_code, cce_st_cracct_no, cce_st_drgl_catg,
			  cce_st_drgl_code, cce_st_drsubgl_code, cce_st_dracct_no,
			  cce_cess_crgl_catg, cce_cess_crgl_code,
			  cce_cess_crsubgl_code, cce_cess_cracct_no,
			  cce_cess_drgl_catg, cce_cess_drgl_code,
			  cce_cess_drsubgl_code, cce_cess_dracct_no, cce_st_calc_flag,
			  cce_cess_calc_flag, cce_pan_code_encr)
		    VALUES
			 (p_instcode_in, l_hash_pan, SYSDATE, p_lupduser_in,
			  p_lupduser_in, SYSDATE, p_fee_plan_id_in, l_flow_source,
			  l_crgl_catg, l_crgl_code, l_crsubgl_code, l_cracct_no,
			  l_drgl_catg, l_drgl_code, l_drsubgl_code, l_dracct_no,
			  l_valid_from, l_valid_to, l_st_crgl_catg, l_st_crgl_code,
			  l_st_crsubgl_code, l_st_cracct_no, l_st_drgl_catg,
			  l_st_drgl_code, l_st_drsubgl_code, l_st_dracct_no,
			  l_cess_crgl_catg, l_cess_crgl_code, l_cess_crsubgl_code,
			  l_cess_cracct_no, l_cess_drgl_catg, l_cess_drgl_code,
			  l_cess_drsubgl_code, l_cess_dracct_no, l_st_calc_flag,
			  l_cess_calc_flag, l_encr_pan);
		  
		    SELECT cce_cardfee_id
		    INTO   l_cardfee_id
		    FROM   cms_card_excpfee
		    WHERE  cce_pan_code = l_hash_pan AND
				 cce_inst_code = p_instcode_in AND
				 ((cce_valid_to IS NOT NULL AND
				 (l_tran_date BETWEEN cce_valid_from AND cce_valid_to)) OR
				 (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from));
		  
		    --- for history table
		    INSERT INTO cms_card_excpfee_hist
			 (cce_inst_code, cce_pan_code, cce_ins_date, cce_mbr_numb,
			  cce_ins_user, cce_lupd_user, cce_lupd_date, cce_fee_plan,
			  cce_flow_source, cce_crgl_catg, cce_crgl_code,
			  cce_crsubgl_code, cce_cracct_no, cce_drgl_catg,
			  cce_drgl_code, cce_drsubgl_code, cce_dracct_no,
			  cce_valid_from, cce_valid_to, cce_st_crgl_catg,
			  cce_st_crgl_code, cce_st_crsubgl_code, cce_st_cracct_no,
			  cce_st_drgl_catg, cce_st_drgl_code, cce_st_drsubgl_code,
			  cce_st_dracct_no, cce_cess_crgl_catg, cce_cess_crgl_code,
			  cce_cess_crsubgl_code, cce_cess_cracct_no,
			  cce_cess_drgl_catg, cce_cess_drgl_code,
			  cce_cess_drsubgl_code, cce_cess_dracct_no, cce_st_calc_flag,
			  cce_cess_calc_flag, cce_pan_code_encr, cce_cardfee_id)
		    VALUES
			 (p_instcode_in, l_hash_pan, SYSDATE, '000', p_lupduser_in,
			  p_lupduser_in, SYSDATE, l_fee_plan_id, l_flow_source,
			  l_crgl_catg, l_crgl_code, l_crsubgl_code, l_cracct_no,
			  l_drgl_catg, l_drgl_code, l_drsubgl_code, l_dracct_no,
			  l_valid_from, l_valid_to, l_st_crgl_catg, l_st_crgl_code,
			  l_st_crsubgl_code, l_st_cracct_no, l_st_drgl_catg,
			  l_st_drgl_code, l_st_drsubgl_code, l_st_dracct_no,
			  l_cess_crgl_catg, l_cess_crgl_code, l_cess_crsubgl_code,
			  l_cess_cracct_no, l_cess_drgl_catg, l_cess_drgl_code,
			  l_cess_drsubgl_code, l_cess_dracct_no, l_st_calc_flag,
			  l_cess_calc_flag, l_encr_pan, l_cardfee_id);
		  
		    -- end history table
		    IF SQL%ROWCOUNT = 0
		    THEN
			 l_errmsg   := 'INSERTING FEE PLAN ID IS NOT HAPPENED';
			 l_respcode := '21';
			 RAISE exp_main_reject_record;
		    END IF;
		  EXCEPTION
		    WHEN exp_main_reject_record THEN
			 RAISE exp_main_reject_record;
		    WHEN no_data_found THEN
			 BEGIN
			   SELECT cdm_flow_source, cdm_crgl_catg, cdm_crgl_code,
					cdm_crsubgl_code, cdm_cracct_no, cdm_drgl_catg,
					cdm_drgl_code, cdm_drsubgl_code, cdm_dracct_no,
					cdm_valid_from, cdm_valid_to, cdm_st_crgl_catg,
					cdm_st_crgl_code, cdm_st_crsubgl_code,
					cdm_st_cracct_no, cdm_st_drgl_catg,
					cdm_st_drgl_code, cdm_st_drsubgl_code,
					cdm_st_dracct_no, cdm_cess_crgl_catg,
					cdm_cess_crgl_code, cdm_cess_crsubgl_code,
					cdm_cess_cracct_no, cdm_cess_drgl_catg,
					cdm_cess_drgl_code, cdm_cess_drsubgl_code,
					cdm_cess_dracct_no, cdm_st_calc_flag,
					cdm_cess_calc_flag
			   --updated by ramesh.a on 30/07/2012
			   INTO   l_flow_source, l_crgl_catg, l_crgl_code,
					l_crsubgl_code, l_cracct_no, l_drgl_catg,
					l_drgl_code, l_drsubgl_code, l_dracct_no,
					l_valid_from, l_valid_to, l_st_crgl_catg,
					l_st_crgl_code, l_st_crsubgl_code, l_st_cracct_no,
					l_st_drgl_catg, l_st_drgl_code, l_st_drsubgl_code,
					l_st_dracct_no, l_cess_crgl_catg, l_cess_crgl_code,
					l_cess_crsubgl_code, l_cess_cracct_no,
					l_cess_drgl_catg, l_cess_drgl_code,
					l_cess_drsubgl_code, l_cess_dracct_no,
					l_st_calc_flag, l_cess_calc_flag
			   --updated by ramesh.a on 30/07/2012
			   FROM   cms_default_glacct_mast
			   WHERE  cdm_inst_code = p_instcode_in;
			 
			   INSERT INTO cms_card_excpfee
				(cce_inst_code, cce_pan_code, cce_ins_date,
				 cce_ins_user, cce_lupd_user, cce_lupd_date,
				 cce_fee_plan, cce_flow_source, cce_crgl_catg,
				 cce_crgl_code, cce_crsubgl_code, cce_cracct_no,
				 cce_drgl_catg, cce_drgl_code, cce_drsubgl_code,
				 cce_dracct_no, cce_valid_from, cce_valid_to,
				 cce_st_crgl_catg, cce_st_crgl_code, cce_st_crsubgl_code,
				 cce_st_cracct_no, cce_st_drgl_catg, cce_st_drgl_code,
				 cce_st_drsubgl_code, cce_st_dracct_no,
				 cce_cess_crgl_catg, cce_cess_crgl_code,
				 cce_cess_crsubgl_code, cce_cess_cracct_no,
				 cce_cess_drgl_catg, cce_cess_drgl_code,
				 cce_cess_drsubgl_code, cce_cess_dracct_no,
				 cce_st_calc_flag, cce_cess_calc_flag, cce_pan_code_encr)
			   VALUES
				(p_instcode_in, l_hash_pan, SYSDATE, p_lupduser_in,
				 p_lupduser_in, SYSDATE, p_fee_plan_id_in, l_flow_source,
				 l_crgl_catg, l_crgl_code, l_crsubgl_code, l_cracct_no,
				 l_drgl_catg, l_drgl_code, l_drsubgl_code, l_dracct_no,
				 l_valid_from, l_valid_to, l_st_crgl_catg,
				 l_st_crgl_code, l_st_crsubgl_code, l_st_cracct_no,
				 l_st_drgl_catg, l_st_drgl_code, l_st_drsubgl_code,
				 l_st_dracct_no, l_cess_crgl_catg, l_cess_crgl_code,
				 l_cess_crsubgl_code, l_cess_cracct_no, l_cess_drgl_catg,
				 l_cess_drgl_code, l_cess_drsubgl_code, l_cess_dracct_no,
				 l_st_calc_flag, l_cess_calc_flag, l_encr_pan);
			 
			   SELECT cce_cardfee_id
			   INTO   l_cardfee_id
			   FROM   cms_card_excpfee
			   WHERE  cce_pan_code = l_hash_pan AND
					cce_inst_code = p_instcode_in AND
					((cce_valid_to IS NOT NULL AND
					(l_tran_date BETWEEN cce_valid_from AND
					cce_valid_to)) OR (cce_valid_to IS NULL AND
					SYSDATE >= cce_valid_from));
			 
			   ---st for history table
			   INSERT INTO cms_card_excpfee_hist
				(cce_inst_code, cce_pan_code, cce_ins_date,
				 cce_mbr_numb, cce_ins_user, cce_lupd_user,
				 cce_lupd_date, cce_fee_plan, cce_flow_source,
				 cce_crgl_catg, cce_crgl_code, cce_crsubgl_code,
				 cce_cracct_no, cce_drgl_catg, cce_drgl_code,
				 cce_drsubgl_code, cce_dracct_no, cce_valid_from,
				 cce_valid_to, cce_st_crgl_catg, cce_st_crgl_code,
				 cce_st_crsubgl_code, cce_st_cracct_no, cce_st_drgl_catg,
				 cce_st_drgl_code, cce_st_drsubgl_code, cce_st_dracct_no,
				 cce_cess_crgl_catg, cce_cess_crgl_code,
				 cce_cess_crsubgl_code, cce_cess_cracct_no,
				 cce_cess_drgl_catg, cce_cess_drgl_code,
				 cce_cess_drsubgl_code, cce_cess_dracct_no,
				 cce_st_calc_flag, cce_cess_calc_flag, cce_pan_code_encr,
				 cce_cardfee_id)
			   VALUES
				(p_instcode_in, l_hash_pan, SYSDATE, '000',
				 p_lupduser_in, p_lupduser_in, SYSDATE, p_fee_plan_id_in,
				 l_flow_source, l_crgl_catg, l_crgl_code, l_crsubgl_code,
				 l_cracct_no, l_drgl_catg, l_drgl_code, l_drsubgl_code,
				 l_dracct_no, l_valid_from, l_valid_to, l_st_crgl_catg,
				 l_st_crgl_code, l_st_crsubgl_code, l_st_cracct_no,
				 l_st_drgl_catg, l_st_drgl_code, l_st_drsubgl_code,
				 l_st_dracct_no, l_cess_crgl_catg, l_cess_crgl_code,
				 l_cess_crsubgl_code, l_cess_cracct_no, l_cess_drgl_catg,
				 l_cess_drgl_code, l_cess_drsubgl_code, l_cess_dracct_no,
				 l_st_calc_flag, l_cess_calc_flag, l_encr_pan,
				 l_cardfee_id);
			 
			   -- end history table
			   IF SQL%ROWCOUNT = 0
			   THEN
				l_errmsg   := 'INSERTING DEFAULT FEE PLAN ID IS NOT HAPPENED';
				l_respcode := '21';
				RAISE exp_main_reject_record;
			   END IF;
			 EXCEPTION
			   WHEN exp_main_reject_record THEN
				RAISE exp_main_reject_record;
			   WHEN no_data_found THEN
				l_errmsg   := 'NO DATA FOUND IN DEFAULT GL MAPPING TABLE';
				l_respcode := '21';
				RAISE exp_main_reject_record;
			   WHEN OTHERS THEN
				l_errmsg   := 'ERROR WHILE SELECTING DEFAULT ENTRY IN GL MAPPING ' ||
						    substr(SQLERRM, 1, 200);
				l_respcode := '21';
				RAISE exp_main_reject_record;
			 END;
		    WHEN OTHERS THEN
			 l_errmsg   := 'ERROR WHILE SELECTING FEE PLAN DETAILS PRODUCT LEVEL ' ||
						substr(SQLERRM, 1, 200);
			 l_respcode := '21';
			 RAISE exp_main_reject_record;
		  END;
		WHEN OTHERS THEN
		  l_errmsg   := 'ERROR WHILE SELECTING FEE PLAN DETAILS PRODUCT CARD TYPE LEVEL ' ||
					 substr(SQLERRM, 1, 200);
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
	   END;
	 WHEN OTHERS THEN
	   l_errmsg   := 'ERROR WHILE UPDATING FEE PLAN ID ' ||
				  substr(SQLERRM, 1, 200);
	   l_respcode := '21';
	   RAISE exp_main_reject_record;
    END;
  
    --sn generate auth id
    BEGIN
	 SELECT lpad(seq_auth_id.NEXTVAL, 6, '0')
	 INTO   l_inil_authid
	 FROM   dual;
    EXCEPTION
	 WHEN OTHERS THEN
	   l_errmsg   := 'ERROR WHILE GENERATING AUTHID ' ||
				  substr(SQLERRM, 1, 300);
	   l_respcode := '21'; -- server declined
    END;
  
    --en generate auth id
  
    -- Migration Proxy validation  
  
    BEGIN
	 IF l_spend_card_status NOT IN ('0', '1', '2', '3', '8')
	 THEN
	   l_respcode   := '262';
	   p_errmsg_out := l_spend_card_status;
	   l_errmsg     := 'INVALID MIGRATION  CARD STATUS ';
	   RAISE exp_main_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE VALIDATING MIGRATION CARD STATUS ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 UPDATE cms_appl_pan
	 SET    CAP_ACCT_NO = L_SPEND_ACCT_NO, CAP_ACCT_ID = L_SPEND_ACCT_ID,
          CAP_CUST_CODE= L_MIGR_CUST_CODE --Added for 4.0.3 changes
          ,CAP_BILL_ADDR=l_migr_bill_addr --FSS-4898 CSDesktop account statement is not working for migrated momentum MasterCard Cards end
	 WHERE  cap_inst_code = p_instcode_in AND cap_pan_code = l_hash_pan;
    
	 UPDATE CMS_APPL_MAST
	 SET    CAM_CUST_CODE = L_MIGR_CUST_CODE,
   CAM_BILL_ADDR=l_migr_bill_addr
	 WHERE  cam_appl_code = l_appl_code AND cam_inst_code = p_instcode_in;
   
   UPDATE cms_appl_det
	 SET    cad_acct_id = l_spend_acct_id
	 WHERE  cad_appl_code = l_appl_code AND cad_inst_code = p_instcode_in;
    
	 p_dda_number_out := l_spend_acct_no;
    
	 IF SQL%ROWCOUNT = 0
	 THEN
	   l_errmsg   := 'ERROR WHILE UPDATING MIGRATION ACCOUNT NUMBER ';
	   l_respcode := '89';
	   RAISE exp_main_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE UPDATING MIGRATION ACCOUNT NUMBER ' ||
				  substr(SQLERRM, 1, 100);
	   RAISE exp_main_reject_record;
    END;
  
 --SN:Commented for 4.0.3 changes
 /*   BEGIN
    
	 UPDATE cms_cust_acct
	 SET    cca_acct_id = l_spend_acct_id
	 WHERE  cca_cust_code = l_cust_code AND cca_acct_id = l_acct_id AND
		   cca_inst_code = p_instcode_in;
    
	 IF SQL%ROWCOUNT = 0
	 THEN
	   l_errmsg   := 'ERROR WHILE UPDATING CMS_CUST_ACCT ';
	   l_respcode := '89';
	   RAISE exp_main_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE UPDATING CMS_CUST_ACCT  ' ||
				  substr(SQLERRM, 1, 100);
	   RAISE exp_main_reject_record;
    END; 
  
    BEGIN
	 IF l_saving_acct_exist = 'Y'
	 THEN
	 
	   INSERT INTO cms_cust_acct
		(cca_inst_code, cca_cust_code, cca_acct_id, cca_acct_name,
		 cca_hold_posn, cca_rel_stat, cca_ins_user, cca_ins_date,
		 cca_lupd_user, cca_lupd_date, cca_threshold_limit,
		 cca_threshold_amt, cca_threshold_acctno, cca_threshold_bank,
		 cca_threshold_branch, cca_threshold_ifcs, cca_threshold_rtg,
		 cca_threshold_micr, cca_fundtrans_amt, cca_fundtrans_acctno,
		 cca_fundtrans_bank, cca_fundtrans_branch, cca_fundtrans_ifcs,
		 cca_fundtrans_rtg, cca_fundtrans_micr, cca_threshold_filegen_flag,
		 cca_fundtrans_filegen_flag)
	   VALUES
		(p_instcode_in, l_cust_code, l_saving_acct_id, NULL, 1, 'Y',
		 p_lupduser_in, SYSDATE, p_lupduser_in, SYSDATE, NULL, NULL, NULL,
		 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		 NULL, NULL, NULL);
	 END IF;
    EXCEPTION
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE INSERTING CMS_CUST_ACCT  ' ||
				  substr(SQLERRM, 1, 100);
	   RAISE exp_main_reject_record;
    END;*/
  --EN:Commented for 4.0.3 changes
  
    BEGIN
    
	 --SN: Modified for 4.0.3 changes
   /*UPDATE cms_pan_acct
	 SET    cpa_acct_id = l_spend_acct_id
	 WHERE  cpa_cust_code = l_cust_code AND cpa_acct_id = l_acct_id AND
		   cpa_inst_code = p_instcode_in;*/
       
   UPDATE CMS_PAN_ACCT
	 SET    cpa_acct_id = l_spend_acct_id, 
          cpa_cust_code=l_migr_cust_code
	 WHERE CPA_INST_CODE = P_INSTCODE_IN  AND CPA_ACCT_ID = L_ACCT_ID 
        AND cpa_mbr_numb=l_mbrnumb AND cpa_pan_code=l_hash_pan;
   --EN: Modified for 4.0.3 changes       
    
	 IF SQL%ROWCOUNT = 0
	 THEN
	   l_errmsg   := 'ERROR WHILE UPDATING CMS_PAN_ACCT ';
	   l_respcode := '89';
	   RAISE exp_main_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE UPDATING CMS_PAN_ACCT  ' ||
				  substr(SQLERRM, 1, 100);
	   RAISE exp_main_reject_record;
    END;
  
    IF l_cap_prod_catg = 'P'
    THEN
	 --sn call to authorize txn
	 BEGIN
	   sp_authorize_txn_cms_auth(p_instcode_in, p_msg_type_in, p_rrn_in,
						    p_delivery_channel_in, p_terminalid_in,
						    p_txn_code_in, p_txn_mode_in,
						    p_trandate_in, p_trantime_in, p_card_no_in,
						    NULL, p_amount_in, p_merchant_name_in,
						    p_merchant_city_in, NULL, l_currcode, NULL,
						    NULL, NULL, NULL, NULL, NULL, NULL, NULL,
						    NULL, NULL, NULL, NULL, NULL, l_stan,
						    p_mbr_numb_in, p_rvsl_code_in, l_tran_amt,
						    l_inil_authid, l_respcode, l_respmsg,
						    l_capture_date);
	 
	   IF l_respcode <> '00' AND l_respmsg <> 'OK'
	   THEN
		l_errmsg := l_respmsg;
		RAISE exp_auth_reject_record;
	   END IF;
	 EXCEPTION
	   WHEN exp_main_reject_record THEN
		RAISE;
	   WHEN exp_auth_reject_record THEN
		RAISE;
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := substr(SQLERRM, 'ERROR FROM CARD AUTHORIZATION' || 1,
						 200);
		RAISE exp_main_reject_record;
	 END;
	 --en call to authorize txn
    END IF;
  
    IF p_optin_list_in IS NOT NULL
    THEN
	 BEGIN
	   LOOP
		l_comma_pos := instr(p_optin_list_in, ',', 1, i);
	   
		IF i = 1 AND l_comma_pos = 0
		THEN
		  l_optin_list := p_optin_list_in;
		ELSIF i <> 1 AND l_comma_pos = 0
		THEN
		  l_comma_pos1 := instr(p_optin_list_in, ',', 1, i - 1);
		  l_optin_list := substr(p_optin_list_in, l_comma_pos1 + 1);
		ELSIF i <> 1 AND l_comma_pos <> 0
		THEN
		  l_comma_pos1 := instr(p_optin_list_in, ',', 1, i - 1);
		  l_optin_list := substr(p_optin_list_in, l_comma_pos1 + 1,
							l_comma_pos - l_comma_pos1 - 1);
		ELSIF i = 1 AND l_comma_pos <> 0
		THEN
		  l_optin_list := substr(p_optin_list_in, 1, l_comma_pos - 1);
		END IF;
	   
		i := i + 1;
	   
		l_optin_type  := substr(l_optin_list, 1,
						    instr(l_optin_list, ':', 1, 1) - 1);
		l_optin_split := substr(l_optin_list,
						    instr(l_optin_list, ':', 1, 1) + 1);
	   
		BEGIN
		  IF l_optin_type IS NOT NULL AND l_optin_type = '1'
		  THEN
		    l_sms_optinflag := l_optin_split;
		    l_optin_flag    := 'Y';
		  ELSIF l_optin_type IS NOT NULL AND l_optin_type = '2'
		  THEN
		    l_email_optinflag := l_optin_split;
		    l_optin_flag      := 'Y';
		  ELSIF l_optin_type IS NOT NULL AND l_optin_type = '3'
		  THEN
		    l_markmsg_optinflag := l_optin_split;
		    l_optin_flag        := 'Y';
		  ELSIF l_optin_type IS NOT NULL AND l_optin_type = '4'
		  THEN
		    l_gpresign_optinflag := l_optin_split;
		    l_optin_flag         := 'Y';
		  ELSIF l_optin_type IS NOT NULL AND l_optin_type = '5'
		  THEN
		    l_savingsesign_optinflag := l_optin_split;
		    l_optin_flag             := 'Y';
		  END IF;
		END;
	   
		IF l_comma_pos = 0
		THEN
		  EXIT;
		END IF;
	   END LOOP;
	 
	   IF l_optin_flag = 'Y'
	   THEN
		BEGIN
		  SELECT COUNT(*)
		  INTO   l_count
		  FROM   cms_optin_status
		  WHERE  COS_INST_CODE = P_INSTCODE_IN AND
			    cos_cust_id = l_migr_cust_id;--l_cust_id;  --Modified for 4.0.3 changes
		
		  IF l_count > 0
		  THEN
		    UPDATE cms_optin_status
		    SET    cos_sms_optinflag = nvl(l_sms_optinflag,
									 cos_sms_optinflag),
				 cos_sms_optintime = nvl(decode(l_sms_optinflag, '1',
										   systimestamp, NULL),
									 cos_sms_optintime),
				 cos_sms_optouttime = nvl(decode(l_sms_optinflag, '0',
										    systimestamp, NULL),
									  cos_sms_optouttime),
				 cos_email_optinflag = nvl(l_email_optinflag,
									   cos_email_optinflag),
				 cos_email_optintime = nvl(decode(l_email_optinflag, '1',
											systimestamp, NULL),
									   cos_email_optintime),
				 cos_email_optouttime = nvl(decode(l_email_optinflag, '0',
											 systimestamp, NULL),
									    cos_email_optouttime),
				 cos_markmsg_optinflag = nvl(l_markmsg_optinflag,
										cos_markmsg_optinflag),
				 cos_markmsg_optintime = nvl(decode(l_markmsg_optinflag,
											  '1', systimestamp,
											  NULL),
										cos_markmsg_optintime),
				 cos_markmsg_optouttime = nvl(decode(l_markmsg_optinflag,
											   '0', systimestamp,
											   NULL),
										 cos_markmsg_optouttime),
				 cos_gpresign_optinflag = nvl(l_gpresign_optinflag,
										 cos_gpresign_optinflag),
				 cos_gpresign_optintime = nvl(decode(l_gpresign_optinflag,
											   '1', systimestamp,
											   NULL),
										 cos_gpresign_optintime),
				 cos_gpresign_optouttime = nvl(decode(l_gpresign_optinflag,
											    '0', systimestamp,
											    NULL),
										  cos_gpresign_optouttime),
				 cos_savingsesign_optinflag = nvl(l_savingsesign_optinflag,
											cos_savingsesign_optinflag),
				 cos_savingsesign_optintime = nvl(decode(l_savingsesign_optinflag,
												  '1', systimestamp,
												  NULL),
											cos_savingsesign_optintime),
				 cos_savingsesign_optouttime = nvl(decode(l_savingsesign_optinflag,
												   '0',
												   systimestamp,
												   NULL),
											 cos_savingsesign_optouttime)
		    
		    WHERE  COS_INST_CODE = P_INSTCODE_IN AND
				 cos_cust_id = l_migr_cust_id;--l_cust_id; --Modified for 4.0.3 changes
		  ELSE
		    INSERT INTO cms_optin_status
			 (cos_inst_code, cos_cust_id, cos_sms_optinflag,
			  cos_sms_optintime, cos_sms_optouttime, cos_email_optinflag,
			  cos_email_optintime, cos_email_optouttime,
			  cos_markmsg_optinflag, cos_markmsg_optintime,
			  cos_markmsg_optouttime, cos_gpresign_optinflag,
			  cos_gpresign_optintime, cos_gpresign_optouttime,
			  cos_savingsesign_optinflag, cos_savingsesign_optintime,
			  cos_savingsesign_optouttime)
		    VALUES
			 (P_INSTCODE_IN,L_MIGR_CUST_ID,-- l_cust_id, --Modified for 4.0.3 changes
        l_sms_optinflag,
			  decode(l_sms_optinflag, '1', systimestamp, NULL),
			  decode(l_sms_optinflag, '0', systimestamp, NULL),
			  l_email_optinflag,
			  decode(l_email_optinflag, '1', systimestamp, NULL),
			  decode(l_email_optinflag, '0', systimestamp, NULL),
			  l_markmsg_optinflag,
			  decode(l_markmsg_optinflag, '1', systimestamp, NULL),
			  decode(l_markmsg_optinflag, '0', systimestamp, NULL),
			  l_gpresign_optinflag,
			  decode(l_gpresign_optinflag, '1', systimestamp, NULL),
			  decode(l_gpresign_optinflag, '0', systimestamp, NULL),
			  l_savingsesign_optinflag,
			  decode(l_savingsesign_optinflag, '1', systimestamp, NULL),
			  decode(l_savingsesign_optinflag, '0', systimestamp, NULL));
		  END IF;
		EXCEPTION
		  WHEN OTHERS THEN
		    l_respcode := '21';
		    l_errmsg   := 'ERROR IN INSERTING RECORDS IN CMS_OPTIN_STATUS' ||
					   substr(SQLERRM, 1, 300);
		    RAISE exp_auth_reject_record;
		END;
	   END IF;
	 END;
    
   --SN: Commented for 4.0.3 Changes
   /* ELSE
    
	 BEGIN
	   SELECT COUNT(*)
	   INTO   l_count_migr
	   FROM   cms_optin_status
	   WHERE  cos_inst_code = p_instcode_in AND
			cos_cust_id = l_migr_cust_id;
	 
	   IF l_count_migr > 0
	   THEN
	   
		SELECT cos_sms_optinflag, cos_sms_optintime, cos_sms_optouttime,
			  cos_email_optinflag, cos_email_optintime,
			  cos_email_optouttime, cos_markmsg_optinflag,
			  cos_markmsg_optintime, cos_markmsg_optouttime,
			  cos_gpresign_optinflag, cos_gpresign_optintime,
			  cos_gpresign_optouttime, cos_savingsesign_optinflag,
			  cos_savingsesign_optintime, cos_savingsesign_optouttime
		INTO   l_sms_optinflag, l_sms_optintime, l_sms_optouttime,
			  l_email_optinflag, l_email_optintime, l_email_optouttime,
			  l_markmsg_optinflag, l_markmsg_optintime,
			  l_markmsg_optouttime, l_gpresign_optinflag,
			  l_gpresign_optintime, l_gpresign_optouttime,
			  l_savingsesign_optinflag, l_savingsesign_optintime,
			  l_savingsesign_optouttime
		FROM   cms_optin_status
		WHERE  cos_inst_code = p_instcode_in AND
			  cos_cust_id = l_migr_cust_id;
	   
		SELECT COUNT(*)
		INTO   l_count
		FROM   cms_optin_status
		WHERE  cos_inst_code = p_instcode_in AND cos_cust_id = l_cust_id;
	   
		IF l_count > 0
		THEN
		  UPDATE cms_optin_status
		  SET    cos_sms_optinflag = l_sms_optinflag,
			    cos_sms_optintime = l_sms_optintime,
			    cos_sms_optouttime = l_sms_optouttime,
			    cos_email_optinflag = l_email_optinflag,
			    cos_email_optintime = l_email_optintime,
			    cos_email_optouttime = l_email_optouttime,
			    cos_markmsg_optinflag = l_markmsg_optinflag,
			    cos_markmsg_optintime = l_markmsg_optintime,
			    cos_markmsg_optouttime = l_markmsg_optouttime,
			    cos_gpresign_optinflag = l_gpresign_optinflag,
			    cos_gpresign_optintime = l_gpresign_optintime,
			    cos_gpresign_optouttime = l_gpresign_optouttime,
			    cos_savingsesign_optinflag = l_savingsesign_optinflag,
			    cos_savingsesign_optintime = l_savingsesign_optintime,
			    cos_savingsesign_optouttime = l_savingsesign_optouttime
		  WHERE  cos_inst_code = p_instcode_in AND
			    cos_cust_id = l_cust_id;
		ELSE
		  INSERT INTO cms_optin_status
		    (cos_inst_code, cos_cust_id, cos_sms_optinflag,
			cos_sms_optintime, cos_sms_optouttime, cos_email_optinflag,
			cos_email_optintime, cos_email_optouttime,
			cos_markmsg_optinflag, cos_markmsg_optintime,
			cos_markmsg_optouttime, cos_gpresign_optinflag,
			cos_gpresign_optintime, cos_gpresign_optouttime,
			cos_savingsesign_optinflag, cos_savingsesign_optintime,
			cos_savingsesign_optouttime)
		  VALUES
		    (p_instcode_in, l_cust_id, l_sms_optinflag, l_sms_optintime,
			l_sms_optouttime, l_email_optinflag, l_email_optintime,
			l_email_optouttime, l_markmsg_optinflag, l_markmsg_optintime,
			l_markmsg_optouttime, l_gpresign_optinflag,
			l_gpresign_optintime, l_gpresign_optouttime,
			l_savingsesign_optinflag, l_savingsesign_optintime,
			l_savingsesign_optouttime);
		END IF;
	   END IF;
	 EXCEPTION
	   WHEN OTHERS THEN
		l_errmsg := 'ERROR WHILE INSERTING CMS_OPTIN_STATUS TABLE' ||
				  SQLERRM;
		RAISE exp_main_reject_record;
	 END; */
   --EN: Commented for 4.0.3 Changes
    END IF;
  
    IF p_optin_in IS NULL
    THEN
	 IF l_sms_optinflag = '1' AND l_email_optinflag = '1'
	 THEN
	   l_optin := 3;
	 ELSIF l_sms_optinflag = '0' AND l_email_optinflag = '1'
	 THEN
	   l_optin := 2;
	 ELSIF l_sms_optinflag = '1' AND l_email_optinflag = '0'
	 THEN
	   l_optin := 1;
	 ELSIF l_sms_optinflag = '0' AND l_email_optinflag = '0'
	 THEN
	   l_optin := 0;
	 END IF;
    ELSE
	 l_optin := p_optin_in;
    END IF;
  
    IF p_optin_list_in IS NULL AND p_optin_in IS NULL
    THEN
	 BEGIN
	   SELECT csa_loadorcredit_flag, csa_lowbal_flag, csa_negbal_flag,
			csa_highauthamt_flag, csa_dailybal_flag, csa_insuff_flag,
			csa_incorrpin_flag, csa_fast50_flag, csa_fedtax_refund_flag,
			csa_cellphonecarrier, csa_lowbal_amt, csa_highauthamt,
			csa_c2c_flag, csa_alert_lang_id
	   INTO   l_loadcredit_flag, l_lowbal_flag, l_negativebal_flag,
			l_highauthamt_flag, l_dailybal_flag, l_insuffund_flag,
			l_incorrectpin_flag, l_fast50_flag, l_federal_flag,
			l_cellphonecarrier, l_lowbal_amt, l_highauthamt, l_c2c_flag,
			l_alert_lang_id
	   FROM   cms_smsandemail_alert
	   WHERE  csa_inst_code = p_instcode_in AND
			csa_pan_code = l_migr_hash_pan;
	 
	   UPDATE cms_smsandemail_alert
	   SET    csa_loadorcredit_flag = l_loadcredit_flag,
			csa_lowbal_flag = l_lowbal_flag,
			csa_negbal_flag = l_negativebal_flag,
			csa_highauthamt_flag = l_highauthamt_flag,
			csa_dailybal_flag = l_dailybal_flag,
			csa_insuff_flag = l_insuffund_flag,
			csa_incorrpin_flag = l_incorrectpin_flag,
			csa_fast50_flag = l_fast50_flag,
			csa_fedtax_refund_flag = l_federal_flag,
			csa_cellphonecarrier = l_cellphonecarrier,
			csa_c2c_flag = l_c2c_flag, csa_lupd_date = SYSDATE,
			csa_lowbal_amt = nvl(l_lowbal_amt, 0),
			csa_highauthamt = nvl(l_highauthamt, 0),
			csa_alert_lang_id = l_alert_lang_id
	   WHERE  csa_inst_code = p_instcode_in AND csa_pan_code = l_hash_pan;
	 
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
    ELSE
	 BEGIN
	   SELECT csa_alert_lang_id
	   INTO   l_alert_lang_id
	   FROM   cms_smsandemail_alert
	   WHERE  csa_inst_code = p_instcode_in AND csa_pan_code = l_hash_pan;
	 EXCEPTION
	   WHEN no_data_found THEN
		l_respcode := '21';
		l_errmsg   := 'No Alert Details found for the card ' ||
				    fn_mask(p_card_no_in, 'X', 7, 6);
		RAISE exp_main_reject_record;
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := 'Error while Selecting Alert Details of Card' ||
				    substr(SQLERRM, 1, 200);
		RAISE exp_main_reject_record;
	 END;
    
	 IF l_alert_lang_id IS NULL
	 THEN
	 
	   BEGIN
		SELECT cps_alert_lang_id
		INTO   l_alert_lang_id
		FROM   cms_prodcatg_smsemail_alerts
		WHERE  cps_inst_code = p_instcode_in AND
			  cps_prod_code = l_prod_code AND
			  cps_card_type = l_card_type AND
			  cps_defalert_lang_flag = 'Y' AND rownum = 1;
	   EXCEPTION
		WHEN OTHERS THEN
		  l_respcode := '21';
		  l_errmsg   := 'Error while Selecting dafault alert  language id ' ||
					 substr(SQLERRM, 1, 200);
		  RAISE exp_main_reject_record;
	   END;
	 
	 END IF;
    
	 BEGIN
	   FOR i1 IN l_cur_alert_config(p_instcode_in, l_prod_code, l_card_type,
							  l_alert_lang_id)
	   LOOP
		IF i1.cps_alert_id = '9'
		THEN
		  l_loadcredit_flag := i1.alert_flag;
		END IF;
		IF i1.cps_alert_id = '10'
		THEN
		  l_lowbal_flag := i1.alert_flag;
		END IF;
	   
		IF i1.cps_alert_id = '11'
		THEN
		  l_negativebal_flag := i1.alert_flag;
		END IF;
	   
		IF i1.cps_alert_id = '13'
		THEN
		  l_incorrectpin_flag := i1.alert_flag;
		END IF;
	   
		IF i1.cps_alert_id = '16'
		THEN
		  l_highauthamt_flag := i1.alert_flag;
		END IF;
	   
		IF i1.cps_alert_id = '12'
		THEN
		  l_dailybal_flag := i1.alert_flag;
		END IF;
	   
		IF i1.cps_alert_id = '17'
		THEN
		  l_insuffund_flag := i1.alert_flag;
		END IF;
	   
		IF i1.cps_alert_id = '21'
		THEN
		  l_fast50_flag := i1.alert_flag;
		END IF;
	   
		IF i1.cps_alert_id = '22'
		THEN
		  l_federal_flag := i1.alert_flag;
		END IF;
	   
	   END LOOP;
	 
	 EXCEPTION
	   WHEN no_data_found THEN
		l_respcode := '21';
		l_errmsg   := 'Invalid product code ' || l_prod_code ||
				    ' and card type' || l_card_type;
		RAISE exp_main_reject_record;
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := 'Error while selecting alerts for ' || l_prod_code ||
				    ' and ' || l_card_type || '  ' ||
				    substr(SQLERRM, 1, 200);
		RAISE exp_main_reject_record;
	 END;
    
	 BEGIN
	   UPDATE cms_smsandemail_alert
	   SET    csa_loadorcredit_flag = decode(nvl(l_loadcredit_flag, 0), '0',
									  '0', l_optin),
			csa_lowbal_flag = decode(nvl(l_lowbal_flag, 0), '0', '0',
								 l_optin),
			csa_negbal_flag = decode(nvl(l_negativebal_flag, 0), '0', '0',
								 l_optin),
			csa_highauthamt_flag = decode(nvl(l_highauthamt_flag, 0), '0',
									 '0', l_optin),
			csa_dailybal_flag = decode(nvl(l_dailybal_flag, 0), '0', '0',
								   l_optin),
			csa_insuff_flag = decode(nvl(l_insuffund_flag, 0), '0', '0',
								 l_optin),
			csa_incorrpin_flag = decode(nvl(l_incorrectpin_flag, 0), '0',
								    '0', l_optin),
			csa_fast50_flag = decode(nvl(l_fast50_flag, 0), '0', '0',
								 l_optin),
			csa_fedtax_refund_flag = decode(nvl(l_federal_flag, 0), '0',
									   '0', l_optin),
			csa_lupd_date = SYSDATE,
			csa_begin_time = nvl(csa_begin_time, 0),
			csa_end_time = nvl(csa_end_time, 0),
			csa_lowbal_amt = nvl(csa_lowbal_amt, 0),
			csa_highauthamt = nvl(csa_highauthamt, 0),
			csa_alert_lang_id = l_alert_lang_id --Added for FWR-59
	   WHERE  csa_inst_code = p_instcode_in AND csa_pan_code = l_hash_pan;
	 
	   IF SQL%ROWCOUNT = 0
	   THEN
		p_errmsg_out := 'Error while Updating Optin_alerts in CMS_SMSANDEMAIL_ALERT' ||
					 substr(SQLERRM, 1, 200);
		l_respcode   := '21';
		RAISE exp_main_reject_record;
	   END IF;
	 EXCEPTION
	   WHEN exp_main_reject_record THEN
		RAISE exp_main_reject_record;
	   WHEN OTHERS THEN
		p_errmsg_out := 'Error while Updating Optin_alerts in CMS_SMSANDEMAIL_ALERT table' ||
					 substr(SQLERRM, 1, 200);
		l_respcode   := '21';
		RAISE exp_main_reject_record;
	   
	 END;
    END IF;
  
    IF l_gpresign_optinflag = '1'
    THEN
    
	 BEGIN
	   SELECT nvl(cpp_tandc_version, '')
	   INTO   l_tandc_version
	   FROM   cms_product_param
	   WHERE  cpp_prod_code = l_prod_code;
	 EXCEPTION
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := 'ERROR FROM  FEATCHING THE T AND C VERSION ' ||
				    substr(SQLERRM, 1, 200);
		RAISE exp_auth_reject_record;
	 END;
    
	 BEGIN
	   UPDATE cms_cust_mast
	   SET    ccm_tandc_version = l_tandc_version
	   WHERE  CCM_INST_CODE = P_INSTCODE_IN AND
			ccm_cust_code = l_migr_cust_code;  --Modified for 4.0.3 changes
	   IF SQL%ROWCOUNT = 0
	   THEN
		l_respcode := '21';
		l_errmsg   := 'ERROR WHILE UPDATING T AND C VERSION ' ||
				    substr(SQLERRM, 1, 200);
		RAISE exp_auth_reject_record;
	   END IF;
	 EXCEPTION
	   WHEN exp_auth_reject_record THEN
		RAISE;
	   WHEN OTHERS THEN
		p_resp_code_out := '21';
		l_errmsg        := 'ERROR WHILE UPDATING T AND C VERSION ' ||
					    substr(SQLERRM, 1, 200);
		RAISE exp_auth_reject_record;
	 END;
    
    END IF;
  
    IF p_delivery_channel_in = '04' AND p_txn_code_in = '68'
    THEN
	 IF l_lmtprfl IS NULL OR l_profile_level IS NULL
	 THEN
	   BEGIN
		SELECT cpl_lmtprfl_id
		INTO   l_lmtprfl
		FROM   cms_prdcattype_lmtprfl
		WHERE  cpl_inst_code = l_inst_code AND
			  cpl_prod_code = l_prod_code AND
			  cpl_card_type = l_card_type;
	   
		l_profile_level := 2;
	   EXCEPTION
		WHEN no_data_found THEN
		  BEGIN
		    SELECT cpl_lmtprfl_id
		    INTO   l_lmtprfl
		    FROM   cms_prod_lmtprfl
		    WHERE  cpl_inst_code = l_inst_code AND
				 cpl_prod_code = l_prod_code;
		  
		    l_profile_level := 3;
		  EXCEPTION
		    WHEN no_data_found THEN
			 NULL;
		    WHEN OTHERS THEN
			 l_errmsg := 'ERROR WHILE SELECTING LIMIT PROFILE AT PRODUCT LEVEL' ||
					   SQLERRM;
			 RAISE exp_main_reject_record;
		  END;
		WHEN OTHERS THEN
		  l_errmsg := 'ERROR WHILE SELECTING LIMIT PROFILE AT PRODUCT CATAGORY LEVEL' ||
				    SQLERRM;
		  RAISE exp_main_reject_record;
	   END;
	 END IF;
    END IF;
  
    BEGIN
    
	 IF l_cap_card_stat <> 0
	 THEN
	   l_respcode := '10';
	   l_errmsg   := 'CARD MUST BE IN INACTIVE STATUS FOR ACTIVATION';
	   RAISE exp_main_reject_record;
	 ELSIF l_firsttime_topup <> 'N'
	 THEN
	   l_respcode := '28';
	   l_errmsg   := 'CARD FIRST TIME TOPUP MUST BE N STATUS FOR ACTIVATION';
	   RAISE exp_main_reject_record;
	 END IF;
    
	 BEGIN
	   sp_log_cardstat_chnge(p_instcode_in, l_hash_pan, l_encr_pan,
						l_inil_authid, '01', p_rrn_in, p_trandate_in,
						p_trantime_in, l_respcode, l_errmsg);
	 
	   IF l_respcode <> '00' AND l_errmsg <> 'OK'
	   THEN
		RAISE exp_main_reject_record;
	   END IF;
	 EXCEPTION
	   WHEN exp_main_reject_record THEN
		RAISE;
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := 'ERROR WHILE LOGGING SYSTEM INITIATED CARD STATUS CHANGE ' ||
				    substr(SQLERRM, 1, 200);
		RAISE exp_main_reject_record;
	 END;
    
	 UPDATE cms_appl_pan
	 SET    cap_firsttime_topup = 'Y', cap_card_stat = 1,
		   cap_active_date = SYSDATE, cap_prfl_code = l_lmtprfl,
		   cap_prfl_levl = l_profile_level
	 WHERE  cap_inst_code = p_instcode_in AND cap_pan_code = l_hash_pan;
    
	 IF SQL%ROWCOUNT = 0
	 THEN
	   l_respcode := '09';
	   l_errmsg   := 'CARD ACTIVATION DATE / FIRST TIME TOPUP UPDATION NOT HAPPENED';
	   RAISE exp_main_reject_record;
	 END IF;
    
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '09';
	   l_errmsg   := 'ERROR IN CARD ACTIVATION DATE UPDATION' || '--' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    FOR j IN (SELECT cap_pan_code_encr, cap_pan_code
		    FROM   cms_appl_pan
		    WHERE  cap_inst_code = p_instcode_in AND
				 cap_pan_code <> l_hash_pan AND
				 cap_acct_no = l_spend_acct_no AND cap_card_stat <> 9)
    
    LOOP
	 BEGIN
	   IF j.cap_pan_code IS NOT NULL
	   THEN
	   
		BEGIN
		  sp_log_cardstat_chnge(p_instcode_in, j.cap_pan_code,
						    j.cap_pan_code_encr, l_inil_authid, '02',
						    p_rrn_in, p_trandate_in, p_trantime_in,
						    l_respcode, l_errmsg);
		
		  IF l_respcode <> '00' AND l_errmsg <> 'OK'
		  THEN
		    l_respcode := '21';
		    RAISE exp_main_reject_record;
		  END IF;
		EXCEPTION
		  WHEN exp_main_reject_record THEN
		    RAISE;
		  WHEN OTHERS THEN
		    l_respcode := '21';
		    l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
					   substr(SQLERRM, 1, 200);
		    RAISE exp_main_reject_record;
		END;
	   
		BEGIN
		  UPDATE cms_appl_pan
		  SET    cap_card_stat = '9'
		  WHERE  cap_pan_code = j.cap_pan_code AND
			    cap_inst_code = p_instcode_in;
		  IF SQL%ROWCOUNT = 0
		  THEN
		    l_respcode := '21';
		    l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS ' ||
					   substr(SQLERRM, 1, 200);
		    RAISE exp_main_reject_record;
		  END IF;
		END;
	   
	   END IF;
	 EXCEPTION
	   WHEN exp_main_reject_record THEN
		RAISE exp_main_reject_record;
	   WHEN no_data_found THEN
		NULL;
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := 'ERROR WHILE SELECTING STARTER CARD DETAILS ' ||
				    substr(SQLERRM, 1, 200);
		RAISE exp_main_reject_record;
	 END;
    END LOOP;
  
    BEGIN
	 UPDATE cms_caf_info_entry
	 SET    cci_kyc_flag = 'Y'
	 WHERE  cci_appl_code = l_appl_code AND cci_inst_code = p_instcode_in;
    
	 UPDATE cms_cust_mast
	 SET    ccm_kyc_flag = 'Y', ccm_kyc_source = '04',
		   CCM_GPR_OPTIN = P_GPR_OPTIN_IN
	 WHERE  ccm_cust_code = l_migr_cust_code AND ccm_inst_code = p_instcode_in;  --Modified for 4.0.3 changes
    EXCEPTION
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE UPDATING CMS_CAF_INFO_ENTRY' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    IF l_errmsg = 'OK'
    THEN
	 IF l_loccheck_flg = 'Y'
	 THEN
	   BEGIN
		SELECT cmm_merprodcat_id
		INTO   l_cmm_merprodcat_id
		FROM   cms_merinv_merpan
		WHERE  cmm_pan_code = l_hash_pan AND
			  cmm_inst_code = p_instcode_in AND
			  cmm_location_id = p_terminalid_in;
	   EXCEPTION
		WHEN no_data_found THEN
		  l_errmsg := 'ERROR WHILE FETCHING PRODCATID FROM MERPAN - NO DATA FOUND';
		
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
		WHEN OTHERS THEN
		  l_errmsg   := 'ERROR WHILE FETCHING PRODCATID FROM MERPAN ' ||
					 substr(SQLERRM, 1, 200);
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
	   END;
	 
	   BEGIN
		UPDATE cms_merinv_merpan
		SET    cmm_activation_flag = 'C'
		WHERE  cmm_pan_code = l_hash_pan AND
			  cmm_inst_code = p_instcode_in AND
			  cmm_location_id = p_terminalid_in;
	   
		IF SQL%ROWCOUNT = 0
		THEN
		  l_errmsg   := 'ERROR WHILE UPDATING CARD ACTIVATION FLAG IN MERPAN ';
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
		END IF;
	   EXCEPTION
		WHEN exp_main_reject_record THEN
		  RAISE exp_main_reject_record;
		WHEN OTHERS THEN
		  l_errmsg   := 'ERROR WHILE UPDATING CARD ACTIVATION FLAG IN MERPAN' ||
					 substr(SQLERRM, 1, 200);
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
	   END;
	 
	   BEGIN
		UPDATE cms_merinv_stock
		SET    cms_curr_stock = (cms_curr_stock - 1)
		WHERE  cms_inst_code = p_instcode_in AND
			  cms_merprodcat_id = l_cmm_merprodcat_id AND
			  cms_location_id = p_terminalid_in;
	   
		IF SQL%ROWCOUNT = 0
		THEN
		  l_errmsg := 'ERROR WHILE UPDATING CURRSTOCK IN MERINVSTOCK 1';
		
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
		END IF;
	   EXCEPTION
		WHEN exp_main_reject_record THEN
		  RAISE exp_main_reject_record;
		WHEN OTHERS THEN
		  l_errmsg   := 'ERROR WHILE UPDATING CURRSTOCK IN MERINVSTOCK' ||
					 substr(SQLERRM, 1, 200);
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
	   END;
	 
	 ELSIF l_actl_flag = 'Y'
	 THEN
	 
	   BEGIN
		SELECT cmm_mer_id, cmm_location_id, cmm_merprodcat_id
		INTO   l_cmm_mer_id, l_cmm_location_id, l_cmm_merprodcat_id
		FROM   cms_merinv_merpan
		WHERE  cmm_pan_code = l_hash_pan AND
			  cmm_inst_code = p_instcode_in;
	   EXCEPTION
		WHEN no_data_found THEN
		  l_errmsg   := 'ERROR WHILE FETCHING PAN FROM MERPAN  - NO DATA FOUND';
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
		WHEN OTHERS THEN
		  l_errmsg   := 'ERROR WHILE FETCHING PAN FROM MERPAN ' ||
					 substr(SQLERRM, 1, 200);
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
	   END;
	 
	   BEGIN
		UPDATE cms_merinv_merpan
		SET    cmm_activation_flag = 'C'
		WHERE  cmm_pan_code = l_hash_pan AND
			  cmm_inst_code = p_instcode_in;
		IF SQL%ROWCOUNT = 0
		THEN
		  l_errmsg   := 'ERROR WHILE UPDATING CARD ACTIVATION FLAG IN MERPAN ' ||
					 substr(SQLERRM, 1, 200);
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
		END IF;
	   EXCEPTION
		WHEN exp_main_reject_record THEN
		  RAISE exp_main_reject_record;
		WHEN OTHERS THEN
		  l_errmsg   := 'ERROR WHILE UPDATING CARD ACTIVATION FLAG IN MERPAN' ||
					 substr(SQLERRM, 1, 200);
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
	   END;
	 
	   BEGIN
		UPDATE cms_merinv_stock
		SET    cms_curr_stock = (cms_curr_stock - 1)
		WHERE  cms_inst_code = p_instcode_in AND
			  cms_merprodcat_id = l_cmm_merprodcat_id AND
			  cms_location_id = l_cmm_location_id;
	   
		IF SQL%ROWCOUNT = 0
		THEN
		  l_errmsg   := 'ERROR WHILE UPDATING CARD ACTIVATION FLAG IN MERPAN ' ||
					 substr(SQLERRM, 1, 200);
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
		END IF;
	   EXCEPTION
		WHEN OTHERS THEN
		  l_errmsg   := 'ERROR WHILE UPDATING FIRST TIME TOPUP FLAG' ||
					 substr(SQLERRM, 1, 200);
		  l_respcode := '21';
		  RAISE exp_main_reject_record;
	   END;
	 END IF;
    END IF;
  
    BEGIN
	 SELECT COUNT(*)
	 INTO   l_prod_code_count
	 FROM   cms_prod_mast
	 WHERE  cpm_program_id = p_prod_id_in AND cpm_prod_code = l_prod_code; --l_pro_id;    --l_prod_id commented to use l_prod_code from above query from cms_appl_pan , dfchost-311
    
	 IF l_prod_code_count = 0
	 THEN
	   l_respcode := '36';
	   l_errmsg   := 'PROFILE DETAILS SENT NOT CORRECT WITH PRODUCT CODE ' ||
				  p_prod_id_in || ' CATG ' || l_prod_code; --l_pro_id  --l_prod_id commented to use l_prod_code from above query from cms_appl_pan , dfchost-311
	   RAISE exp_main_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '36';
	   l_errmsg   := 'ERROR WHILE SELECTING COUNT FROM PROD_MAST ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
	 VALUES
	   (p_rrn_in, p_delivery_channel_in, p_txn_code_in, l_migr_cust_code, 1); --Modified for 4.0.3 changes
    EXCEPTION
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE INSERTING AUDIT DTLS ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
   --SN: Commented for 4.0.3 changes
   /* BEGIN
	 SELECT cam_add_one, cam_add_two, cam_city_name, cam_pin_code,
		   cam_phone_one, cam_mobl_one, cam_email, cam_state_code,
		   cam_cntry_code, cam_state_switch
	 INTO   l_addr_lineone, l_addr_linetwo, l_city_name, l_pin_code,
		   l_phone_no, l_mobl_no, l_email, l_state_code, l_ctnry_code,
		   l_state_switch
	 FROM   cms_addr_mast
	 WHERE  cam_cust_code = l_cust_code AND cam_inst_code = p_instcode_in AND
		   cam_addr_flag = 'P';
    
    EXCEPTION
	 WHEN no_data_found THEN
	   l_respcode := '21';
	   l_errmsg   := 'NO DATA FOUND IN ADDRMAST FOR' || '-' || l_cust_code;
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR IN PROFILE UPDATE ' || substr(SQLERRM, 1, 300);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 SELECT nvl(fn_dmaps_main(ccm_ssn_encr), ccm_ssn), ccm_birth_date,
		   ccm_first_name, ccm_mid_name, ccm_last_name, ccm_partner_id
	 INTO   l_ssn, l_birth_date, l_first_name, l_mid_name, l_last_name,
		   l_partner_id
	 FROM   cms_cust_mast
	 WHERE  ccm_cust_code = l_cust_code AND ccm_inst_code = p_instcode_in;
    EXCEPTION
	 WHEN no_data_found THEN
	   l_respcode := '21';
	   l_errmsg   := 'NO DATA FOUND IN CUSTMAST FOR' || '-' || l_cust_code;
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR IN PROFILE UPDATE ' || substr(SQLERRM, 1, 300);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 SELECT cam_add_one, cam_add_two, cam_city_name, cam_pin_code,
		   cam_phone_one, cam_mobl_one, cam_email, cam_state_code,
		   cam_cntry_code, cam_state_switch
	 INTO   l_migr_p_add_one, l_migr_p_add_two, l_migr_p_city_name,
		   l_migr_p_pin_code, l_migr_p_phone_one, l_migr_p_mobl_one,
		   l_migr_p_email, l_migr_p_state_code, l_migr_p_cntry_code,
		   l_migr_p_state_switch
	 FROM   cms_addr_mast
	 WHERE  cam_cust_code = l_migr_cust_code AND
		   cam_inst_code = p_instcode_in AND cam_addr_flag = 'P';
    EXCEPTION
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE SELECTING MIGRATION ADDRESS DETAILS ' ||
				  substr(SQLERRM, 1, 300);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
    
	 UPDATE cms_addr_mast
	 SET    cam_add_one = l_migr_p_add_one, cam_add_two = l_migr_p_add_two,
		   cam_city_name = l_migr_p_city_name,
		   cam_pin_code = l_migr_p_pin_code,
		   cam_phone_one = l_migr_p_phone_one,
		   cam_mobl_one = l_migr_p_mobl_one, cam_email = l_migr_p_email,
		   cam_state_code = l_migr_p_state_code,
		   cam_cntry_code = l_migr_p_cntry_code,
		   cam_state_switch = l_migr_p_state_switch
	 WHERE  cam_cust_code = l_cust_code AND cam_inst_code = p_instcode_in AND
		   cam_addr_flag = 'P';
    
	 IF SQL%ROWCOUNT = 0
	 THEN
	   RAISE l_update_excp;
	 END IF;
    EXCEPTION
	 WHEN l_update_excp THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR IN PROFILE UPDATE' || l_cust_code;
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR IN PROFILE UPDATE ' || substr(SQLERRM, 1, 300);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 SELECT COUNT(1)
	 INTO   l_mailing_addr_count
	 FROM   cms_addr_mast
	 WHERE  cam_cust_code = l_migr_cust_code AND
		   cam_inst_code = p_instcode_in AND cam_addr_flag = 'O';
    EXCEPTION
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE SELECTING MAILING ADDRESS COUNT ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    IF l_mailing_addr_count > 0
    THEN
	 BEGIN
	   SELECT cam_add_one, cam_add_two, cam_city_name, cam_pin_code,
			cam_phone_one, cam_mobl_one, cam_email, cam_state_code,
			cam_cntry_code, cam_state_switch
	   INTO   l_migr_m_add_one, l_migr_m_add_two, l_migr_m_city_name,
			l_migr_m_pin_code, l_migr_m_phone_one, l_migr_m_mobl_one,
			l_migr_m_email, l_migr_m_state_code, l_migr_m_cntry_code,
			l_migr_m_state_switch
	   FROM   cms_addr_mast
	   WHERE  cam_cust_code = l_migr_cust_code AND
			cam_inst_code = p_instcode_in AND cam_addr_flag = 'O';
	 EXCEPTION
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := 'ERROR WHILE SELECTING MIGRATION ADDRESS DETAILS ' ||
				    substr(SQLERRM, 1, 300);
		RAISE exp_main_reject_record;
	 END;
    
	 BEGIN
	   INSERT INTO cms_addr_mast
		(cam_inst_code, cam_cust_code, cam_addr_code, cam_add_one,
		 cam_add_two, cam_phone_one, cam_mobl_one, cam_email, cam_pin_code,
		 cam_cntry_code, cam_city_name, cam_addr_flag, cam_state_code,
		 cam_state_switch, cam_ins_user, cam_ins_date, cam_lupd_user,
		 cam_lupd_date)
	   VALUES
		(p_instcode_in, l_cust_code, seq_addr_code.NEXTVAL,
		 l_migr_m_add_one, l_migr_m_add_two, l_migr_m_phone_one,
		 l_migr_m_mobl_one, l_migr_m_email, l_migr_m_pin_code,
		 l_migr_m_cntry_code, l_migr_m_city_name, 'O', l_migr_m_state_code,
		 l_migr_m_state_switch, 1, SYSDATE, 1, SYSDATE);
	 EXCEPTION
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := 'ERROR WHILE INSERTING MIGRATION ADDRESS DETAILS ' ||
				    substr(SQLERRM, 1, 300);
		RAISE exp_main_reject_record;
	 END;
    END IF;
  
    --sn added on 05_feb_13 for multiple ssn check
    BEGIN
    
	 SELECT ccm_first_name, ccm_mid_name, ccm_last_name, ccm_birth_date,
		   ccm_gender_type, ccm_ssn, ccm_ssn_encr, ccm_mother_name,
		   ccm_user_name, ccm_password_hash, ccm_kyc_flag, ccm_kyc_source,
		   ccm_appl_id, ccm_ofac_fail_flag, ccm_id_type, ccm_id_issuer,
		   ccm_idissuence_date, ccm_idexpry_date, ccm_optinoptout_status,
		   ccm_addrverify_flag, ccm_addverify_date, ccm_avfset_channel,
		   ccm_avfset_txncode, ccm_auth_user, ccm_wrong_logincnt,
		   ccm_acctlock_flag, ccm_last_logindate, ccm_acctunlock_date,
		   ccm_acctunlock_user, ccm_gpr_optin, ccm_partner_id
	 INTO   l_migr_first_name, l_migr_mid_name, l_migr_last_name,
		   l_migr_birth_date, l_migr_gender_type, l_migr_ssn,
		   l_migr_ssn_encr, l_migr_mother_name, l_migr_user_name,
		   l_migr_password_hash, l_migr_kyc_flag, l_migr_kyc_source,
		   l_migr_appl_id, l_migr_ofac_fail_flag, l_migr_id_type,
		   l_migr_id_issuer, l_migr_idissuence_date, l_migr_idexpry_date,
		   l_migr_optinoptout_status, l_migr_addrverify_flag,
		   l_migr_addverify_date, l_migr_avfset_channel,
		   l_migr_avfset_txncode, l_migr_auth_user, l_migr_wrong_logincnt,
		   l_migr_acctlock_flag, l_migr_last_logindate,
		   l_migr_acctunlock_date, l_migr_acctunlock_user,
		   l_migr_gpr_optin, l_migr_partner_id
	 FROM   cms_cust_mast
	 WHERE  ccm_cust_code = l_migr_cust_code AND
		   ccm_inst_code = p_instcode_in;
    EXCEPTION
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE SELECTING CUSTOMER DETAILS  ' ||
				  substr(SQLERRM, 1, 300);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 UPDATE cms_cust_mast
	 SET    ccm_first_name = l_migr_first_name,
		   ccm_mid_name = l_migr_mid_name,
		   ccm_last_name = l_migr_last_name,
		   ccm_birth_date = l_migr_birth_date,
		   ccm_gender_type = l_migr_gender_type, ccm_ssn = l_migr_ssn,
		   ccm_ssn_encr = l_migr_ssn_encr,
		   ccm_mother_name = l_migr_mother_name,
		   ccm_user_name = l_migr_user_name,
		   ccm_password_hash = l_migr_password_hash,
		   ccm_kyc_flag = l_migr_kyc_flag,
		   ccm_kyc_source = l_migr_kyc_source,
		   ccm_appl_id = nvl((SELECT cim_to_srcapp
						  FROM   cms_interface_mast
						  WHERE  upper(cim_interface_name) =
							    upper(l_migr_appl_id) AND
							    cim_inst_code = p_instcode_in),
						  l_migr_appl_id),
		   ccm_ofac_fail_flag = l_migr_ofac_fail_flag,
		   ccm_id_type = l_migr_id_type, ccm_id_issuer = l_migr_id_issuer,
		   ccm_idissuence_date = l_migr_idissuence_date,
		   ccm_idexpry_date = l_migr_idexpry_date,
		   ccm_optinoptout_status = l_migr_optinoptout_status,
		   ccm_addrverify_flag = l_migr_addrverify_flag,
		   ccm_addverify_date = l_migr_addverify_date,
		   ccm_avfset_channel = l_migr_avfset_channel,
		   ccm_avfset_txncode = l_migr_avfset_txncode,
		   ccm_auth_user = l_migr_auth_user,
		   ccm_wrong_logincnt = l_migr_wrong_logincnt,
		   ccm_acctlock_flag = l_migr_acctlock_flag,
		   ccm_last_logindate = l_migr_last_logindate,
		   ccm_acctunlock_date = l_migr_acctunlock_date,
		   ccm_acctunlock_user = l_migr_acctunlock_user,
		   ccm_gpr_optin = l_migr_gpr_optin,
		   ccm_partner_id = l_migr_partner_id
	 WHERE  ccm_cust_code = l_cust_code AND ccm_inst_code = p_instcode_in;
    END;
  
    -- Migrating security questions
  
    INSERT INTO cms_security_questions
	 (csq_inst_code, csq_cust_id, csq_question, csq_answer_hash)
	 (SELECT p_instcode_in, l_cust_id, csq_question, csq_answer_hash
	  FROM   cms_security_questions
	  WHERE  csq_cust_id = l_migr_cust_id AND
		    csq_inst_code = p_instcode_in);*/
  --EN: Commented for 4.0.3 changes
    -- inserting into cms_cardprofile_hist
    BEGIN
	 INSERT INTO cms_cardprofile_hist
	   (CCP_PAN_CODE, CCP_INST_CODE, 
      --SN:Commented for 4.0.3 changes
      /*ccp_add_one, ccp_add_two,
	    ccp_city_name, ccp_pin_code, ccp_phone_one, ccp_mobl_one, ccp_email,
	    CCP_STATE_CODE, CCP_CNTRY_CODE, CCP_CUST_CODE, CCP_SSN,
	    CCP_BIRTH_DATE, CCP_FIRST_NAME, CCP_MID_NAME, CCP_LAST_NAME,*/
      --EN:Commented for 4.0.3 changes
	    ccp_pan_code_encr, ccp_ins_date, ccp_lupd_date, ccp_mbr_numb,
	    CCP_RRN, CCP_STAN, CCP_BUSINESS_DATE, CCP_BUSINESS_TIME,
	    ccp_terminal_id, ccp_acct_no, ccp_acct_id, --ccp_state_switch, --Modified for 4.0.3 changes
	    CCP_PARTNER_ID,
      CCP_CUST_CODE) --Added for 4.0.3 changes
	 VALUES
	   (L_HASH_PAN, P_INSTCODE_IN, 
      --SN:Commented for 4.0.3 changes
      /*l_addr_lineone, l_addr_linetwo,
	    l_city_name, l_pin_code, l_phone_no, l_mobl_no, l_email,
	    l_state_code, l_ctnry_code, l_cust_code,
	    fn_maskacct_ssn(p_instcode_in, l_ssn, 0), l_birth_date,
	    l_first_name, l_mid_name, l_last_name, */
      --EN:Commented for 4.0.3 changes
      l_encr_pan, SYSDATE, SYSDATE,p_mbr_numb_in, 
      P_RRN_IN, NULL, P_TRANDATE_IN, P_TRANTIME_IN,
	    p_terminalid_in, l_acct_number, l_acct_id, --l_state_switch,--Modified for 4.0.3 changes
	    L_PARTNER_ID,
      l_cust_code); --Added for 4.0.3 changes
    EXCEPTION
	 WHEN no_data_found THEN
	   l_respcode := '21';
	   l_errmsg   := 'NO DATA FOUND IN ADDRMAST/CUSTMAST FOR' || '-' ||
				  l_cust_code;
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR IN PROFILE UPDATE ' || substr(SQLERRM, 1, 300);
	   RAISE exp_main_reject_record;
    END;
  
    IF l_cap_prod_catg = 'P'
    THEN
	 BEGIN
	   IF l_lmtprfl IS NOT NULL AND l_prfl_flag = 'Y'
	   THEN
		pkg_limits_check.sp_limits_check(l_hash_pan, NULL, NULL, NULL,
								   p_txn_code_in, l_tran_type, NULL,
								   NULL, p_instcode_in, NULL,
								   l_lmtprfl, p_amount_in,
								   p_delivery_channel_in,
								   l_comb_hash, l_respcode,
								   l_respmsg);
	   END IF;
	 
	   IF l_respcode <> '00' AND l_respmsg <> 'OK'
	   THEN
		IF (nvl(substr(p_reason_code_in, 1, 1), 0) = 'F' OR
		   nvl(substr(p_reason_code_in, 1, 1), 0) = 'T' OR
		   nvl(substr(p_reason_code_in, 1, 1), 0) = 'A' OR
		   nvl(substr(p_reason_code_in, 1, 1), 0) = 'R' OR
		   nvl(substr(p_reason_code_in, 1, 1), 0) = 'S' OR
		   nvl(substr(p_reason_code_in, 1, 1), 0) = '0')
		THEN
		
		  IF l_respcode = '79'
		  THEN
		    l_respcode := '231';
		    l_errmsg   := 'DENOMINATION BELOW MINIMAL AMOUNT PERMITTED';
		    RAISE exp_main_reject_record;
		  END IF;
		
		  IF l_respcode = '80'
		  THEN
		    l_respcode := '230';
		    l_errmsg   := 'DENOMINATION EXCEED PERMITTED AMOUNT';
		    RAISE exp_main_reject_record;
		  END IF;
		
		ELSE
		  l_errmsg := 'ERROR FROM LIMIT CHECK PROCESS ' || l_respmsg;
		  RAISE exp_main_reject_record;
		END IF;
	   END IF;
	 EXCEPTION
	   WHEN exp_main_reject_record THEN
		RAISE;
	   WHEN OTHERS THEN
		l_respcode := '21';
		l_errmsg   := 'ERROR FROM LIMIT CHECK PROCESS ' ||
				    substr(SQLERRM, 1, 200);
		RAISE exp_main_reject_record;
	 END;
    END IF;
  
    BEGIN
	 SELECT csr_spprt_rsncode
	 INTO   l_resoncode
	 FROM   cms_spprt_reasons
	 WHERE  csr_inst_code = p_instcode_in AND csr_spprt_key = 'INILOAD';
    EXCEPTION
	 WHEN no_data_found THEN
	   l_respcode := '21';
	   l_errmsg   := 'INITIAL LOAD REASON CODE IS PRESENT IN MASTER';
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode := '21';
	   l_errmsg   := 'ERROR WHILE SELECTING REASON CODE FROM MASTER' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    --sn create a record in pan spprt
    BEGIN
	 INSERT INTO cms_pan_spprt
	   (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
	    cps_spprt_key, cps_spprt_rsncode, cps_func_remark, cps_ins_user,
	    cps_lupd_user, cps_cmd_mode, cps_pan_code_encr)
	 VALUES
	   (p_instcode_in, l_hash_pan, l_mbrnumb, l_cap_prod_catg, 'INLOAD',
	    l_resoncode, l_remrk, p_lupduser_in, p_lupduser_in, 0, l_encr_pan);
    EXCEPTION
	 WHEN OTHERS THEN
	   l_errmsg := 'ERROR WHILE INSERTING RECORDS INTO CARD SUPPORT MASTER' ||
				substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    --en create a record in pan spprt
  
    --sn select response code and insert record into txn log dtl
    IF l_respcode <> '00'
    THEN
	 BEGIN
	   p_errmsg_out    := l_errmsg;
	   p_resp_code_out := l_respcode;
	 
	   -- assign the response code to the out parameter
	   SELECT cms_iso_respcde
	   INTO   p_resp_code_out
	   FROM   cms_response_mast
	   WHERE  cms_inst_code = p_instcode_in AND
			cms_delivery_channel = p_delivery_channel_in AND
			cms_response_id = l_respcode;
	 EXCEPTION
	   WHEN no_data_found THEN
		p_errmsg_out    := 'NO DATA AVAILABLE IN RESPONSE MASTER  FOR' ||
					    l_respcode;
		p_resp_code_out := '89';
		RAISE exp_main_reject_record;
	   WHEN OTHERS THEN
		p_errmsg_out    := 'PROBLEM WHILE SELECTING DATA FROM RESPONSE MASTER ' ||
					    l_respcode || substr(SQLERRM, 1, 300);
		p_resp_code_out := '89';
		RAISE exp_main_reject_record;
	 END;
    ELSE
	 p_resp_code_out := l_respcode;
    END IF;
  
    --en select response code and insert record into txn log dtl
  
    ---en updation of usage limit and amount
  
    IF p_errmsg_out = 'OK'
    THEN
	 BEGIN
	   SELECT cam_acct_bal, cam_ledger_bal
	   INTO   l_acct_balance, l_ledger_balance
	   FROM   cms_acct_mast
	   WHERE  cam_acct_no = p_dda_number_out AND
			cam_inst_code = p_instcode_in;
	 EXCEPTION
	   WHEN no_data_found THEN
		p_resp_code_out := '14';
		l_errmsg        := 'INVALID CARD ';
		RAISE exp_main_reject_record;
	   WHEN OTHERS THEN
		l_respcode := '12';
		l_errmsg   := 'ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ' ||
				    SQLERRM;
		RAISE exp_main_reject_record;
	 END;
    
	 --en of getting  the acct balannce
	 p_errmsg_out := to_char(l_acct_balance);
    END IF;
  
    BEGIN
	 IF l_lmtprfl IS NOT NULL AND l_prfl_flag = 'Y'
	 THEN
	   pkg_limits_check.sp_limitcnt_reset(p_instcode_in, l_hash_pan,
								   p_amount_in, l_comb_hash,
								   l_respcode, l_respmsg);
	 END IF;
    
	 IF l_respcode <> '00' AND l_respmsg <> 'OK'
	 THEN
	   l_errmsg := 'FROM PROCEDURE SP_LIMITCNT_RESET' || l_respmsg;
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
  
    BEGIN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
	 UPDATE transactionlog
	 SET    store_id = p_storeid_in, trans_desc = l_trans_desc,
		   customer_starter_card_no = l_encr_pan,
		   gprcardapplicationno = l_appl_code,
		   orgnl_card_no = l_migr_hash_pan,
		   customer_acct_no = l_spend_acct_no, tran_reverse_flag = 'N'
	 WHERE  instcode = p_instcode_in AND rrn = p_rrn_in AND
		   customer_card_no = l_hash_pan AND
		   business_date = p_trandate_in AND txn_code = p_txn_code_in AND
		   delivery_channel = p_delivery_channel_in;
ELSE
		 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
	 SET    store_id = p_storeid_in, trans_desc = l_trans_desc,
		   customer_starter_card_no = l_encr_pan,
		   gprcardapplicationno = l_appl_code,
		   orgnl_card_no = l_migr_hash_pan,
		   customer_acct_no = l_spend_acct_no, tran_reverse_flag = 'N'
	 WHERE  instcode = p_instcode_in AND rrn = p_rrn_in AND
		   customer_card_no = l_hash_pan AND
		   business_date = p_trandate_in AND txn_code = p_txn_code_in AND
		   delivery_channel = p_delivery_channel_in;
END IF;		   
    
	 IF SQL%ROWCOUNT = 0
	 THEN
	   p_errmsg_out := 'ERROR WHILE UPDATING STOREID IN TRANSACTIONLOG TABLE' ||
				    substr(SQLERRM, 1, 200);
	   l_respcode   := '21';
	   RAISE exp_main_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   p_errmsg_out := 'ERROR WHILE UPDATING STOREID IN TRANSACTIONLOG TABLE' ||
				    substr(SQLERRM, 1, 200);
	   l_respcode   := '21';
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


IF (v_Retdate>v_Retperiod)
    THEN
	 UPDATE cms_transaction_log_dtl
	 SET    ctd_location_id = p_terminalid_in,
		   ctd_taxprepare_id = p_taxprepareid_in,
		   ctd_alert_optin = p_optin_in,
		   ctd_reason_code = p_reason_code_in,
		   ctd_gpr_optin = p_gpr_optin_in --added for jh 3011
	 WHERE  ctd_rrn = p_rrn_in AND ctd_business_date = p_trandate_in AND
		   ctd_business_time = p_trantime_in AND
		   ctd_delivery_channel = p_delivery_channel_in AND
		   ctd_txn_code = p_txn_code_in AND ctd_msg_type = p_msg_type_in AND
		   ctd_inst_code = p_instcode_in AND
		   ctd_customer_card_no = l_hash_pan;
ELSE
		UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991
	 SET    ctd_location_id = p_terminalid_in,
		   ctd_taxprepare_id = p_taxprepareid_in,
		   ctd_alert_optin = p_optin_in,
		   ctd_reason_code = p_reason_code_in,
		   ctd_gpr_optin = p_gpr_optin_in --added for jh 3011
	 WHERE  ctd_rrn = p_rrn_in AND ctd_business_date = p_trandate_in AND
		   ctd_business_time = p_trantime_in AND
		   ctd_delivery_channel = p_delivery_channel_in AND
		   ctd_txn_code = p_txn_code_in AND ctd_msg_type = p_msg_type_in AND
		   ctd_inst_code = p_instcode_in AND
		   ctd_customer_card_no = l_hash_pan;
END IF;		   
    
	 IF SQL%ROWCOUNT = 0
	 THEN
	   p_errmsg_out := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
	   l_respcode   := '21';
	   RAISE exp_main_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_main_reject_record THEN
	   RAISE exp_main_reject_record;
	 WHEN OTHERS THEN
	   l_respcode   := '21';
	   p_errmsg_out := 'PROBLEM ON UPDATED CMS_TRANSACTION_LOG_DTL ' ||
				    substr(SQLERRM, 1, 200);
	   RAISE exp_main_reject_record;
    END;
  
    BEGIN
	 current_txnlogclear(p_instcode_in, l_hash_pan, l_migr_hash_pan);
    EXCEPTION
	 WHEN OTHERS THEN
	   NULL;
    END;
  
  EXCEPTION
    --<< main exception >>
    WHEN exp_auth_reject_record THEN
	 ROLLBACK;
	 p_errmsg_out    := l_errmsg;
	 p_resp_code_out := l_respcode;
    
	 BEGIN
	   current_txnlogclear(p_instcode_in, l_hash_pan, l_migr_hash_pan);
	 EXCEPTION
	   WHEN OTHERS THEN
		NULL;
	 END;
    
	 BEGIN
	   SELECT cam_acct_bal, cam_ledger_bal
	   INTO   l_acct_balance, l_ledger_balance
	   FROM   cms_acct_mast
	   WHERE  cam_acct_no = l_acct_number AND
			cam_inst_code = p_instcode_in;
	 EXCEPTION
	   WHEN OTHERS THEN
		l_acct_balance   := 0;
		l_ledger_balance := 0;
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
		 trans_desc, merchant_name, merchant_city, merchant_state,
		 store_id, time_stamp, orgnl_card_no, tran_reverse_flag)
	   VALUES
		(p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
		 l_business_date, p_txn_code_in, l_txn_type, p_txn_mode_in,
		 decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
		 p_trandate_in, substr(p_trantime_in, 1, 10), l_hash_pan, NULL,
		 NULL, NULL, p_instcode_in,
		 TRIM(to_char(l_tran_amt, '99999999999999999.99')), l_currcode,
		 NULL, l_prod_code, l_card_type, p_terminalid_in, l_inil_authid,
		 TRIM(to_char(l_tran_amt, '99999999999999999.99')), NULL, NULL,
		 p_instcode_in, l_encr_pan, l_encr_pan, l_proxunumber,
		 p_rvsl_code_in, l_spend_acct_no, l_acct_balance, l_ledger_balance,
		 l_respcode, l_cap_card_stat, p_errmsg_out, l_trans_desc,
		 p_merchant_name_in, p_merchant_city_in, NULL, p_storeid_in,
		 l_time_stamp, l_migr_hash_pan, 'N');
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
		 ctd_cust_acct_number, ctd_alert_optin, ctd_taxprepare_id,
		 ctd_location_id, ctd_reason_code, ctd_hashkey_id, ctd_gpr_optin)
	   VALUES
		(p_delivery_channel_in, p_txn_code_in, p_msg_type_in,
		 p_txn_mode_in, p_trandate_in, p_trantime_in, l_hash_pan,
		 p_amount_in, l_currcode, p_amount_in, NULL, NULL, NULL, NULL,
		 NULL, NULL, 'E', l_errmsg, p_rrn_in, p_instcode_in, l_encr_pan,
		 l_spend_acct_no, p_optin_in, p_taxprepareid_in, p_terminalid_in,
		 p_reason_code_in, l_hashkey_id, p_gpr_optin_in);
	 
	   p_errmsg_out := l_errmsg;
	 
	   RETURN;
	 EXCEPTION
	   WHEN OTHERS THEN
		l_errmsg        := 'PROBLEM WHILE INSERTING DATA INTO TRANSACTION LOG  DTL' ||
					    substr(SQLERRM, 1, 300);
		p_resp_code_out := '22'; -- server declined
		ROLLBACK;
		RETURN;
	 END;
    
	 p_errmsg_out := l_authmsg;
    WHEN exp_main_reject_record THEN
	 ROLLBACK;
	 BEGIN
	   current_txnlogclear(p_instcode_in, l_hash_pan, l_migr_hash_pan);
	 EXCEPTION
	   WHEN OTHERS THEN
		NULL;
	 END;
    
	 --sn select response code and insert record into txn log dtl
	 BEGIN
	   p_errmsg_out    := l_errmsg;
	   p_resp_code_out := l_respcode;
	 
	   -- assign the response code to the out parameter
	   SELECT cms_iso_respcde
	   INTO   p_resp_code_out
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
		 trans_desc, merchant_name, merchant_city, merchant_state,
		 ssn_fail_dtls, store_id, time_stamp, orgnl_card_no,
		 tran_reverse_flag)
	   VALUES
		(p_msg_type_in, p_rrn_in, p_delivery_channel_in, p_terminalid_in,
		 l_business_date, p_txn_code_in, l_txn_type, p_txn_mode_in,
		 decode(p_resp_code_out, '00', 'C', 'F'), p_resp_code_out,
		 p_trandate_in, substr(p_trantime_in, 1, 10), l_hash_pan, NULL,
		 NULL, NULL, p_instcode_in,
		 TRIM(to_char(l_tran_amt, '99999999999999999.99')), l_currcode,
		 NULL, l_prod_code, l_card_type, p_terminalid_in, l_inil_authid,
		 TRIM(to_char(l_tran_amt, '99999999999999999.99')), NULL, NULL,
		 p_instcode_in, l_encr_pan, l_encr_pan, l_proxunumber,
		 p_rvsl_code_in, l_spend_acct_no, l_acct_balance, l_ledger_balance,
		 l_respcode, l_cap_card_stat, p_errmsg_out, l_trans_desc,
		 p_merchant_name_in, p_merchant_city_in, NULL, l_ssn_crddtls,
		 p_storeid_in, l_time_stamp, l_migr_hash_pan, 'N');
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
		 ctd_cust_acct_number, ctd_alert_optin, ctd_taxprepare_id,
		 ctd_location_id, ctd_reason_code, ctd_hashkey_id, ctd_gpr_optin)
	   VALUES
		(p_delivery_channel_in, p_txn_code_in, p_msg_type_in,
		 p_txn_mode_in, p_trandate_in, p_trantime_in, l_hash_pan,
		 p_amount_in, l_currcode, p_amount_in, NULL, NULL, NULL, NULL,
		 NULL, NULL, 'E', l_errmsg, p_rrn_in, p_instcode_in, l_encr_pan,
		 l_spend_acct_no, p_optin_in, p_taxprepareid_in, p_terminalid_in,
		 p_reason_code_in, l_hashkey_id, p_gpr_optin_in);
	 
	   p_errmsg_out := l_errmsg;
	 
	   RETURN;
	 EXCEPTION
	   WHEN OTHERS THEN
		l_errmsg        := 'PROBLEM WHILE INSERTING DATA INTO TRANSACTION LOG  DTL' ||
					    substr(SQLERRM, 1, 300);
		p_resp_code_out := '22'; -- server declined
		ROLLBACK;
		RETURN;
	 END;
    
	 p_errmsg_out := l_errmsg;
    WHEN OTHERS THEN
	 p_errmsg_out := ' ERROR FROM MAIN ' || substr(SQLERRM, 1, 200);
    
  END activate_intial_load_migr;

  PROCEDURE reverse_activate_initial_load(p_inst_code_in     IN NUMBER,
								  p_msg_typ_in       IN VARCHAR2,
								  p_rvsl_code_in     IN VARCHAR2,
								  p_rrn_in           IN VARCHAR2,
								  p_delv_chnl_in     IN VARCHAR2,
								  p_terminal_id_in   IN VARCHAR2,
								  p_txn_code_in      IN VARCHAR2,
								  p_txn_type_in      IN VARCHAR2,
								  p_txn_mode_in      IN VARCHAR2,
								  p_business_date_in IN VARCHAR2,
								  p_business_time_in IN VARCHAR2,
								  p_card_no_in       IN VARCHAR2,
								  p_mbr_numb_in      IN VARCHAR2,
								  p_curr_code_in     IN VARCHAR2,
								  p_merchant_name    IN VARCHAR2,
								  p_merchant_city    IN VARCHAR2,
								  p_resp_cde_out     OUT VARCHAR2,
								  p_resp_msg_out     OUT VARCHAR2,
								  p_dda_number_out   OUT VARCHAR2) IS
  
    l_orgnl_delivery_channel   transactionlog.delivery_channel%TYPE;
    l_orgnl_resp_code          transactionlog.response_code%TYPE;
    l_orgnl_terminal_id        transactionlog.terminal_id%TYPE;
    l_orgnl_txn_code           transactionlog.txn_code%TYPE;
    l_orgnl_txn_type           transactionlog.txn_type%TYPE;
    l_orgnl_txn_mode           transactionlog.txn_mode%TYPE;
    l_orgnl_business_date      transactionlog.business_date%TYPE;
    l_orgnl_business_time      transactionlog.business_time%TYPE;
    l_orgnl_customer_card_no   transactionlog.customer_card_no%TYPE;
    l_orgnl_total_amount       transactionlog.amount%TYPE;
    l_reversal_amt             NUMBER(9, 2);
    l_orgnl_txn_feecode        cms_fee_mast.cfm_fee_code%TYPE;
    l_orgnl_txn_feeattachtype  transactionlog.feeattachtype%TYPE;
    l_orgnl_txn_servicetax_amt transactionlog.servicetax_amt%TYPE;
    l_orgnl_txn_cess_amt       transactionlog.cess_amt%TYPE;
    l_orgnl_transaction_type   transactionlog.cr_dr_flag%TYPE;
    l_actual_dispatched_amt    transactionlog.amount%TYPE;
    l_resp_cde                 VARCHAR2(3);
    l_func_code                cms_func_mast.cfm_func_code%TYPE;
    l_dr_cr_flag               transactionlog.cr_dr_flag%TYPE;
    l_rvsl_trandate            DATE;
    l_orgnl_termid             transactionlog.terminal_id%TYPE;
    l_orgnl_mcccode            transactionlog.mccode%TYPE;
    l_errmsg                   VARCHAR2(300);
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
    l_prod_code                cms_appl_pan.cap_prod_code%TYPE;
    l_card_type                cms_appl_pan.cap_card_type%TYPE;
    l_gpr_pan                  cms_appl_pan.cap_pan_code%TYPE;
    l_gpr_pan_encr             cms_appl_pan.cap_pan_code_encr%TYPE;
    l_gl_upd_flag              transactionlog.gl_upd_flag%TYPE;
    l_tran_reverse_flag        transactionlog.tran_reverse_flag%TYPE;
    l_savepoint                NUMBER DEFAULT 1;
    l_curr_code                transactionlog.currencycode%TYPE;
    l_auth_id                  transactionlog.auth_id%TYPE;
    l_cutoff_time              VARCHAR2(5);
    l_business_time            VARCHAR2(5);
    exp_rvsl_reject_record EXCEPTION;
    l_card_acct_no            VARCHAR2(20);
    l_hash_pan                cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan                cms_appl_pan.cap_pan_code_encr%TYPE;
    l_tran_amt                NUMBER;
    l_delchannel_code         VARCHAR2(2);
    l_card_curr               VARCHAR2(5);
    l_base_curr               cms_inst_param.cip_param_value%TYPE;
    l_currcode                VARCHAR2(3);
    l_acct_balance            NUMBER;
    l_ledger_balance          NUMBER;
    l_tran_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
    l_cust_code               cms_cust_mast.ccm_cust_code%TYPE;   
    l_migr_acct_no            cms_appl_pan.cap_acct_no%TYPE;
    l_migr_acct_id            cms_appl_pan.cap_acct_id%type;
    l_migr_cust_no            cms_appl_pan.cap_cust_code%type;    
    l_orgnl_txn_business_date transactionlog.business_date%TYPE;
    l_orgnl_txn_business_time transactionlog.business_time%TYPE;
    l_orgnl_txn_rrn           transactionlog.rrn%TYPE;
    l_orgnl_txn_terminalid    transactionlog.terminal_id%TYPE;
    l_proxunumber             cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_number             cms_appl_pan.cap_acct_no%TYPE;
    l_resoncode               cms_spprt_reasons.csr_spprt_rsncode%TYPE;
    p_remrk                   VARCHAR2(100);
    l_cap_prod_catg           cms_appl_pan.cap_prod_catg%TYPE;
    l_txn_narration           cms_statements_log.csl_trans_narrration%TYPE;
    l_fee_narration           cms_statements_log.csl_trans_narrration%TYPE;
    l_applpan_cardstat        transactionlog.cardstatus%TYPE;
    l_txn_merchname           cms_statements_log.csl_merchant_name%TYPE;
    l_fee_merchname           cms_statements_log.csl_merchant_name%TYPE;
    l_txn_merchcity           cms_statements_log.csl_merchant_city%TYPE;
    l_fee_merchcity           cms_statements_log.csl_merchant_city%TYPE;
    l_txn_merchstate          cms_statements_log.csl_merchant_state%TYPE;
    l_fee_merchstate          cms_statements_log.csl_merchant_state%TYPE;
    l_fee_plan_id             cms_card_excpfee_hist.cce_fee_plan%TYPE;
    l_cap_appl_code           cms_appl_pan.cap_appl_code%TYPE;
    l_merl_count              NUMBER;
    l_cap_acct_id             cms_appl_pan.cap_acct_id%TYPE;
    l_gpr_chk                 VARCHAR2(1);
    l_cam_type_code           cms_acct_mast.cam_type_code%TYPE;
    l_timestamp               TIMESTAMP;
    l_txn_type                NUMBER(1);
    l_tran_date               DATE;
    l_fee_plan                cms_fee_plan.cfp_plan_id%TYPE;
    l_fee_amt                 NUMBER;
    l_fee_code                cms_fee_mast.cfm_fee_code%TYPE;
    l_feeattach_type          VARCHAR2(2);
    l_cmm_merprodcat_id       cms_merinv_merpan.cmm_merprodcat_id%TYPE;
    l_loccheck_flg            cms_prod_cattype.cpc_loccheck_flag%TYPE;
    l_cmm_mer_id              cms_merinv_merpan.cmm_mer_id%TYPE;
    l_cmm_location_id         cms_merinv_merpan.cmm_location_id%TYPE;
    l_hashkey_id              cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
    l_invchk_flag             cms_prod_cattype.cpc_invcheck_flag%TYPE;
    l_cardactive_dt           cms_appl_pan.cap_active_date%TYPE;
    L_TXN_CODE                VARCHAR2(3);
    L_BILL_ADDR cms_appl_pan.cap_BILL_ADDR%TYPE; --FSS-4898 CSDesktop account statement is not working for migrated momentum MasterCard Cards
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
  BEGIN
    p_resp_cde_out := '00';
    p_resp_msg_out := 'OK';
    p_remrk        := 'CARD ACTIVATION REVERSAL';
    l_tran_amt     := 0;
    SAVEPOINT l_savepoint;
    l_errmsg := 'OK';
  
    l_timestamp := systimestamp;
  
    BEGIN
	 l_hashkey_id := gethash(p_delv_chnl_in || p_txn_code_in ||
						p_card_no_in || p_rrn_in ||
						to_char(l_timestamp, 'YYYYMMDDHH24MISSFF5'));
    EXCEPTION
	 WHEN OTHERS THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Error while converting master data ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    BEGIN
	 l_hash_pan := gethash(p_card_no_in);
    EXCEPTION
	 WHEN OTHERS THEN
	   l_errmsg := 'Error while converting hash pan ' ||
				substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    --EN CREATE HASH PAN
  
    --SN create encr pan
    BEGIN
	 l_encr_pan := fn_emaps_main(p_card_no_in);
    EXCEPTION
	 WHEN OTHERS THEN
	   l_errmsg := 'Error while converting encr pan ' ||
				substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    --EN create encr pan
  
    --Sn get date
    BEGIN
    
	 l_rvsl_trandate := to_date(substr(TRIM(p_business_date_in), 1, 8) || ' ' ||
						   substr(TRIM(p_business_time_in), 1, 8),
						   'yyyymmdd hh24:mi:ss');
    
	 l_tran_date := l_rvsl_trandate;
    EXCEPTION
	 WHEN OTHERS THEN
	   l_resp_cde := '21';
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
	   l_resp_cde := '21';
	   RAISE exp_rvsl_reject_record;
    END;
  
    BEGIN
	 sp_dup_rrn_check(l_hash_pan, p_rrn_in, p_business_date_in,
				   p_delv_chnl_in, p_msg_typ_in, p_txn_code_in, l_errmsg);
	 IF l_errmsg <> 'OK'
	 THEN
	   l_resp_cde := '22';
	   RAISE exp_rvsl_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_rvsl_reject_record THEN
	   RAISE;
	 WHEN OTHERS THEN
	   l_resp_cde := '22';
	   l_errmsg   := 'Error while checking RRN' || substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
    --En Duplicate RRN Check
  
    --Select the Delivery Channel code of MM-POS
    BEGIN
	 IF p_curr_code_in IS NULL AND l_delchannel_code = p_delv_chnl_in
	 THEN
	   BEGIN
		SELECT cip_param_value
		INTO   l_base_curr
		FROM   cms_inst_param
		WHERE  cip_inst_code = p_inst_code_in AND
			  cip_param_key = 'CURRENCY';
	   
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
		  l_errmsg := 'Error while selecting bese currecy  ' ||
				    substr(SQLERRM, 1, 200);
		  RAISE exp_rvsl_reject_record;
	   END;
	 
	   l_currcode := l_base_curr;
	 ELSE
	   l_currcode := p_curr_code_in;
	 END IF;
    END;
  
    BEGIN
	 SELECT cap_cust_code, cap_proxy_number, cap_acct_no, cap_acct_id,
		   cap_card_stat, cap_appl_code, cap_prod_code, cap_prod_catg,
		   cap_card_type, cap_active_date
	 INTO   l_cust_code, l_proxunumber, l_acct_number, l_cap_acct_id,
		   l_applpan_cardstat, l_cap_appl_code, l_prod_code,
		   l_cap_prod_catg, l_card_type, l_cardactive_dt
	 FROM   cms_appl_pan
	 WHERE  cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan AND
		   cap_mbr_numb = p_mbr_numb_in;
    
	 IF l_cardactive_dt IS NULL
	 THEN
	   l_resp_cde := '28';
	   l_errmsg   := 'Card Activation Reversal Cannot be done., Activation Not done for this card';
	   RAISE exp_rvsl_reject_record;
	 END IF;
    
    EXCEPTION
	 WHEN exp_rvsl_reject_record THEN
	   RAISE;
	 WHEN no_data_found THEN
	   l_errmsg   := 'Error while Fetching Prod Code  type - No Data found';
	   l_resp_cde := '21';
	   RAISE exp_rvsl_reject_record;
	 WHEN OTHERS THEN
	   l_errmsg   := 'Error while Fetching Prod Code  type ' ||
				  substr(SQLERRM, 1, 200);
	   l_resp_cde := '21';
	   RAISE exp_rvsl_reject_record;
    END;
    BEGIN
	 SELECT cpc_loccheck_flag, cpc_invcheck_flag
	 INTO   l_loccheck_flg, l_invchk_flag
	 FROM   cms_prod_cattype
	 WHERE  cpc_prod_code = l_prod_code AND cpc_card_type = l_card_type AND
		   cpc_inst_code = p_inst_code_in;
    EXCEPTION
	 WHEN no_data_found THEN
	   l_errmsg   := 'Error while Fetching Location Check From ProdCattype - No Data found';
	   l_resp_cde := '21';
	   RAISE exp_rvsl_reject_record;
	 WHEN OTHERS THEN
	   l_errmsg   := 'Error while Fetching Location Check From ProdCattype ' ||
				  substr(SQLERRM, 1, 200);
	   l_resp_cde := '21';
	   RAISE exp_rvsl_reject_record;
    END;
  
    --Sn check msg type
    IF l_delchannel_code <> p_delv_chnl_in
    THEN
	 IF (p_msg_typ_in NOT IN ('0400', '0410', '0420', '0430')) OR
	    (p_rvsl_code_in = '00')
	 THEN
	   l_resp_cde := '12';
	   l_errmsg   := 'Not a valid reversal request';
	   RAISE exp_rvsl_reject_record;
	 END IF;
    END IF;
  
    --En check msg type
  
    --   Sn Getting the details of Card Activation Txn.Original txn details are not present in request
  
    begin
	 select z.ccp_business_time,
          Z.CCP_BUSINESS_DATE, Z.CCP_RRN, Z.CCP_TERMINAL_ID,
          z.ccp_acct_no, z.ccp_acct_id,z.CCP_CUST_CODE
	 into   l_orgnl_txn_business_time, l_orgnl_txn_business_date,
		   L_ORGNL_TXN_RRN, L_ORGNL_TXN_TERMINALID,
          l_migr_acct_no, l_migr_acct_id, l_migr_cust_no
	 FROM   (SELECT CCP_BUSINESS_TIME,
				  ccp_business_date, ccp_rrn, ccp_terminal_id,ccp_acct_no,ccp_acct_id,CCP_CUST_CODE
			FROM   cms_cardprofile_hist
			WHERE  ccp_pan_code = l_hash_pan AND
				  ccp_inst_code = p_inst_code_in AND
				  ccp_mbr_numb = p_mbr_numb_in
			ORDER  BY ccp_ins_date DESC) z
	 WHERE  rownum = 1;
	 p_dda_number_out := l_migr_acct_no;
    EXCEPTION
	 WHEN no_data_found THEN
	   l_resp_cde := '23';
	   l_errmsg   := 'No Card Activation has done';
	   RAISE exp_rvsl_reject_record;
	 WHEN OTHERS THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Cannot get the activation details' || ' ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    --   Sn Getting the details of Card Activation Txn.
  
    --Sn check orginal transaction    (-- Amount is missing in reversal request)
    BEGIN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_txn_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
	 SELECT delivery_channel, terminal_id, response_code, txn_code,
		   txn_type, txn_mode, business_date, business_time,
		   customer_card_no, amount, feecode, feeattachtype,
		   servicetax_amt, cess_amt, cr_dr_flag, terminal_id, mccode,
		   feecode, tranfee_amt, servicetax_amt, cess_amt,
		   tranfee_cr_acctno, tranfee_dr_acctno, tran_st_calc_flag,
		   tran_cess_calc_flag, tran_st_cr_acctno, tran_st_dr_acctno,
		   tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
		   tran_reverse_flag, gl_upd_flag
	 INTO   l_orgnl_delivery_channel, l_orgnl_terminal_id,
		   l_orgnl_resp_code, l_orgnl_txn_code, l_orgnl_txn_type,
		   l_orgnl_txn_mode, l_orgnl_business_date, l_orgnl_business_time,
		   l_orgnl_customer_card_no, l_orgnl_total_amount,
		   l_orgnl_txn_feecode, l_orgnl_txn_feeattachtype,
		   l_orgnl_txn_servicetax_amt, l_orgnl_txn_cess_amt,
		   l_orgnl_transaction_type, l_orgnl_termid, l_orgnl_mcccode,
		   l_actual_feecode, l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,
		   l_orgnl_cess_amt, l_orgnl_tranfee_cr_acctno,
		   l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
		   l_orgnl_cess_calc_flag, l_orgnl_st_cr_acctno,
		   l_orgnl_st_dr_acctno, l_orgnl_cess_cr_acctno,
		   l_orgnl_cess_dr_acctno, l_curr_code, l_tran_reverse_flag,
		   l_gl_upd_flag
	 FROM   transactionlog
	 WHERE  rrn = l_orgnl_txn_rrn AND
		   business_date = l_orgnl_txn_business_date AND
		   business_time = l_orgnl_txn_business_time AND
		   customer_card_no = l_hash_pan AND instcode = p_inst_code_in AND
		   delivery_channel = p_delv_chnl_in;
ELSE
		SELECT delivery_channel, terminal_id, response_code, txn_code,
		   txn_type, txn_mode, business_date, business_time,
		   customer_card_no, amount, feecode, feeattachtype,
		   servicetax_amt, cess_amt, cr_dr_flag, terminal_id, mccode,
		   feecode, tranfee_amt, servicetax_amt, cess_amt,
		   tranfee_cr_acctno, tranfee_dr_acctno, tran_st_calc_flag,
		   tran_cess_calc_flag, tran_st_cr_acctno, tran_st_dr_acctno,
		   tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
		   tran_reverse_flag, gl_upd_flag
	 INTO   l_orgnl_delivery_channel, l_orgnl_terminal_id,
		   l_orgnl_resp_code, l_orgnl_txn_code, l_orgnl_txn_type,
		   l_orgnl_txn_mode, l_orgnl_business_date, l_orgnl_business_time,
		   l_orgnl_customer_card_no, l_orgnl_total_amount,
		   l_orgnl_txn_feecode, l_orgnl_txn_feeattachtype,
		   l_orgnl_txn_servicetax_amt, l_orgnl_txn_cess_amt,
		   l_orgnl_transaction_type, l_orgnl_termid, l_orgnl_mcccode,
		   l_actual_feecode, l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,
		   l_orgnl_cess_amt, l_orgnl_tranfee_cr_acctno,
		   l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
		   l_orgnl_cess_calc_flag, l_orgnl_st_cr_acctno,
		   l_orgnl_st_dr_acctno, l_orgnl_cess_cr_acctno,
		   l_orgnl_cess_dr_acctno, l_curr_code, l_tran_reverse_flag,
		   l_gl_upd_flag
	 FROM   VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
	 WHERE  rrn = l_orgnl_txn_rrn AND
		   business_date = l_orgnl_txn_business_date AND
		   business_time = l_orgnl_txn_business_time AND
		   customer_card_no = l_hash_pan AND instcode = p_inst_code_in AND
		   delivery_channel = p_delv_chnl_in;
    
END IF;		   
    
	 IF l_orgnl_resp_code <> '00'
	 THEN
	   l_resp_cde := '23';
	   l_errmsg   := ' The original transaction was not successful';
	   RAISE exp_rvsl_reject_record;
	 END IF;
    
	 IF l_tran_reverse_flag = 'Y'
	 THEN
	   l_resp_cde := '52';
	   l_errmsg   := 'The reversal already done for the orginal transaction';
	   RAISE exp_rvsl_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_rvsl_reject_record THEN
	   RAISE;
	 WHEN no_data_found THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Matching transaction not found';
	   RAISE exp_rvsl_reject_record;
	 WHEN too_many_rows THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'More than one matching record found in the master';
	   RAISE exp_rvsl_reject_record;
	 WHEN OTHERS THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Error while selecting master data' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    --En check orginal transaction
  
    ---Sn check card number
    IF l_orgnl_customer_card_no <> l_hash_pan
    THEN
	 l_resp_cde := '21';
	 l_errmsg   := 'Customer card number is not matching in reversal and orginal transaction';
	 RAISE exp_rvsl_reject_record;
    END IF;
  
    --Sn find the converted tran amt
    IF (l_tran_amt >= 0)
    THEN
	 BEGIN
	   sp_convert_curr(p_inst_code_in, l_currcode, p_card_no_in,
				    l_tran_amt, l_rvsl_trandate, l_tran_amt, l_card_curr,
				    l_errmsg,l_prod_code,l_card_type);
	 
	   IF l_errmsg <> 'OK'
	   THEN
		l_resp_cde := '21';
		RAISE exp_rvsl_reject_record;
	   END IF;
	 EXCEPTION
	   WHEN exp_rvsl_reject_record THEN
		RAISE;
	   WHEN OTHERS THEN
		l_resp_cde := '69'; -- Server Declined -220509
		l_errmsg   := 'Error from currency conversion ' ||
				    substr(SQLERRM, 1, 200);
		RAISE exp_rvsl_reject_record;
	 END;
    ELSE
	 -- If transaction Amount is zero - Invalid Amount -220509
	 l_resp_cde := '43';
	 l_errmsg   := 'INVALID AMOUNT';
	 RAISE exp_rvsl_reject_record;
    END IF;
  
    --En find the  converted tran amt
  
    --Sn check amount with orginal transaction
    IF (l_tran_amt IS NULL OR l_tran_amt = 0)
    THEN
	 l_actual_dispatched_amt := 0;
    ELSE
	 l_actual_dispatched_amt := l_tran_amt;
    END IF;
  
    --En check amount with orginal transaction
    l_reversal_amt := l_orgnl_total_amount - l_actual_dispatched_amt;
  
    --Sn find the type of orginal txn (credit or debit)
    BEGIN
	 SELECT ctm_credit_debit_flag, ctm_tran_desc,
		   to_number(decode(ctm_tran_type, 'N', '0', 'F', '1'))
	 INTO   l_dr_cr_flag, l_tran_desc, l_txn_type
	 FROM   cms_transaction_mast
	 WHERE  ctm_tran_code = p_txn_code_in AND
		   ctm_delivery_channel = p_delv_chnl_in AND
		   ctm_inst_code = p_inst_code_in;
    EXCEPTION
	 WHEN no_data_found THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Transaction detail is not found in master for orginal txn code' ||
				  p_txn_code_in || 'delivery channel ' ||
				  p_delv_chnl_in;
	   RAISE exp_rvsl_reject_record;
	 WHEN OTHERS THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Problem while selecting debit/credit flag ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    --En find the type of orginal txn (credit or debit)
    IF l_dr_cr_flag = 'NA'
    THEN
	 l_resp_cde := '21';
	 l_errmsg   := 'Not a valid orginal transaction for reversal';
	 RAISE exp_rvsl_reject_record;
    END IF;
  
    ---Sn find cutoff time
    BEGIN
	 SELECT cip_param_value
	 INTO   l_cutoff_time
	 FROM   cms_inst_param
	 WHERE  cip_param_key = 'CUTOFF' AND cip_inst_code = p_inst_code_in;
    EXCEPTION
	 WHEN no_data_found THEN
	   l_cutoff_time := 0;
	   l_resp_cde    := '21';
	   l_errmsg      := 'Cutoff time is not defined in the system';
	   RAISE exp_rvsl_reject_record;
	 WHEN OTHERS THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Error while selecting cutoff  dtl  from system ' || ' ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    ---En find cutoff time
    BEGIN
	 SELECT cam_acct_no, cam_type_code
	 INTO   l_card_acct_no, l_cam_type_code
	 FROM   cms_acct_mast
	 WHERE  cam_acct_no = l_migr_acct_no AND
		   cam_inst_code = p_inst_code_in;
    EXCEPTION
	 WHEN no_data_found THEN
	   l_resp_cde := '14';
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


IF (v_Retdate>v_Retperiod)
    THEN
	 SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
		   csl_merchant_state
	 INTO   l_txn_narration, l_txn_merchname, l_txn_merchcity,
		   l_txn_merchstate
	 FROM   cms_statements_log
	 WHERE  csl_business_date = l_orgnl_business_date AND
		   csl_business_time = l_orgnl_business_time AND
		   csl_rrn = l_orgnl_txn_rrn AND
		   csl_delivery_channel = l_orgnl_delivery_channel AND
		   csl_txn_code = l_orgnl_txn_code AND
		   csl_pan_no = l_orgnl_customer_card_no AND
		   csl_inst_code = p_inst_code_in AND txn_fee_flag = 'N';
ELSE
		SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
		   csl_merchant_state
	 INTO   l_txn_narration, l_txn_merchname, l_txn_merchcity,
		   l_txn_merchstate
	 FROM   VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
	 WHERE  csl_business_date = l_orgnl_business_date AND
		   csl_business_time = l_orgnl_business_time AND
		   csl_rrn = l_orgnl_txn_rrn AND
		   csl_delivery_channel = l_orgnl_delivery_channel AND
		   csl_txn_code = l_orgnl_txn_code AND
		   csl_pan_no = l_orgnl_customer_card_no AND
		   csl_inst_code = p_inst_code_in AND txn_fee_flag = 'N';
END IF;		   
    
	 IF l_orgnl_tranfee_amt > 0
	 THEN
	 
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
		SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
			  csl_merchant_state
		INTO   l_fee_narration, l_fee_merchname, l_fee_merchcity,
			  l_fee_merchstate
		FROM   cms_statements_log
		WHERE  csl_business_date = l_orgnl_business_date AND
			  csl_business_time = l_orgnl_business_time AND
			  csl_rrn = l_orgnl_txn_rrn AND
			  csl_delivery_channel = l_orgnl_delivery_channel AND
			  csl_txn_code = l_orgnl_txn_code AND
			  csl_pan_no = l_orgnl_customer_card_no AND
			  csl_inst_code = p_inst_code_in AND txn_fee_flag = 'Y';
ELSE
		SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
			  csl_merchant_state
		INTO   l_fee_narration, l_fee_merchname, l_fee_merchcity,
			  l_fee_merchstate
		FROM   VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
		WHERE  csl_business_date = l_orgnl_business_date AND
			  csl_business_time = l_orgnl_business_time AND
			  csl_rrn = l_orgnl_txn_rrn AND
			  csl_delivery_channel = l_orgnl_delivery_channel AND
			  csl_txn_code = l_orgnl_txn_code AND
			  csl_pan_no = l_orgnl_customer_card_no AND
			  csl_inst_code = p_inst_code_in AND txn_fee_flag = 'Y';
END IF;			  
	   
	   EXCEPTION
		WHEN no_data_found THEN
		  l_fee_narration := NULL;
		WHEN OTHERS THEN
		  l_fee_narration := NULL;
	   END;
	 END IF;
    EXCEPTION
	 WHEN no_data_found THEN
	   l_txn_narration := NULL;
	 WHEN OTHERS THEN
	   l_txn_narration := NULL;
    END;
  
    --En find narration
  
    --Sn reverse the amount
    BEGIN
	 sp_reverse_card_amount(p_inst_code_in, l_func_code, p_rrn_in,
					    p_delv_chnl_in, l_orgnl_txn_terminalid, NULL,
					    l_orgnl_txn_code, l_rvsl_trandate,
					    p_txn_mode_in, p_card_no_in, l_reversal_amt,
					    l_orgnl_txn_rrn, l_acct_number,
					    p_business_date_in, p_business_time_in,
					    l_auth_id, l_txn_narration,
					    l_orgnl_business_date, l_orgnl_business_time,
					    l_txn_merchname, l_txn_merchcity,
					    l_txn_merchstate, l_resp_cde, l_errmsg);
    
	 IF l_resp_cde <> '00' OR l_errmsg <> 'OK'
	 THEN
	   RAISE exp_rvsl_reject_record;
	 END IF;
    EXCEPTION
	 WHEN exp_rvsl_reject_record THEN
	   RAISE;
	 WHEN OTHERS THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Error while reversing the amount ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    --En reverse the amount
    --Sn reverse the fee
    BEGIN
    
	 sp_reverse_fee_amount(p_inst_code_in, p_rrn_in, p_delv_chnl_in,
					   l_orgnl_txn_terminalid, NULL, l_orgnl_txn_code,
					   l_rvsl_trandate, p_txn_mode_in,
					   l_orgnl_tranfee_amt, p_card_no_in,
					   l_actual_feecode, l_orgnl_tranfee_amt,
					   l_orgnl_tranfee_cr_acctno,
					   l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
					   l_orgnl_servicetax_amt, l_orgnl_st_cr_acctno,
					   l_orgnl_st_dr_acctno, l_orgnl_cess_calc_flag,
					   l_orgnl_cess_amt, l_orgnl_cess_cr_acctno,
					   l_orgnl_cess_dr_acctno, l_orgnl_txn_rrn,
					   l_acct_number, p_business_date_in,
					   p_business_time_in, l_auth_id, l_fee_narration,
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
	   l_resp_cde := '21';
	   l_errmsg   := 'Error while reversing the fee amount ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    --En reverse the fee    
  
    IF l_gl_upd_flag = 'Y'
    THEN
	 l_business_time := to_char(l_rvsl_trandate, 'HH24:MI');
	 IF l_business_time > l_cutoff_time
	 THEN
	   l_rvsl_trandate := trunc(l_rvsl_trandate) + 1;
	 ELSE
	   l_rvsl_trandate := trunc(l_rvsl_trandate);
	 END IF;
    
	 --En find businesses date
    
    END IF;
  
    l_resp_cde := '1';
    BEGIN
    
	 sp_tran_reversal_fees(p_inst_code_in, p_card_no_in, p_delv_chnl_in,
					   l_orgnl_txn_mode, p_txn_code_in, p_curr_code_in,
					   NULL, NULL, l_reversal_amt, p_business_date_in,
					   p_business_time_in, NULL, NULL, l_resp_cde,
					   p_msg_typ_in, p_mbr_numb_in, p_rrn_in,
					   p_terminal_id_in, l_txn_merchname,
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
	 IF l_errmsg = 'OK'
	 THEN
	   INSERT INTO cms_transaction_log_dtl
		(ctd_delivery_channel, ctd_txn_code, ctd_txn_type, ctd_msg_type,
		 ctd_txn_mode, ctd_business_date, ctd_business_time,
		 ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
		 ctd_actual_amount, ctd_bill_amount, ctd_bill_curr,
		 ctd_process_flag, ctd_process_msg, ctd_rrn, ctd_inst_code,
		 ctd_customer_card_no_encr, ctd_cust_acct_number, ctd_location_id,
		 ctd_hashkey_id)
	   VALUES
		(p_delv_chnl_in, p_txn_code_in, p_txn_type_in, p_msg_typ_in,
		 p_txn_mode_in, p_business_date_in, p_business_time_in, l_hash_pan,
		 l_tran_amt, l_currcode, l_tran_amt, l_reversal_amt, l_card_curr,
		 'Y', 'Successful', p_rrn_in, p_inst_code_in, l_encr_pan,
		 l_acct_number, p_terminal_id_in, l_hashkey_id);
	 END IF;
    EXCEPTION
	 WHEN OTHERS THEN
	   l_errmsg   := 'Problem while inserting data in to CMS_TRANSACTION_LOG_DTL ' ||
				  substr(SQLERRM, 1, 300);
	   l_resp_cde := '21';
	   RAISE exp_rvsl_reject_record;
    END;
  
       --FSS-4898 CSDesktop account statement is not working for migrated momentum MasterCard Cards begin
      BEGIN
        SELECT CAM_ADDR_CODE INTO L_BILL_ADDR FROM CMS_ADDR_MAST WHERE CAM_CUST_CODE=L_MIGR_CUST_NO AND CAM_ADDR_FLAG='P' AND CAM_INST_CODE=P_INST_CODE_IN;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        SELECT CAM_ADDR_CODE INTO L_BILL_ADDR FROM CMS_ADDR_MAST WHERE CAM_CUST_CODE=L_MIGR_CUST_NO AND CAM_ADDR_FLAG='O' AND CAM_INST_CODE=P_INST_CODE_IN;
      WHEN OTHERS THEN
        l_errmsg := 'Problem while updating billing address ' || SUBSTR(
        SQLERRM, 1, 100);
        l_resp_cde := '21';
        RAISE EXP_RVSL_REJECT_RECORD;
      END;
  --FSS-4898 CSDesktop account statement is not working for migrated momentum MasterCard Cards end
  
    BEGIN    
	 -- Revert changes in  cms_smsandemail_alert 
	 UPDATE cms_smsandemail_alert
	 SET    csa_loadorcredit_flag = 0, csa_lowbal_flag = 0,
		   csa_negbal_flag = 0, csa_highauthamt_flag = 0,
		   csa_dailybal_flag = 0, csa_insuff_flag = 0,
		   csa_incorrpin_flag = 0, csa_fast50_flag = 0,
		   csa_fedtax_refund_flag = 0, csa_cellphonecarrier = 0,
		   csa_c2c_flag = NULL, csa_lupd_date = SYSDATE,
		   csa_lowbal_amt = NULL, csa_highauthamt = NULL,
		   csa_alert_lang_id = NULL
	 WHERE  csa_inst_code = p_inst_code_in AND csa_pan_code = l_hash_pan;
    
	 UPDATE CMS_APPL_MAST
	 SET    cam_cust_code = l_migr_cust_no,cam_bill_addr=L_BILL_ADDR
	 WHERE  CAM_APPL_CODE = l_cap_appl_code AND CAM_INST_CODE = p_inst_code_in;
   
   UPDATE cms_appl_det
	 SET    cad_acct_id = l_migr_acct_id
	 WHERE  cad_appl_code = to_char(l_cap_appl_code) AND
		   cad_inst_code = p_inst_code_in;
    
    
   UPDATE CMS_PAN_ACCT
	 SET    cpa_acct_id = l_migr_acct_id, 
          cpa_cust_code=l_migr_cust_no
	 where cpa_inst_code = p_inst_code_in  and cpa_acct_id = l_cap_acct_id 
        AND cpa_mbr_numb=p_mbr_numb_in AND cpa_pan_code=l_hash_pan;
    
	 FOR j IN (SELECT customer_card_no, customer_card_no_encr, cardstatus
			 FROM   VMSCMS.TRANSACTIONLOG_VW		--Added for VMS-5733/FSP-991
			 WHERE  delivery_channel = '05' AND txn_code = '02' AND
				   instcode = p_inst_code_in AND
				   orgnl_rrn = l_orgnl_txn_rrn AND
				   business_date = l_orgnl_txn_business_date AND
				   customer_acct_no = l_acct_number)
	 LOOP
	   BEGIN
	   
		IF j.customer_card_no IS NOT NULL
		THEN
		
		  BEGIN
		  
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
		    ELSIF j.cardstatus = '9'
		    THEN
			 l_txn_code := '02';
			ELSIF j.cardstatus = '2' --added for Mantis_0016486
		    THEN
			 l_txn_code := '48';
		    END IF;
		  
		    sp_log_cardstat_chnge(p_inst_code_in, j.customer_card_no,
							 j.customer_card_no_encr, l_auth_id,
							 l_txn_code, p_rrn_in, p_business_date_in,
							 p_business_time_in, l_resp_cde, l_errmsg);
		  
		    IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
		    THEN
			 l_resp_cde := '21';
			 RAISE exp_rvsl_reject_record;
		    END IF;
		  EXCEPTION
		    WHEN exp_rvsl_reject_record THEN
			 RAISE;
		    WHEN OTHERS THEN
			 l_resp_cde := '21';
			 l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
						substr(SQLERRM, 1, 200);
			 RAISE exp_rvsl_reject_record;
		  END;
		
		  UPDATE cms_appl_pan
		  SET    cap_card_stat = j.cardstatus
		  WHERE  cap_pan_code = j.customer_card_no AND
			    cap_inst_code = p_inst_code_in;
		
		  IF SQL%ROWCOUNT = 0
		  THEN
		    l_resp_cde := '21';
		    l_errmsg   := 'ERROR WHILE UPDATING OLD CARD STATUS ' ||
					   substr(SQLERRM, 1, 200);
		    RAISE exp_rvsl_reject_record;
		  END IF;
		END IF;
	   
	   EXCEPTION
		WHEN exp_rvsl_reject_record THEN
		  RAISE;
		WHEN no_data_found THEN
		  NULL;
		WHEN OTHERS THEN
		  l_resp_cde := '21';
		  l_errmsg   := 'Error while selecting starter card details ' ||
					 substr(SQLERRM, 1, 200);
		  RAISE exp_rvsl_reject_record;
	   END;
	 END LOOP;
    
    EXCEPTION
	 WHEN exp_rvsl_reject_record THEN
	   RAISE;
	 WHEN OTHERS THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'ERROR WHILE UPDATING REVERSING DETAILS' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    BEGIN
    
	 SELECT cap_pan_code, cap_pan_code_encr
	 INTO   l_gpr_pan, l_gpr_pan_encr
	 from   cms_appl_pan
	 WHERE  cap_inst_code = p_inst_code_in AND cap_cust_code = l_cust_code AND cap_startercard_flag = 'N' and cap_prod_code=l_prod_code;
    
	 l_gpr_chk := 'Y';
    
    EXCEPTION
	 WHEN no_data_found THEN
	 
	   l_gpr_chk := 'N';
	 
	 WHEN OTHERS THEN
	 
	   l_errmsg   := 'Problem while fetching gpr card ' ||
				  substr(SQLERRM, 1, 100);
	   l_resp_cde := '21';
	   RAISE exp_rvsl_reject_record;
	 
    END;
      
    BEGIN
    
	 IF l_gpr_chk = 'N'
	 THEN
	 
	   BEGIN
		BEGIN
		  sp_log_cardstat_chnge(p_inst_code_in, l_hash_pan, l_encr_pan,
						    l_auth_id, '08', p_rrn_in,
						    p_business_date_in, p_business_time_in,
						    l_resp_cde, l_errmsg);
		
		  IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
		  THEN
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		  END IF;
		EXCEPTION
		  WHEN exp_rvsl_reject_record THEN
		    RAISE;
		  WHEN OTHERS THEN
		    l_resp_cde := '21';
		    l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
					   substr(SQLERRM, 1, 200);
		    RAISE exp_rvsl_reject_record;
		END;
    
		UPDATE cms_appl_pan
		set    cap_acct_no = l_migr_acct_no, cap_acct_id = l_migr_acct_id,
   cap_cust_code=l_migr_cust_no,
			  cap_card_stat = '0', cap_firsttime_topup = 'N',
			  CAP_ACTIVE_DATE = NULL, CAP_PRFL_CODE = NULL,
			  CAP_PRFL_LEVL = NULL,CAP_BILL_ADDR=L_BILL_ADDR --FSS-4898 CSDesktop account statement is not working for migrated momentum MasterCard Cards
		WHERE  cap_inst_code = p_inst_code_in AND
			  CAP_PAN_CODE = L_HASH_PAN;	   
		IF SQL%ROWCOUNT = 0
		THEN
		
		  l_errmsg   := 'Starer card not updated to inactive status';
		  l_resp_cde := '21';
		  RAISE exp_rvsl_reject_record;
		
		END IF;
	   
	   EXCEPTION
		WHEN exp_rvsl_reject_record THEN
		  RAISE;
		
		WHEN OTHERS THEN
		
		  l_errmsg   := 'Problem while updating starter card to inactive ' ||
					 substr(SQLERRM, 1, 100);
		  l_resp_cde := '21';
		  RAISE exp_rvsl_reject_record;
		
	   END;
	 
	 ELSIF l_gpr_chk = 'Y'
	 THEN
	 
	   BEGIN
	   
		BEGIN
		  sp_log_cardstat_chnge(p_inst_code_in, l_hash_pan, l_encr_pan,
						    l_auth_id, '02', p_rrn_in,
						    p_business_date_in, p_business_time_in,
						    l_resp_cde, l_errmsg);
		
		  IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
		  THEN
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		  END IF;
		EXCEPTION
		  WHEN exp_rvsl_reject_record THEN
		    RAISE;
		  WHEN OTHERS THEN
		    l_resp_cde := '21';
		    l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
					   substr(SQLERRM, 1, 200);
		    RAISE exp_rvsl_reject_record;
		END;
	   
		UPDATE cms_appl_pan
		set    cap_acct_no = l_migr_acct_no, cap_acct_id = l_migr_acct_id,
      cap_cust_code=l_migr_cust_no,
			  cap_card_stat = '9', cap_firsttime_topup = 'N',
			  CAP_ACTIVE_DATE = NULL, CAP_PRFL_CODE = NULL,
			  cap_prfl_levl = NULL,CAP_BILL_ADDR=L_BILL_ADDR --FSS-4898 CSDesktop account statement is not working for migrated momentum MasterCard Cards
		WHERE  cap_inst_code = p_inst_code_in AND
			  cap_pan_code = l_hash_pan;
	   
		IF SQL%ROWCOUNT = 0
		THEN
		
		  l_errmsg   := 'Starer card not updated to close status';
		  l_resp_cde := '21';
		  RAISE exp_rvsl_reject_record;
		
		END IF;
	   
	   EXCEPTION
		WHEN exp_rvsl_reject_record THEN
		  RAISE;
		
		WHEN OTHERS THEN
		
		  l_errmsg   := 'Problem while updating starter card ' ||
					 substr(SQLERRM, 1, 100);
		  l_resp_cde := '21';
		  RAISE exp_rvsl_reject_record;
		
	   END;
	 
	   BEGIN
	   
		BEGIN
		  sp_log_cardstat_chnge(p_inst_code_in, l_gpr_pan, l_gpr_pan_encr,
						    l_auth_id, '02', p_rrn_in,
						    p_business_date_in, p_business_time_in,
						    l_resp_cde, l_errmsg);
		
		  IF l_resp_cde <> '00' AND l_errmsg <> 'OK'
		  THEN
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		  END IF;
		EXCEPTION
		  WHEN exp_rvsl_reject_record THEN
		    RAISE;
		  WHEN OTHERS THEN
		    l_resp_cde := '21';
		    l_errmsg   := 'ERROR WHILE UPDATING CARD STATUS IN LOG TABLE-' ||
					   substr(SQLERRM, 1, 200);
		    RAISE exp_rvsl_reject_record;
		END;
	   
		UPDATE cms_appl_pan
		set    cap_acct_no = l_migr_acct_no, cap_acct_id = l_migr_acct_id,
      cap_cust_code=l_migr_cust_no,
			  cap_card_stat = 9
		WHERE  cap_inst_code = p_inst_code_in AND
			  cap_pan_code = l_gpr_pan;
	   
		IF SQL%ROWCOUNT = 0
		THEN
		
		  l_errmsg   := 'GPR card not updated to close status';
		  l_resp_cde := '21';
		  RAISE exp_rvsl_reject_record;
		
		END IF;
	   
	   EXCEPTION
		WHEN exp_rvsl_reject_record THEN
		  RAISE;
		
		WHEN OTHERS THEN
		
		  l_errmsg   := 'Problem while updating GPR card ' ||
					 substr(SQLERRM, 1, 100);
		  l_resp_cde := '21';
		  RAISE exp_rvsl_reject_record;
		
	   END;
	 
	 END IF;
    
	 IF l_errmsg = 'OK' AND l_gpr_chk = 'N'
	 THEN
	 
	   IF l_loccheck_flg = 'Y'
	   THEN
		BEGIN
		  SELECT cmm_merprodcat_id
		  INTO   l_cmm_merprodcat_id
		  FROM   cms_merinv_merpan
		  WHERE  cmm_pan_code = l_hash_pan AND
			    cmm_inst_code = p_inst_code_in AND
			    cmm_location_id = l_orgnl_txn_terminalid;
		EXCEPTION
		  WHEN no_data_found THEN
		    l_errmsg   := 'Error while Fetching ProdCat From MERPAN 1';
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		  WHEN OTHERS THEN
		    l_errmsg   := 'Error while Fetching Pan From MERPAN ' ||
					   substr(SQLERRM, 1, 200);
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		END;
	   
		BEGIN
		  UPDATE cms_merinv_merpan
		  SET    cmm_activation_flag = 'M'
		  WHERE  cmm_pan_code = l_hash_pan AND
			    cmm_inst_code = p_inst_code_in AND
			    cmm_location_id = l_orgnl_txn_terminalid;
		
		  IF SQL%ROWCOUNT = 0
		  THEN
		    l_errmsg   := 'Error while Updating Card Activation Flag in MERPAN 1';
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		  END IF;
		EXCEPTION
		  WHEN exp_rvsl_reject_record THEN
		    RAISE exp_rvsl_reject_record;
		  WHEN OTHERS THEN
		    l_errmsg   := 'Error while Updating Card Activation Flag in MERPAN ' ||
					   substr(SQLERRM, 1, 200);
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		END;
	   
		BEGIN
		  UPDATE cms_merinv_stock
		  SET    cms_curr_stock = (cms_curr_stock + 1)
		  WHERE  cms_inst_code = p_inst_code_in AND
			    cms_merprodcat_id = l_cmm_merprodcat_id AND
			    cms_location_id = l_orgnl_txn_terminalid;
		
		  IF SQL%ROWCOUNT = 0
		  THEN
		    l_errmsg   := 'Error while Updating current stock in MERSTOCK ';
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		  END IF;
		EXCEPTION
		  WHEN exp_rvsl_reject_record THEN
		    RAISE exp_rvsl_reject_record;
		  WHEN OTHERS THEN
		    l_errmsg   := 'Error while Updating current stock in MERSTOCK' ||
					   substr(SQLERRM, 1, 200);
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		END;
	   END IF;
	 
	   IF l_invchk_flag = 'Y'
	   THEN
		BEGIN
		  SELECT cmm_mer_id, cmm_location_id, cmm_merprodcat_id
		  INTO   l_cmm_mer_id, l_cmm_location_id, l_cmm_merprodcat_id
		  FROM   cms_merinv_merpan
		  WHERE  cmm_pan_code = l_hash_pan AND
			    cmm_inst_code = p_inst_code_in;
		EXCEPTION
		  WHEN no_data_found THEN
		    l_errmsg   := 'Error while Fetching Pan From MERPAN  - No Data found';
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		  WHEN OTHERS THEN
		    l_errmsg   := 'Error while Fetching Pan From MERPAN ' ||
					   substr(SQLERRM, 1, 200);
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		END;
	   
		BEGIN
		  UPDATE cms_merinv_merpan
		  SET    cmm_activation_flag = 'M'
		  WHERE  cmm_pan_code = l_hash_pan AND
			    cmm_inst_code = p_inst_code_in;
		
		  IF SQL%ROWCOUNT = 0
		  THEN
		    l_errmsg   := 'Error while Updating Card Activation Flag in MERPAN 1';
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		  END IF;
		EXCEPTION
		  WHEN exp_rvsl_reject_record THEN
		    RAISE;
		  WHEN OTHERS THEN
		    l_errmsg   := 'Error while Updating Card Activation Flag in MERPAN 2' ||
					   substr(SQLERRM, 1, 200);
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		END;
	   
		BEGIN
		  UPDATE cms_merinv_stock
		  SET    cms_curr_stock = (cms_curr_stock + 1)
		  WHERE  cms_inst_code = p_inst_code_in AND
			    cms_merprodcat_id = l_cmm_merprodcat_id AND
			    cms_location_id = l_cmm_location_id;
		
		  IF SQL%ROWCOUNT = 0
		  THEN
		    l_errmsg   := 'Error while Updating current stock in CMS_MERINV_STOCK 1 ';
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		  END IF;
		EXCEPTION
		  WHEN exp_rvsl_reject_record THEN
		    RAISE;
		  WHEN OTHERS THEN
		    l_errmsg   := 'Error while Updating current stock in CMS_MERINV_STOCK 2' ||
					   substr(SQLERRM, 1, 200);
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		END;
	   END IF;
	 END IF;
    
    EXCEPTION
	 WHEN exp_rvsl_reject_record THEN
	   RAISE;
	 WHEN OTHERS THEN
	   l_errmsg   := 'Customer details are not reversed' || l_resp_cde ||
				  substr(SQLERRM, 1, 300);
	   l_resp_cde := '21';
	   RAISE exp_rvsl_reject_record;
    END;
  
    BEGIN
    
	 SELECT COUNT(*)
	 INTO   l_merl_count
	 FROM   cms_merinv_merpan
	 WHERE  cmm_inst_code = p_inst_code_in AND
		   cmm_appl_code = l_cap_appl_code AND cmm_pan_code = l_hash_pan;
    
	 IF l_merl_count = 1
	 THEN
	 
	   BEGIN
	   
		UPDATE cms_caf_info_entry
		SET    cci_kyc_flag = 'N'
		WHERE  cci_appl_code = to_char(l_cap_appl_code) AND
			  cci_inst_code = p_inst_code_in;
	   
		UPDATE cms_cust_mast
		SET    ccm_kyc_flag = 'N'
		WHERE  ccm_cust_code = l_cust_code AND
			  ccm_inst_code = p_inst_code_in;
	   END;
	 
	 END IF;
    
    EXCEPTION
	 WHEN OTHERS THEN
	   l_resp_cde := '09';
	   l_errmsg   := 'ERROR WHILE UPDATING CMS_CAF_INFO_ENTRY' || '--' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
	 
    END;
  
    --Sn Selecting Reason code for Initial Load
    BEGIN
	 SELECT csr_spprt_rsncode
	 INTO   l_resoncode
	 FROM   cms_spprt_reasons
	 WHERE  csr_inst_code = p_inst_code_in AND csr_spprt_key = 'INILOAD';
    
    EXCEPTION
	 WHEN no_data_found THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Initial load reason code is present in master';
	   RAISE exp_rvsl_reject_record;
	 WHEN OTHERS THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Error while selecting reason code from master' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
  
    --Sn create a record in pan spprt
    BEGIN
	 INSERT INTO cms_pan_spprt
	   (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
	    cps_spprt_key, cps_spprt_rsncode, cps_func_remark, cps_ins_user,
	    cps_lupd_user, cps_cmd_mode, cps_pan_code_encr)
	 VALUES
	   (p_inst_code_in, l_hash_pan, p_mbr_numb_in, l_cap_prod_catg,
	    'INLOAD', l_resoncode, p_remrk, '1', '1', 0, l_encr_pan);
    EXCEPTION
	 WHEN OTHERS THEN
	   l_errmsg := 'Error while inserting records into card support master' ||
				substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
    --En create a record in pan spprt
  
    --Sn generate response code
    l_resp_cde := '1';
  
    BEGIN
	 SELECT cms_iso_respcde
	 INTO   p_resp_cde_out
	 FROM   cms_response_mast
	 WHERE  cms_inst_code = p_inst_code_in AND
		   cms_delivery_channel = p_delv_chnl_in AND
		   cms_response_id = to_number(l_resp_cde);
    EXCEPTION
	 WHEN OTHERS THEN
	   l_errmsg   := 'Problem while selecting data from response master for respose code' ||
				  l_resp_cde || substr(SQLERRM, 1, 300);
	   l_resp_cde := '69';
	   RAISE exp_rvsl_reject_record;
    END;
  
    BEGIN
    
	 SELECT cam_acct_bal, cam_ledger_bal
	 INTO   l_acct_balance, l_ledger_balance
	 FROM   cms_acct_mast
	 WHERE  cam_acct_no = l_migr_acct_no AND
		   cam_inst_code = p_inst_code_in;
    
    EXCEPTION
	 WHEN no_data_found THEN
	   l_resp_cde := '14';
	   l_errmsg   := 'Invalid Card ';
	   RAISE exp_rvsl_reject_record;
	 WHEN OTHERS THEN
	   l_resp_cde := '12';
	   l_errmsg   := 'Error while selecting data from card Master for card number ' ||
				  SQLERRM;
	   RAISE exp_rvsl_reject_record;
    END;
  
    -- Sn create a entry in GL
    BEGIN
	 INSERT INTO transactionlog
	   (msgtype, rrn, delivery_channel, terminal_id, date_time, txn_code,
	    txn_type, txn_mode, txn_status, response_code, business_date,
	    business_time, customer_card_no, topup_card_no, topup_acct_no,
	    topup_acct_type, bank_code, total_amount, rule_indicator,
	    rulegroupid, currencycode, productid, categoryid, tips,
	    decline_ruleid, atm_name_location, auth_id, trans_desc, amount,
	    preauthamount, partialamount, mccodegroupid, currencycodegroupid,
	    transcodegroupid, rules, preauth_date, gl_upd_flag, instcode,
	    feecode, feeattachtype, tran_reverse_flag, customer_card_no_encr,
	    topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
	    acct_balance, ledger_balance, response_id, cardstatus, acct_type,
	    time_stamp, cr_dr_flag, error_msg, store_id, fee_plan, tranfee_amt,
	    merchant_name, merchant_city)
	 VALUES
	   (p_msg_typ_in, p_rrn_in, p_delv_chnl_in, p_terminal_id_in,
	    l_rvsl_trandate, p_txn_code_in, p_txn_type_in, p_txn_mode_in,
	    decode(p_resp_cde_out, '00', 'C', 'F'), p_resp_cde_out,
	    p_business_date_in, substr(p_business_time_in, 1, 6), l_hash_pan,
	    NULL, NULL, NULL, p_inst_code_in,
	    TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')), NULL,
	    NULL, l_curr_code, l_prod_code, l_card_type, '0.00', NULL, NULL,
	    l_auth_id, l_tran_desc,
	    TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
	    '0.00', '0.00', NULL, NULL, NULL, NULL, NULL, 'Y', p_inst_code_in,
	    l_fee_code, l_feeattach_type, 'N', l_encr_pan, NULL, l_proxunumber,
	    p_rvsl_code_in, l_acct_number,
	    TRIM(to_char(nvl(l_acct_balance, 0), '99999999999999990.99')),
	    TRIM(to_char(nvl(l_ledger_balance, 0), '99999999999999990.99')),
	    l_resp_cde, l_applpan_cardstat, l_cam_type_code, l_timestamp,
	    decode(p_delv_chnl_in, '04', l_dr_cr_flag,
			  decode(l_dr_cr_flag, 'CR', 'DR', 'DR', 'CR', l_dr_cr_flag)),
	    l_errmsg, NULL, l_fee_plan, l_fee_amt, p_merchant_name,
	    p_merchant_city);
    
	 --Sn update reverse flag
	 BEGIN
	 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_txn_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
	   UPDATE transactionlog
	   SET    tran_reverse_flag = 'Y'
	   WHERE  rrn = l_orgnl_txn_rrn AND
			business_date = l_orgnl_txn_business_date AND
			business_time = l_orgnl_txn_business_time AND
			customer_card_no = l_hash_pan AND instcode = p_inst_code_in;
ELSE
		 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
	   SET    tran_reverse_flag = 'Y'
	   WHERE  rrn = l_orgnl_txn_rrn AND
			business_date = l_orgnl_txn_business_date AND
			business_time = l_orgnl_txn_business_time AND
			customer_card_no = l_hash_pan AND instcode = p_inst_code_in;
END IF;			
	 
	   IF SQL%ROWCOUNT = 0
	   THEN
		l_resp_cde := '21';
		l_errmsg   := 'Reverse flag is not updated ';
		RAISE exp_rvsl_reject_record;
	   END IF;
	 EXCEPTION
	   WHEN exp_rvsl_reject_record THEN
		RAISE;
	   WHEN OTHERS THEN
		l_resp_cde := '21';
		l_errmsg   := 'Error while updating gl flag ' ||
				    substr(SQLERRM, 1, 200);
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


IF (v_Retdate>v_Retperiod)
    THEN

	   UPDATE cms_statements_log
	   SET    csl_time_stamp = l_timestamp
	   WHERE  csl_pan_no = l_hash_pan AND csl_rrn = p_rrn_in AND
			csl_delivery_channel = p_delv_chnl_in AND
			csl_txn_code = p_txn_code_in AND
			csl_business_date = p_business_date_in AND
			csl_business_time = p_business_time_in;
ELSE
		  UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
	   SET    csl_time_stamp = l_timestamp
	   WHERE  csl_pan_no = l_hash_pan AND csl_rrn = p_rrn_in AND
			csl_delivery_channel = p_delv_chnl_in AND
			csl_txn_code = p_txn_code_in AND
			csl_business_date = p_business_date_in AND
			csl_business_time = p_business_time_in;
END IF;
			
	 
	   IF SQL%ROWCOUNT = 0
	   THEN
	   
		NULL;
	   
	   END IF;
	 
	 EXCEPTION
	   WHEN OTHERS THEN
	   
		l_resp_cde := '21';
		l_errmsg   := 'Error while updating timestamp in statement log ' ||
				    substr(SQLERRM, 1, 100);
		RAISE exp_rvsl_reject_record;
	 END;
    
	 IF l_errmsg = 'OK'
	 THEN
	 
	   IF l_gpr_chk = 'N'
	   THEN
		BEGIN
		
		  SELECT cce_fee_plan
		  INTO   l_fee_plan_id
		  FROM   cms_card_excpfee_hist
		  WHERE  cce_inst_code = p_inst_code_in AND
			    cce_pan_code = l_hash_pan AND rownum = 1;
		
		EXCEPTION
		  WHEN no_data_found THEN
		    l_resp_cde := '21';
		    l_errmsg   := 'Fee Plan Id not Found in hist table ';
		    RAISE exp_rvsl_reject_record;
		  WHEN OTHERS THEN
		    l_resp_cde := '21';
		    l_errmsg   := 'Error while selecting fee plan id from fee hist table  ' ||
					   SQLERRM;
		    RAISE exp_rvsl_reject_record;
		  
		END;
		BEGIN
		  UPDATE cms_card_excpfee
		  SET    cce_fee_plan = l_fee_plan_id, cce_lupd_user = 1,
			    cce_lupd_date = SYSDATE
		  WHERE  cce_inst_code = p_inst_code_in AND
			    cce_pan_code = l_hash_pan AND
			    ((cce_valid_to IS NOT NULL AND
			    (l_rvsl_trandate BETWEEN cce_valid_from AND
			    cce_valid_to)) OR
			    (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from));
		
		  IF SQL%ROWCOUNT = 0
		  THEN
		    l_errmsg   := 'updating FEE PLAN ID IS NOT HAPPENED';
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		  END IF;
		
		EXCEPTION
		  WHEN exp_rvsl_reject_record THEN
		    RAISE exp_rvsl_reject_record;
		  WHEN OTHERS THEN
		    l_errmsg   := 'Error while updating FEE PLAN ID ' ||
					   substr(SQLERRM, 1, 200);
		    l_resp_cde := '21';
		    RAISE exp_rvsl_reject_record;
		END;
	   
	   END IF;
	   p_resp_msg_out := to_char(l_acct_balance);
	 
	 ELSE
	   p_resp_msg_out := l_errmsg;
	 END IF;
    EXCEPTION
	 WHEN exp_rvsl_reject_record THEN
	   RAISE;
	 WHEN OTHERS THEN
	   l_resp_cde := '21';
	   l_errmsg   := 'Error while inserting records in transaction log ' ||
				  substr(SQLERRM, 1, 200);
	   RAISE exp_rvsl_reject_record;
    END;
    --En  create a entry in GL
  EXCEPTION
    -- << MAIN EXCEPTION>>
    WHEN exp_rvsl_reject_record THEN
	 ROLLBACK TO l_savepoint;
	 BEGIN
	   SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
	   INTO   l_acct_balance, l_ledger_balance, l_cam_type_code
	   FROM   cms_acct_mast
	   WHERE  cam_acct_no = l_acct_number AND
			cam_inst_code = p_inst_code_in;
	 EXCEPTION
	   WHEN OTHERS THEN
		l_acct_balance   := 0;
		l_ledger_balance := 0;
	 END;
	 p_dda_number_out := l_acct_number;
	 BEGIN
	   SELECT cms_iso_respcde
	   INTO   p_resp_cde_out
	   FROM   cms_response_mast
	   WHERE  cms_inst_code = p_inst_code_in AND
			cms_delivery_channel = p_delv_chnl_in AND
			cms_response_id = to_number(l_resp_cde);
	 
	   p_resp_msg_out := l_errmsg;
	 EXCEPTION
	   WHEN OTHERS THEN
		p_resp_msg_out := 'Problem while selecting data from response master ' ||
					   l_resp_cde || substr(SQLERRM, 1, 300);
		p_resp_cde_out := '69';
	 END;
    
	 IF l_prod_code IS NULL
	 THEN
	 
	   BEGIN
	   
		SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
		INTO   l_prod_code, l_card_type, l_applpan_cardstat, l_acct_number
		FROM   cms_appl_pan
		WHERE  cap_inst_code = p_inst_code_in AND
			  cap_pan_code = l_hash_pan;
	   EXCEPTION
		WHEN OTHERS THEN
		
		  NULL;
		
	   END;
	 
	 END IF;
    
	 IF l_dr_cr_flag IS NULL
	 THEN
	 
	   BEGIN
	   
		SELECT ctm_credit_debit_flag
		INTO   l_dr_cr_flag
		FROM   cms_transaction_mast
		WHERE  ctm_tran_code = p_txn_code_in AND
			  ctm_delivery_channel = p_delv_chnl_in AND
			  ctm_inst_code = p_inst_code_in;
	   
	   EXCEPTION
		WHEN OTHERS THEN
		
		  NULL;
		
	   END;
	 
	 END IF;
    
	 BEGIN
	   INSERT INTO transactionlog
		(msgtype, rrn, delivery_channel, terminal_id, date_time, txn_code,
		 txn_type, txn_mode, txn_status, response_code, business_date,
		 business_time, customer_card_no, topup_card_no, topup_acct_no,
		 topup_acct_type, bank_code, total_amount, rule_indicator,
		 rulegroupid, currencycode, productid, categoryid, tips,
		 decline_ruleid, atm_name_location, auth_id, trans_desc, amount,
		 preauthamount, partialamount, mccodegroupid, currencycodegroupid,
		 transcodegroupid, rules, preauth_date, gl_upd_flag, instcode,
		 feecode, feeattachtype, tran_reverse_flag, customer_card_no_encr,
		 topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
		 acct_balance, ledger_balance, response_id, cardstatus, error_msg,
		 acct_type, time_stamp, cr_dr_flag, store_id, fee_plan,
		 tranfee_amt, merchant_name, merchant_city)
	   VALUES
		(p_msg_typ_in, p_rrn_in, p_delv_chnl_in, p_terminal_id_in,
		 l_rvsl_trandate, p_txn_code_in, p_txn_type_in, p_txn_mode_in,
		 decode(p_resp_cde_out, '00', 'C', 'F'), p_resp_cde_out,
		 p_business_date_in, substr(p_business_time_in, 1, 6), l_hash_pan,
		 NULL, NULL, NULL, p_inst_code_in,
		 TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
		 NULL, NULL, l_curr_code, l_prod_code, l_card_type, '0.00', NULL,
		 NULL, l_auth_id, l_tran_desc,
		 TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
		 '0.00', '0.00', NULL, NULL, NULL, NULL, NULL, 'Y', p_inst_code_in,
		 l_fee_code, l_feeattach_type, 'N', l_encr_pan, NULL,
		 l_proxunumber, p_rvsl_code_in, l_acct_number,
		 TRIM(to_char(nvl(l_acct_balance, 0), '99999999999999990.99')),
		 TRIM(to_char(nvl(l_ledger_balance, 0), '99999999999999990.99')),
		 l_resp_cde, l_applpan_cardstat, l_errmsg, l_cam_type_code,
		 nvl(l_timestamp, systimestamp),
		 decode(p_delv_chnl_in, '04', l_dr_cr_flag,
			    decode(l_dr_cr_flag, 'CR', 'DR', 'DR', 'CR', l_dr_cr_flag)),
		 NULL, l_fee_plan, l_fee_amt, p_merchant_name, p_merchant_city);
	 EXCEPTION
	   WHEN OTHERS THEN
		p_resp_msg_out := 'Problem while inserting data into transaction log  dtl' ||
					   substr(SQLERRM, 1, 300);
		p_resp_cde_out := '69'; -- Server Declined
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
		 ctd_location_id, ctd_hashkey_id)
	   VALUES
		(p_delv_chnl_in, p_txn_code_in, p_txn_type_in, p_msg_typ_in,
		 p_txn_mode_in, p_business_date_in, p_business_time_in, l_hash_pan,
		 l_tran_amt, l_currcode, l_tran_amt, NULL, NULL, NULL, NULL,
		 l_tran_amt, l_card_curr, 'E', l_errmsg, p_rrn_in, p_inst_code_in,
		 l_encr_pan, l_acct_number, p_terminal_id_in, l_hashkey_id);
	 EXCEPTION
	   WHEN OTHERS THEN
		p_resp_msg_out := 'Problem while inserting data into transaction log  dtl' ||
					   substr(SQLERRM, 1, 300);
		p_resp_cde_out := '69';
		ROLLBACK;
		RETURN;
	 END;
    
	 p_resp_msg_out := l_errmsg;
    WHEN OTHERS THEN
	 ROLLBACK TO l_savepoint;
	 BEGIN
	   SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
	   INTO   l_acct_balance, l_ledger_balance, l_cam_type_code
	   FROM   cms_acct_mast
	   WHERE  cam_acct_no = l_acct_number AND
			cam_inst_code = p_inst_code_in;
	 EXCEPTION
	   WHEN OTHERS THEN
		l_acct_balance   := 0;
		l_ledger_balance := 0;
	 END;
    
	 BEGIN
	   SELECT cms_iso_respcde
	   INTO   p_resp_cde_out
	   FROM   cms_response_mast
	   WHERE  cms_inst_code = p_inst_code_in AND
			cms_delivery_channel = p_delv_chnl_in AND
			cms_response_id = to_number(l_resp_cde);
	 
	   p_resp_msg_out := l_errmsg;
	 EXCEPTION
	   WHEN OTHERS THEN
		p_resp_msg_out := 'Problem while selecting data from response master ' ||
					   l_resp_cde || substr(SQLERRM, 1, 300);
		p_resp_cde_out := '69';
	 END;
    
	 -----------------------------------------------
	 --SN: Added on 17-Apr-2013 for defect 10871
	 -----------------------------------------------     
    
	 IF l_prod_code IS NULL
	 THEN
	 
	   BEGIN
	   
		SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
		INTO   l_prod_code, l_card_type, l_applpan_cardstat, l_acct_number
		FROM   cms_appl_pan
		WHERE  cap_inst_code = p_inst_code_in AND
			  cap_pan_code = l_hash_pan;
	   EXCEPTION
		WHEN OTHERS THEN
		
		  NULL;
		
	   END;
	 
	 END IF;
    
	 IF l_dr_cr_flag IS NULL
	 THEN
	 
	   BEGIN
	   
		SELECT ctm_credit_debit_flag
		INTO   l_dr_cr_flag
		FROM   cms_transaction_mast
		WHERE  ctm_tran_code = p_txn_code_in AND
			  ctm_delivery_channel = p_delv_chnl_in AND
			  ctm_inst_code = p_inst_code_in;
	   
	   EXCEPTION
		WHEN OTHERS THEN
		
		  NULL;
		
	   END;
	 
	 END IF;
    
	 -----------------------------------------------
	 --EN: Added on 17-Apr-2013 for defect 10871
	 -----------------------------------------------             
    
	 BEGIN
	   INSERT INTO transactionlog
		(msgtype, rrn, delivery_channel, terminal_id, date_time, txn_code,
		 txn_type, txn_mode, txn_status, response_code, business_date,
		 business_time, customer_card_no, topup_card_no, topup_acct_no,
		 topup_acct_type, bank_code, total_amount, rule_indicator,
		 rulegroupid, currencycode, productid, categoryid, tips,
		 decline_ruleid, atm_name_location, auth_id, trans_desc, amount,
		 preauthamount, partialamount, mccodegroupid, currencycodegroupid,
		 transcodegroupid, rules, preauth_date, gl_upd_flag, instcode,
		 feecode, feeattachtype, tran_reverse_flag, customer_card_no_encr,
		 topup_card_no_encr, proxy_number, reversal_code, customer_acct_no,
		 acct_balance, ledger_balance, response_id, cardstatus, error_msg,
		 acct_type, time_stamp, cr_dr_flag, store_id, fee_plan,
		 tranfee_amt, merchant_name, merchant_city)
	   VALUES
		(p_msg_typ_in, p_rrn_in, p_delv_chnl_in, p_terminal_id_in,
		 l_rvsl_trandate, p_txn_code_in, p_txn_type_in, p_txn_mode_in,
		 decode(p_resp_cde_out, '00', 'C', 'F'), p_resp_cde_out,
		 p_business_date_in, substr(p_business_time_in, 1, 6), l_hash_pan,
		 NULL, NULL, NULL, p_inst_code_in,
		 TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
		 NULL, NULL, l_curr_code, l_prod_code, l_card_type, '0.00', NULL,
		 NULL, l_auth_id, l_tran_desc,
		 TRIM(to_char(nvl(l_reversal_amt, 0), '99999999999999990.99')),
		 '0.00', '0.00', NULL, NULL, NULL, NULL, NULL, 'Y', p_inst_code_in,
		 l_fee_code, l_feeattach_type, 'N', l_encr_pan, NULL,
		 l_proxunumber, p_rvsl_code_in, l_acct_number,
		 nvl(l_acct_balance, 0), nvl(l_ledger_balance, 0), l_resp_cde,
		 l_applpan_cardstat, l_errmsg, l_cam_type_code,
		 nvl(l_timestamp, systimestamp),
		 decode(p_delv_chnl_in, '04', l_dr_cr_flag,
			    decode(l_dr_cr_flag, 'CR', 'DR', 'DR', 'CR', l_dr_cr_flag)),
		 NULL, l_fee_plan, l_fee_amt, p_merchant_name, p_merchant_city);
	 EXCEPTION
	   WHEN OTHERS THEN
		p_resp_msg_out := 'Problem while inserting data into transaction log  dtl' ||
					   substr(SQLERRM, 1, 300);
		p_resp_cde_out := '69'; -- Server Declined
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
		 ctd_location_id,
		 --ADDED FOR 12933
		 ctd_hashkey_id
		 --ADDED FOR 12933        
		 )
	   VALUES
		(p_delv_chnl_in, p_txn_code_in, p_txn_type_in, p_msg_typ_in,
		 p_txn_mode_in, p_business_date_in, p_business_time_in, l_hash_pan,
		 l_tran_amt, l_currcode, l_tran_amt, NULL, NULL, NULL, NULL,
		 l_tran_amt, l_card_curr, 'E', l_errmsg, p_rrn_in, p_inst_code_in,
		 l_encr_pan, l_acct_number, p_terminal_id_in, l_hashkey_id);
	 EXCEPTION
	   WHEN OTHERS THEN
		p_resp_msg_out := 'Problem while inserting data into transaction log  dtl' ||
					   substr(SQLERRM, 1, 300);
		p_resp_cde_out := '69';
		ROLLBACK;
		return;
    
	 END;
    
  END reverse_activate_initial_load;

  PROCEDURE concurrent_txncheck(p_inst_code_in        IN VARCHAR2,
						  p_new_card_in         IN VARCHAR2,
						  p_old_card_in         IN VARCHAR2,
						  p_txn_code_in         IN VARCHAR2,
						  p_delivery_channel_in IN VARCHAR2,
						  p_msgtype_in          IN VARCHAR2,
						  p_busdate_in          IN VARCHAR2,
						  p_exist_count_out     OUT NUMBER) IS
  BEGIN
    SELECT COUNT(1)
    INTO   p_exist_count_out
    FROM   vms_concurrent_txncheck
    WHERE  vcm_inst_code = p_inst_code_in AND
		 vcm_new_cardno = p_new_card_in AND
		 vcm_old_cardno = p_old_card_in AND vcm_txn_code = p_txn_code_in AND
		 vcm_delivery_channel = p_delivery_channel_in AND
		 vcm_msg_type = p_msgtype_in AND vcm_business_date = p_busdate_in;
  
  EXCEPTION
    WHEN OTHERS THEN
	 p_exist_count_out := 'N';
    
  END concurrent_txncheck;

  PROCEDURE current_txnlog(p_inst_code_in        IN VARCHAR2,
					  p_new_card_in         IN VARCHAR2,
					  p_old_card_in         IN VARCHAR2,
					  p_txn_code_in         IN VARCHAR2,
					  p_delivery_channel_in IN VARCHAR2,
					  p_msgtype_in          IN VARCHAR2,
					  p_busdate_in          IN VARCHAR2) IS
  
    PRAGMA AUTONOMOUS_TRANSACTION;
  
  BEGIN
    INSERT INTO vms_concurrent_txncheck
	 (vcm_inst_code, vcm_new_cardno, vcm_old_cardno, vcm_txn_code,
	  vcm_delivery_channel, vcm_msg_type, vcm_business_date)
    VALUES
	 (p_inst_code_in, p_new_card_in, p_old_card_in, p_txn_code_in,
	  p_delivery_channel_in, p_msgtype_in, p_busdate_in);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
	 ROLLBACK;
  END current_txnlog;

  PROCEDURE current_txnlogclear(p_inst_code_in IN NUMBER,
						  p_new_card_in  IN VARCHAR2,
						  p_old_card_in  IN VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    DELETE vms_concurrent_txncheck
    WHERE  vcm_inst_code = p_inst_code_in AND
		 vcm_new_cardno = p_new_card_in AND
		 vcm_old_cardno = p_old_card_in;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
	 ROLLBACK;
  END current_txnlogclear;

END;

/

show error;