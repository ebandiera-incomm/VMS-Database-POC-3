create or replace
PROCEDURE     VMSCMS.SP_CARD_ISSUENCE_KYC (
   p_inst_code             IN       NUMBER,
   p_rrn                   IN       VARCHAR2,
   p_card_no               IN       VARCHAR2,
   p_cci_row_id            IN       VARCHAR2,
   --Modified number to varchar2 on 02/01/2014 for FSS-1303
   p_idologyid             IN       NUMBER,
   p_delivery_channel      IN       VARCHAR2,
   p_tran_code             IN       VARCHAR2,
   p_first_name            IN       VARCHAR2,
   p_trandate              IN       VARCHAR2,
   p_trantime              IN       VARCHAR2,
   p_kyc_resp1             IN       VARCHAR2,
   p_kyc_resp2             IN       NUMBER,
   p_kyc_resp3             IN       VARCHAR2,
   p_cntry_code            IN       VARCHAR2,     -- added for defect Id:12285
   p_ipaddress             IN       VARCHAR2,     -- added for defect Id:12285
   p_resp_code             OUT      VARCHAR2,
   p_acct_no               OUT      VARCHAR2,
   --Modified Number to VARCHAR2 for defect id :12101 on 22-Aug-2013
   p_pan_number            OUT      VARCHAR2,
   p_errmsg                OUT      VARCHAR2,
   p_cust_id               OUT      VARCHAR2,
   --Modified Number to VARCHAR2 for defect id :12101 on  22-Aug-2013
   p_cps_welcome_flag      OUT      VARCHAR2,
   p_feeplanid             IN       VARCHAR2 DEFAULT NULL,
   --Added for LYFEHOST-58
   p_lupduser              IN       NUMBER DEFAULT NULL,
   --Added for LYFEHOST-58
   p_document_verify       IN       VARCHAR2 DEFAULT NULL,
   p_id_number             IN       VARCHAR2 DEFAULT NULL,
   P_DEVICE_MOBILE_NO      IN       VARCHAR2 DEFAULT NULL,    --Added on 27-Mar-2014 by Dinesh B for MOB-62
   P_DEVICE_ID             IN       VARCHAR2 DEFAULT NULL,    --Added on 27-Mar-2014 by Dinesh B for MOB-62
   P_ANI                   IN       VARCHAR2 DEFAULT NULL,   -- added for FSS-1747
   p_telnumber             IN       VARCHAR2 DEFAULT NULL,
   p_lastname              IN       VARCHAR2 DEFAULT NULL,
   P_PHYSICAL_ADD_ONE      IN       varchar2 DEFAULT NULL,
   p_physical_add_two      IN       VARCHAR2 DEFAULT NULL,
   P_CITY                  IN       varchar2 DEFAULT NULL,
   p_zipcode               IN       varchar2 DEFAULT NULL, --Modified for FWR 70
   p_mobile_no             IN       NUMBER DEFAULT NULL,
   p_email_add             IN       VARCHAR2 DEFAULT NULL,
   p_id_issuer             IN       VARCHAR2 DEFAULT NULL,
   p_mailing_add_one       IN       VARCHAR2 DEFAULT NULL,
   p_mailing_add_two       IN       VARCHAR2 DEFAULT NULL,
   p_mailing_city          IN       VARCHAR2 DEFAULT NULL,
   p_mailing_zipcode       IN       VARCHAR2 DEFAULT NULL,
   p_mail_cntry_code       IN       VARCHAR2 DEFAULT NULL,
   p_issuance_date         IN       VARCHAR2 DEFAULT NULL,
   p_expiry_date           IN       VARCHAR2 DEFAULT NULL,
   p_mothers_maiden_name   IN       VARCHAR2 DEFAULT NULL,
   p_state_code            IN       VARCHAR2 DEFAULT NULL,
   p_mail_state_code       IN       VARCHAR2 DEFAULT NULL,
   p_dob                   IN       VARCHAR2 DEFAULT NULL,
   p_branch_code           IN       VARCHAR2 DEFAULT NULL,
   p_catg_sname            IN       VARCHAR2 DEFAULT NULL,
   p_startergpr_crdtype    IN       VARCHAR2 DEFAULT NULL,
   p_kyc_idology_id        IN       VARCHAR2 DEFAULT NULL,
   p_state_switch          IN       VARCHAR2 DEFAULT NULL,
   P_MAIL_STATE_SWITCH     IN       varchar2 DEFAULT NULL,
   P_SHIPPING_METHOD       IN       varchar2 DEFAULT NULL, --Added for jh-3043
   p_customer_field1       IN       VARCHAR2 DEFAULT NULL, --Added for NCGPR-1581
   p_customer_field2       IN       VARCHAR2 DEFAULT NULL,  --Added for NCGPR-1581
   P_SAVINGSELIGIBILITY_FLAG  IN    VARCHAR2 DEFAULT NULL,  -- modified for Mantis id:16190
   P_OPTIN_LIST               IN    VARCHAR2  DEFAULT NULL,
   P_IDSCAN                   IN    VARCHAR2 DEFAULT NULL,
   P_GPR_OPTIN                IN    varchar2 DEFAULT 'Y',  --Added for FWR 70
   --Added on 09-10-2017--START
   p_occupation            IN        VARCHAR2 DEFAULT NULL,
   p_id_province           in        varchar2 default null,
   p_id_country            in        varchar2 default null,
   p_id_verification_date  in        varchar2 default null,
   p_tax_res_of_canada    in         char,
   p_tax_payer_id_number   in        varchar2 default null,
   p_reason_for_no_tax_id_type  in        varchar2 default null,
   p_reason_for_no_tax_id  in        varchar2 default null,
   p_jurisdiction_of_tax_res in      varchar2 default null,
   p_type_of_employment IN      VARCHAR2 DEFAULT NULL,
    --Added on 09-10-2017 --END
   --Added on 11-04-2018 VMS-270--END
  p_thirdpartyenabled      in        varchar2 default null,
  p_thirdpartytype      in        varchar2 default null,
  p_thirdpartyfirstname         in        varchar2 default null,
  p_thirdpartylastname         in        varchar2 default null,
  p_thirdpartycorporationname  in        varchar2 default null,
  p_thirdpartycorporation  in        varchar2 default null,
  p_thirdpartyaddress1      in        varchar2 default null,
   p_thirdpartyaddress2      in        varchar2 default null,
   p_thirdpartycity      in        varchar2 default null,
    p_thirdpartystate      in        varchar2 default null,
    p_thirdpartyzip      in        varchar2 default null,
    p_thirdpartycountry      in        varchar2 default null,
    p_thirdpartynaturerelationship in        varchar2 default null,
    p_thirdpartybusiness     in        varchar2 default null,
  p_thirdpartyoccupationtype in        varchar2 default null,
  p_thirdpartyoccupation   in        varchar2 default null,
  p_thirdpartydob          in        varchar2 DEFAULT NULL



  )
