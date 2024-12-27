CREATE OR REPLACE PROCEDURE VMSCMS.SP_KYC_CARD_GEN (
   prm_instcode       IN       NUMBER,
   prm_msg_type       IN       VARCHAR2,
   prm_rowid          IN       VARCHAR2,
   prm_rrn            IN       VARCHAR2,
   prm_stan           IN       VARCHAR2,
   prm_txn_code       IN       VARCHAR2,
   prm_tran_mode      IN       VARCHAR2,
   prm_delv_chnl      IN       VARCHAR2,
   prm_curr_code      IN       VARCHAR2,
   prm_kyc_flag       IN       VARCHAR2,
   prm_starter_card   IN       VARCHAR2,
   prm_tran_date      IN       VARCHAR2,
   prm_tran_time      IN       VARCHAR2,
   prm_lupduser       IN       NUMBER,
   prm_comment        IN       VARCHAR2,
   prm_reason         IN       VARCHAR2,
   prm_ipaddress      IN       VARCHAR2, --added aby amit on 07-Oct-2012
   prm_gpr_card       OUT      VARCHAR2,
   prm_acct_no        OUT      VARCHAR2,
   prm_cust_id        OUT      VARCHAR2,
   prm_resp_code      OUT      VARCHAR2,
   prm_errmsg         OUT      VARCHAR2,
   prm_pin_flag       OUT      VARCHAR2
)
AS


/*********************************************************************************************
  * VERSION           :  1.0
  * DATE OF CREATION  : 22/Aug/2012
  * PURPOSE           : To upload application and card generation
  * CREATED BY        : Sagar More
  * modified for      : SSN validations - New CR
  * modified Date     : 08-Feb-2013
  * modified reason   : 1) to check for thresholdlimit before pan generation
                        2) v_resp_code Datatype size change
                        
  * modified for      : SSN validations - New CR
  * modified Date     : 19-Feb-2013
  * modified reason   : 1) response id changed from 157 to 158 on 19-Feb-2013
  * Reviewer          : Dhiarj
  * Reviewed Date     : 08-Feb-2013
  * Build Number      : CMS3.5.1_RI0023.2_B0001
  
  * Modified By      : Pankaj S.
  * Modified Date    : 19-Mar-2013
  * Modified Reason  : Logging of system initiated card status change(FSS-390)
  * Reviewer         : Dhiraj
  * Reviewed Date    : 
  * Build Number     : CSR3.5.1_RI0024_B0007
  
  * Modified By      : Pankaj S.
  * Modified Date    : 28-Mar-2013
  * Modified Reason  :  To restict GPR generation for manual Cases(Mantis ID-10608)
  * Reviewer         : Dhiraj
  * Reviewed Date    : 
  * Build Number     : CSR3.5.1_RI0024_B0013

  * Modified By      : Sagar
  * Modified Date    : 29-Mar-2013
  * Modified For     : Defect 10756
  * Modified Reason  : Size of v_cust_id_ssn variable is change as per CMS_CUST_MAST.CCM_SSN%type
  * Reviewer         : Dhiraj
  * Reviewed Date    : 29-Mar-2013
  * Build Number     : CSR3.5.1_RI0024_B0014
  
  
  * Modified By      : Santosh k
  * Modified Date    : 26-08-2013
  * Modified For     : MVCSD-4099
  * Modified Reason  : Durbin changes
  * Reviewer         : Dhiraj
  * Reviewed Date    : 29-Mar-2013
  * Build Number     : RI0024.4_B0004

  * Modified By      : Santosh k
  * Modified Date    : 04-09-2013
  * Modified For     : Mantis-0012284 - KYC Fail response code always logged as 21 in transactionlog table and resp id also incorrect
  * Modified Reason  : For logging proper response code against error messages
  * Build Number     : RI0024.4_B0009

  * Modified By      : Dnyaneshwar J
  * Modified Date    : 18-09-2013
  * Modified For     : Mantis-0012284 - KYC Fail response code always logged as 21 in transactionlog table and resp id also incorrect
  * Modified Reason  : For logging proper response code against error messages
  * Build Number     : RI0024.4_B0016
  
  * Modified By      : Santosh k
  * Modified Date    : 10-02-2014
  * Modified For     : FSS-695
  * Modified Reason  : To allow multiple registration attempts
  * Build Number     : RI0027.1_B0001

  * Modified By      : Dnyaneshwar J
  * Modified Date    : 17-02-2014
  * Modified For     : Mantis-13694
  * Build Number     : RI0027.1_B0002
  
  * Modified By      : Dnyaneshwar J
  * Modified Date    : 18-02-2014
  * Modified For     : Mantis-13693
  * Build Number     : RI0027.1_B0004

  * Modified By      : Dnyaneshwar J
  * Modified Date    : 24-02-2014
  * Modified For     : Mantis-13737
  * Build Number     : RI0027.1_B0006

  * Modified By      : Dnyaneshwar J
  * Modified Date    : 18-03-2014
  * Modified For     : Mantis-13847
  * Reviewer         : Dhiraj
  * Reviewed Date    : 18-03-2014
  * Build Number     : RI0027.2_B0002
  
  * Modified Date    : 29-SEP-2014
  * Modified By      : Abdul Hameed M.A
  * Modified for     : FWR 70 & Review changes
  * Reviewer         : Spankaj
  * Release Number   : RI0027.4_B0002
  
  * Modified Date    :  30-Dec-2014
  * Modified By      :  Ramesh A
  * PURPOSE          :  Defect id :0015974
  * Reviewer         :     
  * Build Number     : 
  
  * Modified by                  : MageshKumar S.
  * Modified Date                : 23-June-15
  * Modified For                 : MVCAN-77
  * Modified reason              : Canada account limit check
  * Reviewer                     : Spankaj
  * Build Number                 : VMSGPRHOSTCSD3.1_B0001
  
  * Modified by                  : MageshKumar S.
  * Modified Date                : 02-August-2015
  * Modified For                 : FSS-2125
  * Modified reason              : KYC Override for GPR CARDS
  * Reviewer                     : Spankaj
  * Build Number                 : VMSGPRHOSTCSD3.1_B0008
  
      * Modified by           : Abdul Hameed M.A
      * Modified Date         : 06-Oct-15
      * Modified For          : FSS-3509 & FSS-1817
      * Reviewer              : Saravanankumar
      * Build Number          : VMSGPRHOSTCSD3.2_B0004  
      
      * Modified by           : Abdul Hameed M.A
      * Modified Date         : 06-Oct-15
      * Modified For          : 16203 
      * Reviewer              : Saravanankumar
      * Build Number          : VMSGPRHOSTCSD3.2_B0005  
      
      * Modified by           : Siva Kumar m
      * Modified Date         : 22-Mar-16
      * Modified For          : MVHOST-1323
      * Reviewer              : Saravanankumar/Pankaj
      * Build Number          : VMSGPRHOSTCSD_4.0_B0006
      
    * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
      * Modified By      : Ubaidur Rahman H
      * Modified Date    : 17-Jun-2019
      * Purpose          : VMS-959(Enhance CSD to support cardholder data search for Rewards products)
      * Reviewer         : Saravanakumar A. 
      * Release Number   : VMSGPRHOST_R17
	
**************************************************************************************************/

   v_errmsg                  transactionlog.error_msg%TYPE;
   v_appl_code               cms_caf_info_entry.cci_appl_code%TYPE;
   v_pan                     cms_appl_pan.cap_pan_code%TYPE;
   v_applproc_msg            transactionlog.error_msg%TYPE;
   v_hash_pan                cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cap_cust_code           cms_appl_pan.cap_cust_code%TYPE;
   v_comment                 cms_calllog_details.ccd_comments%type;
   v_spnd_acctno             cms_appl_pan.cap_acct_no%type;
   v_resp_code               transactionlog.response_code%TYPE; 
   v_acct_balance            cms_acct_mast.cam_acct_bal%type;
   v_ledger_bal              cms_acct_mast.cam_ledger_bal%type;
   v_dr_cr_flag              cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_tran_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
   v_cap_prod_code           cms_appl_pan.cap_prod_code%type;
   v_cap_card_type           cms_appl_pan.cap_card_type%type;
   v_cap_proxynumber         cms_appl_pan.cap_proxy_number%type;
   v_auth_id                 transactionlog.auth_id%type;
   v_call_id                 cms_calllog_mast.ccm_call_id%TYPE;
   v_hash_starter_pan        cms_appl_pan.cap_pan_code%TYPE;
   v_encr_starter_pan        cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cnt                     PLS_INTEGER;
   v_document_verify         cms_caf_info_entry.cci_document_verify%type;   
   v_cust_id_ssn             CMS_CUST_MAST.CCM_SSN%type;                  --Added on 29-Apr-2013 for Defect 10756
   v_cci_prod_code           cms_caf_info_entry.cci_prod_code%type;
   v_ssn_crddtls             transactionlog.ssn_fail_dtls%TYPE;
   v_strtogpr_flag           varchar2(3);  
   v_crdstat_chnge           VARCHAR2(2):='N'; --added by Pankaj S. for FSS-390    
   v_startogprissu_flag      cms_prod_cattype.cpc_startergpr_issue%type;  --added by Pankaj S. for Mantis ID-10608     
   v_cap_pin_flag            VARCHAR2(1):='N';--added by Santosh k for MVCSD-4099
  --SN:added by Santosh k for FSS-695
   V_CAP_APPL_CODE           CMS_APPL_PAN.CAP_APPL_CODE%type;
   V_ORIG_ROWID              CMS_CAF_INFO_ENTRY.CCI_ROW_ID%type;
   V_CCI_FIID                CMS_CAF_INFO_ENTRY.CCI_FIID%type;        
   V_CCI_SEG12_HOMEPHONE_NO  CMS_CAF_INFO_ENTRY.CCI_SEG12_HOMEPHONE_NO%type; 
   v_cci_seg12_name_line1    cms_caf_info_entry.cci_seg12_name_line1%type;
   V_CCI_SEG12_NAME_LINE2    CMS_CAF_INFO_ENTRY.CCI_SEG12_NAME_LINE2%type;
   v_cci_seg12_addr_line1    cms_caf_info_entry.cci_seg12_addr_line1%type;
   V_CCI_SEG12_ADDR_LINE2    CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE2%type;
   v_cci_seg12_city          cms_caf_info_entry.cci_seg12_city%type;
   V_CCI_SEG12_STATE         CMS_CAF_INFO_ENTRY.CCI_SEG12_STATE%type;
   v_cci_seg12_postal_code   cms_caf_info_entry.cci_seg12_postal_code%type;
   V_CCI_SEG12_COUNTRY_CODE  CMS_CAF_INFO_ENTRY.CCI_SEG12_COUNTRY_CODE%type;
   V_CCI_SEG12_MOBILENO      CMS_CAF_INFO_ENTRY.CCI_SEG12_MOBILENO%type;
   V_CCI_SEG12_EMAILID       CMS_CAF_INFO_ENTRY.CCI_SEG12_EMAILID%type;
   v_cci_requester_name      cms_caf_info_entry.cci_requester_name%type;
   v_cci_ssn                 cms_caf_info_entry.cci_ssn%type;
   V_CCI_BIRTH_DATE          CMS_CAF_INFO_ENTRY.CCI_BIRTH_DATE%type;
   v_cci_document_verify     cms_caf_info_entry.cci_document_verify%type;
   V_CCI_ENTRY_REC_TYPE      CMS_CAF_INFO_ENTRY.CCI_ENTRY_REC_TYPE%type;
   v_cci_instrument_realised cms_caf_info_entry.cci_instrument_realised%type;
   V_CCI_CUST_CATG           CMS_CAF_INFO_ENTRY.CCI_CUST_CATG%type;
   V_CCI_COMM_TYPE           CMS_CAF_INFO_ENTRY.CCI_COMM_TYPE%type;
   v_cci_seg13_addr_param9   cms_caf_info_entry.cci_seg13_addr_param9%type;
   V_CCI_TITLE               CMS_CAF_INFO_ENTRY.CCI_TITLE%type;
   v_cci_id_issuer           cms_caf_info_entry.cci_id_issuer%type;
   V_CCI_ID_NUMBER           CMS_CAF_INFO_ENTRY.CCI_ID_NUMBER%type;
   v_cci_seg13_addr_line1    cms_caf_info_entry.cci_seg13_addr_line1%type;
   V_CCI_SEG13_ADDR_LINE2    CMS_CAF_INFO_ENTRY.CCI_SEG13_ADDR_LINE2%type;
   v_cci_seg13_city          cms_caf_info_entry.cci_seg13_city%type;
   V_CCI_SEG13_STATE         CMS_CAF_INFO_ENTRY.CCI_SEG13_STATE%type;
   V_CCI_SEG13_POSTAL_CODE   CMS_CAF_INFO_ENTRY.CCI_SEG13_POSTAL_CODE%type;
   v_cci_seg13_country_code  cms_caf_info_entry.cci_seg13_country_code%type;
   V_CCI_ID_ISSUANCE_DATE    CMS_CAF_INFO_ENTRY.CCI_ID_ISSUANCE_DATE%type;
   V_CCI_ID_EXPIRY_DATE      CMS_CAF_INFO_ENTRY.CCI_ID_EXPIRY_DATE%type;
   v_cci_mothers_maiden_name cms_caf_info_entry.cci_mothers_maiden_name%type;
   v_cci_card_type           cms_caf_info_entry.cci_card_type%type;
   V_CCI_SEG12_STATE_CODE    CMS_CAF_INFO_ENTRY.CCI_SEG12_STATE_CODE%type;
   V_CCI_SEG13_STATE_CODE    CMS_CAF_INFO_ENTRY.CCI_SEG13_STATE_CODE%TYPE;
   v_cci_kyc_flag            CMS_CAF_INFO_ENTRY.CCI_KYC_FLAG%TYPE;--Added by Dnyaneshwar J on 10 Mar 2014 for Mantis-13847
  --EN:added by Santosh k for FSS-695
  --Sn:Added for VMS-959
  v_cci_seg12_name_line1_encr    cms_caf_info_entry.cci_seg12_name_line1_encr%type;
  v_cci_seg12_name_line2_encr    cms_caf_info_entry.cci_seg12_name_line2_encr%type;
  v_cci_seg12_addr_line1_encr    cms_caf_info_entry.cci_seg12_addr_line1_encr%type;
  v_cci_seg12_addr_line2_encr    cms_caf_info_entry.cci_seg12_addr_line2_encr%type;
  v_cci_seg12_city_encr          cms_caf_info_entry.cci_seg12_city_encr%type;
  v_cci_seg12_postal_code_encr   cms_caf_info_entry.cci_seg12_postal_code_encr%type;
  v_cci_seg12_emailid_encr       cms_caf_info_entry.cci_seg12_emailid_encr%type;
  --En:Added for VMS-959
  --SN Added for FWR 70 
   V_CURRENCY_CODE            transactionlog.tran_curr%TYPE;
   V_GPR_OPTIN                CMS_TRANSACTION_LOG_DTL.CTD_GPR_OPTIN%TYPE:='Y';
  --EN Added for FWR 70
   v_pan_number               VARCHAR2(20); --Added for Defect id :0015974
   exp_reject_record          EXCEPTION;

