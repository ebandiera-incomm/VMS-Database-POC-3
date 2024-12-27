create or replace PROCEDURE        VMSCMS.SP_ACH_CREDITTRANSACTION (
   p_instcode              IN       NUMBER,
   p_rrn                   IN       VARCHAR2,
   p_terminalid            IN       VARCHAR2,
   p_tracenumber           IN       VARCHAR2,
   p_trandate              IN       VARCHAR2,
   p_trantime              IN       VARCHAR2,
   p_panno                 IN       VARCHAR2,
   p_amount                IN       NUMBER,
   p_currcode              IN       VARCHAR2,
   p_lupduser              IN       NUMBER,
   p_msg                   IN       VARCHAR2,
   p_txn_code              IN       VARCHAR2,
   p_txn_mode              IN       VARCHAR2,
   p_delivery_channel      IN       VARCHAR2,
   p_mbr_numb              IN       VARCHAR2,
   p_rvsl_code             IN       VARCHAR2,
   p_odfi                  IN       VARCHAR2,
   p_rdfi                  IN       VARCHAR2,
   p_achfilename           IN       VARCHAR2,
   p_seccode               IN       VARCHAR2,
   p_impdate               IN       VARCHAR2,
   p_processdate           IN       VARCHAR2,
   p_effectivedate         IN       VARCHAR2,
   p_incoming_crfileid     IN       VARCHAR2,
   p_achtrantype_id        IN       VARCHAR2,
   p_indidnum              IN       VARCHAR2,
   p_indname               IN       VARCHAR2,
   p_companyname           IN       VARCHAR2,
   p_companyid             IN       VARCHAR2,
   p_id                    IN       VARCHAR2,
   p_compentrydesc         IN       VARCHAR2,
   p_cust_acct_no          IN       VARCHAR2,
   p_processtype           IN       VARCHAR2,
   p_source_name           IN       VARCHAR2,
   p_federal_ind           IN       NUMBER,
   p_resp_code             OUT      VARCHAR2,
   p_errmsg                OUT      VARCHAR2,
   p_startledgerbal        OUT      VARCHAR2,
   p_startaccountbalance   OUT      VARCHAR2,
   p_endledgerbal          OUT      VARCHAR2,
   p_endaccountbalance     OUT      VARCHAR2,
   p_auth_id               OUT      VARCHAR2
)
AS
   /*********************************************************************************************
      * Created Date     :  10-Dec-2011
      * Created By       :  Srinivasu
      * PURPOSE          :  For ACH Credit transaction
      * Modified by      :  Saravanakumar
      * Modified Reason  :  10298
      * Modified Date    :  18-Feb-2013
      * Reviewer         : Sachin
      * Reviewed Date    :  18-Feb-2013
      * Build Number     : CMS3.5.1_RI0023.1.1
      
      * Modified by      :  Pankaj S.
      * Modified Reason  :  Logging ODFI code for Fails txns(FSS-921)
      * Modified Date    :  15-Apr-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  
      * Build Number     :  RI0024.1_B0005
      
     * Modified By      :  Shweta M
     * Modified Date    :  14-Aug-2013
     * Modified For     :  MVHOST-367   
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  19-Aug-2013
     * Build Number     :  RI0024.4_B0002

     * Modified by      :  Amudhan  S.
     * Modified Reason  :  Name logic change of MVHOST-478 and Mantis Id: 12416,12429 and 12430
     * Modified Date    :  17-Sep-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  17-Sep-2013
     * Build Number     :  RI0024.4_B0018

      * Modified by     :  Amudhan  S.
      * Modified Reason :  Patch moved from 24.3 for Name logic Change request of MVHOST-478 ,MVHOST-656 ,MVHOST 531 and Mantis ID : 12416 ,12480
      * Modified Date   :  10-Oct-2013
      * Reviewer        :  Dhiraj
      * Reviewed Date   :  10-Oct-2013
      * Build Number    :  RI0024.4.3_B0001
      
      * Modified by      :  Pankaj S.
      * Modified Reason  :  ACH Credit transactions declined in Production due to Name not Matched(FSS-1346)
      * Modified Date    :  21-Oct-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  
      * Build Number     :  RI0024.5.1_B0002

      * Modified by      :  Amudhan S
      * Modified For     :  FSS-1350
      * Modified Reason  :  Name matching by ignoring the spaces and ACH credit trasnaction should be considered as reload
      * Modified Date    :  24-Oct-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  
      * Build Number     :  RI0024.5.2_B0001        
      
      * Modified by       : Sagar
      * Modified for      : 
      * Modified Reason   : Concurrent Processsing Issue 
                            (1.7.6.7 changes integarted)
      * Modified Date     : 04-Mar-2014
      * Reviewer          : Dhiarj
      * Reviewed Date     : 06-Mar-2014
      * Build Number      : RI0027.1.1_B0001   
      
           
      * Modified by       : Siva Kumar M
      * Modified for      : 13787
      * Modified Reason   : ACH Performance issue.
      * Modified Date     : 05-Mar-2014
      * Reviewer          : Dhiraj
      * Reviewed Date     : 05-Mar-2014
      * Build Number      : RI0027.2_B0001     
      
     * Modified by       : Abdul Hameed M.A
     * Modified for      : 13892
     * Modified Reason   : ACH Initial load rule changes for MYVannila GPR Card .
     * Modified Date     : 21-Mar-2014
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 02-April-2014
     * Build Number     : RI0027.2_B0003
      * Modified by       : Pankaj S.
     * Modified for      : Enabling Limit configuration and validation (MVHOST_756 null-4113)         
     * Modified Date     : 24-MAR-2014
     * Reviewer          : Dhiraj
     * Reviewed Date     : 07-April-2014
     * Build Number      : RI0027.2_B0004        
      
     * Modified by       : Abdul Hameed M.A
     * Modified for      : JH 3011   
     * Modified Reason   : GPR  card should be generated for the starter card if GPROPTIN is "N" and starter to gpr is manual.
     * Modified Date     : 01-SEP-2014
     * Build Number      : RI0027.3.2_B0002
     
     * Modified by       : Mageshkumar S
     * Modified for      : FSS-1878(Integration of 2.2.6.1 changes)        
     * Modified Date     : 23-Sep-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3.3_B0001
     
     * Modified Date    : 29-SEP-2014
     * Modified By      : Abdul Hameed M.A
     * Modified for     : FWR 70
     * Reviewer         :  Spankaj
     * Release Number   : RI0027.4_B0002
     
      * Modified Date    : 31-OCT-2014
     * Modified By      : Abdul Hameed M.A
     * Modified for     : MVHOST 1022
     * Reviewer         : Spankaj
     * Release Number   : RI0027.4.3_B0001
     
      * Modified Date    : 07-NOV-2014
     * Modified By      : Abdul Hameed M.A
     * Modified for     : MANTIS id 15866,15865
     * Reviewer         : Saravanakumar
     * Release Number   : RI0027.4.3_B0002
     
     * Modified Date    : 23-JAN-2015
     * Modified By      : Abdul Hameed M.A
     * Modified for     : MVHOST-1099,MVHOST-1103,MVHOST-1093
     
     * Modified Date    : 13-FEB-2015
     * Modified By      : Abdul Hameed M.A
     * Modified for     : MANTIS ID 0016024
     * Reviewer         : Saravanakumar
     * Release Number   : RI0027.4.3.2
     
      * Modified Date    : 12-DEC-2014
     * Modified By      : Ramesh A
     * Modified for     : FSS-1961(Melissa)
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0002
     
      * Modified Date    : 23-JAN-2015
     * Modified By      : Abdul Hameed M.A
     * Modified for     : MVHOST-1099,MVHOST-1103,MVHOST-1093
     * Reviewer         : Spankaj
     * Release Number   :  RI0027.5_B0005
     
     * Modified Date    : 13-FEB-2015
     * Modified By      : Abdul Hameed M.A
     * Modified for     : MANTIS ID 0016024
     * Reviewer         : Saravanakumar
     * Release Number   : RI0027.5
     
     * Modified Date    : 12-Mar-2015
     * Modified By      : Pankaj S.
     * Modified for     : 2.4.3.4 changes integration
     * Reviewer         : Saravanakumar
     * Release Number   : RI0027.5.1_B0001
     
     * Modified Date    : 20-Mar-2015
     * Modified By      : Ramesh A
     * Modified for     : NCGPR-1581
     * Reviewer         : Spankaj
     * Release Number   : 3.0
     
     * Modified Date    : 28-April-2015
     * Modified By      : Pankaj S.
     * Modified for     : 2.5.2 changes integration (To consider only 1st 9 digits in receiver ID field of ACH file for SSN check.)
     * Reviewer         : Saravanakumar
     * Release Number   : 3.0.1_B0001
     
     * Modified Date    : 28-April-2015
     * Modified By      : Pankaj S.
     * Modified for     : 2.5.2.1 changes integration (Added Additional Name Match pattern)
     * Reviewer         :  Saravanakumar
     * Release Number   :  3.0.1_B0001
     
     * Modified Date    :  28-April-2015
     * Modified By      : Pankaj S.
     * Modified for     : 2.5.3 changes integration (SSN null Match failed case should be moved to Exception Queue)
     * Reviewer         :  Saravanakumar
     * Release Number   :  3.0.1_B0001
     
     * Modified By      : Pankaj S.
     * Modified Date    : 01-07-2015
     * Modified Reason  : For new ach changes
     * Reviewer         : Sarvanan
     * Reviewed Date    : 
     * Build Number     : VMSGPRHOST3.0.4

     * Modified By      : Sarvanakumar A
     * Modified Date    : 21-08-2015
     * Modified Reason  : ACH Changes
     * Reviewer         : Pankaj S
     * Build Number     : VMSGPRHOST3.1_B0007
     
     * Modified by       : A.Sivakaminathan
    * Modified Date     : 15-Sep-2015
    * Modified For      : 3.2 Person to Person (P2P) ACH Correction
    * Reviewer          : Saravanankumar
    * Build Number      : VMSGPRHOST_3.2     

       * Modified by       :Siva kumar 
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006
       
       * Modified by       :Siva kumar 
       * Modified Date    : 28-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B007
       
     * Modified By      : Siva Kumar M
     * Modified Date    : 27/05/2016
     * Purpose          : FSS-4354,4355null
     * Reviewer         : Saravana Kumar 
     * Release Number   : VMSGPRHOSTCSD_4.1_B0003
     
     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 22-Aug-2016
     * Modified for     : FSS-4422
     * Reviewer         : Saravanakumar
     * Release Number   : CMS@CORE-VMSGPRHOSTCSD_4.8_B0002
     
    * Modified by       : Ramesh A
    * Modified Date     : 05-Oct-2016
    * Modified For      : FSS-4353 NACHA Compliance Issue for ACH Description
    * Reviewer          : Saravanankumar
    * Build Number      : VMSGPRHOSTCSD_4.9     
    
    * Modified by      :  Pankaj S.
    * Modified Reason  : AQ in ACH queues in VMS(FSS-4613)
    * Modified Date    :  17-Oct-2016
    * Reviewer         :  Saravanankumar
    * Reviewed Date    :   23-Oct-2016
    * Build Number     : VMSGPRHOSTCSD_4.10

    * Modified by      :  Pankaj S.
    * Modified Reason  : FSS-5100
    * Modified Date    :  23-Mar-2017
    * Reviewer         :  Saravanankumar
    * Reviewed Date    :  23-Mar-2017
    * Build Number     : VMSGPRHOSTCSD_17.03

        * Modified by       : DHINAKARAN B
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07+	
	
	       * Modified By      : Akhil
      * Modified Date    : 24-jan-2018
      * Purpose          : VMS-162
      * Reviewer         : Saravanakumar
      * Build Number     : VMSGPRHOST_18.1
	  
     * Modified By      : A.Sivakaminathan
     * Modified Date    : 18-Jun-2019
     * Purpose          : VMS-597
     * Reviewer         : Saravanankumar A
     * Release Number   : VMSGPRHOST R17	  
     
     * Modified By      : T. Narayanan
     * Modified Date    : 08-Jan-2020
     * Purpose          : VMS-1462
     * Reviewer         : Saravanankumar A
     * Release Number   : VMSGPRHOST R24.1  
	      
	 * Modified By      : Ubaid
     * Modified Date    : 06-Nov-2020
     * Purpose          : VMS-3217
     * Reviewer         : Saravanankumar A
     * Release Number   : R38 
	
 **********************************************************************************************/
   v_cap_prod_catg          cms_appl_pan.cap_prod_catg%TYPE;
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_cap_cafgen_flag        cms_appl_pan.cap_cafgen_flag%TYPE;
   v_firsttime_topup        cms_appl_pan.cap_firsttime_topup%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
   v_errmsg                 cms_transaction_log_dtl.ctd_process_msg%type;
   v_appl_code              cms_appl_mast.cam_appl_code%TYPE;
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_respcode               transactionlog.response_id%type;
   v_respmsg                VARCHAR2 (500);
   v_capture_date           DATE;
   v_mbrnumb                cms_appl_pan.cap_mbr_numb%TYPE;
   v_txn_type               cms_func_mast.cfm_txn_type%TYPE;
   v_auth_id                transactionlog.auth_id%TYPE;
   v_rrn_count              PLS_INTEGER;
   
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_tran_date              DATE;
   v_topupremrk             cms_pan_spprt.cps_func_remark%type;
   v_acct_balance           cms_acct_mast.cam_acct_bal%type;
   v_ledger_balance         cms_acct_mast.cam_ledger_bal%type; 
   v_tran_amt               cms_acct_mast.cam_ledger_bal%type; 
   v_card_curr              PCMS_EXCHANGERATE_MAST.PEM_CURR_CODE%TYPE;
   v_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_achflag                cms_prod_cattype.cpc_achtxn_flg%type;
   v_ach_filename           transactionlog.achfilename%type;
   v_achseccode             PLS_INTEGER;
   v_file_count             PLS_INTEGER;
   v_start_acct_balance     cms_acct_mast.cam_acct_bal%type;
   v_start_ledger_balance   cms_acct_mast.cam_ledger_bal%type; 
   v_respcode_org_txn       transactionlog.response_code%type; 
   v_custssn                cms_cust_mast.ccm_ssn%TYPE; 
   v_custlastname           cms_cust_mast.ccm_last_name%type;
    
   v_resp_code              transactionlog.response_code%type;
   v_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%type;
   v_output_type            cms_transaction_mast.ctm_output_type%type; 
   v_tran_type              cms_transaction_mast.ctm_tran_type%type; 
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   v_custfirstname          cms_cust_mast.ccm_first_name%type;
   v_cust_code              cms_appl_pan.cap_cust_code%TYPE;
    
   v_ach_exp_flag           transactionlog.ach_exception_queue_flag%TYPE;
   v_min_init_loadamt       cms_prod_cattype.cpc_achmin_initial_load%TYPE;
   v_init_loadamt           cms_acct_mast.cam_initialload_amt%TYPE;
   v_topup_cnt              cms_acct_mast.cam_topuptrans_count%TYPE;
   v_gpr_cnt                PLS_INTEGER;
   v_starter_cnt            PLS_INTEGER;
   v_cust_init              VARCHAR2 (40);
   v_indname                transactionlog.indname%TYPE;
   v_check_flag             cms_prod_cattype.cpc_ach_loadamnt_check%TYPE;
   v_comb_hash              pkg_limits_check.type_hash;
   v_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
   v_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_initamt_flag           cms_acct_mast.cam_initamt_flag%type;
   v_init_flag              cms_acct_mast.cam_initamt_flag%type := 'N';
   v_topcnt_flag            cms_acct_mast.cam_topcnt_flag%type;
   v_top_flag               cms_acct_mast.cam_topcnt_flag%type := 'N';
   v_cardtype_flag          cms_appl_pan.cap_startercard_flag%TYPE;
    
    
    
   v_staterissusetype       cms_prod_cattype.cpc_startergpr_issue%TYPE;
   v_processmsg             cms_transaction_log_dtl.ctd_process_msg%type;
    
    
   v_pancode                cms_appl_pan.cap_pan_code%TYPE;
   v_gpr_chkflag            cms_cust_mast.ccm_gpr_optin%type;
   v_blcklist_cnt           PLS_INTEGER;
   v_cmpnynme_cnt           PLS_INTEGER;
   v_ssn_chk_flag           VARCHAR2 (1);
   v_jhprod_cnt             cms_jhprod_mast.cjm_prod_code%TYPE;
   v_queue_flag             VARCHAR2 (1);
   v_timestamp              TIMESTAMP;
   v_cam_type_code          cms_acct_mast.cam_type_code%TYPE;
   p_pan_number varchar2(20); --Added for FSS-1961(Melissa)
   V_GPR_CHECK_FLAG         cms_prod_cattype.CPC_GPRFLAG_ACHTXN%TYPE; --Added for NCGPR-1581
     
    v_achbypass  transactionlog.addcharge%type;
    v_fedachbypass_flag     cms_prod_cattype.CPC_FEDERALCHECK_FLAG%TYPE;
    v_queue_name                 VARCHAR2(100);
    v_merc_name                    VARCHAR2(100);
    v_encrypt_enable cms_prod_cattype.cpc_encrypt_enable%type;
    V_BANK_SEC_COUNT NUMBER(5):=0;    
    
   exp_main_reject_record   EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
   
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
	v_Retdate  date; --Added for VMS-5739/FSP-991
    
