create or replace
PROCEDURE        vmscms.sp_upgrade_to_personalisedcard (
   p_inst_code          IN       NUMBER,
   p_msg_type           IN       VARCHAR2,
   p_mbr_numb           IN       VARCHAR2,
   p_starter_card       IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2, 
   p_rrn                IN       VARCHAR2, 
   p_stan               IN       VARCHAR,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_consodium_code     IN       NUMBER,
   p_partner_code       IN       NUMBER,
   p_call_id            IN       NUMBER,
   p_reason_code        IN       NUMBER,
   p_remark             IN       VARCHAR2,
   p_ins_user           IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,             -- added on 22-Jun-2012
   p_merchant_name      IN       VARCHAR2,             -- added on 22-Jun-2012
   p_merchant_city      IN       VARCHAR2,             -- added on 22-Jun-2012
   p_ipaddress          IN       VARCHAR2,         -- added on 06-Oct-2012 by amit to log in transactionlog table
   p_resp_msg           OUT      VARCHAR2,
   p_resp_code          OUT      VARCHAR2
)
IS
   /**********************************************************************************************
  * VERSION           :  1.0
  * DATE OF CREATION  : 11/May/2012
  * PURPOSE           : upgrade to personlaised card
                           (reissue GPR card for existing starter card)
  * CREATED BY        : Sagar More
  * modified for      : SSN validations - New CR
  * modified Date     : 08-Feb-2013
  * modified reason   : 1) to check for thresholdlimit before pan generation 
                        2) v_resp_cde Datatype size change
                        
  * modified for      : SSN validations - New CR
  * modified Date     : 19-Feb-2013
  * modified reason   : 1) response id changed from 157 to 158                     
  * Reviewer          : Dhiarj
  * Reviewed Date     : 08-Feb-2013
  * Build Number      : CMS3.5.1_RI0023.2_B0001
  
  * modified by       : Pankaj S. 
  * modified for      : DFCHOST-249
  * modified Date     : 27-Feb-2013
  * modified reason   : Starter card proxy number need to assign to newly generated GPR card.                     
  * Reviewer          : Dhiarj
  * Reviewed Date     : 
  * Build Number      : RI0023.2_B0011
  
  * Modified by      :  Pankaj S.
  * Modified Reason  :  10871
  * Modified Date    :  18-Apr-2013
  * Reviewer         :  Dhiraj
  * Reviewed Date    :  
  * Build Number     :  RI0024.1_B0013
  
  * Modified by      : MageshKumar.S 
  * Modified Reason  : JH-6(Fast50 and Fedral And State Tax Refund Alerts) 
  * Modified Date    : 19-09-2013
  * Reviewer         : Dhiraj 
  * Reviewed Date    : 19.09.2013 
  * Build Number     : RI0024.5_B0001
  
   * Modified By      : Raja Gopal G
   * Modified Date    : 30-Jul-2014
   * Modified Reason  : Check Deposit Pending ,Accepted And Rejected Alerts(FR 3.2)           
   * Reviewer         : Spankaj
   * Build Number     : RI0027.3.1_B0002
   
   * Modified By      : MageshKumar.S
   * Modified Date    : 08-Sep-2015
   * Modified Reason  : MVHOST-1196 (GPR card sent to AVQ)
   * Reviewer         : Spankaj
   * Build Number     : RI003.1_B00011
   
       * Modified by       :Siva kumar 
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006
       
       * Modified by       :Siva kumar 
       * Modified Date    : 08-May-19
       * Modified For     : VMS-924
       * Reviewer         : Saravanankumar
       * Build Number     : R15_B4
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991

  **************************************************************************************************/
   v_cap_card_stat             cms_appl_pan.cap_card_stat%TYPE;
   v_cap_disp_name             cms_appl_pan.cap_disp_name%TYPE;
   v_cap_cust_code             cms_appl_pan.cap_cust_code%TYPE;
   v_cap_bill_addr             cms_appl_pan.cap_bill_addr%TYPE;
   v_hash_starter_pan          cms_appl_pan.cap_pan_code%TYPE;
   v_encr_starter_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cap_expry_date            cms_appl_pan.cap_expry_date%TYPE;
   v_cap_prod_code             cms_appl_pan.cap_prod_code%TYPE;
   v_cap_card_type             cms_appl_pan.cap_card_type%TYPE;
   v_cap_acct_no               cms_appl_pan.cap_acct_no%TYPE;
   v_resp_cde                  VARCHAR2 (5); -- Datatype size change on 08-Feb-2013
   v_errmsg                    VARCHAR2 (300);
   exp_reject_record           EXCEPTION;
   v_status_chk                VARCHAR2 (2);
   v_rrn_count                 NUMBER (1);
   v_tran_type                 cms_transaction_mast.ctm_tran_type%TYPE;
   v_txn_type                  VARCHAR2 (1);
   v_cfm_func_code             cms_func_mast.cfm_func_code%TYPE;
   v_check_statcnt             NUMBER (1);
   v_cap_proxunumber           cms_appl_pan.cap_proxy_number%TYPE;
   v_fee_code                  cms_fee_mast.cfm_fee_code%TYPE;
   v_fee_crgl_catg             cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_fee_crgl_code             cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_fee_crsubgl_code          cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_fee_cracct_no             cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_drgl_catg             cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_fee_drgl_code             cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_fee_drsubgl_code          cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_fee_dracct_no             cms_prodcattype_fees.cpf_dracct_no%TYPE;
   --st and cess
   v_servicetax_percent        cms_inst_param.cip_param_value%TYPE;
   v_cess_percent              cms_inst_param.cip_param_value%TYPE;
   v_servicetax_amount         NUMBER;
   v_cess_amount               NUMBER;
   v_st_calc_flag              cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_cess_calc_flag            cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_st_cracct_no              cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_st_dracct_no              cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_cess_cracct_no            cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_cess_dracct_no            cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   v_waiv_percnt               cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_hold_amount               NUMBER                                    := 0;
   v_acct_bal                  cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal                cms_acct_mast.cam_ledger_bal%TYPE;
   v_dr_cr_flag                cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_gpr_mbr_numb              cms_htlst_reisu.chr_new_mbr%TYPE;
   v_startercard_appl_status   cms_cardissuance_status.ccs_card_status%TYPE;
   v_cap_startercard_flag      cms_appl_pan.cap_startercard_flag%TYPE;
   v_gprcard_appl_status       cms_cardissuance_status.ccs_card_status%TYPE;
   v_tran_date                 DATE;
   v_fee_amt                   NUMBER;
   v_log_actual_fee            NUMBER;
   v_log_waiver_amt            NUMBER;
   v_total_fee                 NUMBER;
   v_fee_opening_bal           NUMBER;
   v_upd_amt                   NUMBER;
   v_upd_ledger_amt            NUMBER;
   v_auth_id                   transactionlog.auth_id%TYPE;
   v_gpr_pan_code              cms_appl_pan.cap_pan_code%TYPE;
   new_gpr_card_no             VARCHAR2 (50);
   v_chk_starter_card          cms_appl_pan.cap_startercard_flag%TYPE;
   v_cap_prod_catg             cms_appl_pan.cap_prod_catg%TYPE;
   new_gpr_mbr_numb            cms_appl_pan.cap_mbr_numb%TYPE;
   v_table_list                VARCHAR2 (2000);
   v_colm_list                 VARCHAR2 (2000);
   v_colm_qury                 VARCHAR2 (4000);
   v_new_value                 VARCHAR2 (4000);
   v_hash_new_gpr_card         cms_appl_pan.cap_pan_code%TYPE;
   v_call_seq                  NUMBER (3);
   v_gprcard_type              cms_prod_cattype.cpc_startergpr_crdtype%TYPE;
   v_proxylength               cms_prod_mast.cpm_proxy_length%TYPE;
   v_getseqno                  VARCHAR2 (200);
   v_programid                 cms_prod_mast.cpm_program_id%TYPE;
   v_seqno                     cms_program_id_cnt.cpi_sequence_no%TYPE;
   v_proxy_number              cms_appl_pan.cap_proxy_number%TYPE;
   v_capture_date              DATE;
   v_reason                    cms_spprt_reasons.csr_reasondesc%TYPE;
   v_resoncode                 cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_spnd_acctno               cms_appl_pan.cap_acct_no%TYPE;
