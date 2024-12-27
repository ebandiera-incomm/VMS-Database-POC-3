create or replace PACKAGE BODY   vmscms.GPP_SESSION IS

   -- PL/SQL Package using FS Framework
   -- Author  : Vishy Iyer
   -- Created : 09/16/2015 1:32:11 PM

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

   PROCEDURE start_session
   (
      p_customer_id_in     IN VARCHAR2,
      p_session_type_in    IN VARCHAR2,
      p_session_ref_num_in IN VARCHAR2,
      p_session_id_out     OUT VARCHAR2,
      p_status_out         OUT VARCHAR2,
      p_err_msg_out        OUT VARCHAR2
   ) AS
      l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no    vmscms.cms_appl_pan.cap_acct_no%TYPE;
      l_api_name   VARCHAR2(20);
      l_field_name VARCHAR2(20);
      l_flag       PLS_INTEGER := 0;
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
      l_api_name   := 'START SESSION';
      l_start_time := dbms_utility.get_time;
      --Check for mandatory fields
      IF p_session_ref_num_in IS NULL
      THEN
         l_field_name := 'SESSION REF NUMBER';
         l_flag       := 1;
      END IF;
      --Jira Issue CFIP:187 starts
      --getting  the date
      l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                   'x-incfs-date'),
                       6,
                       11);
      l_date := to_char(to_date(l_date, 'dd-mm-yyyy'), 'yyyymmdd');
      --getting the time
      l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                    'x-incfs-date')),
                       18,
                       8);
      l_time := REPLACE(l_time, ':', '');
      --Jira Issue CFIP:187 ends
      IF l_flag = 1
      THEN
         p_status_out := vmscms.gpp_const.c_mandatory_status;
         --g_err_mandatory.raise(l_api_name, vmscms.gpp_const.c_mandatory_errcode, vmscms.gpp_const.c_mandatory_errmsg);
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
                                                      l_timetaken); --Remarks
         RETURN;
      END IF;
   
      -- The session id to be returned from this SP
      SELECT vmscms.seq_call_id.nextval INTO p_session_id_out FROM dual;
   
      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_acct_no);
   
      -- Audit trail into CMS_CALLLOG_MAST
      INSERT INTO vmscms.cms_calllog_mast
         (ccm_call_status,
          ccm_inst_code,
          ccm_call_id,
          ccm_call_catg,
          ccm_pan_code,
          ccm_callstart_date,
          ccm_callend_date,
          ccm_ins_user,
          ccm_ins_date,
          ccm_acct_no,
          ccm_fsapi_username,
          ccm_partner_id)
      VALUES
         ('O', --open
          '1',
          p_session_id_out,
          1,
          l_hash_pan,
          SYSDATE,
          NULL,
          NULL,
          SYSDATE,
          l_acct_no,
          sys_context(fsfw.fsconst.c_fsapi_gpp_context, 'x-incfs-username'),
          sys_context(fsfw.fsconst.c_fsapi_gpp_context, 'x-incfs-partnerid'));
   
      INSERT INTO vmscms.cms_calllog_details
         (ccd_inst_code,
          ccd_call_id,
          ccd_pan_code,
          ccd_call_seq,
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
          p_session_id_out,
          l_hash_pan,
          1,
          '03',
          NULL,
          l_date,
          l_time,
          'CCA Inquiry Start', --vmscms.gpp_const.c_comments,
          NULL,
          SYSDATE,
          NULL,
          SYSDATE,
          l_acct_no,
          sys_context(fsfw.fsconst.c_fsapi_gpp_context, 'x-incfs-username'));
      --time taken
      l_end_time := dbms_utility.get_time;
      g_debug.display('l_end_time' || l_end_time);
      l_timetaken := (l_end_time - l_start_time);
      g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
      g_debug.display('Elapsed Time: ' ||
                      (l_end_time - l_start_time) / 100 || ' secs');
      --Vishy: Question
      --or do we have the x-incfs-correlationid extracted from the context and inserted into a new
      --column in cms_calllog_mast?
      --Per ArunVijay ,new column will be introduced in cms_calllog_mast for x-incfs-correlationid
      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';
      /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,     ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_success_res_id, --CFIP 349 Changed variable name from xx_failure_xx to xx_success_xx
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
         p_err_msg_out    := g_err_unknown.get_current_error;
         p_session_id_out := NULL;
         vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                      p_customer_id_in,
                                                      l_hash_pan,
                                                      l_encr_pan,
                                                      'F',
                                                      p_err_msg_out,
                                                      vmscms.gpp_const.c_failure_res_id,
                                                      NULL,
                                                      l_timetaken);
   END start_session;

   PROCEDURE end_session
   (
      p_customer_id_in IN VARCHAR2,
      p_comment_in     IN VARCHAR2,
      p_status_out     OUT VARCHAR2,
      p_err_msg_out    OUT VARCHAR2
   ) AS
      l_hash_pan    vmscms.cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan    vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no     vmscms.cms_appl_pan.cap_acct_no%TYPE;
      l_call_id_seq PLS_INTEGER;
      l_session_id  VARCHAR2(50);
      l_field_name  VARCHAR2(20);
      l_flag        PLS_INTEGER := 0;
      l_api_name    VARCHAR2(20) := 'END SESSION';
      l_date        VARCHAR2(50);
      l_time        VARCHAR2(50);
      l_start_time  NUMBER;
      l_end_time    NUMBER;
      l_timetaken   NUMBER;

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
      IF p_comment_in IS NULL
      THEN
         l_field_name := 'COMMENT';
         l_flag       := 1;
      END IF;
   
      IF l_flag = 1
      THEN
         p_status_out := vmscms.gpp_const.c_mandatory_status;
         --g_err_mandatory.raise(l_api_name, vmscms.gpp_const.c_mandatory_errcode, vmscms.gpp_const.c_mandatory_errmsg);
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
                                                      l_timetaken); --Remarks
         RETURN;
      END IF;
   
      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_acct_no);
   
      l_session_id := sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                  'x-incfs-sessionid');
   
      g_debug.display('acct no:' || l_acct_no);
   
      SELECT nvl((MAX(ccd_call_seq)), 0) + 1
        INTO l_call_id_seq
        FROM vmscms.cms_calllog_details
       WHERE ccd_inst_code = 1
         AND ccd_call_id = l_session_id
         AND ccd_pan_code = l_hash_pan;
      --Jira Issue CFIP:187 starts
      --getting  the date
      l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                   'x-incfs-date'),
                       6,
                       11);
      l_date := to_char(to_date(l_date, 'dd-mm-yyyy'), 'yyyymmdd');
      --getting the time
      l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                    'x-incfs-date')),
                       18,
                       8);
      l_time := REPLACE(l_time, ':', '');
      --Jira Issue CFIP:187 ends
      INSERT INTO vmscms.cms_calllog_details
         (ccd_inst_code,
          ccd_call_id,
          ccd_pan_code,
          ccd_call_seq,
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
          l_session_id,
          l_hash_pan,
          l_call_id_seq,
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
          sys_context(fsfw.fsconst.c_fsapi_gpp_context, 'x-incfs-username'));
   
      UPDATE vmscms.cms_calllog_mast
         SET ccm_callend_date = SYSDATE,
             ccm_call_status  = 'C', --close
             ccm_lupd_date    = SYSDATE
       WHERE ccm_call_id = l_session_id
         AND ccm_inst_code = 1;
   
      --time taken
      l_end_time := dbms_utility.get_time;
      g_debug.display('l_end_time' || l_end_time);
      l_timetaken := (l_end_time - l_start_time);
      g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
      g_debug.display('Elapsed Time: ' ||
                      (l_end_time - l_start_time) / 100 || ' secs');
   
      p_status_out  := vmscms.gpp_const.c_success_status;
      p_err_msg_out := 'SUCCESS';
      /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,     ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'F',
                                                   p_err_msg_out,
                                                   vmscms.gpp_const.c_success_res_id, --CFIP 349 Changed variable name from xx_failure_xx to xx_success_xx
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
   END end_session;

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

BEGIN
   -- Initialization
   init;
END gpp_session;
/
show error