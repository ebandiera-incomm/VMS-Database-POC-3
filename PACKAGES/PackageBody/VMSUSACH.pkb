CREATE OR REPLACE PACKAGE BODY VMSCMS.VMSUSACH
IS
   -- Private type declarations

   -- Private constant declarations

   -- Private variable declarations

   -- Function and procedure implementations
   --Function "check_achbypass" returns 'Y' or 'N'  for bypassing the rejection
   -- Depending on whether the  input Acct_no and Merchant have the transactions approved from the exception queue
   
   /* 
   * Modified by          :Siva Kumar M
   * Modified Date        : 05-JAN-16
   * Modified For         : MVHOST-1255
   * Modified reason      : reason code logging
   * Reviewer             : Saravans kumar 
   * Build Number         : RI0027.3.3_B0002
   
       * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07*/

   FUNCTION check_achbypass (p_acct_no_in         VARCHAR2,
                             p_company_name_in    VARCHAR2,
                             p_resp_code_in       VARCHAR2)
      RETURN VARCHAR2
   IS
      l_achbypass   VARCHAR2 (1);
   BEGIN
      SELECT vaa_enable_flag
        INTO l_achbypass
        FROM vms_achexc_appd_acc
       WHERE     vaa_acct_no = p_acct_no_in
             AND vaa_company_name = p_company_name_in
             AND vaa_resp_code = p_resp_code_in
             AND vaa_expiry_date >= TRUNC (SYSDATE);

       RETURN l_achbypass;
   EXCEPTION
      WHEN OTHERS THEN
         l_achbypass := 'N';
         RETURN l_achbypass;
   END check_achbypass;
--BEGIN
   -- Initialization
  -- NULL;

