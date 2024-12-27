create or replace PACKAGE BODY  vmscms.GPP_DISPUTE IS

   -- PL/SQL Package using FS Framework
   -- Author  : Rojalin Beura
   -- Created : 11/18/2015 2:42:10 PM

   -- Private type declarations
   -- TEST 1

   -- Private constant declarations

   -- Private variable declarations
   TYPE ty_rec_txn IS RECORD(
      txn_id                  VARCHAR2(50),
      txn_date                VARCHAR2(50),
      txn_deliverychannelcode VARCHAR2(50),
      txn_transactioncode     VARCHAR2(50),
      txn_responsecode        VARCHAR2(50),
      txn_reason              VARCHAR2(500));

   TYPE ty_tbl_txn IS TABLE OF ty_rec_txn INDEX BY PLS_INTEGER;
   g_tbl_data_txn ty_tbl_txn;

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

   -- the init procedure is private and should ALWAYS exist
   PROCEDURE get_dispute_trans_info
   (
      p_customer_id_in        IN VARCHAR2,
      p_txn_id_in             IN VARCHAR2,
      p_txn_date_in           IN VARCHAR2,
      p_delivery_channel_in   IN VARCHAR2,
      p_txn_code_in           IN VARCHAR2,
      p_response_code_in      IN VARCHAR2,
      p_status_out            OUT VARCHAR2,
      p_err_msg_out           OUT VARCHAR2,
      c_dispute_trans_out     OUT SYS_REFCURSOR,
      c_dispute_trans_doc_out OUT SYS_REFCURSOR
   ) AS
      l_hash_pan   vmscms.cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan   vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
      l_field_name VARCHAR2(20);
      l_flag       PLS_INTEGER := 0;
      l_api_name   VARCHAR2(50) := 'GET DISPUTE TRANSACTION INFO';
      l_partner_id vmscms.cms_dispute_txns.cdt_partner_id%TYPE;
      l_start_time NUMBER;
      l_end_time   NUMBER;
      l_timetaken  NUMBER;
      l_cust_code  cms_cust_mast.ccm_cust_code%TYPE;

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
      -- APLS-597
      /*l_partner_id := (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
      'x-incfs-partnerid'));*/

      --Check for madatory fields
      CASE
         WHEN p_customer_id_in IS NULL THEN
            l_field_name := 'CUSTOMER ID';
            l_flag       := 1;
         WHEN p_txn_id_in IS NULL THEN
            l_field_name := 'TRANSACTION ID';
            l_flag       := 1;
         WHEN p_txn_date_in IS NULL THEN
            l_field_name := 'TRANSACTION DATE';
            l_flag       := 1;
         WHEN p_delivery_channel_in IS NULL THEN
            l_field_name := 'DELIVERY CHANNEL';
            l_flag       := 1;
         WHEN p_txn_code_in IS NULL THEN
            l_field_name := 'TRANSACTION CODE';
            l_flag       := 1;
            /*WHEN p_response_code_in IS NULL THEN
            l_field_name := 'RESPONSE CODE';
            l_flag       := 1;*/
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
                                                      l_timetaken);
         RETURN;
      END IF;
      --Fetching the active PAN for the input customer id
      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                     l_hash_pan,
                                     l_encr_pan);

      g_debug.display('l_hash_pan' || l_hash_pan);
      g_debug.display('l_encr_pan' || l_encr_pan);

      -- APLS-597 changes
      SELECT ccm_cust_code
        INTO l_cust_code
        FROM cms_cust_mast
       WHERE ccm_cust_id = p_customer_id_in; -- 100591743

      OPEN c_dispute_trans_out FOR
         SELECT (SELECT rrn
                   FROM VMSCMS.TRANSACTIONLOG_VW  --Added for VMS-5733/FSP-991
                  WHERE customer_acct_no = c.cap_acct_no --'0610003475809'--'9870000005097'
                    AND delivery_channel = '03' --(this is static value - hardcoded)
                    AND txn_code = '25' -- (This is static value - hardcoded)
                    AND response_code = '00' -- (This is static value - hardcoded)
                    AND orgnl_rrn = a.cdt_rrn
                    AND orgnl_business_date = a.cdt_txn_date
                    AND orgnl_business_time = a.cdt_txn_time) case_number,
                /*c.cap_acct_no,
                c.cap_cust_code,
                a.cdt_rrn,
                a.cdt_txn_date,
                a.cdt_txn_time,*/
                CASE a.cdt_dispute_status
                   WHEN 'O' THEN
                    (CASE nvl(a.cdt_ins_user, 0)
                       WHEN 0 THEN
                        a.cdt_fsapi_username
                       ELSE
                        (SELECT cum_user_name
                           FROM vmscms.cms_userdetl_mast
                          WHERE cum_user_code = cdt_ins_user)
                    END)
                   ELSE
                    (CASE nvl(a.cdt_ins_user, 0)
                       WHEN 0 THEN
                        a.cdt_fsapi_updusrname
                       ELSE
                        (SELECT cum_user_name
                           FROM vmscms.cms_userdetl_mast
                          WHERE cum_user_code = cdt_lupd_user)
                    END)
                END AS callagentusername,
                to_char(a.cdt_ins_date, 'YYYY-MM-DD') initiated_date,
                a.cdt_call_id session_id,
                CASE a.cdt_dispute_status
                   WHEN 'A' THEN
                    'Dispute Approved'
                   WHEN 'R' THEN
                    'Dispute Rejected'
                   ELSE
                    'Dispute yet to be approved or rejected'
                END AS disputestatus,
                a.cdt_rrn transactionid,
                to_char(to_date(a.cdt_txn_date || ' ' || a.cdt_txn_time,
                                'yyyymmdd hh24:mi:ss'),
                        'yyyy-mm-dd hh24:mi:ss') txn_date,
                a.cdt_delivery_channel deliverychannelcode,
                a.cdt_txn_code transactioncode,
                '00' responsecode,
                a.cdt_reason reason,
                a.cdt_final_remark comments
         -- Changed to separate result set as user may submit more than one doc
         /*cfu_file_type file_type,
         to_char(cfu_ins_date,
                 'yyyy-mm-dd') file_date,
         substr(cfu_file_path,
                -instr(REVERSE(cfu_file_path),
                       '/') + 1) file_name*/
           FROM vmscms.cms_dispute_txns a,
                --vmscms.cms_fileupload_detl b,
                vmscms.cms_appl_pan c
          WHERE a.cdt_pan_code = c.cap_pan_code
            AND c.cap_cust_code = l_cust_code --658292
            AND a.cdt_rrn = p_txn_id_in -- '135152188021' --'144001876357' --'144027436182'
            AND a.cdt_delivery_channel = p_delivery_channel_in -- '02'
            AND a.cdt_txn_code = p_txn_code_in -- '14'
            AND a.cdt_txn_date =
                to_char(to_date(p_txn_date_in, 'YYYY-MM-DD'), 'YYYYMMDD'); --'20140722'
      --AND cdt_partner_id IN (l_partner_id)
      --AND a.cdt_rrn = b.cfu_ref_number(+)
      --AND b.cfu_file_type(+) = 'DISPUTEPROCESS';

      -- To get array of documents for given dispute transaction.

      OPEN c_dispute_trans_doc_out FOR
         SELECT rownum id, file_type, file_date, file_name
           FROM (SELECT cfu_file_type file_type,
                        to_char(cfu_ins_date, 'yyyy-mm-dd') file_date,
                        substr(cfu_file_path,
                               -instr(REVERSE(cfu_file_path), '/') + 1) file_name
                   FROM vmscms.cms_fileupload_detl
                  WHERE cfu_ref_number = p_txn_id_in
                    AND cfu_file_type = 'DISPUTEPROCESS'
                  ORDER BY cfu_ins_date DESC);

      --time taken
      l_end_time := dbms_utility.get_time;
      g_debug.display('l_end_time' || l_end_time);
      l_timetaken := (l_end_time - l_start_time);
      g_debug.display('Elapsed Time: ' || l_timetaken || ' milisecs');
      g_debug.display('Elapsed Time: ' ||
                      (l_end_time - l_start_time) / 100 || ' secs');
      p_status_out := vmscms.gpp_const.c_success_status;
     /* vmscms.gpp_transaction.audit_transaction_log(l_api_name,      ----Commented for VMS-1719 - CCA RRN Logging Issue.
                                                   p_customer_id_in,
                                                   l_hash_pan,
                                                   l_encr_pan,
                                                   'C',
                                                   'SUCCESS',
                                                   1,
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
         g_err_unknown.raise(l_api_name,
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

   END get_dispute_trans_info;
   PROCEDURE parse_data_txn
   (
      p_dispute_array_in IN VARCHAR2,
      g_tbl_data_txn     OUT ty_tbl_txn,
      p_api_name_in      IN VARCHAR2,
      p_status_out       OUT VARCHAR2,
      p_err_msg_out      OUT VARCHAR2
   ) AS
      l_txn_arr   fsfw.fslist_t := fsfw.fslist_t();
      l_txn       VARCHAR2(4000);
      l_cnt       PLS_INTEGER;
      l_start_pos PLS_INTEGER := 1;
      l_length    PLS_INTEGER := 0;
      l_occ1      PLS_INTEGER;
      l_occ2      PLS_INTEGER;
      l_occ3      PLS_INTEGER;
      l_occ4      PLS_INTEGER;
      l_occ5      PLS_INTEGER;
      l_occ6      PLS_INTEGER;
   BEGIN
      --Parsing the records from input txn array

      l_txn := REPLACE(p_dispute_array_in, '||', ',');
      l_cnt := regexp_count(l_txn, ',');

      l_txn_arr.extend();
      l_txn_arr(1) := substr(l_txn, 1, instr(l_txn, ',') - 1);

      FOR idx IN 1 .. l_cnt
      LOOP
         l_txn_arr.extend();
         g_debug.display(g_debug.format('after extent idx : $1',
                                        l_txn_arr(idx)));

         l_start_pos := instr(l_txn, ',', 1, idx) + 1;

         g_debug.display('start_position:' || l_start_pos);

         l_length := (instr(l_txn, ',', 1, idx + 1) -
                     instr(l_txn, ',', 1, idx)) - 1;

         g_debug.display('length valus is:' || l_length);

         l_txn_arr(idx + 1) := substr(l_txn, l_start_pos, l_length);

         g_debug.display('after array at the end:' || l_txn_arr(idx + 1));

      END LOOP;
      l_txn_arr(l_cnt + 1) := substr(l_txn, instr(l_txn, ',', -1) + 1);

      g_debug.display('after loop array at the end:' ||
                      l_txn_arr(l_cnt + 1));

      --Parsing the fields from the parsed records

      FOR idx IN l_txn_arr.first .. l_txn_arr.last
      LOOP
         l_occ1 := instr(l_txn_arr(idx), '~');
         g_debug.display('Location_1:' || l_occ1);

         g_tbl_data_txn(idx).txn_id := substr(l_txn_arr(idx), 1, l_occ1 - 1);

         g_debug.display('Location_1_value is :' || g_tbl_data_txn(idx)
                         .txn_id);
         l_occ2 := instr(l_txn_arr(idx), '~', 1, 2);

         g_tbl_data_txn(idx).txn_date := substr(l_txn_arr(idx),
                                                l_occ1 + 1,
                                                (l_occ2 - l_occ1) - 1);
         g_debug.display('Location_2:' || l_occ2);
         g_debug.display('Location_2_value is :' || g_tbl_data_txn(idx)
                         .txn_date);

         l_occ3 := instr(l_txn_arr(idx), '~', 1, 3);
         g_tbl_data_txn(idx).txn_deliverychannelcode := substr(l_txn_arr(idx),
                                                               l_occ2 + 1,
                                                               (l_occ3 -
                                                               l_occ2) - 1);
         g_debug.display('Location_3:' || l_occ3);
         g_debug.display('Location_3_value is :' || g_tbl_data_txn(idx)
                         .txn_deliverychannelcode);

         l_occ4 := instr(l_txn_arr(idx), '~', 1, 4);
         g_tbl_data_txn(idx).txn_transactioncode := substr(l_txn_arr(idx),
                                                           l_occ3 + 1,
                                                           (l_occ4 - l_occ3) - 1);
         g_debug.display('Location_4:' || l_occ4);
         g_debug.display('Location_4_value is :' || g_tbl_data_txn(idx)
                         .txn_transactioncode);

         l_occ5 := instr(l_txn_arr(idx), '~', 1, 5);
         g_tbl_data_txn(idx).txn_responsecode := substr(l_txn_arr(idx),
                                                        l_occ4 + 1,
                                                        (l_occ5 - l_occ4) - 1);
         g_debug.display('Location_5:' || l_occ5);
         g_debug.display('Location_5_value is :' || g_tbl_data_txn(idx)
                         .txn_responsecode);

         g_tbl_data_txn(idx).txn_reason := substr(l_txn_arr(idx),
                                                  l_occ5 + 1);

         g_debug.display('Location_6_value is :' || g_tbl_data_txn(idx)
                         .txn_reason);

      END LOOP;
   EXCEPTION
      WHEN OTHERS THEN
         p_status_out := vmscms.gpp_const.c_ora_error_status;
         g_err_unknown.raise(p_api_name_in,
                             vmscms.gpp_const.c_ora_error_status);
         p_err_msg_out := g_err_unknown.get_current_error;
         RETURN;
   END parse_data_txn;
   PROCEDURE dispute_transaction
   (
      p_customer_id_in    IN VARCHAR2,
      p_deliverymethod_in IN VARCHAR2,
      p_dispute_array_in  IN VARCHAR2,
      p_comment_in        IN VARCHAR2,
      p_status_out        OUT VARCHAR2,
      p_err_msg_out       OUT VARCHAR2
   ) AS
      l_hash_pan            vmscms.cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan            vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
      l_api_name            VARCHAR2(20) := 'DISPUTE TRANSACTION';
      l_plain_pan           VARCHAR2(50);
      l_curr_code           VARCHAR2(20);
      l_date                VARCHAR2(50);
      l_time                VARCHAR2(50);
      l_partner_id          vmscms.cms_cust_mast.ccm_partner_id%TYPE;
      l_mbr_numb            vmscms.cms_appl_pan.cap_mbr_numb%TYPE;
      l_rrn                 vmscms.transactionlog.rrn%TYPE;
      l_field_name          VARCHAR2(20);
      l_flag                PLS_INTEGER := 0;
      l_tran_date           vmscms.transactionlog.business_date%TYPE;
      l_business_date       vmscms.transactionlog.business_date%TYPE;
      l_business_time       vmscms.transactionlog.business_time%TYPE;
      l_orgnl_amount        vmscms.transactionlog.amount%TYPE;
      l_txn_code            vmscms.transactionlog.txn_code%TYPE;
      l_delivery_channel    vmscms.transactionlog.delivery_channel%TYPE;
      l_reason_desc         vmscms.cms_spprt_reasons.csr_reasondesc%TYPE;
      l_delivery_channel_in vmscms.transactionlog.delivery_channel%TYPE;
      l_txn_code_in         vmscms.transactionlog.txn_code%TYPE;
      l_response_code_in    vmscms.transactionlog.response_code%TYPE;
      l_orgnl_card_no       VARCHAR2(200);
      l_orgnl_rrn           vmscms.transactionlog.rrn%TYPE;
      l_txn_id_in           vmscms.transactionlog.rrn%TYPE;
      l_orgnl_stan          vmscms.transactionlog.system_trace_audit_no%TYPE;
      l_reason_in           vmscms.cms_spprt_reasons.csr_spprt_rsncode%TYPE;
      l_start_time          NUMBER;
      l_end_time            NUMBER;
      l_timetaken           NUMBER;
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

v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
   BEGIN
      --Fetching the active PAN for the input customer id
      l_start_time := dbms_utility.get_time;
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
      --Check for mandatory fields
      CASE
         WHEN p_customer_id_in IS NULL THEN
            l_field_name := 'CUSTOMER ID';
            l_flag       := 1;

         WHEN p_deliverymethod_in IS NULL THEN
            l_field_name := 'DELIVERYMETHOD';
            l_flag       := 1;
         WHEN p_comment_in IS NULL THEN
            l_field_name := 'COMMENT';
            l_flag       := 1;

         ELSE
            NULL;
      END CASE;

      g_debug.display('Calling parse_data_txn_procedure');
      --    g_debug.display('calling alerts parsing');
      parse_data_txn(p_dispute_array_in,
                     g_tbl_data_txn,
                     l_api_name,
                     p_status_out,
                     p_err_msg_out);

      --    g_debug.display('input array of dispute');
      /*
        FOR i IN g_tbl_data_txn.first .. g_tbl_data_txn.last
      LOOP
         --     g_debug.display(g_debug.format('txn_id id : $1',
         g_tbl_data_txn(i).txn_id));
         --     g_debug.display(g_debug.format('txn_date : $2',
         g_tbl_data_txn(i).txn_date));
         --     g_debug.display(g_debug.format('txn_deliveryChannelCode : $3',
         g_tbl_data_txn(i).txn_deliverychannelcode));
         --      g_debug.display(g_debug.format('txn_transactionCode : $4',
         g_tbl_data_txn(i).txn_transactioncode));
         --     g_debug.display(g_debug.format('txn_responseCode : $5',
         g_tbl_data_txn(i).txn_responsecode));
         --     g_debug.display(g_debug.format('txn_reason: $6',
         g_tbl_data_txn(i).txn_reason));
         ---   g_debug.display(g_debug.format('txn_comment : $7',
         g_tbl_data_txn(i).txn_comment));
      END LOOP;*/
      g_debug.display('before loop of check null in array');

      g_debug.display('flag is :' || l_flag);

      FOR idx IN g_tbl_data_txn.first .. g_tbl_data_txn.last
      LOOP
         CASE
            WHEN g_tbl_data_txn(idx).txn_id IS NULL THEN
               l_field_name := 'ArrayTRANSACTION_ID ' || idx;
               l_flag       := 1;

            WHEN g_tbl_data_txn(idx).txn_date IS NULL THEN
               l_field_name := 'Array_txn_date ' || idx;
               l_flag       := 1;

            WHEN g_tbl_data_txn(idx).txn_deliverychannelcode IS NULL THEN
               l_field_name := 'Array_txn_deliveryChannelCode ' || idx;
               l_flag       := 1;

            WHEN g_tbl_data_txn(idx).txn_transactioncode IS NULL THEN
               l_field_name := 'Array_txn_transactionCode ' || idx;
               l_flag       := 1;

            WHEN g_tbl_data_txn(idx).txn_responsecode IS NULL THEN
               l_field_name := 'Array_txn_responseCode ' || idx;
               l_flag       := 1;

            WHEN g_tbl_data_txn(idx).txn_reason IS NULL THEN
               l_field_name := 'Array_txn_reason ' || idx;
               l_flag       := 1;
            ELSE
               NULL;

         END CASE;
      END LOOP;

      g_debug.display('after loop of check null in array');
      g_debug.display('flag is :' || l_flag);

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

      g_debug.display('enter in to select statement');
      ---fetching mbr_number
      SELECT cap_mbr_numb
        INTO l_mbr_numb
        FROM vmscms.cms_appl_pan
       WHERE cap_pan_code = l_hash_pan;

      g_debug.display('mbr_number:' || l_mbr_numb);

      g_debug.display('enter in to select statement 2');



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

      g_debug.display('currency_code:' || l_curr_code);

      --  g_debug.display('l_curr_code' || l_curr_code);
      --getting the date
      l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                   'x-incfs-date'),
                       6,
                       11);
      --l_date := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11);
      l_date := to_char(to_date(l_date, 'dd-mm-yyyy'), 'yyyymmdd');
      g_debug.display('date value is:' || l_date);

      --getting the time
      l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                    'x-incfs-date')),
                       18,
                       8);

      l_time := REPLACE(l_time, ':', '');
      --l_time := '110045';
      g_debug.display('time value is :' || l_time);

      --fetching the reason description
      g_debug.display('before select for reason desc');
      FOR idx IN g_tbl_data_txn.first .. g_tbl_data_txn.last
      LOOP

         g_debug.display('after loop for reason desc' ||
                         upper(g_tbl_data_txn(idx).txn_reason));
         l_reason_in := upper(g_tbl_data_txn(idx).txn_reason);
         g_debug.display('l_reason_in valuse is  :' || l_reason_in);

         SELECT csr_reasondesc
           INTO l_reason_desc
           FROM vmscms.cms_spprt_reasons
          WHERE upper(csr_spprt_key) = 'DISPUTE'
            AND csr_spprt_rsncode = l_reason_in
            AND csr_inst_code = '1';

         g_debug.display('after loop for reason desc_value_saved:' ||

                         l_reason_desc);

         l_tran_date := to_char(trunc(to_date(g_tbl_data_txn(idx).txn_date,
                                              'YYYY-MM-DD HH24:MI:SS')),
                                'YYYYMMDD');
         g_debug.display('after loop for transaction date:' || l_tran_date);

         l_delivery_channel_in := upper(g_tbl_data_txn(idx)
                                        .txn_deliverychannelcode);
         g_debug.display('after loop for l_delivery_channel_in :' ||
                         l_delivery_channel_in);

         l_txn_code_in := upper(g_tbl_data_txn(idx).txn_transactioncode);
         g_debug.display('after loop for l_txn_code_in :' || l_txn_code_in);
         l_response_code_in := upper(g_tbl_data_txn(idx).txn_responsecode);
         g_debug.display('after loop for l_response_code_in :' ||
                         l_response_code_in);

         l_txn_id_in := upper(g_tbl_data_txn(idx).txn_id);
         g_debug.display('after loop for l_txn_id_in :' || l_txn_id_in);

         --- fetching the original details
		 
		 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
		 
         SELECT business_date orgnl_tran_date,
                business_time orgnl_tran_time,
                nvl(amount, 0.00) orgnl_txn_amount,
                txn_code orgnl_txn_code,
                delivery_channel orgnl_delivery_chnl,
                rrn orgnl_rrn,
                vmscms.fn_dmaps_main(customer_card_no_encr) orgnl_card_no,
                system_trace_audit_no orgnl_stan
           INTO l_business_date,
                l_business_time,
                l_orgnl_amount,
                l_txn_code,
                l_delivery_channel,
                l_orgnl_rrn,
                l_orgnl_card_no,
                l_orgnl_stan
           FROM VMSCMS.TRANSACTIONLOG  --Added for VMS-5733/FSP-991
          WHERE rrn = l_txn_id_in
            AND delivery_channel = l_delivery_channel_in
            AND txn_code = l_txn_code_in
            AND response_code = l_response_code_in
            AND business_date = l_tran_date;
		ELSE
		
		SELECT business_date orgnl_tran_date,
                business_time orgnl_tran_time,
                nvl(amount, 0.00) orgnl_txn_amount,
                txn_code orgnl_txn_code,
                delivery_channel orgnl_delivery_chnl,
                rrn orgnl_rrn,
                vmscms.fn_dmaps_main(customer_card_no_encr) orgnl_card_no,
                system_trace_audit_no orgnl_stan
           INTO l_business_date,
                l_business_time,
                l_orgnl_amount,
                l_txn_code,
                l_delivery_channel,
                l_orgnl_rrn,
                l_orgnl_card_no,
                l_orgnl_stan
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
          WHERE rrn = l_txn_id_in
            AND delivery_channel = l_delivery_channel_in
            AND txn_code = l_txn_code_in
            AND response_code = l_response_code_in
            AND business_date = l_tran_date;

