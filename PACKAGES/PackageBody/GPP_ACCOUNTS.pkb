create or replace PACKAGE BODY        VMSCMS.GPP_ACCOUNTS IS

  -- PL/SQL Package using FS Framework
  -- Author  : Rojalin Beura
  -- Created : 8/17/2015 10:51:34 AM

  -- Private type declarations
  -- TEST 1

  -- Private constant declarations

  -- Private variable declarations

  -- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;

  --declare all FS errors here
  g_err_nodata       fsfw.fserror_t;
  g_err_failure      fsfw.fserror_t;
  g_err_unknown      fsfw.fserror_t;
  g_err_mandatory    fsfw.fserror_t;
  g_err_invalid_data fsfw.fserror_t;
  g_err_savingacc    fsfw.fserror_t;
  g_err_feewaiver    fsfw.fserror_t;

  -- Global variables for the package
  TYPE g_tab_typ IS TABLE OF VARCHAR2(1000) INDEX BY VARCHAR2(1000);

--Commandad since we get the description from master table
--  g_device_type_tab g_tab_typ;

--  g_token_type_tab g_tab_typ;

  g_token_status_tab g_tab_typ;

  -- Function and procedure implementations
  -- To get the account details
  --status: 0 - success, Non Zero value - failure
  PROCEDURE print(p_text_in VARCHAR2) IS
  BEGIN
    dbms_output.put_line(p_text_in);
  END print;

  FUNCTION get_wallet_id(p_vti_token_requestor_id_in IN VARCHAR2,
                         p_vti_wallet_identifier_in  IN VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    IF p_vti_wallet_identifier_in IS NOT NULL
       AND p_vti_token_requestor_id_in IS NOT NULL
    THEN
      -- MasterCard Token
      RETURN p_vti_wallet_identifier_in;
    ELSIF p_vti_wallet_identifier_in IS NULL
          AND p_vti_token_requestor_id_in IS NOT NULL
    THEN
      -- Visa Token
      RETURN p_vti_token_requestor_id_in;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_wallet_id;

  PROCEDURE get_account_details(p_customer_id_in              IN  VARCHAR2,
                                p_status_out                  OUT VARCHAR2,
                                p_err_msg_out                 OUT VARCHAR2,
                                c_account_detail_out          OUT SYS_REFCURSOR,
                                c_cardfee_detail_out          OUT SYS_REFCURSOR,
                                c_limits_detail_out           OUT SYS_REFCURSOR,
                                c_doc_detail_out              OUT SYS_REFCURSOR,
                                c_multipack_card_out          OUT SYS_REFCURSOR,
                                c_relative_account_detail_out OUT SYS_REFCURSOR
                                --p_upgrade_eligible_flag                  OUT VARCHAR2        --Commented by FSS
                                --c_token_detail_out   OUT SYS_REFCURSOR                    --Commented by FSS
                                ) AS
    l_api_name   VARCHAR2(20) := 'GET ACCOUNT DETAILS';
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    --performance change
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no      vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;

    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;

    l_token_rec vmscms.account_detail_token_typ_t;
    l_token_tab vmscms.account_detail_token_list_t := account_detail_token_list_t();
    L_DELETE_DATE DATE;


/***************************************************************************************

	     * Modified By        : UBAIDUR RAHMAN H
         * Modified Date      : 07-Feb-2019
         * Modified Reason    : Modified to return Token and Device details to CCA(VMS-447)/
		                        Permanent Fraud Override Support(VMS-511).
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 07-Feb-2019
         * Build Number       : R12_B0003


         * Modified By        : UBAIDUR RAHMAN H
         * Modified Date      : 26-Apr-2019
         * Modified Reason    : Modified for FSAPI-391 VMS-888 (FSAPI-B2B - Support for Print Order Status)
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 29-Apr-2019
         * Build Number       : R15_B0004

         * Modified By        : UBAIDUR RAHMAN H / Ayodeji Filegbe.
         * Modified Date      : 20-Aug-2019.
         * Modified Reason    : Modified for VMS-1069 - Enhance GPP Accounts lookup to
                                                            return related accounts (CCA Gap)
         * Reviewer           : Saravana Kumar A
         * Reviewed Date      : 20-Aug-2019.
         * Build Number       : R19_B0004

	 * Modified By        : UBAIDUR RAHMAN H
         * Modified Date      : 18-Oct-2019.
         * Modified Reason    : Modified for Momentum Expired Card issue
         * Reviewer           : Saravana Kumar A
         * Reviewed Date      : 18-Oct-2019.
         * Build Number       : VMSRSI0220

	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002

	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 11-Feb-2020
         * Modified Reason    : VMS-1057 - VMS Gift: Card Replacement Tracking.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R26_B0002

	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 26-May-2020
         * Modified Reason    : VMS-2009 - Display CCPA flag for records associated with edit/delete requests.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 26-May-2020
         * Build Number       : R31_B0002

	 * Modified By                  : Ubaidur Rahman.H
	 * Modified Date                : 26-NOV-2021
	 * Modified Reason              : VMS-5253 - Do not pass system Generated Profile from VMS to CCA
	 * Build Number                 : R55 B3
	 * Reviewer                     : Saravanakumar A.
	 * Reviewed Date                : 26-Nov-2021


      * Modified By                  : John G
	 * Modified Date                : 08-DEC-2022
	 * Modified Reason              : VMS-6034
	 * Build Number                 : R73 B1
	 * Reviewer                     : Venkat S
	 * Reviewed Date                :
     
     * Modified By                  : Bhavani E
	 * Modified Date                : 28-Feb-2023
	 * Modified Reason              : VMS-7102 Added to refund check eligibility
	 * Build Number                 : R76
	 * Reviewer                     : Venkat S
	 * Reviewed Date                : 
	 
	 * Modified By      :  John G
     * Modified Date    :  16-May-2023
     * Modified Reason  :  VMS-7303  - Virtual Card Replacements
     * Reviewer         :  Pankaj S.
      
***************************************************************************************/

  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));

    --   l_partner_id := 1;
    --Fetching the active PAN for the input customer id
    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_cust_code,
                                   l_prod_code,
                                   l_card_type,
                                   l_proxy_no,
                                   l_cardstat,
                                   l_acct_no,
                                   l_masked_pan,
                                   l_profile_code);

    g_debug.display('l_acct_no' || l_acct_no);
    g_debug.display('l_cust_code' || l_cust_code);
    g_debug.display('p_customer_id_in' || p_customer_id_in);
    g_debug.display('l_hash_pan' || l_hash_pan);

    BEGIN

     IF L_HASH_PAN IS NULL AND l_encr_pan IS NULL THEN
       BEGIN

SELECT MAX(INS_DATE) 
INTO L_DELETE_DATE
        FROM VMSCMS.ZBDDD_CARD_INFO
        WHERE CUST_CODE = (SELECT ccm_cust_code
                          FROM vmscms.cms_cust_mast
                         WHERE ccm_cust_id = to_number(p_customer_id_in));

IF L_DELETE_DATE IS NOT NULL THEN
OPEN c_account_detail_out FOR 
	   SELECT 'Account deleted on ' || TO_CHAR(L_DELETE_DATE,'MM/DD/YYYY') || ' due to inactivity. Card has zero balance at time of deletion.' accountDeletionDescription
        FROM DUAL;


         vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

p_status_out := vmscms.gpp_const.c_success_status;

                                                   return;

END IF;
		EXCEPTION
		 WHEN OTHERS THEN
		    NULL;
		END;
        END IF;


        IF l_cardstat = '19' THEN
            UPDATE VMSCMS.cms_appl_pan
               SET cap_card_stat = cap_old_cardstat,
                   cap_cardstatus_expiry = NULL
             WHERE cap_pan_code = l_hash_pan
               AND cap_inst_code = 1
               AND cap_card_stat = '19'
               AND cap_cardstatus_expiry <= SYSDATE;

             IF SQL%ROWCOUNT = 1 THEN
                      VMSCMS.SP_LOG_CARDSTAT_CHNGE(1,
                                            l_hash_pan,
                                            l_encr_pan,
                                            LPAD(VMSCMS.SEQ_AUTH_ID.NEXTVAL, 6, '0'),
                                            '99',
                                            null,
                                            null,
                                            null,
                                            p_status_out,
                                            p_err_msg_out,
                                            'Host initiated rollback of card status from RISK INVESTIGATION');
             END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    --- Modified for VMS-1069 - Enhance GPP Accounts lookup to return related accounts (CCA Gap)
    --Ivanhoe addition VMS-1069 starts

      OPEN c_relative_account_detail_out FOR
      SELECT cap_acct_no rel_acct_no,
                 ccm_cust_id rel_customer_id,
                 cap_serial_number rel_serial_number,
                 cap_proxy_number rel_proxy_number,
                 vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) rel_pan
            FROM vmscms.cms_appl_pan, vmscms.cms_cust_mast
           WHERE cap_acct_no = (SELECT CAM_FUNDING_ACCT_NO FROM vmscms.cms_acct_mast
                                WHERE cam_inst_code = 1 AND cam_acct_no = l_acct_no)
             AND cap_cust_code = ccm_cust_code
             AND cap_inst_code = ccm_inst_code;



    --Ivanhoe addition ends

    --Account Detail Array
    OPEN c_account_detail_out FOR
      SELECT cap_acct_no acct_no,
             --  b.ccm_user_name onlineuserid,
			       decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(b.ccm_user_name),b.ccm_user_name) onlineuserid,
             nvl (h.cpc_rout_num, h.cpc_institution_id
                        ||'-'
                        || h.cpc_transit_number) routingnumber,
             decode(b.ccm_acctlock_flag,
                    'L',
                    'Locked',
                    'Active') onlineaccountstaus,
             (select to_char(nvl(cam_ledger_bal,
                         0),
                     '9,999,999,990.99') from vmscms.cms_acct_mast
                     where cam_acct_no=cap_acct_no
                     and cam_inst_code=cap_inst_code)ledger_balance,
             (select to_char(nvl(cam_acct_bal,
                         0),
                     '9,999,999,990.99') from vmscms.cms_acct_mast
                     where cam_acct_no=cap_acct_no
                     and cam_inst_code=cap_inst_code) available_balance,
             to_char(nvl(saving.cam_acct_bal,
                         0),
                     '9,999,999,990.99') savings_acct_balance,
             saving.cam_acct_no saving_acct_no,
             (SELECT cdp_param_value
                FROM cms_dfg_param
               WHERE cdp_param_key IN ('Saving account Interest rate')
                 AND cdp_prod_code = h.cpc_prod_code
                 AND cdp_card_type = h.cpc_card_type) saving_interest_rate,
             --Start CFIP-219 Defect Fix
             --CDP_PARAM_VALUE - NVL(SAVING.CAM_SAVTOSPD_TFER_COUNT,0) REMAINING_TRANSFER,
             CASE
               WHEN (to_date(SYSDATE,
                             'dd-MM-yyyy hh24:MI:ss') <=
                    to_date(saving.cam_savtospd_tfer_date,
                             'dd-MM-yyyy hh24:MI:ss')) THEN
                 (SELECT to_number(cdp_param_value) -
                to_number(nvl(saving.cam_savtospd_tfer_count,
                              0))
                FROM vmscms.cms_dfg_param
               WHERE cdp_param_key='MaxNoTrans'
                 AND cdp_prod_code = h.cpc_prod_code
                 AND cdp_card_type = h.cpc_card_type)
                -- to_number(cdp_param_value) -
                --to_number(nvl(saving.cam_savtospd_tfer_count,
                        --      0))
               ELSE
                 (SELECT to_number(cdp_param_value)
                FROM vmscms.cms_dfg_param
               WHERE cdp_param_key ='MaxNoTrans'
                 AND cdp_prod_code = h.cpc_prod_code
                 AND cdp_card_type = h.cpc_card_type)
                -- to_number(cdp_param_value)
             END remaining_transfer,
             --End CFIP-219
             --     b.ccm_first_name firstname,
             --     b.ccm_mid_name middlename,
             --    b.ccm_last_name lastname,
             decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(b.ccm_first_name),b.ccm_first_name) firstname,
			       decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(b.ccm_mid_name),b.ccm_mid_name) middlename,
			       decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(b.ccm_last_name),b.ccm_last_name) lastname,
             b.ccm_business_name businessname,
             c.cpm_prod_desc product_name,
             c.cpm_prod_code prod_code,
             g.cim_interchange_name product_type,
             to_char(a.cam_reg_date,
                     'YYYY-MM-DD') regn_date,
	         decode(h.cpc_user_identify_type,'1','GIFT','GPR') cardtype,
             /*(SELECT cim_idtype_desc
                FROM vmscms.cms_idtype_mast
               WHERE cim_inst_code = 1
                 AND ccm_id_type = cim_idtype_code
                 AND rownum = 1) idtype,*/
            (SELECT cim_idtype_desc
               FROM vmscms.cms_idtype_mast
              WHERE cim_inst_code = 1 AND ccm_id_type = cim_idtype_code
                    AND cim_idtype_flag =
                           (SELECT DECODE (cbp_param_value, '840', 'U', 'C')
                              FROM vmscms.cms_bin_param
                             WHERE cbp_profile_code = h.cpc_profile_code
                                   AND cbp_param_name = 'Currency')) idtype,
             --Jira issue CFIP: 189 starts
             --b.ccm_ssn id_number,
             decode(ccm_id_type,
                    'SSN',
                    lpad(substr(b.ccm_ssn,
                                length(b.ccm_ssn) - 3,
                                length(b.ccm_ssn)),
                         length(b.ccm_ssn),
                         'X'),
                    b.ccm_ssn) id_number,
             --Jira issue CFIP: 189 ends
             b.ccm_id_issuer id_issuer,
             to_char(ccm_idissuence_date,
                     'YYYY-MM-DD') issued_date,
             to_char(b.ccm_idexpry_date,
                     'YYYY-MM-DD') id_expiry_date,
             vmscms.fn_dmaps_main(b.ccm_mother_name) mothers_maiden_name,
             to_char(b.ccm_birth_date,
                     'YYYY-MM-DD') dateofbirth,
             'MOBILE' mobile_type,
             --    physical_addr.cam_mobl_one cam_mobl_one,
			       decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_mobl_one),physical_addr.cam_mobl_one) cam_mobl_one,
             'LANDLINE' landline_type,
             --  physical_addr.cam_phone_one cam_phone_one,
             --  physical_addr.cam_email email_address,
			       decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_phone_one),physical_addr.cam_phone_one) cam_phone_one,
			       decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_email),physical_addr.cam_email) email_address,
             --physical addr
             CASE physical_addr.cam_addr_flag
               WHEN 'P' THEN
                'PHYSICAL'
             END address_type1,
             --   physical_addr.cam_add_one physical_address1,
             --   physical_addr.cam_add_two physical_address2,
             --   physical_addr.cam_city_name physical_city,

                   decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_add_one),physical_addr.cam_add_one)) physical_address1,
			       decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_add_two),physical_addr.cam_add_two)) physical_address2,
			       decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_city_name),physical_addr.cam_city_name)) physical_city,
             --(SELECT upper(gs.gsm_state_name)
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT upper(gs.gsm_switch_state_code) --Jira Issue: CFIP:211
                FROM vmscms.gen_state_mast gs
               WHERE gs.gsm_inst_code = physical_addr.cam_inst_code
                 AND gs.gsm_state_code = physical_addr.cam_state_code
                 AND gs.gsm_cntry_code = physical_addr.cam_cntry_code)) physical_state,
    --        physical_addr.cam_pin_code physical_zip,
			    decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_pin_code),physical_addr.cam_pin_code)) physical_zip,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT substr(upper(gcm_cntry_name),
                            1,
                            2)
                FROM vmscms.gen_cntry_mast cs
               WHERE cs.gcm_inst_code = physical_addr.cam_inst_code
                 AND cs.gcm_cntry_code = physical_addr.cam_cntry_code)) physical_cntry_code,
             physical_addr.cam_lupd_date physical_timestamp,
             --mailing addr
             CASE mailing_addr.cam_addr_flag
               WHEN 'O' THEN
                'MAILING'
             END address_type2,
             --  mailing_addr.cam_add_one mailing_address1,
             --  mailing_addr.cam_add_two mailing_address2,
             --  mailing_addr.cam_city_name mailing_city,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_add_one),mailing_addr.cam_add_one)) mailing_address1,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_add_two),mailing_addr.cam_add_two)) mailing_address2,
			       decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_city_name),mailing_addr.cam_city_name)) mailing_city,
             --(SELECT upper(gsm_state_name)
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT upper(gm.gsm_switch_state_code) --Jira Issue: CFIP:211
                FROM vmscms.gen_state_mast gm
               WHERE gm.gsm_inst_code = mailing_addr.cam_inst_code
                 AND gm.gsm_state_code = mailing_addr.cam_state_code
                 AND gm.gsm_cntry_code = mailing_addr.cam_cntry_code)) mailing_state,
             --    mailing_addr.cam_pin_code mailing_zip,
                decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(h.cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_pin_code),mailing_addr.cam_pin_code)) mailing_zip,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT substr(upper(gcm_cntry_name),
                            1,
                            2) --Jira Issue: CFIP:211
                FROM vmscms.gen_cntry_mast cm
               WHERE cm.gcm_inst_code = mailing_addr.cam_inst_code
                 AND cm.gcm_cntry_code = mailing_addr.cam_cntry_code)) mailing_cntry_code,
             mailing_addr.cam_lupd_date mailing_timestamp,
             decode(b.ccm_kyc_source,
                    '03',
                    'Desktop',
                    '06',
                    'Website',
                    '04',
                    'MMPOS',
                    '08',
                    'SPIL') regn_source,
             d.ckm_flag_desc kyc_status_desc,
             b.ccm_kyc_flag kyc_code,
             decode(b.ccm_ofac_fail_flag,
                    'Y',
                    'FAILED',
                    'SUCCESS') ofac_status,
             --Jira fix CFIP-51 starts
             --f.ckl_kycres_restricted_message ofac_desc,
             CASE ccm_ofac_fail_flag
               WHEN 'Y' THEN
                (SELECT ckl_kycres_restricted_message
                   FROM vmscms.cms_kyctxn_log, vmscms.cms_caf_info_entry --performance changes
                  WHERE cci_appl_code =to_char( a.cam_appl_code )--performance changes
                    AND ckl_row_id = cci_row_id --performance changes
                    AND ckl_inst_code = cci_inst_code --performance changes
                    AND cci_inst_code = 1 --performance changes
                    AND rownum < 2)
               ELSE
                ''
             END AS ofac_desc,
             --Jira fix CFIP-51 ends
             decode(c.cpm_ctc_bin,
                    'Y',
                    'Enabled',
                    '06',
                    'N',
                    'Disabled') cross_bin_transfer,
             --a.cam_appl_code  --performance changes
             decode(b.ccm_kyc_flag,
                    'Y',
                    'TRUE',
                    'N',
                    'FALSE',
                    'FALSE') isregistered,