PROCEDURE        REJECT_ACHTXN_CSR (
   p_inst_code_in                 IN       NUMBER,
   p_revrsl_code_in               IN       VARCHAR2,
   p_msg_type_in                  IN       VARCHAR2,
   p_rrn_in                       IN       VARCHAR2,
   p_stan_in                      IN       VARCHAR2,
   p_tran_date_in                 IN       VARCHAR2,
   p_tran_time_in                 IN       VARCHAR2,
   p_txn_amt_in                   IN       VARCHAR2,
   p_txn_code_in                  IN       VARCHAR2,
   p_delivery_chnl_in             IN       VARCHAR2,
   p_txn_mode_in                  IN       VARCHAR2,
   p_mbr_numb_in                  IN       VARCHAR2,
   p_orgnl_rrn_in                 IN       VARCHAR2,
   p_orgnl_card_no_in             IN       VARCHAR2,
   p_orgnl_stan_in                IN       VARCHAR2,
   p_orgnl_tran_date_in           IN       VARCHAR2,
   p_orgnl_tran_time_in           IN       VARCHAR2,
   p_orgnl_txn_amt_in             IN       VARCHAR2,
   p_orgnl_txn_code_in            IN       VARCHAR2,
   p_orgnl_delivery_chnl_in       IN       VARCHAR2,
   p_orgnl_auth_id_in             IN       VARCHAR2,
   p_curr_code_in                 IN       VARCHAR2,
   p_remark_in                    IN       VARCHAR2,
  -- p_reason_desc_in               IN       VARCHAR2,
   p_reason_code_in                IN       VARCHAR2,
   p_ins_user_in                   IN       NUMBER,
   p_r17_response_in               IN       VARCHAR2,
   p_resp_code_out                 OUT      VARCHAR2,
   p_errmsg_out                    OUT      VARCHAR2,
   p_ach_startledgerbal_out        OUT      VARCHAR2,
   p_ach_startaccountbalance_out   OUT      VARCHAR2,
   p_ach_endledgerbal_out          OUT      VARCHAR2,
   p_ach_endaccountbalance_out     OUT      VARCHAR2,
   p_ach_auth_id_out               OUT      VARCHAR2
)
IS
/******************************************************************************************
     * Created Date     : 10/July/2015.
     * Created By       : Abdul Hameed M.A
     * Purpose          : Reject the Approved ACH transaction  through CSR
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     :
     
     * Created Date     : 10/Nov/2020.
     * Created By       : Baskar
     * Purpose          : VMS-3326
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     :
     
     * Modified Date    : 17/Dec/2020.
     * Modified By      : RAJ DEVKOTA
     * Purpose          : VMS-3412
     * Reviewer         : Ubaidur Rahman.H
     * Reviewed Date    : 18/Dec/2020.
     * Build Number     : VMS_GPRHOST_R40_B1    
 ********************************************************************************************/
   l_resp_cde                  VARCHAR2 (2);
   l_err_msg                   VARCHAR2 (300);
   l_acct_balance              cms_acct_mast.cam_acct_bal%TYPE;
   l_ledger_bal                cms_acct_mast.cam_ledger_bal%TYPE;
   l_auth_id                   VARCHAR2 (6);
   l_rrn_count                 NUMBER (3);
   l_hash_pan                  cms_appl_pan.cap_pan_code%TYPE;
   l_encr_pan                  cms_appl_pan.cap_pan_code_encr%TYPE;
   l_card_acct_no              cms_appl_pan.cap_acct_no%TYPE;
   l_exp_reject_record           EXCEPTION;
   l_dr_cr_flag                cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   l_proxy_number              transactionlog.proxy_number%TYPE;
   l_tran_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
   l_card_type                 cms_appl_pan.cap_card_type%TYPE;
   l_prod_code                 cms_appl_pan.cap_prod_code%TYPE;
   l_card_stat                 cms_appl_pan.cap_card_stat%TYPE;
   l_expry_date                cms_appl_pan.cap_expry_date%TYPE;
   l_mbr_numb                  cms_appl_pan.cap_mbr_numb%TYPE;
   l_orgnl_terminal_id         transactionlog.terminal_id%TYPE;
   l_orgnl_msgtype             transactionlog.msgtype%TYPE;
   l_orgnl_rrn                 transactionlog.rrn%TYPE;
   l_orgnl_delivery_channel    transactionlog.delivery_channel%TYPE;
   l_orgnl_txn_code            transactionlog.txn_code%TYPE;
   l_orgnl_txn_mode            transactionlog.txn_mode%TYPE;
   l_orgnl_response_code       transactionlog.response_code%TYPE;
   l_orgnl_business_date       transactionlog.business_date%TYPE;
   l_orgnl_business_time       transactionlog.business_time%TYPE;
   l_orgnl_total_amount        transactionlog.total_amount%TYPE;
   l_orgnl_amount              transactionlog.amount%TYPE;
   l_orgnl_instcode            transactionlog.instcode%TYPE;
   l_orgnl_cardnum             VARCHAR2 (20);
   l_orgnl_reversal_code       transactionlog.reversal_code%TYPE;
   l_orgnl_customer_acct_no    transactionlog.customer_acct_no%TYPE;
   l_orgnl_achfilename         transactionlog.achfilename%TYPE;
   l_orgnl_rdfi                transactionlog.rdfi%TYPE;
   l_orgnl_seccodes            transactionlog.seccodes%TYPE;
   l_orgnl_impdate             transactionlog.impdate%TYPE;
   l_orgnl_processdate         transactionlog.processdate%TYPE;
   l_orgnl_effectivedate       transactionlog.effectivedate%TYPE;
   l_orgnl_tracenumber         transactionlog.tracenumber%TYPE;
   l_orgnl_incoming_crfileid   transactionlog.incoming_crfileid%TYPE;
   l_orgnl_auth_id             transactionlog.auth_id%TYPE;
   l_orgnl_achtrantype_id      transactionlog.achtrantype_id%TYPE;
   l_orgnl_indidnum            transactionlog.indidnum%TYPE;
   l_orgnl_indname             transactionlog.indname%TYPE;
   l_orgnl_companyname         transactionlog.companyname%TYPE;
   l_orgnl_companyid           transactionlog.companyid%TYPE;
   l_orgnl_ach_id              transactionlog.ach_id%TYPE;
   l_orgnl_compentrydesc       transactionlog.compentrydesc%TYPE;
   l_orgnl_response_id         transactionlog.response_id%TYPE;
   l_orgnl_customerlastname    transactionlog.customerlastname%TYPE;
   l_orgnl_odfi                transactionlog.odfi%TYPE;
   l_orgnl_currencycode        transactionlog.currencycode%TYPE;
   l_addcharge                 transactionlog.addcharge%TYPE;
   l_timestamp                 TIMESTAMP ( 3 );
   l_txn_type                  transactionlog.txn_type%TYPE;
   l_tran_type                 cms_transaction_mast.ctm_tran_type%TYPE;
   l_txn_narration             cms_statements_log.csl_trans_narrration%TYPE;
   l_fee_narration             cms_statements_log.csl_trans_narrration%TYPE;
   l_txn_merchname             cms_statements_log.csl_merchant_name%TYPE;
   l_fee_merchname             cms_statements_log.csl_merchant_name%TYPE;
   l_txn_merchcity             cms_statements_log.csl_merchant_city%TYPE;
   l_fee_merchcity             cms_statements_log.csl_merchant_city%TYPE;
   l_txn_merchstate            cms_statements_log.csl_merchant_state%TYPE;
   l_fee_merchstate            cms_statements_log.csl_merchant_state%TYPE;
   l_tran_date                 DATE;
   l_tran_amt                  NUMBER;
   l_card_curr                 VARCHAR2 (5);
   l_func_code                 cms_func_mast.cfm_func_code%TYPE;
   l_orgnl_txn_totalfee_amt    transactionlog.tranfee_amt%TYPE;
   l_orgnl_txn_feecode         cms_fee_mast.cfm_fee_code%TYPE;
   l_feecap_flag               VARCHAR2 (1);
   l_orgnl_fee_amt             cms_fee_mast.cfm_fee_amt%TYPE;
   l_orgnl_tranfee_amt         transactionlog.tranfee_amt%TYPE;
   l_add_ins_date              transactionlog.add_ins_date%TYPE;
   l_orgnl_txn_fee_plan        transactionlog.fee_plan%TYPE;
   l_orgnl_servicetax_amt      transactionlog.servicetax_amt%TYPE;
   l_orgnl_cess_amt            transactionlog.cess_amt%TYPE;
   l_orgnl_tranfee_cr_acctno   transactionlog.tranfee_cr_acctno%TYPE;
   l_orgnl_tranfee_dr_acctno   transactionlog.tranfee_dr_acctno%TYPE;
   l_orgnl_st_calc_flag        transactionlog.tran_st_calc_flag%TYPE;
   l_orgnl_cess_calc_flag      transactionlog.tran_cess_calc_flag%TYPE;
   l_orgnl_st_cr_acctno        transactionlog.tran_st_cr_acctno%TYPE;
   l_orgnl_st_dr_acctno        transactionlog.tran_st_dr_acctno%TYPE;
   l_orgnl_cess_cr_acctno      transactionlog.tran_cess_cr_acctno%TYPE;
   l_orgnl_cess_dr_acctno      transactionlog.tran_cess_dr_acctno%TYPE;
   l_acct_type                 cms_acct_mast.cam_type_code%TYPE;
   l_prfl_code                 cms_appl_pan.cap_prfl_code%TYPE;
   l_prfl_flag                 cms_transaction_mast.ctm_prfl_flag%TYPE;
   l_logdtl_resp               VARCHAR2 (500);
   l_auth_savepoint            NUMBER                               DEFAULT 0;
   l_remarks                   VARCHAR2(2000);
   l_upd_amt            NUMBER;
   
   l_reason_desc       cms_spprt_reasons.CSR_REASONDESC%TYPE;
   l_resp_desc         cms_response_mast.cms_resp_desc%TYPE;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991

   CURSOR l_cur_stmnts_log
   IS
      SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
             csl_merchant_state, csl_trans_amount
        FROM VMSCMS.CMS_STATEMENTS_LOG_VW 		--Added for VMS-5733/FSP-991
       WHERE csl_business_date = p_orgnl_tran_date_in
         AND csl_rrn = p_orgnl_rrn_in
         AND csl_delivery_channel = p_orgnl_delivery_chnl_in
         AND csl_txn_code = p_orgnl_txn_code_in
         AND csl_pan_no = l_hash_pan
         AND csl_inst_code = p_inst_code_in
         AND txn_fee_flag = 'Y';
