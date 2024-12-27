SET DEFINE OFF;
create or replace PACKAGE BODY    vmscms.GPP_PROFILE IS

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
  g_err_nodata       fsfw.fserror_t;
  g_err_failure      fsfw.fserror_t;
  g_err_unknown      fsfw.fserror_t;
  g_err_mandatory    fsfw.fserror_t;
  g_err_invalid_data fsfw.fserror_t;

  -- Function and procedure implementations

  -- the init procedure is private and should ALWAYS exist
  --reset online password
  PROCEDURE unlock_account(p_customer_id_in IN VARCHAR2,
                           p_comment_in     IN VARCHAR2,
                           p_status_out     OUT VARCHAR2,
                           p_err_msg_out    OUT VARCHAR2) AS
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_field_name VARCHAR2(20);
    l_api_name   VARCHAR2(20) := 'UNLOCK ACCOUNT';
    l_customer   vmscms.cms_cust_mast.ccm_cust_id%TYPE;
    l_rrn        vmscms.transactionlog.rrn%TYPE;
    l_call_seq   NUMBER(3);
    l_date       VARCHAR2(50);
    l_time       VARCHAR2(50);
    l_acct_no    vmscms.cms_appl_pan.cap_acct_no%TYPE;
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
    g_debug.display('UNLOCK ACCOUNT');

    g_debug.display('p_customer_id_in' || p_customer_id_in);
    --Fetching the active PAN for the input customer id
    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_acct_no);
    g_debug.display('l_hash_pan' || l_hash_pan);
    g_debug.display('l_acct_no' || l_acct_no);

    UPDATE vmscms.cms_cust_mast
       SET ccm_acctlock_flag   = 'N',
           ccm_wrong_logincnt  = '0',
           ccm_last_logindate  = '',
           ccm_acctunlock_date = SYSDATE
     WHERE ccm_cust_id = p_customer_id_in;

    --Populating the values to be inserted cms_calllog_details
    SELECT nvl(MAX(ccd_call_seq),
               0) + 1
      INTO l_call_seq
      FROM vmscms.cms_calllog_details
     WHERE ccd_inst_code = ccd_inst_code
       AND ccd_call_id = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-sessionid'))
       AND ccd_pan_code = l_hash_pan;
    --rrn
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||    --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);
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
    g_debug.display('l_acct_no' || l_acct_no);

    INSERT INTO vmscms.cms_calllog_details
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
       ccd_ins_date,
       ccd_lupd_user,
       ccd_lupd_date,
       ccd_acct_no,
       ccd_fsapi_username)
    VALUES
      (1,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-sessionid')),
       l_hash_pan,
       l_call_seq,
       l_rrn,
       '03',
       NULL,
       l_date,
       l_time,
       p_comment_in,
       NULL,
       SYSDATE,
       NULL,
       SYSDATE,
       l_acct_no,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-username')));
    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out  := vmscms.gpp_const.c_success_status;
    p_err_msg_out := 'SUCCESS';
   /* vmscms.gpp_transaction.audit_transaction_log(l_api_name,     ---Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 l_customer,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C',
                                                 p_err_msg_out,
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
      p_status_out := vmscms.gpp_const.c_unlock_account_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_unlock_account_status);
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

  END unlock_account;
  PROCEDURE update_profile(
                           --name
                           p_action_in            IN VARCHAR2,
                           p_customer_id_in       IN VARCHAR2,
                           p_firstname_in         IN VARCHAR2,
                           p_middlename_in        IN VARCHAR2,
                           p_lastname_in          IN VARCHAR2,
                           p_mothermaiden_name_in IN VARCHAR2,
                           p_dateofbirth_in       IN VARCHAR2,
                           --identification
                           p_id_type_in         IN VARCHAR2,
                           p_number_in          IN VARCHAR2,
                           p_issuedby_in        IN VARCHAR2,
                           p_issuance_date_in   IN VARCHAR2,
                           p_expiration_date_in IN VARCHAR2,
                           --phone
                           p_landline_in IN VARCHAR2,
                           p_mobile_in   IN VARCHAR2,
                           p_email_in    IN VARCHAR2,
                           --address
                           p_physical_address_in IN VARCHAR2,
                           p_mailing_address_in  IN VARCHAR2,
                           --common
                           p_reason_in   IN VARCHAR2,
                           p_comment_in  IN VARCHAR2,
                           p_status_out  OUT VARCHAR2,
                           p_err_msg_out OUT VARCHAR2,
                           p_optinflag_out OUT VARCHAR2) AS
 /***************************************************************************************
         * Modified By        : Ubaidur Rahman H
         * Modified Date      : 26-Jun-2019
         * Modified Reason    : VMS-1008 - Modified to select currency code from product category instead of Prod Mast.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 26-Jun-2019
         * Build Number       : R17_B0005
 ***************************************************************************************/                          
                           
    l_date           VARCHAR2(50);
    l_time           VARCHAR2(50);
    l_api_name       VARCHAR2(50) := 'UPDATE ACCOUNT';
    l_field_name     VARCHAR2(50);
    l_flag           PLS_INTEGER := 0;
    l_hash_pan       vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan       vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_acct_no        vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_plain_pan      VARCHAR2(20);
    l_curr_code      VARCHAR2(20);
    l_charset        VARCHAR2(50);
    l_seed           VARCHAR2(50);
    l_rrn            vmscms.transactionlog.rrn%TYPE;
    l_lenth          VARCHAR2(3);
    l_mobile         VARCHAR2(100);
    l_mobile_no      VARCHAR2(20);
    l_landline       VARCHAR2(100);
    l_landline_no    VARCHAR2(20);
    l_p_type         VARCHAR2(20);
    l_p_address1     vmscms.cms_addr_mast.cam_add_one%TYPE;
    l_p_address2     vmscms.cms_addr_mast.cam_add_two%TYPE;
    l_p_city         vmscms.cms_addr_mast.cam_city_name%TYPE;
    l_p_state        VARCHAR2(20);
    l_p_state_code   vmscms.cms_addr_mast.cam_state_code%TYPE;
    l_p_postal       vmscms.cms_addr_mast.cam_pin_code%TYPE;
    l_p_country_code vmscms.gen_cntry_mast.gcm_cntry_code%TYPE;
    l_p_country      VARCHAR2(20);
    l_m_type         VARCHAR2(20);
    l_m_address1     vmscms.cms_addr_mast.cam_add_one%TYPE;
    l_m_address2     vmscms.cms_addr_mast.cam_add_two%TYPE;
    l_m_city         vmscms.cms_addr_mast.cam_city_name%TYPE;
    l_m_state        VARCHAR2(20);
    l_m_state_code   vmscms.cms_addr_mast.cam_state_code%TYPE;
    l_m_postal       vmscms.cms_addr_mast.cam_pin_code%TYPE;
    l_m_country      VARCHAR2(20);
    l_m_country_code vmscms.gen_cntry_mast.gcm_cntry_code%TYPE;
    l_addrupd_flag   CHAR(1);
    l_len            NUMBER(10);
    l_occ1           PLS_INTEGER;
    l_occ2           PLS_INTEGER;
    l_occ3           PLS_INTEGER;
    l_occ4           PLS_INTEGER;
    l_occ5           PLS_INTEGER;
    l_occ6           PLS_INTEGER;
    l_start_time     NUMBER;
    l_end_time       NUMBER;
    l_timetaken      NUMBER;
    --031716
    l_hash_pan_avq vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_clr_pan_avq  VARCHAR2(20);
    l_avq_id       vmscms.cms_avq_status.cas_avqstat_id%TYPE;
    l_avq_flag     vmscms.cms_avq_status.cas_avq_flag%TYPE;
    l_txn_code     vmscms.transactionlog.txn_code%TYPE;
    l_appl_status  VARCHAR2(2) := '17';
    --031716
    --performance change
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;
    l_call_seq     vmscms.cms_calllog_details.ccd_call_seq%TYPE;
    l_curr_id_type vmscms.cms_cust_mast.ccm_id_type%TYPE;
  BEGIN
    l_start_time := dbms_utility.get_time;
    --Fetching the active PAN for the input customer id
    --      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
    --                                     l_hash_pan,
    --                                     l_encr_pan,
    --                                     l_acct_no);

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
    g_debug.display('l_acct_no' || l_acct_no);

    --fetching the rrn
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||   --Changes VMS-8279 ~ HH has been replaced as HH24
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
    --l_date := substr('Fri, 08 mar 2016 08:49:37 GMT', 6, 11);
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
    /*SELECT cbp_param_value
      INTO l_curr_code
      FROM vmscms.cms_prod_mast, vmscms.cms_bin_param
     WHERE cpm_inst_code = cbp_inst_code
       AND cpm_profile_code = cbp_profile_code
       AND cpm_prod_code = l_prod_code
       AND cpm_inst_code = 1
       AND cbp_param_name = 'Currency';*/
       
      -- Added for VMS-1008 : Currency code taken from product category instead of Prod Mast
      SELECT bin.CBP_PARAM_VALUE
      INTO l_curr_code
      FROM vmscms.CMS_BIN_PARAM bin,
        vmscms.CMS_PROD_CATTYPE prodcat
      WHERE bin.CBP_PROFILE_CODE = prodcat.CPC_PROFILE_CODE
      AND prodcat.CPC_PROD_CODE  = l_prod_code
      AND prodcat.CPC_CARD_TYPE  = l_card_type
      AND bin.CBP_INST_CODE      = 1
      AND prodcat.CPC_INST_CODE  = 1
      AND bin.CBP_PARAM_NAME     = 'Currency';

    --Parsing Mobile
    IF upper(p_action_in) = 'UPDATEPHONE'
    THEN
      l_occ1      := instr(p_mobile_in,
                           '~');
      l_mobile    := substr(p_mobile_in,
                            1,
                            l_occ1 - 1);
      l_occ2      := instr(p_mobile_in,
                           '~',
                           2);
      l_mobile_no := substr(p_mobile_in,
                            l_occ2 + 1);

      g_debug.display('l_mobile' || l_mobile);
      g_debug.display('l_occ1' || l_occ1);
      g_debug.display('l_occ2' || l_occ2);
      g_debug.display('l_mobile_no' || l_mobile_no);

      --Parsing Landline
      l_occ1        := instr(p_landline_in,
                             '~');
      l_landline    := substr(p_landline_in,
                              1,
                              l_occ1 - 1);
      l_occ2        := instr(p_landline_in,
                             '~',
                             2);
      l_landline_no := substr(p_landline_in,
                              l_occ2 + 1);

      g_debug.display('l_landline' || l_landline);
      g_debug.display('l_occ1' || l_occ1);
      g_debug.display('l_occ2' || l_occ2);
      g_debug.display('l_landline_no' || l_landline_no);

      /*IF (length(l_mobile_no) OR length(l_landline_no)) > 10*/
      IF length(l_landline_no) <> 10
         OR length(l_mobile_no) <> 10
      THEN

        p_status_out := vmscms.gpp_const.c_wrong_digits_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0027,',
                                 'WRONG NO OF DIGITS ENTERED');
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

    END IF;

    IF upper(p_action_in) = 'UPDATEADDRESS'
       AND p_physical_address_in IS NOT NULL

    THEN

      g_debug.display('p_action_in.......' || p_action_in);
      --Parsing physical address
      l_occ1   := instr(p_physical_address_in,
                        '~');
      l_p_type := substr(p_physical_address_in,
                         1,
                         l_occ1 - 1);
      g_debug.display('l_p_type' || l_p_type);

      l_occ2       := instr(p_physical_address_in,
                            '~',
                            1,
                            2);
      l_p_address1 := substr(p_physical_address_in,
                             l_occ1 + 1,
                             (l_occ2 - l_occ1) - 1);
      g_debug.display('l_p_address1' || l_p_address1);
      l_occ3       := instr(p_physical_address_in,
                            '~',
                            1,
                            3);
      l_p_address2 := substr(p_physical_address_in,
                             l_occ2 + 1,
                             (l_occ3 - l_occ2) - 1);
      g_debug.display('l_p_address2' || l_p_address2);
      l_occ4   := instr(p_physical_address_in,
                        '~',
                        1,
                        4);
      l_p_city := substr(p_physical_address_in,
                         l_occ3 + 1,
                         (l_occ4 - l_occ3) - 1);
      g_debug.display('l_p_city' || l_p_city);
      l_occ5    := instr(p_physical_address_in,
                         '~',
                         1,
                         5);
      l_p_state := substr(p_physical_address_in,
                          l_occ4 + 1,
                          (l_occ5 - l_occ4) - 1);
      g_debug.display('l_p_state' || l_p_state);
      l_occ6     := instr(p_physical_address_in,
                          '~',
                          1,
                          6);
      l_p_postal := substr(p_physical_address_in,
                           l_occ5 + 1,
                           (l_occ6 - l_occ5) - 1);
      g_debug.display('l_p_postal' || l_p_postal);
      l_p_country := substr(p_physical_address_in,
                            l_occ6 + 1);
      g_debug.display('l_p_country' || l_p_country);

      SELECT gsm_state_code
        INTO l_p_state_code
        FROM vmscms.gen_state_mast
       WHERE gsm_inst_code = 1
         AND upper(gsm_switch_state_code) = upper(l_p_state);
      g_debug.display('l_P_state_CODE' || l_p_state_code);

      SELECT gcm_cntry_code
        INTO l_p_country_code
        FROM vmscms.gen_cntry_mast
       WHERE gcm_inst_code = 1
         AND gcm_switch_cntry_code = substr(l_p_country,
                                1,
                                2);
      g_debug.display('l_p_country' || l_p_country);

    END IF;
    IF upper(p_action_in) IN
       ('UPDATEADDRESS',
        'UPDATEADDRESSOVERRIDEAVS')
       AND p_mailing_address_in IS NOT NULL
    THEN
      --Parsing mailing address
      l_occ1   := instr(p_mailing_address_in,
                        '~');
      l_m_type := substr(p_mailing_address_in,
                         1,
                         l_occ1 - 1);
      g_debug.display('l_m_type' || l_m_type);

      l_occ2       := instr(p_mailing_address_in,
                            '~',
                            1,
                            2);
      l_m_address1 := substr(p_mailing_address_in,
                             l_occ1 + 1,
                             (l_occ2 - l_occ1) - 1);
      g_debug.display('l_m_address1' || l_m_address1);
      l_occ3       := instr(p_mailing_address_in,
                            '~',
                            1,
                            3);
      l_m_address2 := substr(p_mailing_address_in,
                             l_occ2 + 1,
                             (l_occ3 - l_occ2) - 1);
      g_debug.display('l_m_address2' || l_m_address2);
      l_occ4   := instr(p_mailing_address_in,
                        '~',
                        1,
                        4);
      l_m_city := substr(p_mailing_address_in,
                         l_occ3 + 1,
                         (l_occ4 - l_occ3) - 1);
      g_debug.display('l_m_city' || l_m_city);
      l_occ5    := instr(p_mailing_address_in,
                         '~',
                         1,
                         5);
      l_m_state := substr(p_mailing_address_in,
                          l_occ4 + 1,
                          (l_occ5 - l_occ4) - 1);
      g_debug.display('l_m_state' || l_m_state);
      l_occ6     := instr(p_mailing_address_in,
                          '~',
                          1,
                          6);
      l_m_postal := substr(p_mailing_address_in,
                           l_occ5 + 1,
                           (l_occ6 - l_occ5) - 1);
      g_debug.display('l_m_postal' || l_m_postal);
      l_m_country := substr(p_mailing_address_in,
                            l_occ6 + 1);
      g_debug.display('l_m_country' || l_m_country);

      SELECT gsm_state_code
        INTO l_m_state_code
        FROM vmscms.gen_state_mast
       WHERE gsm_inst_code = 1
         AND upper(gsm_switch_state_code) = upper(l_m_state);
      g_debug.display('l_M_state_CODE' || l_m_state_code);

      SELECT gcm_cntry_code
        INTO l_m_country_code
        FROM vmscms.gen_cntry_mast
       WHERE gcm_inst_code = 1
         AND gcm_switch_cntry_code = substr(l_m_country,
                                1,
                                2);
      g_debug.display('l_m_country' || l_m_country);
    END IF;
    IF upper(p_action_in) = 'UPDATEIDENTIFICATION'
    THEN
      CASE
        WHEN p_id_type_in IS NULL THEN
          l_field_name := 'IDENTIFICATION TYPE';
          l_flag       := 1;
        WHEN p_number_in IS NULL THEN
          l_field_name := 'IDENTIFICATION NUMBER';
          l_flag       := 1;
        ELSE
          NULL;
      END CASE;

      IF upper(p_id_type_in) NOT IN ('DL',
                                     'PASS',
                                     'SSN',
                                     'SIN')
      THEN
        p_status_out := vmscms.gpp_const.c_invalid_data_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0029,',
                                 'INVALID DATA FOR ID TYPE');
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

      SELECT ccm_id_type
        INTO l_curr_id_type
        FROM cms_cust_mast
       WHERE ccm_cust_code = l_cust_code
         AND ccm_inst_code = 1;

      IF l_curr_id_type <> upper(p_id_type_in)
      THEN
        p_status_out  := vmscms.gpp_const.c_invalid_id_update;
        p_err_msg_out := vmscms.gpp_const.c_invalid_id_update_errmsg;
        g_err_nodata.raise(l_api_name,
                           vmscms.gpp_const.c_invalid_id_update);
        RETURN;
      END IF;

      IF upper(p_id_type_in) IN ('DL',
                                 'PASS')
         AND (p_issuedby_in IS NULL OR p_issuance_date_in IS NULL OR
              p_expiration_date_in IS NULL)
      THEN
        p_status_out := vmscms.gpp_const.c_invalid_data_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0029,',
                                 'For DL and PASS Issued by, Issuance Date and Expiration Date is Mandatory');
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

    END IF;

    IF upper(p_action_in) = 'UPDATEPHONE'
    THEN
      IF p_mobile_in IS NOT NULL
      THEN
        CASE
          WHEN l_mobile IS NULL THEN
            l_field_name := 'PHONE TYPE';
            l_flag       := 1;
          WHEN l_mobile_no IS NULL THEN
            l_field_name := 'PHONE NO';
            l_flag       := 1;
          ELSE
            NULL;
        END CASE;
      END IF;
      --Jira issue cfip:171 landline no is not mandatory
      /* IF p_landline_in IS NOT NULL
      THEN
         CASE
            WHEN l_landline IS NULL THEN
               l_field_name := 'PHONE TYPE';
               l_flag       := 1;
            WHEN l_landline_no IS NULL THEN
               l_field_name := 'LANDLINE NO';
               l_flag       := 1;
            ELSE
               NULL;
         END CASE;
      END IF;*/
      --Jira issue cfip:171 ends
    END IF;

    IF upper(p_action_in) = 'UPDATEADDRESS'
    THEN
      IF p_physical_address_in IS NULL
         AND p_mailing_address_in IS NULL
      THEN
        l_field_name := 'ONE OF THE ADDRESS TYPE';
        l_flag       := 1;
      END IF;
      IF p_physical_address_in IS NOT NULL
      THEN
        CASE
          WHEN l_p_type IS NULL THEN
            l_field_name := 'ADDRESS TYPE';
            l_flag       := 1;
          WHEN l_p_address1 IS NULL THEN
            l_field_name := 'ADDRESS ONE';
            l_flag       := 1;
            --jira issue 172 fix starts
        /*WHEN l_p_address2 IS NULL THEN


                                                                              l_field_name := 'ADDRESS TWO';


                                                                              l_flag       := 1;*/
        --jira issue 172 fix ends
          WHEN l_p_city IS NULL THEN
            l_field_name := 'PHYSICAL CITY';
            l_flag       := 1;
          WHEN l_p_state IS NULL THEN
            l_field_name := 'PHYSICAL STATE';
            l_flag       := 1;
          WHEN l_p_postal IS NULL THEN
            l_field_name := 'PHYSICAL ZIP';
            l_flag       := 1;
          WHEN l_p_country IS NULL THEN
            l_field_name := 'PHYSICAL COUNTRY';
            l_flag       := 1;
          ELSE
            NULL;
        END CASE;
      END IF;
      IF p_mailing_address_in IS NOT NULL
      THEN
        CASE
          WHEN l_m_type IS NULL THEN
            l_field_name := 'MAILING ADDRESS TYPE';
            l_flag       := 1;
          WHEN l_m_address1 IS NULL THEN
            l_field_name := 'ADDRESS ONE';
            l_flag       := 1;
            --jira issue 172 fix starts
        /*WHEN l_m_address2 IS NULL THEN


                                                                              l_field_name := 'MAILINGADDRESS TWO';


                                                                              l_flag       := 1;*/
        --jira issue 172 fix ends
          WHEN l_m_city IS NULL THEN
            l_field_name := 'MAILING CITY';
            l_flag       := 1;
          WHEN l_m_state IS NULL THEN
            l_field_name := 'MAILING STATE';
            l_flag       := 1;
          WHEN l_m_postal IS NULL THEN
            l_field_name := 'MAILING ZIP';
            l_flag       := 1;
          WHEN l_m_country IS NULL THEN
            l_field_name := 'MAILING COUNTRY';
            l_flag       := 1;
          ELSE
            NULL;
        END CASE;
      END IF;

    END IF;
    IF upper(p_action_in) = 'UPDATEADDRESSOVERRIDEAVS'
    THEN
      CASE
        WHEN l_m_type IS NULL THEN
          l_field_name := 'MAILING ADDRESS TYPE';
          l_flag       := 1;
        WHEN l_m_address1 IS NULL THEN
          l_field_name := 'ADDRESS ONE';
          l_flag       := 1;
        WHEN l_m_city IS NULL THEN
          l_field_name := 'MAILING CITY';
          l_flag       := 1;
        WHEN l_m_state IS NULL THEN
          l_field_name := 'MAILING STATE';
          l_flag       := 1;
        WHEN l_m_postal IS NULL THEN
          l_field_name := 'MAILING ZIP';
          l_flag       := 1;
        WHEN l_m_country IS NULL THEN
          l_field_name := 'MAILING COUNTRY';
          l_flag       := 1;
        ELSE
          NULL;
      END CASE;
    END IF;
    ---Jira fix for CFIP-132 starts
    IF upper(p_action_in) = 'UPDATENAME'
    THEN
      --
      -- Start JIRA: CFIP-251 (1)
      -- 5/13/2016
      -- Check for p_reason whenever First/Last Names are provided. If ONLY maiden name is passed, then p_reason_in is not required.
      IF p_firstname_in IS NOT NULL
         OR p_lastname_in IS NOT NULL
      THEN
        -- End JIRA: CFIP-251 (1)
        --
        CASE
          WHEN p_firstname_in IS NULL THEN
            l_field_name := 'FIRST NAME';
            l_flag       := 1;
          WHEN p_lastname_in IS NULL THEN
            l_field_name := 'LAST NAME';
            l_flag       := 1;
            --Jira issue fix for cfip:174 starts
        --
        -- Start JIRA: CFIP-251 (2)
        -- 5/16/2016
        -- DOB is required when the action is UPDATENAME.
          WHEN p_dateofbirth_in IS NULL THEN
            l_field_name := 'DOB';
            l_flag       := 1;
            -- End JIRA: CFIP-251 (2)
        --
          WHEN p_reason_in IS NULL THEN
            l_field_name := 'REASON';
            l_flag       := 1;
            --Jira issue fix for cfip:174 ends
          ELSE
            NULL;
        END CASE;
        --
        -- Start JIRA: CFIP-251 (5)
        -- 5/16/2016
        -- First and Last names are required when updating Middle Name
      ELSE
        IF p_middlename_in IS NOT NULL
        THEN
          l_field_name := 'FIRST/LAST NAME';
          l_flag       := 1;
          -- End JIRA: CFIP-251 (5)
          --
        END IF;

      END IF;
    END IF;
    ---Jira fix for CFIP-132 ends
    IF upper(p_action_in) = 'UPDATEEMAIL'
    THEN
      CASE
        WHEN p_email_in IS NULL THEN
          l_field_name := 'EMAIL';
          l_flag       := 1;
        ELSE
          NULL;
      END CASE;
    END IF;

    g_debug.display('p_action_in' || p_action_in);
    g_debug.display('l_flag' || l_flag);
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
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
      RETURN;
    END IF;
    --Jira issue fix for cfip:174 starts
    IF upper(p_action_in) = 'UPDATENAME'
       AND p_reason_in NOT IN ('101',
                               '102',
                               '103')
    THEN
      p_status_out := vmscms.gpp_const.c_invalid_reason_status;
      g_err_invalid_data.raise(l_api_name,
                               ',0030,',
                               'INVALID REASON ENTERED');
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
    --Jira issue fix for cfip:174 ends
    g_debug.display('dob' || to_char(to_date(p_dateofbirth_in,
                                             'YYYY-MM-DD'),
                                     'YYYYMMDD'));
    g_debug.display('sysdate' || to_char(SYSDATE,
                                         'YYYYMMDD'));
    IF upper(p_action_in) = 'UPDATENAME'
       AND
       to_char(to_date(p_dateofbirth_in,
                       'YYYY-MM-DD'),
               'YYYYMMDD') >= to_char(to_date(SYSDATE,
                                              'DD/MM/RRRR'),
                                      'YYYYMMDD')
    THEN

      p_status_out := vmscms.gpp_const.c_invalid_dob_status;
      g_err_invalid_data.raise(l_api_name,
                               ',0040,',
                               'DOB CANNOT BE FUTURE DATE');
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
    --Jira issue fix for cfip:204 ends
    --031716
    BEGIN

      SELECT vmscms.fn_dmaps_main(ccs_pan_code_encr), ccs_pan_code
        INTO l_clr_pan_avq, l_hash_pan_avq
        FROM vmscms.cms_cardissuance_status
       WHERE ccs_pan_code IN
             (SELECT cap_pan_code
                FROM cms_appl_pan
               WHERE cap_acct_no = l_acct_no)
         AND ccs_card_status = l_appl_status;

    EXCEPTION
      WHEN no_data_found THEN
        l_clr_pan_avq  := NULL;
        l_hash_pan_avq := NULL;

    END;

    --031716
    IF upper(p_action_in) = 'UPDATEADDRESSOVERRIDEAVS'
    THEN

      BEGIN
        SELECT cas_avqstat_id, cas_avq_flag
          INTO l_avq_id, l_avq_flag
          FROM (SELECT cas_avqstat_id, cas_avq_flag
                  FROM vmscms.cms_avq_status
                 WHERE cas_cust_id = p_customer_id_in
                   AND cas_pan_code = l_hash_pan_avq
                   AND cas_avq_flag IS NOT NULL
                 ORDER BY cas_avqstat_id DESC)
         WHERE rownum = 1;

      EXCEPTION
        WHEN no_data_found THEN

          p_status_out  := vmscms.gpp_const.c_invalid_override_avq_request;
          p_err_msg_out := vmscms.gpp_const.c_invalid_avq_override_errmsg;
          g_err_nodata.raise(l_api_name,
                             vmscms.gpp_const.c_invalid_override_avq_request);

          RETURN;
      END;

      BEGIN
        g_debug.display('Calling SP_CSR_MELISSA_ADDR_OVERRIDE');

        vmscms.sp_csr_melissa_addr_override(1,
                                            '0200',
                                            p_comment_in,
                                            l_clr_pan_avq,
                                            '000',
                                            l_rrn,
                                            NULL,
                                            '91',
                                            0,
                                            '03',
                                            l_date,
                                            l_time,
                                            l_curr_code,
                                            0,
                                            NULL,
                                            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                         'x-incfs-sessionid')),
                                            (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                         'x-incfs-ip')),
                                            l_avq_id,
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

    ELSE
      BEGIN
        g_debug.display('l_m_type before.....' || l_m_type);
        IF (upper(p_action_in) = 'UPDATEADDRESS' AND
           p_physical_address_in IS NULL)
           AND l_clr_pan_avq IS NOT NULL
        THEN
          l_txn_code  := '17';
          l_plain_pan := l_clr_pan_avq;
          g_debug.display('l_hash_pan_avq' || l_hash_pan_avq);
          g_debug.display('l_txn_code' || l_txn_code);
        ELSE
          l_txn_code := '37';
          g_debug.display('l_hash_pan_avq' || l_hash_pan_avq);
          g_debug.display('l_txn_code' || l_txn_code);
        END IF;

        g_debug.display('Calling Update Profile');
        vmscms.gpp_sp_upd_profileinfo(p_action_in,
                                      1, --prm_instcode
                                      '0200', --prm_msg_type
                                      p_comment_in, --prm_remark
                                      l_plain_pan, --prm_pan_code
                                      '000', --prm_mbrnumb
                                      l_acct_no, --prm_acct_no
                                      l_rrn, --prm_rrn
                                      NULL, --prm_stan
                                      -- (CASE upper(p_action_in) WHEN
                                      --  'UPDATEADDRESSOVERRIDEAVS' THEN '17' ELSE '37' END), --prm_txn_code --Jira issue CFIP:90
                                      l_txn_code, --031716
                                      0, --prm_txn_mode
                                      '03', --prm_delivery_channel
                                      l_date, --prm_trandate
                                      l_time, --prm_trantime
                                      l_curr_code, --prm_currcode
                                      p_lastname_in, --prm_lastname
                                      to_char(to_date(p_dateofbirth_in,
                                                      'YYYY-MM-DD'),
                                              'MM/DD/YYYY'), --prm_dob
                                      p_number_in, -- prm_ssn
                                      p_email_in, --prm_email
                                      l_mobile_no, --prm_mobile_no
                                      l_landline_no, --prm_alternate_phone
                                      l_p_address1, --prm_phy_addr1
                                      l_p_address2, --prm_phy_addr2
                                      l_p_city, --prm_phy_city
                                      l_p_state_code, --prm_phy_state
                                      l_p_postal, --prm_phy_zip
                                      l_p_country_code, --prm_phy_country
                                      l_m_address1, --prm_mailing_addr1
                                      l_m_address2, --prm_mailing_addr2
                                      l_m_city, --prm_mailing_city
                                      l_m_state_code, --prm_mailing_state
                                      l_m_postal, --prm_mailing_zip
                                      l_m_country_code, --prm_mailing_country
                                      0, --prm_rvsl_code
                                      NULL, --prm_ins_user
                                      --36386,
                                      (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                   'x-incfs-sessionid')), --prm_call_id
                                      l_addrupd_flag, --prm_addrupd_flag
                                      (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                   'x-incfs-ip')), --prm_ipaddress
                                      p_mothermaiden_name_in, --prm_maiden_name
                                      p_firstname_in, --prm_first_name
                                      p_middlename_in, -- prm_middle_name
                                      p_reason_in, --prm_reason_code
                                      p_id_type_in, --PRM_ID_TYPE
                                      p_issuedby_in,
                                      to_char(to_date(p_issuance_date_in,
                                                      'YYYY-MM-DD'),
                                              'MM/DD/YYYY'),
                                      to_char(to_date(p_expiration_date_in,
                                                      'YYYY-MM-DD'),
                                              'MM/DD/YYYY'),
                                      l_encr_pan,
                                      l_hash_pan,
                                      NULL, --PRM_AUTH_USER,
                                      (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-username')),  --prm_username
                                      p_status_out, --prm_resp_code
                                      p_err_msg_out, --prm_resp_msg
									                    p_optinflag_out
                                      );

        g_debug.display('p_status_out' || p_status_out);
        g_debug.display('p_err_msg_out' || p_err_msg_out);

      EXCEPTION
        WHEN OTHERS THEN
          p_status_out  := p_status_out;
          p_err_msg_out := p_err_msg_out;
          RETURN;
      END;

    END IF;
    --Jira Issue: CFIP:188 starts
    --updating the below fields manually
    --since the base procedure doesnot populate these fields in Transactionlog
    UPDATE vmscms.TRANSACTIONLOG
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

    --Jira Issue: CFIP:187 starts
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
      p_status_out  := vmscms.gpp_const.c_update_account_status;
      p_err_msg_out := substr(SQLERRM,
                              1,
                              100);
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_update_account_status);
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

  END update_profile;
  PROCEDURE unlock_accttoken_provisioning(p_customer_id_in IN VARCHAR2,
                                          p_comment_in     IN VARCHAR2,
                                          p_status_out     OUT VARCHAR2,
                                          p_err_msg_out    OUT VARCHAR2) IS
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_acct_no    vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_api_name   VARCHAR2(20) := 'UNLOCK TOKEN PROVISN';
    l_rrn        vmscms.transactionlog.rrn%TYPE;
    l_call_seq   NUMBER(3);
    l_date       VARCHAR2(50);
    l_time       VARCHAR2(50);
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
    g_debug.display('UNLOCK ACCOUNT FOR TOKEN PROVISIONING');

    --Fetching PAN details
    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_acct_no);

    g_debug.display('l_hash_pan' || l_hash_pan);
    g_debug.display('l_acct_no' || l_acct_no);

    UPDATE vmscms.cms_appl_pan
       SET cap_provisioning_flag = 'Y', cap_provisioning_attempt_count = 0
     WHERE cap_pan_code = l_hash_pan;

    SELECT nvl(MAX(ccd_call_seq),
               0) + 1
      INTO l_call_seq
      FROM vmscms.cms_calllog_details
     WHERE ccd_inst_code = ccd_inst_code
       AND ccd_call_id = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-sessionid'))
       AND ccd_pan_code = l_hash_pan;

    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||   --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);

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

    INSERT INTO vmscms.cms_calllog_details
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
       ccd_ins_date,
       ccd_lupd_user,
       ccd_lupd_date,
       ccd_acct_no,
       ccd_fsapi_username)
    VALUES
      (1,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-sessionid')),
       l_hash_pan,
       l_call_seq,
       l_rrn,
       '03',
       NULL,
       l_date,
       l_time,
       p_comment_in,
       NULL,
       SYSDATE,
       NULL,
       SYSDATE,
       l_acct_no,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-username')));
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
                                                 p_err_msg_out,
                                                 vmscms.gpp_const.c_success_res_id,
                                                 NULL,
                                                 l_timetaken);*/

  EXCEPTION
    WHEN OTHERS THEN
      p_status_out := vmscms.gpp_const.c_unlock_account_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_unlock_account_status);
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
  END unlock_accttoken_provisioning;

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
                                         '$1 $2 $3');
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
  END init;

  -- the get_cpp_context function returns the value of the specific
  -- context value set in the application context for the GPP application

  FUNCTION get_gpp_context(p_name_in IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                       p_name_in));
  END get_gpp_context;

  PROCEDURE enable_fraud_override(p_customer_id_in IN VARCHAR2,
                                  p_comment_in     IN VARCHAR2,
                                  p_status_out     OUT VARCHAR2,
                                  p_err_msg_out    OUT VARCHAR2) IS
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_acct_no    vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_api_name   VARCHAR2(100) := 'FRUAD_OVERRIDE';
    l_rrn        vmscms.transactionlog.rrn%TYPE;
    l_call_seq   NUMBER(3);
    l_date       VARCHAR2(50);
    l_time       VARCHAR2(50);
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
    g_debug.display('ENABLE FRUAD OVERRIDE');

    --Fetching PAN details
    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_acct_no);

    g_debug.display('l_hash_pan' || l_hash_pan);
    g_debug.display('l_acct_no' || l_acct_no);

    UPDATE vmscms.cms_appl_pan
       SET cap_rule_bypass = 'Y'
     WHERE cap_pan_code = l_hash_pan
       AND cap_mbr_numb = '000';

    SELECT nvl(MAX(ccd_call_seq),
               0) + 1
      INTO l_call_seq
      FROM vmscms.cms_calllog_details
     WHERE ccd_inst_code = ccd_inst_code
       AND ccd_call_id = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-sessionid'))
       AND ccd_pan_code = l_hash_pan;

    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||    --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);

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

    INSERT INTO vmscms.cms_calllog_details
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
       ccd_ins_date,
       ccd_lupd_user,
       ccd_lupd_date,
       ccd_acct_no,
       ccd_fsapi_username)
    VALUES
      (1,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-sessionid')),
       l_hash_pan,
       l_call_seq,
       l_rrn,
       '03',
       NULL,
       l_date,
       l_time,
       p_comment_in,
       NULL,
       SYSDATE,
       NULL,
       SYSDATE,
       l_acct_no,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-username')));
    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out  := vmscms.gpp_const.c_success_status;
    p_err_msg_out := 'SUCCESS';
   /* vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 p_customer_id_in,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C',
                                                 p_err_msg_out,
                                                 vmscms.gpp_const.c_success_res_id,
                                                 NULL,
                                                 l_timetaken);*/

  EXCEPTION
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
  END enable_fraud_override;

  PROCEDURE enable_fraud_override(p_customer_id_in IN VARCHAR2,
                                  p_comment_in     IN VARCHAR2,
                                  p_action_in      IN VARCHAR2,
                                  p_status_out     OUT VARCHAR2,
                                  p_err_msg_out    OUT VARCHAR2) IS
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_acct_no    vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_api_name   VARCHAR2(100) := 'FRAUD_OVERRIDE';
    l_rrn        vmscms.transactionlog.rrn%TYPE;
    l_call_seq   NUMBER(3);
    l_date       VARCHAR2(50);
    l_time       VARCHAR2(50);
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;

  /***************************************************************************************

	     * Modified By        : UBAIDUR RAHMAN H
         * Modified Date      : 07-Feb-2019
         * Modified Reason    : Modified to Permanent Fraud Override Support(VMS-511).
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 07-Feb-2019
         * Build Number       : R12_B0003
	 
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002

***************************************************************************************/

  BEGIN
    l_start_time := dbms_utility.get_time;
    g_debug.display('ENABLE FRAUD OVERRIDE');

   										 --Modified to Permanent Fraud Override Support(VMS-511).
    IF upper(p_action_in) NOT IN ('TOGGLEACCOUNTWITHONETIMEFRAUDOVERRIDE','TOGGLEACCOUNTWITHPERMANENTFRAUDOVERRIDE')
      THEN
        p_status_out := vmscms.gpp_const.c_invalid_data_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0029,',
                                 'INVALID DATA FOR ACTION');
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
    --Fetching PAN details

    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_acct_no);

    g_debug.display('l_hash_pan' || l_hash_pan);
    g_debug.display('l_acct_no' || l_acct_no);

    								--Modified to Permanent Fraud Override Support(VMS-511).
    UPDATE vmscms.cms_appl_pan
       SET cap_rule_bypass = CASE
                             WHEN (UPPER(p_action_in) = 'TOGGLEACCOUNTWITHONETIMEFRAUDOVERRIDE' AND nvl(cap_rule_bypass,'N')= 'Y')
                             OR   (UPPER(p_action_in) = 'TOGGLEACCOUNTWITHPERMANENTFRAUDOVERRIDE' AND nvl(cap_rule_bypass,'N')= 'P')
                             THEN 'N'
                             WHEN UPPER(p_action_in) = 'TOGGLEACCOUNTWITHONETIMEFRAUDOVERRIDE' AND nvl(cap_rule_bypass,'N') <> 'Y'
                             THEN 'Y'
                             WHEN UPPER(p_action_in) = 'TOGGLEACCOUNTWITHPERMANENTFRAUDOVERRIDE' AND nvl(cap_rule_bypass,'N') <> 'P'
                             THEN 'P' end,
     cap_provisioning_flag = CASE
                             WHEN (UPPER(p_action_in) = 'TOGGLEACCOUNTWITHONETIMEFRAUDOVERRIDE' AND nvl(cap_rule_bypass,'N') <> 'Y')
                             OR (UPPER(p_action_in) = 'TOGGLEACCOUNTWITHPERMANENTFRAUDOVERRIDE' AND nvl(cap_rule_bypass,'N') <> 'P')
                             THEN 'Y' ELSE cap_provisioning_flag END,
    cap_provisioning_attempt_count = CASE
                             WHEN (UPPER(p_action_in) = 'TOGGLEACCOUNTWITHONETIMEFRAUDOVERRIDE' AND nvl(cap_rule_bypass,'N') <> 'Y')
                              OR (UPPER(p_action_in) = 'TOGGLEACCOUNTWITHPERMANENTFRAUDOVERRIDE' AND nvl(cap_rule_bypass,'N') <> 'P')THEN
                             0 ELSE cap_provisioning_attempt_count END
     	WHERE cap_pan_code = l_hash_pan
          AND cap_mbr_numb = '000';


    SELECT nvl(MAX(ccd_call_seq),
               0) + 1
      INTO l_call_seq
      FROM vmscms.cms_calllog_details
     WHERE ccd_inst_code = ccd_inst_code
       AND ccd_call_id = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-sessionid'))
       AND ccd_pan_code = l_hash_pan;

    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||    --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('l_rrn' || l_rrn);

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

    INSERT INTO vmscms.cms_calllog_details
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
       ccd_ins_date,
       ccd_lupd_user,
       ccd_lupd_date,
       ccd_acct_no,
       ccd_fsapi_username)
    VALUES
      (1,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-sessionid')),
       l_hash_pan,
       l_call_seq,
       l_rrn,
       '03',
       NULL,
       l_date,
       l_time,
       p_comment_in,
       NULL,
       SYSDATE,
       NULL,
       SYSDATE,
       l_acct_no,
       (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                    'x-incfs-username')));
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
                                                 p_err_msg_out,
                                                 vmscms.gpp_const.c_success_res_id,
                                                 NULL,
                                                 l_timetaken);*/

  EXCEPTION
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
  END enable_fraud_override;

  PROCEDURE  get_customer_alerttypes(p_customer_id_in       IN  VARCHAR2,
                                     p_status_out           OUT VARCHAR2,
                                     p_err_msg_out          OUT VARCHAR2,
                                     p_alert_type_out       OUT VARCHAR2)
  AS
    l_field_name              VARCHAR2(50);
    l_api_name                VARCHAR2(30) := 'GET_CUSTOMER_ALERTTYPES';
    l_hash_pan                vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan                vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_partner_id              vmscms.transactionlog.partner_id%TYPE;
    l_start_time              PLS_INTEGER;
    l_end_time                PLS_INTEGER;
    l_timetaken               PLS_INTEGER;
    l_cust_code               vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code               vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type               vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no                vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no                 vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat                vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan              vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code            vmscms.cms_appl_pan.cap_prfl_code%TYPE;
    l_alert_lang_id           vmscms.cms_smsandemail_alert.csa_alert_lang_id%TYPE;
    l_value                   VARCHAR2(100);
    e_reject_record           EXCEPTION;
