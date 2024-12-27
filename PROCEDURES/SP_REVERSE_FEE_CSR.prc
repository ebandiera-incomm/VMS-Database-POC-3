CREATE OR REPLACE PROCEDURE VMSCMS.SP_REVERSE_FEE_CSR (
   prm_inst_code             IN       NUMBER,
   prm_msg_type              IN       VARCHAR2,
   prm_rrn                   IN       VARCHAR2,
   prm_stan                  IN       VARCHAR2,
   prm_tran_date             IN       VARCHAR2,
   prm_tran_time             IN       VARCHAR2,
   prm_txn_amt               IN       NUMBER,                   -- Tran amount
   prm_fee_amt               IN       NUMBER,
   prm_txn_curr              IN       VARCHAR2,
   prm_txn_code              IN       VARCHAR2,
   prm_txn_mode              IN       VARCHAR2,
   prm_delivery_chnl         IN       VARCHAR2,
   prm_mbr_numb              IN       VARCHAR2,
   prm_rvsl_code             IN       VARCHAR2,
   prm_master_card_no        IN       VARCHAR2,--Added by Dnyaneshwar J on 22 July 2013 for Mantis-0011645
   prm_orgnl_rrn             IN       VARCHAR2,
   prm_orgnl_card_no         IN       VARCHAR2,
   prm_orgnl_stan            IN       VARCHAR2,
   prm_orgnl_tran_date       IN       VARCHAR2,
   prm_orgnl_tran_time       IN       VARCHAR2,
   prm_orgnl_txn_amt         IN       NUMBER,
   prm_orgnl_txn_code        IN       VARCHAR2,
   prm_orgnl_delivery_chnl   IN       VARCHAR2,
   prm_ins_user              IN       NUMBER,
   prm_remark                IN       VARCHAR2,
   prm_reason_code           IN       VARCHAR2,
   prm_reason_desc           IN       VARCHAR2,
   prm_call_id               IN       NUMBER,
   prm_merc_name             IN       VARCHAR2,
   prm_merc_city             IN       VARCHAR2,
   prm_merc_state            IN       VARCHAR2,
   prm_ipaddress             IN       VARCHAR2, --added by amit on 07-Oct-2012
   prm_acct_bal              OUT      VARCHAR2,
   prm_resp_code             OUT      VARCHAR2,
   prm_errmsg                OUT      VARCHAR2
)
IS
/***********************************************************************************************************************
  * Created Date         : 13/Jan/2012.
  * Created By           : Sagar More.
  * Purpose              : to reverse fee amount in customers account
  * Modified by          : Sagar M.
  * Modified for         : Internal Enhancement
  * Modified Date        : 09-Oct-2012
  * Modified reason      : Response id changed from 49 to 10
                           To show invalid card status msg in popup query
  * Build Number         : CMS3.5.1_RI0022
  * Modified by          : Sagar M.
  * Modified Date        : 09-Feb-13
  * Modified reason      : Product Category spend limit not being adhered to by VMS
  * Modified for         : NA
  * Reviewer             : Dhiraj
  * Reviewed Date        : 10-Feb-13
  * Build Number         : CMS3.5.1_RI0023.1

  * Modified by          : Sagar M.
  * Modified Date        : 03-Apr-13
  * Modified reason      : To ignore successful original transactions for reversal
  * Modified for         : MVCSD-4071
  * Reviewer             : Dhiraj
  * Reviewed Date        : 03-Apr-13
  * Build Number         : RI0024.1_B0004

  * Modified by          : Dnyaneshwar J
  * Modified Date        : 16-APRIL-13
  * Modified reason      : for FSS-754 : To log Merchant Name

  * Modified by          :  Pankaj S.
  * Modified Reason      :  10871
  * Modified Date        :  19-Apr-2013
  * Reviewer             :  Dhiraj
  * Reviewed Date        :
  * Build Number         : RI0024.1_B0013

  * Modified by          :  Dnyaneshwar J
  * Modified Reason      :  Mantis-0011645
  * Modified Date        :  22-July-2013
  * Reviewer             :
  * Reviewed Date        :
  * Build Number         :

  * Modified by          :  Dnyaneshwar J
  * Modified Reason      :  Mantis-13847
  * Modified Date        :  07-Mar-2014
  * Reviewer             :  Dhiraj
  * Reviewed Date        :  07-Mar-2014
  * Build Number         :  RI0027.2_B0002

  * Modified by          : MageshKumar S.
  * Modified Date        : 25-July-14
  * Modified For         : FWR-48
  * Modified reason      : GL Mapping removal changes
  * Reviewer             : Spankaj
  * Build Number         : RI0027.3.1_B0001

    * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
	
    * Modified By      : Baskar Krishnan
    * Modified Date    : 16-Aug-2019.
    * Purpose          : VMS-1038-VMS Fee Descriptions for statements/transaction history.
    * Reviewer         : Saravana Kumar A 
    * Release Number   : VMSGPRHOSTR19
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-4-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
 ************************************************************************************************************************/

   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_card_acct_no           cms_appl_pan.cap_acct_no%TYPE;
   v_fee_amt                transactionlog.tranfee_amt%TYPE;
   v_reverse_flag           transactionlog.tran_reverse_flag%TYPE;
   v_fee_reversal_flag      transactionlog.fee_reversal_flag%TYPE;
   v_cr_acctno              transactionlog.tranfee_cr_acctno%TYPE;
   v_dr_acctno              transactionlog.tranfee_dr_acctno%TYPE;
   v_responsecode           transactionlog.response_code%TYPE;
   v_acct_balance           cms_acct_mast.cam_acct_bal%TYPE;
   v_resp_cde               transactionlog.response_code%TYPE;
   v_err_msg                transactionlog.error_msg%TYPE;
   v_gl_upd_flag            transactionlog.gl_upd_flag%TYPE;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_master_hash_pan        cms_appl_pan.cap_pan_code%TYPE;--Added by Dnyaneshwar J on 22 July 2013 for Mantis-0011645
   v_auth_id                VARCHAR2 (6);
   v_fee_code               transactionlog.feecode%TYPE;
   v_proxy_number           transactionlog.proxy_number%TYPE;
   v_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
   v_orgnl_tranfee_amt      transactionlog.tranfee_amt%TYPE;
   v_orgnl_servicetax_amt   transactionlog.servicetax_amt%TYPE;
   v_orgnl_cess_amt         transactionlog.cess_amt%TYPE;
   v_orgnl_st_calc_flag     transactionlog.tran_st_calc_flag%TYPE;
   v_orgnl_cess_calc_flag   transactionlog.tran_cess_calc_flag%TYPE;
   v_orgnl_st_cr_acctno     transactionlog.tran_st_cr_acctno%TYPE;
   v_orgnl_st_dr_acctno     transactionlog.tran_st_dr_acctno%TYPE;
   v_orgnl_cess_cr_acctno   transactionlog.tran_cess_cr_acctno%TYPE;
   v_orgnl_cess_dr_acctno   transactionlog.tran_cess_dr_acctno%TYPE;
   v_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_tran_desc              cms_transaction_mast.ctm_tran_desc%TYPE;
   v_card_curr              cms_bin_param.cbp_param_value%TYPE;
   v_check_statcnt          PLS_INTEGER;
   v_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   v_profile_code           cms_prod_mast.cpm_profile_code%TYPE;
   v_max_limit              cms_bin_param.cbp_param_value%TYPE;
   v_expry_date             cms_appl_pan.cap_expry_date%TYPE;
   v_rrn_count              PLS_INTEGER;
   v_check_max_bal          NUMBER (20, 3);
   dum                      PLS_INTEGER;
   v_reason                 transactionlog.reason%TYPE;
   v_csr_reason_desc        cms_csrreason_mast.ccm_reason_desc%TYPE;         -- added on 08022012 by sagar to store reason
   v_call_seq               cms_calllog_details.ccd_call_seq%TYPE;                                      -- variables added for call log info  
   v_status_chk             PLS_INTEGER;                                     -- variables added for GPR 
   v_narration              cms_statements_log.csl_trans_narrration%TYPE;    -- added by sagar on 17-May-2012
   v_spnd_acctno            cms_appl_pan.cap_acct_no%TYPE;                   -- ADDED BY GANESH ON 19-JUL-12
   v_txn_mode               cms_func_mast.cfm_txn_mode%type;                 -- added by sagar on 06Sep2012
   V_ORGNL_DRCR_FLAG        CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%type; -- added by sagar on 06Sep2012
   v_orgnl_merchant         transactionlog.merchant_name%TYPE;               -- added by dnyaneshwar on 16Apr2013
   --Sn Added by Pankaj S. for 10871
   v_acct_type              cms_acct_mast.cam_type_code%TYPE;
   v_timestamp              timestamp(3);
   --En Added by Pankaj S. for 10871
   exp_reject_record        EXCEPTION;
   
   v_Retperiod  date; --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991
   