BEGIN
   l_resp_cde := '1';
   l_timestamp := SYSTIMESTAMP;

   BEGIN
      SAVEPOINT l_auth_savepoint;
      l_err_msg := 'OK';

      BEGIN
         l_hash_pan := gethash (p_orgnl_card_no_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                    'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 100);
            RAISE l_exp_reject_record;
      END;

      BEGIN
         l_encr_pan := fn_emaps_main (p_orgnl_card_no_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                    'Error while converting encr pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE l_exp_reject_record;
      END;

      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO l_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg_out :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 100);
            p_resp_code_out := '21';
            RETURN;
      END;

      BEGIN
         SELECT ctm_credit_debit_flag, ctm_tran_desc,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_prfl_flag
           INTO l_dr_cr_flag, l_tran_desc,
                l_txn_type,
                l_tran_type, l_prfl_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code_in
            AND ctm_delivery_channel = p_delivery_chnl_in
            AND ctm_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_resp_cde := '16';
            l_err_msg :=
                  'Transaction detail is not found in master for reversal txn '
               || p_txn_code_in
               || 'delivery channel '
               || p_delivery_chnl_in;
            RAISE l_exp_reject_record;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                  'Problem while selecting debit/credit flag '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE l_exp_reject_record;
      END;

      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_acct_no, cap_card_stat,
                cap_expry_date, cap_mbr_numb, cap_prfl_code
           INTO l_prod_code, l_card_type, l_card_acct_no, l_card_stat,
                l_expry_date, l_mbr_numb, l_prfl_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = l_hash_pan
            AND cap_mbr_numb = p_mbr_numb_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_resp_cde := '16';
            l_err_msg := 'Pan code is not defined ';
            RAISE l_exp_reject_record;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                  ' Error while selecting data from card master  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE l_exp_reject_record;
      END;
      
        ---SN Reason code description 
         
         begin
         
         select  csr_reasondesc 
         into l_reason_desc 
         from cms_spprt_reasons 
         where csr_spprt_rsncode=p_reason_code_in
         and csr_inst_code=p_inst_code_in;
          
          EXCEPTION
            WHEN OTHERS
             THEN
                p_errmsg_out := '21';
                p_resp_code_out :=
                      ' Error while selecting data from spprt reasons  '
                   || SUBSTR (SQLERRM, 1, 100);
                RAISE l_exp_reject_record;
         
         end;
       
     -- EN  Reason code description
     
     

      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
               INTO l_acct_balance, l_ledger_bal, l_acct_type
               FROM cms_acct_mast
              WHERE cam_inst_code = p_inst_code_in
                AND cam_acct_no = l_card_acct_no
         FOR UPDATE;

         p_ach_startledgerbal_out := l_ledger_bal;
         p_ach_startaccountbalance_out := l_acct_balance;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_resp_cde := '16';
            l_err_msg := 'Account not found';
            RAISE l_exp_reject_record;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                  ' Error while selecting data from acct master  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE l_exp_reject_record;
      END;

      BEGIN
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
         SELECT COUNT (1)
           INTO l_rrn_count
           FROM transactionlog
          WHERE instcode = p_inst_code_in
            AND customer_card_no = l_hash_pan
            AND rrn = p_rrn_in
            AND delivery_channel = p_delivery_chnl_in
            AND txn_code = p_txn_code_in
            AND business_date = p_tran_date_in
            AND business_time = p_tran_time_in;
ELSE
		SELECT COUNT (1)
           INTO l_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE instcode = p_inst_code_in
            AND customer_card_no = l_hash_pan
            AND rrn = p_rrn_in
            AND delivery_channel = p_delivery_chnl_in
            AND txn_code = p_txn_code_in
            AND business_date = p_tran_date_in
            AND business_time = p_tran_time_in;
END IF;			

         IF l_rrn_count > 0
         THEN
            l_resp_cde := '22';
            l_err_msg := 'Duplicate RRN found' || p_rrn_in;
            RAISE l_exp_reject_record;
         END IF;
      END;

      BEGIN
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_tran_date_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
         SELECT proxy_number, msgtype, rrn,
                delivery_channel, txn_code,
                txn_mode, response_code,
                business_date, business_time,
                NVL (TO_CHAR (total_amount, '999999999990.00'), '0.00')
                                                                 total_amount,
                NVL (TO_CHAR (amount, '999999999990.00'), '0.00') amount,
                instcode, fn_dmaps_main (customer_card_no_encr) AS cardnum,
                reversal_code, customer_acct_no,
                achfilename, rdfi, seccodes,
                impdate, processdate, effectivedate,
                tracenumber, incoming_crfileid,
                auth_id, achtrantype_id, indidnum,
                indname, companyname, companyid,
                ach_id, compentrydesc, response_id,
                customerlastname, odfi,
                currencycode, terminal_id, addcharge,
                tranfee_amt, feecode,
                add_ins_date, fee_plan,remark
           INTO l_proxy_number, l_orgnl_msgtype, l_orgnl_rrn,
                l_orgnl_delivery_channel, l_orgnl_txn_code,
                l_orgnl_txn_mode, l_orgnl_response_code,
                l_orgnl_business_date, l_orgnl_business_time,
                l_orgnl_total_amount,
                l_orgnl_amount,
                l_orgnl_instcode, l_orgnl_cardnum,
                l_orgnl_reversal_code, l_orgnl_customer_acct_no,
                l_orgnl_achfilename, l_orgnl_rdfi, l_orgnl_seccodes,
                l_orgnl_impdate, l_orgnl_processdate, l_orgnl_effectivedate,
                l_orgnl_tracenumber, l_orgnl_incoming_crfileid,
                l_orgnl_auth_id, l_orgnl_achtrantype_id, l_orgnl_indidnum,
                l_orgnl_indname, l_orgnl_companyname, l_orgnl_companyid,
                l_orgnl_ach_id, l_orgnl_compentrydesc, l_orgnl_response_id,
                l_orgnl_customerlastname, l_orgnl_odfi,
                l_orgnl_currencycode, l_orgnl_terminal_id, l_addcharge,
                l_orgnl_txn_totalfee_amt, l_orgnl_txn_feecode,
                l_add_ins_date, l_orgnl_txn_fee_plan,l_remarks
           FROM transactionlog
          WHERE instcode = p_inst_code_in
            AND rrn = p_orgnl_rrn_in
            AND business_date = p_orgnl_tran_date_in
            AND business_time = p_orgnl_tran_time_in
            AND customer_card_no = l_hash_pan
            AND (auth_id IS NULL OR auth_id = p_orgnl_auth_id_in)
            AND txn_code = p_orgnl_txn_code_in
            AND delivery_channel = p_orgnl_delivery_chnl_in
            AND response_code = '00';
      -- AND csr_achactiontaken = 'A';
ELSE
		SELECT proxy_number, msgtype, rrn,
                delivery_channel, txn_code,
                txn_mode, response_code,
                business_date, business_time,
                NVL (TO_CHAR (total_amount, '999999999990.00'), '0.00')
                                                                 total_amount,
                NVL (TO_CHAR (amount, '999999999990.00'), '0.00') amount,
                instcode, fn_dmaps_main (customer_card_no_encr) AS cardnum,
                reversal_code, customer_acct_no,
                achfilename, rdfi, seccodes,
                impdate, processdate, effectivedate,
                tracenumber, incoming_crfileid,
                auth_id, achtrantype_id, indidnum,
                indname, companyname, companyid,
                ach_id, compentrydesc, response_id,
                customerlastname, odfi,
                currencycode, terminal_id, addcharge,
                tranfee_amt, feecode,
                add_ins_date, fee_plan,remark
           INTO l_proxy_number, l_orgnl_msgtype, l_orgnl_rrn,
                l_orgnl_delivery_channel, l_orgnl_txn_code,
                l_orgnl_txn_mode, l_orgnl_response_code,
                l_orgnl_business_date, l_orgnl_business_time,
                l_orgnl_total_amount,
                l_orgnl_amount,
                l_orgnl_instcode, l_orgnl_cardnum,
                l_orgnl_reversal_code, l_orgnl_customer_acct_no,
                l_orgnl_achfilename, l_orgnl_rdfi, l_orgnl_seccodes,
                l_orgnl_impdate, l_orgnl_processdate, l_orgnl_effectivedate,
                l_orgnl_tracenumber, l_orgnl_incoming_crfileid,
                l_orgnl_auth_id, l_orgnl_achtrantype_id, l_orgnl_indidnum,
                l_orgnl_indname, l_orgnl_companyname, l_orgnl_companyid,
                l_orgnl_ach_id, l_orgnl_compentrydesc, l_orgnl_response_id,
                l_orgnl_customerlastname, l_orgnl_odfi,
                l_orgnl_currencycode, l_orgnl_terminal_id, l_addcharge,
                l_orgnl_txn_totalfee_amt, l_orgnl_txn_feecode,
                l_add_ins_date, l_orgnl_txn_fee_plan,l_remarks
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE instcode = p_inst_code_in
            AND rrn = p_orgnl_rrn_in
            AND business_date = p_orgnl_tran_date_in
            AND business_time = p_orgnl_tran_time_in
            AND customer_card_no = l_hash_pan
            AND (auth_id IS NULL OR auth_id = p_orgnl_auth_id_in)
            AND txn_code = p_orgnl_txn_code_in
            AND delivery_channel = p_orgnl_delivery_chnl_in
            AND response_code = '00';
      -- AND csr_achactiontaken = 'A';
END IF;	  
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_resp_cde := '16';
            l_err_msg :=
               'Orginal Transaction Record Not Found Or Record Already Processed.';
            RAISE l_exp_reject_record;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                  'while selecting orginal txn detail'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE l_exp_reject_record;
      END;

      BEGIN
         l_tran_date :=
            TO_DATE (   SUBSTR (TRIM (p_tran_date_in), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_tran_time_in), 1, 10),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_resp_cde := '32';
            l_err_msg :=
                  'Problem while converting transaction time '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE l_exp_reject_record;
      END;

      l_tran_amt := p_orgnl_txn_amt_in;

      BEGIN
         sp_convert_curr (p_inst_code_in,
                          p_curr_code_in,
                          p_orgnl_card_no_in,
                          l_orgnl_amount,
                          l_tran_date,
                          l_tran_amt,
                          l_card_curr,
                          l_err_msg,
						  l_prod_code,
						  l_card_type
                         );

         IF l_err_msg <> 'OK'
         THEN
            l_resp_cde := '21';
            RAISE l_exp_reject_record;
         END IF;
      EXCEPTION
         WHEN l_exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            l_resp_cde := '89';
            l_err_msg :=
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
            RAISE l_exp_reject_record;
      END;

      BEGIN
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
         SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
                csl_merchant_state
           INTO l_txn_narration, l_txn_merchname, l_txn_merchcity,
                l_txn_merchstate
           FROM cms_statements_log
          WHERE csl_business_date = l_orgnl_business_date
            AND csl_business_time = l_orgnl_business_time
            AND csl_rrn = l_orgnl_rrn
            AND csl_delivery_channel = l_orgnl_delivery_channel
            AND csl_txn_code = l_orgnl_txn_code
            AND csl_pan_no = p_orgnl_card_no_in
            AND csl_inst_code = p_inst_code_in
            AND txn_fee_flag = 'N';
ELSE
		SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
                csl_merchant_state
           INTO l_txn_narration, l_txn_merchname, l_txn_merchcity,
                l_txn_merchstate
           FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
          WHERE csl_business_date = l_orgnl_business_date
            AND csl_business_time = l_orgnl_business_time
            AND csl_rrn = l_orgnl_rrn
            AND csl_delivery_channel = l_orgnl_delivery_channel
            AND csl_txn_code = l_orgnl_txn_code
            AND csl_pan_no = p_orgnl_card_no_in
            AND csl_inst_code = p_inst_code_in
            AND txn_fee_flag = 'N';
END IF;			
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_txn_narration := l_tran_desc;
         WHEN OTHERS
         THEN
            l_txn_narration := l_tran_desc;
      END;


          l_upd_amt        := l_acct_balance - l_tran_amt;

      IF l_upd_amt < 0 THEN
            l_resp_cde := '15';
            l_err_msg := 'Insufficient Balance ';
            RAISE l_exp_reject_record;
      END IF;


      BEGIN
         sp_reverse_card_amount (p_inst_code_in,
                                 l_func_code,
                                 p_rrn_in,
                                 p_delivery_chnl_in,
                                 NULL,
                                 NULL,
                                 p_txn_code_in,
                                 l_tran_date,
                                 p_txn_mode_in,
                                 p_orgnl_card_no_in,
                                 l_tran_amt,
                                 l_orgnl_rrn,
                                 l_card_acct_no,
                                 p_tran_date_in,
                                 p_tran_time_in,
                                 l_auth_id,
                                 l_txn_narration,
                                 l_orgnl_business_date,
                                 l_orgnl_business_time,
                                 l_txn_merchname,
                                 l_txn_merchcity,
                                 l_txn_merchstate,
                                 l_resp_cde,
                                 l_err_msg
                                );

         IF l_resp_cde <> '00' OR l_err_msg <> 'OK'
         THEN
            RAISE l_exp_reject_record;
         END IF;
      EXCEPTION
         WHEN l_exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
               'Error while reversing the amount '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE l_exp_reject_record;
      END;

      --En reverse the amount
      IF l_orgnl_txn_totalfee_amt > 0 OR l_orgnl_txn_feecode IS NOT NULL
      THEN
         BEGIN
            SELECT cfm_feecap_flag, cfm_fee_amt
              INTO l_feecap_flag, l_orgnl_fee_amt
              FROM cms_fee_mast
             WHERE cfm_inst_code = p_inst_code_in
               AND cfm_fee_code = l_orgnl_txn_feecode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_feecap_flag := '';
            WHEN OTHERS
            THEN
               l_err_msg :=
                    'Error in feecap flag fetch ' || SUBSTR (SQLERRM, 1, 200);
               RAISE l_exp_reject_record;
         END;

         BEGIN
            FOR l_row_idx IN l_cur_stmnts_log
            LOOP
               l_orgnl_tranfee_amt := l_row_idx.csl_trans_amount;

               IF l_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_revcapcheck (p_inst_code_in,
                                               l_card_acct_no,
                                               l_orgnl_business_date,
                                               l_orgnl_tranfee_amt,
                                               l_orgnl_fee_amt,
                                               l_orgnl_txn_fee_plan,
                                               l_orgnl_txn_feecode,
                                               l_err_msg
                                              );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_resp_cde := '21';
                        l_err_msg :=
                              'Error while reversing the fee Cap amount '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE l_exp_reject_record;
                  END;
               END IF;

               BEGIN
                  sp_reverse_fee_amount (p_inst_code_in,
                                         p_rrn_in,
                                         p_delivery_chnl_in,
                                         NULL,
                                         NULL,
                                         p_txn_code_in,
                                         l_tran_date,
                                         p_txn_mode_in,
                                         l_orgnl_tranfee_amt,
                                         p_orgnl_card_no_in,
                                         l_orgnl_txn_feecode,
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
                                         l_orgnl_rrn,
                                         l_card_acct_no,
                                         p_tran_date_in,
                                         p_tran_time_in,
                                         l_auth_id,
                                         l_row_idx.csl_trans_narrration,
                                         l_row_idx.csl_merchant_name,
                                         l_row_idx.csl_merchant_city,
                                         l_row_idx.csl_merchant_state,
                                         l_resp_cde,
                                         l_err_msg
                                        );
                  l_fee_narration := l_row_idx.csl_trans_narrration;

                  IF l_resp_cde <> '00' OR l_err_msg <> 'OK'
                  THEN
                     RAISE l_exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN l_exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_err_msg :=
                           'Error while reversing the fee amount '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE l_exp_reject_record;
               END;
            END LOOP;
         EXCEPTION
          WHEN l_exp_reject_record
            THEN
            RAISE;
            WHEN NO_DATA_FOUND
            THEN
               l_fee_narration := NULL;
            WHEN OTHERS
            THEN
               l_fee_narration := NULL;
         END;
      END IF;

      IF l_fee_narration IS NULL
      THEN
         IF l_feecap_flag = 'Y'
         THEN
            BEGIN
               sp_tran_fees_revcapcheck (p_inst_code_in,
                                         l_card_acct_no,
                                         l_orgnl_business_date,
                                         l_orgnl_tranfee_amt,
                                         l_orgnl_fee_amt,
                                         l_orgnl_txn_fee_plan,
                                         l_orgnl_txn_feecode,
                                         l_err_msg
                                        );
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                        'Error while reversing the fee Cap amount '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE l_exp_reject_record;
            END;
         END IF;

         BEGIN
            sp_reverse_fee_amount (p_inst_code_in,
                                   p_rrn_in,
                                   p_delivery_chnl_in,
                                   NULL,
                                   NULL,
                                   p_txn_code_in,
                                   l_tran_date,
                                   p_txn_mode_in,
                                   l_orgnl_txn_totalfee_amt,
                                   p_orgnl_card_no_in,
                                   l_orgnl_txn_feecode,
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
                                   l_orgnl_rrn,
                                   l_card_acct_no,
                                   p_tran_date_in,
                                   p_tran_time_in,
                                   l_auth_id,
                                   l_fee_narration,
                                   l_fee_merchname,
                                   l_fee_merchcity,
                                   l_fee_merchstate,
                                   l_resp_cde,
                                   l_err_msg
                                  );

            IF l_resp_cde <> '00' OR l_err_msg <> 'OK'
            THEN
               RAISE l_exp_reject_record;
            END IF;
         EXCEPTION
            WHEN l_exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while reversing the fee amount '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE l_exp_reject_record;
         END;
      END IF;

      --En reverse the fee
      IF l_txn_narration IS NULL
      THEN
         IF TRIM (l_tran_desc) IS NOT NULL
         THEN
            l_txn_narration := l_tran_desc || '/';
         END IF;

         IF TRIM (l_txn_merchname) IS NOT NULL
         THEN
            l_txn_narration := l_txn_narration || l_txn_merchname || '/';
         END IF;

         IF TRIM (l_txn_merchcity) IS NOT NULL
         THEN
            l_txn_narration := l_txn_narration || l_txn_merchcity || '/';
         END IF;

         IF TRIM (p_tran_date_in) IS NOT NULL
         THEN
            l_txn_narration := l_txn_narration || p_tran_date_in || '/';
         END IF;

         IF TRIM (l_auth_id) IS NOT NULL
         THEN
            l_txn_narration := l_txn_narration || l_auth_id;
         END IF;
      END IF;


      l_resp_cde := '1';

      BEGIN
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
         UPDATE cms_statements_log
            SET csl_prod_code = l_prod_code,
                csl_card_type=l_card_type,
                csl_acct_type = l_acct_type,
                csl_time_stamp = l_timestamp
          WHERE csl_inst_code = p_inst_code_in
            AND csl_pan_no = l_hash_pan
            AND csl_rrn = p_rrn_in
            AND csl_txn_code = p_txn_code_in
            AND csl_delivery_channel = p_delivery_chnl_in
            AND csl_business_date = p_tran_date_in
            AND csl_business_time = p_tran_time_in;
ELSE
		UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
            SET csl_prod_code = l_prod_code,
                csl_card_type=l_card_type,
                csl_acct_type = l_acct_type,
                csl_time_stamp = l_timestamp
          WHERE csl_inst_code = p_inst_code_in
            AND csl_pan_no = l_hash_pan
            AND csl_rrn = p_rrn_in
            AND csl_txn_code = p_txn_code_in
            AND csl_delivery_channel = p_delivery_chnl_in
            AND csl_business_date = p_tran_date_in
            AND csl_business_time = p_tran_time_in;
END IF;			

         IF SQL%ROWCOUNT = 0
         THEN
            NULL;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                  'Error while updating timestamp in statementlog-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE l_exp_reject_record;
      END;

      BEGIN
         IF     l_add_ins_date IS NOT NULL
            AND l_prfl_code IS NOT NULL
            AND l_prfl_flag = 'Y'
         THEN
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
                                                      p_delivery_chnl_in,
                                                      l_hash_pan,
                                                      l_add_ins_date,
                                                      l_resp_cde,
                                                      l_err_msg
                                                     );


         IF l_err_msg <> 'OK'
         THEN
