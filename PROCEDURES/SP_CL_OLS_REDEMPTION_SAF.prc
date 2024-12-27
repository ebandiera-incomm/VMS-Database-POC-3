create or replace PROCEDURE        VMSCMS.SP_CL_OLS_REDEMPTION_SAF (
   p_inst_code            IN       NUMBER,
   p_msg                  IN       VARCHAR2,
   p_rrn                           VARCHAR2,
   p_delivery_channel              VARCHAR2,
   p_term_id                       VARCHAR2,
   p_txn_code                      VARCHAR2,
   p_txn_mode                      VARCHAR2,
   p_tran_date                     VARCHAR2,
   p_tran_time                     VARCHAR2,
   p_card_no                       VARCHAR2,
   p_bank_code                     VARCHAR2,
   p_txn_amt                       NUMBER,
   p_merchant_name                 VARCHAR2,
   p_merchant_city                 VARCHAR2,
   p_mcc_code                      VARCHAR2,
   p_curr_code                     VARCHAR2,
   p_prod_id                       VARCHAR2,
   p_catg_id                       VARCHAR2,
   p_tip_amt                       VARCHAR2,
   p_decline_ruleid                VARCHAR2,
   p_atmname_loc                   VARCHAR2,
   p_mcccode_groupid               VARCHAR2,
   p_currcode_groupid              VARCHAR2,
   p_transcode_groupid             VARCHAR2,
   p_rules                         VARCHAR2,
   p_preauth_date                  DATE,
   p_consodium_code       IN       VARCHAR2,
   p_partner_code         IN       VARCHAR2,
   p_expry_date           IN       VARCHAR2,
   p_stan                 IN       VARCHAR2,
   p_mbr_numb             IN       VARCHAR2,
   p_preauth_expperiod    IN       VARCHAR2,
   p_preauth_seqno        IN       VARCHAR2,
   p_rvsl_code            IN       NUMBER,
   p_pos_verfication      IN       VARCHAR2,                  --Added by Deepa
   p_international_ind    IN       VARCHAR2,
   p_addl_amnt            IN       VARCHAR2,
   -- Added for OLS additional amount Changes
   p_networkid_switch     IN       VARCHAR2,
   --Added on 20130626 for the Mantis ID 11344
   p_networkid_acquirer   IN       VARCHAR2,
   -- Added on 20130626 for the Mantis ID 11344
   p_network_setl_date    IN       VARCHAR2,
   --Added on 20130626 for the Mantis ID 11123
   p_merchant_zip         IN       VARCHAR2,  --Added by Pankaj S. for Mantis ID 11540
   p_cvv_verificationtype IN       VARCHAR2, --Added on 17.07.2013 for the Mantis ID 11611
   P_PULSE_TRANSACTIONID        IN       VARCHAR2,--Added for MVHOST 926
   P_VISA_TRANSACTIONID          IN       VARCHAR2,--Added for MVHOST 926
   P_MC_TRACEID                 IN       VARCHAR2,--Added for MVHOST 926
   P_CARDVERIFICATION_RESULT      IN       VARCHAR2,--Added for MVHOST 926
   P_ADDRVERIFY_FLAG    IN VARCHAR2,
   P_ZIP_CODE           IN VARCHAR2,
   p_req_resp_code    IN NUMBER,--Added for 15197
   p_auth_id              OUT      VARCHAR2,
   p_resp_code            OUT      VARCHAR2,
   p_resp_msg             OUT      VARCHAR2,
   p_ledger_bal           OUT      VARCHAR2,
   p_capture_date         OUT      DATE,
   p_iso_respcde          OUT      VARCHAR2  --Added on 17.07.2013 for the Mantis ID 11612
   ,P_ADDR_VERFY_RESPONSE  out VARCHAR2-- added for MVHOST-926
   ,P_MERCHANT_ID IN       VARCHAR2       DEFAULT NULL
   ,P_MERCHANT_CNTRYCODE IN       VARCHAR2 DEFAULT NULL
    ,P_cust_addr      IN VARCHAR2   DEFAULT NULL
	 ,P_acqInstAlphaCntrycode_in IN       VARCHAR2 DEFAULT NULL
     ,p_resp_id                  OUT      VARCHAR2 --Added for sending to FSS (VMS-8018)
)
IS
/*************************************************
     * Created Date     : 21-dec-2012
     * Created By       : Trivikram
     * PURPOSE          : Redemption for use case id CL-OLS-001
     * modified by      : B.Besky
     * modified Date    : 12-MAR-13
     * modified reason  : Modified for defect id 10576
     * Reviewer         : Chandan
     * Reviewed Date    : 12-MAR-13
     * Build Number     : CMS_3_5_1_RIC0004_B0001

     * Modified By      : MageshKumar.S
     * Modified Date    : 10-May-2013
     * Modified Reason  : OLS DE54 additional amount changes
     * Reviewer         : Dhiraj
     * Reviewed Date    : 16-May-2013
     * Build Number     : RI0024.1.1_B0001


     * Modified by      : Deepa T
     * Modified for     : Mantis ID 11344,11123
     * Modified Reason  : Log the AcquirerNetworkID received in tag 005 and TermFIID received in tag 020 ,
                          Logging of network settlement date for OLS transactions
     * Modified Date    : 26-Jun-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 27-06-2013
     * Build Number     : RI0024.2_B0009

     * Modified by       : Pankaj S.
     * Modified for      : Mantis ID 0011446
     * Modified Reason   : Medagate : to update PERMRULE_VERIFY_FLAG for SAF advices (failure transactions)
     * Modified Date     : 10_July_2013
     * Reviewer          : Dhiraj
     * Reviewed Date     :
     * Build Number      : RI0024.3_B0003

     * Modified by       : Pankaj S.
     * Modified for      : Mantis ID 0011540
     * Modified Reason   : Merchant related information (like name, city & state) logging
     * Modified Date     : 10_July_2013
     * Reviewer          : Dhiraj
     * Reviewed Date     :
     * Build Number      : RI0024.3_B0003

     * Modified by      : Sachin P.
     * Modified for     : Mantis ID -11611,11612
     * Modified Reason  : 11611-Input parameters needs to be included for the CVV verification
                          We are doing and it needs to be logged in transactionlog
                          11612-Output parameter needs to be included to return the cms_iso_respcde of cms_response_mast
     * Modified Date    : 17-Jul-2013
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     : RI0024.3_B0005

     * Modified by      : Sagar M.
     * Modified for     : MVHOST-500
     * Modified Reason  : To check message type in case of Duplicate RRN check
                          and reject if same RRN repeats with 1220,1221
     * Modified Date    : 26-Jun-2013
     * Reviewer         : Dhiarj
     * Reviewed Date    :
     * Build Number     : RI0024.3.1_B0001

     * Modified by      : Sagar M.
     * Modified for     : 0012198
     * Modified Reason  : To reject duplicate STAN transaction
     * Modified Date    : 29-Aug-2013
     * Reviewer         : Dhiarj
     * Reviewed Date    : 29-Aug-2013
     * Build Number     : RI0024.3.5_B0001


     * Modified by      : Siva Kumar M
     * Modified for     : LYFEHOST-74
     * Modified Reason  : Fee Based on Network
     * Modified Date    : 03.10.2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-Sep-2013
     * Build Number     : RI0024.5_B0001

     * Modified by      : Siva Kumar M
     * Modified for     : LYFEHOST-74
     * Modified Reason  : Fee Based on Network
     * Modified Date    : 03.10.2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-Sep-2013
     * Build Number     : RI0024.5_B0001

     * Modified by      : Sachin P
     * Modified for     : 12840
     * Modified Reason  : In OLS for Pre-Auth Completion Force Post Txn -Validating the Statement
                          Log with Account Balance instead of Ledger Balance
     * Modified Date    : 29.Oct.2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 29.Oct.2013
     * Build Number     : RI0024.6_B0004

     * Modified by       : Pankaj S.
     * Modified for      : Mantis ID 13025,13024
     * Modified Reason   : To comment expiry date check & log international ind in txnlog table
     * Modified Date     : 18_Nov_2013
     * Reviewer          : Dhiraj
     * Reviewed Date     : 18_Nov_2013
     * Build Number      : RI0024.3.11_B0004

     * Modified by       : RAVI N
     * Modified for      : MVCSD-4471
     * Modified Reason   : [in statementlog narration fee entry logging as fee description at narration]
     * Modified Date     : 05/02/14
     * Reviewer          : Dhiraj
     * Build Number      : RI0027.1_B0001

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
     * Reviewed Date     : 10-Mar-2014
     * Build Number      : RI0027.2_B0002

     * Modified by       : Dhinakaran B
     * Modified for      : VISA Certtification Changes integration in 2.2.2
     * Modified Date     : 01-JUL-2014
     * Build Number      : RI0027.2.2_B0001

     * Modified by       : Dhinakaran B
     * Modified for      : MANTIS ID-13642
     * Modified Date     : 09-JUL-2014
     * Reviewer          : Spankaj
     * Reviewed Date     : RI0027.3_B0003

     * Modified by       : MageshKumar S.
     * Modified Date     : 25-July-14
     * Modified For      : FWR-48
     * Modified reason   : GL Mapping removal changes
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3.1_B0001

     * Modified Date    : 29-SEP-2014
       * Modified By      : Abdul Hameed M.A
       * Modified for     : FWR 70
       * Reviewer        :  spankaj
       * Release Number   : RI0027.4_B0002

     * Modified Date    : 30-DEC-2014
     * Modified By      : Dhinakaran B
     * Modified for     : MVHOST-1080/To Log the Merchant id & CountryCode
     * Reviewer         :
     * Reviewed Date    :
     * Release Number   :

     * Modified by      : MAGESHKUMAR S.
     * Modified Date    : 03-FEB-2015
     * Modified For     : 2.4.2.4.1 & 2.4.3.1 integration
     * Reviewer         : PANKAJ S.
     * Build Number     : RI0027.5_B0006

     * Modified By      : MageshKumar S
     * Modified Date    : 11-FEB-2015
     * Modified for     : INSTCODE REMOVAL(2.4.2.4.2 & 2.4.3.1 integration)
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0007

      * Modified By      : Abdul Hameed M.A
     * Modified Date    : 11-FEB-2015
     * Modified for     : OLS AVS Address check
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0007

      * Modified By      :  Abdul Hameed M.A
     * Modified For     :  OLS AVS CHANGES
     * Modified Date    :  23-Apr-2015
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.5.2_B0001

    * Modified by      : Ramesh A
    * Modified for     : FSS-3610
    * Modified Date    : 31-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOST_3.1_B0008

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

     * Modified Date    : 02-Sep-2016
     * Modified By      : Sivakaminathan
     * Modified for     : MVHOST-1344
     * Reviewer         : Saravanakumar/Spankaj
     * Release Number   : VMSGPRHOSTCSD4.9_B0001

     * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07
		 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07
     * Modified By      : MageshKumar S
     * Modified Date    : 18/07/2017
     * Purpose          : FSS-5157
     * Reviewer         : Saravanan/Pankaj S.
     * Release Number   : VMSGPRHOST17.07

    * Modified By      : Vini Pushkaran
    * Modified Date    : 25/10/2017
    * Purpose          : FSS-5303
    * Reviewer         : Saravanakumar A
    * Release Number   : VMSGPRHOST17.10_B0004

       * Modified by       :Vini
       * Modified Date    : 10-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12.1

     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01

     * Modified By      : DHINAKARAN B
     * Modified Date    : 15-NOV-2018
     * Purpose          : VMS-619 (RULE)
     * Reviewer         : SARAVANAKMAR A
     * Release Number   : R08

     * Modified By      : Areshka A.
     * Modified Date    : 03-Nov-2023
     * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
     * Reviewer         : 
     * Release Number   : 

*************************************************/
   v_err_msg               VARCHAR2 (900)                             := 'OK';
   v_acct_balance          NUMBER;
   v_ledger_bal            NUMBER;
   v_tran_amt              NUMBER;
   v_auth_id               transactionlog.auth_id%TYPE;
   v_total_amt             NUMBER;
   v_tran_date             DATE;
   v_func_code             cms_func_mast.cfm_func_code%TYPE;
   v_prod_code             cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype          cms_prod_cattype.cpc_card_type%TYPE;
   v_fee_amt               NUMBER;
   v_total_fee             NUMBER;
   v_upd_amt               NUMBER;
   v_upd_ledger_amt        NUMBER;
   v_narration             VARCHAR2 (300);
   v_trans_desc            VARCHAR2 (50);
   v_fee_opening_bal       NUMBER;
   v_resp_cde              VARCHAR2 (3);
   v_expry_date            DATE;
   v_dr_cr_flag            VARCHAR2 (2);
   v_output_type           VARCHAR2 (2);
   v_applpan_cardstat      cms_appl_pan.cap_card_stat%TYPE;
   v_atmonline_limit       cms_appl_pan.cap_atm_online_limit%TYPE;
   v_posonline_limit       cms_appl_pan.cap_atm_offline_limit%TYPE;
   v_gl_upd_flag           transactionlog.gl_upd_flag%TYPE;
   v_gl_err_msg            VARCHAR2 (500);
   v_savepoint             NUMBER                                        := 0;
   v_tran_fee              NUMBER;
   v_error                 VARCHAR2 (500);
   v_business_date_tran    DATE;
   v_business_time         VARCHAR2 (5);
   v_cutoff_time           VARCHAR2 (5);
   v_card_curr             VARCHAR2 (5);
   v_fee_code              cms_fee_mast.cfm_fee_code%TYPE;
   v_fee_crgl_catg         cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_fee_crgl_code         cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_fee_crsubgl_code      cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_fee_cracct_no         cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_drgl_catg         cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_fee_drgl_code         cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_fee_drsubgl_code      cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_fee_dracct_no         cms_prodcattype_fees.cpf_dracct_no%TYPE;
   --st AND cess
   v_servicetax_percent    cms_inst_param.cip_param_value%TYPE;
   v_cess_percent          cms_inst_param.cip_param_value%TYPE;
   v_servicetax_amount     NUMBER;
   v_cess_amount           NUMBER;
   v_st_calc_flag          cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_cess_calc_flag        cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_st_cracct_no          cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_st_dracct_no          cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_cess_cracct_no        cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_cess_dracct_no        cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   --
   v_waiv_percnt           cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_err_waiv              VARCHAR2 (300);
   v_log_actual_fee        NUMBER;
   v_log_waiver_amt        NUMBER;
   v_auth_savepoint        NUMBER                                   DEFAULT 0;
   v_actual_exprydate      DATE;
   v_business_date         DATE;
   v_txn_type              NUMBER (1);
   v_mini_totrec           NUMBER (2);
   v_ministmt_errmsg       VARCHAR2 (500);
   v_ministmt_output       VARCHAR2 (900);
   exp_reject_record       EXCEPTION;
   v_atm_usageamnt         cms_translimit_check.ctc_atmusage_amt%TYPE;
   v_pos_usageamnt         cms_translimit_check.ctc_posusage_amt%TYPE;
   v_atm_usagelimit        cms_translimit_check.ctc_atmusage_limit%TYPE;
   v_pos_usagelimit        cms_translimit_check.ctc_posusage_limit%TYPE;
   v_preauth_usage_limit   NUMBER;
   v_card_acct_no          VARCHAR2 (20);
   v_hold_amount           NUMBER;
   v_hash_pan              cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan              cms_appl_pan.cap_pan_code_encr%TYPE;
   v_rrn_count             NUMBER;
   v_tran_type             VARCHAR2 (2);
   v_date                  DATE;
   v_time                  VARCHAR2 (10);
   v_max_card_bal          NUMBER;
   v_curr_date             DATE;
   v_saf_txn_count         NUMBER;
   v_proxunumber           cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number           cms_appl_pan.cap_acct_no%TYPE;
   --Added by Deepa On June 19 2012 for Fees Changes
   v_feeamnt_type          cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_per_fees              cms_fee_mast.cfm_per_fees%TYPE;
   v_flat_fees             cms_fee_mast.cfm_fee_amt%TYPE;
   v_clawback              cms_fee_mast.cfm_clawback_flag%TYPE;
   v_fee_plan              cms_fee_feeplan.cff_fee_plan%TYPE;
   v_freetxn_exceed        VARCHAR2 (1);
   -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
   v_duration              VARCHAR2 (20);
   -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
   v_feeattach_type        VARCHAR2 (2);
