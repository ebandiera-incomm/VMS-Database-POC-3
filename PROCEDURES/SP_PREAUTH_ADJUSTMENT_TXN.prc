create or replace PROCEDURE             VMSCMS.SP_PREAUTH_ADJUSTMENT_TXN (
   p_inst_code              IN       NUMBER,
   p_msg                    IN       VARCHAR2,
   p_rrn                             VARCHAR2,
   p_delivery_channel                VARCHAR2,
   p_term_id                         VARCHAR2,
   p_txn_code                        VARCHAR2,
   p_txn_mode                        VARCHAR2,
   p_tran_date                       VARCHAR2,
   p_tran_time                       VARCHAR2,
   p_card_no                         VARCHAR2,
   p_bank_code                       VARCHAR2,
   p_txn_amt                         NUMBER,
   p_merchant_name                   VARCHAR2,
   p_merchant_city                   VARCHAR2,
   p_mcc_code                        VARCHAR2,
   p_curr_code                       VARCHAR2,
   p_prod_id                         VARCHAR2,
   p_catg_id                         VARCHAR2,
   p_tip_amt                         VARCHAR2,
   p_decline_ruleid                  VARCHAR2,
   p_atmname_loc                     VARCHAR2,
   p_mcccode_groupid                 VARCHAR2,
   p_currcode_groupid                VARCHAR2,
   p_transcode_groupid               VARCHAR2,
   p_rules                           VARCHAR2,
   p_preauth_date                    DATE,
   p_consodium_code         IN       VARCHAR2,
   p_partner_code           IN       VARCHAR2,
   p_expry_date             IN       VARCHAR2,
   p_stan                   IN       VARCHAR2,
   p_mbr_numb               IN       VARCHAR2,
   p_preauth_expperiod      IN       VARCHAR2,
   p_preauth_seqno          IN       VARCHAR2,
   p_rvsl_code              IN       NUMBER,
   p_pos_verfication        IN       VARCHAR2,
   p_international_ind      IN       VARCHAR2,
   p_addl_amnt              IN       VARCHAR2,
   p_networkid_switch       IN       VARCHAR2,
   p_networkid_acquirer     IN       VARCHAR2,
   p_network_setl_date      IN       VARCHAR2,
   p_merchant_zip           IN       VARCHAR2,
   p_cvv_verificationtype   IN       VARCHAR2,
   p_orgnl_business_date    IN       VARCHAR2,
   p_orgnl_business_time    IN       VARCHAR2,
   p_orgnl_stan             IN       VARCHAR2,
   p_adj_resp_code          IN       NUMBER,
   P_PULSE_TRANSACTIONID        IN       VARCHAR2,--Added for MVHOST 926
   P_VISA_TRANSACTIONID         IN       VARCHAR2,--Added for MVHOST 926
   P_MC_TRACEID                 IN       VARCHAR2,--Added for MVHOST 926
   P_CARDVERIFICATION_RESULT    IN       VARCHAR2,--Added for MVHOST 926
   p_auth_id                OUT      VARCHAR2,
   p_resp_code              OUT      VARCHAR2,
   p_resp_msg               OUT      VARCHAR2,
   p_ledger_bal             OUT      VARCHAR2,
   p_capture_date           OUT      DATE,
   p_iso_respcde            OUT      VARCHAR2,
   p_acct_bal               OUT      VARCHAR2--To return the account balance for the failure case
   ,P_MERCHANT_ID IN       VARCHAR2  DEFAULT NULL
   ,P_MERCHANT_CNTRYCODE IN       VARCHAR2  DEFAULT NULL
    ,P_acqInstAlphaCntrycode_in IN       VARCHAR2  DEFAULT NULL
	 ,p_surchrg_ind   IN VARCHAR2 DEFAULT '2' --Added for VMS-5856
     ,p_resp_id       OUT VARCHAR2 --Added for sending to FSS (VMS-8018)
)
IS
/*************************************************
     * Created Date     : 10-Sep-2012
     * Created By       : Deepa T
     * PURPOSE          : Mantis ID:12296: OLS changes to support the Adjustment transaction in OLS with Message type 1120
     *                     This transaction will adjust the hold amount of preauth
     * Modified By      :   Deepa T
     * Modified For     :  12296- Code Review Comments
     * Modified Date    :  17-Sep-2013
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     :

     * Modified By      :  Deepa T
     * Modified For     :  FSS-1313- To return the balance for both approved and declined cases(1.7.3.8 changes merged)
     * Modified Date    :  24-Sep-2013
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     : RI0024.4.1_B0001

     * Modified by       : Pankaj S.
     * Modified for      : Mantis ID 13025,13024
     * Modified Reason   : To comment expiry date check & log international ind in txnlog table
     * Modified Date     : 21_Nov_2013
     * Reviewer          : Dhiraj
     * Reviewed Date     :
     * Build Number      :  RI0024.6.1_B0002

     * Modified By      : Pankaj S.
     * Modified Date    : 19-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0027_B0003

     * Modified by      : DHINAKARAN B
     * Modified for     : MANTIS ID-13467
     * Modified Reason  : Implement the 1.7.6.5 changes on 2.0 to Logging the Delivery channel and txn code in CMS_PREAUTH_TRANS_HIST table
     * Modified Date    : 22-jan-14
     * Reviewer         :
     * Reviewed Date    : RI0027_B0004

     * Modified By      : MageshKumar S
     * Modified Date    : 28-Jan-2014
     * Modified for     : MVCSD-4471
     * Modified Reason  : Narration change for FEE amount
     * Reviewer         : DHIRAJ
     * Reviewed Date    :
     * Build Number     : RI0027.1_B0001

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 12-Feb-2014
     * Modified for     : MANTIS ID-13645
     * Modified Reason  : To log the last 4 digit of pan  number in cms_preauth_trans_hist table.
     * Reviewer         : DHIRAJ
     * Reviewed Date    :
     * Build Number     : RI0027.1_B0001

     * Modified by       : Sagar
     * Modified for      :
     * Modified Reason   : Concurrent Processsing Issue
                            (1.7.6.7 changes integarted)
     * Modified Date     : 04-Mar-2014
     * Reviewer          : Dhiarj
     * Reviewed Date     : 06-Mar-2014
     * Build Number      : RI0027.1.1_B0001


     * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13893
     * Modified Reason   : Added card number for duplicate RRN check
     * Modified Date     : 06-Mar-2014
     * Reviewer          : Dhiraj
     * Reviewed Date     : 06-Mar-2014
     * Build Number      : RI0027.2_B0002

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 10-Apr-2014
     * Modified for     : Mantis ID 14086/14122 review comments/14133
     * Modified Reason  : Statements log should be based on ledger balance and card status check should be checked in pcms valid card stat
     * Reviewer         : spankaj
     * Reviewed Date    : 14-April-2014
     * Build Number     : RI0027.2_B0005

     * Modified by       :  Abdul Hameed M.A
     * Modified Reason   :  To hold the Preauth completion fee at the time of preauth
     * Modified for      :  FSS 837
     * Modified Date     :  27-JUNE-2014
     * Reviewer          :  Spankaj
     * Build Number      :  RI0027.3_B0001

     * Modified by       : Dhinakaran B
     * Modified for      : VISA Certtification Changes integration in 2.3
     * Modified Date     : 08-JUL-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0002

     * Modified by       :  Abdul Hameed M.A
     * Modified Reason   :  For Merchandise return adjustment fee is not debiting
     * Modified for      :  Mantis ID   15606
     * Modified Date     :  21-JULY-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0005

     * Modified by       : MageshKumar S.
     * Modified Date     : 25-July-14
     * Modified For      : FWR-48
     * Modified reason   : GL Mapping removal changes
     * Reviewer          : Spankaj
     * Build Number      : Ri0027.3.1_B0001

     * Modified Date    : 16-Oct-2014
     * Modified By      : MageshKumar S
     * Modified for     : OLS Perf Improvement
     * Reviewer         : spankaj
     * Release Number   : RI0027.4.3_B0001

     * Modified Date    : 27-Nov-2014
     * Modified By      : MageshKumar S
     * Modified for     : OLS Perf Improvement removal and keeping Duplicate RRN check commented.
     * Reviewer         : spankaj
     * Release Number   : RI0027.4.3_B0007

     * Modified Date    : 30-DEC-2014
     * Modified By      : Dhinakaran B
     * Modified for     : MVHOST-1080/To Log the Merchant id & CountryCode
     * Reviewer         :
     * Reviewed Date    :
     * Release Number   :

     * Modified by      : MAGESHKUMAR S.
     * Modified Date    : 03-FEB-2015
     * Modified For     : FSS-2065(2.4.2.4.1 & 2.4.3.1 integration)
     * Reviewer         : PANKAJ S.
     * Build Number     : RI0027.5_B0006

     * Modified By      : MageshKumar S
     * Modified Date    : 11-FEB-2015
     * Modified for     : INSTCODE REMOVAL(2.4.2.4.2 & 2.4.3.1 integration)
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0007

    * Modified by      : Ramesh A
    * Modified for     : FSS-3610
    * Modified Date    : 31-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOST_3.1_B0008

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 09-SEP-2015
     * Modified for     : FSS 3643
     * Reviewer         : Spankaj
     * Release Number   : VMSGPRHOSTCSD_3.1_B00010

    * Modified by      : MageshKumar S
    * Modified for     : GPR Card Status Check Moved to Java
    * Modified Date    : 27-JAN-2016
    * Reviewer         : Saravanankumar/SPankaj
    * Build Number     : VMSGPRHOST_4.0_B0001

      * Modified by      : Narayanaswamy.T
    * Modified for     : FSS-4119 - ATM withdrawal transactions should contain terminal id and city in the statement
    * Modified Date    : 01-Mar-2016
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOST_4.0_B0001

     * Modified Date    : 24-Nov-2016
     * Modified By      : Narayanaswamy.T
     * Modified for     : FSS-4960 - UPI Enhancement_Preauth-Cancel Reversal
     * Reviewer         : Saravanakumar/Spankaj
     * Release Number   : VMSGPRHOST4.11_B0003


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

     * Modified By      : DHINAKARAN B
     * Modified Date    : 15-NOV-2018
     * Purpose          : VMS-619 (RULE)
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : R08

       * Modified By      : Karthick/Jey
       * Modified Date    : 05-18-2022
       * Purpose          : Archival changes.
       * Reviewer         : Venkat Singamaneni
       * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991

       * Modified By      : Areshka A.
       * Modified Date    : 03-Nov-2023
       * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
       * Reviewer         :
       * Release Number   :

*************************************************/
   v_err_msg              VARCHAR2 (900)                              := 'OK';
   v_acct_balance         NUMBER;
   v_ledger_bal           NUMBER;
   v_tran_amt             NUMBER;
   v_auth_id              transactionlog.auth_id%TYPE;
   v_total_amt            NUMBER;
   v_tran_date            DATE;
   v_func_code            cms_func_mast.cfm_func_code%TYPE;
   v_prod_code            cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype         cms_prod_cattype.cpc_card_type%TYPE;
   v_fee_amt              NUMBER;
   v_total_fee            NUMBER;
   v_upd_amt              NUMBER;
   v_upd_ledger_amt       NUMBER;
   v_narration            VARCHAR2 (300);
   v_trans_desc           VARCHAR2 (50);
   v_fee_opening_bal      NUMBER;
   v_resp_cde             VARCHAR2 (3);
   v_expry_date           DATE;
   v_dr_cr_flag           VARCHAR2 (2);
   v_output_type          VARCHAR2 (2);
   v_applpan_cardstat     cms_appl_pan.cap_card_stat%TYPE;
   v_atmonline_limit      cms_appl_pan.cap_atm_online_limit%TYPE;
   v_posonline_limit      cms_appl_pan.cap_atm_offline_limit%TYPE;
   v_gl_upd_flag          transactionlog.gl_upd_flag%TYPE;
   v_gl_err_msg           VARCHAR2 (500);
   v_savepoint            NUMBER                                         := 0;
   v_tran_fee             NUMBER;
   v_error                VARCHAR2 (500);
   v_business_date_tran   DATE;
   v_business_time        VARCHAR2 (5);
   v_cutoff_time          VARCHAR2 (5);
   v_card_curr            VARCHAR2 (5);
   v_fee_code             cms_fee_mast.cfm_fee_code%TYPE;
   v_fee_crgl_catg        cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_fee_crgl_code        cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_fee_crsubgl_code     cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_fee_cracct_no        cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_drgl_catg        cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_fee_drgl_code        cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_fee_drsubgl_code     cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_fee_dracct_no        cms_prodcattype_fees.cpf_dracct_no%TYPE;
   --st AND cess
   v_servicetax_percent   cms_inst_param.cip_param_value%TYPE;
   v_cess_percent         cms_inst_param.cip_param_value%TYPE;
   v_servicetax_amount    NUMBER;
   v_cess_amount          NUMBER;
   v_st_calc_flag         cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_cess_calc_flag       cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_st_cracct_no         cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_st_dracct_no         cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_cess_cracct_no       cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_cess_dracct_no       cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   --
   v_waiv_percnt          cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_err_waiv             VARCHAR2 (300);
   v_log_actual_fee       NUMBER;
   v_log_waiver_amt       NUMBER;
   v_auth_savepoint       NUMBER                                    DEFAULT 0;
   v_business_date        DATE;
   v_txn_type             NUMBER (1);
   exp_reject_record      EXCEPTION;
   v_card_acct_no         VARCHAR2 (20);
   v_hold_amount          NUMBER;
   v_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
   v_rrn_count            NUMBER;
   v_tran_type            VARCHAR2 (2);
   v_date                 DATE;
   v_time                 VARCHAR2 (10);
   v_max_card_bal         NUMBER;
   v_curr_date            DATE;
   v_saf_txn_count        NUMBER;
   v_proxunumber          cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number          cms_appl_pan.cap_acct_no%TYPE;
   v_feeamnt_type         cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_per_fees             cms_fee_mast.cfm_per_fees%TYPE;
   v_flat_fees            cms_fee_mast.cfm_fee_amt%TYPE;
   v_clawback             cms_fee_mast.cfm_clawback_flag%TYPE;
   v_fee_plan             cms_fee_feeplan.cff_fee_plan%TYPE;
   v_freetxn_exceed       VARCHAR2 (1);
   v_duration             VARCHAR2 (20);
   v_feeattach_type       VARCHAR2 (2);
   v_cms_iso_respcde      cms_response_mast.cms_iso_respcde%TYPE;
   v_hold_days            cms_txncode_rule.ctr_hold_days%TYPE;
   v_mcc_verify_flag      VARCHAR2 (1);
   v_preauth_flag         NUMBER;
   v_stan_count           NUMBER;
   v_preauth_rrn          transactionlog.rrn%TYPE;
   v_dup_txn_check        NUMBER (5);
   v_status_chk           NUMBER;
   v_precheck_flag        NUMBER;
   v_preauthhold_amnt     NUMBER;
   v_length_pan           NUMBER;

   --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
   v_acct_type            cms_acct_mast.cam_type_code%TYPE;
   v_timestamp            timestamp:=systimestamp;
   --En Added by Pankaj S. for logging changes(Mantis ID-13160)
   V_FEE_DESC         cms_fee_mast.cfm_fee_desc%TYPE;  -- Added for MVCSD-4471
   --Sn Added for FSS 837
   v_completion_fee cms_preauth_transaction.cpt_completion_fee%TYPE;
   v_completion_txn_code VARCHAR2(2);
   v_comp_fee_code             cms_fee_mast.cfm_fee_code%TYPE;
   v_comp_fee_crgl_catg        cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_comp_fee_crgl_code        cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_comp_fee_crsubgl_code     cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_comp_fee_cracct_no        cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_comp_fee_drgl_catg        cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_comp_fee_drgl_code        cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_comp_fee_drsubgl_code     cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_comp_fee_dracct_no        cms_prodcattype_fees.cpf_dracct_no%TYPE;
   v_comp_servicetax_percent   cms_inst_param.cip_param_value%TYPE;
   v_comp_cess_percent         cms_inst_param.cip_param_value%TYPE;
   v_comp_servicetax_amount    NUMBER;
   v_comp_cess_amount          NUMBER;
   v_comp_st_calc_flag         cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_comp_cess_calc_flag       cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_comp_st_cracct_no         cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_comp_st_dracct_no         cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_comp_cess_cracct_no       cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_comp_cess_dracct_no       cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   v_comp_waiv_percnt          cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_comp_feeamnt_type         cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_comp_per_fees             cms_fee_mast.cfm_per_fees%TYPE;
   v_comp_flat_fees            cms_fee_mast.cfm_fee_amt%TYPE;
   v_comp_clawback             cms_fee_mast.cfm_clawback_flag%TYPE;
   v_comp_fee_plan             cms_fee_feeplan.cff_fee_plan%TYPE;
   v_comp_freetxn_exceed       VARCHAR2 (1);
   v_comp_duration             VARCHAR2 (20);
   v_comp_feeattach_type       VARCHAR2 (2);
   v_comp_fee_amt              NUMBER;
    v_comp_err_waiv             VARCHAR2 (300);
      V_COMP_FEE_DESC         cms_fee_mast.cfm_fee_desc%TYPE;
       v_comp_error                VARCHAR2 (500);
       v_comp_total_fee          NUMBER:=0;
       v_tot_hold_amt          NUMBER;
       v_complfee_increment_type   VARCHAR2(1);
       v_comp_fee_hold number:=0; --Added for 15606
       --En Added for FSS 837
  V_PREAUTH_TYPE           CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;----Added for MVHOST 926l

   -- FSS-4960 - UPI Enhancement_Preauth-Cancel Reversal beg
  V_NETWORK_FLAG CHAR(1):=0;
  V_TRAN_PREAUTH_FLAG         CMS_TRANSACTION_MAST.CTM_PREAUTH_FLAG%TYPE;
  V_PREAUTH_DATE              DATE;
  VT_PREAUTH_HOLD        VARCHAR2(1);
  V_PREAUTH_HOLD              VARCHAR2(1);
  V_PREAUTH_PERIOD            NUMBER;
  VT_PREAUTH_PERIOD      NUMBER;
  vp_preauth_exp_period cms_prod_mast.cpm_pre_auth_exp_date%TYPE ;
  VP_PREAUTH_HOLD        VARCHAR2(1);
  VP_PREAUTH_PERIOD      NUMBER;
  vi_preauth_exp_period  cms_inst_param.cip_param_value%TYPE ;
  VI_PREAUTH_HOLD        VARCHAR2(1);
  VI_PREAUTH_PERIOD      NUMBER;
  V_PREAUTH_EXP_PERIOD        VARCHAR2(10);
  -- FSS-4960 - UPI Enhancement_Preauth-Cancel Reversal end
  V_adj_amt number;

  v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991

