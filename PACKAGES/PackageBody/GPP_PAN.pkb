CREATE OR REPLACE PACKAGE BODY "VMSCMS"."GPP_PAN" IS

  -- PL/SQL Package using FS Framework
  -- Author  : Sindhu Selvam
  -- Created : 9/22/2015 10:49:15 AM

  -- Private type declarations
  -- TEST 1

  -- Private constant declarations

  -- Private variable declarations

  -- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;

  --declare all FS errors here
  g_err_unknown fsfw.fserror_t;

  -- Function and procedure implementations
  -- To get the PAN details
  --status: 0 - success, Non Zero value - failure
  PROCEDURE get_pan_details(p_customer_id_in IN VARCHAR2,
                            p_hash_pan_out   OUT VARCHAR2,
                            p_encr_pan_out   OUT VARCHAR2) AS
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
  BEGIN
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));

    --- l_partner_id := 1; --FOR testing
    --Fetching the active PAN for the input customer id
    BEGIN
      SELECT cap_pan_code, cap_pan_code_encr
        INTO p_hash_pan_out, p_encr_pan_out
        FROM (SELECT cap_pan_code, cap_pan_code_encr
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
                 AND cap_inst_code = 1
                 AND cap_active_date IS NOT NULL
                 AND cap_card_stat NOT IN ('9')
               ORDER BY cap_active_date DESC)
       WHERE rownum = 1;
    EXCEPTION
      WHEN no_data_found THEN
        SELECT cap_pan_code, cap_pan_code_encr
          INTO p_hash_pan_out, p_encr_pan_out
          FROM (SELECT cap_pan_code, cap_pan_code_encr
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
         WHERE rownum = 1;
    END;
  EXCEPTION
    WHEN OTHERS THEN
      p_hash_pan_out := NULL;
      p_encr_pan_out := NULL;

  END get_pan_details;

  -- To get the PAN and account details
  --status: 0 - success, Non Zero value - failure
  PROCEDURE get_pan_details(p_customer_id_in IN VARCHAR2,
                            p_hash_pan_out   OUT VARCHAR2,
                            p_encr_pan_out   OUT VARCHAR2,
                            p_acct_no_out    OUT VARCHAR2) AS
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
  BEGIN
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));

    --l_partner_id := 1; --FOR testing
    --Fetching the active PAN for the input customer id
    BEGIN
      SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no
        INTO p_hash_pan_out, p_encr_pan_out, p_acct_no_out
        FROM (SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no
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
                 AND cap_inst_code = 1
                 AND cap_active_date IS NOT NULL
                 AND cap_card_stat NOT IN ('9')
               ORDER BY cap_active_date DESC)
       WHERE rownum = 1;
    EXCEPTION
      WHEN no_data_found THEN
        SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no
          INTO p_hash_pan_out, p_encr_pan_out, p_acct_no_out
          FROM (SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no
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
         WHERE rownum = 1;
    END;
  EXCEPTION
    WHEN OTHERS THEN
      p_hash_pan_out := NULL;
      p_encr_pan_out := NULL;
      p_acct_no_out  := NULL;
  END get_pan_details;

  PROCEDURE get_pan_details(p_customer_id_in IN VARCHAR2,
                            p_hash_pan_out   OUT VARCHAR2,
                            p_encr_pan_out   OUT VARCHAR2,
                            p_cust_code_out  OUT VARCHAR2,
                            p_prod_code_out  OUT VARCHAR2,
                            p_catg_code_out  OUT VARCHAR2,
                            p_proxy_out      OUT VARCHAR2,
                            p_card_stat_out  OUT VARCHAR2,
                            p_acct_no_out    OUT VARCHAR2,
                            p_mask_pan_out   OUT VARCHAR2,
                            p_prfl_code_out  OUT VARCHAR2) AS
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
  BEGIN
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));

    -- l_partner_id := 1; --FOR testing
    --Fetching the active PAN for the input customer id
    BEGIN
      SELECT cap_pan_code,
             cap_pan_code_encr,
             cap_cust_code,
             cap_prod_code,
             cap_card_type,
             cap_proxy_number,
             cap_card_stat,
             cap_acct_no,
             cap_mask_pan,
             cap_prfl_code
        INTO p_hash_pan_out,
             p_encr_pan_out,
             p_cust_code_out,
             p_prod_code_out,
             p_catg_code_out,
             p_proxy_out,
             p_card_stat_out,
             p_acct_no_out,
             p_mask_pan_out,
             p_prfl_code_out
        FROM (SELECT cap_pan_code,
                     cap_pan_code_encr,
                     cap_cust_code,
                     cap_prod_code,
                     cap_card_type,
                     cap_proxy_number,
                     cap_card_stat,
                     cap_acct_no,
                      vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan,
                     cap_prfl_code
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
                 AND cap_inst_code = 1
                 AND cap_active_date IS NOT NULL
                 AND cap_card_stat NOT IN ('9')
               ORDER BY cap_active_date DESC)
       WHERE rownum = 1;
    EXCEPTION
      WHEN no_data_found THEN
        SELECT cap_pan_code,
               cap_pan_code_encr,
               cap_cust_code,
               cap_prod_code,
               cap_card_type,
               cap_proxy_number,
               cap_card_stat,
               cap_acct_no,
               cap_prfl_code
          INTO p_hash_pan_out,
               p_encr_pan_out,
               p_cust_code_out,
               p_prod_code_out,
               p_catg_code_out,
               p_proxy_out,
               p_card_stat_out,
               p_acct_no_out,
               p_prfl_code_out
          FROM (SELECT cap_pan_code,
                       cap_pan_code_encr,
                       cap_cust_code,
                       cap_prod_code,
                       cap_card_type,
                       cap_proxy_number,
                       cap_card_stat,
                       cap_acct_no,
                       cap_prfl_code
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
         WHERE rownum = 1;
    END;
  EXCEPTION
    WHEN OTHERS THEN
      p_hash_pan_out := NULL;
      p_encr_pan_out := NULL;

  END get_pan_details;

  -- the init procedure is private and should ALWAYS exist
  PROCEDURE init IS
  BEGIN
    -- initialize all errors here
    g_err_unknown := fsfw.fserror_t('E-UNKNOWN',
                                    'Unknown error: $1 $2',
                                    'NOTIFY');
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

BEGIN
  -- Initialization
  init;
END gpp_pan;