BEGIN

   V_ERRMSG  := 'OK';
   V_ORIG_ROWID:=prm_rowid;   --added by Santosh k for FSS-695

   BEGIN

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
            v_errmsg :=
                  'Transaction detail is not found in master for txn code '
               || prm_txn_code
               || 'delivery channel '
               || prm_delv_chnl;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_errmsg :=
                  'Problem while selecting debit/credit flag '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
  
--SN:added by Santosh k for FSS-695     

  IF prm_txn_code = '24' AND prm_delv_chnl = '03' THEN

  BEGIN
    SELECT cci_fiid,
      cci_seg12_homephone_no,
      cci_seg12_name_line1,
      cci_seg12_name_line2,
      cci_seg12_addr_line1,
      cci_seg12_addr_line2 ,
      cci_seg12_city,
      cci_seg12_state,
      cci_seg12_postal_code,
      cci_seg12_country_code,
      cci_seg12_mobileno,
      cci_seg12_emailid,
      cci_prod_code,
      cci_requester_name,
      nvl(fn_dmaps_main(cci_ssn_encr),cci_ssn),
      cci_birth_date,
      cci_document_verify,
      cci_entry_rec_type,
      cci_instrument_realised,
      cci_cust_catg,
      cci_comm_type,
      cci_seg13_addr_param9,
      cci_title,
      cci_id_issuer,
      nvl(fn_dmaps_main(cci_id_number_encr),cci_id_number),
      cci_seg13_addr_line1,
      cci_seg13_addr_line2,
      cci_seg13_city,
      cci_seg13_state,
      cci_seg13_postal_code,
      cci_seg13_country_code,
      cci_id_issuance_date,
      cci_id_expiry_date,
      cci_mothers_maiden_name,
      cci_card_type,
      cci_seg12_state_code,
      CCI_SEG13_STATE_CODE,
      CCI_KYC_FLAG,--Added by Dnyaneshwar J on 10 Mar 2014 for Mantis-13847
      --Sn:Added for VMS-959
      cci_seg12_name_line1_encr,
      cci_seg12_name_line2_encr,
      cci_seg12_addr_line1_encr,
      cci_seg12_addr_line2_encr,
      cci_seg12_city_encr, 
      cci_seg12_postal_code_encr,
      cci_seg12_emailid_encr
      --En:Added for VMS-959
    into V_CCI_FIID,
      V_CCI_SEG12_HOMEPHONE_NO,
      V_CCI_SEG12_NAME_LINE1,
      V_CCI_SEG12_NAME_LINE2,
      V_CCI_SEG12_ADDR_LINE1,
      V_CCI_SEG12_ADDR_LINE2 ,
      V_CCI_SEG12_CITY,
      v_cci_seg12_state,
      V_CCI_SEG12_POSTAL_CODE,
      V_CCI_SEG12_COUNTRY_CODE,
      V_CCI_SEG12_MOBILENO,
      V_CCI_SEG12_EMAILID,
      V_CCI_PROD_CODE,
      V_CCI_REQUESTER_NAME,
      V_CCI_SSN,
      V_CCI_BIRTH_DATE,
      V_CCI_DOCUMENT_VERIFY,
      V_CCI_ENTRY_REC_TYPE,
      V_CCI_INSTRUMENT_REALISED,
      V_CCI_CUST_CATG,
      V_CCI_COMM_TYPE,
      V_CCI_SEG13_ADDR_PARAM9,
      V_CCI_TITLE,
      V_CCI_ID_ISSUER,
      V_CCI_ID_NUMBER,
      V_CCI_SEG13_ADDR_LINE1,
      v_CCI_SEG13_ADDR_LINE2,
      V_CCI_SEG13_CITY,
      V_CCI_SEG13_STATE,
      V_CCI_SEG13_POSTAL_CODE,
      V_CCI_SEG13_COUNTRY_CODE,
      V_CCI_ID_ISSUANCE_DATE,
      V_CCI_ID_EXPIRY_DATE,
      V_CCI_MOTHERS_MAIDEN_NAME,
      V_CCI_CARD_TYPE,
      V_CCI_SEG12_STATE_CODE,
      V_CCI_SEG13_STATE_CODE,
      v_cci_kyc_flag,--Added by Dnyaneshwar J on 10 Mar 2014 for Mantis-13847
      --Sn:Added for VMS-959
      v_cci_seg12_name_line1_encr,    
      v_cci_seg12_name_line2_encr,   
      v_cci_seg12_addr_line1_encr,   
      V_cci_seg12_addr_line2_encr,   
      v_cci_seg12_city_encr,         
      v_cci_seg12_postal_code_encr,  
      v_cci_seg12_emailid_encr  
      --En:Added for VMS-959
    FROM cms_caf_info_entry
    where CCI_ROW_ID= V_ORIG_ROWID
    AND CCI_INST_CODE   = PRM_INSTCODE;
             
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_RESP_CODE := '49';
    v_errmsg    := 'No data found for rowid - '||V_ORIG_ROWID;
    RAISE exp_reject_record;
  WHEN OTHERS THEN
    v_resp_code := '21';
    v_errmsg    := 'Error while selecting application detail - for rowid - '||V_ORIG_ROWID || SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  end;
  
  