PROCEDURE lp_purge_q
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
   l_errmsg     VARCHAR2 (1000);
   l_last_ach   vms_achaq_clr.vac_last_ach%TYPE;
BEGIN
   SELECT vac_last_ach INTO l_last_ach FROM vms_achaq_clr;

   IF l_last_ach <> TRUNC (SYSDATE) THEN
      achaq.purge_queue ('ACH_QT', 'ACH_ACHVIEW_QUEUE', l_errmsg);

      UPDATE vms_achaq_clr
         SET vac_last_ach = TRUNC (SYSDATE);

      COMMIT;
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      achaq.purge_queue ('ACH_QT', 'ACH_ACHVIEW_QUEUE', l_errmsg);
      
      INSERT INTO vms_achaq_clr
           VALUES (TRUNC (SYSDATE));

      COMMIT;
   WHEN OTHERS THEN
      ROLLBACK;
END;
    
BEGIN
   p_errmsg := 'OK ';
   v_topupremrk := 'ACH Credit Transaction';

   BEGIN
      v_hash_pan := gethash (p_panno);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      v_encr_pan := fn_emaps_main (p_panno);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while converting encrypted pan '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_tran_desc, ctm_prfl_flag
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type, v_trans_desc, v_prfl_flag
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '12';
         v_errmsg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting transaction details'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   IF (p_amount >= 0)
   THEN
      v_tran_amt := p_amount;
   END IF;

   BEGIN
      SELECT cap_card_stat, cap_prod_catg, cap_cafgen_flag,
             cap_appl_code, cap_firsttime_topup, cap_mbr_numb,
             cap_prod_code, cap_card_type, cap_proxy_number, cap_acct_no,
             cap_cust_code, cap_prfl_code, cap_startercard_flag
        INTO v_cap_card_stat, v_cap_prod_catg, v_cap_cafgen_flag,
             v_appl_code, v_firsttime_topup, v_mbrnumb,
             v_prod_code, v_card_type, v_proxunumber, v_acct_number,
             v_cust_code, v_prfl_code, v_cardtype_flag
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan;-- AND cap_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'Invalid Card number ' || v_hash_pan;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting card dtls ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      SELECT     cam_acct_bal, cam_ledger_bal,
                 cam_initialload_amt, cam_topuptrans_count,
                 cam_initamt_flag, cam_topcnt_flag, cam_type_code
            INTO v_start_acct_balance, v_start_ledger_balance,
                 v_init_loadamt, v_topup_cnt,
                 v_initamt_flag, v_topcnt_flag, v_cam_type_code
            FROM cms_acct_mast
           WHERE cam_acct_no = p_cust_acct_no AND cam_inst_code = p_instcode
      FOR UPDATE;

      p_startledgerbal := v_start_ledger_balance;
      p_startaccountbalance := v_start_acct_balance;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '16';
         v_errmsg := 'Invalid Card ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
            'Error while selecting account dtls ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   
   BEGIN
      SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
        INTO v_auth_id
        FROM DUAL;

      p_auth_id := v_auth_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;
   
	IF v_dr_cr_flag = 'CR' AND UPPER(p_compentrydesc) LIKE '%REVERSAL%' THEN
		v_ach_exp_flag := 'R';
		V_RESPCODE     := '254';
		V_ERRMSG       := 'Credit Reversal';
		RAISE EXP_MAIN_REJECT_RECORD;
	END IF;

   BEGIN
      SELECT COUNT (*)
        INTO v_achseccode
        FROM cms_prod_catsec
       WHERE cpc_prod_code = v_prod_code
         AND cpc_inst_code = p_instcode
         AND cpc_sec_code = p_seccode
         AND cpc_card_type = v_card_type
         AND cpc_tran_code = p_txn_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '27';
         v_errmsg :=
               'Error while selecting cms_prod_catsec '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   IF v_achseccode = 0
   THEN
      v_respcode := '27';
      v_errmsg := 'SEC Code is not allowed for ACH transaction';
      RAISE exp_main_reject_record;
   END IF;
   
   BEGIN      
    SELECT CPC_FEDERALCHECK_FLAG,CPC_GPRFLAG_ACHTXN,cpc_encrypt_enable
      INTO  v_fedachbypass_flag,V_GPR_CHECK_FLAG,v_encrypt_enable
      FROM cms_prod_cattype
     WHERE  cpc_inst_code = p_instcode
	 AND cpc_prod_code = v_prod_code
	 AND cpc_card_type = v_card_type;          
   EXCEPTION 
     WHEN NO_DATA_FOUND THEN
        v_respcode := '21';
         v_errmsg := 'Product Details not Found in product cattype table';
        RAISE exp_main_reject_record;     
     WHEN OTHERS  THEN
        v_respcode := '21';
        v_errmsg :='Error while selecting ACH federal BY PASS FLAG ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_main_reject_record;      
   END;  
   
   IF v_dr_cr_flag = 'CR'
   THEN
      BEGIN
         SELECT COUNT (1)
           INTO v_blcklist_cnt
           FROM cms_blacklist_sources
          WHERE cbs_inst_code = p_instcode
            AND UPPER (cbs_source_name) = UPPER (TRIM (p_companyname))
            AND ((cbs_validfrom_date IS NULL AND cbs_validto_date IS NULL) OR (cbs_validto_date IS NULL AND trunc(sysdate) >= cbs_validfrom_date) OR
            (cbs_validfrom_date IS NULL AND trunc(sysdate) <= cbs_validto_date) OR (trunc(sysdate) BETWEEN cbs_validfrom_date AND cbs_validto_date))
        AND cbs_prod_code = v_prod_code;
            
         IF (v_blcklist_cnt <> 0)
         THEN
          v_achbypass:=vmsusach.check_achbypass ( p_cust_acct_no, UPPER (TRIM (p_companyname)), 1 );
          IF v_achbypass='N' THEN
            v_achbypass :='1';
            v_respcode := '73';
            v_errmsg := 'Blacklisted Source';
            RAISE exp_main_reject_record;
          END IF;  
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error while selecting BLACKLISTED SOURCES  '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      IF p_federal_ind = 2 AND v_fedachbypass_flag='Y'
      THEN
         v_ssn_chk_flag := 'Y';
         v_ach_exp_flag := 'FD';
      END IF;

      BEGIN
         SELECT TRIM (nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn)),
         decode(v_encrypt_enable,'Y',trim(upper(fn_dmaps_main(ccm_last_name))),TRIM (UPPER (ccm_last_name))),
         decode(v_encrypt_enable,'Y',trim(upper(fn_dmaps_main(ccm_first_name))),TRIM (UPPER (ccm_first_name))), ccm_gpr_optin
           INTO v_custssn, v_custlastname,
                v_custfirstname, v_gpr_chkflag
           FROM cms_cust_mast
          WHERE ccm_cust_code = v_cust_code AND ccm_inst_code = p_instcode;

         IF p_processtype <> 'N'
         THEN
            v_indname := UPPER (p_indname);

            IF p_federal_ind <> 2
            THEN
               BEGIN
                  SELECT COUNT (1)
                    INTO v_cmpnynme_cnt
                    FROM cms_company_name
                   WHERE ccn_inst_code = p_instcode
                   AND upper(ccn_company_name) LIKE '%' || upper(TRIM(p_companyname) ) || '%';    ---- Modified for VMS-3217

                  IF (v_cmpnynme_cnt <> 0)
                  THEN
                     v_ssn_chk_flag := 'Y';
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                           'Error while selecting CMS_COMPANY_NAME  '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_main_reject_record;
               END;
            END IF;

            IF (v_ssn_chk_flag = 'Y')
            THEN
               SELECT TRIM (REGEXP_REPLACE (v_indname, '( ){2,}', ' '))
                 INTO v_indname
                 FROM DUAL;

               SELECT TRIM (SUBSTR (v_indname,
                                    INSTR (v_indname, ' ', 1, 1) + 1,
                                      INSTR (v_indname, ' ', 1, 2)
                                    - INSTR (v_indname, ' ', 1, 1)
                                    - 1
                                   )
                           )
                 INTO v_cust_init
                 FROM DUAL;

               IF ((   p_indidnum IS NULL
                    OR substr(TRIM (RTRIM (LTRIM (UPPER (p_indidnum), 'IRS'), 'IRS')),1,9) <> NVL (substr(v_custssn,1,9), ' '))   --substr added To consider only 1st 9 digits in receiver ID field of ACH file for SSN check
                  )   
               THEN
                 v_achbypass:=vmsusach.check_achbypass ( p_cust_acct_no, UPPER (TRIM (p_companyname)), 4 );
                 IF v_achbypass='N' THEN
                  v_achbypass :='4';
                  v_respcode := '74';
                  v_errmsg := 'SSN is not matched';
                  v_queue_flag := 'Y';
                  RAISE exp_main_reject_record;
                 END IF;  
                  --v_ssn_fail:='Y';
               END IF;

               IF (v_indname IS NULL)
               THEN
                  v_respcode := '75';
                  v_errmsg := 'Name is not matched ';
                    
                           v_queue_flag := 'Y';
                    
                  RAISE exp_main_reject_record;
               ELSIF (    (v_indname <>
                                      v_custlastname || ' ' || v_custfirstname
                          )
                      AND (v_indname <>
                                      v_custfirstname || ' ' || v_custlastname
                          )
                      AND (v_indname <>
                                      v_custlastname || ',' || v_custfirstname
                          )
                      AND (v_indname <>
                                      v_custfirstname || ',' || v_custlastname
                          )
                     )
               THEN
                  IF (    INSTR (v_indname,
                                 (v_custlastname || ',' || v_custfirstname
                                  || ' '
                                 )
                                ) <> 1
                      AND INSTR (v_indname,
                                 (v_custfirstname || ',' || v_custlastname
                                  || ' '
                                 )
                                ) <> 1
                      AND INSTR (v_indname,
                                 (v_custlastname || ' ' || v_custfirstname
                                  || ' '
                                 )
                                ) <> 1
                      AND INSTR (v_indname,
                                 (v_custfirstname || ' ' || v_custlastname
                                  || ' '
                                 )
                                ) <> 1
                     )
                  THEN
                     IF (    INSTR (v_indname,
                                    (   v_custlastname
                                     || ' '
                                     || v_cust_init
                                     || ' '
                                     || v_custfirstname
                                    )
                                   ) <> 1
                         AND INSTR (v_indname,
                                    (   v_custfirstname
                                     || ' '
                                     || v_cust_init
                                     || ' '
                                     || v_custlastname
                                    )
                                   ) <> 1
                        )
                     THEN
                       IF (    INSTR (v_indname,
                                 (v_custlastname || ', ' || v_custfirstname
                                 )
                                ) <> 1
                      AND INSTR (v_indname,
                                 (v_custfirstname || ', ' || v_custlastname
                                 )
                                ) <> 1
                      AND INSTR (v_indname,
                                 (v_custlastname || ' ,' || v_custfirstname
                                 )
                                ) <> 1
                      AND INSTR (v_indname,
                                 (v_custfirstname || ' ,' || v_custlastname
                                 )
                                ) <> 1
                     )
                    THEN
                        IF (LENGTH (v_indname) = 22)
                        THEN
                           IF (    INSTR ((   v_custlastname
                                           || ','
                                           || v_custfirstname
                                           || ' '
                                          ),
                                          v_indname
                                         ) <> 1
                               AND INSTR ((   v_custfirstname
                                           || ','
                                           || v_custlastname
                                           || ' '
                                          ),
                                          v_indname
                                         ) <> 1
                               AND INSTR ((   v_custlastname
                                           || ' '
                                           || v_custfirstname
                                           || ' '
                                          ),
                                          v_indname
                                         ) <> 1
                               AND INSTR ((   v_custfirstname
                                           || ' '
                                           || v_custlastname
                                           || ' '
                                          ),
                                          v_indname
                                         ) <> 1
                              AND  INSTR (
                                 (v_custlastname || ', ' || v_custfirstname
                                 ),v_indname
                                ) <> 1
                               AND INSTR (
                                 (v_custfirstname || ', ' || v_custlastname
                                 ),v_indname
                                ) <> 1
                               AND INSTR (
                                 (v_custlastname || ' ,' || v_custfirstname
                                 ),v_indname
                                ) <> 1
                               AND INSTR (
                                 (v_custfirstname || ' ,' || v_custlastname
                                 ),v_indname
                                ) <> 1                  
                              )
                                                     THEN                          
                              v_respcode := '75';
                              v_errmsg := 'Name is not matched ';
                                
                                  v_queue_flag := 'Y';
                                 
                              RAISE exp_main_reject_record;
                           END IF;
                        ELSE                          
                           v_respcode := '75';
                           v_errmsg := 'Name is not matched ';
                           
                              v_queue_flag := 'Y';
                             
                           RAISE exp_main_reject_record;
                        END IF;
                        end if;
                     END IF;
                  END IF;
               END IF;
                          
                   END IF;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
           IF v_respcode = '75' THEN
             v_achbypass:=vmsusach.check_achbypass ( p_cust_acct_no, UPPER (TRIM (p_companyname)), 5 );
             IF v_achbypass='N' THEN
                 v_achbypass:='5';
                 v_respcode:='74';
                RAISE exp_main_reject_record;
             else
                 v_respcode:=NULL;  
             END IF;
           else
              RAISE exp_main_reject_record;  
           END IF;  
         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '17';
            v_errmsg := 'SSN Not Available';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                      'Error while selecting SSN' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   END IF;

   

   IF p_processtype <> 'N'
   THEN
      BEGIN
	  
	  
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)

    THEN
	
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE rrn = p_rrn
            AND business_date = p_trandate
            AND delivery_channel = p_delivery_channel;
