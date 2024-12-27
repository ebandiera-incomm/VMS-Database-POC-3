create or replace PACKAGE BODY vmscms.GPP_ALERTS IS

  -- PL/SQL Package using FS Framework
  -- Author  : SINDHU
  -- Created : 12-08-2015 16:18:36

  -- Private type declarations
  -- TEST 1
  TYPE ty_rec_alert IS RECORD(
    alert_id    VARCHAR2(20),
    alert_name  VARCHAR2(100),
    alert_desc  VARCHAR2(500),
    alert_value VARCHAR2(100),
    alert_type  VARCHAR2(100));
  TYPE ty_tbl_alert IS TABLE OF ty_rec_alert INDEX BY PLS_INTEGER;
  g_tbl_data_alert     ty_tbl_alert;
  g_tbl_customer_alert ty_tbl_alert;
  g_tbl_update_data    ty_tbl_alert;

  TYPE g_list_t IS TABLE OF VARCHAR2(500) INDEX BY PLS_INTEGER;
  -- Private constant declarations

  -- Private variable declarations

  -- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;

  -- other globals
  g_alert_name  g_list_t;
  g_alert_descr g_list_t;

  --declare all FS errors here
  g_err_nodata       fsfw.fserror_t;
  g_err_unknown      fsfw.fserror_t;
  g_err_mandatory    fsfw.fserror_t;
  g_err_invalid_data fsfw.fserror_t;
  g_err_failure      fsfw.fserror_t;

  -- Function and procedure implementations
  --Get alerts API
  --status: 0 - success, Non Zero value - failure

  PROCEDURE get_alerts_old(p_customer_id_in    IN VARCHAR2,
                           p_status_out        OUT VARCHAR2,
                           p_err_msg_out       OUT VARCHAR2,
                           p_email_out         OUT VARCHAR2,
                           p_phone_no_out      OUT VARCHAR2,
                           p_mobile_status_out OUT VARCHAR2,
                           c_alerts_out        OUT SYS_REFCURSOR) AS
    l_hash_pan      vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan      vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_api_name      VARCHAR2(20) := 'GET ALERTS';
    l_partner_id    vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_start_time    NUMBER;
    l_end_time      NUMBER;
    l_timetaken     NUMBER;
    l_cap_prod_code cms_appl_pan.cap_prod_code%TYPE;
    l_cap_card_type cms_appl_pan.cap_card_type%TYPE;
    
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
    --l_partner_id := sys_context('FSAPI_GPP','x-incfs-partnerid');

    -- l_partner_id := '1';

    SELECT cap_prod_code,
           cap_card_type,
           --cam_email,
           --cam_mobl_one,
		     decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(cam_email),cam_email),
		     decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(cam_mobl_one),cam_mobl_one),
           decode(ccm_optinoptout_status,
                  '0',
                  'Not Available',
                  '1',
                  'Opted In',
                  '2',
                  'Opted Out') ccm_optinoptout_status
      INTO l_cap_prod_code,
           l_cap_card_type,
           p_email_out,
           p_phone_no_out,
           p_mobile_status_out
      FROM vmscms.cms_appl_pan, vmscms.cms_addr_mast, vmscms.cms_cust_mast , vmscms.cms_prod_cattype
     WHERE cap_bill_addr = cam_addr_code
       AND cap_cust_code = ccm_cust_code
       AND ccm_cust_id = to_number(p_customer_id_in)
          --AND ccm_partner_id IN (l_partner_id)
       AND ccm_prod_code || ccm_card_type =
           vmscms.gpp_utils.get_prod_code_card_type(l_partner_id,
                                                    ccm_prod_code,
                                                    ccm_card_type)
	   AND cap_inst_code = cpc_inst_code
	   AND cap_prod_code = cpc_prod_code
	   AND cap_card_type = cpc_card_type
       AND rownum < 2;

    --Fetching the active PAN for the input customer id
    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan);

    -- SS - Fetch product information for the specific PAN
    /*SELECT cap_prod_code, cap_card_type
     INTO l_cap_prod_code,exi l_cap_card_type
     FROM CMS_APPL_PAN
    WHERE cap_pan_code = l_hash_pan
      AND ROWNUM < 2;*/

    --Array for alerts
    OPEN c_alerts_out FOR
      SELECT 1 AS alert_id,
             'Load/Credit Alert' AS alert_name, --modified from Alter_value to Alert_value
             'Whenever the available balance is increasing, customer will get the alert message' AS alert_desc,
             NULL AS alert_value,
             CASE nvl(csa_loadorcredit_flag,
                  '0')
               WHEN '0' THEN
                'Disabled'
               WHEN '1' THEN
                'SMS'
               WHEN '2' THEN
                'Email'
               WHEN '3' THEN
                'SMS and Email'
               ELSE
                'NA'
             END load_credit_alert_type
      --case CPS_FAST50_FLAG when '0' then 'null' else nvl(CSA_FAST50_FLAG,'0') end P_FAST50_FLAG,
      --case CPS_FEDTAX_REFUND_FLAG when '0' then 'null' else nvl(CSA_FEDTAX_REFUND_FLAG,'0') end A_FEDTAX_REFUND_FLAG
        FROM -- vmscms.cms_appl_pan,
             vmscms.cms_prodcatg_smsemail_alerts,
             vmscms.cms_smsandemail_alert
       WHERE csa_pan_code = l_hash_pan --vmscms.gethash(vmscms.fn_dmaps_main(l_pan_code))
            -- AND cap_pan_code = csa_pan_code
         AND cps_prod_code = l_cap_prod_code
         AND cps_card_type = l_cap_card_type
            --Start CFIP-224 Defect Fix
            --AND cps_loadcredit_flag <> 0
         AND dbms_lob.substr(cps_alert_msg,
                    1,
                    1) <> '0'
         AND cps_alert_id = 9
         AND cps_alert_lang_id = nvl(csa_alert_lang_id,
                                     1)
      --End CFIP-224
      UNION ALL
      SELECT 2 AS alert_id,
             'Low Balance Alert' AS alert_name, --modified from Alter_value to Alert_value
             'If the available balance is less than or equal to Low Balance Amount, customer will get alert message' AS alert_desc,
             nvl(to_char(csa_lowbal_amt,
                         '9999999990.99'),
                 '0.00') AS alert_value,
             CASE nvl(csa_lowbal_flag,
                  '0')
               WHEN '0' THEN
                'Disabled'
               WHEN '1' THEN
                'SMS'
               WHEN '2' THEN
                'Email'
               WHEN '3' THEN
                'SMS and Email'
               ELSE
                'NA'
             END low_balance_alert_type
        FROM -- vmscms.cms_appl_pan,
             vmscms.cms_prodcatg_smsemail_alerts,
             vmscms.cms_smsandemail_alert
       WHERE csa_pan_code = l_hash_pan --vmscms.gethash(vmscms.fn_dmaps_main(l_pan_code))
            -- AND cap_pan_code = csa_pan_code
         AND cps_prod_code = l_cap_prod_code
         AND cps_card_type = l_cap_card_type
            --Start CFIP-224 Defect Fix
            --AND cps_lowbal_flag <> 0
         AND dbms_lob.substr(cps_alert_msg,
                    1,
                    1) <> '0'
         AND cps_alert_id = 10
         AND cps_alert_lang_id = nvl(csa_alert_lang_id,
                                     1)
      --End CFIP-224
      UNION ALL
      SELECT 3 AS alert_id,
             'Negative Balance Alert' AS alert_name, --modified from Alter_value to Alert_value
             'Once the Negative balance is reached, system will keep on send the alerts whenever the customer do the debit / credit transactions
         and the available balance is less than zero ' AS alert_desc,
             NULL AS alert_value,
             CASE nvl(csa_negbal_flag,
                  '0')
               WHEN '0' THEN
                'Disabled'
               WHEN '1' THEN
                'SMS'
               WHEN '2' THEN
                'Email'
               WHEN '3' THEN
                'SMS and Email'
               ELSE
                'NA'
             END negative_balance_alert_type
        FROM -- vmscms.cms_appl_pan,
             vmscms.cms_prodcatg_smsemail_alerts,
             vmscms.cms_smsandemail_alert
       WHERE csa_pan_code = l_hash_pan --vmscms.gethash(vmscms.fn_dmaps_main(l_pan_code))
            -- AND cap_pan_code = csa_pan_code
         AND cps_prod_code = l_cap_prod_code
         AND cps_card_type = l_cap_card_type
            --Start CFIP-224 Defect Fix
            --AND cps_negativebal_flag <> 0
         AND dbms_lob.substr(cps_alert_msg,
                    1,
                    1) <> '0'
         AND cps_alert_id = 11
         AND cps_alert_lang_id = nvl(csa_alert_lang_id,
                                     1)
      --End CFIP-224
      UNION ALL
      SELECT 4 AS alert_id,
             'High Authorization Alert' AS alert_name, --modified from Alter_value to Alert_value
             'Once the Negative balance is reached, system will keep on send the alerts whenever the customer do the debit / credit transactions
         and the available balance is less than zero ' AS alert_desc,
             nvl(to_char(csa_highauthamt,
                         '9999999990.99'),
                 '0.00') AS alert_value,
             CASE nvl(csa_highauthamt_flag,
                  '0')
               WHEN '0' THEN
                'Disabled'
               WHEN '1' THEN
                'SMS'
               WHEN '2' THEN
                'Email'
               WHEN '3' THEN
                'SMS and Email'
               ELSE
                'NA'
             END high_authorization_alert_type
        FROM -- vmscms.cms_appl_pan,
             vmscms.cms_prodcatg_smsemail_alerts,
             vmscms.cms_smsandemail_alert
       WHERE csa_pan_code = l_hash_pan --vmscms.gethash(vmscms.fn_dmaps_main(l_pan_code))
            -- AND cap_pan_code = csa_pan_code
         AND cps_prod_code = l_cap_prod_code
         AND cps_card_type = l_cap_card_type
            --Start CFIP-224 Defect Fix
            --AND cps_highauthamt_flag <> 0
         AND dbms_lob.substr(cps_alert_msg,
                    1,
                    1) <> '0'
         AND cps_alert_id = 16
         AND cps_alert_lang_id = nvl(csa_alert_lang_id,
                                     1)
      --End CFIP-224
      UNION ALL
      SELECT 5 AS alert_id,
             'Daily Balance Alert' AS alert_name, --modified from Alter_value to Alert_value
             'System will send daily balance alert to customer' AS alert_desc,
             NULL AS alert_value,
             CASE nvl(csa_dailybal_flag,
                  '0')
               WHEN '0' THEN
                'Disabled'
               WHEN '1' THEN
                'SMS'
               WHEN '2' THEN
                'Email'
               WHEN '3' THEN
                'SMS and Email'
               ELSE
                'NA'
             END daily_balance_alert_type
        FROM -- vmscms.cms_appl_pan,
             vmscms.cms_prodcatg_smsemail_alerts,
             vmscms.cms_smsandemail_alert
       WHERE csa_pan_code = l_hash_pan --vmscms.gethash(vmscms.fn_dmaps_main(l_pan_code))
            -- AND cap_pan_code = csa_pan_code
         AND cps_prod_code = l_cap_prod_code
         AND cps_card_type = l_cap_card_type
            --Start CFIP-224 Defect Fix
            --AND cps_dailybal_flag <> 0
         AND dbms_lob.substr(cps_alert_msg,
                    1,
                    1) <> '0'
         AND cps_alert_id = 12
         AND cps_alert_lang_id = nvl(csa_alert_lang_id,
                                     1)
      --End CFIP-224
      UNION ALL
      SELECT 6 AS alert_id,
             'Insufficient Fund Alert' AS alert_name, --modified from Alter_value to Alert_value
             'System will send alert when the available balance is insufficient while doing transactions' AS alert_desc,
             NULL AS alert_value,
             CASE nvl(csa_insuff_flag,
                  '0')
               WHEN '0' THEN
                'Disabled'
               WHEN '1' THEN
                'SMS'
               WHEN '2' THEN
                'Email'
               WHEN '3' THEN
                'SMS and Email'
               ELSE
                'NA'
             END insufficient_fund_alert_type
        FROM -- vmscms.cms_appl_pan,
             vmscms.cms_prodcatg_smsemail_alerts,
             vmscms.cms_smsandemail_alert
       WHERE csa_pan_code = l_hash_pan --vmscms.gethash(vmscms.fn_dmaps_main(l_pan_code))
            -- AND cap_pan_code = csa_pan_code
         AND cps_prod_code = l_cap_prod_code
         AND cps_card_type = l_cap_card_type
            --Start CFIP-224 Defect Fix
            --AND cps_insuffund_flag <> 0
         AND dbms_lob.substr(cps_alert_msg,
                    1,
                    1) <> '0'
         AND cps_alert_id = 17
         AND cps_alert_lang_id = nvl(csa_alert_lang_id,
                                     1)
      --End CFIP-224
      UNION ALL
      SELECT 7 AS alert_id,
             'Incorrect PIN Alert' AS alert_name, --modified from Alter_value to Alert_value
             'System will send alert for each and every invalid PIN' AS alert_desc,
             NULL AS alert_value,
             CASE nvl(csa_incorrpin_flag,
                  '0')
               WHEN '0' THEN
                'Disabled'
               WHEN '1' THEN
                'SMS'
               WHEN '2' THEN
                'Email'
               WHEN '3' THEN
                'SMS and Email'
               ELSE
                'NA'
             END incorrect_pin_alert_type
        FROM -- vmscms.cms_appl_pan,
             vmscms.cms_prodcatg_smsemail_alerts,
             vmscms.cms_smsandemail_alert
       WHERE csa_pan_code = l_hash_pan --vmscms.gethash(vmscms.fn_dmaps_main(l_pan_code))
            -- AND cap_pan_code = csa_pan_code
         AND cps_prod_code = l_cap_prod_code
         AND cps_card_type = l_cap_card_type
            --Start CFIP-224 Defect Fix
            --AND cps_incorrectpin_flag <> 0
         AND dbms_lob.substr(cps_alert_msg,
                    1,
                    1) <> '0'
         AND cps_alert_id = 13
         AND cps_alert_lang_id = nvl(csa_alert_lang_id,
                                     1)
      --End CFIP-224 Defect Fix
      UNION ALL
      SELECT 8 AS alert_id,
             'Fast50 Load Credit Alert' AS alert_name, --modified from Alter_value to Alert_value
             'System will send this alert when a Fast50 transaction is received on a card' AS alert_desc,
             NULL AS alert_value,
             CASE nvl(csa_fast50_flag,
                  '0')
               WHEN '0' THEN
                'Disabled'
               WHEN '1' THEN
                'SMS'
               WHEN '2' THEN
                'Email'
               WHEN '3' THEN
                'SMS and Email'
               ELSE
                'NA'
             END fast50_load_credit_alert_type
        FROM -- vmscms.cms_appl_pan,
             vmscms.cms_prodcatg_smsemail_alerts,
             vmscms.cms_smsandemail_alert
       WHERE csa_pan_code = l_hash_pan --vmscms.gethash(vmscms.fn_dmaps_main(l_pan_code))
            -- AND cap_pan_code = csa_pan_code
         AND cps_prod_code = l_cap_prod_code
         AND cps_card_type = l_cap_card_type
            --Start CFIP-224 Defect Fix
            --AND cps_fast50_flag <> 0
         AND dbms_lob.substr(cps_alert_msg,
                    1,
                    1) <> '0'
         AND cps_alert_id = 21
         AND cps_alert_lang_id = nvl(csa_alert_lang_id,
                                     1)
      --End CFIP-224
      UNION ALL
      SELECT 9 AS alert_id,
             'Federal/State Tax Refund Alert' AS alert_name, --modified from Alter_value to Alert_value
             'System will send this alert when a Tax Refund transaction is received on a card' AS alert_desc,
             NULL AS alert_value,
             CASE nvl(csa_fedtax_refund_flag,
                  '0')
               WHEN '0' THEN
                'Disabled'
               WHEN '1' THEN
                'SMS'
               WHEN '2' THEN
                'Email'
               WHEN '3' THEN
                'SMS and Email'
               ELSE
                'NA'
             END fed_state_tax_ref_alert_type
        FROM -- vmscms.cms_appl_pan,
             vmscms.cms_prodcatg_smsemail_alerts,
             vmscms.cms_smsandemail_alert
       WHERE csa_pan_code = l_hash_pan
            -- AND cap_pan_code = csa_pan_code
         AND cps_prod_code = l_cap_prod_code
         AND cps_card_type = l_cap_card_type
            --Start CFIP-224 Defect Fix
            --AND cps_fedtax_refund_flag <> 0;
         AND dbms_lob.substr(cps_alert_msg,
                    1,
                    1) <> '0'
         AND cps_alert_id = 22
         AND cps_alert_lang_id = nvl(csa_alert_lang_id,
                                     1);
    --End CFIP-224
    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');
    p_status_out := vmscms.gpp_const.c_success_status;
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,       ----Commented for VMS-1719 - CCA RRN Logging Issue.
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
      g_debug.display('Error : ' || substr(SQLERRM,
                                           1,
                                           1000));
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
  END get_alerts_old;

  PROCEDURE get_alerts(p_customer_id_in    IN VARCHAR2,
                       p_status_out        OUT VARCHAR2,
                       p_err_msg_out       OUT VARCHAR2,
                       p_email_out         OUT VARCHAR2,
                       p_phone_no_out      OUT VARCHAR2,
                       p_mobile_status_out OUT VARCHAR2,
                       c_alerts_out        OUT SYS_REFCURSOR) AS
    l_hash_pan        vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan        vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_api_name        VARCHAR2(20) := 'GET ALERTS';
    l_partner_id      vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_start_time      NUMBER;
    l_end_time        NUMBER;
    l_timetaken       NUMBER;
    l_cap_prod_code   vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_cap_card_type   vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_gpp_alerts_list vmscms.gppalerts_list_t := vmscms.gppalerts_list_t();
    l_gpp_alerts_row  vmscms.gppalerts_t := vmscms.gppalerts_t(NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL);
    l_cust_alerts     vmscms.cms_smsandemail_alert%ROWTYPE;
    l_cust_lang_id    vmscms.cms_smsandemail_alert.csa_alert_lang_id%TYPE;
    l_count           PLS_INTEGER;
    l_load_data       BOOLEAN;
    