BEGIN--sn Added by Dnyaneshwar J on 18 Sept 2013 for Mantis-12284
  v_hash_starter_pan := gethash(prm_starter_card);
EXCEPTION
WHEN OTHERS THEN
  v_resp_code := '21';
  v_errmsg    := 'Error while converting into hash pan ' || SUBSTR (SQLERRM, 1, 100);
  RAISE exp_reject_record;
end;
BEGIN
  v_encr_starter_pan := fn_emaps_main(prm_starter_card);
EXCEPTION
WHEN OTHERS THEN
  v_resp_code := '21';
  v_errmsg    := 'Error while converting into encrypt pan ' || SUBSTR (SQLERRM, 1, 100);
  RAISE exp_reject_record;
end;
BEGIN
  SELECT cap_pan_code,
    cap_cust_code,
    cap_pan_code_encr,
    cap_acct_no,
    cap_prod_code,
    cap_card_type,
    CAP_PROXY_NUMBER,
    DECODE(CAP_PIN_OFF,null,'N','Y'),--added by Santosh k for MVCSD-4099
    CAP_APPL_CODE
  INTO v_hash_pan,
    v_cap_cust_code,
    v_encr_pan,
    v_spnd_acctno,
    v_cap_prod_code,
    v_cap_card_type,
    V_CAP_PROXYNUMBER,
    V_CAP_PIN_FLAG,--added by Santosh k for MVCSD-4099
    V_CAP_APPL_CODE
  FROM cms_appl_pan
  WHERE cap_inst_code = prm_instcode
  AND cap_pan_code    = gethash(prm_starter_card);
  prm_acct_no        := v_spnd_acctno;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  v_resp_code := '16';
  v_errmsg    := 'Invalid starter pan for rowid - '||V_ORIG_ROWID;
  RAISE exp_reject_record;
WHEN OTHERS THEN
  v_resp_code := '21';
  v_errmsg    := 'Error while selecting Starter card details - for applcode ' ||v_appl_code || SUBSTR (SQLERRM, 1, 200);
  RAISE exp_reject_record;
END;--en Added by Dnyaneshwar J on 18 Sept 2013 for Mantis-12284
  
--SN Added for FWR 70  
BEGIN

