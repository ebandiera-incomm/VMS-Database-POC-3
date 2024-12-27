create or replace PACKAGE BODY                                                                         VMSCMS.GPP_TRANSACTION IS

  -- PL/SQL Package using FS Framework
  -- Author  : Rojalin
  -- Created : 8/17/2015 1:32:11 PM

  -- Private type declarations
  -- TEST 1

  -- Private constant declarations

  -- Private variable declarations

  -- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;

  --declare all FS errors here
  g_err_unknown      fsfw.fserror_t;
  g_err_nodata       fsfw.fserror_t;
  g_err_mandatory    fsfw.fserror_t;
  g_err_invalid_data fsfw.fserror_t;
  g_err_failure      fsfw.fserror_t;


  -- Function and procedure implementations

  -- To get token
  FUNCTION get_transaction_token(p_customer_card_no_in IN vmscms.transactionlog.customer_card_no%TYPE,
                                 p_rrn_in              IN vmscms.transactionlog.rrn%TYPE,
                                 p_auth_id_in          IN vmscms.transactionlog.auth_id%TYPE)
    RETURN VARCHAR2 IS
    l_token vmscms.vms_token_transactionlog.vtt_token%TYPE;
  BEGIN
    SELECT c.vtt_token
      INTO l_token
      FROM vmscms.vms_token_transactionlog c
     WHERE c.vtt_pan_code = p_customer_card_no_in
       AND c.vtt_rrn = p_rrn_in
       AND c.vtt_auth_id = p_auth_id_in;
    RETURN l_token;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;
  --To audit transaction log for each API call...logged for both success and failure calls
  PROCEDURE audit_transaction_log(p_api_name_in     IN VARCHAR2,
                                  p_customer_id_in  IN VARCHAR2,
                                  p_hash_pan_in     IN VARCHAR2,
                                  p_encr_pan_in     IN VARCHAR2,
                                  p_process_flag_in IN VARCHAR2,
                                  p_process_msg_in  IN VARCHAR2,
                                  p_response_id_in  IN VARCHAR2,
                                  p_remarks_in      IN VARCHAR2,
                                  p_timetaken_in    IN VARCHAR2,
                                  p_fee_calc_in     IN VARCHAR2 DEFAULT 'N',
                                  p_auth_id_in      IN VARCHAR2 DEFAULT NULL) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
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

/****************************************************************************
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0001

****************************************************************************/
  BEGIN
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
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

    l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-date'),
                     6,
                     11);

    --- l_date := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11);
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
    --g_debug.display('l_time' || l_time);
    SELECT to_char(to_char(SYSDATE,
                           'YYMMDDHH24MISS') ||   --Changes VMS-8279 ~ HH has been replaced as HH24
                   lpad(vmscms.seq_deppending_rrn.nextval,
                        3,
                        '0'))
      INTO l_rrn
      FROM dual;
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
       '18',
       (SELECT ctm_tran_type
          FROM vmscms.cms_transaction_mast
         WHERE ctm_delivery_channel = '03'
           AND ctm_tran_code = '18'),
       '0',
       p_process_flag_in,
       --to_char(to_date(l_date, 'dd-mm-yyyy'), 'yyyymmdd'),
       l_date,
       l_time,
       p_hash_pan_in,
       ((SELECT ctm_tran_desc
           FROM vmscms.cms_transaction_mast
          WHERE ctm_delivery_channel = '03'
            AND ctm_tran_code = '18') || ' - ' || p_api_name_in),
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
           AND ctm_tran_code = '18'),
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
       '18',
       (SELECT ctm_tran_type
          FROM vmscms.cms_transaction_mast
         WHERE ctm_delivery_channel = '03'
           AND ctm_tran_code = '18'),
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
       '18',
       NULL,
       NULL,
       SYSDATE,
       NULL,
       p_timetaken_in);
    COMMIT;
    g_debug.display('p_api_name_in' || p_api_name_in);

  EXCEPTION
    WHEN no_data_found THEN
      g_err_nodata.raise(p_api_name_in,
                         vmscms.gpp_const.c_ora_error_status);
    WHEN OTHERS THEN
      g_err_unknown.raise(p_api_name_in,
                          vmscms.gpp_const.c_ora_error_status);

  END audit_transaction_log;

  --Get Transaction Detail API
  --status: 0 - success, Non Zero value - failure
PROCEDURE get_transaction_detail(p_customer_id_in      IN VARCHAR2,
                                   p_txn_id_in           IN VARCHAR2,
                                   p_txn_date_in         IN VARCHAR2,
                                   p_delivery_channel_in IN VARCHAR2,
                                   p_txn_code_in         IN VARCHAR2,
                                   p_response_code_in    IN VARCHAR2,
                                   p_status_out          OUT VARCHAR2,
                                   p_err_msg_out         OUT VARCHAR2,
                                   c_transaction_out     OUT SYS_REFCURSOR,
                                   c_fraudrule_out       OUT SYS_REFCURSOR) AS
    l_field_name VARCHAR2(50);
    l_api_name   VARCHAR2(30) := 'GET TRANSACTION DETAILS';
    l_flag       PLS_INTEGER := 0;
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_partner_id vmscms.transactionlog.partner_id%TYPE;
    l_customer   vmscms.cms_cust_mast.ccm_cust_id%TYPE;
    l_date       vmscms.transactionlog.business_date%TYPE;
    l_time       vmscms.transactionlog.business_time%TYPE;
    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;
    l_acct_no         vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_token           vmscms.vms_token_transactionlog.VTT_TOKEN%TYPE;
    l_correlation_id  vmscms.vms_token_transactionlog.VTT_TOKEN_REF_ID%TYPE;
    l_txn_de_25       vmscms.CMS_TXN_ISO_DETL.cti_de_25%TYPE;
    l_chargeback_val  VMSCMS.CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;