END IF;		

         g_debug.display('BD:' || l_business_date);

         g_debug.display('BT:' || l_business_time);
         g_debug.display('OA:' || l_orgnl_amount);
         g_debug.display('TC:' || l_txn_code);
         g_debug.display('DC:' || l_delivery_channel);
         g_debug.display('ORRN:' || l_orgnl_rrn);
         g_debug.display('OCN:' || l_orgnl_card_no);

         g_debug.display('OS:' || l_orgnl_stan);

         g_debug.display('calling sp_dispute_txns');

         g_debug.display('calling sp_dispute_txns');
         g_debug.display('PLAIN_PAN:' || l_plain_pan);
         g_debug.display('MBR:' || l_mbr_numb);
         g_debug.display('RRN:' || l_rrn);
         g_debug.display('DATE:' || l_date);
         g_debug.display('TIME:' || l_date);
         g_debug.display('ORIG_RRN:' || l_orgnl_rrn);
         g_debug.display('ORIG_CARD:' || l_orgnl_card_no);
         g_debug.display('ORGISTA:' || l_orgnl_stan);
         g_debug.display('BUISNESS DAY:' || l_business_date);
         g_debug.display('BUSINESS TIME:' || l_business_time);
         g_debug.display('ORIGINAL AMT:' || l_orgnl_amount);
         g_debug.display('TXN CODE :' || l_txn_code);
         g_debug.display('ORIGINAL AMT:' || l_orgnl_amount);
         g_debug.display('DELIVERY CHANNEL:' || l_delivery_channel);
         g_debug.display('CURR CODE:' || l_curr_code);
         --fetching the rrn
         SELECT to_char(to_char(SYSDATE, 'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                        lpad(vmscms.seq_deppending_rrn.nextval, 3, '0'))
           INTO l_rrn
           FROM dual;
         vmscms.sp_dispute_txns(1, --prm_instcode
                                l_orgnl_card_no, --l_plain_pan, --prm_pancode
                                '0200', --prm_msg_type
                                l_mbr_numb, --prm_mbrnumb
                                0, --prm_amount
                                l_rrn, --prm_rrn
                                NULL, -- prm_stan
                                '03', --prm_delv_chnl
                                l_date, -- prm_txn_date
                                l_time, -- prm_txn_time
                                25, --prm_txn_code
                                0, -- prm_txn_mode
                                l_orgnl_rrn, --prm_orgnl_rrn
                                l_orgnl_card_no, -- prm_orgnl_card_no
                                l_orgnl_stan, --prm_orgnl_stan
                                l_business_date, --prm_orgnl_tran_date
                                l_business_time, -- prm_orgnl_tran_time
                                l_orgnl_amount, --prm_orgnl_txn_amt
                                l_txn_code, -- prm_orgnl_txn_code
                                l_delivery_channel, --prm_orgnl_delivery_chnl,
                                (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                             'x-incfs-sessionid')), --prm_call_id
                                'O', --prm_dispute_stat
                                '01', -- prm_reversal_code
                                l_curr_code, -- prm_curr_code
                                p_comment_in, --prm_remark
                                l_reason_in, --IN parameter l_reason_desc replaced with l_reason_in due to change in the base SP, -- prm_reasondesc
                                (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                             'x-incfs-ip')), -- prm_ipaddress
                                NULL, --prm_lupduser,
                                p_status_out, --prm_resp_code
                                p_err_msg_out -- prm_resp_msg
                                );

         g_debug.display('p_status_out' || p_status_out);
         g_debug.display('p_err_msg_out' || p_err_msg_out);

         -- CFIP 364, This will update fsapi username as base procedure is not taking care of this.
         update vmscms.cms_dispute_txns
              set CDT_FSAPI_USERNAME = (sys_context(fsfw.fsconst.c_fsapi_gpp_context, 'x-incfs-username'))
          where cdt_inst_code    = 	1
             and cdt_pan_code    =   vmscms.gethash(l_orgnl_card_no)
             and cdt_txn_date     =   l_business_date
             and cdt_txn_time    =   l_business_time
             and cdt_rrn            =   l_orgnl_rrn;

      END LOOP;
      --updating the below fields manually
      --since the base procedure doesnot populate these fields in Transactionlog
      UPDATE VMSCMS.TRANSACTIONLOG  
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
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
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
         p_status_out := vmscms.gpp_const.c_dispute_transaction_status;
         g_err_unknown.raise(l_api_name || ' FAILED',
                             vmscms.gpp_const.c_dispute_transaction_status);
         p_err_msg_out := g_err_unknown.get_current_error;

   END dispute_transaction;

   PROCEDURE update_dispute
   (
      p_customer_id_in      IN VARCHAR2,
      p_txn_id_in           IN VARCHAR2,
      p_txn_date_in         IN VARCHAR2,
      p_delivery_channel_in IN VARCHAR2,
      p_txn_code_in         IN VARCHAR2,
      p_response_code_in    IN VARCHAR2,
      p_isapproved_in       IN VARCHAR2,
      p_refund_type_in      IN VARCHAR2,
      p_comment_in          IN VARCHAR2,
      p_status_out          OUT VARCHAR2,
      p_err_msg_out         OUT VARCHAR2

   ) AS
      l_encr_pan         vmscms.cms_appl_pan.cap_pan_code_encr%TYPE;
      l_hash_pan         vmscms.cms_appl_pan.cap_pan_code%TYPE;
      l_plain_pan        VARCHAR2(50);
      l_date             VARCHAR2(50);
      l_time             VARCHAR2(50);
      l_api_name         VARCHAR2(50) := 'UPDATE DISPUTE';
      l_rrn              vmscms.transactionlog.rrn%TYPE;
      l_field_name       VARCHAR2(20);
      l_flag             PLS_INTEGER := 0;
      l_mbr_numb         vmscms.cms_appl_pan.cap_mbr_numb%TYPE;
      l_business_date    vmscms.transactionlog.business_date%TYPE;
      l_business_time    vmscms.transactionlog.business_time%TYPE;
      l_orgnl_amount     vmscms.transactionlog.amount%TYPE;
      l_txn_code         vmscms.transactionlog.txn_code%TYPE;
      l_delivery_channel vmscms.transactionlog.delivery_channel%TYPE;
      l_reason_desc      vmscms.cms_spprt_reasons.csr_reasondesc%TYPE;
      --L_ORGNL_CARD_NO    VMSCMS.TRANSACTIONLOG.CUSTOMER_CARD_NO_ENCR%TYPE;
      l_orgnl_card_no NUMBER;
      l_orgnl_rrn     vmscms.transactionlog.rrn%TYPE;
      l_orgnl_stan    vmscms.transactionlog.system_trace_audit_no%TYPE;
      l_tran_date     vmscms.transactionlog.business_date%TYPE;
      l_dispute       vmscms.transactionlog.dispute_flag%TYPE;
      l_tran_rev_flag vmscms.transactionlog.tran_reverse_flag%TYPE;
      l_fee_rev_flag  vmscms.transactionlog.fee_reversal_flag%TYPE;
      l_reversal_code vmscms.transactionlog.reversal_code%TYPE;
      l_start_time    NUMBER;
      l_end_time      NUMBER;
      l_timetaken     NUMBER;
      l_call_seq      vmscms.cms_calllog_details.ccd_call_seq%TYPE;
      l_acct_no       vmscms.cms_appl_pan.cap_acct_no%TYPE;