vmsfunutilities.get_currency_code(v_cap_prod_code,v_cap_card_type,prm_instcode,V_CURRENCY_CODE,v_errmsg);
      
      if v_errmsg<>'OK' then
           raise exp_reject_record;
      end if;
  EXCEPTION
    WHEN exp_reject_record then
     RAISE ;
    WHEN OTHERS THEN
     v_resp_code := '21';
     v_errmsg   := 'Error While selecting the Currency code' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE exp_reject_record;
  end;
  --EN Added for FWR 70
  
  BEGIN
    SELECT CCI_ROW_ID INTO V_ORIG_ROWID
    from CMS_CAF_INFO_ENTRY
    where CCI_INST_CODE= PRM_INSTCODE
    and CCI_APPL_CODE  = V_CAP_APPL_CODE;
    
    IF V_ORIG_ROWID  IS NULL THEN
       V_RESP_CODE := '49';
       v_errmsg    := 'No row id found for application detail';
       RAISE exp_reject_record;
    end if;
        
  EXCEPTION
  WHEN exp_reject_record THEN
       RAISE; 
  WHEN NO_DATA_FOUND THEN
    V_RESP_CODE := '49';
    v_errmsg    := 'No data found for application detail - '|| SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_record;
  WHEN OTHERS THEN
    V_RESP_CODE := '21';
    v_errmsg    := 'Error while selecting application detail - '|| SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  end;
  
  
  BEGIN
    UPDATE cms_caf_info_entry
    SET cci_fiid                 = v_cci_fiid,
      cci_seg12_homephone_no     = v_cci_seg12_homephone_no,
      cci_seg12_name_line1       = v_cci_seg12_name_line1,
      cci_seg12_name_line2       = v_cci_seg12_name_line2,
      cci_seg12_addr_line1       = v_cci_seg12_addr_line1,
      cci_seg12_addr_line2       = v_cci_seg12_addr_line2,
      cci_seg12_city             = v_cci_seg12_city,
      cci_seg12_state            = v_cci_seg12_state,
      cci_seg12_postal_code      = v_cci_seg12_postal_code ,
      cci_seg12_country_code     = v_cci_seg12_country_code,
      cci_seg12_mobileno         = v_cci_seg12_mobileno,
      cci_seg12_emailid          = v_cci_seg12_emailid,
      CCI_PROD_CODE              = V_CCI_PROD_CODE,
      CCI_REQUESTER_NAME         = V_CCI_REQUESTER_NAME,
      CCI_SSN                    = fn_maskacct_ssn(prm_instcode,DECODE(V_CCI_DOCUMENT_VERIFY,'SSN',V_CCI_SSN,'SIN',V_CCI_SSN,NULL),0), --Modified for FWR 70
      cci_ssn_encr               = fn_emaps_main(DECODE(V_CCI_DOCUMENT_VERIFY,'SSN',V_CCI_SSN,'SIN',V_CCI_SSN,NULL)),
      CCI_BIRTH_DATE             = V_CCI_BIRTH_DATE,
      cci_document_verify        = v_cci_document_verify,
      CCI_LUPD_DATE              = sysdate,
      cci_entry_rec_type         = v_cci_entry_rec_type,
      cci_instrument_realised    = v_cci_instrument_realised,
      cci_cust_catg              = v_cci_cust_catg,
      CCI_COMM_TYPE              = V_CCI_COMM_TYPE,
      CCI_SEG13_ADDR_PARAM9      = V_CCI_SEG13_ADDR_PARAM9,
      CCI_TITLE                  = V_CCI_TITLE,
      CCI_ID_ISSUER              = DECODE(V_CCI_DOCUMENT_VERIFY,'SSN',NULL,'SIN',NULL,V_CCI_ID_ISSUER),                                 --Modified for FWR 70
      cci_id_number              = fn_maskacct_ssn(prm_instcode,DECODE(v_cci_document_verify,'SSN',NULL,'SIN',NULL,v_cci_id_number),0), --Modified for FWR 70
      cci_id_number_encr         = fn_emaps_main(DECODE(v_cci_document_verify,'SSN',NULL,'SIN',NULL,v_cci_id_number)),
      cci_seg13_addr_line1       = v_cci_seg13_addr_line1,
      cci_seg13_addr_line2       = v_cci_seg13_addr_line2,
      cci_seg13_city             = v_cci_seg13_city,
      cci_seg13_state            = v_cci_seg13_state,
      cci_seg13_postal_code      = v_cci_seg13_postal_code,
      CCI_SEG13_COUNTRY_CODE     = V_CCI_SEG13_COUNTRY_CODE,
      CCI_ID_ISSUANCE_DATE       = DECODE(V_CCI_DOCUMENT_VERIFY,'SSN',NULL,'SIN',NULL,V_CCI_ID_ISSUANCE_DATE), --Modified for FWR 70
      cci_id_expiry_date         = DECODE(v_cci_document_verify,'SSN',NULL,'SIN',NULL,v_cci_id_expiry_date),   --Modified for FWR 70
      cci_mothers_maiden_name    = v_cci_mothers_maiden_name,
      cci_card_type              = v_cci_card_type,
      CCI_SEG12_STATE_CODE       = V_CCI_SEG12_STATE_CODE,
      CCI_SEG13_STATE_CODE       = V_CCI_SEG13_STATE_CODE,
      CCI_PAN_CODE               = V_HASH_STARTER_PAN,--Added by Dnyaneshwar J on 17 Feb 2014 Mantis-13694
      cci_pan_code_encr          = v_encr_starter_pan,--Added by Dnyaneshwar J on 17 Feb 2014 Mantis-13694
      --Sn: Added for VMS-959
      cci_seg12_name_line1_encr  = v_cci_seg12_name_line1_encr,
      cci_seg12_name_line2_encr  = v_cci_seg12_name_line2_encr,
      cci_seg12_addr_line1_encr  = v_cci_seg12_addr_line1_encr,
      cci_seg12_addr_line2_encr  = v_cci_seg12_addr_line2_encr,
      cci_seg12_city_encr        = v_cci_seg12_city_encr ,
      cci_seg12_postal_code_encr = v_cci_seg12_postal_code_encr,
      cci_seg12_emailid_encr     = v_cci_seg12_emailid_encr
      --En: Added for VMS-959
    WHERE CCI_ROW_ID             = V_ORIG_ROWID
    AND CCI_INST_CODE            = prm_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    V_RESP_CODE := '21';
    V_ERRMSG    :=SQLERRM;
    V_ERRMSG    := 'Error while updating application details for rowid - '|| V_ORIG_ROWID || SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  end;
end if;

--EN:added by Santosh k for FSS-695
     ---------------------------------------------- 
     --SN:Added on 08-Feb-2013 for SSN validation 
     ----------------------------------------------     
      
          BEGIN
          
                select CCI_DOCUMENT_VERIFY,
                       DECODE(CCI_DOCUMENT_VERIFY,'SSN',nvl(fn_dmaps_main(CCI_SSN_encr),cci_ssn),'SIN',nvl(fn_dmaps_main(CCI_SSN_encr),cci_ssn),nvl(fn_dmaps_main(CCI_ID_NUMBER_encr),cci_id_number)),  --Modified for FWR 70
                       cci_prod_code,cci_kyc_flag
                into   v_document_verify,
                       V_CUST_ID_SSN,
                       v_cci_prod_code,v_cci_kyc_flag
                from  CMS_CAF_INFO_ENTRY 
                WHERE CCI_ROW_ID = V_ORIG_ROWID
                for update;                                   --SN:Added by Dnyaneshwar J on 10 Mar 2014 for Mantis-13847
          
                IF v_cci_kyc_flag IN ('Y','P','O','I')        --SN:Added by Dnyaneshwar J on 10 Mar 2014 for Mantis-13847
                THEN
                V_RESP_CODE := '217';
                v_errmsg    := 'KYC Override Already Done For This Record ';
                RAISE EXP_REJECT_RECORD;
                END IF;                                      --EN:Added by Dnyaneshwar J on 10 Mar 2014 for Mantis-13847
                
                IF(V_CURRENCY_CODE <>'124') THEN             --Added for FWR 70
               if v_document_verify is null
               then
               
                v_resp_code := '49';
                v_errmsg := 'Invalid document type code';
                RAISE exp_reject_record;  
                
               end if; 
               
                   if v_document_verify ='SSN' and v_cust_id_ssn is null
                   then 
                    
                        v_resp_code := '49';
                        v_errmsg := 'Invalid SSN';
                        RAISE exp_reject_record;  
                            
                   elsif v_document_verify <> 'SSN' and v_cust_id_ssn is null
                   then
                    
                        v_resp_code := '49';
                        v_errmsg := 'Invalid ID number';
                        RAISE exp_reject_record;  
                         
                   
                   end if;        --Added for FWR 70   
               
           END IF;
          EXCEPTION when exp_reject_record
          then
              raise;
          
          WHEN NO_DATA_FOUND
          THEN
                v_resp_code := '49';
                v_errmsg := 'Rowid not found '||V_ORIG_ROWID;
                RAISE exp_reject_record;
                
          WHEN OTHERS
          THEN
                v_resp_code := '21';
                v_errmsg := 'Problem while selecting document type for rowid '||V_ORIG_ROWID||' '|| SUBSTR (SQLERRM, 1, 100);    
                   RAISE exp_reject_record;                  
          END;
          
      IF(V_CURRENCY_CODE <>'124') THEN --Added for FWR 70
       BEGIN
       
          select decode(prm_txn_code,'23',null,'24','SG') into v_strtogpr_flag from dual;
       
          sp_check_ssn_threshold (prm_instcode,
                                  v_cust_id_ssn,
                                  v_cci_prod_code,
                                  V_CCI_CARD_TYPE,
                                  v_strtogpr_flag,--Starter To GPR flag
                                  v_ssn_crddtls,
                                  v_resp_code,
                                  v_errmsg,null   -- Added for MVCAN-77
                                 );

          IF v_errmsg <> 'OK'
          THEN
             v_resp_code := '158'; -- response id changed from 157 to 158 on 19-Feb-2013
             
             RAISE exp_reject_record;
             
          END IF;
          
       EXCEPTION
          WHEN exp_reject_record
          THEN
             RAISE;
          WHEN OTHERS
          THEN
             v_resp_code := '21';
             v_errmsg := 'Error from SSN check- ' || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
       END;        
      
     ---------------------------------------------- 
     --EN:Added on 08-Feb-2013 for SSN validation 
     ----------------------------------------------     
      
