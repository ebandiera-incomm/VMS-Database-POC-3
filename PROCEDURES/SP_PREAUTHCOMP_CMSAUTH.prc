CREATE OR REPLACE PROCEDURE VMSCMS.SP_PREAUTHCOMP_CMSAUTH (
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
   p_txn_amt                       NUMBER,
   p_mcc_code                      VARCHAR2,
   p_curr_code                     VARCHAR2,
   p_merchant_name                 VARCHAR2,
   p_merchant_city                 VARCHAR2,
   p_atmname_loc                   VARCHAR2,
   p_consodium_code       IN       VARCHAR2,
   p_partner_code         IN       VARCHAR2,
   p_expry_date           IN       VARCHAR2,
   p_stan                 IN       VARCHAR2,
   p_mbr_numb             IN       VARCHAR2,
   p_rvsl_code            IN       NUMBER,
   p_orgnl_cardno         IN       VARCHAR2,          --Card No of Preauth txn
   p_orgnl_rrn            IN       VARCHAR2,              --RRN of Preauth txn
   p_orgnl_trandate       IN       VARCHAR2, --Transaction date of Preauth txn
   p_orgnl_trantime       IN       VARCHAR2, --Transaction Time of Preauth txn
   p_orgnl_termid         IN       VARCHAR2,      --Terminal Id of Preauth txn
   p_comp_count           IN       VARCHAR2,                --Completion Count
   p_last_indicator       IN       VARCHAR2,                --Completion Count
   /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
   p_merc_id              IN       VARCHAR2,
   p_country_code         IN       VARCHAR2,
   p_network_id           IN       VARCHAR2,
   p_interchange_feeamt   IN       NUMBER,
   p_merchant_zip         IN       VARCHAR2,
   /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
   p_pos_verfication      IN       VARCHAR2,                  --Added by Deepa
   p_international_ind    IN       VARCHAR2,
   P_NETWORK_SETL_DATE    IN       VARCHAR2,  -- Added on 201112 for logging N/W settlement date in transactionlog
   p_orgnl_mcc_code       IN       VARCHAR2,  -- Added on 201112 for FSS-781
   P_NETWORKID_SWITCH     IN       VARCHAR2, --Added on 20130626 for the Mantis ID 11344
   p_auth_id              OUT      VARCHAR2,
   p_resp_code            OUT      VARCHAR2,
   p_resp_msg             OUT      VARCHAR2,
   p_capture_date         OUT      DATE,
   p_resp_id              OUT      VARCHAR2 --Added for sending to FSS (VMS-8018)
)
IS
   /*******************************************************************************************
     * Modified By       :  Sagar
     * Modified Date     :  03-Jan-2013
     * Modified For      :  FSS-833     
     * Modified Reason   :  To add card number condition while fetching count 
                            and txn details for valid preauth from CMS_PREAUTH_TRANSACTIONS
                            table. 
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  03-Jan-2013
     * Release Number    :  CMS3.5.1_RI0023_B0007
     
     * Modified By       :  Sagar
     * Modified Date     :  15-Feb-2013
     * Modified For      :  FSS-781    
     * Modified Reason   :  To match original transaction details 
                            of completion transaction based on 4 rules
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  15-Feb-2013
     * Release Number    :  CMS3.5.1_RI0023.2_B0011
     
     * Modified By       :  Sagar
     * Modified Date     :  08-Mar-2013
     * Modified For      :  Defect 0010555    
     * Modified Reason   :  To retrun acct balance in resp message
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  08-Mar-2013
     * Release Number    :  CMS3.5.1_RI0023.2_B0020
     
     * Modified by       :  Pankaj S.
     * Modified Reason   :  10871 
     * Modified Date     :  19-Apr-2013
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  
     * Build Number      :  RI0024.1_B0013
     
     * Modified by       :  Ranveer Meel.
     * Modified Reason   :  Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy
     * Modified Date     :  18-JUN-2013
     * Reviewer          :  Saravana kumar
     * Reviewed Date     :  18-JUN-2013
     * Build Number      :  RI0024.2_B0004
     
     * Modified by       :  Ramesh A.
     * Modified Reason   :  Changes for medagate , MVHOST-392
     * Modified Date     :  20-JUN-2013
     * Reviewer          :  
     * Reviewed Date     :  
     * Build Number      :  RI0024.2_B0006
     
     * Modified by       :  Arunprasath
     * Modified Reason   :  Exception added for Resource Busy
     * Modified Date     :  26-JUN-2013
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  26-JUN-2013
     * Build Number      :  RI0024.2_B0009  
     
     * Modified by       : Deepa T
     * Modified for         : Mantis ID 11344
     * Modified Reason   : Log the Network ID as ELAN             
     * Modified Date     : 26-Jun-2013
     * Reviewer          : Dhiraj
     * Reviewed Date     : 26-JUN-2013
     * Build Number      : RI0024.2_B0009
     
     * Modified by       : Sagar
     * Modified for      : FSS-1246
     * Modified Reason   : To check and reject duplicate completion transaction             
     * Modified Date     : 09-Jul-2013
     * Reviewer          : Dhiraj
     * Reviewed Date     : 
     * Build Number      : RI0024.3_B0004     
     
     * Modified by      : Sagar  
     * Modified for     : FSS-1246 Review observations 
     * Modified Reason  : Review observations               
     * Modified Date    : 24-Jul-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0024.4_B0002     
     
     * Modified by     : Sachin P
     * Modified for    : Mantis Id:11692 
     * Modified Reason : In Force post completion transaction, txn amount is logged as incorrect(i.e txn amount+fee amount) 
                         in cms_preauth_transaction,CMS_PREAUTH_TRANS_HIST tables and during preauth transaction, 
                         approve amount is logged with fee amount.In Preauth completion procedure 
                        'Successful preauth completion already done' check does not have the inst code condition.   
     * Modified Date   : 24-Jul-2013
     * Reviewer        : Dhiraj
     * Reviewed Date   : 19-aug-2013
     * Build Number    : RI0024.4_B0002   

     * Modified by      : Sagar  
     * Modified for     : MVHOST-354
     * Modified Reason  : To include Rule5 changes and comparing approve amount in the 5% range of v_tran_amt                
     * Modified Date    : 26-Aug-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0024.4_B0009
     
     * Modified by      : Sagar M.
     * Modified for     : FSS-1246
     * Modified Reason  : Performacne changes
     * Modified Date    : 26-Aug-2013
     * Reviewer         : Sachin
     * Reviewed Date    : 26-Aug-2013
     * Build Number     : RI0024.4_B0009   
     
     * Modified by      : Sagar  
     * Modified for     : MVHOST-354
     * Modified Reason  : Review observation changes                
     * Modified Date    : 03-Aug-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 04-Aug-2013
     * Build Number     : RI0024.4_B0009    
     
     * Modified By      : MageshKumar S
     * Modified Date    : 28-Jan-2014
     * Modified for     : MVCSD-4471
     * Modified Reason  : Narration change for FEE amount
     * Reviewer         : Dhiraj
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
     
      * Modified by       : siva Kumar M
     * Modified for      : FSS-837
     * Modified Reason   : To hold the preauth completion fee at the time preauth
     * Modified Date     : 25-Jun-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0001
     
      * Modified by      : siva Kumar M
     * Modified for      : 15601
     * Modified Reason   : Completion Fee which is holded should be debited from ldg bal for first completion 
     * Modified Date     : 21-July-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0005
     
          
     * Modified by      : siva Kumar M
     * Modified for      : 15601&15619
     * Modified Reason   : Remaining Completion % fee is debiting to the account bal. incase of multiplecompletion &
     Completion Fee which is holded should be debited from ldg bal for first completion
     * Modified Date     : 25-July-2014
     * Reviewer          : Spankaj
     * Build Number      : : RI0027.3_B0006
     
     * Modified by       : MageshKumar S.
     * Modified Date     : 25-July-14    
     * Modified For      : FWR-48
     * Modified reason   : GL Mapping removal changes
     * Reviewer          : Spankaj    
     * Build Number      : RI0027.3.1_B0001
     
      * Modified by       : siva Kumar M
     * Modified Date     : 11-Nov-14
     * Modified For      : Mantis id:15764
     * Modified reason   : Complition Fee is not charging in Multiple (Last) Complition, Since Complition Fee is already hold on Incremental Pre-Auth 
     * Reviewer          : Spankaj
     * Build Number      : Ri0027.4.3_B0003
	 
    * Modified by      : Ramesh A
    * Modified for     : FSS-3610
    * Modified Date    : 31-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOST_3.1_B0008
    
     * Modified by      : Pankaj S.
     * Modified for     : FSS-5126: Free Fee Issue
     
     * Modified Date    : 26-June-2017
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_17.06  

	   * Modified By      : Karthick/Jey
	   * Modified Date    : 05-19-2022
	   * Purpose          : Archival changes.
	   * Reviewer         : Venkat Singamaneni
	   * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991	 

	   * Modified By      : Areshka A.
	   * Modified Date    : 03-Nov-2023
	   * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
	   * Reviewer         : 
	   * Release Number   : 

   *********************************************************************************************/
   v_err_msg                 VARCHAR2 (900)                           := 'OK';
   v_acct_balance            NUMBER;
   v_ledger_bal              NUMBER;
   v_tran_amt                NUMBER;
   v_auth_id                 VARCHAR2 (14);
   v_total_amt               NUMBER;
   v_tran_date               DATE;
   v_func_code               cms_func_mast.cfm_func_code%TYPE;
   v_prod_code               cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype            cms_prod_cattype.cpc_card_type%TYPE;
   v_fee_amt                 NUMBER;
   v_total_fee               NUMBER;
   v_upd_amt                 NUMBER;
   v_upd_ledger_amt          NUMBER;
   v_narration               VARCHAR2 (300);
   v_fee_opening_bal         NUMBER;
   v_resp_cde                VARCHAR2 (3);
   v_expry_date              DATE;
   v_dr_cr_flag              VARCHAR2 (2);
   v_output_type             VARCHAR2 (2);
   v_applpan_cardstat        cms_appl_pan.cap_card_stat%TYPE;
   p_err_msg                 VARCHAR2 (500);
   v_precheck_flag           NUMBER;
   v_preauth_flag            NUMBER;
   v_avail_pan               cms_avail_trans.cat_pan_code%TYPE;
   v_gl_upd_flag             transactionlog.gl_upd_flag%TYPE;
   v_gl_err_msg              VARCHAR2 (500);
   v_savepoint               NUMBER                                      := 0;
   v_tran_fee                NUMBER;
   v_error                   VARCHAR2 (500);
   v_business_date_tran      DATE;
   v_business_time           VARCHAR2 (5);
   v_cutoff_time             VARCHAR2 (5);
   v_card_curr               VARCHAR2 (5);
   v_fee_code                cms_fee_mast.cfm_fee_code%TYPE;
   v_fee_crgl_catg           cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_fee_crgl_code           cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_fee_crsubgl_code        cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_fee_cracct_no           cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_drgl_catg           cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_fee_drgl_code           cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_fee_drsubgl_code        cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_fee_dracct_no           cms_prodcattype_fees.cpf_dracct_no%TYPE;
   --st AND cess
   v_servicetax_percent      cms_inst_param.cip_param_value%TYPE;
   v_cess_percent            cms_inst_param.cip_param_value%TYPE;
   v_servicetax_amount       NUMBER;
   v_cess_amount             NUMBER;
   v_st_calc_flag            cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_cess_calc_flag          cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_st_cracct_no            cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_st_dracct_no            cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_cess_cracct_no          cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_cess_dracct_no          cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   --
   v_waiv_percnt             cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_err_waiv                VARCHAR2 (300);
   v_log_actual_fee          NUMBER;
   v_log_waiver_amt          NUMBER;
   v_auth_savepoint          NUMBER                                 DEFAULT 0;
   v_actual_exprydate        DATE;
   v_business_date           DATE;
   v_txn_type                NUMBER (1);
   v_mini_totrec             NUMBER (2);
   v_ministmt_errmsg         VARCHAR2 (500);
   v_ministmt_output         VARCHAR2 (900);
   v_fee_attach_type         VARCHAR2 (1);
   v_check_merchant          NUMBER (1);
   exp_reject_record         EXCEPTION;
   v_terminal_download_ind   VARCHAR2 (1);
   v_terminal_count          NUMBER;
   v_atmonline_limit         cms_appl_pan.cap_atm_online_limit%TYPE;
   v_posonline_limit         cms_appl_pan.cap_atm_offline_limit%TYPE;
   v_temp_expiry             cms_appl_pan.cap_expry_date%TYPE;
   v_bin_code                NUMBER (6);
   v_terminal_bin_count      NUMBER;
   v_atm_usageamnt           cms_translimit_check.ctc_atmusage_amt%TYPE;
   v_pos_usageamnt           cms_translimit_check.ctc_posusage_amt%TYPE;
   v_atm_usagelimit          cms_translimit_check.ctc_atmusage_limit%TYPE;
   v_pos_usagelimit          cms_translimit_check.ctc_posusage_limit%TYPE;
   v_preauth_amount          NUMBER;
   v_preauth_txnamount       NUMBER;
   v_preauth_date            DATE;
   v_preauth_valid_flag      CHARACTER (1);
   v_preauth_expiry_flag     CHARACTER (1);
   v_preauth_hold            VARCHAR2 (1);
   v_preauth_period          NUMBER;
   v_preauth_usage_limit     NUMBER;
   v_card_acct_no            VARCHAR2 (20);
   v_hold_amount             NUMBER                                      := 0;
   --T.Narayanan assigned value for the hold amount as 0 for completion without preauth
   v_preauth_exp_date        DATE;
   v_hash_pan                cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                cms_appl_pan.cap_pan_code_encr%TYPE;
   v_orgnl_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
   v_rrn_count               NUMBER;
   v_rrn_cnt                 NUMBER;
   v_tran_type               VARCHAR2 (2);
   v_date                    DATE;
   v_time                    VARCHAR2 (10);
   v_max_card_bal            NUMBER;
   v_curr_date               DATE;
   v_total_hold_amt          NUMBER;
   v_pre_auth_check          CHAR (1)                                  := 'N';
   --T.Narayanan added for preauth check
   v_count                   NUMBER                                      := 0;
   --T.Narayanan added for preauth check
   v_proxy_hold_amount       VARCHAR2 (12)                              := '';
   --T.Narayanan added for preauth check
   v_last_comp_ind           VARCHAR2 (1)                               := '';
   v_proxunumber             cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number             cms_appl_pan.cap_acct_no%TYPE;
   v_auth_id_gen_flag        VARCHAR2 (1);
   --AUTHID_DATE             VARCHAR2(8);
   v_trans_desc              VARCHAR2 (50);
   /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
   v_hold_days               cms_txncode_rule.ctr_hold_days%TYPE;
   p_hold_amount             NUMBER;
   /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
   --Added by Deepa On June 19 2012 for Fees Changes
   v_feeamnt_type            cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_per_fees                cms_fee_mast.cfm_per_fees%TYPE;
   v_flat_fees               cms_fee_mast.cfm_fee_amt%TYPE;
   v_clawback                cms_fee_mast.cfm_clawback_flag%TYPE;
   v_fee_plan                cms_fee_feeplan.cff_fee_plan%TYPE;
   v_freetxn_exceed          VARCHAR2 (1);
   -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
   v_duration                VARCHAR2 (20);
   -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
   v_feeattach_type          VARCHAR2 (2);
   -- Added by Trivikram on 5th Sept 2012
   v_oldest_preauth          DATE;   
   v_rule                    varchar2(5);  -- Added for FSS-781 on 22-Feb-2013
   v_rowid                   varchar2(40); -- Added for FSS-781 on 22-Feb-2013
   v_sqlrowcnt               number;       -- Added for FSS-781 on 22-Feb-2013 
   --v_perhold_amount          CMS_TXNCODE_RULE.ctr_perhold_amount%TYPE;  -- Added for FSS-781 on 22-Feb-2013   
   --v_perhold_found           varchar2(1);                               -- Added for FSS-781 on 22-Feb-2013
   --v_match_amt               number;                                    -- Added for FSS-781 on 22-Feb-2013    
   v_cpt_rrn                   cms_preauth_transaction.cpt_rrn%type;      -- Added for FSS-781 on 22-Feb-2013
   v_comp_txn_code             varchar2(2);                               -- Added for FSS-781 on 22-Feb-2013
   --Sn added by Pankaj S. for 10871
   v_totalamt                  transactionlog.total_amount%TYPE;
   v_acct_type                 cms_acct_mast.cam_type_code%TYPE;
   v_timestamp                 timestamp(3); 
   --En added by Pankaj S. for 10871 
    --Added for MVHOST-392 on 18/06/2013
   V_MCC_VERIFY_FLAG       VARCHAR2(1);
   
   v_dup_comp_check        number(5); --FSS-1246
   
   v_incr_tran_amt         number; --Added for MVHOST-354    
   v_decr_tran_amt         number; --Added for MVHOST-354
   
   V_FEE_DESC         cms_fee_mast.cfm_fee_desc%TYPE;  -- Added for MVCSD-4471
   
    --added for FSs-837 on 25-06-2014
    v_completion_fee             cms_preauth_transaction.cpt_completion_fee%TYPE;
    v_fee_reverse_amount         NUMBER;
    v_comp_total_fee             NUMBER;
    v_complfee_increment_type    VARCHAR2(1);
    
   -- v_total_per_fee   NUMBER;  commented for mantis id:15619
   
   v_total_hold_fee  number; -- added for mantis id:15619
   v_complfree_flag   cms_preauth_transaction.cpt_complfree_flag%TYPE;
   
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
   