/***************************************************************************************
         * Modified By        : UBAIDUR RAHMAN
         * Modified Date      : 09-Jan-2019
         * Modified Reason    : Modified to return individual fraud rule executionTime.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 09-Jan-2019
         * Build Number       : R11_B0001

         * Modified By        : VINI PUSHKARAN
         * Modified Date      : 21-Jan-2019
         * Modified Reason    : Modified to return Merchant and Location details to CCA.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 21-Jan-2019
         * Build Number       : R11_B0005

         * Modified By        : UBAIDUR RAHMAN
         * Modified Date      : 04-Feb-2019
         * Modified Reason    : Modified to return Merchant and Location "Address2" details(VMS-766)  and
		                            Token and Device details to CCA(VMS-447).
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 07-Feb-2019
         * Build Number       : R12_B0002

         * Modified by        : Jahnavi B
         * Modified Date      : 21-May-19
         * Modified For       : VMS-935,VMS-936
         * Reviewer           : Saravanankumar
         * Reviewed Date      : 21-May-19
         * Build Number       : R16_B00003

    	 * Modified by        : UBAIDUR RAHMAN H
         * Modified Date      : 06-Aug-19
         * Modified For       : VMS-1022.
         * Modified Reason    : CH Statement/Transaction history should not display
                        			InComm user's name when manually adjusted.
         * Reviewer           : Saravana Kumar
         * Build Number       : R19_B0001

	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0001

	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 07-May-2020
         * Modified Reason    : VMS-1021 FSAPI - Cuentas Banking Alternative Transaction Description
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 08-May-2020
         * Build Number       : R30_B0002
	 * Modified by        : UBAIDUR RAHMAN H
         * Modified Date      : 22-Mar-2021.
         * Modified For       : VMS-3832.
         * Modified Reason    : CCA--Decline Reason Code and Description
         * Reviewer           : Saravana Kumar
         * Build Number       : R45

         * Modified by        : Bhavani E
         * Modified Date      : 16-May-2023
         * Modified For       : VMS-7350
         * Modified Reason    : Send POS entry mode, CNP and Network identifier to CCA
         * Reviewer           : Pankaj S
         * Build Number       : R80

		 * Modified By      : Mohan E.
		 * Modified Date    : 21/06/2024
		 * Purpose          : VMS-8883 Send Dynamic Decline Responses from Accertify to CCA
		 * Reviewer         : Pankaj
		 * Release Number   : VMSGPRHOSTR99_B0002

		 * Modified By      : Mohan E.
		 * Modified Date    : 31/07/2024
		 * Purpose          : VMS_8739 Display Anticipated Verification Amount on CCA
		 * Reviewer         : Pankaj
		 * Release Number   : VMSGPRHOSTR101_B0002
***************************************************************************************/

  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --l_partner_id := 1;
    --Check for mandatory fields
    CASE
      WHEN p_txn_date_in IS NULL THEN
        l_field_name := 'TRANSACTIONDATE';
        l_flag       := 1;
      WHEN p_delivery_channel_in IS NULL THEN
        l_field_name := 'DELIVERYCHANNEL';
        l_flag       := 1;
      WHEN p_txn_code_in IS NULL THEN
        l_field_name := 'TRANSACTIONCODE';
        l_flag       := 1;
      WHEN p_response_code_in IS NULL THEN
        l_field_name := 'RESPONSECODE';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;

    --customer id validation cfip:149 starts
    -- SELECT ccm_cust_id    -- performance change
    --  INTO l_customer       -- performance change
    --  FROM cms_cust_mast     -- performance change
    -- WHERE ccm_cust_id = p_customer_id_in;    -- performance change
    --customer id validation cfip:149 ends

    --Fetching the active PAN for the input customer id
    /*vmscms.gpp_pan.get_pan_details(p_customer_id_in,
    l_hash_pan,
    l_encr_pan);*/
    -- Changinng the call to get vmscms.cms_appl_pan.cap_acct_no

    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   l_acct_no);

    IF l_acct_no IS NULL
    THEN
      /* CFIP 375 Start
      l_field_name := 'CAP_ACCT_NO';
      l_flag       := 1;
      */
      RAISE no_data_found;
      --CFIP 375 end
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
    l_date := to_char(to_date(p_txn_date_in,
                              'yyyy-mm-dd hh24:mi:ss'),
                      'yyyymmdd');
    l_time := to_char(to_date(p_txn_date_in,
                              'yyyy-mm-dd hh24:mi:ss'),
                      'hh24miss');

    --Getting Chargeback Timeframe
    BEGIN
      SELECT CIP_PARAM_VALUE
        INTO l_chargeback_val
        FROM VMSCMS.CMS_INST_PARAM
        WHERE CIP_PARAM_KEY = 'CHARGEBACK_TIMEFRAME'
        AND CIP_INST_CODE = 1;
      EXCEPTION
        WHEN OTHERS THEN
                l_chargeback_val := 0;
    END;
    --Array for transaction details
    OPEN c_transaction_out FOR
      SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
             --                a.business_time,
             --              'yyyymmdd hh24miss'),
             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
             CASE
               WHEN (business_date IS NULL OR business_time IS NULL) THEN
                to_char(add_ins_date,
                        'yyyy-mm-dd hh24:mi:ss')
               WHEN regexp_like(business_time,
                                '[^0-9]+') THEN
                to_char(to_date(business_date || ' ' || business_time,
                                'yyyymmdd hh24:mi:ss'),
                        'yyyy-mm-dd hh24:mi:ss')
               ELSE
                to_char(to_date(business_date || ' ' || business_time,
                                'yyyymmdd hh24miss'),
                        'yyyy-mm-dd hh24:mi:ss')
             END AS businessdate,
             to_char(add_ins_date,
                     'yyyy-mm-dd hh24:mi:ss') systemdate,
             decode(a.network_settl_date,
                    NULL,
                    a.network_settl_date,
                    to_char(to_date(a.network_settl_date || ' 000000',
                                    'yyyymmdd hh24miss'),
                            'yyyy-mm-dd hh24:mi:ss')) settlementdate, -- CFIP 358
             REPLACE(vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(customer_card_no_encr)),
                     '*',
                     'X') pan,
             customer_acct_no accountnumber,
             (SELECT vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr))--cap_mask_pan
                FROM vmscms.cms_appl_pan
               WHERE cap_inst_code = instcode
                 AND cap_pan_code = topup_card_no) topan,
             topup_acct_no toaccountnumber,
             delivery_channel deliverychannelcode,
             c.cdm_channel_desc deliverychanneldescription,
             txn_code transactioncode,
             --start DFCTNM-108 (VMS 3.2.4 integration into CCA)
             --CASE
             -- WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
             --  decode(a.trans_desc, NULL, ctm_tran_desc, trans_desc) ||
             --  decode(a.clawback_indicator, 'Y', ' CLAWBACK FEE')
             -- ELSE
             --  decode(a.trans_desc,
             --         NULL,
             --         ctm_tran_desc,
             --         trans_desc || ' Reversal')
             -- END TRANSACTIONDESCRIPTION,
			CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
                    (SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
                    REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
                                                'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
                        REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
                                                'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE)
			ELSE
             CASE
               WHEN to_number(nvl(reversal_code,
                                  '00')) = 0 THEN
                decode(upper(TRIM(trans_desc)),
                       NULL,
                       ctm_display_txndesc,
                       upper(TRIM(ctm_tran_desc)),
                       ctm_display_txndesc,
                       REPLACE(upper(trans_desc),
                               'CLAWBACK-')) ||
                decode(clawback_indicator,
                       'Y',
                       (SELECT upper(decode(cpc_clawback_desc,
                                            NULL,
                                            '',
                                            ' - ' || cpc_clawback_desc))
                          FROM vmscms.cms_prod_cattype
                         WHERE cpc_prod_code = productid
                           AND cpc_card_type = categoryid
                           AND cpc_inst_code = 1)) -- performance change
               ELSE
                decode(upper(TRIM(trans_desc)),
                       NULL,
                       ctm_display_txndesc,
                       upper(TRIM(ctm_tran_desc)),
                       ctm_display_txndesc,
                       REPLACE(upper(trans_desc),
                               'CLAWBACK-')) || ' Reversal'
             END
			 END transactiondescription,
             --End DFCTNM-108 (VMS 3.2.4 integration into CCA)
             mccode mcccode,
             (SELECT mccodedesc
                FROM vmscms.mccode
               WHERE act_inst_code = 1
                 AND mccode = a.mccode) mccdescription,
             CASE
               WHEN to_number(nvl(reversal_code,
                                  '00')) = 0 THEN
                decode(trans_desc,
                       NULL,
                       ctm_tran_desc,
                       trans_desc)
               ELSE
                decode(trans_desc,
                       NULL,
                       ctm_tran_desc,
                       trans_desc || ' Reversal')
             END TYPE,
             to_char(nvl(ledger_balance,
                         0),
                     '9,999,999,990.99') ledgerbalance,
             to_char(nvl(acct_balance,
                         0),
                     '9,999,999,990.99') availablebalance,
             fee_plan feeplanid,
            CASE
               WHEN (CASE
                      WHEN delivery_channel IN ('01',
                                                '02')
                           AND
                           ctm_credit_debit_flag IN ('DR',
                                                     'CR') THEN
                       decode(dispute_flag,
                              NULL,
                              'N',
                              dispute_flag)
                      ELSE
                       'C'
                    END) = 'N'
                    AND ((trunc(SYSDATE - a.add_ins_date) < to_number(l_chargeback_val)) OR (to_number(l_chargeback_val) <= 0)) THEN
                'True'
               ELSE
                'False'
             END isdisputable,
             CASE dispute_flag
               WHEN 'Y' THEN
                'True'
               ELSE
                'False'
             END AS indispute,
             feecode feeid,
             tranfee_amt feeamount,
             (SELECT cfm_fee_desc
                FROM vmscms.cms_fee_mast
               WHERE cfm_fee_code = feecode
                 AND cfm_inst_code = 1) feedescription,
             amount transactionamount,
             (SELECT cim_inst_name
                FROM vmscms.cms_inst_mast
               WHERE cim_inst_code = instcode) institution,
             (SELECT gcm_curr_name
                FROM vmscms.gen_curr_mast
               WHERE gcm_inst_code = instcode
                 AND gcm_curr_code = currencycode) currencycode,
             currencycode currencynum,
             --decode(decode(cr_dr_flag,
             --              NULL,
             --              ctm_credit_debit_flag,
             --              cr_dr_flag),
             --       'CR',
             --       'Credit',
             --      'DR',
             --      'Debit',
             --      'NA') crdrflag, (This existing logic is replaced with the change below)
             CASE
               WHEN customer_acct_no = l_acct_no THEN
                CASE
                  WHEN ctm_txn_ind = 'Y' THEN
                   decode(decode(ctm_credit_debit_flag,
                                 'DR',
                                 decode(nvl(reversal_code,
                                            '0'),
                                        '0',
                                        'Debit',
                                        'Credit'),
                                 'CR',
                                 decode(nvl(reversal_code,
                                            '0'),
                                        '0',
                                        'Credit',
                                        'Debit')),
                          'Credit',
                          'Debit',
                          'Debit',
                          'Credit')
                  ELSE
                   decode(ctm_credit_debit_flag,
                          'DR',
                          decode(nvl(reversal_code,
                                     '0'),
                                 '0',
                                 'Debit',
                                 'Credit'),
                          'CR',
                          decode(nvl(reversal_code,
                                     '0'),
                                 '0',
                                 'Credit',
                                 'Debit'),
                          'NA',
                          decode(nvl(reversal_code,
                                     '0'),
                                 '0',
                                 'Debit',
                                 'Credit'))
                END
               WHEN topup_acct_no = l_acct_no THEN
                CASE
                  WHEN ctm_txn_ind = 'Y' THEN
                   decode(decode(ctm_credit_debit_flag,
                                 'DR',
                                 decode(nvl(reversal_code,
                                            '0'),
                                        '0',
                                        'Credit',
                                        'Debit'),
                                 'CR',
                                 decode(nvl(reversal_code,
                                            '0'),
                                        '0',
                                        'Debit',
                                        'Credit')),
                          'Credit',
                          'Debit',
                          'Debit',
                          'Credit')
                  ELSE
                   decode(ctm_credit_debit_flag,
                          'DR',
                          decode(nvl(reversal_code,
                                     '0'),
                                 '0',
                                 'Credit',
                                 'Debit'),
                          'CR',
                          decode(nvl(reversal_code,
                                     '0'),
                                 '0',
                                 'Debit',
                                 'Credit'),
                          'NA',
                          decode(nvl(reversal_code,
                                     '0'),
                                 '0',
                                 'Credit',
                                 'Debit'))
                END
             END crdrflag,
             terminal_id terminalid,
             reason,
             decode(reversal_code,
                    '0',
                    'FALSE',
                    'TRUE') isreversaltransaction,
                    -- SN added for VMS-7350
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork,
                  -- EN added for VMS-7350
             --delivery_channel orgnldeliverychannel,
             (SELECT delivery_channel
                FROM transactionlog
               WHERE rrn = a.orgnl_rrn
                 AND response_code = '00'
                 AND rownum < 2) orgnldeliverychannel, --performance change 5.5.5
             decode(orgnl_business_date || orgnl_business_time,
                    NULL,
                    'null',
                    to_char(to_date(orgnl_business_date || ' ' ||
                                    orgnl_business_time,
                                    'yyyymmdd hh24miss'),
                            'yyyy-mm-dd hh24:mi:ss')) originaltxndate,
             orgnl_rrn originaltxnid,
             orgnl_terminal_id originalterminalid,
             response_code orgnlresponsecode,
	     decode
	     ((SELECT upper(trim(cms_resp_desc))
                FROM vmscms.cms_response_mast
               WHERE cms_response_id = response_id
                 AND cms_delivery_channel = delivery_channel
                 AND cms_inst_code = 1),
		 upper(trim(error_msg)),
	      (SELECT cms_resp_desc
                FROM vmscms.cms_response_mast
               WHERE cms_response_id = response_id
                 AND cms_delivery_channel = delivery_channel
                 AND cms_inst_code = 1),
             (SELECT cms_resp_desc
                FROM vmscms.cms_response_mast
               WHERE cms_response_id = response_id
                 AND cms_delivery_channel = delivery_channel
                 AND cms_inst_code = 1)			--- Modified for VMS-3832 CCA--Decline Reason Code and Description
                 ||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) orgnlresponsedescription,
             merchant_id merchantid,
             (
                CASE
                  WHEN (delivery_channel = '11')
                  THEN REGEXP_REPLACE(NVL((DECODE(NVL(COMPANYNAME,''),'','','/'
                    ||COMPANYNAME)
                    || DECODE(NVL(COMPENTRYDESC,''),'','','/'
                    ||COMPENTRYDESC)
                    || DECODE(NVL(INDNAME,''),'','','/'
                    ||INDIDNUM
                    ||' to '
                    ||INDNAME)),'Direct Deposit'),'/','',1,1)
                  ELSE NVL(MERCHANT_NAME,DECODE(DELIVERY_CHANNEL,'01','ATM','02','Retail Merchant','03','Customer Service','07','IVR Transfer','10','Card Holder website','11','Direct Deposit','13','Mobile Transfer','-'))
                END
              ) MerchantName ,
             merchant_city merchantcity,
             case when delivery_channel='03' and txn_code in ('13','14') then NULL
             else
             merchant_state
             end merchantstate,					 --- Modified for VMS-1022
             merchant_zip merchantpostalcode,
            NVL(merchant_street,'-') MerchantAddress1,
            merchant_address2 MerchantAddress2,           -- added for VMS-766 (sending Merchant & Location Details "Address2" to CCA)
             (CASE                                        -- added for VMS-744 (sending Merchant and Location details to CCA)
             WHEN length(spil_loc_cntry) = 3
             THEN
              (select gcm_switch_cntry_code
               from vmscms.gen_cntry_mast
               where gcm_alpha_cntry_code = spil_loc_cntry)
             ELSE
               spil_loc_cntry
             END) MerchantCountry,
             spil_location_id MerchantStoreDbId,
             merchant_id MerchantDbId,
             zip_code avspostalcode,
             decode(addr_verify_indicator,
                    'U',
                    'TRUE',
                    '2',
                    'TRUE',
                    '3',
                    'TRUE',
                    'FALSE') avsindicator,
             addr_verify_response avsresponsecode,
             decode(addr_verify_response,
                    'Y',
                    'Address and ZIP Code Verified',
                    'Z',
                    'ZIP Code Matched but Address Not Matched',
                    'N',
                    'Address Verification Failed',
                    'NA') avsresponsedescription,
             CASE
               WHEN delivery_channel = '02'
                    AND pos_verification = 'S' THEN
                'Signature Based'
               WHEN delivery_channel = '02'
                    AND pos_verification = 'P' THEN
                'PIN Based'
               WHEN delivery_channel = '01' THEN
                'PIN Based'
               ELSE
                'NA'
             END authenticationtype,
             to_char(cpt_expiry_date,
                     'yyyy-mm-dd hh24:mi:ss') preauthreleasedate,
             decode(partial_preauth_ind,
                    '0',
                    'FALSE',
                    '1',
                    'TRUE',
                    'NA') partialauthindicator,
             decode(delivery_channel,
                    '03',
                    cum_lgin_code,
                    NULL) userid,
             CASE nvl(decode(delivery_channel,
                         '03',
                         add_ins_user,
                         NULL),
                  0)
               WHEN 0 THEN
                fsapi_username
               ELSE
                cum_user_name
             END AS username,
             remark,
             vtt_token,
             vtt_token_expiry_date,
             vtt_token_type,
             nvl(k.vtt_wallet_identifier,
                 k.vtt_token_requestorid) wallet,
            ani Ani,
            DECODE(marked_status,'F','TRUE','FALSE') isFraudulent,
            DECLINE_RULEID  ruleid,
            AMEX_TID   TID,
            AMEX_SETTLEMENT_RRN   ARN,
            k.vtt_token token,                         -- added token and device details for VMS-447
            (select to_char(vti_ins_date,'yyyy-mm-dd') from vmscms.vms_token_info
             where vti_token = k.vtt_token and vti_acct_no = a.customer_acct_no) tokenprovisiondate,
            k.vtt_token_expiry_date tokenexpirydate,
            (select vtm_tokentype_desc from vmscms.vms_tokentype_mast where vtm_token_type = k.vtt_token_type) tokentype,
            k.vtt_token_status tokenstatus,
            (select vdm_devicetype_desc from vmscms.vms_devicetype_mast where vdm_device_type =  k.vtt_device_type) devicetype,
            k.vtt_deviceid deviceid,
            k.vtt_device_name devicename,
            k.vtt_device_number devicenumber,
            k.vtt_device_location devicelocation,
            k.vtt_ipaddress  deviceip,
            k.vtt_device_langcode devicelanguage,
           (select vwm_wallet_name from vmscms.vms_wallet_mast where vwm_wallet_id = nvl(k.vtt_wallet_identifier,
                 k.vtt_token_requestorid)) walletid,
            k.vtt_secure_elementid seid,
			rules ruleGroup,         		--Added for VMS_8883
			nvl(src_of_decline , (case when substr(rrn,1,1) ='X'   and DELIVERY_CHANNEL in ('01','02','16') then 'OLS'
                                       when response_code =  '199' and DELIVERY_CHANNEL in ('01','02','16') then 'ACC' end ))   source,			--Added for VMS_8883
			(select VAR_VERBAL_ACTIONCODE
					from vmscms.VMS_ACCERTIFY_RESPONSE_DETAILS
					where  VAR_RRN = rrn
					and VAR_DELIVERY_CHANNEL =DELIVERY_CHANNEL
					and VAR_TXN_CODE = txn_code
					and to_char (VAR_INS_DATE,'YYYYMMDD') = BUSINESS_DATE)  actionCode,			--Added for VMS_8883
			anticipated_amount AnticipatedAmount  --Added for VMS_8739
        FROM vmscms.transactionlog           a,
             vmscms.cms_transaction_mast,
             vmscms.cms_preauth_transaction,
             vmscms.vms_token_transactionlog k,
             vmscms.cms_userdetl_mast,
             vmscms.cms_delchannel_mast      c,
             vmscms.cms_transaction_log_dtl e -- added for VMS-7350
       WHERE instcode = ctm_inst_code
         AND txn_code = ctm_tran_code
         AND delivery_channel = ctm_delivery_channel
         AND instcode = 1
         AND customer_card_no = cpt_card_no(+)
         AND rrn = cpt_rrn(+)
         AND business_date = cpt_txn_date(+)
         AND business_time = cpt_txn_time(+)
         AND a.instcode = c.cdm_inst_code
         AND a.delivery_channel = c.cdm_channel_code
         AND k.vtt_pan_code(+) = a.customer_card_no
         AND k.vtt_rrn(+) = a.rrn
         AND k.vtt_auth_id(+) = a.auth_id
         AND response_code = p_response_code_in
         AND rrn = p_txn_id_in
            --cfip fix 149 starts
         AND business_date = l_date
            -- REPLACE(substr(p_txn_date_in, 1, 10), '-', '') /*substr(p_txn_date_in, 1, 8)*/
            --AND business_time = l_time
         AND REPLACE(business_time,
                     ':',
                     '') = l_time
            --REPLACE(substr(p_txn_date_in, -8, 10), ':', '') /*substr(p_txn_date_in, -6, 10)*/
            --cfip fix 149 ends
         AND txn_code = p_txn_code_in
            --CFIP Jira Issue :206 starts
            --AND nvl(add_ins_user, 1) = cum_user_code
         AND add_ins_user = cum_user_code(+)
            --CFIP Jira Issue :206 ends
         AND delivery_channel = p_delivery_channel_in
         AND productid || categoryid =
             vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                      p_prod_code_in  => productid,
                                                      p_card_type_in  => categoryid)
        --SN Added for VMS-7350
         AND a.rrn=e.ctd_rrn(+)
         AND a.business_date=e.ctd_business_date(+)
         AND a.business_time=e.ctd_business_time(+)
         AND a.delivery_channel=e.ctd_delivery_channel(+)
         AND a.customer_card_no=e.ctd_customer_card_no(+)
         AND a.txn_code=e.ctd_txn_code(+)
         AND a.msgtype=e.ctd_msg_type(+);
        --EN Added for VMS-7350
       IF p_delivery_channel_in = '16' AND p_txn_code_in IN ('11','16') THEN

            SELECT cti_de_25
			into l_txn_de_25
			FROM vmscms.CMS_TXN_ISO_DETL
			WHERE cti_rrn= p_txn_id_in
			AND cti_txn_code = p_txn_code_in
			AND cti_busn_date = l_date
			AND REPLACE(cti_busn_time,
                         ':',
                         '') = l_time;

            SELECT VTT_TOKEN,CASE when l_txn_de_25 = '3700' then VTT_TOKEN_REF_ID
                                  when l_txn_de_25 = '5259' then VTT_WPCONVERSION_ID
                                  else VTT_CORRELATION_ID END
            INTO l_token,l_correlation_id
            FROM vmscms.transactionlog           a,
                 vmscms.vms_token_transactionlog k
             WHERE instcode = 1
             AND k.vtt_pan_code = a.customer_card_no
             AND k.vtt_rrn = a.rrn
             AND k.vtt_auth_id = a.auth_id
             AND response_code = p_response_code_in
             AND rrn = p_txn_id_in
             AND business_date = l_date
             AND REPLACE(business_time,
                         ':',
                         '') = l_time
             AND txn_code = p_txn_code_in
             AND delivery_channel = p_delivery_channel_in
             AND productid || categoryid =
                 vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                          p_prod_code_in  => productid,
                                                          p_card_type_in  => categoryid);

         END IF;
         OPEN c_fraudrule_out FOR
             SELECT VRR_RULE_NAME ruleName,
             VRR_RULE_DESC ruleDescription,
             VRR_RULE_RESULT isPassed,
	     to_char(VRR_EXECUTION_TIME,'YYYY-MM-DD HH24:MI:SS') executionTime		-- Added to return individual fraud rule executionTime
             FROM vmscms.VMS_RULECHECK_RESULTS
             WHERE VRR_TOKEN = l_token
             union
              SELECT VRR_RULE_NAME ruleName,
             VRR_RULE_DESC ruleDescription,
             VRR_RULE_RESULT isPassed,
	     to_char(VRR_EXECUTION_TIME,'YYYY-MM-DD HH24:MI:SS') executionTime		-- Added to return individual fraud rule executionTime
             FROM vmscms.VMS_RULECHECK_RESULTS
             WHERE VRR_CORRELATION_ID = l_correlation_id;

    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;
    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,     ----Commented for VMS-1719 - CCA RRN Logging Issue.
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
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_failure_res_id,
                                                   NULL,
                                                   l_timetaken);
  END get_transaction_detail;

  --Get Transaction History API
  --status: 0 - success, Non Zero value - failure
  PROCEDURE get_transaction_history(p_customer_id_in    IN VARCHAR2,
                                    p_start_date_in     IN VARCHAR2,
                                    p_end_date_in       IN VARCHAR2,
                                    p_acc_type_in       IN VARCHAR2 DEFAULT 'ALL',
                                    p_txn_filter_in     IN VARCHAR2 DEFAULT 'ALL',
                                    p_token_in          IN VARCHAR2,
                                    p_sortorder_in      IN VARCHAR2,
                                    p_sortelement_in    IN VARCHAR2,
                                    p_recordsperpage_in IN VARCHAR2,
                                    p_pagenumber_in     IN VARCHAR2,
                                    p_status_out        OUT VARCHAR2,
                                    p_err_msg_out       OUT VARCHAR2,
                                    c_transaction_out   OUT SYS_REFCURSOR) AS
    l_account_type    VARCHAR2(100) := nvl(upper(p_acc_type_in),
                                           'ALL');
    l_txn_filter_type VARCHAR2(100) := nvl(upper(p_txn_filter_in),
                                           'ALL');
    /*l_start_date       VARCHAR2(100);
    l_end_date        VARCHAR2(100);*/
    l_start_date     DATE;
    l_end_date       DATE;
    l_sort_order     VARCHAR2(20);
    l_api_name       VARCHAR2(30) := 'GET TRANSACTION HISTORY';
    l_hash_pan       vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan       vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_query          VARCHAR2(32000);
    l_wrapper_query  VARCHAR2(32000);
    l_row_query      VARCHAR2(32000);
    l_order_by       VARCHAR2(500);
    l_recordsperpage PLS_INTEGER;
    l_pagenumber     PLS_INTEGER;
    l_rec_start_no   PLS_INTEGER;
    l_rec_end_no     PLS_INTEGER;
    l_partner_id     vmscms.transactionlog.partner_id%TYPE;
    l_start_time     NUMBER;
    l_end_time       NUMBER;
    l_timetaken      NUMBER;
    --performance change
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no      vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;
    l_chargeback_val  VMSCMS.CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;

