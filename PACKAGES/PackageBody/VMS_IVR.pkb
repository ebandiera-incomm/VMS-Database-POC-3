CREATE OR REPLACE
PACKAGE body vmscms.vms_ivr
IS
PROCEDURE startercard_replacement(
    p_instcode_in         IN NUMBER,
    p_msg_type_in         IN VARCHAR2,
    p_rrn_in              IN VARCHAR2,
    p_delivery_channel_in IN VARCHAR2,
    p_terminalid_in       IN VARCHAR2,
    p_txn_code_in         IN VARCHAR2,
    p_txn_mode_in         IN VARCHAR2,
    p_trandate_in         IN VARCHAR2,
    p_trantime_in         IN VARCHAR2,
    p_card_no_in          IN VARCHAR2,
    p_tocard_no_in        IN VARCHAR2,
    p_currcode_in         IN VARCHAR2,
    p_mbr_numb_in         IN VARCHAR2,
    p_rvsl_code_in        IN VARCHAR2,
    p_ani_in              IN VARCHAR2,
    p_dni_in              IN VARCHAR2,
    p_resp_code_out OUT VARCHAR2,
    p_errmsg_out OUT VARCHAR2,
    p_card_status_out OUT VARCHAR2,
    p_card_status_desc_out OUT VARCHAR2)
IS
  /****************************************************************************
  ****************
  * CREATED  BY        : T.NARAYANASWAMY
  * CREATED DATE       : 05 - May - 16
  * CREATED FOR        : To migrate the existing startercard account to new
  startercard
  * REVIEWER           : SARAVANANAKUMAR
  * BUILD NUMBER       : VMSGPRHOST_4.3_B0001
  *****************************************************************************
  *******************/
  
    /* Modified By      : venkat Singamaneni
    * Modified Date    : 5-11-2022
    * Purpose          : Archival changes.
    * Reviewer         : Karthick/Jay
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991*/
	
  l_acct_balance NUMBER;
  l_ledger_bal   NUMBER;
  l_tran_amt     NUMBER;
  l_auth_id transactionlog.auth_id%type;
  l_total_amt NUMBER;
  l_tran_date DATE;
  l_func_code cms_func_mast.cfm_func_code%type;
  l_prod_code cms_prod_mast.cpm_prod_code%type;
  l_prod_cattype cms_prod_cattype.cpc_card_type%type;
  l_fee_amt         NUMBER;
  l_total_fee       NUMBER;
  l_upd_amt         NUMBER;
  l_upd_ledger_amt  NUMBER;
  l_narration       VARCHAR2(50);
  l_fee_opening_bal NUMBER;
  l_resp_cde        VARCHAR2(5);
  l_expry_date DATE;
  l_dr_cr_flag  VARCHAR2(2);
  l_output_type VARCHAR2(2);
  l_applpan_cardstat cms_appl_pan.cap_card_stat%type;
  l_err_msg       VARCHAR2(500);
  l_precheck_flag NUMBER;
  l_preauth_flag  NUMBER;
  l_gl_upd_flag transactionlog.gl_upd_flag%type;
  l_savepoint NUMBER := 0;
  l_tran_fee  NUMBER;
  l_error     VARCHAR2(500);
  l_business_date_tran DATE;
  l_business_time VARCHAR2(5);
  l_card_curr     VARCHAR2(5);
  l_fee_code cms_fee_mast.cfm_fee_code%type;
  l_fee_cracct_no cms_prodcattype_fees.cpf_cracct_no%type;
  l_fee_dracct_no cms_prodcattype_fees.cpf_dracct_no%type;
  l_servicetax_amount NUMBER;
  l_cess_amount       NUMBER;
  l_st_calc_flag cms_prodcattype_fees.cpf_st_calc_flag%type;
  l_cess_calc_flag cms_prodcattype_fees.cpf_cess_calc_flag%type;
  l_st_cracct_no cms_prodcattype_fees.cpf_st_cracct_no%type;
  l_st_dracct_no cms_prodcattype_fees.cpf_st_dracct_no%type;
  l_cess_cracct_no cms_prodcattype_fees.cpf_cess_cracct_no%type;
  l_cess_dracct_no cms_prodcattype_fees.cpf_cess_dracct_no%type;
  l_auth_savepoint NUMBER DEFAULT 0;
  l_business_date DATE;
  l_txn_type        NUMBER(1);
  exp_reject_record EXCEPTION;
  l_card_acct_no    VARCHAR2(20);
  l_hold_amount     NUMBER;
  l_hash_pan cms_appl_pan.cap_pan_code%type;
  l_encr_pan cms_appl_pan.cap_pan_code_encr%type;
  l_hash_topan cms_appl_pan.cap_pan_code%type;
  l_encr_topan cms_appl_pan.cap_pan_code_encr%type;
  l_rrn_count NUMBER;
  l_tran_type VARCHAR2(2);
  l_curr_date DATE;
  l_proxy_number cms_appl_pan.cap_proxy_number%type;
  l_acct_number cms_appl_pan.cap_acct_no%type;
  l_firsttime_topup cms_appl_pan.cap_firsttime_topup%type;
  l_acct_id cms_appl_pan.cap_acct_id%type;
  l_cap_card_stat   VARCHAR2(10);
  l_tocust_code     VARCHAR2(100);
  l_tocap_card_stat VARCHAR2(10);
  l_toccs_card_stat cms_cardissuance_status.ccs_card_status%type;
  l_toacct_bal cms_acct_mast.cam_acct_bal%type;
  l_toledg_bal cms_acct_mast.cam_ledger_bal%type;
  l_toproxy_number cms_appl_pan.cap_proxy_number%type;
  l_tostartercard_flag cms_appl_pan.cap_startercard_flag%type;
  l_toacct_number cms_appl_pan.cap_acct_no%type;
  l_toprod_code cms_prod_mast.cpm_prod_code%type;
  l_toprod_cattype cms_prod_cattype.cpc_card_type%type;
  l_mbrnumb       VARCHAR2(10);
  l_cap_prod_catg VARCHAR2(100);
  l_cust_code     VARCHAR2(100);
  p_remrk         VARCHAR2(100);
  l_resoncode cms_spprt_reasons.csr_spprt_rsncode%type;
  l_status_chk NUMBER;
  l_fee_plan cms_fee_feeplan.cff_fee_plan%type;
  l_startercard_flag cms_appl_pan.cap_startercard_flag%type;
  l_dup_check NUMBER (3);
  l_cam_lupd_date cms_addr_mast.cam_lupd_date%type;
  l_appl_code cms_appl_pan.cap_appl_code%type;
  l_cam_type_code cms_acct_mast.cam_type_code%type;
  l_timestamp TIMESTAMP;
  l_lmtprfl cms_prdcattype_lmtprfl.cpl_lmtprfl_id%type;
  l_profile_level cms_appl_pan.cap_prfl_levl%type;
  l_starter_replacement_flag cms_prod_cattype.cpc_starter_replacement%type;
  l_starter__cattype_count NUMBER;
  l_capture_date DATE;
  l_loadcredit_flag cms_prodcatg_smsemail_alerts.cps_loadcredit_flag%TYPE;
  l_lowbal_flag cms_prodcatg_smsemail_alerts.cps_lowbal_flag%TYPE;
  l_negativebal_flag cms_prodcatg_smsemail_alerts.cps_negativebal_flag%TYPE;
  l_highauthamt_flag cms_prodcatg_smsemail_alerts.cps_highauthamt_flag%TYPE;
  l_dailybal_flag cms_prodcatg_smsemail_alerts.cps_dailybal_flag%TYPE;
  l_insuffund_flag cms_prodcatg_smsemail_alerts.cps_insuffund_flag%TYPE;
  l_incorrectpin_flag cms_prodcatg_smsemail_alerts.cps_incorrectpin_flag%TYPE;
  l_cellphonecarrier CHAR(1);
  l_lowbal_amt       NUMBER(15, 2);
  l_highauthamt      NUMBER(15, 2);
  l_c2c_flag         CHAR(1);
  l_fast50_flag cms_prodcatg_smsemail_alerts.cps_fast50_flag%type;
  l_federal_flag cms_prodcatg_smsemail_alerts.cps_fedtax_refund_flag%type;
  l_alert_lang_id cms_prodcatg_smsemail_alerts.cps_alert_lang_id%type;
  V_PROD_TYPE CMS_PRODUCT_PARAM.CPP_PRODUCT_TYPE%TYPE;
  
  v_Retperiod  date;  --Added for VMS-5735/FSP-991
  v_Retdate  date; --Added for VMS-5735/FSP-991

