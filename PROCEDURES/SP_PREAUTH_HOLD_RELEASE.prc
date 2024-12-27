CREATE OR REPLACE PROCEDURE VMSCMS.SP_PREAUTH_HOLD_RELEASE (
   prm_inst_code             IN       NUMBER,
   prm_msg_typ               IN       VARCHAR2,
   prm_rvsl_code             IN       VARCHAR2,
   prm_rrn                   IN       VARCHAR2,
   prm_delv_chnl             IN       VARCHAR2,
   prm_terminal_id           IN       VARCHAR2, 
   prm_merc_id               IN       VARCHAR2,
   prm_txn_code              IN       VARCHAR2,
   prm_txn_type              IN       VARCHAR2,
   prm_txn_mode              IN       VARCHAR2,
   prm_business_date         IN       VARCHAR2,
   prm_business_time         IN       VARCHAR2,
   prm_card_no               IN       VARCHAR2,
   prm_actual_amt            IN       NUMBER,
   prm_bank_code             IN       VARCHAR2,
   prm_stan                  IN       VARCHAR2,
   prm_orgnl_business_date   IN       VARCHAR2,
   prm_orgnl_business_time   IN       VARCHAR2,
   prm_orgnl_txn_code        IN       VARCHAR2, -- added on 14Sep2012
   prm_orgnl_delivery_chnl   IN       VARCHAR2, -- added on 14Sep2012
   prm_orgnl_rrn             IN       VARCHAR2,
   prm_mbr_numb              IN       VARCHAR2,
   prm_orgnl_terminal_id     IN       VARCHAR2,
   prm_curr_code             IN       VARCHAR2,
   prm_remark                IN       VARCHAR2,
   prm_reason_code           IN       VARCHAR2,
   prm_reason_desc           IN       VARCHAR2,
   prm_call_id               IN       NUMBER,
   prm_ins_user              IN       NUMBER,
   prm_merchant_name         IN       VARCHAR2,
   prm_merchant_city         IN       VARCHAR2,
   prm_merc_state            IN       VARCHAR2,
   prm_ipaddress             IN       VARCHAR2, --added by amit on 07-Oct-2012
   prm_call_card_no          IN       VARCHAR2,--Added by Dnyaneshwar J on 30 Sept 2013
   prm_resp_cde              OUT      VARCHAR2,
   prm_acct_bal              OUT      VARCHAR2,
   prm_resp_msg              OUT      VARCHAR2
)
IS
/******************************************************************************************************
     * Created Date     : 30/Jan/2012.
     * Created By       : Sagar More.
     * Purpose          : to release hold amount of customer in account balance
     * modified by      : B.Besky
     * modified Date    : 08-OCT-12
     * modified reason  : Added IN Parameters in SP_STATUS_CHECK_GPR
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 08-OCT-12
     * Build Number     : CMS3.5.1_RI0021

     * modified by      : Sagar
     * modified for     : Defect 605
     * modified Date    : 08-NOV-12
     * modified reason  : To subtract varibale value from column hold amount

     * modified by      : Sagar
     * modified for     : Defect 0010690
     * modified Date    : 03-APR-13
     * modified reason  : To log original transaction merchant details in Transactionlog table
     * Reviewer         : Dhiraj
     * Reviewed Date    : 03-APR-13
     * Build Number     : RI0024.1_B0004

     * Modified by      :  Pankaj S.
     * Modified Reason  :  10871
     * Modified Date    :  19-Apr-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     :  RI0024.1_B0013

     * Modified by      :  Abhay R.
     * Modified Reason  :  0011216
     * Modified Date    :  11-Jun-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  11-Jun-2013
     * Build Number     :  RI0024.2_B0002

     * Modified by      :  Siva Kumar M
     * Modified Reason  :  Defect Id: 12166
     * Modified Date    :  12-Sept-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  12-Sept-2013
     * Build Number     :  RI0024.4_B0011

     * Modified by      :  Dnyaneshwar J
     * Modified Reason  :  MVCSD-4480
     * Modified Date    :  30-Sept-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  30-Sept-2013
     * Build Number     :  RI0024.5_B0002
     
     * Modified by     :  Abdul Hameed M.A
     * Modified Reason  :  FSS-1731
     * Modified Date    :  03-July-2014
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.3_B0002
     
     * Modified by      :  Pankaj S.
     * Modified Reason  :  FSS-837
     * Modified Date    :  07-Jul-2014
     * Build Number     :  RI0027.3_B0002
     
     * Modified by      : MageshKumar S.
     * Modified Date    : 25-July-14    
     * Modified For     : FWR-48
     * Modified reason  : GL Mapping removal changes
     * Reviewer         : Spankaj    
     * Build Number     : RI0027.3.1_B0001

    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 23-June-15
    * Modified For      : FSS 1960
    * Reviewer          : Pankaj S
    * Build Number      : VMSGPRHOSTCSD_3.1_B0001

     * Modified By      : Abdul Hameed M.A 
     * Modified Date    : 09-SEP-2015
     * Modified for     : FSS 3643
     * Reviewer         : Spankaj
     * Release Number   : VMSGPRHOSTCSD_3.1_B00010

     * Modified by      : Pankaj S.
     * Modified for     : FSS-5126: Free Fee Issue
     * Modified Date    : 26-June-2017
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_17.06 
     
         * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
	
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
	
	* Modified By      : Karthick/Jey
    * Modified Date    : 05-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991
 *******************************************************************************************************/
   v_orgnl_delivery_channel     transactionlog.delivery_channel%TYPE;
   v_orgnl_resp_code            transactionlog.response_code%TYPE;
   v_orgnl_terminal_id          transactionlog.terminal_id%TYPE;
   v_orgnl_txn_code             transactionlog.txn_code%TYPE;
   v_orgnl_txn_type             transactionlog.txn_type%TYPE;
   v_orgnl_txn_mode             transactionlog.txn_mode%TYPE;
   v_orgnl_business_date        transactionlog.business_date%TYPE;
   v_orgnl_business_time        transactionlog.business_time%TYPE;
   v_orgnl_customer_card_no     transactionlog.customer_card_no%TYPE;
   v_orgnl_total_amount         transactionlog.amount%TYPE;
   v_actual_amt                 NUMBER (9, 2);
   v_reversal_amt               NUMBER (9, 2);
   v_orgnl_txn_feecode          cms_fee_mast.cfm_fee_code%TYPE;
   v_orgnl_txn_feeattachtype    transactionlog.feeattachtype%type; -- CHANGED FROM VARCHAR2(1) TO COLUMN DEFINITION
   v_orgnl_txn_totalfee_amt     transactionlog.tranfee_amt%TYPE;
   v_orgnl_txn_servicetax_amt   transactionlog.servicetax_amt%TYPE;
   v_orgnl_txn_cess_amt         transactionlog.cess_amt%TYPE;
   v_orgnl_transaction_type     transactionlog.cr_dr_flag%TYPE;
   v_actual_dispatched_amt      transactionlog.amount%TYPE;
   v_resp_cde                   VARCHAR2 (3);
   v_func_code                  cms_func_mast.cfm_func_code%TYPE;
   v_dr_cr_flag                 transactionlog.cr_dr_flag%TYPE;
   v_orgnl_trandate             DATE;
   v_rvsl_trandate              DATE;
   v_orgnl_termid               transactionlog.terminal_id%TYPE;
   v_orgnl_mcccode              transactionlog.mccode%TYPE;
   v_errmsg                     VARCHAR2 (300);
   v_actual_feecode             transactionlog.feecode%TYPE;
   v_orgnl_tranfee_amt          transactionlog.tranfee_amt%TYPE;
   v_orgnl_servicetax_amt       transactionlog.servicetax_amt%TYPE;
   v_orgnl_cess_amt             transactionlog.cess_amt%TYPE;
   v_orgnl_cr_dr_flag           transactionlog.cr_dr_flag%TYPE;
   v_orgnl_tranfee_cr_acctno    transactionlog.tranfee_cr_acctno%TYPE;
   v_orgnl_tranfee_dr_acctno    transactionlog.tranfee_dr_acctno%TYPE;
   v_orgnl_st_calc_flag         transactionlog.tran_st_calc_flag%TYPE;
   v_orgnl_cess_calc_flag       transactionlog.tran_cess_calc_flag%TYPE;
   v_orgnl_st_cr_acctno         transactionlog.tran_st_cr_acctno%TYPE;
   v_orgnl_st_dr_acctno         transactionlog.tran_st_dr_acctno%TYPE;
   v_orgnl_cess_cr_acctno       transactionlog.tran_cess_cr_acctno%TYPE;
   v_orgnl_cess_dr_acctno       transactionlog.tran_cess_dr_acctno%TYPE;
   v_prod_code                  cms_appl_pan.cap_prod_code%TYPE;
   v_card_type                  cms_appl_pan.cap_card_type%TYPE;
   v_gl_upd_flag                transactionlog.gl_upd_flag%TYPE;
   v_tran_reverse_flag          transactionlog.tran_reverse_flag%TYPE;
   v_savepoint                  NUMBER                              DEFAULT 1;
   v_curr_code                  transactionlog.currencycode%TYPE;
   v_auth_id                    transactionlog.auth_id%TYPE;
   v_terminal_indicator         pcms_terminal_mast.ptm_terminal_indicator%TYPE;
   v_cutoff_time                VARCHAR2 (5);
   v_business_time              VARCHAR2 (5);
   exp_rvsl_reject_record       EXCEPTION;
   v_card_acct_no               VARCHAR2 (20);
   v_tran_sysdate               DATE;
   v_tran_cutoff                DATE;
   v_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;   
   v_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
   v_tran_amt                   NUMBER;
   v_delchannel_code            VARCHAR2 (2);
   v_card_curr                  VARCHAR2 (5);
   v_rrn_count                  NUMBER;
   v_base_curr                  cms_bin_param.cbp_param_value%TYPE;
   v_currcode                   VARCHAR2 (3);
   v_acct_balance               NUMBER;
   v_tran_desc                  cms_transaction_mast.ctm_tran_desc%TYPE;
   v_check_preauthcomp          NUMBER;
   v_preauth_expiry_flag        CHARACTER (1);
   v_preauth_valid_flag         CHARACTER (1);
   v_preauth_amount             NUMBER;
   v_expiry_amount              NUMBER;
   v_preauth_comp_amnt          NUMBER;
--   v_atm_usageamnt              cms_translimit_check.ctc_atmusage_amt%TYPE;
--   v_pos_usageamnt              cms_translimit_check.ctc_posusage_amt%TYPE;
--   v_atm_usagelimit             cms_translimit_check.ctc_atmusage_limit%TYPE;
--   v_pos_usagelimit             cms_translimit_check.ctc_posusage_limit%TYPE;
   v_business_date_tran         DATE;
   v_hold_amount                NUMBER;
   v_preauth_usage_limit        NUMBER;
--   v_mmpos_usageamnt            cms_translimit_check.ctc_mmposusage_amt%TYPE;
   v_proxunumber                cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number                cms_appl_pan.cap_acct_no%TYPE;
   v_ledger_bal                 NUMBER;
   authid_date                  VARCHAR2 (8);
   v_max_card_bal               NUMBER;
   v_orgnl_dracct_no            cms_func_prod.cfp_dracct_no%TYPE;
   v_ledge_balance              NUMBER;
   v_txn_narration              cms_statements_log.csl_trans_narrration%TYPE;
   v_fee_narration              cms_statements_log.csl_trans_narrration%TYPE;
   v_reason                     VARCHAR2 (100);
   -- added on 08022012 by sagar to store reason
   v_csr_reason_desc            cms_csrreason_mast.ccm_reason_desc%TYPE;
                                -- added on 08022012 by sagar to store reason
   /* variables added for call log info   start */
   v_table_list                 VARCHAR2 (2000);
   v_colm_list                  VARCHAR2 (2000);
   v_colm_qury                  VARCHAR2 (2000);
   v_old_value                  VARCHAR2 (2000);
   v_new_value                  VARCHAR2 (2000);
   v_call_seq                   NUMBER (3);