--            l_err_msg := l_err_msg;
            RAISE l_exp_reject_record;
         END IF;
           END IF;
      EXCEPTION
         WHEN l_exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                  'Error from Limit count reveer Process '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE l_exp_reject_record;
      END;



    BEGIN				--- Added for VMS-3412
      IF p_r17_response_in = 'Y'
      THEN      	   
      SELECT cms_resp_desc
        INTO l_resp_desc
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code_in
         AND cms_delivery_channel = '11'
         AND cms_response_id = 266;
      END IF;
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_tran_date_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
         UPDATE transactionlog
            SET csr_achactiontaken = 'R',
                processtype = 'N',
                remark = p_remark_in,
                response_code=decode(p_r17_response_in,'Y','R17','224'),
                response_id=decode(p_r17_response_in,'Y','266','224'),
                gl_eod_flag='V',
                error_msg = DECODE(p_r17_response_in,'Y',l_resp_desc,error_msg) 
          WHERE instcode = p_inst_code_in
            AND rrn = p_orgnl_rrn_in
            AND business_date = p_orgnl_tran_date_in
            AND business_time = p_orgnl_tran_time_in
            AND customer_card_no = l_hash_pan
            AND (auth_id IS NULL OR auth_id = p_orgnl_auth_id_in)
            AND txn_code = p_orgnl_txn_code_in
            AND delivery_channel = p_orgnl_delivery_chnl_in;
