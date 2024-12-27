CREATE OR REPLACE PROCEDURE VMSCMS.SP_ADHOC_FEES_CSR (
   prm_inst_code       IN       NUMBER,
   prm_mbr_numb        IN       VARCHAR2,
   prm_msg_type        IN       VARCHAR2,
   prm_delivery_chnl   IN       VARCHAR2,
   prm_txn_code        IN       VARCHAR2,
   prm_txn_mode        IN       VARCHAR2,
   prm_tran_date       IN       VARCHAR2,
   prm_tran_time       IN       VARCHAR2,
   prm_card_no         IN       VARCHAR2,
   prm_rrn             IN       VARCHAR2,
   prm_stan            IN       VARCHAR2,
   prm_adhoc_fees      IN       VARCHAR2,
   prm_reason_code     IN       VARCHAR2,
   prm_remark          IN       VARCHAR2,
   prm_rvsl_code       IN       NUMBER,
   prm_txn_curr        IN       VARCHAR2,
   prm_ins_user        IN       NUMBER,
   prm_reason_desc     IN       VARCHAR2,
   prm_call_id         IN       NUMBER,
   prm_acct_no         IN       VARCHAR2,
   prm_acct_type       IN       NUMBER,
   prm_ipaddress       IN        VARCHAR2, --added by amit on 06-Sep-2012
   prm_final_bal       OUT      VARCHAR2,
   prm_resp_code       OUT      VARCHAR2,
   prm_errmsg          OUT      VARCHAR2
)
IS
/**********************************************************************************************

  * VERSION              :  1.0
  * DATE OF CREATION     : 19/Apr/2012
  * PURPOSE              : Adhoc Fees
  * CREATED BY           : Sagar More

  * Modified By          : Sagar
  * modified for         : Internal Enhancement
  * modified Date        : 09-OCT-12
  * modified reason      : Response id changed from 49 to 10
                           To show invalid card status msg in popup query
  * Reviewer             : Saravanakumar
  * Reviewed Date        : 09-OCT-12
  * Build Number        : CMS3.5.1_RI0019_B0008

  * Modified by          : Dnyaneshwar
  * modified for         : JIRA Defect
  * modified Date        : 16-APRIL-13
  * modified reason      : for FSS-754 : To log Merchant Name
  * Reviewer             : Saravanakumar
  * Reviewed Date        : 09-OCT-12
  * Build Number         : CMS3.5.1_RI0024.1_B0008


  * Modified By      : Sagar M.
  * Modified Date    : 18-Apr-2013
  * Modified for     : Defect 10871
  * Modified Reason  : Logging of below details in tranasctionlog and statementlog table
                          1) ledger balance in statementlog
                          2) Product code,Product category code,Card status,Acct Type,drcr flag
                          3) Timestamp and Amount values logging correction
  * Reviewer         : Dhiraj
  * Reviewed Date    : 18-Apr-2013
  * Build Number     : RI0024.1_B0014

  * Modified By          : Dnyaneshwar J on 09 May 2013.
  * Modified Date        : 09-May-2013
  * Modified for         : for FSS-754 : To log Merchant Name as 'System'
  * Build Number         : RI0024.1_B0018

   * Modified by          : MageshKumar S.
   * Modified Date        : 25-July-14
   * Modified For         : FWR-48
   * Modified reason      : GL Mapping removal changes
   * Reviewer             : Spankaj
   * Build Number         : RI0027.3.1_B0001
   
   * Modified by          : Siva Kumar M
   * Modified Date        : 05-JAN-16
   * Modified For         : MVHOST-1255
   * Modified reason      : reason code logging
   * Reviewer             : Saravans kumar 
   * Build Number         : RI0027.3.3_B0002
   
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
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-4-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
    
**************************************************************************************************/
   v_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   exp_reject_record    EXCEPTION;
   v_resp_cde           VARCHAR2 (2);
   v_err_msg            VARCHAR2 (300);
   v_auth_id            VARCHAR2 (6);
   v_func_code          cms_func_mast.cfm_func_code%TYPE;
   v_prod_code          cms_appl_pan.cap_prod_code%TYPE;
   v_card_type          cms_appl_pan.cap_card_type%TYPE;
   v_card_acct_no       cms_appl_pan.cap_acct_no%TYPE;
   v_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_acct_balance       cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   v_check_statcnt      NUMBER (1);
   v_check_funcattach   NUMBER (1);
   v_dr_cr_flag         cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
   v_cracct_no          cms_func_prod.cfp_cracct_no%TYPE;
   v_dracct_no          cms_func_prod.cfp_dracct_no%TYPE;
   v_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
   v_card_curr          cms_bin_param.cbp_param_value%TYPE;
   v_reasondesc         cms_spprt_reasons.csr_reasondesc%TYPE;
   v_rrn_count          NUMBER;
   p1                   NUMBER                                      DEFAULT 0;
   v_reason             VARCHAR2 (100);
   v_cnt                NUMBER (2);
   -- added on 16FEB2012 to check rowcount for insert
   v_table_list         VARCHAR2 (2000);
   v_colm_list          VARCHAR2 (2000);
   v_colm_qury          VARCHAR2 (2000);
   v_old_value          VARCHAR2 (2000);
   v_new_value          VARCHAR2 (2000);
   v_call_seq           NUMBER (3);
   v_status_chk         NUMBER;
   v_expry_date         cms_appl_pan.cap_expry_date%TYPE;
   v_cam_type_code      cms_acct_mast.cam_type_code%TYPE;
   v_chk_acct_type      NUMBER (1);
   v_ccs_appl_status    cms_cardissuance_status.ccs_card_status%TYPE;
   v_spnd_acctno        cms_appl_pan.cap_acct_no%TYPE;
                                              -- ADDED BY GANESH ON 19-JUL-12,
   v_timestamp       timestamp;                         -- Added on 17-Apr-2013 for defect 10871
   
   v_Retperiod  date; --Added for VMS-5733/FSP-991
   v_Retdate  date; --Added for VMS-5733/FSP-991