/* variables added for call log info   END */

   /* variables added for GPR start */
   v_status_chk                 NUMBER;
   v_expry_date                 cms_appl_pan.cap_expry_date%TYPE;
   v_card_stat                  cms_appl_pan.cap_card_stat%TYPE;
   v_check_statcnt              NUMBER (1);
/* variables added for GPR END */
   v_spnd_acctno                cms_appl_pan.cap_acct_no%TYPE;
                                              -- ADDED BY GANESH ON 19-JUL-12
   v_fee_reversal_flag          transactionlog.fee_reversal_flag%type;

    --SN: Added on 03-Apr-2013 for defect 0010690
    v_merchant_zip  transactionlog.merchant_zip%type;
    v_merchant_id   transactionlog.merchant_id%type;
    v_merchant_name transactionlog.merchant_name%type;
    v_merchant_state transactionlog.merchant_state%type;
    v_merchant_city  transactionlog.merchant_city%type;
    --EN: Added on 03-Apr-2013 for defect 0010690
    --Sn added by Pankaj S. for 10871
    v_acct_type   cms_acct_mast.cam_type_code%TYPE;
    v_timestamp   timestamp(3);
    --En added by Pankaj S. for 10871
    
    V_HASH_CALL_PAN              CMS_APPL_PAN.CAP_PAN_CODE%type;--Added by Dnyaneshwar J on 30 Sept 2013
    v_repeat_check varchar2(1); --Added for FSS 1731
    v_completion_fee      cms_preauth_transaction.cpt_completion_fee%TYPE;--Added by Pankaj S. for FSS 837
	v_prfl_code           cms_appl_pan.cap_prfl_code%TYPE;
    v_prfl_flag           cms_transaction_mast.ctm_prfl_flag%TYPE;
    
    v_org_txn_code             cms_preauth_transaction.cpt_txn_code%TYPE;
    v_org_mcc_code             cms_preauth_transaction.cpt_mcc_code%TYPE;
    v_org_internation_ind_resp cms_preauth_transaction.cpt_internation_ind_response%TYPE;
    v_org_pos_verification     cms_preauth_transaction.cpt_pos_verification%TYPE;
    v_org_date                 cms_preauth_transaction.cpt_ins_date%TYPE;
    v_org_payment_type         cms_preauth_transaction.cpt_payment_type%TYPE;
    v_org_delivery_channel     cms_preauth_transaction.cpt_delivery_channel%TYPE;
    v_org_prfl_flag            cms_transaction_mast.ctm_prfl_flag%TYPE;
    v_org_tran_type            cms_transaction_mast.ctm_tran_type%TYPE; 
	
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
    v_Retdate  date; --Added for VMS-5739/FSP-991


