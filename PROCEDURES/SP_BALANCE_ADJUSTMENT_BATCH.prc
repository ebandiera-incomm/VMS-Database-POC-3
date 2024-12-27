create or replace PROCEDURE        VMSCMS.SP_BALANCE_ADJUSTMENT_BATCH (
   p_instcode            IN       NUMBER,
   p_rrn                 IN       VARCHAR2,
   p_batch_id            IN       VARCHAR2,
   p_panno               IN       VARCHAR2,
   p_txn_amount          IN       NUMBER,
   p_delivery_channel    IN       VARCHAR2,
   p_force_post          IN       VARCHAR2,
   p_reason_code         IN       VARCHAR2,
   p_reason_desc         IN       VARCHAR2,
   p_ins_user            IN       NUMBER,
   p_resp_code           OUT      VARCHAR2,
   p_errmsg              OUT      VARCHAR2,
   p_acct_no             OUT      VARCHAR2,
   p_before_ledger_bal   OUT      VARCHAR2,
   p_after_ledger_bal    OUT      VARCHAR2,
   p_proxy_no            OUT      VARCHAR2,
   p_serial_no           OUT      VARCHAR2
)
AS
/*************************************************
    * modified by           :B.Besky
    * modified Date        : 08-OCT-12
    * modified reason      : Added IN Parameters in SP_STATUS_CHECK_GPR
    * Reviewer             : Saravanakumar
    * Reviewed Date        : 08-OCT-12
    * Build Number        :  CMS3.5.1_RI0019_B0007

    * Modified By      : Sagar M.
    * Modified Date    : 20-Apr-2013
    * Modified for     : Defect 10871
    * Modified Reason  : Logging of below details handled in tranasctionlog and statementlog table
                          1) ledger balance in statementlog
                          2) Product code,Product category code,Card status,Acct Type,drcr flag
                          3) Timestamp and Amount values logging correction
    * Reviewer         : Dhiraj
    * Reviewed Date    : 20-Apr-2013
    * Build Number     : RI0024.1_B0013

    * Modified By      : DINESH B.
    * Modified Date    : 17-Jan-2014
      * Modified for     : FSS 1407
    * Modified Reason  : Few transactions are missing in the VMS_postedtransactions_IRIS report
                         [Logging account number instead of debit/credit account number]
    * Release Version  : RI0024.6.5_B0001

    * Modified By      : Sagar
    * Modified Date    : 06-Mar-2014
    * Modified Reason  : 1) To log ledger balance as opening and closing balance in CMS_STATEMENTS_LOG
                         2) To correct logging of ledger balance in transactionlog in case of execption
    * Release Version  : RI0027.2_B0001

    * Modified By      :  Mageshkumar S
    * Modified For     :  FWR-48
    * Modified Date    :  25-July-2014
    * Modified Reason  :  GL Mapping Removal Changes.
    * Reviewer         :  Spankaj
    * Build Number     :  RI0027.3.1_B0001

    * Modified By      :  Ramesh A
    * Modified For     :  FSS-1993
    * Modified Date    :  24-NOV-2014
    * Modified Reason  :  TimeStamp not logging in debit transactions
    * Reviewer         :  Spankaj
    * Build Number     :  RI0027.4.2.2_B0004

    * Modified By      :  Mageshkumar S
    * Modified For     :
    * Modified Date    :  08-JUL-2015
    * Modified Reason  :  GPR Card status check removed
    * Reviewer         :  Pankaj S
    * Build Number     :  VMSGPRHOSTCSD_3.0.4_B0001

    * Modified By      :  Mageshkumar S
    * Modified For     :
    * Modified Date    :  27-JUL-2015
    * Modified Reason  :  Institution currency validation removed
    * Reviewer         :  Pankaj S
    * Build Number     :  VMSGPRHOSTCSD_3.0.4_B0003

    * Modified By      :  Siva kumar M
    * Modified For     :  mantis id:16138
    * Modified Date    :  29-JUL-2015
    * Modified Reason  :  the transaction code in not logged in TRANSACTIONLOG table. Due to the same, this transaction is not display in CSR -> Financial transaction tab.
    * Reviewer         :  Pankaj S
    * Build Number     :  VMSGPRHOSTCSD_3.0.4_B0004

    * Modified By      :  Saravanakumar
    * Modified For     :  To log reason code
    * Modified Date    :  28-SEP-2015
    * Reviewer         :  Pankaj S
    * Build Number     :  VMSGPRHOSTCSD_3.1.1


    * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07

        * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07

	* Modified By      : Baskar krishnan
    * Modified Date    : 23/06/2020
    * Purpose          : VMS-2615-Enhance Batch process to support serial
    * Reviewer         : Saravana Kumar A
    * Release Number   : R32


 *************************************************/
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_del_channel            cms_func_mast.cfm_delivery_channel%TYPE;
   v_txn_type               cms_func_mast.cfm_txn_type%TYPE;
   v_auth_id                transactionlog.auth_id%TYPE;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_business_date          VARCHAR2 (10);
   v_tran_date              DATE;
   v_business_time          VARCHAR2 (10);
   v_cr_dr_flag             VARCHAR2 (2);
   v_velocity_check         BOOLEAN                             DEFAULT FALSE;
   v_msg                    VARCHAR2 (2)                         DEFAULT '00';
   v_txn_code               cms_func_mast.cfm_txn_code%TYPE;
   v_txn_mode               cms_func_mast.cfm_txn_mode%TYPE       DEFAULT '0';
  -- v_curr_code              cms_inst_param.cip_param_value%TYPE; --Institution currency validation removed for 3.0.4 release
   v_cracct_no              cms_func_prod.cfp_cracct_no%TYPE;
   v_dracct_no              cms_func_prod.cfp_dracct_no%TYPE;
   v_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_tran_dr_cr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_tran_desc              cms_transaction_mast.ctm_tran_desc%TYPE;
   v_switch_spd_acct_type   cms_acct_type.cat_switch_type%TYPE   DEFAULT '11';
   v_acct_type              cms_acct_type.cat_type_code%TYPE;
   v_acct_bal               cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
   v_card_curr              VARCHAR2 (5);
   v_func_code              cms_func_mast.cfm_func_code%TYPE;
   v_terminal_id            transactionlog.terminal_id%TYPE;
   v_mcc_code               VARCHAR2 (20);
   v_card_expry             VARCHAR2 (20);
   v_stan                   VARCHAR2 (20);
   v_capture_date           DATE;
   v_bank_code              VARCHAR2 (20);
   v_rvsl_code              VARCHAR2 (20)                        DEFAULT '00';
   --v_reason_count           NUMBER;--Commanded by Saravananakumar
   v_max_card_bal           NUMBER;
   v_min_card_bal           NUMBER;
   v_upd_amt                NUMBER;
   v_upd_ledger_bal         NUMBER;
   v_achdaytrancnt          NUMBER;
   v_achdaytranminamt       NUMBER;
   v_achdaytranmaxamt       NUMBER;
   v_achweektrancnt         NUMBER;
   v_achweektranmaxamt      NUMBER;
   v_achmonthtrancnt        NUMBER;
   v_achmonmaxamt           NUMBER;
   v_trancnt                NUMBER;
   v_daytranamt             NUMBER;
   v_weektrancnt            NUMBER;
   v_weektranamt            NUMBER;
   v_monthtrancnt           NUMBER;
   v_monthtranamt           NUMBER;
   v_status_chk             NUMBER;
   v_expry_date             cms_appl_pan.cap_expry_date%TYPE;
   v_check_statcnt          NUMBER (3);
   v_cnt                    NUMBER (3);
   v_rrn_count              NUMBER (3);
   v_narration              VARCHAR2 (300);
   v_txn_amount             NUMBER (20, 3);
   v_auth_savepoint         NUMBER                                  DEFAULT 0;
   exp_main_reject_record   EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
   v_cam_type_code   cms_acct_mast.cam_type_code%type; -- Added on 20-apr-2013 for defect 10871
   v_timestamp       timestamp;                        -- Added on 20-Apr-2013 for defect 10871
   v_reasondesc         cms_spprt_reasons.csr_reasondesc%TYPE;
   v_proxy_number            cms_appl_pan.cap_proxy_number%TYPE;
   v_serial_number            cms_appl_pan.cap_serial_number%TYPE;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
   v_bank_code := p_instcode;
   v_txn_amount := TRIM (TO_CHAR (p_txn_amount, '99999999999999990.99'));
   SAVEPOINT v_auth_savepoint;

   --SN create hash pan
   BEGIN
      v_hash_pan := gethash (p_panno);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Error while converting pan hash ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN create hash pan

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_panno);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Error while converting pan encr ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN create encr pan

   --SN Get Trnsaction Date & Time
   BEGIN
      SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'), TO_CHAR (SYSDATE, 'HH24MISS')
        INTO v_business_date, v_business_time
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg := 'Error while selecting date' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   v_tran_date := SYSDATE;
   v_timestamp := systimestamp; --Added for FSS-1993 on 24/11/2014

   --EN Get Trnsaction Date & Time

   --Sn Duplicate RRN Check
   BEGIN
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(v_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS.transactionlog
       WHERE rrn = p_rrn
         AND business_date = v_business_date
         AND instcode = p_instcode
         AND delivery_channel = p_delivery_channel;
ELSE
	SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.transactionlog_HIST
       WHERE rrn = p_rrn
         AND business_date = v_business_date
         AND instcode = p_instcode
         AND delivery_channel = p_delivery_channel;
END IF;		 

      IF v_rrn_count > 0
      THEN
         p_resp_code := '21';
         p_errmsg := 'Duplicate RRN on ' || v_business_date;
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
            'Error while checking Duplicate RRN ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Duplicate RRN Check

  /* --SN Validate the reason code
   BEGIN
      SELECT COUNT (1)
        INTO v_reason_count
        FROM cms_spprt_reasons
       WHERE csr_spprt_rsncode = p_reason_code
         AND csr_spprt_key = 'MANADJDRCR'
         AND csr_inst_code = p_instcode;

      IF v_reason_count = 0
      THEN
         p_resp_code := '21';
         p_errmsg := 'Invalid reason code ';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         p_resp_code := '21';
         RAISE exp_main_reject_record;
   END;
*/
   --EN Validate the reason code

   --SN Set the txn_code & dr_cr_flag using txn_amount
   IF v_txn_amount = 0
   THEN
      p_resp_code := '12';
      p_errmsg := 'Transaction rejected for txn amount is zero';
      RAISE exp_main_reject_record;
   ELSE
      IF v_txn_amount > 0
      THEN
         v_dr_cr_flag := 'CR';
         v_txn_code := 20;
      ELSE
         v_dr_cr_flag := 'DR';
         v_txn_code := 19;
         v_txn_amount := ABS (v_txn_amount);
      END IF;
   END IF;

   --EN Set the txn_code & dr_cr_flag using txn_amount


--SN Validate the reason code
   BEGIN
      SELECT csr_reasondesc--Modified by Saravananakumar
        INTO v_reasondesc
        FROM cms_spprt_reasons
       WHERE csr_spprt_rsncode = p_reason_code
         AND csr_spprt_key = 'MANADJDRCR'
         AND csr_inst_code = p_instcode;

      /*IF v_reason_count = 0
      THEN
         p_resp_code := '21';
         p_errmsg := 'Invalid reason code ';
         RAISE exp_main_reject_record;
      END IF;*/

   EXCEPTION
      WHEN no_data_found
      THEN
          p_resp_code := '21';
         p_errmsg := 'Invalid reason code ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         p_resp_code := '21';
         RAISE exp_main_reject_record;
   END;

   --Sn Select Pan detail
   BEGIN
      SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
             cap_expry_date, cap_proxy_number, cap_serial_number
        INTO v_cap_card_stat, v_prod_code, v_card_type, v_acct_number,
             v_expry_date, v_proxy_number, v_serial_number
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_INST_CODE = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_errmsg := 'CARD NOT FOUND ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
             'Error while selecting card number ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Select Pan detail

   --SN Get the profile code from mast
   BEGIN
      SELECT cpc_profile_code
        INTO v_profile_code
        FROM cms_prod_cattype
       WHERE cpc_prod_code = v_prod_code
         AND cpc_card_type = v_card_type
         AND cpc_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_errmsg := 'profile_code not defined ' || v_prod_code;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
            'Error while selecting profile_code ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN Get the profile code from mast

   --SN checks the card status in GPR config
 /*  BEGIN
      sp_status_check_gpr
         (p_instcode,
          p_panno,
          p_delivery_channel,
          v_expry_date,
          v_cap_card_stat,
          v_txn_code,
          v_txn_mode,
          v_prod_code,
          v_card_type,
          v_msg,
          v_business_date,
          v_business_time,
          NULL,
          NULL,
--Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
          NULL,
          p_resp_code,
          p_errmsg
         );

      IF (   (p_resp_code <> '1' AND p_errmsg <> 'OK')
          OR (p_resp_code <> '0' AND p_errmsg <> 'OK')
         )
      THEN
         RAISE exp_main_reject_record;
      ELSE
         v_status_chk := p_resp_code;
         p_resp_code := '1';
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
              'Error from GPR Card Status Check ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN checks the card status in GPR config
   IF v_status_chk = '1'
   THEN
      --SN check card stat in pcms table
      BEGIN
         SELECT COUNT (1)
           INTO v_check_statcnt
           FROM pcms_valid_cardstat
          WHERE pvc_inst_code = p_instcode
            AND pvc_card_stat = v_cap_card_stat
            AND pvc_tran_code = v_txn_code
            AND pvc_delivery_channel = p_delivery_channel;

         IF v_check_statcnt = 0
         THEN
            p_resp_code := '21';
            p_errmsg := 'Invalid Card Status';
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code := '21';
            p_errmsg :=
                  'Problem while selecting card stat '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   --EN check card stat in pcms table
   END IF;*/

   --SN Get the base currency from mast
 /*  BEGIN
      SELECT cip_param_value
        INTO v_curr_code
        FROM cms_inst_param
       WHERE ciP_INST_CODE = p_instcode AND cip_param_key = 'CURRENCY';

      IF TRIM (v_curr_code) IS NULL
      THEN
         p_errmsg := 'Base currency cannot be null ';
         p_resp_code := '21';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_errmsg := 'Base currency is not defined for the institution ';
         p_resp_code := '21';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Error while selecting base currency  '
            || SUBSTR (SQLERRM, 1, 200);
         p_resp_code := '21';
         RAISE exp_main_reject_record;
   END; */--Institution currency validation removed for 3.0.4 release

   --EN Get the base currency from mast

   --SN Find the card currency
   BEGIN
--      SELECT TRIM (cbp_param_value)
--        INTO v_card_curr
--        FROM cms_appl_pan, cms_bin_param, cms_prod_mast
--       WHERE cap_prod_code = cpm_prod_code
--         AND cap_pan_code = v_hash_pan
--         AND cbp_param_name = 'Currency'
--         AND cbp_profile_code = cpm_profile_code
--         AND cap_INST_CODE = p_instcode;



      vmsfunutilities.get_currency_code(v_prod_code,v_card_type,p_instcode,v_card_curr,p_errmsg);

      if p_errmsg<>'OK' then
           raise exp_main_reject_record;
      end if;

      IF TRIM (v_card_curr) IS NULL
      THEN
         p_resp_code := '21';
         p_errmsg := 'Card currency cannot be null ';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Error while selecting card currency  '
            || SUBSTR (SQLERRM, 1, 200);
         p_resp_code := '21';
         RAISE exp_main_reject_record;
   END;

   --EN Find the card currency

   --SN Checks card currency with base currency
 /*  IF v_curr_code <> v_card_curr
   THEN
      p_errmsg :=
            'Both card currency and txn currency are not same  '
         || SUBSTR (SQLERRM, 1, 200);
      p_resp_code := '21';
      RAISE exp_main_reject_record;
   END IF;*/--Institution currency validation removed for 3.0.4 release

   --EN Checks card currency with base currency

   --Sn Select acct type(Spending)
   BEGIN
      SELECT cat_type_code
        INTO v_acct_type
        FROM cms_acct_type
       WHERE cat_inst_code = p_instcode
         AND cat_switch_type = v_switch_spd_acct_type;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_errmsg := 'Acct type not defined in master(Spending)';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Error while selecting acct type(Spending) '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Select acct type(Spending)

   --Sn Get the Spending Account Number & Balance
   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal,
             cam_type_code                  --Added for defect 10871
        INTO v_acct_bal, v_ledger_bal,
             v_cam_type_code                --Added for defect 10871
        FROM cms_acct_mast
       WHERE cam_inst_code = p_instcode
         AND cam_acct_no = v_acct_number
         AND cam_type_code = v_acct_type;

      p_before_ledger_bal :=
                         TRIM (TO_CHAR (v_ledger_bal, '99999999999999990.99'));
      p_acct_no := v_acct_number;
      p_proxy_no :=v_proxy_number;
      p_serial_no:=v_serial_number;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_errmsg := 'Account balance not found ' || v_acct_number;
         RAISE exp_main_reject_record;
      WHEN exp_main_reject_record
      THEN
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Problem while selecting Spending Account Number Details '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Get the Spending Account Number & Balance

    --Sn - commented for fwr-48

   --SN Select the function code
 /*  BEGIN
      SELECT cfm_func_code
        INTO v_func_code
        FROM cms_func_mast
       WHERE cfm_txn_code = v_txn_code
         AND cfm_txn_mode = v_txn_mode
         AND cfm_delivery_channel = p_delivery_channel
         AND cfm_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Function code not defined for txn code '
            || v_txn_code
            || ' '
            || p_delivery_channel;
         RAISE exp_main_reject_record;
      WHEN TOO_MANY_ROWS
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'More than one function defined for txn code '
            || v_txn_code
            || ' '
            || p_delivery_channel;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
            'Error while selecting function code '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN Select the function code

   --SN Select the debit and credit gl account
   BEGIN
      SELECT cfp_cracct_no, cfp_dracct_no
        INTO v_cracct_no, v_dracct_no
        FROM cms_func_prod
       WHERE cfp_func_code = v_func_code
         AND cfp_prod_code = v_prod_code
         AND cfp_prod_cattype = v_card_type
         AND cfP_INST_CODE = p_instcode;

      IF TRIM (v_cracct_no) IS NULL AND TRIM (v_dracct_no) IS NULL
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Both credit and debit account cannot be null for a transaction code '
            || v_txn_code
            || ' Function code '
            || v_func_code;
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE exp_main_reject_record;
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_errmsg := 'Function is not attached to card ' || v_func_code;
         RAISE exp_main_reject_record;
      WHEN TOO_MANY_ROWS
      THEN
         p_resp_code := '21';
         p_errmsg :=
             'More than one function defined for card number ' || v_func_code;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Error while selecting Gl details for card number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END; */

   --En - commented for fwr-48

   IF v_dr_cr_flag = 'CR'
   THEN
      v_upd_amt := v_acct_bal + v_txn_amount;
      v_upd_ledger_bal := v_ledger_bal + v_txn_amount;
   ELSIF v_dr_cr_flag = 'DR'
   THEN
      v_upd_amt := v_acct_bal - v_txn_amount;
      v_upd_ledger_bal := v_ledger_bal - v_txn_amount;
   END IF;

   --SN Select the debit and credit gl account
   IF v_txn_amount > 0
   THEN
      --SN Checks for maximum card balance configured for the product profile.
      BEGIN
         SELECT TO_NUMBER (cbp_param_value)
           INTO v_max_card_bal
           FROM cms_bin_param
          WHERE cbp_inst_code = p_instcode
            AND cbp_param_name = 'Max Card Balance'
            AND cbp_profile_code = v_profile_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code := '21';
            p_errmsg :=
                  'Max Card Balance is not attached to profile  '
               || v_profile_code;
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code := '21';
            p_errmsg :=
                  'Error while selecting Max Card Balance '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      --EN Checks for maximum card balance configured for the product profile.

      --SN check balance
      IF (v_upd_ledger_bal > v_max_card_bal) OR (v_upd_amt > v_max_card_bal)
      THEN
         p_resp_code := '12';
         p_errmsg := 'EXCEEDING MAXIMUM CARD BALANCE';
         RAISE exp_main_reject_record;
      END IF;
   --EN check balance
   ELSE
      --SN Checks for minimum card balance configured for the product profile.
      BEGIN
         SELECT TO_NUMBER (cbp_param_value)
           INTO v_min_card_bal
           FROM cms_bin_param
          WHERE cbp_inst_code = p_instcode
            AND cbp_param_name = 'Min Card Balance'
            AND cbp_profile_code = v_profile_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code := '21';
            p_errmsg :=
                  'Min Card Balance is not attached to profile  '
               || v_profile_code;
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code := '21';
            p_errmsg :=
                  'Error while selecting Min Card Balance '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      --EN Checks for minimum card balance configured for the product profile.

      --SN check balance
      IF (v_upd_ledger_bal < v_min_card_bal) OR (v_upd_amt < v_min_card_bal)
      THEN
         p_resp_code := '12';
         p_errmsg := 'Transaction amount is lesser than Minimum Tran amount';
         RAISE exp_main_reject_record;
      END IF;
   --EN check balance
   END IF;

   --SN Find the type of txn (credit or debit)
   BEGIN
      SELECT ctm_credit_debit_flag, ctm_tran_desc,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1'))
        INTO v_tran_dr_cr_flag, v_tran_desc,
             v_txn_type
        FROM cms_transaction_mast
       WHERE ctm_tran_code = v_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_instcode
         AND ctm_support_type = 'M';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Transaction detail is not found in master for manual adj txn '
            || v_txn_code
            || 'delivery channel '
            || p_delivery_channel;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Problem while selecting debit/credit flag '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
   END;

   IF v_tran_dr_cr_flag <> v_dr_cr_flag
   THEN
      p_resp_code := '21';
      p_errmsg :=
            'Debit Credit not matched transaction mast & txn_amt flag '
         || v_tran_dr_cr_flag
         || ' '
         || v_dr_cr_flag;
      RAISE exp_main_reject_record;
   END IF;

   --EN Find the type of txn (credit or debit)

   --SN generate auth id
   BEGIN
      SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
        INTO v_auth_id
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 100);
         p_resp_code := '21';
         RETURN;
   END;

   --EN generate auth id

   --SN Transaction the amount based on the dr_cr_flag
   BEGIN
      IF v_dr_cr_flag = 'CR'
      THEN
         IF TRIM (p_reason_desc) IS NOT NULL
         THEN
            v_narration := p_reason_desc || '/';
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

         BEGIN
            UPDATE cms_acct_mast
               SET cam_acct_bal = cam_acct_bal + v_txn_amount,
                   cam_ledger_bal = cam_ledger_bal + v_txn_amount
             WHERE cam_inst_code = p_instcode AND cam_acct_no = v_acct_number;

            IF SQL%ROWCOUNT = 0
            THEN
               p_resp_code := '21';
               p_errmsg :=
                     'Problem while updating in account master for transaction account '
                  || v_acct_number
                  || ' and Dr/Cr flag '
                  || v_dr_cr_flag;
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error occurred while acct mast  '
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '21';
               RAISE exp_main_reject_record;
         END;

     /*    BEGIN
            sp_ins_eodupdate_acct_cmsauth (p_rrn,
                                           NULL,
                                           p_delivery_channel,
                                           v_txn_code,
                                           v_txn_mode,
                                           TO_DATE (v_business_date,
                                                    'yyyymmdd'
                                                   ),
                                           p_panno,
                                           v_dracct_no,
                                           v_txn_amount,
                                           'D',
                                           p_instcode,
                                           p_errmsg
                                          );

            IF p_errmsg <> 'OK'
            THEN
               p_resp_code := '21';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error occurred while debiting gl '
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '21';
               RAISE exp_main_reject_record;
         END;*/--review changes for fwr-48

        -- v_timestamp := systimestamp;    --Added for defect 10871 --Commented for FSS-1993 on 24/11/2014

         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_opening_bal, csl_trans_amount,
                         csl_trans_type,
                         csl_trans_date,
                         csl_closing_balance, csl_trans_narrration,
                         csl_inst_code, csl_pan_no_encr, csl_rrn,
                         csl_business_date, csl_business_time,
                         csl_delivery_channel, csl_txn_code, csl_auth_id,
                         csl_ins_date, csl_ins_user, csl_acct_no,
                         csl_panno_last4digit,
                         --csl_to_acctno,   -- Commented on 07-Mar-2014
                         csl_acct_type,     --Added on 10-apr-2013 for defect 10871
                         csl_time_stamp,    --Added on 10-apr-2013 for defect 10871
                         csl_prod_code ,csl_card_type     --Added on 10-apr-2013 for defect 10871
                        )
                 VALUES (v_hash_pan,
                         --v_acct_bal,      --Commented to log ledger balacne
                         v_ledger_bal,      --Modified to log ledger balacne
                         v_txn_amount,
                         v_dr_cr_flag,
                         TO_DATE (v_business_date, 'yyyymmdd'),
                         --v_acct_bal + v_txn_amount,           -- Commented to log ledger balance
                         v_ledger_bal + v_txn_amount,           -- Modified to log ledger balance
                         v_narration,
                         p_instcode, v_encr_pan, p_rrn,
                         v_business_date, v_business_time,
                         p_delivery_channel, v_txn_code, v_auth_id,
                         SYSDATE, 1, v_acct_number,--v_dracct_no FSS-1407
                         (SUBSTR (p_panno,
                                  LENGTH (p_panno) - 3,
                                  LENGTH (p_panno)
                                 )
                         ),
                         --v_acct_number,   -- Commented on 07-Mar-2014
                         v_cam_type_code,   --Added on 10-apr-2013 for defect 10871
                         v_timestamp,       --Added on 10-apr-2013 for defect 10871
                         v_prod_code,v_card_type        --Added on 10-apr-2013 for defect 10871
                        );

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               p_resp_code := '21';
               p_errmsg := 'No records inserted in statements log for CR';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code := '21';
               p_errmsg :=
                     'Problem while inserting into statement log for tran amt '
                  || v_txn_amount
                  || ' and Dr/Cr flag '
                  || v_dr_cr_flag
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      ELSIF v_dr_cr_flag = 'DR'
      THEN
         IF TRIM (p_reason_desc) IS NOT NULL
         THEN
            v_narration := p_reason_desc || '/';
         END IF;

         IF TRIM (v_auth_id) IS NOT NULL
         THEN
            v_narration := v_narration || v_auth_id || '/';
         END IF;

         IF TRIM (v_cracct_no) IS NOT NULL
         THEN
            v_narration := v_narration || v_cracct_no || '/';
         END IF;

         IF TRIM (v_business_date) IS NOT NULL
         THEN
            v_narration := v_narration || v_business_date;
         END IF;

         BEGIN
            UPDATE cms_acct_mast
               SET cam_acct_bal = cam_acct_bal - v_txn_amount,
                   cam_ledger_bal = cam_ledger_bal - v_txn_amount
             WHERE cam_inst_code = p_instcode AND cam_acct_no = v_acct_number;

            IF SQL%ROWCOUNT = 0
            THEN
               p_resp_code := '21';
               p_errmsg :=
                     'Problem while updating in account master for transaction account '
                  || v_acct_number
                  || ' and Dr/Cr flag '
                  || v_dr_cr_flag;
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error occurred while updating acct mast '
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '21';
               RAISE exp_main_reject_record;
         END;

       /*  BEGIN
            sp_ins_eodupdate_acct_cmsauth (p_rrn,
                                           NULL,
                                           p_delivery_channel,
                                           v_txn_code,
                                           v_txn_mode,
                                           TO_DATE (v_business_date,
                                                    'yyyymmdd'
                                                   ),
                                           p_panno,
                                           v_cracct_no,
                                           v_txn_amount,
                                           'C',
                                           p_instcode,
                                           p_errmsg
                                          );

            IF p_errmsg <> 'OK'
            THEN
               p_resp_code := '21';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error occurred while crediting gl '
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '21';
               RAISE exp_main_reject_record;
         END;*/--review changes for fwr-48

         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_opening_bal, csl_trans_amount,
                         csl_trans_type,
                         csl_trans_date,
                         csl_closing_balance, csl_trans_narrration,
                         csl_inst_code, csl_pan_no_encr, csl_rrn,
                         csl_business_date, csl_business_time,
                         csl_delivery_channel, csl_txn_code, csl_auth_id,
                         csl_ins_date, csl_ins_user, csl_acct_no,
                         csl_panno_last4digit,
                         --csl_to_acctno,   -- Commented on 07-Mar-2014
                         csl_acct_type,     --Added on 10-apr-2013 for defect 10871
                         csl_time_stamp,    --Added on 10-apr-2013 for defect 10871
                         csl_prod_code ,csl_card_type     --Added on 10-apr-2013 for defect 10871
                        )
                 VALUES (v_hash_pan,
                         --v_acct_bal,      -- Commented to log ledger balance
                         v_ledger_bal,      -- Added to log ledger balance
                         v_txn_amount,
                         v_dr_cr_flag,
                         TO_DATE (v_business_date, 'yyyymmdd'),
                         --v_acct_bal - v_txn_amount,           -- Commented to log ledger balance
                         v_ledger_bal - v_txn_amount,           -- Added to log ledger balance
                         v_narration,
                         p_instcode, v_encr_pan, p_rrn,
                         v_business_date, v_business_time,
                         p_delivery_channel, v_txn_code, v_auth_id,
                         SYSDATE, 1, v_acct_number,
                         (SUBSTR (p_panno,
                                  LENGTH (p_panno) - 3,
                                  LENGTH (p_panno)
                                 )
                         ),
                         --v_acct_number,     --v_cracct_no FSS-1407 -- Commented on 07-Mar-2014
                         v_cam_type_code,   --Added on 10-apr-2013 for defect 10871
                         v_timestamp,       --Added on 10-apr-2013 for defect 10871
                         v_prod_code ,v_card_type       --Added on 10-apr-2013 for defect 10871
                        );

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               p_resp_code := '21';
               p_errmsg := 'No records inserted in statements log for DR';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code := '21';
               p_errmsg :=
                     'Problem while inserting into statement log for tran amt '
                  || v_txn_amount
                  || ' and Dr/Cr flag '
                  || v_dr_cr_flag
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      ELSIF NVL (v_dr_cr_flag, '0') NOT IN ('DR', 'CR')
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'invalid debit/credit flag '
            || v_dr_cr_flag
            || ' for deliver chnl '
            || p_delivery_channel
            || ' and txn code '
            || v_txn_code;
         RAISE exp_main_reject_record;
      END IF;
   END;

   --EN Transaction the amount based on the dr_cr_flag

   --SN Get the Spending Account ledger balance
   BEGIN
      SELECT TRIM (TO_CHAR (cam_ledger_bal, '99999999999999990.99'))
        INTO p_after_ledger_bal
        FROM cms_acct_mast
       WHERE cam_inst_code = p_instcode
         AND cam_acct_no = v_acct_number
         AND cam_type_code = v_acct_type;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         p_errmsg := 'Account balance not found ' || v_acct_number;
         RAISE exp_main_reject_record;
      WHEN exp_main_reject_record
      THEN
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_errmsg :=
               'Problem while selecting Spending Account Number Detail'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN Get the Spending Account ledger balance

   --SN log the transaction detials in bal_adj_batch table
   BEGIN
      INSERT INTO cms_bal_adj_batch
                  (cbb_batch_id, cbb_pan_code, cbb_pan_code_encr,
                   cbb_txn_amt, cbb_forse_post, cbb_reason_code,
                   cbb_txn_desc, cbb_before_ledg_bal, cbb_after_ledg_bal,
                   cbb_process_flag, cbb_process_msg, cbb_ins_user,
                   cbb_ins_date
                  )
           VALUES (p_batch_id, v_hash_pan, v_encr_pan,
                   v_txn_amount, p_force_post, p_reason_code,
                   v_narration, p_before_ledger_bal, p_after_ledger_bal,
                   'S', 'Success', 1,
                   v_tran_date
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         p_errmsg :=
               'Problem while inserting bal adj batch process Detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN log the transaction detials in bal_adj_batch table
   p_errmsg := 'Success';
   p_resp_code:= '1';

   --SN Get responce code from master
   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_instcode
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = p_resp_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_errmsg := 'No data found in response mast ' || p_resp_code;
         p_resp_code := '21';
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Problem while selecting data from response master '
            || p_resp_code
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '21';
   END;

   --EN Get responce code fomr master

   --SN Inserting data in transactionlog
   BEGIN
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, date_time, txn_code,
                   txn_type, txn_mode, txn_status, response_code,
                   business_date, business_time, customer_card_no, instcode,
                   customer_card_no_encr, customer_acct_no, error_msg,
                   cardstatus, amount, bank_code, total_amount,
                   currencycode, auth_id, trans_desc, gl_upd_flag,
                   acct_balance,
                   ledger_balance, response_id, add_ins_date, add_ins_user,
                   productid,       --Added for defect 10871
                   categoryid,      --Added for defect 10871
                   acct_type,       --Added for defect 10871
                   time_stamp,      --Added for defect 10871
                   cr_dr_flag,     --Added for defect 10871
                   reason,reason_code--Added by Saravananakumar
                  )
           VALUES (v_msg, p_rrn, p_delivery_channel, SYSDATE, v_txn_code,
                   v_txn_type, v_txn_mode, 'C', p_resp_code,
                   v_business_date, v_business_time, v_hash_pan, p_instcode,
                   v_encr_pan, v_acct_number, p_errmsg,
                   v_cap_card_stat, TRIM(TO_CHAR(nvl(v_txn_amount,0), '99999999999999990.99')),-- NVl added for defect 10871
                   v_bank_code, TRIM(TO_CHAR(nvl(v_txn_amount,0), '99999999999999990.99')),-- NVl added for defect 10871,
                   v_card_curr, v_auth_id, p_reason_desc, 'N',
                   TRIM (TO_CHAR (nvl(v_upd_amt,0), '99999999999999990.99')),
                   TRIM (TO_CHAR (nvl(p_after_ledger_bal,0), '99999999999999990.99')),
                   p_resp_code, SYSDATE, 1,
                   v_prod_code,      --Added for defect 10871
                   v_card_type,      --Added for defect 10871
                   v_cam_type_code,  --Added for defect 10871
                   v_timestamp,       --Added for defect 10871
                   v_dr_cr_flag ,   --Added for defect 10871
                   v_reasondesc,p_reason_code --Added by Saravananakumar
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         p_errmsg :=
               'Exception while inserting to transaction log '
            || SQLCODE
            || '---'
            || SQLERRM;
   END;

   --EN Inserting data in transactionlog

   --SN Inserting data in transactionlog dtl
   BEGIN
      INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                   ctd_txn_mode, ctd_business_date, ctd_business_time,
                   ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                   ctd_waiver_amount, ctd_servicetax_amount,
                   ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                   ctd_rrn, ctd_inst_code, ctd_ins_date,
                   ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                   ctd_cust_acct_number, ctd_addr_verify_response,
                   ctd_actual_amount, ctd_txn_amount
                  )
           VALUES (p_delivery_channel, v_txn_code, v_txn_type,
                   v_txn_mode, v_business_date, v_business_time,
                   v_hash_pan, v_card_curr, NULL,
                   NULL, NULL,
                   NULL, 'Y', p_errmsg,
                   p_rrn, p_instcode, SYSDATE,
                   v_encr_pan, v_msg, '',
                   v_acct_number, '',
                   v_txn_amount, v_txn_amount
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '21';
   END;
--En Inserting data in transactionlog dtl
EXCEPTION
   WHEN exp_main_reject_record
   THEN
      ROLLBACK TO v_auth_savepoint;

      --SN Get responce code from master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = p_resp_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg := 'No data found in response mast ' || p_resp_code;
            p_resp_code := '21';
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '21';
      END;

      --EN Get responce code fomr master

         -----------------------------------------------
         --SN: Added on 20-Apr-2013 for defect 10871
         -----------------------------------------------

         IF  V_ACCT_BAL IS NULL
         THEN

             BEGIN

               SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                      cam_type_code
                INTO v_acct_bal, v_ledger_bal,
                      v_cam_type_code
                FROM CMS_ACCT_MAST
                WHERE CAM_ACCT_NO =
                    (SELECT CAP_ACCT_NO
                       FROM CMS_APPL_PAN
                      WHERE CAP_PAN_CODE = V_HASH_PAN AND
                           CAP_INST_CODE = P_INSTCODE) AND
                    CAM_INST_CODE = P_INSTCODE;
             EXCEPTION
               WHEN OTHERS THEN
                V_ACCT_BAL := 0;
                V_LEDGER_BAL   := 0;
             END;

         END IF;

         if V_PROD_CODE is null
         then

             BEGIN

                 SELECT CAP_PROD_CODE,
                        CAP_CARD_TYPE,
                        CAP_CARD_STAT,
                        CAP_ACCT_NO
                   INTO V_PROD_CODE,
                        V_CARD_TYPE,
                        V_CAP_CARD_STAT,
                        V_ACCT_NUMBER
                   FROM CMS_APPL_PAN
                  WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
             EXCEPTION
             WHEN OTHERS THEN

             NULL;

             END;

         end if;


         if V_DR_CR_FLAG is null
         then

            BEGIN

                 SELECT CTM_CREDIT_DEBIT_FLAG
                   INTO V_DR_CR_FLAG
                   FROM CMS_TRANSACTION_MAST
                  WHERE CTM_TRAN_CODE = v_txn_code
                  AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                  AND   CTM_INST_CODE = P_INSTCODE;

            EXCEPTION
             WHEN OTHERS THEN

             NULL;

            END;

         end if;

         if v_timestamp is null
         then
             v_timestamp := systimestamp;              -- Added on 20-Apr-2013 for defect 10871

         end if;

         -----------------------------------------------
         --EN: Added on 20-Apr-2013 for defect 10871
         -----------------------------------------------

      --SN Inserting data in transactionlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, customer_acct_no,
                      error_msg, cardstatus, amount, bank_code,
                      total_amount, currencycode, auth_id, trans_desc,
                      gl_upd_flag,
                      acct_balance,
                      ledger_balance, response_id, add_ins_date, add_ins_user,
                      productid,       --Added for defect 10871
                      categoryid,      --Added for defect 10871
                      acct_type,       --Added for defect 10871
                      time_stamp,      --Added for defect 10871
                      cr_dr_flag  ,    --Added for defect 10871
                      reason,reason_code     --Added by Saravananakumar
                     )
              VALUES (v_msg, p_rrn, p_delivery_channel, SYSDATE, v_txn_code,
                      v_txn_type, v_txn_mode, 'F', p_resp_code,
                      v_business_date, v_business_time, v_hash_pan,
                      p_instcode, v_encr_pan, v_acct_number,
                      p_errmsg, v_cap_card_stat, trim(to_char(nvl(v_txn_amount,0), '99999999999999990.99')), v_bank_code,
                      trim(to_char(nvl(v_txn_amount,0), '99999999999999990.99')), v_card_curr, v_auth_id, p_reason_desc,
                      'N',
                      TRIM (TO_CHAR (v_acct_bal, '99999999999999990.99')),
                      --nvl(p_after_ledger_bal,0),                              -- Commented to log proper ledger balance in case of exception
                      TRIM (TO_CHAR (v_ledger_bal, '99999999999999990.99')),    -- Added to log proper ledger balance in case of exception
                      p_resp_code, SYSDATE, 1,
                      v_prod_code,     --Added for defect 10871
                      v_card_type,     --Added for defect 10871
                      v_cam_type_code,  --Added for defect 10871,
                      v_timestamp,       --Added for defect 10871
                      v_dr_cr_flag ,   --Added for defect 10871
                      v_reasondesc,p_reason_code  --Added by Saravananakumar
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '21';
            p_errmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --EN Inserting data in transactionlog

      --SN Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number, ctd_addr_verify_response,
                      ctd_actual_amount, ctd_txn_amount
                     )
              VALUES (p_delivery_channel, v_txn_code, v_txn_type,
                      v_txn_mode, v_business_date, v_business_time,
                      v_hash_pan, v_card_curr, NULL,
                      NULL, NULL,
                      NULL, 'E', p_errmsg,
                      p_rrn, p_instcode, SYSDATE,
                      v_encr_pan, v_msg, '',
                      v_acct_number, '',
                      v_txn_amount, v_txn_amount
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '21';
      END;

      --En Inserting data in transactionlog dtl

      --SN Log the transaction details in bal_adj_batch
      BEGIN
         INSERT INTO cms_bal_adj_batch
                     (cbb_batch_id, cbb_pan_code, cbb_pan_code_encr,
                      cbb_txn_amt, cbb_forse_post, cbb_reason_code,
                      cbb_txn_desc, cbb_before_ledg_bal,
                      cbb_after_ledg_bal, cbb_process_flag, cbb_process_msg,
                      cbb_ins_user, cbb_ins_date
                     )
              VALUES (p_batch_id, v_hash_pan, v_encr_pan,
                      v_txn_amount, p_force_post, p_reason_code,
                      v_narration, NVL (p_before_ledger_bal, 0),
                      NVL (p_after_ledger_bal, 0), 'F', p_errmsg,
                      1, v_tran_date
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '21';
            p_errmsg :=
                  'Problem while inserting bal adj batch process Detail'
               || SUBSTR (SQLERRM, 1, 200);
      END;
   --EN Log the transaction details in bal_adj_batch
   WHEN OTHERS
   THEN
      ROLLBACK TO v_auth_savepoint;

      --SN Get responce code fomr master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = p_resp_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg := 'No data found in response mast ' || p_resp_code;
            p_resp_code := '21';
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
      END;

      --EN Get responce code fomr master

         -----------------------------------------------
         --SN: Added on 20-Apr-2013 for defect 10871
         -----------------------------------------------

         IF  V_ACCT_BAL IS NULL
         THEN

             BEGIN

               SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                      cam_type_code
                INTO V_ACCT_BAL, V_LEDGER_BAL,
                      v_cam_type_code
                FROM CMS_ACCT_MAST
                WHERE CAM_ACCT_NO =
                    (SELECT CAP_ACCT_NO
                       FROM CMS_APPL_PAN
                      WHERE CAP_PAN_CODE = V_HASH_PAN AND
                           CAP_INST_CODE = P_INSTCODE) AND
                    CAM_INST_CODE = P_INSTCODE;
             EXCEPTION
               WHEN OTHERS THEN
                V_ACCT_BAL := 0;
                V_LEDGER_BAL   := 0;
             END;

         END IF;

         if V_PROD_CODE is null
         then

             BEGIN

                 SELECT CAP_PROD_CODE,
                        CAP_CARD_TYPE,
                        CAP_CARD_STAT,
                        CAP_ACCT_NO
                   INTO V_PROD_CODE,
                        V_CARD_TYPE,
                        V_CAP_CARD_STAT,
                        V_ACCT_NUMBER
                   FROM CMS_APPL_PAN
                  WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
             EXCEPTION
             WHEN OTHERS THEN

             NULL;

             END;

         end if;


         if V_DR_CR_FLAG is null
         then

            BEGIN

                 SELECT CTM_CREDIT_DEBIT_FLAG
                   INTO V_DR_CR_FLAG
                   FROM CMS_TRANSACTION_MAST
                  WHERE CTM_TRAN_CODE = V_TXN_CODE
                  AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                  AND   CTM_INST_CODE = P_INSTCODE;

            EXCEPTION
             WHEN OTHERS THEN

             NULL;

            END;

         end if;

         if v_timestamp is null
         then
             v_timestamp := systimestamp;              -- Added on 20-Apr-2013 for defect 10871

         end if;

         -----------------------------------------------
         --EN: Added on 20-Apr-2013 for defect 10871
         -----------------------------------------------


      --SN Inserting data in transactionlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, customer_acct_no,
                      error_msg, cardstatus, amount, bank_code,
                      total_amount, currencycode, auth_id, trans_desc,
                      gl_upd_flag,
                      acct_balance,
                      ledger_balance, response_id, add_ins_date, add_ins_user,
                      productid,       --Added for defect 10871
                      categoryid,      --Added for defect 10871
                      acct_type,       --Added for defect 10871
                      time_stamp,      --Added for defect 10871
                      cr_dr_flag ,     --Added for defect 10871
                      reason,reason_code     --Added by Saravananakumar
                     )
              VALUES (v_msg, p_rrn, p_delivery_channel, SYSDATE, v_txn_code,
                      v_txn_type, v_txn_mode, 'F', p_resp_code,
                      v_business_date, v_business_time, v_hash_pan,
                      p_instcode, v_encr_pan, v_acct_number,
                      p_errmsg, v_cap_card_stat, TRIM(TO_CHAR(nvl(v_txn_amount,0), '99999999999999990.99')), v_bank_code,
                      TRIM(TO_CHAR(nvl(v_txn_amount,0), '99999999999999990.99')), v_card_curr, v_auth_id, p_reason_desc,
                      'N',
                      TRIM (TO_CHAR (v_acct_bal, '99999999999999990.99')),
                      --nvl(p_after_ledger_bal,0),                              -- Commented to log proper ledger balance in case of exception
                      TRIM (TO_CHAR (v_ledger_bal, '99999999999999990.99')),    -- Added to log proper ledger balance in case of exception
                      p_resp_code,
                      SYSDATE,
                      1,
                      v_prod_code,     --Added for defect 10871
                      v_card_type,     --Added for defect 10871
                      v_cam_type_code,  --Added for defect 10871
                      v_timestamp,       --Added for defect 10871
                      v_dr_cr_flag  ,  --Added for defect 10871
                      v_reasondesc,p_reason_code     --Added by Saravananakumar
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_errmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --EN Inserting data in transactionlog

      --SN Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number, ctd_addr_verify_response,
                      ctd_actual_amount, ctd_txn_amount
                     )
              VALUES (p_delivery_channel, v_txn_code, v_txn_type,
                      v_txn_mode, v_business_date, v_business_time,
                      v_hash_pan, v_card_curr, NULL,
                      NULL, NULL,
                      NULL, 'E', p_errmsg,
                      p_rrn, p_instcode, SYSDATE,
                      v_encr_pan, v_msg, '',
                      v_acct_number, '',
                      v_txn_amount, v_txn_amount
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
      END;

      --En Inserting data in transactionlog dtl

      --SN Log the transaction details in bal_adj_batch
      BEGIN
         INSERT INTO cms_bal_adj_batch
                     (cbb_batch_id, cbb_pan_code, cbb_pan_code_encr,
                      cbb_txn_amt, cbb_forse_post, cbb_reason_code,
                      cbb_txn_desc, cbb_before_ledg_bal,
                      cbb_after_ledg_bal, cbb_process_flag, cbb_process_msg,
                      cbb_ins_user, cbb_ins_date
                     )
              VALUES (p_batch_id, v_hash_pan, v_encr_pan,
                      v_txn_amount, p_force_post, p_reason_code,
                      v_narration, NVL (p_before_ledger_bal, 0),
                      NVL (p_after_ledger_bal, 0), 'F', p_errmsg,
                      1, v_tran_date
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_errmsg :=
                  'Problem while inserting bal adj batch process Detail'
               || SUBSTR (SQLERRM, 1, 200);
      END;
--EN Log the transaction details in bal_adj_batch
END;
/
SHOW ERROR;