create or replace PROCEDURE  VMSCMS.sp_dispute_txns (
   prm_instcode              IN       NUMBER,
   prm_pancode               IN       VARCHAR2,
   prm_msg_type              IN       VARCHAR2,
   prm_mbrnumb               IN       VARCHAR2,
   prm_amount                IN       VARCHAR2,
   prm_rrn                   IN       VARCHAR2,
   prm_stan                  IN       NUMBER,
   prm_delv_chnl             IN       VARCHAR2, 
   prm_txn_date              IN       VARCHAR2,
   prm_txn_time              IN       VARCHAR2,
   prm_txn_code              IN       VARCHAR2,
   prm_txn_mode              IN       VARCHAR2,
   prm_orgnl_rrn             IN       VARCHAR2,
   prm_orgnl_card_no         IN       VARCHAR2,
   prm_orgnl_stan            IN       VARCHAR2,
   prm_orgnl_tran_date       IN       VARCHAR2,
   prm_orgnl_tran_time       IN       VARCHAR2,
   prm_orgnl_txn_amt         IN       VARCHAR2,
   prm_orgnl_txn_code        IN       VARCHAR2,
   prm_orgnl_delivery_chnl   IN       VARCHAR2,
   prm_call_id               IN       NUMBER,
   prm_dispute_stat          IN       VARCHAR2,
   prm_reversal_code         IN       NUMBER,
   prm_curr_code             IN       VARCHAR2,
   prm_remark                IN       VARCHAR2,
   PRM_REASON_CODE           IN       VARCHAR2,
  -- prm_reasondesc            IN       VARCHAR2,
   prm_ipaddress             IN          VARCHAR2,  --added by amit on 06-Oct-2012
   prm_lupduser              IN       NUMBER,
   prm_resp_code             OUT      VARCHAR2,
   prm_resp_msg              OUT      VARCHAR2
)
AS
/*************************************************
  * VERSION              :  1.0
  * Created Date         : 09/May/2012
  * Created By           : Pankaj S.
  * PURPOSE              : Dispute Transactions
  * modified for         : Internal Enhancement
  * modified Date        : 09-Oct-2012
  * modified reason      : Response id changed from 49 to 10
                           To show invalid card status msg in popup query
  * Reviewer             : Saravanakumar
  * Reviewed Date        : 09-OCT-12
   * Build Number        : CMS3.5.1_RI0019_B0008

  * Modified by          :  Dnyaneshwar J
  * Modified Reason      :  Mantis-13847
  * Modified Date        :  07-Mar-2014
  * Reviewer             : Dhiraj
  * Reviewed Date        : 18-03-2014
  * Build Number         : RI0027.2_B0002  
  * Modified by          :  Ramesh A
  * Modified Reason      :  Commented the card status check for not required
  * Modified Date        :  16-July-2015
  * Reviewer             : Pankaj S
  * Reviewed Date        : 17-July-2015
  * Build Number         : 3.0.4
  
  * Modified by          :  Abdul Hameed M.A
  * Modified Reason      :  Dispute button needs to be functional for all Card status
  * Modified Date        :  2-Sep-2015
  * Reviewer             : Saravanankumar
  * Reviewed Date        :  2-Sep-2015
  * Build Number         :  VMSGPRHOAT_3.1_B0008
  
  * Modified by          :  Siva Kumar M
  * Modified Reason      :  FSS-3742
  * Modified Date        :  02-11-015
  * Reviewer             : Saravana Kumar m
  * Reviewed Date        : 03-11-015
  * Build Number         : VMSGPRHOAT_3.2 
  
  * Modified by          : Spankaj
  * Modified Date        : 28-Dec-15
  * Modified For         : CFIP-214
  * Reviewer             : Saravanankumar
  * Build Number         : VMSGPRHOSTCSD3.3
  
  * Modified by          : Siva Kumar M
  * Modified Date        : 05-Jan-16
  * Modified For         : MVHOST-1255
  * Reviewer             : Saravanankumar
  * Build Number         : VMSGPRHOSTCSD3.3_B00002
  
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

***********************************************/
   v_hash_pan            cms_appl_pan.cap_pan_code%TYPE;
   v_call_seq            NUMBER (3);
   v_resp_code           VARCHAR2 (3);
   v_resp_msg            VARCHAR2 (300);
   v_rrn_count           NUMBER (3);
   v_encr_pan            cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cap_acct_no         cms_appl_pan.cap_acct_no%TYPE;
   v_prod_code           cms_appl_pan.cap_prod_code%TYPE;
   v_prod_cattype        cms_appl_pan.cap_card_type%TYPE;
   v_card_stat           cms_appl_pan.cap_card_stat%TYPE;
   v_status_chk          NUMBER;
   v_check_statcnt       NUMBER (1);
   v_expry_date          cms_appl_pan.cap_expry_date%TYPE;
   v_proxynumber         cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_balance        cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_balance      cms_acct_mast.cam_ledger_bal%TYPE;
   v_auth_id             transactionlog.auth_id%TYPE;
   v_dr_cr_flag          cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_tran_desc           cms_transaction_mast.ctm_tran_desc%TYPE;
   v_reverse_flag        transactionlog.tran_reverse_flag%TYPE;
   v_fee_reversal_flag   transactionlog.fee_reversal_flag%TYPE;
   v_reversalcode        transactionlog.reversal_code%TYPE;
   v_ccs_appl_status     cms_cardissuance_status.ccs_card_status%TYPE;
   v_authid_date         VARCHAR2 (8);
   excp_rej_record       EXCEPTION;
   v_spnd_acctno          cms_appl_pan.cap_acct_no%TYPE;
   v_txn_date  transactionlog.add_ins_date%TYPE;
   v_crdr_flag  transactionlog.cr_dr_flag%TYPE;
   v_chargeback_val      CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