--             nvl(e.cap_provisioning_flag,
--                 'Y') token_provisioning_status,
             case when nvl(h.cpc_token_eligibility,'N') = 'N' then 'UNSUPPORTED'
                  when e.cap_provisioning_flag = 'N' then 'LOCKED'
                  else 'SUPPORTED'
                  end token_provisioning_status,
             e.cap_proxy_number AS proxynumber,
             decode(h.cpc_upgrade_eligible_flag,
                    'N',
                    'N/A',
                    'Y',
                    decode((SELECT COUNT(1)
                             FROM vmscms.cms_appl_pan
                            WHERE cap_startercard_flag = 'N'
                              AND cap_acct_no = e.cap_acct_no
							  AND cap_prod_code = h.cpc_prod_code
                              AND cap_inst_code = e.cap_inst_code),
                           0,
                           'TRUE',
                           'FALSE')) upgrade_eligible,
            -- decode(cap_rule_bypass, -- Modified for VMS-511(Permanent Fraud Override Support)
            --       'Y',
            --       'TRUE',
            --       'FALSE') AS fraud_override_flag,
             ccm_occupation occupationCode,
             decode(nvl(ccm_occupation,
                        '00'),
                    '00',
                    ccm_occupation_others,
                    (SELECT vom_occu_name
                       FROM vmscms.vms_occupation_mast
                      WHERE ccm_occupation = vom_occu_code)) occupationDescription,
             (SELECT upper(gsm_state_name)
                FROM vmscms.gen_state_mast
               WHERE gsm_switch_state_code = ccm_id_province
                 AND gsm_alpha_cntry_code =  (SELECT gcm_alpha_cntry_code
                                                FROM vmscms.gen_cntry_mast
                                               WHERE gcm_switch_cntry_code = ccm_id_country )) issuance_province,
             (SELECT upper(gcm_cntry_name)
                FROM vmscms.gen_cntry_mast
               WHERE gcm_switch_cntry_code = ccm_id_country) issuance_country,
             to_char(ccm_verification_date,
                     'YYYY-MM-DD') id_verification_date,
             decode(TRIM(ccm_tax_res_of_canada),
                    'Y',
                    'NO',
                    'N',
                    'YES') tax_resident_canada,
             ccm_tax_payer_id_num tax_payer_id_number,
             ccm_reason_for_no_tax_id noTaxIDReasonCode,
             ccm_reason_for_no_taxid_others noTaxIDReasonDescription,
             (SELECT upper(gcm_cntry_name)
                FROM gen_cntry_mast
               WHERE gcm_switch_cntry_code = ccm_jurisdiction_of_tax_res) tax_residence_jurisdiction,
               --Sn Added by FSS for VMS-78
               CURSOR(
                SELECT vdl_tran_amt loadAmount,
                       (vdl_expiry_date - vdl_ins_date) * 24 * 60 delayPeriod,
                       vdl_ins_date loadDateTime,
                       merchant_id merchantId,
                       merchant_name merchantName
                  FROM vmscms.vms_delayed_load, vmscms.transactionlog
                 WHERE     vdl_acct_no = e.cap_acct_no
                       AND vdl_expiry_date > SYSDATE
                       AND vdl_acct_no = customer_acct_no
                       AND vdl_rrn = rrn
                       AND vdl_txn_code = txn_code
                       AND vdl_delivery_channel = delivery_channel) REDEMPTION_DELAY,
                decode(f.vta_thirdparty_type,'1','INDIVIDUAL','2','CORPORATION') thirdPartyType,
                vmscms.fn_dmaps_main(f.vta_first_name) thirdPartyInfoFirstName,
                vmscms.fn_dmaps_main(f.vta_last_name) thirdPartyInfoLastName,
                f.vta_corporation_name thirdPartyInfoCorporationName,
                to_char(f.vta_dob, 'YYYY-MM-DD') thirdPartyInfoDateOfBirth,
                vmscms.fn_dmaps_main(f.vta_address_one) thirdPartyInfoAddress1,
                vmscms.fn_dmaps_main(f.vta_address_two) thirdPartyInfoAddress2,
                vmscms.fn_dmaps_main(f.vta_city_name) thirdPartyInfoCity,
                case when f.vta_cntry_code in (2,3) then f.vta_state_switch else f.vta_state_desc end thirdPartyInfoState,
                vmscms.fn_dmaps_main(f.vta_pin_code) thirdPartyInfoPostalCode,
                (SELECT upper(gcm_switch_cntry_code)
                        FROM vmscms.gen_cntry_mast
                       WHERE gcm_cntry_code = f.vta_cntry_code
                   AND gcm_inst_code = b.ccm_inst_code) thirdPartyInfoCountryCode,
                f.vta_occupation thirdpartyOccupationCode,
                f.vta_occupation_others thirdpartyOccupationDesc,
                f.vta_incorporation_number thirdPartyInfoInCorporationNum,
                f.vta_nature_of_releationship thirdPartyInfoNatureofRelation,
                f.vta_nature_of_business thirdPartyInfoNatureofBusiness,
                nvl(h.cpc_wrong_logoncount,0) - nvl(b.ccm_wrong_logincnt,0) remainingLoginAttempts,
                nvl(h.cpc_wrong_logoncount,0) totalLoginAttempts,
                nvl((SELECT cip_param_value FROM vmscms.cms_inst_param WHERE cip_param_key = 'TOTAL_PIN_ATTEMPTS' AND cip_inst_code='1'),0)
                - nvl(p.vpc_pin_count,0) remainingPinAttempts,
                nvl((SELECT cip_param_value FROM vmscms.cms_inst_param WHERE cip_param_key = 'TOTAL_PIN_ATTEMPTS' AND cip_inst_code='1'),0) totalPinAttempts,
                nvl(h.cpc_token_provision_retry_max,0)-nvl(e.cap_provisioning_attempt_count,0) rem_TokenProvisioningAttempts,
                nvl(h.cpc_token_provision_retry_max,0) tot_TokenProvisioningAttempts,
                e.cap_panmast_param2 parentSerialNumber,
                CASE when e.cap_rule_bypass = 'P' then 'TRUE' -- Modified for VMS-511(Permanent Fraud Override Support)
                      else 'FALSE'
                END  fraudOverridePermanentEnabled,
                CASE when e.cap_rule_bypass = 'Y' then 'TRUE'
                      else 'FALSE'
                END fraudOverrideOneTimeEnabled,
		decode(b.ccm_privacyregulation_flag,'Y','TRUE','FALSE') isCCPAEnabled          --- Added for VMS-2009
                --En Added by FSS for VMS-78
                ,decode(h.cpc_chequerefund_eligibility,'Y','TRUE','FALSE') IsChequeRefundSupported,         -- Added for VMS-7102 to refund check eligibility
                CASE WHEN nvl(E.cap_form_factor,'NA') = 'V' THEN 'TRUE' ELSE 'FALSE' END isVirtualProduct  --Added for VMS-7303
FROM vmscms.cms_appl_mast      a,
             vmscms.cms_cust_mast      b,
             vmscms.cms_prod_mast      c,
             vmscms.cms_prod_cattype   h,
             vmscms.cms_kycstatus_mast d,
             --  vmscms.cms_caf_info_entry e, --performance changes
             vmscms.cms_appl_pan e,
             vmscms.cms_interchange_mast g,
             vmscms.vms_thirdparty_address f,
			       vmscms.vms_pin_check p,
             /*(SELECT *
                FROM vmscms.cms_acct_mast, vmscms.cms_cust_acct
               WHERE cam_type_code = '1'
                 AND cca_acct_id = cam_acct_id
                 AND cca_inst_code = cam_inst_code
                 AND cca_inst_code = 1) spending,*/
             (SELECT *
                FROM vmscms.cms_acct_mast, vmscms.cms_cust_acct
               WHERE cam_type_code = '2'
                 AND cca_acct_id = cam_acct_id
                 AND cca_inst_code = cam_inst_code
                 AND cca_inst_code = 1) saving,
             --CFIP-6 Fix ends
             vmscms.cms_addr_mast physical_addr,
             vmscms.cms_addr_mast mailing_addr
             --cdp_card_type included to fix the duplicate record issue
             --This is due to 17.08 VMS changes
             /*(SELECT cdp_prod_code,
                     cdp_card_type,
                     cdp_param_value,
                     cdp_inst_code
                FROM cms_dfg_param
               WHERE cdp_param_key IN ('MaxNoTrans')
                 AND cdp_inst_code = 1) saving_acct_param*/
       WHERE a.cam_cust_code = b.ccm_cust_code
         AND a.cam_inst_code = b.ccm_inst_code --performance changes
            --  AND e.cci_appl_code = a.cam_appl_code --performance changes
            --  and e.cci_inst_code = a.cam_inst_code --performance changes
         AND b.ccm_cust_code = physical_addr.cam_cust_code
         AND b.ccm_inst_code = physical_addr.cam_inst_code --performance changes
         AND physical_addr.cam_addr_flag = 'P'
         AND b.ccm_cust_code = mailing_addr.cam_cust_code(+)
         AND b.ccm_inst_code = mailing_addr.cam_inst_code(+) --performance changes
         AND mailing_addr.cam_addr_flag(+) = 'O'
         AND a.cam_prod_code = c.cpm_prod_code
         AND e.cap_prod_code = h.cpc_prod_code
         AND e.cap_card_type = h.cpc_card_type
         AND e.cap_inst_code=h.cpc_inst_code
         AND a.cam_inst_code = c.cpm_inst_code
         AND g.cim_interchange_code = c.cpm_interchange_code
         AND g.cim_inst_code = c.cpm_inst_code
         AND d.ckm_flag = b.ccm_kyc_flag(+)
         AND d.ckm_inst_code = b.ccm_inst_code(+) --performance changes
         AND ccm_inst_code = saving.cca_inst_code(+)
         AND ccm_cust_code = saving.cca_cust_code(+)
         AND e.cap_appl_code = a.cam_appl_code
         AND e.cap_pan_code = l_hash_pan
		     AND b.ccm_cust_code = f.vta_cust_code(+)
            ----CFIP-6 Fix ends
            --  AND B.CCM_CUST_ID = 112590350 --108088146 --112590350 --performance changes
         AND b.ccm_cust_code = l_cust_code --performance changes
         AND b.ccm_inst_code = 1
		     AND e.cap_pan_code = p.vpc_pan_code(+);
      -- AND b.ccm_partner_id IN (1); --performance changes