AS
      /**************************************************************************
      * Created Date      : 19_July_2013
      * Created By        : Arunprasath
      * Purpose           : Card Issuance KYC Success And Failuare Process
      * Reviewer          : Dhiraj
      * Reviewed Date     : 19-aug-2013
      * Release Number    : RI0024.4_B0002

       * Modified By      : Ramesh.A
       * Modified Date    : 22-Aug-2013
       * Modified For     : Defect ID - 12101 :
       * Modified Reason  : Modified the output paramter (Account number and customer ID as varchar2)
       * Reviewer         : Dhiraj
       * Reviewed Date    : 22-Aug-2013
       * Build Number     : RI0024.4_B0003

       * Modified By      : Ramesh.A
       * Modified Date    : 22-Aug-2013
       * Modified For     : MVCSD-4099 :
       * Modified Reason  : Commented the code for startercard activation
       * Reviewer         : Dhiraj
       * Reviewed Date    : 22-Aug-2013
       * Build Number     : RI0024.4_B0004

       * Modified By      : Sachin P.
       * Modified Date    : 29-AUG-2013
       * Modified For     : MVCSD-4099(Review)changes
       * Modified Reason  : Review changes
       * Reviewer         : Dhiraj
       * Reviewed Date    : 30-aug-2013
       * Release Number   : RI0024.4_B0006

       * Modified By      : Siva kumar M.
       * Modified Date    : 03-Sept-2013
       * Modified For     : Defect Id:12212
       * Modified Reason  : commented the card status logging block,
       * Reviewer         : DHIRAJ
       * Reviewed Date    : 03-Sept-2013
       * Release Number   : ri0024.4_B0007


       * Modified By      : Siva kumar M.
       * Modified Date    : 10-Sept-2013
       * Modified For     : Defect Id:12285,12254
       * Modified Reason  :
       * Reviewer         : Dhiraj
       * Reviewed Date    : 12-sep-2013
       * Build Number     : RI0024.4_B0010

       * Modified Date    : 10_Sep_2013
       * Modified By      : Pankaj S.
       * Purpose          : SPIL target registration
       * Reviewer         : Dhiraj
       * Reviewed Date    : 12-sep-2013
       * Build Number     : RI0024.4_B0010

      * Modified by      :  Pankaj S.
      * Reason           :  To skip txn log insert for target registration
      * Created Date     :  25-Sep-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  25-Sep-2013
      * Build Number     :  RI0024.4_B0018

      * Modified By      : RameshA
      * Modified Date    : 24-SEP-2013
      * Modified Reason  : Mantis id : 12449
      * Modified for     : logging card number values in log table
      * Reviewer         : Dhiraj
      * Reviewed Date    : 24-SEP-2013
      * Build Number     : RI0024.4_B0018

      * Modified By      : Ramesh A
      * Modified Date    : 02-OCT-2013
      * Modified Reason  : Mantis id :12515 , card isuance status updates while KYC failed
      * Reviewer         : Dhiraj
      * Reviewed Date    : 02-OCT-2013
      * Build Number     : RI0024.4.2_B0001

      * Modified By      : Arun vijay
      * Modified Date    : 31-SEP-2013
      * Modified Reason  : LYFEHOST-58
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19-09-2013
      * Build Number     : RI0024.5_B0001

      * Modified By      : Arun vijay
      * Modified Date    : 15-Oct-2013
      * Modified Reason  : LYFEHOST-58
      * Reviewer         : Dhiraj
      * Reviewed Date    : 15-10-2013
      * Build Number     : RI0024.5_B0004

      * Modified By      : Ramesh
      * Modified Date    : 02-Jan-2014
      * Modified Reason  : FSS-1303 : paramter modified and inst_code added in cms_caf_info_entry(where clause) table
      * Reviewer         : Dhiraj
      * Reviewed Date    : 02-Jan-2014
      * Build Number     : RI0024.6.4_B0001

      * Modified Date    : 10-Dec-2013
      * Modified By      : Sagar More
      * Modified for     : Defect ID 13160
      * Modified reason  : To log below details in transactinlog and cms_transaction_log_dtl if applicable
                           Account Type,Card Status,Timestamp,CR_DR_FLAG
      * Reviewer         : Dhiraj
      * Reviewed Date    : 10-Dec-2013
      * Release Number   : RI0024.7_B0001

      * Modified Date    : 11-Feb-2013
      * Modified By      : Dhinakaran B
      * Modified for     : FSS-695
      * Modified reason  :
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Release Number   : RI0027.1_B0001


       * Modified Date    : 31-Jan-2014
       * Modified By      : Sagar More
       * Modified for     : Spil_3.0 Changes
       * Modified reason  : 1) Or condition added while p_kyc_resp1 check
                            2) kyc flag set as E for spil_3,0 activation transaction when KYC process fails due to communication issue
                            3) appl_mast updated for startercard flag as N for null KYC response for ACTIVATION transaction
       * Reviewer         : Dhiraj
       * Reviewed Date    : 01-Feb-2014
       * Release Number   : RI0027.1_B0001

       * Modified Date    : 13-Feb-2014
       * Modified By      : Deepa T
       * Modified for     : FSS-695
       * Modified reason  : To maintain multiple records for KYC failed records of Starter to GPR registration
       * Reviewer         : Dhiraj
       * Reviewed Date    : 13-Feb-2014
       * Release Number   : RI0027.1_B0001

       * Modified Date    : 20-Feb-2014
       * Modified By      : Dayanand Kesarkar
       * Modified for     : Mantis:13713
       * Modified reason  : Record inserted in CMS_KYCTXN_LOG  table  for FWR-39
       * Reviewer         : Dhiraj
       * Reviewed Date    : 20-Feb-2014
       * Release Number   : RI0027.1_B0004

       * Modified Date    : 20-Feb-2014
       * Modified By      : Dayanand Kesarkar
       * Modified for     : Mantis:13712
       * Modified reason  : Message type added for  for FWR-39
       * Reviewer         : Dhiraj
       * Reviewed Date    : 20-Feb-2014
       * Release Number   : RI0027.1_B0004

       * Modified Date    : 22-Feb-2014
       * Modified By      : Dayanand Kesarkar
       * Modified for     : Mantis:13743
       * Modified reason  : 1)Added  p_errmsg instead of  hardcoded 'successful' message in cms_transaction_log_dtl and
                            2)changed trancode from 26 to 34 for spil3.0
       * Reviewer         : Dhiraj
       * Reviewed Date    : 24-Feb-2014
       * Release Number   : RI0027.1_B0005

       * Modified Date    : 24-Feb-2014
       * Modified By      : Abdul Hameed M.A
       * Modified for     : Mantis:13737
       * Modified reason  : To update the failure records with same id type and number
       * Reviewer         : Dhiraj
       * Reviewed Date    : 24-Feb-2014
       * Release Number   : RI0027.1_B0005

       * Modified Date    : 4-Apr-2014
       * Modified By      : Dinesh B
       * Modified for     : MOB-62
       * Modified reason  : Logging Device Id and mobile no.
       * Reviewer         : Pankaj S
       * Reviewed Date    : 07-Apr-2014
       * Release Number   : RI0024.2_B0004

       * Modified Date    : 21-Apr-2014
       * Modified By      : Dinesh B
       * Modified for     : Mantis-14308
       * Modified reason  : Logging Hash key value.
       * Reviewer         : spankaj
       * Reviewed Date    : 22-April-2014
       * Release Number   : RI0027.2_B0007

       * Modified Date    : 24-Apr-2014
       * Modified By      : Ramesh
       * Modified for     : Mantis-14308
       * Modified reason  : Logging Hash key value.
       * Reviewer         : spankaj
       * Reviewed Date    : 24-April-2014
       * Release Number   : RI0027.2_B0009

       * Modified Date    : 25-Jun-2014
       * Modified By      : Ramesh
       * Modified for     : Integration from RI0027.1.9 (FSS-1710  - Performance changes)
       * Reviewer         : spankaj
       * Release Number   : RI0027.2.1_B0004

       * Modified Date    : 04-July-2014
       * Modified By      : Ramesh
       * Modified for     : FSS-1672
       * Reviewer         : Spankaj
       * Release Number   : RI0027.3_B0002

       * Modified Date    : 22-July-2014
       * Modified By      : MageshKumar S
       * Modified for     : FSS-1747
       * Reviewer         : Spankaj
       * Release Number   : RI0027.3.1_B0001

       * Modified Date    : 29-SEP-2014
       * Modified By      : Abdul Hameed M.A
       * Modified for     : FWR 70
       * Reviewer         : Spankaj
       * Release Number   : RI0027.4_B0002

       * Modified Date    : 12-DEC-2014
       * Modified By      : Ramesh A
       * Modified for     : FSS-1961(Melissa)
       * Reviewer         : Spankaj
       * Release Number   : RI0027.5_B0002

       * Modified Date    : 20-MAR-2015
       * Modified By      : Ramesh A
       * Modified for     : NCGPR-1581
       * Reviewer         : Spankaj
       * Release Number   : 3.0

       * Modified by      : MageshKumar S.
       * Modified Date    : 23-June-15
       * Modified For     : MVCAN-77
       * Modified reason  : Canada account limit check
       * Reviewer         : Spankaj
       * Build Number     : VMSGPRHOSTCSD3.1_B0001


       * Modified by      :Abdul Hameed M.A
       * Modified Date    : 21-Aug-15
       * Modified For     : 16169
       * Reviewer         : Spankaj
       * Build Number     : VMSGPRHOSTCSD3.1_B0004


     * Modified by      : Siva Kumar M
     * Modified for     : FSS-2279(Savings account changes)
     * Modified Date    : 31-Aug-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1.1_B0007

     * Modified by      : Siva Kumar M
     * Modified for     : Modified for Mantis id:16190
     * Modified Date    : 09-09-2015
     * Reviewer         : Saravana kumar
     * Build Number     : VMSGPRHOAT_3.1_B00010

     * Modified by                  : MageshKumar S.
     * Modified Date                : 22-June-15
     * Modified For                 : IDSCAN CHANGES
     * Reviewer                     : Spankaj
     * Build Number                 : VMSGPRHOSTCSD3.2_B0002

      * Modified by             : Spankaj
      * Modified Date         : 07-Sep-15
      * Modified For           : FSS-2321
      * Reviewer                  : Saravanankumar
      * Build Number           : VMSGPRHOSTCSD3.2

      * Modified by           : Abdul Hameed M.A
      * Modified Date         : 07-Sep-15
      * Modified For          : FSS-3509 & FSS-1817
      * Reviewer              : Saravanankumar
      * Build Number          : VMSGPRHOSTCSD3.2

     * Modified by                  : MageshKumar S.
     * Modified Date                : 26-Oct-15
     * Modified For                 : Mantis Id:0016200
     * Reviewer                     : Spankaj
     * Build Number                 : VMSGPRHOSTCSD3.1.2

     * Modified by                  : Siva Kumar M
     * Modified Date                : 29-Oct-15
     * Modified For                 : Mantis Id:0016211
     * Reviewer                     : Saravana kumar
     * Build Number                 : VMSGPRHOSTCSD3.2

      * Modified by                :Spankaj
      * Modified Date            : 06-Jan-16
      * Modified For             : MVHOST-1249
      * Reviewer                   : Saravanankumar
      * Build Number            : VMSGPRHOSTCSD3.3

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

       * Modified by      : A.Sivakaminathan
       * Modified Date    : 29-Mar-16
       * Modified For     : partner_id logged null / Mantis 0016338 Error in Registration API when the KYC is in Failed status.
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_4.0_B008

	   	 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07

	 	 * Modified By      : Akhil
     * Modified Date    : 05/01/2018
     * Purpose          : VMS-78
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST17.12

	 * Modified by      :  Vini Pushkaran
     * Modified Date    :  02-Feb-2018
     * Modified For     :  VMS-162
     * Reviewer         :  Saravanankumar
     * Build Number     :  VMSGPRHOSTCSD_18.01

     * Modified by      :  Sivakumar M.
     * Modified Date    :  02-May-2019
     * Modified For     :  VMS-836
     * Reviewer         :  Saravanankumar
     * Build Number     :  VMSGPRHOSTCSD_R15_B4

      * Modified by       :Siva kumar
       * Modified Date    : 08-May-19
       * Modified For     : VMS-924
       * Reviewer         : Saravanankumar
       * Build Number     : R15_B4
       
      * Modified by       :Dhinakaran B
       * Modified Date    : 25-JUN-19
       * Modified For     : VMS-913
       * Reviewer         : Saravanankumar
       * Build Number     : R17_B4
        
     * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search � phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
      ****************************************************************************/
   v_hash_pan                  cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                  cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cci_appl_code             cms_appl_pan.cap_appl_code%TYPE; --Added for FSS-1710
   v_resp_cde                  transactionlog.response_id%type  := '1';
   v_userbin                   CMS_ACCT_MAST.CAM_LUPD_USER%TYPE   DEFAULT 1;
   kyc_flag                    cms_caf_info_entry.cci_kyc_flag%type;
   v_startercardissuancetype   cms_prod_cattype.cpc_startergpr_issue%type       DEFAULT 'A';
   v_ofcaflag                  cms_caf_info_entry.cci_ofac_fail_flag%type;
   v_gpr_card_no               CMS_APPL_PAN.CAP_MASK_PAN%TYPE;
   v_applproces_msg            transactionlog.error_msg%type;
   v_count                     PLS_INTEGER;
   v_acct_bal                  cms_acct_mast.cam_acct_bal%type;
   v_ledger_bal                cms_acct_mast.cam_ledger_bal%type;   
   v_sysdate                   cms_caf_info_entry.cci_kyc_reg_date%type;
   -- ADDED for review changes on 16/Aug/2013.
   v_cust_code                 cms_appl_pan.cap_cust_code%TYPE;
   -- ADDED for review changes on 16/Aug/2013.
   v_prod_code                 cms_appl_pan.cap_prod_code%TYPE;
   --Added on 29.08.2013 for MVCSD-4099(Review)changes
   v_card_type                 cms_appl_pan.cap_card_type%TYPE;
   --Added on 29.08.2013 for MVCSD-4099(Review)changes
   v_trans_desc                cms_transaction_mast.ctm_tran_desc%TYPE;
   -- added for defect Id:12285
   v_curr_code                 gen_cntry_mast.gcm_curr_code%TYPE;
   -- added for defect Id:12285
   v_proxy_no                  cms_appl_pan.cap_proxy_number%TYPE;
   v_appl_code                 cms_appl_pan.cap_appl_code%TYPE;--Added on 02/10/2013 for Mantis id :12515
   --Start Added for LYFEHOST-58
   v_tran_date                 cms_card_excpfee.cce_valid_from%type;
   v_feeplan_count             PLS_INTEGER;
   v_fee_plan_desc             cms_fee_plan.cfp_plan_desc%TYPE;
   v_fee_plan_id               cms_card_excpfee.cce_fee_plan%TYPE;
   v_flow_source               cms_card_excpfee.cce_flow_source%TYPE;
   v_valid_from                cms_card_excpfee.cce_valid_from%TYPE;
   v_valid_to                  cms_card_excpfee.cce_valid_to%TYPE;
   v_cardfee_id                cms_card_excpfee.cce_cardfee_id%TYPE;
   --End LYFEHOST-58
   --SN : Added on 10-Dec-2013 for 13160
   v_acct_type                 cms_acct_mast.cam_type_code%TYPE;
   v_card_stat                 cms_appl_pan.cap_card_stat%TYPE;
   v_timestamp                 transactionlog.time_stamp%type;
   v_cr_dr_flag                cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   --EN : Added on 10-Dec-2013 for 13160
   --ADDED FOR FSS-695
   v_seq_val_temp              PLS_INTEGER;
   v_seq_val                   cms_caf_info_entry.Cci_row_id%type;
   v_cap_acct_no               cms_appl_pan.cap_acct_no%TYPE;
   V_CCI_PROD_CODE             CMS_CAF_INFO_ENTRY.CCI_PROD_CODE%TYPE;
   V_MSGTYPE                  TRANSACTIONLOG.MSGTYPE%TYPE DEFAULT '0200'; -- Added for Mantis 13712 on  20 Feb 14
   V_HASHKEY_ID               CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; --Added for Mantis-14308
   v_DELIVERY_CHANNEL         cms_transaction_mast.CTM_DELIVERY_CHANNEL%TYPE  DEFAULT '05';
   V_TXN_CODE                 cms_transaction_mast.CTM_TRAN_CODE%TYPE DEFAULT '46';
   v_pan_number_savingacct    varchar2(50);
   V_ACCT_FLAG                VARCHAR2(5);
   V_TXN_AMT                  cms_dfg_param.cdp_param_value%type;
   V_GPRCARD_FLAG             varchar2(1);
   V_SAVACCT_CONSENT_FLAG     CMS_ACCT_MAST.CAM_SAVACCT_CONSENT_FLAG%TYPE;
   V_SAVINGS_BAL              cms_acct_mast.cam_acct_bal%TYPE;
   V_SPENDING_BAL             cms_acct_mast.cam_acct_bal%TYPE;
   V_SPENEINGLEG_BAL          cms_acct_mast.cam_ledger_bal%TYPE;
   v_spending_acctno          cms_acct_mast.cam_acct_no%TYPE;
   v_savings_acctno           cms_acct_mast.cam_acct_no%TYPE;

   v_sms_optinflag            cms_optin_status.cos_sms_optinflag%TYPE;
   v_email_optinflag          cms_optin_status.cos_email_optinflag%TYPE;
   v_markmsg_optinflag        cms_optin_status.cos_markmsg_optinflag%TYPE;
   v_gpresign_optinflag       cms_optin_status.cos_gpresign_optinflag%TYPE;

   v_optin_type               cms_optin_status.cos_sms_optinflag%TYPE;
   v_optin                    cms_optin_status.cos_sms_optinflag%TYPE;
   v_optin_list               VARCHAR2(1000);
   v_comma_pos                PLS_INTEGER;
   v_comma_pos1               PLS_INTEGER;
   i                          PLS_INTEGER:=1;
  v_tandc_version             CMS_PROD_CATTYPE.CPC_TANDC_VERSION%TYPE;
   V_OPTIN_FLAG               VARCHAR2(10) DEFAULT 'N';
   v_startercard_flag         cms_appl_pan.CAP_STARTERCARD_FLAG%TYPE;
   v_cci_card_type            cms_caf_info_entry.cci_card_type%type;

   v_encrypt_enable          CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  v_encr_telnum			         CMS_CAF_INFO_ENTRY.CCI_SEG12_HOMEPHONE_NO%TYPE;
  v_encr_firstname           CMS_CAF_INFO_ENTRY.CCI_SEG12_NAME_LINE1%TYPE;
  v_encr_lastname            CMS_CAF_INFO_ENTRY.CCI_SEG12_NAME_LINE2%TYPE;
  v_encr_p_add_one           CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE1%TYPE;
  v_encr_p_add_two           CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE2%TYPE;
  v_encr_city                CMS_CAF_INFO_ENTRY.CCI_SEG12_CITY%TYPE;
  v_encr_zipcode             CMS_CAF_INFO_ENTRY.CCI_SEG12_POSTAL_CODE%TYPE;
  v_encr_mobile_no           CMS_CAF_INFO_ENTRY.CCI_SEG12_MOBILENO%TYPE;
  v_encr_email_add           CMS_CAF_INFO_ENTRY.CCI_SEG12_EMAILID%TYPE;
  v_encr_m_add_one           CMS_CAF_INFO_ENTRY.CCI_SEG13_ADDR_LINE1%TYPE;
  v_encr_m_add_two           CMS_CAF_INFO_ENTRY.CCI_SEG13_ADDR_LINE2%TYPE;
  v_encr_m_city              CMS_CAF_INFO_ENTRY.CCI_SEG13_CITY%TYPE;
  v_encr_m_zipcode           CMS_CAF_INFO_ENTRY.CCI_SEG13_POSTAL_CODE%TYPE;
  v_encr_mothers_name        CMS_CAF_INFO_ENTRY.CCI_MOTHERS_MAIDEN_NAME%TYPE;
  v_encr_requester_name      cms_caf_info_entry.cci_requester_name%type;
  V_Occupation_Desc          Vms_Occupation_Mast.Vom_Occu_Name%Type;
  V_State_Switch_Code        Gen_State_Mast.Gsm_Switch_State_Code%Type;
  V_Cntrycode                gen_state_mast.Gsm_Cntry_Code%type;
  V_State_Desc               Vms_Thirdparty_Address.Vta_State_Desc%Type;
  V_state_code               Vms_Thirdparty_Address.Vta_State_code%Type;
  v_id_country               gen_cntry_mast.gcm_switch_cntry_code%TYPE;
  v_jurisdiction_of_tax_res  gen_cntry_mast.gcm_switch_cntry_code%TYPE;
  exp_reject_record          EXCEPTION;