ELSE
		SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE rrn = p_rrn
            AND business_date = p_trandate
            AND delivery_channel = p_delivery_channel;
END IF;			

         IF v_rrn_count > 0
         THEN
            v_respcode := '22';
            v_errmsg := 'Duplicate RRN ' || 'on ' || p_trandate;
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
               'Error while Duplicate RRN check ' || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_main_reject_record;
      END;
   END IF;

   IF v_dr_cr_flag = 'CR'
   THEN
      BEGIN
         SELECT cpc_achtxn_flg, cpc_profile_code, cpc_achmin_initial_load,
                cpc_ach_loadamnt_check, cpc_startergpr_issue
           INTO v_achflag, v_profile_code, v_min_init_loadamt,
                v_check_flag, v_staterissusetype
           FROM cms_prod_cattype
          WHERE cpc_prod_code = v_prod_code
            AND cpc_card_type = v_card_type
            AND cpc_inst_code = p_instcode;

         IF TRIM (v_achflag) IS NULL
         THEN
            v_respcode := '21';
            v_errmsg := 'ACH FLAG Cannot be null ';
            RAISE exp_main_reject_record;
         END IF;

         IF TRIM (v_achflag) = 'N'
         THEN
            v_respcode := '33';
            v_errmsg :=
                  'ACH Transaction is not Supported for the Product Category'
               || p_cust_acct_no;
            RAISE exp_main_reject_record;
         END IF;

         IF NVL (v_min_init_loadamt, 0) = 0
         THEN
            v_respcode := '38';
            v_errmsg :=
               'Minimum initial load amount is not configured for product category code';
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '21';
            v_errmsg := 'ACH FLAG Cannot be null ';
            RAISE exp_main_reject_record;
         WHEN exp_main_reject_record
         THEN
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
               'Error while selecting ACH FLAG  ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   END IF;

   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_trandate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_trantime), 1, 10),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '32';
         v_errmsg :=
               'Problem while converting transaction time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      sp_convert_curr (p_instcode,
                       p_currcode,
                       p_panno,
                       p_amount,
                       v_tran_date,
                       v_tran_amt,
                       v_card_curr,
                       v_errmsg,
                       v_prod_code,
                       v_card_type
                      );

      IF v_errmsg <> 'OK'
      THEN
         v_respcode := '21';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_respcode := '89';
         v_errmsg :=
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   IF v_dr_cr_flag = 'CR'
   THEN
      IF (p_federal_ind = 2 AND v_fedachbypass_flag='Y')
      THEN
         BEGIN
            SELECT COUNT (1)
              INTO v_jhprod_cnt
              FROM cms_jhprod_mast
             WHERE cjm_prod_code = v_prod_code; 
         EXCEPTION
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'Error while selecting jhprod cnt '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      END IF;

      IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
      THEN
         IF v_dr_cr_flag = 'CR'
         THEN
            BEGIN
               pkg_limits_check.sp_limits_check
                                   (v_hash_pan,
                                    NULL,
                                    NULL,
                                    NULL,
                                    p_txn_code,									
                                    v_tran_type,
                                    NULL,
                                    NULL,
                                    p_instcode,
                                    NULL,
                                    v_prfl_code,
                                    v_tran_amt,
                                    p_delivery_channel,
                                    v_comb_hash,
                                    v_respcode,
                                    v_errmsg
                                   );

               IF v_errmsg <> 'OK'
               THEN                
                  IF v_respcode = '79'
                  THEN
                     v_respcode := '20';
                  ELSIF v_respcode = '80'
                  THEN
                     v_respcode := '23';
                  END IF;

                  IF (v_jhprod_cnt <> 0)
                  THEN
                     v_queue_flag := 'Y';
                  END IF;

                  RAISE exp_main_reject_record;
                 else
                    v_respcode := NULL;
                 END IF;
            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_respcode := '21';
                  v_errmsg :=
                        'Error from Limit Check Process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
            END;
         END IF;
      END IF;

      BEGIN
         SELECT SUM (DECODE (cap_startercard_flag, 'Y', 1, 0)) starter_cnt,
                SUM (DECODE (cap_startercard_flag, 'N', 1, 0)) gpr_cnt
           INTO v_starter_cnt,
                v_gpr_cnt
           FROM cms_appl_pan
          WHERE cap_inst_code = p_instcode AND cap_acct_no = p_cust_acct_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting starter_cnt null '|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      IF v_starter_cnt <> 0
      THEN
         IF v_init_loadamt = 0
         THEN
            IF v_initamt_flag = 'N'
            THEN
               BEGIN
                  SELECT amt
                    INTO v_init_loadamt
                    FROM (SELECT   amount amt
                              FROM VMSCMS.TRANSACTIONLOG					--Added for VMS-5739/FSP-991
                             WHERE (   (    delivery_channel = '08'
                                        AND txn_code = '26'
                                       )
                                    OR (    delivery_channel = '04'
                                        AND txn_code = '68'
                                       )
                                   )
                               AND response_code = '00'
                               AND customer_acct_no = p_cust_acct_no 
                            ORDER BY add_ins_date DESC) a
                   WHERE ROWNUM = 1;
				   IF SQL%ROWCOUNT = 0 THEN 
				   SELECT amt
                    INTO v_init_loadamt
                    FROM (SELECT   amount amt
                              FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST					--Added for VMS-5739/FSP-991
                             WHERE (   (    delivery_channel = '08'
                                        AND txn_code = '26'
                                       )
                                    OR (    delivery_channel = '04'
                                        AND txn_code = '68'
                                       )
                                   )
                               AND response_code = '00'
                               AND customer_acct_no = p_cust_acct_no 
                            ORDER BY add_ins_date DESC) a
                   WHERE ROWNUM = 1;
				   END IF;

                  v_init_flag := 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                    v_achbypass:=vmsusach.check_achbypass ( p_cust_acct_no, UPPER (TRIM (p_companyname)), 2 );
                    IF v_achbypass='N' THEN
                      v_achbypass:='2';
                      v_respcode := '37';
                      v_errmsg :=
                          'Initial load amount is not loaded for this account';
                      v_queue_flag := 'Y';
                      RAISE exp_main_reject_record;
                    END IF; 
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                           'Error while selecting init_loadamt '
                        || SUBSTR (1, 200);
                     RAISE exp_main_reject_record;
               END;
            END IF;
         END IF;

         IF v_init_loadamt <= v_min_init_loadamt
         THEN
            IF v_topup_cnt = 0
            THEN
               IF v_topcnt_flag = 'N'
               THEN
                  BEGIN
                     SELECT COUNT (1)
                       INTO v_topup_cnt
                       FROM VMSCMS.TRANSACTIONLOG				--Added for VMS-5739/FSP-991
                      WHERE (   (delivery_channel = '08' AND txn_code = '22'
                                )
                             OR (delivery_channel = '10' AND txn_code = '08'
                                )
                             OR (delivery_channel = '07' AND txn_code = '08'
                                )
                             OR (    delivery_channel = '04'
                                 AND txn_code IN ('80', '82', '85', '88')
                                )
                             OR (delivery_channel = '11'
                                 AND txn_code IN ('22')
                                )
                            )
                        AND response_code = '00'
                        AND customer_card_no IN (
                               SELECT cap_pan_code
                                 FROM cms_appl_pan
                                WHERE cap_acct_no = p_cust_acct_no
                                  AND cap_inst_code = p_instcode);
						IF SQL%ROWCOUNT = 0 THEN 
						SELECT COUNT (1)
                       INTO v_topup_cnt
                       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST				--Added for VMS-5739/FSP-991
                      WHERE (   (delivery_channel = '08' AND txn_code = '22'
                                )
                             OR (delivery_channel = '10' AND txn_code = '08'
                                )
                             OR (delivery_channel = '07' AND txn_code = '08'
                                )
                             OR (    delivery_channel = '04'
                                 AND txn_code IN ('80', '82', '85', '88')
                                )
                             OR (delivery_channel = '11'
                                 AND txn_code IN ('22')
                                )
                            )
                        AND response_code = '00'
                        AND customer_card_no IN (
                               SELECT cap_pan_code
                                 FROM cms_appl_pan
                                WHERE cap_acct_no = p_cust_acct_no
                                  AND cap_inst_code = p_instcode);
						END IF;						
                         

                     v_top_flag := 'Y';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_respcode := '21';
                        v_errmsg :=
                              'Error while selecting topup_cnt '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_main_reject_record;
                  END;
               END IF;

               IF v_topup_cnt = 0
               THEN
                 v_achbypass:=vmsusach.check_achbypass ( p_cust_acct_no, UPPER (TRIM (p_companyname)), 3 );
                 IF v_achbypass='N' THEN
                  v_achbypass:='3';
                  v_respcode := '37';
                   v_errmsg :=
                      'Initial load amount is less than configured minimum load amount';
                   v_queue_flag := 'Y';
                   RAISE exp_main_reject_record;
                 END IF;  
               END IF;
            END IF;
         END IF;
      ELSIF v_check_flag = 'Y'
      THEN
         IF v_topup_cnt = 0
         THEN
            IF v_topcnt_flag = 'N'
            THEN
               BEGIN
                  SELECT COUNT (1)
                    INTO v_topup_cnt
                    FROM VMSCMS.TRANSACTIONLOG 				--Added for VMS-5739/FSP-991
                   WHERE (   (delivery_channel = '08' AND txn_code = '22')
                          OR (delivery_channel = '10' AND txn_code = '08')
                          OR (delivery_channel = '07' AND txn_code = '08')
                          OR (    delivery_channel = '04'
                              AND txn_code IN ('80', '82', '85', '88')
                             )
                          OR (delivery_channel = '11' AND txn_code IN ('22')
                             )
                         )
                     AND response_code = '00'
                     AND customer_card_no IN (
                            SELECT cap_pan_code
                              FROM cms_appl_pan
                             WHERE cap_acct_no = p_cust_acct_no
                               AND cap_inst_code = p_instcode);
						IF SQL%ROWCOUNT = 0 THEN 
						 SELECT COUNT (1)
                    INTO v_topup_cnt
                    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST 				--Added for VMS-5739/FSP-991
                   WHERE (   (delivery_channel = '08' AND txn_code = '22')
                          OR (delivery_channel = '10' AND txn_code = '08')
                          OR (delivery_channel = '07' AND txn_code = '08')
                          OR (    delivery_channel = '04'
                              AND txn_code IN ('80', '82', '85', '88')
                             )
                          OR (delivery_channel = '11' AND txn_code IN ('22')
                             )
                         )
                     AND response_code = '00'
                     AND customer_card_no IN (
                            SELECT cap_pan_code
                              FROM cms_appl_pan
                             WHERE cap_acct_no = p_cust_acct_no
                               AND cap_inst_code = p_instcode);