/***************************************************************************************
	       * Modified By        : Vini Pushkaran
         * Modified Date      : 13-Feb-2019
         * Modified Reason    : VMS-721
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 13-Feb-2019
         * Build Number       : R12_B0005
	 

	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002
	 
***************************************************************************************/
BEGIN
    p_err_msg_out := 'OK';
    l_start_time := dbms_utility.get_time;

    --Getting partner id
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));

    --Getting card details
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

        g_debug.display('l_cust_code' || l_cust_code);

        IF l_cust_code IS NULL
        THEN
           p_err_msg_out := 'Given Customer id is Invalid';
           RAISE e_reject_record;
        END IF;

      --Getting default language id for card
        BEGIN

          SELECT csa_alert_lang_id
          INTO l_alert_lang_id
          FROM vmscms.cms_smsandemail_alert
          WHERE csa_pan_code= l_hash_pan ;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_alert_lang_id := NULL;
        WHEN OTHERS THEN
          p_err_msg_out  := 'Error while Selecting Alert Details of Card'||SUBSTR(SQLERRM, 1, 200);
          RAISE e_reject_record;
        END;

          --Getting default language id for product category
        IF l_alert_lang_id IS NULL
        THEN
            BEGIN

              SELECT cps_alert_lang_id
              INTO l_alert_lang_id
              FROM vmscms.cms_prodcatg_smsemail_alerts
              WHERE cps_inst_code = 1
              AND cps_prod_code = l_prod_code
              AND cps_card_type = l_card_type
              AND cps_defalert_lang_flag = 'Y'
              AND ROWNUM = 1;

            EXCEPTION
            WHEN OTHERS THEN
              p_err_msg_out  := 'Error while Selecting Alert Details of Card'||SUBSTR(SQLERRM, 1, 200);
              RAISE e_reject_record;
          END;
        END IF;

     --Getting alert details which are opted in by customer
      FOR i IN (SELECT *
                FROM vmscms.CMS_SMSEMAIL_ALERT_DET,
                     vmscms.CMS_PRODCATG_SMSEMAIL_ALERTS
                WHERE cps_inst_code                             = 1
                AND NVL(dbms_lob.substr( cps_alert_msg,1,1),0) != 0
                AND cps_alert_id                                = cad_alert_id
                AND cps_prod_code                               = l_prod_code
                AND cps_card_type                               = l_card_type
                AND cps_alert_lang_id                           = l_alert_lang_id )
      LOOP
          BEGIN

            EXECUTE IMMEDIATE 'SELECT '|| i.CAD_COLUMN_NAME ||' FROM VMSCMS.CMS_SMSANDEMAIL_ALERT WHERE CSA_PAN_CODE= :l_hash_pan'
            INTO l_value USING l_hash_pan ;

          IF l_value <> 0
          THEN

            p_alert_type_out := p_alert_type_out || i.cad_alert_name ||'|';

          END IF;
         EXCEPTION
         WHEN OTHERS THEN
           p_err_msg_out:= 'Error in Alerts array'||SUBSTR(SQLERRM, 1, 200);
           RAISE e_reject_record;
         END;
     END LOOP;

     p_alert_type_out := rtrim(nvl(p_alert_type_out,'No Data Found'),'|');

     --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out  := vmscms.gpp_const.c_success_status;
    p_err_msg_out := 'SUCCESS';
    --Logging success record details
   /* vmscms.gpp_transaction.audit_transaction_log(l_api_name,     ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 p_customer_id_in,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C',
                                                 p_err_msg_out,
                                                 vmscms.gpp_const.c_success_res_id,
                                                 NULL,
                                                 l_timetaken);*/

  EXCEPTION
    WHEN e_reject_record THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := p_err_msg_out;
       --Logging failure record details
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
         --Logging failure record details
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
         --Logging failure record details
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
  END get_customer_alerttypes;

 PROCEDURE get_customer_alertlog(p_customer_id_in       IN  VARCHAR2,
                                 p_start_date_in        IN  VARCHAR2,
                                 p_end_date_in          IN  VARCHAR2,
                                 p_alert_mode_in        IN  VARCHAR2,
                                 p_alert_type_in        IN  VARCHAR2,
                                 p_recordsperpage_in    IN  VARCHAR2,
                                 p_pagenumber_in        IN  VARCHAR2,
                                 p_status_out           OUT VARCHAR2,
                                 p_err_msg_out          OUT VARCHAR2,
                                 c_alert_log_out        OUT SYS_REFCURSOR)
  AS
    l_field_name        VARCHAR2(50);
    l_api_name          VARCHAR2(30) := 'GET_CUSTOMER_ALERTLOG';
    l_flag              PLS_INTEGER := 0;
    l_hash_pan          vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan          vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_partner_id        vmscms.transactionlog.partner_id%TYPE;
    l_date              vmscms.transactionlog.business_date%TYPE;
    l_time              vmscms.transactionlog.business_time%TYPE;
    l_start_time        PLS_INTEGER;
    l_end_time          PLS_INTEGER;
    l_timetaken         PLS_INTEGER;
    l_recordsperpage    PLS_INTEGER;
    l_pagenumber        PLS_INTEGER;
    l_rec_start_no      PLS_INTEGER;
    l_rec_end_no        PLS_INTEGER;
    l_start_date        DATE;
    l_end_date          DATE;
    l_cust_code         vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code         vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type         vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no          vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no           vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat          vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan        vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code      vmscms.cms_appl_pan.cap_prfl_code%TYPE;
    l_alert_value       vmscms.cms_smsandemail_log.csl_alert_type%TYPE;
    l_alert_mode        PLS_INTEGER;
    l_count             PLS_INTEGER;
    l_alert_type        vmscms.cms_smsemail_alert_det.cad_alert_name%TYPE;
    e_reject_record     EXCEPTION;
