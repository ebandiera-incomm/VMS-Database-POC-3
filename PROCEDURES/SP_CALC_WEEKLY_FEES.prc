CREATE OR REPLACE PROCEDURE VMSCMS.SP_CALC_WEEKLY_FEES (
   p_instcode   IN       NUMBER,
   p_lupduser   IN       NUMBER,
   p_errmsg     OUT      VARCHAR2
)
AS
   v_raise_exp          EXCEPTION;
   exp_reject_record    EXCEPTION;
   v_err_msg            VARCHAR2 (900)                                := 'OK';
   v_cfm_fee_amt        NUMBER (15, 2);
   v_cpw_waiv_prcnt     cms_card_excpwaiv.cce_waiv_prcnt%TYPE;
   v_waivamt            NUMBER;
   v_rrn1               NUMBER (10)                                 DEFAULT 0;
   v_rrn2               VARCHAR2 (15);
   v_cam_type_code      cms_acct_mast.cam_type_code%TYPE;
   v_dr_cr_flag         cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_debit_amnt         NUMBER;
   v_timestamp          TIMESTAMP;
   v_upd_rec_cnt        NUMBER                                           := 0;
   v_next_mb_date       cms_appl_pan.cap_next_wb_date%TYPE;
   v_delivery_channel   cms_func_mast.cfm_delivery_channel%TYPE  DEFAULT '05';
   v_txn_code           cms_func_mast.cfm_txn_code%TYPE          DEFAULT '97';
   v_no_of_week         NUMBER;
   --Sn Added by Pankaj S. for revised approch
   v_cal_date           DATE;
   v_card_cnt           NUMBER (5);
   v_prdcatg_cnt        NUMBER (5);
   v_diff_day           NUMBER;
   v_days               NUMBER;
   v_previous_card_no   cms_appl_pan.cap_pan_code%TYPE;
   --En Added by Pankaj S. for revised approch
   --Sn Added for JH - weekly Fee Waiver changes
   v_weeklyfee_counter   cms_acct_mast.cam_weeklyfee_counter%TYPE;
   v_week_diff           NUMBER;
   v_weekly_txn          NUMBER;
   v_free_cnt            NUMBER;
   v_free_txn            VARCHAR2 (2);
   v_max_exceed          VARCHAR2 (2);
   v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
   v_chrg_dtl_cnt    NUMBER;     -- Added for FWR 64
   --En Added for JH - weekly Fee Waiver changes


   /******************************************************************************************************
       * Modified By      :  Pankaj S.
       * Modified Date    :  08-Oct-2013
       * Purpose          :  Weekly Fee revised approch
       * Reviewer         :  Dhiraj
       * Reviewed Date    :  08-Oct-2013
       * Build Number     :  RI0024.5_B0003

       * Modified By      :  Pankaj S.
       * Modified Date    :  15-Oct-2013
       * Purpose          :  Review comments changes
       * Reviewer         :  Dhiraj
       * Reviewed Date    :  15-Oct-2013
       * Build Number     :  RI0024.5_B0004

       * Modified By      :  Pankaj S.
       * Modified Date    :  16-Oct-2013
       * Purpose          :  Entry in cms_staments_log is not required if the fee cap is over for the weekly fee(Mantis ID-12729)
       * Reviewer         :  Dhiraj
       * Reviewed Date    :  16-Oct-2013
       * Build Number     :  RI0024.5_B0005

       * Modified By      :  Pankaj S.
       * Modified Date    :  17-Oct-2013
       * Purpose          :  Return count of cards for which fee calculation had done(Mantis ID-12737)
       * Reviewer         :  Dhiraj
       * Reviewed Date    :  16-Oct-2013
       * Build Number     :  RI0024.5_B0006

       * Modified By      :  Pankaj S.
       * Modified Date    :  18-Oct-2013
       * Purpose          :  Weekly fees is getting successful even for insufficient fee amount for the account (Mantis ID-12754 and 12755)
       * Reviewer         :  Dhiraj
       * Reviewed Date    :  18-Oct-2013
       * Build Number     :  RI0024.5_B0007

       * Modified By      :  Pankaj S.
       * Modified Date    :  18-Oct-2013
       * Purpose          :  Mantis ID-12766
       * Reviewer         :  Dhiraj
       * Reviewed Date    :  18-Oct-2013
       * Build Number     :  RI0024.5_B0008
       
       * Modified By      : Pankaj S.
       * Modified Date    : 07-Jan-2014
       * Modified for     : JH - weekly Fee Waiver changes
       * Reviewer         : Dhiraj
       * Reviewed Date    : 07-Jan-2014
       * Build Number     : RI0027_B0003
       
      * Modified By      : Sai Prasad.
      * Modified Date    : 22-Jan-2014
      * Modified for     : Mantis - 0013511  (JH-95, 96, 97 & 98)
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : RI0027_B0004
      
    * modified by       : RAVI N
    * modified Date     : FEB-05-14
    * modified reason   : MVCSD-4471 
    * modified reason   : 
    * Reviewer          : DHIRAJ 
    * Reviewed Date     :  
    * Build Number      : RI0027.1_B0001
    
     * Modified By      : Revathi D
     * Modified Date    : 02-APR-2014
     * Modified for     : 
     * Modified Reason  : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
                          CMS_STATEMENTS_LOG,TRANSACTIONLOG.
                          
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 06-APR-2014
     * Build Number     : CMS3.5.1_RI0027.2_B0004
  
    * modified by       : Amudhan S
    * modified Date     : 23-may-14
    * modified for      : FWR 64 
    * modified reason   : To restrict clawback fee entries as per the configuration done by user.
    * Reviewer          : spankaj
    * Build Number      : RI0027.3_B0001    
    
    * modified by       : Ramesh A
    * modified Date     : 21-July-14
    * modified for      : 15544 
    * modified reason   : Fees entries not logging in activity tab after the claw back count has been reached 
    * Reviewer          : spankaj
    * Build Number      : RI0027.3_B0005

    * Modified by      : Pankaj S.
    * Modified Date    : 07/Oct/2016
    * PURPOSE          : FSS-4755
    * Review           : Saravana 
    * Build Number     : VMSGPRHOST_4.10    
    
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
   ***********************************************************************************************************/
   CURSOR cardfee
   IS
      SELECT cfm_fee_code, cfm_fee_amt, cce_pan_code, cce_pan_code_encr,
             cce_crgl_catg, cce_crgl_code, cce_crsubgl_code, cce_cracct_no,
             cce_drgl_catg, cce_drgl_code, cce_drsubgl_code, cce_dracct_no,
             cff_fee_plan, cap_active_date, cfm_date_assessment,
             cfm_clawback_flag, cfm_proration_flag, cft_fee_freq,
             cft_feetype_code, cap_next_mb_date, cap_card_stat,
             cfm_feecap_flag, cap_acct_no, cap_prod_code, cap_card_type,
             cap_acct_id, cfm_free_txncnt, cfm_txnfree_amt, cfm_feeamnt_type,
             cap_next_wb_date, cce_valid_from, cff_ins_date,
             cfm_crfree_txncnt, cfm_max_limit, --Added for JH - weekly Fee Waiver changes
             CFM_FEE_DESC--Added on 03/02/2014 for regarding  MVCSD0-4471
        FROM cms_fee_mast,
             cms_card_excpfee,
             cms_fee_types,
             cms_fee_feeplan,
             cms_appl_pan
       WHERE cfm_inst_code = p_instcode
         AND cfm_inst_code = cce_inst_code
         AND cce_fee_plan = cff_fee_plan
         AND cff_fee_code = cfm_fee_code
         AND (   (    cce_valid_to IS NOT NULL
                  AND (TRUNC (SYSDATE) BETWEEN TRUNC (cce_valid_from)
                                           AND TRUNC (cce_valid_to)
                      )
                 )                   --TRUNC added for Review comments changes
              OR (    cce_valid_to IS NULL
                  AND TRUNC (SYSDATE) >= TRUNC (cce_valid_from)
                 )
             )                       --TRUNC added for Review comments changes
         AND cfm_feetype_code = cft_feetype_code
         AND cft_inst_code = cfm_inst_code
         AND cap_card_stat NOT IN ('9')
         AND cft_fee_freq = 'W'
         --AND cft_fee_type = 'W'
         AND cap_pan_code = cce_pan_code;

   --Sn Cursor added by Pankaj S. to get fee details attached to product category(Revised approch)
   CURSOR prodcatgfee
   IS
      SELECT cfm_fee_code, cfm_fee_amt, cpf_prod_code, cpf_card_type,
             cpf_crgl_catg, cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no,
             cpf_drgl_catg, cpf_drgl_code, cpf_drsubgl_code, cpf_dracct_no,
             cff_fee_plan, cfm_date_assessment, cfm_clawback_flag,
             cfm_proration_flag, cft_fee_freq, cft_feetype_code, cap_pan_code,
             cap_pan_code_encr, cap_active_date, cap_next_mb_date,
             cap_card_stat, cfm_feecap_flag, cap_acct_no, cap_prod_code,
             cap_card_type, cap_acct_id, cfm_free_txncnt, cfm_txnfree_amt,
             cfm_feeamnt_type, cap_next_wb_date, cpf_valid_from, cff_ins_date,
             cfm_crfree_txncnt, cfm_max_limit,        --Added for JH - weekly Fee Waiver changes     
             CFM_FEE_DESC--Added on 03/02/2014 for regarding  MVCSD0-4471
        FROM cms_fee_mast,
             cms_prodcattype_fees,
             cms_fee_types,
             cms_fee_feeplan,
             cms_appl_pan
       WHERE cfm_inst_code = p_instcode
         AND cfm_inst_code = cpf_inst_code
         AND cff_fee_plan = cpf_fee_plan
         AND cff_fee_code = cfm_fee_code
         AND (   (    cpf_valid_to IS NOT NULL
                  AND (TRUNC (SYSDATE) BETWEEN TRUNC (cpf_valid_from)
                                           AND TRUNC (cpf_valid_to)
                      )
                 )                   --TRUNC added for Review comments changes
              OR (    cpf_valid_to IS NULL
                  AND TRUNC (SYSDATE) >= TRUNC (cpf_valid_from)
                 )
             )                       --TRUNC added for Review comments changes
         AND cfm_feetype_code = cft_feetype_code
         AND cft_inst_code = cfm_inst_code
         AND cap_prod_code = cpf_prod_code
         AND cap_card_type = cpf_card_type
         AND cap_inst_code = cpf_inst_code
         AND cap_card_stat NOT IN ('9')
         AND cft_fee_freq = 'W';

         --AND cft_fee_type = 'W';
   --En Cursor added by Pankaj S. to get fee details attached to product category(Revised approch)

   --Sn Cursor added by Pankaj S. to get fee details attached to product(Revised approch)
   CURSOR prodfee
   IS
      SELECT cfm_fee_code, cfm_fee_amt, cpf_prod_code, cpf_crgl_catg,
             cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no, cpf_drgl_catg,
             cpf_drgl_code, cpf_drsubgl_code, cpf_dracct_no, cff_fee_plan,
             cfm_date_assessment, cfm_clawback_flag, cfm_proration_flag,
             cft_fee_freq, cft_feetype_code, cap_pan_code, cap_pan_code_encr,
             cap_active_date, cap_next_mb_date, cap_card_stat,
             cfm_feecap_flag, cap_acct_no, cap_card_type, cap_prod_code,
             cap_acct_id, cfm_free_txncnt, cfm_txnfree_amt, cfm_feeamnt_type,
             cap_next_wb_date, cpf_valid_from, cff_ins_date,
             cfm_crfree_txncnt, cfm_max_limit,--Added for JH - weekly Fee Waiver changes
             CFM_FEE_DESC--Added on 03/02/2014 for regarding  MVCSD0-4471
        FROM cms_fee_mast,
             cms_prod_fees,
             cms_fee_types,
             cms_fee_feeplan,
             cms_appl_pan
       WHERE cfm_inst_code = p_instcode
         AND cfm_inst_code = cpf_inst_code
         AND cff_fee_plan = cpf_fee_plan
         AND cff_fee_code = cfm_fee_code
         AND (   (    cpf_valid_to IS NOT NULL
                  AND (TRUNC (SYSDATE) BETWEEN TRUNC (cpf_valid_from)
                                           AND TRUNC (cpf_valid_to)
                      )
                 )                   --TRUNC added for Review comments changes
              OR (    cpf_valid_to IS NULL
                  AND TRUNC (SYSDATE) >= TRUNC (cpf_valid_from)
                 )
             )                       --TRUNC added for Review comments changes
         AND cfm_feetype_code = cft_feetype_code
         AND cft_inst_code = cfm_inst_code
         AND cap_prod_code = cpf_prod_code
         AND cap_inst_code = cpf_inst_code
         AND cap_card_stat NOT IN ('9')
         AND cft_fee_freq = 'W';

       --  AND cft_fee_type = 'W'
   --En Cursor added by Pankaj S. to get fee details attached to product(Revised approch)

   --Sn Procedure to log weekly fee cal error
   PROCEDURE lp_weekly_fee_err_log (
      p_ins_code      IN   NUMBER,
      p_lupduser      IN   NUMBER,
      p_card_number   IN   VARCHAR2,
      p_attach_type   IN   VARCHAR2,
      p_err_msg       IN   VARCHAR2
   )
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO cms_wfee_erlog
                  (cwe_inst_code, cwe_pan_code, cwe_atch_type, cwe_err_msg,
                   cwe_ins_user, cwe_ins_date
                  )
           VALUES (p_ins_code, p_card_number, p_attach_type, p_err_msg,
                   p_lupduser, SYSDATE
                  );

      COMMIT;
   END lp_weekly_fee_err_log;

   --En Procedure to log weekly fee cal error

   --Sn Procedure to cal weekly fee
   PROCEDURE lp_weekly_fee_calc (
      p_date_assessment        IN       VARCHAR2,
      p_proration              IN       VARCHAR2,
      p_fee_amnt               IN       NUMBER,
      p_feeplan_actvate_date   IN       DATE,
      p_feetoplan_attch_date   IN       DATE,
      p_pan_code               IN       VARCHAR2,
      p_inst_code              IN       NUMBER,
      p_capactive_date         IN       DATE,
      p_wb_date                IN       DATE,
      p_feeamount              OUT      NUMBER,
      p_errmsg                 OUT      VARCHAR2,
      p_no_of_weeek            OUT      VARCHAR2
   )
   AS
      v_fee_amnt               cms_acct_mast.cam_acct_bal%TYPE;
      v_prev_week_first_date   DATE;
      v_prev_week_end_date     DATE;
      v_tot_days               NUMBER;
      v_activation_day         NUMBER;
      v_monfee_cardcnt         NUMBER;
      v_calc_date              DATE;
      v_next_week_date         DATE;
      v_diff_day               NUMBER;
      v_total_week             NUMBER;
   BEGIN
      p_errmsg := 'OK';

      IF p_date_assessment = 'FD'
      THEN
         IF p_capactive_date < SYSDATE AND p_wb_date IS NULL
         THEN
            v_calc_date := SYSDATE;
            v_total_week := 1;

            SELECT TRUNC (SYSDATE) - TRUNC (p_capactive_date)
              INTO v_diff_day
              FROM DUAL;

            SELECT TO_CHAR (TO_DATE (p_capactive_date, 'dd-mm-yyyy'), 'D')
              INTO v_activation_day
              FROM DUAL;

            IF v_diff_day > 7
            THEN
               v_fee_amnt := p_fee_amnt;
            ELSE
               IF     p_proration = 'Y'
                  AND (v_calc_date IS NULL OR v_calc_date < p_capactive_date
                      )
               THEN
                  v_fee_amnt := ((p_fee_amnt / 7) * (7 - v_activation_day));
               ELSE
                  v_fee_amnt := p_fee_amnt;
               END IF;
            END IF;
         ELSIF p_wb_date IS NOT NULL AND p_wb_date <= SYSDATE
         THEN
            SELECT FLOOR ((TRUNC (SYSDATE) - TRUNC (p_wb_date)) / 7)
              INTO v_total_week
              FROM DUAL;

            v_fee_amnt := p_fee_amnt;
         ELSE
            p_errmsg := 'NO FEES';
            v_fee_amnt := 0;
         END IF;

         p_no_of_weeek := v_total_week;
         p_feeamount := v_fee_amnt;
      END IF;
   /* IF p_calc_date IS NULL OR p_calc_date < p_capactive_date
    THEN
       IF p_date_assessment = 'FD'
       THEN
          v_calc_date := SYSDATE;
       END IF;
    ELSE
       v_calc_date := p_calc_date;
    END IF;

    IF p_date_assessment = 'FD'
    THEN
       SELECT NEXT_DAY (SYSDATE - 7, 'SUNDAY') - 1,
              NEXT_DAY (SYSDATE - 14, 'SUNDAY'),
              NEXT_DAY (SYSDATE, 'SUNDAY'),
              TO_CHAR (TO_DATE (p_capactive_date, 'dd-mm-yyyy'), 'D')
         INTO v_prev_week_end_date,
              v_prev_week_first_date,
              v_next_week_date,
              v_activation_day
         FROM DUAL;

       IF     ((TRUNC (v_calc_date) > TRUNC (v_prev_week_first_date)))
          AND ((TRUNC (v_calc_date) <= TRUNC (v_next_week_date)))
          AND (    TRUNC (v_calc_date) >= TRUNC (v_prev_week_end_date)
               AND TRUNC (v_calc_date) <= TRUNC (v_next_week_date)
              )
       THEN
          IF     p_proration = 'Y'
             AND (p_calc_date IS NULL OR p_calc_date < p_capactive_date)
          THEN
             v_fee_amnt := ((p_fee_amnt / 7) * (7 - v_activation_day));
          ELSE
             v_fee_amnt := p_fee_amnt;
          END IF;

          p_errmsg := 'OK';
       ELSE
          p_errmsg := 'NO FEES';
          v_fee_amnt := 0;
       END IF;

       p_feeamount := v_fee_amnt;
    END IF;*/
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
                   'Error in LP_WEEKLY_FEE_CALC ' || SUBSTR (SQLERRM, 1, 200);
   END lp_weekly_fee_calc;

   --En Procedure to cal weekly fee

   --Sn Procedure to log entry into txnlog
   PROCEDURE lp_transaction_log (
      p_instcode           IN   NUMBER,
      p_hashpan            IN   VARCHAR2,
      p_encrpan            IN   VARCHAR2,
      p_rrn                IN   VARCHAR2,
      p_delivery_channel   IN   VARCHAR2,
      p_business_date      IN   VARCHAR2,
      p_business_time      IN   VARCHAR2,
      p_acct_number        IN   VARCHAR2,
      p_acct_bal           IN   VARCHAR2,
      p_ledger_bal         IN   VARCHAR2,
      p_fee_amnt           IN   VARCHAR2,
      p_auth_id            IN   VARCHAR2,
      p_tran_desc          IN   VARCHAR2,
      p_tran_code          IN   VARCHAR2,
      p_response_id        IN   VARCHAR2,
      p_card_curr          IN   VARCHAR2,
      p_waiv_amnt          IN   NUMBER,
      p_fee_code           IN   VARCHAR2,
      p_fee_plan           IN   VARCHAR2,
      p_cr_acctno          IN   VARCHAR2,
      p_dr_acctno          IN   VARCHAR2,
      p_attach_type        IN   VARCHAR2,
      p_card_stat          IN   VARCHAR2,
      p_cam_type_code      IN   VARCHAR2,
      p_timestamp          IN   TIMESTAMP,
      p_prod_code          IN   VARCHAR2,
      p_prod_cattype       IN   VARCHAR2,
      p_dr_cr_flag         IN   VARCHAR2,
      p_err_msg            IN   VARCHAR2
   )
   AS
   BEGIN
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time,
                      txn_code, txn_type,
                      txn_status,
                      response_code,
                      business_date, business_time, customer_card_no,
                      bank_code,
                      total_amount,
                      auth_id, trans_desc, amount, instcode,
                      customer_card_no_encr, customer_acct_no, acct_balance,
                      ledger_balance, response_id, txn_mode, currencycode,
                      tranfee_amt,
                      feeattachtype, fee_plan, feecode, tranfee_cr_acctno,
                      tranfee_dr_acctno, cardstatus, acct_type,
                      time_stamp, productid, categoryid,
                      cr_dr_flag, error_msg,
                      reversal_code  --Added for LYFEHOST-98
                     )
              VALUES ('0200', p_rrn, p_delivery_channel, SYSDATE,
                      p_tran_code, '1',
                      DECODE (p_response_id, '1', 'C', 'F'),
                      DECODE (p_response_id, '1', '00','21','89','15','51'),  --Modified for LYFEHOST-98
                      p_business_date, p_business_time, p_hashpan,
                      p_instcode,
                      TRIM (TO_CHAR ((  NVL (p_fee_amnt, 0)
                                      - NVL (p_waiv_amnt, 0)
                                     ),
                                     '99999999999999990.99'
                                    )
                           ),
                      p_auth_id, p_tran_desc, '0.00', p_instcode,
                      p_encrpan, p_acct_number, ROUND(NVL (p_acct_bal, 0),2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                      ROUND(NVL (p_ledger_bal, 0),2), p_response_id, 0, p_card_curr,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                      TRIM (TO_CHAR ((  NVL (p_fee_amnt, 0)
                                      - NVL (p_waiv_amnt, 0)
                                     ),
                                     '99999999999999990.99'
                                    )
                           ),
                      p_attach_type, p_fee_plan, p_fee_code, p_cr_acctno,
                      p_dr_acctno, p_card_stat, p_cam_type_code,
                      p_timestamp, p_prod_code, p_prod_cattype,
                      p_dr_cr_flag, p_err_msg,
                      0 --Added for LYFEHOST-98
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while inserting into transactionlog-'
               || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no, ctd_txn_curr,
                      ctd_fee_amount, ctd_waiver_amount, ctd_bill_curr,
                      ctd_process_flag,
                      ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_customer_card_no_encr,
                      ctd_cust_acct_number
                     )
              VALUES (p_delivery_channel, p_tran_code, '1',
                      '0200', 0, p_business_date,
                      p_business_time, p_hashpan, p_card_curr,
                      p_fee_amnt, p_waiv_amnt, p_card_curr,
                      DECODE (p_response_id, '1', 'Y', 'F'),
                      DECODE (p_response_id, '1', 'Successful', p_errmsg),
                      p_rrn, p_instcode, p_encrpan,
                      p_acct_number
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while inserting into cms_transaction_log_dtl-'
               || SUBSTR (SQLERRM, 1, 200);
      END;
   END lp_transaction_log;

   --En Procedure to log entry into txnlog

   --Sn Procedure to update Fee
   PROCEDURE lp_fee_update_log (
      p_instcode       IN       NUMBER,
      p_hashpan        IN       VARCHAR2,
      p_encrpan        IN       VARCHAR2,
      p_fee_code       IN       NUMBER,
      p_fee_amnt       IN       NUMBER,
      p_fee_plan       IN       VARCHAR2,
      p_cr_glcatg      IN       VARCHAR2,
      p_cr_glcode      IN       VARCHAR2,
      p_cr_subglcode   IN       VARCHAR2,
      p_cr_acctno      IN       VARCHAR2,
      p_dr_glcatg      IN       VARCHAR2,
      p_dr_glcode      IN       VARCHAR2,
      p_dr_subglcode   IN       VARCHAR2,
      p_dr_acctno      IN       VARCHAR2,
      p_clawback       IN       VARCHAR2,
      p_fee_freq       IN       VARCHAR2,
      p_feetype_code   IN       VARCHAR2,
      p_lupduser       IN       VARCHAR2,
      p_waiv_amnt      IN       NUMBER,
      p_attach_type    IN       VARCHAR2,
      p_card_stat      IN       VARCHAR2,
      p_acct_no        IN       VARCHAR2,
      p_prod_code      IN       VARCHAR2,
      p_card_type      IN       NUMBER,
      p_free_txn       IN       VARCHAR2, --Added for JH-Waiver changes
      p_fee_desc       IN       VARCHAR2,--Added  on 03/02/14 for MVCSD-4471
      p_errmsg         OUT      VARCHAR2
   )
   AS
      v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
      v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
      v_acct_number        cms_appl_pan.cap_acct_no%TYPE;
      v_auth_id            transactionlog.auth_id%TYPE;
      v_business_date      VARCHAR2 (10);
      v_business_time      VARCHAR2 (10);
      v_txn_mode           cms_func_mast.cfm_txn_mode%TYPE        DEFAULT '0';
      v_delivery_channel   cms_func_mast.cfm_delivery_channel%TYPE
                                                                 DEFAULT '05';
      v_txn_code           cms_func_mast.cfm_txn_code%TYPE       DEFAULT '97';
      v_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      v_narration          cms_statements_log.csl_trans_narrration%TYPE;
      v_pan_code           VARCHAR2 (19);
      v_clawback_amnt      cms_acct_mast.cam_acct_bal%TYPE;
      v_file_status        cms_charge_dtl.ccd_file_status%TYPE    DEFAULT 'N';
      v_clawback_count     NUMBER;
      v_fee_amnt           cms_acct_mast.cam_acct_bal%TYPE;
      v_bin_curr            CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
      v_card_curr          transactionlog.currencycode%TYPE;
      v_resp_code          transactionlog.response_id%TYPE;

   BEGIN
      p_errmsg := 'OK';

      BEGIN
         SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'), TO_CHAR (SYSDATE, 'HH24MISS')
           INTO v_business_date, v_business_time
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                    'Error while selecting date-' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      v_rrn1 := v_rrn1 + 1;
      v_rrn2 := 'WF' || v_business_date || v_rrn1;
      v_pan_code := fn_dmaps_main (p_encrpan);


      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no, cam_type_code
               INTO v_acct_bal, v_ledger_bal, v_acct_number, v_cam_type_code
               FROM cms_acct_mast
              WHERE cam_inst_code = p_instcode AND cam_acct_no = p_acct_no
         FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg := 'Account Details Not Found in Master';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while selecting data from Account Master-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      v_fee_amnt := p_fee_amnt - p_waiv_amnt;

      --v_pan_code := fn_dmaps_main (p_encrpan);  --Commented by Pankaj S.
      
      BEGIN
--         SELECT cip_param_value
--           INTO bin_curr
--           FROM cms_inst_param
--          WHERE cip_inst_code = p_instcode AND cip_param_key = 'CURRENCY';

         SELECT TRIM (cbp_param_value) 
	 INTO v_bin_curr 
	 FROM cms_bin_param WHERE cbp_param_name = 'Currency' 
	 AND cbp_inst_code= p_instcode
	 AND cbp_profile_code = (select  cpc_profile_code from 
	cms_prod_cattype where cpc_prod_code = p_prod_code and
         cpc_card_type = p_card_type  and cpc_inst_code=p_instcode);			 
				 
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg := 'Currency parameter not defined for PROFILE';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error in selecting BIN currency-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT ctm_tran_desc, ctm_credit_debit_flag
           INTO v_tran_desc, v_dr_cr_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = v_txn_code
            AND ctm_delivery_channel = v_delivery_channel
            AND ctm_inst_code = p_instcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while selecting transaction desc-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         sp_convert_curr (p_instcode,
                          v_bin_curr,
                          v_pan_code,
                          v_fee_amnt,
                          SYSDATE,
                          v_fee_amnt,
                          v_card_curr,
                          p_errmsg,
                          p_prod_code,
                          p_card_type
                         );

         IF p_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_errmsg :=
                'Error from currency conversion-' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF p_clawback = 'N'
      THEN
        --Sn Modified for LYFEHOST-98
        IF v_fee_amnt=0 OR (v_acct_bal > 0 AND (v_acct_bal >= v_fee_amnt))THEN
          v_debit_amnt := v_fee_amnt;
        ELSE
          v_resp_code:='15';
          p_errmsg :='INSUFFICIENT BALANCE';
          RAISE exp_reject_record;
        END IF;
        /*IF v_acct_bal > 0
         THEN
            IF (v_acct_bal >= v_fee_amnt)
            THEN
               v_debit_amnt := v_fee_amnt;
            --v_fee_amount := p_fee_amnt;
            ELSE
               v_debit_amnt := v_acct_bal;
            -- v_fee_amount := 0;
            END IF;
         ELSE
            -- v_fee_amount:=p_fee_amnt;
            v_debit_amnt := 0;
         END IF;*/
         --En Modified for LYFEHOST-98

         v_clawback_amnt := 0;
      ELSE
         IF v_acct_bal > 0
         THEN
            IF (v_acct_bal >= v_fee_amnt)
            THEN
               v_debit_amnt := v_fee_amnt;
               v_clawback_amnt := 0;
            ELSE
               v_debit_amnt := v_acct_bal;
               v_clawback_amnt := v_fee_amnt - v_debit_amnt;
            END IF;
         ELSE
            v_clawback_amnt := v_fee_amnt;
            v_debit_amnt := 0;
         END IF;
      END IF;

      IF (v_debit_amnt > 0) OR (v_clawback_amnt > 0)
      THEN
         BEGIN
            UPDATE cms_acct_mast
               SET cam_acct_bal = ROUND(cam_acct_bal - v_debit_amnt,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                   cam_ledger_bal = ROUND(cam_ledger_bal - v_debit_amnt,2)--Modified by Revathi on 02-APR-2014 for 3decimal place issue
             WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_instcode;

            IF SQL%ROWCOUNT = 0
            THEN
               p_errmsg := 'Balances not updated';
               -- || SUBSTR (SQLERRM, 1, 200);  --MOdified by Pankaj S.
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                  'Error while updating balances-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      IF (v_debit_amnt > 0) OR (p_clawback = 'Y' AND v_clawback_amnt > 0) OR p_free_txn = 'Y'
       --v_clawback_amnt condition added for Mantis ID 12729 --p_free_txn='Y' added by Pankaj S for JH weekly fee wavier
      THEN
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO v_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                  'Error while generating authid-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
         --Start--Added on 03/02/2014 for regarding  MVCSD0-4471
         /*
            IF TRIM (v_tran_desc) IS NOT NULL
            THEN
               v_narration := v_tran_desc || '/';
            END IF;

            IF TRIM (v_auth_id) IS NOT NULL
            THEN
               v_narration := v_narration || v_auth_id || '/';
            END IF;

            IF TRIM (v_acct_number) IS NOT NULL
            THEN
               v_narration := v_narration || v_acct_number || '/';
            END IF;

            IF TRIM (v_business_date) IS NOT NULL
            THEN
               v_narration := v_narration || v_business_date;
            END IF;
            */
            v_narration:=p_fee_desc;
            --Start--Added on 03/02/2014 for regarding  MVCSD0-4471
           --Sn Added by Pankaj S .for JH-Weekly Fee wavier
            IF p_free_txn = 'Y' THEN
               v_narration := 'Waived weekly fee';
               v_tran_desc := 'Waived weekly fee';
            END IF;
           --En Added by Pankaj S .for JH-Weekly Fee wavier

         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting narration-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         v_timestamp := SYSTIMESTAMP; -- Added on 17-Apr-2013 for defect 10871

         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_acct_no, csl_opening_bal,
                         csl_trans_amount, csl_trans_type, csl_trans_date,
                         csl_closing_balance, csl_trans_narrration,
                         csl_pan_no_encr, csl_rrn, csl_auth_id,
                         csl_business_date, csl_business_time, txn_fee_flag,
                         csl_delivery_channel, csl_inst_code, csl_txn_code,
                         csl_ins_date, csl_ins_user,
                         csl_panno_last4digit,
                         csl_acct_type, csl_time_stamp, csl_prod_code,csl_card_type
                        )
                 VALUES (p_hashpan, v_acct_number,ROUND(v_ledger_bal,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         ROUND(v_debit_amnt,2), 'DR', SYSDATE,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         ROUND(v_ledger_bal - v_debit_amnt,2), v_narration,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         p_encrpan, v_rrn2, v_auth_id,
                         v_business_date, v_business_time, 'Y',
                         v_delivery_channel, p_instcode, v_txn_code,
                         SYSDATE, 1,
                         (SUBSTR (v_pan_code,
                                  LENGTH (v_pan_code) - 3,
                                  LENGTH (v_pan_code)
                                 )
                         ),
                         v_cam_type_code, v_timestamp, p_prod_code,p_card_type
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error creating entry in statement log-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         IF (v_debit_amnt > 0)
         THEN                            --condition added for Mantis ID 12729
            BEGIN
               sp_ins_eodupdate_acct_cmsauth (v_rrn2,
                                              NULL,
                                              v_delivery_channel,
                                              v_txn_code,
                                              v_txn_mode,
                                              SYSDATE,
                                              v_pan_code,
                                              p_cr_acctno,
                                              v_debit_amnt,
                                              'C',
                                              p_instcode,
                                              p_errmsg
                                             );

               IF p_errmsg <> 'OK'
               THEN
                  p_errmsg :=
                      'Error from SP_INS_EODUPDATE_ACCT_CMSAUTH-' || p_errmsg;
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               --Sn Added by Pankaj S. during revised approch changes
               WHEN exp_reject_record
               THEN
                  RAISE;
               --En Added by Pankaj S. during revised approch changes
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH-'
                     || SUBSTR (SQLERRM, 1, 250);
                  RAISE exp_reject_record;
            END;
         END IF;

         IF NVL (v_previous_card_no, '1') <> p_hashpan
         THEN
            v_upd_rec_cnt := v_upd_rec_cnt + 1;
            v_previous_card_no := p_hashpan;
         END IF;
      END IF;

      BEGIN
         IF p_clawback = 'Y' AND v_clawback_amnt > 0
         THEN
            v_file_status := 'C';

        -- Added for FWR 64 --     
                  begin
                    select cfm_clawback_count into v_tot_clwbck_count from cms_fee_mast where cfm_fee_code=P_FEE_CODE; 
                      
                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN                 
                    p_errmsg  := 'Clawback count not configured '|| SUBSTR(SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                  END;
                   
                BEGIN
                                SELECT COUNT (*)
                                  INTO v_chrg_dtl_cnt
                                  FROM cms_charge_dtl
                                 WHERE      ccd_inst_code = p_instcode
                                         AND ccd_delivery_channel = v_delivery_channel
                                         AND ccd_txn_code = v_txn_code
                                         --AND ccd_pan_code = P_HASHPAN  --Commented for FSS-4755
                                         AND ccd_acct_no = v_acct_number and CCD_FEE_CODE=P_FEE_CODE 
                     and ccd_clawback ='Y';
                            EXCEPTION
                                WHEN OTHERS 
                                THEN                                
                                    p_errmsg :=
                                        'Error occured while fetching count from cms_charge_dtl'
                                        || SUBSTR (SQLERRM, 1, 100);
                                    RAISE EXP_REJECT_RECORD;
                            END;
            -- Added for fwr 64 
            
            BEGIN
               SELECT COUNT (*)
                 INTO v_clawback_count
                 FROM cms_acctclawback_dtl
                WHERE cad_inst_code = p_instcode
                  AND cad_delivery_channel = v_delivery_channel
                  AND cad_txn_code = v_txn_code
                  AND cad_pan_code = p_hashpan
                  AND cad_acct_no = v_acct_number;

               IF v_clawback_count = 0
               THEN
                  BEGIN
                     INSERT INTO cms_acctclawback_dtl
                                 (cad_inst_code, cad_acct_no, cad_pan_code,
                                  cad_pan_code_encr, cad_clawback_amnt,
                                  cad_recovery_flag, cad_ins_date,
                                  cad_lupd_date, cad_delivery_channel,
                                  cad_txn_code, cad_ins_user, cad_lupd_user
                                 )
                          VALUES (p_instcode, v_acct_number, p_hashpan,
                                  p_encrpan,ROUND( v_clawback_amnt,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                  'N', SYSDATE,
                                  SYSDATE, v_delivery_channel,
                                  v_txn_code, '1', '1'
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_errmsg :=
                              'Error while inserting Account ClawBack details-'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;
                   ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count then  -- Modified for fwr 64 
                  BEGIN
                     UPDATE cms_acctclawback_dtl
                        SET cad_clawback_amnt =
                                          ROUND( cad_clawback_amnt + v_clawback_amnt,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            cad_recovery_flag = 'N',
                            cad_lupd_date = SYSDATE
                      WHERE cad_inst_code = p_instcode
                        AND cad_acct_no = v_acct_number
                        AND cad_pan_code = p_hashpan
                        AND cad_delivery_channel = v_delivery_channel
                        AND cad_txn_code = v_txn_code;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        p_errmsg :=
                              'No records updated in ACCTCLAWBACK_DTL for pan-'
                           || p_hashpan;
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        p_errmsg :=
                              'Error while Updating ACCTCLAWBACK_DTL-'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while selecting Account ClawBack details-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSIF v_debit_amnt = p_fee_amnt
         THEN
            v_file_status := 'Y';
         ELSE
            v_file_status := 'N';
         END IF;
       
         if v_chrg_dtl_cnt < v_tot_clwbck_count THEN  -- Modified for fwr 64 
         
         BEGIN
            INSERT INTO cms_charge_dtl
                        (ccd_inst_code, ccd_pan_code, ccd_mbr_numb,
                         ccd_acct_no, ccd_fee_freq, ccd_feetype_code,
                         ccd_fee_code, ccd_calc_amt, ccd_expcalc_date,
                         ccd_calc_date, ccd_file_name, ccd_file_date,
                         ccd_ins_user, ccd_lupd_user, ccd_file_status,
                         ccd_rrn, ccd_debited_amnt, ccd_process_msg,
                         ccd_clawback_amnt, ccd_clawback, ccd_fee_plan,
                         ccd_pan_code_encr, ccd_gl_acct_no,
                         ccd_delivery_channel, ccd_txn_code,
                         ccd_feeattachtype
                        )
                 VALUES (p_instcode, p_hashpan, '000',
                         v_acct_number, p_fee_freq, p_feetype_code,
                         p_fee_code,ROUND( p_fee_amnt,2), SYSDATE,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         SYSDATE, 'N', SYSDATE,
                         p_lupduser, p_lupduser, v_file_status,
                         v_rrn2, ROUND(v_debit_amnt,2), p_errmsg,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         ROUND(v_clawback_amnt,2), p_clawback, p_fee_plan,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         p_encrpan, p_cr_acctno,
                         v_delivery_channel, v_txn_code,
                         p_attach_type
                        );
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while inserting into chanrge details-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         else  --Added for Defect id : 15544
           p_errmsg :='CLAW BLACK WAIVED';
         end if;
      END;

      lp_transaction_log (p_instcode,
                          p_hashpan,
                          p_encrpan,
                          v_rrn2,
                          v_delivery_channel,
                          v_business_date,
                          v_business_time,
                          v_acct_number,
                          v_acct_bal - v_debit_amnt,
                          v_ledger_bal - v_debit_amnt,
                          v_debit_amnt,
                          v_auth_id,
                          v_tran_desc,
                          v_txn_code,
                          1,
                          v_card_curr,
                          p_waiv_amnt,
                          p_fee_code,
                          p_fee_plan,
                          p_cr_acctno,
                          p_dr_acctno,
                          p_attach_type,
                          p_card_stat,
                          v_cam_type_code,
                          v_timestamp,
                          p_prod_code,
                          p_card_type,
                          v_dr_cr_flag,
                          p_errmsg
                         );
   EXCEPTION
      WHEN exp_reject_record
      THEN
        -- p_errmsg := 'Error in update account-' ||SUBSTR (SQLERRM, 1, 200);;  --Commented for LYFEHOST-98

         BEGIN
            INSERT INTO cms_charge_dtl
                        (ccd_inst_code, ccd_pan_code, ccd_mbr_numb,
                         ccd_acct_no, ccd_fee_freq, ccd_feetype_code,
                         ccd_fee_code, ccd_calc_amt, ccd_expcalc_date,
                         ccd_calc_date, ccd_file_name, ccd_file_date,
                         ccd_ins_user, ccd_lupd_user, ccd_file_status,
                         ccd_rrn, ccd_process_msg, ccd_fee_plan,
                         ccd_pan_code_encr, ccd_gl_acct_no,
                         ccd_delivery_channel, ccd_txn_code
                        )
                 VALUES (p_instcode, p_hashpan, '000',
                         v_acct_number, p_fee_freq, p_feetype_code,
                         p_fee_code, ROUND(p_fee_amnt,2), SYSDATE,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         SYSDATE, 'N', SYSDATE,
                         p_lupduser, p_lupduser, 'E',
                         v_rrn2, p_errmsg, p_fee_plan,
                         p_encrpan, p_cr_acctno,
                         v_delivery_channel, v_txn_code
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while inserting into CHARGE_DTL 1.0-'
                  || SUBSTR (SQLERRM, 1, 200);
         END;

         IF v_dr_cr_flag IS NULL
         THEN
            BEGIN
               SELECT ctm_credit_debit_flag
                 INTO v_dr_cr_flag
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = v_txn_code
                  AND ctm_delivery_channel = v_delivery_channel
                  AND ctm_inst_code = p_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         --Sn Added for LYFEHOST-98
         IF v_resp_code IS NULL THEN
           v_resp_code:=21;
         END IF;
         --En Added for LYFEHOST-98

         lp_transaction_log (p_instcode,
                             p_hashpan,
                             p_encrpan,
                             v_rrn2,
                             v_delivery_channel,
                             v_business_date,
                             v_business_time,
                             v_acct_number,
                             v_acct_bal, -- -v_debit_amnt,
                             v_ledger_bal, -- -v_debit_amnt,
                             p_fee_amnt,
                             v_auth_id,
                             v_tran_desc,
                             v_txn_code,
                             v_resp_code,--21,  --Modified for LYFEHOST-98
                             v_card_curr,
                             p_waiv_amnt,
                             p_fee_code,
                             p_fee_plan,
                             p_cr_acctno,
                             p_dr_acctno,
                             p_attach_type,
                             p_card_stat,
                             v_cam_type_code,
                             NVL (v_timestamp, SYSTIMESTAMP),
                             p_prod_code,
                             p_card_type,
                             v_dr_cr_flag,
                             p_errmsg
                            );
      WHEN OTHERS
      THEN
         p_errmsg := 'Error in update account-' || SUBSTR (SQLERRM, 1, 200);

         BEGIN
            INSERT INTO cms_charge_dtl
                        (ccd_inst_code, ccd_pan_code, ccd_mbr_numb,
                         ccd_acct_no, ccd_fee_freq, ccd_feetype_code,
                         ccd_fee_code, ccd_calc_amt, ccd_expcalc_date,
                         ccd_calc_date, ccd_file_name, ccd_file_date,
                         ccd_ins_user, ccd_lupd_user, ccd_file_status,
                         ccd_rrn, ccd_process_msg, ccd_fee_plan,
                         ccd_pan_code_encr, ccd_gl_acct_no,
                         ccd_delivery_channel, ccd_txn_code
                        )
                 VALUES (p_instcode, p_hashpan, '000',
                         v_acct_number, p_fee_freq, p_feetype_code,
                         p_fee_code, ROUND(p_fee_amnt,2), SYSDATE,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         SYSDATE, 'N', SYSDATE,
                         p_lupduser, p_lupduser, 'E',
                         v_rrn2, p_errmsg, p_fee_plan,
                         p_encrpan, p_cr_acctno,
                         v_delivery_channel, v_txn_code
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while inserting into CHARGE_DTL 1.1-'
                  || SUBSTR (SQLERRM, 1, 200);
         END;

         IF v_dr_cr_flag IS NULL
         THEN
            BEGIN
               SELECT ctm_credit_debit_flag
                 INTO v_dr_cr_flag
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = v_txn_code
                  AND ctm_delivery_channel = v_delivery_channel
                  AND ctm_inst_code = p_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;

         lp_transaction_log (p_instcode,
                             p_hashpan,
                             p_encrpan,
                             v_rrn2,
                             v_delivery_channel,
                             v_business_date,
                             v_business_time,
                             v_acct_number,
                             v_acct_bal, -- -v_debit_amnt,
                             v_ledger_bal, -- -v_debit_amnt,
                             p_fee_amnt,
                             v_auth_id,
                             v_tran_desc,
                             v_txn_code,
                             21,
                             v_card_curr,
                             p_waiv_amnt,
                             p_fee_code,
                             p_fee_plan,
                             p_cr_acctno,
                             p_dr_acctno,
                             p_attach_type,
                             p_card_stat,
                             v_cam_type_code,
                             NVL (v_timestamp, SYSTIMESTAMP),
                             p_prod_code,
                             p_card_type,
                             v_dr_cr_flag,
                             p_errmsg
                            );
   END lp_fee_update_log;
--En Procedure to update Fee
BEGIN
   IF TRIM (TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY'
   THEN
      BEGIN
         FOR c1 IN cardfee
         LOOP
            v_err_msg := 'OK';

            --Sn Added for JH - weekly Fee Waiver changes
            v_weekly_txn := 0;
            v_free_txn := 'N';
            v_free_cnt := 0;
            --En Added for JH - weekly Fee Waiver changes

            IF c1.cap_active_date IS NOT NULL
            THEN
               BEGIN
               
                  --Sn Added for JH - weekly Fee Waiver changes
                  BEGIN
                     SELECT cam_weeklyfee_counter
                       INTO v_weeklyfee_counter
                       FROM cms_acct_mast
                      WHERE cam_inst_code = p_instcode
                        AND cam_acct_id = c1.cap_acct_id;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        v_err_msg := 'Acct not found 1.0 -' || c1.cap_acct_id;
                        RAISE v_raise_exp;
                     WHEN OTHERS THEN
                        v_err_msg :='Error occured while fetching acct dtls 1.0 -'|| SUBSTR (SQLERRM, 1, 200);
                        RAISE v_raise_exp;
                  END;
                  --En Added for JH - weekly Fee Waiver changes
                  
                  IF c1.cfm_max_limit = 0 OR v_weeklyfee_counter < c1.cfm_max_limit THEN   --Added for JH - Weekly Fee Waiver
               
                  --Sn Added by Pankaj S. for Revised approch
                  BEGIN
                     SELECT GREATEST (c1.cce_valid_from,
                                      c1.cff_ins_date,
                                      c1.cap_active_date
                                     )
                       INTO v_cal_date
                       FROM DUAL;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while getting recent date 1.0 -'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE v_raise_exp;
                  END;

                                       --Sn Added for JH - weekly Fee Waiver changes
                     BEGIN
                        SELECT CEIL ((TRUNC (SYSDATE) - TRUNC (v_cal_date)) / 7)
                          INTO v_week_diff
                          FROM DUAL;
                     EXCEPTION
                        WHEN OTHERS THEN
                           v_err_msg :='Error while getting weekly diff 1.0 -'|| SUBSTR (SQLERRM, 1, 200);
                           RAISE v_raise_exp;
                     END;
                     --En Added for JH - weekly Fee Waiver changes
                     
                     IF  c1.cap_next_wb_date IS NOT NULL AND c1.cap_next_wb_date >= v_cal_date --Modified for JH - weekly Fee Waiver changes
                     THEN
                        --IF c1.cap_next_wb_date>=v_cal_date THEN
                         v_free_cnt := c1.cfm_free_txncnt - v_week_diff +1; -- Added for Mantis 0013511 
                        v_cal_date := c1.cap_next_wb_date - 7;
                      
                        SELECT CEIL ((TRUNC (SYSDATE) - TRUNC (v_cal_date)) / 7)
                          INTO v_week_diff
                          FROM DUAL;
                          
                     --Sn Added for JH - weekly Fee Waiver changes
                      /*  IF c1.cfm_free_txncnt >= v_week_diff THEN
                           IF v_weeklyfee_counter = 0 THEN
                              v_free_cnt :=CEIL ((TRUNC (SYSDATE) - TRUNC (v_cal_date))/ 7);
                           END IF;
                        ELSE
                           v_free_cnt :=c1.cfm_free_txncnt- (v_week_diff- CEIL ((TRUNC (SYSDATE)- TRUNC (v_cal_date))/ 7));
                        END IF;*/
                     --END IF;
                     ELSIF c1.cfm_free_txncnt >= v_week_diff THEN
                        v_free_cnt := v_week_diff;
                     ELSE
                        v_free_cnt := c1.cfm_free_txncnt;
                     END IF;
                     --En Added for JH - weekly Fee Waiver changes
                     
                     SELECT TRUNC (SYSDATE) - TRUNC (v_cal_date)
                       INTO v_diff_day  --Get no of days for which fee need to apply

                     FROM   DUAL;

                     IF v_err_msg = 'OK' THEN

                        FOR i IN 1 .. CEIL (v_diff_day / 7)
                        LOOP
                           IF  c1.cfm_max_limit = 0 OR v_weeklyfee_counter + v_weekly_txn < c1.cfm_max_limit THEN --Added for JH - Weekly Fee Waiver
                              v_max_exceed := 'N';
                           ELSE
                              v_max_exceed := 'Y';
                           END IF;

                        IF c1.cfm_date_assessment = 'FD'
                        THEN
                           IF v_diff_day <= 7
                           THEN
                              v_cfm_fee_amt :=
                                       ((c1.cfm_fee_amt / 7) * (v_diff_day)
                                       );
                           ELSE
                              IF CEIL (v_diff_day / 7) > 2
                              THEN
                                 v_diff_day := v_diff_day - 7;
                              ELSE
                                 v_days := MOD (v_diff_day, 7);

                                 IF v_days <> 0
                                 THEN
                                    v_diff_day := v_days;
                                 END IF;
                              END IF;

                              v_cfm_fee_amt := c1.cfm_fee_amt;
                           END IF;
                              --Sn Added for JH - weekly Fee Waiver changes
                             IF v_free_cnt > 0 and v_week_diff <= v_free_cnt THEN --Added V_free_cnt >0 for 0013511
                                 v_cfm_fee_amt := 0;
                                 v_free_txn := 'Y';
                              ELSE
                                 IF v_max_exceed = 'N' THEN
                                    v_weekly_txn := v_weekly_txn + 1;
                                 END IF;

                                 v_week_diff := v_week_diff - 1;
                              END IF;
                              --En Added for JH - weekly Fee Waiver changes
                           END IF;

                           IF v_max_exceed = 'N' OR v_free_txn = 'Y' THEN --Added for JH - weekly Fee Waiver changes


                       IF c1.cfm_feecap_flag = 'Y'  AND v_free_txn = 'N' THEN  --v_free_txn='N' condition Added for JH - weekly Fee Waiver changes
                           BEGIN
                              sp_tran_fees_cap (p_instcode,
                                                c1.cap_acct_no,
                                                TRUNC (SYSDATE),
                                                v_cfm_fee_amt,
                                                c1.cff_fee_plan,
                                                c1.cfm_fee_code,
                                                v_err_msg
                                               );
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        END IF;

                        BEGIN
                           SELECT cce_waiv_prcnt
                             INTO v_cpw_waiv_prcnt
                             FROM cms_card_excpwaiv
                            WHERE cce_inst_code = p_instcode
                              AND cce_pan_code = c1.cce_pan_code
                              AND cce_fee_code = c1.cfm_fee_code
                              AND cce_fee_plan = c1.cff_fee_plan
                              AND (   (    cce_valid_to IS NOT NULL
                                       AND (TRUNC (SYSDATE)
                                               BETWEEN TRUNC (cce_valid_from)
                                                   AND TRUNC (cce_valid_to)
                                           )
                                      )
                                   --TRUNC added for Review comments changes
                                   OR (    cce_valid_to IS NULL
                                       AND TRUNC (SYSDATE) >=
                                                        TRUNC (cce_valid_from)
                                      )
                                  ); --TRUNC added for Review comments changes

                           v_waivamt :=
                                      (v_cpw_waiv_prcnt / 100) * v_cfm_fee_amt;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_waivamt := 0;
                        END;

                        BEGIN
                           lp_fee_update_log (p_instcode,
                                              c1.cce_pan_code,
                                              c1.cce_pan_code_encr,
                                              c1.cfm_fee_code,
                                              v_cfm_fee_amt,
                                              c1.cff_fee_plan,
                                              c1.cce_crgl_catg,
                                              c1.cce_crgl_code,
                                              c1.cce_crsubgl_code,
                                              c1.cce_cracct_no,
                                              c1.cce_drgl_catg,
                                              c1.cce_drgl_code,
                                              c1.cce_drsubgl_code,
                                              c1.cce_dracct_no,
                                              c1.cfm_clawback_flag,
                                              c1.cft_fee_freq,
                                              c1.cft_feetype_code,
                                              p_lupduser,
                                              v_waivamt,
                                              'C',
                                              c1.cap_card_stat,
                                              c1.cap_acct_no,
                                              c1.cap_prod_code,
                                              c1.cap_card_type,
                                              v_free_txn, --Added for JH-Weekly fee wavier
                                              c1.CFM_FEE_DESC, --Added  on 03/02/14 for MVCSD-4471 
                                              v_err_msg
                                             );

                           --IF v_err_msg <> 'OK'
                           --THEN
                             -- RAISE v_raise_exp;
                           --END IF;
                        EXCEPTION
                           --WHEN v_raise_exp
                          -- THEN
                          --    RAISE;
                           WHEN OTHERS
                           THEN
                              v_err_msg :=
                                    'Error while calling LP_FEE_UPDATE_LOG 1.0 -'
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE v_raise_exp;
                        END;
                       END IF; 
                     END LOOP;

                     --Sn Added by Pankaj S. for Revised approch

                     --Sn Commented by Pankaj S. for Revised approch
                     /*BEGIN
                        lp_weekly_fee_calc
                           (c1.cfm_date_assessment,
                            c1.cfm_proration_flag,
                            c1.cfm_fee_amt,
                            c1.cce_ins_date,
                                   --cap_active_date, --Fee plan activated to card date
                            c1.cff_ins_date,    -- weekly fee attached to fee plan date
                            c1.cce_pan_code,
                            p_instcode,
                            c1.cap_active_date,                  --Card activation date
                            c1.cap_next_wb_date,                     --Weekly Bill date
                            v_cfm_fee_amt,
                            v_err_msg,
                            v_no_of_week
                           );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_err_msg :=
                                 'Error while calling LP_WEEKLY_FEE_CALC -'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE v_raise_exp;
                     END;
                     --En Commented by Pankaj S. for Revised approch
                     IF v_err_msg = 'OK' THEN
                       FOR i IN 1 .. v_no_of_week
                       LOOP
                           IF c1.cfm_feecap_flag = 'Y' THEN
                              BEGIN
                                 sp_tran_fees_cap (p_instcode,
                                                   c1.cap_acct_no,
                                                   TRUNC (SYSDATE),
                                                   v_cfm_fee_amt,
                                                   c1.cff_fee_plan,
                                                   c1.cfm_fee_code,
                                                   v_err_msg
                                                  );
                              EXCEPTION
                                 WHEN OTHERS THEN
                                    NULL;
                              END;
                           END IF;

                           BEGIN
                              SELECT cce_waiv_prcnt
                                INTO v_cpw_waiv_prcnt
                                FROM cms_card_excpwaiv
                               WHERE cce_inst_code = p_instcode
                                 AND cce_pan_code = c1.cce_pan_code
                                 AND cce_fee_code = c1.cfm_fee_code
                                 AND cce_fee_plan = c1.cff_fee_plan
                                 AND ((cce_valid_to IS NOT NULL AND (SYSDATE BETWEEN cce_valid_from AND cce_valid_to))
                                      OR (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from));

                              v_waivamt := (v_cpw_waiv_prcnt / 100) * v_cfm_fee_amt;
                           EXCEPTION
                              WHEN OTHERS THEN
                                 v_waivamt := 0;
                           END;

                           BEGIN
                              lp_fee_update_log (p_instcode,
                                                 c1.cce_pan_code,
                                                 c1.cce_pan_code_encr,
                                                 c1.cfm_fee_code,
                                                 v_cfm_fee_amt,
                                                 c1.cff_fee_plan,
                                                 c1.cce_crgl_catg,
                                                 c1.cce_crgl_code,
                                                 c1.cce_crsubgl_code,
                                                 c1.cce_cracct_no,
                                                 c1.cce_drgl_catg,
                                                 c1.cce_drgl_code,
                                                 c1.cce_drsubgl_code,
                                                 c1.cce_dracct_no,
                                                 c1.cfm_clawback_flag,
                                                 c1.cft_fee_freq,
                                                 c1.cft_feetype_code,
                                                 p_lupduser,
                                                 v_waivamt,
                                                 'C',
                                                 c1.cap_card_stat,
                                                 c1.cap_acct_no,
                                                 c1.cap_prod_code,
                                                 c1.cap_card_type,
                                                 v_err_msg
                                                );
                           EXCEPTION
                              WHEN OTHERS THEN
                                 v_err_msg :='Error while calling LP_FEE_UPDATE_LOG -'|| SUBSTR (SQLERRM, 1, 200);
                                 RAISE v_raise_exp;
                           END;
                        END LOOP;*/
                        --En Commented by Pankaj S. for Revised approch

                     /* IF C1.CFM_DATE_ASSESSMENT = 'FD' THEN
                        IF (C1.CAP_NEXT_WB_DATE IS NULL OR C1.CAP_NEXT_WB_DATE < C1.CAP_ACTIVE_DATE)
                           AND TRUNC(C1.CAP_ACTIVE_DATE) < TRUNC(SYSDATE)
                        THEN
                             IF TRUNC(NEXT_DAY(NEXT_DAY (C1.CAP_ACTIVE_DATE, 'MONDAY'),'MONDAY')) >= TRUNC(SYSDATE) THEN

                              V_NEXT_MB_DATE := NEXT_DAY(NEXT_DAY (C1.CAP_ACTIVE_DATE, 'MONDAY'),'MONDAY');

                             ELSE

                              V_NEXT_MB_DATE := NEXT_DAY (C1.CAP_ACTIVE_DATE, 'MONDAY');

                             END IF;

                        ELSIF C1.CAP_NEXT_WB_DATE IS NOT NULL AND TRUNC(C1.CAP_NEXT_WB_DATE) < TRUNC(SYSDATE)
                        THEN
                           V_NEXT_MB_DATE :=  NEXT_DAY (C1.CAP_NEXT_WB_DATE, 'MONDAY');
                        ELSE
                           V_NEXT_MB_DATE :=  NEXT_DAY (SYSDATE, 'MONDAY');
                        END IF;
                      END IF;*/
                     IF c1.cfm_date_assessment = 'FD'
                     THEN
                        v_next_mb_date := NEXT_DAY (SYSDATE, 'SUNDAY');
                     END IF;

                     BEGIN
                        UPDATE cms_appl_pan
                           SET cap_next_wb_date = v_next_mb_date
                         WHERE cap_pan_code = c1.cce_pan_code
                           --AND cap_card_stat NOT IN ('9')  --Modified by Pankaj S. for revised approch
                           AND cap_inst_code = p_instcode;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_err_msg :=
                                 'No records updated in APPL_PAN 1.0 for pan '
                              || c1.cce_pan_code;
                           RAISE v_raise_exp;
                        END IF;
                     EXCEPTION
                        WHEN v_raise_exp
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_err_msg :=
                                 'Error while upadating APPL_PAN card fee billing date 1.0-'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE v_raise_exp;       --Added for review changes
                     END;
                  END IF;
                     --Sn Added for JH - Weekly Fee Waiver
                     IF v_weekly_txn <> 0 THEN
                        BEGIN
                           UPDATE cms_acct_mast
                              SET cam_weeklyfee_counter =cam_weeklyfee_counter + v_weekly_txn
                            WHERE cam_inst_code = p_instcode
                              AND cam_acct_id = c1.cap_acct_id;

                           IF SQL%ROWCOUNT = 0 THEN
                              v_err_msg :='No records updated in Acct_mast for acct 1.0 -';
                              RAISE v_raise_exp;
                           END IF;
                        EXCEPTION
                           WHEN v_raise_exp THEN
                              RAISE;
                           WHEN OTHERS THEN
                              v_err_msg :='Error while upadating Acct_mast 1.0 -'|| SUBSTR (SQLERRM, 1, 200);
                              RAISE v_raise_exp;
                        END;
                     END IF;
                     --En Added for JH - Weekly Fee Waiver
                  END IF;  --Added for JH-Weekly fee wavier

               EXCEPTION
                  WHEN v_raise_exp
                  THEN
                     --v_err_msg := v_err_msg; --Commented for review changes
                     lp_weekly_fee_err_log (p_instcode,
                                            p_lupduser,
                                            c1.cce_pan_code,
                                            'C',
                                            v_err_msg
                                           );
                  WHEN OTHERS
                  THEN
                     v_err_msg :=
                           'Main exception from card level weekly fee cal-'
                        || SUBSTR (SQLERRM, 1, 200);
                     lp_weekly_fee_err_log (p_instcode,
                                            p_lupduser,
                                            c1.cce_pan_code,
                                            'C',
                                            v_err_msg
                                           );
               END;
            END IF;
         END LOOP;

         --Sn Added by Pankaj S. for Revised approch
         FOR c2 IN prodcatgfee
         LOOP
            v_err_msg := 'OK';
            --Sn Added for JH - weekly Fee Waiver changes
            v_weekly_txn := 0;
            v_free_txn := 'N';
            v_free_cnt := 0;
            --En Added for JH - weekly Fee Waiver changes


            --Sn Fee paln attached to card..?
            BEGIN
               SELECT COUNT
                         (CASE
                             WHEN (    cce_valid_to IS NOT NULL
                                   AND (TRUNC (SYSDATE)
                                           BETWEEN TRUNC (cce_valid_from)
                                               AND TRUNC (cce_valid_to)
                                       )
                                  )  --TRUNC added for Review comments changes
                              OR (    cce_valid_to IS NULL
                                  AND TRUNC (SYSDATE) >=
                                                        TRUNC (cce_valid_from)
                                 )
                                THEN 1
                          --TRUNC added for Review comments changes
                          END
                         )
                 INTO v_card_cnt
                 FROM cms_card_excpfee
                WHERE cce_inst_code = p_instcode
                  AND cce_pan_code = c2.cap_pan_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_card_cnt := 0;
            END;

            --En Fee paln attached to card..?
            IF v_card_cnt = 0
            THEN
               IF c2.cap_active_date IS NOT NULL
               THEN
                  BEGIN
                  
                    --Sn Added for JH - weekly Fee Waiver changes
                     BEGIN
                        SELECT cam_weeklyfee_counter
                          INTO v_weeklyfee_counter
                          FROM cms_acct_mast
                         WHERE cam_inst_code = p_instcode
                           AND cam_acct_id = c2.cap_acct_id;
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                           v_err_msg :='Acct not found 2.0 -' || c2.cap_acct_id;RAISE v_raise_exp;
                        WHEN OTHERS THEN
                           v_err_msg :='Error occured while fetching acct dtls 2.0 -'|| SUBSTR (SQLERRM, 1, 100);
                           RAISE v_raise_exp;
                     END;
                     --En Added for JH - weekly Fee Waiver changes
                     
                     IF c2.cfm_max_limit = 0 OR v_weeklyfee_counter < c2.cfm_max_limit THEN --Added for JH - Weekly Fee Waiver
                     BEGIN
                        SELECT GREATEST (c2.cpf_valid_from,
                                         c2.cff_ins_date,
                                         c2.cap_active_date
                                        )
                          INTO v_cal_date
                          FROM DUAL;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_err_msg :=
                                 'Error while getting recent date 1.1 -'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE v_raise_exp;
                     END;

                                             --Sn Added for JH - weekly Fee Waiver changes
                        BEGIN
                           SELECT CEIL ((TRUNC (SYSDATE)- TRUNC (v_cal_date))/ 7)
                             INTO v_week_diff
                             FROM DUAL;
                        EXCEPTION
                           WHEN OTHERS THEN
                              v_err_msg :='Error while getting weekly diff 2.0 -'|| SUBSTR (SQLERRM, 1, 200);
                              RAISE v_raise_exp;
                        END;
                        --En Added for JH - weekly Fee Waiver changes
                        
                        IF c2.cap_next_wb_date IS NOT NULL AND c2.cap_next_wb_date >= v_cal_date --Modified for JH - weekly Fee Waiver changes
                        THEN
                           --IF c2.cap_next_wb_date>=v_cal_date THEN
                            v_free_cnt := c2.cfm_free_txncnt - v_week_diff +1; -- Added for Mantis 0013511 
                           v_cal_date := c2.cap_next_wb_date - 7;
                            
                           
                          SELECT CEIL ((TRUNC (SYSDATE) - TRUNC (v_cal_date)) / 7)
                          INTO v_week_diff
                          FROM DUAL;
                          
                           --Sn Added for JH - weekly Fee Waiver changes
                          /* IF c2.cfm_free_txncnt >= v_week_diff THEN
                              IF v_weeklyfee_counter = 0 THEN
                                 v_free_cnt :=CEIL((TRUNC (SYSDATE) - TRUNC (v_cal_date))/7);
                              END IF;
                           ELSE
                              v_free_cnt := c2.cfm_free_txncnt- (  v_week_diff-CEIL((TRUNC(SYSDATE)-TRUNC(v_cal_date))/7));
                           END IF;*/
                        --END IF;
                        ELSIF c2.cfm_free_txncnt >= v_week_diff THEN
                           v_free_cnt := v_week_diff;
                        ELSE
                           v_free_cnt := c2.cfm_free_txncnt;
                        END IF;
                        --En Added for JH - weekly Fee Waiver changes
                        
                        SELECT TRUNC (SYSDATE) - TRUNC (v_cal_date)
                          INTO v_diff_day --Get no of days for which fee need to apply

                        FROM   DUAL;

                        FOR i IN 1 .. CEIL (v_diff_day / 7)
                        LOOP
                           --Sn Added for JH - Weekly Fee Waiver
                           IF c2.cfm_max_limit = 0 OR v_weeklyfee_counter + v_weekly_txn <c2.cfm_max_limit THEN 
                              v_max_exceed := 'N';
                           ELSE
                              v_max_exceed := 'Y';
                           END IF;
                          --En Added for JH - Weekly Fee Waiver
                        IF c2.cfm_date_assessment = 'FD'
                        THEN
                           IF v_diff_day <= 7
                           THEN
                              v_cfm_fee_amt :=
                                       ((c2.cfm_fee_amt / 7) * (v_diff_day)
                                       );
                           ELSE
                              IF CEIL (v_diff_day / 7) > 2
                              THEN
                                 v_diff_day := v_diff_day - 7;
                              ELSE
                                 v_days := MOD (v_diff_day, 7);

                                 IF v_days <> 0
                                 THEN
                                    v_diff_day := v_days;
                                 END IF;
                              END IF;

                              v_cfm_fee_amt := c2.cfm_fee_amt;
                           END IF;
                              --Sn Added for JH - weekly Fee Waiver changes
                              IF v_free_cnt > 0 and v_week_diff <= v_free_cnt THEN --Added V_free_cnt >0 for 0013511 
                                 v_cfm_fee_amt := 0;
                                 v_free_txn := 'Y';
                              ELSE
                                 IF v_max_exceed = 'N' THEN
                                    v_weekly_txn := v_weekly_txn + 1;
                                 END IF;

                                 v_week_diff := v_week_diff - 1;
                              END IF;
                              --En Added for JH - weekly Fee Waiver changes
                         END IF;

                           IF v_max_exceed = 'N' OR v_free_txn = 'Y' THEN --Added for JH - weekly Fee Waiver changes
                              IF c2.cfm_feecap_flag = 'Y' AND v_free_txn = 'N' THEN --v_free_txn='N' condition Added for JH - weekly Fee Waiver changes
                           BEGIN
                              sp_tran_fees_cap (p_instcode,
                                                c2.cap_acct_no,
                                                TRUNC (SYSDATE),
                                                v_cfm_fee_amt,
                                                c2.cff_fee_plan,
                                                c2.cfm_fee_code,
                                                v_err_msg
                                               );
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        END IF;

                        BEGIN
                           SELECT cpw_waiv_prcnt
                             INTO v_cpw_waiv_prcnt
                             FROM cms_prodcattype_waiv
                            WHERE cpw_inst_code = p_instcode
                              AND cpw_prod_code = c2.cpf_prod_code
                              AND cpw_card_type = c2.cpf_card_type
                              AND cpw_fee_code = c2.cfm_fee_code
                              AND TRUNC (SYSDATE) >= TRUNC (cpw_valid_from)
                              --TRUNC added for Review comments changes
                              AND TRUNC (SYSDATE) <= TRUNC (cpw_valid_to);

                           --TRUNC added for Review comments changes
                           v_waivamt :=
                                      (v_cpw_waiv_prcnt / 100) * v_cfm_fee_amt;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_waivamt := 0;
                        END;

                        BEGIN
                           lp_fee_update_log (p_instcode,
                                              c2.cap_pan_code,
                                              c2.cap_pan_code_encr,
                                              c2.cfm_fee_code,
                                              v_cfm_fee_amt,
                                              c2.cff_fee_plan,
                                              c2.cpf_crgl_catg,
                                              c2.cpf_crgl_code,
                                              c2.cpf_crsubgl_code,
                                              c2.cpf_cracct_no,
                                              c2.cpf_drgl_catg,
                                              c2.cpf_drgl_code,
                                              c2.cpf_drsubgl_code,
                                              c2.cpf_dracct_no,
                                              c2.cfm_clawback_flag,
                                              c2.cft_fee_freq,
                                              c2.cft_feetype_code,
                                              p_lupduser,
                                              v_waivamt,
                                              'PC',
                                              c2.cap_card_stat,
                                              c2.cap_acct_no,
                                              c2.cap_prod_code,
                                              c2.cap_card_type,
                                              v_free_txn, --Added for JH-Weekly fee wavier
                                              c2.CFM_FEE_DESC, --Added  on 03/02/14 for MVCSD-4471
                                              v_err_msg
                                             );

                           --IF v_err_msg <> 'OK'
                           --THEN
                              --RAISE v_raise_exp;
                           --END IF;
                        EXCEPTION
                           --WHEN v_raise_exp
                           --THEN
                              --RAISE;
                           WHEN OTHERS
                           THEN
                              v_err_msg :=
                                    'Error while calling LP_FEE_UPDATE_LOG 1.1 -'
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE v_raise_exp;
                        END;
                     END IF;   
                     END LOOP;

                     --Sn Updating next weekly billing date
                     IF c2.cfm_date_assessment = 'FD'
                     THEN
                        v_next_mb_date := NEXT_DAY (SYSDATE, 'SUNDAY');
                     END IF;

                     BEGIN
                        UPDATE cms_appl_pan
                           SET cap_next_wb_date = v_next_mb_date
                         WHERE cap_pan_code = c2.cap_pan_code
                           AND cap_inst_code = p_instcode;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_err_msg :=
                                 'No records updated in APPL_PAN 1.1 for pan '
                              || c2.cap_pan_code;
                           RAISE v_raise_exp;
                        END IF;
                     EXCEPTION
                        WHEN v_raise_exp
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_err_msg :=
                                 'Error while upadating APPL_PAN for prodcat fee billing date 1.1-'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE v_raise_exp;       --Added for review changes
                     END;
                  --En Updating next weekly billing date
                  
                         --Sn Added for JH - Weekly Fee Waiver
                        IF v_weekly_txn <> 0 THEN
                           BEGIN
                              UPDATE cms_acct_mast
                                 SET cam_weeklyfee_counter =cam_weeklyfee_counter + v_weekly_txn
                               WHERE cam_inst_code = p_instcode
                                 AND cam_acct_id = c2.cap_acct_id;

                              IF SQL%ROWCOUNT = 0 THEN
                                 v_err_msg :='No records updated in Acct_mast for acct 2.0 -';RAISE v_raise_exp;
                              END IF;
                           EXCEPTION
                              WHEN v_raise_exp THEN
                                 RAISE;
                              WHEN OTHERS THEN
                                 v_err_msg :='Error while upadating Acct_mast 2.0 -'|| SUBSTR (SQLERRM, 1, 200);
                                 RAISE v_raise_exp;
                           END;
                        END IF;
                        --En Added for JH - Weekly Fee Waiver
                     END IF;     --Added for JH-Weekly fee wavier

                  EXCEPTION
                     WHEN v_raise_exp
                     THEN
                        --v_err_msg := v_err_msg; --Commented for review changes
                        lp_weekly_fee_err_log (p_instcode,
                                               p_lupduser,
                                               c2.cap_pan_code,
                                               'PC',
                                               v_err_msg
                                              );
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Main exception from product catg level weekly fee cal-'
                           || SUBSTR (SQLERRM, 1, 200);
                        lp_weekly_fee_err_log (p_instcode,
                                               p_lupduser,
                                               c2.cap_pan_code,
                                               'PC',
                                               v_err_msg
                                              );
                  END;
               END IF;
            END IF;
         END LOOP;

         --En Added by Pankaj S. for Revised approch

         --Sn Added by Pankaj S. for Revised approch
         FOR c3 IN prodfee
         LOOP
         
            v_err_msg := 'OK';
            --Sn Added for JH - weekly Fee Waiver changes
            v_weekly_txn := 0;
            v_free_txn := 'N';
            v_free_cnt := 0;
            --En Added for JH - weekly Fee Waiver changes

          
            --Sn Fee paln attached to card..?
            BEGIN
               SELECT COUNT
                         (CASE
                             WHEN (    cce_valid_to IS NOT NULL
                                   AND (TRUNC (SYSDATE)
                                           BETWEEN TRUNC (cce_valid_from)
                                               AND TRUNC (cce_valid_to)
                                       )
                                  )  --TRUNC added for review comments changes
                              OR (    cce_valid_to IS NULL
                                  AND TRUNC (SYSDATE) >=
                                                        TRUNC (cce_valid_from)
                                 )
                                THEN 1
                          --TRUNC added for review comments changes
                          END
                         )
                 INTO v_card_cnt
                 FROM cms_card_excpfee
                WHERE cce_inst_code = p_instcode
                  AND cce_pan_code = c3.cap_pan_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_card_cnt := 0;
            END;

            --En Fee paln attached to card..?
            IF v_card_cnt = 0
            THEN
               --Sn Fee paln attached to product category..?
               BEGIN
                  SELECT COUNT
                            (CASE
                                WHEN ((    cpf_valid_to IS NOT NULL
                                       AND TRUNC (SYSDATE)
                                              BETWEEN TRUNC (cpf_valid_from)
                                                  AND TRUNC (cpf_valid_to)
                                      )
                                     )
                                 --TRUNC added for review comments changes
                                 OR (    cpf_valid_to IS NULL
                                     AND TRUNC (SYSDATE) >=
                                                        TRUNC (cpf_valid_from)
                                    )
                                   THEN 1
                             --TRUNC added for review comments changes
                             END
                            )
                    INTO v_prdcatg_cnt
                    FROM cms_prodcattype_fees
                   WHERE cpf_inst_code = p_instcode
                     AND cpf_prod_code = c3.cpf_prod_code
                     AND cpf_card_type = c3.cap_card_type;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_prdcatg_cnt := 0;
               END;
            --En Fee paln attached to product category..?
            END IF;

            IF v_card_cnt = 0 AND v_prdcatg_cnt = 0
            THEN
               IF c3.cap_active_date IS NOT NULL
               THEN
                  BEGIN
                     --Sn Added for JH - weekly Fee Waiver changes
                     BEGIN
                        SELECT cam_weeklyfee_counter
                          INTO v_weeklyfee_counter
                          FROM cms_acct_mast
                         WHERE cam_inst_code = p_instcode
                           AND cam_acct_id = c3.cap_acct_id;
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                           v_err_msg :='Acct not found 3.0 -' || c3.cap_acct_id;
                           RAISE v_raise_exp;
                        WHEN OTHERS THEN
                           v_err_msg :='Error occured while fetching acct dtls 3.0 -'|| SUBSTR (SQLERRM, 1, 200);
                           RAISE v_raise_exp;
                     END;
                     --En Added for JH - weekly Fee Waiver changes
                     
                     IF c3.cfm_max_limit = 0 OR v_weeklyfee_counter < c3.cfm_max_limit THEN     --Added for JH - Weekly Fee Waiver
                     BEGIN
                        SELECT GREATEST (c3.cpf_valid_from,
                                         c3.cff_ins_date,
                                         c3.cap_active_date
                                        )
                          INTO v_cal_date
                          FROM DUAL;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_err_msg :=
                                 'Error while getting recent date -'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE v_raise_exp;
                     END;
                       --Sn Added for JH - weekly Fee Waiver changes
                        BEGIN
                           SELECT CEIL ((TRUNC (SYSDATE)- TRUNC (v_cal_date))/ 7)
                             INTO v_week_diff
                             FROM DUAL;
                        EXCEPTION
                           WHEN OTHERS THEN
                              v_err_msg :='Error while getting weekly diff 3.0 -'|| SUBSTR (SQLERRM, 1, 200);
                              RAISE v_raise_exp;
                        END;


                        IF c3.cap_next_wb_date IS NOT NULL AND c3.cap_next_wb_date >= v_cal_date --Modified for JH - weekly Fee Waiver changes
                        THEN
                           --IF c3.cap_next_wb_date>=v_cal_date THEN
                           v_free_cnt := c3.cfm_free_txncnt - v_week_diff +1; -- Added for Mantis 0013511 
                           v_cal_date := c3.cap_next_wb_date - 7;
                           
                           
                          SELECT CEIL ((TRUNC (SYSDATE) - TRUNC (v_cal_date)) / 7)
                          INTO v_week_diff
                          FROM DUAL;
                          
                           --Sn Added for JH - weekly Fee Waiver changes
                        /*   IF c3.cfm_free_txncnt >= v_week_diff THEN
                              IF v_weeklyfee_counter = 0 THEN
                                 v_free_cnt := CEIL ((TRUNC (SYSDATE) - TRUNC (v_cal_date))/ 7);
                              END IF;
                           ELSE
                              v_free_cnt :=c3.cfm_free_txncnt- ( v_week_diff- CEIL ((TRUNC (SYSDATE)- TRUNC (v_cal_date))/ 7));
                           END IF;*/
                        --END IF;
                        ELSIF c3.cfm_free_txncnt >= v_week_diff THEN
                           v_free_cnt := v_week_diff;
                        ELSE
                           v_free_cnt := c3.cfm_free_txncnt;
                        END IF;
                        --En Added for JH - weekly Fee Waiver changes
                        
                        SELECT TRUNC (SYSDATE) - TRUNC (v_cal_date)
                          INTO v_diff_day --Get no of days for which fee need to apply

                        FROM   DUAL;

                        FOR i IN 1 .. CEIL (v_diff_day / 7)
                        LOOP
                          --Sn Added for JH - Weekly Fee Waiver
                           IF c3.cfm_max_limit = 0 OR v_weeklyfee_counter + v_weekly_txn < c3.cfm_max_limit THEN 
                              v_max_exceed := 'N';
                           ELSE
                              v_max_exceed := 'Y';
                           END IF;
                           --En Added for JH - Weekly Fee Waiver

                        IF c3.cfm_date_assessment = 'FD'
                        THEN
                           IF v_diff_day <= 7
                           THEN
                              v_cfm_fee_amt :=
                                       ((c3.cfm_fee_amt / 7) * (v_diff_day)
                                       );
                           ELSE
                              IF CEIL (v_diff_day / 7) > 2
                              THEN
                                 v_diff_day := v_diff_day - 7;
                              ELSE
                                 v_days := MOD (v_diff_day, 7);

                                 IF v_days <> 0
                                 THEN
                                    v_diff_day := v_days;
                                 END IF;
                              END IF;

                              v_cfm_fee_amt := c3.cfm_fee_amt;
                           END IF;
                              --Sn Added for JH - weekly Fee Waiver changes
                              IF v_free_cnt > 0 and v_week_diff <= v_free_cnt THEN --Added V_free_cnt >0 for 0013511
                                 v_cfm_fee_amt := 0;
                                 v_free_txn := 'Y';
                              ELSE
                                 IF v_max_exceed = 'N' THEN
                                    v_weekly_txn := v_weekly_txn + 1;
                                 END IF;

                                 v_week_diff := v_week_diff - 1;
                              END IF;
                              --En Added for JH - weekly Fee Waiver changes
                           END IF;

                           IF v_max_exceed = 'N' OR v_free_txn = 'Y' THEN --Added for JH - weekly Fee Waiver changes
                              IF c3.cfm_feecap_flag = 'Y' AND v_free_txn = 'N' THEN --v_free_txn='N' condition Added for JH - weekly Fee Waiver changes

                           BEGIN
                              sp_tran_fees_cap (p_instcode,
                                                c3.cap_acct_no,
                                                TRUNC (SYSDATE),
                                                v_cfm_fee_amt,
                                                c3.cff_fee_plan,
                                                c3.cfm_fee_code,
                                                v_err_msg
                                               );
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        END IF;

                        BEGIN
                           SELECT cpw_waiv_prcnt
                             INTO v_cpw_waiv_prcnt
                             FROM cms_prodccc_waiv
                            WHERE cpw_inst_code = p_instcode
                              AND cpw_prod_code = c3.cpf_prod_code
                              AND cpw_fee_code = c3.cfm_fee_code
                              AND TRUNC (SYSDATE) >= TRUNC (cpw_valid_from)
                              --TRUNC added for review comments changes
                              AND TRUNC (SYSDATE) <= TRUNC (cpw_valid_to);

                           --TRUNC added for review comments changes
                           v_waivamt :=
                                      (v_cpw_waiv_prcnt / 100) * v_cfm_fee_amt;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_waivamt := 0;
                        END;

                        BEGIN
                           lp_fee_update_log (p_instcode,
                                              c3.cap_pan_code,
                                              c3.cap_pan_code_encr,
                                              c3.cfm_fee_code,
                                              v_cfm_fee_amt,
                                              c3.cff_fee_plan,
                                              c3.cpf_crgl_catg,
                                              c3.cpf_crgl_code,
                                              c3.cpf_crsubgl_code,
                                              c3.cpf_cracct_no,
                                              c3.cpf_drgl_catg,
                                              c3.cpf_drgl_code,
                                              c3.cpf_drsubgl_code,
                                              c3.cpf_dracct_no,
                                              c3.cfm_clawback_flag,
                                              c3.cft_fee_freq,
                                              c3.cft_feetype_code,
                                              p_lupduser,
                                              v_waivamt,
                                              'P',
                                              c3.cap_card_stat,
                                              c3.cap_acct_no,
                                              c3.cap_prod_code,
                                              c3.cap_card_type,
                                              v_free_txn, --Added for JH-Weekly fee wavier
                                              c3.CFM_FEE_DESC, --Added  on 03/02/14 for MVCSD-4471
                                              v_err_msg
                                             );

                           --IF v_err_msg <> 'OK'
                           --THEN
                              --RAISE v_raise_exp;
                           --END IF;
                        EXCEPTION
                           --WHEN v_raise_exp
                           --THEN
                              --RAISE;
                           WHEN OTHERS
                           THEN
                              v_err_msg :=
                                    'Error while calling LP_FEE_UPDATE_LOG 1.2-'
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE v_raise_exp;
                        END;
                      END IF;   
                     END LOOP;

                     --Sn Updating next weekly billing date
                     IF c3.cfm_date_assessment = 'FD'
                     THEN
                        v_next_mb_date := NEXT_DAY (SYSDATE, 'SUNDAY');
                     END IF;

                     BEGIN
                        UPDATE cms_appl_pan
                           SET cap_next_wb_date = v_next_mb_date
                         WHERE cap_pan_code = c3.cap_pan_code
                           AND cap_inst_code = p_instcode;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_err_msg :=
                                 'No records updated in APPL_PAN 1.2 for pan '
                              || c3.cap_pan_code;
                           RAISE v_raise_exp;
                        END IF;
                     EXCEPTION
                        WHEN v_raise_exp
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_err_msg :=
                                 'Error while upadating APPL_PAN for prod fee billing date 1.2-'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE v_raise_exp;       --Added for review changes
                     END;
                  --En Updating next weekly billing date
                  
                        --Sn Added for JH - Weekly Fee Waiver
                        IF v_weekly_txn <> 0 THEN
                           BEGIN
                              UPDATE cms_acct_mast
                                 SET cam_weeklyfee_counter = cam_weeklyfee_counter + v_weekly_txn
                               WHERE cam_inst_code = p_instcode
                                 AND cam_acct_id = c3.cap_acct_id;

                              IF SQL%ROWCOUNT = 0 THEN
                                 v_err_msg :='No records updated in Acct_mast for acct 3.0 -';
                                 RAISE v_raise_exp;
                              END IF;
                           EXCEPTION
                              WHEN v_raise_exp THEN
                                 RAISE;
                              WHEN OTHERS THEN
                                 v_err_msg :='Error while upadating Acct_mast 3.0 -'|| SUBSTR (SQLERRM, 1, 200);
                                 RAISE v_raise_exp;
                           END;
                        END IF;
                        --En Added for JH - Weekly Fee Waiver
                     END IF;     --Added for JH-Weekly fee wavier

                  EXCEPTION
                     WHEN v_raise_exp
                     THEN
                        --v_err_msg := v_err_msg;  --Commented for review changes
                        lp_weekly_fee_err_log (p_instcode,
                                               p_lupduser,
                                               c3.cap_pan_code,
                                               'P',
                                               v_err_msg
                                              );
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Main exception from product level weekly fee cal -'
                           || SUBSTR (SQLERRM, 1, 200);
                        lp_weekly_fee_err_log (p_instcode,
                                               p_lupduser,
                                               c3.cap_pan_code,
                                               'P',
                                               v_err_msg
                                              );
                  END;
               END IF;
            END IF;
         END LOOP;

         p_errmsg := 'Weekly Fee Calculated for ' || v_upd_rec_cnt || ' Cards';
      END;
   ELSE
      p_errmsg :=
             'Weekly fee will be calculated on first day of week i.e. Sunday';
   END IF;
END;

/

show error