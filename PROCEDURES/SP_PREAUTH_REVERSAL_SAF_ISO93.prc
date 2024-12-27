CREATE OR REPLACE
PROCEDURE vmscms.sp_preauth_reversal_saf_iso93(
    p_inst_code           IN NUMBER,
    p_msg_typ             IN VARCHAR2,
    p_rvsl_code           IN VARCHAR2,
    p_rrn                 IN VARCHAR2,
    p_delv_chnl           IN VARCHAR2,
    p_terminal_id         IN VARCHAR2,
    p_merc_id             IN VARCHAR2,
    p_txn_code            IN VARCHAR2,
    p_txn_type            IN VARCHAR2,
    p_txn_mode            IN VARCHAR2,
    p_business_date       IN VARCHAR2,
    p_business_time       IN VARCHAR2,
    p_card_no             IN VARCHAR2,
    p_actual_amt          IN NUMBER,
    p_bank_code           IN VARCHAR2,
    p_stan                IN VARCHAR2,
    p_expry_date          IN VARCHAR2,
    p_tocust_card_no      IN VARCHAR2,
    p_tocust_expry_date   IN VARCHAR2,
    p_orgnl_business_date IN VARCHAR2,
    p_orgnl_business_time IN VARCHAR2,
    p_orgnl_rrn           IN VARCHAR2,
    p_mbr_numb            IN VARCHAR2,
    p_orgnl_terminal_id   IN VARCHAR2,
    p_curr_code           IN VARCHAR2,
    p_merchant_name       IN VARCHAR2,
    p_merchant_city       IN VARCHAR2,
    p_resp_cde OUT VARCHAR2,
    p_resp_msg OUT VARCHAR2,
    p_resp_msg_m24 OUT VARCHAR2 )
IS
  /*************************************************
       * Created Date     :  10-Dec-2012
       * Created By       :  Srinivasu
       * PURPOSE          :  For preauth reversal
       * Modified By      :  Trivikram
       * Modified Date    :  14-NOV-12
       * Modified Reason  : Modified msgtype 9220 and 9221 with 1220 and 1221
       * Reviewer         : B.Besky Anand
       * Reviewed Date    : 14-NOV-12
       * Build Number     :  CMS3.5.1_RI0021_B0008

       * Modified By      : Pankaj S.
       * Modified Date    : 09-Feb-2013
       * Modified Reason  : Product Category spend limit not being adhered to by VMS
       * Reviewer         : Dhiraj
       * Reviewed Date    :
       * Build Number     :
       
       * Modified By      : Pankaj S.
       * Modified Date    : 15-Mar-2013
       * Modified Reason  : Logging of system initiated card status change(FSS-390)
       * Reviewer         : Dhiraj
       * Reviewed Date    : 
       * Build Number     : CMS3.5.1_RI0024_B0008
       
       * Modified by      :  Pankaj S.
       * Modified Reason  :  10871 
       * Modified Date    :  19-Apr-2013
       * Reviewer         :  Dhiraj
       * Reviewed Date    :  
       * Build Number     : RI0024.1_B0013
       
	    * Modified by      :  Mageshkumar
       * Modified Reason  :  currency code changes 
       * Modified Date    :  19-Jul-2017
       * Reviewer         :  Saravanakumar
       * Reviewed Date    :  19-Jul-2017
       * Build Number     : VMSGPRHOST17.07_B0003
	   
   *************************************************/
   
   v_orgnl_delivery_channel transactionlog.delivery_channel%TYPE;
  v_orgnl_resp_code transactionlog.response_code%TYPE;
  v_orgnl_terminal_id transactionlog.terminal_id%TYPE;
  v_orgnl_txn_code transactionlog.txn_code%TYPE;
  v_orgnl_txn_type transactionlog.txn_type%TYPE;
  v_orgnl_txn_mode transactionlog.txn_mode%TYPE;
  v_orgnl_business_date transactionlog.business_date%TYPE;
  v_orgnl_business_time transactionlog.business_time%TYPE;
  v_orgnl_customer_card_no transactionlog.customer_card_no%TYPE;
  v_orgnl_total_amount transactionlog.amount%TYPE;
  v_actual_amt   NUMBER (9, 2);
  v_reversal_amt NUMBER (9, 2);
  v_orgnl_txn_feecode cms_fee_mast.cfm_fee_code%TYPE;
  v_orgnl_txn_feeattachtype transactionlog.feeattachtype%TYPE;
  v_orgnl_txn_totalfee_amt transactionlog.tranfee_amt%TYPE;
  v_orgnl_txn_servicetax_amt transactionlog.servicetax_amt%TYPE;
  v_orgnl_txn_cess_amt transactionlog.cess_amt%TYPE;
  v_orgnl_transaction_type transactionlog.cr_dr_flag%TYPE;
  v_actual_dispatched_amt transactionlog.amount%TYPE;
  v_resp_cde VARCHAR2 (3);
  v_func_code cms_func_mast.cfm_func_code%TYPE;
  v_dr_cr_flag transactionlog.cr_dr_flag%TYPE;
  v_orgnl_trandate DATE;
  v_rvsl_trandate DATE;
  v_orgnl_termid transactionlog.terminal_id%TYPE;
  v_orgnl_mcccode transactionlog.mccode%TYPE;
  v_errmsg VARCHAR2 (300) := 'OK';
  v_actual_feecode transactionlog.feecode%TYPE;
  v_orgnl_tranfee_amt transactionlog.tranfee_amt%TYPE;
  v_orgnl_servicetax_amt transactionlog.servicetax_amt%TYPE;
  v_orgnl_cess_amt transactionlog.cess_amt%TYPE;
  v_orgnl_cr_dr_flag transactionlog.cr_dr_flag%TYPE;
  v_orgnl_tranfee_cr_acctno transactionlog.tranfee_cr_acctno%TYPE;
  v_orgnl_tranfee_dr_acctno transactionlog.tranfee_dr_acctno%TYPE;
  v_orgnl_st_calc_flag transactionlog.tran_st_calc_flag%TYPE;
  v_orgnl_cess_calc_flag transactionlog.tran_cess_calc_flag%TYPE;
  v_orgnl_st_cr_acctno transactionlog.tran_st_cr_acctno%TYPE;
  v_orgnl_st_dr_acctno transactionlog.tran_st_dr_acctno%TYPE;
  v_orgnl_cess_cr_acctno transactionlog.tran_cess_cr_acctno%TYPE;
  v_orgnl_cess_dr_acctno transactionlog.tran_cess_dr_acctno%TYPE;
  v_prod_code cms_appl_pan.cap_prod_code%TYPE;
  v_card_type cms_appl_pan.cap_card_type%TYPE;
  v_gl_upd_flag transactionlog.gl_upd_flag%TYPE;
  v_tran_reverse_flag transactionlog.tran_reverse_flag%TYPE;
  v_savepoint NUMBER DEFAULT 1;
  v_curr_code transactionlog.currencycode%TYPE;
  v_auth_id transactionlog.auth_id%TYPE;
  v_terminal_indicator pcms_terminal_mast.ptm_terminal_indicator%TYPE;
  v_cutoff_time          VARCHAR2 (5);
  v_business_time        VARCHAR2 (5);
  exp_rvsl_reject_record EXCEPTION;
  v_card_acct_no         VARCHAR2 (20);
  v_tran_sysdate DATE;
  v_tran_cutoff DATE;
  v_hash_pan cms_appl_pan.cap_pan_code%TYPE;
  v_encr_pan cms_appl_pan.cap_pan_code_encr%TYPE;
  v_tran_amt        NUMBER;
  v_delchannel_code VARCHAR2 (2);
  v_card_curr       VARCHAR2 (5);
  v_rrn_count       NUMBER;
  v_base_curr cms_inst_param.cip_param_value%TYPE;
  v_currcode     VARCHAR2 (3);
  v_acct_balance NUMBER;
  v_tran_desc cms_transaction_mast.ctm_tran_desc%TYPE;
  v_atm_usageamnt cms_translimit_check.ctc_atmusage_amt%TYPE;
  v_pos_usageamnt cms_translimit_check.ctc_posusage_amt%TYPE;
  v_atm_usagelimit cms_translimit_check.ctc_atmusage_limit%TYPE;
  v_pos_usagelimit cms_translimit_check.ctc_posusage_limit%TYPE;
  v_business_date_tran DATE;
  v_hold_amount         NUMBER;
  v_upd_hold_amount     NUMBER;
  v_preauth_usage_limit NUMBER;
  v_saf_txn_count       NUMBER;
  v_orgnl_txn_rrn transactionlog.rrn%TYPE;
  v_orgnl_txn_business_date transactionlog.business_date%TYPE;
  v_orgnl_txn_business_time transactionlog.business_time%TYPE;
  v_orgnl_txn_term_id transactionlog.terminal_id%TYPE;
  v_ledger_bal   NUMBER;
  v_max_card_bal NUMBER;
  v_orgnl_txn    VARCHAR2 (20);
  v_orgnl_rrn    VARCHAR2 (25);
  v_mmpos_usageamnt cms_translimit_check.ctc_mmposusage_amt%TYPE;
  v_proxunumber cms_appl_pan.cap_proxy_number%TYPE;
  v_acct_number cms_appl_pan.cap_acct_no%TYPE;
  v_txn_narration cms_statements_log.csl_trans_narrration%TYPE;
  v_fee_narration cms_statements_log.csl_trans_narrration%TYPE;
  v_tot_fee_amount transactionlog.tranfee_amt%TYPE;
  v_tot_amount transactionlog.amount%TYPE;
  v_txn_type NUMBER (1);
  v_tran_preauth_flag cms_transaction_mast.ctm_preauth_flag%TYPE;
  v_fee_merchname cms_statements_log.csl_merchant_name%TYPE;
  v_fee_merchcity cms_statements_log.csl_merchant_city%TYPE;
  v_fee_merchstate cms_statements_log.csl_merchant_state%TYPE;
  v_fee_amt NUMBER;
  v_fee_plan cms_fee_plan.cfp_plan_id%TYPE;
  v_txn_merchname cms_statements_log.csl_merchant_name%TYPE;
  v_txn_merchcity cms_statements_log.csl_merchant_city%TYPE;
  v_txn_merchstate cms_statements_log.csl_merchant_state%TYPE;
  v_narration VARCHAR2 (300);
  v_tran_date DATE;
  v_chnge_crdstat VARCHAR2 (2) := 'N';
  v_cap_card_stat cms_appl_pan.cap_card_stat%TYPE;
  v_acct_type cms_acct_mast.cam_type_code%TYPE;
  
  
  v_timestamp TIMESTAMP ( 3 );
  CURSOR feereverse
  IS
    SELECT csl_trans_narrration,
      csl_merchant_name,
      csl_merchant_city,
      csl_merchant_state,
      csl_trans_amount
    FROM cms_statements_log
    WHERE csl_business_date  = v_orgnl_business_date
    AND csl_business_time    = v_orgnl_business_time
    AND csl_rrn              = p_orgnl_rrn
    AND csl_delivery_channel = v_orgnl_delivery_channel
    AND csl_txn_code         = v_orgnl_txn_code
    AND csl_pan_no           = v_orgnl_customer_card_no
    AND csl_inst_code        = p_inst_code
    AND txn_fee_flag         = 'Y';
