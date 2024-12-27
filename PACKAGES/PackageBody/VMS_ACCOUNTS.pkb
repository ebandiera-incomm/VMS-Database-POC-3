create or replace
PACKAGE BODY              VMSCMS.VMS_ACCOUNTS
IS
PROCEDURE get_accountstmt_details (p_inst_code_in                 IN     NUMBER,
                                   p_delivery_channel_in          IN     VARCHAR2,
                                   p_txn_code_in                  IN     VARCHAR2,
                                   p_rrn_in                       IN     VARCHAR2,
                                   p_cust_id_in                   IN     VARCHAR2,
                                   p_partner_id_in                IN     VARCHAR2,
                                   p_trandate_in                  IN     VARCHAR2,
                                   p_trantime_in                  IN     VARCHAR2,
                                   p_curr_code_in                 IN     VARCHAR2,
                                   p_rvsl_code_in                 IN     VARCHAR2,
                                   p_msg_type_in                  IN     VARCHAR2,
                                   p_ip_addr_in                   IN     VARCHAR2,
                                   p_ani_in                       IN     VARCHAR2,
                                   p_dni_in                       IN     VARCHAR2,
                                   p_device_mob_no_in             IN     VARCHAR2,
                                   p_device_id_in                 IN     VARCHAR2,
                                   p_pan_code_in                  IN     VARCHAR2,
                                   p_uuid_in                      IN     VARCHAR2,
                                   p_os_name_in                   IN     VARCHAR2,
                                   p_os_version_in                IN     VARCHAR2,
                                   p_gps_coordinates_in           IN     VARCHAR2,
                                   p_display_resolution_in        IN     VARCHAR2,
                                   p_physical_memory_in           IN     VARCHAR2,
                                   p_app_name_in                  IN     VARCHAR2,
                                   p_app_version_in               IN     VARCHAR2,
                                   p_session_id_in                IN     VARCHAR2,
                                   p_device_country_in            IN     VARCHAR2,
                                   p_device_region_in             IN     VARCHAR2,
                                   p_ip_country_in                IN     VARCHAR2,
                                   p_proxy_flag_in                IN     VARCHAR2,
                                   p_month_year_in                IN     VARCHAR2,
                                   p_account_type_in              IN     VARCHAR2,
                                   p_resp_code_out                OUT    VARCHAR2,
                                   p_respmsg_out                  OUT    VARCHAR2,
                                   p_acct_type_out                OUT    VARCHAR2,
                                   p_acct_no_out                  OUT    VARCHAR2,
                                   p_first_name_out               OUT    VARCHAR2,
                                   p_middle_name_out              OUT    VARCHAR2,
                                   p_last_name_out                OUT    VARCHAR2,
                                   p_led_bal_out                  OUT    VARCHAR2,
                                   p_acct_bal_out                 OUT    VARCHAR2,
                                   p_opening_bal_out              OUT    VARCHAR2,
                                   p_closing_bal_out              OUT    VARCHAR2,
                                   p_interest_accrued_out         OUT    VARCHAR2,
                                   p_interest_paid_out            OUT    VARCHAR2,
                                   p_percentage_yield_out         OUT    VARCHAR2,
                                   p_interest_rate_out            OUT    VARCHAR2,
                                   p_totfee_stmt_period_out       OUT    VARCHAR2,
                                   p_totfee_stmt_year_out         OUT    VARCHAR2,
				   p_prev_month_fee_out	          OUT    VARCHAR2,
                                   p_statement_footer_out         OUT    VARCHAR2,
                                   p_transaction_out              OUT    sys_refcursor
                                   )
IS
/*******************************************************************************
     * Modified by       : Sivakumar M
     * Modified Date     : 02-June-18
     * Modified For      : VMS-372
     * Reviewer          : Saravanakumar A
     * Build Number      : R03_B0001
     
     * Modified by       : Sivakumar M
     * Modified Date     : 28-June-18
     * Modified For      : VMS-372
     * Reviewer          : Saravanakumar A
     * Build Number      : R03_B0002
     * Modified by       : Vini
     * Modified Date     : 11-Jul-2018
     * Modified For      : FSAPICCA-113
     * Reviewer          : Saravanakumar A
     * Build Number      : R03_B0005
  * Modified By       : Sivakumar M
  * Modified Date     : 08-Feb-2019 
  * Purpose           : VMS-780 
  * Reviewer          : Saravanakumar
  * Build Number      : VMSR12-B0003
  
   * Modified By      : Sivakumar M
    * Modified Date    : 23-May-2019
    * Purpose          : VMS-922
    * Reviewer         : Saravanan
    * Release Number   : VMSGPRHOST R16
	
	* Modified By      : Baskar Krishnan
    * Modified Date    : 08-Aug-2019
    * Purpose          : VMS-1022
    * Reviewer         : Saravanan
    * Release Number   : VMSGPRHOST R19
    
    
    * Modified By      : Baskar Krishnan
    * Modified Date    : 10-JuL-2020
    * Purpose          : VMS-2693 - Include previous month fee amount in 
    					My Vanilla CSD statement.
    * Reviewer         : Saravanan
    * Release Number   : VMSGPRHOST R33 B1
    
    * Modified by        : UBAIDUR RAHMAN H
    * Modified Date      : 22-Mar-2021.
    * Modified For       : VMS-3945.
    * Modified Reason    : GPR Statement Enhancement--Complete ATM Address--CHW and CCA
    * Reviewer           : Saravana Kumar
    * Build Number       : R44_B0001
    
    * Modified by        : UBAIDUR RAHMAN H
    * Modified Date      : 26-Oct-2021.
    * Modified For       : VMS-4379.
    * Modified Reason    : Remove Account Statement Txn log logging into Transactionlog
    * Reviewer           : Saravana Kumar
    * Build Number       : R52_B3

    * Modified By      : John Gingrich
    * Modified Date    : 08-28-2023
    * Purpose          : Concurrent Pre-Auth Reversals
    * Reviewer         :
    * Release Number   : VMSGPRHOSTR85 for VMS-5551	
	
	* Modified By      : venkat Singamaneni
    * Modified Date    : 5-11-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jey
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
    
********************************************************************************/
      l_account_type      VARCHAR2 (100)
                               := NVL (UPPER (p_account_type_in), 'SPENDING');
      l_select_query      VARCHAR2 (20000);
      l_query             VARCHAR2 (10000);
      l_exec_query        VARCHAR2 (10000);
      l_start_date        DATE;
      l_end_date          DATE;
      l_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no           cms_acct_mast.cam_acct_no%TYPE;
	  l_spending_acct_no  cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code         cms_appl_pan.cap_prod_code%TYPE;
      l_prod_cattype      cms_appl_pan.cap_card_type%TYPE;
      l_card_stat         cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date        cms_appl_pan.cap_expry_date%TYPE;
      l_active_date       cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
      l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
      l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_comb_hash         pkg_limits_check.type_hash;
      l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp         TIMESTAMP;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
      l_acct_type         cms_acct_mast.cam_type_code%TYPE;
      l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type    transactionlog.feeattachtype%TYPE;
      l_tranfee_amt       transactionlog.tranfee_amt%TYPE;
      l_total_amt         cms_acct_mast.cam_acct_bal%TYPE;
      l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
      l_errmsg            VARCHAR2 (500);
      exp_reject_record   EXCEPTION;
      l_status_chk        pls_integer;
      l_precheck_flag     pls_integer;
      l_tran_amt          cms_acct_mast.cam_acct_bal%TYPE;
      l_audit_flag		    cms_transaction_mast.ctm_txn_log_flag%TYPE;
BEGIN

  BEGIN
         p_resp_code_out := '00';
         p_respmsg_out := 'success';
         l_tran_amt:=0;

 --SN:Start and End date
  Begin
       l_start_date := to_date('01' || p_month_year_in,'DDMMYYYY');
       SELECT to_date(to_char(last_day(l_start_date),'ddmmyyyy')||'23:59:59','ddmmyyyyhh24:mi:ss')
       INTO  l_end_date
       FROM  dual;

    EXCEPTION
      WHEN OTHERS THEN
        l_errmsg := 'Problem while  converting  month year' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
   --EN:Start and End date

   -- SN Validate account type and transaction filter
     BEGIN
            IF (upper(l_account_type) NOT IN ('SPENDING', 'SAVINGS'))
            THEN
               p_resp_code_out := '21';
               RAISE exp_reject_record;
            END IF;

         EXCEPTION
            WHEN exp_reject_record
            THEN
               l_errmsg :=
                     'Error in Input Data - Account Type '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error in Input Data - Account Type '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

-- EN Validate account type and transaction filter

--Sn pan details
         BEGIN
          SELECT cap_pan_code, cap_pan_code_encr,cap_acct_no,
                cap_card_stat, cap_prod_code, cap_card_type,
                cap_expry_date, cap_active_date, cap_prfl_code,
                cap_proxy_number,cap_cust_code,
                decode(cpc_encrypt_enable,'Y',fn_dmaps_main(ccm_first_name),ccm_first_name) ,
                decode(cpc_encrypt_enable,'Y',fn_dmaps_main(ccm_mid_name),ccm_mid_name) ,
                decode(cpc_encrypt_enable,'Y',fn_dmaps_main(ccm_last_name),ccm_last_name)
           INTO l_hash_pan, l_encr_pan,l_acct_no,
                l_card_stat, l_prod_code, l_prod_cattype,
                l_expry_date, l_active_date, l_prfl_code,
                l_proxynumber,l_cust_code,p_first_name_out,
                p_middle_name_out,p_last_name_out
           FROM cms_appl_pan , cms_cust_mast,cms_prod_cattype
          WHERE cap_inst_code = p_inst_code_in
          and cap_inst_code=cpc_inst_code
          and cap_prod_code=cpc_prod_code
          and cap_card_type=cpc_card_type
            AND cap_pan_code = gethash (p_pan_code_in)
            AND cap_mbr_numb = '000'
            AND ccm_inst_code = p_inst_code_in
            AND ccm_cust_code = cap_cust_code;

         EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
                 RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

--En pan details
         l_spending_acct_no := l_acct_no;
         
         --- Added for VMS-4379 - Remove 'ACCOUNT STATEMENT' Transaction logging from Transactionlog.
         BEGIN  
                    
               SELECT nvl(ctm_txn_log_flag,'T')
                 INTO l_audit_flag
                 FROM cms_transaction_mast
                WHERE ctm_inst_code = 1
                  AND ctm_tran_code = p_txn_code_in
                  AND ctm_delivery_channel = p_delivery_channel_in;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code_out := '12';
                  l_errmsg :=
                        'Error while selcting txn log type'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
--Sn Validating Savings Account type
 IF upper(p_account_type_in) = 'SAVINGS'
 THEN
    BEGIN
         SELECT cam_acct_no
         INTO l_acct_no
         FROM CMS_ACCT_MAST
         WHERE cam_inst_code = p_inst_code_in
         AND cam_type_code = '2'
         AND cam_acct_id   in (select cca_acct_id from cms_cust_acct where cca_cust_code = l_cust_code);

    EXCEPTION
             WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Saving account not created ' ;
                 RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                   'Error in getting savings account number' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
    END;
 END IF;
--En Validating Account type

-- Sn Transaction Details  procedure call
         BEGIN
            vmscommon.get_transaction_details (p_inst_code_in,
                                               p_delivery_channel_in,
                                               p_txn_code_in,
                                               l_cr_dr_flag,
                                               l_txn_type,
                                               l_txn_desc,
                                               l_prfl_flag,
                                               l_preauth_flag,
                                               l_login_txn,
                                               l_preauth_type,
                                               l_dup_rrn_check,
                                               p_resp_code_out,
                                               l_errmsg
                                              );


            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                  'Error from Transaction Details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En Transaction Details  procedure call

         -- Sn validating Date Time RRN

         IF l_dup_rrn_check = 'Y' AND l_audit_flag = 'T'     ------ Modified for VMS-4379 - Remove 'ACCOUNT STATEMENT' Transaction logging from Transactionlog.
         THEN
            BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out
                                        );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                     'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END;
         END IF;


         -- En validating Date Time RRN

