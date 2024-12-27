CREATE OR REPLACE PROCEDURE VMSCMS.SP_CALC_DECLINE_TRANFEES (
   p_inst_code           IN       NUMBER,
   p_card_number         IN       VARCHAR2,
   p_del_channel         IN       VARCHAR2,
   p_tran_mode           IN       VARCHAR2,
   p_tran_code           IN       VARCHAR2,
   p_currency_code       IN       VARCHAR2,
   p_consodium_code      IN       VARCHAR2,
   p_partner_code        IN       VARCHAR2,
   p_trn_amt             IN       NUMBER,
   p_tran_date           IN       VARCHAR2,
   p_tran_time           IN       VARCHAR2,
   p_international_ind   IN       VARCHAR2,
   p_pos_verification    IN       VARCHAR2,
   p_response_code       IN       VARCHAR2,
   p_msg_type            IN       VARCHAR2,
   p_mbr_numb            IN       VARCHAR2,
   p_rrn                 IN       VARCHAR2,
   p_terminal_id         IN       VARCHAR2,
   p_merchant_name       IN       VARCHAR2,
   p_merchant_city       IN       VARCHAR2,
   p_auth_id             IN       VARCHAR2,
   p_atmname_loc         IN       VARCHAR2,
   p_rvsl_code           IN       NUMBER,
                            --Added by Deepa on June 26 2012 for Reversal Fees
   p_mcc_code            IN       VARCHAR2,
                    -- Added by Trivikram on 05/Sep/2012 For Merchat Catg Code
   p_error               OUT      VARCHAR2,
   p_fee_amount          OUT      VARCHAR2,
                                 --Fee Amount debited from account with waiver
   p_actual_feeamnt      OUT      VARCHAR2, --Actual Fee Amount without waiver
   p_fee_code            OUT      VARCHAR2,                          --FeeCode
   p_fee_plan            OUT      VARCHAR2,                         -- FeePlan
   p_fee_attachtype      OUT      VARCHAR2,
                                  --FeePlan Attachtype(Product/Prod Catg/Card)
   p_cr_acct_no          OUT      VARCHAR2,     --Credit Account Number of Fee
   p_dr_acct_no          OUT      VARCHAR2,      --Debit Account Number of Fee
   p_waiv_percnt         OUT      VARCHAR2,    --Waiver Percentage for the Fee
   p_waiv_amnt           OUT      VARCHAR2,         --Waiver Amount for the Fee
   p_authid              OUT      VARCHAR2         --ADDED FOR FSS-744
) 
AS
   v_trandate           DATE;
   v_tran_type          cms_transaction_mast.ctm_tran_type%TYPE;
   exp_reject_record    EXCEPTION;
   v_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   v_declinerespcount   NUMBER;
   v_fee_code           cms_fee_mast.cfm_fee_code%TYPE;
   v_fee_crgl_catg      cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_fee_crgl_code      cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_fee_crsubgl_code   cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_fee_cracct_no      cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_drgl_catg      cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_fee_drgl_code      cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_fee_drsubgl_code   cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_fee_dracct_no      cms_prodcattype_fees.cpf_dracct_no%TYPE;
   v_st_calc_flag       cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_cess_calc_flag     cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_st_cracct_no       cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_st_dracct_no       cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_cess_cracct_no     cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_cess_dracct_no     cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   v_fee_amt            NUMBER;
   v_feeamnt_type       cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_per_fees           cms_fee_mast.cfm_per_fees%TYPE;
   v_flat_fees          cms_fee_mast.cfm_fee_amt%TYPE;
   v_clawback           cms_fee_mast.cfm_clawback_flag%TYPE;
   v_fee_plan           cms_fee_feeplan.cff_fee_plan%TYPE;
   v_acct_balance       cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   v_card_acct_no       cms_acct_mast.cam_acct_no%TYPE;
   v_trans_desc         cms_transaction_mast.ctm_tran_desc%TYPE;
   v_narration          VARCHAR2 (300);
   v_auth_id            transactionlog.auth_id%TYPE;
   v_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
   v_freetxn_exceed     VARCHAR2 (1);
   -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
   v_duration           VARCHAR2 (20);
   -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
   v_prod_code          cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype       cms_prod_cattype.cpc_card_type%TYPE;
   v_waiv_percnt        cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_err_waiv           VARCHAR2 (300);
   v_log_waiver_amt     NUMBER;
   v_log_actual_fee     NUMBER;
   v_feeattach_type     VARCHAR2 (2);  -- Added by Trivikram on 5th Sept 2012
   v_cam_type_code      cms_acct_mast.cam_type_code%TYPE;  
   --Sn Added for MVHOST-346 changes
   v_clawback_amnt      cms_fee_mast.cfm_fee_amt%TYPE;
   v_actual_fee_amnt    NUMBER;
   v_clawback_count     NUMBER;
   v_fee_debit          VARCHAR2 (1)                              DEFAULT 'N';
   v_clawback_txn       cms_transaction_mast.ctm_login_txn%TYPE;