-- ADDED BY GANESH ON 19-JUL-12
   
    v_reason_desc       cms_spprt_reasons.CSR_REASONDESC%TYPE;
    
    v_Retperiod  date; --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991
    
BEGIN                                                       --<<Main Begin>>--
   prm_resp_code := '00';
   prm_resp_msg := 'OK';

   BEGIN                                                --<<Begin I Start>>--
      --Sn get hash pan
      BEGIN
         v_hash_pan := gethash (prm_pancode);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while converting pan into hash '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_rej_record;
      END;

      --En get hash pan

       --Sn find the type of orginal txn (credit or debit)
      BEGIN
         SELECT ctm_credit_debit_flag, ctm_tran_desc
           INTO v_dr_cr_flag, v_tran_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_txn_code
            AND ctm_delivery_channel = prm_delv_chnl
            AND ctm_inst_code = prm_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_code := '49';
            v_resp_msg :=
                  'Transaction detail is not found in master for reversal txn '
               || prm_txn_code
               || 'delivery channel '
               || prm_delv_chnl;
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Problem while selecting debit/credit flag '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      --En find the type of orginal txn (credit or debit)

      --Sn call log info

      -- SN : ADDED BY Ganesh on 18-JUL-12
      BEGIN
         SELECT cap_acct_no
           INTO v_spnd_acctno
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan
            AND cap_inst_code = prm_instcode
            AND cap_mbr_numb = prm_mbrnumb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_code := '21';
            v_resp_msg :=
               'Spending Account Number Not Found For the Card in PAN Master ';
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error While Selecting Spending account Number for Card '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

-- EN : ADDED BY Ganesh on 18-JUL-12


