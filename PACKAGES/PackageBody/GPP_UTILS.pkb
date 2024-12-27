create or replace PACKAGE BODY  vmscms.GPP_UTILS IS

  -- PL/SQL Package using FS Framework
  -- Author  : Rojalin
  -- Created : 9/25/2015 11:25:59 AM

  -- Private type declarations
  -- TEST 1

  -- Private constant declarations

  -- Private variable declarations

  -- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;

  --declare all FS errors here
  g_err_nodata    fsfw.fserror_t;
  g_err_unknown   fsfw.fserror_t;
  g_err_mandatory fsfw.fserror_t;
  g_err_failure   fsfw.fserror_t;

  -- Function and procedure implementations
  --Get Response Code
  PROCEDURE get_response_code(c_response_code_out OUT SYS_REFCURSOR,
                              p_status_out        OUT VARCHAR2,
                              p_err_msg_out       OUT VARCHAR2) AS
    l_api_name   VARCHAR2(20) := 'GET RESPONSE CODE';
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;

/**************************************************************************************************
     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 06-AUG-2019
     * Purpose          : VMS-1039(Manual adjustment enhancement for debit/credit reason codes to flag for "not used")
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R19

	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0002
****************************************************************************************************/
  BEGIN
    l_start_time := dbms_utility.get_time;
    OPEN c_response_code_out FOR
      SELECT 1 actionid,
             'Adjust Balance' actiondescription,
             csr_spprt_rsncode reasoncode,
             csr_reasondesc reasondescription,
             DECODE(UPPER(csr_reason_ind),'CR','CREDIT','DR','DEBIT') crdr
        FROM cms_spprt_reasons
       WHERE csr_inst_code = 1
         AND csr_spprt_key = 'MANADJDRCR'
         AND csr_status_flag = 'E'
      UNION ALL
      SELECT 2 actionid,
             'Profile Update' actiondescription,
             csr_spprt_rsncode reasoncode,
             csr_reasondesc reasondescription,
             DECODE(UPPER(csr_reason_ind),'CR','CREDIT','DR','DEBIT') crdr
        FROM cms_spprt_reasons
       WHERE csr_inst_code = 1
         AND csr_spprt_key = 'PROFILE'
         AND csr_status_flag = 'E'
      UNION ALL
      SELECT 3 actionid,
             'Reverse Fee' actiondescription,
             67 reasoncode,
             'Incorrect Fee' reasondescription,
             'CREDIT' crdr
        FROM dual
      UNION ALL
      SELECT 3 actionid,
             'Reverse Fee' actiondescription,
             68 reasoncode,
             'Courtesy Reversal' reasondescription,
             'CREDIT' crdr
        FROM dual
      UNION ALL
      SELECT 4 actionid,
             'Release Preauth' actiondescription,
             69 reasoncode,
             'Duplicate Auth' reasondescription,
             '' crdr
        FROM dual
      UNION ALL
      SELECT 4 actionid,
             'Release Preauth' actiondescription,
             70 reasoncode,
             'Void Do Not Proceed' reasondescription,
             '' crdr
        FROM dual
      UNION ALL
      SELECT 4 actionid,
             'Release Preauth' actiondescription,
             71 reasoncode,
             'Merchant Error' reasondescription,
             '' crdr
        FROM dual
      UNION ALL
      SELECT 5 action_id,
             'Raise Dispute' action_description,
             csr_spprt_rsncode reason_code,
             csr_reasondesc reason_description,
             DECODE(UPPER(csr_reason_ind),'CR','CREDIT','DR','DEBIT') crdr
        FROM cms_spprt_reasons
       WHERE csr_inst_code = 1
         AND csr_spprt_key = 'DISPUTE'
         AND csr_status_flag = 'E';

    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;
   /* vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 NULL, --customer id
                                                 NULL, --hash pan
                                                 NULL, --encrypted pan
                                                 'C', --vmscms.gpp_const.c_success_flag,
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
                                                   NULL,
                                                   NULL,
                                                   NULL,
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
                                                   NULL, --customer id
                                                   NULL, --hash pan
                                                   NULL, --encrypted pan
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

  END get_response_code;

  --Get Transaction Code
  PROCEDURE get_transaction_code(p_delv_chnl_in  IN VARCHAR2,
                                 c_tran_code_out OUT SYS_REFCURSOR,
                                 p_status_out    OUT VARCHAR2,
                                 p_err_msg_out   OUT VARCHAR2) AS
    l_api_name   VARCHAR2(20) := 'GET TRANSACTION CODE';
    l_field_name VARCHAR2(50);
    l_flag       PLS_INTEGER := 0;
    l_tran_code  vmscms.cms_transaction_mast.ctm_tran_code%TYPE;
    l_tran_desc  vmscms.cms_transaction_mast.ctm_tran_desc%TYPE;
    l_delv_chnl  VARCHAR2(10) := nvl(p_delv_chnl_in,
                                     '03');
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
    --check mandatory parameter
    IF p_delv_chnl_in IS NULL
    THEN
      l_field_name := 'DELIVERY CHANNEL';
      l_flag       := 1;
    END IF;

    IF l_flag = 1
    THEN
      p_status_out := vmscms.gpp_const.c_mandatory_status;
      g_err_mandatory.raise(l_api_name,
                            ',0002,',
                            l_field_name || ' is mandatory');
      p_err_msg_out := g_err_mandatory.get_current_error;

      RETURN;
    END IF;

    OPEN c_tran_code_out FOR
      SELECT ctm_tran_code, ctm_tran_desc
        INTO l_tran_code, l_tran_desc
        FROM vmscms.cms_transaction_mast
       WHERE ctm_delivery_channel = l_delv_chnl;

    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');
    p_status_out := vmscms.gpp_const.c_success_status;
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,     ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 NULL, --customer id
                                                 NULL, --hash pan
                                                 NULL, --encrypted pan
                                                 'C', --vmscms.gpp_const.c_success_flag,
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
                                                   NULL,
                                                   NULL,
                                                   NULL,
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
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

  END get_transaction_code;

  PROCEDURE get_datetime_rrn(p_date_out OUT VARCHAR2,
                             p_time_out OUT VARCHAR2,
                             p_rrn_out  OUT VARCHAR2) AS
    l_date VARCHAR2(50);
    l_time VARCHAR2(50);

  BEGIN
    --getting the date
    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);
    ---  l_date := substr('Sun, 22 May 1987 08:49:37 GMT', 6, 11);
    SELECT to_char(to_date(l_date,
                           'dd-mm-yyyy'),
                   'yyyymmdd')
      INTO p_date_out
      FROM dual;
    l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-date')),
                     18,
                     8);
    --- l_time := '20:20:20';
    SELECT REPLACE(l_time,
                   ':',
                   '')
      INTO p_time_out
      FROM dual;
    g_debug.display('l_date' || l_date);
    g_debug.display('l_time' || l_time);

    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO p_rrn_out
      FROM dual;
    g_debug.display('p_rrn_out' || p_rrn_out);
  EXCEPTION
    WHEN OTHERS THEN
      p_date_out := NULL;
      p_time_out := NULL;
  END get_datetime_rrn;

  --Get State and Country Codes
  PROCEDURE get_country_state_codes(c_country_code_out OUT SYS_REFCURSOR,
                                    c_state_code_out   OUT SYS_REFCURSOR,
                                    p_status_out       OUT VARCHAR2,
                                    p_err_msg_out      OUT VARCHAR2) AS
    l_api_name   VARCHAR2(25) := 'GET COUNTRY STATE CODES';
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
    OPEN c_country_code_out FOR
      SELECT gcm_cntry_code        AS ctry_num_code,
             gcm_switch_cntry_code AS ctry_alpha_code,
             gcm_cntry_name        AS ctry_name
        FROM gen_cntry_mast
       WHERE gcm_inst_code = 1;

    OPEN c_state_code_out FOR
      SELECT gcm_cntry_code        AS ctry_num_code,
             gcm_switch_cntry_code AS ctry_alpha_code,
             gcm_cntry_name        AS ctry_name,
             gsm_state_code        AS state_num_code,
             gsm_switch_state_code AS state_alpha_code,
             gsm_state_name        AS state_name
        FROM gen_cntry_mast, gen_state_mast
       WHERE gcm_cntry_code = gsm_cntry_code
         AND gcm_inst_code = gsm_inst_code
         AND gcm_inst_code = 1
       ORDER BY ctry_num_code, state_num_code;

    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 NULL, --customer id
                                                 NULL, --hash pan
                                                 NULL, --encrypted pan
                                                 'C', --vmscms.gpp_const.c_success_flag,
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
                                                   NULL,
                                                   NULL,
                                                   NULL,
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
                                                   NULL, --customer id
                                                   NULL, --hash pan
                                                   NULL, --encrypted pan
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

  END get_country_state_codes;


  -- the init procedure is private and should ALWAYS exist
  PROCEDURE init IS
  BEGIN
    -- initialize all errors here
    g_err_nodata    := fsfw.fserror_t('E-NO-DATA',
                                      '$1 $2');
    g_err_unknown   := fsfw.fserror_t('E-UNKNOWN',
                                      'Unknown error: $1 $2',
                                      'NOTIFY');
    g_err_mandatory := fsfw.fserror_t('E-MANDATORY',
                                      'Mandatory Field is NULL: $1 $2 $3',
                                      'NOTIFY');
    g_err_failure   := fsfw.fserror_t('E-FAILURE',
                                      'Procedure failed: $1 $2 $3',
                                      'NOLOG');

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

  -- Below function will validate whether given customer is having same inst code
  -- as passed one.
  FUNCTION validate_cust_partner(p_ccm_cust_id_in    cms_cust_mast.ccm_cust_id%TYPE,
                                 p_ccm_partner_id_in cms_cust_mast.ccm_partner_id%TYPE)
    RETURN VARCHAR2 AS

    l_result    VARCHAR2(1);
    l_count     NUMBER(1);
    l_inst_code cms_cust_mast.ccm_inst_code%TYPE;

  BEGIN

    l_inst_code := 1;

    SELECT 1
      INTO l_count
      FROM cms_cust_mast
     WHERE ccm_cust_id = p_ccm_cust_id_in
       AND ccm_partner_id = p_ccm_partner_id_in
       AND ccm_inst_code = l_inst_code;

    IF l_count = 1
    THEN
      l_result := 'Y';
    ELSE
      l_result := 'N';
    END IF;

    RETURN l_result;
  EXCEPTION
    WHEN OTHERS THEN
      g_debug.display(dbms_utility.format_error_backtrace || ' ' ||
                      dbms_utility.format_error_stack);
      l_result := 'N';
      RETURN l_result;

  END validate_cust_partner;

  FUNCTION get_prod_code_card_type(p_partner_id_in IN vmscms.vms_groupid_partnerid_map.vgp_partner_id%type,
                                   p_prod_code_in  IN vmscms.cms_cust_mast.ccm_prod_code%TYPE,
                                   p_card_type_in  IN vmscms.cms_cust_mast.ccm_card_type%type)
    RETURN VARCHAR2 IS
    l_api_name   VARCHAR2(25) := 'GET_PROD_CODE_CARD_TYPE';
    l_details VARCHAR2(500);
  BEGIN

    SELECT nvl(x.vpg_prod_code,'^') || nvl(to_char(x.vpg_card_type),'~')
      INTO l_details
      FROM vmscms.vms_prod_groupaccess_map x, vmscms.vms_groupid_partnerid_map y
     WHERE x.vpg_prod_group_name = y.vgp_group_access_name
       AND y.vgp_partner_id = p_partner_id_in
       AND x.vpg_prod_code = p_prod_code_in
       AND x.vpg_card_type = p_card_type_in;
    RETURN l_details;
    /*
    EXISTS
         (SELECT 1
      FROM vms_prod_groupaccess_map x, vms_groupid_partnerid_map y
     WHERE x.vpg_prod_group_name = y.vgp_group_access_name
       AND y.vgp_group_access_name = :partner_id
       AND nvl(b.ccm_prod_code,
               '~') = nvl(x.vpg_prod_code,
                          '^')
       AND nvl(to_char(b.ccm_card_type),
               '^') = nvl(to_char(x.vpg_card_type),
                          '~'))
    */
  EXCEPTION
    WHEN OTHERS THEN
      g_err_failure.raise;
      RETURN 'NULL';
  END get_prod_code_card_type;

  PROCEDURE get_occupation_details(c_occupation_detail_out OUT SYS_REFCURSOR,
                                    p_status_out           OUT VARCHAR2,
                                    p_err_msg_out          OUT VARCHAR2) AS
    l_api_name   VARCHAR2(25) := 'GET OCCUPATION DETAILS';
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;
    l_occupation        vms_occupation_mast.vom_occu_name%TYPE;
    l_occupation_code   vms_occupation_mast.vom_occu_code%TYPE;
    
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

    OPEN c_occupation_detail_out FOR
      SELECT vom_occu_code code,
             vom_occu_name description
        FROM vmscms.vms_occupation_mast;

    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,     ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 NULL, --customer id
                                                 NULL, --hash pan
                                                 NULL, --encrypted pan
                                                 'C', --vmscms.gpp_const.c_success_flag,
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
                                                   NULL,
                                                   NULL,
                                                   NULL,
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
                                                   NULL, --customer id
                                                   NULL, --hash pan
                                                   NULL, --encrypted pan
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

   END get_occupation_details;

   PROCEDURE get_identification_types(c_id_types_out OUT SYS_REFCURSOR,
                                      p_status_out            OUT VARCHAR2,
                                      p_err_msg_out           OUT VARCHAR2) AS

    l_api_name   VARCHAR2(25) := 'GET IDENTIFICATION TYPES';
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

    OPEN c_id_types_out FOR
      SELECT cim_idtype_code type,
             cim_idtype_desc description,
             decode(cim_idtype_flag, 'U', 'US','C','CA') country
        FROM vmscms.cms_idtype_mast;

    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                 NULL, --customer id
                                                 NULL, --hash pan
                                                 NULL, --encrypted pan
                                                 'C', --vmscms.gpp_const.c_success_flag,
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
                                                   NULL,
                                                   NULL,
                                                   NULL,
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
                                                   NULL, --customer id
                                                   NULL, --hash pan
                                                   NULL, --encrypted pan
                                                   'F', --vmscms.gpp_const.c_failure_flag,
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);

   END get_identification_types;
BEGIN
  -- Initialization
  init;
END gpp_utils;
/
show error