-- Added by Trivikram on 5th Sept 2012
   v_cms_iso_respcde       cms_response_mast.cms_iso_respcde%TYPE;
   --Added  by Besky on 11/03/13 for defect id 10576
   --Sn Added by Pankaj S. for Mantis ID 11446
   v_hold_days             cms_txncode_rule.ctr_hold_days%TYPE;
   v_mcc_verify_flag       VARCHAR2 (1);
   v_preauth_flag          NUMBER;
--En Added by Pankaj S. for Mantis ID 11446

   V_STAN_COUNT                  NUMBER; -- Added for Duplicate Stan check 0012198

    V_NETWORKIDCOUNT  number default 0; -- lyfe changes.
   v_fee_desc              cms_fee_mast.cfm_fee_desc%TYPE;--Added on 05/02/14 for regarding MVCSD-4471

   V_CAP_CUST_CODE    CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
  v_txn_nonnumeric_chk    VARCHAR2 (2);
  v_cust_nonnumeric_chk   VARCHAR2 (2);
  V_ADDRVRIFY_FLAG        CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_CHECK%TYPE;
  V_ENCRYPT_ENABLE        CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  V_ADDRVERIFY_RESP       CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_RESPONSE%TYPE;
  V_ZIP_CODE                  cms_addr_mast.cam_pin_code%type;
  v_first3_custzip         cms_addr_mast.cam_pin_code%type;
  v_inputzip_length        number(3);
  v_numeric_zip            cms_addr_mast.cam_pin_code%type;
  v_removespace_txn       VARCHAR2 (10);
  v_removespace_cust      VARCHAR2 (10);
    V_CAM_TYPE_CODE   cms_acct_mast.cam_type_code%type;  --Added for 15197
    v_timestamp timestamp; --Added for 15197
    v_zip_code_trimmed VARCHAR2(10); --Added for 15165

    --SN Added for FWR 70
       v_removespacenum_txn  VARCHAR2 (10);
V_REMOVESPACENUM_CUST   VARCHAR2 (10);
V_REMOVESPACECHAR_TXN   varchar2 (10);
V_REMOVESPACECHAR_CUST   VARCHAR2 (10);
   -- EN Added for FWR 70

    V_ADDR_ONE CMS_ADDR_MAST.CAM_ADD_ONE%type;
  V_ADDR_TWO CMS_ADDR_MAST.CAM_ADD_TWO%type;
  V_REMOVESPACE_ADDRCUST     VARCHAR2(100);
  V_REMOVESPACE_ADDRTXN      VARCHAR2(20);
  V_REMOVESPACECHAR_ADDRCUST VARCHAR2(100);
  V_REMOVESPACECHAR_ADDRTXN  VARCHAR2(20);
  V_ADDR_VERFY               number;
  V_REMOVESPACECHAR_ADDRONECUST   VARCHAR2(100);
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991

