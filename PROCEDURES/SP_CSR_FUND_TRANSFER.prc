create or replace
PROCEDURE        vmscms.sp_csr_fund_transfer(

    prm_inst_code        IN NUMBER,
    prm_msg              IN VARCHAR2,
    prm_rrn              IN VARCHAR2,
    prm_delivery_channel IN VARCHAR2,
    prm_term_id          IN VARCHAR2,
    prm_txn_code         IN VARCHAR2,
    prm_txn_mode         IN VARCHAR2,
    prm_tran_date        IN VARCHAR2,
    prm_tran_time        IN VARCHAR2,
    PRM_CARD_NO          IN VARCHAR2,
    PRM_SPEN_ACCT        IN VARCHAR2,
    PRM_SVNG_ACCT        IN VARCHAR2,
    prm_bank_code        IN VARCHAR2,
    prm_txn_amt          IN NUMBER,
    prm_mcc_code         IN VARCHAR2,
    prm_curr_code        IN VARCHAR2,
    prm_stan             IN VARCHAR2,
    PRM_MBR_NUMB         IN VARCHAR2,
    prm_rvsl_code        IN VARCHAR2,--Modified by Dnyaneshwar J on 17 April 2014 For Mantis-14047
    prm_call_id          IN NUMBER,
    prm_ipaddress        IN VARCHAR2,
    prm_ins_user         IN NUMBER,
    PRM_REMARK           IN VARCHAR2,
    prm_auth_id OUT VARCHAR2,
    prm_resp_code OUT VARCHAR2,
    PRM_RESP_MSG OUT VARCHAR2,
    PRM_AVAIL_BAL OUT VARCHAR2,
    PRM_LEDGER_BAL OUT VARCHAR2,
    P_AVAILED_TXN OUT NUMBER,
    P_AVAILABLE_TXN OUT NUMBER,
    PRM_SAVING_AVAIL_BAL OUT VARCHAR2 )
IS
  /**********************************************************************************************
  * VERSION                  :  1.0
  * DATE OF CREATION         :  26/Feb/2014
  * PURPOSE                  :
  * CREATED BY               : Santosh Kokane
  * Build Number             : RI0027.2_B0001

  * Modified by              :  Dnyaneshwar J
  * Modified Reason          :  Mantis-14047
  * Modified Date            :  17-Apr-2014
  * Reviewer                 :  spankaj
  * Reviewed Date            :  18-april-2014
  * Build Number             :  RI0027.2_B0006

      * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
        * Modified by       : Siva Kumar M
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07
        
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
  **************************************************************************************************/
  v_call_seq NUMBER (3);
  v_hash_pan cms_appl_pan.cap_pan_code%TYPE;
  v_encr_pan cms_appl_pan.cap_pan_code_encr%TYPE;
  v_resp_code     VARCHAR2 (3);
  v_resp_msg      VARCHAR2 (300);
  excp_rej_record EXCEPTION;
  v_acct_balance cms_acct_mast.cam_acct_bal%TYPE;
  V_LEDGER_BALANCE CMS_ACCT_MAST.CAM_LEDGER_BAL%type;
  v_cap_acct_no cms_appl_pan.cap_acct_no%TYPE;
  v_prod_code cms_appl_pan.cap_prod_code%TYPE;
  v_prod_cattype cms_appl_pan.cap_card_type%TYPE;
  V_PROXYNUMBER CMS_APPL_PAN.CAP_PROXY_NUMBER%type;
  V_APPLPAN_CARDSTAT CMS_APPL_PAN.CAP_CARD_STAT%type;
  V_CAM_TYPE_CODE CMS_ACCT_MAST.CAM_TYPE_CODE%type;
  V_TIMESTAMP TIMESTAMP;
  V_AUTH_ID TRANSACTIONLOG.AUTH_ID%type;
  V_CARDTYPE CMS_APPL_PAN.CAP_CARD_TYPE%type;
  v_cardexp DATE;
  V_ACCT_NUMBER CMS_APPL_PAN.CAP_ACCT_NO%type;
  v_savinngs_bal CMS_ACCT_MAST.CAM_ACCT_BAL%type;
  V_SAVINNGS_LEDGBAL CMS_ACCT_MAST.CAM_LEDGER_BAL%type;
  V_SPENDING_BAL CMS_ACCT_MAST.CAM_ACCT_BAL%type;
  v_spending_ledgbal CMS_ACCT_MAST.CAM_LEDGER_BAL%type;
  V_DR_CR_FLAG  VARCHAR2 (2);
  V_TRANS_DESC  VARCHAR2 (50);
  v_narration   VARCHAR2 (300);
  V_OUTPUT_TYPE VARCHAR2 (2);
  v_tran_type   VARCHAR2 (2);
  v_txn_type transactionlog.txn_type%TYPE;
  v_acct_type cms_acct_type.cat_type_code%TYPE;
  v_max_noOf_txn cms_dfg_param.cdp_param_value%type;
  V_SAVTOSPD_TFR_COUNT CMS_ACCT_MAST.CAM_SAVTOSPD_TFER_COUNT%type;
  v_tran_date DATE;
  v_Retperiod  date; --Added for VMS-5733/FSP-991
  v_Retdate  date; --Added for VMS-5733/FSP-991
  
  --<< MAIN BEGIN>>