end if;  --Added for FWR 70

      IF prm_txn_code = '24' AND prm_delv_chnl = '03'
      then
           
          BEGIN
            sp_check_starter_card(prm_instcode,
                                  prm_starter_card,
                                  prm_txn_code,
                                  PRM_DELV_CHNL,
                                  v_resp_code,--Added by Santosh K on 04 Sept 2013 For Mantis-0012284
                                  v_errmsg
                                 );

            IF v_errmsg <> 'OK'
            then
               RAISE exp_reject_record;
            END IF;

          EXCEPTION WHEN exp_reject_record
          THEN
              Raise;

          WHEN OTHERS
             THEN

             v_resp_code := '21';
             v_errmsg :=
                      'Error while calling check starter card prcoess '
                      || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;

          END;

      END IF;


      BEGIN

         UPDATE cms_caf_info_entry
            set CCI_KYC_FLAG = 'O',
            CCI_OVERRIDE_FLAG = 1                                           --SN:added by Santosh k for FSS-695
          WHERE cci_inst_code = prm_instcode AND cci_row_id = V_ORIG_ROWID; --SN:modify by Santosh k for FSS-695
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_errmsg :=
                  'Error while updating KYC Registration-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      
  
        IF prm_txn_code = '23' AND prm_delv_chnl = '03'
          THEN
          
          IF prm_starter_card IS NULL THEN                                --condition added for FSS-2125

         BEGIN
            SP_ENTRY_NEWCAF_PCMS_ROWID (PRM_INSTCODE,
                                        V_ORIG_ROWID,                     --SN:modify by Santosh k for FSS-695
                                        prm_lupduser,
                                        v_errmsg
                                       );

            IF v_errmsg <> 'OK'
            THEN
               v_resp_code := '21';
               v_errmsg :=
                       'Error from Entry_newcaf_pcms_rowid: ' || v_errmsg;
               RAISE exp_reject_record;
            END IF;

         EXCEPTION when exp_reject_record
         then
             Raise;

         WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_errmsg :=
                     'Error while calling sp_entry_newcaf_pcms_rowid-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN

             SELECT cci_appl_code
               INTO v_appl_code
               from CMS_CAF_INFO_ENTRY
              WHERE cci_inst_code = prm_instcode AND cci_row_id = V_ORIG_ROWID;           --SN:modify by Santosh k for FSS-695

              If  v_appl_code is null
              then
                v_resp_code := '49';
                v_errmsg := 'Application code not found for rowid';
                RAISE exp_reject_record;
              end if;

         EXCEPTION
	     WHEN exp_reject_record THEN
	        RAISE;
             WHEN NO_DATA_FOUND
             THEN
                v_resp_code := '49';
                v_errmsg := 'Application code not found for rowid - '||V_ORIG_ROWID;
                RAISE exp_reject_record;

             WHEN OTHERS
             THEN
                v_resp_code := '21';
                v_errmsg :=
                      'Error while selecting application detail - for rowid - '||V_ORIG_ROWID
                   || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
         END;


          BEGIN
             sp_gen_pan (prm_instcode,
                         v_appl_code,
                         prm_lupduser,
                         v_pan,
                         v_applproc_msg,
                         v_errmsg
                        );
                        
               v_errmsg := v_applproc_msg;         

             IF v_errmsg <> 'OK'
             THEN
                v_resp_code := '21';
                v_errmsg := 'Error from pan generation: ' || v_errmsg;
                RAISE exp_reject_record;
             END IF;


          EXCEPTION when exp_reject_record
          then
               raise;

          WHEN OTHERS
             THEN
                v_resp_code := '21';
                v_errmsg :=
                    'Error while calling sp_gen_pan -' || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
          END;
          
          
          else
          
              --Start Block moved from bottom to top for FSS-2125
             BEGIN

                 SELECT cci_appl_code
                   INTO v_appl_code
                   from CMS_CAF_INFO_ENTRY
                  WHERE cci_inst_code = prm_instcode AND cci_row_id = V_ORIG_ROWID;        --SN:modify by Santosh k for FSS-695

                  If  v_appl_code is null
                  then
                    v_resp_code := '49';
                    v_errmsg := 'During starter_to_gpr Application code not found for rowid';
                    RAISE exp_reject_record;
                  end if;

              EXCEPTION
	         WHEN exp_reject_record THEN
		   RAISE;
                 WHEN NO_DATA_FOUND
                 THEN
                    v_resp_code := '49';
                    v_errmsg := 'During starter_to_gpr Application code not found for rowid - '||V_ORIG_ROWID;
                    RAISE exp_reject_record;

                 WHEN OTHERS
                 THEN
                    v_resp_code := '21';
                    v_errmsg :=
                          'During starter_to_gpr Error while selecting application detail - for rowid - '||V_ORIG_ROWID
                       || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
              END;
            --End Block moved from bottom to top for FSS-2125
          END IF; --condition added for FSS-2125

          ELSIF prm_txn_code = '24' AND prm_delv_chnl = '03'
          then
          --SN Added for FWR 70
              IF(V_CURRENCY_CODE ='124') THEN
              begin
              select CTD_GPR_OPTIN into V_GPR_OPTIN from (select CTD_GPR_OPTIN
              from CMS_TRANSACTION_LOG_DTL
              where
              CTD_CUSTOMER_CARD_NO=V_HASH_STARTER_PAN
              and CTD_INST_CODE=prm_instcode order by CTD_INS_DATE desc) where rownum=1 ;
              EXCEPTION
               when OTHERS then
                v_resp_code := '21';
                V_ERRMSG := 'Error while selecting V_GPR_OPTIN '||substr(sqlerrm,1,200);
                RAISE exp_reject_record;
            end;
            END IF;

            --EN Added for FWR 70


         BEGIN
            SP_ENTRY_NEWCAF_STARTER_TO_GPR (PRM_INSTCODE,
                                            V_ORIG_ROWID,               --SN:modify by Santosh k for FSS-695
                                            prm_starter_card,
                                            prm_lupduser,
                                            v_errmsg
                                           );

            IF v_errmsg <> 'OK'
            THEN
               v_resp_code := '21';
               v_errmsg := 'Error from Entry_Newcaf_starter_to_gpr: ' || v_errmsg;
               RAISE exp_reject_record;
            END IF;

         EXCEPTION WHEN exp_reject_record
         THEN
             Raise;

         WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_errmsg :=
                     'Error while calling Entry_Newcaf_starter_to_gpr -'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
--Start block moved to top for FSS-2125
             BEGIN

             SELECT cci_appl_code
               INTO v_appl_code
               from CMS_CAF_INFO_ENTRY
              WHERE cci_inst_code = prm_instcode AND cci_row_id = V_ORIG_ROWID;        --SN:modify by Santosh k for FSS-695

              If  v_appl_code is null
              then
	       V_RESP_CODE := '49';
	       v_errmsg    := 'During starter_to_gpr Appl code not found for rowid';
	       RAISE exp_reject_record;
              end if;

            EXCEPTION
	    WHEN exp_reject_record THEN
	        RAISE;
             WHEN NO_DATA_FOUND
             THEN
                v_resp_code := '49';
                v_errmsg := 'During starter_to_gpr Application code not found for rowid - '||V_ORIG_ROWID;
                RAISE exp_reject_record;

                 WHEN OTHERS
                 THEN
                    v_resp_code := '21';
                    v_errmsg :=
                          'During starter_to_gpr Error while selecting application detail - for rowid - '||V_ORIG_ROWID
                       || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
              END; --End block moved to top for FSS-2125

            --Sn Added by Pankaj S. for Mantis ID -10608 to get starter to GPR issue flag
            BEGIN
             SELECT NVL(CPC_STARTERGPR_ISSUE,'A')
               INTO v_startogprissu_flag
               FROM CMS_PROD_CATTYPE,
                    CMS_APPL_PAN
              WHERE CAP_INST_CODE  = prm_instcode
              AND CAP_appl_CODE=v_appl_code
              AND CPC_PROD_CODE  = CAP_PROD_CODE
              AND CPC_CARD_TYPE  = CAP_CARD_TYPE;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_resp_code := '16';
                  v_errmsg := 'Product category not found';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_resp_code := '21';
                  v_errmsg :=
                        'Error while selecting product category details -'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
            --En Added by Pankaj S. for Mantis ID -10608 to get starter to GPR issue flag

             IF UPPER(V_GPR_OPTIN)='Y' AND  --Added for FWR 70
             v_startogprissu_flag = 'A' THEN   --added by Pankaj S. for Mantis ID -10608 to restrict the GPR card generation for manual cases
             BEGIN   --Added on 23Nov2012 for FSS - 817 DEFECT

            UPDATE CMS_APPL_MAST
              SET CAM_APPL_STAT   = 'A',
                 CAM_LUPD_USER    = Prm_LUPDUSER
            WHERE CAM_INST_CODE   = Prm_INSTCODE
            AND CAM_APPL_CODE     = v_appl_code
            and CAM_APPL_STAT     = 'O';

            if sql%rowcount = 0
            then
             
             v_resp_code := '21'; -- added on 28Nov2012
             V_ERRMSG := 'Record not updated in appl mast for appl code ' ||v_appl_code;
             RAISE exp_reject_record;

            end if;

         EXCEPTION when exp_reject_record
          then
              raise;

            WHEN OTHERS THEN
             v_resp_code := '21'; -- added on 28Nov2012
             V_ERRMSG := 'Error while updating appl mast  ' ||
                       SUBSTR(SQLERRM, 1, 200);
             RAISE exp_reject_record;
         END;
          

          BEGIN
             sp_gen_pan_starter_to_gpr (prm_instcode,
                         v_appl_code,
                         prm_lupduser,
                         v_pan,
                         v_applproc_msg,
                         v_errmsg
                        );
                        
                  v_errmsg := v_applproc_msg;      

             IF v_errmsg <> 'OK'
             THEN
                v_resp_code := '21';
                v_errmsg := 'Error from starter_to_gpr: ' || v_errmsg;
                RAISE exp_reject_record;
             END IF;

          EXCEPTION when exp_reject_record
          then
               raise;

          WHEN OTHERS
             THEN
                v_resp_code := '21';
                v_errmsg :=
                    'Error while calling starter_to_gpr-' || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
          END;
      END IF;
      --SN Added for FWR 70