BEGIN
   SAVEPOINT v_auth_savepoint;
   v_resp_cde := '1';
   p_resp_msg := 'OK';

   BEGIN
      --SN CREATE HASH PAN
      BEGIN
         v_hash_pan := gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while converting the hashed pan '--Modified the Error message for 12296(review)
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN CREATE HASH PAN

      --SN create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while converting the encrypted pan '--Modified the Error message for 12296(review)
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN create encr pan

      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      --En generate auth id

      --En check txn currency
      BEGIN
         v_date := TO_DATE (SUBSTR (TRIM (p_tran_date), 1, 8), 'yyyymmdd');
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '45';
            v_err_msg :=
                  'Problem while converting transaction date '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_tran_date :=
            TO_DATE (   SUBSTR (TRIM (p_tran_date), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_tran_time), 1, 10),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '32';
            v_err_msg :=
                  'Problem while converting transaction time '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En get date

      --Sn find debit and credit flag
      BEGIN
         SELECT ctm_credit_debit_flag, ctm_output_type,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                CTM_TRAN_TYPE, CTM_TRAN_DESC
                ,CTM_PREAUTH_TYPE,CTM_PREAUTH_FLAG--Added for MVHOST 926
           INTO v_dr_cr_flag, v_output_type,
                v_txn_type,
                V_TRAN_TYPE, V_TRANS_DESC
                ,V_PREAUTH_TYPE,V_TRAN_PREAUTH_FLAG--Added for MVHOST 926
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Transflag  not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Error while selecting CMS_TRANSACTION_MAST '
               || p_txn_code
               || p_delivery_channel
               || SQLERRM;
            RAISE exp_reject_record;
      END;

      --Sn find card detail
      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_expry_date,
                cap_card_stat, cap_atm_online_limit, cap_pos_online_limit,
                cap_proxy_number, cap_acct_no
           INTO v_prod_code, v_prod_cattype, v_expry_date,
                v_applpan_cardstat, v_atmonline_limit, v_atmonline_limit,
                v_proxunumber, v_acct_number
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan; --For Instcode removal of 2.4.2.4.2 release
          --AND cap_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';
            v_err_msg := 'CARD NOT FOUND ' || v_hash_pan;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En find debit and credit flag

       IF (p_txn_amt >= 0)
      THEN
         v_tran_amt := p_txn_amt;

         BEGIN
            sp_convert_curr (p_inst_code,
                             p_curr_code,
                             p_card_no,
                             p_txn_amt,
                             v_tran_date,
                             v_tran_amt,
                             v_card_curr,
                             v_err_msg,
                             v_prod_code,
                             v_prod_cattype
                            );

            IF v_err_msg <> 'OK'
            THEN
               v_resp_cde := '44';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '69';
               v_err_msg :=
                     'Error from currency conversion '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      ELSE
         v_resp_cde := '43';
         v_err_msg := 'INVALID AMOUNT';
         v_tran_amt := p_txn_amt;
         RAISE exp_reject_record;
      END IF;

      --En find the tran amt


      IF p_adj_resp_code >= 100
      THEN
         v_resp_cde := '1';
         v_err_msg := 'Adjustment Notification transaction';
         RAISE exp_reject_record;
      END IF;
