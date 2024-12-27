CREATE OR REPLACE PACKAGE BODY VMSCMS.GPP_CARDS IS
  -- PL/SQL Package using FS Framework
  -- Author  : Rojalin
  -- Created : 9/11/2015 5:38:50 PM
  -- Private type declarations
  -- TEST 1
  -- Private constant declarations
  -- Private variable declarations
  -- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;
  --declare all FS errors here
  g_err_nodata           fsfw.fserror_t;
  g_err_failure          fsfw.fserror_t;
  g_err_unknown          fsfw.fserror_t;
  g_err_mandatory        fsfw.fserror_t;
  g_err_invalid_data     fsfw.fserror_t;
  g_err_upd_token_status fsfw.fserror_t; --CFIP-416
  -- Function and procedure implementations
  -- the init procedure is private and should ALWAYS exist

/***************************************************************************************
         * Modified By        : Vini Pushkaran
         * Modified Date      : 09-Jan-2019
         * Modified Reason    : Modified to handle the fee waiver flag (Boolean value) correctly
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 09-Jan-2019
         * Build Number       : R11_B0001
         ****************************************
         * Modified By        : Raj Devkota
         * Modified Date      : 19-May-2021
         * Modified Reason    : VMS-4023 Enable push notification for B2B card replacement for CCA
         * Reviewer           : Ubaidur
         * Reviewed Date      : 19-May-2021
         * Build Number       : R47_B0001
***************************************************************************************/

  PROCEDURE get_cvvplus_info(p_customer_id_in               IN VARCHAR2,
                             p_cvvplus_token_out            OUT vmscms.vms_cvvplus_info.vci_cvvplus_token%TYPE,
                             p_cvvplus_accountid_out        OUT vmscms.vms_cvvplus_info.vci_cvvplus_accountid%TYPE,
                             p_cvvplus_registration_id_out  OUT vmscms.vms_cvvplus_info.vci_cvvplus_registration_id%TYPE,
                             p_cvvplus_email_contactid_out  OUT vmscms.vms_cvvplus_info.vci_cvvplus_email_contactid%TYPE,
                             p_cvvplus_mobile_contactid_out OUT vmscms.vms_cvvplus_info.vci_cvvplus_mobile_contactid%TYPE,
                             p_cvvplus_codeprofile_id_out   OUT vmscms.vms_cvvplus_info.vci_cvvplus_codeprofile_id%TYPE,
                             p_status_out                   OUT VARCHAR2,
                             p_err_msg_out                  OUT VARCHAR2) AS
    l_cust_code  vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_acct_no    vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_plain_pan  VARCHAR2(20);
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;

    c_api_name CONSTANT VARCHAR2(50) := 'GET_CVVPLUS_INFO';
  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_acct_no);
    -- Get customer code from cms_cust_mast
    SELECT a.ccm_cust_code
      INTO l_cust_code
      FROM vmscms.cms_cust_mast a
     WHERE a.ccm_cust_id = p_customer_id_in;

    SELECT b.cam_acct_no
      INTO l_acct_no
      FROM vmscms.cms_acct_mast b,
           vmscms.cms_cust_acct c
     WHERE c.cca_inst_code = b.cam_inst_code
       AND c.cca_acct_id = b.cam_acct_id
       AND c.cca_inst_code = 1
       AND c.cca_cust_code = l_cust_code
       AND b.cam_type_code = '1'; -- Spending

    -- get the required info from VMS_CVVPLUS_INFO
    SELECT vci_cvvplus_token,
           vci_cvvplus_accountid,
           vci_cvvplus_registration_id,
           vci_cvvplus_email_contactid,
           vci_cvvplus_mobile_contactid,
           vci_cvvplus_codeprofile_id
      INTO p_cvvplus_token_out,
           p_cvvplus_accountid_out,
           p_cvvplus_registration_id_out,
           p_cvvplus_email_contactid_out,
           p_cvvplus_mobile_contactid_out,
           p_cvvplus_codeprofile_id_out
      FROM vmscms.vms_cvvplus_info c
     WHERE c.vci_cvvplus_acct_no = l_acct_no;

    l_end_time  := dbms_utility.get_time;
    l_timetaken := (l_end_time - l_start_time);

    p_status_out  := vmscms.gpp_const.c_success_status;
    p_err_msg_out := 'SUCCESS';
  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(c_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(c_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_update_card_status;
      g_err_unknown.raise(c_api_name || ' FAILED',
                          vmscms.gpp_const.c_update_card_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(c_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
  END get_cvvplus_info;

   PROCEDURE update_card_status (p_customer_id_in IN VARCHAR2,
                               p_type_in        IN VARCHAR2,
                               p_value_in       IN VARCHAR2,
                               p_pan_in         IN VARCHAR2,
                               p_postalcode_in  IN VARCHAR2,
                               p_eff_date_in    IN VARCHAR2,
                               p_comment_in     IN VARCHAR2,
                               --CFIP-416 starts
                               p_istoken_eligible_out   OUT VARCHAR2,
                               p_iscvvplus_eligible_out OUT VARCHAR2,
                               p_cardno_out             OUT VARCHAR2,
                               p_exprydate_out          OUT VARCHAR2,
                               p_token_dtls_out         OUT SYS_REFCURSOR,
                               --CFIP-416 ends
                               p_status_out  OUT VARCHAR2,
                               p_err_msg_out OUT VARCHAR2,
							   p_reason_code_in IN VARCHAR2 default null) AS

/********************************************************************************************
     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 17-JUN-2019
     * Purpose          : VMS-958(Enhance CCA to support cardholder data search for Rewards products)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R17

     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 27-Sep-2021
     * Purpose          : VMS-5244- CCA Reject Replacement Request if Card was Put on Hold via New Hold API.
     * Reviewer         : Saravanakumar A
     * Release Number   : CCA_R53B3

	 * Modified By      : Ubaidur Rahman H
     * Modified Date    : 07-Mar-2022
     * Purpose          : VMS-5589- Update Closed Logic on VMS
     * Reviewer         : Saravanakumar A
     * Release Number   : CCA_R60B1

	 * Modified By      : John G
     * Modified Date    : 28-May-2024
     * Purpose          : VMS-8761 - Decline Activations with No Initial Funds
     * Reviewer         :
     * Release Number   : VMSGPRHOST_R98

********************************************************************************************/
    l_date                 VARCHAR2(50);
    l_time                 VARCHAR2(20);
    l_api_name             VARCHAR2(50) := 'UPDATE CARD STATUS';
    l_field_name           VARCHAR2(50);
    l_flag                 PLS_INTEGER := 0;
    l_value                VARCHAR2(50);
    l_hash_pan             vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan             vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_plain_pan            VARCHAR2(20);
    l_partner_id           vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_rrn                  vmscms.transactionlog.rrn%TYPE;
    l_adj_rrn                  vmscms.transactionlog.rrn%TYPE;
    l_cap_startercard_flag vmscms.cms_appl_pan.cap_startercard_flag%TYPE;
    l_cap_card_stat        vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_ccm_kyc_flag         vmscms.cms_cust_mast.ccm_kyc_flag%TYPE;
    l_acct_no              vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_mbr_numb             vmscms.cms_appl_pan.cap_mbr_numb%TYPE;
    l_curr_name            vmscms.gen_curr_mast.gcm_curr_name%TYPE;
    l_prod_code            vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_cust_code            vmscms.cms_appl_pan.cap_cust_code%TYPE;
    l_call_seq             vmscms.cms_calllog_details.ccd_call_seq%TYPE;
    l_eff_date             VARCHAR2(10);
    l_reason_code          VARCHAR2(10);
    l_start_time           NUMBER;
    l_end_time             NUMBER;
    l_timetaken            NUMBER;
    --CFIP-416 starts
    l_check_tokens        NUMBER;
    l_action              VARCHAR2(10) := 'U';
    l_exprydate           vmscms.cms_appl_pan.cap_expry_date%TYPE;
    l_exprydate_tln       vmscms.cms_appl_pan.cap_expry_date%TYPE;
    l_card_type           vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_token_eligibility   vmscms.cms_prod_cattype.cpc_token_eligibility%TYPE;
    l_cvvplus_eligibility vmscms.cms_prod_cattype.cpc_cvvplus_eligibility%TYPE;
    l_encrypt_enable      vmscms.cms_prod_cattype.cpc_encrypt_enable%TYPE;
    l_postalcode_in       vmscms.cms_addr_mast.cam_pin_code%TYPE;
    l_status_update_event vmscms.cms_appl_pan.cap_status_update_event%TYPE;
	l_final_bal     	  vmscms.cms_acct_mast.cam_acct_bal%TYPE;
	l_acct_bal		      vmscms.cms_acct_mast.cam_acct_bal%TYPE;
	l_ledger_bal		  vmscms.cms_acct_mast.cam_ledger_bal%TYPE;
	l_5589_toggle         vmscms.cms_inst_param.cip_param_value%TYPE;
    l_adj_txn_code        vmscms.cms_transaction_mast.ctm_tran_code%TYPE;
    l_resp_code           VARCHAR2(5);
        l_resp_msg            VARCHAR2(500);
    --CFIP-416 ends
    L_REPL_FLAG           vmscms.cms_appl_pan.CAP_REPL_FLAG%TYPE;
    L_PRODUCT_PORTFOLIO   vmscms.cms_prod_cattype.CPC_PRODUCT_PORTFOLIO%TYPE;
    L_INITIALLOAD_AMT     vmscms.cms_acct_mast.CAM_INITIALLOAD_AMT%TYPE;
    l_ordr_prod_fund      vms_order_lineitem.vol_product_funding%type;
    l_litem_denom         vms_order_lineitem.vol_denomination%type;
    l_ordr_fund_amt       vms_order_lineitem.vol_fund_amount%TYPE;
  BEGIN
    --CFIP-416 starts
    p_istoken_eligible_out   := 'FALSE';
    p_iscvvplus_eligible_out := 'FALSE';
    --CFIP-416 ends
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));

    --Check for madatory fields
    --l_partner_id := '1'; -- for testing
    CASE
      WHEN p_customer_id_in IS NULL THEN
        l_field_name := 'CUSTOMER ID';
        l_flag       := 1;
      WHEN p_type_in IS NULL THEN
        l_field_name := 'TYPE';
        l_flag       := 1;
      WHEN p_value_in IS NULL THEN
        l_field_name := 'VALUE';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;
    g_debug.display('In update card' || p_customer_id_in);
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
    ---Fetching the active PAN
    g_debug.display('before p_pan_in' || p_pan_in);
    IF p_pan_in IS NULL
    THEN
      --Fetching the active PAN for the input customer id
      g_debug.display('pan is null' || p_pan_in);
      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_acct_no);
      g_debug.display('l_acct_no' || l_acct_no);
    ELSE
      BEGIN
        -- Performance Fix
        SELECT cap_pan_code,
               cap_pan_code_encr,
               cap_acct_no,
               cap_startercard_flag,
               cap_card_stat,
               cap_mbr_numb,
               cap_prod_code,
               cap_cust_code,
               cap_card_type, --CFIP-416
               cap_expry_date, --CFIP-416
               nvl(cap_cvvplus_reg_flag,
                   'N'), --CFIP-416
               nvl(cap_status_update_event,
                 'N'),
                 CAP_REPL_FLAG --VMS-8761
          INTO l_hash_pan,
               l_encr_pan,
               l_acct_no,
               l_cap_startercard_flag,
               l_cap_card_stat,
               l_mbr_numb,
               l_prod_code,
               l_cust_code,
               l_card_type, --CFIP-416
               l_exprydate, --CFIP-416
               l_cvvplus_eligibility, --CFIP-416
               l_status_update_event,
               L_REPL_FLAG --VMS-8761
          FROM (SELECT cap_pan_code,
                       cap_pan_code_encr,
                       cap_acct_no,
                       cap_startercard_flag,
                       cap_card_stat,
                       cap_mbr_numb,
                       cap_prod_code,
                       cap_cust_code,
                       cap_card_type, --CFIP-416
                       cap_expry_date, --CFIP-416
                       cap_cvvplus_reg_flag, --CFIP-416
                       cap_status_update_event,
                       CAP_REPL_FLAG --VMS-8761
                  FROM vmscms.cms_appl_pan
                 WHERE cap_cust_code =
                       (SELECT ccm_cust_code
                          FROM vmscms.cms_cust_mast
                         WHERE ccm_cust_id = to_number(p_customer_id_in)
                              --AND ccm_partner_id IN (l_partner_id)
                           AND ccm_prod_code || ccm_card_type =
                               vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                        p_prod_code_in  => ccm_prod_code,
                                                                        p_card_type_in  => ccm_card_type))
                   AND cap_inst_code = 1
                      --AND cap_mask_pan LIKE ('%' || p_pan_in || '%')  -- Performance Fix
                      -- AND substr(cap_mask_pan,
                      --    length(cap_mask_pan) - 3) = p_pan_in
                   AND substr(vmscms.fn_dmaps_main(cap_pan_code_encr),
                              length(vmscms.fn_dmaps_main(cap_pan_code_encr)) - 3) =
                       p_pan_in
                   AND cap_active_date IS NOT NULL
                   AND cap_card_stat NOT IN ('9')
                 ORDER BY cap_active_date DESC)
         WHERE rownum < 2;
        g_debug.display('test_tamil_select1' || l_hash_pan || l_encr_pan ||
                        l_acct_no);
      EXCEPTION
        WHEN no_data_found THEN
          SELECT cap_pan_code,
                 cap_pan_code_encr,
                 cap_acct_no,
                 cap_startercard_flag,
                 cap_card_stat,
                 cap_mbr_numb,
                 cap_prod_code,
                 cap_cust_code,
                 cap_card_type, --CFIP-416
                 cap_expry_date, --CFIP-416
                 nvl(cap_cvvplus_reg_flag,
                     'N'), --CFIP-416
                nvl(cap_status_update_event,
                 'N'),
                 CAP_REPL_FLAG --VMS-8761
            INTO l_hash_pan,
                 l_encr_pan,
                 l_acct_no,
                 l_cap_startercard_flag,
                 l_cap_card_stat,
                 l_mbr_numb,
                 l_prod_code,
                 l_cust_code,
                 l_card_type, --CFIP-416
                 l_exprydate, --CFIP-416
                 l_cvvplus_eligibility, --CFIP-416
                 l_status_update_event,
                 L_REPL_FLAG --VMS-8761
            FROM (SELECT cap_pan_code,
                         cap_pan_code_encr,
                         cap_acct_no,
                         cap_startercard_flag,
                         cap_card_stat,
                         cap_mbr_numb,
                         cap_prod_code,
                         cap_cust_code,
                         cap_card_type, --CFIP-416
                         cap_expry_date, --CFIP-416
                         cap_cvvplus_reg_flag, --CFIP-416
                         cap_status_update_event,
                         CAP_REPL_FLAG --VMS-8761
                    FROM vmscms.cms_appl_pan
                   WHERE cap_cust_code =
                         (SELECT ccm_cust_code
                            FROM vmscms.cms_cust_mast
                           WHERE ccm_cust_id = to_number(p_customer_id_in)
                                --AND ccm_partner_id IN (l_partner_id)
                             AND ccm_prod_code || ccm_card_type =
                                 vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                          p_prod_code_in  => ccm_prod_code,
                                                                          p_card_type_in  => ccm_card_type))
                     AND cap_inst_code = 1
                        -- AND cap_mask_pan LIKE ('%' || p_pan_in || '%')   -- Performance Fix
                        -- AND substr(cap_mask_pan,
                        --            length(cap_mask_pan) - 3) = p_pan_in
                     AND substr(vmscms.fn_dmaps_main(cap_pan_code_encr),
                                length(vmscms.fn_dmaps_main(cap_pan_code_encr)) - 3) =
                         p_pan_in
                   ORDER BY cap_pangen_date DESC)
           WHERE rownum < 2;
      END;
    END IF;
    g_debug.display('test_tamil_select1_nodataquery' || l_hash_pan ||
                    l_encr_pan || l_acct_no);
    l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);
    g_debug.display('l_encr_pan' || l_encr_pan);
    g_debug.display('l_plain_pan' || l_plain_pan);
    --getting the date
    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);
    --l_date := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11);
    l_date := to_char(to_date(l_date,
                              'dd-mm-yyyy'),
                      'yyyymmdd');
    --getting the time
    l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-date')),
                     18,
                     8);
    -- l_time := '08:49:39';
    l_time := REPLACE(l_time,
                      ':',
                      '');
    g_debug.display('l_date' || l_date);
    g_debug.display('l_time' || l_time);
    --getting the value
    CASE upper(p_value_in)
      WHEN 'CARD ACTIVATION' THEN
        l_value       := '74';
        l_reason_code := 60;
        l_action      := 'A'; --CFIP-416
      WHEN 'CARD LOST-STOLEN' THEN
        l_value       := '75';
        l_reason_code := 2;
      WHEN 'CARD DAMAGE' THEN
        l_value       := '78';
        l_reason_code := 3;
      WHEN 'CARD BLOCK' THEN
        l_value       := '76';
        l_reason_code := 62;
      WHEN 'MONITORED CARD' THEN
        l_value       := '84';
        l_reason_code := 5;
      WHEN 'HOT CARDED' THEN
        l_value       := '85';
        l_reason_code := 6;
      WHEN 'RETURNED MAIL' THEN
        l_value       := '86';
        l_reason_code := 12;
      WHEN 'ORDER REPLACEMENT CARD' THEN
        l_value       := '16';
        l_reason_code := NULL;
      WHEN 'RESTRICTED CARD' THEN
        l_value       := '87';
        l_reason_code := 4;
      WHEN 'CARD EXPIRED' THEN
        l_value       := '79';
        l_reason_code := 106;
      WHEN 'CARD SPEND DOWN' THEN
        l_value       := '80';
        l_reason_code := 109;
      WHEN 'CARD STATUS CHANGE TO INACTIVE' THEN
        l_value       := '81';
        l_reason_code := 110;
      WHEN 'CARD STATUS UPDATE_CLOSE' THEN
        l_value       := '83';
        l_reason_code := 9;
      WHEN 'CARD BAD CREDIT' THEN
        l_value       := '61';
        l_reason_code := 251;
      WHEN 'CARD ON HOLD' THEN
        l_value       := '62';
        l_reason_code := 105;
      WHEN 'FRAUD HOLD' THEN
        l_value       := '51';
        l_reason_code := 141;
      WHEN 'CARD CONSUMED' THEN
        l_value       := '82';
        l_reason_code := 250;
      WHEN 'RISK INVESTIGATION' THEN
        l_value       := '99';
        l_reason_code := 254;
      ELSE
        NULL;
    END CASE;
    g_debug.display('l_value' || l_value);
    --getting the rrn
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);
    ---validation for postal code --JIRA Issue CFIP:201 starts
    --Whether the card is a starter card in inactive status
    IF p_pan_in IS NULL
    THEN
      SELECT cap_startercard_flag,
             cap_card_stat,
             cap_mbr_numb,
             cap_prod_code,
             cap_acct_no,
             cap_card_type, --CFIP-416
             cap_expry_date, --CFIP-416
             nvl(cap_cvvplus_reg_flag,
                 'N'), --CFIP-416
             nvl(cap_status_update_event,
                 'N'),
			 cap_pan_code_encr,
			 CAP_REPL_FLAG --VMS-8761
        INTO l_cap_startercard_flag,
             l_cap_card_stat,
             l_mbr_numb,
             l_prod_code,
             l_acct_no,
             l_card_type, --CFIP-416
             l_exprydate, --CFIP-416
             l_cvvplus_eligibility, --CFIP-416
             l_status_update_event,
			 l_encr_pan,
			 L_REPL_FLAG --VMS-8761
        FROM vmscms.cms_appl_pan
       WHERE cap_pan_code = l_hash_pan;
    END IF;
    g_debug.display('l_cap_startercard_flag' || l_cap_startercard_flag);
    g_debug.display('l_cap_card_stat' || l_cap_card_stat);

    --- Added for VMS-5244

    IF l_cap_card_stat = '6' and l_status_update_event = 'B2B_CARD_HOLD'
    THEN

    p_status_out  :='14';
    p_err_msg_out :='Status Update not Permitted for Hold Card made by B2B_CARD_HOLD API' ;

    vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   '14',
                                                   NULL,
                                                   l_timetaken);
     RETURN;

    END IF;

    --Performance Fix - queries commented below
    --      SELECT ccm_kyc_flag
    --        INTO l_ccm_kyc_flag
    --        FROM vmscms.cms_cust_mast
    --       WHERE ccm_cust_id = p_customer_id_in;
    --      g_debug.display('l_ccm_kyc_flag' || l_ccm_kyc_flag);
    --fetching the mbr number
    --      SELECT cap_mbr_numb
    --        INTO l_mbr_numb
    --        FROM vmscms.cms_appl_pan
    --       WHERE cap_pan_code = l_hash_pan;
    g_debug.display('l_mbr_numb' || l_mbr_numb);

    --CFIP-416 starts
    p_cardno_out := l_plain_pan;
    --    p_exprydate_out := to_char(l_exprydate,
    --                               'MMYY');

	SELECT cbp_param_value
        INTO l_curr_name
        FROM vmscms.cms_prod_cattype,
             vmscms.cms_bin_param
       WHERE cpc_inst_code = cbp_inst_code
         AND cpc_profile_code = cbp_profile_code
         AND cpc_prod_code = l_prod_code
         AND cpc_card_type = l_card_type
         AND cpc_inst_code = 1
         AND cbp_param_name = 'Currency';

    SELECT nvl(cpc_token_eligibility,
               'N'),
           cpc_encrypt_enable,
    --nvl(cpc_cvvplus_eligibility,
    --  'N')
           CPC_PRODUCT_PORTFOLIO
      INTO l_token_eligibility,
           l_encrypt_enable, --, l_cvvplus_eligibility
           L_PRODUCT_PORTFOLIO --VMS-8761
      FROM vmscms.cms_prod_cattype
     WHERE cpc_inst_code = 1
       AND cpc_prod_code = l_prod_code
       AND cpc_card_type = l_card_type;

    IF l_token_eligibility = 'Y'
    THEN
      p_istoken_eligible_out := 'TRUE';
    END IF;

    IF l_cvvplus_eligibility = 'Y'
    THEN
      p_iscvvplus_eligible_out := 'TRUE';
    END IF;
    --CFIP-416 ends

    --Updating Effective Date

	IF l_value  = '83'    --- Request for Card Closure
	THEN
			BEGIN
				SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
					INTO l_5589_toggle
					FROM vmscms.cms_inst_param
				   WHERE cip_inst_code = 1
					 AND cip_param_key = 'VMS_5589_TOGGLE';
		   EXCEPTION
				WHEN OTHERS THEN
					l_5589_toggle :='N';
			END;

			IF l_5589_toggle='Y' THEN

					SELECT cam_acct_bal,cam_ledger_bal
					  INTO l_acct_bal,l_ledger_bal
					FROM vmscms.CMS_ACCT_MAST
					WHERE cam_inst_code = 1
					AND cam_acct_no = l_acct_no;


					IF l_acct_bal = l_ledger_bal
					THEN

						 IF l_acct_bal < 0
						THEN
						l_acct_bal := ABS(l_acct_bal);
						l_adj_txn_code := '14';
						ELSIF l_acct_bal > 0
                        THEN
						l_adj_txn_code := '13';
						END IF;



					ELSE

						p_status_out  :='14';
						p_err_msg_out :='Cannot Close Card due to Pending Auths.' ;

						vmscms.gpp_transaction.audit_transaction_log(l_api_name,
																	p_customer_id_in,
																	l_hash_pan,
																	l_encr_pan,
																	'F',
																	p_err_msg_out,
																	'14',
																	NULL,
																	l_timetaken);
					RETURN;


					END IF;

			IF l_acct_bal <> 0
			THEN

           SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
             INTO l_adj_rrn
            FROM dual;

				BEGIN
					vmscms.sp_manual_adj_csr(1,
											 l_mbr_numb,
											 '0200',
											 '03',
											 l_adj_txn_code,
											 '0',
											 l_date,
											 l_time,
											 vmscms.fn_dmaps_main(l_encr_pan),
											 l_adj_rrn,
											 NULL,
											 l_acct_bal,
											 p_reason_code_in,
											 p_comment_in,
											 0,
											 l_curr_name,
											 NULL,
											 NULL,
											 (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
													'x-incfs-sessionid')),
											 l_acct_no,
											 1,
											  (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
														   'x-incfs-ip')),
											 1,
											 NULL,
											 l_final_bal,
											 l_resp_code,
											 l_resp_msg);

			  IF l_resp_msg <> 'OK' AND l_resp_code <> '00'
              THEN
                p_status_out := l_resp_code;
                p_err_msg_out := 'Balance Adjustment while Card Closure ' ||
                                 'CUSTOMER ID ' || p_customer_id_in ||
                                 ', Error: ' || l_resp_msg;
                vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                             p_customer_id_in,
                                                             l_hash_pan,
                                                             l_encr_pan,
                                                             'F',
                                                             p_err_msg_out,
                                                             p_status_out,
                                                             NULL,
                                                             l_timetaken);
					RETURN;
              END IF;

			  EXCEPTION
					WHEN OTHERS THEN
					  g_debug.display('Exception in Adjust Balance');
					  p_status_out  := '16';
					  p_err_msg_out := 'Exception in Adjust Balance while Card Closure '|| l_resp_msg;

					  vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                             p_customer_id_in,
                                                             l_hash_pan,
                                                             l_encr_pan,
                                                             'F',
                                                             p_err_msg_out,
                                                             p_status_out,
                                                             NULL,
                                                             l_timetaken);
					RETURN;

				  END;

			END IF;  --- Bal >0 Condition Closure
	  END IF; --toggle condition closure
	END IF;    ---- l_value '83' Condition Closure

    --Added for VMS-8761
    IF     l_value = '74'
       AND L_REPL_FLAG = '0'
       AND L_PRODUCT_PORTFOLIO IN ('B2B (SINGLE LOAD)',
                                   'B2B (RELOADABLE)',
                                   'SLG',
                                   'SLG RAN',
                                   'SLG RAN/PL')
    THEN
        SELECT CAM_INITIALLOAD_AMT
          INTO L_INITIALLOAD_AMT
          FROM vmscms.CMS_ACCT_MAST
         WHERE cam_inst_code = 1 AND cam_acct_no = l_acct_no;

        IF l_initialload_amt = 0 THEN
            BEGIN
                SELECT TO_NUMBER (NVL (l_item.vol_denomination, '0')),
                       l_item.vol_product_funding,
                       l_item.vol_fund_amount
                  INTO l_litem_denom,
                       l_ordr_prod_fund,
                       l_ordr_fund_amt
                  FROM vmscms.vms_line_item_dtl dtls, vmscms.vms_order_lineitem l_item
                 WHERE     dtls.vli_order_id = l_item.vol_order_id
                       AND dtls.vli_partner_id = l_item.vol_partner_id
                       AND dtls.vli_lineitem_id = l_item.vol_line_item_id
                       AND dtls.vli_pan_code = l_hash_pan;
            EXCEPTION
              WHEN OTHERS THEN
                NULL;
            END;

            --Sn: Added for VMS-9058
            IF l_ordr_prod_fund = 2 AND l_ordr_fund_amt =2
            THEN
                p_status_out := '222';
                p_err_msg_out := 'Activation through CCA is not supported for this product';

                vmscms.gpp_transaction.audit_transaction_log (l_api_name,
                                                              p_customer_id_in,
                                                              l_hash_pan,
                                                              l_encr_pan,
                                                              'F',
                                                              p_err_msg_out,
                                                              p_status_out,
                                                              NULL,
                                                              l_timetaken);
                RETURN;
            END IF;
            --En: Added for VMS-9058

            IF l_ordr_prod_fund = 2 AND l_ordr_fund_amt =1 AND l_litem_denom > 0 THEN
               l_initialload_amt:= l_litem_denom;
            END IF;
        END IF;

        IF L_INITIALLOAD_AMT = '0'
        THEN
            p_status_out := '222';
            p_err_msg_out := 'Declined activation due to no initial funds';

            vmscms.gpp_transaction.audit_transaction_log (l_api_name,
                                                          p_customer_id_in,
                                                          l_hash_pan,
                                                          l_encr_pan,
                                                          'F',
                                                          p_err_msg_out,
                                                          p_status_out,
                                                          NULL,
                                                          l_timetaken);
            RETURN;
        END IF;
    END IF;

    IF p_eff_date_in IS NOT NULL
       AND upper(p_value_in) IN ('CARD ACTIVATION',
                                 'CARD STATUS UPDATE_CLOSE',
                                 'CARD BLOCK',
                                 'HOT CARDED')
    THEN
      INSERT INTO vmscms.cms_chngcardstat_req
        (ccr_inst_code,
         ccr_del_chnl,
         ccr_txn_code,
         ccr_rrn,
         ccr_pan_code,
         ccr_pan_code_encr,
         ccr_mbr_numb,
         ccr_acct_no,
         ccr_business_date,
         ccr_business_time,
         ccr_reason_code,
         ccr_remark,
         ccr_req_callid,
         ccr_ip_addr,
         ccr_process_date,
         ccr_status,
         ccr_email_status,
         ccr_ins_date,
         ccr_ins_user,
         ccr_lupd_date,
         ccr_lupd_user,
         ccr_process_msg)
      VALUES
        (1,
         '03',
         l_value,
         l_rrn,
         l_hash_pan,
         l_encr_pan,
         l_mbr_numb,
         l_acct_no,
         l_date,
         l_time,
         NULL,
         p_comment_in,
         (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                      'x-incfs-sessionid')),
         (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                      'x-incfs-ip')),
         to_char(to_date(p_eff_date_in,
                         'YYYY-MM-DD'),
                 'DD-MON-YYYY'),
         'N',
         'N',
         SYSDATE,
         NULL,
         SYSDATE,
         NULL,
         NULL);
    ELSE
      ---validation for postal code --JIRA Issue CFIP:201 ends
      --updating the card
      IF upper(p_type_in) = 'CARDSTATUS'
      THEN
        g_debug.display('sp_chnge_crdstat_csr');
        vmscms.sp_chnge_crdstat_csr(1,
                                    l_rrn,
                                    l_plain_pan,
                                    NULL, --NULL, -- PRM_LUPDUSER
                                    l_value,
                                    '03',
                                    '0200',
                                    '0',
                                    '0',
                                    l_mbr_numb, --'000' Performance Fix
                                    l_date,
                                    l_time,
                                    l_reason_code, --p_rsc_Code
                                    p_comment_in,
                                    (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                 'x-incfs-sessionid')), ---prm_call_id,
                                    (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                 'x-incfs-ip')),
                                    'N',
                                    NULL,
                                    'Y', --Y indicates sysadmin role
                                    p_status_out,
                                    p_err_msg_out);
        g_debug.display('p_status_out' || p_status_out);
        g_debug.display('p_err_msg_out' || p_err_msg_out);
        --Jira Issue: CFIP:188 starts
        --updating the below fields manually
        --since the base procedure doesnot populate these fields in Transactionlog
        --CFIP-416 starts
        IF p_err_msg_out = 'OK'
        THEN
          SELECT COUNT(*)
            INTO l_check_tokens
            FROM vmscms.vms_token_info
           WHERE vti_acct_no = l_acct_no
             AND vti_token_stat <> 'D';

          IF l_check_tokens > 0
          THEN
            g_debug.display('inside token check');
            BEGIN
              vmscms.gpp_tokens.update_token_status(l_hash_pan,
                                                    l_hash_pan,
                                                    l_action,
                                                    l_action,
                                                    p_cardno_out,
                                                    p_exprydate_out,
                                                    p_token_dtls_out,
                                                    p_err_msg_out);

              IF p_err_msg_out <> 'OK'
              THEN
                p_status_out := vmscms.gpp_const.c_ora_error_status;
                g_err_upd_token_status.raise(l_api_name,
                                             'CUSTOMER ID ' ||
                                             p_customer_id_in,
                                             vmscms.gpp_const.c_ora_error_status);
                p_err_msg_out := 'Update Tokens failed for ' ||
                                 'CUSTOMER ID ' || p_customer_id_in ||
                                 ', Error: ' || p_err_msg_out;
                vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                             p_customer_id_in,
                                                             l_hash_pan,
                                                             l_encr_pan,
                                                             'F',
                                                             p_err_msg_out,
                                                             vmscms.gpp_const.c_failure_res_id,
                                                             NULL,
                                                             l_timetaken);
              END IF;
            END;
          END IF;
        END IF;
        --CFIP-416 ends

        UPDATE VMSCMS.TRANSACTIONLOG
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
   --Added for VMS-5733/FSP-991
     IF SQL%ROWCOUNT = 0 THEN
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
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
    end if;

        --Jira Issue: CFIP:188 ends
      END IF;
    END IF;
    --Updating Postal Code
    IF p_postalcode_in IS NOT NULL
    THEN
      SELECT ccm_kyc_flag
        INTO l_ccm_kyc_flag
        FROM vmscms.cms_cust_mast
       WHERE ccm_cust_code = l_cust_code
         AND ccm_inst_code = 1;
      -- ccm_cust_id = p_customer_id_in;
      g_debug.display('l_ccm_kyc_flag' || l_ccm_kyc_flag);
      --Jira Issue: CFIP:201 starts
      --fetching the currency
      --Performqance change query below updated

      g_debug.display('l_curr_name' || l_curr_name);
      IF l_curr_name = '840' --'USD' Performance Fix
         AND length(p_postalcode_in) <> 5
      THEN
        p_status_out := vmscms.gpp_const.c_invalid_uspostal_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0041,',
                                 'FOR US CARD POSTAL CODE SHOULD BE 5 DIGITS');
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F', --vmscms.gpp_const.c_failure_flag,
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL,
                                                     l_timetaken);
      ELSIF l_curr_name = '124' -- 'CAN' Performance Fix
            AND length(p_postalcode_in) > 7
      THEN
        p_status_out := vmscms.gpp_const.c_invalid_canpostal_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0042,',
                                 'FOR CANDIAN CARD POSTAL CODE SHOULD BE 7 CHARACTERS');
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F', --vmscms.gpp_const.c_failure_flag,
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL,
                                                     l_timetaken);
      END IF;
      IF l_cap_startercard_flag = 'Y'
         AND l_cap_card_stat = '0'
         AND l_ccm_kyc_flag = 'N'
         AND upper(p_value_in) = 'CARD ACTIVATION'
         AND p_status_out = '00'
      THEN
        -- Changes for JIRA CFIP-391 - query tuned
        IF l_encrypt_enable = 'Y'
        THEN
          l_postalcode_in := vmscms.fn_emaps_main(p_postalcode_in);
        ELSE
          l_postalcode_in := p_postalcode_in;
        END IF;

        UPDATE vmscms.cms_addr_mast
           SET cam_pin_code = l_postalcode_in,
               cam_pin_code_encr =  vmscms.fn_emaps_main(p_postalcode_in)            --Added for VMS-958
         WHERE cam_addr_flag = 'P'
           AND cam_inst_code = 1
           AND cam_cust_code IN
               (SELECT ccm_cust_code
                  FROM cms_cust_mast
                 WHERE ccm_cust_id = p_customer_id_in);
      END IF;
    END IF;
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
    --Jira Issue: CFIP:187 ends
    IF p_status_out <> '00'
       AND p_err_msg_out <> 'OK'
    THEN
      p_status_out  := p_status_out;
      p_err_msg_out := p_err_msg_out;
      RETURN;
    ELSE
      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';
    END IF;
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
      p_status_out := vmscms.gpp_const.c_update_card_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_update_card_status);
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
  END update_card_status;

  PROCEDURE replace_card(p_customer_id_in IN VARCHAR2,
                         p_isexpedited_in IN VARCHAR2,
                         p_isfeewaived_in IN VARCHAR2,
                         p_comment_in     IN VARCHAR2,
                         --Sn:Added for VMS-104
                         p_createnewcard_in IN VARCHAR2 DEFAULT 'FALSE',
                         --En:Added for VMS-104
                         --CFIP starts
                         p_loadamounttype_in   IN VARCHAR2,
                         p_loadamount_in          IN VARCHAR2,
                         p_merchantid_in          IN VARCHAR2,
                         p_terminalid_in          IN VARCHAR2,
                         p_locationid_in          IN VARCHAR2,
                         p_merchantbillable_in    IN VARCHAR2,
                         p_activationcode_in      IN VARCHAR2,
                         p_firstname_in           IN VARCHAR2,
                         p_middlename_in          IN VARCHAR2,
                         p_lastname_in            IN VARCHAR2,
                         p_addrone_in             IN VARCHAR2,
                         p_addrtwo_in             IN VARCHAR2,
                         p_city_in                IN VARCHAR2,
                         p_state_in               IN VARCHAR2,
                         p_postalcode_in          IN VARCHAR2,
                         p_countrycode_in         IN VARCHAR2,
                         p_email_in 		      IN VARCHAR2,
                         p_istoken_eligible_out   OUT VARCHAR2,
                         p_iscvvplus_eligible_out OUT VARCHAR2,
                         p_cardno_out             OUT VARCHAR2,
                         p_exprydate_out          OUT VARCHAR2,
                         p_new_cardno_out         OUT VARCHAR2,
                         p_new_exprydate_out      OUT VARCHAR2,
                         p_stan_out               OUT VARCHAR2,
                         p_rrn_out                OUT VARCHAR2,
                         p_activationcode_out     OUT VARCHAR2,
                         p_req_reason_out         OUT VARCHAR2,
                         p_forward_instcode_out   OUT VARCHAR2,
                         p_message_reasoncode_out OUT VARCHAR2,
                         p_new_maskcardno_out     OUT VARCHAR2,
                         p_token_dtls_out         OUT SYS_REFCURSOR,
                         p_status_out             OUT VARCHAR2,
                         p_err_msg_out            OUT VARCHAR2) AS
