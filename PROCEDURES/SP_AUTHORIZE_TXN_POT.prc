create or replace PROCEDURE                             VMSCMS.SP_AUTHORIZE_TXN_POT (
    p_inst_code IN NUMBER,
    p_msg       IN VARCHAR2,
    p_rrn              VARCHAR2,
    p_delivery_channel VARCHAR2,
    p_term_id          VARCHAR2,
    p_txn_code         VARCHAR2,
    p_txn_mode         VARCHAR2,
    p_tran_date        VARCHAR2,
    p_tran_time        VARCHAR2,
    p_card_no          VARCHAR2,
    p_bank_code        VARCHAR2,
    p_txn_amt          NUMBER,
    p_merchant_name    VARCHAR2,
    p_merchant_city    VARCHAR2,
    p_mcc_code         VARCHAR2,
    p_curr_code        VARCHAR2,
    p_pos_verfication  VARCHAR2,
    --Modified by Deepa On June 19 2012 for Fees Changes
    p_catg_id           VARCHAR2,
    p_tip_amt           VARCHAR2,
    p_decline_ruleid    VARCHAR2,
    p_atmname_loc       VARCHAR2,
    p_mcccode_groupid   VARCHAR2,
    p_currcode_groupid  VARCHAR2,
    p_transcode_groupid VARCHAR2,
    p_rules             VARCHAR2,
    p_preauth_date DATE,
    p_consodium_code    IN VARCHAR2,
    p_partner_code      IN VARCHAR2,
    p_expry_date        IN VARCHAR2,
    p_stan              IN VARCHAR2,
    p_mbr_numb          IN VARCHAR2,
    p_preauth_expperiod IN VARCHAR2,
    p_international_ind IN VARCHAR2,
    --Changed the preauth sequence number as international indicator --Sequence no of preAuth transaction
    p_rvsl_code IN NUMBER,
    p_tran_cnt  IN NUMBER,
    /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
    p_network_id         IN VARCHAR2,
    p_interchange_feeamt IN NUMBER,
    p_merchant_zip       IN VARCHAR2,
    /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
    p_network_setl_date IN VARCHAR2,
    -- Added on 201112 for logging N/W settlement date in transactionlog
    p_merchant_id      IN VARCHAR2, --Added on 19-Mar-2013 for FSS-970
    P_NETWORKID_SWITCH IN VARCHAR2, --Added on 20130626 for the Mantis ID 11344
    p_auth_id OUT VARCHAR2,
    p_resp_code OUT VARCHAR2,
    p_resp_msg OUT CLOB,
    p_ledger_bal OUT VARCHAR2,
    p_dda_number OUT VARCHAR2,    --Added by Ramesh.A on 18/07/2012
    p_prod_desc OUT VARCHAR2,     --Added by Ramesh.A on 18/07/2012
    p_prod_cat_desc OUT VARCHAR2, --Added by Ramesh.A on 18/07/2012
    p_fee_plan_id OUT VARCHAR2,   --Added by Ramesh.A on 18/07/2012
    p_card_status OUT VARCHAR2,   --Added by Ramesh.A on 18/07/2012
    p_prod_id OUT VARCHAR2,
    --Added by siva kumar on 01/08/2012.
    p_medagateref_Id IN VARCHAR2 DEFAULT NULL,-- Added for medagate Changes defect id:MVHOST-387
    P_CARD_USEDCNT OUT VARCHAR2               --Added by Abdul Hameed M.A for EEP2.1 on 05/03/2014
    ,p_reasoncode_in in varchar2 default null
    ,p_funding_account IN VARCHAR2 DEFAULT NULL
  )
IS
  /****************************************************************************************************
  * Modified by      : Sagar M.
  * Modified Date    : 04-Feb-13
  * Modified reason  : 1) To subtract surcharge fee (P_INTERCHANGE_FEEAMT) from P_TXN_AMT
  and pass the same to limit process
  2) Error message passed into transactionlog table
  * Modified for     : FSS-821
  * Reviewer         : Dhiraj
  * Reviewed Date    : 05-Feb-13
  * Build Number     : CMS3.5.1_RI0023.2_B0001
  * Modified By      : Pankaj S.
  * Modified Date    : 09-Feb-2013
  * Modified Reason  : Product Category spend limit not being adhered to by VMS
  * Modified By      : Sagar
  * Modified Date    : 12-Feb-2013
  * Modified Reason  : "v_resp_cde := 21" commented on line 2276 while call to sp_limitcnt_reset
  * Reviewer         : Dhiraj
  * Reviewed Date    :
  * Build Number     : CMS3.5.1_RI0023.2_B0001
  * Modified By      : Sagar M.
  * Modified Date    : 19-Mar-2013
  * Modified Reason  : Logging of input merchant id in Transactionlog and
  cms_transaction_log_dtl
  * Modified For     : FSS-970
  * Reviewer         : Dhiraj
  * Reviewed Date    : 19-Mar-2013
  * Build Number     : RI0024_B0009
  * Modified by      : Dhinakaran B
  * Modified Reason  : MVHOST - 346
  * Modified Date    : 20-APR-2013
  * Reviewer         :
  * Reviewed Date    :
  * Build Number     : RI0024.1_B0010
  * Modified By      : Sagar M.
  * Modified Date    : 20-Apr-2013
  * Modified for     : Defect 10871
  * Modified Reason  : Logging of below details in tranasctionlog and statementlog table
  1) ledger balance in statementlog
  2) Product code,Product category code,Card status,Acct Type,drcr flag
  3) Timestamp and Amount values logging correction
  * Reviewer         : Dhiraj
  * Reviewed Date    : 20-Apr-2013
  * Build Number     : RI0024.1_B0013
  * Modified By     : Siva Kumar M
  * Modified Date    : 11-June-2013
  * Modified for     : MVHOST-387
  * Modified Reason  : Changes Done for Medagate Balance inquiry Transaction.
  * Reviewer         :
  * Reviewed Date    :
  * Build Number     :  RI0024.2_B0003
  * Modified by      : Ravi N
  * Modified for        : Mantis ID 0011282
  * Modified Reason  : Correction of Insufficient balance spelling mistake
  * Modified Date    : 20-Jun-2013
  * Reviewer         : Dhiraj
  * Reviewed Date    : 20-Jun-2013
  * Build Number     : RI0024.2_B0006
  * Modified by       : Deepa T
  * Modified for      : Mantis ID 11344
  * Modified Reason   : Log the Network ID as ELAN
  * Modified Date     : 26-Jun-2013
  * Reviewer          : Dhiraj
  * Reviewed Date     : 27-06-2013
  * Build Number      : RI0024.2_B0009
  * Modified by      : Anil Kumar
  * Modified for     : JIRA MVCHW - 454
  * Modified Reason  : Insufficient Balance for Non-financial Transactions.
  * Modified Date    : 16-07-2013
  * Reviewer         :
  * Reviewed Date    :
  * Build Number     : RI0024.3_B0005
  * Modified by      : Anil Kumar
  * Modified for     : Mantis ID 0011792
  * Modified Reason  : Response data issue in Non financial transaction with claw back fees enabled
  * Modified Date    : 26-07-2013
  * Reviewer         : Dhiraj
  * Reviewed Date    :
  * Build Number     : RI0024.3_B0007
  * Modified by       : Sachin P.
  * Modified for      : MVHOST-505
  * Modified Reason   : Balance inquiry issue (Multi-instituion issue)
  * Modified Date     : 05.08.2013
  * Reviewer          : Dhiraj
  * Reviewed Date     : 05.08.2013
  * Build Number      : RI0024.3.1_B0003
  * Modified by       : Siva Kumar M
  * Modified for      : LYFEHOST-73 &  LYFEHOST-74
  * Modified Reason   : Network Acquirer ID & Fee Based on Network
  * Modified Date     : 30.09.2013
  * Reviewer          : Dhiraj
  * Reviewed Date     : 30.09.2013
  * Build Number      : RI0024.5_B0001
  * Modified by       :  Sagar More
  * Modified for      :  Mantis ID- 13063
  * Modified Reason   :  To pass international indicator and pos verfication as null for merchantdise return transactions
  * Modified Date     :  19-Nov-2013
  * Reviewer          :  Sagar
  * Reviewed Date     :  20-Nov-2013
  * Build Number      :  RI0024.6.1_B0002   (RI0024.6.4_B0001)
  * Modified by       :  Sagar More
  * Modified for      :  FSS-1398
  * Modified Reason   :  To include category code while fetching fee plan id from cms_prodcattype_fees
  * Modified Date     :  19-Nov-2013
  * Reviewer          :  Sagar
  * Reviewed Date     :  20-Nov-2013
  * Build Number      :  RI0024.6.2.1_B0001
  * Modified Date    : 10-Dec-2013
  * Modified By      : Sagar More
  * Modified for     : Defect ID 13160
  * Modified reason  : nvl Added for amount logging
  * Reviewer         : Dhiraj
  * Reviewed Date    : 10-Dec-2013
  * Release Number   : RI0027_B0004
  * modified by       : Ramesh A
  * modified Date     : FEB-05-14
  * modified reason   : MVCSD-4471
  * modified reason   :
  * Reviewer          : Dhiraj
  * Reviewed Date     :
  * Build Number      : RI0027.1_B0001
  * Modified by       : Sagar
  * Modified for      :
  * Modified Reason   : Concurrent Processsing Issue
  (1.7.6.7 changes integarted)
  * Modified Date     : 04-Mar-2014
  * Reviewer          : Dhiarj
  * Reviewed Date     : 06-Mar-2014
  * Build Number      : RI0027.1.1_B0001
  * modified by       : Abdul Hameed M.A
  * modified Date     : FEB-25-14
  * modified reason   : Mantis ID 13736
  * modified reason   : To log  the network switch id in transaction log table
  * Reviewer          :
  * Reviewed Date     :
  * Build Number      :

  * Modified by       : Abdul Hameed M.A / Siva Kumar M
  * Modified for      :  Mantis ID 13893/EPP2.1
  * Modified Reason   : Added card number for duplicate RRN check/Medagate card Top-Up.
  * Modified Date     : 06-Mar-2014
  * Reviewer          : Dhiraj
  * Reviewed Date     : 10-Mar-2014
  * Build Number      : RI0027.2_B0002

  * Modified By      : Sankar S
  * Modified Date    : 08-APR-2014
  * Modified for     :
  * Modified Reason  : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
  CMS_STATEMENTS_LOG,TRANSACTIONLOG.
  2.V_TRAN_AMT initial value assigned as zero.
  * Reviewer         : Pankaj S.
  * Reviewed Date    : 08-APR-2014
  * Build Number     : CMS3.5.1_RI0027.2_B0005

  * Modified by       : Deepa T
  * Modified for      :  Mantis ID 14158/EPP2.1
  * Modified Reason   : To apply the limit validation for card topup and to calculate the adjusted amount based on ledger balance also
  * Modified Date     : 11-Apr-2014
  * Reviewer          : spankaj
  * Reviewed Date     : 15-April-2014
  * Build Number      : CMS3.5.1_RI0027.2_B0005

    * modified by       : Amudhan S
    * modified Date     : 23-may-14
    * modified for      : FWR 64
    * modified reason   : To restrict clawback fee entries as per the configuration done by user.
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3_B0001

    * Modified By      :  Mageshkumar S
    * Modified For     :  FWR-48
    * Modified Date    :  25-July-2014
    * Modified Reason  :  GL Mapping Removal Changes.
    * Reviewer         :  Spankaj
    * Build Number     :  RI0027.3.1_B0001

     * Modified Date    : 11-Nov2014
     * Modified By      : Dhinakaran B
     * Modified for     : MVHOST-1041
     * Reviewer         : Spankaj
     * Release Number   : RI0027.4.2.1

     * Modified Date    : 20-Mar-2015
     * Modified By      : Ramesh A
     * Modified for     : FSS-2281
     * Reviewer         : Spankaj
     * Release Number   : 3.0

     * Modified by      : Pankaj S.
     * Modified for     : Transactionlog Functional Removal
     * Modified Date    : 13-May-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOAT_3.0.3_B0001

     * Modified by      : Pankaj S.
     * Modified for     : Transactionlog Functional Removal Phase-II changes
     * Modified Date    : 11-Aug-2015
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1

    * Modified by      : Ramesh A
    * Modified for     : FSS-3610
    * Modified Date    : 31-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOST_3.1_B0008

    * Modified by      : Pankaj S.
    * Modified Date    : 07/Oct/2016
    * PURPOSE          : FSS-4755
    * Review           : Saravana
    * Build Number     : VMSGPRHOST_4.10
        * Modified by      : Saravanakumar
    * Modified Date    : 20-Mar-17
    * Modified For     : FSS-4647
    * Modified reason  : Redemption Delay Changes
    * Reviewer         : Pankaj S.
    * Build Number     : VMSGPRHOST_17.3

        * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07
    * Modified By      : MageshKumar S
    * Modified Date    : 18/07/2017
    * Purpose          : FSS-5157
    * Reviewer         : Saravanan/Pankaj S.
    * Release Number   : VMSGPRHOST17.07

	* Modified By      : Vini Pushkaran
    * Modified Date    : 24/11/2017
    * Purpose          : VMS-64
    * Reviewer         : Saravanankumar A
    * Release Number   : VMSGPRHOST17.12

	 * Modified By      : DHINAKARAN B
     * Modified Date    : 29-JUN-2018
     * Purpose          : VMS-344
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : VMSGPRHOST R03


	 * Modified By      : Baskar K
     * Modified Date    : 21-AUG-2018
     * Purpose          : VMS-454
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : VMSGPRHOST R05

     * Modified By      : Bhavani E
     * Modified Date    : 11-OCT-2022
     * Purpose          : VMS-5546
     * Reviewer         : VENKAT S.
     * Release Number   : VMSGPRHOST R70
  *****************************************************************************************************/
  v_err_msg      VARCHAR2 (900) := 'OK';
  v_acct_balance NUMBER;
  v_ledger_bal   NUMBER;
  v_tran_amt     NUMBER := 0; --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
  v_auth_id transactionlog.auth_id%TYPE;
  v_total_amt NUMBER;
  v_tran_date DATE;
  v_func_code cms_func_mast.cfm_func_code%TYPE;
  v_prod_code cms_prod_mast.cpm_prod_code%TYPE;
  v_prod_cattype cms_prod_cattype.cpc_card_type%TYPE;
  v_fee_amt         NUMBER;
  v_total_fee       NUMBER;
  v_upd_amt         NUMBER;
  v_upd_ledger_amt  NUMBER;
  v_narration       VARCHAR2 (300);
  v_trans_desc      VARCHAR2 (50);
  v_fee_opening_bal NUMBER;
  v_resp_cde        VARCHAR2 (5);
  v_expry_date DATE;
  v_dr_cr_flag  VARCHAR2 (2);
  v_output_type VARCHAR2 (2);
  v_applpan_cardstat cms_appl_pan.cap_card_stat%TYPE;
  v_atmonline_limit cms_appl_pan.cap_atm_online_limit%TYPE;
  v_posonline_limit cms_appl_pan.cap_atm_offline_limit%TYPE;
  v_precheck_flag pcms_tranauth_param.ptp_param_value%TYPE;
  v_preauth_flag pcms_tranauth_param.ptp_param_value%TYPE;
  v_gl_upd_flag transactionlog.gl_upd_flag%TYPE;
  v_gl_err_msg VARCHAR2 (500);
  v_savepoint  NUMBER := 0;
  v_tran_fee   NUMBER;
  v_error      VARCHAR2 (500);
  v_business_date_tran DATE;
  v_business_time VARCHAR2 (5);
  v_cutoff_time   VARCHAR2 (5);
  v_card_curr     VARCHAR2 (5);
  v_fee_code cms_fee_mast.cfm_fee_code%TYPE;
  v_fee_crgl_catg cms_prodcattype_fees.cpf_crgl_catg%TYPE;
  v_fee_crgl_code cms_prodcattype_fees.cpf_crgl_code%TYPE;
  v_fee_crsubgl_code cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
  v_fee_cracct_no cms_prodcattype_fees.cpf_cracct_no%TYPE;
  v_fee_drgl_catg cms_prodcattype_fees.cpf_drgl_catg%TYPE;
  v_fee_drgl_code cms_prodcattype_fees.cpf_drgl_code%TYPE;
  v_fee_drsubgl_code cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
  v_fee_dracct_no cms_prodcattype_fees.cpf_dracct_no%TYPE;
  --st AND cess
  v_servicetax_percent cms_inst_param.cip_param_value%TYPE;
  v_cess_percent cms_inst_param.cip_param_value%TYPE;
  v_servicetax_amount NUMBER;
  v_cess_amount       NUMBER;
  v_st_calc_flag cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
  v_cess_calc_flag cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
  v_st_cracct_no cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
  v_st_dracct_no cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
  v_cess_cracct_no cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
  v_cess_dracct_no cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
  --
  v_waiv_percnt cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
  v_err_waiv       VARCHAR2 (300);
  v_log_actual_fee NUMBER;
  v_log_waiver_amt NUMBER;
  v_auth_savepoint NUMBER DEFAULT 0;
  v_actual_exprydate DATE;
  v_business_date DATE;
  v_txn_type        NUMBER (1);
  v_mini_totrec     NUMBER (2);
  v_ministmt_errmsg VARCHAR2 (500);
  v_ministmt_output VARCHAR2 (900);
  exp_reject_record EXCEPTION;
  v_atm_usageamnt cms_translimit_check.ctc_atmusage_amt%TYPE;
  v_pos_usageamnt cms_translimit_check.ctc_posusage_amt%TYPE;
  v_atm_usagelimit cms_translimit_check.ctc_atmusage_limit%TYPE;
  v_pos_usagelimit cms_translimit_check.ctc_posusage_limit%TYPE;
  v_mmpos_usageamnt cms_translimit_check.ctc_mmposusage_amt%TYPE;
  v_mmpos_usagelimit cms_translimit_check.ctc_mmposusage_limit%TYPE;
  v_preauth_date DATE;
  v_preauth_hold        VARCHAR2 (1);
  v_preauth_period      NUMBER;
  v_preauth_usage_limit NUMBER;
  v_card_acct_no        VARCHAR2 (20);
  v_hold_amount         NUMBER;
  v_hash_pan cms_appl_pan.cap_pan_code%TYPE;
  v_encr_pan cms_appl_pan.cap_pan_code_encr%TYPE;
  v_rrn_count NUMBER;
  v_tran_type VARCHAR2 (2);
  v_date DATE;
  v_time         VARCHAR2 (10);
  v_max_card_bal NUMBER;
  v_curr_date DATE;
  v_preauth_exp_period VARCHAR2 (10);
 -- v_mini_stat_res CLOB;
  v_mini_stat_val VARCHAR2 (100);
  v_international_flag cms_prod_cattype.cpc_international_check%TYPE;
  v_tran_cnt NUMBER;
  v_proxunumber cms_appl_pan.cap_proxy_number%TYPE;
  v_acct_number cms_appl_pan.cap_acct_no%TYPE;
  v_status_chk NUMBER;
  --Added by Deepa On June 19 2012 for Fees Changes
  v_feeamnt_type cms_fee_mast.cfm_feeamnt_type%TYPE;
  v_per_fees cms_fee_mast.cfm_per_fees%TYPE;
  v_flat_fees cms_fee_mast.cfm_fee_amt%TYPE;
  v_clawback cms_fee_mast.cfm_clawback_flag%TYPE;
  v_fee_plan cms_fee_feeplan.cff_fee_plan%TYPE;
  v_clawback_amnt cms_fee_mast.cfm_fee_amt%TYPE;
  /* Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
  v_comb_hash pkg_limits_check.type_hash;
  v_prfl_code cms_appl_pan.cap_prfl_code%TYPE;
  v_prfl_flag cms_transaction_mast.ctm_prfl_flag%TYPE;
  /* END  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD  */
  v_freetxn_exceed VARCHAR2 (1);
  -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  v_duration VARCHAR2 (20);
  -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  v_feeattach_type VARCHAR2 (2);
  -- Added by Trivikram on 5th Sept 2012
  v_limit_amt NUMBER;
  -- Added on 04-Feb-2013 to Subtract surcharge fee from txn amount and validate the same using limit package
  V_LOGIN_TXN CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE; --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
  V_ACTUAL_FEE_AMNT NUMBER;                            --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
  V_CLAWBACK_COUNT  NUMBER;                            --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
  V_CAM_TYPE_CODE cms_acct_mast.cam_type_code%type;    -- Added on 20-Apr-2013 for defect 10871
  v_timestamp TIMESTAMP;                               -- Added on 20-Apr-2013 for defect 10871
  v_card_stat_desc cms_card_stat.CCS_STAT_DESC%type;   -- Added for medagate Changes defect id:MVHOST-387
  V_NETWORKIDCOUNT NUMBER DEFAULT 0;                   -- lyfe changes.
  v_fee_desc cms_fee_mast.cfm_fee_desc%TYPE;           -- Added for MVCSD-4471
  V_CARD_USEDCNT  NUMBER;                               --ADDED BY ABDUL HAMEED M.A FOR EEP2.1
  v_tran_amt_temp NUMBER;                               --Added for 14158 on 11 Apr 2014
    v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
  v_chrg_dtl_cnt    NUMBER;     -- Added for FWR 64
  v_mrlimitbreach_count  number default 0;
  v_mrminmaxlmt_ignoreflag  VARCHAR2 (1) default 'N';
  v_card_usedflag          cms_appl_pan.cap_card_usedflag%TYPE;   --Added Transactionlog Functional Removal Phase-II changes
  v_card_usedflag_upd   cms_appl_pan.cap_card_usedflag%TYPE;   --Added Transactionlog Functional Removal Phase-II changes
  --SN added for FSS-4647
  v_redemption_delay_flag cms_acct_mast.cam_redemption_delay_flag%type;
  v_delayed_amount number:=0;
   V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;   --Added for JH-10

   --EN added for FSS-4647
 /* CURSOR c_mini_tran
  IS
    SELECT z.*
    FROM
      (SELECT TO_CHAR (csl_trans_date, 'MM/DD/YYYY')
        || ' '
        || csl_trans_type
        || ' '
        || TRIM (TO_CHAR (csl_trans_amount, '99999999999999990.99' ) )
      FROM cms_statements_log
      WHERE csl_pan_no = gethash (p_card_no)
      ORDER BY csl_trans_date DESC
      ) z
  WHERE ROWNUM <= v_tran_cnt; */