BEGIN
   -- << MAIN BEGIN>>
   prm_resp_cde := '00';
   prm_resp_msg := 'OK';
   v_errmsg := 'OK';
   SAVEPOINT v_savepoint;

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (prm_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
               'Error while converting pan '
            || prm_card_no
            || ' '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --EN CREATE HASH PAN
   
    --SN CREATE HASH PAN added by Dnyaneshwar J on 30 Sept 2013
   BEGIN
      v_hash_call_pan := gethash (prm_call_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :='Error while converting pan '|| prm_card_no|| ' '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --EN CREATE HASH PAN added by Dnyaneshwar J on 30 Sept 2013


   --Sn find the type of orginal txn (credit or debit)
   BEGIN
      SELECT ctm_credit_debit_flag, ctm_tran_desc, ctm_prfl_flag
        INTO v_dr_cr_flag, v_tran_desc, v_prfl_flag
        FROM cms_transaction_mast
       WHERE ctm_tran_code = prm_txn_code
         AND ctm_delivery_channel = prm_delv_chnl
         AND ctm_inst_code = prm_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         v_errmsg :=
               'Transaction detail is not found in master for orginal txn code'
            || prm_txn_code
            || 'delivery channel '
            || prm_delv_chnl;
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
               'Problem while selecting debit/credit flag '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --En find the type of orginal txn (credit or debit)

   /*  call log info   start       */

   -- SN : ADDED BY Ganesh on 18-JUL-12
   BEGIN
      SELECT cap_acct_no
        INTO v_spnd_acctno
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan
         AND cap_inst_code = prm_inst_code
         AND cap_mbr_numb = prm_mbr_numb;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         v_errmsg :=
              'Spending Account Number Not Found For the Card in PAN Master ';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
               'Error While Selecting Spending account Number for Card '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_rvsl_reject_record;
   END;

-- EN : ADDED BY Ganesh on 18-JUL-12

   -- inserted user not present
   BEGIN
      BEGIN
         SELECT NVL (MAX (ccd_call_seq), 0) + 1
           INTO v_call_seq
           FROM cms_calllog_details
          WHERE ccd_inst_code = prm_inst_code
            AND ccd_call_id = prm_call_id
            AND ccd_pan_code = v_hash_call_pan;--Modified by Dnyaneshwar J on 30 Sept 2013
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_errmsg := 'record is not present in cms_calllog_details  ';
            RAISE exp_rvsl_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while selecting frmo cms_calllog_details '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_rvsl_reject_record;
      END;

      INSERT INTO cms_calllog_details
                  (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                   ccd_rrn, ccd_devl_chnl, ccd_txn_code, ccd_tran_date,
                   ccd_tran_time, ccd_tbl_names, ccd_colm_name,
                   ccd_old_value, ccd_new_value, ccd_comments, ccd_ins_user,
                   ccd_ins_date, ccd_lupd_user, ccd_lupd_date,
                   ccd_acct_no   -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                  )
           VALUES (prm_inst_code, prm_call_id, v_hash_call_pan, v_call_seq,--Modified by Dnyaneshwar J on 30 Sept 2013
                   prm_rrn, prm_delv_chnl, prm_txn_code, prm_business_date,
                   prm_business_time, NULL, NULL,
                   NULL, NULL, prm_remark, prm_ins_user,
                   SYSDATE, prm_ins_user, SYSDATE,
                   v_spnd_acctno
                               -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
                  );
   EXCEPTION
      WHEN exp_rvsl_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
                ' Error while inserting into cms_calllog_details ' || SQLERRM;
         RAISE exp_rvsl_reject_record;
   END;

   /*  call log info   END */

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (prm_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while converting pan '
            || prm_card_no
            || ' '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --EN create encr pan

   --Sn generate auth id
   BEGIN
      SELECT --TO_CHAR (SYSDATE, 'YYYYMMDD') --commented by sagar on 25-jul-2012 to keep 6 digit auth id
             --||
             LPAD (seq_auth_id.NEXTVAL, 6, '0')
        INTO v_auth_id
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
         v_resp_cde := '21';                               -- Server Declined
         RAISE exp_rvsl_reject_record;
   END;

   --En generate auth id

   --Sn Txn date conversion
   BEGIN
      v_orgnl_trandate :=
         TO_DATE (   SUBSTR (TRIM (prm_orgnl_business_date), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (prm_orgnl_business_time), 1, 8),
                  'yyyymmdd hh24:mi:ss'
                 );
      v_rvsl_trandate :=
         TO_DATE (   SUBSTR (TRIM (prm_business_date), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (prm_business_time), 1, 8),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '32';
         v_errmsg :=
               'Problem while converting transaction Time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --En Txn date conversion

   --Sn get the product code
   BEGIN
      SELECT cap_prod_code, cap_card_type, cap_proxy_number, cap_acct_no,
             cap_expry_date, cap_card_stat, cap_prfl_code
        INTO v_prod_code, v_card_type, v_proxunumber, v_acct_number,
             v_expry_date, v_card_stat, v_prfl_code
        FROM cms_appl_pan
       WHERE cap_inst_code = prm_inst_code
         AND cap_pan_code = v_hash_pan
         AND cap_mbr_numb = prm_mbr_numb;           -- mbrnumb added on 310112
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         v_errmsg := prm_card_no || ' Card no not in master';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
             'Error while retriving card detail ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --***********SN:GPR changes added on 28-FEB-2012*****************
   BEGIN
      sp_status_check_gpr (prm_inst_code,
                           prm_card_no,
                           prm_delv_chnl,
                           v_expry_date,
                           v_card_stat,
                           prm_txn_code,
                           prm_txn_mode,
                           v_prod_code,
                           v_card_type,
                           prm_msg_typ,
                           prm_business_date,
                           prm_business_time,
                           NULL,
                           NULL,
                           NULL,   --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                           v_resp_cde,
                           v_errmsg
                          );

      IF (   (v_resp_cde <> '1' AND v_errmsg <> 'OK')
          OR (v_resp_cde <> '0' AND v_errmsg <> 'OK')
         )
      THEN
         RAISE exp_rvsl_reject_record;
      ELSE
         v_status_chk := v_resp_cde;
         v_resp_cde := '1';
      END IF;
   EXCEPTION
      WHEN exp_rvsl_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
              'Error from GPR Card Status Check ' || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_rvsl_reject_record;
   END;

   --***********EN:GPR changes added on 28-FEB-2012 *******************
   IF v_status_chk = '1'
   THEN                 -- IF condition checked for GPR changes on 28-FEB-2012
      --Sn check card stat
      BEGIN
         SELECT COUNT (1)
           INTO v_check_statcnt
           FROM pcms_valid_cardstat
          WHERE pvc_inst_code = prm_inst_code
            AND pvc_card_stat = v_card_stat
            AND pvc_tran_code = prm_txn_code
            AND pvc_delivery_channel = prm_delv_chnl;

         IF v_check_statcnt = 0
         THEN
            v_resp_cde := '10'; -- response id changed from 49 to 10 on 05Oct2012
            v_errmsg := ' Invalid Card Status';
            RAISE exp_rvsl_reject_record;
         END IF;

      EXCEPTION WHEN exp_rvsl_reject_record -- added by sagar on 01-OCT-2012
      THEN
          RAISE;

      WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Problem while selecting card stat '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_rvsl_reject_record;
      END;
   --En check card stat
   END IF;

   IF prm_reason_code IS NOT NULL
   THEN
      BEGIN
         SELECT csr_reasondesc
           INTO v_csr_reason_desc
           FROM cms_spprt_reasons
          WHERE csr_inst_code = prm_inst_code
            AND csr_spprt_rsncode = prm_reason_code;

         v_reason := v_csr_reason_desc || ' ' || TRIM (prm_reason_desc);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF TRIM (prm_reason_desc) IS NOT NULL
            THEN
               v_reason := TRIM (prm_reason_desc);
            END IF;
         WHEN OTHERS
         THEN
            IF TRIM (prm_reason_desc) IS NOT NULL
            THEN
               v_reason := TRIM (prm_reason_desc);
            END IF;
      END;
   ELSE
      v_reason := TRIM (prm_reason_desc);
   END IF;

   --Sn Duplicate RRN Check
--    terminal id commented on 31012012
   BEGIN
   
       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(prm_business_date), 1, 8), 'yyyymmdd');
	
    IF (v_Retdate>v_Retperiod) THEN	                                                --Added for VMS-5739/FSP-991
	
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE instcode = prm_inst_code
         AND customer_card_no = v_hash_pan
         AND rrn = prm_rrn
         AND delivery_channel = prm_delv_chnl
         AND txn_code = prm_txn_code
         AND business_date = prm_business_date
         AND business_time = prm_business_time;
		 
	ELSE
	
	    SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                 --Added for VMS-5739/FSP-991
       WHERE instcode = prm_inst_code
         AND customer_card_no = v_hash_pan
         AND rrn = prm_rrn
         AND delivery_channel = prm_delv_chnl
         AND txn_code = prm_txn_code
         AND business_date = prm_business_date
         AND business_time = prm_business_time;
	
	END IF;

      IF v_rrn_count > 0
      THEN
         v_resp_cde := '22';
         v_errmsg := 'Duplicate RRN found ' || prm_rrn;
         RAISE exp_rvsl_reject_record;
      END IF;
   END;

   --En Duplicate RRN Check

   --Select the Delivery Channel code of MM-POS
   BEGIN
      SELECT cdm_channel_code
        INTO v_delchannel_code
        FROM cms_delchannel_mast
       WHERE cdm_channel_desc = 'MMPOS' AND cdm_inst_code = prm_inst_code;

      --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr
      IF prm_curr_code IS NULL AND v_delchannel_code = prm_delv_chnl
      THEN
         BEGIN
--            SELECT cip_param_value
--              INTO v_base_curr
--              FROM cms_inst_param
--             WHERE cip_inst_code = prm_inst_code
--                   AND cip_param_key = 'CURRENCY';


             SELECT TRIM (cbp_param_value) 
	      INTO v_base_curr
	      FROM cms_bin_param 
             WHERE cbp_param_name = 'Currency' AND cbp_inst_code= prm_inst_code
             AND cbp_profile_code = (select  cpc_profile_code from 
             cms_prod_cattype where cpc_prod_code = v_prod_code and
	         cpc_card_type = v_card_type and cpc_inst_code=prm_inst_code);

            IF v_base_curr IS NULL
            THEN
               v_errmsg := 'Base currency cannot be null ';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                          'Base currency is not defined for the BIN PROFILE ';
               RAISE exp_rvsl_reject_record;
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting base currency for bin  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         v_currcode := v_base_curr;
      ELSE
         v_currcode := prm_curr_code;
      END IF;
   END;

   /*Sn check msg type  --commented by abhay for issue -0011216
   IF v_delchannel_code <> prm_delv_chnl
   THEN
      IF    (prm_msg_typ NOT IN ('0400', '0410', '0420', '0430'))
         OR (prm_rvsl_code = '00')
      THEN
         v_resp_cde := '12';
         v_errmsg := 'Not a valid reversal request';
         RAISE exp_rvsl_reject_record;
      END IF;
   END IF;

   En check msg type*/

   --Sn check orginal transaction    (-- Amount is missing in reversal request)
   BEGIN
   
       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
   
      v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_business_date), 1, 8), 'yyyymmdd');
	
    IF (v_Retdate>v_Retperiod) THEN	                                                --Added for VMS-5739/FSP-991
	
      SELECT delivery_channel, terminal_id,
             response_code, txn_code, txn_type,
             txn_mode, business_date, business_time,
             customer_card_no, amount,                    --Transaction amount
             feecode, feeattachtype,        -- card level / prod cattype level
             tranfee_amt,                           --Tranfee  Total    amount
                         servicetax_amt,              --Tran servicetax amount
             cess_amt,                                      --Tran cess amount
                      cr_dr_flag, terminal_id,
             mccode, feecode, tranfee_amt,
             servicetax_amt, cess_amt,
             tranfee_cr_acctno, tranfee_dr_acctno,
             tran_st_calc_flag, tran_cess_calc_flag,
             tran_st_cr_acctno, tran_st_dr_acctno,
             tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
             tran_reverse_flag, gl_upd_flag,fee_reversal_flag,
            --SN: Added on 03-Apr-2013 for defect 0010690
             merchant_zip,
             merchant_id,
             merchant_name,
             merchant_state,
             merchant_city
             --EN: Added on 03-Apr-2013 for defect 0010690
        INTO v_orgnl_delivery_channel, v_orgnl_terminal_id,
             v_orgnl_resp_code, v_orgnl_txn_code, v_orgnl_txn_type,
             v_orgnl_txn_mode, v_orgnl_business_date, v_orgnl_business_time,
             v_orgnl_customer_card_no, v_orgnl_total_amount,
             v_orgnl_txn_feecode, v_orgnl_txn_feeattachtype,
             v_orgnl_txn_totalfee_amt, v_orgnl_txn_servicetax_amt,
             v_orgnl_txn_cess_amt, v_orgnl_transaction_type, v_orgnl_termid,
             v_orgnl_mcccode, v_actual_feecode, v_orgnl_tranfee_amt,
             v_orgnl_servicetax_amt, v_orgnl_cess_amt,
             v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,
             v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag,
             v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno,
             v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno, v_curr_code,
             v_tran_reverse_flag, v_gl_upd_flag,v_fee_reversal_flag,
            --SN: Added on 03-Apr-2013 for defect 0010690
             v_merchant_zip,
             v_merchant_id,
             v_merchant_name,
             v_merchant_state,
             v_merchant_city
             --EN: Added on 03-Apr-2013 for defect 0010690
        FROM transactionlog
       WHERE rrn = prm_orgnl_rrn
         AND business_date    = prm_orgnl_business_date
         AND business_time    = prm_orgnl_business_time -- uncommented on 14-Sep-2012 by Sagar
         AND txn_code         = prm_orgnl_txn_code      -- added on 14-Sep-2012 by Sagar
         AND delivery_channel = prm_orgnl_delivery_chnl -- added on 14-Sep-2012 by Sagar
         AND customer_card_no = v_hash_pan
         AND response_code    = '00'                    -- added on 14-Sep-2012 by Sagar
         and INSTCODE = PRM_INST_CODE
         and REVERSAL_CODE=0     ---added for FSS 1731
         and msgtype in ('1100','0100'); ---added for FSS 1731

      -- AND terminal_id = prm_orgnl_terminal_id;

      --AND      MCCODE            = prm_merc_id;

    ELSE
	   
	         SELECT delivery_channel, terminal_id,
             response_code, txn_code, txn_type,
             txn_mode, business_date, business_time,
             customer_card_no, amount,                    --Transaction amount
             feecode, feeattachtype,        -- card level / prod cattype level
             tranfee_amt,                           --Tranfee  Total    amount
                         servicetax_amt,              --Tran servicetax amount
             cess_amt,                                      --Tran cess amount
                      cr_dr_flag, terminal_id,
             mccode, feecode, tranfee_amt,
             servicetax_amt, cess_amt,
             tranfee_cr_acctno, tranfee_dr_acctno,
             tran_st_calc_flag, tran_cess_calc_flag,
             tran_st_cr_acctno, tran_st_dr_acctno,
             tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
             tran_reverse_flag, gl_upd_flag,fee_reversal_flag,
            --SN: Added on 03-Apr-2013 for defect 0010690
             merchant_zip,
             merchant_id,
             merchant_name,
             merchant_state,
             merchant_city
             --EN: Added on 03-Apr-2013 for defect 0010690
        INTO v_orgnl_delivery_channel, v_orgnl_terminal_id,
             v_orgnl_resp_code, v_orgnl_txn_code, v_orgnl_txn_type,
             v_orgnl_txn_mode, v_orgnl_business_date, v_orgnl_business_time,
             v_orgnl_customer_card_no, v_orgnl_total_amount,
             v_orgnl_txn_feecode, v_orgnl_txn_feeattachtype,
             v_orgnl_txn_totalfee_amt, v_orgnl_txn_servicetax_amt,
             v_orgnl_txn_cess_amt, v_orgnl_transaction_type, v_orgnl_termid,
             v_orgnl_mcccode, v_actual_feecode, v_orgnl_tranfee_amt,
             v_orgnl_servicetax_amt, v_orgnl_cess_amt,
             v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,
             v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag,
             v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno,
             v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno, v_curr_code,
             v_tran_reverse_flag, v_gl_upd_flag,v_fee_reversal_flag,
            --SN: Added on 03-Apr-2013 for defect 0010690
             v_merchant_zip,
             v_merchant_id,
             v_merchant_name,
             v_merchant_state,
             v_merchant_city
             --EN: Added on 03-Apr-2013 for defect 0010690
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                        --Added for VMS-5739/FSP-991
       WHERE rrn = prm_orgnl_rrn
         AND business_date    = prm_orgnl_business_date
         AND business_time    = prm_orgnl_business_time -- uncommented on 14-Sep-2012 by Sagar
         AND txn_code         = prm_orgnl_txn_code      -- added on 14-Sep-2012 by Sagar
         AND delivery_channel = prm_orgnl_delivery_chnl -- added on 14-Sep-2012 by Sagar
         AND customer_card_no = v_hash_pan
         AND response_code    = '00'                    -- added on 14-Sep-2012 by Sagar
         and INSTCODE = PRM_INST_CODE
         and REVERSAL_CODE=0     ---added for FSS 1731
         and msgtype in ('1100','0100'); ---added for FSS 1731

      -- AND terminal_id = prm_orgnl_terminal_id;

      --AND      MCCODE            = prm_merc_id;	
	
	END IF;


      IF v_orgnl_resp_code <> '00'
      THEN
         v_resp_cde := '23';
         v_errmsg := ' The original transaction was not successful';
         RAISE exp_rvsl_reject_record;
      END IF;

     --SN: Commented on 17-Apr-2013 for defect 0010798

    /*  IF v_tran_reverse_flag = 'Y'
      THEN
         v_resp_cde := '52';
         v_errmsg := 'The reversal already done for the orginal transaction';
         RAISE exp_rvsl_reject_record;
      end if;
    */

    --EN: Commented on 17-Apr-2013 for defect 0010798


   EXCEPTION
      WHEN exp_rvsl_reject_record
      THEN
         RAISE;
         
      WHEN NO_DATA_FOUND
      then
      v_repeat_check:='Y'; --Modified  for FSS 1731
        /* v_resp_cde := '53';
         v_errmsg := 'Matching transaction not found';
         RAISE exp_rvsl_reject_record;*/
      WHEN TOO_MANY_ROWS
      THEN
         v_resp_cde := '21';
         v_errmsg := 'More than one matching record found in the master';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
              'Error while selecting master data' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --En check orginal transaction
   
    --SN Added for FSS 1731
   begin
     if v_repeat_check ='Y' then
	        
			--Added for VMS-5739/FSP-991
	        v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_business_date), 1, 8), 'yyyymmdd');
	
         IF (v_Retdate>v_Retperiod) THEN	                                                --Added for VMS-5739/FSP-991
	 
             SELECT delivery_channel, terminal_id,
             response_code, txn_code, txn_type,
             txn_mode, business_date, business_time,
             customer_card_no, amount,                    --Transaction amount
             feecode, feeattachtype,        -- card level / prod cattype level
             tranfee_amt,                           --Tranfee  Total    amount
                         servicetax_amt,              --Tran servicetax amount
             cess_amt,                                      --Tran cess amount
                      cr_dr_flag, terminal_id,
             mccode, feecode, tranfee_amt,
             servicetax_amt, cess_amt,
             tranfee_cr_acctno, tranfee_dr_acctno,
             tran_st_calc_flag, tran_cess_calc_flag,
             tran_st_cr_acctno, tran_st_dr_acctno,
             tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
             tran_reverse_flag, gl_upd_flag,fee_reversal_flag,
             merchant_zip,
             merchant_id,
             merchant_name,
             merchant_state,
             merchant_city
        INTO v_orgnl_delivery_channel, v_orgnl_terminal_id,
             v_orgnl_resp_code, v_orgnl_txn_code, v_orgnl_txn_type,
             v_orgnl_txn_mode, v_orgnl_business_date, v_orgnl_business_time,
             v_orgnl_customer_card_no, v_orgnl_total_amount,
             v_orgnl_txn_feecode, v_orgnl_txn_feeattachtype,
             v_orgnl_txn_totalfee_amt, v_orgnl_txn_servicetax_amt,
             v_orgnl_txn_cess_amt, v_orgnl_transaction_type, v_orgnl_termid,
             v_orgnl_mcccode, v_actual_feecode, v_orgnl_tranfee_amt,
             v_orgnl_servicetax_amt, v_orgnl_cess_amt,
             v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,
             v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag,
             v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno,
             v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno, v_curr_code,
             v_tran_reverse_flag, v_gl_upd_flag,v_fee_reversal_flag,
             v_merchant_zip,
             v_merchant_id,
             v_merchant_name,
             v_merchant_state,
             v_merchant_city
        FROM transactionlog
       WHERE rrn = prm_orgnl_rrn
         AND business_date    = prm_orgnl_business_date
         AND business_time    = prm_orgnl_business_time 
         AND txn_code         = prm_orgnl_txn_code      
         AND delivery_channel = prm_orgnl_delivery_chnl 
         AND customer_card_no = v_hash_pan
         AND response_code    = '00'                    
         and INSTCODE = PRM_INST_CODE
         and REVERSAL_CODE=0
         and MSGTYPE='1101';
		 
	ELSE
	   
	        SELECT delivery_channel, terminal_id,
             response_code, txn_code, txn_type,
             txn_mode, business_date, business_time,
             customer_card_no, amount,                    --Transaction amount
             feecode, feeattachtype,        -- card level / prod cattype level
             tranfee_amt,                           --Tranfee  Total    amount
                         servicetax_amt,              --Tran servicetax amount
             cess_amt,                                      --Tran cess amount
                      cr_dr_flag, terminal_id,
             mccode, feecode, tranfee_amt,
             servicetax_amt, cess_amt,
             tranfee_cr_acctno, tranfee_dr_acctno,
             tran_st_calc_flag, tran_cess_calc_flag,
             tran_st_cr_acctno, tran_st_dr_acctno,
             tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,
             tran_reverse_flag, gl_upd_flag,fee_reversal_flag,
             merchant_zip,
             merchant_id,
             merchant_name,
             merchant_state,
             merchant_city
        INTO v_orgnl_delivery_channel, v_orgnl_terminal_id,
             v_orgnl_resp_code, v_orgnl_txn_code, v_orgnl_txn_type,
             v_orgnl_txn_mode, v_orgnl_business_date, v_orgnl_business_time,
             v_orgnl_customer_card_no, v_orgnl_total_amount,
             v_orgnl_txn_feecode, v_orgnl_txn_feeattachtype,
             v_orgnl_txn_totalfee_amt, v_orgnl_txn_servicetax_amt,
             v_orgnl_txn_cess_amt, v_orgnl_transaction_type, v_orgnl_termid,
             v_orgnl_mcccode, v_actual_feecode, v_orgnl_tranfee_amt,
             v_orgnl_servicetax_amt, v_orgnl_cess_amt,
             v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,
             v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag,
             v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno,
             v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno, v_curr_code,
             v_tran_reverse_flag, v_gl_upd_flag,v_fee_reversal_flag,
             v_merchant_zip,
             v_merchant_id,
             v_merchant_name,
             v_merchant_state,
             v_merchant_city
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                            --Added for VMS-5739/FSP-991
       WHERE rrn = prm_orgnl_rrn
         AND business_date    = prm_orgnl_business_date
         AND business_time    = prm_orgnl_business_time 
         AND txn_code         = prm_orgnl_txn_code      
         AND delivery_channel = prm_orgnl_delivery_chnl 
         AND customer_card_no = v_hash_pan
         AND response_code    = '00'                    
         and INSTCODE = PRM_INST_CODE
         and REVERSAL_CODE=0
         and MSGTYPE='1101';
	
	
	END IF;
         
      IF v_orgnl_resp_code <> '00'
      THEN
         v_resp_cde := '23';
         V_ERRMSG := ' The original transaction was not successful';
         RAISE exp_rvsl_reject_record;
      end if;
    end if;
   EXCEPTION
      WHEN exp_rvsl_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      then
         v_resp_cde := '53';
         v_errmsg := 'Matching transaction not found';
         RAISE exp_rvsl_reject_record;
      WHEN TOO_MANY_ROWS
      THEN
         v_resp_cde := '21';
         v_errmsg := 'More than one matching record found in the master';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
              'Error while selecting master data' || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_RVSL_REJECT_RECORD;
   END;
   
   --EN Added for FSS 1731
   ---Sn check card number