--En Added for MVHOST-346 changes
   v_timestamp       timestamp;                        -- Added on 20-Apr-2013 for defect 10871
   --v_prod_code cms_appl_pan.cap_prod_code%type;      -- Added on 20-Apr-2013 for defect 10871 
   v_card_type cms_appl_pan.cap_card_stat%type;        -- Added on 20-Apr-2013 for defect 10871 
   v_card_stat cms_appl_pan.cap_card_type%type;        -- Added on 20-Apr-2013 for defect 10871 
   v_cam_ledger_bal cms_acct_mast.cam_ledger_bal%TYPE; -- Added on 20-Apr-2013 for defect 10871
   V_FEE_DESC CMS_FEE_MAST.CFM_FEE_DESC%TYPE; -- Added on 05-FEB-2014 for defect MVCSD-4471
   v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
   v_chrg_dtl_cnt    NUMBER;     -- Added for FWR 64
/**************************************************************************************************
    * Created By       : Deepa
    * Created Date     : 20-June-2012
    * Purpose          : Fee changes
    * Modified By      : Deepa T
    * Modified Date    : 11-Oct-2012
    * Modified Reason  : To log the Decline Fee details in transactionlog
    * Reviewer         : Saravanakumar.
    * Reviewed Date    : 15-Oct-2012
    * Build Number     : CMS3.5.1_RI0020_B0001
    * Modified By      : Sachin P.
    * Modified For     : Defect 10502
    * Modified Date    : 26-Feb-2013
    * Modified Reason  : Fees to debit account only if the balance is available
    * Reviewer         :
    * Reviewed Date    :
    * Build Number     : CMS3.5.1_RI0023.2_B0011

    * Modified By      : Sagar M.
    * Modified Date    : 04-Apr-2013
    * Modified Reason  : To update after transaction account and ledger balance in Transactionlog
    * Modified For     : DEFECT-0010782
    * Reviewer         : Dhiraj
    * Reviewed Date    : 10-Apr-2013
    * Build Number     : RI0024.1_B0003
    
    * Modified By      : Deepa T
    * Modified Date    : 22-Apr-2013
    * Modified for     : Defect -MVHOST-346
    * Modified Reason  :
    
    * Modified By      : Sagar M.
    * Modified Date    : 20-Apr-2013
    * Modified for     : Defect 10871
    * Modified Reason  : Logging of below details handled in tranasctionlog and statementlog table
                          1) ledger balance in statementlog
                          2) Product code,Product category code,Card status,Acct Type,drcr flag
                          3) Timestamp and Amount values logging correction 
    * Reviewer         : Dhiraj
    * Reviewed Date    : 20-Apr-2013
    * Build Number     : RI0024.1_B0012
    
    * Modified By      : DHINAKARAN B
    * Modified Date    : 10-Jun-2013
    * Modified for     : FSS-744
    * Modified Reason  : Logging Auth_id in transactionlog table
    * Reviewer         : 
    * Reviewed Date    : 
    * Build Number     : RI0024.2_B0001
    
    * Modified By      : RAVI N
    * Modified Date    : 29-JAN-2014
    * Modified Reason  : 0013542 [Negative Feee] & Fee description logging instead narration For MVCSD-4471
    * Reviewer         : Dhiraj
    * Reviewed Date    : 
    * Build Number     : RI0027.1_B0001
    
     * Modified By      : Revathi D
     * Modified Date    : 02-APR-2014
     * Modified for     : 
     * Modified Reason  : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
                          CMS_ACCT_MAST,CMS_STATEMENTS_LOG,TRANSACTIONLOG.
                          
     * Reviewer         : 
     * Reviewed Date    : 
     * Build Number     : 
     
      * Modified By      : Abdul Hameed m.A
     * Modified Date    : 02-APR-2014
     * Modified for     : Mantis Id 14050
     * Modified Reason  : Round functions added upto 2nd decimal for fee  amount           
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
    * modified Date     : 28-Nov-14
    * modified for      : Defect ID: 15919
    * modified reason   : Commented GL code for required
    * Reviewer          : Spankaj
    * Build Number      : Ri0027.4.2.2_B0007
    
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
    *************************************************************************************************/
