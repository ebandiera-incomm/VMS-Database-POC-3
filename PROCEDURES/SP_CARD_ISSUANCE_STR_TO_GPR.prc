create or replace
PROCEDURE        VMSCMS.SP_CARD_ISSUENCE_SRT_TO_GPR(
    p_inst_code           IN NUMBER,
    p_card_no             IN VARCHAR2,
    p_rrn                 IN VARCHAR2,
    p_business_date       IN VARCHAR2,
    p_business_time       IN VARCHAR2,
    p_delivery_channel    IN VARCHAR2,
    p_txn_code            IN VARCHAR2,
    p_idologyid           IN VARCHAR2,
    p_firstname           IN VARCHAR2,
    p_lastname            IN VARCHAR2,
    p_physical_add_one    IN VARCHAR2,
    p_physical_add_two    IN VARCHAR2,
    p_city                IN VARCHAR2,
    p_cntry_code          IN VARCHAR2,
    p_state_code          IN VARCHAR2,
    p_zipcode             IN VARCHAR2, --Mantisid-14041
    p_mobile_no           IN NUMBER,
    p_telnumber           IN VARCHAR2,
    p_email_add           IN VARCHAR2,
    p_dob                 IN VARCHAR2,
    p_mailing_add_one     IN VARCHAR2,
    p_mailing_add_two     IN VARCHAR2,
    p_mailing_city        IN VARCHAR2,
    p_mail_cntry_code     IN VARCHAR2,
    p_mail_state_code     IN VARCHAR2,
    p_mailing_zipcode     IN VARCHAR2,
    p_mothers_maiden_name IN VARCHAR2,
    p_rowID               IN NUMBER,
    p_id_number           IN VARCHAR2,
    p_document_verify     IN VARCHAR2,
    p_id_issuer           IN VARCHAR2,
    p_issuance_date       IN VARCHAR2,
    p_expiry_date         IN VARCHAR2,
    p_cci_a1              IN VARCHAR2,
    p_cci_a2              IN VARCHAR2,
    p_cci_a3              IN VARCHAR2,
    p_ipaddress           IN VARCHAR2,
    p_id_province         IN VARCHAR2,
    p_id_country          IN VARCHAR2,
    p_jurisdiction_of_tax_res IN VARCHAR2,
    P_RESP_CODE           OUT VARCHAR2,
    p_errmsg              OUT VARCHAR2,
    p_security_q1         OUT VARCHAR2,
    p_security_q2         OUT VARCHAR2,
    p_security_q3         OUT VARCHAR2,
    p_RespRowID           OUT VARCHAR2,
    p_switch_state_code   OUT VARCHAR2,-- Added for MVHOST -355 by Amudhan S
    p_mailing_state_code  OUT VARCHAR2,-- Added for MVHOST -355 by Amudhan S
    p_branch_code         OUT VARCHAR2,
    p_catg_sname          OUT VARCHAR2,
    p_startergpr_crdtype  OUT VARCHAR2,
    p_document_verify_res OUT VARCHAR2,
    p_cci_a4              IN VARCHAR2 DEFAULT NULL,
    p_security_q4         OUT VARCHAR2
  )