BEGIN
   p_errmsg := 'OK';                                                        --
   v_sysdate := SYSDATE;                         -- added for defect id:12254
   v_timestamp :=SYSTIMESTAMP; --Added for Mantis-14308

  --Start Generate HashKEY for Mantis-14308
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TRAN_CODE||p_card_no||P_RRN||to_char(v_timestamp,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        v_resp_cde := '21';
        p_errmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
     END;

      --End Generate HashKEY for Mantis-14308

   BEGIN                                         -- added for defect Id:12285
      SELECT ctm_tran_desc, ctm_credit_debit_flag
        INTO v_trans_desc, v_cr_dr_flag
        FROM cms_transaction_mast
       WHERE ctm_inst_code = p_inst_code
         AND ctm_tran_code = p_tran_code
         AND ctm_delivery_channel = p_delivery_channel;

      IF v_trans_desc IS NULL
      THEN
         v_resp_cde := '21';
         p_errmsg := 'Transaction Not Defined';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_errmsg :=
               'Error while checking transaction mast details-'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF p_card_no IS NOT NULL
   THEN
      BEGIN
         v_hash_pan := gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';   -- added on 16/Aug/2013 for review changes.
            p_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Create hash PAN

       --Sn Create encr PAN
      BEGIN
         v_encr_pan := fn_emaps_main (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';   -- added on 16/Aug/2013 for review changes.
            p_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Create encr PAN
         IF (P_DELIVERY_CHANNEL = '08' AND P_TRAN_CODE = '34' ) -- Modified  for Mantis- 13743 on 22-Feb-2014
            THEN
            V_MSGTYPE:='1200';
       END IF ;

      --Sn selecting the customer details. block is added on 16/Aug/2013 for review changes.
      BEGIN
         SELECT pan.cap_cust_code,pan.cap_prod_code,
                                             --Added on 29.08.2013 for MVCSD-4099(Review)changes
                                            pan.cap_card_type,
                                                           --Added on 29.08.2013 for MVCSD-4099(Review)changes
                                                          pan.cap_acct_no,
                --Added on 29.08.2013 for MVCSD-4099(Review)changes
                pan.cap_proxy_number,pan.cap_appl_code,
                --Added on 02/10/2013 for Mantis id :12515
                pan.cap_card_stat                 --Added on 10-Dec-2013 for 13160
                             ,pan.cap_acct_no,cust.ccm_cust_id,pan.cap_startercard_flag
           INTO v_cust_code, v_prod_code,
                                         --Added on 29.08.2013 for MVCSD-4099(Review)changes
                                         v_card_type,
                                                     --Added on 29.08.2013 for MVCSD-4099(Review)changes
                                                     p_acct_no,
                --Added on 29.08.2013 for MVCSD-4099(Review)changes
                v_proxy_no, v_appl_code,
                --Added on 02/10/2013 for Mantis id :12515
                v_card_stat                   --Added on 10-Dec-2013 for 13160
                           , v_cap_acct_no,p_cust_id,v_startercard_flag
           FROM cms_appl_pan pan,cms_cust_mast cust
          WHERE pan.cap_inst_code = cust.ccm_inst_code
               AND pan.cap_cust_code = cust.ccm_cust_code
              AND pan.cap_inst_code = p_inst_code AND pan.cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';   -- added on 16/Aug/2013 for review changes.
            p_errmsg :=
                  'Error while CUST code from appl_pan table. '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   --En selecting the customer details.
   ELSE                                                    --ADDED FOR FSS-695
      SELECT cci_prod_code,cci_card_type
        INTO v_cci_prod_code,v_cci_card_type
        FROM cms_caf_info_entry
       WHERE cci_row_id = p_cci_row_id AND cci_inst_code = p_inst_code;
   END IF;

   --Sn get currency code  -- added for defect Id:12285
   BEGIN
      SELECT gcm_curr_code
        INTO v_curr_code
        FROM gen_cntry_mast
       WHERE gcm_inst_code = p_inst_code
                                        -- Modified the query for review comments.
             AND gcm_cntry_code = p_cntry_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_errmsg :=
               'Error while selecting country detail-'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En get currency code

   --Sn Added for FSS-2321
    BEGIN
       INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
            VALUES (p_rrn, p_delivery_channel, p_tran_code, v_cust_code,1);
    EXCEPTION
       WHEN OTHERS THEN
          v_resp_cde := '21';
          p_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
    --En Added for FSS-2321

   BEGIN
      SELECT cpc_encrypt_enable
        INTO v_encrypt_enable
        FROM cms_prod_cattype
       WHERE cpc_inst_code = p_inst_code
	     AND cpc_prod_code = nvl(v_prod_code,v_cci_prod_code)
		 AND cpc_card_type =  nvl(v_card_type,v_cci_card_type);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_errmsg :=
               'Error while selecting product category details-'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF v_encrypt_enable = 'Y' THEN
     v_encr_telnum := fn_emaps_main(p_telnumber);
		 v_encr_firstname := fn_emaps_main(p_first_name);
     v_encr_lastname := fn_emaps_main(p_lastname);
 		 v_encr_p_add_one := fn_emaps_main(p_physical_add_one);
		 v_encr_p_add_two := fn_emaps_main(p_physical_add_two);
		 v_encr_city := fn_emaps_main(p_city);
		 v_encr_zipcode := fn_emaps_main(p_zipcode);
		 v_encr_mobile_no := fn_emaps_main(p_mobile_no);
		 v_encr_email_add := fn_emaps_main(p_email_add);
		 v_encr_m_add_one := fn_emaps_main(p_mailing_add_one);
		 v_encr_m_add_two := fn_emaps_main(p_mailing_add_two);
		 v_encr_m_city := fn_emaps_main(p_mailing_city);
		 v_encr_m_zipcode := fn_emaps_main(p_mailing_zipcode);
		 v_encr_mothers_name := fn_emaps_main(p_mothers_maiden_name);
     V_ENCR_REQUESTER_NAME := fn_emaps_main(P_FIRST_NAME);
	  ELSE
     v_encr_telnum := p_telnumber;
		 v_encr_firstname := p_first_name;
     v_encr_lastname := p_lastname;
 		 v_encr_p_add_one := p_physical_add_one;
		 v_encr_p_add_two := p_physical_add_two;
		 v_encr_city := p_city;
		 v_encr_zipcode := p_zipcode;
		 v_encr_mobile_no := p_mobile_no;
		 v_encr_email_add := p_email_add;
		 v_encr_m_add_one := p_mailing_add_one;
		 v_encr_m_add_two := p_mailing_add_two;
		 v_encr_m_city := p_mailing_city;
		 v_encr_m_zipcode := p_mailing_zipcode;
		 v_encr_mothers_name := p_mothers_maiden_name;
     V_ENCR_REQUESTER_NAME := P_FIRST_NAME;
	  END IF;


      IF p_id_country IS NOT NULL
        THEN
            BEGIN
              SELECT gcm_switch_cntry_code
              INTO v_id_country
              FROM gen_cntry_mast
              where gcm_inst_code   = p_inst_code
               AND (gcm_alpha_cntry_code  = p_id_country or
               gcm_switch_cntry_code  = p_id_country);

            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_resp_cde := '274';
              p_errmsg  := 'Invalid Data for ID Country code';
              RAISE exp_reject_record;
            WHEN OTHERS THEN
              v_resp_cde := '21';
              p_errmsg  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
            END;

       END IF;
      IF  p_jurisdiction_of_tax_res IS NOT NULL
      THEN
         BEGIN
          SELECT gcm_switch_cntry_code
          INTO v_jurisdiction_of_tax_res
          FROM gen_cntry_mast
          where gcm_inst_code   = p_inst_code
          AND (gcm_alpha_cntry_code  = p_jurisdiction_of_tax_res or gcm_switch_cntry_code  = p_jurisdiction_of_tax_res);

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_resp_cde := '275';
          p_errmsg  := 'Invalid Data for Jurisdiction of tax residence';
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          v_resp_cde := '21';
          p_errmsg  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
       END IF;


   --KYC SUCCESS STARTS
   IF    UPPER (p_kyc_resp1) = 'TRUE'
      OR (    p_delivery_channel = '08'
          AND p_tran_code = '34' -- Modified  for Mantis- 13743 on 22-Feb-2014
          AND p_kyc_resp1 IS NULL
         )
   THEN                             -- OR condition added for Spil_3.0 Changes
      IF UPPER (p_kyc_resp1) = 'TRUE'        -- Added during Spil_3.0 Changes
      THEN
         IF p_idologyid IS NULL
         THEN
            kyc_flag := 'Y';
         ELSE
            kyc_flag := 'P';
         END IF;

         IF (p_delivery_channel = '06'  AND p_tran_code = '06') or ( p_delivery_channel = '13'  AND p_tran_code = '49' )
         then
            kyc_flag:='I';
         end if;

         BEGIN
            --ADDED FOR FSS-695
            IF (p_delivery_channel <> '08' AND p_card_no IS NOT NULL)
            THEN
               UPDATE cms_caf_info_entry
                  SET cci_inst_code = p_inst_code,
                      cci_fiid = p_branch_code,
                      cci_seg12_homephone_no = v_encr_telnum,
                      cci_seg12_name_line1 = v_encr_firstname,
                      cci_seg12_name_line2 = v_encr_lastname,
                      cci_seg12_addr_line1 = v_encr_p_add_one,
                      cci_seg12_addr_line2 = v_encr_p_add_two,
                      cci_seg12_city = v_encr_city,
                      cci_seg12_state = p_state_switch,
                      cci_seg12_postal_code = v_encr_zipcode,
                      cci_seg12_country_code = p_cntry_code,
                      cci_seg12_mobileno = v_encr_mobile_no,
                      cci_seg12_emailid = v_encr_email_add,
                      CCI_PROD_CODE = V_PROD_CODE,
                      CCI_REQUESTER_NAME = V_ENCR_REQUESTER_NAME,
                      CCI_SSN = fn_maskacct_ssn(p_inst_code,DECODE (P_DOCUMENT_VERIFY,
                                        'SSN', p_id_number,'SIN', p_id_number  --Modified for FWR 70
                                       ),0),
                      cci_ssn_encr =fn_emaps_main(DECODE (P_DOCUMENT_VERIFY,'SSN', p_id_number,'SIN', p_id_number)),
                      cci_birth_date = TO_DATE (p_dob, 'mmddyyyy'),
                      cci_document_verify = p_document_verify,
                      cci_kyc_flag = kyc_flag,
                      cci_ins_date = SYSDATE,
                      cci_lupd_date = NULL,
                      cci_approved = 'A',
                      cci_upld_stat = 'P',
                      cci_entry_rec_type = 'P',
                      cci_instrument_realised = 'Y',
                      cci_cust_catg = p_catg_sname,
                      cci_comm_type = '0',
                      cci_seg13_addr_param9 = v_curr_code,
                      CCI_TITLE = 'MR',
                      CCI_ID_ISSUER =
                          DECODE (P_DOCUMENT_VERIFY,
                                  'SSN', NULL,'SIN', NULL, --Modified for FWR 70
                                  p_id_issuer
                                 ),
                      CCI_ID_NUMBER =
                          fn_maskacct_ssn(p_inst_code,DECODE (P_DOCUMENT_VERIFY,
                                  'SSN', NULL,'SIN', NULL, --Modified for FWR 70
                                  p_id_number
                                 ),0),
                      cci_id_number_encr =fn_emaps_main(DECODE (P_DOCUMENT_VERIFY,'SSN', NULL,'SIN', NULL,p_id_number)),
                      cci_seg13_addr_line1 = v_encr_m_add_one,
                      cci_seg13_addr_line2 = v_encr_m_add_two,
                      cci_seg13_city = v_encr_m_city,
                      cci_seg13_state = p_mail_state_switch,
                      cci_seg13_postal_code = v_encr_m_zipcode,
                      CCI_SEG13_COUNTRY_CODE = P_MAIL_CNTRY_CODE,
                      cci_id_issuance_date =
                         DECODE (P_DOCUMENT_VERIFY,
                                 'SSN', NULL,'SIN', NULL, --Modified for FWR 70
                                 TO_DATE (p_issuance_date, 'mmddyyyy')
                                ),
                      CCI_ID_EXPIRY_DATE =
                         DECODE (P_DOCUMENT_VERIFY,
                                 'SSN', NULL,'SIN', NULL, --Modified for FWR 70
                                 TO_DATE (p_expiry_date, 'mmddyyyy')
                                ),
                      cci_mothers_maiden_name = v_encr_mothers_name,
                      cci_card_type = p_startergpr_crdtype,
                      cci_pan_code = v_hash_pan,
                      cci_pan_code_encr = v_encr_pan,
                      cci_seg12_state_code = p_state_code,
                      cci_seg13_state_code = p_mail_state_code,
                      cci_process_msg = 'SUCCESS',
                      cci_kyc_reg_date = v_sysdate,
                      cci_occupation = p_occupation,
                      cci_id_province = p_id_province,
                      cci_id_country = v_id_country,
                      cci_verification_date =  DECODE (P_DOCUMENT_VERIFY,
                                             'SSN', NULL,'SIN', NULL,
                                             TO_DATE (p_id_verification_date, 'mmddyyyy')
                                            ),
                      cci_tax_res_of_canada = p_tax_res_of_canada,
                      Cci_Tax_Payer_Id_Num = P_Tax_Payer_Id_Number,
                      Cci_Reason_For_No_Tax_Id =  P_Reason_For_No_Tax_Id,
                      Cci_Reasontype_For_No_Tax_Id=P_Reason_For_No_Tax_Id_type,
                      cci_jurisdiction_of_tax_res = v_jurisdiction_of_tax_res,
                      CCI_OCCUPATION_OTHERS = p_type_of_employment,
                      cci_seg12_name_line1_encr = fn_emaps_main(p_first_name),
                      cci_seg12_name_line2_encr = fn_emaps_main(p_lastname),
                      cci_seg12_addr_line1_encr = fn_emaps_main(p_physical_add_one),
                      cci_seg12_addr_line2_encr = fn_emaps_main(p_physical_add_two),
                      cci_seg12_city_encr = fn_emaps_main(p_city),
                      cci_seg12_postal_code_encr = fn_emaps_main(p_zipcode),
                      cci_seg12_emailid_encr = fn_emaps_main(p_email_add)
                WHERE cci_row_id = p_cci_row_id
                AND cci_inst_code = p_inst_code;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_cde := '21';
                  p_errmsg := 'Error while updating StarterCard Details';
                  RAISE exp_reject_record;
               END IF;
            END IF;

        UPDATE cms_caf_info_entry
               SET cci_kyc_flag = kyc_flag,
                   cci_process_msg = 'SUCCESS',
                   cci_kyc_reg_date = v_sysdate
            WHERE  cci_row_id = p_cci_row_id AND cci_inst_code = p_inst_code;

            -- Added inst_code on 02/01/2014 for FSS-1303
            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                         'Error while occured KYC Flag in CMS_CAF_INFO_ENTRY';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while updating KYC Flag in CMS_CAF_INFO_ENTRY-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            IF (p_delivery_channel <> '08')
            THEN
               IF (v_hash_pan IS NOT NULL)
               THEN
                  UPDATE cms_caf_info_entry
                     SET cci_override_flag = 1
                   WHERE cci_inst_code = p_inst_code
                     AND cci_starter_card_no = v_hash_pan
                     AND cci_appl_code IS NULL;
               ELSE
                  IF (p_document_verify = 'SSN' or p_document_verify='SIN' )
                  THEN
                     UPDATE cms_caf_info_entry
                        SET cci_override_flag = 1,
                            cci_orig_rowid = p_cci_row_id
                      WHERE cci_inst_code = p_inst_code
                        AND cci_ssn_encr = fn_emaps_main(p_id_number)
                        AND cci_prod_code = v_cci_prod_code
                        AND cci_override_flag = 0
                        AND cci_kyc_flag IN ('E', 'F');
                  ELSE
                     UPDATE cms_caf_info_entry
                        SET cci_override_flag = 1,
                            cci_orig_rowid = p_cci_row_id
                      WHERE cci_inst_code = p_inst_code
                        -- AND cci_id_number = p_id_number
                        --AND fn_dmaps_main(cci_id_number_encr) = p_id_number
                        AND cci_id_number_encr = fn_emaps_main(p_id_number)
                        AND cci_prod_code = v_cci_prod_code
                        AND cci_override_flag = 0
                        AND cci_kyc_flag IN ('E', 'F')
                        AND  cci_document_verify = p_document_verify;--Added by Abdul Hameed M.A on 24 Feb 2014 for 13737
                  END IF;
               END IF;
            END IF;
         END;
      --End FOR FSS-695
      END IF;

      IF p_card_no IS NULL AND (P_IDSCAN IS NULL OR (P_IDSCAN IS NOT NULL AND UPPER(TRIM(P_IDSCAN)) <> 'YES' ))
      THEN
         BEGIN
            sp_entry_newcaf_pcms_rowid (p_inst_code,
                                        p_cci_row_id,
                                        v_userbin,
                                        p_errmsg
                                       );

            IF p_errmsg <> 'OK'
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
               v_resp_cde := '21';
               p_errmsg :=
                     'Error from SP_ENTRY_NEWCAF_PCMS_ROWID'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT cci_appl_code
              INTO v_cci_appl_code
              FROM cms_caf_info_entry
             WHERE cci_inst_code = p_inst_code AND cci_row_id = p_cci_row_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while selecting Entry Record Type-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SP_GEN_PAN ( P_INST_CODE,
                        v_cci_appl_code,
                        v_userbin,
                        p_pan_number,
                        v_applproces_msg,
                        p_errmsg
                       );

            IF p_errmsg <> 'OK'
            THEN
               v_resp_cde := '21';
               RAISE exp_reject_record;
            END IF;

            IF v_applproces_msg <> 'OK'
            THEN
               v_resp_cde := '21';
               p_errmsg := v_applproces_msg;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while generating PAN' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT fn_dmaps_main (pan.cap_pan_code_encr),
                   pan.cap_pan_code_encr, pan.cap_acct_no, pan.cap_pan_code,
                   cust.ccm_cust_id, cust.ccm_cust_code,
                                                        -- Added for review changes on 16/Aug/2013.
                                                        pan.cap_prod_code,
                   -- Added for the defect id:12212
                   pan.cap_card_type          -- Added for the defect id:12212
              INTO p_pan_number,
                   v_encr_pan, p_acct_no, v_hash_pan,
                   p_cust_id, v_cust_code,
                                          -- Added for review changes on 16/Aug/2013.
                                          v_prod_code,
                   v_card_type
              FROM cms_appl_pan pan, cms_cust_mast cust
             WHERE pan.cap_appl_code = v_cci_appl_code
               AND pan.cap_cust_code = cust.ccm_cust_code
               AND pan.cap_inst_code = cust.ccm_inst_code
               AND pan.cap_inst_code = p_inst_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';
               p_errmsg := 'PAN Data is not defined in master';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while selecting PAN Data-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN

            SELECT cps_welcome_flag
              INTO p_cps_welcome_flag
              FROM cms_prodcatg_smsemail_alerts
             WHERE cps_inst_code = p_inst_code
               AND cps_prod_code = v_prod_code
               AND cps_card_type = v_card_type
              AND CPS_DEFALERT_LANG_FLAG='Y' AND cps_alert_id='1';
         --EN Commented and modified on 29.08.2013 for MVCSD-4099(Review)changes
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '21';
               p_errmsg := 'PAN Data is not defined in master';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while selecting PAN Data-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

      --Start Generate HashKEY for Mantis-14308
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TRAN_CODE||p_pan_number||P_RRN||to_char(v_timestamp,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        v_resp_cde := '21';
        p_errmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
     END;
    --End Generate HashKEY for Mantis-14308

    --AVQ Added for FSS-1961(Melissa)
          BEGIN
              SP_LOGAVQSTATUS(
              p_inst_code,
              P_DELIVERY_CHANNEL,
              p_pan_number,
              V_PROD_CODE,
              V_CUST_CODE,
              v_resp_cde,
              p_errmsg,
              v_card_type
              );
            IF p_errmsg <> 'OK' THEN
               p_errmsg  := 'Exception while calling LOGAVQSTATUS-- ' || p_errmsg;
               v_resp_cde := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
        EXCEPTION WHEN EXP_REJECT_RECORD
        THEN  RAISE;
        WHEN OTHERS THEN
           p_errmsg  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
           v_resp_cde := '21';
           RAISE EXP_REJECT_RECORD;
        END;
      --END Added for FSS-1961(Melissa)
    ELSE
   IF  P_IDSCAN IS NULL OR (P_IDSCAN IS NOT NULL AND UPPER(TRIM(P_IDSCAN)) <> 'YES' ) THEN
         BEGIN
            SELECT cci_appl_code
              INTO v_cci_appl_code
              FROM cms_caf_info_entry
             WHERE cci_inst_code = p_inst_code AND cci_row_id = p_cci_row_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while selecting Entry Record Type-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            sp_entry_newcaf_starter_to_gpr (p_inst_code,
                                            p_cci_row_id,
                                            p_card_no,
                                            v_userbin,
                                            p_errmsg
                                           );

            IF p_errmsg <> 'OK'
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
               v_resp_cde := '21';
               p_errmsg :=
                     'Error from Sp_Entry_Newcaf_Starter_To_GPR'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --Reg:Starter card to GPR card deactivation
         BEGIN
            UPDATE cms_appl_pan
               SET
                   cap_disp_name = p_first_name,
                   cap_ip_address =p_ipaddress
            WHERE  cap_pan_code = v_hash_pan
               AND cap_inst_code = p_inst_code;

            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                         'Error while updating cms_appl_pan for Deactivation';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while updating card status-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            UPDATE cms_appl_mast
               SET cam_reg_date = v_sysdate
             -- Modified for review changes on 16/Aug/2013.
            WHERE  cam_inst_code = p_inst_code AND cam_cust_code = v_cust_code;

            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_cde := '21';
               p_errmsg := 'Error while updating cms_appl_mast for reg_date';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while updating CMS_APPL_MAST-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN

            SELECT cpc_startergpr_issue
              INTO v_startercardissuancetype
              FROM cms_prod_cattype
             WHERE cpc_inst_code = p_inst_code
               AND cpc_prod_code = v_prod_code
               AND cpc_card_type = v_card_type;

         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while selecting data records from CMS_APPL_PAN-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         IF v_startercardissuancetype = 'A'
         THEN
            IF     p_delivery_channel = '08'

               AND p_tran_code = '34'  --Modified for Mantis- 13743 on 22-Feb-2014
               AND p_kyc_resp1 IS NULL
            THEN
               BEGIN
                  UPDATE cms_appl_mast
                     SET cam_appl_stat = 'A',
                         cam_starter_card = 'N'   -- Flag updated for Spil_3.0
                   WHERE cam_appl_code = v_cci_appl_code
                     AND cam_inst_code = p_inst_code;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_resp_cde := '21';
                     p_errmsg :=
                        'Error while updating cms_appl_mast for appl_stat and startercard flag';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     p_errmsg :=
                           'Error while updating CMS_APPL_MAST FOR APPL_STAT AND STARTERCARD FLAG'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            ELSE
               BEGIN
              IF UPPER(P_GPR_OPTIN)='Y' THEN --Added for FWR 70
                  UPDATE cms_appl_mast
                     SET cam_appl_stat = 'A'
                   WHERE cam_appl_code = v_cci_appl_code
                     AND cam_inst_code = p_inst_code;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_resp_cde := '21';
                     p_errmsg :=
                           'Error while updating cms_appl_mast for appl_stat';
                     RAISE exp_reject_record;
                  END IF; --Added for FWR 70
                END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     p_errmsg :=
                           'Error while updating CMS_APPL_MAST-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END IF;
IF UPPER(P_GPR_OPTIN)='Y' THEN  --Added for FWR 70

            BEGIN
               sp_gen_pan_starter_to_gpr (p_inst_code,
                                          v_cci_appl_code,
                                          v_userbin,
                                          v_gpr_card_no,
                                          v_applproces_msg,
                                          p_errmsg
                                         );

               IF p_errmsg <> 'OK'
               THEN
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
               END IF;

               IF v_applproces_msg <> 'OK'
               THEN
                  v_resp_cde := '21';
                  p_errmsg := v_applproces_msg;
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  p_errmsg :=
                        'Error while updating CMS_APPL_MAST-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            BEGIN
               SELECT fn_dmaps_main (pan.cap_pan_code_encr),
                      pan.cap_acct_no, cust.ccm_cust_id
                 INTO p_pan_number,
                      p_acct_no, p_cust_id
                 FROM cms_appl_pan pan, cms_cust_mast cust
                WHERE pan.cap_appl_code = v_cci_appl_code
                  AND pan.cap_cust_code = cust.ccm_cust_code
                  AND pan.cap_inst_code = cust.ccm_inst_code
                  And Pan.Cap_Inst_Code = P_Inst_Code
                  AND cap_startercard_flag = 'N' ;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  p_errmsg :=
                        'Error while selecting (gpr card)details from appl_pan :'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

             --AVQ Added for FSS-1961(Melissa)
                BEGIN
                    SP_LOGAVQSTATUS(
                    p_inst_code,
                    P_DELIVERY_CHANNEL,
                    p_pan_number,
                    V_PROD_CODE,
                    V_CUST_CODE,
                    v_resp_cde,
                    p_errmsg,
                    v_card_type
                    );
                  IF p_errmsg <> 'OK' THEN
                     p_errmsg  := 'Exception while calling LOGAVQSTATUS-- ' || p_errmsg;
                     v_resp_cde := '21';
                  RAISE EXP_REJECT_RECORD;
                  END IF;
                EXCEPTION WHEN EXP_REJECT_RECORD
                THEN  RAISE;
                WHEN OTHERS THEN
                   p_errmsg  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
                   v_resp_cde := '21';
                   RAISE EXP_REJECT_RECORD;
              END;
            --End Added for FSS-1961(Melissa)

   ELSE
--SN Added for FWR 70

    BEGIN
               SELECT  pan.cap_acct_no, cust.ccm_cust_id
                 INTO  p_acct_no, p_cust_id
                 FROM cms_appl_pan pan, cms_cust_mast cust
                WHERE pan.cap_appl_code = v_cci_appl_code
                  AND pan.cap_cust_code = cust.ccm_cust_code
                  AND PAN.CAP_INST_CODE = CUST.CCM_INST_CODE
                  AND pan.cap_inst_code = p_inst_code;

            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  P_ERRMSG :=
                        'Error while selecting acct_no from appl_pan :'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
            END;
   BEGIN
    UPDATE cms_appl_mast set CAM_STARTER_CARD= 'Y' WHERE
            CAM_APPL_CODE = v_cci_appl_code AND CAM_INST_CODE=p_inst_code;
                IF SQL%ROWCOUNT = 0 THEN
                v_resp_cde := '21';
                P_ERRMSG :=
                     'Error while Updating cms_appl_mast  v_appl_code:'
                  || v_appl_code;
               RAISE exp_reject_record;
                END IF;

            EXCEPTION
            WHEN exp_reject_record THEN
            RAISE exp_reject_record;
            WHEN OTHERS
            THEN
                v_resp_cde := '21';
               p_errmsg :=
                     'Error while updating cms_appl_mast'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
          END;

        BEGIN
            UPDATE CMS_ACCT_MAST
               SET cam_hold_count = cam_hold_count - 1,
                   cam_lupd_user = v_userbin
             WHERE cam_inst_code = p_inst_code AND cam_acct_no = p_acct_no;

            IF SQL%ROWCOUNT = 0
            THEN
                v_resp_cde := '21';
               p_errmsg :=
                       'Error while update acct ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                       'Error while update acct ' || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
         END;



END IF;
         ELSE
     --EN Added for FWR 70
            v_resp_cde := '1';
            p_errmsg := 'SUCCESS';
         END IF;
      END IF;
      END IF;



      IF v_hash_pan IS NOT NULL
      THEN
         BEGIN
            UPDATE cms_cust_mast
               SET ccm_kyc_flag = kyc_flag,
                   ccm_kyc_source = p_delivery_channel,
                   CCM_FLNAMEDOB_HASHKEY = gethash(UPPER(p_first_name)||UPPER(p_lastname)||TO_DATE (p_dob, 'mmddyyyy')), --Added for MVCAN-77 of 3.1 release
                   ccm_occupation = p_occupation,
                    ccm_id_province = p_id_province,
                    ccm_id_country = v_id_country,--p_id_country,
                    ccm_verification_date =  DECODE (P_DOCUMENT_VERIFY,
                                           'SSN', NULL,'SIN', NULL,
                                           TO_DATE (p_id_verification_date, 'mmddyyyy')
                                          ),
                    ccm_tax_res_of_canada = p_tax_res_of_canada,
                    Ccm_Tax_Payer_Id_Num = P_Tax_Payer_Id_Number,
                    Ccm_Reason_For_No_Tax_Id = P_Reason_For_No_Tax_Id_Type,
                    Ccm_Reason_For_No_Taxid_Others = Upper(P_Reason_For_No_Tax_Id),
                    ccm_jurisdiction_of_tax_res = upper(v_jurisdiction_of_tax_res),
                    Ccm_Occupation_Others = P_Type_Of_Employment,
                    ccm_Third_Party_Enabled=upper(P_Thirdpartyenabled )

             WHERE ccm_inst_code = p_inst_code AND ccm_cust_code = v_cust_code;

            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_cde := '21';
               p_errmsg := 'Error while updating KYC Flag in CMS_CUST_MAST';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while updating kyc flag in cust-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

            --St Added on 03/07/2013 for FSS-1672
               BEGIN
                  UPDATE cms_cardissuance_status
                     SET ccs_card_status = '15',
                         ccs_lupd_date = SYSDATE
                   WHERE ccs_appl_code = v_cci_appl_code
                     AND ccs_pan_code = v_hash_pan
                     AND ccs_inst_code = p_inst_code
                     AND ccs_card_status='31';

               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     p_errmsg :=
                           'Error while updating CMS_CARDISSUANCE_STATUS'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            --End Added on 03/07/2013 for FSS-1672
      END IF;
   --KYC SUCCESS END
   ELSE
      --KYC FAILURE STARTS   --ADDED FOR FSS-695
      BEGIN
         IF (p_delivery_channel <> '08') AND p_card_no IS NOT NULL
         THEN
            IF p_idologyid IS NULL
            THEN
               BEGIN
                  SELECT seq_dirupld_rowid.NEXTVAL
                    INTO v_seq_val_temp
                    FROM DUAL;

                  v_seq_val := TO_CHAR (v_seq_val_temp);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     p_errmsg :=
                           'Error while selecting Sequence Number-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               BEGIN
                  INSERT INTO cms_caf_info_entry
                              (cci_inst_code, cci_fiid,
                               cci_seg12_homephone_no, cci_seg12_name_line1,
                               cci_seg12_name_line2, cci_seg12_addr_line1,
                               cci_seg12_addr_line2, cci_seg12_city,
                               cci_seg12_state, cci_seg12_postal_code,
                               cci_seg12_country_code, cci_seg12_mobileno,
                               cci_seg12_emailid, cci_prod_code,
                               cci_requester_name,
                               cci_ssn,
                               cci_birth_date,
                               cci_document_verify,
                               cci_kyc_flag,
                               cci_row_id, cci_ins_date, cci_lupd_date,
                               cci_approved, cci_upld_stat,
                               cci_entry_rec_type, cci_instrument_realised,
                               cci_cust_catg, cci_comm_type,
                               cci_seg13_addr_param9, cci_title,
                               cci_id_issuer,
                               cci_id_number,
                               cci_seg13_addr_line1, cci_seg13_addr_line2,
                               cci_seg13_city, cci_seg13_state,
                               cci_seg13_postal_code,
                               cci_seg13_country_code,
                               cci_id_issuance_date,
                               cci_id_expiry_date,
                               cci_mothers_maiden_name, cci_card_type,
                               cci_seg12_state_code, cci_seg13_state_code,
                               cci_starter_card_no,
                               cci_starter_card_no_encr,
                               cci_starter_acct_no, cci_orig_rowid,
                               cci_idology_id,
                               cci_ssn_encr,
                               cci_id_number_encr,
			                         cci_occupation,
		                          --   cci_id_reference,
                               cci_id_province,
                               cci_id_country ,
                               cci_verification_date ,
                               cci_tax_res_of_canada,
                               cci_tax_payer_id_num,
                               cci_reason_for_no_tax_id,
                               cci_jurisdiction_of_tax_res,
                               CCI_OCCUPATION_OTHERS,
                               cci_seg12_name_line1_encr,
                               cci_seg12_name_line2_encr,
                               cci_seg12_addr_line1_encr,
                               cci_seg12_addr_line2_encr, 
                               cci_seg12_city_encr,
                               cci_seg12_postal_code_encr,
                               cci_seg12_emailid_encr
                              )
                       VALUES (p_inst_code, p_branch_code,
                               v_encr_telnum, v_encr_firstname,
                               v_encr_lastname, v_encr_p_add_one,
                               v_encr_p_add_two, v_encr_city,
                               p_state_switch, v_encr_zipcode,
                               P_CNTRY_CODE, v_encr_mobile_no,
                               v_encr_email_add, v_prod_code,
                               V_ENCR_REQUESTER_NAME,
                               fn_maskacct_ssn(P_inst_code,DECODE (p_document_verify, 'SSN', p_id_number,'SIN', p_id_number),0), --Modified for FWR 70
                               TO_DATE (p_dob, 'mmddyyyy'),
                               p_document_verify,
                               DECODE (p_idologyid, NULL, 'E', 'F'),
                               v_seq_val, SYSDATE, NULL,
                               'A', 'P',
                               'P', 'Y',
                               p_catg_sname, '0',
                               V_CURR_CODE, 'MR',
                               DECODE (P_DOCUMENT_VERIFY,
                                       'SSN', NULL,'SIN', NULL, --Modified for FWR 70
                                       p_id_issuer
                                      ),
                               fn_maskacct_ssn(p_inst_code,DECODE (P_DOCUMENT_VERIFY,
                                       'SSN', NULL,'SIN', NULL, --Modified for FWR 70
                                       p_id_number
                                      ),0),
                               v_encr_m_add_one, v_encr_m_add_two,
                               v_encr_m_city, p_mail_state_switch,
                               v_encr_m_zipcode,
                               p_mail_cntry_code,
                               DECODE (P_DOCUMENT_VERIFY,
                                       'SSN', NULL,'SIN', NULL,  --Modified for FWR 70
                                       TO_DATE (p_issuance_date, 'mmddyyyy')
                                      ),
                               DECODE (P_DOCUMENT_VERIFY,
                                       'SSN', NULL,'SIN', NULL,  --Modified for FWR 70
                                       TO_DATE (p_expiry_date, 'mmddyyyy')
                                      ),
                               v_encr_mothers_name, p_startergpr_crdtype,
                               p_state_code, p_mail_state_code,
                               v_hash_pan,
                               v_encr_pan,
                               v_cap_acct_no, p_cci_row_id,
                               p_kyc_idology_id,
                               fn_emaps_main(DECODE (p_document_verify, 'SSN', p_id_number,'SIN', p_id_number)),
                               fn_emaps_main(DECODE (P_DOCUMENT_VERIFY,'SSN', NULL,'SIN', NULL,p_id_number)),
                                p_occupation,
                                --    p_id_reference,
                                p_id_province,
                                v_id_country,--p_id_country,
                                DECODE (P_DOCUMENT_VERIFY,
                                                         'SSN', NULL,'SIN', NULL,
                                                         TO_DATE (p_id_verification_date, 'mmddyyyy')
                                                        ),
                                p_tax_res_of_canada,
                                p_tax_payer_id_number,
                                p_reason_for_no_tax_id,
                                v_jurisdiction_of_tax_res,
                                p_type_of_employment,
                                fn_emaps_main(p_first_name),
                                fn_emaps_main(p_lastname),
                                fn_emaps_main(p_physical_add_one),
                                fn_emaps_main(p_physical_add_two),
                                fn_emaps_main(p_city),
                                fn_emaps_main(p_zipcode),
                                fn_emaps_main(p_email_add)  
                              );

                  IF SQL%ROWCOUNT <> 1
                  THEN
                     v_resp_cde := '21';
                     p_errmsg := 'Insert not happen in CMS_CAF_INFO_ENTRY';
                     RAISE exp_reject_record;
                  END IF;
               END;
            ELSE
               BEGIN
                  SELECT cci_row_id
                    INTO v_seq_val
                    FROM cms_caf_info_entry
                   WHERE cci_inst_code = p_inst_code
                     AND cci_idology_id = p_idologyid;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_seq_val := p_cci_row_id;
               END;
            END IF;

            BEGIN
               UPDATE cms_kyctxn_log
                  SET ckl_row_id = v_seq_val
                WHERE ckl_row_id = p_cci_row_id
                      AND ckl_inst_code = p_inst_code;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_cde := '21';
                  p_errmsg :=
                         'Error while updating appl detail in CMS_KYCTXN_LOG';
                  RAISE exp_reject_record;
               END IF;
            END;
         end if;


         ---added for VMS-207
          IF v_hash_pan IS NOT NULL
      THEN
         BEGIN
            UPDATE cms_cust_mast
               SET ccm_occupation = p_occupation,
                    ccm_id_province = p_id_province,
                    ccm_id_country = v_id_country,
                    ccm_verification_date =  DECODE (P_DOCUMENT_VERIFY,
                                           'SSN', NULL,'SIN', NULL,
                                           TO_DATE (p_id_verification_date, 'mmddyyyy')
                                          ),
                    ccm_tax_res_of_canada = p_tax_res_of_canada,
                    Ccm_Tax_Payer_Id_Num = P_Tax_Payer_Id_Number,
                    Ccm_Reason_For_No_Tax_Id = P_Reason_For_No_Tax_Id_Type,
                    Ccm_Reason_For_No_Taxid_Others = Upper(P_Reason_For_No_Tax_Id),
                    ccm_jurisdiction_of_tax_res = upper(v_jurisdiction_of_tax_res),
                    Ccm_Occupation_Others = P_Type_Of_Employment,
                    ccm_Third_Party_Enabled=upper(P_Thirdpartyenabled )

             WHERE ccm_inst_code = p_inst_code AND ccm_cust_code = v_cust_code;

            IF SQL%ROWCOUNT = 0
            THEN
               v_resp_cde := '21';
               p_errmsg := 'Error while updating KYC Flag in CMS_CUST_MAST';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while updating kyc flag in cust-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

      END IF;

      END;

      IF v_seq_val IS NULL
      THEN
         v_seq_val := p_cci_row_id;
      END IF;

      --End for FSS-695
      BEGIN
         BEGIN
            SELECT COUNT (1)
              INTO v_count
              FROM cms_kyctxn_log
             WHERE ckl_cmsreq_refno = p_rrn
               AND TRUNC (ckl_kycreq_date) = TRUNC (v_sysdate);
         -- modified for review changes on 16/Aug/2013.
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while selecting (gpr card)details from appl_pan :'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         IF v_count = 0
         THEN
            IF p_idologyid IS NULL
            THEN                --Modified on 02/10/2013 for Mantis id :12515
               --kyc_flag     :='N';     -- Commented for Spil_3.0 Changes

               -- SN Added for Spil_3.0 Changes
               BEGIN 
               SELECT CASE
                       --  WHEN p_delivery_channel = '08' AND p_tran_code = '26' --Commented  for Mantis- 13743 on 22-Feb-2014
                        WHEN p_delivery_channel = '08' AND p_tran_code = '34'  --Modified  for Mantis- 13743 on 22-Feb-2014
                            THEN 'E'
                         ELSE 'N'
                      END
                 INTO kyc_flag
                 FROM DUAL;
               EXCEPTION 
               WHEN OTHERS
                    THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while selecting kyc_flag :'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;              
               
               END;
                 
            -- EN Added for Spil_3.0 Changes
            ELSE
               kyc_flag := 'E';
            END IF;

            --Added for Mantis:13713 on 20/02/2014

          IF (p_delivery_channel = '08' AND p_tran_code = '34')  --Modified  for Mantis- 13743 on 22-Feb-2014
            THEN
               BEGIN
                  INSERT INTO cms_kyctxn_log
                              (ckl_cmsreq_refno, ckl_row_id,
                               ckl_kycreq_date, ckl_inst_code,
                               ckl_kyc_type, ckl_kycres_date
                              )
                       VALUES (p_rrn, p_cci_row_id,
                               SYSDATE, p_inst_code,
                               'IDOLOGY Communication Failed', SYSDATE
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '89';
                     p_errmsg :=
                           'Error while inserting in CMS_KYCTXN_LOG '
                        || SUBSTR (SQLERRM, 1, 100);
                    RAISE exp_reject_record;
               END;
            END IF;

            --End  for Mantis:13713 on 20/02/2014
            BEGIN
               UPDATE cms_caf_info_entry
                  SET cci_kyc_flag = kyc_flag,
                      --Modified on 02/10/2013 for Mantis id :12515
                      cci_process_msg = 'IDOLOGY Communication Failed',
                      cci_kyc_reg_date = v_sysdate
                -- modified for review changes on 16/Aug/2013
               WHERE  cci_row_id = v_seq_val AND cci_inst_code = p_inst_code;

               -- Added inst_code on 02/01/2014 for FSS-1303
               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_cde := '21';
                  p_errmsg :=
                           'Error while updating CMS_CAF_INFO_ENTRY for flag';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  p_errmsg :=
                        'Error while updating CMS_CAF_INFO_ENTRY'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            IF v_hash_pan IS NOT NULL
            THEN
               BEGIN
                  UPDATE cms_cust_mast
                     SET ccm_kyc_flag = kyc_flag,
                         --Modified on 02/10/2013 for Mantis id :12515
                         ccm_kyc_source = p_delivery_channel,
                         CCM_FLNAMEDOB_HASHKEY = gethash(UPPER(p_first_name)||UPPER(p_lastname)||TO_DATE (p_dob, 'mmddyyyy')) --Added for MVCAN-77 of 3.1 release
                   WHERE ccm_inst_code = p_inst_code
                     AND ccm_cust_code = v_cust_code;
             IF SQL%ROWCOUNT = 0
                  THEN
                     v_resp_cde := '21';
                     p_errmsg := 'Error while updating CMS_CUST_MAST';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     p_errmsg :=
                           'Error while updating CMS_CUST_MAST'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --St Added for mantis id:12514 on 02/10/2013
               BEGIN
                  UPDATE cms_cardissuance_status
                     SET ccs_card_status = 31,
                         ccs_ins_date = SYSDATE,
                         ccs_lupd_date = SYSDATE
                   WHERE ccs_appl_code = v_appl_code
                     AND ccs_pan_code = v_hash_pan
                     AND ccs_inst_code = p_inst_code;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_resp_cde := '21';
                     p_errmsg :=
                               'Error while updating CMS_CARDISSUANCE_STATUS';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     p_errmsg :=
                           'Error while updating CMS_CARDISSUANCE_STATUS'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            --End Added on 02/10/2013 for Mantis id :12515
            END IF;

            v_resp_cde := '88';
            p_errmsg := 'IDOLOGY Communication Failed';
         ELSE
            IF p_kyc_resp2 IS NOT NULL AND p_kyc_resp2 > 0
            THEN
               IF p_idologyid IS NULL
               THEN
                  kyc_flag := 'E';
               ELSE
                  kyc_flag := 'F';
               END IF;

               BEGIN
                  UPDATE cms_caf_info_entry
                     SET cci_kyc_flag = kyc_flag,
                         cci_process_msg =
                                   'KYC Request Rejected and Questions Raised',
                         cci_kyc_reg_date = v_sysdate
                  WHERE  cci_row_id = v_seq_val
                         AND cci_inst_code = p_inst_code;

                  -- Added inst_code on 02/01/2014
                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_resp_cde := '21';
                     p_errmsg := 'Error while updating cms_caf_info_entry';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     p_errmsg :=
                           'Error while updating cms_caf_info_entry'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               IF v_hash_pan IS NOT NULL
               THEN
                  BEGIN
                     UPDATE cms_cust_mast
                        SET ccm_kyc_flag = kyc_flag,
                            ccm_kyc_source = p_delivery_channel,
                            CCM_FLNAMEDOB_HASHKEY = gethash(UPPER(p_first_name)||UPPER(p_lastname)||TO_DATE (p_dob, 'mmddyyyy')) --Added for MVCAN-77 of 3.1 release
                      WHERE ccm_inst_code = p_inst_code
                        AND ccm_cust_code = v_cust_code;
                    IF SQL%ROWCOUNT = 0
                     THEN
                        v_resp_cde := '21';
                        p_errmsg := 'KYC updation not happen';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_resp_cde := '21';
                        p_errmsg :=
                              'Error while updating CMS_CUST_MAST'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;
               END IF;

               v_resp_cde := '88';
               p_errmsg := 'KYC Request Rejected and Questions Raised';
            ELSE
               IF p_kyc_resp3 IS NOT NULL
               THEN
                  BEGIN
                     UPDATE cms_caf_info_entry
                        SET cci_kyc_flag = nvl(cci_kyc_flag,'N'),
                            cci_process_msg =
                                  'KYC Verification Failed'
                               || SUBSTR (p_kyc_resp3, 0, 200),
                            cci_kyc_reg_date = v_sysdate
                      -- Modified for review changes on 16/Aug/2013
                     WHERE  cci_row_id = v_seq_val
                        AND cci_inst_code = p_inst_code;

                     -- Added inst_code on 02/01/2014 for FSS-1303
                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_resp_cde := '21';
                        p_errmsg := 'Error while updating cms_caf_info_entry';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_resp_cde := '21';
                        p_errmsg :=
                              'Error while updating cms_caf_info_entry'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;

                  v_resp_cde := '99';
                  p_errmsg :=
                     'KYC Verification Failed' || SUBSTR (p_kyc_resp3, 0, 200);
               ELSE
                  IF p_idologyid IS NULL
                  THEN
                     kyc_flag := 'E';
                  ELSE
                     kyc_flag := 'F';
                  END IF;

                  BEGIN
                     UPDATE cms_caf_info_entry
                        SET cci_kyc_flag = kyc_flag,
                            cci_process_msg = 'KYC Verification Failed',
                            cci_kyc_reg_date = v_sysdate
                      -- Modified for review changes on 16/Aug/2013.
                     WHERE  cci_inst_code = p_inst_code
                        -- Added for review changes on 16/Aug/2013.
                        AND cci_row_id = v_seq_val;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_resp_cde := '21';
                        p_errmsg := 'Error while updating cms_caf_info_entry';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_resp_cde := '21';
                        p_errmsg :=
                              'Error while updating cms_caf_info_entry'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;

                  IF v_hash_pan IS NOT NULL
                  THEN
                     BEGIN
                        UPDATE cms_cust_mast
                           SET ccm_kyc_flag = kyc_flag,
                               --Modified on 02/10/2013 for Mantis id :12515
                               ccm_kyc_source = p_delivery_channel,
                               CCM_FLNAMEDOB_HASHKEY = gethash(UPPER(p_first_name)||UPPER(p_lastname)||TO_DATE (p_dob, 'mmddyyyy')) --Added for MVCAN-77 of 3.1 release
                         WHERE ccm_inst_code = p_inst_code
                           AND ccm_cust_code = v_cust_code;
                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_resp_cde := '21';
                           p_errmsg := 'KYC updation not happen';
                           RAISE exp_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_resp_cde := '21';
                           p_errmsg :=
                                 'Error while updating CMS_CUST_MAST'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     BEGIN
                        SELECT cci_ofac_fail_flag
                          INTO v_ofcaflag
                          FROM cms_caf_info_entry
                         WHERE cci_inst_code = p_inst_code
                           -- Added for review changes on 16/Aug/2013.
                           AND cci_row_id = v_seq_val;
                     EXCEPTION
                        WHEN OTHERS
                        THEN                           --no data found decline
                           v_resp_cde := '21';
                           p_errmsg :=
                                 'Error while selecting FAIL_FLAG details from cms_caf_info_entry :'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     IF v_ofcaflag = 'Y'
                     THEN
                        BEGIN
                           UPDATE cms_cust_mast
                              SET ccm_ofac_fail_flag = 'Y'
                            WHERE ccm_inst_code = p_inst_code
                              AND ccm_cust_code = v_cust_code;
                          IF SQL%ROWCOUNT = 0
                           THEN
                              v_resp_cde := '21';
                              p_errmsg :=
                                 'Error while updating cms_cust_mast for CCM_OFAC_FAIL_FLAG';
                              RAISE exp_reject_record;
                           END IF;
                        EXCEPTION
                           WHEN exp_reject_record
                           THEN
                              RAISE;
                           WHEN OTHERS
                           THEN
                              v_resp_cde := '21';
                              p_errmsg :=
                                    'Error while updating CMS_CUST_MAST'
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_record;
                        END;
                     END IF;

                     --Added for mantis id:12515 on 02/10/2013
                     BEGIN
                        UPDATE cms_cardissuance_status
                           SET ccs_card_status = 31,
                               ccs_ins_date = SYSDATE,
                               ccs_lupd_date = SYSDATE
                         WHERE ccs_appl_code = v_appl_code
                           AND ccs_pan_code = v_hash_pan
                           AND ccs_inst_code = p_inst_code;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_resp_cde := '21';
                           p_errmsg :=
                               'Error while updating CMS_CARDISSUANCE_STATUS';
                           RAISE exp_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_resp_cde := '21';
                           p_errmsg :=
                                 'Error while updating CMS_CARDISSUANCE_STATUS'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;
                  --End Added on 02/10/2013 for Mantis id :12515
                  END IF;

              IF P_IDSCAN IS NOT NULL AND UPPER (TRIM (P_IDSCAN))='YES' THEN

              v_resp_cde := '247';
              p_errmsg := 'KYC Verification Failed';

              ELSE

                  v_resp_cde := '99';
                  p_errmsg := 'KYC Verification Failed';

                  END IF;
               END IF;
            END IF;
         END IF;
      END;
   END IF;


-- Added for VMS-207


    if  P_Thirdpartyenabled Is Not Null And upper(P_Thirdpartyenabled)='Y' then
      Begin

      select to_number(gcm_cntry_code) into V_cntryCode
      from gen_cntry_mast
       where (GCM_SWITCH_CNTRY_CODE=upper(p_ThirdPartyCountry)
        or GCM_ALPHA_CNTRY_CODE=upper(p_ThirdPartyCountry))
       and Gcm_Inst_Code=p_inst_code;

     EXCEPTION
      When No_Data_Found Then
       P_Errmsg   := 'Invalid Country Code' ;
       v_resp_cde := '49';
       Raise exp_reject_record;
        When Others Then
         v_resp_cde := '89';
         P_Errmsg   := 'Error while selecting gen_cntry_mast ' || Substr(Sqlerrm, 1, 300);
         Raise exp_reject_record;
      End;

    if p_thirdpartytype = '1' and p_thirdpartyoccupationType is not null and p_thirdpartyoccupationType <> '00' then
      begin
       select vom_occu_name into v_occupation_desc
       from vms_occupation_mast
       where vom_occu_code =p_thirdpartyoccupationtype;

         EXCEPTION
           When No_Data_Found Then
             p_errmsg   := 'Invalid ThirdParty Occupation Code' ;
             v_resp_cde := '49';
             Raise exp_reject_record;
          when others then
           v_resp_cde := '89';
           p_errmsg   := 'Error while selecting Vms_Occupation_Mast ' || substr(sqlerrm, 1, 300);
           raise exp_reject_record;
      End;
    end if;
      If P_Thirdpartycountry Is Not Null And P_Thirdpartycountry  In ('US','CA','USA','CAN') Then

        Begin


        Select Gsm_Switch_State_Code,gsm_state_code  Into V_State_Switch_Code,v_state_code
        from gen_state_mast
        Where GSM_SWITCH_STATE_CODE=upper(P_Thirdpartystate)
        And Gsm_Cntry_Code=v_cntryCode and Gsm_Inst_Code=p_inst_code;

        EXCEPTION
         When No_Data_Found Then
           p_errmsg   := 'Invalid ThirdParty State Code' ;
           v_resp_cde := '49';
           Raise exp_reject_record;
          When Others Then
           v_resp_cde := '89';
           p_errmsg   := 'Error while selecting Gen_State_Mast ' || Substr(Sqlerrm, 1, 300);
           Raise exp_reject_record;
        end;
      Else
         v_state_code:=NULL;
        V_State_Desc:=P_Thirdpartystate;
        end if;
    Begin


      Insert Into Vms_Thirdparty_Address
      (Vta_Inst_Code,Vta_Cust_Code,VTA_THIRDPARTY_TYPE,VTA_FIRST_NAME,VTA_LAST_NAME,VTA_ADDRESS_ONE,VTA_ADDRESS_TWO,VTA_CITY_NAME,VTA_STATE_CODE,VTA_STATE_DESC,VTA_STATE_SWITCH,VTA_CNTRY_CODE,
    Vta_Pin_Code,Vta_Occupation,Vta_Occupation_Others,VTA_NATURE_OF_BUSINESS,VTA_DOB,VTA_NATURE_OF_RELEATIONSHIP,
    VTA_CORPORATION_NAME,VTA_INCORPORATION_NUMBER,Vta_Ins_User ,Vta_Ins_Date ,Vta_Lupd_User ,Vta_Lupd_Date)
    Values (P_Inst_Code,V_Cust_Code,P_Thirdpartytype,Upper(P_Thirdpartyfirstname),Upper(P_Thirdpartylastname),Upper(P_Thirdpartyaddress1),Upper(P_Thirdpartyaddress2),
    upper(p_thirdpartycity),v_state_code,upper(v_state_desc),v_state_switch_code,v_cntrycode,p_thirdpartyzip,p_thirdpartyoccupationtype,
    Upper(Decode(P_Thirdpartyoccupationtype,'00',P_Thirdpartyoccupation,V_Occupation_Desc)),Upper(P_Thirdpartybusiness),TO_DATE(P_Thirdpartydob,'mm/dd/yyyy'),Upper(P_Thirdpartynaturerelationship),Upper(P_Thirdpartycorporationname),
    upper(p_ThirdPartyCorporation),1,sysdate,1,sysdate);

      EXCEPTION
            When Others Then
             v_resp_cde := '89';
             p_errmsg   := 'Error while Inserting third party  address details in Vms_Thirdparty_Address ' ||'V_State_Code' ||V_State_Code ||'V_State_Desc' || V_State_Desc || 'P_Thirdpartydob' || P_Thirdpartydob || 'V_cntryCode ' || V_cntryCode||SUBSTR(SQLERRM, 1, 300);
             Raise exp_reject_record;
    End ;
  end if;

-- savings account creation


   IF  P_SAVINGSELIGIBILITY_FLAG IS NOT NULL AND P_SAVINGSELIGIBILITY_FLAG  =1  AND  UPPER (p_kyc_resp1) = 'TRUE' THEN



     BEGIN
                 SELECT  cdp_param_value
                 INTO V_TXN_AMT
                 FROM cms_dfg_param
                 WHERE cdp_param_key = 'InitialTransferAmount'
                 AND  cdp_inst_code = p_inst_code
                 AND cdp_prod_code = v_prod_code
                and  cdp_card_type= v_card_type;


     EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                       v_resp_cde := '21';
                       p_errmsg:='Saving account parameters is not defined for product '||v_prod_code;
                       RAISE EXP_REJECT_RECORD;
                   WHEN OTHERS THEN
                     v_resp_cde := '12';
                     p_errmsg:= 'Error while selecting min Initial Tran amt ' ||
                          SUBSTR(SQLERRM, 1, 200);
                     RAISE EXP_REJECT_RECORD;

     END;


     IF p_card_no IS NULL THEN

         v_pan_number_savingacct := p_pan_number;

         V_TXN_AMT := '0';
         V_GPRCARD_FLAG :='Y';
     ELSE
         v_pan_number_savingacct := p_card_no;


        V_GPRCARD_FLAG :='N';

        -- V_TXN_AMT := '0';

      END IF;

   V_TXN_CODE :=46;
   V_ACCT_FLAG :='YES';
   V_SAVACCT_CONSENT_FLAG :='Y';

  BEGIN
    SP_CREATE_SAVINGS_ACCT( p_inst_code  ,
                          v_pan_number_savingacct,
                          V_DELIVERY_CHANNEL,
                          V_TXN_CODE,
                          P_RRN ,
                          v_ACCT_FLAG,
                          '0',--P_TXN_MODE,
                          p_trandate,
                          p_trantime ,
                          p_ipaddress,
                          v_curr_code,--P_CURR_CODE,
                          '00',      --reversal code
                          p_inst_code,-- P_BANK_CODE,
                          '0200',-- P_MSG,
                          V_TXN_AMT,     --
                          V_SAVACCT_CONSENT_FLAG,
                          V_SAVINGS_BAL,
                          V_SPENDING_BAL,
                          V_SPENEINGLEG_BAL,
                          v_resp_cde ,
                          p_errmsg  ,
                          NULL,--P_OPTIN_LIST,
                         -- P_OPTIN,
                          v_spending_acctno,
                          v_savings_acctno,
                          V_GPRCARD_FLAG);

           IF  V_RESP_CDE <> '00' THEN

           RAISE exp_reject_record;

          END IF;

  EXCEPTION
    WHEN exp_reject_record THEN

    RAISE;
    WHEN OTHERS THEN
                    v_resp_cde := '12';
                     p_errmsg:= 'Error while creating savins account ' || SUBSTR(SQLERRM, 1, 200);
                     RAISE EXP_REJECT_RECORD;


  END;

 END IF;

     IF p_optin_list IS NOT NULL   AND  UPPER (p_kyc_resp1) = 'TRUE' THEN




      BEGIN

         LOOP


            v_comma_pos:= instr(p_optin_list,',',1,i);

            IF i=1 AND v_comma_pos=0 THEN
                v_optin_list:=p_optin_list;
            ELSIF i<>1 AND v_comma_pos=0 THEN
                v_comma_pos1:= instr(p_optin_list,',',1,i-1);
                v_optin_list:=substr(p_optin_list,v_comma_pos1+1);
             ELSIF i<>1 AND v_comma_pos<>0 THEN
                v_comma_pos1:= instr(p_optin_list,',',1,i-1);
                v_optin_list:=substr(p_optin_list,v_comma_pos1+1,v_comma_pos-v_comma_pos1-1);
            ELSIF i=1 AND v_comma_pos<>0 THEN
                v_optin_list:=substr(p_optin_list,1,v_comma_pos-1);
            END IF;

            i:=i+1;

            v_optin_type:=substr(v_optin_list,1,instr(v_optin_list,':',1,1)-1);
            v_optin:=substr(v_optin_list,instr(v_optin_list,':',1,1)+1);


          BEGIN
             IF v_optin_type IS NOT NULL AND v_optin_type = '1'
             THEN
                v_sms_optinflag := v_optin;
                 V_OPTIN_FLAG := 'Y';
             ELSIF v_optin_type IS NOT NULL AND v_optin_type = '2'
             THEN
                v_email_optinflag := v_optin;
                V_OPTIN_FLAG := 'Y';
             ELSIF v_optin_type IS NOT NULL AND v_optin_type = '3'
             THEN
                v_markmsg_optinflag := v_optin;
                V_OPTIN_FLAG := 'Y';
             ELSIF v_optin_type IS NOT NULL AND v_optin_type = '4'
             THEN
                v_gpresign_optinflag := v_optin;
                V_OPTIN_FLAG := 'Y';
              IF v_gpresign_optinflag='1' THEN  --Added for MVHOST-1249
                BEGIN

                  SELECT  CPC_TANDC_VERSION 
                   INTO v_tandc_version
                   FROM CMS_PROD_CATTYPE
					WHERE CPC_PROD_CODE=v_prod_code
					AND CPC_CARD_TYPE= V_CARD_TYPE
					AND CPC_INST_CODE=p_inst_code;

                EXCEPTION
                WHEN others THEN

                  v_resp_cde := '21';
                  p_errmsg :='Error from  featching the t and c version '|| SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;

                END;

                BEGIN

                        UPDATE cms_cust_mast
                        set ccm_tandc_version=v_tandc_version
                        WHERE ccm_inst_code=p_inst_code
                          AND ccm_cust_code=V_CUST_CODE;

                        IF  SQL%ROWCOUNT =0 THEN
                           v_resp_cde := '21';
                           p_errmsg :=
                                 'Error while updating t and c version '|| SUBSTR (SQLERRM, 1, 200);
                             RAISE exp_reject_record;

                        END IF;


                EXCEPTION

                 WHEN exp_reject_record THEN
                  RAISE ;
                 WHEN others THEN

                   v_resp_cde := '21';
                   p_errmsg :='Error while updating t and c version '|| SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
                END;
              END IF;
             END IF;
          END;

         IF V_OPTIN_FLAG = 'Y' THEN
              BEGIN
                 SELECT COUNT (*)
                   INTO v_count
                   FROM cms_optin_status
                  WHERE cos_inst_code = p_inst_code AND cos_cust_id = p_cust_id;

                 IF v_count > 0
                 THEN
                    UPDATE cms_optin_status
                       SET cos_sms_optinflag =
                                              NVL (v_sms_optinflag, cos_sms_optinflag),
                           cos_sms_optintime =
                              NVL (DECODE (v_sms_optinflag, '1', SYSTIMESTAMP, NULL),
                                   cos_sms_optintime
                                  ),
                           cos_sms_optouttime =
                              NVL (DECODE (v_sms_optinflag, '0', SYSTIMESTAMP, NULL),
                                   cos_sms_optouttime
                                  ),
                           cos_email_optinflag =
                                          NVL (v_email_optinflag, cos_email_optinflag),
                           cos_email_optintime =
                              NVL (DECODE (v_email_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_email_optintime
                                  ),
                           cos_email_optouttime =
                              NVL (DECODE (v_email_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_email_optouttime
                                  ),
                           cos_markmsg_optinflag =
                                      NVL (v_markmsg_optinflag, cos_markmsg_optinflag),
                           cos_markmsg_optintime =
                              NVL (DECODE (v_markmsg_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_markmsg_optintime
                                  ),
                           cos_markmsg_optouttime =
                              NVL (DECODE (v_markmsg_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_markmsg_optouttime
                                  ),
                           cos_gpresign_optinflag =
                                    NVL (v_gpresign_optinflag, cos_gpresign_optinflag),
                           cos_gpresign_optintime =
                              NVL (DECODE (v_gpresign_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_gpresign_optintime
                                  ),
                           cos_gpresign_optouttime =
                              NVL (DECODE (v_gpresign_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   cos_gpresign_optouttime
                                  )

                     WHERE cos_inst_code = p_inst_code AND cos_cust_id = p_cust_id;
                 ELSE
                    INSERT INTO cms_optin_status
                                (cos_inst_code, cos_cust_id, cos_sms_optinflag,
                                 cos_sms_optintime,
                                 cos_sms_optouttime,
                                 cos_email_optinflag,
                                 cos_email_optintime,
                                 cos_email_optouttime,
                                 cos_markmsg_optinflag,
                                 cos_markmsg_optintime,
                                 cos_markmsg_optouttime,
                                 cos_gpresign_optinflag,
                                 cos_gpresign_optintime,
                                 cos_gpresign_optouttime
                                )
                         VALUES (p_inst_code, p_cust_id, v_sms_optinflag,
                                 DECODE (v_sms_optinflag, '1', SYSTIMESTAMP, NULL),
                                 DECODE (v_sms_optinflag, '0', SYSTIMESTAMP, NULL),
                                 v_email_optinflag,
                                 DECODE (v_email_optinflag, '1', SYSTIMESTAMP, NULL),
                                 DECODE (v_email_optinflag, '0', SYSTIMESTAMP, NULL),
                                 v_markmsg_optinflag,
                                 DECODE (v_markmsg_optinflag,
                                         '1', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 DECODE (v_markmsg_optinflag,
                                         '0', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 v_gpresign_optinflag,
                                 DECODE (v_gpresign_optinflag,
                                         '1', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 DECODE (v_gpresign_optinflag,
                                         '0', SYSTIMESTAMP,
                                         NULL
                                        )
                                );
                 END IF;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    v_resp_cde := '21';
                    p_errmsg  :='ERROR IN INSERTING RECORDS IN CMS_OPTIN_STATUS' || SUBSTR (SQLERRM, 1, 300);
                    RAISE exp_reject_record;
              END;
         END IF;

              EXIT WHEN v_comma_pos=0;
              
        END LOOP;
        END;

     END IF;



   -- added for defect Id:12285
      --Added for LYFEHOST-58 27-09-2013
   BEGIN
      IF p_feeplanid IS NOT NULL AND kyc_flag IN ('Y', 'P', 'O','I')
      THEN
         BEGIN
            SELECT cfp_plan_desc
              INTO v_fee_plan_desc
              FROM cms_fee_plan
             WHERE cfp_plan_id = p_feeplanid AND cfp_inst_code = p_inst_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_cde := '131';
               p_errmsg := 'INVALID FEE PLAN ID ' || '--' || p_feeplanid;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while selecting FEE PLAN ID '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT COUNT (*)
              INTO v_feeplan_count
              FROM cms_feeplan_prod_mapg
             WHERE cfm_plan_id = p_feeplanid
               AND cfm_prod_code = v_prod_code
               AND cfm_inst_code = p_inst_code;

            IF v_feeplan_count = 0
            THEN
               v_resp_cde := '166';
               p_errmsg :=
                     'Fee Plan ID not linked to Product'
                  || '--'
                  || p_feeplanid
                  || '--'
                  || v_prod_code
                  || '--'
                  || v_feeplan_count;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while selecting FEE PLAN ID '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;



         BEGIN
            SELECT cpf_fee_plan, cpf_flow_source,
                   cpf_valid_from, cpf_valid_to

              INTO v_fee_plan_id, v_flow_source,
                   v_valid_from, v_valid_to

              FROM cms_prodcattype_fees
             WHERE cpf_inst_code = p_inst_code
               AND cpf_prod_code = v_prod_code
               AND cpf_card_type = v_card_type
                AND (   (    cpf_valid_to IS NOT NULL
                        AND (v_tran_date BETWEEN cpf_valid_from AND cpf_valid_to
                            )
                       )     --Added by Ramesh.A on 11/10/2012 for defect 9332
                    OR (cpf_valid_to IS NULL AND SYSDATE >= cpf_valid_from)
                   );

            INSERT INTO cms_card_excpfee
                        (cce_inst_code, cce_pan_code, cce_ins_date,
                         cce_ins_user, cce_lupd_user, cce_lupd_date,
                         cce_fee_plan, cce_flow_source, cce_valid_from,
                         cce_valid_to,cce_pan_code_encr,CCE_MBR_NUMB
                                             )
                 VALUES (p_inst_code, v_hash_pan, SYSDATE,
                         p_lupduser, p_lupduser, SYSDATE,
                         p_feeplanid, v_flow_source,v_valid_from, v_valid_to,v_encr_pan,'000'
                                          );

            SELECT cce_cardfee_id
              INTO v_cardfee_id
              FROM cms_card_excpfee
             WHERE cce_pan_code = v_hash_pan
               AND cce_inst_code = p_inst_code
               AND (   (    cce_valid_to IS NOT NULL
                        AND (v_tran_date BETWEEN cce_valid_from AND cce_valid_to
                            )
                       )          -- Condition added on 23Jan2013 Defect 10063
                    OR (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from)
                   );             -- Condition added on 23Jan2013 Defect 10063

            --- FOR HISTORY TABLE
            INSERT INTO cms_card_excpfee_hist
                        (cce_inst_code, cce_pan_code, cce_ins_date,
                         cce_ins_user, cce_lupd_user, cce_lupd_date,
                         cce_fee_plan, cce_flow_source,cce_valid_from, cce_valid_to,
                         cce_pan_code_encr, cce_cardfee_id, cce_mbr_numb

                        )                    --Added by Ramesh.A on 31/07/2012
                 VALUES (p_inst_code, v_hash_pan, SYSDATE,
                         p_lupduser, p_lupduser, SYSDATE,
                         p_feeplanid, v_flow_source,
                         v_valid_from, v_valid_to,
                         v_encr_pan, v_cardfee_id, '000'
                                                );                   --Added by Ramesh.A on 31/07/2012

            -- END HISTORY TABLE
            IF SQL%ROWCOUNT = 0
            THEN
               p_errmsg := 'inserting FEE PLAN ID IS NOT HAPPENED';
               v_resp_cde := '21';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE exp_reject_record;
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT cpf_fee_plan, cpf_flow_source,
                         cpf_valid_from, cpf_valid_to
                         INTO v_fee_plan_id, v_flow_source,
                         v_valid_from, v_valid_to
                            FROM cms_prod_fees
                   WHERE cpf_inst_code = p_inst_code
                     AND cpf_prod_code = v_prod_code
                              AND (   (    cpf_valid_to IS NOT NULL
                              AND (v_tran_date BETWEEN cpf_valid_from
                                                   AND cpf_valid_to
                                  )
                             )
                          --Added by Ramesh.A on 11/10/2012 for defect 9332
                          OR (    cpf_valid_to IS NULL
                              AND SYSDATE >= cpf_valid_from
                             )
                         );

                  INSERT INTO cms_card_excpfee
                              (cce_inst_code, cce_pan_code, cce_ins_date,
                               cce_ins_user, cce_lupd_user, cce_lupd_date,
                               cce_fee_plan, cce_flow_source,cce_valid_from, cce_valid_to, cce_pan_code_encr,CCE_MBR_NUMB
                                                        )
                       VALUES (p_inst_code, v_hash_pan, SYSDATE,
                               p_lupduser, p_lupduser, SYSDATE,
                               p_feeplanid,v_flow_source, --Updated by Ramesh.A on 30/07/2012
                               v_valid_from, v_valid_to,v_encr_pan,'000'
                                                       );

                  SELECT cce_cardfee_id
                    INTO v_cardfee_id
                    FROM cms_card_excpfee
                   WHERE cce_pan_code = v_hash_pan
                     AND cce_inst_code = p_inst_code
                     AND (   (    cce_valid_to IS NOT NULL
                              AND (v_tran_date BETWEEN cce_valid_from
                                                   AND cce_valid_to
                                  )
                             )    -- Condition added on 23Jan2013 Defect 10063
                          OR (    cce_valid_to IS NULL
                              AND SYSDATE >= cce_valid_from
                             )
                         );       -- Condition added on 23Jan2013 Defect 10063

                  --- FOR HISTORY TABLE
                  INSERT INTO cms_card_excpfee_hist
                              (cce_inst_code, cce_pan_code, cce_ins_date,
                               cce_mbr_numb, cce_ins_user, cce_lupd_user,
                               cce_lupd_date, cce_fee_plan, cce_flow_source,
                               cce_valid_from, cce_valid_to,cce_pan_code_encr, cce_cardfee_id
                                                       )
                       VALUES (p_inst_code, v_hash_pan, SYSDATE,
                               '000', p_lupduser, p_lupduser,
                               SYSDATE, v_fee_plan_id, v_flow_source,
                               v_valid_from, v_valid_to,v_encr_pan, v_cardfee_id
                                                        );

                  -- END HISTORY TABLE
                  IF SQL%ROWCOUNT = 0
                  THEN
                     p_errmsg := 'INSERTING FEE PLAN ID IS NOT HAPPENED';
                     v_resp_cde := '21';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE exp_reject_record;
                  WHEN NO_DATA_FOUND
                  THEN
                     BEGIN
                        SELECT cdm_flow_source, cdm_valid_from, cdm_valid_to
                        INTO   v_flow_source, v_valid_from, v_valid_to
                     	FROM   cms_default_glacct_mast
                         WHERE cdm_inst_code = p_inst_code;

                        INSERT INTO cms_card_excpfee
                                    (cce_inst_code, cce_pan_code,
                                     cce_ins_date, cce_ins_user,
                                     cce_lupd_user, cce_lupd_date,
                                     cce_fee_plan, cce_flow_source,
                                     cce_valid_from, cce_valid_to,cce_pan_code_encr,cce_mbr_numb
                                                                      )
                             VALUES (p_inst_code, v_hash_pan,
                                     SYSDATE, p_lupduser,
                                     p_lupduser, SYSDATE,
                                     p_feeplanid,v_flow_source,--Updated by Ramesh.A on 30/07/2012
                                     v_valid_from, v_valid_to, v_encr_pan,'000'
                                                                        );

                        SELECT cce_cardfee_id
                          INTO v_cardfee_id
                          FROM cms_card_excpfee
                         WHERE cce_pan_code = v_hash_pan
                           AND cce_inst_code = p_inst_code
                           AND (   (    cce_valid_to IS NOT NULL
                                    AND (v_tran_date BETWEEN cce_valid_from
                                                         AND cce_valid_to
                                        )
                                   )
                                -- Condition added on 23Jan2013 Defect 10063
                                OR (    cce_valid_to IS NULL
                                    AND SYSDATE >= cce_valid_from
                                   )
                               ); -- Condition added on 23Jan2013 Defect 10063

                        ---ST FOR HISTORY TABLE
                        INSERT INTO cms_card_excpfee_hist
                                    (cce_inst_code, cce_pan_code,
                                     cce_ins_date, cce_mbr_numb,
                                     cce_ins_user, cce_lupd_user,
                                     cce_lupd_date, cce_fee_plan,
                                     cce_flow_source,cce_valid_from,
                                     cce_valid_to,cce_pan_code_encr,cce_cardfee_id
                                                                      )
                             VALUES (p_inst_code, v_hash_pan,
                                     SYSDATE, '000',
                                     p_lupduser, p_lupduser,
                                     SYSDATE, p_feeplanid,
                                     v_flow_source, v_valid_from,
                                     v_valid_to, v_encr_pan,v_cardfee_id
                                            );

                        -- END HISTORY TABLE
                        IF SQL%ROWCOUNT = 0
                        THEN
                           p_errmsg :=
                              'inserting default FEE PLAN ID IS NOT HAPPENED';
                           v_resp_cde := '21';
                           RAISE exp_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE exp_reject_record;
                        WHEN NO_DATA_FOUND
                        THEN
                           p_errmsg :=
                                  'NO DATA FOUND IN DEFAULT GL MAPPING TABLE';
                           v_resp_cde := '21';
                           RAISE exp_reject_record;
                        WHEN OTHERS
                        THEN
                           p_errmsg :=
                                 'Error while selecting default entry in gl mapping '
                              || SUBSTR (SQLERRM, 1, 200);
                           v_resp_cde := '21';
                           RAISE exp_reject_record;
                     END;
                  WHEN OTHERS
                  THEN
                     p_errmsg :=
                           'Error while selecting fee plan details product level '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_resp_cde := '21';
                     RAISE exp_reject_record;
               END;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting fee plan details product card type level '
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

  ELSIF p_feeplanid IS NULL AND kyc_flag IN ('Y', 'P', 'O','I') and v_hash_pan is not null then

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
                              gethash(P_Pan_Number),
                              SYSDATE,
                              1,
                              1,
                              SYSDATE,
                              Cce_Fee_Plan,
                              Cce_Flow_Source,
                              Cce_Valid_From,
                              Cce_Valid_To,
                              Fn_Emaps_Main(P_Pan_Number),
                              Cce_Mbr_Numb,
                              Cce_St_Calc_Flag,
                              cce_cess_calc_flag,
                              cce_drgl_catg
                FROM CMS_CARD_EXCPFEE
               WHERE cce_pan_code = v_hash_pan
                 AND cce_inst_code = p_inst_code
                 AND (   (    cce_valid_to IS NOT NULL
                          AND (trunc(SYSDATE) BETWEEN cce_valid_from AND cce_valid_to
                              )
                         )   OR (cce_valid_to IS NULL AND trunc(SYSDATE) >= cce_valid_from)
                     ));
                  Exception
                      WHEN OTHERS THEN
                          p_errmsg  := 'Error while Inserting into cms_card_excpfee table ' ||
                                      SUBSTR(SQLERRM, 1, 100);
                          v_resp_cde := '21';
                          Raise Exp_Reject_Record;
            End;



      END IF;
   END;

   --End LYFEHOST-58
   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal,
             cam_type_code                    --Added on 10-Dec-2013 for 13160
        INTO v_acct_bal, v_ledger_bal,
             v_acct_type                      --Added on 10-Dec-2013 for 13160
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
                                        -- Added the inst code for review changes on 16/Aug/2013
             AND cam_acct_no = p_acct_no;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_acct_bal := 0;
         v_ledger_bal := 0;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         p_errmsg :=
               'Error while selecting Account Balance from CMS_ACCT_MAST-'
            || '- '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF p_delivery_channel = '08' AND p_tran_code IN ('30', '34') --Modified  for Mantis- 13743 on 22-Feb-2014
   THEN                                      -- TXN CODE 26 added for Spil_3.0
      BEGIN
         SELECT DECODE (v_resp_cde, '88', '69', '99', '133', v_resp_cde)
           INTO v_resp_cde
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            p_errmsg :=
                  'Error while getting SPIL specific responses '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   END IF;

   --En Added by Pankaj S. for SPIL Target registration
   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = TO_NUMBER (p_delivery_channel)
         AND cms_response_id = TO_NUMBER (v_resp_cde);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Problem while selecting data from response master for respose code'
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         v_resp_cde := '21';
         RAISE exp_reject_record;
   END;

	IF v_prod_code IS NULL
	THEN
	v_prod_code := v_cci_prod_code;
	END IF;

	IF v_card_type IS NULL
	THEN
	v_card_type := v_cci_card_type;
	END IF;
        BEGIN
      INSERT INTO transactionlog
                  (rrn, txn_code, msgtype, business_date, business_time,
                   currencycode, productid, categoryid, trans_desc,
                   instcode, delivery_channel, txn_status, response_code,
                   customer_acct_no, customer_card_no,
                   customer_card_no_encr, proxy_number, acct_balance,
                   ledger_balance, customer_starter_card_no,
                   --Added on 24/09/2013 for mantis id :12449
                   gprcardapplicationno,
                   --Added on 24/09/2013 for mantis id :12449
                   response_id, error_msg,
                   ipaddress, fee_plan,                  --LYFEHOST-58 Changes
                                       --Added on 10-Dec-2013 for 13160
                                       acct_type, cardstatus,
                   time_stamp, cr_dr_flag,ANI, -- Added for FSS-1747
                  --Added on 10-Dec-2013 for 13160
                  transactionlog --Added for jh-3043
                  )
                    VALUES (p_rrn, p_tran_code, V_MSGTYPE, p_trandate, p_trantime,-- Added for Mantis 13712 on  20 Feb 14
                   v_curr_code, v_prod_code, v_card_type, v_trans_desc,
                   p_inst_code, p_delivery_channel, 'C', p_resp_code,
                   p_acct_no, v_hash_pan,
                   v_encr_pan, v_proxy_no, NVL (v_acct_bal, 0),
                   NVL (v_ledger_bal, 0), v_encr_pan,
                   --Added on 24/09/2013 for mantis id :12449
                   v_cci_appl_code, --Added on 24/09/2013 for mantis id :12449
                   DECODE (v_resp_cde, '00', '1', v_resp_cde), p_errmsg,
                   p_ipaddress, p_feeplanid,             --LYFEHOST-58 Changes
                                            --Added on 10-Dec-2013 for 13160
                                            v_acct_type, v_card_stat,
                   v_timestamp, v_cr_dr_flag,P_ANI, -- Added for FSS-1747
                                  P_SHIPPING_METHOD  --Added for jh-3043
                  );

      IF SQL%ROWCOUNT <> 1
      THEN
         v_resp_cde := '21';
         p_errmsg := 'Insert not happen in TRANSACTIONLOG';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '89';
         p_errmsg :=
               'Error while inserting in TRANSACTIONLOG '
            || SUBSTR (SQLERRM, 1, 100);
   END;
      -- added for defect Id:12285
   BEGIN
      INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                   ctd_business_date, ctd_business_time, ctd_txn_curr,
                   ctd_rrn, ctd_inst_code, ctd_process_flag,
                   ctd_process_msg, ctd_cust_acct_number,
                   CTD_CUSTOMER_CARD_NO_ENCR, CTD_MOBILE_NUMBER , CTD_DEVICE_ID,  CTD_HASHKEY_ID  --Added for Mantis-14308
                   ,ctd_gpr_optin,CTD_CUSTOMER_CARD_NO, --Modified for FWR 70
                   ctd_customer_field1,ctd_customer_field2  --Added for NCGPR-1581
                  )
                 VALUES (p_delivery_channel, p_tran_code, V_MSGTYPE,-- Added for Mantis 13712 on  20 Feb 14
                   p_trandate, p_trantime, v_curr_code,
                   p_rrn, p_inst_code, 'Y',
                   p_errmsg, p_acct_no,                   --Modified for spil3.0 by Dayanand p_errmsg instead of by default successful -mantis-13743 on 22-Feb-2014
                   v_encr_pan,                             --Added for Spil_3.0
                   P_DEVICE_MOBILE_NO,--Added for MOB-62
                   P_DEVICE_ID, --Added for MOB-62
                   V_HASHKEY_ID --Added for Mantis-14308
                   ,p_gpr_optin,v_hash_pan,  --Modified for FWR 70
                   p_customer_field1,p_customer_field2  --Added for NCGPR-1581
                  );

      IF SQL%ROWCOUNT <> 1
      THEN
         v_resp_cde := '21';
         p_errmsg := 'Insert not happen in CMS_TRANSACTION_LOG_DTL';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '89';
         p_errmsg :=
               'Error while inserting in CMS_TRANSACTION_LOG_DTL '
            || SUBSTR (SQLERRM, 1, 100);
   END;
--  END IF;
--update log table for succss case
EXCEPTION                                              --- Main Exception-----
   WHEN exp_reject_record
   THEN
      ROLLBACK;

      -- added for defect Id:12285
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code                 --Added on 10-Dec-2013 for 13160
           INTO v_acct_bal, v_ledger_bal,
                v_acct_type                   --Added on 10-Dec-2013 for 13160
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code AND cam_acct_no = p_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_acct_bal := 0;
            v_ledger_bal := 0;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            p_errmsg :=
                  'Error while selecting Account Balance from CMS_ACCT_MAST-'
               || '- '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      --Sn Added by Pankaj S. for SPIL Target registration
      IF     p_delivery_channel = '08'
         --AND p_tran_code IN ('30', '26')     -- Txm code 26 added for Spil_3.0 --Commented  for Mantis- 13743  on 22-Feb-2014
        AND p_tran_code IN ('30', '34') -- Modified  for Mantis- 13743  on 22-Feb-2014
      THEN
         BEGIN
            SELECT DECODE (v_resp_cde, '88', '69', '99', '133', v_resp_cde)
              INTO v_resp_cde
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               p_errmsg :=
                     'Error while getting SPIL specific responses '
                  || SUBSTR (SQLERRM, 1, 300);
         END;
      END IF;

      --En Added by Pankaj S. for SPIL Target registration
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = TO_NUMBER (p_delivery_channel)
            AND cms_response_id = TO_NUMBER (v_resp_cde);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting data from response master for respose code'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
      END;

      -- SN --Added on 10-Dec-2013 for 13160
      IF v_card_stat IS NULL
      THEN
         BEGIN
            SELECT cap_cust_code, cap_prod_code,
                                                cap_card_type,
                                                              cap_acct_no,
                   cap_proxy_number, cap_appl_code,
                   --Added on 02/10/2013 for Mantis id :12515
                   cap_card_stat              --Added on 10-Dec-2013 for 13160
              INTO v_cust_code, v_prod_code,
                                            --Added on 29.08.2013 for MVCSD-4099(Review)changes
                                            v_card_type,
                                                        p_acct_no,
                   v_proxy_no, v_appl_code, --Added on 02/10/2013 for Mantis id :12515
                   v_card_stat
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_cr_dr_flag IS NULL
      THEN
         BEGIN                                   -- added for defect Id:12285
            SELECT ctm_tran_desc, ctm_credit_debit_flag
              INTO v_trans_desc, v_cr_dr_flag
              FROM cms_transaction_mast
             WHERE ctm_inst_code = p_inst_code
               AND ctm_tran_code = p_tran_code
               AND ctm_delivery_channel = p_delivery_channel;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_prod_code IS NULL
      THEN
	  v_prod_code := v_cci_prod_code;
      END IF;

      IF v_card_type IS NULL
      THEN
	  v_card_type := v_cci_card_type;
      END IF;
           BEGIN
         INSERT INTO transactionlog
                     (rrn, txn_code, msgtype, business_date, business_time,
                      currencycode, productid, categoryid, trans_desc,
                      instcode, delivery_channel, txn_status, response_code,
                      acct_balance, ledger_balance,
                      response_id, error_msg, ipaddress, fee_plan,
                      acct_type, cardstatus, time_stamp, cr_dr_flag,
                      CUSTOMER_CARD_NO_ENCR,ANI,    --Added during spil_3.0 changes
                      transactionlog --Added for jh-3043
                     )             
            VALUES (p_rrn, p_tran_code, V_MSGTYPE, p_trandate, p_trantime,-- Added for Mantis 13712 on  20 Feb 14
                      v_curr_code, v_prod_code, v_card_type, v_trans_desc,
                      p_inst_code, p_delivery_channel, 'F', p_resp_code,
                      NVL (v_acct_bal, 0), NVL (v_ledger_bal, 0),
                      v_resp_cde, p_errmsg, p_ipaddress, p_feeplanid,
                      v_acct_type, v_card_stat, v_timestamp, v_cr_dr_flag,
                      v_encr_pan,P_ANI, -- Added for FSS-1747               --Added during spil_3.0 changes
                      P_SHIPPING_METHOD --Added for jh-3043
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '89';
            p_errmsg :=
                  'Error while inserting in Transactionlog '
               || SUBSTR (SQLERRM, 1, 100);
      END;
     -- added for defect Id:12285
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_business_date, ctd_business_time, ctd_txn_curr,
                      ctd_rrn, ctd_inst_code, ctd_process_flag,
                      CTD_PROCESS_MSG, CTD_CUSTOMER_CARD_NO_ENCR, CTD_MOBILE_NUMBER ,CTD_DEVICE_ID, CTD_HASHKEY_ID --Added for Mantis-14308
                      ,ctd_gpr_optin,CTD_CUSTOMER_CARD_NO,  --Modified for FWR 70
                      ctd_customer_field1,ctd_customer_field2  --Added for NCGPR-1581
                     )
             VALUES (p_delivery_channel, p_tran_code,V_MSGTYPE,-- Added for Mantis 13712 on  20 Feb 14
                      p_trandate, p_trantime, v_curr_code,
                      p_rrn, p_inst_code, 'E',
                      p_errmsg, v_encr_pan,     --Added during spil_3.0 changes
                      P_DEVICE_MOBILE_NO,--Added for MOB-62
                      P_DEVICE_ID, --Added for MOB-62
                      V_HASHKEY_ID --Added for Mantis-14308
                      ,p_gpr_optin,v_hash_pan,  --Modified for FWR 70
                      p_customer_field1,p_customer_field2  --Added for NCGPR-1581
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '89';
            p_errmsg :=
                  'Error while inserting in CMS_TRANSACTION_LOG_DTL '
               || SUBSTR (SQLERRM, 1, 100);
      END;
   -- END IF;
   WHEN OTHERS
   THEN
      --update log table for faliyre  case
      p_resp_code := '89';
      p_errmsg := 'Main Excp-' || SUBSTR (SQLERRM, 1, 200);
END;

/
show error

