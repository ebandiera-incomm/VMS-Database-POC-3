create or replace
PROCEDURE        VMSCMS.SP_ACH_REJECTTXN_CSR (
   prm_inst_code                 IN       NUMBER,
   prm_revrsl_code               IN       VARCHAR2,
   prm_msg_type                  IN       VARCHAR2,
   prm_rrn                       IN       VARCHAR2,
   prm_stan                      IN       VARCHAR2,
   prm_tran_date                 IN       VARCHAR2,
   prm_tran_time                 IN       VARCHAR2,
   prm_txn_amt                   IN       VARCHAR2,
   prm_txn_code                  IN       VARCHAR2,
   prm_delivery_chnl             IN       VARCHAR2,
   prm_txn_mode                  IN       VARCHAR2,
   prm_mbr_numb                  IN       VARCHAR2,
   prm_orgnl_rrn                 IN       VARCHAR2,
   prm_orgnl_card_no             IN       VARCHAR2,
   prm_orgnl_stan                IN       VARCHAR2,
   prm_orgnl_tran_date           IN       VARCHAR2,
   prm_orgnl_tran_time           IN       VARCHAR2,
   prm_orgnl_txn_amt             IN       VARCHAR2,
   prm_orgnl_txn_code            IN       VARCHAR2,
   prm_orgnl_delivery_chnl       IN       VARCHAR2,
   prm_orgnl_auth_id             IN       VARCHAR2,
   prm_curr_code               IN       VARCHAR2,
   prm_remark                    IN       VARCHAR2,
   prm_reason_desc               IN       VARCHAR2,
   --prm_approve_rej               IN       VARCHAR2,
  -- prm_ipaddress                 IN       VARCHAR2,
   prm_ins_user                  IN       NUMBER,
   prm_resp_code                 OUT      VARCHAR2,
   prm_errmsg                    OUT      VARCHAR2,
   prm_ach_startledgerbal        OUT      VARCHAR2,
   prm_ach_startaccountbalance   OUT      VARCHAR2,
   prm_ach_endledgerbal          OUT      VARCHAR2,
   prm_ach_endaccountbalance     OUT      VARCHAR2,
   prm_ach_auth_id               OUT      VARCHAR2
)
IS
/******************************************************************************************
     * Created Date     : 23/July/2015
     * Created By       : Abdul Hameed M.A
     * Purpose          : Reject the Approved ACH transaction  through CSR
     * Reviewer         : Spankaj
     * Reviewed Date    : 23/July/2015
     * Build Number     : VMSGPRHOST3.0.4

 ********************************************************************************************/
   v_resp_cde                  VARCHAR2 (2);
   v_err_msg                   VARCHAR2 (300);
   v_acct_balance              cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal                cms_acct_mast.cam_ledger_bal%TYPE;
   v_auth_id                   VARCHAR2 (6);
   v_rrn_count                 NUMBER (3);
   v_hash_pan                  cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                  cms_appl_pan.cap_pan_code_encr%TYPE;
   v_card_acct_no              cms_appl_pan.cap_acct_no%TYPE;
   exp_reject_record           EXCEPTION;
   v_dr_cr_flag                cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_proxy_number              transactionlog.proxy_number%TYPE;
   v_tran_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
   v_card_type                 cms_appl_pan.cap_card_type%TYPE;
   v_prod_code                 cms_appl_pan.cap_prod_code%TYPE;
   v_card_stat                 cms_appl_pan.cap_card_stat%TYPE;
   v_expry_date                cms_appl_pan.cap_expry_date%TYPE;
   v_mbr_numb                  cms_appl_pan.cap_mbr_numb%TYPE;
   v_orgnl_terminal_id         transactionlog.terminal_id%TYPE;
   v_orgnl_msgtype             transactionlog.msgtype%TYPE;
   v_orgnl_rrn                 transactionlog.rrn%TYPE;
   v_orgnl_delivery_channel    transactionlog.delivery_channel%TYPE;
   v_orgnl_txn_code            transactionlog.txn_code%TYPE;
   v_orgnl_txn_mode            transactionlog.txn_mode%TYPE;
   v_orgnl_response_code       transactionlog.response_code%TYPE;
   v_orgnl_business_date       transactionlog.business_date%TYPE;
   v_orgnl_business_time       transactionlog.business_time%TYPE;
   v_orgnl_total_amount        transactionlog.total_amount%TYPE;
   v_orgnl_amount              transactionlog.amount%TYPE;
   v_orgnl_instcode            transactionlog.instcode%TYPE;
   v_orgnl_cardnum             VARCHAR2 (20);
   v_orgnl_reversal_code       transactionlog.reversal_code%TYPE;
   v_orgnl_customer_acct_no    transactionlog.customer_acct_no%TYPE;
   v_orgnl_achfilename         transactionlog.achfilename%TYPE;
   v_orgnl_rdfi                transactionlog.rdfi%TYPE;
   v_orgnl_seccodes            transactionlog.seccodes%TYPE;
   v_orgnl_impdate             transactionlog.impdate%TYPE;
   v_orgnl_processdate         transactionlog.processdate%TYPE;
   v_orgnl_effectivedate       transactionlog.effectivedate%TYPE;
   v_orgnl_tracenumber         transactionlog.tracenumber%TYPE;
   v_orgnl_incoming_crfileid   transactionlog.incoming_crfileid%TYPE;
   v_orgnl_auth_id             transactionlog.auth_id%TYPE;
   v_orgnl_achtrantype_id      transactionlog.achtrantype_id%TYPE;
   v_orgnl_indidnum            transactionlog.indidnum%TYPE;
   v_orgnl_indname             transactionlog.indname%TYPE;
   v_orgnl_companyname         transactionlog.companyname%TYPE;
   v_orgnl_companyid           transactionlog.companyid%TYPE;
   v_orgnl_ach_id              transactionlog.ach_id%TYPE;
   v_orgnl_compentrydesc       transactionlog.compentrydesc%TYPE;
   v_orgnl_response_id         transactionlog.response_id%TYPE;
   v_orgnl_customerlastname    transactionlog.customerlastname%TYPE;
   v_orgnl_odfi                transactionlog.odfi%TYPE;
   v_orgnl_currencycode        transactionlog.currencycode%TYPE;
   v_addcharge                 transactionlog.addcharge%TYPE;
   v_timestamp                 TIMESTAMP ( 3 );
   v_txn_type                  transactionlog.txn_type%TYPE;
   v_tran_type                 cms_transaction_mast.ctm_tran_type%TYPE;
   v_txn_narration             cms_statements_log.csl_trans_narrration%TYPE;
   v_fee_narration             cms_statements_log.csl_trans_narrration%TYPE;
   v_txn_merchname             cms_statements_log.csl_merchant_name%TYPE;
   v_fee_merchname             cms_statements_log.csl_merchant_name%TYPE;
   v_txn_merchcity             cms_statements_log.csl_merchant_city%TYPE;
   v_fee_merchcity             cms_statements_log.csl_merchant_city%TYPE;
   v_txn_merchstate            cms_statements_log.csl_merchant_state%TYPE;
   v_fee_merchstate            cms_statements_log.csl_merchant_state%TYPE;
   v_tran_date                 DATE;
   v_tran_amt                  NUMBER;
   v_card_curr                 VARCHAR2 (5);
   v_func_code                 cms_func_mast.cfm_func_code%TYPE;
   v_orgnl_txn_totalfee_amt    transactionlog.tranfee_amt%TYPE;
   v_orgnl_txn_feecode         cms_fee_mast.cfm_fee_code%TYPE;
   v_feecap_flag               VARCHAR2 (1);
   v_orgnl_fee_amt             cms_fee_mast.cfm_fee_amt%TYPE;
   v_orgnl_tranfee_amt         transactionlog.tranfee_amt%TYPE;
   v_add_ins_date              transactionlog.add_ins_date%TYPE;
   v_orgnl_txn_fee_plan        transactionlog.fee_plan%TYPE;
   v_orgnl_servicetax_amt      transactionlog.servicetax_amt%TYPE;
   v_orgnl_cess_amt            transactionlog.cess_amt%TYPE;
   v_orgnl_tranfee_cr_acctno   transactionlog.tranfee_cr_acctno%TYPE;
   v_orgnl_tranfee_dr_acctno   transactionlog.tranfee_dr_acctno%TYPE;
   v_orgnl_st_calc_flag        transactionlog.tran_st_calc_flag%TYPE;
   v_orgnl_cess_calc_flag      transactionlog.tran_cess_calc_flag%TYPE;
   v_orgnl_st_cr_acctno        transactionlog.tran_st_cr_acctno%TYPE;
   v_orgnl_st_dr_acctno        transactionlog.tran_st_dr_acctno%TYPE;
   v_orgnl_cess_cr_acctno      transactionlog.tran_cess_cr_acctno%TYPE;
   v_orgnl_cess_dr_acctno      transactionlog.tran_cess_dr_acctno%TYPE;
   v_acct_type                 cms_acct_mast.cam_type_code%TYPE;
   v_prfl_code                 cms_appl_pan.cap_prfl_code%TYPE;
   v_prfl_flag                 cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_logdtl_resp               VARCHAR2 (500);
   v_auth_savepoint            NUMBER                               DEFAULT 0;
   v_remarks                   VARCHAR2(2000);
   V_UPD_AMT            NUMBER;

   CURSOR feereverse
   IS
      SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
             csl_merchant_state, csl_trans_amount
        FROM cms_statements_log
       WHERE csl_business_date = prm_orgnl_tran_date
         AND csl_rrn = prm_orgnl_rrn
         AND csl_delivery_channel = prm_orgnl_delivery_chnl
         AND csl_txn_code = prm_orgnl_txn_code
         AND csl_pan_no = v_hash_pan
         AND csl_inst_code = prm_inst_code
         AND txn_fee_flag = 'Y';
