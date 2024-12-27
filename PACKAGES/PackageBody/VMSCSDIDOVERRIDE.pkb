
CREATE OR REPLACE PACKAGE BODY VMSCMS.VMSCSDIDOVERRIDE
IS
   PROCEDURE OVERRIDE_IDCHECK_FAIL (p_instcode_in       IN     NUMBER,
                                    p_msg_type_in       IN     VARCHAR2,
                                    p_rowid_in          IN     VARCHAR2,
                                    p_rrn_in            IN     VARCHAR2,
                                    p_stan_in           IN     VARCHAR2,
                                    p_txn_code_in       IN     VARCHAR2,
                                    p_tran_mode_in      IN     VARCHAR2,
                                    p_delv_chnl_in      IN     VARCHAR2,
                                    p_curr_code_in      IN     VARCHAR2,
                                    p_kyc_flag_in       IN     VARCHAR2,
                                    p_starter_card_in   IN     VARCHAR2,
                                    p_tran_date_in      IN     VARCHAR2,
                                    p_tran_time_in      IN     VARCHAR2,
                                    p_lupduser_in       IN     NUMBER,
                                    p_comment_in        IN     VARCHAR2,
                                    p_reason_in         IN     VARCHAR2,
                                    p_ipaddress_in      IN     VARCHAR2,
                                    p_gpr_card_out      OUT    VARCHAR2,
                                    p_acct_no_out       OUT    VARCHAR2,
                                    p_cust_id_out       OUT    VARCHAR2,
                                    p_resp_code_out     OUT    VARCHAR2,
                                    p_errmsg_out        OUT    VARCHAR2,
                                    p_pin_flag_out      OUT    VARCHAR2,
                                    p_gpr_pan_out       OUT    VARCHAR2
)
   IS
   
   
      /**********************************************************************************************

        * Created by                  : MageshKumar S.
        * Created Date                : 23-June-15
        * Created For                 : MVCAN-77
        * Created reason              : Canada account limit check
        * Reviewer                    : Spankaj
        * Build Number                : VMSGPRHOSTCSD3.1_B0001
    
        * Created by                  : Siva Kumar M
        * Created Date                : 22-Mar-16
        * Created For                 : MVHOST-1323
        * Created reason              : ssn encription logic
        * Reviewer                    : Spankaj/Saravana
        * Build Number                : VMSGPRHOSTCSD_4.0_B0006
		
		* Modified by                 : T.Narayanaswamy
        * Modified Date               : 29-Sep-16
        * Modified For                : To restrict the Duplicate Starter Card Generation
        * Reviewer                    : Spankaj/Saravana
        * Build Number                : VMSGPRHOSTCSD_4.2.5
        * Modified by                 : Ubaidur Rahman H
        * Modified Date               : 17-Jun-2019
        * Modified For                : VMS-959 (Enhance CSD to support cardholder data search for Rewards products )
        * Reviewer                    : Saravanakumar A
        * Build Number                : VMSGPRHOST_R17

    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-4-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991


      **************************************************************************************************/

      l_errmsg                    transactionlog.error_msg%TYPE;
      l_appl_code                 cms_caf_info_entry.cci_appl_code%TYPE;
      l_pan                       cms_appl_pan.cap_pan_code%TYPE;
      l_applproc_msg              transactionlog.error_msg%TYPE;
      l_hash_pan                  cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                  cms_appl_pan.cap_pan_code_encr%TYPE;
      l_cap_cust_code             cms_appl_pan.cap_cust_code%TYPE;
      l_comment                   cms_calllog_details.ccd_comments%TYPE;
      l_spnd_acctno               cms_appl_pan.cap_acct_no%TYPE;
      l_resp_code                 transactionlog.response_code%TYPE;
      l_acct_balance              cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal                cms_acct_mast.cam_ledger_bal%TYPE;
      l_dr_cr_flag                cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_tran_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
      l_cap_prod_code             cms_appl_pan.cap_prod_code%TYPE;
      l_cap_card_type             cms_appl_pan.cap_card_type%TYPE;
      l_cap_proxynumber           cms_appl_pan.cap_proxy_number%TYPE;
      l_auth_id                   transactionlog.auth_id%TYPE;
      l_call_id                   cms_calllog_mast.ccm_call_id%TYPE;
      l_hash_starter_pan          cms_appl_pan.cap_pan_code%TYPE;
      l_encr_starter_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
      l_cci_prod_code             cms_caf_info_entry.cci_prod_code%TYPE;
      l_ssn_crddtls               transactionlog.ssn_fail_dtls%TYPE;
      l_crdstat_chnge             VARCHAR2 (2) := 'N';
      l_startogprissu_flag        cms_prod_cattype.cpc_startergpr_issue%TYPE;
      l_cap_pin_flag              VARCHAR2 (1) := 'N';
      l_cci_appl_code             cms_caf_info_entry.cci_appl_code%TYPE;
      l_cap_appl_code             cms_appl_pan.cap_appl_code%TYPE;
      l_orig_rowid                cms_caf_info_entry.cci_row_id%TYPE;
      l_cci_fiid                  cms_caf_info_entry.cci_fiid%TYPE;
      l_cci_seg12_homephone_no    cms_caf_info_entry.cci_seg12_homephone_no%TYPE;
      l_cci_seg12_name_line1      cms_caf_info_entry.cci_seg12_name_line1%TYPE;
      l_cci_seg12_name_line2      cms_caf_info_entry.cci_seg12_name_line2%TYPE;
      l_cci_seg12_addr_line1      cms_caf_info_entry.cci_seg12_addr_line1%TYPE;
      l_cci_seg12_addr_line2      cms_caf_info_entry.cci_seg12_addr_line2%TYPE;
      l_cci_seg12_city            cms_caf_info_entry.cci_seg12_city%TYPE;
      l_cci_seg12_state           cms_caf_info_entry.cci_seg12_state%TYPE;
      l_cci_seg12_postal_code     cms_caf_info_entry.cci_seg12_postal_code%TYPE;
      l_cci_seg12_country_code    cms_caf_info_entry.cci_seg12_country_code%TYPE;
      l_cci_seg12_mobileno        cms_caf_info_entry.cci_seg12_mobileno%TYPE;
      l_cci_seg12_emailid         cms_caf_info_entry.cci_seg12_emailid%TYPE;
      l_cci_requester_name        cms_caf_info_entry.cci_requester_name%TYPE;
      l_cci_ssn                   cms_caf_info_entry.cci_ssn%TYPE;
      l_cci_birth_date            cms_caf_info_entry.cci_birth_date%TYPE;
      l_cci_document_verify       cms_caf_info_entry.cci_document_verify%TYPE;
      l_cci_entry_rec_type        cms_caf_info_entry.cci_entry_rec_type%TYPE;
      l_cci_instrument_realised   cms_caf_info_entry.cci_instrument_realised%TYPE;
      l_cci_cust_catg             cms_caf_info_entry.cci_cust_catg%TYPE;
      l_cci_comm_type             cms_caf_info_entry.cci_comm_type%TYPE;
      l_cci_seg13_addr_param9     cms_caf_info_entry.cci_seg13_addr_param9%TYPE;
      l_cci_title                 cms_caf_info_entry.cci_title%TYPE;
      l_cci_id_issuer             cms_caf_info_entry.cci_id_issuer%TYPE;
      l_cci_id_number             cms_caf_info_entry.cci_id_number%TYPE;
      l_cci_seg13_addr_line1      cms_caf_info_entry.cci_seg13_addr_line1%TYPE;
      l_cci_seg13_addr_line2      cms_caf_info_entry.cci_seg13_addr_line2%TYPE;
      l_cci_seg13_city            cms_caf_info_entry.cci_seg13_city%TYPE;
      l_cci_seg13_state           cms_caf_info_entry.cci_seg13_state%TYPE;
      l_cci_seg13_postal_code     cms_caf_info_entry.cci_seg13_postal_code%TYPE;
      l_cci_seg13_country_code    cms_caf_info_entry.cci_seg13_country_code%TYPE;
      l_cci_id_issuance_date      cms_caf_info_entry.cci_id_issuance_date%TYPE;
      l_cci_id_expiry_date        cms_caf_info_entry.cci_id_expiry_date%TYPE;
      l_cci_mothers_maiden_name   cms_caf_info_entry.cci_mothers_maiden_name%TYPE;
      l_cci_card_type             cms_caf_info_entry.cci_card_type%TYPE;
      l_cci_seg12_state_code      cms_caf_info_entry.cci_seg12_state_code%TYPE;
      l_cci_seg13_state_code      cms_caf_info_entry.cci_seg13_state_code%TYPE;
      l_cci_kyc_flag              cms_caf_info_entry.cci_kyc_flag%TYPE;
      l_gpr_optin                 cms_transaction_log_dtl.ctd_gpr_optin%TYPE := 'Y';
      l_cap_card_stat             cms_appl_pan.cap_card_type%TYPE;
      l_pan_number                VARCHAR2 (20);
      --Sn:Added for VMS-959
      l_cci_seg12_name_line1_encr    cms_caf_info_entry.cci_seg12_name_line1_encr%type;
      l_cci_seg12_name_line2_encr    cms_caf_info_entry.cci_seg12_name_line2_encr%type;
      l_cci_seg12_addr_line1_encr    cms_caf_info_entry.cci_seg12_addr_line1_encr%type;
      l_cci_seg12_addr_line2_encr    cms_caf_info_entry.cci_seg12_addr_line2_encr%type;
      l_cci_seg12_city_encr          cms_caf_info_entry.cci_seg12_city_encr%type;
      l_cci_seg12_postal_code_encr   cms_caf_info_entry.cci_seg12_postal_code_encr%type;
      l_cci_seg12_emailid_encr       cms_caf_info_entry.cci_seg12_emailid_encr%type;
      --En:Added for VMS-959
      exp_reject_record           EXCEPTION;
   BEGIN
      l_errmsg := 'OK';
      l_orig_rowid := p_rowid_in;

      BEGIN
         BEGIN
            SELECT ctm_credit_debit_flag, ctm_tran_desc
              INTO l_dr_cr_flag, l_tran_desc
              FROM cms_transaction_mast
             WHERE     ctm_tran_code = p_txn_code_in
                   AND ctm_delivery_channel = p_delv_chnl_in
                   AND ctm_inst_code = p_instcode_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_code := '49';
               l_errmsg :=
                  'Transaction detail is not found in master for txn code '
                  || p_txn_code_in
                  || 'delivery channel '
                  || p_delv_chnl_in;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Problem while selecting debit/credit flag '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;


         BEGIN
            SELECT cci_fiid,
                   cci_seg12_homephone_no,
                   cci_seg12_name_line1,
                   cci_seg12_name_line2,
                   cci_seg12_addr_line1,
                   cci_seg12_addr_line2,
                   cci_seg12_city,
                   cci_seg12_state,
                   cci_seg12_postal_code,
                   cci_seg12_country_code,
                   cci_seg12_mobileno,
                   cci_seg12_emailid,
                   cci_prod_code,
                   cci_requester_name,
                   nvl(fn_dmaps_main(cci_ssn_encr),cci_ssn),
                   cci_birth_date,
                   cci_document_verify,
                   cci_entry_rec_type,
                   cci_instrument_realised,
                   cci_cust_catg,
                   cci_comm_type,
                   cci_seg13_addr_param9,
                   cci_title,
                   cci_id_issuer,
                   nvl(fn_dmaps_main(cci_id_number_encr),cci_id_number),
                   cci_seg13_addr_line1,
                   cci_seg13_addr_line2,
                   cci_seg13_city,
                   cci_seg13_state,
                   cci_seg13_postal_code,
                   cci_seg13_country_code,
                   cci_id_issuance_date,
                   cci_id_expiry_date,
                   cci_mothers_maiden_name,
                   cci_card_type,
                   cci_seg12_state_code,
                   CCI_SEG13_STATE_CODE,
                   CCI_KYC_FLAG,
                   --Sn:Added for VMS-959
                   cci_seg12_name_line1_encr,
                   cci_seg12_name_line2_encr,
                   cci_seg12_addr_line1_encr,
                   cci_seg12_addr_line2_encr,
                   cci_seg12_city_encr, 
                   cci_seg12_postal_code_encr,
                   cci_seg12_emailid_encr
                   --En:Added for VMS-959
              INTO l_cci_fiid,
                   l_cci_seg12_homephone_no,
                   l_cci_seg12_name_line1,
                   l_cci_seg12_name_line2,
                   l_cci_seg12_addr_line1,
                   l_cci_seg12_addr_line2,
                   l_cci_seg12_city,
                   l_cci_seg12_state,
                   l_cci_seg12_postal_code,
                   l_cci_seg12_country_code,
                   l_cci_seg12_mobileno,
                   l_cci_seg12_emailid,
                   l_cci_prod_code,
                   l_cci_requester_name,
                   l_cci_ssn,
                   l_cci_birth_date,
                   l_cci_document_verify,
                   l_cci_entry_rec_type,
                   l_cci_instrument_realised,
                   l_cci_cust_catg,
                   l_cci_comm_type,
                   l_cci_seg13_addr_param9,
                   l_cci_title,
                   l_cci_id_issuer,
                   l_cci_id_number,
                   l_cci_seg13_addr_line1,
                   l_cci_seg13_addr_line2,
                   l_cci_seg13_city,
                   l_cci_seg13_state,
                   l_cci_seg13_postal_code,
                   l_cci_seg13_country_code,
                   l_cci_id_issuance_date,
                   l_cci_id_expiry_date,
                   l_cci_mothers_maiden_name,
                   l_cci_card_type,
                   l_cci_seg12_state_code,
                   l_cci_seg13_state_code,
                   l_cci_kyc_flag,
                   --Sn:Added for VMS-959
                   l_cci_seg12_name_line1_encr,    
                   l_cci_seg12_name_line2_encr,   
                   l_cci_seg12_addr_line1_encr,   
                   l_cci_seg12_addr_line2_encr,   
                   l_cci_seg12_city_encr,         
                   l_cci_seg12_postal_code_encr,  
                   l_cci_seg12_emailid_encr
                   --En:Added for VMS-959
              FROM cms_caf_info_entry
             WHERE CCI_ROW_ID = l_orig_rowid
                   AND CCI_INST_CODE = p_instcode_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_code := '49';
               l_errmsg := 'No data found for rowid - ' || l_orig_rowid;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while selecting application detail - for rowid - '
                  || l_orig_rowid
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
         END;


         BEGIN
            l_hash_starter_pan := gethash (p_starter_card_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while converting into hash pan '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;

         BEGIN
            l_encr_starter_pan := fn_emaps_main (p_starter_card_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while converting into encrypt pan '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT cap_pan_code,
                   cap_cust_code,
                   cap_pan_code_encr,
                   cap_acct_no,
                   cap_prod_code,
                   cap_card_type,
                   CAP_PROXY_NUMBER,
                   DECODE (CAP_PIN_OFF, NULL, 'N', 'Y'),
                   CAP_APPL_CODE,
                   cap_card_stat
              INTO l_hash_pan,
                   l_cap_cust_code,
                   l_encr_pan,
                   l_spnd_acctno,
                   l_cap_prod_code,
                   l_cap_card_type,
                   l_cap_proxynumber,
                   l_cap_pin_flag,
                   l_cap_appl_code,
                   l_cap_card_stat
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode_in
                   AND cap_pan_code = gethash (p_starter_card_in);

            p_acct_no_out := l_spnd_acctno;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_code := '16';
               l_errmsg := 'Invalid starter pan for rowid - ' || l_orig_rowid;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while selecting Starter card details - for applcode '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;



         BEGIN
            l_cci_appl_code := l_cap_appl_code;

            SELECT CCI_ROW_ID
              INTO l_orig_rowid
              FROM cms_caf_info_entry
             WHERE CCI_INST_CODE = p_instcode_in
                   AND CCI_APPL_CODE = l_cci_appl_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_code := '49';
               l_errmsg := 'No data found for application detail';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while selecting application detail - '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
         END;

         BEGIN
            UPDATE cms_caf_info_entry
            SET cci_fiid                 = l_cci_fiid,
              cci_seg12_homephone_no     = l_cci_seg12_homephone_no,
              cci_seg12_name_line1       = l_cci_seg12_name_line1,
              cci_seg12_name_line2       = l_cci_seg12_name_line2,
              cci_seg12_addr_line1       = l_cci_seg12_addr_line1,
              cci_seg12_addr_line2       = l_cci_seg12_addr_line2,
              cci_seg12_city             = l_cci_seg12_city,
              cci_seg12_state            = l_cci_seg12_state,
              cci_seg12_postal_code      = l_cci_seg12_postal_code,
              cci_seg12_country_code     = l_cci_seg12_country_code,
              cci_seg12_mobileno         = l_cci_seg12_mobileno,
              cci_seg12_emailid          = l_cci_seg12_emailid,
              cci_prod_code              = l_cci_prod_code,
              cci_requester_name         = l_cci_requester_name,
              cci_ssn =fn_maskacct_ssn(p_instcode_in,
                      DECODE (l_cci_document_verify,
                              'SSN', l_cci_ssn,
                              'SIN', l_cci_ssn,
                              NULL),0),
              cci_ssn_encr =fn_emaps_main(DECODE (l_cci_document_verify,
                              'SSN', l_cci_ssn,
                              'SIN', l_cci_ssn,
                              NULL)),
              cci_birth_date             = l_cci_birth_date,
              cci_document_verify        = l_cci_document_verify,
              cci_lupd_date              = SYSDATE,
              cci_entry_rec_type         = l_cci_entry_rec_type,
              cci_instrument_realised    = l_cci_instrument_realised,
              cci_cust_catg              = l_cci_cust_catg,
              cci_comm_type              = l_cci_comm_type,
              cci_seg13_addr_param9      = l_cci_seg13_addr_param9,
              cci_title                  = l_cci_title,
              cci_id_issuer =
                      DECODE (l_cci_document_verify,
                              'SSN', NULL,
                              'SIN', NULL,
                              l_cci_id_issuer),
              cci_id_number =fn_maskacct_ssn(p_instcode_in,
                      DECODE (l_cci_document_verify,
                              'SSN', NULL,
                              'SIN', NULL,
                              l_cci_id_number),0),
              cci_id_number_encr = fn_emaps_main( DECODE (l_cci_document_verify,
                              'SSN', NULL,
                              'SIN', NULL,
                              l_cci_id_number)),
              cci_seg13_addr_line1       = l_cci_seg13_addr_line1,
              cci_seg13_addr_line2       = l_cci_seg13_addr_line2,
              cci_seg13_city             = l_cci_seg13_city,
              cci_seg13_state            = l_cci_seg13_state,
              cci_seg13_postal_code      = l_cci_seg13_postal_code,
              cci_seg13_country_code     = l_cci_seg13_country_code,
              cci_id_issuance_date =
                      DECODE (l_cci_document_verify,
                              'SSN', NULL,
                              'SIN', NULL,
                              l_cci_id_issuance_date),
              cci_id_expiry_date =
                      DECODE (l_cci_document_verify,
                              'SSN', NULL,
                              'SIN', NULL,
                              l_cci_id_expiry_date),
              cci_mothers_maiden_name    = l_cci_mothers_maiden_name,
              cci_card_type              = l_cci_card_type,
              cci_seg12_state_code       = l_cci_seg12_state_code,
              cci_seg13_state_code       = l_cci_seg13_state_code,
              cci_pan_code               = l_hash_starter_pan,
              cci_pan_code_encr          = l_encr_starter_pan,
              --Sn:Added for VMS-959
              cci_seg12_name_line1_encr  = l_cci_seg12_name_line1_encr,
              cci_seg12_name_line2_encr  = l_cci_seg12_name_line2_encr,
              cci_seg12_addr_line1_encr  = l_cci_seg12_addr_line1_encr,
              cci_seg12_addr_line2_encr  = l_cci_seg12_addr_line2_encr,
              cci_seg12_city_encr        = l_cci_seg12_city_encr ,
              cci_seg12_postal_code_encr = l_cci_seg12_postal_code_encr,
              cci_seg12_emailid_encr     = l_cci_seg12_emailid_encr
              --En:Added for VMS-959
            WHERE cci_row_id             = l_orig_rowid
            AND cci_inst_code            = p_instcode_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                     'Error while updating application details for rowid - '
                  || l_orig_rowid
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
         END;



         BEGIN
            sp_check_starter_card (p_instcode_in,
                                   p_starter_card_in,
                                   p_txn_code_in,
                                   p_delv_chnl_in,
                                   l_resp_code,
                                   l_errmsg);

            IF l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while calling check starter card prcoess '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


         BEGIN
            UPDATE cms_caf_info_entry
               SET CCI_SSN_FLAG = 'O',
                   cci_kyc_flag = 'O',
                   CCI_OVERRIDE_FLAG = 1
             WHERE cci_inst_code = p_instcode_in
                   AND cci_row_id = l_orig_rowid;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while updating KYC Registration-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;



         BEGIN
            SELECT NVL (CTD_GPR_OPTIN, 'Y')
              INTO l_gpr_optin
              FROM (  SELECT CTD_GPR_OPTIN
                        FROM VMSCMS.CMS_TRANSACTION_LOG_DTL_VW  --Added for VMS-5733/FSP-991
                       WHERE CTD_CUSTOMER_CARD_NO = l_hash_starter_pan
                             AND CTD_INST_CODE = p_instcode_in
                    ORDER BY CTD_INS_DATE DESC)
             WHERE ROWNUM = 1;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while selecting l_gpr_optin '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


         BEGIN
            SP_ENTRY_NEWCAF_STARTER_TO_GPR (p_instcode_in,
                                            l_orig_rowid,
                                            p_starter_card_in,
                                            p_lupduser_in,
                                            l_errmsg);

            IF l_errmsg <> 'OK'
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error from Entry_Newcaf_starter_to_gpr: ' || l_errmsg;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while calling Entry_Newcaf_starter_to_gpr -'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT cci_appl_code
              INTO l_appl_code
              FROM cms_caf_info_entry
             WHERE cci_inst_code = p_instcode_in
             AND cci_row_id = l_orig_rowid;

            IF l_appl_code IS NULL
            THEN
               l_resp_code := '49';
               l_errmsg :=
                  'During starter_to_gpr Application code not found for rowid ';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
	    WHEN exp_reject_record THEN
	       RAISE;
            WHEN NO_DATA_FOUND
            THEN
               l_resp_code := '49';
               l_errmsg :=
                  'During starter_to_gpr Application code not found for rowid - '
                  || l_orig_rowid;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'During starter_to_gpr Error while selecting application detail - for rowid - '
                  || l_orig_rowid
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


         BEGIN
            SELECT NVL (CPC_STARTERGPR_ISSUE, 'A')
              INTO l_startogprissu_flag
              FROM CMS_PROD_CATTYPE, CMS_APPL_PAN
             WHERE     CAP_INST_CODE = p_instcode_in
                   AND CAP_appl_CODE = l_appl_code
                   AND CPC_PROD_CODE = CAP_PROD_CODE
                   AND CPC_CARD_TYPE = CAP_CARD_TYPE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_code := '16';
               l_errmsg := 'Product category not found';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while selecting product category details -'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


         IF UPPER (l_gpr_optin) = 'Y'
         AND l_startogprissu_flag = 'A' -- Changed for To restrict the Duplicate Starter Card Generation
         THEN
               BEGIN
                  UPDATE CMS_APPL_MAST
                     SET CAM_APPL_STAT = 'A', CAM_LUPD_USER = p_lupduser_in
                   WHERE     CAM_INST_CODE = p_instcode_in
                         AND CAM_APPL_CODE = l_appl_code
                         AND CAM_APPL_STAT = 'O';

                  IF SQL%ROWCOUNT = 0
                  THEN
                     l_resp_code := '21';
                     l_errmsg :=
                        'Record not updated in appl mast for appl code '
                        || l_appl_code;
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_code := '21';
                     l_errmsg :=
                        'Error while updating appl mast  '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;


               BEGIN
                  sp_gen_pan_starter_to_gpr (p_instcode_in,
                                             l_appl_code,
                                             p_lupduser_in,
                                             l_pan,
                                             l_applproc_msg,
                                             l_errmsg);

                  l_errmsg := l_applproc_msg;

                  IF l_errmsg <> 'OK'
                  THEN
                     l_resp_code := '21';
                     l_errmsg := 'Error from starter_to_gpr: ' || l_errmsg;
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_code := '21';
                     l_errmsg :=
                        'Error while calling starter_to_gpr-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
         END IF;


         IF UPPER (l_gpr_optin) = 'Y'
         THEN
            BEGIN
               SELECT cap_mask_pan,
                      cap_cust_code,
                      fn_dmaps_main (cap_pan_code_encr),
                      cap_prod_code
                 INTO p_gpr_card_out,
                      l_cap_cust_code,
                      l_pan_number,
                      l_cap_prod_code
                 FROM cms_appl_pan
                WHERE     cap_inst_code = p_instcode_in
                      AND cap_acct_no = l_spnd_acctno
                      AND cap_startercard_flag = 'N'
                      AND cap_appl_code = l_appl_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  l_resp_code := '21';
                  l_errmsg :=
                        'Error while selecting GPR card - for applcode '
                     || l_appl_code
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;                                            --Added for FWR 70



         IF l_pan_number IS NOT NULL
         THEN
	  p_gpr_pan_out:=l_pan_number;
            BEGIN
               SP_LOGAVQSTATUS (p_instcode_in,
                                p_delv_chnl_in,
                                l_pan_number,
                                l_cap_prod_code,
                                l_cap_cust_code,
                                l_resp_code,
                                l_errmsg,
                                l_cap_card_type);

               IF l_errmsg <> 'OK'
               THEN
                  l_errmsg :=
                     'Exception while calling LOGAVQSTATUS-- ' || l_errmsg;
                  l_resp_code := '21';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Exception in LOGAVQSTATUS-- '
                     || SUBSTR (SQLERRM, 1, 200);
                  l_resp_code := '21';
                  RAISE exp_reject_record;
            END;
         END IF;



         p_pin_flag_out := l_cap_pin_flag;

         IF l_cap_pin_flag = 'Y'
         THEN
            BEGIN
               UPDATE cms_appl_pan
                  SET cap_card_stat = '1',cap_active_date=sysdate
                WHERE cap_pan_code = l_hash_starter_pan;

               l_crdstat_chnge := 'Y';
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'error while activating stater card '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE exp_reject_record;
            END;
         END IF;

         BEGIN
            UPDATE CMS_CARDISSUANCE_STATUS
               SET CCS_CARD_STATUS = '15'
             WHERE     CCS_INST_CODE = p_instcode_in
                   AND CCS_PAN_CODE = l_hash_starter_pan
                   AND CCS_CARD_STATUS = '31';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                  'While updating application status for starter card '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;


         BEGIN
            UPDATE cms_caf_info_entry
               SET CCI_OVERRIDE_FLAG =
                      CASE WHEN CCI_ROW_ID = p_rowid_in THEN 2 ELSE 1 END,
                   CCI_ORIG_ROWID = l_orig_rowid
             WHERE CCI_STARTER_CARD_NO = l_hash_starter_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while updating KYC failed pending records for rowId -'
                  || l_orig_rowid
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
         END;



         BEGIN
            SELECT ccm_cust_id
              INTO p_cust_id_out
              FROM cms_cust_mast
             WHERE ccm_inst_code = p_instcode_in
                   AND ccm_cust_code = l_cap_cust_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_code := '49';
               l_errmsg :=
                     'Invalid cust code - '
                  || l_cap_cust_code
                  || ' for rowid - '
                  || l_orig_rowid;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                     'Error while selecting cust id for cust code '
                  || l_cap_cust_code
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;



         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO l_acct_balance, l_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = p_instcode_in
                   AND cam_acct_no = l_spnd_acctno;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_code := '7';
               l_errmsg := 'Spending Account not found ' || l_spnd_acctno;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while selecting acct details-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            UPDATE cms_cust_mast
               SET ccm_kyc_flag = p_kyc_flag_in,
                   ccm_kyc_source = p_delv_chnl_in
             WHERE ccm_cust_code = l_cap_cust_code
                   AND ccm_inst_code = p_instcode_in;

            IF SQL%ROWCOUNT <> 1
            THEN
               l_resp_code := '21';
               l_errmsg := 'Error while updating kyc';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  'Error while updating KYC Flag during SSN override-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;



         IF p_comment_in IS NULL
         THEN
            IF p_txn_code_in = '04' AND p_delv_chnl_in = '03'
            THEN
               l_comment := 'SSN CHECK OVERRIDE FOR STARTER TO GPR CARD';
            END IF;
         ELSE
            l_comment := p_comment_in;
         END IF;



         BEGIN
            SELECT seq_call_id.NEXTVAL INTO l_call_id FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               p_errmsg_out := ' Error while generating call id  ' || SQLERRM;
               RAISE exp_reject_record;
         END;

         BEGIN
            INSERT INTO cms_calllog_mast (ccm_inst_code,
                                          ccm_call_id,
                                          ccm_call_catg,
                                          ccm_pan_code,
                                          ccm_callstart_date,
                                          ccm_callend_date,
                                          ccm_ins_user,
                                          ccm_ins_date,
                                          ccm_lupd_user,
                                          ccm_lupd_date,
                                          ccm_acct_no,
                                          ccm_call_status)
                 VALUES (p_instcode_in,
                         l_call_id,
                         1,
                         l_hash_pan,
                         SYSDATE,
                         NULL,
                         p_lupduser_in,
                         SYSDATE,
                         p_lupduser_in,
                         SYSDATE,
                         l_spnd_acctno,
                         'C');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               p_errmsg_out :=
                  ' Error while inserting into cms_calllog_mast ' || SQLERRM;
               RAISE exp_reject_record;
         END;


         BEGIN
            INSERT INTO cms_calllog_details (ccd_inst_code,
                                             ccd_call_id,
                                             ccd_pan_code,
                                             ccd_call_seq,
                                             ccd_rrn,
                                             ccd_devl_chnl,
                                             ccd_txn_code,
                                             ccd_tran_date,
                                             ccd_tran_time,
                                             ccd_tbl_names,
                                             ccd_colm_name,
                                             ccd_old_value,
                                             ccd_new_value,
                                             ccd_comments,
                                             ccd_ins_user,
                                             ccd_ins_date,
                                             ccd_lupd_user,
                                             ccd_lupd_date,
                                             ccd_acct_no)
                 VALUES (p_instcode_in,
                         l_call_id,
                         l_hash_pan,
                         1,
                         p_rrn_in,
                         p_delv_chnl_in,
                         p_txn_code_in,
                         p_tran_date_in,
                         p_tran_time_in,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         l_comment,
                         p_lupduser_in,
                         SYSDATE,
                         p_lupduser_in,
                         SYSDATE,
                         l_spnd_acctno);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_code := '21';
               l_errmsg :=
                  ' Error while inserting into cms_calllog_details '
                  || SQLERRM;
               RAISE exp_reject_record;
         END;


         l_resp_code := '1';

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE     cms_inst_code = p_instcode_in
                   AND cms_delivery_channel = p_delv_chnl_in
                   AND cms_response_id = l_resp_code;

            p_errmsg_out := l_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'Problem while selecting data from response master1 '
                  || l_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               l_resp_code := '21';
               RAISE exp_reject_record;
         END;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK;
            p_errmsg_out := l_errmsg;

            BEGIN
               SELECT cam_acct_bal, cam_ledger_bal
                 INTO l_acct_balance, l_ledger_bal
                 FROM cms_acct_mast
                WHERE cam_inst_code = p_instcode_in
                      AND cam_acct_no = l_spnd_acctno;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_acct_balance := 0;
                  l_ledger_bal := 0;
            END;

            BEGIN
               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_instcode_in
                      AND cms_delivery_channel = p_delv_chnl_in
                      AND cms_response_id = l_resp_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                        'Problem while selecting data from response master2 '
                     || l_resp_code
                     || SUBSTR (SQLERRM, 1, 100);
                  p_resp_code_out := '89';
            END;

            p_errmsg_out := RTRIM (l_errmsg || '|' || l_ssn_crddtls, '|');
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_errmsg_out :=
               'Error while Processing ' || SUBSTR (SQLERRM, 1, 200);
            l_resp_code := '21';

            BEGIN
               SELECT cam_acct_bal, cam_ledger_bal
                 INTO l_acct_balance, l_ledger_bal
                 FROM cms_acct_mast
                WHERE cam_inst_code = p_instcode_in
                      AND cam_acct_no = l_spnd_acctno;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_acct_balance := 0;
                  l_ledger_bal := 0;
            END;

            BEGIN
               SELECT cms_iso_respcde
                 INTO p_resp_code_out
                 FROM cms_response_mast
                WHERE     cms_inst_code = p_instcode_in
                      AND cms_delivery_channel = p_delv_chnl_in
                      AND cms_response_id = l_resp_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg_out :=
                        'Problem while selecting data from response master3 '
                     || l_resp_code
                     || SUBSTR (SQLERRM, 1, 100);
                  p_resp_code_out := '89';
            END;
      END;

      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0') INTO l_auth_id FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg_out :=
               'Error while generating authid ' || SUBSTR (SQLERRM, 1, 100);
            p_resp_code_out := '89';
            RETURN;
      END;


      IF l_errmsg = 'OK' AND l_crdstat_chnge = 'Y'
      THEN
         BEGIN
            sp_log_cardstat_chnge (p_instcode_in,
                                   l_hash_starter_pan,
                                   l_encr_starter_pan,
                                   l_auth_id,
                                   '01',
                                   p_rrn_in,
                                   p_tran_date_in,
                                   p_tran_time_in,
                                   l_resp_code,
                                   l_errmsg);

            IF l_resp_code <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               p_resp_code_out := l_resp_code;
               p_errmsg_out := l_errmsg;
               RETURN;
            WHEN OTHERS
            THEN
               p_resp_code_out := '89';
               p_errmsg_out :=
                  'Error while logging system initiated card status change '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      END IF;



      BEGIN
         INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                              ctd_txn_code,
                                              ctd_txn_type,
                                              ctd_msg_type,
                                              ctd_txn_mode,
                                              ctd_business_date,
                                              ctd_business_time,
                                              ctd_customer_card_no,
                                              ctd_txn_amount,
                                              ctd_fee_amount,
                                              ctd_txn_curr,
                                              ctd_actual_amount,
                                              ctd_bill_amount,
                                              ctd_bill_curr,
                                              ctd_process_flag,
                                              ctd_process_msg,
                                              ctd_rrn,
                                              ctd_system_trace_audit_no,
                                              ctd_inst_code,
                                              CTD_CUSTOMER_CARD_NO_ENCR,
                                              CTD_CUST_ACCT_NUMBER,
                                              ctd_ins_date,
                                              ctd_ins_user,
                                              ctd_gpr_optin --Added for FWR 70
                                                           )
              VALUES (p_delv_chnl_in,
                      p_txn_code_in,
                      l_dr_cr_flag,
                      p_msg_type_in,
                      p_tran_mode_in,
                      p_tran_date_in,
                      p_tran_time_in,
                      DECODE (p_txn_code_in, '04', l_hash_starter_pan),
                      '0.00',
                      '0.00',
                      p_curr_code_in,
                      '0.00',
                      '0.00',
                      p_curr_code_in,
                      DECODE (p_resp_code_out, '00', 'Y', 'E'),
                      l_errmsg,
                      p_rrn_in,
                      p_stan_in,
                      p_instcode_in,
                      DECODE (p_txn_code_in, '04', l_encr_starter_pan),
                      l_spnd_acctno,
                      SYSDATE,
                      p_lupduser_in,
                      l_gpr_optin                           --Added for FWR 70
                                 );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            p_errmsg_out :=
               'Error while inserting in log detail 1 '
               || SUBSTR (SQLERRM, 1, 100);
            RETURN;
      END;

      BEGIN
         INSERT INTO TRANSACTIONLOG (msgtype,
                                     rrn,
                                     delivery_channel,
                                     date_time,
                                     txn_code,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     response_code,
                                     business_date,
                                     business_time,
                                     customer_card_no,
                                     bank_code,
                                     total_amount,
                                     currencycode,
                                     productid,
                                     categoryid,
                                     tips,
                                     auth_id,
                                     trans_desc,
                                     tranfee_amt,
                                     amount,
                                     system_trace_audit_no,
                                     instcode,
                                     feecode,
                                     tran_reverse_flag,
                                     customer_card_no_encr,
                                     proxy_number,
                                     reversal_code,
                                     customer_acct_no,
                                     acct_balance,
                                     ledger_balance,
                                     error_msg,
                                     add_ins_date,
                                     add_ins_user,
                                     add_lupd_date,
                                     add_lupd_user,
                                     response_id,
                                     remark,
                                     reason,
                                     processes_flag,
                                     ipaddress,
                                     cr_dr_flag,
                                     ssn_fail_dtls,
                                     customer_starter_card_no,
                                     gprcardapplicationno)
              VALUES (
                        p_msg_type_in,
                        p_rrn_in,
                        p_delv_chnl_in,
                        TO_DATE (p_tran_date_in || ' ' || p_tran_time_in,
                                 'yyyymmdd hh24miss'),
                        p_txn_code_in,
                        1,
                        p_tran_mode_in,
                        DECODE (p_resp_code_out, '00', 'C', 'F'),
                        p_resp_code_out,
                        p_tran_date_in,
                        p_tran_time_in,
                        DECODE (p_txn_code_in, '04', l_hash_starter_pan),
                        p_instcode_in,
                        '0.00',
                        p_curr_code_in,
                        l_cap_prod_code,
                        l_cap_card_type,
                        0,
                        l_auth_id,
                        SUBSTR (l_tran_desc || ' - ' || p_reason_in, 1, 40),
                        '0.00',
                        '0.00',
                        p_stan_in,
                        p_instcode_in,
                        NULL,
                        'N',
                        DECODE (p_txn_code_in, '04', l_encr_starter_pan),
                        l_cap_proxynumber,
                        '00',
                        l_spnd_acctno,
                        l_acct_balance,
                        l_ledger_bal,
                        l_errmsg,
                        SYSDATE,
                        p_lupduser_in,
                        SYSDATE,
                        p_lupduser_in,
                        l_resp_code,
                        l_comment,
                        p_reason_in,
                        DECODE (p_resp_code_out, '00', 'Y', 'E'),
                        p_ipaddress_in,
                        l_dr_cr_flag,
                        l_ssn_crddtls,
                        l_encr_starter_pan,
                        l_appl_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            p_errmsg_out :=
               'Error while inserting in transactionlog '
               || SUBSTR (SQLERRM, 1, 100);
      END;
   EXCEPTION                                          --<< MAIN EXCEPTION >>--
      WHEN OTHERS
      THEN
         p_resp_code_out := '89';
         p_errmsg_out := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
   END;
END;

/
SHOW ERROR;