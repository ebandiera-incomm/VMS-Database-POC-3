CREATE OR REPLACE PACKAGE BODY "VMSCMS"."GPP_ACCOUNT_TRANSFER" IS

  -- PL/SQL Package using FS Framework
  -- Author  : Aparna Sakhalkar
  -- Created : 1/16/2017 8:50:34 PM

  -- Private type declarations

  -- Private constant declarations
  c_inst_code CONSTANT VARCHAR2(2) := '1';

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

  FUNCTION get_account_number(p_account_type_in VARCHAR2,
                              p_cust_code_in    VARCHAR2)
    RETURN cms_acct_mast.cam_acct_no%TYPE IS
    l_acct_no vmscms.cms_acct_mast.cam_acct_no%TYPE;
  BEGIN
    SELECT cam_acct_no
      INTO l_acct_no
      FROM vmscms.cms_acct_mast, vmscms.cms_cust_acct
     WHERE cam_type_code = p_account_type_in -- e.g.'1' -- Spending
       AND cca_acct_id = cam_acct_id
       AND cca_inst_code = cam_inst_code
       AND cca_inst_code = c_inst_code
       AND cca_cust_code = p_cust_code_in;
    RETURN l_acct_no;
  EXCEPTION
    WHEN no_data_found THEN
      g_err_nodata.raise(p_ctxt_value_1_in => 'CUSTOMER CODE',
                         p_ctxt_value_2_in => p_cust_code_in);
      RETURN NULL;
    WHEN OTHERS THEN
      g_err_failure.raise(p_ctxt_value_1_in => 'CUSTOMER CODE',
                          p_ctxt_value_2_in => p_cust_code_in);
      RETURN NULL;
  END get_account_number;

  FUNCTION get_currency_code(p_prod_code_in cms_prod_mast.cpm_prod_code%TYPE, p_card_type_in cms_prod_cattype.cpc_card_type%TYPE )
    RETURN VARCHAR2 IS
    l_currency_code vmscms.gen_curr_mast.gcm_curr_code%TYPE;
  BEGIN
    SELECT TRIM(cbp_param_value)
      INTO l_currency_code
      FROM cms_bin_param, cms_prod_cattype
     WHERE cbp_param_name = 'Currency'
       AND cbp_profile_code = cpc_profile_code
       AND cpc_prod_code = p_prod_code_in
	   AND cpc_card_type = p_card_type_in
       AND cpc_inst_code = c_inst_code;
    RETURN l_currency_code;
  EXCEPTION
    WHEN no_data_found THEN
      g_err_nodata.raise(p_ctxt_value_1_in => 'PRODUCT CODE',
                         p_ctxt_value_2_in => p_prod_code_in);
      RETURN NULL;
    WHEN OTHERS THEN
      g_err_failure.raise(p_ctxt_value_1_in => 'PRODUCT CODE',
                          p_ctxt_value_2_in => p_prod_code_in);
      RETURN NULL;
  END get_currency_code;

  FUNCTION get_rrn RETURN VARCHAR2 IS
    l_rrn_inner vmscms.transactionlog.rrn%TYPE;
  BEGIN
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||   --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn_inner
      FROM dual;
    RETURN l_rrn_inner;
  EXCEPTION
    WHEN OTHERS THEN
      g_err_failure.raise;
      RETURN NULL;
  END get_rrn;

  PROCEDURE get_savings_xfr_count(p_saving_acct_number_in IN cms_acct_mast.cam_acct_no%TYPE,
                                  p_hash_pan_in           IN cms_appl_pan.cap_pan_code%TYPE,
                                  p_availed_txns_out      OUT NUMBER,
                                  p_available_txns_out    OUT NUMBER,
                                  p_resp_code_out         OUT VARCHAR2,
                                  p_errmsg_out            OUT VARCHAR2) IS
    l_prod_code cms_dfg_param.cdp_prod_code%TYPE;
	l_card_type cms_dfg_param.cdp_card_type%TYPE;
    l_max_trans NUMBER;
    l_curr_step VARCHAR2(1000);
    exp_reject_record EXCEPTION;
  BEGIN
    l_curr_step := 'In get_savings_xfr_count - Get prod code';
    SELECT cap_prod_code, cap_card_type
      INTO l_prod_code, l_card_type
      FROM cms_appl_pan
     WHERE cap_pan_code = p_hash_pan_in
       AND cap_inst_code = c_inst_code;

    l_curr_step := 'In get_savings_xfr_count - Get MaxNoTrans';
    SELECT to_number(cdp_param_value)
      INTO l_max_trans
      FROM cms_dfg_param
     WHERE cdp_inst_code = c_inst_code
       AND cdp_prod_code = l_prod_code
	   AND cdp_card_type = l_card_type
       AND cdp_param_key IN ('MaxNoTrans');

    l_curr_step := 'In get_savings_xfr_count - Get current number of txns';
    BEGIN
      sp_savtospd_limit_check(c_inst_code,
                              '03',
                              '44',
                              p_hash_pan_in,
                              p_saving_acct_number_in,
                              '2',
                              NULL,
                              NULL,
                              p_resp_code_out,
                              p_errmsg_out,
                              p_availed_txns_out);

      IF p_resp_code_out <> '00'
         AND p_errmsg_out <> 'OK'
      THEN
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        p_resp_code_out := '21';
        p_errmsg_out    := 'Error from Saving account limit check' ||
                           substr(SQLERRM,
                                  1,
                                  200);
        RAISE exp_reject_record;
    END;

    l_curr_step          := 'In get_savings_xfr_count - Set p_available_txns_out';
    p_available_txns_out := l_max_trans - p_availed_txns_out;
  EXCEPTION
    WHEN OTHERS THEN
      p_resp_code_out := '21';
      p_errmsg_out    := l_curr_step || ' ' ||
                         substr(SQLERRM,
                                1,
                                200);
      RAISE;
  END get_savings_xfr_count;

  -- Function and procedure implementations
  -- To get the account details
  --status: 0 - success, Non Zero value - failure
  PROCEDURE account_transfer(p_customer_id_in              IN VARCHAR2,
                             p_from_account_type_in        IN VARCHAR2,
                             p_amount_in                   IN VARCHAR2,
                             p_close_flag_in               IN VARCHAR2,
                             p_comment_in                  IN VARCHAR2,
                             p_spending_ledger_balance     OUT VARCHAR2,
                             p_spending_available_balance  OUT VARCHAR2,
                             p_savings_ledger_balance      OUT VARCHAR2,
                             p_savings_completed_transfers OUT VARCHAR2,
                             p_savings_remaining_transfers OUT VARCHAR2,
                             p_status_out                  OUT VARCHAR2,
                             p_err_msg_out                 OUT VARCHAR2) AS
    l_api_name   VARCHAR2(20) := 'ACCOUNT TRANSFER';
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    l_plain_pan  vmscms.cms_appl_pan.cap_mask_pan%TYPE;

    l_saving_acct_no   vmscms.cms_acct_mast.cam_acct_no%TYPE;
    l_spending_acct_no vmscms.cms_acct_mast.cam_acct_no%TYPE;
    l_delivery_channel vmscms.transactionlog.delivery_channel%TYPE;
    l_txn_code         vmscms.transactionlog.txn_code%TYPE;
    l_rrn              vmscms.transactionlog.rrn%TYPE;
    l_txn_mode         vmscms.transactionlog.txn_mode%TYPE := '0';
    l_bank_code        vmscms.transactionlog.bank_code%TYPE := '1';
    l_currency_code    vmscms.gen_curr_mast.gcm_curr_code%TYPE;
    l_reversal_code    vmscms.transactionlog.reversal_code%TYPE := '0';
    l_ipaddress        vmscms.transactionlog.ipaddress%TYPE;
    l_date             VARCHAR2(11);
    l_time             VARCHAR2(10);
    l_mobile_number    vmscms.cms_transaction_log_dtl.ctd_mobile_number%TYPE;
    l_device_id        vmscms.cms_transaction_log_dtl.ctd_device_id%TYPE;
    l_amount           vmscms.cms_acct_mast.cam_acct_bal%type;

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
    
   v_Retperiod  date; --Added for VMS-5733/FSP-991
   v_Retdate  date; --Added for VMS-5733/FSP-991

  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 --'x-incfs-partnerid'
                                 vmscms.gpp_const.c_partnerid_context));

    --Fetching the active PAN and other details
    -- for the input customer id
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

    g_debug.display('p_customer_id_in' || p_customer_id_in);
    g_debug.display('l_cust_code' || l_cust_code);
    g_debug.display('l_partner_id' || l_partner_id);
    g_debug.display('l_acct_no' || l_acct_no);

    --Set up all the parameters for the VMS procedures

    -- Get Spending account number
    l_spending_acct_no := get_account_number('1',
                                             l_cust_code);
    -- Get Savings account number
    l_saving_acct_no := get_account_number('2',
                                           l_cust_code);
    -- Get rrn
    l_rrn := get_rrn;

    -- get currency code
    l_currency_code := get_currency_code(l_prod_code, l_card_type);

    -- Set the date and time values
    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);

    l_date := to_char(to_date(l_date,
                              'dd-mm-yyyy'),
                      'yyyymmdd');
    ---g_debug.display('l_date' || l_date);
    l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-date')),
                     18,
                     8);

    l_time := REPLACE(l_time,
                      ':',
                      '');
    -- set IP Address
    l_ipaddress := sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                               vmscms.gpp_const.c_ip_context);

    -- Get pan in clear text
    l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);

    l_delivery_channel := '03';

    l_txn_code := '44'; -- SavingstoSpendingTransfer

    -- Parameter set up complete.

    -- Check if the transfer is from savings to spending account
    IF p_from_account_type_in = 'SAVINGS'
    THEN
      -- temporary fix till VMS fix is available
      -- The close savings flag is true then
      -- get the full amount in the Savings account.
      -- This amount will be sent to the transfer procedure
      IF upper(p_close_flag_in) = 'TRUE'
      THEN
        select NVL(a.cam_acct_bal,0)
          into l_amount
          from vmscms.cms_acct_mast a
         where a.cam_inst_code = c_inst_code
           and a.cam_acct_no = l_saving_acct_no;
      ELSE
        l_amount := p_amount_in;
      END IF;

      -- Call VMS procedure to transfer from savings to spending.
      sp_savingstospendingtransfer(p_inst_code        => c_inst_code,
                                   p_pan_code         => l_plain_pan,
                                   p_msg              => p_comment_in,
                                   p_spd_acct_no      => l_spending_acct_no,
                                   p_svg_acct_no      => l_saving_acct_no,
                                   p_delivery_channel => l_delivery_channel,
                                   p_txn_code         => l_txn_code,
                                   p_rrn              => l_rrn,
                                   p_txn_amt          => to_char(l_amount),
                                   p_txn_mode         => l_txn_mode,
                                   p_bank_code        => l_bank_code,
                                   p_curr_code        => l_currency_code,
                                   p_rvsl_code        => l_reversal_code,
                                   p_tran_date        => l_date,
                                   p_tran_time        => l_time,
                                   p_ipaddress        => l_ipaddress,
                                   p_ani              => NULL,
                                   p_dni              => NULL,
                                   p_resp_code        => p_status_out,
                                   -- This will hold 'C'
                                   -- if the close saving account flag is true
                                   p_resmsg            => p_err_msg_out,
                                   p_spenacctbal       => p_spending_available_balance,
                                   p_spenacctledgbal   => p_spending_ledger_balance,
                                   p_availed_txn       => p_savings_completed_transfers,
                                   p_available_txn     => p_savings_remaining_transfers,
                                   p_svgacct_closrflag => p_close_flag_in);


      IF upper(p_close_flag_in) = 'TRUE'
      THEN
        BEGIN
         
        --Added for VMS-5733/FSP-991
        v_Retdate := TO_DATE(SUBSTR(TRIM(l_date), 1, 8), 'yyyymmdd');
        
        select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';