BEGIN
   SAVEPOINT v_auth_savepoint;
   v_resp_cde := '1';
   -- P_ERR_MSG  := 'OK';
   p_resp_msg := 'OK';

   BEGIN
      --SN CREATE HASH PAN
      BEGIN
         v_hash_pan := gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
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
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN create encr pan

      --Sn generate auth id
      BEGIN
         -- SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

         --  SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';                            -- Server Declined
            RAISE exp_reject_record;
      END;

      --En generate auth id

      --En check txn currency
      BEGIN
         v_date := TO_DATE (SUBSTR (TRIM (p_tran_date), 1, 8), 'yyyymmdd');
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '45';                    -- Server Declined -220509
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
            v_resp_cde := '32';                    -- Server Declined -220509
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
                ctm_tran_type
                ,ctm_tran_desc --Added for 15197
           INTO v_dr_cr_flag, v_output_type,
                v_txn_type,
                v_tran_type
                ,v_trans_desc --Added for 15197
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '12';                      --Ineligible Transaction
            v_err_msg :=
                  'Transflag  not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';                      --Ineligible Transaction
            v_err_msg :=
                  'Error while selecting CMS_TRANSACTION_MAST '
               || p_txn_code
               || p_delivery_channel
               || SQLERRM;
            RAISE exp_reject_record;
      END;

      --En find debit and credit flag
      -- Sn Added for 15197
       IF p_req_resp_code >= 100 and P_TXN_CODE='16'
      THEN
         V_TRAN_AMT := P_TXN_AMT;
     v_resp_cde := '1';
         v_err_msg := 'Decline Notification transaction';
         RAISE exp_reject_record;
      END IF;
--En Added for 15197
      /*
      -----------------------------------------
      --SN: Added for Duplicate STAN check 0012198
      -----------------------------------------

      BEGIN

        SELECT COUNT(1)
         INTO V_STAN_COUNT
         FROM TRANSACTIONLOG
        WHERE INSTCODE = P_INST_CODE
        AND   CUSTOMER_CARD_NO  = V_HASH_PAN
        AND   BUSINESS_DATE = P_TRAN_DATE
        AND   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND   SYSTEM_TRACE_AUDIT_NO = P_STAN;

        IF V_STAN_COUNT > 0 THEN

         V_RESP_CDE := '191';
         V_ERR_MSG   := 'Duplicate Stan from the Treminal' || P_TERM_ID || 'on' ||
                    P_TRAN_DATE;
         RAISE EXP_REJECT_RECORD;

        END IF;


      EXCEPTION WHEN EXP_REJECT_RECORD
      THEN
            RAISE EXP_REJECT_RECORD;

      WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while checking duplicate STAN ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;

      END;

      -----------------------------------------
      --SN: Added for Duplicate STAN check 0012198
      -----------------------------------------
      */

      --Sn Duplicate RRN Check
      BEGIN
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS.transactionlog
          WHERE terminal_id = p_term_id
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel
            AND MSGTYPE IN ('1200','1201','1220','1221')               --Added for MVHOST-500
            AND txn_code =   p_txn_code   --Added for MVHOST-500 on 02.08.2013
            AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
	else
		SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.transactionlog_HIST
          WHERE terminal_id = p_term_id
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND delivery_channel = p_delivery_channel
            AND MSGTYPE IN ('1200','1201','1220','1221')               --Added for MVHOST-500
            AND txn_code =   p_txn_code   --Added for MVHOST-500 on 02.08.2013
            AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
END IF;	

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

      --En Duplicate RRN Check

      --Sn SAF  txn Check
      IF p_msg = '1221'
      THEN
-- Modified msgtype 9220 and 9221 with 1220 and 1221  by Trivikram on 14/Nov/2012 ,
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
         SELECT COUNT (*)
           INTO v_saf_txn_count
           FROM VMSCMS.transactionlog
          WHERE rrn = p_rrn
            AND business_date = p_tran_date
            AND customer_card_no = v_hash_pan                      --P_card_no
           -- AND instcode = p_inst_code --For Instcode removal of 2.4.2.4.2 release
            AND terminal_id = p_term_id
            AND response_code = '00'
            AND msgtype = '1220'
            AND txn_code = p_txn_code;--Added for MVHOST-500 on 02.08.2013
else
		SELECT COUNT (*)
           INTO v_saf_txn_count
           FROM VMSCMS_HISTORY.transactionlog_HIST
          WHERE rrn = p_rrn
            AND business_date = p_tran_date
            AND customer_card_no = v_hash_pan                      --P_card_no
           -- AND instcode = p_inst_code --For Instcode removal of 2.4.2.4.2 release
            AND terminal_id = p_term_id
            AND response_code = '00'
            AND msgtype = '1220'
            AND txn_code = p_txn_code;--Added for MVHOST-500 on 02.08.2013