-- ADDED BY GANESH ON 19-JUL-12
   v_ssn                    cms_cust_mast.ccm_ssn%TYPE;
   v_ssn_crddtls            VARCHAR2 (4000); 
   v_acct_type    cms_acct_mast.cam_type_code%TYPE;-- added by Pankaj S. for 10871
   V_Appl_Code             Cms_Appl_Pan.Cap_Appl_Code%Type; --Added for MVHOST-1196
v_fee_flagcheck varchar2(20):='Y';
 v_Retperiod  date; --Added for VMS-5733/FSP-991
   v_Retdate  date; --Added for VMS-5733/FSP-991
BEGIN
   BEGIN
      BEGIN
         v_hash_starter_pan := gethash (p_starter_card);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while converting stater pan into hash'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_encr_starter_pan := fn_emaps_main (p_starter_card);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while converting stater pan into hash'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         --         SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cut_table_list, cut_colm_list, cut_colm_qury
           INTO v_table_list, v_colm_list, v_colm_qury
           FROM cms_calllogquery_mast
          WHERE cut_inst_code = p_inst_code
            AND cut_devl_chnl = p_delivery_channel
            AND cut_txn_code = p_txn_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '49';
            v_errmsg := 'Column list not found in cms_calllogquery_mast ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while fetching Column list '
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      BEGIN
--Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod)
    THEN
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_starter_pan
            AND rrn = p_rrn
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code
            AND business_date = p_tran_date
            AND business_time = p_tran_time;
     ELSE
        SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_starter_pan
            AND rrn = p_rrn
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code
            AND business_date = p_tran_date
            AND business_time = p_tran_time;
     END IF;
   

         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_errmsg := 'Duplicate RRN found';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                       'while getting rrn count ' || SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cap_card_stat, cap_disp_name, cap_cust_code,
                cap_bill_addr, cap_expry_date, cap_prod_code,
                cap_card_type, cap_acct_no, cap_proxy_number,
                cap_startercard_flag, cap_prod_catg,cap_appl_code --Added for MVHOST-1196
           INTO v_cap_card_stat, v_cap_disp_name, v_cap_cust_code,
                v_cap_bill_addr, v_cap_expry_date, v_cap_prod_code,
                v_cap_card_type, v_cap_acct_no, v_cap_proxunumber,
                v_chk_starter_card, v_cap_prod_catg,v_appl_code --Added for MVHOST-1196
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code
            AND cap_mbr_numb = p_mbr_numb
            AND cap_pan_code = v_hash_starter_pan;

         IF NVL (v_chk_starter_card, '0') = 'N'
         THEN
            v_resp_cde := '49';
            v_errmsg := 'Given card is not a starter card';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';
            v_errmsg := 'Starter card not found';
            RAISE exp_reject_record;
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'While fetching details for starter card '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,cam_type_code
           INTO v_acct_bal, v_ledger_bal,v_acct_type  --v_acct_type added by Pankaj S. for 10871
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '07';
            v_errmsg := 'Account not found';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'while getting balance from acct master '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      /*
       BEGIN
          SELECT ctm_credit_debit_flag,
                 ctm_tran_type,
                 TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1'))
            INTO v_dr_cr_flag,
                 v_tran_type,
                 v_txn_type
            FROM cms_transaction_mast
           WHERE ctm_tran_code = p_txn_code
             AND ctm_delivery_channel = p_delivery_channel
             AND ctm_inst_code = p_inst_code;
       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             v_resp_cde := '12';
             v_errmsg :=
                   'Transflag  not defined for txn code '
                || p_txn_code
                || ' and delivery channel '
                || p_delivery_channel;
             RAISE exp_reject_record;
          WHEN OTHERS
          THEN
             v_resp_cde := '21';
             v_errmsg :=
                   'Error while selecting transaction details'
                || SUBSTR (SQLERRM, 1, 100);
             RAISE exp_reject_record;
       END;

       BEGIN
          SELECT cfm_func_code
            INTO v_cfm_func_code
            FROM cms_func_mast
           WHERE cfm_inst_code = p_inst_code
             AND cfm_txn_code = p_txn_code
             AND cfm_delivery_channel = p_delivery_channel;
       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             v_resp_cde := '49';
             v_errmsg :=
                   'Function not defined for txn code '
                || p_txn_code
                || ' and delivery channel '
                || p_delivery_channel;
             RAISE exp_reject_record;
          WHEN OTHERS
          THEN
             v_resp_cde := '21';
             v_errmsg :=
                   'error while fetching function code '
                || SUBSTR (SQLERRM, 1, 100);
             RAISE exp_reject_record;
       END;
      */
      BEGIN
         sp_status_check_gpr (p_inst_code,
                              p_starter_card,
                              p_delivery_channel,
                              v_cap_expry_date,
                              v_cap_card_stat,
                              p_txn_code,
                              p_txn_mode,
                              v_cap_prod_code,
                              v_cap_card_type,
                              p_msg_type,
                              p_tran_date,
                              p_tran_time,
                              null,
                              null,  --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                              null,
                              v_resp_cde,
                              v_errmsg
                             );

         IF (   (v_resp_cde <> '1' AND v_errmsg <> 'OK')
             OR (v_resp_cde <> '0' AND v_errmsg <> 'OK')
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
            v_errmsg :=
               'Error from GPR Card Status Check '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF v_status_chk = '1'
      THEN
         --Sn : check expiry card
--         IF LAST_DAY (TRUNC (v_cap_expry_date)) <
--                                            TO_DATE (p_tran_date, 'yyyymmdd')
--         -- last_day checked during expired card check
--         THEN
--            v_resp_cde := '13';                      --Ineligible Transaction
--            v_errmsg := 'EXPIRED CARD';
--            RAISE exp_reject_record;
--         END IF;
  IF LAST_DAY (TRUNC (v_cap_expry_date)) <
                                         TO_DATE (p_tran_date, 'yyyymmdd')
        -- last_day checked during expired card check
       THEN
          v_fee_flagcheck := 'N';                      --Ineligible Transaction
           
        END IF;
         --En : check expiry card
         BEGIN
            SELECT ccs_card_status
              INTO v_startercard_appl_status
              FROM cms_cardissuance_status
             WHERE ccs_inst_code = p_inst_code
               AND ccs_pan_code = v_hash_starter_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '49';
               v_errmsg := 'Application status not found for starter card';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '89';
               v_errmsg :=
                     'While fetching application status '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;

         IF v_startercard_appl_status <> '15'
         THEN
            v_resp_cde := '49';
            v_errmsg := 'Starter Card Not In Shipped State';
            RAISE exp_reject_record;
         END IF;

         --Sn check card stat
         BEGIN
            SELECT COUNT (1)
              INTO v_check_statcnt
              FROM pcms_valid_cardstat
             WHERE pvc_inst_code = p_inst_code
               AND pvc_card_stat = v_cap_card_stat
               AND pvc_tran_code = p_txn_code
               AND pvc_delivery_channel = p_delivery_channel;

            IF v_check_statcnt = 0
            THEN
               v_resp_cde := '10'; -- response id changed from 49 to 10 on 09-Oct-2012
               v_errmsg := 'Invalid Card Status';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record  -- added onn 19-JUL-12
            THEN
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_errmsg :=
                     'Problem while selecting card stat '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      --En check card stat
      END IF;

      BEGIN
         SELECT cap_pan_code
           INTO v_gpr_pan_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code
            AND cap_cust_code = v_cap_cust_code
            AND cap_acct_no = v_cap_acct_no
            AND NVL (cap_startercard_flag, 'N') = 'N'
            AND cap_card_stat <> '9';

         v_resp_cde := '49';
         v_errmsg := 'GPR card already available to this customer';
         RAISE exp_reject_record;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN TOO_MANY_ROWS
         THEN
            v_resp_cde := '49';
            v_errmsg :=
                    'More than 1 GPR card already avalibale to this customer';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'While checking for GPR card exists or not '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         -- added by sagar 0n 21-May-2012 to fetch product catg for GPR card
         SELECT cpc_startergpr_crdtype
           INTO v_gprcard_type
           FROM cms_prod_cattype
          WHERE cpc_inst_code = p_inst_code
            AND cpc_prod_code = v_cap_prod_code
            AND cpc_card_type = v_cap_card_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '49';
            v_errmsg :=
                  'product '
               || v_cap_prod_code
               || ' and product catg '
               || v_cap_card_type
               || ' not found in master';
            RAISE exp_reject_record;
      END; -- added by sagar 0n 21-May-2012 to fetch product catg for GPR card
      
      
       BEGIN
       
          SELECT nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn)
            INTO v_ssn
            FROM cms_cust_mast
           WHERE ccm_inst_code = p_inst_code AND ccm_cust_code = v_cap_cust_code;

          sp_check_ssn_threshold (p_inst_code,
                                  v_ssn,
                                  v_cap_prod_code,
                                  v_cap_card_type,
                                  'SG',               --Starter To GPR flag
                                  v_ssn_crddtls,
                                  v_resp_cde,
                                  v_errmsg
                                 );

          IF v_errmsg <> 'OK'
          THEN             
             v_resp_cde := '158'; --response id changed from 157 to 158 on 19-Feb-2013 
             RAISE exp_reject_record;
             
          END IF;
          
       EXCEPTION
          WHEN exp_reject_record
          THEN
             RAISE;
          WHEN OTHERS
          THEN
             v_resp_cde := '21';
             v_errmsg := 'Error from SSN check- ' || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
       END;      
      
      

      BEGIN
         sp_order_reissuepan_cms (p_inst_code,
                                  p_starter_card,
                                  v_cap_prod_code,
                                  v_gprcard_type,
                                  -- changed by sagar on 21May2012 as per requirement given by tejas
                                   --v_cap_card_type,
                                  v_cap_disp_name,
                                  p_ins_user,
                                  new_gpr_card_no,
                                  v_errmsg
                                 );

         IF v_errmsg != 'OK'
         THEN
            v_errmsg := 'From reissue pan generation process-- ' || v_errmsg;
            v_resp_cde := '21';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                'while calling reissue pan generation process-- ' || v_errmsg;
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

     --Sn Commented by Pankaj S. on 27_Feb_2013 for DFCHOST-249 
     /*BEGIN
         SELECT cpm_proxy_length, cpm_program_id
           INTO v_proxylength, v_programid
           FROM cms_prod_cattype, cms_prod_mast
          WHERE cpc_inst_code = p_inst_code
            AND cpc_inst_code = cpm_inst_code
            AND cpc_prod_code = v_cap_prod_code
            AND cpc_card_type = v_gprcard_type
            AND cpm_prod_code = cpc_prod_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '49';
            v_errmsg :=
                  'proxy length not defined for product code '
               || v_cap_prod_code
               || 'card type '
               || v_gprcard_type;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while selecting proxy length from master'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      IF v_proxylength = '12'
      THEN
         BEGIN
            v_getseqno :=
                  'SELECT CPI_SEQUENCE_NO FROM CMS_PROGRAM_ID_CNT WHERE CPI_PROGRAM_ID='
               || CHR (39)
               || v_programid
               || CHR (39)
               || 'AND CPI_INST_CODE='
               || p_inst_code;

            EXECUTE IMMEDIATE v_getseqno
                         INTO v_seqno;

            v_proxy_number :=
               fn_proxy_no (SUBSTR (new_gpr_card_no, 1, 6),
                            LPAD (v_gprcard_type, 2, 0),
                            v_programid,
                            NVL (v_seqno, 0),
                            p_inst_code,
                            p_ins_user
                           );

            IF v_proxy_number = '0'
            THEN
               v_resp_cde := '21';
               v_errmsg :=
                  'Error while gen Proxy number ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_errmsg :=
                      'Error while Proxy number ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      ELSIF v_proxylength = '9'
      THEN
         SELECT LPAD (seq_proxy_no.NEXTVAL, 9, 0)
           INTO v_proxy_number
           FROM DUAL;
      ELSE
         v_resp_cde := '21';
         v_errmsg := 'Invalid length for proxy number generation';
         RAISE exp_reject_record;
      END IF;

      BEGIN
         UPDATE cms_appl_pan
            SET cap_proxy_number = v_proxy_number
          WHERE cap_inst_code = p_inst_code
            AND cap_pan_code = gethash (new_gpr_card_no);

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            v_errmsg := 'proxy number not updated in master';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'error while proxy number updation in master'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;*/
      --En Commented by Pankaj S. on 27_Feb_2013 for DFCHOST-249

      BEGIN
         -- Added by sagar on 22-Jun-2012 to handle new fee related changes
         sp_authorize_txn_cms_auth (p_inst_code,
                                    p_msg_type,
                                    p_rrn,
                                    p_delivery_channel,
                                    NULL,                          --P_TERM_ID
                                    p_txn_code,
                                    p_txn_mode,
                                    p_tran_date,
                                    p_tran_time,
                                    p_starter_card,
                                    p_inst_code,
                                    0,                                   --AMT
                                    p_merchant_name,
                                    p_merchant_city,
                                    NULL,                         --P_MCC_CODE
                                    p_curr_code,
                                    NULL,                          --P_PROD_ID
                                    NULL,                          --P_CATG_ID
                                    NULL,                          --P_TIP_AMT
                                    NULL,                       --P_TO_ACCT_NO
                                    NULL,                      --P_ATMNAME_LOC
                                    NULL,                  --P_MCCCODE_GROUPID
                                    NULL,                 --P_CURRCODE_GROUPID
                                    NULL,                --P_TRANSCODE_GROUPID
                                    NULL,                            --P_RULES
                                    NULL,                     --P_PREAUTH_DATE
                                    p_consodium_code,       --P_CONSODIUM_CODE
                                    p_partner_code,           --P_PARTNER_CODE
                                    v_cap_expry_date,           --P_EXPRY_DATE
                                    p_stan,
                                    p_mbr_numb,
                                    p_rvsl_code,
                                    NULL,                --P_CURR_CONVERT_AMNT
                                    v_auth_id,
                                    p_resp_code,
                                    v_errmsg,
                                    V_Capture_Date,
                                   v_fee_flagcheck
                                   );

         IF p_resp_code <> '00' AND v_errmsg <> 'OK'
         THEN
            v_resp_cde := '21';
            v_errmsg := 'Error from auth process' || v_errmsg;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      /*
      BEGIN

         SELECT cip_param_value
           INTO v_servicetax_percent
           FROM cms_inst_param
          WHERE cip_param_key = 'SERVICETAX' and cip_inst_code = p_inst_code;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           v_resp_cde := '21';
           v_errmsg  := 'Service Tax is  not defined in the system';
           raise exp_reject_record;
         WHEN OTHERS THEN
           v_resp_cde := '21';
           v_errmsg  := 'Error while selecting service tax from system ';
           RAISE EXP_REJECT_RECORD;
      END;

      BEGIN

         SELECT cip_param_value
           INTO v_cess_percent
           FROM cms_inst_param
          WHERE cip_param_key = 'CESS' and cip_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           v_resp_cde := '21';
           v_errmsg  := 'Cess is not defined in the system';
           raise exp_reject_record;
         WHEN OTHERS THEN
           v_resp_cde := '21';
           v_errmsg  := 'Error while selecting cess from system ';
           raise exp_reject_record;
      END;


      BEGIN
         V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                            SUBSTR(TRIM(P_TRAN_TIME), 1, 10),
                            'yyyymmdd hh24:mi:ss');
        EXCEPTION
         WHEN OTHERS THEN
           v_resp_cde := '89';
           v_errmsg  := 'Problem while converting transaction time ' ||substr(sqlerrm, 1, 200);
           raise exp_reject_record;
      END;

        BEGIN

         SP_TRAN_FEES_CMSAUTH(p_inst_code,
                              p_starter_card,
                              p_delivery_channel,
                              v_txn_type,
                              p_txn_mode,
                              p_txn_code,
                              p_curr_code,
                              p_consodium_code,
                              p_partner_code,
                              '0',           -- Transaction amount hardcoded zero since its a nonfinancial transaction
                              v_tran_date,
                              v_fee_amt,
                              v_errmsg,
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
                              v_cess_dracct_no
                          );

          if v_errmsg <> 'OK' then
               v_resp_cde := '21';
               v_errmsg  := v_errmsg;
               raise exp_reject_record;
          end if;
        exception
         when exp_reject_record then
           raise;
         when others then
           v_resp_cde := '21';
           v_errmsg  := 'Error from fee calc process ' ||
                      substr(sqlerrm, 1, 200);
           raise exp_reject_record;

        END;

       BEGIN
         sp_calculate_waiver(p_inst_code,
                             p_starter_card,
                             '000',
                             v_cap_prod_code,
                             v_cap_card_type,
                             v_fee_code,
                             v_waiv_percnt,
                             v_errmsg
                             );

         IF v_errmsg <> 'OK' THEN
           v_resp_cde := '21';
           v_errmsg  := v_errmsg;
           RAISE EXP_REJECT_RECORD;
         END IF;
        EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
           RAISE;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERRMSG  := 'Error from waiver calc process ' ||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
       END;

        v_log_actual_fee := v_fee_amt;
        v_fee_amt        := round(v_fee_amt -((v_fee_amt * v_waiv_percnt) / 100),2);
        v_log_waiver_amt := v_log_actual_fee - v_fee_amt;

       if v_st_calc_flag = 1
        then
         v_servicetax_amount := (v_fee_amt * v_servicetax_percent) / 100;
        else
         v_servicetax_amount := 0;
       end if;

        if v_cess_calc_flag = 1 then
         v_cess_amount := (v_servicetax_amount * v_cess_percent) / 100;
        else
         v_cess_amount := 0;
        end if;

        v_total_fee := round(v_fee_amt + v_servicetax_amount + v_cess_amount, 2);

        if  v_acct_bal < v_total_fee
        then
            v_resp_cde :='15';
            v_errmsg := 'Insufficient balance';
        else
           v_upd_amt        := v_acct_bal   - v_total_fee;
           v_upd_ledger_amt := v_ledger_bal - v_total_fee;

        end if;


        BEGIN
         SP_UPD_TRANSACTION_ACCNT_AUTH(  p_inst_code,
                                         v_tran_date,
                                         v_cap_prod_code,
                                         v_cap_card_type,
                                         '0',           -- Transaction amount hardcoded since its a nonfinancial transaction
                                         v_cfm_func_code,
                                         p_txn_code,
                                         v_dr_cr_flag,
                                         p_rrn,
                                         null,           -- Terminal id
                                         p_delivery_channel,
                                         p_txn_mode,
                                         p_starter_card,
                                         v_fee_code,
                                         v_fee_amt,
                                         v_fee_cracct_no,
                                         v_fee_dracct_no,
                                         v_st_calc_flag,
                                         v_cess_calc_flag,
                                         v_servicetax_amount,
                                         v_st_cracct_no,
                                         v_st_dracct_no,
                                         v_cess_amount,
                                         v_cess_cracct_no,
                                         v_cess_dracct_no,
                                         v_cap_acct_no,
                                         v_hold_amount,
                                         p_msg_type,
                                         v_resp_cde,
                                         v_errmsg
                                         );

         if (v_resp_cde <> '1' or v_errmsg <> 'OK') then
           v_resp_cde := '21';
           raise exp_reject_record;
         end if;
        exception
         when exp_reject_record then
           raise;
         when others then
           v_resp_cde := '21';
           v_errmsg  := 'Error from currency conversion ' ||
                      substr(sqlerrm, 1, 200);
           raise exp_reject_record;
        end;

        IF v_total_fee <> 0
        THEN

             BEGIN
               SELECT DECODE(V_DR_CR_FLAG,
                            'DR',
                            V_ACCT_BAL - '0',
                            'CR',
                            V_ACCT_BAL + '0',
                            'NA',
                            V_ACCT_BAL
                            )
                INTO V_FEE_OPENING_BAL
                FROM DUAL;
             EXCEPTION
               WHEN OTHERS THEN
                v_resp_cde := '12';
                v_errmsg  := 'Error while selecting balance for dr/cr flag ' ||
                            p_starter_card;
                RAISE EXP_REJECT_RECORD;
             END;

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
                 CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                 CSL_INS_USER,
                 CSL_INS_DATE
                 )
               VALUES
                (
                 v_hash_starter_pan,
                 V_FEE_OPENING_BAL,
                 V_TOTAL_FEE,
                 'DR',
                 V_TRAN_DATE,
                 V_FEE_OPENING_BAL - V_TOTAL_FEE,
                 'Fee debited for ' || p_remark,
                 P_INST_CODE,
                 v_encr_starter_pan,
                 P_RRN,
                 V_AUTH_ID,
                 P_TRAN_DATE,
                 P_TRAN_TIME,
                 'Y',
                 P_DELIVERY_CHANNEL,
                 P_TXN_CODE,
                 v_cap_acct_no,
                 p_ins_user,
                 sysdate
                 );
             EXCEPTION
               WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERRMSG  := 'Problem while inserting into statement log for tran fee ' ||
                            SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
             END;
        END IF;

      */
      IF p_reason_code IS NULL
      THEN
         v_reason := 'Upgrade to personalised card';
      ELSE
         v_resoncode := p_reason_code;

         BEGIN
            --added by sagar on 19-Jun-2012 for reasioin desc logging in txnlog table
            SELECT csr_reasondesc
              INTO v_reason
              FROM cms_spprt_reasons
             WHERE csr_spprt_rsncode = v_resoncode
               AND csr_inst_code = p_inst_code;
         --    AND ROWNUM < 2;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';                                    --added
               v_errmsg :=
                     'reason code not found in master for reason code '
                  || v_resoncode;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';                                    --added
               v_errmsg :=
                     'Error while selecting reason description'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      BEGIN
         INSERT INTO cms_pan_spprt
                     (cps_inst_code, cps_pan_code, cps_mbr_numb,
                      cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                      cps_func_remark, cps_ins_user, cps_lupd_user,
                      cps_cmd_mode, cps_pan_code_encr
                     )
              VALUES (p_inst_code, v_hash_starter_pan, p_mbr_numb,
                      v_cap_prod_catg, 'REISSUE', p_reason_code,
                      p_remark, p_ins_user, p_ins_user,
                      0, v_encr_starter_pan
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while inserting records into card support master'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cap_mbr_numb
           INTO new_gpr_mbr_numb
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code
            AND cap_pan_code = gethash (new_gpr_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'while fetching mbr number for GPR card '
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      BEGIN
         INSERT INTO cms_htlst_reisu
                     (chr_inst_code, chr_pan_code, chr_mbr_numb,
                      chr_new_pan, chr_new_mbr, chr_reisu_cause,
                      chr_ins_user, chr_lupd_user, chr_pan_code_encr,
                      chr_new_pan_encr
                     )
              VALUES (p_inst_code, v_hash_starter_pan, p_mbr_numb,
                      gethash (new_gpr_card_no), new_gpr_mbr_numb, 'R',
                      p_ins_user, p_ins_user, v_encr_starter_pan,
                      fn_emaps_main (new_gpr_card_no)
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while creating  reissuue record '
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;


     BEGIN
       INSERT INTO CMS_CARDISSUANCE_STATUS
        (CCS_INST_CODE,
         CCS_PAN_CODE,
         CCS_CARD_STATUS,
         CCS_INS_USER,
         CCS_INS_DATE,
         CCS_PAN_CODE_ENCR,
         CCS_LUPD_USER,--Added for MVHOST-1196
         CCS_LUPD_DATE,--Added for MVHOST-1196
         CCS_APPL_CODE)--Added for MVHOST-1196
       VALUES
        (P_INST_CODE,
         gethash (new_gpr_card_no),
         '2',
         p_ins_user,
         SYSDATE,
         fn_emaps_main (new_gpr_card_no),
         p_ins_user,--Added for MVHOST-1196
         SYSDATE,--Added for MVHOST-1196
         v_appl_code--Added for MVHOST-1196
        );
     EXCEPTION
       WHEN OTHERS THEN
        V_ERRMSG  := 'Error while Inserting into card issuance status table ' ||
                    SUBSTR(SQLERRM, 1, 100);
        v_resp_cde := '21';
        RAISE exp_reject_record;
     END;
     
        BEGIN 
          Insert Into Cms_Card_Excpfee
                            (Cce_Inst_Code, 
                             cce_Pan_Code,
                             cce_Ins_Date, 
                             cce_Ins_User,
                             cce_Lupd_User,
                             Cce_Lupd_Date,
                             cce_Fee_Plan, 
                             Cce_Flow_Source,
                             Cce_Valid_From, 
                             Cce_Valid_To,
                             Cce_Pan_Code_Encr,
                             Cce_Mbr_Numb,
                             Cce_St_Calc_Flag,
                             Cce_Cess_Calc_Flag,
                             cce_drgl_catg)
                             (Select Cce_Inst_Code, 
                              gethash(New_Gpr_Card_No),
                              SYSDATE,
                              1,
                              1,
                              SYSDATE,
                              Cce_Fee_Plan, 
                              Cce_Flow_Source,
                              Cce_Valid_From, 
                              Cce_Valid_To,
                              Fn_Emaps_Main(New_Gpr_Card_No),
                              Cce_Mbr_Numb,
                              Cce_St_Calc_Flag,
                              cce_cess_calc_flag,
                              cce_drgl_catg
                FROM CMS_CARD_EXCPFEE 
               WHERE cce_pan_code = v_hash_starter_pan
                 AND cce_inst_code = p_inst_code
                 And (   (    Cce_Valid_To Is Not Null
                          AND (trunc(sysdate) BETWEEN cce_valid_from AND cce_valid_to
                              )
                         )   OR (cce_valid_to IS NULL AND trunc(SYSDATE) >= cce_valid_from)
                     ));
                  Exception  
                      WHEN OTHERS THEN
                          V_ERRMSG  := 'Error while Inserting into cms_card_excpfee table ' ||
                                      SUBSTR(SQLERRM, 1, 100);
                          v_resp_cde := '21';
                          Raise Exp_Reject_Record;
            END;
                
      
     
      --Start Added for MVHOST-1196 (Melissa)
          BEGIN
              SP_LOGAVQSTATUS(
              p_inst_code,
              P_DELIVERY_CHANNEL,
              new_gpr_card_no,
              v_cap_prod_code,
              v_cap_cust_code,
              v_resp_cde,
              V_ERRMSG,
              v_cap_card_type
              );
            IF V_ERRMSG != 'OK' THEN
               V_ERRMSG  := 'Exception while calling LOGAVQSTATUS-- ' || V_ERRMSG;
               v_resp_cde := '21';
              RAISE EXP_REJECT_RECORD;         
             END IF;
        EXCEPTION WHEN EXP_REJECT_RECORD
        THEN  RAISE;
        WHEN OTHERS THEN
           V_ERRMSG  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
           v_resp_cde := '21';
           RAISE EXP_REJECT_RECORD;
        END; 
 --End Added for MVHOST-1196 (Melissa)
     BEGIN
       INSERT INTO CMS_SMSANDEMAIL_ALERT
        (CSA_INST_CODE,
         CSA_PAN_CODE,
         CSA_PAN_CODE_ENCR,
         CSA_CELLPHONECARRIER,
         CSA_LOADORCREDIT_FLAG,
         CSA_LOWBAL_FLAG,
         CSA_LOWBAL_AMT,
         CSA_NEGBAL_FLAG,
         CSA_HIGHAUTHAMT_FLAG,
         CSA_HIGHAUTHAMT,
         CSA_DAILYBAL_FLAG,
         CSA_BEGIN_TIME,
         CSA_END_TIME,
         CSA_INSUFF_FLAG,
         CSA_INCORRPIN_FLAG,
         CSA_FAST50_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
         CSA_FEDTAX_REFUND_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
         CSA_DEPPENDING_FLAG, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
         CSA_DEPACCEPTED_FLAG, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
         CSA_DEPREJECTED_FLAG, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
         CSA_INS_USER,
         CSA_INS_DATE,
         CSA_LUPD_USER,
         CSA_LUPD_DATE)
        (SELECT P_INST_CODE,
               gethash (new_gpr_card_no),
               fn_emaps_main (new_gpr_card_no),
               NVL(CSA_CELLPHONECARRIER, 0),
               CSA_LOADORCREDIT_FLAG,
               CSA_LOWBAL_FLAG,
               NVL(CSA_LOWBAL_AMT, 0),
               CSA_NEGBAL_FLAG,
               CSA_HIGHAUTHAMT_FLAG,
               NVL(CSA_HIGHAUTHAMT, 0),
               CSA_DAILYBAL_FLAG,
               NVL(CSA_BEGIN_TIME, 0),
               NVL(CSA_END_TIME, 0),
               CSA_INSUFF_FLAG,
               CSA_INCORRPIN_FLAG,
               CSA_FAST50_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
               CSA_FEDTAX_REFUND_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
               CSA_DEPPENDING_FLAG, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
               CSA_DEPACCEPTED_FLAG, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
               CSA_DEPREJECTED_FLAG, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
               p_ins_user,
               SYSDATE,
               p_ins_user,
               SYSDATE
           FROM CMS_SMSANDEMAIL_ALERT
          WHERE CSA_INST_CODE = P_INST_CODE AND CSA_PAN_CODE = v_hash_starter_pan);
          
       IF SQL%ROWCOUNT != 1 THEN
        V_ERRMSG  := 'Error while Entering sms email alert detail ';
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       END IF;
       
     EXCEPTION 
	  WHEN DUP_VAL_ON_INDEX THEN NULL;
	 when EXP_REJECT_RECORD
     then 
         raise;
     
       WHEN OTHERS THEN
        V_ERRMSG  := 'Error while Entering sms email alert detail ' ||
                    SUBSTR(SQLERRM, 1, 100);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
        
     END;


      v_resp_cde := 1;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_resp_cde;

         p_resp_msg := v_errmsg;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 100);
            p_resp_code := '89';
            ROLLBACK;
            RETURN;
      END;

      BEGIN
IF (v_Retdate>v_Retperiod)
    THEN
         --added by sagar on 20-Jun-2012 for reamrk logging in txnlog table
         UPDATE transactionlog
            SET remark = p_remark,
                reason = v_reason,
                ipaddress = p_ipaddress,     --added by amit on 06-Oct-2012 to log tranactionlog table
                add_lupd_user = p_ins_user  --added by amit on 06-Oct-2012 to log lupd user.
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_starter_pan
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND business_time = p_tran_time
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code;
     ELSE
         UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
            SET remark = p_remark,
                reason = v_reason,
                ipaddress = p_ipaddress,     --added by amit on 06-Oct-2012 to log tranactionlog table
                add_lupd_user = p_ins_user  --added by amit on 06-Oct-2012 to log lupd user.
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_starter_pan
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND business_time = p_tran_time
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code;
      END IF;


         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                     'Txn not updated in transactiolog for remark and reason';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while updating into transactiolog '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      /*
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
                        ctd_cust_acct_number, ctd_inst_code,
                        ctd_lupd_date,ctd_lupd_user,ctd_ins_date,ctd_ins_user
                       )
                VALUES (p_delivery_channel, p_txn_code, NULL,
                        p_txn_mode, p_tran_date, p_tran_time,
                        v_hash_starter_pan, NULL, p_curr_code,
                        '0.00', V_TOTAL_FEE,
                        v_log_waiver_amt, v_servicetax_amount,
                        v_cess_amount, NULL, NULL,
                        'Y', v_errmsg, p_rrn,
                        p_stan,
                        v_encr_starter_pan, p_msg_type,
                        v_cap_acct_no, p_inst_code,
                        sysdate,p_ins_user,sysdate,p_ins_user
                       );

           p_resp_msg := v_errmsg;
        EXCEPTION
           WHEN OTHERS
           THEN
              p_resp_code := '89';
              p_resp_msg :=
                    'Problem while inserting data into transaction_log_dtl'
                 || SUBSTR (SQLERRM, 1, 300);
              ROLLBACK;
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
                        currencycode, productid, categoryid,
                        trans_desc,
                        amount,
                        system_trace_audit_no, instcode, cr_dr_flag,
                        customer_card_no_encr, proxy_number,
                        customer_acct_no, acct_balance, ledger_balance,
                        response_id, error_msg,tranfee_amt,
                        tranfee_cr_acctno,
                        tranfee_dr_acctno,
                        tran_st_calc_flag,
                        tran_cess_calc_flag,
                        tran_st_cr_acctno,
                        tran_st_dr_acctno,
                        tran_cess_cr_acctno,
                        tran_cess_dr_acctno,
                        add_lupd_date,add_lupd_user,add_ins_date,add_ins_user
                       )
                VALUES (p_msg_type, p_rrn, p_delivery_channel,
                        TO_DATE (p_tran_date || ' ' || p_tran_time,'yyyymmdd hh24miss'),
                        p_txn_code, NULL, p_txn_mode,
                        DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                        p_tran_date, p_tran_time, v_hash_starter_pan,
                        TRIM (TO_CHAR (v_total_fee, '99999999999999990.99')),
                        p_curr_code, v_cap_prod_code, v_cap_card_type,
                        p_remark,
                        TRIM (TO_CHAR (0, '999999999999999990.99')),
                        p_stan, p_inst_code, 'NA',
                        v_encr_starter_pan, v_cap_proxunumber,
                        v_cap_acct_no, v_upd_amt, v_upd_ledger_amt,
                        v_resp_cde, v_errmsg,v_total_fee,
                        v_fee_cracct_no,
                        v_fee_dracct_no,
                        decode(v_st_calc_flag,1,'Y','N'),
                        decode(v_cess_calc_flag,1,'Y','N'),
                        v_st_cracct_no,
                        v_st_dracct_no,
                        v_cess_cracct_no,
                        v_cess_dracct_no,
                        sysdate,p_ins_user,sysdate,p_ins_user
                       );

           p_resp_msg := v_errmsg;
        EXCEPTION
           WHEN OTHERS
           THEN
              ROLLBACK;
              p_resp_code := '89';
              p_resp_msg :=
                    'Problem while inserting data into transactionlog '
                 || SUBSTR (SQLERRM, 1, 300);
              RETURN;
        END;
      */
      IF p_resp_code = '00'
      THEN
         BEGIN
            v_hash_new_gpr_card := gethash (new_gpr_card_no);

            EXECUTE IMMEDIATE v_colm_qury
                         INTO v_new_value
                        USING p_inst_code, v_hash_new_gpr_card;

            v_new_value := 'NEWGPRCARD DETAILS - ' || v_new_value;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting values of starter card -- '
                  || '---'
                  || SUBSTR (SQLERRM, 1, 100);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

-- SN : ADDED BY Ganesh on 18-JUL-12
         BEGIN
            SELECT cap_acct_no
              INTO v_spnd_acctno
              FROM cms_appl_pan
             WHERE cap_pan_code = v_hash_starter_pan
               AND cap_inst_code = p_inst_code
               AND cap_mbr_numb = p_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';
               v_errmsg :=
                  'Spending Account Number Not Found For the Card in PAN Master ';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_errmsg :=
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
                WHERE ccd_inst_code = ccd_inst_code
                  AND ccd_call_id = p_call_id
                  AND ccd_pan_code = v_hash_starter_pan;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                             'record is not present in cms_calllog_details  ';
                  v_resp_cde := '49';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting frmo cms_calllog_details '
                     || SUBSTR (SQLERRM, 1, 100);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
            END;

            INSERT INTO cms_calllog_details
                        (ccd_inst_code, ccd_call_id, ccd_pan_code,
                         ccd_call_seq, ccd_rrn, ccd_devl_chnl, ccd_txn_code,
                         ccd_tran_date, ccd_tran_time, ccd_tbl_names,
                         ccd_colm_name, ccd_new_value, ccd_comments,
                         ccd_ins_user, ccd_ins_date, ccd_lupd_user,
                         ccd_lupd_date, ccd_acct_no
                        -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                        )
                 VALUES (p_inst_code, p_call_id, v_hash_starter_pan,
                         v_call_seq, p_rrn, p_delivery_channel, p_txn_code,
                         p_tran_date, p_tran_time, v_table_list,
                         v_colm_list, v_new_value, p_remark,
                         p_ins_user, SYSDATE, p_ins_user,
                         SYSDATE, v_spnd_acctno
                        -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
                        );
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_errmsg :=
                     ' Error while inserting into cms_calllog_details '
                  || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_reject_record;
         END;
      END IF;
---------------------------------------------------------------------------------------------------------------------------------------------
   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK;

         BEGIN
         
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;

            p_resp_msg := v_errmsg;
            
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master1 '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '89';
               ROLLBACK;
               RETURN;
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
                         ctd_cust_acct_number, ctd_inst_code, ctd_lupd_date,
                         ctd_lupd_user, ctd_ins_date, ctd_ins_user
                        )
                 VALUES (p_delivery_channel, p_txn_code, NULL,
                         p_txn_mode, p_tran_date, p_tran_time,
                         v_hash_starter_pan, NULL, p_curr_code,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_errmsg, p_rrn,
                         p_stan,
                         v_encr_starter_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code, SYSDATE,
                         p_ins_user, SYSDATE, p_ins_user
                        );

            p_resp_msg := v_errmsg;
            
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction_log_dtl1'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal,
                   cam_type_code --added by Pankaj S. for 10871
              INTO v_acct_bal, v_ledger_bal,
                   v_acct_type --added by Pankaj S. for 10871
              FROM cms_acct_mast
             WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_bal := 0;
               v_ledger_bal := 0;
         END;
         
          --Sn added by Pankaj S. for 10871
          IF v_cap_prod_code is NULL THEN
          BEGIN  
            SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
              INTO v_cap_prod_code, v_cap_card_type, v_cap_card_stat,v_cap_acct_no
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code
               AND cap_pan_code = gethash (p_starter_card);
          EXCEPTION
             WHEN OTHERS THEN
                NULL;
          END;
          END IF;
          --En added by Pankaj S. for 10871 

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status, response_code,
                         business_date, business_time, customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, tranfee_amt, add_lupd_date,
                         add_lupd_user, add_ins_date, add_ins_user,
                         remark,     --added by amit on 06-Oct-2012 to log remark in transactionlog table
                         ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog table
                         reason,      --added by amit on 06-Oct-2012 to log reason in transactionlog table
                         ssn_fail_dtls,  -- added on 12-Feb-2013
                         --Sn added by Pankaj S. for 10871
                         cardstatus,
                         acct_type,
                         time_stamp
                         --En added by Pankaj S. for 10871
                        )
                 VALUES (p_msg_type, p_rrn, p_delivery_channel,
                         TO_DATE (p_tran_date || ' ' || p_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         p_txn_code, NULL, p_txn_mode,
                         DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                         p_tran_date, p_tran_time, v_hash_starter_pan,
                         TRIM (TO_CHAR (nvl(v_total_fee,0), '99999999999999990.99')), --Modified for 10871
                         p_curr_code, v_cap_prod_code, v_cap_card_type,
                         p_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         p_stan, p_inst_code, 'NA',
                         v_encr_starter_pan, v_cap_proxunumber,
                         v_cap_acct_no, v_acct_bal, v_ledger_bal,
                         v_resp_cde, v_errmsg, nvl(v_total_fee,0),--Modified for 10871
                          SYSDATE,
                         p_ins_user, SYSDATE, p_ins_user,
                         p_remark,     --added by amit on 06-Oct-2012 to log remark in transactionlog table
                         p_ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog table
                         v_reason,      --added by amit on 06-Oct-2012 to log reason in transactionlog table
                         v_ssn_crddtls,  -- added on 12-Feb-2013
                         --Sn added by Pankaj S. for 10871
                         v_cap_card_stat,
                         v_acct_type,
                         systimestamp
                         --En added by Pankaj S. for 10871
                        );

            p_resp_msg := rtrim(v_errmsg||'|'||v_ssn_crddtls,'|');
            
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transactionlog1 '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;
      WHEN OTHERS
      THEN
         ROLLBACK;
         v_errmsg := 'Inside when others '||substr(sqlerrm,1,100);

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master1 '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '89';
               ROLLBACK;
               RETURN;
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
                         ctd_cust_acct_number, ctd_inst_code, ctd_lupd_date,
                         ctd_lupd_user, ctd_ins_date, ctd_ins_user
                        )
                 VALUES (p_delivery_channel, p_txn_code, NULL,
                         p_txn_mode, p_tran_date, p_tran_time,
                         v_hash_starter_pan, NULL, p_curr_code,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_errmsg, p_rrn,
                         p_stan,
                         v_encr_starter_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code, SYSDATE,
                         p_ins_user, SYSDATE, p_ins_user
                        );

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction_log_dtl2'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal,
                   cam_type_code --added by Pankaj S. for 10871
              INTO v_acct_bal, v_ledger_bal,
                   v_acct_type --added by Pankaj S. for 10871
              FROM cms_acct_mast
             WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_bal := 0;
               v_ledger_bal := 0;
         END;
         
         --Sn added by Pankaj S. for 10871
          IF v_cap_prod_code is NULL THEN
          BEGIN  
            SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
              INTO v_cap_prod_code, v_cap_card_type, v_cap_card_stat,v_cap_acct_no
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code
               AND cap_pan_code = gethash (p_starter_card);
          EXCEPTION
             WHEN OTHERS THEN
                NULL;
          END;
          END IF;
          --En added by Pankaj S. for 10871 
         
         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status, response_code,
                         business_date, business_time, customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, tranfee_amt, add_lupd_date,
                         add_lupd_user, add_ins_date, add_ins_user,
                         remark,     --added by amit on 06-Oct-2012 to log remark in transactionlog table
                         ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog table
                         reason,      --added by amit on 06-Oct-2012 to log reason in transactionlog table
                         ssn_fail_dtls,  -- added on 12-Feb-2013
                         --Sn added by Pankaj S. for 10871
                         cardstatus,
                         acct_type,
                         time_stamp
                         --En added by Pankaj S. for 10871
                        )
                 VALUES (p_msg_type, p_rrn, p_delivery_channel,
                         TO_DATE (p_tran_date || ' ' || p_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         p_txn_code, NULL, p_txn_mode,
                         DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                         p_tran_date, p_tran_time, v_hash_starter_pan,
                         TRIM (TO_CHAR (nvl(v_total_fee,0), '99999999999999990.99')), --Modified for 10871
                         p_curr_code, v_cap_prod_code, v_cap_card_type,
                         p_remark,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         p_stan, p_inst_code, 'NA',
                         v_encr_starter_pan, v_cap_proxunumber,
                         v_cap_acct_no, v_acct_bal, v_ledger_bal,
                         v_resp_cde, v_errmsg, nvl(v_total_fee,0), --modified for 10871
                          SYSDATE,
                         p_ins_user, SYSDATE, p_ins_user,
                         p_remark,     --added by amit on 06-Oct-2012 to log remark in transactionlog table
                         p_ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog table
                         v_reason,      --added by amit on 06-Oct-2012 to log reason in transactionlog table
                         v_ssn_crddtls,  -- added on 12-Feb-2013
                         --Sn added by Pankaj S. for 10871
                         v_cap_card_stat,
                         v_acct_type,
                         systimestamp
                         --En added by Pankaj S. for 10871
                        );

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transactionlog2 '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      p_resp_msg := 'Exception occured in main ' || SUBSTR (SQLERRM, 1, 100);
      p_resp_code := '89';
END;
/
show error