/****************************************************************************    
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002
	 
	 
      * Modified by      : UBAIDUR RAHMAN H
      * Modified for     : VMS-2010
      * Modified Date    : 26-JAN-2020
      * Reviewer         : Saravanakumar A
      * Build Number     : VMSGPRHOST_R27_B2
	 
****************************************************************************/

  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --dbms_output.put_line(l_partner_id || '....' || p_customer_id_in);
    --l_partner_id := sys_context('FSAPI_GPP','x-incfs-partnerid');

    --l_partner_id := '1';

    WITH cust_mast AS
     (SELECT ccm_inst_code,
             ccm_cust_code,
             ccm_optinoptout_status,
             ccm_prod_code,
             ccm_card_type
        FROM cms_cust_mast
       WHERE ccm_cust_id = to_number(p_customer_id_in)
         AND
            --ccm_partner_id = l_partner_id
             ccm_prod_code || ccm_card_type =
             vmscms.gpp_utils.get_prod_code_card_type(l_partner_id,
                                                      ccm_prod_code,
                                                      ccm_card_type)),
    appl_pan_all AS
     (SELECT cap_pan_code,
             cap_prod_code,
             cap_card_type,
             cap_bill_addr,
             cap_active_date,
             cap_card_stat,
             cap_inst_code,
             cap_cust_code,
             cap_pan_code_encr -- CFIP 350
        FROM cms_appl_pan, cust_mast
       WHERE cap_inst_code = cust_mast.ccm_inst_code
         AND cap_cust_code = cust_mast.ccm_cust_code
            -- CFIP-259
            --AND cap_active_date IS NOT NULL
         AND cap_card_stat <> '9'
       ORDER BY cap_active_date, cap_pangen_date DESC), -- CFIP-259 added cap_pangen_date column
    appl_pan AS
     (SELECT * FROM appl_pan_all WHERE rownum = 1),
    addr_mast AS
     (SELECT cam_email, cam_mobl_one, cam_inst_code, cam_cust_code
        FROM cms_addr_mast, cust_mast, appl_pan
       WHERE cam_inst_code = 1
         AND cam_cust_code = cust_mast.ccm_cust_code
        --- AND cam_addr_code = appl_pan.cap_bill_addr
	 AND cam_addr_flag = 'P')
    SELECT appl_pan.cap_pan_code,
           appl_pan.cap_prod_code,
           appl_pan.cap_card_type,
           decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(addr_mast.cam_email),addr_mast.cam_email) cam_email,
           decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(addr_mast.cam_mobl_one),addr_mast.cam_mobl_one) cam_mobl_one,
           decode(cust_mast.ccm_optinoptout_status,
                  '0',
                  'Not Available',
                  '1',
                  'Opted In',
                  '2',
                  'Opted Out'),
           appl_pan.cap_pan_code_encr
      INTO l_hash_pan,
           l_cap_prod_code,
           l_cap_card_type,
           p_email_out,
           p_phone_no_out,
           p_mobile_status_out,
           l_encr_pan -- CFIP 305
      FROM appl_pan, addr_mast, cust_mast , cms_prod_cattype
     WHERE cust_mast.ccm_inst_code = appl_pan.cap_inst_code
       AND cust_mast.ccm_cust_code = appl_pan.cap_cust_code
       AND cust_mast.ccm_inst_code = addr_mast.cam_inst_code
       AND cust_mast.ccm_cust_code = addr_mast.cam_cust_code
       AND appl_pan.cap_inst_code = cpc_inst_code
       AND appl_pan.cap_prod_code = cpc_prod_code
       AND appl_pan.cap_card_type = cpc_card_type;

    --Fetching the active PAN for the input customer id
    -- vmscms.gpp_pan.get_pan_details(p_customer_id_in,
    -- l_hash_pan, l_encr_pan);

    -- new code using the gpp_alerts_list_t table object type

    -- 1. Get data from cms_smsandemail_alert

    SELECT *
      INTO l_cust_alerts
      FROM vmscms.cms_smsandemail_alert
     WHERE csa_pan_code = l_hash_pan;

    l_cust_lang_id := nvl(l_cust_alerts.csa_alert_lang_id,
                          1);

    -- 2. Loop through data in cms_prodcatg_smsemail_alerts

    l_count := 1;

    FOR l_rec IN (SELECT cps_alert_id, cps_alert_msg
                    FROM vmscms.cms_prodcatg_smsemail_alerts
                   WHERE cps_prod_code = l_cap_prod_code
                     AND cps_card_type = l_cap_card_type
                     AND dbms_lob.substr(cps_alert_msg,
                                1,
                                1) <> '0'
                     AND cps_alert_lang_id = l_cust_lang_id
                     AND cps_alert_id BETWEEN 9 AND 22
                   ORDER BY cps_alert_id)
    LOOP

      l_load_data                  := TRUE;
      l_gpp_alerts_row.alert_value := NULL; --modified from Alter_value to Alert_value

      CASE l_rec.cps_alert_id
        WHEN 9 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_loadorcredit_flag,
                                                         '0');
        WHEN 10 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_lowbal_flag,
                                                         '0');
          --modified from Alter_value to Alert_value
          l_gpp_alerts_row.alert_value := nvl(to_char(l_cust_alerts.csa_lowbal_amt,
                                                      '9999999990.99'),
                                              '0.00');
        WHEN 11 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_negbal_flag,
                                                         '0');
        WHEN 12 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_dailybal_flag,
                                                         '0');
        WHEN 13 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_incorrpin_flag,
                                                         '0');
        WHEN 16 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_highauthamt_flag,
                                                         '0');
          --modified from Alter_value to Alert_value
          l_gpp_alerts_row.alert_value := nvl(to_char(l_cust_alerts.csa_highauthamt,
                                                      '9999999990.99'),
                                              '0.00');
        WHEN 17 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_insuff_flag,
                                                         '0');
        WHEN 21 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_fast50_flag,
                                                         '0');
        WHEN 22 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_fedtax_refund_flag,
                                                         '0');
        ELSE
          l_gpp_alerts_row.load_credit_alert_type := '0';
          l_load_data                             := FALSE;
      END CASE;

      IF l_load_data
      THEN
        l_gpp_alerts_list.extend;
        l_gpp_alerts_row.alert_id := l_count;
        l_gpp_alerts_row.load_credit_alert_type := CASE
                                                    l_gpp_alerts_row.load_credit_alert_type
                                                     WHEN '0' THEN
                                                      'Disabled'
                                                     WHEN '1' THEN
                                                      'SMS'
                                                     WHEN '2' THEN
                                                      'Email'
                                                     WHEN '3' THEN
                                                      'SMS and Email'
                                                     ELSE
                                                      'NA'
                                                   END;
        l_gpp_alerts_row.alert_name := g_alert_name(l_rec.cps_alert_id);
        l_gpp_alerts_row.alert_desc := g_alert_descr(l_rec.cps_alert_id);
        l_gpp_alerts_list(l_count) := l_gpp_alerts_row;
        l_count := l_count + 1;
      END IF;
    END LOOP;

    -- all data loaded, return ref cursor
    OPEN c_alerts_out FOR
      SELECT *
        FROM TABLE(CAST(l_gpp_alerts_list AS vmscms.gppalerts_list_t));

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
      g_debug.display('Error : ' || substr(SQLERRM,
                                           1,
                                           1000));
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
  END get_alerts;

  PROCEDURE get_alert_details_for_update(p_customer_id_in    IN VARCHAR2,
                                         p_status_out        OUT VARCHAR2,
                                         p_err_msg_out       OUT VARCHAR2,
                                         p_email_out         OUT VARCHAR2,
                                         p_phone_no_out      OUT VARCHAR2,
                                         p_mobile_status_out OUT VARCHAR2,
                                         p_pan_code          OUT VARCHAR2,
                                         p_pan_code_encr     OUT VARCHAR2,
                                         p_prod_code         OUT VARCHAR2,
                                         p_card_type         OUT VARCHAR2,
                                         p_acct_no           OUT VARCHAR2,
                                         c_alerts_out        OUT SYS_REFCURSOR) AS
    l_hash_pan        vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan        vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_api_name        VARCHAR2(20) := 'GET ALERTS';
    l_partner_id      vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_start_time      NUMBER;
    l_end_time        NUMBER;
    l_timetaken       NUMBER;
    l_cap_prod_code   vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_cap_card_type   vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_gpp_alerts_list vmscms.gppalerts_list_t := vmscms.gppalerts_list_t();
    l_gpp_alerts_row  vmscms.gppalerts_t := vmscms.gppalerts_t(NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL);
    l_cust_alerts     vmscms.cms_smsandemail_alert%ROWTYPE;
    l_cust_lang_id    vmscms.cms_smsandemail_alert.csa_alert_lang_id%TYPE;
    l_count           PLS_INTEGER;
    l_load_data       BOOLEAN;