ELSE
		   UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            SET csr_achactiontaken = 'R',
                processtype = 'N',
                remark = p_remark_in,
                response_code=decode(p_r17_response_in,'Y','R17','224'),
                response_id=decode(p_r17_response_in,'Y','266','224'),
                gl_eod_flag='V',
                error_msg = DECODE(p_r17_response_in,'Y',l_resp_desc,error_msg) 
          WHERE instcode = p_inst_code_in
            AND rrn = p_orgnl_rrn_in
            AND business_date = p_orgnl_tran_date_in
            AND business_time = p_orgnl_tran_time_in
            AND customer_card_no = l_hash_pan
            AND (auth_id IS NULL OR auth_id = p_orgnl_auth_id_in)
            AND txn_code = p_orgnl_txn_code_in
            AND delivery_channel = p_orgnl_delivery_chnl_in;
END IF;			

         IF SQL%ROWCOUNT = 0
         THEN
            l_resp_cde := '16';
            l_err_msg := 'Orignal txn not updated';
            RAISE l_exp_reject_record;
         END IF;
         
         IF p_r17_response_in = 'Y' --- Added for VMS-3412
         THEN
		 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_tran_date_in), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
            UPDATE CMS_TRANSACTION_LOG_DTL 
               SET ctd_process_msg = l_resp_desc
             WHERE ctd_inst_code = p_inst_code_in
               AND ctd_rrn = p_orgnl_rrn_in 
               AND ctd_business_date = p_orgnl_tran_date_in
               AND ctd_business_time = p_orgnl_tran_time_in
               AND ctd_customer_card_no = l_hash_pan
               AND ctd_txn_code = p_orgnl_txn_code_in
               AND ctd_delivery_channel = p_orgnl_delivery_chnl_in;