BEGIN
   --<< MAIN BEGIN >>
   BEGIN
      --SN CREATE HASH PAN
      v_err_msg := 'OK';
      SAVEPOINT p1;

   --SN CREATE HASH PAN  added by Dnyaneshwar J on 22 July 2013 for Mantis-0011645
       BEGIN
          v_master_hash_pan := gethash (prm_master_card_no);
       EXCEPTION
          WHEN OTHERS
          THEN
             v_resp_cde := '21';
             v_err_msg :='Error while converting pan '|| prm_master_card_no|| ' '|| SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
       END;
     --EN CREATE HASH PAN  added by Dnyaneshwar J on 22 July 2013 for Mantis-0011645

      BEGIN
         v_hash_pan := gethash (prm_orgnl_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 100);
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
               AND ccd_pan_code = v_master_hash_pan;--replace v_hash_pan by Dnyaneshwar J on 22 July 2013 for Mantis-0011645
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
              VALUES (prm_inst_code, prm_call_id, v_master_hash_pan, v_call_seq,--replace v_hash_pan by Dnyaneshwar J on 22 July 2013 for Mantis-0011645
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
                ' Error while inserting into cms_calllog_details ' || SQLERRM;
            RAISE exp_reject_record;
      END;

      /*  call log info   END */

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
            prm_resp_code := '21';
            RETURN;
      END;

      IF prm_reason_code IS NOT NULL
      THEN
         BEGIN
            SELECT csr_reasondesc
              INTO v_csr_reason_desc
              FROM cms_spprt_reasons
             WHERE csr_inst_code = prm_inst_code
               AND csr_spprt_rsncode = prm_reason_code;

            v_reason := v_csr_reason_desc || ' ' || TRIM (prm_reason_desc);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               IF TRIM (prm_reason_desc) IS NOT NULL
               THEN
                  v_reason := TRIM (prm_reason_desc);
               END IF;

            WHEN OTHERS
            THEN
               IF TRIM (prm_reason_desc) IS NOT NULL
               THEN
                  v_reason := TRIM (prm_reason_desc);
               END IF;

         END;
      ELSE
         v_reason := TRIM (prm_reason_desc);
      END IF;

      --Below block Moved Up for FSS-754 : To log Merchant Name in case of declined transaction as well
      --Sn get orginal transaction

      BEGIN
      
       --Added for VMS-5733/FSP-991

v_Retdate := TO_DATE(SUBSTR(TRIM(prm_orgnl_tran_date), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';



IF (v_Retdate>v_Retperiod)
    THEN
      
         SELECT tranfee_amt, tran_reverse_flag, fee_reversal_flag,
                tranfee_cr_acctno, tranfee_dr_acctno, response_code,
                feecode, proxy_number, tranfee_amt,
                tran_st_calc_flag, servicetax_amt,
                tran_st_cr_acctno, tran_st_dr_acctno,
                TRAN_CESS_CALC_FLAG, CESS_AMT,
                TRAN_CESS_CR_ACCTNO, TRAN_CESS_DR_ACCTNO, GL_UPD_FLAG,TXN_MODE,
                merchant_name  -- added by Dnyaneshwar on 16APR2013
           INTO v_fee_amt, v_reverse_flag, v_fee_reversal_flag,
                v_cr_acctno, v_dr_acctno, v_responsecode,
                v_fee_code, v_proxy_number, v_orgnl_tranfee_amt,
                v_orgnl_st_calc_flag, v_orgnl_servicetax_amt,
                v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno,
                V_ORGNL_CESS_CALC_FLAG, V_ORGNL_CESS_AMT,
                V_ORGNL_CESS_CR_ACCTNO, V_ORGNL_CESS_DR_ACCTNO, V_GL_UPD_FLAG,V_TXN_MODE,
                v_orgnl_merchant  -- added by Dnyaneshwar on 16APR2013
           FROM transactionlog
          WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date             --changed here
            AND business_time = prm_orgnl_tran_time             --changed here
            AND customer_card_no = v_hash_pan
            -- changed from clear pan to hash pan
            AND delivery_channel = prm_orgnl_delivery_chnl      --added by sagar on 14Sep2012
            AND txn_code         = prm_orgnl_txn_code           --added by sagar on 14Sep2012
           --AND response_code    = '00'                         --added by sagar on 14Sep2012 -- Commented on 03-Apr-2013 to reverse fee for original transactions which are declined defect MVCSD-4071
            AND NVL (AMOUNT, 0.00) = PRM_ORGNL_TXN_AMT
            for update;--Added by Dnyaneshwar J on 05 Mar 2014 for Mantis-13847
   ELSE
          SELECT tranfee_amt, tran_reverse_flag, fee_reversal_flag,
                tranfee_cr_acctno, tranfee_dr_acctno, response_code,
                feecode, proxy_number, tranfee_amt,
                tran_st_calc_flag, servicetax_amt,
                tran_st_cr_acctno, tran_st_dr_acctno,
                TRAN_CESS_CALC_FLAG, CESS_AMT,
                TRAN_CESS_CR_ACCTNO, TRAN_CESS_DR_ACCTNO, GL_UPD_FLAG,TXN_MODE,
                merchant_name  -- added by Dnyaneshwar on 16APR2013
           INTO v_fee_amt, v_reverse_flag, v_fee_reversal_flag,
                v_cr_acctno, v_dr_acctno, v_responsecode,
                v_fee_code, v_proxy_number, v_orgnl_tranfee_amt,
                v_orgnl_st_calc_flag, v_orgnl_servicetax_amt,
                v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno,
                V_ORGNL_CESS_CALC_FLAG, V_ORGNL_CESS_AMT,
                V_ORGNL_CESS_CR_ACCTNO, V_ORGNL_CESS_DR_ACCTNO, V_GL_UPD_FLAG,V_TXN_MODE,
                v_orgnl_merchant  -- added by Dnyaneshwar on 16APR2013
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date             --changed here
            AND business_time = prm_orgnl_tran_time             --changed here
            AND customer_card_no = v_hash_pan
            -- changed from clear pan to hash pan
            AND delivery_channel = prm_orgnl_delivery_chnl      --added by sagar on 14Sep2012
            AND txn_code         = prm_orgnl_txn_code           --added by sagar on 14Sep2012
           --AND response_code    = '00'                         --added by sagar on 14Sep2012 -- Commented on 03-Apr-2013 to reverse fee for original transactions which are declined defect MVCSD-4071
            AND NVL (AMOUNT, 0.00) = PRM_ORGNL_TXN_AMT
            for update;--Added by Dnyaneshwar J on 05 Mar 2014 for Mantis-13847
        END IF;    

      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Orginal transaction record not found';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'while selecting orginal txn detail'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --En get orginal transaction

      --Sn Duplicate RRN Check
      BEGIN
      v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');
      
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
            v_err_msg  := 'Duplicate RRN found' || prm_rrn;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
         RAISE exp_reject_record;
      WHEN OTHERS THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting rrn count'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;     
      END;

      --En Duplicate RRN Check
     
      --Sn get the prod detail
      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_acct_no, cap_card_stat,
                cap_expry_date
           INTO v_prod_code, v_card_type, v_card_acct_no, v_card_stat,
                v_expry_date
           FROM cms_appl_pan
          WHERE cap_inst_code = prm_inst_code
            AND cap_pan_code = v_hash_pan
            -- changed from clear pan to hash pan
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

      --Sn check acct bal for debitted acct
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code --added by Pankaj S. for 10871
           INTO v_acct_balance, v_ledger_bal,
                v_acct_type --added by Pankaj S. for 10871
           FROM cms_acct_mast
          WHERE cam_inst_code = prm_inst_code AND cam_acct_no = v_card_acct_no;

         prm_acct_bal := v_acct_balance;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Account not found ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  ' Error while selecting data from acct master  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --En check acct balance for debitted acct

      --SN: get profile code
      BEGIN
                                     -- Added on 09-Feb-2013 for max card balance check based on product category
         SELECT cpc_profile_code     -- commneted by sagar on 14-Sep-2012 to fetch profile code based on Product code only
           INTO v_profile_code
           FROM cms_prod_cattype
          WHERE cpc_prod_code = v_prod_code
            AND cpc_card_type = v_card_type
            AND cpc_inst_code = prm_inst_code;


      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '49';
            v_err_msg := 'profile_code not defined ' || v_profile_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'profile_code not defined ' || v_profile_code;
            RAISE exp_reject_record;
      END;
      --EN: get profile code


      --Sn: get max topup limit
      BEGIN
         SELECT cbp_param_value
           INTO v_max_limit
           FROM cms_bin_param
          WHERE cbp_profile_code = v_profile_code
            AND cbp_param_type = 'Max Card Balance'
            AND cbp_param_name = 'Max Card Balance';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=
                  'max Card Balance not configured for profile code '
               || v_profile_code;
            RAISE exp_reject_record;
      END;

      --Sn: get max topup limit
      v_check_max_bal := prm_acct_bal + prm_txn_amt;

      IF v_max_limit < v_check_max_bal
      THEN
         v_resp_cde := '2';
         v_err_msg := 'Fee Reversal failed.Maximum balance exceeding';
         RAISE exp_reject_record;
      END IF;

      --***********SN:GPR changes added on 27-FEB-2012*****************
      BEGIN
         sp_status_check_gpr (prm_inst_code,
                              prm_orgnl_card_no,
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
                              NULL, --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                              NULL,
                              v_resp_cde,
                              v_err_msg
                             );

         IF (   (v_resp_cde <> '1' AND v_err_msg <> 'OK')
             OR (v_resp_cde <> '0' AND v_err_msg <> 'OK')
            )
         THEN
            RAISE exp_reject_record;
         END IF;
         
            v_status_chk := v_resp_cde;
            v_resp_cde := '1';

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

      --***********EN:GPR changes added on 27-FEB-2012 *******************
      IF v_status_chk = '1'
      THEN              -- IF condition checked for GPR changes on 27-FEB-2012
         --Sn : check expiry card
         IF TRUNC (v_expry_date) < TO_DATE (prm_tran_date, 'yyyymmdd')
         THEN
            v_resp_cde := '13';                      --Ineligible Transaction
            v_err_msg := 'EXPIRED CARD';
            RAISE exp_reject_record;
         END IF;

         --En : check expiry card

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
               v_resp_cde := '10'; -- response id changed from 49 to 10 on 09-Oct-2012
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


         --Sn commented for fwr-48
        
      --Sn check is it already reversed
      BEGIN
         IF v_reverse_flag = 'Y'
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Transaction is already reversed';
            RAISE exp_reject_record;
         ELSIF v_fee_reversal_flag = 'Y'
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Fee reversal transaction is already done for the transaction';
            RAISE exp_reject_record;
         END IF;
      END;

      --En check is it already reversed
      --Sn check reverse amount
      BEGIN
         IF prm_txn_amt <> v_fee_amt
         -- changed from prm_fee_amt to prm_txn_amt as discussed with
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Requested fee amount is not matching with transaction fee amount';
            RAISE exp_reject_record;
         END IF;
      END;

      --En check reverse amount
      --Sn find the type of orginal txn (credit or debit)
      BEGIN
         SELECT ctm_credit_debit_flag
           INTO v_dr_cr_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_txn_code
            AND ctm_delivery_channel = prm_delivery_chnl
            AND ctm_inst_code = prm_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '49';
            v_err_msg :=
                  'Transaction detail is not found in master for reversal txn '
               || prm_txn_code
               || 'delivery channel '
               || prm_delivery_chnl;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting debit/credit flag for reversal txn'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --En find the type of orginal txn (credit or debit)
      
      
      -- get fee Description  VMS-1038
       BEGIN
         SELECT CFM_FEE_DESC ||'  Reversal'
          into v_tran_desc
           from CMS_FEE_MAST
          WHERE CFM_FEE_CODE = v_fee_code and CFM_INST_CODE=prm_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '49';
            v_err_msg :=
                  'Fee detail is not found in master for reversal txn '
               || prm_txn_code
               || 'delivery channel '
               || prm_delivery_chnl;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting Fee Description for reversal txn'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
      -- end


      BEGIN -- added by sagar on 06Sep2012 to fetch de/cr flag for orgnl transaction

         SELECT ctm_credit_debit_flag
           INTO v_orgnl_drcr_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_orgnl_txn_code
            AND ctm_delivery_channel = prm_orgnl_delivery_chnl
            AND ctm_inst_code = prm_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '49';
            v_err_msg :=
                  'Transaction detail is not found in master for orgnl txn '
               || prm_orgnl_txn_code
               || 'delivery channel '
               || prm_orgnl_delivery_chnl;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting debit/credit flag for orgnl transaction'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;

      END; -- added by sagar on 06Sep2012 to fetch de/cr flag for orgnl transaction




      --Sn find the card curr
      BEGIN
         vmsfunutilities.get_currency_code(v_prod_code,v_card_type,prm_inst_code,V_CARD_CURR,v_err_msg);
      
      if v_err_msg<>'OK' then
           raise exp_reject_record;
      end if;

         IF TRIM (v_card_curr) IS NULL
         THEN
            v_resp_cde := '49';
            v_err_msg := 'Card currency cannot be null ';
            RAISE exp_reject_record;
         END IF;

      EXCEPTION WHEN exp_reject_record
      THEN
          RAISE;

      WHEN NO_DATA_FOUND
      THEN
            v_resp_cde := '49';
            v_err_msg := 'card currency is not defined for the institution ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting card currecy  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --En find the card curr
      v_narration :=
            ' for rrn '
         || prm_orgnl_rrn
         || ' date: '
         || TO_DATE (prm_orgnl_tran_date || ' ' || prm_orgnl_tran_time,
                     'yyyymmdd hh24miss'
                    );
      v_timestamp:=systimestamp;  --added by Pankaj S. for 10871

      BEGIN
         sp_reverse_fee_amount
                       (prm_inst_code,
                        prm_rrn,
                        prm_delivery_chnl,
                        NULL,                         --PRM_ORGNL_TERMINAL_ID,
                        NULL,                                   --PRM_MERC_ID,
                        prm_txn_code,
                        TO_DATE (prm_tran_date, 'yyyymmdd'),
                        prm_txn_mode,
                        v_fee_amt,
                        prm_orgnl_card_no,
                        v_fee_code,
                        v_orgnl_tranfee_amt,
                        v_cr_acctno,
                        v_dr_acctno,
                        v_orgnl_st_calc_flag,
                        v_orgnl_servicetax_amt,
                        v_orgnl_st_cr_acctno,
                        v_orgnl_st_dr_acctno,
                        v_orgnl_cess_calc_flag,
                        v_orgnl_cess_amt,
                        v_orgnl_cess_cr_acctno,
                        v_orgnl_cess_dr_acctno,
                        prm_orgnl_rrn, --changed from prm_rrn to prm_orgnl_rrn
                        v_card_acct_no,
                        prm_tran_date,
                        prm_tran_time,
                        v_auth_id,
                        v_tran_desc,                              -- Narration
                        prm_merc_name,
                        prm_merc_city,
                        prm_merc_state,
                        v_resp_cde,
                        v_err_msg
                       );

         IF v_resp_cde <> '00' OR v_err_msg <> 'OK'
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
                  'Error while reversing the fee amount '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --Sn commented for fwr-48

      --Sn check acct bal for debitted acct
      --Sn update reverse flag
      BEGIN
      
     v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');
      
      IF (v_Retdate>v_Retperiod)
    THEN
         UPDATE transactionlog
            SET fee_reversal_flag = 'Y'
          WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date
            AND business_time = prm_orgnl_tran_time
            AND customer_card_no = v_hash_pan             --prm_orgnl_card_no;
            AND instcode = prm_inst_code;
        ELSE
             UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            SET fee_reversal_flag = 'Y'
          WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date
            AND business_time = prm_orgnl_tran_time
            AND customer_card_no = v_hash_pan             --prm_orgnl_card_no;
            AND instcode = prm_inst_code;
         END IF;   

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Reverse flag is not updated ';
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
                  'Error while updating gl flag ' || SUBSTR (SQLERRM, 1, 150);
            RAISE exp_reject_record;
      END;

      --Sn added by Pankaj S. for 10871
        BEGIN
        
        --Added for VMS-5733/FSP-991

v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';



IF (v_Retdate>v_Retperiod)
    THEN
           UPDATE cms_statements_log
              SET csl_time_stamp = v_timestamp
            WHERE csl_inst_code= prm_inst_code
              AND csl_pan_no = v_hash_pan
              AND csl_rrn = prm_rrn
              AND csl_txn_code = prm_txn_code
              AND csl_delivery_channel = prm_delivery_chnl
              AND csl_business_date = prm_tran_date
              AND csl_business_time = prm_tran_time;
           ELSE
              UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
              SET csl_time_stamp = v_timestamp
            WHERE csl_inst_code= prm_inst_code
              AND csl_pan_no = v_hash_pan
              AND csl_rrn = prm_rrn
              AND csl_txn_code = prm_txn_code
              AND csl_delivery_channel = prm_delivery_chnl
              AND csl_business_date = prm_tran_date
              AND csl_business_time = prm_tran_time;
           END IF;      

           IF SQL%ROWCOUNT =0
           THEN
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
                   'Error while updating timestamp in statementlog-' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
       --En added by Pankaj S. for 10871
      --En update reverse flag
      BEGIN         --SN to  get the  balance after updating customers account
         SELECT cam_acct_bal
           INTO prm_acct_bal
           FROM cms_acct_mast
          WHERE cam_inst_code = prm_inst_code AND cam_acct_no = v_card_acct_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'error occured while getting current balance '
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;          --SN to  get the  balance after updating customers account

      v_resp_cde := '1';

      --Sn get record for successful transaction
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
            v_err_msg :=
                  'Problem while selecting data from response master1 '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';

            RAISE exp_reject_record;

      END;

      --En get record for successful transaction
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
              VALUES (prm_delivery_chnl, prm_txn_code, 1,
                      prm_msg_type,      --changed from '0420' to prm_msg_type
                                   prm_txn_mode, prm_tran_date,
                      --TO_CHAR (TRUNC (SYSDATE), 'yyyymmdd'), changed here
                      prm_tran_time,
                                    --TO_CHAR (TRUNC (SYSDATE), 'hh24miss'),  changed here
                                    v_hash_pan,
                      prm_txn_amt,      --changed here from fee_amt to txn_amt
                                  prm_txn_curr, prm_txn_amt,
                      --changed here from fee_amt to txn_amt
                      prm_txn_amt,      --changed here from fee_amt to txn_amt
                                  v_card_curr, 'Y',      --changed from E to Y
                      v_err_msg, prm_rrn, prm_stan,
                      prm_inst_code, fn_emaps_main (prm_orgnl_card_no),
                      v_card_acct_no, SYSDATE, prm_ins_user
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while inserting in log detail '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;

      END;

      -- Sn create a entry in GL
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type,
                      bank_code, total_amount, rule_indicator, rulegroupid,
                      mccode, currencycode, productid, categoryid,tranfee_amt,
                      tips,
                      decline_ruleid, atm_name_location,
                      auth_id,
                      trans_desc,
                      amount, preauthamount, partialamount, mccodegroupid,
                      currencycodegroupid, transcodegroupid, rules,
                      preauth_date, gl_upd_flag, system_trace_audit_no,
                      instcode, feecode, feeattachtype, tran_reverse_flag,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance,
                      error_msg, orgnl_card_no, orgnl_rrn,
                      orgnl_business_date, orgnl_business_time,
                      orgnl_terminal_id, add_ins_date, add_ins_user, remark,
                      reason,response_id,
                      ipaddress,  --added by amit on 07-Oct-2012
                      CR_DR_FLAG, --added by amit on 07-Oct-2012
                      ADD_LUPD_USER, --added by amit on 07-Oct-2012
                      merchant_name,  -- added by Dnyaneshwar on 16APR2013
                      --Sn added by Pankaj S. for 10871
                      cardstatus,
                      acct_type,
                      time_stamp
                      --En added by Pankaj S. for 10871
                     )
              VALUES (prm_msg_type,
                                   --'0420',                       changed here
                                   prm_rrn, prm_delivery_chnl, NULL,
                      TO_DATE (prm_tran_date || ' ' || prm_tran_time,'yyyymmdd hh24miss'), prm_txn_code, 1, prm_txn_mode,
                      DECODE (prm_resp_code, '00', 'C', 'F'), prm_resp_code,
                      prm_tran_date,
                                    --TO_CHAR (TO_DATE (SYSDATE), 'yyyymmdd'),         changed here
                                    prm_tran_time,
                                                  --TO_CHAR (TO_DATE (SYSDATE), 'hh24miss'),         changed here
                                                  v_hash_pan,
                      NULL, NULL, NULL,
                      prm_inst_code,TRIM(TO_CHAR(prm_txn_amt, '999999999999999990.99')), --modified for 10871
                                                 --prm_fee_amt,                   changed here
                      NULL, NULL,
                      NULL, prm_txn_curr, v_prod_code, v_card_type,0,
                      '0.00', --modified by Pankaj S. for 10871
                       NULL, NULL,
                      v_auth_id,
                         v_tran_desc,
                      TRIM(TO_CHAR(prm_txn_amt, '999999999999999990.99')), --modified for 10871
                                  --prm_fee_amt,                           changed here
                      '0.00', '0.00', --modified by Pankaj S. for 10871
                      NULL,
                      NULL, NULL, NULL,
                      NULL, 'Y', prm_stan,
                      prm_inst_code, NULL, NULL, 'N',
                      fn_emaps_main (prm_orgnl_card_no), NULL,
                      v_proxy_number, prm_rvsl_code, v_card_acct_no,
                      v_acct_balance + v_fee_amt, v_ledger_bal + v_fee_amt,
                      v_err_msg, fn_emaps_main (prm_orgnl_card_no), -- changes done by sagar on 24Jul2012 to store encrypted pan in Orgnl_card_no field
                      prm_orgnl_rrn,
                      prm_orgnl_tran_date, prm_orgnl_tran_time,
                      NULL, SYSDATE, prm_ins_user, prm_remark,
                      v_reason,v_resp_cde,
                      prm_ipaddress, --added by amit on 07-Oct-2012
                      V_DR_CR_FLAG,  --added by amit on 07-Oct-2012
                      PRM_INS_USER,   --added by amit on 07-Oct-2012
                      v_orgnl_merchant , -- added by Dnyaneshwar on 16APR2013
                      --Sn added by Pankaj S. for 10871
                      v_card_stat,
                      v_acct_type,
                      v_timestamp
                      --En added by Pankaj S. for 10871
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Error while inserting in txnlog ' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
   EXCEPTION                              --<< MAIN REVERSAL PART EXCEPTION >>
      WHEN exp_reject_record
      THEN
         ROLLBACK TO SAVEPOINT p1;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal,
                   cam_type_code --added by Pankaj S. for 10871
              INTO v_acct_balance, v_ledger_bal,
                   v_acct_type --added by Pankaj S. for 10871
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code
               AND cam_acct_no =
                      (SELECT cap_acct_no
                         FROM cms_appl_pan
                        WHERE cap_pan_code = v_hash_pan          --prm_card_no
                          AND cap_mbr_numb = prm_mbr_numb
                          AND cap_inst_code = prm_inst_code);

            prm_acct_bal := v_acct_balance;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
               prm_acct_bal := 0;
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
                         --ctd_ins_date,
                         ctd_ins_user
                        )
                 VALUES (prm_delivery_chnl, prm_txn_code, 1,
                         prm_msg_type,   --changed from '0420' to prm_msg_type
                                      prm_txn_mode, prm_tran_date,
                         --TO_CHAR (TRUNC (SYSDATE), 'yyyymmdd'), changed here
                         prm_tran_time,
                                       --TO_CHAR (TRUNC (SYSDATE), 'hh24miss'),  changed here
                                       v_hash_pan,
                         prm_txn_amt,   --changed here from fee_amt to txn_amt
                                     prm_txn_curr, prm_txn_amt,
                         --changed here from fee_amt to txn_amt
                         prm_txn_amt,   --changed here from fee_amt to txn_amt
                                     v_card_curr, 'E',
                         v_err_msg, prm_rrn,
                         prm_stan, prm_inst_code,
                         fn_emaps_main (prm_orgnl_card_no), v_card_acct_no,
                         --SYSDATE,
                         prm_ins_user
                        );

            dum := SQL%ROWCOUNT;

            IF dum = 0
            THEN
               RETURN;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in log detail 1'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

          --Sn added by Pankaj S. for 10871
          IF v_dr_cr_flag IS NULL THEN
          BEGIN
           SELECT ctm_credit_debit_flag
               INTO v_dr_cr_flag
               FROM cms_transaction_mast
              WHERE ctm_tran_code = prm_txn_code
                AND ctm_delivery_channel = prm_delivery_chnl
                AND ctm_inst_code = prm_inst_code;
          EXCEPTION
             WHEN OTHERS THEN
                NULL;
          END;
          END IF;

          IF v_prod_code is NULL THEN
          BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
              INTO v_prod_code, v_card_type, v_card_stat,v_card_acct_no
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_inst_code
               AND cap_pan_code = gethash (prm_orgnl_card_no);
          EXCEPTION
             WHEN OTHERS THEN
                NULL;
          END;
          END IF;
          --En added by Pankaj S. for 10871


         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, terminal_id,
                         date_time, txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no, topup_card_no, topup_acct_no,
                         topup_acct_type, bank_code, total_amount,
                         rule_indicator, rulegroupid, mccode, currencycode,
                         productid, categoryid, tranfee_amt, tips,
                         decline_ruleid, atm_name_location, auth_id,
                         trans_desc, amount, preauthamount, partialamount,
                         mccodegroupid, currencycodegroupid,
                         transcodegroupid, rules,             -- preauth_date,
                                                 gl_upd_flag,
                         system_trace_audit_no, instcode, feecode,
                         feeattachtype, tran_reverse_flag,
                         customer_card_no_encr, topup_card_no_encr,
                         proxy_number, reversal_code, customer_acct_no,
                         acct_balance, ledger_balance, error_msg,
                         orgnl_card_no, orgnl_rrn, orgnl_business_date,
                         orgnl_business_time, orgnl_terminal_id,
                         --add_ins_date,
                         add_ins_user, remark, reason,response_id,
                         ipaddress,  --added by amit on 07-Oct-2012
                         CR_DR_FLAG, --added by amit on 07-Oct-2012
                         ADD_LUPD_USER, --added by amit on 07-Oct-2012
                         merchant_name,  -- added by Dnyaneshwar on 16APR2013
                         --Sn added by Pankaj S. for 10871
                         cardstatus,
                         acct_type,
                         time_stamp
                         --En added by Pankaj S. for 10871
                        )
                 VALUES (prm_msg_type,
                                      --'0420',                       changed here
                                      prm_rrn, prm_delivery_chnl, NULL,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,'yyyymmdd hh24miss'), prm_txn_code, 1, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_tran_date,
                                                      --TO_CHAR (TO_DATE (SYSDATE), 'yyyymmdd'),         changed here
                                                      prm_tran_time,
                         --TO_CHAR (TO_DATE (SYSDATE), 'hh24miss'),         changed here
                         v_hash_pan, NULL, NULL,
                         NULL, prm_inst_code, TRIM(TO_CHAR(prm_txn_amt, '999999999999999990.99')), --modified for 10871
                         --prm_fee_amt,                   changed here
                         NULL, NULL, NULL, prm_txn_curr,
                         v_prod_code, v_card_type, 0, '0.00',--modified by Pankaj S. for 10871
                         NULL, NULL, v_auth_id,
                         v_tran_desc, TRIM(TO_CHAR(prm_txn_amt, '999999999999999990.99')), --modified for 10871
                                                  --prm_fee_amt,                           changed here
                         '0.00', '0.00',--modified by Pankaj S. for 10871
                         NULL, NULL,
                         NULL, NULL,                                  -- NULL,
                                    'Y',
                         prm_stan, prm_inst_code, NULL,
                         NULL, 'N',
                         fn_emaps_main (prm_orgnl_card_no), NULL,
                         v_proxy_number, prm_rvsl_code, v_card_acct_no,
                         v_acct_balance, v_ledger_bal, v_err_msg,
                         fn_emaps_main (prm_orgnl_card_no), -- changes done by sagar on 24Jul2012 to store encrypted pan in Orgnl_card_no field
                         prm_rrn, prm_tran_date,
                         prm_tran_time, NULL,
                         --SYSDATE,
                         prm_ins_user, prm_remark, v_reason,v_resp_cde,
                         prm_ipaddress, --added by amit on 07-Oct-2012
                         V_DR_CR_FLAG,  --added by amit on 07-Oct-2012
                         PRM_INS_USER,   --added by amit on 07-Oct-2012
                         v_orgnl_merchant,  -- added by Dnyaneshwar on 16APR2013
                         --Sn added by Pankaj S. for 10871
                         v_card_stat,
                         v_acct_type,
                         nvl(v_timestamp,systimestamp)
                         --En added by Pankaj S. for 10871
                        );

            dum := SQL%ROWCOUNT;

            IF dum = 0
            THEN
               RETURN;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in txnlog 1'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
      WHEN OTHERS
      THEN
         ROLLBACK;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal,
                   cam_type_code --added by Pankaj S. for 10871
              INTO v_acct_balance, v_ledger_bal,
                   v_acct_type --added by Pankaj S. for 10871
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_inst_code
               AND cam_acct_no =
                      (SELECT cap_acct_no
                         FROM cms_appl_pan
                        WHERE cap_pan_code = v_hash_pan          --prm_card_no
                          AND cap_mbr_numb = prm_mbr_numb
                          AND cap_inst_code = prm_inst_code);

            prm_acct_bal := v_acct_balance;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
               prm_acct_bal := 0;
         END;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_chnl
               AND cms_response_id = '21';
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Problem while selecting data from response master3'
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
                 VALUES (prm_delivery_chnl, prm_txn_code, 1,
                         prm_msg_type,   --changed from '0420' to prm_msg_type
                                      prm_txn_mode, prm_tran_date,
                         --TO_CHAR (TRUNC (SYSDATE), 'yyyymmdd'), changed here
                         prm_tran_time,
                                       --TO_CHAR (TRUNC (SYSDATE), 'hh24miss'),  changed here
                                       v_hash_pan,
                         prm_txn_amt,   --changed here from fee_amt to txn_amt
                                     prm_txn_curr, prm_txn_amt,
                         --changed here from fee_amt to txn_amt
                         prm_txn_amt,   --changed here from fee_amt to txn_amt
                                     v_card_curr, 'E',
                         v_err_msg, prm_rrn,
                         prm_stan, prm_inst_code,
                         fn_emaps_main (prm_orgnl_card_no), v_card_acct_no,
                         SYSDATE, prm_ins_user
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in log detail 2'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

         --Sn added by Pankaj S. for 10871
          IF v_dr_cr_flag IS NULL THEN
          BEGIN
           SELECT ctm_credit_debit_flag
               INTO v_dr_cr_flag
               FROM cms_transaction_mast
              WHERE ctm_tran_code = prm_txn_code
                AND ctm_delivery_channel = prm_delivery_chnl
                AND ctm_inst_code = prm_inst_code;
          EXCEPTION
             WHEN OTHERS THEN
                NULL;
          END;
          END IF;

          IF v_prod_code is NULL THEN
          BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
              INTO v_prod_code, v_card_type, v_card_stat,v_card_acct_no
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_inst_code
               AND cap_pan_code = gethash (prm_orgnl_card_no);
          EXCEPTION
             WHEN OTHERS THEN
                NULL;
          END;
          END IF;
          --En added by Pankaj S. for 10871

         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel, terminal_id,
                         date_time, txn_code, txn_type, txn_mode,
                         txn_status,
                         response_code, business_date, business_time,
                         customer_card_no, topup_card_no, topup_acct_no,
                         topup_acct_type, bank_code, total_amount,
                         rule_indicator, rulegroupid, mccode, currencycode,
                         productid, categoryid, tranfee_amt, tips,
                         decline_ruleid, atm_name_location, auth_id,
                         trans_desc, amount, preauthamount, partialamount,
                         mccodegroupid, currencycodegroupid,
                         transcodegroupid, rules, preauth_date, gl_upd_flag,
                         system_trace_audit_no, instcode, feecode,
                         feeattachtype, tran_reverse_flag,
                         customer_card_no_encr, topup_card_no_encr,
                         proxy_number, reversal_code, customer_acct_no,
                         acct_balance, ledger_balance, error_msg,
                         orgnl_card_no, orgnl_rrn, orgnl_business_date,
                         orgnl_business_time, orgnl_terminal_id,
                         add_ins_date, add_ins_user, remark, reason,response_id,
                         ipaddress,  --added by amit on 07-Oct-2012
                         CR_DR_FLAG, --added by amit on 07-Oct-2012
                         ADD_LUPD_USER, --added by amit on 07-Oct-2012
                         merchant_name,  -- added by Dnyaneshwar on 16APR2013
                         --Sn added by Pankaj S. for 10871
                         cardstatus,
                         acct_type,
                         time_stamp
                         --En added by Pankaj S. for 10871
                        )
                 VALUES (prm_msg_type,
                                      --'0420',                       changed here
                                      prm_rrn, prm_delivery_chnl, NULL,
                         TO_DATE (prm_tran_date || ' ' || prm_tran_time,'yyyymmdd hh24miss'), prm_txn_code, 1, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_tran_date,
                                                      --TO_CHAR (TO_DATE (SYSDATE), 'yyyymmdd'),         changed here
                                                      prm_tran_time,
                         --TO_CHAR (TO_DATE (SYSDATE), 'hh24miss'),         changed here
                         v_hash_pan, NULL, NULL,
                         NULL, prm_inst_code, TRIM(TO_CHAR(prm_txn_amt, '999999999999999990.99')), --modified for 10871
                         --prm_fee_amt,                   changed here
                         NULL, NULL, NULL, prm_txn_curr,
                         v_prod_code, v_card_type, 0, '0.00', --modified by Pankaj S. for 10871
                         NULL, NULL, v_auth_id,
                         v_tran_desc, TRIM(TO_CHAR(prm_txn_amt, '999999999999999990.99')), --modified for 10871
                                                  --prm_fee_amt,                           changed here
                         '0.00', '0.00', --modified by Pankaj S. for 10871
                         NULL, NULL,
                         NULL, NULL, NULL, 'Y',
                         prm_stan, prm_inst_code, NULL,
                         NULL, 'N',
                         fn_emaps_main (prm_orgnl_card_no), NULL,
                         v_proxy_number, prm_rvsl_code, v_card_acct_no,
                         v_acct_balance, v_ledger_bal, v_err_msg,
                         fn_emaps_main (prm_orgnl_card_no) -- changes done by sagar on 24Jul2012 to store encrypted pan in Orgnl_card_no field
                         , prm_rrn, prm_tran_date,
                         prm_tran_time, NULL,
                         SYSDATE, prm_ins_user, prm_remark, v_reason,v_resp_cde,
                         prm_ipaddress, --added by amit on 07-Oct-2012
                         V_DR_CR_FLAG,  --added by amit on 07-Oct-2012
                         PRM_INS_USER,   --added by amit on 07-Oct-2012
                         v_orgnl_merchant,  -- added by Dnyaneshwar on 16APR2013
                         --Sn added by Pankaj S. for 10871
                         v_card_stat,
                         v_acct_type,
                         nvl(v_timestamp,systimestamp)
                         --En added by Pankaj S. for 10871
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in txnlog 2'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
   END;                                        --<< MAIN REVERSAL PART  END >>

   prm_acct_bal := TO_CHAR (prm_acct_bal, '99,99,99,999.99');
EXCEPTION                                              -- << MAIN EXCEPTION >>
   WHEN OTHERS
   THEN
      prm_errmsg := 'ERROR FROM MAIN ' || SUBSTR (SQLERRM, 1, 100);
END;                                                         -- << MAIN END >>

/
show error