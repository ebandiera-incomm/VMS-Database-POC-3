create or replace PACKAGE BODY vmscms.GPP_COMMENTS IS

   -- PL/SQL Package using FS Framework
   -- Author  : Rojalin Beura
   -- Created : 8/12/2015 5:14:30 PM

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
   -- Function and procedure implementations
   PROCEDURE get_comments
   (
      p_customer_id_in  IN VARCHAR2,
      p_comment_type_in IN VARCHAR2 DEFAULT 'ALL',
      p_status_out      OUT VARCHAR2,
      p_err_msg_out     OUT VARCHAR2,
      c_comments_out    OUT SYS_REFCURSOR

   ) AS
      l_api_name     VARCHAR2(20) := 'GET COMMENTS';
      l_field_name   VARCHAR2(50);
      l_flag         PLS_INTEGER := 0;
      l_comment_type VARCHAR2(10) := nvl(p_comment_type_in, 'ALL');
      l_hash_pan     vmscms.cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan     vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
      l_partner_id   vmscms.cms_cust_mast.ccm_partner_id%TYPE;
      l_start_time   NUMBER;
      l_end_time     NUMBER;
      l_timetaken    NUMBER;
      l_date         VARCHAR2(50);
      l_time         VARCHAR2(50);
      l_rrn          vmscms.transactionlog.rrn%TYPE;

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
      g_debug.display('l_start_time' || l_start_time);
      --Check for mandatory fields
      l_partner_id := sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-partnerid');
      --l_partner_id := 1;
      g_debug.display('l_partner_id' || l_partner_id);
      --Fetching the active PAN for the input customer id
      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                     l_hash_pan,
                                     l_encr_pan);

      CASE
         WHEN p_customer_id_in IS NULL THEN
            l_field_name := 'CUSTOMER ID';
            l_flag       := 1;
         WHEN p_comment_type_in IS NULL THEN
            l_field_name := 'COMMENT TYPE';
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
                                                      'F', --vmscms.gpp_const.c_failure_flag,
                                                      p_err_msg_out,
                                                      vmscms.gpp_const.c_failure_res_id,
                                                      NULL,
                                                      l_timetaken); --Remarks --Remarks

         RETURN;
      END IF;

      CASE
         WHEN upper(l_comment_type) = 'ALL' THEN
            OPEN c_comments_out FOR
               SELECT ccd_call_id call_log_id,
                      ccd_call_seq call_seq_id,
                      c.ccm_catg_desc call_type,
                     -- e.cap_mask_pan pan,
                     vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(e.cap_pan_code_encr)) pan,
                      decode(vmscms.fn_check_date(b.ccd_tran_date || '-' ||
                                                  b.ccd_tran_time),
                             NULL,
                             '',
                             to_char(to_date(b.ccd_tran_date || ' ' ||
                                             b.ccd_tran_time,
                                             'yyyymmdd hh24miss'),
                                     'mm/dd/yyyy hh24:mi:ss')) call_date,
                      --Jira Issue: CFIP:187 starts
                      /*CASE d.cum_user_name
                         WHEN NULL THEN
                          a.ccm_fsapi_username
                         ELSE
                          d.cum_user_name
                      END AS userid,*/
                      CASE nvl(b.ccd_ins_user, 0)
                         WHEN 0 THEN  
						  b.ccd_fsapi_username
                         ELSE
						--d.cum_user_name				 --Commented for VMS_8375
							(SELECT d.cum_user_name
							  FROM vmscms.cms_userdetl_mast d
							 WHERE d.cum_user_code = a.ccm_ins_user)	--Added for VMS_8375
                      END AS userid,
                      --Jira Issue: CFIP:187 ends
                      b.ccd_comments comments
                 FROM vmscms.cms_calllog_mast    a,
                      vmscms.cms_calllog_details b,
                      vmscms.cms_callcatg_mast   c,
                     -- vmscms.cms_userdetl_mast   d,		 --Commented for VMS_8375
                      vmscms.cms_appl_pan        e,
                      vmscms.cms_cust_mast       f
		 
                WHERE a.ccm_call_id = b.ccd_call_id
                  AND a.ccm_inst_code = b.ccd_inst_code
                  AND a.ccm_inst_code = c.ccm_inst_code
                  AND a.ccm_call_catg = c.ccm_catg_id
                  --AND a.ccm_ins_user = d.cum_user_code(+)  --Commented for VMS_8375
                  AND a.ccm_pan_code = b.ccd_pan_code
                  --AND b.ccd_acct_no = e.cap_acct_no		 --Commented for VMS_8375				  
				  AND b.ccd_inst_code= e.cap_inst_code		 --Added for VMS_8375
				  AND b.ccd_pan_code = e.cap_pan_code		 --Added for VMS_8375				  
                  --AND e.cap_pan_code = ccm_pan_code		 --Commented for VMS_8375
                  AND e.cap_cust_code = f.ccm_cust_code
                  AND f.ccm_cust_id = p_customer_id_in
                  --AND f.ccm_partner_id IN (l_partner_id)
                  AND nvl(f.ccm_prod_code,
                                 '~') || nvl(to_char(f.ccm_card_type),
                                             '^') =
                             vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                      p_prod_code_in  => f.ccm_prod_code,
                                                                      p_card_type_in  => f.ccm_card_type)	

																  
                ORDER BY call_date DESC;

         WHEN upper(l_comment_type) = 'SUMMARY' THEN
            OPEN c_comments_out FOR
               SELECT *
                 FROM (SELECT ccd_call_id call_log_id,
                              ccd_call_seq call_seq_id,
                              c.ccm_catg_desc call_type,
                             -- e.cap_mask_pan pan,
                             vmscms.fn_getmaskpan(vmscms.fn_dmaps_main(e.cap_pan_code_encr)) pan,
                              decode(vmscms.fn_check_date(b.ccd_tran_date || '-' ||
                                                          b.ccd_tran_time),
                                     NULL,
                                     '',
                                     to_char(to_date(b.ccd_tran_date || ' ' ||
                                                     b.ccd_tran_time,
                                                     'yyyymmdd hh24miss'),
                                             'mm/dd/yyyy hh24:mi:ss')) call_date,
                              --Jira Issue: CFIP:187 starts
                              /*CASE d.cum_user_name
                                 WHEN NULL THEN
                                  a.ccm_fsapi_username
                                 ELSE
                                  d.cum_user_name
                              END AS userid,*/
                              CASE nvl(b.ccd_ins_user, 0)
                                 WHEN 0 THEN
                                  b.ccd_fsapi_username
                                 ELSE
                                  d.cum_user_name
                              END AS userid,
                              --Jira Issue: CFIP:187 ends
                              b.ccd_comments comments,
                              rank() over(PARTITION BY ccd_call_id ORDER BY ccd_call_seq DESC) drank,
                              COUNT(ccd_call_id) over(PARTITION BY ccd_call_id) COUNT
                         FROM vmscms.cms_calllog_mast    a,
                              vmscms.cms_calllog_details b,
                              vmscms.cms_callcatg_mast   c,
                              vmscms.cms_userdetl_mast   d,
                              vmscms.cms_appl_pan        e,
                              vmscms.cms_cust_mast       f
                        WHERE a.ccm_call_id = b.ccd_call_id
                          AND a.ccm_inst_code = b.ccd_inst_code
                          AND a.ccm_inst_code = c.ccm_inst_code
                          AND a.ccm_call_catg = c.ccm_catg_id
                          AND a.ccm_ins_user = d.cum_user_code(+)
                          AND a.ccm_pan_code = b.ccd_pan_code
                          AND b.ccd_acct_no = e.cap_acct_no
                          AND e.cap_pan_code = ccm_pan_code
                          AND e.cap_cust_code = f.ccm_cust_code
                          AND f.ccm_cust_id = p_customer_id_in
                          --AND f.ccm_partner_id IN (l_partner_id)
                          AND nvl(f.ccm_prod_code,
                                 '~') || nvl(to_char(f.ccm_card_type),
                                             '^') =
                             vmscms.gpp_utils.get_prod_code_card_type(p_partner_id_in => l_partner_id,
                                                                      p_prod_code_in  => f.ccm_prod_code,
                                                                      p_card_type_in  => f.ccm_card_type)
                          AND a.ccm_call_status = 'C') a
                WHERE a.drank = 1;

      END CASE;
      --time taken
      l_end_time := dbms_utility.get_time;
      g_debug.display('l_end_time' || l_end_time);
      l_timetaken := (l_end_time - l_start_time);
      g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
      --l_diff_time := (l_end_time - l_start_time) / 100; --IN SECONDS
      g_debug.display('Elapsed Time: ' ||
                      (l_end_time - l_start_time) / 100 || ' secs');

      p_status_out := vmscms.gpp_const.c_success_status;
      /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'C',
                                                   'SUCCESS', --vmscms.gpp_const.c_success_msg,
                                                   vmscms.gpp_const.c_success_res_id,
                                                   NULL,
                                                   l_timetaken);*/ --Remarks

      /*INSERT INTO vmscms.cms_rrn_logging
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
          l_encr_pan,
          l_date,
          l_time,
          l_rrn,
          '03',
          '18',
          l_diff_time,
          'TESTCOMMENTS',
          SYSDATE,
          NULL,
          NULL);
      COMMIT;*/

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

   END get_comments;

   -- the init procedure is private and should ALWAYS exist

   PROCEDURE init IS
   BEGIN
      -- initialize all errors here
      g_err_nodata    := fsfw.fserror_t('E-NO-DATA', '$1 $2');
      g_err_unknown   := fsfw.fserror_t('E-UNKNOWN',
                                        'Unknown error: $1 $2',
                                        'NOTIFY');
      g_err_mandatory := fsfw.fserror_t('E-MANDATORY',
                                        'Mandatory Field is NULL: $1 $2 $3',
                                        'NOTIFY');

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
END gpp_comments;
/
show error