/***************************************************************************************
         * Modified By        : VINI PUSHKARAN
         * Modified Date      : 21-Jan-2019
         * Modified Reason    : Modified to return Merchant and Location details to CCA.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 21-Jan-2019
         * Build Number       : R11_B0005
         * Modified by        : Jahnavi B
         * Modified Date      : 21-May-19
         * Modified For       : VMS-935,VMS-936
         * Reviewer           : Saravanankumar
         * Reviewed Date      : 21-May-19
         * Build Number       : R16_B00003


	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0001

	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 07-May-2020
         * Modified Reason    : VMS-1021 FSAPI - Cuentas Banking Alternative Transaction Description
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 08-May-2020
         * Build Number       : R30_B0002

	 * Modified by        : UBAIDUR RAHMAN H
         * Modified Date      : 01-Apr-2021.
         * Modified For       : VMS-3832.
         * Modified Reason    : CCA--Decline Reason Code and Description
         * Reviewer           : Saravana Kumar
         * Build Number       : R45

         * Modified by        : Bhavani E
         * Modified Date      : 16-May-2023
         * Modified For       : VMS-7350
         * Modified Reason    : Send POS entry mode, CNP and Network identifier to CCA
         * Reviewer           : Pankaj S
         * Build Number       : R80
***************************************************************************************/


  BEGIN
    L_Start_Time := Dbms_Utility.Get_Time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));

    IF p_start_date_in IS NULL
    THEN
      IF p_end_date_in IS NULL
      THEN
        l_end_date := to_date((to_char(trunc(SYSDATE),
                                       'YYYYMMDD') || ' 235959'),
                              'YYYYMMDD HH24MISS');
      ELSE
        l_end_date := to_date((p_end_date_in || ' 235959'),
                              'YYYY-MM-DD HH24MISS');
      END IF;
      l_start_date := to_date((to_char(trunc(l_end_date) - 30) || ' 235959'),
                              'YYYY-MM-DD HH24MISS');
    ELSIF p_start_date_in IS NOT NULL
    THEN
      l_start_date := to_date((p_start_date_in || ' 000000'),
                              'YYYY-MM-DD HH24MISS');
      IF p_end_date_in IS NULL
      THEN
        l_end_date := to_date((to_char(trunc(l_start_date) + 30) ||
                              ' 235959'),
                              'YYYY-MM-DD HH24MISS');
      ELSE
        l_end_date := to_date((p_end_date_in || ' 235959'),
                              'YYYY-MM-DD HH24MISS');
      END IF;
    END IF;

    /*CASE
      WHEN p_start_date_in IS NULL AND p_end_date_in IS NULL THEN
        l_end_date   := to_char(to_date(SYSDATE, 'DD/MM/RRRR'), 'YYYYMMDD');
        l_start_date := to_char((to_date(SYSDATE, 'DD/MM/RRRR') - 30),
                                'YYYYMMDD');
      WHEN p_start_date_in IS NULL AND p_end_date_in IS NOT NULL THEN
        l_start_date := to_char((to_date(p_end_date_in, 'YYYY-MM-DD') - 30),
                                'YYYYMMDD');
        l_end_date   := to_char(to_date(p_end_date_in, 'YYYY-MM-DD'),
                                'YYYYMMDD');

      WHEN p_start_date_in IS NOT NULL AND p_end_date_in IS NULL THEN
        l_start_date := to_char(to_date(p_start_date_in, 'YYYY-MM-DD'),
                                'YYYYMMDD');
        l_end_date   := to_char((to_date(p_start_date_in, 'YYYY-MM-DD') + 30),
                                'YYYYMMDD');

      ELSE
        l_start_date := to_char(to_date(p_start_date_in, 'YYYY-MM-DD'),
                                'YYYYMMDD');
        l_end_date   := to_char(to_date(p_end_date_in, 'YYYY-MM-DD'),
                                'YYYYMMDD');

    END CASE;
    */
    g_debug.display('l_start_date' || l_start_date);
    g_debug.display('l_end_date' || l_end_date);
    --Fetching the active PAN for the input customer id
    --performance change
    -- vmscms.gpp_pan.get_pan_details(p_customer_id_in,
    --                           l_hash_pan,
    --                          l_encr_pan);

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
    g_debug.display('l_txn_filter_type' || l_txn_filter_type);

    IF (l_account_type NOT IN ('SPENDING',
                               'SAVINGS',
                               'ALL') OR
       l_txn_filter_type NOT IN ('ALL',
                                  'POSTED',
                                  'PREAUTH',
                                  'ADMIN',
                                  'DECLINED',
                                  'ACH',
                                  'HOLDS',
                                  'SETTLED',
                                  'FEES',
                                  'ALLFINANCIAL',
                                  'ACCOUNTACTIVITY',
                                  'ISDISPUTABLE', -- Phase 2 chnages
                                  'ISINDISPUTE',   -- Phase 2 chnages
                                  'ISFRAUDULENT',
                                  'TOKENPROVISIONINGATTEMPTS'))
       OR
       (l_account_type IN ('SAVINGS') AND
       l_txn_filter_type NOT IN ('ALL',
                                  'POSTED',
                                  'DECLINED'))
    THEN
      p_status_out := vmscms.gpp_const.c_inv_txn_acc_status;
      g_err_invalid_data.raise(l_api_name,
                               ',0004,',
                               'INVALID TXN FILTER OR ACCOUNT TYPE');
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

    IF upper(p_sortelement_in) NOT IN
       ('BUSINESSDATE',
        'DELIVERYCHANNELCODE',
        'MERCHANTNAME',
        'RESPONSEDESCRIPTION',
        'TRANSACTIONAMOUNT',
        'LEDGERBALANCE',
        'AVAILABLEBALANCE')
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

    --Defaulting start and end date when the values are null
    l_sort_order := CASE upper(p_sortorder_in)
                      WHEN 'ASCENDING' THEN
                       'ASC'
                      WHEN 'DESCENDING' THEN
                       'DESC'
                      ELSE
                       'ASC'
                    END;

    g_debug.display(p_customer_id_in || p_customer_id_in);
    g_debug.display('p_start_date_in' || p_start_date_in);
    g_debug.display('p_sortelement_in' || p_sortelement_in);
    g_debug.display('p_sortorder_in' || p_sortorder_in);

    l_order_by := nvl(upper(p_sortelement_in),
                      'BUSINESSDATE') || ' ' || l_sort_order;
    g_debug.display('l_order_by' || l_order_by);

    --Default values for Recordsperpage = 10, pagenumber = 1, if input parameters are null
    l_recordsperpage := nvl(p_recordsperpage_in,
                            1000);
    l_pagenumber     := nvl(p_pagenumber_in,
                            1);
    l_rec_end_no     := l_recordsperpage * l_pagenumber;
    l_rec_start_no   := (l_rec_end_no - l_recordsperpage) + 1;

    g_debug.display('l_recordsperpage' || l_recordsperpage);
    g_debug.display('l_pagenumber' || l_pagenumber);
    g_debug.display('l_rec_start_no' || l_rec_start_no);
    g_debug.display('l_rec_end_no' || l_rec_end_no);

    --Getting Chargeback Timeframe
    BEGIN
      SELECT CIP_PARAM_VALUE
        INTO l_chargeback_val
        FROM VMSCMS.CMS_INST_PARAM
        WHERE CIP_PARAM_KEY = 'CHARGEBACK_TIMEFRAME'
        AND CIP_INST_CODE = 1;
      EXCEPTION
        WHEN OTHERS THEN
                l_chargeback_val := 0;
    END;

    --savings
    l_wrapper_query := q'[SELECT * FROM (SELECT txns.*, rownum rnum FROM (]';
    CASE
      WHEN l_account_type = 'SAVINGS'
           AND l_txn_filter_type = 'POSTED' THEN
        l_query := q'[SELECT a.rrn id,
                       --to_char(to_date(a.business_date || ' ' ||
                       --                a.business_time,
                       --              'yyyymmdd hh24miss'),
                       --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                            CASE
                            WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                            TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                            WHEN regexp_like(business_time,'[^0-9]+') THEN
                            to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                            ELSE
                            to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                            END AS businessdate,
                            to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                             d.cap_mask_pan pan,
                              a.delivery_channel deliverychannelcode,
                              c.cdm_channel_desc deliverychanneldescription,
                              nvl(a.merchant_name,
                                  decode(a.delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              a.txn_code transactioncode,
                              --Start DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                 -- decode(a.trans_desc,
                                 --        NULL,
                                 --        ctm_tran_desc,
                                 --        trans_desc) ||
                                 -- decode(a.clawback_indicator,
                                 --        'Y',
                                 --        ' CLAWBACK FEE')
                                 --ELSE
                                 -- decode(a.trans_desc,
                                 --        NULL,
                                 --        ctm_tran_desc,
                                 --        trans_desc || ' Reversal')
                              --END transactiondescription,
                                CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
                    (SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
                    REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
                                                'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
                        REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
                                                'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE)
						ELSE
								CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              a.response_code responsecode,
                              decode((SELECT cms_resp_desc
                                       FROM vmscms.cms_response_mast e
                                      WHERE e.cms_response_id =
                                            a.response_id
                                        AND cms_delivery_channel =
                                            a.delivery_channel),
                                     NULL,
                                     nvl(a.error_msg, 'TRANSACTION DECLINED'),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast f
                                       WHERE f.cms_response_id = a.response_id
                                         AND f.cms_delivery_channel =
                                             a.delivery_channel)) responsedescription,
                              to_char(nvl(a.amount, 0), '9,999,999,990.99') transactionamount,
                              decode(decode(cr_dr_flag,
                                            NULL,
                                            ctm_credit_debit_flag,
                                            cr_dr_flag),
                                     'CR',
                                     'Credit',
                                     'DR',
                                     'Debit',
                                     'NA') crdrflag,
                              (SELECT g.gcm_curr_name
                                 FROM vmscms.gen_curr_mast g
                                WHERE g.gcm_inst_code = a.instcode
                                  AND g.gcm_curr_code = a.currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN a.customer_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN a.topup_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN a.customer_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN a.topup_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              a.fee_plan feeplanid,
                              a.feecode feeid,
                              to_char(nvl(a.tranfee_amt, 0),
                                      '9,999,999,990.99') feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              , :p_token_in TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                                FROM vmscms.transactionlog a,
                              (SELECT cap_pan_code, cam_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_cust_acct,
                                      vmscms.cms_acct_mast,
                                      vmscms.cms_appl_pan
                                WHERE cca_inst_code = cap_inst_code
                                  AND cca_cust_code = cap_cust_code
                                  and cca_acct_id = cam_acct_id
                                  AND cca_cust_code = :l_cust_code
                                  and cam_inst_code = 1
                                  and cam_type_code = '2') d,
                              vmscms.cms_transaction_mast b,
                              vmscms.cms_delchannel_mast c,
                              vmscms.cms_transaction_log_dtl e
                        WHERE b.ctm_inst_code = a.instcode
                          AND b.ctm_tran_code = a.txn_code
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                          AND b.ctm_delivery_channel = a.delivery_channel
                          AND a.customer_card_no = cap_pan_code
                          AND a.instcode = c.cdm_inst_code
                          AND a.delivery_channel = c.cdm_channel_code
                          AND (a.customer_acct_no = d.cam_acct_no OR
                              (a.topup_acct_no = d.cam_acct_no))
                          AND ((customer_card_no = d.cap_pan_code) OR
                              (topup_card_no = d.cap_pan_code))
                          AND (((to_number(nvl(a.total_amount, 0)) > 0 OR
                              to_number(nvl(a.amount, 0)) > 0 OR
                              to_number(nvl(a.tranfee_amt, 0)) > 0)) OR
                              b.ctm_tran_type = 'F')
                          AND a.response_code = '00'
                        --     AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                           AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        -- AND add_ins_date <= :l_end_date order by ]' ||
    --l_order_by;

    --Account Type : SAVINGS and Filter Type: DECLINED
      WHEN l_account_type = 'SAVINGS'
           AND l_txn_filter_type = 'DECLINED' THEN
        l_query := q'[SELECT a.rrn id,
                           --to_char(to_date(a.business_date || ' ' ||
                           --                a.business_time,
                           --              'yyyymmdd hh24miss'),
                           --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                            CASE
                            WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                            TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                            WHEN regexp_like(business_time,'[^0-9]+') THEN
                            to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                            ELSE
                            to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                            END AS businessdate,
                           to_char(a.add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                             d.cap_mask_pan pan,
                              a.delivery_channel deliverychannelcode,
                              c.cdm_channel_desc deliverychanneldescription,
                              nvl(a.merchant_name,
                                  decode(a.delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              a.txn_code transactioncode,
                              --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                 -- decode(a.trans_desc,
                                 --        NULL,
                                 --        b.ctm_tran_desc,
                                 --        trans_desc) ||
                                 -- decode(a.clawback_indicator,
                                 --        'Y',
                                 --        ' CLAWBACK FEE')
                                 --ELSE
                                 -- decode(a.trans_desc,
                                 --        NULL,
                                 --        b.ctm_tran_desc,
                                 --        a.trans_desc || ' Reversal')
                              --END transactiondescription,

							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                               CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)

                              a.response_code responsecode,
                              decode((SELECT upper(trim(cms_resp_desc))
                                       FROM vmscms.cms_response_mast e
                                      WHERE e.cms_response_id =
                                            a.response_id
                                        AND cms_delivery_channel =
                                            a.delivery_channel),
                                     NULL,
                                     nvl(a.error_msg, 'TRANSACTION DECLINED'),
				     upper(trim(error_msg)),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast f
                                       WHERE f.cms_response_id = a.response_id
                                         AND f.cms_delivery_channel =
                                             a.delivery_channel)||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) responsedescription,
                              to_char(nvl(a.amount, 0), '9,999,999,990.99') transactionamount,
                              decode(decode(cr_dr_flag,
                                            NULL,
                                            ctm_credit_debit_flag,
                                            cr_dr_flag),
                                     'CR',
                                     'Credit',
                                     'DR',
                                     'Debit',
                                     'NA') crdrflag,
                              (SELECT g.gcm_curr_name
                                 FROM vmscms.gen_curr_mast g
                                WHERE g.gcm_inst_code = a.instcode
                                  AND g.gcm_curr_code = a.currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN a.customer_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN a.topup_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN a.customer_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN a.topup_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              a.fee_plan feeplanid,
                              a.feecode feeid,
                              to_char(nvl(a.tranfee_amt, 0),
                                      '9,999,999,990.99') feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              , :p_token_in TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
                   e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id) ) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                   FROM vmscms.transactionlog a,
                              (SELECT cap_pan_code, cam_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_cust_acct,
                                      vmscms.cms_acct_mast,
                                      vmscms.cms_appl_pan
                                WHERE cca_inst_code = cap_inst_code
                                  AND cca_cust_code = cap_cust_code
                                  and cca_acct_id = cam_acct_id
                                  AND cca_cust_code = :l_cust_code
                                  and cam_inst_code = 1
                                  and cam_type_code = '2') d,
                              vmscms.cms_transaction_mast b,
                              vmscms.cms_delchannel_mast c,
                              vmscms.cms_transaction_log_dtl e
                        WHERE b.ctm_inst_code = a.instcode
                          AND b.ctm_tran_code = a.txn_code
                          AND b.ctm_delivery_channel = a.delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                          AND a.customer_card_no = cap_pan_code
                          AND a.instcode = c.cdm_inst_code
                          AND a.delivery_channel = c.cdm_channel_code
                          AND (a.customer_acct_no = d.cam_acct_no OR
                              (a.topup_acct_no = d.cam_acct_no))
                          AND ((customer_card_no = d.cap_pan_code) OR
                              (topup_card_no = d.cap_pan_code))
                          AND (((to_number(nvl(a.total_amount, 0)) > 0 OR
                              to_number(nvl(a.amount, 0)) > 0 OR
                              to_number(nvl(a.tranfee_amt, 0)) > 0)) OR
                              b.ctm_tran_type = 'F')
                          AND response_code <> '00'
                          --   AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                           AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';

        -- AND add_ins_date <= :l_end_date order by ]' ||
    --l_order_by;

    --Account Type : SAVINGS and Filter Type: ALL

      WHEN l_account_type = 'SAVINGS'
           AND l_txn_filter_type = 'ALL' THEN
        g_debug.display('savings all' || l_txn_filter_type);
        l_query := q'[SELECT a.rrn id,
                             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                             to_char(add_ins_date, 'yyyy-mm-dd') || ' ' ||
                              to_char(add_ins_date, 'hh24:mi:ss') systemdate,
                             d.cap_mask_pan pan,
                              a.delivery_channel deliverychannelcode,
                              c.cdm_channel_desc deliverychanneldescription,
                              nvl(a.merchant_name,
                                  decode(a.delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              a.txn_code transactioncode,
                              --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)

                              a.response_code responsecode,
                              decode((SELECT upper(trim(cms_resp_desc))
                                       FROM vmscms.cms_response_mast e
                                      WHERE e.cms_response_id =
                                            a.response_id
                                        AND cms_delivery_channel =
                                            a.delivery_channel),
                                     NULL,
                                     nvl(a.error_msg, 'TRANSACTION DECLINED'),
				     upper(trim(error_msg)),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast f
                                       WHERE f.cms_response_id = a.response_id
                                         AND f.cms_delivery_channel =		--- Modified for VMS-3832 CCA--Decline Reason Code and Description
                                             a.delivery_channel)||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) responsedescription,
                              to_char(nvl(a.amount, 0), '9,999,999,990.99') transactionamount,
                              decode(decode(cr_dr_flag,
                                            NULL,
                                            ctm_credit_debit_flag,
                                            cr_dr_flag),
                                     'CR',
                                     'Credit',
                                     'DR',
                                     'Debit',
                                     'NA') crdrflag,
                              (SELECT g.gcm_curr_name
                                 FROM vmscms.gen_curr_mast g
                                WHERE g.gcm_inst_code = a.instcode
                                  AND g.gcm_curr_code = a.currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN a.customer_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN a.topup_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN a.customer_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN a.topup_acct_no = d.cam_acct_no THEN
                                  to_char(nvl(a.topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              a.fee_plan feeplanid,
                              a.feecode feeid,
                              to_char(nvl(a.tranfee_amt, 0),
                                      '9,999,999,990.99') feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                               a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              , :p_token_in TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              (SELECT cap_pan_code, cam_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_cust_acct,
                                      vmscms.cms_acct_mast,
                                      vmscms.cms_appl_pan
                                WHERE cca_inst_code = cap_inst_code
                                  AND cca_cust_code = cap_cust_code
                                  and cca_acct_id = cam_acct_id
                                  AND cca_cust_code = :l_cust_code
                                  and cam_inst_code = 1
                                  and cam_type_code = '2') d,
                              vmscms.cms_transaction_mast b,
                              vmscms.cms_delchannel_mast c,
                              vmscms.cms_transaction_log_dtl e
                        WHERE b.ctm_inst_code = a.instcode
                          AND b.ctm_tran_code = a.txn_code
                          AND b.ctm_delivery_channel = a.delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                          AND a.customer_card_no = cap_pan_code
                          AND a.instcode = c.cdm_inst_code
                          AND a.delivery_channel = c.cdm_channel_code
                          AND (a.customer_acct_no = d.cam_acct_no OR
                              (a.topup_acct_no = d.cam_acct_no))
                          AND ((customer_card_no = d.cap_pan_code) OR
                              (topup_card_no = d.cap_pan_code))
                          -- CFIP-255
                          /*
                          AND (((to_number(nvl(a.total_amount, 0)) > 0 OR
                              to_number(nvl(a.amount, 0)) > 0 OR
                              to_number(nvl(a.tranfee_amt, 0)) > 0)) OR
                              b.ctm_tran_type = 'F')
                            */
                         --    AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                           AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        -- AND add_ins_date <= :l_end_date order by ]' ||
        --l_order_by;
        g_debug.display('test ' || l_account_type);
        g_debug.display('test ' || l_txn_filter_type);
        --Account Type : SPENDING,ALL and Filter Type: ALL
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'ALL' THEN
        --g_debug.display('inside spending');
        l_query := q'[SELECT rrn id,
                             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                            to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss')systemdate,
                              b.cap_mask_pan pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,
                              --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE
                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                              END
							  END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode((SELECT upper(trim(cms_resp_desc))
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
				     upper(trim(error_msg)),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =		--- Modified for VMS-3832 CCA--Decline Reason Code and Description
                                             delivery_channel)||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
                              --decode(decode(cr_dr_flag,
                              --              NULL,
                              --              ctm_credit_debit_flag,
                              --              cr_dr_flag),
                              --       'CR',
                              --       'Credit',
                              --       'DR',
                              --       'Debit',
                              --       'NA') crdrflag,
                          case
                          WHEN customer_card_no =  b.cap_pan_code
                          THEN  DECODE (ctm_credit_debit_flag, 'DR', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'), 'CR', DECODE (nvl(reversal_code,'0'), '0', 'Credit', 'Debit'), 'NA', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'))
                          ELSE  DECODE (CTM_CREDIT_DEBIT_FLAG, 'DR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Credit', 'Debit'), 'CR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Debit', 'Credit'), 'NA', DECODE (NVL(REVERSAL_CODE,'0'), '0',  'Credit','Debit'))
                          END CRDRFLAG,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              CASE
                                 WHEN customer_card_no = b.cap_pan_code
                                      AND topup_card_no = b.cap_pan_code THEN
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                                 WHEN topup_card_no = b.cap_pan_code THEN
                                  '0.00'
                                 ELSE
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                              END feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              ,NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id)) TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                              (SELECT cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                                  vmscms.cms_transaction_log_dtl e
                        WHERE ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                          --AND customer_card_no = b.cap_pan_code
                          AND ( ( CUSTOMER_CARD_NO = B.CAP_PAN_CODE  )
                             OR (topup_card_no  = b.cap_pan_code ) )
                          AND instcode = cdm_inst_code
                          AND instcode = '1'
                          AND delivery_channel = cdm_channel_code
                          AND ((nvl(customer_acct_no, cap_acct_no) =
                              b.cap_acct_no) OR
                              (topup_acct_no = b.cap_acct_no))
                              -- CFIP-255
                          /*AND (((((to_number(nvl(total_amount, 0)) > 0 OR
                              to_number(nvl(amount, 0)) > 0) AND
                              (ctm_tran_type = 'F' OR
                              ctm_preauth_flag = 'Y')) OR
                              to_number(nvl(tranfee_amt, 0)) > 0)) OR
                              (ctm_tran_type = 'F' AND
                              error_msg <> 'CLAW BLACK WAIVED') OR
                              ctm_preauth_flag = 'Y')*/
                            -- AND a.partner_id IN (:l_partner_id)
                           AND add_ins_date >= :l_start_date
                           AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';

        -- AND add_ins_date <= :l_end_date order by ]' ||
    --l_order_by;

    --Account Type : SPENDING,ALL and Filter Type: DECLINED
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'DECLINED' THEN
        l_query := q'[SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                            to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                             b.cap_mask_pan pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,
                              --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode((SELECT upper(trim(cms_resp_desc))
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
				     upper(trim(error_msg)),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =		--- Modified for VMS-3832 CCA--Decline Reason Code and Description
                                             delivery_channel)||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
--                              decode(decode(cr_dr_flag,
--                                            NULL,
--                                            ctm_credit_debit_flag,
--                                            cr_dr_flag),
--                                     'CR',
--                                     'Credit',
--                                     'DR',
--                                     'Debit',
--                                     'NA') CRDRFLAG,
                           case
                           WHEN customer_card_no =  b.cap_pan_code
                           THEN  DECODE (ctm_credit_debit_flag, 'DR', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'), 'CR', DECODE (nvl(reversal_code,'0'), '0', 'Credit', 'Debit'), 'NA', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'))
                           ELSE  DECODE (CTM_CREDIT_DEBIT_FLAG, 'DR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Credit', 'Debit'), 'CR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Debit', 'Credit'), 'NA', DECODE (NVL(REVERSAL_CODE,'0'), '0',  'Credit','Debit'))
                           END CRDRFLAG,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              CASE
                                 WHEN customer_card_no = b.cap_pan_code
                                      AND topup_card_no = b.cap_pan_code THEN
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                                 WHEN topup_card_no = b.cap_pan_code THEN
                                  '0.00'
                                 ELSE
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                              END feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              ,NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id) ) TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                              (SELECT cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                               vmscms.cms_transaction_log_dtl e
                        WHERE ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                         -- AND CUSTOMER_CARD_NO = B.CAP_PAN_CODE
                          AND ( ( CUSTOMER_CARD_NO = B.CAP_PAN_CODE  )
                             OR (topup_card_no  = b.cap_pan_code ) )
                          AND instcode = cdm_inst_code
                          AND delivery_channel = cdm_channel_code
                          AND ((nvl(customer_acct_no, cap_acct_no) =
                              b.cap_acct_no) OR
                              (topup_acct_no = b.cap_acct_no))
                          AND (((((to_number(nvl(total_amount, 0)) > 0 OR
                              to_number(nvl(amount, 0)) > 0) AND
                              (ctm_tran_type = 'F' OR
                              ctm_preauth_flag = 'Y')) OR
                              to_number(nvl(tranfee_amt, 0)) > 0)) OR
                              (ctm_tran_type = 'F' AND
                              error_msg <> 'CLAW BLACK WAIVED') OR
                              ctm_preauth_flag = 'Y')
                          AND response_code <> '00'
                            -- AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        -- AND add_ins_date <= :l_end_date order by ]' ||
    --l_order_by;

    --Account Type : SPENDING,ALL and Filter Type: POSTED
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'POSTED' THEN

        l_query := q'[SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                           to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                              b.cap_mask_pan pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,
                              --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode((SELECT cms_resp_desc
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel)) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
--                              decode(decode(cr_dr_flag,
--                                            NULL,
--                                            ctm_credit_debit_flag,
--                                            cr_dr_flag),
--                                     'CR',
--                                     'Credit',
--                                     'DR',
--                                     'Debit',
--                                     'NA') CRDRFLAG,
                           case
                 WHEN customer_card_no =  b.cap_pan_code
   THEN  DECODE (ctm_credit_debit_flag, 'DR', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'), 'CR', DECODE (nvl(reversal_code,'0'), '0', 'Credit', 'Debit'), 'NA', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'))
                  ELSE  DECODE (CTM_CREDIT_DEBIT_FLAG, 'DR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Credit', 'Debit'), 'CR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Debit', 'Credit'), 'NA', DECODE (NVL(REVERSAL_CODE,'0'), '0',  'Credit','Debit'))
   END CRDRFLAG,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              CASE
                                 WHEN customer_card_no = b.cap_pan_code
                                      AND topup_card_no = b.cap_pan_code THEN
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                                 WHEN topup_card_no = b.cap_pan_code THEN
                                  '0.00'
                                 ELSE
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                              END feeamount,
                              CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              ,NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id) ) TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                              (SELECT cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                                  vmscms.cms_transaction_log_dtl e
                        WHERE ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                         -- AND CUSTOMER_CARD_NO = B.CAP_PAN_CODE
                          AND ( ( CUSTOMER_CARD_NO = B.CAP_PAN_CODE  )
                             OR (topup_card_no  = b.cap_pan_code ) )
                          AND instcode = cdm_inst_code
                          and instcode = 1
                          AND delivery_channel = cdm_channel_code
                          AND ((nvl(customer_acct_no, cap_acct_no) =
                              b.cap_acct_no) OR
                              (topup_acct_no = b.cap_acct_no))
                          AND (((((to_number(nvl(total_amount, 0)) > 0 OR
                              to_number(nvl(amount, 0)) > 0) AND
                              (ctm_tran_type = 'F' OR
                              ctm_preauth_flag = 'Y')) OR
                              to_number(nvl(tranfee_amt, 0)) > 0)) OR
                              (ctm_tran_type = 'F' AND
                              error_msg <> 'CLAW BLACK WAIVED') OR
                              ctm_preauth_flag = 'Y')
                          AND response_code = '00'
                          --   AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                           AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        -- AND add_ins_date <= :l_end_date order by ]' ||
    --l_order_by;
    --Account Type : SPENDING,ALL and Filter Type: PREAUTH
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'PREAUTH' THEN
        l_query := q'[SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                            to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                              b.cap_mask_pan pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,
                              --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode((SELECT upper(trim(cms_resp_desc))
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
				     upper(trim(error_msg)),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =		--- Modified for VMS-3832 CCA--Decline Reason Code and Description
                                             delivery_channel)||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
                              decode(decode(cr_dr_flag,
                                            NULL,
                                            ctm_credit_debit_flag,
                                            cr_dr_flag),
                                     'CR',
                                     'Credit',
                                     'DR',
                                     'Debit',
                                     'NA') crdrflag,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              to_char(nvl(acct_balance, 0),
                                      '9,999,999,990.99') availablebalance,
                              to_char(nvl(ledger_balance, 0),
                                      '9,999,999,990.99') ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              to_char(nvl(tranfee_amt, 0),
                                      '9,999,999,990.99') feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              ,NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id) ) TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                              (SELECT cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                              vmscms.cms_transaction_log_dtl e
                        WHERE ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                          AND customer_card_no = b.cap_pan_code
                          AND instcode = cdm_inst_code
                          and instcode = 1
                          AND delivery_channel = cdm_channel_code
                          AND nvl(customer_acct_no, cap_acct_no) =
                              b.cap_acct_no
                          AND (ctm_preauth_flag = 'Y' OR
                              ctm_initial_preauth_ind = 'Y')
                            -- AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                           AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        -- AND add_ins_date <= :l_end_date order by ]' ||
    --l_order_by;

    --Account Type : SPENDING,ALL and Filter Type: ADMIN
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'ADMIN' THEN
        l_query := q'[SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                            to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                              REPLACE(vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(customer_card_no_encr)),
                        '*',
                        'X') pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,
                                --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode((SELECT cms_resp_desc
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel)) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
--                              decode(decode(cr_dr_flag,
--                                            NULL,
--                                            ctm_credit_debit_flag,
--                                            cr_dr_flag),
--                                     'CR',
--                                     'Credit',
--                                     'DR',
--                                     'Debit',
--                                     'NA') CRDRFLAG,
                           case
                 WHEN customer_card_no =  b.cap_pan_code
   THEN  DECODE (ctm_credit_debit_flag, 'DR', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'), 'CR', DECODE (nvl(reversal_code,'0'), '0', 'Credit', 'Debit'), 'NA', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'))
                  ELSE  DECODE (CTM_CREDIT_DEBIT_FLAG, 'DR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Credit', 'Debit'), 'CR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Debit', 'Credit'), 'NA', DECODE (NVL(REVERSAL_CODE,'0'), '0',  'Credit','Debit'))
   END CRDRFLAG,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              to_char(nvl(acct_balance, 0),
                                      '9,999,999,990.99') availablebalance,
                              to_char(nvl(ledger_balance, 0),
                                      '9,999,999,990.99') ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              to_char(nvl(tranfee_amt, 0),
                                      '9,999,999,990.99') feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId, -- added for VMS-744 (sending Merchant and Location details to CCA)
                              :p_token_in TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                          FROM vmscms.transactionlog a,
                               vmscms.cms_transaction_mast,
                               vmscms.cms_delchannel_mast,
                               (SELECT cap_pan_code
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                               vmscms.cms_transaction_log_dtl e
                        WHERE ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                          AND customer_card_no = b.cap_pan_code
                          AND instcode = cdm_inst_code
                          AND instcode =1
                          AND delivery_channel = cdm_channel_code
                          AND to_number(nvl(total_amount, 0)) > 0
                          AND (((to_number(nvl(total_amount, 0)) > 0 OR
                              to_number(nvl(amount, 0)) > 0 OR
                              to_number(nvl(tranfee_amt, 0)) > 0)) OR
                              ctm_tran_type = 'F' OR ctm_preauth_flag = 'Y')
                          AND response_code = '00'
                          AND ((delivery_channel = '03' AND
                              txn_code IN ('13', '14')) OR
                              (delivery_channel = '04' AND
                              txn_code IN ('92', '93')))
                           -- AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                           AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        -- AND add_ins_date <= :l_end_date order by ]' ||
    --l_order_by;

    --Account Type : SPENDING,ALL and Filter Type: ACH
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'ACH' THEN
        l_query := q'[SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                           to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                             REPLACE(vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(customer_card_no_encr)),
                        '*',
                        'X') pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,
                                --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode((SELECT upper(trim(cms_resp_desc))
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
				     upper(trim(error_msg)),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =		--- Modified for VMS-3832 CCA--Decline Reason Code and Description
                                             delivery_channel)||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
                              decode(decode(cr_dr_flag,
                                            NULL,
                                            ctm_credit_debit_flag,
                                            cr_dr_flag),
                                     'CR',
                                     'Credit',
                                     'DR',
                                     'Debit',
                                     'NA') crdrflag,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              to_char(nvl(acct_balance, 0),
                                      '9,999,999,990.99') availablebalance,
                              to_char(nvl(ledger_balance, 0),
                                      '9,999,999,990.99') ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              to_char(nvl(tranfee_amt, 0),
                                      '9,999,999,990.99') feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              ,:p_token_in TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                               (SELECT cap_pan_code
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                              vmscms.cms_transaction_log_dtl e
                        WHERE ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                          AND customer_card_no = b.cap_pan_code
                          AND instcode = cdm_inst_code
                          AND instcode = 1
                          AND delivery_channel = cdm_channel_code
                          AND delivery_channel = 11
                          AND (((to_number(nvl(total_amount, 0)) > 0 OR
                              to_number(nvl(amount, 0)) > 0 OR
                              to_number(nvl(tranfee_amt, 0)) > 0)) OR
                              ctm_tran_type = 'F' OR ctm_preauth_flag = 'Y')
                          --   AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        --order by ]' || l_order_by;

    --Account Type : SPENDING,ALL and Filter Type: HOLDS
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'HOLDS' THEN
        l_query := q'[SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                             to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                              REPLACE(vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(customer_card_no_encr)),
                        '*',
                        'X') pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,
                                --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode((SELECT cms_resp_desc
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel)) responsedescription,
                              to_char(nvl(cpt_totalhold_amt, 0),
                                      '9,999,999,990.99') transactionamount,
                              decode(decode(cr_dr_flag,
                                            NULL,
                                            ctm_credit_debit_flag,
                                            cr_dr_flag),
                                     'CR',
                                     'Credit',
                                     'DR',
                                     'Debit',
                                     'NA') crdrflag,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              to_char(nvl(acct_balance, 0),
                                      '9,999,999,990.99') availablebalance,
                              to_char(nvl(ledger_balance, 0),
                                      '9,999,999,990.99') ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              to_char(nvl(tranfee_amt, 0),
                                      '9,999,999,990.99') feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              ,NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id) ) TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
                       e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_preauth_transaction,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                              (SELECT cap_pan_code
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                              vmscms.cms_transaction_log_dtl e
                        WHERE instcode = cpt_inst_code
                          AND customer_card_no = cpt_card_no
                          AND rrn = cpt_rrn
                          AND business_date = cpt_txn_date
                          AND business_time = cpt_txn_time
                          AND instcode = ctm_inst_code
                          AND txn_code = ctm_tran_code
                          AND delivery_channel = ctm_delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                          AND instcode = cdm_inst_code
                          AND delivery_channel = cdm_channel_code
                          AND cpt_card_no = b.cap_pan_code
                          AND cpt_preauth_validflag = 'Y'
                          AND cpt_completion_flag = 'N'
                          AND cpt_expiry_flag = 'N'
                          AND cpt_totalhold_amt > 0
                          AND ctm_preauth_flag = 'Y'
                          AND ctm_initial_preauth_ind = 'Y'
                          AND response_code = '00'
                          AND ctm_credit_debit_flag = 'NA'
                          AND reversal_code = 0
                          AND upper(TRIM(error_msg)) = 'OK'
                        --     AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        --order by ]' || l_order_by;

    --Account Type : SPENDING,ALL and Filter Type: SETTLED
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'SETTLED' THEN
        l_query := q'[SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                            to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                             b.cap_mask_pan pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,
                                --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode((SELECT cms_resp_desc
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel)) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
--                              decode(decode(cr_dr_flag,
--                                            NULL,
--                                            ctm_credit_debit_flag,
--                                            cr_dr_flag),
--                                     'CR',
--                                     'Credit',
--                                     'DR',
--                                     'Debit',
--                                     'NA') CRDRFLAG,
                           case
                 WHEN customer_card_no =  b.cap_pan_code
   THEN  DECODE (ctm_credit_debit_flag, 'DR', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'), 'CR', DECODE (nvl(reversal_code,'0'), '0', 'Credit', 'Debit'), 'NA', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'))
                  ELSE  DECODE (CTM_CREDIT_DEBIT_FLAG, 'DR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Credit', 'Debit'), 'CR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Debit', 'Credit'), 'NA', DECODE (NVL(REVERSAL_CODE,'0'), '0',  'Credit','Debit'))
   END CRDRFLAG,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              CASE
                                 WHEN customer_card_no = b.cap_pan_code
                                      AND topup_card_no = b.cap_pan_code THEN
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                                 WHEN topup_card_no = b.cap_pan_code THEN
                                  '0.00'
                                 ELSE
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                              END feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              ,NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id) ) TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                              (SELECT cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                              vmscms.cms_transaction_log_dtl e
                        WHERE ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                         -- AND CUSTOMER_CARD_NO = B.CAP_PAN_CODE
                          AND ( ( CUSTOMER_CARD_NO = B.CAP_PAN_CODE  )
                             OR (topup_card_no  = b.cap_pan_code ) )
                          AND instcode = cdm_inst_code
                          and instcode = 1
                          AND delivery_channel = cdm_channel_code
                          AND ((nvl(customer_acct_no, cap_acct_no) =
                              b.cap_acct_no) OR
                              (topup_acct_no = b.cap_acct_no))
                          AND (((((to_number(nvl(total_amount, 0)) > 0 OR
                              to_number(nvl(amount, 0)) > 0) AND
                              (ctm_tran_type = 'F' OR
                              ctm_preauth_flag = 'Y')) OR
                              to_number(nvl(tranfee_amt, 0)) > 0)) OR
                              (ctm_tran_type = 'F' AND
                              error_msg <> 'CLAW BLACK WAIVED') OR
                              ctm_preauth_flag = 'Y')
                          AND response_code = '00'
                          AND (CASE
                                 WHEN ((delivery_channel IN ('02', '03') AND
                                      txn_code = '11') OR (delivery_channel = '05' AND
                                      txn_code = '24'))
                                      AND nvl(tranfee_amt, 0) <= 0 THEN
                                  0
                                 ELSE
                                  1
                              END) = (CASE
                                 WHEN ((delivery_channel IN ('02', '03') AND
                                      txn_code = '11') OR (delivery_channel = '05' AND
                                      txn_code = '24'))
                                      AND nvl(tranfee_amt, 0) <= 0 THEN
                                  2
                                 ELSE
                                  1
                              END)
                           --  AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        --order by ]' || l_order_by;

    --Account Type : SPENDING,ALL and Filter Type: FEES
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'FEES' THEN
        l_query := q'[SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                           to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                             b.cap_mask_pan pan,
                              delivery_channel deliverychannelcode,
                              (SELECT cdm_channel_desc
                                 FROM vmscms.cms_delchannel_mast
                                WHERE cdm_channel_code = delivery_channel) deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,

                              ----start DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              -- initcap(csl_trans_narrration) transactiondescription,
                          CASE  WHEN REGEXP_LIKE(CSL_TRANS_NARRRATION, '/')
                          THEN
                          REPLACE (SUBSTR(INITCAP(CSL_TRANS_NARRRATION),1,INSTR(INITCAP(CSL_TRANS_NARRRATION),'/',1)-1),'Clawback-')
                          || DECODE(UPPER(SUBSTR(CSL_TRANS_NARRRATION,1,9)),'CLAWBACK-',(SELECT INITCAP(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=CSL_PROD_CODE AND CPC_CARD_TYPE = csl_card_type),'')
                          ELSE
                          INITCAP(REPLACE(UPPER(CSL_TRANS_NARRRATION),'CLAWBACK-')) || DECODE(UPPER(SUBSTR(CSL_TRANS_NARRRATION,1,9)),'CLAWBACK-',(SELECT INITCAP(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=CSL_PROD_CODE AND CPC_CARD_TYPE = csl_card_type),'')
                           --END
						   END AS transactiondescription  ,
                              --End DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode(response_code,
                                     '00',
                                     'Approved',
                                     'Decline') responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
                              decode(decode(cr_dr_flag,
                                            NULL,
                                            ctm_credit_debit_flag,
                                            cr_dr_flag),
                                     'CR',
                                     'Credit',
                                     'DR',
                                     'Debit',
                                     'NA') CRDRFLAG,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              to_char(nvl(acct_balance, 0),
                                      '9,999,999,990.99') availablebalance,
                              to_char(nvl(ledger_balance, 0),
                                      '9,999,999,990.99') ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              to_char(nvl(tranfee_amt, 0),
                                      '9,999,999,990.99') feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                             ,NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id) ) TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_statements_log,
                              vmscms.cms_transaction_mast,
                              (SELECT  cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                              vmscms.cms_transaction_log_dtl e
                          WHERE csl_acct_no = b.cap_acct_no
                          AND csl_inst_code = instcode
                          AND  csl_pan_no = b.cap_pan_code
                          AND  csl_pan_no = customer_card_no
                          and instcode =  1
                          AND  csl_rrn = rrn
                          AND csl_business_date = business_date
                          AND  csl_business_time = business_time
                          AND  csl_delivery_channel = delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                          AND csl_txn_code = txn_code
                          AND ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND fee_reversal_flag IN ('N', 'Y')
                          AND tranfee_amt > 0
                          AND  txn_fee_flag = 'Y'
                            -- AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        --order by ]' || l_order_by;
    --Filter Type: ACCOUNTACTIVITY
      WHEN l_txn_filter_type = 'ACCOUNTACTIVITY' THEN
        l_query := q'[SELECT rrn id,
                              --to_char(to_date(business_date || ' ' ||
                              --                business_time,
                              --                'yyyymmdd hh24miss'),
                              --        'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                            to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                              b.cap_mask_pan pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,
                                --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode((SELECT upper(trim(cms_resp_desc))
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
				     upper(trim(error_msg)),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =    --- Modified for VMS-3832 CCA--Decline Reason Code and Description
                                             delivery_channel)||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
                              --CFIP 375, Account activity will have either Debit or NA for crdr flag
                              decode(decode(cr_dr_flag,
                                            NULL,
                                            ctm_credit_debit_flag,
                                            cr_dr_flag),
                                     'DR',
                                     'Debit',
                                     'NA') CRDRFLAG,
                             -- commented below code for CFIP 375
--                           case
--                 WHEN customer_card_no =  b.cap_pan_code
--   THEN  DECODE (ctm_credit_debit_flag, 'DR', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'), 'CR', DECODE (nvl(reversal_code,'0'), '0', 'Credit', 'Debit'), 'NA', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'))
--                  ELSE  DECODE (CTM_CREDIT_DEBIT_FLAG, 'DR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Credit', 'Debit'), 'CR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Debit', 'Credit'), 'NA', DECODE (NVL(REVERSAL_CODE,'0'), '0',  'Credit','Debit'))
--   END CRDRFLAG,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              CASE
                                 WHEN customer_card_no = b.cap_pan_code
                                      AND topup_card_no = b.cap_pan_code THEN
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                                 WHEN topup_card_no = b.cap_pan_code THEN
                                  '0.00'
                                 ELSE
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                              END feeamount,
                               CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                              ,NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id) ) TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			      DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog       a,
                              vmscms.cms_appl_pan         b,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                              vmscms.cms_transaction_log_dtl e
                         WHERE cap_cust_code = :l_cust_code
                         AND customer_card_no = cap_pan_code
                         and delivery_channel = ctm_delivery_channel
                         AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                         and txn_code = ctm_tran_code
                         and instcode = ctm_inst_code
                          AND instcode = cdm_inst_code
                          and instcode = 1
                          AND delivery_channel = cdm_channel_code
                          AND (ctm_tran_type = 'N' OR
                              (ctm_delivery_channel = '05' AND
                              ctm_tran_code IN ('16', '17', '18', '97') AND
                              error_msg = 'CLAW BLACK WAIVED' AND
                              ctm_tran_type = 'F'))
                          AND ctm_preauth_flag = 'N'
                          --   AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        --order by ]' || l_order_by;

    --- Transaction fileter is isdisputable
    --Account Type : SPENDING,ALL and Filter Type: POSTED
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'ISDISPUTABLE' THEN
        l_query := q'[SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                            to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
                             b.cap_mask_pan pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              txn_code transactioncode,
                                --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              --CASE
                                 --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc) ||
                                  --decode(a.clawback_indicator,
                                   --      'Y',
                                   --      ' CLAWBACK FEE')
                                 --ELSE
                                  --decode(a.trans_desc,
                                  --       NULL,
                                  --       ctm_tran_desc,
                                  --       trans_desc || ' Reversal')
                              --END transactiondescription,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE

                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                                END
								END transactiondescription,
                              --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                              response_code responsecode,
                              decode((SELECT cms_resp_desc
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel)) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
                              decode(decode(cr_dr_flag,
                                            NULL,
                                            ctm_credit_debit_flag,
                                            cr_dr_flag),
                                     'CR',
                                     'Credit',
                                     'DR',
                                     'Debit',
                                     'NA') crdrflag,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              CASE
                                 WHEN customer_card_no = b.cap_pan_code
                                      AND topup_card_no = b.cap_pan_code THEN
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                                 WHEN topup_card_no = b.cap_pan_code THEN
                                  '0.00'
                                 ELSE
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                              END feeamount,
                              CASE --dispute
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              a.merchant_id merchantid ,--APLS-607
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
                             ,:p_token_in TOKEN,
                              a.ani Ani,
			      decode(a.network_settl_date,
				                     NULL,
				                     a.network_settl_date,
				                     to_char(to_date(a.network_settl_date || ' 000000',
				                                     'yyyymmdd hh24miss'),
				                                     'yyyy-mm-dd hh24:mi:ss')) settlementDate,
			            DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                              (SELECT cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                              vmscms.cms_transaction_log_dtl e
                        WHERE ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                         -- AND CUSTOMER_CARD_NO = B.CAP_PAN_CODE
                          AND ( ( CUSTOMER_CARD_NO = B.CAP_PAN_CODE  )
                             OR (topup_card_no  = b.cap_pan_code ) )
                          AND instcode = cdm_inst_code
                          AND delivery_channel = cdm_channel_code
                          AND ((nvl(customer_acct_no, cap_acct_no) =
                              b.cap_acct_no) OR
                              (topup_acct_no = b.cap_acct_no))
                          AND (((((to_number(nvl(total_amount, 0)) > 0 OR
                              to_number(nvl(amount, 0)) > 0) AND
                              (ctm_tran_type = 'F' OR
                              ctm_preauth_flag = 'Y')) OR
                              to_number(nvl(tranfee_amt, 0)) > 0)) OR
                              (ctm_tran_type = 'F' AND
                              error_msg <> 'CLAW BLACK WAIVED') OR
                              ctm_preauth_flag = 'Y')
                          AND response_code = '00'
                          and a.delivery_channel IN ('01', '02')
                          AND ctm_credit_debit_flag IN ('DR', 'CR')
                          AND ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0))
                          AND dispute_flag IS NULL
                           --  AND a.partner_id IN (:l_partner_id)
                          AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        --AND add_ins_date <= :l_end_date order by ]' ||
    --l_order_by;

    --account TYPE :spending AND filter type isindispute
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'ISINDISPUTE' THEN
        l_query := q'[SELECT a.rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                             CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
      to_char(a.add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
       b.cap_mask_pan pan,
       a.delivery_channel deliverychannelcode,
       d.cdm_channel_desc deliverychanneldescription,
       nvl(a.merchant_name,
           decode(a.delivery_channel,
                  '01',
                  'ATM',
                  '02',
                  'Retail Merchant',
                  '03',
                  'Customer Service',
                  '07',
                  'IVR Transfer',
                  '10',
                  'Card Holder website',
                  '11',
                  'Direct Deposit',
                  '13',
                  'Mobile Transfer',
                  'null')) merchantname,
       a.txn_code transactioncode,
          --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
          --CASE
          --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
          --decode(a.trans_desc,
          --       NULL,
          --       ctm_tran_desc,
          --       trans_desc) ||
          --decode(a.clawback_indicator,
          --      'Y',
          --      ' CLAWBACK FEE')
          --ELSE
          --decode(a.trans_desc,
          --       NULL,
          --       ctm_tran_desc,
          --       trans_desc || ' Reversal')
          --END transactiondescription,
		  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
		  ELSE

          CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
          THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
          DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
          ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
          END
		  END transactiondescription,
          --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
       a.response_code responsecode,
       decode((SELECT cms_resp_desc
                FROM vmscms.cms_response_mast
               WHERE cms_response_id = a.response_id
                 AND cms_delivery_channel = a.delivery_channel),
              NULL,
              nvl(a.error_msg, 'TRANSACTION DECLINED'),
              (SELECT cms_resp_desc
                 FROM vmscms.cms_response_mast
                WHERE cms_response_id = a.response_id
                  AND cms_delivery_channel = a.delivery_channel)) responsedescription,
       to_char(nvl(a.amount, 0), '9,999,999,990.99') transactionamount,
       decode(decode(a.cr_dr_flag, NULL, ctm_credit_debit_flag, cr_dr_flag),
              'CR',
              'Credit',
              'DR',
              'Debit',
              'NA') crdrflag,
       (SELECT gcm_curr_name
          FROM vmscms.gen_curr_mast
         WHERE gcm_inst_code = a.instcode
           AND gcm_curr_code = a.currencycode) currencycode,
       currencycode currencynum,
       CASE
          WHEN (a.customer_card_no = b.cap_pan_code AND
               a.customer_acct_no = b.cap_acct_no) THEN
           to_char(NVL(a.acct_balance, 0), '9,999,999,990.99')
          WHEN (a.topup_card_no = b.cap_pan_code AND
               a.topup_acct_no = b.cap_acct_no) THEN
           to_char(nvl(a.topup_acct_balance, 0), '9,999,999,990.99')
       END availablebalance,
       CASE
          WHEN (a.customer_card_no = b.cap_pan_code AND
               a.customer_acct_no = b.cap_acct_no) THEN
           to_char(nvl(a.ledger_balance, 0), '9,999,999,990.99')
          WHEN (a.topup_card_no = b.cap_pan_code AND
               a.topup_acct_no = b.cap_acct_no) THEN
           to_char(nvl(a.topup_ledger_balance, 0), '9,999,999,990.99')
       END ledgerbalance,
       a.fee_plan feeplanid,
       a.feecode feeid,
       CASE
          WHEN a.customer_card_no = b.cap_pan_code
               AND a.topup_card_no = b.cap_pan_code THEN
           to_char(nvl(a.tranfee_amt, 0), '9,999,999,990.99')
          WHEN a.topup_card_no = b.cap_pan_code THEN
           '0.00'
          ELSE
           to_char(nvl(a.tranfee_amt, 0), '9,999,999,990.99')
       END feeamount,
       CASE --dispute
          WHEN (CASE
                  WHEN a.delivery_channel IN ('01', '02')
                       AND c.ctm_credit_debit_flag IN ('DR', 'CR') THEN
                   decode(a.dispute_flag, NULL, 'N', dispute_flag)
                  ELSE
                   'C'
               END) = 'N'
               AND ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
           'True'
          ELSE
           'False'
       END isdisputable,
       CASE dispute_flag
          WHEN 'Y' THEN
           'True'
          ELSE
           'False'
       END AS indispute,
      a.merchant_id merchantid ,--APLS-607
      a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
      a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
       ,:p_token_in TOKEN,
       a.ani Ani,
       decode(a.network_settl_date,
	                      NULL,
	                      a.network_settl_date,
	                      to_char(to_date(a.network_settl_date || ' 000000',
	                                      'yyyymmdd hh24miss'),
	                                      'yyyy-mm-dd hh24:mi:ss')) settlementDate,
       DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
  FROM vmscms.transactionlog a,
       vmscms.cms_transaction_mast c,
       vmscms.cms_delchannel_mast d,
       (SELECT cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
        FROM vmscms.cms_appl_pan
        WHERE cap_cust_code = :l_cust_code
        AND cap_inst_code = 1) b,
        vmscms.cms_transaction_log_dtl e
 WHERE c.ctm_inst_code = a.instcode
   AND c.ctm_tran_code = a.txn_code
   AND c.ctm_delivery_channel = delivery_channel
   AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
   AND a.customer_card_no = b.cap_pan_code
   AND a.instcode = d.cdm_inst_code
   AND a.delivery_channel = d.cdm_channel_code
   AND ((nvl(a.customer_acct_no, b.cap_acct_no) = b.cap_acct_no) OR
       (a.topup_acct_no = b.cap_acct_no))
   AND (((((to_number(nvl(a.total_amount, 0)) > 0 OR
       to_number(nvl(a.amount, 0)) > 0) AND
       (c.ctm_tran_type = 'F' OR c.ctm_preauth_flag = 'Y')) OR
       to_number(nvl(a.tranfee_amt, 0)) > 0)) OR
       (c.ctm_tran_type = 'F' AND a.error_msg <> 'CLAW BLACK WAIVED') OR
       c.ctm_preauth_flag = 'Y')
   AND a.response_code = '00'
   AND a.dispute_flag = 'Y'
   --AND a.partner_id IN (:l_partner_id)
   AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
    AND a.rrn=e.ctd_rrn(+)
    AND a.business_date=e.ctd_business_date(+)
    AND a.business_time=e.ctd_business_time(+)
    AND a.delivery_channel=e.ctd_delivery_channel(+)
    AND a.customer_card_no=e.ctd_customer_card_no(+)
    AND a.txn_code=e.ctd_txn_code(+)
    AND a.msgtype=e.ctd_msg_type(+)]';
        --order by ]' || l_order_by;

    --account TYPE :spending AND filter TYPE isallfinancial

      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'ALLFINANCIAL' THEN

        l_query := q'[SELECT rrn id,
             --to_char(to_date(a.business_date || ' ' ||
                             --                a.business_time,
                             --              'yyyymmdd hh24miss'),
                             --      'yyyy-mm-dd hh24:mi:ss') businessdate,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
             to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss') systemdate,
       b.cap_mask_pan pan,
       delivery_channel deliverychannelcode,
       cdm_channel_desc deliverychanneldescription,
       nvl(merchant_name,
           decode(delivery_channel,
                  '01',
                  'ATM',
                  '02',
                  'Retail Merchant',
                  '03',
                  'Customer Service',
                  '07',
                  'IVR Transfer',
                  '10',
                  'Card Holder website',
                  '11',
                  'Direct Deposit',
                  '13',
                  'Mobile Transfer',
                  'null')) merchantname,
       txn_code transactioncode,
        --Start  DFCTNM-108 (VMS 3.2.4 integration into CCA)
                --CASE
                   --WHEN to_number(nvl(a.reversal_code, '00')) = 0 THEN
                    --decode(a.trans_desc,
                    --       NULL,
                    --       ctm_tran_desc,
                    --       trans_desc) ||
                    --decode(a.clawback_indicator,
                     --      'Y',
                     --      ' CLAWBACK FEE')
                   --ELSE
                    --decode(a.trans_desc,
                    --       NULL,
                    --       ctm_tran_desc,
                    --       trans_desc || ' Reversal')
                --END transactiondescription,
				CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
				ELSE

                CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                  THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                  DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                  ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                  END
				  END transactiondescription,
                --End  DFCTNM-108 (VMS 3.2.4 integration into CCA)
       response_code responsecode,
       decode((SELECT upper(trim(cms_resp_desc))
                FROM cms_response_mast
               WHERE cms_response_id = response_id
                 AND cms_delivery_channel = delivery_channel),
              NULL,
              nvl(error_msg, 'TRANSACTION DECLINED'),
	      upper(trim(error_msg)),
    	      (SELECT cms_resp_desc
                FROM vmscms.cms_response_mast
                WHERE cms_response_id = response_id
                AND cms_delivery_channel =
                delivery_channel),  --- Modified for VMS-3832 CCA--Decline Reason Code and Description
              (SELECT cms_resp_desc
                 FROM cms_response_mast
                WHERE cms_response_id = response_id
                  AND cms_delivery_channel = delivery_channel)||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) responsedescription,
       to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
       decode(decode(a.cr_dr_flag, NULL, ctm_credit_debit_flag, cr_dr_flag),
              'CR',
              'Credit',
              'DR',
              'Debit',
              'NA') crdrflag,
       (SELECT gcm_curr_name
          FROM gen_curr_mast
         WHERE gcm_inst_code = instcode
           AND gcm_curr_code = currencycode) currencycode,
       currencycode currencynum,
       CASE
          WHEN (customer_card_no = b.cap_pan_code AND
               customer_acct_no = b.cap_acct_no) THEN
           to_char(nvl(acct_balance, 0), '9,999,999,990.99')
          WHEN (topup_card_no = b.cap_pan_code AND
               topup_acct_no = b.cap_acct_no) THEN
           to_char(nvl(topup_acct_balance, 0), '9,999,999,990.99')
       END availablebalance,
       CASE
          WHEN (customer_card_no = b.cap_pan_code AND
               customer_acct_no = b.cap_acct_no) THEN
           to_char(nvl(ledger_balance, 0), '9,999,999,990.99')
          WHEN (topup_card_no = b.cap_pan_code AND
               topup_acct_no = b.cap_acct_no) THEN
           to_char(nvl(topup_ledger_balance, 0), '9,999,999,990.99')
       END ledgerbalance,
       fee_plan feeplanid,
       feecode feeid,
       CASE
          WHEN customer_card_no = b.cap_pan_code
               AND topup_card_no = b.cap_pan_code THEN
           to_char(nvl(tranfee_amt, 0), '9,999,999,990.99')
          WHEN topup_card_no = b.cap_pan_code THEN
           '0.00'
          ELSE
           to_char(nvl(tranfee_amt, 0), '9,999,999,990.99')
       END feeamount,
       CASE
          WHEN (CASE
                  WHEN delivery_channel IN ('01', '02')
                       AND ctm_credit_debit_flag IN ('DR', 'CR')
                       AND response_code = '00' THEN
                   decode(dispute_flag, NULL, 'N', dispute_flag)
                  ELSE
                   'C'
               END) = 'N'
               AND ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
           'True'
          ELSE
           'False'
       END isdisputable,
       CASE dispute_flag
          WHEN 'Y' THEN
           'True'
          ELSE
           'False'
       END AS indispute,
      a.merchant_id merchantid ,--APLS-607
      a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
      a.spil_location_id MerchantStoreDbId -- added for VMS-744 (sending Merchant and Location details to CCA)
       ,NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id) ) TOKEN,
       a.ani Ani,
       decode(a.network_settl_date,
	                      NULL,
	                      a.network_settl_date,
	                      to_char(to_date(a.network_settl_date || ' 000000',
	                                      'yyyymmdd hh24miss'),
	                                      'yyyy-mm-dd hh24:mi:ss')) settlementDate,
       DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
              e.ctd_posentrymode_id POSEntryMode,
              (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
              decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
              a.networkid_switch paymentNetwork
  FROM transactionlog a,
       cms_transaction_mast,
       cms_delchannel_mast,
       (SELECT cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
        FROM vmscms.cms_appl_pan
        WHERE cap_cust_code = :l_cust_code
        AND cap_inst_code = 1) b,
        vmscms.cms_transaction_log_dtl e
 WHERE ctm_inst_code = instcode
   AND ctm_tran_code = txn_code
   AND ctm_delivery_channel = delivery_channel
   AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
  --AND customer_card_no = b.cap_pan_code --VR-9
    AND ( ( CUSTOMER_CARD_NO = B.CAP_PAN_CODE  ) OR (topup_card_no  = b.cap_pan_code ) )
   AND instcode = cdm_inst_code
   AND delivery_channel = cdm_channel_code
   AND ((nvl(customer_acct_no, cap_acct_no) = b.cap_acct_no) OR
       (topup_acct_no = b.cap_acct_no))
   AND (((((to_number(nvl(total_amount, 0)) > 0 OR
       to_number(nvl(amount, 0)) > 0) AND
       (ctm_tran_type = 'F' OR ctm_preauth_flag = 'Y')) OR
       to_number(nvl(tranfee_amt, 0)) > 0)) OR
       (ctm_tran_type = 'F' AND error_msg <> 'CLAW BLACK WAIVED') OR
       ctm_preauth_flag = 'Y')
  -- AND a.partner_id IN (:l_partner_id)
   AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
    AND a.rrn=e.ctd_rrn(+)
    AND a.business_date=e.ctd_business_date(+)
    AND a.business_time=e.ctd_business_time(+)
    AND a.delivery_channel=e.ctd_delivery_channel(+)
    AND a.customer_card_no=e.ctd_customer_card_no(+)
    AND a.txn_code=e.ctd_txn_code(+)
    AND a.msgtype=e.ctd_msg_type(+)]';
        --order by ]' || l_order_by;

    --account TYPE :spending AND filter type isFraudulent
      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'ISFRAUDULENT' THEN

                l_query := q'[SELECT rrn id,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                              to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss')systemdate,
                              b.cap_mask_pan pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              a.merchant_id merchantid,
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId, -- added for VMS-744 (sending Merchant and Location details to CCA)
                              txn_code transactioncode,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE
                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                              END
							  END transactiondescription,
                              response_code responsecode,
                              decode((SELECT upper(trim(cms_resp_desc))
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
				     upper(trim(error_msg)),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel),		--- Modified for VMS-3832 CCA--Decline Reason Code and Description
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel)||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
                          case
                          WHEN customer_card_no =  b.cap_pan_code
                          THEN  DECODE (ctm_credit_debit_flag, 'DR', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'), 'CR', DECODE (nvl(reversal_code,'0'), '0', 'Credit', 'Debit'), 'NA', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'))
                          ELSE  DECODE (CTM_CREDIT_DEBIT_FLAG, 'DR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Credit', 'Debit'), 'CR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Debit', 'Credit'), 'NA', DECODE (NVL(REVERSAL_CODE,'0'), '0',  'Credit','Debit'))
                          END CRDRFLAG,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              CASE
                                 WHEN customer_card_no = b.cap_pan_code
                                      AND topup_card_no = b.cap_pan_code THEN
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                                 WHEN topup_card_no = b.cap_pan_code THEN
                                  '0.00'
                                 ELSE
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                              END feeamount,
                               CASE
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id)) TOKEN,
                              a.ani Ani,
                              decode(a.network_settl_date,
                                                  NULL,
                                                  a.network_settl_date,
                                                  to_char(to_date(a.network_settl_date || ' 000000',
                                                                  'yyyymmdd hh24miss'),
                                                          'yyyy-mm-dd hh24:mi:ss')) settlementDate,
                              DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
                     e.ctd_posentrymode_id POSEntryMode,
                    (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                    where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
                    decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
                    a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                              (SELECT cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                              vmscms.cms_transaction_log_dtl e
                        WHERE ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND NOT(a.delivery_channel = '03' AND a.txn_code = '18')
                          AND ( ( CUSTOMER_CARD_NO = B.CAP_PAN_CODE  )
                             OR (topup_card_no  = b.cap_pan_code ) )
                          AND instcode = cdm_inst_code
                          AND instcode = '1'
                          AND delivery_channel = cdm_channel_code
                          AND ((nvl(customer_acct_no, cap_acct_no) =
                              b.cap_acct_no) OR
                              (topup_acct_no = b.cap_acct_no))
                          AND a.marked_status = 'F'
	AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
        --order by ]' || l_order_by;

      WHEN l_account_type IN ('ALL',
                              'SPENDING')
           AND l_txn_filter_type = 'TOKENPROVISIONINGATTEMPTS' THEN

                l_query := q'[SELECT rrn id,
                              CASE
                              WHEN (BUSINESS_DATE IS NULL or BUSINESS_TIME is null )  THEN
                              TO_CHAR(ADD_INS_DATE,'yyyy-mm-dd hh24:mi:ss')
                              WHEN regexp_like(business_time,'[^0-9]+') THEN
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24:mi:ss'),'yyyy-mm-dd hh24:mi:ss')
                              ELSE
                              to_char(to_date(business_date || ' ' || business_time,'yyyymmdd hh24miss'),'yyyy-mm-dd hh24:mi:ss')
                              END AS businessdate,
                              to_char(add_ins_date, 'yyyy-mm-dd hh24:mi:ss')systemdate,
                              b.cap_mask_pan pan,
                              delivery_channel deliverychannelcode,
                              cdm_channel_desc deliverychanneldescription,
                              nvl(merchant_name,
                                  decode(delivery_channel,
                                         '01',
                                         'ATM',
                                         '02',
                                         'Retail Merchant',
                                         '03',
                                         'Customer Service',
                                         '07',
                                         'IVR Transfer',
                                         '10',
                                         'Card Holder website',
                                         '11',
                                         'Direct Deposit',
                                         '13',
                                         'Mobile Transfer',
                                         'null')) merchantname,
                              a.merchant_id merchantid,
			                  a.merchant_id MerchantDbId, 	-- added for VMS-744 (sending Merchant and Location details to CCA)
			                  a.spil_location_id MerchantStoreDbId, -- added for VMS-744 (sending Merchant and Location details to CCA)
                              txn_code transactioncode,
							  CASE WHEN (select count(1) from vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
                                                                AND VPT_CARD_TYPE = CATEGORYID
                                                                AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                AND VPT_TXN_CODE = TXN_CODE
                                                                ) = 1 THEN
									(SELECT DECODE(NVL (REVERSAL_CODE,'0'),'0',
									REPLACE (REPLACE (VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)),
										REPLACE (REPLACE ('RVSL - '||VPT_TXNDESC_FORMAT,'email of sender',vmscms.vms_transaction.get_email_id('1',CUSTOMER_CARD_NO)),
																'email of recipient',vmscms.vms_transaction.get_email_id('1',TOPUP_CARD_NO)))	FROM vmscms.VMS_PRODUCT_CUSTOM_TRANDESC where VPT_PROD_CODE = PRODUCTID
																				AND VPT_CARD_TYPE = CATEGORYID
																				AND VPT_DELIVERY_CHANNEL = DELIVERY_CHANNEL
																				AND VPT_TXN_CODE = TXN_CODE)
							ELSE
                              CASE  WHEN TO_NUMBER(NVL(REVERSAL_CODE,'00')) = 0
                                THEN  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC,UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC, REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) ||
                                DECODE (CLAWBACK_INDICATOR, 'Y', (SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '|| CPC_CLAWBACK_DESC)) FROM VMSCMS.CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=PRODUCTID AND CPC_CARD_TYPE = CATEGORYID))
                                ELSE  DECODE (UPPER(TRIM(TRANS_DESC)), NULL,CTM_DISPLAY_TXNDESC, UPPER(TRIM(CTM_TRAN_DESC)),CTM_DISPLAY_TXNDESC,  REPLACE(UPPER(TRANS_DESC),'CLAWBACK-') ) || ' Reversal'
                              END
							  END transactiondescription,
                              response_code responsecode,
                              decode((SELECT upper(trim(cms_resp_desc))
                                       FROM vmscms.cms_response_mast
                                      WHERE cms_response_id = response_id
                                        AND cms_delivery_channel =
                                            delivery_channel),
                                     NULL,
                                     nvl(error_msg, 'TRANSACTION DECLINED'),
				     upper(trim(error_msg)),
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel),		--- Modified for VMS-3832 CCA--Decline Reason Code and Description
                                     (SELECT cms_resp_desc
                                        FROM vmscms.cms_response_mast
                                       WHERE cms_response_id = response_id
                                         AND cms_delivery_channel =
                                             delivery_channel)||DECODE(response_code,'00','',DECODE(nvl(regexp_instr(error_msg,'ORA-',1,1,0,'i'),1),0,' - '||ERROR_MSG))) responsedescription,
                              to_char(nvl(amount, 0), '9,999,999,990.99') transactionamount,
                          case
                          WHEN customer_card_no =  b.cap_pan_code
                          THEN  DECODE (ctm_credit_debit_flag, 'DR', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'), 'CR', DECODE (nvl(reversal_code,'0'), '0', 'Credit', 'Debit'), 'NA', DECODE (nvl(reversal_code,'0'), '0', 'Debit', 'Credit'))
                          ELSE  DECODE (CTM_CREDIT_DEBIT_FLAG, 'DR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Credit', 'Debit'), 'CR', DECODE (NVL(REVERSAL_CODE,'0'), '0', 'Debit', 'Credit'), 'NA', DECODE (NVL(REVERSAL_CODE,'0'), '0',  'Credit','Debit'))
                          END CRDRFLAG,
                              (SELECT gcm_curr_name
                                 FROM vmscms.gen_curr_mast
                                WHERE gcm_inst_code = instcode
                                  AND gcm_curr_code = currencycode) currencycode,
                              currencycode currencynum,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(acct_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_acct_balance, 0),
                                          '9,999,999,990.99')
                              END availablebalance,
                              CASE
                                 WHEN (customer_card_no = b.cap_pan_code AND
                                      customer_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(ledger_balance, 0),
                                          '9,999,999,990.99')
                                 WHEN (topup_card_no = b.cap_pan_code AND
                                      topup_acct_no = b.cap_acct_no) THEN
                                  to_char(nvl(topup_ledger_balance, 0),
                                          '9,999,999,990.99')
                              END ledgerbalance,
                              fee_plan feeplanid,
                              feecode feeid,
                              CASE
                                 WHEN customer_card_no = b.cap_pan_code
                                      AND topup_card_no = b.cap_pan_code THEN
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                                 WHEN topup_card_no = b.cap_pan_code THEN
                                  '0.00'
                                 ELSE
                                  to_char(nvl(tranfee_amt, 0),
                                          '9,999,999,990.99')
                              END feeamount,
                               CASE
                                 WHEN (CASE
                                         WHEN delivery_channel IN ('01', '02')
                                              AND
                                              ctm_credit_debit_flag IN ('DR', 'CR') THEN
                                          decode(dispute_flag,
                                                 NULL,
                                                 'N',
                                                 dispute_flag)
                                         ELSE
                                          'C'
                                      END) = 'N'
                                      AND
                                      ((trunc(SYSDATE - a.add_ins_date) < to_number(:l_chargeback_val)) OR (to_number(:l_chargeback_val) <= 0)) THEN
                                  'True'
                                 ELSE
                                  'False'
                              END isdisputable,
                              CASE dispute_flag
                                 WHEN 'Y' THEN
                                  'True'
                                 ELSE
                                  'False'
                              END AS indispute,
                              NVL(:p_token_in,
                                   vmscms.gpp_transaction.get_transaction_token(a.customer_card_no,
                                                         a.rrn,
                                                         a.auth_id)) TOKEN,
                              a.ani Ani,
                              decode(a.network_settl_date,
                                                  NULL,
                                                  a.network_settl_date,
                                                  to_char(to_date(a.network_settl_date || ' 000000',
                                                                  'yyyymmdd hh24miss'),
                                                          'yyyy-mm-dd hh24:mi:ss')) settlementDate,
                              DECODE(a.marked_status,'F','TRUE','FALSE') isFraudulent,
                       e.ctd_posentrymode_id POSEntryMode,
                       (select vpm_posentrymode_desc from VMSCMS.vms_posentrymode_mast
                        where trim(vpm_posentry_id)=trim(e.ctd_posentrymode_id)) POSEntryModeDescription,
                        decode(e.ctd_cnp_indicator,'0','Card Not Present','1','Card Present','Card Indicator Not Available') isCardPresent,
                       a.networkid_switch paymentNetwork
                         FROM vmscms.transactionlog a,
                              vmscms.cms_transaction_mast,
                              vmscms.cms_delchannel_mast,
                              (SELECT cap_pan_code, cap_acct_no, vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(cap_pan_code_encr)) cap_mask_pan
                                 FROM vmscms.cms_appl_pan
                                WHERE cap_cust_code = :l_cust_code
                                  AND cap_inst_code = 1) b,
                              vmscms.cms_transaction_log_dtl e
                        WHERE ctm_inst_code = instcode
                          AND ctm_tran_code = txn_code
                          AND ctm_delivery_channel = delivery_channel
                          AND ( ( CUSTOMER_CARD_NO = B.CAP_PAN_CODE  )
                             OR (topup_card_no  = b.cap_pan_code ) )
                          AND instcode = cdm_inst_code
                          AND instcode = '1'
                          AND delivery_channel = cdm_channel_code
                          AND ((nvl(customer_acct_no, cap_acct_no) =
                              b.cap_acct_no) OR
                              (topup_acct_no = b.cap_acct_no))
                          AND delivery_channel = '16'
                          AND txn_code IN ('01','11','16')
                          AND add_ins_date >= :l_start_date
                          AND add_ins_date <= :l_end_date
                        AND a.rrn=e.ctd_rrn(+)
                        AND a.business_date=e.ctd_business_date(+)
                        AND a.business_time=e.ctd_business_time(+)
                        AND a.delivery_channel=e.ctd_delivery_channel(+)
                        AND a.customer_card_no=e.ctd_customer_card_no(+)
                        AND a.txn_code=e.ctd_txn_code(+)
                        AND a.msgtype=e.ctd_msg_type(+)]';
    END CASE;

    --l_row_query := ') WHERE rownum BETWEEN :l_rec_start_no AND :l_rec_end_no';
    l_row_query := CASE
                     WHEN p_token_in IS NOT NULL THEN
                      ' AND EXISTS  (SELECT 1 FROM vmscms.vms_token_transactionlog c WHERE c.vtt_token=''' ||
                      p_token_in ||
                      ''' AND c.vtt_pan_code = a.customer_card_no
           AND c.vtt_rrn = a.rrn  AND c.vtt_auth_id  = a.auth_id) '
                   END || 'order by ' || l_order_by ||
                   ')txns) WHERE rnum BETWEEN :l_rec_start_no AND :l_rec_end_no';

    --
    --            l_row_query :=
    --
    --                ' AND EXISTS  (SELECT 1 FROM vms_token_transactionlog c WHERE c.vtt_token='''
    --                || p_token_in
    --                || ''' AND c.vtt_pan_code = a.customer_card_no
    --           AND c.vtt_rrn = a.rrn  AND c.vtt_auth_id  = a.auth_id) '
    --
    --          || 'order by '
    --          || l_order_by
    --          || ')txns WHERE rownum BETWEEN :l_rec_start_no AND :l_rec_end_no';

    l_query := l_wrapper_query || l_query || l_row_query;
    dbms_output.put_line('l_query' || l_query);

    IF l_txn_filter_type = 'ISDISPUTABLE' THEN
        OPEN c_transaction_out FOR l_query
          USING l_chargeback_val,l_chargeback_val,p_token_in, l_cust_code, l_chargeback_val,l_chargeback_val,l_start_date, l_end_date, l_rec_start_no, l_rec_end_no;
    ELSE
        OPEN c_transaction_out FOR l_query
          USING l_chargeback_val,l_chargeback_val,p_token_in, l_cust_code, l_start_date, l_end_date, l_rec_start_no, l_rec_end_no;
    END IF;
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
                         vmscms.gpp_const.c_ora_error_status,
                         ' Customer_id - '||p_customer_id_in||
                         ' Acct_type - '||p_acc_type_in||
                         ' Txn_filter - '||p_txn_filter_in);
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
                          vmscms.gpp_const.c_ora_error_status,
                         ' Customer_id - '||p_customer_id_in||
                         ' Acct_type - '||p_acc_type_in||
                         ' Txn_filter - '||p_txn_filter_in);
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
  END get_transaction_history;

  PROCEDURE update_transaction_status(p_customer_id_in       IN VARCHAR2,
                                      p_txn_id_in            IN VARCHAR2,
                                      p_txn_date_in          IN VARCHAR2,
                                      p_delivery_channel_in  IN VARCHAR2,
                                      p_txn_code_in          IN VARCHAR2,
                                      p_response_code_in     IN VARCHAR2,
                                      p_fraudulent_in		     IN VARCHAR2,
                                      p_comment_in		       IN VARCHAR2,
                                      p_status_out           OUT VARCHAR2,
                                      p_err_msg_out          OUT VARCHAR2) AS
    l_field_name        VARCHAR2(50);
    l_api_name          VARCHAR2(30) := 'UPDATE_TRANSACTION_STATUS';
    l_flag              PLS_INTEGER := 0;
    l_hash_pan          vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan          vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_partner_id        vmscms.transactionlog.partner_id%TYPE;
    l_customer          vmscms.cms_cust_mast.ccm_cust_id%TYPE;
    l_date              vmscms.transactionlog.business_date%TYPE;
    l_time              vmscms.transactionlog.business_time%TYPE;
    l_start_time        NUMBER;
    l_end_time          NUMBER;
    l_timetaken         NUMBER;
    l_acct_no           vmscms.cms_appl_pan.cap_acct_no%TYPE;
	  l_rrn               vmscms.transactionlog.rrn%TYPE;
  	l_auth_id           vmscms.transactionlog.auth_id%TYPE;
	  l_stan              vmscms.transactionlog.system_trace_audit_no%TYPE;
	  l_orgnl_stan        vmscms.transactionlog.original_stan%TYPE;
  	l_orgnl_card_no     vmscms.transactionlog.orgnl_card_no%TYPE;
	  l_orgnl_term_id     vmscms.transactionlog.orgnl_terminal_id%TYPE;
	  l_acct_balance      vmscms.cms_acct_mast.cam_acct_bal%TYPE;
    l_ledger_balance    vmscms.cms_acct_mast.cam_ledger_bal%TYPE;
    l_acct_type         vmscms.cms_acct_mast.cam_type_code%TYPE;
    l_card_stat         vmscms.cms_appl_pan.cap_card_stat%TYPE;
    L_Prod_Code         Vmscms.Cms_Appl_Pan.Cap_Prod_Code%Type;
    l_Card_Type         vmscms.cms_appl_pan.cap_card_type%Type;
    l_call_seq          vmscms.cms_calllog_details.ccd_call_seq%TYPE;

  BEGIN
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --Check for mandatory fields
    CASE
      WHEN p_txn_date_in IS NULL THEN
        l_field_name := 'TRANSACTIONDATE';
        l_flag       := 1;
      WHEN p_delivery_channel_in IS NULL THEN
        l_field_name := 'DELIVERYCHANNEL';
        l_flag       := 1;
      WHEN p_txn_code_in IS NULL THEN
        l_field_name := 'TRANSACTIONCODE';
        l_flag       := 1;
      WHEN p_response_code_in IS NULL THEN
        l_field_name := 'RESPONSECODE';
        l_flag       := 1;
      WHEN p_fraudulent_in IS NULL THEN
        l_field_name := 'IS FRADULENT';
        l_flag       := 1;
      WHEN p_comment_in IS NULL THEN
        l_field_name := 'COMMENTS';
        l_flag       := 1;
      ELSE
        NULL;
    END CASE;

    vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                   l_hash_pan,
                                   l_encr_pan,
                                   L_Acct_No);

    IF l_acct_no IS NULL
    THEN
      RAISE no_data_found;
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

      l_date := to_char(to_date(p_txn_date_in,
                                'yyyy-mm-dd hh24:mi:ss'),
                        'yyyymmdd');
      l_time := to_char(to_date(p_txn_date_in,
                                'yyyy-mm-dd hh24:mi:ss'),
                        'hh24miss');

     UPDATE transactionlog
        SET marked_status = decode(UPPER(p_fraudulent_in),'TRUE','F', NULL) , -- Added decode to handle both true and false inputs
            remark =  SUBSTR(remark ||p_comment_in,1,2000)
      WHERE rrn = p_txn_id_in
        AND business_date = l_date
        AND business_time = l_time
        AND delivery_channel = p_delivery_channel_in
        AND txn_code = p_txn_code_in
        AND response_code = p_response_code_in;


     SELECT to_char(to_char(SYSDATE, 'YYMMDDHH24MISS') ||   --Changes VMS-8279 ~ HH has been replaced as HH24
                    lpad(vmscms.seq_deppending_rrn.nextval, 3, '0')),
            lpad(vmscms.seq_auth_id.nextval, 6, '0'),
            lpad(vmscms.seq_auth_stan.nextval, 6, '0')
       INTO l_rrn, l_auth_id, l_stan
       FROM dual;

     SELECT cam_acct_bal,
            cam_ledger_bal,
            cam_type_code
       INTO l_acct_balance,
            l_ledger_balance,
            l_acct_type
       FROM vmscms.cms_acct_mast
      WHERE cam_acct_no = l_acct_no
        AND cam_inst_code = 1;

     SELECT cap_card_stat,
            cap_prod_code,
            cap_card_type
       INTO l_card_stat,
            l_prod_code,
            l_card_type
       FROM vmscms.cms_appl_pan
      WHERE cap_pan_code = l_hash_pan
        AND cap_mbr_numb = '000';

     SELECT system_trace_audit_no,
            customer_card_no,
            terminal_id
       INTO l_orgnl_stan,
            l_orgnl_card_no,
            l_orgnl_term_id
       FROM vmscms.transactionlog
      WHERE rrn = p_txn_id_in
        AND business_date = l_date
        AND business_time = l_time
        AND delivery_channel = p_delivery_channel_in
        AND txn_code = p_txn_code_in
        AND response_code = p_response_code_in;

     --time taken
      g_debug.display('l_rrn' || l_rrn);
      l_end_time := dbms_utility.get_time;
      g_debug.display('l_end_time' || l_end_time);
      l_timetaken := (l_end_time - l_start_time);
      g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
      g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                      ' secs');

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
                         system_trace_audit_no,
                         orgnl_business_date,
                         orgnl_business_time,
                         orgnl_rrn,
                         original_stan,
                         orgnl_card_no,
                         orgnl_terminal_id)
        VALUES
                        ('0200',
                         l_rrn,
                         '03',
                         '72',
                         (SELECT ctm_tran_desc
                          FROM vmscms.cms_transaction_mast
                         WHERE ctm_inst_code = 1
                           AND ctm_tran_code = '72'
                           AND ctm_delivery_channel = '03'),
                         '0',
                         0,
                         l_hash_pan,
                         l_encr_pan,
                         to_char(SYSDATE, 'yyyymmdd'),
                         to_char(SYSDATE, 'hh24miss'),
                         'C',
                         '00',
                         l_auth_id,
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
                         l_stan,
                         l_date,
                         l_time,
                         p_txn_id_in,
                         l_orgnl_stan,
                         l_orgnl_card_no,
                         l_orgnl_term_id);

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
                         '72',
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
                         l_stan,
                         l_auth_id);


     SELECT NVL(MAX(ccd_call_seq), 0) + 1
       INTO l_call_seq
       FROM vmscms.cms_calllog_details
      WHERE ccd_inst_code = 1
        AND ccd_call_id =
                 (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                              'x-incfs-sessionid'))
        AND ccd_pan_code = l_hash_pan;

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
                         '72',
                         l_date,
                         l_time,
                         p_comment_in,
                         NULL,
                         sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                     'x-incfs-username'),
                         l_acct_No,
                         SYSDATE);

     p_status_out := vmscms.gpp_const.c_success_status;

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
  END UPDATE_TRANSACTION_STATUS;

    PROCEDURE get_transaction_audit_log(p_customer_id_in       IN  VARCHAR2,
                                      p_txn_id_in            IN  VARCHAR2,
                                      p_txn_date_in          IN  VARCHAR2,
                                      p_delivery_channel_in  IN  VARCHAR2,
                                      p_txn_code_in          IN  VARCHAR2,
                                      p_status_out           OUT VARCHAR2,
                                      p_err_msg_out          OUT VARCHAR2,
                                      c_transaction_out      OUT SYS_REFCURSOR) AS
    l_field_name        VARCHAR2(50);
    l_api_name          VARCHAR2(30) := 'GET_TRANSACTION_AUDIT_LOG';
    l_flag              PLS_INTEGER := 0;
    l_hash_pan          vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan          vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_partner_id        vmscms.transactionlog.partner_id%TYPE;
    l_date              vmscms.transactionlog.business_date%TYPE;
    l_time              vmscms.transactionlog.business_time%TYPE;
    l_start_time        NUMBER;
    l_end_time          NUMBER;
    l_timetaken         NUMBER;
    l_query             VARCHAR2(32000);
    l_cust_code         vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code         vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type         vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no          vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no           vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat          vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan        vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code      vmscms.cms_appl_pan.cap_prfl_code%TYPE;

/****************************************************************************
	* Modified By        : Ubaidur Rahman.H
         * Modified Date      : 17-Jan-2020
         * Modified Reason    : VMS-1719 - CCA RRN Logging Issue.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 17-Jan-2020
         * Build Number       : R25_B0001

****************************************************************************/
BEGIN
    p_err_msg_out := 'OK';
    l_start_time := dbms_utility.get_time;
    l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                 'x-incfs-partnerid'));
    --Check for mandatory fields
	IF p_txn_id_in IS NOT NULL THEN
		CASE
		  WHEN p_txn_date_in IS NULL THEN
			l_field_name := 'TRANSACTIONDATE';
			l_flag       := 1;
		  WHEN p_delivery_channel_in IS NULL THEN
			l_field_name := 'DELIVERYCHANNEL';
			l_flag       := 1;
		  WHEN p_txn_code_in IS NULL THEN
			l_field_name := 'TRANSACTIONCODE';
			l_flag       := 1;
		ELSE
			NULL;
		END CASE;
	ELSE
       	NULL;
  END IF;


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


   l_date := to_char(to_date(p_txn_date_in,
                                'yyyy-mm-dd hh24:mi:ss'),
                        'yyyymmdd');
   l_time := to_char(to_date(p_txn_date_in,
                                'yyyy-mm-dd hh24:mi:ss'),
                        'hh24miss');


    IF p_txn_id_in IS NULL THEN

      OPEN c_transaction_out FOR
                    SELECT SUBSTR(a.vai_column_name,
                      CASE
                        WHEN SUBSTR(a.vai_column_name,1,1) IN ('P','O')
                        THEN 7
                        ELSE 5
                      END) fieldName,
                      nvl(vmscms.fn_dmaps_main(b.vai_action_username),(SELECT cum_user_name
                      FROM vmscms.cms_user_mast
                      WHERE cum_user_pin= b.vai_action_user
                      )) lastModifiedUserName,
                      to_char(b.vai_action_date,'YYYY-MM-DD HH24:MI:SS') lastModifiedDate,
                      CASE
                        WHEN upper(a.vai_column_name) IN ('O-CAM_CNTRY_CODE','P-CAM_CNTRY_CODE','VTA_CNTRY_CODE')
                        THEN
                          (SELECT gcm_cntry_name
                          FROM vmscms.gen_cntry_mast
                          WHERE gcm_inst_code=1
                          AND gcm_cntry_code = to_number(a.vai_old_val )
                          )
                        WHEN upper(a.vai_column_name) IN ('O-CAM_STATE_CODE','P-CAM_STATE_CODE','VTA_STATE_CODE')
                        THEN
                          (SELECT upper(gsm_state_name)
                          FROM vmscms.gen_state_mast
                          WHERE gsm_inst_code=1
                          AND gsm_cntry_code = to_number(SUBSTR(a.vai_old_val ,1,1))
                          AND gsm_state_code = to_number(SUBSTR( a.vai_old_val , 3 ))
                          )
                        ELSE a.vai_old_val
                      END originalValue,
                      CASE
                        WHEN upper(b.vai_column_name) IN ('O-CAM_CNTRY_CODE','P-CAM_CNTRY_CODE','VTA_CNTRY_CODE')
                        THEN
                          (SELECT gcm_cntry_name
                          FROM vmscms.gen_cntry_mast
                          WHERE gcm_inst_code=1
                          AND gcm_cntry_code = to_number(b.vai_new_val )
                          )
                        WHEN upper(b.vai_column_name) IN ('O-CAM_STATE_CODE','P-CAM_STATE_CODE','VTA_STATE_CODE')
                        THEN
                          (SELECT upper(gsm_state_name)
                          FROM vmscms.gen_state_mast
                          WHERE gsm_inst_code=1
                          AND gsm_cntry_code = to_number(SUBSTR(b.vai_new_val ,1,1))
                          AND gsm_state_code = to_number(SUBSTR( b.vai_new_val , 3 ))
                          )
                        ELSE b.vai_new_val
                      END updatedValue
                    FROM
                      (SELECT *
                      FROM
                        (SELECT vai_cust_code,
                          vam_table_name,
                          vai_column_name,
                          vai_action_type,
                          vmscms.fn_dmaps_main(decode(vai_action_type,'I',TO_CHAR(vai_new_val),TO_CHAR(vai_old_val)))  vai_old_val,
                          vai_action_date,
                           ROW_NUMBER () OVER (PARTITION BY vai_cust_code,vai_column_name ORDER BY vai_action_date DESC)r
                        FROM vmscms.vms_audit_info,
                             vmscms.vms_audit_mast
                        WHERE vam_table_id = vai_table_id
                        AND vam_table_name <> 'CMS_SMSANDEMAIL_ALERT'
						            AND vai_column_name NOT IN ('CCM_OCCUPATION','VTA_OCCUPATION','CCM_REASON_FOR_NO_TAX_ID','CCM_CANADA_CREDIT_AGENCY','CCM_CREDIT_FILE_REF_NUMBER','CCM_DATE_OF_VERIFICATION','VTA_STATE_SWITCH')
                        AND vai_cust_code  =l_cust_code
                        )
                      WHERE r=1
                      )a,
                      (SELECT *
                      FROM
                        (SELECT vai_cust_code,
                          vam_table_name,
                          vai_column_name,
                          vai_action_user,
                          vai_action_date,
                          vai_action_type,
                          vai_action_username,
                          vmscms.fn_dmaps_main(TO_CHAR(vai_new_val)) vai_new_val,
                          ROW_NUMBER () OVER (PARTITION BY vai_cust_code,vai_column_name ORDER BY vai_action_date DESC)r
                        FROM vmscms.vms_audit_info,
                             vmscms.vms_audit_mast
                        WHERE vam_table_id = vai_table_id
                        AND vam_table_name <> 'CMS_SMSANDEMAIL_ALERT'
						            AND vai_column_name NOT IN ('CCM_OCCUPATION','VTA_OCCUPATION','CCM_REASON_FOR_NO_TAX_ID','CCM_CANADA_CREDIT_AGENCY','CCM_CREDIT_FILE_REF_NUMBER','CCM_DATE_OF_VERIFICATION','VTA_STATE_SWITCH')
                        AND vai_cust_code  =l_cust_code
                        )
                      WHERE r=1
                      )b
                    WHERE a.vai_column_name=b.vai_column_name
                    AND ((a.vai_action_type='I' AND a.vai_action_date <>b.vai_action_date) or a.vai_action_type='U');

	ELSE

      OPEN c_transaction_out FOR
                    SELECT SUBSTR(a.vai_column_name,
                      CASE
                        WHEN SUBSTR(a.vai_column_name,1,1) IN ('P','O')
                        THEN 7
                        ELSE 5
                      END) fieldName,
                      nvl(vmscms.fn_dmaps_main(b.vai_action_username),(SELECT cum_user_name
                      FROM vmscms.cms_user_mast
                      WHERE cum_user_pin= b.vai_action_user
                      )) lastModifiedUserName,
                      to_char(b.vai_action_date,'YYYY-MM-DD HH24:MI:SS') lastModifiedDate,
                      CASE
                        WHEN upper(a.vai_column_name) IN ('O-CAM_CNTRY_CODE','P-CAM_CNTRY_CODE','VTA_CNTRY_CODE')
                        THEN
                          (SELECT gcm_cntry_name
                          FROM vmscms.gen_cntry_mast
                          WHERE gcm_inst_code=1
                          AND gcm_cntry_code = to_number(a.vai_old_val )
                          )
                        WHEN upper(a.vai_column_name) IN ('O-CAM_STATE_CODE','P-CAM_STATE_CODE','VTA_STATE_CODE')
                        THEN
                          (SELECT upper(gsm_state_name)
                          FROM vmscms.gen_state_mast
                          WHERE gsm_inst_code=1
                          AND gsm_cntry_code = to_number(SUBSTR(a.vai_old_val ,1,1))
                          AND gsm_state_code = to_number(SUBSTR( a.vai_old_val , 3 ))
                          )
                         ELSE a.vai_old_val
                      END originalValue,
                      CASE
                        WHEN upper(b.vai_column_name) IN ('O-CAM_CNTRY_CODE','P-CAM_CNTRY_CODE','VTA_CNTRY_CODE')
                        THEN
                          (SELECT gcm_cntry_name
                          FROM vmscms.gen_cntry_mast
                          WHERE gcm_inst_code=1
                          AND gcm_cntry_code = to_number(b.vai_new_val )
                          )
                        WHEN upper(b.vai_column_name) IN ('O-CAM_STATE_CODE','P-CAM_STATE_CODE','VTA_STATE_CODE')
                        THEN
                          (SELECT upper(gsm_state_name)
                          FROM vmscms.gen_state_mast
                          WHERE gsm_inst_code=1
                          AND gsm_cntry_code = to_number(SUBSTR(b.vai_new_val ,1,1))
                          AND gsm_state_code = to_number(SUBSTR( b.vai_new_val , 3 ))
                          )
                        ELSE b.vai_new_val
                      END updatedValue
                    FROM
                      (SELECT *
                      FROM
                        (SELECT vai_cust_code,
                          vam_table_name,
                          vai_column_name,
                          vai_action_type,
                          vmscms.fn_dmaps_main(decode(vai_action_type,'I',TO_CHAR(vai_new_val),TO_CHAR(vai_old_val))) vai_old_val,
                          vai_action_date,
                          ROW_NUMBER () OVER (PARTITION BY vai_cust_code,vai_column_name ORDER BY vai_action_date DESC)r
                        FROM vmscms.vms_audit_info,
                             vmscms.vms_audit_mast
                        WHERE vam_table_id                   = vai_table_id
                        AND vam_table_name <> 'CMS_SMSANDEMAIL_ALERT'
						            AND vai_column_name NOT IN ('CCM_OCCUPATION','VTA_OCCUPATION','CCM_REASON_FOR_NO_TAX_ID','CCM_CANADA_CREDIT_AGENCY','CCM_CREDIT_FILE_REF_NUMBER','CCM_DATE_OF_VERIFICATION','VTA_STATE_SWITCH')
                        AND (vai_cust_code,vai_column_name) IN
                          (SELECT vai_cust_code,
                            vai_column_name
                          FROM vmscms.vms_audit_info
                          WHERE vai_rrn      =p_txn_id_in
                          AND vai_del_chnnl  =p_delivery_channel_in
                          AND vai_txn_code   =p_txn_code_in
                          AND TRUNC(vai_action_date)=TRUNC(to_date(p_txn_date_in,'YYYY-MM-DD HH24:MI:SS'))
                          )
                        )
                      WHERE r=1
                      )a,
                      (SELECT vai_cust_code,
                        vam_table_name,
                        vai_column_name,
                        vai_action_user,
                        vai_action_date,
                        vai_action_type,
                        vai_action_username,
                        vmscms.fn_dmaps_main(TO_CHAR(vai_new_val)) vai_new_val
                      FROM vmscms.vms_audit_info,
                           vmscms.vms_audit_mast
                      WHERE vam_table_id = vai_table_id
                      AND vam_table_name <> 'CMS_SMSANDEMAIL_ALERT'
					            AND vai_column_name NOT IN ('CCM_OCCUPATION','VTA_OCCUPATION','CCM_REASON_FOR_NO_TAX_ID','CCM_CANADA_CREDIT_AGENCY','CCM_CREDIT_FILE_REF_NUMBER','CCM_DATE_OF_VERIFICATION','VTA_STATE_SWITCH')
                      AND vai_rrn        =p_txn_id_in
                      AND vai_del_chnnl  =p_delivery_channel_in
                      AND vai_txn_code   =p_txn_code_in
                      AND TRUNC(vai_action_date)=TRUNC(to_date(p_txn_date_in,'YYYY-MM-DD HH24:MI:SS'))
                      ) b
                    WHERE a.vai_column_name=b.vai_column_name;


	END IF;

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
                         vmscms.gpp_const.c_ora_error_status,
                         ' Customer_id - '||p_customer_id_in);
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
                          vmscms.gpp_const.c_ora_error_status,
                         ' Customer_id - '||p_customer_id_in);
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



 END  get_transaction_audit_log;


  PROCEDURE init IS
  BEGIN
    -- initialize all errors here
    g_err_nodata       := fsfw.fserror_t('E-NO-DATA',
                                         '$1 $2');
    g_err_mandatory    := fsfw.fserror_t('E-MANDATORY',
                                         'Mandatory Field is NULL: $1 $2 $3',
                                         'NOTIFY');
    g_err_unknown      := fsfw.fserror_t('E-UNKNOWN',
                                         'Unknown error: $1 $2',
                                         'NOTIFY');
    g_err_invalid_data := fsfw.fserror_t('E-INVALID_DATA',
                                         'ACCOUNT TYPE: $1 $2 $3');
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
END gpp_transaction;
/