/********************************************************************************************
     * Modified By      : VINI PUSHKARAN
     * Modified Date    : 07-MAR-2019
     * Purpose          : VMS-810(Replacement Processing: Emboss Line 3 and Emboss Line 4)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R13_B0004

     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 03-APR-2019
     * Purpose          : VMS-846(Replacement Not allowed for digital products)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R14_B0004

	 * Modified By      : Ubaidur Rahman H
     * Modified Date    : 25-APR-2019
     * Purpose          : VMS-895(AMEX Retail Card replacements are failing with "NO DATA FOUND" from CCA)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R14.1

     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 17-JUN-2019
     * Purpose          : VMS-958(Enhance CCA to support cardholder data search for Rewards products)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R17

     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 02-JUN-2020
     * Purpose          : VMS-2428.
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R31

     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 22-JUN-2021
     * Purpose          : VMS-4559 - Replacement Push Notification (Physical via CCA)-B2B Spec Consolidation.
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R48_B1

          * Modified By      : Ubaidur Rahman H
     * Modified Date    : 22-JUN-2021
     * Purpose          : VMS-4484- Support Virtual Card Replacement via CCA--B2B Spec Consolidation
     * Purpose          : VMS-4509- Replacement Push Notification (Virtual via CCA)--B2B Spec Consolidation
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R48_B2

     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 28-JUL-2021
     * Purpose          : VMS-4633- Update Address/Email for CCA initiated Replacement--B2B Spec Consolidation
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R50_B1

     * Modified By      : SanthoshKumar Chigullapally
     * Modified Date    : 24-AUG-2021
     * Purpose          : VMS-4682 - Replacement PushNOtification add LastFourPAN
     * Reviewer         : Puvanesh
     * Release Number   : VMSGPRHOST_R50_B2

     * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 21-SEP-2021
     * Purpose          : VMS-5020 - Email ID missing in ORDER TABLE for Physcial Replacement
     * Reviewer         : Saravana Kumar.A
     * Release Number   : VMSGPRHOST_R52_B1

	 * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 29-09-2021
     * Purpose          : VMS-5015:Virtual Card replacement without address is updating system passed default name & address for Customer Profile.
     * Reviewer         : Saravanakumar A.
     * Build Number     : R52 - BUILD 2

     * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 27-10-2021
     * Purpose          : VMS-5045: Embossing F/L Name during Phhysical Repl via CCA
     * Reviewer         : Saravanakumar A.
     * Build Number     : CCA R53 - BUILD 2
     * Modified By      :  Ubaidur Rahman.H
     * Modified Date    :  03-Dec-2021
     * Modified Reason  :  VMS-5253 / 5372 - Do not pass sytem generated value from VMS to CCA.
     * Reviewer         :  Saravanakumar
     * Build Number     :  VMSGPRHOST_R55_RELEASE

     * Modified By      :  Mohan Kumar.E
     * Modified Date    :  03-Feb-2023
     * Modified Reason  :  VMS-6024  - Replacement Cards Persisting Original Encrypted Data.
     * Reviewer         :  Pankaj Salunkhe
     * Build Number     :  R75 - BUILD 2

	 * Modified By      :  Mohan Kumar.E
     * Modified Date    :  09-Feb-2023
     * Modified Reason  :  VMS-6026  - Replacement Cards Persisting Original PackID Values.
     * Reviewer         :  Pankaj S.

     * Modified By      :  John G
     * Modified Date    :  16-May-2023
     * Modified Reason  :  VMS-7303  - Virtual Card Replacements
     * Reviewer         :  Pankaj S.

********************************************************************************************/
    l_encr_pan                  vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_hash_pan                  vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_acct_no                   vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_prod_code                 vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_mbr_numb                  vmscms.cms_appl_pan.cap_mbr_numb%TYPE;
    l_call_seq                  vmscms.cms_calllog_details.ccd_call_seq%TYPE;
    l_fee_plan                  vmscms.cms_fee_feeplan.cff_fee_plan%TYPE;
    l_card_type                 vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_plain_pan                 VARCHAR2(20);
    l_curr_code                 VARCHAR2(20);
    l_date                      VARCHAR2(20);
    l_time                      VARCHAR2(20);
    l_fee_amt                   VARCHAR2(50);
    l_expiry_date               VARCHAR2(10);
    l_expiry_date_parameter     DATE;
    l_new_expiry_date_parameter DATE;
    l_fee_desc                  vmscms.cms_fee_mast.cfm_fee_desc%TYPE;
    l_feeflag                   VARCHAR2(1);
    l_avail_bal                 VARCHAR2(50);
    l_ledger_bal                VARCHAR2(50);
    l_clawback_flag             vmscms.cms_fee_mast.cfm_clawback_flag%TYPE;
    l_auth_id                   VARCHAR2(20);
    l_resp_code                 VARCHAR2(5);
    l_resp_msg                  VARCHAR2(500);

    l_capture_date              DATE;
    l_api_name                  VARCHAR2(20) := 'REPLACE CARD';
    l_field_name                VARCHAR2(20);
    l_flag                      PLS_INTEGER := 0;
    l_rrn                       vmscms.transactionlog.rrn%TYPE;
    l_partner_id                vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_txn_code                  VARCHAR2(20);
    l_fee_flag                  CHAR(1);
    l_start_time                NUMBER;
    l_end_time                  NUMBER;
    l_timetaken                 NUMBER;
    --CFIP-416 starts
    l_check_tokens          NUMBER;
    l_card_stat             vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_action                VARCHAR2(10);
    l_card_dtls             vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_token_eligibility     vmscms.cms_prod_cattype.cpc_token_eligibility%TYPE;
    l_cvvplus_eligibility   vmscms.cms_prod_cattype.cpc_cvvplus_eligibility%TYPE;
    l_replace_optn          vmscms.cms_prod_cattype.cpc_renew_replace_option%TYPE;
    --CFIP-416 ends
    l_acct_balance          vmscms.cms_acct_mast.cam_acct_bal%TYPE;
    l_ledger_balance        vmscms.cms_acct_mast.cam_ledger_bal%TYPE;
    l_acct_type             vmscms.cms_acct_mast.cam_type_code%TYPE;
    l_newcard_flag          VARCHAR2(1) := 'N';
    l_new_pan               VARCHAR2(100);
    l_user_type             vmscms.cms_prod_cattype.cpc_user_identify_type%TYPE;
    l_encrypt_enable        vmscms.cms_prod_cattype.cpc_encrypt_enable%TYPE;
  	l_addr_one              vmscms.vms_order_details.VOD_ADDRESS_LINE1%type;
	  l_addr_two 			        vmscms.vms_order_details.VOD_ADDRESS_LINE2%type;
  	l_city 				          vmscms.vms_order_details.VOD_CITY%type;
    l_postal_code 		      vmscms.vms_order_details.VOD_POSTALCODE%type;
    l_first_name 		        vmscms.vms_order_details.VOD_FIRSTNAME%type;
  	l_mid_name 			        vmscms.vms_order_details.VOD_MIDDLEINITIAL%type;
    l_last_name			        vmscms.vms_order_details.VOD_LASTNAME%type;
    l_order_id_num          VARCHAR2(50);
    l_order_id              VARCHAR2(50);
    l_line_item_id          VARCHAR2(50);
    l_parent_id             VARCHAR2(50);
    l_loadamounttype_in     VARCHAR2(50);
    l_package_id            vmscms.vms_packageid_mast.vpm_package_id%type;
    l_product_id            vmscms.cms_prod_cattype.cpc_product_id%TYPE;
    l_serial_number         vmscms.cms_appl_pan.cap_serial_number%TYPE;
    l_proxy_number          vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_profile_code          vmscms.cms_prod_cattype.cpc_profile_code%TYPE;
    l_shipping_method       VARCHAR2(20);
    l_cardpack_id           vmscms.cms_appl_pan.cap_cardpack_id%TYPE;
    --l_card_id               vmscms.cms_prod_cattype.cpc_card_id%TYPE; --- Modified for VMS-6026
    l_replace_shipmethod    vmscms.vms_packageid_mast.vpm_replace_shipmethod%TYPE;
    l_exp_replaceshipmethod vmscms.vms_packageid_mast.vpm_exp_replaceshipmethod%TYPE;
    l_shipment_key          vmscms.vms_shipment_tran_mast.vsm_shipment_key%TYPE;
    l_initialload_amt       vmscms.cms_acct_mast.cam_acct_bal%TYPE;
    l_load_amt              vmscms.cms_acct_mast.cam_acct_bal%TYPE;
    l_session_id            VARCHAR2(20);
    l_final_bal             vmscms.cms_acct_mast.cam_acct_bal%TYPE;
    l_loadamount            vmscms.cms_acct_mast.cam_acct_bal%TYPE;
    l_cust_first_name       vmscms.cms_cust_mast.ccm_first_name%TYPE;
    l_cust_last_name        vmscms.cms_cust_mast.ccm_last_name%TYPE;
    l_cust_business_name    vmscms.cms_cust_mast.ccm_business_name%TYPE;
    l_embname               vmscms.vms_order_lineitem.vol_embossedline%TYPE;
    l_encr_embname          vmscms.vms_order_lineitem.vol_embossedline%TYPE;
    l_length                number := 21;
    l_merchant_id           vmscms.cms_appl_pan.cap_merchant_id%TYPE;
    l_location_id           vmscms.cms_appl_pan.cap_location_id%TYPE;
    l_cust_code             vmscms.cms_appl_pan.cap_cust_code%TYPE;
    l_state_code            vmscms.gen_state_mast.gsm_state_code%TYPE;
    l_cntry_code            vmscms.gen_cntry_mast.gcm_cntry_code%TYPE;
	l_logo_id				vmscms.vms_order_lineitem.vol_logo_id%TYPE;
    l_push_config            VARCHAR2(10);

   l_partner_name            vmscms.cms_prod_cattype.cpc_partner_name%TYPE;
   l_event_msg_type          vmscms.vms_trans_configuration.vtc_event_msg_type%TYPE;
   l_errmsg                 VARCHAR2(1000);

    l_dcrypt_check          number:=0; --Added for VMS 6024
    l_renew_replace_prodcode  vmscms.cms_prod_cattype.cpc_renew_replace_prodcode%TYPE;--Added for VMS 6024
    l_renew_replace_cardtype  vmscms.cms_prod_cattype.cpc_renew_replace_cardtype%TYPE;--Added for VMS 6024
    l_renew_replace_option    vmscms.cms_prod_cattype.cpc_renew_replace_option%TYPE;--Added for VMS 6024

   l_CARD_STATUS            vmscms.cms_card_stat.ccs_stat_desc%TYPE;
   l_payload                VARCHAR2(4000);
   l_queue_name              vmscms.cms_inst_param.cip_param_value%TYPE;
   l_email                   vmscms.cms_addr_mast.cam_email%TYPE;
   l_form_factor             vmscms.cms_appl_pan.cap_form_factor%TYPE;
   l_serial_proxy_encr		 vmscms.vms_line_item_dtl.vli_proxy_pin_encr%TYPE;
   l_encr_key                vmscms.cms_bin_param.cbp_param_value%TYPE;
   l_virtual_email           vmscms.cms_addr_mast.cam_email%TYPE;
   l_ord_email               vmscms.cms_addr_mast.cam_email%TYPE;
   l_ord_first_name          vmscms.vms_order_details.VOD_FIRSTNAME%type;
   l_ord_last_name           vmscms.vms_order_details.VOD_LASTNAME%type;
   l_payload_type_in        VARCHAR2(40):='REPLACE';
   l_tran_desc              vmscms.cms_transaction_mast.ctm_tran_desc%TYPE;
   l_order_stat             vmscms.vms_order_details.vod_order_status%TYPE;
   l_nano_time	            NUMBER;
   l_copy_encr_embname      vmscms.vms_order_lineitem.vol_embossedline%TYPE;
   l_copy_cust_business_name vmscms.cms_cust_mast.ccm_business_name%TYPE;
   l_emboss_name_on_replacement  vmscms.vms_packageid_mast.VPM_emboss_name_on_replacement%TYPE;
   l_activation_sticker_id vmscms.vms_order_lineitem.vol_activation_sticker_id%TYPE := NULL;--Modified by VMS-8938
   l_ccf_format_version    vmscms.cms_prod_cattype.cpc_ccf_format_version%TYPE;--Modified by VMS-8938

   L_EXP                    EXCEPTION;

  BEGIN
    --CFIP-416 starts
    p_istoken_eligible_out   := 'FALSE';
    p_iscvvplus_eligible_out := 'FALSE';
    p_forward_instcode_out   := '000000';
    l_loadamounttype_in := upper(p_loadamounttype_in);
    --CFIP-416 ends
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
	  l_loadamount:= to_number(nvl(p_loadamount_in,
                                 0));
    --Check for mandatory fields
    CASE
      WHEN p_customer_id_in IS NULL THEN
        l_field_name := 'CUSTOMER ID';
        l_flag       := 1;
      WHEN p_isexpedited_in IS NULL THEN
        l_field_name := 'IS EXPEDITED';
        l_flag       := 1;
      WHEN p_isfeewaived_in IS NULL THEN
        l_field_name := 'IS FEE WAIVED';
        l_flag       := 1;
      WHEN p_comment_in IS NULL THEN
        l_field_name := 'COMMENT';
        l_flag       := 1;
	  WHEN l_loadamounttype_in='OTHER_AMOUNT' and l_loadamounttype_in is null then
        l_field_name := 'Load Amount';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;
    g_debug.display('l_partner_id' || l_partner_id);
    g_debug.display('p_customer_id_in' || p_customer_id_in);
    --Fetching the active PAN for the input customer id
    --Performance Fix
    BEGIN
      SELECT cap_pan_code,
             cap_pan_code_encr,
             cap_expry_date,
             cap_prod_code,
             cap_mbr_numb,
             cap_card_type,
             cap_acct_no,
             cap_card_stat, --CFIP-416
             nvl(cap_cvvplus_reg_flag,
                 'N'), --CFIP-416
             cap_serial_number,
             cap_proxy_number,
             cap_cardpack_id,
             cap_merchant_id,
             cap_location_id,
             cap_cust_code,
             cap_form_factor
        INTO l_hash_pan,
             l_encr_pan,
             l_expiry_date,
             l_prod_code,
             l_mbr_numb,
             l_card_type,
             l_acct_no,
             l_card_stat, --CFIP-416
             l_cvvplus_eligibility, --CFIP-416
             l_serial_number,
             l_proxy_number,
             l_cardpack_id,
             l_merchant_id,
             l_location_id,
             l_cust_code,
             l_form_factor
        FROM (SELECT cap_pan_code,
                     cap_pan_code_encr,
                     to_char(cap_expry_date,
                             'yyyymmdd') cap_expry_date,
                     cap_prod_code,
                     cap_mbr_numb,
                     cap_card_type,
                     cap_acct_no,
                     cap_card_stat, --CFIP-416
                     cap_cvvplus_reg_flag, --CFIP-416
                     cap_serial_number,
                     cap_proxy_number,
                     cap_cardpack_id,
                     cap_merchant_id,
                     cap_location_id,
                     cap_cust_code,
                     cap_form_factor
                FROM vmscms.cms_appl_pan
               WHERE cap_cust_code =
                     (SELECT ccm_cust_code
                        FROM vmscms.cms_cust_mast
                       WHERE ccm_cust_id = to_number(p_customer_id_in)
                            --AND ccm_partner_id IN (l_partner_id)
                         AND ccm_prod_code || ccm_card_type =
                             vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                      p_prod_code_in  => ccm_prod_code,
                                                                      p_card_type_in  => ccm_card_type))
                 AND cap_inst_code = 1
                 AND cap_active_date IS NOT NULL
                 AND cap_card_stat NOT IN ('9')
                 AND cap_startercard_flag <> 'Y'
               ORDER BY cap_active_date DESC)
       WHERE rownum < 2;
    EXCEPTION
      WHEN no_data_found THEN
        BEGIN
          SELECT cap_pan_code,
                 cap_pan_code_encr,
                 cap_expry_date,
                 cap_prod_code,
                 cap_mbr_numb,
                 cap_card_type,
                 cap_acct_no,
                 cap_card_stat, --CFIP-416
                 nvl(cap_cvvplus_reg_flag,
                     'N'), --CFIP-416,
                 cap_serial_number,
                 cap_proxy_number,
                 cap_cardpack_id,
                 cap_merchant_id,
                 cap_location_id,
                 cap_cust_code,
                 cap_form_factor
            INTO l_hash_pan,
                 l_encr_pan,
                 l_expiry_date,
                 l_prod_code,
                 l_mbr_numb,
                 l_card_type,
                 l_acct_no,
                 l_card_stat, --CFIP-416
                 l_cvvplus_eligibility, --CFIP-416
                 l_serial_number,
                 l_proxy_number,
                 l_cardpack_id,
                 l_merchant_id,
                 l_location_id,
                 l_cust_code,
                 l_form_factor
            FROM (SELECT cap_pan_code,
                         cap_pan_code_encr,
                         to_char(cap_expry_date,
                                 'yyyymmdd') cap_expry_date,
                         cap_prod_code,
                         cap_mbr_numb,
                         cap_card_type,
                         cap_acct_no,
                         cap_card_stat, --CFIP-416
                         cap_cvvplus_reg_flag, --CFIP-416
                         cap_serial_number,
                         cap_proxy_number,
                         cap_cardpack_id,
                         cap_merchant_id,
                         cap_location_id,
                         cap_cust_code,
                         cap_form_factor
                    FROM vmscms.cms_appl_pan
                   WHERE cap_cust_code =
                         (SELECT ccm_cust_code
                            FROM vmscms.cms_cust_mast
                           WHERE ccm_cust_id = to_number(p_customer_id_in)
                                --AND ccm_partner_id IN (l_partner_id)
                             AND ccm_prod_code || ccm_card_type =
                                 vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                          p_prod_code_in  => ccm_prod_code,
                                                                          p_card_type_in  => ccm_card_type))
                     AND cap_inst_code = 1
                     AND cap_startercard_flag <> 'Y'
                   ORDER BY cap_pangen_date DESC)
           WHERE rownum < 2;
        EXCEPTION

          WHEN no_data_found THEN
            BEGIN
              SELECT cap_pan_code,
                     cap_pan_code_encr,
                     cap_expry_date,
                     cap_prod_code,
                     cap_mbr_numb,
                     cap_card_type,
                     cap_acct_no,
                     cap_card_stat, --CFIP-416
                     nvl(cap_cvvplus_reg_flag,
                         'N'), --CFIP-416
                     cap_serial_number,
                     cap_proxy_number,
                     cap_cardpack_id,
                     cap_merchant_id,
                     cap_location_id,
                     cap_cust_code,
                     cap_form_factor
                INTO l_hash_pan,
                     l_encr_pan,
                     l_expiry_date,
                     l_prod_code,
                     l_mbr_numb,
                     l_card_type,
                     l_acct_no,
                     l_card_stat, --CFIP-416
                     l_cvvplus_eligibility, --CFIP-416
                     l_serial_number,
                     l_proxy_number,
                     l_cardpack_id,
                     l_merchant_id,
                     l_location_id,
                     l_cust_code,
                     l_form_factor
                FROM (SELECT cap_pan_code,
                             cap_pan_code_encr,
                             to_char(cap_expry_date,
                                     'yyyymmdd') cap_expry_date,
                             cap_prod_code,
                             cap_mbr_numb,
                             cap_card_type,
                             cap_acct_no,
                             cap_card_stat, --CFIP-416
                             cap_cvvplus_reg_flag, --CFIP-416
                             cap_serial_number,
                             cap_proxy_number,
                             cap_cardpack_id,
                             cap_merchant_id,
                             cap_location_id,
                             cap_cust_code,
                             cap_form_factor
                        FROM vmscms.cms_appl_pan
                       WHERE cap_cust_code =
                             (SELECT ccm_cust_code
                                FROM vmscms.cms_cust_mast
                               WHERE ccm_cust_id =
                                     to_number(p_customer_id_in)
                                    --AND ccm_partner_id IN (l_partner_id)
                                 AND ccm_prod_code || ccm_card_type =
                                     vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                              p_prod_code_in  => ccm_prod_code,
                                                                              p_card_type_in  => ccm_card_type))
                         AND cap_inst_code = 1
                         AND cap_active_date IS NOT NULL
                         AND cap_card_stat NOT IN ('9')
                       ORDER BY cap_active_date DESC)
               WHERE rownum < 2;
            EXCEPTION
              WHEN no_data_found THEN
                BEGIN
                  SELECT cap_pan_code,
                         cap_pan_code_encr,
                         cap_expry_date,
                         cap_prod_code,
                         cap_mbr_numb,
                         cap_card_type,
                         cap_acct_no,
                         cap_card_stat, --CFIP-416
                         nvl(cap_cvvplus_reg_flag,
                             'N'), --CFIP-416
                         cap_serial_number,
                         cap_proxy_number,
                         cap_cardpack_id,
                         cap_merchant_id,
                         cap_location_id,
                         cap_cust_code,
                         cap_form_factor
                    INTO l_hash_pan,
                         l_encr_pan,
                         l_expiry_date,
                         l_prod_code,
                         l_mbr_numb,
                         l_card_type,
                         l_acct_no,
                         l_card_stat, --CFIP-416
                         l_cvvplus_eligibility, --CFIP-416
                         l_serial_number,
                         l_proxy_number,
                         l_cardpack_id,
                         l_merchant_id,
                         l_location_id,
                         l_cust_code,
                         l_form_factor
                    FROM (SELECT cap_pan_code,
                                 cap_pan_code_encr,
                                 to_char(cap_expry_date,
                                         'yyyymmdd') cap_expry_date,
                                 cap_prod_code,
                                 cap_mbr_numb,
                                 cap_card_type,
                                 cap_acct_no,
                                 cap_card_stat, --CFIP-416
                                 cap_cvvplus_reg_flag, --CFIP-416
                                 cap_serial_number,
                                 cap_proxy_number,
                                 cap_cardpack_id,
                                 cap_merchant_id,
                                 cap_location_id,
                                 cap_cust_code,
                                 cap_form_factor
                            FROM vmscms.cms_appl_pan
                           WHERE cap_cust_code =
                                 (SELECT ccm_cust_code
                                    FROM vmscms.cms_cust_mast
                                   WHERE ccm_cust_id =
                                         to_number(p_customer_id_in)
                                        --AND ccm_partner_id IN (l_partner_id)
                                     AND ccm_prod_code || ccm_card_type =
                                         vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                                  p_prod_code_in  => ccm_prod_code,
                                                                                  p_card_type_in  => ccm_card_type))
                             AND cap_inst_code = 1
                          --  AND cap_startercard_flag <> 'Y'
                           ORDER BY cap_pangen_date DESC)
                   WHERE rownum < 2;
                EXCEPTION

                  WHEN no_data_found THEN
                    g_debug.display('no data----' || l_hash_pan);
                    l_hash_pan    := NULL;
                    l_encr_pan    := NULL;
                    l_expiry_date := NULL;
                END;
            END;
        END;
    END;
    g_debug.display('l_hash_pan' || l_hash_pan);
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

    IF l_form_factor = 'V' and p_email_in IS NULL
    THEN
        p_status_out := vmscms.gpp_const.c_mandatory_status;
        g_err_mandatory.raise(l_api_name,
                            ',0002,',
                            'Email is mandatory for Virtual Card Replacement.');
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

	if l_loadamounttype_in not in ('INITIAL_LOAD_AMOUNT','CURRENT_BALANCE','OTHER_AMOUNT')
    THEN
        p_status_out := vmscms.gpp_const.c_invalid_data_status;
        p_err_msg_out := 'Invalid Load Amount Type';
        return;
    end if;
      BEGIN
        SELECT cam_acct_bal,
               cam_ledger_bal,
               cam_type_code,
               nvl(cam_initialload_amt,0)
          INTO l_acct_balance,
               l_ledger_balance,
               l_acct_type,
               l_initialload_amt
          FROM vmscms.cms_acct_mast
         WHERE cam_acct_no = l_acct_no
           AND cam_inst_code = 1;
      EXCEPTION
        WHEN OTHERS THEN
          p_err_msg_out := 'Error while selecting acct dtl' || SQLERRM;
      END;
      IF L_LOADAMOUNTTYPE_IN='OTHER_AMOUNT' AND l_loadamount < L_ACCT_BALANCE THEN
          p_status_out := vmscms.gpp_const.c_invalid_data_status;
          p_err_msg_out := 'Load Amount Should be Greater Than Account Balance';
          return;
      elsif l_loadamounttype_in='INITIAL_LOAD_AMOUNT' and l_acct_balance>l_initialload_amt then
          p_status_out := vmscms.gpp_const.c_invalid_data_status;
          p_err_msg_out := 'Initial Load Amount Should Be Greater Than Account Balance';
          return;
      end if;

    --getting the date
    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);
    -- l_date := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11); --for testing
    l_date := to_char(to_date(l_date,
                              'dd-mm-yyyy'),
                      'yyyymmdd');
    --getting the time
    l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-date')),
                     18,
                     8);
    --l_time := '08:49:37';
    l_time      := REPLACE(l_time,
                           ':',
                           '');
    l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);

    --CFIP-416 starts
    p_cardno_out := l_plain_pan;
    l_session_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-sessionid'));

    SELECT nvl(cpc_token_eligibility,
               'N'),
           nvl(cpc_user_identify_type,
               '0'),
           cpc_encrypt_enable,
           cpc_renew_replace_prodcode,--added for VMS 6024
           cpc_renew_replace_cardtype,--added for VMS 6024
           cpc_renew_replace_option,--added for VMS 6024
           cpc_product_id,
           cpc_profile_code
           ,cpc_ccf_format_version--Modified for VMS-8938
           --cpc_card_id --,  --- Modified for VMS-6026
    --nvl(cpc_cvvplus_eligibility,
    --  'N')
      INTO l_token_eligibility,
           l_user_type,
           l_encrypt_enable,
           l_renew_replace_prodcode,--added for VMS 6024
           l_renew_replace_cardtype,--added for VMS 6024
           l_renew_replace_option,--added for VMS 6024
           l_product_id,
           l_profile_code
           ,l_ccf_format_version--Modified for VMS-8938
           --l_card_id   --- Modified for VMS-6026
		   --, l_cvvplus_eligibility
      FROM vmscms.cms_prod_cattype
     WHERE cpc_inst_code = 1
       AND cpc_prod_code = l_prod_code
       AND cpc_card_type = l_card_type;

    IF (l_user_type IN ( '1', '4') and NVL(l_form_factor,'P') <> 'V') or l_form_factor <> 'V'  --VMS-7303
    THEN
      CASE
        WHEN p_addrone_in IS NULL THEN
          l_field_name := 'Address 1';
          l_flag       := 1;
        WHEN p_city_in IS NULL THEN
          l_field_name := 'City';
          l_flag       := 1;
        WHEN p_state_in IS NULL THEN
          l_field_name := 'State';
          l_flag       := 1;
        WHEN p_postalcode_in IS NULL THEN
          l_field_name := 'Postal Code';
          l_flag       := 1;
        WHEN p_countrycode_in IS NULL THEN
          l_field_name := 'Country Code';
          l_flag       := 1;
        ELSE
          NULL;
      END CASE;
      --Need to check mandatory fields
    END IF;

    IF l_flag = 1
    THEN
      p_status_out := vmscms.gpp_const.c_mandatory_status;
      g_err_mandatory.raise(l_api_name,
                            ',0002,',
                            l_field_name ||
                            ' is mandatory for Anonymous User');
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

    IF l_token_eligibility = 'Y'
    THEN
      p_istoken_eligible_out := 'TRUE';
    END IF;

    IF l_cvvplus_eligibility = 'Y'
    THEN
      p_iscvvplus_eligible_out := 'TRUE';
    END IF;
    --CFIP-416 ends
    --Sn Added for VMS-104
    IF upper(p_createnewcard_in) = 'TRUE'
    THEN
      l_newcard_flag := 'Y';
    END IF;




    --Performance Fix
    SELECT cbp_param_value
      INTO l_curr_code
      FROM vmscms.cms_bin_param
     WHERE cbp_inst_code = 1
       AND cbp_profile_code = l_profile_code
       AND cbp_param_name = 'Currency';

    SELECT /*to_char(substr(to_char(SYSDATE,
                                  'YYMMDDHHMMSS'),
                          1,
                          9) || --Modified for CFIP-416*/
                   to_char(to_char(SYSDATE,'YYMMDDHH24MISS') ||      --Changes VMS-8279 ~ HHMM has been replaced as HH24MI, Length of RRN changed to 15
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0')),
           lpad(vmscms.seq_auth_stan.nextval,
                6,
                '0') --CFIP-416
      INTO l_rrn,
           p_stan_out --CFIP-416
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);
    p_rrn_out := l_rrn;
    --jira issue CFIP:145 starts
    CASE
      WHEN upper(p_isexpedited_in) = 'TRUE'
           AND upper(p_isfeewaived_in) = 'TRUE' THEN
        l_txn_code := '29';
        l_fee_flag := 'N';
      WHEN upper(p_isexpedited_in) = 'TRUE'
           AND upper(p_isfeewaived_in) = 'FALSE' THEN
        l_txn_code := '29';
        l_fee_flag := 'Y';
      WHEN upper(p_isexpedited_in) = 'FALSE'
           AND upper(p_isfeewaived_in) = 'TRUE' THEN
        l_txn_code := '22';
        l_fee_flag := 'N';
      WHEN upper(p_isexpedited_in) = 'FALSE'
           AND upper(p_isfeewaived_in) = 'FALSE' THEN
        l_txn_code := '22';
        l_fee_flag := 'Y';
    END CASE;
    g_debug.display('l_txn_code' || l_txn_code);
    g_debug.display('l_fee_flag' || l_fee_flag);
    --jira issue CFIP:145 ends
    BEGIN
      --Performance Fix
      SELECT vmscms.gpp_feeplan.get_fee_plan(l_hash_pan,
                                             l_prod_code,
                                             l_card_type)
        INTO l_fee_plan
        FROM dual;
      g_debug.display('l_fee_plan' || l_fee_plan);
      --Performance Fix
      BEGIN
        SELECT TRIM(to_char(a.cfm_fee_amt,
                            '9999999999999990.00'))
          INTO l_fee_amt
          FROM vmscms.cms_fee_mast a
         WHERE a.cfm_inst_code = 1
           AND a.cfm_fee_code IN
               (SELECT b.cff_fee_code
                  FROM vmscms.cms_fee_feeplan b
                 WHERE b.cff_fee_plan = l_fee_plan
                   AND b.cff_inst_code = 1)
           AND a.cfm_delivery_channel = '03'
           AND (cfm_tran_code = l_txn_code OR cfm_tran_code = 'A')
           AND nvl(cfm_normal_rvsl,
                   'N') = 'N';
      EXCEPTION
        WHEN no_data_found THEN
          l_fee_amt := '0.00';
      END;

      g_debug.display('l_fee_amt' || l_fee_amt);
      BEGIN
      g_debug.display('calling sp_csr_order_replace');
      vmscms.sp_csr_order_replace('1',
                                  '0200',
                                  l_rrn,
                                  '03',
                                  NULL,
                                  l_txn_code,
                                  '0',
                                  l_date,
                                  l_time,
                                  l_plain_pan,
                                  '1',
                                  '0',
                                  NULL,
                                  l_curr_code,
                                  NULL,
                                  l_expiry_date,
                                  p_stan_out, --NULL, --CFIP-416
                                  l_mbr_numb, --'000',  --Performance Fix
                                  '0',
                                  (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                               'x-incfs-sessionid')),
                                  (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                               'x-incfs-ip')),
                                  NULL,
                                  p_comment_in,
                                  --Jira issue fix:145 starts
                                  /*(CASE p_isfeewaived_in WHEN 'TRUE' THEN 'Y' ELSE 'N' END),*/
                                  l_fee_flag,
                                  ----Jira issue fix:145 ends
                                  p_activationcode_out, --l_auth_id,
                                  l_resp_code,
                                  l_resp_msg,
                                  l_capture_date,
                                  l_fee_amt,
                                  l_avail_bal,
                                  l_ledger_bal,
                                  p_err_msg_out,
                                  --CFIP-416 starts
                                  l_expiry_date_parameter,
                                  l_new_expiry_date_parameter,
                                  l_replace_optn,
                                  --CFIP-416 ends
                                  l_newcard_flag --Added for VMS-104
                                  );
       IF l_resp_msg <> 'OK'   -- Added for VMS-846(Replacement Not allowed for digital card)
       THEN
          p_status_out  := l_resp_code;
          p_err_msg_out := l_resp_msg;
          RETURN;
       END IF;
      EXCEPTION
      WHEN OTHERS THEN
          g_debug.display('Exception in sp_csr_order_replace');
          dbms_output.put_line(SQLERRM);
          p_status_out  := l_resp_code;
          p_err_msg_out := l_resp_msg;
          RETURN;
      END;

      p_exprydate_out     := to_char(l_expiry_date_parameter,
                                     'MMYY');
      p_new_exprydate_out := to_char(l_new_expiry_date_parameter,
                                     'MMYY');
      IF l_encrypt_enable = 'Y'
      THEN
        l_addr_one           := vmscms.fn_emaps_main(p_addrone_in);
        l_addr_two           := vmscms.fn_emaps_main(p_addrtwo_in);
        l_city               := vmscms.fn_emaps_main(p_city_in);
        l_postal_code        := vmscms.fn_emaps_main(p_postalcode_in);
        l_first_name         := vmscms.fn_emaps_main(p_firstname_in);
        l_mid_name           := vmscms.fn_emaps_main(p_middlename_in);
        l_last_name          := vmscms.fn_emaps_main(p_lastname_in);

        l_virtual_email      := vmscms.fn_emaps_main(p_email_in);
      ELSE
        l_addr_one           := p_addrone_in;
        l_addr_two           := p_addrtwo_in;
        l_city               := p_city_in;
        l_postal_code        := p_postalcode_in;
        l_first_name         := p_firstname_in;
        l_mid_name           := p_middlename_in;
        l_last_name          := p_lastname_in;

        l_virtual_email      := p_email_in;

      END IF;

      IF l_resp_code = '00'
      THEN
        BEGIN
          SELECT vmscms.fn_dmaps_main(cap_pan_code_encr)
            INTO l_new_pan
            FROM vmscms.cms_htlst_reisu,
                 vmscms.cms_appl_pan
           WHERE chr_inst_code = 1
             AND chr_pan_code = l_hash_pan
             AND chr_mbr_numb = l_mbr_numb
             AND cap_inst_code = chr_inst_code
             AND cap_mbr_numb = l_mbr_numb
             AND cap_pan_code = chr_new_pan;

          p_new_cardno_out     := l_new_pan;
          p_new_maskcardno_out := vmscms.fn_getmaskpan(l_new_pan);

          p_message_reasoncode_out := '3721';
          p_req_reason_out         := 'New PAN Replacement By Program Manager';

          g_debug.display('p_message_reasoncode_out:' ||
                          p_message_reasoncode_out);
          g_debug.display('p_req_reason_out:' || p_req_reason_out);

          IF l_token_eligibility = 'Y'
          THEN
            SELECT COUNT(*)
              INTO l_check_tokens
              FROM vmscms.vms_token_info
             WHERE vti_acct_no = l_acct_no
               AND vti_token_stat <> 'D';

            IF l_check_tokens > 0
            THEN
              IF l_card_stat = '2'
              THEN
                vmscms.gpp_tokens.update_token_status(l_hash_pan,
                                                      vmscms.gethash(l_new_pan),
                                                      'R',
                                                      l_action,
                                                      l_card_dtls,
                                                      l_card_dtls,
                                                      p_token_dtls_out,
                                                      p_err_msg_out);
                g_debug.display('token_msg_out:' || p_err_msg_out);

                IF p_err_msg_out <> 'OK'
                THEN
                  p_status_out := vmscms.gpp_const.c_ora_error_status;
                  g_err_upd_token_status.raise(l_api_name,
                                               'CUSTOMER ID ' ||
                                               p_customer_id_in,
                                               vmscms.gpp_const.c_ora_error_status);
                  p_err_msg_out := 'Update Tokens failed for ' ||
                                   'CUSTOMER ID ' || p_customer_id_in ||
                                   ', Error: ' || p_err_msg_out;
                  vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                               p_customer_id_in,
                                                               l_hash_pan,
                                                               l_encr_pan,
                                                               'F',
                                                               p_err_msg_out,
                                                               vmscms.gpp_const.c_failure_res_id,
                                                               NULL,
                                                               l_timetaken);