BEGIN
  V_RESP_MSG := 'OK';
  v_timestamp :=SYSTIMESTAMP;
  BEGIN
    BEGIN
      v_hash_pan := gethash (prm_card_no);
    EXCEPTION
    WHEN OTHERS THEN
      v_resp_code := '21';
      v_resp_msg  := 'Error while converting pan into hash' || SUBSTR (SQLERRM, 1, 100);
      RAISE excp_rej_record;
    END;
    BEGIN
      v_encr_pan := fn_emaps_main (prm_card_no);
    EXCEPTION
    WHEN OTHERS THEN
      v_resp_code := '21';
      v_resp_msg  := 'Error while converting pan into encr ' || SUBSTR (SQLERRM, 1, 100);
      RAISE excp_rej_record;
    END;
    BEGIN
      SELECT cap_prod_code,
        cap_card_type,
        cap_acct_no,
        cap_expry_date
      INTO v_prod_code,
        v_cardtype,
        v_acct_number,
        v_cardexp
      FROM cms_appl_pan
      WHERE cap_pan_code = v_hash_pan
      AND cap_inst_code  = prm_inst_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_resp_code := '16';
      v_resp_msg  := 'Card number not found ';
      RAISE excp_rej_record;
    WHEN OTHERS THEN
      v_resp_code := '21';
      v_resp_msg  :='Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
      RAISE excp_rej_record;
    END;
    BEGIN
      IF prm_txn_code = '45' THEN
        SP_SPENDINGTOSAVINGSTRANSFER( prm_inst_code,
                                      PRM_CARD_NO,
                                      PRM_MSG,
                                      PRM_SPEN_ACCT,
                                      PRM_SVNG_ACCT,
                                      PRM_DELIVERY_CHANNEL,
                                      prm_txn_code,
                                      PRM_RRN,
                                      prm_txn_amt,
                                      PRM_TXN_MODE,
                                      PRM_BANK_CODE,
                                      prm_curr_code,
                                      PRM_RVSL_CODE,
                                      prm_tran_date,
                                      PRM_TRAN_TIME,
                                      PRM_IPADDRESS,
                                      NULL,
                                      NULL,
                                      PRM_RESP_CODE,
                                      PRM_RESP_MSG,
                                      prm_avail_bal,
                                      prm_ledger_bal );
      ELSE
        SP_SAVINGSTOSPENDINGTRANSFER( prm_inst_code,
                                      PRM_CARD_NO,
                                      PRM_MSG,
                                      PRM_SPEN_ACCT,
                                      PRM_SVNG_ACCT,
                                      PRM_DELIVERY_CHANNEL,
                                      prm_txn_code,
                                      PRM_RRN,
                                      prm_txn_amt,
                                      PRM_TXN_MODE,
                                      prm_bank_code,
                                      prm_curr_code,
                                      PRM_RVSL_CODE,
                                      prm_tran_date,
                                      PRM_TRAN_TIME,
                                      PRM_IPADDRESS,
                                      NULL,
                                      NULL,
                                      PRM_RESP_CODE,
                                      PRM_RESP_MSG,
                                      PRM_AVAIL_BAL,
                                      PRM_LEDGER_BAL,
                                      P_AVAILED_TXN,
                                      p_available_txn );
      END IF;
      IF prm_resp_code <> '00' THEN
        V_RESP_MSG  := PRM_RESP_MSG;
        v_resp_code := prm_resp_code;
        RAISE EXCP_REJ_RECORD;
      ELSE
        PRM_RESP_MSG  := V_RESP_MSG;
      END IF;
    EXCEPTION
    WHEN EXCP_REJ_RECORD THEN
        RAISE;
    WHEN OTHERS THEN
      v_resp_code := '21';
      V_RESP_MSG  := 'while calling transfer process ' || SUBSTR (SQLERRM, 1, 100);
      RAISE excp_rej_record;
    END;
    IF prm_resp_code = '00' THEN
      --Getting Max No Of Transaction At Product level
      BEGIN
        SELECT cdp_param_value
        INTO v_max_noOf_txn
        FROM cms_dfg_param
        WHERE cdp_inst_code = prm_inst_code
        AND cdp_prod_code   = v_prod_code
        and cdp_card_type = v_cardtype
        AND cdp_param_key   ='MaxNoTrans';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_resp_msg  := 'Maximum No Of Transaction Not Set At Product Level';
        v_resp_code := '49';
        RAISE EXCP_REJ_RECORD;
      WHEN OTHERS THEN
      V_RESP_CODE := '21';
      v_resp_msg  := 'Error while selecting Max No Of Trans ' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXCP_REJ_RECORD;
      END;
      --Getting Saving Account Count
      BEGIN
        SELECT CAM_SAVTOSPD_TFER_COUNT
        INTO v_savtospd_tfr_count
        FROM CMS_ACCT_MAST
        where CAM_INST_CODE = PRM_INST_CODE
        AND CAM_ACCT_NO  = PRM_SVNG_ACCT;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_RESP_CODE := '16';
        v_resp_msg  := 'Saving Account Not Found ';
        RAISE EXCP_REJ_RECORD;
      WHEN OTHERS THEN
      V_RESP_CODE := '21';
      V_RESP_MSG  := 'Error while selecting saving to spending trans count ' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXCP_REJ_RECORD;
      END;
      P_AVAILABLE_TXN := v_max_noOf_txn - v_savtospd_tfr_count;
      BEGIN
        BEGIN
          SELECT NVL (MAX (ccd_call_seq), 0) + 1
          INTO v_call_seq
          FROM cms_calllog_details
          WHERE ccd_inst_code = ccd_inst_code
          AND ccd_call_id     = prm_call_id
          AND ccd_pan_code    = v_hash_pan;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_resp_msg  := 'record is not present in cms_calllog_details  ';
          v_resp_code := '49';
          RAISE excp_rej_record;
        WHEN OTHERS THEN
          V_RESP_MSG  := 'Error while selecting from cms_calllog_details ' || SUBSTR (SQLERRM, 1, 100);
          v_resp_code := '21';
          RAISE excp_rej_record;
        END;
        INSERT
        INTO cms_calllog_details
          (
            ccd_inst_code,
            ccd_call_id,
            ccd_pan_code,
            ccd_call_seq,
            ccd_rrn,
            ccd_devl_chnl,
            ccd_txn_code,
            ccd_tran_date,
            ccd_tran_time,
            ccd_tbl_names,
            ccd_colm_name,
            ccd_old_value,
            ccd_new_value,
            ccd_comments,
            ccd_ins_user,
            ccd_ins_date,
            ccd_lupd_user,
            ccd_lupd_date,
            ccd_acct_no
          )
          VALUES
          (
            prm_inst_code,
            prm_call_id,
            v_hash_pan,
            v_call_seq,
            prm_rrn,
            prm_delivery_channel,
            PRM_TXN_CODE,
            PRM_TRAN_DATE,
            PRM_TRAN_TIME,
            NULL,
            NULL,
            NULL,
            NULL,
            NVL(prm_remark,DECODE(prm_txn_code,'45','SPENDING TO SAVING TRANSFER','44','SAVING TO SPENDING TRANSFER')),
            prm_ins_user,
            SYSDATE,
            prm_ins_user,
            sysdate,
            PRM_SPEN_ACCT
          );
      EXCEPTION
      WHEN excp_rej_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_code := '21';
        v_resp_msg  := ' Error while inserting into cms_calllog_details ' || SUBSTR (SQLERRM, 1, 100);
        RAISE excp_rej_record;
      END;
    END IF;
    BEGIN
    
    v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
      SET remark           = NVL(prm_remark,DECODE(prm_txn_code,'45','SPENDING TO SAVING TRANSFER','44','SAVING TO SPENDING TRANSFER')),
        add_ins_user       = prm_ins_user,
        add_lupd_user      = prm_ins_user,
        ipaddress          = prm_ipaddress
      WHERE instcode       = prm_inst_code
      AND customer_card_no = v_hash_pan
      AND rrn              = prm_rrn
      AND business_date    = prm_tran_date
      AND business_time    = prm_tran_time
      AND delivery_channel = prm_delivery_channel
      AND txn_code         = prm_txn_code;
    ELSE
         UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
      SET remark           = NVL(prm_remark,DECODE(prm_txn_code,'45','SPENDING TO SAVING TRANSFER','44','SAVING TO SPENDING TRANSFER')),
        add_ins_user       = prm_ins_user,
        add_lupd_user      = prm_ins_user,
        ipaddress          = prm_ipaddress
      WHERE instcode       = prm_inst_code
      AND customer_card_no = v_hash_pan
      AND rrn              = prm_rrn
      AND business_date    = prm_tran_date
      AND business_time    = prm_tran_time
      AND delivery_channel = prm_delivery_channel
      AND txn_code         = prm_txn_code;
    END IF;  
      
      IF SQL%ROWCOUNT      = 0 THEN
        v_resp_code       := '21';
        v_resp_msg        := 'Txn not updated in transactiolog for remark';
        RAISE excp_rej_record;
      END IF;
    EXCEPTION
    WHEN excp_rej_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_code := '21';
      v_resp_msg  := 'Error while updating into transactiolog ' || SUBSTR (SQLERRM, 1, 200);
      RAISE excp_rej_record;
    END;
    IF prm_txn_code = '44' AND PRM_RESP_CODE='00' AND P_AVAILABLE_TXN = '0' THEN
      BEGIN
        SELECT CAM_ACCT_BAL,
          CAM_LEDGER_BAL,
          CAM_TYPE_CODE
        INTO v_savinngs_bal,
          v_savinngs_ledgbal,
          v_acct_type
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = PRM_INST_CODE
        AND CAM_ACCT_NO     = PRM_SVNG_ACCT;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_RESP_CODE := '17'; --Ineligible Transaction
        v_resp_msg  := 'Invalid Saving Account ';
        RAISE excp_rej_record;
      WHEN OTHERS THEN
        v_resp_code := '21';
        v_resp_msg  := 'Error while selecting data from card Master ' || SUBSTR (SQLERRM, 1, 200);
        RAISE excp_rej_record;
      END;
      --Selecting Spending Account Balance
      BEGIN
        SELECT CAM_ACCT_BAL,
          CAM_LEDGER_BAL--,CAM_TYPE_CODE
        INTO V_SPENDING_BAL,
          v_spending_ledgbal--,v_acct_type
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = PRM_INST_CODE
        AND CAM_ACCT_NO     = PRM_SPEN_ACCT;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_RESP_CODE := '17'; --Ineligible Transaction
        v_resp_msg  := 'Invalid Spending Account ';
        RAISE excp_rej_record;
      WHEN OTHERS THEN
        V_RESP_CODE := '21';
        v_resp_msg  := 'Error while selecting spending account balance ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXCP_REJ_RECORD;
      END;
      BEGIN
        UPDATE CMS_ACCT_MAST
        SET cam_acct_bal    = cam_acct_bal   + v_savinngs_bal,
          CAM_LEDGER_BAL    = CAM_LEDGER_BAL + V_SAVINNGS_LEDGBAL,
          cam_lupd_date     = SYSDATE,
          CAM_LUPD_USER     = 1
        WHERE cam_inst_code = prm_inst_code
        AND CAM_ACCT_NO     = PRM_SPEN_ACCT;
        IF sql%ROWCOUNT     = 0 THEN
          V_RESP_CODE      := '21';
          v_resp_msg       := 'Error while updating spending account';
          RAISE excp_rej_record;
        END IF;
      EXCEPTION
      WHEN excp_rej_record THEN
        RAISE excp_rej_record;
      WHEN OTHERS THEN
        v_resp_code := '21';
        v_resp_msg  := 'Error while updating spending account details' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXCP_REJ_RECORD;
      END;
      BEGIN
        UPDATE CMS_ACCT_MAST
        SET cam_stat_code   = '2',
          cam_acct_bal      = cam_acct_bal   - v_savinngs_bal,
          CAM_LEDGER_BAL    = CAM_LEDGER_BAL - V_SAVINNGS_LEDGBAL,
          cam_lupd_date     = SYSDATE,
          CAM_LUPD_USER     = 1
        WHERE cam_inst_code = prm_inst_code
        AND CAM_ACCT_NO     = PRM_SVNG_ACCT;
        IF sql%ROWCOUNT     = 0 THEN
          v_RESP_CODE      := '21';
          v_resp_msg       := 'Error while closing saving account';
          RAISE excp_rej_record;
        END IF;
      EXCEPTION
      WHEN excp_rej_record THEN
        RAISE excp_rej_record;
      WHEN OTHERS THEN
        v_resp_code := '21';
        v_resp_msg  := 'Error while updating saving account details' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXCP_REJ_RECORD;
      END;
      BEGIN
        SELECT ctm_credit_debit_flag,
          ctm_output_type,
          TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
          ctm_tran_type,
          ctm_tran_desc
        INTO v_dr_cr_flag,
          v_output_type,
          v_txn_type,
          v_tran_type,
          v_trans_desc
        FROM cms_transaction_mast
        WHERE ctm_tran_code      = '40'
        AND ctm_delivery_channel = '05'
        AND ctm_inst_code        = prm_inst_code;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_resp_code := '12'; --Ineligible Transaction
        v_resp_msg  := 'Transflag  not defined for txn code 40 and delivery channel 05';
        RAISE EXCP_REJ_RECORD;
      WHEN OTHERS THEN
        v_resp_code := '21'; --Ineligible Transaction
        v_resp_msg  := 'Error while selecting transaction details ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXCP_REJ_RECORD;
      END;
      BEGIN
        IF TRIM (v_trans_desc) IS NOT NULL THEN
          v_narration          := v_trans_desc || '/';
        END IF;
        IF TRIM (v_auth_id) IS NOT NULL THEN
          v_narration       := v_narration || v_auth_id || '/';
        END IF;
        IF TRIM (PRM_SVNG_ACCT) IS NOT NULL THEN
          v_narration           := v_narration || PRM_SVNG_ACCT || '/';
        END IF;
        IF TRIM (prm_tran_date) IS NOT NULL THEN
          v_narration           := v_narration || prm_tran_date;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_code := '21';
        v_resp_msg  := 'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXCP_REJ_RECORD;
      END;
      BEGIN
        v_dr_cr_flag := 'DR';
        INSERT
        INTO cms_statements_log
          (
            csl_pan_no,
            csl_acct_no,
            csl_opening_bal,
            csl_trans_amount,
            csl_trans_type,
            csl_trans_date,
            csl_closing_balance,
            csl_trans_narrration,
            csl_pan_no_encr,
            csl_rrn,
            csl_auth_id,
            csl_business_date,
            csl_business_time,
            txn_fee_flag,
            csl_delivery_channel,
            csl_inst_code,
            csl_txn_code,
            csl_ins_date,
            csl_ins_user,
            csl_panno_last4digit,
            csl_to_acctno,
            csl_acct_type,
            csl_prod_code,csl_card_type,
            csl_time_stamp
          )
          VALUES
          (
            v_hash_pan,
            PRM_SVNG_ACCT,
            v_savinngs_bal,
            V_SAVINNGS_BAL,
            v_dr_cr_flag,
            sysdate,
            0,
            v_narration,
            V_ENCR_PAN,
            prm_rrn,
            PRM_AUTH_ID,
            prm_tran_date,
            prm_tran_time,
            'N',
            '05',
            PRM_INST_CODE,
            '40',
            SYSDATE,
            1,
            (SUBSTR (PRM_CARD_NO, LENGTH (PRM_CARD_NO) - 3, LENGTH (PRM_CARD_NO) ) ),
            PRM_SPEN_ACCT,
            DECODE(v_dr_cr_flag,'DR','2','1'),
            v_prod_code,v_cardtype,
            v_timestamp
          );
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_code := '21';
        v_resp_msg  := 'Error creating entry in statement log ';
        RAISE EXCP_REJ_RECORD;
      END;

      BEGIN
        v_dr_cr_flag := 'CR';
        INSERT
        INTO cms_statements_log
          (
            csl_pan_no,
            csl_acct_no,
            csl_opening_bal,
            csl_trans_amount,
            csl_trans_type,
            csl_trans_date,
            csl_closing_balance,
            csl_trans_narrration,
            csl_pan_no_encr,
            csl_rrn,
            csl_auth_id,
            csl_business_date,
            csl_business_time,
            txn_fee_flag,
            csl_delivery_channel,
            csl_inst_code,
            csl_txn_code,
            csl_ins_date,
            csl_ins_user,
            csl_panno_last4digit,
            csl_to_acctno,
            csl_acct_type,
            csl_prod_code,
            csl_time_stamp
          )
          VALUES
          (
            V_HASH_PAN,
            PRM_SPEN_ACCT,
            V_SPENDING_BAL,
            V_SAVINNGS_BAL,
            v_dr_cr_flag,
            sysdate,
            V_SPENDING_BAL + V_SAVINNGS_BAL,
            v_narration,
            V_ENCR_PAN,
            prm_rrn,
            PRM_AUTH_ID,
            prm_tran_date,
            prm_tran_time,
            'N',
            '05',
            PRM_INST_CODE,
            '40',
            SYSDATE,
            1,
            (SUBSTR (PRM_CARD_NO, LENGTH (PRM_CARD_NO) - 3, LENGTH (PRM_CARD_NO) ) ),
            PRM_SVNG_ACCT,
            DECODE(v_dr_cr_flag,'DR','2','1'),
            v_prod_code,
            V_TIMESTAMP
          );
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_code := '21';
        v_resp_msg  := 'Error creating entry in statement log ';
        RAISE EXCP_REJ_RECORD;
      END;
      ----------------------------------------
      BEGIN
        v_tran_date := TO_DATE ( SUBSTR (TRIM (PRM_TRAN_DATE), 1, 8) || ' ' || SUBSTR (TRIM (prm_tran_time), 1, 8), 'yyyymmdd hh24:mi:ss' );
      EXCEPTION
      WHEN OTHERS THEN
        V_RESP_CODE := '21';
        v_resp_msg  := 'Problem while converting transaction date ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXCP_REJ_RECORD;
      END;
      ----------------------------------------
      BEGIN
        SP_DAILY_BIN_BAL (PRM_CARD_NO, v_tran_date, V_SAVINNGS_BAL, V_DR_CR_FLAG, PRM_INST_CODE, PRM_BANK_CODE, v_resp_msg);
        IF v_resp_msg <> 'OK' THEN
          V_RESP_CODE := '21';
          v_resp_msg  := 'Error while executing daily_bin log '|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXCP_REJ_RECORD;
        END IF;
      EXCEPTION
      WHEN EXCP_REJ_RECORD THEN
        RAISE EXCP_REJ_RECORD;
      WHEN OTHERS THEN
        V_RESP_CODE := '21';
        v_resp_msg  := 'Error creating entry in daily_bin log '|| SUBSTR (SQLERRM, 1, 200);
        RAISE EXCP_REJ_RECORD;
      END;
      BEGIN
        INSERT
        INTO CMS_TRANSACTION_LOG_DTL
          (
            CTD_DELIVERY_CHANNEL,
            CTD_TXN_CODE,
            CTD_TXN_TYPE,
            CTD_TXN_MODE,
            CTD_BUSINESS_DATE,
            CTD_BUSINESS_TIME,
            CTD_CUSTOMER_CARD_NO,
            CTD_TXN_AMOUNT,
            CTD_TXN_CURR,
            CTD_ACTUAL_AMOUNT,
            --CTD_FEE_AMOUNT,
            --CTD_WAIVER_AMOUNT,
            --CTD_SERVICETAX_AMOUNT,
            --CTD_CESS_AMOUNT,
            --CTD_BILL_AMOUNT,
            CTD_BILL_CURR,
            CTD_PROCESS_FLAG,
            CTD_PROCESS_MSG,
            CTD_RRN,
            CTD_SYSTEM_TRACE_AUDIT_NO,
            CTD_CUSTOMER_CARD_NO_ENCR,
            CTD_MSG_TYPE,
            CTD_CUST_ACCT_NUMBER,
            CTD_INST_CODE--,
            --CTD_HASHKEY_ID
          )
          VALUES
          (
            prm_delivery_channel,
            prm_txn_code,
            V_TXN_TYPE,
            prm_txn_mode,
            PRM_TRAN_DATE,
            prm_tran_time,
            V_HASH_PAN,
            prm_txn_amt,
            prm_curr_code,
            prm_txn_amt,
            --V_LOG_ACTUAL_FEE,
            --V_LOG_WAIVER_AMT,
            --V_SERVICETAX_AMOUNT,
            --V_CESS_AMOUNT,
            --V_TOTAL_AMT,
            prm_curr_code,
            'Y',
            'Successful',
            prm_rrn,
            prm_stan,
            V_ENCR_PAN,
            prm_msg,
            V_ACCT_NUMBER,
            prm_inst_code--,
            --V_HASHKEY_ID
          );
      EXCEPTION
      WHEN OTHERS THEN
        prm_resp_msg  := 'Problem while inserting record in transaction log detail table ' ||SUBSTR(SQLERRM, 1, 300);
        prm_resp_code := '21';
        RAISE excp_rej_record;
      END;
      --------------------
      BEGIN
        INSERT
        INTO TRANSACTIONLOG
          (
            MSGTYPE,
            RRN,
            DELIVERY_CHANNEL,
            --TERMINAL_ID,
            DATE_TIME,
            TXN_CODE,
            TXN_TYPE,
            TXN_MODE,
            TXN_STATUS,
            RESPONSE_CODE,
            BUSINESS_DATE,
            BUSINESS_TIME,
            CUSTOMER_CARD_NO,
            TOPUP_CARD_NO,
            TOPUP_ACCT_NO,
            TOPUP_ACCT_TYPE,
            --BANK_CODE,
            --TOTAL_AMOUNT,
            RULE_INDICATOR,
            RULEGROUPID,
            MCCODE,
            CURRENCYCODE,
            ADDCHARGE,
            PRODUCTID,
            CATEGORYID,
            --TIPS,
            DECLINE_RULEID,
            --ATM_NAME_LOCATION,
            AUTH_ID,
            TRANS_DESC,
            AMOUNT,
            PREAUTHAMOUNT,
            PARTIALAMOUNT,
            --MCCODEGROUPID,
            --CURRENCYCODEGROUPID,
            --TRANSCODEGROUPID,
            --rules,
            --PREAUTH_DATE,
            --GL_UPD_FLAG,
            SYSTEM_TRACE_AUDIT_NO,
            INSTCODE,
            --FEECODE,
            --TRANFEE_AMT,
            --SERVICETAX_AMT,
            --CESS_AMT,
            CR_DR_FLAG,
            --TRANFEE_CR_ACCTNO,
            --TRANFEE_DR_ACCTNO,
            --TRAN_ST_CALC_FLAG,
            --TRAN_CESS_CALC_FLAG,
            --TRAN_ST_CR_ACCTNO,
            --TRAN_ST_DR_ACCTNO,
            --TRAN_CESS_CR_ACCTNO,
            --TRAN_CESS_DR_ACCTNO,
            CUSTOMER_CARD_NO_ENCR,
            TOPUP_CARD_NO_ENCR,
            --PROXY_NUMBER,
            REVERSAL_CODE,
            CUSTOMER_ACCT_NO,
            ACCT_BALANCE,
            ledger_balance,
            TOPUP_ACCT_BALANCE,
            topup_ledger_balance,
            RESPONSE_ID,
            ADD_INS_DATE,
            ADD_INS_USER,
            CARDSTATUS,
            --FEE_PLAN,
            --CSR_ACHACTIONTAKEN,
            ERROR_MSG,
            --FEEATTACHTYPE,
            --MERCHANT_NAME,
            --MERCHANT_CITY,
            --MERCHANT_STATE,
            ACCT_TYPE,
            TIME_STAMP
          )
          VALUES
          (
            Prm_MSG,
            Prm_RRN,
            '05',
            --P_TERM_ID,
            V_TRAN_DATE,
            '40',
            V_TXN_TYPE,
            Prm_TXN_MODE,
            DECODE(prm_resp_code, '00', 'C', 'F'),
            prm_resp_code,
            prm_TRAN_DATE,
            Prm_TRAN_TIME,
            V_HASH_PAN,
            V_HASH_PAN,
            PRM_SPEN_ACCT,
            NULL,
            --P_BANK_CODE,
            --TRIM(TO_CHAR(NVL(V_TOTAL_AMT,0), '99999999999999990.99')),
            NULL,
            NULL,
            prm_mcc_code,
            Prm_CURR_CODE,
            NULL,
            V_PROD_CODE,
            V_PROD_CATTYPE,
            --P_TIP_AMT,
            NULL,
            --P_ATMNAME_LOC,
            V_AUTH_ID,
            V_TRANS_DESC,
            TRIM(TO_CHAR(NVL(V_SAVINNGS_BAL,0), '999999999999999990.99')),
            '0.00',
            '0.00',
            --P_MCCCODE_GROUPID,
            --P_CURRCODE_GROUPID,
            --P_TRANSCODE_GROUPID,
            --P_RULES,
            --P_PREAUTH_DATE,
            --V_GL_UPD_FLAG,
            Prm_STAN,
            prm_inst_code,
            --V_FEE_CODE,
            --V_FEE_AMT,
            --V_SERVICETAX_AMOUNT,
            --V_CESS_AMOUNT,
            V_DR_CR_FLAG,
            --V_FEE_CRACCT_NO,
            --V_FEE_DRACCT_NO,
            --V_ST_CALC_FLAG,
            --V_CESS_CALC_FLAG,
            --V_ST_CRACCT_NO,
            --V_ST_DRACCT_NO,
            --V_CESS_CRACCT_NO,
            --V_CESS_DRACCT_NO,
            V_ENCR_PAN,
            V_ENCR_PAN,
            --V_PROXUNUMBER,
            prm_rvsl_code,
            PRM_SVNG_ACCT,
            0,
            0,
            TRIM(TO_CHAR(NVL(V_SPENDING_BAL     + V_SAVINNGS_BAL,0), '999999999999999990.99')),
            TRIM(TO_CHAR(NVL(v_spending_ledgbal + V_SAVINNGS_BAL,0), '999999999999999990.99')),
            prm_resp_code,
            SYSDATE,
            1,
            V_APPLPAN_CARDSTAT,
            --V_FEE_PLAN,
            --p_fee_flag,
            prm_resp_msg,
            --V_FEEATTACH_TYPE,
            --P_MERCHANT_NAME,
            --P_MERCHANT_CITY,
            --P_ATMNAME_LOC,
            V_CAM_TYPE_CODE,
            V_TIMESTAMP
          );
      EXCEPTION
      WHEN OTHERS THEN
        prm_resp_msg  := 'Problem while inserting record in transaction log table ' ||SUBSTR(SQLERRM, 1, 300);
        prm_resp_code := '21';
        RAISE EXCP_REJ_RECORD;
      END;
      -------------------
    END IF;
    ------------------------------------------------------------------------------------------------------------------------------------------------
    --Fetching saving account balance after processing as displaying in CSR out put screen
    BEGIN
      SELECT CAM_ACCT_BAL
      INTO PRM_SAVING_AVAIL_BAL
      FROM CMS_ACCT_MAST
      WHERE CAM_INST_CODE = PRM_INST_CODE
      AND CAM_ACCT_NO     = PRM_SVNG_ACCT;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_RESP_CODE := '17'; --Ineligible Transaction
      V_RESP_MSG  := 'Invalid Saving Account ';
      RAISE EXCP_REJ_RECORD;
    WHEN OTHERS THEN
    V_RESP_CODE := '21';
    V_RESP_MSG  := 'Error while selecting saving account balance ' || SUBSTR (SQLERRM, 1, 200);
    RAISE EXCP_REJ_RECORD;
    END;
  EXCEPTION
  WHEN excp_rej_record THEN
    ROLLBACK;
    BEGIN
      SELECT cms_iso_respcde
      INTO prm_resp_code
      FROM cms_response_mast
      WHERE cms_inst_code      = prm_inst_code
      AND cms_delivery_channel = prm_delivery_channel
      AND cms_response_id      = v_resp_code;
      prm_resp_msg            := v_resp_msg;
    EXCEPTION
    WHEN OTHERS THEN
      prm_resp_msg  := 'Problem while selecting data from response master2 ' || v_resp_code || SUBSTR (SQLERRM, 1, 100);
      prm_resp_code := '89';
    END;
    IF V_APPLPAN_CARDSTAT IS NULL
    then
    BEGIN
      SELECT cap_acct_no,
        cap_prod_code,
        cap_card_type,
        cap_proxy_number,
        cap_card_stat
      INTO v_cap_acct_no,
        v_prod_code,
        v_prod_cattype,
        v_proxynumber,
        v_applpan_cardstat
      FROM cms_appl_pan
      WHERE cap_inst_code = prm_inst_code
      AND cap_pan_code    = v_hash_pan;
    EXCEPTION
    WHEN OTHERS THEN
      null;
    END;
    end if;
    BEGIN
      SELECT cam_acct_bal,
        cam_ledger_bal,
        cam_type_code
      INTO V_SPENDING_BAL,
        V_SPENDING_LEDGBAL,
        v_cam_type_code
      FROM cms_acct_mast
      WHERE cam_inst_code = prm_inst_code
      AND CAM_ACCT_NO     = PRM_SPEN_ACCT;
    EXCEPTION
    WHEN OTHERS THEN
      V_SPENDING_BAL   := NULL;
      V_SPENDING_LEDGBAL := NULL;
    END;
    -----------------------
    BEGIN
      SELECT cam_acct_bal,
        cam_ledger_bal,
        cam_type_code
      INTO V_SAVINNGS_BAL,
        V_SAVINNGS_LEDGBAL,
        v_cam_type_code
      FROM cms_acct_mast
      WHERE cam_inst_code = prm_inst_code
      AND cam_acct_no     = PRM_SVNG_ACCT;
    EXCEPTION
    WHEN OTHERS THEN
      V_SAVINNGS_BAL   := NULL;
      V_SAVINNGS_LEDGBAL := NULL;
    END;
    BEGIN
      INSERT
      INTO cms_transaction_log_dtl
        (
          ctd_delivery_channel,
          ctd_txn_code,
          ctd_txn_type,
          ctd_txn_mode,
          ctd_business_date,
          ctd_business_time,
          ctd_customer_card_no,
          ctd_txn_amount,
          ctd_txn_curr,
          ctd_actual_amount,
          ctd_fee_amount,
          ctd_waiver_amount,
          ctd_servicetax_amount,
          ctd_cess_amount,
          ctd_bill_amount,
          ctd_bill_curr,
          ctd_process_flag,
          ctd_process_msg,
          ctd_rrn,
          ctd_system_trace_audit_no,
          ctd_customer_card_no_encr,
          ctd_msg_type,
          ctd_cust_acct_number,
          ctd_inst_code,
          ctd_lupd_date,
          ctd_lupd_user,
          ctd_ins_date,
          ctd_ins_user
        )
        VALUES
        (
          prm_delivery_channel,
          prm_txn_code,
          NULL,
          prm_txn_mode,
          prm_tran_date,
          prm_tran_time,
          v_hash_pan,
          NULL,
          prm_curr_code,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          'E',
          v_resp_msg,
          prm_rrn,
          prm_stan,
          v_encr_pan,
          prm_msg,
          v_cap_acct_no,
          prm_inst_code,
          SYSDATE,
          prm_ins_user,
          SYSDATE,
          prm_ins_user
        );
    EXCEPTION
    WHEN OTHERS THEN
      prm_resp_code := '89';
      prm_resp_msg  := 'Problem while inserting data into transaction log1  dtl' || SUBSTR (SQLERRM, 1, 100);
      ROLLBACK;
    END;
    --Sn create a entry in txn log
    BEGIN
      INSERT
      INTO transactionlog
        (
          msgtype,
          rrn,
          delivery_channel,
          date_time,
          txn_code,
          txn_type,
          txn_mode,
          txn_status,
          response_code,
          business_date,
          business_time,
          customer_card_no,
          total_amount,
          currencycode,
          productid,
          categoryid,
          auth_id,
          trans_desc,
          amount,
          system_trace_audit_no,
          instcode,
          cr_dr_flag,
          CUSTOMER_CARD_NO_ENCR,
          TOPUP_CARD_NO_ENCR,
          proxy_number,
          reversal_code,
          CUSTOMER_ACCT_NO,
          topup_acct_no,
          acct_balance,
          LEDGER_BALANCE,
          TOPUP_ACCT_BALANCE,
          topup_ledger_balance,
          response_id,
          error_msg,
          add_lupd_date,
          add_lupd_user,
          add_ins_date,
          add_ins_user,
          remark,
          ipaddress,
          cardstatus,
          acct_type,
          time_stamp
        )
        VALUES
        (
          prm_msg,
          prm_rrn,
          prm_delivery_channel,
          TO_DATE (prm_tran_date
          || ' '
          || prm_tran_time, 'yyyymmdd hh24:mi:ss' ),
          prm_txn_code,
          NULL,
          prm_txn_mode,
          DECODE (prm_resp_code, '00', 'C', 'F'),
          prm_resp_code,
          prm_tran_date,
          prm_tran_time,
          v_hash_pan,
          TRIM (TO_CHAR (0, '99999999999999990.99')),
          prm_curr_code,
          v_prod_code,
          v_prod_cattype,
          PRM_AUTH_ID,
          decode(PRM_TXN_CODE,'45','SPENDING TO SAVING ACCOUNT TRANSFER','44','SAVING TO SPENDING ACCOUNT TRANSFER'),
          PRM_TXN_AMT,
          prm_stan,
          PRM_INST_CODE,
          decode(PRM_TXN_CODE,'45','DR','44','CR'),
          V_ENCR_PAN,
          v_encr_pan,
          v_proxynumber,
          '00',
          DECODE(PRM_TXN_CODE,'45',PRM_SPEN_ACCT,'44',PRM_SVNG_ACCT),
          DECODE(PRM_TXN_CODE,'45',PRM_SVNG_ACCT,'44',PRM_SPEN_ACCT),
          DECODE(PRM_TXN_CODE,'45',V_SPENDING_BAL,'44',V_SAVINNGS_BAL),
          DECODE(PRM_TXN_CODE,'45',v_spending_ledgbal,'44',V_SAVINNGS_LEDGBAL),
          DECODE(PRM_TXN_CODE,'45',v_savinngs_bal,'44',V_SPENDING_BAL),
          DECODE(PRM_TXN_CODE,'45',V_SAVINNGS_LEDGBAL,'44',v_spending_ledgbal),
          v_resp_code,
          prm_resp_msg,
          SYSDATE,
          prm_ins_user,
          SYSDATE,
          prm_ins_user,
          prm_remark,
          prm_ipaddress,
          V_APPLPAN_CARDSTAT,
          decode(PRM_TXN_CODE,'45','1','44','2'),
          v_timestamp
        );
    EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      prm_resp_code := '89';
      prm_resp_msg  := 'Problem while inserting data into transaction log3 ' || SUBSTR (SQLERRM, 1, 100);
    END;
    --En create a entry in txn log
  WHEN OTHERS THEN
    ROLLBACK;
    BEGIN
      SELECT cms_iso_respcde
      INTO prm_resp_code
      FROM cms_response_mast
      WHERE cms_inst_code      = prm_inst_code
      AND cms_delivery_channel = prm_delivery_channel
      AND cms_response_id      = '21';
      prm_resp_msg            := 'Error from others exception ' || SUBSTR (SQLERRM, 1, 100);
    EXCEPTION
    WHEN OTHERS THEN
      prm_resp_msg  := 'Problem while selecting data from response master3 ' || v_resp_code || SUBSTR (SQLERRM, 1, 100);
      prm_resp_code := '89';
    END;
    BEGIN
      SELECT cap_acct_no,
        cap_prod_code,
        cap_card_type,
        cap_proxy_number
      INTO v_cap_acct_no,
        v_prod_code,
        v_prod_cattype,
        v_proxynumber
      FROM cms_appl_pan
      WHERE cap_inst_code = prm_inst_code
      AND cap_pan_code    = v_hash_pan;
    EXCEPTION
    WHEN OTHERS THEN
      v_cap_acct_no  := NULL;
      v_prod_code    := NULL;
      v_prod_cattype := NULL;
      v_proxynumber  := NULL;
    END;
    BEGIN
      SELECT cam_acct_bal,
        cam_ledger_bal
      INTO v_acct_balance,
        v_ledger_balance
      FROM cms_acct_mast
      WHERE cam_inst_code = prm_inst_code
      AND cam_acct_no     = v_cap_acct_no;
    EXCEPTION
    WHEN OTHERS THEN
      v_acct_balance   := NULL;
      v_ledger_balance := NULL;
    END;
    BEGIN
      INSERT
      INTO cms_transaction_log_dtl
        (
          ctd_delivery_channel,
          ctd_txn_code,
          ctd_txn_type,
          ctd_txn_mode,
          ctd_business_date,
          ctd_business_time,
          ctd_customer_card_no,
          ctd_txn_amount,
          ctd_txn_curr,
          ctd_actual_amount,
          ctd_fee_amount,
          ctd_waiver_amount,
          ctd_servicetax_amount,
          ctd_cess_amount,
          ctd_bill_amount,
          ctd_bill_curr,
          ctd_process_flag,
          ctd_process_msg,
          ctd_rrn,
          ctd_system_trace_audit_no,
          ctd_customer_card_no_encr,
          ctd_msg_type,
          ctd_cust_acct_number,
          ctd_inst_code,
          ctd_lupd_date,
          ctd_lupd_user,
          ctd_ins_date,
          ctd_ins_user
        )
        VALUES
        (
          prm_delivery_channel,
          prm_txn_code,
          NULL,
          prm_txn_mode,
          prm_tran_date,
          prm_tran_time,
          v_hash_pan,
          NULL,
          prm_curr_code,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          'E',
          v_resp_msg,
          prm_rrn,
          prm_stan,
          v_encr_pan,
          prm_msg,
          v_cap_acct_no,
          prm_inst_code,
          SYSDATE,
          prm_ins_user,
          SYSDATE,
          prm_ins_user
        );
    EXCEPTION
    WHEN OTHERS THEN
      PRM_RESP_CODE := '89';
      prm_resp_msg  := 'Problem while inserting data into transaction log1  dtl ' || SUBSTR (SQLERRM, 1, 100);
      ROLLBACK;
    END;
    --Sn create a entry in txn log
    BEGIN
      INSERT
      INTO transactionlog
        (
          msgtype,
          rrn,
          delivery_channel,
          date_time,
          txn_code,
          txn_type,
          txn_mode,
          txn_status,
          response_code,
          business_date,
          business_time,
          customer_card_no,
          total_amount,
          currencycode,
          productid,
          categoryid,
          auth_id,
          trans_desc,
          amount,
          system_trace_audit_no,
          instcode,
          cr_dr_flag,
          CUSTOMER_CARD_NO_ENCR,
          TOPUP_CARD_NO_ENCR,
          proxy_number,
          reversal_code,
          CUSTOMER_ACCT_NO,
          topup_acct_no,
          acct_balance,
          LEDGER_BALANCE,
          TOPUP_ACCT_BALANCE,
          topup_ledger_balance,
          response_id,
          error_msg,
          add_lupd_date,
          add_lupd_user,
          add_ins_date,
          add_ins_user,
          remark,
          ipaddress,
          cardstatus,
          acct_type,
          time_stamp
        )
        VALUES
        (
          prm_msg,
          prm_rrn,
          prm_delivery_channel,
          TO_DATE (prm_tran_date
          || ' '
          || prm_tran_time, 'yyyymmdd hh24:mi:ss' ),
          prm_txn_code,
          NULL,
          prm_txn_mode,
          DECODE (prm_resp_code, '00', 'C', 'F'),
          prm_resp_code,
          prm_tran_date,
          prm_tran_time,
          v_hash_pan,
          TRIM (TO_CHAR (0, '99999999999999990.99')),
          prm_curr_code,
          v_prod_code,
          v_prod_cattype,
          PRM_AUTH_ID,
          decode(PRM_TXN_CODE,'45','SPENDING TO SAVING ACCOUNT TRANSFER','44','SAVING TO SPENDING ACCOUNT TRANSFER'),
          PRM_TXN_AMT,
          prm_stan,
          PRM_INST_CODE,
          decode(PRM_TXN_CODE,'45','DR','44','CR'),
          V_ENCR_PAN,
          v_encr_pan,
          v_proxynumber,
          '00',
          DECODE(PRM_TXN_CODE,'45',PRM_SPEN_ACCT,'44',PRM_SVNG_ACCT),
          DECODE(PRM_TXN_CODE,'45',PRM_SVNG_ACCT,'44',PRM_SPEN_ACCT),
          DECODE(PRM_TXN_CODE,'45',V_SPENDING_BAL,'44',V_SAVINNGS_BAL),
          DECODE(PRM_TXN_CODE,'45',v_spending_ledgbal,'44',V_SAVINNGS_LEDGBAL),
          DECODE(PRM_TXN_CODE,'45',v_savinngs_bal,'44',V_SPENDING_BAL),
          DECODE(PRM_TXN_CODE,'45',V_SAVINNGS_LEDGBAL,'44',v_spending_ledgbal),
          v_resp_code,
          prm_resp_msg,
          SYSDATE,
          prm_ins_user,
          SYSDATE,
          prm_ins_user,
          prm_remark,
          prm_ipaddress,
          V_APPLPAN_CARDSTAT,
          decode(PRM_TXN_CODE,'45','1','44','2'),
          v_timestamp
        );
    EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      prm_resp_code := '89';
      prm_resp_msg  := 'Problem while inserting data into transactionlog ' || SUBSTR (SQLERRM, 1, 100);
      RETURN;
    END;
  END;
  DBMS_OUTPUT.put_line (prm_resp_msg);
EXCEPTION
WHEN OTHERS THEN
  prm_resp_code := '89';
  prm_resp_msg  := ' Error from mail' || SUBSTR (SQLERRM, 1, 100);
  RETURN;
END;

/

show error