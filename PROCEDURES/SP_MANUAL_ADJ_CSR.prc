CREATE OR REPLACE PROCEDURE VMSCMS.SP_MANUAL_ADJ_CSR (
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
   prm_tran_amt        IN       VARCHAR2,
   prm_reason_code     IN       VARCHAR2,
   prm_remark          IN       VARCHAR2,
   prm_rvsl_code       IN       NUMBER,
   prm_txn_curr        IN       VARCHAR2,
   prm_ins_user        IN       NUMBER,
   prm_reason_desc     IN       VARCHAR2,
   prm_call_id         IN       NUMBER,
   prm_acct_no         IN       VARCHAR2,
   prm_acct_type       IN       NUMBER,
   prm_ipaddress       IN       VARCHAR2,
   PRM_ROLE_ID         in       number,
   PRM_Merchant_Name   in       VARCHAR2,
   prm_final_bal       OUT      VARCHAR2,
   prm_resp_code       OUT      VARCHAR2,
   prm_errmsg          OUT      VARCHAR2
)
IS
/**********************************************************************************************
  * VERSION              :  1.0
  * DATE OF CREATI       : 06/NOV/2011
  * PURPOSE              : Manual adj DR / CR
  * CREATED BY           : Sagar More
  * modified for         : New Requirement
  * modified Date        : 25-Jan-2013
  * modified reason      : 1) Position of query is change so that reason will be
                             logged in transactionlog for failure cases also
  * modified for         : Defect 0010016
  * Reviewer             : Dhiraj
  * Reviewed Date        : 25-Jan-2013
  * Build Number         : RI0023.1_B0009

  * Modified By          : Pankaj S.
  * Modified Date        : 21-Mar-2013
  * Modified Reason      : Logging of system initiated card status change(FSS-390) and
                           for max card balance check based on product category(Mantis ID-10643)
  * Reviewer             : Dhiraj
  * Reviewed Date        :
  * Build Number         : CSR3.5.1_RI0024_B0007

  * Modified By          : Pankaj S.
  * Modified Date        :  09-Apr-2013
  * Modified Reason      :  Max Card Balance Check (MVHOST-299)
  * Reviewer             : Dhiraj
  * Reviewed Date        :
  * Build Number         : CSR3.5.1_RI0024.1_B0004

  * Modified by          : Dnyaneshwar J ,Santosh K
  * Modified Date        : 16-APRIL-13
  * Modified for         : FSS-754 ,MVHOST-299
  * Modified reason      : 1) To log Merchant Name
                           2) To Remove max card balance check
  * Build Number         : CSR3.5.1_RI0024.1_B0008

  * Modified By          : Sagar M.
  * Modified Date        : 19-Apr-2013
  * Modified for         : Defect 10871
  * Modified Reason      : below details handled while insering into tranasctionlog and statementlog table
                           1) ledger balance in statementlog
                           2) Product code,Product category code,Card status,Acct Type,drcr flag
                           3) Timestamp and Amount values logging correction
  * Reviewer             : Dhiraj
  * Reviewed Date        : 19-Apr-2013
  * Build Number         : RI0024.1_B0013

  * Modified By          : Dnyaneshwar J on 09 May 2013.
  * Modified Date        : 09-May-2013
  * Modified for         : for FSS-754 : To log Merchant Name as 'System'
  * Build Number         : RI0024.1_B0018

  * Modified by          : Dnyaneshwar J
  * Modified Date        : 02-Jun-14
  * Modified For         : Mantis-14991

  * Modified by          : Narsing I
  * Modified Date        : 06-Jun-14
  * Modified For         : MVCSD-5336
  * Build Number         : RI0027.3_B0001

  * Modified by          : Sai Prasad
  * Modified Date        : 06-Jun-14
  * Modified For         : MVCSD-5336 - Mantis 15569
  * Build Number         : RI0027.3_B0005

  * Modified by          : MageshKumar S.
  * Modified Date        : 25-July-14
  * Modified For         : FWR-48
  * Modified reason      : GL Mapping removal changes
  * Reviewer             : Spankaj
  * Build Number         : RI0027.3.1_B0001

   * Modified by        : Abdul Hameed M.A
    * Modified Date     : 01-Oct-14
    * Modified For      : Mantis ID 15779
    * Reviewer          : Spankaj
    * Build Number      : RI0027.4_B0002

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
        
    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 07-MAR-2019.
    * Purpose          : VMS-609.
    * Reviewer         : Saravana Kumar A. 
    * Release Number   : VMSGPRHOST - R13.
	
	* Modified By      : BASKAR KRISHNAN
    * Modified Date    : 08-AUG-2019.
    * Purpose          : VMS-1022.
    * Reviewer         : Saravana Kumar A. 
    * Release Number   : VMSGPRHOST - R19.
    
    * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 06-May-2021
    * Modified For     : VMS-4223 - B2B Replace card for virtual product is not creating card in Active status 
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR46_B0002
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-4-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991

**************************************************************************************************/
   v_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   v_resp_cde           cms_response_mast.cms_response_id%type;                    
   v_err_msg            transactionlog.error_msg%type;
   v_auth_id            transactionlog.auth_id%type;
   v_func_code          cms_func_mast.cfm_func_code%TYPE;
   v_prod_code          cms_appl_pan.cap_prod_code%TYPE;
   v_card_type          cms_appl_pan.cap_card_type%TYPE;
   v_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_acct_balance       cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   v_check_statcnt      NUMBER (1);
   v_dr_cr_flag         cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
   v_cracct_no          cms_func_prod.cfp_cracct_no%TYPE;
   v_dracct_no          cms_func_prod.cfp_dracct_no%TYPE;
   v_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
   v_card_curr          cms_bin_param.cbp_param_value%TYPE;
   v_reasondesc         cms_spprt_reasons.csr_reasondesc%TYPE;
   v_rrn_count          NUMBER;
   v_cnt                NUMBER (2);
   v_call_seq           cms_calllog_details.ccd_call_seq%type;
   v_status_chk         NUMBER;
   v_expry_date         cms_appl_pan.cap_expry_date%TYPE;
   v_chk_acct_type      NUMBER (1);
   v_cam_type_code      cms_acct_mast.cam_type_code%TYPE;
   v_spnd_acctno        cms_appl_pan.cap_acct_no%TYPE;
   v_spending_limit     cms_role_mast.crm_spendingadj_limit%TYPE;
   v_saving_limit       cms_role_mast.crm_savingadj_limit%TYPE;
   v_total_limit        cms_role_mast.crm_savingadj_limit%TYPE;
   v_total_credit       cms_manual_adjustment.cma_credit_amount%TYPE;

   v_max_card_bal       cms_bin_param.cbp_param_value%TYPE;
   v_chnge_crdstat      VARCHAR2 (2)                                   := 'N';
   v_timestamp           transactionlog.time_stamp%TYPE;                         
   v_tran_amt            cms_acct_mast.cam_ledger_bal%TYPE;         
   exp_reject_record    EXCEPTION;
   v_Retperiod  date; --Added for VMS-5733/FSP-991
   v_Retdate  date; --Added for VMS-5733/FSP-991

BEGIN

   v_tran_amt := ROUND(prm_tran_amt,2);  

   -- Main begin starts here
   BEGIN
      -- Manual adj begin starts here
      v_err_msg := 'OK';

   

 
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
                  'reason desc not found in master for reason code '
               || prm_reason_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting reason desc '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;


      --Sn get the prod detail
      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_expry_date,cap_acct_no
           INTO v_prod_code, v_card_type, v_card_stat, v_expry_date,v_spnd_acctno
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
      
     /* BEGIN
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
      END;*/

  --- Modified for VMS-4223 - B2B Replace card for virtual product is not creating card in Active status 
  IF prm_call_id IS NOT NULL 
  THEN 
  
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
                      ccd_lupd_user, ccd_lupd_date, ccd_acct_no
                     )
              VALUES (prm_inst_code, prm_call_id, v_hash_pan, v_call_seq,
                      prm_rrn, prm_delivery_chnl, prm_txn_code,
                      prm_tran_date, prm_tran_time, NULL,
                      NULL, NULL, NULL,
                      prm_remark, prm_ins_user, SYSDATE,
                      prm_ins_user, SYSDATE, v_spnd_acctno
                     );
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  ' Error while inserting into cms_calllog_details '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
    END IF;
    

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
            v_resp_cde := '21';
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
            SELECT cam_type_code, cam_acct_bal, cam_ledger_bal,
                   cam_type_code                                    
              INTO v_cam_type_code, v_acct_balance, v_ledger_bal,
                   v_cam_type_code                                  
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code AND cam_acct_no = prm_acct_no FOR UPDATE;

            prm_final_bal := TO_CHAR (v_acct_balance);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';
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
            v_resp_cde := '21';
            v_err_msg :=
               'account type not matching with input accout type for spending';
            RAISE exp_reject_record;
         END IF;
      ELSIF prm_acct_type = '2'                    -- check for saving account
      THEN
         BEGIN
            SELECT cam_type_code, cam_acct_bal, cam_ledger_bal,
                   cam_type_code                                    
              INTO v_cam_type_code, v_acct_balance, v_ledger_bal,
                   v_cam_type_code                                 
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code AND cam_acct_no = prm_acct_no FOR UPDATE;

            prm_final_bal := TO_CHAR (v_acct_balance);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';
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
            v_resp_cde := '21';
            v_err_msg :=
               'account type not matching with input accout type for saving ';
            RAISE exp_reject_record;
         END IF;
      END IF;

      IF prm_txn_code = '14' and prm_reason_code not in ('260','262') AND (prm_acct_type = '1' OR prm_acct_type = '2')
      THEN
         BEGIN
            SELECT NVL (crm_spendingadj_limit, 0),
                   NVL (crm_savingadj_limit, 0)
              INTO v_spending_limit,
                   v_saving_limit
              FROM cms_role_mast
             WHERE crm_inst_code = prm_inst_code
               AND crm_role_code = prm_role_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               prm_resp_code := '49';
               prm_errmsg :=
                           'Manual adjustment limit is not defined in master';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               prm_resp_code := '21';
               prm_errmsg :=
                     'Error while selecting master data for manual adj '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT NVL (SUM (cma_credit_amount), 0)
              INTO v_total_credit
              FROM cms_manual_adjustment
             WHERE cma_inst_code = prm_inst_code
               AND cma_pan_code = gethash (prm_card_no)
               AND cma_acct_no = prm_acct_no
               AND cma_acct_type = prm_acct_type
               AND cma_ins_user = prm_ins_user
               AND cma_delivery_channel = prm_delivery_chnl
               AND cma_tran_code = prm_txn_code
               AND TRUNC (cma_adjustment_date) = TRUNC (SYSDATE);
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '21';
               prm_errmsg :=
                     'Error while selecting daily total credit amount '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;

         IF prm_acct_type = '1'
         THEN
            v_total_limit := v_spending_limit;
         ELSIF prm_acct_type = '2'
         THEN
            v_total_limit := v_saving_limit;
         END IF;

         IF v_total_credit >= v_total_limit
         THEN
            v_resp_cde := '147';
            v_err_msg :=
                     'USER DAILY CREDIT LIMIT EXCEEDED FOR SELECTED ACCOUNT.';
            RAISE EXP_REJECT_RECORD;
         ELSIF     ROUND(V_TOTAL_CREDIT,2) < V_TOTAL_LIMIT
               AND ROUND(V_TOTAL_CREDIT + V_TRAN_AMT
               ,2) > v_total_limit
         THEN
            v_resp_cde := '147';
            v_err_msg :=
                     'USER DAILY CREDIT LIMIT EXCEEDED FOR SELECTED ACCOUNT.';
            RAISE exp_reject_record;
         END IF;
      END IF;



if prm_reason_code not in ('260','262') then
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
                              NULL,
                              NULL,
                              NULL,
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
      THEN              
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
               v_resp_cde := '10';
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
      END IF;
END IF;
       BEGIN

vmsfunutilities.get_currency_code(v_prod_code,v_card_type,prm_inst_code,V_CARD_CURR,v_err_msg);
      
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


      IF v_card_curr <> prm_txn_curr
      THEN
         v_err_msg :=
               'Both from card currency and txn currency are not same  '
            || SUBSTR (SQLERRM, 1, 200);
         v_resp_cde := '21';
         RAISE exp_reject_record;
      END IF;

 
if prm_reason_code not in ('260','262') then
      BEGIN
         SELECT TO_NUMBER (cbp_param_value)
           INTO v_max_card_bal
           FROM cms_bin_param
          WHERE cbp_inst_code = prm_inst_code
            AND cbp_param_name = 'Max Card Balance'
            AND cbp_profile_code IN (
                   SELECT cpc_profile_code
                     FROM cms_prod_cattype
                    WHERE cpc_inst_code = prm_inst_code
                      AND cpc_prod_code = v_prod_code
                      AND cpc_card_type = v_card_type);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Max card balance not configured to product profile';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
END IF;
 
      BEGIN
         SELECT ctm_credit_debit_flag, ctm_tran_desc
           INTO v_dr_cr_flag, v_tran_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_txn_code
            AND ctm_delivery_channel = prm_delivery_chnl
            AND ctm_inst_code = prm_inst_code
            AND ctm_support_type = 'M';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=
                  'Transaction detail is not found in master for manual adj txn '
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

      IF v_dr_cr_flag = 'CR' and prm_reason_code not in ('260','262')
      THEN
         IF    (ROUND(V_ACCT_BALANCE + V_TRAN_AMT
               ,2) > V_MAX_CARD_BAL)
            OR (ROUND(V_LEDGER_BAL + V_TRAN_AMT
              ,2) > v_max_card_bal)
         THEN
            IF v_card_stat <> '12'
            THEN
               UPDATE cms_appl_pan
                  SET cap_card_stat = '12'
                WHERE cap_inst_code = prm_inst_code
                  AND cap_pan_code = v_hash_pan;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_err_msg := 'Error while updating the card status';
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
               END IF;

               v_chnge_crdstat := 'Y';                    
            END IF;
         END IF;
      END IF;


      BEGIN
         IF v_dr_cr_flag = 'CR'
         THEN
            UPDATE CMS_ACCT_MAST
               SET CAM_ACCT_BAL = ROUND(CAM_ACCT_BAL + V_TRAN_AMT,2),
                   cam_ledger_bal = ROUND(cam_ledger_bal + v_tran_amt,2) 
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


            v_timestamp := systimestamp;  

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
                            csl_ins_user, 
                                         csl_acct_no,
                             csl_panno_last4digit,
                           csl_merchant_name, 
                           csl_acct_type, 
                           csl_time_stamp,
                           csl_prod_code,csl_card_type   
                           )
                    VALUES (V_HASH_PAN, V_LEDGER_BAL, 
                            v_tran_amt, 
                            v_dr_cr_flag,
                            TO_DATE (PRM_TRAN_DATE, 'yyyymmdd'),
                            ROUND(v_ledger_bal + v_tran_amt,2),
                            'Manual adj - ' || v_reasondesc, prm_inst_code,
                            v_encr_pan, prm_rrn, prm_tran_date,
                            prm_tran_time, prm_delivery_chnl,
                            prm_txn_code, v_auth_id, SYSDATE,
                            1,             
                              prm_acct_no,
                            SUBSTR (prm_card_no,
                                    LENGTH (prm_card_no) - 3,
                                    LENGTH (prm_card_no)
                                   ),
                           PRM_Merchant_Name,
                           v_cam_type_code,  
                           v_timestamp,       
                           v_prod_code,v_card_type     

                           );

               v_cnt := SQL%ROWCOUNT;

               IF v_cnt = 0
               THEN
                  v_resp_cde := '21';
                  v_err_msg := 'No records inserted in statements log for CR';
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
                        'Problem while inserting into statement log for tran amt '
                     || v_tran_amt
                     || ' and db/cr flag '
                     || v_dr_cr_flag
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSIF v_dr_cr_flag = 'DR'
         THEN
            UPDATE CMS_ACCT_MAST
               SET CAM_ACCT_BAL = ROUND(CAM_ACCT_BAL - V_TRAN_AMT,2) , 
                   cam_ledger_bal = ROUND(cam_ledger_bal - v_tran_amt,2) 
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

            v_timestamp := systimestamp;   

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
                            csl_ins_user, 
                                         csl_acct_no,
                             csl_panno_last4digit,
                           csl_acct_type, 
                           csl_time_stamp,
                           CSL_PROD_CODE   
                           ,csl_merchant_name,csl_card_type  
                           )
                    VALUES (v_hash_pan, ROUND(v_ledger_bal,2), v_tran_amt,
                                         
                            v_dr_cr_flag,
                            TO_DATE (PRM_TRAN_DATE, 'yyyymmdd'),
                            ROUND(v_ledger_bal - v_tran_amt,2), 
                            'Manual Adj - ' || v_reasondesc, prm_inst_code,
                            v_encr_pan, prm_rrn, prm_tran_date,
                            prm_tran_time, prm_delivery_chnl,
                            prm_txn_code, v_auth_id, SYSDATE,
                            1,            
                              prm_acct_no,
                            SUBSTR (prm_card_no,
                                    LENGTH (prm_card_no) - 3,
                                    LENGTH (prm_card_no)
                                   ),
                           v_cam_type_code,  
                           v_timestamp,       
                           V_PROD_CODE,        
                           PRM_Merchant_Name,v_card_type  
                           );

               v_cnt := SQL%ROWCOUNT;

               IF v_cnt = 0
               THEN
                  v_resp_cde := '21';
                  v_err_msg := 'No records inserted in statements log for DR';
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
                        'Problem while inserting into statement log for tran amt '
                     || v_tran_amt
                     || ' and db/cr flag '
                     || v_dr_cr_flag
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSIF NVL (v_dr_cr_flag, '0') NOT IN ('DR', 'CR')
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


      IF v_chnge_crdstat = 'Y'
      THEN
         BEGIN
            sp_log_cardstat_chnge (prm_inst_code,
                                   v_hash_pan,
                                   v_encr_pan,
                                   v_auth_id,
                                   '03',
                                   prm_rrn,
                                   prm_tran_date,
                                   prm_tran_time,
                                   v_resp_cde,
                                   v_err_msg
                                  );

            IF v_resp_cde <> '00' AND v_err_msg <> 'OK'
            THEN
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
                     'Error while logging system initiated card status change '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;


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


 if prm_reason_code not in ('260','262') then

      BEGIN
         INSERT INTO cms_manual_adjustment
                     (cma_inst_code, cma_adjustment_date,
                      cma_pan_code, cma_pan_code_encr, cma_adjustment_type,
                      cma_debit_amount,
                      cma_credit_amount,
                      cma_tran_code, cma_tran_mode, cma_delivery_channel,
                      cma_ins_user, cma_ins_date, cma_lupd_user,
                      cma_lupd_date, cma_acct_no,
                                                 cma_acct_type
                     )
              VALUES (prm_inst_code, TO_DATE (prm_tran_date, 'yyyymmdd'),
                      v_hash_pan, v_encr_pan, prm_reason_code,
                      DECODE (v_dr_cr_flag, 'DR', v_tran_amt, '0.00'),
                      DECODE (v_dr_cr_flag, 'CR', v_tran_amt, '0.00'),
                      prm_txn_code, prm_txn_mode, prm_delivery_chnl,
                      prm_ins_user, SYSDATE, prm_ins_user,
                      SYSDATE, prm_acct_no,
                                           prm_acct_type
                     );

         v_cnt := SQL%ROWCOUNT;

         IF v_cnt = 0
         THEN
            v_resp_cde := '21';
            v_err_msg := 'No records inserted in manual adjustment';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := 21;
            v_err_msg :=
                'error while inserting into adj ' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