/***************************************************************************************
	       * Modified By        : Vini Pushkaran
         * Modified Date      : 13-Feb-2019
         * Modified Reason    : VMS-721
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 13-Feb-2019
         * Build Number       : R12_B0005
	 
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002
	
        * Modified By        : John G
         * Modified Date      : 1-Aug-2024
         * Modified Reason    : VMS-8942 - Display Alert Log Details on CCA
         * Reviewer           : 
         * Reviewed Date      : 
         * Build Number       : R101_B0002

***************************************************************************************/
BEGIN
    p_err_msg_out := 'OK';
    l_alert_type :=upper(p_alert_type_in);
    l_start_time := dbms_utility.get_time;
    --Getting partner id
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --Validating start date and end date
    IF p_start_date_in IS NULL
    THEN
      IF p_end_date_in IS NULL
      THEN
        l_end_date := SYSDATE;
      ELSE
        l_end_date := to_date(p_end_date_in,
                              'YYYY-MM-DD HH24:MI:SS');
      END IF;
        l_start_date := trunc(l_end_date - 30);

    ELSIF p_start_date_in IS NOT NULL
    THEN
        l_start_date := to_date(p_start_date_in ,
                              'YYYY-MM-DD HH24:MI:SS');
      IF p_end_date_in IS NULL
      THEN
        l_end_date := to_date(to_char((l_start_date + 30), 'YYYY-MM-DD') ||
                              ' 23:59:59',
                              'YYYY-MM-DD HH24:MI:SS');
      ELSE
        l_end_date := to_date(p_end_date_in ,
                              'YYYY-MM-DD HH24:MI:SS');
      END IF;
    END IF;

