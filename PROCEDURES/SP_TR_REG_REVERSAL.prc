create or replace PROCEDURE        VMSCMS.sp_tr_reg_reversal (
   p_inst_code       IN       NUMBER,
   p_msg_typ         IN       VARCHAR2,
   p_rvsl_code       IN       VARCHAR2,
   p_rrn             IN       VARCHAR2,
   p_delv_chnl       IN       VARCHAR2,
   p_terminal_id     IN       VARCHAR2,
   p_txn_code        IN       VARCHAR2,
   p_txn_type        IN       VARCHAR2,
   p_txn_mode        IN       VARCHAR2,
   p_business_date   IN       VARCHAR2,
   p_business_time   IN       VARCHAR2,
   p_card_no         IN       VARCHAR2,
   p_mbr_numb        IN       VARCHAR2,
   p_curr_code       IN       VARCHAR2,
   p_merchant_name   IN       VARCHAR2,
   p_merchant_city   IN       VARCHAR2,
   p_resp_cde        OUT      VARCHAR2,
   p_resp_msg        OUT      VARCHAR2,
   p_dda_number      OUT      VARCHAR2
)
IS
   /**************************************************************************************************
       * Created by       :  Pankaj S.
       * Reason           :  SPIL Target registration reversal
       * Created Date     :  17-Sep-2013
       * Reviewer         :  Dhiraj
       * Reviewed Date    :
       * Build Number     :  RI0024.4_B0016

       * MOdified by      :  Pankaj S.
       * Reason           :  To handle currncy code
       * Created Date     :  20-Sep-2013
       * Reviewer         :  Dhiraj
       * Reviewed Date    :
       * Build Number     :  RI0024.4_B0017

       * Modified by     : Pankaj S.
      * Reason           : Review observations changes
      * Created Date     : 25-Sep-2013
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : RI0024.4_B0018

      * Modified by      : MageshKumar S.
      * Modified Date    : 25-July-14
      * Modified For     : FWR-48
      * Modified reason  : GL Mapping removal changes
      * Reviewer         : Spankaj
      * Build Number     : RI0027.3.1_B0001

	  * Modified By      : Saravana Kumar A
	  * Modified Date    : 24-DEC-2021
	  * Purpose          : VMS-5378 : Need to update ccm_system_generate_profile flag in Retail / Card stock flow.
	  * Reviewer         : Venkat S
	  * Release Number   : VMSGPRHOST_R56 Build 3
   *****************************************************************************************************/
   v_orgnl_delivery_channel     transactionlog.delivery_channel%TYPE;
   v_orgnl_resp_code            transactionlog.response_code%TYPE;
   v_orgnl_txn_code             transactionlog.txn_code%TYPE;
   v_orgnl_txn_mode             transactionlog.txn_mode%TYPE;
   v_orgnl_business_date        transactionlog.business_date%TYPE;
   v_orgnl_business_time        transactionlog.business_time%TYPE;
   v_orgnl_total_amount         transactionlog.amount%TYPE;
   v_actual_amt                 NUMBER (9, 2);
   v_reversal_amt               NUMBER (9, 2);
   v_orgnl_txn_totalfee_amt     transactionlog.tranfee_amt%TYPE;
   v_orgnl_transaction_type     transactionlog.cr_dr_flag%TYPE;
   v_actual_dispatched_amt      transactionlog.amount%TYPE;
   v_resp_cde                   VARCHAR2 (3);
   v_func_code                  cms_func_mast.cfm_func_code%TYPE;
   v_dr_cr_flag                 transactionlog.cr_dr_flag%TYPE;
   v_orgnl_trandate             DATE;
   v_rvsl_trandate              DATE;
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
   v_tran_sysdate               DATE;
   v_tran_cutoff                DATE;
   v_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
   v_tran_amt                   NUMBER;
   v_card_curr                  VARCHAR2 (5);
   v_rrn_count                  NUMBER;
   v_base_curr                  cms_inst_param.cip_param_value%TYPE;
   v_currcode                   VARCHAR2 (3);
   v_acct_balance               NUMBER;
   v_ledger_balance             NUMBER;
   v_tran_desc                  cms_transaction_mast.ctm_tran_desc%TYPE;
   v_tran_count                 NUMBER;
   v_cust_code                  cms_cust_mast.ccm_cust_code%TYPE;
   V_ADDR_LINEONE               CMS_CARDPROFILE_HIST.CCP_ADD_ONE%type;
   V_ADDR_LINETWO               CMS_CARDPROFILE_HIST.CCP_ADD_TWO%type;
   V_CITY_NAME                  CMS_CARDPROFILE_HIST.CCP_CITY_NAME%type;
   V_PIN_CODE                   CMS_CARDPROFILE_HIST.CCP_PIN_CODE%type;
   V_PHONE_NO                   CMS_CARDPROFILE_HIST.CCP_PHONE_ONE%type;
   V_MOBL_NO                    CMS_CARDPROFILE_HIST.CCP_MOBL_ONE%type;
   V_EMAIL                      CMS_CARDPROFILE_HIST.CCP_EMAIL%type;
   v_state_code                 NUMBER (3);
   v_ctnry_code                 NUMBER (3);
   v_ssn                        VARCHAR2 (10);
   v_birth_date                 DATE;
   V_FIRST_NAME                 CMS_CARDPROFILE_HIST.CCP_FIRST_NAME%type;
   V_MID_NAME                   CMS_CARDPROFILE_HIST.CCP_MID_NAME%type;
   V_LAST_NAME                  CMS_CARDPROFILE_HIST.CCP_LAST_NAME%type;
   v_orgnl_txn_business_date    transactionlog.business_date%TYPE;
   v_orgnl_txn_business_time    transactionlog.business_time%TYPE;
   v_orgnl_txn_rrn              transactionlog.rrn%TYPE;
   v_orgnl_txn_terminalid       transactionlog.terminal_id%TYPE;
   v_business_date_tran         DATE;
   v_proxunumber                cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number                cms_appl_pan.cap_acct_no%TYPE;
   v_resoncode                  cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   p_remrk                      VARCHAR2 (100);
   v_cap_prod_catg              cms_appl_pan.cap_prod_catg%TYPE;
   v_authid_date                VARCHAR2 (8);
   v_txn_narration              cms_statements_log.csl_trans_narrration%TYPE:=NULL;
   v_fee_narration              cms_statements_log.csl_trans_narrration%TYPE:=NULL;
   v_applpan_cardstat           transactionlog.cardstatus%TYPE;
   v_txn_merchname              cms_statements_log.csl_merchant_name%TYPE;
   v_fee_merchname              cms_statements_log.csl_merchant_name%TYPE;
   v_txn_merchcity              cms_statements_log.csl_merchant_city%TYPE;
   v_fee_merchcity              cms_statements_log.csl_merchant_city%TYPE;
   v_txn_merchstate             cms_statements_log.csl_merchant_state%TYPE;
   v_fee_merchstate             cms_statements_log.csl_merchant_state%TYPE;
   v_fee_plan_id                cms_card_excpfee_hist.cce_fee_plan%TYPE;
   v_cap_appl_code              cms_appl_pan.cap_appl_code%TYPE;
   v_merv_count                 NUMBER;
   v_cap_acct_id                cms_appl_pan.cap_acct_id%TYPE;
   v_starter_chk                NUMBER (3);
   v_gpr_pan                    cms_appl_pan.cap_pan_code%TYPE;
   v_gpr_chk                    VARCHAR2 (1);
   v_cam_type_code              cms_acct_mast.cam_type_code%TYPE;
   v_timestamp                  TIMESTAMP;
   v_txn_type                   NUMBER (1);
   v_fee_plan                   cms_fee_plan.cfp_plan_id%TYPE;
   v_fee_amt                    NUMBER;
   v_fee_code                   cms_fee_mast.cfm_fee_code%TYPE;
   v_feeattach_type             VARCHAR2 (2);
   v_cmm_inst_code              cms_merinv_merpan.cmm_inst_code%type;
   v_cmm_mer_id                 cms_merinv_merpan.cmm_mer_id%type;
   v_cmm_location_id            cms_merinv_merpan.cmm_location_id%type;
   v_cmm_merprodcat_id          cms_merinv_merpan.cmm_merprodcat_id%type;
   v_firsttime_topup            cms_appl_pan.cap_firsttime_topup%TYPE;
   V_SYSTEM_GENERATED_PROFILE	cms_cust_mast.CCM_SYSTEM_GENERATED_PROFILE%TYPE;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
   p_resp_cde := '00';
   p_resp_msg := 'OK';
   p_remrk := 'TARGET REG REVERSAL';
   --v_tran_amt := 0;
   SAVEPOINT v_savepoint;
   v_errmsg := 'OK';

   --Sn Create hash pan
   BEGIN
      v_hash_pan := gethash (p_card_no);
   EXCEPTION
      WHEN OTHERS THEN
         v_errmsg := 'Error while converting pan to HASH ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En Create hash pan

   --Sn create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_card_no);
   EXCEPTION
      WHEN OTHERS THEN
         v_errmsg := 'Error while converting pan to ENCR ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --Sn create encr pan

   --Sn get date
   BEGIN
      v_rvsl_trandate := TO_DATE (   SUBSTR (TRIM (p_business_date), 1, 8) || ' ' || SUBSTR (TRIM (p_business_time), 1, 10), 'yyyymmdd hh24:mi:ss' );
   EXCEPTION
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg := 'Problem while converting transaction date '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En get date

   --Sn generate auth id
   BEGIN
      SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
        INTO v_auth_id
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS THEN
         v_errmsg :='Error while generating authid ' || SUBSTR (SQLERRM, 1, 200);
         v_resp_cde := '21';
         RAISE exp_rvsl_reject_record;
   END;
   --En generate auth id

   --Sn Get txn details
   BEGIN
      SELECT ctm_credit_debit_flag, ctm_tran_desc,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1'))
        INTO v_dr_cr_flag, v_tran_desc,
             v_txn_type
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delv_chnl
         AND ctm_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_resp_cde := '69';
         v_errmsg :='Transaction detail is not found in master for orginal txn code '|| p_txn_code|| 'delivery channel '|| p_delv_chnl;
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Problem while selecting txn details '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En Get txn details