BEGIN
   p_error := 'OK';
   v_auth_id := p_auth_id;

   SELECT COUNT (*)
     INTO v_declinerespcount
     FROM cms_declinetxn_response
    WHERE cdr_inst_code = p_inst_code
      AND cdr_delivery_channel = p_del_channel
      AND cdr_tran_code = p_tran_code
      AND cdr_msg_type = p_msg_type
      AND cdr_respcde = p_response_code
      AND cdr_reversal_code = p_rvsl_code;

   IF v_declinerespcount > 0
   THEN
      --SN CREATE HASH PAN
      BEGIN
         v_hash_pan := gethash (p_card_number);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_error :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN CREATE HASH PAN
      BEGIN
         v_encr_pan := fn_emaps_main (p_card_number);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_error :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1'))
           INTO v_tran_type
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_tran_code
            AND ctm_delivery_channel = p_del_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_error :=
                  'Transflag  not defined for txn code '
               || p_tran_code
               || ' and delivery channel '
               || p_del_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_error := 'Error while selecting transaction details';
            RAISE exp_reject_record;
      END;

      BEGIN
         v_trandate :=
            TO_DATE (   SUBSTR (TRIM (p_tran_date), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_tran_time), 1, 10),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_error :=
                  'Problem while converting transaction time '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         sp_tran_fees_cmsauth
            (p_inst_code,
             p_card_number,
             p_del_channel,
             v_tran_type,
             p_tran_mode,
             p_tran_code,
             p_currency_code,
             p_consodium_code,
             p_partner_code,
             p_trn_amt,
             v_trandate,
             p_international_ind,
             p_pos_verification,
             p_response_code,
             p_msg_type,
             p_rvsl_code,   --Added by Deepa on June 26 2012 for Reversal Fees
             p_mcc_code,       --P_MCC_CoDe Added by Trivinkram on 05-sep-2012
             v_fee_amt,
             p_error,
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
                     -- Added by Trivikram for logging fee of free transaction
             v_duration,
                     -- Added by Trivikram for logging fee of free transaction
             v_feeattach_type,             -- Added by Trivikram on Sep 05 2012
             V_FEE_DESC -- Added  on FEB 05 2014
            );

         IF p_error <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_error :=
                  'Error from decline fee calc process '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         sp_calculate_waiver
            (p_inst_code,
             p_card_number,
             '000',
             v_prod_code,
             v_prod_cattype,
             v_fee_code,
             v_fee_plan,                  -- Added by Trivikram on 21/aug/2012
             v_trandate,
         --Added Trivikram on Aug-23-2012 to calculate the waiver based on tran date
             v_waiv_percnt,
             v_err_waiv
            );

         IF v_err_waiv <> 'OK'
         THEN
            p_error := v_err_waiv;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_error :=
                'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En calculate waiver on the fee

      --Sn apply waiver on fee amount
      dbms_output.put_line('fee amt is'||v_fee_amt);
      v_log_actual_fee := v_fee_amt;           --only used to log in log table
      v_fee_amt := ROUND (v_fee_amt - ((v_fee_amt * v_waiv_percnt) / 100), 2);
      v_log_waiver_amt := v_log_actual_fee - v_fee_amt;

      --only used to log in log table

      --En apply waiver on fee amount
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no,
                    cam_type_code                            --Added for defect 10871                   
               INTO v_acct_balance, v_ledger_bal, v_card_acct_no,
                    v_cam_type_code                              --Added for defect 10871                   
               FROM cms_acct_mast
              WHERE cam_acct_no =
                       (SELECT cap_acct_no
                          FROM cms_appl_pan
                         WHERE cap_pan_code = v_hash_pan
                           AND cap_mbr_numb = p_mbr_numb
                           AND cap_inst_code = p_inst_code)
                AND cam_inst_code = p_inst_code
         FOR UPDATE NOWAIT;
         
         v_cam_ledger_bal := v_ledger_bal;  --Added for defect 10871 to log proper ledger balance in Transactionlog table
         
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_error := 'Invalid Card ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_error :=
                  'Error while selecting data from card Master for card number '
               || SQLERRM;
            RAISE exp_reject_record;
      END;
        dbms_output.put_line('fee amt is'||v_fee_amt);
      BEGIN
         IF v_fee_amt <> 0
         THEN
           /* Commented for not required defect id : 15919
            IF TRIM (v_fee_cracct_no) IS NULL
               AND TRIM (v_fee_dracct_no) IS NULL
            THEN
               p_error :=
                     'Both credit and debit account cannot be null for a fee '
                  || v_fee_code;
               RAISE exp_reject_record;
            END IF;

            IF TRIM (v_fee_cracct_no) IS NULL
            THEN
               v_fee_cracct_no := v_card_acct_no;
            END IF;
          */
            IF TRIM (v_fee_dracct_no) IS NULL
            THEN
               v_fee_dracct_no := v_card_acct_no;
            END IF;
 
          /* Commented for not required defect id : 15919
            IF TRIM (v_fee_cracct_no) = TRIM (v_fee_dracct_no)
            THEN
               p_error := 'Both debit and credit fee account cannot be same';
               RAISE exp_reject_record;
            END IF;
          */
            BEGIN
               SELECT ctm_tran_desc, ctm_login_txn
                 INTO v_trans_desc, v_clawback_txn
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = p_tran_code
                  AND ctm_delivery_channel = p_del_channel
                  AND ctm_inst_code = p_inst_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_trans_desc := 'Transaction type ' || p_tran_code;
               WHEN OTHERS
               THEN
                  p_error :=
                        'Error in finding the narration '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            IF v_fee_dracct_no = v_card_acct_no
            THEN
               --SN DEBIT THE  CONCERN FEE  ACCOUNT
               --Sn modified for the MVHOST -346 to enable claw back for the decline fees
               IF NVL (v_acct_balance, 0) >= NVL (v_fee_amt, 0)
               THEN
                  v_fee_debit := 'Y';
               ELSIF v_clawback = 'Y' AND v_clawback_txn = 'Y'
               THEN
                  v_fee_debit := 'Y';
                  v_actual_fee_amnt := v_fee_amt;
                   --Added on 29/01/14 for regarding 0013542 
                IF (v_acct_balance >0) THEN
                  v_clawback_amnt   := v_fee_amt - v_acct_balance;
                  v_fee_amt         := v_acct_balance;
                ELSE
                  v_clawback_amnt   := v_fee_amt;
                  v_fee_amt         := 0;
                End IF;
                
                