--Getting card details
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

      g_debug.display('l_cust_code' || l_cust_code);

      IF l_cust_code IS NULL
      THEN
           p_err_msg_out := 'Given Customer id is Invalid';
           RAISE e_reject_record;
      END IF;

      --Validating alert mode
	    IF  p_alert_mode_in IS NOT NULL
      AND upper(p_alert_mode_in) NOT IN ('ALL',
                                         'SMS',
                                         'EMAIL')
      THEN
		  p_status_out := vmscms.gpp_const.c_inv_txn_acc_status;
		  g_err_invalid_data.raise(l_api_name,
								   '0029',
								   'INVALID ALERT MODE');
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

    l_alert_mode := CASE
                    WHEN upper(p_alert_mode_in) = 'SMS'
                    THEN
                       '1'
                    WHEN upper(p_alert_mode_in) = 'EMAIL'
                    THEN
                       '2'
                    END;

      --Valildaing alert type
      IF l_alert_type IS NOT NULL AND l_alert_type <> 'ALL'
      THEN

        BEGIN
            SELECT COUNT(1)
            INTO l_count
            FROM vmscms.CMS_SMSEMAIL_ALERT_DET
            WHERE cad_alert_name =l_alert_type;
        EXCEPTION
        WHEN OTHERS THEN
            p_err_msg_out  := 'Error while Selecting Alert Type Count'||SUBSTR(SQLERRM, 1, 200);
            RAISE e_reject_record;
        END;

        IF l_count = 0
        THEN
        p_status_out := vmscms.gpp_const.c_invalid_sort_status;
        g_err_invalid_data.raise(l_api_name,
                                 ',0012,',
                                 'INVALID ALERT TYPE');
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
    END IF;

    l_alert_value := CASE
                    WHEN  l_alert_type = 'DAILY_BAL_ALERT'
                    THEN
                        'Daily Balance'
                    WHEN  l_alert_type = 'LOW_BAL_ALERT'
                    THEN
                        'Low Balance'
                    WHEN  l_alert_type = 'NEG_BAL_ALERT'
                    THEN
                        'Negative Balance'
                    WHEN  l_alert_type = 'LOAD_ALERT'
                    THEN
                        'Load/ Credit Alert'
                    WHEN l_alert_type = 'HIGH_AUTH_ALERT'
                    THEN
                        'High Authorization Amount'
                    WHEN l_alert_type = 'INSUFFICIENT_FUND_ALERT'
                    THEN
                        'Insufficient Funds Decline'
                    WHEN l_alert_type = 'INCORRECT_PIN_ALERT'
                    THEN
                        'Incorrect PIN used'
                    WHEN l_alert_type = 'FAST_FIFTY_ALERT'
                    THEN
                        'Fast50'
                    WHEN l_alert_type = 'FEDERALSTATE_TAXREFUND_ALERT'
                    THEN
                        'FEDERALSTATETAXREFUND'
                    END;

    --Validating page and record count
    l_recordsperpage := nvl(p_recordsperpage_in,
                            1000);
    l_pagenumber     := nvl(p_pagenumber_in,
                            1);
    IF  p_recordsperpage_in IS NULL 
    THEN
      l_pagenumber := 1;
    END IF;
                        
    l_rec_end_no     := l_recordsperpage * l_pagenumber;
    l_rec_start_no   := (l_rec_end_no - l_recordsperpage) + 1;
    