/* 31012012 need to check  this  */
   IF v_orgnl_customer_card_no <> v_hash_pan
   THEN
      v_resp_cde := '21';
      v_errmsg :=
         'Customer card number is not matching in reversal and orginal transaction';
      RAISE exp_rvsl_reject_record;
   END IF;

   --En check card number

   --Sn find the converted tran amt
   v_tran_amt := prm_actual_amt;

   IF (prm_actual_amt >= 0)
   THEN
      BEGIN
         sp_convert_curr (prm_inst_code,
                          v_currcode,
                          prm_card_no,
                          prm_actual_amt,
                          v_rvsl_trandate,
                          v_tran_amt,
                          v_card_curr,
                          v_errmsg,
                          v_prod_code,
                          v_card_type
                         );

         IF v_errmsg <> 'OK'
         THEN
            v_resp_cde := '44';
            RAISE exp_rvsl_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_rvsl_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '44';                    -- Server Declined -220509
            v_errmsg :=
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      END;
   ELSE
      -- If transaction Amount is zero - Invalid Amount -220509
      v_resp_cde := '13';
      v_errmsg := 'INVALID AMOUNT';
      RAISE exp_rvsl_reject_record;
   END IF;

   --En find the  converted tran amt

   --Sn check amount with orginal transaction
   IF (v_tran_amt IS NULL OR v_tran_amt = 0)
   THEN
      -- V_REVERSAL_AMT := 0;
      v_actual_dispatched_amt := 0;
   ELSE
      --V_REVERSAL_AMT := V_TRAN_AMT; --For Preauth reversal,txn amount will the amount to be credited to the customer
      v_actual_dispatched_amt := v_tran_amt;
   END IF;

   --En check amount with orginal transaction

   --Sn Check PreAuth Completion txn
   BEGIN
   
      	 --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_PREAUTH_TRANSACTION_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_business_date), 1, 8), 'yyyymmdd');
	   
	IF (v_Retdate>v_Retperiod) THEN                                                 --Added for VMS-5739/FSP-991
	   
      SELECT cpt_totalhold_amt, cpt_expiry_flag,
             cpt_completion_fee, --Added by Pankaj S. for FSS-837
             cpt_txn_code,
             cpt_mcc_code,
             cpt_internation_ind_response,
             cpt_pos_verification,
             cpt_ins_date,
             cpt_payment_type,
             cpt_delivery_channel
        INTO v_hold_amount, v_preauth_expiry_flag,
             v_completion_fee,--Added by Pankaj S. for FSS-837
             v_org_txn_code,
             v_org_mcc_code,
             v_org_internation_ind_resp,
             v_org_pos_verification,
             v_org_date,
             v_org_payment_type,
             v_org_delivery_channel
        FROM cms_preauth_transaction
       WHERE cpt_rrn = prm_orgnl_rrn
         AND cpt_txn_date = prm_orgnl_business_date
         AND cpt_inst_code = prm_inst_code
         AND cpt_mbr_no = prm_mbr_numb
         -- need to add in preauth duplicate RRN check 310112
         AND cpt_card_no = v_hash_pan;
		 
    ELSE
	        
	  SELECT cpt_totalhold_amt, cpt_expiry_flag,
             cpt_completion_fee, --Added by Pankaj S. for FSS-837
             cpt_txn_code,
             cpt_mcc_code,
             cpt_internation_ind_response,
             cpt_pos_verification,
             cpt_ins_date,
             cpt_payment_type,
             cpt_delivery_channel
        INTO v_hold_amount, v_preauth_expiry_flag,
             v_completion_fee,--Added by Pankaj S. for FSS-837
             v_org_txn_code,
             v_org_mcc_code,
             v_org_internation_ind_resp,
             v_org_pos_verification,
             v_org_date,
             v_org_payment_type,
             v_org_delivery_channel
        FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                           --Added for VMS-5739/FSP-991
       WHERE cpt_rrn = prm_orgnl_rrn
         AND cpt_txn_date = prm_orgnl_business_date
         AND cpt_inst_code = prm_inst_code
         AND cpt_mbr_no = prm_mbr_numb
         -- need to add in preauth duplicate RRN check 310112
         AND cpt_card_no = v_hash_pan;
	
	
	END IF;
	
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '53';
         v_errmsg := 'Matching transaction not found';
         RAISE exp_rvsl_reject_record;
      WHEN TOO_MANY_ROWS
      THEN
         v_resp_cde := '21';                         --Ineligible Transaction
         v_errmsg := 'More than one record found ';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';                         --Ineligible Transaction
         v_errmsg := 'Error while selecting the PreAuth details';
         RAISE exp_rvsl_reject_record;
   END;

   --En Check PreAuth Completion txn
   BEGIN
      IF v_hold_amount <= 0
      THEN
         v_resp_cde := '58';
         v_errmsg := 'There is no hold amount for reversal';
         RAISE exp_rvsl_reject_record;
      ELSE
         IF (v_hold_amount < v_actual_dispatched_amt)
         THEN
            v_resp_cde := '59';
            v_errmsg :=
                    'Reversal amount exceeds the original transaction amount';
            RAISE exp_rvsl_reject_record;
         END IF;
      END IF;

      v_reversal_amt := v_actual_dispatched_amt;
   END;



   --Sn Check the Flag for Reversal transaction
   IF prm_txn_code != '11'
   THEN
      IF v_dr_cr_flag = 'NA'
      THEN
         v_resp_cde := '21';
         v_errmsg := 'Not a valid orginal transaction for reversal';
         RAISE exp_rvsl_reject_record;
      END IF;
   END IF;

   --En Check the Flag for Reversal transaction

   --Sn Check the transaction type with Original txn type
     /*
     commented on 30012012 bcz pre auth transaction type  is NA

     IF v_dr_cr_flag <> v_orgnl_transaction_type
      THEN
         v_resp_cde := '21';
         v_errmsg :=
            'Orginal transaction type is not matching with actual transaction type';
         RAISE exp_rvsl_reject_record;
      END IF;
   */
      --En Check the transaction type
      
  --SN - commented for fwr-48

   --Sn find the orginal func code
  /* BEGIN
      SELECT cfm_func_code
        INTO v_func_code
        FROM cms_func_mast
       WHERE cfm_txn_code = v_orgnl_txn_code
         AND cfm_txn_mode = v_orgnl_txn_mode
         AND cfm_delivery_channel = v_orgnl_delivery_channel
         AND cfm_inst_code = prm_inst_code;
   --TXN mode and delivery channel we need to attach
   --bkz txn code may be same for all type of channels
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '69';                         --Ineligible Transaction
         v_errmsg :=
                    'Function code not defined for txn code ' || prm_txn_code;
         RAISE exp_rvsl_reject_record;
      WHEN TOO_MANY_ROWS
      THEN
         v_resp_cde := '69';
         v_errmsg :=
               'More than one function defined for txn code ' || prm_txn_code;
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '69';
         v_errmsg :=
               'Problem while selecting function code from function mast  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;*/

   --En find the orginal func code
   
   --EN - commented for fwr-48

   ---Sn find cutoff time
   BEGIN
      SELECT cip_param_value
        INTO v_cutoff_time
        FROM cms_inst_param
       WHERE cip_param_key = 'CUTOFF' AND cip_inst_code = prm_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_cutoff_time := 0;
         v_resp_cde := '21';
         v_errmsg := 'Cutoff time is not defined in the system';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg := 'Error while selecting cutoff  dtl  from system ';
         RAISE exp_rvsl_reject_record;
   END;

   ---En find cutoff time
   BEGIN
      SELECT     cam_acct_no, cam_acct_bal, cam_ledger_bal
                 ,cam_type_code --added by Pankaj S. for 10871
            INTO v_card_acct_no, v_acct_balance, v_ledger_bal
                 ,v_acct_type --added by Pankaj S. for 10871
            FROM cms_acct_mast
           WHERE cam_acct_no = 
                    (SELECT cap_acct_no
                       FROM cms_appl_pan
                      WHERE cap_pan_code = v_hash_pan            --prm_card_no
                        AND cap_mbr_numb = prm_mbr_numb
                        AND cap_inst_code = prm_inst_code)
             AND cam_inst_code = prm_inst_code
      FOR UPDATE NOWAIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '14';                         --Ineligible Transaction
         v_errmsg := 'Invalid Card ';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '12';
         v_errmsg :=
               'Error while selecting data from card Master for card number '
            || prm_card_no;
         RAISE exp_rvsl_reject_record;
   END;

   IF v_orgnl_txn_totalfee_amt > 0
   THEN
      BEGIN
	  
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(v_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
	  
         SELECT csl_trans_narrration
           INTO v_fee_narration
           FROM VMSCMS.CMS_STATEMENTS_LOG                     --Added for VMS-5739/FSP-991
          WHERE csl_business_date = v_orgnl_business_date
            AND csl_business_time = v_orgnl_business_time
            AND csl_rrn = prm_orgnl_rrn
            AND csl_delivery_channel = v_orgnl_delivery_channel
            AND csl_txn_code = v_orgnl_txn_code
            AND csl_pan_no = v_orgnl_customer_card_no
            AND csl_inst_code = prm_inst_code
            AND txn_fee_flag = 'Y';
ELSE
		SELECT csl_trans_narrration
           INTO v_fee_narration
           FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST                     --Added for VMS-5739/FSP-991
          WHERE csl_business_date = v_orgnl_business_date
            AND csl_business_time = v_orgnl_business_time
            AND csl_rrn = prm_orgnl_rrn
            AND csl_delivery_channel = v_orgnl_delivery_channel
            AND csl_txn_code = v_orgnl_txn_code
            AND csl_pan_no = v_orgnl_customer_card_no
            AND csl_inst_code = prm_inst_code
            AND txn_fee_flag = 'Y';

END IF;			
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_fee_narration := NULL;

      WHEN TOO_MANY_ROWS
      THEN

       v_fee_narration :=' hold release for rrn '
                         || prm_orgnl_rrn
                         || ' date: '
                         || TO_DATE (v_orgnl_business_date || ' ' || v_orgnl_business_time,
                                     'yyyymmdd hh24miss'
                                    );

         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                      'Error fetching narration ' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_rvsl_reject_record;
      END;
   END IF;
  --En find narration

   v_timestamp:=systimestamp; --added by Pankaj S. for 10871

   BEGIN
      sp_reverse_card_amount (prm_inst_code,
                              v_func_code,
                              prm_rrn,
                              prm_delv_chnl,
                              prm_orgnl_terminal_id,
                              prm_merc_id,
                              prm_txn_code,
                              v_rvsl_trandate,
                              prm_txn_mode,
                              prm_card_no,
                              v_reversal_amt+NVL(v_completion_fee,0),  --Modified by Pankaj S. for Fss-837
                              prm_orgnl_rrn,
                              v_card_acct_no,
                              prm_business_date,
                              prm_business_time,
                              v_auth_id,
                              v_txn_narration,
                              prm_orgnl_business_date,
                              prm_orgnl_business_time,
                              prm_merchant_name,
                              prm_merchant_city,
                              prm_merc_state,
                              v_resp_cde,
                              v_errmsg
                             );

      IF v_resp_cde <> '00' OR v_errmsg <> 'OK'
      THEN
         RAISE exp_rvsl_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_rvsl_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
              'Error while reversing the amount ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --En reverse the amount

   --Sn reverse the fee

   IF v_fee_reversal_flag = 'N' -- added by sagar on 14Sep2012 to check fee reversal flag before reversing fee amount
   THEN


       BEGIN
          sp_reverse_fee_amount (prm_inst_code,
                                 prm_rrn,
                                 prm_delv_chnl,
                                 prm_orgnl_terminal_id,
                                 prm_merc_id,
                                 prm_txn_code,
                                 v_rvsl_trandate,
                                 prm_txn_mode,
                                 v_orgnl_txn_totalfee_amt,
                                 prm_card_no,
                                 v_actual_feecode,
                                 v_orgnl_tranfee_amt,
                                 v_orgnl_tranfee_cr_acctno,
                                 v_orgnl_tranfee_dr_acctno,
                                 v_orgnl_st_calc_flag,
                                 v_orgnl_servicetax_amt,
                                 v_orgnl_st_cr_acctno,
                                 v_orgnl_st_dr_acctno,
                                 v_orgnl_cess_calc_flag,
                                 v_orgnl_cess_amt,
                                 v_orgnl_cess_cr_acctno,
                                 v_orgnl_cess_dr_acctno,
                                 prm_orgnl_rrn,
                                 v_card_acct_no,
                                 prm_business_date,
                                 prm_business_time,
                                 v_auth_id,
                                 v_fee_narration,
                                 prm_merchant_name,
                                 prm_merchant_city,
                                 prm_merc_state,
                                 v_resp_cde,
                                 v_errmsg
                                );

          IF v_resp_cde <> '00' OR v_errmsg <> 'OK'
          THEN
             RAISE exp_rvsl_reject_record;
          END IF;
       EXCEPTION
          WHEN exp_rvsl_reject_record
          THEN
             RAISE;
          WHEN OTHERS
          THEN
             v_resp_cde := '21';
             v_errmsg :=
                   'Error while reversing the fee amount '
                || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_rvsl_reject_record;
       END;

   elsif v_fee_reversal_flag = 'Y' and v_orgnl_tranfee_amt <> 0 -- added by sagar on 14Sep2012 to check fee reversal flag before reversing fee amount
   then
        v_orgnl_tranfee_amt := 0;

   END IF;

   --En reverse the fee
   IF v_gl_upd_flag = 'Y'
   THEN
      --Sn find business date
      --  v_business_date
      -- v_cutoff_time
      v_business_time := TO_CHAR (v_rvsl_trandate, 'HH24:MI');

      IF v_business_time > v_cutoff_time
      THEN
         v_rvsl_trandate := TRUNC (v_rvsl_trandate) + 1;
      ELSE
         v_rvsl_trandate := TRUNC (v_rvsl_trandate);
      END IF;

      --En find businesses date
      
      --SN - commented for fwr-48
    /*  sp_reverse_gl_entries (prm_inst_code,
                             v_rvsl_trandate,
                             v_prod_code,
                             v_card_type,
                             v_reversal_amt,
                             v_func_code,
                             prm_txn_code,
                             v_dr_cr_flag,
                             prm_card_no,
                             v_actual_feecode,
                             v_orgnl_txn_totalfee_amt,
                             v_orgnl_tranfee_cr_acctno,
                             v_orgnl_tranfee_dr_acctno,
                             v_card_acct_no,
                             prm_rvsl_code,
                             prm_msg_typ,
                             prm_delv_chnl,
                             v_resp_cde,
                             v_gl_upd_flag,
                             v_errmsg
                            );

      IF v_gl_upd_flag <> 'Y'
      THEN
         v_resp_cde := '21';
         v_errmsg :=
               v_errmsg
            || 'Error while retriving gl detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
      END IF;*/
      
      --EN - commented for fwr-48
      
   END IF;
   --En reverse the GL entries
    --Sn added by Pankaj S. for 10871
     BEGIN
	 
	   --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(prm_business_date), 1, 8), 'yyyymmdd');
	  
	 IF (v_Retdate>v_Retperiod) THEN                                           --Added for VMS-5739/FSP-991
	 
        UPDATE cms_statements_log
           SET csl_prod_code = v_prod_code,
               csl_card_type=v_card_type,
               csl_acct_type = v_acct_type,
               csl_time_stamp = v_timestamp
         WHERE csl_inst_code = prm_inst_code
           AND csl_pan_no = v_hash_pan
           AND csl_rrn = prm_rrn
           AND csl_txn_code = prm_txn_code
           AND csl_delivery_channel = prm_delv_chnl
           AND csl_business_date = prm_business_date
           AND csl_business_time = prm_business_time;
		   
	ELSE
	
	       UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST                   --Added for VMS-5739/FSP-991
           SET csl_prod_code = v_prod_code,
               csl_card_type=v_card_type,
               csl_acct_type = v_acct_type,
               csl_time_stamp = v_timestamp
         WHERE csl_inst_code = prm_inst_code
           AND csl_pan_no = v_hash_pan
           AND csl_rrn = prm_rrn
           AND csl_txn_code = prm_txn_code
           AND csl_delivery_channel = prm_delv_chnl
           AND csl_business_date = prm_business_date
           AND csl_business_time = prm_business_time;
	
	
	END IF;
       IF SQL%ROWCOUNT =0
       THEN
         NULL;
       END IF;
       EXCEPTION
       WHEN OTHERS
       THEN
          v_resp_cde := '21';
          v_errmsg :=
               'Error while updating timestamp in statementlog-' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
    END;
    --Sn added by Pankaj S. for 10871
   --Sn create a entry for successful
    BEGIN
        SELECT ctm_prfl_flag, CTM_TRAN_TYPE
           INTO v_org_prfl_flag, v_org_tran_type
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = v_org_txn_code AND
                CTM_DELIVERY_CHANNEL = v_org_delivery_channel AND
                CTM_INST_CODE = prm_inst_code;
       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             v_resp_cde := '21';
             v_errmsg :=
                   'Transaction detail is not found in master for orginal txn code'
                || prm_txn_code
                || 'delivery channel '
                || prm_delv_chnl;
             RAISE exp_rvsl_reject_record;
          WHEN OTHERS
          THEN
             v_resp_cde := '21';
             v_errmsg :=
                   'Problem while selecting debit/credit flag '
                || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_rvsl_reject_record;
   END;
   
   IF v_prfl_code IS NOT NULL AND v_org_prfl_flag = 'Y' THEN
      BEGIN
         PKG_LIMITS_CHECK.sp_limitcnt_rever_reset
                          (prm_inst_code,
                           null,
                           null,
                           prm_merc_id,    
                           v_org_txn_code,
                           v_org_tran_type,
                           v_org_internation_ind_resp,
                           v_org_pos_verification,
                           v_prfl_code,
                           v_hold_amount,
                           v_hold_amount,
                           v_org_delivery_channel,
                           v_hash_pan,
                           v_org_date,
                           v_resp_cde,
                           v_errmsg,
                           v_org_payment_type
                          );
         IF v_errmsg <> 'OK' THEN
            RAISE exp_rvsl_reject_record;
         END IF;
       EXCEPTION
          WHEN exp_rvsl_reject_record THEN
               RAISE;
          WHEN OTHERS    THEN
               v_resp_cde := '21';
               v_errmsg :='Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
      END;
   END IF;
   
   BEGIN
      IF v_errmsg = 'OK'
      THEN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_system_trace_audit_no,
                      ctd_inst_code, ctd_customer_card_no_encr,
                      ctd_cust_acct_number,
                      ctd_completion_fee,ctd_complfee_increment_type  --Added by Pankaj S. for FSS-837
                     )
              VALUES (prm_delv_chnl, prm_txn_code, prm_txn_type,
                      prm_msg_typ, prm_txn_mode, prm_business_date,
                      prm_business_time, v_hash_pan,
                      prm_actual_amt,--v_tran_amt, --prm_actual_amt modified for 10871 modified for defect id:12166
                      v_currcode, v_tran_amt,
                      v_reversal_amt, v_card_curr, 'Y',
                      'Successful', prm_rrn, prm_stan,
                      prm_inst_code, v_encr_pan,
                      v_acct_number,
                      v_completion_fee,'C'  --Added by Pankaj S. for FSS-837
                     );
      END IF;
   --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem while selecting data from response master '
            || SUBSTR (SQLERRM, 1, 300);
         v_resp_cde := '21';
         RAISE exp_rvsl_reject_record;
   END;

   --En create a entry for successful

   --Sn generate response code
   v_resp_cde := '1';

   BEGIN
      INSERT INTO cms_preauth_trans_hist
                  (cph_card_no, cph_mbr_no, cph_inst_code, cph_card_no_encr,
                   cph_preauth_validflag, cph_completion_flag, cph_txn_amnt,
                   cph_rrn, cph_txn_date, cph_txn_time,
                   cph_orgnl_rrn, cph_orgnl_txn_date,
                   cph_orgnl_txn_time, cph_orgnl_card_no, cph_terminalid,
                   cph_orgnl_terminalid, cph_transaction_flag
                  )
           VALUES (v_hash_pan, prm_mbr_numb, prm_inst_code, v_encr_pan,
                   'N', 'C', v_tran_amt, --prm_actual_amt modified for 10871
                   prm_rrn, prm_business_date, prm_business_time,
                   prm_orgnl_rrn, prm_orgnl_business_date,
                   prm_orgnl_business_time, v_hash_pan, prm_terminal_id,
                   prm_orgnl_terminal_id, 'R'
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
               'Problem while inserting into preauth hist '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_rvsl_reject_record;
   END;

   BEGIN
      IF v_preauth_expiry_flag = 'N'
      THEN
        IF v_orgnl_delivery_channel='13' THEN
		
		 	 --Added for VMS-5739/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='CMS_PREAUTH_TRANSACTION_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_business_date), 1, 8), 'yyyymmdd');
	   
	    IF (v_Retdate>v_Retperiod) THEN                                        --Added for VMS-5739/FSP-991
		
         UPDATE cms_preauth_transaction
            SET cpt_totalhold_amt = cpt_totalhold_amt - v_actual_dispatched_amt,
                cpt_transaction_rrn = prm_rrn,
                cpt_transaction_flag = 'R',
                CPT_PREAUTH_VALIDFLAG = 'N', 
                cpt_completion_fee=0 
                ,cpt_approve_amt=cpt_approve_amt-v_actual_dispatched_amt
          WHERE cpt_rrn = prm_orgnl_rrn
            AND cpt_txn_date = prm_orgnl_business_date
            AND cpt_txn_time = prm_orgnl_business_time
            AND cpt_mbr_no = prm_mbr_numb
            AND cpt_inst_code = prm_inst_code
            AND cpt_card_no = v_hash_pan;
			
		ELSE
		
		    UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                 --Added for VMS-5739/FSP-991
            SET cpt_totalhold_amt = cpt_totalhold_amt - v_actual_dispatched_amt,
                cpt_transaction_rrn = prm_rrn,
                cpt_transaction_flag = 'R',
                CPT_PREAUTH_VALIDFLAG = 'N', 
                cpt_completion_fee=0 
                ,cpt_approve_amt=cpt_approve_amt-v_actual_dispatched_amt
          WHERE cpt_rrn = prm_orgnl_rrn
            AND cpt_txn_date = prm_orgnl_business_date
            AND cpt_txn_time = prm_orgnl_business_time
            AND cpt_mbr_no = prm_mbr_numb
            AND cpt_inst_code = prm_inst_code
            AND cpt_card_no = v_hash_pan;
		
		END IF;
		
        ELSE
		
		 IF (v_Retdate>v_Retperiod) THEN                                        --Added for VMS-5739/FSP-991
		
          UPDATE cms_preauth_transaction
            SET cpt_totalhold_amt = cpt_totalhold_amt - v_actual_dispatched_amt,
                cpt_transaction_rrn = prm_rrn,
                -- updating the last completion RRN or reversal RRN in this column.
                cpt_transaction_flag = 'R',
                CPT_PREAUTH_VALIDFLAG = 'N', -- added on 11-Sep-2012 to flag reversal transactions
                cpt_completion_fee=0 --Added by Pankaj S. for FSS 837
                 ,cpt_approve_amt=cpt_approve_amt-v_actual_dispatched_amt
           WHERE cpt_rrn = prm_orgnl_rrn
            AND cpt_txn_date = prm_orgnl_business_date
            AND cpt_txn_time = prm_orgnl_business_time
            AND cpt_terminalid = prm_orgnl_terminal_id
            AND cpt_mbr_no = prm_mbr_numb
            AND cpt_inst_code = prm_inst_code
            AND cpt_card_no = v_hash_pan;
			
		 ELSE
		 
		    UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                     --Added for VMS-5739/FSP-991
            SET cpt_totalhold_amt = cpt_totalhold_amt - v_actual_dispatched_amt,
                cpt_transaction_rrn = prm_rrn,
                -- updating the last completion RRN or reversal RRN in this column.
                cpt_transaction_flag = 'R',
                CPT_PREAUTH_VALIDFLAG = 'N', -- added on 11-Sep-2012 to flag reversal transactions
                cpt_completion_fee=0 --Added by Pankaj S. for FSS 837
                 ,cpt_approve_amt=cpt_approve_amt-v_actual_dispatched_amt
          WHERE cpt_rrn = prm_orgnl_rrn
            AND cpt_txn_date = prm_orgnl_business_date
            AND cpt_txn_time = prm_orgnl_business_time
            AND cpt_terminalid = prm_orgnl_terminal_id
            AND cpt_mbr_no = prm_mbr_numb
            AND cpt_inst_code = prm_inst_code
            AND cpt_card_no = v_hash_pan;
				
		 END IF;
		
        END IF;
         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '53';
            --      V_ERRMSG   := 'Problem while updating preauth transaction ' ||
            --   SUBSTR(SQLERRM, 1, 200);
            v_errmsg := 'Invalid Reversal Request';
            RAISE exp_rvsl_reject_record;
         END IF;
      END IF;
   END;

   BEGIN
      SELECT cms_iso_respcde
        INTO prm_resp_cde
        FROM cms_response_mast
       WHERE cms_inst_code = prm_inst_code
         AND cms_delivery_channel = prm_delv_chnl
         AND cms_response_id = TO_NUMBER (v_resp_cde);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem while selecting data from response master for respose code'
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         v_resp_cde := '69';
         RAISE exp_rvsl_reject_record;
   END;

   --En generate response code
   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal
        INTO v_acct_balance, v_ledger_bal
        FROM cms_acct_mast
       WHERE cam_acct_no =v_acct_number    --Modified during FSS-837
                 /*(SELECT cap_acct_no
                   FROM cms_appl_pan
                  WHERE cap_inst_code = prm_inst_code
                    AND cap_pan_code = v_hash_pan
                    AND cap_mbr_numb = prm_mbr_numb)*/
         AND cam_inst_code = prm_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '14';                         --Ineligible Transaction
         v_errmsg := 'Invalid Card ';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         --v_acct_balance := 0;
         --v_ledger_bal := 0;
         v_resp_cde := '12';
         v_errmsg :=
               'Error while selecting balance from acct Master for card number '
            || prm_card_no
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_rvsl_reject_record;
   END;

   -- Sn create a entry in GL
   BEGIN
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, terminal_id,
                   date_time, txn_code, txn_type,
                   txn_mode, txn_status,
                   response_code, business_date,
                   business_time, customer_card_no, topup_card_no,
                   topup_acct_no, topup_acct_type, bank_code,
                   total_amount,
                   rule_indicator, rulegroupid, mccode, currencycode,
                   --  ADDCHARGE
                   --  ,
                   productid, categoryid, tranfee_amt, tips, decline_ruleid,
                   atm_name_location, auth_id, trans_desc,
                   amount,
                   preauthamount, partialamount, mccodegroupid,
                   currencycodegroupid, transcodegroupid, rules,
                   preauth_date, gl_upd_flag, system_trace_audit_no,
                   instcode, feecode, feeattachtype, tran_reverse_flag,
                   customer_card_no_encr, topup_card_no_encr, orgnl_card_no,
                   orgnl_rrn, orgnl_business_date,
                   orgnl_business_time, orgnl_terminal_id,
                   proxy_number, reversal_code, customer_acct_no,
                   acct_balance, ledger_balance, response_id, remark,
                   reason,
                   cr_dr_flag, -- added on 22-Sep-2012 by sagar
                   add_ins_date,  -- added on 25-Sep-2012 by sagar
                   add_ins_user,  -- added on 25-Sep-2012 by sagar
                   add_lupd_user,  -- added on 25-Sep-2012 by sagar
                   error_msg,       -- added by sagar on 03-oct-2012
                   ipaddress,        --added by amit on 07-Oct-2012
                  --SN: Added on 03-Apr-2013 for defect 0010690
                   merchant_zip,
                   merchant_id,
                   merchant_name,
                   merchant_state,
                   merchant_city,
                  --EN: Added on 03-Apr-2013 for defect 0010690
                  cardstatus,acct_type,time_stamp --added by Pankaj S. for 10871

                  )
           VALUES (prm_msg_typ, prm_rrn, prm_delv_chnl, prm_terminal_id,
                   v_rvsl_trandate, prm_txn_code, prm_txn_type,
                   prm_txn_mode, DECODE (prm_resp_cde, '00', 'C', 'F'),
                   prm_resp_cde, prm_business_date,
                   SUBSTR (prm_business_time, 1, 6),
                                                    --prm_card_no
                                                    v_hash_pan, NULL,
                   --prm_topup_cardno,
                   NULL,                               --prm_topup_acctno    ,
                        NULL,                            --prm_topup_accttype,
                             prm_inst_code,
                   --                          prm_actual_amt
                   TRIM (TO_CHAR (v_reversal_amt, '999999999999999990.99')) --modified for 10871
-- reversal amount will be passed in the table as the same is used in the recon report.
      ,
                   NULL, NULL, prm_merc_id, v_curr_code,
                   --  prm_add_charge,
                   v_prod_code, v_card_type, 0, '0.00' --modified for 10871
                   , NULL,
                   NULL, v_auth_id, v_tran_desc,
                   --                          0,
                   TRIM (TO_CHAR (v_reversal_amt, '999999999999999990.99')), --modified for 10871
-- reversal amount will be passed in the table as the same is used in the recon report.
                   '0.00',--Modified by Pankaj S. for 10871  --- PRE AUTH AMOUNT
                   '0.00',--Modified by Pankaj S. for 10871
                             -- Partial amount (will be given for partial txn)
                   NULL,
                   NULL, NULL, NULL,
                   NULL, 'Y', prm_stan,
                   prm_inst_code, NULL, NULL, 'N',
                   v_encr_pan, NULL, v_encr_pan,
                   prm_orgnl_rrn, prm_orgnl_business_date,
                   prm_orgnl_business_time, prm_orgnl_terminal_id,
                   v_proxunumber, prm_rvsl_code, v_acct_number,
                   v_acct_balance, v_ledger_bal, v_resp_cde, prm_remark,
                   v_reason,
                   v_dr_cr_flag, -- added on 22-Sep-2012 by sagar
                   sysdate,      -- added on 25-Sep-2012 by sagar
                   prm_ins_user, -- added on 25-Sep-2012 by sagar
                   prm_ins_user,  -- added on 25-Sep-2012 by sagar
                   v_errmsg,       -- added by sagar on 03-oct-2012
                   prm_ipaddress,  --added by amit on 07-Oct-2012
                  --SN: Added on 03-Apr-2013 for defect 0010690
                   v_merchant_zip,
                   v_merchant_id,
                   v_merchant_name,
                   v_merchant_state,
                   v_merchant_city,
                  --EN: Added on 03-Apr-2013 for defect 0010690
                  v_card_stat,v_acct_type,v_timestamp   --added by Pankaj S. for 10871
                  );

      --prm_resp_cde := '00';
      --Sn update reverse flag
      BEGIN
       IF v_orgnl_delivery_channel='13' THEN
	   
	     --Added for VMS-5739/FSP-991
		   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_business_date), 1, 8), 'yyyymmdd');
		   
	     IF (v_Retdate>v_Retperiod) THEN                                       --Added for VMS-5739/FSP-991
		
          UPDATE transactionlog
            SET tran_reverse_flag = 'Y',
                fee_reversal_flag ='Y'  
           WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_business_date
            AND business_time = prm_orgnl_business_time
            AND customer_card_no = v_hash_pan                 
            AND instcode = prm_inst_code;
			
		 ELSE
		
		    UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST                  --Added for VMS-5739/FSP-991
            SET tran_reverse_flag = 'Y',
                fee_reversal_flag ='Y'  
          WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_business_date
            AND business_time = prm_orgnl_business_time
            AND customer_card_no = v_hash_pan                 
            AND instcode = prm_inst_code;
		
		 END IF;
		
        ELSE
		
	     IF (v_Retdate>v_Retperiod) THEN                                       --Added for VMS-5739/FSP-991
            
			UPDATE transactionlog
            SET tran_reverse_flag = 'Y',
                fee_reversal_flag ='Y'   -- Added by sagar on 15Sep2012
          WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_business_date
            AND business_time = prm_orgnl_business_time
            AND customer_card_no = v_hash_pan                   --prm_card_no;
            AND instcode = prm_inst_code
            AND terminal_id = prm_orgnl_terminal_id;
			
		 ELSE
		 
		    UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST                   --Added for VMS-5739/FSP-991
            SET tran_reverse_flag = 'Y',
                fee_reversal_flag ='Y'   -- Added by sagar on 15Sep2012
          WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_business_date
            AND business_time = prm_orgnl_business_time
            AND customer_card_no = v_hash_pan                   --prm_card_no;
            AND instcode = prm_inst_code
            AND terminal_id = prm_orgnl_terminal_id;
		 
		 END IF;
		 
        END IF;
         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            v_errmsg := 'Reverse flag is not updated ';
            RAISE exp_rvsl_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_rvsl_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while updating gl flag ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      END;

      --En update reverse flag 
      
      -- Commented by UBAIDUR RAHMAN on 17-JAN-2018
      /*
	  BEGIN
         SELECT ctc_atmusage_amt, ctc_posusage_amt, ctc_business_date,
                ctc_mmposusage_amt
           INTO v_atm_usageamnt, v_pos_usageamnt, v_business_date_tran,
                v_mmpos_usageamnt
           FROM cms_translimit_check
          WHERE ctc_inst_code = prm_inst_code
            AND ctc_pan_code = v_hash_pan                       -- prm_card_no
            AND ctc_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Cannot get the Transaction Limit Details of the Card'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_rvsl_reject_record;
      END;
	  */
      /*
      BEGIN
         --Sn Limit and amount check for POS
         IF prm_delv_chnl = '02'
         THEN
            IF v_rvsl_trandate > v_business_date_tran
            THEN
               UPDATE cms_translimit_check
                  SET ctc_posusage_amt = 0,
                      ctc_posusage_limit = 0,
                      ctc_atmusage_amt = 0,
                      ctc_atmusage_limit = 0,
                      ctc_business_date =
                         TO_DATE (prm_business_date || '23:59:59',
                                  'yymmdd' || 'hh24:mi:ss'
                                 ),
                      ctc_preauthusage_limit = 0,
                      ctc_mmposusage_amt = 0,
                      ctc_mmposusage_limit = 0
                WHERE ctc_inst_code = prm_inst_code
                  AND ctc_pan_code = v_hash_pan                 -- prm_card_no
                  AND ctc_mbr_numb = prm_mbr_numb;
            ELSE
               IF prm_orgnl_business_date = prm_business_date
               THEN
                  IF v_reversal_amt IS NULL
                  THEN
                     v_pos_usageamnt := v_pos_usageamnt;
                  ELSE
                     v_pos_usageamnt :=
                          v_pos_usageamnt
                        - TRIM (TO_CHAR (v_reversal_amt, '999999999999.99'));
                  END IF;

                  UPDATE cms_translimit_check
                     SET ctc_posusage_amt = v_pos_usageamnt
                   WHERE ctc_inst_code = prm_inst_code
                     AND ctc_pan_code = v_hash_pan                   --CARD NO
                     AND ctc_mbr_numb = prm_mbr_numb;
               END IF;
            END IF;
         END IF;
      --En Limit and amount check for POS
      END;
	  */

      IF v_errmsg = 'OK'
      THEN
          --Sn find prod code and card type and available balance for the card number
         /* BEGIN
             SELECT     cam_acct_bal, cam_ledger_bal
                   INTO v_acct_balance, v_ledger_bal
                   FROM cms_acct_mast
                  WHERE cam_acct_no =
                           (SELECT cap_acct_no
                              FROM cms_appl_pan
                             WHERE cap_pan_code = v_hash_pan      --prm_card_no
                               AND cap_mbr_numb = prm_mbr_numb
                               AND cap_inst_code = prm_inst_code)
                    AND cam_inst_code = prm_inst_code
             FOR UPDATE NOWAIT;
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                v_resp_cde := '14';                   --Ineligible Transaction
                v_errmsg := 'Invalid Card ';
                RAISE exp_rvsl_reject_record;
             WHEN OTHERS
             THEN
                v_resp_cde := '12';
                v_errmsg :=
                      'Error while selecting balance from acct Master for card number '||prm_card_no
                      ||substr(SQLERRM,1,100);
                RAISE exp_rvsl_reject_record;
          END;
         */
          --En find prod code and card type for the card number
         prm_acct_bal := TO_CHAR (v_acct_balance);
         prm_resp_msg := v_errmsg;
      ELSE
         prm_resp_msg := v_errmsg;
      END IF;
   -- prm_resp_msg := 'OK';
   EXCEPTION
      WHEN exp_rvsl_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
               'Error while inserting records in transaction log '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