BEGIN
  SAVEPOINT v_auth_savepoint;
  v_resp_cde := '1';
  --P_ERR_MSG  := 'OK';
  p_resp_msg  := 'OK';
  v_limit_amt := NVL (p_txn_amt, 0) - NVL (p_interchange_feeamt, 0);
    v_timestamp := systimestamp;
  --Subtracting surcharge fee from txn amount FSS-821 , added on 04-Feb-2013
  BEGIN
    --SN CREATE HASH PAN
    --Gethash is used to hash the original Pan no
    BEGIN
      v_hash_pan := gethash (p_card_no);
    EXCEPTION
    WHEN OTHERS THEN
      v_err_msg := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --EN CREATE HASH PAN
    --SN create encr pan
    --Fn_Emaps_Main is used for Encrypt the original Pan no
    BEGIN
      v_encr_pan := fn_emaps_main (p_card_no);
    EXCEPTION
    WHEN OTHERS THEN
      v_err_msg := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;

        BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||p_card_no||P_RRN||to_char(v_timestamp,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        p_resp_code := '21';
        v_err_msg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
     END;
    --Sn find narration
   /* BEGIN
      SELECT ctm_tran_desc
      INTO v_trans_desc
      FROM cms_transaction_mast
      WHERE ctm_tran_code      = p_txn_code
      AND ctm_delivery_channel = p_delivery_channel
      AND ctm_inst_code        = p_inst_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_trans_desc := 'Transaction type ' || p_txn_code;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END; */
    --Sn generate auth id
    BEGIN
      SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0') INTO v_auth_id FROM DUAL;
    EXCEPTION
    WHEN OTHERS THEN
      v_err_msg  := 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
      v_resp_cde := '21'; -- Server Declined
      RAISE exp_reject_record;
    END;
    --En generate auth id
    --EN create encr pan
 /*   IF p_delivery_channel = '07' AND p_txn_code = '04' THEN
      IF p_tran_cnt      IS NULL THEN
        BEGIN
          SELECT cap_prod_code
          INTO v_prod_code
          FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan
          AND cap_inst_code  = p_inst_code;
          SELECT TO_NUMBER (cbp_param_value)
          INTO v_tran_cnt
          FROM cms_bin_param
          WHERE cbp_inst_code   = p_inst_code
          AND cbp_param_name    = 'TranCount_For_RecentStmt'
          AND cbp_profile_code IN
            (SELECT cpm_profile_code FROM cms_prod_mast WHERE cpm_prod_code = v_prod_code
            );
        EXCEPTION
        WHEN OTHERS THEN
          v_tran_cnt := 10;
        END;
      ELSE
        v_tran_cnt := p_tran_cnt;
      END IF;
    END IF; */
    --SN CHECK INST CODE
    BEGIN
      IF p_inst_code IS NULL THEN
        v_resp_cde   := '12'; -- Invalid Transaction
        v_err_msg    := 'Institute code cannot be null ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '12'; -- Invalid Transaction
      v_err_msg  := 'Institute code cannot be null ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --EN CHECK INST CODE
    BEGIN
      v_date := TO_DATE (SUBSTR (TRIM (p_tran_date), 1, 8), 'yyyymmdd');
    EXCEPTION
    WHEN OTHERS THEN
      v_resp_cde := '45'; -- Server Declined -220509
      v_err_msg  := 'Problem while converting transaction date ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    BEGIN
      v_tran_date := TO_DATE ( SUBSTR (TRIM (p_tran_date), 1, 8) || ' ' || SUBSTR (TRIM (p_tran_time), 1, 10), 'yyyymmdd hh24:mi:ss' );
    EXCEPTION
    WHEN OTHERS THEN
      v_resp_cde := '32'; -- Server Declined -220509
      v_err_msg  := 'Problem while converting transaction time ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En get date
    --Sn find debit and credit flag
    BEGIN
      /* Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
      SELECT ctm_credit_debit_flag,
        ctm_output_type,
        TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
        ctm_tran_type,
        ctm_prfl_flag -- prifile code added for LIMITS BRD
        ,
        CTM_LOGIN_TXN,ctm_tran_desc --Added For Clawback changes (MVHOST - 346)  on 200413
      INTO v_dr_cr_flag,
        v_output_type,
        v_txn_type,
        v_tran_type,
        v_prfl_flag -- prifile code added for LIMITS BRD
        ,
        V_LOGIN_TXN,v_trans_desc
      FROM cms_transaction_mast
      WHERE ctm_tran_code      = p_txn_code
      AND ctm_delivery_channel = p_delivery_channel
      AND ctm_inst_code        = p_inst_code;
      /* Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_resp_cde := '12'; --Ineligible Transaction
      v_err_msg  := 'Transflag  not defined for txn code ' || p_txn_code || ' and delivery channel ' || p_delivery_channel;
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_cde := '21'; --Ineligible Transaction
      v_err_msg  := 'Error while selecting transaction details';
      RAISE exp_reject_record;
    END;
    --En find debit and credit flag
    --Sn Duplicate RRN Check
    /*   BEGIN
    SELECT COUNT (1)
    INTO v_rrn_count
    FROM transactionlog
    WHERE rrn = p_rrn
    AND                                     --Changed for admin dr cr.
    business_date = p_tran_date
    AND delivery_channel = p_delivery_channel;
    --Added by ramkumar.Mk on 25 march 2012
    IF v_rrn_count > 0
    THEN
    v_resp_cde := '22';
    v_err_msg :=
    'Duplicate RRN from the Terminal '
    || p_term_id
    || ' on '
    || p_tran_date;
    RAISE exp_reject_record;
    END IF;
    END;
    */
    -- MODIFIED BY ABDUL HAMEED M.A  ON 06-03-2014
    BEGIN
      sp_dup_rrn_check (v_hash_pan, p_rrn, p_tran_date, p_delivery_channel, p_msg, p_txn_code, v_err_msg );
      IF v_err_msg <> 'OK' THEN
        v_resp_cde := '22';
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '22';
      v_err_msg  := 'Error while  checking RRN' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En Duplicate RRN Check
    --Sn find service tax
    BEGIN
      SELECT cip_param_value
      INTO v_servicetax_percent
      FROM cms_inst_param
      WHERE cip_param_key = 'SERVICETAX'
      AND cip_inst_code   = p_inst_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_resp_cde := '21';
      v_err_msg  := 'Service Tax is  not defined in the system';
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error while selecting service tax from system ';
      RAISE exp_reject_record;
    END;
    --En find service tax
    BEGIN
      IF p_txn_code               = '04' AND p_delivery_channel = '07' THEN
        IF TO_NUMBER (p_tran_cnt) = '0' THEN
          v_resp_cde             := '90';
          v_err_msg              := 'Minimum Transaction Count should be greater than 0 ';
          RAISE exp_reject_record;
        ELSIF TO_NUMBER (p_tran_cnt) > '10' THEN
          v_resp_cde                := '90';
          v_err_msg                 := 'Maximum Transaction Count should not be greater than 10 ';
          RAISE exp_reject_record;
        END IF;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error Occured while finding the service tax' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --Sn find cess
    BEGIN
      SELECT cip_param_value
      INTO v_cess_percent
      FROM cms_inst_param
      WHERE cip_param_key = 'CESS'
      AND cip_inst_code   = p_inst_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_resp_cde := '21';
      v_err_msg  := 'Cess is not defined in the system';
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error while selecting cess from system ';
      RAISE exp_reject_record;
    END;
    --En find cess
    ---Sn find cutoff time
    BEGIN
      SELECT cip_param_value
      INTO v_cutoff_time
      FROM cms_inst_param
      WHERE cip_param_key = 'CUTOFF'
      AND cip_inst_code   = p_inst_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_cutoff_time := 0;
      v_resp_cde    := '21';
      v_err_msg     := 'Cutoff time is not defined in the system';
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error while selecting cutoff  dtl  from system ';
      RAISE exp_reject_record;
    END;
    ---En find cutoff time
    --Sn find card detail
    BEGIN
      /* Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
      SELECT cap_prod_code,
        cap_card_type,
        cap_expry_date,
        cap_card_stat,
        cap_atm_online_limit,
        cap_pos_online_limit,
        cap_proxy_number,
        cap_acct_no,
        cap_prfl_code, -- prifile code added for LIMITS BRD
        cap_card_usedflag  --Added for Transactionlog Functional Removal Phase-II changes
      INTO v_prod_code,
        v_prod_cattype,
        v_expry_date,
        v_applpan_cardstat,
        v_atmonline_limit,
        v_atmonline_limit,
        v_proxunumber,
        v_acct_number,
        v_prfl_code, -- prifile code added for LIMITS BRD
        v_card_usedflag  --Added for Transactionlog Functional Removal Phase-II changes
      FROM cms_appl_pan
      WHERE cap_pan_code = v_hash_pan
      AND cap_inst_code  = p_inst_code;
      /* End  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_resp_cde := '14';
      v_err_msg  := 'CARD NOT FOUND ' || v_hash_pan;
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En find card detail
    --Sn find the tran amt
    IF ((v_tran_type = 'F') OR (p_msg = '0100')) THEN
      IF (p_txn_amt >= 0) THEN
        v_tran_amt  := p_txn_amt;
        BEGIN
          sp_convert_curr (p_inst_code, p_curr_code, p_card_no, p_txn_amt, v_tran_date, v_tran_amt, v_card_curr, v_err_msg,v_prod_code,v_prod_cattype );
          IF v_err_msg <> 'OK' THEN
            v_resp_cde := '44';
            RAISE exp_reject_record;
          END IF;
        EXCEPTION
        WHEN exp_reject_record THEN
          RAISE;
        WHEN OTHERS THEN
          v_resp_cde := '69'; -- Server Declined -220509
          v_err_msg  := 'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
      ELSE
        -- If transaction Amount is zero - Invalid Amount -220509
        v_resp_cde := '43';
        v_err_msg  := 'INVALID AMOUNT';
        RAISE exp_reject_record;
      END IF;
    END IF;
    --En find the tran amt
    --Sn select authorization processe flag
    BEGIN
      SELECT ptp_param_value
      INTO v_precheck_flag
      FROM pcms_tranauth_param
      WHERE ptp_param_name = 'PRE CHECK'
      AND ptp_inst_code    = p_inst_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_resp_cde := '21'; --only for master setups
      v_err_msg  := 'Master set up is not done for Authorization Process';
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_cde := '21'; --only for master setups
      v_err_msg  := 'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En select authorization process   flag
    --Sn select authorization processe flag
    BEGIN
      SELECT ptp_param_value
      INTO v_preauth_flag
      FROM pcms_tranauth_param
      WHERE ptp_param_name = 'PRE AUTH'
      AND ptp_inst_code    = p_inst_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_resp_cde := '21';
      v_err_msg  := 'Master set up is not done for Authorization Process';
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error while selecting PCMS_TRANAUTH_PARAM' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En select authorization process   flag

    --Comment  hardcoded condition for Active-Unregistered card status POS  transaction on 02-Oct-2012 by Ananth Thota
    -- ST Added New card status Active/UnRegistered Card    card 13(Card Status) 02 (POS txn) 14 (txn code)
    /*if V_APPLPAN_CARDSTAT = '13' and  P_DELIVERY_CHANNEL = 02 and P_TXN_CODE = '14'
    then
    if P_POS_VERFICATION <>'S'  then
    V_RESP_CDE := '10';
    V_ERR_MSG  := 'Invalid Card Status ' || V_HASH_PAN;
    RAISE EXP_REJECT_RECORD;
    end if;
    end if;
    */
    -- ET Added New card status Active/UnRegistered Card
    --St Added by Ramesh.A on 18/07/2012 for MMPOS Balance Enquiry
    IF (( p_delivery_channel = '04' AND p_txn_code = '94') OR ( p_delivery_channel = '14' AND p_txn_code = '13' ) ) -- Added for medagate Changes defect id:MVHOST-387
      THEN
      BEGIN
        p_dda_number  := v_acct_number;
        p_card_status := v_applpan_cardstat;
        SELECT cpm_prod_desc,
          cpc_cardtype_desc,
          cpc_program_id,
          ccs.CCS_STAT_DESC -- Added for medagate Changes defect id:MVHOST-387
        INTO p_prod_desc,
          p_prod_cat_desc,
          p_prod_id,       --Added by siva kumar on 01/08/2012.
          v_card_stat_desc -- Added for medagate Changes defect id:MVHOST-387
        FROM cms_prod_mast,
          cms_prod_cattype ,
          cms_card_stat ccs
        WHERE cpm_inst_code  = cpc_inst_code
        AND cpc_inst_code    = p_inst_code
        AND cpc_inst_code    = ccs_inst_code --Added On 05.08.2013 for MVHOST-505
        AND cpm_prod_code    = cpc_prod_code
        AND cpm_prod_code    = v_prod_code
        AND cpc_card_type    = v_prod_cattype
        AND ccs.CCS_STAT_CODE=v_applpan_cardstat;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_err_msg  := 'No Data Found in getting prod desc , prod cattype desc';
        v_resp_cde := '21';
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        v_err_msg  := 'Error while selecting prod desc and prod catype desc ' || SUBSTR (SQLERRM, 1, 200);
        v_resp_cde := '21';
        RAISE exp_reject_record;
      END;
      --ST Added for medagate Changes defect id:MVHOST-387
       IF p_delivery_channel = '14' AND p_txn_code = '13' THEN
        p_prod_cat_desc    := v_card_stat_desc;
        -- ST  ADDED BY ABDUL HAMEED M.A FOR EEP2.1
        --Sn Modified for Transactionlog Functional Removal Phase-II changes
         IF v_card_usedflag IS NULL THEN
            BEGIN
              SELECT COUNT(*)
              INTO V_CARD_USEDCNT
              FROM TRANSACTIONLOG
              WHERE CUSTOMER_CARD_NO=V_HASH_PAN
              AND DELIVERY_CHANNEL  =p_delivery_channel
              AND TXN_CODE NOT     IN ('13','14')
              AND instcode          =p_inst_code;
            EXCEPTION
            WHEN OTHERS THEN
              v_err_msg  := 'Error while GETTING CARD USED DETAILS ' || SUBSTR (SQLERRM, 1, 200);
              v_resp_cde := '21';
              RAISE exp_reject_record;
            END;

           IF (V_CARD_USEDCNT    >0) THEN
            P_CARD_USEDCNT     :=1;
            v_card_usedflag_upd:='Y';
            ELSE
            IF (V_CARD_USEDCNT =0) THEN
              P_CARD_USEDCNT  :=0;
              v_card_usedflag_upd:='N';
            END IF;
           END IF;
         ELSIF  v_card_usedflag='Y' THEN
               P_CARD_USEDCNT     :=1;
         ELSE
               P_CARD_USEDCNT:=0;
         END IF;
         --En Modified for Transactionlog Functional Removal Phase-II changes
        -- EN  ADDED BY ABDUL HAMEED M.A FOR EEP2.1
      END IF;

      -- EN Added for medagate Changes defect id:MVHOST-387
      IF p_delivery_channel <> '14' AND p_txn_code <> '13' THEN -- Added for medagate Changes defect id:MVHOST-387
        BEGIN
          BEGIN
            --Get Fee Plan ID from card level
            SELECT cce_fee_plan
            INTO p_fee_plan_id
            FROM cms_card_excpfee
            WHERE cce_inst_code  = p_inst_code
            AND cce_pan_code     = v_hash_pan
            AND ( (cce_valid_to IS NOT NULL
            AND (v_tran_date BETWEEN cce_valid_from AND cce_valid_to) )
            OR (cce_valid_to IS NULL
            AND SYSDATE      >= cce_valid_from) );
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            BEGIN
              SELECT cpf_fee_plan
              INTO p_fee_plan_id
              FROM cms_prodcattype_fees
              WHERE cpf_inst_code = p_inst_code
              AND cpf_prod_code   = v_prod_code
              AND cpf_card_type   = v_prod_cattype -- Added on 09-Jan-2014 for FSS-1398
              AND ((cpf_valid_to IS NOT NULL
              AND (v_tran_date BETWEEN cpf_valid_from AND cpf_valid_to ) )
              OR ( cpf_valid_to IS NULL
              AND SYSDATE       >= cpf_valid_from ));
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              BEGIN
                SELECT cpf_fee_plan
                INTO p_fee_plan_id
                FROM cms_prod_fees
                WHERE cpf_inst_code = p_inst_code
                AND cpf_prod_code   = v_prod_code
                AND ((cpf_valid_to IS NOT NULL
                AND (v_tran_date BETWEEN cpf_valid_from AND cpf_valid_to ) )
                OR ( cpf_valid_to IS NULL
                AND SYSDATE       >= cpf_valid_from ));
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                p_fee_plan_id := '';
              WHEN OTHERS THEN
                v_err_msg  := 'Error while selecting --Get Fee Plan ID FROM PRODUCT LEVEL ' || SUBSTR (SQLERRM, 1, 200);
                v_resp_cde := '21';
                RAISE exp_reject_record;
              END;
            WHEN OTHERS THEN
              v_err_msg  := 'Error while selecting --Get Fee Plan ID FROM PRODUCT CARD TYPE LEVEL ' || SUBSTR (SQLERRM, 1, 200);
              v_resp_cde := '21';
              RAISE exp_reject_record;
            END;
          WHEN OTHERS THEN
            v_err_msg  := 'Error while selecting --Get Fee Plan ID FROM CARDLEVEL ' || SUBSTR (SQLERRM, 1, 200);
            v_resp_cde := '21';
            RAISE exp_reject_record;
          END;
          DBMS_OUTPUT.put_line ('fee plan ::'||p_fee_plan_id);
        EXCEPTION
        WHEN OTHERS THEN
          v_err_msg  := 'Error while selecting --Get Fee Plan ID  ' || SUBSTR (SQLERRM, 1, 200);
          v_resp_cde := '21';
          RAISE exp_reject_record;
        END;
      END IF;
    END IF;
    --En Added by Ramesh.A on 18/07/2012 for MMPOS Balance Enquiry
     --Sn Added for Transactionlog Functional Removal Phase-II changes
      IF p_delivery_channel = '14'  AND NVL(v_card_usedflag,'N')='N'  THEN
       IF not(p_txn_code in('13','14')) THEN
          v_card_usedflag_upd:='Y';
       END IF;

       IF v_card_usedflag_upd is not null  THEN
         BEGIN
            UPDATE CMS_APPL_PAN
               SET cap_card_usedflag = v_card_usedflag_upd
             WHERE cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS THEN
               v_err_msg :='Error while updating card used flag- ' || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;
       END IF;
      END IF;
      --En Added for Transactionlog Functional Removal Phase-II changes
    --Sn GPR Card status check
    BEGIN
      sp_status_check_gpr (p_inst_code, p_card_no, p_delivery_channel, v_expry_date, v_applpan_cardstat, p_txn_code, p_txn_mode, v_prod_code, v_prod_cattype, p_msg, p_tran_date, p_tran_time, p_international_ind, p_pos_verfication,
      --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
      p_mcc_code, v_resp_cde, v_err_msg );
      IF ( (v_resp_cde <> '1' AND v_err_msg <> 'OK') OR (v_resp_cde <> '0' AND v_err_msg <> 'OK') ) THEN
        RAISE exp_reject_record;
      ELSE
        v_status_chk := v_resp_cde;
        v_resp_cde   := '1';
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error from GPR Card Status Check ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En GPR Card status check
    IF v_status_chk = '1' THEN
      -- Expiry Check
      BEGIN
        IF TO_DATE (p_tran_date, 'YYYYMMDD') > LAST_DAY (TO_CHAR (v_expry_date, 'DD-MON-YY')) THEN
          v_resp_cde                        := '13';
          v_err_msg                         := 'EXPIRED CARD';
          RAISE exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_cde := '21';
        v_err_msg  := 'ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      -- End Expiry Check
      --Sn check for precheck
      IF v_precheck_flag = 1 THEN
        BEGIN
          sp_precheck_txn (p_inst_code, p_card_no, p_delivery_channel, v_expry_date, v_applpan_cardstat, p_txn_code, p_txn_mode, p_tran_date, p_tran_time, v_tran_amt, v_atmonline_limit, v_posonline_limit, v_resp_cde, v_err_msg );
          IF (v_resp_cde <> '1' OR v_err_msg <> 'OK') THEN
            RAISE exp_reject_record;
          END IF;
        EXCEPTION
        WHEN exp_reject_record THEN
          RAISE;
        WHEN OTHERS THEN
          v_resp_cde := '21';
          v_err_msg  := 'Error from precheck processes ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
      END IF;
    END IF;
    --En check for Precheck
    --Sn check for Preauth
    IF v_preauth_flag = 1 THEN
      BEGIN
        sp_preauthorize_txn (p_card_no, p_mcc_code, p_curr_code, v_tran_date, p_txn_code, p_inst_code, p_tran_date, v_tran_amt, p_delivery_channel, v_resp_cde, v_err_msg,p_merchant_id ); --Modified for FSS-2281
        IF (v_resp_cde <> '1' OR TRIM (v_err_msg) <> 'OK') THEN
          RAISE exp_reject_record;
          --Modified by Deepa on Apr-30 to send separate response for rule
          /*IF (V_RESP_CDE = '70' OR TRIM(V_ERR_MSG) <> 'OK') THEN
          V_RESP_CDE := '70';
          RAISE EXP_REJECT_RECORD;
          ELSE
          V_RESP_CDE := '21';
          RAISE EXP_REJECT_RECORD;
          END IF;*/
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_cde := '21';
        v_err_msg  := 'Error from pre_auth process ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
    END IF;
    --En check for preauth

    --Sn - commented for fwr-48

    --Sn find function code attached to txn code
  /*  BEGIN
      SELECT cfm_func_code
      INTO v_func_code
      FROM cms_func_mast
      WHERE cfm_txn_code       = p_txn_code
      AND cfm_txn_mode         = p_txn_mode
      AND cfm_delivery_channel = p_delivery_channel
      AND cfm_inst_code        = p_inst_code;
      --TXN mode and delivery channel we need to attach
      --bkz txn code may be same for all type of channels
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_resp_cde := '69'; --Ineligible Transaction
      v_err_msg  := 'Function code not defined for txn code ' || p_txn_code;
      RAISE exp_reject_record;
    WHEN TOO_MANY_ROWS THEN
      v_resp_cde := '69';
      v_err_msg  := 'More than one function defined for txn code ' || p_txn_code;
      RAISE exp_reject_record;
    END; */
    --En find function code attached to txn code

    --En - commented for fwr-48

    --Sn find prod code and card type and available balance for the card number
    BEGIN
    -- SN added changes for VMS-5546 by Bhavani
    IF ((p_delivery_channel = '02' AND p_txn_code='31') OR (p_delivery_channel = '04' AND p_txn_code IN ('30','94'))) THEN -- Added changes for VMS-5546 by Bhavani
    SELECT cam_acct_bal,
        cam_ledger_bal,
        cam_acct_no,
        cam_type_code,--Added for defect 10871,
        nvl(cam_redemption_delay_flag,'N')
      INTO v_acct_balance,
        v_ledger_bal,
        v_card_acct_no,
        v_cam_type_code ,
        v_redemption_delay_flag
      FROM cms_acct_mast
      WHERE cam_acct_no = V_ACCT_NUMBER
        AND cam_inst_code = p_inst_code ; --FOR UPDATE;    -- Commented for Concurrent Processsing Issue for VMS-5546
    ELSE
      SELECT cam_acct_bal,
        cam_ledger_bal,
        cam_acct_no,
        cam_type_code,--Added for defect 10871,
        nvl(cam_redemption_delay_flag,'N')
      INTO v_acct_balance,
        v_ledger_bal,
        v_card_acct_no,
        v_cam_type_code ,--Added for defect 10871
        v_redemption_delay_flag
      FROM cms_acct_mast
      WHERE cam_acct_no = V_ACCT_NUMBER -- Added changes for VMS-5546 by Bhavani
      /*  (SELECT cap_acct_no -- Commented for VMS-5546 by Bhavani
        FROM cms_appl_pan
        WHERE cap_pan_code = v_hash_pan
        AND cap_mbr_numb   = p_mbr_numb
        AND cap_inst_code  = p_inst_code
        ) */
      AND cam_inst_code = p_inst_code FOR UPDATE; -- Added for Concurrent Processsing Issue
      --FOR UPDATE NOWAIT;             -- Commented for Concurrent Processsing Issue
    END IF;
    -- EN added changes For VMS-5546 by Bhavani
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_resp_cde := '14'; --Ineligible Transaction
      v_err_msg  := 'Invalid Card ';
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_cde := '12';
      v_err_msg  := 'Error while selecting data from card Master for card number ' || SQLERRM;
      RAISE exp_reject_record;
    END;
    DBMS_OUTPUT.put_line ('acct bal  ::'||v_acct_balance);
    DBMS_OUTPUT.put_line ('ledger bal ::'||v_ledger_bal);
    --En find prod code and card type for the card number
    --Sn Moved the query for topup transaction of Medagate for the Mantis ID:14158 on Apr-11-2014
    -- Check for maximum card balance configured for the product profile.
    if v_redemption_delay_flag='Y' then
            vmsredemptiondelay.check_delayed_load(v_acct_number,v_delayed_amount,v_err_msg);
              if v_err_msg<>'OK' then
                 RAISE exp_reject_record;
              end if;
         if v_delayed_amount>0 then
              if v_acct_balance-v_delayed_amount<p_txn_amt then
                 V_RESP_CDE := '1000';
                 V_ERR_MSG  := 'Insufficient Balance ';
                 RAISE exp_reject_record;
              end if;
         end if;
    end if;
    BEGIN
      --Sn Added on 09-Feb-2013 for max card balance check based on product category
      SELECT TO_NUMBER (cbp_param_value)
      INTO v_max_card_bal
      FROM cms_bin_param
      WHERE cbp_inst_code   = p_inst_code
      AND cbp_param_name    = 'Max Card Balance'
      AND cbp_profile_code IN
        (SELECT cpc_profile_code
        FROM cms_prod_cattype
        WHERE cpc_inst_code = p_inst_code
        AND cpc_prod_code   = v_prod_code
        AND cpc_card_type   = v_prod_cattype
        );
      --En Added on 09-Feb-2013 for max card balance check based on product category
      --Sn Commented on 09-Feb-2013 for max card balance check based on product category
      /*SELECT TO_NUMBER(CBP_PARAM_VALUE)
      INTO V_MAX_CARD_BAL
      FROM CMS_BIN_PARAM
      WHERE CBP_INST_CODE = P_INST_CODE AND
      CBP_PARAM_NAME = 'Max Card Balance' AND
      CBP_PROFILE_CODE IN
      (SELECT CPM_PROFILE_CODE
      FROM CMS_PROD_MAST
      WHERE CPM_PROD_CODE = V_PROD_CODE);*/
      --En Commented on 09-Feb-2013 for max card balance check based on product category
    EXCEPTION
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En  Mantis ID:14158 on Apr-11-2014
    -- added for medagate Card Top-Up
    IF p_delivery_channel='14' AND p_txn_code='16' THEN
      --Sn  Modified for the Mantis ID:14158 on Apr-11-14
      IF v_tran_amt > v_max_card_bal THEN
        v_resp_cde := '30';
        v_err_msg  := 'EXCEEDING MAXIMUM CARD BALANCE / BAD CREDIT STATUS';
        RAISE exp_reject_record;
      END IF;
      v_tran_amt_temp     :=v_tran_amt;
      IF v_acct_balance   <= v_tran_amt THEN
        v_tran_amt        := v_tran_amt - v_acct_balance;
        v_limit_amt       :=v_tran_amt;
      elsif v_acct_balance > v_tran_amt THEN
        v_resp_cde        := '210';
        v_err_msg         := 'Target balance is less than current account balance';
        RAISE exp_reject_record;
      END IF;
      IF (v_ledger_bal+v_tran_amt) > v_max_card_bal THEN
        IF v_ledger_bal                <= v_tran_amt_temp THEN
          v_tran_amt                   := v_tran_amt_temp - v_ledger_bal;
          v_limit_amt                  :=v_tran_amt;
        elsif v_ledger_bal              > v_tran_amt THEN
          v_resp_cde                   := '210';
          v_err_msg                    := 'Target balance is less than current ledger balance';
          RAISE exp_reject_record;
        END IF;
      END IF;
      --En  Modified for the Mantis ID:14158 on Apr-11-14
    END IF;
    ------------------------------------------------------
    --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------
    /*    BEGIN
    SELECT COUNT (1)
    INTO v_rrn_count
    FROM transactionlog
    WHERE rrn = p_rrn
    AND                                     --Changed for admin dr cr.
    business_date = p_tran_date
    AND delivery_channel = p_delivery_channel;
    --Added by ramkumar.Mk on 25 march 2012
    IF v_rrn_count > 0
    THEN
    v_resp_cde := '22';
    v_err_msg :=
    'Duplicate RRN from the Terminal '
    || p_term_id
    || ' on '
    || p_tran_date;
    RAISE exp_reject_record;
    END IF;
    END;
    */
    -- MODIFIED BY ABDUL HAMEED M.A  ON 06-03-2014
    BEGIN
      sp_dup_rrn_check (v_hash_pan, p_rrn, p_tran_date, p_delivery_channel, p_msg, p_txn_code, v_err_msg );
      IF v_err_msg <> 'OK' THEN
        v_resp_cde := '22';
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '22';
      v_err_msg  := 'Error while  checking RRN' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    ------------------------------------------------------
    --En Added for Concurrent Processsing Issue
    ------------------------------------------------------
    --Sn Internation Flag check
    IF p_international_ind = '1' THEN
      BEGIN
        SELECT cpc_international_check
        INTO v_international_flag
        FROM cms_prod_cattype
--Modified to retrieve from cms_prod_cattype instead of cms_bin_level_config since international transactions will be tied to product category henceforth
        WHERE cpc_inst_code = p_inst_code
          AND cpc_prod_code = v_prod_code
          AND cpc_card_type = v_prod_cattype;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_international_flag := 'Y';
      WHEN OTHERS THEN
        v_resp_cde := '21';
        V_ERR_MSG  := 'Error while selecting Product Category level Configuration' || SUBSTR(SQLERRM,1,200);
        RAISE exp_reject_record;
      END;
      IF v_international_flag <> 'Y' THEN
        v_resp_cde            := '38';
        v_err_msg             := 'International Transaction Not supported';
        RAISE exp_reject_record;
      END IF;
    END IF;
    --LYFE changes....
    IF p_delivery_channel = '01' THEN
      BEGIN
       SELECT COUNT(*)
          into V_NETWORKIDCOUNT
          from CMS_PROD_CATTYPE PRODCAT,
	  VMS_PRODCAT_NETWORKID_MAPPING MAPP
          WHERE prodCat.CPC_INST_CODE       =MAPP.VPN_INST_CODE
          AND prodCat.CPC_INST_CODE         =p_inst_code
          and PRODCAT.CPC_NETWORKACQID_FLAG ='Y'
          and PRODCAT.CPC_PROD_CODE         =MAPP.VPN_PROD_CODE
          and UPPER(MAPP.VPN_NETWORK_ID)    ='VDBZ'
          AND prodCat.CPC_CARD_TYPE         = MAPP.VPN_CARD_TYPE
          and PRODCAT.CPC_CARD_TYPE         = V_PROD_CATTYPE
          AND MAPP.VPN_PROD_CODE            =v_prod_code;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21';
        v_err_msg  := 'Error while selecting product network id ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
    END IF;
    IF V_NETWORKIDCOUNT <> 1 THEN
      --En Internation Flag check
      BEGIN
        sp_tran_fees_cmsauth (p_inst_code, p_card_no, p_delivery_channel, v_txn_type, p_txn_mode, p_txn_code, p_curr_code, p_consodium_code, p_partner_code, v_tran_amt, v_tran_date, p_international_ind, --Added by Deepa for Fees Changes
        p_pos_verfication,                                                                                                                                                                                 --Added by Deepa for Fees Changes
        v_resp_cde,                                                                                                                                                                                        --Added by Deepa for Fees Changes
        p_msg,                                                                                                                                                                                             --Added by Deepa for Fees Changes
        p_rvsl_code,
        --Added by Deepa on June 25 2012 for Reversal txn Fee
        p_mcc_code,
        --Added by Trivikram on 05-Sep-2012 for merchant catg code
        v_fee_amt, v_error, v_fee_code, v_fee_crgl_catg, v_fee_crgl_code, v_fee_crsubgl_code, v_fee_cracct_no, v_fee_drgl_catg, v_fee_drgl_code, v_fee_drsubgl_code, v_fee_dracct_no, v_st_calc_flag, v_cess_calc_flag, v_st_cracct_no, v_st_dracct_no, v_cess_cracct_no, v_cess_dracct_no, v_feeamnt_type, --Added by Deepa for Fees Changes
        v_clawback,                                                                                                                                                                                                                                                                                         --Added by Deepa for Fees Changes
        v_fee_plan,                                                                                                                                                                                                                                                                                         --Added by Deepa for Fees Changes
        v_per_fees,                                                                                                                                                                                                                                                                                         --Added by Deepa for Fees Changes
        v_flat_fees,                                                                                                                                                                                                                                                                                        --Added by Deepa for Fees Changes
        v_freetxn_exceed,
        -- Added by Trivikram for logging fee of free transaction
        v_duration,
        -- Added by Trivikram for logging fee of free transaction
        v_feeattach_type, -- Added by Trivikram on Sep 05 2012
        v_fee_desc        -- Added for MVCSD-4471
        );
        IF v_error   <> 'OK' THEN
          v_resp_cde := '21';
          v_err_msg  := v_error;
          RAISE exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_cde := '21';
        v_err_msg  := 'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      ---En dynamic fee calculation .
    ELSE
      v_fee_amt :=0;
    END IF;
    DBMS_OUTPUT.put_line ('fee av_fee_amt  ::'||v_fee_amt);
    DBMS_OUTPUT.put_line ('v_fee_code  ::'||v_fee_code);
    --Sn calculate waiver on the fee
    BEGIN
      sp_calculate_waiver (p_inst_code, p_card_no, '000', v_prod_code, v_prod_cattype, v_fee_code, v_fee_plan, -- Added by Trivikram on 21/aug/2012
      v_tran_date,
      --Added Deepa on Aug-23-2012 to calculate the waiver based on tran date
      v_waiv_percnt, v_err_waiv );
      IF v_err_waiv <> 'OK' THEN
        v_resp_cde  := '21';
        v_err_msg   := v_err_waiv;
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En calculate waiver on the fee
    --Sn apply waiver on fee amount
    v_log_actual_fee := v_fee_amt; --only used to log in log table
    v_fee_amt        := ROUND (v_fee_amt - ((v_fee_amt * v_waiv_percnt) / 100), 2);
    v_log_waiver_amt := v_log_actual_fee - v_fee_amt;
    --only used to log in log table
    --En apply waiver on fee amount
    --Sn apply service tax and cess
    IF v_st_calc_flag      = 1 THEN
      v_servicetax_amount := (v_fee_amt * v_servicetax_percent) / 100;
    ELSE
      v_servicetax_amount := 0;
    END IF;
    IF v_cess_calc_flag = 1 THEN
      v_cess_amount    := (v_servicetax_amount * v_cess_percent) / 100;
    ELSE
      v_cess_amount := 0;
    END IF;
    v_total_fee := ROUND (v_fee_amt + v_servicetax_amount + v_cess_amount, 2);
    --Sn Added for the Mantis ID:14158
    IF p_delivery_channel='14' AND p_txn_code='16' THEN
      v_limit_amt       :=v_limit_amt + v_total_fee;
    END IF;
    --En Added for the Mantis ID:14158
    --Moved the limit procedure call for Mantis ID:14158

     --Added for MVHOST-1022
    BEGIN
       IF p_delivery_channel = '02' AND p_txn_code = '25'
       THEN
          SELECT COUNT (1)
            INTO v_mrlimitbreach_count
            FROM cms_mrlimitbreach_merchantname
           WHERE cpt_inst_code = p_inst_code
             AND UPPER (TRIM (p_merchant_name)) LIKE cmm_merchant_name || '%';

          IF v_mrlimitbreach_count > 0
          THEN
             v_mrminmaxlmt_ignoreflag := 'Y';
          END IF;
       END IF;
    EXCEPTION
       WHEN OTHERS
       THEN
          V_RESP_CDE := '21';
          V_ERR_MSG  := 'Error While Occured checking the  limit breach count'|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
    END;
    --End MVHOST-1022

    /* Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
    BEGIN
      IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
        pkg_limits_check.sp_limits_check (v_hash_pan, NULL, NULL, p_mcc_code, p_txn_code, v_tran_type,
        CASE
        WHEN p_delivery_channel ='02' AND p_txn_code ='25' -- Case added for 13063 defect
          THEN
          NULL
        ELSE
          p_international_ind
        END,
        CASE
        WHEN p_delivery_channel ='02' AND p_txn_code ='25' -- Case added for 13063 defect
          THEN
          NULL
        ELSE
          p_pos_verfication
        END, p_inst_code, NULL, v_prfl_code, v_limit_amt, --Added on 04-Feb-2013 for FSS-821
        --p_txn_amt, -- commented on 04-Feb-2013 for FSS-821
        p_delivery_channel, v_comb_hash, v_resp_cde, v_error,v_mrminmaxlmt_ignoreflag);
      END IF;
      IF v_error <> 'OK' THEN
        --v_resp_cde := '21'; --commented by amit on 26-Jul-12 to pass response code from limit check
        v_err_msg := v_error; --'From Procedure sp_limits_check '||
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    /* End  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
    --En apply service tax and cess
    --En find fees amount attached to func code, prod code and card type
    --Sn find total transaction    amount
    IF v_dr_cr_flag = 'CR' THEN
      -- added for Card Top-up
      IF p_delivery_channel='14' AND p_txn_code='16' THEN
        v_total_amt       := v_tran_amt;
        v_upd_amt         := v_acct_balance + v_tran_amt;
        v_upd_ledger_amt  := v_ledger_bal   + v_tran_amt;
        v_tran_amt        := v_tran_amt     + v_total_fee;
        p_dda_number      := v_tran_amt;
      ELSE
        v_total_amt      := v_tran_amt     - v_total_fee;
        v_upd_amt        := v_acct_balance + v_total_amt;
        v_upd_ledger_amt := v_ledger_bal   + v_total_amt;
      END IF;
    ELSIF v_dr_cr_flag    = 'DR' THEN
      v_total_amt        := v_tran_amt     + v_total_fee;
      v_upd_amt          := v_acct_balance - v_total_amt;
      v_upd_ledger_amt   := v_ledger_bal   - v_total_amt;
    ELSIF v_dr_cr_flag    = 'NA' THEN
      IF p_txn_code       = '11' AND p_msg = '0100' THEN
        v_total_amt      := v_tran_amt     + v_total_fee;
        v_upd_amt        := v_acct_balance - v_total_amt;
        v_upd_ledger_amt := v_ledger_bal   - v_total_amt;
      ELSE
        IF v_total_fee = 0 THEN
          v_total_amt := 0;
        ELSE
          v_total_amt := v_total_fee;
        END IF;
        v_upd_amt        := v_acct_balance - v_total_amt;
        v_upd_ledger_amt := v_ledger_bal   - v_total_amt;
      END IF;
    ELSE
      v_resp_cde := '12'; --Ineligible Transaction
      v_err_msg  := 'Invalid transflag    txn code ' || p_txn_code;
      RAISE exp_reject_record;
    END IF;
    --En find total transaction    amout
    /*  Commented For Clawback Changes (MVHOST - 346)  on 20/04/2013
    --Sn check balance
    IF    (v_dr_cr_flag NOT IN ('NA', 'CR') AND p_txn_code <> '93')
    OR v_total_fee <>
    0
    --Modified by Deepa As it needs to check insufficient balance for fee
    THEN
    IF v_upd_amt < 0
    THEN
    v_resp_cde := '15';                      --Ineligible Transaction
    v_err_msg := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
    RAISE exp_reject_record;
    END IF;
    END IF;
    --En check balance  */
    DBMS_OUTPUT.put_line ('V_UPD_AMT  ::'||V_UPD_AMT);
    --Start Clawback Changes (MVHOST - 346)  on 20/04/2013
    IF (V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0)) THEN --ADDED FOR JIRA MVCHW - 454
      IF (V_UPD_AMT-v_delayed_amount)   < 0 THEN
        --Sn IVR ClawBack amount updation
        --IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK = 'Y' V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0) THEN  --commented for JIRA MVCHW - 454
        IF V_LOGIN_TXN       = 'Y' AND V_CLAWBACK = 'Y' THEN --ADDED FOR JIRA MVCHW - 454
          V_ACTUAL_FEE_AMNT := V_TOTAL_FEE;
          --V_CLAWBACK_AMNT   := V_TOTAL_FEE - V_ACCT_BALANCE;  --commented for JIRA MVCHW - 454
          --   V_FEE_AMT         := V_ACCT_BALANCE;  --commented for JIRA MVCHW - 454
          --Start  ADDED FOR JIRA MVCHW - 454
          IF (V_ACCT_BALANCE >0) THEN
            V_CLAWBACK_AMNT := V_TOTAL_FEE - V_ACCT_BALANCE;
            V_FEE_AMT       := V_ACCT_BALANCE;
          ELSE
            V_CLAWBACK_AMNT := V_TOTAL_FEE;
            V_FEE_AMT       := 0;
          END IF;
          --END FOR JIRA MVCHW - 454
          IF V_CLAWBACK_AMNT > 0 THEN
           -- Added for FWR 64 --
                  begin
                    select cfm_clawback_count into v_tot_clwbck_count from cms_fee_mast where cfm_fee_code=V_FEE_CODE;

                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    V_RESP_CDE := '12';
                    V_ERR_MSG  := 'Clawback count not configured '|| SUBSTR(SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                  END;

                BEGIN
                                SELECT COUNT (*)
                                  INTO v_chrg_dtl_cnt
                                  FROM cms_charge_dtl
                                 WHERE      ccd_inst_code = p_inst_code
                                         AND ccd_delivery_channel = p_delivery_channel
                                         AND ccd_txn_code = p_txn_code
                                         --AND ccd_pan_code = v_hash_pan  --Commented for FSS-4755
                                         AND ccd_acct_no = v_card_acct_no  and CCD_FEE_CODE=V_FEE_CODE
                     and ccd_clawback ='Y';
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    V_RESP_CDE := '21';
                                    V_ERR_MSG :=
                                        'Error occured while fetching count from cms_charge_dtl'
                                        || SUBSTR (SQLERRM, 1, 100);
                                    RAISE EXP_REJECT_RECORD;
                            END;
            -- Added for fwr 64

            BEGIN
              SELECT COUNT(*)
              INTO V_CLAWBACK_COUNT
              FROM CMS_ACCTCLAWBACK_DTL
              WHERE CAD_INST_CODE      = P_INST_CODE
              AND CAD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
              AND CAD_TXN_CODE         = P_TXN_CODE
              AND CAD_PAN_CODE         = V_HASH_PAN
              AND CAD_ACCT_NO          = V_CARD_ACCT_NO;
              IF V_CLAWBACK_COUNT      = 0 THEN
                INSERT
                INTO CMS_ACCTCLAWBACK_DTL
                  (
                    CAD_INST_CODE,
                    CAD_ACCT_NO,
                    CAD_PAN_CODE,
                    CAD_PAN_CODE_ENCR,
                    CAD_CLAWBACK_AMNT,
                    CAD_RECOVERY_FLAG,
                    CAD_INS_DATE,
                    CAD_LUPD_DATE,
                    CAD_DELIVERY_CHANNEL,
                    CAD_TXN_CODE,
                    CAD_INS_USER,
                    CAD_LUPD_USER
                  )
                  VALUES
                  (
                    P_INST_CODE,
                    V_CARD_ACCT_NO,
                    V_HASH_PAN,
                    V_ENCR_PAN,
                    ROUND (V_CLAWBACK_AMNT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                    'N',
                    SYSDATE,
                    SYSDATE,
                    P_DELIVERY_CHANNEL,
                    P_TXN_CODE,
                    '1',
                    '1'
                  );
               ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count then  -- Modified for fwr 64
                UPDATE CMS_ACCTCLAWBACK_DTL
                SET CAD_CLAWBACK_AMNT    = ROUND (CAD_CLAWBACK_AMNT + V_CLAWBACK_AMNT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                  CAD_RECOVERY_FLAG      = 'N',
                  CAD_LUPD_DATE          = SYSDATE
                WHERE CAD_INST_CODE      = P_INST_CODE
                AND CAD_ACCT_NO          = V_CARD_ACCT_NO
                AND CAD_PAN_CODE         = V_HASH_PAN
                AND CAD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                AND CAD_TXN_CODE         = P_TXN_CODE;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              V_RESP_CDE := '21';
              V_ERR_MSG  := 'Error while inserting Account ClawBack details' || SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
            END;
          END IF;
        ELSE
          IF v_delayed_amount>0 THEN
               v_resp_cde:='1000';
          ELSE
               V_RESP_CDE := '15';
          END IF;
          V_ERR_MSG  := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
          RAISE EXP_REJECT_RECORD;
        END IF;
        IF (V_ACCT_BALANCE  >0) THEN -- ADDED for Mantis ID : 0011792
          V_UPD_AMT        := 0;
          V_UPD_LEDGER_AMT := 0;
        ELSE -- Sn ADDED for Mantis ID : 0011792
          V_UPD_AMT        := V_ACCT_BALANCE;
          V_UPD_LEDGER_AMT := v_ledger_bal;
        END IF;
        -- en ADDED for Mantis ID : 0011792
        V_TOTAL_AMT := V_TRAN_AMT + V_FEE_AMT ;
      END IF;
    END IF; -- ADDED FOR JIRA MVCHW - 454
    --End  Clawback Changes (MVHOST - 346)  on 20/04/2013
    --Commented to move the query execution above for the mantis iD:14158
    -- Check for maximum card balance configured for the product profile.
    /*  BEGIN
    --Sn Added on 09-Feb-2013 for max card balance check based on product category
    SELECT TO_NUMBER (cbp_param_value)
    INTO v_max_card_bal
    FROM cms_bin_param
    WHERE cbp_inst_code = p_inst_code
    AND cbp_param_name = 'Max Card Balance'
    AND cbp_profile_code IN (
    SELECT cpc_profile_code
    FROM cms_prod_cattype
    WHERE cpc_inst_code = p_inst_code
    AND cpc_prod_code = v_prod_code
    AND cpc_card_type = v_prod_cattype);
    --En Added on 09-Feb-2013 for max card balance check based on product category
    --Sn Commented on 09-Feb-2013 for max card balance check based on product category
    /*SELECT TO_NUMBER(CBP_PARAM_VALUE)
    INTO V_MAX_CARD_BAL
    FROM CMS_BIN_PARAM
    WHERE CBP_INST_CODE = P_INST_CODE AND
    CBP_PARAM_NAME = 'Max Card Balance' AND
    CBP_PROFILE_CODE IN
    (SELECT CPM_PROFILE_CODE
    FROM CMS_PROD_MAST
    WHERE CPM_PROD_CODE = V_PROD_CODE);*/
    --En Commented on 09-Feb-2013 for max card balance check based on product category
    /* EXCEPTION
    WHEN OTHERS
    THEN
    v_resp_cde := '21';
    v_err_msg :=
    'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
    || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
    END;*/
    --EN Mantis ID:14158
    --Added by Ramkumar.MK, check the DR_CR_Flag
    IF v_dr_cr_flag = 'CR' THEN
      --Sn check balance
      IF (v_upd_ledger_amt > v_max_card_bal) OR (v_upd_amt > v_max_card_bal) THEN
        v_resp_cde        := '30';
        v_err_msg         := 'EXCEEDING MAXIMUM CARD BALANCE / BAD CREDIT STATUS';
        RAISE exp_reject_record;
      END IF;
      --En check balance
    END IF;
    --Sn create gl entries and acct update
    BEGIN
      sp_upd_transaction_accnt_auth (p_inst_code, v_tran_date, v_prod_code, v_prod_cattype, v_tran_amt, v_func_code, p_txn_code, v_dr_cr_flag, p_rrn, p_term_id, p_delivery_channel, p_txn_mode, p_card_no, v_fee_code, v_fee_amt, v_fee_cracct_no, v_fee_dracct_no, v_st_calc_flag, v_cess_calc_flag, v_servicetax_amount, v_st_cracct_no, v_st_dracct_no, v_cess_amount, v_cess_cracct_no, v_cess_dracct_no, v_card_acct_no,
      ---Card's account no has been passed instead of card no(For Debit card acct_no will be different)
      v_hold_amount, --For PreAuth Completion transaction
      p_msg, v_resp_cde, v_err_msg );
      IF (v_resp_cde <> '1' OR v_err_msg <> 'OK') THEN
        v_resp_cde   := '21';
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En create gl entries and acct update
    --Sn find narration
    BEGIN
  /*    SELECT ctm_tran_desc
      INTO v_trans_desc
      FROM cms_transaction_mast
      WHERE ctm_tran_code      = p_txn_code
      AND ctm_delivery_channel = p_delivery_channel
      AND ctm_inst_code        = p_inst_code; */
      IF TRIM (v_trans_desc)  IS NOT NULL THEN
        v_narration           := v_trans_desc || '/';
      END IF;
      IF TRIM (p_merchant_name) IS NOT NULL THEN
        v_narration             := v_narration || p_merchant_name || '/';
      END IF;
      IF TRIM (p_merchant_city) IS NOT NULL THEN
        v_narration             := v_narration || p_merchant_city || '/';
      END IF;
      IF TRIM (p_tran_date) IS NOT NULL THEN
        v_narration         := v_narration || p_tran_date || '/';
      END IF;
      IF TRIM (v_auth_id) IS NOT NULL THEN
        v_narration       := v_narration || v_auth_id;
      END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_trans_desc := 'Transaction type ' || p_txn_code;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En find narration
  --  v_timestamp := systimestamp; -- Added on 20-Apr-2013 for defect 10871
    --Sn create a entry in statement log
    IF v_dr_cr_flag <> 'NA' THEN
      BEGIN
        INSERT
        INTO cms_statements_log
          (
            csl_pan_no,
            csl_opening_bal,
            csl_trans_amount,
            csl_trans_type,
            csl_trans_date,
            csl_closing_balance,
            csl_trans_narrration,
            csl_inst_code,
            csl_pan_no_encr,
            csl_rrn,
            csl_auth_id,
            csl_business_date,
            csl_business_time,
            txn_fee_flag,
            csl_delivery_channel,
            csl_txn_code,
            csl_acct_no,
            --Added by Deepa to log the account number ,INS_DATE and INS_USER
            csl_ins_user,
            csl_ins_date,
            csl_merchant_name,
            --Added by Deepa on 03-May-2012 to log Merchant name,city and state
            csl_merchant_city,
            csl_merchant_state,
            csl_panno_last4digit,
            csl_acct_type,  -- Added on 20-Apr-2013 for defect 10871
            csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
            csl_prod_code,   -- Added on 20-Apr-2013 for defect 10871
          csl_card_type
          )
          --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
          VALUES
          (
            v_hash_pan,
            ROUND (v_ledger_bal, 2),--Modified by Sankar S on 08-APR-2014 for 3decimal place issue
            ROUND (v_tran_amt, 2),  -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871   --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
            v_dr_cr_flag,
            v_tran_date,
            ROUND ( DECODE (v_dr_cr_flag, 'DR', v_ledger_bal - v_tran_amt, -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
            'CR', v_ledger_bal                               + v_tran_amt, -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
            'NA', v_ledger_bal                                             -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
            ), 2),                                                         --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
            v_narration,
            p_inst_code,
            v_encr_pan,
            p_rrn,
            v_auth_id,
            p_tran_date,
            p_tran_time,
            'N',
            p_delivery_channel,
            p_txn_code,
            v_card_acct_no,
            --Added by Deepa to log the account number ,INS_DATE and INS_USER
            1,
            SYSDATE,
            p_merchant_name,
            --Added by Deepa on 03-May-2012 to log Merchant name,city and state
            p_merchant_city,
            p_atmname_loc,
            (SUBSTR (p_card_no, LENGTH (p_card_no) - 3, LENGTH (p_card_no) ) ),
            v_cam_type_code, -- added on 20-Apr-2013 for defect 10871
            v_timestamp,     -- Added on 20-Apr-2013 for defect 10871
            v_prod_code ,     -- Added on 20-Apr-2013 for defect 10871
          v_prod_cattype
          );
        --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21';
        v_err_msg  := 'Problem while inserting into statement log for tran amt ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      BEGIN
        sp_daily_bin_bal (p_card_no, v_tran_date, v_tran_amt, v_dr_cr_flag, p_inst_code, p_bank_code, v_err_msg );
        IF v_err_msg <> 'OK' THEN
          v_resp_cde := '21';
          v_err_msg  := 'Problem while calling SP_DAILY_BIN_BAL ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21';
        v_err_msg  := 'Problem while calling SP_DAILY_BIN_BAL ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
    END IF;
    --En create a entry in statement log
    --Sn find fee opening balance
    IF v_total_fee <> 0 OR v_freetxn_exceed = 'N' THEN
      -- Modified by Trivikram on 26-July-2012 for logging fee of free transaction
      BEGIN
        SELECT DECODE (v_dr_cr_flag, 'DR', v_ledger_bal - v_tran_amt, -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
          'CR', v_ledger_bal                            + v_tran_amt, -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
          'NA', v_ledger_bal                                          -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
          )
        INTO v_fee_opening_bal
        FROM DUAL;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '12';
        v_err_msg  := 'Error while selecting data from card Master for card number ' || p_card_no;
        RAISE exp_reject_record;
      END;
      -- Added by Trivikram on 27-July-2012 for logging complementary transaction
      IF v_freetxn_exceed = 'N' THEN
        BEGIN
          INSERT
          INTO cms_statements_log
            (
              csl_pan_no,
              csl_opening_bal,
              csl_trans_amount,
              csl_trans_type,
              csl_trans_date,
              csl_closing_balance,
              csl_trans_narrration,
              csl_inst_code,
              csl_pan_no_encr,
              csl_rrn,
              csl_auth_id,
              csl_business_date,
              csl_business_time,
              txn_fee_flag,
              csl_delivery_channel,
              csl_txn_code,
              csl_acct_no,
              --Added by Deepa to log the account number ,INS_DATE and INS_USER
              csl_ins_user,
              csl_ins_date,
              csl_merchant_name,
              --Added by Deepa on 03-May-2012 to log Merchant name,city and state
              csl_merchant_city,
              csl_merchant_state,
              csl_panno_last4digit,
              csl_acct_type,  -- Added on 20-Apr-2013 for defect 10871
              csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
              csl_prod_code   -- Added on 20-Apr-2013 for defect 10871
            )
            --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
            VALUES
            (
              v_hash_pan,
              ROUND (v_fee_opening_bal, 2),--Modified by Sankar S on 08-APR-2014 for 3decimal place issue
              ROUND (v_total_fee, 2),      --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
              'DR',
              v_tran_date,
              ROUND (v_fee_opening_bal - v_total_fee, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
              -- 'Complimentary ' || v_duration || ' '|| v_narration,  -- Commented for MVCSD-4471
              v_fee_desc, -- Added for MVCSD-4471
              p_inst_code,
              v_encr_pan,
              p_rrn,
              v_auth_id,
              p_tran_date,
              p_tran_time,
              'Y',
              p_delivery_channel,
              p_txn_code,
              v_card_acct_no,
              --Added by Deepa to log the account number ,INS_DATE and INS_USER
              1,
              SYSDATE,
              p_merchant_name,
              --Added by Deepa on 03-May-2012 to log Merchant name,city and state
              p_merchant_city,
              p_atmname_loc,
              (SUBSTR (p_card_no, LENGTH (p_card_no) - 3, LENGTH (p_card_no) ) ),
              v_cam_type_code, -- added on 20-Apr-2013 for defect 10871
              v_timestamp,     -- Added on 20-Apr-2013 for defect 10871
              v_prod_code      -- Added on 20-Apr-2013 for defect 10871
            );
          --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
        EXCEPTION
        WHEN OTHERS THEN
          v_resp_cde := '21';
          v_err_msg  := 'Problem while inserting into statement log for tran fee ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
      ELSE
        BEGIN
          --Added by Deepa for Fee Changes on June 10 2012
          --En find fee opening balance
          IF v_feeamnt_type = 'A' THEN
            v_flat_fees    := ROUND ( v_flat_fees - ((v_flat_fees * v_waiv_percnt) / 100), 2 );
            v_per_fees     := ROUND (v_per_fees   - ((v_per_fees * v_waiv_percnt) / 100), 2 );
            --En Entry for Fixed Fee
            INSERT
            INTO cms_statements_log
              (
                csl_pan_no,
                csl_opening_bal,
                csl_trans_amount,
                csl_trans_type,
                csl_trans_date,
                csl_closing_balance,
                csl_trans_narrration,
                csl_inst_code,
                csl_pan_no_encr,
                csl_rrn,
                csl_auth_id,
                csl_business_date,
                csl_business_time,
                txn_fee_flag,
                csl_delivery_channel,
                csl_txn_code,
                csl_acct_no,
                csl_ins_user,
                csl_ins_date,
                csl_merchant_name,
                csl_merchant_city,
                csl_merchant_state,
                csl_panno_last4digit,
                csl_acct_type,  -- Added on 20-Apr-2013 for defect 10871
                csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                csl_prod_code   -- Added on 20-Apr-2013 for defect 10871
              )
              VALUES
              (
                v_hash_pan,
                ROUND (v_fee_opening_bal, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                -- V_FLAT_FEES,
                ROUND (v_flat_fees, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                'DR',
                v_tran_date,
                ROUND (v_fee_opening_bal - v_flat_fees, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                --Added by Deepa on Aug-22-2012 to log the Fixed Fee with waiver amount
                -- 'Fixed Fee debited for ' || v_narration, -- Commented for MVCSD-4471
                'Fixed Fee debited for '
                || v_fee_desc, -- Added for MVCSD-4471
                p_inst_code,
                v_encr_pan,
                p_rrn,
                v_auth_id,
                p_tran_date,
                p_tran_time,
                'Y',
                p_delivery_channel,
                p_txn_code,
                v_card_acct_no,
                1,
                SYSDATE,
                p_merchant_name,
                p_merchant_city,
                p_atmname_loc,
                (SUBSTR (p_card_no, LENGTH (p_card_no) - 3, LENGTH (p_card_no) ) ),
                v_cam_type_code, -- added on 20-Apr-2013 for defect 10871
                v_timestamp,     -- Added on 20-Apr-2013 for defect 10871
                v_prod_code      -- Added on 20-Apr-2013 for defect 10871
              );
            --En Entry for Fixed Fee
            v_fee_opening_bal := v_fee_opening_bal - v_flat_fees;
            --Sn Entry for Percentage Fee
            INSERT
            INTO cms_statements_log
              (
                csl_pan_no,
                csl_opening_bal,
                csl_trans_amount,
                csl_trans_type,
                csl_trans_date,
                csl_closing_balance,
                csl_trans_narrration,
                csl_inst_code,
                csl_pan_no_encr,
                csl_rrn,
                csl_auth_id,
                csl_business_date,
                csl_business_time,
                txn_fee_flag,
                csl_delivery_channel,
                csl_txn_code,
                csl_acct_no,
                --Added by Deepa to log the account number ,INS_DATE and INS_USER
                csl_ins_user,
                csl_ins_date,
                csl_merchant_name,
                --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                csl_merchant_city,
                csl_merchant_state,
                csl_panno_last4digit,
                csl_acct_type,  -- Added on 20-Apr-2013 for defect 10871
                csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                csl_prod_code   -- Added on 20-Apr-2013 for defect 10871
              )
              --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
              VALUES
              (
                v_hash_pan,
                ROUND (v_fee_opening_bal, 2),--Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                ROUND (v_per_fees, 2),       --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                'DR',
                v_tran_date,
                ROUND (v_fee_opening_bal - v_per_fees, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                -- 'Percetage Fee debited for ' || v_narration, -- Added for MVCSD-4471
                'Percentage Fee debited for '
                || v_fee_desc, -- Added for MVCSD-4471
                p_inst_code,
                v_encr_pan,
                p_rrn,
                v_auth_id,
                p_tran_date,
                p_tran_time,
                'Y',
                p_delivery_channel,
                p_txn_code,
                v_card_acct_no,
                --Added by Deepa to log the account number ,INS_DATE and INS_USER
                1,
                SYSDATE,
                p_merchant_name,
                --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                p_merchant_city,
                p_atmname_loc,
                (SUBSTR (p_card_no, LENGTH (p_card_no) - 3, LENGTH (p_card_no) ) ),
                v_cam_type_code, -- added on 20-Apr-2013 for defect 10871
                v_timestamp,     -- Added on 20-Apr-2013 for defect 10871
                v_prod_code      -- Added on 20-Apr-2013 for defect 10871
              );
            --En Entry for Percentage Fee
          ELSE
            INSERT
            INTO cms_statements_log
              (
                csl_pan_no,
                csl_opening_bal,
                csl_trans_amount,
                csl_trans_type,
                csl_trans_date,
                csl_closing_balance,
                csl_trans_narrration,
                csl_inst_code,
                csl_pan_no_encr,
                csl_rrn,
                csl_auth_id,
                csl_business_date,
                csl_business_time,
                txn_fee_flag,
                csl_delivery_channel,
                csl_txn_code,
                csl_acct_no,
                --Added by Deepa to log the account number ,INS_DATE and INS_USER
                csl_ins_user,
                csl_ins_date,
                csl_merchant_name,
                --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                csl_merchant_city,
                csl_merchant_state,
                csl_panno_last4digit,
                csl_acct_type,  -- Added on 20-Apr-2013 for defect 10871
                csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                csl_prod_code   -- Added on 20-Apr-2013 for defect 10871
              )
              --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
              VALUES
              (
                v_hash_pan,
                ROUND (v_fee_opening_bal, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                ROUND (V_FEE_AMT, 2),
                'DR', --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                v_tran_date,
                ROUND (v_fee_opening_bal - V_FEE_AMT, 2), --modified for MVHOST-346  --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                --'Fee debited for ' || v_narration, -- Added for MVCSD-4471
                v_fee_desc, -- Added for MVCSD-4471
                p_inst_code,
                v_encr_pan,
                p_rrn,
                v_auth_id,
                p_tran_date,
                p_tran_time,
                'Y',
                p_delivery_channel,
                p_txn_code,
                v_card_acct_no,
                --Added by Deepa to log the account number ,INS_DATE and INS_USER
                1,
                SYSDATE,
                p_merchant_name,
                --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                p_merchant_city,
                p_atmname_loc,
                (SUBSTR (p_card_no, LENGTH (p_card_no) - 3, LENGTH (p_card_no) ) ),
                v_cam_type_code, -- added on 20-Apr-2013 for defect 10871
                v_timestamp,     -- Added on 20-Apr-2013 for defect 10871
                v_prod_code      -- Added on 20-Apr-2013 for defect 10871
              );
            --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
            --Start  Clawback Changes (MVHOST - 346)  on 20/04/2013
            IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK_AMNT > 0 and v_chrg_dtl_cnt < v_tot_clwbck_count THEN  -- Modified for fwr 64
              BEGIN
                INSERT
                INTO CMS_CHARGE_DTL
                  (
                    CCD_PAN_CODE,
                    CCD_ACCT_NO,
                    CCD_CLAWBACK_AMNT,
                    CCD_GL_ACCT_NO,
                    CCD_PAN_CODE_ENCR,
                    CCD_RRN,
                    CCD_CALC_DATE,
                    CCD_FEE_FREQ,
                    CCD_FILE_STATUS,
                    CCD_CLAWBACK,
                    CCD_INST_CODE,
                    CCD_FEE_CODE,
                    CCD_CALC_AMT,
                    CCD_FEE_PLAN,
                    CCD_DELIVERY_CHANNEL,
                    CCD_TXN_CODE,
                    CCD_DEBITED_AMNT,
                    CCD_MBR_NUMB,
                    CCD_PROCESS_MSG,
                    CCD_FEEATTACHTYPE
                  )
                  VALUES
                  (
                    V_HASH_PAN,
                    V_CARD_ACCT_NO,
                    ROUND (V_CLAWBACK_AMNT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                    V_FEE_CRACCT_NO,
                    V_ENCR_PAN,
                    P_RRN,
                    V_TRAN_DATE,
                    'T',
                    'C',
                    V_CLAWBACK,
                    P_INST_CODE,
                    V_FEE_CODE,
                    ROUND (V_ACTUAL_FEE_AMNT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                    V_FEE_PLAN,
                    P_DELIVERY_CHANNEL,
                    P_TXN_CODE,
                    ROUND (V_FEE_AMT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                    P_MBR_NUMB,
                    DECODE(V_ERR_MSG, 'OK', 'SUCCESS'),
                    V_FEEATTACH_TYPE
                  );
              EXCEPTION
              WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERR_MSG  := 'Problem while inserting into CMS_CHARGE_DTL ' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
              END;
            END IF;
            --End  Clawback Changes (MVHOST - 346)  on 20/04/2013
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          v_resp_cde := '21';
          v_err_msg  := 'Problem while inserting into statement log for tran fee ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
      END IF;
    END IF;
    --En create entries for FEES attached
    --Sn create a entry for successful
    BEGIN
      INSERT
      INTO cms_transaction_log_dtl
        (
          ctd_delivery_channel,
          ctd_txn_code,
          ctd_txn_type,
          ctd_msg_type,
          ctd_txn_mode,
          ctd_business_date,
          ctd_business_time,
          ctd_customer_card_no,
          ctd_txn_amount,
          ctd_txn_curr,
          ctd_actual_amount,
          ctd_fee_amount,
          ctd_waiver_amount,
          ctd_servicetax_amount,
          ctd_cess_amount,
          ctd_bill_amount,
          ctd_bill_curr,
          ctd_process_flag,
          ctd_process_msg,
          ctd_rrn,
          ctd_system_trace_audit_no,
          ctd_inst_code,
          ctd_customer_card_no_encr,
          ctd_cust_acct_number,
          ctd_internation_ind_response,
          /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          ctd_network_id,
          ctd_interchange_feeamt,
          ctd_merchant_zip,
          /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          CTD_MERCHANT_ID --Added on 19-Mar-2013 for FSS-970
          ,ctd_reason_code,
           ctd_hashkey_id
        )
        VALUES
        (
          p_delivery_channel,
          p_txn_code,
          v_txn_type,
          p_msg,
          p_txn_mode,
          p_tran_date,
          p_tran_time,
          v_hash_pan,
          DECODE(p_txn_code,'16',v_tran_amt,p_txn_amt), -- Modified for Medagate Card Top-Up
          p_curr_code,
          DECODE(p_txn_code,'16',p_txn_amt,v_tran_amt),
          v_log_actual_fee,
          v_log_waiver_amt,
          v_servicetax_amount,
          v_cess_amount,
          DECODE(p_txn_code,'16',v_tran_amt,v_total_amt),
          v_card_curr,
          'Y', -- Modified for Medagate Card Top-Up
          'Successful',
          p_rrn,
          p_stan,
          p_inst_code,
          v_encr_pan,
          v_acct_number,
          p_international_ind,
          /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          p_network_id,
          p_interchange_feeamt,
          p_merchant_zip,
          /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          P_MERCHANT_ID --Added on 19-Mar-2013 for FSS-970
          ,p_reasoncode_in,
          v_hashkey_id
        );
      --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
    EXCEPTION
    WHEN OTHERS THEN
      v_err_msg  := 'Problem while inserting in to CMS_TRANSACTION_LOG_DTL ' || SUBSTR (SQLERRM, 1, 300);
      v_resp_cde := '21';
      RAISE exp_reject_record;
    END;
    --En create a entry for successful
    ---Sn update daily and weekly transcounter  and amount
    BEGIN
      /*SELECT CAT_PAN_CODE
      INTO V_AVAIL_PAN
      FROM CMS_AVAIL_TRANS
      WHERE CAT_PAN_CODE = V_HASH_PAN
      AND CAT_TRAN_CODE = P_TXN_CODE AND
      CAT_TRAN_MODE = P_TXN_MODE;*/
      UPDATE cms_avail_trans
      SET cat_maxdaily_trancnt = DECODE (cat_maxdaily_trancnt, 0, cat_maxdaily_trancnt, cat_maxdaily_trancnt   - 1 ),
        cat_maxdaily_tranamt   = DECODE (v_dr_cr_flag, 'DR', cat_maxdaily_tranamt                              - v_tran_amt, cat_maxdaily_tranamt ),
        cat_maxweekly_trancnt  = DECODE (cat_maxweekly_trancnt, 0, cat_maxweekly_trancnt, cat_maxdaily_trancnt - 1 ),
        cat_maxweekly_tranamt  = DECODE (v_dr_cr_flag, 'DR', cat_maxweekly_tranamt                             - v_tran_amt, cat_maxweekly_tranamt )
      WHERE cat_inst_code      = p_inst_code
      AND cat_pan_code         = v_hash_pan
      AND cat_tran_code        = p_txn_code
      AND cat_tran_mode        = p_txn_mode;
      /*IF SQL%ROWCOUNT = 0 THEN
      V_ERR_MSG  := 'Problem while updating data in avail trans ' ||
      SUBSTR(SQLERRM, 1, 300);
      V_RESP_CDE := '21';
      RAISE EXP_REJECT_RECORD;
      END IF;
      */
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN NO_DATA_FOUND THEN
      NULL;
    WHEN OTHERS THEN
      v_err_msg  := 'Problem while selecting data from avail trans ' || SUBSTR (SQLERRM, 1, 300);
      v_resp_cde := '21';
      RAISE exp_reject_record;
    END;
    --En update daily and weekly transaction counter and amount
    --Sn create detail for response message
    -- added for mini statement
 /*   IF v_output_type = 'B' THEN
      --Balance Inquiry
      IF p_txn_code = '04' AND p_delivery_channel = '07' THEN
        BEGIN
          OPEN c_mini_tran;
          LOOP
            FETCH c_mini_tran INTO v_mini_stat_val;
            EXIT
          WHEN c_mini_tran%NOTFOUND;
            v_mini_stat_res := v_mini_stat_res || ' | ' || v_mini_stat_val;
          END LOOP;
          CLOSE c_mini_tran;
        EXCEPTION
        WHEN OTHERS THEN
          v_err_msg  := 'Problem while selecting data from C_MINI_TRAN cursor' || SUBSTR (SQLERRM, 1, 300);
          v_resp_cde := '21';
          RAISE exp_reject_record;
        END;
        IF (v_mini_stat_res IS NULL) THEN
          v_mini_stat_res   := ' ';
        ELSE
          v_mini_stat_res := SUBSTR (v_mini_stat_res, 3, LENGTH (v_mini_stat_res));
        END IF;
      ELSE
        p_resp_msg   := TO_CHAR (v_upd_amt);
        p_ledger_bal := TO_CHAR (v_upd_ledger_amt);
        -- ADDED FOR LEDGER BALANCE FOR mPAY BALANCE ENQUIRY REQUEST.
      END IF;
    END IF; */
    -- added for mini statement
    --En create detail fro response message
    --Sn mini statement
    IF v_output_type = 'M' THEN
      --Mini statement
      BEGIN
        sp_gen_mini_stmt (p_inst_code, p_card_no, v_mini_totrec, v_ministmt_output, v_ministmt_errmsg );
        IF v_ministmt_errmsg <> 'OK' THEN
          v_err_msg          := v_ministmt_errmsg;
          v_resp_cde         := '21';
          RAISE exp_reject_record;
        END IF;
        p_resp_msg := LPAD (TO_CHAR (v_mini_totrec), 2, '0') || v_ministmt_output;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_err_msg  := 'Problem while selecting data for mini statement ' || SUBSTR (SQLERRM, 1, 300);
        v_resp_cde := '21';
        RAISE exp_reject_record;
      END;
    END IF;
    --En mini statement
    v_resp_cde := '1';
    BEGIN
      --Add for PreAuth Transaction of CMSAuth;
      --Sn creating entries for preauth txn
      --if incoming message not contains checking for prod preauth expiry period
      --if preauth expiry period is not configured checking for instution expirty period
      BEGIN
        IF p_txn_code             = '11' AND p_msg = '0100' THEN
          IF p_preauth_expperiod IS NULL THEN
            SELECT cpm_pre_auth_exp_date
            INTO v_preauth_exp_period
            FROM cms_prod_mast
            WHERE cpm_prod_code      = v_prod_code;
            IF v_preauth_exp_period IS NULL THEN
              SELECT cip_param_value
              INTO v_preauth_exp_period
              FROM cms_inst_param
              WHERE cip_inst_code = p_inst_code
              AND cip_param_key   = 'PRE-AUTH EXP PERIOD';
              v_preauth_hold     := SUBSTR (TRIM (v_preauth_exp_period), 1, 1);
              v_preauth_period   := SUBSTR (TRIM (v_preauth_exp_period), 2, 2);
            ELSE
              v_preauth_hold   := SUBSTR (TRIM (v_preauth_exp_period), 1, 1);
              v_preauth_period := SUBSTR (TRIM (v_preauth_exp_period), 2, 2);
            END IF;
          ELSE
            v_preauth_hold     := SUBSTR (TRIM (p_preauth_expperiod), 1, 1);
            v_preauth_period   := SUBSTR (TRIM (p_preauth_expperiod), 2, 2);
            IF v_preauth_period = '00' THEN
              SELECT cpm_pre_auth_exp_date
              INTO v_preauth_exp_period
              FROM cms_prod_mast
              WHERE cpm_prod_code      = v_prod_code;
              IF v_preauth_exp_period IS NULL THEN
                SELECT cip_param_value
                INTO v_preauth_exp_period
                FROM cms_inst_param
                WHERE cip_inst_code = p_inst_code
                AND cip_param_key   = 'PRE-AUTH EXP PERIOD';
                v_preauth_hold     := SUBSTR (TRIM (v_preauth_exp_period), 1, 1);
                v_preauth_period   := SUBSTR (TRIM (v_preauth_exp_period), 2, 2);
              ELSE
                v_preauth_hold   := SUBSTR (TRIM (v_preauth_exp_period), 1, 1);
                v_preauth_period := SUBSTR (TRIM (v_preauth_exp_period), 2, 2);
              END IF;
            ELSE
              v_preauth_hold   := v_preauth_hold;
              v_preauth_period := v_preauth_period;
            END IF;
          END IF;
          /*
          preauth period will be added with transaction date based on preauth_hold
          IF v_preauth_hold is '0'--'Minute'
          '1'--'Hour'
          '2'--'Day'
          */
          IF v_preauth_hold = '0' THEN
            v_preauth_date := v_tran_date + (v_preauth_period * (1 / 1440));
          END IF;
          IF v_preauth_hold = '1' THEN
            v_preauth_date := v_tran_date + (v_preauth_period * (1 / 24));
          END IF;
          IF v_preauth_hold = '2' THEN
            v_preauth_date := v_tran_date + v_preauth_period;
          END IF;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21'; -- Server Declione
        v_err_msg  := 'Problem while inserting preauth transaction details' || SUBSTR (SQLERRM, 1, 300);
        RAISE exp_reject_record;
      END;
      IF v_resp_cde = '1' THEN
        --Sn find business date
        v_business_time   := TO_CHAR (v_tran_date, 'HH24:MI');
        IF v_business_time > v_cutoff_time THEN
          v_business_date := TRUNC (v_tran_date) + 1;
        ELSE
          v_business_date := TRUNC (v_tran_date);
        END IF;
        --En find businesses date

       --Sn - commented for fwr-48

      /*  BEGIN
          sp_create_gl_entries_cmsauth (p_inst_code, v_business_date, v_prod_code, v_prod_cattype, v_tran_amt, v_func_code, p_txn_code, v_dr_cr_flag, p_card_no, v_fee_code, v_total_fee, v_fee_cracct_no, v_fee_dracct_no, v_card_acct_no, p_rvsl_code, p_msg, p_delivery_channel, v_resp_cde, v_gl_upd_flag, v_gl_err_msg );
          IF v_gl_err_msg <> 'OK' OR v_gl_upd_flag <> 'Y' THEN
            v_gl_upd_flag := 'N';
            p_resp_code   := v_resp_cde;
            v_err_msg     := v_gl_err_msg;
            RAISE exp_reject_record;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          v_gl_upd_flag := 'N';
          p_resp_code   := v_resp_cde;
          v_err_msg     := v_gl_err_msg;
          RAISE exp_reject_record;
        END; */

        --En - commented for fwr-48

        --Sn find prod code and card type and available balance for the card number
        BEGIN
          SELECT cam_acct_bal
          INTO v_acct_balance
          FROM cms_acct_mast
          WHERE cam_acct_no =
            (SELECT cap_acct_no
            FROM cms_appl_pan
            WHERE cap_pan_code = v_hash_pan
            AND cap_mbr_numb   = p_mbr_numb
            AND cap_inst_code  = p_inst_code
            )
          AND cam_inst_code = p_inst_code;
          --FOR UPDATE NOWAIT;                -- Commented for Concurrent Processsing Issue
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_resp_cde := '14'; --Ineligible Transaction
          v_err_msg  := 'Invalid Card ';
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          v_resp_cde := '12';
          v_err_msg  := 'Error while selecting data from card Master for card number ' || SQLERRM;
          RAISE exp_reject_record;
        END;
        --En find prod code and card type for the card number
        IF v_output_type = 'N' THEN
          --Balance Inquiry
          p_resp_msg   := TO_CHAR (v_upd_amt);
          p_ledger_bal := TO_CHAR (v_upd_ledger_amt);
          -- ADDED FOR LEDGER BALANCE FOR mPAY BALANCE ENQUIRY REQUEST.
        END IF;
      END IF;
      --En create GL ENTRIES
      ---Sn Updation of Usage limit and amount
      BEGIN
        SELECT ctc_atmusage_amt,
          ctc_posusage_amt,
          ctc_atmusage_limit,
          ctc_posusage_limit,
          ctc_business_date,
          ctc_preauthusage_limit,
          ctc_mmposusage_amt,
          ctc_mmposusage_limit
        INTO v_atm_usageamnt,
          v_pos_usageamnt,
          v_atm_usagelimit,
          v_pos_usagelimit,
          v_business_date_tran,
          v_preauth_usage_limit,
          v_mmpos_usageamnt,
          v_mmpos_usagelimit
        FROM cms_translimit_check
        WHERE ctc_inst_code = p_inst_code
        AND ctc_pan_code    = v_hash_pan
        AND ctc_mbr_numb    = p_mbr_numb;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_err_msg  := 'Cannot get the Transaction Limit Details of the Card' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
        v_resp_cde := '21';
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        v_err_msg  := 'Error while selecting CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
        v_resp_cde := '21';
        RAISE exp_reject_record;
      END;
      BEGIN
        IF p_delivery_channel  = '01' THEN
          IF v_tran_date       > v_business_date_tran THEN
            IF p_txn_amt      IS NULL THEN
              v_atm_usageamnt := TRIM (TO_CHAR (0, '99999999999999990.99'));
            ELSE
              v_atm_usageamnt := TRIM (TO_CHAR (v_tran_amt, '99999999999999990.99'));
            END IF;
            v_atm_usagelimit := 1;
            BEGIN
              UPDATE cms_translimit_check
              SET ctc_atmusage_amt     = v_atm_usageamnt,
                ctc_atmusage_limit     = v_atm_usagelimit,
                ctc_posusage_amt       = 0,
                ctc_posusage_limit     = 0,
                ctc_preauthusage_limit = 0,
                ctc_business_date      = TO_DATE (p_tran_date
                || '23:59:59', 'yymmdd'
                || 'hh24:mi:ss' ),
                ctc_mmposusage_amt   = 0,
                ctc_mmposusage_limit = 0
              WHERE ctc_inst_code    = p_inst_code
              AND ctc_pan_code       = v_hash_pan
              AND ctc_mbr_numb       = p_mbr_numb;
              IF SQL%ROWCOUNT        = 0 THEN
                v_err_msg           := 'Error while updating 1 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
                v_resp_cde          := '21';
                RAISE exp_reject_record;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              v_err_msg  := 'Error while updating 1 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
              v_resp_cde := '21';
              RAISE exp_reject_record;
            END;
          ELSE
            IF p_txn_amt      IS NULL THEN
              v_atm_usageamnt := v_atm_usageamnt + TRIM (TO_CHAR (0, '99999999999999990.99'));
            ELSE
              v_atm_usageamnt := v_atm_usageamnt + TRIM (TO_CHAR (v_tran_amt, '99999999999999990.99'));
            END IF;
            v_atm_usagelimit := v_atm_usagelimit + 1;
            BEGIN
              UPDATE cms_translimit_check
              SET ctc_atmusage_amt = v_atm_usageamnt,
                ctc_atmusage_limit = v_atm_usagelimit
              WHERE ctc_inst_code  = p_inst_code
              AND ctc_pan_code     = v_hash_pan
              AND ctc_mbr_numb     = p_mbr_numb;
              IF SQL%ROWCOUNT      = 0 THEN
                v_err_msg         := 'Error while updating 2 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
                v_resp_cde        := '21';
                RAISE exp_reject_record;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              v_err_msg  := 'Error while updating 2 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
              v_resp_cde := '21';
              RAISE exp_reject_record;
            END;
          END IF;
        END IF;
        IF p_delivery_channel  = '02' THEN
          IF v_tran_date       > v_business_date_tran THEN
            IF p_txn_amt      IS NULL THEN
              v_pos_usageamnt := TRIM (TO_CHAR (0, '99999999999999990.99'));
            ELSE
              v_pos_usageamnt := TRIM (TO_CHAR (v_tran_amt, '99999999999999990.99'));
            END IF;
            v_pos_usagelimit        := 1;
            IF p_txn_code            = '11' AND p_msg = '0100' THEN
              v_preauth_usage_limit := 1;
              v_pos_usageamnt       := 0;
            ELSE
              v_preauth_usage_limit := 0;
            END IF;
            BEGIN
              UPDATE cms_translimit_check
              SET ctc_posusage_amt = v_pos_usageamnt,
                ctc_posusage_limit = v_pos_usagelimit,
                ctc_atmusage_amt   = 0,
                ctc_atmusage_limit = 0,
                ctc_business_date  = TO_DATE (p_tran_date
                || '23:59:59', 'yymmdd'
                || 'hh24:mi:ss' ),
                ctc_preauthusage_limit = v_preauth_usage_limit,
                ctc_mmposusage_amt     = 0,
                ctc_mmposusage_limit   = 0
              WHERE ctc_inst_code      = p_inst_code
              AND ctc_pan_code         = v_hash_pan
              AND ctc_mbr_numb         = p_mbr_numb;
              IF SQL%ROWCOUNT          = 0 THEN
                v_err_msg             := 'Error while updating 3 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
                v_resp_cde            := '21';
                RAISE exp_reject_record;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              v_err_msg  := 'Error while updating 3 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
              v_resp_cde := '21';
              RAISE exp_reject_record;
            END;
          ELSE
            v_pos_usagelimit        := v_pos_usagelimit + 1;
            IF p_txn_code            = '11' AND p_msg = '0100' THEN
              v_preauth_usage_limit := v_preauth_usage_limit + 1;
              v_pos_usageamnt       := v_pos_usageamnt;
            ELSE
              IF p_txn_amt      IS NULL THEN
                v_pos_usageamnt := v_pos_usageamnt + TRIM (TO_CHAR (0, '99999999999999990.99'));
              ELSE
                IF v_dr_cr_flag    = 'CR' THEN
                  v_pos_usageamnt := v_pos_usageamnt;
                ELSE
                  v_pos_usageamnt := v_pos_usageamnt + TRIM (TO_CHAR (v_tran_amt, '99999999999999990.99' ) );
                END IF;
              END IF;
            END IF;
            BEGIN
              UPDATE cms_translimit_check
              SET ctc_posusage_amt     = v_pos_usageamnt,
                ctc_posusage_limit     = v_pos_usagelimit,
                ctc_preauthusage_limit = v_preauth_usage_limit
              WHERE ctc_inst_code      = p_inst_code
              AND ctc_pan_code         = v_hash_pan
              AND ctc_mbr_numb         = p_mbr_numb;
              IF SQL%ROWCOUNT          = 0 THEN
                v_err_msg             := 'Error while updating 4 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
                v_resp_cde            := '21';
                RAISE exp_reject_record;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              v_err_msg  := 'Error while updating 4 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
              v_resp_cde := '21';
              RAISE exp_reject_record;
            END;
          END IF;
        END IF;
        --Sn Usage limit and amount updation for MMPOS
        IF p_delivery_channel    = '04' THEN
          IF v_tran_date         > v_business_date_tran THEN
            IF p_txn_amt        IS NULL THEN
              v_mmpos_usageamnt := TRIM (TO_CHAR (0, '99999999999999990.99'));
            ELSE
              v_mmpos_usageamnt := TRIM (TO_CHAR (v_tran_amt, '99999999999999990.99'));
            END IF;
            v_mmpos_usagelimit := 1;
            BEGIN
              UPDATE cms_translimit_check
              SET ctc_mmposusage_amt = v_mmpos_usageamnt,
                ctc_mmposusage_limit = v_mmpos_usagelimit,
                ctc_atmusage_amt     = 0,
                ctc_atmusage_limit   = 0,
                ctc_business_date    = TO_DATE (p_tran_date
                || '23:59:59', 'yymmdd'
                || 'hh24:mi:ss' ),
                ctc_preauthusage_limit = 0,
                ctc_posusage_amt       = 0,
                ctc_posusage_limit     = 0
              WHERE ctc_inst_code      = p_inst_code
              AND ctc_pan_code         = v_hash_pan
              AND ctc_mbr_numb         = p_mbr_numb;
              IF SQL%ROWCOUNT          = 0 THEN
                v_err_msg             := 'Error while updating 5 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
                v_resp_cde            := '21';
                RAISE exp_reject_record;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              v_err_msg  := 'Error while updating 5 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
              v_resp_cde := '21';
              RAISE exp_reject_record;
            END;
          ELSE
            v_mmpos_usagelimit  := v_mmpos_usagelimit + 1;
            IF p_txn_amt        IS NULL THEN
              v_mmpos_usageamnt := v_mmpos_usageamnt + TRIM (TO_CHAR (0, 999999999999999));
            ELSE
              v_mmpos_usageamnt := v_mmpos_usageamnt + TRIM (TO_CHAR (v_tran_amt, '99999999999999990.99'));
            END IF;
            BEGIN
              UPDATE cms_translimit_check
              SET ctc_mmposusage_amt = v_mmpos_usageamnt,
                ctc_mmposusage_limit = v_mmpos_usagelimit
              WHERE ctc_inst_code    = p_inst_code
              AND ctc_pan_code       = v_hash_pan
              AND ctc_mbr_numb       = p_mbr_numb;
              IF SQL%ROWCOUNT        = 0 THEN
                v_err_msg           := 'Error while updating 6 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
                v_resp_cde          := '21';
                RAISE exp_reject_record;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              v_err_msg  := 'Error while updating 6 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
              v_resp_cde := '21';
              RAISE exp_reject_record;
            END;
          END IF;
        END IF;
        --En Usage limit and amount updation for MMPOS
      END;
    END;
    ---En Updation of Usage limit and amount
    BEGIN
      SELECT cms_iso_respcde
      INTO p_resp_code
      FROM cms_response_mast
      WHERE cms_inst_code      = p_inst_code
      AND cms_delivery_channel = p_delivery_channel
      AND cms_response_id      = TO_NUMBER (v_resp_cde);
    EXCEPTION
    WHEN OTHERS THEN
      v_err_msg  := 'Problem while selecting data from response master for respose code' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
      v_resp_cde := '21';
      RAISE exp_reject_record;
    END;
    ---
    /* Start  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
    BEGIN
      IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
        pkg_limits_check.sp_limitcnt_reset (p_inst_code, v_hash_pan, v_limit_amt, --Added on 04-Feb-2013 for FSS-821
        --p_txn_amt, -- commented on 04-Feb-2013 for FSS-821
        v_comb_hash, v_resp_cde, v_error );
      END IF;
      IF v_error <> 'OK' THEN
        --v_resp_cde := '21'; -- Commented on 12-Feb-2013
        v_err_msg := 'From Procedure sp_limitcnt_reset' || v_error;
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg  := 'Error from Limit Reset Count Process ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    /* End  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
  EXCEPTION
    --<< MAIN EXCEPTION >>
  WHEN exp_reject_record THEN
    ROLLBACK TO v_auth_savepoint;
    --St Added by Ramesh.A on 18/07/2012 for MMPOS Balance Enquiry
    IF (( p_delivery_channel = '04' AND p_txn_code = '94' ) OR ( p_delivery_channel = '14' AND p_txn_code = '13' )) -- Added for medagate Changes defect id:MVHOST-387
      THEN
      BEGIN
        SELECT cap.cap_card_stat,
          cap.cap_acct_no,
          cpm.cpm_prod_desc,
          cpc.cpc_cardtype_desc,
          cpc.cpc_program_id,
          ccs.CCS_STAT_DESC
        INTO p_card_status,
          p_dda_number,
          p_prod_desc,
          p_prod_cat_desc,
          p_prod_id,       --Added by siva kumar on 01/08/2012.
          v_card_stat_desc -- Added for medagate Changes defect id:MVHOST-387
        FROM cms_appl_pan cap,
          cms_prod_mast cpm,
          cms_prod_cattype cpc,
          cms_card_stat ccs
        WHERE cpm_inst_code   = cpc_inst_code
        AND cpm_prod_code     = cpc_prod_code
        AND cpm_prod_code     = cap.cap_prod_code
        AND cpc_card_type     = cap.cap_card_type
        AND cap_inst_code     = cpm_inst_code --Added On 05.08.2013 for MVHOST-505
        AND cap.cap_pan_code  = v_hash_pan
        AND cap.cap_inst_code = p_inst_code
        AND cap.cap_card_stat =ccs.CCS_STAT_CODE
        AND cap.CAP_INST_CODE = ccs.CCS_INST_CODE; -- Added for medagate Changes defect id:MVHOST-387
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        p_resp_msg  := 'No Data Found in getting prod desc , prod cattype desc';
        p_resp_code := '69';
        RAISE;
      WHEN OTHERS THEN
        p_resp_msg  := 'Error while selecting prod desc and prod catype desc ' || SUBSTR (SQLERRM, 1, 200);
        p_resp_code := '69';
        RAISE;
      END;
      --ST Added for medagate Changes defect id:MVHOST-387
      IF p_delivery_channel = '14' AND p_txn_code = '13' THEN
        p_prod_cat_desc    := v_card_stat_desc;
      END IF;
      --EN  Added for medagate Changes defect id:MVHOST-387
      IF p_delivery_channel <> '14' AND p_txn_code <> '13' THEN -- Added for medagate Changes defect id:MVHOST-387
        BEGIN
          BEGIN
            --Get Fee Plan ID from card level
            SELECT cce_fee_plan
            INTO p_fee_plan_id
            FROM cms_card_excpfee
            WHERE cce_inst_code = p_inst_code
            AND cce_pan_code    = v_hash_pan;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            BEGIN
              SELECT cpf_fee_plan
              INTO p_fee_plan_id
              FROM cms_prodcattype_fees
              WHERE cpf_inst_code = p_inst_code
              AND cpf_prod_code   = v_prod_code
              AND cpf_card_type   = v_prod_cattype;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              BEGIN
                SELECT cpf_fee_plan
                INTO p_fee_plan_id
                FROM cms_prod_fees
                WHERE cpf_inst_code = p_inst_code
                AND cpf_prod_code   = v_prod_code;
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                p_fee_plan_id := '';
              WHEN OTHERS THEN
                p_resp_msg  := 'Error while selecting --Get Fee Plan ID FROM PRODUCT LEVEL ' || SUBSTR (SQLERRM, 1, 200);
                p_resp_code := '69';
                RAISE;
              END;
            WHEN OTHERS THEN
              p_resp_msg  := 'Error while selecting --Get Fee Plan ID FROM PRODUCT CARD TYPE LEVEL ' || SUBSTR (SQLERRM, 1, 200);
              p_resp_code := '69';
              RAISE;
            END;
          WHEN OTHERS THEN
            p_resp_msg  := 'Error while selecting --Get Fee Plan ID FROM CARDLEVEL ' || SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '69';
            RAISE;
          END;
        EXCEPTION
        WHEN OTHERS THEN
          p_resp_msg  := 'Error while selecting --Get Fee Plan ID  ' || SUBSTR (SQLERRM, 1, 200);
          p_resp_code := '69';
          RAISE;
        END;
      END IF;
    END IF;
    --En Added by Ramesh.A on 18/07/2012 for MMPOS Balance Enquiry
    BEGIN
      SELECT cam_acct_bal,
        cam_ledger_bal,
        cam_acct_no,
        cam_type_code --Added for defect 10871
      INTO v_acct_balance,
        v_ledger_bal,
        v_acct_number,
        v_cam_type_code --Added for defect 10871
      FROM cms_acct_mast
      WHERE cam_acct_no =
        (SELECT cap_acct_no
        FROM cms_appl_pan
        WHERE cap_pan_code = v_hash_pan
        AND cap_inst_code  = p_inst_code
        )
      AND cam_inst_code = p_inst_code;
    EXCEPTION
    WHEN OTHERS THEN
      v_acct_balance := 0;
      v_ledger_bal   := 0;
    END;
--    BEGIN
--      SELECT ctc_atmusage_limit,
--        ctc_posusage_limit,
--        ctc_business_date,
--        ctc_preauthusage_limit,
--        ctc_mmposusage_limit
--      INTO v_atm_usagelimit,
--        v_pos_usagelimit,
--        v_business_date_tran,
--        v_preauth_usage_limit,
--        v_mmpos_usagelimit
--      FROM cms_translimit_check
--      WHERE ctc_inst_code = p_inst_code
--      AND ctc_pan_code    = v_hash_pan
--      AND ctc_mbr_numb    = p_mbr_numb;
--    EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--      v_err_msg  := 'Cannot get the Transaction Limit Details of the Card' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
--      v_resp_cde := '21';
--      RAISE exp_reject_record;
--    WHEN OTHERS THEN
--      v_err_msg  := 'Error while selecting 1 CMS_TRANSLIMIT_CHECK' || SUBSTR (SQLERRM, 1, 200);
--      v_resp_cde := '21';
--      RAISE exp_reject_record;
--    END;
--    BEGIN
--      IF p_delivery_channel = '01' THEN
--        IF v_tran_date      > v_business_date_tran THEN
--          v_atm_usageamnt  := 0;
--          v_atm_usagelimit := 1;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_atmusage_amt     = v_atm_usageamnt,
--              ctc_atmusage_limit     = v_atm_usagelimit,
--              ctc_posusage_amt       = 0,
--              ctc_posusage_limit     = 0,
--              ctc_preauthusage_limit = 0,
--              ctc_mmposusage_amt     = 0,
--              ctc_mmposusage_limit   = 0,
--              ctc_business_date      = TO_DATE (p_tran_date
--              || '23:59:59', 'yymmdd'
--              || 'hh24:mi:ss' )
--            WHERE ctc_inst_code = p_inst_code
--            AND ctc_pan_code    = v_hash_pan
--            AND ctc_mbr_numb    = p_mbr_numb;
--            IF SQL%ROWCOUNT     = 0 THEN
--              v_err_msg        := 'Error while updating 7 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde       := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 7 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        ELSE
--          v_atm_usagelimit := v_atm_usagelimit + 1;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_atmusage_limit = v_atm_usagelimit
--            WHERE ctc_inst_code    = p_inst_code
--            AND ctc_pan_code       = v_hash_pan
--            AND ctc_mbr_numb       = p_mbr_numb;
--            IF SQL%ROWCOUNT        = 0 THEN
--              v_err_msg           := 'Error while updating 8 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde          := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 8 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        END IF;
--      END IF;
--      IF p_delivery_channel      = '02' THEN
--        IF v_tran_date           > v_business_date_tran THEN
--          v_pos_usageamnt       := 0;
--          v_pos_usagelimit      := 1;
--          v_preauth_usage_limit := 0;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_posusage_amt   = v_pos_usageamnt,
--              ctc_posusage_limit   = v_pos_usagelimit,
--              ctc_atmusage_amt     = 0,
--              ctc_atmusage_limit   = 0,
--              ctc_mmposusage_amt   = 0,
--              ctc_mmposusage_limit = 0,
--              ctc_business_date    = TO_DATE (p_tran_date
--              || '23:59:59', 'yymmdd'
--              || 'hh24:mi:ss' ),
--              ctc_preauthusage_limit = v_preauth_usage_limit
--            WHERE ctc_inst_code      = p_inst_code
--            AND ctc_pan_code         = v_hash_pan
--            AND ctc_mbr_numb         = p_mbr_numb;
--            IF SQL%ROWCOUNT          = 0 THEN
--              v_err_msg             := 'Error while updating 9 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde            := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 9 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        ELSE
--          v_pos_usagelimit := v_pos_usagelimit + 1;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_posusage_limit = v_pos_usagelimit
--            WHERE ctc_inst_code    = p_inst_code
--            AND ctc_pan_code       = v_hash_pan
--            AND ctc_mbr_numb       = p_mbr_numb;
--            IF SQL%ROWCOUNT        = 0 THEN
--              v_err_msg           := 'Error while updating 10 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde          := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 10 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        END IF;
--      END IF;
--      --Sn Usage limit updation for MMPOS
--      IF p_delivery_channel   = '04' THEN
--        IF v_tran_date        > v_business_date_tran THEN
--          v_mmpos_usageamnt  := 0;
--          v_mmpos_usagelimit := 1;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_posusage_amt   = 0,
--              ctc_posusage_limit   = 0,
--              ctc_atmusage_amt     = 0,
--              ctc_atmusage_limit   = 0,
--              ctc_mmposusage_amt   = v_mmpos_usageamnt,
--              ctc_mmposusage_limit = v_mmpos_usagelimit,
--              ctc_business_date    = TO_DATE (p_tran_date
--              || '23:59:59', 'yymmdd'
--              || 'hh24:mi:ss' ),
--              ctc_preauthusage_limit = 0
--            WHERE ctc_inst_code      = p_inst_code
--            AND ctc_pan_code         = v_hash_pan
--            AND ctc_mbr_numb         = p_mbr_numb;
--            IF SQL%ROWCOUNT          = 0 THEN
--              v_err_msg             := 'Error while updating 11 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde            := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 11 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        ELSE
--          v_mmpos_usagelimit := v_mmpos_usagelimit + 1;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_mmposusage_limit = v_mmpos_usagelimit
--            WHERE ctc_inst_code      = p_inst_code
--            AND ctc_pan_code         = v_hash_pan
--            AND ctc_mbr_numb         = p_mbr_numb;
--            IF SQL%ROWCOUNT          = 0 THEN
--              v_err_msg             := 'Error while updating 12 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde            := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 12 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        END IF;
--      END IF;
--      --En Usage limit updation for MMPOS
--    END;
    --Sn select response code and insert record into txn log dtl
    BEGIN
      p_resp_code := v_resp_cde;
      p_resp_msg  := v_err_msg;
      -- Assign the response code to the out parameter
      SELECT cms_iso_respcde
      INTO p_resp_code
      FROM cms_response_mast
      WHERE cms_inst_code      = p_inst_code
      AND cms_delivery_channel = p_delivery_channel
      AND cms_response_id      = v_resp_cde;
    EXCEPTION
    WHEN OTHERS THEN
      p_resp_msg  := 'Problem while selecting data from response master ' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
      p_resp_code := '69';
      ---ISO MESSAGE FOR DATABASE ERROR Server Declined
      ROLLBACK;
    END;

     --Sn Commented for Transactionlog Functional Removal
    /*BEGIN
      IF v_rrn_count                      > 0 THEN
        IF TO_NUMBER (p_delivery_channel) = 8 THEN
          BEGIN
            SELECT response_code
            INTO v_resp_cde
            FROM transactionlog a,
              (SELECT MIN (add_ins_date) mindate FROM transactionlog WHERE rrn = p_rrn
              ) b
            WHERE a.add_ins_date = mindate
            AND rrn              = p_rrn;
            p_resp_code         := v_resp_cde;
            SELECT acct_balance
            INTO v_acct_balance
            FROM transactionlog
            WHERE rrn         = p_rrn
            AND business_date = p_tran_date
            AND ROWNUM        = 1;
            v_err_msg        := TO_CHAR (v_acct_balance);
          EXCEPTION
          WHEN OTHERS THEN
            v_err_msg   := 'Problem in selecting the response detail of Original transaction' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89'; -- Server Declined
            ROLLBACK;
            RETURN;
          END;
        END IF;
      END IF;
    END;*/
    --En Commented for Transactionlog Functional Removal

    BEGIN
      INSERT
      INTO cms_transaction_log_dtl
        (
          ctd_delivery_channel,
          ctd_txn_code,
          ctd_txn_type,
          ctd_msg_type,
          ctd_txn_mode,
          ctd_business_date,
          ctd_business_time,
          ctd_customer_card_no,
          ctd_txn_amount,
          ctd_txn_curr,
          ctd_actual_amount,
          ctd_fee_amount,
          ctd_waiver_amount,
          ctd_servicetax_amount,
          ctd_cess_amount,
          ctd_bill_amount,
          ctd_bill_curr,
          ctd_process_flag,
          ctd_process_msg,
          ctd_rrn,
          ctd_system_trace_audit_no,
          ctd_inst_code,
          ctd_customer_card_no_encr,
          ctd_cust_acct_number,
          ctd_internation_ind_response,
          /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          ctd_network_id,
          ctd_interchange_feeamt,
          ctd_merchant_zip,
          /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          CTD_MERCHANT_ID --Added on 19-Mar-2013 for FSS-970
          ,ctd_reason_code,
          ctd_hashkey_id
        )
        VALUES
        (
          p_delivery_channel,
          p_txn_code,
          v_txn_type,
          p_msg,
          p_txn_mode,
          p_tran_date,
          p_tran_time,
          v_hash_pan,
          p_txn_amt,
          p_curr_code,
          v_tran_amt,
          NULL,
          NULL,
          NULL,
          NULL,
          v_total_amt,
          v_card_curr,
          'E',
          v_err_msg,
          p_rrn,
          p_stan,
          p_inst_code,
          v_encr_pan,
          v_acct_number,
          p_international_ind,
          /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          p_network_id,
          p_interchange_feeamt,
          p_merchant_zip,
          /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          P_MERCHANT_ID --Added on 19-Mar-2013 for FSS-970
          ,p_reasoncode_in,
          v_hashkey_id
        );
      p_resp_msg := v_err_msg;
    EXCEPTION
    WHEN OTHERS THEN
      p_resp_msg  := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
      p_resp_code := '69'; -- Server Declined
      ROLLBACK;
      RETURN;
    END;
    -----------------------------------------------
    --SN: Added on 20-Apr-2013 for defect 10871
    -----------------------------------------------
    IF V_PROD_CODE IS NULL THEN
      BEGIN
        SELECT CAP_PROD_CODE,
          CAP_CARD_TYPE,
          CAP_CARD_STAT,
          CAP_ACCT_NO
        INTO V_PROD_CODE,
          V_PROD_CATTYPE,
          V_APPLPAN_CARDSTAT,
          V_ACCT_NUMBER
        FROM CMS_APPL_PAN
        WHERE CAP_INST_CODE = P_INST_CODE
        AND CAP_PAN_CODE    = V_HASH_PAN; --P_card_no;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    IF V_DR_CR_FLAG IS NULL THEN
      BEGIN
        SELECT CTM_CREDIT_DEBIT_FLAG
        INTO V_DR_CR_FLAG
        FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE      = P_TXN_CODE
        AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CTM_INST_CODE        = P_INST_CODE;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    IF v_timestamp IS NULL THEN
      v_timestamp  := systimestamp; -- Added on 20-Apr-2013 for defect 10871
    END IF;
    -----------------------------------------------
    --EN: Added on 20-Apr-2013 for defect 10871
    -----------------------------------------------
  WHEN OTHERS THEN
    ROLLBACK TO v_auth_savepoint;
--    BEGIN
--      SELECT ctc_atmusage_limit,
--        ctc_posusage_limit,
--        ctc_business_date,
--        ctc_preauthusage_limit,
--        ctc_mmposusage_limit
--      INTO v_atm_usagelimit,
--        v_pos_usagelimit,
--        v_business_date_tran,
--        v_preauth_usage_limit,
--        v_mmpos_usagelimit
--      FROM cms_translimit_check
--      WHERE ctc_inst_code = p_inst_code
--      AND ctc_pan_code    = v_hash_pan
--      AND ctc_mbr_numb    = p_mbr_numb;
--    EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--      v_err_msg  := 'Cannot get the Transaction Limit Details of the Card' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
--      v_resp_cde := '21';
--      RAISE exp_reject_record;
--    WHEN OTHERS THEN
--      v_err_msg  := 'Error while selecting 2 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--      v_resp_cde := '21';
--      RAISE exp_reject_record;
--    END;
--    BEGIN
--      IF p_delivery_channel = '01' THEN
--        IF v_tran_date      > v_business_date_tran THEN
--          v_atm_usageamnt  := 0;
--          v_atm_usagelimit := 1;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_atmusage_amt     = v_atm_usageamnt,
--              ctc_atmusage_limit     = v_atm_usagelimit,
--              ctc_posusage_amt       = 0,
--              ctc_posusage_limit     = 0,
--              ctc_preauthusage_limit = 0,
--              ctc_mmposusage_amt     = 0,
--              ctc_mmposusage_limit   = 0,
--              ctc_business_date      = TO_DATE (p_tran_date
--              || '23:59:59', 'yymmdd'
--              || 'hh24:mi:ss' )
--            WHERE ctc_inst_code = p_inst_code
--            AND ctc_pan_code    = v_hash_pan
--            AND ctc_mbr_numb    = p_mbr_numb;
--            IF SQL%ROWCOUNT     = 0 THEN
--              v_err_msg        := 'Error while updating 13 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde       := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 13 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        ELSE
--          v_atm_usagelimit := v_atm_usagelimit + 1;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_atmusage_limit = v_atm_usagelimit
--            WHERE ctc_inst_code    = p_inst_code
--            AND ctc_pan_code       = v_hash_pan
--            AND ctc_mbr_numb       = p_mbr_numb;
--            IF SQL%ROWCOUNT        = 0 THEN
--              v_err_msg           := 'Error while updating 14 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde          := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 14 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        END IF;
--      END IF;
--      IF p_delivery_channel      = '02' THEN
--        IF v_tran_date           > v_business_date_tran THEN
--          v_pos_usageamnt       := 0;
--          v_pos_usagelimit      := 1;
--          v_preauth_usage_limit := 0;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_posusage_amt   = v_pos_usageamnt,
--              ctc_posusage_limit   = v_pos_usagelimit,
--              ctc_atmusage_amt     = 0,
--              ctc_atmusage_limit   = 0,
--              ctc_mmposusage_amt   = 0,
--              ctc_mmposusage_limit = 0,
--              ctc_business_date    = TO_DATE (p_tran_date
--              || '23:59:59', 'yymmdd'
--              || 'hh24:mi:ss' ),
--              ctc_preauthusage_limit = v_preauth_usage_limit
--            WHERE ctc_inst_code      = p_inst_code
--            AND ctc_pan_code         = v_hash_pan
--            AND ctc_mbr_numb         = p_mbr_numb;
--            IF SQL%ROWCOUNT          = 0 THEN
--              v_err_msg             := 'Error while updating 15 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde            := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 15 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        ELSE
--          v_pos_usagelimit := v_pos_usagelimit + 1;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_posusage_limit = v_pos_usagelimit
--            WHERE ctc_inst_code    = p_inst_code
--            AND ctc_pan_code       = v_hash_pan
--            AND ctc_mbr_numb       = p_mbr_numb;
--            IF SQL%ROWCOUNT        = 0 THEN
--              v_err_msg           := 'Error while updating 16 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde          := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 16 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        END IF;
--      END IF;
--      --Sn Usage limit updation for MMPOS
--      IF p_delivery_channel   = '04' THEN
--        IF v_tran_date        > v_business_date_tran THEN
--          v_mmpos_usageamnt  := 0;
--          v_mmpos_usagelimit := 1;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_posusage_amt   = 0,
--              ctc_posusage_limit   = 0,
--              ctc_atmusage_amt     = 0,
--              ctc_atmusage_limit   = 0,
--              ctc_mmposusage_amt   = v_mmpos_usageamnt,
--              ctc_mmposusage_limit = v_mmpos_usagelimit,
--              ctc_business_date    = TO_DATE (p_tran_date
--              || '23:59:59', 'yymmdd'
--              || 'hh24:mi:ss' ),
--              ctc_preauthusage_limit = 0
--            WHERE ctc_inst_code      = p_inst_code
--            AND ctc_pan_code         = v_hash_pan
--            AND ctc_mbr_numb         = p_mbr_numb;
--            IF SQL%ROWCOUNT          = 0 THEN
--              v_err_msg             := 'Error while updating 17 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde            := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 17 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        ELSE
--          v_pos_usagelimit := v_pos_usagelimit + 1;
--          BEGIN
--            UPDATE cms_translimit_check
--            SET ctc_posusage_limit = v_pos_usagelimit
--            WHERE ctc_inst_code    = p_inst_code
--            AND ctc_pan_code       = v_hash_pan
--            AND ctc_mbr_numb       = p_mbr_numb;
--            IF SQL%ROWCOUNT        = 0 THEN
--              v_err_msg           := 'Error while updating 18 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--              v_resp_cde          := '21';
--              RAISE exp_reject_record;
--            END IF;
--          EXCEPTION
--          WHEN OTHERS THEN
--            v_err_msg  := 'Error while updating 18 CMS_TRANSLIMIT_CHECK ' || SUBSTR (SQLERRM, 1, 200);
--            v_resp_cde := '21';
--            RAISE exp_reject_record;
--          END;
--        END IF;
--      END IF;
--      --En Usage limit updation for MMPOS
--    END;
    --Sn select response code and insert record into txn log dtl
    BEGIN
      SELECT cms_iso_respcde
      INTO p_resp_code
      FROM cms_response_mast
      WHERE cms_inst_code      = p_inst_code
      AND cms_delivery_channel = p_delivery_channel
      AND cms_response_id      = v_resp_cde;
      p_resp_msg              := v_err_msg;
    EXCEPTION
    WHEN OTHERS THEN
      p_resp_msg  := 'Problem while selecting data from response master ' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
      p_resp_code := '69'; -- Server Declined
      ROLLBACK;
    END;
    BEGIN
      INSERT
      INTO cms_transaction_log_dtl
        (
          ctd_delivery_channel,
          ctd_txn_code,
          ctd_txn_type,
          ctd_msg_type,
          ctd_txn_mode,
          ctd_business_date,
          ctd_business_time,
          ctd_customer_card_no,
          ctd_txn_amount,
          ctd_txn_curr,
          ctd_actual_amount,
          ctd_fee_amount,
          ctd_waiver_amount,
          ctd_servicetax_amount,
          ctd_cess_amount,
          ctd_bill_amount,
          ctd_bill_curr,
          ctd_process_flag,
          ctd_process_msg,
          ctd_rrn,
          ctd_system_trace_audit_no,
          ctd_inst_code,
          ctd_customer_card_no_encr,
          ctd_cust_acct_number,
          ctd_internation_ind_response,
          /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          ctd_network_id,
          ctd_interchange_feeamt,
          ctd_merchant_zip,
          /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          CTD_MERCHANT_ID --Added on 19-Mar-2013 for FSS-970
          ,ctd_reason_code
        )
        VALUES
        (
          p_delivery_channel,
          p_txn_code,
          v_txn_type,
          p_msg,
          p_txn_mode,
          p_tran_date,
          p_tran_time,
          v_hash_pan,
          p_txn_amt,
          p_curr_code,
          v_tran_amt,
          NULL,
          NULL,
          NULL,
          NULL,
          v_total_amt,
          v_card_curr,
          'E',
          v_err_msg,
          p_rrn,
          p_stan,
          p_inst_code,
          v_encr_pan,
          v_acct_number,
          p_international_ind,
          /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          p_network_id,
          p_interchange_feeamt,
          p_merchant_zip,
          /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
          P_MERCHANT_ID --Added on 19-Mar-2013 for FSS-970
          ,p_reasoncode_in
        );
    EXCEPTION
    WHEN OTHERS THEN
      p_resp_msg  := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
      p_resp_code := '69'; -- Server Decline Response 220509
      ROLLBACK;
      RETURN;
    END;
    --En select response code and insert record into txn log dtl
    -----------------------------------------------
    --SN: Added on 20-Apr-2013 for defect 10871
    -----------------------------------------------
    IF v_acct_balance IS NULL THEN
      BEGIN
        SELECT cam_acct_bal,
          cam_ledger_bal,
          cam_acct_no,
          cam_type_code --Added for defect 10871
        INTO v_acct_balance,
          v_ledger_bal,
          v_acct_number,
          v_cam_type_code --Added for defect 10871
        FROM cms_acct_mast
        WHERE cam_acct_no =
          (SELECT cap_acct_no
          FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan
          AND cap_inst_code  = p_inst_code
          )
        AND cam_inst_code = p_inst_code;
      EXCEPTION
      WHEN OTHERS THEN
        v_acct_balance := 0;
        v_ledger_bal   := 0;
      END;
    END IF;
    IF V_PROD_CODE IS NULL THEN
      BEGIN
        SELECT CAP_PROD_CODE,
          CAP_CARD_TYPE,
          CAP_CARD_STAT,
          CAP_ACCT_NO
        INTO V_PROD_CODE,
          V_PROD_CATTYPE,
          V_APPLPAN_CARDSTAT,
          V_ACCT_NUMBER
        FROM CMS_APPL_PAN
        WHERE CAP_INST_CODE = P_INST_CODE
        AND CAP_PAN_CODE    = V_HASH_PAN; --P_card_no;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    IF V_DR_CR_FLAG IS NULL THEN
      BEGIN
        SELECT CTM_CREDIT_DEBIT_FLAG
        INTO V_DR_CR_FLAG
        FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE      = P_TXN_CODE
        AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CTM_INST_CODE        = P_INST_CODE;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    IF v_timestamp IS NULL THEN
      v_timestamp  := systimestamp; -- Added on 20-Apr-2013 for defect 10871
    END IF;
    -----------------------------------------------
    --EN: Added on 20-Apr-2013 for defect 10871
    -----------------------------------------------
  END;
  --- Sn create GL ENTRIES
  --Sn create a entry in txn log
  BEGIN
    INSERT
    INTO transactionlog
      (
        msgtype,
        rrn,
        delivery_channel,
        terminal_id,
        date_time,
        txn_code,
        txn_type,
        txn_mode,
        txn_status,
        response_code,
        business_date,
        business_time,
        customer_card_no,
        topup_card_no,
        topup_acct_no,
        topup_acct_type,
        bank_code,
        total_amount,
        rule_indicator,
        rulegroupid,
        mccode,
        currencycode,
        addcharge,
        productid,
        categoryid,
        tips,
        decline_ruleid,
        atm_name_location,
        auth_id,
        trans_desc,
        amount,
        preauthamount,
        partialamount,
        mccodegroupid,
        currencycodegroupid,
        transcodegroupid,
        rules,
        preauth_date,
        gl_upd_flag,
        system_trace_audit_no,
        instcode,
        feecode,
        tranfee_amt,
        servicetax_amt,
        cess_amt,
        cr_dr_flag,
        tranfee_cr_acctno,
        tranfee_dr_acctno,
        tran_st_calc_flag,
        tran_cess_calc_flag,
        tran_st_cr_acctno,
        tran_st_dr_acctno,
        tran_cess_cr_acctno,
        tran_cess_dr_acctno,
        customer_card_no_encr,
        topup_card_no_encr,
        proxy_number,
        reversal_code,
        customer_acct_no,
        acct_balance,
        ledger_balance,
        internation_ind_response,
        response_id,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        network_id,
        interchange_feeamt,
        merchant_zip,
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        fee_plan,
        pos_verification,
        --Added by Deepa on July 03 2012 to log the verification of POS
        feeattachtype,
        -- Added by Trivikram on 05-Sep-2012
        merchant_name,
        -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        merchant_city,
        -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        merchant_state,
        -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        network_settl_date,
        -- Added on 201112 for logging N/W settlement date in transactionlog
        error_msg,           -- Added on 06-Feb-2013 ,same was missing
        MERCHANT_ID,         --Added on 19-Mar-2013 for FSS-970
        acct_type,           --Added for defect 10871
        time_stamp,          --Added for defect 10871
        cardstatus,          --Added for defect 10871
        medagateref_id,      -- Added for Medagate changes.
        NETWORKID_ACQUIRER , -- Added for LYFE Changes
        networkid_switch,     --Added by Abdul Hameed M.A on 25 Feb 2014 for Mantis ID 13736
        remark, --Added for error msg need to display in CSR(declined by rule)
        fundingaccount --added VMS-454
      )
      VALUES
      (
        p_msg,
        p_rrn,
        p_delivery_channel,
        p_term_id,
        v_business_date,
        p_txn_code,
        v_txn_type,
        p_txn_mode,
        DECODE (p_resp_code, '00', 'C', 'F'),
        p_resp_code,
        p_tran_date,
        p_tran_time,
        v_hash_pan,
        NULL,
        NULL, --P_topup_acctno    ,
        NULL, --P_topup_accttype,
        p_bank_code,
        TRIM (TO_CHAR (NVL(v_total_amt,0), '99999999999999990.99')), --NVL added for defect 10871
        NULL,
        NULL,
        p_mcc_code,
        p_curr_code,
        NULL, -- P_add_charge,
        v_prod_code,
        v_prod_cattype,
        TRIM (TO_CHAR (NVL(p_tip_amt,0), '99999999999999990.99')), --TRIM(To_CHAR added for defect 10871
        p_decline_ruleid,
        p_atmname_loc,
        v_auth_id,
        v_trans_desc,
        TRIM (TO_CHAR (NVL(v_tran_amt,0), '99999999999999990.99')), --NVL added for defect 10871
        '0.00',
        '0.00', -- NULL replaced by 0.00 , on 20-Apr-2013 for defect 10871
        -- Partial amount (will be given for partial txn)
        p_mcccode_groupid,
        p_currcode_groupid,
        p_transcode_groupid,
        p_rules,
        p_preauth_date,
        v_gl_upd_flag,
        p_stan,
        p_inst_code,
        v_fee_code,
        NVL(v_fee_amt,0),
        NVL(v_servicetax_amount,0), -- nvl added :- nvl(v_fee_amt,0) 10-Dec-2013 for 13160
        NVL(v_cess_amount,0),
        v_dr_cr_flag,
        v_fee_cracct_no,
        v_fee_dracct_no,
        v_st_calc_flag,
        v_cess_calc_flag,
        v_st_cracct_no,
        v_st_dracct_no,
        v_cess_cracct_no,
        v_cess_dracct_no,
        v_encr_pan,
        NULL,
        v_proxunumber,
        p_rvsl_code,
        v_acct_number,
        ROUND ( DECODE (p_resp_code, '00', NVL (v_upd_amt, 0), v_acct_balance), 2),      --NVL added for defect 10871   --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
        ROUND ( DECODE (p_resp_code, '00', NVL (v_upd_ledger_amt, 0), v_ledger_bal), 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
        p_international_ind,
        v_resp_cde,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        p_network_id,
        NVL(p_interchange_feeamt,0),
        p_merchant_zip,
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        v_fee_plan,
        --Added by Deepa for Fee Plan on June 10 2012
        p_pos_verfication,
        --Added by Deepa on July 03 2012 to log the verification of POS
        v_feeattach_type,
        -- Added by Trivikram on 05-Sep-2012
        p_merchant_name,
        -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        p_merchant_city,
        -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        p_atmname_loc,
        -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        p_network_setl_date,
        -- Added on 201112 for logging N/W settlement date in transactionlog
        v_err_msg, -- Added on 06-Feb-2013 ,same was missing
        P_MERCHANT_ID,
        v_cam_type_code,                                --Added for defect 10871
        v_timestamp,                                    --Added for defect 10871
        v_applpan_cardstat,                             --Added for defect 10871
        p_medagateref_Id,                               -- Added for Medagate Changes.
        DECODE (p_delivery_channel, '01', 'VDBZ', '') , -- Added for LYFE Changes
        p_networkid_switch,                              --Added by Abdul Hameed M.A on 25 Feb 2014 for Mantis ID 13736
        decode(v_resp_cde,'1000','Decline due to redemption delay',v_err_msg), --Added for error msg need to display in CSR(declined by rule)
        p_funding_account
      );
    --DBMS_OUTPUT.put_line ('AFTER INSERT IN TRANSACTIONLOG');
    p_auth_id := v_auth_id;
  EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    p_resp_code := '69'; -- Server Declione
    p_resp_msg  := 'Problem while inserting data into transaction log  ' || SUBSTR (SQLERRM, 1, 300);
  END;
  --En create a entry in txn log
--  IF p_txn_code    = '04' AND p_delivery_channel = '07' AND v_mini_stat_res IS NOT NULL THEN
 --   p_resp_msg    := v_mini_stat_res;
 IF p_resp_msg = 'OK' THEN
    --DBMS_OUTPUT.put_line ('AFTER INSERT IN TRANSACTIONLOG'|| v_upd_amt);
    --DBMS_OUTPUT.put_line ('AFTER INSERT IN TRANSACTIONLOG'|| v_upd_ledger_amt);
    p_resp_msg   := TO_CHAR (v_upd_amt); --added for response data
    p_ledger_bal := TO_CHAR (v_upd_ledger_amt);
    -- ADDED FOR LEDGER BALANCE FOR mPAY BALANCE ENQUIRY REQUEST.
  END IF;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  --St Added by Ramesh.A on 18/07/2012 for MMPOS Balance Enquiry
  IF (( p_delivery_channel = '04' AND p_txn_code = '94') OR ( p_delivery_channel = '14' AND p_txn_code = '13' )) -- Added by for medagate
    THEN
    BEGIN
      SELECT cap.cap_card_stat,
        cap.cap_acct_no,
        cpm.cpm_prod_desc,
        cpc.cpc_cardtype_desc,
        cpc.cpc_program_id,
        ccs.CCS_STAT_DESC
      INTO p_card_status,
        p_dda_number,
        p_prod_desc,
        p_prod_cat_desc,
        p_prod_id,       --Added by siva kumar on 01/08/2012.
        v_card_stat_desc -- Added for medagate Changes defect id:MVHOST-387
      FROM cms_appl_pan cap,
        cms_prod_mast cpm,
        cms_prod_cattype cpc,
        cms_card_stat ccs
      WHERE cpm_inst_code   = cpc_inst_code
      AND cpm_prod_code     = cpc_prod_code
      AND cpm_prod_code     = cap.cap_prod_code
      AND cpc_card_type     = cap.cap_card_type
      AND cap.cap_pan_code  = v_hash_pan
      AND cap.cap_inst_code = p_inst_code
      AND cap.cap_card_stat =ccs.CCS_STAT_CODE
      AND cap.CAP_INST_CODE = ccs.CCS_INST_CODE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      p_resp_msg  := 'No Data Found in getting prod desc , prod cattype desc';
      p_resp_code := '69';
    WHEN OTHERS THEN
      p_resp_msg  := 'Error while selecting prod desc and prod catype desc ' || SUBSTR (SQLERRM, 1, 200);
      p_resp_code := '69';
    END;
    -- ST Added for medagate Changes defect id:MVHOST-387
    IF p_delivery_channel = '14' AND p_txn_code = '13' THEN
      p_prod_cat_desc    := v_card_stat_desc;
    END IF;
    -- EN Added for medagate Changes defect id:MVHOST-387
    IF p_delivery_channel <> '14' AND p_txn_code <> '13' THEN -- Added for medagate Changes defect id:MVHOST-387
      BEGIN
        BEGIN
          --Get Fee Plan ID from card level
          SELECT cce_fee_plan
          INTO p_fee_plan_id
          FROM cms_card_excpfee
          WHERE cce_inst_code = p_inst_code
          AND cce_pan_code    = v_hash_pan;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          BEGIN
            SELECT cpf_fee_plan
            INTO p_fee_plan_id
            FROM cms_prodcattype_fees
            WHERE cpf_inst_code = p_inst_code
            AND cpf_prod_code   = v_prod_code
            AND cpf_card_type   = v_prod_cattype;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            BEGIN
              SELECT cpf_fee_plan
              INTO p_fee_plan_id
              FROM cms_prod_fees
              WHERE cpf_inst_code = p_inst_code
              AND cpf_prod_code   = v_prod_code;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              p_fee_plan_id := '';
            WHEN OTHERS THEN
              p_resp_msg  := 'Error while selecting --Get Fee Plan ID FROM PRODUCT LEVEL ' || SUBSTR (SQLERRM, 1, 200);
              p_resp_code := '69';
            END;
          WHEN OTHERS THEN
            p_resp_msg  := 'Error while selecting --Get Fee Plan ID FROM PRODUCT CARD TYPE LEVEL ' || SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '69';
          END;
        WHEN OTHERS THEN
          p_resp_msg  := 'Error while selecting --Get Fee Plan ID FROM CARDLEVEL ' || SUBSTR (SQLERRM, 1, 200);
          p_resp_code := '69';
        END;
      EXCEPTION
      WHEN OTHERS THEN
        p_resp_msg  := 'Error while selecting --Get Fee Plan ID  ' || SUBSTR (SQLERRM, 1, 200);
        p_resp_code := '69';
      END;
    END IF;
    -----------------------------------------------
    --SN: Added on 20-Apr-2013 for defect 10871
    -----------------------------------------------
    IF v_acct_balance IS NULL THEN
      BEGIN
        SELECT cam_acct_bal,
          cam_ledger_bal,
          cam_acct_no,
          cam_type_code --Added for defect 10871
        INTO v_acct_balance,
          v_ledger_bal,
          v_acct_number,
          v_cam_type_code --Added for defect 10871
        FROM cms_acct_mast
        WHERE cam_acct_no =
          (SELECT cap_acct_no
          FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan
          AND cap_inst_code  = p_inst_code
          )
        AND cam_inst_code = p_inst_code;
      EXCEPTION
      WHEN OTHERS THEN
        v_acct_balance := 0;
        v_ledger_bal   := 0;
      END;
    END IF;
    IF V_PROD_CODE IS NULL THEN
      BEGIN
        SELECT CAP_PROD_CODE,
          CAP_CARD_TYPE,
          CAP_CARD_STAT,
          CAP_ACCT_NO
        INTO V_PROD_CODE,
          V_PROD_CATTYPE,
          V_APPLPAN_CARDSTAT,
          V_ACCT_NUMBER
        FROM CMS_APPL_PAN
        WHERE CAP_INST_CODE = P_INST_CODE
        AND CAP_PAN_CODE    = V_HASH_PAN; --P_card_no;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    IF V_DR_CR_FLAG IS NULL THEN
      BEGIN
        SELECT CTM_CREDIT_DEBIT_FLAG
        INTO V_DR_CR_FLAG
        FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE      = P_TXN_CODE
        AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CTM_INST_CODE        = P_INST_CODE;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    IF v_timestamp IS NULL THEN
      v_timestamp  := systimestamp; -- Added on 20-Apr-2013 for defect 10871
    END IF;
    -----------------------------------------------
    --EN: Added on 20-Apr-2013 for defect 10871
    -----------------------------------------------
  END IF; --Added by Abdul Hameed M.A on 25 Feb 2014 for Mantis ID 13736
  --Sn create a entry in txn log
  BEGIN
    INSERT
    INTO transactionlog
      (
        msgtype,
        rrn,
        delivery_channel,
        terminal_id,
        date_time,
        txn_code,
        txn_type,
        txn_mode,
        txn_status,
        response_code,
        business_date,
        business_time,
        customer_card_no,
        topup_card_no,
        topup_acct_no,
        topup_acct_type,
        bank_code,
        total_amount,
        rule_indicator,
        rulegroupid,
        mccode,
        currencycode,
        addcharge,
        productid,
        categoryid,
        tips,
        decline_ruleid,
        atm_name_location,
        auth_id,
        trans_desc,
        amount,
        preauthamount,
        partialamount,
        mccodegroupid,
        currencycodegroupid,
        transcodegroupid,
        rules,
        preauth_date,
        gl_upd_flag,
        system_trace_audit_no,
        instcode,
        feecode,
        tranfee_amt,
        servicetax_amt,
        cess_amt,
        cr_dr_flag,
        tranfee_cr_acctno,
        tranfee_dr_acctno,
        tran_st_calc_flag,
        tran_cess_calc_flag,
        tran_st_cr_acctno,
        tran_st_dr_acctno,
        tran_cess_cr_acctno,
        tran_cess_dr_acctno,
        customer_card_no_encr,
        topup_card_no_encr,
        proxy_number,
        reversal_code,
        customer_acct_no,
        acct_balance,
        ledger_balance,
        internation_ind_response,
        response_id,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        network_id,
        interchange_feeamt,
        merchant_zip,
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        fee_plan,
        pos_verification,
        --Added by Deepa on July 03 2012 to log the verification of POS
        feeattachtype,
        -- Added by Trivikram on 05-Sep-2012
        merchant_name,
        -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        merchant_city,
        -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        merchant_state,
        -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        network_settl_date,
        -- Added on 201112 for logging N/W settlement date in transactionlog
        error_msg,
        MERCHANT_ID,     --Added on 19-Mar-2013 for FSS-970
        acct_type,       --Added for defect 10871
        time_stamp,      --Added for defect 10871
        cardstatus,      --Added for defect 10871
        medagateref_id , -- Added by for medagate
        networkid_switch, --Added on 20130626 for the Mantis ID 11344
        fundingaccount --vms-454
      )
      VALUES
      (
        p_msg,
        p_rrn,
        p_delivery_channel,
        p_term_id,
        v_business_date,
        p_txn_code,
        v_txn_type,
        p_txn_mode,
        DECODE (p_resp_code, '00', 'C', 'F'),
        p_resp_code,
        p_tran_date,
        p_tran_time,
        v_hash_pan,
        NULL,
        NULL, --P_topup_acctno    ,
        NULL, --P_topup_accttype,
        p_bank_code,
        TRIM (TO_CHAR (NVL(v_total_amt,0), '99999999999999990.99')),
        NULL,
        NULL,
        p_mcc_code,
        p_curr_code,
        NULL, -- P_add_charge,
        v_prod_code,
        v_prod_cattype,
        p_tip_amt,
        p_decline_ruleid,
        p_atmname_loc,
        v_auth_id,
        v_trans_desc,
        TRIM (TO_CHAR (NVL(v_tran_amt,0), '99999999999999990.99')),
        NULL,
        NULL,
        -- Partial amount (will be given for partial txn)
        p_mcccode_groupid,
        p_currcode_groupid,
        p_transcode_groupid,
        p_rules,
        p_preauth_date,
        v_gl_upd_flag,
        p_stan,
        p_inst_code,
        v_fee_code,
        NVL(v_fee_amt,0), -- nvl added :- nvl(v_fee_amt,0) 10-Dec-2013 for 13160
        NVL(v_servicetax_amount,0),
        NVL(v_cess_amount,0),
        v_dr_cr_flag, --nvl added for service tax and cess amount for defect 10871
        v_fee_cracct_no,
        v_fee_dracct_no,
        v_st_calc_flag,
        v_cess_calc_flag,
        v_st_cracct_no,
        v_st_dracct_no,
        v_cess_cracct_no,
        v_cess_dracct_no,
        v_encr_pan,
        NULL,
        v_proxunumber,
        p_rvsl_code,
        v_acct_number,
        ROUND ( DECODE (p_resp_code, '00', v_upd_amt, v_acct_balance), 2),      --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
        ROUND ( DECODE (p_resp_code, '00', v_upd_ledger_amt, v_ledger_bal), 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
        p_international_ind,
        p_resp_code,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        p_network_id,
        p_interchange_feeamt,
        p_merchant_zip,
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        v_fee_plan,
        --Added by Deepa for Fee Plan on June 10 2012
        p_pos_verfication,
        --Added by Deepa on July 03 2012 to log the verification of POS
        v_feeattach_type,
        -- Added by Trivikram on 05-Sep-2012
        p_merchant_name,
        -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        p_merchant_city,
        -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        p_atmname_loc,
        -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        p_network_setl_date,
        -- Added on 201112 for logging N/W settlement date in transactionlog
        v_err_msg,          -- Added on 06-Feb-2013 ,same was missing
        P_MERCHANT_ID,      --Added on 19-Mar-2013 for FSS-970
        v_cam_type_code,    --Added for defect 10871
        v_timestamp,        --Added for defect 10871
        v_applpan_cardstat, --Added for defect 10871
        p_medagateref_id ,  -- Added for medagate changes.
        p_networkid_switch,  --Added on 20130626 for the Mantis ID 11344
        p_funding_account --vms-454
      );
    DBMS_OUTPUT.put_line ('AFTER INSERT IN TRANSACTIONLOG');
    p_auth_id := v_auth_id;
  EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    p_resp_code := '69'; -- Server Declione
    p_resp_msg  := 'Problem while inserting data into transaction log  ' || SUBSTR (SQLERRM, 1, 300);
  END;
  --    END IF;  --Commented by Abdul Hameed M.A on 25 Feb 2014 for Mantis ID 13736
  --En Added by Ramesh.A on 18/07/2012 for MMPOS Balance Enquiry
  p_resp_code := '69'; -- Server Declined
  p_resp_msg  := 'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/
SHOW ERROR;