BEGIN
   v_resp_cde := '1';
   v_timestamp := SYSTIMESTAMP;

   BEGIN
      SAVEPOINT v_auth_savepoint;
      v_err_msg := 'OK';

      BEGIN
         v_hash_pan := gethash (prm_orgnl_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_encr_pan := fn_emaps_main (prm_orgnl_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 100);
            prm_resp_code := '21';
            RETURN;
      END;

      BEGIN
         SELECT ctm_credit_debit_flag, ctm_tran_desc,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_prfl_flag
           INTO v_dr_cr_flag, v_tran_desc,
                v_txn_type,
                v_tran_type, v_prfl_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_txn_code
            AND ctm_delivery_channel = prm_delivery_chnl
            AND ctm_inst_code = prm_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=
                  'Transaction detail is not found in master for reversal txn '
               || prm_txn_code
               || 'delivery channel '
               || prm_delivery_chnl;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting debit/credit flag '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_acct_no, cap_card_stat,
                cap_expry_date, cap_mbr_numb, cap_prfl_code
           INTO v_prod_code, v_card_type, v_card_acct_no, v_card_stat,
                v_expry_date, v_mbr_numb, v_prfl_code
           FROM cms_appl_pan
          WHERE cap_inst_code = prm_inst_code
            AND cap_pan_code = v_hash_pan
            AND cap_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Pan code is not defined ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  ' Error while selecting data from card master  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
               INTO v_acct_balance, v_ledger_bal, v_acct_type
               FROM cms_acct_mast
              WHERE cam_inst_code = prm_inst_code
                AND cam_acct_no = v_card_acct_no
         FOR UPDATE;

         prm_ach_startledgerbal := v_ledger_bal;
         prm_ach_startaccountbalance := v_acct_balance;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Account not found';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  ' Error while selecting data from acct master  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE instcode = prm_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND delivery_channel = prm_delivery_chnl
            AND txn_code = prm_txn_code
            AND business_date = prm_tran_date
            AND business_time = prm_tran_time;

         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_err_msg := 'Duplicate RRN found' || prm_rrn;
            RAISE exp_reject_record;
         END IF;
      END;

      BEGIN
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
           INTO v_proxy_number, v_orgnl_msgtype, v_orgnl_rrn,
                v_orgnl_delivery_channel, v_orgnl_txn_code,
                v_orgnl_txn_mode, v_orgnl_response_code,
                v_orgnl_business_date, v_orgnl_business_time,
                v_orgnl_total_amount,
                v_orgnl_amount,
                v_orgnl_instcode, v_orgnl_cardnum,
                v_orgnl_reversal_code, v_orgnl_customer_acct_no,
                v_orgnl_achfilename, v_orgnl_rdfi, v_orgnl_seccodes,
                v_orgnl_impdate, v_orgnl_processdate, v_orgnl_effectivedate,
                v_orgnl_tracenumber, v_orgnl_incoming_crfileid,
                v_orgnl_auth_id, v_orgnl_achtrantype_id, v_orgnl_indidnum,
                v_orgnl_indname, v_orgnl_companyname, v_orgnl_companyid,
                v_orgnl_ach_id, v_orgnl_compentrydesc, v_orgnl_response_id,
                v_orgnl_customerlastname, v_orgnl_odfi,
                v_orgnl_currencycode, v_orgnl_terminal_id, v_addcharge,
                v_orgnl_txn_totalfee_amt, v_orgnl_txn_feecode,
                v_add_ins_date, v_orgnl_txn_fee_plan,v_remarks
           FROM transactionlog
          WHERE instcode = prm_inst_code
            AND rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date
            AND business_time = prm_orgnl_tran_time
            AND customer_card_no = v_hash_pan
            AND (auth_id IS NULL OR auth_id = prm_orgnl_auth_id)
            AND txn_code = prm_orgnl_txn_code
            AND delivery_channel = prm_orgnl_delivery_chnl
            AND response_code = '00';
      -- AND csr_achactiontaken = 'A';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=
               'Orginal Transaction Record Not Found Or Record Already Processed.';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'while selecting orginal txn detail'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_tran_date :=
            TO_DATE (   SUBSTR (TRIM (prm_tran_date), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (prm_tran_time), 1, 10),
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

      v_tran_amt := prm_orgnl_txn_amt;

      BEGIN
         sp_convert_curr (prm_inst_code,
                          prm_curr_code,
                          prm_orgnl_card_no,
                          v_orgnl_amount,
                          v_tran_date,
                          v_tran_amt,
                          v_card_curr,
                          v_err_msg
                         );

         IF v_err_msg <> 'OK'
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
            v_resp_cde := '89';                    
            v_err_msg :=
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
                csl_merchant_state
           INTO v_txn_narration, v_txn_merchname, v_txn_merchcity,
                v_txn_merchstate
           FROM cms_statements_log
          WHERE csl_business_date = v_orgnl_business_date
            AND csl_business_time = v_orgnl_business_time
            AND csl_rrn = v_orgnl_rrn
            AND csl_delivery_channel = v_orgnl_delivery_channel
            AND csl_txn_code = v_orgnl_txn_code
            AND csl_pan_no = prm_orgnl_card_no
            AND csl_inst_code = prm_inst_code
            AND txn_fee_flag = 'N';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_txn_narration := v_tran_desc;
         WHEN OTHERS
         THEN
            v_txn_narration := v_tran_desc;
      END;
      
     
          V_UPD_AMT        := V_ACCT_BALANCE - v_tran_amt;
          
      IF V_UPD_AMT < 0 THEN
            v_resp_cde := '15';                    
            v_err_msg := 'Insufficient Balance '; 
            RAISE exp_reject_record;
      END IF;
      
      
      BEGIN
         sp_reverse_card_amount (prm_inst_code,
                                 v_func_code,
                                 prm_rrn,
                                 prm_delivery_chnl,
                                 NULL,
                                 NULL,
                                 prm_txn_code,
                                 v_tran_date,
                                 prm_txn_mode,
                                 prm_orgnl_card_no,
                                 v_tran_amt,
                                 v_orgnl_rrn,
                                 v_card_acct_no,
                                 prm_tran_date,
                                 prm_tran_time,
                                 v_auth_id,
                                 v_txn_narration,
                                 v_orgnl_business_date,
                                 v_orgnl_business_time,
                                 v_txn_merchname,
                                 v_txn_merchcity,
                                 v_txn_merchstate,
                                 v_resp_cde,
                                 v_err_msg
                                );

         IF v_resp_cde <> '00' OR v_err_msg <> 'OK'
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
               'Error while reversing the amount '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En reverse the amount
      IF v_orgnl_txn_totalfee_amt > 0 OR v_orgnl_txn_feecode IS NOT NULL
      THEN
         BEGIN
            SELECT cfm_feecap_flag, cfm_fee_amt
              INTO v_feecap_flag, v_orgnl_fee_amt
              FROM cms_fee_mast
             WHERE cfm_inst_code = prm_inst_code
               AND cfm_fee_code = v_orgnl_txn_feecode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_feecap_flag := '';
            WHEN OTHERS
            THEN
               v_err_msg :=
                    'Error in feecap flag fetch ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            FOR c1 IN feereverse
            LOOP
               v_orgnl_tranfee_amt := c1.csl_trans_amount;

               IF v_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_revcapcheck (prm_inst_code,
                                               v_card_acct_no,
                                               v_orgnl_business_date,
                                               v_orgnl_tranfee_amt,
                                               v_orgnl_fee_amt,
                                               v_orgnl_txn_fee_plan,
                                               v_orgnl_txn_feecode,
                                               v_err_msg
                                              );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_cde := '21';
                        v_err_msg :=
                              'Error while reversing the fee Cap amount '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;
               END IF;

               BEGIN
                  sp_reverse_fee_amount (prm_inst_code,
                                         prm_rrn,
                                         prm_delivery_chnl,
                                         NULL,
                                         NULL,
                                         prm_txn_code,
                                         v_tran_date,
                                         prm_txn_mode,
                                         v_orgnl_tranfee_amt,
                                         prm_orgnl_card_no,
                                         v_orgnl_txn_feecode,
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
                                         v_orgnl_rrn,
                                         v_card_acct_no,
                                         prm_tran_date,
                                         prm_tran_time,
                                         v_auth_id,
                                         c1.csl_trans_narrration,
                                         c1.csl_merchant_name,
                                         c1.csl_merchant_city,
                                         c1.csl_merchant_state,
                                         v_resp_cde,
                                         v_err_msg
                                        );
                  v_fee_narration := c1.csl_trans_narrration;

                  IF v_resp_cde <> '00' OR v_err_msg <> 'OK'
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
                           'Error while reversing the fee amount '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END LOOP;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_fee_narration := NULL;
            WHEN OTHERS
            THEN
               v_fee_narration := NULL;
         END;
      END IF;

      IF v_fee_narration IS NULL
      THEN
         IF v_feecap_flag = 'Y'
         THEN
            BEGIN
               sp_tran_fees_revcapcheck (prm_inst_code,
                                         v_card_acct_no,
                                         v_orgnl_business_date,
                                         v_orgnl_tranfee_amt,
                                         v_orgnl_fee_amt,
                                         v_orgnl_txn_fee_plan,
                                         v_orgnl_txn_feecode,
                                         v_err_msg
                                        );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Error while reversing the fee Cap amount '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

         BEGIN
            sp_reverse_fee_amount (prm_inst_code,
                                   prm_rrn,
                                   prm_delivery_chnl,
                                   NULL,
                                   NULL,
                                   prm_txn_code,
                                   v_tran_date,
                                   prm_txn_mode,
                                   v_orgnl_txn_totalfee_amt,
                                   prm_orgnl_card_no,
                                   v_orgnl_txn_feecode,
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
                                   v_orgnl_rrn,
                                   v_card_acct_no,
                                   prm_tran_date,
                                   prm_tran_time,
                                   v_auth_id,
                                   v_fee_narration,
                                   v_fee_merchname,
                                   v_fee_merchcity,
                                   v_fee_merchstate,
                                   v_resp_cde,
                                   v_err_msg
                                  );

            IF v_resp_cde <> '00' OR v_err_msg <> 'OK'
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
                     'Error while reversing the fee amount '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      --En reverse the fee
      IF v_txn_narration IS NULL
      THEN
         IF TRIM (v_tran_desc) IS NOT NULL
         THEN
            v_txn_narration := v_tran_desc || '/';
         END IF;

         IF TRIM (v_txn_merchname) IS NOT NULL
         THEN
            v_txn_narration := v_txn_narration || v_txn_merchname || '/';
         END IF;

         IF TRIM (v_txn_merchcity) IS NOT NULL
         THEN
            v_txn_narration := v_txn_narration || v_txn_merchcity || '/';
         END IF;

         IF TRIM (prm_tran_date) IS NOT NULL
         THEN
            v_txn_narration := v_txn_narration || prm_tran_date || '/';
         END IF;

         IF TRIM (v_auth_id) IS NOT NULL
         THEN
            v_txn_narration := v_txn_narration || v_auth_id;
         END IF;
      END IF;

     
      v_resp_cde := '1';

      BEGIN
         UPDATE cms_statements_log
            SET csl_prod_code = v_prod_code,
                csl_acct_type = v_acct_type,
                csl_time_stamp = v_timestamp
          WHERE csl_inst_code = prm_inst_code
            AND csl_pan_no = v_hash_pan
            AND csl_rrn = prm_rrn
            AND csl_txn_code = prm_txn_code
            AND csl_delivery_channel = prm_delivery_chnl
            AND csl_business_date = prm_tran_date
            AND csl_business_time = prm_tran_time;

         IF SQL%ROWCOUNT = 0
         THEN
            NULL;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while updating timestamp in statementlog-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         IF     v_add_ins_date IS NOT NULL
            AND v_prfl_code IS NOT NULL
            AND v_prfl_flag = 'Y'
         THEN
            pkg_limits_check.sp_limitcnt_rever_reset (prm_inst_code,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      prm_txn_code,
                                                      v_tran_type,
                                                      NULL,
                                                      NULL,
                                                      v_prfl_code,
                                                      v_tran_amt,
                                                      v_tran_amt,
                                                      prm_delivery_chnl,
                                                      v_hash_pan,
                                                      v_add_ins_date,
                                                      v_resp_cde,
                                                      v_err_msg
                                                     );
         END IF;

         IF v_err_msg <> 'OK'
         THEN
            v_err_msg := v_err_msg;
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
                  'Error from Limit count reveer Process '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
          
         
        
    BEGIN
         UPDATE transactionlog
            SET csr_achactiontaken = 'R',
                processtype = 'N',
                remark = prm_remark,
                response_code='224',
                gl_eod_flag='V'
          WHERE instcode = prm_inst_code
            AND rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date
            AND business_time = prm_orgnl_tran_time
            AND customer_card_no = v_hash_pan
            AND (auth_id IS NULL OR auth_id = prm_orgnl_auth_id)
            AND txn_code = prm_orgnl_txn_code
            AND delivery_channel = prm_orgnl_delivery_chnl;

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Orignal txn not updated';
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
                  'problem occured while updating orignal txn '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

if v_addcharge is not null then
BEGIN
    UPDATE vms_achexc_appd_acc
      SET vaa_enable_flag = 'N',
          vaa_lupd_user = prm_ins_user,
          vaa_lupd_date = SYSDATE
        WHERE     vaa_acct_no = v_card_acct_no
          AND vaa_company_name = UPPER (TRIM (v_orgnl_companyname))
          AND vaa_resp_code = v_addcharge;
    EXCEPTION
   WHEN OTHERS THEN
      v_resp_cde := '21';
      v_err_msg :='Excp while achappr resp flag updation-' || SUBSTR (SQLERRM, 1, 200);
       RAISE exp_reject_record;
END; 
end if;
    IF v_remarks IS NOT NULL THEN
      v_remarks:=v_remarks || '/' || prm_remark;
    ELSE
        v_remarks:=prm_remark;
        
    END IF;    

   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK TO v_auth_savepoint;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
         ROLLBACK TO v_auth_savepoint;
   END;
     
 
                 
   --Sn Get responce code fomr master
   BEGIN
      SELECT cms_iso_respcde
        INTO prm_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = prm_inst_code
         AND cms_delivery_channel = prm_delivery_chnl
         AND cms_response_id = v_resp_cde;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while selecting data from response master '
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         prm_resp_code := '89';
   END;

   --En Get responce code fomr master
   IF v_prod_code IS NULL
   THEN
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
           INTO v_card_stat, v_prod_code, v_card_type, v_card_acct_no
           FROM cms_appl_pan
          WHERE cap_inst_code = prm_inst_code
            AND cap_pan_code = gethash (prm_orgnl_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO v_acct_balance, v_ledger_bal, v_acct_type
        FROM cms_acct_mast
       WHERE cam_acct_no = v_card_acct_no AND cam_inst_code = prm_inst_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_acct_balance := 0;
         v_ledger_bal := 0;
   END;

   IF v_dr_cr_flag IS NULL
   THEN
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_tran_desc, v_prfl_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_txn_code
            AND ctm_delivery_channel = prm_delivery_chnl
            AND ctm_inst_code = prm_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;

   --Sn Inserting data in transactionlog
   BEGIN
      sp_log_txnlog (prm_inst_code,
                     prm_msg_type,
                     prm_rrn,
                     prm_delivery_chnl,
                     prm_txn_code,
                     v_txn_type,
                     prm_txn_mode,
                     prm_tran_date,
                     prm_tran_time,
                     prm_revrsl_code,
                     v_hash_pan,
                     v_encr_pan,
                     v_err_msg,
                     NULL,
                     v_card_stat,
                     v_tran_desc,
                     NULL,
                     NULL,
                     v_timestamp,
                     v_card_acct_no,
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     v_acct_balance,
                     v_ledger_bal,
                     v_acct_type,
                     v_proxy_number,
                     v_auth_id,
                     v_tran_amt,
                     v_tran_amt + NVL (v_orgnl_txn_totalfee_amt, 0),
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     v_resp_cde,
                     prm_resp_code,
                     prm_curr_code,
                     v_err_msg,
                     NULL,
                     NULL,
                     SUBSTR(v_remarks,1,1000)
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_resp_code := '89';
         v_err_msg :=
               'Exception while inserting to transaction log '
            || SQLCODE
            || '---'
            || SQLERRM;
   END;

   --En Inserting data in transactionlog
   --Sn Inserting data in transactionlog dtl
   BEGIN
      sp_log_txnlogdetl (prm_inst_code,
                         prm_msg_type,
                         prm_rrn,
                         prm_delivery_chnl,
                         prm_txn_code,
                         v_txn_type,
                         prm_txn_mode,
                         prm_tran_date,
                         prm_tran_time,
                         v_hash_pan,
                         v_encr_pan,
                         v_err_msg,
                         v_card_acct_no,
                         v_auth_id,
                         v_tran_amt,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         prm_resp_code,
                         NULL,
                         NULL,
                         NULL,
                         v_logdtl_resp
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         prm_resp_code := '89';
   END;

   prm_errmsg := v_err_msg;
   prm_ach_endledgerbal := v_ledger_bal;
   prm_ach_endaccountbalance := v_acct_balance;
   prm_ach_auth_id := v_auth_id;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      prm_resp_code := '69';                              
      prm_errmsg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;