--   --Sn Duplicate RRN Check
--   BEGIN
--      SELECT COUNT (1)
--        INTO v_rrn_count
--        FROM transactionlog
--       WHERE terminal_id = p_terminal_id
--         AND rrn = p_rrn
--         AND business_date = p_business_date
--         AND delivery_channel = p_delv_chnl;

--      IF v_rrn_count > 0 THEN
--         v_resp_cde := '22';
--         v_errmsg := 'Duplicate RRN from the Treminal '|| p_terminal_id|| ' on '|| p_business_date;
--         RAISE exp_rvsl_reject_record;
--      END IF;
--   EXCEPTION
--      WHEN exp_rvsl_reject_record THEN
--         RAISE;
--      WHEN OTHERS THEN
--         v_resp_cde := '21';
--         v_errmsg :='Error while checking duplicate RRN-'|| SUBSTR (SQLERRM, 1, 200);
--         RAISE exp_rvsl_reject_record;
--   END;
--   --En Duplicate RRN Check

   --Sn currncy check
    BEGIN
       SELECT gcm_curr_code
         INTO v_currcode
         FROM gen_curr_mast
        WHERE gcm_curr_name = p_curr_code AND gcm_inst_code = p_inst_code;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          v_resp_cde := '65';
          v_errmsg := 'Invalid Currency Code';
          RAISE exp_rvsl_reject_record;
       WHEN OTHERS
       THEN
          v_resp_cde := '21';
          v_errmsg :='Error while selecting the currency code for '|| p_curr_code|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
    END;
   --En currncy check

   --Sn check msg type
   IF    (p_msg_typ NOT IN ('0400', '0410', '0420', '0430')) OR (p_rvsl_code = '00') THEN
      v_resp_cde := '12';
      v_errmsg := 'Not a valid reversal request';
      RAISE exp_rvsl_reject_record;
   END IF;
   --En check msg type

   --Sn check orginal transaction
   BEGIN
    SELECT business_time,business_date,
           rrn,terminal_id,
           delivery_channel, response_code, txn_code,
           txn_mode, business_date, business_time,
           amount, cr_dr_flag, feecode,
           tranfee_amt, servicetax_amt, cess_amt,
           tranfee_cr_acctno, tranfee_dr_acctno,
           tran_st_calc_flag, tran_cess_calc_flag, tran_st_cr_acctno,
           tran_st_dr_acctno, tran_cess_cr_acctno, tran_cess_dr_acctno,
           currencycode, tran_reverse_flag, gl_upd_flag
      INTO v_orgnl_txn_business_time, v_orgnl_txn_business_date,
           v_orgnl_txn_rrn, v_orgnl_txn_terminalid,
           v_orgnl_delivery_channel, v_orgnl_resp_code, v_orgnl_txn_code,
           v_orgnl_txn_mode, v_orgnl_business_date, v_orgnl_business_time,
           v_orgnl_total_amount, v_orgnl_transaction_type, v_actual_feecode,
           v_orgnl_tranfee_amt, v_orgnl_servicetax_amt, v_orgnl_cess_amt,
           v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,
           v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag, v_orgnl_st_cr_acctno,
           v_orgnl_st_dr_acctno, v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno,
           v_curr_code, v_tran_reverse_flag, v_gl_upd_flag
      FROM VMSCMS.transactionlog
     WHERE rrn = p_rrn--v_orgnl_txn_rrn
       --AND business_date = v_orgnl_txn_business_date
       --AND business_time = v_orgnl_txn_business_time
       AND customer_card_no = v_hash_pan
       AND instcode = p_inst_code
       AND msgtype ='0200'
       AND txn_code='32'
       AND delivery_channel = p_delv_chnl;
      -- AND terminal_id = v_orgnl_txn_terminalid;
	  IF SQL%ROWCOUNT=0 THEN
	  SELECT business_time,business_date,
           rrn,terminal_id,
           delivery_channel, response_code, txn_code,
           txn_mode, business_date, business_time,
           amount, cr_dr_flag, feecode,
           tranfee_amt, servicetax_amt, cess_amt,
           tranfee_cr_acctno, tranfee_dr_acctno,
           tran_st_calc_flag, tran_cess_calc_flag, tran_st_cr_acctno,
           tran_st_dr_acctno, tran_cess_cr_acctno, tran_cess_dr_acctno,
           currencycode, tran_reverse_flag, gl_upd_flag
      INTO v_orgnl_txn_business_time, v_orgnl_txn_business_date,
           v_orgnl_txn_rrn, v_orgnl_txn_terminalid,
           v_orgnl_delivery_channel, v_orgnl_resp_code, v_orgnl_txn_code,
           v_orgnl_txn_mode, v_orgnl_business_date, v_orgnl_business_time,
           v_orgnl_total_amount, v_orgnl_transaction_type, v_actual_feecode,
           v_orgnl_tranfee_amt, v_orgnl_servicetax_amt, v_orgnl_cess_amt,
           v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,
           v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag, v_orgnl_st_cr_acctno,
           v_orgnl_st_dr_acctno, v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno,
           v_curr_code, v_tran_reverse_flag, v_gl_upd_flag
      FROM VMSCMS_HISTORY.transactionlog_HIST
     WHERE rrn = p_rrn--v_orgnl_txn_rrn
       --AND business_date = v_orgnl_txn_business_date
       --AND business_time = v_orgnl_txn_business_time
       AND customer_card_no = v_hash_pan
       AND instcode = p_inst_code
       AND msgtype ='0200'
       AND txn_code='32'
       AND delivery_channel = p_delv_chnl;
      -- AND terminal_id = v_orgnl_txn_terminalid;
	  END IF;

      IF v_orgnl_resp_code <> '00' THEN
         v_resp_cde := '23';
         v_errmsg := ' The original transaction was not successful';
         RAISE exp_rvsl_reject_record;
      END IF;

      IF v_tran_reverse_flag = 'Y' THEN
         v_resp_cde := '52';
         v_errmsg := 'The reversal already done for the orginal transaction';
         RAISE exp_rvsl_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_rvsl_reject_record THEN
         RAISE;
      WHEN NO_DATA_FOUND THEN
         v_resp_cde := '53';
         v_errmsg := 'Matching transaction not found';
         RAISE exp_rvsl_reject_record;
      WHEN TOO_MANY_ROWS THEN
         v_resp_cde := '23';
         v_errmsg := 'More than one matching record found in the master';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Error while selecting master data ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En check orginal transaction

   --Sn Convert Original Txn date
   BEGIN
      v_orgnl_trandate := TO_DATE (SUBSTR (TRIM (v_orgnl_txn_business_date), 1, 8)|| ' '|| SUBSTR (TRIM (v_orgnl_txn_business_time), 1, 8),'yyyymmdd hh24:mi:ss');
   EXCEPTION
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Problem while converting Original transaction date '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En Convert Original Txn date

   --Sn Check for the txns using this card after card Activation