END IF;						
                     

                  v_top_flag := 'Y';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_respcode := '21';
                     v_errmsg :=
                           'Error while selecting topup_cnt '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_main_reject_record;
               END;
            END IF;

            IF v_topup_cnt = 0
            THEN
             v_achbypass:=vmsusach.check_achbypass ( p_cust_acct_no, UPPER (TRIM (p_companyname)), 3 );
             IF v_achbypass='N' THEN
               v_achbypass:='3';
               v_respcode := '37';
               v_errmsg :=
                  'Initial load amount is less than configured minimum load amount';
               v_queue_flag := 'Y';
               RAISE exp_main_reject_record;
             END IF;  
            END IF;
         END IF;
      END IF;

      IF v_init_flag = 'Y' OR v_top_flag = 'Y'
      THEN
         BEGIN
            UPDATE cms_acct_mast
               SET cam_initialload_amt = v_init_loadamt,
                   cam_topuptrans_count = v_topup_cnt,
                   cam_initamt_flag =
                                DECODE (v_init_flag,
                                        'Y', 'Y',
                                        v_initamt_flag
                                       ),
                   cam_topcnt_flag =
                                  DECODE (v_top_flag,
                                          'Y', 'Y',
                                          v_topcnt_flag
                                         )
             WHERE cam_acct_no = p_cust_acct_no AND cam_inst_code = p_instcode;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
      
       
        IF v_gpr_cnt =0 and v_gpr_chkflag IS NULL and V_GPR_CHECK_FLAG = 'Y' THEN --Modified for NCGPR-1581
         v_achbypass:=vmsusach.check_achbypass ( p_cust_acct_no, UPPER (TRIM (p_companyname)), 6 );
         IF v_achbypass='N' THEN
            v_achbypass :='6';   
            v_respcode := '39';
            v_errmsg := 'GPR card is not generated for this account';
            RAISE exp_main_reject_record;
         END IF;   
        END IF;       

 
   END IF;

   IF v_cap_prod_catg = 'P'
   THEN
      v_ach_filename := p_achfilename;

      BEGIN
         sp_authorize_txn_cms_auth_ach (p_instcode,
                                        p_msg,
                                        p_rrn,
                                        p_delivery_channel,
                                        p_terminalid,
                                        p_txn_code,
                                        p_txn_mode,
                                        p_trandate,
                                        p_trantime,
                                        p_panno,
                                        NULL,
                                        p_amount,
                                        NULL,
                                        NULL,
                                        NULL,
                                        p_currcode,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        p_mbr_numb,
                                        p_rvsl_code,
                                        v_tran_amt,
                                        p_achfilename,
                                        p_odfi,
                                        p_rdfi,
                                        p_seccode,
                                        p_impdate,
                                        p_processdate,
                                        p_effectivedate,
                                        p_tracenumber,
                                        p_incoming_crfileid,
                                        p_achtrantype_id,
                                        v_start_ledger_balance,
                                        v_start_acct_balance,
                                        p_indidnum,
                                        p_indname,
                                        p_companyname,
                                        p_companyid,
                                        p_id,
                                        p_compentrydesc,
                                        v_custlastname,
                                        v_cap_card_stat,
                                        p_processtype,
                                        p_auth_id,
                                        v_custfirstname,
                                        v_ach_exp_flag,
                                        v_respcode,
                                        v_resp_code,
                                        v_respmsg,
                                        v_capture_date
                                       );

         IF v_resp_code <> '00' AND v_respmsg <> 'OK'
         THEN
            p_errmsg := v_respmsg;
            p_resp_code := v_resp_code;
            RAISE exp_auth_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_auth_reject_record
         THEN
            RAISE;
         WHEN exp_main_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   END IF;

   p_auth_id := v_auth_id;

   BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM cms_spprt_reasons
       WHERE csr_spprt_key = 'TOP UP' AND csr_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Top up reason code is present in master';
         v_respcode := '21';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   BEGIN
      INSERT INTO cms_pan_spprt
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,
                   cps_pan_code_encr
                  )
           VALUES (p_instcode, v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'TOP', v_resoncode, v_topupremrk,
                   p_lupduser, p_lupduser, 0,
                   v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   v_respcode := 1;

   BEGIN
   
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)

    THEN
      UPDATE cms_transaction_log_dtl
         SET ctd_source_name = p_source_name,
             ctd_originator_statcode = p_federal_ind
       WHERE ctd_rrn = p_rrn
         AND ctd_business_date = p_trandate
         AND ctd_business_time = p_trantime
         AND ctd_delivery_channel = p_delivery_channel
         AND ctd_txn_code = p_txn_code
         AND ctd_msg_type = p_msg          
         AND ctd_customer_card_no = v_hash_pan;