v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
   BEGIN
      l_start_time := dbms_utility.get_time;
      --Fetching the active PAN for the input customer id
      vmscms.gpp_pan.get_pan_details(p_customer_id_in,
                                     l_hash_pan,
                                     l_encr_pan);
      l_plain_pan := vmscms.fn_dmaps_main(l_encr_pan);

      g_debug.display('l_hash_pan' || l_hash_pan);
      g_debug.display('l_encr_pan' || l_encr_pan);
      g_debug.display('l_plain_pan' || l_plain_pan);

      --Check for madatory fields
      CASE
         WHEN p_customer_id_in IS NULL THEN
            l_field_name := 'CUSTOMER ID';
            l_flag       := 1;
         WHEN p_txn_id_in IS NULL THEN
            l_field_name := 'TRANSACTION ID';
            l_flag       := 1;
         WHEN p_txn_date_in IS NULL THEN
            l_field_name := 'TRANSACTION DATE';
            l_flag       := 1;
         WHEN p_delivery_channel_in IS NULL THEN
            l_field_name := 'DELIVERY CHANNEL';
            l_flag       := 1;
         WHEN p_txn_code_in IS NULL THEN
            l_field_name := 'TRANSACTION CODE';
            l_flag       := 1;
         WHEN p_response_code_in IS NULL THEN
            l_field_name := 'RESPONSE CODE';
            l_flag       := 1;
         WHEN p_comment_in IS NULL THEN
            l_field_name := 'COMMENT';
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
                                                      l_timetaken);
         RETURN;
      END IF;

      --fetching the mbe number
      SELECT cap_mbr_numb, cap_acct_no
        INTO l_mbr_numb, l_acct_no
        FROM vmscms.cms_appl_pan
       WHERE cap_pan_code = l_hash_pan;

      --getting the date
      l_date := substr(sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                   'x-incfs-date'),
                       6,
                       11);
      -- l_date := substr('Sun, 06 Nov 1994 08:49:37 GMT', 6, 11);
      l_date := to_char(to_date(l_date, 'dd-mm-yyyy'), 'yyyymmdd');
      --getting the time
      l_time := substr((sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                    'x-incfs-date')),
                       18,
                       8);

      l_time := REPLACE(l_time, ':', '');
      --l_time := '110045';
      g_debug.display('l_date' || l_date);
      g_debug.display('l_time' || l_time);

      --fetching the rrn
      SELECT to_char(to_char(SYSDATE, 'YYMMDDHH24MISS') ||  --Changes VMS-8279 ~ HH has been replaced as HH24
                     lpad(vmscms.seq_deppending_rrn.nextval, 3, '0'))
        INTO l_rrn
        FROM dual;
      g_debug.display('l_rrn' || l_rrn);

      l_tran_date := to_char(trunc(to_date(p_txn_date_in,
                                           'YYYY-MM-DD HH24:MI:SS')),
                             'YYYYMMDD');
      g_debug.display('l_tran_date' || l_tran_date);
      --- fetching the original details
	  
	  		 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      SELECT business_date orgnl_tran_date,
             business_time orgnl_tran_time,
             nvl(to_char(amount, '9999999990.99'), '0.00') orgnl_txn_amount,
             txn_code orgnl_txn_code,
             delivery_channel orgnl_delivery_chnl,
             rrn orgnl_rrn,
             to_number(vmscms.fn_dmaps_main(customer_card_no_encr)) orgnl_card_no,
             system_trace_audit_no orgnl_stan,
             nvl(tran_reverse_flag, 'N') tran_reverse_flag,
             nvl(fee_reversal_flag, 'N') fee_reversal_flag,
             reversal_code,
             nvl(dispute_flag, 'N') dispute_flag
        INTO l_business_date,
             l_business_time,
             l_orgnl_amount,
             l_txn_code,
             l_delivery_channel,
             l_orgnl_rrn,
             l_orgnl_card_no,
             l_orgnl_stan,
             l_tran_rev_flag, 
             l_fee_rev_flag,
             l_reversal_code,
             l_dispute
        FROM VMSCMS.TRANSACTIONLOG --Added for VMS-5733/FSP-991
       WHERE rrn = p_txn_id_in
         AND delivery_channel = p_delivery_channel_in
         AND txn_code = p_txn_code_in
         AND response_code = p_response_code_in
         AND business_date = l_tran_date;
		ELSE
		     SELECT business_date orgnl_tran_date,
             business_time orgnl_tran_time,
             nvl(to_char(amount, '9999999990.99'), '0.00') orgnl_txn_amount,
             txn_code orgnl_txn_code,
             delivery_channel orgnl_delivery_chnl,
             rrn orgnl_rrn,
             to_number(vmscms.fn_dmaps_main(customer_card_no_encr)) orgnl_card_no,
             system_trace_audit_no orgnl_stan,
             nvl(tran_reverse_flag, 'N') tran_reverse_flag,
             nvl(fee_reversal_flag, 'N') fee_reversal_flag,
             reversal_code,
             nvl(dispute_flag, 'N') dispute_flag
        INTO l_business_date,
             l_business_time,
             l_orgnl_amount,
             l_txn_code,
             l_delivery_channel,
             l_orgnl_rrn,
             l_orgnl_card_no,
             l_orgnl_stan,
             l_tran_rev_flag, 
             l_fee_rev_flag,
             l_reversal_code,
             l_dispute
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       WHERE rrn = p_txn_id_in
         AND delivery_channel = p_delivery_channel_in
         AND txn_code = p_txn_code_in
         AND response_code = p_response_code_in
         AND business_date = l_tran_date;

