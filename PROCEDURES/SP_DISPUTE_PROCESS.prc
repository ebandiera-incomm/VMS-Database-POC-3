CREATE OR REPLACE PROCEDURE VMSCMS.sp_dispute_process (
   p_inst_code             IN       NUMBER,
   p_pan                   IN       NUMBER,
   p_orgnl_pan             IN       NUMBER,
   p_msg_type              IN       VARCHAR2,
   p_mbr_numb              IN       VARCHAR2,
   p_txn_amount            IN       VARCHAR2,
   p_rrn                   IN       VARCHAR2,
   p_stan                  IN       VARCHAR2,
   p_del_channel           IN       VARCHAR2,
   p_txn_date              IN       VARCHAR2,
   p_txn_time              IN       VARCHAR2,
   p_txn_code              IN       VARCHAR2,
   p_txn_mode              IN       VARCHAR2,
   p_orgnl_rrn             IN       VARCHAR2,
   p_orgnl_stan            IN       VARCHAR2,
   p_orgnl_business_date   IN       VARCHAR2,
   p_orgnl_business_time   IN       VARCHAR2,
   p_orgnl_txn_amt         IN       VARCHAR2,
   p_orgnl_txn_code        IN       VARCHAR2,
   p_orgnl_del_channel     IN       VARCHAR2,
   --Sn Added for performance changes
   p_reverse_flag              IN   transactionlog.tran_reverse_flag%TYPE,
   p_fee_reversal_flag         IN   transactionlog.fee_reversal_flag%TYPE,
   p_reversalcode              IN   transactionlog.reversal_code%TYPE,
   p_orgnl_amount              IN   transactionlog.amount%TYPE,
   p_dispute_flag              IN   transactionlog.dispute_flag%TYPE,
   --En Added for performance changes
   p_call_id               IN       VARCHAR2,
   p_appr_resolution       IN       CHAR,
   p_ipaddress             IN       VARCHAR2,
   p_insuser               IN       NUMBER,
   p_resp_code             OUT      VARCHAR2,
   p_resp_msg              OUT      VARCHAR2
)
AS
/*************************************************
  * VERSION              :  1.0
  * Created Date         : 11/Apr/2014
  * Created By           : Sankar S.
  * PURPOSE              : Dispute Transactions Approve/Reject process
  * Release Number       : RI0027.2_B0005

  * Modified by          :  Dnyaneshwar J
  * Modified Reason      :  Mantis-14224
  * Modified Date        :  17-Apr-2014
  * Reviewer             :  spankaj
  * Reviewed Date        :  18-April-2014
  * Build Number         :  RI0027.2_B0006

  * Modified by          :  Dnyaneshwar J
  * Modified Reason      :  Mantis-14295
  * Modified Date        :  17-Apr-2014
  * Reviewer             :  spankaj
  * Reviewed Date        :  22-April-2014
  * Build Number         :  RI0027.2_B0006

  * Modified by          :  Dnyaneshwar J
  * Modified Reason      :  Mantis-14338
  * Modified Date        :  23-Apr-2014
  * Build Number         :  RI0027.2_B0008

  * Modified by          :  Dnyaneshwar J
  * Modified Reason      :  Mantis-14338
  * Modified Date        :  24-Apr-2014
  * Build Number         :  RI0027.2_B0009

  * Modified by          :  Ramesh A 
  * Modified Reason      :  MVCSD-5513
  * Modified Date        :  26-Jul-2014
  * Reviewer             :  Spankaj
  * Build Number         :  RI0024.2.4_B0001

  * Modified by          :  A.Sivakaminathan 
  * Modified Reason      :  MVCSD-5669
  * Modified Date        :  30-Sep-2015
  * Reviewer             :  Spankaj
  * Build Number         :  VMSGPRHOSTCSD_3.2

  * Modified by          : Jahnavi B
  * Modified Date        : 20-May-19
  * Modified For         : VMS-932,VMS-935,VMS-936
  * Reviewer             : Saravanankumar
  * Build Number         : R16_B00003

    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-4-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
    
    * Modified By      : Bhavani E
    * Modified Date    : 15-Mar-2023
    * Purpose          : VMS-7103 - decline dispute by checking Refund eligibility 
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991


 ************************************************/
   v_resp_code                 VARCHAR2 (3);
   v_resp_msg                  VARCHAR2 (300);
   v_rrn_count                 NUMBER (3);
   v_call_seq                  NUMBER (3);
   v_max_card_bal              NUMBER;
   --v_reverse_flag              transactionlog.tran_reverse_flag%TYPE;
   --v_fee_reversal_flag         transactionlog.fee_reversal_flag%TYPE;
   --v_reversalcode              transactionlog.reversal_code%TYPE;
   v_hash_pan                  cms_appl_pan.cap_pan_code%TYPE;
   v_orgnl_hash_pan            cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                  cms_appl_pan.cap_pan_code_encr%TYPE;
   v_orgnl_encr_pan            cms_appl_pan.cap_pan_code_encr%TYPE;
   v_expry_date                cms_appl_pan.cap_expry_date%TYPE;
   v_acct_balance              cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_balance            cms_acct_mast.cam_ledger_bal%TYPE;
   v_cap_acct_no               cms_appl_pan.cap_acct_no%TYPE;
   v_prod_cattype              cms_appl_pan.cap_card_type%TYPE;
   v_card_stat                 cms_appl_pan.cap_card_stat%TYPE;
   v_proxynumber               cms_appl_pan.cap_proxy_number%TYPE;
   v_prod_code                 cms_appl_pan.cap_prod_code%TYPE;
   v_tran_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
   v_credit_debit_flag         cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_cam_type_code             cms_acct_mast.cam_type_code%TYPE;
   v_cam_stat_code             cms_acct_mast.cam_stat_code%TYPE;
   --v_orgnl_amount              transactionlog.amount%TYPE;
   --v_original_tranfee_amt      transactionlog.tranfee_amt%TYPE;
   excp_rej_record             EXCEPTION;
   v_timestamp                 transactionlog.time_stamp%TYPE;
   --v_orgnl_txn_feecode         transactionlog.feecode%TYPE;
   v_feecap_flag               cms_fee_mast.cfm_feecap_flag%TYPE;
   v_orgnl_fee_amt             cms_fee_mast.cfm_fee_amt%TYPE;
   --v_orgnl_txn_fee_plan        transactionlog.fee_plan%TYPE;
   --v_orgnl_servicetax_amt      transactionlog.servicetax_amt%TYPE;
   --v_orgnl_cess_amt            transactionlog.cess_amt%TYPE;
   v_orgnl_cr_dr_flag          transactionlog.cr_dr_flag%TYPE;
   --v_orgnl_tranfee_cr_acctno   transactionlog.tranfee_cr_acctno%TYPE;
   --v_orgnl_tranfee_dr_acctno   transactionlog.tranfee_dr_acctno%TYPE;
   --v_orgnl_st_calc_flag        transactionlog.tran_st_calc_flag%TYPE;
   --v_orgnl_cess_calc_flag      transactionlog.tran_cess_calc_flag%TYPE;
   --v_orgnl_st_cr_acctno        transactionlog.tran_st_cr_acctno%TYPE;
   --v_orgnl_st_dr_acctno        transactionlog.tran_st_dr_acctno%TYPE;
   --v_orgnl_cess_cr_acctno      transactionlog.tran_cess_cr_acctno%TYPE;
   --v_orgnl_cess_dr_acctno      transactionlog.tran_cess_dr_acctno%TYPE;
   v_fee_narration             cms_statements_log.csl_trans_narrration%TYPE;
   --v_dispute_flag              transactionlog.dispute_flag%TYPE;
   V_TXN_TYPE            NUMBER (1); --Added for to log MVCSD-5513
   v_Retperiod  date; --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991