/****************************************************************************    
 	 
      * Modified by      : UBAIDUR RAHMAN H
      * Modified for     : VMS-2010
      * Modified Date    : 26-JAN-2020
      * Reviewer         : Saravanakumar A
      * Build Number     : VMSGPRHOST_R27_B2
	 
****************************************************************************/

  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --l_partner_id := sys_context('FSAPI_GPP','x-incfs-partnerid');

    -- l_partner_id := '1';

    WITH cust_mast AS
     (SELECT ccm_inst_code, ccm_cust_code, ccm_optinoptout_status
        FROM (SELECT ccm_inst_code,
                     ccm_cust_code,
                     ccm_optinoptout_status,
                     ccm_partner_id,
                     ccm_prod_code,
                     ccm_card_type
                FROM cms_cust_mast
               WHERE ccm_cust_id = to_number(p_customer_id_in))
       WHERE
      --ccm_partner_id = l_partner_id
       ccm_prod_code || ccm_card_type =
       vmscms.gpp_utils.get_prod_code_card_type(l_partner_id,
                                                ccm_prod_code,
                                                ccm_card_type)),
    appl_pan_all AS
     (SELECT cap_pan_code,
             cap_prod_code,
             cap_card_type,
             cap_bill_addr,
             cap_active_date,
             cap_card_stat,
             cap_inst_code,
             cap_cust_code,
             cap_pan_code_encr,
             cap_acct_no
        FROM cms_appl_pan, cust_mast
       WHERE cap_inst_code = cust_mast.ccm_inst_code
         AND cap_cust_code = cust_mast.ccm_cust_code
         AND cap_active_date IS NOT NULL
         AND cap_card_stat <> '9'
       ORDER BY cap_active_date DESC),
    appl_pan AS
     (SELECT * FROM appl_pan_all WHERE rownum = 1),
    addr_mast AS
     (SELECT cam_email, cam_mobl_one, cam_inst_code, cam_cust_code
        FROM cms_addr_mast, cust_mast, appl_pan
       WHERE cam_inst_code = 1
         AND cam_cust_code = cust_mast.ccm_cust_code
         --- AND cam_addr_code = appl_pan.cap_bill_addr
	  AND cam_addr_flag = 'P')
    SELECT appl_pan.cap_pan_code,
           appl_pan.cap_prod_code,
           appl_pan.cap_card_type,
           decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(addr_mast.cam_email),addr_mast.cam_email) cam_email,
           decode(cpc_encrypt_enable,'Y', vmscms.fn_dmaps_main(addr_mast.cam_mobl_one),addr_mast.cam_mobl_one) cam_mobl_one,
           decode(cust_mast.ccm_optinoptout_status,
                  '0',
                  'Not Available',
                  '1',
                  'Opted In',
                  '2',
                  'Opted Out'),
           appl_pan.cap_pan_code_encr,
           appl_pan.cap_acct_no
      INTO p_pan_code,
           p_prod_code,
           p_card_type,
           p_email_out,
           p_phone_no_out,
           p_mobile_status_out,
           p_pan_code_encr,
           p_acct_no
      FROM appl_pan, addr_mast, cust_mast, cms_prod_cattype
     WHERE cust_mast.ccm_inst_code = appl_pan.cap_inst_code
       AND cust_mast.ccm_cust_code = appl_pan.cap_cust_code
       AND cust_mast.ccm_inst_code = addr_mast.cam_inst_code
       AND cust_mast.ccm_cust_code = addr_mast.cam_cust_code
       AND appl_pan.cap_inst_code = cpc_inst_code
       AND appl_pan.cap_prod_code = cpc_prod_code
       AND appl_pan.cap_card_type = cpc_card_type;

    --Fetching the active PAN for the input customer id
    -- vmscms.gpp_pan.get_pan_details(p_customer_id_in,
    -- l_hash_pan, l_encr_pan);

    -- new code using the gpp_alerts_list_t table object type

    -- 1. Get data from cms_smsandemail_alert

    SELECT *
      INTO l_cust_alerts
      FROM vmscms.cms_smsandemail_alert
     WHERE csa_pan_code = p_pan_code;

    l_cust_lang_id := nvl(l_cust_alerts.csa_alert_lang_id,
                          1);

    -- 2. Loop through data in cms_prodcatg_smsemail_alerts

    l_count := 1;

    FOR l_rec IN (SELECT cps_alert_id, cps_alert_msg
                    FROM vmscms.cms_prodcatg_smsemail_alerts
                   WHERE cps_prod_code = p_prod_code
                     AND cps_card_type = p_card_type
                     AND dbms_lob.substr(cps_alert_msg,
                                1,
                                1) <> '0'
                     AND cps_alert_lang_id = l_cust_lang_id
                     AND cps_alert_id BETWEEN 9 AND 22
                   ORDER BY cps_alert_id)
    LOOP

      l_load_data                  := TRUE;
      l_gpp_alerts_row.alert_value := NULL; --modified from Alter_value to Alert_value

      CASE l_rec.cps_alert_id
        WHEN 9 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_loadorcredit_flag,
                                                         '0');
        WHEN 10 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_lowbal_flag,
                                                         '0');
          --modified from Alter_value to Alert_value
          l_gpp_alerts_row.alert_value := nvl(to_char(l_cust_alerts.csa_lowbal_amt,
                                                      '9999999990.99'),
                                              '0.00');
        WHEN 11 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_negbal_flag,
                                                         '0');
        WHEN 12 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_dailybal_flag,
                                                         '0');
        WHEN 13 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_incorrpin_flag,
                                                         '0');
        WHEN 16 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_highauthamt_flag,
                                                         '0');
          --modified from Alter_value to Alert_value
          l_gpp_alerts_row.alert_value := nvl(to_char(l_cust_alerts.csa_highauthamt,
                                                      '9999999990.99'),
                                              '0.00');
        WHEN 17 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_insuff_flag,
                                                         '0');
        WHEN 21 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_fast50_flag,
                                                         '0');
        WHEN 22 THEN
          l_gpp_alerts_row.load_credit_alert_type := nvl(l_cust_alerts.csa_fedtax_refund_flag,
                                                         '0');
        ELSE
          l_gpp_alerts_row.load_credit_alert_type := '0';
          l_load_data                             := FALSE;
      END CASE;

      IF l_load_data
      THEN
        l_gpp_alerts_list.extend;
        l_gpp_alerts_row.alert_id := l_count;
        l_gpp_alerts_row.load_credit_alert_type := CASE
                                                    l_gpp_alerts_row.load_credit_alert_type
                                                     WHEN '0' THEN
                                                      'Disabled'
                                                     WHEN '1' THEN
                                                      'SMS'
                                                     WHEN '2' THEN
                                                      'Email'
                                                     WHEN '3' THEN
                                                      'SMS and Email'
                                                     ELSE
                                                      'NA'
                                                   END;
        l_gpp_alerts_row.alert_name := g_alert_name(l_rec.cps_alert_id);
        l_gpp_alerts_row.alert_desc := g_alert_descr(l_rec.cps_alert_id);
        l_gpp_alerts_list(l_count) := l_gpp_alerts_row;
        l_count := l_count + 1;
      END IF;
    END LOOP;

    -- all data loaded, return ref cursor
    OPEN c_alerts_out FOR
      SELECT *
        FROM TABLE(CAST(l_gpp_alerts_list AS vmscms.gppalerts_list_t));

    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');
    p_status_out := vmscms.gpp_const.c_success_status;

  EXCEPTION
    WHEN no_data_found THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(l_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_nodata.get_current_error;

    WHEN OTHERS THEN
      g_debug.display('Error : ' || substr(SQLERRM,
                                           1,
                                           1000));
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := g_err_unknown.get_current_error;

  END get_alert_details_for_update;

  --Update Alerts
  PROCEDURE get_customer_alerts(p_customer_id        IN VARCHAR2,
                                g_tbl_customer_alert OUT ty_tbl_alert,
                                p_api_name           IN VARCHAR2,
                                p_pan_code           OUT VARCHAR2,
                                p_pan_code_encr      OUT VARCHAR2,
                                p_prod_code          OUT VARCHAR2,
                                p_card_type          OUT VARCHAR2,
                                p_acct_no            OUT VARCHAR2,
                                p_status             OUT VARCHAR2,
                                p_err_msg            OUT VARCHAR2) AS
    l_email         cms_addr_mast.cam_email%TYPE;
    l_phone_no      VARCHAR2(20);
    l_mobile_status VARCHAR2(20);
    c_alerts        SYS_REFCURSOR;
  BEGIN
    g_debug.display('calling get_alert_details_for_update call');
    get_alert_details_for_update(p_customer_id, --'101653917',
                                 p_status,
                                 p_err_msg,
                                 l_email,
                                 l_phone_no,
                                 l_mobile_status,
                                 p_pan_code,
                                 p_pan_code_encr,
                                 p_prod_code,
                                 p_card_type,
                                 p_acct_no,
                                 c_alerts);
    g_debug.display('after get_alert_details_for_update call');
    FETCH c_alerts BULK COLLECT
      INTO g_tbl_customer_alert;
    CLOSE c_alerts;

    --Converting types as per FAS API Doc, since the types returned from GET ALERTS are different from the values mentioned in FS API
    IF g_tbl_customer_alert.count > 0
    THEN
      FOR i IN g_tbl_customer_alert.first .. g_tbl_customer_alert.last
      LOOP
        CASE upper(g_tbl_customer_alert(i).alert_type)
          WHEN 'SMS AND EMAIL' THEN
            g_tbl_customer_alert(i).alert_type := 'BOTH';
          WHEN 'SMS' THEN
            g_tbl_customer_alert(i).alert_type := 'MOBILE';
          WHEN 'DISABLED' THEN
            g_tbl_customer_alert(i).alert_type := 'OFF';
          ELSE
            NULL;
        END CASE;
      END LOOP;
    END IF;

  EXCEPTION
    WHEN no_data_found THEN
      p_status := vmscms.gpp_const.c_ora_error_status;
      g_err_nodata.raise(p_api_name,
                         vmscms.gpp_const.c_ora_error_status);
      p_err_msg := g_err_nodata.get_current_error;
    WHEN OTHERS THEN
      p_status := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(p_api_name,
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg := g_err_unknown.get_current_error;
      RETURN;
  END get_customer_alerts;

  PROCEDURE parse_data_alerts(p_alerts         IN VARCHAR2,
                              g_tbl_data_alert OUT ty_tbl_alert,
                              p_api_name       IN VARCHAR2,
                              p_status         OUT VARCHAR2,
                              p_err_msg        OUT VARCHAR2) AS
    l_alerts_arr fsfw.fslist_t := fsfw.fslist_t();
    l_alerts     VARCHAR2(4000);
    l_cnt        PLS_INTEGER;
    l_start_pos  PLS_INTEGER := 1;
    l_length     PLS_INTEGER := 0;
    l_occ1       PLS_INTEGER;
    l_occ2       PLS_INTEGER;
    l_occ3       PLS_INTEGER;
    l_occ4       PLS_INTEGER;
  BEGIN
    --Parsing the records from input alerts array
    g_debug.display('parsing the records in input alerts');
    l_alerts := REPLACE(p_alerts,
                        '||',
                        ':');
    l_cnt    := regexp_count(l_alerts,
                             ':');
    l_alerts_arr.extend();
    l_alerts_arr(1) := substr(l_alerts,
                              1,
                              instr(l_alerts,
                                    ':') - 1);
    FOR idx IN 1 .. l_cnt
    LOOP
      l_alerts_arr.extend();
      g_debug.display(g_debug.format('idx : $1 ',
                                     l_alerts_arr(idx)));
      l_start_pos := instr(l_alerts,
                           ':',
                           1,
                           idx) + 1;
      l_length    := (instr(l_alerts,
                            ':',
                            1,
                            idx + 1) - instr(l_alerts,
                                              ':',
                                              1,
                                              idx)) - 1;
      g_debug.display(g_debug.format('sp :$1 ',
                                     l_start_pos));
      g_debug.display(g_debug.format('ln :$1 ',
                                     l_length));
      l_alerts_arr(idx + 1) := substr(l_alerts,
                                      l_start_pos,
                                      l_length);
    END LOOP;
    l_alerts_arr(l_cnt + 1) := substr(l_alerts,
                                      instr(l_alerts,
                                            ':',
                                            -1) + 1);

    --Parsing the fields from the parsed records
    g_debug.display('parsing the fields in input alerts');
    --if l_alerts_arr.count > 0 then
    FOR idx IN l_alerts_arr.first .. l_alerts_arr.last
    LOOP
      l_occ1 := instr(l_alerts_arr(idx),
                      '~');

      g_tbl_data_alert(idx).alert_id := substr(l_alerts_arr(idx),
                                               1,
                                               l_occ1 - 1);
      g_debug.display('parsing alert id' || g_tbl_data_alert(idx).alert_id);
      l_occ2 := instr(l_alerts_arr(idx),
                      '~',
                      1,
                      2);

      g_tbl_data_alert(idx).alert_name := substr(l_alerts_arr(idx),
                                                 l_occ1 + 1,
                                                 (l_occ2 - l_occ1) - 1);
      g_debug.display('parsing alert_name' || g_tbl_data_alert(idx)
                      .alert_name);

      l_occ3 := instr(l_alerts_arr(idx),
                      '~',
                      1,
                      3);
      /*g_tbl_data_alert(idx).alert_desc := substr(l_alerts_arr(idx),
      l_occ2 + 1,
      (l_occ3 - l_occ2) - 1);*/

      g_tbl_data_alert(idx).alert_desc := substr(l_alerts_arr(idx),
                                                 l_occ2 + 1,
                                                 (l_occ3 - l_occ2) - 1);
      g_debug.display('parsing alert_desc' || g_tbl_data_alert(idx)
                      .alert_desc);

      l_occ4 := instr(l_alerts_arr(idx),
                      '~',
                      1,
                      4);
      g_tbl_data_alert(idx).alert_value := substr(l_alerts_arr(idx),
                                                  l_occ3 + 1,
                                                  (l_occ4 - l_occ3) - 1);
      g_debug.display('parsing alert_value' || g_tbl_data_alert(idx)
                      .alert_value);
      g_tbl_data_alert(idx).alert_type := substr(l_alerts_arr(idx),
                                                 l_occ4 + 1);
      g_debug.display('parsing alert_type' || g_tbl_data_alert(idx)
                      .alert_type);
    END LOOP;
    --end if;
  EXCEPTION

    WHEN OTHERS THEN
      g_debug.display('Exception in parsing');
      p_status := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(p_api_name,
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg := g_err_unknown.get_current_error;
      RETURN;
  END parse_data_alerts;

  PROCEDURE update_customer_alerts(g_tbl_customer_alert IN ty_tbl_alert,
                                   g_tbl_data_alert     IN ty_tbl_alert,
                                   g_tbl_update_data    OUT ty_tbl_alert,
                                   p_api_name           IN VARCHAR2,
                                   p_status             OUT VARCHAR2,
                                   p_err_msg            OUT VARCHAR2) AS

  BEGIN
    g_debug.display('copying customer alerts details');
    g_tbl_update_data := g_tbl_customer_alert;

    g_debug.display('updating customer alerts details');

    IF g_tbl_update_data.count > 0
    THEN
      FOR i IN g_tbl_update_data.first .. g_tbl_update_data.last
      LOOP
        FOR j IN g_tbl_data_alert.first .. g_tbl_data_alert.last
        LOOP
          --modified if condition by Arun Devappa for CFIP-66
          IF upper(g_tbl_update_data(i).alert_name) =
             upper(g_tbl_data_alert(j).alert_name)
          THEN
            g_tbl_update_data(i).alert_value := g_tbl_data_alert(j)
                                                .alert_value;
            g_tbl_update_data(i).alert_type := g_tbl_data_alert(j)
                                               .alert_type;
          END IF;
        END LOOP;
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      g_debug.display('Exception in updating customer alerts');
      p_status := vmscms.gpp_const.c_ora_error_status;
      g_err_unknown.raise(p_api_name,
                          vmscms.gpp_const.c_ora_error_status);
      p_err_msg := g_err_unknown.get_current_error;
      RETURN;
  END update_customer_alerts;

  PROCEDURE update_alerts(p_customer_id_in IN VARCHAR2,
                          p_email_in       IN VARCHAR2,
                          p_phone_no_in    IN VARCHAR2,
                          p_alerts_in      IN VARCHAR2,
                          p_comment_in     IN VARCHAR2,
                          --p_dummy_in       IN varchar2,
                          p_status_out     OUT VARCHAR2,
                          p_err_msg_out    OUT VARCHAR2,
						              p_optinflag_out  OUT  VARCHAR2) AS
							      
/****************************************************************************    
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 20-Jul-2020
         * Modified Reason    : VMS-2809 - Decouple initial load alerts from Reload.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 20-Jul-2020
         * Build Number       : R33_B3
	 
****************************************************************************/    
    l_hash_pan               vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan               vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_date                   VARCHAR2(50);
    l_timestamp              VARCHAR2(20);
    l_resp_code              VARCHAR2(5);
    l_resp_msg               VARCHAR2(500);
    l_curr_code              VARCHAR2(20);
    l_flag                   PLS_INTEGER;
    l_loadorcreditalert      VARCHAR2(1);
    l_lowbalalert            VARCHAR2(1);
    l_negativebalalert       VARCHAR2(1);
    l_highauthamtalert       VARCHAR2(1);
    l_dailybalalert          VARCHAR2(1);
    l_insufficientalert      VARCHAR2(1);
    l_incorrectpinalert      VARCHAR2(1);
    l_fast50alert            VARCHAR2(1);
    l_federalstatealert      VARCHAR2(1);
    l_field_name             VARCHAR2(30);
    l_plain_pan              VARCHAR2(20);
    l_lowbalalert_value      VARCHAR2(20);
    l_highauthamtalert_value VARCHAR2(20);
    l_rrn                    VARCHAR2(20);
    l_alert_type             VARCHAR2(30);
    l_api_name               VARCHAR2(20) := 'UPDATE ALERTS';
    l_start_time             NUMBER;
    l_end_time               NUMBER;
    l_timetaken              NUMBER;
    l_prod_code              vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type              vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_call_seq               vmscms.cms_calllog_details.ccd_call_seq%TYPE;
    l_acct_no                vmscms.cms_appl_pan.cap_acct_no%TYPE;
  BEGIN
    /*If p_dummy_in = 'TRUE' THEN
      dbms_output.put_line('TRUE');
    ELSE
      dbms_output.put_line('FALSE');
    end if;*/

    l_start_time := dbms_utility.get_time;
    --Check for mandatory fields
    CASE
      WHEN p_customer_id_in IS NULL THEN
        l_field_name := 'CUSTOMER ID';
        l_flag       := 1;
      WHEN p_email_in IS NULL THEN
        l_field_name := 'EMAIL';
        l_flag       := 1;
      WHEN p_phone_no_in IS NULL THEN
        l_field_name := 'PHONE';
        l_flag       := 1;
      WHEN p_comment_in IS NULL THEN
        l_field_name := 'COMMENT';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;

    g_debug.display('calling alerts parsing');
    parse_data_alerts(p_alerts_in,
                      g_tbl_data_alert,
                      l_api_name,
                      p_status_out,
                      p_err_msg_out);

    --if g_tbl_data_alert.count > 0 then
    FOR idx IN g_tbl_data_alert.first .. g_tbl_data_alert.last
    LOOP
      g_debug.display('alert id' || g_tbl_data_alert(idx).alert_id);
      g_debug.display('alert_type' || g_tbl_data_alert(idx).alert_type);
      g_debug.display('alert_name' || g_tbl_data_alert(idx).alert_name);
      g_debug.display('alert_value' || g_tbl_data_alert(idx).alert_value);
      g_debug.display('alert_desc' || g_tbl_data_alert(idx).alert_desc);
      CASE
        WHEN g_tbl_data_alert(idx).alert_id IS NULL THEN
          l_field_name := 'ID ' || idx;
          l_flag       := 1;
          EXIT;
        WHEN g_tbl_data_alert(idx).alert_type IS NULL THEN
          l_field_name := 'TYPE ' || idx;
          l_flag       := 1;
          EXIT;
        WHEN upper(g_tbl_data_alert(idx).alert_type) NOT IN
             ('MOBILE',
              'EMAIL',
              'BOTH',
              'OFF') THEN
          g_debug.display('rosy' ||
                          upper(g_tbl_data_alert(idx).alert_type));
          l_flag := 2;
          EXIT;
        WHEN upper(g_tbl_data_alert(idx).alert_name) = 'LOW BALANCE ALERT' THEN
          --value for lowbalance alert is mandatory
          IF g_tbl_data_alert(idx).alert_value IS NULL
          THEN
            l_field_name := 'Value for Low Balance Alert';
            l_flag       := 1;
            EXIT;
          END IF;
        WHEN upper(g_tbl_data_alert(idx).alert_name) =
             'HIGH AUTHORIZATION ALERT' THEN
          --value for highauthamt alert is mandatory
          IF g_tbl_data_alert(idx).alert_value IS NULL
          THEN
            l_field_name := 'Value for High Auth Alert';
            l_flag       := 1;
            EXIT;
          END IF;
        ELSE
          NULL;
      END CASE;
    END LOOP;
    --end if;

    g_debug.display('input array of alerts');
    FOR i IN g_tbl_data_alert.first .. g_tbl_data_alert.last
    LOOP
      g_debug.display(g_debug.format('alert id : $1',
                                     g_tbl_data_alert(i).alert_id));
      g_debug.display(g_debug.format('alert name : $2',
                                     g_tbl_data_alert(i).alert_name));
      g_debug.display(g_debug.format('alert desc : $3',
                                     g_tbl_data_alert(i).alert_desc));
      g_debug.display(g_debug.format('alert value : $4',
                                     g_tbl_data_alert(i).alert_value));
      g_debug.display(g_debug.format('alert type : $5',
                                     g_tbl_data_alert(i).alert_type));
    END LOOP;
    g_debug.display('l_flag' || l_flag);
    CASE l_flag

      WHEN 1 THEN
        p_status_out := vmscms.gpp_const.c_mandatory_status;
        --g_err_mandatory.raise(g_api_name, vmscms.gpp_const.c_mandatory_errcode, vmscms.gpp_const.c_mandatory_errmsg);
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
                                                     NULL, --Remarks
                                                     l_timetaken);
        RETURN;
      WHEN 2 THEN
        g_debug.display('l_flag test' || l_flag);
        p_status_out := vmscms.gpp_const.c_inv_alert_type_status;
        --g_err_invalid_data.raise(l_api_name, vmscms.gpp_const.c_inv_alert_type_errcode, vmscms.gpp_const.c_inv_alert_type_errmsg);
        g_err_invalid_data.raise(l_api_name,
                                 ',0012,',
                                 'Invalid Alert Type');
        p_err_msg_out := g_err_invalid_data.get_current_error;
        vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                     p_customer_id_in,
                                                     l_hash_pan,
                                                     l_encr_pan,
                                                     'F', --vmscms.gpp_const.c_failure_flag,
                                                     p_err_msg_out,
                                                     vmscms.gpp_const.c_failure_res_id,
                                                     NULL, --Remarks
                                                     l_timetaken);
        RETURN;
      ELSE
        NULL; --nothing to be handled for flag = 0
    END CASE;

    g_debug.display('calling get customer alerts');
    get_customer_alerts(p_customer_id_in,
                        g_tbl_customer_alert,
                        l_api_name,
                        l_hash_pan,
                        l_encr_pan,
                        l_prod_code,
                        l_card_type,
                        l_acct_no,
                        p_status_out,
                        p_err_msg_out);

    g_debug.display('customer alerts details');
    /*FOR i IN g_tbl_customer_alert.first .. g_tbl_customer_alert.last
    LOOP
       g_debug.display(g_debug.format('alert id : $1',
                                      g_tbl_customer_alert(i).alert_id));
       g_debug.display(g_debug.format('alert name : $2',
                                      g_tbl_customer_alert(i).alert_name));
       g_debug.display(g_debug.format('alert desc : $3',
                                      g_tbl_customer_alert(i).alert_desc));
       g_debug.display(g_debug.format('alert value : $4',
                                      g_tbl_customer_alert(i).alert_value));
       g_debug.display(g_debug.format('alert type : $5',
                                      g_tbl_customer_alert(i).alert_type));
    END LOOP;*/

    g_debug.display('calling update customer alerts');
    update_customer_alerts(g_tbl_customer_alert,
                           g_tbl_data_alert,
                           g_tbl_update_data,
                           l_api_name,
                           p_status_out,
                           p_err_msg_out);
    g_debug.display('after call to update customer alerts');

    /* IF g_tbl_update_data.count > 0
    THEN
       FOR i IN g_tbl_update_data.first .. g_tbl_update_data.last
       LOOP
          g_debug.display(g_debug.format('alert id : $1',
                                         g_tbl_update_data(i).alert_id));
          g_debug.display(g_debug.format('alert name : $2',
                                         g_tbl_update_data(i).alert_name));
          g_debug.display(g_debug.format('alert desc : $3',
                                         g_tbl_update_data(i).alert_desc));
          g_debug.display(g_debug.format('alert value : $4',
                                         g_tbl_update_data(i).alert_value));
          g_debug.display(g_debug.format('alert type : $5',
                                         g_tbl_update_data(i).alert_type));
       END LOOP;
    END IF;*/

    --Fetching the active PAN for the input customer id
    --      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
    --                                     l_hash_pan,
    --                                     l_encr_pan);
    g_debug.display('after getting pan details' || l_hash_pan);
    l_date      := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-date'),
                          6,
                          11);
    l_timestamp := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                      'x-incfs-date'),
                          18,
                          8);
    --l_timestamp := '08:49:37';
    l_timestamp := REPLACE(l_timestamp,
                           ':',
                           '');

    l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);

    SELECT cbp_param_value
      INTO l_curr_code
      FROM vmscms.cms_prod_cattype, vmscms.cms_bin_param
     WHERE cpc_inst_code = cbp_inst_code
       AND cpc_profile_code = cbp_profile_code
       AND cpc_prod_code = l_prod_code
       AND cpc_card_type = l_card_type
       AND cpc_inst_code = 1
       AND cbp_param_name = 'Currency';

    g_debug.display('l_curr_code' || l_curr_code);
    FOR idx IN g_tbl_update_data.first .. g_tbl_update_data.last
    LOOP

      l_alert_type := upper(g_tbl_update_data(idx).alert_type);
      CASE upper(g_tbl_update_data(idx).alert_name)
        WHEN 'RELOAD ALERT' THEN
          CASE l_alert_type
            WHEN 'OFF' THEN
              l_loadorcreditalert := '0';
            WHEN 'MOBILE' THEN
              l_loadorcreditalert := '1';
            WHEN 'EMAIL' THEN
              l_loadorcreditalert := '2';
            WHEN 'BOTH' THEN
              l_loadorcreditalert := '3';
            ELSE
              l_flag := 3;
          END CASE;
        WHEN 'LOW BALANCE ALERT' THEN
          l_lowbalalert_value := g_tbl_update_data(idx).alert_value;
          g_debug.display('l_lowbalalert_value' || l_lowbalalert_value);
          CASE l_alert_type
            WHEN 'OFF' THEN
              l_lowbalalert := '0';
            WHEN 'MOBILE' THEN
              l_lowbalalert := '1';
            WHEN 'EMAIL' THEN
              l_lowbalalert := '2';
            WHEN 'BOTH' THEN
              l_lowbalalert := '3';
            ELSE
              l_flag := 3;
          END CASE;
          g_debug.display('l_flag' || l_flag);
        WHEN 'NEGATIVE BALANCE ALERT' THEN
          CASE l_alert_type
            WHEN 'OFF' THEN
              l_negativebalalert := '0';
            WHEN 'MOBILE' THEN
              l_negativebalalert := '1';
            WHEN 'EMAIL' THEN
              l_negativebalalert := '2';
            WHEN 'BOTH' THEN
              l_negativebalalert := '3';
            ELSE
              l_flag := 3;
          END CASE;
        WHEN 'HIGH AUTHORIZATION ALERT' THEN
          l_highauthamtalert_value := g_tbl_update_data(idx).alert_value;
          CASE l_alert_type
            WHEN 'OFF' THEN
              l_highauthamtalert := '0';
            WHEN 'MOBILE' THEN
              l_highauthamtalert := '1';
            WHEN 'EMAIL' THEN
              l_highauthamtalert := '2';
            WHEN 'BOTH' THEN
              l_highauthamtalert := '3';
            ELSE
              l_flag := 3;
          END CASE;
        WHEN 'DAILY BALANCE ALERT' THEN
          CASE l_alert_type
            WHEN 'OFF' THEN
              l_dailybalalert := '0';
            WHEN 'MOBILE' THEN
              l_dailybalalert := '1';
            WHEN 'EMAIL' THEN
              l_dailybalalert := '2';
            WHEN 'BOTH' THEN
              l_dailybalalert := '3';
            ELSE
              l_flag := 3;
          END CASE;
        WHEN 'INSUFFICIENT FUND ALERT' THEN
          CASE l_alert_type
            WHEN 'OFF' THEN
              l_insufficientalert := '0';
            WHEN 'MOBILE' THEN
              l_insufficientalert := '1';
            WHEN 'EMAIL' THEN
              l_insufficientalert := '2';
            WHEN 'BOTH' THEN
              l_insufficientalert := '3';
            ELSE
              l_flag := 3;
          END CASE;
        WHEN 'INCORRECT PIN ALERT' THEN
          CASE l_alert_type
            WHEN 'OFF' THEN
              l_incorrectpinalert := '0';
            WHEN 'MOBILE' THEN
              l_incorrectpinalert := '1';
            WHEN 'EMAIL' THEN
              l_incorrectpinalert := '2';
            WHEN 'BOTH' THEN
              l_incorrectpinalert := '3';
            ELSE
              l_flag := 3;
          END CASE;
        WHEN 'FAST50 LOAD CREDIT ALERT' THEN
          CASE l_alert_type
            WHEN 'OFF' THEN
              l_fast50alert := '0';
            WHEN 'MOBILE' THEN
              l_fast50alert := '1';
            WHEN 'EMAIL' THEN
              l_fast50alert := '2';
            WHEN 'BOTH' THEN
              l_fast50alert := '3';
            ELSE
              l_flag := 3;
          END CASE;
        WHEN 'FEDERAL/STATE TAX REFUND ALERT' THEN
          CASE l_alert_type
            WHEN 'OFF' THEN
              l_federalstatealert := '0';
            WHEN 'MOBILE' THEN
              l_federalstatealert := '1';
            WHEN 'EMAIL' THEN
              l_federalstatealert := '2';
            WHEN 'BOTH' THEN
              l_federalstatealert := '3';
            ELSE
              l_flag := 3;
          END CASE;
        ELSE
          p_status_out := vmscms.gpp_const.c_inv_alert_name_status;
          g_err_invalid_data.raise(l_api_name,
                                   ',0012,',
                                   'Invalid Alert Name');
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
      END CASE;
    END LOOP;
    g_debug.display('Invalid Alert Type' || l_flag);
    IF l_flag = 3
    THEN
      --g_debug.display('Invalid Alert Type' || l_flag);
      p_status_out := vmscms.gpp_const.c_inv_alert_type_status;
      --g_err_invalid_data.raise(l_api_name, vmscms.gpp_const.c_inv_alert_type_errcode, vmscms.gpp_const.c_inv_alert_type_errmsg);
      g_err_invalid_data.raise(l_api_name,
                               ',0012,',
                               'Invalid Alert Type');
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

    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||   --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
    g_debug.display('Calling base stored procedure' || l_flag);
    vmscms.sp_csr_smsandemail_alert('1',
                                    l_rrn,
                                    NULL,
                                    NULL,
                                    to_char(to_date(l_date,
                                                    'dd-mm-yyyy'),
                                            'yyyymmdd'), --date
                                    l_timestamp,
                                    l_plain_pan,
                                    l_curr_code,
                                    '0200',
                                    '28',
                                    '0',
                                    '03',
                                    '000',
                                    '0',
                                    p_phone_no_in,
                                    NULL,
                                    p_email_in,
                                    NULL,
                                    l_loadorcreditalert,
                                    l_lowbalalert,
                                    l_lowbalalert_value,
                                    l_negativebalalert,
                                    l_highauthamtalert,
                                    l_highauthamtalert_value,
                                    l_dailybalalert,
                                    NULL,
                                    NULL,
                                    l_insufficientalert,
                                    l_incorrectpinalert,
                                    l_fast50alert,
                                    l_federalstatealert,
                                    (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                 'x-incfs-ip')),
                                    NULL,
                                    (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                 'x-incfs-sessionid')),
                                    p_comment_in,
                                    '1',
                                    l_resp_code,
                                    l_resp_msg,
									                  p_optinflag_out);

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

    IF l_resp_code = '00'
    THEN
      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';
    ELSE
      p_status_out  := l_resp_code;
      p_err_msg_out := l_resp_msg;
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
      p_status_out := vmscms.gpp_const.c_update_alerts_status;
      g_err_unknown.raise(l_api_name || ' FAILED',
                          vmscms.gpp_const.c_update_alerts_status);
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
  END update_alerts;

  PROCEDURE test_get_alerts(p_customer_id_in IN VARCHAR2) IS
    l_status        VARCHAR2(100);
    l_err_msg       VARCHAR2(100);
    l_email         VARCHAR2(100);
    l_phone_no      VARCHAR2(100);
    l_mobile_status VARCHAR2(100);
    l_c_alerts      SYS_REFCURSOR;
    -- cursor elements
    l_alert_id     VARCHAR2(20);
    l_alert_name   VARCHAR(100);
    l_alert_descr  VARCHAR2(500);
    l_alert_value  VARCHAR2(100);
    l_alert_type   VARCHAR2(100);
    l_count        PLS_INTEGER;
    l_context_list fsfw.fslist_t := fsfw.fslist_t();

  BEGIN
    -- set context first

    l_context_list.extend;
    l_context_list(1) := 'x-incfs-partnerid,1';
    fsfw.fscontext.set_context(l_context_list);
    -- now call get_alerts
    get_alerts(p_customer_id_in,
               l_status,
               l_err_msg,
               l_email,
               l_phone_no,
               l_mobile_status,
               l_c_alerts);

    g_debug.display('l_status -> ' || l_status);
    g_debug.display('l_err_msg -> ' || l_err_msg);
    g_debug.display('l_email -> ' || l_email);
    g_debug.display('l_phone_no -> ' || l_phone_no);
    g_debug.display('l_mobile_status -> ' || l_mobile_status);

    -- now walk the cursor
    l_count := 1;

    LOOP
      FETCH l_c_alerts
        INTO l_alert_id,
             l_alert_name,
             l_alert_descr,
             l_alert_value,
             l_alert_type;
      IF l_c_alerts%NOTFOUND
      THEN
        EXIT;
      END IF;
      g_debug.display('Loop count : ' || to_char(l_count));
      g_debug.display('   l_alert_id -> ' || l_alert_id);
      g_debug.display('   l_alert_name -> ' || l_alert_name);
      g_debug.display('   l_alert_descr -> ' || l_alert_descr);
      g_debug.display('   l_alert_value -> ' || l_alert_value);
      g_debug.display('   l_alert_type -> ' || l_alert_type);
      g_debug.display('-----------------------------------------');
    END LOOP;

    CLOSE l_c_alerts;

  END test_get_alerts;

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
                                         'Invalid Data: $1 $2 $3');
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

    -- initializations for get_alerts

    -- alert names

    g_alert_name(9) := 'Reload Alert';           ------ VMS-2809 - Decouple initial load alerts from Reload.
    g_alert_name(10) := 'Low Balance Alert';
    g_alert_name(11) := 'Negative Balance Alert';
    g_alert_name(12) := 'Daily Balance Alert';
    g_alert_name(13) := 'Incorrect PIN Alert';
    g_alert_name(16) := 'High Authorization Alert';
    g_alert_name(17) := 'Insufficient Fund Alert';
    g_alert_name(21) := 'Fast50 Load Credit Alert';
    g_alert_name(22) := 'Federal/State Tax Refund Alert';

    -- alert descriptions

    g_alert_descr(9) := 'Whenever the available balance increases, the  customer will receive an alert message';
    g_alert_descr(10) := 'If the available balance is less than or equal to Low Balance Amount, the customer will receive an alert message';
    g_alert_descr(11) := 'Once the balance goes negative, the system will send alerts whenever the customer performs any transaction and the available balance is less than zero';
    g_alert_descr(12) := 'This alert provides the daily balance to the customer';
    g_alert_descr(13) := 'This alert is sent every time an invalid PIN is entered';
    g_alert_descr(16) := 'This alert is sent when the authorization amount of a transaction exceeds the customer-provided limit';
    g_alert_descr(17) := 'This alert will be sent when the available balance is insufficient for a transaction';
    g_alert_descr(21) := 'This alert is sent when a Fast50 transaction is received';
    g_alert_descr(22) := 'This alert is sent when a Tax Refund transaction is received';

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
END gpp_alerts;
/
show error