/*
--SN: Added for Duplicate STAN check
      BEGIN
         SELECT COUNT (1)
           INTO v_stan_count
           FROM transactionlog
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_pan
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel
            AND system_trace_audit_no = p_stan;

         IF v_stan_count > 0
         THEN
            v_resp_cde := '191';
            v_err_msg := 'Duplicate STAN from the Treminal';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while checking duplicate STAN '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
*/
--SN: Added for Duplicate STAN check

      --Sn Duplicate RRN Check
   /*   BEGIN
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE terminal_id = p_term_id
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel
            AND msgtype IN ('1120', '1121')
            AND txn_code = p_txn_code
            AND CUSTOMER_CARD_NO=V_HASH_PAN;--ADDED BY ABDUL HAMEED M.A ON 06-03-2014


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
      EXCEPTION ----Added for 12296(review comments)
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while checking duplicate RRN '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END; */ -- commented for OLS Perf Improvement

      --En Duplicate RRN Check

      --Sn SAF  txn Check
      BEGIN
         IF p_msg = '1121'
         THEN

				--Added for VMS-5739/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
		   WHERE  OPERATION_TYPE='ARCHIVE'
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';

           v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

		IF (v_Retdate>v_Retperiod) THEN                                             --Added for VMS-5739/FSP-991

            SELECT COUNT (*)
              INTO v_saf_txn_count
              FROM transactionlog
             WHERE rrn = p_rrn
               AND business_date = p_tran_date
               AND customer_card_no = v_hash_pan
               --AND instcode = p_inst_code --For Instcode removal of 2.4.2.4.2 release
               AND terminal_id = p_term_id
               AND response_code = '00'
               AND msgtype = '1120'
               AND txn_code = p_txn_code;

		ELSE

		      SELECT COUNT (*)
              INTO v_saf_txn_count
              FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                           --Added for VMS-5739/FSP-991
             WHERE rrn = p_rrn
               AND business_date = p_tran_date
               AND customer_card_no = v_hash_pan
               --AND instcode = p_inst_code --For Instcode removal of 2.4.2.4.2 release
               AND terminal_id = p_term_id
               AND response_code = '00'
               AND msgtype = '1120'
               AND txn_code = p_txn_code;


		END IF;

            IF v_saf_txn_count > 0
            THEN
               v_resp_cde := '38';
               v_err_msg :=
                     'Successful SAF Transaction has already done';
               --   || SUBSTR (SQLERRM, 1, 200);Commented based on the review comments of 14122
               RAISE exp_reject_record;
            END IF;
         END IF;
      EXCEPTION--Added for 12296(review comments)
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while checking duplicate SAF transaction '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En SAF  txn Check
      BEGIN

	    v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_business_date), 1, 8), 'yyyymmdd');

	  IF (v_Retdate>v_Retperiod) THEN                                                          --Added for VMS-5739/FSP-991

         SELECT COUNT (1)
           INTO v_dup_txn_check
           FROM transactionlog
          WHERE CUSTOMER_CARD_NO = v_hash_pan
            AND original_stan = p_orgnl_stan
            AND orgnl_business_date = p_orgnl_business_date
            AND orgnl_business_time = p_orgnl_business_time
            AND response_code = '00'
            AND delivery_channel = p_delivery_channel
            AND msgtype IN ('1120', '1121')
            AND txn_code = p_txn_code;

	   ELSE

	       SELECT COUNT (1)
           INTO v_dup_txn_check
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                        --Added for VMS-5739/FSP-991
          WHERE CUSTOMER_CARD_NO = v_hash_pan
            AND original_stan = p_orgnl_stan
            AND orgnl_business_date = p_orgnl_business_date
            AND orgnl_business_time = p_orgnl_business_time
            AND response_code = '00'
            AND delivery_channel = p_delivery_channel
            AND msgtype IN ('1120', '1121')
            AND txn_code = p_txn_code;


	   END IF;

         IF v_dup_txn_check > 0
         THEN
            v_resp_cde := '155';
            v_err_msg := 'Successful Adjustment Transaction has already done';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while fetching duplicate Adjustment count '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         FOR i IN (SELECT cip_param_value, cip_param_key
                     FROM cms_inst_param
                    WHERE cip_param_key IN ('CUTOFF', 'CESS', 'SERVICETAX')
                      AND cip_inst_code = p_inst_code)
         LOOP
            IF i.cip_param_key = 'SERVICETAX'
            THEN
               v_servicetax_percent := i.cip_param_value;
            ELSIF i.cip_param_key = 'CESS'
            THEN
               v_cess_percent := i.cip_param_value;
            ELSIF i.cip_param_key = 'CUTOFF'
            THEN
               v_cutoff_time := i.cip_param_value;
            END IF;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting institution parameters '|| SUBSTR (SQLERRM, 1, 200); --Modified based on the review comments of 14122
            RAISE exp_reject_record;
      END;

      IF v_servicetax_percent IS NULL
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Service Tax is  not defined in the system';
         RAISE exp_reject_record;
      ELSIF v_cess_percent IS NULL
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Cess is not defined in the system';
         RAISE exp_reject_record;
      ELSIF v_cutoff_time IS NULL
      THEN
         v_cutoff_time := 0;
         v_resp_cde := '21';
         v_err_msg := 'Cutoff time is not defined in the system';
         RAISE exp_reject_record;
      END IF;



      --En find Preauth detail
      BEGIN

	  v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_business_date), 1, 8), 'yyyymmdd');             --Added for VMS-5739/FSP-991

	  IF (v_Retdate>v_Retperiod) THEN                                                          --Added for VMS-5739/FSP-991

         SELECT Z.rrn INTO v_preauth_rrn from (SELECT   rrn
             FROM transactionlog
            WHERE system_trace_audit_no = p_orgnl_stan
              AND business_date = p_orgnl_business_date
              AND business_time = p_orgnl_business_time
              AND customer_card_no = v_hash_pan
            --  AND instcode = p_inst_code --For Instcode removal of 2.4.2.4.2 release
              AND delivery_channel = p_delivery_channel
              AND response_code = '00' ORDER BY add_ins_date DESC)Z
              WHERE ROWNUM = 1; --Modified for 12296(review comments)

	   ELSE

	         SELECT Z.rrn INTO v_preauth_rrn from (SELECT   rrn
             FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                --Added for VMS-5739/FSP-991
            WHERE system_trace_audit_no = p_orgnl_stan
              AND business_date = p_orgnl_business_date
              AND business_time = p_orgnl_business_time
              AND customer_card_no = v_hash_pan
            --  AND instcode = p_inst_code --For Instcode removal of 2.4.2.4.2 release
              AND delivery_channel = p_delivery_channel
              AND response_code = '00' ORDER BY add_ins_date DESC)Z
              WHERE ROWNUM = 1; --Modified for 12296(review comments)

	   END IF;

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_preauth_rrn := p_rrn;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg := 'Error while selecting the original RRN' || SQLERRM;
            RAISE exp_reject_record;
      END;

      BEGIN

				 --Added for VMS-5739/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
		   WHERE  OPERATION_TYPE='ARCHIVE'
		   AND OBJECT_NAME='CMS_PREAUTH_TRANSACTION_EBR';

		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_business_date), 1, 8), 'yyyymmdd');

	  IF (v_Retdate>v_Retperiod) THEN                                                   --Added for VMS-5739/FSP-991

         SELECT cpt_totalhold_amt,cpt_completion_fee --Added for FSS 837
           INTO v_preauthhold_amnt,v_completion_fee --Added for FSS 837
           FROM cms_preauth_transaction
          WHERE cpt_rrn = v_preauth_rrn
            AND cpt_txn_date = p_orgnl_business_date
            AND cpt_inst_code = p_inst_code
            AND cpt_mbr_no = p_mbr_numb
            AND cpt_card_no = v_hash_pan
            AND cpt_txn_time = p_orgnl_business_time
            AND cpt_preauth_validflag <> 'N'
            AND cpt_expiry_flag = 'N';

	  ELSE

	       SELECT cpt_totalhold_amt,cpt_completion_fee --Added for FSS 837
           INTO v_preauthhold_amnt,v_completion_fee --Added for FSS 837
           FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                                  --Added for VMS-5739/FSP-991
          WHERE cpt_rrn = v_preauth_rrn
            AND cpt_txn_date = p_orgnl_business_date
            AND cpt_inst_code = p_inst_code
            AND cpt_mbr_no = p_mbr_numb
            AND cpt_card_no = v_hash_pan
            AND cpt_txn_time = p_orgnl_business_time
            AND cpt_preauth_validflag <> 'N'
            AND cpt_expiry_flag = 'N';

	  END IF;

      EXCEPTION                          --added for VMS-8550
         WHEN NO_DATA_FOUND 
         THEN
         BEGIN
             IF (v_Retdate>v_Retperiod) THEN                                                   --Added for VMS-5739/FSP-991
    
             SELECT cpt_totalhold_amt,cpt_completion_fee --Added for FSS 837
               INTO v_preauthhold_amnt,v_completion_fee --Added for FSS 837
               FROM cms_preauth_transaction
              WHERE cpt_rrn = v_preauth_rrn
                --AND cpt_txn_date = p_orgnl_business_date
                AND cpt_inst_code = p_inst_code
                AND cpt_mbr_no = p_mbr_numb
                AND cpt_card_no = v_hash_pan
                --AND cpt_txn_time = p_orgnl_business_time
                AND cpt_preauth_validflag <> 'N'
                AND cpt_expiry_flag = 'N';
    
          ELSE
    
               SELECT cpt_totalhold_amt,cpt_completion_fee --Added for FSS 837
               INTO v_preauthhold_amnt,v_completion_fee --Added for FSS 837
               FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                                  --Added for VMS-5739/FSP-991
              WHERE cpt_rrn = v_preauth_rrn
                --AND cpt_txn_date = p_orgnl_business_date
                AND cpt_inst_code = p_inst_code
                AND cpt_mbr_no = p_mbr_numb
                AND cpt_card_no = v_hash_pan
                --AND cpt_txn_time = p_orgnl_business_time
                AND cpt_preauth_validflag <> 'N'
                AND cpt_expiry_flag = 'N';
    
          END IF;
         EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         -- FSS-4960 - UPI Enhancement_Preauth-Cancel Reversal beg
         BEGIN
          SELECT COUNT(*) INTO V_NETWORK_FLAG FROM VMS_ISO_NETWORKID_FORCEPOST WHERE TRIM(UPPER(VIN_NETWORK_ID))=TRIM(UPPER(P_NETWORKID_SWITCH));
           EXCEPTION
             WHEN OTHERS
             THEN
                v_resp_cde := '21';
                v_err_msg :=
                      'Error while checking NETWORK_FLAG '
                   || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
          END;
          IF V_NETWORK_FLAG > 0 THEN
          VT_PREAUTH_HOLD :=TO_NUMBER (SUBSTR (TRIM (NVL (V_PREAUTH_EXP_PERIOD, '000')), 1, 1));
          vt_preauth_period :=TO_NUMBER (SUBSTR (TRIM (NVL (V_PREAUTH_EXP_PERIOD, '000')), 2, 2));

            BEGIN
                 SELECT NVL (cpm_pre_auth_exp_date, '000')
                   INTO vp_preauth_exp_period
                   FROM cms_prod_mast
                  WHERE cpm_prod_code = v_prod_code;
              EXCEPTION
                 WHEN NO_DATA_FOUND
                 THEN
                    vp_preauth_exp_period := '000';
                 WHEN OTHERS
                 THEN
                    vp_preauth_exp_period := '000';
              END;

                  vp_preauth_hold :=TO_NUMBER (SUBSTR (TRIM (vp_preauth_exp_period), 1, 1));
                  vp_preauth_period :=TO_NUMBER (SUBSTR (TRIM (vp_preauth_exp_period), 2, 2));

                  IF vt_preauth_hold = vp_preauth_hold
                  THEN
                     v_preauth_hold := vt_preauth_hold;

                     SELECT GREATEST (vt_preauth_period, vp_preauth_period)
                       INTO v_preauth_period
                       FROM DUAL;
                  ELSE
                     IF vt_preauth_hold > vp_preauth_hold
                     THEN
                        v_preauth_hold := vt_preauth_hold;
                        v_preauth_period := vt_preauth_period;
                     ELSIF vt_preauth_hold < vp_preauth_hold
                     THEN
                        v_preauth_hold := vp_preauth_hold;
                        v_preauth_period := vp_preauth_period;
                     END IF;
                  END IF;

                /*Comparing greatest from both with institution peroid Txn Peroid and product peroid  */

                  BEGIN
                     SELECT NVL (cip_param_value, '000')
                       INTO vi_preauth_exp_period
                       FROM cms_inst_param
                      WHERE cip_inst_code = p_inst_code
                        AND cip_param_key = 'PRE-AUTH EXP PERIOD';
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        vi_preauth_exp_period := '000';
                     WHEN OTHERS
                     THEN
                        vi_preauth_exp_period := '000';
                  END;

                  vi_preauth_hold :=TO_NUMBER (SUBSTR (TRIM (vi_preauth_exp_period), 1, 1)); --01122012
                  vi_preauth_period :=TO_NUMBER (SUBSTR (TRIM (vi_preauth_exp_period), 2, 2));--01122012

                  IF v_preauth_hold = vi_preauth_hold
                  THEN
                     v_preauth_hold := v_preauth_hold;

                     SELECT GREATEST (v_preauth_period, vi_preauth_period)
                       INTO v_preauth_period
                       FROM DUAL;
                  ELSE
                     IF v_preauth_hold > vi_preauth_hold
                     THEN
                        v_preauth_hold := v_preauth_hold;
                        v_preauth_period := v_preauth_period;
                     ELSIF v_preauth_hold < vi_preauth_hold
                     THEN
                        v_preauth_hold := vi_preauth_hold;
                        v_preauth_period := vi_preauth_period;
                     END IF;
                  END IF;


              IF     P_DELIVERY_CHANNEL IN ('01', '02') AND V_TRAN_PREAUTH_FLAG = 'Y'
                AND  V_DR_CR_FLAG = 'NA' THEN
              IF V_HOLD_DAYS IS NOT NULL
              AND V_HOLD_DAYS <> '0'    -- Added on 26-Feb-2013 during FSS-781 changes
              THEN
                 IF V_PREAUTH_HOLD in( '0', '1')  THEN
                    V_PREAUTH_PERIOD := V_HOLD_DAYS;
                    V_PREAUTH_HOLD:='2'  ;
                 ELSIF V_PREAUTH_HOLD='2' THEN
                   IF V_HOLD_DAYS > V_PREAUTH_PERIOD THEN
                    V_PREAUTH_PERIOD := V_HOLD_DAYS;
                    V_PREAUTH_HOLD:='2'  ;
                   END IF;
                 END IF ;
              END IF;
            END IF;



            IF V_PREAUTH_HOLD = '0' THEN
              V_PREAUTH_DATE := V_TRAN_DATE + (V_PREAUTH_PERIOD * (1 / 1440));
            END IF;

            IF V_PREAUTH_HOLD = '1' THEN
              V_PREAUTH_DATE := V_TRAN_DATE + (V_PREAUTH_PERIOD * (1 / 24));
            END IF;

            IF V_PREAUTH_HOLD = '2' THEN
              V_PREAUTH_DATE := V_TRAN_DATE + V_PREAUTH_PERIOD;
            END IF;

              V_PREAUTHHOLD_AMNT:=0;
              v_completion_fee:=0;
        ELSE
                v_resp_cde := '58';
                v_err_msg := 'There is no hold amount for adjustment';
                RAISE EXP_REJECT_RECORD;
        END IF;
    -- FSS-4960 - UPI Enhancement_Preauth-Cancel Reversal end
       WHEN OTHERS
       THEN
          v_resp_cde := '12';
          v_err_msg := 'Error while selecting the hold amount' || SQLERRM;
          RAISE exp_reject_record;
        END;
    WHEN OTHERS
    THEN
          v_resp_cde := '12';
          v_err_msg := 'Error while selecting the hold amount' || SQLERRM;
          RAISE exp_reject_record;
      END;

    /*  IF v_tran_amt >= v_preauthhold_amnt
      THEN
         v_tran_amt := v_preauthhold_amnt;
      END IF;*/ --commented for FSS 837

      --Sn Commented by Pankaj S. on 21_Nov_2013 for Mantis ID 13025
      /*--- st Expiry date validation for ols changes
      BEGIN
         IF p_expry_date <> TO_CHAR (v_expry_date, 'YYMM')
         THEN
            v_resp_cde := '13';
            v_err_msg := 'EXPIRY DATE NOT EQUAL TO APPL EXPRY DATE ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                    'ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      --- end Expiry date validation for ols changes*/
      --En Commented by Pankaj S. on 21_Nov_2013 for Mantis ID 13025

      --Sn GPR Card status check
  /*    BEGIN
         sp_status_check_gpr (p_inst_code,
                              p_card_no,
                              p_delivery_channel,
                              v_expry_date,
                              v_applpan_cardstat,
                              p_txn_code,
                              p_txn_mode,
                              v_prod_code,
                              v_prod_cattype,
                              p_msg,
                              p_tran_date,
                              p_tran_time,
                              p_international_ind,
                              p_pos_verfication,
                              p_mcc_code,
                              v_resp_cde,
                              v_err_msg
                             );

         IF (   (v_resp_cde <> '1' AND v_err_msg <> 'OK')
             OR (v_resp_cde <> '0' AND v_err_msg <> 'OK')
            )
         THEN
            RAISE exp_reject_record;
         ELSE
            v_status_chk := v_resp_cde;
            v_resp_cde := '1';
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Error from GPR Card Status Check '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En GPR Card status check
      IF v_status_chk = '1'
      THEN
         -- Expiry Check
         BEGIN
            IF TO_DATE (p_tran_date, 'YYYYMMDD') >
                               LAST_DAY (TO_CHAR (v_expry_date, 'DD-MON-YY'))
            THEN
               v_resp_cde := '13';
               v_err_msg := 'EXPIRED CARD ISSUE';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                    'ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;*/

         -- End Expiry Check