END IF;			

         IF v_saf_txn_count > 0
         THEN
            v_resp_cde := '38';
            v_err_msg :=
                  'Successful SAF Transaction has already done'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
         END IF;
      END IF;

      --En SAF  txn Check

      --Sn find service tax
      BEGIN
         SELECT cip_param_value
           INTO v_servicetax_percent
           FROM cms_inst_param
          WHERE cip_param_key = 'SERVICETAX' AND cip_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Service Tax is  not defined in the system';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting service tax from system ';
            RAISE exp_reject_record;
      END;

      --En find service tax

      --Sn find cess
      BEGIN
         SELECT cip_param_value
           INTO v_cess_percent
           FROM cms_inst_param
          WHERE cip_param_key = 'CESS' AND cip_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Cess is not defined in the system';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting cess from system ';
            RAISE exp_reject_record;
      END;

      --En find cess

      ---Sn find cutoff time
      BEGIN
         SELECT cip_param_value
           INTO v_cutoff_time
           FROM cms_inst_param
          WHERE cip_param_key = 'CUTOFF' AND cip_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_cutoff_time := 0;
            v_resp_cde := '21';
            v_err_msg := 'Cutoff time is not defined in the system';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting cutoff  dtl  from system ';
            RAISE exp_reject_record;
      END;

      ---En find cutoff time





      --Sn find card detail
      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_expry_date,
                cap_card_stat, cap_atm_online_limit, cap_pos_online_limit,
                cap_proxy_number, cap_acct_no
                ,CAP_CUST_CODE
           INTO v_prod_code, v_prod_cattype, v_expry_date,
                v_applpan_cardstat, v_atmonline_limit, v_atmonline_limit,
                v_proxunumber, v_acct_number
                ,V_CAP_CUST_CODE
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan;
         -- AND cap_inst_code = p_inst_code; --For Instcode removal of 2.4.2.4.2 release
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

      --En find card detail
        --Sn find the tran amt
      IF ((v_tran_type = 'F') OR (p_msg = '0100'))
      THEN
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
                  v_resp_cde := '69';              -- Server Declined -220509
                  v_err_msg :=
                        'Error from currency conversion '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSE
            -- If transaction Amount is zero - Invalid Amount -220509
            v_resp_cde := '43';
            v_err_msg := 'INVALID AMOUNT';
            RAISE exp_reject_record;
         END IF;
      END IF;
      --En find the tran amt

      --Sn Commented by Pankaj S. on 18_Nov_2013 for Mantis ID 13025
     /* --- st Expiry date validation for ols changes
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
      --En Commented by Pankaj S. on 18_Nov_2013 for Mantis ID 13025

     BEGIN

     SELECT  CPC_ADDR_VERIFICATION_CHECK, CPC_ENCRYPT_ENABLE , NVL(CPC_ADDR_VERIFICATION_RESPONSE, 'U')
       INTO  V_ADDRVRIFY_FLAG, V_ENCRYPT_ENABLE , V_ADDRVERIFY_RESP
       FROM CMS_PROD_CATTYPE
      WHERE CPC_INST_CODE = P_INST_CODE AND
	        CPC_PROD_CODE = V_PROD_CODE AND
            CPC_CARD_TYPE = V_PROD_CATTYPE;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN

       V_ADDRVRIFY_FLAG    := 'Y';

     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while seelcting BIN level Configuration' || SUBSTR (SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;

   v_zip_code_trimmed:=TRIM(P_ZIP_CODE); --Added for 15165
   --St: Added for OLS  changes( AVS & ZIP validation changes) on 11/05/2013
     IF V_ADDRVRIFY_FLAG = 'Y' AND P_ADDRVERIFY_FLAG in('2','3') then

       if P_ZIP_CODE is null then

               V_RESP_CDE := '105';
               V_ERR_MSG  := 'Required Property Not Present : ZIP';
               RAISE EXP_REJECT_RECORD;

            ELSIF trim(P_ZIP_CODE) is null then   --tag present but value empty or space

               P_ADDR_VERFY_RESPONSE := 'U';

      ELSE

           BEGIN

               SELECT decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(CAM_PIN_CODE),CAM_PIN_CODE),
                 decode(V_ENCRYPT_ENABLE,'Y',trim(fn_dmaps_main(cam_add_one)),trim(cam_add_one)),
                 decode(v_encrypt_enable,'Y',trim(fn_dmaps_main(cam_add_two)),trim(cam_add_two))
          INTO V_ZIP_CODE,
            v_addr_one,
            v_addr_two
                FROM CMS_ADDR_MAST
                WHERE CAM_CUST_CODE = V_CAP_CUST_CODE
                AND CAM_ADDR_FLAG = 'P';

                   v_first3_custzip := SUBSTR(V_ZIP_CODE,1,3);

             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   V_RESP_CDE := '21';
                   V_ERR_MSG  := 'No data found in CMS_ADDR_MAST ' || V_HASH_PAN;
                   RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
                   V_RESP_CDE := '21';
                   V_ERR_MSG  := 'Error while seelcting CMS_ADDR_MAST ' ||SUBSTR(SQLERRM, 1, 200);
                   RAISE EXP_REJECT_RECORD;
             END;

             SELECT REGEXP_instr(p_zip_code,'([A-Z,a-z])') into v_txn_nonnumeric_chk
             FROM dual;

             SELECT REGEXP_instr(V_ZIP_CODE,'([A-Z,a-z])') into v_cust_nonnumeric_chk
             FROM dual;

         if  v_txn_nonnumeric_chk = '0' and v_cust_nonnumeric_chk = '0' then -- It Means txn and cust zip code is numeric

                    --if  p_zip_code = v_zip_code then -- Commented on 20/12/13 for FSS-1388
               --  IF SUBSTR (p_zip_code, 1, 5) = SUBSTR (v_zip_code, 1, 5) then -- Added on 20/12/13 for FSS-1388
                --Modified for 15165
                    IF SUBSTR (v_zip_code_trimmed, 1, 5) = SUBSTR (v_zip_code, 1, 5) then

                      P_ADDR_VERFY_RESPONSE := 'W';
                 else
                      P_ADDR_VERFY_RESPONSE := 'N';
                 end if;


        elsif v_txn_nonnumeric_chk <> '0' and v_cust_nonnumeric_chk = '0' then -- It Means txn zip code is aplhanumeric and cust zip code is numeric

           --     if  p_zip_code = v_zip_code then
              IF v_zip_code_trimmed=v_zip_code THEN  --Modified for 15165

                     P_ADDR_VERFY_RESPONSE := 'W';
                else

                      P_ADDR_VERFY_RESPONSE := 'N';
                end if;

        elsif v_txn_nonnumeric_chk = '0' and v_cust_nonnumeric_chk <> '0' then -- It Means txn zip code is numeric and cust zip code is alphanumeric

                   SELECT REGEXP_REPLACE(v_zip_code,'([A-Z ,a-z ])', '') into v_numeric_zip FROM dual;

             --  IF  p_zip_code = v_numeric_zip THEN
               IF v_zip_code_trimmed=v_numeric_zip THEN  --Modified for 15165

                   P_ADDR_VERFY_RESPONSE := 'W';
               else
                   P_ADDR_VERFY_RESPONSE := 'N';

               end if;

        elsif v_txn_nonnumeric_chk <> '0' and v_cust_nonnumeric_chk <> '0' then -- It Means txn zip code and cust zip code is alphanumeric

                  v_inputzip_length := length(p_zip_code);

                 if v_inputzip_length = length(v_zip_code) then  -- both txn and cust zip length is equal

                   --   if  p_zip_code = v_zip_code then
                         IF v_zip_code_trimmed=v_zip_code THEN  --Modified for 15165

                                P_ADDR_VERFY_RESPONSE := 'W';
                      else
                                 P_ADDR_VERFY_RESPONSE := 'N';

                      end if;

                 else

                         SELECT REGEXP_REPLACE(p_zip_code,'([ ])', '') into v_removespace_txn from dual;

                         SELECT REGEXP_REPLACE(v_zip_code,'([ ])', '') into v_removespace_cust from dual;

                         if v_removespace_txn =  v_removespace_cust then

                                   P_ADDR_VERFY_RESPONSE := 'W';

                         --elsif v_inputzip_length >=3 then --Commented for defect : 13297 on 26/12/13
                         elsif length(v_removespace_txn) >=3 then --Added for defect : 13297 on 26/12/13

                         --if substr(p_zip_code,1,3) = v_first3_custzip then  --Commented for defect : 13297 on 26/12/13
                            if substr(v_removespace_txn,1,3) = substr(v_removespace_cust,1,3) then  --Added for defect : 13297 on 26/12/13

                             P_ADDR_VERFY_RESPONSE := 'W';
                                  --SN dded for FWR 70
                            ELSIF v_inputzip_length >= 6
                        THEN                         --Added for defect : 13297 on 26/12/13

                         select REGEXP_REPLACE (P_ZIP_CODE, '([0-9 ])', '')
                          INTO v_removespacenum_txn
                          FROM DUAL;

                        select REGEXP_REPLACE (V_ZIP_CODE, '([0-9 ])', '')
                          into V_REMOVESPACENUM_CUST
                          FROM DUAL;

                           select REGEXP_REPLACE (P_ZIP_CODE, '([a-zA-Z ])', '')
                          INTO v_removespacechar_txn
                          FROM DUAL;

                        select REGEXP_REPLACE (V_ZIP_CODE, '([a-zA-Z ])', '')
                          into V_REMOVESPACECHAR_CUST
                          FROM DUAL;
                            --if substr(p_zip_code,1,3) = v_first3_custzip then  --Commented for defect : 13297 on 26/12/13
                            IF SUBSTR (v_removespacenum_txn, 1, 3) =
                                    SUBSTR (V_REMOVESPACENUM_CUST, 1, 3)
                            then                     --Added for defect : 13297 on 26/12/13
                                P_ADDR_VERFY_RESPONSE := 'W';
                            ELSIF  SUBSTR (V_REMOVESPACECHAR_TXN, 1, 3) =
                                    SUBSTR (V_REMOVESPACECHAR_CUST, 1, 3)
                                    then
                                    P_ADDR_VERFY_RESPONSE := 'W';
                            ELSE
                                P_ADDR_VERFY_RESPONSE := 'N';
                            end if;
                            --en --Added for FWR 70
                          else
                                  P_ADDR_VERFY_RESPONSE := 'N';

                          end if;


                         else  --Added for defect : 13296 on 26/12/13
                          P_ADDR_VERFY_RESPONSE := 'N'; --Added for defect : 13296 on 26/12/13

                          end if;
                     end if;
         else
             P_ADDR_VERFY_RESPONSE := 'N';
        end if;

       end if;

     ELSE

         IF P_ADDRVERIFY_FLAG in('2','3') THEN

           P_ADDR_VERFY_RESPONSE := V_ADDRVERIFY_RESP;

         ELSE

           P_ADDR_VERFY_RESPONSE := 'NA';

         END IF;

        END IF;

         select REGEXP_REPLACE (v_addr_one||v_addr_TWO,'[^[:digit:]]')
           INTO v_removespacechar_addrcust
          FROM DUAL;


        select REGEXP_REPLACE (V_ADDR_ONE,'[^[:digit:]]')
           into V_REMOVESPACECHAR_ADDRONECUST
          FROM DUAL;


        select REGEXP_REPLACE (P_CUST_ADDR,'[^[:digit:]]')
             INTO V_REMOVESPACECHAR_ADDRTXN
             from DUAL;

          SELECT REGEXP_REPLACE (P_CUST_ADDR, '([ ])', '')
           INTO V_REMOVESPACE_addrtxn
           from DUAL;

          SELECT REGEXP_REPLACE (v_addr_one||v_addr_TWO, '([ ])', '')
           INTO V_REMOVESPACE_addrcust
           from DUAL;
        IF V_ADDRVRIFY_FLAG = 'Y'  then
    if(P_ADDR_VERFY_RESPONSE  ='W') then

      if(V_REMOVESPACE_ADDRCUST is not null) then

     if(V_REMOVESPACE_ADDRCUST=SUBSTR(V_REMOVESPACE_ADDRTXN,1,length(V_REMOVESPACE_ADDRCUST))) then
     V_ADDR_VERFY:=1;
      elsif(V_REMOVESPACECHAR_ADDRCUST=V_REMOVESPACECHAR_ADDRTXN) then
        V_ADDR_VERFY:=1;
      ELSIF(V_REMOVESPACECHAR_ADDRONECUST=V_REMOVESPACECHAR_ADDRTXN) then
        V_ADDR_VERFY:=1;
        else
        V_ADDR_VERFY:=-1;
        end if;


        IF(V_ADDR_VERFY          =1) THEN
          P_ADDR_VERFY_RESPONSE := 'Y';
        ELSE
          P_ADDR_VERFY_RESPONSE := 'Z';
        END IF;
      ELSE
        P_ADDR_VERFY_RESPONSE := 'Z';
      end if;
    end if;

     if (UPPER (TRIM(p_networkid_switch)) = 'BANKNET' and P_ADDR_VERFY_RESPONSE = 'Y') then
          P_ADDR_VERFY_RESPONSE := 'Z';
      end if;
end if;
    /*  BEGIN
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
      END;*/

      --Sn Added by Pankaj S. for Mantis ID 11446
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
                                      NULL,                        --P_MERC_ID
                                      P_MERCHANT_CNTRYCODE,                  --P_COUNTRY_CODE,
                                      v_hold_amount,
                                      v_hold_days,
                                      v_resp_cde,
                                      v_err_msg,
                                      P_acqInstAlphaCntrycode_in
                                     );

            IF (v_resp_cde <> '1' OR TRIM (v_err_msg) <> 'OK')
            THEN
               IF p_msg IS NOT NULL AND p_msg IN ('1220', '1221')
               THEN
                  IF UPPER (v_err_msg) = 'INVALID MERCHANT CODE'
                  THEN
                     v_resp_cde := 1;
                     v_err_msg := 'OK';
                     v_mcc_verify_flag := 'N';
                  ELSE
                     RAISE exp_reject_record;
                  END IF;
               ELSE
                  RAISE exp_reject_record;
               END IF;
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
      --En Added by Pankaj S. for Mantis ID 11446

      --Sn - Commented for fwr-48

      --Sn find function code attached to txn code
    /*  BEGIN
         SELECT cfm_func_code
           INTO v_func_code
           FROM cms_func_mast
          WHERE cfm_txn_code = p_txn_code
            AND cfm_txn_mode = p_txn_mode
            AND cfm_delivery_channel = p_delivery_channel
            AND cfm_inst_code = p_inst_code;
      --TXN mode and delivery channel we need to attach
      --bkz txn code may be same for all type of channels
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '69';                      --Ineligible Transaction
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
      END; */

      --En find function code attached to txn code

      --En - Commented for fwr-48

      --Sn find prod code and card type and available balance for the card number
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no,cam_type_code
               INTO v_acct_balance, v_ledger_bal, v_card_acct_no,v_cam_type_code
               FROM cms_acct_mast
              WHERE cam_acct_no = v_acct_number
                      /* (SELECT cap_acct_no
                          FROM cms_appl_pan
                         WHERE cap_pan_code = v_hash_pan
                           AND cap_mbr_numb = p_mbr_numb
                           AND cap_inst_code = p_inst_code)*/ --For Instcode removal of 2.4.2.4.2 release
                AND cam_inst_code = p_inst_code
                FOR UPDATE;                      -- Added for Concurrent Processsing Issue
                --FOR UPDATE NOWAIT;             -- Commented for Concurrent Processsing Issue

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';                      --Ineligible Transaction
            v_err_msg := 'Invalid Card ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Error while selecting data from card Master for card number '
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
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
            SELECT COUNT(1)
             INTO V_STAN_COUNT
             FROM VMSCMS.TRANSACTIONLOG
            WHERE --INSTCODE = P_INST_CODE AND   --For Instcode removal of 2.4.2.4.2 release
            CUSTOMER_CARD_NO  = V_HASH_PAN
            AND   BUSINESS_DATE = P_TRAN_DATE
            AND   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
            AND   ADD_INS_DATE BETWEEN TRUNC(SYSDATE-1)  AND SYSDATE
            AND   SYSTEM_TRACE_AUDIT_NO = P_STAN;
			else
			  SELECT COUNT(1)
             INTO V_STAN_COUNT
             FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST
            WHERE --INSTCODE = P_INST_CODE AND   --For Instcode removal of 2.4.2.4.2 release
            CUSTOMER_CARD_NO  = V_HASH_PAN
            AND   BUSINESS_DATE = P_TRAN_DATE
            AND   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
            AND   ADD_INS_DATE BETWEEN TRUNC(SYSDATE-1)  AND SYSDATE
            AND   SYSTEM_TRACE_AUDIT_NO = P_STAN;
			END IF;

            IF V_STAN_COUNT > 0 THEN

             V_RESP_CDE := '191';
             V_ERR_MSG   := 'Duplicate Stan from the Treminal' || P_TERM_ID || 'on' ||
                        P_TRAN_DATE;
             RAISE EXP_REJECT_RECORD;

            END IF;


          EXCEPTION WHEN EXP_REJECT_RECORD
          THEN
                RAISE EXP_REJECT_RECORD;

          WHEN OTHERS THEN

           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Error while checking duplicate STAN ' ||SUBSTR(SQLERRM,1,200);
           RAISE EXP_REJECT_RECORD;

          END;


          --Sn Duplicate RRN Check
          BEGIN
		  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
             SELECT COUNT (1)
               INTO v_rrn_count
               FROM VMSCMS.transactionlog
              WHERE terminal_id = p_term_id
                AND rrn = p_rrn
                AND business_date = p_tran_date
                AND delivery_channel = p_delivery_channel
                AND MSGTYPE IN ('1200','1201','1220','1221')
                AND txn_code =   p_txn_code
                AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
				else
				SELECT COUNT (1)
               INTO v_rrn_count
               FROM VMSCMS_HISTORY.transactionlog_HIST
              WHERE terminal_id = p_term_id
                AND rrn = p_rrn
                AND business_date = p_tran_date
                AND delivery_channel = p_delivery_channel
                AND MSGTYPE IN ('1200','1201','1220','1221')
                AND txn_code =   p_txn_code
                AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
				END IF;

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

          --En Duplicate RRN Check


          IF p_msg = '1221'
          THEN
		  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
             SELECT COUNT (*)
               INTO v_saf_txn_count
               FROM vmscms.transactionlog
              WHERE rrn = p_rrn
                AND business_date = p_tran_date
                AND customer_card_no = v_hash_pan
               -- AND instcode = p_inst_code --For Instcode removal of 2.4.2.4.2 release
                AND terminal_id = p_term_id
                AND response_code = '00'
                AND msgtype = '1220'
                AND txn_code = p_txn_code;
				else
				 SELECT COUNT (*)
               INTO v_saf_txn_count
               FROM VMSCMS_HISTORY.transactionlog_HIST
              WHERE rrn = p_rrn
                AND business_date = p_tran_date
                AND customer_card_no = v_hash_pan
               -- AND instcode = p_inst_code --For Instcode removal of 2.4.2.4.2 release
                AND terminal_id = p_term_id
                AND response_code = '00'
                AND msgtype = '1220'
                AND txn_code = p_txn_code;
				END IF;

             IF v_saf_txn_count > 0
             THEN
                v_resp_cde := '38';
                v_err_msg :=
                      'Successful SAF Transaction has already done'
                   || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
             END IF;
          END IF;


    ------------------------------------------------------
        --En Added for Concurrent Processsing Issue
    ------------------------------------------------------


    IF p_delivery_channel = '01' THEN
        BEGIN

          SELECT COUNT(*)
          INTO V_NETWORKIDCOUNT
          FROM CMS_PROD_CATTYPE prodCat,
          VMS_PRODCAT_NETWORKID_MAPPING MAPP
          WHERE prodCat.CPC_INST_CODE=MAPP.VPN_INST_CODE
          AND prodCat.CPC_INST_CODE=p_inst_code
          AND prodCat.CPC_NETWORKACQID_FLAG='Y'
          and prodCat.CPC_PROD_CODE=MAPP.VPN_PROD_CODE
          and upper(MAPP.VPN_NETWORK_ID)='VDBZ'
          AND PRODCAT.CPC_CARD_TYPE= V_PROD_CATTYPE
          AND prodCat.CPC_CARD_TYPE= MAPP.VPN_CARD_TYPE
          and MAPP.VPN_PROD_CODE=v_prod_code;

        EXCEPTION
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
            v_err_msg :=
                'Error while selecting product network id ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;

        END;

      END IF;

    IF V_NETWORKIDCOUNT <> 1 THEN

      --En Check PreAuth Completion txn
      BEGIN
         sp_tran_fees_cmsauth
                       (p_inst_code,
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
                        p_international_ind, --Added by Deepa for Fees Changes
                        p_pos_verfication,   --Added by Deepa for Fees Changes
                        v_resp_cde,          --Added by Deepa for Fees Changes
                        p_msg,               --Added by Deepa for Fees Changes
                        p_rvsl_code,
                        --Added by Deepa on June 25 2012 for Reversal txn Fee
                        p_mcc_code,
                        --Added by Trivikram on 05-Sep-2012 for merchant catg code
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
                        v_feeamnt_type,      --Added by Deepa for Fees Changes
                        v_clawback,          --Added by Deepa for Fees Changes
                        v_fee_plan,          --Added by Deepa for Fees Changes
                        v_per_fees,          --Added by Deepa for Fees Changes
                        v_flat_fees,         --Added by Deepa for Fees Changes
                        v_freetxn_exceed,
                        -- Added by Trivikram for logging fee of free transaction
                        v_duration,
                        -- Added by Trivikram for logging fee of free transaction
                        v_feeattach_type,  -- Added by Trivikram on Sep 05 2012
                        V_FEE_DESC  --Added on 05/02/14 for MVCSD-4471
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
    else
     v_fee_amt :=0;
      end if;
      --Sn calculate waiver on the fee
      BEGIN
         sp_calculate_waiver (p_inst_code,
                              p_card_no,
                              '000',
                              v_prod_code,
                              v_prod_cattype,
                              v_fee_code,
                              v_fee_plan, -- Added by Trivikram on 21/aug/2012
                              v_tran_date,
                              --Added Trivikam on Aug-23-2012 to calculate the waiver based on tran date
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

      --only used to log in log table

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

      --En find fees amount attached to func code, prod code and card type

      --Sn find total transaction    amount
      IF v_dr_cr_flag = 'CR'
      THEN
         v_total_amt := v_tran_amt - v_total_fee;
         v_upd_amt := v_acct_balance + v_total_amt;
         v_upd_ledger_amt := v_ledger_bal + v_total_amt;
      ELSIF v_dr_cr_flag = 'DR'
      THEN
         v_total_amt := v_tran_amt + v_total_fee;
         v_upd_amt := v_acct_balance - v_total_amt;
         v_upd_ledger_amt := v_ledger_bal - v_total_amt;
      ELSIF v_dr_cr_flag = 'NA'
      THEN
         IF p_txn_code = '11' AND p_msg = '0100'
         THEN
            v_total_amt := v_tran_amt + v_total_fee;
            v_upd_amt := v_acct_balance - v_total_amt;
            v_upd_ledger_amt := v_ledger_bal - v_total_amt;
         ELSE
            IF v_total_fee = 0
            THEN
               v_total_amt := 0;
            ELSE
               v_total_amt := v_total_fee;
            END IF;

            v_upd_amt := v_acct_balance - v_total_amt;
            v_upd_ledger_amt := v_ledger_bal - v_total_amt;
         END IF;
      ELSE
         v_resp_cde := '12';                         --Ineligible Transaction
         v_err_msg := 'Invalid transflag    txn code ' || p_txn_code;
         RAISE exp_reject_record;
      END IF;

      --Sn create gl entries and acct update
      BEGIN
         sp_upd_transaction_accnt_auth
                          (p_inst_code,
                           v_tran_date,
                           v_prod_code,
                           v_prod_cattype,
                           v_tran_amt,
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
                           ---Card's account no has been passed instead of card no(For Debit card acct_no will be different)
                           v_hold_amount, --For PreAuth Completion transaction
                           p_msg,
                           v_resp_cde,
                           v_err_msg
                          );

         IF (v_resp_cde <> '1' OR v_err_msg <> 'OK')
         THEN
            v_resp_cde := '21';
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
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En create gl entries and acct update
      --Sn find narration
      BEGIN
         SELECT ctm_tran_desc
           INTO v_trans_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;

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

		 IF TRIM (p_merchant_city) IS NOT NULL
         THEN
            v_narration := v_narration || p_merchant_city || '/';
         END IF;

         IF TRIM (p_tran_date) IS NOT NULL
         THEN
            v_narration := v_narration || p_tran_date || '/';
         END IF;

         IF TRIM (v_auth_id) IS NOT NULL
         THEN
            v_narration := v_narration || v_auth_id;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_trans_desc := 'Transaction type ' || p_txn_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En find narration
       v_timestamp := systimestamp;  --Added for 15197
      --Sn create a entry in statement log
      IF v_dr_cr_flag <> 'NA'
      THEN
         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no,
                         csl_opening_bal,
                         csl_trans_amount,
                         csl_trans_type, csl_trans_date,
                         csl_closing_balance,
                         csl_trans_narrration, csl_inst_code,
                         csl_pan_no_encr, csl_rrn, csl_auth_id,
                         csl_business_date, csl_business_time, txn_fee_flag,
                         csl_delivery_channel, csl_txn_code, csl_acct_no,
                         --Added by Deepa to log the account number ,INS_DATE and INS_USER
                         csl_ins_user, csl_ins_date, csl_merchant_name,
                         --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                         csl_merchant_city, csl_merchant_state,
                         csl_panno_last4digit
                         ,csl_prod_code,csl_acct_type,csl_time_stamp,csl_card_type
                        )
                 --Added by Srinivasu on 15-May-2012 to log Last $ Digit of the card number
            VALUES      (v_hash_pan,
                        -- v_acct_balance, --V_ACCT_BALANCE replaced on 29.10.2013with v_ledger_bal for 12840
                         v_ledger_bal,
                         v_tran_amt,
                         v_dr_cr_flag, v_tran_date,
                         DECODE (v_dr_cr_flag,
                                 'DR', v_ledger_bal - v_tran_amt,--V_ACCT_BALANCE replaced on 29.10.2013with v_ledger_bal for 12840
                                 'CR', v_ledger_bal + v_tran_amt,--V_ACCT_BALANCE replaced on 29.10.2013with v_ledger_bal for 12840
                                 'NA', v_ledger_bal--V_ACCT_BALANCE replaced on 29.10.2013with v_ledger_bal for 12840
                                ),
                         v_narration, p_inst_code,
                         v_encr_pan, p_rrn, v_auth_id,
                         p_tran_date, p_tran_time, 'N',
                         p_delivery_channel, p_txn_code, v_card_acct_no,
                         --Added by Deepa to log the account number ,INS_DATE and INS_USER
                         1, SYSDATE, p_merchant_name,
                         --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                         p_merchant_city, p_atmname_loc,
                         (SUBSTR (p_card_no,
                                  LENGTH (p_card_no) - 3,
                                  LENGTH (p_card_no)
                                 )
                         )
                         ,v_prod_code, v_cam_type_code,v_timestamp,V_PROD_CATTYPE
                        );
         --Added by Srinivasu on 15-May-2012 to log Last $ Digit of the card number
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while inserting into statement log for tran amt '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      --En create a entry in statement log

      --Sn find fee opening balance
      IF v_total_fee <> 0 OR v_freetxn_exceed = 'N'
      THEN
         -- Modified by Trivikram on 26-July-2012 for logging fee of free transaction
         BEGIN
            SELECT DECODE (v_dr_cr_flag,
                           'DR', v_ledger_bal - v_tran_amt,--V_ACCT_BALANCE replaced on 29.10.2013with v_ledger_bal for 12840
                           'CR', v_ledger_bal + v_tran_amt,--V_ACCT_BALANCE replaced on 29.10.2013with v_ledger_bal for 12840
                           'NA', v_ledger_bal--V_ACCT_BALANCE replaced on 29.10.2013with v_ledger_bal for 12840
                          )
              INTO v_fee_opening_bal
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '12';
               v_err_msg :=
                     'Error while selecting data from card Master for card number '
                  || p_card_no;
               RAISE exp_reject_record;
         END;

         --En find fee opening balance
         --Sn create entries for FEES attached
         -- Added by Trivikram on 27-July-2012 for logging complementary transaction
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
                            --Added by Deepa to log the account number ,INS_DATE and INS_USER
                            csl_ins_user, csl_ins_date, csl_merchant_name,
                            --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                            csl_merchant_city, csl_merchant_state,
                            csl_panno_last4digit
                            ,csl_prod_code,csl_acct_type,csl_time_stamp,csl_card_type
                           )
                    --Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
               VALUES      (v_hash_pan, v_fee_opening_bal, v_total_fee,
                            'DR', v_tran_date,
                            v_fee_opening_bal - v_total_fee,
                           -- 'Complimentary ' || v_duration || ' '
                            --|| v_narration,
                            -- Modified by Trivikram  on 27-July-2012  --Commented on 05/02/14 for MVCSD-4471
                            V_FEE_DESC, --Added on 05/02/14 for MVCSD-4471
                            p_inst_code, v_encr_pan, p_rrn,
                            v_auth_id, p_tran_date,
                            p_tran_time, 'Y',
                            p_delivery_channel, p_txn_code, v_card_acct_no,
                            --Added by Deepa to log the account number ,INS_DATE and INS_USER
                            1, SYSDATE, p_merchant_name,
                            --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                            p_merchant_city, p_atmname_loc,
                            (SUBSTR (p_card_no,
                                     LENGTH (p_card_no) - 3,
                                     LENGTH (p_card_no)
                                    )
                            )
                            ,v_prod_code, v_cam_type_code,v_timestamp,V_PROD_CATTYPE
                           );
            --Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Problem while inserting into statement log for tran fee '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSE
            BEGIN
               IF v_feeamnt_type = 'A'
               THEN
                  -- Added by Trivikram on 23/aug/2012 for logged fixed fee and percentage fee with waiver
                  v_flat_fees :=
                     ROUND (  v_flat_fees
                            - ((v_flat_fees * v_waiv_percnt) / 100),
                            2
                           );
                  v_per_fees :=
                     ROUND (v_per_fees - ((v_per_fees * v_waiv_percnt) / 100),
                            2
                           );

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
                               csl_panno_last4digit
                                ,csl_prod_code,csl_acct_type,csl_time_stamp,csl_card_type
                              )
                       VALUES (v_hash_pan, v_fee_opening_bal, v_flat_fees,
                               'DR', v_tran_date,
                               v_fee_opening_bal - v_flat_fees,
                              -- 'Fixed Fee debited for ' || v_narration,--Commented on 05/02/14 for MVCSD-4471
                               'Fixed Fee debited for ' || V_FEE_DESC,--Added on 05/02/14 for MVCSD-4471
                               p_inst_code, v_encr_pan, p_rrn,
                               v_auth_id, p_tran_date,
                               p_tran_time, 'Y',
                               p_delivery_channel, p_txn_code,
                               v_card_acct_no, 1, SYSDATE,
                               p_merchant_name, p_merchant_city,
                               p_atmname_loc,
                               (SUBSTR (p_card_no,
                                        LENGTH (p_card_no) - 3,
                                        LENGTH (p_card_no)
                                       )
                               )
                               ,v_prod_code, v_cam_type_code,v_timestamp,V_PROD_CATTYPE
                              );

                  --En Entry for Fixed Fee
                  v_fee_opening_bal := v_fee_opening_bal - v_flat_fees;

                  --Sn Entry for Percentage Fee
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal, csl_trans_amount,
                               csl_trans_type, csl_trans_date,
                               csl_closing_balance,
                               csl_trans_narrration,
                               csl_inst_code, csl_pan_no_encr, csl_rrn,
                               csl_auth_id, csl_business_date,
                               csl_business_time, txn_fee_flag,
                               csl_delivery_channel, csl_txn_code,
                               csl_acct_no,
                                           --Added by Deepa to log the account number ,INS_DATE and INS_USER
                                           csl_ins_user, csl_ins_date,
                               csl_merchant_name,
                                                 --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                                 csl_merchant_city,
                               csl_merchant_state,
                               csl_panno_last4digit
                                ,csl_prod_code,csl_acct_type,csl_time_stamp,csl_card_type
                              )
                       --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                  VALUES      (v_hash_pan, v_fee_opening_bal, v_per_fees,
                               'DR', v_tran_date,
                               v_fee_opening_bal - v_per_fees,
                              -- 'Percetage Fee debited for ' || v_narration,--Commented on 05/02/14 for MVCSD-4471
                               'Percentage Fee debited for ' || V_FEE_DESC,--Added on 05/02/14 for MVCSD-4471
                               p_inst_code, v_encr_pan, p_rrn,
                               v_auth_id, p_tran_date,
                               p_tran_time, 'Y',
                               p_delivery_channel, p_txn_code,
                               v_card_acct_no,
                                              --Added by Deepa to log the account number ,INS_DATE and INS_USER
                               1, SYSDATE,
                               p_merchant_name,
                                               --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                               p_merchant_city,
                               p_atmname_loc,
                               (SUBSTR (p_card_no,
                                        LENGTH (p_card_no) - 3,
                                        LENGTH (p_card_no)
                                       )
                               )
                               ,v_prod_code, v_cam_type_code,v_timestamp,V_PROD_CATTYPE
                              );
               --En Entry for Percentage Fee
               ELSE
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal,
                               csl_trans_amount, csl_trans_type,
                               csl_trans_date, csl_closing_balance,
                               csl_trans_narrration,
                               csl_inst_code, csl_pan_no_encr, csl_rrn,
                               csl_auth_id, csl_business_date,
                               csl_business_time, txn_fee_flag,
                               csl_delivery_channel, csl_txn_code,
                               csl_acct_no,
                                           --Added by Deepa to log the account number ,INS_DATE and INS_USER
                                           csl_ins_user, csl_ins_date,
                               csl_merchant_name,
                                                 --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                                 csl_merchant_city,
                               csl_merchant_state,
                               csl_panno_last4digit
                                ,csl_prod_code,csl_acct_type,csl_time_stamp,csl_card_type
                              )
                       --Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
                  VALUES      (v_hash_pan, v_fee_opening_bal,
                               v_total_fee, 'DR',
                               v_tran_date, v_fee_opening_bal - v_total_fee,
                             --  'Fee debited for ' || v_narration,--Commented on 05/02/14 for MVCSD-4471
                                 V_FEE_DESC,--Added on 05/02/14 for MVCSD-4471
                               p_inst_code, v_encr_pan, p_rrn,
                               v_auth_id, p_tran_date,
                               p_tran_time, 'Y',
                               p_delivery_channel, p_txn_code,
                               v_card_acct_no,
                                              --Added by Deepa to log the account number ,INS_DATE and INS_USER
                               1, SYSDATE,
                               p_merchant_name,
                                               --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                               p_merchant_city,
                               p_atmname_loc,
                               (SUBSTR (p_card_no,
                                        LENGTH (p_card_no) - 3,
                                        LENGTH (p_card_no)
                                       )
                               )
                               ,v_prod_code, v_cam_type_code,v_timestamp,V_PROD_CATTYPE
                              );
               --Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
               END IF;
            EXCEPTION
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
                      ctd_cust_acct_number,ctd_merchant_zip,  --Added by Pankaj S. for 11540
                      ctd_internation_ind_response  --Added by Pankaj S. for Mantis ID 13024
                      ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
                      CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
                        ,ctd_req_resp_code,ctd_ins_user --Added for 15197
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
                      v_acct_number,p_merchant_zip,  --Added by Pankaj S. for 11540
                      p_international_ind  --Added by Pankaj S. for Mantis ID 13024
                      ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
                      P_VISA_TRANSACTIONID,--Added for MVHOST 926
                      P_MC_TRACEID,--Added for MVHOST 926
                      P_CARDVERIFICATION_RESULT
                      ,p_req_resp_code,1 --Added for 15197
                      ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE
                     );
      --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Problem while selecting data from response master '
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      --En update daily and weekly transaction counter and amount
      --Sn create detail for response message
      IF v_output_type = 'B'
      THEN
         --Balance Inquiry
         p_resp_msg := TO_CHAR (v_upd_amt);
      END IF;

      --En create detail fro response message
      --Sn mini statement
      IF v_output_type = 'M'
      THEN
         --Mini statement
         BEGIN
            sp_gen_mini_stmt (p_inst_code,
                              p_card_no,
                              v_mini_totrec,
                              v_ministmt_output,
                              v_ministmt_errmsg
                             );

            IF v_ministmt_errmsg <> 'OK'
            THEN
               v_err_msg := v_ministmt_errmsg;
               v_resp_cde := '21';
               RAISE exp_reject_record;
            END IF;

            p_resp_msg :=
                    LPAD (TO_CHAR (v_mini_totrec), 2, '0')
                    || v_ministmt_output;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Problem while selecting data for mini statement '
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;
      END IF;

      --En mini statement

      -- Below IF condition block moved up to handle execption properly , (Change done during concurrent prcessing issue)

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

          --En find businesses date

          --SN - Commeneted for fwr-48

      /*    BEGIN
          IF(p_req_resp_code < 100 and p_txn_code='16') THEN  --Added for 15197


             sp_create_gl_entries_cmsauth (p_inst_code,
                                           v_business_date,
                                           v_prod_code,
                                           v_prod_cattype,
                                           v_tran_amt,
                                           v_func_code,
                                           p_txn_code,
                                           v_dr_cr_flag,
                                           p_card_no,
                                           v_fee_code,
                                           v_total_fee,
                                           v_fee_cracct_no,
                                           v_fee_dracct_no,
                                           v_card_acct_no,
                                           p_rvsl_code,
                                           p_msg,
                                           p_delivery_channel,
                                           v_resp_cde,
                                           v_gl_upd_flag,
                                           v_gl_err_msg
                                          );

             IF v_gl_err_msg <> 'OK' OR v_gl_upd_flag <> 'Y'
             THEN
                v_gl_upd_flag := 'N';
                p_resp_code := v_resp_cde;
                v_err_msg := v_gl_err_msg;
                RAISE exp_reject_record;
             END IF;
              END IF;
          EXCEPTION WHEN exp_reject_record                                      -- Added during concurrent processing issue
          THEN
                RAISE;

          WHEN OTHERS
             THEN
                v_gl_upd_flag := 'N';
                p_resp_code := v_resp_cde;
                v_err_msg := v_gl_err_msg;
                RAISE exp_reject_record;
          END; */

          --EN - Commeneted for fwr-48

          --Sn find prod code and card type and available balance for the card number
          BEGIN
             SELECT     cam_acct_bal, cam_ledger_bal      -- Added for OLS changes
                   INTO v_acct_balance, p_ledger_bal      -- Added for OLS changes
                   FROM cms_acct_mast
                  WHERE cam_acct_no =
                           (SELECT cap_acct_no
                              FROM cms_appl_pan
                             WHERE cap_pan_code = v_hash_pan
                               AND cap_mbr_numb = p_mbr_numb
                               AND cap_inst_code = p_inst_code)
                    AND cam_inst_code = p_inst_code;
             --FOR UPDATE NOWAIT;                           -- Commented for Concurrent Processsing Issue
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                v_resp_cde := '14';                      --Ineligible Transaction
                v_err_msg := 'Invalid Card ';
                RAISE exp_reject_record;
             WHEN OTHERS
             THEN
                v_resp_cde := '12';
                v_err_msg :=
                      'Error while selecting data from card Master for card number '
                   || SQLERRM;
                RAISE exp_reject_record;
          END;

          --En find prod code and card type for the card number
          IF v_output_type = 'N'
          THEN
             --Balance Inquiry
             p_resp_msg := TO_CHAR (v_upd_amt);
          END IF;
       END IF;

       --En create GL ENTRIES


      v_resp_cde := '1';

      ---En Updation of Usage limit and amount
      p_resp_id := v_resp_cde; --Added for VMS-8018
      BEGIN
         SELECT cms_b24_respcde, cms_iso_respcde
--Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
         INTO  p_resp_code,
               --v_cms_iso_respcde --Added  by Besky on 11/03/13 for defect id 10576
               p_iso_respcde --Commented and replaced on 17.07.2013 for the Mantis ID 11612
         FROM   cms_response_mast
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
      --<< MAIN EXCEPTION >>
      WHEN exp_reject_record
      THEN
         ROLLBACK TO v_auth_savepoint;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal,cam_type_code,cam_acct_no --Added for 15197
              INTO v_acct_balance, v_ledger_bal,v_cam_type_code,v_acct_number --Added for 15197
              FROM cms_acct_mast
             WHERE cam_acct_no =
                      (SELECT cap_acct_no
                         FROM cms_appl_pan
                        WHERE cap_pan_code = v_hash_pan
                          AND cap_inst_code = p_inst_code)
               AND cam_inst_code = p_inst_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
         END;

         BEGIN
            SELECT ctc_posusage_limit, ctc_business_date
              INTO v_pos_usagelimit, v_business_date_tran
              FROM cms_translimit_check
             WHERE ctc_inst_code = p_inst_code
               AND ctc_pan_code = v_hash_pan
               AND ctc_mbr_numb = p_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err_msg :=
                     'Cannot get the Transaction Limit Details of the Card'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Error while selecting CMS_TRANSLIMIT_CHECK '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         -- commented by trivikram on 22/12/2012

         /* IF P_DELIVERY_CHANNEL = '02' THEN
            IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
             V_POS_USAGEAMNT  := 0;
             V_POS_USAGELIMIT := 1;
             BEGIN
               UPDATE CMS_TRANSLIMIT_CHECK
                 SET CTC_POSUSAGE_AMT       = V_POS_USAGEAMNT,
                     CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
                     CTC_ATMUSAGE_AMT       = 0,
                     CTC_ATMUSAGE_LIMIT     = 0,
                     CTC_MMPOSUSAGE_AMT     = 0,
                     CTC_MMPOSUSAGE_LIMIT   = 0,
                     CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                               '23:59:59',
                                               'yymmdd' || 'hh24:mi:ss'),
                     CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
                WHERE CTC_INST_CODE = P_INST_CODE AND
                     CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;
               IF SQL%ROWCOUNT = 0 THEN
                 V_ERR_MSG  := 'updating 3 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
                 V_RESP_CDE := '21';
                 RAISE EXP_REJECT_RECORD;
               END IF;
             EXCEPTION
               WHEN EXP_REJECT_RECORD THEN
                 RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
                 V_ERR_MSG  := 'Error while updating 3 CMS_TRANSLIMIT_CHECK ' ||
                            V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                 V_RESP_CDE := '21';
                 RAISE EXP_REJECT_RECORD;
             END;
            ELSE
             V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;
             BEGIN
               UPDATE CMS_TRANSLIMIT_CHECK
                 SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
                WHERE CTC_INST_CODE = P_INST_CODE AND
                     CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;
               IF SQL%ROWCOUNT = 0 THEN
                 V_ERR_MSG  := 'updating 4 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
                 V_RESP_CDE := '21';
                 RAISE EXP_REJECT_RECORD;
               END IF;
             EXCEPTION
               WHEN EXP_REJECT_RECORD THEN
                 RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
                 V_ERR_MSG  := 'Error while updating 4 CMS_TRANSLIMIT_CHECK ' ||
                            V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                 V_RESP_CDE := '21';
                 RAISE EXP_REJECT_RECORD;
             END;
            END IF;
          END IF;*/

         --Sn select response code and insert record into txn log dtl
         BEGIN
            p_resp_msg := v_err_msg;
            p_resp_code := v_resp_cde;
            p_resp_id := v_resp_cde; --Added for VMS-8018

            -- Assign the response code to the out parameter
            SELECT cms_b24_respcde, cms_iso_respcde
--Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
            INTO   p_resp_code,
                  -- v_cms_iso_respcde --Added  by Besky on 11/03/13 for defect id 10576
                  p_iso_respcde --Commented and replaced  on 17.07.2013 for the Mantis ID 11612
            FROM   cms_response_mast
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
               ---ISO MESSAGE FOR DATABASE ERROR Server Declined
               p_resp_id := '69'; --Added for VMS-8018
               ROLLBACK;
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
                         ctd_customer_card_no_encr, ctd_cust_acct_number,ctd_merchant_zip,  --Added by Pankaj S. for 11540
                         ctd_internation_ind_response  --Added by Pankaj S. for Mantis ID 13024
                         ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
                         CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
                           ,ctd_req_resp_code,ctd_ins_user --Added for 15197
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
                         v_encr_pan, v_acct_number,p_merchant_zip,  --Added by Pankaj S. for 11540
                         p_international_ind  --Added by Pankaj S. for Mantis ID 13024
                         ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
                         P_VISA_TRANSACTIONID,--Added for MVHOST 926
                         P_MC_TRACEID,--Added for MVHOST 926
                         P_CARDVERIFICATION_RESULT
                         ,p_req_resp_code,1 --Added for 15197
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
               p_resp_id := '69'; --Added for VMS-8018
               ROLLBACK;
               RETURN;
         END;
      WHEN OTHERS
      THEN
         ROLLBACK TO v_auth_savepoint;

         BEGIN
            SELECT ctc_posusage_limit, ctc_business_date
              INTO v_pos_usagelimit, v_business_date_tran
              FROM cms_translimit_check
             WHERE ctc_inst_code = p_inst_code
               AND ctc_pan_code = v_hash_pan
               AND ctc_mbr_numb = p_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err_msg :=
                     'Cannot get the Transaction Limit Details of the Card'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Error while selecting CMS_TRANSLIMIT_CHECK 1'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         -- commented by trivikram on 22/12/2012

         /*IF P_DELIVERY_CHANNEL = '02' THEN
           IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
            V_POS_USAGEAMNT  := 0;
            V_POS_USAGELIMIT := 1;
            BEGIN
              UPDATE CMS_TRANSLIMIT_CHECK
                SET CTC_POSUSAGE_AMT       = V_POS_USAGEAMNT,
                    CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
                    CTC_ATMUSAGE_AMT       = 0,
                    CTC_ATMUSAGE_LIMIT     = 0,
                    CTC_MMPOSUSAGE_AMT     = 0,
                    CTC_MMPOSUSAGE_LIMIT   = 0,
                    CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                              '23:59:59',
                                              'yymmdd' || 'hh24:mi:ss'),
                    CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
               WHERE CTC_INST_CODE = P_INST_CODE AND
                    CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;
              IF SQL%ROWCOUNT = 0 THEN
                V_ERR_MSG  := 'updating 5 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
              END IF;
            EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
                RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                V_ERR_MSG  := 'Error while updating 5 CMS_TRANSLIMIT_CHECK ' ||
                           V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
            END;

           ELSE
            V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;
            BEGIN
              UPDATE CMS_TRANSLIMIT_CHECK
                SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
               WHERE CTC_INST_CODE = P_INST_CODE AND
                    CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;
              IF SQL%ROWCOUNT = 0 THEN
                V_ERR_MSG  := 'updating 6 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
              END IF;
            EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
                RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                V_ERR_MSG  := 'Error while updating 6 CMS_TRANSLIMIT_CHECK ' ||
                           V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
            END;
           END IF;
         END IF;*/

         --Sn select response code and insert record into txn log dtl
         BEGIN
            SELECT cms_b24_respcde, cms_iso_respcde
--Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
            INTO   p_resp_code,
                  --v_cms_iso_respcde --Added  by Besky on 11/03/13 for defect id 10576
                  p_iso_respcde --Commented and replaced  on 17.07.2013 for the Mantis ID 11612
            FROM   cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;

            p_resp_msg := v_err_msg;
            p_resp_id := v_resp_cde; --Added for VMS-8018
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';                         -- Server Declined
               p_resp_id := '69'; --Added for VMS-8018
               ROLLBACK;
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
                         ctd_merchant_zip,  --Added by Pankaj S. for 11540
                         ctd_internation_ind_response  --Added by Pankaj S. for Mantis ID 13024
                         ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
                         CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
                         ,ctd_req_resp_code,ctd_ins_user --Added for 15197
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
                         p_merchant_zip,  --Added by Pankaj S. for 11540
                         p_international_ind  --Added by Pankaj S. for Mantis ID 13024
                         ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
                         P_VISA_TRANSACTIONID,--Added for MVHOST 926
                         P_MC_TRACEID,--Added for MVHOST 926
                         P_CARDVERIFICATION_RESULT
                         ,p_req_resp_code,1 --Added for 15197
                         ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';          -- Server Decline Response 220509
               p_resp_id := '69'; --Added for VMS-8018
               ROLLBACK;
               RETURN;
         END;
   --En select response code and insert record into txn log dtl
   END;


   --Sn create a entry in txn log
   BEGIN

   --Sn Added for 15197
     IF p_req_resp_code >= 100 AND P_TXN_CODE='16'
      THEN

  if V_PROD_CODE is null
     then

         BEGIN

             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO,
                    cap_proxy_number
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER,
                    V_PROXUNUMBER
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
         EXCEPTION
         WHEN OTHERS THEN

         NULL;

         END;

     end if;



     IF v_business_date IS NULL
     THEN
         v_business_date :=  TRUNC (v_tran_date);

     END IF;

      if v_timestamp is null
     then
         v_timestamp := systimestamp;

     END IF;


       P_LEDGER_BAL := to_char(v_ledger_bal);
       V_UPD_AMT:=V_ACCT_BALANCE;
       V_UPD_LEDGER_AMT:=V_LEDGER_BAL;