END IF;
      --EN insert in manual adj table
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_system_trace_audit_no,
                      ctd_inst_code, ctd_customer_card_no_encr,
                      ctd_cust_acct_number, ctd_ins_date, ctd_ins_user
                     )
              VALUES (prm_delivery_chnl, prm_txn_code, v_dr_cr_flag,
                      prm_msg_type, prm_txn_mode, prm_tran_date,
                      PRM_TRAN_TIME, V_HASH_PAN,
                      v_tran_amt,
                      PRM_TXN_CURR, 
                      v_tran_amt,
                      v_tran_amt,
                      v_card_curr, 'Y',
                      prm_errmsg, prm_rrn, prm_stan,
                      prm_inst_code, v_encr_pan,
                      prm_acct_no, SYSDATE, prm_ins_user
                     );

         v_cnt := SQL%ROWCOUNT;

         IF v_cnt = 0
         THEN
            v_resp_cde := '21';
            v_err_msg := 'No records inserted in manual adjustment';
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
                  'Error while inserting in transactionlog detail '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      -- Sn create a entry in txnlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time,
                      txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type,
                      bank_code, total_amount, rule_indicator, rulegroupid,
                      mccode, currencycode, productid, categoryid, tips,
                      decline_ruleid, atm_name_location, auth_id,
                      trans_desc, amount, preauthamount,
                      partialamount, mccodegroupid, currencycodegroupid,
                      transcodegroupid, rules, preauth_date, gl_upd_flag,
                      system_trace_audit_no, instcode, feecode,
                      feeattachtype, tran_reverse_flag,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance,
                      ledger_balance,
                      error_msg, add_ins_date, add_ins_user, response_id,
                      remark, reason, ipaddress,
                                                cr_dr_flag,
                      add_lupd_user,         
                      
                     merchant_name, 
                     acct_type,    
                     time_stamp,    
                     cardstatus,  
                     reason_code
                     )
              VALUES (prm_msg_type, prm_rrn, prm_delivery_chnl, NULL,
                      TO_DATE (prm_tran_date || ' ' || prm_tran_time,
                               'yyyymmdd hh24miss'
                              ),
                      prm_txn_code, 1, prm_txn_mode,
                      DECODE (prm_resp_code, '00', 'C', 'F'), prm_resp_code,
                      prm_tran_date, prm_tran_time, v_hash_pan,
                      NULL, NULL, NULL,
                      prm_inst_code, 
                      TRIM(TO_CHAR(nvl(v_tran_amt,0), '99999999999999990.99')), 
                      NULL, NULL,
                      NULL, prm_txn_curr, v_prod_code, v_card_type, 0,
                      NULL, NULL, v_auth_id,
                      'Manual Adj - ' || v_reasondesc,
                      TRIM(TO_CHAR(nvl(v_tran_amt,0), '99999999999999990.99')),
                      '0.00', 
                      '0.00', NULL, NULL,             
                      NULL, NULL, NULL, 'Y',
                      prm_stan, prm_inst_code, NULL,
                      NULL, 'N',
                      v_encr_pan, NULL,
                      NULL,                          
                           prm_rvsl_code, prm_acct_no,
                      DECODE (V_DR_CR_FLAG,
                              'CR', ROUND(V_ACCT_BALANCE + V_TRAN_AMT,2),
                              'DR', round(v_acct_balance - v_tran_amt,2),
                              v_acct_balance
                             ),
                      DECODE (V_DR_CR_FLAG,
                              'CR', ROUND(V_LEDGER_BAL + V_TRAN_AMT,2) ,
                              'DR', ROUND(V_LEDGER_BAL - V_TRAN_AMT,2),
                              round(v_ledger_bal,2)
                             ),
                      prm_errmsg, SYSDATE, prm_ins_user, v_resp_cde,
                      prm_remark, v_reasondesc, prm_ipaddress,
                                                             
                                                              v_dr_cr_flag,
                      prm_ins_user,           
                                
                      PRM_Merchant_Name, 
                     v_cam_type_code,   
                     v_timestamp,       
                     v_card_stat,        
                     prm_reason_code 
                     );

         v_cnt := SQL%ROWCOUNT;

         IF v_cnt = 0
         THEN
            v_resp_cde := '21';
            v_err_msg := 'sucessful record not inserted in transactionlog';
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
                  'Error while inserting in transactionlog '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      -- Sn create a entry in txnlog
      prm_errmsg := v_err_msg;

      SELECT DECODE (V_DR_CR_FLAG,
                     'CR',  ROUND(V_ACCT_BALANCE + V_TRAN_AMT,2),
                     'DR',  ROUND(V_ACCT_BALANCE - V_TRAN_AMT,2)
                    )
        INTO prm_final_bal
        FROM DUAL;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK;-- TO SAVEPOINT p1;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal,
                   cam_type_code                    
              INTO v_acct_balance, v_ledger_bal,
                   v_cam_type_code                  
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
                         ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                         ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                         ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no, ctd_inst_code,
                         ctd_customer_card_no_encr, ctd_cust_acct_number,
                         ctd_ins_date, ctd_ins_user
                        )
                 VALUES (prm_delivery_chnl, prm_txn_code, v_dr_cr_flag,
                         prm_msg_type, prm_txn_mode, prm_tran_date,
                         PRM_TRAN_TIME, V_HASH_PAN,
                         v_tran_amt, 
                         PRM_TXN_CURR, v_tran_amt,
                         v_tran_amt,
                         v_card_curr, 'E',
                         prm_errmsg, prm_rrn,
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


     if V_PROD_CODE is null
     then

         BEGIN

             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT
               INTO V_PROD_CODE,
                    v_card_type,
                    V_CARD_STAT
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = prm_inst_code AND CAP_PAN_CODE = V_HASH_PAN; 
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
              WHERE CTM_TRAN_CODE = prm_txn_code
              AND   CTM_DELIVERY_CHANNEL = prm_delivery_chnl
              AND   CTM_INST_CODE = prm_inst_code;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;

     if v_timestamp is null
     then
         v_timestamp := systimestamp;              

     end if;

         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, terminal_id,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no, topup_card_no, topup_acct_no,
                         topup_acct_type, bank_code, total_amount,
                         rule_indicator, rulegroupid, mccode, currencycode,
                         productid, categoryid, tips, decline_ruleid,
                         atm_name_location, auth_id, trans_desc,
                         amount, preauthamount, partialamount,
                         mccodegroupid, currencycodegroupid,
                         transcodegroupid, rules, preauth_date, gl_upd_flag,
                         system_trace_audit_no, instcode, feecode,
                         feeattachtype, tran_reverse_flag,
                         customer_card_no_encr, topup_card_no_encr,
                         proxy_number, reversal_code, customer_acct_no,
                         acct_balance, ledger_balance, error_msg,
                         add_ins_date, add_ins_user, response_id, remark,
                         reason, ipaddress,   
                                           cr_dr_flag,
                         add_lupd_user,       
                                     
                       MERCHANT_NAME, 
                        acct_type,     
                        time_stamp,   
                        cardstatus ,   
                        reason_code  
                        )
                 VALUES (prm_msg_type, prm_rrn, prm_delivery_chnl, NULL,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         prm_txn_code, 1, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_tran_date, prm_tran_time,
                         v_hash_pan, NULL, NULL,
                         NULL, prm_inst_code, 
                         TRIM(TO_CHAR(nvl(v_tran_amt,0), '99999999999999990.99')),
                         NULL, NULL, NULL, prm_txn_curr,
                         v_prod_code, v_card_type, 0, NULL,
                         NULL, v_auth_id, 'Manual Adj - ' || v_reasondesc,
                         TRIM(TO_CHAR(nvl(v_tran_amt,0), '99999999999999990.99')),
                        '0.00', '0.00', 
                         NULL, NULL,
                         NULL, NULL, NULL, 'N',
                         prm_stan, prm_inst_code, NULL,
                         NULL, 'N',
                         v_encr_pan, NULL,
                         NULL,                      
                              prm_rvsl_code, prm_acct_no,
                         v_acct_balance, v_ledger_bal, prm_errmsg,
                         SYSDATE, prm_ins_user, v_resp_cde, prm_remark,
                         v_reasondesc, prm_ipaddress,
                                                     v_dr_cr_flag,
                          prm_ins_user,        
                                  
                        PRM_Merchant_Name, 
                        v_cam_type_code,   
                        v_timestamp,      
                        v_card_stat  ,      
                        prm_reason_code 
                        );

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                        'unsuccessful record  not inserted in transactionlog';
               RAISE exp_reject_record;
            END IF;
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

      WHEN OTHERS
      THEN
         ROLLBACK;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal,
                   cam_type_code               
              INTO v_acct_balance, v_ledger_bal,
                   v_cam_type_code             
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
                         ctd_txn_amount, ctd_txn_curr, ctd_actual_amount,
                         ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                         ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no, ctd_inst_code,
                         ctd_customer_card_no_encr, ctd_cust_acct_number,
                         ctd_ins_date, ctd_ins_user
                        )
                 VALUES (prm_delivery_chnl, prm_txn_code, v_dr_cr_flag,
                         prm_msg_type, prm_txn_mode, prm_tran_date,
                         PRM_TRAN_TIME, V_HASH_PAN,
                         v_tran_amt,
                         PRM_TXN_CURR, v_tran_amt,
                         v_tran_amt,
                         v_card_curr, 'E',
                         prm_errmsg, prm_rrn,
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

     if V_PROD_CODE is null
     then

         BEGIN

             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT
               INTO V_PROD_CODE,
                    v_card_type,
                    V_CARD_STAT
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = prm_inst_code AND CAP_PAN_CODE = V_HASH_PAN; 
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
              WHERE CTM_TRAN_CODE = prm_txn_code
              AND   CTM_DELIVERY_CHANNEL = prm_delivery_chnl
              AND   CTM_INST_CODE = prm_inst_code;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;

     if v_timestamp is null
     then
         v_timestamp := systimestamp;             

     end if;

        BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, terminal_id,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no, topup_card_no, topup_acct_no,
                         topup_acct_type, bank_code, total_amount,
                         rule_indicator, rulegroupid, mccode, currencycode,
                         productid, categoryid, tips, decline_ruleid,
                         atm_name_location, auth_id, trans_desc,
                         amount, preauthamount, partialamount,
                         mccodegroupid, currencycodegroupid,
                         transcodegroupid, rules, preauth_date, gl_upd_flag,
                         system_trace_audit_no, instcode, feecode,
                         feeattachtype, tran_reverse_flag,
                         customer_card_no_encr, topup_card_no_encr,
                         proxy_number, reversal_code, customer_acct_no,
                         acct_balance, ledger_balance, error_msg,
                         add_ins_date, add_ins_user, response_id, remark,
                         reason, ipaddress,    
                                           cr_dr_flag,
                         add_lupd_user,        
                                   
                        MERCHANT_NAME, 
                        acct_type,     
                        time_stamp,   
                        cardstatus ,   
                        reason_code  
                        )
                 VALUES (prm_msg_type, prm_rrn, prm_delivery_chnl, NULL,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         prm_txn_code, 1, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_tran_date, prm_tran_time,
                         v_hash_pan, NULL, NULL,
                         NULL, prm_inst_code, 
                         TRIM(TO_CHAR(nvl(v_tran_amt,0), '99999999999999990.99')),
                         NULL, NULL, NULL, prm_txn_curr,
                         v_prod_code, v_card_type, 0, NULL,
                         NULL, v_auth_id, 'Manual Adj - ' || v_reasondesc,
                         TRIM(TO_CHAR(nvl(v_tran_amt,0), '99999999999999990.99')),
                         '0.00', '0.00',  
                         NULL, NULL,
                         NULL, NULL, NULL, 'N',
                         prm_stan, prm_inst_code, NULL,
                         NULL, 'N',
                         v_encr_pan, NULL,
                         NULL,                      
                              prm_rvsl_code, prm_acct_no,
                         v_acct_balance, v_ledger_bal, prm_errmsg,
                         SYSDATE, prm_ins_user, v_resp_cde, prm_remark,
                         v_reasondesc, prm_ipaddress,
                                                     v_dr_cr_flag,
                          prm_ins_user,        
                                   
                        PRM_Merchant_Name, 
                         v_cam_type_code,  
                         v_timestamp,       
                         v_card_stat  ,     
                         prm_reason_code 
                        );

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                      'unsuccessful record  not inserted in transactionlog 2';
               RAISE exp_reject_record;
            END IF;
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

   END;                                         
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'ERROR FROM MAIN ' || SUBSTR (SQLERRM, 1, 100);
      prm_resp_code := '89';
END;                                                   
/

show error