---SN Reason code description 
     
     begin
     
     select  csr_reasondesc 
     into v_reason_desc 
     from cms_spprt_reasons 
     where csr_spprt_rsncode=prm_reason_code
     and csr_inst_code=prm_instcode;
      
      EXCEPTION
        WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg  :=
                  ' Error while selecting data from spprt reasons  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
     
     end;
     
     
     -- EN  Reason code description 
     
     
     
      BEGIN
         BEGIN
            SELECT NVL (MAX (ccd_call_seq), 0) + 1
              INTO v_call_seq
              FROM cms_calllog_details
             WHERE ccd_inst_code = prm_instcode
               AND ccd_call_id = prm_call_id
               AND ccd_pan_code = v_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_code := '49';
               v_resp_msg := 'record is not present in cms_calllog_details  ';
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
                     (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                      ccd_rrn, ccd_devl_chnl, ccd_txn_code, ccd_tran_date,
                      ccd_tran_time, ccd_tbl_names, ccd_colm_name,
                      ccd_old_value, ccd_new_value, ccd_comments,
                      ccd_ins_user, ccd_ins_date, ccd_lupd_user,
                      ccd_lupd_date, ccd_acct_no
                     -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                     )
              VALUES (prm_instcode, prm_call_id, v_hash_pan, v_call_seq,
                      prm_rrn, prm_delv_chnl, prm_txn_code, prm_txn_date,
                      prm_txn_time, NULL, NULL,
                      NULL, NULL, prm_remark,
                      prm_lupduser, SYSDATE, prm_lupduser,
                      SYSDATE, v_spnd_acctno
                     -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
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

      --En call log info

      --Sn get encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (prm_pancode);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while converting pan into encr '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      --En get encr pan

      --Sn generate auth id
      BEGIN
         /*SELECT TO_CHAR (SYSDATE, 'YYYYMMDD')
           INTO v_authid_date
           FROM DUAL;

         SELECT v_authid_date || LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;*/

           SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO v_auth_id FROM DUAL; --Added by Trivikram on 25/09/2012 for generated auth id with 6 character length

      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_code := '21';                           -- Server Declined
            RAISE excp_rej_record;
      END;

      --En generate auth id

      --Sn Duplicate rrn check
      BEGIN
      
      v_Retdate := TO_DATE(SUBSTR(TRIM(prm_txn_date), 1, 8), 'yyyymmdd');

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
          WHERE instcode = prm_instcode
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND delivery_channel = prm_delv_chnl
            AND txn_code = prm_txn_code
            AND business_date = prm_txn_date
            AND business_time = prm_txn_time;
       ELSE
               SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE instcode = prm_instcode
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND delivery_channel = prm_delv_chnl
            AND txn_code = prm_txn_code
            AND business_date = prm_txn_date
            AND business_time = prm_txn_time;
        END IF;    
                 

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
      v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_tran_date), 1, 8), 'yyyymmdd');

       select trunc(add_months(sysdate,'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';



IF (v_Retdate>v_Retperiod)
    THEN
      SELECT tran_reverse_flag, fee_reversal_flag, reversal_code,
                        add_ins_date, cr_dr_flag
           INTO v_reverse_flag, v_fee_reversal_flag, v_reversalcode,
                      v_txn_date, v_crdr_flag
           FROM transactionlog
          WHERE instcode = prm_instcode
            AND rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date
            AND business_time = prm_orgnl_tran_time
            AND customer_card_no = v_hash_pan
            AND NVL (AMOUNT, 0.00) = PRM_ORGNL_TXN_AMT
            AND RESPONSE_CODE='00'--sn:added by Dnyaneshwar J on 06 Mar 2014
            AND NVL(DISPUTE_FLAG,'N') <> 'Y' 
            AND TXN_CODE = prm_orgnl_txn_code  -- Added for  FSS-3742  on 02/11/15
            AND ROWNUM =1
            FOR UPDATE;--en:added by Dnyaneshwar J on 06 Mar 2014 for Mantis-13847
          ELSE
             SELECT tran_reverse_flag, fee_reversal_flag, reversal_code,
                        add_ins_date, cr_dr_flag
           INTO v_reverse_flag, v_fee_reversal_flag, v_reversalcode,
                      v_txn_date, v_crdr_flag
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE instcode = prm_instcode
            AND rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date
            AND business_time = prm_orgnl_tran_time
            AND customer_card_no = v_hash_pan
            AND NVL (AMOUNT, 0.00) = PRM_ORGNL_TXN_AMT
            AND RESPONSE_CODE='00'--sn:added by Dnyaneshwar J on 06 Mar 2014
            AND NVL(DISPUTE_FLAG,'N') <> 'Y' 
            AND TXN_CODE = prm_orgnl_txn_code  -- Added for  FSS-3742  on 02/11/15
            AND ROWNUM =1
            FOR UPDATE;--en:added by Dnyaneshwar J on 06 Mar 2014 for Mantis-13847
          END IF;    

         --Sn check for successful Transaction and get the detail...
         IF v_reversalcode <> '00'
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                       'Orginal transaction was not a successful transaction';
            RAISE excp_rej_record;
         END IF;

         --En check for successful Transaction and get the detail...
         
         --Sn Added for MVHOST-1249
         IF prm_orgnl_delivery_chnl  NOT IN ('01','02') THEN 
            v_resp_code := '21';
            v_resp_msg :='Invalid Dispute ';
            RAISE excp_rej_record;
         END IF;
         
         IF v_crdr_flag IS NULL OR  v_crdr_flag NOT IN ('CR','DR')THEN
            v_resp_code := '21';
            v_resp_msg :='Invalid Dispute ';
            RAISE excp_rej_record;
         END IF;
      --En Added for MVHOST-1249
      
        -- Commenting this check as part of VMS-932,VMS-935,VMS-936
        /* IF TRUNC(v_txn_date)<TRUNC(sysdate)-90 THEN
            v_resp_code := '21';
            v_resp_msg :='Invalid Dispute ';
            RAISE excp_rej_record;
         END IF; */

        -- Checking for ChargeBack Timeframe
        
       BEGIN
          SELECT CIP_PARAM_VALUE
            INTO v_chargeback_val
            FROM CMS_INST_PARAM
            WHERE CIP_PARAM_KEY = 'CHARGEBACK_TIMEFRAME'
            AND CIP_INST_CODE = 1;
          EXCEPTION
            WHEN OTHERS THEN
                v_chargeback_val := 0;   
       END;   
          --Sn check for ChargeBack value
       IF to_number(v_chargeback_val) > 0
         THEN
            IF (TRUNC(sysdate)-TRUNC(v_txn_date)) > to_number(v_chargeback_val)
            THEN
               v_resp_code := '21';
               v_resp_msg :='Invalid Dispute ';                       
            RAISE excp_rej_record;
            END IF;
       END IF;    
        
         

         --Sn check is it already reversed
         BEGIN
            IF v_reverse_flag = 'Y'
            THEN
               v_resp_code := '21';
               v_resp_msg := 'Transaction is already reversed';
               RAISE excp_rej_record;
            ELSIF v_fee_reversal_flag = 'Y'
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                  'Fee reversal transaction is already done for the transaction';
               RAISE excp_rej_record;
            END IF;
         END;
      EXCEPTION
         WHEN excp_rej_record
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
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
            RAISE excp_rej_record;
      END;

      --En check is it already reversed

      --Sn Get card details
      BEGIN
         SELECT cap_acct_no, cap_prod_code, cap_card_type, cap_card_stat,
                cap_expry_date, cap_proxy_number
           INTO v_cap_acct_no, v_prod_code, v_prod_cattype, v_card_stat,
                v_expry_date, v_proxynumber
           FROM cms_appl_pan
          WHERE cap_inst_code = prm_instcode
            AND cap_pan_code = v_hash_pan
            AND cap_mbr_numb = prm_mbrnumb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_code := '16';
            v_resp_msg := 'PAN not Found ';
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  ' Error while selecting data from card master  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      --En Get card details

      --Sn Check expiry
   /*   IF TO_DATE (prm_txn_date, 'yyyymmdd') > v_expry_date
      THEN
         v_resp_code := '13';
         v_resp_msg := 'Expired Card';
         RAISE excp_rej_record;
      END IF;
*/
      --En Check expiry

      --En Card Status check
      -- Commenting the below checks as part of VMS-932,VMS-935,VMS-936
/*      BEGIN
         SELECT ccs_card_status
           INTO v_ccs_appl_status
           FROM cms_cardissuance_status
          WHERE ccs_inst_code = prm_instcode AND ccs_pan_code = v_hash_pan;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_code := '16';
            v_resp_msg := 'PAN not found for application status';
            RAISE excp_rej_record;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'While fetching application status '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE excp_rej_record;
      END;

      IF v_ccs_appl_status <> '15'
      THEN
         v_resp_code := '49';
         v_resp_msg := 'Card Not In Shipped State';
         RAISE excp_rej_record;
      END IF; 
*/      
      
/*  Commented the card status check for not required
      BEGIN
         sp_status_check_gpr (prm_instcode,
                              prm_pancode,
                              prm_delv_chnl,
                              v_expry_date,
                              v_card_stat,
                              prm_txn_code,
                              prm_txn_mode,
                              v_prod_code,
                              v_prod_cattype,
                              prm_msg_type,
                              prm_txn_date,
                              prm_txn_time,
                              NULL,
                              NULL,  --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                              NULL,
                              v_resp_code,
                              v_resp_msg
                             );

         IF (   (v_resp_code <> '1' AND v_resp_msg <> 'OK')
             OR (v_resp_code <> '0' AND v_resp_msg <> 'OK')
            )
         THEN
            RAISE excp_rej_record;
         ELSE
            v_status_chk := v_resp_code;
            v_resp_code := '1';
         END IF;
      EXCEPTION
         WHEN excp_rej_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
               'Error from GPR Card Status Check '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_rej_record;
      END;

      IF v_status_chk = '1'
      THEN
         --Sn check card stat
         BEGIN
            SELECT COUNT (1)
              INTO v_check_statcnt
              FROM pcms_valid_cardstat
             WHERE pvc_inst_code = prm_instcode
               AND pvc_card_stat = v_card_stat
               AND pvc_tran_code = prm_txn_code
               AND pvc_delivery_channel = prm_delv_chnl;

            IF v_check_statcnt = 0
            THEN
               v_resp_code := '10'; -- response id changed from 49 to 10 on 09-Oct-2012
               v_resp_msg := 'Invalid Card Status';
               RAISE excp_rej_record;
            END IF;

         EXCEPTION when excp_rej_record
         then

             raise excp_rej_record;

         WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_resp_msg :=
                     'Problem while selecting card stat '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_rej_record;
         END;
      --En check card stat
      END IF;

      --En Card Status check
*/

      --Sn Update Dispute Staus
      BEGIN
      
      
v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_tran_date), 1, 8), 'yyyymmdd');

     IF (v_Retdate>v_Retperiod)
    THEN 
         UPDATE transactionlog
            SET dispute_flag = 'Y', reason_code=prm_reason_code
          WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date
            AND business_time = prm_orgnl_tran_time
            AND txn_code = prm_orgnl_txn_code
            AND customer_card_no = v_hash_pan
            AND delivery_channel = prm_orgnl_delivery_chnl
            AND instcode = prm_instcode;
       ELSE
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            SET dispute_flag = 'Y', reason_code=prm_reason_code
          WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date
            AND business_time = prm_orgnl_tran_time
            AND txn_code = prm_orgnl_txn_code
            AND customer_card_no = v_hash_pan
            AND delivery_channel = prm_orgnl_delivery_chnl
            AND instcode = prm_instcode;     
     END IF;
         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_code := '49';
            v_resp_msg :=
               'Problem in updation of Dispute status for pan '
               || prm_pancode;
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

      --En Update Dispute Staus

      --Sn Create dispute txn entry
      BEGIN
         INSERT INTO cms_dispute_txns
                     (cdt_inst_code, cdt_pan_code, cdt_pan_code_encr,
                      cdt_dispute_status, cdt_dispute_amount,
                      cdt_txn_date, cdt_txn_time,
                      cdt_delivery_channel, cdt_txn_code,
                      cdt_rrn, cdt_call_id, cdt_remark, cdt_final_remark,
                      cdt_ins_user, cdt_ins_date, cdt_lupd_user,
                      cdt_lupd_date, cdt_reason
                     )
              VALUES (prm_instcode, v_hash_pan, v_encr_pan,
                      prm_dispute_stat, prm_orgnl_txn_amt,
                      prm_orgnl_tran_date, prm_orgnl_tran_time,
                      prm_orgnl_delivery_chnl, prm_orgnl_txn_code,
                      prm_orgnl_rrn, prm_call_id, prm_remark, prm_remark,
                      prm_lupduser, SYSDATE, prm_lupduser,
                      SYSDATE,v_reason_desc-- prm_reasondesc
                     -- added by sagar on 15may2012 to insert reason for dispute
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_resp_msg :=
                  'Error while inserting records for dispute txn'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_rej_record;
      END;

      --En Create dispute txn entry
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_balance
           FROM cms_acct_mast
          WHERE cam_inst_code = prm_instcode AND cam_acct_no = v_cap_acct_no;
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
              VALUES (prm_delv_chnl, prm_txn_code, NULL,
                      prm_txn_mode, prm_txn_date, prm_txn_time,
                      v_hash_pan, prm_amount, prm_curr_code,
                      prm_amount, prm_amount, NULL,
                      NULL, NULL,
                      NULL, NULL, 'Y',
                      v_resp_msg, prm_rrn, prm_stan,
                      v_encr_pan, prm_msg_type,
                      v_cap_acct_no, prm_instcode
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_code := '89';
            prm_resp_msg :=
                  'Problem while inserting data into transaction log1  dtl'
               || SUBSTR (SQLERRM, 1, 100);
            RETURN;
      END;

      --Sn create a entry in txn log
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel,
                      date_time,
                      txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      total_amount,
                      currencycode, productid, categoryid, auth_id,
                      trans_desc,
                      amount,
                      system_trace_audit_no, instcode, cr_dr_flag,
                      customer_card_no_encr, proxy_number, reversal_code,
                      customer_acct_no, acct_balance, ledger_balance,
                      response_id, error_msg, orgnl_card_no,
                      orgnl_rrn, orgnl_business_date,
                      orgnl_business_time, orgnl_terminal_id, add_ins_date,
                      add_ins_user, remark, reason,
                      ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog
                      add_lupd_user,reason_code --added by amit on 06-Oct-2012 to log lupduser in transactionlog
                     )
              VALUES (prm_msg_type, prm_rrn, prm_delv_chnl,
                      TO_DATE (prm_txn_date || ' ' || prm_txn_time,
                               'yyyymmdd hh24:mi:ss'
                              ),
                      prm_txn_code, NULL, prm_txn_mode,
                      DECODE (prm_resp_code, '00', 'C', 'F'), prm_resp_code,
                      prm_txn_date, prm_txn_time, v_hash_pan,
                      TRIM (TO_CHAR (prm_amount, '99999999999999990.99')),
                      prm_curr_code, v_prod_code, v_prod_cattype, v_auth_id,
                      v_tran_desc,
                      TRIM (TO_CHAR (prm_amount, '999999999999999990.99')),
                      prm_stan, prm_instcode, 'NA',
                      v_encr_pan, v_proxynumber, prm_reversal_code,
                      v_cap_acct_no, v_acct_balance, v_ledger_balance,
                      v_resp_code, prm_resp_msg, fn_emaps_main(prm_orgnl_card_no), --Changes done by sagar on 24Jul2012 to store encrypted pan in Orgnl_card_no field
                      prm_orgnl_rrn, prm_orgnl_tran_date,
                      prm_orgnl_tran_time, NULL, SYSDATE,
                      prm_lupduser, prm_remark,v_reason_desc,-- prm_reasondesc,
                      prm_ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog
                      prm_lupduser,prm_reason_code  --added by amit on 06-Oct-2012 to log lupduser in transactionlog
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            prm_resp_code := '89';
            prm_resp_msg :=
                  'Problem while inserting data into transaction log3 '
               || SUBSTR (SQLERRM, 1, 100);
            RETURN;
      END;
   --En Create successful entry in Transactionlog and transaction_details
   EXCEPTION                                         --<<Begin I Exception>>--
      WHEN excp_rej_record
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_instcode
               AND cms_delivery_channel = prm_delv_chnl
               AND cms_response_id = v_resp_code;

            prm_resp_msg := v_resp_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_msg :=
                     'Problem while selecting data from response master1 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '21';
               RETURN;
         END;

         BEGIN
            SELECT cap_acct_no, cap_prod_code, cap_card_type,
                   cap_proxy_number
              INTO v_cap_acct_no, v_prod_code, v_prod_cattype,
                   v_proxynumber
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_cap_acct_no := NULL;
               v_prod_code := NULL;
               v_prod_cattype := NULL;
               v_proxynumber := NULL;
         END;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_balance
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_instcode
                   AND cam_acct_no = v_cap_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := NULL;
               v_ledger_balance := NULL;
         END;

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
                 VALUES (prm_delv_chnl, prm_txn_code, NULL,
                         prm_txn_mode, prm_txn_date, prm_txn_time,
                         v_hash_pan, prm_amount, prm_curr_code,
                         prm_amount, prm_amount,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_resp_msg, prm_rrn,
                         prm_stan,
                         v_encr_pan, prm_msg_type,
                         v_cap_acct_no, prm_instcode
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log1  dtl'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         auth_id, trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, orgnl_card_no,
                         orgnl_rrn, orgnl_business_date,
                         orgnl_business_time, orgnl_terminal_id,
                         add_ins_date, add_ins_user, remark, reason,
                         ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog
                         add_lupd_user,reason_code --added by amit on 06-Oct-2012 to log lupduser in transactionlog
                        )
                 VALUES (prm_msg_type, prm_rrn, prm_delv_chnl,
                         TO_DATE (prm_txn_date || ' ' || prm_txn_time,
                                  'yyyymmdd hh24:mi:ss'
                                  ),
                         prm_txn_code, NULL, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_txn_date, prm_txn_time,
                         v_hash_pan,
                         TRIM (TO_CHAR (prm_amount, '99999999999999990.99')),
                         prm_curr_code, v_prod_code, v_prod_cattype,
                         v_auth_id, v_tran_desc,
                         TRIM (TO_CHAR (prm_amount, '999999999999999990.99')),
                         prm_stan, prm_instcode, 'NA',
                         v_encr_pan, v_proxynumber, prm_reversal_code,
                         v_cap_acct_no, v_acct_balance, v_ledger_balance,
                         v_resp_code, prm_resp_msg, fn_emaps_main(prm_orgnl_card_no),--Changes done by sagar on 24Jul2012 to store encrypted pan in Orgnl_card_no field
                         prm_orgnl_rrn, prm_orgnl_tran_date,
                         prm_orgnl_tran_time, NULL,
                         SYSDATE, prm_lupduser, prm_remark,v_reason_desc,-- prm_reasondesc,
                         prm_ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog
                         prm_lupduser,prm_reason_code  --added by amit on 06-Oct-2012 to log lupduser in transactionlog
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log3 '
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
      WHEN OTHERS
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_instcode
               AND cms_delivery_channel = prm_delv_chnl
               AND cms_response_id = '21';

            prm_resp_msg :=
                    'Error from others exception ' || SUBSTR (SQLERRM, 1, 100);
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_msg :=
                     'Problem while selecting data from response master2 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '21';
               RETURN;
         END;

         BEGIN
            SELECT cap_acct_no, cap_prod_code, cap_card_type,
                   cap_proxy_number
              INTO v_cap_acct_no, v_prod_code, v_prod_cattype,
                   v_proxynumber
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_cap_acct_no := NULL;
               v_prod_code := NULL;
               v_prod_cattype := NULL;
               v_proxynumber := NULL;
         END;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_balance
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_instcode
                   AND cam_acct_no = v_cap_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := NULL;
               v_ledger_balance := NULL;
         END;

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
                 VALUES (prm_delv_chnl, prm_txn_code, NULL,
                         prm_txn_mode, prm_txn_date, prm_txn_time,
                         v_hash_pan, prm_amount, prm_curr_code,
                         prm_amount, prm_amount,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_resp_msg, prm_rrn,
                         prm_stan,
                         v_encr_pan, prm_msg_type,
                         v_cap_acct_no, prm_instcode
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log1  dtl'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         auth_id, trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, orgnl_card_no,
                         orgnl_rrn, orgnl_business_date,
                         orgnl_business_time, orgnl_terminal_id,
                         add_ins_date, add_ins_user, remark, reason,
                         ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog
                         add_lupd_user --added by amit on 06-Oct-2012 to log lupduser in transactionlog
                        )
                 VALUES (prm_msg_type, prm_rrn, prm_delv_chnl,
                         TO_DATE (prm_txn_date || ' ' || prm_txn_time,
                                  'yyyymmdd hh24:mi:ss'
                                 ),
                         prm_txn_code, NULL, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_txn_date, prm_txn_time,
                         v_hash_pan,
                         TRIM (TO_CHAR (prm_amount, '99999999999999990.99')),
                         prm_curr_code, v_prod_code, v_prod_cattype,
                         v_auth_id, v_tran_desc,
                         TRIM (TO_CHAR (prm_amount, '999999999999999990.99')),
                         prm_stan, prm_instcode, 'NA',
                         v_encr_pan, v_proxynumber, prm_reversal_code,
                         v_cap_acct_no, v_acct_balance, v_ledger_balance,
                         v_resp_code, prm_resp_msg, fn_emaps_main(prm_orgnl_card_no),--Changes done by sagar on 24Jul2012 to store encrypted pan in Orgnl_card_no field
                         prm_orgnl_rrn, prm_orgnl_tran_date,
                         prm_orgnl_tran_time, NULL,
                         SYSDATE, prm_lupduser, prm_remark,v_reason_desc,-- prm_reasondesc,
                         prm_ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog
                         prm_lupduser  --added by amit on 06-Oct-2012 to log lupduser in transactionlog
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               prm_resp_code := '89';
               prm_resp_msg :=
                     'Problem while inserting data into transaction log3 '
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
   END;                                                    --<<Begin I End>>--
EXCEPTION                                               --<<Main Exception>>--
   WHEN OTHERS
   THEN
      prm_resp_code := '21';
      prm_resp_msg := 'Main Exception -- ' || SUBSTR (SQLERRM, 1, 200);
END;                                                  --<<Main Begin Ends >>--
/
SHOW ERROR;