AS
  /**************************************************************************
  * Created Date    : 20_July_2013
  * Created By      : Arunprasath
  * Purpose         : To handle Application processing null verification for starter card
  * Reviewer        :  Dhiraj
  * Reviewed Date   : 19-aug-2013
  * Release Number  : RI0024.4_B0002

  * Modified Date   : 22_Aug_2013
  * Modified By     : Ramesh
  * Purpose         : Defect : 12097
  * Reviewer        : Dhiraj
  * Reviewed Date   : 09-Aug-2013
  * Build Number    : RI0024.4_B0003

  * Modified By      : Amudhan S
  * Modified Date    : 22-Aug-2013
  * Modified Reason  : To get the state code for sending the idiology Server -MVHOST-355
  * Reviewer         : Dhiraj
  * Reviewed Date    : 09-Aug-2013
  * Build Number     : RI0024.4_B0003

  * Modified Date    : 10_Sep_2013
  * Modified By      : Pankaj S.
  * Purpose          : SPIL target registration
  * Reviewer         : Dhiraj
  * Reviewed Date    : 11-sep-2013
  * Build Number     : RI0024.4_B0009

  * Modified By      : Siva Kumar M
  * Modified Date    : 11-Sept-2013
  * Modified Reason  : Defect id:12285
  * Reviewer         : Dhiraj
  * Reviewed Date    : 11-sep-2013
  * Build Number     : RI0024.4_B0010

  * Modified By      : Ramesh A
  * Modified Date    : 17-Sept-2013
  * Modified Reason  : Defect id:12310
  * Reviewer         : Dhiraj
  * Reviewed Date    :
  * Build Number     : RI0024.4_B0016

  * Modified By      : Pankaj S.
  * Modified Date    : 18-Sept-2013
  * Modified Reason  : Target registration changes
  * Reviewer         : Dhiraj
  * Reviewed Date    :
  * Build Number     : RI0024.4_B0016

  * Modified By      : Ramesh A.
  * Modified Date    : 30-Sept-2013
  * Modified Reason  : Manual Registraton failed for mantis id :12488
  * Reviewer         : Dhiraj
  * Reviewed Date    : 30-Sept-2013
  * Build Number     : RI0024.4.1_B0001

  * Modified By      : MageshKumar S.
  * Modified Date    : 10-Jan-2014
  * Modified Reason  : MVHOST-822 -  Incorrect responsecode logged during card Registration
  * Reviewer         : Dhiraj
  * Reviewed Date    :
  * Build Number     : RI0027_B0005

  * Modified Date    : 11-Feb-2013
  * Modified By      : Dhinakaran B
  * Modified for     : FSS-695
  * Modified reason  :
  * Reviewer         : Dhiraj
  * Reviewed Date    :
  * Release Number   : RI0027.1_B0001

  * Modified Date    : 31-Jan-2014
  * Modified By      : Sagar More
  * Modified for     : Spil 3.0 Changes
  * Modified reason  : 1) Verification Id generated for SPIL id_verification transaction
                       2) Insert in Transactionlog and transaction_log_dtl table uncommented for id verification transaction
                       3) Added duplicate target resgistration request check
  * Reviewer         : Dhiraj
  * Reviewed Date    : 01-Feb-2014
  * Release Number   : RI0027.1_B0001

  * Modified Date    : 20-Feb-2014
  * Modified By      : Sagar More
  * Modified for     : Mantis -13713
  * Modified reason  : 1) Starter card hash and encrypted value logged into
                        CCI_STARTER_CARD_NO and CCI_STARTER_CARD_NO_ENCR fields
  * Reviewer         : Dhiraj
  * Reviewed Date    : 20-Feb-2014
  * Release Number   : RI0027.1_B0004

  * Modified By      : Sagar
  * Modified Date    : 04-Mar-2014
  * Modified Reason  : Performance fix to compare cci_appl_code instead of cap_appl_code with CMS_CAF_INFO_ENTRY
                       (1.7.6.7 changes integarted)
  * Reviewer         : Dhiraj
  * Reviewed Date    : 06-Mar-2014
  * Build Number     : RI0027.1.1_B0001

  * Modified Date    : 02-APR-2014
  * Modified By      : Dhinakaran B
  * Modified for     : Zip code type changed from NUMBER to VARCHAR2 for  Spil(3.0) Changes (Mantisid-14041)
  * Modified reason  :
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 03-APR-2014
     * Build Number     : CMS3.5.1_RI0027.1.2_B0001

  * Modified By      : DINESH B.
  * Modified Date    : 10-Apr-2014
  * Modified Reason  : MOB-62 - Adding delievery channel.
  * Reviewer         : spankaj
  * Reviewed Date    : 15-April-2014
  * Build Number     : RI0027.2_B0005

  * Modified Date    : 20-May-2014
  * Modified By      : MageshKumar S
  * Modified for     : FSS-1624
  * Modified reason  : Integration changes 0f RI0027.1.4_B0001(Verification ID should not start with zero)
  * Reviewer         : spankaj
  * Reviewed Date    : 21-May-2014
  * Build Number     : RI0027.2.1_B0001

  * Modified Date    : 04-Jun-2014
  * Modified By      : Ramesh
  * Modified for     : defect id : 14569 -SPIL Target Registration transaction showing user defined exception instead of oracle error
  * Modified reason  : Integration changes 0f RI0027.1.7
  * Reviewer         : spankaj
  * Reviewed Date    : 12-Jun-2014
  * Build Number     : RI0027.2.1_B0003

  * Modified By      : DINESH B.
  * Modified Date    : 27-May-2014 -Need to remove the sale transaction check when doing startecard registration.
  * Modified Reason  : MVCSD-5125
  * Reviewer         : spankaj
  * Build Number     : RI0027.3_B0001

  * Modified By      : Ramesh A
  * Modified Date    : 18-SEP-2014
  * Modified Reason  : MVCSD-5381
  * Reviewer         :
  * Build Number     :RI0027.4_B0001

  * Modified Date    : 29-SEP-2014
  * Modified By      : Abdul Hameed M.A
  * Modified for     : FWR 70
  * Reviewer        :  spankaj
  * Release Number   : RI0027.4_B0002
  
  * Modified Date    : 04-Oct-2014
  * Modified By      : Sai Prasad
  * Modified for     : MVCSD-5381 - 0015800 
  * Reviewer         : Spankaj
  * Release Number   : RI0027.4_B0003
  
  * Modified Date    : 13-Jan-15
  * Modified By      : Siva Kumar 
  * Modified for     : MVCSD-5565
  * Reviewer         : 
  * Release Number   :
  
  * Modified by                  : MageshKumar S.
  * Modified Date                : 23-June-15
  * Modified For                 : MVCAN-77
  * Modified reason              : Canada account limit check
  * Reviewer                     : Spankaj
  * Build Number                 : VMSGPRHOSTCSD3.1_B0001
  
  * Modified by                  : MageshKumar S.
  * Modified Date                : 22-June-15
  * Modified For                 : IDSCAN CHANGES
  * Reviewer                     : Spankaj
  * Build Number                 : VMSGPRHOSTCSD3.2_B0002
  
   * Modified by           : Abdul Hameed M.A
      * Modified Date         : 07-Sep-15
      * Modified For          : FSS-3509 -1817
      * Reviewer              : Saravanankumar
      * Build Number          : VMSGPRHOSTCSD3.2  
      
  * Modified by                :MageshKumar S
  * Modified Date            : 06-Jan-16
  * Modified For             : VP-177
  * Reviewer                   : Saravanankumar/Spankaj
  * Build Number            : VMSGPRHOSTCSD3.3
  
       * Modified by       :Siva kumar 
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006
  
  ****************************************************************************/
  --p_errmsg                        VARCHAR2 (500) := 'OK';
  v_resp_id                         VARCHAR2 (10) := '1';
  v_hash_pan                        cms_appl_pan.cap_pan_code%TYPE;
  v_encr_pan                        cms_appl_pan.cap_pan_code_encr%TYPE;
  v_rrn_count                       NUMBER (5);
  v_cap_prod_code                   cms_appl_pan.cap_prod_code%TYPE;
  v_cap_firsttime_topup             cms_appl_pan.cap_firsttime_topup%TYPE;
  v_cap_cust_code                   cms_appl_pan.cap_cust_code%TYPE;
  v_cap_appl_code                   cms_appl_pan.cap_appl_code%TYPE;
  v_cap_acct_no                     cms_appl_pan.cap_acct_no%TYPE;
  v_cap_card_type                   cms_appl_pan.cap_card_type%TYPE;
  v_cap_expry_date                  cms_appl_pan.cap_expry_date%TYPE;
  v_cap_card_stat                   cms_appl_pan.cap_card_stat%TYPE;
  v_cap_startercard_flag            cms_appl_pan.cap_startercard_flag%TYPE;
  --v_cci_row_id                    cms_caf_info_entry.cci_row_id%TYPE;
  v_cci_ssnfail_dtls                cms_caf_info_entry.cci_ssnfail_dtls%TYPE;
  v_cci_idology_id                  cms_caf_info_entry.cci_idology_id%TYPE;
  v_cci_type_one                    cms_caf_info_entry.cci_type_one%TYPE;
  v_cci_type_two                    cms_caf_info_entry.cci_type_two%TYPE;
  v_cci_type_three                  cms_caf_info_entry.cci_type_three%TYPE;
  v_cci_upld_stat                   cms_caf_info_entry.cci_upld_stat%TYPE;
  v_cci_kyc_flag                    cms_caf_info_entry.cci_kyc_flag%TYPE;
  v_cci_ins_date                    cms_caf_info_entry.cci_ins_date%TYPE;
  v_cci_approved                    cms_caf_info_entry.cci_approved%TYPE;
  v_cust_id                         cms_cust_mast.ccm_cust_id%TYPE;
  v_min_age_kyc                     cms_prod_cattype.cpc_min_age_kyc%TYPE;
  v_startergpr_issue                cms_prod_cattype.cpc_startergpr_issue%TYPE;
  v_startergpr_crdtype              cms_prod_cattype.cpc_startergpr_crdtype%TYPE;
  v_catg_sname                      cms_cust_catg.ccc_catg_sname%TYPE;
  v_cust_catg                       cms_prod_ccc.cpc_cust_catg%TYPE;
  v_check_txn                       NUMBER (5);
  v_branch_code                     cms_bran_mast.cbm_bran_code%TYPE;
  v_curr_code                       gen_cntry_mast.gcm_curr_code%TYPE;
  v_state_code                      gen_state_mast.gsm_switch_state_code%TYPE;
  v_proxy_number                    cms_appl_pan.cap_proxy_number%type;
  v_card_dtl                        VARCHAR2 (4000);
  v_seq_val                         NUMBER (10);
  v_agecal                          NUMBER;
  v_acct_balance                    NUMBER;
  v_ledger_bal                      NUMBER;
  v_mail_gsm_switch_state_code      gen_state_mast.gsm_switch_state_code%TYPE;
  v_trans_desc                      cms_transaction_mast.ctm_tran_desc%type;
  exp_reject_record                 EXCEPTION;
  --v_card_type                     cms_appl_pan.cap_card_type%TYPE;
  v_document_verify                 cms_caf_info_entry.cci_document_verify%type;  -- added for review changes on 16/Aug/2013.
  v_dob                             date;
  v_verification_id              cms_transaction_log_dtl.ctd_auth_id%TYPE;
                                                -- Added for Spil_3.0 Changes
  v_dup_chk                      NUMBER (3);   -- Added for Spil_3.0 Changes
  v_cr_dr_flag                   cms_transaction_mast.ctm_credit_debit_flag%type; -- Added during spil_3.0 changes
  v_time_stamp                   timestamp(3);                                    -- Added during spil_3.0 changes
  v_type_code                    cms_acct_mast.cam_type_code%type;                -- Added during spil_3.0 changes
  v_cci_appl_code                   cms_caf_info_entry.cci_appl_code%TYPE;        -- Added for performance fix
  v_tran_date                   DATE; --Added for MVCSD-5381
  v_fee_plan_id                cms_card_excpfee.cce_fee_plan%TYPE; --Added for MVCSD-5381
  v_minorcard                  BOOLEAN DEFAULT FALSE;       --Added for MVCSD-5381
  v_kyc_flag                    cms_caf_info_entry.cci_kyc_flag%TYPE DEFAULT 'N'; --Added for MVCSD-5381
  v_fee_planid                NUMBER(3); --Added for MVCSD-5381(Review Comments)
  v_precheck_flag pcms_tranauth_param.ptp_param_value%TYPE;
  V_FLDOB_HASHKEY_ID         CMS_CUST_MAST.CCM_FLNAMEDOB_HASHKEY%TYPE;  --Added for MVCAN-77 OF 3.1 RELEASE
  v_id_province              gen_state_mast.gsm_switch_state_code%TYPE;
  v_id_country               gen_cntry_mast.gcm_alpha_cntry_code%TYPE;
  v_jurisdiction_of_tax_res  gen_cntry_mast.gcm_alpha_cntry_code%TYPE;