--En  create a entry in GL

      IF v_orgnl_txn_totalfee_amt=0 AND v_orgnl_txn_feecode IS NOT NULL THEN
        BEGIN
           vmsfee.fee_freecnt_reverse (v_acct_number, v_orgnl_txn_feecode, v_errmsg);
        
           IF v_errmsg <> 'OK' THEN
              v_resp_cde := '21';
              RAISE exp_rvsl_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_rvsl_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              v_resp_cde := '21';
              v_errmsg :='Error while reversing freefee count-'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_rvsl_reject_record;
        END;
      END IF;  
EXCEPTION
   -- << MAIN EXCEPTION>>
   WHEN exp_rvsl_reject_record
   THEN
      ROLLBACK TO v_savepoint;

      --Sn Commented here & used doun during Fss-837
      /*BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code --added by Pankaj S. for 10871
           INTO v_acct_balance, v_ledger_bal,
                v_acct_type --added by Pankaj S. for 10871
           FROM cms_acct_mast
          WHERE cam_acct_no =
                   (SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_inst_code = prm_inst_code
                       AND cap_pan_code = v_hash_pan
                       AND cap_mbr_numb = prm_mbr_numb)
            AND cam_inst_code = prm_inst_code;

         prm_acct_bal := TO_CHAR (v_acct_balance);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
            prm_acct_bal := 0;
      END;*/
      --En Commented here & used doun during Fss-837
      

      BEGIN
         SELECT cms_iso_respcde
           INTO prm_resp_cde
           FROM cms_response_mast
          WHERE cms_inst_code = prm_inst_code
            AND cms_delivery_channel = prm_delv_chnl
            AND cms_response_id = TO_NUMBER (v_resp_cde);

         prm_resp_msg := v_errmsg;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_msg :=
                  'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_cde := '69';
      -- RETURN;
      END;

 -- Commented by UBAIDUR RAHMAN on 17-JAN-2018
	  /* 
      BEGIN
         SELECT ctc_atmusage_amt, ctc_posusage_amt, ctc_business_date,
                ctc_mmposusage_amt
           INTO v_atm_usageamnt, v_pos_usageamnt, v_business_date_tran,
                v_mmpos_usageamnt
           FROM cms_translimit_check
          WHERE ctc_inst_code = prm_inst_code
            AND ctc_pan_code = v_hash_pan                       -- prm_card_no
            AND ctc_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_msg :=
                  'Cannot get the Transaction Limit Details of the Card'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_cde := '89';
      --v_resp_cde := '21';
      --RAISE exp_rvsl_reject_record;
      END;
	  */
 
      /* 
      BEGIN
         --Sn limit update for POS
         IF prm_delv_chnl = '02'
         THEN
            IF v_rvsl_trandate > v_business_date_tran
            THEN
               UPDATE cms_translimit_check
                  SET ctc_posusage_amt = 0,
                      ctc_posusage_limit = 0,
                      ctc_atmusage_amt = 0,
                      ctc_atmusage_limit = 0,
                      ctc_business_date =
                         TO_DATE (prm_business_date || '23:59:59',
                                  'yymmdd' || 'hh24:mi:ss'
                                 ),
                      ctc_preauthusage_limit = 0,
                      ctc_mmposusage_amt = 0,
                      ctc_mmposusage_limit = 0
                WHERE ctc_inst_code = prm_inst_code
                  AND ctc_pan_code = v_hash_pan                 -- prm_card_no
                  AND ctc_mbr_numb = prm_mbr_numb;
            END IF;
         END IF;
      END;
	  */

      --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
        SELECT  ctm_credit_debit_flag, ctm_tran_desc
           INTO v_dr_cr_flag, v_tran_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_txn_code
            AND ctm_delivery_channel = prm_delv_chnl
            AND ctm_inst_code = prm_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_prod_code is NULL THEN
      BEGIN
        SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
          INTO v_prod_code, v_card_type, v_card_stat,v_acct_number
          FROM cms_appl_pan
         WHERE cap_inst_code = prm_inst_code
           AND cap_pan_code = gethash (prm_card_no)
           AND cap_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code --added by Pankaj S. for 10871
           INTO v_acct_balance, v_ledger_bal,
                v_acct_type --added by Pankaj S. for 10871
           FROM cms_acct_mast
          WHERE cam_acct_no =v_acct_number
                   /*(SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_inst_code = prm_inst_code
                       AND cap_pan_code = v_hash_pan
                       AND cap_mbr_numb = prm_mbr_numb)*/
            AND cam_inst_code = prm_inst_code;

         prm_acct_bal := TO_CHAR (v_acct_balance);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
            prm_acct_bal := 0;
      END;
      --En added by Pankaj S. for 10871


      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type,
                      txn_mode, txn_status,
                      response_code, business_date,
                      business_time, customer_card_no, topup_card_no,
                      topup_acct_no, topup_acct_type, bank_code,
                      total_amount,
                      currencycode, addcharge, categoryid,
                      atm_name_location, auth_id,
                      amount,
                      preauthamount, partialamount,
                      instcode,
                      customer_card_no_encr, topup_card_no_encr,
                      orgnl_card_no, orgnl_rrn, orgnl_business_date,
                      orgnl_business_time, orgnl_terminal_id,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance, response_id, remark,
                      reason,trans_desc,
                      cr_dr_flag, -- added on 22-Sep-2012 by sagar
                      add_ins_date, -- added on 25-Sep-2012 by sagar
                      add_ins_user, -- added on 25-Sep-2012 by sagar
                      add_lupd_user, -- added on 25-Sep-2012 by sagar
                      error_msg,      -- added by sagar on 03-oct-2012
                      ipaddress,        --added by amit on 07-Oct-2012
                      --SN: Added on 03-Apr-2013 for defect 0010690
                       merchant_zip,
                       merchant_id,
                       merchant_name,
                       merchant_state,
                       merchant_city,
                      --EN: Added on 03-Apr-2013 for defect 0010690
                      --Sn added by Pankaj S. for 10871
                      productid,cardstatus,acct_type,time_stamp
                      --En added by Pankaj S. for 10871
                     )
              VALUES (prm_msg_typ, prm_rrn, prm_delv_chnl, prm_terminal_id,
                      v_rvsl_trandate, prm_txn_code, prm_txn_type,
                      prm_txn_mode, DECODE (prm_resp_cde, '00', 'C', 'F'),
                      prm_resp_cde, prm_business_date,
                      SUBSTR (prm_business_time, 1, 10), v_hash_pan, NULL,
                      NULL, NULL, prm_inst_code,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '999999999999999990.99')), --modified for 10871
                      v_currcode, NULL, v_card_type, --v_card_type added by Pankaj S. for 10871
                      prm_terminal_id, v_auth_id,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '999999999999999990.99')), --modified for 10871
                      '0.00', '0.00', --modified by Pankaj S. for 10871
                       prm_inst_code,
                      v_encr_pan, v_encr_pan,
                      v_encr_pan, prm_orgnl_rrn, prm_orgnl_business_date,
                      prm_orgnl_business_time, prm_orgnl_terminal_id,
                      v_proxunumber, prm_rvsl_code, v_acct_number,
                      v_acct_balance, v_ledger_bal, v_resp_cde, prm_remark,
                      v_reason,v_tran_desc,
                      v_dr_cr_flag,   -- added on 22-Sep-2012 by sagar
                      sysdate,        -- added on 25-Sep-2012 by sagar
                      prm_ins_user,   -- added on 25-Sep-2012 by sagar
                      prm_ins_user,   -- added on 25-Sep-2012 by sagar
                      v_errmsg,        -- added by sagar on 03-oct-2012
                      prm_ipaddress,   --added by amit on 07-Oct-2012
                      --SN: Added on 03-Apr-2013 for defect 0010690
                      v_merchant_zip,
                      v_merchant_id,
                      v_merchant_name,
                      v_merchant_state,
                      v_merchant_city,
                      --EN: Added on 03-Apr-2013 for defect 0010690
                      --Sn added by Pankaj S. for 10871
                      v_prod_code,v_card_stat,v_acct_type,nvl(v_timestamp,systimestamp)
                      --En added by Pankaj S. for 10871
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_cde := '89';
            prm_resp_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --En create a entry in txn log
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
                      ctd_completion_fee,ctd_complfee_increment_type  --Added by Pankaj S. for FSS-837
                     )
              VALUES (prm_delv_chnl, prm_txn_code, prm_txn_type,
                      prm_msg_typ, prm_txn_mode, prm_business_date,
                      prm_business_time, v_hash_pan,
                      prm_actual_amt,--v_tran_amt, --prm_actual_amt modified for 10871  modified for defect id:12166
                      v_currcode, v_tran_amt,
                      NULL, NULL,
                      NULL, NULL,
                      v_tran_amt, --prm_actual_amt modified for 10871
                      v_card_curr, 'E',
                      v_errmsg, prm_rrn, prm_stan,
                      prm_inst_code, v_encr_pan,
                      v_acct_number,
                      v_completion_fee,'C'  --Added by Pankaj S. for FSS-837
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_cde := '69';            -- Server Decline Response 220509
            ROLLBACK;
            RETURN;
      END;
   --  prm_resp_msg := v_errmsg;
   WHEN OTHERS
   THEN
      ROLLBACK TO v_savepoint;
      --Sn Commented here & used doun during Fss-837
      /*BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code --added by Pankaj S. for 10871
           INTO v_acct_balance, v_ledger_bal,
                v_acct_type --added by Pankaj S. for 10871
           FROM cms_acct_mast
          WHERE cam_acct_no =v_acct_number
                  (SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_inst_code = prm_inst_code
                       AND cap_pan_code = v_hash_pan
                       AND cap_mbr_numb = prm_mbr_numb)
            AND cam_inst_code = prm_inst_code;

         prm_acct_bal := TO_CHAR (v_acct_balance);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
            prm_acct_bal := 0;
      END;*/
      --En Commented here & used doun during Fss-837
      

      BEGIN
         SELECT cms_iso_respcde
           INTO prm_resp_cde
           FROM cms_response_mast
          WHERE cms_inst_code = prm_inst_code
            AND cms_delivery_channel = prm_delv_chnl
            AND cms_response_id = TO_NUMBER (v_resp_cde);

         prm_resp_msg := v_errmsg;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_msg :=
                  'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_cde := '69';
      --  RETURN;
      END;
      
       -- Commented by UBAIDUR RAHMAN on 17-JAN-2018
      /*
      BEGIN
         SELECT ctc_atmusage_amt, ctc_posusage_amt, ctc_business_date,
                ctc_mmposusage_amt
           INTO v_atm_usageamnt, v_pos_usageamnt, v_business_date_tran,
                v_mmpos_usageamnt
           FROM cms_translimit_check
          WHERE ctc_inst_code = prm_inst_code
            AND ctc_pan_code = v_hash_pan                       -- prm_card_no
            AND ctc_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_msg :=
                  'Cannot get the Transaction Limit Details of the Card'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_cde := '89';
      -- v_resp_cde := '21';
       --RAISE exp_rvsl_reject_record;
      END;

      BEGIN
         --Sn limit update for POS
         IF prm_delv_chnl = '02'
         THEN
            IF v_rvsl_trandate > v_business_date_tran
            THEN
               UPDATE cms_translimit_check
                  SET ctc_posusage_amt = 0,
                      ctc_posusage_limit = 0,
                      ctc_atmusage_amt = 0,
                      ctc_atmusage_limit = 0,
                      ctc_business_date =
                         TO_DATE (prm_business_date || '23:59:59',
                                  'yymmdd' || 'hh24:mi:ss'
                                 ),
                      ctc_preauthusage_limit = 0,
                      ctc_mmposusage_amt = 0,
                      ctc_mmposusage_limit = 0
                WHERE ctc_inst_code = prm_inst_code
                  AND ctc_pan_code = v_hash_pan                 -- prm_card_no
                  AND ctc_mbr_numb = prm_mbr_numb;
            END IF;
         END IF;
      END;
	  */

      --Sn create a entry in txn log
      --Sn Commented during FSS-837 changes
     /* BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_bal
           FROM cms_acct_mast
          WHERE cam_acct_no =
                   (SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_inst_code = prm_inst_code
                       AND cap_pan_code = v_hash_pan
                       AND cap_mbr_numb = prm_mbr_numb)
            AND cam_inst_code = prm_inst_code;

         prm_acct_bal := TO_CHAR (v_acct_balance);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;*/
      --En Commented during FSS-837 changes

      --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
        SELECT  ctm_credit_debit_flag, ctm_tran_desc
           INTO v_dr_cr_flag, v_tran_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_txn_code
            AND ctm_delivery_channel = prm_delv_chnl
            AND ctm_inst_code = prm_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_prod_code is NULL THEN
      BEGIN
        SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
          INTO v_prod_code, v_card_type, v_card_stat,v_acct_number
          FROM cms_appl_pan
         WHERE cap_inst_code = prm_inst_code
           AND cap_pan_code = gethash (prm_card_no)
           AND cap_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code --added by Pankaj S. for 10871
           INTO v_acct_balance, v_ledger_bal,
                v_acct_type --added by Pankaj S. for 10871
           FROM cms_acct_mast
          WHERE cam_acct_no =v_acct_number
                  /* (SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_inst_code = prm_inst_code
                       AND cap_pan_code = v_hash_pan
                       AND cap_mbr_numb = prm_mbr_numb)*/
            AND cam_inst_code = prm_inst_code;

         prm_acct_bal := TO_CHAR (v_acct_balance);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
            prm_acct_bal := 0;
      END;
      --En added by Pankaj S. for 10871

      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type,
                      txn_mode, txn_status,
                      response_code, business_date,
                      business_time, customer_card_no, topup_card_no,
                      topup_acct_no, topup_acct_type, bank_code,
                      total_amount,
                      currencycode, addcharge, categoryid,
                      atm_name_location, auth_id,
                      amount,
                      preauthamount, partialamount, instcode,
                      customer_card_no_encr, topup_card_no_encr,
                      orgnl_card_no, orgnl_rrn, orgnl_business_date,
                      orgnl_business_time, orgnl_terminal_id,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance, response_id, remark,
                      reason,trans_desc,
                      cr_dr_flag,    -- added on 22-Sep-2012 by sagar
                      add_ins_date,  -- added on 25-Sep-2012 by sagar
                      add_ins_user,  -- added on 25-Sep-2012 by sagar
                      add_lupd_user, -- added on 25-Sep-2012 by sagar
                      error_msg,      -- added by sagar on 03-oct-2012
                      ipaddress,   --added by amit on 07-Oct-2012
                      --SN: Added on 03-Apr-2013 for defect 0010690
                      merchant_zip,
                      merchant_id,
                      merchant_name,
                      merchant_state,
                      merchant_city,
                     --EN: Added on 03-Apr-2013 for defect 0010690
                     --Sn added by Pankaj S. for 10871
                      productid,cardstatus,acct_type,time_stamp
                      --En added by Pankaj S. for 10871
                      )
              VALUES (prm_msg_typ, prm_rrn, prm_delv_chnl, prm_terminal_id,
                      v_rvsl_trandate, prm_txn_code, prm_txn_type,
                      prm_txn_mode, DECODE (prm_resp_cde, '00', 'C', 'F'),
                      prm_resp_cde, prm_business_date,
                      SUBSTR (prm_business_time, 1, 10), v_hash_pan, NULL,
                      NULL, NULL, prm_inst_code,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '999999999999999990.99')), --modified for 10871
                      v_currcode, NULL, v_card_type, --v_card_type added by Pankaj S. for 10871
                      prm_terminal_id, v_auth_id,
                      TRIM (TO_CHAR (nvl(v_tran_amt,0), '999999999999999990.99')), --modified for 10871
                      '0.00','0.00',--modified by Pankaj S. for 10871
                      prm_inst_code,
                      v_encr_pan, v_encr_pan,
                      v_encr_pan, prm_orgnl_rrn, prm_orgnl_business_date,
                      prm_orgnl_business_time, prm_orgnl_terminal_id,
                      v_proxunumber, prm_rvsl_code, v_acct_number,
                      v_acct_balance, v_ledger_bal, v_resp_cde, prm_remark,
                      v_reason,v_tran_desc,
                      v_dr_cr_flag,  -- added on 22-Sep-2012 by sagar
                      sysdate,       -- added on 25-Sep-2012 by sagar
                      prm_ins_user,  -- added on 25-Sep-2012 by sagar
                      prm_ins_user,  -- added on 25-Sep-2012 by sagar
                      v_errmsg,       -- added by sagar on 03-oct-2012
                      prm_ipaddress,  --added by amit on 07-Oct-2012
                      --SN: Added on 03-Apr-2013 for defect 0010690
                      v_merchant_zip,
                      v_merchant_id,
                      v_merchant_name,
                      v_merchant_state,
                      v_merchant_city,
                      --EN: Added on 03-Apr-2013 for defect 0010690
                      --Sn added by Pankaj S. for 10871
                      v_prod_code,v_card_stat,v_acct_type,nvl(v_timestamp,systimestamp)
                      --En added by Pankaj S. for 10871
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_cde := '89';
            prm_resp_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --En create a entry in txn log
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
                      ctd_completion_fee,ctd_complfee_increment_type  --Added by Pankaj S. for FSS-837
                     )
              VALUES (prm_delv_chnl, prm_txn_code, prm_txn_type,
                      prm_msg_typ, prm_txn_mode, prm_business_date,
                      prm_business_time, v_hash_pan,
                      prm_actual_amt,--v_tran_amt, --prm_actual_amt modified for 10871 modified for defect id:12166
                      v_currcode, v_tran_amt,
                      NULL, NULL,
                      NULL, NULL,
                      v_tran_amt, --prm_actual_amt modified for 10871
                      v_card_curr, 'E',
                      v_errmsg, prm_rrn, prm_stan,
                      prm_inst_code, v_encr_pan,
                      v_acct_number,
                      v_completion_fee,'C'  --Added by Pankaj S. for FSS-837
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_cde := '69';            -- Server Decline Response 220509
            ROLLBACK;
            RETURN;
      END;
-- prm_resp_msg := v_errmsg;
END;                                                         -- << MAIN END;>>

/
show error;