/*                ELSE
                  g_debug.display('inserting token status update txn into transactionlog');

                  BEGIN
                      INSERT INTO vmscms.transactionlog
                        (msgtype,
                         rrn,
                         delivery_channel,
                         txn_code,
                         trans_desc,
                         txn_type,
                         txn_mode,
                         customer_card_no,
                         customer_card_no_encr,
                         business_date,
                         business_time,
                         txn_status,
                         response_code,
                         auth_id,
                         instcode,
                         date_time,
                         response_id,
                         customer_acct_no,
                         acct_balance,
                         ledger_balance,
                         acct_type,
                         cardstatus,
                         error_msg,
                         productid,
                         categoryid,
                         system_trace_audit_no)
                      VALUES
                        ('0200',
                         l_rrn,
                         '03',
                         l_txn_code,
                         (SELECT ctm_tran_desc
                          FROM vmscms.cms_transaction_mast
                         WHERE ctm_inst_code = 1
                           AND ctm_tran_code = l_txn_code
                           AND ctm_delivery_channel = '03'),
                         '0',
                         0,
                         l_hash_pan,
                         l_encr_pan,
                         to_char(SYSDATE,
                             'yyyymmdd'),
                         to_char(SYSDATE,
                             'hh24miss'),
                         'C',
                         '00',
                         p_activationcode_out,
                         1,
                         SYSDATE,
                         '1',
                         l_acct_no,
                         l_acct_balance,
                         l_ledger_balance,
                         l_acct_type,
                         l_card_stat,
                         'SUCCESS',
                         l_prod_code,
                         l_card_type,
                         p_stan_out);
                  EXCEPTION
                  WHEN OTHERS THEN
                    p_err_msg_out := 'Error while logging token status update txn' ||
                             SQLERRM;
                  END;

                  g_debug.display('inserting token status update txn into transactionlog dtl');

                  BEGIN
                      INSERT INTO vmscms.cms_transaction_log_dtl
                        (ctd_delivery_channel,
                         ctd_txn_code,
                         ctd_txn_type,
                         ctd_msg_type,
                         ctd_txn_mode,
                         ctd_business_date,
                         ctd_business_time,
                         ctd_customer_card_no,
                         ctd_process_flag,
                         ctd_process_msg,
                         ctd_rrn,
                         ctd_inst_code,
                         ctd_customer_card_no_encr,
                         ctd_cust_acct_number,
                         ctd_system_trace_audit_no,
                         ctd_auth_id)
                      VALUES
                        ('03',
                         l_txn_code,
                         '0',
                         '0200',
                         0,
                         to_char(SYSDATE,
                             'yyyymmdd'),
                         to_char(SYSDATE,
                             'hh24miss'),
                         l_hash_pan,
                         'Y',
                         'Successful',
                         l_rrn,
                         1,
                         l_encr_pan,
                         l_acct_no,
                         p_stan_out,
                         p_activationcode_out);
                  EXCEPTION
                  WHEN OTHERS THEN
                    p_err_msg_out := 'Error while logging token status update txn dtls' ||
                             SQLERRM;
                  END;*/
                END IF;
              ELSE
                l_action := 'N';
              END IF;
            END IF;
            IF p_err_msg_out = 'OK'
               AND l_action IN ('N',
                                'D')
            THEN
              p_stan_out               := '';
              p_rrn_out                := '';
              p_activationcode_out     := '';
              p_req_reason_out         := '';
              p_forward_instcode_out   := '';
              p_message_reasoncode_out := '';
            END IF;
          END IF;
        EXCEPTION
          WHEN no_data_found THEN
            l_new_pan                := l_plain_pan;
            p_message_reasoncode_out := '3720';
            p_req_reason_out         := 'Same PAN Relpacement By Program Manager';
        END;

	IF l_card_stat not in (2,15) and l_form_factor = 'V'
	THEN

	UPDATE vmscms.CMS_APPL_PAN			--- Closing the old card for Virtual Replace
            SET CAP_CARD_STAT = 9
          WHERE cap_inst_code = 1
           AND  cap_mbr_numb = l_mbr_numb
	   AND  CAP_PAN_CODE = l_hash_pan;


	   vmscms.sp_log_cardstat_chnge (1,
                                  l_hash_pan,
                                  l_encr_pan,
                                  p_activationcode_out,
                                  '02',
                                  l_rrn,
                                  l_date,
                                  l_time,
                                  l_resp_code,
                                  l_resp_msg
                                 );

	IF l_resp_msg <> 'OK'   -- Added for VMS-846(Replacement Not allowed for digital card)
        THEN
          p_status_out  := l_resp_code;
          p_err_msg_out := l_resp_msg;
          RETURN;
        END IF;


	END IF;

        UPDATE vmscms.cms_appl_pan
           SET cap_replace_merchant_id = p_merchantid_in,
               cap_replace_terminal_id = p_terminalid_in,
               cap_activation_code     = p_activationcode_in,
               cap_serial_number       = l_serial_number,
               cap_proxy_number        = l_proxy_number,
               cap_merchant_billable   = DECODE(upper(p_merchantbillable_in),
                                                'TRUE',
                                                'Y',
                                                'N'),
               cap_replace_location_id = p_locationid_in,
               cap_merchant_id = NVL(p_merchantid_in,l_merchant_id),
               cap_location_id = NVL(p_locationid_in,l_location_id),    --- Modified for VMS-4484
    	       cap_form_factor = l_form_factor,
               cap_card_stat = decode(l_form_factor,'V',1,cap_card_stat),
               cap_active_date = decode(l_form_factor,'V',SYSDATE,cap_active_date)
         WHERE cap_pan_code = vmscms.gethash(l_new_pan)
           AND cap_mbr_numb = l_mbr_numb
           AND cap_inst_code = 1;


	IF l_form_factor = 'V'				--- Modified for VMS-4484
    THEN

        UPDATE vmscms.cms_cardissuance_status
        SET ccs_card_status = 15   				--- SHIPPED
        where ccs_pan_code =  vmscms.gethash(l_new_pan);



    END IF;

	--- VMS-4633- Update Address/Email for CCA initiated Replacement--B2B Spec Consolidation

	IF p_firstname_in IS NOT NULL
                THEN

                         UPDATE vmscms.cms_cust_mast
                                   SET ccm_first_name = l_first_name,
                                       ccm_mid_name =  nvl(l_mid_name,ccm_mid_name),
                                       ccm_last_name = nvl(l_last_name,ccm_last_name),
                                       ccm_first_name_encr = vmscms.fn_emaps_main(p_firstname_in),
                                       ccm_last_name_encr = nvl(vmscms.fn_emaps_main(p_lastname_in),trim(ccm_last_name_encr))
                                 WHERE ccm_inst_code = 1
                                   AND ccm_cust_code = l_cust_code;

        END IF;


		    --En Added for VMS-104
        SELECT vmscms.fn_dmaps_main(ccm_first_name),
               vmscms.fn_dmaps_main(ccm_last_name),
               ccm_business_name
          INTO l_cust_first_name,
               l_cust_last_name,
               l_cust_business_name
          FROM vmscms.cms_cust_mast
         WHERE ccm_cust_id = p_customer_id_in;

    l_embname := vmscms.FN_B2B_EMBNAME(l_cust_first_name, l_cust_last_name, l_length);


          IF l_encrypt_enable = 'Y'
      THEN
        l_encr_embname       := vmscms.fn_emaps_main(l_embname);
        l_cust_business_name := vmscms.fn_emaps_main(l_cust_business_name);
        l_copy_encr_embname  := l_encr_embname;
        l_copy_cust_business_name := l_cust_business_name;
      ELSE
        l_encr_embname       := l_embname;
        l_cust_business_name := l_cust_business_name;
        l_copy_encr_embname  := l_encr_embname;
        l_copy_cust_business_name := l_cust_business_name;
      END IF;




	--- Modified for VMS-4633- Update Address/Email for CCA initiated Replacement--B2B Spec Consolidation
        IF  p_addrone_in IS NOT NULL and p_city_in IS NOT NULL and
        p_state_in IS NOT NULL and p_postalcode_in IS NOT NULL and p_countrycode_in IS NOT NULL


        THEN

           BEGIN
                  SELECT gsm_state_code
                  INTO l_state_code
                  FROM vmscms.gen_state_mast
                  WHERE gsm_inst_code = 1
                  AND gsm_switch_state_code = upper(p_state_in);

                  SELECT gcm_cntry_code
                  INTO l_cntry_code
                  FROM vmscms.gen_cntry_mast
                  WHERE gcm_inst_code = 1
                  AND gcm_switch_cntry_code = upper(p_countrycode_in);


                  MERGE INTO vmscms.cms_addr_mast
                  USING (select l_cust_code cust_code,'O' addr_flag from dual) a
                  ON (cam_cust_code = a.cust_code and cam_addr_flag = a.addr_flag)
                  WHEN MATCHED THEN
                    UPDATE
                    SET CAM_ADD_ONE      = l_addr_one,
                      CAM_ADD_TWO        = l_addr_two,
                      CAM_CITY_NAME      = l_city,
                      CAM_STATE_CODE     = l_state_code,
                      CAM_PIN_CODE       = l_postal_code,
                      CAM_CNTRY_CODE     = l_cntry_code,
                      CAM_LUPD_DATE      = sysdate,
                      CAM_ADD_ONE_ENCR   = vmscms.fn_emaps_main(p_addrone_in),              --Sn:Added for VMS-958
                      CAM_ADD_TWO_ENCR   = vmscms.fn_emaps_main(p_addrtwo_in),
                      CAM_CITY_NAME_ENCR = vmscms.fn_emaps_main(p_city_in),
                      CAM_PIN_CODE_ENCR  = vmscms.fn_emaps_main(p_postalcode_in)            --En:Added for VMS-958
                  WHEN NOT MATCHED THEN
                      INSERT (
                              CAM_INST_CODE,
                              CAM_CUST_CODE,
                              CAM_ADDR_CODE,
                              CAM_ADD_ONE,
                              CAM_ADD_TWO,
                              CAM_PIN_CODE,
                              CAM_CNTRY_CODE,
                              CAM_CITY_NAME,
                              CAM_ADDR_FLAG,
                              CAM_INS_DATE,
                              CAM_STATE_CODE,
                              CAM_ADD_ONE_ENCR,                                      --Sn:Added for VMS-958
                              CAM_ADD_TWO_ENCR,
                              CAM_PIN_CODE_ENCR,
                              CAM_CITY_NAME_ENCR,                                     --En:Added for VMS-958
							  CAM_INS_USER,
							  CAM_LUPD_USER
                            )
                      VALUES
                            (
                              1,
                              l_cust_code,
                              vmscms.seq_addr_code.nextval,
                              l_addr_one,
                              l_addr_two,
                              l_postal_code,
                              l_cntry_code,
                              l_city,
                              'O',
                              sysdate,
                              l_state_code,
                              vmscms.fn_emaps_main(p_addrone_in),                     --Sn:Added for VMS-958
                              vmscms.fn_emaps_main(p_addrtwo_in),
                              vmscms.fn_emaps_main(p_postalcode_in),
                              vmscms.fn_emaps_main(p_city_in),                         --En:Added for VMS-958
							  1,
							  1
                            );

		IF l_user_type in ('1','4') THEN

		 UPDATE vmscms.cms_addr_mast
                    SET CAM_ADD_ONE      = l_addr_one,
                      CAM_ADD_TWO        = l_addr_two,
                      CAM_CITY_NAME      = l_city,
                      CAM_STATE_CODE     = l_state_code,
                      CAM_PIN_CODE       = l_postal_code,
                      CAM_CNTRY_CODE     = l_cntry_code,
                      CAM_LUPD_DATE      = sysdate,
                      CAM_ADD_ONE_ENCR   = vmscms.fn_emaps_main(p_addrone_in),
                      CAM_ADD_TWO_ENCR   = vmscms.fn_emaps_main(p_addrtwo_in),
                      CAM_CITY_NAME_ENCR = vmscms.fn_emaps_main(p_city_in),
                      CAM_PIN_CODE_ENCR  = vmscms.fn_emaps_main(p_postalcode_in)
		 WHERE CAM_INST_CODE = 1
	           AND CAM_CUST_CODE = l_cust_code
		   AND CAM_ADDR_FLAG  = 'P' ;

		END IF;
        				 --- Added for VMS-5253 / VMS-5372
        	UPDATE vmscms.CMS_CUST_MAST
                   SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
                   WHERE CCM_INST_CODE = 1
                    AND CCM_CUST_CODE = l_cust_code;

            EXCEPTION
              WHEN OTHERS THEN
                  g_debug.display('Exception while updating addrmast');
                  dbms_output.put_line(SQLERRM);
                  p_status_out  := l_resp_code;
                  p_err_msg_out := l_resp_msg;
                  RETURN;
            END;
        END IF;

	--- Added for VMS-4633- Update Address/Email for CCA initiated Replacement--B2B Spec Consolidation

    IF p_email_in IS NULL          --- Added for VMS-5020
	THEN

	SELECT CAM_EMAIL
                            INTO l_ord_email
                            FROM vmscms.CMS_ADDR_MAST
                            WHERE cam_inst_code = 1
                            AND cam_cust_code = l_cust_code
                            AND cam_addr_flag = 'P';
      ELSE

	UPDATE vmscms.CMS_ADDR_MAST
        SET CAM_EMAIL = l_virtual_email,
        CAM_EMAIL_ENCR = vmscms.fn_emaps_main(p_email_in)
        WHERE CAM_CUST_CODE = l_cust_code
        AND CAM_INST_CODE = 1;


	END IF;


        IF l_user_type in ('1','4')
        THEN

          SELECT vmscms.replace_order_id.nextval,
                 vmscms.seq_parent_id.nextval
            INTO l_order_id_num,
                 l_parent_id
            FROM dual;

          l_order_id     := 'ROID' || l_order_id_num;
          l_line_item_id := 'RLID' || l_order_id_num;

          --Sn:Added for VMS-810 (Replacement Processing: Emboss Line 3 and Emboss Line 4)


          IF l_user_type = '1' THEN

            BEGIN--Added for VMS-895
                SELECT lineitem.vol_embossedline,
                       lineitem.vol_embossed_line1
                INTO l_encr_embname,
                     l_cust_business_name
                FROM vmscms.vms_order_lineitem lineitem,
                     vmscms.vms_line_item_dtl lineitem_dtl
                WHERE lineitem.vol_line_item_id = lineitem_dtl.vli_lineitem_id
                AND lineitem.vol_order_id       = lineitem_dtl.vli_order_id
                AND lineitem.vol_parent_oid     = lineitem_dtl.vli_parent_oid
                AND lineitem_dtl.vli_pan_code   = l_hash_pan
                AND rownum = 1;
            EXCEPTION
            WHEN OTHERS THEN
              l_encr_embname := NULL;
              l_cust_business_name := NULL;
            END;

          END IF;

          --En:Added for VMS-810 (Replacement Processing: Emboss Line 3 and Emboss Line 4)


			--SN:Added for VMS-6026

		   if l_cardpack_id is null then

                    select  cap_cardpack_id
                    into l_cardpack_id
                    from ( select  cap_cardpack_id
                    from vmscms.cms_appl_pan
                    where cap_inst_code = 1
                    and cap_acct_no = l_acct_no
                    and  cap_repl_flag = 0
                    ORDER BY cap_ins_date
                    )
                where rownum =1;

            end if;

		   --EN:Added for VMS-6026


          SELECT vpm_replace_shipmethod,
                 vpm_exp_replaceshipmethod,
		             vpm_package_id
            INTO l_replace_shipmethod,
                 l_exp_replaceshipmethod,
		             l_package_id
            FROM vmscms.vms_packageid_mast
           WHERE vpm_package_id IN
                 (SELECT vpm_replacement_package_id
                    FROM vmscms.vms_packageid_mast
                   WHERE vpm_package_id IN
                         (SELECT cpc_card_details
                            FROM vmscms.cms_prod_cardpack
                           WHERE cpc_prod_code = l_prod_code
                             AND cpc_card_id = l_cardpack_id )); -- nvl(l_cardpack_id, l_card_id)));--- Modified for VMS-6026

          IF upper(p_isexpedited_in) = 'TRUE'
          THEN
            l_shipping_method := l_exp_replaceshipmethod;
          ELSE
            l_shipping_method := l_replace_shipmethod;
          END IF;

	  IF l_encr_embname IS NULL		--- Modified for VMS-5045: Embossing F/L Name during Phhysical Repl via CCA
	  THEN

          BEGIN

          SELECT NVL(vpm_emboss_name_on_replacement,'N')
          INTO l_emboss_name_on_replacement
                    FROM vmscms.vms_packageid_mast
                   WHERE vpm_package_id IN
                         (SELECT cpc_card_details
                            FROM vmscms.cms_prod_cardpack
                           WHERE cpc_prod_code = l_prod_code
                             AND cpc_card_id = l_cardpack_id); --nvl(l_cardpack_id, l_card_id));--- Modified for VMS-6026

                IF l_emboss_name_on_replacement = 'Y'
                THEN

                      l_encr_embname:= l_copy_encr_embname;
                      l_cust_business_name:= l_copy_cust_business_name;

                  END IF;

          EXCEPTION
          WHEN OTHERS THEN
                  ROLLBACK;
                  p_status_out  := '49';
                  p_err_msg_out := 'Error While Selecting Embooss Configuration at Package'||SUBSTR(SQLERRM,1,250);
                  RETURN;
        END;

	END IF;



          SELECT vsm_shipment_key
            INTO l_shipment_key
            FROM vmscms.vms_shipment_tran_mast
           WHERE vsm_shipment_id = l_shipping_method;


		BEGIN                             --- Added for VMS-2428.
		   SELECT vpl_logo_id
			INTO l_logo_id
			FROM vmscms.VMS_PACKID_LOGOID_MAPPING
			WHERE vpl_package_id = l_package_id
			  AND vpl_default_flag = 'Y';
		EXCEPTION
			WHEN OTHERS
			THEN l_logo_id :='000000';
		END;

    IF l_form_factor = 'V'
	 THEN
	 l_order_stat := 'Completed';
	 ELSE
         l_order_stat := 'Processed';
	 END IF;

       IF p_firstname_in IS  NULL AND p_lastname_in IS NULL
        THEN

        BEGIN
                SELECT ord.vod_firstname,
                       ord.vod_lastname
                INTO l_ord_first_name,
                     l_ord_last_name
                FROM vmscms.vms_order_details ord,
                     vmscms.vms_line_item_dtl lineitem_dtl
                WHERE ord.vod_order_id       = lineitem_dtl.vli_order_id
                AND ord.vod_partner_id     = lineitem_dtl.vli_partner_id
                AND lineitem_dtl.vli_pan_code   = l_hash_pan
                AND rownum = 1;
            EXCEPTION
            WHEN OTHERS THEN
                NULL;
            END;

         END IF;
        
        --Modified for VMS-8938
        -- If CCF 5.0 then get the activation sticker Id
          IF TO_NUMBER(l_ccf_format_version) >= 5
          THEN
              -- get the sticker ID
              BEGIN
                  SELECT TRIM(vpd_field_value)
                  INTO l_activation_sticker_id
                  FROM vmscms.vms_packageid_detl
                  WHERE vpd_field_key = 'activationStickerId'
                    AND vpd_package_id IN (l_package_id);
              EXCEPTION WHEN NO_DATA_FOUND
                  THEN
                      l_activation_sticker_id := NULL;
              END;
          END IF;

          INSERT INTO vmscms.vms_order_details
            (vod_order_id,
             vod_partner_id,
             vod_merchant_id,
             vod_order_default_card_status,
             vod_postback_response,
             vod_activation_code,
             vod_shipping_method,
             vod_order_status,
             vod_address_line1,
             vod_address_line2,
             vod_city,
             vod_state,
             vod_postalcode,
             vod_country,
             vod_firstname,
             vod_middleinitial,
             vod_lastname,
             vod_ins_date,
             vod_error_msg,
             vod_channel_id,
             vod_accept_partial,
             vod_order_type,
             vod_parent_oid,
			 VOD_EMAIL)
          VALUES
            (l_order_id,
             'Replace_Partner_ID',
             p_merchantid_in,
             decode(l_form_factor,'V','ACTIVE','INACTIVE'),
             'False',
             p_activationcode_in,
             l_shipment_key,
             l_order_stat,
             l_addr_one,
             l_addr_two,
             l_city,
             DECODE (l_encrypt_enable,'N',p_state_in,vmscms.fn_emaps_main(p_state_in)),
             l_postal_code,
             DECODE (l_encrypt_enable,'N',p_countrycode_in,vmscms.fn_emaps_main(p_countrycode_in)),
             nvl(l_first_name,l_ord_first_name),
             l_mid_name,
             nvl(l_last_name,l_ord_last_name),
             SYSDATE,
             'OK',
             'WEB',
             'true',
             'IND',
             l_parent_id,
			 nvl(l_virtual_email,l_ord_email)  --- Modified for VMS-5020
             );


          INSERT INTO vmscms.vms_order_lineitem
            (vol_order_id,
             vol_line_item_id,
             vol_package_id,
             vol_product_id,
             vol_quantity,
             vol_order_status,
             vol_ins_date,
             vol_error_msg,
             vol_partner_id,
             vol_parent_oid,
             vol_ccf_flag,
             vol_return_file_msg,
             vol_embossedline,
             vol_embossed_line1,
			 vol_logo_id
			 ,vol_activation_sticker_id--Modified for VMS-8938
			 )
          VALUES
            (l_order_id,
             l_line_item_id,
             l_package_id,
             l_product_id,
             1,
             l_order_stat,
             SYSDATE,
             'OK',
             'Replace_Partner_ID',
             l_parent_id,
             decode(l_form_factor,'V',2,1),
             NULL,
             l_encr_embname,         --Modified for VMS-810 (Replacement Processing: Emboss Line 3 and Emboss Line 4)
             l_cust_business_name,   --Modified for VMS-810 (Replacement Processing: Emboss Line 3 and Emboss Line 4)
			 l_logo_id   --- Added for VMS-2428.
			 ,l_activation_sticker_id --Modified for VMS-8938
			 ); 

            IF l_form_factor = 'V'   --- Added for VMS-4484
             THEN

             SELECT cip_param_value
		        INTO l_encr_key
			FROM vmscms.cms_inst_param
		       WHERE cip_inst_code = 1
		       	 AND cip_param_key = 'FSAPIKEY' ;


             l_serial_proxy_encr :=   vmscms.fn_emaps_main_b2b ('serialNumber='||l_serial_number|| '&' ||'PIN='||l_proxy_number,
                                     l_encr_key);

             END IF;


          INSERT INTO vmscms.vms_line_item_dtl
            (vli_pan_code,
             vli_order_id,
             vli_partner_id,
             vli_lineitem_id,
             vli_parent_oid,
             vli_serial_number,
             vli_proxy_pin_encr,
             vli_proxy_pin_hash)
          VALUES
            (vmscms.gethash(l_new_pan),
             l_order_id,
             'Replace_Partner_ID',
             l_line_item_id,
             l_parent_id,
             l_serial_number,
             l_serial_proxy_encr,
             CASE WHEN l_form_factor ='V' then vmscms.gethash(l_serial_proxy_encr) ELSE NULL END
             );
        END IF;

      END IF;

      -- St Added by Saravanakumar on 03-Aug-2017
      /*
      IF p_message_reasoncode_out = '3720'
      THEN
        l_txn_code := '96';
      ELSE
        l_txn_code := '97';
      END IF;
      */

                 IF l_loadamounttype_in='INITIAL_LOAD_AMOUNT' THEN
                    l_load_amt         :=l_initialload_amt;
                    -- l_adjust_amt:=l_initialload_amt-l_acct_balance;
                  ELSIF l_loadamounttype_in='OTHER_AMOUNT' THEN
                    l_load_amt            := l_loadamount;
                    -- l_adjust_amt:=p_loadamount_in-l_acct_balance;
                  END IF;
                  IF l_load_amt IS NOT NULL THEN
                    UPDATE vmscms.cms_acct_mast
                    SET cam_new_initialload_amt=l_load_amt
                    WHERE cam_inst_code        =1
                    AND cam_acct_no            =l_acct_no
                    AND cam_initialload_amt    < l_load_amt ;
                  END IF;
         IF l_load_amt <>0 and l_loadamounttype_in <> 'CURRENT_BALANCE' THEN
         BEGIN
        vmscms.sp_manual_adj_csr(1,
                                 '000',
                                 '0200',
                                 '03',
                                 '14',--txn code
                                 '0',
                                 l_date, --date
                                 l_time,
                                 l_new_pan,
                                 l_rrn,
                                 NULL,
                                 l_load_amt,
                                 CASE
                                 WHEN p_loadamounttype_in='INITIAL_LOAD_AMOUNT'
                                 THEN '260'
                                 WHEN p_loadamounttype_in='OTHER_AMOUNT'
                                 THEN '262'
                                 END,
                                 p_comment_in,
                                 0,
                                 l_curr_code,
                                 NULL,
                                 NULL,--Reason Description
                                 l_session_id,
                                 l_acct_no,
                                 1,--account type
                                (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                               'x-incfs-ip')),
                                 1,
                                 NULL,
                                 l_final_bal,
                                 l_resp_code,
                                 l_resp_msg);
      EXCEPTION
        WHEN OTHERS THEN
          g_debug.display('Exception in Adjust Balance');
          dbms_output.put_line(SQLERRM);
          p_status_out  := l_resp_code;
          p_err_msg_out := l_resp_msg;
          RETURN;
      END;
      END iF;


     IF l_acct_balance<>0  and l_loadamounttype_in <> 'CURRENT_BALANCE'  THEN
      BEGIN
        vmscms.sp_manual_adj_csr(1,
                                 '000',
                                 '0200',
                                 '03',
                                 '13',--txn code
                                 '0',
                                 l_date, --date
                                 l_time,
                                 l_new_pan,
                                 l_rrn,
                                 NULL,
                                 l_acct_balance,
                                 CASE
                                 WHEN p_loadamounttype_in='INITIAL_LOAD_AMOUNT'
                                 THEN '260'
                                 WHEN p_loadamounttype_in='OTHER_AMOUNT'
                                 THEN '262'
                                 END,
                                 p_comment_in,
                                 0,
                                 l_curr_code,
                                 NULL,
                                 NULL,--Reason Description
                                 l_session_id,
                                 l_acct_no,
                                 1,--account type
                                  (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                               'x-incfs-ip')),
                                 1,
                                 NULL,
                                 l_final_bal,
                                 l_resp_code,
                                 l_resp_msg);
      EXCEPTION
        WHEN OTHERS THEN
          g_debug.display('Exception in Adjust Balance');
          dbms_output.put_line(SQLERRM);
          p_status_out  := l_resp_code;
          p_err_msg_out := l_resp_msg;
          RETURN;
      END;
      IF l_resp_code = '00'
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
      ELSE
        g_debug.display('Adjust Balance Failed');
        p_status_out  := l_resp_code;
        p_err_msg_out := l_resp_msg;
        RETURN;
      END IF;
     END IF;

      BEGIN
        SELECT cam_acct_bal,
               cam_ledger_bal,
               cam_type_code
          INTO l_acct_balance,
               l_ledger_balance,
               l_acct_type
          FROM vmscms.cms_acct_mast
         WHERE cam_acct_no = l_acct_no
           AND cam_inst_code = 1;

      EXCEPTION
        WHEN OTHERS THEN
          p_err_msg_out := 'Error while selecting acct dtl' || SQLERRM;
      END;



      -- En Added by Saravanakumar on 03-Aug-2017

      --Jira Issue: CFIP:188 starts
      --updating the below fields manually
      --since the base procedure doesnot populate these fields in Transactionlog
      UPDATE VMSCMS.TRANSACTIONLOG
         SET correlation_id =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-correlationid')),
             fsapi_username =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-username')),
             partner_id    =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-partnerid')),
             merchant_id   =   p_merchantid_in,
             terminal_id   =   p_terminalid_in
       WHERE rrn = l_rrn;
    --Added for VMS-5733/FSP-991
     IF SQL%ROWCOUNT = 0 THEN
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST
      SET correlation_id =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-correlationid')),
             fsapi_username =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-username')),
             partner_id    =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-partnerid')),
             merchant_id   =   p_merchantid_in,
             terminal_id   =   p_terminalid_in
       WHERE rrn = l_rrn;
   end if;
      --Jira Issue: CFIP:188 ends
       IF p_locationid_in IS NOT NULL THEN
           UPDATE VMSCMS.CMS_TRANSACTION_LOG_DTL
              SET ctd_location_id = p_locationid_in
           WHERE ctd_rrn = l_rrn;
        --Added for VMS-5733/FSP-991
     IF SQL%ROWCOUNT = 0 THEN
       UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST
             SET ctd_location_id = p_locationid_in
           WHERE ctd_rrn = l_rrn;
  end if;
       END IF;

    EXCEPTION
      WHEN OTHERS THEN
        g_debug.display('Exception in Replace Card ' || SQLERRM);
        p_status_out  := vmscms.gpp_const.c_ora_error_status;
        p_err_msg_out := g_err_failure.get_current_error || SQLERRM;
        ROLLBACK;
        --p_status_out  := l_resp_code;
        --p_err_msg_out := l_resp_msg;
        RETURN;
    END;
    --Performance Fix
    SELECT MAX(ccd_call_seq)
      INTO l_call_seq
      FROM vmscms.cms_calllog_details
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
    --Jira Issue: CFIP:187 ends
    IF l_resp_code <> '00'
       AND l_resp_msg <> 'OK'
    THEN
      p_status_out  := l_resp_code;
      p_err_msg_out := l_resp_msg;
      RETURN;
    ELSE
      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';
      g_debug.display('Sending Push notfication request');
      BEGIN
      			---Modified for VMS-4559 - Replacement Push Notification (Physical via CCA)-B2B Spec Consolidation.

           SELECT
            ccs_stat_desc
        INTO
            l_CARD_STATUS
        FROM
            vmscms.CMS_APPL_PAN,vmscms.cms_card_stat
        WHERE
            CAP_PAN_CODE = vmscms.gethash(l_new_pan)
            AND CAP_MBR_NUMB = '000'
            AND ccs_stat_code = cap_card_stat;


        vmscms.pkg_event_push_notification.check_push_notification_config(1,l_prod_code,l_card_type,'03',l_txn_code,l_partner_name,l_event_msg_type
                                                                            ,l_push_config,l_errmsg);

      IF l_errmsg = 'OK'
      THEN

                      IF l_push_config = 'Y'
                      THEN


                            SELECT ctm_tran_desc
                            INTO l_tran_desc
                                          FROM vmscms.cms_transaction_mast
                                         WHERE ctm_inst_code = 1
                                           AND ctm_tran_code = l_txn_code
                                           AND ctm_delivery_channel = '03';


                            SELECT vmscms.fn_dmaps_main(CAM_EMAIL)
                            INTO l_email
                            FROM vmscms.CMS_ADDR_MAST
                            WHERE cam_cust_code = l_cust_code
                            AND cam_addr_flag = 'P'
                            AND cam_inst_code = 1;


                            						--- Modifed for VMS-4509
                vmscms.PKG_EVENT_PUSH_NOTIFICATION.FORM_PUSH_NOTIFICATION_PAYLOAD (p_customer_id_in,
			    l_email ,
                l_acct_balance,
			    l_ledger_balance,SYSDATE,l_tran_desc,l_order_stat,
                l_proxy_number,
			    l_serial_number,
			    CASE WHEN l_form_factor = 'V' then l_serial_proxy_encr else NULL END,
			    l_CARD_STATUS,
			    NULL,
			    NULL,
			    NULL,
			    l_payload_type_in,substr(l_new_pan, length(l_new_pan) - 3),l_payload, l_errmsg);

                       IF  l_errmsg = 'OK'
                       THEN

                       SELECT
                            cip_param_value
                        INTO l_queue_name
                        FROM
                            vmscms.cms_inst_param
                        WHERE
                            cip_inst_code = 1
                            AND cip_param_key = 'EVENT_PROCESS_QueueName';


                        SELECT EXTRACT(DAY FROM TIME) * 24 * 60 * 60 * 1E9 + EXTRACT(HOUR FROM TIME) * 60 * 60 * 1E9 + EXTRACT(MINUTE FROM TIME)
                            * 60 * 1E9 + EXTRACT(SECOND FROM TIME) * 1E9 AS NANOTIME
                            INTO l_nano_time
                        FROM
                        (
                            SELECT
                                SYSTIMESTAMP(9) - TIMESTAMP '1970-01-01 00:00:00 UTC' AS TIME
                            FROM
                                DUAL
                        );

                        VMSCMS.PKG_EVENT_PUSH_NOTIFICATION.INSERT_EVENT_PROCESSING(l_rrn|| '_'|| SUBSTR(l_nano_time, 1, 16),l_payload,l_partner_name,l_event_msg_type,l_queue_name,'PENDING',l_errmsg);

                                IF l_errmsg <> 'OK' THEN

                                    l_errmsg := 'Error while Inserting into Event Processing Table-'||l_errmsg;
                                    RAISE L_EXP;
                                END IF;

                    ELSE

                    l_errmsg := 'Error while forming payload-'|| l_errmsg;
                     RAISE L_EXP;

                    END IF;             --- Payload form End.

            END IF;                     --- Push config end.


      ELSE

          l_errmsg := 'Error while checking Event Notification config-'||l_errmsg;
          RAISE L_EXP;

      END IF;

      EXCEPTION

      WHEN L_EXP THEN
        g_debug.display('Exception during creating transaction log: ' || SQLCODE || ' -ERROR- ' || SQLERRM);
        l_errmsg := SUBSTR(l_errmsg,1,500);
        vmscms.gpp_cards.log_transactionlog(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   l_txn_code,
                                                   'F',
                                                   l_errmsg,
                                                   vmscms.gpp_const.c_failure_res_id,
		                                           'Sending Event Notification Failed.',
                                                   l_timetaken);

      WHEN OTHERS
      THEN
        g_debug.display('Exception during creating transaction log: ' || SQLCODE || ' -ERROR- ' || SQLERRM);
       l_errmsg := SUBSTR(SQLCODE || ' -ERROR- ' || SQLERRM, 1, 200);
        vmscms.gpp_cards.log_transactionlog(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   l_txn_code,
                                                   'F',
                                                   l_errmsg,
                                                   vmscms.gpp_const.c_failure_res_id,
		                                           'Sending Event Notifcation Failed',
                                                   l_timetaken);


      END;
 /*     BEGIN
        vmscms.VMS_INS_PUSH_NOTIFICATION(
          p_instcode=> 1, p_hash_pan=> vmscms.gethash(l_new_pan), p_hold_amount=> l_loadamount, p_rrn=> l_rrn, p_delv_chnl=> '03', p_txn_code=> l_txn_code,
          p_acct_bal=> l_acct_balance, p_ledger_bal=> l_ledger_balance, p_ins_date=> SYSDATE, p_mbr_numb=> l_mbr_numb,
          p_merchant_name=> p_merchantid_in, p_event_status=>'PENDING', p_errmsg=> l_notification_response);
          g_debug.display('Received push notification response:' || l_notification_response);

        IF l_notification_response <> 'OK'
        THEN
          g_debug.display('Exception during push notification:' || l_notification_response);
	      l_notification_response := 'Error while pushing Event Notification -' || l_notification_response;

           vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   l_notification_response,
                                                   vmscms.gpp_const.c_failure_res_id,
						                           NULL,
                                                   l_timetaken);
	    END IF;
      EXCEPTION WHEN OTHERS
      THEN
        g_debug.display('Exception during creating transaction log: ' || SQLCODE || ' -ERROR- ' || SQLERRM);
        l_notification_response := 'Error while calling SP for Event Notification -' || SUBSTR(SQLCODE || ' -ERROR- ' || SQLERRM, 1, 200);
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   l_notification_response,
                                                   vmscms.gpp_const.c_failure_res_id,
		                                           NULL,
                                                   l_timetaken);
      END;
  */
  END IF;

        --SN:Added for VMS-6024
            IF l_renew_replace_option = 'NPP' THEN
                SELECT COUNT(*)
                  INTO l_dcrypt_check
                  FROM vmscms.cms_prod_cattype
                 WHERE cpc_inst_code = 1
                   AND cpc_prod_code = l_renew_replace_prodcode
                   AND cpc_card_type = l_renew_replace_cardtype
                   AND cpc_encrypt_enable = 'N';


                IF (l_dcrypt_check = 1 AND l_encrypt_enable = 'Y') OR (l_dcrypt_check = 0 AND l_encrypt_enable = 'N') THEN
                    UPDATE vmscms.cms_cust_mast
                       SET ccm_first_name = upper(vmscms.fn_dmaps_main(ccm_first_name)),
                           ccm_mid_name = upper(vmscms.fn_dmaps_main(ccm_mid_name)),
                           ccm_last_name = upper(vmscms.fn_dmaps_main(ccm_last_name)),
                           ccm_user_name = upper(vmscms.fn_dmaps_main(ccm_user_name)),
                           ccm_business_name = upper(vmscms.fn_dmaps_main(ccm_business_name)),
                           ccm_mother_name = upper(vmscms.fn_dmaps_main(ccm_mother_name))
                     WHERE ccm_cust_code = l_cust_code
                       AND ccm_inst_code = 1;


                    UPDATE vmscms.cms_addr_mast
                       SET cam_add_one = upper(vmscms.fn_dmaps_main(cam_add_one)),
                           cam_add_two = upper(vmscms.fn_dmaps_main(cam_add_two)),
                           cam_add_three = upper(vmscms.fn_dmaps_main(cam_add_three)),
                           cam_pin_code = upper(vmscms.fn_dmaps_main(cam_pin_code)),
                           cam_phone_one = upper(vmscms.fn_dmaps_main(cam_phone_one)),
                           cam_phone_two = upper(vmscms.fn_dmaps_main(cam_phone_two)),
                           cam_city_name = upper(vmscms.fn_dmaps_main(cam_city_name)),
                           cam_email = upper(vmscms.fn_dmaps_main(cam_email)),
                           cam_mobl_one = upper(vmscms.fn_dmaps_main(cam_mobl_one))
                     WHERE cam_cust_code = l_cust_code
                       AND cam_inst_code = 1;


                END IF;

            END IF;
            --EN:Added for VMS-6024
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
      p_status_out := vmscms.gpp_const.c_rpl_card_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_rpl_card_status);
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
  END replace_card;

  PROCEDURE release_preauth(p_customer_id_in   IN VARCHAR2,
                            p_tran_id_in       IN VARCHAR2,
                            p_tran_date_in     IN VARCHAR2,
                            p_delv_chnl_in     IN VARCHAR2,
                            p_tran_code_in     IN VARCHAR2,
                            p_response_code_in IN VARCHAR2,
                            p_reason_in        IN VARCHAR2,
                            p_comment_in       IN VARCHAR2,
                            p_status_out       OUT VARCHAR2,
                            p_err_msg_out      OUT VARCHAR2) AS
    l_date       VARCHAR2(50);
    l_time       VARCHAR2(20);
    l_api_name   VARCHAR2(50) := 'RELEASE PREAUTH';
    l_field_name VARCHAR2(50);
    l_flag       PLS_INTEGER := 0;
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_plain_pan  VARCHAR2(20);
    l_curr_code  VARCHAR2(20);
    l_acct_bal   PLS_INTEGER := 0;
    /* CFIP 5.5.6
     l_card_no          vmscms.transactionlog.customer_card_no_encr%TYPE;
     l_org_rrn          vmscms.transactionlog.rrn%TYPE;
     l_audit_no         vmscms.transactionlog.system_trace_audit_no%TYPE;
     l_terminal_id      vmscms.transactionlog.terminal_id%TYPE;
     l_business_date    vmscms.transactionlog.business_date%TYPE;
     l_business_time    vmscms.transactionlog.business_time%TYPE;
     l_amount           vmscms.transactionlog.amount%TYPE;
     l_txn_code         vmscms.transactionlog.txn_code%TYPE;
     l_delivery_channel vmscms.transactionlog.delivery_channel%TYPE;
     l_tranfee_amt      vmscms.transactionlog.tranfee_amt%TYPE;
     l_trans_desc       vmscms.transactionlog.trans_desc%TYPE;
    */
    l_rrn         vmscms.transactionlog.rrn%TYPE;
    l_reason_desc vmscms.cms_spprt_reasons.csr_reasondesc%TYPE;
    l_tran_date   vmscms.transactionlog.business_date%TYPE;
    l_tran_time   vmscms.cms_preauth_transaction.cpt_txn_time%TYPE;
    l_start_time  NUMBER;
    l_end_time    NUMBER;
    l_timetaken   NUMBER;
    --performance change
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no      vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;
    l_call_seq     vmscms.cms_calllog_details.ccd_call_seq%TYPE;

    --5.5.6

    l_card_no          VARCHAR2(30);
    l_org_rrn          vmscms.cms_preauth_transaction.cpt_rrn%TYPE;
    l_terminal_id      vmscms.cms_preauth_transaction.cpt_terminalid%TYPE;
    l_business_date    vmscms.cms_preauth_transaction.cpt_txn_date%TYPE;
    l_business_time    vmscms.cms_preauth_transaction.cpt_txn_time%TYPE;
    l_amount           vmscms.cms_preauth_transaction.cpt_totalhold_amt%TYPE;
    l_txn_code         vmscms.cms_preauth_transaction.cpt_txn_code%TYPE;
    l_delivery_channel vmscms.cms_preauth_transaction.cpt_delivery_channel%TYPE;