--   BEGIN
--      SELECT COUNT (*)
--        INTO v_tran_count
--        FROM transactionlog
--       WHERE customer_card_no = v_hash_pan
--         AND response_code = '00'
--         AND txn_code = '30'
--         AND delivery_channel = '08';

--      IF v_tran_count = 0 THEN
--         v_resp_cde := '28';
--         v_errmsg :='Card Activation Reversal Cannot be done. Target Activation Not done in SPIL';
--         RAISE exp_rvsl_reject_record;
--      END IF;
--   EXCEPTION
--   WHEN exp_rvsl_reject_record THEN
--     RAISE;
--   WHEN OTHERS THEN
--     v_resp_cde := '21';
--     v_errmsg :='Problem while checking activation txn '|| SUBSTR (SQLERRM, 1, 200);
--     RAISE exp_rvsl_reject_record;
--   END;
   --En Check for the txns using this card after card Activation

  --Sn Get card details
   BEGIN
      SELECT cap_prod_code, cap_prod_catg, cap_card_type, cap_cust_code,
             cap_proxy_number, cap_acct_no, cap_card_stat,
             cap_appl_code, cap_acct_id,cap_firsttime_topup
        INTO v_prod_code, v_cap_prod_catg, v_card_type, v_cust_code,
             v_proxunumber, v_acct_number, v_applpan_cardstat,
             v_cap_appl_code, v_cap_acct_id,v_firsttime_topup
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '6';
         v_errmsg := 'Invalid card';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
             'Error while retriving card detail ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En Get card details

   --Sn Getting the details of Card Activation Txn.Original txn details are not present in request
   BEGIN
      SELECT z.ccp_add_one,z.ccp_add_two, z.ccp_city_name, z.ccp_pin_code,
             z.ccp_phone_one, z.ccp_mobl_one, z.ccp_email, z.ccp_state_code,
             z.ccp_cntry_code, z.ccp_ssn, z.ccp_birth_date,
             z.ccp_first_name, z.ccp_mid_name, z.ccp_last_name
        INTO v_addr_lineone, v_addr_linetwo, v_city_name, v_pin_code,
             v_phone_no, v_mobl_no, v_email, v_state_code,
             v_ctnry_code, v_ssn, v_birth_date,
             v_first_name, v_mid_name, v_last_name
        FROM (SELECT  ccp_add_one, ccp_add_two,
                       ccp_city_name, ccp_pin_code, ccp_phone_one,
                       ccp_mobl_one, ccp_email, ccp_state_code,
                       ccp_cntry_code, ccp_ssn, ccp_birth_date,
                       ccp_first_name, ccp_mid_name, ccp_last_name
                  FROM cms_cardprofile_hist
                 WHERE ccp_pan_code = v_hash_pan
                   AND ccp_inst_code = p_inst_code
                   AND ccp_mbr_numb = p_mbr_numb
              ORDER BY ccp_ins_date DESC) z
       WHERE ROWNUM = 1;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_resp_cde := '69';
         v_errmsg := 'No Card Activation has done';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg := 'Error while getting the activation details '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --Sn Getting the details of Card Activation Txn.Original txn details are not present in request

  -- IF v_firsttime_topup='Y' THEN
   --Sn find the converted tran amt
   /*IF (v_tran_amt >= 0) THEN
      BEGIN
         sp_convert_curr (p_inst_code,
                          v_currcode,
                          p_card_no,
                          v_tran_amt,
                          v_rvsl_trandate,
                          v_tran_amt,
                          v_card_curr,
                          v_errmsg
                         );

         IF v_errmsg <> 'OK' THEN
            v_resp_cde := '69';
            RAISE exp_rvsl_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_rvsl_reject_record THEN
            RAISE;
         WHEN OTHERS THEN
            v_resp_cde := '21';
            v_errmsg :='Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_rvsl_reject_record;
      END;
   ELSE
      v_resp_cde := '43';
      v_errmsg := 'INVALID AMOUNT';
      RAISE exp_rvsl_reject_record;
   END IF;
   --En find the  converted tran amt

   --Sn check amount with orginal transaction
   IF (v_tran_amt IS NULL OR v_tran_amt = 0) THEN
      v_actual_dispatched_amt := 0;
   ELSE
      v_actual_dispatched_amt := v_tran_amt;
   END IF;
   --En check amount with orginal transaction*/

   v_reversal_amt := v_orgnl_total_amount; --v_actual_dispatched_amt; --Review observations changes

    --Sn Commented for review observations