--Get the description from master table

    --SN:Added by FSS
    FOR l_rec IN (SELECT a.vti_token_pan,
                         a.vti_token,
                         a.vti_ins_date,
                         (select vdm_devicetype_desc from vmscms.vms_devicetype_mast where vdm_device_type = a.vti_token_device_type) vti_token_device_type,
                         a.vti_token_device_id,
                         a.vti_token_device_no,
                         a.vti_token_device_name,
                         a.vti_token_device_loc,
                         a.vti_token_device_ip,
                         a.vti_token_expiry_date,
                         (select vtm_tokentype_desc from vmscms.vms_tokentype_mast where vtm_token_type = a.vti_token_type) vti_token_type,
                         a.vti_token_stat,
                         (select vwm_wallet_name from vmscms.vms_wallet_mast where vwm_wallet_id =nvl(a.vti_wallet_identifier,
                                                                                                  a.vti_token_requestor_id)) wallet,
                         a.vti_token_device_langcode,
			                   a.vti_token_device_secureeleid  --added for VMS-447(Token and Device details)
                    FROM vmscms.vms_token_info a
                   WHERE a.vti_token_type NOT IN
                         ('CF',
                          '01')
                     AND a.vti_token_stat <> 'D'
                     AND EXISTS
                   (SELECT 1
                            FROM vmscms.cms_appl_pan b
                           WHERE b.cap_pan_code = a.vti_token_pan
                             AND b.cap_cust_code = l_cust_code))
    LOOP

      l_token_tab.extend;

      l_token_tab(l_token_tab.last) := vmscms.account_detail_token_typ_t(l_rec.vti_token_pan,
                                                                         l_rec.vti_token,
                                                                         l_rec.vti_ins_date,
                                                                         l_rec.vti_token_device_type,--g_device_type_tab(l_rec.vti_token_device_type),
                                                                         --NULL,
                                                                         l_rec.vti_token_device_id,
                                                                         l_rec.vti_token_device_no,
                                                                         l_rec.vti_token_device_name,
                                                                         l_rec.vti_token_device_loc,
                                                                         l_rec.vti_token_device_ip,
                                                                         l_rec.vti_token_expiry_date,
                                                                         l_rec.vti_token_type,--g_token_type_tab(l_rec.vti_token_type),
                                                                         --NULL,
                                                                         g_token_status_tab(l_rec.vti_token_stat),
                                                                         l_rec.wallet,
                                                                         l_rec.vti_token_device_langcode,
                                                                         l_rec.vti_token_device_secureeleid); --added for VMS-447(Token and Device details)

 --Commandad since we get the description from master table

  /*    IF g_device_type_tab.exists(l_rec.vti_token_device_type)
      THEN
        l_token_tab(l_token_tab.last).device_type := g_device_type_tab(l_rec.vti_token_device_type);
      ELSE
        l_token_tab(l_token_tab.last).device_type := 'Unknown';
      END IF;

      IF g_token_type_tab.exists(l_rec.vti_token_type)
      THEN
        l_token_tab(l_token_tab.last).token_type := g_token_type_tab(l_rec.vti_token_type);
      ELSE
        l_token_tab(l_token_tab.last).token_type := 'Unknown';
      END IF;*/

    END LOOP;
    print('token details populted');
    --EN:Added by FSS

    -- Cards and fee array
     OPEN c_cardfee_detail_out FOR
      SELECT  --a.cap_mask_pan pan,
            vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(a.cap_pan_code_encr)) pan,
             f.ccs_stat_desc card_status,
             to_char(a.cap_active_date,
                 'yyyy-mm-dd') activation_date,
             to_char(a.cap_expry_date,
                 'yyyy-mm-dd') expiry_date,
             c.cpc_cardtype_desc product_category_desc,
             e.ccm_status_desc shipped_status,
             'Incomm' institution,
             vmscms.fn_get_feeplan('1',
                         vmscms.fn_dmaps_main(cap_pan_code_encr)) fee_plan_details,
             /* CFIP 377 to use nvl2 instead of case
             (CASE
              WHEN vmscms.gpp_feeplan.get_fee_plan(a.cap_pan_code,
                                 a.cap_prod_code,
                                 a.cap_card_type) IS NOT NULL THEN
               'TRUE'
              ELSE
               'FALSE'
             END) is_active_plan,*/
             nvl2(vmscms.gpp_feeplan.get_fee_plan(a.cap_pan_code,
                                a.cap_prod_code,
                                a.cap_card_type),
                'TRUE',
                'FALSE') is_active_plan,
             cfp_plan_desc plan_name,
             addressverification.status address_verification_status,
             addressverification.code md_responsecode,
             addressverification.cam_long_desp md_responsedesc,
             a.cap_serial_number serial_number, -- CFIP-261 to include serial number account details
      --             a.cap_panmast_param2 parent_serial_number,
             nvl2(a.cap_pin_off,
                'TRUE',
                'FALSE') ispinset, -- CFIP 377 to check whether pin is set for a card
             (decode(a.cap_startercard_flag,
                 'Y',
                 'TRUE',
                 'N',
                 'FALSE',
                 'FALSE')) AS isstartercard, -- CFIP 394                ,
             --l_proxy_no AS proxynumber, --JIRA CFIP-356
             --a.cam_appl_code  --performance changes
             a.cap_card_id "CardID", -- CFIP-406
             nvl((SELECT cpc_card_details
                FROM vmscms.cms_prod_cardpack
                WHERE cpc_prod_code = a.cap_prod_code
                AND cpc_card_id =a.cap_cardpack_id),cpc_package_id) packageId,
             (SELECT VPM_PACKAGE_DESC
              FROM vmscms.vms_packageid_mast
               WHERE VPM_PACKAGE_ID =
                nvl((SELECT cpc_card_details
                FROM vmscms.cms_prod_cardpack
                WHERE cpc_prod_code = a.cap_prod_code
                AND cpc_card_id =a.cap_cardpack_id),cpc_package_id)) packageDescription,
             --Sn Added by FSS for VMS-78
             cap_merchant_id merchantId,
             cap_merchant_name merchantName,
             cap_store_id storeId,
             cap_terminal_id terminalId,
             order_detail.vli_order_id orderId,
             cap_ip_address ipAddress,
             cap_url url,
			 --En Added by FSS for VMS-78
			 --Sn Added for VMS-888
             (
              CASE
              WHEN order_detail.vli_pan_code IS NOT NULL
              THEN
                'B2B'
              ELSE
                'RETAIL'
              END) orderType,
             (
              CASE
              WHEN upper(order_detail.vod_print_order) = 'TRUE'
              THEN
                order_detail.vli_po_tracking_no
              ELSE
                order_detail.vli_tracking_no
              END) trackingNumber,
              order_detail.vli_po_fulfillment_order_id fulfillmentOrderId,
              upper(nvl(order_detail.vod_print_order,'FALSE')) isPrintOrder,
              (SELECT vpi_order_channel
               FROM vmscms.vms_partner_id_mast
               WHERE vpi_partner_id = order_detail.vli_partner_id
              ) orderChannel,	---- Modified for VMS-1057 - VMS Gift: Card Replacement Tracking.
			  (decode(NVL(a.CAP_REPL_FLAG,'0'),'0','FALSE','TRUE')) AS isReplacementCard,
				to_char(order_detail.vod_ins_date,'yyyy-mm-dd') as OrderDate,
				order_detail.vod_order_status as Orderstatus,
				to_char(order_detail.vli_shipping_datetime,'yyyy-mm-dd HH24:MI:SS') as Shippingdateandtimeinfo,
				vmscms.fn_dmaps_main(order_detail.VOD_FIRSTNAME) as firstname,
                vmscms.fn_dmaps_main(order_detail.VOD_LASTNAME)as lastname,
				vmscms.fn_dmaps_main(order_detail.VOD_ADDRESS_LINE1) as Address1,
				vmscms.fn_dmaps_main(order_detail.VOD_ADDRESS_LINE2) as Address2,
				vmscms.fn_dmaps_main(order_detail.vod_city) as city,
				order_detail.vod_state as state,
                vmscms.fn_dmaps_main(order_detail.vod_postalcode) as postalcode,
				order_detail.vod_country as countrycode,
				 --En Added for VMS-888
              --SN:Added by FSS
             CURSOR (SELECT token,
                    token_provision_date,
                    device_type,
                    device_id,
                    device_number,
                    device_name,
                    device_location,
                    device_ip,
                    token_expiry,
                    token_type,
                    token_status,
                    wallet,
                    devicelanguage,
                    se_id     --added for VMS-447(Token and Device details)
                   FROM TABLE(l_token_tab) tab
                  WHERE tab.pan = a.cap_pan_code) token_dtls,
          --EN:Added by FSS
           --Sn Added by FSS for VMS-78
            (SELECT cpb_inst_bin
               FROM vmscms.cms_prod_bin
              WHERE cpb_inst_code = c.cpc_inst_code
                AND cpb_prod_code =
                     CASE
                      WHEN c.cpc_renew_replace_option= 'NPP'
                      THEN
                       c.cpc_renew_replace_prodcode
                      ELSE
                       c.cpc_prod_code
                     END) replacementCardBin,
                     (CASE
                      WHEN a.cap_card_stat = '17'
                      THEN
                (SELECT * FROM (SELECT reason
                        FROM vmscms.transactionlog,vmscms.cms_appl_pan
                        WHERE instcode = 1
                AND cap_inst_code = 1
                        AND customer_card_no = cap_pan_code
                AND cap_cust_code = l_cust_code
                        AND delivery_channel = '05'
                        AND txn_code = '49'
                        AND response_code = '00' order by add_ins_date desc) WHERE ROWNUM = 1)
                      ELSE
                 null
              END) statusReason
             --En Added by FSS for VMS-78
          FROM vmscms.cms_appl_pan a,
             --  vmscms.cms_cust_mast b, --performance changes
             vmscms.cms_prod_cattype c,
             vmscms.cms_cardissuance_status d,
             vmscms.cms_cardissuance_status_mast e,
             vmscms.cms_card_stat f,
             vmscms.cms_fee_plan g,
			 --Sn Added for VMS-888
				 (SELECT vli_pan_code ,
					vod_print_order,
					vli_tracking_no,
					vli_po_tracking_no,
					vli_po_fulfillment_order_id,
					vli_partner_id,
					vli_order_id,
					vli_shipping_datetime,
					vod_order_status,
					vod_ins_date,
					vod_city,
					vod_state,
					vod_postalcode,
					VOD_ADDRESS_LINE1,
					VOD_ADDRESS_LINE2,
					VOD_FIRSTNAME,
					VOD_LASTNAME,
					vod_country
				  FROM vmscms.cms_appl_pan j,
					vmscms.vms_line_item_dtl h,
					vmscms.vms_order_details i
				  WHERE j.cap_cust_code = l_cust_code
				  AND j.cap_pan_code    = h.vli_pan_code
				  AND i.vod_order_id    = h.vli_order_id
				  AND i.vod_partner_id  = h.vli_partner_id
				---  AND h.vli_partner_id <>'Replace_Partner_ID'  	---- Modified for VMS-1057 - VMS Gift: Card Replacement Tracking.
              ) order_detail,
			  --En Added for VMS-888
             (SELECT *
              FROM (SELECT cas_avqstat_id,
                     cas_pan_code,
                     decode(cas_avq_flag,
                        'P',
                        'Pending',
                        'O',
                        'Override',
                        'S',
                        'Success',
                        'Failed') status,
                     cam_long_desp,
                     substr(cas_avq_resp_msg,
                        0,
                        4) code
                  FROM vmscms.cms_avq_status, vmscms.cms_avqres_mast
                   WHERE substr(cas_avq_resp_msg,
                        0,
                        4) = cam_resp_code
                   AND cas_inst_code = cam_inst_code --performance changes
                   AND cas_cust_id = p_customer_id_in --performance changes
                   AND cas_inst_code = 1 --performance changes
                   ORDER BY cas_avqstat_id DESC)
               WHERE rownum = 1) addressverification --performance changes
           WHERE --a.cap_cust_code = b.ccm_cust_code  --performance changes
          -- and a.cap_inst_code = b.ccm_inst_code --performance changes
           a.cap_cust_code = l_cust_code
       AND a.cap_inst_code = 1
           AND a.cap_prod_code = c.cpc_prod_code
           AND a.cap_card_type = c.cpc_card_type
           AND a.cap_inst_code = c.cpc_inst_code --performance changes
           AND a.cap_pan_code = d.ccs_pan_code
           AND a.cap_inst_code = d.ccs_inst_code --performance changes
           AND d.ccs_card_status = e.ccm_status_code
           AND d.ccs_inst_code = e.ccm_inst_code --performance changes
           AND a.cap_card_stat = f.ccs_stat_code
           AND a.cap_inst_code = f.ccs_inst_code --performance changes
           AND a.cap_pan_code = addressverification.cas_pan_code(+)
          --   AND substr(vmscms.fn_get_feeplan('1',    --performance changes
          --                               vmscms.fn_dmaps_main(a.cap_pan_code_encr)),  --performance changes
          --       1,  --performance changes
          --      instr(vmscms.fn_get_feeplan('1',  --performance changes
          --                                 vmscms.fn_dmaps_main(a.cap_pan_code_encr)), --performance changes
          --          '|') - 1) = cfp_plan_id;  --performance changes
           AND vmscms.gpp_feeplan.get_fee_plan(a.cap_pan_code,
                           a.cap_prod_code,
                           a.cap_card_type) = cfp_plan_id(+)
           AND a.cap_pan_code = order_detail.vli_pan_code(+);  -- Added for VMS-888

    OPEN c_limits_detail_out FOR
      SELECT a.cap_prfl_code id, b.clm_lmtprfl_name groupname
        FROM vmscms.cms_appl_pan a, vmscms.cms_lmtprfl_mast b
       WHERE a.cap_prfl_code = b.clm_lmtprfl_id
         AND cap_pan_code = l_hash_pan;

    print('c_limits_detail displayed');

    OPEN c_doc_detail_out FOR
      SELECT a.cfu_file_type file_type,
             a.cfu_ins_date file_date,
             substr(a.cfu_file_path,
                    -instr(REVERSE(a.cfu_file_path),
                           '/') + 1) file_name --Jira issue CFIP:213
        FROM vmscms.cms_fileupload_detl a
       WHERE a.cfu_upload_stat = 'C'
         AND a.cfu_acct_no = l_acct_no --performance changes
         AND a.cfu_inst_code = 1; --performance changes

    print('c_doc details displayed');


    OPEN c_multipack_card_out FOR
      SELECT cap_serial_number serialNumber,
             cap_mask_pan PAN
        FROM vmscms.cms_appl_pan
       WHERE cap_panmast_param2 IN (SELECT cap_panmast_param2
                                      FROM vmscms.cms_appl_pan
                                     WHERE cap_acct_no = l_acct_no
                                       AND cap_inst_code = 1);


    -- Tokens Array
    --OPEN c_token_detail_out FOR
    --SN:Commented by Fss
    /*FOR l_rec IN (SELECT a.vti_token,
                         a.vti_ins_date,
                         a.vti_token_device_type,
                         a.vti_token_device_id,
                         a.vti_token_device_no,
                         a.vti_token_device_name,
                         a.vti_token_device_loc,
                         a.vti_token_device_ip,
                         a.vti_token_expiry_date,
                         a.vti_token_type,
                         a.vti_token_stat,
                         vmscms.gpp_accounts.get_wallet_id(a.vti_wallet_identifier,
                                                           a.vti_token_requestor_id) wallet,
                         a.vti_token_device_langcode
                    FROM vmscms.vms_token_info a
                   WHERE a.vti_token_type NOT IN
                         ('CF',
                          '01')
                     AND a.vti_token_stat <> 'D'
                     AND EXISTS
                   (SELECT 1
                            FROM vmscms.cms_appl_pan b
                           WHERE b.cap_pan_code = a.vti_token_pan
                             AND b.cap_cust_code = l_cust_code))
    LOOP
      l_token_tab.extend(1);
      l_token_tab(1) := vmscms.account_detail_token_typ_t(l_rec.vti_token,
                                                          l_rec.vti_ins_date,
                                                          g_device_type_tab(l_rec.vti_token_device_type),
                                                          l_rec.vti_token_device_id,
                                                          l_rec.vti_token_device_no,
                                                          l_rec.vti_token_device_name,
                                                          l_rec.vti_token_device_loc,
                                                          l_rec.vti_token_device_ip,
                                                          l_rec.vti_token_expiry_date,
                                                          g_token_type_tab(l_rec.vti_token_type),
                                                          g_token_status_tab(l_rec.vti_token_stat),
                                                          l_rec.wallet,
                                                          l_rec.vti_token_device_langcode);
    END LOOP;
    print('after for loop');
    OPEN c_token_detail_out FOR
      SELECT * FROM TABLE(l_token_tab);

    print('token details displayed');*/
    --EN:Commented by Fss

    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 p_customer_id_in,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C',
                                                 'SUCCESS',
                                                 vmscms.gpp_const.c_success_res_id,
                                                 NULL,
                                                 l_timetaken);*/

  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

  END get_account_details;

  -- To get the account limits
  PROCEDURE get_account_limits(p_customer_id_in     IN VARCHAR2,
                               p_status_out         OUT VARCHAR2,
                               p_err_msg_out        OUT VARCHAR2,
                               c_account_limits_out OUT SYS_REFCURSOR) AS
    l_api_name   VARCHAR2(20) := 'GET ACCOUNT LIMITS';
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;
    --performance change
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no      vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;

  BEGIN
    l_start_time := dbms_utility.get_time;
    --Fetching the active PAN for the input customer id
    --vmscms.gpp_pan.get_pan_details(p_customer_id_in,   --performance change
    --  l_hash_pan,         --performance change
    --  l_encr_pan);        --performance change

    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_cust_code,
                                   l_prod_code,
                                   l_card_type,
                                   l_proxy_no,
                                   l_cardstat,
                                   l_acct_no,
                                   l_masked_pan,
                                   l_profile_code);
    -- Account limits array
    OPEN c_account_limits_out FOR
      SELECT *
        FROM (SELECT DISTINCT c.cgm_limitgl_name,
                               b.cgl_group_code,
                               to_char(nvl(b.cgl_pertxn_minamnt,
                                           0),
                                       '9,999,999,990.99') cgl_pertxn_minamnt,
                               to_char(nvl(b.cgl_pertxn_maxamnt,
                                           0),
                                       '9,999,999,990.99') cgl_pertxn_maxamnt,
                               to_char(nvl(b.cgl_dmax_txnamnt,
                                           0),
                                       '9,999,999,990.99') cgl_dmax_txnamnt,
                               to_char(nvl(b.cgl_wmax_txnamnt,
                                           0),
                                       '9,999,999,990.99') cgl_wmax_txnamnt,
                               to_char(nvl(b.cgl_mmax_txnamnt,
                                           0),
                                       '9,999,999,990.99') cgl_mmax_txnamnt,
                               to_char(nvl(b.cgl_ymax_txnamnt,
                                           0),
                                       '9,999,999,990.99') cgl_ymax_txnamnt,
                               b.cgl_dmax_txncnt,
                               b.cgl_wmax_txncnt,
                               b.cgl_mmax_txncnt,
                               b.cgl_ymax_txncnt
                 FROM --  vmscms.cms_appl_pan         a, --performance change
                      vmscms.cms_group_limit      b,
                      vmscms.cms_grplmt_mast      c,
                      vmscms.cms_lmtprfl_mast     d,
                      vmscms.cms_grplmt_param     e,
                      vmscms.cms_delchannel_mast  f,
                      vmscms.cms_transaction_mast g
                WHERE d.clm_lmtprfl_id = l_profile_code --performance change
                  AND d.clm_inst_code = 1
                     -- a.cap_pan_code = l_hash_pan)   --performance change
                     --   AND a.cap_prfl_code = d.clm_lmtprfl_id  --performance change
                  AND b.cgl_group_code = c.cgm_limitgl_code
                     --    and b.cgl_inst_code = c.cgm_inst_code --performance change
                  AND d.clm_lmtprfl_id = b.cgl_lmtprfl_id
                  AND d.clm_inst_code = b.cgl_inst_code --performance change
                  AND e.cgp_group_code = b.cgl_group_code
                  AND e.cgp_inst_code = b.cgl_inst_code --performance change
                  AND e.cgp_dlvr_chnl = f.cdm_channel_code
                     --   and e.cgp_inst_code = f.cdm_inst_code --performance change
                  AND e.cgp_dlvr_chnl = g.ctm_delivery_channel
                     --   and e.cgp_inst_code = g.ctm_inst_code  --performance change
                  AND f.cdm_channel_code = g.ctm_delivery_channel
                     --   and f.cdm_inst_code = g.ctm_inst_code --performance change
                  AND e.cgp_tran_code = g.ctm_tran_code
                  AND e.cgp_inst_code = g.ctm_inst_code --performance change
                  AND d.clm_active_flag = 'Y'
               UNION
               SELECT e.cdm_channel_desc || ' - Transaction Limit - ' ||
                      d.ctm_tran_desc || ' - ' || (CASE
                        WHEN c.clp_dlvr_chnl = '02' THEN
                         (CASE
                           WHEN c.clp_intl_flag = '0' THEN
                            'Domestic'
                           WHEN c.clp_intl_flag = '1' THEN
                            'International'
                         END) || '-' || (CASE
                           WHEN c.clp_pnsign_flag = 'P' THEN
                            'PIN'
                           WHEN c.clp_pnsign_flag = 'S' THEN
                            'Signature'
                           WHEN clp_pnsign_flag = 'A' THEN
                            'All'
                         END) || '-' || (CASE
                           WHEN c.clp_mcc_code = 'NA' THEN
                            'MCC(NA)'
                           ELSE
                            'MCC(' || c.clp_mcc_code || ')'
                         END)
                        WHEN c.clp_dlvr_chnl = '01' THEN
                         (CASE
                           WHEN c.clp_intl_flag = '0' THEN
                            'Domestic'
                           WHEN c.clp_intl_flag = '1' THEN
                            'International'
                         END)
                      END) AS heading,
                      b.clm_lmtprfl_id,
                      to_char(nvl(c.clp_pertxn_minamnt,
                                  0),
                              '9,999,999,990.99') clp_pertxn_minamnt,
                      to_char(nvl(c.clp_pertxn_maxamnt,
                                  0),
                              '9,999,999,990.99') clp_pertxn_maxamnt,
                      to_char(nvl(c.clp_dmax_txnamnt,
                                  0),
                              '9,999,999,990.99') clp_dmax_txnamnt,

                      to_char(nvl(c.clp_wmax_txnamnt,
                                  0),
                              '9,999,999,990.99') clp_wmax_txnamnt,
                      to_char(nvl(c.clp_mmax_txnamnt,
                                  0),
                              '9,999,999,990.99') clp_mmax_txnamnt,
                      to_char(nvl(c.clp_ymax_txnamnt,
                                  0),
                              '9,999,999,990.99') clp_ymax_txnamnt,
                      c.clp_dmax_txncnt,
                      c.clp_wmax_txncnt,
                      c.clp_mmax_txncnt,
                      c.clp_ymax_txncnt
                 FROM --vmscms.cms_appl_pan         a, --performance change
                      vmscms.cms_lmtprfl_mast     b,
                      vmscms.cms_limit_prfl       c,
                      vmscms.cms_transaction_mast d,
                      vmscms.cms_delchannel_mast  e
                WHERE --cap_pan_code = l_hash_pan --performance change
               --AND a.cap_prfl_code = b.clm_lmtprfl_id --performance change
                b.clm_lmtprfl_id = l_profile_code --performance change
             AND b.clm_inst_code = 1 --performance change
             AND d.ctm_tran_code = c.clp_tran_code
               --  and d.ctm_inst_code = c.clp_inst_code --performance change
             AND c.clp_lmtprfl_id = b.clm_lmtprfl_id
               --  and c.clp_inst_code = b.clm_inst_code --performance change
             AND d.ctm_delivery_channel = c.clp_dlvr_chnl
               --   and d.ctm_inst_code = c.clp_inst_code --performance change
             AND d.ctm_delivery_channel = e.cdm_channel_code
               -- and d.ctm_inst_code = e.cdm_inst_code --performance change
             AND b.clm_active_flag = 'Y') f
       ORDER BY f.cgl_group_code;

    p_status_out := vmscms.gpp_const.c_success_status;
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                 p_customer_id_in,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C',
                                                 'SUCCESS',
                                                 vmscms.gpp_const.c_success_res_id,
                                                 NULL,
                                                 l_timetaken);*/

    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
  END get_account_limits;

  --Get Direct Deposit Form API
  --status: 0 - success, Non Zero value - failure
  PROCEDURE get_directdeposit_form(p_customer_id_in    IN VARCHAR2,
                                   p_status_out        OUT VARCHAR2,
                                   p_err_msg_out       OUT VARCHAR2,
                                   c_directdeposit_out OUT SYS_REFCURSOR) AS
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_api_name   VARCHAR2(30) := 'GET DIRECT DEPOSIT FORM';
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;
    --performance change
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no      vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;

    -- delivery channel and tran code
    l_delivery_channel vmscms.cms_transaction_mast.ctm_delivery_channel%TYPE;
    l_tran_code        vmscms.cms_transaction_mast.ctm_tran_code%TYPE;