v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
  BEGIN
    l_start_time := dbms_utility.get_time;
    --Fetching the active PAN for the input customer id
    --      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
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
    l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);
    g_debug.display('l_encr_pan' || l_encr_pan);
    g_debug.display('l_plain_pan' || l_plain_pan);
    --Check for madatory fields
    CASE
      WHEN p_customer_id_in IS NULL THEN
        l_field_name := 'CUSTOMER ID';
        l_flag       := 1;
      WHEN p_tran_id_in IS NULL THEN
        l_field_name := 'TRANSACTION ID';
        l_flag       := 1;
      WHEN p_tran_date_in IS NULL THEN
        l_field_name := 'TRANSACTION DATE';
        l_flag       := 1;
      WHEN p_delv_chnl_in IS NULL THEN
        l_field_name := 'DELIVERY CHANNEL';
        l_flag       := 1;
      WHEN p_tran_code_in IS NULL THEN
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
        NULL;
    END CASE;
    g_debug.display('In release preauth' || p_customer_id_in);
    g_debug.display('p_reason_in' || p_reason_in);
    --throw error if mandatory fields are not given
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
    ---for testing ends
    g_debug.display('l_encr_pan' || l_encr_pan);
    --get the date from the header
    --getting the date
    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);
    --l_date := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11); --for testing
    l_date := to_char(to_date(l_date,
                              'dd-mm-yyyy'),
                      'yyyymmdd');
    --getting the time
    l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-date')),
                     18,
                     8);
    --l_time := '08:49:37';
    l_time := REPLACE(l_time,
                      ':',
                      '');
    g_debug.display('l_date' || l_date);
    g_debug.display('l_time' || l_time);
    --fetching the currency
    --Performance Fix
    SELECT cbp_param_value
      INTO l_curr_code
      FROM vmscms.cms_prod_cattype,
           vmscms.cms_bin_param
     WHERE cpc_inst_code = cbp_inst_code
       AND cpc_profile_code = cbp_profile_code
       AND cpc_prod_code = l_prod_code
       AND cpc_card_type = l_card_type
       AND cpc_inst_code = 1
       AND cbp_param_name = 'Currency';
    g_debug.display('l_curr_code' || l_curr_code);
    l_tran_date := to_char(trunc(to_date(p_tran_date_in,
                                         'YYYY-MM-DD HH24:MI:SS')),
                           'YYYYMMDD');
    -- 5.5.6
    l_tran_time := to_char(to_date(p_tran_date_in,
                                   'YYYY-MM-DD HH24:MI:SS'),
                           'HH24MISS');
    /*  5.5.6 start
    --Fetching the parameter values to be passed
      SELECT vmscms.fn_dmaps_main(customer_card_no_encr) cardnumber,
             rrn,
             system_trace_audit_no,
             terminal_id,
             business_date,
             business_time,
             --nvl(to_char(amount, '9999999990.99'), '0.00') amount,
             txn_code,
             delivery_channel,
             tranfee_amt,
             trans_desc
        INTO l_card_no,
             l_org_rrn,
             l_audit_no,
             l_terminal_id,
             l_business_date,
             l_business_time,
             --l_amount,
             l_txn_code,
             l_delivery_channel,
             l_tranfee_amt,
             l_trans_desc
        FROM vmscms.transactionlog
       WHERE rrn = p_tran_id_in
         AND delivery_channel = p_delv_chnl_in
         AND txn_code = p_tran_code_in
         AND response_code = p_response_code_in
         AND business_date = l_tran_date;

    -- FSAPI Prod bug fixes 5.5.4 Starts
    -- get hold amount from cms_preauth_transaction table for given transaction

    select cpt_totalhold_amt  -- pass this value to the l_amount variable
      into l_amount
        from vmscms.cms_preauth_transaction
       where cpt_rrn =  l_org_rrn --'OR00000035B6'
         and cpt_txn_date = l_business_date --'20160516'
         and cpt_inst_code = '1'  --hardcode it as 1
         and cpt_card_no = l_hash_pan
         AND cpt_txn_time = l_business_time --'084739'  --l_business_time
         and upper(cpt_preauth_validflag) <> 'N'
         AND upper(cpt_expiry_flag) = 'N';
    -- FSAPI Prod bug fixes 5.5.4 ends*/

    -- FSAPI 5.5.6 Start

