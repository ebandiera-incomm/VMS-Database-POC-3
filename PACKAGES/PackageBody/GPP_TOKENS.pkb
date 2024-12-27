create or replace PACKAGE BODY        vmscms.GPP_TOKENS IS

  -- PL/SQL Package using FS Framework
  -- Author  : Rojalin Beura
  -- Created : 8/17/2015 10:51:34 AM

  -- Private type declarations
  -- TEST 1

  -- Private constant declarations

  -- Private variable declarations

  -- global variables for the FS framework
  g_config fsfw.fstype.parms_typ;
  g_debug  fsfw.fsdebug_t;

  --declare all FS errors here
  g_err_nodata              fsfw.fserror_t;
  g_err_failure             fsfw.fserror_t;
  g_err_unknown             fsfw.fserror_t;
  g_err_mandatory           fsfw.fserror_t;
  g_err_invalid_data        fsfw.fserror_t;
  g_err_savingacc           fsfw.fserror_t;
  g_err_feewaiver           fsfw.fserror_t;
  g_err_invalid_status      fsfw.fserror_t;
  g_err_update_token_status fsfw.fserror_t;

  -- Global variables for the package
  TYPE status_rec_typ IS RECORD(
    status_code VARCHAR2(10),
    status_abbr VARCHAR2(2));

  TYPE status_tab_typ IS TABLE OF status_rec_typ INDEX BY VARCHAR2(1000);

  g_token_status_tab status_tab_typ;

  TYPE g_token_status_tab_typ IS TABLE OF VARCHAR2(1000) INDEX BY VARCHAR2(1000);
  g_token_msgreasoncode_tab g_token_status_tab_typ; --CFIP-416

  g_is_token_updated BOOLEAN := FALSE;
  -- Function and procedure implementations
  -- To get the account details
  --status: 0 - success, Non Zero value - failure
  FUNCTION get_wallet_id(p_vti_token_requestor_id_in IN VARCHAR2,
                         p_vti_wallet_identifier_in  IN VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    IF p_vti_wallet_identifier_in IS NOT NULL
       AND p_vti_token_requestor_id_in IS NOT NULL
    THEN
      -- MasterCard Token
      RETURN p_vti_wallet_identifier_in;
    ELSIF p_vti_wallet_identifier_in IS NULL
          AND p_vti_token_requestor_id_in IS NOT NULL
    THEN
      -- Visa Token
      RETURN p_vti_token_requestor_id_in;
    END IF;
    RETURN NULL;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_wallet_id;

  FUNCTION does_token_exist(p_pan_in IN VARCHAR2) RETURN BOOLEAN IS
    l_ctr PLS_INTEGER := 0;
  BEGIN
    SELECT COUNT(1)
      INTO l_ctr
      FROM vmscms.vms_token_info
     WHERE vti_token_pan = p_pan_in
       AND vti_token_stat <> 'D';

    IF l_ctr > 0
    THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END does_token_exist;

  PROCEDURE get_token_details(p_customer_id_in     IN VARCHAR2,
                              p_status_out         OUT VARCHAR2,
                              p_err_msg_out        OUT VARCHAR2,
                              c_account_detail_out OUT SYS_REFCURSOR,
                              c_cardfee_detail_out OUT SYS_REFCURSOR,
                              c_limits_detail_out  OUT SYS_REFCURSOR,
                              c_doc_detail_out     OUT SYS_REFCURSOR,
                              c_token_detail_out   OUT SYS_REFCURSOR) IS
  BEGIN
    NULL;
  END get_token_details;

  FUNCTION get_current_token_status(p_token_in    IN VARCHAR2,
                                    p_hash_pan_in IN vmscms.cms_appl_pan.cap_pan_code%TYPE)
    RETURN VARCHAR2 IS
    l_current_token_status VARCHAR2(100);

  BEGIN
    -- Get the current status of the token entered.
    SELECT vti_token_stat
      INTO l_current_token_status
      FROM vmscms.vms_token_info a
     WHERE a.vti_token = p_token_in
       AND a.vti_token_pan = p_hash_pan_in;
    RETURN l_current_token_status;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'INVALID TOKEN';
  END get_current_token_status;

  FUNCTION update_status(p_token_in    IN VARCHAR2,
                         p_hash_pan_in IN vmscms.cms_appl_pan.cap_pan_code%TYPE,
                         p_status_in   IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    g_is_token_updated := FALSE;

    -- Update the token status
    UPDATE vmscms.vms_token_info a
       SET a.vti_token_stat = g_token_status_tab(p_status_in).status_abbr
     WHERE a.vti_token = p_token_in
       AND a.vti_token_pan = p_hash_pan_in;

    IF SQL%ROWCOUNT <> 1
    THEN
      RETURN 'UPDATE FAILED';
    END IF;

    g_is_token_updated := TRUE;

    RETURN 'OK';
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'UPDATE FAILED';
  END update_status;

  FUNCTION check_status(p_token_in          IN VARCHAR2,
                        p_current_status_in IN VARCHAR2,
                        p_status_in         IN VARCHAR2,
                        p_hash_pan_in       IN vmscms.cms_appl_pan.cap_pan_code%TYPE)
    RETURN VARCHAR2 IS
    l_api_name VARCHAR2(20) := 'UPDATE_TOKEN_STATUS';

    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;

  BEGIN

    IF p_current_status_in = ('I')
    THEN
      IF g_token_status_tab(p_status_in)
       .status_abbr NOT IN ('D',
                              'A')
      THEN
        RETURN 'INVALID STATUS';
      END IF;
    ELSIF p_current_status_in = 'A'
    THEN
      IF g_token_status_tab(p_status_in)
       .status_abbr NOT IN ('D',
                              'S')
      THEN
        RETURN 'INVALID STATUS';
      END IF;
    ELSIF p_current_status_in = 'S'
    THEN
      IF g_token_status_tab(p_status_in)
       .status_abbr NOT IN ('A',
                              'D')
      THEN
        RETURN 'INVALID STATUS';
      END IF;
    ELSE
      RETURN 'INVALID STATUS';
    END IF;
    RETURN 'OK';
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'INVALID STATUS';
  END check_status;

  PROCEDURE update_token_cards(p_newcard_no_in     IN VARCHAR2,
                               p_oldcard_no_out    OUT VARCHAR2,
                               p_provisioning_flag OUT VARCHAR2,
                               p_err_msg_out       OUT VARCHAR2) IS
    l_cnt_token NUMBER;
  BEGIN
    p_err_msg_out := 'OK';

    SELECT chr_pan_code
      INTO p_oldcard_no_out
      FROM vmscms.cms_htlst_reisu
     WHERE chr_new_pan = p_newcard_no_in;

    SELECT COUNT(*)
      INTO l_cnt_token
      FROM vmscms.vms_token_info
     WHERE vti_token_pan = p_oldcard_no_out
       AND vti_token_stat <> 'D';

    IF l_cnt_token > 0
    THEN
      SELECT nvl(cpc_replacement_provision_flag,
                 'N')
        INTO p_provisioning_flag
        FROM vmscms.cms_prod_cattype
       WHERE (cpc_inst_code, cpc_prod_code, cpc_card_type) =
             (SELECT cap_inst_code, cap_prod_code, cap_card_type
                FROM vmscms.cms_appl_pan
               WHERE cap_pan_code = p_oldcard_no_out);

      IF p_provisioning_flag = 'Y'
      THEN
        UPDATE vmscms.vms_token_info
           SET vti_token_pan = p_newcard_no_in
         WHERE vti_token_pan = p_oldcard_no_out
           AND vti_token_stat <> 'D';
      END IF;
    END IF;
  EXCEPTION
    WHEN no_data_found THEN
      NULL;
    WHEN OTHERS THEN
      p_err_msg_out := 'TOKEN CARDS UPDATE FAILED';
  END update_token_cards;

  PROCEDURE update_token_status(p_customer_id_in    IN VARCHAR2 DEFAULT NULL,
                                p_token_in          IN VARCHAR2,
                                p_status_in         IN VARCHAR2,
                                p_comment_in        IN VARCHAR2,
                                p_cardno_out        OUT VARCHAR2,
                                p_exprydate_out     OUT VARCHAR2,
                                p_token_dtls_out OUT SYS_REFCURSOR,
                                p_status_out        OUT VARCHAR2,
                                p_err_msg_out       OUT VARCHAR2) IS
    l_api_name   VARCHAR2(20) := 'UPDATE_TOKEN_STATUS';
    l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_partner_id vmscms.cms_cust_mast.ccm_partner_id%TYPE;
    --performance change
    l_cust_code    vmscms.cms_cust_mast.ccm_cust_code%TYPE;
    l_prod_code    vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type    vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_proxy_no     vmscms.cms_appl_pan.cap_proxy_number%TYPE;
    l_acct_no      vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_cardstat     vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_masked_pan   vmscms.cms_appl_pan.cap_mask_pan%TYPE;
    l_profile_code vmscms.cms_appl_pan.cap_prfl_code%TYPE;

    l_current_token        vmscms.vms_token_info.vti_token%TYPE;
    l_current_token_status VARCHAR2(100);
    l_status               VARCHAR2(100);

    l_expiry_date vmscms.cms_appl_pan.cap_expry_date%TYPE := NULL;

    l_start_time NUMBER;
    l_end_time   NUMBER;
    l_timetaken  NUMBER;

    l_return    VARCHAR2(100);
    l_curr_step VARCHAR2(1000);
    l_cnt       PLS_INTEGER := 1;

    l_pan       VARCHAR2(100);
    l_token_tab tab_token_detail_list_t := tab_token_detail_list_t();
    e_update_token_status_failed EXCEPTION;
    --SN:Added by FSS
    l_delivery_channel     vmscms.cms_transaction_mast.ctm_delivery_channel%TYPE := '03';
    l_txn_code             vmscms.cms_transaction_mast.ctm_tran_code%TYPE := '94';
    l_rrn                  vmscms.vms_token_transactionlog.vtt_rrn%TYPE;
    l_activation_code      vmscms.vms_token_transactionlog.vtt_auth_id%TYPE;
    --EN:Added by FSS

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

    --   l_partner_id := 1;
    --Fetching the active PAN for the input customer id

    CASE
      WHEN p_customer_id_in IS NOT NULL THEN
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

        g_debug.display('l_acct_no' || l_acct_no);
        g_debug.display('l_cust_code' || l_cust_code);
        g_debug.display('p_customer_id_in' || p_customer_id_in);
      ELSE
        NULL;
    END CASE;

    l_status := upper(p_status_in);

    -- Get all the tokens for the customer id passed in
    FOR i IN (SELECT a.vti_token, b.cap_expry_date,
                                     a.vti_token_requestor_id,a.vti_token_ref_id,a.vti_token_expiry_date  --Added by FSS
                FROM vmscms.vms_token_info a,
                     vmscms.cms_appl_pan   b,
                     vmscms.cms_cust_mast  c
               WHERE a.vti_token_pan = b.cap_pan_code
                 AND c.ccm_cust_code = b.cap_cust_code
                 AND c.ccm_cust_id = p_customer_id_in
                 AND a.vti_token = CASE p_token_in
                       WHEN 'ALL' THEN
                        a.vti_token
                       ELSE
                        p_token_in
                     END
                 AND a.vti_token_stat <> 'D')
    LOOP

      l_current_token := i.vti_token;
      -- Get the current status of the token entered.
      l_curr_step            := 'Get Current token status';
      l_current_token_status := get_current_token_status(l_current_token,
                                                         l_hash_pan);

      IF l_current_token_status = 'INVALID TOKEN'
      THEN
        RAISE e_update_token_status_failed;
      END IF;

      l_curr_step := 'Check status validity';

      -- Check status validity
      IF check_status(l_current_token,
                      l_current_token_status,
                      l_status,
                      l_hash_pan) <> 'OK'
      THEN
        IF p_token_in <> 'ALL'
        THEN
          RAISE e_update_token_status_failed;
        END IF;
      END IF;

      -- Call update status
      l_curr_step := 'Update status';
      IF update_status(l_current_token,
                       l_hash_pan,
                       l_status) <> 'OK'
      THEN
        RAISE e_update_token_status_failed;
      END IF;

      IF l_expiry_date IS NULL
      THEN
        l_expiry_date := i.cap_expry_date;
      END IF;

     --SN:Modified by FSS
    SELECT TO_CHAR (
              --SN: Changes VMS-8279 ~ HH has been replaced as HH24, Length of RRN changed to 15
              --SUBSTR (TO_CHAR (SYSDATE, 'YYMMDDHHMISS'), 1, 9)
              substr(to_char(SYSDATE,'YYMMDDHH24MISS'),4)
              --EN: Changes VMS-8279 ~ HH has been replaced as HH24
              || LPAD (vmscms.seq_deppending_rrn.NEXTVAL, 3, '0')),
           LPAD (vmscms.seq_auth_id.NEXTVAL, 6, '0')
      INTO l_rrn, l_activation_code
      FROM DUAL;

      -- Populate the token list array
      l_token_tab.extend(1);
      l_token_tab(l_cnt) := token_detail_list_t(token             => l_current_token,
                                                rrn               =>/* to_char(substr(to_char(SYSDATE,
                                                                                            'YYMMDDHHMISS'),
                                                                                    1,
                                                                                    9) ||
                                                                             lpad(vmscms.seq_deppending_rrn.nextval,
                                                                                  3,
                                                                                  '0')), -- Sequence*/ l_rrn,
                                                stan              => lpad(vmscms.seq_auth_stan.nextval,
                                                                          6,
                                                                          '0'), --sequence
                                                activationcode    =>/* lpad(vmscms.seq_auth_id.nextval,
                                                                          6,
                                                                          '0'), -- sequence*/l_activation_code,
                                                messagereasoncode => g_token_status_tab(l_status)
                                                                     .status_code,
                                                requestreason     => p_comment_in,
                                                forwardinstcode   => '11111' -- static value
                                                );

        l_curr_step            := 'token status update txn logging';
        BEGIN
           INSERT INTO vmscms.vms_token_transactionlog (vtt_pan_code,
                                                        vtt_pan_code_encr,
                                                        vtt_rrn,
                                                        vtt_auth_id,
                                                        vtt_token,
                                                        vtt_token_requestorid,
                                                        vtt_token_ref_id,
                                                        vtt_token_expiry_date,
                                                        vtt_token_status,
                                                        vtt_delivery_channel,
                                                        vtt_txn_code,
                                                        vtt_lifecycle_reqreason)
                VALUES (l_hash_pan,
                        l_encr_pan,
                        l_rrn,
                        l_activation_code,
                        l_current_token,
                        i.vti_token_requestor_id,
                        i.vti_token_ref_id,
                        i.vti_token_expiry_date,
                        g_token_status_tab(l_status).status_abbr,
                        l_delivery_channel,
                        l_txn_code,
                        p_comment_in);
        EXCEPTION
           WHEN OTHERS
           THEN
              RAISE e_update_token_status_failed;
        END;
      --EN:Added by FSS

      IF p_token_in <> 'ALL'
      THEN
        -- No need to loop for a single token
        EXIT;
      END IF;
      l_cnt := l_cnt + 1;

    END LOOP;

    OPEN p_token_dtls_out FOR
      SELECT * FROM TABLE(l_token_tab);

    p_cardno_out    := vmscms.fn_dmaps_main(l_encr_pan);
    p_exprydate_out := to_char(l_expiry_date,
                               'MMYY');
    --time taken
    l_end_time := dbms_utility.get_time;
    g_debug.display('l_end_time' || l_end_time);
    l_timetaken := (l_end_time - l_start_time);
    g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
    g_debug.display('Elapsed Time: ' || (l_end_time - l_start_time) / 100 ||
                    ' secs');

    p_status_out := vmscms.gpp_const.c_success_status;

        ----Commented for VMS-1719 - CCA RRN Logging Issue.

    /*vmscms.gpp_transaction.audit_transaction_log(l_api_name,
                                                 p_customer_id_in,
                                                 l_hash_pan,
                                                 l_encr_pan,
                                                 'C',
                                                 'SUCCESS',
                                                 vmscms.gpp_const.c_success_res_id,
                                                 substr(p_comment_in,
                                                        1,
                                                        255),
                                                 l_timetaken);*/

  EXCEPTION
    WHEN e_update_token_status_failed THEN
      p_status_out := vmscms.gpp_const.c_ora_error_status;
      g_err_update_token_status.raise(l_api_name,
                                      'CUSTOMER ID ' || p_customer_id_in ||
                                      ',TOKEN ' || p_token_in,
                                      vmscms.gpp_const.c_ora_error_status);
      p_err_msg_out := 'Update Token failed for ' || 'CUSTOMER ID ' ||
                       p_customer_id_in || ',TOKEN ' || l_current_token ||
                       ' at ' || l_curr_step;
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
  END update_token_status;

  PROCEDURE update_token_status(p_cardno_in      IN VARCHAR2,
                                p_new_cardno_in  IN VARCHAR2,
                                p_action_in      IN VARCHAR2, --'R'~Replace, 'U'~Update Status, 'A'~Activation
                                p_action_out     OUT VARCHAR2, --'R'~Token Replaced, 'D'~Token Deleted
                                p_old_card_out   OUT VARCHAR2,
                                p_old_expry_out  OUT VARCHAR2,
                                p_token_dtls_out OUT SYS_REFCURSOR,
                                p_err_msg_out    OUT VARCHAR2) IS
    l_token_dtls           token_details_rec_typ := token_details_rec_typ();
    l_delivery_channel     vmscms.cms_transaction_mast.ctm_delivery_channel%TYPE := '03';
    l_txn_code             vmscms.cms_transaction_mast.ctm_tran_code%TYPE := '94'; --Token Updated Txn
    l_token_status         vmscms.vms_token_info.vti_token_stat%TYPE;
    l_rrn                  vmscms.transactionlog.rrn%TYPE;
    l_stan                 vmscms.transactionlog.system_trace_audit_no%TYPE;
    l_activation_code      vmscms.transactionlog.auth_id%TYPE;
    l_acct_no              vmscms.cms_appl_pan.cap_acct_no%TYPE;
    l_encr_pan             vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
    l_prod_code            vmscms.cms_appl_pan.cap_prod_code%TYPE;
    l_card_type            vmscms.cms_appl_pan.cap_card_type%TYPE;
    l_card_stat            vmscms.cms_appl_pan.cap_card_stat%TYPE;
    l_acct_balance         vmscms.cms_acct_mast.cam_acct_bal%TYPE;
    l_ledger_balance       vmscms.cms_acct_mast.cam_ledger_bal%TYPE;
    l_acct_type            vmscms.cms_acct_mast.cam_type_code%TYPE;
    l_replace_provisioning vmscms.cms_prod_cattype.cpc_replacement_provision_flag%TYPE;
    l_card_no              vmscms.cms_appl_pan.cap_pan_code%TYPE;
    l_token_savepoint      NUMBER := 1;
	l_wallet_count         NUMBER; -- added for VMS_8349
	l_vms8349_toggle 	   cms_inst_param.cip_param_value%type :='Y';  -- added for VMS_8349

  BEGIN
    p_err_msg_out := 'OK';
    SAVEPOINT l_token_savepoint;
    l_card_no    := p_cardno_in;
    p_action_out := p_action_in;
    g_debug.display('start q123' );
    IF p_action_out <> 'U'
    THEN
      vmscms.gpp_tokens.update_token_cards(p_new_cardno_in,
                                           l_card_no,
                                           l_replace_provisioning,
                                           p_err_msg_out);
    END IF;

    IF nvl(l_replace_provisioning,
           'O') = 'N'
    THEN
      p_action_out := 'D';
    ELSIF p_action_in = 'R'
    THEN
      RETURN;
    ELSE
      l_card_no := p_cardno_in;
    END IF;
   g_debug.display('start 5345' );
    --Get card details for txn logging
    SELECT cap_prod_code,
           cap_card_type,
           cap_card_stat,
           cap_acct_no,
           cap_pan_code_encr,
           vmscms.fn_dmaps_main(cap_pan_code_encr),
           to_char(cap_expry_date,'MMYY')
      INTO l_prod_code,
           l_card_type,
           l_card_stat,
           l_acct_no,
           l_encr_pan,
           p_old_card_out,
           p_old_expry_out
      FROM vmscms.cms_appl_pan
     WHERE cap_pan_code = l_card_no;
    g_debug.display('start 87878' );
    SELECT ccs_token_stat
      INTO l_token_status
      FROM vmscms.cms_card_stat
     WHERE ccs_stat_code = l_card_stat
       AND ccs_inst_code = 1;

    g_debug.display('token status to be updated :' || l_token_status);

    --Get acct details for txn logging
    SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
      INTO l_acct_balance, l_ledger_balance, l_acct_type
      FROM vmscms.cms_acct_mast
     WHERE cam_acct_no = l_acct_no
       AND cam_inst_code = 1;

    g_debug.display('Acct no :' || l_acct_no);

    FOR l_idx IN (SELECT vti_token token,
                         vti_token_requestor_id,
                         vti_token_ref_id,
                         vti_token_expiry_date,
                         vti_token_stat,
                         vti_token_old_status,
						 vti_wallet_identifier, -- added for VMS_8349
                         CASE
                           WHEN p_action_out = 'A'
                                AND vti_token_stat <> l_token_status THEN --Condition added for FSS-5248
                           nvl(vti_token_old_status,
                                l_token_status)
                           ELSE
                            l_token_status
                         END token_stat
                    FROM vmscms.vms_token_info
                   WHERE vti_token_pan = l_card_no
                     AND vti_token_stat <> 'D')
    LOOP
      g_debug.display('token :' || l_idx.token);
      g_debug.display('status to update :' || l_idx.token_stat);

     IF NOT(l_idx.vti_token_stat='I' AND l_idx.vti_token_old_status IS NULL AND l_token_status='S') THEN
      --Update token status

				---Sn added for VMS_8349
			BEGIN
                Select CIP_PARAM_VALUE
				into l_vms8349_toggle
				from vmscms.cms_inst_param
				where cip_param_key='VMS_8349_TOGGLE';
			EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   l_vms8349_toggle:='Y';
                WHEN OTHERS THEN
                   p_err_msg_out := 'Error while selecting toggle value' ||
                   SUBSTR (SQLERRM, 1, 200);
			END;

		IF l_vms8349_toggle = 'Y' then

					SELECT count(*)
					  INTO l_wallet_count
					  FROM vmscms.vms_wallet_mast
					  WHERE lower(vwm_wallet_name) like '%apple%'
					  AND  vwm_wallet_id = l_idx.vti_token_requestor_id;--l_idx.vti_wallet_identifier; Modified for VMS_9234
		ELSE
			l_wallet_count := 0;
		END IF;
				---En added for VMS_8349

			IF NOT (l_card_stat = 2 and l_wallet_count > 0 ) THEN -- added for VMS_8349

			BEGIN
				UPDATE vmscms.vms_token_info
				   SET vti_token_stat = l_idx.token_stat
				 WHERE vti_token = l_idx.token
				   AND vti_token_stat <> l_idx.token_stat;

				IF SQL%ROWCOUNT = 0
				THEN
				  CONTINUE;
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
				  p_err_msg_out := 'Update TOKEN Status Failed For ' || l_idx.token || ' :' ||
								   SQLERRM;
				  EXIT;
			END;


      SELECT
            --SN: Changes VMS-8279 ~ HHMM has been replaced as HH24MI, Length of RRN changes to 15
            to_char( --substr(to_char(SYSDATE,'YYMMDDHHMMSS'),1,9)
            substr(to_char(SYSDATE,'YYMMDDHH24MISS'),4)
            --EN: Changes VMS-8279 ~ HHMM has been replaced as HH24MI
            || lpad(vmscms.seq_deppending_rrn.nextval,
                                       3,
                                       '0')),
             lpad(vmscms.seq_auth_stan.nextval,
                  6,
                  '0'),
             lpad(vmscms.seq_auth_id.nextval,
                  6,
                  '0')
        INTO l_rrn, l_stan, l_activation_code
        FROM dual;

      g_debug.display('rrn :' || l_rrn);
      g_debug.display('stan :' || l_stan);
      g_debug.display('auth_id :' || l_activation_code);



      g_debug.display('inserting token dtls into token array');
      l_token_dtls.extend;
      l_token_dtls(l_token_dtls.last) := token_details_type(l_idx.token,
                                                            g_token_msgreasoncode_tab(l_idx.token_stat),
                                                            l_stan,
                                                            l_rrn,
                                                            l_activation_code,
                                                           'Token ' || (CASE
                                                             l_idx.token_stat
                                                              WHEN 'S' THEN
                                                               'Suspended'
                                                              WHEN 'D' THEN
                                                               'Deleted'
                                                              WHEN 'A' THEN
                                                               'Resumed'
                                                            END) ||
                                                            ' Due to Card Status Change',
                                                            '000000');

      g_debug.display('inserting token status update txn into token_transactionlog');


      BEGIN
        INSERT INTO vmscms.vms_token_transactionlog
          (vtt_pan_code,
           vtt_pan_code_encr,
           vtt_rrn,
           vtt_auth_id,
           vtt_token,
           vtt_token_requestorid,
           vtt_token_ref_id,
           vtt_token_expiry_date,
           vtt_token_status,
           vtt_delivery_channel,
           vtt_txn_code,
           vtt_lifecycle_reqreason)
        VALUES
          (l_card_no,
           l_encr_pan,
           l_rrn,
           l_activation_code,
           l_idx.token,
           l_idx.vti_token_requestor_id,
           l_idx.vti_token_ref_id,
           l_idx.vti_token_expiry_date,
           l_idx.token_stat,
           l_delivery_channel,
           l_txn_code,
           'Token ' || decode(l_idx.token_stat,
                              'S',
                              'Suspended',
                              'D',
                              'Deleted',
                              'A',
                              'Resumed') || ' Due to Card Status Change');
      EXCEPTION
        WHEN OTHERS THEN
          p_err_msg_out := 'Error while logging system initiated token status update into token_txnlog' ||
                           SQLERRM;
          EXIT;
      END;

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
           system_trace_audit_no,
           remark,
           time_stamp,
           fsapi_username,
           ipaddress)
        VALUES
          ('0200',
           l_rrn,
           l_delivery_channel,
           l_txn_code,
           (SELECT ctm_tran_desc
              FROM vmscms.cms_transaction_mast
             WHERE ctm_inst_code = 1
               AND ctm_tran_code = l_txn_code
               AND ctm_delivery_channel = l_delivery_channel),
           '0',
           0,
           l_card_no,
           l_encr_pan,
           to_char(SYSDATE,
                   'yyyymmdd'),
           to_char(SYSDATE,
                   'hh24miss'),
           'C',
           '00',
           l_activation_code,
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
           'Token ' || decode(l_idx.token_stat,
                              'S',
                              'Suspended',
                              'D',
                              'Deleted',
                              'A',
                              'Resumed') || ' Due to Card Status Change',
         systimestamp,
        (sys_context(fsfw.fsconst.c_fsapi_gpp_context, 'x-incfs-username')),
         (sys_context(fsfw.fsconst.c_fsapi_gpp_context, 'x-incfs-ip')));
      EXCEPTION
        WHEN OTHERS THEN
          p_err_msg_out := 'Error while logging system initiated token status update txn' ||
                           SQLERRM;
          EXIT;
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
          (l_delivery_channel,
           l_txn_code,
           '0',
           '0200',
           0,
           to_char(SYSDATE,
                   'yyyymmdd'),
           to_char(SYSDATE,
                   'hh24miss'),
           l_card_no,
           'Y',
           'Successful',
           l_rrn,
           1,
           l_encr_pan,
           l_acct_no,
           l_stan,
           l_activation_code);
      EXCEPTION
        WHEN OTHERS THEN
          p_err_msg_out := 'Error while logging system initiated token status update txn dtls' ||
                           SQLERRM;
          EXIT;
      END;
      END IF;
	  END IF;
    END LOOP;

    IF p_err_msg_out = 'OK'
    THEN
      OPEN p_token_dtls_out FOR
        SELECT token,
               msgreasoncode messagereasoncode,
               stan,
               rrn,
               activationcode,
               requestreason,
               forwardinstidcode forwardinstcode
          FROM TABLE(l_token_dtls);

      g_debug.display('return token array');
    ELSE
      ROLLBACK TO l_token_savepoint;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      p_err_msg_out := 'UPDATE TOKEN STATUS FAILED' || SQLERRM;
  END update_token_status;

  -- the init procedure is private and should ALWAYS exist
  PROCEDURE init IS
  BEGIN
    -- initialize all errors here
    g_err_nodata              := fsfw.fserror_t('E-NO-DATA',
                                                '$1 $2');
    g_err_unknown             := fsfw.fserror_t('E-UNKNOWN',
                                                'Unknown error: $1 $2',
                                                'NOTIFY');
    g_err_mandatory           := fsfw.fserror_t('E-MANDATORY',
                                                'Mandatory Field is NULL: $1 $2 $3',
                                                'NOTIFY');
    g_err_invalid_data        := fsfw.fserror_t('E-INVALID_DATA',
                                                'ACCOUNT TYPE: $1 $2 $3');
    g_err_savingacc           := fsfw.fserror_t('E-FETCH-SAVINGACC',
                                                'Fetch saving acc details: $1 $2 $3');
    g_err_feewaiver           := fsfw.fserror_t('E-FEEWAIVER',
                                                'Fee waiver calculation: $1 $2 $3');
    g_err_failure             := fsfw.fserror_t('E-FAILURE',
                                                'Procedure failed: $1 $2 $3');
    g_err_invalid_status      := fsfw.fserror_t('E-INVALID_STATUS',
                                                'TOKEN STATUS: $1 $2 $3');
    g_err_update_token_status := fsfw.fserror_t('E-UPDATE_TOKEN_FAILED',
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

    -- Populate the token status array.
    g_token_status_tab('DELETE TOKEN').status_code := '3701';
    g_token_status_tab('DELETE TOKEN').status_abbr := 'D';

    g_token_status_tab('SUSPEND TOKEN').status_code := '3702';
    g_token_status_tab('SUSPEND TOKEN').status_abbr := 'S';

    g_token_status_tab('RESUME TOKEN').status_code := '3703';
    g_token_status_tab('RESUME TOKEN').status_abbr := 'A';

    --CFIP-416 starts
    FOR l_idx IN (SELECT vts_token_stat, vts_reason_code
                    FROM vmscms.vms_token_status)
    LOOP
      g_token_msgreasoncode_tab(l_idx.vts_token_stat) := l_idx.vts_reason_code;
    END LOOP;
    --CFIP-416 ends

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
END gpp_tokens;
/
show error