/****************************************************************************
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002

	 * Modified By                  : Ubaidur Rahman.H
 	 * Modified Date                : 26-NOV-2021
	 * Modified Reason              : VMS-5253 - Do not pass system Generated Profile from VMS to CCA
	 * Build Number                 : R55 B3
	 * Reviewer                     : Saravanakumar A.
	 * Reviewed Date                : 26-Nov-2021

****************************************************************************/

  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));

    l_delivery_channel := '03';
    l_tran_code        := '33';
    --Fetching the active PAN for the input customer id
    --performance change
    -- vmscms.gpp_pan.get_pan_details(p_customer_id_in,
    --         l_hash_pan,
    --        l_encr_pan);

    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_cust_code,
                                   l_prod_code,
                                   l_card_type,
                                   l_proxy_no,
                                   l_cardstat,
                                   l_acct_no,
                                   l_masked_pan,
                                   l_profile_code);

    OPEN c_directdeposit_out FOR
      SELECT --ccm_first_name firstname,
             --ccm_mid_name   middlename,
             -- ccm_last_name  lastname,
			       decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(ccm_first_name),ccm_first_name) firstname,
			       decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(ccm_mid_name),ccm_mid_name) middlename,
			       decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(ccm_last_name),ccm_last_name) lastname,
             --Physical addr
             CASE physical_addr.cam_addr_flag
               WHEN 'P' THEN
                'PHYSICAL'
             END address_type1,
              -- physical_addr.cam_add_one physical_address1,
              -- physical_addr.cam_add_two physical_address2,
              --  physical_addr.cam_city_name physical_city,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_add_one),physical_addr.cam_add_one)) physical_address1,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_add_two),physical_addr.cam_add_two)) physical_address2,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_city_name),physical_addr.cam_city_name)) physical_city,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT upper(gsm_switch_state_code)
                FROM vmscms.gen_state_mast
               WHERE gsm_inst_code = physical_addr.cam_inst_code
                 AND gsm_state_code = physical_addr.cam_state_code
                 AND gsm_cntry_code = physical_addr.cam_cntry_code)) physical_state,
   --          physical_addr.cam_pin_code physical_zip,
			  decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', VMSCMS.fn_dmaps_main(physical_addr.cam_pin_code),physical_addr.cam_pin_code)) physical_zip,
             --Mailing addr
             CASE mailing_addr.cam_addr_flag
               WHEN 'O' THEN
                'MAILING'
             END address_type2,
             --  mailing_addr.cam_add_one mailing_address1,
             --  mailing_addr.cam_add_two mailing_address2,
             --  mailing_addr.cam_city_name mailing_city,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_add_one),mailing_addr.cam_add_one)) mailing_address1,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_add_two),mailing_addr.cam_add_two)) mailing_address2,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_city_name),mailing_addr.cam_city_name)) mailing_city,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT upper(gsm_switch_state_code)
                FROM gen_state_mast
               WHERE gsm_inst_code = mailing_addr.cam_inst_code
                 AND gsm_state_code = mailing_addr.cam_state_code
                 AND gsm_cntry_code = mailing_addr.cam_cntry_code)) mailing_state,
  --           mailing_addr.cam_pin_code mailing_zip,
	      		 decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', VMSCMS.fn_dmaps_main(mailing_addr.cam_pin_code),mailing_addr.cam_pin_code)) mailing_zip,
             --  cap_acct_no accountnumber,  --performance change
             l_acct_no          accountnumber, --performance change
             nvl (cpc_rout_num, cpc_institution_id
                        ||'-'
                        || cpc_transit_number)       routing_number,
             cpc_institution_id institution_id,
             cpc_transit_number transit_number,
             -- cap_proxy_number proxy_number  --performance change
             l_proxy_no proxy_number --performance change
        FROM --vmscms.cms_appl_pan  a,  --performance change
             vmscms.cms_cust_mast,
             vmscms.cms_addr_mast physical_addr,
             cms_addr_mast        mailing_addr,
             --vmscms.cms_prod_mast,
             vmscms.cms_prod_cattype
       WHERE
      --cap_inst_code = ccm_inst_code  --performance change
       ccm_cust_code = l_cust_code --performance change
       AND ccm_inst_code = 1
       AND cpc_prod_code = l_prod_code
       AND cpc_card_type = l_card_type
       AND cpc_inst_code = ccm_inst_code
       AND ccm_cust_code = physical_addr.cam_cust_code
       AND ccm_inst_code = physical_addr.cam_inst_code
       AND physical_addr.cam_addr_flag = 'P'
       AND ccm_cust_code = mailing_addr.cam_cust_code(+)
       AND ccm_inst_code = mailing_addr.cam_inst_code(+)
       AND mailing_addr.cam_addr_flag(+) = 'O';

    -- AND cap_prod_code = cpm_prod_code  --performance change
    --    AND cap_inst_code = cpm_inst_code   --performance change
    -- AND ccm_partner_id IN (l_partner_id)  --performance change
    -- AND cap_pan_code = l_hash_pan;  --performance change

    p_status_out := vmscms.gpp_const.c_success_status;
    -- CFIP 374 commented to call new audit transaction log for storing
    -- tran code and delivery channel

   /* vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 p_customer_id_in,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C', --vmscms.gpp_const.c_success_flag,
                                                 'SUCCESS', --vmscms.gpp_const.c_success_msg,
                                                 vmscms.gpp_const.c_success_res_id,
                                                 NULL,
                                                 l_timetaken); */--Remarks
    /*
    -- CFIP 374, calling transaction log with trancode and del channel
    vmscms.clputil.audit_transaction_log(l_api_name,
                                         p_customer_id_in,
                                         l_hash_pan,
                                         l_encr_pan,
                                         'C',
                                         'SUCCESS',
                                         vmscms.gpp_const.c_success_res_id,
                                         NULL,
                                         l_timetaken,
                                         l_delivery_channel,
                                         l_tran_code);
    */
    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
  END get_directdeposit_form;

  --Procedure to fetch savings account details
  PROCEDURE fetch_savingacctdetl(p_inst_code_in         IN NUMBER,
                                 p_month_year_in        IN VARCHAR2,
                                 p_svg_acct_no_in       IN VARCHAR2,
                                 p_err_msg_out          OUT VARCHAR2,
                                 p_interest_rate_out    OUT VARCHAR2,
                                 p_interest_paid_out    OUT VARCHAR2,
                                 p_interest_accrued_out OUT VARCHAR2,
                                 p_percentage_yield_out OUT VARCHAR2,
                                 p_begining_bal_out     OUT VARCHAR2,
                                 p_ending_bal_out       OUT VARCHAR2) AS
    exp_reject_record EXCEPTION;
    start_date       VARCHAR2(8);
    v_month          VARCHAR2(2);
    v_year           VARCHAR2(4);
    v_firstday_month DATE;
    v_lastdate_month DATE;
    v_business_date  VARCHAR2(8);
  BEGIN

    BEGIN
      start_date := '01' || p_month_year_in;
    EXCEPTION
      WHEN OTHERS THEN
        p_err_msg_out := 'Problem while formatting  start_date' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
    BEGIN
      SELECT to_date(start_date,
                     'DDMMYYYY'),
             last_day(to_date(start_date,
                              'DDMMYYYY'))
        INTO v_firstday_month, v_lastdate_month
        FROM dual;

    EXCEPTION
      WHEN OTHERS THEN
        p_err_msg_out := 'Problem while  converting  month year' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
    BEGIN
      SELECT cid_interest_rate
        INTO p_interest_rate_out
        FROM vmscms.cms_interest_detl a
       WHERE a.cid_acct_no = p_svg_acct_no_in
         AND cid_inst_code = p_inst_code_in
         AND a.cid_calc_date =
             (SELECT MAX(b.cid_calc_date)
                FROM vmscms.cms_interest_detl b
               WHERE b.cid_acct_no = p_svg_acct_no_in
                 AND cid_inst_code = p_inst_code_in
                 AND to_char(cid_calc_date,
                             'MMYYYY') = p_month_year_in);
    EXCEPTION
      WHEN no_data_found THEN
        BEGIN
          SELECT cid_interest_rate
            INTO p_interest_rate_out
            FROM vmscms.cms_interest_detl_hist a
           WHERE a.cid_acct_no = p_svg_acct_no_in
             AND cid_inst_code = p_inst_code_in
             AND a.cid_calc_date =
                 (SELECT MAX(b.cid_calc_date)
                    FROM vmscms.cms_interest_detl_hist b
                   WHERE b.cid_acct_no = p_svg_acct_no_in
                     AND cid_inst_code = p_inst_code_in
                     AND to_char(cid_calc_date,
                                 'MMYYYY') = p_month_year_in);
        EXCEPTION
          WHEN no_data_found THEN
            p_interest_rate_out := '0.00';
          WHEN OTHERS THEN
            p_err_msg_out := 'Error while selecting interest detl hist ...' ||
                             substr(SQLERRM,
                                    1,
                                    200);
            RAISE exp_reject_record;
        END;
      WHEN OTHERS THEN
        p_err_msg_out := 'Error while selecting interest detl ...' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
    BEGIN
      SELECT round((power(1 +
                          (round(SUM(cid_interest_amount),
                                 2) /
                          trunc(AVG((cid_close_balance +
                                     (SELECT nvl(SUM(cid_qtly_interest_accr),
                                                  0)
                                         FROM vmscms.cms_interest_detl
                                        WHERE cid_acct_no = p_svg_acct_no_in
                                          AND cid_inst_code = p_inst_code_in
                                          AND trunc(cid_calc_date) =
                                              last_day(v_firstday_month - 1))) -
                                     cid_interest_amount) *
                                 (trunc(MAX(cid_calc_date) -
                                        MIN(cid_calc_date) + 1) /
                                  to_char(last_day(MAX(cid_calc_date)),
                                          'dd')),
                                 2)),
                          (365 / to_char(last_day(MAX(cid_calc_date)),
                                         'dd'))) - 1) * 100,
                   2)
        INTO p_percentage_yield_out
        FROM vmscms.cms_interest_detl
       WHERE cid_acct_no = p_svg_acct_no_in
         AND cid_inst_code = p_inst_code_in
         AND trunc(cid_calc_date) BETWEEN v_firstday_month AND
             v_lastdate_month;
      IF p_percentage_yield_out IS NULL
      THEN
        SELECT round((power(1 +
                            (round(SUM(cid_interest_amount),
                                   2) / trunc(AVG((cid_close_balance +
                                                   (SELECT nvl(SUM(cid_qtly_interest_accr),
                                                                0)
                                                       FROM vmscms.cms_interest_detl_hist
                                                      WHERE cid_acct_no =
                                                            p_svg_acct_no_in
                                                        AND cid_inst_code =
                                                            p_inst_code_in
                                                        AND trunc(cid_calc_date) =
                                                            last_day(v_firstday_month - 1)
                                                        AND to_char(last_day(v_firstday_month - 1),
                                                                    'MMDD') NOT IN
                                                            ('0331',
                                                             '0630',
                                                             '0930',
                                                             '1231'))) -
                                                   cid_interest_amount) *
                                               (trunc(MAX(cid_calc_date) -
                                                      MIN(cid_calc_date) + 1) /
                                                to_char(last_day(MAX(cid_calc_date)),
                                                        'dd')),
                                               2)),
                            (365 / to_char(last_day(MAX(cid_calc_date)),
                                           'dd'))) - 1) * 100,
                     2)
          INTO p_percentage_yield_out
          FROM vmscms.cms_interest_detl_hist
         WHERE cid_acct_no = p_svg_acct_no_in
           AND cid_inst_code = p_inst_code_in
           AND trunc(cid_calc_date) BETWEEN v_firstday_month AND
               v_lastdate_month;
        IF p_percentage_yield_out IS NULL
        THEN
          p_percentage_yield_out := '0.00';
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        p_err_msg_out := 'Error while selecting percentage yield from interest detl and hist ...' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
    BEGIN
      v_month := substr(TRIM(p_month_year_in),
                        1,
                        2);
      v_year  := substr(TRIM(p_month_year_in),
                        3,
                        6);
    EXCEPTION
      WHEN OTHERS THEN
        p_err_msg_out := 'Problem while   substring   month_year ' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
    IF v_month IN ('03',
                   '12')
    THEN
      v_business_date := v_year || v_month || '31';
    ELSIF v_month IN ('06',
                      '09')
    THEN
      v_business_date := v_year || v_month || '30';
    END IF;
    IF v_month IN ('03',
                   '06',
                   '09',
                   '12')
    THEN
      BEGIN
        SELECT csl_trans_amount
          INTO p_interest_paid_out
          FROM vmscms.cms_statements_log
         WHERE csl_business_date = v_business_date
           AND csl_trans_type = 'CR'
           AND csl_delivery_channel = '05'
           AND csl_txn_code = '13'
           AND csl_acct_no = p_svg_acct_no_in
           AND csl_inst_code = p_inst_code_in;
      EXCEPTION
        WHEN no_data_found THEN
          p_interest_paid_out := '0.00';
        WHEN OTHERS THEN
          p_err_msg_out := 'Error while selecting interest amount from statements...' ||
                           substr(SQLERRM,
                                  1,
                                  200);
          RAISE exp_reject_record;
      END;
    ELSE
      p_interest_paid_out := '0.00';
    END IF;
    BEGIN
      SELECT to_char(nvl(SUM(cid_interest_amount),
                         '0'),
                     '99999999999999990.99')
        INTO p_interest_accrued_out
        FROM vmscms.cms_interest_detl
      --WHERE to_date(cid_calc_date, 'YYYY-MM-DD') BETWEEN
       WHERE trunc(cid_calc_date) BETWEEN --JIRA issue CFIP:81
             v_firstday_month AND v_lastdate_month
         AND cid_acct_no = p_svg_acct_no_in
         AND cid_inst_code = p_inst_code_in;
      IF p_interest_accrued_out = 0.00
      THEN
        BEGIN
          SELECT to_char(nvl(SUM(cid_interest_amount),
                             '0'),
                         '99999999999999990.99')
            INTO p_interest_accrued_out
            FROM vmscms.cms_interest_detl_hist
           WHERE to_date(cid_calc_date,
                         'YYYY-MM-DD') BETWEEN v_firstday_month AND
                 v_lastdate_month
             AND cid_acct_no = p_svg_acct_no_in
             AND cid_inst_code = p_inst_code_in;
        EXCEPTION
          WHEN OTHERS THEN
            p_err_msg_out := 'Error while selecting interest amount from hist ...' ||
                             substr(SQLERRM,
                                    1,
                                    200);
            RAISE exp_reject_record;
        END;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        p_err_msg_out := 'Error while selecting interest amount from interest detl ...' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
    BEGIN
      --fix for jira CFIP:81 starts
      SELECT to_char(nvl(csl_opening_bal,
                         0),
                     '9,999,999,990.99') opening_balance
        INTO p_begining_bal_out
        FROM vmscms.cms_statements_log s1
       WHERE s1.csl_acct_no = p_svg_acct_no_in
         AND s1.csl_inst_code = p_inst_code_in
         AND s1.csl_ins_date =
             (SELECT MIN(s2.csl_ins_date)
                FROM vmscms.cms_statements_log s2
               WHERE s2.csl_acct_no = p_svg_acct_no_in
                 AND s2.csl_inst_code = p_inst_code_in
                 AND to_char(s2.csl_ins_date,
                             'MMYYYY') = p_month_year_in);
      /*SELECT decode(s1.csl_opening_bal,
      0,
      to_char(s1.csl_closing_balance,
      '99999999999999990.99'),
      to_char(s1.csl_opening_bal, '99999999999999990.99'))
      INTO p_begining_bal_out
      FROM vmscms.cms_statements_log s1
      WHERE s1.csl_acct_no = p_svg_acct_no_in
      AND s1.csl_inst_code = p_inst_code_in
      AND s1.csl_ins_date =
      (SELECT MIN(s2.csl_ins_date)
      FROM vmscms.cms_statements_log s2
      WHERE s2.csl_acct_no = p_svg_acct_no_in
      AND s2.csl_inst_code = p_inst_code_in
      AND to_char(s2.csl_trans_date, 'MMYYYY') =
      p_month_year_in)
      AND rownum = 1;*/
      --fix for jira CFIP:81 ends
    EXCEPTION
      WHEN no_data_found THEN
        BEGIN
          SELECT to_char(cid_close_balance - cid_interest_amount,
                         '99999999999999990.99')
            INTO p_begining_bal_out
            FROM vmscms.cms_interest_detl a
           WHERE a.cid_acct_no = p_svg_acct_no_in
             AND cid_inst_code = p_inst_code_in
             AND a.cid_calc_date =
                 (SELECT MIN(b.cid_calc_date)
                    FROM vmscms.cms_interest_detl b
                   WHERE b.cid_acct_no = p_svg_acct_no_in
                     AND cid_inst_code = p_inst_code_in
                     AND to_char(cid_calc_date,
                                 'MMYYYY') = p_month_year_in);
        EXCEPTION
          WHEN no_data_found THEN
            BEGIN
              SELECT to_char(cid_close_balance - cid_interest_amount,
                             '99999999999999990.99')
                INTO p_begining_bal_out
                FROM vmscms.cms_interest_detl_hist a
               WHERE a.cid_acct_no = p_svg_acct_no_in
                 AND cid_inst_code = p_inst_code_in
                 AND a.cid_calc_date =
                     (SELECT MIN(b.cid_calc_date)
                        FROM vmscms.cms_interest_detl_hist b
                       WHERE b.cid_acct_no = p_svg_acct_no_in
                         AND cid_inst_code = p_inst_code_in
                         AND to_char(cid_calc_date,
                                     'MMYYYY') = p_month_year_in);
            EXCEPTION
              WHEN no_data_found THEN
                p_begining_bal_out := '0.00';
              WHEN OTHERS THEN
                p_err_msg_out := 'Error while selecting opening balance from hist ...' ||
                                 substr(SQLERRM,
                                        1,
                                        200);
                RAISE exp_reject_record;
            END;
          WHEN OTHERS THEN
            p_err_msg_out := 'Error while selecting opening balance from interest detl ...' ||
                             substr(SQLERRM,
                                    1,
                                    200);
            RAISE exp_reject_record;
        END;
      WHEN OTHERS THEN
        p_err_msg_out := 'Error while selecting opening balance from stmt sav ...' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
    BEGIN
      --fix for jira CFIP:81 starts
      SELECT to_char(nvl(csl_closing_balance,
                         0),
                     '9,999,999,990.99') closing_balance
        INTO p_ending_bal_out
        FROM vmscms.cms_statements_log s1
       WHERE s1.csl_acct_no = p_svg_acct_no_in
         AND s1.csl_inst_code = p_inst_code_in
         AND s1.csl_ins_date =
             (SELECT MAX(s2.csl_ins_date)
                FROM vmscms.cms_statements_log s2
               WHERE s2.csl_acct_no = p_svg_acct_no_in
                 AND s2.csl_inst_code = p_inst_code_in
                 AND to_char(s2.csl_ins_date,
                             'MMYYYY') = p_month_year_in);
      /* SELECT to_char(s1.csl_closing_balance, '99999999999999990.99')
      INTO p_ending_bal_out
      FROM vmscms.cms_statements_log s1
      WHERE s1.csl_acct_no = p_svg_acct_no_in
      AND s1.csl_inst_code = p_inst_code_in
      AND s1.csl_ins_date =
      (SELECT MAX(s2.csl_ins_date)
      FROM vmscms.cms_statements_log s2
      WHERE s2.csl_acct_no = p_svg_acct_no_in
      AND s2.csl_inst_code = p_inst_code_in
      AND to_char(s2.csl_trans_date, 'MMYYYY') =
      p_month_year_in)
      AND rownum = 1;*/
      --fix for jira CFIP:81 ends
    EXCEPTION
      WHEN no_data_found THEN
        BEGIN
          SELECT to_char(cid_close_balance - cid_interest_amount,
                         '99999999999999990.99')
            INTO p_ending_bal_out
            FROM vmscms.cms_interest_detl a
           WHERE a.cid_acct_no = p_svg_acct_no_in
             AND cid_inst_code = p_inst_code_in
             AND a.cid_calc_date =
                 (SELECT MAX(b.cid_calc_date)
                    FROM vmscms.cms_interest_detl b
                   WHERE b.cid_acct_no = p_svg_acct_no_in
                     AND cid_inst_code = p_inst_code_in
                     AND to_char(cid_calc_date,
                                 'MMYYYY') = p_month_year_in);
        EXCEPTION
          WHEN no_data_found THEN
            BEGIN
              SELECT to_char(cid_close_balance - cid_interest_amount,
                             '99999999999999990.99')
                INTO p_ending_bal_out
                FROM vmscms.cms_interest_detl_hist a
               WHERE a.cid_acct_no = p_svg_acct_no_in
                 AND cid_inst_code = p_inst_code_in
                 AND a.cid_calc_date =
                     (SELECT MAX(b.cid_calc_date)
                        FROM vmscms.cms_interest_detl_hist b
                       WHERE b.cid_acct_no = p_svg_acct_no_in
                         AND cid_inst_code = p_inst_code_in
                         AND to_char(cid_calc_date,
                                     'MMYYYY') = p_month_year_in);
            EXCEPTION
              WHEN no_data_found THEN
                p_ending_bal_out := '0.00';
              WHEN OTHERS THEN
                p_err_msg_out := 'Error while selecting closing balance from acct mast ...' ||
                                 substr(SQLERRM,
                                        1,
                                        200);
                RAISE exp_reject_record;
            END;
          WHEN OTHERS THEN
            p_err_msg_out := 'Error while selecting closing balance from hist  ...' ||
                             substr(SQLERRM,
                                    1,
                                    200);
            RAISE exp_reject_record;
        END;
      WHEN OTHERS THEN
        p_err_msg_out := 'Error while selecting closing balance from interest detl ' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
  EXCEPTION
    WHEN exp_reject_record THEN
      RETURN;
  END fetch_savingacctdetl;

  --Get Account Statement API
  --status: 0 - success, Non Zero value - failure
  PROCEDURE get_account_statement(p_customer_id_in       IN VARCHAR2,
                                  p_acc_type_in          IN OUT VARCHAR2,
                                  p_stmt_type_in         IN VARCHAR2,
                                  p_start_date_in        IN VARCHAR2,
                                  p_end_date_in          IN VARCHAR2,
                                  p_fee_waiver_in        IN VARCHAR2,
                                  p_sortorder_in         IN VARCHAR2,
                                  p_sortelement_in       IN VARCHAR2,
                                  p_recordsperpage_in    IN VARCHAR2,
                                  p_pagenumber_in        IN VARCHAR2,
                                  p_status_out           OUT VARCHAR2,
                                  p_err_msg_out          OUT VARCHAR2,
                                  p_int_accrued_out      OUT VARCHAR2,
                                  p_int_paid_out         OUT VARCHAR2,
                                  p_percent_yield_out    OUT VARCHAR2,
                                  p_int_rate_out         OUT VARCHAR2,
                                  p_open_bal_out         OUT VARCHAR2,
                                  p_close_bal_out        OUT VARCHAR2,
                                  p_total_fee_out        OUT NUMBER,
                                  p_ytd_out              OUT NUMBER,
                                  p_statement_footer_out OUT VARCHAR2,
                                  c_txn_det_out          OUT SYS_REFCURSOR,
                                  c_acc_det_out          OUT SYS_REFCURSOR) AS
    l_hash_pan       vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan       vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_cust_acc_no    VARCHAR2(100);
    l_month_year     VARCHAR2(10);
    l_year_month     VARCHAR2(10);
    l_inst_code      NUMBER;
    l_curr_code      VARCHAR2(50);
    l_field_name     VARCHAR2(50);
    l_recordsperpage PLS_INTEGER;
    l_pagenumber     PLS_INTEGER;
    l_sort_element   VARCHAR2(20);
    l_rec_start_no   PLS_INTEGER;
    l_rec_end_no     PLS_INTEGER;
    l_auth_id        transactionlog.auth_id%TYPE;
    l_resp_cde       VARCHAR2(3);
    l_capture_date   DATE;
    l_date           VARCHAR2(20);
    l_time           VARCHAR2(20);
    l_api_name       VARCHAR2(30) := 'GET ACCOUNT STATEMENT';
    l_flag           PLS_INTEGER := 0;
    l_partner_id     vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_rn             PLS_INTEGER;
    l_total_count    PLS_INTEGER;
    l_rrn            VARCHAR2(20);
    l_query          VARCHAR2(32000);
    l_wrapper_query  VARCHAR2(32000);
    l_row_query      VARCHAR2(32000);
    l_order_by       VARCHAR2(500);
    l_sort_order     VARCHAR2(20);
    l_start_time     NUMBER;
    l_end_time       NUMBER;
    l_timetaken      NUMBER;
    --performance changes
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no      vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_acct_type_cd vmscms.cms_acct_mast.cam_type_code%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;
    --performance changes