--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
       WHERE  OPERATION_TYPE='ARCHIVE'
       AND OBJECT_NAME='CMS_PREAUTH_TRANSACTION_EBR';

       v_Retdate := TO_DATE(SUBSTR(TRIM(l_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
    SELECT vmscms.fn_dmaps_main(cpt_card_no_encr),
           cpt_rrn,
           cpt_terminalid,
           cpt_txn_date,
           cpt_txn_time,
           cpt_totalhold_amt,
           cpt_txn_code,
           cpt_delivery_channel
      INTO l_card_no,
           l_org_rrn,
           l_terminal_id,
           l_business_date,
           l_business_time,
           l_amount,
           l_txn_code,
           l_delivery_channel
      FROM vmscms.CMS_PREAUTH_TRANSACTION --Added for VMS-5735/FSP-991
     WHERE cpt_rrn = p_tran_id_in --'OR00000035B6'
       AND cpt_txn_date = l_tran_date --'20160516'
       AND cpt_txn_time = l_tran_time --'084739'  --l_business_time
       AND cpt_inst_code = '1' --hardcode it as 1
       AND upper(cpt_preauth_validflag) <> 'N'
       AND upper(cpt_expiry_flag) = 'N'
       AND cpt_delivery_channel = p_delv_chnl_in
       AND cpt_txn_code = p_tran_code_in;
	ELSE
	 SELECT vmscms.fn_dmaps_main(cpt_card_no_encr),
           cpt_rrn,
           cpt_terminalid,
           cpt_txn_date,
           cpt_txn_time,
           cpt_totalhold_amt,
           cpt_txn_code,
           cpt_delivery_channel
      INTO l_card_no,
           l_org_rrn,
           l_terminal_id,
           l_business_date,
           l_business_time,
           l_amount,
           l_txn_code,
           l_delivery_channel
      FROM vmscms_HISTORY.CMS_PREAUTH_TRANSACTION_HIST --Added for VMS-5735/FSP-991
     WHERE cpt_rrn = p_tran_id_in --'OR00000035B6'
       AND cpt_txn_date = l_tran_date --'20160516'
       AND cpt_txn_time = l_tran_time --'084739'  --l_business_time
       AND cpt_inst_code = '1' --hardcode it as 1
       AND upper(cpt_preauth_validflag) <> 'N'
       AND upper(cpt_expiry_flag) = 'N'
       AND cpt_delivery_channel = p_delv_chnl_in
       AND cpt_txn_code = p_tran_code_in;
END IF;
    --5.5.6 ends
    g_debug.display('l_card_no' || l_card_no);
    g_debug.display('l_org_rrn' || l_org_rrn);
    --g_debug.display('l_audit_no' || l_audit_no);
    g_debug.display('l_terminal_id' || l_terminal_id);
    g_debug.display('l_business_date' || l_business_date);
    g_debug.display('l_business_time' || l_business_time);
    g_debug.display('l_amount' || l_amount);
    g_debug.display('l_txn_code' || l_txn_code);
    g_debug.display('l_delivery_channel' || l_delivery_channel);
    -- g_debug.display('l_tranfee_amt' || l_tranfee_amt);
    --fetching the rrn
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);
    --fetching the reason desc from input reason code
    SELECT csr_reasondesc
      INTO l_reason_desc
      FROM vmscms.cms_spprt_reasons
     WHERE csr_spprt_key = 'PREHOLDREL'
       AND csr_spprt_rsncode = p_reason_in
       AND csr_inst_code = '1';
    g_debug.display('l_reason_desc' || l_reason_desc);
    g_debug.display('callin SP_PREAUTH_HOLD_RELEASE ' || p_comment_in);
    BEGIN
      vmscms.sp_preauth_hold_release(1, --prm_inst_code,
                                     '0200', --prm_msg_typ,
                                     '0', --prm_rvsl_code,
                                     l_rrn, --prm_rrn
                                     '03', --p_delv_chnl_in,
                                     NULL, --prm_terminal_id,
                                     NULL, --prm_merc_id,
                                     '11', --prm_txn_code,
                                     '0', --prm_txn_type,
                                     '0', --prm_txn_mode,
                                     l_date, --prm_business_date,
                                     l_time, --prm_business_time,
                                     l_card_no, --prm_card_no,
                                     l_amount, --prm_actual_amt,
                                     NULL, --prm_bank_code,
                                     NULL, --prm_stan,
                                     l_business_date, --prm_orgnl_business_date,
                                     l_business_time, --prm_orgnl_business_time,
                                     l_txn_code, --prm_orgnl_txn_code,
                                     l_delivery_channel, --prm_orgnl_delivery_chnl,
                                     l_org_rrn, --prm_orgnl_rrn,
                                     '000', --prm_mbr_numb,
                                     l_terminal_id, --prm_orgnl_terminal_id,
                                     l_curr_code,
                                     p_comment_in, --prm_remark,
                                     (CASE p_reason_in WHEN 69 THEN
                                      'Duplicate Auth' WHEN 70 THEN
                                      'Void Do Not Proceed' WHEN 71 THEN
                                      'Merchant Error' END), --prm_reason_code
                                     l_reason_desc, --prm_reason_desc,
                                     (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                  'x-incfs-sessionid')), --prm_call_id,
                                     NULL, --prm_ins_user,
                                     NULL, --prm_merchant_name,
                                     NULL, --prm_merchant_city,
                                     NULL, --prm_merc_state,
                                     (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                  'x-incfs-ip')), --prm_ipaddress,
                                     l_plain_pan, --prm_call_card_no,
                                     p_status_out,
                                     l_acct_bal, --prm_acct_bal,
                                     p_err_msg_out);
      --Jira Issue: CFIP:188 starts
      --updating the below fields manually
      --since the base procedure doesnot populate these fields in Transactionlog
      UPDATE VMSCMS.TRANSACTIONLOG
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
--Added for VMS-5733/FSP-991
     IF SQL%ROWCOUNT = 0 THEN
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST
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
  end if;
      --Jira Issue: CFIP:188 ends
    EXCEPTION
      WHEN OTHERS THEN
        p_status_out  := p_status_out;
        p_err_msg_out := p_err_msg_out;
        RETURN;
    END;
    g_debug.display('p_status_out' || p_status_out);
    g_debug.display('l_acct_bal' || l_acct_bal);
    g_debug.display('p_err_msg_out' || p_err_msg_out);
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
    --Jira Issue: CFIP:187 ends
    IF p_status_out = '00'
    THEN
      BEGIN
        g_debug.display('callin sp_clawback_recovery ');
        vmscms.sp_clawback_recovery('1',
                                    l_card_no,
                                    '000',
                                    p_err_msg_out);
      EXCEPTION
        WHEN OTHERS THEN
          p_status_out  := vmscms.gpp_const.c_clw_bck_status;
          p_err_msg_out := p_err_msg_out;
          RETURN;
      END;
    ELSE
      p_status_out  := p_status_out;
      p_err_msg_out := p_err_msg_out;
      RETURN;
    END IF;
    --For Success
    p_status_out  := vmscms.gpp_const.c_success_status;
    p_err_msg_out := 'SUCCESS';
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
      p_status_out := vmscms.gpp_const.c_release_preauth_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_release_preauth_status);
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
  END release_preauth;
  --reset online password
  PROCEDURE reset_online_password(p_customer_id_in  IN VARCHAR2,
                                  p_comment_in      IN VARCHAR2,
                                  p_firstname_out   OUT VARCHAR2,
                                  p_lastname_out    OUT VARCHAR2,
                                  p_email_out       OUT VARCHAR2,
                                  p_panlastfour_out OUT VARCHAR2,
                                  p_prod_out        OUT VARCHAR2,
                                  p_password_out    OUT VARCHAR2,
                                  p_lang_out        OUT VARCHAR2,
                                  p_status_out      OUT VARCHAR2,
                                  p_err_msg_out     OUT VARCHAR2) AS
    l_date       VARCHAR2(50);
    l_time       VARCHAR2(50);
    l_api_name   VARCHAR2(50) := 'RESET ONLINE PASSWORD';
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_plain_pan  VARCHAR2(20);
    l_curr_code  VARCHAR2(20);
    l_charset    VARCHAR2(50);
    l_seed       VARCHAR2(50);
    l_rrn        vmscms.transactionlog.rrn%TYPE;
    l_lenth      VARCHAR2(3);
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;
    --performance change
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no      vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;
    l_call_seq     vmscms.cms_calllog_details.ccd_call_seq%TYPE;
	  l_encrypt_enable      vmscms.cms_prod_cattype.cpc_encrypt_enable%TYPE;
  BEGIN
    l_start_time := dbms_utility.get_time;
    SELECT cip_param_value
      INTO l_lenth
      FROM cms_inst_param
     WHERE cip_param_key = 'CUST PASSWORD LENGTH'
       AND cip_inst_code = 1;
    g_debug.display('sys_guid' || sys_guid);
    l_charset := sys_guid();
    g_debug.display('l_charset' || l_charset);
    g_debug.display('l_seed' || l_seed);
    l_seed := to_char(systimestamp,
                      'YYYYDDMMHH24MISSFFFF');
    g_debug.display('l_seed' || l_seed);
    dbms_random.seed(val => l_seed);
    g_debug.display('l_seed' || l_seed);
    g_debug.display('l_seed' || l_seed);
    g_debug.display('p_password_out' || p_password_out);
    FOR i IN 1 .. l_lenth
    LOOP
      p_password_out := p_password_out || substr(l_charset,
                                                 floor(dbms_random.value(0,
                                                                         length(l_charset))),
                                                 1);
    END LOOP;
    g_debug.display('p_password_out' || p_password_out);
    p_password_out := lower(p_password_out);
    --Fetching the active PAN for the input customer id
    --      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
    --                                     l_hash_pan,
    --                                     l_encr_pan);
    --
    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_cust_code,
                                   p_prod_out,
                                   l_card_type,
                                   l_proxy_no,
                                   l_cardstat,
                                   l_acct_no,
                                   l_masked_pan,
                                   l_profile_code);
    l_plain_pan       := vmscms.fn_dmaps_main(l_encr_pan);
    p_panlastfour_out := substr(l_masked_pan,
                                length(l_masked_pan) - 3,
                                length(l_masked_pan));
    g_debug.display('l_encr_pan' || l_encr_pan);
    g_debug.display('l_plain_pan' || l_plain_pan);
    --fetching the rrn
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);
    --getting the date
    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);
    --l_date := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11);
    l_date := to_char(to_date(l_date,
                              'dd-mm-yyyy'),
                      'yyyymmdd');
    --getting the time
    l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-date')),
                     18,
                     8);
    --l_time := '08:49:37';
    l_time := REPLACE(l_time,
                      ':',
                      '');
    g_debug.display('l_date' || l_date);
    g_debug.display('l_time' || l_time);
    --fetching the currency
    --Performance Fix
    SELECT cbp_param_value, cpc_encrypt_enable,
           CASE cbp_param_value
             WHEN '124' THEN
              'Fr'
             WHEN '840' THEN
              'En'
           END AS template_lang
      INTO l_curr_code,
           l_encrypt_enable,
           p_lang_out
      FROM vmscms.cms_prod_cattype,
           vmscms.cms_bin_param
     WHERE cpc_inst_code = cbp_inst_code
       AND cpc_profile_code = cbp_profile_code
       AND cpc_prod_code = p_prod_out
       AND cpc_card_type = l_card_type
       AND cpc_inst_code = 1
       AND cbp_param_name = 'Currency';
    ---fields required for sending email
    --      SELECT CASE a.cbp_param_value
    --                WHEN '124' THEN
    --                 'Fr'
    --                ELSE
    --                 'En'
    --             END AS template_lang
    --        INTO p_lang_out
    --        FROM vmscms.cms_bin_param a,
    --             vmscms.cms_prod_mast b,
    --             vmscms.cms_cust_mast c,
    --             vmscms.cms_appl_mast d
    --       WHERE a.cbp_profile_code = b.cpm_profile_code
    --         AND b.cpm_prod_code = d.cam_prod_code
    --         AND d.cam_cust_code = c.ccm_cust_code
    --         AND c.ccm_cust_id = p_customer_id_in
    --         AND a.cbp_param_name = 'Currency';
    --      SELECT firstname, lastname, panlast4, email, prod
    --        INTO p_firstname_out,
    --             p_lastname_out,
    --             p_panlastfour_out,
    --             p_email_out,
    --             p_prod_out
    --        FROM (SELECT a.ccm_first_name firstname,
    --                     a.ccm_last_name lastname,
    --                     substr(c.cap_mask_pan,
    --                            length(c.cap_mask_pan) - 3,
    --                            length(c.cap_mask_pan)) panlast4,
    --                     b.cam_email email,
    --                     e.cpm_prod_code prod
    --                FROM vmscms.cms_cust_mast a,
    --                     vmscms.cms_addr_mast b,
    --                     vmscms.cms_appl_pan  c,
    --                     vmscms.cms_appl_mast d,
    --                     vmscms.cms_prod_mast e
    --               WHERE a.ccm_cust_code = b.cam_cust_code
    --                 AND a.ccm_cust_code = c.cap_cust_code
    --                 AND a.ccm_cust_code = d.cam_cust_code
    --                 AND d.cam_prod_code = e.cpm_prod_code
    --                 AND cap_active_date IS NOT NULL
    --                 AND cap_card_stat NOT IN ('9')
    --                 AND a.ccm_cust_id = p_customer_id_in)
    --       WHERE rownum < 2;
    SELECT
       --a.ccm_first_name firstname,
       -- a.ccm_last_name  lastname,
       -- b.cam_email      email
		   decode(l_encrypt_enable,'Y', vmscms.fn_dmaps_main(a.ccm_first_name),a.ccm_first_name) firstname,
		   decode(l_encrypt_enable,'Y', vmscms.fn_dmaps_main(a.ccm_last_name),a.ccm_last_name) lastname,
		   decode(l_encrypt_enable,'Y', vmscms.fn_dmaps_main(b.cam_email),b.cam_email) email
      INTO p_firstname_out,
           p_lastname_out,
           p_email_out
      FROM vmscms.cms_cust_mast a,
           vmscms.cms_addr_mast b
     WHERE a.ccm_cust_code = l_cust_code
       AND a.ccm_inst_code = 1
       AND a.ccm_cust_code = b.cam_cust_code
       AND a.ccm_inst_code = b.cam_inst_code
       AND b.cam_addr_flag = 'P';
    BEGIN
      g_debug.display('callin sp_resetcustomer_password ');
      vmscms.sp_resetcustomer_password(1, --P_INST_CODE
                                       l_plain_pan, --P_PAN_CODE
                                       '03', --P_DELIVERY_CHANNEL
                                       '30', --P_TXN_CODE
                                       l_rrn, --P_RRN
                                       p_password_out, --P_PASSWORD
                                       '0', --P_TXN_MODE
                                       l_date, ----P_TRAN_DATE
                                       l_time,
                                       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                    'x-incfs-ip')), --P_IPADDRESS
                                       l_curr_code, --P_CURR_CODE
                                       '0', --P_RVSL_CODE
                                       NULL, --P_BANK_CODE
                                       '0200', --P_MSG
                                       '000', --P_MBRNUMB
                                       NULL, --P_STAN
                                       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                    'x-incfs-sessionid')), --P_CALL_ID
                                       NULL, --P_INS_USER
                                       p_comment_in, --P_REMARK
                                       p_status_out,
                                       p_err_msg_out);
      g_debug.display('p_status_out' || p_status_out);
      g_debug.display('p_err_msg_out' || p_err_msg_out);
    EXCEPTION
      WHEN OTHERS THEN
        p_status_out  := p_status_out;
        p_err_msg_out := p_err_msg_out;
        RETURN;
    END;
    --Performance Fix
    SELECT MAX(ccd_call_seq)
      INTO l_call_seq
      FROM cms_calllog_details
     WHERE ccd_acct_no = l_acct_no
       AND ccd_inst_code = 1
       AND ccd_rrn = l_rrn
       AND ccd_call_id = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-sessionid'));
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
    --Jira Issue: CFIP:187 ends
    IF p_status_out <> '00'
       AND p_err_msg_out <> 'OK'
    THEN
      p_status_out  := p_status_out;
      p_err_msg_out := p_err_msg_out;
      RETURN;
    ELSE
      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';
    END IF;
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
      p_status_out := vmscms.gpp_const.c_reset_password_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_reset_password_status);
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
  END reset_online_password;
  PROCEDURE cardtocard_transfer(p_customer_id_in IN VARCHAR2,
                                p_pan_in         IN VARCHAR2,
                                p_amount_in      IN VARCHAR2,
                                p_approved_in    IN VARCHAR2,
                                p_reason_in      IN VARCHAR2,
                                p_comment_in     IN VARCHAR2,
                                p_isfeewaived_in IN VARCHAR2,
                                p_status_out     OUT VARCHAR2,
                                p_err_msg_out    OUT VARCHAR2) AS
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_plain_pan  VARCHAR2(50);
    l_curr_code  VARCHAR2(20);
    l_date       VARCHAR2(50);
    l_time       VARCHAR2(50);
    l_api_name   VARCHAR2(50) := 'CARD TO CARD TRANSFER';
    l_rrn        vmscms.transactionlog.rrn%TYPE;
    l_field_name VARCHAR2(20);
    l_flag       PLS_INTEGER := 0;
    l_fee_amt    PLS_INTEGER;
    l_approved   VARCHAR2(20) := nvl(p_approved_in,
                                     'TRUE');
    l_id_type    vmscms.cms_cust_mast.ccm_id_type%TYPE;
    l_id_number  vmscms.cms_cust_mast.ccm_ssn%TYPE;
    -- CFIP -396 - Changed the datatype of l_amount
    l_amount     NUMBER(18, 3) := to_number(nvl(p_amount_in,
                                                0),
                                            '9,999,999,990.99');
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
    l_call_seq     vmscms.cms_calllog_details.ccd_call_seq%TYPE;
  BEGIN
    l_start_time := dbms_utility.get_time;
    --Fetching the active PAN for the input customer id
    --      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
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
    l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);
    g_debug.display('l_hash_pan' || l_hash_pan);
    g_debug.display('l_encr_pan' || l_encr_pan);
    --Check for madatory fields
    CASE
      WHEN p_pan_in IS NULL THEN
        l_field_name := 'PAN';
        l_flag       := 1;
      WHEN p_amount_in IS NULL THEN
        l_field_name := 'AMOUNT';
        l_flag       := 1;
      WHEN p_approved_in IS NULL THEN
        l_field_name := 'ISAPPROVED';
        l_flag       := 1;
      WHEN p_reason_in IS NULL THEN
        l_field_name := 'REASON';
        l_flag       := 1;
      WHEN p_isfeewaived_in IS NULL THEN
        l_field_name := 'IS FEE WAIVED';
        l_flag       := 1;
      WHEN p_comment_in IS NULL THEN
        l_field_name := 'COMMENT';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;
    g_debug.display('In card to card transfer' || l_amount);
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
    --Checking from pan and two pan should not be same
    --Jira issue CFIP:197 starts
    IF l_plain_pan = p_pan_in
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_card_no_status;
      g_err_invalid_data.raise(l_api_name,
                               ',39,',
                               'FROM AND TO CARD NUMBERS SHOULD NOT BE SAME');
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
    --Jira issue CFIP:197 ends
    --fetching the currency
    --Performance Fix
    SELECT cbp_param_value
      INTO l_curr_code
      FROM vmscms.cms_prod_cattype,
           vmscms.cms_bin_param
     WHERE cpc_inst_code = cbp_inst_code
       AND cpc_profile_code = cbp_profile_code
       AND cpc_prod_code = l_prod_code
       AND cpc_card_type = l_card_type
       AND cpc_inst_code = 1
       AND cbp_param_name = 'Currency';
    g_debug.display('l_encr_pan' || l_encr_pan);
    --getting the date
    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);
    --l_date := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11);
    l_date := to_char(to_date(l_date,
                              'dd-mm-yyyy'),
                      'yyyymmdd');
    --getting the time
    l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-date')),
                     18,
                     8);
    l_time := to_char(to_date(l_time,
                              'HH24:MI:SS'),
                      'HH24MISS');
    --l_time := REPLACE(l_time, ':', '');
    g_debug.display('l_date' || l_date);
    g_debug.display('l_time' || l_time);
    --fetching the rrn
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);
    -- CFIP-351 Get decrypted SSN to pass to the vmscms procedure
    SELECT ccm_id_type,
           nvl(vmscms.fn_dmaps_main(ccm_ssn_encr),
               ccm_ssn)
      INTO l_id_type,
           l_id_number
      FROM cms_cust_mast
     WHERE ccm_cust_id = p_customer_id_in;
    IF upper(l_approved) = 'TRUE'
    THEN
      BEGIN
        BEGIN
          --Below query is required to validate session against a card number
          SELECT nvl(MAX(ccd_call_seq),
                     0) + 1
            INTO l_call_seq
            FROM cms_calllog_details
           WHERE ccd_inst_code = 1
             AND ccd_call_id =
                 (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                              'x-incfs-sessionid'))
             AND ccd_pan_code = l_hash_pan;
        END;
        INSERT INTO cms_calllog_details
          (ccd_inst_code,
           ccd_call_id,
           ccd_pan_code,
           ccd_call_seq,
           ccd_rrn,
           ccd_devl_chnl,
           ccd_txn_code,
           ccd_tran_date,
           ccd_tran_time,
           ccd_comments,
           ccd_ins_user,
           ccd_fsapi_username,
           ccd_acct_no,
           ccd_ins_date)
        VALUES
          (1,
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-sessionid')),
           l_hash_pan,
           l_call_seq,
           l_rrn,
           '03',
           '39',
           l_date,
           l_time,
           p_comment_in,
           NULL,
           sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                       'x-incfs-username'),
           l_acct_no,
           SYSDATE);
      END;
      g_debug.display('calling sp_update_feeplan');
      vmscms.sp_card_to_card_transfer_ivr(1, --P_INST_CODE
                                          '0200', --P_MSG
                                          l_rrn, --P_RRN
                                          '03', -- p_delivery_channel
                                          NULL, --p_term_id
                                          39, --P_TXN_CODE
                                          0, --P_TXN_MODE
                                          l_date, --P_TRAN_DATE
                                          l_time, --p_tran_time,
                                          l_plain_pan, --p_from_card_no
                                          NULL, --p_from_card_expry
                                          NULL, --p_bank_code
                                          l_amount, --P_TXN_AMT
                                          NULL, --P_MCC_CODE
                                          l_curr_code, --P_CURR_CODE
                                          p_pan_in, --P_TO_CARD_NO,
                                          NULL, --P_TO_EXPRY_DATE
                                          NULL, --P_STAN
                                          NULL, --NULL, --P_LUPD_USER
                                          0, --P_RVSL_CODE
                                          NULL, --P_ANI
                                          NULL, --P_DNI
                                          (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                       'x-incfs-ip')), -- p_ipaddress,
                                          l_id_type, --p_id_type
                                          l_id_number, --P_ID_NUMBER
                                          NULL, --p_mob_no ,
                                          NULL, --p_device_id ,
                                          NULL, --p_ctc_binflag
                                          p_status_out,
                                          p_err_msg_out,
                                          l_fee_amt,
                                          -- Fee flag
                                          CASE upper(p_isfeewaived_in) WHEN
                                          'TRUE' THEN 'Y' WHEN 'FALSE' THEN 'N' ELSE 'Y' END);
      g_debug.display('p_status_out' || p_status_out);
      g_debug.display('p_err_msg_out' || p_err_msg_out);
      g_debug.display('l_fee_amt' || l_fee_amt);
      --Jira Issue: CFIP:188 starts
      --updating the below fields manually
      --since the base procedure doesnot populate these fields in Transactionlog
      UPDATE VMSCMS.TRANSACTIONLOG
         SET correlation_id =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-correlationid')),
             fsapi_username =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-username')),
             partner_id    =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-partnerid')),
             remark         = p_comment_in,
             add_ins_user   = NULL
       WHERE rrn = l_rrn;
   --Added for VMS-5733/FSP-991
     IF SQL%ROWCOUNT = 0 THEN
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST
           SET correlation_id =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-correlationid')),
             fsapi_username =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-username')),
             partner_id    =
             (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                          'x-incfs-partnerid')),
             remark         = p_comment_in,
             add_ins_user   = NULL
       WHERE rrn = l_rrn;
     end if;

      --Jira Issue: CFIP:188 ends
    ELSE
      p_status_out := vmscms.gpp_const.c_approved_status;
      g_err_invalid_data.raise(l_api_name,
                               ',254,',
                               'ISAPPROVED SHOULD BE SET TO TRUE FOR CARD TRANSFER');
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
    --Jira Issue: CFIP:187 ends
    IF p_status_out <> '00'
       AND p_err_msg_out <> 'OK'
    THEN
      p_status_out  := p_status_out;
      p_err_msg_out := p_err_msg_out;
      RETURN;
    ELSE
      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';
    END IF;
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
      p_status_out := vmscms.gpp_const.c_card_transfer_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_card_transfer_status);
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
  END cardtocard_transfer;
  PROCEDURE decrypt_pan(p_card_id_in  IN VARCHAR2,
                        p_pan_out     OUT VARCHAR2,
                        p_status_out  OUT VARCHAR2,
                        p_err_msg_out OUT VARCHAR2) AS
    l_hash_pan    vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan    vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_api_name    VARCHAR2(20) := 'Get CardId Info';
    l_customer_id vmscms.cms_cust_mast.ccm_cust_id%TYPE;
    l_card_id     vmscms.cms_appl_pan.cap_card_id%TYPE;
    bins_do_not_match EXCEPTION;
  BEGIN
    g_debug.display('Get Card Info');
    --validating card id
    SELECT cap_card_id
      INTO l_card_id
      FROM vmscms.cms_appl_pan
     WHERE cap_card_id = substr(p_card_id_in,
                                -12);
    --Invoke the get_clr_pan function get the 16 digit card
    IF l_card_id IS NOT NULL
    THEN
      SELECT vmscms.vmsprm.get_clr_pan(p_card_id_in)
        INTO p_pan_out
        FROM dual;
      p_status_out := vmscms.gpp_const.c_success_status;
    END IF;
    --to make sure user is providing valid CARDID and not any number
    IF substr(p_card_id_in,
              1,
              6) <> substr(p_pan_out,
                           1,
                           6)
    THEN
      RAISE bins_do_not_match;
    END IF;
    --not needed for CARDID because we do not have customer ID or partner ID
    /*      --Fetching the active PAN for the input customer id
    SELECT vmscms.gethash(p_pan_out) INTO l_hash_pan FROM dual;
    --Fetching the customer id from Card
    SELECT ccm_cust_id
    INTO l_customer_id
    FROM vmscms.cms_cust_mast
    WHERE ccm_cust_code =
    (SELECT cap_cust_code
    FROM cms_appl_pan
    WHERE cap_pan_code = l_hash_pan);
    g_debug.display('l_hash_pan' || l_hash_pan);
    g_debug.display('l_customer_id' || l_customer_id);
    vmscms.gpp_pan.get_pan_details(l_customer_id, l_hash_pan, l_encr_pan);
    g_debug.display('l_hash_pan' || l_hash_pan);
    g_debug.display('l_encr_pan' || l_encr_pan);
    p_status_out := vmscms.gpp_const.c_success_status;
    vmscms.gpp_transaction.audit_transaction_log(l_api_name,
    l_customer_id, --customer id
    l_hash_pan, --hash pan
    l_encr_pan, --encrypted pan
    'C', --vmscms.gpp_const.c_success_flag,
    p_err_msg_out,
    vmscms.gpp_const.c_success_res_id,
    NULL); --Remarks
    */
  EXCEPTION
    WHEN bins_do_not_match THEN
      p_err_msg_out := 'Input and output BIN''s do not match';
      p_pan_out     := NULL;
      p_status_out  := 'Error';
    WHEN OTHERS THEN
      p_pan_out    := NULL;
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name,
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      --not needed for CARDID because we do not have customer ID or partner ID
    /*
    vmscms.gpp_transaction.audit_transaction_log(l_api_name,
    l_customer_id,
    l_hash_pan,
    l_encr_pan,
    'F', --vmscms.gpp_const.c_failure_flag,
    p_err_msg_out,
    vmscms.gpp_const.c_failure_res_id,
    NULL); --Remarks
    */
  END decrypt_pan;
  PROCEDURE init IS
  BEGIN
    -- initialize all errors here
    g_err_nodata           := fsfw.fserror_t('E-NO-DATA',
                                             '$1 $2');
    g_err_unknown          := fsfw.fserror_t('E-UNKNOWN',
                                             'Unknown error: $1 $2',
                                             'NOTIFY');
    g_err_mandatory        := fsfw.fserror_t('E-MANDATORY',
                                             'Mandatory Field is NULL: $1 $2 $3',
                                             'NOTIFY');
    g_err_failure          := fsfw.fserror_t('E-FAILURE',
                                             'Procedure failed: $1 $2 $3');
    g_err_invalid_data     := fsfw.fserror_t('E-INVALID_DATA',
                                             '$1 $2 $3');
    g_err_upd_token_status := fsfw.fserror_t('E-UPDATE_TOKEN_FAILED',
                                             'UPDATE TOKEN FAILED : $1 $2 $3');
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
  END init;
  -- the get_cpp_context function returns the value of the specific
  -- context value set in the application context for the GPP application
  FUNCTION get_gpp_context(p_name_in IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                       p_name_in));
  END get_gpp_context;

  PROCEDURE upgrade_to_personalized_card(p_customer_id_in     IN  VARCHAR2,
                                         p_fee_waiver_flag_in IN  VARCHAR2,
                                         p_isexpedited_in     IN  VARCHAR2,
                                         p_addrone_in         IN  VARCHAR2,
                                         p_addrtwo_in         IN  VARCHAR2,
                                         p_city_in            IN  VARCHAR2,
                                         p_state_in           IN  VARCHAR2,
                                         p_postalcode_in      IN  VARCHAR2,
                                         p_countrycode_in     IN  VARCHAR2,
                                         p_new_maskcardno_out OUT VARCHAR2,
                                         p_status_out         OUT VARCHAR2,
                                         p_err_msg_out        OUT VARCHAR2
                                         ) AS

    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_acct_no    vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_plain_pan  VARCHAR2(50);
    l_date       VARCHAR2(50);
    l_time       VARCHAR2(50);
    l_api_name   VARCHAR2(50) := 'UPGRADE TO PERSONLIZED CARD';
    l_rrn        vmscms.transactionlog.rrn%TYPE;
    l_field_name VARCHAR2(20);
    l_flag       PLS_INTEGER := 0;
    l_fee_amt    PLS_INTEGER;
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;
    l_call_seq   vmscms.cms_calllog_details.ccd_call_seq%TYPE;
    --SN: Added by FSS
    l_gpr_card    vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_acct_number vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cust_id     vmscms.cms_cust_mast.ccm_cust_id%TYPE;
    l_txn_code    vmscms.cms_transaction_mast.ctm_tran_code%TYPE;
    l_isexpedited VARCHAR2(10);
    --EN: Added by FSS
  BEGIN
    l_start_time := dbms_utility.get_time;

    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_acct_no);

    l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);
    g_debug.display('l_hash_pan' || l_hash_pan);
    g_debug.display('l_encr_pan' || l_encr_pan);

    --Check for madatory fields
    CASE
      WHEN p_customer_id_in IS NULL THEN
        l_field_name := 'CUSTOMER ID';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;

    l_isexpedited := nvl(p_isexpedited_in,'FALSE');
	  IF upper(l_isexpedited) NOT IN ('TRUE',
                                    'FALSE')
      THEN
        p_status_out := vmscms.gpp_const.c_invalid_data_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0029,',
                                 'INVALID DATA FOR EXPEDITED SHIPPING');
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F', --vmscms.gpp_const.c_failure_flag,
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL,
                                                     l_timetaken); --Remarks
      RETURN;
    END IF;

      -- Validating whether p_fee_waiver_flag_in input is TRUE or FALSE
      -- Input other than TRUE or FALSE will throw error

      IF upper(p_fee_waiver_flag_in) NOT IN ('TRUE',
                                    'FALSE')
      THEN
        p_status_out := vmscms.gpp_const.c_invalid_data_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0029,',
                                 'INVALID DATA FOR FEE WAIVED');
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F', --vmscms.gpp_const.c_failure_flag,
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL,
                                                     l_timetaken); --Remarks
      RETURN;
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

    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);
    --l_date := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11);
    l_date := to_char(to_date(l_date,
                              'dd-mm-yyyy'),
                      'yyyymmdd');
    --getting the time
    l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-date')),
                     18,
                     8);
    l_time := to_char(to_date(l_time,
                              'HH24:MI:SS'),
                      'HH24MISS');

    g_debug.display('l_date' || l_date);
    g_debug.display('l_time' || l_time);
    --fetching the rrn
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);

    BEGIN
      BEGIN
        --Below query is required to validate session against a card number
        SELECT nvl(MAX(ccd_call_seq),
                   0) + 1
          INTO l_call_seq
          FROM cms_calllog_details
         WHERE ccd_inst_code = 1
           AND ccd_call_id =
               (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                            'x-incfs-sessionid'))
           AND ccd_pan_code = l_hash_pan;
      END;
      INSERT INTO cms_calllog_details
        (ccd_inst_code,
         ccd_call_id,
         ccd_pan_code,
         ccd_call_seq,
         ccd_rrn,
         ccd_devl_chnl,
         ccd_txn_code,
         ccd_tran_date,
         ccd_tran_time,
         ccd_ins_user,
         ccd_fsapi_username,
         ccd_acct_no,
         ccd_ins_date)
      VALUES
        (1,
         (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                      'x-incfs-sessionid')),
         l_hash_pan,
         l_call_seq,
         l_rrn,
         '03',
         '96',
         l_date,
         l_time,
         NULL,
         sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                     'x-incfs-username'),
         l_acct_no,
         SYSDATE);
    END;

	IF upper(l_isexpedited) = 'TRUE'
	THEN
           l_txn_code := '35';
        ELSE
            l_txn_code := '98';
        END IF;


    g_debug.display('calling SP_CHW_GPR_CARDGEN');

    vmscms.sp_chw_gpr_cardgen(1,
                              l_plain_pan,
                              l_rrn,
                              '03',
                              l_txn_code,
                              l_date,
                              l_time,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
			      --If p_fee_waiver_flag_in is TRUE then 'Y' ,FALSE then 'N' is passed
			      --since sp_chw_gpr_cardgen is handling fee waiver flag as 'Y' or 'N'
                              CASE
                              WHEN upper(p_fee_waiver_flag_in) = 'TRUE'
                              THEN
                                'Y'
                              ELSE
                                'N'
                              END,
                              p_addrone_in,
                              p_addrtwo_in,
                              p_city_in,
                              p_state_in,
                              p_postalcode_in,
                              p_countrycode_in,
							  p_status_out,
                              --SN: Modified by FSS
                              l_gpr_card, --P_PAN_NUMBER_OUT,
                              l_acct_number, --P_ACCT_NO_OUT,
                              l_cust_id, --P_CUST_ID_OUT,
                              --EN: Modified by FSS
                              p_err_msg_out);

    g_debug.display('p_status_out' || p_status_out);
    g_debug.display('p_err_msg_out' || p_err_msg_out);
    g_debug.display('l_gpr_card' || l_gpr_card);
    g_debug.display('l_acct_number' || l_acct_number);
    g_debug.display('l_cust_id' || l_cust_id);

    p_new_maskcardno_out := vmscms.fn_getmaskpan(l_gpr_card);

    UPDATE VMSCMS.TRANSACTIONLOG
       SET correlation_id =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-correlationid')),
           fsapi_username =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-username')),
           partner_id    =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-partnerid')),
           add_ins_user   = NULL
     WHERE rrn = l_rrn;
 --Added for VMS-5733/FSP-991
     IF SQL%ROWCOUNT = 0 THEN
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST
          SET correlation_id =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-correlationid')),
           fsapi_username =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-username')),
           partner_id    =
           (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                        'x-incfs-partnerid')),
           add_ins_user   = NULL
     WHERE rrn = l_rrn;
    end if;

    IF p_status_out <> '00'
       AND p_err_msg_out <> 'OK'
    THEN
      p_status_out  := p_status_out;
      p_err_msg_out := p_err_msg_out;
      RETURN;
    ELSE
      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';
    END IF;
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
      p_status_out := vmscms.gpp_const.c_card_transfer_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_card_transfer_status);
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
  END upgrade_to_personalized_card;

  PROCEDURE get_card_status(p_pan_in                    IN VARCHAR2,
                            p_serialnumber_in           IN VARCHAR2,
                            p_card_id_in                IN VARCHAR2,
                            p_card_status_out           OUT VARCHAR2,
                            p_available_balance_out     OUT NUMBER,
                            p_initial_load_amount_out   OUT NUMBER,
                            p_status_out                OUT VARCHAR2,
                            p_err_msg_out               OUT VARCHAR2) AS
    l_cust_code  vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_acct_no    vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_card_id    vmscms.cms_appl_pan.cap_card_id%TYPE;
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;
    c_api_name   CONSTANT VARCHAR2(50) := 'GET_CARD_STATUS';
    l_query       VARCHAR2(1000);
    l_active_date cms_appl_pan.cap_active_date%TYPE;
    l_cust_id     cms_cust_mast.ccm_cust_id%TYPE;

