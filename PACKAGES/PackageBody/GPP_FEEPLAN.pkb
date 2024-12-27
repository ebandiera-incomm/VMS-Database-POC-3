create or replace PACKAGE BODY   vmscms.GPP_FEEPLAN IS

   -- PL/SQL Package using FS Framework
   -- Author  : Rojalin Beura
   -- Created : 8/12/2015 4:06:48 PM

   -- Private type declarations
   -- TEST 1

   -- Private constant declarations

   -- Private variable declarations

   -- global variables for the FS framework
   g_config fsfw.fstype.parms_typ;
   g_debug  fsfw.fsdebug_t;

   --declare all FS errors here
   g_err_nodata       fsfw.fserror_t;
   g_err_unknown      fsfw.fserror_t;
   g_err_mandatory    fsfw.fserror_t;
   g_err_failure      fsfw.fserror_t;
   g_err_invalid_data fsfw.fserror_t;
   -- Function and procedure implementations
   --Get feeplan details API
   PROCEDURE get_feeplan_details
   (
      p_feeplan_id_in      IN VARCHAR2,
      p_status_out         OUT VARCHAR2,
      p_err_msg_out        OUT VARCHAR2,
      p_feeplan_desc_out   OUT VARCHAR2,
      c_feeplan_detail_out OUT SYS_REFCURSOR

   ) AS
      l_api_name   VARCHAR2(30) := 'GET FEE PLAN DETAILS';
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
      SELECT cfp_plan_desc
        INTO p_feeplan_desc_out
        FROM vmscms.cms_fee_plan
       WHERE cfp_plan_id = p_feeplan_id_in;

      OPEN c_feeplan_detail_out FOR
         SELECT a.cfm_fee_code id,
                b.cft_feetype_desc fee_type,
                a.cfm_fee_desc,
                to_char(nvl(a.cfm_fee_amt, 0), '9,999,999,990.99') cfm_fee_amt,
                to_char(nvl(a.cfm_per_fees, 0), '9,999,999,990.99') cfm_per_fees,
                to_char(nvl(a.cfm_min_fees, 0), '9,999,999,990.99') cfm_min_fees,
                a.cfm_clawback_flag
           FROM vmscms.cms_fee_mast a, vmscms.cms_fee_types b
          WHERE a.cfm_fee_code IN
                (SELECT cff_fee_code
                   FROM vmscms.cms_fee_feeplan
                  WHERE cff_fee_plan = p_feeplan_id_in)
            AND a.cfm_feetype_code = b.cft_feetype_code;
      --time taken
      l_end_time := dbms_utility.get_time;
      g_debug.display('l_end_time' || l_end_time);
      l_timetaken := (l_end_time - l_start_time);
      g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
      g_debug.display('Elapsed Time: ' ||
                      (l_end_time - l_start_time) / 100 || ' secs');

      p_status_out := vmscms.gpp_const.c_success_status;
      /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                   NULL,
                                                   NULL,
                                                   NULL,
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

   END get_feeplan_details;

   --Get customer fee plan details API
   --status: 0 - success, Non Zero value - failure
   PROCEDURE get_customer_feeplan_details
   (
      p_customer_id_in       IN VARCHAR2,
      p_status_out           OUT VARCHAR2,
      p_err_msg_out          OUT VARCHAR2,
      c_cust_feeplan_out     OUT SYS_REFCURSOR,
      c_cust_feeplan_det_out OUT SYS_REFCURSOR
   ) AS
      l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
      l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
      l_plain_pan  VARCHAR2(20);
      l_api_name   VARCHAR2(30) := 'GET CUSTOMER FEE PLAN DETAILS';
      l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
      l_start_time NUMBER;
      l_end_time   NUMBER;
      l_timetaken  NUMBER;
      -- performance change
      l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
      l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
      l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
      l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
      l_acct_no      vmscms.cms_appl_pan.cap_acct_no%TYPE;
      l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
      l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
      l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;

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
      --Fetching the active PAN for the input customer id
      --performance change
      -- vmscms.gpp_pan.get_pan_details(p_customer_id_in,
      --                    l_hash_pan,
      --                  l_encr_pan);
      --performance change
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
      -- l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);  --performance change

      --Fetching all Fee Plan FOR THE input customer id
      OPEN c_cust_feeplan_out FOR
         SELECT cfp_plan_id,
                cfp_plan_desc,
                decode(cfp_plan_id,
                       vmscms.gpp_feeplan.get_fee_plan(l_hash_pan,
                                                       l_prod_code,
                                                       l_card_type),
                       --  (SELECT substr(vmscms.fn_get_feeplan('1', l_plain_pan), --performance change
                       --                 1,                                       --performance change
                       --                instr(vmscms.fn_get_feeplan('1',         --performance change
                       --                                            l_plain_pan), --performance change
                       --                      '|') - 1)                          --performance change
                       --    FROM dual),                                           --performance change
                       'TRUE',
                       'FALSE') isactive
           FROM vmscms.cms_fee_plan
          WHERE cfp_plan_id IN
                (SELECT --DISTINCT
                  cfm_plan_id
                   FROM vmscms.cms_feeplan_prod_mapg --,
                 --   vmscms.cms_appl_pan, per  --performance change
                 --  vmscms.cms_cust_mast  --performance change
                  WHERE cfm_prod_code = l_prod_code);
      --cap_cust_code = ccm_cust_code     --performance change
      --  AND cfm_prod_code = cap_prod_code   --performance change
      -- AND ccm_cust_id = p_customer_id_in   --performance change
      -- AND ccm_partner_id IN (l_partner_id));   --performance change

      OPEN c_cust_feeplan_det_out FOR
         SELECT a.cff_fee_plan fee_plan_id,
                cfm_fee_code fee_id,
                cft_feetype_desc fee_type,
                cfm_fee_desc,
                to_char(nvl(cfm_fee_amt, 0), '9,999,999,990.99') cfm_fee_amt,
                to_char(nvl(cfm_per_fees, 0), '9,999,999,990.99') cfm_per_fees,
                to_char(nvl(cfm_min_fees, 0), '9,999,999,990.99') cfm_min_fees,
                cfm_clawback_flag
           FROM vmscms.cms_fee_mast,
                vmscms.cms_fee_types,
                (SELECT cff_fee_code, cff_fee_plan
                   FROM vmscms.cms_fee_feeplan, vmscms.cms_feeplan_prod_mapg
                  WHERE cff_fee_plan = cfm_plan_id
                    AND cff_inst_code = cfm_inst_code
                    AND cfm_prod_code = l_prod_code) a
         --IN  --performance change
         -- (SELECT --DISTINCT --performance change
         --  cfm_plan_id   --performance change
         --    FROM vmscms.cms_feeplan_prod_mapg --, --performance change
         -- vmscms.cms_appl_pan,  --performance change
         --   vmscms.cms_cust_mast  --performance change
         --  WHERE cfm_prod_code = l_prod_code))a --cap_cust_code = ccm_cust_code --performance change
         -- AND cfm_prod_code = cap_prod_code --performance change
         --  AND ccm_cust_id = p_customer_id_in --performance change
         -- AND ccm_partner_id IN (l_partner_id))) a --performance change
          WHERE cfm_inst_code = 1
            AND cfm_fee_code = a.cff_fee_code
            AND cfm_feetype_code = cft_feetype_code
          ORDER BY fee_plan_id, fee_id;

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

      --time taken
      l_end_time := dbms_utility.get_time;
      g_debug.display('l_end_time' || l_end_time);
      l_timetaken := (l_end_time - l_start_time);
      g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
      g_debug.display('Elapsed Time: ' ||
                      (l_end_time - l_start_time) / 100 || ' secs');

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
   END get_customer_feeplan_details;

   -- the init procedure is private and should ALWAYS exist
   PROCEDURE update_fee_plan
   (
      p_customer_id_in IN VARCHAR2,
      p_feeplan_id_in  IN VARCHAR2,
      p_eff_date_in    IN VARCHAR2,
      p_comment_in     IN VARCHAR2,
      p_status_out     OUT VARCHAR2,
      p_err_msg_out    OUT VARCHAR2

   ) AS
      l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
      l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
      l_plain_pan  VARCHAR2(20);
      l_curr_code  VARCHAR2(20);
      l_date       VARCHAR2(50);
      l_time       VARCHAR2(50);
      l_api_name   VARCHAR2(50) := 'UPDATE FEE PLAN';
      l_rrn        vmscms.transactionlog.rrn%TYPE;
      l_field_name VARCHAR2(20);
      l_flag       PLS_INTEGER := 0;
      l_session_id VARCHAR2(20);
      l_eff_date   VARCHAR2(100) := to_char(to_date(SYSDATE, 'DD/MM/RRRR'),
                                            'MM/DD/YYYY');
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
      g_debug.display('l_encr_pan' || l_encr_pan);

      --Check for madatory fields
      CASE
         WHEN p_customer_id_in IS NULL THEN
            l_field_name := 'CUSTOMER ID';
            l_flag       := 1;
         WHEN p_feeplan_id_in IS NULL THEN
            l_field_name := 'FEE PLAN ID';
            l_flag       := 1;
         WHEN p_eff_date_in IS NULL THEN
            l_field_name := 'EFFECTIVE DATE';
            l_flag       := 1;
         WHEN p_comment_in IS NULL THEN
            l_field_name := 'COMMENT';
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

      g_debug.display('l_eff_date' || l_eff_date);
      IF l_eff_date <>
         to_char(to_date(p_eff_date_in, 'YYYY-MM-DD'), 'MM/DD/YYYY')
      THEN
         g_debug.display('p_eff_date_in' ||
                         to_char(to_date(p_eff_date_in, 'YYYY-MM-DD'),
                                 'MM/DD/YYYY'));
         p_status_out := vmscms.gpp_const.c_invalid_date_status;
         g_err_invalid_data.raise(l_api_name,
                                  ',0021,',
                                  'EFFECTIVE DATE SHOULD BE THE CURRENT DATE');
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



      --fetching the currency
      --Performqance change query below updated
      SELECT cbp_param_value
        INTO l_curr_code
        FROM vmscms.cms_prod_cattype, vmscms.cms_bin_param
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
      l_date := to_char(to_date(l_date, 'dd-mm-yyyy'), 'yyyymmdd');
      --getting the time
      l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                    'x-incfs-date')),
                       18,
                       8);
      l_time := to_char(to_date(l_time, 'HH24:MI:SS'), 'HH24MISS');
      --l_time := REPLACE(l_time, ':', '');

      g_debug.display('l_date' || l_date);
      g_debug.display('l_time' || l_time);

      l_session_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                   'x-incfs-sessionid'));
      l_session_id := to_number(l_session_id, '999999999');
      --fetching the rrn
      SELECT to_char(to_char(SYSDATE, 'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                     lpad(vmscms.seq_deppending_rrn.nextval, 3, '0'))
        INTO l_rrn
        FROM dual;
      g_debug.display('l_rrn' || l_rrn);
      g_debug.display('l_eff_date' || l_eff_date);
      g_debug.display('calling sp_update_feeplan');
      vmscms.sp_update_feeplan(1, --PRM_INST_CODE
                               l_rrn, --PRM_RRN
                               NULL, --PRM_STAN
                               l_plain_pan, --PRM_CARD_NUMBER
                               '000', --PRM_MBR_NUMB
                               '03', --PRM_DEL_CHANNEL
                               NULL, --PRM_TRAN_TYPE
                               '0', --PRM_TRAN_MODE
                               34, --PRM_TRAN_CODE
                               l_curr_code, --PRM_CURRENCY_CODE
                               l_date, --PRM_TRAN_DATE
                               l_time, --PRM_TRAN_TIME
                               '0200', --PRM_MSG_TYPE
                               '0', --PRM_REVERSAL_CODE
                               p_feeplan_id_in,
                               l_eff_date,
                               p_comment_in,
                               NULL, --PRM_REASON_CODE
                               l_session_id, --prm_call_id
                               NULL, --PRM_INS_USER
                               (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                            'x-incfs-ip')),
                               p_err_msg_out,
                               p_status_out);

      g_debug.display('p_status_out' || p_status_out);
      g_debug.display('p_err_msg_out' || p_err_msg_out);
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
      --Jira Issue: CFIP:187 starts
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
      g_debug.display('Elapsed Time: ' ||
                      (l_end_time - l_start_time) / 100 || ' secs');
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
         p_status_out := vmscms.gpp_const.c_update_fee_status;
         g_err_unknown.raise(l_api_name || ' FAILED',
                             vmscms.gpp_const.c_update_fee_status);
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

   END update_fee_plan;
   --

   FUNCTION get_fee_plan
   (
      p_hash_pan_in  IN VARCHAR2,
      p_prod_code_in IN VARCHAR2,
      p_catg_code_in IN VARCHAR2
   ) RETURN NUMBER IS
      l_fee_plan vmscms.cms_card_excpfee.cce_fee_plan%TYPE;
   BEGIN

      BEGIN
         SELECT cce_fee_plan
           INTO l_fee_plan
           FROM vmscms.cms_card_excpfee a,
                vmscms.cms_appl_pan     b,
                vmscms.cms_fee_plan     f
          WHERE cce_inst_code = 1
            AND a.cce_pan_code = p_hash_pan_in
            AND a.cce_inst_code = b.cap_inst_code
            AND a.cce_pan_code = b.cap_pan_code
            AND a.cce_inst_code = f.cfp_inst_code
            AND a.cce_fee_plan = f.cfp_plan_id
            AND ((cce_valid_to IS NOT NULL AND
                (trunc(SYSDATE) BETWEEN cce_valid_from AND cce_valid_to)) OR
                (cce_valid_to IS NULL AND trunc(SYSDATE) >= cce_valid_from));
      EXCEPTION
         WHEN no_data_found THEN
            BEGIN
               SELECT cpf_fee_plan
                 INTO l_fee_plan
                 FROM vmscms.cms_prodcattype_fees a,
                      vmscms.cms_prod_cattype     g,
                      vmscms.cms_prod_mast        p,
                      vmscms.cms_fee_plan         h
                WHERE cpf_inst_code = 1
                  AND a.cpf_prod_code = p_prod_code_in
                  AND a.cpf_card_type = p_catg_code_in
                  AND a.cpf_inst_code = g.cpc_inst_code
                  AND a.cpf_prod_code = g.cpc_prod_code
                  AND a.cpf_card_type = g.cpc_card_type
                  AND p.cpm_prod_code = a.cpf_prod_code
                  AND p.cpm_inst_code = a.cpf_inst_code
                  AND a.cpf_inst_code = h.cfp_inst_code
                  AND a.cpf_fee_plan = h.cfp_plan_id
                  AND ((cpf_valid_to IS NOT NULL AND
                      (trunc(SYSDATE) BETWEEN cpf_valid_from AND
                      cpf_valid_to)) OR (cpf_valid_to IS NULL AND
                      trunc(SYSDATE) >= cpf_valid_from));
            EXCEPTION
               WHEN no_data_found THEN

                  BEGIN
                     SELECT cpf_fee_plan
                       INTO l_fee_plan
                       FROM vmscms.cms_prod_fees a,
                            vmscms.cms_prod_mast b,
                            vmscms.cms_fee_plan  e
                      WHERE cpf_inst_code = 1
                        AND a.cpf_prod_code = p_prod_code_in
                        AND a.cpf_inst_code = b.cpm_inst_code
                        AND a.cpf_prod_code = b.cpm_prod_code
                        AND a.cpf_inst_code = e.cfp_inst_code
                        AND a.cpf_fee_plan = e.cfp_plan_id
                        AND upper(cpm_marc_prod_flag) = 'N'
                        AND ((cpf_valid_to IS NOT NULL AND
                            (trunc(SYSDATE) BETWEEN cpf_valid_from AND
                            cpf_valid_to)) OR
                            (cpf_valid_to IS NULL AND
                            trunc(SYSDATE) >= cpf_valid_from));

                  EXCEPTION
                     WHEN no_data_found THEN
                        l_fee_plan := NULL;
                  END;

            END;

      END;

      RETURN l_fee_plan;
   END;

   PROCEDURE init IS
   BEGIN
      -- initialize all errors here
      g_err_nodata := fsfw.fserror_t('E-NO-DATA',
                                     'No data is available : $1 $2 $3');

      g_err_unknown      := fsfw.fserror_t('E-UNKNOWN',
                                           'Unknown error: $1 $2',
                                           'NOTIFY');
      g_err_mandatory    := fsfw.fserror_t('E-MANDATORY',
                                           'Mandatory Field is NULL: $1 $2 $3',
                                           'NOTIFY');
      g_err_failure      := fsfw.fserror_t('E-FAILURE',
                                           'Procedure failed: $1 $2 $3');
      g_err_invalid_data := fsfw.fserror_t('E-INVALID_DATA', '$1 $2 $3');

      -- load configuration elements
      g_config := fsfw.fsconfig.get_configuration($$PLSQL_UNIT);
      IF g_config.exists(fsfw.fsconst.c_debug)
      THEN
         g_debug := fsfw.fsdebug_t($$PLSQL_UNIT,
                                   g_config(fsfw.fsconst.c_debug));
      ELSE
         g_debug := fsfw.fsdebug_t($$PLSQL_UNIT, '');
      END IF;
   END init;

   -- the get_cpp_context function returns the value of the specific
   -- context value set in the application context for the GPP application

   FUNCTION get_gpp_context(p_name_in IN VARCHAR2) RETURN VARCHAR2 IS
   BEGIN
      RETURN(sys_context(fsfw.fsconst.c_fsapi_gpp_context, p_name_in));
   END get_gpp_context;

BEGIN
   -- Initialization
   init;
END gpp_feeplan;
/
show error