BEGIN
   -- Main begin starts here
   BEGIN
      -- Adhoc Fees begin starts here
      v_err_msg := 'OK';
      SAVEPOINT p1;

      IF prm_adhoc_fees < 0
      THEN
         v_resp_cde := '25';
         v_err_msg := 'Amount invalid ';
         RAISE exp_reject_record;
      END IF;

      --SN CREATE HASH PAN
      BEGIN
         v_hash_pan := gethash (prm_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while converting pan into hash'
               || prm_card_no
               || ' '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --EN CREATE HASH PAN

      /*  call log info   start */

      -- SN : ADDED BY Ganesh on 18-JUL-12
      BEGIN
         SELECT cap_acct_no
           INTO v_spnd_acctno
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan
            AND cap_inst_code = prm_inst_code
            AND cap_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Spending Account Number Not Found For the Card in PAN Master ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error While Selecting Spending account Number for Card '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

-- EN : ADDED BY Ganesh on 18-JUL-12
      BEGIN
         BEGIN
            SELECT NVL (MAX (ccd_call_seq), 0) + 1
              INTO v_call_seq
              FROM cms_calllog_details
             WHERE ccd_inst_code = prm_inst_code
               AND ccd_call_id = prm_call_id
               AND ccd_pan_code = v_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '16';
               v_err_msg := 'record is not present in cms_calllog_details  ';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Error while selecting frmo cms_calllog_details '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;

         INSERT INTO cms_calllog_details
                     (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                      ccd_rrn, ccd_devl_chnl, ccd_txn_code,
                      ccd_tran_date, ccd_tran_time, ccd_tbl_names,
                      ccd_colm_name, ccd_old_value, ccd_new_value,
                      ccd_comments, ccd_ins_user, ccd_ins_date,
                      ccd_lupd_user, ccd_lupd_date,
                      ccd_acct_no
                                 -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                     )
              VALUES (prm_inst_code, prm_call_id, v_hash_pan, v_call_seq,
                      prm_rrn, prm_delivery_chnl, prm_txn_code,
                      prm_tran_date, prm_tran_time, NULL,
                      NULL, NULL, NULL,
                      prm_remark, prm_ins_user, SYSDATE,
                      prm_ins_user, SYSDATE,
                      v_spnd_acctno
                               -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
                     );
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while inserting into cms_calllog_details '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      /*  call log info   END */

      --SN create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (prm_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while converting pan into encrypted pan for'
               || prm_card_no
               || ' '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN create encr pan

      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 100);
            prm_resp_code := '99';
            RETURN;
      END;

      --En generate auth id



      --Sn Duplicate RRN Check
      BEGIN
  v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

IF (v_Retdate>v_Retperiod)
    THEN
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
        ELSE
              SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE instcode = prm_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND delivery_channel = prm_delivery_chnl
            AND txn_code = prm_txn_code
            AND business_date = prm_tran_date
            AND business_time = prm_tran_time;
          END IF;  

         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_err_msg := 'Duplicate RRN found' || prm_rrn;
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
                  'While checking for duplicate '
               || prm_rrn
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --Sn: find reason desc for reason code
          BEGIN
             SELECT csr_reasondesc
               INTO v_reasondesc
               FROM cms_spprt_reasons
              WHERE csr_inst_code = prm_inst_code
                AND csr_spprt_rsncode = prm_reason_code;
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                v_resp_cde := '16';
                v_err_msg :=
                            'reason desc not found in master ' || prm_reason_code;
                RAISE exp_reject_record;
             WHEN OTHERS
             THEN
                v_resp_cde := '21';
                v_err_msg :=
                      'Problem while selecting reason desc '
                   || SUBSTR (SQLERRM, 1, 100);
                RAISE exp_reject_record;
          END;

          --Sn: find reason desc for reason code 
      --En Duplicate RRN Check
      BEGIN
         SELECT 1
           INTO v_chk_acct_type
           FROM cms_acct_type
          WHERE cat_inst_code = prm_inst_code
                AND cat_type_code = prm_acct_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '08';
            v_err_msg := 'Account type not found in master' || prm_acct_type;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '49';
            v_err_msg :=
                  'error while validating account type '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      IF prm_acct_type = '1'                     -- check for spending account
      THEN
         BEGIN
            SELECT cam_type_code, cam_acct_bal, cam_ledger_bal
              INTO v_cam_type_code, v_acct_balance, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code AND cam_acct_no = prm_acct_no;

            prm_final_bal := TO_CHAR (v_acct_balance);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '07';
               v_err_msg := 'account not found in master' || prm_acct_no;
            WHEN OTHERS
            THEN
               v_resp_cde := '49';
               v_err_msg :=
                     'error while validating account number '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;

         IF v_cam_type_code <> prm_acct_type
         THEN
            v_resp_cde := '08';
            v_err_msg :=
               'account type not matching with input accout type for spending';
            RAISE exp_reject_record;
         END IF;

         IF v_acct_balance < prm_adhoc_fees
         THEN
            v_resp_cde := '15';
            v_err_msg := 'Insufficient balance in spending account';
            RAISE exp_reject_record;
         END IF;
      ELSIF prm_acct_type = '2'                    -- check for saving account
      THEN
         BEGIN
            SELECT cam_type_code, cam_acct_bal, cam_ledger_bal
              INTO v_cam_type_code, v_acct_balance, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code AND cam_acct_no = prm_acct_no;

            prm_final_bal := TO_CHAR (v_acct_balance);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '07';
               v_err_msg := 'Account not found in master' || prm_acct_no;
            WHEN OTHERS
            THEN
               v_resp_cde := '49';
               v_err_msg :=
                     'error while validating account number '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;

         IF v_cam_type_code <> prm_acct_type
         THEN
            v_resp_cde := '08';
            v_err_msg :=
                'account type not matching with input accout type for saving';
            RAISE exp_reject_record;
         END IF;

         IF v_acct_balance < prm_adhoc_fees
         THEN
            v_resp_cde := '15';
            v_err_msg := 'Insufficient balance in saving account';
            RAISE exp_reject_record;
         END IF;
      END IF;

      --Sn get the prod detail
      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_expry_date,
                cap_acct_no                                                     --Added for defect 10871
           INTO v_prod_code, v_card_type, v_card_stat, v_expry_date,
                v_card_acct_no                                                  --Added for defect 10871
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

      --En get the prod detail
      IF TO_DATE (prm_tran_date, 'yyyymmdd') > LAST_DAY (TRUNC (v_expry_date))
      -- last_day added by sagar on 28-May-2012
      THEN
         v_resp_cde := '13';
         v_err_msg := 'Expired Card';
         RAISE exp_reject_record;
      END IF;

      BEGIN
         SELECT ccs_card_status
           INTO v_ccs_appl_status
           FROM cms_cardissuance_status
          WHERE ccs_inst_code = prm_inst_code AND ccs_pan_code = v_hash_pan;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Pan not found for application status';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'While fetching application status '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      IF v_ccs_appl_status <> '15'
      THEN
         v_resp_cde := '49';
         v_err_msg := 'Card Not In Shipped State';
         RAISE exp_reject_record;
      END IF;

      BEGIN
         sp_status_check_gpr (prm_inst_code,
                              prm_card_no,
                              prm_delivery_chnl,
                              v_expry_date,
                              v_card_stat,
                              prm_txn_code,
                              prm_txn_mode,
                              v_prod_code,
                              v_card_type,
                              prm_msg_type,
                              prm_tran_date,
                              prm_tran_time,
                              null,
                              null,  --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                              null,
                              v_resp_cde,
                              v_err_msg
                             );

         IF (   (v_resp_cde <> '1' AND v_err_msg <> 'OK')
             OR (v_resp_cde <> '0' AND v_err_msg <> 'OK')
            )
         THEN
            RAISE exp_reject_record;
         ELSE
            v_status_chk := v_resp_cde;
            v_resp_cde := '1';
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Error from GPR Card Status Check '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF v_status_chk = '1'
      THEN              -- IF condition checked for GPR changes on 27-FEB-2012
         --Sn check card stat
         BEGIN
            SELECT COUNT (1)
              INTO v_check_statcnt
              FROM pcms_valid_cardstat
             WHERE pvc_inst_code = prm_inst_code
               AND pvc_card_stat = v_card_stat
               AND pvc_tran_code = prm_txn_code
               AND pvc_delivery_channel = prm_delivery_chnl;

            IF v_check_statcnt = 0
            THEN
               v_resp_cde := '10'; -- response id changed from 49 to 10 on 09Oct2012
               v_err_msg := 'Invalid Card Status';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while selecting card stat '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      --En check card stat
      END IF;

      --Sn find the card curr
      BEGIN
--         SELECT TRIM (cbp_param_value)
--           INTO v_card_curr
--           FROM cms_appl_pan, cms_bin_param, cms_prod_mast
--          WHERE cap_inst_code = cbp_inst_code
--            AND cpm_inst_code = cbp_inst_code
--            AND cap_prod_code = cpm_prod_code
--            AND cpm_profile_code = cbp_profile_code
--            AND cbp_param_name = 'Currency'
--            AND cap_pan_code = v_hash_pan                 --prm_orgnl_card_no;
--            AND cap_mbr_numb = prm_mbr_numb;

vmsfunutilities.get_currency_code(v_prod_code,v_card_type,prm_inst_code,v_card_curr,v_err_msg);
      
      if v_err_msg<>'OK' then
           raise exp_reject_record;
      end if;

         IF TRIM (v_card_curr) IS NULL
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Card currency cannot be null ';
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
                  'Error while selecting card currecy  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --En find the card curr

      --Sn check card currency with txn currency --------
      IF v_card_curr <> prm_txn_curr
      THEN
         v_err_msg :=
                    'Both from card currency and txn currency are not same  ';
         v_resp_cde := '21';
         RAISE exp_reject_record;
      END IF;

      --En check card currency with txn currency
      --Sn commented for fwr-48
      --SN identify adhoc fee txn
   /*   BEGIN
         SELECT cfm_func_code
           INTO v_func_code
           FROM cms_func_mast
          WHERE cfm_inst_code = prm_inst_code
            AND cfm_txn_code = prm_txn_code
            AND cfm_txn_mode = prm_txn_mode
            AND cfm_delivery_channel = prm_delivery_chnl;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            prm_resp_code := '21';
            prm_errmsg := 'function code is not defined in master';
            RETURN;
         WHEN OTHERS
         THEN
            prm_resp_code := '21';
            prm_errmsg :=
                  'Error while master data for Adhoc Fees '
               || SUBSTR (SQLERRM, 1, 100);
            RETURN;
      END;

      --En identify adhoc fee txn
      BEGIN
         SELECT cfp_cracct_no, cfp_dracct_no
           INTO v_cracct_no, v_dracct_no
           FROM cms_func_prod
          WHERE cfp_func_code = v_func_code
            AND cfp_prod_code = v_prod_code
            AND cfp_prod_cattype = v_card_type
            AND cfp_inst_code = prm_inst_code;

         IF TRIM (v_cracct_no) IS NULL AND TRIM (v_dracct_no) IS NULL
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Both credit and debit account cannot be null for a transaction code '
               || prm_txn_code
               || ' Function code '
               || v_func_code;
            RAISE exp_reject_record;
         END IF;

         IF TRIM (v_cracct_no) = TRIM (v_dracct_no)
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Credit and debit account cannot be same ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=
                  'Credit and debit gl is not defined for the funcode'
               || v_func_code
               || ' Product '
               || v_prod_code
               || 'Prod cattype '
               || v_card_type;
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'More than one record found for function code '
               || v_func_code
               || ' Product '
               || v_prod_code
               || 'Prod cattype '
               || v_card_type;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Error while selecting GL details '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;*/

      --en find the orginal credit and debit leg

      --En commented for fwr-48

      --Sn find the type of txn (credit or debit)
      BEGIN
         SELECT ctm_credit_debit_flag, ctm_tran_desc
           INTO v_dr_cr_flag, v_tran_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_txn_code
            AND ctm_delivery_channel = prm_delivery_chnl
            AND ctm_inst_code = prm_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=
                  'Transaction detail is not found in master for Adhoc Fees txn '
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

      --En find the type of txn (credit or debit)

    /*  --Sn: find reason desc for reason code   commented and moved to above
      BEGIN
         SELECT csr_reasondesc
           INTO v_reasondesc
           FROM cms_spprt_reasons
          WHERE csr_inst_code = prm_inst_code
            AND csr_spprt_rsncode = prm_reason_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=
                        'reason desc not found in master ' || prm_reason_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting reason desc '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --Sn: find reason desc for reason code  */
      BEGIN
         IF v_dr_cr_flag = 'DR'
         THEN
            UPDATE cms_acct_mast
               SET cam_acct_bal = cam_acct_bal - prm_adhoc_fees,
                   cam_ledger_bal = cam_ledger_bal - prm_adhoc_fees
             WHERE cam_inst_code = prm_inst_code AND cam_acct_no = prm_acct_no;

            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while updating in account master for transaction account '
                  || prm_acct_no
                  || ' and db/cr flag '
                  || v_dr_cr_flag;
               RAISE exp_reject_record;
            END IF;

       /*     BEGIN
               sp_ins_eodupdate_acct_cmsauth (prm_rrn,
                                              NULL,
                                              prm_delivery_chnl,
                                              prm_txn_code,
                                              prm_txn_mode,
                                              TO_DATE (prm_tran_date,
                                                       'yyyymmdd'
                                                      ),
                                              prm_card_no,
                                              v_cracct_no,
                                              prm_adhoc_fees,
                                              'C',
                                              prm_inst_code,
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
                  v_err_msg :=
                        'error occured while crediting gl '
                     || SUBSTR (SQLERRM, 1, 100);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
            END;*/--review changes for fwr-48

             v_timestamp := systimestamp;      -- Added on 17-Apr-2013 for defect 10871

            BEGIN
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_opening_bal, csl_trans_amount,
                            csl_trans_type,
                            csl_trans_date,
                            csl_closing_balance,
                            csl_trans_narrration, csl_inst_code,
                            csl_pan_no_encr, csl_rrn, csl_business_date,
                            csl_business_time, csl_delivery_channel,
                            csl_txn_code, csl_auth_id, csl_ins_date,
                            csl_ins_user, csl_acct_no, txn_fee_flag,
                            CSL_PANNO_LAST4DIGIT,                       -- added by sagar on 21Aug2012 to store last 4 digits of pan code
                            CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
                            CSL_TIME_STAMP,        -- Added on 17-Apr-2013 for defect 10871
                            CSL_PROD_CODE,          -- Added on 17-Apr-2013 for defect 10871
                           csl_card_type
                           )
                    VALUES (v_hash_pan,
                            --v_acct_balance,       -- Commented for 10871
                            v_ledger_bal,            -- Added for 10871
                            prm_adhoc_fees,
                            v_dr_cr_flag,
                            TO_DATE (prm_tran_date, 'yyyymmdd'),
                            v_ledger_bal - prm_adhoc_fees,          -- v_acct_bal replaced by v_ledger_bal for defect 10871
                            'Adhoc Fees - ' || v_reasondesc, prm_inst_code,
                            v_encr_pan, prm_rrn, prm_tran_date,
                            prm_tran_time, prm_delivery_chnl,
                            prm_txn_code, v_auth_id, SYSDATE,
                            1, prm_acct_no, 'Y',
                            SUBSTR(prm_card_no, LENGTH(prm_card_no) - 3, LENGTH(prm_card_no)), -- added by sagar on 21Aug2012 to store last 4 digits of pan code
                            v_cam_type_code,    -- Added on 17-Apr-2013 for defect 10871
                            v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
                            v_prod_code  ,       -- Added on 17-Apr-2013 for defect 10871
                            v_card_type
                           );
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Problem while inserting into statement log for adhoc fees amount '
                     || prm_adhoc_fees
                     || ' and db/cr flag '
                     || v_dr_cr_flag
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSIF NVL (v_dr_cr_flag, '0') NOT IN ('DR')
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'invalid debit/credit flag '
               || v_dr_cr_flag
               || ' for deliver chnl '
               || prm_delivery_chnl
               || ' and txn code '
               || prm_txn_code;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while updating acct master for db/cr flag = '
               || v_dr_cr_flag
               || ' '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --Sn get record for successful transaction
      v_resp_cde := '1';

      BEGIN
         SELECT cms_iso_respcde
           INTO prm_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = prm_inst_code
            AND cms_delivery_channel = prm_delivery_chnl
            AND cms_response_id = v_resp_cde;

         prm_errmsg := v_err_msg;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Problem while selecting data from response master1 '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 100);
            prm_resp_code := '89';
            ROLLBACK;
            RETURN;
      END;

      --En get record for successful transaction
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_txn_amount, ctd_fee_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_bill_amount, ctd_bill_curr,
                      ctd_process_flag, ctd_process_msg, ctd_rrn,
                      ctd_system_trace_audit_no, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number,
                      ctd_ins_date, ctd_ins_user
                     )
              VALUES (prm_delivery_chnl, prm_txn_code, v_dr_cr_flag,
                      prm_msg_type, prm_txn_mode, prm_tran_date,
                      prm_tran_time, v_hash_pan,
                      '0.00', prm_adhoc_fees, prm_txn_curr,
                      prm_adhoc_fees, prm_adhoc_fees, v_card_curr,
                      'Y', prm_errmsg, prm_rrn,
                      prm_stan, prm_inst_code,
                      v_encr_pan, prm_acct_no,
                      SYSDATE, prm_ins_user
                     );
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while inserting in transactionlog detail '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      -- Sn create a entry in txnlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type,
                      bank_code, total_amount, rule_indicator, rulegroupid,
                      mccode, currencycode, productid, categoryid, tips,
                      decline_ruleid, atm_name_location, auth_id,
                      trans_desc,
                      tranfee_amt, amount, preauthamount, partialamount,
                      mccodegroupid, currencycodegroupid, transcodegroupid,
                      rules, preauth_date, gl_upd_flag,
                      system_trace_audit_no, instcode, feecode,
                      feeattachtype, tran_reverse_flag,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance,
                      ledger_balance,
                      error_msg, add_ins_date, add_ins_user, response_id,
                      remark, reason, tranfee_cr_acctno, tranfee_dr_acctno,
                      cr_dr_flag, --added by amit on 06-Oct-2012 to log cr-dr flag in transaction log table.
                      ipaddress,  --added by amit on 06-Oct-2012 to log ip address in transaction log table.
                      add_lupd_user, --added by amit on 06-Oct-2012 to log lupduser in transaction log table.
                      MERCHANT_NAME, --added by Dnyaneshwar on 16-April-2013 to log merchant name
                      time_stamp,        --Added for defect 10871
                      cardstatus,       --Added for defect 10871
                      acct_type,         --Added for defect 10871
                      reason_code    --Added for mvhost-1255
                     )
              VALUES (prm_msg_type, prm_rrn, prm_delivery_chnl, NULL,
                      TO_DATE (prm_tran_date || ' ' || prm_tran_time,'yyyymmdd hh24miss'), prm_txn_code, 1, prm_txn_mode,
                      DECODE (prm_resp_code, '00', 'C', 'F'), prm_resp_code,
                      prm_tran_date, prm_tran_time, v_hash_pan,
                      NULL, NULL, NULL,
                      prm_inst_code, TRIM(TO_CHAR(NVL(prm_adhoc_fees,0), '99999999999999990.99')), NULL, NULL,--to_cha(nvl added for defect 10871
                      NULL, prm_txn_curr, v_prod_code, v_card_type, 0.00,
                      NULL, NULL, v_auth_id,
                      SUBSTR ('Adhoc Fees - ' || v_reasondesc, 1, 40),
                      prm_adhoc_fees, '0.00', '0.00', '0.00',           --Null replaced by '0.00' for defect 10871
                      NULL, NULL, NULL,
                      NULL, NULL, 'Y',
                      prm_stan, prm_inst_code, NULL,
                      NULL, 'N',
                      v_encr_pan, NULL,
                      NULL,                          --v_proxy_number, discuss
                           prm_rvsl_code, prm_acct_no,
                      DECODE (v_dr_cr_flag,
                              'DR', v_acct_balance - TRIM(TO_CHAR(NVL(prm_adhoc_fees,0), '99999999999999990.99')),
                              v_acct_balance
                             ),
                      DECODE (v_dr_cr_flag,
                              'DR', v_ledger_bal - TRIM(TO_CHAR(NVL(prm_adhoc_fees,0), '99999999999999990.99')),
                              v_ledger_bal
                             ),
                      prm_errmsg, SYSDATE, prm_ins_user, v_resp_cde,
                      prm_remark, v_reasondesc, v_cracct_no, prm_acct_no,
                      v_dr_cr_flag, --added by amit on 06-Oct-2012 to log cr-dr flag in transaction log table.
                      prm_ipaddress, --added by amit on 06-Oct-2012 to log ip address in transaction log table.
                      prm_ins_user, --added by amit on 06-Oct-2012 to log lupduser in transaction log table.
                      'System', --added by Dnyaneshwar on 16-April-2013 to log merchant name--Modify by Dnyaneshwar J on 09 May 2013
                      v_timestamp,  --Added for defect 10871
                      v_card_stat,  --Added for defect 10871
                      v_cam_type_code,   --Added for defect 10871
                      prm_reason_code    --Added for mvhost-1255
                     );
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while inserting in transactionlog '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      -- Sn create a entry in txnlog
      prm_errmsg := v_err_msg;

      SELECT DECODE (v_dr_cr_flag,
                     'DR', v_acct_balance - prm_adhoc_fees,
                     v_acct_balance
                    )
        INTO prm_final_bal
        FROM DUAL;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK TO SAVEPOINT p1;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal,
                   cam_type_code                    --Added for defect 10871
              INTO v_acct_balance, v_ledger_bal,
                   v_cam_type_code                  --Added for defect 10871
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code AND cam_acct_no = prm_acct_no;

            prm_final_bal := TO_CHAR (v_acct_balance);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
               prm_final_bal := 0;
         END;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_chnl
               AND cms_response_id = v_resp_cde;

            prm_errmsg := v_err_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Problem while selecting data from response master2 '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_msg_type, ctd_txn_mode, ctd_business_date,
                         ctd_business_time, ctd_customer_card_no,
                         ctd_txn_amount, ctd_fee_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no, ctd_inst_code,
                         ctd_customer_card_no_encr, ctd_cust_acct_number,
                         ctd_ins_date, ctd_ins_user
                        )
                 VALUES (prm_delivery_chnl, prm_txn_code, v_dr_cr_flag,
                         prm_msg_type, prm_txn_mode, prm_tran_date,
                         prm_tran_time, v_hash_pan,
                         '0.00', prm_adhoc_fees, prm_txn_curr,
                         prm_adhoc_fees, prm_adhoc_fees, v_card_curr,
                         'E', prm_errmsg, prm_rrn,
                         prm_stan, prm_inst_code,
                         v_encr_pan, prm_acct_no,
                         SYSDATE, prm_ins_user
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in log detail 1 '
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

     -----------------------------------------------
     --SN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------

     if V_PROD_CODE is null
     then

         BEGIN

              SELECT CAP_CARD_STAT,
                     CAP_PROD_CODE,
                     CAP_CARD_TYPE,
                     CAP_ACCT_NO
              INTO   V_CARD_STAT,
                     V_PROD_CODE,
                     V_CARD_TYPE,
                     v_card_acct_no
              FROM   CMS_APPL_PAN
              WHERE  CAP_INST_CODE = PRM_INST_CODE
              AND    CAP_PAN_CODE  = V_HASH_PAN;

         EXCEPTION WHEN OTHERS THEN
            null;

         END;

     end if;


     if V_DR_CR_FLAG is null
     then

        BEGIN

             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO V_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = Prm_TXN_CODE
              AND   CTM_DELIVERY_CHANNEL = prm_delivery_chnl
              AND   CTM_INST_CODE = PRM_INST_CODE;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;

     -----------------------------------------------
     --EN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------


         -- Sn create a entry in txnlog
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, terminal_id,
                         date_time, txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no, topup_card_no, topup_acct_no,
                         topup_acct_type, bank_code, total_amount,
                         rule_indicator, rulegroupid, mccode, currencycode,
                         productid, categoryid, tips, decline_ruleid,
                         atm_name_location, auth_id,
                         trans_desc,
                         tranfee_amt, amount, preauthamount, partialamount,
                         mccodegroupid, currencycodegroupid,
                         transcodegroupid, rules, preauth_date, gl_upd_flag,
                         system_trace_audit_no, instcode, feecode,
                         feeattachtype, tran_reverse_flag,
                         customer_card_no_encr, topup_card_no_encr,
                         proxy_number, reversal_code, customer_acct_no,
                         acct_balance, ledger_balance, error_msg,
                         add_ins_date, add_ins_user, response_id, remark,
                         reason, tranfee_cr_acctno, tranfee_dr_acctno,
                         cr_dr_flag, --added by amit on 06-Oct-2012 to log cr-dr flag in transaction log table.
                         ipaddress,  --added by amit on 06-Oct-2012 to log ip address in transaction log table.
                         add_lupd_user, --added by amit on 06-Oct-2012 to log lupduser in transaction log table.
                         MERCHANT_NAME, --added by Dnyaneshwar on 16-April-2013 to log merchant name
                         time_stamp,        --Added for defect 10871
                         cardstatus,       --Added for defect 10871
                         acct_type,         --Added for defect 10871
                         reason_code       --Added for mvhost-1255
                        )
                 VALUES (prm_msg_type, prm_rrn, prm_delivery_chnl, NULL,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,'yyyymmdd hh24miss'), prm_txn_code, 1, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_tran_date, prm_tran_time,
                         v_hash_pan, NULL, NULL,
                         NULL, prm_inst_code, TRIM(TO_CHAR(NVL(prm_adhoc_fees,0), '99999999999999990.99')), --Added for defect 10871
                         NULL, NULL, NULL, prm_txn_curr,
                         v_prod_code, v_card_type, '0.00', NULL,
                         NULL, v_auth_id,
                         SUBSTR ('Adhoc Fees - ' || v_reasondesc, 1, 40),
                         prm_adhoc_fees, '0.00', '0.00', '0.00', -- null replaced by 0.00 for defect 10871
                         NULL, NULL,
                         NULL, NULL, NULL, 'N',
                         prm_stan, prm_inst_code, NULL,
                         NULL, 'N',
                         v_encr_pan, NULL,
                         NULL,                       --v_proxy_number, discuss
                              prm_rvsl_code, prm_acct_no,
                         v_acct_balance, v_ledger_bal, prm_errmsg,
                         SYSDATE, prm_ins_user, v_resp_cde, prm_remark,
                         v_reasondesc, v_cracct_no, prm_acct_no,
                         v_dr_cr_flag, --added by amit on 06-Oct-2012 to log cr-dr flag in transaction log table.
                         prm_ipaddress, --added by amit on 06-Oct-2012 to log ip address in transaction log table.
                         prm_ins_user, --added by amit on 06-Oct-2012 to log lupduser in transaction log table.
                         'System', --added by Dnyaneshwar on 16-April-2013 to log merchant name--Modified by Dnyaneshwar J on 09 May 2013
                         NVL(v_timestamp,SYSTIMESTAMP),  --Added for defect 10871
                         v_card_stat,  --Added for defect 10871
                         v_cam_type_code,   --Added for defect 10871
                         prm_reason_code   --Added for mvhost-1255
                        );
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in txnlog 1 '
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
      -- Sn create a entry in txnlog
      WHEN OTHERS
      THEN
         ROLLBACK;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code AND cam_acct_no = prm_acct_no;

            prm_final_bal := TO_CHAR (v_acct_balance);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
               prm_final_bal := 0;
         END;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_chnl
               AND cms_response_id = '21';

            prm_errmsg :=
                    'Error from others exception ' || SUBSTR (SQLERRM, 1, 100);
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Problem while selecting data from response master3 '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_msg_type, ctd_txn_mode, ctd_business_date,
                         ctd_business_time, ctd_customer_card_no,
                         ctd_fee_amount, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no, ctd_inst_code,
                         ctd_customer_card_no_encr, ctd_cust_acct_number,
                         ctd_ins_date, ctd_ins_user
                        )
                 VALUES (prm_delivery_chnl, prm_txn_code, v_dr_cr_flag,
                         prm_msg_type, prm_txn_mode, prm_tran_date,
                         prm_tran_time, v_hash_pan,
                         prm_adhoc_fees, '0.00', prm_txn_curr,
                         prm_adhoc_fees, prm_adhoc_fees, v_card_curr,
                         'E', prm_errmsg, prm_rrn,
                         prm_stan, prm_inst_code,
                         v_encr_pan, prm_acct_no,
                         SYSDATE, prm_ins_user
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in log detail 2 '
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;


     -----------------------------------------------
     --SN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------

     if V_PROD_CODE is null
     then

         BEGIN

              SELECT CAP_CARD_STAT,
                     CAP_PROD_CODE,
                     CAP_CARD_TYPE,
                     CAP_ACCT_NO
              INTO   V_CARD_STAT,
                     V_PROD_CODE,
                     V_CARD_TYPE,
                     v_card_acct_no
              FROM   CMS_APPL_PAN
              WHERE  CAP_INST_CODE = Prm_INST_CODE
              AND    CAP_PAN_CODE  = V_HASH_PAN;

         EXCEPTION WHEN OTHERS THEN
            null;

         END;

     end if;


     if V_DR_CR_FLAG is null
     then

        BEGIN

             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO V_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = Prm_TXN_CODE
              AND   CTM_DELIVERY_CHANNEL = prm_delivery_chnl
              AND   CTM_INST_CODE = Prm_INST_CODE;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;

     -----------------------------------------------
     --EN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------

         -- Sn create a entry in txnlog
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, terminal_id,
                         date_time, txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no, topup_card_no, topup_acct_no,
                         topup_acct_type, bank_code, total_amount,
                         rule_indicator, rulegroupid, mccode, currencycode,
                         productid, categoryid, tips, decline_ruleid,
                         atm_name_location, auth_id,
                         trans_desc,
                         tranfee_amt, amount, preauthamount, partialamount,
                         mccodegroupid, currencycodegroupid,
                         transcodegroupid, rules, preauth_date, gl_upd_flag,
                         system_trace_audit_no, instcode, feecode,
                         feeattachtype, tran_reverse_flag,
                         customer_card_no_encr, topup_card_no_encr,
                         proxy_number, reversal_code, customer_acct_no,
                         acct_balance, ledger_balance, error_msg,
                         add_ins_date, add_ins_user, response_id, remark,
                         reason, tranfee_cr_acctno, tranfee_dr_acctno,
                         cr_dr_flag, --added by amit on 06-Oct-2012 to log cr-dr flag in transaction log table.
                         ipaddress,  --added by amit on 06-Oct-2012 to log ip address in transaction log table.
                         add_lupd_user, --added by amit on 06-Oct-2012 to log lupduser in transaction log table.
                         time_stamp,        --Added for defect 10871
                         cardstatus,       --Added for defect 10871
                         acct_type,         --Added for defect 10871
                         MERCHANT_NAME,--Added by Dnyaneshwar J on 09 May 2013
                         reason_code   --Added for mvhost-1255
                        )
                 VALUES (prm_msg_type, prm_rrn, prm_delivery_chnl, NULL,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,'yyyymmdd hh24miss'), prm_txn_code, 1, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_tran_date, prm_tran_time,
                         v_hash_pan, NULL, NULL,
                         NULL, prm_inst_code, TRIM(TO_CHAR(NVL(prm_adhoc_fees,0), '99999999999999990.99')), --tRIM(TO_CHAR ADDED FOR DEFECT 10871
                         NULL, NULL, NULL, prm_txn_curr,
                         v_prod_code, v_card_type, '0.00', NULL,
                         NULL, v_auth_id,
                         SUBSTR ('Adhoc Fees - ' || v_reasondesc, 1, 40),
                         prm_adhoc_fees, '0.00', '0.00', '0.00', -- Null replaced by 0.00 for defect 10871
                         NULL, NULL,
                         NULL, NULL, NULL, 'N',
                         prm_stan, prm_inst_code, NULL,
                         NULL, 'N',
                         v_encr_pan, NULL,
                         NULL,                       --v_proxy_number, discuss
                              prm_rvsl_code, prm_acct_no,
                         v_acct_balance, v_ledger_bal, prm_errmsg,
                         SYSDATE, prm_ins_user, v_resp_cde, prm_remark,
                         v_reasondesc, v_cracct_no, prm_acct_no,
                         v_dr_cr_flag, --added by amit on 06-Oct-2012 to log cr-dr flag in transaction log table.
                         prm_ipaddress, --added by amit on 06-Oct-2012 to log ip address in transaction log table.
                         prm_ins_user, --added by amit on 06-Oct-2012 to log lupduser in transaction log table.
                         v_timestamp,  --Added for defect 10871
                         v_card_stat,  --Added for defect 10871
                        v_cam_type_code,   --Added for defect 10871
                        'System',--Added by Dnyaneshwar J on 09 May 2013
                        prm_reason_code  --Added for mvhost-1255
                        );
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in txnlog 2 '
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
   -- Sn create a entry in txnlog
   END;                                          -- Adhoc Fees begin ends here
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'ERROR FROM MAIN ' || SUBSTR (SQLERRM, 1, 100);
      prm_resp_code := '89';
END;                                                   -- Main begin ends here
/

show error