/***************************************************************************************
         * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 09-Sep-2019
         * Modified Reason    : VMS-1058 - Add Initial Load Amount to GET CARD DETAIL API response for CCA
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 09-Sep-2019
         * Build Number       : R20_B0002

	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002

 	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 15-Jun-2020
         * Modified Reason    : VMS-2699 - CCA Enchanment - Virtual Gift Cards
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 15-Jun-2020
         * Build Number       : R32_B0001.

***************************************************************************************/

  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    IF p_card_id_in IS NOT NULL
    THEN
      l_card_id := substr(p_card_id_in,
                          -12);
    END IF;
    l_query := 'SELECT cap_pan_code,cap_pan_code_encr,
                            cap_card_stat,cap_acct_no,
                            cap_active_date,cap_cust_code
                       FROM vmscms.cms_appl_pan a
                      WHERE a.cap_prod_code||to_char(a.cap_card_type) =
                            vmscms.gpp_utils.get_prod_code_card_type(:l_partner_id,
                                                                     a.cap_prod_code,
                                                                     a.cap_card_type)
                        AND ';

    IF p_pan_in IS NOT NULL
    THEN
      l_query := l_query ||
                 ' cap_pan_code=vmscms.gethash(:p_pan_in) and cap_mbr_numb=''000''';

      EXECUTE IMMEDIATE l_query
        INTO l_hash_pan, l_encr_pan, p_card_status_out, l_acct_no, l_active_date, l_cust_code
        USING l_partner_id, p_pan_in;
    ELSIF p_serialnumber_in IS NOT NULL
    THEN
      l_query := 'SELECT * FROM ('||l_query || ' cap_serial_number=: p_serial_number_in
	              ORDER BY CAP_PANGEN_DATE DESC) WHERE rownum = 1';

      ---- and cap_form_factor is null (VMS-2699 CCA Enchanment - Virtual Gift Cards). Dropped the filter condition.

      EXECUTE IMMEDIATE l_query
        INTO l_hash_pan, l_encr_pan, p_card_status_out, l_acct_no, l_active_date, l_cust_code
        USING l_partner_id, p_serialnumber_in;
    ELSIF p_card_id_in IS NOT NULL
    THEN
      l_query := l_query || ' cap_card_id=:l_card_id';
      EXECUTE IMMEDIATE l_query
        INTO l_hash_pan, l_encr_pan, p_card_status_out, l_acct_no, l_active_date, l_cust_code
        USING l_partner_id, l_card_id;
    ELSE
      p_status_out  := vmscms.gpp_const.c_ora_error_status;
      p_err_msg_out := 'Atlease One(pan code/serial number/card id) is mandatory.';
      RETURN;
    END IF;
    g_debug.display('query' || l_query);
    IF p_card_status_out = 0
    THEN
      IF l_active_date IS NULL
      THEN
        p_card_status_out := 'INACTIVE';
      ELSE
        p_card_status_out := 'BLOCKED';
      END IF;
    ELSE
      SELECT ccs_stat_desc
        INTO p_card_status_out
        FROM vmscms.cms_card_stat
       WHERE ccs_stat_code = p_card_status_out;
    END IF;

    SELECT cam_acct_bal,nvl(CAM_NEW_INITIALLOAD_AMT,cam_initialload_amt)
      INTO p_available_balance_out,p_initial_load_amount_out
      FROM vmscms.cms_acct_mast
     WHERE cam_inst_code = 1
       AND cam_acct_no = l_acct_no;

    SELECT ccm_cust_id
      INTO l_cust_id
      FROM vmscms.cms_cust_mast
     WHERE ccm_inst_code = 1
       AND ccm_cust_code = l_cust_code;

    l_end_time    := dbms_utility.get_time;
    l_timetaken   := (l_end_time - l_start_time);
    p_status_out  := vmscms.gpp_const.c_success_status;
    p_err_msg_out := 'SUCCESS';
    /*vmscms.gpp_transaction.audit_transaction_log(c_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 l_cust_id,
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
      g_err_nodata.raise(c_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(c_api_name,
                                                   l_cust_id,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_update_card_status;
      g_err_unknown.raise(c_api_name || ' FAILED',
                          vmscms.gpp_const.c_update_card_status);
      p_err_msg_out := g_err_unknown.get_current_error;
      vmscms.gpp_transaction.audit_transaction_log(c_api_name,
                                                   l_cust_id,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
  END get_card_status;

    PROCEDURE log_transactionlog(p_api_name_in     IN VARCHAR2,
                                  p_customer_id_in  IN VARCHAR2,
                                  p_hash_pan_in     IN VARCHAR2,
                                  p_encr_pan_in     IN VARCHAR2,
								  p_txn_code_in 	IN VARCHAR2,
                                  p_process_flag_in IN VARCHAR2,
                                  p_process_msg_in  IN VARCHAR2,
                                  p_response_id_in  IN VARCHAR2,
                                  p_remarks_in      IN VARCHAR2,
                                  p_timetaken_in    IN VARCHAR2,
								  p_audit_flag		IN VARCHAR2 DEFAULT 'T',
                                  p_fee_calc_in     IN VARCHAR2 DEFAULT 'N',
                                  p_auth_id_in      IN VARCHAR2 DEFAULT NULL) AS

    l_prod_code     vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type     vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no      vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no       vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_acct_bal      vmscms.cms_acct_mast.cam_acct_bal%TYPE;
    l_ledger_bal    vmscms.cms_acct_mast.cam_ledger_bal%TYPE;
    l_cam_type_code vmscms.cms_acct_mast.cam_type_code%TYPE;
    l_cardstat      vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_date          VARCHAR2(50);
    l_time          VARCHAR2(50);
    l_partner_id    vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_rrn           vmscms.transactionlog.rrn%TYPE;
	l_curr_code		vmscms.transactionlog.currencycode%type;
	l_pan			vmscms.cms_appl_pan.cap_pan_code%type;
    l_resp_out      vmscms.transactionlog.error_msg%type;



/****************************************************************************
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 28-Jun-2020
         * Modified Reason    : VMS-4509 - Replacement Push Notification.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 28-Jun-2020
         * Build Number       : R48_B0002

* Modified By      : Ubaidur Rahman H
     * Modified Date    : 28-JUN-2021
     * Purpose          : VMS-4565 - Resend Email - Virtual Push Notification (Physical via CCA)-B2B Spec Consolidation.
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R48_B3

****************************************************************************/
  BEGIN
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));

	IF p_txn_code_in = '65'           ---- Modified for VMS-4565 - Resend Email
    THEN


    l_rrn :=( sys_context(fsfw.fsconst.c_fsapi_gpp_context,'x-incfs-correlationid') );

    ELSE
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;

     END IF;

	 l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);

    l_date := to_char(to_date(l_date,
                              'dd-mm-yyyy'),
                      'yyyymmdd');
    l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-date')),
                     18,
                     8);

    l_time := REPLACE(l_time,
                      ':',
                      '');

	IF p_audit_flag = 'T' THEN

    IF p_customer_id_in IS NOT NULL
    THEN
      BEGIN
        --Fetching the active PAN for the input customer id
        SELECT cap_prod_code,
               cap_card_type,
               cap_proxy_number,
               cap_card_stat,
               cap_acct_no
          INTO l_prod_code, l_card_type, l_proxy_no, l_cardstat, l_acct_no
          FROM (SELECT cap_prod_code,
                       cap_card_type,
                       cap_proxy_number,
                       cap_card_stat,
                       cap_acct_no
                  FROM vmscms.cms_appl_pan
                 WHERE cap_cust_code =
                       (SELECT ccm_cust_code
                          FROM vmscms.cms_cust_mast
                         WHERE ccm_cust_id = to_number(p_customer_id_in)
                           AND ccm_inst_code = 1
                              --AND ccm_partner_id IN (l_partner_id)
                           AND nvl(ccm_prod_code,
                                   '~') || nvl(to_char(ccm_card_type),
                                               '^') =
                               vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                        p_prod_code_in  => ccm_prod_code,
                                                                        p_card_type_in  => ccm_card_type))
                   AND cap_inst_code = 1 --performance change
                   AND cap_active_date IS NOT NULL --performance change
                   AND cap_card_stat NOT IN ('9')
                 ORDER BY cap_active_date DESC)
         WHERE rownum < 2;
      EXCEPTION
        WHEN no_data_found THEN
          BEGIN
            SELECT cap_prod_code,
                   cap_card_type,
                   cap_proxy_number,
                   cap_card_stat,
                   cap_acct_no
              INTO l_prod_code,
                   l_card_type,
                   l_proxy_no,
                   l_cardstat,
                   l_acct_no
              FROM (SELECT cap_prod_code,
                           cap_card_type,
                           cap_proxy_number,
                           cap_card_stat,
                           cap_acct_no
                      FROM vmscms.cms_appl_pan
                     WHERE cap_cust_code =
                           (SELECT ccm_cust_code
                              FROM vmscms.cms_cust_mast
                             WHERE ccm_cust_id = to_number(p_customer_id_in)
                                  --AND ccm_partner_id IN (l_partner_id)
                               AND nvl(ccm_prod_code,
                                       '~') || nvl(to_char(ccm_card_type),
                                                   '^') =
                                   vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                            p_prod_code_in  => ccm_prod_code,
                                                                            p_card_type_in  => ccm_card_type))
                       AND cap_inst_code = 1
                     ORDER BY cap_pangen_date DESC)
             WHERE rownum < 2;
          EXCEPTION
            WHEN OTHERS THEN
              l_prod_code := NULL;
              l_card_type := NULL;
              l_proxy_no  := NULL;
              l_acct_no   := NULL;
          END;
      END;

      --To be populated only for GET ACCT STMT'DDA Form APIs
      IF p_api_name_in IN ('GET ACCOUNT STATEMENT',
                           'GET DIRECT DEPOSIT FORM')
      THEN
        SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
          INTO l_acct_bal, l_ledger_bal, l_cam_type_code
          FROM vmscms.cms_acct_mast
         WHERE cam_inst_code = 1 --'1'performance change
           AND cam_acct_no = l_acct_no; --performance change
        -- (SELECT cap_acct_no   --performance change
        --  FROM vmscms.cms_appl_pan  --performance change
        --  WHERE cap_inst_code = '1'   --performance change
        --AND cap_pan_code = p_hash_pan_in);  --performance change
      ELSE
        l_acct_bal      := NULL;
        l_ledger_bal    := NULL;
        l_cam_type_code := NULL;
      END IF;
      --Customer id will be NULL in call to SEARCH CUSTOMERS API
    ELSE
      l_prod_code := NULL;
      l_card_type := NULL;
      l_proxy_no  := NULL;
      l_acct_no   := NULL;
    END IF;

    g_debug.display('inserting into transactionlog');

    INSERT INTO vmscms.transactionlog
      (msgtype,
       rrn,
       delivery_channel,
       date_time,
       txn_code,
       txn_type,
       txn_mode,
       txn_status,
       business_date,
       business_time,
       customer_card_no,
       trans_desc,
       instcode,
       customer_card_no_encr,
       customer_acct_no,
       ipaddress,
       error_msg,
       response_code,
       response_id,
       add_ins_date,
       cr_dr_flag,
       time_stamp,
       fsapi_username,
       productid,
       categoryid,
       proxy_number,
       currencycode,
       amount,
       acct_balance,
       ledger_balance,
       acct_type,
       cardstatus,
       tranfee_amt,
       total_amount,
       system_trace_audit_no,
       remark,
       add_ins_user,
       add_lupd_user,
       csr_achactiontaken,
       auth_id,
       partner_id,
       correlation_id)
    VALUES
      ('0200',
       l_rrn,
       '03',
       SYSDATE,
       p_txn_code_in,
       (SELECT ctm_tran_type
          FROM vmscms.cms_transaction_mast
         WHERE ctm_delivery_channel = '03'
           AND ctm_tran_code = p_txn_code_in),
       '0',
       p_process_flag_in,
       --to_char(to_date(l_date, 'dd-mm-yyyy'), 'yyyymmdd'),
       l_date,
       l_time,
       p_hash_pan_in,
       ((SELECT ctm_tran_desc
           FROM vmscms.cms_transaction_mast
          WHERE ctm_delivery_channel = '03'
            AND ctm_tran_code = p_txn_code_in) || ' - ' || p_api_name_in),
       '1',
       p_encr_pan_in,
       l_acct_no,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-ip')),
       p_process_msg_in,
       (SELECT cms_iso_respcde
          FROM vmscms.cms_response_mast
         WHERE cms_delivery_channel = '03'
           AND cms_response_id = p_response_id_in),
       p_response_id_in,
       SYSDATE,
       (SELECT ctm_credit_debit_flag
          FROM vmscms.cms_transaction_mast
         WHERE ctm_delivery_channel = '03'
           AND ctm_tran_code = p_txn_code_in),
       systimestamp,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-username')),
       l_prod_code,
       l_card_type,
       l_proxy_no,
       (CASE WHEN
        p_api_name_in IN ('GET ACCOUNT STATEMENT',
                          'GET DIRECT DEPOSIT FORM') THEN
        (SELECT cip_param_value
           FROM vmscms.cms_inst_param
          WHERE cip_inst_code = '1'
            AND cip_param_key = 'CURRENCY') ELSE NULL END),
       (CASE WHEN
        p_api_name_in IN ('GET ACCOUNT STATEMENT',
                          'GET DIRECT DEPOSIT FORM') THEN
        TRIM(to_char(0,
                     '999999999999999990.99')) ELSE NULL END),
       l_acct_bal,
       l_ledger_bal,
       l_cam_type_code,
       (CASE WHEN
        p_api_name_in IN ('GET ACCOUNT STATEMENT',
                          'GET DIRECT DEPOSIT FORM') THEN l_cardstat ELSE NULL END),
       NULL,
       NULL,
       NULL,
       p_remarks_in,
       NULL,
       NULL,
       p_fee_calc_in,
       p_auth_id_in,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-partnerid')),
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-correlationid')));

    g_debug.display('inserting into cms_transaction_log_dtl');

    INSERT INTO vmscms.cms_transaction_log_dtl
      (ctd_delivery_channel,
       ctd_txn_code,
       ctd_txn_type,
       ctd_txn_mode,
       ctd_business_date,
       ctd_business_time,
       ctd_customer_card_no,
       ctd_process_flag,
       ctd_process_msg,
       ctd_rrn,
       ctd_ins_date,
       ctd_customer_card_no_encr,
       ctd_msg_type,
       ctd_cust_acct_number,
       ctd_txn_amount,
       ctd_txn_curr,
       ctd_actual_amount,
       ctd_fee_amount,
       ctd_waiver_amount,
       ctd_servicetax_amount,
       ctd_cess_amount,
       ctd_bill_amount,
       ctd_bill_curr,
       ctd_inst_code,
       ctd_system_trace_audit_no)
    VALUES
      ('03',
       p_txn_code_in,
       (SELECT ctm_tran_type
          FROM vmscms.cms_transaction_mast
         WHERE ctm_delivery_channel = '03'
           AND ctm_tran_code = p_txn_code_in),
       '0',
       --to_char(to_date(l_date, 'dd-mm-yyyy'), 'yyyymmdd'),
       l_date,
       l_time,
       p_hash_pan_in,
       p_process_flag_in,
       p_process_msg_in,
       l_rrn,/*(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-correlationid')),*/     ----Modified for VMS-1719 - CCA RRN Logging Issue.
       NULL, --ctd_ins_date...populated by trigger after record insertion
       p_encr_pan_in,
       '0200',
       l_acct_no,
       NULL,
       (CASE WHEN
        p_api_name_in IN ('GET ACCOUNT STATEMENT',
                          'GET DIRECT DEPOSIT FORM') THEN
        (SELECT cip_param_value
           FROM vmscms.cms_inst_param
          WHERE cip_inst_code = '1'
            AND cip_param_key = 'CURRENCY') ELSE NULL END),
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       '1',
       NULL);

    g_debug.display('p_encr_pan_in' || p_encr_pan_in);
    g_debug.display('l_date' || l_date);
    g_debug.display('l_time' || l_time);
    g_debug.display('l_rrn' || l_rrn);
    g_debug.display('p_api_name_in' || p_api_name_in);
    g_debug.display('p_timetaken_in' || p_timetaken_in);
    g_debug.display('SYSDATE' || SYSDATE);
    g_debug.display('inserting into cms_rrn_logging');

	ELSIF p_audit_flag = 'A' THEN
		l_pan := VMSCMS.FN_DMAPS_MAIN(P_ENCR_PAN_IN);

		BEGIN
			SELECT cip_param_value INTO l_curr_code
			   FROM vmscms.cms_inst_param
			  WHERE cip_inst_code = '1'
				AND cip_param_key = 'CURRENCY';
		EXCEPTION
            WHEN OTHERS THEN
                l_curr_code := NULL;
		END;

        g_debug.display('Calling VMS_LOG.LOG_TRANSACTIONLOG_AUDIT');

		VMSCMS.VMS_LOG.LOG_TRANSACTIONLOG_AUDIT('0200',
												 l_rrn,
												 '03',
                                                 p_txn_code_in,
												 '0',
												 l_date,
												 l_time,
												 '0',
												 l_pan,
												 p_process_msg_in,
												 0,
												 NULL,
												 p_response_id_in,
												 l_curr_code,
												 (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
													'x-incfs-partnerid')),
												 p_remarks_in,
												 l_resp_out,
												 (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
													'x-incfs-correlationid')),
												 (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
													'x-incfs-ip')),
												  (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
													'x-incfs-username')),
												  p_process_flag_in);

	g_debug.display('p_encr_pan_in' || p_encr_pan_in);
    g_debug.display('l_date' || l_date);
    g_debug.display('l_time' || l_time);
    g_debug.display('l_rrn' || l_rrn);
    g_debug.display('p_api_name_in' || p_api_name_in);
    g_debug.display('p_timetaken_in' || p_timetaken_in);
    g_debug.display('SYSDATE' || SYSDATE);
    g_debug.display('inserting into cms_rrn_logging');

	END IF;

    INSERT INTO vmscms.cms_rrn_logging
      (crl_inst_code,
       crl_card_no,
       crl_trans_date,
       crl_trans_time,
       crl_rrn,
       crl_delivery_channel,
       crl_txn_code,
       crl_time_takenms,
       crl_sever,
       crl_time_stamp,
       crl_msg_type,
       crl_dbresp_timems)
    VALUES
      (1,
       p_encr_pan_in,
       l_date,
       l_time,
       l_rrn,
       '03',
       p_txn_code_in,
       NULL,
       NULL,
       SYSDATE,
       NULL,
       p_timetaken_in);

    g_debug.display('p_api_name_in' || p_api_name_in);

  EXCEPTION
    WHEN no_data_found THEN
      g_err_nodata.raise(p_api_name_in,
                         vmscms.gpp_const.c_ora_error_status);
    WHEN OTHERS THEN


      g_err_unknown.raise(p_api_name_in,
                          vmscms.gpp_const.c_ora_error_status);

  END log_transactionlog;