else

 begin
    update cms_appl_mast set CAM_STARTER_CARD= 'Y' where
            CAM_APPL_CODE = v_appl_code and CAM_INST_CODE=prm_instcode;
                if sql%ROWCOUNT = 0 then
                v_resp_code := '21';
                V_ERRMSG :=
                     'Error while Updating cms_appl_mast v_appl_code:'
                  || v_appl_code;
               RAISE exp_reject_record;
                END IF;

            EXCEPTION
            WHEN exp_reject_record THEN
            RAISE exp_reject_record;
            WHEN OTHERS
            then
                v_resp_code := '21';
               V_ERRMSG :=
                     'Error while Updating cms_appl_mast'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
          end;
          
      BEGIN
            update CMS_ACCT_MAST
               SET cam_hold_count = cam_hold_count - 1,
                   cam_lupd_user = prm_lupduser
             WHERE cam_inst_code = prm_instcode AND cam_acct_no = v_spnd_acctno;

            IF SQL%ROWCOUNT = 0
            then
                v_resp_code := '21';
               V_ERRMSG :=
                       'Error while update acct '; --|| SUBSTR (SQLERRM, 1, 200);--Commented for review comments FWR 70
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            then
               v_resp_code := '21';
               v_errmsg :=
                       'Error while update acct ' || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
         end;     