BEGIN
  p_errmsg := 'OK';
  --Sn Create hash PAN
  BEGIN
    v_hash_pan := gethash (p_card_no);
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  --En Create hash PAN
  --Sn Create encr PAN
  BEGIN
    v_encr_pan := fn_emaps_main (p_card_no);
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg :='Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  --En Create encr PAN
  BEGIN
    SELECT COUNT (1)
    INTO v_rrn_count
    FROM transactionlog
    WHERE rrn            = p_rrn
    AND business_date    = p_business_date
    AND delivery_channel = p_delivery_channel
    AND instcode         = p_inst_code;
    IF v_rrn_count       > 0 THEN
      v_resp_id         := '22';
      p_errmsg          := 'Duplicate RRN from the Terminal on ' || p_business_date;
      RAISE exp_reject_record;
    END IF;
  EXCEPTION
  WHEN exp_reject_record THEN
    RAISE;
  WHEN OTHERS THEN
    v_resp_id := '21';
    p_errmsg  := 'Error while checking for duplicate RRN-'|| SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  --En Duplicate RRN Check

  --Added for MVCSD-5381
   --Sn Transaction Time Check
   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_business_date), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_business_time), 1, 10),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_id := '32';                       -- Server Declined -220509
         p_errmsg :=
               'Problem while converting transaction Time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Transaction Time Check

  --Sn txn validation
  BEGIN
    SELECT ctm_tran_desc,ctm_credit_debit_flag -- DR_CR flag added during Spil_3.0 changes
    INTO v_trans_desc,v_cr_dr_flag
    FROM cms_transaction_mast
    WHERE ctm_inst_code      = p_inst_code
    AND ctm_tran_code        = p_txn_code
    AND ctm_delivery_channel = p_delivery_channel;
    IF v_trans_desc         IS NULL THEN
      v_resp_id             := '21';
      p_errmsg              := 'Transaction Not Defined';
      RAISE exp_reject_record;
    END IF;
  EXCEPTION
  WHEN exp_reject_record THEN
    RAISE;
  WHEN OTHERS THEN
    v_resp_id := '21';
    p_errmsg  := 'Error while checking transaction mast details-'|| SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  --En txn validation
   --Sn converting the variable p_document_verify . this block added on 16/Aug/2013
  BEGIN

   SELECT upper(p_document_verify)
   INTO  v_document_verify
   FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg  := 'Error while converting document_verify '|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
  END;
  --En converting the variable p_document_verify
  --Sn Added by Pankaj S. for Target registration
  IF p_delivery_channel='08' AND p_txn_code='30' THEN
  --Sn Get Card details
  BEGIN
    SELECT cap_prod_code,
      cap_firsttime_topup,
      cap_cust_code,
      cap_appl_code,
      cap_acct_no,
      cap_card_type,
      cap_expry_date,
      cap_card_stat,
      cap_startercard_flag,
      cap_proxy_number
    INTO v_cap_prod_code,
      v_cap_firsttime_topup,
      v_cap_cust_code,
      v_cap_appl_code,
      v_cap_acct_no,
      v_cap_card_type,
      v_cap_expry_date,
      v_cap_card_stat,
      v_cap_startercard_flag,
      v_proxy_number
    FROM cms_appl_pan
    WHERE cap_inst_code      = p_inst_code
    --AND cap_startercard_flag = 'Y'
    AND cap_pan_code         = v_hash_pan;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_resp_id := '6';
    p_errmsg  := 'Error while selecting card details' || SUBSTR (SQLERRM, 1, 200); -- Modified the message for review comments on 16/Aug/2013
    RAISE exp_reject_record;
  WHEN OTHERS THEN
    v_resp_id := '21';
    p_errmsg  := 'Error while selecting card details for ' || fn_mask (p_card_no, 'X', 7, 6) || '-' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  --En Get Card details
  ELSE
  --En Added by Pankaj S. for Target registration
  --Sn Get Card details
  BEGIN
    SELECT cap_prod_code,
      cap_firsttime_topup,
      cap_cust_code,
      cap_appl_code,
      cap_acct_no,
      cap_card_type,
      cap_expry_date,
      cap_card_stat,
      cap_startercard_flag,
      cap_proxy_number
    INTO v_cap_prod_code,
      v_cap_firsttime_topup,
      v_cap_cust_code,
      v_cap_appl_code,
      v_cap_acct_no,
      v_cap_card_type,
      v_cap_expry_date,
      v_cap_card_stat,
      v_cap_startercard_flag,
      v_proxy_number
    FROM cms_appl_pan
    WHERE cap_inst_code      = p_inst_code
   -- AND cap_startercard_flag = 'Y'
    AND cap_pan_code         = v_hash_pan;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_resp_id := '143';
    p_errmsg  := 'Error while selecting card details' || SUBSTR (SQLERRM, 1, 200); -- Modified the message for review comments on 16/Aug/2013
    RAISE exp_reject_record;
  WHEN OTHERS THEN
    v_resp_id := '21';
    p_errmsg  := 'Error while selecting card details for ' || fn_mask (p_card_no, 'X', 7, 6) || '-' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  --En Get Card details
  END IF;
  --Sn Get application details
  BEGIN

   v_cci_appl_code := v_cap_appl_code;             -- Added for performance fix

    SELECT cci_row_id,
      cci_ssnfail_dtls,
      cci_idology_id,
      cci_type_one,
      cci_type_two,
      cci_type_three,
      cci_upld_stat,
      cci_kyc_flag,
      cci_ins_date,
      cci_approved,
      CCI_TYPE_ONE,
      CCI_TYPE_TWO,
      CCI_TYPE_THREE,CCI_TYPE_FOUR
    INTO p_RespRowID,
      v_cci_ssnfail_dtls,
      v_cci_idology_id,
      v_cci_type_one,
      v_cci_type_two,
      v_cci_type_three,
      v_cci_upld_stat,
      v_cci_kyc_flag,
      v_cci_ins_date,
      v_cci_approved,
      p_security_q1,
      p_security_q2,
      p_security_q3,p_security_q4
    FROM cms_caf_info_entry
    WHERE cci_appl_code = v_cci_appl_code;             -- Changed from V_CAP_APPL_CODE to V_CCI_APPL_CODE for performance fix
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_resp_id := '21';
    p_errmsg  := 'Application not found-' || v_cap_appl_code;
    RAISE exp_reject_record;
  WHEN OTHERS THEN
    v_resp_id := '21';
    p_errmsg  := 'Error while selecting application details ' || v_cap_appl_code || '-' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  /*
  IF (v_cap_card_stat = '0' AND  v_cci_kyc_flag ='N') OR (v_cap_card_stat = '13' AND  v_cci_kyc_flag ='N') THEN
  NULL;
  ELSIF (v_cap_card_stat = '0' AND  v_cci_kyc_flag ='E') OR (v_cap_card_stat = '13' AND  v_cci_kyc_flag ='E') THEN
  NULL;
  ELSE
  v_resp_id := '143';
  p_errmsg   := 'Duplicate Registration Attempt';
  RAISE exp_reject_record;
  END IF;
  */
  IF p_RespRowID IS NULL THEN
    v_resp_id    := '65';
    p_errmsg     := 'Invalid Data for Idology ID';
    RAISE exp_reject_record;
  END IF;
   IF  (p_delivery_channel <> '08')   THEN
      IF     v_cap_card_stat NOT IN ('0', '13') AND v_cci_kyc_flag IN ('Y', 'P', 'O')
      THEN
         v_resp_id := '143';
         p_errmsg := 'Duplicate Registration Attempt';
         RAISE exp_reject_record;
      END IF;
  ELSIF v_cap_card_stat NOT IN('0','13') AND v_cci_kyc_flag NOT IN ('N','E') THEN
    v_resp_id            := '143';
    p_errmsg             := 'Duplicate Registration Attempt';
    RAISE exp_reject_record;
  END IF;
  --En Get application details
  --Commented for MVCSD-5125
  /*
  IF p_delivery_channel<>'08' AND p_txn_code<>'30' THEN  --Condition added by Pankaj S. for Target registration
  IF v_cap_firsttime_topup = 'N' THEN
    v_resp_id             := '126';
    p_errmsg              := 'Spil Activation  not done for this card';
    RAISE exp_reject_record;
  END IF;
  END IF;
  */
  --Sn Get starter card details
  BEGIN
    SELECT ccm_cust_id
    INTO v_cust_id
    FROM cms_cust_mast
    WHERE ccm_inst_code = p_inst_code
    AND ccm_cust_code   = v_cap_cust_code;
  EXCEPTION
  WHEN exp_reject_record THEN
    RAISE;
  WHEN OTHERS THEN
    v_resp_id := '21';
    p_errmsg  := 'Error while Customer id from Cust Mast-'|| SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  --En Get starter card details
  --Sn Expiry date check
  IF LAST_DAY (TO_DATE (p_business_date, 'YYYYMMDD')) > LAST_DAY (v_cap_expry_date) THEN
    v_resp_id                                        := '13'; -- modified for defect id:12285
    p_errmsg                                         := 'Expired Card';
    RAISE exp_reject_record;
  END IF;
  --En Expiry date check

     BEGIN
        SELECT cbm_bran_code
        INTO v_branch_code
        FROM cms_bran_mast
        WHERE cbm_inst_code = p_inst_code
        AND rownum          =1;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg  := 'Error while selecting branch detail ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En check branch
      --Sn Check valid Card Type
      BEGIN
      /* Commented for mantis id :12488
        SELECT CPC_CARD_TYPE
        INTO v_cust_catg
        FROM cms_prod_ccc
        WHERE cpc_inst_code = p_inst_code
        AND cpc_prod_code   = v_cap_prod_code
        AND rownum          =1;
        */

        --Added the below query for mantis id : 12488
        SELECT cpc_cust_catg
        INTO v_cust_catg
        FROM cms_prod_ccc
        WHERE cpc_inst_code = p_inst_code
        AND cpc_prod_code   = v_cap_prod_code
        and cpc_card_type = v_cap_card_type
        AND rownum =1;

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_resp_id := '83';
        p_errmsg  := 'Invalid Data for Product Category';
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg  :='Error while selecting prodccc detail from master-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En Check valid Card Type
      --Sn select customer category
      BEGIN
        SELECT ccc_catg_sname
        INTO v_catg_sname
        FROM cms_cust_catg
        WHERE ccc_catg_code = v_cust_catg;
       --ND ROWNUM          =1;  Commented for reveiw changes on 16/Aug/2013.
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg  :='Error while selecting customer category-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En select customer category

      --Sn Age limit validation
      BEGIN
        SELECT cpc_min_age_kyc,
          cpc_startergpr_issue,
          decode(cpc_starter_card,'Y',cpc_startergpr_crdtype,cpc_card_type)--Modified for VPP-177
        INTO v_min_age_kyc,
          v_startergpr_issue,
          v_startergpr_crdtype
        FROM cms_prod_cattype
        WHERE cpc_inst_code  = p_inst_code
        AND cpc_prod_code    = v_cap_prod_code
        AND cpc_card_type    = v_cap_card_type;
       -- AND cpc_starter_card = 'Y';
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg  := 'Error while checking age limits details-' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En Age limit validation
      p_branch_code :=   v_branch_code ;
      p_catg_sname :=  v_catg_sname ;
      p_startergpr_crdtype := v_startergpr_crdtype;
      p_document_verify_res  :=  v_document_verify;