BEGIN
   SAVEPOINT v_auth_savepoint;
   v_resp_cde := '1';
   p_err_msg := 'OK';
   p_resp_msg := 'OK';
   v_auth_id_gen_flag := 'N';

   BEGIN
      --SN CREATE HASH PAN
      BEGIN
         v_hash_pan := gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';                          -- added by chinmaya
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN CREATE HASH PAN

      --SN CREATE Original HASH PAN
      BEGIN
         v_orgnl_hash_pan := gethash (p_orgnl_cardno);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';                          -- added by chinmaya
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN CREATE Original HASH PAN
      

     --SN :- Query shifted at this place as per review observations changes for MVHOST-354

       --Sn find debit and credit flag 
      BEGIN
         SELECT ctm_credit_debit_flag, ctm_output_type,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type,
                ctm_tran_desc                                           --Added as per review observations changes for MVHOST-354
           INTO v_dr_cr_flag, v_output_type,
                v_txn_type,
                v_tran_type,
                v_trans_desc                                            --Added as per review observations changes for MVHOST-354
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         
            v_trans_desc := 'Transaction type ' || p_txn_code; -- Added since query on line 1701 is commented as per review observation for MVHOST-354
            v_resp_cde := '12';                      --Ineligible Transaction
            v_err_msg :=
                  'Transflag  not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            v_resp_cde := '21';                      --Ineligible Transaction
            v_err_msg := 'More than one transaction defined for txn code ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';                      --Ineligible Transaction
            v_err_msg := 'Error while selecting the details fromtransaction ';
            RAISE exp_reject_record;
      END;

      --En find debit and credit flag
      
      --EN :- Query shifted at this place as per review observations changes for MVHOST-354
      

      --SN create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';                          -- added by chinmaya
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN create encr pan

      --Sn Transaction Date Check
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

      --En Transaction Date Check

      --Sn Date Conversion
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

      --Sn Date Conversion

     

      --Sn Duplicate RRN Check
      BEGIN
	  
			 --Added for VMS-5739/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');
	   
        IF (v_Retdate>v_Retperiod) THEN                                  --Added for VMS-5739/FSP-991
		 
           SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE terminal_id = p_term_id
            AND rrn = p_rrn
            AND business_date = p_tran_date
            /*Added by ramkumar.Mk on 25 march 2012
                          *Reason: check the condition for Delivery channel
                          */
            AND delivery_channel = p_delivery_channel
            AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
			
	    ELSE
	
		    SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                   --Added for VMS-5739/FSP-991
          WHERE terminal_id = p_term_id
            AND rrn = p_rrn
            AND business_date = p_tran_date
            /*Added by ramkumar.Mk on 25 march 2012
                          *Reason: check the condition for Delivery channel
                          */
            AND delivery_channel = p_delivery_channel
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
         EXCEPTION--Added Exception by Arunprasath on 25 june 2013
     WHEN EXP_REJECT_RECORD THEN
     RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting RRN ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;
      END;

      --En Duplicate RRN Check
      
     -------------------------         
     --SN:Added for FSS-1246
     -------------------------          
      
      Begin
      
      
           --SN:- Query changed for performance changes
           
           select count(1)
           into  v_dup_comp_check
           from cms_preauth_trans_hist
           where CPH_ORGNL_CARD_NO = v_orgnl_hash_pan
           and   CPH_ORGNL_TXN_DATE = p_orgnl_trandate
           and   CPH_ORGNL_TXN_TIME = p_orgnl_trantime
           and   CPH_ORGNL_RRN = p_orgnl_rrn
           and   CPH_TRAN_CODE = p_txn_code
           and   CPH_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
           and   CPH_COMP_COUNT = p_comp_count
           and   CPH_TRANSACTION_FLAG ='C';       
           
           --EN:- Query changed for performance changes      
      
      
           --SN:- Query commented for performance changes   
           /*       
      
           select count(1) into v_dup_comp_check
           from transactionlog
           where instcode     = p_inst_code --Added on 14.07.2013 for 11692 
           and orgnl_card_no = p_orgnl_cardno  
           and   orgnl_rrn = p_orgnl_rrn
           and   orgnl_business_Date = p_orgnl_trandate
           and   orgnl_business_time = p_orgnl_trantime
           and   completion_count = p_comp_count
           and   response_code = '00';
           
          */
            --EN:- Query commented for performance changes           
          
           if v_dup_comp_check > 0
           then
           
               V_RESP_CDE := '155';
               V_ERR_MSG  := 'Successful preauth completion already done';
               RAISE EXP_REJECT_RECORD;              
           
           end if;
      
      
      exception when  EXP_REJECT_RECORD
      then
          raise;
      when others
      then
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while fetching duplicate completion count ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;      
      
      End;
      
     -------------------------         
     --EN:Added for FSS-1246
     -------------------------     
     
     /* -- Commented and converted into cursor logic 

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
      
      */ -- Commented and converted into cursor logic below
      
      
      --SN :- Added as per review observation changes for MVHOST-354
      
      BEGIN
           for i in (SELECT cip_param_value,cip_param_key 
                      FROM cms_inst_param
                     WHERE cip_param_key in('CUTOFF','CESS','SERVICETAX') AND cip_inst_code = p_inst_code
                   )
            loop
           
                 if i.cip_param_key = 'SERVICETAX' 
                 then
                     
                     v_servicetax_percent := i.cip_param_value;
                     
                 elsif i.cip_param_key = 'CESS'    
                 then   
                     v_cess_percent := i.cip_param_value;
                     
                 elsif  i.cip_param_key = 'CUTOFF'
                 then    
                     
                     v_cutoff_time := i.cip_param_value;
                 
                 end if;
        
            end loop;      
            
      EXCEPTION WHEN OTHERS
      THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting institution parameters ';
            RAISE exp_reject_record;
      END;              
       
        if v_servicetax_percent is null
        then
             
            v_resp_cde := '21';
            v_err_msg := 'Service Tax is  not defined in the system';
            RAISE exp_reject_record;             
             
        elsif v_cess_percent is null
        then
             
            v_resp_cde := '21';
            v_err_msg := 'Cess is not defined in the system';
            RAISE exp_reject_record;             
             
        elsif v_cutoff_time is null
        then
             
            v_cutoff_time := 0;
            v_resp_cde := '21';
            v_err_msg := 'Cutoff time is not defined in the system';
            RAISE exp_reject_record;             
             
        end if;
        
      --EN :- Added as per review observation changes for MVHOST-354        
                  
       --Sn find card detail
      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_expry_date,
                cap_card_stat, cap_atm_online_limit, cap_pos_online_limit,
                cap_proxy_number, cap_acct_no
           INTO v_prod_code, v_prod_cattype, v_expry_date,
                v_applpan_cardstat, v_atmonline_limit, v_atmonline_limit,
                v_proxunumber, v_acct_number
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan                         -- P_card_no
            AND cap_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';
            v_err_msg := 'CARD NOT FOUND ' || v_hash_pan;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      --En find card detail          

      --Sn find the  Currency Converted txn amnt
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
               v_resp_cde := '69';                 -- Server Declined -220509
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

      --Sn find the  Currency Converted txn amnt
      

      BEGIN
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
      END;

      --Sn select authorization processe flag
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
                        'Master set up is not done for Authorization Process for pre check'; -- Review observation changes MVHOST-354
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
                        'Master set up is not done for Authorization Process for pre auth'; -- Review observation changes MVHOST-354
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
      
      /*                                        --SN:Commented as per review observation for FSS-1246  
      --Sn find card detail
      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_expry_date,
                cap_card_stat, cap_atm_online_limit, cap_pos_online_limit,
                cap_proxy_number, cap_acct_no
           INTO v_prod_code, v_prod_cattype, v_expry_date,
                v_applpan_cardstat, v_atmonline_limit, v_atmonline_limit,
                v_proxunumber, v_acct_number
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan                         -- P_card_no
            AND cap_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';
            v_err_msg := 'CARD NOT FOUND ' || v_hash_pan;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      --En find card detail
     */                        --EN:Commented as per review observation for FSS-1246 

      --Sn check for Preauth
      IF v_preauth_flag = 1
      THEN
         BEGIN
            /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
            sp_elan_preauthorize_txn(p_card_no,
                                      p_mcc_code,
                                      p_curr_code,
                                      v_tran_date,
                                      p_txn_code,
                                      p_inst_code,
                                      p_tran_date,
                                      v_tran_amt,
                                      p_delivery_channel,
                                      p_merc_id,
                                      p_country_code,
                                      p_hold_amount,
                                      v_hold_days,
                                      v_resp_cde,
                                      v_err_msg
                                     );

            /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
            IF (v_resp_cde <> '1' OR TRIM (v_err_msg) <> 'OK')
            THEN
                --ST: Added for MVHOST-392 on 18/06/2013
          IF P_MSG IS NOT NULL AND P_MSG IN(9220,9221) THEN
            IF UPPER(V_ERR_MSG) = 'INVALID MERCHANT CODE' THEN
              V_RESP_CDE :=1;
              V_ERR_MSG  :='OK';
              V_MCC_VERIFY_FLAG :='N';
            ELSE
             RAISE EXP_REJECT_RECORD;
            END IF;
          ELSE
             RAISE EXP_REJECT_RECORD;
          END IF;
       --END :Added for MVHOST-392 on 18/06/2013
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                   'Error from pre_auth process ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      --En check for preauth
      
      --SN - commented for fwr-48

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
      END;*/

      --En find function code attached to txn code
      
      --EN - commented for fwr-48
      
      --Sn find prod code and card type and available balance for the card number
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no,
                    cam_type_code --added by Pankaj S. for 10871
               INTO v_acct_balance, v_ledger_bal, v_card_acct_no,
                    v_acct_type --added by Pankaj S. for 10871
               FROM cms_acct_mast
              WHERE cam_acct_no = v_acct_number                             --V_acct_number comapred instead od subquery as per review observation for FSS-1246  
        --                       (SELECT cap_acct_no
        --                          FROM cms_appl_pan
        --                         WHERE cap_pan_code = v_hash_pan           --P_card_no
        --                           AND cap_mbr_numb = p_mbr_numb
        --                           AND cap_inst_code = p_inst_code)
                AND cam_inst_code = p_inst_code
                FOR UPDATE;    --SN:Added on 18-Jun-2013
        --FOR UPDATE NOWAIT;   --SN:COMMENTED for FSS-Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy on 18-Jun-2013 by Ranveer Meel
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';                      --Ineligible Transaction
            v_err_msg := 'Invalid Card ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting data from card Master for card number '
               || SQLERRM;
            RAISE exp_reject_record;
      END;

    --Sn Duplicate RRN Check again  added for FSS-Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy on 18-Jun-2013 by Ranveer Meel
      BEGIN
	     
	   IF (v_Retdate>v_Retperiod) THEN                                  --Added for VMS-5739/FSP-991
	   
         SELECT COUNT (1)
           INTO v_rrn_cnt
           FROM transactionlog
          WHERE terminal_id = p_term_id
            AND rrn = p_rrn
            AND business_date = p_tran_date
            /*Added by ramkumar.Mk on 25 march 2012
                          *Reason: check the condition for Delivery channel
                          */
            AND delivery_channel = p_delivery_channel
            AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
			
		ELSE
		 
		  SELECT COUNT (1)
          INTO v_rrn_cnt
          FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                      --Added for VMS-5739/FSP-991
          WHERE terminal_id = p_term_id
            AND rrn = p_rrn
            AND business_date = p_tran_date
            /*Added by ramkumar.Mk on 25 march 2012
                          *Reason: check the condition for Delivery channel
                          */
            AND delivery_channel = p_delivery_channel
            AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
		
		END IF;

         IF v_rrn_cnt > 0
         THEN
            v_resp_cde := '22';
            v_err_msg :=
                  'Duplicate RRN from the Terminal '
               || p_term_id
               || ' on '
               || p_tran_date;
            RAISE exp_reject_record;
         END IF;
         EXCEPTION--Added Exception by Arunprasath on 25 june 2013
     WHEN EXP_REJECT_RECORD THEN
     RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting RRN ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;
      END;

      --En find prod code and card type for the card number
      
    ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------           
 
      Begin
      
           select count(1)
           into  v_dup_comp_check
           from cms_preauth_trans_hist
           where CPH_ORGNL_CARD_NO = v_orgnl_hash_pan
           and   CPH_ORGNL_TXN_DATE = p_orgnl_trandate
           and   CPH_ORGNL_TXN_TIME = p_orgnl_trantime
           and   CPH_ORGNL_RRN = p_orgnl_rrn
           and   CPH_TRAN_CODE = p_txn_code
           and   CPH_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
           and   CPH_COMP_COUNT = p_comp_count
           and   CPH_TRANSACTION_FLAG ='C';       
           

           if v_dup_comp_check > 0
           then
           
               V_RESP_CDE := '155';
               V_ERR_MSG  := 'Successful preauth completion already done';
               RAISE EXP_REJECT_RECORD;              
           
           end if;
      
      
      exception when  EXP_REJECT_RECORD
      then
          raise;
      when others
      then
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while fetching duplicate completion count ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;      
      
      End;

    ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------            

      /*  
          --Sn Check PreAuth Completion txn
          BEGIN
             --First check for trandate with rrn or based on rrn and hasehd pan

             --Added by T.Narayanan for the changes completion with out pre-auth beg
             SELECT COUNT (*)
               INTO v_count
               FROM cms_preauth_transaction
              WHERE cpt_mbr_no = p_mbr_numb
                AND cpt_inst_code = p_inst_code
                AND (    (   (cpt_txn_date = p_orgnl_trandate
                              AND cpt_rrn = p_orgnl_rrn
                              AND cpt_card_no = v_orgnl_hash_pan -- Added on 03-Jan-2013 for FSS-833
                             )
                          OR (    cpt_rrn = p_orgnl_rrn
                              AND cpt_card_no = v_orgnl_hash_pan
                             )
                         )
                     AND  cpt_preauth_validflag <> 'N'
                    );


             IF v_count > 0
             THEN
                v_pre_auth_check := 'Y';
             ELSE
                v_pre_auth_check := 'N';
             END IF;

             --Added by T.Narayanan for the changes completion with out pre-auth end
             SELECT cpt_txn_amnt, cpt_preauth_validflag, cpt_totalhold_amt,
                    cpt_expiry_flag
               INTO v_preauth_amount, v_preauth_valid_flag, v_hold_amount,
                    v_preauth_expiry_flag
               FROM cms_preauth_transaction
              WHERE     cpt_mbr_no = p_mbr_numb
                    AND cpt_inst_code = p_inst_code
                    AND ( cpt_txn_date = p_orgnl_trandate
                         AND cpt_rrn = p_orgnl_rrn
                         AND cpt_card_no = v_orgnl_hash_pan   -- Added on 03-Jan-2013 for FSS-833
                         AND cpt_preauth_validflag <> 'N'
                        )
                 OR (    cpt_rrn = p_orgnl_rrn
                     AND cpt_card_no = v_orgnl_hash_pan
                     AND cpt_preauth_validflag <> 'N'
                    );
          EXCEPTION
             -- by T.Narayanan for pre-auth without completion
             WHEN NO_DATA_FOUND
             THEN
                v_err_msg := '';
             -- V_RESP_CDE := '21'; --Ineligible Transaction
             -- V_ERR_MSG  := 'No data found in preauth details';
             -- RAISE EXP_REJECT_RECORD; --Commented by Deepa on Sep-14-2012 as the PreauthCompletion is getting declined without the original preauth transaction
             WHEN TOO_MANY_ROWS
             THEN
                v_resp_cde := '21';                      --Ineligible Transaction
                v_err_msg := 'More than one record found in preauth details ';
                RAISE exp_reject_record;
             WHEN OTHERS
             THEN
                v_resp_cde := '21';                      --Ineligible Transaction
                v_err_msg := 'Error while selecting the PreAuth details';
                RAISE exp_reject_record;
          END;
     */     
     
     
     --SN :- Change in rules check as per review observation for MVHOST-354 
     
    -----------------------------------------      
    --SN: Added on 15-Feb-2013 for FSS-781
    -----------------------------------------    
  
      BEGIN

         SELECT min(cpt_ins_date)  
         INTO  v_oldest_preauth
         FROM  VMSCMS.CMS_PREAUTH_TRANSACTION                  --Added for VMS-5739/FSP-991
         WHERE cpt_mbr_no    = p_mbr_numb
         AND   cpt_inst_code = p_inst_code
         AND   cpt_rrn       = p_orgnl_rrn
         AND   cpt_card_no   = v_orgnl_hash_pan
         AND   cpt_preauth_validflag <> 'N'
         AND   cpt_expiry_flag = 'N';             
		IF SQL%ROWCOUNT = 0 THEN
		SELECT min(cpt_ins_date)  
         INTO  v_oldest_preauth
         FROM  VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                  --Added for VMS-5739/FSP-991
         WHERE cpt_mbr_no    = p_mbr_numb
         AND   cpt_inst_code = p_inst_code
         AND   cpt_rrn       = p_orgnl_rrn
         AND   cpt_card_no   = v_orgnl_hash_pan
         AND   cpt_preauth_validflag <> 'N'
         AND   cpt_expiry_flag = 'N';  
		END IF;
             
         IF v_oldest_preauth is null
         THEN 
                 
             SELECT min(cpt_ins_date)
             INTO   v_oldest_preauth
             FROM VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
             WHERE cpt_mbr_no    = p_mbr_numb
             AND   cpt_inst_code = p_inst_code
             AND   CPT_APPROVE_AMT   = v_tran_amt  --p_txn_amt modified for 10871
             AND   cpt_card_no   = v_orgnl_hash_pan
             AND   cpt_preauth_validflag <> 'N'
             AND   cpt_expiry_flag = 'N' ;  
				IF SQL%ROWCOUNT = 0 THEN
				   SELECT min(cpt_ins_date)
             INTO   v_oldest_preauth
             FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST            --Added for VMS-5739/FSP-991
             WHERE cpt_mbr_no    = p_mbr_numb
             AND   cpt_inst_code = p_inst_code
             AND   CPT_APPROVE_AMT   = v_tran_amt  --p_txn_amt modified for 10871
             AND   cpt_card_no   = v_orgnl_hash_pan
             AND   cpt_preauth_validflag <> 'N'
             AND   cpt_expiry_flag = 'N' ;  
				END IF;
                 
             IF v_oldest_preauth is null
             THEN 
                     
                 SELECT min(cpt_ins_date)
                 INTO   v_oldest_preauth
                 FROM   VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                 WHERE  cpt_mbr_no      =  p_mbr_numb
                 AND    cpt_inst_code   =  p_inst_code
                 AND    cpt_card_no     =  v_orgnl_hash_pan
                 AND    cpt_terminalid  =  p_orgnl_termid
                 AND    cpt_mcc_code    =  p_orgnl_mcc_code
                 AND    cpt_preauth_validflag <> 'N'
                 AND   cpt_expiry_flag = 'N'; 
					IF SQL%ROWCOUNT = 0 THEN
					 SELECT min(cpt_ins_date)
                 INTO   v_oldest_preauth
                 FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST            --Added for VMS-5739/FSP-991
                 WHERE  cpt_mbr_no      =  p_mbr_numb
                 AND    cpt_inst_code   =  p_inst_code
                 AND    cpt_card_no     =  v_orgnl_hash_pan
                 AND    cpt_terminalid  =  p_orgnl_termid
                 AND    cpt_mcc_code    =  p_orgnl_mcc_code
                 AND    cpt_preauth_validflag <> 'N'
                 AND   cpt_expiry_flag = 'N'; 
					END IF;
                     
                 IF   v_oldest_preauth is null
                 THEN
                      v_comp_txn_code := '11';
                          
                     BEGIN
                                
                        SP_ELAN_PREAUTHCOMP_TXN  (p_card_no,
                                                  p_mcc_code,
                                                  p_curr_code,
                                                  v_tran_date,
                                                  v_comp_txn_code,
                                                  p_inst_code,
                                                  p_tran_date,
                                                  v_tran_amt,
                                                  p_delivery_channel,
                                                  p_merc_id,
                                                  p_country_code,
                                                  p_hold_amount,
                                                  v_hold_days,
                                                  v_resp_cde,
                                                  v_err_msg
                                                 );

                               
                        IF (v_resp_cde <> '1' OR TRIM (v_err_msg) <> 'OK')
                        THEN
                                
                           v_err_msg := 'From Completion '||v_err_msg;
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
                               'Error from pre_auth_comp process ' || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;                          

                     SELECT min(cpt_ins_date)
                     INTO   v_oldest_preauth
                     FROM   VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                     WHERE cpt_mbr_no    = p_mbr_numb
                     AND   cpt_inst_code = p_inst_code
                     AND   cpt_card_no   = v_orgnl_hash_pan
                     AND   cpt_mcc_code  = p_orgnl_mcc_code
                     AND   cpt_approve_amt = p_hold_amount
                     AND   cpt_preauth_validflag <> 'N'
                     AND   cpt_expiry_flag = 'N';   
						IF SQL%ROWCOUNT = 0 THEN
						SELECT min(cpt_ins_date)
                     INTO   v_oldest_preauth
                     FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST           --Added for VMS-5739/FSP-991
                     WHERE cpt_mbr_no    = p_mbr_numb
                     AND   cpt_inst_code = p_inst_code
                     AND   cpt_card_no   = v_orgnl_hash_pan
                     AND   cpt_mcc_code  = p_orgnl_mcc_code
                     AND   cpt_approve_amt = p_hold_amount
                     AND   cpt_preauth_validflag <> 'N'
                     AND   cpt_expiry_flag = 'N';
						END IF;
                             
                     --SN: Added for MVHOST-354                             
                             
                     if v_oldest_preauth is null
                     then
                             
                          v_incr_tran_amt := v_tran_amt + (v_tran_amt*5/100); 
                                  
                          v_decr_tran_amt := v_tran_amt - (v_tran_amt*5/100);
                                 
                         SELECT min(cpt_ins_date)
                         INTO   v_oldest_preauth
                         FROM   VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                         WHERE cpt_mbr_no      = p_mbr_numb
                         AND   cpt_inst_code   = p_inst_code
                         AND   cpt_card_no     = v_orgnl_hash_pan
                         AND   cpt_mcc_code    = p_orgnl_mcc_code
                         AND   to_number(cpt_approve_amt) between round(v_decr_tran_amt,2) and round(v_incr_tran_amt,2)
                         AND   cpt_preauth_validflag <> 'N'
                         AND   cpt_expiry_flag = 'N'; 
							IF SQL%ROWCOUNT = 0 THEN
							  SELECT min(cpt_ins_date)
                         INTO   v_oldest_preauth
                         FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST             --Added for VMS-5739/FSP-991
                         WHERE cpt_mbr_no      = p_mbr_numb
                         AND   cpt_inst_code   = p_inst_code
                         AND   cpt_card_no     = v_orgnl_hash_pan
                         AND   cpt_mcc_code    = p_orgnl_mcc_code
                         AND   to_number(cpt_approve_amt) between round(v_decr_tran_amt,2) and round(v_incr_tran_amt,2)
                         AND   cpt_preauth_validflag <> 'N'
                         AND   cpt_expiry_flag = 'N';
							END IF;
                             
                        if v_oldest_preauth is null
                        then
                                
                           v_pre_auth_check := 'N';
                           v_rule := 'U';
                                    
                        else
                                     
                                     
                            BEGIN
                                    
                             SELECT rowid,
                                    cpt_txn_amnt, 
                                    cpt_preauth_validflag, 
                                    cpt_totalhold_amt,
                                    cpt_expiry_flag,
                                    cpt_rrn,
                                    nvl(cpt_completion_fee,'0'), --added nvl for mantis id:15619
                                    nvl(cpt_complfree_flag,'N')
                             INTO   v_rowid,
                                    v_preauth_amount, 
                                    v_preauth_valid_flag, 
                                    v_hold_amount,
                                    v_preauth_expiry_flag,
                                    v_cpt_rrn,
                                    v_completion_fee,
                                    v_complfree_flag
                             FROM   VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                             WHERE cpt_mbr_no      = p_mbr_numb
                             AND   cpt_inst_code   = p_inst_code
                             AND   cpt_card_no     = v_orgnl_hash_pan
                             AND   cpt_mcc_code    = p_orgnl_mcc_code
                             AND   to_number(cpt_approve_amt) between round(v_decr_tran_amt,2) and round(v_incr_tran_amt,2)
                             AND   cpt_ins_date  = v_oldest_preauth
                             AND   cpt_preauth_validflag <> 'N'
                             AND   cpt_expiry_flag = 'N'
                             AND    rownum < 2;
							 IF SQL%ROWCOUNT = 0 THEN
							 SELECT rowid,
                                    cpt_txn_amnt, 
                                    cpt_preauth_validflag, 
                                    cpt_totalhold_amt,
                                    cpt_expiry_flag,
                                    cpt_rrn,
                                    nvl(cpt_completion_fee,'0'), --added nvl for mantis id:15619
                                    nvl(cpt_complfree_flag,'N')
                             INTO   v_rowid,
                                    v_preauth_amount, 
                                    v_preauth_valid_flag, 
                                    v_hold_amount,
                                    v_preauth_expiry_flag,
                                    v_cpt_rrn,
                                    v_completion_fee,
                                    v_complfree_flag
                             FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST              --Added for VMS-5739/FSP-991
                             WHERE cpt_mbr_no      = p_mbr_numb
                             AND   cpt_inst_code   = p_inst_code
                             AND   cpt_card_no     = v_orgnl_hash_pan
                             AND   cpt_mcc_code    = p_orgnl_mcc_code
                             AND   to_number(cpt_approve_amt) between round(v_decr_tran_amt,2) and round(v_incr_tran_amt,2)
                             AND   cpt_ins_date  = v_oldest_preauth
                             AND   cpt_preauth_validflag <> 'N'
                             AND   cpt_expiry_flag = 'N'
                             AND    rownum < 2;
							 END IF;
                                        
                            EXCEPTION  WHEN OTHERS
                            THEN   
                                v_resp_cde := '21';                      
                                v_err_msg := 'Error while selecting the oldest PreAuth details for rule 5 ' 
                                             ||substr(sqlerrm,1,200);
                                RAISE exp_reject_record;                    
                            END;                      
                                  
                            v_pre_auth_check := 'Y'; 
                            v_rule := 'Rule5';     
                             
                        end if;

                       --EN: Added for MVHOST-354                                
                             
                     ELSE

                                 
                        BEGIN
                                
                         SELECT rowid,
                                cpt_txn_amnt, 
                                cpt_preauth_validflag, 
                                cpt_totalhold_amt,
                                cpt_expiry_flag,
                                cpt_rrn,
                                nvl(cpt_completion_fee,'0'), --added nvl for mantis id:15619
                                nvl(cpt_complfree_flag,'N')
                         INTO   v_rowid,
                                v_preauth_amount, 
                                v_preauth_valid_flag, 
                                v_hold_amount,
                                v_preauth_expiry_flag,
                                v_cpt_rrn,
                                v_completion_fee,
                                v_complfree_flag
                         FROM   VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                         WHERE  cpt_mbr_no    =  p_mbr_numb
                         AND    cpt_inst_code =  p_inst_code                             
                         AND    cpt_card_no   = v_orgnl_hash_pan
                         AND    cpt_mcc_code  = p_orgnl_mcc_code
                         AND    cpt_ins_date  = v_oldest_preauth
                         AND    cpt_approve_amt = p_hold_amount
                         AND    cpt_preauth_validflag <> 'N'
                         AND    cpt_expiry_flag = 'N'
                         AND    rownum < 2;
						 IF SQL%ROWCOUNT = 0 THEN
						 
                         SELECT rowid,
                                cpt_txn_amnt, 
                                cpt_preauth_validflag, 
                                cpt_totalhold_amt,
                                cpt_expiry_flag,
                                cpt_rrn,
                                nvl(cpt_completion_fee,'0'), --added nvl for mantis id:15619
                                nvl(cpt_complfree_flag,'N')
                         INTO   v_rowid,
                                v_preauth_amount, 
                                v_preauth_valid_flag, 
                                v_hold_amount,
                                v_preauth_expiry_flag,
                                v_cpt_rrn,
                                v_completion_fee,
                                v_complfree_flag
                         FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST            --Added for VMS-5739/FSP-991
                         WHERE  cpt_mbr_no    =  p_mbr_numb
                         AND    cpt_inst_code =  p_inst_code                             
                         AND    cpt_card_no   = v_orgnl_hash_pan
                         AND    cpt_mcc_code  = p_orgnl_mcc_code
                         AND    cpt_ins_date  = v_oldest_preauth
                         AND    cpt_approve_amt = p_hold_amount
                         AND    cpt_preauth_validflag <> 'N'
                         AND    cpt_expiry_flag = 'N'
                         AND    rownum < 2;
						 END IF;
                                    
                        EXCEPTION                                                 
                        WHEN OTHERS
                        THEN   
                            v_resp_cde := '21';                      
                            v_err_msg := 'Error while selecting the oldest PreAuth details for rule 4 ' 
                                         ||substr(sqlerrm,1,200);
                            RAISE exp_reject_record;                    
                        END;                      
                              
                        v_pre_auth_check := 'Y'; 
                        v_rule := 'Rule4';                            
                                 
                     END IF;  -- End Rule 4       
     
                 ELSE
                       

                    BEGIN
                        
                         SELECT rowid,
                                cpt_txn_amnt, 
                                cpt_preauth_validflag, 
                                cpt_totalhold_amt,
                                cpt_expiry_flag,
                                cpt_rrn,
                                nvl(cpt_completion_fee,'0'), --added nvl for mantis id:15619
                                nvl(cpt_complfree_flag,'N')
                         INTO   v_rowid,
                                v_preauth_amount, 
                                v_preauth_valid_flag, 
                                v_hold_amount,
                                v_preauth_expiry_flag,
                                v_cpt_rrn,
                                v_completion_fee,
                                v_complfree_flag
                         FROM   VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                         WHERE  cpt_mbr_no      =  p_mbr_numb
                         AND    cpt_inst_code   =  p_inst_code
                         AND    cpt_card_no     =  v_orgnl_hash_pan
                         AND    cpt_terminalid  =  p_orgnl_termid
                         AND    cpt_mcc_code    =  p_orgnl_mcc_code
                         AND    cpt_ins_date    =  v_oldest_preauth
                         AND    cpt_preauth_validflag <> 'N'
                         AND    cpt_expiry_flag = 'N'
                         AND    ROWNUM < 2 ; 
					IF SQL%ROWCOUNT = 0 THEN
					
                         SELECT rowid,
                                cpt_txn_amnt, 
                                cpt_preauth_validflag, 
                                cpt_totalhold_amt,
                                cpt_expiry_flag,
                                cpt_rrn,
                                nvl(cpt_completion_fee,'0'), --added nvl for mantis id:15619
                                nvl(cpt_complfree_flag,'N')
                         INTO   v_rowid,
                                v_preauth_amount, 
                                v_preauth_valid_flag, 
                                v_hold_amount,
                                v_preauth_expiry_flag,
                                v_cpt_rrn,
                                v_completion_fee,
                                v_complfree_flag
                         FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST             --Added for VMS-5739/FSP-991
                         WHERE  cpt_mbr_no      =  p_mbr_numb
                         AND    cpt_inst_code   =  p_inst_code
                         AND    cpt_card_no     =  v_orgnl_hash_pan
                         AND    cpt_terminalid  =  p_orgnl_termid
                         AND    cpt_mcc_code    =  p_orgnl_mcc_code
                         AND    cpt_ins_date    =  v_oldest_preauth
                         AND    cpt_preauth_validflag <> 'N'
                         AND    cpt_expiry_flag = 'N'
                         AND    ROWNUM < 2 ; 
					END IF;						 
                         
                    EXCEPTION                                               
                    WHEN OTHERS
                    THEN   
                        v_resp_cde := '21';                      
                        v_err_msg := 'Error while selecting the oldest PreAuth details for rule 3 ' 
                                     ||substr(sqlerrm,1,200);
                        RAISE exp_reject_record;                    
                    END;                      
                      
                    v_pre_auth_check := 'Y';
                    v_rule := 'Rule3';
                     
                 END IF;  -- End Rule 3
                     
             ELSE
                 
                BEGIN
                     
                  SELECT rowid,
                         cpt_txn_amnt, 
                         cpt_preauth_validflag, 
                         cpt_totalhold_amt,
                         cpt_expiry_flag,
                         cpt_rrn,
                         nvl(cpt_completion_fee,'0'), --added nvl for mantis id:15619
                         nvl(cpt_complfree_flag,'N')
                  INTO   v_rowid,
                         v_preauth_amount, 
                         v_preauth_valid_flag, 
                         v_hold_amount,
                         v_preauth_expiry_flag,
                         v_cpt_rrn,
                         v_completion_fee,
                         v_complfree_flag
                  FROM  VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                  WHERE cpt_mbr_no    = p_mbr_numb
                  AND   cpt_inst_code = p_inst_code
                  AND   CPT_APPROVE_AMT   = v_tran_amt --p_txn_amt modified for 10871
                  AND   cpt_card_no   = v_orgnl_hash_pan
                  AND   cpt_ins_date  = v_oldest_preauth
                  AND   cpt_preauth_validflag <> 'N'
                  AND   cpt_expiry_flag = 'N'
                  AND   rownum < 2 ;
				  IF SQL%ROWCOUNT = 0 THEN
				  
                  SELECT rowid,
                         cpt_txn_amnt, 
                         cpt_preauth_validflag, 
                         cpt_totalhold_amt,
                         cpt_expiry_flag,
                         cpt_rrn,
                         nvl(cpt_completion_fee,'0'), --added nvl for mantis id:15619
                         nvl(cpt_complfree_flag,'N')
                  INTO   v_rowid,
                         v_preauth_amount, 
                         v_preauth_valid_flag, 
                         v_hold_amount,
                         v_preauth_expiry_flag,
                         v_cpt_rrn,
                         v_completion_fee,
                         v_complfree_flag
                  FROM  VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST             --Added for VMS-5739/FSP-991
                  WHERE cpt_mbr_no    = p_mbr_numb
                  AND   cpt_inst_code = p_inst_code
                  AND   CPT_APPROVE_AMT   = v_tran_amt --p_txn_amt modified for 10871
                  AND   cpt_card_no   = v_orgnl_hash_pan
                  AND   cpt_ins_date  = v_oldest_preauth
                  AND   cpt_preauth_validflag <> 'N'
                  AND   cpt_expiry_flag = 'N'
                  AND   rownum < 2 ;
				  END IF;
                      
                EXCEPTION                                           
                WHEN OTHERS
                THEN   
                    v_resp_cde := '21';                      
                    v_err_msg := 'Error while selecting the oldest PreAuth details for rule 2 ' 
                                 ||substr(sqlerrm,1,200);
                    RAISE exp_reject_record;                    
                END; 
                    
                v_pre_auth_check := 'Y';   
                v_rule := 'Rule2';          
             
             END IF;    -- End Rule 2      
             
         ELSE

            BEGIN
                 
              SELECT rowid,
                     cpt_txn_amnt, 
                     cpt_preauth_validflag, 
                     cpt_totalhold_amt,
                     cpt_expiry_flag,
                     cpt_rrn,
                     nvl(cpt_completion_fee,'0'), --added nvl for mantis id:15619
                     nvl(cpt_complfree_flag,'N')
              INTO   v_rowid,
                     v_preauth_amount, 
                     v_preauth_valid_flag, 
                     v_hold_amount,
                     v_preauth_expiry_flag,
                     V_cpt_rrn,
                     v_completion_fee,
                     v_complfree_flag
              FROM  VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
              WHERE cpt_mbr_no    = p_mbr_numb
              AND   cpt_inst_code = p_inst_code                 
              AND   cpt_rrn       = p_orgnl_rrn
              AND   cpt_card_no   = v_orgnl_hash_pan
              AND   cpt_ins_date  = v_oldest_preauth
              AND   cpt_preauth_validflag <> 'N'
              AND   cpt_expiry_flag = 'N'
              and   rownum < 2;
			  IF SQL%ROWCOUNT = 0 THEN
			  SELECT rowid,
                     cpt_txn_amnt, 
                     cpt_preauth_validflag, 
                     cpt_totalhold_amt,
                     cpt_expiry_flag,
                     cpt_rrn,
                     nvl(cpt_completion_fee,'0'), --added nvl for mantis id:15619
                     nvl(cpt_complfree_flag,'N')
              INTO   v_rowid,
                     v_preauth_amount, 
                     v_preauth_valid_flag, 
                     v_hold_amount,
                     v_preauth_expiry_flag,
                     V_cpt_rrn,
                     v_completion_fee,
                     v_complfree_flag
              FROM  VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST            --Added for VMS-5739/FSP-991
              WHERE cpt_mbr_no    = p_mbr_numb
              AND   cpt_inst_code = p_inst_code                 
              AND   cpt_rrn       = p_orgnl_rrn
              AND   cpt_card_no   = v_orgnl_hash_pan
              AND   cpt_ins_date  = v_oldest_preauth
              AND   cpt_preauth_validflag <> 'N'
              AND   cpt_expiry_flag = 'N'
              and   rownum < 2;
			  END IF;
                  
            EXCEPTION                                      
            WHEN OTHERS
            THEN   
                v_resp_cde := '21';                      --Ineligible Transaction
                v_err_msg := 'Error while selecting the oldest PreAuth details for rule 1 '||substr(sqlerrm,1,200);
                RAISE exp_reject_record;                    
            END; 
                
            v_pre_auth_check := 'Y';
            v_rule := 'Rule1';
             
             
         END IF;  -- End Rule 1
      
      exception when others
      then 
      
        v_resp_cde := '21';                      --Ineligible Transaction
        v_err_msg := 'Error while rule wise check '||substr(sqlerrm,1,100);
        RAISE exp_reject_record;
      
      END;

    -----------------------------------------      
    --EN: Added on 15-Feb-2013 for FSS-781
    -----------------------------------------    
    
    --EN :- Change in rules check as per review observation for MVHOST-354

      --Commented by srinivasuk
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
                        V_FEE_DESC, -- Added for MVCSD-4471
                        v_complfree_flag
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
                              --Added Deepa on Aug-23-2012 to calculate the waiver based on tran date
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
   
   
   
--Sn added to calculate the fee to be debit from account
/*  Commented for mantis id:15601
    IF(v_total_fee=v_completion_fee) THEN
        v_fee_reverse_amount:=0;
        v_comp_total_fee:=0;
        v_complfee_increment_type:='N';
        
    ELSIF(v_total_fee > v_completion_fee) THEN
        v_fee_reverse_amount:=0;
        v_comp_total_fee:=v_total_fee-v_completion_fee;
        v_complfee_increment_type:='D';
        
    ELSIF(v_total_fee < v_completion_fee) THEN
        v_fee_reverse_amount:=v_completion_fee-v_total_fee;
        v_comp_total_fee:=v_fee_reverse_amount;
        v_complfee_increment_type:='C';
        
     
    END IF;*/
    
    
   /*  -- added for mantis id :15601
     if v_feeamnt_type <> 'O' then
        if  TO_NUMBER (p_comp_count) <> 0  then
        
        if  TO_NUMBER (p_comp_count) <> 1 then
        
          v_fee_amt :=0;
       
         end if;
            
        end if;
    end if;
    
    dbms_output.put_line('v_feeamnt_type'||v_feeamnt_type);
    
    -- added for mantis id :15601
     if  (v_feeamnt_type='A' or v_feeamnt_type='M' or v_feeamnt_type='N' OR v_feeamnt_type ='C'  )
                     and  (TO_NUMBER (p_comp_count) = 0 OR  TO_NUMBER (p_comp_count) = 1 ) then
     
          
            IF(v_total_fee=v_completion_fee) THEN
                v_fee_reverse_amount:=0;
                v_comp_total_fee:=0;
                v_complfee_increment_type:='N';
                
            ELSIF(v_total_fee > v_completion_fee) THEN
                v_fee_reverse_amount:=0;
                v_comp_total_fee:=v_total_fee-v_completion_fee;
                v_complfee_increment_type:='D';
                
            ELSIF(v_total_fee < v_completion_fee) THEN
                v_fee_reverse_amount:=v_completion_fee-v_total_fee;
                v_comp_total_fee:=v_fee_reverse_amount;
                v_complfee_increment_type:='C';
                
             
            END IF;   
     
     elsif v_feeamnt_type='O' then
     
              if  v_completion_fee > v_total_fee then
               
                v_total_per_fee  := v_completion_fee - v_total_fee;
                v_completion_fee := v_total_fee;
                v_comp_total_fee :=v_total_fee;
                v_complfee_increment_type:='N';
                
               elsif   v_completion_fee < v_total_fee  then
                    
               v_comp_total_fee :=v_total_fee -v_completion_fee;
               v_total_per_fee  := 0;
               v_complfee_increment_type:='D';
               
               elsif v_completion_fee = v_total_fee then
               
                 v_total_per_fee  := v_completion_fee - v_total_fee;
             --   v_completion_fee := v_total_fee;
              --  v_comp_total_fee :=v_total_fee;
                 v_complfee_increment_type:='N';
               
                end if;
                
              
           
     end if;*/
     --SN  added for  for mantis id:15619
     if v_feeamnt_type = 'N'  then
     
      if  TO_NUMBER (p_comp_count) <> 0  then
        
        if  TO_NUMBER (p_comp_count) <> 1 then
                                           -- modified for mantis id:15764
            if p_last_indicator ='L' then
            
              v_total_hold_fee:=0;
              
             else
             
              v_fee_amt :=0;
              v_total_fee :=0;
              v_total_hold_fee :=v_completion_fee;
              
             end if;
        else
         v_total_hold_fee:=0;
         end if;
      else
        v_total_hold_fee :=0;      
        end if;
     
     else
     
          IF(v_total_fee = v_completion_fee) THEN
          
               v_total_hold_fee :=0;
               v_comp_total_fee :=0;
               v_complfee_increment_type:='N';
                              
          ELSIF( v_total_fee > v_completion_fee) THEN
                v_total_hold_fee :=0;
                v_comp_total_fee :=v_total_fee-v_completion_fee;
                v_complfee_increment_type:='D';
                
          ELSIF(v_total_fee < v_completion_fee) THEN
               
               v_total_hold_fee := v_completion_fee - v_total_fee;      
               v_completion_fee :=v_total_fee;
               v_comp_total_fee :=v_total_fee;
               v_complfee_increment_type:='N';
                  
            END IF;   
     
     end if;
    --EN added for mantis id:15619
    