--Sn Added on 10/04/2014 for Mantis ID 14133
 BEGIN
         SELECT ptp_param_value
           INTO v_precheck_flag
           FROM pcms_tranauth_param
          WHERE ptp_param_name = 'PRE CHECK' AND ptp_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';                      --only for master setups
            v_err_msg :=
                        'Master set up is not done for Authorization Process';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';                      --only for master setups
            v_err_msg :=
                  'Error while selecting precheck flag'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

 --En Added on 10/04/2014 for Mantis ID 14133


         --Sn check for precheck
         IF v_precheck_flag = 1
         THEN
            BEGIN
               sp_precheck_txn (p_inst_code,
                                p_card_no,
                                p_delivery_channel,
                                v_expry_date,
                                v_applpan_cardstat,
                                p_txn_code,
                                p_txn_mode,
                                p_tran_date,
                                p_tran_time,
                                v_tran_amt,
                                v_atmonline_limit,
                                v_posonline_limit,
                                v_resp_cde,
                                v_err_msg
                               );

               IF (v_resp_cde <> '1' OR v_err_msg <> 'OK')
               THEN
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Error from precheck processes '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;
   --   END IF;

      --En check for Precheck

      --Sn select authorization processe flag
      BEGIN
         SELECT ptp_param_value
           INTO v_preauth_flag
           FROM pcms_tranauth_param
          WHERE ptp_param_name = 'PRE AUTH' AND ptp_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                        'Master set up is not done for Authorization Process';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';                      --only for master setups
            v_err_msg :=
                  'Error while selecting precheck flag'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En select authorization process   flag
      IF v_preauth_flag = 1
      THEN
         BEGIN
            sp_elan_preauthorize_txn (p_card_no,
                                      p_mcc_code,
                                      p_curr_code,
                                      v_tran_date,
                                      p_txn_code,
                                      p_inst_code,
                                      p_tran_date,
                                      v_tran_amt,
                                      p_delivery_channel,
                                      NULL,
                                      P_MERCHANT_CNTRYCODE,
                                      v_hold_amount,
                                      v_hold_days,
                                      v_resp_cde,
                                      v_err_msg,
                                      P_acqInstAlphaCntrycode_in
                                     );

            IF (v_resp_cde <> '1' OR TRIM (v_err_msg) <> 'OK')
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Error from elan pre_auth process-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      --Sn - commented for fwr-48
      --Sn find function code attached to txn code
    /*  BEGIN
         SELECT cfm_func_code
           INTO v_func_code
           FROM cms_func_mast
          WHERE cfm_txn_code = p_txn_code
            AND cfm_txn_mode = p_txn_mode
            AND cfm_delivery_channel = p_delivery_channel
            AND cfm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '69';
            v_err_msg :=
                      'Function code not defined for txn code ' || p_txn_code;
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            v_resp_cde := '69';
            v_err_msg :=
                 'More than one function defined for txn code ' || p_txn_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '69';
            v_err_msg :=
               'Error while selecting CMS_FUNC_MAST ' || p_txn_code
               || SQLERRM;
            RAISE exp_reject_record;
      END;*/

      --En find function code attached to txn code
      --En - commented for fwr-48
      --Sn find prod code and card type and available balance for the card number
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no,
                    cam_type_code --Added by Pankaj S. for logging changes(Mantis ID-13160)
               INTO v_acct_balance, v_ledger_bal, v_card_acct_no,
                    v_acct_type --Added by Pankaj S. for logging changes(Mantis ID-13160)
               FROM cms_acct_mast
              WHERE cam_acct_no = v_acct_number
                    AND cam_inst_code = p_inst_code
          FOR UPDATE;                           -- Added for Concurrent Processsing Issue
        --FOR UPDATE NOWAIT;                     -- Commented for Concurrent Processsing Issue

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';
            v_err_msg := 'Invalid Account Number ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Error while selecting data from Account Master for Account number '
               || SQLERRM;
            RAISE exp_reject_record;
      END;

      --En find prod code and card type for the card number


    ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------

      BEGIN

			 --Added for VMS-5739/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
		   WHERE  OPERATION_TYPE='ARCHIVE'
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';

         v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

        IF (v_Retdate>v_Retperiod) THEN	                                                  --Added for VMS-5739/FSP-991

         SELECT COUNT (1)
           INTO v_stan_count
           FROM transactionlog
          WHERE --instcode = p_inst_code AND --For Instcode removal of 2.4.2.4.2 release
          customer_card_no = v_hash_pan
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel
            AND   ADD_INS_DATE BETWEEN TRUNC(SYSDATE-1)  AND SYSDATE
            AND system_trace_audit_no = p_stan;

	    ELSE

		   SELECT COUNT (1)
           INTO v_stan_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                   --Added for VMS-5739/FSP-991
          WHERE --instcode = p_inst_code AND --For Instcode removal of 2.4.2.4.2 release
          customer_card_no = v_hash_pan
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel
            AND   ADD_INS_DATE BETWEEN TRUNC(SYSDATE-1)  AND SYSDATE
            AND system_trace_audit_no = p_stan;

		END IF;

         IF v_stan_count > 0
         THEN
            v_resp_cde := '191';
            v_err_msg := 'Duplicate STAN from the Treminal';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while checking duplicate STAN '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;


      --Sn Duplicate RRN Check
  /*    BEGIN
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE terminal_id = p_term_id
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel
            AND msgtype IN ('1120', '1121')
            AND txn_code = p_txn_code
            AND CUSTOMER_CARD_NO=V_HASH_PAN;--ADDED BY ABDUL HAMEED M.A ON 06-03-2014

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
      EXCEPTION ----Added for 12296(review comments)
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while checking duplicate RRN '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END; */ -- commented for OLS Perf Improvement

      --En Duplicate RRN Check

      --Sn SAF  txn Check
      BEGIN
         IF p_msg = '1121'
         THEN

		    v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

        IF (v_Retdate>v_Retperiod) THEN	                                                  --Added for VMS-5739/FSP-991

            SELECT COUNT (*)
              INTO v_saf_txn_count
              FROM transactionlog
             WHERE rrn = p_rrn
               AND business_date = p_tran_date
               AND customer_card_no = v_hash_pan
               --AND instcode = p_inst_code --For Instcode removal of 2.4.2.4.2 release
               AND terminal_id = p_term_id
               AND response_code = '00'
               AND msgtype = '1120'
               AND txn_code = p_txn_code;

		ELSE

		      SELECT COUNT (*)
              INTO v_saf_txn_count
              FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                  --Added for VMS-5739/FSP-991
             WHERE rrn = p_rrn
               AND business_date = p_tran_date
               AND customer_card_no = v_hash_pan
               --AND instcode = p_inst_code --For Instcode removal of 2.4.2.4.2 release
               AND terminal_id = p_term_id
               AND response_code = '00'
               AND msgtype = '1120'
               AND txn_code = p_txn_code;

		END IF;

            IF v_saf_txn_count > 0
            THEN
               v_resp_cde := '38';
               v_err_msg :=
                     'Successful SAF Transaction has already done';
                  --   || SUBSTR (SQLERRM, 1, 200);Commented based on the review comments of 14122
               RAISE exp_reject_record;
            END IF;
         END IF;
      EXCEPTION--Added for 12296(review comments)
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while checking duplicate SAF transaction '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En SAF  txn Check
      BEGIN

			 --Added for VMS-5739/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
		   WHERE  OPERATION_TYPE='ARCHIVE'
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';

		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_business_date), 1, 8), 'yyyymmdd');

       IF (v_Retdate>v_Retperiod) THEN                                                --Added for VMS-5739/FSP-991

         SELECT COUNT (1)
           INTO v_dup_txn_check
           FROM transactionlog
          WHERE CUSTOMER_CARD_NO = v_hash_pan
            AND original_stan = p_orgnl_stan
            AND orgnl_business_date = p_orgnl_business_date
            AND orgnl_business_time = p_orgnl_business_time
            AND response_code = '00'
            AND delivery_channel = p_delivery_channel
            AND msgtype IN ('1120', '1121')
            AND txn_code = p_txn_code;

	    ELSE

		   SELECT COUNT (1)
           INTO v_dup_txn_check
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                 --Added for VMS-5739/FSP-991
          WHERE CUSTOMER_CARD_NO = v_hash_pan
            AND original_stan = p_orgnl_stan
            AND orgnl_business_date = p_orgnl_business_date
            AND orgnl_business_time = p_orgnl_business_time
            AND response_code = '00'
            AND delivery_channel = p_delivery_channel
            AND msgtype IN ('1120', '1121')
            AND txn_code = p_txn_code;


		END IF;


         IF v_dup_txn_check > 0
         THEN
            v_resp_cde := '155';
            v_err_msg := 'Successful Adjustment Transaction has already done';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while fetching duplicate Adjustment count '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;


    ------------------------------------------------------
        --En Added for Concurrent Processsing Issue
    ------------------------------------------------------


      --En Check PreAuth Completion txn
      BEGIN
         sp_tran_fees_cmsauth (p_inst_code,
                               p_card_no,
                               p_delivery_channel,
                               v_txn_type,
                               p_txn_mode,
                               p_txn_code,
                               p_curr_code,
                               p_consodium_code,
                               p_partner_code,
                               v_tran_amt,
                               v_tran_date,
                               p_international_ind,
                               p_pos_verfication,
                               v_resp_cde,
                               p_msg,
                               p_rvsl_code,
                               --Added by Deepa on June 25 2012 for Reversal txn Fee
                               p_mcc_code,
                               v_fee_amt,
                               v_error,
                               v_fee_code,
                               v_fee_crgl_catg,
                               v_fee_crgl_code,
                               v_fee_crsubgl_code,
                               v_fee_cracct_no,
                               v_fee_drgl_catg,
                               v_fee_drgl_code,
                               v_fee_drsubgl_code,
                               v_fee_dracct_no,
                               v_st_calc_flag,
                               v_cess_calc_flag,
                               v_st_cracct_no,
                               v_st_dracct_no,
                               v_cess_cracct_no,
                               v_cess_dracct_no,
                               v_feeamnt_type,
                               v_clawback,
                               v_fee_plan,
                               v_per_fees,
                               v_flat_fees,
                               v_freetxn_exceed,
                               v_duration,
                               v_feeattach_type,
                               V_FEE_DESC,  -- Added for MVCSD-4471
                               'N',p_surchrg_ind --Added for VMS-5856
                              );

         IF v_error <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := v_error;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                   'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      ---En dynamic fee calculation .
         if(v_preauth_type!='C') then --Added for 15606
    --Sn Added for FSS 837