--   IF v_dr_cr_flag = 'NA' THEN
--      v_resp_cde := '69';
--      v_errmsg := 'Not a valid orginal transaction for reversal';
--      RAISE exp_rvsl_reject_record;
--   END IF;
   --En Commented for review observations

--   IF v_dr_cr_flag <> v_orgnl_transaction_type THEN
--      v_resp_cde := '69';
--      v_errmsg :='Orginal transaction type is not matching with actual transaction type';
--      RAISE exp_rvsl_reject_record;
--   END IF;


   --Sn - commented for fwr-48
   --Sn find the orginal func code
 /*  BEGIN
      SELECT cfm_func_code
        INTO v_func_code
        FROM cms_func_mast
       WHERE cfm_txn_code = v_orgnl_txn_code
         AND cfm_txn_mode = v_orgnl_txn_mode
         AND cfm_delivery_channel = v_orgnl_delivery_channel
         AND cfm_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_resp_cde := '69';
         v_errmsg := 'Function code not defined for txn code ' || p_txn_code;
         RAISE exp_rvsl_reject_record;
      WHEN TOO_MANY_ROWS THEN
         v_resp_cde := '69';
         v_errmsg :='More than one function defined for txn code ' || p_txn_code;
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Problem while selecting function code from function mast  '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;*/
   --En find the orginal func code

   --En - commented for fwr-48

   --Sn find cutoff time
   BEGIN
      SELECT cip_param_value
        INTO v_cutoff_time
        FROM cms_inst_param
       WHERE cip_param_key = 'CUTOFF' AND cip_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_cutoff_time := 0;
         v_resp_cde := '69';
         v_errmsg := 'Cutoff time is not defined in the system';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg := 'Error while selecting cutoff  dtl  from system ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En find cutoff time

   --Sn find narration  --Modified for Review observations
   BEGIN
   FOR i IN (SELECT csl_trans_narrration, csl_merchant_name,
                    csl_merchant_city, csl_merchant_state, txn_fee_flag
               FROM VMSCMS.cms_statements_log_VW		--VMS-5739/FSP-991
              WHERE csl_business_date = v_orgnl_business_date
                AND csl_business_time = v_orgnl_business_time
                AND csl_rrn = v_orgnl_txn_rrn
                AND csl_delivery_channel = v_orgnl_delivery_channel
                AND csl_txn_code = v_orgnl_txn_code
                AND csl_pan_no = v_hash_pan
                AND csl_inst_code = p_inst_code)
   LOOP
      IF i.txn_fee_flag = 'N'
      THEN
         v_txn_narration := i.csl_trans_narrration;
         v_txn_merchname := i.csl_merchant_name;
         v_txn_merchcity := i.csl_merchant_city;
         v_txn_merchstate := i.csl_merchant_state;
      ELSIF i.txn_fee_flag = 'Y' AND v_orgnl_tranfee_amt > 0
      THEN
         v_fee_narration := i.csl_trans_narrration;
         v_fee_merchname := i.csl_merchant_name;
         v_fee_merchcity := i.csl_merchant_city;
         v_fee_merchstate := i.csl_merchant_state;
      END IF;
   END LOOP;
--      SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
--             csl_merchant_state
--        INTO v_txn_narration, v_txn_merchname, v_txn_merchcity,
--             v_txn_merchstate
--        FROM cms_statements_log
--       WHERE csl_business_date = v_orgnl_business_date
--         AND csl_business_time = v_orgnl_business_time
--         AND csl_rrn = v_orgnl_txn_rrn
--         AND csl_delivery_channel = v_orgnl_delivery_channel
--         AND csl_txn_code = v_orgnl_txn_code
--         AND csl_pan_no = v_hash_pan
--         AND csl_inst_code = p_inst_code
--         AND txn_fee_flag = 'N';