BEGIN
  SAVEPOINT l_auth_savepoint;
  l_resp_cde   := '1';
  l_err_msg    := 'OK';
  p_errmsg_out := 'OK';
  p_remrk      := 'IVR Starter Card Replacement';
  BEGIN
    --SN CREATE HASH PAN
    BEGIN
      l_hash_pan := gethash(p_card_no_in);
    EXCEPTION
    WHEN OTHERS THEN
      l_err_msg := 'Error while converting into hash value ' ||fn_mask(
      p_card_no_in,'X',7,6) ||' '||SUBSTR(sqlerrm, 1, 200);
      raise exp_reject_record;
    END;
    --EN CREATE HASH PAN
    --SN CREATE HASH TO CARD NUMBER
    BEGIN
      l_hash_topan := gethash(p_tocard_no_in);
    EXCEPTION
    WHEN OTHERS THEN
      l_err_msg := 'Error while converting into hash value ' ||fn_mask(
      p_card_no_in,'X',7,6) ||' '||SUBSTR(sqlerrm, 1, 200);
      raise exp_reject_record;
    END;
    --EN CREATE HASH TO CARD NUMBER
    --SN create encr pan
    BEGIN
      l_encr_pan := fn_emaps_main(p_card_no_in);
    EXCEPTION
    WHEN OTHERS THEN
      l_err_msg := 'Error while converting into encrypted value '||fn_mask(
      p_card_no_in,'X',7,6) ||' '||SUBSTR(sqlerrm, 1, 200);
      raise exp_reject_record;
    END;
    --EN create encr pan
    --SN create encr to card number
    BEGIN
      l_encr_topan := fn_emaps_main(p_tocard_no_in);
    EXCEPTION
    WHEN OTHERS THEN
      l_err_msg := 'Error while converting into encrypted value '||fn_mask(
      p_card_no_in,'X',7,6) ||' '||SUBSTR(sqlerrm, 1, 200);
      raise exp_reject_record;
    END;
    --EN create encr pan
    BEGIN
      SELECT
        cap_prod_catg,
        cap_card_stat,
        cap_acct_no,
        cap_acct_id,
        cap_cust_code,
        cap_appl_code,
        cap_startercard_flag,
        cap_prod_code,
        cap_card_type,
        cap_prfl_code,
        cap_prfl_levl,
        cap_proxy_number,
        CAP_FIRSTTIME_TOPUP
      INTO
        l_cap_prod_catg,
        l_cap_card_stat,
        l_acct_number,
        l_acct_id,
        l_cust_code,
        l_appl_code,
        l_startercard_flag,
        l_prod_code,
        l_prod_cattype,
        l_lmtprfl,
        l_profile_level,
        l_proxy_number,
        l_FIRSTTIME_TOPUP
      FROM
        cms_appl_pan
      WHERE
        cap_pan_code    = l_hash_pan
      AND cap_inst_code = p_instcode_in;
    EXCEPTION
    WHEN no_data_found THEN
      l_err_msg  := 'Pan not found in master';
      l_resp_cde := '21';
      raise exp_reject_record;
    WHEN OTHERS THEN
      l_err_msg := 'Error while selecting CMS_APPL_PAN' || SUBSTR(sqlerrm, 1,
      200);
      l_resp_cde := '21';
      raise exp_reject_record;
    END;
    BEGIN
      IF l_startercard_flag <> 'Y' THEN
        l_err_msg           :=
        'From Card should be Starter Card for Replacement';
        l_resp_cde := '182';
        raise exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      l_err_msg := 'Error while Validating From card details' || SUBSTR(sqlerrm
      , 1, 200);
      l_resp_cde := '21';
      raise exp_reject_record;
    END;
    BEGIN
      l_business_date := to_date(SUBSTR(trim(p_trandate_in), 1, 8) || ' ' ||
      SUBSTR(trim(p_trantime_in), 1, 10), 'yyyymmdd hh24:mi:ss');
    EXCEPTION
    WHEN OTHERS THEN
      l_resp_cde := '32';
      l_err_msg  := 'Problem while converting transaction date time ' || SUBSTR
      (sqlerrm, 1, 200);
      raise exp_reject_record;
    END;
    --Sn find debit and credit flag
    BEGIN
      SELECT
        ctm_credit_debit_flag,
        ctm_output_type,
        to_number(DECODE(ctm_tran_type, 'N', '0', 'F', '1')),
        ctm_tran_type,
        CTM_TRAN_DESC
      INTO
        l_dr_cr_flag,
        l_output_type,
        l_txn_type,
        l_tran_type,
        l_narration
      FROM
        cms_transaction_mast
      WHERE
        ctm_tran_code          = p_txn_code_in
      AND ctm_delivery_channel = p_delivery_channel_in
      AND ctm_inst_code        = p_instcode_in;
    EXCEPTION
    WHEN no_data_found THEN
      l_resp_cde := '12'; --Ineligible Transaction
      l_err_msg  := 'Transflag  not defined for txn code ' || p_txn_code_in ||
      ' and delivery channel ' || p_delivery_channel_in;
      raise exp_reject_record;
    WHEN OTHERS THEN
      l_resp_cde := '21'; --Ineligible Transaction
      l_err_msg  := 'Error while selecting transaction details';
      raise exp_reject_record;
    END;
    --En find debit and credit flag
    --Sn Duplicate RRN Check
    BEGIN
	
	   --Added for VMS-5735/FSP-991
	   
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate_in), 1, 8), 'yyyymmdd');
	 
    IF (v_Retdate>v_Retperiod) THEN                                      --Added for VMS-5733/FSP-991
	
        SELECT
         COUNT(1)
        INTO
         l_rrn_count
        FROM
         transactionlog
        WHERE
         rrn                = p_rrn_in
        AND business_date    = p_trandate_in
        AND delivery_channel = p_delivery_channel_in;
	  
	 ELSE 
	 
	    SELECT
         COUNT(1)
        INTO
         l_rrn_count
        FROM
         VMSCMS_HISTORY.TRANSACTIONLOG_HIST                  --Added for VMS-5733/FSP-991
        WHERE
         rrn                = p_rrn_in
        AND business_date    = p_trandate_in
        AND delivery_channel = p_delivery_channel_in;
	  
	END IF;
	  
      IF l_rrn_count       > 0 THEN
        l_resp_cde        := '22';
        l_err_msg         := 'Duplicate RRN from the Terminal on ' ||
        p_trandate_in;
        raise exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg  := 'Error while selecting transaction details';
      raise exp_reject_record;
    END;
    --En Duplicate RRN Check
    BEGIN
      IF p_card_no_in=p_tocard_no_in THEN
        l_err_msg   := 'From and To Card Number cannot be same';
        l_resp_cde  := '189';
        raise exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      l_err_msg := 'Error while Validating To card details' || SUBSTR(sqlerrm ,
      1, 200);
      l_resp_cde := '21';
      raise exp_reject_record;
    END;
    BEGIN
      sp_authorize_txn_cms_auth (p_instcode_in, p_msg_type_in, p_rrn_in,
      p_delivery_channel_in, p_terminalid_in, p_txn_code_in, p_txn_mode_in,
      p_trandate_in, p_trantime_in, p_card_no_in, p_instcode_in, NULL, NULL,
      NULL, NULL, p_currcode_in, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
      , NULL, NULL, NULL, NULL, NULL, NULL, p_mbr_numb_in, p_rvsl_code_in, NULL
      , l_auth_id, l_resp_cde, l_err_msg, l_capture_date, NULL );
      IF l_resp_cde     <> '00' AND l_err_msg <> 'OK' THEN
        p_resp_code_out := l_resp_cde;
        p_errmsg_out    := 'Error from auth process' || l_err_msg;
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      l_resp_cde := '21';
      l_err_msg  := 'Error from Card authorization' || SUBSTR (sqlerrm, 1, 200)
      ;
      raise exp_reject_record;
    END;
    p_resp_code_out := l_resp_cde;
    p_errmsg_out    := l_err_msg;
    IF l_resp_cde    = '00' AND l_err_msg = 'OK' THEN
      BEGIN
        SELECT
          cap_card_stat,
          cap_acct_no,
          cap_cust_code,
          cap_startercard_flag,
          cap_prod_code,
          cap_card_type,
          cap_proxy_number
        INTO
          l_tocap_card_stat,
          l_toacct_number,
          l_tocust_code,
          l_tostartercard_flag,
          l_toprod_code,
          l_toprod_cattype,
          l_toproxy_number
        FROM
          cms_appl_pan
        WHERE
          cap_pan_code    = l_hash_topan
        AND cap_inst_code = p_instcode_in;
      EXCEPTION
      WHEN no_data_found THEN
        l_err_msg  := 'To Pan not found in master';
        l_resp_cde := '21';
        raise exp_reject_record;
      WHEN OTHERS THEN
        l_err_msg := 'Error while selecting to card details from CMS_APPL_PAN'
        || SUBSTR(sqlerrm, 1, 200);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      BEGIN
        IF l_tostartercard_flag <> 'Y' THEN
          l_err_msg             :=
          'To Card should be Starter Card for Replacement';
          l_resp_cde := '183';
          raise exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        l_err_msg := 'Error while Validating To card details' || SUBSTR(sqlerrm
        , 1, 200);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      BEGIN
        IF l_tocap_card_stat <> '0' THEN
          l_err_msg          := 'To Card should be in Inactive status';
          l_resp_cde         := '184';
          raise exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        l_err_msg := 'Error while Validating To card details' || SUBSTR(sqlerrm
        , 1, 200);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      BEGIN
        SELECT
          ccs_card_status
        INTO
          l_toccs_card_stat
        FROM
          CMS_CARDISSUANCE_STATUS
        WHERE
          CCS_PAN_CODE    = l_hash_topan
        AND CCS_INST_CODE = p_instcode_in;
      EXCEPTION
      WHEN no_data_found THEN
        l_err_msg  := 'To Pan not found in masters';
        l_resp_cde := '21';
        raise exp_reject_record;
      WHEN OTHERS THEN
        l_err_msg :=
        'Error while selecting to card details from CMS_CARDISSUANCE_STATUS' ||
        SUBSTR(sqlerrm, 1, 200);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      BEGIN
        IF l_toccs_card_stat <> '15' THEN
          l_err_msg          := 'To Card should be in Shipped Status';
          l_resp_cde         := '185';
          raise exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        l_err_msg := 'Error while Validating New card details' || SUBSTR(
        sqlerrm, 1, 200);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      BEGIN
        SELECT
          cam_acct_bal,
          cam_ledger_bal
        INTO
          l_toacct_bal,
          l_toledg_bal
        FROM
          cms_acct_mast
        WHERE
          cam_acct_no     =l_toacct_number
        AND CAM_INST_CODE = p_instcode_in;
      EXCEPTION
      WHEN no_data_found THEN
        l_err_msg  := 'Account not found in master';
        l_resp_cde := '21';
        raise exp_reject_record;
      WHEN OTHERS THEN
        l_err_msg := 'Error while selecting to card details from CMS_ACCT_MAST'
        || SUBSTR(sqlerrm, 1, 200);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      BEGIN
        IF l_toacct_bal > '0' OR l_toledg_bal > '0' THEN
          l_err_msg    := 'To Card Balance is not equal to Zero';
          l_resp_cde   := '186';
          raise exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        l_err_msg := 'Error while Validating To card details' || SUBSTR(sqlerrm
        , 1, 200);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      BEGIN
        SELECT
          cpc_starter_replacement
        INTO
          l_starter_replacement_flag
        FROM
          cms_prod_cattype
        WHERE
          cpc_prod_code                =l_prod_code
        AND cpc_card_type              =l_prod_cattype
        AND cpc_inst_code              = p_instcode_in;
        IF l_starter_replacement_flag IS NULL THEN
          l_err_msg                   :=
          'Startercard Replacement is not Allowed for this Product/Product Category'
          ;
          l_resp_cde := '263';
          raise exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE exp_reject_record;
      WHEN no_data_found THEN
        l_err_msg  := 'Product config not found in master';
        l_resp_cde := '21';
        raise exp_reject_record;
      WHEN OTHERS THEN
        l_err_msg := 'Error while selecting Product details' || SUBSTR(sqlerrm,
        1, 200);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      BEGIN
        IF l_prod_code <> l_toprod_code THEN
          l_err_msg    := 'Both the card number should be in same BIN' ;
          l_resp_cde   := '140';
          raise exp_reject_record;
        elsif l_starter_replacement_flag = '0' THEN
          l_err_msg                     :=
          'Startercard Replacement is not Allowed for this Product/Product Category'
          ;
          l_resp_cde := '263';
          raise exp_reject_record;
        elsif l_starter_replacement_flag='1' THEN
          SELECT
            COUNT(*)
          INTO
            l_starter__cattype_count
          FROM
            cms_prod_cattype
          WHERE
            cpc_prod_code       =l_toprod_code
          AND cpc_card_type     =l_toprod_cattype
          AND l_toprod_cattype IN
            (
              SELECT DISTINCT
                regexp_substr(cpc_replacement_cattype,'[^,]+', 1, level)
              FROM
                cms_prod_cattype
              WHERE
                cpc_prod_code   =l_prod_code
              AND cpc_card_type =l_prod_cattype
              AND cpc_inst_code =p_instcode_in
                CONNECT BY regexp_substr(cpc_replacement_cattype, '[^,]+', 1,
                level) IS NOT NULL
            );
          IF l_starter__cattype_count=0 THEN
            l_err_msg               :=
            'Startercard Replacement is not Allowed for this Product/Product Category'
            ;
            l_resp_cde := '263';
            raise exp_reject_record;
          END IF;
        elsif l_starter_replacement_flag='2' THEN
          IF l_prod_code               <> l_toprod_code OR l_prod_cattype <>
            l_toprod_cattype THEN
            l_err_msg :=
            'Startercard Replacement is not Allowed for this Product/Product Category'
            ;
            l_resp_cde := '263';
            raise exp_reject_record;
          END IF;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        l_err_msg :=
        'Error while selecting Starter Card Configuration for Replacement' ||
        SUBSTR( sqlerrm, 1, 200);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      BEGIN
        INSERT
        INTO
          cms_card_excpfee
          (
            cce_inst_code,
            cce_pan_code,
            cce_ins_date,
            cce_ins_user,
            cce_lupd_user,
            cce_lupd_date,
            cce_fee_plan,
            cce_flow_source,
            cce_valid_from,
            cce_valid_to,
            cce_pan_code_encr,
            cce_mbr_numb
          )
          (
            SELECT
              cce_inst_code,
              l_hash_topan,
              sysdate,
              cce_ins_user,
              cce_lupd_user,
              sysdate,
              cce_fee_plan,
              cce_flow_source,
              (
                CASE
                  WHEN cce_valid_from>=TRUNC(sysdate)
                  THEN cce_valid_from
                  ELSE sysdate
                END)cce_valid_from,
              cce_valid_to,
              l_encr_topan,
              cce_mbr_numb
            FROM
              cms_card_excpfee
            WHERE
              cce_pan_code    =l_hash_pan
            AND cce_inst_code =p_instcode_in
            AND
              (
                (
                  cce_valid_to IS NOT NULL
                AND
                  (
                    TRUNC(sysdate) BETWEEN cce_valid_from AND cce_valid_to
                  )
                )
              OR
                (
                  cce_valid_to     IS NULL
                AND TRUNC(sysdate) >= cce_valid_from
                )
              OR
                (
                  cce_valid_from >=TRUNC(sysdate)
                )
              )
          );
      EXCEPTION
      WHEN OTHERS THEN
        l_err_msg := 'Error while attaching fee plan to reissuue card ' ||
        SUBSTR(sqlerrm, 1, 200);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      IF l_err_msg = 'OK' THEN
        BEGIN
          SELECT
            csa_loadorcredit_flag,
            csa_lowbal_flag,
            csa_negbal_flag,
            csa_highauthamt_flag,
            csa_dailybal_flag,
            csa_insuff_flag,
            csa_incorrpin_flag,
            csa_fast50_flag,
            csa_fedtax_refund_flag,
            csa_cellphonecarrier,
            csa_lowbal_amt,
            csa_highauthamt,
            csa_c2c_flag,
            csa_alert_lang_id
          INTO
            l_loadcredit_flag,
            l_lowbal_flag,
            l_negativebal_flag,
            l_highauthamt_flag,
            l_dailybal_flag,
            l_insuffund_flag,
            l_incorrectpin_flag,
            l_fast50_flag,
            l_federal_flag,
            l_cellphonecarrier,
            l_lowbal_amt,
            l_highauthamt,
            l_c2c_flag,
            l_alert_lang_id
          FROM
            cms_smsandemail_alert
          WHERE
            csa_inst_code  = p_instcode_in
          AND csa_pan_code = l_hash_pan;
          UPDATE
            cms_smsandemail_alert
          SET
            csa_loadorcredit_flag  = l_loadcredit_flag,
            csa_lowbal_flag        = l_lowbal_flag,
            csa_negbal_flag        = l_negativebal_flag,
            csa_highauthamt_flag   = l_highauthamt_flag,
            csa_dailybal_flag      = l_dailybal_flag,
            csa_insuff_flag        = l_insuffund_flag,
            csa_incorrpin_flag     = l_incorrectpin_flag,
            csa_fast50_flag        = l_fast50_flag,
            csa_fedtax_refund_flag = l_federal_flag,
            csa_cellphonecarrier   = l_cellphonecarrier,
            csa_c2c_flag           = l_c2c_flag,
            csa_lupd_date          = SYSDATE,
            csa_lowbal_amt         = NVL(l_lowbal_amt, 0),
            csa_highauthamt        = NVL(l_highauthamt, 0),
            csa_alert_lang_id      = l_alert_lang_id
          WHERE
            csa_inst_code  = p_instcode_in
          AND csa_pan_code = l_hash_topan;
          IF sql%rowcount != 1 THEN
            l_err_msg     := 'Error while Entering sms email alert detail ' ||
            SUBSTR (sqlerrm, 1, 200);
            l_resp_cde := '21';
            raise exp_reject_record;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          l_err_msg := 'Error while Entering sms email alert detail ' || SUBSTR
          ( sqlerrm, 1, 200);
          l_resp_cde := '21';
          raise exp_reject_record;
        END;
        IF l_lmtprfl IS NULL OR l_profile_level IS NULL THEN
          BEGIN
            SELECT
              cpl_lmtprfl_id
            INTO
              l_lmtprfl
            FROM
              cms_prdcattype_lmtprfl
            WHERE
              cpl_inst_code   = p_instcode_in
            AND cpl_prod_code = l_prod_code
            AND cpl_card_type = l_prod_cattype;
            l_profile_level  := 2;
          EXCEPTION
          WHEN no_data_found THEN
            BEGIN
              SELECT
                cpl_lmtprfl_id
              INTO
                l_lmtprfl
              FROM
                cms_prod_lmtprfl
              WHERE
                cpl_inst_code   = p_instcode_in
              AND cpl_prod_code = l_prod_code;
              l_profile_level  := 3;
            EXCEPTION
            WHEN no_data_found THEN
              NULL;
            WHEN OTHERS THEN
              l_resp_cde := '21';
              l_err_msg  :=
              'Error while selecting Limit Profile At Product Level'|| SUBSTR(
              sqlerrm, 1, 200);
              raise exp_reject_record;
            END;
          WHEN OTHERS THEN
            l_resp_cde := '21';
            l_err_msg  :=
            'Error while selecting Limit Profile At Product Catagory Level' ||
            SUBSTR (sqlerrm, 1, 200);
            raise exp_reject_record;
          END;
        END IF;
        BEGIN
          SELECT
            UPPER(NVL(CPP_PRODUCT_TYPE,'O'))
          INTO
            V_PROD_TYPE
          FROM
            CMS_PRODUCT_PARAM
          WHERE
            CPP_PROD_CODE  =l_prod_code
          AND CPP_INST_CODE=p_instcode_in;
        EXCEPTION
        WHEN OTHERS THEN
          l_resp_cde := '21';
          l_err_msg  := 'Error While selecting the product type' || SUBSTR(
          SQLERRM, 1, 200);
          raise exp_reject_record;
        END;
        BEGIN
          UPDATE
            cms_appl_pan
          SET
            cap_card_stat      ='1',
            cap_acct_no        =l_acct_number,
            CAP_ACCT_ID        =l_acct_id,
            cap_cust_code      =l_cust_code,
            cap_prfl_code      = l_lmtprfl,
            cap_prfl_levl      = l_profile_level,
            cap_active_date    =sysdate,
            cap_firsttime_topup=l_firsttime_topup,
            cap_pin_off=decode(V_PROD_TYPE,'C','0000',cap_pin_off)
          WHERE
            cap_pan_code    = l_hash_topan
          AND cap_inst_code = p_instcode_in;
        EXCEPTION
        WHEN OTHERS THEN
          l_err_msg := 'Error while Updating CMS_APPL_PAN' || SUBSTR(sqlerrm, 1
          , 200);
          l_resp_cde := '21';
          raise exp_reject_record;
        END;
        BEGIN
          sp_log_cardstat_chnge (p_instcode_in, l_hash_topan, l_encr_topan,
          l_auth_id, '01', p_rrn_in, p_trandate_in, p_trantime_in, l_resp_cde,
          l_err_msg );
          IF l_resp_cde <> '00' AND l_err_msg <> 'OK' THEN
            RAISE exp_reject_record;
          END IF;
        EXCEPTION
        WHEN exp_reject_record THEN
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          l_resp_cde := '21';
          l_err_msg  :=
          'Error while logging system initiated card status change ' || SUBSTR
          (SQLERRM, 1, 200);
          raise exp_reject_record;
        END;
        BEGIN
          UPDATE
            cms_appl_mast
          SET
            cam_cust_code = l_cust_code
          WHERE
            cam_appl_code   = l_appl_code
          AND cam_inst_code = p_instcode_in;
          UPDATE
            cms_appl_det
          SET
            cad_acct_id = l_acct_id
          WHERE
            cad_appl_code   = l_appl_code
          AND cad_inst_code = p_instcode_in;
        EXCEPTION
        WHEN exp_reject_record THEN
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          l_resp_cde := '21';
          l_err_msg  := 'Error while logging updating card details ' || SUBSTR
          (SQLERRM, 1, 200);
          raise exp_reject_record;
        END;
        BEGIN
          UPDATE
            cms_appl_pan
          SET
            cap_card_stat ='9'
          WHERE
            cap_pan_code    = l_hash_pan
          AND cap_inst_code = p_instcode_in;
        EXCEPTION
        WHEN OTHERS THEN
          l_err_msg := 'Error while Updating CMS_APPL_PAN' || SUBSTR(sqlerrm, 1
          , 200);
          l_resp_cde := '21';
          raise exp_reject_record;
        END;
        BEGIN
          sp_log_cardstat_chnge (p_instcode_in, l_hash_pan, l_encr_pan,
          l_auth_id, '02', p_rrn_in, p_trandate_in, p_trantime_in, l_resp_cde,
          l_err_msg );
          IF l_resp_cde <> '00' AND l_err_msg <> 'OK' THEN
            RAISE exp_reject_record;
          END IF;
        EXCEPTION
        WHEN exp_reject_record THEN
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          l_resp_cde := '21';
          l_err_msg  :=
          'Error while logging system initiated card status change ' || SUBSTR
          (SQLERRM, 1, 200);
          raise exp_reject_record;
        END;
        SELECT
          CCS_STAT_CODE,
          ccs_stat_desc
        INTO
          p_card_status_out,
          p_card_status_desc_out
        FROM
          cms_card_stat
        WHERE
          CCS_STAT_CODE   ='1'
        AND ccs_inst_code =p_instcode_in;
      END IF;
      BEGIN
        BEGIN
          SELECT
            cam_acct_bal
          INTO
            l_acct_balance
          FROM
            cms_acct_mast
          WHERE
            cam_acct_no     =l_acct_number
          AND cam_inst_code = p_instcode_in;
        EXCEPTION
        WHEN no_data_found THEN
          l_resp_cde := '14'; --Ineligible Transaction
          l_err_msg  := 'Invalid Card ';
          raise exp_reject_record;
        WHEN OTHERS THEN
          l_resp_cde := '12';
          l_err_msg  :=
          'Error while selecting data from card Master for card number ' ||
          sqlerrm;
          raise exp_reject_record;
        END;
        --En find prod code and card type for the card number
        p_errmsg_out    :=l_acct_balance;
        IF l_output_type = 'N' THEN
          NULL;
        END IF;
        --Sn create a record in pan spprt
        --Sn Selecting Reason code for Initial Load
        BEGIN
          SELECT
            csr_spprt_rsncode
          INTO
            l_resoncode
          FROM
            cms_spprt_reasons
          WHERE
            csr_inst_code   = p_instcode_in
          AND csr_spprt_key = 'REISSUE'
          AND rownum        < 2;
        EXCEPTION
        WHEN no_data_found THEN
          l_resp_cde := '21';
          l_err_msg  :=
          'IVR Startercard Replacement reason code is not present in master';
          raise exp_reject_record;
        WHEN OTHERS THEN
          l_resp_cde := '21';
          l_err_msg  := 'Error while selecting reason code from master' ||
          SUBSTR(sqlerrm, 1, 200);
          raise exp_reject_record;
        END;
        BEGIN
          INSERT
          INTO
            cms_pan_spprt
            (
              cps_inst_code,
              cps_pan_code,
              cps_mbr_numb,
              cps_prod_catg,
              cps_spprt_key,
              cps_spprt_rsncode,
              cps_func_remark,
              cps_ins_user,
              cps_lupd_user,
              cps_cmd_mode,
              cps_pan_code_encr
            )
            VALUES
            (
              p_instcode_in,
              l_hash_pan,
              p_mbr_numb_in,
              l_cap_prod_catg,
              'REISSUE',
              l_resoncode,
              p_remrk,
              p_instcode_in,
              p_instcode_in,
              0,
              l_encr_pan
            );
        EXCEPTION
        WHEN OTHERS THEN
          l_resp_cde := '21';
          l_err_msg  :=
          'Error while inserting records into card support master' || SUBSTR(
          sqlerrm, 1, 200);
          raise exp_reject_record;
        END;
        --En create a record in pan spprt
      END;
      p_errmsg_out :=l_acct_balance;
      BEGIN
        SELECT
          cms_iso_respcde
        INTO
          p_resp_code_out
        FROM
          cms_response_mast
        WHERE
          cms_inst_code          = p_instcode_in
        AND cms_delivery_channel = p_delivery_channel_in
        AND cms_response_id      = to_number(l_resp_cde);
      EXCEPTION
      WHEN OTHERS THEN
        l_err_msg :=
        'Problem while selecting data from response master for respose code' ||
        l_resp_cde || SUBSTR(sqlerrm, 1, 300);
        l_resp_cde := '21';
        raise exp_reject_record;
      END;
      BEGIN
	  
	   --Added for VMS-5735/FSP-991
	   
	   v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate_in), 1, 8), 'yyyymmdd');
	  
	   IF (v_Retdate>v_Retperiod) THEN                                 --Added for VMS-5735/FSP-991
	   
			UPDATE
			  transactionlog
			SET
			  ani = p_ani_in,
			  dni = p_dni_in
			WHERE
			  rrn                = p_rrn_in
			AND business_date    = p_trandate_in
			AND txn_code         = p_txn_code_in
			AND msgtype          = p_msg_type_in
			AND business_time    = p_trantime_in
			AND delivery_channel = p_delivery_channel_in;
			
		ELSE
		
			UPDATE
			  VMSCMS_HISTORY.TRANSACTIONLOG_HIST                       --Added for VMS-5735/FSP-991
			SET
			  ani = p_ani_in,
			  dni = p_dni_in
			WHERE
			  rrn                = p_rrn_in
			AND business_date    = p_trandate_in
			AND txn_code         = p_txn_code_in
			AND msgtype          = p_msg_type_in
			AND business_time    = p_trantime_in
			AND delivery_channel = p_delivery_channel_in;	
		
		END IF;
      EXCEPTION
      WHEN OTHERS THEN
        l_resp_cde := '69';
        l_err_msg  := 'Problem while inserting data into transaction log' ||
        SUBSTR(sqlerrm, 1, 300);
        raise exp_reject_record;
      END;
    END IF;
  END;