--En added to calculate the fee to be debit from account

      --Sn find total transaction    amount
      IF v_dr_cr_flag = 'CR'
      THEN
         v_total_amt := v_tran_amt - v_total_fee;
         v_upd_amt := v_acct_balance + v_total_amt;
         v_upd_ledger_amt := v_ledger_bal + v_total_amt;
      ELSIF v_dr_cr_flag = 'DR'
      THEN
         v_total_amt := v_tran_amt + v_total_fee;
         v_upd_amt := (v_hold_amount + v_acct_balance) - v_total_amt;
         v_upd_ledger_amt := (v_hold_amount + v_ledger_bal) - v_total_amt;
         p_resp_msg := TO_CHAR (v_acct_balance);                            --Added on 08-Mar-2013 for defect 0010555
         
      ELSIF v_dr_cr_flag = 'NA'
      THEN
         IF v_total_fee = 0
         THEN
            v_total_amt := 0;
         ELSE
            v_total_amt := v_total_fee;
         END IF;

         v_upd_amt := v_acct_balance - v_total_amt;
         v_upd_ledger_amt := v_upd_ledger_amt - v_total_amt;
         --p_resp_msg := TO_CHAR (v_upd_amt);                               --Commented on 08-Mar-2013 for defect 0010555 same is not require
      ELSE
         v_resp_cde := '12';                         --Ineligible Transaction
         v_err_msg := 'Invalid transflag    txn code ' || p_txn_code;
         RAISE exp_reject_record;
      END IF;

      v_totalamt:=TRIM (TO_CHAR (v_total_amt, '999999999999999990.99')); --added by Pankaj S. for 10871
      
      --En find total transaction    amout
      IF TO_NUMBER (p_comp_count) = 0 OR p_last_indicator = 'L'
      THEN
         v_last_comp_ind := 'L';
      ELSE
         v_last_comp_ind := 'N';
      END IF;

      --end

      --Check For Last completion ind
      BEGIN
         SELECT DECODE (v_pre_auth_check,
                        'Y', v_hold_amount
                         || v_preauth_expiry_flag
                         || v_last_comp_ind,
                        0
                       )
           INTO v_proxy_hold_amount
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while generating V_PROXY_HOLD_AMOUNT '
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;
    --Sn Added for FSS 837  
    v_fee_reverse_amount:=nvl(v_fee_reverse_amount,0);
    v_completion_fee:=nvl(v_completion_fee,0);
    --En Added for FSS 837

      BEGIN
         --T.Narayanan added for completion without pre-auth completion end
         sp_upd_transaction_accnt_auth (p_inst_code,
                                        v_tran_date,
                                        v_prod_code,
                                        v_prod_cattype,
                                        V_TRAN_AMT, --    - v_fee_reverse_amount, --Modified for FSS 837
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
                                        --T.Narayanan changed this for completion without pre-auth
                                        v_proxy_hold_amount,
                                        --For PreAuth Completion transaction
                                        p_msg,
                                        v_resp_cde,
                                        v_err_msg,
                                        v_completion_fee
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
      --Sn generate auth id
      BEGIN
         --SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO AUTHID_DATE FROM DUAL;

         --    SELECT TO_CHAR(SYSDATE, 'YYYYMMDD')|| LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;

         v_auth_id_gen_flag := 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';                            -- Server Declined
            RAISE exp_reject_record;
      END;

      --En generate auth id

      --Sn find narration
      BEGIN
      
       /*   --SN :- Commented since same is already fetched at line 356 as per review observations given for MVHOST-354
       
         SELECT ctm_tran_desc
           INTO v_trans_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
            
         */ --EN :- Commented since same is already fetched at line 356 as per review observations given for MVHOST-354  

         IF TRIM (v_trans_desc) IS NOT NULL
         THEN
            v_narration := v_trans_desc || '/';
         END IF;

         IF TRIM (p_merchant_name) IS NOT NULL
         THEN
            v_narration := v_narration || p_merchant_name || '/';
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
         /*                  -- Comemnted since query is commented review observation MVHOST-354
         WHEN NO_DATA_FOUND
         THEN
            v_trans_desc := 'Transaction type ' || p_txn_code;
            
         */                  -- Comemnted since query is commented review observation MVHOST-354  
         
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                --'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);     --review observation changes MVHOST-354   
                'Error during preparing the narration ' || SUBSTR (SQLERRM, 1, 200); --Added review observation changes MVHOST-354
            RAISE exp_reject_record;
      END;

      --En find narration
      v_timestamp:=systimestamp;  --added by Pankaj S. for 10871
      
      --Sn create a entry in statement log
      IF v_dr_cr_flag <> 'NA'
      THEN
         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_opening_bal, 
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
                         csl_panno_last4digit,
                         csl_prod_code,csl_card_type,csl_acct_type,csl_time_stamp --added by Pankaj S. for 10871
                        )
                 --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
            VALUES      (v_hash_pan, v_ledger_bal, --v_acct_balance replaced by Pankaj S. with v_ledger_bal for 10871 
                         v_tran_amt,
                         v_dr_cr_flag, v_tran_date,
                         DECODE (v_dr_cr_flag,
                                 'DR', v_ledger_bal - v_tran_amt,  --v_acct_balance replaced by Pankaj S. with v_ledger_bal for 10871
                                 'CR', v_ledger_bal + v_tran_amt,  --v_acct_balance replaced by Pankaj S. with v_ledger_bal for 10871
                                 'NA', v_ledger_bal                --v_acct_balance replaced by Pankaj S. with v_ledger_bal for 10871
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
                         ),
                         v_prod_code,v_prod_cattype,v_acct_type,v_timestamp --added by Pankaj S. for 10871
                        );
         --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while inserting into statement log for tran amt '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            sp_daily_bin_bal (p_card_no,
                              v_tran_date,
                              v_tran_amt,
                              v_dr_cr_flag,
                              p_inst_code,
                              '',
                              v_err_msg
                             );

            IF v_err_msg <> 'OK'
            THEN
               v_resp_cde := '21';
               v_err_msg := 'Error while executing  SP_DAILY_BIN_BAL ';
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
                     'Error while calling SP_DAILY_BIN_BAL '
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
                           'DR', v_ledger_bal - v_tran_amt, --v_acct_balance replaced by Pankaj S. with v_ledger_bal for 10871
                           'CR', v_ledger_bal + v_tran_amt, --v_acct_balance replaced by Pankaj S. with v_ledger_bal for 10871
                           'NA', v_ledger_bal               --v_acct_balance replaced by Pankaj S. with v_ledger_bal for 10871
                          )
              INTO v_fee_opening_bal
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '12';
               v_err_msg :=
                     'Error in acct balance calculation based on transflag'
                  || v_dr_cr_flag;
               RAISE exp_reject_record;
         END;

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
                            csl_panno_last4digit,
                             csl_prod_code,csl_card_type,csl_acct_type,csl_time_stamp --added by Pankaj S. for 10871
                           )
                    --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
               VALUES      (v_hash_pan, v_fee_opening_bal, v_total_fee,
                            'DR', v_tran_date,
                            v_fee_opening_bal - v_total_fee,
                           -- 'Complimentary ' || v_duration || ' ' --Commented for MVCSD-4471
                           -- || v_narration, --Commented for MVCSD-4471
                            V_FEE_DESC, --Added for MVCSD-4471
                            -- Modified by Trivikram  on 27-July-2012
                            p_inst_code, v_encr_pan, p_rrn,
                            v_auth_id, p_tran_date,
                            p_tran_time, 'Y',
                            p_delivery_channel, p_txn_code, v_card_acct_no,
                            --Added by Deepa to log the account number ,INS_DATE and INS_USER
                            1, SYSDATE, p_merchant_name,
                            --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                            p_merchant_city, p_atmname_loc,
                            SUBSTR (p_card_no,
                                    LENGTH (p_card_no) - 3,
                                    LENGTH (p_card_no)
                                   ),
                           v_prod_code,v_prod_cattype,v_acct_type,v_timestamp --added by Pankaj S. for 10871
                           );
            --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
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
               --En find fee opening balance
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
                                   csl_prod_code,csl_card_type,csl_acct_type,csl_time_stamp --added by Pankaj S. for 10871
                                  )
                           VALUES (v_hash_pan, v_fee_opening_bal,
                                                                 -- V_FLAT_FEES,
                                                                 v_flat_fees,
                                   'DR', v_tran_date,
                                   v_fee_opening_bal - v_flat_fees,
                                 --  'Fixed Fee debited for ' || v_narration, --Commented for MVCSD-4471
                                   'Fixed Fee debited for ' || V_FEE_DESC, --Added for MVCSD-4471
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
                                   ),
                                   v_prod_code,v_prod_cattype,v_acct_type,v_timestamp --added by Pankaj S. for 10871
                                  );
                                  
                   EXCEPTION WHEN OTHERS                       --Excecption block added as per review observations for FSS-1246     
                   THEN
                        v_resp_cde := '21';
                        v_err_msg :='Problem while inserting into statement log for Fixed fee '|| SUBSTR (SQLERRM, 1, 100);
                   RAISE exp_reject_record;      
                                  
                   END;    
                  --En Entry for Fixed Fee
                  v_fee_opening_bal := v_fee_opening_bal - v_flat_fees;


                   BEGIN
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
                                   csl_panno_last4digit,
                                   csl_prod_code,csl_card_type,csl_acct_type,csl_time_stamp --added by Pankaj S. for 10871
                                  )
                           --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                      VALUES      (v_hash_pan, v_fee_opening_bal, v_per_fees,
                                   'DR', v_tran_date,
                                   v_fee_opening_bal - v_per_fees,
                                  -- 'Percetage Fee debited for ' || v_narration, --Commented for MVCSD-4471
                                   'Percentage Fee debited for ' || V_FEE_DESC, --Added for MVCSD-4471
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
                                   ),
                                   v_prod_code,v_prod_cattype,v_acct_type,v_timestamp --added by Pankaj S. for 10871
                                  );
                             --En Entry for Percentage Fee
                             
                   EXCEPTION WHEN OTHERS                    --Excecption block added as per review observations for FSS-1246
                   THEN
                        v_resp_cde := '21';
                        v_err_msg :='Problem while inserting into statement log for Percetage fee '|| SUBSTR (SQLERRM, 1, 100);
                   RAISE exp_reject_record;      
                                  
                   END;                             
                             
               ELSE
                 
                 if  v_total_fee >0 then --added  for mantis id:15619
                   BEGIN
                      --Sn create entries for FEES attached
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
                                   csl_panno_last4digit,
                                   csl_prod_code,csl_card_type,csl_acct_type,csl_time_stamp --added by Pankaj S. for 10871
                                  )
                           --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                      VALUES      (v_hash_pan, v_fee_opening_bal,
                                   v_total_fee, 'DR',
                                   v_tran_date, v_fee_opening_bal - v_total_fee,
                                  -- 'Fee debited for ' || v_narration, --Commented for MVCSD-4471
                                   V_FEE_DESC, --Added for MVCSD-4471
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
                                   SUBSTR (p_card_no,
                                           LENGTH (p_card_no) - 3,
                                           LENGTH (p_card_no)
                                          ),
                                   v_prod_code,v_prod_cattype,v_acct_type,v_timestamp --added by Pankaj S. for 10871        
                                  );
                            --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                            
                   EXCEPTION WHEN OTHERS             --Excecption block added as per review observations for FSS-1246
                   THEN
                        v_resp_cde := '21';
                        v_err_msg :='Problem occured while inserting into statement log '|| SUBSTR (SQLERRM, 1, 100);
                   RAISE exp_reject_record;      
                                  
                   END;  
                 end if;                             
                            
               END IF;
               
            EXCEPTION WHEN exp_reject_record        --Excecption EXP_REJECT_RECORD added as per review observations for FSS-1246
            THEN
                RAISE;
            
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
                      ctd_cust_acct_number,
                                           /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                           ctd_network_id,
                      ctd_interchange_feeamt, ctd_merchant_zip,
                      ctd_merchant_id, ctd_country_code, ctd_completion_fee,ctd_complfee_increment_type
                     /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_msg, p_txn_mode, p_tran_date,
                      p_tran_time, v_hash_pan,
                      v_tran_amt,--p_txn_amt modified for 10871 
                      p_curr_code, v_tran_amt,
                      v_log_actual_fee, v_log_waiver_amt,
                      v_servicetax_amount, v_cess_amount,
                      v_total_amt, v_card_curr, 'Y',
                      'Successful', p_rrn, p_stan,
                      p_inst_code, v_encr_pan,
                      v_acct_number,
                                    /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                    p_network_id,
                      p_interchange_feeamt, p_merchant_zip,
                      p_merc_id, p_country_code,v_comp_total_fee,v_complfee_increment_type
                     /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
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

      --En create a entry for successful
      v_resp_cde := '1';

      --Add for PreAuth Transaction of CMSAuth
      BEGIN
      
         BEGIN
         
              BEGIN 
         
                INSERT INTO cms_preauth_trans_hist
                        (cph_card_no, cph_mbr_no, cph_inst_code,
                         cph_card_no_encr, cph_preauth_validflag,
                         cph_completion_flag, cph_txn_amnt, cph_approve_amt,
                         cph_rrn, cph_txn_date, cph_txn_time, cph_orgnl_rrn,
                         cph_orgnl_txn_date, cph_orgnl_txn_time,
                         cph_orgnl_card_no, cph_terminalid,
                         cph_orgnl_terminalid, cph_comp_count,
                         cph_transaction_flag, cph_totalhold_amt,
                         cph_merchant_name,
                                           --Added by Deepa on May-09-2012 for statement changes
                                           cph_merchant_city,
                         cph_merchant_state, cph_delivery_channel,
                         cph_tran_code,
                         cph_panno_last4digit,
                         CPH_ACCT_NO,
                         CPH_ORGNL_MCCCODE,  -- Added on 27-Feb-2013 for FSS-781
                         CPH_MATCH_RRN,      -- Added on 27-Feb-2013 for FSS-781
                         cph_completion_fee -- Added for FSS-837 on 24/06/2014
                        )
                 VALUES (v_hash_pan, p_mbr_numb, p_inst_code,
                         v_encr_pan, 'N',
                         'C', v_tran_amt, --p_txn_amt modified for 10871
                         --TRIM (TO_CHAR (nvl(v_total_amt,0) ,'999999999999999990.99')), --modified for 10871
                               --Commented and modified on 24.07.2013 for 11692
                         TRIM (TO_CHAR (nvl(v_tran_amt,0) ,'999999999999999990.99')),
                         p_rrn, p_tran_date, p_tran_time, p_orgnl_rrn,
                         p_orgnl_trandate, p_orgnl_trantime,
                         v_orgnl_hash_pan, p_term_id,
                         p_orgnl_termid, p_comp_count,
                         'C', '0.00', --modified for 10871
                         p_merchant_name,
                                         --Added by Deepa on May-09-2012 for statement changes
                                         p_merchant_city,
                         p_atmname_loc, p_delivery_channel,
                         p_txn_code,
                         (SUBSTR (p_card_no,
                                  LENGTH (p_card_no) - 3,
                                  LENGTH (p_card_no)
                                 )
                         ),
                        V_ACCT_NUMBER,           -- Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                        p_orgnl_mcc_code,        -- Added on 27-Feb-2013 for FSS-781
                        v_cpt_rrn,             -- Added on 27-Feb-2013 for FSS-781
                        V_TOTAL_FEE
                        );
              EXCEPTION WHEN OTHERS             --Excecption block added as per review observations for FSS-1246
              THEN
                    v_resp_cde := '21';
                    v_err_msg :='Problem occured while inserting into preauth hist '|| SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;      
                                  
              END;                        
                        

            --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
            IF v_pre_auth_check = 'N'
            THEN
            
                 BEGIN
                 
                   INSERT INTO cms_preauth_transaction
                               (cpt_card_no, cpt_txn_amnt, cpt_expiry_date,
                                cpt_sequence_no, cpt_preauth_validflag,
                                cpt_inst_code, cpt_mbr_no, cpt_card_no_encr,
                                cpt_completion_flag, cpt_approve_amt, cpt_rrn,
                                cpt_txn_date, cpt_txn_time, cpt_terminalid,
                                cpt_expiry_flag, cpt_totalhold_amt,
                                cpt_transaction_flag,CPT_ACCT_NO,cpt_completion_fee--Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                               )
                        VALUES (v_hash_pan, 
                                --nvl(v_total_amt,0), --modified for 10871
                                            --Commented and modified on 24.07.2013 for 11692
                                 TRIM (TO_CHAR (nvl(v_tran_amt,0) ,'999999999999999990.99')),
                                v_preauth_date,
                                p_rrn, 'N',
                                p_inst_code, p_mbr_numb, v_encr_pan,
                                'Y', 
                                --TRIM (TO_CHAR (nvl(v_total_amt,0) ,'999999999999999990.99')) --modified for 10871
                                             --Commented and modified on 24.07.2013 for 11692
                                 TRIM (TO_CHAR (nvl(v_tran_amt,0) ,'999999999999999990.99')) 
                                , p_rrn,
                                p_tran_date, p_tran_time, p_term_id,
                                'Y', '0.00', --Modified by Pankaj S. for 10871
                                'C',V_ACCT_NUMBER,v_total_fee--Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                                );
                            
                 EXCEPTION WHEN OTHERS             --Excecption block added as per review observations for FSS-1246
                 THEN
                        v_resp_cde := '21';
                        v_err_msg :='Problem occured while inserting into preauth txn '|| SUBSTR (SQLERRM, 1, 100);
                   RAISE exp_reject_record;      
                                      
                 END;                           
                          
            ELSE
            
               IF v_tran_amt >= v_hold_amount  --p_txn_amt modified for 10871
               THEN
               
                     --SN: Added on 22Feb2013 for FSS-781
                       
                      UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION                   --Added for VMS-5739/FSP-991
                      SET  cpt_totalhold_amt = '0.00', --modified for 10871
                           cpt_transaction_flag = 'C',
                           cpt_txn_amnt = v_tran_amt, --p_txn_amt modified for 10871
                           cpt_transaction_rrn = p_rrn,
                           cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,null,'',',')||v_rule -- Added for FSS-781
                           ,cpt_completion_fee=v_total_hold_fee--decode(v_feeamnt_type ,'O',v_total_per_fee,v_total_fee) commented for mantis id:15619
                      WHERE rowid = v_rowid                         
                      AND   cpt_preauth_validflag <> 'N';
					  
					    IF SQL%ROWCOUNT = 0
                  THEN
					  UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                   --Added for VMS-5739/FSP-991
                      SET  cpt_totalhold_amt = '0.00', --modified for 10871
                           cpt_transaction_flag = 'C',
                           cpt_txn_amnt = v_tran_amt, --p_txn_amt modified for 10871
                           cpt_transaction_rrn = p_rrn,
                           cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,null,'',',')||v_rule -- Added for FSS-781
                           ,cpt_completion_fee=v_total_hold_fee--decode(v_feeamnt_type ,'O',v_total_per_fee,v_total_fee) commented for mantis id:15619
                      WHERE rowid = v_rowid                         
                      AND   cpt_preauth_validflag <> 'N';
                      
                      --EN: Added on 22Feb2013 for FSS-781
                      
                     
                     
                                               
                     /* -- Commented on 22Feb2013 for FSS-781 
                      UPDATE cms_preauth_transaction
                         --SET CPT_PREAUTH_VALIDFLAG = 'N', Commnetd by srinivasuk
                      SET cpt_totalhold_amt = '0',
                          cpt_transaction_flag = 'C',
                          cpt_txn_amnt = p_txn_amt,
                          cpt_transaction_rrn = p_rrn
                       WHERE (    cpt_rrn = p_orgnl_rrn
                              AND cpt_txn_date = p_orgnl_trandate
                              AND cpt_inst_code = p_inst_code
                              AND cpt_preauth_validflag <> 'N'
                             )
                          OR (    cpt_rrn = p_orgnl_rrn
                              AND cpt_card_no = v_orgnl_hash_pan
                              AND cpt_inst_code = p_inst_code
                              AND cpt_preauth_validflag <> 'N'
                             );
                      */  -- Commented on 22Feb2013 for FSS-781            

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_err_msg :=
                           'Problem while updating data in CMS_PREAUTH_TRANSACTION 1 '
                        || SUBSTR (SQLERRM, 1, 300);
                     v_resp_cde := '21';
                     RAISE exp_reject_record;
                  END IF;
              END IF;      
                  v_sqlrowcnt := SQL%ROWCOUNT; 
                  
               ELSE
                  v_total_amt := v_hold_amount - v_tran_amt; --p_txn_amt modified for 10871

                  IF v_total_amt > 0
                  THEN
                  
                     --SN: Added on 22Feb2013 for FSS-781
                     
                     UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION                        --Added for VMS-5739/FSP-991 
                        SET cpt_transaction_flag = 'C',
                            cpt_totalhold_amt = TRIM (TO_CHAR (nvl(v_total_amt,0) ,'999999999999999990.99')),  --modified for 10871
                            cpt_txn_amnt = v_tran_amt, --p_txn_amt modified for 10871
                            cpt_transaction_rrn = p_rrn,
                            cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,null,'',',')||v_rule -- Added for FSS-781 
                             ,cpt_completion_fee=v_total_hold_fee--decode(v_feeamnt_type ,'O',v_total_per_fee,v_total_fee)    commented for mantis id:15619            
                        WHERE rowid = v_rowid;
						
						IF SQL%ROWCOUNT = 0
                     THEN
						  UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                        --Added for VMS-5739/FSP-991 
                        SET cpt_transaction_flag = 'C',
                            cpt_totalhold_amt = TRIM (TO_CHAR (nvl(v_total_amt,0) ,'999999999999999990.99')),  --modified for 10871
                            cpt_txn_amnt = v_tran_amt, --p_txn_amt modified for 10871
                            cpt_transaction_rrn = p_rrn,
                            cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,null,'',',')||v_rule -- Added for FSS-781 
                             ,cpt_completion_fee=v_total_hold_fee--decode(v_feeamnt_type ,'O',v_total_per_fee,v_total_fee)    commented for mantis id:15619            
                        WHERE rowid = v_rowid;
                          
                     --EN: Added on 22Feb2013 for FSS-781    
                     
                     
                    
                    /* -- Commented on 22Feb2013 for FSS-781 
                    
                     UPDATE cms_preauth_transaction
                        SET cpt_transaction_flag = 'C',
                            cpt_totalhold_amt = v_total_amt,
                            cpt_txn_amnt = p_txn_amt,
                            cpt_transaction_rrn = p_rrn
                      WHERE (    cpt_rrn = p_orgnl_rrn
                             AND cpt_txn_date = p_orgnl_trandate
                             AND cpt_inst_code = p_inst_code
                            )
                         OR (    cpt_rrn = p_orgnl_rrn
                             AND cpt_card_no = v_orgnl_hash_pan
                             AND cpt_inst_code = p_inst_code
                            );
                            
                     */  -- Commented on 22Feb2013 for FSS-781      

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                              'Problem while updating data in CMS_PREAUTH_TRANSACTION 2 '
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  END IF;     
                     v_sqlrowcnt := SQL%ROWCOUNT;
                     
                     
                  ELSE
                  
                     --SN: Added on 22Feb2013 for FSS-781
                     
                     UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION                        --Added for VMS-5739/FSP-991 
                     SET cpt_totalhold_amt = '0.00', --modified for 10871
                         cpt_transaction_flag = 'C',
                         cpt_txn_amnt = v_tran_amt, --p_txn_amt modified for 10871
                         cpt_transaction_rrn = p_rrn,
                         cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,null,'',',')||v_rule -- Added for FSS-781
                          ,cpt_completion_fee=v_total_hold_fee--decode(v_feeamnt_type ,'O',v_total_per_fee,v_total_fee) commented for mantis id:15619
                     WHERE rowid = v_rowid;
					 
					 IF SQL%ROWCOUNT = 0
                     THEN
					  UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                      --Added for VMS-5739/FSP-991 
                     SET cpt_totalhold_amt = '0.00', --modified for 10871
                         cpt_transaction_flag = 'C',
                         cpt_txn_amnt = v_tran_amt, --p_txn_amt modified for 10871
                         cpt_transaction_rrn = p_rrn,
                         cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,null,'',',')||v_rule -- Added for FSS-781
                          ,cpt_completion_fee=v_total_hold_fee--decode(v_feeamnt_type ,'O',v_total_per_fee,v_total_fee) commented for mantis id:15619
                     WHERE rowid = v_rowid;
                                           
                    --EN: Added on 22Feb2013 for FSS-781

                      
                    /* -- Commented on 22Feb2013 for FSS-781      
                    
                     UPDATE cms_preauth_transaction
                        --SET CPT_PREAUTH_VALIDFLAG = 'N',
                     SET cpt_totalhold_amt = '0',
                         cpt_transaction_flag = 'C',
                         cpt_txn_amnt = p_txn_amt,
                         cpt_transaction_rrn = p_rrn
                      WHERE (    cpt_rrn = p_orgnl_rrn
                             AND cpt_txn_date = p_orgnl_trandate
                             AND cpt_inst_code = p_inst_code
                            )
                         OR (    cpt_rrn = p_orgnl_rrn
                             AND cpt_card_no = v_orgnl_hash_pan
                             AND cpt_inst_code = p_inst_code
                            );
                     */  -- Commented on 22Feb2013 for FSS-781           

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                              'Problem while updating data in CMS_PREAUTH_TRANSACTION 3 '
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                   END IF;    
                     v_sqlrowcnt := SQL%ROWCOUNT;
                     
                  END IF;
               END IF;

               IF v_last_comp_ind = 'L'
               THEN
                 
                 --SN: Added on 22Feb2013 for FSS-781  
               
                  UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION                        --Added for VMS-5739/FSP-991 
                     SET cpt_preauth_validflag = 'N',
                         cpt_totalhold_amt = '0.00', --modified for 10871
                         cpt_exp_release_amount = (v_hold_amount - v_tran_amt), --p_txn_amt modified for 10871
                         cpt_completion_flag='Y',--Modified by Deepa on 26-Nov-2012 to update the Completion Flag of Preauth transaction
                         cpt_match_rule = decode (v_sqlrowcnt,'0',cpt_match_rule||decode(cpt_match_rule,null,'',',')||v_rule,cpt_match_rule) -- Added for FSS-781
                          ,cpt_completion_fee=v_total_hold_fee--decode(v_feeamnt_type ,'O',v_total_per_fee,v_total_fee) commented for mantis id:15619
                     WHERE rowid = v_rowid    
                     AND cpt_preauth_validflag = 'Y'
                     AND cpt_inst_code = p_inst_code;
					 
					 
					 IF SQL%ROWCOUNT = 0
                  THEN
					 
					    UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                       --Added for VMS-5739/FSP-991 
                     SET cpt_preauth_validflag = 'N',
                         cpt_totalhold_amt = '0.00', --modified for 10871
                         cpt_exp_release_amount = (v_hold_amount - v_tran_amt), --p_txn_amt modified for 10871
                         cpt_completion_flag='Y',--Modified by Deepa on 26-Nov-2012 to update the Completion Flag of Preauth transaction
                         cpt_match_rule = decode (v_sqlrowcnt,'0',cpt_match_rule||decode(cpt_match_rule,null,'',',')||v_rule,cpt_match_rule) -- Added for FSS-781
                          ,cpt_completion_fee=v_total_hold_fee--decode(v_feeamnt_type ,'O',v_total_per_fee,v_total_fee) commented for mantis id:15619
                     WHERE rowid = v_rowid    
                     AND cpt_preauth_validflag = 'Y'
                     AND cpt_inst_code = p_inst_code;
                     
                 --EN: Added on 22Feb2013 for FSS-781    
                     
                     
               
                 /* -- Commented on 22Feb2013 for FSS-781 
                 
                  UPDATE cms_preauth_transaction
                     SET cpt_preauth_validflag = 'N',
                         cpt_totalhold_amt = 0,
                         cpt_exp_release_amount = (v_hold_amount - p_txn_amt),
                         CPT_COMPLETION_FLAG='Y'--Modified by Deepa on 26-Nov-2012 to update the Completion Flag of Preauth transaction
                   WHERE cpt_card_no = v_orgnl_hash_pan
                     AND cpt_rrn = p_orgnl_rrn
                     AND cpt_preauth_validflag = 'Y'
                     AND cpt_inst_code = p_inst_code;
                     
                  */   -- Commented on 22Feb2013 for FSS-781 

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_err_msg :=
                           'Problem while updating data in CMS_PREAUTH_TRANSACTION 4 '
                        || SUBSTR (SQLERRM, 1, 300);
                     v_resp_cde := '21';
                     RAISE exp_reject_record;
                  END IF;
                END IF;   
                  
               END IF;
            END IF;
            
         EXCEPTION WHEN exp_reject_record       --Exception added as per review observation for FSS-1246
         THEN 
             RAISE;
         
         WHEN OTHERS
            THEN
               v_err_msg :=
                     'Problem While Updating the Pre-Auth Completion transaction details of the card'
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         --- Sn create GL ENTRIES
         IF v_resp_cde = '1'
         THEN
            --SAVEPOINT v_savepoint;
            v_business_time := TO_CHAR (v_tran_date, 'HH24:MI');

            IF v_business_time > v_cutoff_time
            THEN
               v_business_date := TRUNC (v_tran_date) + 1;
            ELSE
               v_business_date := TRUNC (v_tran_date);
            END IF;

            --En find businesses date
            
            --SN - commented for fwr-48
            
        /*    BEGIN
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
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_gl_upd_flag := 'N';
                  p_resp_code := v_resp_cde;
                  v_err_msg := v_gl_err_msg;
                  RAISE exp_reject_record;
            END; */
            
            --EN - commented for fwr-48

            --Sn find prod code and card type and available balance for the card number
            BEGIN
               SELECT     cam_acct_bal,cam_ledger_bal--Modified by Deepa on Nov-27-2012 to log the ledger bal after the completion of transaction
                     INTO v_acct_balance,v_ledger_bal
                     FROM cms_acct_mast
                     WHERE cam_acct_no = v_acct_number                             --V_acct_number comapred instead od subquery as per review observation for FSS-1246 
            --                             (SELECT cap_acct_no
            --                                FROM cms_appl_pan
            --                               WHERE cap_pan_code = v_hash_pan     --P_card_no
            --                                 AND cap_mbr_numb = p_mbr_numb
            --                                 AND cap_inst_code = p_inst_code)
                      AND cam_inst_code = p_inst_code;
               --FOR UPDATE NOWAIT;                                             -- Commented for Concurrent Processsing Issue
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_resp_cde := '14';                --Ineligible Transaction
                  v_err_msg := 'Invalid Card ';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Error while selecting data from card Master for card number '
                     || SQLERRM;
                  RAISE exp_reject_record;
            END;

            --En find prod code and card type for the card number
            IF v_output_type = 'N'
            THEN
               --Balance Inquiry
               --p_resp_msg := TO_CHAR (v_upd_amt);                               --Commented on 08-Mar-2013 for defect 0010555 same is not require  
               p_resp_msg := TO_CHAR (v_acct_balance);                            --Added on 08-Mar-2013 for defect 0010555
            END IF;
         END IF;

         --En create GL ENTRIES

         /*                                             --Sn:Commented since same is not used as per review observation for FSS-1246
         ---Sn Updation of Usage limit and amount
         BEGIN
            SELECT ctc_atmusage_amt, ctc_posusage_amt, ctc_atmusage_limit,
                   ctc_posusage_limit, ctc_business_date,
                   ctc_preauthusage_limit
              INTO v_atm_usageamnt, v_pos_usageamnt, v_atm_usagelimit,
                   v_pos_usagelimit, v_business_date_tran,
                   v_preauth_usage_limit
              FROM cms_translimit_check
             WHERE ctc_inst_code = p_inst_code
               AND ctc_pan_code = v_hash_pan                       --P_card_no
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
                     'Error while selecting 1 CMS_TRANSLIMIT_CHECK'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            IF p_delivery_channel = '02'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  v_pos_usagelimit := 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_amt = 0,
                            ctc_posusage_limit = v_pos_usagelimit,
                            ctc_atmusage_amt = 0,
                            ctc_atmusage_limit = 0,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       ),
                            ctc_preauthusage_limit = 0,
                            ctc_mmposusage_amt = 0,
                            ctc_mmposusage_limit = 0
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan             -- P_card_no
                        AND ctc_mbr_numb = p_mbr_numb;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                              'Problem while updating data in CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 1 CMS_TRANSLIMIT_CHECK'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_pos_usagelimit := v_pos_usagelimit + 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_amt = v_pos_usageamnt,
                            ctc_posusage_limit = v_pos_usagelimit
                      -- ctc_business_date =TO_DATE (P_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss'),
                     WHERE  ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan              --P_card_no
                        AND ctc_mbr_numb = p_mbr_numb;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                              'Problem while updating data in CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 2 CMS_TRANSLIMIT_CHECK'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_err_msg :=
                     'Error IN CMS_TRANSLIMIT_CHECK INNER LOOP'
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;
        */              --En:Commented since same is not used as per review observation for FSS-1246  
         
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error IN CMS_TRANSLIMIT_CHECK' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;
    

      ---En Updation of Usage limit and amount
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = TO_NUMBER (v_resp_cde);

         --p_resp_msg := TO_CHAR (v_upd_amt);               --Commented on 08-Mar-2013 for defect 0010555 same is not require        
         p_resp_msg := TO_CHAR (v_acct_balance);            --Added on 08-Mar-2013 for defect 0010555
         p_resp_id := v_resp_cde; --Added for VMS-8018
         
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_err_msg :=
                  'No data in response master for respose code' || v_resp_cde;
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
   ---
   EXCEPTION
      --<< MAIN EXCEPTION >>
      WHEN exp_reject_record
      THEN
         ROLLBACK TO v_auth_savepoint;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_acct_no
              INTO v_acct_balance, v_ledger_bal, v_acct_number
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
         
       /*                                           --Sn:Commented since same is not used as per review observation for FSS-1246
         BEGIN
            SELECT ctc_atmusage_limit, ctc_posusage_limit,
                   ctc_business_date, ctc_preauthusage_limit
              INTO v_atm_usagelimit, v_pos_usagelimit,
                   v_business_date_tran, v_preauth_usage_limit
              FROM cms_translimit_check
             WHERE ctc_inst_code = p_inst_code
               AND ctc_pan_code = v_hash_pan                       --P_card_no
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
                     'Error while selecting 2 CMS_TRANSLIMIT_CHECK '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            IF p_delivery_channel = '02'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  v_pos_usageamnt := 0;
                  v_pos_usagelimit := 1;
                  v_preauth_usage_limit := 0;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_amt = v_pos_usageamnt,
                            ctc_posusage_limit = v_pos_usagelimit,
                            ctc_atmusage_amt = 0,
                            ctc_atmusage_limit = 0,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       ),
                            ctc_preauthusage_limit = v_preauth_usage_limit,
                            ctc_mmposusage_amt = 0,
                            ctc_mmposusage_limit = 0
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan             -- P_card_no
                        AND ctc_mbr_numb = p_mbr_numb;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                              'Problem while updating data in CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 3 CMS_TRANSLIMIT_CHECK'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_pos_usagelimit := v_pos_usagelimit + 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_limit = v_pos_usagelimit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan              --P_card_no
                        AND ctc_mbr_numb = p_mbr_numb;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                              'Problem while updating data in CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 4 CMS_TRANSLIMIT_CHECK'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         END;
        */          --En:Commented since same is not used as per review observation for FSS-1246

         --Sn select response code and insert record into txn log dtl
         BEGIN
            p_resp_msg := v_err_msg;
            p_resp_code := v_resp_cde;
            p_resp_id := v_resp_cde; --Added for VMS-8018

            -- Assign the response code to the out parameter
            SELECT cms_iso_respcde
              INTO p_resp_code
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
               ---ISO MESSAGE FOR DATABASE ERROR Server Declined
               p_resp_id := '69'; --Added for VMS-8018
               ROLLBACK;
         -- RETURN;
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
                         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                         ctd_network_id, ctd_interchange_feeamt,
                         ctd_merchant_zip, ctd_merchant_id, ctd_country_code,ctd_completion_fee,ctd_complfee_increment_type
                        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                        )
                 VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                         p_msg, p_txn_mode, p_tran_date,
                         p_tran_time, v_hash_pan,
                         v_tran_amt, --p_txn_amt modified for 10871
                         p_curr_code, v_tran_amt,
                         NULL, NULL,
                         NULL, NULL,
                         v_total_amt, v_card_curr, 'E',
                         v_err_msg, p_rrn,
                         p_stan, p_inst_code,
                         v_encr_pan, v_acct_number,
                         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                         p_network_id, p_interchange_feeamt,
                         p_merchant_zip, p_merc_id, p_country_code,v_comp_total_fee,v_complfee_increment_type
                        /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
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

       /*                                                --Sn:Commented since same is not used as per review observation for FSS-1246
         BEGIN
            SELECT ctc_atmusage_limit, ctc_posusage_limit,
                   ctc_business_date, ctc_preauthusage_limit
              INTO v_atm_usagelimit, v_pos_usagelimit,
                   v_business_date_tran, v_preauth_usage_limit
              FROM cms_translimit_check
             WHERE ctc_inst_code = p_inst_code
               AND ctc_pan_code = v_hash_pan                       --P_card_no
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
                     'Error while selecting 3 CMS_TRANSLIMIT_CHECK'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            IF p_delivery_channel = '02'
            THEN
               IF v_tran_date > v_business_date_tran
               THEN
                  v_pos_usageamnt := 0;
                  v_pos_usagelimit := 1;
                  v_preauth_usage_limit := 0;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_amt = v_pos_usageamnt,
                            ctc_posusage_limit = v_pos_usagelimit,
                            ctc_atmusage_amt = 0,
                            ctc_atmusage_limit = 0,
                            ctc_business_date =
                               TO_DATE (p_tran_date || '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'
                                       ),
                            ctc_preauthusage_limit = v_preauth_usage_limit,
                            ctc_mmposusage_amt = 0,
                            ctc_mmposusage_limit = 0
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan             -- P_card_no
                        AND ctc_mbr_numb = p_mbr_numb;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                              'Problem while updating data in CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 5 CMS_TRANSLIMIT_CHECK'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_pos_usagelimit := v_pos_usagelimit + 1;

                  BEGIN
                     UPDATE cms_translimit_check
                        SET ctc_posusage_limit = v_pos_usagelimit
                      WHERE ctc_inst_code = p_inst_code
                        AND ctc_pan_code = v_hash_pan              --P_card_no
                        AND ctc_mbr_numb = p_mbr_numb;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                              'Problem while updating data in CMS_TRANSLIMIT_CHECK'
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating 6 CMS_TRANSLIMIT_CHECK'
                           || v_resp_cde
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         END;
       */                    --En:Commented since same is not used as per review observation for FSS-1246 

         --Sn select response code and insert record into txn log dtl
         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
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
               --ROLLBACK;                                  -- Commented as per review observation for MVHOST-354
         -- RETURN;
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
                         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                         ctd_network_id, ctd_interchange_feeamt,
                         ctd_merchant_zip, ctd_merchant_id, ctd_country_code
                        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                        )
                 VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                         p_msg, p_txn_mode, p_tran_date,
                         p_tran_time, v_hash_pan,
                         v_tran_amt, --p_txn_amt modified for 10871
                         p_curr_code, v_tran_amt,
                         NULL, NULL,
                         NULL, NULL,
                         v_total_amt, v_card_curr, 'E',
                         v_err_msg, p_rrn,
                         p_stan, p_inst_code,
                         v_encr_pan, v_acct_number,
                         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                         p_network_id, p_interchange_feeamt,
                         p_merchant_zip, p_merc_id, p_country_code
                        /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '69';          -- Server Decline Response 220509
               p_resp_id := '69'; --Added for VMS-8018
               --ROLLBACK;                   -- Commented as per review observation for MVHOST-354
               RETURN;
         END;
   --En select response code and insert record into txn log dtl
   END;

   --Sn generate auth id
   IF v_auth_id_gen_flag = 'N'
   THEN
      BEGIN
          -- SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO AUTHID_DATE FROM DUAL;
         /* SELECT    TO_CHAR (SYSDATE, 'YYYYMMDD')
                 || LPAD (seq_auth_id.NEXTVAL, 6, '0')
            INTO v_auth_id
            FROM DUAL;*/
            --Auth_id length change from 14 to 6 on 221012
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';                           -- Server Declined
            p_resp_id := '89'; --Added for VMS-8018
            ROLLBACK;
      END;
   END IF;
   --En generate auth id
   
  --Sn added by Pankaj S. for 10871 
  IF v_dr_cr_flag IS NULL THEN
  BEGIN  
   SELECT ctm_credit_debit_flag,TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),ctm_tran_type
       INTO v_dr_cr_flag,v_txn_type,v_tran_type
       FROM cms_transaction_mast
      WHERE ctm_tran_code = p_txn_code
        AND ctm_delivery_channel = p_delivery_channel
        AND ctm_inst_code = p_inst_code; 
  EXCEPTION
     WHEN OTHERS THEN
        NULL;
  END;
  END IF;
      
  IF v_prod_code is NULL THEN
  BEGIN  
    SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
      INTO v_prod_code, v_prod_cattype, v_applpan_cardstat,v_acct_number
      FROM cms_appl_pan
     WHERE cap_inst_code = p_inst_code
       AND cap_pan_code = gethash (p_card_no);
  EXCEPTION
     WHEN OTHERS THEN
        NULL;
  END;
  END IF;
      
  IF v_acct_type IS NULL THEN
  BEGIN  
    SELECT cam_type_code
      INTO v_acct_type
      FROM cms_acct_mast
     WHERE cam_inst_code = p_inst_code
       AND cam_acct_no = v_acct_number;
  EXCEPTION
     WHEN OTHERS THEN
        NULL;
  END;
  END IF;
  --En added by Pankaj S. for 10871 

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
                   addcharge, productid, categoryid, tips, decline_ruleid,
                   atm_name_location, auth_id, trans_desc,
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
                                                                  /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                           network_id,
                   interchange_feeamt, merchant_zip, merchant_id,
                   country_code,
                                /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                fee_plan, pos_verification,
                   --Added by Deepa on July 03 2012 to log the verification of POS
                   internation_ind_response,
                                            --Added by Deepa on July 03 2012 to log International Indicator
                                            feeattachtype,
                                                          -- Added by Trivikram on 05-Sep-2012
                                                          merchant_name,
                   -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                   merchant_city,
                                 -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                 merchant_state,
                  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                  NETWORK_SETTL_DATE,  -- Added on 201112 for logging N/W settlement date in transactionlog
                  MATCH_RULE, -- Added for FSS-781
                  error_msg,acct_type,time_stamp,preauth_lastcomp_ind,--added by Pankaj S. for 10871 
                  PERMRULE_VERIFY_FLAG ,--Added for MVHOST-392 on 18/06/2013
                   NETWORKID_SWITCH,   --Added on 20130626 for the Mantis ID 11344
                   ORGNL_CARD_NO,       --Added for FSS-1246 
                   ORGNL_RRN,           --Added for FSS-1246  
                   ORGNL_BUSINESS_DATE, --Added for FSS-1246
                   ORGNL_BUSINESS_TIME, --Added for FSS-1246
                   ORGNL_TERMINAL_ID,   --Added for FSS-1246
                   completion_count,     --Added for FSS-1246
                   remark --Added for error msg need to display in CSR(declined by rule)
                  )
           VALUES (p_msg, p_rrn, p_delivery_channel, p_term_id,
                   v_business_date, p_txn_code, v_txn_type, p_txn_mode,
                   DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                   p_tran_date, SUBSTR (p_tran_time, 1, 10), v_hash_pan,
                   NULL, NULL,                           --P_topup_acctno    ,
                              NULL,                        --P_topup_accttype,
                                   p_inst_code,
                   v_totalamt, --TRIM (TO_CHAR (v_total_amt, '99999999999999999.99')), --Modified by Pankaj S. for 10871
                   NULL, NULL, p_mcc_code, p_curr_code,
                   NULL,                                      -- P_add_charge,
                   v_prod_code, v_prod_cattype, '0.00' --modified by Pankaj S. for 10871
                   , NULL,
                   p_atmname_loc, v_auth_id, v_trans_desc,
                   TRIM (TO_CHAR (nvl(v_tran_amt,0) ,'999999999999999990.99')), --modified for 10871
                   '0.00','0.00', --modified by Pankaj S. for 10871
                              -- Partial amount (will be given for partial txn)
                   NULL,
                   NULL, NULL, NULL,
                   NULL, v_gl_upd_flag, p_stan,
                   p_inst_code,
                   v_fee_code, nvl(v_fee_amt,0), nvl(v_servicetax_amount,0),nvl(v_cess_amount,0), --modified for 10871
                   v_dr_cr_flag, v_fee_cracct_no,
                   v_fee_dracct_no, v_st_calc_flag,
                   v_cess_calc_flag, v_st_cracct_no,
                   v_st_dracct_no, v_cess_cracct_no,
                   v_cess_dracct_no, v_encr_pan,
                   NULL, v_proxunumber, p_rvsl_code,
                   v_acct_number, v_acct_balance, v_ledger_bal,
                   v_resp_cde, v_applpan_cardstat,
                                                  --Added cardstatus insert in transactionlog by srinivasu.k
                                                                                /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                                  p_network_id,
                   p_interchange_feeamt, p_merchant_zip, p_merc_id,
                   p_country_code,
                                  /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                  v_fee_plan,
                                             --Added by Deepa for Fee Plan on June 10 2012
                                             p_pos_verfication,
                   --Added by Deepa on July 03 2012 to log the verification of POS
                   p_international_ind,
                                       --Added by Deepa on July 03 2012 to log International Indicator
                                       v_feeattach_type,
                                                        -- Added by Trivikram on 05-Sep-2012
                                                        p_merchant_name,
                   -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                   p_merchant_city,
                                   -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                   p_atmname_loc,
                  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                  P_NETWORK_SETL_DATE,  -- Added on 201112 for logging N/W settlement date in transactionlog
                  v_rule,                -- Added for FSS-781
                  v_err_msg,v_acct_type,nvl(v_timestamp,systimestamp),v_last_comp_ind, --added by Pankaj S. for 10871
                  V_MCC_VERIFY_FLAG , --Added for MVHOST-392 on 18/06/2013
                  P_NETWORKID_SWITCH,  --Added on 20130626 for the Mantis ID 11344
                  v_orgnl_hash_pan,   --Added for FSS-1246  
                  p_orgnl_rrn,      --Added for FSS-1246 
                  p_orgnl_trandate, --Added for FSS-1246
                  p_orgnl_trantime, --Added for FSS-1246 
                  p_orgnl_termid,   --Added for FSS-1246
                  p_comp_count ,     --Added for FSS-1246        
                  V_ERR_MSG --Added for error msg need to display in CSR(declined by rule)
                  );

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

show error;