PROCEDURE resend_email(
      p_customer_id_in   IN VARCHAR2,
      p_email_in         IN VARCHAR2,
	  p_comment_in       IN VARCHAR2,
      p_status_out       OUT VARCHAR2,
      p_err_msg_out      OUT VARCHAR2
    ) AS
/********************************************************************************************
     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 26-JUN-2021
     * Purpose          : VMS-4565 - Resend Email - Virtual Push Notification (Physical via CCA)-B2B Spec Consolidation.
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R48_B3

     * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 21-SEP-2021
     * Purpose          : VMS-4927 - Resend Email Need Decline for Physcial and show proper Eror msg
     * Reviewer         : Saravana Kumar.A
     * Release Number   : VMSGPRHOST_R52_B1

********************************************************************************************/

        l_encr_pan            vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
        l_hash_pan            vmscms.cms_appl_pan.cap_pan_code%TYPE;
        l_acct_no             vmscms.cms_appl_pan.cap_acct_no%TYPE;
        l_prod_code           vmscms.cms_appl_pan.cap_prod_code%TYPE;
        l_mbr_numb            vmscms.cms_appl_pan.cap_mbr_numb%TYPE;
        l_call_seq            vmscms.cms_calllog_details.ccd_call_seq%TYPE;
        l_fee_plan            vmscms.cms_fee_feeplan.cff_fee_plan%TYPE;
        l_card_type           vmscms.cms_appl_pan.cap_card_type%TYPE;

        l_resp_code           VARCHAR2(5);
        l_resp_msg            VARCHAR2(500);

        l_api_name            VARCHAR2(20) := 'RESEND EMAIL';
        l_field_name          VARCHAR2(20);
        l_flag                PLS_INTEGER := 0;
        l_rrn                 vmscms.transactionlog.rrn%TYPE;
        l_partner_id          vmscms.cms_cust_mast.ccm_partner_id%TYPE;
        l_txn_code            VARCHAR2(20):='65';

        l_start_time          NUMBER;
        l_end_time            NUMBER;
        l_timetaken           NUMBER;

        l_card_stat           vmscms.cms_appl_pan.cap_card_stat%TYPE;
        l_acct_balance        vmscms.cms_acct_mast.cam_acct_bal%TYPE;
        l_ledger_balance      vmscms.cms_acct_mast.cam_ledger_bal%TYPE;
        l_date                  VARCHAR2(50);
        l_time                  VARCHAR2(50);
        l_encrypt_enable      vmscms.cms_prod_cattype.cpc_encrypt_enable%TYPE;
        l_serial_number       vmscms.cms_appl_pan.cap_serial_number%TYPE;
        l_proxy_number        vmscms.cms_appl_pan.cap_proxy_number%TYPE;
        l_session_id          VARCHAR2(20);
        l_cust_code           vmscms.cms_appl_pan.cap_cust_code%TYPE;
        l_push_config         VARCHAR2(10);
        l_partner_name        vmscms.cms_prod_cattype.cpc_partner_name%TYPE;
        l_event_msg_type      vmscms.vms_trans_configuration.vtc_event_msg_type%TYPE;
        l_errmsg              VARCHAR2(1000);
        l_card_status         vmscms.cms_card_stat.ccs_stat_desc%TYPE;
        l_payload             VARCHAR2(4000);
        l_queue_name          vmscms.cms_inst_param.cip_param_value%TYPE;
        l_email               vmscms.cms_addr_mast.cam_email%TYPE;
        l_form_factor         vmscms.cms_appl_pan.cap_form_factor%TYPE;
        l_serial_proxy_encr   vmscms.vms_line_item_dtl.vli_proxy_pin_encr%TYPE;
        l_encr_key            vmscms.cms_bin_param.cbp_param_value%TYPE;
        l_virtual_email       vmscms.cms_addr_mast.cam_email%TYPE;
        l_payload_type_in     VARCHAR2(40) := 'RESEND EMAIL';
        l_tran_desc           vmscms.cms_transaction_mast.ctm_tran_desc%TYPE;
		l_audit_flag		  vmscms.cms_transaction_mast.ctm_txn_log_flag%TYPE;
        l_exp 				  EXCEPTION;
		l_nano_time	            NUMBER;
    BEGIN
        l_start_time := dbms_utility.get_time;
        l_partner_id := ( sys_context(fsfw.fsconst.c_fsapi_gpp_context,'x-incfs-partnerid') );
     --Check for mandatory fields
        CASE
            WHEN p_customer_id_in IS NULL THEN
                l_field_name := 'CUSTOMER ID';
                l_flag := 1;
            WHEN p_email_in IS NULL THEN
                l_field_name := 'EMAIL ID';
                l_flag := 1;
            ELSE
                NULL;
        END CASE;

        g_debug.display('l_partner_id' || l_partner_id);
        g_debug.display('p_customer_id_in' || p_customer_id_in);
    --Fetching the active PAN for the input customer id
    --Performance Fix
        BEGIN
            SELECT
                cap_pan_code,
                cap_pan_code_encr,
                cap_prod_code,
                cap_mbr_numb,
                cap_card_type,
                cap_acct_no,
                cap_card_stat,
                cap_serial_number,
                cap_proxy_number,
                cap_cust_code,
                NVL(cap_form_factor,'P')
            INTO
                l_hash_pan,
                l_encr_pan,
                l_prod_code,
                l_mbr_numb,
                l_card_type,
                l_acct_no,
                l_card_stat,
                l_serial_number,
                l_proxy_number,
                l_cust_code,
                l_form_factor
            FROM
                (
                    SELECT
                        cap_pan_code,
                        cap_pan_code_encr,
                        cap_prod_code,
                        cap_mbr_numb,
                        cap_card_type,
                        cap_acct_no,
                        cap_card_stat,
                        cap_serial_number,
                        cap_proxy_number,
                        cap_cust_code,
                        cap_form_factor
                    FROM
                        vmscms.cms_appl_pan
                    WHERE
                        cap_cust_code = (
                            SELECT
                                ccm_cust_code
                            FROM
                                vmscms.cms_cust_mast
                            WHERE
                                ccm_cust_id = to_number(p_customer_id_in)
                            --AND ccm_partner_id IN (l_partner_id)
                                AND ccm_prod_code || ccm_card_type = vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id
                               ,p_prod_code_in => ccm_prod_code,p_card_type_in => ccm_card_type)
                        )
                        AND cap_inst_code = 1
                        AND cap_active_date IS NOT NULL
                        AND cap_card_stat NOT IN (
                            '9'
                        )
                        AND cap_startercard_flag <> 'Y'
                    ORDER BY
                        cap_active_date DESC
                )
            WHERE
                ROWNUM < 2;

        EXCEPTION
            WHEN no_data_found THEN
                BEGIN
                    SELECT
                        cap_pan_code,
                        cap_pan_code_encr,
                        cap_prod_code,
                        cap_mbr_numb,
                        cap_card_type,
                        cap_acct_no,
                        cap_card_stat,
                        cap_serial_number,
                        cap_proxy_number,
                        cap_cust_code,
                        NVL(cap_form_factor,'P')
                    INTO
                        l_hash_pan,
                        l_encr_pan,
                        l_prod_code,
                        l_mbr_numb,
                        l_card_type,
                        l_acct_no,
                        l_card_stat,
                        l_serial_number,
                        l_proxy_number,
                        l_cust_code,
                        l_form_factor
                    FROM
                        (
                            SELECT
                                cap_pan_code,
                                cap_pan_code_encr,
                                cap_prod_code,
                                cap_mbr_numb,
                                cap_card_type,
                                cap_acct_no,
                                cap_card_stat,
                                cap_serial_number,
                                cap_proxy_number,
                                cap_cust_code,
                                cap_form_factor
                            FROM
                                vmscms.cms_appl_pan
                            WHERE
                                cap_cust_code = (
                                    SELECT
                                        ccm_cust_code
                                    FROM
                                        vmscms.cms_cust_mast
                                    WHERE
                                        ccm_cust_id = to_number(p_customer_id_in)
                                --AND ccm_partner_id IN (l_partner_id)
                                        AND ccm_prod_code || ccm_card_type = vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in
                                        => l_partner_id,p_prod_code_in => ccm_prod_code,p_card_type_in => ccm_card_type)
                                )
                                AND cap_inst_code = 1
                                AND cap_startercard_flag <> 'Y'
                            ORDER BY
                                cap_pangen_date DESC
                        )
                    WHERE
                        ROWNUM < 2;

                EXCEPTION
                    WHEN no_data_found THEN
                        BEGIN
                            SELECT
                                cap_pan_code,
                                cap_pan_code_encr,
                                cap_prod_code,
                                cap_mbr_numb,
                                cap_card_type,
                                cap_acct_no,
                                cap_card_stat,
                                cap_serial_number,
                                cap_proxy_number,
                                cap_cust_code,
                                NVL(cap_form_factor,'P')
                            INTO
                                l_hash_pan,
                                l_encr_pan,
                                l_prod_code,
                                l_mbr_numb,
                                l_card_type,
                                l_acct_no,
                                l_card_stat,
                                l_serial_number,
                                l_proxy_number,
                                l_cust_code,
                                l_form_factor
                            FROM
                                (
                                    SELECT
                                        cap_pan_code,
                                        cap_pan_code_encr,
                                        cap_prod_code,
                                        cap_mbr_numb,
                                        cap_card_type,
                                        cap_acct_no,
                                        cap_card_stat,
                                        cap_serial_number,
                                        cap_proxy_number,
                                        cap_cust_code,
                                        cap_form_factor
                                    FROM
                                        vmscms.cms_appl_pan
                                    WHERE
                                        cap_cust_code = (
                                            SELECT
                                                ccm_cust_code
                                            FROM
                                                vmscms.cms_cust_mast
                                            WHERE
                                                ccm_cust_id = to_number(p_customer_id_in)
                                    --AND ccm_partner_id IN (l_partner_id)
                                                AND ccm_prod_code || ccm_card_type = vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in
                                                => l_partner_id,p_prod_code_in => ccm_prod_code,p_card_type_in => ccm_card_type)
                                        )
                                        AND cap_inst_code = 1
                                        AND cap_active_date IS NOT NULL
                                        AND cap_card_stat NOT IN (
                                            '9'
                                        )
                                    ORDER BY
                                        cap_active_date DESC
                                )
                            WHERE
                                ROWNUM < 2;

                        EXCEPTION
                            WHEN no_data_found THEN
                                BEGIN
                                    SELECT
                                        cap_pan_code,
                                        cap_pan_code_encr,
                                        cap_prod_code,
                                        cap_mbr_numb,
                                        cap_card_type,
                                        cap_acct_no,
                                        cap_card_stat,
                                        cap_serial_number,
                                        cap_proxy_number,
                                        cap_cust_code,
                                        NVL(cap_form_factor,'P')
                                    INTO
                                        l_hash_pan,
                                        l_encr_pan,
                                        l_prod_code,
                                        l_mbr_numb,
                                        l_card_type,
                                        l_acct_no,
                                        l_card_stat,
                                        l_serial_number,
                                        l_proxy_number,
                                        l_cust_code,
                                        l_form_factor
                                    FROM
                                        (
                                            SELECT
                                                cap_pan_code,
                                                cap_pan_code_encr,
                                                cap_prod_code,
                                                cap_mbr_numb,
                                                cap_card_type,
                                                cap_acct_no,
                                                cap_card_stat,
                                                cap_serial_number,
                                                cap_proxy_number,
                                                cap_cust_code,
                                                cap_form_factor
                                            FROM
                                                vmscms.cms_appl_pan
                                            WHERE
                                                cap_cust_code = (
                                                    SELECT
                                                        ccm_cust_code
                                                    FROM
                                                        vmscms.cms_cust_mast
                                                    WHERE
                                                        ccm_cust_id = to_number(p_customer_id_in)
                                        --AND ccm_partner_id IN (l_partner_id)
                                                        AND ccm_prod_code || ccm_card_type = vmscms.gpp_utils.get_prod_code_card_type
                                                        (p_partner_id_in => l_partner_id,p_prod_code_in => ccm_prod_code,p_card_type_in
                                                        => ccm_card_type)
                                                )
                                                AND cap_inst_code = 1
                          --  AND cap_startercard_flag <> 'Y'
                                            ORDER BY
                                                cap_pangen_date DESC
                                        )
                                    WHERE
                                        ROWNUM < 2;

                                EXCEPTION
                                    WHEN no_data_found THEN
                                        l_errmsg:= 'No Cards/ Check Partner Id Found for the Cusotmer';
                                        g_debug.display('no data----' || l_hash_pan);
                                        l_hash_pan := NULL;
                                        l_encr_pan := NULL;
                                END;
                        END;
                END;
        END;

		SELECT
                    ctm_tran_desc,nvl(ctm_txn_log_flag,'T')
                INTO l_tran_desc,l_audit_flag
                FROM
                    vmscms.cms_transaction_mast
                WHERE
                    ctm_inst_code = 1
                    AND ctm_tran_code = l_txn_code
                    AND ctm_delivery_channel = '03';


        g_debug.display('l_hash_pan' || l_hash_pan);

	IF l_form_factor <> 'V'					--- Added for VMS-4927
	THEN
            p_status_out := vmscms.gpp_const.c_failure_res_id;

            p_err_msg_out := 'Only Virtual Cards are allowed to Resend Email';

                vmscms.gpp_cards.log_transactionlog (l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
												   l_txn_code,
                                                   'F',
                                                   'Only Virtual Cards are allowed to Resend Email',
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   p_comment_in,
                                                   l_timetaken,
												   l_audit_flag);
            RETURN;
        END IF;

        IF l_flag = 1 THEN
            p_status_out := vmscms.gpp_const.c_mandatory_status;

            p_err_msg_out := l_field_name || ' is mandatory';

                vmscms.gpp_cards.log_transactionlog (l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
												   l_txn_code,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   p_comment_in,
                                                   l_timetaken,
												   l_audit_flag);
            RETURN;
        END IF;


            SELECT
                cam_acct_bal,
                cam_ledger_bal
            INTO
                l_acct_balance,
                l_ledger_balance
            FROM
                vmscms.cms_acct_mast
            WHERE
                cam_acct_no = l_acct_no
                AND cam_inst_code = 1;

    --getting the date

        l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,'x-incfs-date'),6,11);
    -- l_date := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11); --for testing

        l_date := TO_CHAR(TO_DATE(l_date,'dd-mm-yyyy'),'yyyymmdd');
    --getting the time
        l_time := substr( (sys_context(fsfw.fsconst.c_fsapi_gpp_context,'x-incfs-date') ),18,8);
    --l_time := '08:49:37';

        l_time := replace(l_time,':','');

        l_session_id := ( sys_context(fsfw.fsconst.c_fsapi_gpp_context,'x-incfs-sessionid') );
        l_rrn := ( sys_context(fsfw.fsconst.c_fsapi_gpp_context,'x-incfs-correlationid') );

        g_debug.display('l_rrn' || l_rrn);
        IF l_encrypt_enable = 'Y' THEN
            l_virtual_email := vmscms.fn_emaps_main(p_email_in);
        ELSE
            l_virtual_email := p_email_in;
        END IF;



        SELECT
            cip_param_value
        INTO l_encr_key
        FROM
            vmscms.cms_inst_param
        WHERE
            cip_inst_code = 1
            AND cip_param_key = 'FSAPIKEY';

        l_serial_proxy_encr := vmscms.fn_emaps_main_b2b('serialNumber='
                                                          || l_serial_number
                                                          || '&'
                                                          || 'PIN='
                                                          || l_proxy_number,l_encr_key);

        BEGIN
            BEGIN
          --Below query is required to validate session against a card number
                SELECT
                    nvl(MAX(ccd_call_seq),0) + 1
                INTO l_call_seq
                FROM
                    vmscms.cms_calllog_details
                WHERE
                    ccd_inst_code = 1
                    AND ccd_call_id = ( sys_context(fsfw.fsconst.c_fsapi_gpp_context,'x-incfs-sessionid') )
                    AND ccd_pan_code = l_hash_pan;

            END;

            INSERT INTO vmscms.cms_calllog_details (
                ccd_inst_code,
                ccd_call_id,
                ccd_pan_code,
                ccd_call_seq,
                ccd_rrn,
                ccd_devl_chnl,
                ccd_txn_code,
                ccd_tran_date,
                ccd_tran_time,
                ccd_comments,
                ccd_ins_user,
                ccd_fsapi_username,
                ccd_acct_no,
                ccd_ins_date
            ) VALUES (
                1,
                ( sys_context(fsfw.fsconst.c_fsapi_gpp_context,'x-incfs-sessionid') ),
                l_hash_pan,
                l_call_seq,
                l_rrn,
                '03',
                l_txn_code,
                l_date,
                l_time,
                p_comment_in,
                NULL,
                sys_context(fsfw.fsconst.c_fsapi_gpp_context,'x-incfs-username'),
                l_acct_no,
                SYSDATE
            );

        END;