--Sn select authorization processe flag
    BEGIN
      SELECT ptp_param_value
      INTO v_precheck_flag
      FROM pcms_tranauth_param
      WHERE ptp_param_name = 'PRE CHECK'
      AND ptp_inst_code    = p_inst_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_resp_id := '21'; --only for master setups
      p_errmsg  := 'Master set up is not done for Authorization Process';
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_resp_id := '21'; --only for master setups
      p_errmsg  := 'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
     --Sn check for precheck
      IF v_precheck_flag = 1 THEN
        BEGIN
          sp_precheck_txn (p_inst_code, 
                              p_card_no, 
                              p_delivery_channel, 
                              v_cap_expry_date, 
                              v_cap_card_stat, 
                              p_txn_code, 
                              null,  -- mode
                              p_business_date,
                              p_business_time, 
                              null,  -- tran amt
                              null,   -- atm limit
                              null,   -- pos limit 
                              v_resp_id, 
                              p_errmsg );
          IF (v_resp_id <> '1' OR p_errmsg <> 'OK') THEN
            RAISE exp_reject_record;
          END IF;
        EXCEPTION
        WHEN exp_reject_record THEN
          RAISE;
        WHEN OTHERS THEN
          v_resp_id := '21';
          p_errmsg  := 'Error from precheck processes ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
      END IF;
      
      --Start Generate HashKEY for MVCAN-77
       BEGIN
           V_FLDOB_HASHKEY_ID := GETHASH (UPPER(p_firstname)||UPPER(p_lastname)||to_date(p_dob,'mmddyyyy'));
       EXCEPTION
        WHEN OTHERS
        THEN
        v_resp_id := '21';
        p_errmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
     END;
    --End Generate HashKEY for  MVCAN-77
    
    
  --idologyID is null Start
  IF p_idologyid          IS NULL THEN--v_cci_idology_id
    --IF p_delivery_channel <> '03' AND p_txn_code <>'04' THEN
      -- Sn DOB Validation.  add for review cahnges on 16/Aug/2013
      BEGIN

      v_dob:=to_date(p_dob,'mmddyyyy');

      EXCEPTION
        WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg   := 'Error while converting dob-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
       END;
      -- En DOB Validation.

       IF v_startergpr_issue IS NULL THEN
        v_startergpr_issue  :='A';
      END IF;
      --Sn check branch
       -- UnCommented for defect :12097 on 22/Aug/2013
      --Sn get currency code
      BEGIN
        SELECT gcm_curr_code
        INTO v_curr_code
        FROM gen_cntry_mast
        WHERE gcm_inst_code    = p_inst_code  -- Modified the query on 16/Aug/2013 for review changes.
        AND gcm_cntry_code = p_cntry_code;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_resp_id := '75';
        p_errmsg  := 'Invalid Data for Country Code';
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg  :='Error while selecting country detail-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En get currency code
      BEGIN
        SELECT gsm_switch_state_code
        INTO v_state_code
        FROM GEN_STATE_MAST
        WHERE GSM_INST_CODE   =p_inst_code  -- Modified the query on 16/Aug/2013 for review changes.
        AND GSM_CNTRY_CODE  =p_cntry_code
        AND GSM_STATE_CODE=p_state_code;

        p_switch_state_code := v_state_code; -- Added for getting state code as output param for MVHOST-355 amudhan
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        p_errmsg  := 'Invalid Data for Physical Address State';
        v_resp_id := '73';
        RAISE exp_reject_record;
      WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg  :='Error while selecting state detail-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
        /* Commented for defect :12097 on 22/Aug/2013
      --Sn Selecting Branch Code    -- added this block for review changes on 16/Aug/2013
       BEGIN
        SELECT cbm_bran_code
        INTO v_branch_code
        FROM cms_bran_mast
        WHERE cbm_inst_code=p_inst_code
        AND CBM_CNTRY_CODE=p_cntry_code
        AND CBM_STATE_CODE=p_state_code
        AND rownum         =1;
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg   := 'Error while selecting Branch Code-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En Selecting Branch Code
      */

      IF p_mail_state_code IS NOT NULL AND p_mail_cntry_code IS NOT NULL THEN
        --En validate state code for mailing address state if entered
        BEGIN
          SELECT gsm_switch_state_code
          INTO v_mail_gsm_switch_state_code
          FROM gen_state_mast
          WHERE gsm_inst_code   =p_inst_code  -- Modified the query on 16/Aug/2013 for review changes.
          AND gsm_cntry_code  =p_mail_cntry_code
          AND gsm_state_code=p_mail_state_code;

          p_mailing_state_code:=v_mail_gsm_switch_state_code; -- Added for getting state code as output param for MVHOST-355 amudhan

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_resp_id := '32';
          p_errmsg  := 'Invalid Data for Mailing Address State';
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          v_resp_id := '21';
          p_errmsg  := 'Error while selecting state-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
        --En validate state code for mailing address state if entered
      END IF;
            
      
    IF p_id_province IS NOT NULL
    AND p_id_country IS NOT NULL 	
	  THEN
        BEGIN
          SELECT gcm_alpha_cntry_code
          INTO v_id_country
          FROM gen_cntry_mast
          WHERE gcm_inst_code   = p_inst_code  
          AND gcm_alpha_cntry_code  = p_id_country;
          
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_resp_id := '274';
          p_errmsg  := 'Invalid Data for ID Country code';
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          v_resp_id := '21';
          p_errmsg  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
        
        BEGIN
          SELECT gsm_switch_state_code
          INTO v_id_province
          FROM gen_state_mast
          WHERE gsm_inst_code   = p_inst_code  
		    AND gsm_alpha_cntry_code = p_id_country
            AND gsm_switch_state_code  = p_id_province;
                    
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_resp_id := '273';
          p_errmsg  := 'Invalid Data for ID Province';
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          v_resp_id := '21';
          p_errmsg  := 'Error while selecting state-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
	     
       END IF;
      IF  p_jurisdiction_of_tax_res IS NOT NULL    
      THEN
         BEGIN
          SELECT gcm_alpha_cntry_code
          INTO v_jurisdiction_of_tax_res
          FROM gen_cntry_mast
          WHERE gcm_inst_code   = p_inst_code  
          AND gcm_alpha_cntry_code  = p_jurisdiction_of_tax_res;
         
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_resp_id := '275';
          p_errmsg  := 'Invalid Data for Jurisdiction of tax residence';
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          v_resp_id := '21';
          p_errmsg  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
       END IF;
         
            
      --Sn KYC age validation
      BEGIN
        v_agecal := (TRUNC(sysdate)-v_dob)/365; -- modified for review changes on 16/Aug/2013
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg  := 'Error while calculating KYC age-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En KYC age validation
      IF v_agecal  < v_min_age_kyc THEN

        v_resp_id := '35';
        p_errmsg  := 'Age Limit Verification Failed';

        IF p_delivery_channel='03' AND p_txn_code='03' THEN --Added for MVCSD-5381
          v_minorcard := TRUE;
          v_kyc_flag := 'M';
        else
          RAISE exp_reject_record;
        END IF;

      END IF;

      --Sn Update the details in CMS_CAF_INFO_ENTRY for selected application
      BEGIN
      IF (p_delivery_channel = '08' or v_minorcard)    THEN     --Added for MVCSD-5381

        UPDATE cms_caf_info_entry
        SET cci_inst_code         = p_inst_code,
          cci_fiid                = v_branch_code,
          cci_seg12_homephone_no  = p_telnumber,
          cci_seg12_name_line1    = p_firstname,
          cci_seg12_name_line2    = p_lastname,
          cci_seg12_addr_line1    = p_physical_add_one,
          cci_seg12_addr_line2    = p_physical_add_two,
          cci_seg12_city          = p_city,
          cci_seg12_state         = v_state_code,
          cci_seg12_postal_code   = p_zipcode ,
          cci_seg12_country_code  = p_cntry_code,
          cci_seg12_mobileno      = p_mobile_no,
          CCI_SEG12_EMAILID       = P_EMAIL_ADD,
          cci_prod_code           = v_cap_prod_code,
          CCI_REQUESTER_NAME      = P_FIRSTNAME,
          cci_ssn                 = fn_maskacct_ssn(p_inst_code,DECODE(v_document_verify,'SSN',p_id_number,'SIN',p_id_number),0), --Modified for defect :12310 on 17/09/2013,
          cci_ssn_encr            = fn_emaps_main(DECODE(v_document_verify,'SSN',p_id_number,'SIN',p_id_number)),
          cci_birth_date          = TO_DATE(p_dob ,'mmddyyyy'),
          cci_document_verify     = p_document_verify,
          cci_kyc_flag            = v_kyc_flag, --Modified for MVCSD-5381
          cci_ins_date            = SYSDATE,
          cci_lupd_date           = NULL,
          cci_approved            = 'A',
          cci_upld_stat           = 'P',
          cci_entry_rec_type      = 'P',
          cci_instrument_realised = 'Y',
          cci_cust_catg           = v_catg_sname,
          CCI_COMM_TYPE           = '0',
          cci_seg13_addr_param9   = v_curr_code,
          CCI_TITLE               = 'MR',
          CCI_ID_ISSUER           = DECODE(V_DOCUMENT_VERIFY,'SSN',NULL,'SIN',NULL,P_ID_ISSUER),  -- Modified for review changes on 16/Aug/2013
          cci_id_number           = fn_maskacct_ssn(p_inst_code,DECODE(v_document_verify,'SSN',NULL,'SIN',NULL,p_id_number),0),  -- Modified for review changes on 16/Aug/2013.
          cci_id_number_encr      = fn_emaps_main(DECODE(v_document_verify,'SSN',NULL,'SIN',NULL,p_id_number)),
          cci_seg13_addr_line1    = p_mailing_add_one,
          cci_seg13_addr_line2    = p_mailing_add_two,
          cci_seg13_city          = p_mailing_city,
          CCI_SEG13_STATE         = V_MAIL_GSM_SWITCH_STATE_CODE,
          cci_seg13_postal_code   = p_mailing_zipcode,
          CCI_SEG13_COUNTRY_CODE  = P_MAIL_CNTRY_CODE,
          CCI_ID_ISSUANCE_DATE    = DECODE(V_DOCUMENT_VERIFY,'SSN',null,'SIN',null,TO_DATE(P_ISSUANCE_DATE,'mmddyyyy')), -- Modified for review changes on 16/Aug/2013.
          cci_id_expiry_date      = DECODE(v_document_verify,'SSN',NULL,'SIN',NULL,to_date(p_expiry_date,'mmddyyyy')),  -- Modified for review changes on 16/Aug/2013.
          cci_mothers_maiden_name = p_mothers_maiden_name,
          cci_card_type           = v_startergpr_crdtype,--v_cap_card_type,
          cci_pan_code            = v_hash_pan,
          cci_pan_code_encr       = v_encr_pan,
          cci_seg12_state_code    = p_state_code,
          cci_seg13_state_code    = p_mail_state_code,
          cci_kyc_reg_date        = SYSDATE,
          CCI_STARTER_CARD_NO     = v_hash_pan,             --Added for Mantis id -13713
          CCI_STARTER_CARD_NO_ENCR = v_encr_pan            --Added for Mantis id -13713
          WHERE cci_row_id          = p_RespRowID;
        IF SQL%ROWCOUNT           = 0 THEN
          p_errmsg               :='Error while updating appl detail in CMS_CAF_INFO_ENTRY';
          RAISE exp_reject_record;
        END IF;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_id := '21';
        p_errmsg  :='Error while updating appl detail in CMS_CAF_INFO_ENTRY-'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
      --En Update the details in CMS_CAF_INFO_ENTRY for selected application*/
   -- END IF;
   --ST Added for MVCSD-5381
   IF v_minorcard then
          --UPDATE CARD STATUS AND ATTACH DUMMY FEE PLAN TO CARD LEVEL
           BEGIN

               UPDATE CMS_APPL_PAN SET CAP_CARD_STAT='13'
               WHERE CAP_PAN_CODE=v_hash_pan
               AND   CAP_INST_CODE = p_inst_code;

               IF SQL%ROWCOUNT !=1 THEN
                v_resp_id := '21';
                p_errmsg   := 'Problem in updation of card status' ||  SUBSTR(SQLERRM, 1, 200);
                RAISE exp_reject_record;
               END IF;

               EXCEPTION
                WHEN exp_reject_record THEN
                RAISE;
                WHEN OTHERS THEN
                  v_resp_id := '21';
                  p_errmsg   := 'Error ocurs while updating card status  ' ||SUBSTR(SQLERRM, 1, 200);
                  RAISE exp_reject_record;
          END;

           BEGIN
               sp_log_cardstat_chnge (p_inst_code,
                                      V_HASH_PAN,
                                      V_ENCR_PAN ,
                                      v_verification_id,
                                      '09',
                                      p_rrn,
                                      p_business_date,
                                      p_business_time,
                                      v_resp_id,
                                      p_errmsg
                                     );

               IF v_resp_id <> '00' AND p_errmsg <> 'OK'
               THEN
                  RAISE exp_reject_record;
               END IF;

               EXCEPTION
                 WHEN exp_reject_record THEN
                   RAISE;
                 WHEN OTHERS THEN
                    v_resp_id := '21';
                    p_errmsg := 'Error while logging system initiated card status change '|| SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
           END;

          --Updating KYC status as Miner "M" for Minor Card(Age Limit Verification Failed)
           BEGIN
            UPDATE cms_cust_mast
               SET ccm_kyc_flag = 'M',
                   ccm_kyc_source = p_delivery_channel
             WHERE ccm_inst_code = p_inst_code AND ccm_cust_code = v_cap_cust_code;

            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_id := '21';
               p_errmsg := 'Error while updating KYC Flag in CMS_CUST_MAST';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_id := '21';
               p_errmsg :=
                     'Error while updating kyc flag in cust-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
            --St Updates the fee plan id to card
           BEGIN
              SELECT cce_fee_plan
                INTO v_fee_plan_id
                FROM cms_card_excpfee
               WHERE cce_inst_code = p_inst_code
                 AND cce_pan_code = v_hash_pan
                 AND (   (    cce_valid_to IS NOT NULL
                          AND (v_tran_date BETWEEN cce_valid_from AND cce_valid_to)
                         )
                      OR (cce_valid_to IS NULL AND trunc(SYSDATE) >= cce_valid_from) -- modified for 0015800
                     );

            UPDATE cms_card_excpfee set cce_valid_to=sysdate-1
            WHERE cce_inst_code = p_inst_code
            AND cce_pan_code = v_hash_pan
            AND cce_fee_plan = v_fee_plan_id;

              IF SQL%ROWCOUNT = 0
              THEN
                 p_errmsg := 'updating FEE PLAN ID IS NOT HAPPENED'|| SUBSTR (SQLERRM, 1, 200);
                 v_resp_id := '21';
                 RAISE exp_reject_record;
              END IF;

               INSERT INTO cms_card_excpfee
                              (cce_inst_code, cce_pan_code, cce_ins_date,
                               cce_ins_user, cce_lupd_user, cce_lupd_date,
                               cce_fee_plan, cce_flow_source, cce_valid_from,
                               cce_valid_to,cce_pan_code_encr,cce_mbr_numb
                              )
                       VALUES (1, V_HASH_PAN, SYSDATE,
                             1, 1, SYSDATE,0,'C',trunc(sysdate), null, -- modified for 0015800
                             V_ENCR_PAN,'000'
                            );

                   IF SQL%ROWCOUNT !=1 THEN
                    v_resp_id := '21';
                    p_errmsg   := 'Problem in attaching fee plan to card ' ||  SUBSTR(SQLERRM, 1, 200);
                    RAISE exp_reject_record;
                   END IF;

           EXCEPTION
              WHEN exp_reject_record
              THEN
                 RAISE exp_reject_record;
              WHEN NO_DATA_FOUND
              THEN
                 BEGIN

                 INSERT INTO cms_card_excpfee
                              (cce_inst_code, cce_pan_code, cce_ins_date,
                               cce_ins_user, cce_lupd_user, cce_lupd_date,
                               cce_fee_plan, cce_flow_source, cce_valid_from,
                               cce_valid_to,cce_pan_code_encr,cce_mbr_numb
                              )
                       VALUES (1, V_HASH_PAN, SYSDATE,
                             1, 1, SYSDATE,0,'C',trunc(sysdate), null, -- modified for 0015800
                             V_ENCR_PAN,'000'
                            );

                   IF SQL%ROWCOUNT !=1 THEN
                    v_resp_id := '21';
                    p_errmsg   := 'Problem in attaching fee plan to card ' ||  SUBSTR(SQLERRM, 1, 200);
                    RAISE exp_reject_record;
                   END IF;

                  EXCEPTION
                     WHEN exp_reject_record THEN
                       RAISE;
                     WHEN OTHERS THEN
                        v_resp_id := '21';
                        p_errmsg := 'Error while attach dummy fee plan to card '|| SUBSTR (SQLERRM, 1, 200);
                       RAISE exp_reject_record;
               END;
               WHEN OTHERS THEN
                   p_errmsg :=
                        'Error while updating FEE PLAN ID ' || SUBSTR (SQLERRM, 1, 200);
                   v_resp_id := '21';
                   RAISE exp_reject_record;
             END;

           BEGIN

             --Added for MVCSD-5381(review Chanegs)
             select count(1) into v_fee_planid  from CMS_FEEPLAN_PROD_MAPG
             where CFM_PLAN_ID=0
             and CFM_PROD_CODE=v_cap_prod_code
             and CFM_INST_CODE=p_inst_code;

             if v_fee_planid = 0 then
               --Commented for review changes for MVCSD-5381
               --delete from CMS_FEEPLAN_PROD_MAPG where CFM_PLAN_ID=0 and CFM_INST_CODE=p_inst_code;

                 INSERT INTO CMS_FEEPLAN_PROD_MAPG (CFM_PLAN_ID, CFM_PROD_CODE, CFM_INST_CODE ,CFM_INS_USER,CFM_INS_DATE)
                         VALUES (0,v_cap_prod_code,p_inst_code,1,sysdate);

                IF SQL%ROWCOUNT = 0
                THEN
                   v_resp_id := '21';
                   p_errmsg := 'Not attached fee plan to product';
                   RAISE exp_reject_record;
                END IF;
            end if;

         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_id := '21';
               p_errmsg :=
                     'Error while attaching fee plan to product-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

        END IF;
   --END Added for MVCSD-5381
  END IF; --idologyID is null End
  --IF (p_idologyid IS NULL OR (p_delivery_channel ='03' AND p_txn_code='04')) THEN
  
  
  
  if P_IDOLOGYID is null then

  /*  if ( (P_DELIVERY_CHANNEL='03' and P_TXN_CODE='90') or (P_DELIVERY_CHANNEL='06' and P_TXN_CODE='05')) then

       BEGIN               -- Modified the quiry for review changes on 16/Aug/2013

        UPDATE cms_caf_info_entry
        SET cci_ssn_flag    = 'Y',
          cci_ssnfail_dtls  = v_card_dtl-- Modified 0n 10-01-2014 for MVHOST-822
        WHERE cci_inst_code = p_inst_code
        AND cci_row_id      = p_RespRowID;

          IF SQL%ROWCOUNT =0 THEN
              v_resp_id            := '21';
              p_errmsg              :='Error while updating caf_info_entry ' || SUBSTR (SQLERRM, 1, 200) ;
            RAISE exp_reject_record;
           END IF;
        EXCEPTION
        WHEN  exp_reject_record THEN
          RAISE;
        WHEN OTHERS THEN
          v_resp_id := '21';
          P_ERRMSG  := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
        end;
        else*/
       
     BEGIN
      sp_check_ssn_threshold (p_inst_code,p_id_number,v_cap_prod_code,v_cap_card_type,'EN',v_card_dtl, v_resp_id, p_errmsg,V_FLDOB_HASHKEY_ID ); --Added for MVCAN-77 of 3.1 release 
      /*IF p_delivery_channel ='03' AND p_txn_code='04' AND p_rowID IS NOT NULL THEN
        p_RespRowID        :=p_rowID;
      END IF;
      */

      -- Sn Added 0n 10-01-2014 for MVHOST-822

      --IF v_resp_id <> '00' THEN

         IF p_errmsg <> 'OK' THEN

          IF p_delivery_channel = '06' OR  p_delivery_channel  = '13' THEN --Modified for MOB-62
            v_resp_id := '144';
          END IF;

          IF p_delivery_channel = '03' THEN
            v_resp_id := '158';
          END IF;

          IF p_delivery_channel = '08' THEN --Added for defect id : 14569 on 28/05/2014
            v_resp_id := '135';
          END IF;
      -- En Added 0n 10-01-2014 for MVHOST-822
      --Sn - Added for MVCAN-77 of 3.1 release 
       if ( (P_DELIVERY_CHANNEL='03' and P_TXN_CODE='90') or (P_DELIVERY_CHANNEL='06' and P_TXN_CODE='05')) then

         BEGIN                      -- Modified the quiry for review changes on 16/Aug/2013
        UPDATE cms_caf_info_entry
        SET
          cci_inst_code           = p_inst_code,
          cci_fiid                = v_branch_code,
          cci_seg12_homephone_no  = p_telnumber,
          cci_seg12_name_line1    = p_firstname,
          cci_seg12_name_line2    = p_lastname,
          cci_seg12_addr_line1    = p_physical_add_one,
          cci_seg12_addr_line2    = p_physical_add_two,
          cci_seg12_city          = p_city,
          cci_seg12_state         = v_state_code,
          cci_seg12_postal_code   = p_zipcode ,
          cci_seg12_country_code  = p_cntry_code,
          cci_seg12_mobileno      = p_mobile_no,
          CCI_SEG12_EMAILID       = P_EMAIL_ADD,
          cci_prod_code           = v_cap_prod_code,
          CCI_REQUESTER_NAME      = P_FIRSTNAME,
          cci_ssn                 = fn_maskacct_ssn(p_inst_code,DECODE(v_document_verify,'SSN',p_id_number,'SIN',p_id_number),0), --Modified for defect :12310 on 17/09/2013,
          cci_ssn_encr            = fn_emaps_main(DECODE(v_document_verify,'SSN',p_id_number,'SIN',p_id_number)),
          cci_birth_date          = TO_DATE(p_dob ,'mmddyyyy'),
          cci_document_verify     = p_document_verify,
          cci_kyc_flag            = v_kyc_flag, --Modified for MVCSD-5381
          cci_ins_date            = SYSDATE,
          cci_lupd_date           = NULL,
          cci_approved            = 'A',
          cci_upld_stat           = 'P',
          cci_entry_rec_type      = 'P',
          cci_instrument_realised = 'Y',
          cci_cust_catg           = v_catg_sname,
          CCI_COMM_TYPE           = '0',
          cci_seg13_addr_param9   = v_curr_code,
          CCI_TITLE               = 'MR',
          CCI_ID_ISSUER           = DECODE(V_DOCUMENT_VERIFY,'SSN',NULL,'SIN',NULL,P_ID_ISSUER),  -- Modified for review changes on 16/Aug/2013
          cci_id_number           = fn_maskacct_ssn(p_inst_code,DECODE(v_document_verify,'SSN',NULL,'SIN',NULL,p_id_number),0),  -- Modified for review changes on 16/Aug/2013.
          cci_id_number_encr      = fn_emaps_main(DECODE(v_document_verify,'SSN',NULL,'SIN',NULL,p_id_number)),
          cci_seg13_addr_line1    = p_mailing_add_one,
          cci_seg13_addr_line2    = p_mailing_add_two,
          cci_seg13_city          = p_mailing_city,
          CCI_SEG13_STATE         = V_MAIL_GSM_SWITCH_STATE_CODE,
          cci_seg13_postal_code   = p_mailing_zipcode,
          CCI_SEG13_COUNTRY_CODE  = P_MAIL_CNTRY_CODE,
          CCI_ID_ISSUANCE_DATE    = DECODE(V_DOCUMENT_VERIFY,'SSN',null,'SIN',null,TO_DATE(P_ISSUANCE_DATE,'mmddyyyy')), -- Modified for review changes on 16/Aug/2013.
          cci_id_expiry_date      = DECODE(v_document_verify,'SSN',NULL,'SIN',NULL,to_date(p_expiry_date,'mmddyyyy')),  -- Modified for review changes on 16/Aug/2013.
          cci_mothers_maiden_name = p_mothers_maiden_name,
          cci_card_type           = v_startergpr_crdtype,--v_cap_card_type,
          cci_pan_code            = v_hash_pan,
          cci_pan_code_encr       = v_encr_pan,
          cci_seg12_state_code    = p_state_code,
          cci_seg13_state_code    = p_mail_state_code,
          cci_kyc_reg_date        = SYSDATE,
          CCI_STARTER_CARD_NO     = v_hash_pan,             --Added for Mantis id -13713
          CCI_STARTER_CARD_NO_ENCR = v_encr_pan, 
          cci_ssn_flag    = 'E',
          cci_ssnfail_dtls  = v_card_dtl,-- Modified 0n 10-01-2014 for MVHOST-822
          cci_process_msg   = p_errmsg
          WHERE cci_inst_code = p_inst_code
        AND cci_row_id      = p_RespRowID;
        --RAISE exp_reject_record;
         IF SQL%ROWCOUNT     = 0 THEN
            v_resp_id       := '21';
            p_errmsg         :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag E';
            RAISE exp_reject_record;
          END IF;
       EXCEPTION
        WHEN exp_reject_record THEN
         RAISE;
        WHEN OTHERS THEN
          v_resp_id := '21';
          p_errmsg  := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
       END;
       --En - Added for MVCAN-77 of 3.1 release 
       ELSE 
       
        BEGIN                      -- Modified the quiry for review changes on 16/Aug/2013
        UPDATE cms_caf_info_entry
        SET 
          cci_ssn_flag    = 'E',
          cci_ssnfail_dtls  = v_card_dtl,-- Modified 0n 10-01-2014 for MVHOST-822
          cci_process_msg   = p_errmsg,
           CCI_STARTER_CARD_NO     = v_hash_pan,             
          CCI_STARTER_CARD_NO_ENCR = v_encr_pan
        WHERE cci_inst_code = p_inst_code
        AND cci_row_id      = p_RespRowID;
        --RAISE exp_reject_record;
         IF SQL%ROWCOUNT     = 0 THEN
            v_resp_id       := '21';
            p_errmsg         :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag E';
            RAISE exp_reject_record;
          END IF;
       EXCEPTION
        WHEN exp_reject_record THEN
         RAISE;
        WHEN OTHERS THEN
          v_resp_id := '21';
          p_errmsg  := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
       END;
       
       END IF;
       

      ELSE
       BEGIN               -- Modified the quiry for review changes on 16/Aug/2013

        UPDATE cms_caf_info_entry
        SET cci_ssn_flag    = 'Y',
          cci_ssnfail_dtls  = v_card_dtl-- Modified 0n 10-01-2014 for MVHOST-822
          , CCI_STARTER_CARD_NO     = v_hash_pan,            
          CCI_STARTER_CARD_NO_ENCR = v_encr_pan
        WHERE cci_inst_code = p_inst_code
        AND cci_row_id      = p_RespRowID;

          IF SQL%ROWCOUNT =0 THEN
              v_resp_id            := '21';
              p_errmsg              :='Error while updating caf_info_entry ' || SUBSTR (SQLERRM, 1, 200) ;
            RAISE exp_reject_record;
           END IF;
        EXCEPTION
        WHEN  exp_reject_record THEN
          RAISE;
        WHEN OTHERS THEN
          v_resp_id := '21';
          P_ERRMSG  := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;


        end;

          end if;

    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_id := '21';
      p_errmsg  := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    end;
    --En SSN validations


  end if;
  --end if;

  --idologyID is not null start
  IF p_idologyid IS NOT NULL THEN
  
    --Sn SSN validations
    BEGIN
      sp_check_ssn_threshold (p_inst_code,p_id_number,v_cap_prod_code,'EN',v_card_dtl, v_resp_id, p_errmsg,V_FLDOB_HASHKEY_ID ); --Added for MVCAN-77 of 3.1 release
      /*  IF p_delivery_channel ='03' AND p_txn_code='02' THEN
      v_seq_val          :=p_rowID;
      END IF;
      */

      -- Sn Added 0n 10-01-2014 for MVHOST-822

      --IF v_resp_id <> '00' THEN

         IF p_errmsg <> 'OK' THEN

          IF p_delivery_channel = '06' OR  p_delivery_channel  = '13' THEN --Modified for MOB-62
            v_resp_id := '144';
          END IF;

          IF p_delivery_channel = '03' THEN
            v_resp_id := '158';
          END IF;

           IF p_delivery_channel = '08' THEN --Added for defect id : 14569 on 28/05/2014
            v_resp_id := '135';
          END IF;
      -- En Added 0n 10-01-2014 for MVHOST-822

        BEGIN                           -- Modified the quiry for review changes on 16/Aug/2013

        UPDATE cms_caf_info_entry
        SET cci_ssn_flag    = 'E',
          cci_ssnfail_dtls  = v_card_dtl, -- Modified 0n 10-01-2014 for MVHOST-822
          cci_process_msg   = p_errmsg
        WHERE cci_inst_code = p_inst_code
        AND cci_row_id      = p_RespRowID;
       -- RAISE exp_reject_record;
        IF SQL%ROWCOUNT     = 0 THEN
            v_resp_id       := '21';
            p_errmsg         :='Updation not happen in CMS_CAF_INFO_ENTRY for cci_ssn_flag E-2';
            RAISE exp_reject_record;
          END IF;
        EXCEPTION
          WHEN exp_reject_record THEN
          RAISE;
          WHEN OTHERS THEN
            v_resp_id := '21';
             p_errmsg  := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
          END;
      ELSE
       BEGIN   -- Modified the quiry for review changes on 16/Aug/2013

         UPDATE cms_caf_info_entry
         SET cci_ssn_flag    = 'Y',
         cci_ssnfail_dtls  = v_card_dtl -- Modified 0n 10-01-2014 for MVHOST-822
        WHERE cci_inst_code = p_inst_code
        AND cci_row_id      = p_RespRowID;
         IF SQL%ROWCOUNT =0 THEN
               v_resp_id            := '21';
               p_errmsg              :='Error while updating caf_info_entry ' || SUBSTR (SQLERRM, 1, 200) ;
             RAISE exp_reject_record;
             END IF;
        EXCEPTION
        WHEN  exp_reject_record THEN
          RAISE;
          WHEN OTHERS THEN
          v_resp_id := '21';
          p_errmsg  := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;

         END;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_id := '21';
      p_errmsg  := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En SSN validations
    IF v_cci_upld_stat <> 'P' THEN
      v_resp_id        := '65';
      p_errmsg         := 'Invalid Data for Idology ID';
      RAISE exp_reject_record;
    END IF;
    --Sn Updating answer for idology
    BEGIN
      UPDATE cms_caf_info_entry
      SET cci_answer_one  = p_cci_a1,
        cci_answer_two    = p_cci_a2,
        cci_answer_three  = p_cci_a3,
         CCI_ANSWER_FOUR=p_cci_a4
      WHERE cci_inst_code = p_inst_code
      AND cci_idology_id  = v_cci_idology_id
      AND cci_row_id      = p_RespRowID;
      IF SQL%ROWCOUNT     = 0 THEN
        p_errmsg         := 'Error while updating ans idology in CMS_CAF_INFO_ENTRY';
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_id := '21';
      p_errmsg  := 'Error while updating ans for idology in CMS_CAF_INFO_ENTRY-'|| SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;
    --En Updating answer for idology
  END IF;