ELSE
		UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST			--Added for VMS-5733/FSP-991
         SET ctd_source_name = p_source_name,
             ctd_originator_statcode = p_federal_ind
       WHERE ctd_rrn = p_rrn
         AND ctd_business_date = p_trandate
         AND ctd_business_time = p_trantime
         AND ctd_delivery_channel = p_delivery_channel
         AND ctd_txn_code = p_txn_code
         AND ctd_msg_type = p_msg          
         AND ctd_customer_card_no = v_hash_pan;
END IF;
		 
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem on updated cms_Transaction_log_dtl '
            || SUBSTR (SQLERRM, 1, 200);
   END;

   BEGIN
      p_errmsg := v_errmsg;
      p_resp_code := v_respcode;

      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_instcode
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = v_respcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_errmsg :=
                   'Data not available in response master for ' || v_respcode;
         
         p_resp_code := 'R16';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Problem while selecting data from response master '
            || v_respcode
            || SUBSTR (SQLERRM, 1, 300);
         
         p_resp_code := 'R16';
         RAISE exp_main_reject_record;
   END;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal
        INTO v_acct_balance, v_ledger_balance
        FROM cms_acct_mast
       WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_instcode;

      p_endledgerbal := v_ledger_balance;
      p_endaccountbalance := v_acct_balance;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '16';
         v_errmsg := 'Invalid Card ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :='Error while selecting acct dtls ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      SELECT COUNT (*)
        INTO v_file_count
        FROM cms_ach_fileprocess
       WHERE caf_ach_file = p_achfilename AND caf_inst_code = p_instcode;

      IF v_file_count = 0
      THEN
         INSERT INTO cms_ach_fileprocess
                     (caf_inst_code, caf_ach_file, caf_tran_date,
                      caf_lupd_user, caf_ins_user
                     )
              VALUES (p_instcode, p_achfilename, p_trandate,
                      p_lupduser, p_lupduser
                     );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into ACH File Processing table    '
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   BEGIN
      IF (v_gpr_chkflag = 'N')
      THEN
          IF v_cap_card_stat = 1 AND v_gpr_cnt = 0
         THEN
            IF v_staterissusetype = 'M'
            THEN
               UPDATE cms_appl_mast
                  SET cam_appl_stat = 'A'
                WHERE cam_appl_code = v_appl_code AND cam_inst_code = p_instcode;
 
                  BEGIN
                     sp_gen_pan (p_instcode,
                                 v_appl_code,
                                 1,
                                 v_pancode,
                                 v_processmsg,
                                 v_respmsg
                                );

                     IF v_processmsg <> 'OK'
                     THEN
                        v_respcode := '21';
                        v_errmsg := v_processmsg;
                        RAISE exp_main_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_main_reject_record
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_respcode := '21';
                        v_errmsg :=
                              'Error while calling SP_GEN_PAN '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_main_reject_record;
                  END;
                  
                            --AVQ  --Added for FSS-1961(Melissa)         
          BEGIN
               SELECT fn_dmaps_main (cap_pan_code_encr)                    
                 INTO p_pan_number                     
                 FROM cms_appl_pan
                WHERE cap_appl_code = v_appl_code
                  AND cap_inst_code = P_INSTCODE
                  AND cap_cust_code = v_cust_code
                  AND cap_startercard_flag = 'N';
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    v_respcode := '21';
                    v_errmsg := 'Error while selecting (gpr card)details from appl_pan :'
                       || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_MAIN_REJECT_RECORD;
            end;
            
                BEGIN
                    SP_LOGAVQSTATUS(
                          P_INSTCODE,
                          P_DELIVERY_CHANNEL,
                          p_pan_number,
                          V_PROD_CODE,
                          V_CUST_CODE,
                          V_RESPCODE,
                          p_errmsg,
                          v_card_type
                          );
                  IF p_errmsg != 'OK' THEN
                     v_errmsg  := 'Exception while calling LOGAVQSTATUS-- ' || p_errmsg;
                     V_RESPCODE := '21';
                  RAISE EXP_MAIN_REJECT_RECORD;         
                  END IF;
                EXCEPTION WHEN EXP_MAIN_REJECT_RECORD
                THEN  RAISE;
                WHEN OTHERS THEN
                   v_errmsg  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
                   V_RESPCODE := '21';
                   RAISE EXP_MAIN_REJECT_RECORD;
              END;             
              
               END IF;
            
         END IF;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

	IF v_dr_cr_flag = 'CR' 
      AND v_prfl_code IS NOT NULL
      AND v_prfl_flag = 'Y'
   THEN
      BEGIN
         pkg_limits_check.sp_limitcnt_reset (p_instcode,
                                             v_hash_pan,
                                             v_tran_amt,
                                             v_comb_hash,
                                             v_respcode,
                                             v_errmsg
                                            );

         IF v_errmsg <> 'OK'
         THEN
            v_errmsg := 'From Procedure sp_limitcnt_reset' || p_errmsg;
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error from Limit Reset Count Process '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   END IF;
   
    BEGIN        
      IF v_queue_name IS NULL THEN 
              lp_purge_q;
      END IF;   
      
      SELECT REGEXP_REPLACE(NVL((DECODE( p_companyname ,'','','/'||p_companyname) ||
            DECODE( p_compentrydesc ,'','','/'||p_compentrydesc) ||
            DECODE( p_indname ,'','','/'||p_indidnum||' to '||p_indname)),'Direct Deposit'),'/','',1,1)
      INTO V_MERC_NAME
      FROM dual;
 
        
       achaq.enqueue_ach_msgs (ach_type (p_rrn,
                                         p_trandate,
                                         p_trantime,
                                         p_txn_code,
                                         p_delivery_channel,
                                         v_trans_desc,
                                         v_hash_pan,
                                         v_encr_pan,
                                         v_cap_card_stat,
                                         v_tran_amt,
                                         NULL,
                                         SYSDATE,
                                         p_achfilename,
                                         NULL,
                                         'N',
                                         p_auth_id,
                                         p_indname,
                                         v_acct_balance,
                                         v_ledger_balance,
                                         v_respcode,
                                         p_resp_code,
                                         v_merc_name),
                               NVL (v_queue_name, 'ACH_ACHVIEW_QUEUE'),
                               v_errmsg);
        IF v_errmsg <> 'OK'
         THEN
            v_errmsg := 'Error in enqueue_ach_msgs ACH_ACHVIEW_QUEUE ' || v_errmsg;
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record THEN
             RAISE;
            
         WHEN OTHERS    THEN
            V_RESPCODE := '21';
            v_errmsg := 'Error while enqueue ACH_ACHVIEW_QUEUE ' || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
      END;
   