IF (v_Retdate>v_Retperiod)
    THEN
         -- Get mobile number and device id
          SELECT ctd_mobile_number, ctd_device_id
            INTO l_mobile_number, l_device_id
            FROM vmscms.cms_transaction_log_dtl
           WHERE ctd_rrn = l_rrn
             AND ctd_delivery_channel = l_delivery_channel
             AND ctd_txn_code = l_txn_code
             AND ctd_business_date = l_date
             AND ctd_business_time = l_time;
         ELSE
              SELECT ctd_mobile_number, ctd_device_id
            INTO l_mobile_number, l_device_id
            FROM VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST --Added for VMS-5733/FSP-991
           WHERE ctd_rrn = l_rrn
             AND ctd_delivery_channel = l_delivery_channel
             AND ctd_txn_code = l_txn_code
             AND ctd_business_date = l_date
             AND ctd_business_time = l_time;
         END IF;        
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;

        --get rrn
        l_rrn := get_rrn;

        -- Call SP_CLOSE_SAVINGS_ACCT to close the savings account
        sp_close_savings_acct(p_inst_code        => c_inst_code,
                              p_pan_code         => l_plain_pan,
                              p_svg_acct_no      => l_saving_acct_no,
                              p_delivery_channel => l_delivery_channel,
                              p_txn_code         => l_txn_code,
                              p_rrn              => l_rrn,
                              p_txn_mode         => l_txn_mode,
                              p_tran_date        => l_date,
                              p_tran_time        => l_time,
                              p_ani              => NULL,
                              p_dni              => NULL,
                              p_ipaddress        => l_ipaddress,
                              p_bank_code        => l_bank_code,
                              p_curr_code        => l_currency_code,
                              p_rvsl_code        => l_reversal_code,
                              p_msg              => p_comment_in,
                              p_mob_no           => l_mobile_number,
                              p_device_id        => l_device_id,
                              p_resp_code        => p_status_out,
                              p_resmsg           => p_err_msg_out,
                              p_spend_acct_bal   => p_spending_available_balance);
      END IF;
      -- Set up savings ledger balance
      IF regexp_like(p_err_msg_out,
                     '^[[0-9]]*')
      THEN
        p_savings_ledger_balance := p_err_msg_out;
      END IF;

    ELSE
      l_txn_code := '45'; -- SpendingtoSavingsTransfer
      -- transfer from spending to savings
      sp_spendingtosavingstransfer(p_inst_code        => c_inst_code,
                                   p_pan_code         => l_plain_pan,
                                   p_msg              => p_comment_in,
                                   p_spd_acct_no      => l_spending_acct_no,
                                   p_svg_acct_no      => l_saving_acct_no,
                                   p_delivery_channel => l_delivery_channel,
                                   p_txn_code         => l_txn_code,
                                   p_rrn              => l_rrn,
                                   p_txn_amt          => p_amount_in,
                                   p_txn_mode         => l_txn_mode,
                                   p_bank_code        => l_bank_code,
                                   p_curr_code        => l_currency_code,
                                   p_rvsl_code        => l_reversal_code,
                                   p_tran_date        => l_date,
                                   p_tran_time        => l_time,
                                   p_ipaddress        => l_ipaddress,
                                   p_ani              => NULL,
                                   p_dni              => NULL,
                                   p_resp_code        => p_status_out,
                                   p_resmsg           => p_err_msg_out,
                                   p_spenacctbal      => p_spending_available_balance,
                                   p_spenacctledgbal  => p_spending_ledger_balance);
      g_debug.display('p_status_out' || p_status_out);
      g_debug.display('p_err_msg_out' || p_err_msg_out);

      -- Set up savings ledger balance
      IF regexp_like(p_err_msg_out,
                     '^[[0-9]]*')
      THEN
        p_savings_ledger_balance := p_err_msg_out;
      END IF;

      -- Set up availed and available transactions
      get_savings_xfr_count(p_saving_acct_number_in => l_saving_acct_no,
                            p_hash_pan_in           => l_hash_pan,
                            p_availed_txns_out      => p_savings_completed_transfers,
                            p_available_txns_out    => p_savings_remaining_transfers,
                            p_resp_code_out         => p_status_out,
                            p_errmsg_out            => p_err_msg_out);

    END IF; -- If p_from_account_type_in = 'SAVINGS' THEN

    IF p_status_out <> '00'
       OR p_err_msg_out <> 'OK'
    THEN
      p_status_out  := p_status_out;
      p_err_msg_out := p_err_msg_out;
    ELSE
      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';

    END IF;

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
  END account_transfer;

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
END gpp_account_transfer;
/

show error