--      IF v_orgnl_tranfee_amt > 0
--      THEN
--         BEGIN
--            SELECT csl_trans_narrration, csl_merchant_name,
--                   csl_merchant_city, csl_merchant_state
--              INTO v_fee_narration, v_fee_merchname,
--                   v_fee_merchcity, v_fee_merchstate
--              FROM cms_statements_log
--             WHERE csl_business_date = v_orgnl_business_date
--               AND csl_business_time = v_orgnl_business_time
--               AND csl_rrn = v_orgnl_txn_rrn
--               AND csl_delivery_channel = v_orgnl_delivery_channel
--               AND csl_txn_code = v_orgnl_txn_code
--               AND csl_pan_no = v_hash_pan
--               AND csl_inst_code = p_inst_code
--               AND txn_fee_flag = 'Y';
--         EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--               v_fee_narration := NULL;
--            WHEN OTHERS THEN
--               v_fee_narration := NULL;
--         END;
--      END IF;
   EXCEPTION
      --WHEN NO_DATA_FOUND THEN
       --  v_txn_narration := NULL;
      WHEN OTHERS THEN
         v_txn_narration := NULL;
         v_fee_narration := NULL;
   END;
   --En find narration  --Modified for Review observations

   --Sn reverse the amount
   BEGIN
      sp_reverse_card_amount (p_inst_code,
                              v_func_code,
                              p_rrn,
                              p_delv_chnl,
                              v_orgnl_txn_terminalid,
                              NULL,
                              p_txn_code,
                              v_rvsl_trandate,
                              p_txn_mode,
                              p_card_no,
                              v_reversal_amt,
                              v_orgnl_txn_rrn,
                              v_acct_number,
                              p_business_date,
                              p_business_time,
                              v_auth_id,
                              v_txn_narration,
                              v_orgnl_business_date,
                              v_orgnl_business_time,
                              v_txn_merchname,
                              v_txn_merchcity,
                              v_txn_merchstate,
                              v_resp_cde,
                              v_errmsg
                             );

      IF v_resp_cde <> '00' OR v_errmsg <> 'OK' THEN
         RAISE exp_rvsl_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_rvsl_reject_record THEN
         RAISE;
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Error while reversing the amount ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   BEGIN
      sp_daily_bin_bal (p_card_no,
                        v_rvsl_trandate,
                        v_reversal_amt,
                        'DR',
                        p_inst_code,
                        '',
                        v_errmsg
                       );
      --Sn Review observation changes
      IF v_errmsg <> 'OK' THEN
         RAISE exp_rvsl_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_rvsl_reject_record THEN
      RAISE;
       --En Review observation changes
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg := 'Error while calling SP_DAILY_BIN_BAL '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En reverse the amount

   --Sn reverse the fee
   BEGIN
      sp_reverse_fee_amount (p_inst_code,
                             p_rrn,
                             p_delv_chnl,
                             v_orgnl_txn_terminalid,
                             NULL,
                             p_txn_code,
                             v_rvsl_trandate,
                             p_txn_mode,
                             v_orgnl_tranfee_amt,
                             p_card_no,
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
                             v_orgnl_txn_rrn,
                             v_acct_number,
                             p_business_date,
                             p_business_time,
                             v_auth_id,
                             v_fee_narration,
                             v_fee_merchname,
                             v_fee_merchcity,
                             v_fee_merchstate,
                             v_resp_cde,
                             v_errmsg
                            );

      IF v_resp_cde <> '00' OR v_errmsg <> 'OK' THEN
         RAISE exp_rvsl_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_rvsl_reject_record THEN
         RAISE;
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Error while reversing the fee amount '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En reverse the fee


   --Sn reverse the GL entries
   IF v_gl_upd_flag = 'Y' THEN
      --Sn find business date
      v_business_time := TO_CHAR (v_rvsl_trandate, 'HH24:MI');

      IF v_business_time > v_cutoff_time
      THEN
         v_rvsl_trandate := TRUNC (v_rvsl_trandate) + 1;
      ELSE
         v_rvsl_trandate := TRUNC (v_rvsl_trandate);
      END IF;
      --En find businesses date
      --Sn - commented for fwr-48
     /* sp_reverse_gl_entries (p_inst_code,
                             v_rvsl_trandate,
                             v_prod_code,
                             v_card_type,
                             v_reversal_amt,
                             v_func_code,
                             p_txn_code,
                             v_dr_cr_flag,
                             p_card_no,
                             v_actual_feecode,
                             v_orgnl_txn_totalfee_amt,
                             v_orgnl_tranfee_cr_acctno,
                             v_orgnl_tranfee_dr_acctno,
                             v_acct_number,
                             p_rvsl_code,
                             p_msg_typ,
                             p_delv_chnl,
                             v_resp_cde,
                             v_gl_upd_flag,
                             v_errmsg
                            );

      IF v_gl_upd_flag <> 'Y' THEN
         v_errmsg :='Error while retriving gl detail '|| v_errmsg;
         RAISE exp_rvsl_reject_record;
      END IF;  */
      --En - commented for fwr-48
   END IF;
   --En reverse the GL entries
   --ELSE
   --  v_reversal_amt:=0;
   --END IF;
   --Sn reversal Fee Calculation

   v_resp_cde := '1';
   BEGIN
      sp_tran_reversal_fees (p_inst_code,
                             p_card_no,
                             p_delv_chnl,
                             v_orgnl_txn_mode,
                             p_txn_code,
                             p_curr_code,
                             NULL,
                             NULL,
                             v_reversal_amt,
                             p_business_date,
                             p_business_time,
                             NULL,
                             NULL,
                             v_resp_cde,
                             p_msg_typ,
                             p_mbr_numb,
                             p_rrn,
                             p_terminal_id,
                             v_txn_merchname,
                             v_txn_merchcity,
                             v_auth_id,
                             v_fee_merchstate,
                             p_rvsl_code,
                             v_txn_narration,
                             v_txn_type,
                             v_rvsl_trandate,
                             v_errmsg,
                             v_resp_cde,
                             v_fee_amt,
                             v_fee_plan,
                             v_fee_code,
                             v_feeattach_type
                            );

      IF v_errmsg <> 'OK' THEN
         RAISE exp_rvsl_reject_record;
      END IF;
   --Sn Review observation changes
   EXCEPTION
      WHEN exp_rvsl_reject_record THEN
         RAISE;
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Error while getting fee amount '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   --En Review observation changes
   END;
   --En reversal Fee Calculation

--   BEGIN
--      SELECT COUNT (1)
--        INTO v_starter_chk
--        FROM cms_appl_pan, cms_merinv_merpan
--       WHERE cap_inst_code = cmm_inst_code
--         AND cap_pan_code = cmm_pan_code
--         AND cap_pan_code = v_hash_pan
--         AND cap_startercard_flag = 'Y';

