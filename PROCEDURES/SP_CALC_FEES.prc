CREATE OR REPLACE PROCEDURE VMSCMS.SP_CALC_FEES (
   p_instcode   IN       NUMBER,
   p_lupduser   IN       NUMBER,
   p_errmsg     OUT      VARCHAR2
)
AS
   v_debit_amnt        NUMBER;
   v_fee_amount        NUMBER;
   v_err_msg           VARCHAR2 (900) := 'OK';
   exp_reject_record   EXCEPTION;
   v_monfee_cardcnt    NUMBER;
   v_waivamt           NUMBER;
   v_cpw_waiv_prcnt    NUMBER;
   v_feeamt            NUMBER;
   v_upd_rec_cnt       NUMBER         := 0;
   v_rrn1              NUMBER (10)    DEFAULT 0;
   v_rrn2              VARCHAR2 (15);
   v_cfm_fee_amt       NUMBER (15, 2);
   v_cam_type_code   cms_acct_mast.cam_type_code%type;   -- Added on 17-Apr-2013 for defect 10871
   v_timestamp       timestamp;                          -- Added on 17-Apr-2013 for defect 10871
   v_prod_code cms_appl_pan.cap_prod_code%type;          -- Added on 20-Apr-2013 for defect 10871
   v_card_type cms_appl_pan.cap_card_stat%type;          -- Added on 20-Apr-2013 for defect 10871
   v_card_stat cms_appl_pan.cap_card_type%type;          -- Added on 20-Apr-2013 for defect 10871
   v_acct_id            cms_acct_mast.cam_acct_id%TYPE;  -- Added on 20-Apr-2013 for defect 10871
   v_next_bill_date     CMS_APPL_PAN.CAP_NEXT_MB_DATE%TYPE; -- Added for Defect HOST-328
   V_PROD_CATTYPE     CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
   V_DR_CR_FLAG       CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%type;
   v_card_cnt         NUMBER;  --Added on 03.09.2013 for DFCHOST-340
   v_prdcatg_cnt      NUMBER;--Added on 03.09.2013 for DFCHOST-340
     v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
    v_chrg_dtl_cnt    NUMBER;     -- Added for FWR 64
   --Sn added on 10.09.2013 for DFCHOST-340(review)
    v_txn_mode           cms_func_mast.cfm_txn_mode%TYPE        DEFAULT '0';
    v_txn_code           cms_func_mast.cfm_txn_code%TYPE       DEFAULT '18';
    v_delivery_channel   cms_func_mast.cfm_delivery_channel%TYPE DEFAULT '05';
    v_business_date      VARCHAR2 (10);
    v_business_time      VARCHAR2 (10);
    v_auth_id            transactionlog.auth_id%TYPE;
    v_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
    v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
    v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   --En added on 10.09.2013 for DFCHOST-340(review)

   /*************************************************
      * Created By       : Deepa
      * Created Date     : 29-June-2012
      * Purpose          : For the proper process message
      * Modified By      : Deepa T
      * Modified Date    : 22--OCT-2012
      * Modified Reason  : To log the Fee details in transactionlog,cms_tarnsaction_log_dtl table.
      * Reviewer         : Saravanakumar
      * Reviewed Date    : 31-OCT-12
      * Build Number     : CMS3.5.1_RI0021_B0001

      * Modified By      : Sagar M.
      * Modified for     : Defect 10871
      * Modified Date    : 17-Apr-2013
      * Modified Reason  : Logging of below details in statementlog table
                           1) ledger balance,Timestamp and account type
      * Reviewer         : Dhiraj
      * Reviewed Date    : 17-Apr-2013
      * Build Number     : RI0024.1_B00013

      * Modified By      : Sagar M. and  Sai Prasad
      * Modified reason  : To handle fee calculation incase of scheduler fails and ClawBack cases
      * Modified for     : HOST-328
      * Modified On      : 27-May-2013
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : RI0024.1.3_B0002

       * Modified By      : Sai Prasad.
       * Modified reason  : To handle fee calculation for existing monthly fee issue inventory cards.
       * Modified for     : HOST-328
       * Modified On      : 07-Jun-2013
       * Reviewer         : Dhiraj
       * Reviewed Date    : 07-Jun-2013
       * Build Number     : RI0024.1.3_B0003

       * Modified By      : Sai Prasad
       * Modified reason  : Fee Capping
       * Modified for     : JIRA  FWR-11
       * Modified On      : 20-Aug-2013
       * Reviewer         : Dhiraj
       * Reviewed Date    : 20-Aug-2013
       * Build Number     : RI0024.4_B0004

      * Modified By      : Sachin P.
      * Modified Date    : 03-Sep-2013
      * Modified for     : DFCHOST-340
      * Modified Reason  : Momentum Production Testing - Loading test card with $20.00
      * Reviewer         : Dhiraj
      * Reviewed Date    : 03-SEP-2013
      * Build Number     : RI0024.3.6_B0002

      * Modified By      : Sachin P.
      * Modified Date    : 06-Sep-2013
      * Modified for     : DFCHOST-340(review)
      * Modified Reason  : Review changes
      * Reviewer         : Dhiraj
      * Reviewed Date    : 11-sep_2013
      * Build Number     : RI0024.4_B0009

     * Modified By      : Revathi D
     * Modified Date    : 02-APR-2014
     * Modified for     :
     * Modified Reason  : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
                          CMS_ACCT_MAST,CMS_STATEMENTS_LOG,TRANSACTIONLOG.

     * Reviewer         : Pankaj S.
     * Reviewed Date    : 03-APR-2014
     * Build Number     : CMS3.5.1_RI0027.2_B0004

    * modified by       : Amudhan S
    * modified Date     : 23-may-14
    * modified for      : FWR 64
    * modified reason   : To restrict clawback fee entries as per the configuration done by user.
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3_B0001

    * modified by       : Ramesh A
    * modified Date     : 21-July-14
    * modified for      : 15544
    * modified reason   : Fees entries not logging in activity tab after the claw back count has been reached
    * Reviewer          : spankaj
    * Build Number      : RI0027.3_B0005
    
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
	
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
	
   *************************************************/
   CURSOR cardfee
   IS
      SELECT cfm_fee_code, cfm_fee_amt, cce_pan_code, cce_pan_code_encr,
             cce_crgl_catg, cce_crgl_code, cce_crsubgl_code, cce_cracct_no,
             cce_drgl_catg, cce_drgl_code, cce_drsubgl_code, cce_dracct_no,
             cff_fee_plan, cap_active_date, cfm_date_assessment,
             cfm_clawback_flag, cfm_proration_flag, cft_fee_freq,
             cft_feetype_code, cap_next_mb_date, cap_next_bill_date,cap_card_stat,
             CFM_FEECAP_FLAG, CAP_ACCT_NO, -- Added for FWR-11
             cap_prod_code,cap_card_type,cap_acct_id --Added on 06.09.2013 for DFCHOST-340(review)
        FROM cms_fee_mast,
             cms_card_excpfee,
             cms_fee_types,
             cms_fee_feeplan,
             cms_appl_pan
       WHERE cfm_inst_code = p_instcode
         AND cfm_inst_code = cce_inst_code
         AND cce_fee_plan = cff_fee_plan
         AND cff_fee_code = cfm_fee_code
         AND
             -- TRUNC(SYSDATE) >= TRUNC(CCE_VALID_FROM) AND
             (   (    cce_valid_to IS NOT NULL
                  AND (TRUNC (SYSDATE) BETWEEN cce_valid_from AND cce_valid_to
                      )
                 )
              OR (cce_valid_to IS NULL AND TRUNC (SYSDATE) >= cce_valid_from)
             )
         AND     --Modified by Deepa on Aug-18-2012 to have two active FeePlan
             cfm_feetype_code = cft_feetype_code
         AND cft_inst_code = cfm_inst_code
         AND cap_card_stat NOT IN ('9')
         AND cft_fee_freq = 'A'
         AND cap_pan_code = cce_pan_code;



   CURSOR prodcatgfee
   IS
      SELECT cfm_fee_code, cfm_fee_amt, cpf_prod_code, cpf_card_type,
             cpf_crgl_catg, cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no,
             cpf_drgl_catg, cpf_drgl_code, cpf_drsubgl_code, cpf_dracct_no,
             cff_fee_plan, cfm_date_assessment, cfm_clawback_flag,
             cfm_proration_flag, cft_fee_freq, cft_feetype_code, cap_pan_code,
             cap_pan_code_encr, cap_active_date, cap_next_mb_date,
             cap_next_bill_date,cap_card_stat,
             CFM_FEECAP_FLAG, CAP_ACCT_NO, -- Added for FWR-11
             cap_prod_code,cap_card_type,cap_acct_id --Added on 06.09.2013 for DFCHOST-340(review)
        FROM cms_fee_mast,
             cms_prodcattype_fees,
             cms_fee_types,
             cms_fee_feeplan,
             cms_appl_pan
       WHERE cfm_inst_code = p_instcode
         AND cfm_inst_code = cpf_inst_code
         --  AND cpf_fee_code = cfm_fee_code--Modified by Deepa on June 26 2012  as the cce_fee_code will be NULL
         AND cff_fee_plan = cpf_fee_plan
         AND cff_fee_code = cfm_fee_code
         AND
             --TRUNC(SYSDATE) >= TRUNC(CPF_VALID_FROM) AND
             (   (    cpf_valid_to IS NOT NULL
                  AND (TRUNC (SYSDATE) BETWEEN cpf_valid_from AND cpf_valid_to
                      )
                 )
              OR (cpf_valid_to IS NULL AND TRUNC (SYSDATE) >= cpf_valid_from)
             )
         AND     --Modified by Deepa on Aug-18-2012 to have two active FeePlan
             cfm_feetype_code = cft_feetype_code
         AND cft_inst_code = cfm_inst_code
         AND cap_prod_code = cpf_prod_code
         AND cap_card_type = cpf_card_type
         AND cap_inst_code = cpf_inst_code
         -- AND cap_card_stat = '1'
         --AND CAP_EXPRY_DATE > sysdate
         AND cap_card_stat NOT IN ('9')
         AND cft_fee_freq = 'A';




   CURSOR prodfee
   IS
      SELECT cfm_fee_code, cfm_fee_amt, cpf_prod_code, cpf_crgl_catg,
             cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no, cpf_drgl_catg,
             cpf_drgl_code, cpf_drsubgl_code, cpf_dracct_no, cff_fee_plan,
             cfm_date_assessment, cfm_clawback_flag, cfm_proration_flag,
             cft_fee_freq, cft_feetype_code, cap_pan_code, cap_pan_code_encr,
             cap_active_date, cap_next_mb_date, cap_next_bill_date,cap_card_stat,
             CFM_FEECAP_FLAG, CAP_ACCT_NO, -- Added for FWR-11
             cap_card_type, ---Added on 03.09.2013 for DFCHOST-340
             cap_prod_code,cap_acct_id ---Added on 06.09.2013 for DFCHOST-340(review)
        FROM cms_fee_mast,
             cms_prod_fees,
             cms_fee_types,
             cms_fee_feeplan,
             cms_appl_pan
       WHERE cfm_inst_code = p_instcode
         AND cfm_inst_code = cpf_inst_code
         AND cff_fee_plan = cpf_fee_plan
         AND cff_fee_code = cfm_fee_code
         AND
             --TRUNC(SYSDATE) >= TRUNC(CPF_VALID_FROM) AND
             (   (    cpf_valid_to IS NOT NULL
                  AND (TRUNC (SYSDATE) BETWEEN cpf_valid_from AND cpf_valid_to
                      )
                 )
              OR (cpf_valid_to IS NULL AND TRUNC (SYSDATE) >= cpf_valid_from)
             )
         AND     --Modified by Deepa on Aug-18-2012 to have two active FeePlan
             cfm_feetype_code = cft_feetype_code
         AND cft_inst_code = cfm_inst_code
         AND cap_prod_code = cpf_prod_code
         AND cap_inst_code = cpf_inst_code
         -- AND cap_card_stat = '1'
         --AND CAP_EXPRY_DATE > sysdate
         AND cap_card_stat NOT IN ('9')
         AND cft_fee_freq = 'A';




   PROCEDURE lp_monthly_fee_calc (
      p_date_assessment   IN       VARCHAR2,
      p_proration         IN       VARCHAR2,
      p_fee_amnt          IN       NUMBER,
      p_calc_date         IN       DATE,
      p_pan_code          IN       VARCHAR2,
      p_inst_code         IN       NUMBER,
      p_capactive_date    IN       VARCHAR2,
      p_feeamount         OUT      NUMBER,
      p_errmsg            OUT      VARCHAR2
   )
   AS
      v_first_date       DATE;
      v_tot_days         NUMBER;
      v_activationdate   NUMBER;
      v_monfee_cardcnt   NUMBER;
      v_calc_date        DATE;
   BEGIN
      p_errmsg := 'OK';

      IF p_calc_date IS NULL OR P_CALC_DATE < P_CAPACTIVE_DATE  --  Added next mb date < active date to handle existing inventory cards which are activated for defect Host-328
      THEN
         v_calc_date := ADD_MONTHS (p_capactive_date, 12);
       -- This is to handle existing cards generated through inventory, in which active date and next mb date updated as pan generated date for defect Host-328
      ELSIF  P_CALC_DATE = P_CAPACTIVE_DATE THEN
        V_CALC_DATE := ADD_MONTHS(SYSDATE, 12); -- This is handle not to collect Annual fee for not activated inventory card. for defect Host-328
      ELSE
         v_calc_date := p_calc_date;
      END IF;


          IF  TRUNC (v_calc_date) <= TRUNC (SYSDATE) -- less than equal to (<=) added instead of equal to (=) for defect Host-328
              --TRUNC (v_calc_date) = TRUNC (SYSDATE) -- Commented for defect Host-328
          THEN
             p_errmsg := 'OK';
             p_feeamount := p_fee_amnt;
          ELSE
             p_errmsg := 'NO FEES';
             p_feeamount := 0;
          END IF;


   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
                    'Error in lp_monthly_fee_calc ' || SUBSTR (SQLERRM, 1, 200);
   END lp_monthly_fee_calc;


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
      p_timestamp          IN   timestamp,   --Added for defect 10871
      p_err_msg             IN   VARCHAR2,     --Added for defect 10871
      p_prod_code          IN   VARCHAR2,     --Added for defect 10871
      p_card_type          IN   VARCHAR2,     --Added for defect 10871
      p_acct_type          IN   VARCHAR2     --Added for defect 10871
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
                      auth_id, trans_desc,
                                          -- AMOUNT,
                                          instcode, customer_card_no_encr,
                      customer_acct_no, acct_balance, ledger_balance,
                      response_id, txn_mode, currencycode,
                      tranfee_amt,
                      feeattachtype, fee_plan, feecode, tranfee_cr_acctno,
                      tranfee_dr_acctno,CARDSTATUS,
                      productid,            --Added for defect 10871
                      categoryid,           --Added for defect 10871
                      acct_type,            --Added for defect 10871
                      time_stamp,            --Added for defect 10871
                      error_msg             --Added for defect 10871
                     )
              VALUES ('0200', p_rrn, p_delivery_channel, SYSDATE,
                      p_tran_code, '1',
                      DECODE (p_response_id, '1', 'C', 'F'),
                      DECODE (p_response_id, '1', '00', '89'),
                      p_business_date, p_business_time, p_hashpan,
                      p_instcode,
                      TRIM (TO_CHAR (NVL(p_fee_amnt,0) - NVL(p_waiv_amnt,0),
                                     '99999999999999990.99'
                                    )
                           ),
                      p_auth_id, p_tran_desc,
                                             -- TRIM(TO_CHAR(P_TRAN_AMNT, '99999999999999999.99')),
                                             p_instcode, p_encrpan,
                      p_acct_number, ROUND(p_acct_bal,2), ROUND(p_ledger_bal,2), --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                      p_response_id, 0, p_card_curr,
                      TRIM (TO_CHAR (NVL(p_fee_amnt,0) - NVL(p_waiv_amnt,0),
                                     '99999999999999990.99'
                                    )
                           ),
                      p_attach_type, p_fee_plan, p_fee_code, p_cr_acctno,
                      p_dr_acctno,p_card_stat,
                      p_prod_code,          --Added for defect 10871
                      p_card_type,          --Added for defect 10871
                      p_acct_type,         --Added for defect 10871
                      p_timestamp,          --Added for defect 10871
                      p_err_msg              --Added for defect 10871
                     );

         IF SQL%ROWCOUNT = 0
         THEN
            p_errmsg :=
                  'Error while insertg in transactionlog'
               || SUBSTR (SQLERRM, 1, 200);
         END IF;
       --SN Added on 06.09.2013 for DFCHOST-340(review)
      EXCEPTION
      WHEN OTHERS THEN
      p_errmsg :=
                  'Error while insertg in transactionlog'
               || SUBSTR (SQLERRM, 1, 200);
      --EN Added on 06.09.2013 for DFCHOST-340(review)
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

         IF SQL%ROWCOUNT = 0
         THEN
            p_errmsg :=
                  'Error while insertg in cms_transaction_log_dtl'
               || SUBSTR (SQLERRM, 1, 200);
         END IF;
        --SN Added on 06.09.2013 for DFCHOST-340(review)
      EXCEPTION
      WHEN OTHERS THEN
          p_errmsg :=
                  'Error while insertg in cms_transaction_log_dtl'
               || SUBSTR (SQLERRM, 1, 200);
        --EN Added on 06.09.2013 for DFCHOST-340(review)
      END;
   END lp_transaction_log;

      PROCEDURE lp_fee_update_log (
      p_instcode       IN       NUMBER,
      p_hashpan        IN       VARCHAR2,
      p_encrpan        IN       VARCHAR2,
      p_fee_code       IN       NUMBER,
      p_fee_amnt       IN       NUMBER,
      p_fee_plan       IN       VARCHAR2,
      --  p_card_type  IN       VARCHAR2,
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
      p_acct_no        IN       VARCHAR2,--Added on 06.09.2013 for DFCHOST-340(review)
      p_prod_code      IN       VARCHAR2,--Added on 06.09.2013 for DFCHOST-340(review)
      p_card_type      IN       NUMBER, --Added on 06.09.2013 for DFCHOST-340(review)
      p_acct_id        IN       NUMBER, --Added on 06.09.2013 for DFCHOST-340(review)
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
      v_txn_code           cms_func_mast.cfm_txn_code%TYPE       DEFAULT '18';
      v_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
      v_narration          cms_statements_log.csl_trans_narrration%TYPE;
      v_pan_code           VARCHAR2 (19);
      V_CLAWBACK_AMNT      CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
      V_FILE_STATUS        CMS_CHARGE_DTL.CCD_FILE_STATUS%TYPE DEFAULT 'N';
      V_CLAWBACK_COUNT     NUMBER;
      v_fee_amnt           cms_acct_mast.cam_acct_bal%TYPE;
      v_bin_curr              cms_bin_param.cbp_param_value%TYPE;
      v_card_curr          transactionlog.currencycode%TYPE;

   BEGIN
      p_errmsg := 'OK';

  --Sn moved up to handle RRN null issue for defect Host-328

      BEGIN
            SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'),
                   TO_CHAR (SYSDATE, 'HH24MISS')
              INTO v_business_date,
                   v_business_time
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting date' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         v_rrn1 := v_rrn1 + 1;
         v_rrn2 := 'AF' || v_business_date || v_rrn1;

      --En moved up to handle RRN null issue for defect Host-328

      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no,
                    cam_type_code                             -- Added on 17-Apr-2013 for defect 10871
               INTO v_acct_bal, v_ledger_bal, v_acct_number,
                    v_cam_type_code                           -- Added on 17-Apr-2013 for defect 10871
               FROM cms_acct_mast
              WHERE cam_inst_code = p_instcode
                AND cam_acct_no =   p_acct_no  --Commented and modified on 06.09.2013 for DFCHOST-340(review)
                /*
                       (SELECT cap_acct_no
                          FROM cms_appl_pan
                         WHERE cap_pan_code = p_hashpan
                           AND cap_inst_code = p_instcode)*/
         FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg := 'Account Details Not Found in Master';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while selecting data from Account Master' || SQLERRM;
            RAISE exp_reject_record;
      END;

      v_pan_code := fn_dmaps_main (p_encrpan);
      v_fee_amnt := p_fee_amnt - p_waiv_amnt;

 

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
            p_errmsg := 'No Currency Found for the bin profile';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error in selecting bin currency '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --SN Added and moved here to avoid repetation on 06.09.2013 for DFCHOST-340(review)
      BEGIN
           SELECT ctm_tran_desc,ctm_credit_debit_flag
              INTO v_tran_desc,v_dr_cr_flag
              FROM cms_transaction_mast
             WHERE ctm_inst_code = p_instcode
               AND ctm_tran_code = v_txn_code
               AND ctm_delivery_channel = v_delivery_channel;

      EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting narration and CR/DR flag'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;

      END;
     --EN Added and moved here to avoid repetation on 06.09.2013 for DFCHOST-340(review)


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

       --SN Added on 06.09.2013 for DFCHOST-340(review)
          IF p_errmsg <> 'OK' THEN
              RAISE exp_reject_record;
          END IF;
       --SN Added on 06.09.2013 for DFCHOST-340(review)
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_errmsg :=
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

    IF P_CLAWBACK = 'N' THEN

     IF V_ACCT_BAL > 0 THEN
       IF (V_ACCT_BAL >= V_FEE_AMNT) THEN
            v_debit_amnt := v_fee_amnt;
         --v_fee_amount := p_fee_amnt;
         ELSE
            v_debit_amnt := v_acct_bal;
         -- v_fee_amount := 0;
         END IF;
      ELSE
         -- v_fee_amount:=p_fee_amnt;
         v_debit_amnt := 0;
      END IF;
     V_CLAWBACK_AMNT := 0;
    ELSE
     IF V_ACCT_BAL > 0 THEN
       IF (V_ACCT_BAL >= V_FEE_AMNT) THEN
        V_DEBIT_AMNT    := V_FEE_AMNT;
        V_CLAWBACK_AMNT := 0;
       ELSE
        V_DEBIT_AMNT    := V_ACCT_BAL;
        V_CLAWBACK_AMNT := V_FEE_AMNT - V_DEBIT_AMNT;
       END IF;
     ELSE
       V_CLAWBACK_AMNT := V_FEE_AMNT;
       V_DEBIT_AMNT    := 0;
     END IF;
    END IF;

      IF (v_debit_amnt > 0 OR (V_CLAWBACK_AMNT > 0) )
      THEN
         BEGIN
            UPDATE cms_acct_mast
               SET cam_acct_bal = ROUND(cam_acct_bal - v_debit_amnt,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                   cam_ledger_bal = ROUND(cam_ledger_bal - v_debit_amnt,2)--Modified by Revathi on 02-APR-2014 for 3decimal place issue
             WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_instcode;

            IF SQL%ROWCOUNT = 0
            THEN
               p_errmsg :=
                   'Error while updating balance' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END IF;
          --SN Added on 06.09.2013 for DFCHOST-340(review)
         EXCEPTION
         WHEN exp_reject_record THEN
           RAISE exp_reject_record;
         WHEN OTHERS THEN
               p_errmsg :=
                   'Error while updating balance' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
          --EN Added on 06.09.2013 for DFCHOST-340(review)
         END;
      END IF;



      IF (v_debit_amnt > 0 OR (P_CLAWBACK = 'Y'))
      THEN
         BEGIN
            --            SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO v_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

       /*  BEGIN
            SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'),
                   TO_CHAR (SYSDATE, 'HH24MISS')
              INTO v_business_date,
                   v_business_time
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting date' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         v_rrn1 := v_rrn1 + 1;
         v_rrn2 := 'AF' || v_business_date || v_rrn1;*/

         --V_PAN_CODE := FN_DMAPS_MAIN(P_ENCRPAN);
         BEGIN
         --SN Commented on 06.09.2013 for DFCHOST-340(review)
           /* SELECT ctm_tran_desc
              INTO v_tran_desc
              FROM cms_transaction_mast
             WHERE ctm_tran_code = v_txn_code
               AND ctm_delivery_channel = v_delivery_channel
               AND ctm_inst_code = p_instcode;*/
          --EN Commented on 06.09.2013 for DFCHOST-340(review)

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
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting narration'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
       --Sn Commented on 06.09.2013 for DFCHOST-340(review)
      /*  BEGIN

         SELECT CAP_PROD_CODE,
                CAP_CARD_TYPE
           INTO V_PROD_CODE,
                V_PROD_CATTYPE
           FROM CMS_APPL_PAN
          WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = P_HASHPAN; --P_card_no;
       EXCEPTION
       WHEN OTHERS THEN
         NULL;
       END;*/
       --En Commented on 06.09.2013 for DFCHOST-340(review)
      --Sn Commented on 06.09.2013 for DFCHOST-340(review)
      /* BEGIN
             SELECT CTM_CREDIT_DEBIT_FLAG
             INTO   V_DR_CR_FLAG
             FROM   CMS_TRANSACTION_MAST
             WHERE CTM_TRAN_CODE = V_TXN_CODE
             AND   CTM_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL
             AND   CTM_INST_CODE = P_INSTCODE;
       EXCEPTION
         WHEN OTHERS THEN
         NULL;
       END;*/
      --En Commented on 06.09.2013 for DFCHOST-340(review)
         v_timestamp := systimestamp;              -- Added on 17-Apr-2013 for defect 10871

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
                         csl_acct_type,         -- added on 17-apr-2013 for defect 10871
                         csl_time_stamp,         -- added on 17-apr-2013 for defect 10871
                         csl_prod_code,csl_card_type
                        )
                 VALUES (p_hashpan, v_acct_number,ROUND(v_ledger_bal,2),    -- v_acct_bal removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         ROUND(v_debit_amnt,2), 'DR', SYSDATE,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         ROUND(v_ledger_bal - v_debit_amnt,2), v_narration,  -- v_acct_bal removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                         p_encrpan, v_rrn2, v_auth_id,
                         v_business_date, v_business_time, 'Y',
                         v_delivery_channel, p_instcode, v_txn_code,
                         SYSDATE, 1,
                         (SUBSTR (v_pan_code,
                                  LENGTH (v_pan_code) - 3,
                                  LENGTH (v_pan_code)
                                 )
                         ),
                        v_cam_type_code,   -- added on 16-apr-2013 for defect 10871
                        v_timestamp,        -- Added on 16-Apr-2013 for defect 10871
                        --- v_prod_code        -- Added on 17-Apr-2013 for defect 10871
                         p_prod_code,p_card_type --Commented and modified on 06.09.2013 for DFCHOST-340(review)
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error creating entry in statement log '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            sp_ins_eodupdate_acct_cmsauth (v_rrn2,                   --prm_rrn
                                           NULL,            -- prm_terminal_id
                                           v_delivery_channel,
                                           v_txn_code,
                                           0,
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
                     'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH'
                  || p_errmsg;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
           --SN Added on 06.09.2013 for DFCHOST-340(review)
            WHEN exp_reject_record THEN
              RAISE;
            --EN Added on 06.09.2013 for DFCHOST-340(review)
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH'
                  || SUBSTR (SQLERRM, 1, 250);
               RAISE exp_reject_record;
         END;

         v_upd_rec_cnt := v_upd_rec_cnt + 1;
      END IF;
    BEGIN

       IF P_CLAWBACK = 'Y' AND V_CLAWBACK_AMNT > 0 THEN

       V_FILE_STATUS := 'C';

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
                                         AND ccd_pan_code = P_HASHPAN
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

       --Added by Deepa on July 02 2012 to maintain clawback amount details in separate table

       BEGIN

        BEGIN
        SELECT COUNT(*)
          INTO V_CLAWBACK_COUNT
          FROM CMS_ACCTCLAWBACK_DTL
         WHERE CAD_INST_CODE = P_INSTCODE AND
              CAD_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
              CAD_TXN_CODE = V_TXN_CODE AND CAD_PAN_CODE = P_HASHPAN AND
              CAD_ACCT_NO = V_ACCT_NUMBER; -- Modified for FWR-11
        --SN Added on 06.09.2013 for DFCHOST-340(review)
        EXCEPTION
        WHEN OTHERS THEN
              P_ERRMSG := 'Error while selecting count from ACCTCLAWBACK_DTL' ||
                    SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
        --EN Added on 06.09.2013 for DFCHOST-340(review)
        END;

        IF V_CLAWBACK_COUNT = 0 THEN

          BEGIN
          INSERT INTO CMS_ACCTCLAWBACK_DTL
            (CAD_INST_CODE,
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
            CAD_LUPD_USER)
          VALUES
            (P_INSTCODE,
            V_ACCT_NUMBER,
            P_HASHPAN,
            P_ENCRPAN,
            ROUND(V_CLAWBACK_AMNT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
            'N',
            SYSDATE,
            SYSDATE,
            V_DELIVERY_CHANNEL,
            V_TXN_CODE,
            '1',
            '1');
              --SN Added on 06.09.2013 for DFCHOST-340(review)
          EXCEPTION
            WHEN OTHERS THEN
                  P_ERRMSG := 'Error while inserting records into ACCTCLAWBACK_DTL' ||
                        SUBSTR(SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
            --EN Added on 06.09.2013 for DFCHOST-340(review)
          END;
       ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count then  -- Modified for fwr 64

          BEGIN
          UPDATE CMS_ACCTCLAWBACK_DTL
            SET CAD_CLAWBACK_AMNT = ROUND(CAD_CLAWBACK_AMNT + V_CLAWBACK_AMNT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                CAD_RECOVERY_FLAG = 'N',
                CAD_LUPD_DATE     = SYSDATE
           WHERE CAD_INST_CODE = P_INSTCODE AND
                CAD_ACCT_NO = V_ACCT_NUMBER AND CAD_PAN_CODE = P_HASHPAN AND
                CAD_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
                CAD_TXN_CODE = V_TXN_CODE;

        --SN Added on 06.09.2013 for DFCHOST-340(review)
            IF SQL%ROWCOUNT =0 THEN
                P_ERRMSG := 'No records updated in ACCTCLAWBACK_DTL';
              RAISE EXP_REJECT_RECORD;
            END IF;

        EXCEPTION
        WHEN OTHERS THEN
              P_ERRMSG := 'Error while updating ACCTCLAWBACK_DTL' ||
                    SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
        --EN Added on 06.09.2013 for DFCHOST-340(review)
          END;

        END IF;
       EXCEPTION
        WHEN OTHERS THEN
          P_ERRMSG := 'Error while inserting Account ClawBack details' ||
                    SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;

       END;

     ELSIF V_DEBIT_AMNT = P_FEE_AMNT THEN

       V_FILE_STATUS := 'Y';

     ELSE

       V_FILE_STATUS := 'N';

     END IF;
      if v_chrg_dtl_cnt < v_tot_clwbck_count THEN  -- Modified for fwr 64

     BEGIN
      INSERT INTO CMS_CHARGE_DTL
       (CCD_INST_CODE,
        CCD_PAN_CODE,
        CCD_MBR_NUMB,
        CCD_ACCT_NO,
        CCD_FEE_FREQ,
        CCD_FEETYPE_CODE,
        CCD_FEE_CODE,
        CCD_CALC_AMT,
        CCD_EXPCALC_DATE,
        CCD_CALC_DATE,
        CCD_FILE_NAME,
        CCD_FILE_DATE,
        CCD_INS_USER,
        CCD_LUPD_USER,
        CCD_FILE_STATUS,
        CCD_RRN,
        CCD_DEBITED_AMNT,
        CCD_PROCESS_MSG,
        CCD_CLAWBACK_AMNT,
        CCD_CLAWBACK,
        CCD_FEE_PLAN,
        CCD_PAN_CODE_ENCR,
        CCD_GL_ACCT_NO,
        CCD_DELIVERY_CHANNEL,
        CCD_TXN_CODE,
        CCD_FEEATTACHTYPE)
     VALUES
       (P_INSTCODE,
        P_HASHPAN,
        '000',
        V_ACCT_NUMBER,
        P_FEE_FREQ,
        P_FEETYPE_CODE,
        P_FEE_CODE,
        ROUND(P_FEE_AMNT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
        SYSDATE,
        SYSDATE,
        'N',
        SYSDATE,
        P_LUPDUSER,
        P_LUPDUSER,
        V_FILE_STATUS,
        V_RRN2,
        ROUND(V_DEBIT_AMNT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
        P_ERRMSG,
        ROUND(V_CLAWBACK_AMNT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
        P_CLAWBACK,
        P_FEE_PLAN,
        P_ENCRPAN,
        P_CR_ACCTNO,
        V_DELIVERY_CHANNEL,
        V_TXN_CODE,
        P_ATTACH_TYPE);
     --SN Added on 06.09.2013 for DFCHOST-340(review)
        /* IF SQL%ROWCOUNT = 0 THEN
           P_ERRMSG := 'Error while inserting Fee details' ||
                    SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
         END IF;*/
     EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG := 'Error while inserting Fee details' ||
                    SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
      --EN Added on 06.09.2013 for DFCHOST-340(review)
     END;
      else --Added for Defect id : 15544
           v_err_msg :='CLAW BLACK WAIVED';
     end if;
    END;

   /*   BEGIN
         INSERT INTO cms_charge_dtl
                     (ccd_inst_code, ccd_pan_code, ccd_mbr_numb,
                      ccd_acct_no, ccd_fee_freq, ccd_feetype_code,
                      ccd_fee_code, ccd_calc_amt, ccd_expcalc_date,
                      ccd_calc_date, ccd_file_name, ccd_file_date,
                      ccd_ins_user, ccd_lupd_user, ccd_file_status, ccd_rrn,
                      ccd_debited_amnt, ccd_process_msg, ccd_clawback,
                      ccd_fee_plan, ccd_delivery_channel, ccd_txn_code,CCD_FEEATTACHTYPE
                     )
              VALUES (p_instcode, p_hashpan, '000',
                      v_acct_number, p_fee_freq, p_feetype_code,
                      p_fee_code, p_fee_amnt, SYSDATE,
                      SYSDATE, 'N', SYSDATE,
                      p_lupduser, p_lupduser, 'N', v_rrn2,
                      v_debit_amnt, p_errmsg, p_clawback,
                      p_fee_plan, v_delivery_channel, v_txn_code,p_attach_type
                     );

         IF SQL%ROWCOUNT = 0
         THEN
            v_err_msg :=
               'Error while inserting Fee details'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
         END IF;
      END;*/
    --Added by Deepa on Oct-22-2012 to log the Fee Details in transactionlog

    -----------------------------
    --SN: Added for defect 10871
    -----------------------------
      --SN Commented on  06.09.2013 for DFCHOST-340(review)
      /*Begin

        select cap_prod_code,cap_card_stat,cap_card_type,cap_acct_id
        into   v_prod_code,v_card_type,v_card_stat,v_acct_id
        from   cms_appl_pan
        where  cap_inst_code = p_instcode
        and    cap_pan_code = p_hashpan;

      exception when no_data_found
      then
          p_errmsg := 'Product details not found in pan_master';
          RAISE exp_reject_record;
      when others
      then
          p_errmsg :=  'Error occured while fetching Product details '||substr(sqlerrm,1,100);
          RAISE exp_reject_record;

      End;*/
      --EN Commented on  06.09.2013 for DFCHOST-340(review)

      Begin

        select cam_type_code
        into   v_cam_type_code
        from   cms_acct_mast
        where  cam_inst_code = p_instcode
        --and    cam_acct_id   = v_acct_id;--Commented and modified on 06.09.2013 for DFCHOST-340(review)
        and    cam_acct_id   = p_acct_id;


      exception when no_data_found
      then
          p_errmsg := 'AcctType not found in acct_master for acct_id '||p_acct_id;
          RAISE exp_reject_record;
      when others
      then
          p_errmsg :=   'Error occured while fetching acct_type '||substr(sqlerrm,1,100);
          RAISE exp_reject_record;

      End;

    -----------------------------
    --EN: Added for defect 10871
    -----------------------------

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
                          p_fee_amnt,
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
                          v_timestamp,      --Added for defect 10871
                          v_err_msg,        --Added for defect 10871
                          --v_prod_code,      --Added for defect 10871
                          p_prod_code,      --Commented and modified on 06.09.2013 for DFCHOST-340(review)
                          --v_card_type,      --Added for defect 10871
                          p_card_type,     --Commented and modified on 06.09.2013 for DFCHOST-340(review)
                          v_cam_type_code   --Added for defect 10871
                         );
   EXCEPTION
      WHEN exp_reject_record
      THEN
         p_errmsg := 'Error in update account ' || SUBSTR (SQLERRM, 1, 200);
         BEGIN

         INSERT INTO cms_charge_dtl
                     (ccd_inst_code, ccd_pan_code, ccd_mbr_numb,
                      ccd_acct_no, ccd_fee_freq, ccd_feetype_code,
                      ccd_fee_code, ccd_calc_amt, ccd_expcalc_date,
                      ccd_calc_date, ccd_file_name, ccd_file_date,
                      ccd_ins_user, ccd_lupd_user, ccd_file_status, ccd_rrn,
                      ccd_process_msg, ccd_fee_plan, ccd_delivery_channel,
                      ccd_txn_code
                     )
              VALUES (p_instcode, p_hashpan, '000',
                      v_acct_number, p_fee_freq, p_feetype_code,
                      p_fee_code, ROUND(p_fee_amnt,2), SYSDATE,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                      SYSDATE, 'N', SYSDATE,
                      p_lupduser, p_lupduser, 'N', v_rrn2,
                      p_errmsg, p_fee_plan, v_delivery_channel,
                      v_txn_code
                     );
         --SN Added on 06.09.2013 for DFCHOST-340(review)
         EXCEPTION
         WHEN OTHERS THEN
           p_errmsg := 'Error while inserting into charge detl 1.0 ' || SUBSTR (SQLERRM, 1, 200);
         --EN Added on 06.09.2013 for DFCHOST-340(review)
         END;

        -----------------------------
        --SN: Added for defect 10871
        -----------------------------


     -- if v_prod_code is null then --Commented and modified on 06.09.2013 for DFCHOST-340(review)
      if v_cam_type_code is null then
         --SN Commented on 06.09.2013 for DFCHOST-340(review)
         /* Begin

            select cap_prod_code,cap_card_stat,cap_card_type,cap_acct_id
            into   v_prod_code,v_card_type,v_card_stat,v_acct_id
            from   cms_appl_pan
            where  cap_inst_code = p_instcode
            and    cap_pan_code = p_hashpan;

          exception when no_data_found
          then
              p_errmsg := 'Product details not found in pan_master';
          when others
          then
              p_errmsg :=  'Error occured while fetching Product details '||substr(sqlerrm,1,100);

          End;*/
          --EN Commented and modified on 06.09.2013 for DFCHOST-340(review)

          Begin

            select cam_type_code
            into   v_cam_type_code
            from   cms_acct_mast
            where  cam_inst_code = p_instcode
            --and    cam_acct_id   = v_acct_id;--Commented and modified on 06.09.2013 for DFCHOST-340(review)
             and    cam_acct_id   = p_acct_id;


          exception when no_data_found
          then
              p_errmsg := 'AcctType not found in acct_master for acct_id '||p_acct_id;
          when others
          then
              p_errmsg :=   'Error occured while fetching acct_type '||substr(sqlerrm,1,100);

          End;

      end if;
        -----------------------------
        --EN: Added for defect 10871
        -----------------------------


        v_timestamp := systimestamp;              -- Added on 17-Apr-2013 for defect 10871

        --Added by Deepa on Oct-22-2012 to log the Fee Details in transactionlog
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
                             v_timestamp,      --Added for defect 10871
                             p_errmsg,         --Added for defect 10871
                             --v_prod_code,      --Added for defect 10871
                             p_prod_code,    --Commented and modified on 06.09.2013 for DFCHOST-340(review)
                             --v_card_type,      --Added for defect 10871
                             p_card_type,      --Commented and modified on 06.09.2013 for DFCHOST-340(review)
                             v_cam_type_code   --Added for defect 10871
                            );
      WHEN OTHERS
      THEN
         p_errmsg := 'Error in update account ' || SUBSTR (SQLERRM, 1, 200);

         BEGIN
         INSERT INTO cms_charge_dtl
                     (ccd_inst_code, ccd_pan_code, ccd_mbr_numb,
                      ccd_acct_no, ccd_fee_freq, ccd_feetype_code,
                      ccd_fee_code, ccd_calc_amt, ccd_expcalc_date,
                      ccd_calc_date, ccd_file_name, ccd_file_date,
                      ccd_ins_user, ccd_lupd_user, ccd_file_status, ccd_rrn,
                      ccd_process_msg, ccd_fee_plan, ccd_delivery_channel,
                      ccd_txn_code
                     )
              VALUES (p_instcode, p_hashpan, '000',
                      v_acct_number, p_fee_freq, p_feetype_code,
                      p_fee_code,ROUND(p_fee_amnt,2), SYSDATE,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                      SYSDATE, 'N', SYSDATE,
                      p_lupduser, p_lupduser, 'N', v_rrn2,
                      p_errmsg, p_fee_plan, v_delivery_channel,
                      v_txn_code
                     );
         --SN Added on 06.09.2013 for DFCHOST-340(review)
         EXCEPTION
         WHEN OTHERS THEN
           p_errmsg := 'Error while inserting into charge detl 1.1 ' || SUBSTR (SQLERRM, 1, 200);
         --EN Added on 06.09.2013 for DFCHOST-340(review)
         END;

        -----------------------------
        --SN: Added for defect 10871
        -----------------------------

      --if v_prod_code is null  then --Commented and modified on 06.09.2013 for DFCHOST-340(review)
      if v_cam_type_code is null  then

         --SN Commented on 06.09.2013 for DFCHOST-340(review)
          /*Begin

            select cap_prod_code,cap_card_stat,cap_card_type,cap_acct_id
            into   v_prod_code,v_card_type,v_card_stat,v_acct_id
            from   cms_appl_pan
            where  cap_inst_code = p_instcode
            and    cap_pan_code = p_hashpan;

          exception when no_data_found
          then
              p_errmsg := 'Product details not found in pan_master';
          when others
          then
              p_errmsg :=  'Error occured while fetching Product details '||substr(sqlerrm,1,100);

          End;*/
           --EN Commented and modified on 06.09.2013 for DFCHOST-340(review)

          Begin

            select cam_type_code
            into   v_cam_type_code
            from   cms_acct_mast
            where  cam_inst_code = p_instcode
            --and    cam_acct_id   = v_acct_id; --Commented and modified on 06.09.2013 for DFCHOST-340(review)
            and    cam_acct_id   = p_acct_id;

          exception when no_data_found
          then
              p_errmsg := 'AcctType not found in acct_master for acct_id '||p_acct_id;
          when others
          then
              p_errmsg :=   'Error occured while fetching acct_type '||substr(sqlerrm,1,100);

          End;

      end if;
        -----------------------------
        --EN: Added for defect 10871
        -----------------------------

       v_timestamp := systimestamp;              -- Added on 17-Apr-2013 for defect 10871

        --Added by Deepa on Oct-22-2012 to log the Fee Details in transactionlog
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
                             v_timestamp,      --Added for defect 10871
                             p_errmsg,         --Added for defect 10871
                             v_prod_code,      --Added for defect 10871
                             v_card_type,      --Added for defect 10871
                             v_cam_type_code   --Added for defect 10871
                            );
   END lp_fee_update_log;
BEGIN
   --Sn InActivity Fee Calculation for the Card
   BEGIN
      FOR c1 IN cardfee
      LOOP
         lp_monthly_fee_calc (c1.cfm_date_assessment,
                              c1.cfm_proration_flag,
                              c1.cfm_fee_amt,
                              c1.cap_next_bill_date,
                              c1.cce_pan_code,
                              p_instcode,
                              c1.cap_active_date,
                              v_cfm_fee_amt,
                              v_err_msg
                             );



         IF v_err_msg = 'OK'
         THEN
           IF C1.CFM_FEECAP_FLAG ='Y' then
           Begin
            SP_TRAN_FEES_CAP(P_INSTCODE,
                        C1.CAP_ACCT_NO,
                        TRUNC(SYSDATE),
                        V_CFM_FEE_AMT,
                        C1.CFF_FEE_PLAN,
                        C1.CFM_FEE_CODE,
                        V_ERR_MSG
                      ); -- Added for FWR-11
            exception
              when others
              then
                  p_errmsg :=   'Error occured in fee cap '||substr(sqlerrm,1,200);

              End;

             End if;

            BEGIN
               SELECT cce_waiv_prcnt
                 INTO v_cpw_waiv_prcnt
                 FROM cms_card_excpwaiv
                WHERE cce_inst_code = p_instcode
                  AND cce_pan_code = c1.cce_pan_code
                  AND cce_fee_code = c1.cfm_fee_code
                  AND cce_fee_plan = c1.cff_fee_plan
                  AND
                      --SYSDATE >= CCE_VALID_FROM AND SYSDATE <= CCE_VALID_TO;
                      (   (    cce_valid_to IS NOT NULL
                           AND (SYSDATE BETWEEN cce_valid_from AND cce_valid_to
                               )
                          )
                       OR (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from
                          )
                      );

               v_waivamt := (v_cpw_waiv_prcnt / 100) * v_cfm_fee_amt;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_waivamt := 0;
            --p_err_msg := 'Lp1.1 card -- ' || SQLERRM;
            END;

            -- V_FEEAMT := V_CFM_FEE_AMT - V_WAIVAMT;
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
                               c1.cap_acct_no, --Added on 06.09.2013 for DFCHOST-340(review)
                               c1.cap_prod_code, --Added on 06.09.2013 for DFCHOST-340(review)
                               c1.cap_card_type, --Added on 06.09.2013 for DFCHOST-340(review)
                               c1.cap_acct_id, --Added on 06.09.2013 for DFCHOST-340(review)
                               v_err_msg
                              );


               IF (C1.cap_next_bill_date IS NULL OR C1.cap_next_bill_date < c1.cap_active_date) and TRUNC(c1.cap_active_date) < TRUNC(SYSDATE) -- IF condition added for defect HOST-328
               THEN
                  IF  TRUNC(ADD_MONTHS (C1.cap_active_date,24)) >=  TRUNC(SYSDATE) then
                      V_NEXT_BILL_DATE := ADD_MONTHS (c1.cap_active_date,24);
                  ELSE
                      V_NEXT_BILL_DATE := ADD_MONTHS (c1.cap_active_date,12);
                  END IF;

               elsIF C1.cap_next_bill_date IS NOT NULL and TRUNC(C1.cap_next_bill_date) < TRUNC(SYSDATE)
               THEN
                    V_NEXT_BILL_DATE := ADD_MONTHS (C1.cap_next_bill_date,12);
               ELSE
                    V_NEXT_BILL_DATE := ADD_MONTHS(SYSDATE, 12);
               END IF;

            -- IF v_err_msg='OK' THEN
            BEGIN
            UPDATE cms_appl_pan
               SET cap_next_bill_date = V_NEXT_BILL_DATE --ADD_MONTHS (SYSDATE, 12) -- Changed for defect HOST-328
             WHERE cap_pan_code = c1.cce_pan_code
               AND cap_card_stat NOT IN ('9')
               AND cap_inst_code = p_instcode;
              --SN  Added on 06.09.2013 for DFCHOST-340(review)
                 IF SQL%ROWCOUNT =0 THEN
                   p_errmsg :=  'No record updated in APPL_PAN 1.0';
                 END IF;

            EXCEPTION
            WHEN OTHERS THEN
                p_errmsg :=  'Error while updating APPL_PAN 1.0 --'||SUBSTR(SQLERRM,1,200);
               --EN  Added on 06.09.2013 for DFCHOST-340(review)
            END;
         --AND cap_card_stat = '1'
         --and CAP_EXPRY_DATE > sysdate;
         -- and trunc(add_months(CAP_INACTIVE_FEECALC_DATE,1))<=trunc(sysdate);
         -- END IF;
         --Sn added on 10.09.2013 for DFCHOST-340(review)
         ELSIF  v_err_msg <>'NO FEES' THEN



                BEGIN
                   SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'), TO_CHAR (SYSDATE, 'HH24MISS')
                     INTO v_business_date, v_business_time
                     FROM DUAL;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      p_errmsg := 'Error while selecting date' || SUBSTR (SQLERRM, 1, 200);
                END;

                 v_rrn1 := v_rrn1 + 1;
                 v_rrn2 := 'AF' || v_business_date || v_rrn1;


                BEGIN
                   SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
                     INTO v_auth_id
                     FROM DUAL;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      v_err_msg :=
                                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 200);
                END;


                BEGIN
                   SELECT ctm_tran_desc
                     INTO v_tran_desc
                     FROM cms_transaction_mast
                    WHERE ctm_tran_code = v_txn_code
                      AND ctm_delivery_channel = v_delivery_channel
                      AND ctm_inst_code = p_instcode;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      v_err_msg :=
                               'Error while selecting tran desc-' || SUBSTR (SQLERRM, 1, 200);
                END;


                BEGIN
                   SELECT cam_type_code,cam_acct_bal,cam_ledger_bal
                     INTO v_cam_type_code, v_acct_bal,
                          v_ledger_bal
                     FROM cms_acct_mast
                    WHERE cam_inst_code = p_instcode AND cam_acct_id = c1.cap_acct_id;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      v_err_msg :=
                           'AcctType not found in acct_master for acct_id ' || c1.cap_acct_id;
                   WHEN OTHERS
                   THEN
                      v_err_msg :=
                         'Error occured while fetching acct_type '
                         || SUBSTR (SQLERRM, 1, 100);
                END;

              v_timestamp := systimestamp;

               lp_transaction_log (p_instcode,
                          c1.cce_pan_code,
                          c1.cce_pan_code_encr,
                          v_rrn2,
                          v_delivery_channel,
                          v_business_date,
                          v_business_time,
                          c1.cap_acct_no,
                          v_acct_bal,
                          v_ledger_bal,
                          --p_fee_amnt,
                          null,
                          v_auth_id,
                          v_tran_desc,
                          v_txn_code,
                          21,
                          null,
                          null,
                          c1.cfm_fee_code,
                          c1.cff_fee_plan,
                          c1.cce_cracct_no,
                          c1.cce_dracct_no,
                          'C',
                          c1.cap_card_stat,
                          v_timestamp,
                          v_err_msg,
                          c1.cap_prod_code,
                          c1.cap_card_type,
                          v_cam_type_code
                         );


         --En added on 10.09.2013 for DFCHOST-340(review)
         END IF;
      END LOOP;
   END;

   --En InActivity Fee Calculation for the Card
   --Sn InActivity Fee Calculation for the Product Category
   BEGIN
      FOR c2 IN prodcatgfee
      LOOP

      --SN Added on 03.09.2013 for DFCHOST-340
      BEGIN
        select COUNT(CASE WHEN  (cce_valid_to IS NOT NULL AND (trunc(sysdate) between cce_valid_from and cce_valid_to))
             OR (cce_valid_to IS NULL AND trunc(sysdate) >= cce_valid_from)   THEN
              1 END)
        into   v_card_cnt
        from  cms_card_excpfee
        where cce_inst_code = p_instcode
        and   cce_pan_code = c2.cap_pan_code ;
      EXCEPTION
      WHEN OTHERS THEN
          v_card_cnt := 0;
      END;
     --EN Added on 03.09.2013 for DFCHOST-340

       IF v_card_cnt = 0 THEN --Added on 03.09.2013 for DFCHOST-340
         lp_monthly_fee_calc (c2.cfm_date_assessment,
                              c2.cfm_proration_flag,
                              c2.cfm_fee_amt,
                              c2.cap_next_bill_date,
                              c2.cap_pan_code,
                              p_instcode,
                              c2.cap_active_date,
                              v_cfm_fee_amt,
                              v_err_msg
                             );

         IF v_err_msg = 'OK'
         THEN
        IF C2.CFM_FEECAP_FLAG ='Y' then
            Begin
                SP_TRAN_FEES_CAP(P_INSTCODE,
                            C2.CAP_ACCT_NO,
                            TRUNC(SYSDATE),
                            V_FEE_AMOUNT,
                            C2.CFF_FEE_PLAN,
                            C2.CFM_FEE_CODE,
                            V_ERR_MSG
                          ); -- Added for FWR-11
              exception
                  when others
                  then
                      p_errmsg :=   'Error occured in fee cap '||substr(sqlerrm,1,200);

                  End;
                End if;
            BEGIN
               SELECT cpw_waiv_prcnt
                 INTO v_cpw_waiv_prcnt
                 FROM cms_prodcattype_waiv
                WHERE cpw_inst_code = p_instcode
                  AND cpw_prod_code = c2.cpf_prod_code
                  AND cpw_card_type = c2.cpf_card_type
                  AND cpw_fee_code = c2.cfm_fee_code
                  AND SYSDATE >= cpw_valid_from
                  AND SYSDATE <= cpw_valid_to;

               v_waivamt := (v_cpw_waiv_prcnt / 100) * v_cfm_fee_amt;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_waivamt := 0;
            --p_err_msg := 'Lp1.1 card -- ' || SQLERRM;
            END;

            --  V_FEEAMT := V_CFM_FEE_AMT - V_WAIVAMT;
            lp_fee_update_log (p_instcode,
                               c2.cap_pan_code,
                               c2.cap_pan_code_encr,
                               c2.cfm_fee_code,
                               v_cfm_fee_amt,
                               c2.cff_fee_plan,
                               -- c2.cpf_card_type,
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
                               c2.cap_acct_no, --Added on 06.09.2013 forDFCHOST-340(review)
                               c2.cap_prod_code, --Added on 06.09.2013 for DFCHOST-340(review)
                               c2.cap_card_type, --Added on 06.09.2013 for DFCHOST-340(review)
                               c2.cap_acct_id, --Added on 06.09.2013 for DFCHOST-340(review)
                               v_err_msg
                              );

               IF (C2.cap_next_bill_date IS NULL OR C2.cap_next_bill_date < c2.cap_active_date) and TRUNC(c2.cap_active_date) < TRUNC(SYSDATE) -- IF condition added for defect HOST-328
               THEN
                  IF  TRUNC(ADD_MONTHS (C2.cap_active_date,24)) >=  TRUNC(SYSDATE) then
                      V_NEXT_BILL_DATE := ADD_MONTHS (c2.cap_active_date,24);
                  ELSE
                      V_NEXT_BILL_DATE := ADD_MONTHS (c2.cap_active_date,12);
                  END IF;

               elsIF C2.cap_next_bill_date IS NOT NULL and TRUNC(C2.cap_next_bill_date) < TRUNC(SYSDATE)
               THEN
                    V_NEXT_BILL_DATE := ADD_MONTHS (C2.cap_next_bill_date,12);
               ELSE
                    V_NEXT_BILL_DATE := ADD_MONTHS(SYSDATE, 12);
               END IF;

            IF v_err_msg = 'OK'
            THEN
             BEGIN
               UPDATE cms_appl_pan
                  SET cap_next_bill_date = V_NEXT_BILL_DATE --ADD_MONTHS (SYSDATE, 12) -- Changed for defect HOST-328
                WHERE cap_pan_code = c2.cap_pan_code
                  AND cap_card_stat NOT IN ('9')
                  AND cap_inst_code = p_instcode;
                    --SN  Added on 06.09.2013 for DFCHOST-340(review)
                 IF SQL%ROWCOUNT =0 THEN
                   p_errmsg :=  'No record updated in APPL_PAN 1.1';
                 END IF;

                EXCEPTION
                WHEN OTHERS THEN
                    p_errmsg :=  'Error while updating APPL_PAN 1.1 --'||SUBSTR(SQLERRM,1,200);
                   --EN  Added on 06.09.2013 for DFCHOST-340(review)
                END;
            --AND cap_card_stat = '1'
            --and CAP_EXPRY_DATE > sysdate;
            -- and trunc(add_months(CAP_INACTIVE_FEECALC_DATE,1))<=trunc(sysdate);
            END IF;
         --Sn added on 10.09.2013 for DFCHOST-340(review)
         ELSIF  v_err_msg <>'NO FEES' THEN



                BEGIN
                   SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'), TO_CHAR (SYSDATE, 'HH24MISS')
                     INTO v_business_date, v_business_time
                     FROM DUAL;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      p_errmsg := 'Error while selecting date' || SUBSTR (SQLERRM, 1, 200);
                END;

                 v_rrn1 := v_rrn1 + 1;
                 v_rrn2 := 'AF' || v_business_date || v_rrn1;


                BEGIN
                   SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
                     INTO v_auth_id
                     FROM DUAL;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      v_err_msg :=
                                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 200);
                END;


                BEGIN
                   SELECT ctm_tran_desc
                     INTO v_tran_desc
                     FROM cms_transaction_mast
                    WHERE ctm_tran_code = v_txn_code
                      AND ctm_delivery_channel = v_delivery_channel
                      AND ctm_inst_code = p_instcode;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      v_err_msg :=
                               'Error while selecting tran desc-' || SUBSTR (SQLERRM, 1, 200);
                END;


                BEGIN
                   SELECT cam_type_code,cam_acct_bal,cam_ledger_bal
                     INTO v_cam_type_code, v_acct_bal,
                          v_ledger_bal
                     FROM cms_acct_mast
                    WHERE cam_inst_code = p_instcode AND cam_acct_id = c2.cap_acct_id;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      v_err_msg :=
                           'AcctType not found in acct_master for acct_id ' || c2.cap_acct_id;
                   WHEN OTHERS
                   THEN
                      v_err_msg :=
                         'Error occured while fetching acct_type '
                         || SUBSTR (SQLERRM, 1, 100);
                END;

               v_timestamp := systimestamp;

               lp_transaction_log (p_instcode,
                          c2.cap_pan_code,
                          c2.cap_pan_code_encr,
                          v_rrn2,
                          v_delivery_channel,
                          v_business_date,
                          v_business_time,
                          c2.cap_acct_no,
                          v_acct_bal,
                          v_ledger_bal,
                          --p_fee_amnt,
                          null,
                          v_auth_id,
                          v_tran_desc,
                          v_txn_code,
                          21,
                          null,
                          null,
                          c2.cfm_fee_code,
                          c2.cff_fee_plan,
                          c2.cpf_cracct_no,
                          c2.cpf_dracct_no,
                          'PC',
                          c2.cap_card_stat,
                          v_timestamp,
                          v_err_msg,
                          c2.cap_prod_code,
                          c2.cap_card_type,
                          v_cam_type_code
                         );


         --En added on 10.09.2013 for DFCHOST-340(review)
         END IF;
       END IF;--Added on 03.09.2013 for DFCHOST-340
      END LOOP;
   END;

   --En InActivity Fee Calculation for the Product Category

   --Sn InActivity Fee Calculation for the Product Category
   BEGIN
      FOR c3 IN prodfee
      LOOP

       --SN Added on 03.09.2013 for DFCHOST-340
          BEGIN
            select COUNT(CASE WHEN  (cce_valid_to IS NOT NULL AND (trunc(sysdate) between cce_valid_from and cce_valid_to))
                 OR (cce_valid_to IS NULL AND trunc(sysdate) >= cce_valid_from)   THEN
                  1 END)
            into   v_card_cnt
            from  cms_card_excpfee
            where cce_inst_code = p_instcode
            and   cce_pan_code = c3.cap_pan_code ;
          EXCEPTION
          WHEN OTHERS THEN
              v_card_cnt := 0;
          END;

        IF v_card_cnt = 0 THEN
          BEGIN
           SELECT count (case when ((cpf_valid_to IS NOT NULL AND TRUNC(sysdate) between cpf_valid_from and cpf_valid_to))
                 OR (cpf_valid_to IS NULL AND TRUNC(sysdate) >= cpf_valid_from)then 1 end)
            INTO v_prdcatg_cnt
            FROM cms_prodcattype_fees
            WHERE cpf_inst_code = p_instcode
            AND cpf_prod_code   = c3.cpf_prod_code
            AND cpf_card_type   = c3.cap_card_type;
           EXCEPTION
           WHEN OTHERS THEN
              v_prdcatg_cnt := 0;

          END;
        END IF;
         --EN Added on 03.09.2013 for DFCHOST-340
        IF v_card_cnt = 0 AND v_prdcatg_cnt = 0 THEN --Added on 03.09.2013 for DFCHOST-340
         lp_monthly_fee_calc (c3.cfm_date_assessment,
                              c3.cfm_proration_flag,
                              c3.cfm_fee_amt,
                              c3.cap_next_bill_date,
                              c3.cap_pan_code,
                              p_instcode,
                              c3.cap_active_date,
                              v_cfm_fee_amt,
                              v_err_msg
                             );

         IF v_err_msg = 'OK'
         THEN
           IF C3.CFM_FEECAP_FLAG ='Y' then
       Begin
            SP_TRAN_FEES_CAP(P_INSTCODE,
                    C3.CAP_ACCT_NO,
                    TRUNC(SYSDATE),
                    V_FEE_AMOUNT,
                    C3.CFF_FEE_PLAN,
                    C3.CFM_FEE_CODE,
                    V_ERR_MSG
                  ); -- Added for FWR-11
         exception
          when others
          then
              p_errmsg :=   'Error occured in fee cap '||substr(sqlerrm,1,200);

          End;
         End if;
            BEGIN
               SELECT cpw_waiv_prcnt
                 INTO v_cpw_waiv_prcnt
                 FROM cms_prodccc_waiv
                WHERE cpw_inst_code = p_instcode
                  AND cpw_prod_code = c3.cpf_prod_code
                  AND cpw_fee_code = c3.cfm_fee_code
                  AND SYSDATE >= cpw_valid_from
                  AND SYSDATE <= cpw_valid_to;

               v_waivamt := (v_cpw_waiv_prcnt / 100) * v_cfm_fee_amt;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_waivamt := 0;
            --p_err_msg := 'Lp1.1 card -- ' || SQLERRM;
            END;

            --V_FEEAMT := V_CFM_FEE_AMT - V_WAIVAMT;
            lp_fee_update_log (p_instcode,
                               c3.cap_pan_code,
                               c3.cap_pan_code_encr,
                               c3.cfm_fee_code,
                               v_cfm_fee_amt,
                               c3.cff_fee_plan,
                               --  I2.cap_card_type,
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
                               c3.cap_acct_no, --Added on 06.09.2013 forDFCHOST-340(review)
                               c3.cap_prod_code, --Added on 06.09.2013 for DFCHOST-340(review)
                               c3.cap_card_type, --Added on 06.09.2013 for DFCHOST-340(review)
                               c3.cap_acct_id, --Added on 06.09.2013 for DFCHOST-340(review)
                               v_err_msg
                              );

               IF (C3.cap_next_bill_date IS NULL OR C3.cap_next_bill_date < c3.cap_active_date) and TRUNC(c3.cap_active_date) < TRUNC(SYSDATE) -- IF condition added for defect HOST-328
               THEN
                  IF  TRUNC(ADD_MONTHS (C3.cap_active_date,24)) >=  TRUNC(SYSDATE) then
                      V_NEXT_BILL_DATE := ADD_MONTHS (c3.cap_active_date,24);
                  ELSE
                      V_NEXT_BILL_DATE := ADD_MONTHS (c3.cap_active_date,12);
                  END IF;

               elsIF C3.cap_next_bill_date IS NOT NULL and TRUNC(C3.cap_next_bill_date) < TRUNC(SYSDATE)
               THEN
                    V_NEXT_BILL_DATE := ADD_MONTHS (C3.cap_next_bill_date,12);
               ELSE
                    V_NEXT_BILL_DATE := ADD_MONTHS(SYSDATE, 12);
               END IF;


            IF v_err_msg = 'OK'
            THEN
              BEGIN
               UPDATE cms_appl_pan
                  SET cap_next_bill_date = V_NEXT_BILL_DATE --ADD_MONTHS (SYSDATE, 12) -- Changed for defect HOST-328
                WHERE cap_pan_code = c3.cap_pan_code
                  AND cap_card_stat NOT IN ('9')
                  AND cap_inst_code = p_instcode;

                  --SN  Added on 06.09.2013 for DFCHOST-340(review)
                 IF SQL%ROWCOUNT =0 THEN
                   p_errmsg :=  'No record updated in APPL_PAN 1.2';
                 END IF;

                EXCEPTION
                WHEN OTHERS THEN
                    p_errmsg :=  'Error while updating APPL_PAN 1.2 --'||SUBSTR(SQLERRM,1,200);
                   --EN  Added on 06.09.2013 for DFCHOST-340(review)
                END;
            --AND cap_card_stat = '1'
            -- and CAP_EXPRY_DATE > sysdate;
            END IF;
         --Sn added on 10.09.2013 for DFCHOST-340(review)
         ELSIF  v_err_msg <>'NO FEES' THEN



                BEGIN
                   SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'), TO_CHAR (SYSDATE, 'HH24MISS')
                     INTO v_business_date, v_business_time
                     FROM DUAL;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      p_errmsg := 'Error while selecting date' || SUBSTR (SQLERRM, 1, 200);
                END;

                 v_rrn1 := v_rrn1 + 1;
                 v_rrn2 := 'AF' || v_business_date || v_rrn1;


                BEGIN
                   SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
                     INTO v_auth_id
                     FROM DUAL;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      v_err_msg :=
                                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 200);
                END;


                BEGIN
                   SELECT ctm_tran_desc
                     INTO v_tran_desc
                     FROM cms_transaction_mast
                    WHERE ctm_tran_code = v_txn_code
                      AND ctm_delivery_channel = v_delivery_channel
                      AND ctm_inst_code = p_instcode;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      v_err_msg :=
                               'Error while selecting tran desc-' || SUBSTR (SQLERRM, 1, 200);
                END;


                BEGIN
                   SELECT cam_type_code,cam_acct_bal,cam_ledger_bal
                     INTO v_cam_type_code, v_acct_bal,
                          v_ledger_bal
                     FROM cms_acct_mast
                    WHERE cam_inst_code = p_instcode AND cam_acct_id = c3.cap_acct_id;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      v_err_msg :=
                           'AcctType not found in acct_master for acct_id ' || c3.cap_acct_id;
                   WHEN OTHERS
                   THEN
                      v_err_msg :=
                         'Error occured while fetching acct_type '
                         || SUBSTR (SQLERRM, 1, 100);
                END;

               v_timestamp := systimestamp;

               lp_transaction_log (p_instcode,
                          c3.cap_pan_code,
                          c3.cap_pan_code_encr,
                          v_rrn2,
                          v_delivery_channel,
                          v_business_date,
                          v_business_time,
                          c3.cap_acct_no,
                          v_acct_bal,
                          v_ledger_bal,
                          --p_fee_amnt,
                          null,
                          v_auth_id,
                          v_tran_desc,
                          v_txn_code,
                          21,
                          null,
                          null,
                          c3.cfm_fee_code,
                          c3.cff_fee_plan,
                          c3.cpf_cracct_no,
                          c3.cpf_dracct_no,
                          'P',
                          c3.cap_card_stat,
                          v_timestamp,
                          v_err_msg,
                          c3.cap_prod_code,
                          c3.cap_card_type,
                          v_cam_type_code
                         );


         --En added on 10.09.2013 for DFCHOST-340(review)
         END IF;
        END IF;--Added on 03.09.2013 for DFCHOST-340
      END LOOP;
   END;

   --p_errmsg:='Monthly Fee Calculated for '|| V_UPD_REC_CNT || 'Cards';
   p_errmsg := 'Annual Fee Calculated for ' || v_upd_rec_cnt || 'Cards';
                --Modified by Deepa on June 29 2012 as the procee msg is wrong
EXCEPTION
   WHEN OTHERS
   THEN
      p_errmsg := 'Error in SP_CALC_FEES ' || SUBSTR (SQLERRM, 1, 200);
END;

/

show error