/***************************************************************************************

    	 * Modified by        : UBAIDUR RAHMAN H
         * Modified Date      : 06-Aug-19
         * Modified For       : VMS-1022.
         * Modified Reason    : CH Statement/Transaction history should not display
                					InComm user's name when manually adjusted.
         * Reviewer           : Saravana Kumar
         * Build Number       : R19_B0001

	 * Modified by        : UBAIDUR RAHMAN H
         * Modified Date      : 22-Mar-2021.
         * Modified For       : VMS-3945.
         * Modified Reason    : GPR Statement Enhancement--Complete ATM Address--CHW and CCA
         * Reviewer           : Saravana Kumar
         * Build Number       : R44_B0001

	 * Modified By                  : Ubaidur Rahman.H
  	 * Modified Date                : 26-NOV-2021
	 * Modified Reason              : VMS-5253 - Do not pass system Generated Profile from VMS to CCA
	 * Build Number                 : R55 B3
	 * Reviewer                     : Saravanakumar A.
	 * Reviewed Date                : 26-Nov-2021

***************************************************************************************/


  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --  l_partner_id := 3;
    --Check for mandatory fields
    CASE
      WHEN p_customer_id_in IS NULL THEN
        l_field_name := 'CUSTOMER ID';
        l_flag       := 1;
      WHEN p_acc_type_in IS NULL THEN
        l_field_name := 'ACCOUNT TYPE';
        l_flag       := 1;
      WHEN p_stmt_type_in IS NULL THEN
        l_field_name := 'STATEMENT TYPE';
        l_flag       := 1;
      WHEN p_start_date_in IS NULL THEN
        l_field_name := 'START DATE';
        l_flag       := 1;
      WHEN p_end_date_in IS NULL THEN
        l_field_name := 'END DATE';
        l_flag       := 1;
      WHEN p_fee_waiver_in IS NULL THEN
        l_field_name := 'IS FEE WAIVED';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;

    IF l_flag = 1
    THEN
      p_status_out := vmscms.gpp_const.c_mandatory_status;
      g_err_mandatory.raise(l_api_name,
                            ',0002,',
                            l_field_name || ' is mandatory');
      p_err_msg_out := g_err_mandatory.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken,
                                                   (CASE WHEN
                                                    p_fee_waiver_in = 'TRUE' THEN 'Y' ELSE 'N' END),
                                                   l_auth_id);
      RETURN;
    END IF;

    IF upper(p_acc_type_in) NOT IN ('SPENDING',
                                    'SAVING',
                                    'SAVINGS')
    THEN
      p_status_out := vmscms.gpp_const.c_inv_acc_status;
      g_err_invalid_data.raise(l_api_name,
                               ',0003,',
                               'INVALID ACCOUNT TYPE');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken,
                                                   (CASE WHEN
                                                    p_fee_waiver_in = 'TRUE' THEN 'Y' ELSE 'N' END),
                                                   l_auth_id);
      RETURN;
    END IF;

    l_recordsperpage := nvl(p_recordsperpage_in,
                            1000);
    l_pagenumber     := nvl(p_pagenumber_in,
                            1);
    l_rec_end_no     := l_recordsperpage * l_pagenumber;
    l_rec_start_no   := (l_rec_end_no - l_recordsperpage) + 1;
    l_sort_element   := nvl(p_sortelement_in,
                            'business_date');
    l_year_month     := substr(p_start_date_in,
                               1,
                               4) || substr(p_start_date_in,
                                            6,
                                            2);
    l_month_year     := substr(p_start_date_in,
                               6,
                               2) || substr(p_start_date_in,
                                            1,
                                            4);

    --Cursor to fetch txn details
    IF upper(p_sortelement_in) NOT IN
       ('BUSINESSDATE',
        'TRANSACTIONAMOUNT',
        'BALANCE')
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_sort_status;
      g_err_invalid_data.raise(l_api_name,
                               ',0028,',
                               'WRONG SORT ELEMENT');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
      RETURN;
    END IF;

    l_sort_order := CASE upper(p_sortorder_in)
                      WHEN 'ASCENDING' THEN
                       'ASC'
                      WHEN 'DESCENDING' THEN
                       'DESC'
                      ELSE
                       'ASC'
                    END;
    g_debug.display('sort order :' || l_sort_order);

    --performance change
    IF upper(p_acc_type_in) = 'SPENDING'
    THEN
      l_acct_type_cd := 1;
    ELSIF upper(p_acc_type_in) IN ('SAVING',
                                   'SAVINGS')
    THEN
      l_acct_type_cd := 2;
    END IF;

    g_debug.display('p_acc_type_in :' || p_acc_type_in);
    g_debug.display('l_acct_type_cd :' || l_acct_type_cd);
    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_cust_code,
                                   l_prod_code,
                                   l_card_type,
                                   l_proxy_no,
                                   l_cardstat,
                                   l_acct_no,
                                   l_masked_pan,
                                   l_profile_code);

    g_debug.display('l_cust_code :' || l_cust_code);


    l_order_by := nvl(upper(p_sortelement_in),
                      'BUSINESSDATE') || ' ' || l_sort_order;

    l_wrapper_query := q'[SELECT * FROM (]';
    g_debug.display('order by :' || l_order_by);

    l_query := q'[SELECT csl_rrn transactionid,
                         to_char(to_date(csl_business_date,
                                         'yyyymmdd'),
                                 'yyyy-mm-dd') businessdate,
                         to_char(to_date(csl_business_time,
                                         'hh24:mi:ss'),
                                 'hh24:mi:ss') businesstime,
                         to_char(csl_ins_date,
                                 'YYYY-MM-DD HH24:MI:SS') systemdate,
                         csl_trans_type txn_type,
                         CASE
			   WHEN csl_delivery_channel IN ('01','02') AND TXN_FEE_FLAG = 'N'
			   THEN DECODE(nvl(regexp_instr(csl_trans_narrration,'RVSL-',1,1,0,'i'),0),0,TRANS_DESC,
                          'RVSL-'||TRANS_DESC)
			  ||'/'||DECODE(nvl(merchant_name,CSL_MERCHANT_NAME), NULL, DECODE(delivery_channel, '01', 'ATM', '02', 'Retail Merchant'), nvl(merchant_name,CSL_MERCHANT_NAME)
                                                                                                             || '/'
                                                                                                             || terminal_id
                                                                                                             || '/'
                                                                                                             || merchant_street
                                                                                                             || '/'
                                                                                                             || merchant_city
                                                                                                             || '/'
                                                                                                             || merchant_state
                                                                                                             || '/'
                                                                                                             || preauthamount
                                                                                                             || '/'
                                                                                                             ||business_date
                                                                                                             ||'/'
                                                                                                             ||auth_id)
                           WHEN regexp_like(csl_trans_narrration,
                                            '/') THEN
                            REPLACE(substr(initcap(csl_trans_narrration),
                                           1,
                                           instr(initcap(csl_trans_narrration),
                                                 '/',
                                                 1) - 1),
                                    'Clawback-') ||
                            decode(upper(substr(csl_trans_narrration,
                                                1,
                                                9)),
                                   'CLAWBACK-',
                                   (SELECT initcap(decode(cpc_clawback_desc,
                                                          NULL,
                                                          '',
                                                          ' - ' || cpc_clawback_desc))
                                      FROM --vmscms.cms_product_param
                                            vmscms.cms_prod_cattype
                                     WHERE cpc_prod_code = csl_prod_code
                                       AND cpc_card_type = :l_card_type
                                       AND cpc_inst_code = 1),
                                   '')
                           ELSE
                            initcap(REPLACE(upper(csl_trans_narrration),
                                            'CLAWBACK-')) ||
                            decode(upper(substr(csl_trans_narrration,
                                                1,
                                                9)),
                                   'CLAWBACK-',
                                   (SELECT initcap(decode(cpc_clawback_desc,
                                                          NULL,
                                                          '',
                                                          ' - ' || cpc_clawback_desc))
                                      FROM -- vmscms.cms_product_param
                                            vmscms.cms_prod_cattype
                                     WHERE cpc_prod_code = csl_prod_code
                                       AND cpc_card_type = :l_card_type
                                       AND cpc_inst_code = 1),
                                   '')
                         END AS txn_description,
                         to_char(nvl(csl_trans_amount,
                                     0),
                                 '9,999,999,990.99') transactionamount,
                         to_char(nvl(csl_closing_balance,
                                     0),
                                 '9,999,999,990.99') balance,
                     CASE WHEN (csl_delivery_channel='02' AND csl_txn_code='12') AND txn_fee_flag = 'N' THEN
                                  (SELECT cpi_spu_id  FROM vmscms.cms_payment_info
                                   WHERE cpi_inst_code=csl_inst_code
                                   AND cpi_rrn=csl_rrn
                                   AND cpi_pan_code=csl_pan_no
                                   AND rownum = 1)
                        WHEN ((csl_delivery_channel='03' AND csl_txn_code='39')
                           OR (csl_delivery_channel='10' AND csl_txn_code='07')
                           OR (csl_delivery_channel='07' AND csl_txn_code='07')
                           OR (csl_delivery_channel='13' AND csl_txn_code='13'))
                           AND customer_card_no IS NOT NULL AND txn_fee_flag = 'N' THEN
                                  (SELECT vmscms.fn_dmaps_main(ccm_first_name)||' '||vmscms.fn_dmaps_main(ccm_last_name) FROM vmscms.cms_cust_mast
                                   WHERE  ccm_inst_code=csl_inst_code
                                   AND ccm_cust_code=(SELECT cap_cust_code FROM vmscms.cms_appl_pan
                                                      WHERE cap_inst_code=csl_inst_code
                                                      AND cap_mbr_numb='000'
                                                      AND cap_pan_code= topup_card_no)) END toThirdPartyName,
                     CASE  WHEN ((csl_delivery_channel = '11' AND csl_txn_code = '22' )
                              OR (csl_delivery_channel = '03' AND csl_txn_code = '93'))
                              AND txn_fee_flag = 'N' THEN
                                   NVL(COMPANYNAME,'') ||'/ ' || NVL(COMPENTRYDESC,'')
                                   || '/ ' ||NVL(INDIDNUM,'') || '/ to ' ||INDNAME
                        WHEN (csl_delivery_channel='02' AND csl_txn_code='37') AND txn_fee_flag = 'N' THEN
                                  (SELECT cpi_payer_id  FROM vmscms.cms_payment_info
                                   WHERE cpi_inst_code=csl_inst_code
                                   AND cpi_rrn=csl_rrn
                                   AND cpi_pan_code=csl_pan_no)
                        WHEN ((csl_delivery_channel='03' AND csl_txn_code='39')
                           OR (csl_delivery_channel='10' AND csl_txn_code='07')
                           OR (csl_delivery_channel='07' AND csl_txn_code='07')
                           OR (csl_delivery_channel='13' AND csl_txn_code='13') )
                           AND customer_card_no IS NULL AND txn_fee_flag = 'N' THEN
                                  (SELECT vmscms.fn_dmaps_main(ccm_first_name)||' '||vmscms.fn_dmaps_main(ccm_last_name) FROM vmscms.cms_cust_mast
                                   WHERE  ccm_inst_code=csl_inst_code
                                   AND ccm_cust_code=(SELECT cap_cust_code FROM vmscms.cms_appl_pan
                                                      WHERE cap_inst_code=csl_inst_code
                                                      AND cap_mbr_numb='000'
                                                      AND cap_pan_code= (SELECT customer_card_no FROM vmscms.transactionlog
                                                                         WHERE  csl_delivery_channel = delivery_channel
                                                                         AND csl_txn_code       = txn_code
                                                                         AND csl_rrn            = rrn
                                                                         AND csl_auth_id        = auth_id
                                                                         AND csl_inst_code      = instcode
                                                                         AND response_code      ='00' ))) END fromThirdPartyName,
                         merchant_id id,
                         merchant_name name,
                         merchant_street streetAddress,
                         merchant_city city,
                         merchant_zip postalCode,
                         case when delivery_channel='03' and txn_code in ('13','14') then NULL
                         else
                         merchant_state
                         end state,                                      --- Modified for VMS-1022
                         country_code country,
                         terminal_id terminalId
                    FROM vmscms.cms_statements_log,
                         vmscms.transactionlog,
                         (SELECT cam_acct_no, cam_inst_code
                            FROM vmscms.cms_cust_acct, vmscms.cms_acct_mast
                           WHERE cca_acct_id = cam_acct_id
                             AND cam_inst_code = 1
                             AND cam_type_code = :l_acct_type_cd
                             AND cca_cust_code = :l_cust_code) d
                   WHERE csl_acct_no = d.cam_acct_no
                     AND csl_inst_code = d.cam_inst_code
                     AND csl_inst_code=instcode(+)
                     AND csl_rrn = rrn(+)
                     AND csl_pan_no = customer_card_no(+)
                     AND csl_auth_id = auth_id(+)
                     AND csl_delivery_channel = delivery_channel(+)
                     AND csl_txn_code = txn_code(+)
                     AND (response_code = '00' OR  response_code IS NULL)
                     AND to_char(csl_ins_date,
                                 'YYYYMM') = :l_year_month
                                  ORDER BY ]' || l_order_by;

    l_row_query := ') WHERE rownum BETWEEN :l_rec_start_no AND :l_rec_end_no';

    l_query := l_wrapper_query || l_query || l_row_query;

    OPEN c_txn_det_out FOR l_query
    --performance changes
    -- USING l_partner_id, p_acc_type_in, p_acc_type_in, p_customer_id_in, l_year_month, l_rec_start_no, l_rec_end_no;
      USING l_card_type, l_card_type, l_acct_type_cd, l_cust_code, l_year_month, l_rec_start_no, l_rec_end_no;

    --Fetching the active PAN for the input customer id
    --performance changes
    --vmscms.gpp_pan.get_pan_details(p_customer_id_in,
    --                               l_hash_pan,
    --                               l_encr_pan);

    g_debug.display('getting total monthly fee');
    SELECT TRIM(to_char(nvl(SUM(decode(to_char(csl_ins_date,
                                               'YYYYMM'),
                                       l_year_month,
                                       decode(csl_trans_type,
                                              'DR',
                                              csl_trans_amount,
                                              -csl_trans_amount),
                                       0)),
                            0),
                        '9,999,999,990.99')) month_fee,
           TRIM(to_char(nvl(SUM(CASE
                                  WHEN to_char(csl_ins_date,
                                               'YYYYMM') BETWEEN
                                       substr(l_year_month,
                                              1,
                                              4) || '01' AND l_year_month THEN
                                   decode(csl_trans_type,
                                          'DR',
                                          csl_trans_amount,
                                          -csl_trans_amount)
                                END),
                            0),
                        '9,999,999,990.99')) yearly_fee
      INTO p_total_fee_out, p_ytd_out
      FROM cms_statements_log
     WHERE csl_acct_no = l_acct_no
       AND csl_inst_code = 1
       AND txn_fee_flag = 'Y'
       AND to_char(csl_ins_date,
                   'YYYY') = substr(l_year_month,
                                    1,
                                    4);

    SELECT cpm_statement_footer1 || '~' || cpm_statement_footer2 || '~' ||
           cpm_statement_footer3 || '~' || cpm_statement_footer4 || '~' ||
           cpm_statement_footer5
      INTO p_statement_footer_out
      FROM cms_prod_mast
     WHERE cpm_prod_code = l_prod_code;

    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;

    --Cursor to fetch spending and savings account details
    OPEN c_acc_det_out FOR
      SELECT spending.cam_acct_no spendingacctnumber,
             saving.cam_acct_no savingacctnumber,
             -- ccm_first_name firstname,
             -- ccm_last_name lastname,
             decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(ccm_first_name),ccm_first_name) firstname,
             decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(ccm_last_name),ccm_last_name) lastname,
             (SELECT gcm_curr_name
                FROM vmscms.gen_curr_mast, vmscms.cms_bin_param
               WHERE gcm_curr_code = cbp_param_value --performance change
                 AND gcm_inst_code = cbp_inst_code --performance change
                 AND gcm_inst_code = 1
                 AND cbp_profile_code = e.cpc_profile_code
                 AND cbp_param_name = 'Currency') currency_code,
             to_char(nvl(spending.cam_ledger_bal,
                         0),
                     '9,999,999,990.99') spendingledgerbalance,
             to_char(nvl(spending.cam_acct_bal,
                         0),
                     '9,999,999,990.99') spendingavailablebalance,
             to_char(nvl(saving.cam_ledger_bal,
                         0),
                     '9,999,999,990.99') savingledgerbalance,
             to_char(nvl(saving.cam_acct_bal,
                         0),
                     '9,999,999,990.99') savingavailablebalance,
             'PHYSICAL' address_type1,
             -- physical_addr.cam_add_one physical_address1,
             --  physical_addr.cam_add_two physical_address2,
             --  physical_addr.cam_city_name physical_city,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_add_one),physical_addr.cam_add_one)) physical_address1,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_add_two),physical_addr.cam_add_two)) physical_address2,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_city_name),physical_addr.cam_city_name)) physical_city,
             --(SELECT upper(gsm_state_name)
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT upper(gsm_switch_state_code) --Jira Issue: CFIP:211
                FROM vmscms.gen_state_mast
               WHERE gsm_inst_code = physical_addr.cam_inst_code
                 AND gsm_state_code = physical_addr.cam_state_code
                 AND gsm_cntry_code = physical_addr.cam_cntry_code)) physical_state,
    --         physical_addr.cam_pin_code physical_zip,
		      	 decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(physical_addr.cam_pin_code),physical_addr.cam_pin_code)) physical_zip,
             'MAILING' address_type2,
              --  mailing_addr.cam_add_one mailing_address1,
              --  mailing_addr.cam_add_two mailing_address2,
              --  mailing_addr.cam_city_name mailing_city,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_add_one),mailing_addr.cam_add_one)) mailing_address1,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_add_two),mailing_addr.cam_add_two)) mailing_address2,
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_city_name),mailing_addr.cam_city_name)) mailing_city,
             --(SELECT upper(gsm_state_name)
             decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',(SELECT upper(gsm_switch_state_code) --Jira Issue: CFIP:211
                FROM vmscms.gen_state_mast
               WHERE gsm_inst_code = mailing_addr.cam_inst_code
                 AND gsm_state_code = mailing_addr.cam_state_code
                 AND gsm_cntry_code = mailing_addr.cam_cntry_code)) mailing_state,
   --          mailing_addr.cam_pin_code mailing_zip,
	       		decode (nvl(CCM_SYSTEM_GENERATED_PROFILE,'N'),'N',decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(mailing_addr.cam_pin_code),mailing_addr.cam_pin_code)) mailing_zip,
             cpm_prod_desc product_desc,
             cpc_cardtype_desc product_category_desc,
             -- a.cap_mask_pan masked_pan    --performance change
             l_masked_pan masked_pan --performance change
        FROM --vmscms.cms_appl_pan a,     --performance change
             vmscms.cms_cust_mast a,
             --    vmscms.cms_cust_acct,
             vmscms.cms_addr_mast physical_addr,
             vmscms.cms_addr_mast mailing_addr,
             (SELECT * ---- updated v2.3
                FROM cms_acct_mast, cms_cust_acct
               WHERE cam_type_code = '1'
                 AND cca_acct_id = cam_acct_id
                 AND cca_inst_code = cam_inst_code
                 AND cca_inst_code = 1) spending,
             (SELECT *
                FROM cms_acct_mast, cms_cust_acct
               WHERE cam_type_code = '2'
                 AND cca_acct_id = cam_acct_id
                 AND cca_inst_code = cam_inst_code
                 AND cca_inst_code = 1) saving,
             vmscms.cms_prod_mast d,
             vmscms.cms_prod_cattype e
       WHERE ccm_cust_code = l_cust_code --cap_inst_code = ccm_inst_code  --performance change
            -- AND cap_cust_code = ccm_cust_code  --performance change
         AND ccm_cust_code = physical_addr.cam_cust_code
         AND physical_addr.cam_addr_flag = 'P'
         AND ccm_cust_code = mailing_addr.cam_cust_code(+)
         AND mailing_addr.cam_addr_flag(+) = 'O'
         AND ccm_inst_code = spending.cca_inst_code
         AND ccm_cust_code = spending.cca_cust_code
         AND ccm_inst_code = saving.cca_inst_code(+)
         AND ccm_cust_code = saving.cca_cust_code(+)
         AND cpm_prod_code = l_prod_code --performance change
         AND cpm_inst_code = 1 --performance change
         AND cpc_card_type = l_card_type --performance change
         AND cpc_prod_code = l_prod_code --performance change
         AND cpc_inst_code = 1; --performance change
    --  AND cap_prod_code = cpm_prod_code  --performance change
    -- AND cap_card_type = cpc_card_type   --performance change
    -- AND cap_prod_code = cpc_prod_code    --performance change
    -- AND ccm_partner_id IN (l_partner_id)  --performance change
    -- AND cap_pan_code =  l_hash_pan;  --performance change
    --vmscms.gethash(vmscms.fn_dmaps_main(l_hash_pan));

    --Fetching the discrete output parameters for spending/saving account
    CASE
      WHEN upper(p_acc_type_in) = 'SPENDING' THEN
        --Fix for JIRA CFIP-8 Starts
        --All values other than opening/closing balance are null for spending account
        p_int_accrued_out   := NULL;
        p_int_paid_out      := NULL;
        p_percent_yield_out := NULL;
        p_int_rate_out      := NULL;
        BEGIN
          SELECT opening_balance, rn, total_count
            INTO p_open_bal_out, l_rn, l_total_count
            FROM (SELECT to_char(nvl(csl_opening_bal,
                                     0),
                                 '9,999,999,990.99') opening_balance,
                         row_number() over(ORDER BY csl_ins_date) AS rn,
                         COUNT(*) over() AS total_count
                    FROM vmscms.cms_statements_log,
                         (SELECT cam_acct_no, cam_inst_code
                            FROM vmscms.cms_cust_acct, vmscms.cms_acct_mast --performance change
                           WHERE cca_acct_id = cam_acct_id
                             AND cam_inst_code = 1
                             AND cam_type_code = 1
                             AND cca_cust_code = l_cust_code) d
                   WHERE csl_inst_code = 1
                     AND csl_inst_code = d.cam_inst_code
                     AND csl_acct_no = d.cam_acct_no
                     AND to_char(csl_ins_date,
                                 'YYYYMM') = l_year_month) t
           WHERE rn = 1;
        EXCEPTION
          WHEN no_data_found THEN
            NULL;
        END;

        BEGIN
          SELECT closing_balance, rn, total_count
            INTO p_close_bal_out, l_rn, l_total_count
            FROM (SELECT to_char(nvl(csl_closing_balance,
                                     0),
                                 '9,999,999,990.99') closing_balance,
                         row_number() over(ORDER BY csl_ins_date) AS rn,
                         COUNT(*) over() AS total_count
                    FROM vmscms.cms_statements_log,
                         (SELECT cam_acct_no, cam_inst_code
                            FROM vmscms.cms_cust_acct, vmscms.cms_acct_mast --performance change
                           WHERE cca_acct_id = cam_acct_id
                             AND cam_inst_code = 1
                             AND cam_type_code = 1
                             AND cca_cust_code = l_cust_code) d
                   WHERE csl_inst_code = 1
                     AND csl_inst_code = d.cam_inst_code
                     AND csl_acct_no = d.cam_acct_no
                     AND to_char(csl_ins_date,
                                 'YYYYMM') = l_year_month) t
           WHERE rn = total_count;
        EXCEPTION
          WHEN no_data_found THEN
            NULL;
        END;
        --Fix for JIRA CFIP-8 Ends
      WHEN upper(p_acc_type_in) IN ('SAVING',
                                    'SAVINGS') THEN
        --Fetching the savings account number for the input customer id
        BEGIN
          SELECT cam_acct_no, cam_inst_code
            INTO l_cust_acc_no, l_inst_code
            FROM vmscms.cms_cust_acct, vmscms.cms_acct_mast --, --performance change
          -- vmscms.cms_cust_mast    --performance change
           WHERE cca_acct_id = cam_acct_id
                -- AND cca_cust_code = ccm_cust_code --performance change
             AND cam_inst_code = 1
             AND cam_type_code = 2 --performance change
                -- AND ccm_cust_id = p_customer_id_in  --performance change
                -- AND ccm_partner_id IN (l_partner_id);  --performance change
             AND cca_cust_code = l_cust_code; --performance change
        EXCEPTION
          WHEN no_data_found THEN
            NULL;
        END;
        --Procedure call to fetch the discrete parameters
        BEGIN
          fetch_savingacctdetl(l_inst_code,
                               l_month_year, --(p_start_date_in), ---Vishy: FIX THIS as the expected format here is MMYYYY
                               l_cust_acc_no,
                               p_err_msg_out,
                               p_int_rate_out,
                               p_int_paid_out,
                               p_int_accrued_out,
                               p_percent_yield_out,
                               p_open_bal_out,
                               p_close_bal_out);
        EXCEPTION
          WHEN OTHERS THEN
            p_status_out := vmscms.gpp_const.c_savingacc_status;
            g_err_savingacc.raise(l_api_name,
                                  ',0005,',
                                  'FETCH SAVING ACCOUNT DETAILS - FAILED');
            p_err_msg_out := g_err_savingacc.get_current_error;
            vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                         p_customer_id_in,
                                                         l_hash_pan,
                                                         l_encr_pan,
                                                         'F', --vmscms.gpp_const.c_failure_flag,
                                                         p_err_msg_out,
                                                         vmscms.gpp_const.c_failure_res_id,
                                                         NULL, --Remarks
                                                         l_timetaken,
                                                         (CASE WHEN p_fee_waiver_in =
                                                          'TRUE' THEN 'Y' ELSE 'N' END),
                                                         l_auth_id);
            RETURN;
        END;
      ELSE
        NULL;
    END CASE;

    --fee waiver

    BEGIN
      -- start of CFIP 371
      /*CASE upper(p_fee_waiver_in)
      WHEN 'TRUE' THEN
         NULL;
      ELSE*/
      --default value is FALSE
      --END of CFIP 371
      SELECT cip_param_value
        INTO l_curr_code
        FROM vmscms.cms_inst_param
       WHERE cip_inst_code = '1'
         AND cip_param_key = 'CURRENCY';

      l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                   'x-incfs-date'),
                       6,
                       11);

      vmscms.sp_authorize_txn_cms_auth(1,
                                       0200,
                                       l_rrn,
                                       '03',
                                       NULL,
                                       (CASE upper(p_stmt_type_in) WHEN
                                        'EMAIL' THEN 32 WHEN 'PAPER' THEN 42 END),
                                       0,
                                       to_char(to_date(l_date,
                                                       'dd-mm-yyyy'),
                                               'yyyymmdd'), -- Pass txn date in yyyymmdd
                                       -- CFIP 373 removed : for the time
                                       REPLACE(substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                                   'x-incfs-date')),
                                                      18,
                                                      8),
                                               ':'), --Pass txn time in hh24miss
                                       --substr('Sun, 06 Nov 1994 08:49:37 GMT',
                                       --18,8),
                                       vmscms.fn_dmaps_main(l_encr_pan), --decrypted current active pan code
                                       1,
                                       0,
                                       NULL,
                                       NULL,
                                       NULL,
                                       l_curr_code,
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
                                       NULL,
                                       000,
                                       00,
                                       NULL,
                                       l_auth_id,
                                       l_resp_cde,
                                       p_err_msg_out,
                                       l_capture_date,
                                       --start of CFIP 371
                                       CASE upper(p_fee_waiver_in) WHEN
                                       'TRUE' THEN 'N' ELSE 'Y' END
                                       -- end of CFIP 371
                                       );
      IF l_resp_cde <> '00'
         AND p_err_msg_out <> 'OK'
      THEN
        CLOSE c_acc_det_out;
        CLOSE c_txn_det_out;
        p_int_accrued_out   := NULL;
        p_int_paid_out      := NULL;
        p_percent_yield_out := NULL;
        p_int_rate_out      := NULL;
        p_open_bal_out      := NULL;
        p_close_bal_out     := NULL;

        p_status_out := vmscms.gpp_const.c_fee_waiver_status;
        --display the error message from the base procedure
        /*g_err_feewaiver.raise(l_api_name,
        vmscms.gpp_const.c_fee_waiver_errcode,
        vmscms.gpp_const.c_fee_waiver_errmsg);*/
        /*g_err_feewaiver.raise(l_api_name,
        ',0006,',
        'FEE WAIVER - FAILED');*/
        p_err_msg_out := p_err_msg_out;
        /*g_err_feewaiver.get_current_error*/
        RETURN;
      END IF;
      -- END CASE;

      --updating the below fields manually
      --since the sp_authorize_txn_cms_auth doesnot populate these fields in Transactionlog
      UPDATE vmscms.transactionlog
         SET ipaddress     =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-ip')),
             fsapi_username =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-username')),
             remark         = NULL,
             add_lupd_user  = NULL,
             add_ins_user   = NULL, --CFIP 372
             --Jira Issue: CFIP:188 starts
             correlation_id =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-correlationid')),
             partner_id    =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-partnerid'))
      --Jira Issue: CFIP:188 ends
       WHERE rrn = l_rrn;

    EXCEPTION
      WHEN OTHERS THEN
        --Procedure-sp_authorize_txn_cms_auth itself makes entry into transactionlog,cms_transaction_log_dtl tables
        --in success and failure cases.So no explicit calls to audit_txn_log
        CLOSE c_acc_det_out;
        CLOSE c_txn_det_out;
        p_int_accrued_out   := NULL;
        p_int_paid_out      := NULL;
        p_percent_yield_out := NULL;
        p_int_rate_out      := NULL;
        p_open_bal_out      := NULL;
        p_close_bal_out     := NULL;
        p_status_out        := vmscms.gpp_const.c_fee_waiver_status;

        g_err_feewaiver.raise(l_api_name,
                              ',0006,',
                              'FEE WAIVER - FAILED');
        p_err_msg_out := g_err_feewaiver.get_current_error;
        RETURN;
    END;
    --fee waiver ends
    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');
    p_status_out := vmscms.gpp_const.c_success_status;
    --Procedure-sp_authorize_txn_cms_auth itself makes entry into transactionlog,cms_transaction_log_dtl tables
    --in success and failure cases.So no explicit calls to audit_txn_log
  EXCEPTION
    WHEN no_data_found THEN

      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   (CASE WHEN
                                                    p_fee_waiver_in = 'TRUE' THEN 'Y' ELSE 'N' END),
                                                   l_auth_id);
  END get_account_statement;

  --get unmask pan
  PROCEDURE get_umaskpan(p_customer_id_in IN VARCHAR2,
                         p_mask_pan_in    IN VARCHAR2,
                         p_unmask_pan_out OUT VARCHAR2,
                         p_status_out     OUT VARCHAR2,
                         p_err_msg_out    OUT VARCHAR2) AS
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_field_name VARCHAR2(20);
    l_flag       PLS_INTEGER := 0;
    l_api_name   VARCHAR2(20) := 'GET UMMASK PAN';
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;