--SN added to find the completion txn fee for the auth adjustment txn
      BEGIN
      SELECT cpt_compl_txncode
      INTO v_completion_txn_code
       FROM cms_preauthcomp_txncode
       WHERE cpt_inst_code = p_inst_code AND cpt_adjst_txncode = p_txn_code;

        EXCEPTION
     WHEN NO_DATA_FOUND THEN
      v_completion_txn_code:='00';
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting data for Completion transaction code ' ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
       END;


 BEGIN
         sp_tran_fees_cmsauth (p_inst_code,
                               p_card_no,
                               p_delivery_channel,
                               '1',
                               p_txn_mode,
                               v_completion_txn_code,
                               p_curr_code,
                               p_consodium_code,
                               p_partner_code,
                               v_tran_amt,
                               v_tran_date,
                               p_international_ind,
                               p_pos_verfication,
                               v_resp_cde,
                               '1220',
                               p_rvsl_code,
                               p_mcc_code,
                               v_comp_fee_amt,
                               v_comp_error,
                               v_comp_fee_code,
                               v_comp_fee_crgl_catg,
                               v_comp_fee_crgl_code,
                               v_comp_fee_crsubgl_code,
                               v_comp_fee_cracct_no,
                               v_comp_fee_drgl_catg,
                               v_comp_fee_drgl_code,
                               v_comp_fee_drsubgl_code,
                               v_comp_fee_dracct_no,
                               v_comp_st_calc_flag,
                               v_comp_cess_calc_flag,
                               v_comp_st_cracct_no,
                               v_comp_st_dracct_no,
                               v_comp_cess_cracct_no,
                               v_comp_cess_dracct_no,
                               v_comp_feeamnt_type,
                               v_comp_clawback,
                               v_comp_fee_plan,
                               v_comp_per_fees,
                               v_comp_flat_fees,
                               v_comp_freetxn_exceed,
                               v_comp_duration,
                               v_comp_feeattach_type,
                               V_COMP_FEE_DESC
                              );

         IF v_comp_error <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := v_comp_error;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                   'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;


  --Sn calculate waiver on the fee
      BEGIN
         sp_calculate_waiver (p_inst_code,
                              p_card_no,
                              '000',
                              v_prod_code,
                              v_prod_cattype,
                              v_comp_fee_code,
                              v_comp_fee_plan,
                              v_tran_date,
                              v_comp_waiv_percnt,
                              v_comp_err_waiv
                             );

         IF v_comp_err_waiv <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := v_comp_err_waiv;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En calculate waiver on the fee

      --Sn apply waiver on fee amount
      v_comp_fee_amt := ROUND (v_comp_fee_amt - ((v_comp_fee_amt * v_comp_waiv_percnt) / 100), 2);

      --En apply waiver on fee amount

      --Sn apply service tax and cess
      IF v_comp_st_calc_flag = 1
      THEN
         v_comp_servicetax_amount := (v_comp_fee_amt * v_comp_servicetax_percent) / 100;
      ELSE
         v_comp_servicetax_amount := 0;
      END IF;

      IF v_comp_cess_calc_flag = 1
      THEN
         v_comp_cess_amount := (v_comp_servicetax_amount * v_comp_cess_percent) / 100;
      ELSE
         v_comp_cess_amount := 0;
      END IF;

      v_comp_total_fee :=
                    ROUND (v_comp_fee_amt + v_comp_servicetax_amount + v_comp_cess_amount, 2);
      --En apply service tax and cess
  v_comp_fee_hold:=v_comp_total_fee;
IF (v_completion_fee <> v_comp_total_fee) THEN

IF v_completion_fee < v_comp_total_fee THEN
v_tot_hold_amt:=v_tran_amt+(v_comp_total_fee-v_completion_fee);
v_comp_total_fee:=v_comp_total_fee-v_completion_fee;
v_complfee_increment_type:='D';
ELSE
v_tot_hold_amt:=v_tran_amt-(v_completion_fee-v_comp_total_fee);
v_comp_total_fee:=v_completion_fee-v_comp_total_fee;
v_complfee_increment_type:='C';
END IF;
ELSE
v_tot_hold_amt:=v_tran_amt;
v_comp_total_fee:=0;
v_complfee_increment_type:='N';
END IF;



--EN added to find the completion txn feefor the auth adjustment txn

--En Added for FSS 837