EXCEPTION
   WHEN exp_auth_reject_record
   THEN
      IF v_ach_exp_flag = 'FD'
      THEN
         IF (v_respcode IN
                ('20', '23', '30', '24', '25', '28', '29', '35', '36', '40',
                 '41')
            )
         THEN
            p_resp_code := 'R23';
         ELSIF v_respcode='10' AND v_cap_card_stat='11'
         THEN
             p_resp_code := 'R16';
         ELSIF v_respcode='10'
         THEN   
         
          p_resp_code := 'R16';
         ELSE
            p_resp_code := 'R17';
         END IF;

         BEGIN
            IF (v_respcode IN
                   ('37', '24', '25', '28', '29', '35', '36', '40', '41',
                    '20', '23','74')
               )
            THEN
			
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
               UPDATE transactionlog
                  SET response_code = p_resp_code,
                      ach_exception_queue_flag =
                                          DECODE (v_queue_flag,
                                                  'Y', 'FD',
                                                  ''
                                                 )
                WHERE rrn = p_rrn
                  AND delivery_channel = p_delivery_channel
                  AND txn_code = p_txn_code
                  AND customer_card_no = v_hash_pan                   
                  AND business_date = p_trandate;
ELSE
				UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                  SET response_code = p_resp_code,
                      ach_exception_queue_flag =
                                          DECODE (v_queue_flag,
                                                  'Y', 'FD',
                                                  ''
                                                 )
                WHERE rrn = p_rrn
                  AND delivery_channel = p_delivery_channel
                  AND txn_code = p_txn_code
                  AND customer_card_no = v_hash_pan                   
                  AND business_date = p_trandate; 
END IF;				  

                IF v_queue_flag='Y' THEN
                     v_queue_name :='ACH_FEDEXCP_QUEUE';
                END IF;

            else
			
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN			
              UPDATE transactionlog
                  SET response_code = p_resp_code,
                      ach_exception_queue_flag = ''
                WHERE rrn = p_rrn
                  AND delivery_channel = p_delivery_channel
                  AND txn_code = p_txn_code
                  AND customer_card_no = v_hash_pan                  
                  AND business_date = p_trandate;
ELSE
				UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                  SET response_code = p_resp_code,
                      ach_exception_queue_flag = ''
                WHERE rrn = p_rrn
                  AND delivery_channel = p_delivery_channel
                  AND txn_code = p_txn_code
                  AND customer_card_no = v_hash_pan                  
                  AND business_date = p_trandate;
END IF;				  
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while updating transactionlog '
                  || SUBSTR (SQLERRM, 1, 200);
         END;
         ELSE
         
             IF v_respcode='10' AND v_cap_card_stat='11'
             THEN
                 p_resp_code := 'R16';
             --Added for VMS-5739/FSP-991
	   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)

    THEN
             
              UPDATE transactionlog
                  SET response_code = p_resp_code
                WHERE rrn = p_rrn
                  AND delivery_channel = p_delivery_channel
                  AND txn_code = p_txn_code
                  AND customer_card_no = v_hash_pan
                  AND business_date = p_trandate;
ELSE
				UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                  SET response_code = p_resp_code
                WHERE rrn = p_rrn
                  AND delivery_channel = p_delivery_channel
                  AND txn_code = p_txn_code
                  AND customer_card_no = v_hash_pan
                  AND business_date = p_trandate;
END IF;				  
             END IF;
             
             IF v_respcode IN('37','74') THEN 
                  v_queue_name :='ACH_EXCP_QUEUE';
             END IF;     

      END IF;
      
     IF p_processtype <> 'N' THEN
        BEGIN        
         IF v_queue_name IS NULL THEN 
              lp_purge_q;
         END IF;   
         
          SELECT REGEXP_REPLACE(NVL((DECODE( p_companyname ,'','','/'||p_companyname) ||
                DECODE( p_compentrydesc ,'','','/'||p_compentrydesc) ||
                DECODE( p_indname ,'','','/'||p_indidnum||' to '||p_indname)),'Direct Deposit'),'/','',1,1)
          INTO V_MERC_NAME
          FROM dual;

           achaq.enqueue_ach_msgs (ach_type (p_rrn,
                                             p_trandate,
                                             p_trantime,
                                             p_txn_code,
                                             p_delivery_channel,
                                             v_trans_desc,
                                             v_hash_pan,
                                             v_encr_pan,
                                             v_cap_card_stat,
                                             v_tran_amt,
                                             NULL,
                                             SYSDATE,
                                             p_achfilename,
                                             NULL,
                                             'N',
                                             p_auth_id,
                                             p_indname,
                                             v_acct_balance,
                                             v_ledger_balance,
                                             v_respcode,
                                             p_resp_code,
                                             v_merc_name),
                                   NVL (v_queue_name, 'ACH_ACHVIEW_QUEUE'),
                                   v_errmsg);
         IF v_errmsg <> 'OK'
         THEN
            v_errmsg := 'Error in enqueue_ach_msgs1 ACH_ACHVIEW_QUEUE ' || v_errmsg;
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record THEN
            --RAISE;
            null;
         WHEN OTHERS    THEN
            V_RESPCODE := '21';
            v_errmsg := 'Error while enqueue1 ACH_ACHVIEW_QUEUE ' || SUBSTR (SQLERRM, 1, 200);
            --RAISE exp_main_reject_record;
      END;
     END IF;      

      BEGIN
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)

    THEN
         UPDATE cms_transaction_log_dtl
            SET ctd_source_name = p_source_name,
                ctd_originator_statcode = p_federal_ind,
                ctd_process_msg = v_errmsg
          WHERE ctd_rrn = p_rrn
            AND ctd_business_date = p_trandate
            AND ctd_business_time = p_trantime
            AND ctd_delivery_channel = p_delivery_channel
            AND ctd_txn_code = p_txn_code
            AND ctd_msg_type = p_msg            
            AND ctd_customer_card_no = v_hash_pan;
ELSE
		UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991
            SET ctd_source_name = p_source_name,
                ctd_originator_statcode = p_federal_ind,
                ctd_process_msg = v_errmsg
          WHERE ctd_rrn = p_rrn
            AND ctd_business_date = p_trandate
            AND ctd_business_time = p_trantime
            AND ctd_delivery_channel = p_delivery_channel
            AND ctd_txn_code = p_txn_code
            AND ctd_msg_type = p_msg            
            AND ctd_customer_card_no = v_hash_pan;