/****************************************************************************
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002

****************************************************************************/

  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --Check for mandatory fields
    CASE
      WHEN p_customer_id_in IS NULL THEN
        l_field_name := 'CUSTOMER_ID';
        l_flag       := 1;
      WHEN p_mask_pan_in IS NULL THEN
        l_field_name := 'MASK PAN';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;

    IF l_flag = 1
    THEN
      p_status_out := vmscms.gpp_const.c_mandatory_status;
      g_err_mandatory.raise(l_api_name,
                            ',0002,',
                            l_field_name || ' is mandatory');
      p_err_msg_out := g_err_mandatory.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
      RETURN;
    END IF;
    BEGIN
      SELECT cap_pan_code, cap_pan_code_encr
        INTO l_hash_pan, l_encr_pan
        FROM (SELECT cap_pan_code, cap_pan_code_encr
                FROM vmscms.cms_appl_pan
               WHERE cap_cust_code =
                     (SELECT ccm_cust_code
                        FROM vmscms.cms_cust_mast
                       WHERE ccm_cust_id = to_number(p_customer_id_in)
                         AND ccm_inst_code = 1
                            --AND ccm_partner_id IN (l_partner_id))
                         AND ccm_prod_code || ccm_card_type =
                             vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                      p_prod_code_in  => ccm_prod_code,
                                                                      p_card_type_in  => ccm_card_type))
                 --Defect fix for AMEX unmask pan issue 03.02.18 - ARD
                 --AND cap_mask_pan = p_mask_pan_in
                 AND vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) = p_mask_pan_in
                 AND cap_inst_code = 1
                 AND cap_active_date IS NOT NULL
                 AND cap_card_stat NOT IN ('9')
               ORDER BY cap_active_date DESC)
       WHERE rownum = 1;

    EXCEPTION
      WHEN no_data_found THEN
        SELECT cap_pan_code, cap_pan_code_encr
          INTO l_hash_pan, l_encr_pan
          FROM (SELECT cap_pan_code, cap_pan_code_encr
                  FROM vmscms.cms_appl_pan
                 WHERE cap_cust_code =
                       (SELECT ccm_cust_code
                          FROM vmscms.cms_cust_mast
                         WHERE ccm_cust_id = to_number(p_customer_id_in)
                              --AND ccm_partner_id IN (l_partner_id))
                           AND ccm_prod_code || ccm_card_type =
                               vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                        p_prod_code_in  => ccm_prod_code,
                                                                        p_card_type_in  => ccm_card_type))
                   --Defect fix for AMEX unmask pan issue 03.02.18 - ARD
                   --AND cap_mask_pan = p_mask_pan_in
                   AND vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) = p_mask_pan_in
                   AND cap_inst_code = 1
                 ORDER BY cap_pangen_date DESC)
         WHERE rownum < 2;
    END;
    SELECT vmscms.fn_dmaps_main(l_encr_pan)
      INTO p_unmask_pan_out
      FROM dual;
    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');
    p_status_out := vmscms.gpp_const.c_success_status;
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 p_customer_id_in,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C',
                                                 'SUCCESS',
                                                 1,
                                                 NULL,
                                                 l_timetaken);*/
  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

  END get_umaskpan;

  --Submit Document API
  PROCEDURE submit_document(p_customer_id_in   IN VARCHAR2,
                            p_file_type_in     IN VARCHAR2,
                            p_file_path_in     IN VARCHAR2,
                            p_file_size_in     IN VARCHAR2,
                            p_business_date_in IN VARCHAR2,
                            p_business_time_in IN VARCHAR2,
                            p_txn_code_in      IN VARCHAR2,
                            p_txn_id_in        IN VARCHAR2,
                            p_status_out       OUT VARCHAR2,
                            p_err_msg_out      OUT VARCHAR2) AS
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_acct_no    vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_field_name VARCHAR2(20);
    l_flag       PLS_INTEGER := 0;
    l_api_name   VARCHAR2(20) := 'SUBMIT DOCUMENT';
    l_customer   vmscms.cms_cust_mast.ccm_cust_id%TYPE;
    l_rrn        vmscms.transactionlog.rrn%TYPE;
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;