--      IF v_starter_chk = 0 THEN
--         v_errmsg := 'Given starter card not found in inventory master';
--         v_resp_cde := '69';
--         RAISE exp_rvsl_reject_record;
--      END IF;
--   EXCEPTION
--      WHEN exp_rvsl_reject_record THEN
--         RAISE;
--      WHEN OTHERS THEN
--         v_errmsg :='Problem while fetching count of starter card '|| SUBSTR (SQLERRM, 1, 100);
--         v_resp_cde := '21';
--         RAISE exp_rvsl_reject_record;
--   END;

   --Sn Check wheather card having GPR or Not
   BEGIN
      SELECT cap_pan_code
        INTO v_gpr_pan
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code
         --AND cap_cust_code = v_cust_code
         AND cap_acct_no = v_acct_number
         AND cap_startercard_flag = 'N';

      v_gpr_chk := 'Y';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_gpr_chk := 'N';
      WHEN OTHERS THEN
         v_errmsg :='Problem while fetching gpr card ' || SUBSTR (SQLERRM, 1, 100);
         v_resp_cde := '21';
         RAISE exp_rvsl_reject_record;
   END;
   --En Check wheather card having GPR or Not

   --Sn Card Status updation
   IF v_gpr_chk = 'N' THEN
      --Sn Mark card as inactive since Card dont have GPR
      BEGIN
         UPDATE cms_appl_pan
            SET cap_card_stat = 0,
                cap_firsttime_topup = 'N',
                cap_pin_off = '',
                cap_pin_flag = 'Y'
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT = 0 THEN
            v_errmsg := 'Starer card not updated to inactive status';
            v_resp_cde := '21';
            RAISE exp_rvsl_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_rvsl_reject_record THEN
            RAISE;
         WHEN OTHERS THEN
            v_errmsg :='Problem while updating starter card to inactive '|| SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';
            RAISE exp_rvsl_reject_record;
      END;
      --En Mark card as inactive since Card dont have GPR

      --Sn Address dtls Updation
       BEGIN
          UPDATE cms_addr_mast
             SET cam_add_one = v_addr_lineone,
                 cam_add_two = v_addr_linetwo,
                 cam_city_name = v_city_name,
                 cam_pin_code = v_pin_code,
                 cam_phone_one = v_phone_no,
                 cam_mobl_one = v_mobl_no,
                 cam_email = v_email,
                 cam_state_code = v_state_code,
                 cam_cntry_code = v_ctnry_code
           WHERE cam_cust_code = v_cust_code
             AND cam_inst_code = p_inst_code
             AND cam_addr_flag = 'P';

          IF SQL%ROWCOUNT = 0 THEN
             v_errmsg := 'Address for starter card not updated';
             v_resp_cde := '21';
             RAISE exp_rvsl_reject_record;
          END IF;
       EXCEPTION
          WHEN exp_rvsl_reject_record THEN
             RAISE;
          WHEN OTHERS THEN
             v_errmsg :='Problem while updating address dtls for starter card '|| SUBSTR (SQLERRM, 1, 100);
             v_resp_cde := '21';
             RAISE exp_rvsl_reject_record;
       END;
       --En Address dtls Updation

		IF FN_DMAPS_MAIN(V_ADDR_LINEONE) <> '*' THEN
			V_SYSTEM_GENERATED_PROFILE := 'N';
		ELSE
			V_SYSTEM_GENERATED_PROFILE := 'Y';
		END IF;

       --Sn Mailing Address deletion
       BEGIN
          DELETE FROM cms_addr_mast
                WHERE cam_cust_code = v_cust_code
                  AND cam_inst_code = p_inst_code
                  AND cam_addr_flag = 'O';
       EXCEPTION
          WHEN OTHERS THEN
             v_errmsg :='Problem while deleting mailing address for starter card '|| SUBSTR (SQLERRM, 1, 100);
             v_resp_cde := '21';
             RAISE exp_rvsl_reject_record;
       END;
       --En Mailing Address deletion

       --Sn Customer dtls updation
       BEGIN
          UPDATE cms_cust_mast
             SET ccm_ssn = v_ssn,
                 ccm_birth_date = v_birth_date,
                 ccm_first_name = v_first_name,
                 ccm_mid_name = v_mid_name,
                 ccm_last_name = v_last_name,
				 ccm_system_generated_profile = v_system_generated_profile
           WHERE ccm_cust_code = v_cust_code AND ccm_inst_code = p_inst_code;

          IF SQL%ROWCOUNT = 0 THEN
             v_errmsg := 'Customer dtls for starter card not updated';
             v_resp_cde := '21';
             RAISE exp_rvsl_reject_record;
          END IF;
       EXCEPTION
          WHEN exp_rvsl_reject_record THEN
             RAISE;
          WHEN OTHERS THEN
             v_errmsg :='Problem while updating customer dtls for starter card '|| SUBSTR (SQLERRM, 1, 100);
             v_resp_cde := '21';
             RAISE exp_rvsl_reject_record;
       END;
       --En Customer dtls updation
    BEGIN
        SELECT cmm_inst_code, cmm_location_id, cmm_merprodcat_id
          INTO v_cmm_inst_code, v_cmm_location_id, v_cmm_merprodcat_id
          FROM cms_merinv_merpan
         WHERE cmm_inst_code = p_inst_code AND cmm_pan_code = v_hash_pan;
       --IF v_cmm_location_id IS NOT NULL THEN
          BEGIN
             UPDATE cms_caf_info_entry
                SET cci_kyc_flag = 'N'
              WHERE cci_appl_code = to_char(v_cap_appl_code) --Added to_char for number to varchar2 changes
                AND cci_inst_code = p_inst_code;

             IF SQL%ROWCOUNT = 0 THEN
                v_resp_cde := '21';
                v_errmsg :='No records updated in caf_info_entry for application-'|| v_cap_appl_code;
                RAISE exp_rvsl_reject_record;
             END IF;
          EXCEPTION
          WHEN exp_rvsl_reject_record THEN
            RAISE;
          WHEN OTHERS THEN
            v_resp_cde := '21';
            v_errmsg :='Error while updating KYC dtls into caf_info_entry-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
          END;

          BEGIN
             UPDATE cms_cust_mast
                SET ccm_kyc_flag = 'N',
                    ccm_kyc_source = ''
              WHERE ccm_cust_code = v_cust_code
                AND ccm_inst_code = p_inst_code;

             IF SQL%ROWCOUNT = 0 THEN
                v_resp_cde := '21';
                v_errmsg :='KYC not updated for customer-' || v_cust_code;
                RAISE exp_rvsl_reject_record;
             END IF;
          EXCEPTION
          WHEN exp_rvsl_reject_record THEN
            RAISE;
          WHEN OTHERS THEN
            v_resp_cde := '21';
            v_errmsg :='Error while updating KYC dtls into cust_mast-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
          END;

         BEGIN
            UPDATE cms_merinv_stock
               SET cms_curr_stock = (cms_curr_stock + 1)
             WHERE cms_inst_code = v_cmm_inst_code
               AND cms_merprodcat_id = v_cmm_merprodcat_id
               AND cms_location_id = v_cmm_location_id;

            IF SQL%ROWCOUNT = 0 THEN
               v_errmsg :='No records updated to increment the stock count for the inventory';
               v_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS THEN
               v_errmsg :='Error while increment the stock count for the inventory '|| SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
         END;
      --END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;
    WHEN exp_rvsl_reject_record THEN
        RAISE;
    WHEN OTHERS THEN
        v_resp_cde := '21';
        v_errmsg :='Error while fetching inventory dtls-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_rvsl_reject_record;
    END;
   ELSIF v_gpr_chk = 'Y' THEN
      --Sn Close Starter card
      BEGIN
         UPDATE cms_appl_pan
            SET cap_card_stat = 9
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT = 0 THEN
            v_errmsg := 'Starer card not updated to close status';
            v_resp_cde := '21';
            RAISE exp_rvsl_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_rvsl_reject_record THEN
            RAISE;
         WHEN OTHERS THEN
            v_errmsg :='Problem while updating starter card '|| SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';
            RAISE exp_rvsl_reject_record;
      END;
      --En Close Starter card

      --Sn Close GPR card
      BEGIN
         UPDATE cms_appl_pan
            SET cap_card_stat = 9
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_gpr_pan;

         IF SQL%ROWCOUNT = 0 THEN
            v_errmsg := 'GPR card not updated to close status';
            v_resp_cde := '21';
            RAISE exp_rvsl_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_rvsl_reject_record THEN
            RAISE;
         WHEN OTHERS THEN
            v_errmsg :='Problem while updating GPR card ' || SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';
            RAISE exp_rvsl_reject_record;
      END;
      --En Close GPR card
   END IF;
   --En Card Status updation

   --Sn Selecting Reason code for Initial Load
   BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM cms_spprt_reasons
       WHERE csr_inst_code = p_inst_code AND csr_spprt_key = 'INILOAD';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_resp_cde := '69';
         v_errmsg := 'Initial load reason code is present in master';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Error while selecting reason code from master '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En Selecting Reason code for Initial Load

   --Sn create a record in pan spprt
   BEGIN
      INSERT INTO cms_pan_spprt
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,
                   cps_pan_code_encr
                  )
           VALUES (p_inst_code, v_hash_pan, p_mbr_numb, v_cap_prod_catg,
                   'INLOAD', v_resoncode, p_remrk,
                   '1', '1', 0,
                   v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS THEN
         v_errmsg :='Error while inserting records into card support master '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En create a record in pan spprt

   --Sn create a entry for successful
   BEGIN
      IF v_errmsg = 'OK'
      THEN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES (p_delv_chnl, p_txn_code, p_txn_type,
                      p_msg_typ, p_txn_mode, p_business_date,
                      p_business_time, v_hash_pan,
                      v_reversal_amt,-- v_tran_amt,  --Review observations changes
                      v_currcode, v_reversal_amt, --v_tran_amt, --Review observations changes
                      v_reversal_amt, v_currcode, --v_card_curr, --Review observations changes
                      'Y',
                      'Successful', p_rrn, p_inst_code,
                      v_encr_pan, v_acct_number
                     );
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         v_errmsg :='Problem while inserting data in to CMS_TRANSACTION_LOG_DTL '|| SUBSTR (SQLERRM, 1, 200);
         v_resp_cde := '21';
         RAISE exp_rvsl_reject_record;
   END;
   --En create a entry for successful

   --Sn Get account details
   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO v_acct_balance, v_ledger_balance, v_cam_type_code
        FROM cms_acct_mast
       WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code
       FOR UPDATE NOWAIT;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_resp_cde := '6';
         v_errmsg := 'Account not found in Master';
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS THEN
         v_resp_cde := '12';
         v_errmsg :='Error while selecting account dtls from Master '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En Get account details

   --Sn generate response code
   v_resp_cde := '1';
   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_cde
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delv_chnl
         AND cms_response_id = TO_NUMBER (v_resp_cde);
   EXCEPTION
      WHEN OTHERS THEN
         v_errmsg :='Problem while selecting data from response master for respose code '|| v_resp_cde|| SUBSTR (SQLERRM, 1, 200);
         v_resp_cde := '69';
         RAISE exp_rvsl_reject_record;
   END;
   --En generate response code

   v_timestamp := SYSTIMESTAMP;

   --Sn create a entry in  transactionlog
   BEGIN
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, terminal_id,
                   date_time, txn_code, txn_type, txn_mode,
                   txn_status, response_code,
                   business_date, business_time,
                   customer_card_no, topup_card_no, topup_acct_no,
                   topup_acct_type, bank_code,
                   total_amount,
                   rule_indicator, rulegroupid, currencycode, productid,
                   categoryid, tips, decline_ruleid, atm_name_location,
                   auth_id, trans_desc,
                   amount,
                   preauthamount, partialamount, mccodegroupid,
                   currencycodegroupid, transcodegroupid, rules,
                   preauth_date, gl_upd_flag, instcode, feecode,
                   feeattachtype, tran_reverse_flag, customer_card_no_encr,
                   topup_card_no_encr, proxy_number, reversal_code,
                   customer_acct_no,
                   acct_balance,
                   ledger_balance,
                   response_id, cardstatus, acct_type,
                   time_stamp,
                   cr_dr_flag,
                   error_msg, store_id, fee_plan, tranfee_amt
                  )
           VALUES (p_msg_typ, p_rrn, p_delv_chnl, p_terminal_id,
                   v_rvsl_trandate, p_txn_code, p_txn_type, p_txn_mode,
                   DECODE (p_resp_cde, '00', 'C', 'F'), p_resp_cde,
                   p_business_date, SUBSTR (p_business_time, 1, 6),
                   v_hash_pan, NULL, NULL,
                   NULL, p_inst_code,
                   TRIM (TO_CHAR (NVL (v_reversal_amt, 0),'99999999999999990.99')),
                   NULL, NULL, v_curr_code, v_prod_code,
                   v_card_type, '0.00', NULL, NULL,
                   v_auth_id, v_tran_desc,
                   TRIM (TO_CHAR (NVL (v_reversal_amt, 0),'99999999999999990.99')),
                   '0.00', '0.00', NULL,
                   NULL, NULL, NULL,
                   NULL, 'Y', p_inst_code, v_fee_code,
                   v_feeattach_type, 'N', v_encr_pan,
                   NULL, v_proxunumber, p_rvsl_code,
                   v_acct_number,
                   v_acct_balance,
                   v_ledger_balance,
                   v_resp_cde, v_applpan_cardstat, v_cam_type_code,
                   v_timestamp,
                   v_dr_cr_flag,
                   v_errmsg, p_terminal_id, v_fee_plan, v_fee_amt
                  );
   EXCEPTION
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Error while inserting records in transactionlog '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En create a entry in  transactionlog

   --Sn update reverse flag
   BEGIN
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(v_orgnl_txn_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE VMSCMS.transactionlog
         SET tran_reverse_flag = 'Y'
       WHERE rrn = p_rrn
         AND business_date = v_orgnl_txn_business_date
         AND business_time = v_orgnl_txn_business_time
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code
         AND terminal_id = v_orgnl_txn_terminalid;
		 ELSE
		   UPDATE VMSCMS_HISTORY.transactionlog_HIST
         SET tran_reverse_flag = 'Y'
       WHERE rrn = p_rrn
         AND business_date = v_orgnl_txn_business_date
         AND business_time = v_orgnl_txn_business_time
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code
         AND terminal_id = v_orgnl_txn_terminalid;
		 END IF;

      IF SQL%ROWCOUNT = 0 THEN
         v_resp_cde := '21';
         v_errmsg := 'Reverse flag is not updated ';
         RAISE exp_rvsl_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_rvsl_reject_record THEN
         RAISE;
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Error while updating txn reversal flag ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En update reverse flag

   --Sn Timestamp updation
   BEGIN
   
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE VMSCMS.cms_statements_log
         SET csl_time_stamp = v_timestamp
       WHERE csl_pan_no = v_hash_pan
         AND csl_rrn = p_rrn
         AND csl_delivery_channel = p_delv_chnl
         AND csl_txn_code = p_txn_code
         AND csl_business_date = p_business_date
         AND csl_business_time = p_business_time;
		 ELSE
		 UPDATE VMSCMS_HISTORY.cms_statements_log_HIST
         SET csl_time_stamp = v_timestamp
       WHERE csl_pan_no = v_hash_pan
         AND csl_rrn = p_rrn
         AND csl_delivery_channel = p_delv_chnl
         AND csl_txn_code = p_txn_code
         AND csl_business_date = p_business_date
         AND csl_business_time = p_business_time;
		 END IF;

      --Sn Modified for review changes
      IF SQL%ROWCOUNT = 0
      THEN
         v_resp_cde := '21';
         v_errmsg := 'Timestamp is not updated in statementlog';
         RAISE exp_rvsl_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_rvsl_reject_record THEN
       RAISE;
     --En Modified for review changes
      WHEN OTHERS THEN
         v_resp_cde := '21';
         v_errmsg :='Error while updating timestamp in statementlog '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;
   --En Timestamp updation
EXCEPTION
   -- << MAIN EXCEPTION>>
   WHEN exp_rvsl_reject_record THEN
      ROLLBACK TO v_savepoint;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_cde
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delv_chnl
            AND cms_response_id = TO_NUMBER (v_resp_cde);

         p_resp_msg := v_errmsg;
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg :='Problem while selecting data from response master '|| v_resp_cde|| SUBSTR (SQLERRM, 1, 200);
            p_resp_cde := '69';
      END;

      IF v_prod_code IS NULL THEN
         BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat,
                   cap_acct_no
              INTO v_prod_code, v_card_type, v_applpan_cardstat,
                   v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_balance, v_ledger_balance, v_cam_type_code
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
      END;

      IF v_dr_cr_flag IS NULL THEN
         BEGIN
            SELECT ctm_credit_debit_flag
              INTO v_dr_cr_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code
               AND ctm_delivery_channel = p_delv_chnl
               AND ctm_inst_code = p_inst_code;
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;
      END IF;

      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time,
                      customer_card_no, topup_card_no, topup_acct_no,
                      topup_acct_type, bank_code,
                      total_amount,
                      rule_indicator, rulegroupid, currencycode, productid,
                      categoryid, tips, decline_ruleid, atm_name_location,
                      auth_id, trans_desc,
                      amount,
                      preauthamount, partialamount, mccodegroupid,
                      currencycodegroupid, transcodegroupid, rules,
                      preauth_date, gl_upd_flag, instcode, feecode,
                      feeattachtype, tran_reverse_flag,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance,
                      ledger_balance,
                      response_id, cardstatus, error_msg,
                      acct_type, time_stamp,
                      cr_dr_flag,
                      store_id, fee_plan, tranfee_amt
                     )
              VALUES (p_msg_typ, p_rrn, p_delv_chnl, p_terminal_id,
                      v_rvsl_trandate, p_txn_code, p_txn_type, p_txn_mode,
                      DECODE (p_resp_cde, '00', 'C', 'F'), p_resp_cde,
                      p_business_date, SUBSTR (p_business_time, 1, 6),
                      v_hash_pan, NULL, NULL,
                      NULL, p_inst_code,
                      TRIM (TO_CHAR (NVL (v_reversal_amt, 0),'99999999999999990.99')),
                      NULL, NULL, v_curr_code, v_prod_code,
                      v_card_type, '0.00', NULL, NULL,
                      v_auth_id, v_tran_desc,
                      TRIM (TO_CHAR (NVL (v_reversal_amt, 0),'99999999999999990.99')),
                      '0.00', '0.00', NULL,
                      NULL, NULL, NULL,
                      NULL, 'Y', p_inst_code, v_fee_code,
                      v_feeattach_type, 'N',
                      v_encr_pan, NULL,
                      v_proxunumber, p_rvsl_code, v_acct_number,
                      v_acct_balance,
                      v_ledger_balance,
                      v_resp_cde, v_applpan_cardstat, v_errmsg,
                      v_cam_type_code, NVL (v_timestamp, SYSTIMESTAMP),
                      v_dr_cr_flag,
                      p_terminal_id, v_fee_plan, v_fee_amt
                     );
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg :='Problem while inserting data into transaction log  dtl'|| SUBSTR (SQLERRM, 1, 200);
            p_resp_cde := '69';
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                      ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES (p_delv_chnl, p_txn_code, p_txn_type,
                      p_msg_typ, p_txn_mode, p_business_date,
                      p_business_time, v_hash_pan,
                      v_reversal_amt, --v_tran_amt, --Review observations changes
                      v_currcode, v_tran_amt,
                      NULL, NULL,
                      NULL, NULL,
                      v_reversal_amt, --v_tran_amt, --Review observations changes
                      v_currcode, --v_card_curr, --Review observations changes
                      'E',
                      v_errmsg, p_rrn, p_inst_code,
                      v_encr_pan, v_acct_number
                     );
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg :='Problem while inserting data into transaction log  dtl'|| SUBSTR (SQLERRM, 1, 200);
            p_resp_cde := '69';
            ROLLBACK;
            RETURN;
      END;
   WHEN OTHERS THEN
      ROLLBACK TO v_savepoint;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_cde
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delv_chnl
            AND cms_response_id = TO_NUMBER (v_resp_cde);

         p_resp_msg := v_errmsg;
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg :='Problem while selecting data from response master '|| v_resp_cde|| SUBSTR (SQLERRM, 1, 200);
            p_resp_cde := '69';
      END;

      IF v_prod_code IS NULL THEN
         BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat,
                   cap_acct_no
              INTO v_prod_code, v_card_type, v_applpan_cardstat,
                   v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_balance, v_ledger_balance, v_cam_type_code
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
      END;

      IF v_dr_cr_flag IS NULL THEN
         BEGIN
            SELECT ctm_credit_debit_flag
              INTO v_dr_cr_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code
               AND ctm_delivery_channel = p_delv_chnl
               AND ctm_inst_code = p_inst_code;
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;
      END IF;

      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time,
                      customer_card_no, topup_card_no, topup_acct_no,
                      topup_acct_type, bank_code,
                      total_amount,
                      rule_indicator, rulegroupid, currencycode, productid,
                      categoryid, tips, decline_ruleid, atm_name_location,
                      auth_id, trans_desc,
                      amount,
                      preauthamount, partialamount, mccodegroupid,
                      currencycodegroupid, transcodegroupid, rules,
                      preauth_date, gl_upd_flag, instcode, feecode,
                      feeattachtype, tran_reverse_flag,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance,
                      response_id, cardstatus, error_msg,
                      acct_type, time_stamp,
                      cr_dr_flag,
                      store_id, fee_plan, tranfee_amt
                     )
              VALUES (p_msg_typ, p_rrn, p_delv_chnl, p_terminal_id,
                      v_rvsl_trandate, p_txn_code, p_txn_type, p_txn_mode,
                      DECODE (p_resp_cde, '00', 'C', 'F'), p_resp_cde,
                      p_business_date, SUBSTR (p_business_time, 1, 6),
                      v_hash_pan, NULL, NULL,
                      NULL, p_inst_code,
                      TRIM (TO_CHAR (NVL (v_reversal_amt, 0), '99999999999999990.99')),
                      NULL, NULL, v_curr_code, v_prod_code,
                      v_card_type, '0.00', NULL, NULL,
                      v_auth_id, v_tran_desc,
                      TRIM (TO_CHAR (NVL (v_reversal_amt, 0),'99999999999999990.99')),
                      '0.00', '0.00', NULL,
                      NULL, NULL, NULL,
                      NULL, 'Y', p_inst_code, v_fee_code,
                      v_feeattach_type, 'N',
                      v_encr_pan, NULL,
                      v_proxunumber, p_rvsl_code, v_acct_number,
                      v_acct_balance,v_ledger_balance,
                      v_resp_cde, v_applpan_cardstat, v_errmsg,
                      v_cam_type_code, NVL (v_timestamp, SYSTIMESTAMP),
                      v_dr_cr_flag,
                      p_terminal_id, v_fee_plan, v_fee_amt
                     );
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg :='Problem while inserting data into transaction log  dtl'|| SUBSTR (SQLERRM, 1, 200);
            p_resp_cde := '69';
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                      ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES (p_delv_chnl, p_txn_code, p_txn_type,
                      p_msg_typ, p_txn_mode, p_business_date,
                      p_business_time, v_hash_pan,
                      v_reversal_amt, --v_tran_amt, --Review observations changes
                      v_currcode, v_tran_amt,
                      NULL, NULL,
                      NULL, NULL,
                      v_reversal_amt, --v_tran_amt, --Review observations changes
                      v_currcode, --v_card_curr, --Review observations changes
                      'E',
                      v_errmsg, p_rrn, p_inst_code,
                      v_encr_pan, v_acct_number
                     );
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg :='Problem while inserting data into transaction log  dtl'|| SUBSTR (SQLERRM, 1, 200);
            p_resp_cde := '69';
            ROLLBACK;
            RETURN;
      END;
END;
/
SHOW ERROR;