END IF;

-- En Added for 15197

      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, terminal_id,
                   date_time, txn_code, txn_type, txn_mode,
                   txn_status,
                   response_code, business_date,
                   business_time, customer_card_no, topup_card_no,
                   topup_acct_no, topup_acct_type, bank_code,
                   total_amount,
                   rule_indicator, rulegroupid, mccode, currencycode,
                   addcharge, productid, categoryid, tips,
                   decline_ruleid, atm_name_location,auth_id, trans_desc,
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
                   response_id, cardstatus,
                                           --Added cardstatus insert in transactionlog by srinivasu.k
                                           feeattachtype,
                   -- Added by Trivikram on 05-Sep-2012
                   merchant_name,
                                 -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                 merchant_city,
                                               -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                               merchant_state,
                   -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                   addl_amnt,       -- Added for OLS additional amount Changes
                             networkid_switch,
                                              --Added on 20130626 for the Mantis ID 11344
                                              networkid_acquirer,
                   --Added on 20130626 for the Mantis ID 11344
                   network_settl_date,
                   --Added on 20130626 for the Mantis ID 11123
                   permrule_verify_flag,--Added by Pankaj S. for Mantis ID 11446
                   merchant_zip,  --Added by Pankaj S. for 11540
                   cvv_verificationtype,  --Added on 17.07.2013 for the Mantis ID 11611
                   internation_ind_response,  --Added by Pankaj S. for Mantis ID 13024
                   error_msg
                   ,addr_verify_response ,
                   addr_verify_indicator,
                   acct_type,time_stamp,add_ins_user
                   ,merchant_id ,
                   remark --Added for error msg need to display in CSR(declined by rule)
                  )
           VALUES (p_msg, p_rrn, p_delivery_channel, p_term_id,
                   v_business_date, p_txn_code, v_txn_type, p_txn_mode,
                   --DECODE (v_cms_iso_respcde, '00', 'C', 'F'),
                   DECODE (p_iso_respcde , '00', 'C', 'F'),--Commented and  replaced on 17.07.2013 for the Mantis ID 11612
                  -- v_cms_iso_respcde,
                   p_iso_respcde, --Commented and replaced on 17.07.2013 for the Mantis ID 11612
                                     --Modified  by Besky on 11/03/13 for defect id 10576
                                     p_tran_date,
                   SUBSTR (p_tran_time, 1, 10), v_hash_pan, NULL,
                   NULL,                                 --P_topup_acctno    ,
                        NULL,                              --P_topup_accttype,
                             p_bank_code,
                   TRIM(TO_CHAR(nvl(V_TOTAL_AMT,0), '99999999999999990.99')),
                   NULL, NULL, p_mcc_code, p_curr_code,
                   NULL,                                      -- P_add_charge,
                        v_prod_code, v_prod_cattype, p_tip_amt,
                   p_decline_ruleid, p_atmname_loc, v_auth_id, v_trans_desc,
                   TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99')),
                   P_MERCHANT_CNTRYCODE, NULL,
                              -- Partial amount (will be given for partial txn)
                              p_mcccode_groupid,
                   p_currcode_groupid, p_transcode_groupid, p_rules,
                   p_preauth_date, v_gl_upd_flag, p_stan,
                   p_inst_code, v_fee_code, nvl(v_fee_amt,0), nvl(v_servicetax_amount,0),
                   nvl(v_cess_amount,0), v_dr_cr_flag, v_fee_cracct_no,
                   v_fee_dracct_no, v_st_calc_flag,
                   v_cess_calc_flag, v_st_cracct_no,
                   v_st_dracct_no, v_cess_cracct_no,
                   v_cess_dracct_no, v_encr_pan,
                   NULL, v_proxunumber, p_rvsl_code,
                   v_acct_number, v_upd_amt, v_upd_ledger_amt,
                   v_resp_cde, v_applpan_cardstat,
                                                  --Added cardstatus insert in transactionlog by srinivasu.k
                                                  v_feeattach_type,
                   -- Added by Trivikram on 05-Sep-2012
                   p_merchant_name,
                                   -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                   p_merchant_city,
                                                   -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                                   p_atmname_loc,
                   -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                   p_addl_amnt,     -- Added for OLS additional amount Changes
                               p_networkid_switch,
                                                  --Added on 20130626 for the Mantis ID 11344
                                                  p_networkid_acquirer,
                   -- Added on 20130626 for the Mantis ID 11344
                   p_network_setl_date,
                   --Added on 20130626 for the Mantis ID 11123
                   v_mcc_verify_flag , --Added by Pankaj S. for Mantis ID 11446
                   p_merchant_zip,  --Added by Pankaj S. for 11540
                   NVL(p_cvv_verificationtype,'N'),  --Added on 17.07.2013 for the Mantis ID 11611
                   p_international_ind,  --Added by Pankaj S. for Mantis ID 13024
                   v_err_msg             --Added during concurrent processing issue
                   ,P_ADDR_VERFY_RESPONSE,
                   P_ADDRVERIFY_FLAG,
                   v_cam_type_code, v_timestamp,1
                   ,P_MERCHANT_ID,
                   V_ERR_MSG --Added for error msg need to display in CSR(declined by rule)
                  );

      --DBMS_OUTPUT.put_line ('AFTER INSERT IN TRANSACTIONLOG');
      p_capture_date := v_business_date;
      p_auth_id := v_auth_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code := '69';                              -- Server Declione
         p_resp_id := '69'; --Added for VMS-8018
         p_resp_msg :=
               'Problem while inserting data into transaction log  '
            || SUBSTR (SQLERRM, 1, 300);
   END;
--En create a entry in txn log
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code := '69';                                 -- Server Declined
      p_resp_id := '69'; --Added for VMS-8018
      p_resp_msg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/
SHOW ERROR;