EXCEPTION
  --<< MAIN EXCEPTION >>
WHEN exp_reject_record THEN
  p_errmsg_out := l_err_msg;
  ROLLBACK TO l_auth_savepoint;
  BEGIN
    
	IF (v_Retdate>v_Retperiod) THEN                                 --Added for VMS-5735/FSP-991
	
		UPDATE
		  transactionlog
		SET
		  ani = p_ani_in,
		  dni =p_dni_in
		WHERE
		  rrn                = p_rrn_in
		AND business_date    = p_trandate_in
		AND txn_code         = p_txn_code_in
		AND msgtype          = p_msg_type_in
		AND business_time    = p_trantime_in
		AND delivery_channel = p_delivery_channel_in;
	
	ELSE
	
		UPDATE
		  VMSCMS_HISTORY.TRANSACTIONLOG_HIST                   --Added for VMS-5733/FSP-991
		SET
		  ani = p_ani_in,
		  dni =p_dni_in
		WHERE
		  rrn                = p_rrn_in
		AND business_date    = p_trandate_in
		AND txn_code         = p_txn_code_in
		AND msgtype          = p_msg_type_in
		AND business_time    = p_trantime_in
		AND delivery_channel = p_delivery_channel_in;
		
	
	END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_resp_cde := '69';
    l_err_msg  := 'Problem while inserting data into transaction log  dtl' ||
    SUBSTR(sqlerrm, 1, 300);
    RAISE exp_reject_record;
  END;
  BEGIN
    SELECT
      cam_acct_bal,
      cam_ledger_bal
    INTO
      l_acct_balance,
      l_ledger_bal
    FROM
      cms_acct_mast
    WHERE
      cam_acct_no     =l_acct_number
    AND cam_inst_code = p_instcode_in;
  EXCEPTION
  WHEN no_data_found THEN
    l_resp_cde := '14'; --Ineligible Transaction
    l_err_msg  := 'Invalid Card ';
    raise exp_reject_record;
  WHEN OTHERS THEN
    l_resp_cde := '12';
    l_err_msg  :=
    'Error while selecting data from card Master for card number ' || sqlerrm;
    raise exp_reject_record;
  END;
  --Sn select response code and insert record into txn log dtl
  BEGIN
    p_errmsg_out := l_err_msg;
    -- Assign the response code to the out parameter
    SELECT
      cms_iso_respcde
    INTO
      p_resp_code_out
    FROM
      cms_response_mast
    WHERE
      cms_inst_code          = p_instcode_in
    AND cms_delivery_channel = p_delivery_channel_in
    AND cms_response_id      = l_resp_cde;
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg_out := 'Problem while selecting data from response master ' ||
    l_resp_cde || SUBSTR(sqlerrm, 1, 300);
    p_resp_code_out := '69';
    ---ISO MESSAGE FOR DATABASE ERROR Server Declined
    ROLLBACK;
  END;
  BEGIN
    INSERT
    INTO
      cms_transaction_log_dtl
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
        p_delivery_channel_in,
        p_txn_code_in,
        l_txn_type,
        p_msg_type_in,
        0,
        p_trandate_in,
        p_trantime_in,
        l_hash_pan,
        NULL,
        p_currcode_in,
        l_tran_amt,
        NULL,
        NULL,
        NULL,
        NULL,
        l_total_amt,
        l_card_curr,
        'E',
        l_err_msg,
        p_rrn_in,
        NULL,
        p_instcode_in,
        l_encr_pan,
        l_acct_number
      );
    p_errmsg_out := l_err_msg;
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg_out := 'Problem while inserting data into transaction log  dtl' ||
    SUBSTR(sqlerrm, 1, 300);
    p_resp_code_out := '69'; -- Server Declined
    ROLLBACK;
    RETURN;
  END;
  l_timestamp             := systimestamp;
  IF l_prod_code          IS NULL OR l_prod_cattype IS NULL OR l_applpan_cardstat IS
    NULL OR l_acct_number IS NULL THEN
    BEGIN
      SELECT
        cap_prod_code,
        cap_card_type,
        cap_card_stat,
        cap_acct_no
      INTO
        l_prod_code,
        l_prod_cattype,
        l_applpan_cardstat,
        l_acct_number
      FROM
        cms_appl_pan
      WHERE
        cap_inst_code  = p_instcode_in
      AND cap_pan_code = l_hash_pan;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  IF l_dr_cr_flag IS NULL THEN
    BEGIN
      SELECT
        ctm_credit_debit_flag
      INTO
        l_dr_cr_flag
      FROM
        cms_transaction_mast
      WHERE
        ctm_tran_code          = p_txn_code_in
      AND ctm_delivery_channel = p_delivery_channel_in
      AND ctm_inst_code        = p_instcode_in;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  BEGIN
    INSERT
    INTO
      transactionlog
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
        addcharge,
        productid,
        categoryid,
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
        tranfee_amt,
        servicetax_amt,
        cess_amt,
        cr_dr_flag,
        tranfee_cr_acctno,
        tranfee_dr_acctno,
        tran_st_calc_flag,
        tran_cess_calc_flag,
        tran_st_cr_acctno,
        tran_st_dr_acctno,
        tran_cess_cr_acctno,
        tran_cess_dr_acctno,
        customer_card_no_encr,
        topup_card_no_encr,
        proxy_number,
        reversal_code,
        customer_acct_no,
        acct_balance,
        ledger_balance,
        response_id,
        ani,
        dni,
        cardstatus,
        fee_plan,
        csr_achactiontaken,
        error_msg,
        processes_flag,
        acct_type,
        time_stamp
      )
      VALUES
      (
        p_msg_type_in,
        p_rrn_in,
        p_delivery_channel_in,
        0,
        l_business_date,
        p_txn_code_in,
        l_txn_type,
        0,
        DECODE(p_resp_code_out, '00', 'C', 'F'),
        p_resp_code_out,
        p_trandate_in,
        SUBSTR(p_trantime_in, 1, 10),
        l_hash_pan,
        NULL,
        NULL,
        NULL,
        p_instcode_in,
        trim(TO_CHAR(NVL(l_total_amt,0), '99999999999999990.99')),
        '',
        '',
        NULL,
        p_currcode_in,
        NULL,
        l_prod_code,
        l_prod_cattype,
        0,
        '',
        '',
        l_auth_id,
        l_narration,
        trim(TO_CHAR(NVL(l_tran_amt,0), '99999999999999990.99')),
        '0.00',
        '0.00',
        '',
        '',
        '',
        '',
        '',
        l_gl_upd_flag,
        NULL,
        p_instcode_in,
        l_fee_code,
        NVL(l_fee_amt,0),
        NVL(l_servicetax_amount,0),
        NVL(l_cess_amount,0),
        l_dr_cr_flag,
        l_fee_cracct_no,
        l_fee_dracct_no,
        l_st_calc_flag,
        l_cess_calc_flag,
        l_st_cracct_no,
        l_st_dracct_no,
        l_cess_cracct_no,
        l_cess_dracct_no,
        l_encr_pan,
        NULL,
        l_proxy_number,
        p_rvsl_code_in,
        l_acct_number,
        NVL(l_acct_balance,0),
        NVL(l_ledger_bal,0),
        l_resp_cde,
        p_ani_in,
        p_dni_in,
        l_applpan_cardstat,
        l_fee_plan,
        NULL,
        l_err_msg,
        'E',
        l_cam_type_code,
        l_timestamp
      );
    l_capture_date := l_business_date;
  EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    p_resp_code_out := '69';
    p_errmsg_out    := 'Problem while inserting data into transaction log  ' ||
    SUBSTR(sqlerrm, 1, 300);
    RETURN;
  END;
  --En create a entry in txn log