ELSE
			UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991 
               SET ctd_process_msg = l_resp_desc
             WHERE ctd_inst_code = p_inst_code_in
               AND ctd_rrn = p_orgnl_rrn_in 
               AND ctd_business_date = p_orgnl_tran_date_in
               AND ctd_business_time = p_orgnl_tran_time_in
               AND ctd_customer_card_no = l_hash_pan
               AND ctd_txn_code = p_orgnl_txn_code_in
               AND ctd_delivery_channel = p_orgnl_delivery_chnl_in;
END IF;			   
           END IF;
      EXCEPTION
         WHEN l_exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                  'problem occured while updating orignal txn '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE l_exp_reject_record;
      END;

if l_addcharge is not null then
BEGIN
    UPDATE vms_achexc_appd_acc
      SET vaa_enable_flag = 'N',
          vaa_lupd_user = p_ins_user_in,
          vaa_lupd_date = SYSDATE
        WHERE     vaa_acct_no = l_card_acct_no
          AND vaa_company_name = UPPER (TRIM (l_orgnl_companyname))
          AND vaa_resp_code = l_addcharge;
    EXCEPTION
   WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg :='Excp while achappr resp flag updation-' || SUBSTR (SQLERRM, 1, 200);
       RAISE l_exp_reject_record;