--Fetching alert log details
    OPEN c_alert_log_out FOR
        SELECT id,tran_date,mobile,email,alert_type,alert_mode,status, messageDetails  
        FROM (SELECT a.*,rownum  r
        FROM
          (SELECT csl_rrn id,
            TO_CHAR( to_date(csl_business_date
            ||csl_business_time, 'yyyy-mm-dd hh24:mi:ss'), 'yyyy-mm-dd hh24:mi:ss' ) tran_date,
            vmscms.fn_dmaps_main(csl_mobile_no) mobile,
            vmscms.fn_dmaps_main(csl_email_id) email,
            csl_alert_type alert_type,
            DECODE(csl_alertmsg_type,'1','SMS','2','Email','SMS & Email') alert_mode,
            DECODE(csl_process_msg,'Success','Successful',csl_process_msg) status,
            CSL_ALERT_MSG messageDetails --Added for VMS-8942
          FROM VMSCMS.CMS_SMSANDEMAIL_LOG
          WHERE csl_inst_code   = 1
          AND csl_pan_code      = l_hash_pan
          AND (csl_alertmsg_type = l_alert_mode OR l_alert_mode IS NULL)
          AND (csl_alert_type    = l_alert_value OR l_alert_type IS NULL OR l_alert_type = 'ALL')
          AND csl_ins_date BETWEEN l_start_date AND l_end_date ORDER BY csl_ins_date DESC
          )a  
          )alerts
          WHERE r BETWEEN l_rec_start_no AND l_rec_end_no;
 
     
     --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out  := vmscms.gpp_const.c_success_status;

        SELECT count(1)
        INTO l_count
        FROM (SELECT rownum r
        FROM
          (SELECT csl_ins_date     
          FROM VMSCMS.CMS_SMSANDEMAIL_LOG
          WHERE csl_inst_code   = 1
          AND csl_pan_code      = l_hash_pan
          AND (csl_alertmsg_type = l_alert_mode OR l_alert_mode IS NULL)
          AND (csl_alert_type    = l_alert_value OR l_alert_type IS NULL OR l_alert_type = 'ALL')
          AND csl_ins_date BETWEEN l_start_date AND l_end_date ORDER BY csl_ins_date DESC
          )a  
          )alerts
          WHERE r BETWEEN l_rec_start_no AND l_rec_end_no;
     
        
     IF l_count <> 0
     THEN
         p_err_msg_out := 'SUCCESS';
     ELSE
         p_err_msg_out := 'No Data Found';
     END IF;
     
    --Logging success record details
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 p_customer_id_in,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C',
                                                 p_err_msg_out,
                                                 vmscms.gpp_const.c_success_res_id,
                                                 NULL,
                                                 l_timetaken);*/

  EXCEPTION
    WHEN e_reject_record THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := p_err_msg_out;
         --Logging failure record details
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;
         --Logging failure record details
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
         --Logging failure record details
      vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
  END get_customer_alertlog;

BEGIN
  -- Initialization
  init;
END gpp_profile;
/
show error