/****************************************************************************
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002

****************************************************************************/


  BEGIN
    l_start_time := dbms_utility.get_time;
    --Check for mandatory fields
    CASE
      WHEN p_customer_id_in IS NULL THEN
        l_field_name := 'CUSTOMER_ID';
        l_flag       := 1;
      WHEN p_file_type_in IS NULL THEN
        l_field_name := 'FILE TYPE';
        l_flag       := 1;
      WHEN p_file_path_in IS NULL THEN
        l_field_name := 'FILE PATH';
        l_flag       := 1;
      WHEN p_txn_code_in IS NULL THEN
        l_field_name := 'TXN CODE';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;

    IF l_flag = 1
    THEN
      p_status_out := vmscms.gpp_const.c_mandatory_status;
      g_err_mandatory.raise(l_api_name,
                            ',0002,',
                            l_field_name || ' is mandatory');
      p_err_msg_out := g_err_mandatory.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
      RETURN;
    END IF;

    IF p_file_type_in NOT IN ('KYC',
                              'DISPUTE',
                              'AUTHORIZEUSERPROOF',
                              'PREAUTH',
                              'PROOFOFID',
                              'DISPUTEPROCESS',
                              'ADDRESSOVERRIDE')
    THEN
      p_status_out := vmscms.gpp_const.c_inv_filetyp_status;
      g_err_invalid_data.raise(l_api_name,
                               ',0009,',
                               'INVALID FILE TYPE');
      p_err_msg_out := g_err_invalid_data.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
      RETURN;
    END IF;

    /* IF (p_file_type_in = 'DISPUTE' AND p_txn_code_in NOT IN ('88', '89','25'))
    THEN
    p_status_out := vmscms.gpp_const.c_inv_filetyp_txncode_status;
    g_err_invalid_data.raise(l_api_name,
    ',0010,',
    'INVALID FILE TYPE-TXN CODE COMBINATION');
    p_err_msg_out := g_err_invalid_data.get_current_error;
    vmscms.gpp_transaction.audit_transaction_log(l_api_name,
    p_customer_id_in,
    l_hash_pan,
    l_encr_pan,
    'F',
    p_err_msg_out,
    vmscms.gpp_const.c_failure_res_id,
    NULL,
    l_timetaken);
    RETURN;
    END IF;*/
    --customer id validation cfip:133 starts
    SELECT ccm_cust_id
      INTO l_customer
      FROM cms_cust_mast
     WHERE ccm_cust_id = p_customer_id_in;

    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_acct_no);
    --customer id validation cfip:133 ends
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;

    INSERT INTO vmscms.cms_fileupload_detl
      (cfu_inst_code,
       cfu_pan_code,
       cfu_pan_code_encr,
       cfu_file_type,
       cfu_file_path,
       cfu_file_size,
       cfu_ref_number,
       cfu_ins_date,
       cfu_ins_user,
       cfu_lupd_date,
       cfu_lupd_user,
       cfu_business_date,
       cfu_business_time,
       cfu_txn_code,
       cfu_delivery_channel,
       cfu_rrn,
       cfu_acct_no,
       cfu_upload_stat)
    VALUES
      ('1',
       l_hash_pan,
       l_encr_pan,
       p_file_type_in,
       p_file_path_in,
       p_file_size_in,
       decode(p_file_type_in,
              'DISPUTEPROCESS',
              p_txn_id_in,
              l_customer), --Modified DISPUTE to DIPUTEPROCESS
       SYSDATE,
       NULL,
       NULL,
       NULL,
       p_business_date_in,
       p_business_time_in,
       p_txn_code_in,
       '03',
       --NVL(p_txn_id_in, l_rrn),
       l_rrn,
       l_acct_no,
       'C');
    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');
    p_status_out  := vmscms.gpp_const.c_success_status;
    p_err_msg_out := 'SUCCESS';
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,     ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 p_customer_id_in,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C',
                                                 'SUCCESS',
                                                 1,
                                                 NULL,
                                                 l_timetaken);*/
  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

  END submit_document;

  --Adjust Balance
  PROCEDURE adjust_balance(p_action_in           IN VARCHAR2,
                           p_customer_id_in      IN VARCHAR2,
                           p_txn_id_in           IN VARCHAR2,
                           p_txn_date_in         IN VARCHAR2,
                           p_delivery_channel_in IN VARCHAR2,
                           p_txn_code_in         IN VARCHAR2,
                           p_response_code_in    IN VARCHAR2,
                           p_amount_in           IN VARCHAR2,
                           p_crdr_flag_in        IN VARCHAR2,
                           p_acct_type_in        IN VARCHAR2,
                           p_reason_in           IN VARCHAR2,
                           p_comment_in          IN VARCHAR2,
                           c_adj_bal_out         OUT SYS_REFCURSOR,
                           p_status_out          OUT VARCHAR2,
                           p_err_msg_out         OUT VARCHAR2) AS
    l_hash_pan        vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan        vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_date            VARCHAR2(20);
    l_time            VARCHAR2(50);
    l_timestamp       VARCHAR2(20);
    l_resp_code       VARCHAR2(5);
    l_resp_msg        VARCHAR2(500);
    l_curr_code       VARCHAR2(20);
    l_flag            PLS_INTEGER;
    l_crdr_flag_in    VARCHAR2(10);
    l_acct_type_in    VARCHAR2(10);
    l_reason_desc     vmscms.cms_spprt_reasons.csr_reasondesc%TYPE;
    l_acct_no         vmscms.cms_acct_mast.cam_acct_no%TYPE;
    l_final_bal       VARCHAR2(20);
    l_field_name      VARCHAR2(30);
    l_plain_pan       VARCHAR2(20);
    l_rrn             VARCHAR2(20);
    l_session_id      VARCHAR2(20);
    l_api_name        VARCHAR2(50);
    l_partner_id      vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_start_time      NUMBER;
    l_end_time        NUMBER;
    l_timetaken       NUMBER;
    l_tran_date       vmscms.transactionlog.business_date%TYPE;
    l_transfee_amt    vmscms.transactionlog.tranfee_amt%TYPE;
    l_original_rrn    vmscms.transactionlog.rrn%TYPE;
    l_audit_no        vmscms.transactionlog.system_trace_audit_no%TYPE;
    l_original_amount vmscms.transactionlog.amount%TYPE;
    /* l_business_date       vmscms.transactionlog.business_date%TYPE;
    l_business_time       vmscms.transactionlog.business_time%TYPE;*/
    l_business_date    VARCHAR2(8);
    l_business_time    VARCHAR2(9);
    l_txn_code         vmscms.transactionlog.txn_code%TYPE;
    l_delivery_channel vmscms.transactionlog.delivery_channel%TYPE;
    l_currtime         VARCHAR2(20);
    l_currdate         VARCHAR2(20);
    l_trans_desc       vmscms.transactionlog.trans_desc%TYPE;
    l_businessdate     VARCHAR2(20);
    l_businesstime     VARCHAR2(20);
    l_cardnumber       VARCHAR2(4000);
    l_acct_bal         VARCHAR2(200);
    --performance change
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;
    l_call_seq     vmscms.cms_calllog_details.ccd_call_seq%TYPE;
  BEGIN

    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --append action to API as this API has 2 actions
    l_api_name := 'ADJUST BALANCE:' || upper(p_action_in);
    --Fetching the active PAN for the input customer id
    --    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
    --                                     l_hash_pan,
    --                                     l_encr_pan);
    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_cust_code,
                                   l_prod_code,
                                   l_card_type,
                                   l_proxy_no,
                                   l_cardstat,
                                   l_acct_no,
                                   l_masked_pan,
                                   l_profile_code);

    --    l_partner_id :=1;
    --Fetching the active PAN for the input customer id
    --because FSAPI actions are not translated to VMS SPPRT_KEY directly
    --we need to use decode to translate

    IF upper(p_action_in) = 'ADJUSTBALANCE'
    /*AND  (p_txn_id_in IS NOT NULL or
                                                                                                                                                                                                          ---p_txn_date_in IS NOT NULL or
                                                                                                                                                                                                          ---p_delivery_channel_in IS NOT NULL or
                                                                                                                                                                                                          ---p_txn_code_in IS NOT NULL or
                                                                                                                                                                                                          ---p_response_code_in is not NULL)*/
    THEN
      CASE
        WHEN p_customer_id_in IS NULL THEN
          l_field_name := 'CUSTOMER ID';
          l_flag       := 1;
        WHEN p_amount_in IS NULL THEN
          l_field_name := 'AMOUNT';
          l_flag       := 1;
        WHEN p_crdr_flag_in IS NULL THEN
          l_field_name := 'CREDIT-DEBIT FLAG';
          l_flag       := 1;
        WHEN p_acct_type_in IS NULL THEN
          l_field_name := 'ACCOUNT TYPE';
          l_flag       := 1;
        WHEN p_reason_in IS NULL THEN
          l_field_name := 'REASON';
          l_flag       := 1;
        WHEN p_comment_in IS NULL THEN
          l_field_name := 'COMMENT';
          l_flag       := 1;
        ELSE
          --everything is ok
          l_flag := 0;
      END CASE;
    ELSIF upper(p_action_in) = 'REVERSEFEE'
    THEN
      CASE
        WHEN p_customer_id_in IS NULL THEN
          l_field_name := 'CUSTOMER ID';
          l_flag       := 1;
        WHEN p_txn_id_in IS NULL THEN
          l_field_name := 'TRANSACTION ID';
          l_flag       := 1;
        WHEN p_txn_date_in IS NULL THEN
          l_field_name := 'TRANSACTION DATE';
          l_flag       := 1;
        WHEN p_delivery_channel_in IS NULL THEN
          l_field_name := 'DELIVERY CHANNEL';
          l_flag       := 1;
        WHEN p_txn_code_in IS NULL THEN
          l_field_name := 'TRANSACTION CODE';
          l_flag       := 1;
        WHEN p_response_code_in IS NULL THEN
          l_field_name := 'RESPONSE CODE';
          l_flag       := 1;
        WHEN p_reason_in IS NULL THEN
          l_field_name := 'REASON';
          l_flag       := 1;
        WHEN p_comment_in IS NULL THEN
          l_field_name := 'COMMENT';
          l_flag       := 1;
        ELSE
          --everything is ok
          l_flag := 0;
      END CASE;
    END IF;
    IF l_flag = 1
    THEN
      p_status_out := vmscms.gpp_const.c_mandatory_status;
      g_err_mandatory.raise(l_api_name,
                            ',0002,',
                            l_field_name || ' is mandatory');
      p_err_msg_out := g_err_mandatory.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
      RETURN;
    END IF;

    BEGIN
      SELECT csr_reasondesc
        INTO l_reason_desc
        FROM cms_spprt_reasons
      --because FSAPI actions are not translated to VMS SPPRT_KEY directly
      --we need to use decode to translate
       WHERE csr_spprt_key = decode(upper(p_action_in),
                                    'REVERSEFEE',
                                    'FEEREVERSAL',
                                    'ADJUSTBALANCE',
                                    'MANADJDRCR',
                                    upper(p_action_in))
         AND csr_spprt_rsncode = p_reason_in
         AND csr_inst_code = '1';
    EXCEPTION
      WHEN no_data_found THEN
        p_status_out := vmscms.gpp_const.c_invalid_reason_code_status;
        --using constants doesnt work for some reason
        --need to find out
        g_err_invalid_data.raise(l_api_name,
                                 ',' ||
                                 vmscms.gpp_const.c_invalid_reason_code_errcode || ',',
                                 vmscms.gpp_const.c_invalid_reason_code_errmsg);

        /*             g_err_invalid_data.raise(l_api_name,
        ',0044,',
        'INVALID REASON CODE ENTERED');
        */
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F',
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL,
                                                     l_timetaken);
        RETURN;
    END;

    ---get currency code
    g_debug.display(g_debug.format('encrypted pan : $1',
                                   l_encr_pan));
    l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);
    g_debug.display(g_debug.format('l_plain_pan : $1',
                                   l_plain_pan));
    g_debug.display(g_debug.format('l_plain_pan updated : $1',
                                   l_plain_pan));

    --Performance Fix
    SELECT cbp_param_value
      INTO l_curr_code
      FROM vmscms.cms_prod_cattype, vmscms.cms_bin_param
     WHERE cpc_inst_code = cbp_inst_code
       AND cpc_profile_code = cbp_profile_code
       AND cpc_prod_code = l_prod_code
       AND cpc_card_type = l_card_type
       AND cpc_inst_code = 1
       AND cbp_param_name = 'Currency';

    g_debug.display(g_debug.format('currenct_code updated : $1',
                                   l_curr_code));
    g_debug.display(g_debug.format('currenct_code : $1',
                                   l_curr_code));
    g_debug.display(g_debug.format('reason_description : $1',
                                   l_reason_desc));
    l_rrn := to_char(to_char(SYSDATE,
                             'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                     lpad(vmscms.seq_deppending_rrn.nextval,
                          3,
                          '0'));

    g_debug.display(g_debug.format('l_rrn : $1',
                                   l_rrn));

    l_session_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-sessionid'));

    g_debug.display(g_debug.format('session_id : $1',
                                   l_session_id));

    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);
    --  l_date      := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11);
    l_timestamp := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-date'),
                          18,
                          8);
    --  l_timestamp := to_char(to_date('08:49:37', 'HH:MI:SS'), 'HHMISS');
    l_timestamp := REPLACE(l_timestamp,
                           ':',
                           '');

    --Check for mandatory fields
    g_debug.display(g_debug.format('ACTION_2 : $1',
                                   p_action_in));
    g_debug.display(g_debug.format('account_type : $1',
                                   p_acct_type_in));

    IF upper(p_action_in) = 'ADJUSTBALANCE'
    THEN

      l_acct_type_in := upper(p_acct_type_in);

      IF l_acct_type_in NOT IN ('SPENDING',
                                'SAVING',
                                'SAVINGS')
      THEN
        p_status_out := vmscms.gpp_const.c_inv_acc_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0003,',
                                 'Invalid Account Type');
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F',
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL,
                                                     l_timetaken);
        RETURN;
      END IF;
      g_debug.display(g_debug.format('credit flag : $1',
                                     p_crdr_flag_in));

      l_crdr_flag_in := upper(p_crdr_flag_in);
      IF l_crdr_flag_in NOT IN ('CREDIT',
                                'DEBIT')
      THEN
        p_status_out := vmscms.gpp_const.c_inv_crdr_flg_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0014,',
                                 'Invalid Credit-Debit Flag');
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F',
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL,
                                                     l_timetaken);
        RETURN;
      END IF;

      g_debug.display(g_debug.format('TAMIL_ACCOUNT_NUMBER : $1',
                                     l_acct_type_in));

      IF upper(l_acct_type_in) = 'SAVINGS'
      THEN

        SELECT cam_acct_no
          INTO l_acct_no
          FROM vmscms.cms_cust_acct, vmscms.cms_acct_mast
         WHERE cca_cust_code = l_cust_code
           AND cca_inst_code = 1
           AND cca_acct_id = cam_acct_id
           AND cca_inst_code = cam_inst_code
           AND cam_type_code = '2';

      END IF;

      g_debug.display('l_acct_no ' || l_acct_no);

      BEGIN
        g_debug.display(g_debug.format('l_plain_pan : $1',
                                       l_plain_pan));
        g_debug.display(g_debug.format('l_rrn : $1',
                                       l_rrn));
        g_debug.display(g_debug.format('l_curr_code : $1',
                                       l_curr_code));
        g_debug.display(g_debug.format('l_acct_no : $1',
                                       l_acct_no));
        g_debug.display(g_debug.format('l_reason_desc : $1',
                                       l_reason_desc));

        vmscms.sp_manual_adj_csr(1,
                                 '000',
                                 '0200',
                                 '03',
                                 (CASE WHEN l_crdr_flag_in = 'CREDIT' THEN '14' WHEN
                                  l_crdr_flag_in = 'DEBIT' THEN '13' END),
                                 '0',
                                 to_char(to_date(l_date,
                                                 'dd-mm-yyyy'),
                                         'yyyymmdd'), --date
                                 l_timestamp,
                                 l_plain_pan,
                                 l_rrn,
                                 NULL,
                                 p_amount_in,
                                 p_reason_in,
                                 p_comment_in,
                                 0,
                                 l_curr_code,
                                 NULL,
                                 l_reason_desc,
                                 l_session_id,
                                 l_acct_no,
                                 (CASE WHEN l_acct_type_in = 'SPENDING' THEN 1 WHEN
                                  l_acct_type_in = 'SAVINGS' THEN 2 END),
                                 (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                              'x-incfs-ip')),
                                 1,
                                 NULL,
                                 l_final_bal,
                                 l_resp_code,
                                 l_resp_msg);
        g_debug.display(g_debug.format('response_code : $1',
                                       l_resp_code));
        g_debug.display(g_debug.format('response_message : $1',
                                       l_resp_msg));
        g_debug.display(g_debug.format('final_balance : $1',
                                       l_final_bal));
      EXCEPTION
        WHEN OTHERS THEN
          g_debug.display('Exception in Adjust Balance');
          p_status_out  := l_resp_code;
          p_err_msg_out := l_resp_msg;
          RETURN;
      END;

      IF l_resp_code = '00'
      THEN
        IF l_crdr_flag_in = 'CREDIT'
        THEN
          BEGIN
            vmscms.sp_clawback_recovery('1',
                                        l_plain_pan,
                                        '000',
                                        l_resp_msg);
          EXCEPTION
            WHEN OTHERS THEN
              g_debug.display('Exception in Clawback Recovery');
              p_status_out  := vmscms.gpp_const.c_clw_bck_status;
              p_err_msg_out := l_resp_msg;
              RETURN;
          END;
        END IF;
      ELSE
        g_debug.display('Adjust Balance Failed');
        p_status_out  := l_resp_code;
        p_err_msg_out := l_resp_msg;
        RETURN;
      END IF;

      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';

    END IF;

    --Check for mandatory fields for FEE REVERSAL

    IF upper(p_action_in) = 'REVERSEFEE'
    THEN
      l_acct_type_in := upper(p_acct_type_in); -- FSAPI 5.5.5

      l_tran_date := to_char(trunc(to_date(p_txn_date_in,
                                           'YYYY-MM-DD HH24:MI:SS')),
                             'YYYYMMDD');
      -- l_time := replace(substr(p_txn_date_in,11,9),':', '' );

      SELECT vmscms.fn_dmaps_main(customer_card_no_encr) cardnumber,
             rrn,
             system_trace_audit_no,
             business_date,
             business_time,
             nvl(to_char(amount,
                         '9999999990.99'),
                 '0.00') amount,
             txn_code,
             delivery_channel,
             nvl(to_char(tranfee_amt,
                         '9999999990.99'),
                 '0.00') tranfee_amt,
             to_char(SYSDATE,
                     'yyyymmdd') currdate,
             to_char(SYSDATE,
                     'hh24miss') currtime,
             trans_desc,
             to_char(to_date(business_date,
                             'yyyymmdd'),
                     'mm/dd/yyyy') business_date,
             to_char(to_date(business_time,
                             'hh24miss'),
                     'hh24:mi:ss') business_time
        INTO l_cardnumber,
             l_original_rrn,
             l_audit_no,
             l_business_date,
             l_business_time,
             l_original_amount,
             l_txn_code,
             l_delivery_channel,
             l_transfee_amt,
             l_currdate,
             l_currtime,
             l_trans_desc,
             l_businessdate,
             l_businesstime
        FROM transactionlog
       WHERE rrn = p_txn_id_in
         AND delivery_channel = p_delivery_channel_in
         AND txn_code = p_txn_code_in --Performance Fix
         AND response_code = p_response_code_in --Performance Fix
         AND business_date = l_tran_date;
      -- and business_time = l_time;

      g_debug.display('after reverse free part l_cardnumber' ||
                      l_cardnumber);
      g_debug.display('after reverse free part l_original_rrn' ||
                      l_original_rrn);
      g_debug.display('after reverse free part l_audit_no' || l_audit_no);
      g_debug.display('after reverse free part l_business_date' ||
                      l_business_date);
      g_debug.display('after reverse free part l_business_time' ||
                      l_business_time);
      g_debug.display('after reverse free part l_original_amount' ||
                      l_original_amount);
      g_debug.display('after reverse free part l_delivery_channel' ||
                      l_delivery_channel);
      g_debug.display('after reverse free part l_transfee_amt' ||
                      l_transfee_amt);
      g_debug.display('after reverse free part l_tran_date' || l_tran_date);
      g_debug.display('after reverse free part l_currdate' || l_currdate);

      g_debug.display('after reverse free part l_currtime' || l_currtime);
      g_debug.display('after reverse free part l_trans_desc' ||
                      l_trans_desc);
      g_debug.display('after reverse free part l_businessdate' ||
                      l_business_date);
      g_debug.display('after reverse free part l_businesstime' ||
                      l_business_time);

      BEGIN
        g_debug.display('INSERT TO BASE PROC SP_REVERSE_FEE_CRS');
        vmscms.sp_reverse_fee_csr('1',
                                  '0200',
                                  l_rrn,
                                  NULL,
                                  to_char(to_date(l_date,
                                                  'dd-mm-yyyy'),
                                          'yyyymmdd'), --date
                                  l_timestamp,
                                  l_transfee_amt,
                                  NULL,
                                  l_curr_code,
                                  '12',
                                  '0',
                                  '03',
                                  '000',
                                  '0',
                                  l_plain_pan,
                                  l_original_rrn,
                                  l_cardnumber,
                                  l_audit_no,
                                  l_business_date,
                                  l_business_time,
                                  l_original_amount,
                                  l_txn_code,
                                  l_delivery_channel,
                                  NULL,
                                  p_comment_in,
                                  (CASE WHEN p_reason_in = '63' THEN
                                   'Incorrect Fee' WHEN
                                   p_reason_in = 'DEBIT' THEN
                                   'Courtesy Reversal' END),
                                  l_reason_desc,
                                  l_session_id,
                                  NULL,
                                  NULL,
                                  NULL,
                                  (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                               'x-incfs-ip')),
                                  l_acct_bal,
                                  l_resp_code,
                                  l_resp_msg);

        g_debug.display('after reverse BASEPROC RESPONSE CODE' ||
                        l_resp_code);
        g_debug.display('after reverse BASEPROC ACCT BALANCE ' ||
                        l_acct_bal);
        g_debug.display('after reverse BASEPROC RESPONSE MESSAGE ' ||
                        l_resp_msg);
      EXCEPTION
        WHEN OTHERS THEN
          g_debug.display('Exception in FEE REVERSAL Balance');
          p_status_out  := l_resp_code;
          p_err_msg_out := l_resp_msg;
          RETURN;
      END;

      ---------------------
      IF l_resp_code <> '00'
         AND l_resp_msg <> 'OK'
      THEN
        p_status_out  := l_resp_code;
        p_err_msg_out := l_resp_msg;
        RETURN;
      ELSE
        p_status_out  := vmscms.gpp_const.c_success_status;
        p_err_msg_out := 'SUCCESS';
      END IF;

    END IF;
    --Performance Fix
    OPEN c_adj_bal_out FOR
      SELECT l_acct_type_in account_type,
             to_char(nvl(cam_ledger_bal,
                         0),
                     '9,999,999,990.99') ledger_balance,
             to_char(nvl(cam_acct_bal,
                         0),
                     '9,999,999,990.99') available_balance
        FROM vmscms.cms_acct_mast
       WHERE cam_acct_no = l_acct_no
         AND cam_inst_code = 1;

    UPDATE vmscms.transactionlog
       SET correlation_id =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-correlationid')),
           fsapi_username =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-username')),
           partner_id    =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-partnerid'))
     WHERE rrn = l_rrn;

    --Performance Fix
    SELECT MAX(ccd_call_seq)
      INTO l_call_seq
      FROM cms_calllog_details
     WHERE ccd_acct_no = l_acct_no
       AND ccd_inst_code = 1
       AND ccd_rrn = l_rrn
       AND ccd_call_id = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-sessionid'));

    --Jira Issue: CFIP:187 starts
    --Performance Fix
    UPDATE vmscms.cms_calllog_details
       SET ccd_fsapi_username =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-username'))
     WHERE ccd_acct_no = l_acct_no
       AND ccd_inst_code = 1
       AND ccd_rrn = l_rrn
       AND ccd_call_id = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-sessionid'))
       AND ccd_call_seq = l_call_seq;

    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 1000 ||
                    ' secs');

  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_adj_bal_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_adj_bal_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

    --Jira Issue: CFIP:188 starts
    --updating the below fields manually
    --since the base procedure doesnot populate these fields in Transactionlog

  END adjust_balance;

  -- the init procedure is private and should ALWAYS exist
  PROCEDURE init IS
  BEGIN
    -- initialize all errors here
    g_err_nodata       := fsfw.fserror_t('E-NO-DATA',
                                         '$1 $2');
    g_err_unknown      := fsfw.fserror_t('E-UNKNOWN',
                                         'Unknown error: $1 $2',
                                         'NOTIFY');
    g_err_mandatory    := fsfw.fserror_t('E-MANDATORY',
                                         'Mandatory Field is NULL: $1 $2 $3',
                                         'NOTIFY');
    g_err_invalid_data := fsfw.fserror_t('E-INVALID_DATA',
                                         'ACCOUNT TYPE: $1 $2 $3');
    g_err_savingacc    := fsfw.fserror_t('E-FETCH-SAVINGACC',
                                         'Fetch saving acc details: $1 $2 $3');
    g_err_feewaiver    := fsfw.fserror_t('E-FEEWAIVER',
                                         'Fee waiver calculation: $1 $2 $3');
    g_err_failure      := fsfw.fserror_t('E-FAILURE',
                                         'Procedure failed: $1 $2 $3');
    -- load configuration elements
    g_config := fsfw.fsconfig.get_configuration($$PLSQL_UNIT);
    IF g_config.exists(fsfw.fsconst.c_debug)
    THEN
      g_debug := fsfw.fsdebug_t($$PLSQL_UNIT,
                                g_config(fsfw.fsconst.c_debug));
    ELSE
      g_debug := fsfw.fsdebug_t($$PLSQL_UNIT,
                                '');
    END IF;

    -- Load predefined arrays used inside the procedures
    --Commandad since we get the description from master table

--    g_device_type_tab('00') := 'Unknown';
--    g_device_type_tab('01') := 'Mobile Phone';
--    g_device_type_tab('02') := 'Tablet';
--    g_device_type_tab('03') := 'Watch';
--    g_device_type_tab('04') := 'Mobile Phone or Tablet';
--
--    g_token_type_tab('CF') := 'Card on File';
--    g_token_type_tab('SE') := 'Secure Element';
--    g_token_type_tab('HC') := 'Host Based, Cloud';
--    g_token_type_tab('01') := 'ECOM/COF (e-commerce/card on file)';
--    g_token_type_tab('02') := 'SE (secure element)';
--    g_token_type_tab('03') := 'CBP (cloud-based payment)';
--    g_token_type_tab('05') := 'E-commerce enabler';

    g_debug.display('in init');
    FOR l_rec IN (SELECT a.vts_token_stat, a.vts_status_desc
                    FROM vmscms.vms_token_status a)
    LOOP
      g_token_status_tab(l_rec.vts_token_stat) := l_rec.vts_status_desc;
    END LOOP;
    g_debug.display('after for in init');

  END init;

  -- the get_cpp_context function returns the value of the specific
  -- context value set in the application context for the GPP application

  FUNCTION get_gpp_context(p_name_in IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                       p_name_in));
  END get_gpp_context;

BEGIN
  -- Initialization
  init;
END gpp_accounts;
/
Show error;