WHEN OTHERS THEN
  ROLLBACK TO l_auth_savepoint;
  BEGIN
    SELECT
      cam_acct_bal,
      cam_ledger_bal,
      cam_type_code,
      cam_acct_no
    INTO
      l_acct_balance,
      l_ledger_bal,
      l_cam_type_code,
      l_acct_number
    FROM
      cms_acct_mast
    WHERE
      cam_acct_no     =l_acct_number
    AND cam_inst_code = p_instcode_in;
  EXCEPTION
  WHEN OTHERS THEN
    l_acct_balance := 0;
    l_ledger_bal   := 0;
  END;
  --Sn select response code and insert record into txn log dtl
  BEGIN
    SELECT
      cms_iso_respcde
    INTO
      p_resp_code_out
    FROM
      cms_response_mast
    WHERE
      cms_inst_code          = p_instcode_in
    AND cms_delivery_channel = p_delivery_channel_in
    AND cms_response_id      = l_resp_cde;
    p_errmsg_out            := l_err_msg;
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg_out := 'Problem while selecting data from response master ' ||
    l_resp_cde || SUBSTR(sqlerrm, 1, 300);
    p_resp_code_out := '69'; -- Server Declined
    ROLLBACK;
    -- RETURN;
  END;
  BEGIN
    INSERT
    INTO
      cms_transaction_log_dtl
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
        p_delivery_channel_in,
        p_txn_code_in,
        l_txn_type,
        p_msg_type_in,
        0,
        p_trandate_in,
        p_trantime_in,
        l_hash_pan,
        NULL,
        p_currcode_in,
        l_tran_amt,
        NULL,
        NULL,
        NULL,
        NULL,
        l_total_amt,
        l_card_curr,
        'E',
        l_err_msg,
        p_rrn_in,
        NULL,
        p_instcode_in,
        l_encr_pan,
        l_acct_number
      );
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg_out := 'Problem while inserting data into transaction log  dtl' ||
    SUBSTR(sqlerrm, 1, 300);
    p_resp_code_out := '69'; -- Server Decline Response 220509
    ROLLBACK;
    RETURN;
  END;
  --En select response code and insert record into txn log dtl
  l_timestamp             := systimestamp;
  IF l_prod_code          IS NULL OR l_prod_cattype IS NULL OR l_applpan_cardstat IS
    NULL OR l_acct_number IS NULL THEN
    BEGIN
      SELECT
        cap_prod_code,
        cap_card_type,
        cap_card_stat,
        cap_acct_no
      INTO
        l_prod_code,
        l_prod_cattype,
        l_applpan_cardstat,
        l_acct_number
      FROM
        cms_appl_pan
      WHERE
        cap_inst_code  = p_instcode_in
      AND cap_pan_code = l_hash_pan;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  IF l_dr_cr_flag IS NULL THEN
    BEGIN
      SELECT
        ctm_credit_debit_flag
      INTO
        l_dr_cr_flag
      FROM
        cms_transaction_mast
      WHERE
        ctm_tran_code          = p_txn_code_in
      AND ctm_delivery_channel = p_delivery_channel_in
      AND ctm_inst_code        = p_instcode_in;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  --Sn create a entry in txn log
  BEGIN
    INSERT
    INTO
      transactionlog
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
        addcharge,
        productid,
        categoryid,
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
        tranfee_amt,
        servicetax_amt,
        cess_amt,
        cr_dr_flag,
        tranfee_cr_acctno,
        tranfee_dr_acctno,
        tran_st_calc_flag,
        tran_cess_calc_flag,
        tran_st_cr_acctno,
        tran_st_dr_acctno,
        tran_cess_cr_acctno,
        tran_cess_dr_acctno,
        customer_card_no_encr,
        topup_card_no_encr,
        proxy_number,
        reversal_code,
        customer_acct_no,
        acct_balance,
        ledger_balance,
        response_id,
        ani,
        dni,
        cardstatus,
        fee_plan,
        csr_achactiontaken,
        error_msg,
        processes_flag,
        acct_type,
        time_stamp
      )
      VALUES
      (
        p_msg_type_in,
        p_rrn_in,
        p_delivery_channel_in,
        0,
        l_business_date,
        p_txn_code_in,
        l_txn_type,
        0,
        DECODE(p_resp_code_out, '00', 'C', 'F'),
        p_resp_code_out,
        p_trandate_in,
        SUBSTR(p_trantime_in, 1, 10),
        l_hash_pan,
        NULL,
        NULL,
        NULL,
        p_instcode_in,
        trim(TO_CHAR(NVL(l_total_amt,0), '99999999999999999.99')),
        '',
        '',
        NULL,
        p_currcode_in,
        NULL,
        l_prod_code,
        l_prod_cattype,
        0,
        '',
        '',
        l_auth_id,
        l_narration,
        trim(TO_CHAR(NVL(l_tran_amt,0), '99999999999999999.99')),
        '0.00',
        '0.00',
        '',
        '',
        '',
        '',
        '',
        l_gl_upd_flag,
        NULL,
        p_instcode_in,
        l_fee_code,
        NVL(l_fee_amt,0),
        NVL(l_servicetax_amount,0),
        NVL(l_cess_amount,0),
        l_dr_cr_flag,
        l_fee_cracct_no,
        l_fee_dracct_no,
        l_st_calc_flag,
        l_cess_calc_flag,
        l_st_cracct_no,
        l_st_dracct_no,
        l_cess_cracct_no,
        l_cess_dracct_no,
        l_encr_pan,
        NULL,
        l_proxy_number,
        p_rvsl_code_in,
        l_acct_number,
        NVL(l_acct_balance,0),
        NVL(l_ledger_bal,0),
        l_resp_cde,
        p_ani_in,
        p_dni_in,
        l_applpan_cardstat,
        l_fee_plan,
        NULL,
        l_err_msg,
        'E',
        l_cam_type_code,
        l_timestamp
      );
    l_capture_date := l_business_date;
  EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    p_resp_code_out := '69';
    p_errmsg_out    := 'Problem while inserting data into transaction log  ' ||
    SUBSTR(sqlerrm, 1, 300);
    RETURN;
  END;
END startercard_replacement;
END;
/
show error