---      g_debug.display('Sending Push notfication request');


 			---Modified for VMS-4559 - Replacement Push Notification (Physical via CCA)-B2B Spec Consolidation.

        SELECT
            ccs_stat_desc
        INTO l_card_status
        FROM
            vmscms.cms_card_stat
        WHERE
            ccs_stat_code = l_card_stat;

        vmscms.pkg_event_push_notification.check_push_notification_config(1,l_prod_code,l_card_type,'03',l_txn_code,
							l_partner_name,l_event_msg_type,l_push_config,l_errmsg);

        IF l_errmsg = 'OK' THEN
            IF l_push_config = 'Y' THEN

                 vmscms.pkg_event_push_notification.form_push_notification_payload(p_customer_id_in,p_email_in,l_acct_balance,l_ledger_balance,SYSDATE,l_tran_desc,
					'Completed',l_proxy_number,l_serial_number,CASE WHEN l_form_factor = 'V' THEN l_serial_proxy_encr ELSE NULL END,
					l_card_status,NULL,NULL,NULL,l_payload_type_in, substr(VMSCMS.FN_DMAPS_MAIN(l_encr_pan), length(VMSCMS.FN_DMAPS_MAIN(l_encr_pan)) - 3), l_payload,l_errmsg);

                IF l_errmsg = 'OK' THEN
                    SELECT
                        cip_param_value
                    INTO l_queue_name
                    FROM
                        vmscms.cms_inst_param
                    WHERE
                        cip_inst_code = 1
                        AND cip_param_key = 'EVENT_PROCESS_QueueName';

					SELECT EXTRACT(DAY FROM TIME) * 24 * 60 * 60 * 1E9 + EXTRACT(HOUR FROM TIME) * 60 * 60 * 1E9 + EXTRACT(MINUTE FROM TIME)
                            * 60 * 1E9 + EXTRACT(SECOND FROM TIME) * 1E9 AS NANOTIME
                            INTO l_nano_time
                        FROM
                        (
                            SELECT
                                SYSTIMESTAMP(9) - TIMESTAMP '1970-01-01 00:00:00 UTC' AS TIME
                            FROM
                                DUAL
                        );

                     vmscms.pkg_event_push_notification.insert_event_processing(l_rrn|| '_'|| SUBSTR(l_nano_time, 1, 16),l_payload,l_partner_name,
                                                                               l_event_msg_type,l_queue_name,'PENDING',
									       l_errmsg );

                    IF l_errmsg <> 'OK' THEN
                        l_errmsg := 'Error while Inserting into Event Processing Table-' || l_errmsg;
                        RAISE l_exp;
                    END IF;

                                UPDATE vmscms.cms_addr_mast
                                                SET
                                                    cam_email = l_virtual_email,
                                                    cam_email_encr = vmscms.fn_emaps_main(p_email_in)
                                                WHERE
                                                    cam_cust_code = l_cust_code
                                                    AND cam_inst_code = 1;

                ELSE
                    l_errmsg := 'Error while forming payload-' || l_errmsg;
                    RAISE l_exp;
                END IF;             --- Payload form End.

             ELSE
                    l_errmsg := 'Product/Txn is not configured to resend email.  ';
                    RAISE l_exp;

            END IF;                     --- Push config end.
        ELSE
            l_errmsg := 'Error while checking Event Notification config-' || l_errmsg;
            RAISE l_exp;
        END IF;

    --time taken

        l_end_time := dbms_utility.get_time;
        g_debug.display('l_end_time' || l_end_time);
        l_timetaken := ( l_end_time - l_start_time );
        g_debug.display('Elapsed Time: '
                          || l_timetaken
                          || ' milisecs');
        g_debug.display('Elapsed Time: '
                          || (l_end_time - l_start_time) / 1000
                          || ' secs');

        p_status_out := vmscms.gpp_const.c_success_status;
        p_err_msg_out := 'SUCCESS';
                    vmscms.gpp_cards.log_transactionlog(l_api_name,
                                                           p_customer_id_in,
                                                           l_hash_pan,
                                                           l_encr_pan,
														   l_txn_code,
                                                           'C',
                                                           p_err_msg_out,
                                                           vmscms.gpp_const.c_success_res_id,
                                                           p_comment_in,
                                                           l_timetaken,
														   l_audit_flag);

    EXCEPTION             ---- << MAIN EXCEPTION >>>
        WHEN no_data_found THEN
            p_status_out := vmscms.gpp_const.c_ora_error_status;
            g_err_nodata.RAISE(l_api_name,vmscms.gpp_const.c_ora_error_status);
            p_err_msg_out := g_err_nodata.get_current_error;
                vmscms.gpp_cards.log_transactionlog(l_api_name,
                                                           p_customer_id_in,
                                                           l_hash_pan,
                                                           l_encr_pan,
														   l_txn_code,
                                                           'F',
                                                           l_errmsg,
                                                           vmscms.gpp_const.c_failure_res_id,
                                                           p_comment_in,
                                                           l_timetaken,
														   l_audit_flag);

        WHEN l_exp THEN                                          --- Modified  for VMS-4927
        p_status_out := vmscms.gpp_const.c_failure_res_id;
            g_debug.display('Exception during creating transaction log: ' || SQLCODE || ' -ERROR- ' || SQLERRM);
        p_err_msg_out := SUBSTR(l_errmsg,1,500);
                vmscms.gpp_cards.log_transactionlog(l_api_name,
                                                           p_customer_id_in,
                                                           l_hash_pan,
                                                           l_encr_pan,
														   l_txn_code,
                                                           'F',
                                                           l_errmsg,
                                                           vmscms.gpp_const.c_failure_res_id,
                                                           p_comment_in,
                                                           l_timetaken,
														   l_audit_flag);


        WHEN OTHERS THEN
            p_status_out := vmscms.gpp_const.c_rpl_card_status;
            g_err_unknown.RAISE(l_api_name || ' FAILED',vmscms.gpp_const.c_rpl_card_status);
            p_err_msg_out := g_err_unknown.get_current_error;
                            vmscms.gpp_cards.log_transactionlog(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
												   l_txn_code,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   p_comment_in,
                                                   l_timetaken,
												   l_audit_flag);
    END resend_email;




BEGIN
  -- Initialization
  init;
END gpp_cards;
/