--                  v_clawback_amnt := v_fee_amt - v_acct_balance;
--                  v_fee_amt := v_acct_balance;
              --End

                  IF v_clawback_amnt > 0
                  THEN
                 -- Added for FWR 64 --     
                  begin
                    select cfm_clawback_count into v_tot_clwbck_count from cms_fee_mast where cfm_fee_code=V_FEE_CODE; 
                      
                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                   p_error := 'Clawback count not configured '|| SUBSTR(SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                  END;
                   
                BEGIN
                                SELECT COUNT (*)
                                  INTO v_chrg_dtl_cnt
                                  FROM cms_charge_dtl
                                 WHERE      ccd_inst_code = p_inst_code
                                         AND ccd_delivery_channel = p_del_channel
                                         AND ccd_txn_code = p_tran_code
                                         --AND ccd_pan_code = v_hash_pan --Commented for FSS-4755
                                         AND ccd_acct_no = v_card_acct_no and CCD_FEE_CODE=V_FEE_CODE 
                     and ccd_clawback ='Y';
                            EXCEPTION
                                WHEN OTHERS 
                                THEN
                p_error :=
                                        'Error occured while fetching count from cms_charge_dtl'
                                        || SUBSTR (SQLERRM, 1, 100);
                                    RAISE EXP_REJECT_RECORD;
                            END;
            -- Added for fwr 64 
                
                     BEGIN
                        SELECT COUNT (*)
                          INTO v_clawback_count
                          FROM cms_acctclawback_dtl
                         WHERE cad_inst_code = p_inst_code
                           AND cad_delivery_channel = p_del_channel
                           AND cad_txn_code = p_tran_code
                           AND cad_pan_code = v_hash_pan
                           AND cad_acct_no = v_card_acct_no;

                        IF v_clawback_count = 0
                        THEN
                           INSERT INTO cms_acctclawback_dtl
                                       (cad_inst_code, cad_acct_no,
                                        cad_pan_code, cad_pan_code_encr,
                                        cad_clawback_amnt,
                                        cad_recovery_flag, cad_ins_date,
                                        cad_lupd_date, cad_delivery_channel,
                                        cad_txn_code, cad_ins_user,
                                        cad_lupd_user
                                       )
                                VALUES (p_inst_code, v_card_acct_no,
                                        v_hash_pan, v_encr_pan,
                                       ROUND(v_clawback_amnt,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        'N', SYSDATE,
                                        SYSDATE, p_del_channel,
                                        p_tran_code, '1',
                                        '1'
                                       );
                       ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count then  -- Modified for fwr 64 
                           UPDATE cms_acctclawback_dtl
                              SET cad_clawback_amnt =
                                           ROUND(cad_clawback_amnt + v_clawback_amnt,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                  cad_recovery_flag = 'N',
                                  cad_lupd_date = SYSDATE
                            WHERE cad_inst_code = p_inst_code
                              AND cad_acct_no = v_card_acct_no
                              AND cad_pan_code = v_hash_pan
                              AND cad_delivery_channel = p_del_channel
                              AND cad_txn_code = p_tran_code;
                        END IF;

                       
                     EXCEPTION
                     when exp_reject_record THEN
                     RAISE;
                        WHEN OTHERS
                        THEN
                           p_error :=
                                 'Error while inserting Account ClawBack details'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;
                  END IF;
               END IF;

               -- IF NVL(V_ACCT_BALANCE,0) >= NVL(V_FEE_AMT,0) THEN
               IF v_fee_debit = 'Y'
               THEN
                  ---Condition Added on 26.02.2013 for fees to debit account only if the balance is available
                  BEGIN
                     UPDATE cms_acct_mast
                        SET cam_acct_bal = ROUND(cam_acct_bal - v_fee_amt,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            cam_ledger_bal = ROUND(cam_ledger_bal - v_fee_amt,2)--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                      WHERE cam_inst_code = p_inst_code
                        AND cam_acct_no = v_fee_dracct_no;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        p_error := 'Problem while updating the FEE ';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_error :=
                              'Error while updating CMS_ACCT_MAST1 '
                           || SUBSTR (SQLERRM, 1, 200);
                        RETURN;
                  END;

                  --END IF;
                  IF v_auth_id IS NULL
                  THEN
                     --Sn generate auth id
                     BEGIN
                        --                 SELECT TO_CHAR(SYSDATE, 'YYYYMMDD')|| LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
                        SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
                          INTO v_auth_id
                          FROM DUAL;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_error :=
                                 'Error while generating authid '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;
                  --En generate auth id
                  END IF;

                  --Sn find narration
                  /*BEGIN
                    SELECT CTM_TRAN_DESC
                      INTO V_TRANS_DESC
                      FROM CMS_TRANSACTION_MAST
                     WHERE CTM_TRAN_CODE = P_TRAN_CODE AND
                          CTM_DELIVERY_CHANNEL = P_DEL_CHANNEL AND
                          CTM_INST_CODE = P_INST_CODE;*/
               --Start-comment
             --Start Comment on o2/FEB/14 for regarding MVCSD-4471
              /*
                IF TRIM (v_trans_desc) IS NOT NULL
                  THEN
                     v_narration := v_trans_desc || '/';
                  END IF;

                  IF TRIM (p_merchant_name) IS NOT NULL
                  THEN
                     v_narration := v_narration || p_merchant_name, || '/';
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
             --End Comment on o2/FEB/14 for regarding MVCSD-4471     

                  /*EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      V_TRANS_DESC := 'Transaction type ' || P_TRAN_CODE;
                    WHEN OTHERS THEN

                      P_ERROR := 'Error in finding the narration ' ||
                              SUBSTR(SQLERRM, 1, 200);
                      RAISE EXP_REJECT_RECORD;

                  END;*/
                  
                  Begin         --Added for defect 10871
                  
                        select cap_prod_code,cap_card_stat,cap_card_type
                        into   v_prod_code,v_card_type,v_card_stat
                        from   cms_appl_pan
                        where  cap_inst_code = p_inst_code
                        and    cap_pan_code = v_hash_pan;
                        
                  exception when no_data_found
                  then
                      p_error := 'Product details not found in pan_mast for card '||fn_mask(p_card_number,'X',7,6);
                      RAISE exp_reject_record;
                      
                  when others
                  then
                      p_error := 'Error occured while fetching Product details '||substr(sqlerrm,1,100);
                      RAISE exp_reject_record;
                  
                  End;    --Added for defect 10871                   
                
                 v_timestamp := systimestamp; --Added for defect 10871  
               
                  -- Added by Trivikram on 27-July-2012 for logging complementary transaction
                  IF v_freetxn_exceed = 'N'
                  THEN
                     --  IF NVL(V_ACCT_BALANCE,0) >= NVL(V_FEE_AMT,0) 
                      -- THEN --Condition Added on 26.02.2013 for fees to debit account only if the balance is available
                    --Commented for MVHOSt-346

                       BEGIN
                            INSERT INTO CMS_STATEMENTS_LOG
                       (CSL_PAN_NO,
                        CSL_OPENING_BAL,
                        CSL_TRANS_AMOUNT,
                        CSL_TRANS_TYPE,
                        CSL_TRANS_DATE,
                        CSL_CLOSING_BALANCE,
                        CSL_TRANS_NARRRATION,
                        CSL_INST_CODE,
                        CSL_PAN_NO_ENCR,
                        CSL_RRN,
                        CSL_AUTH_ID,
                        CSL_BUSINESS_DATE,
                        CSL_BUSINESS_TIME,
                        TXN_FEE_FLAG,
                        CSL_DELIVERY_CHANNEL,
                        CSL_TXN_CODE,
                        CSL_ACCT_NO,
                        CSL_INS_USER,
                        CSL_INS_DATE,
                        CSL_MERCHANT_NAME,
                        CSL_MERCHANT_CITY,
                        CSL_MERCHANT_STATE,
                        CSL_PANNO_LAST4DIGIT,
                        CSL_PROD_CODE,csl_card_type ,         --Addded for defect 10871
                        CSL_ACCT_TYPE,          --Addded for defect 10871
                        CSL_TIME_STAMP          --Addded for defect 10871
                        )
                        VALUES
                       (V_HASH_PAN,
                        ROUND(V_LEDGER_BAL,2),      --V_ACCT_BALANCE Is replaced by V_LEDGER_BAL for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                        ROUND(V_FEE_AMT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                        'DR',
                        V_TRANDATE,
                        ROUND(V_LEDGER_BAL - V_FEE_AMT, 2),    --V_ACCT_BALANCE Is replaced by V_LEDGER_BAL for defect 10871  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                        --'Complimentary ' || V_DURATION ||' '|| V_NARRATION, -- Modified by Trivikram  on 27-July-2012
                        V_FEE_DESC,--Added on 05/02/14 for regarding MVCSD-4471
                        P_INST_CODE,
                        V_ENCR_PAN,
                        P_RRN,
                        V_AUTH_ID,
                        P_TRAN_DATE,
                        P_TRAN_TIME,
                        'Y',
                        P_DEL_CHANNEL,
                        P_TRAN_CODE,
                        V_CARD_ACCT_NO,
                        1,
                        SYSDATE,
                        P_MERCHANT_NAME,
                        P_MERCHANT_CITY,
                        P_ATMNAME_LOC,
                        (SUBSTR(P_CARD_NUMBER,
                              LENGTH(P_CARD_NUMBER) - 3,
                              LENGTH(P_CARD_NUMBER))),
                        v_prod_code,v_prod_cattype ,               --Addded for defect 10871
                        v_cam_type_code, --v_card_type,                --Addded for defect 10871 Modified for FSS-1586
                        v_timestamp                 --Addded for defect 10871
                        );
                       EXCEPTION
                            WHEN OTHERS
                            THEN
                               p_error :=
                                     'Problem while inserting into statement log for tran fee '
                                  || SUBSTR (SQLERRM, 1, 200);
                               RAISE exp_reject_record;
                       END;
                      -- END IF;
                  ELSE
                  
                     BEGIN
                        IF v_feeamnt_type = 'A'
                        THEN
                           v_flat_fees :=
                              ROUND (  v_flat_fees
                                     - ((v_flat_fees * v_waiv_percnt) / 100),
                                     2
                                    );
                           v_per_fees :=
                              ROUND (  v_per_fees
                                     - ((v_per_fees * v_waiv_percnt) / 100),
                                     2
                                    );

                           -- IF NVL(V_ACCT_BALANCE,0) >= NVL(V_FEE_AMT,0) THEN --Condition Added on 26.02.2013 for fees to debit account only if the balance is available  
                             --Sn Entry for Fixed Fee
                           INSERT INTO CMS_STATEMENTS_LOG
                             (CSL_PAN_NO,
                              CSL_OPENING_BAL,
                              CSL_TRANS_AMOUNT,
                              CSL_TRANS_TYPE,
                              CSL_TRANS_DATE,
                              CSL_CLOSING_BALANCE,
                              CSL_TRANS_NARRRATION,
                              CSL_INST_CODE,
                              CSL_PAN_NO_ENCR,
                              CSL_RRN,
                              CSL_AUTH_ID,
                              CSL_BUSINESS_DATE,
                              CSL_BUSINESS_TIME,
                              TXN_FEE_FLAG,
                              CSL_DELIVERY_CHANNEL,
                              CSL_TXN_CODE,
                              CSL_ACCT_NO,
                              CSL_INS_USER,
                              CSL_INS_DATE,
                              CSL_MERCHANT_NAME,
                              CSL_MERCHANT_CITY,
                              CSL_MERCHANT_STATE,
                              CSL_PANNO_LAST4DIGIT,
                              CSL_PROD_CODE, csl_card_type,         --Addded for defect 10871
                              CSL_ACCT_TYPE,          --Addded for defect 10871
                              CSL_TIME_STAMP          --Addded for defect 10871
                              )
                            VALUES
                             (V_HASH_PAN,
                              ROUND(V_LEDGER_BAL,2),     --V_ACCT_BALANCE Is replaced by V_LEDGER_BAL for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                              ROUND(V_FLAT_FEES,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                              'DR',
                              V_TRANDATE,
                              ROUND(V_LEDGER_BAL - V_FLAT_FEES,2),   --V_ACCT_BALANCE Is replaced by V_LEDGER_BAL for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                              'Fixed Fee debited for ' || V_NARRATION,
                              P_INST_CODE,
                              V_ENCR_PAN,
                              P_RRN,
                              V_AUTH_ID,
                              P_TRAN_DATE,
                              P_TRAN_TIME,
                              'Y',
                              P_DEL_CHANNEL,
                              P_TRAN_CODE,
                              V_CARD_ACCT_NO,
                              1,
                              SYSDATE,
                              P_MERCHANT_NAME,
                              P_MERCHANT_CITY,
                              P_ATMNAME_LOC,
                              (SUBSTR(P_CARD_NUMBER,
                                    LENGTH(P_CARD_NUMBER) - 3,
                                    LENGTH(P_CARD_NUMBER))),
                              v_prod_code, v_prod_cattype ,              --Addded for defect 10871
                             v_cam_type_code,-- v_card_type,                --Addded for defect 10871 Modified for FSS-1586
                              v_timestamp                 --Addded for defect 10871                                    
                              );
                            --En Entry for Fixed Fee
                            V_LEDGER_BAL := V_LEDGER_BAL - V_FLAT_FEES;
                            --Sn Entry for Percentage Fee

                            INSERT INTO CMS_STATEMENTS_LOG
                             (CSL_PAN_NO,
                              CSL_OPENING_BAL,
                              CSL_TRANS_AMOUNT,
                              CSL_TRANS_TYPE,
                              CSL_TRANS_DATE,
                              CSL_CLOSING_BALANCE,
                              CSL_TRANS_NARRRATION,
                              CSL_INST_CODE,
                              CSL_PAN_NO_ENCR,
                              CSL_RRN,
                              CSL_AUTH_ID,
                              CSL_BUSINESS_DATE,
                              CSL_BUSINESS_TIME,
                              TXN_FEE_FLAG,
                              CSL_DELIVERY_CHANNEL,
                              CSL_TXN_CODE,
                              CSL_ACCT_NO,
                              CSL_INS_USER,
                              CSL_INS_DATE,
                              CSL_MERCHANT_NAME,
                              CSL_MERCHANT_CITY,
                              CSL_MERCHANT_STATE,
                              CSL_PANNO_LAST4DIGIT,
                              CSL_PROD_CODE,          --Addded for defect 10871
                              CSL_ACCT_TYPE,          --Addded for defect 10871
                              CSL_TIME_STAMP          --Addded for defect 10871
                              )
                            VALUES
                             (V_HASH_PAN,
                              ROUND(V_LEDGER_BAL,2),     --V_ACCT_BALANCE Is replaced by V_LEDGER_BAL for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                              ROUND(V_PER_FEES,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                              'DR',
                              V_TRANDATE,
                              ROUND(V_LEDGER_BAL - V_PER_FEES,2),   --V_ACCT_BALANCE Is replaced by V_LEDGER_BAL for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            --  'Percetage Fee debited for ' || V_NARRATION,--Commented on 05/02/14 for regarding MVCSD-4471
                               'Percetage Fee debited for ' || V_FEE_DESC,--Added on 05/02/14 for regarding MVCSD-4471
                              P_INST_CODE,
                              V_ENCR_PAN,
                              P_RRN,
                              V_AUTH_ID,
                              P_TRAN_DATE,
                              P_TRAN_TIME,
                              'Y',
                              P_DEL_CHANNEL,
                              P_TRAN_CODE,
                              V_CARD_ACCT_NO,
                              1,
                              SYSDATE,
                              P_MERCHANT_NAME,
                              P_MERCHANT_CITY,
                              P_ATMNAME_LOC,
                              (SUBSTR(P_CARD_NUMBER,
                                    LENGTH(P_CARD_NUMBER) - 3,
                                    LENGTH(P_CARD_NUMBER))),
                              v_prod_code,                --Addded for defect 10871
                              v_cam_type_code, --v_card_type,                --Addded for defect 10871 Modified for FSS-1586
                              v_timestamp                 --Addded for defect 10871                                         
                              );

                            --En Entry for Percentage Fee
                                      --En Entry for Percentage Fee
                                    -- END IF;
                                    ELSE
                                        --Sn create entries for FEES attached
                                       -- IF NVL(V_ACCT_BALANCE,0) >= NVL(V_FEE_AMT,0) THEN --Condition Added on 26.02.2013 for fees to debit account only if the balance is available  
                            INSERT INTO CMS_STATEMENTS_LOG
                               (CSL_PAN_NO,
                                CSL_OPENING_BAL,
                                CSL_TRANS_AMOUNT,
                                CSL_TRANS_TYPE,
                                CSL_TRANS_DATE,
                                CSL_CLOSING_BALANCE,
                                CSL_TRANS_NARRRATION,
                                CSL_INST_CODE,
                                CSL_PAN_NO_ENCR,
                                CSL_RRN,
                                CSL_AUTH_ID,
                                CSL_BUSINESS_DATE,
                                CSL_BUSINESS_TIME,
                                TXN_FEE_FLAG,
                                CSL_DELIVERY_CHANNEL,
                                CSL_TXN_CODE,
                                CSL_ACCT_NO,
                                CSL_INS_USER,
                                CSL_INS_DATE,
                                CSL_MERCHANT_NAME,
                                CSL_MERCHANT_CITY,
                                CSL_MERCHANT_STATE,
                                CSL_PANNO_LAST4DIGIT,
                                CSL_PROD_CODE,          --Addded for defect 10871
                                CSL_ACCT_TYPE,          --Addded for defect 10871
                                CSL_TIME_STAMP          --Addded for defect 10871
                                )
                             VALUES
                               (V_HASH_PAN,
                                ROUND(V_LEDGER_BAL,2),         --V_ACCT_BALANCE Is replaced by V_LEDGER_BAL for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                ROUND(V_FEE_AMT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                'DR',
                                V_TRANDATE,
                                ROUND(V_LEDGER_BAL - V_FEE_AMT,2),     --V_ACCT_BALANCE Is replaced by V_LEDGER_BAL for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                --'Fee debited for ' || V_NARRATION,--Added on 05/02/14 for regarding MVCSD-4471
                                V_FEE_DESC,--Added on 05/02/14 for regarding MVCSD-4471
                                P_INST_CODE,
                                V_ENCR_PAN,
                                P_RRN,
                                V_AUTH_ID,
                                P_TRAN_DATE,
                                P_TRAN_TIME,
                                'Y',
                                P_DEL_CHANNEL,
                                P_TRAN_CODE,
                                V_CARD_ACCT_NO,
                                1,
                                SYSDATE,
                                P_MERCHANT_NAME,
                                P_MERCHANT_CITY,
                                P_ATMNAME_LOC,
                                (SUBSTR(P_CARD_NUMBER,
                                      LENGTH(P_CARD_NUMBER) - 3,
                                      LENGTH(P_CARD_NUMBER))),
                                v_prod_code,                --Addded for defect 10871
                                v_cam_type_code,--v_card_type,                --Addded for defect 10871 Modified for FSS-1586
                                v_timestamp                 --Addded for defect 10871                                        
                               );
                          
                       IF v_clawback_txn = 'Y' AND V_CLAWBACK_AMNT > 0 and v_chrg_dtl_cnt < v_tot_clwbck_count THEN  -- Modified for fwr 64 
                      BEGIN
                           INSERT INTO cms_charge_dtl
                                       (ccd_pan_code, ccd_acct_no,
                                        ccd_clawback_amnt, ccd_gl_acct_no,
                                        ccd_pan_code_encr, ccd_rrn,
                                        ccd_calc_date, ccd_fee_freq,
                                        ccd_file_status, ccd_clawback,
                                        ccd_inst_code, ccd_fee_code,
                                        ccd_calc_amt, ccd_fee_plan,
                                        ccd_delivery_channel, ccd_txn_code,
                                        ccd_debited_amnt, ccd_mbr_numb,
                                        ccd_process_msg,
                                        ccd_feeattachtype
                         --Added by Deepa on Oct-22-2012 to log the FeeAttach type for Clawback
                                       )
                                VALUES (v_hash_pan, v_card_acct_no,
                                        ROUND(v_clawback_amnt,2), v_fee_cracct_no,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        v_encr_pan, p_rrn,
                                        v_trandate, 'T',
                                        'C', v_clawback,
                                        p_inst_code, v_fee_code,
                                        ROUND(v_actual_fee_amnt,2), v_fee_plan,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        p_del_channel, p_tran_code,
                                        ROUND(v_fee_amt,2), p_mbr_numb,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        'SUCCESS',
                                        v_feeattach_type
                                       );
                          --Added by Deepa on Oct-22-2012 to log the FeeAttach type for Clawback
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              p_error :=
                                    'Problem while inserting into CMS_CHARGE_DTL '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_record;
                        END;
                        END IF;
                        -- END IF;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_error :=
                                 'Problem while inserting into statement log for tran fee '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;
                  END IF;

                  --Sn insert a record into EODUPDATE_ACCT

                  -- IF NVL(V_ACCT_BALANCE,0) >= NVL(V_FEE_AMT,0) THEN --Condition Added on 26.02.2013 for fees to debit account only if the balance is available
                  BEGIN
                     sp_ins_eodupdate_acct_cmsauth (p_rrn,
                                                    p_terminal_id,
                                                    p_del_channel,
                                                    p_tran_code,
                                                    p_tran_mode,
                                                    v_trandate,
                                                    v_card_acct_no,
                                                    v_fee_cracct_no,
                                                    v_fee_amt,
                                                    'C',
                                                    p_inst_code,
                                                    p_error
                                                   );

                     IF p_error <> 'OK'
                     THEN
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_error :=
                              'Error while calling SP_INS_EODUPDATE_ACCT_CMSAUTH3 '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;

                    --En insert a record into EODUPDATE_ACCT
                  -- END IF;

                  --Added by Deepa on Oct-09-2012 to log the decline transction Fee Details
                  /*This procedure called only for the ELAN decline transaction.If the txn declined from Procedure
                  insert will be there in transactionlog decline fee details should be updated.If declined from Java,
                  decline fee details will be logged using the OUT parameter
                  */
                   -- IF NVL(V_ACCT_BALANCE,0) >= NVL(V_FEE_AMT,0) THEN --Condition Added on 26.02.2013 for fees to debit account only if the balance is available
                  BEGIN
                  
                     UPDATE TRANSACTIONLOG
                      SET FEEATTACHTYPE=V_FEEATTACH_TYPE,
                          FEE_PLAN=V_FEE_PLAN,
                          FEECODE=V_FEE_CODE,
                          TRANFEE_AMT=V_FEE_AMT,
                          TRANFEE_CR_ACCTNO=V_FEE_CRACCT_NO,
                          TRANFEE_DR_ACCTNO=V_FEE_DRACCT_NO,
                          TOTAL_AMOUNT=ROUND(V_FEE_AMT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                          ACCT_BALANCE = ROUND(V_ACCT_BALANCE - V_FEE_AMT,2), -- Added on 04-Apr-2013 for defect 0010782 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                          --LEDGER_BALANCE = V_LEDGER_BAL - V_FEE_AMT, -- Added on 04-Apr-2013 for defect 0010782 -- Commented for defect 10871 ,sicne V_LEDGER_BAL variable getting incorrect value 
                          LEDGER_BALANCE = ROUND(v_cam_ledger_bal - V_FEE_AMT,2), -- Added on 04-Apr-2013 for defect 0010782 -- Added for defect 10871 , since V_LEDGER_BAL variable getting incorrect value --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                          TIME_STAMP = v_timestamp,                   --Added for defect 10871
                          AUTH_ID    =V_AUTH_ID                       --ADDED FOR FSS-744
                    WHERE RRN = P_RRN
                    AND BUSINESS_DATE = P_TRAN_DATE AND
                    TXN_CODE = P_TRAN_CODE
                    AND BUSINESS_TIME = P_TRAN_TIME
                    AND DELIVERY_CHANNEL = P_DEL_CHANNEL
                    AND RESPONSE_CODE=P_RESPONSE_CODE
                    AND MSGTYPE=P_MSG_TYPE;

                     IF SQL%ROWCOUNT <> 0
                     THEN
                        UPDATE cms_transaction_log_dtl
                           SET ctd_fee_amount = v_log_actual_fee,
                               ctd_waiver_amount = v_log_waiver_amt
                         WHERE ctd_delivery_channel = p_del_channel
                           AND ctd_txn_code = p_tran_code
                           AND ctd_business_date = p_tran_date
                           AND ctd_business_time = p_tran_time
                           AND ctd_msg_type = p_msg_type
                           AND ctd_rrn = p_rrn;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_error :=
                              'Error while logging Decline Fee Details '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;

                  p_fee_amount := ROUND(v_fee_amt,2);-- Modified on 02/04/2014 for Mantis Id 14050
                  p_fee_code := v_fee_code;
                  p_fee_plan := v_fee_plan;
                  p_fee_attachtype := v_feeattach_type;
                  p_cr_acct_no := v_fee_cracct_no;
                  p_dr_acct_no := v_fee_dracct_no;
                  p_actual_feeamnt := v_log_actual_fee;
                  p_waiv_percnt := v_waiv_percnt;
                  p_waiv_amnt := v_log_waiver_amt;
                  p_authid     :=V_AUTH_ID;  --ADDED FOR FSS-744
               ELSE
                  p_fee_amount := 0;
                  p_fee_code := NULL;
                  p_fee_plan := NULL;
                  p_fee_attachtype := NULL;
                  p_cr_acct_no := NULL;
                  p_dr_acct_no := NULL;
                  p_actual_feeamnt := 0;
                  p_waiv_percnt := NULL;
                  p_waiv_amnt := 0;
                  p_authid     :=V_AUTH_ID;  --ADDED FOR FSS-744
               END IF;
            --En Modified for MVHOST-346 to enable claw back for the decline fee
            END IF;
         END IF;
      END;
   ELSE
      p_error := 'NO FEES';
   END IF;
EXCEPTION
   WHEN exp_reject_record
   THEN
      RETURN;
   WHEN OTHERS
   THEN
-- Added by Deepa on Sep-27-2012 To handle the exception to avoid two entries in transactionlog table
      p_error := 'Exception in Main' || SUBSTR (SQLERRM, 1, 200);
      RETURN;
END;

/

show error