END;
end if;
    IF l_remarks IS NOT NULL THEN
      l_remarks:=l_remarks || '/' || p_remark_in;
    ELSE
        l_remarks:=p_remark_in;

    END IF;

   EXCEPTION
      WHEN l_exp_reject_record
      THEN
         ROLLBACK TO l_auth_savepoint;
      WHEN OTHERS
      THEN
         l_resp_cde := '21';
         l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
         ROLLBACK TO l_auth_savepoint;
   END;



   --Sn Get responce code fomr master
   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code_out
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code_in
         AND cms_delivery_channel = p_delivery_chnl_in
         AND cms_response_id = l_resp_cde;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_msg :=
               'Problem while selecting data from response master '
            || l_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
   END;

   --En Get responce code fomr master
   IF l_prod_code IS NULL
   THEN
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
           INTO l_card_stat, l_prod_code, l_card_type, l_card_acct_no
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code_in
            AND cap_pan_code = gethash (p_orgnl_card_no_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO l_acct_balance, l_ledger_bal, l_acct_type
        FROM cms_acct_mast
       WHERE cam_acct_no = l_card_acct_no AND cam_inst_code = p_inst_code_in;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_acct_balance := 0;
         l_ledger_bal := 0;
   END;

   IF l_dr_cr_flag IS NULL
   THEN
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag
           INTO l_dr_cr_flag,
                l_txn_type,
                l_tran_type, l_tran_desc, l_prfl_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code_in
            AND ctm_delivery_channel = p_delivery_chnl_in
            AND ctm_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;

   --Sn Inserting data in transactionlog
   BEGIN
      sp_log_txnlog (p_inst_code_in,
                     p_msg_type_in,
                     p_rrn_in,
                     p_delivery_chnl_in,
                     p_txn_code_in,
                     l_txn_type,
                     p_txn_mode_in,
                     p_tran_date_in,
                     p_tran_time_in,
                     p_revrsl_code_in,
                     l_hash_pan,
                     l_encr_pan,
                     l_err_msg,
                     NULL,
                     l_card_stat,
                     l_tran_desc,
                     NULL,
                     NULL,
                     l_timestamp,
                     l_card_acct_no,
                     l_prod_code,
                     l_card_type,
                     l_dr_cr_flag,
                     l_acct_balance,
                     l_ledger_bal,
                     l_acct_type,
                     l_proxy_number,
                     l_auth_id,
                     l_tran_amt,
                     l_tran_amt + NVL (l_orgnl_txn_totalfee_amt, 0),
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     l_resp_cde,
                     p_resp_code_out,
                     p_curr_code_in,
                     l_err_msg,
                     NULL,
                     NULL,
                     SUBSTR(l_remarks,1,1000),
                     l_reason_desc,
                     p_reason_code_in
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '89';
         l_err_msg :=
               'Exception while inserting to transaction log '
            || SQLCODE
            || '---'
            || SQLERRM;
   END;

   --En Inserting data in transactionlog
   --Sn Inserting data in transactionlog dtl
   BEGIN
      sp_log_txnlogdetl (p_inst_code_in,
                         p_msg_type_in,
                         p_rrn_in,
                         p_delivery_chnl_in,
                         p_txn_code_in,
                         l_txn_type,
                         p_txn_mode_in,
                         p_tran_date_in,
                         p_tran_time_in,
                         l_hash_pan,
                         l_encr_pan,
                         l_err_msg,
                         l_card_acct_no,
                         l_auth_id,
                         l_tran_amt,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         p_resp_code_out,
                         NULL,
                         NULL,
                         NULL,
                         l_logdtl_resp
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '89';
   END;

   p_errmsg_out := l_err_msg;
   p_ach_endledgerbal_out := l_ledger_bal;
   p_ach_endaccountbalance_out := l_acct_balance;
   p_ach_auth_id_out := l_auth_id;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code_out := '69';
      p_errmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
    
  
END VMSUSACH;
/
show error;