/*   commented for defect id:12285
  BEGIN
    SELECT CAM_ACCT_BAL,
      CAM_LEDGER_BAL
    INTO V_ACCT_BALANCE,
      V_LEDGER_BAL
    FROM CMS_ACCT_MAST
    WHERE CAM_INST_CODE=P_INST_CODE -- Added the inst code for review changes on 16/Aug/2013
        AND CAM_ACCT_NO =v_cap_acct_no;
  EXCEPTION
  WHEN OTHERS THEN
    v_resp_id := '21';
    p_errmsg  := 'Error while selecting Account Balance from CMS_ACCT_MAST-'|| SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  END;
  */
  --idologyID is not null end
  BEGIN
    SELECT CMS_ISO_RESPCDE
    INTO P_RESP_CODE
    FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE      = P_INST_CODE
    AND CMS_DELIVERY_CHANNEL = TO_NUMBER(P_DELIVERY_CHANNEL)
    AND CMS_RESPONSE_ID      = TO_NUMBER(DECODE(v_resp_id, '00', '1',v_resp_id));
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg  :='Problem while selecting data from response master for respose code'|| SUBSTR(SQLERRM, 1, 300);
    v_resp_id := '21';
    RAISE EXP_REJECT_RECORD;
  END;


  --commented for defect id:12285 -- uncommented for Spil_3.0 Changes
  IF     (p_delivery_channel = '08'
      AND p_txn_code = '30') or v_minorcard      --Added for MVCSD-5381   -- if condition added for Spil_3.0 Changes
  THEN

     v_time_stamp := systimestamp;

        if v_cap_acct_no is not null
        then

          BEGIN

            SELECT CAM_ACCT_BAL,
              CAM_LEDGER_BAL,cam_type_code
            INTO V_ACCT_BALANCE,
              V_LEDGER_BAL,v_type_code
            FROM CMS_ACCT_MAST
            WHERE CAM_INST_CODE=P_INST_CODE -- Added the inst code for review changes on 16/Aug/2013
                AND CAM_ACCT_NO = v_cap_acct_no;

          EXCEPTION
          WHEN OTHERS THEN
            v_resp_id := '21';
            p_errmsg  := 'Error while selecting Account Balance from CMS_ACCT_MAST-'|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
          END;

        end if;
      BEGIN
        INSERT
        INTO TRANSACTIONLOG
          (
            RRN,
            TXN_CODE,
            MSGTYPE,
            BUSINESS_DATE,
            BUSINESS_TIME,
            CURRENCYCODE,
            PRODUCTID,
            categoryid,
            TRANS_DESC,
            INSTCODE,
            DELIVERY_CHANNEL,
            TXN_STATUS,
            RESPONSE_CODE,
            CUSTOMER_ACCT_NO,
            CUSTOMER_CARD_NO,
            CUSTOMER_CARD_NO_ENCR,
            PROXY_NUMBER,
            ACCT_BALANCE,
            LEDGER_BALANCE,
            CUSTOMER_STARTER_CARD_NO,
            GPRCARDAPPLICATIONNO,
            response_id,
            error_msg,
            ipaddress,
            -- sn Added during spil_3.0 changes
            cr_dr_flag,
            cardstatus,
            time_stamp,
            amount,
            total_amount,
            acct_type
            -- en Added during spil_3.0 changes
          )
          VALUES
          (
            p_rrn,
            p_txn_code,
            '0200',
            p_business_date,
            p_business_time,
            v_curr_code,
            v_cap_prod_code,
            v_cap_card_type,
            v_trans_desc,
            p_inst_code,
            p_delivery_channel,
            DECODE(P_RESP_CODE, '00', 'C', 'F'),
            P_RESP_CODE,
            v_cap_acct_no,
            v_hash_pan,
            v_encr_pan,
            v_proxy_number,
            V_ACCT_BALANCE,
            V_LEDGER_BAL,
            v_encr_pan,
            v_cap_appl_code,
            DECODE(v_resp_id, '00', '1',v_resp_id),
            p_errmsg,
            p_ipaddress,
            -- sn Added during spil_3.0 changes
            v_cr_dr_flag,
            v_cap_card_stat,
            v_time_stamp,
            '0.00',
            '0.00',
            v_type_code
            -- en Added during spil_3.0 changes
          );
        IF SQL%ROWCOUNT != 1 THEN
          v_resp_id     := '21';
          p_errmsg      :='Insert not happen in TRANSACTIONLOG';
          RAISE exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_id := '89';
        p_errmsg  := 'Error while inserting in Transactionlog ' || SUBSTR (SQLERRM, 1, 100);
      END;

      -- Sn Added for spil_3.0
      BEGIN
         /*v_verification_id :=
            SUBSTR (   LPAD (seq_auth_id.NEXTVAL, 6, '0')
                    || TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS'),
                    1,
                    15
                   );
                   */
                   --Commented and modified for FSS-1624
         v_verification_id :=
               TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS')
                       ||   SUBSTR( LPAD(seq_auth_id.NEXTVAL, 6, '0'),4,6);

      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while generating verification id '
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_id := '21';
            RAISE exp_reject_record;
      END;

      if p_errmsg = 'OK' then  --Added for defect id : 14569 on 28/05/2014
        p_errmsg := v_verification_id;
      end if;

      -- En Added for Spil_3.0

      BEGIN
        INSERT
        INTO CMS_TRANSACTION_LOG_DTL
          (
            CTD_DELIVERY_CHANNEL,
            CTD_TXN_CODE,
            CTD_MSG_TYPE,
            CTD_BUSINESS_DATE,
            CTD_BUSINESS_TIME,
            CTD_TXN_CURR,
            CTD_RRN,
            CTD_INST_CODE,
            CTD_PROCESS_FLAG,
            CTD_PROCESS_MSG,
            CTD_CUST_ACCT_NUMBER,
            CTD_CUSTOMER_CARD_NO,
            CTD_CUSTOMER_CARD_NO_ENCR,
            ctd_auth_id                 --Added for Spil_3.0 Changes
          )
          VALUES
          (
            p_delivery_channel,
            p_txn_code,
            '0200',
            p_business_date,
            p_business_time,
            v_curr_code,
            p_rrn,
            p_inst_code,
            DECODE(P_RESP_CODE, '00', 'Y', 'E'),  --Modified for defect id : 14569 on 28/05/2014
            p_errmsg,  --Modified for defect id : 14569 on 28/05/2014
            v_cap_acct_no,
            v_hash_pan,
            v_encr_pan,
            v_verification_id       --Added for Spil_3.0 Changes
          );
        IF SQL%ROWCOUNT != 1 THEN
          v_resp_id     := '21';
          p_errmsg      :='Insert not happen in CMS_TRANSACTION_LOG_DTL';
          RAISE exp_reject_record;
        END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_id := '89';
        p_errmsg  := 'Error while inserting in CMS_TRANSACTION_LOG_DTL ' || SUBSTR (SQLERRM, 1, 100);
      END;

      if v_minorcard then --Added for MVCSD-5381
        p_errmsg := 'Minor';
      end if;
  END IF;