END IF;		
		 
      --fetching the dispute status

      g_debug.display('l_dispute' || l_dispute);
      CASE
         WHEN l_dispute = 'A' THEN
            p_status_out := vmscms.gpp_const.c_dispute_approved_status;
            g_err_invalid_data.raise(l_api_name,
                                     ',0034,',
                                     'DISPUTE IS ALREADY BEEN APPROVED');
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

         WHEN l_dispute = 'R' THEN
            p_status_out := vmscms.gpp_const.c_dispute_approved_status;
            g_err_invalid_data.raise(l_api_name,
                                     ',0035,',
                                     'DISPUTE IS ALREADY BEEN REJECTED');
            p_err_msg_out := g_err_invalid_data.get_current_error;
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

         WHEN l_dispute IS NULL THEN
            g_debug.display('l_dispute in null condition' || l_dispute);
            p_status_out := vmscms.gpp_const.c_dispute_approved_status;
            g_debug.display('ERROR_MESSAGE_STATUS_TEST' || p_status_out);
            g_err_invalid_data.raise(l_api_name,
                                     ',0036,',
                                     'DISPUTE IS NOT YET RAISED');
            p_err_msg_out := g_err_invalid_data.get_current_error;

            g_debug.display('ERROR_MESSAGE_TEST' || p_err_msg_out);
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

         WHEN l_dispute = 'Y' THEN
            g_debug.display('calling sp_dispute_process');
            vmscms.sp_dispute_process(1, --p_inst_code
                                      l_plain_pan, --p_pan
                                      l_orgnl_card_no, --p_orgnl_pan
                                      '0200', --p_msg_type
                                      l_mbr_numb, --p_mbr_numb
                                      l_orgnl_amount, --p_txn_amount
                                      l_rrn, --p_rrn
                                      NULL, --p_stan
                                      '03', --p_del_channel
                                      l_date, --p_txn_date
                                      l_time, --p_txn_time
                                      (CASE WHEN
                                       upper(p_isapproved_in) = 'TRUE' THEN 88 ELSE 89 END), --p_txn_code
                                      0, --p_txn_mode
                                      l_orgnl_rrn, --p_orgnl_rrn
                                      l_orgnl_stan, --p_orgnl_stan
                                      l_business_date, --p_orgnl_business_date
                                      l_business_time, --p_orgnl_business_time
                                      l_orgnl_amount, --p_orgnl_txn_amt
                                      l_txn_code, --p_orgnl_txn_code
                                      l_delivery_channel, --p_orgnl_del_channel
                                      l_tran_rev_flag,
                                      l_fee_rev_flag,
                                      l_reversal_code,
                                      l_orgnl_amount,
                                      l_dispute,
                                      --36194,
                                      (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                   'x-incfs-sessionid')), --p_call_id
                                      (CASE upper(p_refund_type_in) WHEN
                                       'CREDIT' THEN 1 WHEN 'NEWCARD' THEN 2 WHEN
                                       'REFUNDCHECK' THEN 3 END), --p_appr_resolution
                                      (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                                   'x-incfs-ip')), --p_ipaddress
                                      NULL,--1, --p_insuser FSAPI 5.5.5 passing null instead of 1
                                      p_status_out, --p_resp_code
                                      p_err_msg_out --p_resp_msg
                                      );

            g_debug.display('p_status_out' || p_status_out);
            g_debug.display('p_err_msg_out' || p_err_msg_out);

         -- CFIP 364, This will update fsapi username as base procedure is not taking care of this.
        update vmscms.cms_dispute_txns
              set CDT_FSAPI_UPDUSRNAME = (sys_context(fsfw.fsconst.c_fsapi_gpp_context, 'x-incfs-username')),
               cdt_final_remark = p_comment_in -- FSAPI 5.5.5
          where cdt_inst_code    = 	1
             and cdt_pan_code    =   vmscms.gethash(l_orgnl_card_no)
             and cdt_txn_date     =   l_business_date
             and cdt_txn_time    =   l_business_time
             and cdt_rrn            =   l_orgnl_rrn;

      END CASE;
      --updating the below fields manually
      --since the base procedure doesnot populate these fields in Transactionlog
      UPDATE VMSCMS.TRANSACTIONLOG  
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
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
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
                          'x-incfs-username')),
			 ccd_comments=p_comment_in -- FSAPI 5.5.5
       WHERE ccd_acct_no = l_acct_no
         AND ccd_inst_code = 1
         AND ccd_rrn = l_rrn
         AND ccd_call_id = (sys_context(fsfw.fsconst.c_fsapi_gpp_context,
                                        'x-incfs-sessionid'))
         AND ccd_call_seq = l_call_seq;

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
         p_status_out := vmscms.gpp_const.c_dispute_transaction_status;
         g_err_unknown.raise(l_api_name || ' FAILED',
                             vmscms.gpp_const.c_dispute_transaction_status);
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

   END update_dispute;

   PROCEDURE init IS
   BEGIN
      -- initialize all errors here
      g_err_nodata       := fsfw.fserror_t('E-NO-DATA', '$1 $2');
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
END gpp_dispute;
/
show error;