BEGIN
  p_resp_cde := '000';
  p_resp_msg := 'OK';
  SAVEPOINT v_savepoint;
  BEGIN
    v_hash_pan := gethash (p_card_no);
  EXCEPTION
  WHEN OTHERS THEN
    v_errmsg := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    v_encr_pan := fn_emaps_main (p_card_no);
  EXCEPTION
  WHEN OTHERS THEN
    v_errmsg := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    SELECT ctm_credit_debit_flag,
      ctm_tran_desc,
      TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
      ctm_preauth_flag
    INTO v_dr_cr_flag,
      v_tran_desc,
      v_txn_type,
      v_tran_preauth_flag
    FROM cms_transaction_mast
    WHERE ctm_tran_code      = p_txn_code
    AND ctm_delivery_channel = p_delv_chnl
    AND ctm_inst_code        = p_inst_code;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_resp_cde := '21';
    v_errmsg   := 'Transaction detail is not found in master for orginal txn code' || p_txn_code || 'delivery channel ' || p_delv_chnl;
    RAISE exp_rvsl_reject_record;
  WHEN OTHERS THEN
    v_resp_cde := '21';
    v_errmsg   := 'Problem while selecting debit/credit flag ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    v_orgnl_trandate := TO_DATE (SUBSTR (TRIM (p_orgnl_business_date), 1, 8), 'yyyymmdd');
    v_rvsl_trandate  := TO_DATE (SUBSTR (TRIM (p_business_date), 1, 8), 'yyyymmdd');
  EXCEPTION
  WHEN OTHERS THEN
    v_resp_cde := '45';
    v_errmsg   := 'Problem while converting transaction date ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0') INTO 
    v_auth_id FROM DUAL;
  EXCEPTION
  WHEN OTHERS THEN
    v_errmsg   := 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
    v_resp_cde := '21';
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    v_orgnl_trandate := TO_DATE ( SUBSTR (TRIM (p_orgnl_business_date), 1, 8) || ' ' || SUBSTR (TRIM (p_orgnl_business_time), 1, 8), 'yyyymmdd hh24:mi:ss' );
    v_rvsl_trandate  := TO_DATE ( SUBSTR (TRIM (p_business_date), 1, 8) || ' ' || SUBSTR (TRIM (p_business_time), 1, 8), 'yyyymmdd hh24:mi:ss' );
    v_tran_date      := v_rvsl_trandate;
  EXCEPTION
  WHEN OTHERS THEN
    v_resp_cde := '32';
    v_errmsg   := 'Problem while converting transaction Time ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    SELECT COUNT (1)
    INTO v_rrn_count
    FROM transactionlog
    WHERE terminal_id    = p_terminal_id
    AND rrn              = p_rrn
    AND business_date    = p_business_date
    AND delivery_channel = p_delv_chnl;
    IF v_rrn_count       > 0 THEN
      v_resp_cde        := '22';
      v_errmsg          := 'Duplicate RRN from the Treminal' || p_terminal_id || 'on' || p_business_date;
      RAISE exp_rvsl_reject_record;
    END IF;
  END;
  
       

    

  
  
  
  
  BEGIN
    SELECT cdm_channel_code
    INTO v_delchannel_code
    FROM cms_delchannel_mast
    WHERE cdm_channel_desc = 'MMPOS'
    AND cdm_inst_code      = p_inst_code;
    IF p_curr_code        IS NULL AND v_delchannel_code = p_delv_chnl THEN
      BEGIN
        SELECT cip_param_value

	     INTO v_base_curr 
        FROM cms_inst_param
        WHERE cip_inst_code    = p_inst_code
        AND cip_param_key      = 'CURRENCY';

        IF TRIM (v_base_curr) IS NULL THEN
          v_errmsg            := 'Base currency cannot be null ';
          RAISE exp_rvsl_reject_record;
        END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errmsg := 'Base currency is not defined for the institution ';
        RAISE exp_rvsl_reject_record;
      WHEN OTHERS THEN
        v_errmsg := 'Error while selecting bese currecy  ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_rvsl_reject_record;
      END;
      v_currcode := v_base_curr;
    ELSE
      v_currcode := p_curr_code;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    v_errmsg := 'Error while CMS_DELCHANNEL_MAST  ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  IF v_delchannel_code <> p_delv_chnl THEN
    IF (p_msg_typ NOT  IN ('0400', '0410', '1420', '0430', '1220', '1221') ) OR (p_rvsl_code = '00') THEN
      v_resp_cde       := '12';
      v_errmsg         := 'Not a valid reversal request';
      RAISE exp_rvsl_reject_record;
    END IF;
  END IF;
  BEGIN
    SELECT delivery_channel,
      terminal_id,
      response_code,
      txn_code,
      txn_type,
      txn_mode,
      business_date,
      business_time,
      customer_card_no,
      amount,
      feecode,
      feeattachtype,
      tranfee_amt,
      servicetax_amt,
      cess_amt,
      cr_dr_flag,
      terminal_id,
      mccode,
      feecode,
      tranfee_amt,
      servicetax_amt,
      cess_amt,
      tranfee_cr_acctno,
      tranfee_dr_acctno,
      tran_st_calc_flag,
      tran_cess_calc_flag,
      tran_st_cr_acctno,
      tran_st_dr_acctno,
      tran_cess_cr_acctno,
      tran_cess_dr_acctno,
      currencycode,
      tran_reverse_flag,
      gl_upd_flag
    INTO v_orgnl_delivery_channel,
      v_orgnl_terminal_id,
      v_orgnl_resp_code,
      v_orgnl_txn_code,
      v_orgnl_txn_type,
      v_orgnl_txn_mode,
      v_orgnl_business_date,
      v_orgnl_business_time,
      v_orgnl_customer_card_no,
      v_orgnl_total_amount,
      v_orgnl_txn_feecode,
      v_orgnl_txn_feeattachtype,
      v_orgnl_txn_totalfee_amt,
      v_orgnl_txn_servicetax_amt,
      v_orgnl_txn_cess_amt,
      v_orgnl_transaction_type,
      v_orgnl_termid,
      v_orgnl_mcccode,
      v_actual_feecode,
      v_orgnl_tranfee_amt,
      v_orgnl_servicetax_amt,
      v_orgnl_cess_amt,
      v_orgnl_tranfee_cr_acctno,
      v_orgnl_tranfee_dr_acctno,
      v_orgnl_st_calc_flag,
      v_orgnl_cess_calc_flag,
      v_orgnl_st_cr_acctno,
      v_orgnl_st_dr_acctno,
      v_orgnl_cess_cr_acctno,
      v_orgnl_cess_dr_acctno,
      v_curr_code,
      v_tran_reverse_flag,
      v_gl_upd_flag
    FROM transactionlog
    WHERE rrn             = p_orgnl_rrn
    AND business_date     = p_orgnl_business_date
    AND business_time     = p_orgnl_business_time
    AND customer_card_no  = v_hash_pan
    AND instcode          = p_inst_code
    AND delivery_channel  = p_delv_chnl;
    IF v_orgnl_resp_code <> '000' THEN
      IF p_msg_typ NOT   IN ('1220', '1221') THEN
        v_resp_cde       := '23';
        v_errmsg         := ' The original transaction was not successful';
        RAISE exp_rvsl_reject_record;
      END IF;
    END IF;
    IF v_tran_reverse_flag = 'Y' THEN
      v_resp_cde          := '52';
      v_errmsg            := 'The reversal already done for the orginal transaction';
      RAISE exp_rvsl_reject_record;
    END IF;
  EXCEPTION
  WHEN exp_rvsl_reject_record THEN
    RAISE;
  WHEN NO_DATA_FOUND THEN
    v_orgnl_txn      := 'NO ORGNL TXN';
    IF p_msg_typ NOT IN ('1220', '1221') THEN
      v_resp_cde     := '53';
      v_errmsg       := 'Matching transaction not found';
      RAISE exp_rvsl_reject_record;
    END IF;
  WHEN TOO_MANY_ROWS THEN
    IF p_msg_typ IN ('1220', '1221') THEN
      BEGIN
        SELECT SUM (tranfee_amt),
          SUM (amount)
        INTO v_tot_fee_amount,
          v_tot_amount
        FROM transactionlog
        WHERE rrn            = p_orgnl_rrn
        AND business_date    = p_orgnl_business_date
        AND business_time    = p_orgnl_business_time
        AND customer_card_no = v_hash_pan
        AND instcode         = p_inst_code
        AND response_code    = '000';
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_cde := '21';
        v_errmsg   := 'Error while selecting TRANSACTIONLOG ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_rvsl_reject_record;
      END;
      IF (v_tot_fee_amount  IS NULL) AND (v_tot_amount IS NULL) THEN
        v_orgnl_txn         := 'NO ORGNL TXN';
      ELSIF v_tot_fee_amount > 0 THEN
        BEGIN
          SELECT delivery_channel,
            terminal_id,
            response_code,
            txn_code,
            txn_type,
            txn_mode,
            business_date,
            business_time,
            customer_card_no,
            amount,
            feecode,
            feeattachtype,
            tranfee_amt,
            servicetax_amt,
            cess_amt,
            cr_dr_flag,
            terminal_id,
            mccode,
            feecode,
            tranfee_amt,
            servicetax_amt,
            cess_amt,
            tranfee_cr_acctno,
            tranfee_dr_acctno,
            tran_st_calc_flag,
            tran_cess_calc_flag,
            tran_st_cr_acctno,
            tran_st_dr_acctno,
            tran_cess_cr_acctno,
            tran_cess_dr_acctno,
            currencycode,
            tran_reverse_flag,
            gl_upd_flag
          INTO v_orgnl_delivery_channel,
            v_orgnl_terminal_id,
            v_orgnl_resp_code,
            v_orgnl_txn_code,
            v_orgnl_txn_type,
            v_orgnl_txn_mode,
            v_orgnl_business_date,
            v_orgnl_business_time,
            v_orgnl_customer_card_no,
            v_orgnl_total_amount,
            v_orgnl_txn_feecode,
            v_orgnl_txn_feeattachtype,
            v_orgnl_txn_totalfee_amt,
            v_orgnl_txn_servicetax_amt,
            v_orgnl_txn_cess_amt,
            v_orgnl_transaction_type,
            v_orgnl_termid,
            v_orgnl_mcccode,
            v_actual_feecode,
            v_orgnl_tranfee_amt,
            v_orgnl_servicetax_amt,
            v_orgnl_cess_amt,
            v_orgnl_tranfee_cr_acctno,
            v_orgnl_tranfee_dr_acctno,
            v_orgnl_st_calc_flag,
            v_orgnl_cess_calc_flag,
            v_orgnl_st_cr_acctno,
            v_orgnl_st_dr_acctno,
            v_orgnl_cess_cr_acctno,
            v_orgnl_cess_dr_acctno,
            v_curr_code,
            v_tran_reverse_flag,
            v_gl_upd_flag
          FROM transactionlog
          WHERE rrn                 = p_orgnl_rrn
          AND business_date         = p_orgnl_business_date
          AND business_time         = p_orgnl_business_time
          AND customer_card_no      = v_hash_pan
          AND instcode              = p_inst_code
          AND response_code         = '000'
          AND delivery_channel      = p_delv_chnl
          AND tranfee_cr_acctno    IS NOT NULL
          AND ROWNUM                = 1;
          v_orgnl_total_amount     := v_tot_amount;
          v_orgnl_txn_totalfee_amt := v_tot_fee_amount;
          v_orgnl_tranfee_amt      := v_tot_fee_amount;
        EXCEPTION
        WHEN OTHERS THEN
          v_resp_cde := '21';
          v_errmsg   := 'Error while selecting TRANSACTIONLOG1 ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
        END;
        IF v_tran_reverse_flag = 'Y' THEN
          v_resp_cde          := '52';
          v_errmsg            := 'The reversal already done for the orginal transaction';
          RAISE exp_rvsl_reject_record;
        END IF;
      ELSE
        BEGIN
          SELECT delivery_channel,
            terminal_id,
            response_code,
            txn_code,
            txn_type,
            txn_mode,
            business_date,
            business_time,
            customer_card_no,
            amount,
            feecode,
            feeattachtype,
            tranfee_amt,
            servicetax_amt,
            cess_amt,
            cr_dr_flag,
            terminal_id,
            mccode,
            feecode,
            tranfee_amt,
            servicetax_amt,
            cess_amt,
            tranfee_cr_acctno,
            tranfee_dr_acctno,
            tran_st_calc_flag,
            tran_cess_calc_flag,
            tran_st_cr_acctno,
            tran_st_dr_acctno,
            tran_cess_cr_acctno,
            tran_cess_dr_acctno,
            currencycode,
            tran_reverse_flag,
            gl_upd_flag
          INTO v_orgnl_delivery_channel,
            v_orgnl_terminal_id,
            v_orgnl_resp_code,
            v_orgnl_txn_code,
            v_orgnl_txn_type,
            v_orgnl_txn_mode,
            v_orgnl_business_date,
            v_orgnl_business_time,
            v_orgnl_customer_card_no,
            v_orgnl_total_amount,
            v_orgnl_txn_feecode,
            v_orgnl_txn_feeattachtype,
            v_orgnl_txn_totalfee_amt,
            v_orgnl_txn_servicetax_amt,
            v_orgnl_txn_cess_amt,
            v_orgnl_transaction_type,
            v_orgnl_termid,
            v_orgnl_mcccode,
            v_actual_feecode,
            v_orgnl_tranfee_amt,
            v_orgnl_servicetax_amt,
            v_orgnl_cess_amt,
            v_orgnl_tranfee_cr_acctno,
            v_orgnl_tranfee_dr_acctno,
            v_orgnl_st_calc_flag,
            v_orgnl_cess_calc_flag,
            v_orgnl_st_cr_acctno,
            v_orgnl_st_dr_acctno,
            v_orgnl_cess_cr_acctno,
            v_orgnl_cess_dr_acctno,
            v_curr_code,
            v_tran_reverse_flag,
            v_gl_upd_flag
          FROM transactionlog
          WHERE rrn                 = p_orgnl_rrn
          AND business_date         = p_orgnl_business_date
          AND business_time         = p_orgnl_business_time
          AND customer_card_no      = v_hash_pan
          AND instcode              = p_inst_code
          AND response_code         = '000'
          AND delivery_channel      = p_delv_chnl
          AND ROWNUM                = 1;
          v_orgnl_total_amount     := v_tot_amount;
          v_orgnl_txn_totalfee_amt := v_tot_fee_amount;
          v_orgnl_tranfee_amt      := v_tot_fee_amount;
        EXCEPTION
        WHEN OTHERS THEN
          v_resp_cde := '21';
          v_errmsg   := 'Error while selecting TRANSACTIONLOG2 ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
        END;
        IF v_tran_reverse_flag = 'Y' THEN
          v_resp_cde          := '52';
          v_errmsg            := 'The reversal already done for the orginal transaction';
          RAISE exp_rvsl_reject_record;
        END IF;
      END IF;
    END IF;
  WHEN OTHERS THEN
    v_orgnl_txn      := 'NO ORGNL TXN';
    IF p_msg_typ NOT IN ('1220', '1221') THEN
      v_resp_cde     := '21';
      v_errmsg       := 'Error while selecting master data' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_rvsl_reject_record;
    END IF;
  END;
  IF p_msg_typ = '1221' THEN
    SELECT COUNT (*)
    INTO v_saf_txn_count
    FROM transactionlog
    WHERE rrn            = p_rrn
    AND business_date    = p_business_date
    AND customer_card_no = v_hash_pan
    AND instcode         = p_inst_code
    AND response_code    = '000'
    AND msgtype          = '1220';
    IF v_saf_txn_count   > 0 THEN
      v_resp_cde        := '38';
      v_errmsg          := 'Successful SAF Transaction has already done' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_rvsl_reject_record;
    END IF;
  END IF;
  BEGIN
    SELECT cap_prod_code,
      cap_card_type,
      cap_proxy_number,
      cap_acct_no,
      cap_card_stat
    INTO v_prod_code,
      v_card_type,
      v_proxunumber,
      v_acct_number,
      v_cap_card_stat
    FROM cms_appl_pan
    WHERE cap_inst_code = p_inst_code
    AND cap_pan_code    = v_hash_pan;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_resp_cde := '21';
    v_errmsg   := p_card_no || ' Card no not in master';
    RAISE exp_rvsl_reject_record;
  WHEN OTHERS THEN
    v_resp_cde := '21';
    v_errmsg   := 'Error while retriving card detail ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  v_tran_amt       := p_actual_amt;
  IF (p_actual_amt >= 0) THEN
    BEGIN
      sp_convert_curr (p_inst_code, v_currcode, p_card_no, p_actual_amt, v_rvsl_trandate, v_tran_amt, v_card_curr, v_errmsg, v_prod_code, v_card_type );
      IF v_errmsg  <> 'OK' THEN
        v_resp_cde := '44';
        RAISE exp_rvsl_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_rvsl_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '44';
      v_errmsg   := 'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_rvsl_reject_record;
    END;
  ELSE
    v_resp_cde := '13';
    v_errmsg   := 'INVALID AMOUNT';
    RAISE exp_rvsl_reject_record;
  END IF;
  BEGIN
    SELECT cpt_totalhold_amt
    INTO v_hold_amount
    FROM cms_preauth_transaction
    WHERE cpt_rrn     = p_orgnl_rrn
    AND cpt_txn_date  = p_orgnl_business_date
    AND cpt_inst_code = p_inst_code;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    BEGIN
      SELECT cpt_totalhold_amt
      INTO v_hold_amount
      FROM cms_preauth_transaction
      WHERE cpt_rrn     = p_orgnl_rrn
      AND cpt_inst_code = p_inst_code
      AND cpt_card_no   = v_hash_pan;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_hold_amount := -1;
      v_orgnl_txn   := 'NO ORGNL TXN';
    WHEN OTHERS THEN
      v_hold_amount := -1;
      v_orgnl_txn   := 'NO ORGNL TXN';
    END;
  END;
  BEGIN
    IF (v_tran_amt            IS NULL OR v_tran_amt = 0) THEN
      v_actual_dispatched_amt := 0;
    ELSE
      v_actual_dispatched_amt := v_tran_amt;
    END IF;
    IF (v_hold_amount   IS NULL OR v_hold_amount = 0) THEN
      v_reversal_amt    := 0;
    ELSIF (v_hold_amount = -1) THEN
      v_reversal_amt    := v_actual_dispatched_amt;
    ELSE
      v_reversal_amt   := v_hold_amount - v_actual_dispatched_amt;
      IF v_reversal_amt < 0 THEN
        v_reversal_amt := v_hold_amount;
      END IF;
    END IF;
  END;
  BEGIN
    SELECT cam_acct_bal,
      cam_ledger_bal,
      cam_acct_no,
      cam_type_code
    INTO v_acct_balance,
      v_ledger_bal,
      v_card_acct_no,
      v_acct_type
    FROM cms_acct_mast
    WHERE cam_acct_no = v_acct_number
      /*  (SELECT cap_acct_no
      FROM cms_appl_pan
      WHERE cap_pan_code = v_hash_pan
      AND cap_mbr_numb = p_mbr_numb
      AND cap_inst_code = p_inst_code)*/
    AND cam_inst_code = p_inst_code FOR UPDATE NOWAIT;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_resp_cde := '14';
    v_errmsg   := 'Invalid Card ';
    RAISE exp_rvsl_reject_record;
  WHEN OTHERS THEN
    v_resp_cde := '21';
    v_errmsg   := 'Error while selecting data from card Master for card number ' || SQLERRM;
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    SELECT TO_NUMBER (cbp_param_value)
    INTO v_max_card_bal
    FROM cms_bin_param
    WHERE cbp_inst_code   = p_inst_code
    AND cbp_param_name    = 'Max Card Balance'
    AND cbp_profile_code IN
      (SELECT cpc_profile_code
      FROM cms_prod_cattype
      WHERE cpc_inst_code = p_inst_code
      AND cpc_prod_code   = v_prod_code
      AND cpc_card_type   = v_card_type
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_resp_cde := '21';
    v_errmsg   := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  IF v_orgnl_txn  = 'NO ORGNL TXN' THEN
    v_ledger_bal := v_ledger_bal + v_reversal_amt;
  END IF;
  IF ((v_acct_balance + v_reversal_amt) > v_max_card_bal) OR (v_ledger_bal > v_max_card_bal) THEN
    BEGIN
      IF v_cap_card_stat <> '12' THEN
        UPDATE cms_appl_pan
        SET cap_card_stat  = '12'
        WHERE cap_pan_code = v_hash_pan
        AND cap_inst_code  = p_inst_code;
        IF SQL%ROWCOUNT    = 0 THEN
          v_errmsg        := 'Error while updating the card status';
          v_resp_cde      := '21';
          RAISE exp_rvsl_reject_record;
        END IF;
        v_chnge_crdstat := 'Y';
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_errmsg   := 'Error while updating cms_appl_pan ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_rvsl_reject_record;
    END;
  END IF;
  IF v_tran_preauth_flag != 'Y' THEN
    IF v_dr_cr_flag       = 'NA' THEN
      v_resp_cde         := '21';
      v_errmsg           := 'Not a valid orginal transaction for reversal';
      RAISE exp_rvsl_reject_record;
    END IF;
  END IF;
  IF v_dr_cr_flag <> v_orgnl_transaction_type THEN
    v_resp_cde    := '21';
    v_errmsg      := 'Orginal transaction type is not matching with actual transaction type';
    RAISE exp_rvsl_reject_record;
  END IF;
  BEGIN
    SELECT cfm_func_code
    INTO v_func_code
    FROM cms_func_mast
    WHERE cfm_txn_code       = p_txn_code
    AND cfm_txn_mode         = p_txn_mode
    AND cfm_delivery_channel = p_delv_chnl
    AND cfm_inst_code        = p_inst_code;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_resp_cde := '69';
    v_errmsg   := 'Function code not defined for txn code ' || p_txn_code;
    RAISE exp_rvsl_reject_record;
  WHEN TOO_MANY_ROWS THEN
    v_resp_cde := '69';
    v_errmsg   := 'More than one function defined for txn code ' || p_txn_code;
    RAISE exp_rvsl_reject_record;
  WHEN OTHERS THEN
    v_resp_cde := '69';
    v_errmsg   := 'Problem while selecting function code from function mast  ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    SELECT cip_param_value
    INTO v_cutoff_time
    FROM cms_inst_param
    WHERE cip_param_key = 'CUTOFF'
    AND cip_inst_code   = p_inst_code;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_cutoff_time := 0;
    v_resp_cde    := '21';
    v_errmsg      := 'Cutoff time is not defined in the system';
    RAISE exp_rvsl_reject_record;
  WHEN OTHERS THEN
    v_resp_cde := '21';
    v_errmsg   := 'Error while selecting cutoff  dtl  from system ';
    RAISE exp_rvsl_reject_record;
  END;
  v_timestamp := SYSTIMESTAMP;
  BEGIN
    IF v_orgnl_txn = 'NO ORGNL TXN' THEN
      v_orgnl_rrn := 'N:' || p_orgnl_rrn;
    ELSE
      v_orgnl_rrn := 'Y:' || p_orgnl_rrn;
    END IF;
    sp_reverse_card_amount (p_inst_code, v_func_code, p_rrn, p_delv_chnl, p_orgnl_terminal_id, p_merc_id, p_txn_code, v_rvsl_trandate, p_txn_mode, p_card_no, v_reversal_amt, v_orgnl_rrn, v_card_acct_no, p_business_date, p_business_time, v_auth_id, v_txn_narration, p_orgnl_business_date, p_orgnl_business_time, NULL, NULL, NULL, v_resp_cde, v_errmsg );
    IF v_resp_cde <> '00' OR v_errmsg <> 'OK' THEN
      RAISE exp_rvsl_reject_record;
    END IF;
  EXCEPTION
  WHEN exp_rvsl_reject_record THEN
    RAISE;
  WHEN OTHERS THEN
    v_resp_cde := '21';
    v_errmsg   := 'Error while reversing the amount ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  IF v_orgnl_txn_totalfee_amt > 0 THEN
    BEGIN
      FOR c1 IN feereverse
      LOOP
        BEGIN
          sp_reverse_fee_amount (p_inst_code, p_rrn, p_delv_chnl, p_orgnl_terminal_id, p_merc_id, p_txn_code, v_rvsl_trandate, p_txn_mode, c1.csl_trans_amount, p_card_no, v_actual_feecode, c1.csl_trans_amount, v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno, v_orgnl_st_calc_flag, v_orgnl_servicetax_amt, v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno, v_orgnl_cess_calc_flag, v_orgnl_cess_amt, v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno, p_orgnl_rrn, v_card_acct_no, p_business_date, p_business_time, v_auth_id, c1.csl_trans_narrration, c1.csl_merchant_name, c1.csl_merchant_city, c1.csl_merchant_state, v_resp_cde, v_errmsg );
          v_fee_narration := c1.csl_trans_narrration;
          IF v_resp_cde   <> '00' OR v_errmsg <> 'OK' THEN
            RAISE exp_rvsl_reject_record;
          END IF;
        EXCEPTION
        WHEN exp_rvsl_reject_record THEN
          RAISE;
        WHEN OTHERS THEN
          v_resp_cde := '21';
          v_errmsg   := 'Error while reversing the fee amount ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
        END;
      END LOOP;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_fee_narration := NULL;
    WHEN OTHERS THEN
      v_fee_narration := NULL;
    END;
  END IF;
  IF v_fee_narration IS NULL THEN
    BEGIN
      sp_reverse_fee_amount (p_inst_code, p_rrn, p_delv_chnl, p_orgnl_terminal_id, p_merc_id, p_txn_code, v_rvsl_trandate, p_txn_mode, v_orgnl_txn_totalfee_amt, p_card_no, v_actual_feecode, v_orgnl_tranfee_amt, v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno, v_orgnl_st_calc_flag, v_orgnl_servicetax_amt, v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno, v_orgnl_cess_calc_flag, v_orgnl_cess_amt, v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno, p_orgnl_rrn, v_card_acct_no, p_business_date, p_business_time, v_auth_id, v_fee_narration, v_fee_merchname, v_fee_merchcity, v_fee_merchstate, v_resp_cde, v_errmsg );
      IF v_resp_cde <> '00' OR v_errmsg <> 'OK' THEN
        RAISE exp_rvsl_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_rvsl_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_errmsg   := 'Error while reversing the fee amount ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_rvsl_reject_record;
    END;
  END IF;
  IF v_gl_upd_flag     = 'Y' THEN
    v_business_time   := TO_CHAR (v_rvsl_trandate, 'HH24:MI');
    IF v_business_time > v_cutoff_time THEN
      v_rvsl_trandate := TRUNC (v_rvsl_trandate) + 1;
    ELSE
      v_rvsl_trandate := TRUNC (v_rvsl_trandate);
    END IF;
    sp_reverse_gl_entries (p_inst_code, v_rvsl_trandate, v_prod_code, v_card_type, v_reversal_amt, v_func_code, p_txn_code, v_dr_cr_flag, p_card_no, v_actual_feecode, v_orgnl_txn_totalfee_amt, v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno, v_card_acct_no, p_rvsl_code, p_msg_typ, p_delv_chnl, v_resp_cde, v_gl_upd_flag, v_errmsg );
    IF v_gl_upd_flag <> 'Y' THEN
      v_resp_cde     := '21';
      v_errmsg       := v_errmsg || 'Error while retriving gl detail ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_rvsl_reject_record;
    END IF;
  END IF;
  IF v_chnge_crdstat = 'Y' THEN
    BEGIN
      sp_log_cardstat_chnge (p_inst_code, v_hash_pan, v_encr_pan, v_auth_id, '03', p_rrn, p_business_date, p_business_time, v_resp_cde, v_errmsg );
      IF v_resp_cde <> '00' AND v_errmsg <> 'OK' THEN
        RAISE exp_rvsl_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_rvsl_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_errmsg   := 'Error while logging system initiated card status change ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_rvsl_reject_record;
    END;
  END IF;
  BEGIN
    IF v_errmsg = 'OK' THEN
      INSERT
      INTO cms_transaction_log_dtl
        (
          ctd_delivery_channel,
          ctd_txn_code,
          ctd_txn_type,
          ctd_msg_type,
          ctd_txn_mode,
          ctd_business_date,
          ctd_business_time,
          ctd_customer_card_no,
          ctd_txn_amount,
          ctd_txn_curr,
          ctd_actual_amount,
          ctd_bill_amount,
          ctd_bill_curr,
          ctd_process_flag,
          ctd_process_msg,
          ctd_rrn,
          ctd_system_trace_audit_no,
          ctd_inst_code,
          ctd_customer_card_no_encr,
          ctd_cust_acct_number
        )
        VALUES
        (
          p_delv_chnl,
          p_txn_code,
          v_txn_type,
          p_msg_typ,
          p_txn_mode,
          p_business_date,
          p_business_time,
          v_hash_pan,
          p_actual_amt,
          v_currcode,
          v_tran_amt,
          v_reversal_amt,
          v_card_curr,
          'Y',
          'Successful',
          p_rrn,
          p_stan,
          p_inst_code,
          v_encr_pan,
          v_acct_number
        );
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    v_errmsg   := 'Problem while selecting data from response master ' || SUBSTR (SQLERRM, 1, 300);
    v_resp_cde := '21';
    RAISE exp_rvsl_reject_record;
  END;
  v_resp_cde := '1';
  BEGIN
    SELECT cpt_totalhold_amt
    INTO v_hold_amount
    FROM cms_preauth_transaction
    WHERE cpt_rrn         = p_orgnl_rrn
    AND cpt_txn_date      = p_orgnl_business_date
    AND cpt_inst_code     = p_inst_code;
    v_upd_hold_amount    := v_hold_amount - v_reversal_amt;
    IF v_upd_hold_amount <= 0 THEN
      v_upd_hold_amount  := 0;
      UPDATE cms_preauth_transaction
      SET cpt_totalhold_amt   = TRIM (TO_CHAR (v_upd_hold_amount, '999999999999999990.99')),
        cpt_preauth_validflag = 'N',
        cpt_transaction_flag  = 'R'
      WHERE cpt_rrn           = p_orgnl_rrn
      AND cpt_txn_date        = p_orgnl_business_date
      AND cpt_inst_code       = p_inst_code;
    ELSE
      UPDATE cms_preauth_transaction
      SET cpt_totalhold_amt  = TRIM (TO_CHAR (v_upd_hold_amount, '999999999999999990.99')),
        cpt_transaction_flag = 'R'
      WHERE cpt_rrn          = p_orgnl_rrn
      AND cpt_txn_date       = p_orgnl_business_date
      AND cpt_inst_code      = p_inst_code;
    END IF;
    IF SQL%ROWCOUNT = 0 THEN
      v_errmsg     := 'Error while updating the CMS_PREAUTH_TRANSACTION table';
      v_resp_cde   := '21';
      RAISE exp_rvsl_reject_record;
    END IF;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    BEGIN
      SELECT cpt_totalhold_amt
      INTO v_hold_amount
      FROM cms_preauth_transaction
      WHERE cpt_rrn         = p_orgnl_rrn
      AND cpt_inst_code     = p_inst_code
      AND cpt_card_no       = v_hash_pan;
      v_upd_hold_amount    := v_hold_amount - v_reversal_amt;
      IF v_upd_hold_amount <= 0 THEN
        v_upd_hold_amount  := 0;
        UPDATE cms_preauth_transaction
        SET cpt_totalhold_amt   = TRIM (TO_CHAR (v_upd_hold_amount, '999999999999999990.99' ) ),
          cpt_preauth_validflag = 'N',
          cpt_transaction_flag  = 'R'
        WHERE cpt_rrn           = p_orgnl_rrn
        AND cpt_inst_code       = p_inst_code
        AND cpt_card_no         = v_hash_pan;
      ELSE
        UPDATE cms_preauth_transaction
        SET cpt_totalhold_amt  = TRIM (TO_CHAR (v_upd_hold_amount, '999999999999999990.99' ) ),
          cpt_transaction_flag = 'R'
        WHERE cpt_rrn          = p_orgnl_rrn
        AND cpt_inst_code      = p_inst_code
        AND cpt_card_no        = v_hash_pan;
      END IF;
      IF SQL%ROWCOUNT = 0 THEN
        v_errmsg     := 'Error while updating the CMS_PREAUTH_TRANSACTION table';
        v_resp_cde   := '21';
        RAISE exp_rvsl_reject_record;
      END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_upd_hold_amount := 0;
    WHEN OTHERS THEN
      v_upd_hold_amount := 0;
    END;
  WHEN OTHERS THEN
    v_upd_hold_amount := 0;
  END;
  BEGIN
    SELECT cph_merchant_name,
      cph_merchant_city,
      cph_merchant_state
    INTO v_txn_merchname,
      v_txn_merchcity,
      v_txn_merchstate
    FROM cms_preauth_trans_hist
    WHERE cph_rrn             = p_orgnl_rrn
    AND cph_card_no           = v_hash_pan
    AND cph_mbr_no            = p_mbr_numb
    AND cph_txn_date          = p_orgnl_business_date
    AND cph_inst_code         = p_inst_code
    AND cph_transaction_flag IN ('N', 'I')
    AND ROWNUM                = 1;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    NULL;
  END;
  IF TRIM (v_tran_desc) IS NOT NULL THEN
    v_narration         := v_tran_desc || '/';
  END IF;
  IF TRIM (p_merchant_name) IS NOT NULL THEN
    v_narration             := v_narration || p_merchant_name || '/';
  END IF;
  IF TRIM (p_merchant_city) IS NOT NULL THEN
    v_narration             := v_narration || p_merchant_city || '/';
  END IF;
  IF TRIM (p_business_date) IS NOT NULL THEN
    v_narration             := v_narration || p_business_date || '/';
  END IF;
  IF TRIM (v_auth_id) IS NOT NULL THEN
    v_narration       := v_narration || v_auth_id;
  END IF;
  BEGIN
    sp_tran_reversal_fees (p_inst_code, p_card_no, p_delv_chnl, v_orgnl_txn_mode, p_txn_code, p_curr_code, NULL, NULL, v_reversal_amt, p_business_date, p_business_time, NULL, NULL, v_resp_cde, p_msg_typ, p_mbr_numb, p_rrn, p_terminal_id, v_txn_merchname, v_txn_merchcity, v_auth_id, v_fee_merchstate, p_rvsl_code, v_txn_narration, v_orgnl_txn_type, v_rvsl_trandate, v_errmsg, v_resp_cde, v_fee_amt, v_fee_plan );
    IF v_errmsg <> 'OK' THEN
      RAISE exp_rvsl_reject_record;
    END IF;
  END;
  BEGIN
    SELECT cms_b24_respcde
    INTO p_resp_cde
    FROM cms_response_mast
    WHERE cms_inst_code      = p_inst_code
    AND cms_delivery_channel = p_delv_chnl
    AND cms_response_id      = TO_NUMBER (v_resp_cde);
  EXCEPTION
  WHEN OTHERS THEN
    v_errmsg   := 'Problem while selecting data from response master for respose code' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
    v_resp_cde := '69';
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    UPDATE cms_statements_log
    SET csl_prod_code        = v_prod_code,
      csl_card_type          =v_card_type,
      csl_acct_type          = v_acct_type,
      csl_time_stamp         = v_timestamp
    WHERE csl_inst_code      = p_inst_code
    AND csl_pan_no           = v_hash_pan
    AND csl_rrn              = p_rrn
    AND csl_txn_code         = p_txn_code
    AND csl_delivery_channel = p_delv_chnl
    AND csl_business_date    = p_business_date
    AND csl_business_time    = p_business_time;
    IF SQL%ROWCOUNT          = 0 THEN
      NULL;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    v_resp_cde := '21';
    v_errmsg   := 'Error while updating timestamp in statementlog-' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    INSERT
    INTO transactionlog
      (
        msgtype,
        rrn,
        delivery_channel,
        terminal_id,
        date_time,
        txn_code,
        txn_type,
        txn_mode,
        txn_status,
        response_code,
        business_date,
        business_time,
        customer_card_no,
        topup_card_no,
        topup_acct_no,
        topup_acct_type,
        bank_code,
        total_amount,
        rule_indicator,
        rulegroupid,
        mccode,
        currencycode,
        productid,
        categoryid,
        tranfee_amt,
        tips,
        decline_ruleid,
        atm_name_location,
        auth_id,
        trans_desc,
        amount,
        preauthamount,
        partialamount,
        mccodegroupid,
        currencycodegroupid,
        transcodegroupid,
        rules,
        preauth_date,
        gl_upd_flag,
        system_trace_audit_no,
        instcode,
        feecode,
        feeattachtype,
        tran_reverse_flag,
        customer_card_no_encr,
        topup_card_no_encr,
        orgnl_card_no,
        orgnl_rrn,
        orgnl_business_date,
        orgnl_business_time,
        orgnl_terminal_id,
        proxy_number,
        reversal_code,
        customer_acct_no,
        acct_balance,
        ledger_balance,
        response_id,
        fee_plan,
        merchant_name,
        merchant_city,
        merchant_state,
        cardstatus,
        cr_dr_flag,
        acct_type,
        error_msg,
        time_stamp
      )
      VALUES
      (
        p_msg_typ,
        p_rrn,
        p_delv_chnl,
        p_terminal_id,
        v_rvsl_trandate,
        p_txn_code,
        v_txn_type,
        p_txn_mode,
        DECODE (p_resp_cde, '00', 'C', 'F'),
        p_resp_cde,
        p_business_date,
        SUBSTR (p_business_time, 1, 6),
        v_hash_pan,
        NULL,
        NULL,
        NULL,
        p_inst_code,
        TRIM (TO_CHAR (v_reversal_amt, '999999999999999990.99')),
        NULL,
        NULL,
        p_merc_id,
        v_curr_code,
        v_prod_code,
        v_card_type,
        v_fee_amt,
        '0.00',
        NULL,
        NULL,
        v_auth_id,
        v_tran_desc,
        TRIM (TO_CHAR (v_reversal_amt, '999999999999999990.99')),
        '0.00',
        '0.00',
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'Y',
        p_stan,
        p_inst_code,
        NULL,
        NULL,
        'N',
        v_encr_pan,
        NULL,
        v_encr_pan,
        p_orgnl_rrn,
        p_orgnl_business_date,
        p_orgnl_business_time,
        p_orgnl_terminal_id,
        v_proxunumber,
        p_rvsl_code,
        v_acct_number,
        v_acct_balance,
        v_ledger_bal,
        v_resp_cde,
        v_fee_plan,
        v_txn_merchname,
        v_txn_merchcity,
        v_txn_merchstate,
        v_cap_card_stat,
        v_dr_cr_flag,
        v_acct_type,
        v_errmsg,
        v_timestamp
      );
    BEGIN
      UPDATE transactionlog
      SET tran_reverse_flag = 'Y'
      WHERE rrn             = p_orgnl_rrn
      AND business_date     = p_orgnl_business_date
      AND business_time     = p_orgnl_business_time
      AND customer_card_no  = v_hash_pan
      AND instcode          = p_inst_code
      AND terminal_id       = p_orgnl_terminal_id;
      IF SQL%ROWCOUNT       = 0 THEN
        IF p_msg_typ NOT   IN ('1220', '1221') THEN
          v_resp_cde       := '21';
          v_errmsg         := 'Reverse flag is not updated ';
          RAISE exp_rvsl_reject_record;
        END IF;
      END IF;
    EXCEPTION
    WHEN exp_rvsl_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      v_errmsg   := 'Error while updating gl flag ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_rvsl_reject_record;
    END;
	
	
    BEGIN
      SELECT ctc_atmusage_amt,
        ctc_posusage_amt,
        ctc_business_date,
        ctc_mmposusage_amt
      INTO v_atm_usageamnt,
        v_pos_usageamnt,
        v_business_date_tran,
        v_mmpos_usageamnt
      FROM cms_translimit_check
      WHERE ctc_inst_code = p_inst_code
      AND ctc_pan_code    = v_hash_pan
      AND ctc_mbr_numb    = p_mbr_numb;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_errmsg   := 'Cannot get the Transaction Limit Details of the Card' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
      v_resp_cde := '21';
      RAISE exp_rvsl_reject_record;
    WHEN OTHERS THEN
      v_errmsg   := 'Error while selecting CMS_TRANSLIMIT_CHECK ' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
      v_resp_cde := '21';
      RAISE exp_rvsl_reject_record;
    END;
	
    BEGIN
      IF p_delv_chnl       = '02' THEN
        IF v_rvsl_trandate > v_business_date_tran THEN
          UPDATE cms_translimit_check
          SET ctc_posusage_amt = 0,
            ctc_posusage_limit = 0,
            ctc_atmusage_amt   = 0,
            ctc_atmusage_limit = 0,
            ctc_business_date  = TO_DATE (p_business_date
            || '23:59:59', 'yymmdd'
            || 'hh24:mi:ss' ),
            ctc_preauthusage_limit = 0,
            ctc_mmposusage_amt     = 0,
            ctc_mmposusage_limit   = 0
          WHERE ctc_inst_code      = p_inst_code
          AND ctc_pan_code         = v_hash_pan
          AND ctc_mbr_numb         = p_mbr_numb;
        ELSE
          IF p_orgnl_business_date = p_business_date THEN
            IF v_reversal_amt     IS NULL THEN
              v_pos_usageamnt     := v_pos_usageamnt;
            ELSE
              v_pos_usageamnt := v_pos_usageamnt - TRIM (TO_CHAR (v_reversal_amt, '999999999999.99'));
            END IF;
            UPDATE cms_translimit_check
            SET ctc_posusage_amt = v_pos_usageamnt
            WHERE ctc_inst_code  = p_inst_code
            AND ctc_pan_code     = v_hash_pan
            AND ctc_mbr_numb     = p_mbr_numb;
          END IF;
        END IF;
      END IF;
      IF SQL%ROWCOUNT = 0 THEN
        v_errmsg     := 'Error while updating the CMS_TRANSLIMIT_CHECK';
        v_resp_cde   := '21';
        RAISE exp_rvsl_reject_record;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      v_errmsg   := 'Error while updating CMS_TRANSLIMIT_CHECK ' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
      v_resp_cde := '21';
      RAISE exp_rvsl_reject_record;
    END;
 IF v_errmsg = 'OK' THEN
      BEGIN
        SELECT cam_acct_bal,
          cam_ledger_bal
        INTO v_acct_balance,
          v_ledger_bal
        FROM cms_acct_mast
        WHERE cam_acct_no =
          (SELECT cap_acct_no
          FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan
          AND cap_mbr_numb   = p_mbr_numb
          AND cap_inst_code  = p_inst_code
          )
        AND cam_inst_code = p_inst_code FOR UPDATE NOWAIT;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_resp_cde := '14';
        v_errmsg   := 'Invalid Card ';
        RAISE exp_rvsl_reject_record;
      WHEN OTHERS THEN
        v_resp_cde := '21';
        v_errmsg   := 'Error while selecting data from card Master for card number ' || SQLERRM;
        RAISE exp_rvsl_reject_record;
      END;
      p_resp_msg := TO_CHAR (v_acct_balance);
    ELSE
      p_resp_msg := v_errmsg;
    END IF;
  EXCEPTION
  WHEN exp_rvsl_reject_record THEN
    RAISE;
  WHEN OTHERS THEN
    v_resp_cde := '21';
    v_errmsg   := 'Error while inserting records in transaction log ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_rvsl_reject_record;
  END;
EXCEPTION
WHEN exp_rvsl_reject_record THEN
  ROLLBACK TO v_savepoint;
  BEGIN
    SELECT cam_acct_bal,
      cam_ledger_bal,
      cam_type_code
    INTO v_acct_balance,
      v_ledger_bal,
      v_acct_type
    FROM cms_acct_mast
    WHERE cam_acct_no =
      (SELECT cap_acct_no
      FROM cms_appl_pan
      WHERE cap_pan_code = v_hash_pan
      AND cap_inst_code  = p_inst_code
      )
    AND cam_inst_code = p_inst_code;
  EXCEPTION
  WHEN OTHERS THEN
    v_acct_balance := 0;
    v_ledger_bal   := 0;
  END;
  BEGIN
    SELECT cms_b24_respcde
    INTO p_resp_cde
    FROM cms_response_mast
    WHERE cms_inst_code      = p_inst_code
    AND cms_delivery_channel = p_delv_chnl
    AND cms_response_id      = TO_NUMBER (v_resp_cde);
    p_resp_msg              := v_errmsg;
  EXCEPTION
  WHEN OTHERS THEN
    p_resp_msg := 'Problem while selecting data from response master ' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
    p_resp_cde := '69';
  END;
  BEGIN
    SELECT ctc_atmusage_amt,
      ctc_posusage_amt,
      ctc_business_date,
      ctc_mmposusage_amt
    INTO v_atm_usageamnt,
      v_pos_usageamnt,
      v_business_date_tran,
      v_mmpos_usageamnt
    FROM cms_translimit_check
    WHERE ctc_inst_code = p_inst_code
    AND ctc_pan_code    = v_hash_pan
    AND ctc_mbr_numb    = p_mbr_numb;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_errmsg   := 'Cannot get the Transaction Limit Details of the Card' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
    v_resp_cde := '21';
    RAISE exp_rvsl_reject_record;
  WHEN OTHERS THEN
    v_errmsg   := 'Error while selecting CMS_TRANSLIMIT_CHECK 5' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
    v_resp_cde := '21';
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    IF p_delv_chnl       = '02' THEN
      IF v_rvsl_trandate > v_business_date_tran THEN
        UPDATE cms_translimit_check
        SET ctc_posusage_amt = 0,
          ctc_posusage_limit = 0,
          ctc_atmusage_amt   = 0,
          ctc_atmusage_limit = 0,
          ctc_business_date  = TO_DATE (p_business_date
          || '23:59:59', 'yymmdd'
          || 'hh24:mi:ss' ),
          ctc_preauthusage_limit = 0,
          ctc_mmposusage_amt     = 0,
          ctc_mmposusage_limit   = 0
        WHERE ctc_inst_code      = p_inst_code
        AND ctc_pan_code         = v_hash_pan
        AND ctc_mbr_numb         = p_mbr_numb;
      END IF;
    END IF;
    IF SQL%ROWCOUNT = 0 THEN
      v_errmsg     := 'Error while updating the CMS_TRANSLIMIT_CHECK';
      v_resp_cde   := '21';
      RAISE exp_rvsl_reject_record;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    v_errmsg   := 'Error while updating CMS_TRANSLIMIT_CHECK 5' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
    v_resp_cde := '21';
    RAISE exp_rvsl_reject_record;
  END;
  
  IF v_resp_cde NOT IN ('45', '32') THEN
    IF v_dr_cr_flag IS NULL THEN
      BEGIN
        SELECT ctm_credit_debit_flag,
          ctm_tran_desc,
          TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1'))
        INTO v_dr_cr_flag,
          v_tran_desc,
          v_txn_type
        FROM cms_transaction_mast
        WHERE ctm_tran_code      = p_txn_code
        AND ctm_delivery_channel = p_delv_chnl
        AND ctm_inst_code        = p_inst_code;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    IF v_prod_code IS NULL THEN
      BEGIN
        SELECT cap_prod_code,
          cap_card_type,
          cap_card_stat,
          cap_acct_no
        INTO v_prod_code,
          v_card_type,
          v_cap_card_stat,
          v_acct_number
        FROM cms_appl_pan
        WHERE cap_inst_code = p_inst_code
        AND cap_pan_code    = gethash (p_card_no);
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    BEGIN
      INSERT
      INTO transactionlog
        (
          msgtype,
          rrn,
          delivery_channel,
          terminal_id,
          date_time,
          txn_code,
          txn_type,
          txn_mode,
          txn_status,
          response_code,
          business_date,
          business_time,
          customer_card_no,
          topup_card_no,
          topup_acct_no,
          topup_acct_type,
          bank_code,
          total_amount,
          currencycode,
          addcharge,
          categoryid,
          atm_name_location,
          auth_id,
          amount,
          preauthamount,
          partialamount,
          instcode,
          customer_card_no_encr,
          topup_card_no_encr,
          orgnl_card_no,
          orgnl_rrn,
          orgnl_business_date,
          orgnl_business_time,
          orgnl_terminal_id,
          proxy_number,
          reversal_code,
          customer_acct_no,
          acct_balance,
          ledger_balance,
          response_id,
          trans_desc,
          merchant_name,
          merchant_city,
          merchant_state,
          productid,
          cardstatus,
          cr_dr_flag,
          acct_type,
          error_msg,
          time_stamp
        )
        VALUES
        (
          p_msg_typ,
          p_rrn,
          p_delv_chnl,
          p_terminal_id,
          v_rvsl_trandate,
          p_txn_code,
          v_txn_type,
          p_txn_mode,
          DECODE (p_resp_cde, '00', 'C', 'F'),
          p_resp_cde,
          p_business_date,
          SUBSTR (p_business_time, 1, 10),
          v_hash_pan,
          NULL,
          NULL,
          NULL,
          p_inst_code,
          TRIM (TO_CHAR (NVL (v_tran_amt, 0), '999999999999999990.99' ) ),
          v_currcode,
          NULL,
          v_card_type,
          p_terminal_id,
          v_auth_id,
          TRIM (TO_CHAR (NVL (v_tran_amt, 0), '999999999999999990.99' ) ),
          '0.00',
          '0.00',
          p_inst_code,
          v_encr_pan,
          v_encr_pan,
          v_encr_pan,
          p_orgnl_rrn,
          p_orgnl_business_date,
          p_orgnl_business_time,
          p_orgnl_terminal_id,
          v_proxunumber,
          p_rvsl_code,
          v_acct_number,
          v_acct_balance,
          v_ledger_bal,
          v_resp_cde,
          v_tran_desc,
          v_txn_merchname,
          v_txn_merchcity,
          v_txn_merchstate,
          v_prod_code,
          v_cap_card_stat,
          v_dr_cr_flag,
          v_acct_type,
          v_errmsg,
          NVL (v_timestamp, SYSTIMESTAMP)
        );
    EXCEPTION
    WHEN OTHERS THEN
      p_resp_cde := '89';
      p_resp_msg := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
    END;
  END IF;
  BEGIN
    INSERT
    INTO cms_transaction_log_dtl
      (
        ctd_delivery_channel,
        ctd_txn_code,
        ctd_txn_type,
        ctd_msg_type,
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
        ctd_inst_code,
        ctd_customer_card_no_encr,
        ctd_cust_acct_number
      )
      VALUES
      (
        p_delv_chnl,
        p_txn_code,
        v_txn_type,
        p_msg_typ,
        p_txn_mode,
        p_business_date,
        p_business_time,
        v_hash_pan,
        p_actual_amt,
        v_currcode,
        v_tran_amt,
        NULL,
        NULL,
        NULL,
        NULL,
        p_actual_amt,
        v_card_curr,
        'E',
        v_errmsg,
        p_rrn,
        p_stan,
        p_inst_code,
        v_encr_pan,
        v_acct_number
      );
  EXCEPTION
  WHEN OTHERS THEN
    p_resp_msg := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
    p_resp_cde := '69';
    ROLLBACK;
    RETURN;
  END;
  p_resp_msg := v_errmsg;
WHEN OTHERS THEN
  ROLLBACK TO v_savepoint;
  BEGIN
    SELECT cms_b24_respcde
    INTO p_resp_cde
    FROM cms_response_mast
    WHERE cms_inst_code      = p_inst_code
    AND cms_delivery_channel = p_delv_chnl
    AND cms_response_id      = TO_NUMBER (v_resp_cde);
    p_resp_msg              := v_errmsg;
  EXCEPTION
  WHEN OTHERS THEN
    p_resp_msg := 'Problem while selecting data from response master ' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
    p_resp_cde := '69';
  END;
  BEGIN
    SELECT ctc_atmusage_amt,
      ctc_posusage_amt,
      ctc_business_date,
      ctc_mmposusage_amt
    INTO v_atm_usageamnt,
      v_pos_usageamnt,
      v_business_date_tran,
      v_mmpos_usageamnt
    FROM cms_translimit_check
    WHERE ctc_inst_code = p_inst_code
    AND ctc_pan_code    = v_hash_pan
    AND ctc_mbr_numb    = p_mbr_numb;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_errmsg   := 'Cannot get the Transaction Limit Details of the Card' || v_resp_cde || SUBSTR (SQLERRM, 1, 300);
    v_resp_cde := '21';
    RAISE exp_rvsl_reject_record;
  WHEN OTHERS THEN
    v_errmsg   := 'Error while selecting 3 CMS_TRANSLIMIT_CHECK' || SUBSTR (SQLERRM, 1, 200);
    v_resp_cde := '21';
    RAISE exp_rvsl_reject_record;
  END;
  BEGIN
    IF p_delv_chnl       = '02' THEN
      IF v_rvsl_trandate > v_business_date_tran THEN
        UPDATE cms_translimit_check
        SET ctc_posusage_amt = 0,
          ctc_posusage_limit = 0,
          ctc_atmusage_amt   = 0,
          ctc_atmusage_limit = 0,
          ctc_business_date  = TO_DATE (p_business_date
          || '23:59:59', 'yymmdd'
          || 'hh24:mi:ss' ),
          ctc_preauthusage_limit = 0,
          ctc_mmposusage_amt     = 0,
          ctc_mmposusage_limit   = 0
        WHERE ctc_inst_code      = p_inst_code
        AND ctc_pan_code         = v_hash_pan
        AND ctc_mbr_numb         = p_mbr_numb;
      END IF;
    END IF;
    IF SQL%ROWCOUNT = 0 THEN
      v_errmsg     := 'Error while updating the CMS_TRANSLIMIT_CHECK';
      v_resp_cde   := '21';
      RAISE exp_rvsl_reject_record;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    v_errmsg   := 'Error while updating 3 CMS_TRANSLIMIT_CHECK' || SUBSTR (SQLERRM, 1, 200);
    v_resp_cde := '21';
    RAISE exp_rvsl_reject_record;
  END;
  IF v_resp_cde NOT IN ('45', '32') THEN
    IF v_dr_cr_flag IS NULL THEN
      BEGIN
        SELECT ctm_credit_debit_flag,
          ctm_tran_desc,
          TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1'))
        INTO v_dr_cr_flag,
          v_tran_desc,
          v_txn_type
        FROM cms_transaction_mast
        WHERE ctm_tran_code      = p_txn_code
        AND ctm_delivery_channel = p_delv_chnl
        AND ctm_inst_code        = p_inst_code;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    IF v_prod_code IS NULL THEN
      BEGIN
        SELECT cap_prod_code,
          cap_card_type,
          cap_card_stat,
          cap_acct_no
        INTO v_prod_code,
          v_card_type,
          v_cap_card_stat,
          v_acct_number
        FROM cms_appl_pan
        WHERE cap_inst_code = p_inst_code
        AND cap_pan_code    = gethash (p_card_no);
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
        AND cam_acct_no     = v_acct_number;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    BEGIN
      INSERT
      INTO transactionlog
        (
          msgtype,
          rrn,
          delivery_channel,
          terminal_id,
          date_time,
          txn_code,
          txn_type,
          txn_mode,
          txn_status,
          response_code,
          business_date,
          business_time,
          customer_card_no,
          topup_card_no,
          topup_acct_no,
          topup_acct_type,
          bank_code,
          total_amount,
          currencycode,
          addcharge,
          categoryid,
          atm_name_location,
          auth_id,
          amount,
          preauthamount,
          partialamount,
          instcode,
          customer_card_no_encr,
          topup_card_no_encr,
          orgnl_card_no,
          orgnl_rrn,
          orgnl_business_date,
          orgnl_business_time,
          orgnl_terminal_id,
          proxy_number,
          reversal_code,
          customer_acct_no,
          acct_balance,
          ledger_balance,
          response_id,
          trans_desc,
          merchant_name,
          merchant_city,
          merchant_state,
          productid,
          cardstatus,
          cr_dr_flag,
          acct_type,
          error_msg,
          time_stamp
        )
        VALUES
        (
          p_msg_typ,
          p_rrn,
          p_delv_chnl,
          p_terminal_id,
          v_rvsl_trandate,
          p_txn_code,
          v_txn_type,
          p_txn_mode,
          DECODE (p_resp_cde, '00', 'C', 'F'),
          p_resp_cde,
          p_business_date,
          SUBSTR (p_business_time, 1, 10),
          v_hash_pan,
          NULL,
          NULL,
          NULL,
          p_inst_code,
          TRIM (TO_CHAR (NVL (v_tran_amt, 0), '999999999999999990.99' ) ),
          v_currcode,
          NULL,
          v_card_type,
          p_terminal_id,
          v_auth_id,
          TRIM (TO_CHAR (NVL (v_tran_amt, 0), '999999999999999990.99' ) ),
          '0.00',
          '0.00',
          p_inst_code,
          v_encr_pan,
          v_encr_pan,
          v_encr_pan,
          p_orgnl_rrn,
          p_orgnl_business_date,
          p_orgnl_business_time,
          p_orgnl_terminal_id,
          v_proxunumber,
          p_rvsl_code,
          v_acct_number,
          v_acct_balance,
          v_ledger_bal,
          v_resp_cde,
          v_tran_desc,
          v_txn_merchname,
          v_txn_merchcity,
          v_txn_merchstate,
          v_prod_code,
          v_cap_card_stat,
          v_dr_cr_flag,
          v_acct_type,
          v_errmsg,
          NVL (v_timestamp, SYSTIMESTAMP)
        );
    EXCEPTION
    WHEN OTHERS THEN
      p_resp_cde := '89';
      p_resp_msg := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
    END;
  END IF;
  BEGIN
    INSERT
    INTO cms_transaction_log_dtl
      (
        ctd_delivery_channel,
        ctd_txn_code,
        ctd_txn_type,
        ctd_msg_type,
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
        ctd_inst_code,
        ctd_customer_card_no_encr,
        ctd_cust_acct_number
      )
      VALUES
      (
        p_delv_chnl,
        p_txn_code,
        v_txn_type,
        p_msg_typ,
        p_txn_mode,
        p_business_date,
        p_business_time,
        v_hash_pan,
        p_actual_amt,
        v_currcode,
        v_tran_amt,
        NULL,
        NULL,
        NULL,
        NULL,
        p_actual_amt,
        v_card_curr,
        'E',
        v_errmsg,
        p_rrn,
        p_stan,
        p_inst_code,
        v_encr_pan,
        v_acct_number
      );
  EXCEPTION
  WHEN OTHERS THEN
    p_resp_msg := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
    p_resp_cde := '69';
    ROLLBACK;
    RETURN;
  END;
  p_resp_msg_m24 := v_errmsg;
END;

/
show error