V_chequerefund_eligibility    vmscms.cms_prod_cattype.cpc_chequerefund_eligibility%TYPE; --added for VMS-7103
   CURSOR feereverse
   IS
      SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
             csl_merchant_state, csl_trans_amount
        FROM VMSCMS.CMS_STATEMENTS_LOG_VW
       WHERE csl_business_date = p_orgnl_business_date
         AND csl_business_time = p_orgnl_business_time
         AND csl_rrn = p_orgnl_rrn
         AND csl_delivery_channel = p_orgnl_del_channel
         AND csl_txn_code = p_orgnl_txn_code
         AND csl_pan_no = v_orgnl_hash_pan
         AND csl_inst_code = p_inst_code
         AND txn_fee_flag = 'Y';
BEGIN
   v_resp_code := '00';
   v_resp_msg := 'OK';
   v_timestamp := SYSTIMESTAMP;

   BEGIN
      BEGIN
         v_hash_pan := gethash (p_pan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while converting pan into hash '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_rej_record;
      END;

      BEGIN
         v_orgnl_hash_pan := gethash (p_orgnl_pan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while converting orgnl pan into hash '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_rej_record;
      END;

      --Sn get encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_pan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while converting pan into encr '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      BEGIN
         v_orgnl_encr_pan := fn_emaps_main (p_orgnl_pan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while converting  orgnl pan into encr '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

         --En get encr pan
      --Sn Duplicate rrn check
      BEGIN


         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog_VW
          WHERE instcode = p_inst_code
            AND customer_card_no = gethash (p_pan)
            AND rrn = p_rrn
            AND delivery_channel = p_del_channel
            AND txn_code = p_txn_code;


         IF v_rrn_count > 0
         THEN
            v_resp_code := '22';
            v_resp_msg := 'Duplicate RRN found';
            RAISE excp_rej_record;
         END IF;
      EXCEPTION
         WHEN excp_rej_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_msg :=
                       'while getting rrn count ' || SUBSTR (SQLERRM, 1, 100);
            v_resp_code := '21';
            RAISE excp_rej_record;
      END;

      --En Duplicate rrn check
      BEGIN
         /*SELECT     tran_reverse_flag, fee_reversal_flag, reversal_code,
                    amount, tranfee_amt,
                    feecode, fee_plan,
                    servicetax_amt, cess_amt,
                    tranfee_cr_acctno, tranfee_dr_acctno,
                    tran_st_calc_flag, tran_cess_calc_flag,
                    tran_st_cr_acctno, tran_st_dr_acctno,
                    tran_cess_cr_acctno, tran_cess_dr_acctno,
                     dispute_flag
               INTO v_reverse_flag, v_fee_reversal_flag, v_reversalcode,
                    v_orgnl_amount, v_original_tranfee_amt,
                    v_orgnl_txn_feecode, v_orgnl_txn_fee_plan,
                    v_orgnl_servicetax_amt, v_orgnl_cess_amt,
                    v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,
                    v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag,
                    v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno,
                    v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno,
                     v_dispute_flag
               FROM transactionlog, cms_dispute_txns
              WHERE instcode = p_inst_code
                AND instcode = cdt_inst_code
                AND rrn = p_orgnl_rrn
                AND rrn = cdt_rrn
                AND business_date = p_orgnl_business_date
                AND business_time = p_orgnl_business_time
                AND business_date = cdt_txn_date
                AND business_time = cdt_txn_time
                AND customer_card_no = v_orgnl_hash_pan
                AND customer_card_no = cdt_pan_code
                AND delivery_channel = cdt_delivery_channel
                AND delivery_channel = p_orgnl_del_channel
                AND txn_code = cdt_txn_code
                AND txn_code = p_orgnl_txn_code
                AND response_code = '00'
                AND cdt_dispute_status = 'O'
         --Added by Dnyaneshwar J on 18 Apr 2014, Mantis-14224
         FOR UPDATE;*/

         --SN check for successful Transaction and get the detail...
         IF p_reversalcode <> '00'
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                       'Orginal transaction was not a successful transaction';
            RAISE excp_rej_record;
         END IF;

         --EN check for successful Transaction and get the detail...
         IF p_txn_code <> '95'
         THEN
         --SN check is it already reversed
         BEGIN
            IF p_reverse_flag = 'Y'
            THEN
               v_resp_code := '21';
               v_resp_msg := 'Transaction is already reversed';
               RAISE excp_rej_record;
            ELSIF p_fee_reversal_flag = 'Y'
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                  'Fee reversal transaction is already done for the transaction';
               RAISE excp_rej_record;
            END IF;
         END;
         END IF;         
         --EN check is it already reversed
         IF  p_dispute_flag = 'A'
         THEN
            v_resp_code := '220';
            v_resp_msg := 'Dispute already apporved';
            RAISE excp_rej_record;
         ELSIF  p_dispute_flag = 'R'
         THEN
            v_resp_code := '221';
            v_resp_msg := 'Dispute already rejected';
            RAISE excp_rej_record;
         END IF;
      EXCEPTION
         WHEN excp_rej_record
         THEN
            RAISE;
       /*  WHEN NO_DATA_FOUND
         THEN
            v_resp_code := '49';
            v_resp_msg := 'Orginal transaction record not found';
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'while selecting orginal txn detail'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;*/
      END;

      BEGIN
         SELECT ctm_tran_desc, ctm_credit_debit_flag,TO_NUMBER (DECODE (CTM_TRAN_TYPE,  'N', '0',  'F', '1')) --Added txn type for to log MVCSD-5513
           INTO v_tran_desc, v_credit_debit_flag,V_TXN_TYPE
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_del_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_code := '49';
            v_resp_msg :=
                  'Transaction detail is not found in master for reversal txn '
               || p_txn_code
               || 'delivery channel '
               || p_del_channel;
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Problem while selecting debit/credit flag '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      BEGIN
         SELECT cap_acct_no, cap_prod_code, cap_card_type, cap_card_stat,
                cap_expry_date, cap_proxy_number
           INTO v_cap_acct_no, v_prod_code, v_prod_cattype, v_card_stat,
                v_expry_date, v_proxynumber
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan
            AND cap_inst_code = p_inst_code
            AND cap_mbr_numb = p_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_code := '16';
            v_resp_msg := 'Card not found in PAN master ';
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error While Selecting Card in PAN master '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;
    --sn adding for VMS-7103 

    select cpc_chequerefund_eligibility 
      into V_chequerefund_eligibility
      from vmscms.cms_prod_cattype 
     where cpc_inst_code=p_inst_code
       and cpc_prod_code=v_prod_code
       and cpc_card_type=v_prod_cattype;
       
       IF V_chequerefund_eligibility <> 'Y' THEN
             IF p_appr_resolution ='3' THEN
            v_resp_code := '324';
            v_resp_msg :='Dispute is Declined due to refund check is not eligible';
            Raise excp_rej_record;     
        END IF;
       END IF;
 
  --en adding for VMS-7103 
      -- Commenting the below checks as part of VMS-932,VMS-935,VMS-936
      --Sn Check expiry
    /*  IF TO_DATE (p_txn_date, 'yyyymmdd') > v_expry_date
      THEN
         v_resp_code := '13';
         v_resp_msg := 'Expired Card';
         RAISE excp_rej_record;
      END IF; */

      --En Check expiry
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code,
                cam_stat_code
           INTO v_acct_balance, v_ledger_balance, v_cam_type_code,
                v_cam_stat_code
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_code := '49';
            v_resp_msg := 'Account No. ' || v_cap_acct_no || 'Not found';
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while select Account details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_rej_record;
      END;

      --v_timestamp := SYSTIMESTAMP;
-- Commented reversal action has it is not need as of now for MVCSD-5513
      IF p_txn_code = '88'
      THEN
      /*   IF p_txn_amount <= p_orgnl_txn_amt
         THEN
            IF v_cam_stat_code <> 2
            THEN
               IF p_appr_resolution = 1
               THEN
                  BEGIN
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
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_code := '21';
                        v_resp_msg :=
                              'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_rej_record;
                  END;

                  IF v_max_card_bal < (v_ledger_balance + p_txn_amount)
                  THEN
                     v_resp_code := '2';
                     v_resp_msg := 'Dispute failed.Maximum balance exceeding';
                     RAISE excp_rej_record;
                  END IF;

                  BEGIN
                     UPDATE cms_acct_mast
                        SET cam_acct_bal = v_acct_balance + p_txn_amount,
                            cam_ledger_bal = v_ledger_balance + p_txn_amount
                      WHERE cam_inst_code = p_inst_code
                        AND cam_acct_no = v_cap_acct_no;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_resp_code := '49';
                        v_resp_msg := 'Problem in updation of CMS_ACCT_MAST ';
                        RAISE excp_rej_record;
                     END IF;
                  EXCEPTION
                     WHEN excp_rej_record
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_resp_code := '21';
                        v_resp_msg :=
                              'Error while updating CMS_ACCT_MAST'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_rej_record;
                  END;

                  --SN create a entry in stmts log
                  BEGIN
                     INSERT INTO cms_statements_log
                                 (csl_pan_no, csl_acct_no,
                                  csl_opening_bal, csl_trans_amount,
                                  csl_trans_type, csl_trans_date,
                                  csl_closing_balance,
                                  csl_trans_narrration,
                                  csl_pan_no_encr, csl_rrn,
                                  csl_auth_id,
                                  csl_business_date, csl_business_time,
                                  csl_delivery_channel, csl_inst_code,
                                  csl_txn_code, csl_ins_date, csl_ins_user,
                                  csl_panno_last4digit,
                                  csl_acct_type, csl_time_stamp,
                                  csl_prod_code
                                 )
                          VALUES (v_hash_pan, v_cap_acct_no,
                                  v_ledger_balance, p_txn_amount,
                                  v_credit_debit_flag, SYSDATE,
                                  v_ledger_balance + p_txn_amount,
                                  'Dispute process ' || v_tran_desc,
                                  v_encr_pan, p_rrn,
                                  LPAD (seq_auth_id.NEXTVAL, 6, '0'),
                                  p_txn_date, p_txn_time,
                                  p_del_channel, p_inst_code,
                                  p_orgnl_txn_code, SYSDATE, p_insuser,
                                  (SUBSTR (p_orgnl_pan,
                                           LENGTH (p_pan) - 3,
                                           LENGTH (p_pan)
                                          )
                                  ),
                                  v_cam_type_code, v_timestamp,
                                  v_prod_code
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_resp_code := '89';
                        v_resp_msg :=
                              'Error creating entry in statement log-'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_rej_record;
                  END;
               --EN create a entry in stmts log
               END IF;
            ELSE
               v_resp_code := '219';
               v_resp_msg := 'CLOSED ACCOUNT ';
               RAISE excp_rej_record;
            END IF;

--------------------------------------------
--SN: Added to reverse fee
--------------------------------------------
            IF p_txn_amount = v_orgnl_amount
            THEN
               IF    v_original_tranfee_amt > 0
                  OR v_orgnl_txn_feecode IS NOT NULL
               THEN
                  -- SN Added for FWR-11
                  BEGIN
                     SELECT cfm_feecap_flag, cfm_fee_amt
                       INTO v_feecap_flag, v_orgnl_fee_amt
                       FROM cms_fee_mast
                      WHERE cfm_inst_code = p_inst_code
                        AND cfm_fee_code = v_orgnl_txn_feecode;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_feecap_flag := '';
                     WHEN OTHERS
                     THEN
                        v_resp_msg :=
                              'Error in feecap flag fetch '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_rej_record;
                  END;

                  -- EN Added for FWR-11
                  BEGIN
                     FOR c1 IN feereverse
                     LOOP
                        -- SN Added for FWR-11
                        v_original_tranfee_amt := c1.csl_trans_amount;

                        IF v_feecap_flag = 'Y'
                        THEN
                           BEGIN
                              sp_tran_fees_revcapcheck
                                                     (p_inst_code,
                                                      v_cap_acct_no,
                                                      p_orgnl_business_date,
                                                      v_original_tranfee_amt,
                                                      v_orgnl_fee_amt,
                                                      v_orgnl_txn_fee_plan,
                                                      v_orgnl_txn_feecode,
                                                      v_resp_msg
                                                     );
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 v_resp_code := '21';
                                 v_resp_msg :=
                                       'Error while reversing the fee Cap amount '
                                    || SUBSTR (SQLERRM, 1, 200);
                                 RAISE excp_rej_record;
                           END;
                        END IF;

                        -- EN Added for FWR-11
                        BEGIN
                           sp_reverse_fee_amount
                               (p_inst_code,
                                p_rrn,
                                p_del_channel,
                                NULL,
                                --p_orgnl_terminal_id,  Temp commented by Spankaj
                                NULL,                             --p_merc_id,
                                p_txn_code,
                                TO_DATE (   SUBSTR (TRIM (p_txn_date), 1, 8)
                                         || ' '
                                         || SUBSTR (TRIM (p_txn_time), 1, 8),
                                         'yyyymmdd hh24:mi:ss'
                                        ),
                                p_txn_mode,
                                -- C1.CSL_TRANS_AMOUNT,
                                v_original_tranfee_amt, -- Modified for FWR-11
                                p_pan,
                                v_orgnl_txn_feecode,
                                --C1.CSL_TRANS_AMOUNT,
                                v_original_tranfee_amt, -- Modified for FWR-11
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
                                p_orgnl_rrn,
                                v_cap_acct_no,
                                p_txn_date,
                                p_txn_time,
                                NULL,
                                c1.csl_trans_narrration,
                                /*C1.CSL_MERCHANT_NAME,
                                C1.CSL_MERCHANT_CITY,
                                C1.CSL_MERCHANT_STATE,*/
                                --Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
                               /* NULL,
                                --p_merchant_name, Temp commented by Spankaj
                                NULL,
                                --p_merchant_city, Temp commented by Spankaj
                                NULL,
                                --p_merchant_state, Temp commented by Spankaj
                                v_resp_code,
                                v_resp_msg
                               );
                           v_fee_narration := c1.csl_trans_narrration;

                           IF v_resp_code <> '00' OR v_resp_msg <> 'OK'
                           THEN
                              RAISE excp_rej_record;
                           END IF;
                        EXCEPTION
                           WHEN excp_rej_record
                           THEN
                              RAISE;
                           WHEN OTHERS
                           THEN
                              v_resp_code := '21';
                              v_resp_msg :=
                                    'Error while reversing the fee amount '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE excp_rej_record;
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

               --Added by Deepa For Reversal Fees on June 27 2012
               IF v_fee_narration IS NULL
               THEN
                  BEGIN
                     --SN Added for FWR-11
                     IF v_feecap_flag = 'Y'
                     THEN
                        BEGIN
                           sp_tran_fees_revcapcheck (p_inst_code,
                                                     v_cap_acct_no,
                                                     p_orgnl_business_date,
                                                     v_original_tranfee_amt,
                                                     v_orgnl_fee_amt,
                                                     v_orgnl_txn_fee_plan,
                                                     v_orgnl_txn_feecode,
                                                     v_resp_msg
                                                    );     -- Added for FWR-11
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_resp_code := '21';
                              v_resp_msg :=
                                    'Error while reversing the fee Cap amount '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE excp_rej_record;
                        END;
                     END IF;

                     --EN Added for FWR-11
                     sp_reverse_fee_amount
                                       (p_inst_code,
                                        p_rrn,
                                        p_del_channel,
                                        NULL,
                                        --p_orgnl_terminal_id,  Temp commented by Spankaj,
                                        NULL,                     --p_merc_id,
                                        p_txn_code,
                                        TO_DATE (   SUBSTR (TRIM (p_txn_date),
                                                            1,
                                                            8
                                                           )
                                                 || ' '
                                                 || SUBSTR (TRIM (p_txn_time),
                                                            1,
                                                            8
                                                           ),
                                                 'yyyymmdd hh24:mi:ss'
                                                ),
                                        p_txn_mode,
                                        v_original_tranfee_amt,
                                        p_pan,
                                        v_orgnl_txn_feecode,
                                        v_original_tranfee_amt,
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
                                        p_orgnl_rrn,
                                        v_cap_acct_no,
                                        p_txn_date,
                                        p_txn_time,
                                        NULL,                      --v_auth_id
                                        v_fee_narration,
                                        /*V_FEE_MERCHNAME,
                                        V_FEE_MERCHCITY,
                                        V_FEE_MERCHSTATE,*/
                                        --Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
                                      /*  NULL,
                                        --p_merchant_name, Temp commented by Spankaj
                                        NULL,
                                        --p_merchant_city, Temp commented by Spankaj
                                        NULL,
                                        --p_merchant_state, Temp commented by Spankaj
                                        v_resp_code,
                                        v_resp_msg
                                       );

                     IF v_resp_code <> '00' OR v_resp_msg <> 'OK'
                     THEN
                        RAISE excp_rej_record;
                     END IF;
                  EXCEPTION
                     WHEN excp_rej_record
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_resp_code := '21';
                        v_resp_msg :=
                              'Error while reversing the fee amount '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_rej_record;
                  END;
               END IF;
            END IF;

            BEGIN
               UPDATE CMS_STATEMENTS_LOG
                  SET CSL_TIME_STAMP = V_TIMESTAMP,
                      CSL_ACCT_TYPE=V_CAM_TYPE_CODE,
                      csl_prod_code=v_prod_Code
                WHERE csl_inst_code = p_inst_code
                  AND csl_pan_no = v_hash_pan
                  AND csl_rrn = p_rrn
                  AND csl_txn_code = p_txn_code
                  AND csl_delivery_channel = p_del_channel
                  AND csl_business_date = p_txn_date
                  AND csl_business_time = p_txn_time;

               IF SQL%ROWCOUNT = 0
               THEN
                  NULL;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_code := '21';
                  v_resp_msg :=
                        'Error while updating timestamp in statementlog-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_rej_record;
            END;*/

--------------------------------------------
--EN: Added to reverse fee
--------------------------------------------

            --SN call log info
            BEGIN
               BEGIN
                  SELECT NVL (MAX (ccd_call_seq), 0) + 1
                    INTO v_call_seq
                    FROM cms_calllog_details
                   WHERE ccd_inst_code = p_inst_code
                     AND ccd_call_id = p_call_id
                     AND ccd_pan_code = v_hash_pan;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_resp_code := '49';
                     v_resp_msg :=
                             'record is not present in cms_calllog_details  ';
                     RAISE excp_rej_record;
                  WHEN OTHERS
                  THEN
                     v_resp_code := '21';
                     v_resp_msg :=
                           'Error while selecting frmo cms_calllog_details '
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE excp_rej_record;
               END;

               INSERT INTO cms_calllog_details
                           (ccd_inst_code, ccd_call_id, ccd_pan_code,
                            ccd_call_seq, ccd_rrn, ccd_devl_chnl,
                            ccd_txn_code, ccd_tran_date, ccd_tran_time,
                            ccd_tbl_names, ccd_colm_name, ccd_old_value,
                            ccd_new_value, ccd_comments, ccd_ins_user,
                            ccd_ins_date, ccd_lupd_user, ccd_lupd_date,
                            ccd_acct_no
                           )
                    VALUES (p_inst_code, p_call_id, v_hash_pan,
                            v_call_seq, p_rrn, p_del_channel,
                            p_txn_code, p_txn_date, p_txn_time,
                            NULL, NULL, NULL,
                            NULL, NULL, p_insuser,
                            SYSDATE, p_insuser, SYSDATE,
                            v_cap_acct_no
                           );
            EXCEPTION
               WHEN excp_rej_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_resp_code := '21';
                  v_resp_msg :=
                        ' Error while inserting into cms_calllog_details '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE excp_rej_record;
            END;

            --SN Update Dispute Staus at transactionlog
            BEGIN

--Added for VMS-5733/FSP-991

v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_business_date), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

IF (v_Retdate>v_Retperiod)
    THEN
               UPDATE transactionlog
                  SET dispute_flag = 'A'
                WHERE rrn = p_orgnl_rrn
                  AND business_date = p_orgnl_business_date
                  AND business_time = p_orgnl_business_time
                  AND txn_code = p_orgnl_txn_code
                  AND customer_card_no = v_orgnl_hash_pan
                  AND delivery_channel = p_orgnl_del_channel
                  AND instcode = p_inst_code;
           else    
               UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                  SET dispute_flag = 'A'
                WHERE rrn = p_orgnl_rrn
                  AND business_date = p_orgnl_business_date
                  AND business_time = p_orgnl_business_time
                  AND txn_code = p_orgnl_txn_code
                  AND customer_card_no = v_orgnl_hash_pan
                  AND delivery_channel = p_orgnl_del_channel
                  AND instcode = p_inst_code;
                end if;      

               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_code := '49';
                  v_resp_msg :=
                     'Problem in updation of Dispute status in transactionlog';
                  RAISE excp_rej_record;
               END IF;
            EXCEPTION
               WHEN excp_rej_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_resp_code := '21';
                  v_resp_msg :=
                        'Error while updating Dispute status'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_rej_record;
            END;

            --EN Update Dispute Staus at transactionlog
            --SN Update Dispute Staus at CMS_DISPUTE_TXNS
            BEGIN
               UPDATE cms_dispute_txns
                  SET cdt_dispute_status = 'A'
                WHERE cdt_rrn = p_orgnl_rrn
                  AND cdt_txn_code = p_orgnl_txn_code
                  AND cdt_pan_code = v_orgnl_hash_pan
                  AND cdt_delivery_channel = p_orgnl_del_channel
                  AND cdt_inst_code = p_inst_code;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_code := '49';
                  v_resp_msg :=
                     'Problem in updation of Dispute status in dispute details';
                  RAISE excp_rej_record;
               END IF;
            EXCEPTION
               WHEN excp_rej_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_resp_code := '21';
                  v_resp_msg :=
                        'Error while updating Dispute status'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_rej_record;
            END;
         --EN Update Dispute Staus at CMS_DISPUTE_TXNS
        /* ELSE
            v_resp_code := '218';
            v_resp_msg :=
                       'Amount should not exceed the Maximum Transfer amount';
            RAISE excp_rej_record;*/
         END IF;
      IF p_txn_code = '89' THEN
         --SN call log info
         BEGIN
            BEGIN
               SELECT NVL (MAX (ccd_call_seq), 0) + 1
                 INTO v_call_seq
                 FROM cms_calllog_details
                WHERE ccd_inst_code = p_inst_code
                  AND ccd_call_id = p_call_id
                  AND ccd_pan_code = v_hash_pan;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_resp_code := '49';
                  v_resp_msg :=
                             'record is not present in cms_calllog_details  ';
                  RAISE excp_rej_record;
               WHEN OTHERS
               THEN
                  v_resp_code := '21';
                  v_resp_msg :=
                        'Error while selecting frmo cms_calllog_details '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE excp_rej_record;
            END;

            INSERT INTO cms_calllog_details
                        (ccd_inst_code, ccd_call_id, ccd_pan_code,
                         ccd_call_seq, ccd_rrn, ccd_devl_chnl, ccd_txn_code,
                         ccd_tran_date, ccd_tran_time, ccd_tbl_names,
                         ccd_colm_name, ccd_old_value, ccd_new_value,
                         ccd_comments, ccd_ins_user, ccd_ins_date,
                         ccd_lupd_user, ccd_lupd_date, ccd_acct_no
                        )
                 VALUES (p_inst_code, p_call_id, v_hash_pan,
                         v_call_seq, p_rrn, p_del_channel, p_txn_code,
                         p_txn_date, p_txn_time, NULL,
                         NULL, NULL, NULL,
                         NULL, p_insuser, SYSDATE,
                         p_insuser, SYSDATE, v_cap_acct_no
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                     ' Error while inserting into cms_calllog_details '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE excp_rej_record;
         END;

         --SN Update Dispute Staus at transactionlog
         BEGIN

         --Added for VMS-5733/FSP-991



IF (v_Retdate>v_Retperiod)
    THEN

            UPDATE transactionlog
               SET dispute_flag = 'R'
             WHERE rrn = p_orgnl_rrn
               AND business_date = p_orgnl_business_date
               AND business_time = p_orgnl_business_time
               AND txn_code = p_orgnl_txn_code
               AND customer_card_no = v_orgnl_hash_pan
               AND delivery_channel = p_orgnl_del_channel
               AND instcode = p_inst_code;
           else
                UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
               SET dispute_flag = 'R'
             WHERE rrn = p_orgnl_rrn
               AND business_date = p_orgnl_business_date
               AND business_time = p_orgnl_business_time
               AND txn_code = p_orgnl_txn_code
               AND customer_card_no = v_orgnl_hash_pan
               AND delivery_channel = p_orgnl_del_channel
               AND instcode = p_inst_code;
            end if;   


            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_code := '49';
               v_resp_msg := 'Problem in updation of Dispute status ';
               RAISE excp_rej_record;
            END IF;
         EXCEPTION
            WHEN excp_rej_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                     'Error while updating Dispute status'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_rej_record;
         END;

         --EN Update Dispute Staus at transactionlog
         --SN Update Dispute Staus at CMS_DISPUTE_TXNS
         BEGIN
            UPDATE cms_dispute_txns
               SET cdt_dispute_status = 'R'
             WHERE cdt_rrn = p_orgnl_rrn
               AND cdt_txn_code = p_orgnl_txn_code
               AND cdt_pan_code = v_orgnl_hash_pan
               AND cdt_delivery_channel = p_orgnl_del_channel
               AND cdt_inst_code = p_inst_code;

            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_code := '49';
               v_resp_msg := 'Problem in updation of Dispute status ';
               RAISE excp_rej_record;
            END IF;
         EXCEPTION
            WHEN excp_rej_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                     'Error while updating Dispute status'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_rej_record;
         END;
      --EN Update Dispute Staus at CMS_DISPUTE_TXNS
      END IF;
    IF p_txn_code = '95' Then
         --SN call log info
         BEGIN
            BEGIN
               SELECT NVL (MAX (ccd_call_seq), 0) + 1
                 INTO v_call_seq
                 FROM cms_calllog_details
                WHERE ccd_inst_code = p_inst_code
                  AND ccd_call_id = p_call_id
                  AND ccd_pan_code = v_hash_pan;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_resp_code := '49';
                  v_resp_msg :=
                             'record is not present in cms_calllog_details  ';
                  RAISE excp_rej_record;
               WHEN OTHERS
               THEN
                  v_resp_code := '21';
                  v_resp_msg :=
                        'Error while selecting frmo cms_calllog_details '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE excp_rej_record;
            END;

            INSERT INTO cms_calllog_details
                        (ccd_inst_code, ccd_call_id, ccd_pan_code,
                         ccd_call_seq, ccd_rrn, ccd_devl_chnl, ccd_txn_code,
                         ccd_tran_date, ccd_tran_time, ccd_tbl_names,
                         ccd_colm_name, ccd_old_value, ccd_new_value,
                         ccd_comments, ccd_ins_user, ccd_ins_date,
                         ccd_lupd_user, ccd_lupd_date, ccd_acct_no
                        )
                 VALUES (p_inst_code, p_call_id, v_hash_pan,
                         v_call_seq, p_rrn, p_del_channel, p_txn_code,
                         p_txn_date, p_txn_time, NULL,
                         NULL, NULL, NULL,
                         NULL, p_insuser, SYSDATE,
                         p_insuser, SYSDATE, v_cap_acct_no
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                     ' Error while inserting into cms_calllog_details '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE excp_rej_record;
         END;

         --SN Update Dispute Staus at transactionlog
         BEGIN



IF (v_Retdate>v_Retperiod)
    THEN
            UPDATE transactionlog
               SET dispute_flag = 'C'
             WHERE rrn = p_orgnl_rrn
               AND business_date = p_orgnl_business_date
               AND business_time = p_orgnl_business_time
               AND txn_code = p_orgnl_txn_code
               AND customer_card_no = v_orgnl_hash_pan
               AND delivery_channel = p_orgnl_del_channel
               AND instcode = p_inst_code;
             else
                    UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
               SET dispute_flag = 'C'
             WHERE rrn = p_orgnl_rrn
               AND business_date = p_orgnl_business_date
               AND business_time = p_orgnl_business_time
               AND txn_code = p_orgnl_txn_code
               AND customer_card_no = v_orgnl_hash_pan
               AND delivery_channel = p_orgnl_del_channel
               AND instcode = p_inst_code;
             end if;    

            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_code := '49';
               v_resp_msg := 'Problem in updation of Dispute status ';
               RAISE excp_rej_record;
            END IF;
         EXCEPTION
            WHEN excp_rej_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                     'Error while updating Dispute status'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_rej_record;
         END;

         --EN Update Dispute Staus at transactionlog
         --SN Update Dispute Staus at CMS_DISPUTE_TXNS
         BEGIN
            UPDATE cms_dispute_txns
               SET cdt_dispute_status = 'C'
             WHERE cdt_rrn = p_orgnl_rrn
               AND cdt_txn_code = p_orgnl_txn_code
               AND cdt_pan_code = v_orgnl_hash_pan
               AND cdt_delivery_channel = p_orgnl_del_channel
               AND cdt_inst_code = p_inst_code;

            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_code := '49';
               v_resp_msg := 'Problem in updation of Dispute status ';
               RAISE excp_rej_record;
            END IF;
         EXCEPTION
            WHEN excp_rej_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                     'Error while updating Dispute status'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_rej_record;
         END;
      --EN Update Dispute Staus at CMS_DISPUTE_TXNS
      END IF;
      --sn:Added by Dnyaneshwar J on 23 April 2014 for Mantis-14338
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code,
                cam_stat_code
           INTO v_acct_balance, v_ledger_balance, v_cam_type_code,
                v_cam_stat_code
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_code := '49';
            v_resp_msg := 'Account No. ' || v_cap_acct_no || 'Not found';
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while select Account details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_rej_record;
      END;
       --en:Added by Dnyaneshwar J on 23 April 2014 for Mantis-14338

      --Sn create a entry in txn log
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel,
                      date_time,
                      txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      total_amount,
                      productid, categoryid,
                      auth_id, trans_desc,
                      amount,
                      system_trace_audit_no, instcode, cr_dr_flag,
                      customer_card_no_encr, reversal_code,
                      customer_acct_no, acct_balance, ledger_balance,
                      response_id, error_msg, orgnl_card_no, orgnl_rrn,
                      orgnl_business_date, orgnl_business_time,
                      orgnl_terminal_id, add_ins_date, add_ins_user,
                      ipaddress, add_lupd_user, acct_type, time_stamp,
                      cardstatus,proxy_number
                     )
              VALUES (p_msg_type, p_rrn, p_del_channel,
                      TO_DATE (p_txn_date || ' ' || p_txn_time,
                               'yyyymmdd hh24:mi:ss'
                              ),
                      p_txn_code, V_TXN_TYPE, p_txn_mode, --Added V_TXN_TYPE MVCSD-5513
                      DECODE (v_resp_code, '00', 'C', 'F'), v_resp_code,
                      p_txn_date, p_txn_time, v_hash_pan,
                      TRIM (TO_CHAR (p_orgnl_amount, '99999999999999990.99')),
                      v_prod_code, v_prod_cattype,
                      LPAD (seq_auth_id.NEXTVAL, 6, '0'), v_tran_desc,
                      TRIM (TO_CHAR (p_txn_amount, '999999999999999990.99')),
                      P_STAN, P_INST_CODE, V_CREDIT_DEBIT_FLAG,
                      v_encr_pan, p_reversalcode,
                      V_CAP_ACCT_NO, v_acct_balance, v_ledger_balance,
                      1, v_resp_msg, v_hash_pan, p_orgnl_rrn,
                      --Modified by Dnyaneshwar J on 17 Apr 2014 For Mantis-14224
                      p_txn_date, p_txn_time,
                      NULL, SYSDATE, p_insuser,
                      p_ipaddress, p_insuser, v_cam_type_code, v_timestamp,
                      v_card_stat,v_proxynumber
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '89';
            v_resp_msg :=
                  'Problem while inserting data into transaction log '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      --Sn create a entry in txn log

      --SN create a entry in txn log detl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_system_trace_audit_no,
                      ctd_customer_card_no_encr, ctd_msg_type,
                      ctd_cust_acct_number, ctd_inst_code
                     )
              VALUES (p_del_channel, p_txn_code, NULL,
                      p_txn_mode, p_txn_date, p_txn_time,
                      v_hash_pan, p_txn_amount, '840',
                      p_orgnl_amount, '0.00', NULL,
                      NULL, NULL,
                      NULL, NULL, 'C',
                      v_resp_msg, p_rrn, p_stan,
                      v_encr_pan, p_msg_type,
                      v_cap_acct_no, p_inst_code
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '89';
            v_resp_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      --EN create a entry in txn log detl

      --SN Update File upload status
      BEGIN
         UPDATE cms_fileupload_detl
            SET cfu_upload_stat = 'C',
                cfu_pan_code = v_hash_pan,
                cfu_pan_code_encr = v_encr_pan,
                cfu_lupd_date = SYSDATE,
                cfu_lupd_user = p_insuser,
                cfu_rrn = p_rrn,
                cfu_business_date = p_txn_date,
                cfu_business_time = p_txn_time,
                cfu_acct_no = v_cap_acct_no,
                cfu_delivery_channel = p_del_channel,
                cfu_txn_code = p_txn_code
          WHERE cfu_ref_number = p_orgnl_rrn;

         IF p_txn_code = '88' AND SQL%ROWCOUNT = 0
         THEN
            v_resp_code := '49';
            v_resp_msg := 'Problem in updation of file upload status ';
            RAISE excp_rej_record;
         END IF;
      EXCEPTION
         WHEN excp_rej_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while updating file upload status'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_rej_record;
      END;

      --EN Update File upload status
      p_resp_msg := v_resp_msg;
      --Added by Dnyaneshwar J on 17 Apr 2014 For Mantis-14224
      p_resp_code := v_resp_code;
   --Added by Dnyaneshwar J on 17 Apr 2014 For Mantis-14224
   EXCEPTION                                            --<<Main Exception>>--
      WHEN excp_rej_record
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_del_channel
               AND cms_response_id = v_resp_code;

            p_resp_msg := v_resp_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master1 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '21';
         END;

         IF v_prod_code IS NULL
         THEN
            BEGIN
               SELECT cap_acct_no, cap_prod_code, cap_card_type,
                      cap_card_stat,cap_proxy_number
                 INTO v_cap_acct_no, v_prod_code, v_prod_cattype,
                      v_card_stat,v_proxynumber
                 FROM cms_appl_pan
                WHERE cap_inst_code = p_inst_code
                      AND cap_pan_code = v_hash_pan;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO v_acct_balance, v_ledger_balance, v_cam_type_code
              FROM cms_acct_mast
             WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_balance := 0;
               v_cam_type_code := NULL;
         END;

         IF v_tran_desc IS NULL
         THEN
            BEGIN
             SELECT ctm_tran_desc, ctm_credit_debit_flag,TO_NUMBER (DECODE (CTM_TRAN_TYPE,  'N', '0',  'F', '1'))--Added txn type for to log MVCSD-5513
                INTO v_tran_desc, v_credit_debit_flag,V_TXN_TYPE                    
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = p_txn_code
                  AND ctm_delivery_channel = p_del_channel
                  AND ctm_inst_code = p_inst_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         --SN create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status, response_code,
                         business_date, business_time, customer_card_no,
                         total_amount,
                         productid, categoryid,
                         auth_id, trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, orgnl_card_no, orgnl_rrn,
                         orgnl_business_date, orgnl_business_time,
                         orgnl_terminal_id, add_ins_date, add_ins_user,
                         ipaddress, add_lupd_user, acct_type,
                         time_stamp, cardstatus,proxy_number
                        )
                 VALUES (p_msg_type, p_rrn, p_del_channel,
                         TO_DATE (p_txn_date || ' ' || p_txn_time,
                                  'yyyymmdd hh24:mi:ss'
                                 ),
                         p_txn_code, V_TXN_TYPE, p_txn_mode, --Added for to log MVCSD-5513
                         DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                         p_txn_date, p_txn_time, v_hash_pan,
                         TRIM (TO_CHAR (p_txn_amount, '99999999999999990.99')),
                         v_prod_code, v_prod_cattype,
                         LPAD (seq_auth_id.NEXTVAL, 6, '0'), v_tran_desc,
                         TRIM (TO_CHAR (p_txn_amount, '999999999999999990.99')),
                         p_stan, p_inst_code, v_credit_debit_flag,
                         v_encr_pan, p_reversalcode,
                         v_cap_acct_no, v_acct_balance, v_ledger_balance,
                         v_resp_code, p_resp_msg, v_hash_pan, p_orgnl_rrn,
                         p_txn_date, p_txn_time,
                         NULL, SYSDATE, p_insuser,
                         p_ipaddress, p_insuser, v_cam_type_code,
                         SYSTIMESTAMP, v_card_stat,v_proxynumber
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction log 1 '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN create a entry in txn log
         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_customer_card_no_encr, ctd_msg_type,
                         ctd_cust_acct_number, ctd_inst_code
                        )
                 VALUES (p_del_channel, p_txn_code, NULL,
                         p_txn_mode, p_txn_date, p_txn_time,
                         v_hash_pan, p_txn_amount, '840',
                         p_orgnl_amount, '0.00',
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', p_resp_msg, p_rrn,
                         p_stan,
                         v_encr_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl 1'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
      WHEN OTHERS
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_del_channel
               AND cms_response_id = v_resp_code;

            p_resp_msg := v_resp_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master2 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '21';
         END;

         IF v_prod_code IS NULL
         THEN
            BEGIN
               SELECT cap_acct_no, cap_prod_code, cap_card_type,
                      cap_card_stat,cap_proxy_number
                 INTO v_cap_acct_no, v_prod_code, v_prod_cattype,
                      v_card_stat,v_proxynumber
                 FROM cms_appl_pan
                WHERE cap_inst_code = p_inst_code
                      AND cap_pan_code = v_hash_pan;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO v_acct_balance, v_ledger_balance, v_cam_type_code
              FROM cms_acct_mast
             WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_balance := 0;
               v_cam_type_code := NULL;
         END;

         IF v_tran_desc IS NULL
         THEN
            BEGIN
             SELECT ctm_tran_desc, ctm_credit_debit_flag,TO_NUMBER (DECODE (CTM_TRAN_TYPE,  'N', '0',  'F', '1')) --Added txn type for to log MVCSD-5513
                INTO v_tran_desc, v_credit_debit_flag,V_TXN_TYPE              
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = p_txn_code
                  AND ctm_delivery_channel = p_del_channel
                  AND ctm_inst_code = p_inst_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         --SN create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status, response_code,
                         business_date, business_time, customer_card_no,
                         total_amount,
                         productid, categoryid,
                         auth_id, trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, orgnl_card_no, orgnl_rrn,
                         orgnl_business_date, orgnl_business_time,
                         orgnl_terminal_id, add_ins_date, add_ins_user,
                         ipaddress, add_lupd_user, acct_type,
                         time_stamp, cardstatus,proxy_number
                        )
                 VALUES (p_msg_type, p_rrn, p_del_channel,
                         TO_DATE (p_txn_date || ' ' || p_txn_time,
                                  'yyyymmdd hh24:mi:ss'
                                 ),
                         p_txn_code, V_TXN_TYPE, p_txn_mode, --Added V_TXN_TYPE for to log MVCSD-5513
                         DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                         p_txn_date, p_txn_time, v_hash_pan,
                         TRIM (TO_CHAR (p_txn_amount, '99999999999999990.99')),
                         v_prod_code, v_prod_cattype,
                         LPAD (seq_auth_id.NEXTVAL, 6, '0'), v_tran_desc,
                         TRIM (TO_CHAR (p_txn_amount, '999999999999999990.99')),
                         p_stan, p_inst_code, v_credit_debit_flag,
                         v_encr_pan, p_reversalcode,
                         v_cap_acct_no, v_acct_balance, v_ledger_balance,
                         v_resp_code, p_resp_msg, v_hash_pan, p_orgnl_rrn,
                         p_txn_date, p_txn_time,
                         NULL, SYSDATE, p_insuser,
                         p_ipaddress, p_insuser, v_cam_type_code,
                         SYSTIMESTAMP, v_card_stat,v_proxynumber
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction log 2 '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN create a entry in txn log
         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_customer_card_no_encr, ctd_msg_type,
                         ctd_cust_acct_number, ctd_inst_code
                        )
                 VALUES (p_del_channel, p_txn_code, NULL,
                         p_txn_mode, p_txn_date, p_txn_time,
                         v_hash_pan, p_txn_amount, '840',
                         p_orgnl_amount, '0.00',
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', p_resp_msg, p_rrn,
                         p_stan,
                         v_encr_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction log  dtl 2'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
   END;
EXCEPTION                                               --<<Main Exception>>--
   WHEN OTHERS
   THEN
      p_resp_code := '21';
      p_resp_msg := 'Main Exception -- ' || SUBSTR (SQLERRM, 1, 200);
END;
/