end if; --Added for 15606
      --Sn calculate waiver on the fee
      BEGIN
         sp_calculate_waiver (p_inst_code,
                              p_card_no,
                              '000',
                              v_prod_code,
                              v_prod_cattype,
                              v_fee_code,
                              v_fee_plan,
                              v_tran_date,
                              v_waiv_percnt,
                              v_err_waiv
                             );

         IF v_err_waiv <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := v_err_waiv;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En calculate waiver on the fee

      --Sn apply waiver on fee amount
      v_log_actual_fee := v_fee_amt;           --only used to log in log table
      v_fee_amt := ROUND (v_fee_amt - ((v_fee_amt * v_waiv_percnt) / 100), 2);
      v_log_waiver_amt := v_log_actual_fee - v_fee_amt;

      --En apply waiver on fee amount

      --Sn apply service tax and cess
      IF v_st_calc_flag = 1
      THEN
         v_servicetax_amount := (v_fee_amt * v_servicetax_percent) / 100;
      ELSE
         v_servicetax_amount := 0;
      END IF;

      IF v_cess_calc_flag = 1
      THEN
         v_cess_amount := (v_servicetax_amount * v_cess_percent) / 100;
      ELSE
         v_cess_amount := 0;
      END IF;

      v_total_fee :=
                    ROUND (v_fee_amt + v_servicetax_amount + v_cess_amount, 2);
      --En apply service tax and cess

      --Sn find total transaction    amount
      if(v_preauth_type!='C') then --Added for 15606
      v_total_amt := v_tran_amt + v_total_fee;
      -- Sn Added for 15606
      else
       v_total_amt := v_tran_amt - v_total_fee;
       end if;
      --En Added for 15606

      --Sn create gl entries and acct update
      BEGIN

      IF(V_PREAUTH_TYPE!='C') THEN
      -- FSS-4960 - UPI Enhancement_Preauth-Cancel Reversal beg
      IF V_NETWORK_FLAG > 0 THEN
      V_ADJ_AMT:=V_TOTAL_AMT;
      else
      --Sn Added for 15194
       V_ADJ_AMT:=V_TOT_HOLD_AMT;
       END IF;
       -- FSS-4960 - UPI Enhancement_Preauth-Cancel Reversal end
       else
        V_adj_amt:=V_PREAUTHHOLD_AMNT;
        end if;
    --En Added for 15194

         sp_upd_transaction_accnt_auth
                     (p_inst_code,
                      v_tran_date,
                      v_prod_code,
                      V_PROD_CATTYPE,
                    --  v_tran_amt,
                    V_adj_amt,--Modified for  15606

                      v_func_code,
                      p_txn_code,
                      v_dr_cr_flag,
                      p_rrn,
                      p_term_id,
                      p_delivery_channel,
                      p_txn_mode,
                      p_card_no,
                      v_fee_code,
                      v_fee_amt,
                      v_fee_cracct_no,
                      v_fee_dracct_no,
                      v_st_calc_flag,
                      v_cess_calc_flag,
                      v_servicetax_amount,
                      v_st_cracct_no,
                      v_st_dracct_no,
                      v_cess_amount,
                      v_cess_cracct_no,
                      v_cess_dracct_no,
                      v_card_acct_no,
                      v_preauthhold_amnt, --Preauth Hold amount for adjustment
                      p_msg,
                      v_resp_cde,
                      v_err_msg
                     );

         IF (v_resp_cde <> '1' OR v_err_msg <> 'OK')
         THEN
            v_resp_cde := '21';
            RAISE exp_reject_record;
         end if;
     --  END IF;  --Commented for 15194
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En st to update cms_preauth_transaction table

       -- FSS-4960 - UPI Enhancement_Preauth-Cancel Reversal beg

      BEGIN
      IF V_NETWORK_FLAG > 0 THEN
      INSERT INTO cms_preauth_transaction
                                 (cpt_card_no, cpt_txn_amnt, cpt_expiry_date,
                                  cpt_sequence_no, cpt_preauth_validflag, cpt_inst_code,
                                  cpt_mbr_no, cpt_card_no_encr, cpt_completion_flag,
                                  cpt_approve_amt,
                                  cpt_rrn, cpt_txn_date, cpt_txn_time, cpt_terminalid,
                                  cpt_expiry_flag,
                                  cpt_totalhold_amt,
                                  cpt_transaction_flag, cpt_acct_no, cpt_mcc_code,
                                  cpt_completion_fee,
                                  --Sn Added for Transactionlog Functional Removal Phase-II changes
                                  cpt_delivery_channel, cpt_txn_code, cpt_merchant_id,
                                  cpt_merchant_name,  cpt_merchant_city, cpt_merchant_state,
                                  cpt_merchant_zip,  cpt_pos_verification, cpt_internation_ind_response
                                  --En Added for Transactionlog Functional Removal Phase-II changes
                                 )
                          VALUES (v_hash_pan, v_tran_amt, v_preauth_date,
                                  '1', 'Y', p_inst_code,
                                  p_mbr_numb, v_encr_pan, 'N',
                                  TRIM (TO_CHAR (NVL (v_tran_amt, 0),
                                                 '999999999999999990.99'
                                                )
                                       ),
                                  p_rrn, p_tran_date, p_tran_time, p_term_id,
                                  'N',
                                  TRIM (TO_CHAR (NVL (v_tran_amt, 0),
                                                 '999999999999999990.99'
                                                )
                                       ),
                                  v_tran_type, v_acct_number, p_mcc_code,
                                  v_comp_total_fee,
                                 p_delivery_channel, p_txn_code, P_MERCHANT_ID,
                                 p_merchant_name, p_merchant_city, p_atmname_loc,
                                 p_merchant_zip, p_pos_verfication, p_international_ind
                                 );
      ELSE

				 --Added for VMS-5739/FSP-991
	       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
		   WHERE  OPERATION_TYPE='ARCHIVE'
		   AND OBJECT_NAME='CMS_PREAUTH_TRANSACTION_EBR';

		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_business_date), 1, 8), 'yyyymmdd');

		IF (v_Retdate>v_Retperiod) THEN

         UPDATE cms_preauth_transaction
            SET cpt_totalhold_amt = v_tran_amt,
                cpt_preauth_validflag = DECODE (v_tran_amt, 0, 'N', 'Y'),
                cpt_transaction_flag = 'A',
                CPT_TRANSACTION_RRN=p_rrn,
                cpt_completion_fee=v_comp_fee_hold --Added for FSS 837
                ,cpt_approve_amt=v_tran_amt
          WHERE cpt_rrn = v_preauth_rrn
            AND cpt_txn_date = p_orgnl_business_date
            AND cpt_inst_code = p_inst_code
            AND cpt_mbr_no = p_mbr_numb
            AND cpt_card_no = v_hash_pan
            AND cpt_txn_time = p_orgnl_business_time
            AND cpt_preauth_validflag <> 'N'
            AND CPT_EXPIRY_FLAG = 'N';
            
            IF SQL%ROWCOUNT     = 0 THEN            
                UPDATE cms_preauth_transaction
                SET cpt_totalhold_amt = v_tran_amt,
                cpt_preauth_validflag = DECODE (v_tran_amt, 0, 'N', 'Y'),
                cpt_transaction_flag = 'A',
                CPT_TRANSACTION_RRN=p_rrn,
                cpt_completion_fee=v_comp_fee_hold --Added for FSS 837
                ,cpt_approve_amt=v_tran_amt
            WHERE cpt_rrn = v_preauth_rrn
            --AND cpt_txn_date = p_orgnl_business_date
            AND cpt_inst_code = p_inst_code
            AND cpt_mbr_no = p_mbr_numb
            AND cpt_card_no = v_hash_pan
            --AND cpt_txn_time = p_orgnl_business_time
            AND cpt_preauth_validflag <> 'N'
            AND CPT_EXPIRY_FLAG = 'N';            
            END IF;

		ELSE

		    UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                               --Added for VMS-5739/FSP-991
            SET cpt_totalhold_amt = v_tran_amt,
                cpt_preauth_validflag = DECODE (v_tran_amt, 0, 'N', 'Y'),
                cpt_transaction_flag = 'A',
                CPT_TRANSACTION_RRN=p_rrn,
                cpt_completion_fee=v_comp_fee_hold --Added for FSS 837
                ,cpt_approve_amt=v_tran_amt
          WHERE cpt_rrn = v_preauth_rrn
            AND cpt_txn_date = p_orgnl_business_date
            AND cpt_inst_code = p_inst_code
            AND cpt_mbr_no = p_mbr_numb
            AND cpt_card_no = v_hash_pan
            AND cpt_txn_time = p_orgnl_business_time
            AND cpt_preauth_validflag <> 'N'
            AND CPT_EXPIRY_FLAG = 'N';
            
            IF SQL%ROWCOUNT     = 0 THEN            
                UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                               --Added for VMS-5739/FSP-991
            SET cpt_totalhold_amt = v_tran_amt,
                cpt_preauth_validflag = DECODE (v_tran_amt, 0, 'N', 'Y'),
                cpt_transaction_flag = 'A',
                CPT_TRANSACTION_RRN=p_rrn,
                cpt_completion_fee=v_comp_fee_hold --Added for FSS 837
                ,cpt_approve_amt=v_tran_amt
          WHERE cpt_rrn = v_preauth_rrn
            --AND cpt_txn_date = p_orgnl_business_date
            AND cpt_inst_code = p_inst_code
            AND cpt_mbr_no = p_mbr_numb
            AND cpt_card_no = v_hash_pan
            --AND cpt_txn_time = p_orgnl_business_time
            AND cpt_preauth_validflag <> 'N'
            AND CPT_EXPIRY_FLAG = 'N';          
            END IF;

		END IF;
      END IF;
         IF SQL%ROWCOUNT = 0
         THEN
            v_err_msg :=
                'Error while updating the hold maount of Preauth Trasnaction';
            v_resp_cde := '21';
            RAISE exp_reject_record;
         END IF;
      END;
        --Fn st Inserting cms_preauth_trans_hist table
    BEGIN
      IF V_NETWORK_FLAG > 0 THEN
    INSERT INTO CMS_PREAUTH_TRANS_HIST
             (CPH_CARD_NO,
              CPH_TXN_AMNT,
              CPH_EXPIRY_DATE,
              CPH_SEQUENCE_NO,
              CPH_PREAUTH_VALIDFLAG,
              CPH_INST_CODE,
              CPH_MBR_NO,
              CPH_CARD_NO_ENCR,
              CPH_COMPLETION_FLAG,
              CPH_APPROVE_AMT,
              CPH_RRN,
              CPH_TXN_DATE,
              CPH_TXN_TIME,
              CPH_TERMINALID,
              CPH_EXPIRY_FLAG,
              CPH_TRANSACTION_FLAG,
              CPH_TOTALHOLD_AMT,
              CPH_TRANSACTION_RRN,
              CPH_ACCT_NO,
              CPH_MERCHANT_NAME,
              CPH_MERCHANT_STATE,
              CPH_MERCHANT_CITY
              ,CPH_DELIVERY_CHANNEL
              ,CPH_TRAN_CODE,
              CPH_PANNO_LAST4DIGIT,
               cph_completion_fee
             )
            VALUES
             (V_HASH_PAN,
              v_tran_amt ,
              V_PREAUTH_DATE,
              p_rrn ,
              'Y',
              P_INST_CODE,
              P_MBR_NUMB,
              V_ENCR_PAN,
              'N',
              TRIM (TO_CHAR (nvl(v_tran_amt,0),'999999999999999990.99')),
              P_RRN,
              P_TRAN_DATE,
              P_TRAN_TIME,
              P_TERM_ID,
              'N',
              v_tran_type,
              trim(to_char(nvl(V_TRAN_AMT,0),'999999999999999990.99')),
              P_RRN,
              V_ACCT_NUMBER,
              P_MERCHANT_NAME,
              P_ATMNAME_LOC,
              P_MERCHANT_CITY
              ,P_DELIVERY_CHANNEL
              ,P_TXN_CODE,
               (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
               V_COMP_TOTAL_FEE
              );
              ELSE
       INSERT INTO cms_preauth_trans_hist
                   (cph_card_no, cph_txn_amnt, cph_sequence_no,
                    cph_preauth_validflag, cph_inst_code, cph_mbr_no,
                    cph_card_no_encr, cph_completion_flag,
                    cph_approve_amt,
                    cph_rrn, cph_txn_date, cph_txn_time, cph_terminalid,
                    cph_expiry_flag, cph_transaction_flag,
                    cph_totalhold_amt,
                    cph_transaction_rrn, cph_acct_no, cph_merchant_name,
                    cph_merchant_state, cph_merchant_city,CPH_DELIVERY_CHANNEL,CPH_TRAN_CODE,
                    CPH_PANNO_LAST4DIGIT,  --Added by Abdul Hameed M.A on 12 Feb 2014 for Mantis ID 13645
                    cph_completion_fee --Added for FSS 837
                    ,cph_preauth_type--Added for MVHOST 926
                   )
            VALUES (v_hash_pan, v_tran_amt, p_rrn,
                    DECODE (v_tran_amt, 0, 'N', 'Y'), p_inst_code, p_mbr_numb,
                    v_encr_pan, 'N',
                    TRIM (TO_CHAR (NVL (v_tran_amt, 0), '999999999999999990.99')),
                    p_rrn, p_tran_date, p_tran_time, p_term_id,
                    'N', 'A',
                    TRIM (TO_CHAR (NVL (v_tran_amt, 0), '999999999999999990.99')),
                    p_rrn, v_acct_number, p_merchant_name,
                    p_atmname_loc, p_merchant_city,p_delivery_channel,p_txn_code, -- Added for Mantis ID -13467
                     (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))), --Added by Abdul Hameed M.A on 12 Feb 2014 for Mantis ID 13645
                     v_comp_fee_hold --Added for FSS 837
                     ,V_PREAUTH_TYPE
                   );
                   END IF;
              -- FSS-4960 - UPI Enhancement_Preauth-Cancel Reversal end

    EXCEPTION
       WHEN OTHERS
       THEN
          v_err_msg :=
                'Error while inserting  CMS_PREAUTH_TRANS_HIST '|| SUBSTR (SQLERRM, 1, 300);
          v_resp_cde := '21';
          RAISE exp_reject_record;
    END;
     --Fn end to Inserting cms_preauth_trans_hist table

      --Sn find narration
      IF TRIM (v_trans_desc) IS NOT NULL
      THEN
         v_narration := v_trans_desc || '/';
      END IF;

      IF TRIM (p_merchant_name) IS NOT NULL
      THEN
         v_narration := v_narration || p_merchant_name || '/';
      END IF;

      -- Changed for FSS-4119
      IF TRIM (P_TERM_ID) IS NOT NULL
      THEN
         v_narration := v_narration || P_TERM_ID || '/';
      END IF;

      IF TRIM (P_MERCHANT_CITY) IS NOT NULL
      THEN
         v_narration := v_narration || P_MERCHANT_CITY || '/';
      END IF;

      IF TRIM (p_tran_date) IS NOT NULL
      THEN
         v_narration := v_narration || p_tran_date || '/';
      END IF;

      IF TRIM (v_auth_id) IS NOT NULL
      THEN
         v_narration := v_narration || v_auth_id;
      END IF;

      --En find narration

       v_length_pan:= LENGTH (p_card_no);--Added for 12296(review comments)

      --Sn find fee opening balance
      IF v_total_fee <> 0 OR v_freetxn_exceed = 'N'
      THEN
         BEGIN
          /*  SELECT DECODE (v_dr_cr_flag,
                           'DR', v_acct_balance - v_tran_amt,
                           'CR', v_acct_balance + v_tran_amt,
                           'NA', v_acct_balance
                          )
              INTO v_fee_opening_bal
              FROM DUAL; */
         --Modified on 09/04/2014 for Mantis ID 14086
 SELECT DECODE (v_dr_cr_flag,
                           'DR', v_ledger_bal - v_tran_amt,
                           'CR', v_ledger_bal + v_tran_amt,
                           'NA', v_ledger_bal
                          )
              INTO v_fee_opening_bal
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '12';
               v_err_msg :=
                     'Error while selecting data from Fee Opening balance ';
              --    || p_card_no; Commented based on the review comments of 14122
               RAISE exp_reject_record;
         END;

         --En find fee opening balance
         --Sn create entries for FEES attached
         IF v_freetxn_exceed = 'N'
         THEN
            BEGIN
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_opening_bal, csl_trans_amount,
                            csl_trans_type, csl_trans_date,
                            csl_closing_balance,
                            csl_trans_narrration,
                            csl_inst_code, csl_pan_no_encr, csl_rrn,
                            csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_txn_code, csl_acct_no,
                            csl_ins_user, csl_ins_date, csl_merchant_name,
                            csl_merchant_city, csl_merchant_state,
                            csl_panno_last4digit,
                            --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                            csl_prod_code,csl_acct_type,csl_time_stamp,csl_card_type
                            --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                           )
                    VALUES (v_hash_pan, v_fee_opening_bal, v_total_fee,
                            'DR', v_tran_date,
                            v_fee_opening_bal - v_total_fee,
                           -- 'Complimentary ' || v_duration || ' ' -- Commented for MVCSD-4471
                            --|| v_narration, -- Commented for MVCSD-4471
                            V_FEE_DESC,  -- Added for MVCSD-4471
                            p_inst_code, v_encr_pan, p_rrn,
                            v_auth_id, p_tran_date,
                            p_tran_time, 'Y',
                            p_delivery_channel, p_txn_code, v_card_acct_no,
                            1, SYSDATE, p_merchant_name,
                            p_merchant_city, p_atmname_loc,
                            (SUBSTR (p_card_no,
                                     v_length_pan - 3,
                                     v_length_pan--Modified for 12296(review comments)
                                    )
                            ),
                            --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                            v_prod_code,v_acct_type,v_timestamp,V_PROD_CATTYPE
                            --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                           );
            EXCEPTION--Added for 12296(review comments)
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Problem while inserting into statement log for tran fee '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSE
              IF v_feeamnt_type = 'A'
               THEN
                  v_flat_fees :=
                     ROUND (  v_flat_fees
                            - ((v_flat_fees * v_waiv_percnt) / 100),
                            2
                           );
                  v_per_fees :=
                     ROUND (v_per_fees - ((v_per_fees * v_waiv_percnt) / 100),
                            2
                           );
                    BEGIN
                  --En Entry for Fixed Fee
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal, csl_trans_amount,
                               csl_trans_type, csl_trans_date,
                               csl_closing_balance,
                               csl_trans_narrration,
                               csl_inst_code, csl_pan_no_encr, csl_rrn,
                               csl_auth_id, csl_business_date,
                               csl_business_time, txn_fee_flag,
                               csl_delivery_channel, csl_txn_code,
                               csl_acct_no, csl_ins_user, csl_ins_date,
                               csl_merchant_name, csl_merchant_city,
                               csl_merchant_state,
                               csl_panno_last4digit,
                               --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                               csl_prod_code,csl_acct_type,csl_time_stamp,csl_card_type
                               --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                              )
                       VALUES (v_hash_pan, v_fee_opening_bal, v_flat_fees,
                               'DR', v_tran_date,
                               v_fee_opening_bal - v_flat_fees,
                              -- 'Fixed Fee debited for ' || v_narration, --Commented for MVCSD-4471
                               'Fixed Fee debited for ' || V_FEE_DESC, --Added for MVCSD-4471
                               p_inst_code, v_encr_pan, p_rrn,
                               v_auth_id, p_tran_date,
                               p_tran_time, 'Y',
                               p_delivery_channel, p_txn_code,
                               v_card_acct_no, 1, SYSDATE,
                               p_merchant_name, p_merchant_city,
                               p_atmname_loc,
                               (SUBSTR (p_card_no,
                                        v_length_pan - 3,
                                        v_length_pan--Modified for 12296(review comments)
                                       )
                               ),
                               --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                               v_prod_code,v_acct_type,v_timestamp,V_PROD_CATTYPE
                               --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                              );
                  EXCEPTION--Added for 12296(review comments)
                   WHEN OTHERS THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Problem while inserting into statement log for tran Fixed Fee '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
                  END;
                  --En Entry for Fixed Fee

				   IF v_per_fees <> 0 THEN --Added for VMS-5856
                  v_fee_opening_bal := v_fee_opening_bal - v_flat_fees;

                  --Sn Entry for Percentage Fee
                      BEGIN
                      INSERT INTO cms_statements_log
                                  (csl_pan_no, csl_opening_bal, csl_trans_amount,
                                   csl_trans_type, csl_trans_date,
                                   csl_closing_balance,
                                   csl_trans_narrration,
                                   csl_inst_code, csl_pan_no_encr, csl_rrn,
                                   csl_auth_id, csl_business_date,
                                   csl_business_time, txn_fee_flag,
                                   csl_delivery_channel, csl_txn_code,
                                   csl_acct_no, csl_ins_user, csl_ins_date,
                                   csl_merchant_name, csl_merchant_city,
                                   csl_merchant_state,
                                   csl_panno_last4digit,
                                   --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                                   csl_prod_code,csl_acct_type,csl_time_stamp,csl_card_type
                                   --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                                  )
                           VALUES (v_hash_pan, v_fee_opening_bal, v_per_fees,
                                   'DR', v_tran_date,
                                   v_fee_opening_bal - v_per_fees,
                                  -- 'Percetage Fee debited for ' || v_narration, --Commented for MVCSD-4471
                                  'Percentage Fee debited for ' || V_FEE_DESC, --Added for MVCSD-4471
                                   p_inst_code, v_encr_pan, p_rrn,
                                   v_auth_id, p_tran_date,
                                   p_tran_time, 'Y',
                                   p_delivery_channel, p_txn_code,
                                   v_card_acct_no, 1, SYSDATE,
                                   p_merchant_name, p_merchant_city,
                                   p_atmname_loc,
                                   (SUBSTR (p_card_no,
                                            v_length_pan - 3,
                                            v_length_pan--Modified for 12296(review comments)
                                           )
                                   ),
                                   --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                                   v_prod_code,v_acct_type,v_timestamp,V_PROD_CATTYPE
                                   --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                                  );
                   EXCEPTION--Added for 12296(review comments)
                   WHEN OTHERS
                   THEN
                      v_resp_cde := '21';
                      v_err_msg :=
                            'Problem while inserting into statement log for tran Percentage Fee '
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record;
                END;
               --En Entry for Percentage Fee
			 END IF;
               ELSE
                       BEGIN
                          INSERT INTO cms_statements_log
                                      (csl_pan_no, csl_opening_bal,
                                       csl_trans_amount, csl_trans_type,
                                       csl_trans_date, csl_closing_balance,
                                       csl_trans_narrration,
                                       csl_inst_code, csl_pan_no_encr, csl_rrn,
                                       csl_auth_id, csl_business_date,
                                       csl_business_time, txn_fee_flag,
                                       csl_delivery_channel, csl_txn_code,
                                       csl_acct_no, csl_ins_user, csl_ins_date,
                                       csl_merchant_name, csl_merchant_city,
                                       csl_merchant_state,
                                       csl_panno_last4digit,
                                       --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                                       csl_prod_code,csl_acct_type,csl_time_stamp,csl_card_type
                                       --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                                      )
                               VALUES (v_hash_pan, v_fee_opening_bal,
                                       v_total_fee, 'DR',
                                       v_tran_date, v_fee_opening_bal - v_total_fee,
                                     --  'Fee debited for ' || v_narration, --Commented for MVCSD-4471
                                       V_FEE_DESC, --Added for MVCSD-4471
                                       p_inst_code, v_encr_pan, p_rrn,
                                       v_auth_id, p_tran_date,
                                       p_tran_time, 'Y',
                                       p_delivery_channel, p_txn_code,
                                       v_card_acct_no, 1, SYSDATE,
                                       p_merchant_name, p_merchant_city,
                                       p_atmname_loc,
                                       (SUBSTR (p_card_no,
                                                v_length_pan - 3,
                                                v_length_pan--Modified for 12296(review comments)
                                               )
                                       ),
                                       --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                                       v_prod_code,v_acct_type,v_timestamp,V_PROD_CATTYPE
                                       --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                                      );

                    EXCEPTION--Added for 12296(review comments)
                       WHEN OTHERS
                       THEN
                          v_resp_cde := '21';
                          v_err_msg :=
                                'Problem while inserting into statement log for tran fee '
                             || SUBSTR (SQLERRM, 1, 200);
                          RAISE exp_reject_record;
                    END;
            END IF;
         END IF;
      END IF;

      --En create entries for FEES attached
      --Sn create a entry for successful
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                      ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_system_trace_audit_no,
                      ctd_inst_code, ctd_customer_card_no_encr,
                      ctd_cust_acct_number, ctd_merchant_zip,
                      ctd_req_resp_code,
                      ctd_internation_ind_response , --Added by Pankaj S. for Mantis ID 13024
                      ctd_completion_fee,ctd_complfee_increment_type,CTD_COMPFEE_CODE,CTD_COMPFEEATTACH_TYPE,CTD_COMPFEEPLAN_ID --Added for FSS 837
                      , CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
                      ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_msg, p_txn_mode, p_tran_date,
                      p_tran_time, v_hash_pan,
                      p_txn_amt, p_curr_code, v_tran_amt,
                      v_log_actual_fee, v_log_waiver_amt,
                      v_servicetax_amount, v_cess_amount,
                      v_total_amt, v_card_curr, 'Y',
                      'Successful', p_rrn, p_stan,
                      p_inst_code, v_encr_pan,
                      v_acct_number, p_merchant_zip,
                      p_adj_resp_code,
                      p_international_ind,  --Added by Pankaj S. for Mantis ID 13024
                      v_comp_total_fee, --Added for FSS 837
                      v_complfee_increment_type,v_comp_fee_code,v_comp_feeattach_type,v_comp_fee_plan --Added for FSS 837
                      ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
                      P_VISA_TRANSACTIONID,--Added for MVHOST 926
                      P_MC_TRACEID,--Added for MVHOST 926
                      P_CARDVERIFICATION_RESULT--Added for MVHOST 926
                      ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Problem while selecting data from response master '
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      --En create detail for response message
      v_resp_cde := '1';
      p_resp_id  := v_resp_cde; --Added for VMS-8018

      BEGIN
         SELECT cms_b24_respcde, cms_iso_respcde
           INTO p_resp_code, p_iso_respcde
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = TO_NUMBER (v_resp_cde);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_err_msg :=
                  'No Data from response master for respose code'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Problem while selecting data from response master for respose code'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK TO v_auth_savepoint;

         --Sn select response code and insert record into txn log dtl
         BEGIN
            p_resp_msg := v_err_msg;
            p_resp_id  := v_resp_cde; --Added for VMS-8018

            SELECT cms_b24_respcde, cms_iso_respcde
              INTO p_resp_code, p_iso_respcde
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';
               p_resp_id   := '69'; --Added for VMS-8018
         --  ROLLBACK; Commented based on the code review commencts on Sep-17 by Deepa
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_msg_type, ctd_txn_mode, ctd_business_date,
                         ctd_business_time, ctd_customer_card_no,
                         ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                         ctd_fee_amount, ctd_waiver_amount,
                         ctd_servicetax_amount, ctd_cess_amount,
                         ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                         ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no, ctd_inst_code,
                         ctd_customer_card_no_encr, ctd_cust_acct_number,
                         ctd_merchant_zip, ctd_req_resp_code,
                         ctd_internation_ind_response , --Added by Pankaj S. for Mantis ID 13024
                         ctd_completion_fee,ctd_complfee_increment_type,CTD_COMPFEE_CODE,CTD_COMPFEEATTACH_TYPE,CTD_COMPFEEPLAN_ID --Added for FSS 837
                          ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
                          ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE
                        )
                 VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                         p_msg, p_txn_mode, p_tran_date,
                         p_tran_time, v_hash_pan,
                         p_txn_amt, p_curr_code, v_tran_amt,
                         NULL, NULL,
                         NULL, NULL,
                         v_total_amt, v_card_curr, 'E',
                         v_err_msg, p_rrn,
                         p_stan, p_inst_code,
                         v_encr_pan, v_acct_number,
                         p_merchant_zip, p_adj_resp_code,
                         p_international_ind , --Added by Pankaj S. for Mantis ID 13024
                         v_comp_total_fee,v_complfee_increment_type,v_comp_fee_code,v_comp_feeattach_type,v_comp_fee_plan --Added for FSS 837
                         ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
                         P_VISA_TRANSACTIONID,--Added for MVHOST 926
                         P_MC_TRACEID,--Added for MVHOST 926
                         P_CARDVERIFICATION_RESULT--Added for MVHOST 926
                         ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE
                        );

            p_resp_msg := v_err_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';                         -- Server Declined
               p_resp_id   := '69'; --Added for VMS-8018
               --   ROLLBACK; Commented based on the code review commencts on Sep-17 by Deepa
               RETURN;
         END;
      WHEN OTHERS
      THEN
         ROLLBACK TO v_auth_savepoint;

         --Sn select response code and insert record into txn log dtl
         BEGIN
            SELECT cms_b24_respcde, cms_iso_respcde
              INTO p_resp_code, p_iso_respcde
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;

            p_resp_msg := v_err_msg;
            p_resp_id  := v_resp_cde; --Added for VMS-8018
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';
               p_resp_id   := '69'; --Added for VMS-8018
         --ROLLBACK; Commented based on the code review commencts on Sep-17 by Deepa
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_msg_type, ctd_txn_mode, ctd_business_date,
                         ctd_business_time, ctd_customer_card_no,
                         ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                         ctd_fee_amount, ctd_waiver_amount,
                         ctd_servicetax_amount, ctd_cess_amount,
                         ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                         ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no, ctd_inst_code,
                         ctd_customer_card_no_encr, ctd_cust_acct_number,
                         ctd_merchant_zip, ctd_req_resp_code,
                         ctd_internation_ind_response,  --Added by Pankaj S. for Mantis ID 13024
                         ctd_completion_fee,ctd_complfee_increment_type,CTD_COMPFEE_CODE,CTD_COMPFEEATTACH_TYPE,CTD_COMPFEEPLAN_ID --Added for FSS 837
                         ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT
                         ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE
                        )
                 VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                         p_msg, p_txn_mode, p_tran_date,
                         p_tran_time, v_hash_pan,
                         p_txn_amt, p_curr_code, v_tran_amt,
                         NULL, NULL,
                         NULL, NULL,
                         v_total_amt, v_card_curr, 'E',
                         v_err_msg, p_rrn,
                         p_stan, p_inst_code,
                         v_encr_pan, v_acct_number,
                         p_merchant_zip, p_adj_resp_code,
                         p_international_ind,  --Added by Pankaj S. for Mantis ID 13024
                         v_comp_total_fee,v_complfee_increment_type,v_comp_fee_code,v_comp_feeattach_type,v_comp_fee_plan --Added for FSS 837
                         ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
                         P_VISA_TRANSACTIONID,--Added for MVHOST 926
                         P_MC_TRACEID,--Added for MVHOST 926
                         P_CARDVERIFICATION_RESULT--Added for MVHOST 926
                         ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE
                        );

            p_resp_msg := v_err_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';
               p_resp_id   := '69'; --Added for VMS-8018
         --  ROLLBACK; Commented based on the code review commencts on Sep-17 by Deepa
         END;
   --En select response code and insert record into txn log dtl
   END;

   --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
   IF v_prod_code IS NULL THEN
    BEGIN
       SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
         INTO v_prod_code, v_prod_cattype, v_applpan_cardstat, v_acct_number
         FROM cms_appl_pan
        WHERE cap_pan_code = gethash (p_card_no) AND cap_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS
       THEN
          NULL;
    END;
   END IF;

   IF v_dr_cr_flag IS NULL THEN
    BEGIN
       SELECT ctm_credit_debit_flag,
              TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
              ctm_tran_type, ctm_tran_desc
         INTO v_dr_cr_flag,
              v_txn_type,
              v_tran_type, v_trans_desc
         FROM cms_transaction_mast
        WHERE ctm_tran_code = p_txn_code
          AND ctm_delivery_channel = p_delivery_channel
          AND ctm_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS
       THEN
          NULL;
    END;
   END IF;
   --En Added by Pankaj S. for logging changes(Mantis ID-13160)

   BEGIN
      SELECT     cam_acct_bal, cam_ledger_bal,
                 cam_type_code --Added by Pankaj S. for logging changes(Mantis ID-13160)
            INTO v_acct_balance, p_ledger_bal,
                 v_acct_type --Added by Pankaj S. for logging changes(Mantis ID-13160)
            FROM cms_acct_mast
           WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      --FOR UPDATE NOWAIT;                                                      -- Commented for Concurrent Processsing Issue
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '14';
         v_err_msg := 'Invalid Account Number ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '12';
         v_err_msg :=
               'Error while selecting data from Account  Master for Account number '
            || SQLERRM;
         RAISE exp_reject_record;
   END;

   --- Sn create GL ENTRIES
   IF v_resp_cde = '1'
   THEN
      v_business_time := TO_CHAR (v_tran_date, 'HH24:MI');

      IF v_business_time > v_cutoff_time
      THEN
         v_business_date := TRUNC (v_tran_date) + 1;
      ELSE
         v_business_date := TRUNC (v_tran_date);
      END IF;

      p_resp_msg := TO_CHAR (v_acct_balance);
      p_acct_bal := TO_CHAR (v_acct_balance);-- Added by Deepa on FSS-1313 to return the account balance for decline case also
   ELSE

        p_acct_bal := TO_CHAR (v_acct_balance);-- Added by Deepa on FSS-1313 to return the account balance for decline case also
   END IF;

   --Sn create a entry in txn log
   BEGIN
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, terminal_id,
                   date_time, txn_code, txn_type, txn_mode,
                   txn_status, response_code,
                   business_date, business_time, customer_card_no,
                   topup_card_no, topup_acct_no, topup_acct_type, bank_code,
                   total_amount,
                   rule_indicator, rulegroupid, mccode, currencycode,
                   addcharge, productid, categoryid, tips,
                   decline_ruleid, atm_name_location, auth_id, trans_desc,
                   amount,
                   preauthamount, partialamount, mccodegroupid,
                   currencycodegroupid, transcodegroupid, rules,
                   preauth_date, gl_upd_flag, system_trace_audit_no,
                   instcode, feecode, tranfee_amt, servicetax_amt,
                   cess_amt, cr_dr_flag, tranfee_cr_acctno,
                   tranfee_dr_acctno, tran_st_calc_flag,
                   tran_cess_calc_flag, tran_st_cr_acctno,
                   tran_st_dr_acctno, tran_cess_cr_acctno,
                   tran_cess_dr_acctno, customer_card_no_encr,
                   topup_card_no_encr, proxy_number, reversal_code,
                   customer_acct_no, acct_balance, ledger_balance,
                   response_id, cardstatus, feeattachtype,
                   merchant_name, merchant_city, merchant_state,
                   addl_amnt, networkid_switch, networkid_acquirer,
                   network_settl_date, permrule_verify_flag, merchant_zip,
                   cvv_verificationtype, error_msg, fee_plan,
                   ORGNL_BUSINESS_DATE,ORGNL_BUSINESS_TIME,ORIGINAL_STAN,
                   internation_ind_response,  --Added by Pankaj S. for Mantis ID 13024
                   --Sn added by Pankaj S. for logging changes(Mantis ID-13160)
                   acct_type,time_stamp
                   --En added by Pankaj S. for logging changes(Mantis ID-13160)
                   ,merchant_id,remark, --Added for error msg need to display in CSR(declined by rule)
                   surchargefee_ind_ptc  --Added for VMS-5856
                  )
           VALUES (p_msg, p_rrn, p_delivery_channel, p_term_id,
                   v_business_date, p_txn_code, v_txn_type, p_txn_mode,
                   DECODE (p_iso_respcde, '00', 'C', 'F'), p_iso_respcde,
                   p_tran_date, SUBSTR (p_tran_time, 1, 10), v_hash_pan,
                   NULL, NULL, NULL, p_bank_code,
                   TRIM (TO_CHAR (nvl(v_total_amt,0), '999999999999999990.99')),  --Formatted by Pankaj S. for logging changes(Mantis ID-13160)
                   NULL, NULL, p_mcc_code, p_curr_code,
                   NULL, v_prod_code, v_prod_cattype, nvl(p_tip_amt,'0.00'), --Formatted by Pankaj S. for logging changes(Mantis ID-13160)
                   p_decline_ruleid, p_atmname_loc, v_auth_id, v_trans_desc,
                   TRIM (TO_CHAR (nvl(v_tran_amt,0), '999999999999999990.99')), --Formatted by Pankaj S. for logging changes(Mantis ID-13160)
                   P_MERCHANT_CNTRYCODE,'0.00', --Formatted by Pankaj S. for logging changes(Mantis ID-13160)
                   p_mcccode_groupid,
                   p_currcode_groupid, p_transcode_groupid, p_rules,
                   p_preauth_date, v_gl_upd_flag, p_stan,
                   p_inst_code, v_fee_code,
                   nvl(v_fee_amt,0), nvl(v_servicetax_amount,0),nvl(v_cess_amount,0), --Formatted by Pankaj S. for logging changes(Mantis ID-13160)
                   v_dr_cr_flag, v_fee_cracct_no,
                   v_fee_dracct_no, v_st_calc_flag,
                   v_cess_calc_flag, v_st_cracct_no,
                   v_st_dracct_no, v_cess_cracct_no,
                   v_cess_dracct_no, v_encr_pan,
                   NULL, v_proxunumber, p_rvsl_code,
                   v_acct_number, v_acct_balance, p_ledger_bal,
                   v_resp_cde, v_applpan_cardstat, v_feeattach_type,
                   p_merchant_name, p_merchant_city, p_atmname_loc,
                   p_addl_amnt, p_networkid_switch, p_networkid_acquirer,
                   p_network_setl_date, v_mcc_verify_flag, p_merchant_zip,
                   NVL (p_cvv_verificationtype, 'N'), v_err_msg, v_fee_plan,
                   p_orgnl_business_date,p_orgnl_business_time,p_orgnl_stan,
                   p_international_ind,  --Added by Pankaj S. for Mantis ID 13024
                   --Sn added by Pankaj S. for logging changes(Mantis ID-13160)
                   v_acct_type,v_timestamp
                   --En added by Pankaj S. for logging changes(Mantis ID-13160)
                   ,P_MERCHANT_ID, V_ERR_MSG, --Added for error msg need to display in CSR(declined by rule)
                   DECODE(p_surchrg_ind,'2',NULL,p_surchrg_ind) --Added for VMS-5856
                  );

      p_capture_date := v_business_date;
      p_auth_id := v_auth_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code := '69';
         p_resp_id   := '69'; --Added for VMS-8018
         p_resp_msg :=
               'Problem while inserting data into transaction log  '
            || SUBSTR (SQLERRM, 1, 300);
   END;
--En create a entry in txn log
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code := '69';
      p_resp_id   := '69'; --Added for VMS-8018
      p_resp_msg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/