--SN Perform common validations
        BEGIN
      sp_status_check_gpr (p_inst_code_in,
                           p_pan_code_in,
                           p_delivery_channel_in,
                           l_expry_date,
                           l_card_stat,
                           p_txn_code_in,
                           '0',--p_txn_mode_in',
                           l_prod_code,
                           l_prod_cattype,
                           p_msg_type_in,
                           p_trandate_in,
                           p_trantime_in,
                           NULL,
                           NULL,
                           NULL,
                           p_resp_code_out,
                           l_errmsg
                          );

      IF (   (p_resp_code_out <> '1' AND l_errmsg <> 'OK')
          OR (p_resp_code_out <> '0' AND l_errmsg <> 'OK'))  THEN
         RAISE exp_reject_record;
      ELSE
         l_status_chk := p_resp_code_out;
         p_resp_code_out := '1';
      END IF;
   EXCEPTION  WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS  THEN
         p_resp_code_out := '21';
         l_errmsg :=  'Error from GPR Card Status Check '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En GPR Card status check
   IF l_status_chk = '1'
   THEN
      -- Expiry Check
      BEGIN
         IF TO_DATE (p_trandate_in, 'YYYYMMDD') >  LAST_DAY (TO_CHAR (l_expry_date, 'DD-MON-YY'))
         THEN
            p_resp_code_out := '13';
            l_errmsg := 'EXPIRED CARD';
            RAISE exp_reject_record ;
         END IF;
      EXCEPTION WHEN exp_reject_record THEN
               RAISE;
         WHEN OTHERS    THEN
            p_resp_code_out := '21';
            l_errmsg :='ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_reject_record;
      END;
      --Sn select authorization processe flag
      BEGIN
         SELECT ptp_param_value
           INTO l_precheck_flag
           FROM pcms_tranauth_param
          WHERE ptp_param_name = 'PRE CHECK' AND ptp_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS   THEN
            p_resp_code_out := '21';
            l_errmsg :=  'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      --Sn check for precheck
      IF l_precheck_flag = 1  THEN
         BEGIN
            sp_precheck_txn (p_inst_code_in,
                             p_pan_code_in,
                             p_delivery_channel_in,
                             l_expry_date,
                             l_card_stat,
                             p_txn_code_in,
                             '0',--p_txn_mode_in,
                             p_trandate_in,
                             p_trantime_in,
                             l_tran_amt,
                             NULL,
                             NULL,
                             p_resp_code_out,
                             l_errmsg
                            );

            IF (p_resp_code_out <> '1' OR l_errmsg <> 'OK') THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION WHEN exp_reject_record THEN
               RAISE;
            WHEN OTHERS   THEN
               p_resp_code_out := '21';
               l_errmsg := 'Error from precheck processes '  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;
   END IF;
        
        /*
         BEGIN
            vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
                                                  p_msg_type_in,
                                                  p_rrn_in,
                                                  p_delivery_channel_in,
                                                  p_txn_code_in,
                                                  0,
                                                  p_trandate_in,
                                                  p_trantime_in,
                                                  '00',
                                                  l_txn_type,
                                                  p_pan_code_in,
                                                  l_hash_pan,
                                                  l_encr_pan,
                                                  l_spending_acct_no,
                                                  l_card_stat,
                                                  l_expry_date,
                                                  l_prod_code,
                                                  l_prod_cattype,
                                                  l_prfl_flag,
                                                  l_prfl_code,
                                                  l_txn_type,
                                                  p_curr_code_in,
                                                  l_preauth_flag,
                                                  l_txn_desc,
                                                  l_cr_dr_flag,
                                                  l_login_txn,
                                                  p_resp_code_out,
                                                  l_errmsg,
                                                  l_comb_hash,
                                                  l_auth_id,
                                                  l_fee_code,
                                                  l_fee_plan,
                                                  l_feeattach_type,
                                                  l_tranfee_amt,
                                                  l_total_amt,
                                                  l_preauth_type
                                                 );

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
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error from authorize_nonfinancial_txn '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END; */
         
         --EN Perform common validations

    p_acct_type_out := upper(p_account_type_in);
    p_acct_no_out   := l_acct_no;

   --SN Ledger and Acct balance
   BEGIN
   SELECT trim(to_char(nvl(cam_ledger_bal,0),'99999999999999990.99')) ,
          trim(to_char(nvl(cam_acct_bal,0),'99999999999999990.99'))
   INTO   p_led_bal_out,
          p_acct_bal_out
   FROM   CMS_ACCT_MAST
   WHERE  cam_inst_code = p_inst_code_in
   and cam_acct_no =  l_acct_no;
   EXCEPTION
       WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card/ Account ' || gethash (p_pan_code_in);
                 RAISE exp_reject_record;
       WHEN OTHERS THEN
        p_resp_code_out := '21';
        l_errmsg := 'Problem while selecting ledger and account balance';
        RAISE exp_reject_record;
   END;
    --EN Ledger and Acct bal

     --SN Opening Balance
    BEGIN

        SELECT *  INTO p_opening_bal_out FROM
        (SELECT trim(to_char(nvl(csl_opening_bal,
                         0),
                    '99999999999999990.99'))
        FROM VMSCMS.CMS_STATEMENTS_LOG_VW                 --Added for VMS-5735/FSP-991
        WHERE csl_acct_no = l_acct_no
        AND csl_inst_code = p_inst_code_in
        AND csl_ins_date
              between l_start_date  and l_end_date
               order by csl_ins_date asc, csl_txn_seq asc) where rownum = 1;

     EXCEPTION
      WHEN no_data_found THEN
         p_opening_bal_out := '0.00';
      WHEN OTHERS THEN
        l_errmsg := 'Error while selecting opening balance ' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
    --EN Opening Balance

     --SN Closing Balance
    BEGIN
        SELECT *  INTO p_closing_bal_out FROM
        (SELECT trim(to_char(nvl(csl_closing_balance,
                         0),
                     '99999999999999990.99'))
         FROM VMSCMS.CMS_STATEMENTS_LOG_VW             --Added for VMS-5735/FSP-991        
         WHERE csl_acct_no = l_acct_no
         AND csl_inst_code = p_inst_code_in
         AND csl_ins_date
              between l_start_date  and l_end_date
               order by csl_ins_date desc, csl_txn_seq desc) where rownum = 1;

    EXCEPTION
      WHEN no_data_found THEN
         p_closing_bal_out := '0.00';
      WHEN OTHERS THEN
        l_errmsg := 'Error while selecting closing balance' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
      --EN Closing Balance

    IF upper(p_account_type_in) = 'SAVINGS' THEN

   --SN: Interest Rate and Percentage yield
     BEGIN
        SELECT * INTO p_interest_rate_out, p_percentage_yield_out
        FROM (SELECT   trim(to_char(nvl(cid_interest_rate, 0),
                '99999999999999990.99')),
                 trim(to_char(nvl(cid_apye_amount, 0),
                '99999999999999990.99'))

        FROM vmscms.cms_interest_detl
        WHERE cid_acct_no = l_acct_no
        AND cid_inst_code = p_inst_code_in
        AND cid_calc_date between
            l_start_date  and l_end_date
            order by cid_calc_date desc) where rownum = 1;

            p_interest_rate_out    := ( p_interest_rate_out    || '%');
            p_percentage_yield_out := ( p_percentage_yield_out || '%');

     EXCEPTION
      WHEN no_data_found THEN
        BEGIN
            SELECT * INTO p_interest_rate_out, p_percentage_yield_out
        FROM (SELECT   trim(to_char(nvl(cid_interest_rate, 0),
                '99999999999999990.99')),
                 trim(to_char(nvl(cid_apye_amount, 0),
                '99999999999999990.99'))

        FROM vmscms.cms_interest_detl_hist
        WHERE cid_acct_no = l_acct_no
        AND cid_inst_code = p_inst_code_in
        AND cid_calc_date between
            l_start_date  and l_end_date
            order by cid_calc_date desc) where rownum = 1;
			
			p_interest_rate_out    := ( p_interest_rate_out    || '%');
            p_percentage_yield_out := ( p_percentage_yield_out || '%');
        EXCEPTION
          WHEN no_data_found THEN
            p_interest_rate_out := '0.00%';
            p_percentage_yield_out := '0.00%';
          WHEN OTHERS THEN
            l_errmsg := 'Error while selecting interest detl hist ...' ||
                             substr(SQLERRM,
                                    1,
                                    200);
            RAISE exp_reject_record;
        END;
      WHEN OTHERS THEN
        l_errmsg := 'Error while selecting interest detl ...' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
    --EN: Interest Rate and Percentage yield

    --SN Interest Paid
     BEGIN
         SELECT trim(to_char(nvl(csl_trans_amount, 0),
                '99999999999999990.99'))
          INTO p_interest_paid_out
          FROM VMSCMS.CMS_STATEMENTS_LOG_VW               --Added for VMS-5735/FSP-991
          WHERE csl_trans_type = 'CR'
           AND csl_delivery_channel = '05'
           AND csl_txn_code = '13'
           AND csl_acct_no = l_acct_no
           AND csl_inst_code = p_inst_code_in
           AND csl_ins_date between
            l_start_date and l_end_date;
      EXCEPTION
        WHEN no_data_found THEN
          p_interest_paid_out := '0.00';
        WHEN OTHERS THEN
          l_errmsg := 'Error while selecting interest amount from statements...' ||
                           substr(SQLERRM,
                                  1,
                                  200);
          RAISE exp_reject_record;
      END;
  --EN Interest Paid

    --SN Interest Accrued
    BEGIN
      SELECT trim(to_char(nvl(SUM(cid_interest_amount),
                         '0'),
                     '99999999999999990.99'))
        INTO p_interest_accrued_out
        FROM vmscms.cms_interest_detl
       WHERE cid_calc_date BETWEEN
             l_start_date AND l_end_date
         AND cid_acct_no = l_acct_no
         AND cid_inst_code = p_inst_code_in;
      IF p_interest_accrued_out = '0.00'
      THEN
        BEGIN
          SELECT trim(to_char(nvl(SUM(cid_interest_amount),
                             '0'),
                         '99999999999999990.99'))
            INTO p_interest_accrued_out
            FROM vmscms.cms_interest_detl_hist
           WHERE to_date(cid_calc_date,
                         'YYYY-MM-DD') BETWEEN l_start_date AND
                 l_end_date
             AND cid_acct_no = l_acct_no
             AND cid_inst_code = p_inst_code_in;
        EXCEPTION
         WHEN no_data_found THEN
          p_interest_accrued_out := '0.00';
          WHEN OTHERS THEN
            l_errmsg := 'Error while selecting interest amount from hist ...' ||
                             substr(SQLERRM,
                                    1,
                                    200);
            RAISE exp_reject_record;
        END;
      END IF;
    EXCEPTION
     WHEN no_data_found THEN
          p_interest_accrued_out := '0.00';
      WHEN OTHERS THEN
        l_errmsg := 'Error while selecting interest amount from interest detl ...' ||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;
    --En Interest Accrued
 END IF;

 -- SN Total Fee Accessed for Statement Period
 BEGIN

    select
      sum(decode(csl_trans_type,'DR',csl_trans_amount,'CR',-csl_trans_amount)) ,
      sum(case
           when csl_ins_date
              between  l_start_date  and l_end_date
           then
              (decode(csl_trans_type,'DR',csl_trans_amount,'CR',-csl_trans_amount))
           else
               0
          end) as totfee		  	  
     into p_totfee_stmt_year_out, p_totfee_stmt_period_out
     from VMSCMS.CMS_STATEMENTS_LOG_VW                       --Added for VMS-5735/FSP-991
     where csl_inst_code = 1
    and csl_acct_no =  l_acct_no
    and TXN_FEE_FLAG = 'Y'
    and csl_ins_date between
    trunc(l_start_date,'Y')  and l_end_date;
	
		p_totfee_stmt_year_out:= NVL(p_totfee_stmt_year_out,'0.00');
		p_totfee_stmt_period_out:= NVL(p_totfee_stmt_period_out,'0.00');

   EXCEPTION
     WHEN OTHERS THEN
        p_resp_code_out := '21';
        l_errmsg := 'Error while selecting total fee amount...'||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;

  -- EN Total Fee Accessed for Statement Period
  
  -- SN Total Fee Accessed for previous month  --- Added for VMS-2693
 BEGIN

    
	
    select      
      sum(decode(csl_trans_type,'DR',csl_trans_amount,'CR',-csl_trans_amount)) as prevmonthfee		  	  
     into
	 p_prev_month_fee_out   
     from VMSCMS.CMS_STATEMENTS_LOG_VW                          --Added for VMS-5735/FSP-991
     where csl_inst_code = 1
    and csl_acct_no =  l_acct_no
    and TXN_FEE_FLAG = 'Y'
    and csl_ins_date between add_months(l_start_date,-1) and add_months(l_end_date,-1) ;
	
		 
		p_prev_month_fee_out:= NVL(p_prev_month_fee_out,'0.00');

   EXCEPTION
     WHEN OTHERS THEN
        p_resp_code_out := '21';
        l_errmsg := 'Error while selecting previous month fee amount...'||
                         substr(SQLERRM,
                                1,
                                200);
        RAISE exp_reject_record;
    END;

  -- EN Total Fee Accessed for previous month 
  
  
  
 --SN Footer Note
    BEGIN
       select cpm_statement_footer1||'~'||
              cpm_statement_footer2||'~'||
              cpm_statement_footer3||'~'||
              cpm_statement_footer4||'~'||
              cpm_statement_footer5
       into p_statement_footer_out
       from cms_prod_mast
       where cpm_inst_code = p_inst_code_in
       and cpm_prod_code=l_prod_code;

   EXCEPTION
    WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Problem while selecting statement footer';
    END;

    --EN Footer Note

    --EN:ACCOUNT Statement details

  -- SN Generate common select query
         BEGIN
    l_select_query :='select csl_ins_date run_date,CSL_TIME_STAMP ts,csl_rrn rrnid,
                                   to_char(csl_ins_date, ''YYYY-MM-DD HH24:MI:SS'') transactionDate,
                                   decode(upper(CSL_TRANS_TYPE),''CR'',''Credit'',''DR'',''Debit'') crdrFlag,
				   CASE 
				   WHEN csl_delivery_channel IN (''01'',''02'') AND TXN_FEE_FLAG = ''N'' 
				   THEN DECODE(nvl(regexp_instr(csl_trans_narrration,''RVSL-'',1,1,0,''i''),0),0,TRANS_DESC,
	                          ''RVSL-''||TRANS_DESC)
				  ||''/''||DECODE(nvl(merchant_name,CSL_MERCHANT_NAME), NULL, DECODE(delivery_channel, ''01'', ''ATM'', ''02'', ''Retail Merchant''), nvl(merchant_name,CSL_MERCHANT_NAME)
                                                                                                             || ''/''
                                                                                                             || terminal_id
                                                                                                             || ''/''
                                                                                                             || merchant_street
                                                                                                             || ''/''
                                                                                                             || merchant_city
                                                                                                             || ''/''
                                                                                                             || merchant_state
                                                                                                             || ''/''
                                                                                                             || preauthamount
                                                                                                             || ''/''
                                                                                                             ||business_date
                                                                                                             ||''/''
                                                                                                             ||auth_id)
				   ELSE									     
                                   DECODE ( NVL (REVERSAL_CODE, ''0''), ''0'', DECODE ( TXN_FEE_FLAG, ''Y'',
                                      REPLACE(TRIM(UPPER(SUBSTR(CSL_TRANS_NARRRATION,0,DECODE(instr(CSL_TRANS_NARRRATION,'' - '',-1),0,LENGTH(CSL_TRANS_NARRRATION),instr(CSL_TRANS_NARRRATION,'' - '',-1))))),''CLAWBACK-'''',''), 
                                      DECODE(upper(trim(NVL(trans_desc,CTM_TRAN_DESC))),upper(trim(CTM_TRAN_DESC)),ctm_display_txndesc,trans_desc))
                                    , DECODE ( TXN_FEE_FLAG, ''Y'', REPLACE(TRIM(UPPER(SUBSTR(CSL_TRANS_NARRRATION,0,DECODE(instr(CSL_TRANS_NARRRATION,'' - '',-1),0,LENGTH(CSL_TRANS_NARRRATION),instr(CSL_TRANS_NARRRATION,'' - '',-1))))),''CLAWBACK-'',''''), ''RVSL-''
                                      ||
                                      DECODE(upper(trim(NVL(trans_desc,CTM_TRAN_DESC))),upper(trim(CTM_TRAN_DESC)),ctm_display_txndesc,trans_desc))) 
                                      || (
                                      CASE
                                          WHEN clawback_indicator = ''Y''
                                          THEN
                                            (
                                            SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'''','' -''
                                              || CPC_CLAWBACK_DESC))
                                              ||rtrim(SUBSTR(CSL_TRANS_NARRRATION,instr(CSL_TRANS_NARRRATION,'' - '',-1)))
                                              FROM CMS_PROD_CATTYPE
                                           WHERE CPC_PROD_CODE = PRODUCTID
                                            AND CPC_CARD_TYPE= CATEGORYID
                                            AND CPC_INST_CODE=INSTCODE
                                        ) 
                                      ELSE DECODE (TXN_FEE_FLAG, ''Y'', '' - FEE'')
                                   END)                        
                                    END transactionDescription,
                                   TRIM(TO_CHAR (nvl(csl_trans_amount,amount), ''99999999999999990.99'')) transactionAmount,
                                   TRIM(TO_CHAR (nvl(csl_closing_balance,acct_balance), ''99999999999999990.99'')) balance,
                                   reason reason,
                                   --'''' checkDescription,
                                   --'''' checkRoutingNumber,
                                   --'''' checkAccountNumber,
                                    case when csl_delivery_channel = ''13'' then
                                    (select ctd_check_desc||''~''||ctd_routing_number||''~''||ctd_check_acctno
                                    from   VMSCMS.CMS_TRANSACTION_LOG_DTL_VW        --Added for VMS-5735/FSP-991
                                    where   csl_rrn=ctd_rrn 
                                    and csl_acct_no=ctd_cust_acct_number
                                    and  csl_delivery_channel = ctd_delivery_channel
                                    and  csl_txn_code = ctd_txn_code 
                                    and  csl_business_date = ctd_business_date
                                    and  csl_business_time = ctd_business_time
                                    and rownum=1) end check_detls,
                                   ''POSTED'' transactionType,
                                   csl_acct_no   accountNumber,
                                   csl_to_acctno   toAccountNumber,
                                   CSL_PANNO_LAST4DIGIT lastFourPAN,
                                   (substr(fn_dmaps_main(topup_card_no_encr),
                                      length(fn_dmaps_main(topup_card_no_encr)) - 3,
                                      length(fn_dmaps_main(topup_card_no_encr)))) toLastFourPAN,
                                   mccode MCCDescription,
                            CASE  WHEN ((csl_delivery_channel = ''11'' AND csl_txn_code = ''22'' )
                                     OR (csl_delivery_channel = ''03'' AND csl_txn_code = ''93'')) 
                                    AND txn_fee_flag = ''N'' THEN
                                       NVL(COMPANYNAME,'''') ||''/ '' || NVL(COMPENTRYDESC,'''')
                                        || ''/ '' ||NVL(INDIDNUM,'''') || ''/ to '' ||INDNAME
                        WHEN csl_delivery_channel=''02'' and csl_txn_code=''37'' and TXN_FEE_FLAG =''N'' THEN
                                  (select cpi_payer_id  from vmscms.cms_payment_info where 
                                  CPI_INST_CODE=csl_inst_code
                                  and cpi_RRN=csl_RRN
                                  and CPI_PAN_CODE=csl_PAN_no
                                  and rownum = 1)
                        WHEN ((csl_delivery_channel=''03'' and csl_txn_code=''39'')
                        or (csl_delivery_channel=''10'' and csl_txn_code=''07'')
                        or (csl_delivery_channel=''07'' and csl_txn_code=''07'')						
                        or (csl_delivery_channel=''13'' and csl_txn_code=''13'') ) 
                        and CUSTOMER_CARD_NO is null and TXN_FEE_FLAG =''N'' THEN
                                  (select vmscms.fn_dmaps_main(ccm_first_name)||'' ''||vmscms.fn_dmaps_main(ccm_last_name) from vmscms.cms_cust_mast
                                  where ccm_inst_code=csl_inst_code
                                  and ccm_cust_code=(select cap_cust_code from vmscms.cms_appl_pan   
                                                      where cap_inst_code=csl_inst_code 
                                                            and cap_mbr_numb=''000'' 
                                                            and cap_pan_code=  (select CUSTOMER_CARD_NO from VMSCMS.TRANSACTIONLOG_VW      --Added for VMS-5735/FSP-991 
                                                                      where   CSL_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                      AND CSL_TXN_CODE       = TXN_CODE
                                                                      AND CSL_RRN            = RRN
                                                                      AND CSL_AUTH_ID        = AUTH_ID
                                                                      AND CSL_INST_CODE      = INSTCODE and response_code=''00'' ))) end fromThirdPartyName,
                         case  WHEN csl_delivery_channel=''02''  and csl_txn_code=''12'' and TXN_FEE_FLAG =''N'' THEN
                            (select cpi_spu_id  from vmscms.cms_payment_info where 
                                  CPI_INST_CODE=csl_inst_code
                                  and cpi_RRN=csl_RRN
                                  and CPI_PAN_CODE=csl_PAN_no
                                  and rownum = 1)
                         WHEN ((csl_delivery_channel=''03'' and csl_txn_code=''39'')
                        or (csl_delivery_channel=''10'' and csl_txn_code=''07'')
                        or (csl_delivery_channel=''07'' and csl_txn_code=''07'')						
                        or (csl_delivery_channel=''13'' and csl_txn_code=''13'') )
                        and CUSTOMER_CARD_NO is not null and TXN_FEE_FLAG =''N'' THEN
                                  (select vmscms.fn_dmaps_main(ccm_first_name)||'' ''||vmscms.fn_dmaps_main(ccm_last_name) from vmscms.cms_cust_mast
                                  where ccm_inst_code=csl_inst_code
                                  and ccm_cust_code=(select cap_cust_code from vmscms.cms_appl_pan   
                                                      where cap_inst_code=csl_inst_code 
                                                            and cap_mbr_numb=''000'' 
                                                            and cap_pan_code= TOPUP_CARD_NO)) end toThirdPartyName,
                                   merchant_id merchantID,
                                   merchant_name mername,
                                   merchant_street streetAddress,
                                   merchant_city city,
                                   merchant_zip postalCode,
                                   case when delivery_channel=''03'' and txn_code in(''13'',''14'') then null
                                   else
                                   merchant_state
                                   end state,
                                   country_code country,
                                   terminal_id terminalId
                            from   VMSCMS.TRANSACTIONLOG_VW,       --Added for VMS-5735/FSP-991
								  -- vmscms.cms_transaction_log_dtl,
								   vmscms.cms_transaction_mast,
								   VMSCMS.CMS_STATEMENTS_LOG_VW    --Added for VMS-5735/FSP-991
							where  csl_acct_no = :l_acct_no  
							 -- and  csl_rrn = ctd_rrn 
							 -- and  csl_delivery_channel = ctd_delivery_channel
							 -- and  csl_txn_code = ctd_txn_code
							 -- and  csl_business_date = ctd_business_date
							 -- and  csl_business_time = ctd_business_time
							 -- and  ctd_process_flag IN ( ''Y'' , ''C'') modified for vms-780:to include decline fee record
							  and  csl_inst_code = ctm_inst_code 
							  and  csl_delivery_channel = ctm_delivery_channel 
							  and  csl_txn_code = ctm_tran_code
							  and  CSL_PAN_NO= customer_card_no (+)
							  and  csl_rrn = rrn(+) 
							  and  CSL_TXN_CODE = txn_code(+) 
							  and  CSL_DELIVERY_CHANNEL= delivery_channel (+)
							  and  CSL_AUTH_ID= AUTH_ID (+)
							 -- and  (response_code = ''00'' or response_code is null) modified for vms-780:to include decline fee record
							  and  csl_ins_date  between :l_start_date and :l_end_date 
							       order by run_date desc,csl_txn_seq desc';


                   END;



     
-- EN Generate common select query

-- SN Open cursor to execute query
         BEGIN
               OPEN p_transaction_out FOR l_select_query
               USING l_acct_no,l_start_date,l_end_date;

         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error while executing query '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

-- EN Close cursor to execute query

         p_resp_code_out := '1';

       EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
       END;

        BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = TO_NUMBER (p_resp_code_out);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'Problem while selecting respose code'
                  || p_resp_code_out
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
         END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_hashkey_id :=
            gethash (   p_delivery_channel_in
                     || p_txn_code_in
                     || p_pan_code_in
                     || p_rrn_in
                     || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN

          SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL,CAM_TYPE_CODE
          INTO   l_acct_bal,l_ledger_bal,l_acct_type
          FROM   CMS_ACCT_MAST
          WHERE  CAM_INST_CODE = p_inst_code_in
          AND    CAM_ACCT_NO = l_acct_no;

      EXCEPTION
        WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card/ Account ' ;
        WHEN OTHERS
        THEN
           p_resp_code_out := '12';
           l_errmsg :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      IF p_resp_code_out <> '00' THEN
          p_respmsg_out        :=l_errmsg;
      END IF;
      
      IF l_audit_flag = 'T'         --- Modified for VMS-4379 - Remove 'ACCOUNT STATEMENT' Transaction logging from Transactionlog.
	  THEN 

      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_prod_cattype,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg
                                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
      
      ELSIF l_audit_flag = 'A'
      THEN
      
      BEGIN 
      
         
	VMSCMS.VMS_LOG.LOG_TRANSACTIONLOG_AUDIT(p_msg_type_in,
												 p_rrn_in,
												 p_delivery_channel_in,
												 p_txn_code_in,                                     
												 '0',   
												 p_trandate_in,    
												 p_trantime_in,   
												 '00',  
												 p_pan_code_in,
												 l_errmsg,
												 0,
												 NULL,
												 CASE WHEN p_resp_code_out = '00' THEN  '1' ELSE p_resp_code_out END,
												 p_curr_code_in,
												 p_partner_id_in,
												 NULL,   
												 l_errmsg,
                                                 NULL,
                                                 p_ip_addr_in,
                                                 NULL,
                                                 CASE WHEN p_resp_code_out = '00' THEN  'C' ELSE 'F' END,
                                                 P_ANI_IN,
                                                 P_DNI_IN
                                                 ); 
		
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
                  'Erorr while inserting to transaction log AUDIT'
               || SUBSTR (SQLERRM, 1, 300);
      END; 
      
      END IF;

END get_accountstmt_details;

PROCEDURE create_check_deposit(p_inst_code_in             IN  NUMBER,
                     p_delivery_channel_in      IN  VARCHAR2,
                     p_txn_code_in              IN  VARCHAR2,
                     p_rrn_in                   IN  VARCHAR2,
                     p_cust_id_in               IN  VARCHAR2,
                     p_partner_id_in            IN  VARCHAR2,
                     p_trandate_in              IN  VARCHAR2,
                     p_trantime_in              IN  VARCHAR2,
                     p_curr_code_in             IN  VARCHAR2,
                     p_rvsl_code_in             IN  VARCHAR2,
                     p_msg_type_in              IN  VARCHAR2,
                     p_ip_addr_in               IN  VARCHAR2,
                     p_ani_in                   IN  VARCHAR2,
                     p_dni_in                   IN  VARCHAR2,
                     p_device_mob_no_in         IN  VARCHAR2,
                     p_device_id_in             IN  VARCHAR2,
                     p_pan_code_in              IN  VARCHAR2,
                     p_uuid_in                  IN  VARCHAR2,
                     p_os_name_in               IN  VARCHAR2,
                     p_os_version_in            IN  VARCHAR2,
                     p_gps_coordinates_in       IN  VARCHAR2,
                     p_display_resolution_in    IN  VARCHAR2,
                     p_physical_memory_in       IN  VARCHAR2,
                     p_app_name_in              IN  VARCHAR2,
                     p_app_version_in           IN  VARCHAR2,
                     p_session_id_in            IN  VARCHAR2,
                     p_device_country_in        IN  VARCHAR2,
                     p_device_region_in         IN  VARCHAR2,
                     p_ip_country_in            IN  VARCHAR2,
                     p_proxy_flag_in            IN  VARCHAR2,
                     p_check_no_in              IN  VARCHAR2,
                     p_routing_no_in            IN  VARCHAR2,
                     p_chcek_acctno_in          IN  VARCHAR2,
                     p_deposit_id_in            IN  VARCHAR2,
                     p_tran_amount_in           IN  VARCHAR2,
                     p_user_checkdesc_in        IN  VARCHAR2,
                     p_check_imagefs_in         IN  BLOB,
                     p_check_imagebs_in         IN  BLOB,
                     p_resp_code_out            OUT VARCHAR2,
                     p_respmsg_out              OUT VARCHAR2,
                     p_acct_bal_out             OUT VARCHAR2,
                     p_prev_balance             OUT VARCHAR2,
                     p_email_id_out             OUT VARCHAR2,
                     p_org_resp_code            OUT VARCHAR2,
                     p_org_resp_desc            OUT VARCHAR2

                     )
AS
      l_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no           cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code         cms_appl_pan.cap_prod_code%TYPE;
      l_card_type         cms_appl_pan.cap_card_type%TYPE;
      l_card_stat         cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date        cms_appl_pan.cap_expry_date%TYPE;
      l_active_date       cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
      l_comb_hash         pkg_limits_check.type_hash;
      l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp         TIMESTAMP;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
      l_acct_type         cms_acct_mast.cam_type_code%TYPE;
      l_pre_acct_bal      cms_acct_mast.cam_acct_bal%type;
      l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type    transactionlog.feeattachtype%TYPE;
      l_tranfee_amt       transactionlog.tranfee_amt%TYPE;
      l_total_amt         cms_acct_mast.cam_acct_bal%TYPE;
      l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
      l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
      l_errmsg            VARCHAR2 (500);
      l_email_id          cms_cust_mast.ccm_email_one%TYPE;
      l_pendingrrn_count  NUMBER;
      l_concurrent_flag  NUMBER;
      l_txn_flag          cms_checkdeposit_transaction.cct_txn_flag%type;
      l_response_code     cms_checkdeposit_transaction.cct_response_code%type;
      l_response_desc     cms_checkdeposit_transaction.cct_response_desc%type;
      l_tran_amt          cms_acct_mast.cam_acct_bal%TYPE;
      exp_reject_record   EXCEPTION;
      v_encrypt_enable cms_prod_cattype.cpc_encrypt_enable%type;


   BEGIN
      BEGIN

         p_respmsg_out := 'success';
         l_tran_amt := NVL (ROUND (p_tran_amount_in, 2), 0);
    --Sn pan  and customer details
    BEGIN
        SELECT cap_pan_code, cap_pan_code_encr,cap_acct_no,
               cap_card_stat, cap_prod_code, cap_card_type,
               cap_expry_date, cap_active_date, cap_prfl_code,
               cap_proxy_number,cap_cust_code
          INTO l_hash_pan, l_encr_pan,l_acct_no,
               l_card_stat, l_prod_code, l_card_type,
               l_expry_date, l_active_date, l_prfl_code,
               l_proxynumber,l_cust_code
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code_in
           AND cap_pan_code = gethash (p_pan_code_in)
           AND cap_mbr_numb = '000';

       EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' || gethash(p_pan_code_in);
                 RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
         begin
               select cpc_encrypt_enable
               into v_encrypt_enable
               from cms_prod_cattype
               where cpc_inst_code=p_inst_code_in
               and cpc_prod_code=l_prod_code
               and cpc_card_type=l_card_type;
         exception
            when others then
                 p_resp_code_out := '12';
               l_errmsg :=
                   'Error in selecing prod cattype' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record; 
         end;

--Sn pan  and customer details
         -- Sn Transaction Details  procedure call
         BEGIN
            vmscommon.get_transaction_details (p_inst_code_in,
                                               p_delivery_channel_in,
                                               p_txn_code_in,
                                               l_cr_dr_flag,
                                               l_txn_type,
                                               l_txn_desc,
                                               l_prfl_flag,
                                               l_preauth_flag,
                                               l_login_txn,
                                               l_preauth_type,
                                               l_dup_rrn_check,
                                               p_resp_code_out,
                                               l_errmsg
                                              );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                  'Error from Transaction Details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En Transaction Details  procedure call

         -- Sn validating Date Time RRN
         IF l_dup_rrn_check = 'Y' THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out
                                        );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                     'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         END IF;
         -- En validating Date Time RRN

         BEGIN

          SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL,CAM_TYPE_CODE
          INTO   l_acct_bal,l_ledger_bal,l_acct_type
          FROM   CMS_ACCT_MAST
          WHERE  CAM_INST_CODE = p_inst_code_in
          AND    CAM_ACCT_NO = l_acct_no FOR UPDATE;

      EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' ;
        WHEN OTHERS
        THEN
           p_resp_code_out := '12';
           l_errmsg :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;
      
      l_pre_acct_bal :=l_acct_bal;
      
      l_txn_desc := l_txn_desc || substr(p_rrn_in , 1, 5);
      
      if length(l_txn_desc)>50 then
      l_txn_desc := substr(l_txn_desc,1,50);
      end if;
      
         --SN : authorize_nonfinancial_txn check
         BEGIN
            vmscommon.authorize_financial_txn (p_inst_code_in,
                                                  p_msg_type_in,
                                                  p_rrn_in,
                                                  p_delivery_channel_in,
                                                  null,   --p_terminal_id_in
                                                  p_txn_code_in,
                                                  0,
                                                  p_trandate_in,
                                                  p_trantime_in,
                                                  p_pan_code_in,
                                                  l_hash_pan,
                                                  l_encr_pan,
                                                  l_card_stat,
                                                  l_proxynumber,
                                                  l_acct_no,
                                                  l_expry_date,
                                                  l_prod_code,
                                                  l_card_type,
                                                  l_prfl_flag,
                                                  l_prfl_code,
                                                  l_txn_type,
                                                  p_curr_code_in,
                                                  l_preauth_flag,
                                                  l_txn_desc,
                                                  l_cr_dr_flag,
                                                  l_login_txn,
                                                  null,  --ctm_amnt_transfer_flag
                                                  p_inst_code_in,
                                                  l_tran_amt,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  p_rvsl_code_in,
                                           --       l_tran_amt,
                                                  null,
                                                  null,
                                                  p_ip_addr_in,
                                                  p_ani_in,
                                                  p_dni_in,
                                                  p_device_mob_no_in,
                                                  p_device_id_in,
                                                  p_uuid_in,
                                                  p_os_name_in,
                                                  p_os_version_in,
                                                  p_gps_coordinates_in,
                                                  p_display_resolution_in,
                                                  p_physical_memory_in,
                                                  p_app_name_in,
                                                  p_app_version_in,
                                                  p_session_id_in,
                                                  p_device_country_in,
                                                  p_device_region_in,
                                                  null,
                                                  l_auth_id,
                                                  p_resp_code_out,
                                                  l_errmsg
                                                  );
                                        
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
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error from authorize_nonfinancial_txn '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
    --SN : authorize_nonfinancial_txn check
       
    BEGIN
         SELECT decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_email),cam_email)
           INTO p_email_id_out
           FROM cms_addr_mast
          WHERE cam_inst_code = p_inst_code_in
            AND cam_cust_code = l_cust_code
            AND cam_addr_flag = 'P';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '89';
            l_errmsg := 'Email Id not found ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            l_errmsg :=
               'Problem while selecting Email Id '
               || SUBSTR (SQLERRM, 1, 300);
      END;
                 
      BEGIN
    
      select CCT_TXN_FLAG,CCT_RESPONSE_CODE,CCT_RESPONSE_DESC 
      into l_txn_flag,l_response_code,l_response_desc  
      FROM CMS_CHECKDEPOSIT_TRANSACTION 
      where CCT_DELV_CHNL = p_delivery_channel_in
      --and CCT_PARTNER_ID = p_partner_id_in
      and CCT_DEPOSIT_ID = p_deposit_id_in      
      and CCT_INST_CODE = p_inst_code_in;
       
      if l_txn_flag in('1','3') then
      
         if p_delivery_channel_in = '13' then
         p_resp_code_out := '252';
         elsif p_delivery_channel_in = '10' then
         p_resp_code_out := '295';
         end if;
         
         l_errmsg :='Duplicate Deposit ID';  
       
         p_org_resp_code :=l_response_code;
         p_org_resp_desc :=l_response_desc;        
              
         RAISE EXP_REJECT_RECORD;   
       
     END IF;
                
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
         NULL;
       when EXP_REJECT_RECORD then
         RAISE;
       when OTHERS then
            p_resp_code_out := '21';
            l_errmsg :='Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      end;
      
      BEGIN
       sp_autonomous_preauth_log(l_auth_id,p_deposit_id_in||'~'||p_partner_id_in, p_trandate_in, l_hash_pan, p_inst_code_in, p_delivery_channel_in, l_errmsg);
       --Added VMS-5551
       IF l_errmsg != 'OK' THEN
       p_resp_code_out     := '191';
       RAISE exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        p_resp_code_out := '12';
        l_errmsg  := 'Concurrent check Failed' || SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
  
   BEGIN

          SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL,CAM_TYPE_CODE
          INTO   l_acct_bal,l_ledger_bal,l_acct_type
          FROM   CMS_ACCT_MAST
          WHERE  CAM_INST_CODE = p_inst_code_in
          AND    CAM_ACCT_NO = l_acct_no;

      EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' ;
        WHEN OTHERS
        THEN
           p_resp_code_out := '12';
           l_errmsg :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

     p_resp_code_out := '1';
     p_acct_bal_out := l_acct_bal;
     p_prev_balance := l_pre_acct_bal;
     
       EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
           
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
             ROLLBACK;
       END;

        BEGIN
            SELECT cms_iso_respcde,CMS_RESP_DESC
              INTO p_resp_code_out,l_response_desc
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = TO_NUMBER (p_resp_code_out);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'Problem while selecting respose code'
                  || p_resp_code_out
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
         END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_hashkey_id :=
            gethash (   p_delivery_channel_in
                     || p_txn_code_in
                     || l_hash_pan
                     || p_rrn_in
                     || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

     

      IF p_resp_code_out <> '00' THEN
          p_respmsg_out  := l_errmsg;
          
      END IF;
      
     IF p_resp_code_out != '252' and p_resp_code_out != '295' then
         BEGIN
         INSERT INTO cms_checkdeposit_transaction
                     (cct_inst_code, cct_card_no, cct_card_no_encr,
                      cct_acct_no, cct_cust_id, cct_delv_chnl,
                      cct_check_imagefs, cct_check_imagebs, cct_pend_amt,
                      CCT_RRN, cct_act_date, cct_act_time, CCT_CHECK_NO,
                      CCT_TXN_FLAG, CCT_AUTH_ID,cct_check_desc,
                       cct_txn_amnt,cct_deposit_id,CCT_RESPONSE_CODE,CCT_RESPONSE_DESC,cct_routing_no
                     )
              VALUES (p_inst_code_in, l_hash_pan, l_encr_pan,
                      p_chcek_acctno_in, p_cust_id_in, p_delivery_channel_in,
                      p_check_imagefs_in, p_check_imagebs_in, l_tran_amt,
                      p_rrn_in, p_trandate_in, p_trantime_in, p_check_no_in,
                     '1', l_auth_id,p_user_checkdesc_in, 
                      l_tran_amt,p_deposit_id_in,p_resp_code_out,l_response_desc,p_routing_no_in
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_respmsg_out :=
                  'Problem while inserting deposit transaction details '
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
           -- RAISE EXP_REJECT_RECORD;
      END;
      END IF;

      Begin
      sp_autonomous_preauth_logclear(l_auth_id);
      exception
         When others then
           null;
      End;
    
      IF  p_resp_code_out <> '00' THEN   
      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_card_type,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     l_tran_amt,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg
                                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
      END IF;
END create_check_deposit;

PROCEDURE create_check_deposit_reversal(p_inst_code_in             IN  NUMBER,
                     p_delivery_channel_in      IN  VARCHAR2,
                     p_txn_code_in              IN  VARCHAR2,
                     p_rrn_in                   IN  VARCHAR2,
                     p_cust_id_in               IN  VARCHAR2,
                     p_partner_id_in            IN  VARCHAR2,
                     p_trandate_in              IN  VARCHAR2,
                     p_trantime_in              IN  VARCHAR2,
                     p_curr_code_in             IN  VARCHAR2,
                     p_rvsl_code_in             IN  VARCHAR2,
                     p_msg_type_in              IN  VARCHAR2,
                     p_ip_addr_in               IN  VARCHAR2,
                     p_ani_in                   IN  VARCHAR2,
                     p_dni_in                   IN  VARCHAR2,
                     p_device_mob_no_in         IN  VARCHAR2,
                     p_device_id_in             IN  VARCHAR2,
                     p_pan_code_in              IN  VARCHAR2,
                     p_uuid_in                  IN  VARCHAR2,
                     p_os_name_in               IN  VARCHAR2,
                     p_os_version_in            IN  VARCHAR2,
                     p_gps_coordinates_in       IN  VARCHAR2,
                     p_display_resolution_in    IN  VARCHAR2,
                     p_physical_memory_in       IN  VARCHAR2,
                     p_app_name_in              IN  VARCHAR2,
                     p_app_version_in           IN  VARCHAR2,
                     p_session_id_in            IN  VARCHAR2,
                     p_device_country_in        IN  VARCHAR2,
                     p_device_region_in         IN  VARCHAR2,
                     p_ip_country_in            IN  VARCHAR2,
                     p_proxy_flag_in            IN  VARCHAR2,
                     p_check_no_in              IN  VARCHAR2,
                     p_routing_no_in            IN  VARCHAR2,
                     p_chcek_acctno_in          IN  VARCHAR2,
                     p_deposit_id_in            IN  VARCHAR2,
                     p_tran_amount_in           IN  VARCHAR2,
                     p_user_checkdesc_in        IN  VARCHAR2,
                     --     p_original_rrn_in          IN  VARCHAR2,
                     p_resp_code_out            OUT VARCHAR2,
                     p_respmsg_out              OUT VARCHAR2,
                     p_acct_bal_out             OUT VARCHAR2,
                     p_email_id_out             OUT VARCHAR2

                     )
AS
      l_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
      l_acct_no           cms_acct_mast.cam_acct_no%TYPE;
      l_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
      l_prod_code         cms_appl_pan.cap_prod_code%TYPE;
      l_card_type         cms_appl_pan.cap_card_type%TYPE;
      l_card_stat         cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date        cms_appl_pan.cap_expry_date%TYPE;
      l_active_date       cms_appl_pan.cap_expry_date%TYPE;
      l_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
      l_cr_dr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type          cms_transaction_mast.ctm_tran_type%TYPE;
      l_txn_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_dup_rrn_check     cms_transaction_mast.ctm_rrn_check%TYPE;
      l_comb_hash         pkg_limits_check.type_hash;
      l_auth_id           cms_transaction_log_dtl.ctd_auth_id%TYPE;
      l_timestamp         TIMESTAMP;
      l_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
      l_acct_type         cms_acct_mast.cam_type_code%TYPE;
      l_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
      l_fee_code          cms_fee_mast.cfm_fee_code%TYPE;
      l_fee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
      l_feeattach_type    transactionlog.feeattachtype%TYPE;
      l_tranfee_amt       transactionlog.tranfee_amt%TYPE;
      l_total_amt         cms_acct_mast.cam_acct_bal%TYPE;
      l_preauth_type      cms_transaction_mast.ctm_preauth_type%TYPE;
      l_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_proxynumber       cms_appl_pan.cap_proxy_number%TYPE;
      l_cust_code         cms_appl_pan.cap_cust_code%TYPE;
      l_errmsg            VARCHAR2 (500);
      l_email_id          cms_cust_mast.ccm_email_one%TYPE;
      l_pendingrrn_count  NUMBER;
      l_concurrent_flag  NUMBER;
      l_orgnl_delivery_channel     transactionlog.delivery_channel%TYPE;
      l_orgnl_resp_code            transactionlog.response_code%TYPE;
      l_orgnl_terminal_id          transactionlog.terminal_id%TYPE;
      l_orgnl_txn_code             transactionlog.txn_code%TYPE;
      l_orgnl_txn_type             transactionlog.txn_type%TYPE;
      l_orgnl_txn_mode             transactionlog.txn_mode%TYPE;
      l_orgnl_business_date        transactionlog.business_date%TYPE;
      l_orgnl_business_time        transactionlog.business_time%TYPE;
      l_orgnl_customer_card_no     transactionlog.customer_card_no%TYPE;
      l_orgnl_total_amount         transactionlog.amount%TYPE;
      l_orgnl_txn_feecode          cms_fee_mast.cfm_fee_code%TYPE;
      l_orgnl_txn_feeattachtype    transactionlog.feeattachtype%TYPE;
      l_orgnl_txn_totalfee_amt     transactionlog.tranfee_amt%TYPE;
      l_orgnl_txn_servicetax_amt   transactionlog.servicetax_amt%TYPE;
      l_orgnl_txn_cess_amt         transactionlog.cess_amt%TYPE;
      l_orgnl_transaction_type     transactionlog.cr_dr_flag%TYPE;
      l_orgnl_trandate             DATE;
      l_rvsl_trandate              DATE;
      l_curr_code                  transactionlog.currencycode%TYPE;
      l_orgnl_termid               transactionlog.terminal_id%TYPE;
      l_orgnl_mcccode              transactionlog.mccode%TYPE;
      l_orgnl_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_orgnl_servicetax_amt       transactionlog.servicetax_amt%TYPE;
      l_orgnl_cess_amt             transactionlog.cess_amt%TYPE;
      l_orgnl_cr_dr_flag           transactionlog.cr_dr_flag%TYPE;
      l_orgnl_tranfee_cr_acctno    transactionlog.tranfee_cr_acctno%TYPE;
      l_orgnl_tranfee_dr_acctno    transactionlog.tranfee_dr_acctno%TYPE;
      l_orgnl_st_calc_flag         transactionlog.tran_st_calc_flag%TYPE;
      l_orgnl_cess_calc_flag       transactionlog.tran_cess_calc_flag%TYPE;
      l_orgnl_st_cr_acctno         transactionlog.tran_st_cr_acctno%TYPE;
      l_orgnl_st_dr_acctno         transactionlog.tran_st_dr_acctno%TYPE;
      l_orgnl_cess_cr_acctno       transactionlog.tran_cess_cr_acctno%TYPE;
      l_orgnl_cess_dr_acctno       transactionlog.tran_cess_dr_acctno%TYPE;
      l_orgnl_cardstatus           transactionlog.cardstatus%TYPE;
      l_gl_upd_flag                transactionlog.gl_upd_flag%TYPE;
      l_totpup_pan_hash            transactionlog.topup_card_no%TYPE;
      l_tran_reverse_flag          transactionlog.tran_reverse_flag%TYPE;
      l_actual_feecode             transactionlog.feecode%TYPE;
      l_add_ins_date               transactionlog.add_ins_date%TYPE;
      l_fee_narration              cms_statements_log.csl_trans_narrration%TYPE;
      l_txn_narration              cms_statements_log.csl_trans_narrration%TYPE;
      l_txn_flag                   cms_checkdeposit_transaction.cct_txn_flag%type;
      l_response_code              cms_checkdeposit_transaction.cct_response_code%type;
      l_response_desc              cms_checkdeposit_transaction.cct_response_desc%type;
      l_org_rrn                    cms_checkdeposit_transaction.cct_rrn%type;
      l_org_tran_amt                   cms_checkdeposit_transaction.cct_txn_amnt%type;
      l_act_date                   cms_checkdeposit_transaction.cct_act_date%type;
      l_act_time                   cms_checkdeposit_transaction.cct_act_time%type;
      l_tran_amt                   cms_acct_mast.cam_acct_bal%TYPE;
      l_tran_type                  VARCHAR2 (2);
      exp_reject_record            EXCEPTION;
      v_encrypt_enable             cms_prod_cattype.cpc_encrypt_enable%type;


   BEGIN
      BEGIN

         p_respmsg_out := 'success';
         l_tran_amt := NVL (ROUND (p_tran_amount_in, 2), 0);

    --Sn pan  and customer details
    BEGIN
        SELECT cap_pan_code, cap_pan_code_encr,cap_acct_no,
               cap_card_stat, cap_prod_code, cap_card_type,
               cap_expry_date, cap_active_date, cap_prfl_code,
               cap_proxy_number,cap_cust_code
          INTO l_hash_pan, l_encr_pan,l_acct_no,
               l_card_stat, l_prod_code, l_card_type,
               l_expry_date, l_active_date, l_prfl_code,
               l_proxynumber,l_cust_code
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code_in
           AND cap_pan_code = gethash (p_pan_code_in)
           AND cap_mbr_numb = '000';

       EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' || gethash(p_pan_code_in);
                 RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
             
         begin
               select cpc_encrypt_enable
               into v_encrypt_enable
               from cms_prod_cattype
               where cpc_inst_code=p_inst_code_in
               and cpc_prod_code=l_prod_code
               and cpc_card_type=l_card_type;
         exception
            when others then
                 p_resp_code_out := '12';
               l_errmsg :=
                   'Error in selecing prod cattype' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record; 
         end;


         -- Sn Transaction Details  procedure call
         BEGIN
            vmscommon.get_transaction_details (p_inst_code_in,
                                               p_delivery_channel_in,
                                               p_txn_code_in,
                                               l_cr_dr_flag,
                                               l_txn_type,
                                               l_txn_desc,
                                               l_prfl_flag,
                                               l_preauth_flag,
                                               l_login_txn,
                                               l_preauth_type,
                                               l_dup_rrn_check,
                                               p_resp_code_out,
                                               l_errmsg
                                              );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '12';
               l_errmsg :=
                  'Error from Transaction Details'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En Transaction Details  procedure call
              l_cr_dr_flag := 'DR';
         -- Sn validating Date Time RRN
         IF l_dup_rrn_check = 'Y' THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out
                                        );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                     'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         END IF;
         -- En validating Date Time RRN

         l_txn_desc := l_txn_desc || substr(p_rrn_in , 1, 5);
      
         if length(l_txn_desc)>50 then
         l_txn_desc := substr(l_txn_desc,1,50);
         end if;
       
      BEGIN
         SELECT decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_email),cam_email)
           INTO p_email_id_out
           FROM cms_addr_mast
          WHERE cam_inst_code = p_inst_code_in
            AND cam_cust_code = l_cust_code
            AND cam_addr_flag = 'P';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '89';
            l_errmsg := 'Email Id not found ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            l_errmsg :=
               'Problem while selecting Email Id '
               || SUBSTR (SQLERRM, 1, 300);
      END;
      
      BEGIN
      select CCT_TXN_FLAG,CCT_RESPONSE_CODE,CCT_TXN_AMNT,CCT_RRN,CCT_ACT_DATE,CCT_ACT_TIME 
      into l_txn_flag,l_response_code,l_ORG_TRAN_AMT,l_org_rrn,l_act_date,l_act_time
      from CMS_CHECKDEPOSIT_TRANSACTION 
      WHERE CCT_DELV_CHNL = p_delivery_channel_in
   --   and CCT_PARTNER_ID=p_partner_id_in
      and CCT_DEPOSIT_ID = p_deposit_id_in      
      AND CCT_INST_CODE = p_inst_code_in;
      if l_txn_flag ='3' then   --reversal already done  
         if p_delivery_channel_in = '13' then
         p_resp_code_out := '254';
         elsif p_delivery_channel_in = '10' then
         p_resp_code_out := '297';
         end if;
         l_errmsg :='Original already reversed';                               
         RAISE EXP_REJECT_RECORD;                       
       END IF;
       if l_txn_flag ='1' and l_response_code != '00' then --original trasnaction was declined
         if p_delivery_channel_in = '13' then
         p_resp_code_out := '253';
         elsif p_delivery_channel_in = '10' then
         p_resp_code_out := '296';
         end if;
         l_errmsg :='Original cannot be reversed'; 
         RAISE EXP_REJECT_RECORD; 
       END IF;                                  
     if l_tran_amt > l_org_tran_amt then
       p_resp_code_out := '37';
       l_errmsg   := 'Reversal amount exceeds the original transaction amount';
       RAISE EXP_REJECT_RECORD;
     END IF;
       EXCEPTION
       when NO_DATA_FOUND then
         if p_delivery_channel_in = '13' then
         p_resp_code_out := '255';
         elsif p_delivery_channel_in = '10' then
         p_resp_code_out := '298';
         end if;
         l_errmsg :='Original not found';                               
        RAISE EXP_REJECT_RECORD; 
       when EXP_REJECT_RECORD then
         RAISE;
       WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg :='Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      end;
      BEGIN
         SELECT delivery_channel, terminal_id,
                response_code, txn_code, txn_type,
                txn_mode, business_date,
                business_time, customer_card_no,
                amount, feecode,
                feeattachtype, tranfee_amt,
                servicetax_amt, cess_amt,
                cr_dr_flag, terminal_id, mccode,
                feecode, tranfee_amt,
                servicetax_amt, cess_amt,
                tranfee_cr_acctno, tranfee_dr_acctno,
                tran_st_calc_flag, tran_cess_calc_flag,
                tran_st_cr_acctno, tran_st_dr_acctno,
                tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
                tran_reverse_flag, gl_upd_flag, topup_card_no,
                cardstatus,add_ins_date 
           INTO l_orgnl_delivery_channel, l_orgnl_terminal_id,
                l_orgnl_resp_code, l_orgnl_txn_code, l_orgnl_txn_type,
                l_orgnl_txn_mode, l_orgnl_business_date,
                l_orgnl_business_time, l_orgnl_customer_card_no,
                l_orgnl_total_amount, l_orgnl_txn_feecode,
                l_orgnl_txn_feeattachtype, l_orgnl_txn_totalfee_amt,
                l_orgnl_txn_servicetax_amt, l_orgnl_txn_cess_amt,
                l_orgnl_transaction_type, l_orgnl_termid, l_orgnl_mcccode,
                l_actual_feecode, l_orgnl_tranfee_amt,
                l_orgnl_servicetax_amt, l_orgnl_cess_amt,
                l_orgnl_tranfee_cr_acctno, l_orgnl_tranfee_dr_acctno,
                l_orgnl_st_calc_flag, l_orgnl_cess_calc_flag,
                l_orgnl_st_cr_acctno, l_orgnl_st_dr_acctno,
                l_orgnl_cess_cr_acctno, l_orgnl_cess_dr_acctno, l_curr_code,
                l_tran_reverse_flag, l_gl_upd_flag, l_totpup_pan_hash,
                l_orgnl_cardstatus,l_add_ins_date
           FROM VMSCMS.TRANSACTIONLOG_VW                  --Added for VMS-5735/FSP-991
          WHERE rrn = l_org_rrn
            AND business_date = l_act_date
            AND business_time = l_act_time
            AND customer_card_no = l_hash_pan
            AND delivery_channel = p_delivery_channel_in
            AND instcode = p_inst_code_in
            AND response_code = '00';

         IF l_orgnl_resp_code <> '00'
         THEN
            p_resp_code_out := '23';
            l_errmsg := ' The original transaction was not successful';
            RAISE exp_reject_record;
         END IF;

         IF l_tran_reverse_flag = 'Y'
         THEN
            p_resp_code_out := '52';
            l_errmsg :=
                      'The reversal already done for the orginal transaction';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '53';
            l_errmsg := 'Matching transaction not found';
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'More than one matching record found in the master';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
               'Error while selecting master data'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      
      IF l_orgnl_customer_card_no <> l_hash_pan
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
            'Customer card number is not matching in reversal and orginal transaction';
         RAISE exp_reject_record;
      END IF;
      
       --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO l_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '21';                            -- Server Declined
            RAISE exp_reject_record;
      END;

      --En generate auth id
      
      BEGIN
         SELECT csl_trans_narrration
           INTO l_fee_narration
           FROM VMSCMS.CMS_STATEMENTS_LOG_VW              --Added for VMS-5735/FSP-991
          WHERE csl_business_date = l_act_date
            AND csl_business_time = l_act_time
            AND csl_rrn = l_org_rrn
            AND csl_delivery_channel = p_delivery_channel_in
            AND csl_txn_code = p_txn_code_in
            AND csl_pan_no = l_orgnl_customer_card_no
            AND csl_inst_code = p_inst_code_in
            AND txn_fee_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_fee_narration := NULL;
         WHEN OTHERS
         THEN
            l_fee_narration := NULL;
      END;
      
      BEGIN
         l_rvsl_trandate :=
            TO_DATE (   SUBSTR (TRIM (p_trandate_in), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_trantime_in), 1, 10),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Problem while converting V_RVSL_TRANDATE date '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      
       BEGIN
         sp_reverse_fee_amount (p_inst_code_in,
                                p_rrn_in,
                                p_delivery_channel_in,
                                l_orgnl_terminal_id,
                                NULL,                             --P_MERC_ID,
                                p_txn_code_in,
                                l_rvsl_trandate,
                                NULL,                           -- P_TXN_MODE,
                                l_orgnl_tranfee_amt,
                                p_pan_code_in,
                                l_actual_feecode,
                                l_orgnl_tranfee_amt,
                                l_orgnl_tranfee_cr_acctno,
                                l_orgnl_tranfee_dr_acctno,
                                l_orgnl_st_calc_flag,
                                l_orgnl_servicetax_amt,
                                l_orgnl_st_cr_acctno,
                                l_orgnl_st_dr_acctno,
                                l_orgnl_cess_calc_flag,
                                l_orgnl_cess_amt,
                                l_orgnl_cess_cr_acctno,
                                l_orgnl_cess_dr_acctno,
                                l_org_rrn,
                                l_acct_no,
                                p_trandate_in,
                                p_trantime_in,
                                l_auth_id,
                                l_fee_narration,
                                NULL,                          --MERCHANT_NAME
                                NULL,                          --MERCHANT_CITY
                                NULL,                         --MERCHANT_STATE
                                p_resp_code_out,
                                l_errmsg
                               );

         IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while reversing the fee amount '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      
       BEGIN
         SELECT csl_trans_narrration
           INTO l_txn_narration
           FROM VMSCMS.CMS_STATEMENTS_LOG_VW              --Added for VMS-5735/FSP-991
           WHERE csl_business_date = l_act_date
            AND csl_business_time = l_act_time
            AND csl_rrn = l_org_rrn
            AND csl_delivery_channel = p_delivery_channel_in
            AND csl_txn_code = p_txn_code_in
            AND csl_pan_no = l_orgnl_customer_card_no
            AND csl_inst_code = p_inst_code_in
            AND txn_fee_flag = 'N';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_txn_narration := NULL;
         WHEN OTHERS
         THEN
            l_txn_narration := NULL;
      END;
      
          
     BEGIN

          SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL,CAM_TYPE_CODE
          INTO   l_acct_bal,l_ledger_bal,l_acct_type
          FROM   CMS_ACCT_MAST
          WHERE  CAM_INST_CODE = p_inst_code_in
          AND    CAM_ACCT_NO = l_acct_no FOR UPDATE;

      EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' ;
        WHEN OTHERS
        THEN
           p_resp_code_out := '12';
           l_errmsg :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END; 
      
            
      BEGIN
        sp_autonomous_preauth_log(l_auth_id,p_deposit_id_in||'~'||p_partner_id_in, p_trandate_in, l_hash_pan, p_inst_code_in, p_delivery_channel_in , l_errmsg);
       --Added VMS-5551
       IF l_errmsg != 'OK' THEN
       p_resp_code_out     := '191';
       RAISE exp_reject_record;

        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        p_resp_code_out := '12';
        l_errmsg  := 'Concurrent check Failed' || SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      
      BEGIN
             UPDATE CMS_ACCT_MAST
             SET CAM_ACCT_BAL  = CAM_ACCT_BAL-l_tran_amt,
                 CAM_LEDGER_BAL =  CAM_LEDGER_BAL-l_tran_amt
                 WHERE CAM_INST_CODE = p_inst_code_in AND CAM_ACCT_NO = l_acct_no;

            IF SQL%ROWCOUNT = 0 THEN
             p_resp_code_out := '21';
             l_errmsg  := 'Account is not updated for reversal ' ;
             RAISE exp_reject_record;
            END IF;
            
        EXCEPTION
           when exp_reject_record then
           raise;
         WHEN OTHERS THEN
               p_resp_code_out := '21';
               l_errmsg  := 'Error while updating CMS_ACCT_MAST ' ||
                            SUBSTR(SQLERRM, 1, 250);
               RAISE exp_reject_record;
     END;
             
       BEGIN
          INSERT INTO cms_statements_log
                      (csl_pan_no, csl_opening_bal,
                       csl_trans_amount,
                       csl_trans_type, csl_trans_date,
                       csl_closing_balance,
                       csl_trans_narrration, csl_inst_code,
                       csl_pan_no_encr, csl_rrn, csl_auth_id,
                       CSL_BUSINESS_DATE, CSL_BUSINESS_TIME, TXN_FEE_FLAG,
                       csl_delivery_channel, csl_txn_code, csl_acct_no,
                       csl_ins_user, csl_ins_date,
                       csl_panno_last4digit,
                       csl_prod_code,csl_card_type, csl_acct_type,
                       csl_time_stamp
                      )
          VALUES      (l_hash_pan, l_ledger_bal,NVL (l_tran_amt, 0),'DR', sysdate,
                       l_ledger_bal - l_tran_amt,
                       'RVSL-' || l_TXN_NARRATION, p_inst_code_in,
                       l_encr_pan, p_rrn_in, l_auth_id,p_trandate_in, p_trantime_in, 'N',
                       p_delivery_channel_in, p_txn_code_in, l_acct_no,
                       1, SYSDATE,
                       (SUBSTR (p_pan_code_in,length (p_pan_code_in) - 3,length (p_pan_code_in))),
                       l_prod_code,l_card_type, l_acct_type,l_timestamp 
                      );
       EXCEPTION
          WHEN OTHERS THEN
             p_resp_code_out := '21';
             l_errmsg := 'Error while inserting into CMS_STATEMENTS_LOG 1.0-'|| SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
       END;
       
       BEGIN
         UPDATE cms_checkdeposit_transaction
            SET cct_txn_flag = '3',               
                cct_txn_amnt = l_tran_amt             
          WHERE cct_inst_code = p_inst_code_in
            and CCT_DELV_CHNL = p_delivery_channel_in
 --           and CCT_PARTNER_ID = p_partner_id_in
            and CCT_DEPOSIT_ID = p_deposit_id_in
            and CCT_RRN=l_org_rrn;
           
        if sql%ROWCOUNT = 0 then
           l_errmsg   := 'Error while Updating Check Deposit Transaction Reversal';
           p_resp_code_out := '21';
           RAISE exp_reject_record;
         END IF;
          EXCEPTION
       WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            l_errmsg :=
                  'Problem while updating the records into cms_checkdeposit_transaction table'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
            RAISE EXP_REJECT_RECORD;
      END;
     
     IF l_orgnl_tranfee_amt=0 AND l_actual_feecode IS NOT NULL THEN
        BEGIN
           vmsfee.fee_freecnt_reverse (l_acct_no, l_actual_feecode, l_errmsg);
        
           IF l_errmsg <> 'OK' THEN
              p_resp_code_out := '21';
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              p_resp_code_out := '21';
              l_errmsg :='Error while reversing freefee count-'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
      END IF;      
      
      IF l_prfl_code IS NOT NULL AND l_prfl_flag = 'Y'
         THEN
            BEGIN  
            
                BEGIN
                select TO_CHAR (DECODE (l_txn_type,  '0', 'N',  '1', 'F')) into l_tran_type from dual;     
                EXCEPTION
                 WHEN OTHERS
                 THEN
                   p_resp_code_out := '12';
                   l_errmsg :=
                   'Error in selecting tran type' || SUBSTR (SQLERRM, 1, 200);
                 END; 
                 
               pkg_limits_check.sp_limitcnt_rever_reset (p_inst_code_in,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         p_txn_code_in,
                                                         l_tran_type,
                                                         NULL,
                                                         NULL,
                                                         l_prfl_code,
                                                         l_tran_amt,
                                                         l_tran_amt,
                                                         p_delivery_channel_in,
                                                         l_hash_pan,
                                                         l_add_ins_date,
                                                         p_resp_code_out,
                                                         l_errmsg
                                                        );

               IF l_errmsg <> 'OK'
               then
                  p_resp_code_out :='21';
                  l_errmsg := 'From Procedure sp_limitcnt_reset' || l_errmsg;
                  RAISE EXP_REJECT_RECORD;
               END IF;
            EXCEPTION
               WHEN EXP_REJECT_RECORD
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                        'Error from Limit Reset Count Process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
            end;
         END IF;
  
     BEGIN

          SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL,CAM_TYPE_CODE
          INTO   l_acct_bal,l_ledger_bal,l_acct_type
          FROM   CMS_ACCT_MAST
          WHERE  CAM_INST_CODE = p_inst_code_in
          AND    CAM_ACCT_NO = l_acct_no;

      EXCEPTION
            WHEN NO_DATA_FOUND    THEN
                 p_resp_code_out := '21';
                 l_errmsg := 'Invalid Card number ' ;
        WHEN OTHERS
        THEN
           p_resp_code_out := '12';
           l_errmsg :=
                   'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END; 

     p_resp_code_out := '1';
     p_acct_bal_out:= l_acct_bal;
     
       EXCEPTION                                         --<<Main Exception>>--
         WHEN exp_reject_record
         THEN
            ROLLBACK;
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
       END;

        BEGIN
            SELECT cms_iso_respcde,CMS_RESP_DESC
              INTO p_resp_code_out,l_response_desc
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = TO_NUMBER (p_resp_code_out);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                     'Problem while selecting respose code'
                  || p_resp_code_out
                  || ' is-'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '69';
         END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_hashkey_id :=
            gethash (   p_delivery_channel_in
                     || p_txn_code_in
                     || l_hash_pan
                     || p_rrn_in
                     || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

     

      IF p_resp_code_out <> '00' THEN
          p_respmsg_out  := l_errmsg;
          
      END IF;
      
      BEGIN
      sp_autonomous_preauth_logclear(l_auth_id);
      exception
         When others then
           NULL;
      END;
  
     BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     p_rvsl_code_in,
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_card_type,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg
                                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;

END create_check_deposit_reversal;

PROCEDURE create_savings_account (
                                   p_inst_code_in                   IN       NUMBER,
                                   p_delivery_chnl_in               IN       VARCHAR2,
                                   p_txn_code_in                    IN       VARCHAR2,
                                   p_rrn_in                         IN       VARCHAR2,
                                  p_cust_id_in                     IN       VARCHAR2,
                                   p_appl_id_in                     IN       VARCHAR2,
                                   p_partner_id_in                  IN       VARCHAR2,
                                   p_tran_date_in                   IN       VARCHAR2,
                                   p_tran_time_in                   IN       VARCHAR2,
                                   p_curr_code_in                   IN       VARCHAR2,
                                   p_revrsl_code_in                 IN       VARCHAR2,  
                                   p_msg_type_in                    IN       VARCHAR2,
                                   p_ip_addr_in                     IN       VARCHAR2,
                                   p_ani_in                         IN       VARCHAR2,
                                   p_dni_in                         IN       VARCHAR2,
                                   p_device_mobno_in                IN       VARCHAR2,  
                                   p_device_id_in                   IN       VARCHAR2,  
                                   p_uuid_in                        IN       VARCHAR2,
                                   p_osname_in                      IN       VARCHAR2,
                                   p_osversion_in                   IN       VARCHAR2,
                                   p_gps_coordinates_in             IN       VARCHAR2,
                                   p_display_resolution_in          IN       VARCHAR2,
                                   p_physical_memory_in             IN       VARCHAR2,
                                   p_appname_in                     IN       VARCHAR2,
                                   p_appversion_in                  IN       VARCHAR2,
                                   p_sessionid_in                   IN       VARCHAR2,
                                   p_device_country_in              IN       VARCHAR2,
                                   p_device_region_in               IN       VARCHAR2,
                                   p_ipcountry_in                   IN       VARCHAR2,
                                   p_proxy_flag_in                  IN       VARCHAR2,
                                   p_pan_code_in                    IN       VARCHAR2,
                                   p_txn_amt                        IN       NUMBER,
								                   p_savacct_consent_flag_in        IN       VARCHAR2,
								                   p_savingsacct_no_out             OUT      VARCHAR2,
								                   p_spendingacct_no_out            OUT      VARCHAR2,
								                   p_savings_bal_out                OUT      VARCHAR2,               
                                   p_spending_bal_out               OUT      VARCHAR2,        
                                   p_spendingleg_bal_out            OUT      VARCHAR2, 							   
                                   p_resp_code_out                  OUT      VARCHAR2,
                                   p_resp_msg_out                   OUT      VARCHAR2,
                                   p_gprcard_flag_in                IN       VARCHAR2 DEFAULT 'N'
                                )
AS
   l_hash_pan                 cms_appl_pan.cap_pan_code%TYPE;
   l_encr_pan                 cms_appl_pan.cap_pan_code_encr%TYPE;
   l_acct_no                  cms_acct_mast.cam_acct_no%TYPE;
   l_acct_bal                 cms_acct_mast.cam_acct_bal%TYPE;
   l_ledger_bal               cms_acct_mast.cam_ledger_bal%TYPE;
   l_prod_code                cms_appl_pan.cap_prod_code%TYPE;
   l_prod_cattype             cms_appl_pan.cap_card_type%TYPE;
   l_card_stat                cms_appl_pan.cap_card_stat%TYPE;
   l_expry_date               cms_appl_pan.cap_expry_date%TYPE;
   l_active_date              cms_appl_pan.cap_expry_date%TYPE;
   l_prfl_code                cms_appl_pan.cap_prfl_code%TYPE;
   l_cr_dr_flag               cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_txn_type                 cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
   l_prfl_flag                cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_comb_hash                pkg_limits_check.type_hash;
   l_auth_id                  cms_transaction_log_dtl.ctd_auth_id%TYPE;
   l_timestamp                TIMESTAMP;
   l_preauth_flag             cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_dup_rrn_check            cms_transaction_mast.ctm_rrn_check%TYPE;
   l_acct_type                cms_acct_mast.cam_type_code%TYPE := 2;
   l_login_txn                cms_transaction_mast.ctm_login_txn%TYPE;
   l_fee_code                 cms_fee_mast.cfm_fee_code%TYPE;
   l_fee_plan                 cms_fee_feeplan.cff_fee_plan%TYPE;
   l_feeattach_type           transactionlog.feeattachtype%TYPE;
   l_tranfee_amt              transactionlog.tranfee_amt%TYPE;
   l_total_amt                cms_acct_mast.cam_acct_bal%TYPE;
   l_preauth_type             cms_transaction_mast.ctm_preauth_type%TYPE;
   l_hashkey_id               cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_proxynumber              cms_appl_pan.cap_proxy_number%TYPE;
   l_errmsg                   VARCHAR2 (500);
   l_appl_code                cms_appl_pan.cap_appl_code%type;
   l_cust_code                cms_appl_pan.cap_cust_code%TYPE;
   L_SAVING_ACCTNO            cms_acct_mast.cam_acct_no%TYPE;
   exp_reject_record          exception;
   l_max_svg_lmt              NUMBER;
   l_max_spend_amt            cms_dfg_param.cdp_param_key%TYPE;
   l_min_spend_amt            cms_dfg_param.cdp_param_key%TYPE;
   l_dfg_cnt           	      NUMBER(10); 
   l_switch_acct_stat  	      CMS_ACCT_STAT.CAS_SWITCH_STATCODE%TYPE DEFAULT '8';
   l_svng_acct_type  	      cms_acct_mast.cam_type_code%TYPE;
   l_acct_stat         	      CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
   l_txn_amt           	      cms_acct_mast.cam_acct_bal%TYPE;
   l_count             	      NUMBER;
   l_min_tran_amt      	      cms_acct_mast.cam_acct_bal%TYPE;
   l_branch_code       	      VARCHAR2(5);
   l_spnd_bal          	      CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
   l_acctid            	      CMS_ACCT_MAST.CAM_ACCT_ID%TYPE;
   l_trans_desc        	      CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
   l_narration                CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
   l_savings_acct_balance     cms_acct_mast.cam_acct_bal%TYPE;
   l_savings_ledger_balance   cms_acct_mast.cam_ledger_bal%TYPE;
   l_tran_date                DATE;
    
BEGIN
   BEGIN
      p_resp_msg_out := 'success';

      BEGIN
         vmscommon.get_transaction_details (p_inst_code_in,
                                            p_delivery_chnl_in,
                                            p_txn_code_in,
                                            l_cr_dr_flag,
                                            l_txn_type,
                                            l_txn_desc,
                                            l_prfl_flag,
                                            l_preauth_flag,
                                            l_login_txn,
                                            l_preauth_type,
                                            l_dup_rrn_check,
                                            p_resp_code_out,
                                            l_errmsg
                                           );

      IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
      THEN
          RAISE exp_reject_record;
      END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                 'Error from Transaction Details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no, cap_card_stat,
                cap_prod_code, cap_card_type, cap_expry_date,
                cap_active_date, cap_prfl_code, cap_proxy_number,
                cap_appl_code, cap_cust_code
           INTO l_hash_pan, l_encr_pan, l_acct_no, l_card_stat,
                l_prod_code, l_prod_cattype, l_expry_date,
                l_active_date, l_prfl_code, l_proxynumber,
                l_appl_code, l_cust_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            AND cap_mbr_numb = '000';
			
			
             p_spendingacct_no_out:= l_acct_no;
			
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while selecting CMS_APPL_PAN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF l_dup_rrn_check = 'Y' THEN
      BEGIN
         vmscommon.validate_date_rrn (p_inst_code_in,
                                      p_rrn_in,
                                      p_tran_date_in,
                                      p_tran_time_in,
                                      p_delivery_chnl_in,
                                      l_errmsg,
                                      p_resp_code_out
                                     );

      IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
      THEN
          RAISE exp_reject_record;
      END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '22';
            l_errmsg :=
                  'Error while validating DATE AND RRN'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      END IF;

--      BEGIN
--         vmscommon.authorize_nonfinancial_txn (p_inst_code_in,
--                                               p_msg_type_in,
--                                               p_rrn_in,
--                                               p_delivery_chnl_in,
--                                               p_txn_code_in,
--                                               0,
--                                               p_tran_date_in,
--                                               p_tran_time_in,
--                                               '00',
--                                               l_txn_type,
--                                               p_pan_code_in,
--                                               l_hash_pan,
--                                               l_encr_pan,
--                                               l_acct_no,
--                                               l_card_stat,
--                                               l_expry_date,
--                                               l_prod_code,
--                                               l_prod_cattype,
--                                               l_prfl_flag,
--                                               l_prfl_code,
--                                               l_txn_type,
--                                               p_curr_code_in,
--                                               l_preauth_flag,
--                                               l_txn_desc,
--                                               l_cr_dr_flag,
--                                               l_login_txn,
--                                               p_resp_code_out,
--                                               l_errmsg,
--                                               l_comb_hash,
--                                               l_auth_id,
--                                               l_fee_code,
--                                               l_fee_plan,
--                                               l_feeattach_type,
--                                               l_tranfee_amt,
--                                               l_total_amt,
--                                               l_preauth_type
--                                              );
--
--      IF l_errmsg <> 'OK'
--      THEN
--            RAISE exp_reject_record;
--      END IF;
--      EXCEPTION
--         WHEN exp_reject_record
--         THEN
--            RAISE;
--         WHEN OTHERS
--         THEN
--            p_resp_code_out := '21';
--            l_errmsg :=
--                  'ERROR FROM authorize_nonfinancial_txn '
--               || SUBSTR (SQLERRM, 1, 200);
--            RAISE exp_reject_record;
--      end;
         
          l_txn_amt := p_txn_amt;
           --St Get Branch code from pan code
         BEGIN
           SELECT SUBSTR(P_PAN_CODE_IN,7,4) INTO l_branch_code FROM DUAL;

            EXCEPTION
              WHEN OTHERS THEN
                 p_resp_code_out := '12';
                 l_errmsg :='Error while getting branch code from pan code '|| SUBSTR (SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
         END;
       --En Get Branch code from pan code          

           --Sn select acct stat
          BEGIN
           SELECT CAS_STAT_CODE
           INTO l_acct_stat
           FROM CMS_ACCT_STAT
           WHERE CAS_INST_CODE = p_inst_code_in AND
           CAS_SWITCH_STATCODE = l_switch_acct_stat;

           EXCEPTION
             WHEN NO_DATA_FOUND THEN
             p_resp_code_out := '21';
             l_errmsg := 'Acct stat not defined for  master';
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
             p_resp_code_out := '12';
             l_errmsg := 'Error while selecting accttype ' ||
                  SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
          END;
        --En select acct stat
        
        
        --Sn check whether the Saving Account already created or not
         BEGIN
           SELECT COUNT(1) INTO l_count FROM CMS_ACCT_MAST
           WHERE cam_acct_id in( SELECT cca_acct_id FROM CMS_CUST_ACCT
           where cca_cust_code=l_cust_code and cca_inst_code=p_inst_code_in) and cam_type_code=2
           AND CAM_INST_CODE=p_inst_code_in;

           IF l_count = 1 THEN
             l_errmsg := 'Savings Account already created';
             p_resp_code_out := '63';
             RAISE EXP_REJECT_RECORD;
           END IF;

           EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
                  RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
             p_resp_code_out := '12';
             l_errmsg := 'Error while selecting Savings Account count ' || SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;

         END;
      --En check whether the Saving Account already created or not
    
     
           IF p_gprcard_flag_in <> 'Y' THEN

     l_dfg_cnt:=0; 
       FOR i IN (SELECT cdp_param_value, cdp_param_key
                   FROM cms_dfg_param
                  WHERE cdp_param_key IN
                           ('InitialTransferAmount', 'MaxSavingParam',
                            'MaxSpendingParam', 'MinSpendingParam')
                    AND cdp_inst_code = p_inst_code_in
                    and cdp_prod_code = l_prod_code                
                    and CDP_CARD_TYPE = l_prod_cattype 
                    )
       LOOP
        IF i.cdp_param_key = 'InitialTransferAmount'
          THEN
             l_dfg_cnt:=l_dfg_cnt+1;
             l_min_tran_amt := i.cdp_param_value;

          ELSIF i.cdp_param_key = 'MaxSavingParam'
          THEN
             l_dfg_cnt:=l_dfg_cnt+1;
             l_max_svg_lmt := i.cdp_param_value;
          ELSIF i.cdp_param_key = 'MaxSpendingParam'
          THEN
             l_dfg_cnt:=l_dfg_cnt+1;
             l_max_spend_amt := i.cdp_param_value;
          ELSIF i.cdp_param_key = 'MinSpendingParam'
          THEN
             l_dfg_cnt:=l_dfg_cnt+1;
             l_min_spend_amt := i.cdp_param_value;
          END IF;
       END LOOP;


    
       IF l_dfg_cnt=0 THEN
          p_resp_code_out := '21';
          l_errmsg:='Saving account parameters is not defined for product '||l_prod_code;
          RAISE exp_reject_record;
       END IF;
     


       if l_min_tran_amt is null                            
       then

            p_resp_code_out := '21';
            l_errmsg := 'No data for selecting min Initial Tran amt for product code '||l_prod_code ||' and instcode '||p_inst_code_in||' '||p_resp_code_out;
            raise exp_reject_record;

       elsif l_max_svg_lmt is null
       then

            p_resp_code_out := '21';
            l_errmsg := 'No data for selecting max savings acct bal for product code '||l_prod_code ||' and instcode '||p_inst_code_in||' '||p_resp_code_out;
            raise exp_reject_record;

       elsif l_max_spend_amt is null
       then

            p_resp_code_out := '21';
            l_errmsg := 'No data for selecting max spending acct bal for product code '||l_prod_code ||' and instcode '||p_inst_code_in;
            raise exp_reject_record;

       elsif l_min_spend_amt is null
       then

            p_resp_code_out := '21';
            l_errmsg := 'No data for selecting min spending acct bal for product code '||l_prod_code ||' and instcode '||p_inst_code_in;
            raise exp_reject_record;

       end if;

    -- En get the dfg level initial transafer amount  param

     BEGIN

         SELECT CAM_ACCT_BAL
           INTO l_spnd_bal
           FROM CMS_ACCT_MAST
          WHERE CAM_ACCT_NO = l_acct_no
            AND CAM_INST_CODE=p_inst_code_in;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
         p_resp_code_out := '21';
         l_errmsg := 'No data for selecting spending  acc bal   '||p_resp_code_out;
        RAISE EXP_REJECT_RECORD;
         WHEN OTHERS
        THEN
         p_resp_code_out := '12';
         l_errmsg :=
               'Error while selecting spending  acc bal '
            || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;

     END;

        if l_txn_amt = 0 then
           l_txn_amt :=l_min_tran_amt;

        END IF;

    BEGIN
       IF  l_txn_amt < l_min_tran_amt
       THEN
           l_errmsg :=
                    'Transaction amount is less than the Initial Transfer Amount';
           p_resp_code_out := '151';
          RAISE exp_reject_record;
       ELSIF l_txn_amt < l_min_spend_amt
          THEN
             l_errmsg := 'Amount should not below the Minimum configured amount';
             p_resp_code_out := '103';
           RAISE exp_reject_record;
       ELSIF l_txn_amt > l_max_spend_amt
          THEN
             l_errmsg := 'Amount should not exceed the Maximum Transfer amount';
             p_resp_code_out := '150';
           RAISE exp_reject_record;
       ELSIF l_txn_amt > l_max_svg_lmt
          THEN
             l_errmsg :=
                   'Amount should not exceed the Maximum Savings Account Balance';
             p_resp_code_out := '104';
           RAISE exp_reject_record;
       ELSIF l_txn_amt > l_spnd_bal
          THEN
             l_errmsg := 'Insufficient funds to create savings account';
             p_resp_code_out := '152';
           RAISE exp_reject_record;
       END IF;
     EXCEPTION
          WHEN exp_reject_record
           THEN
          RAISE;
          WHEN OTHERS
           THEN
              p_resp_code_out := '12';
              l_errmsg :=
                'Error while Checking the transaction amount matched with the configured values '
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
  
  END IF;
  
  
   BEGIN
            vmscommon.authorize_financial_txn (p_inst_code_in,
                                                  p_msg_type_in,
                                                  p_rrn_in,
                                                  p_delivery_chnl_in,
                                                  null,   --p_terminal_id_in
                                                  p_txn_code_in,
                                                  0,
                                                  p_tran_date_in,
                                                  p_tran_time_in,
                                                  p_pan_code_in,
                                                  l_hash_pan,
                                                  l_encr_pan,
                                                  l_card_stat,
                                                  l_proxynumber,
                                                  l_acct_no,
                                                  l_expry_date,
                                                  l_prod_code,
                                                  l_prod_cattype,
                                                  l_prfl_flag,
                                                  l_prfl_code,
                                                  l_txn_type,
                                                  p_curr_code_in,
                                                  l_preauth_flag,
                                                  l_txn_desc,
                                                  l_cr_dr_flag,
                                                  l_login_txn,
                                                  null,  --ctm_amnt_transfer_flag
                                                  p_inst_code_in,
                                                  l_txn_amt,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  null,
                                                  p_revrsl_code_in,
                                           --       l_tran_amt,
                                                  null,
                                                  null,
                                                  p_ip_addr_in,
                                                  p_ani_in,
                                                  p_dni_in,
                                                  p_device_mobno_in,
                                                  p_device_id_in,
                                                  p_uuid_in,
                                                  p_osname_in,
                                                  p_osversion_in,
                                                  p_gps_coordinates_in,
                                                  p_display_resolution_in,
                                                  p_physical_memory_in,
                                                  p_appname_in,
                                                  p_appversion_in,
                                                  p_sessionid_in,
                                                  p_device_country_in,
                                                  p_device_region_in,
                                                  null,
                                                  l_auth_id,
                                                  p_resp_code_out,
                                                  l_errmsg
                                                  );
                                        
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
               p_resp_code_out := '21';
               l_errmsg :=
                     'Error from authorize_financial_txn '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         
     BEGIN

          SP_SAVINGS_ACCOUNT_CONSTRUCT(p_inst_code_in,
                      l_branch_code,
                      l_prod_code,
                      l_prod_cattype,  
                      L_SAVING_ACCTNO,
                      l_errmsg);
           IF l_errmsg <> 'OK' 
             THEN
                p_resp_code_out := '12';
                l_errmsg := 'Error from create savings acct construct ' || l_errmsg;
                RAISE EXP_REJECT_RECORD;
           END IF;
             EXCEPTION
                WHEN EXP_REJECT_RECORD
                THEN  
                RAISE EXP_REJECT_RECORD;   
                WHEN OTHERS THEN
                   p_resp_code_out := '12';
                   l_errmsg :='Error while creating account construct '|| SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

     END;
       --En Get Account Number

      --Sn Get Accout Id
      BEGIN
              SELECT SEQ_ACCT_ID.NEXTVAL
                INTO l_acctid
                FROM DUAL;
           EXCEPTION
              WHEN OTHERS  THEN
                 p_resp_code_out := '12';
                 l_errmsg :='Error while getting acctId from master'|| SUBSTR (SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;
      END;
      --End Get Account Id
      
          --Sn Transaction Time Check
    BEGIN
        L_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE_IN), 1, 8) || ' ' || SUBSTR(TRIM(P_TRAN_TIME_IN), 1, 10),'yyyymmdd hh24:mi:ss');
    EXCEPTION
        WHEN OTHERS THEN
            p_resp_code_out := '21';
            l_errmsg   := 'Problem while converting transaction Time ' || SUBSTR(SQLERRM, 1, 200);
            return;
    END;
    --En Transaction Time Check


          BEGIN
        L_SAVING_ACCTNO := TRIM(L_SAVING_ACCTNO);

        p_savingsacct_no_out :=L_SAVING_ACCTNO;

         INSERT INTO CMS_ACCT_MAST(CAM_INST_CODE,
                      CAM_ACCT_ID,
                      CAM_ACCT_NO,
                      CAM_HOLD_COUNT,
                      CAM_CURR_BRAN,
                      CAM_TYPE_CODE,
                      CAM_STAT_CODE,
                      CAM_CURR_LOYL,
                      CAM_UNCLAIMED_LOYL,
                      CAM_INS_DATE,
                      CAM_INS_USER,
                      CAM_LUPD_USER,
                      CAM_ACCT_BAL,
                      CAM_LEDGER_BAL,
                      CAM_ACCPT_DATE,
                      CAM_CREATION_DATE,
                      cam_savacct_consent_flag,
                      cam_acct_crea_tnfr_date, 
                      cam_prod_code,
                      cam_card_type
                      )
              VALUES( p_inst_code_in,
                      l_acctid,
                      L_SAVING_ACCTNO,
                      1,
                      l_branch_code,
                      l_acct_type,
                      l_acct_stat,
                      0,
                      0,
                      SYSDATE,
                      1,
                      1,
                      l_txn_amt,
                      l_txn_amt,
                      L_TRAN_DATE,
                      L_TRAN_DATE,
                      UPPER(p_savacct_consent_flag_in), 
                      sysdate,  
                      l_prod_code,
                      l_prod_cattype
                      );

          EXCEPTION
          WHEN OTHERS THEN
          p_resp_code_out := '12';
          l_errmsg := 'Exception in Acct mast for inserting Saving Account Number '||SQLCODE||'---'||SQLERRM;
          RAISE EXP_REJECT_RECORD;
        END;
      --En Inserting Saving Account Number in Acct Mast
      
      
      --Sn Inserting Saving Account Id in Cust Acct
        BEGIN

          INSERT INTO CMS_CUST_ACCT(CCA_INST_CODE,
                      CCA_ACCT_ID,
                      CCA_CUST_CODE,
                      CCA_HOLD_POSN,
                      CCA_REL_STAT,
                      CCA_INS_DATE,
                      CCA_INS_USER,
                      CCA_LUPD_USER,
                      CCA_LUPD_DATE)
                VALUES(p_inst_code_in,
                      l_acctid,
                      l_cust_code,
                      1,
                      'Y',
                      SYSDATE,
                      1,
                      1,
                      SYSDATE);
                p_resp_code_out := '1';
                p_resp_msg_out := L_SAVING_ACCTNO;
                l_errmsg := 'Saving Account Created';
            EXCEPTION
            WHEN OTHERS THEN
              p_resp_code_out := '12';
              l_errmsg := 'Exception in Cust Acct mast for inserting  Account Id '||SQLCODE||'---'||SQLERRM;
              RAISE EXP_REJECT_RECORD;

          END;
     --En Inserting Saving Account Id in Cust Acct
     
     --Sn Get Savings Acc Balance
          BEGIN
                 SELECT cam_acct_bal,
                        cam_ledger_bal,cam_type_code
                   INTO l_savings_acct_balance,
                        l_savings_ledger_balance,l_svng_acct_type 
                   FROM cms_acct_mast
                  WHERE cam_acct_no = L_SAVING_ACCTNO
                    AND cam_inst_code = p_inst_code_in;
              EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                        p_resp_code_out := '12';
                        l_errmsg :=
                               'No data for selecting savings acct balance '
                            || L_SAVING_ACCTNO;
                  RAISE exp_reject_record;
                   WHEN OTHERS
                      THEN
                         p_resp_code_out := '12';
                         l_errmsg :=
                               'Error while selecting savings acct balance '
                            || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
         END;
                   
                    IF l_txn_amt > 0 THEN
                   BEGIN

                      IF TRIM (l_trans_desc) IS NOT NULL
                      THEN
                         l_narration := l_trans_desc || '/';
                      END IF;

                      IF TRIM (l_auth_id) IS NOT NULL
                      THEN
                         l_narration := l_narration || l_auth_id || '/';
                      END IF;

                      IF TRIM (l_acct_no) IS NOT NULL
                      THEN
                         l_narration := l_narration || l_acct_no || '/';
                      END IF;

                      IF TRIM (p_tran_date_in) IS NOT NULL
                      THEN
                         l_narration := l_narration || p_tran_date_in;
                      END IF;
                   EXCEPTION
                      WHEN NO_DATA_FOUND
                      THEN
                         p_resp_code_out := '21';
                         l_errmsg :=
                               'No records founds while getting narration '
                            || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                      WHEN OTHERS
                      THEN
                         p_resp_code_out := '21';
                         l_errmsg :=
                                'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                   END;

                   BEGIN
                      l_cr_dr_flag := 'CR';
                      l_timestamp := systimestamp;   

                      INSERT INTO cms_statements_log
                                  (csl_pan_no, csl_acct_no,csl_opening_bal,
                                   csl_trans_amount, csl_trans_type, csl_trans_date,
                                   csl_closing_balance,
                                   csl_trans_narrration, csl_pan_no_encr, csl_rrn,
                                   csl_auth_id, csl_business_date, csl_business_time,
                                   txn_fee_flag, csl_delivery_channel, csl_inst_code,
                                   csl_txn_code, csl_ins_date, csl_ins_user,
                                   csl_panno_last4digit,
                                   csl_acct_type,          
                                   csl_time_stamp,         
                                   csl_prod_code,csl_card_type 
                                  )
                      VALUES      (l_hash_pan, L_SAVING_ACCTNO,0,
                                   l_txn_amt,
                                   'CR',l_tran_date,
                                   l_txn_amt,
                                   l_narration, l_encr_pan, p_rrn_in,
                                   l_auth_id, p_tran_date_in, p_tran_time_in,
                                   'N', p_delivery_chnl_in, p_inst_code_in,
                                   p_txn_code_in, SYSDATE,1,
                                   (SUBSTR (p_pan_code_in,
                                            LENGTH (p_pan_code_in) - 3,
                                            LENGTH (p_pan_code_in)
                                           )
                                   ),
                                   l_acct_type,
                                   l_timestamp,
                                   l_prod_code,l_prod_cattype                 
                                  );
                   EXCEPTION
                      WHEN OTHERS
                      THEN
                         p_resp_code_out := '21';
                         l_errmsg := 'Error creating entry in statement log '|| SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                   END;
                
                END IF;
             --En  Add a record in statements for TO ACCT(Savings)

              --Sn Get Spending Acc Balance
                   BEGIN
                      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
                      INTO l_acct_bal, l_ledger_bal, l_acct_type
                        FROM cms_acct_mast
                       WHERE cam_acct_no = l_acct_no
                        AND cam_inst_code = p_inst_code_in;

                   EXCEPTION
                      WHEN NO_DATA_FOUND
                      THEN
                         p_resp_code_out := '12';
                         l_errmsg :=
                                'No data for selecting spending acct balance ' || l_acct_no;
                         RAISE exp_reject_record;
                      WHEN OTHERS
                      THEN
                         p_resp_code_out := '12';
                         l_errmsg :=
                               'Error while selecting spending acct balance '
                            || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;
                   END;

                   p_savings_bal_out      :=  l_savings_acct_balance;
                   p_spending_bal_out     :=  l_acct_bal;
                   p_spendingleg_bal_out  :=  l_ledger_bal ;
                   p_resp_code_out := '1';
               
                   

  EXCEPTION                                            --<<Main Exception>>--
      WHEN exp_reject_record
      THEN
         ROLLBACK;
         p_resp_msg_out := l_errmsg;
      WHEN OTHERS
      THEN
         ROLLBACK;
         l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';      
         
    END;     
 
   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code_out
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code_in
         AND cms_delivery_channel = p_delivery_chnl_in
         AND cms_response_id = TO_NUMBER (p_resp_code_out);
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errmsg :=
               'Error while selecting respose code'
            || p_resp_code_out
            || ' is-'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '69';
   END;

   BEGIN
      l_hashkey_id :=
         gethash (   p_delivery_chnl_in
                  || p_txn_code_in
                  || p_pan_code_in
                  || p_rrn_in
                  || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
            'Error while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
   END;
  IF  p_resp_code_out <> '00' THEN   
     BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_chnl_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_tran_date_in,
                                     p_tran_time_in,
                                    '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_prod_cattype,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_osname_in,
                                     p_osversion_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_appname_in,
                                     p_appversion_in,
                                     p_sessionid_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ipcountry_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg
                                    ); 

         IF l_errmsg <> 'OK'
         THEN
          RAISE exp_reject_record;
         END IF;
         
         UPDATE TRANSACTIONLOG
          SET  topup_card_no = l_hash_pan,
               topup_card_no_encr = l_encr_pan,
               topup_acct_no = L_SAVING_ACCTNO,
               topup_acct_balance=l_savings_acct_balance,
               topup_ledger_balance=l_savings_ledger_balance,
               topup_acct_type=l_svng_acct_type
          WHERE RRN = p_rrn_in AND DELIVERY_CHANNEL = p_delivery_chnl_in AND
           TXN_CODE = p_txn_code_in AND BUSINESS_DATE = p_tran_date_in AND
           BUSINESS_TIME = p_tran_time_in AND  MSGTYPE = p_msg_type_in AND
           CUSTOMER_CARD_NO = l_hash_pan AND INSTCODE=p_inst_code_in;
		   
		   
        IF SQL%ROWCOUNT = 0 THEN                                          --Added for VMS-5735/FSP-991
		
		UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST                     --Added for VMS-5735/FSP-991
          SET  topup_card_no = l_hash_pan,
               topup_card_no_encr = l_encr_pan,
               topup_acct_no = L_SAVING_ACCTNO,
               topup_acct_balance=l_savings_acct_balance,
               topup_ledger_balance=l_savings_ledger_balance,
               topup_acct_type=l_svng_acct_type
          WHERE RRN = p_rrn_in AND DELIVERY_CHANNEL = p_delivery_chnl_in AND
           TXN_CODE = p_txn_code_in AND BUSINESS_DATE = p_tran_date_in AND
           BUSINESS_TIME = p_tran_time_in AND  MSGTYPE = p_msg_type_in AND
           CUSTOMER_CARD_NO = l_hash_pan AND INSTCODE=p_inst_code_in;
		END IF;
	 
	 
     EXCEPTION
         WHEN exp_reject_record
         THEN
            p_resp_code_out := '69';
            p_resp_msg_out := p_resp_msg_out || ' Error while inserting into transaction log  '
            || l_errmsg;
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_resp_msg_out := 'Error while inserting into transaction log '
            || SUBSTR (SQLERRM, 1, 300);
     END;
     END IF;
  
END create_savings_account;

PROCEDURE spending_to_savings (
   p_inst_code_in              IN       NUMBER,
   p_delivery_channel_in       IN       VARCHAR2,
   p_txn_code_in               IN       VARCHAR2,
   p_rrn_in                    IN       VARCHAR2,
   p_cust_id_in                IN       VARCHAR2,
   p_partner_id_in             IN       VARCHAR2,
   p_trandate_in               IN       VARCHAR2,
   p_trantime_in               IN       VARCHAR2,
   p_curr_code_in              IN       VARCHAR2,
   p_rvsl_code_in              IN       VARCHAR2,
   p_msg_type_in               IN       VARCHAR2,
   p_ip_addr_in                IN       VARCHAR2,
   p_ani_in                    IN       VARCHAR2,
   p_dni_in                    IN       VARCHAR2,
   p_device_mob_no_in          IN       VARCHAR2,
   p_device_id_in              IN       VARCHAR2,
   p_pan_code_in               IN       VARCHAR2,
   p_uuid_in                   IN       VARCHAR2,
   p_os_name_in                IN       VARCHAR2,
   p_os_version_in             IN       VARCHAR2,
   p_gps_coordinates_in        IN       VARCHAR2,
   p_display_resolution_in     IN       VARCHAR2,
   p_physical_memory_in        IN       VARCHAR2,
   p_app_name_in               IN       VARCHAR2,
   p_app_version_in            IN       VARCHAR2,
   p_session_id_in             IN       VARCHAR2,
   p_device_country_in         IN       VARCHAR2,
   p_device_region_in          IN       VARCHAR2,
   p_ip_country_in             IN       VARCHAR2,
   p_proxy_flag_in             IN       VARCHAR2,
   p_from_acct_type_in         IN       VARCHAR2,
   p_amount_in                 IN       NUMBER,
   p_tran_mode_in              IN       VARCHAR2,
   p_svgacct_closrflag_in      IN       VARCHAR2,
   p_comments_in               IN       VARCHAR2,
   p_resp_code_out             OUT      VARCHAR2,
   p_respmsg_out               OUT      VARCHAR2,
   p_completed_transfers_out   OUT      VARCHAR2,
   p_remaining_transfers_out   OUT      VARCHAR2,
   p_savings_acct_out          OUT      VARCHAR2,
   p_spending_acctbal_out      OUT      VARCHAR2,
   p_spending_acctlegbal_out   OUT      VARCHAR2
)
IS
   l_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   l_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   l_acct_no                cms_acct_mast.cam_acct_no%TYPE;
   l_acct_bal               cms_acct_mast.cam_acct_bal%TYPE;
   l_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
   l_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   l_prod_cattype           cms_appl_pan.cap_card_type%TYPE;
   l_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   l_expry_date             cms_appl_pan.cap_expry_date%TYPE;
   l_active_date            cms_appl_pan.cap_expry_date%TYPE;
   l_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
   l_cr_dr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_txn_type               cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
   l_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_dup_rrn_check          cms_transaction_mast.ctm_rrn_check%TYPE;
   l_comb_hash              pkg_limits_check.type_hash;
   l_auth_id                cms_transaction_log_dtl.ctd_auth_id%TYPE;
   l_timestamp              TIMESTAMP;
   l_preauth_flag           cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   l_acct_type              cms_acct_mast.cam_type_code%TYPE;
   l_login_txn              cms_transaction_mast.ctm_login_txn%TYPE;
   l_fee_code               cms_fee_mast.cfm_fee_code%TYPE;
   l_fee_plan               cms_fee_feeplan.cff_fee_plan%TYPE;
   l_feeattach_type         transactionlog.feeattachtype%TYPE;
   l_tranfee_amt            transactionlog.tranfee_amt%TYPE;
   l_total_amt              cms_acct_mast.cam_acct_bal%TYPE;
   l_preauth_type           cms_transaction_mast.ctm_preauth_type%TYPE;
   l_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_proxynumber            cms_appl_pan.cap_proxy_number%TYPE;
   l_repl_flag              cms_appl_pan.cap_repl_flag%TYPE;
   l_switch_acct_type       cms_acct_type.cat_switch_type%TYPE   DEFAULT '22';
   l_switch_spd_acct_type   cms_acct_type.cat_switch_type%TYPE   DEFAULT '11';
   l_switch_acct_stat       cms_acct_stat.cas_switch_statcode%TYPE
                                                                  DEFAULT '8';
   l_spd_acct_type          cms_acct_type.cat_type_code%TYPE;
   l_cust_code              cms_appl_pan.cap_cust_code%TYPE;
   l_savings_acct_no        cms_acct_mast.cam_acct_no%TYPE;
   l_svg_acct_stat          cms_acct_mast.cam_stat_code%TYPE;
   l_acct_stat              cms_acct_stat.cas_stat_code%TYPE;
   l_savings_acct_bal       cms_acct_mast.cam_acct_bal%TYPE;
   l_savings_led_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   l_min_spd_amt            cms_dfg_param.cdp_param_key%TYPE;
   l_max_spd_amt            cms_dfg_param.cdp_param_key%TYPE;
   l_max_svg_trns_limt      cms_dfg_param.cdp_param_key%TYPE;
   l_max_svg_lmt            cms_dfg_param.cdp_param_key%TYPE;
   l_spenacctbal            cms_acct_mast.cam_acct_bal%TYPE;
   l_spenacctledgbal        cms_acct_mast.cam_ledger_bal%TYPE;
   l_svgtospd_trans         NUMBER;
   l_narration              CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
   l_dfg_cnt                NUMBER (10);
   l_count                  NUMBER;
   l_tran_date              DATE;
   l_errmsg                 VARCHAR2 (500);
   exp_reject_record        EXCEPTION;
   l_savtospd_count         cms_acct_mast.cam_savtospd_tfer_count%TYPE;
   l_stan                   VARCHAR2 (20);
   l_capture_date           DATE;
   --Sn Getting DFG Parameters
   CURSOR c (
      p_prod_code   cms_prod_mast.cpm_prod_code%TYPE,
      p_card_type   cms_appl_pan.cap_card_type%TYPE
   )
   IS
      SELECT cdp_param_key, cdp_param_value
        FROM cms_dfg_param
       WHERE cdp_inst_code = p_inst_code_in
         AND cdp_prod_code = p_prod_code
         AND cdp_card_type = p_card_type;
--En Getting DFG Parameters
BEGIN
   BEGIN
      p_resp_code_out := '00';
      p_respmsg_out := 'success';

      --Sn pan details procedure call
      BEGIN
         SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no, cap_card_stat,
                cap_prod_code, cap_card_type, cap_expry_date,
                cap_active_date, cap_prfl_code, cap_proxy_number,
                cap_repl_flag, cap_cust_code
           INTO l_hash_pan, l_encr_pan, l_acct_no, l_card_stat,
                l_prod_code, l_prod_cattype, l_expry_date,
                l_active_date, l_prfl_code, l_proxynumber,
                l_repl_flag, l_cust_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            AND cap_mbr_numb = '000';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En pan details procedure call

      -- Sn Transaction Details  procedure call
      BEGIN
         vmscommon.get_transaction_details (p_inst_code_in,
                                            p_delivery_channel_in,
                                            p_txn_code_in,
                                            l_cr_dr_flag,
                                            l_txn_type,
                                            l_txn_desc,
                                            l_prfl_flag,
                                            l_preauth_flag,
                                            l_login_txn,
                                            l_preauth_type,
                                            l_dup_rrn_check,
                                            p_resp_code_out,
                                            l_errmsg
                                           );

         IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                 'Error from Transaction Details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      -- En Transaction Details  procedure call

      -- Sn validating Date Time RRN
      IF l_dup_rrn_check = 'Y'
      THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out
                                        );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                     'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      -- En validating Date Time RRN

      --Sn Get Tran date
      BEGIN
         l_tran_date :=
            TO_DATE (   SUBSTR (TRIM (p_trandate_in), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_trantime_in), 1, 8),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Problem while converting transaction date '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get Tran date

      --Sn select acct type(Savings)
      BEGIN
         SELECT cat_type_code
           INTO l_acct_type
           FROM cms_acct_type
          WHERE cat_inst_code = p_inst_code_in
            AND cat_switch_type = l_switch_acct_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Acct type not defined in master(Savings)';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting accttype(Savings) '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En select acct type(Savings)

      --Sn select acct type(Spending)
                BEGIN
                      SELECT cat_type_code
                      INTO l_spd_acct_type
                      FROM cms_acct_type
                      WHERE cat_inst_code = p_inst_code_in
                      AND cat_switch_type = l_switch_spd_acct_type;
                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      p_resp_code_out := '21';
                      l_errmsg := 'Acct type not defined in master(Spending)';
                      RAISE exp_reject_record;
                  WHEN OTHERS THEN
                      p_resp_code_out := '12';
                      l_errmsg :='Error while selecting accttype(Spending) '
                      || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record;
                  END; 
      --En select acct type(Spending)

      -- Sn Get Savings Acct number
      BEGIN
         SELECT cam_acct_no, cam_acct_bal, cam_ledger_bal,
                cam_stat_code, cam_savtospd_tfer_count
           INTO l_savings_acct_no, l_savings_acct_bal, l_savings_led_bal,
                l_svg_acct_stat, l_savtospd_count
           FROM cms_acct_mast
          WHERE cam_acct_id IN (
                   SELECT cca_acct_id
                     FROM cms_cust_acct
                    WHERE cca_cust_code = l_cust_code
                      AND cca_inst_code = p_inst_code_in)
            AND cam_type_code = l_acct_type
            AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '105';
            l_errmsg := 'Savings Acc not created for this card';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting savings acc number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN Get Savings Acct number

      --Sn Check the Savings Account Number
      BEGIN
         SELECT COUNT (1)
           INTO l_count
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code_in
            AND cam_acct_no = l_savings_acct_no
            AND cam_type_code = l_acct_type;

         IF l_count = 0
         THEN
            p_resp_code_out := '109';
            l_errmsg :=
                       'Invalid Savings Account Number ' || l_savings_acct_no;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Problem while selecting Savings Account Number Card Detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Check the Savings Account Number

      --Sn check valid Savings acc number
                /*  IF l_savings_acct_no <> l_acct_no
                  THEN
                      p_resp_code_out := '109';
                      l_errmsg := 'Invalid Savings Account Number '||l_acct_no;
                      RAISE exp_reject_record;
                  END IF; */
      --En check valid Savings acc number

      --Sn Get Account Status(Savings)
      BEGIN
         SELECT cas_stat_code
           INTO l_acct_stat
           FROM cms_acct_stat
          WHERE cas_inst_code = p_inst_code_in
            AND cas_switch_statcode = l_switch_acct_stat;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Account Status not defind for Savings acc';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting savings acc status '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get Account Status(Savings)

      --Sn checks valid acc status
      IF l_acct_stat <> l_svg_acct_stat
      THEN
         p_resp_code_out := '106';
         l_errmsg := 'Savings account already closed';
         RAISE exp_reject_record;
      END IF;

      --En checks valid acc status
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO l_acct_bal, l_ledger_bal
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code_in AND cam_acct_no = l_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card /Account ';
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                       'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      --Sn Get the DFG paramers
      l_dfg_cnt := 0;

      BEGIN
         FOR i IN c (l_prod_code, l_prod_cattype)
         LOOP
            BEGIN
               IF i.cdp_param_key = 'MinSpendingParam'
               THEN
                  l_dfg_cnt := l_dfg_cnt + 1;
                  l_min_spd_amt := i.cdp_param_value;
               ELSIF i.cdp_param_key = 'MaxSpendingParam'
               THEN
                  l_dfg_cnt := l_dfg_cnt + 1;
                  l_max_spd_amt := i.cdp_param_value;
               ELSIF i.cdp_param_key = 'MaxSavingParam'
               THEN
                  l_dfg_cnt := l_dfg_cnt + 1;
                  l_max_svg_lmt := i.cdp_param_value;
               ELSIF i.cdp_param_key = 'MaxNoTrans'
               THEN
                  l_dfg_cnt := l_dfg_cnt + 1;
                  l_max_svg_trns_limt := i.cdp_param_value;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                        'Error while selecting saving account parameters '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END LOOP;

         IF l_dfg_cnt = 0
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'saving account parameters is not defined for product '
               || l_prod_code;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Error IN CURSOR 1 ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get the DFG paramers
      IF l_min_spd_amt IS NULL
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
               'No data for selecting min spnding amt for product code '
            || l_prod_code
            || ' and instcode '
            || p_inst_code_in;
         RAISE exp_reject_record;
      ELSIF l_max_spd_amt IS NULL
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
               'No data for selecting max spending amt for product code '
            || l_prod_code
            || ' and instcode '
            || p_inst_code_in;
         RAISE exp_reject_record;
      ELSIF l_max_svg_lmt IS NULL
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
               'No data for selecting max saving amt for product code '
            || l_prod_code
            || ' and instcode '
            || p_inst_code_in;
         RAISE exp_reject_record;
      ELSIF l_max_svg_trns_limt IS NULL
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
               'No data for selecting max spending trans limit for product code '
            || l_prod_code
            || ' and instcode '
            || p_inst_code_in;
         RAISE exp_reject_record;
      END IF;

      --Sn Checks validation
      IF p_amount_in = 0
      THEN
         p_resp_code_out := '25';
         l_errmsg := 'INVALID AMOUNT ';
         RAISE exp_reject_record;
      END IF;

      IF l_acct_bal < p_amount_in
      THEN
         p_resp_code_out := '15';
         l_errmsg := 'Insufficient Balance ';
         RAISE exp_reject_record;
      END IF;

      IF p_amount_in > l_max_spd_amt
      THEN
         IF p_delivery_channel_in = '03'
         THEN
            p_resp_code_out := '218';
         ELSE
            p_resp_code_out := '150';
         END IF;

         l_errmsg := 'Amount should not exceed the Maximum  Transfer amount' || p_amount_in || 'l_max_spd_amt' || l_max_spd_amt;
         RAISE exp_reject_record;
      END IF;

      IF p_amount_in < l_min_spd_amt
      THEN
         p_resp_code_out := '103';
         l_errmsg := 'Amount should not below the Minimum configured amount';
         RAISE exp_reject_record;
      END IF;

      IF (l_savings_acct_bal + p_amount_in) > l_max_svg_lmt
      THEN
         p_resp_code_out := '104';
         l_errmsg := 'Amount should not exceed the Maximum configured amount';
         RAISE exp_reject_record;
      END IF;

      --En Checks validation

      --SN : CMSAUTH check
      BEGIN
--         vmscommon.authorize_financial_txn (p_inst_code_in,
--                                     p_msg_type_in,
--                                     p_rrn_in,
--                                     p_delivery_channel_in,
--                                     NULL,                      --terminal  id
--                                     p_txn_code_in,         --transaction code
--                                     NULL,                  --transaction mode
--                                     p_trandate_in,
--                                     p_trantime_in,
--                                     p_pan_code_in,              --card number
--                                     l_hash_pan,                    --hash pan
--                                     l_encr_pan,              --encryption pan
--                                     l_card_stat,                --card status
--                                     l_proxynumber,             --proxy number
--                                     l_acct_no,               --account number
--                                     l_expry_date,               --expiry date
--                                     l_prod_code,                  --prod code
--                                     l_prod_cattype,               --card type
--                                     l_prfl_flag,               --profile flag
--                                     l_prfl_code,               --profile code
--                                     l_txn_type,                    --txn type
--                                     p_curr_code_in,           --currnecy code
--                                     l_preauth_flag,            --preauth flag
--                                     l_txn_desc,                   --tran desc
--                                     l_cr_dr_flag,                --cr dr flag
--                                     l_login_txn,                 --log in txn
--                                     NULL,              --amount transfer flag
--                                     NULL,                      --bank code in
--                                     p_amount_in,      --transaction amount in
--                                     NULL,                     --merchant name
--                                     NULL,                     --merchant city
--                                     NULL,                          --MCC code
--                                     NULL,                        --Tip amount
--                                     NULL,                 --to account number
--                                     NULL,                 --atm name location
--                                     NULL,                      --mcc group id
--                                     NULL,            --currency code group id
--                                     NULL,               --trans code group id
--                                     NULL,                          --rules in
--                                     NULL,                      --preauth date
--                                     NULL,                    --consodium code
--                                     NULL,                      --partner code
--                                     NULL,                              --stan
--                                     p_rvsl_code_in,           --reversal code
--                                     NULL,              --current convert amnt
--                                     NULL,                          --fee flag
--                                     NULL,                        --admin flag
--                                     p_ip_addr_in,               --ip address,
--                                     p_ani_in,                           --ani
--                                     p_dni_in,                          --dni,
--                                     p_device_mob_no_in,  --device mob number,
--                                     p_device_id_in,              --device id,
--                                     p_uuid_in,                         --uuid
--                                     p_os_name_in,                   --os name
--                                     p_os_version_in,             --os version
--                                     p_gps_coordinates_in,
--                                     p_display_resolution_in,
--                                     p_physical_memory_in,
--                                     p_app_name_in,
--                                     p_app_version_in,
--                                     p_session_id_in,
--                                     p_device_country_in,
--                                     p_device_region_in,
--                                     p_comments_in,
--                                     l_auth_id,                       --output
--                                     p_resp_code_out,                 --output
--                                     l_errmsg                         --output
--                                    );



 sp_authorize_txn_cms_auth (p_inst_code_in,
                                 p_msg_type_in,
                                 p_rrn_in,
                                 p_delivery_channel_in,
                                 null,--v_term_id,
                                 p_txn_code_in,
                                 p_tran_mode_in,
                                 p_trandate_in,
                                 p_trantime_in,
                                 p_pan_code_in,
                                 null,--p_bank_code,
                                 p_amount_in,
                                 NULL,
                                 NULL,
                                 null,--v_mcc_code,
                                 p_curr_code_in,
                                 NULL,
                                 NULL,
                                 NULL,
                                l_acct_no,-- l_savings_acct_no,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 l_expry_date,
                                 l_stan,
                                 '000',
                                 p_rvsl_code_in,
                                 p_amount_in,
                                 l_auth_id,
                                 p_resp_code_out,
                                 l_errmsg,
                                 l_capture_date
                                );

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
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error from authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN : CMSAUTH check
 Begin
      SELECT cam_acct_bal,
             cam_ledger_bal
       INTO  l_savings_acct_bal, l_savings_led_bal
        FROM cms_acct_mast
       WHERE cam_acct_no = l_savings_acct_no
         AND cam_type_code = l_acct_type
         AND cam_inst_code = p_inst_code_in;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '12';
         l_errmsg := 'Data not available for savings acc number 1'
            || l_savings_acct_no;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '12';
         l_errmsg :=
               'Error while selecting savings acc number 1'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --En Get Savings Acc number
     --Sn Get Spending Acc Balance
   BEGIN
      SELECT cam_acct_bal,
             cam_ledger_bal
        INTO l_acct_bal, l_ledger_bal
        FROM cms_acct_mast
       WHERE cam_acct_no = l_acct_no
         AND cam_type_code = l_spd_acct_type
         AND cam_inst_code = p_inst_code_in;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '12';
         l_errmsg :='No data for selecting spending acc number ' || l_acct_no;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '12';
         l_errmsg :='Error while selecting spending acc number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
        Begin
                UPDATE transactionlog  SET 
                uuid=p_uuid_in,
                os_name=p_os_name_in, 
                os_version=p_os_version_in, 
                gps_coordinates=p_gps_coordinates_in, 
                display_resolution=p_display_resolution_in, 
                physical_memory=p_physical_memory_in, 
                app_name=p_app_name_in, 
                app_version=p_app_version_in, 
                session_id=p_session_id_in, 
                device_country=p_device_country_in, 
                device_region=p_device_region_in, 
                ip_country=p_ip_country_in, 
                proxy_flag=p_proxy_flag_in, 
                REQ_PARTNER_ID=p_partner_id_in,
                 remark=p_comments_in,  
                topup_card_no = l_hash_pan,
                topup_card_no_encr = l_encr_pan,
             topup_acct_no =l_savings_acct_no,
             topup_acct_balance=l_savings_acct_bal,
             topup_ledger_balance=l_savings_led_bal,
             topup_acct_type =l_acct_type,
              acct_balance =l_acct_bal ,
              ledger_balance =l_ledger_bal ,
             add_lupd_date = SYSDATE,
             add_lupd_user = 1,
             customer_acct_no =l_acct_no,
            -- error_msg = v_errmsg,  
             acct_type =  l_spd_acct_type --l_acct_type  
                WHERE rrn  = p_rrn_in AND business_date= p_trandate_in
                                          AND business_time =p_trantime_in
                AND delivery_channel=p_delivery_channel_in AND txn_code =p_txn_code_in AND INSTCODE=p_inst_code_in  AND MSGTYPE =p_msg_type_in;
				
				 --Added for VMS-5735/FSP-991
            IF SQL%ROWCOUNT = 0 THEN                                      --Added for VMS-5735/FSP-991
			
			 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST  SET 
                uuid=p_uuid_in,
                os_name=p_os_name_in, 
                os_version=p_os_version_in, 
                gps_coordinates=p_gps_coordinates_in, 
                display_resolution=p_display_resolution_in, 
                physical_memory=p_physical_memory_in, 
                app_name=p_app_name_in, 
                app_version=p_app_version_in, 
                session_id=p_session_id_in, 
                device_country=p_device_country_in, 
                device_region=p_device_region_in, 
                ip_country=p_ip_country_in, 
                proxy_flag=p_proxy_flag_in, 
                REQ_PARTNER_ID=p_partner_id_in,
                 remark=p_comments_in,  
                topup_card_no = l_hash_pan,
                topup_card_no_encr = l_encr_pan,
             topup_acct_no =l_savings_acct_no,
             topup_acct_balance=l_savings_acct_bal,
             topup_ledger_balance=l_savings_led_bal,
             topup_acct_type =l_acct_type,
              acct_balance =l_acct_bal ,
              ledger_balance =l_ledger_bal ,
             add_lupd_date = SYSDATE,
             add_lupd_user = 1,
             customer_acct_no =l_acct_no,
            -- error_msg = v_errmsg,  
             acct_type =  l_spd_acct_type --l_acct_type  
                WHERE rrn  = p_rrn_in AND business_date= p_trandate_in
                                          AND business_time =p_trantime_in
                AND delivery_channel=p_delivery_channel_in AND txn_code =p_txn_code_in AND INSTCODE=p_inst_code_in  AND MSGTYPE =p_msg_type_in;
			END IF;
                
                IF SQL%ROWCOUNT = 0
                 THEN
                    p_resp_code_out := '21';
                    l_errmsg := 'Error while updating transactionlog';
                    RAISE exp_reject_record;
                 END IF;
        exception
            when exp_reject_record then
                raise;
            when others then
                 p_resp_code_out := '21';
                    l_errmsg :=
                          'Error while updating transactionlog '
                       || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
        end;

      --Sn Update the Amount To acct no(Savings)
      BEGIN
         UPDATE cms_acct_mast
            SET cam_acct_bal = cam_acct_bal + p_amount_in,
                cam_ledger_bal = cam_ledger_bal + p_amount_in,
                cam_lupd_date = SYSDATE,
                cam_lupd_user = 1,
                cam_acct_crea_tnfr_date = SYSDATE
          WHERE cam_inst_code = p_inst_code_in
            AND cam_acct_no = l_savings_acct_no
            AND cam_type_code = l_acct_type;

         IF SQL%ROWCOUNT = 0
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Error while updating amount in to acct no(Savings) ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while updating amount in to acct no(Savings) '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Update the Amount To acct no(Savings)

      ---Sn  Add a record in statements  for TO ACCT (Savings)
      BEGIN
         IF TRIM (l_trans_desc) IS NOT NULL
         THEN
            l_narration := l_trans_desc || '/';
         END IF;

         IF TRIM (l_auth_id) IS NOT NULL
         THEN
            l_narration := l_narration || l_auth_id || '/';
         END IF;

         IF TRIM (l_acct_no) IS NOT NULL
         THEN
            l_narration := l_narration || l_acct_no || '/';
         END IF;

         IF TRIM (p_trandate_in) IS NOT NULL
         THEN
            l_narration := l_narration || p_trandate_in;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_cr_dr_flag := 'CR';

         INSERT INTO cms_statements_log
                     (csl_pan_no, csl_acct_no, csl_opening_bal,
                      csl_trans_amount, csl_trans_type, csl_trans_date,
                      csl_closing_balance,
                      csl_trans_narrration, csl_pan_no_encr, csl_rrn,
                      csl_auth_id, csl_business_date, csl_business_time,
                      txn_fee_flag, csl_delivery_channel, csl_inst_code,
                      csl_txn_code, csl_ins_date,
                      csl_panno_last4digit,
                      csl_acct_type, csl_prod_code, csl_card_type,
                      csl_time_stamp
                     )
              VALUES (l_hash_pan, l_savings_acct_no, l_savings_led_bal,
                      NVL (p_amount_in, 0), 'CR', l_tran_date,
                      DECODE (l_cr_dr_flag,
                              'DR', l_savings_led_bal - p_amount_in,
                              'CR', l_savings_led_bal + p_amount_in,
                              'NA', l_savings_led_bal
                             ),
                      l_narration, l_encr_pan, p_rrn_in,
                      l_auth_id, p_trandate_in, p_trantime_in,
                      'N', p_delivery_channel_in, p_inst_code_in,
                      p_txn_code_in, SYSDATE,
                      (SUBSTR (p_pan_code_in,
                               LENGTH (p_pan_code_in) - 3,
                               LENGTH (p_pan_code_in)
                              )
                      ),
                      l_acct_type, l_prod_code, l_prod_cattype,
                      l_timestamp
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error creating entry in statement log '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      /*  BEGIN
          sp_daily_bin_bal (p_pan_code_in,
                            l_tran_date,
                            p_amount_in,
                            l_cr_dr_flag,
                            p_inst_code_in,
                            p_inst_code_in,
                            l_errmsg
                           );

          IF l_errmsg <> 'OK'
          THEN
             p_resp_code_out := '21';
             l_errmsg := 'Error while executing daily_bin log ';
             RAISE exp_reject_record;
          END IF;
       EXCEPTION
          WHEN exp_reject_record
          THEN
             RAISE exp_reject_record;
          WHEN OTHERS
          THEN
             p_resp_code_out := '21';
             l_errmsg := 'Error creating entry in daily_bin log '|| SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
       END; */
      --En  Add a record in statements for TO ACCT(Savings)
         
       BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO l_acct_bal, l_ledger_bal
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code_in AND cam_acct_no = l_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card /Account ';
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                       'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;
         
       BEGIN
         SELECT     cam_ledger_bal,cam_savtospd_tfer_count
           INTO   l_savings_led_bal, l_savtospd_count
           FROM cms_acct_mast
          WHERE cam_acct_no = l_savings_acct_no
            AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '105';
            l_errmsg := 'Savings Acc not created for this card';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting savings acc number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      p_remaining_transfers_out := l_max_svg_trns_limt - l_savtospd_count;
      p_completed_transfers_out := l_savtospd_count;
      p_savings_acct_out :=
                    TRIM (TO_CHAR (l_savings_led_bal, '99999999999999990.99'));
      p_spending_acctbal_out :=
                           TRIM (TO_CHAR (l_acct_bal, '99999999999999990.99'));
      p_spending_acctlegbal_out :=
                         TRIM (TO_CHAR (l_ledger_bal, '99999999999999990.99'));
      p_resp_code_out := '1';
   EXCEPTION                                            --<<Main Exception>>--
      WHEN exp_reject_record
      THEN
         ROLLBACK;
      WHEN OTHERS
      THEN
         ROLLBACK;
         l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
   END;

   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code_out
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code_in
         AND cms_delivery_channel = p_delivery_channel_in
         AND cms_response_id = TO_NUMBER (p_resp_code_out);
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errmsg :=
               'Problem while selecting respose code'
            || p_resp_code_out
            || ' is-'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '69';
   END;

   BEGIN
      l_hashkey_id :=
         gethash (   p_delivery_channel_in
                  || p_txn_code_in
                  || p_pan_code_in
                  || p_rrn_in
                  || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
            'Error while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
   END;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO l_acct_bal, l_ledger_bal, l_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code_in AND cam_acct_no = l_acct_no;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '21';
         l_errmsg := 'Invalid Card /Account ';
      WHEN OTHERS
      THEN
         p_resp_code_out := '12';
         l_errmsg := 'Error in account details' || SUBSTR (SQLERRM, 1, 200);
   END;

   IF p_resp_code_out <> '00'
   THEN
      p_respmsg_out := l_errmsg;

      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_prod_cattype,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg);
       if l_errmsg<>'OK' then
            p_respmsg_out := l_errmsg;
       end if;  
       
             update transactionlog
      set remark=p_comments_in
      where rrn=p_rrn_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   END IF;
END spending_to_savings;

PROCEDURE savings_to_spending (
   p_inst_code_in              IN       NUMBER,
   p_delivery_channel_in       IN       VARCHAR2,
   p_txn_code_in               IN       VARCHAR2,
   p_rrn_in                    IN       VARCHAR2,
   p_cust_id_in                IN       VARCHAR2,
   p_partner_id_in             IN       VARCHAR2,
   p_trandate_in               IN       VARCHAR2,
   p_trantime_in               IN       VARCHAR2,
   p_curr_code_in              IN       VARCHAR2,
   p_rvsl_code_in              IN       VARCHAR2,
   p_msg_type_in               IN       VARCHAR2,
   p_ip_addr_in                IN       VARCHAR2,
   p_ani_in                    IN       VARCHAR2,
   p_dni_in                    IN       VARCHAR2,
   p_device_mob_no_in          IN       VARCHAR2,
   p_device_id_in              IN       VARCHAR2,
   p_uuid_in                   IN       VARCHAR2,
   p_os_name_in                IN       VARCHAR2,
   p_os_version_in             IN       VARCHAR2,
   p_gps_coordinates_in        IN       VARCHAR2,
   p_display_resolution_in     IN       VARCHAR2,
   p_physical_memory_in        IN       VARCHAR2,
   p_app_name_in               IN       VARCHAR2,
   p_app_version_in            IN       VARCHAR2,
   p_session_id_in             IN       VARCHAR2,
   p_device_country_in         IN       VARCHAR2,
   p_device_region_in          IN       VARCHAR2,
   p_ip_country_in             IN       VARCHAR2,
   p_proxy_flag_in             IN       VARCHAR2,
   p_pan_code_in               IN       VARCHAR2,
   p_amount_in                 IN       VARCHAR2,
   p_tran_mode_in                 IN       VARCHAR2,
   p_comments_in               IN       VARCHAR2,
   p_resp_code_out             OUT      VARCHAR2,
   p_respmsg_out               OUT      VARCHAR2,
   p_completed_transfers_out   OUT      VARCHAR2,
   p_remaining_transfers_out   OUT      VARCHAR2,
   p_savings_acct_out          OUT      VARCHAR2,
   p_spending_acctbal_out      OUT      VARCHAR2,
   p_spending_acctlegbal_out   OUT      VARCHAR2
)
IS
   l_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   l_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   l_acct_no                cms_acct_mast.cam_acct_no%TYPE;
   l_acct_bal               cms_acct_mast.cam_acct_bal%TYPE;
   l_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
   l_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   l_prod_cattype           cms_appl_pan.cap_card_type%TYPE;
   l_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   l_expry_date             cms_appl_pan.cap_expry_date%TYPE;
   l_active_date            cms_appl_pan.cap_expry_date%TYPE;
   l_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
   l_cr_dr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_txn_type               cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
   l_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_dup_rrn_check          cms_transaction_mast.ctm_rrn_check%TYPE;
   l_comb_hash              pkg_limits_check.type_hash;
   l_auth_id                cms_transaction_log_dtl.ctd_auth_id%TYPE;
   l_timestamp              TIMESTAMP;
   l_preauth_flag           cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   l_acct_type              cms_acct_mast.cam_type_code%TYPE;
   l_login_txn              cms_transaction_mast.ctm_login_txn%TYPE;
   l_fee_code               cms_fee_mast.cfm_fee_code%TYPE;
   l_fee_plan               cms_fee_feeplan.cff_fee_plan%TYPE;
   l_feeattach_type         transactionlog.feeattachtype%TYPE;
   l_tranfee_amt            transactionlog.tranfee_amt%TYPE;
   l_total_amt              cms_acct_mast.cam_acct_bal%TYPE;
   l_preauth_type           cms_transaction_mast.ctm_preauth_type%TYPE;
   l_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_proxynumber            cms_appl_pan.cap_proxy_number%TYPE;
   l_repl_flag              cms_appl_pan.cap_repl_flag%TYPE;
   l_switch_acct_type       cms_acct_type.cat_switch_type%TYPE   DEFAULT '22';
   l_switch_spd_acct_type   cms_acct_type.cat_switch_type%TYPE   DEFAULT '11';
   l_switch_acct_stat       cms_acct_stat.cas_switch_statcode%TYPE
                                                                  DEFAULT '8';
   l_spd_acct_type          cms_acct_type.cat_type_code%TYPE;
   l_cust_code              cms_appl_pan.cap_cust_code%TYPE;
   l_savings_acct_no        cms_acct_mast.cam_acct_no%TYPE;
   l_svg_acct_stat          cms_acct_mast.cam_stat_code%TYPE;
   l_acct_stat              cms_acct_stat.cas_stat_code%TYPE;
   l_savings_acct_bal       cms_acct_mast.cam_acct_bal%TYPE;
   l_savings_led_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   l_min_svg_amt            cms_dfg_param.cdp_param_key%TYPE;
   l_max_svg_trns_limt      cms_dfg_param.cdp_param_key%TYPE;
   l_spenacctbal            cms_acct_mast.cam_acct_bal%TYPE;
   l_spenacctledgbal        cms_acct_mast.cam_ledger_bal%TYPE;
   l_svgtospd_trans         NUMBER;
   l_narration              CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
   l_dfg_cnt                NUMBER (10);
   l_count                  NUMBER;
   l_tran_date              DATE;
   l_errmsg                 VARCHAR2 (500);
   exp_reject_record        EXCEPTION;
   l_stan                   VARCHAR2 (20);
   l_capture_date           DATE;
--Sn Getting DFG Parameters
   CURSOR c (
      p_prod_code   cms_prod_mast.cpm_prod_code%TYPE,
      p_card_type   cms_appl_pan.cap_card_type%TYPE
   )
   IS
      SELECT cdp_param_key, cdp_param_value
        FROM cms_dfg_param
       WHERE cdp_inst_code = p_inst_code_in
         AND cdp_prod_code = p_prod_code
         AND cdp_card_type = p_card_type
         AND cdp_param_key IN ('MinSavingParam', 'MaxNoTrans');
--En Getting DFG Parameters
BEGIN
   BEGIN
      p_resp_code_out := '00';
      p_respmsg_out := 'success';

      --Sn pan details procedure call
      BEGIN
         SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no, cap_card_stat,
                cap_prod_code, cap_card_type, cap_expry_date,
                cap_active_date, cap_prfl_code, cap_proxy_number,
                cap_repl_flag, cap_cust_code
           INTO l_hash_pan, l_encr_pan, l_acct_no, l_card_stat,
                l_prod_code, l_prod_cattype, l_expry_date,
                l_active_date, l_prfl_code, l_proxynumber,
                l_repl_flag, l_cust_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            AND cap_mbr_numb = '000';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En pan details procedure call

      -- Sn Transaction Details  procedure call
      BEGIN
         vmscommon.get_transaction_details (p_inst_code_in,
                                            p_delivery_channel_in,
                                            p_txn_code_in,
                                            l_cr_dr_flag,
                                            l_txn_type,
                                            l_txn_desc,
                                            l_prfl_flag,
                                            l_preauth_flag,
                                            l_login_txn,
                                            l_preauth_type,
                                            l_dup_rrn_check,
                                            p_resp_code_out,
                                            l_errmsg
                                           );

         IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                 'Error from Transaction Details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      -- En Transaction Details  procedure call

      -- Sn validating Date Time RRN
      IF l_dup_rrn_check = 'Y'
      THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out
                                        );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                     'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      -- En validating Date Time RRN

      --Sn Get Tran date
      BEGIN
         l_tran_date :=
            TO_DATE (   SUBSTR (TRIM (p_trandate_in), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_trantime_in), 1, 8),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Problem while converting transaction date '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get Tran date

      --Sn select acct type(Savings)
      BEGIN
         SELECT cat_type_code
           INTO l_acct_type
           FROM cms_acct_type
          WHERE cat_inst_code = p_inst_code_in
            AND cat_switch_type = l_switch_acct_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Acct type not defined in master(Savings)';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting accttype(Savings) '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En select acct type(Savings)

      --Sn select acct type(Spending)
                   BEGIN
                       SELECT cat_type_code
                       INTO l_spd_acct_type
                       FROM cms_acct_type
                       WHERE cat_inst_code = p_inst_code_in
                       AND cat_switch_type = l_switch_spd_acct_type;
                   EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                       p_resp_code_out := '21';
                       l_errmsg := 'Acct type not defined in master(Spending)';
                       RAISE exp_reject_record;
                   WHEN OTHERS THEN
                       p_resp_code_out := '12';
                       l_errmsg :='Error while selecting accttype(Spending) '
                       || SUBSTR (SQLERRM, 1, 200);
                       RAISE exp_reject_record;
                   END;
       --En select acct type(Spending) 

      -- Sn Get Savings Acct number
      BEGIN
         SELECT cam_acct_no, cam_acct_bal, cam_ledger_bal,
                cam_stat_code
           INTO l_savings_acct_no, l_savings_acct_bal, l_savings_led_bal,
                l_svg_acct_stat
           FROM cms_acct_mast
          WHERE cam_acct_id IN (
                   SELECT cca_acct_id
                     FROM cms_cust_acct
                    WHERE cca_cust_code = l_cust_code
                      AND cca_inst_code = p_inst_code_in)
            AND cam_type_code = l_acct_type
            AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '105';
            l_errmsg := 'Savings Acc not created for this card';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting savings acc number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN Get Savings Acct number

      --Sn Check the Savings Account Number

      /*  BEGIN
            SELECT COUNT (1)
            INTO l_count
            FROM cms_acct_mast
            WHERE cam_inst_code = p_inst_code_in
            AND cam_acct_no = l_savings_acct_no
            AND cam_type_code = l_acct_type;

            IF l_count = 0
            THEN
            p_resp_code_out := '109';
            l_errmsg := 'Invalid Savings Account Number '||l_savings_acct_no;
            RAISE exp_reject_record;
            END IF;
        EXCEPTION
        WHEN exp_reject_record THEN
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          p_resp_code_out := '12';
          l_errmsg :=
          'Problem while selecting Savings Account Number Card Detail'
          || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END; */

      --En Check the Savings Account Number

      --Sn check valid Savings acc number
                  /*IF l_savings_acct_no <> l_acct_no
                  THEN
                      p_resp_code_out := '109';
                      l_errmsg := 'Invalid Savings Account Number '||l_acct_no;
                      RAISE exp_reject_record;
                  END IF;*/
      --En check valid Savings acc number

      --Sn Get Account Status(Savings)
      BEGIN
         SELECT cas_stat_code
           INTO l_acct_stat
           FROM cms_acct_stat
          WHERE cas_inst_code = p_inst_code_in
            AND cas_switch_statcode = l_switch_acct_stat;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Account Status not defind for Savings acc';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting savings acc status '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get Account Status(Savings)

      --Sn checks valid acc status
      IF l_acct_stat <> l_svg_acct_stat
      THEN
         p_resp_code_out := '106';
         l_errmsg := 'Savings account already closed';
         RAISE exp_reject_record;
      END IF;

      --En checks valid acc status
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal                 --, Cam_Type_Code
           INTO l_acct_bal, l_ledger_bal                       --, l_acct_type
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code_in AND cam_acct_no = l_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card /Account ';
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                       'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      --Sn call to SP_SAVTOSPD_LIMIT_CHECK procedure
      BEGIN
         sp_savtospd_limit_check (p_inst_code_in,
                                  p_delivery_channel_in,
                                  p_txn_code_in,
                                  l_hash_pan,
                                  l_savings_acct_no,
                                  l_acct_type,
                                  l_tran_date,
                                  p_trantime_in,
                                  p_resp_code_out,
                                  l_errmsg,
                                  l_svgtospd_trans
                                 );

         IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error from Saving account limit check'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En call to SP_SAVTOSPD_LIMIT_CHECK procedure

      --Sn Get the DFG paramers
      l_dfg_cnt := 0;

      BEGIN
         FOR i IN c (l_prod_code, l_prod_cattype)
         LOOP
            BEGIN
               IF i.cdp_param_key = 'MinSavingParam'
               THEN
                  l_dfg_cnt := l_dfg_cnt + 1;
                  l_min_svg_amt := i.cdp_param_value;
               ELSIF i.cdp_param_key = 'MaxNoTrans'
               THEN
                  l_dfg_cnt := l_dfg_cnt + 1;
                  l_max_svg_trns_limt := i.cdp_param_value;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_errmsg :=
                        'Error while selecting Saving account parameters '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END LOOP;

         IF l_dfg_cnt = 0
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Saving account parameters is not defined for product '
               || l_prod_code;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while opening cursor C ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get the DFG paramers
      IF l_min_svg_amt IS NULL
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
               'No data for selecting min Savings amt for product code '
            || l_prod_code
            || ' and instcode '
            || p_inst_code_in;
         RAISE exp_reject_record;
      ELSIF l_max_svg_trns_limt IS NULL
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
               'No data for selecting max savings tran limit for product code '
            || l_prod_code
            || ' and instcode '
            || p_inst_code_in;
         RAISE exp_reject_record;
      END IF;

      --Sn Checks validation
      IF p_amount_in = 0
      THEN
         p_resp_code_out := '25';
         l_errmsg := 'INVALID AMOUNT ';
         RAISE exp_reject_record;
      END IF;

      IF l_savings_acct_bal < p_amount_in
      THEN
         p_resp_code_out := '15';
         l_errmsg := 'Insufficient Balance';
         RAISE exp_reject_record;
      END IF;

      IF NOT (   (p_delivery_channel_in = '07' AND p_txn_code_in = '21')
              OR (p_delivery_channel_in = '10' AND p_txn_code_in = '40')
              OR (p_delivery_channel_in = '13' AND p_txn_code_in = '12')
             )
      THEN
         IF p_amount_in < l_min_svg_amt
         THEN
            p_resp_code_out := '103';                --Ineligible Transaction
            l_errmsg :=
                      'Amount should not below the Minimum configured amount';
            RAISE exp_reject_record;
         END IF;

         -- IF p_delivery_channel_in IN ('10','13') AND (l_svgtospd_trans+1=l_max_svg_trns_limt) THEN
         --   IF p_from_acct_type_in = 'SAVINGS' THEN
         --     IF p_svgacct_closrflag_in ='TRUE' THEN
         --       l_svgacctclosr := 'Y';
         --     ELSE
         IF     p_delivery_channel_in IN ('10', '13')
            AND (l_svgtospd_trans + 1 = l_max_svg_trns_limt)
         THEN
            p_resp_code_out := '260';
            l_errmsg := 'Saving Account Closure Confirmation required';
            RAISE exp_reject_record;
            --END IF;
         --- END IF;
         END IF;

         IF l_svgtospd_trans >= l_max_svg_trns_limt
         THEN
            p_resp_code_out := '111';
            l_errmsg := 'Maximum number of transactions exceeded for a month';
            RAISE exp_reject_record;
         END IF;
      END IF;

      --En Checks validation
      --SN : CMSAUTH check
      BEGIN
--         vmscommon.authorize_financial_txn (p_inst_code_in,
--                                     p_msg_type_in,
--                                     p_rrn_in,
--                                     p_delivery_channel_in,
--                                     NULL,                      --terminal  id
--                                     p_txn_code_in,         --transaction code
--                                     p_tran_mode_in,                  --transaction mode
--                                     p_trandate_in,
--                                     p_trantime_in,
--                                     p_pan_code_in,              --card number
--                                     l_hash_pan,                    --hash pan
--                                     l_encr_pan,              --encryption pan
--                                     l_card_stat,                --card status
--                                     l_proxynumber,             --proxy number
--                                     l_savings_acct_no,              --account number
--                                     l_expry_date,               --expiry date
--                                     l_prod_code,                  --prod code
--                                     l_prod_cattype,               --card type
--                                     l_prfl_flag,               --profile flag
--                                     l_prfl_code,               --profile code
--                                     l_txn_type,                    --txn type
--                                     p_curr_code_in,           --currnecy code
--                                     l_preauth_flag,            --preauth flag
--                                     l_txn_desc,                   --tran desc
--                                     l_cr_dr_flag,                --cr dr flag
--                                     l_login_txn,                 --log in txn
--                                     NULL,              --amount transfer flag
--                                     NULL,                      --bank code in
--                                     p_amount_in,      --transaction amount in
--                                     NULL,                     --merchant name
--                                     NULL,                     --merchant city
--                                     NULL,                          --MCC code
--                                     NULL,                        --Tip amount
--                                     l_acct_no,                 --to account number
--                                     NULL,                 --atm name location
--                                     NULL,                      --mcc group id
--                                     NULL,            --currency code group id
--                                     NULL,               --trans code group id
--                                     NULL,                          --rules in
--                                     NULL,                      --preauth date
--                                     NULL,                    --consodium code
--                                     NULL,                      --partner code
--                                     NULL,                              --stan
--                                     p_rvsl_code_in,           --reversal code
--                                     NULL,              --current convert amnt
--                                     NULL,                          --fee flag
--                                     NULL,                       --admin flag,
--                                     p_ip_addr_in,               --ip address,
--                                     p_ani_in,                           --ani
--                                     p_dni_in,                          --dni,
--                                     p_device_mob_no_in,  --device mob number,
--                                     p_device_id_in,              --device id,
--                                     p_uuid_in,                         --uuid
--                                     p_os_name_in,                   --os name
--                                     p_os_version_in,             --os version
--                                     p_gps_coordinates_in,
--                                     p_display_resolution_in,
--                                     p_physical_memory_in,
--                                     p_app_name_in,
--                                     p_app_version_in,
--                                     p_session_id_in,
--                                     p_device_country_in,
--                                     p_device_region_in,
--                                     p_comments_in,
--                                     l_auth_id,                       --output
--                                     p_resp_code_out,                 --output
--                                     l_errmsg                         --output
--                                    );

 

 sp_authorize_txn_cms_auth (p_inst_code_in,
                                 p_msg_type_in,
                                 p_rrn_in,
                                 p_delivery_channel_in,
                                 null,--v_term_id,
                                 p_txn_code_in,
                                 p_tran_mode_in,
                                 p_trandate_in,
                                 p_trantime_in,
                                 p_pan_code_in,
                                 null,--p_bank_code,
                                 p_amount_in,
                                 NULL,
                                 NULL,
                                 null,--v_mcc_code,
                                 p_curr_code_in,
                                 NULL,
                                 NULL,
                                 NULL,
                                 l_savings_acct_no,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 l_expry_date,
                                 l_stan,
                                 '000',
                                 p_rvsl_code_in,
                                 p_amount_in,
                                 l_auth_id,
                                 p_resp_code_out,
                                 l_errmsg,
                                 l_capture_date
                                );

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
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error from authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN : CMSAUTH check
 Begin
      SELECT cam_acct_bal,
             cam_ledger_bal
       INTO  l_savings_acct_bal, l_savings_led_bal
        FROM cms_acct_mast
       WHERE cam_acct_no = l_savings_acct_no
         AND cam_type_code = l_acct_type
         AND cam_inst_code = p_inst_code_in;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '12';
         l_errmsg := 'Data not available for savings acc number 1'
            || l_savings_acct_no;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '12';
         l_errmsg :=
               'Error while selecting savings acc number 1'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --En Get Savings Acc number
     --Sn Get Spending Acc Balance
   BEGIN
      SELECT cam_acct_bal,
             cam_ledger_bal
        INTO l_acct_bal, l_ledger_bal
        FROM cms_acct_mast
       WHERE cam_acct_no = l_acct_no
         AND cam_type_code = l_spd_acct_type
         AND cam_inst_code = p_inst_code_in;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '12';
         l_errmsg :='No data for selecting spending acc number ' || l_acct_no;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '12';
         l_errmsg :='Error while selecting spending acc number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --En Get Spending Acc Balance
 Begin
                  UPDATE transactionlog  SET 
                uuid=p_uuid_in,
                os_name=p_os_name_in, 
                os_version=p_os_version_in, 
                gps_coordinates=p_gps_coordinates_in, 
                display_resolution=p_display_resolution_in, 
                physical_memory=p_physical_memory_in, 
                app_name=p_app_name_in, 
                app_version=p_app_version_in, 
                session_id=p_session_id_in, 
                device_country=p_device_country_in, 
                device_region=p_device_region_in, 
                ip_country=p_ip_country_in, 
                proxy_flag=p_proxy_flag_in, 
                REQ_PARTNER_ID=p_partner_id_in,
                remark=p_comments_in,  
                topup_card_no = l_hash_pan,
                topup_card_no_encr = l_encr_pan,
             topup_acct_no = l_acct_no,
             topup_acct_balance=l_acct_bal,
             topup_ledger_balance=l_ledger_bal,
             topup_acct_type = l_spd_acct_type,
              acct_balance = l_savings_acct_bal,
              ledger_balance = l_savings_led_bal,
             add_lupd_date = SYSDATE,
             add_lupd_user = 1,
             customer_acct_no = l_savings_acct_no,
            -- error_msg = v_errmsg,  
             acct_type = l_acct_type  
                WHERE rrn  = p_rrn_in AND business_date= p_trandate_in
                                          AND business_time =p_trantime_in
                AND delivery_channel=p_delivery_channel_in AND txn_code =p_txn_code_in AND INSTCODE=p_inst_code_in  AND MSGTYPE =p_msg_type_in;
        
		 
        IF SQL%ROWCOUNT = 0 THEN                                                       --Added for VMS-5735/FSP-991
		
		     UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST  SET                        --Added for VMS-5735/FSP-991
                uuid=p_uuid_in,
                os_name=p_os_name_in, 
                os_version=p_os_version_in, 
                gps_coordinates=p_gps_coordinates_in, 
                display_resolution=p_display_resolution_in, 
                physical_memory=p_physical_memory_in, 
                app_name=p_app_name_in, 
                app_version=p_app_version_in, 
                session_id=p_session_id_in, 
                device_country=p_device_country_in, 
                device_region=p_device_region_in, 
                ip_country=p_ip_country_in, 
                proxy_flag=p_proxy_flag_in, 
                REQ_PARTNER_ID=p_partner_id_in,
                remark=p_comments_in,  
                topup_card_no = l_hash_pan,
                topup_card_no_encr = l_encr_pan,
             topup_acct_no = l_acct_no,
             topup_acct_balance=l_acct_bal,
             topup_ledger_balance=l_ledger_bal,
             topup_acct_type = l_spd_acct_type,
              acct_balance = l_savings_acct_bal,
              ledger_balance = l_savings_led_bal,
             add_lupd_date = SYSDATE,
             add_lupd_user = 1,
             customer_acct_no = l_savings_acct_no,
            -- error_msg = v_errmsg,  
             acct_type = l_acct_type  
                WHERE rrn  = p_rrn_in AND business_date= p_trandate_in
                                          AND business_time =p_trantime_in
                AND delivery_channel=p_delivery_channel_in AND txn_code =p_txn_code_in AND INSTCODE=p_inst_code_in  AND MSGTYPE =p_msg_type_in;
        
		END IF;
                IF SQL%ROWCOUNT = 0
                 THEN
                    p_resp_code_out := '21';
                    l_errmsg := 'Error while updating transactionlog';
                    RAISE exp_reject_record;
                 END IF;
        exception
            when exp_reject_record then
                raise;
            when others then
                 p_resp_code_out := '21';
                    l_errmsg :=
                          'Error while updating transactionlog '
                       || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
        end;

      --Sn Update the Amount To acct no(Savings)
      BEGIN
         UPDATE cms_acct_mast
            SET cam_acct_bal = cam_acct_bal - p_amount_in,
                cam_ledger_bal = cam_ledger_bal - p_amount_in,
                cam_lupd_date = SYSDATE,
                cam_lupd_user = 1,
                cam_savtospd_tfer_count =
                   DECODE (p_delivery_channel_in || p_txn_code_in,
                           '0547', l_svgtospd_trans,
                           l_svgtospd_trans + 1
                          ),
                cam_acct_crea_tnfr_date = SYSDATE
          WHERE cam_inst_code = p_inst_code_in
            AND cam_acct_no = l_savings_acct_no
            AND cam_type_code = l_acct_type;

         IF SQL%ROWCOUNT = 0
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Error while updating amount in to acct no(Savings) ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while updating amount in to acct no(Savings) '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Update the Amount To acct no(Savings)

      ---Sn  Add a record in statements for TO ACCT (Savings)
      BEGIN
         IF TRIM (l_trans_desc) IS NOT NULL
         THEN
            l_narration := l_trans_desc || '/';
         END IF;

         IF TRIM (l_auth_id) IS NOT NULL
         THEN
            l_narration := l_narration || l_auth_id || '/';
         END IF;

         IF TRIM (l_acct_no) IS NOT NULL
         THEN
            l_narration := l_narration || l_acct_no || '/';
         END IF;

         IF TRIM (p_trandate_in) IS NOT NULL
         THEN
            l_narration := l_narration || p_trandate_in;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_cr_dr_flag := 'DR';

         INSERT INTO cms_statements_log
                     (csl_pan_no, csl_acct_no, csl_opening_bal,
                      csl_trans_amount, csl_trans_type, csl_trans_date,
                      csl_closing_balance,
                      csl_trans_narrration, csl_pan_no_encr, csl_rrn,
                      csl_auth_id, csl_business_date, csl_business_time,
                      txn_fee_flag, csl_delivery_channel, csl_inst_code,
                      csl_txn_code, csl_ins_date, csl_ins_user,
                      csl_panno_last4digit,
                      csl_to_acctno, csl_acct_type, csl_prod_code,
                      csl_card_type, csl_time_stamp
                     )
              VALUES (l_hash_pan, l_savings_acct_no, l_savings_led_bal,
                      p_amount_in, 'DR', l_tran_date,
                      DECODE (l_cr_dr_flag,
                              'DR', l_savings_led_bal - p_amount_in,
                              'CR', l_savings_led_bal + p_amount_in,
                              'NA', l_savings_led_bal
                             ),
                      l_narration, l_encr_pan, p_rrn_in,
                      l_auth_id, p_trandate_in, p_trantime_in,
                      'N', p_delivery_channel_in, p_inst_code_in,
                      p_txn_code_in, SYSDATE, 1,
                      (SUBSTR (p_pan_code_in,
                               LENGTH (p_pan_code_in) - 3,
                               LENGTH (p_pan_code_in)
                              )
                      ),
                      NULL,                                   --p_spd_acct_no,
                           l_acct_type, l_prod_code,
                      l_prod_cattype, l_timestamp
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Error creating entry in statement log ';
            RAISE exp_reject_record;
      END;

      -- SN calling procedure sp_daily_bin_bal
           /* BEGIN
                sp_daily_bin_bal (p_pan_code_in,
                                  l_tran_date,
                                  p_amount_in,
                                  l_cr_dr_flag,
                                  p_inst_code_in,
                                  p_inst_code_in,
                                  l_errmsg
                                  );

                IF l_errmsg <> 'OK'
                THEN
                  p_resp_code_out := '21';
                  l_errmsg := 'Error while executing daily_bin log ';
                  RAISE exp_reject_record;
                END IF;
            EXCEPTION
            WHEN exp_reject_record
            THEN
                RAISE exp_reject_record;
            WHEN OTHERS
            THEN
              p_resp_code_out := '21';
              l_errmsg := 'Error creating entry in daily_bin log ';
              RAISE exp_reject_record;
            END; */
                   -- EN calling procedure sp_daily_bin_bal

      --Sn Get Savings Acc bal after updation
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO l_savings_acct_bal, l_savings_led_bal
           FROM cms_acct_mast
          WHERE cam_acct_no = l_savings_acct_no
            AND cam_type_code = l_acct_type
            AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Data not available for savings acc number 1'
               || l_savings_acct_no;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting savings acc number 1'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get Savings Acc bal

      --Sn Get Spending Acc Balance
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO l_acct_bal, l_ledger_bal
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_no
                                       -- AND cam_type_code = l_spd_acct_type
                AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                    'No data for selecting spending acc number ' || l_acct_no;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting spending acc number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get Spending Acc Balance

      --Sn Append respcode
      l_svgtospd_trans := l_svgtospd_trans + 1;
      p_completed_transfers_out := l_svgtospd_trans;
      p_remaining_transfers_out := l_max_svg_trns_limt - l_svgtospd_trans;
      /*p_savings_acct_out :=
                'SELECT (l_svgtospd_trans) l_completed_transfers ,
                        (l_max_svg_trns_limt - l_svgtospd_trans) l_remaining_transfers,
                         TRIM (TO_CHAR (l_savings_led_bal, ''99999999999999990.99'')) l_sacctledgbal
                  FROM DUAL'; */
      p_savings_acct_out :=
                    TRIM (TO_CHAR (l_savings_led_bal, '99999999999999990.99'));
      p_resp_code_out := '1';
      --l_errmsg := TRIM (TO_CHAR (l_savings_acct_bal, '99999999999999990.99'));
      l_errmsg := 'Funds Transferred Successfully';
      /*p_spending_acct_out :=
                 '(SELECT TRIM (TO_CHAR (l_acct_bal, ''99999999999999990.99'')) l_spenacctbal,
                          TRIM (TO_CHAR (l_ledger_bal, ''99999999999999990.99'')) l_spenacctledgbal
                   FROM DUAL)';
       */
      p_spending_acctbal_out :=
                           TRIM (TO_CHAR (l_acct_bal, '99999999999999990.99'));
      p_spending_acctlegbal_out :=
                         TRIM (TO_CHAR (l_ledger_bal, '99999999999999990.99'));

      IF l_max_svg_trns_limt = l_svgtospd_trans
      THEN
         l_errmsg :=
             l_errmsg || '~This is the last transaction for a calendar month';
      END IF;

      --En Append respcode

      /*  IF l_svgacctclosr='Y' THEN
             l_errmsg:='ACCOUNT NEED TO BE CLOSED';
        END IF;

        IF (p_delivery_channel_in ='05' and p_txn_code_in ='47') THEN
             l_errmsg :='OK';
        END IF; */
      p_resp_code_out := '1';
   EXCEPTION                                            --<<Main Exception>>--
      WHEN exp_reject_record
      THEN
         ROLLBACK;
      WHEN OTHERS
      THEN
         ROLLBACK;
         l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
   END;

   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code_out
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code_in
         AND cms_delivery_channel = p_delivery_channel_in
         AND cms_response_id = TO_NUMBER (p_resp_code_out);
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errmsg :=
               'Problem while selecting respose code'
            || p_resp_code_out
            || ' is-'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '69';
   END;

   -- l_timestamp := SYSTIMESTAMP;
   BEGIN
      l_hashkey_id :=
         gethash (   p_delivery_channel_in
                  || p_txn_code_in
                  || p_pan_code_in
                  || p_rrn_in
                  || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
            'Error while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
   END;

   IF p_resp_code_out <> '00'
   THEN
      p_respmsg_out := l_errmsg;

      /*IF p_from_acct_type_in = 'SAVINGS'
      THEN
           l_acct_bal := l_savings_acct_bal;
           l_ledger_bal := l_savings_led_bal;
      END IF;     */
      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     p_ani_in,
                                     p_dni_in,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_prod_cattype,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg
                                    );
       if l_errmsg<>'OK' then
            p_respmsg_out := l_errmsg;
       end if;
      
	  update transactionlog
      set remark=p_comments_in
      where rrn=p_rrn_in;
	  
	   
     IF SQL%ROWCOUNT = 0 THEN                                             --Added for VMS-5735/FSP-991
	  	  update VMSCMS_HISTORY.TRANSACTIONLOG_HIST                   --Added for VMS-5735/FSP-991
          set remark=p_comments_in
          where rrn=p_rrn_in;
	 END IF;
	 
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   END IF;
END savings_to_spending;

PROCEDURE saving_transfer_account_close (
   p_inst_code_in            IN       NUMBER,
   p_delivery_channel_in     IN       VARCHAR2,
   p_txn_code_in             IN       VARCHAR2,
   p_rrn_in                  IN       VARCHAR2,
   p_cust_id_in              IN       VARCHAR2,
   p_partner_id_in           IN       VARCHAR2,
   p_trandate_in             IN       VARCHAR2,
   p_trantime_in             IN       VARCHAR2,
   p_curr_code_in            IN       VARCHAR2,
   p_rvsl_code_in            IN       VARCHAR2,
   p_msg_type_in             IN       VARCHAR2,
   p_ip_addr_in              IN       VARCHAR2,
   p_ani_in                  IN       VARCHAR2,
   p_dni_in                  IN       VARCHAR2,
   p_device_mob_no_in        IN       VARCHAR2,
   p_device_id_in            IN       VARCHAR2,
   p_uuid_in                 IN       VARCHAR2,
   p_os_name_in              IN       VARCHAR2,
   p_os_version_in           IN       VARCHAR2,
   p_gps_coordinates_in      IN       VARCHAR2,
   p_display_resolution_in   IN       VARCHAR2,
   p_physical_memory_in      IN       VARCHAR2,
   p_app_name_in             IN       VARCHAR2,
   p_app_version_in          IN       VARCHAR2,
   p_session_id_in           IN       VARCHAR2,
   p_device_country_in       IN       VARCHAR2,
   p_device_region_in        IN       VARCHAR2,
   p_ip_country_in           IN       VARCHAR2,
   p_proxy_flag_in           IN       VARCHAR2,
   p_pan_code_in             IN       VARCHAR2,
   p_amount_in               IN       VARCHAR2,
   p_comments_in             IN       VARCHAR2,
   P_TXN_MODE_in                IN   VARCHAR2,
   --p_orig_rrn_in             IN       VARCHAR2,
  -- p_is_closed_flag_in       IN       VARCHAR2,
   p_resp_code_out           OUT      VARCHAR2,
   p_respmsg_out             OUT      VARCHAR2,
   p_spending_acct_out       OUT      VARCHAR2,
   p_savings_acct_out        OUT      VARCHAR2
)
IS
   l_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   l_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   l_acct_no                cms_acct_mast.cam_acct_no%TYPE;
   l_acct_bal               cms_acct_mast.cam_acct_bal%TYPE;
   l_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
   l_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   l_prod_cattype           cms_appl_pan.cap_card_type%TYPE;
   l_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   l_expry_date             cms_appl_pan.cap_expry_date%TYPE;
   l_active_date            cms_appl_pan.cap_expry_date%TYPE;
   l_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
   l_cr_dr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_txn_type               cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
   l_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_dup_rrn_check          cms_transaction_mast.ctm_rrn_check%TYPE;
   l_comb_hash              pkg_limits_check.type_hash;
   l_auth_id                cms_transaction_log_dtl.ctd_auth_id%TYPE;
   l_timestamp              TIMESTAMP;
   l_preauth_flag           cms_transaction_mast.ctm_preauth_flag%TYPE;
   l_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   l_acct_type              cms_acct_mast.cam_type_code%TYPE;
   l_login_txn              cms_transaction_mast.ctm_login_txn%TYPE;
   l_fee_code               cms_fee_mast.cfm_fee_code%TYPE;
   l_fee_plan               cms_fee_feeplan.cff_fee_plan%TYPE;
   l_feeattach_type         transactionlog.feeattachtype%TYPE;
   l_tranfee_amt            transactionlog.tranfee_amt%TYPE;
   l_total_amt              cms_acct_mast.cam_acct_bal%TYPE;
   l_preauth_type           cms_transaction_mast.ctm_preauth_type%TYPE;
   l_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_proxynumber            cms_appl_pan.cap_proxy_number%TYPE;
   l_repl_flag              cms_appl_pan.cap_repl_flag%TYPE;
   l_errmsg                 VARCHAR2 (500);
   exp_reject_record        EXCEPTION;
   l_switch_acct_type       cms_acct_type.cat_switch_type%TYPE   DEFAULT '22';
   l_switch_spd_acct_type   cms_acct_stat.cas_switch_statcode%TYPE
                                                                  DEFAULT '3';
   l_switch_acct_stat       cms_acct_stat.cas_switch_statcode%TYPE     DEFAULT '2';
   l_cust_code              cms_appl_pan.cap_cust_code%TYPE;
   l_tran_date              DATE;
   l_savings_acct_no        cms_acct_mast.cam_acct_no%TYPE;
   l_savings_acct_bal       cms_acct_mast.cam_acct_bal%TYPE;
   l_savings_led_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   l_svg_acct_stat          cms_acct_mast.cam_stat_code%TYPE;
   l_savtospd_count         cms_acct_mast.cam_savtospd_tfer_count%TYPE;
   l_acct_stat              cms_acct_stat.cas_stat_code%TYPE;
   l_narration              CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
     L_STAN                     VARCHAR2 (20);
      l_capture_date             DATE;
   l_spendacct_type  cms_acct_mast.cam_type_code%type;
BEGIN
   BEGIN
      p_resp_code_out := '00';
      p_respmsg_out := 'success';

      --Sn pan details procedure call
      BEGIN
         SELECT cap_pan_code, cap_pan_code_encr, cap_acct_no, cap_card_stat,
                cap_prod_code, cap_card_type, cap_expry_date,
                cap_active_date, cap_prfl_code, cap_proxy_number,
                cap_repl_flag, cap_cust_code
           INTO l_hash_pan, l_encr_pan, l_acct_no, l_card_stat,
                l_prod_code, l_prod_cattype, l_expry_date,
                l_active_date, l_prfl_code, l_proxynumber,
                l_repl_flag, l_cust_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_pan_code_in)
            AND cap_mbr_numb = '000';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card number ' || gethash (p_pan_code_in);
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                   'Error in getting Pan Details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En pan details procedure call

      -- Sn Transaction Details  procedure call
      BEGIN
         vmscommon.get_transaction_details (p_inst_code_in,
                                            p_delivery_channel_in,
                                            p_txn_code_in,
                                            l_cr_dr_flag,
                                            l_txn_type,
                                            l_txn_desc,
                                            l_prfl_flag,
                                            l_preauth_flag,
                                            l_login_txn,
                                            l_preauth_type,
                                            l_dup_rrn_check,
                                            p_resp_code_out,
                                            l_errmsg
                                           );

         IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                 'Error from Transaction Details' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      -- En Transaction Details  procedure call

      -- Sn validating Date Time RRN
      IF l_dup_rrn_check = 'Y'
      THEN
         BEGIN
            vmscommon.validate_date_rrn (p_inst_code_in,
                                         p_rrn_in,
                                         p_trandate_in,
                                         p_trantime_in,
                                         p_delivery_channel_in,
                                         l_errmsg,
                                         p_resp_code_out
                                        );

            IF p_resp_code_out <> '00' AND l_errmsg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '22';
               l_errmsg :=
                     'Error while validating DATE and RRN'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      -- En validating Date Time RRN

      --Sn Get Tran date
      BEGIN
         l_tran_date :=
            TO_DATE (   SUBSTR (TRIM (p_trandate_in), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_trantime_in), 1, 8),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Problem while converting transaction date '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get Tran date

      --Sn select acct type(Savings)
      BEGIN
         SELECT cat_type_code
           INTO l_acct_type
           FROM cms_acct_type
          WHERE cat_inst_code = p_inst_code_in
            AND cat_switch_type = l_switch_acct_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Acct type not defined in master(Savings)';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting accttype(Savings) '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En select acct type(Savings)

      -- Sn Get Savings Acct number
      BEGIN
         SELECT cam_acct_no, cam_acct_bal, cam_ledger_bal,
                cam_stat_code, cam_savtospd_tfer_count
           INTO l_savings_acct_no, l_savings_acct_bal, l_savings_led_bal,
                l_svg_acct_stat, l_savtospd_count
           FROM cms_acct_mast
          WHERE cam_acct_id IN (
                   SELECT cca_acct_id
                     FROM cms_cust_acct
                    WHERE cca_cust_code = l_cust_code
                      AND cca_inst_code = p_inst_code_in)
            AND cam_type_code = l_acct_type
            AND cam_inst_code = p_inst_code_in;
      --p_amount_in :=l_savings_acct_bal;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '105';
            l_errmsg := 'Savings Acc not created for this card';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting savings acc number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN Get Savings Acct number

      --Sn Get Account Status(Savings)
      BEGIN
         SELECT cas_stat_code
           INTO l_acct_stat
           FROM cms_acct_stat
          WHERE cas_inst_code = p_inst_code_in
            AND cas_switch_statcode = l_switch_acct_stat;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Account Status not defind for Savings acc';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                  'Error while selecting savings acc status '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get Account Status(Savings)

      --Sn checks valid acc status
      IF l_acct_stat = l_svg_acct_stat
      THEN
         p_resp_code_out := '106';
         l_errmsg := 'Savings account already closed';
         RAISE exp_reject_record;
      END IF;

      --En checks valid acc status
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_spendacct_type
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code_in AND cam_acct_no = l_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Invalid Card /Account '||l_acct_no;
         WHEN OTHERS
         THEN
            p_resp_code_out := '12';
            l_errmsg :=
                       'Error in account details' || SUBSTR (SQLERRM, 1, 200);
      END;

      --SN : CMSAUTH check
      BEGIN
--         vmscommon.authorize_financial_txn (p_inst_code_in,
--                                     p_msg_type_in,
--                                     p_rrn_in,
--                                     p_delivery_channel_in,
--                                     NULL,                      --terminal  id
--                                     p_txn_code_in,         --transaction code
--                                     NULL,                  --transaction mode
--                                     p_trandate_in,
--                                     p_trantime_in,
--                                     p_pan_code_in,              --card number
--                                     l_hash_pan,                    --hash pan
--                                     l_encr_pan,              --encryption pan
--                                     l_card_stat,                --card status
--                                     l_proxynumber,             --proxy number
--                                     l_acct_no,               --account number
--                                     l_expry_date,               --expiry date
--                                     l_prod_code,                  --prod code
--                                     l_prod_cattype,               --card type
--                                     l_prfl_flag,               --profile flag
--                                     l_prfl_code,               --profile code
--                                     l_txn_type,                    --txn type
--                                     p_curr_code_in,           --currnecy code
--                                     l_preauth_flag,            --preauth flag
--                                     l_txn_desc,                   --tran desc
--                                     l_cr_dr_flag,                --cr dr flag
--                                     l_login_txn,                 --log in txn
--                                     NULL,              --amount transfer flag
--                                     NULL,                      --bank code in
--                                     l_savings_acct_bal, --p_amount_in,      --transaction amount in
--                                     NULL,                     --merchant name
--                                     NULL,                     --merchant city
--                                     NULL,                          --MCC code
--                                     NULL,                        --Tip amount
--                                     l_acct_no,                 --to account number
--                                     NULL,                 --atm name location
--                                     NULL,                      --mcc group id
--                                     NULL,            --currency code group id
--                                     NULL,               --trans code group id
--                                     NULL,                          --rules in
--                                     NULL,                      --preauth date
--                                     NULL,                    --consodium code
--                                     NULL,                      --partner code
--                                     NULL,                              --stan
--                                     p_rvsl_code_in,           --reversal code
--                                    -- NULL,              --current convert amnt
--                                     NULL,                          --fee flag
--                                     NULL,                        --admin flag
--                                     p_ip_addr_in,               --ip address,
--                                     p_ani_in,                           --ani
--                                     p_dni_in,                          --dni,
--                                     p_device_mob_no_in,  --device mob number,
--                                     p_device_id_in,              --device id,
--                                     p_uuid_in,                         --uuid
--                                     p_os_name_in,                   --os name
--                                     p_os_version_in,             --os version
--                                     p_gps_coordinates_in,
--                                     p_display_resolution_in,
--                                     p_physical_memory_in,
--                                     p_app_name_in,
--                                     p_app_version_in,
--                                     p_session_id_in,
--                                     p_device_country_in,
--                                     p_device_region_in,
--                                     p_comments_in,
--                                     l_auth_id,                       --output
--                                     p_resp_code_out,                 --output
--                                     l_errmsg                         --output
--                                    );
--
--         IF l_errmsg <> 'OK'
--         THEN
--            RAISE exp_reject_record;
--         END IF;
--      EXCEPTION
--         WHEN exp_reject_record
--         THEN
--            RAISE;
--         WHEN OTHERS
--         THEN
--            p_resp_code_out := '21';
--            l_errmsg :=
--                  'Error from authorize_nonfinancial_txn '
--               || SUBSTR (SQLERRM, 1, 200);
--            RAISE exp_reject_record;
--      END;


sp_authorize_txn_cms_auth (p_inst_code_in,
                                 p_msg_type_in,
                                 p_rrn_in,
                                 p_delivery_channel_in,
                                 null,--v_term_id,
                                 p_txn_code_in,
                                 P_TXN_MODE_in,
                                 p_trandate_in,
                                 p_trantime_in,
                                 p_pan_code_in,
                                 null,--p_bank_code,
                                 l_savings_acct_bal,
                                 NULL,
                                 NULL,
                                 null,--v_mcc_code,
                                 p_curr_code_in,
                                 NULL,
                                 NULL,
                                 NULL,
                                 l_acct_no,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 l_expry_date,
                                 l_stan,
                                 '000',
                                 p_rvsl_code_in,
                                 l_savings_acct_bal,
                                 l_auth_id,
                                 p_resp_code_out,
                                 l_errmsg,
                                 l_capture_date
                                );

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
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error from authorize_nonfinancial_txn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN : CMSAUTH check
 Begin
                UPDATE transactionlog  SET 
                uuid=p_uuid_in,
                os_name=p_os_name_in, 
                os_version=p_os_version_in, 
                gps_coordinates=p_gps_coordinates_in, 
                display_resolution=p_display_resolution_in, 
                physical_memory=p_physical_memory_in, 
                app_name=p_app_name_in, 
                app_version=p_app_version_in, 
                session_id=p_session_id_in, 
                device_country=p_device_country_in, 
                device_region=p_device_region_in, 
                ip_country=p_ip_country_in, 
                proxy_flag=p_proxy_flag_in, 
                REQ_PARTNER_ID=p_partner_id_in,
                 remark=p_comments_in						    							   
                WHERE rrn  = p_rrn_in AND business_date= p_trandate_in
                                          AND business_time =p_trantime_in
                AND delivery_channel=p_delivery_channel_in AND txn_code =p_txn_code_in AND INSTCODE=p_inst_code_in  AND MSGTYPE =p_msg_type_in;
            
             
            IF SQL%ROWCOUNT = 0 THEN                                                --Added for VMS-5733/FSP-991
			
               UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST  SET                   --Added for VMS-5733/FSP-991
                uuid=p_uuid_in,
                os_name=p_os_name_in, 
                os_version=p_os_version_in, 
                gps_coordinates=p_gps_coordinates_in, 
                display_resolution=p_display_resolution_in, 
                physical_memory=p_physical_memory_in, 
                app_name=p_app_name_in, 
                app_version=p_app_version_in, 
                session_id=p_session_id_in, 
                device_country=p_device_country_in, 
                device_region=p_device_region_in, 
                ip_country=p_ip_country_in, 
                proxy_flag=p_proxy_flag_in, 
                REQ_PARTNER_ID=p_partner_id_in,
                 remark=p_comments_in						    							   
                WHERE rrn  = p_rrn_in AND business_date= p_trandate_in
                                          AND business_time =p_trantime_in
                AND delivery_channel=p_delivery_channel_in AND txn_code =p_txn_code_in AND INSTCODE=p_inst_code_in  AND MSGTYPE =p_msg_type_in;
				
            END IF;			

			
                IF SQL%ROWCOUNT = 0
                 THEN
                    p_resp_code_out := '21';
                    l_errmsg := 'Error while updating transactionlog';
                    RAISE exp_reject_record;
                 END IF;
        exception
            when exp_reject_record then
                raise;
            when others then
                 p_resp_code_out := '21';
                    l_errmsg :=
                          'Error while updating transactionlog '
                       || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
        end;

      --Sn Update the Amount To acct no(Savings)
      BEGIN
         UPDATE cms_acct_mast
            SET cam_acct_bal = 0,
                cam_ledger_bal = 0,
                CAM_STAT_CODE =l_acct_stat,
                cam_lupd_date = SYSDATE,
                cam_lupd_user = 1,
                cam_savtospd_tfer_count = 0,
                cam_acct_crea_tnfr_date = SYSDATE
          WHERE cam_inst_code = p_inst_code_in
            AND cam_acct_no = l_savings_acct_no
            AND cam_type_code = l_acct_type;

         IF SQL%ROWCOUNT = 0
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Error while updating amount in to acct no(Savings) ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                  'Error while updating amount in to acct no(Savings) '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Update the Amount To acct no(Savings)

      ---Sn  Add a record in statements for TO ACCT (Savings)
      BEGIN
         IF TRIM (l_trans_desc) IS NOT NULL
         THEN
            l_narration := l_trans_desc || '/';
         END IF;

         IF TRIM (l_auth_id) IS NOT NULL
         THEN
            l_narration := l_narration || l_auth_id || '/';
         END IF;

         IF TRIM (l_acct_no) IS NOT NULL
         THEN
            l_narration := l_narration || l_acct_no || '/';
         END IF;

         IF TRIM (p_trandate_in) IS NOT NULL
         THEN
            l_narration := l_narration || p_trandate_in;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg :=
                'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      l_timestamp := SYSTIMESTAMP;

      BEGIN
         l_cr_dr_flag := 'DR';

         INSERT INTO cms_statements_log
                     (csl_pan_no, csl_acct_no, csl_opening_bal,
                      csl_trans_amount, csl_trans_type, csl_trans_date,
                      csl_closing_balance,
                      csl_trans_narrration, csl_pan_no_encr, csl_rrn,
                      csl_auth_id, csl_business_date, csl_business_time,
                      txn_fee_flag, csl_delivery_channel, csl_inst_code,
                      csl_txn_code, csl_ins_date, csl_ins_user,
                      csl_panno_last4digit,
                      csl_to_acctno, csl_acct_type, csl_prod_code,
                      csl_card_type, csl_time_stamp
                     )
              VALUES (l_hash_pan, l_savings_acct_no, l_savings_led_bal,
                      p_amount_in, 'DR', l_tran_date,
                      DECODE (l_cr_dr_flag,
                              'DR', l_savings_led_bal - p_amount_in,
                              'CR', l_savings_led_bal + p_amount_in,
                              'NA', l_savings_led_bal
                             ),
                      l_narration, l_encr_pan, p_rrn_in,
                      l_auth_id, p_trandate_in, p_trantime_in,
                      'N', p_delivery_channel_in, p_inst_code_in,
                      p_txn_code_in, SYSDATE, 1,
                      (SUBSTR (p_pan_code_in,
                               LENGTH (p_pan_code_in) - 3,
                               LENGTH (p_pan_code_in)
                              )
                      ),
                      NULL,                                   --p_spd_acct_no,
                           l_acct_type, l_prod_code,
                      l_prod_cattype, l_timestamp
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_errmsg := 'Error creating entry in statement log ';
            RAISE exp_reject_record;
      END;
      p_resp_code_out := '1';
   EXCEPTION                                            --<<Main Exception>>--
      WHEN exp_reject_record
      THEN
         ROLLBACK;
      WHEN OTHERS
      THEN
         ROLLBACK;
         l_errmsg := 'Other Excp-' || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
   END;

   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code_out
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code_in
         AND cms_delivery_channel = p_delivery_channel_in
         AND cms_response_id = TO_NUMBER (p_resp_code_out);
   EXCEPTION
      WHEN OTHERS
      THEN
         l_errmsg :=
               'Problem while selecting respose code'
            || p_resp_code_out
            || ' is-'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '69';
   END;

   l_timestamp := SYSTIMESTAMP;

   BEGIN
      l_hashkey_id :=
         gethash (   p_delivery_channel_in
                  || p_txn_code_in
                  || p_pan_code_in
                  || p_rrn_in
                  || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_errmsg :=
            'Error while generating hashkey_id- ' || SUBSTR (SQLERRM, 1, 200);
   END;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO l_acct_bal, l_ledger_bal, l_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code_in AND cam_acct_no = l_acct_no;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '21';
         l_errmsg := 'Invalid Card /Account ';
      WHEN OTHERS
      THEN
         p_resp_code_out := '12';
         l_errmsg := 'Error in account details' || SUBSTR (SQLERRM, 1, 200);
   END;

p_spending_acct_out :=TRIM (TO_CHAR (l_acct_bal, '99999999999999990.99'));
p_savings_acct_out := TRIM (TO_CHAR (l_ledger_bal, '99999999999999990.99')) ;
   IF p_resp_code_out <> '00'
   THEN
      p_respmsg_out := l_errmsg;

      BEGIN
         vms_log.log_transactionlog (p_inst_code_in,
                                     p_msg_type_in,
                                     p_rrn_in,
                                     p_delivery_channel_in,
                                     p_txn_code_in,
                                     l_txn_type,
                                     0,
                                     p_trandate_in,
                                     p_trantime_in,
                                     '00',
                                     l_hash_pan,
                                     l_encr_pan,
                                     l_errmsg,
                                     p_ip_addr_in,
                                     l_card_stat,
                                     l_txn_desc,
                                     NULL,
                                     NULL,
                                     l_timestamp,
                                     l_acct_no,
                                     l_prod_code,
                                     l_prod_cattype,
                                     l_cr_dr_flag,
                                     l_acct_bal,
                                     l_ledger_bal,
                                     l_acct_type,
                                     l_proxynumber,
                                     l_auth_id,
                                     0,
                                     l_total_amt,
                                     l_fee_code,
                                     l_tranfee_amt,
                                     l_fee_plan,
                                     l_feeattach_type,
                                     p_resp_code_out,
                                     p_resp_code_out,
                                     p_curr_code_in,
                                     l_hashkey_id,
                                     p_uuid_in,
                                     p_os_name_in,
                                     p_os_version_in,
                                     p_gps_coordinates_in,
                                     p_display_resolution_in,
                                     p_physical_memory_in,
                                     p_app_name_in,
                                     p_app_version_in,
                                     p_session_id_in,
                                     p_device_country_in,
                                     p_device_region_in,
                                     p_ip_country_in,
                                     p_proxy_flag_in,
                                     p_partner_id_in,
                                     l_errmsg
                                    );
     if l_errmsg<>'OK' then
            p_respmsg_out := l_errmsg;
       end if;
	   
      update transactionlog
      set remark=p_comments_in
      where rrn=p_rrn_in;
	  
	   
     IF SQL%ROWCOUNT = 0 THEN                             --Added for VMS-5735/FSP-991
	 
	  update VMSCMS_HISTORY.TRANSACTIONLOG_HIST       --Added for VMS-5735/FSP-991               
      set remark=p_comments_in
      where rrn=p_rrn_in;
	  
	 
	 END IF;
	  
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '69';
            p_respmsg_out :=
                  'Exception while inserting to transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   END IF;
END saving_transfer_account_close;

PROCEDURE 
  ACCOUNT_TO_ACCOUNT_TRANSFER(
                              p_i_inst_code               IN      VARCHAR2,      
                              p_i_del_channel             IN      VARCHAR2,  
                              p_i_txn_code                IN      VARCHAR2,   
                              p_i_rrn                     IN      VARCHAR2, 
                              p_i_partner_id              IN      VARCHAR2,
                              p_i_business_date           IN      VARCHAR2,         
                              p_i_business_time           IN      VARCHAR2,         
                              p_i_curr_code               IN      VARCHAR2,         
                              p_i_reversal_code           IN      VARCHAR2,                 
                              p_i_msg_type                IN      VARCHAR2,               
                              p_i_ip_addr                 IN      VARCHAR2,         
                              p_i_ani                     IN      VARCHAR2,               
                              p_i_dni                     IN      VARCHAR2,               
                              p_i_dev_mob_no              IN      VARCHAR2,
                              p_i_device_id               IN      VARCHAR2,         
                              p_i_uuid                    IN      VARCHAR2,
                              p_i_osname                  IN      VARCHAR2,
                              p_i_osversion               IN      VARCHAR2,
                              p_i_gpscoordinates          IN      VARCHAR2,
                              p_i_displayresolution       IN      VARCHAR2,
                              p_i_physicalmemory          IN      VARCHAR2,
                              p_i_appname                 IN      VARCHAR2,
                              p_i_appversion              IN      VARCHAR2,
                              p_i_sessionid               IN      VARCHAR2,
                              p_i_devicecountry           IN      VARCHAR2,
                              p_i_deviceregion            IN      VARCHAR2,
                              p_i_ipcountry               IN      VARCHAR2,
                              p_i_proxy                   IN      VARCHAR2,
                              p_i_term_id                 IN      VARCHAR2,
                              p_i_txn_mode                IN      VARCHAR2,
                              p_i_from_card_no            IN      VARCHAR2,
                              p_i_from_hash_card_no       IN      VARCHAR2,
                              p_i_from_encr_pan           IN      VARCHAR2,
                              p_i_txn_amt          		    IN      NUMBER,
                              p_i_mcc_code        		    IN      VARCHAR2,
                              p_i_to_card_no   		        IN      VARCHAR2,
                              p_i_to_hash_card_no         IN      VARCHAR2,
                              p_i_to_encr_pan             IN      VARCHAR2,
                              p_i_stan            		  IN      VARCHAR2,
                              p_i_ctc_binflag      		  IN      VARCHAR2,
                              p_i_fee_waiver_flag  		  IN      VARCHAR2,
                              p_i_comments                IN      VARCHAR2,
                              p_o_resp_code               OUT     VARCHAR2,
                              p_o_resp_msg                OUT     VARCHAR2,
                              p_o_fee_amt          			  OUT     VARCHAR2                                                
                               )
                                     
AS

  v_varchar2_resp_cde                   CMS_RESPONSE_MAST.CMS_RESPONSE_ID%type;
  v_varchar2_txn_type                   TRANSACTIONLOG.TXN_TYPE%type;
  v_varchar2_respmsg                    VARCHAR2(500);
  v_date_capture_date                   DATE;
  v_number_toacct_bal                   CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  v_varchar2_dr_cr_flag                 CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%type;
  v_varchar2_ctoc_auth_id               TRANSACTIONLOG.AUTH_ID%type;
  v_varchar2_from_prodcode              CMS_APPL_PAN.CAP_PROD_CODE%type;
  v_number_from_cardtype                CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  v_date_tran_date                      CMS_STATEMENTS_LOG.CSL_TRANS_DATE%type;
  v_varchar2_from_card_curr             CMS_BIN_PARAM.CBP_PARAM_VALUE%type;
  v_varchar2_to_card_curr               CMS_BIN_PARAM.CBP_PARAM_VALUE%type;
  e_reject_record                       EXCEPTION;
  e_auth_reject_record                  EXCEPTION;
  v_number_acct_balance                 CMS_ACCT_MAST.CAM_ACCT_BAL%type;
  v_varchar2_tocardstat                 CMS_APPL_PAN.cap_card_stat%type;
  v_varchar2_fromcardstat               CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  v_date_fromcardexp                    CMS_APPL_PAN.cap_expry_date%TYPE;
  v_date_tocardexp                      CMS_APPL_PAN.cap_expry_date%type;
  v_number_rrn_count                    NUMBER;
  v_number_max_card_bal                 CMS_ACCT_MAST.CAM_ACCT_BAL%type;
  v_number_acct_number                  CMS_APPL_PAN.CAP_ACCT_NO%type;
  v_number_ledger_balance               CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
  v_varchar2_narration                  CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  v_varchar2_toacct_no                  CMS_ACCT_MAST.CAM_ACCT_NO%type;
  v_varchar2_toprodcode                 CMS_APPL_PAN.CAP_PROD_CODE%type;
  v_number_tocardtype                   CMS_APPL_PAN.CAP_CARD_TYPE%type;
  v_varchar2_toacctnumber               CMS_APPL_PAN.CAP_ACCT_NO%type;
  v_number_status_chk                   NUMBER;
  v_number_precheck_flag                PCMS_TRANAUTH_PARAM.PTP_PARAM_VALUE%type;
  v_number_atmonline_limit              CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%type;
  v_number_posonline_limit              CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%type;
  v_varchar2_tran_type                  CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%type;
  v_type_comb_hash                      PKG_LIMITS_CHECK.TYPE_HASH;
  v_varchar2_prfl_code                  CMS_APPL_PAN.CAP_PRFL_CODE%type;
  v_char_prfl_flag                      CMS_TRANSACTION_MAST.CTM_PRFL_FLAG%type;
  v_varchar2_trans_desc                 CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
  v_number_from_pan_bin                 CMS_PROD_BIN.CPB_INST_BIN%TYPE;
  v_number_to_pan_bin                   CMS_PROD_BIN.CPB_INST_BIN%type;
  v_number_toledger_bal                 CMS_ACCT_MAST.CAM_LEDGER_BAL%type;
  v_number_frmacct_type                 CMS_ACCT_MAST.CAM_TYPE_CODE%type;
  v_number_toacct_type                  CMS_ACCT_MAST.CAM_TYPE_CODE%type;
  v_varchar2_hashkey_id                 cms_transaction_log_dtl.ctd_hashkey_id%type;
  v_time_stamp                          TIMESTAMP;
  v_number_initialload_amt              CMS_ACCT_MAST.CAM_NEW_INITIALLOAD_AMT%TYPE;
  v_varchar2_profile_code               CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  v_varchar2_badcredit_flag             CMS_PROD_CATTYPE.CPC_BADCREDIT_FLAG%type;
  v_number_txn_amt                      CMS_STATEMENTS_LOG.CSL_TRANS_AMOUNT%type;
  
  v_Retperiod  date;  --Added for VMS-5735/FSP-991
  v_Retdate  date; --Added for VMS-5735/FSP-991
  
BEGIN

    v_varchar2_txn_type  := '1';
    P_O_FEE_AMT   :=0;
    v_time_stamp :=SYSTIMESTAMP;
    v_number_txn_amt := ROUND (P_I_TXN_AMT, 2);

    BEGIN
        v_varchar2_hashkey_id := GETHASH (p_i_del_channel||p_i_txn_code||P_I_FROM_CARD_NO|| p_i_rrn||to_char(v_time_stamp,'YYYYMMDDHH24MISSFF5'));
    EXCEPTION
        WHEN OTHERS
        THEN
            p_o_resp_code := '21';
            v_varchar2_respmsg :='Error while converting hashkey_id ' || SUBSTR (SQLERRM, 1, 200);
            RAISE E_REJECT_RECORD;
    END;


    BEGIN
       SELECT ctm_credit_debit_flag,
              TO_NUMBER(DECODE(ctm_tran_type, 'N', '0', 'F', '1')),
              ctm_tran_type,
              ctm_prfl_flag,ctm_tran_desc
         INTO v_varchar2_dr_cr_flag,
              v_varchar2_txn_type, v_varchar2_tran_type,
              v_char_prfl_flag,v_varchar2_trans_desc
         FROM CMS_TRANSACTION_MAST
        WHERE ctm_tran_code = p_i_txn_code AND
              ctm_delivery_channel = p_i_del_channel AND
              ctm_inst_code = p_i_inst_code;
        EXCEPTION
             WHEN OTHERS THEN
               v_varchar2_resp_cde := '21';
               v_varchar2_respmsg  := 'Error while selecting transaction details '|| SUBSTR (SQLERRM, 1, 200);
               RAISE E_REJECT_RECORD;
    END;

        BEGIN

        SELECT cap_card_stat,cap_expry_date,
               cap_prod_code,cap_card_type,cap_acct_no
        INTO v_varchar2_fromcardstat,v_date_fromcardexp,
             v_varchar2_from_prodcode,v_number_from_cardtype,v_number_acct_number
        FROM CMS_APPL_PAN
        WHERE cap_inst_code = p_i_inst_code AND cap_pan_code = P_I_FROM_HASH_CARD_NO;

        EXCEPTION
          WHEN OTHERS THEN
             v_varchar2_resp_cde := '12';
             v_varchar2_respmsg  := 'Problem while selecting from card detail' || SUBSTR(SQLERRM, 1, 200);
          RAISE E_REJECT_RECORD;
    END;



    BEGIN
      SELECT cap_card_stat, cap_expry_date, cap_prod_code, cap_card_type, cap_acct_no,
             cap_atm_online_limit,cap_pos_online_limit
      INTO v_varchar2_tocardstat, v_date_tocardexp, v_varchar2_toprodcode, v_number_tocardtype, v_varchar2_toacctnumber,
           v_number_atmonline_limit,v_number_posonline_limit
      FROM CMS_APPL_PAN
      WHERE cap_inst_code = p_i_inst_code AND cap_pan_code = p_i_to_hash_card_no;
        EXCEPTION
           WHEN OTHERS THEN
             v_varchar2_resp_cde := '12';
             v_varchar2_respmsg  := 'Problem while selecting to card detail' ||   SUBSTR(SQLERRM, 1, 200);
           RAISE E_REJECT_RECORD;
    END;


    IF P_I_CTC_BINFLAG = 'N' THEN
     IF( LENGTH (P_I_FROM_CARD_NO) > 10) and ( LENGTH (P_I_TO_CARD_NO) > 10) THEN

        v_number_from_pan_bin := SUBSTR (P_I_FROM_CARD_NO, 1, 6);
        v_number_to_pan_bin := SUBSTR (P_I_TO_CARD_NO, 1, 6);

         IF v_number_from_pan_bin <> v_number_to_pan_bin then
               v_varchar2_resp_cde := '140';
               v_varchar2_respmsg  := 'Both the card number should be in same BIN';
               RAISE E_REJECT_RECORD;
         END IF;

      END IF;
    END IF;

    BEGIN
	    
		--Added for VMS-5735/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_i_business_date), 1, 8), 'yyyymmdd');
	 
	 IF (v_Retdate>v_Retperiod) THEN                                     --Added for VMS-5735/FSP-991
	
        SELECT COUNT(1)
        INTO v_number_rrn_count
        FROM TRANSACTIONLOG
        WHERE rrn = p_i_rrn AND business_date = p_i_business_date
        AND delivery_channel = p_i_del_channel;
		
	 ELSE
	 
	    SELECT COUNT(1)
        INTO v_number_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                      --Added for VMS-5735/FSP-991
        WHERE rrn = p_i_rrn AND business_date = p_i_business_date
        AND delivery_channel = p_i_del_channel;
	 
	 END IF;

          IF v_number_rrn_count > 0 THEN
             v_varchar2_resp_cde := '22';
             v_varchar2_respmsg  := 'Duplicate RRN ';
             RAISE E_REJECT_RECORD;
          END IF;
		  
        EXCEPTION
          WHEN E_REJECT_RECORD THEN
          RAISE;
          WHEN OTHERS THEN
             v_varchar2_resp_cde := '21';
             v_varchar2_respmsg  := 'Error while checking  duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
          RAISE E_REJECT_RECORD;
    END;

    BEGIN
          v_date_tran_date := TO_DATE(SUBSTR(TRIM(p_i_business_date), 1, 8) || ' ' ||
                            SUBSTR(TRIM(p_i_business_time), 1, 8),
                                'yyyymmdd hh24:mi:ss');
      EXCEPTION
        WHEN OTHERS THEN
         v_varchar2_resp_cde := '21';
         v_varchar2_respmsg  := 'Problem while converting transaction date ' ||
                    SUBSTR(SQLERRM, 1, 200);
         RAISE E_REJECT_RECORD;
    END;




    BEGIN

        vmsfunutilities.get_currency_code(v_varchar2_from_prodcode,v_number_from_cardtype,p_i_inst_code,v_varchar2_from_card_curr,v_varchar2_respmsg);

          IF v_varchar2_respmsg <>'OK' then
               RAISE E_REJECT_RECORD;
          END IF;

          IF v_varchar2_from_card_curr IS NULL THEN
             v_varchar2_resp_cde := '21';
             v_varchar2_respmsg  := 'From Card currency cannot be null ';
             RAISE E_REJECT_RECORD;
          END IF;

          EXCEPTION
          WHEN E_REJECT_RECORD THEN
          RAISE;
          WHEN OTHERS THEN
             v_varchar2_respmsg  := 'Error while selecting card currecy  ' ||
                        SUBSTR(SQLERRM, 1, 200);
             v_varchar2_resp_cde := '21';
          RAISE E_REJECT_RECORD;
    END;


    BEGIN
         SELECT ptp_param_value
         INTO v_number_precheck_flag
         FROM PCMS_TRANAUTH_PARAM
         WHERE ptp_param_name = 'PRE CHECK' 
         AND ptp_inst_code = p_i_inst_code;
          EXCEPTION
             WHEN OTHERS THEN
                 v_varchar2_resp_cde := '21';
                 v_varchar2_respmsg  := 'Error while selecting precheck flag' ||
                            SUBSTR(SQLERRM, 1, 200);
             RAISE E_REJECT_RECORD;
    END;


  BEGIN

      vmsfunutilities.get_currency_code(v_varchar2_toprodcode,v_number_tocardtype,p_i_inst_code,v_varchar2_to_card_curr,v_varchar2_respmsg);

          IF v_varchar2_respmsg <>'OK' then
               RAISE E_REJECT_RECORD;
          END IF;

          IF v_varchar2_to_card_curr IS NULL THEN
             v_varchar2_resp_cde := '21';
             v_varchar2_respmsg  := 'To Card currency cannot be null ';
             RAISE E_REJECT_RECORD;
          END IF;

        EXCEPTION
            WHEN E_REJECT_RECORD THEN
            RAISE;
            WHEN OTHERS THEN
              v_varchar2_respmsg  := 'Error while selecting card currecy  ' ||
                          SUBSTR(SQLERRM, 1, 200);
              v_varchar2_resp_cde:= '21';
            RAISE E_REJECT_RECORD;
  END;


    IF v_varchar2_to_card_curr <> v_varchar2_from_card_curr
    THEN
        v_varchar2_respmsg  := 'Both from card currency and to card currency are not same  ';
        v_varchar2_resp_cde := '21';
        RAISE E_REJECT_RECORD;
    END IF;


    BEGIN
        SELECT CAM_ACCT_BAL
        INTO v_number_acct_balance
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = p_i_inst_code AND
              CAM_ACCT_NO =  v_number_acct_number
        FOR UPDATE;

      EXCEPTION
        WHEN OTHERS 
        THEN
           v_varchar2_resp_cde := '21';
           v_varchar2_respmsg  := 'Error while selecting data from account master ' || SUBSTR(SQLERRM, 1, 200);
           RAISE E_REJECT_RECORD;
    END;


    IF v_number_acct_balance < v_number_txn_amt
    THEN
        v_varchar2_resp_cde := '15';
        v_varchar2_respmsg  := 'Insufficient Fund ';
        RAISE E_REJECT_RECORD;
    END IF;


    BEGIN
        SELECT cam_acct_bal, cam_acct_no,cam_ledger_bal,
               cam_type_code,NVL(cam_new_initialload_amt,cam_initialload_amt)
        INTO v_number_toacct_bal, v_varchar2_toacct_no,v_number_toledger_bal,
              v_number_toacct_type,v_number_initialload_amt
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = p_i_inst_code AND
             CAM_ACCT_NO =  v_varchar2_toacctnumber;
          EXCEPTION
             WHEN OTHERS THEN
               v_varchar2_resp_cde := '21';
               v_varchar2_respmsg  := 'Problem while selecting to acct balance ' ||
                          SUBSTR(SQLERRM, 1, 200);
               RAISE E_REJECT_RECORD;
    END;


     BEGIN
           SP_STATUS_CHECK_GPR( p_i_inst_code,
                                p_i_to_card_no,
                                p_i_del_channel,
                                v_date_tocardexp,
                                v_varchar2_tocardstat,
                                p_i_txn_code,
                                P_I_TXN_MODE,
                                v_varchar2_toprodcode,
                                v_number_tocardtype,
                                p_i_msg_type,
                                p_i_business_date,
                                p_i_business_time,
                                NULL,
                                NULL,
                                p_i_mcc_code,
                                v_varchar2_resp_cde,
                                v_varchar2_respmsg
                               );

               IF ((v_varchar2_resp_cde <> '1' AND v_varchar2_respmsg <> 'OK') OR 
                          (v_varchar2_resp_cde <> '0' AND v_varchar2_respmsg <> 'OK'))
               THEN     
                      v_varchar2_respmsg := 'For TO CARD -- '||v_varchar2_respmsg;
                      RAISE E_REJECT_RECORD;
               ELSE
                      v_number_status_chk:=v_varchar2_resp_cde;
                      v_varchar2_resp_cde:='1';
               END IF;

            EXCEPTION
                WHEN E_REJECT_RECORD
                THEN RAISE;
                WHEN OTHERS THEN
                    v_varchar2_resp_cde := '21';
                    v_varchar2_respmsg  := 'Error from GPR Card Status Check for TO CARD' ||SUBSTR(SQLERRM, 1, 200);
                RAISE E_REJECT_RECORD;
     END;

     IF v_number_status_chk='1' THEN

          IF p_i_del_channel <> '11' THEN

             BEGIN

                     IF TO_DATE(p_i_business_date, 'YYYYMMDD') >
                        LAST_DAY(TO_CHAR(v_date_tocardexp, 'DD-MON-YY'))
                     THEN      
                            v_varchar2_resp_cde := '13';
                            v_varchar2_respmsg  := 'TO CARD IS EXPIRED';
                            RAISE E_REJECT_RECORD;      
                     END IF;

                     EXCEPTION     
                       WHEN E_REJECT_RECORD 
                       THEN RAISE;      
                       WHEN OTHERS THEN
                            v_varchar2_resp_cde := '21';
                            v_varchar2_respmsg  := 'ERROR IN EXPIRY DATE CHECK FOR TO CARD: Tran Date - ' ||
                                        p_i_business_date || ', Expiry Date - ' || v_date_tocardexp || ',' ||
                                        SUBSTR(SQLERRM, 1, 200);
                       RAISE E_REJECT_RECORD;

             END;

          END IF;

          IF v_number_precheck_flag = 1 THEN

               BEGIN
                 SP_PRECHECK_TXN( p_i_inst_code,
                                  p_i_to_card_no,
                                  p_i_del_channel,
                                  v_date_tocardexp,
                                  v_varchar2_tocardstat,
                                  p_i_txn_code,
                                  p_i_txn_mode,
                                  p_i_business_date,
                                  p_i_business_time,
                                  v_number_txn_amt,
                                  v_number_atmonline_limit,
                                  v_number_posonline_limit,
                                  v_varchar2_resp_cde,
                                  v_varchar2_respmsg
                                 );

                     IF (v_varchar2_resp_cde <> '1' OR v_varchar2_respmsg <> 'OK')
                     THEN   
                        v_varchar2_respmsg := 'For TO CARD -- '||v_varchar2_respmsg;
                        RAISE E_REJECT_RECORD;
                     END IF;

                       EXCEPTION
                         WHEN E_REJECT_RECORD
                         THEN RAISE;
                         WHEN OTHERS THEN
                            v_varchar2_resp_cde := '21';
                            v_varchar2_respmsg  := 'Error from precheck processes for TO CARD' ||SUBSTR(SQLERRM, 1, 200);
                         raise E_REJECT_RECORD;
               END;

          END IF;

    END IF;

     BEGIN
          SP_AUTHORIZE_TXN_CMS_AUTH(
                              p_i_inst_code,
                              p_i_msg_type,
                              p_i_rrn,
                              p_i_del_channel,
                              p_i_term_id,
                              p_i_txn_code,
                              p_i_txn_mode,
                              p_i_business_date,
                              p_i_business_time,
                              p_i_from_card_no,
                              1,
                              v_number_txn_amt,
                              NULL,
                              NULL,
                              p_i_mcc_code,
                              p_i_curr_code,
                              NULL,
                              NULL,
                              NULL,
                              v_varchar2_toacct_no,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              v_date_fromcardexp,
                              p_i_stan,
                              '000',
                              p_i_reversal_code,
                              v_number_txn_amt,
                              v_varchar2_ctoc_auth_id,
                              v_varchar2_resp_cde,
                              v_varchar2_respmsg,
                              v_date_capture_date,
                              CASE WHEN p_i_fee_waiver_flag='N'
                                   THEN 'Y'
                                   WHEN p_i_fee_waiver_flag='Y'
                                   THEN 'N'
                              END);

                  IF v_varchar2_resp_cde <> '00' AND v_varchar2_respmsg <> 'OK' THEN
                     RAISE E_REJECT_RECORD;
                  END IF;

                EXCEPTION
                    WHEN E_REJECT_RECORD THEN
                    RAISE;
                    WHEN OTHERS THEN
                         v_varchar2_resp_cde := '21';
                         v_varchar2_respmsg  := 'Error from Card authorization' ||
                                    SUBSTR(SQLERRM, 1, 200);
                    RAISE E_REJECT_RECORD;
     END;

     BEGIN
          IF v_char_prfl_flag = 'Y'
          THEN
             pkg_limits_check.sp_limits_check (NULL,
                                               p_i_from_hash_card_no,
                                               p_i_to_hash_card_no,
                                               NULL,
                                               p_i_txn_code,
                                               v_varchar2_tran_type,
                                               NULL,
                                               NULL,
                                               p_i_inst_code,
                                               NULL,
                                               v_varchar2_prfl_code,
                                               v_number_txn_amt,
                                               p_i_del_channel,
                                               v_type_comb_hash,
                                               v_varchar2_resp_cde,
                                               v_varchar2_respmsg
                                              );

          END IF;

          IF v_varchar2_resp_cde <> '00' AND v_varchar2_respmsg <> 'OK'
          THEN
               v_varchar2_respmsg := 'Error from Limit Check Process ' || v_varchar2_respmsg;
               RAISE E_REJECT_RECORD;
          END IF;
             EXCEPTION
                WHEN E_REJECT_RECORD
                THEN
                   RAISE;
                WHEN OTHERS
                THEN
                     v_varchar2_resp_cde := '21';
                     v_varchar2_respmsg :=
                            'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
                RAISE E_REJECT_RECORD;
     END;

     BEGIN
           SELECT cpc_profile_code,cpc_badcredit_flag
           INTO v_varchar2_profile_code,v_varchar2_badcredit_flag
           FROM CMS_PROD_CATTYPE
           WHERE CPC_INST_CODE = p_i_inst_code
           AND cpc_prod_code = v_varchar2_toprodcode
           AND cpc_card_type = v_number_tocardtype;

              EXCEPTION
                  WHEN OTHERS
                  THEN
                       v_varchar2_respmsg  := 'Error while getting details from prod cattype';
                      v_varchar2_resp_cde := '21';
              RAISE E_REJECT_RECORD;
     END;

      BEGIN  

          SELECT TO_NUMBER(cbp_param_value)
          INTO v_number_max_card_bal
          FROM CMS_BIN_PARAM
          WHERE cbp_inst_code = p_i_inst_code 
          AND cbp_param_name = 'Max Card Balance' 
          AND cbp_profile_code = v_varchar2_profile_code;

          EXCEPTION
              WHEN OTHERS THEN
               v_varchar2_resp_cde := '21';
               v_varchar2_respmsg  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                          SUBSTR(SQLERRM, 1, 200);
               RAISE E_REJECT_RECORD;
      END;


        IF ((v_number_toacct_bal) > v_number_max_card_bal)
            OR ((v_number_toacct_bal + v_number_txn_amt) > v_number_max_card_bal)
        THEN
               v_varchar2_resp_cde := '30';
               v_varchar2_respmsg := 'EXCEEDING MAXIMUM CARD BALANCE';
                RAISE E_REJECT_RECORD;
        END IF;

        BEGIN
              UPDATE CMS_ACCT_MAST
              SET    CAM_ACCT_BAL   = CAM_ACCT_BAL + v_number_txn_amt,
                     CAM_LEDGER_BAL = CAM_LEDGER_BAL + v_number_txn_amt
              WHERE  CAM_INST_CODE = p_i_inst_code AND
                     CAM_ACCT_NO =v_varchar2_toacctnumber;

              IF SQL%ROWCOUNT = 0 THEN
                 v_varchar2_resp_cde := '21';
                 v_varchar2_respmsg  := 'To account number not updated ';
                 RAISE E_REJECT_RECORD;
              END IF;

              EXCEPTION

                WHEN E_REJECT_RECORD THEN
                RAISE;

                WHEN OTHERS THEN
                   v_varchar2_resp_cde := '21';
                   v_varchar2_respmsg  := 'Error while updating to acct no ' ||
                              SUBSTR(SQLERRM, 1, 200);
                RAISE E_REJECT_RECORD;
        END;

      BEGIN    

        IF TRIM(v_varchar2_trans_desc) IS NOT NULL THEN

            v_varchar2_narration := v_varchar2_trans_desc || '/';

        END IF;

        IF TRIM(v_varchar2_ctoc_auth_id) IS NOT NULL THEN

            v_varchar2_narration := v_varchar2_narration || v_varchar2_ctoc_auth_id || '/';

        END IF;

        IF TRIM(v_number_acct_number) IS NOT NULL THEN

            v_varchar2_narration := v_varchar2_narration || v_number_acct_number || '/';

        END IF;

        IF TRIM(p_i_business_date) IS NOT NULL THEN

            v_varchar2_narration := v_varchar2_narration || p_i_business_date;

        END IF;

      EXCEPTION   
        WHEN OTHERS THEN    
           v_varchar2_resp_cde := '21';
           v_varchar2_respmsg  := 'Error in finding the narration ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE E_REJECT_RECORD;   
      END;

      BEGIN
	  
	            --Added for VMS-5735/FSP-991
                 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
                 INTO   v_Retperiod 
                 FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
                 WHERE  OPERATION_TYPE='ARCHIVE' 
                 AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
				 
				 v_Retdate := TO_DATE(SUBSTR(TRIM(p_i_business_date), 1, 8), 'yyyymmdd');
				 
		IF (v_Retdate>v_Retperiod)  THEN		                                --Added for VMS-5735/FSP-991
				 
                  UPDATE CMS_TRANSACTION_LOG_DTL
                  SET    CTD_DEVICE_ID=p_i_device_id,
                         CTD_HASHKEY_ID=v_varchar2_hashkey_id
                  WHERE CTD_RRN=p_i_rrn AND CTD_BUSINESS_DATE=p_i_business_date
                  AND   CTD_BUSINESS_TIME=p_i_business_time
                  AND   CTD_DELIVERY_CHANNEL=p_i_del_channel
                  AND   CTD_TXN_CODE=p_i_txn_code
                  AND   CTD_MSG_TYPE=p_i_msg_type
                  AND   CTD_INST_CODE=p_i_inst_code;
				  
		ELSE
		
		          UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST        --Added for VMS-5735/FSP-991
                  SET    CTD_DEVICE_ID=p_i_device_id,
                        CTD_HASHKEY_ID=v_varchar2_hashkey_id
                  WHERE CTD_RRN=p_i_rrn AND CTD_BUSINESS_DATE=p_i_business_date
                  AND   CTD_BUSINESS_TIME=p_i_business_time
                  AND   CTD_DELIVERY_CHANNEL=p_i_del_channel
                  AND   CTD_TXN_CODE=p_i_txn_code
                  AND   CTD_MSG_TYPE=p_i_msg_type
                  AND   CTD_INST_CODE=p_i_inst_code;
				  
		END IF;

                   IF SQL%ROWCOUNT = 0 THEN
                        v_varchar2_respmsg  := 'Not updated CMS_TRANSACTION_LOG_DTL ';
                        p_o_resp_code := '21';
                    RAISE E_REJECT_RECORD;
                   END IF;

                 EXCEPTION
                   WHEN E_REJECT_RECORD THEN
                   RAISE E_REJECT_RECORD;
                   WHEN OTHERS THEN
                    p_o_resp_code := '21';
                    v_varchar2_respmsg  := 'Problem on updated cms_Transaction_log_dtl ' ||
                    SUBSTR(SQLERRM, 1, 200);
                     RAISE E_REJECT_RECORD;
      END;

        BEGIN
          v_varchar2_dr_cr_flag := 'CR';
      
               INSERT INTO CMS_STATEMENTS_LOG
               (CSL_PAN_NO,
                CSL_OPENING_BAL,
                CSL_TRANS_AMOUNT,
                CSL_TRANS_TYPE,
                CSL_TRANS_DATE,
                CSL_CLOSING_BALANCE,
                CSL_TRANS_NARRRATION,
                CSL_PAN_NO_ENCR,
                CSL_RRN,
                CSL_AUTH_ID,
                CSL_BUSINESS_DATE,
                CSL_BUSINESS_TIME,
                TXN_FEE_FLAG,
                CSL_DELIVERY_CHANNEL,
                CSL_INST_CODE,
                CSL_TXN_CODE,
                CSL_ACCT_NO,
                CSL_INS_USER,
                CSL_INS_DATE,
                CSL_PANNO_LAST4DIGIT,
                CSL_ACCT_TYPE,
                CSL_time_stamp,
                CSL_PROD_CODE,csl_card_type
                )
                VALUES
               (p_i_to_hash_card_no,
                v_number_toledger_bal,
                v_number_txn_amt,
                'CR',
                v_date_tran_date,
                v_number_toledger_bal + v_number_txn_amt,
                v_varchar2_narration,
                p_i_to_encr_pan,
                p_i_rrn,
                v_varchar2_ctoc_auth_id,
                p_i_business_date,
                p_i_business_time,
                'N',
                p_i_del_channel,
                p_i_inst_code,
                p_i_txn_code,
                v_varchar2_toacct_no,
                1,
                SYSDATE,
                (SUBSTR(p_i_to_card_no, LENGTH(p_i_to_card_no) -3,LENGTH(p_i_to_card_no))),
                v_number_toacct_type,
                v_time_stamp,
                v_varchar2_toprodcode,v_number_tocardtype
                );

              EXCEPTION
                WHEN OTHERS THEN
                   v_varchar2_resp_cde := '21';
                   v_varchar2_respmsg  := 'Error creating entry in statement log ';
                 RAISE E_REJECT_RECORD;
      
        END;

        BEGIN
		
		--Added for VMS-5735/FSP-991
		    select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			INTO   v_Retperiod 
			FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
			WHERE  OPERATION_TYPE='ARCHIVE' 
			AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
            v_Retdate := TO_DATE(SUBSTR(TRIM(p_i_business_date), 1, 8), 'yyyymmdd');
			
		
         IF (v_Retdate>v_Retperiod) THEN

            UPDATE CMS_STATEMENTS_LOG
            SET   csl_time_stamp = v_time_stamp
            WHERE csl_pan_no = p_i_from_hash_card_no
            AND   csl_rrn = p_i_rrn
            AND   csl_delivery_channel=p_i_del_channel
            AND   csl_txn_code = p_i_txn_code
            AND   csl_business_date = p_i_business_date
            AND   csl_business_time = p_i_business_time;
		
         ELSE

            UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST              --Added for VMS-5735/FSP-991
            SET   csl_time_stamp = v_time_stamp
            WHERE csl_pan_no = p_i_from_hash_card_no
            AND   csl_rrn = p_i_rrn
            AND   csl_delivery_channel=p_i_del_channel
            AND   csl_txn_code = p_i_txn_code
            AND   csl_business_date = p_i_business_date
            AND   csl_business_time = p_i_business_time;
		
			
	     END IF;

            IF sql%rowcount = 0
            THEN  
               v_varchar2_resp_cde := '21';
               v_varchar2_respmsg  := 'Timestamp not updated in statement log';
                RAISE E_REJECT_RECORD;  
            END IF;

              EXCEPTION 
              WHEN E_REJECT_RECORD
              THEN RAISE;
              WHEN OTHERS
              THEN      
                  v_varchar2_resp_cde := '21';
                  v_varchar2_respmsg  := 'Error while updating timestamp in statement log '||substr(sqlerrm,1,100);
                  RAISE E_REJECT_RECORD;
        END;

       BEGIN
	   
	   
             select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
             INTO   v_Retperiod 
             FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
             WHERE  OPERATION_TYPE='ARCHIVE' 
             AND OBJECT_NAME='TRANSACTIONLOG_EBR';
			 
			 v_Retdate := TO_DATE(SUBSTR(TRIM(p_i_business_date ), 1, 8), 'yyyymmdd');      
			
			IF (v_Retdate>v_Retperiod) THEN
			
            UPDATE TRANSACTIONLOG
            SET    TOPUP_CARD_NO        = p_i_to_hash_card_no,
                   TOPUP_CARD_NO_ENCR   = p_i_to_encr_pan,
                   TOPUP_ACCT_NO        = v_varchar2_toacctnumber,
                   TOPUP_ACCT_BALANCE   = v_number_toacct_bal+v_number_txn_amt,
                   TOPUP_LEDGER_BALANCE = v_number_toledger_bal+v_number_txn_amt,
                   TOPUP_ACCT_TYPE      = v_number_toacct_type,
                   TIME_STAMP           = v_time_stamp,
                   UUID                 = p_i_uuid,
                   OS_NAME              = p_i_osname,
                   OS_VERSION           = p_i_osversion,
                   GPS_COORDINATES      = p_i_gpscoordinates,
                   DISPLAY_RESOLUTION   = p_i_displayresolution,
                   PHYSICAL_MEMORY      = p_i_physicalmemory,
                   APP_NAME             = p_i_appname,
                   APP_VERSION          = p_i_appversion,
                   SESSION_ID           = p_i_sessionid,
                   DEVICE_COUNTRY       = p_i_devicecountry,
                   DEVICE_REGION        = p_i_deviceregion,
                   IP_COUNTRY           = p_i_ipcountry,
                   PROXY_FLAG           = p_i_proxy,
                   REQ_PARTNER_ID       = p_i_partner_id,
                   ANI                  = p_i_ani,
                   DNI                  = p_i_dni,
                   IPADDRESS            = p_i_ip_addr,
                   REMARK               = p_i_comments,
                   TRAN_REVERSE_FLAG    = 'N'
                WHERE  RRN = p_i_rrn 
                AND    DELIVERY_CHANNEL     = p_i_del_channel 
                AND    TXN_CODE             = p_i_txn_code 
                AND    BUSINESS_DATE        = p_i_business_date 
                AND    BUSINESS_TIME        = p_i_business_time 
                AND    CUSTOMER_CARD_NO     = p_i_from_hash_card_no;
			
	        ELSE
			
			  UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST               --Added for VMS-5733/FSP-991
                SET    TOPUP_CARD_NO        = p_i_to_hash_card_no,
                   TOPUP_CARD_NO_ENCR   = p_i_to_encr_pan,
                   TOPUP_ACCT_NO        = v_varchar2_toacctnumber,
                   TOPUP_ACCT_BALANCE   = v_number_toacct_bal+v_number_txn_amt,
                   TOPUP_LEDGER_BALANCE = v_number_toledger_bal+v_number_txn_amt,
                   TOPUP_ACCT_TYPE      = v_number_toacct_type,
                   TIME_STAMP           = v_time_stamp,
                   UUID                 = p_i_uuid,
                   OS_NAME              = p_i_osname,
                   OS_VERSION           = p_i_osversion,
                   GPS_COORDINATES      = p_i_gpscoordinates,
                   DISPLAY_RESOLUTION   = p_i_displayresolution,
                   PHYSICAL_MEMORY      = p_i_physicalmemory,
                   APP_NAME             = p_i_appname,
                   APP_VERSION          = p_i_appversion,
                   SESSION_ID           = p_i_sessionid,
                   DEVICE_COUNTRY       = p_i_devicecountry,
                   DEVICE_REGION        = p_i_deviceregion,
                   IP_COUNTRY           = p_i_ipcountry,
                   PROXY_FLAG           = p_i_proxy,
                   REQ_PARTNER_ID       = p_i_partner_id,
                   ANI                  = p_i_ani,
                   DNI                  = p_i_dni,
                   IPADDRESS            = p_i_ip_addr,
                   REMARK               = p_i_comments,
                   TRAN_REVERSE_FLAG    = 'N'
                WHERE  RRN = p_i_rrn 
                AND    DELIVERY_CHANNEL     = p_i_del_channel 
                AND    TXN_CODE             = p_i_txn_code 
                AND    BUSINESS_DATE        = p_i_business_date 
                AND    BUSINESS_TIME        = p_i_business_time 
                AND    CUSTOMER_CARD_NO     = p_i_from_hash_card_no;
			
			END IF;
      
              IF SQL%ROWCOUNT <> 1 THEN
                 v_varchar2_resp_cde := '21';
                 v_varchar2_respmsg  := 'Error while updating transactionlog no valid records ';
                 RAISE E_REJECT_RECORD;
              END IF;
      
              EXCEPTION
                WHEN E_REJECT_RECORD THEN
                 RAISE;
                WHEN OTHERS THEN
                 v_varchar2_resp_cde := '21';
                 v_varchar2_respmsg  := 'Error while updating transactionlog ' ||
                            SUBSTR(SQLERRM, 1, 200);
                 RAISE E_REJECT_RECORD;
      
        END;
 
  P_O_RESP_CODE := '00';
      IF p_o_resp_msg = 'OK' OR p_o_resp_msg IS NULL THEN
        BEGIN
           SELECT TRIM(TO_CHAR (cam_acct_bal, '99999999999999990.99'))
             INTO v_number_toacct_bal
             FROM CMS_ACCT_MAST
            WHERE CAM_INST_CODE = p_i_inst_code AND
                 CAM_ACCT_NO =v_number_acct_number;
           P_O_RESP_MSG := v_number_toacct_bal;
            EXCEPTION
               WHEN OTHERS THEN
                 v_varchar2_resp_cde := '21';
                 v_varchar2_respmsg  := 'Error while selecting CMS_ACCT_MAST' ||
                            SUBSTR(SQLERRM, 1, 200);
                 RAISE E_REJECT_RECORD;
            END;
      END IF;

      BEGIN
            IF v_char_prfl_flag = 'Y'
            THEN
               pkg_limits_check.sp_limitcnt_reset (p_i_inst_code,
                                                   NULL,
                                                   v_number_txn_amt,
                                                   v_type_comb_hash,
                                                   v_varchar2_resp_cde,
                                                   v_varchar2_respmsg
                                                  );
            END IF;
    
            IF v_varchar2_resp_cde <> '00' AND v_varchar2_respmsg <> 'OK'
            THEN
               v_varchar2_respmsg := 'From Procedure sp_limitcnt_reset' || v_varchar2_respmsg;
               RAISE E_REJECT_RECORD;
            END IF;
             EXCEPTION
                WHEN E_REJECT_RECORD
                THEN
                   RAISE;
                WHEN OTHERS
                THEN
                   v_varchar2_resp_cde := '21';
                   v_varchar2_respmsg :=
                         'Error from Limit Reset Count Process '
                      || SUBSTR (SQLERRM, 1, 200);
                  RAISE E_REJECT_RECORD;
      END;

      BEGIN
          SELECT SUM(csl_trans_amount) INTO P_O_FEE_AMT
          FROM VMSCMS.CMS_STATEMENTS_LOG
          WHERE txn_fee_flag='Y'
          AND csl_delivery_channel=p_i_del_channel
          AND csl_txn_code=p_i_txn_code
          AND csl_pan_no= P_I_FROM_HASH_CARD_NO
          AND csl_rrn=p_i_rrn
          and csl_inst_code=p_i_inst_code;
        EXCEPTION
            WHEN no_data_found then
                P_O_FEE_AMT:=0;
    
            WHEN OTHERS  THEN
                v_varchar2_resp_cde := '21';
                v_varchar2_respmsg :=  'Error while selecting CMS_STATEMENTS_LOG ' || SUBSTR (SQLERRM, 1, 200);
                RAISE E_REJECT_RECORD;
      END;

EXCEPTION
  WHEN E_REJECT_RECORD THEN
        ROLLBACK ;
  
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code
         INTO v_number_acct_balance, v_number_ledger_balance,
              v_number_frmacct_type
         FROM CMS_ACCT_MAST
         WHERE CAM_ACCT_NO =v_number_acct_number AND
               CAM_INST_CODE = p_i_inst_code;
          EXCEPTION
           WHEN OTHERS THEN
             v_number_acct_balance   := 0;
             v_number_ledger_balance := 0;
      END;


     IF v_varchar2_toacctnumber IS NULL
     THEN

         BEGIN

              SELECT CAP_ACCT_NO
              INTO   v_varchar2_toacctnumber
              FROM   CMS_APPL_PAN
              WHERE  CAp_inst_code = p_i_inst_code
              AND    CAP_PAN_CODE  = P_I_TO_HASH_CARD_NO;

               EXCEPTION WHEN OTHERS THEN
                  null;
      
          END;

      END IF;


      BEGIN
        SELECT cam_acct_bal, cam_acct_no,cam_ledger_bal,
               cam_type_code
         INTO v_number_toacct_bal, v_varchar2_toacct_no,v_number_toledger_bal,
              v_number_toacct_type
         FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = p_i_inst_code AND
             CAM_ACCT_NO =  v_varchar2_toacctnumber;

          EXCEPTION
            WHEN OTHERS THEN
            null;
      END;

    BEGIN
     SELECT cms_iso_respcde
       INTO p_o_resp_code
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = p_i_inst_code AND
           CMS_DELIVERY_CHANNEL = p_i_del_channel AND
           CMS_RESPONSE_ID = v_varchar2_resp_cde;
      
        p_o_resp_msg := v_varchar2_respmsg;
        EXCEPTION
         WHEN OTHERS THEN
           p_o_resp_msg  := 'Problem while selecting data from response master ' ||
                       v_varchar2_resp_cde || SUBSTR(SQLERRM, 1, 300);
           p_o_resp_code := '69';
    END;

     BEGIN
       INSERT INTO TRANSACTIONLOG
                (MSGTYPE,
                 RRN,
                 DELIVERY_CHANNEL,
                 TERMINAL_ID,
                 DATE_TIME,
                 TXN_CODE,
                 TXN_TYPE,
                 TXN_MODE,
                 TXN_STATUS,
                 RESPONSE_CODE,
                 BUSINESS_DATE,
                 BUSINESS_TIME,
                 CUSTOMER_CARD_NO,
                 TOPUP_CARD_NO,
                 TOPUP_ACCT_NO,
                 TOPUP_ACCT_TYPE,
                 BANK_CODE,
                 TOTAL_AMOUNT,
                 CURRENCYCODE,
                 ADDCHARGE,
                 PRODUCTID,
                 CATEGORYID,
                 ATM_NAME_LOCATION,
                 AUTH_ID,
                 AMOUNT,
                 PREAUTHAMOUNT,
                 PARTIALAMOUNT,
                 INSTCODE,
                 CUSTOMER_CARD_NO_ENCR,
                 TOPUP_CARD_NO_ENCR,
                 PROXY_NUMBER,
                 REVERSAL_CODE,
                 CUSTOMER_ACCT_NO,
                 ACCT_BALANCE,
                 LEDGER_BALANCE,
                 RESPONSE_ID,
                 ANI,
                 DNI,
                 IPADDRESS,
                 CARDSTATUS,
                 TRANS_DESC,
                 ERROR_MSG,
                 TOPUP_ACCT_BALANCE ,
                 TOPUP_LEDGER_BALANCE,
                 ACCT_TYPE,
                 TIME_STAMP,
                 CR_DR_FLAG,
                 REMARK,
                 UUID,
                 OS_NAME,
                 OS_VERSION,
                 GPS_COORDINATES,
                 DISPLAY_RESOLUTION,
                 PHYSICAL_MEMORY,
                 APP_NAME,
                 APP_VERSION,
                 SESSION_ID,
                 DEVICE_COUNTRY,
                 DEVICE_REGION,
                 IP_COUNTRY,
                 PROXY_FLAG,
                 REQ_PARTNER_ID,
                 TRAN_REVERSE_FLAG
                 )
               VALUES
                ('0200',
                 p_i_rrn,
                 p_i_del_channel,
                 0,
                 TO_DATE(p_i_business_date, 'YYYY/MM/DD'),
                 p_i_txn_code,
                 v_varchar2_txn_type,
                 0,
                 DECODE(p_o_resp_code, '00', 'C', 'F'),
                 p_o_resp_code,
                 p_i_business_date,
                 SUBSTR(p_i_business_time, 1, 10),
                 P_I_FROM_HASH_CARD_NO,
                 P_I_TO_HASH_CARD_NO,
                 v_varchar2_toacctnumber,
                 v_number_toacct_type,
                 p_i_inst_code,
                 TRIM(TO_CHAR(nvl(v_number_txn_amt,0), '99999999999999990.99')),
                 p_i_curr_code,
                 NULL,
                 v_varchar2_from_prodcode,
                 v_number_from_cardtype,
                 0,
                 v_varchar2_ctoc_auth_id,
                 TRIM(TO_CHAR(nvl(v_number_txn_amt,0), '99999999999999990.99')),
                 '0.00',
                 '0.00',
                 p_i_inst_code,
                 P_I_FROM_ENCR_PAN,
                 P_I_TO_ENCR_PAN,
                 '',
                 0,
                 v_number_acct_number,
                 nvl(v_number_acct_balance,0),
                 nvl(v_number_ledger_balance,0),
                 v_varchar2_resp_cde,
                 p_i_ani,
                 p_i_dni,
                 p_i_ip_addr,
                 v_varchar2_fromcardstat,
                 v_varchar2_trans_desc,
                 v_varchar2_respmsg,
                 nvl(v_number_toacct_bal,0),
                 nvl(v_number_toledger_bal,0),
                 v_number_frmacct_type,
                 v_time_stamp,
                 v_varchar2_dr_cr_flag,
                p_i_comments,
                p_i_uuid,
                p_i_osname,
                p_i_osversion,
                p_i_gpscoordinates,
                p_i_displayresolution,
                p_i_physicalmemory,
                p_i_appname,
                p_i_appversion,
                p_i_sessionid,
                p_i_devicecountry,
                p_i_deviceregion,
                p_i_ipcountry,
                p_i_proxy,
                p_i_partner_id,
                'N'
                );

             EXCEPTION
               WHEN OTHERS THEN
        
                p_o_resp_code := '89';
                p_o_resp_msg  := 'Problem while inserting data into transaction log  dtl' ||
                            SUBSTR(SQLERRM, 1, 300);
     END;

    BEGIN
    
     INSERT INTO CMS_TRANSACTION_LOG_DTL
                 (CTD_DELIVERY_CHANNEL,
                  CTD_TXN_CODE,
                  CTD_TXN_TYPE,
                  CTD_TXN_MODE,
                  CTD_BUSINESS_DATE,
                  CTD_BUSINESS_TIME,
                  CTD_CUSTOMER_CARD_NO,
                  CTD_TXN_AMOUNT,
                  CTD_TXN_CURR,
                  CTD_ACTUAL_AMOUNT,
                  CTD_FEE_AMOUNT,
                  CTD_WAIVER_AMOUNT,
                  CTD_SERVICETAX_AMOUNT,
                  CTD_CESS_AMOUNT,
                  CTD_BILL_AMOUNT,
                  CTD_BILL_CURR,
                  CTD_PROCESS_FLAG,
                  CTD_PROCESS_MSG,
                  CTD_RRN,
                  CTD_SYSTEM_TRACE_AUDIT_NO,
                  CTD_LUPD_DATE,
                  CTD_INST_CODE,
                  CTD_LUPD_USER,
                  CTD_INS_DATE,
                  CTD_INS_USER,
                  CTD_CUSTOMER_CARD_NO_ENCR,
                  CTD_MSG_TYPE,
                  REQUEST_XML,
                  CTD_CUST_ACCT_NUMBER,
                  CTD_ADDR_VERIFY_RESPONSE,
                  CTD_DEVICE_ID,CTD_HASHKEY_ID
                  )
                VALUES
                 (p_i_del_channel,
                  p_i_txn_code,
                  v_varchar2_txn_type,
                  p_i_txn_mode,
                  p_i_business_date,
                  p_i_business_time,
                  p_i_from_hash_card_no,
                  v_number_txn_amt,
                  p_i_curr_code,
                  v_number_txn_amt,
                  NULL,
                  NULL,
                  NULL,
                  NULL,
                  v_number_txn_amt,
                  p_i_curr_code,
                  'E',
                  v_varchar2_respmsg,
                  p_i_rrn,
                  P_I_STAN,
                  SYSDATE,
                  p_i_inst_code,
                  1,
                  SYSDATE,
                  1,
                  p_i_from_encr_pan,
                  '000',
                  '',
                  v_number_acct_number,
                  '',
                  p_i_device_id,v_varchar2_hashkey_id
                  );
                      p_o_resp_msg := v_varchar2_respmsg;
    
            EXCEPTION
             WHEN OTHERS THEN
               p_o_resp_msg  := 'Problem while inserting data into transaction log  dtl' ||
                           SUBSTR(SQLERRM, 1, 300);
               p_o_resp_code := '99';
         END;

          WHEN OTHERS THEN
          ROLLBACK ;
          v_varchar2_resp_cde := '69';
          p_o_resp_msg  := 'Error from transaction processing ' ||
                     SUBSTR(SQLERRM, 1, 90);

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code
         INTO v_number_acct_balance, v_number_ledger_balance,
              v_number_frmacct_type
         FROM CMS_ACCT_MAST
         WHERE CAM_ACCT_NO =v_number_acct_number AND
               CAM_INST_CODE = p_i_inst_code;
          EXCEPTION
           WHEN OTHERS THEN
             v_number_acct_balance   := 0;
             v_number_ledger_balance := 0;
      END;


     IF v_varchar2_toacctnumber IS NULL
     THEN

         BEGIN

              SELECT CAP_ACCT_NO
              INTO   v_varchar2_toacctnumber
              FROM   CMS_APPL_PAN
              WHERE  CAp_inst_code = p_i_inst_code
              AND    CAP_PAN_CODE  = P_I_TO_HASH_CARD_NO;

               EXCEPTION WHEN OTHERS THEN
                  null;

          END;

      END IF;


      BEGIN
        SELECT cam_acct_bal, cam_acct_no,cam_ledger_bal,
               cam_type_code
        INTO v_number_toacct_bal, v_varchar2_toacct_no,v_number_toledger_bal,
              v_number_toacct_type
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = p_i_inst_code AND
             CAM_ACCT_NO =  v_varchar2_toacctnumber;
    
          EXCEPTION
            WHEN OTHERS THEN
            NULL;
      END;

      BEGIN
         SELECT CMS_ISO_RESPCDE
           INTO p_o_resp_code
           FROM CMS_RESPONSE_MAST
          WHERE CMS_INST_CODE = p_i_inst_code AND
               CMS_DELIVERY_CHANNEL = p_i_del_channel AND
               CMS_RESPONSE_ID = v_varchar2_resp_cde;


            EXCEPTION
             WHEN OTHERS THEN
               p_o_resp_msg  := 'Problem while selecting data from response master ' ||
                           v_varchar2_resp_cde || SUBSTR(SQLERRM, 1, 300);
               p_o_resp_code := '99';
    END;


    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
               (CTD_DELIVERY_CHANNEL,
                CTD_TXN_CODE,
                CTD_TXN_TYPE,
                CTD_TXN_MODE,
                CTD_BUSINESS_DATE,
                CTD_BUSINESS_TIME,
                CTD_CUSTOMER_CARD_NO,
                CTD_TXN_AMOUNT,
                CTD_TXN_CURR,
                CTD_ACTUAL_AMOUNT,
                CTD_FEE_AMOUNT,
                CTD_WAIVER_AMOUNT,
                CTD_SERVICETAX_AMOUNT,
                CTD_CESS_AMOUNT,
                CTD_BILL_AMOUNT,
                CTD_BILL_CURR,
                CTD_PROCESS_FLAG,
                CTD_PROCESS_MSG,
                CTD_RRN,
                CTD_SYSTEM_TRACE_AUDIT_NO,
                CTD_LUPD_DATE,
                CTD_INST_CODE,
                CTD_LUPD_USER,
                CTD_INS_DATE,
                CTD_INS_USER,
                CTD_CUSTOMER_CARD_NO_ENCR,
                CTD_MSG_TYPE,
                REQUEST_XML,
                CTD_CUST_ACCT_NUMBER,
                CTD_ADDR_VERIFY_RESPONSE,
                CTD_DEVICE_ID,CTD_HASHKEY_ID
                )
             VALUES
               (p_i_del_channel,
                p_i_txn_code,
                v_varchar2_txn_type,
                P_I_TXN_MODE,
                p_i_business_date,
                p_i_business_time,
                P_I_FROM_HASH_CARD_NO,
                v_number_txn_amt,
                p_i_curr_code,
                v_number_txn_amt,
                NULL,
                NULL,
                NULL,
                NULL,
                v_number_txn_amt,
                p_i_curr_code,
                'E',
                v_varchar2_respmsg,
                p_i_rrn,
                P_I_STAN,
                SYSDATE,
                p_i_inst_code,
                1,
                SYSDATE,
                1,
                P_I_FROM_ENCR_PAN,
                '000',
                '',
                v_number_acct_number,
                '',
                p_i_device_id,v_varchar2_hashkey_id
          );
              EXCEPTION
               WHEN OTHERS THEN
                 p_o_resp_msg  := 'Problem while inserting data into transaction log  dtl' ||
                             SUBSTR(SQLERRM, 1, 300);
                 p_o_resp_code := '99';
      END;

     BEGIN
       INSERT INTO TRANSACTIONLOG
                  (MSGTYPE,
                   RRN,
                   DELIVERY_CHANNEL,
                   TERMINAL_ID,
                   DATE_TIME,
                   TXN_CODE,
                   TXN_TYPE,
                   TXN_MODE,
                   TXN_STATUS,
                   RESPONSE_CODE,
                   BUSINESS_DATE,
                   BUSINESS_TIME,
                   CUSTOMER_CARD_NO,
                   TOPUP_CARD_NO,
                   TOPUP_ACCT_NO,
                   TOPUP_ACCT_TYPE,
                   BANK_CODE,
                   TOTAL_AMOUNT,
                   CURRENCYCODE,
                   ADDCHARGE,
                   PRODUCTID,
                   CATEGORYID,
                   ATM_NAME_LOCATION,
                   AUTH_ID,
                   AMOUNT,
                   PREAUTHAMOUNT,
                   PARTIALAMOUNT,
                   INSTCODE,
                   CUSTOMER_CARD_NO_ENCR,
                   TOPUP_CARD_NO_ENCR,
                   PROXY_NUMBER,
                   REVERSAL_CODE,
                   CUSTOMER_ACCT_NO,
                   ACCT_BALANCE,
                   LEDGER_BALANCE,
                   RESPONSE_ID,
                   ANI,
                   DNI,
                   IPADDRESS,
                   CARDSTATUS,
                   TRANS_DESC,
                   ERROR_MSG,
                   TOPUP_ACCT_BALANCE ,
                   TOPUP_LEDGER_BALANCE,
                   ACCT_TYPE,
                   TIME_STAMP,
                   CR_DR_FLAG,
                   REMARK,
                   UUID,
                   OS_NAME,
                   OS_VERSION,
                   GPS_COORDINATES,
                   DISPLAY_RESOLUTION,
                   PHYSICAL_MEMORY,
                   APP_NAME,
                   APP_VERSION,
                   SESSION_ID,
                   DEVICE_COUNTRY,
                   DEVICE_REGION,
                   IP_COUNTRY,
                   PROXY_FLAG,
                   REQ_PARTNER_ID,
                   TRAN_REVERSE_FLAG
                   )
                 VALUES
                  ('0200',
                   p_i_rrn,
                   p_i_del_channel,
                   0,
                   TO_DATE(p_i_business_date, 'YYYY/MM/DD'),
                   p_i_txn_code,
                   v_varchar2_txn_type,
                   0,
                   DECODE(p_o_resp_code, '00', 'C', 'F'),
                   p_o_resp_code,
                   p_i_business_date,
                   SUBSTR(p_i_business_time, 1, 10),
                   P_I_FROM_HASH_CARD_NO,
                    P_I_TO_HASH_CARD_NO,
                   v_varchar2_toacctnumber,
                   v_number_toacct_type,
                   p_i_inst_code,
                   TRIM(TO_CHAR(nvl(v_number_txn_amt,0), '99999999999999990.99')),
                   p_i_curr_code,
                   NULL,
                   v_varchar2_from_prodcode,
                   v_number_from_cardtype,
                   0,
                   v_varchar2_ctoc_auth_id,
                   TRIM(TO_CHAR(nvl(v_number_txn_amt,0), '99999999999999990.99')),
                   '0.00',
                   '0.00',
                   p_i_inst_code,
                   P_I_FROM_ENCR_PAN,
                   P_I_TO_ENCR_PAN,
                   '',
                   0,
                   v_number_acct_number,
                   nvl(v_number_acct_balance,0),
                   nvl(v_number_ledger_balance,0),
                   v_varchar2_resp_cde,
                   p_i_ani,
                   p_i_dni,
                   p_i_ip_addr,
                   v_varchar2_fromcardstat,
                   v_varchar2_trans_desc,
                   v_varchar2_respmsg,
                   nvl(v_number_toacct_bal,0),
                   nvl(v_number_toledger_bal,0),
                   v_number_frmacct_type,
                   v_time_stamp,
                   v_varchar2_dr_cr_flag,
                   p_i_comments,
                   p_i_uuid,
                   p_i_osname,
                   p_i_osversion,
                   p_i_gpscoordinates,
                   p_i_displayresolution,
                   p_i_physicalmemory,
                   p_i_appname,
                   p_i_appversion,
                   p_i_sessionid,
                   p_i_devicecountry,
                   p_i_deviceregion,
                   p_i_ipcountry,
                   p_i_proxy,
                   p_i_partner_id,
                   'N'
             );

           EXCEPTION
             WHEN OTHERS THEN
      
              p_o_resp_code := '89';
              p_o_resp_msg  := 'Problem while inserting data into transaction log  dtl' ||
                          SUBSTR(SQLERRM, 1, 300);
     END;

END ACCOUNT_TO_ACCOUNT_TRANSFER;


END VMS_ACCOUNTS;

/
show error