END IF;
			
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem on updated cms_Transaction_log_dtl '
               || SUBSTR (SQLERRM, 1, 200);
      END;
   WHEN exp_main_reject_record
   THEN
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_balance, v_ledger_balance, v_cam_type_code
           FROM cms_acct_mast
          WHERE cam_acct_no = p_cust_acct_no AND cam_inst_code = p_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
      END;

      IF v_init_flag = 'Y' OR v_top_flag = 'Y'
      THEN
         BEGIN
            UPDATE cms_acct_mast
               SET cam_initialload_amt = v_init_loadamt,
                   cam_topuptrans_count = v_topup_cnt,
                   cam_initamt_flag =
                                DECODE (v_init_flag,
                                        'Y', 'Y',
                                        v_initamt_flag
                                       ),
                   cam_topcnt_flag =
                                  DECODE (v_top_flag,
                                          'Y', 'Y',
                                          v_topcnt_flag
                                         )
             WHERE cam_acct_no = p_cust_acct_no AND cam_inst_code = p_instcode;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      BEGIN
         p_errmsg := v_errmsg;

         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg :=
               'Response code not available in response master '
               || v_respcode;
           
            p_resp_code := 'R16';
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
             
             p_resp_code := 'R16';
      END;

      IF v_ach_exp_flag = 'FD'
      THEN
         IF (v_respcode IN
                ('20', '23', '30', '24', '25', '28', '29', '35', '36', '40',
                 '41')
            )
         THEN
            p_resp_code := 'R23';
         ELSE
            p_resp_code := 'R17';
         END IF;

         IF (v_respcode IN
                ('37', '24', '25', '28', '29', '35', '36', '40', '41', '20',
                 '23','74')
            )
         THEN
            IF (v_queue_flag = 'Y')
            THEN
               v_ach_exp_flag := 'FD';
               v_queue_name :='ACH_FEDEXCP_QUEUE';
            ELSE
               v_ach_exp_flag := '';
            END IF;
         ELSE
            v_ach_exp_flag := '';
         END IF;
      ELSE
          IF v_respcode IN('37','74') THEN 
               v_queue_name :='ACH_EXCP_QUEUE';
          ELSIF  v_respcode='254' THEN
                v_queue_name :='ACH_REVERSAL_QUEUE';    
          END IF;
      END IF;

      v_respcode_org_txn := p_resp_code;

      BEGIN
         SELECT COUNT (*)
           INTO v_file_count
           FROM cms_ach_fileprocess
          WHERE caf_ach_file = p_achfilename AND caf_inst_code = p_instcode;

         IF v_file_count = 0
         THEN
            INSERT INTO cms_ach_fileprocess
                        (caf_inst_code, caf_ach_file, caf_tran_date,
                         caf_lupd_user, caf_ins_user
                        )
                 VALUES (p_instcode, p_achfilename, p_trandate,
                         p_lupduser, p_lupduser
                        );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting records into ACH File Processing table '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      IF v_rrn_count > 0
      THEN
         IF TO_NUMBER (p_delivery_channel) = 11
         THEN
            BEGIN
               SELECT acct_balance, ledger_balance, auth_id,
                      befretran_ledgerbal, befretran_availbalance
                 INTO p_endaccountbalance, p_endledgerbal, p_auth_id,
                      p_startledgerbal, p_startaccountbalance
                 FROM VMSCMS.TRANSACTIONLOG a,		--Added for VMS-5733/FSP-991
                      (SELECT MIN (add_ins_date) mindate
                         FROM VMSCMS.TRANSACTIONLOG		--Added for VMS-5733/FSP-991
                        WHERE rrn = p_rrn) b
                WHERE a.add_ins_date = mindate AND rrn = p_rrn;
				IF SQL%ROWCOUNT = 0 THEN
				SELECT acct_balance, ledger_balance, auth_id,
                      befretran_ledgerbal, befretran_availbalance
                 INTO p_endaccountbalance, p_endledgerbal, p_auth_id,
                      p_startledgerbal, p_startaccountbalance
                 FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST a,		--Added for VMS-5733/FSP-991
                      (SELECT MIN (add_ins_date) mindate
                         FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST		--Added for VMS-5733/FSP-991
                        WHERE rrn = p_rrn) b
                WHERE a.add_ins_date = mindate AND rrn = p_rrn;				
				END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem in selecting the response detail of Original transaction'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code := '89';
            END;
         END IF;
      END IF;

      IF v_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat
              INTO v_prod_code, v_card_type, v_cap_card_stat
              FROM cms_appl_pan
             WHERE cap_pan_code = gethash (p_panno);
                     
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_dr_cr_flag IS NULL
      THEN
         BEGIN
		 
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_desc
              INTO v_dr_cr_flag,
                   v_txn_type,
                   v_trans_desc
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code
               AND ctm_delivery_channel = p_delivery_channel
               AND ctm_inst_code = p_instcode;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      v_timestamp := SYSTIMESTAMP;
      
       BEGIN
            SELECT COUNT(*) INTO V_BANK_SEC_COUNT FROM VMS_ISSUBANK_MAST,VMS_BANKFEATURE_MAST,CMS_PROD_CATTYPE WHERE 
            VIM_BANK_ID=VBM_BANK_ID 
            AND CPC_ISSU_BANK=VIM_BANK_NAME
            AND UPPER(P_SECCODE)='WEB'
            AND CPC_PROD_CODE=V_PROD_CODE AND CPC_CARD_TYPE=V_CARD_TYPE
            AND VBM_FEATURE_ID=1;            
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;

      IF v_respcode NOT IN ('45', '32')
      THEN
         IF p_processtype <> 'N'
         THEN
            BEGIN
               INSERT INTO transactionlog
                           (msgtype, rrn, delivery_channel, terminal_id,
                            txn_code, txn_type, txn_mode,
                            txn_status,
                            response_code, business_date,
                            business_time, customer_card_no,
                            topup_card_no, topup_acct_no, topup_acct_type,
                            bank_code,
                            total_amount,
                            currencycode, addcharge, productid, categoryid,
                            atm_name_location, auth_id,
                            amount,
                            preauthamount, partialamount, instcode,
                            customer_card_no_encr, topup_card_no_encr,
                            proxy_number, reversal_code, customer_acct_no,
                            acct_balance, ledger_balance, achfilename,
                            rdfi, seccodes, impdate, processdate,
                            effectivedate, tracenumber,
                            incoming_crfileid, achtrantype_id,
                            indidnum, indname, companyname,
                            companyid, ach_id, compentrydesc, response_id,
                            customerlastname, cardstatus, processtype,
                            trans_desc, custfirstname,
                            ach_exception_queue_flag, odfi, merchant_name,
                            error_msg, cr_dr_flag, time_stamp,
                            acct_type
                           )
                    VALUES (p_msg, p_rrn, p_delivery_channel, p_terminalid,
                            p_txn_code, v_txn_type, p_txn_mode,
                            DECODE (v_respcode_org_txn, '00', 'C', 'F'),
                            v_respcode_org_txn, p_trandate,
                            SUBSTR (p_trantime, 1, 10), v_hash_pan,
                            v_hash_pan, p_cust_acct_no, NULL,
                            p_instcode,
                            TRIM (TO_CHAR (v_tran_amt,
                                           '999999999999999990.99')
                                 ),
                            p_currcode, v_achbypass, v_prod_code, v_card_type,
                            p_terminalid, v_auth_id,
                            TRIM (TO_CHAR (v_tran_amt, '99999999999999990.99')),
                            NULL, NULL, p_instcode,
                            v_encr_pan, v_encr_pan,
                            v_proxunumber, p_rvsl_code, p_cust_acct_no,
                            v_acct_balance, v_ledger_balance, p_achfilename,
                            p_rdfi, p_seccode, p_impdate, p_processdate,
                            p_effectivedate, p_tracenumber,
                            p_incoming_crfileid, p_achtrantype_id,
                            DECODE(NVL(LENGTH(TRIM(TRANSLATE(SUBSTR(TRIM (RTRIM (LTRIM (UPPER (p_indidnum), 'IRS'), 'IRS')),1,9), '0123456789',' '))),0),0,DECODE(V_BANK_SEC_COUNT,0,FN_MASKACCT_SSN(P_INSTCODE,P_INDIDNUM ,0),P_INDIDNUM),p_INDIDNUM),
                            p_indname, p_companyname,
                            p_companyid, p_id, p_compentrydesc, v_respcode,
                            v_custlastname, v_cap_card_stat, p_processtype,
                            v_trans_desc, v_custfirstname,
                            v_ach_exp_flag, p_odfi, p_companyname,
                            v_errmsg, v_dr_cr_flag, v_timestamp,
                            v_cam_type_code
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code := '89';
                  p_errmsg :=
                        'Problem while inserting data into transaction log  dtl'
                     || SUBSTR (SQLERRM, 1, 300);
            END;
         END IF;

         IF p_processtype = 'N'
         THEN
            BEGIN
			--Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)

    THEN
               UPDATE transactionlog
                  SET processtype = p_processtype,
                      response_code = p_resp_code
                WHERE rrn = p_rrn
                  AND business_date = p_trandate
                  AND txn_code = p_txn_code;
	ELSE
				 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST 	--Added for VMS-5733/FSP-991
                  SET processtype = p_processtype,
                      response_code = p_resp_code
                WHERE rrn = p_rrn
                  AND business_date = p_trandate
                  AND txn_code = p_txn_code;
	END IF;			  
                   
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem while  updating data into transaction log'
                     || SUBSTR (SQLERRM, 1, 300);
                  p_resp_code := '21';
            END;
         END IF;
      END IF;
      
      IF p_processtype <> 'N' THEN
        BEGIN
         IF v_queue_name IS NULL THEN 
              lp_purge_q;
         END IF;     
         
        SELECT REGEXP_REPLACE(NVL((DECODE( p_companyname ,'','','/'||p_companyname) ||
              DECODE( p_compentrydesc ,'','','/'||p_compentrydesc) ||
              DECODE( p_indname ,'','','/'||p_indidnum||' to '||p_indname)),'Direct Deposit'),'/','',1,1)
        INTO V_MERC_NAME
        FROM dual;

            
           achaq.enqueue_ach_msgs (ach_type (p_rrn,
                                             p_trandate,
                                             p_trantime,
                                             p_txn_code,
                                             p_delivery_channel,
                                             v_trans_desc,
                                             v_hash_pan,
                                             v_encr_pan,
                                             v_cap_card_stat,
                                             v_tran_amt,
                                             NULL,
                                             SYSDATE,
                                             p_achfilename,
                                             NULL,
                                             'N',
                                             p_auth_id,
                                             p_indname,
                                             v_acct_balance,
                                             v_ledger_balance,
                                             v_respcode,
                                             p_resp_code,
                                             v_merc_name),
                                   NVL (v_queue_name, 'ACH_ACHVIEW_QUEUE'),
                                   v_errmsg);
        IF v_errmsg <> 'OK'
         THEN
            v_errmsg := 'Error in enqueue_ach_msgs2 ACH_ACHVIEW_QUEUE ' || v_errmsg;
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record THEN
            --RAISE;
            null;
         WHEN OTHERS    THEN
            V_RESPCODE := '21';
            v_errmsg := 'Error while enqueue2 ACH_ACHVIEW_QUEUE ' || SUBSTR (SQLERRM, 1, 200);
            --RAISE exp_main_reject_record;
			null;
      END;
      END IF;  
      
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number,
                      ctd_txn_type, ctd_source_name, ctd_originator_statcode
                     )
              VALUES (p_delivery_channel, p_txn_code, p_msg,
                      p_txn_mode, p_trandate, p_trantime,
                      v_hash_pan, p_amount, p_currcode,
                      p_amount, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      p_errmsg, p_rrn, p_instcode,
                      v_encr_pan, p_cust_acct_no,
                      v_txn_type, p_source_name, p_federal_ind
                     );

         p_errmsg := v_errmsg;
         RETURN;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
            ROLLBACK;
            RETURN;
      END;

      p_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      p_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;


/

show error;