end if;
--EN Added for FWR 70
        IF PRM_TXN_CODE = '23' AND prm_delv_chnl= '03'
        THEN
             BEGIN

                SELECT cap_pan_code,
                       cap_cust_code,
                       cap_pan_code_encr,
                       cap_acct_no,
                       cap_prod_code,
                       cap_card_type,
                       cap_proxy_number,
                       cap_mask_pan,
                       fn_dmaps_main (cap_pan_code_encr),  --Added for Defect id :0015974
                       DECODE(CAP_PIN_OFF,null,'N','Y') --added for FSS-2125
                  INTO v_hash_pan,
                       v_cap_cust_code,
                       v_encr_pan,
                       v_spnd_acctno,
                       v_cap_prod_code,
                       v_cap_card_type,
                       v_cap_proxynumber,
                       prm_gpr_card,
                       v_pan_number,  --Added for Defect id :0015974
                       V_CAP_PIN_FLAG --added for FSS-2125
                  FROM cms_appl_pan
                 WHERE cap_inst_code = prm_instcode
                 AND cap_appl_code = v_appl_code
                 AND cap_startercard_flag = 'N';

                  prm_acct_no := v_spnd_acctno;

             EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                   v_resp_code := '100';
                   v_errmsg := 'GPR card details not found for application code - '||v_appl_code|| ' for rowid - '||V_ORIG_ROWID;
                   RAISE exp_reject_record;
                WHEN OTHERS
                THEN
                   v_resp_code := '21';
                   v_errmsg :=
                         'Error while selecting GPR card details - for applcode '
                         ||v_appl_code
                         || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;

             END;

        ELSIF PRM_TXN_CODE = '24' AND prm_delv_chnl= '03'
        then

        if UPPER(V_GPR_OPTIN)='Y' then  --Added for FWR 70
             BEGIN

                   SELECT cap_mask_pan,cap_cust_code,fn_dmaps_main (cap_pan_code_encr),cap_prod_code  --Added for Defect id :0015974
                   INTO prm_gpr_card,v_cap_cust_code,v_pan_number,v_cap_prod_code  --Added for Defect id :0015974
                   FROM cms_appl_pan
                   WHERE cap_inst_code = prm_instcode
                   AND cap_acct_no = v_spnd_acctno
                   AND cap_startercard_flag = 'N'
                   AND cap_appl_code = v_appl_code;

             EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;

                WHEN OTHERS
                THEN
                   v_resp_code := '21';
                   v_errmsg :=
                         'Error while selecting GPR card - for applcode '
                         ||v_appl_code
                         || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;

             end;
         end if; --Added for FWR 70
        END IF;


      --AVQ Added for Defect id :0015974
      if v_pan_number is not null then
        BEGIN                
          SP_LOGAVQSTATUS(
                prm_instcode,
                prm_delv_chnl,
                v_pan_number,
                v_cap_prod_code,
                v_cap_cust_code,
                v_resp_code,
                v_errmsg,
                v_cap_card_type
                );
            IF v_errmsg <> 'OK' THEN
               v_errmsg  := 'Exception while calling LOGAVQSTATUS-- ' || v_errmsg;
               v_resp_code := '21';
              RAISE exp_reject_record;         
             END IF;
        EXCEPTION WHEN exp_reject_record
        THEN  RAISE;
        WHEN OTHERS THEN
           v_errmsg  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
           v_resp_code := '21';
           RAISE exp_reject_record;
        END;  
      END IF;
        --End  Added for Defect id :0015974
        

        if prm_txn_code = '23' AND prm_delv_chnl = '03'
        then

           BEGIN

              update cms_fileupload_detl
              set cfu_pan_code=v_hash_pan,
                  cfu_pan_code_encr=v_encr_pan,
                  cfu_acct_no=v_spnd_acctno,
                  CFU_DELIVERY_CHANNEL=prm_delv_chnl,
                  cfu_rrn=prm_rrn,
                  cfu_business_date=prm_tran_date,
                  cfu_business_time=prm_tran_time,
                  cfu_txn_code=prm_txn_code,
                  cfu_lupd_user=prm_lupduser,
                  CFU_UPLOAD_STAT='C'--Added by Dnyaneshwar J on 26 Oct 2012.
              where  cfu_ref_number = V_ORIG_ROWID;                 --SN:modify by Santosh k for FSS-695

           EXCEPTION WHEN OTHERS
                THEN
                   v_resp_code := '21';
                   v_errmsg :=
                         'Error while updating fileupload detl for GPR - for rowid '
                         ||V_ORIG_ROWID
                         || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;

           END;

             --SN:added by Santosh k for FSS-695
            BEGIN

              UPDATE CMS_CAF_INFO_ENTRY
                SET CCI_OVERRIDE_FLAG = 1,
                    CCI_ORIG_ROWID      = V_ORIG_ROWID
                WHERE CCI_ROW_ID <> V_ORIG_ROWID
                  AND cci_prod_code     = v_cci_prod_code
                  and ((v_document_verify='SSN' and (cci_ssn_encr=fn_emaps_main(V_CUST_ID_SSN) or cci_ssn=V_CUST_ID_SSN))
                  or (v_document_verify<>'SSN' and (cci_id_number_encr=fn_emaps_main(V_CUST_ID_SSN) or cci_id_number=V_CUST_ID_SSN)))
                  and cci_document_verify=v_document_verify--Added by Dnyaneshwar J on 24 Feb 2014 For Mantis-13737
                  AND cci_override_flag = 0
                  AND cci_kyc_flag IN ('E', 'F');

            EXCEPTION
              WHEN OTHERS THEN
                V_RESP_CODE := '21';
                v_errmsg    :='Error while updating KYC failed pending records for rowId -'||V_ORIG_ROWID || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
            end;
         --EN:added by Santosh k for FSS-695
     
         --start added for FSS-2125
         
            prm_pin_flag := v_cap_pin_flag; --added by Santosh k for MVCSD-4099

             if V_CAP_PIN_FLAG = 'Y' then  --added by Santosh k for MVCSD-4099

              BEGIN

                    UPDATE cms_appl_pan
                    set    cap_card_stat = '1',cap_active_date=sysdate -- added for FSS-2125
                    where  cap_pan_code  = v_hash_pan;

                    v_crdstat_chnge:='Y';  --added by Pankaj S. for FSS-390
              exception when others
              then
                   v_errmsg := 'error while activating GPR card '||substr(sqlerrm,1,100);
                   raise exp_reject_record;

              END;

            end if; --added by Santosh k for MVCSD-4099

          Begin

              select count(1)
              into   v_cnt
              from  CMS_CARDISSUANCE_STATUS
              where CCS_INST_CODE = prm_instcode
              and   CCS_PAN_CODE  = v_hash_pan
              and   CCS_CARD_STATUS ='31';

          exception when others
          then
                v_errmsg := 'While checking for kyc failed status of starter card '||substr(sqlerrm,1,100);
                raise exp_reject_record;

          End;

          if v_cnt = 1
          then

            Begin

                 update CMS_CARDISSUANCE_STATUS
                 set  CCS_CARD_STATUS ='15'
                 where CCS_INST_CODE = prm_instcode
                 and   CCS_PAN_CODE  = v_hash_pan;

            exception when others
            then
                v_errmsg := 'While updating application status for GPR card '||substr(sqlerrm,1,100);
                 raise exp_reject_record;

            End;


          end if; --end added for FSS-2125

        elsif prm_txn_code = '24' AND prm_delv_chnl = '03'
        then

           BEGIN

              update cms_fileupload_detl
              set cfu_pan_code=v_hash_starter_pan,
                  cfu_pan_code_encr=v_encr_starter_pan,
                  cfu_acct_no=v_spnd_acctno,
                  CFU_DELIVERY_CHANNEL=prm_delv_chnl,
                  cfu_rrn=prm_rrn,
                  cfu_business_date=prm_tran_date,
                  cfu_business_time=prm_tran_time,
                  cfu_txn_code=prm_txn_code,
                  CFU_LUPD_USER=PRM_LUPDUSER
              where  cfu_ref_number = V_ORIG_ROWID;                   --SN:modify by Santosh k for FSS-695

           EXCEPTION WHEN OTHERS
                THEN
                   v_resp_code := '21';
                   v_errmsg :=
                         'Error while updating fileupload detl for GPR - for rowid '
                         ||V_ORIG_ROWID
                         || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;

           END;

       prm_pin_flag := v_cap_pin_flag; --added by Santosh k for MVCSD-4099

        if V_CAP_PIN_FLAG = 'Y' then  --added by Santosh k for MVCSD-4099

          BEGIN

                    UPDATE cms_appl_pan
                    set    cap_card_stat = '1',cap_active_date=sysdate --added for FSS-2125
                    where  cap_pan_code  = v_hash_starter_pan;

                    v_crdstat_chnge:='Y';  --added by Pankaj S. for FSS-390
              exception when others
              then
                   v_errmsg := 'error while activating stater card '||substr(sqlerrm,1,100);
                   raise exp_reject_record;

          END;

        end if; --added by Santosh k for MVCSD-4099
        
          Begin

              select count(1)
              into   v_cnt
              from  CMS_CARDISSUANCE_STATUS
              where CCS_INST_CODE = prm_instcode
              and   CCS_PAN_CODE  = v_hash_starter_pan
              and   CCS_CARD_STATUS ='31';

          exception when others
          then
                v_errmsg := 'While checking for kyc failed status of starter card '||substr(sqlerrm,1,100);
                raise exp_reject_record;

          End;

          if v_cnt = 1
          then

            Begin

                 update CMS_CARDISSUANCE_STATUS
                 set  CCS_CARD_STATUS ='15'
                 where CCS_INST_CODE = prm_instcode
                 and   CCS_PAN_CODE  = v_hash_starter_pan;

            exception when others
            then
                v_errmsg := 'While updating application status for starter card '||substr(sqlerrm,1,100);
                 raise exp_reject_record;

            End;


          end if;
     
     --SN:added by Santosh k for FSS-695     
      BEGIN
          update CMS_CAF_INFO_ENTRY
            set CCI_OVERRIDE_FLAG = case when CCI_ROW_ID=PRM_ROWID then --sn:Added by Dnyaneshwar J on 18 Feb 2014 for Mantis-13693
                                    2 else 1
                                    END,                                --en:Added by Dnyaneshwar J on 18 Feb 2014 for Mantis-13693
            CCI_ORIG_ROWID          = V_ORIG_ROWID
            WHERE CCI_STARTER_CARD_NO = V_HASH_STARTER_PAN;
        EXCEPTION
          WHEN OTHERS THEN
            V_RESP_CODE := '21';
            v_errmsg    :='Error while updating KYC failed pending records for rowId -'||V_ORIG_ROWID || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        end;
     --EN:added by Santosh k for FSS-695

        End if;


         BEGIN

               select ccm_cust_id
               into   prm_cust_id
               from   cms_cust_mast
               where  ccm_inst_code = prm_instcode
               and    ccm_cust_code = v_cap_cust_code;

         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_code := '49';
               v_errmsg := 'Invalid cust code - '||v_cap_cust_code|| ' for rowid - '||V_ORIG_ROWID;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_errmsg :=
                     'Error while selecting cust id for cust code '
                     ||v_cap_cust_code
                     || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;



         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_instcode AND cam_acct_no = v_spnd_acctno;


         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_code := '7'; -- Changed from 95 to 7 on 28Nov2012
               v_errmsg := 'Spending Account not found '||v_spnd_acctno;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_code := '21';
               v_errmsg :=
                     'Error while selecting acct details-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


      BEGIN

         UPDATE cms_cust_mast
            SET ccm_kyc_flag = prm_kyc_flag,
                ccm_kyc_source = prm_delv_chnl
          WHERE ccm_cust_code = v_cap_cust_code
            AND ccm_inst_code = prm_instcode;

         IF SQL%ROWCOUNT <> 1
         THEN
            v_resp_code := '21';
            v_errmsg := 'Error while updating kyc';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_errmsg :=
                  'Error while updating KYC Registration-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      IF prm_comment is null
      THEN
           IF  prm_txn_code = '23' AND prm_delv_chnl = '03'
           THEN

            v_comment := 'KYC OVERRIDE FOR GPR CARD';


           ELSIF  prm_txn_code = '24' AND prm_delv_chnl = '03'
           THEN

            v_comment := 'KYC OVERRIDE FOR STARTER TO GPR CARD';

           END IF;

      else

         v_comment := prm_comment;

      END IF;



       BEGIN
          SELECT seq_call_id.NEXTVAL
            INTO v_call_id
            FROM DUAL;
       EXCEPTION
          WHEN OTHERS
          THEN
             v_resp_code := '21';
             prm_errmsg := ' Error while generating call id  ' || SQLERRM;
             RAISE exp_reject_record;
       END;

       BEGIN

          INSERT INTO cms_calllog_mast
                      (ccm_inst_code, ccm_call_id, ccm_call_catg, ccm_pan_code,
                       ccm_callstart_date, ccm_callend_date, ccm_ins_user,
                       ccm_ins_date, ccm_lupd_user, ccm_lupd_date,
                       ccm_acct_no,ccm_call_status
                      )
               VALUES (prm_instcode, v_call_id, 1, v_hash_pan,
                       sysdate, null, prm_lupduser,
                       sysdate, prm_lupduser, sysdate,
                       v_spnd_acctno,'C'
                      );
       EXCEPTION
          WHEN OTHERS
          THEN
             v_resp_code := '21';
             prm_errmsg :=
                       ' Error while inserting into cms_calllog_mast ' || SQLERRM;
             RAISE exp_reject_record;
       END;


       BEGIN
          INSERT INTO cms_calllog_details
                      (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                       ccd_rrn, ccd_devl_chnl, ccd_txn_code,
                       ccd_tran_date, ccd_tran_time, ccd_tbl_names,
                       ccd_colm_name, ccd_old_value, ccd_new_value,
                       ccd_comments, ccd_ins_user, ccd_ins_date, ccd_lupd_user,
                       ccd_lupd_date,
                       ccd_acct_no
                      )
               VALUES (prm_instcode, v_call_id, v_hash_pan, 1,
                       prm_rrn, prm_delv_chnl, prm_txn_code,
                       prm_tran_date, prm_tran_time, NULL,
                       NULL, NULL, NULL,
                       v_comment, prm_lupduser, SYSDATE, prm_lupduser,
                       SYSDATE,
                       v_spnd_acctno
                      );
       EXCEPTION
          WHEN OTHERS
          THEN
             v_resp_code := '21';
             v_errmsg :=
                    ' Error while inserting into cms_calllog_details ' || SQLERRM;
             RAISE  exp_reject_record;
       END;


      v_resp_code := '1';

      BEGIN
         SELECT cms_iso_respcde
           INTO prm_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = prm_instcode
            AND cms_delivery_channel = prm_delv_chnl
            AND cms_response_id = v_resp_code;

         prm_errmsg := v_errmsg;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from response master1 '
               || v_resp_code
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_code := '21';
            RAISE  exp_reject_record;
      END;

   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK;
         prm_errmsg := v_errmsg;

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_instcode AND cam_acct_no = v_spnd_acctno;


         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
         END;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_instcode
               AND cms_delivery_channel = prm_delv_chnl
               AND cms_response_id = v_resp_code;
               
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Problem while selecting data from response master2 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';

         END;

         prm_errmsg := RTRIM(v_errmsg||'|'||v_ssn_crddtls,'|');

   WHEN OTHERS
   THEN
         ROLLBACK;
         prm_errmsg := 'Error while Processing ' || SUBSTR (SQLERRM, 1, 200);
         v_resp_code := '21';

         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal
              INTO v_acct_balance, v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_instcode AND cam_acct_no = v_spnd_acctno;


         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_balance := 0;
               v_ledger_bal := 0;
         END;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_instcode
               AND cms_delivery_channel = prm_delv_chnl
               AND cms_response_id = v_resp_code;

         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Problem while selecting data from response master3 '
                  || v_resp_code
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';

         END;
   END;

   BEGIN

     SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
       INTO v_auth_id
       FROM DUAL;

   EXCEPTION
     WHEN OTHERS
     THEN
        prm_errmsg := 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 100);
        prm_resp_code := '89';
        RETURN;
   END;
   --start added for FSS-2125
   IF v_hash_starter_pan IS NULL THEN
   v_hash_starter_pan := v_hash_pan;
   v_encr_starter_pan := v_encr_pan;
   END IF;
   --End added for FSS-2125
   --Sn Added by Pankaj S. for FSS-390
   IF v_errmsg='OK' AND v_crdstat_chnge='Y' THEN
    BEGIN
       sp_log_cardstat_chnge (prm_instcode,
                              v_hash_starter_pan,
                              v_encr_starter_pan,
                              v_auth_id,
                              '01',
                              prm_rrn,
                              prm_tran_date,
                              prm_tran_time,
                              v_resp_code,
                              v_errmsg
                             );

       IF v_resp_code <> '00' AND v_errmsg <> 'OK'
       THEN
          RAISE exp_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_reject_record
       THEN
        prm_resp_code:=v_resp_code;
        prm_errmsg:=v_errmsg;
        RETURN;
       WHEN OTHERS
       THEN
          prm_resp_code := '89';
          prm_errmsg :=
                'Error while logging system initiated card status change '
             || SUBSTR (SQLERRM, 1, 200);
          RETURN;
    END;
   END IF;
   --En Added by Pankaj S. for FSS-390
   

   BEGIN

        INSERT INTO cms_transaction_log_dtl
                    (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                     ctd_msg_type, ctd_txn_mode, ctd_business_date,
                     ctd_business_time, ctd_customer_card_no,
                     ctd_txn_amount, ctd_fee_amount, ctd_txn_curr,
                     ctd_actual_amount, ctd_bill_amount, ctd_bill_curr,
                     ctd_process_flag, ctd_process_msg, ctd_rrn,
                     ctd_system_trace_audit_no, ctd_inst_code,
                     CTD_CUSTOMER_CARD_NO_ENCR, CTD_CUST_ACCT_NUMBER,
                     ctd_ins_date, ctd_ins_user,ctd_gpr_optin  --Added for FWR 70
                    )
             VALUES (prm_delv_chnl, prm_txn_code, v_dr_cr_flag,
                     prm_msg_type, prm_tran_mode, prm_tran_date,
                     prm_tran_time, decode (prm_txn_code,'23',v_hash_pan,'24',v_hash_starter_pan),
                     '0.00', '0.00', prm_curr_code,
                     '0.00', '0.00', prm_curr_code,
                     decode(PRM_RESP_CODE, '00','Y','E'), v_errmsg, prm_rrn,
                     prm_stan, prm_instcode,
                     DECODE (PRM_TXN_CODE,'23',V_ENCR_PAN,'24',V_ENCR_STARTER_PAN), V_SPND_ACCTNO,
                     SYSDATE, prm_lupduser,v_gpr_optin   --Added for FWR 70
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

  BEGIN
    INSERT INTO TRANSACTIONLOG
     (msgtype,
      rrn,
      delivery_channel,
      date_time,
      txn_code,
      txn_type,
      txn_mode,
      txn_status,
      response_code,
      business_date,
      business_time,
      customer_card_no,
      bank_code,
      total_amount,
      currencycode,
      productid,
      categoryid,
      tips,
      auth_id,
      trans_desc,
      tranfee_amt,
      amount,
      system_trace_audit_no,
      instcode,
      feecode,
      tran_reverse_flag,
      customer_card_no_encr,
      proxy_number,
      reversal_code,
      customer_acct_no,
      acct_balance,
      ledger_balance,
      error_msg,
      add_ins_date,
      add_ins_user,
      add_lupd_date,
      add_lupd_user,
      response_id,
      remark,
      reason,
      processes_flag,
      ipaddress,     --added aby amit on 07-Oct-2012
      cr_dr_flag,    --added aby amit on 07-Oct-2012
      ssn_fail_dtls,
      customer_starter_card_no , --added by Pankaj S. for Mantis ID-10608
      gprcardapplicationno   --added by Pankaj S. for Mantis ID-10608
      )
    VALUES
     (prm_msg_type,
      prm_rrn,
      prm_delv_chnl,
      to_date (prm_tran_date ||' '|| prm_tran_time,'yyyymmdd hh24miss'),
      prm_txn_code,
      1,
      prm_tran_mode,
      decode(prm_resp_code, '00', 'C', 'F'),
      prm_resp_code,
      prm_tran_date,
      prm_tran_time,
      decode (prm_txn_code,'23',v_hash_pan,'24',v_hash_starter_pan),
      prm_instcode,
      '0.00',
      prm_curr_code,
      v_cap_prod_code,
      v_cap_card_type,
      0,
      v_auth_id,
      substr(v_tran_desc||' - '|| prm_reason, 1, 40),
      '0.00',
      '0.00',
      prm_stan,
      prm_instcode,
      null,
      'N',
      decode (prm_txn_code,'23',v_encr_pan,'24',v_encr_starter_pan),
      v_cap_proxynumber,
      '00',
      v_spnd_acctno,
      v_acct_balance,
      v_ledger_bal,
      v_errmsg,
      sysdate,
      prm_lupduser,
      sysdate,
      prm_lupduser,
      v_resp_code,
      v_comment,
      prm_reason,
      decode(prm_resp_code, '00', 'Y', 'E'),
      prm_ipaddress, --added aby amit on 07-Oct-2012
      v_dr_cr_flag, --added aby amit on 07-Oct-2012
      v_ssn_crddtls,
      v_encr_starter_pan , --added by Pankaj S. for Mantis ID-10608
      v_appl_code--added by Pankaj S. for Mantis ID-10608
      );
  EXCEPTION
    WHEN OTHERS THEN
     prm_resp_code := '89';
     prm_errmsg    := 'Error while inserting in transactionlog ' ||
                   SUBSTR(SQLERRM, 1, 100);

  END;


EXCEPTION                                             --<< MAIN EXCEPTION >>--
   WHEN OTHERS
   THEN
      prm_resp_code := '89';
      prm_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                           --<< MAIN END>>

/
show error