EXCEPTION---Main Exception---
WHEN exp_reject_record THEN
ROLLBACK;

  /* commented for defect id:12285
  BEGIN
    SELECT CAM_ACCT_BAL,
      CAM_LEDGER_BAL
    INTO V_ACCT_BALANCE,
      V_LEDGER_BAL
    FROM CMS_ACCT_MAST
    WHERE CAM_INST_CODE=P_INST_CODE -- Added the inst code for review changes on 16/Aug/2013
      AND CAM_ACCT_NO =v_cap_acct_no;
  EXCEPTION
  WHEN OTHERS THEN
    v_resp_id := '21';
    p_errmsg  := 'Error while selecting Account Balance from CMS_ACCT_MAST-'|| SUBSTR (SQLERRM, 1, 200);
  END;
  */

  --Sn Added by Pankaj S. for SPIL Target registration
   IF p_delivery_channel='08' AND p_txn_code='30' THEN
   BEGIN
      SELECT DECODE (v_resp_id,
                     '143','22',
                     '65', '69',
                     '22', '13',
                     '35', '49',
                     '83', '49',
                     '75', '49',
                     '73', '49',
                     '32', '49',v_resp_id
                    )
        INTO v_resp_id
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS THEN
      
    
       p_errmsg :='Error while getting SPIL specific responses ' || SUBSTR (SQLERRM, 1, 300);
   END;
   END IF;
  --En Added by Pankaj S. for SPIL Target registration

  BEGIN
    SELECT CMS_ISO_RESPCDE
    INTO P_RESP_CODE
    FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE      = P_INST_CODE
    AND CMS_DELIVERY_CHANNEL = TO_NUMBER(P_DELIVERY_CHANNEL)
    AND CMS_RESPONSE_ID      = TO_NUMBER(v_resp_id);
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg  := p_errmsg||'Problem while selecting data from response master for respose code' || v_resp_id || SUBSTR(SQLERRM, 1, 300);
    v_resp_id := '21';
  END;


  -- commented for defect id:12285 -- uncommented for Spil_3.0 Changes

  IF     p_delivery_channel = '08'
     AND p_txn_code = '30'      -- if condition added for Spil_3.0 Changes
  THEN


      IF V_CAP_PROD_CODE IS NULL
      THEN

          BEGIN
            SELECT cap_prod_code,
              cap_acct_no,
              cap_card_type,
              cap_card_stat
            INTO v_cap_prod_code,
              v_cap_acct_no,
              v_cap_card_type,
              v_cap_card_stat
            FROM cms_appl_pan
            WHERE cap_inst_code      = p_inst_code
            AND cap_pan_code         = v_hash_pan;
          EXCEPTION
          WHEN OTHERS THEN
          null;
          END;

      END IF;

      if v_cap_acct_no is not null and v_acct_balance is null
      then

          BEGIN

            SELECT CAM_ACCT_BAL,
              CAM_LEDGER_BAL,
              cam_type_code
            INTO v_acct_balance,
              v_ledger_bal,v_type_code
            FROM CMS_ACCT_MAST
            WHERE CAM_INST_CODE=P_INST_CODE -- Added the inst code for review changes on 16/Aug/2013
              AND CAM_ACCT_NO =v_cap_acct_no;
          EXCEPTION
          WHEN OTHERS THEN
            V_ACCT_BALANCE := '0.00';
            V_LEDGER_BAL := '0.00';
          END;
      end if;

      if v_trans_desc is null
      then
          BEGIN
            SELECT ctm_tran_desc,ctm_credit_debit_flag
            INTO v_trans_desc,v_cr_dr_flag
            FROM cms_transaction_mast
            WHERE ctm_inst_code      = p_inst_code
            AND ctm_tran_code        = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel;

          EXCEPTION WHEN OTHERS THEN
          null;

          END;

      end if;

     v_time_stamp := systimestamp;

      BEGIN
        INSERT
        INTO TRANSACTIONLOG
          (
            RRN,
            TXN_CODE,
            MSGTYPE,
            BUSINESS_DATE,
            BUSINESS_TIME,
            CURRENCYCODE,
            PRODUCTID,
            categoryid,
            TRANS_DESC,
            INSTCODE,
            DELIVERY_CHANNEL,
            TXN_STATUS,
            RESPONSE_CODE,
            CUSTOMER_ACCT_NO,
            CUSTOMER_CARD_NO,
            CUSTOMER_CARD_NO_ENCR,
            PROXY_NUMBER,
            ACCT_BALANCE,
            LEDGER_BALANCE,
            CUSTOMER_STARTER_CARD_NO,
            response_id,
            error_msg,
            ipaddress,
            -- sn Added during spil_3.0 changes
            cr_dr_flag,
            cardstatus,
            time_stamp,
            amount,
            total_amount,
            acct_type
            -- en Added during spil_3.0 changes
          )
          VALUES
          (
            p_rrn,
            p_txn_code,
            '0200',
            p_business_date,
            p_business_time,
            v_curr_code,
            v_cap_prod_code,
            v_cap_card_type,
            v_trans_desc,
            p_inst_code,
            p_delivery_channel,
            DECODE(P_RESP_CODE, '00', 'C', 'F'),
            P_RESP_CODE,
            v_cap_acct_no,
            v_hash_pan,
            v_encr_pan,
            v_proxy_number,
            V_ACCT_BALANCE,
            V_LEDGER_BAL,
            v_hash_pan,
            v_resp_id,
            p_errmsg,
            p_ipaddress,
            -- sn Added during spil_3.0 changes
            v_cr_dr_flag,
            v_cap_card_stat,
            v_time_stamp,
            '0.00',
            '0.00',
            v_type_code
            -- en Added during spil_3.0 changes
          );
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_id := '89';
        p_errmsg  := 'Error while inserting in Transactionlog ' || SUBSTR (SQLERRM, 1, 100);
      END;

      BEGIN
        INSERT
        INTO CMS_TRANSACTION_LOG_DTL
          (
            CTD_DELIVERY_CHANNEL,
            CTD_TXN_CODE,
            CTD_MSG_TYPE,
            CTD_BUSINESS_DATE,
            CTD_BUSINESS_TIME,
            CTD_TXN_CURR,
            CTD_RRN,
            CTD_INST_CODE,
            CTD_PROCESS_FLAG,
            CTD_PROCESS_MSG,
            CTD_CUST_ACCT_NUMBER,
            CTD_CUSTOMER_CARD_NO,
            CTD_CUSTOMER_CARD_NO_ENCR
          )
          VALUES
          (
            p_delivery_channel,
            p_txn_code,
            '0200',
            p_business_date,
            p_business_time,
            v_curr_code,
            p_rrn,
            p_inst_code,
            'E',
            p_errmsg,
            v_cap_acct_no,
            v_hash_pan,
            v_encr_pan
          );
      EXCEPTION
      WHEN OTHERS THEN
        v_resp_id := '89';
        p_errmsg  := 'Error while inserting in CMS_TRANSACTION_LOG_DTL ' || SUBSTR (SQLERRM, 1, 100);
      END;
      --*/      -- uncommented for Spil_3.0 Changes
  END IF;
  
WHEN OTHERS THEN
  p_errmsg := 'Main Excp-' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERROR