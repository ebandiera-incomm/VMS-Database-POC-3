create or replace
PROCEDURE VMSCMS.SP_ACTIVATE_INTIALLOAD_PROFILE (
   p_instcode           IN       NUMBER,
   p_rrn                IN       VARCHAR2,
   p_terminalid         IN       VARCHAR2,
   p_stan               IN       VARCHAR2,
   p_trandate           IN       VARCHAR2,
   p_trantime           IN       VARCHAR2,
   p_acctno             IN       VARCHAR2,
   p_amount             IN       NUMBER,
   p_currcode           IN       VARCHAR2,
   p_lupduser           IN       NUMBER,
   p_msg_type           IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_mbr_numb           IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_ssn                IN       VARCHAR2,
   p_dob                IN       DATE,
   p_first_name         IN       VARCHAR2,
   p_middle_name        IN       VARCHAR2,
   p_last_name          IN       VARCHAR2,
   p_addr_lineone       IN       VARCHAR2,
   p_addr_linetwo       IN       VARCHAR2,
   p_city               IN       VARCHAR2,
   p_zip                IN       VARCHAR2,
   p_phone_no           IN       VARCHAR2,
   p_other_no           IN       VARCHAR2,
   p_email              IN       VARCHAR2,
   p_state              IN       VARCHAR2,
   p_cntry_code         IN       VARCHAR2,
   p_prod_id            IN       VARCHAR2,
   p_prod_catg          IN       VARCHAR2,
   p_merchant_name      IN       VARCHAR2,
   p_merchant_city      IN       VARCHAR2,
   p_fee_plan_id        IN       VARCHAR2,  -- Added by Ramesh.A on 20/07/2012
   p_mailaddr_lineone   IN       VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
   p_mailaddr_linetwo   IN       VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
   p_mailaddr_city      IN       VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
   p_mailaddr_state     IN       VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
   p_mailaddr_zip       IN       VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
   p_mailaddr_cnrycode  IN       VARCHAR2,  -- Added by MageshKumar.S on 25/04/2013
   P_StoreID            IN       VARCHAR2,  -- Added by Ravi N for regarding JH-8
   P_Optin              IN       VARCHAR2,  -- Added by Ravi N for regarding JH-8
   P_TaxPrepareID       IN       VARCHAR2,  -- Added by Ravi N for regarding JH-8
   P_REASON_CODE        in       varchar2,  -- Added by Ravi N for regarding JH-8
   P_GPR_OPTIN          IN       VARCHAR2,  -- Added for JH 3011
   p_resp_code          OUT      VARCHAR2,
   p_errmsg             OUT      VARCHAR2,
   p_dda_number         OUT      VARCHAR2,  -- Added by Ramesh.A on 20/07/2012
   p_optin_list         IN       VARCHAR2,
   p_business_name_in   IN       VARCHAR2,  -- Added for FSS-3626 for 3.2 release
    --Added on 09-10-2017--START
   p_occupation         IN        VARCHAR2,
   P_Id_Province        IN        VARCHAR2,
   P_Id_Country         IN        VARCHAR2,
   P_Id_Expiry_Date     IN        VARCHAR2,   
   P_Id_Verification_Date         IN      VARCHAR2,
   P_Reason_For_No_Tax_Id_Type    IN      VARCHAR2,
   P_Tax_Res_Of_Canada            IN      VARCHAR2,
   P_Tax_Payer_Id_Number          IN      VARCHAR2,
   p_reason_for_no_tax_id         IN      VARCHAR2,
   p_jurisdiction_of_tax_res      IN      VARCHAR2,
   P_Id_Type                      IN      VARCHAR2,
   p_type_of_employment           IN      VARCHAR2,
   p_ThirdPartyEnabled            IN      VARCHAR2,
   p_ThirdPartyType               In      VARCHAR2,
   p_ThirdPartyFirstName          IN      VARCHAR2,
   p_ThirdPartyLastName           IN      VARCHAR2,
   p_ThirdPartyCorporationName    IN      VARCHAR2,
   p_ThirdPartyCorporation        IN      VARCHAR2,
   p_ThirdPartyAddress1           IN      VARCHAR2,
   p_ThirdPartyAddress2           IN      VARCHAR2,
   p_ThirdPartyCity               IN      VARCHAR2,
   p_ThirdPartyState              IN      VARCHAR2,
   p_ThirdPartyZIP                IN      VARCHAR2,
   p_ThirdPartyCountry            IN      VARCHAR2,
   p_ThirdPartyNatureRelationship IN      VARCHAR2,
   p_ThirdPartyBusiness           IN      VARCHAR2,
   p_ThirdPartyOccupationType     IN      VARCHAR2,
   p_ThirdPartyOccupation         IN      VARCHAR2,
   p_ThirdPartyDOB                IN      VARCHAR2,
   p_termid_in                    IN      VARCHAR2 default null,
   p_funding_account              IN      VARCHAR2 default null,
   p_merchantZipCode              IN      VARCHAR2 default null, -- added for VMS-622 (redemption_delay zip code validation)
   p_member_id                    IN      VARCHAR2 --Added on 22-03-2021 for VMS-3846 --END
    
)
AS
   /********************************************************************************************
      * Modified BY      : B.Besky
      * Modified for     : Defect 9968,10063
      * Modified Reason  : 1) DFG STARTER CARD UPGRADE PROCESS IN MMPOS CARD ACTIVATION :
                           EXISTING FEE PLAN IS NOT UPDATE IN HISTORY TABLE (9968)
                           2) Card feeId is selected only for active fee plan (10063)
      * Modified Date    : 22/01/2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 22/01/2013
      * Release Number   : CMS3.5.1_RI0023.1_B0007

      * Modified By      :  Pankaj S.
      * Modified Date    :  05-Feb-2013
      * Modified Reason  :  Multiple SSN check
      * Reviewer         :  Dhiraj

      * Modified By      :  Sagar
      * Modified Date    :  12-Feb-2013
      * Modified Reason  :  v_errmsg replaced by v_respmsg
      * Reviewer         :  Dhiraj
      * Reviewed Date    :
      * Build Number     :

      * modified by      : Pankaj S.
      * modified for     : FSS-391
      * modified Date    : 15-Feb-2013
      * modified reason  : card replacement changes
      * Reviewer         : Dhiarj
      * Reviewed Date    :
      * Build Number     :

      * Modified By      : Pankaj S.
      * Modified Date    : 15-Mar-2013
      * Modified Reason  : Logging of system initiated card status change(FSS-390)
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : CMS3.5.1_RI0024_B0008

      * Modified By      : MageshKumar S.
      * Modified Date    : 25-Apr-2013
      * Modified Reason  : Logging of Mailing Address changes in Addr mast(DFCHOST-310)

      * Modified By      : Ramesh.A.
      * Modified Date    : 25-Apr-2013
      * Modified Reason  : DFCCSD-59 , Added validation  mapping for feeplan with product.
      * Reviewer         : Dhiraj
      * Reviewed Date    : 29-Apr-2013
      * Build Number     : RI0024.0.1_B0004

      * Modified By      : Sagar M.
      * Modified Date    : 30-Apr-2013
      * Modified Reason  : Modified for performance changes
      * Modified for     : DFCHOST-311
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : CMS3.5.1_RI0024.0.1_B0007

      * Modified By      : Dhinakaran B
      * Modified Date    : 11-Jul-2013
      * Modified Reason  : Update the switch state code in Address Master Table
      * Modified for     : FSS-919(Mantis ID-11457)
      * Reviewer         :
      * Reviewed Date    :
      * Build Number     : CMS3.5.1_RI0024.3_B0003

      * Modified By      : Santosh P
      * Modified Date    : 17-Jul-2013
      * Modified Reason  : Capture terminalId in StoreId column of transactionlog table
      * Modified for     : FSS-1146
      * Reviewer         :
      * Reviewed Date    :
      * Build Number     : RI0024.3_B0005

      * Modified By      : Siva Kumar Arcot
      * Modified Date    : 16-Aug-2013
      * Modified Reason  : Updating  KYC Source Through MMPOS Delivery Channel
      * Modified for     : DFCHOST-337
      * Reviewer         : Dhiraj
      * Reviewed Date    : 16-Aug-2013
      * Build Number     : RI0024.4_B0004

      * Modified By      : Ravi N
      * Modified Date    : 05-SEP-2013
      * Modified Reason  : Capture STOREID,OPTIN,TaxPrepareID into transactionlog dtl table
      * Modified for     : JH-8,
      * Reviewer         : Dhiraj
      * Reviewed Date    : 05-SEP-2013
      * Build Number     : RI0024.4_B0010

      * Modified By      : Ramesh
      * Modified Date    : 14-SEP-2013
      * Modified Reason  : commented duplicate rrn code and update to kyc flag(handled in java)
      * Modified for     : JH-58,
      * Reviewer         : dhiraj
      * Reviewed Date    :
      * Build Number     : RI0024.4_B0012

      * Modified By      : Sai Prasad
      * Modified Date    : 15-SEP-2013
      * Modified Reason  : based on OPT-In value, alert is not working
      * Modified for     : 0012337 JH-8
      * Reviewer         : dhiraj
      * Reviewed Date    : 16-SEP-2013
      * Build Number     : RI0024.4_B0013

      * Modified By      : Anil Kumar
      * Modified Date    : 16-SEP-2013
      * Modified Reason  : To Update The Inventory Card Current Stock
      * Modified for     : DFCHOST-345
      * Reviewer         : SAGAR
      * Reviewed Date    : 16-SEP-2013
      * Build Number     : RI0024.4_B0015

      * Modified By      : Sai Prasad
      * Modified Date    : 23-SEP-2013
      * Modified Reason  : To Update The Inventory Card Current Stock
      * Modified for     : DFCHOST-345 (Review)
      * Reviewer         : Dhiraj
      * Reviewed Date    : 23-SEP-2013
      * Build Number     : RI0024.4_B0018

      * Modified By      : RameshA
      * Modified Date    : 24-SEP-2013
      * Modified Reason  : Mantis id : 12449 and 12464
      * Modified for     : logging card number values in log table
      * Reviewer         : Dhiraj
      * Reviewed Date    : 23-SEP-2013
      * Build Number     : RI0024.4_B0018

      * Modified By      : RameshA
      * Modified Date    : 25-SEP-2013
      * Modified Reason  : Mantis id : 12464
      * Modified for     : logging card number values in log table
                           Change in update query on line 2881
      * Reviewer         : Dhiraj
      * Reviewed Date    : 25-SEP-2013
      * Build Number     : RI0024.4_B0019

      * Modified By      : MageshKumar S.
      * Modified Date    : 19-Sep-2013
      * Modified Reason  : JH-6(Fast50 SMS and Email Alert)
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19-Sep-2013
      * Build Number     : RI0024.4_B0019

      * Modified By      : Anil Kumar
      * Modified Date    : 04-Oct-13
      * Modified Reason  : JH-60
      * Reviewer         : Dhiraj
      * Reviewed Date    : 04-Oct-13
      * Build Number     : RI0024.5_B0001


      * Modified By      : RameshA
      * Modified Date    : 10-OCT-2013
      * Modified Reason  : DFCCHW-360(1.7.4.3 changes merged)
      * Modified for     : DFCCHW-360 - DFC CHW - Not able to Create Online Account
      * Reviewer         : Dhiraj
      * Reviewed Date    : 10-Oct-2013
      * Build Number     : RI0024.5_B0005

      * Modified By      : Anil Kumar
      * Modified Date    : 24-Oct-13
      * Modified Reason  : JH-8(Additional Changes)
      * Reviewer         : Dhiraj
      * Reviewed Date    : 25-Oct-2013
      * Build Number     : RI0024.6_B0003

      * Modified By      : Sagar More
      * Modified Date    : 13-Jan-14
      * Modified Reason  : Performace Fix
      * Reviewer         : Dhiraj
      * Reviewed Date    : 13-Jan-14
      * Build Number     : RI0024.6.2.2_B0003

      * Modified by       : Sagar
      * Modified for      :
      * Modified Reason   : Concurrent Processsing Issue
                            (1.7.6.7 changes integarted)
      * Modified Date     : 04-Mar-2014
      * Reviewer          : Dhiarj
      * Reviewed Date     : 06-Mar-2014
      * Build Number      : RI0027.1.1_B0001

      * Modified by       : MageshKumar S.
      * Modified Date     : 25-July-14
      * Modified For      : FWR-48
      * Modified reason   : GL Mapping removal changes
      * Reviewer          : Spankaj
      * Build Number      : RI0027.3.1_B0001

      * Modified By       : Raja Gopal G
      * Modified Date     : 30-Jul-2014
      * Modified Reason   : Check Deposit Pending ,Accepted And Rejected Alerts(FWR 67)
      * Reviewer          : Spankaj
      * Build Number      : RI0027.3.1_B0002

      * Modified by       : MageshKumar S.
      * Modified Date     : 12-August-14
      * Modified For      : FSS-1785
      * Modified reason   : 2.2.5 integration of FSS-1785 into 2.3.1
      * Reviewer          : Spankaj
      * Build Number      : RI0027.3.1_B0003

      * Modified by       : Abdul Hameed M.A
      * Modified for      : JH 3012
      * Modified Reason   : New error code and error message added for all fast transactions.
      * Modified Date     : 22-August-2014
      * Reviewer          : Spankaj
      * Build Number      : RI0027.3.2_B0001

      * Modified by       : Dhinakaran B
      * Modified for      : JH-3023
      * Modified Date     : 26-AUG-2014
      * Build Number      : RI0027.3.2_B0002

      * Modified by       : Siva Kumar M
      * Modified for      : JH 3020
      * Modified Reason   : Duplicate Account Check
      * Modified Date     : 28-August-2014
      * Build Number      : RI0027.3.2_B0002

      * Modified by       : Abdul Hameed M.A
      * Modified for      : JH 3011
      * Modified Reason   : GPR  card should be generated for the starter card if GPROPTIN is "N" and starter to gpr is manual.
      * Modified Date     : 01-SEP-2014
      * Build Number      : RI0027.3.2_B0002

      * Modified by       : Siva Kumar M
      * Modified for      : Mantis id:15743
      * Modified Reason   : New Duplicate Account : System allows multiple registration with in the configured time
      * Modified Date     : 08-sept-2014
      * Build Number      : RI0027.3.2_B0004

      * Modified by       : Sai
      * Modified for      : FWR-70
      * Modified Date     : 04-Oct-2014
      * Reviewer          : Spankaj
      * Build Number      : RI0027.4_B0003

      * Modified by       : Abdul Hameed M.A
      * Modified for      : JH-3062
      * Modified Date     : 18-Dec-2014
      * Reviewer          : spankaj
      * Build Number      : RI0027.5_B0001

      * Modified by       : Abdul Hameed M.A
      * Modified Date     : 06-Jan-2015
      * Reviewer          : spankaj
      * Build Number      : RI0027.5_B0005

       * Modified by       : Ramesh A
       * Modified for      : FSS-2263
       * Modified Date     : 17-MAR-15
       * Reviewer          : Spankaj
       * Build Number      : RI0027.4.3.4 Integration to 2.5.1

       * Modified by      : Pankaj S.
       * Modified for     : Transactionlog Functional Removal
       * Modified Date    : 13-May-2015
       * Reviewer         :  Saravanankumar
       * Build Number     : VMSGPRHOAT_3.0.3_B0001

       * Modified by                  : MageshKumar S.
       * Modified Date                : 23-June-15
       * Modified For                 : MVCAN-77
       * Modified reason              : Canada account limit check
       * Reviewer                     : Spankaj
       * Build Number                 : VMSGPRHOSTCSD3.1_B0001

       * Modified by                  : Ramesh A.
       * Modified Date                : 13-Aug-15
       * Modified For                 : FWR-59
       * Modified reason              : SMS and Email ALerts
       * Reviewer                     : Spankaj
       * Build Number                 : VMSGPRHOSTCSD3.1_B0002

     * Modified by      :Abdul Hameed M.A
       * Modified Date    : 21-Aug-15
       * Modified For     : 16169
       * Reviewer         : Spankaj
       * Build Number     : VMSGPRHOSTCSD3.1_B0004

       * Modified by      : MageshKumar S
       * Modified Date    : 14-Sep-15
       * Modified For     : FSS-3626
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD3.2

       * Modified by      :Spankaj
       * Modified Date    : 07-Sep-15
       * Modified For     : FSS-2321
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD3.2

        * Modified by      : Ramesh A
        * Modified Date    : 30-Sep-15
        * Modified For     : FSS-3626
        * Reviewer         : Saravanankumar
        * Build Number     : VMSGPRHOSTCSD3.2

        * Modified by       :Spankaj
       * Modified Date    : 23-Dec-15
       * Modified For     : FSS-3925
       * Reviewer            : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD3.3

       * Modified by       :Spankaj
       * Modified Date    : 06-Jan-16
       * Modified For     : MVHOST-1249
       * Reviewer            : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD3.3

       * Modified by       :Siva kumar
       * Modified Date    : 06-Jan-16
       * Modified For     : VPP-177
       * Reviewer            : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD3.3


       * Modified by       :Siva kumar
       * Modified Date    : 18-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006

        * Modified by     : A.Sivakaminathan
        * Modified Date   : 29-Mar-16
        * Modified For    : Partner_id logged null
        * Reviewer        : Saravanakumar
        * Build Number    : VMSGPRHOSTCSD_4.0_B008

       * Modified by      : MageshKumar S.
       * Modified Date    : 14-June-16
       * Modified For     : FSS-3927
       * Modified reason  : Canada account limit check
       * Reviewer         : Saravanakumar/Spankaj
       * Build Number     : VMSGPRHOSTCSD4.2_B0002

       * Modified by      : Pankaj S.
       * Modified Date    : 09-Mar-17
       * Modified For     : FSS-4647
       * Modified reason  : Redemption Delay Changes
       * Reviewer         : Saravanakumar
       * Build Number     : VMSGPRHOST_17.3
	* Modified by      : T.Narayanaswamy
       * Modified Date    : 11-Mar-17
       * Modified For     : FSS-5070
       * Modified reason  : Remove Hardcode/Implement Configuration for Minimum Age Validation: MMPOS
       * Reviewer         : Saravanakumar/Spankaj
       * Build Number     : VMSGPRHOST 17.4

       * Modified by      : MageshKumar
       * Modified Date    : 10-MAY-17
       * Modified For     : FSS-5103
       * Reviewer         : Saravanankumar/Spankaj
       * Build Number     : VMSGPRHOSTCSD17.05_B0001

           * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07
		 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07

     * Modified By      : T.Narayanaswamy.
     * Modified Date    : 04/08/2017
     * Purpose          : FSS-5157 - B2B Gift Card - Phase 2
     * Reviewer         : Saravanan/Pankaj S.
     * Release Number   : VMSGPRHOST17.08
	 
	 * Modified By      : Akhil
     * Modified Date    : 05/01/2018
     * Purpose          : VMS-78
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST17.12
     
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01
	 
	 * Modified By      : DHINAKARAN B
     * Modified Date    : 29-JUN-2018
     * Purpose          : VMS-344
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : VMSGPRHOST R03
     
     * Modified By      : Baskar K
     * Modified Date    : 21-AUG-2018
     * Purpose          : VMS-454
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : VMSGPRHOST R05
	 
	 * Modified By      : Veneetha C
     * Modified Date    : 21-JAN-2019
     * Purpose          : VMS-622 Redemption delay for activations /reloads processed through ICGPRM
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST R11
     
    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
    
    * Modified By      : MAGESHKUMAR S
    * Modified Date    : 22-MAR-2021
    * Purpose          : VMS-3846.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R44
	
	* Modified By      : Saravana Kumar.A
    * Modified Date    : 24-DEC-2021
    * Purpose          : VMS-5378 : Need to update ccm_system_generate_profile flag in Retail / Card stock flow.
    * Reviewer         : Venkat. S
    * Release Number   : VMSGPRHOST_R56 Build 2.
   ************************************************************************************************/
   v_cap_prod_catg          cms_appl_pan.cap_prod_catg%TYPE;
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_cap_cafgen_flag        cms_appl_pan.cap_cafgen_flag%TYPE;
   v_firsttime_topup        cms_appl_pan.cap_firsttime_topup%TYPE;
   v_errmsg                 transactionlog.error_msg%type;
   v_currcode               transactionlog.currencycode%type;
   v_appl_code              cms_caf_info_entry.cci_appl_code%TYPE; -- Added    on 13-Jan-2014
   v_resoncode              cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_respcode               transactionlog.response_code%type;
   v_respmsg                transactionlog.error_msg%type;
   v_authmsg                transactionlog.error_msg%type;
   v_capture_date           DATE;
   v_mbrnumb                cms_appl_pan.cap_mbr_numb%TYPE;
   v_txn_type               cms_func_mast.cfm_txn_type%TYPE;
   v_inil_authid            transactionlog.auth_id%TYPE;
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_remrk                  cms_pan_spprt.cps_func_remark%type;
   v_delchannel_code        cms_delchannel_mast.cdm_channel_code%type;
   v_base_curr              cms_inst_param.cip_param_value%TYPE;
   v_tran_date              DATE;
   v_tran_amt               cms_acct_mast.cam_acct_bal%type;
   v_card_curr              VARCHAR2 (5);
   v_acct_balance           cms_acct_mast.cam_acct_bal%type;
   v_ledger_balance         cms_acct_mast.cam_ledger_bal%type;
   v_business_date          transactionlog.date_time%type;
   v_business_time          transactionlog.business_time%type;
   v_cutoff_time            transactionlog.business_time%type;
   valid_cardstat_count     PLS_INTEGER;
   v_card_topup_flag        PLS_INTEGER;
   v_cust_code              cms_cust_mast.ccm_cust_code%TYPE;
   v_prod_code_count        VARCHAR2 (5);
   v_mmpos_usageamnt        cms_translimit_check.ctc_mmposusage_amt%TYPE;
   v_mmpos_usagelimit       cms_translimit_check.ctc_mmposusage_limit%TYPE;
   v_business_date_tran     cms_translimit_check.ctc_business_date%type;
   v_addr_lineone           cms_addr_mast.CAM_ADD_ONE%type;
   v_addr_linetwo           cms_addr_mast.CAM_ADD_TWO%type;
   v_city_name              cms_addr_mast.CAM_CITY_NAME%type;
   v_pin_code               cms_addr_mast.CAM_PIN_CODE%type;
   v_phone_no               cms_addr_mast.CAM_PHONE_ONE%type;
   v_mobl_no                cms_addr_mast.CAM_MOBL_ONE%type;
   v_email                  cms_addr_mast.CAM_EMAIL%type;
   v_state_code             cms_addr_mast.cam_state_code%type;
   v_ctnry_code             cms_addr_mast.cam_cntry_code%type;
   v_ssn                    cms_cust_mast.ccm_ssn%type;
   v_birth_date             cms_cust_mast.ccm_birth_date%type;
   v_first_name             cms_cust_mast.CCM_FIRST_NAME%type;
   v_mid_name               cms_cust_mast.CCM_MID_NAME%type;		
   v_last_name              cms_cust_mast.CCM_LAST_NAME%type;      
   v_store_count            PLS_INTEGER;                                 -- ADDED FOR STORE ID CONFIG
   v_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%type;
   v_output_type            cms_transaction_mast.ctm_output_type%type;
   v_tran_type              cms_transaction_mast.ctm_tran_type%type;
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   v_comb_hash              pkg_limits_check.type_hash;              -- Added by Dhiraj G on 12072012 for Pre - LIMITS BRD  
   v_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE; -- Added by Dhiraj G on 12072012 for Pre - LIMITS BRD  
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;   --SN:added by amit on 20-Jul-2012 for activation part in LIMITS
   v_inst_code              cms_appl_pan.cap_inst_code%TYPE;
   v_lmtprfl                cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
   v_profile_level          cms_appl_pan.cap_prfl_levl%TYPE;
   v_fee_plan_desc          cms_fee_plan.cfp_plan_desc%TYPE;    --EN:added by amit on 20-Jul-2012 for activation part in LIMITS
   v_fee_plan_id            cms_card_excpfee.cce_fee_plan%TYPE;
   v_flow_source            cms_card_excpfee.cce_flow_source%TYPE;
   v_crgl_catg              cms_card_excpfee.cce_crgl_catg%TYPE;
   v_crgl_code              cms_card_excpfee.cce_crgl_code%TYPE;
   v_crsubgl_code           cms_card_excpfee.cce_crsubgl_code%TYPE;
   v_cracct_no              cms_card_excpfee.cce_cracct_no%TYPE;
   v_drgl_catg              cms_card_excpfee.cce_drgl_catg%TYPE;
   v_drgl_code              cms_card_excpfee.cce_drgl_code%TYPE;
   v_drsubgl_code           cms_card_excpfee.cce_drsubgl_code%TYPE;
   v_dracct_no              cms_card_excpfee.cce_dracct_no%TYPE;
   v_valid_from             cms_card_excpfee.cce_valid_from%TYPE;
   v_valid_to               cms_card_excpfee.cce_valid_to%TYPE;
   v_st_crgl_catg           cms_card_excpfee.cce_st_crgl_catg%TYPE;
   v_st_crgl_code           cms_card_excpfee.cce_st_crgl_code%TYPE;
   v_st_crsubgl_code        cms_card_excpfee.cce_st_crsubgl_code%TYPE;
   v_st_cracct_no           cms_card_excpfee.cce_st_cracct_no%TYPE;
   v_st_drgl_catg           cms_card_excpfee.cce_st_drgl_catg%TYPE;
   v_st_drgl_code           cms_card_excpfee.cce_st_drgl_code%TYPE;
   v_st_drsubgl_code        cms_card_excpfee.cce_st_drsubgl_code%TYPE;
   v_st_dracct_no           cms_card_excpfee.cce_st_dracct_no%TYPE;
   v_cess_crgl_catg         cms_card_excpfee.cce_cess_crgl_catg%TYPE;
   v_cess_crgl_code         cms_card_excpfee.cce_cess_crgl_code%TYPE;
   v_cess_crsubgl_code      cms_card_excpfee.cce_cess_crsubgl_code%TYPE;
   v_cess_cracct_no         cms_card_excpfee.cce_cess_cracct_no%TYPE;
   v_cess_drgl_catg         cms_card_excpfee.cce_cess_drgl_catg%TYPE;
   v_cess_drgl_code         cms_card_excpfee.cce_cess_drgl_code%TYPE;
   v_cess_drsubgl_code      cms_card_excpfee.cce_cess_drsubgl_code%TYPE;
   v_cess_dracct_no         cms_card_excpfee.cce_cess_dracct_no%TYPE;
   v_st_calc_flag           cms_card_excpfee.cce_st_calc_flag%TYPE;
   v_cess_calc_flag         cms_card_excpfee.cce_cess_calc_flag%TYPE;
   v_cardfee_id             cms_card_excpfee.cce_cardfee_id%TYPE;
   v_cap_appl_code          cms_appl_pan.cap_appl_code%TYPE;
   v_cap_cust_code          cms_appl_pan.cap_cust_code%TYPE;
   v_ssn_crddtls            transactionlog.ssn_fail_dtls%type;                          -- Added by Besky on 09/01/2013 to update the KYC flag in CMS_CUST_MAST table for 9957
   v_dup_check              PLS_INTEGER;                                                -- Added by Pankaj S. on 15-Feb-2013 for Card replacement changes(FSS-391)
   v_oldcrd                 cms_htlst_reisu.chr_pan_code%TYPE;                          -- Added by Pankaj S. on 15-Feb-2013 for Card replacement changes(FSS-391)
   v_mailing_addr_count      PLS_INTEGER;                                               -- Sn:Added by Mageshkumar.S on 25-Apr-2013 for defect Id:DFCHOST-310
   v_mailing_switch_state_code   cms_addr_mast.cam_state_switch%TYPE;
   v_phys_switch_state_code      cms_addr_mast.cam_state_switch%TYPE ;
   v_curr_code                   gen_cntry_mast.gcm_curr_code%TYPE;                     -- En:Added by Mageshkumar.S on 25-Apr-2013 for defect Id:DFCHOST-310
   v_feeplan_count               PLS_INTEGER ;                                          -- Added by Ramesh.A on 26/04/2013 for DFCCSD-59
   V_HASHKEY_ID                 CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;            -- Added for JH-8
   V_TIME_STAMP                 TIMESTAMP;                                              -- Added for JH-8
   v_loadcredit_flag        cms_prodcatg_smsemail_alerts.cps_loadcredit_flag%TYPE;      -- sn Added for 0012337 JH-8
   v_lowbal_flag            cms_prodcatg_smsemail_alerts.cps_lowbal_flag%TYPE;
   v_negativebal_flag       cms_prodcatg_smsemail_alerts.cps_negativebal_flag%TYPE;
   v_highauthamt_flag       cms_prodcatg_smsemail_alerts.cps_highauthamt_flag%TYPE;
   v_dailybal_flag          cms_prodcatg_smsemail_alerts.cps_dailybal_flag%TYPE;
   v_insuffund_flag         cms_prodcatg_smsemail_alerts.cps_insuffund_flag%TYPE;
   V_Incorrectpin_Flag      Cms_Prodcatg_Smsemail_Alerts.Cps_Incorrectpin_Flag%Type;    -- en Added for 0012337 JH-8
   V_Cmm_Merprodcat_Id      Cms_Merinv_Merpan.Cmm_Merprodcat_Id%Type;                   -- Added for DFCHOST-345
   v_fast50_flag            cms_Prodcatg_Smsemail_Alerts.cps_fast50_Flag%Type;          -- Added by MageshKumar.S on 19/09/2013
   v_federal_flag           cms_Prodcatg_Smsemail_Alerts.CPS_FEDTAX_REFUND_FLAG%Type;   -- Added by MageshKumar.S on 19/09/2013
   V_Loccheck_Flg           cms_prod_cattype.CPC_LOCCHECK_FLAG%Type;                    -- Added for JH-8(Additional Changes) on 24/10/2013
   V_Cmm_Mer_Id             Cms_Merinv_Merpan.Cmm_Mer_Id%Type;
   V_Cmm_Location_Id        Cms_Merinv_Merpan.Cmm_Location_Id%Type;                     -- End for JH-8(Additional Changes)
   v_actv_flag              cms_prod_cattype.CPC_INVCHECK_FLAG%Type;                    -- Added for fss-1785
   v_dup_ssnchk             cms_prod_cattype.cpC_dup_ssnchk%TYPE;                       -- added for JH-3020 changes.
   v_dup_timeperiod         cms_prod_cattype.cpC_dup_timeperiod%TYPE;
   v_dup_timeunt            cms_prod_cattype.cpC_dup_timeunt%TYPE;
   V_DAYS_DIFF              cms_product_param.cpp_dup_timeperiod%TYPE;
   V_WEEKS_DIFF             cms_product_param.cpp_dup_timeperiod%TYPE;
   V_MONTHS_DIFF            cms_product_param.cpp_dup_timeperiod%TYPE;
   V_YEARS_DIFF             cms_product_param.cpp_dup_timeperiod%TYPE;
   v_active_date            cms_appl_pan.cap_active_date%TYPE;
   v_new_registrition       varchar2(1) ;
   v_cardactive_dt          cms_appl_pan.cap_active_date%TYPE;
   V_FLDOB_HASHKEY_ID       CMS_CUST_MAST.CCM_FLNAMEDOB_HASHKEY%TYPE;                   --Added for MVCAN-77 OF 3.1 RELEASE
   L_ALERT_LANG_ID          cms_prodcatg_smsemail_alerts.CPS_ALERT_LANG_ID%TYPE;
   V_OPTIN                  VARCHAR2(1);
   v_sms_optinflag          cms_optin_status.cos_sms_optinflag%TYPE;                    --Sn Added for FSS-3626 Implementation for MMPOS
   v_email_optinflag        cms_optin_status.cos_email_optinflag%TYPE;
   v_markmsg_optinflag      cms_optin_status.cos_markmsg_optinflag%TYPE;
   v_gpresign_optinflag     cms_optin_status.cos_gpresign_optinflag%TYPE;
   v_savingsesign_optinflag cms_optin_status.cos_savingsesign_optinflag%TYPE;
   v_optin_type             cms_optin_status.cos_sms_optinflag%TYPE;
   v_optin_split            cms_optin_status.cos_sms_optinflag%TYPE;
   v_optin_list             VARCHAR2(1000);
   v_comma_pos              PLS_INTEGER;
   v_comma_pos1             PLS_INTEGER;
   i                        PLS_INTEGER:=1;
   v_tandc_version          CMS_PROD_CATTYPE.CPC_TANDC_VERSION%TYPE;
   V_OPTIN_FLAG             VARCHAR2(10) DEFAULT 'N';
   v_cust_id                cms_cust_mast.ccm_cust_id%TYPE;
   v_count                  PLS_INTEGER;                                                --En Added for FSS-3626 Implementation for MMPOS
   v_redmption_delay_flag   cms_prod_cattype.cpc_redemption_delay_flag%TYPE;            --Sn Added for FSS-4647
   v_txn_redmption_flag     cms_transaction_mast.ctm_redemption_delay_flag%TYPE;
   v_min_age_kyc            cms_prod_cattype.cpc_min_age_kyc%TYPE;
   v_agecal                 PLS_INTEGER;                                                --En Added for FSS-4647
   V_CPC_PROD_DENO          CMS_PROD_CATTYPE.CPC_PROD_DENOM%TYPE;
   V_CPC_PDEN_MIN           CMS_PROD_CATTYPE.CPC_PDENOM_MIN%TYPE;
   V_CPC_PDEN_MAX           CMS_PROD_CATTYPE.CPC_PDENOM_MAX%TYPE;
   V_CPC_PDEN_FIX           CMS_PROD_CATTYPE.CPC_PDENOM_FIX%TYPE;
   V_PROFILE_CODE           CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
   v_varprodflag            CMS_PROD_CATTYPE.CPC_RELOADABLE_FLAG%TYPE;
   v_id_province            GEN_STATE_MAST.GSM_SWITCH_STATE_CODE%TYPE;
   v_id_country             GEN_CNTRY_MAST.GCM_ALPHA_CNTRY_CODE%TYPE;
   v_jurisdiction_of_tax_res GEN_CNTRY_MAST.GCM_ALPHA_CNTRY_CODE%TYPE;
   V_ENCRYPT_ENABLE         CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;      
   V_ZIPCODE                cms_addr_mast.CAM_PIN_CODE%type;
   v_encr_addr_lineone      cms_addr_mast.CAM_ADD_ONE%type;
   v_encr_addr_linetwo      cms_addr_mast.CAM_ADD_TWO%type;
   v_encr_city              cms_addr_mast.CAM_CITY_NAME%type;
   v_encr_email             cms_addr_mast.CAM_EMAIL%type;
   v_encr_phone_no          cms_addr_mast.CAM_PHONE_ONE%type;
   v_encr_mob_one           cms_addr_mast.CAM_MOBL_ONE%type;        
   v_encr_first_name        cms_cust_mast.CCM_FIRST_NAME%type; 
   v_encr_last_name         cms_cust_mast.CCM_LAST_NAME%type; 
   v_encr_mid_name          cms_cust_mast.CCM_MID_NAME%type;       
   V_Occupation_Desc        Vms_Occupation_Mast.Vom_Occu_Name%Type;  
   V_State_Switch_Code      Gen_State_Mast.Gsm_Switch_State_Code%Type;
   V_Cntrycode              Number(10);
   V_State_Desc             Vms_Thirdparty_Address.Vta_State_Desc%Type;
   V_Third_party_State_Code Vms_Thirdparty_Address.Vta_State_Code%Type;
   v_update_excp            EXCEPTION;                                                    -- Added by Mageshkumar.S on 25-Apr-2013 for defect Id:DFCHOST-310
   exp_main_reject_record   EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
   
    CURSOR ALERTDTLS (p_instcode IN VARCHAR2,P_prod_code IN VARCHAR2,p_card_type IN VARCHAR2,p_alert_lang_id IN VARCHAR2) IS
    SELECT cps_config_flag, SUBSTR(CPS_ALERT_MSG,1,1) alert_flag,CPS_ALERT_ID
        FROM cms_prodcatg_smsemail_alerts
       WHERE cps_inst_code = p_instcode
         AND cps_prod_code = p_prod_code
         AND cps_card_type = p_card_type
         AND cps_alert_lang_id=p_alert_lang_id;

BEGIN
   p_errmsg := 'OK';
   v_remrk := 'CARD ACTIVATION WITH PROFILE';
   V_TIME_STAMP :=SYSTIMESTAMP;      --Added for JH-8

   v_new_registrition:='N';
   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (p_acctno);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN CREATE HASH PAN

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_acctno);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN create encr pan
   
   --Start Generate HashKEY value for JH-8
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||p_acctno||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        P_RESP_CODE := '21';
        v_errmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_main_reject_record;
     END;
   --End Generate HashKEY value for JH-8

   --Sn find debit and credit flag
   BEGIN
      
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_prfl_flag,
             ctm_tran_desc,     --Added for transaction detail report on 210812
             NVL(ctm_redemption_delay_flag,'N')
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type, v_prfl_flag,    -- prifile code added for LIMITS BRD
             v_trans_desc,      --Added for transaction detail report on 210812
             v_txn_redmption_flag
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_instcode;
     
   
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '12';                         --Ineligible Transaction
         v_errmsg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';                         --Ineligible Transaction
         v_respcode := 'Error while selecting transaction details';
         RAISE exp_main_reject_record;
   END;

   --En find debit and credit flag
   
   --Start generating transaction description for regarding JH-8
   BEGIN
       select  VRM_REASON_DESC
           into V_TRANS_DESC
           from vms_reason_mast
          where VRM_REASON_CODE=upper(p_reason_code)
           AND VRM_REASON_TYPE is null;

    EXCEPTION
    WHEN NO_DATA_FOUND
      THEN
           BEGIN
                   select  VRM_REASON_DESC
                   into V_TRANS_DESC
                   from vms_reason_mast
                  where VRM_REASON_CODE=upper(substr(p_reason_code,1,1))
                   AND VRM_REASON_TYPE is null;

           EXCEPTION
           WHEN NO_DATA_FOUND THEN

               V_TRANS_DESC := V_TRANS_DESC;

           WHEN OTHERS THEN
                 v_respcode := '21';
                v_errmsg := 'Error while transaction description '  || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_main_reject_record;

           END;

   WHEN exp_main_reject_record THEN
        RAISE;

      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Problem on generating transaction description  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
    --End generating transaction description for regarding JH-8
	
      BEGIN
        SELECT REPLACE(V_TRANS_DESC,'<<AMNT>>',p_amount)
        INTO V_TRANS_DESC FROM dual;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
          V_TRANS_DESC := V_TRANS_DESC;
         WHEN OTHERS
             THEN
             v_respcode := '21';
              v_errmsg := 'Error while transaction description '  || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
      END;
	  
   --Sn Transaction Date Check
   BEGIN
      v_tran_date := TO_DATE (SUBSTR (TRIM (p_trandate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '45';                       -- Server Declined -220509
         v_errmsg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Transaction Date Check

   --Sn Transaction Time Check
   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_trandate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_trantime), 1, 10),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '32';                       -- Server Declined -220509
         v_errmsg :=
               'Problem while converting transaction Time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Transaction Time Check
   
   v_business_time := TO_CHAR (v_tran_date, 'HH24:MI');

   IF v_business_time > v_cutoff_time
   THEN
      v_business_date := TRUNC (v_tran_date) + 1;
   ELSE
      v_business_date := TRUNC (v_tran_date);
   END IF;

  --Sn select Pan detail
   BEGIN
     -- Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD  
		SELECT pan.cap_card_stat,
		  pan.cap_prod_catg,
		  pan.cap_cafgen_flag,
		  pan.cap_appl_code,
		  pan.cap_firsttime_topup,
		  pan.cap_mbr_numb,
		  pan.cap_cust_code,
		  pan.cap_proxy_number,
		  pan.cap_acct_no,
		  pan.cap_prfl_code,
		  pan.cap_appl_code, --Added by Besky on 12-nov-12
		  pan.cap_prod_code,
		  pan.cap_prfl_levl,
		  pan.cap_card_type,
		  pan.cap_inst_code,
		  pan.cap_cust_code,
		  pan.cap_active_date,
		  cust.ccm_cust_id --Added for FSS-3626 Implementation for MMPOS
		INTO v_cap_card_stat,
		  v_cap_prod_catg,
		  v_cap_cafgen_flag,
		  v_appl_code,
		  v_firsttime_topup,
		  v_mbrnumb,
		  v_cust_code,
		  v_proxunumber,
		  v_acct_number,
		  v_lmtprfl,
		  v_cap_appl_code, -- Added by Besky on 12-nov-12
		  v_prod_code,     -- Added on 20Dec2012 for FSS-847
		  v_profile_level,
		  v_card_type,     -- Added on 20Dec2012 for FSS-847
		  v_inst_code,     -- Added on 20Dec2012 for FSS-847
		  v_cap_cust_code,
		  v_cardactive_dt,
		  v_cust_id        -- Added for FSS-3626 Implementation for MMPOS
		FROM cms_appl_pan pan,
		  cms_cust_mast cust
		WHERE pan.cap_inst_code = p_instcode
		AND pan.cap_inst_code   = cust.ccm_inst_code
		AND pan.cap_cust_code   = cust.ccm_cust_code --Added for FSS-3626 Implementation for MMPOS
		AND pan.cap_pan_code    = v_hash_pan
		AND pan.cap_mbr_numb    = p_mbr_numb;
   
        p_dda_number := v_acct_number;  --added newly on 23-Jan-2013 defect 9968
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Invalid Card number ' || p_acctno;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while selecting card number ' || p_acctno;
         RAISE exp_main_reject_record;
   END;

   --En select Pan detail
   
   -- Sn Moved down for FWR-70
   BEGIN
      SELECT cdm_channel_code
        INTO v_delchannel_code
        FROM cms_delchannel_mast
       WHERE cdm_channel_desc = 'MMPOS' AND cdm_inst_code = p_instcode;

      IF v_delchannel_code = p_delivery_channel
      THEN
         BEGIN
      vmsfunutilities.get_currency_code(v_prod_code,v_card_type,p_instcode,v_base_curr,v_errmsg);
      if v_errmsg<>'OK' then
           raise exp_main_reject_record;
      end if;
            IF TRIM (v_base_curr) IS NULL
            THEN
               v_respcode := '21';
               v_errmsg := 'Base currency cannot be null ';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            when exp_main_reject_record then
                raise;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'Error while selecting bese currecy  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         v_currcode := v_base_curr;
      ELSE
         v_currcode := p_currcode;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting the Delivery Channel of MMPOS  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   -- En Moved down for FWR-70
   
   -- added for jH-3020 on 20-08-2014 

     BEGIN

		SELECT CPC_DUP_SSNCHK,
		  CPC_DUP_TIMEPERIOD,
		  cpC_dup_timeunt,
		  cpc_encrypt_enable
		INTO v_dup_ssnchk,
		  v_dup_timeperiod,
		  v_dup_timeunt,
		  V_ENCRYPT_ENABLE
		FROM CMS_PROD_CATTYPE
		WHERE CPC_PROD_CODE=v_prod_code
		AND CPC_CARD_TYPE  = v_card_type
		AND CPC_INST_CODE  =p_instcode;

    EXCEPTION   WHEN OTHERS  THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting product detls ' || v_prod_code;
         RAISE exp_main_reject_record;

    END;
 
    IF v_dup_ssnchk ='Y' THEN

      --St Added for mantis id :15743

         BEGIN

			select cap_active_date
			into v_active_date  from (
			select pan.cap_active_date from cms_appl_pan pan ,cms_cust_mast cust
			where (cust.ccm_ssn_encr=fn_emaps_main(p_ssn) or cust.ccm_ssn=p_ssn)
			and pan.cap_cust_code=cust.ccm_cust_code
			and pan.cap_inst_code=cust.CCM_INST_CODE
			and cust.ccm_inst_code=p_instcode
			and pan.cap_card_stat not in ('9','13')
			and cap_active_date is not null
			and pan.CAP_STARTERCARD_FLAG='Y'
			order by CAP_ACTIVE_DATE desc) where rownum=1;

        EXCEPTION

        WHEN NO_DATA_FOUND THEN

        v_new_registrition :='Y';

        WHEN OTHERS
          THEN
              v_respcode := '21';
              v_errmsg := 'Error while selecting  activation  detls for last card of ssn ';
             RAISE exp_main_reject_record;

        END;


       --Sn Denomination Check
        BEGIN
            BEGIN
              SELECT CPC_RELOADABLE_FLAG,CPC_PROD_DENOM, CPC_PDENOM_MIN, CPC_PDENOM_MAX,
              CPC_PDENOM_FIX,CPC_PROFILE_CODE
              INTO v_varprodflag,v_cpc_prod_deno, v_cpc_pden_min, v_cpc_pden_max,
              v_cpc_pden_fix,v_profile_code
              FROM cms_prod_cattype
              WHERE cpc_prod_code = v_prod_code
              AND cpc_card_type = V_CARD_TYPE
              AND cpc_inst_code = p_instcode;
            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
              v_respcode := '12';
              v_errmsg :=
              'No data for this Product code and category type'
              || v_prod_code;
            RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
              v_respcode := '12';
              v_errmsg :=
              'Error while selecting data from CMS_PROD_CATTYPE for Product code'
              || v_prod_code
              || SQLERRM;
            RAISE exp_main_reject_record;
            END;

            IF v_cpc_prod_deno = 1
            THEN
              IF p_amount NOT BETWEEN v_cpc_pden_min AND v_cpc_pden_max
              THEN
              v_respcode := '43';
              v_errmsg := 'Invalid Amount';
              RAISE exp_main_reject_record;
            END IF;
            ELSIF v_cpc_prod_deno = 2
            THEN
              IF p_amount <> v_cpc_pden_fix
              THEN
                v_respcode := '43';
                v_errmsg := 'Invalid Amount';
                RAISE exp_main_reject_record;
              END IF;
            ELSIF v_cpc_prod_deno = 3
            THEN
              SELECT COUNT (*)
              INTO v_count
              FROM VMS_PRODCAT_DENO_MAST
              WHERE VPD_INST_CODE = p_instcode
              AND VPD_PROD_CODE = v_prod_code
              AND VPD_CARD_TYPE = V_CARD_TYPE
              AND VPD_PDEN_VAL = p_amount;

              IF v_count = 0
              THEN
                v_respcode := '43';
                v_errmsg := 'Invalid Amount';
                RAISE exp_main_reject_record;
              END IF;
          END IF;

        EXCEPTION
        WHEN exp_main_reject_record
        THEN
          RAISE;
        WHEN NO_DATA_FOUND
        THEN
          v_respcode := '21';
          V_ERRMSG :=
          'Card type (fixed/variable ) is not defined for the card '
          || v_acct_number;
        RAISE exp_main_reject_record;
        WHEN OTHERS
        THEN
          V_RESPCODE := '21';
          v_errmsg := 'Error while selecting topup flag ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
        END;

         --En  Denomination Check

        -- en Added for mantis id :15743

     IF  v_new_registrition <> 'Y' then

          if v_dup_timeunt ='D'  then  -- Days

          BEGIN

                  SELECT ROUND(SYSDATE-V_ACTIVE_DATE,2)
                       into V_DAYS_DIFF
                       from dual;

                EXCEPTION
                      WHEN OTHERS THEN

                  v_respcode := '21';
                  v_errmsg :='Error while getting day diff'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;

                END;


                if v_days_diff <= v_dup_timeperiod then

                  v_respcode := '232';
                  v_errmsg := 'Cardholder has a recent existing account';
                  RAISE exp_main_reject_record;

                end if;

          elsif v_dup_timeunt='W' then   -- Weeks


              BEGIN

                  SELECT CEIL ((TRUNC (SYSDATE) - TRUNC (V_ACTIVE_DATE)) / 7)
                      INTO V_WEEKS_DIFF
                      FROM DUAL;

              EXCEPTION
                 WHEN OTHERS THEN
                  v_respcode := '21';
                  v_errmsg :='Error while getting weekly diff'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;
              END;


              if v_weeks_diff <= v_dup_timeperiod then

                 v_respcode := '232';
                 v_errmsg := 'Cardholder has a recent existing account';
                 RAISE exp_main_reject_record;

              end if;


          elsif v_dup_timeunt='M' then  -- Months

               BEGIN

               SELECT ceil (MONTHS_BETWEEN
                    (TO_DATE(to_char(sysdate,'MM-DD-YYYY'),'MM-DD-YYYY'),
                    TO_DATE(to_char(v_active_date,'MM-DD-YYYY'),'MM-DD-YYYY') ) )
                    INTO V_MONTHS_DIFF
                    FROM DUAL;

              EXCEPTION
                   WHEN OTHERS THEN

                  v_respcode := '21';
                  v_errmsg :='Error while getting monthly diff'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;

              END;


              IF V_MONTHS_DIFF <= V_DUP_TIMEPERIOD THEN

               v_respcode := '232';
               v_errmsg := 'Cardholder has a recent existing account';
               RAISE exp_main_reject_record;


              END IF;


          elsif v_dup_timeunt='Y' then  -- Years


              BEGIN

              SELECT floor (MONTHS_BETWEEN
                   (TO_DATE(to_char(sysdate,'MM-DD-YYYY'),'MM-DD-YYYY'),
                    TO_DATE(to_char(v_active_date,'MM-DD-YYYY'),'MM-DD-YYYY') )/12)
                    INTO V_YEARS_DIFF
                    FROM DUAL;

               EXCEPTION WHEN OTHERS THEN

                  v_respcode := '21';
                  v_errmsg :='Error while getting yearly diff'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_main_reject_record;


              END;

              IF V_YEARS_DIFF <= V_DUP_TIMEPERIOD THEN

                   v_respcode := '232';
                   v_errmsg := 'Cardholder has a recent existing account';
                   RAISE exp_main_reject_record;

              END IF;


          end if;
      end if;


    END IF;

    --Added for JH-8(Additional Changes) on 24-Oct-13
    Begin
		SELECT Cpc_Loccheck_Flag,
		  CPC_INVCHECK_FLAG,                 --Added for fss-1785
		  NVL(cpc_redemption_delay_flag,'N'),--Added for FSS-4647
		  cpc_min_age_kyc
		INTO V_Loccheck_Flg,
		  v_actv_flag,                      --Added for fss-1785
		  v_redmption_delay_flag,
		  v_min_age_kyc                     --Added for FSS-4647
		FROM Cms_Prod_Cattype
		WHERE Cpc_Prod_Code = V_Prod_Code
		AND Cpc_Card_Type   = V_Card_Type
		AND Cpc_Inst_Code   = P_Instcode ;

      Exception
        When No_Data_Found Then
          V_ERRMSG   := 'Error while Fetching Location Check From ProdCattype - No Data found' ;
          V_Respcode := '21';
        Raise Exp_Main_Reject_Record;
        When Others Then
          V_ERRMSG   := 'Error while Fetching Location Check From ProdCattype ' ||
                  SUBSTR(SQLERRM, 1, 200);
          V_Respcode := '21';
        Raise Exp_Main_Reject_Record;
  End;
  --End for JH-8(Additional Changes)

   BEGIN                               --SN Added for DFCHOST-311
    if V_Loccheck_Flg = 'Y' Then       --Added for JH-8(Additional Changes)
      SELECT COUNT (*)
        INTO v_store_count
        FROM cms_caf_info_entry
       WHERE cci_appl_code  = v_appl_code
         AND cci_store_id = p_terminalid;

      IF v_store_count = 0
      THEN
         v_respcode := '40';             -- response for invalid transaction
         v_errmsg := 'STORE ID MISMATCH';
         RAISE exp_main_reject_record;
      END IF;
    End if;                              -- Added for JH-8(Additional Changes)
   EXCEPTION
   WHEN OTHERS THEN
	  v_respcode := '21';                -- response for invalid transaction
	  v_errmsg := 'Error while Fetching store count' || SUBSTR(SQLERRM, 1, 200);
	  RAISE exp_main_reject_record;   
   END;                                  --EN Added for DFCHOST-311


  --St Added by Ramesh.A on 02/07/2012
   BEGIN
      SELECT cfp_plan_desc
        INTO v_fee_plan_desc
        FROM cms_fee_plan
       WHERE cfp_plan_id = p_fee_plan_id AND cfp_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '131';
         v_errmsg := 'INVALID FEE PLAN ID ' || '--' || p_fee_plan_id;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
             'Error while selecting FEE PLAN ID ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --End Added by Ramesh.A on 02/07/2012

   --St Added by Ramesh.A on 26/04/2013 for DFCCSD-59
   BEGIN
       SELECT COUNT(*) INTO v_feeplan_count
        FROM CMS_FEEPLAN_PROD_MAPG
       Where Cfm_Plan_Id = P_Fee_Plan_Id And Cfm_Prod_Code=V_Prod_Code And Cfm_Inst_Code = P_Instcode;
       IF v_feeplan_count = 0 THEN
         v_respcode := '166';
         v_errmsg := 'Fee Plan ID not linked to Product' || '--' || p_fee_plan_id|| '--' || v_prod_code;
         RAISE exp_main_reject_record;
       END IF;
   EXCEPTION
      WHEN exp_main_reject_record THEN
        RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
             'Error while selecting FEE PLAN ID ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --End Added by Ramesh.A on 26/04/2013 for DFCCSD-59

   --Sn Added by Pankaj S. on 15-Feb-2013 for Damage replacement changes(FSS-391)
   BEGIN
      SELECT chr_pan_code
        INTO v_oldcrd
        FROM cms_htlst_reisu
       WHERE chr_inst_code = p_instcode
         AND chr_new_pan = v_hash_pan
         AND chr_reisu_cause = 'R'
         AND chr_pan_code IS NOT NULL;

      BEGIN
         SELECT COUNT (1)
           INTO v_dup_check
           FROM cms_appl_pan
          WHERE cap_inst_code = p_instcode
            AND cap_acct_no = v_acct_number
             AND cap_card_stat IN ('0', '1', '2', '5', '6', '8', '12');

         IF v_dup_check <> 1
         THEN
            v_errmsg := 'Card is not allowed for activation';
            v_respcode := '89';         --need to configure new response code
            RAISE exp_main_reject_record;
         END IF;
	  EXCEPTION
	  WHEN OTHERS THEN
	    v_respcode := '21';  
		v_errmsg := 'Error while seloecting count of cards for activation'|| SUBSTR (SQLERRM, 1, 200);
		RAISE exp_main_reject_record;	  
      END;

      BEGIN
         UPDATE cms_appl_pan
            SET cap_card_stat = '9'
          WHERE cap_inst_code = p_instcode AND cap_pan_code = v_oldcrd;

         IF SQL%ROWCOUNT <> 1
         THEN
            v_errmsg := 'Problem in updation of status for old damage card';
            v_respcode := '89';         --need to configure new response code
            RAISE exp_main_reject_record;
         END IF;
      END;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting damage card details '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main_reject_record;
   END;

   --En Added by Pankaj S. on 15-Feb-2013 for Damage replacement changes(FSS-391)

   --Sn Check initial load
   IF v_firsttime_topup = 'Y' AND v_cap_card_stat = '1'
   THEN
      v_respcode := '27';                 -- response for invalid transaction
      v_errmsg := 'Card Activation With Profile Already Done';
      RAISE exp_main_reject_record;
   END IF;
      IF TRIM (v_firsttime_topup) IS NULL
      THEN
         v_errmsg := 'Invalid Card Activation With Profile Parameter';
         RAISE exp_main_reject_record;
      END IF;


   BEGIN
      IF (TO_NUMBER (p_amount) >= 0)
      THEN
         v_tran_amt := p_amount;

         BEGIN
            sp_convert_curr (p_instcode,
                             v_currcode,
                             p_acctno,
                             p_amount,
                             v_tran_date,
                             v_tran_amt,
                             v_card_curr,
                             v_errmsg,
                             v_prod_code,
                             v_card_type
                            );

            IF v_errmsg <> 'OK'
            THEN
               v_respcode := '21';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_respcode := '21';                 -- Server Declined -220509
               v_errmsg :=
                     'Error from currency conversion '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      ELSE
         -- If transaction Amount is zero - Invalid Amount -220509
         v_respcode := '43';
         v_errmsg := 'INVALID AMOUNT';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN INVALID_NUMBER
      THEN
         v_respcode := '43';
         v_errmsg := 'INVALID AMOUNT';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'Error in Convert Currency ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;


   IF v_cardactive_dt IS NOT NULL
   THEN
      v_respcode := '27';
      v_errmsg := 'Card Activation Already Done For This Card ';
      RAISE exp_main_reject_record;
   END IF;

   --St Updates the fee plan id to card
   BEGIN
      SELECT cce_fee_plan
        INTO v_fee_plan_id
        FROM cms_card_excpfee
       WHERE cce_inst_code = p_instcode
         AND cce_pan_code = v_hash_pan
         AND (( cce_valid_to IS NOT NULL
                 AND (v_tran_date BETWEEN cce_valid_from AND cce_valid_to)
                 )           --Added by Ramesh.A on 11/10/2012 for defect 9332
              OR (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from)
             );

      UPDATE cms_card_excpfee
         SET cce_fee_plan = p_fee_plan_id,
             cce_lupd_user = 1,
             cce_lupd_date = SYSDATE
       WHERE cce_inst_code = p_instcode
         AND cce_pan_code = v_hash_pan
         AND (   (    cce_valid_to IS NOT NULL
                  AND (v_tran_date BETWEEN cce_valid_from AND cce_valid_to)
                 )           --Added by Ramesh.A on 11/10/2012 for defect 9332
              OR (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from)
             );

      IF SQL%ROWCOUNT = 0
      THEN
         v_errmsg := 'updating FEE PLAN ID IS NOT HAPPENED';
         v_respcode := '21';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE exp_main_reject_record;
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT cpf_fee_plan, cpf_flow_source, cpf_crgl_catg,
                   cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no,
                   cpf_drgl_catg, cpf_drgl_code, cpf_drsubgl_code,
                   cpf_dracct_no, cpf_valid_from, cpf_valid_to,
                   cpf_st_crgl_catg, cpf_st_crgl_code, cpf_st_crsubgl_code,
                   cpf_st_cracct_no, cpf_st_drgl_catg, cpf_st_drgl_code,
                   cpf_st_drsubgl_code, cpf_st_dracct_no,
                   cpf_cess_crgl_catg, cpf_cess_crgl_code,
                   cpf_cess_crsubgl_code, cpf_cess_cracct_no,
                   cpf_cess_drgl_catg, cpf_cess_drgl_code,
                   cpf_cess_drsubgl_code, cpf_cess_dracct_no,
                   cpf_st_calc_flag, cpf_cess_calc_flag
              INTO v_fee_plan_id, v_flow_source, v_crgl_catg,
                   v_crgl_code, v_crsubgl_code, v_cracct_no,
                   v_drgl_catg, v_drgl_code, v_drsubgl_code,
                   v_dracct_no, v_valid_from, v_valid_to,
                   v_st_crgl_catg, v_st_crgl_code, v_st_crsubgl_code,
                   v_st_cracct_no, v_st_drgl_catg, v_st_drgl_code,
                   v_st_drsubgl_code, v_st_dracct_no,
                   v_cess_crgl_catg, v_cess_crgl_code,
                   v_cess_crsubgl_code, v_cess_cracct_no,
                   v_cess_drgl_catg, v_cess_drgl_code,
                   v_cess_drsubgl_code, v_cess_dracct_no,
                   v_st_calc_flag, v_cess_calc_flag
              FROM cms_prodcattype_fees
             WHERE cpf_inst_code = p_instcode
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
                         cce_fee_plan, cce_flow_source, cce_crgl_catg,
                         cce_crgl_code, cce_crsubgl_code, cce_cracct_no,
                         cce_drgl_catg, cce_drgl_code, cce_drsubgl_code,
                         cce_dracct_no, cce_valid_from, cce_valid_to,
                         cce_st_crgl_catg, cce_st_crgl_code,
                         cce_st_crsubgl_code, cce_st_cracct_no,
                         cce_st_drgl_catg, cce_st_drgl_code,
                         cce_st_drsubgl_code, cce_st_dracct_no,
                         cce_cess_crgl_catg, cce_cess_crgl_code,
                         cce_cess_crsubgl_code, cce_cess_cracct_no,
                         cce_cess_drgl_catg, cce_cess_drgl_code,
                         cce_cess_drsubgl_code, cce_cess_dracct_no,
                         cce_st_calc_flag, cce_cess_calc_flag,
                         cce_pan_code_encr
                        )
                 VALUES (p_instcode, v_hash_pan, SYSDATE,
                         p_lupduser, p_lupduser, SYSDATE,
                         p_fee_plan_id,    --Updated by Ramesh.A on 30/07/2012
                         v_flow_source, v_crgl_catg,
                         v_crgl_code, v_crsubgl_code, v_cracct_no,
                         v_drgl_catg, v_drgl_code, v_drsubgl_code,
                         v_dracct_no, v_valid_from, v_valid_to,
                         v_st_crgl_catg, v_st_crgl_code,
                         v_st_crsubgl_code, v_st_cracct_no,
                         v_st_drgl_catg, v_st_drgl_code,
                         v_st_drsubgl_code, v_st_dracct_no,
                         v_cess_crgl_catg, v_cess_crgl_code,
                         v_cess_crsubgl_code, v_cess_cracct_no,
                         v_cess_drgl_catg, v_cess_drgl_code,
                         v_cess_drsubgl_code, v_cess_dracct_no,
                         v_st_calc_flag, v_cess_calc_flag,
                         v_encr_pan
                        );

            SELECT cce_cardfee_id
              INTO v_cardfee_id
              FROM cms_card_excpfee
             WHERE cce_pan_code = v_hash_pan
               AND cce_inst_code = p_instcode
               AND (   (    cce_valid_to IS NOT NULL
                        AND (v_tran_date BETWEEN cce_valid_from AND cce_valid_to
                            )
                       )          -- Condition added on 23Jan2013 Defect 10063
                    OR (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from)
                   );             -- Condition added on 23Jan2013 Defect 10063

            -- FOR HISTORY TABLE
            INSERT INTO cms_card_excpfee_hist
                        (cce_inst_code, cce_pan_code, cce_ins_date,
                         cce_ins_user, cce_lupd_user, cce_lupd_date,
                         cce_fee_plan, cce_flow_source, cce_crgl_catg,
                         cce_crgl_code, cce_crsubgl_code, cce_cracct_no,
                         cce_drgl_catg, cce_drgl_code, cce_drsubgl_code,
                         cce_dracct_no, cce_valid_from, cce_valid_to,
                         cce_st_crgl_catg, cce_st_crgl_code,
                         cce_st_crsubgl_code, cce_st_cracct_no,
                         cce_st_drgl_catg, cce_st_drgl_code,
                         cce_st_drsubgl_code, cce_st_dracct_no,
                         cce_cess_crgl_catg, cce_cess_crgl_code,
                         cce_cess_crsubgl_code, cce_cess_cracct_no,
                         cce_cess_drgl_catg, cce_cess_drgl_code,
                         cce_cess_drsubgl_code, cce_cess_dracct_no,
                         cce_st_calc_flag, cce_cess_calc_flag,
                         cce_pan_code_encr, cce_cardfee_id, cce_mbr_numb
                        )                    --Added by Ramesh.A on 31/07/2012
                 VALUES (p_instcode, v_hash_pan, SYSDATE,
                         p_lupduser, p_lupduser, SYSDATE,
                         v_fee_plan_id, v_flow_source, v_crgl_catg,
                         v_crgl_code, v_crsubgl_code, v_cracct_no,
                         v_drgl_catg, v_drgl_code, v_drsubgl_code,
                         v_dracct_no, v_valid_from, v_valid_to,
                         v_st_crgl_catg, v_st_crgl_code,
                         v_st_crsubgl_code, v_st_cracct_no,
                         v_st_drgl_catg, v_st_drgl_code,
                         v_st_drsubgl_code, v_st_dracct_no,
                         v_cess_crgl_catg, v_cess_crgl_code,
                         v_cess_crsubgl_code, v_cess_cracct_no,
                         v_cess_drgl_catg, v_cess_drgl_code,
                         v_cess_drsubgl_code, v_cess_dracct_no,
                         v_st_calc_flag, v_cess_calc_flag,
                         v_encr_pan, v_cardfee_id, '000'
                        );                   --Added by Ramesh.A on 31/07/2012

            -- END HISTORY TABLE
            IF SQL%ROWCOUNT = 0
            THEN
               v_errmsg := 'inserting FEE PLAN ID IS NOT HAPPENED';
               v_respcode := '21';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE exp_main_reject_record;
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT cpf_fee_plan, cpf_flow_source, cpf_crgl_catg,
                         cpf_crgl_code, cpf_crsubgl_code, cpf_cracct_no,
                         cpf_drgl_catg, cpf_drgl_code, cpf_drsubgl_code,
                         cpf_dracct_no, cpf_valid_from, cpf_valid_to,
                         cpf_st_crgl_catg, cpf_st_crgl_code,
                         cpf_st_crsubgl_code, cpf_st_cracct_no,
                         cpf_st_drgl_catg, cpf_st_drgl_code,
                         cpf_st_drsubgl_code, cpf_st_dracct_no,
                         cpf_cess_crgl_catg, cpf_cess_crgl_code,
                         cpf_cess_crsubgl_code, cpf_cess_cracct_no,
                         cpf_cess_drgl_catg, cpf_cess_drgl_code,
                         cpf_cess_drsubgl_code, cpf_cess_dracct_no,
                         cpf_st_calc_flag, cpf_cess_calc_flag
                    INTO v_fee_plan_id, v_flow_source, v_crgl_catg,
                         v_crgl_code, v_crsubgl_code, v_cracct_no,
                         v_drgl_catg, v_drgl_code, v_drsubgl_code,
                         v_dracct_no, v_valid_from, v_valid_to,
                         v_st_crgl_catg, v_st_crgl_code,
                         v_st_crsubgl_code, v_st_cracct_no,
                         v_st_drgl_catg, v_st_drgl_code,
                         v_st_drsubgl_code, v_st_dracct_no,
                         v_cess_crgl_catg, v_cess_crgl_code,
                         v_cess_crsubgl_code, v_cess_cracct_no,
                         v_cess_drgl_catg, v_cess_drgl_code,
                         v_cess_drsubgl_code, v_cess_dracct_no,
                         v_st_calc_flag, v_cess_calc_flag
                    FROM cms_prod_fees
                   WHERE cpf_inst_code = p_instcode
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
                               cce_fee_plan, cce_flow_source, cce_crgl_catg,
                               cce_crgl_code, cce_crsubgl_code,
                               cce_cracct_no, cce_drgl_catg, cce_drgl_code,
                               cce_drsubgl_code, cce_dracct_no,
                               cce_valid_from, cce_valid_to,
                               cce_st_crgl_catg, cce_st_crgl_code,
                               cce_st_crsubgl_code, cce_st_cracct_no,
                               cce_st_drgl_catg, cce_st_drgl_code,
                               cce_st_drsubgl_code, cce_st_dracct_no,
                               cce_cess_crgl_catg, cce_cess_crgl_code,
                               cce_cess_crsubgl_code, cce_cess_cracct_no,
                               cce_cess_drgl_catg, cce_cess_drgl_code,
                               cce_cess_drsubgl_code, cce_cess_dracct_no,
                               cce_st_calc_flag, cce_cess_calc_flag,
                               cce_pan_code_encr
                              )
                       VALUES (p_instcode, v_hash_pan, SYSDATE,
                               p_lupduser, p_lupduser, SYSDATE,
                               p_fee_plan_id,
                               --Updated by Ramesh.A on 30/07/2012
                               v_flow_source, v_crgl_catg,
                               v_crgl_code, v_crsubgl_code,
                               v_cracct_no, v_drgl_catg, v_drgl_code,
                               v_drsubgl_code, v_dracct_no,
                               v_valid_from, v_valid_to,
                               v_st_crgl_catg, v_st_crgl_code,
                               v_st_crsubgl_code, v_st_cracct_no,
                               v_st_drgl_catg, v_st_drgl_code,
                               v_st_drsubgl_code, v_st_dracct_no,
                               v_cess_crgl_catg, v_cess_crgl_code,
                               v_cess_crsubgl_code, v_cess_cracct_no,
                               v_cess_drgl_catg, v_cess_drgl_code,
                               v_cess_drsubgl_code, v_cess_dracct_no,
                               v_st_calc_flag, v_cess_calc_flag,
                               v_encr_pan
                              );

                  SELECT cce_cardfee_id
                    INTO v_cardfee_id
                    FROM cms_card_excpfee
                   WHERE cce_pan_code = v_hash_pan
                     AND cce_inst_code = p_instcode
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
                               cce_crgl_catg, cce_crgl_code,
                               cce_crsubgl_code, cce_cracct_no,
                               cce_drgl_catg, cce_drgl_code,
                               cce_drsubgl_code, cce_dracct_no,
                               cce_valid_from, cce_valid_to,
                               cce_st_crgl_catg, cce_st_crgl_code,
                               cce_st_crsubgl_code, cce_st_cracct_no,
                               cce_st_drgl_catg, cce_st_drgl_code,
                               cce_st_drsubgl_code, cce_st_dracct_no,
                               cce_cess_crgl_catg, cce_cess_crgl_code,
                               cce_cess_crsubgl_code, cce_cess_cracct_no,
                               cce_cess_drgl_catg, cce_cess_drgl_code,
                               cce_cess_drsubgl_code, cce_cess_dracct_no,
                               cce_st_calc_flag, cce_cess_calc_flag,
                               cce_pan_code_encr, cce_cardfee_id
                              )
                       VALUES (p_instcode, v_hash_pan, SYSDATE,
                               '000', p_lupduser, p_lupduser,
                               SYSDATE, v_fee_plan_id, v_flow_source,
                               v_crgl_catg, v_crgl_code,
                               v_crsubgl_code, v_cracct_no,
                               v_drgl_catg, v_drgl_code,
                               v_drsubgl_code, v_dracct_no,
                               v_valid_from, v_valid_to,
                               v_st_crgl_catg, v_st_crgl_code,
                               v_st_crsubgl_code, v_st_cracct_no,
                               v_st_drgl_catg, v_st_drgl_code,
                               v_st_drsubgl_code, v_st_dracct_no,
                               v_cess_crgl_catg, v_cess_crgl_code,
                               v_cess_crsubgl_code, v_cess_cracct_no,
                               v_cess_drgl_catg, v_cess_drgl_code,
                               v_cess_drsubgl_code, v_cess_dracct_no,
                               v_st_calc_flag, v_cess_calc_flag,
                               v_encr_pan, v_cardfee_id
                              );

                  -- END HISTORY TABLE
                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg := 'INSERTING FEE PLAN ID IS NOT HAPPENED';
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_main_reject_record
                  THEN
                     RAISE exp_main_reject_record;
                  WHEN NO_DATA_FOUND
                  THEN
                     BEGIN
                        SELECT cdm_flow_source, cdm_crgl_catg,
                               cdm_crgl_code, cdm_crsubgl_code,
                               cdm_cracct_no, cdm_drgl_catg, cdm_drgl_code,
                               cdm_drsubgl_code, cdm_dracct_no,
                               cdm_valid_from, cdm_valid_to,
                               cdm_st_crgl_catg, cdm_st_crgl_code,
                               cdm_st_crsubgl_code, cdm_st_cracct_no,
                               cdm_st_drgl_catg, cdm_st_drgl_code,
                               cdm_st_drsubgl_code, cdm_st_dracct_no,
                               cdm_cess_crgl_catg, cdm_cess_crgl_code,
                               cdm_cess_crsubgl_code, cdm_cess_cracct_no,
                               cdm_cess_drgl_catg, cdm_cess_drgl_code,
                               cdm_cess_drsubgl_code, cdm_cess_dracct_no,
                               cdm_st_calc_flag, cdm_cess_calc_flag
                          --Updated by Ramesh.A on 30/07/2012
                        INTO   v_flow_source, v_crgl_catg,
                               v_crgl_code, v_crsubgl_code,
                               v_cracct_no, v_drgl_catg, v_drgl_code,
                               v_drsubgl_code, v_dracct_no,
                               v_valid_from, v_valid_to,
                               v_st_crgl_catg, v_st_crgl_code,
                               v_st_crsubgl_code, v_st_cracct_no,
                               v_st_drgl_catg, v_st_drgl_code,
                               v_st_drsubgl_code, v_st_dracct_no,
                               v_cess_crgl_catg, v_cess_crgl_code,
                               v_cess_crsubgl_code, v_cess_cracct_no,
                               v_cess_drgl_catg, v_cess_drgl_code,
                               v_cess_drsubgl_code, v_cess_dracct_no,
                               v_st_calc_flag, v_cess_calc_flag
                          --Updated by Ramesh.A on 30/07/2012
                        FROM   cms_default_glacct_mast
                         WHERE cdm_inst_code = p_instcode;

                        INSERT INTO cms_card_excpfee
                                    (cce_inst_code, cce_pan_code,
                                     cce_ins_date, cce_ins_user,
                                     cce_lupd_user, cce_lupd_date,
                                     cce_fee_plan, cce_flow_source,
                                     cce_crgl_catg, cce_crgl_code,
                                     cce_crsubgl_code, cce_cracct_no,
                                     cce_drgl_catg, cce_drgl_code,
                                     cce_drsubgl_code, cce_dracct_no,
                                     cce_valid_from, cce_valid_to,
                                     cce_st_crgl_catg, cce_st_crgl_code,
                                     cce_st_crsubgl_code, cce_st_cracct_no,
                                     cce_st_drgl_catg, cce_st_drgl_code,
                                     cce_st_drsubgl_code, cce_st_dracct_no,
                                     cce_cess_crgl_catg, cce_cess_crgl_code,
                                     cce_cess_crsubgl_code,
                                     cce_cess_cracct_no, cce_cess_drgl_catg,
                                     cce_cess_drgl_code,
                                     cce_cess_drsubgl_code,
                                     cce_cess_dracct_no, cce_st_calc_flag,
                                     cce_cess_calc_flag, cce_pan_code_encr
                                    )
                             VALUES (p_instcode, v_hash_pan,
                                     SYSDATE, p_lupduser,
                                     p_lupduser, SYSDATE,
                                     p_fee_plan_id,
                                     --Updated by Ramesh.A on 30/07/2012
                                     v_flow_source,
                                     v_crgl_catg, v_crgl_code,
                                     v_crsubgl_code, v_cracct_no,
                                     v_drgl_catg, v_drgl_code,
                                     v_drsubgl_code, v_dracct_no,
                                     v_valid_from, v_valid_to,
                                     v_st_crgl_catg, v_st_crgl_code,
                                     v_st_crsubgl_code, v_st_cracct_no,
                                     v_st_drgl_catg, v_st_drgl_code,
                                     v_st_drsubgl_code, v_st_dracct_no,
                                     v_cess_crgl_catg, v_cess_crgl_code,
                                     v_cess_crsubgl_code,
                                     v_cess_cracct_no, v_cess_drgl_catg,
                                     v_cess_drgl_code,
                                     v_cess_drsubgl_code,
                                     v_cess_dracct_no, v_st_calc_flag,
                                     v_cess_calc_flag, v_encr_pan
                                    );

                        SELECT cce_cardfee_id
                          INTO v_cardfee_id
                          FROM cms_card_excpfee
                         WHERE cce_pan_code = v_hash_pan
                           AND cce_inst_code = p_instcode
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
                                     cce_flow_source, cce_crgl_catg,
                                     cce_crgl_code, cce_crsubgl_code,
                                     cce_cracct_no, cce_drgl_catg,
                                     cce_drgl_code, cce_drsubgl_code,
                                     cce_dracct_no, cce_valid_from,
                                     cce_valid_to, cce_st_crgl_catg,
                                     cce_st_crgl_code, cce_st_crsubgl_code,
                                     cce_st_cracct_no, cce_st_drgl_catg,
                                     cce_st_drgl_code, cce_st_drsubgl_code,
                                     cce_st_dracct_no, cce_cess_crgl_catg,
                                     cce_cess_crgl_code,
                                     cce_cess_crsubgl_code,
                                     cce_cess_cracct_no, cce_cess_drgl_catg,
                                     cce_cess_drgl_code,
                                     cce_cess_drsubgl_code,
                                     cce_cess_dracct_no, cce_st_calc_flag,
                                     cce_cess_calc_flag, cce_pan_code_encr,
                                     cce_cardfee_id
                                    )
                             VALUES (p_instcode, v_hash_pan,
                                     SYSDATE, '000',
                                     p_lupduser, p_lupduser,
                                     SYSDATE, p_fee_plan_id,
                                     --Updated by Ramesh.A on 30/07/2012
                                     v_flow_source, v_crgl_catg,
                                     v_crgl_code, v_crsubgl_code,
                                     v_cracct_no, v_drgl_catg,
                                     v_drgl_code, v_drsubgl_code,
                                     v_dracct_no, v_valid_from,
                                     v_valid_to, v_st_crgl_catg,
                                     v_st_crgl_code, v_st_crsubgl_code,
                                     v_st_cracct_no, v_st_drgl_catg,
                                     v_st_drgl_code, v_st_drsubgl_code,
                                     v_st_dracct_no, v_cess_crgl_catg,
                                     v_cess_crgl_code,
                                     v_cess_crsubgl_code,
                                     v_cess_cracct_no, v_cess_drgl_catg,
                                     v_cess_drgl_code,
                                     v_cess_drsubgl_code,
                                     v_cess_dracct_no, v_st_calc_flag,
                                     v_cess_calc_flag, v_encr_pan,
                                     v_cardfee_id
                                    );

                        -- END HISTORY TABLE
                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_errmsg :=
                              'inserting default FEE PLAN ID IS NOT HAPPENED';
                           v_respcode := '21';
                           RAISE exp_main_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_main_reject_record
                        THEN
                           RAISE exp_main_reject_record;
                        WHEN NO_DATA_FOUND
                        THEN
                           v_errmsg :=
                                  'NO DATA FOUND IN DEFAULT GL MAPPING TABLE';
                           v_respcode := '21';
                           RAISE exp_main_reject_record;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while selecting default entry in gl mapping '
                              || SUBSTR (SQLERRM, 1, 200);
                           v_respcode := '21';
                           RAISE exp_main_reject_record;
                     END;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting fee plan details product level '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
               END;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting fee plan details product card type level '
                  || SUBSTR (SQLERRM, 1, 200);
               v_respcode := '21';
               RAISE exp_main_reject_record;
         END;
      WHEN OTHERS
      THEN
         v_errmsg :=
              'Error while updating FEE PLAN ID ' || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   --En Updates the fee plan id to card
   IF v_cap_prod_catg = 'P'
   THEN
      --Sn call to authorize txn
      BEGIN
         sp_authorize_txn_cms_auth (p_instcode,
                                    p_msg_type,
                                    p_rrn,
                                    p_delivery_channel,
                                    p_termid_in,
                                    p_txn_code,
                                    p_txn_mode,
                                    p_trandate,
                                    p_trantime,
                                    p_acctno,
                                    NULL,
                                    p_amount,
                                    p_merchant_name,
                                    p_merchant_city,
                                    NULL,
                                    v_currcode,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    p_stan,                         -- P_stan
                                    p_mbr_numb,                     --Ins User
                                    p_rvsl_code,                    --INS Date
                                    v_tran_amt,
                                    v_inil_authid,
                                    v_respcode,
                                    v_respmsg,
                                    v_capture_date,
                                    'Y',
                                    'N',
                                    'N',
                                    p_funding_account,
                                    p_merchantZipCode--added for VMS-622 (redemption_delay zip code validation)
                                   );

         IF v_respcode <> '00' AND v_respmsg <> 'OK'
         THEN
            v_errmsg := v_respmsg;
            RAISE exp_auth_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN            --added by amit on 01-Aug-2012 for exception handling
            RAISE;
         WHEN exp_auth_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   --En call to authorize txn
   END IF;

   --Sn Added for FSS-3626 Implementation for MMPOS
     IF p_optin_list IS NOT NULL THEN
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
            v_optin_split:=substr(v_optin_list,instr(v_optin_list,':',1,1)+1);


          BEGIN
             IF v_optin_type IS NOT NULL AND v_optin_type = '1'
             THEN
                v_sms_optinflag := v_optin_split;
                 V_OPTIN_FLAG := 'Y';
             ELSIF v_optin_type IS NOT NULL AND v_optin_type = '2'
             THEN
                v_email_optinflag := v_optin_split;
                V_OPTIN_FLAG := 'Y';
             ELSIF v_optin_type IS NOT NULL AND v_optin_type = '3'
             THEN
                v_markmsg_optinflag := v_optin_split;
                V_OPTIN_FLAG := 'Y';
             ELSIF v_optin_type IS NOT NULL AND v_optin_type = '4'
             THEN
                v_gpresign_optinflag := v_optin_split;
                V_OPTIN_FLAG := 'Y';

              IF v_gpresign_optinflag='1' THEN  --Added for MVHOST-1249

                BEGIN

                SELECT CPC_TANDC_VERSION
                   INTO v_tandc_version
                   FROM CMS_PROD_CATTYPE
					WHERE CPC_PROD_CODE=v_prod_code
					AND CPC_CARD_TYPE= v_card_type
					AND CPC_INST_CODE=p_instcode;
                EXCEPTION
                WHEN others THEN

                  p_resp_code := '21';
                  v_errmsg :='Error from  featching the t and c version '|| SUBSTR (SQLERRM, 1, 200);
                RAISE exp_auth_reject_record;

                END;

                BEGIN

                        UPDATE cms_cust_mast
                        set ccm_tandc_version=v_tandc_version
                        WHERE ccm_inst_code=p_instcode
                          AND ccm_cust_code=V_CUST_CODE;

                        IF  SQL%ROWCOUNT =0 THEN
                           p_resp_code := '21';
                           v_errmsg :=
                                 'Error while updating t and c version '|| SUBSTR (SQLERRM, 1, 200);
                             RAISE exp_auth_reject_record;

                        END IF;


                EXCEPTION

                 WHEN exp_auth_reject_record THEN
                  RAISE ;
                 WHEN others THEN

                   p_resp_code := '21';
                   v_errmsg :='Error while updating t and c version '|| SUBSTR (SQLERRM, 1, 200);
                RAISE exp_auth_reject_record;
                END;

              END IF;


             ELSIF v_optin_type IS NOT NULL AND v_optin_type = '5'
               THEN
                v_savingsesign_optinflag := v_optin_split;
                V_OPTIN_FLAG := 'Y';
             END IF;
          END;

         IF V_OPTIN_FLAG = 'Y' THEN
              BEGIN
                 SELECT COUNT (*)
                   INTO v_count
                   FROM cms_optin_status
                  WHERE cos_inst_code = p_instcode AND cos_cust_id = v_cust_id;

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
                                  ),
                           COS_SAVINGSESIGN_OPTINFLAG =
                                    NVL (v_savingsesign_optinflag, COS_SAVINGSESIGN_OPTINFLAG),
                           COS_SAVINGSESIGN_OPTINTIME =
                              NVL (DECODE (v_savingsesign_optinflag,
                                           '1', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   COS_SAVINGSESIGN_OPTINTIME
                                  ),
                           COS_SAVINGSESIGN_OPTOUTTIME =
                              NVL (DECODE (v_savingsesign_optinflag,
                                           '0', SYSTIMESTAMP,
                                           NULL
                                          ),
                                   COS_SAVINGSESIGN_OPTOUTTIME
                                  )

                     WHERE cos_inst_code = p_instcode AND cos_cust_id = v_cust_id;
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
                                 cos_gpresign_optouttime,
                                 COS_SAVINGSESIGN_OPTINFLAG,
                                 COS_SAVINGSESIGN_OPTINTIME,
                                 COS_SAVINGSESIGN_OPTOUTTIME
                                )
                         VALUES (p_instcode, v_cust_id, v_sms_optinflag,
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
                                        ),
                                 v_savingsesign_optinflag,
                                 DECODE (v_savingsesign_optinflag,
                                         '1', SYSTIMESTAMP,
                                         NULL
                                        ),
                                 DECODE (v_savingsesign_optinflag,
                                         '0', SYSTIMESTAMP,
                                         NULL
                                        )
                                );
                 END IF;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    p_resp_code := '21';
                    v_errmsg  :='ERROR IN INSERTING RECORDS IN CMS_OPTIN_STATUS' || SUBSTR (SQLERRM, 1, 300);
                    RAISE exp_auth_reject_record;
              END;
         END IF;

         EXIT WHEN v_comma_pos=0;

		 END LOOP;
        END;

     END IF;
   --Added for FSS-3626 for 3.2 release
   IF P_OPTIN IS NULL THEN
    IF v_sms_optinflag = '1' AND v_email_optinflag = '1' THEN
      V_OPTIN := 3;
    ELSIF v_sms_optinflag = '0' AND v_email_optinflag = '1' THEN
      V_OPTIN := 2;
    ELSIF v_sms_optinflag = '1' AND v_email_optinflag = '0' THEN
      V_OPTIN := 1;
    ELSIF v_sms_optinflag = '0' AND v_email_optinflag = '0' THEN
      V_OPTIN := 0;
    END IF;
   ELSE
    V_OPTIN:=P_OPTIN;
   END IF;
   --En Added for FSS-3626 Implementation for MMPOS

   --Sn to attache profile code for card activation and del chnl='04'   --added by amit on 20-Jul-2012 for profile update
   IF p_delivery_channel = '04' AND p_txn_code = '68'
   -- Txn code 68 is used instead of 69 for DFC defect FSS-847
   THEN
      --Sn to attach profile to the card
      IF    v_lmtprfl IS NULL
         OR v_profile_level IS NULL                -- Added on 30102012 Dhiraj
      THEN
         BEGIN
            SELECT cpl_lmtprfl_id
              INTO v_lmtprfl
              FROM cms_prdcattype_lmtprfl
             WHERE cpl_inst_code = v_inst_code
               AND cpl_prod_code = v_prod_code
               AND cpl_card_type = v_card_type;

            v_profile_level := 2;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT cpl_lmtprfl_id
                    INTO v_lmtprfl
                    FROM cms_prod_lmtprfl
                   WHERE cpl_inst_code = v_inst_code
                     AND cpl_prod_code = v_prod_code;

                  v_profile_level := 3;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     NULL;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting Limit Profile At Product Level'
                        || SQLERRM;
                     RAISE exp_main_reject_record;
               END;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting Limit Profile At Product Catagory Level'
                  || SQLERRM;
               RAISE exp_main_reject_record;
         END;
      END IF;                                      -- Added on 30102012 Dhiraj

      --Sn Activate the card / update the flag in appl_pan
      BEGIN
         UPDATE cms_appl_pan
            SET
                cap_prfl_code = v_lmtprfl,
                cap_prfl_levl = v_profile_level,
                cap_merchant_name=P_Merchant_Name,
                cap_terminal_id=p_termid_in,cap_store_id=P_StoreID
          WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT = 0
         THEN
            v_errmsg :=
                  'Activating GPR card ACTIVE DATE NOT UPDATED' || v_hash_pan;
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                'Error while Activating GPR card' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      --En update the flag in appl_pan
   --En to attach profile to the card------
   END IF;

   --En to attache profile code for card activation and del chnl='04'--------------

   --En Check initial load


    --Start Generate HashKEY for MVCAN-77
       BEGIN
           V_FLDOB_HASHKEY_ID := GETHASH (UPPER(p_first_name)||UPPER(p_last_name)||p_dob);
       EXCEPTION
        WHEN OTHERS
        THEN
        v_respcode := '21';
        v_errmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_main_reject_record;
     END;
    --End Generate HashKEY for  MVCAN-77

   IF v_base_curr<>'124' THEN  --Condition Added for FSS-3925
   --Sn Added on 05_Feb_13 to call procedure for multiple SSN check
   BEGIN
      sp_check_ssn_threshold (p_instcode,
                              p_ssn,
                              v_prod_code,
                              v_card_type,
                              NULL,
                              v_ssn_crddtls,
                              v_respcode,
                              v_respmsg,
                              V_FLDOB_HASHKEY_ID --Added for MVCAN-77 of 3.1 release
                             );

      IF v_respmsg <> 'OK'
      THEN
         v_respcode := '146';
         v_errmsg := v_respmsg;
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   END IF;
   --En Added on 05_Feb_13 to call procedure for multiple SSN check


    BEGIN

        SELECT SUM(case when CAP_CARD_STAT = 0 THEN 1 ELSE 0 END  )  ,
               SUM (CASE WHEN CAP_FIRSTTIME_TOPUP = 'N' THEN 1 ELSE 0 END )
        INTO VALID_CARDSTAT_COUNT ,V_CARD_TOPUP_FLAG
             FROM CMS_APPL_PAN
        WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;

    EXCEPTION WHEN NO_DATA_FOUND
    THEN
         v_errmsg := 'Invalid Card number - activation ' || FN_MASK(p_acctno,'X',7,6);
         RAISE exp_main_reject_record;
    WHEN OTHERS
    THEN
         v_errmsg := 'Error while selecting card number during activation' || substr(sqlerrm,1,100);
         RAISE exp_main_reject_record;
    END;


    IF VALID_CARDSTAT_COUNT = 0 THEN
         V_RESPCODE := '10';
         V_ERRMSG   := 'CARD MUST BE IN INACTIVE STATUS FOR ACTIVATION';
         RAISE EXP_MAIN_REJECT_RECORD;
    ELSIF  V_CARD_TOPUP_FLAG = 0 THEN
         V_RESPCODE := '28';
         V_ERRMSG   := 'CARD FIRST TIME TOPUP MUST BE N STATUS FOR ACTIVATION';
         RAISE EXP_MAIN_REJECT_RECORD;
    END IF;

     BEGIN


        UPDATE cms_appl_pan
           SET cap_firsttime_topup = (case when V_CARD_TOPUP_FLAG >0 THEN 'Y' ELSE cap_firsttime_topup end),
               cap_card_stat = (case when VALID_CARDSTAT_COUNT >0 THEN '1'  ELSE cap_card_stat end),
               cap_active_date = (case when VALID_CARDSTAT_COUNT >0 THEN SYSDATE   ELSE cap_active_date end)
        WHERE cap_inst_code = p_instcode
        AND cap_pan_code =V_HASH_PAN;

            IF SQL%ROWCOUNT = 0
            THEN
               v_respcode := '09';
               v_errmsg :=
                     'CARD ACTIVATION DATE / FIRST TIME TOPUP UPDATION NOT HAPPENED'
                  || '--'
                  || p_acctno;
               RAISE exp_main_reject_record;
            END IF;

     EXCEPTION
        WHEN exp_main_reject_record
        THEN
           RAISE exp_main_reject_record;
        WHEN OTHERS
        THEN
           v_respcode := '09';
           v_errmsg :=
                 'ERROR IN CARD ACTIVATION DATE UPDATION'
              || '--'
              || p_acctno
              || '--'
              || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_main_reject_record;
     END;

--Added for DFCHOST-345
  IF V_ERRMSG = 'OK' THEN
    if V_Loccheck_Flg = 'Y' Then  --Added for JH-8(Additional Changes)
    BEGIN
     SELECT   CMM_MERPRODCAT_ID
       INTO
           V_CMM_MERPRODCAT_ID
       From Cms_Merinv_Merpan
      Where Cmm_Pan_Code = V_Hash_Pan And
            Cmm_Inst_Code = P_Instcode And
            CMM_LOCATION_ID = p_terminalid;
    EXCEPTION
     When No_Data_Found Then
       V_ERRMSG   := 'Error while Fetching ProdCatId From MERPAN - No Data found' ; -- Modified for DFCHOST 345(review)

       V_RESPCODE := '21';
       Raise Exp_Main_Reject_Record;
     When Others Then
       V_ERRMSG   := 'Error while Fetching ProdCatId From MERPAN ' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESPCODE := '21';
       Raise Exp_Main_Reject_Record;
    End;

     BEGIN
       UPDATE CMS_MERINV_MERPAN
         SET CMM_ACTIVATION_FLAG = 'C'
        WHERE CMM_PAN_CODE = V_HASH_PAN and
         Cmm_Inst_Code = P_Instcode And
         CMM_LOCATION_ID = p_terminalid;

       IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG   := 'Error while Updating Card Activation Flag in MERPAN ' ; --Modified for JH-8(Additional Changes) Modified for DFCHOST 345(review)
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
     EXCEPTION
      WHEN  EXP_MAIN_REJECT_RECORD THEN -- Modified for DFCHOST 345(review)
      RAISE EXP_MAIN_REJECT_RECORD;     -- Modified for DFCHOST 345(review)
       WHEN OTHERS THEN
        V_ERRMSG   := 'Error while Updating Card Activation Flag in MERPAN' ||    --Modified for JH-8(Additional Changes)
                    SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
     END;

  BEGIN
       UPDATE CMS_MERINV_STOCK
         SET CMS_CURR_STOCK = (CMS_CURR_STOCK - 1)
        WHERE CMS_INST_CODE = P_Instcode AND
            CMS_MERPRODCAT_ID = V_CMM_MERPRODCAT_ID AND
            CMS_LOCATION_ID = p_terminalid;

       IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG   := 'Error while Updating CurrStock in MerinvStock 1'; -- Modified for DFCHOST 345(review)

        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
     EXCEPTION
     WHEN  EXP_MAIN_REJECT_RECORD THEN -- Modified for DFCHOST 345(review)
      RAISE EXP_MAIN_REJECT_RECORD;    -- Modified for DFCHOST 345(review)
       When Others Then
        V_ERRMSG   := 'Error while Updating CurrStock in MerinvStock' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
  End;
--Added for JH-8(Additional Changes)

  Elsif v_actv_flag = 'Y' THEN--Added for FSS-1785

    BEGIN
     Select  Cmm_Mer_Id, Cmm_Location_Id, Cmm_Merprodcat_Id
       INTO V_CMM_MER_ID,
           V_CMM_LOCATION_ID,
           V_CMM_MERPRODCAT_ID
       From Cms_Merinv_Merpan
      Where Cmm_Pan_Code = V_Hash_Pan And
            Cmm_Inst_Code = P_instcode;
    EXCEPTION
     When No_Data_Found Then
       V_ERRMSG   := 'Error while Fetching Pan From MERPAN  - No Data found' ;
       V_RESPCODE := '21';
       Raise Exp_Main_Reject_Record;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while Fetching Pan From MERPAN ' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
    End;

    BEGIN
       UPDATE CMS_MERINV_MERPAN
         SET CMM_ACTIVATION_FLAG = 'C'
        Where Cmm_Pan_Code = V_Hash_Pan And
              Cmm_Inst_Code = P_instcode;
       IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG   := 'Error while Updating Card Activation Flag in MERPAN ' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
      EXCEPTION
       WHEN OTHERS THEN
        V_ERRMSG   := 'Error while Updating first time topup flag' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
     END;

     BEGIN
       UPDATE CMS_MERINV_STOCK
         Set Cms_Curr_Stock = (Cms_Curr_Stock - 1)
        WHERE CMS_INST_CODE = P_instcode AND
            CMS_MERPRODCAT_ID = V_CMM_MERPRODCAT_ID AND
            CMS_LOCATION_ID = V_CMM_LOCATION_ID;

       IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG   := 'Error while Updating Card Activation Flag in MERPAN ' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN OTHERS THEN
        V_ERRMSG   := 'Error while Updating first time topup flag' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '21';
        Raise Exp_Main_Reject_Record;
     END;
  End If;
--End for JH-8(Additional Changes)
 End If;
--End for DFCHOST-345

     BEGIN
        sp_log_cardstat_chnge (p_instcode,
                               v_hash_pan,
                               v_encr_pan,
                               v_inil_authid,
                               '01',
                               p_rrn,
                               p_trandate,
                               p_trantime,
                               v_respcode,
                               v_errmsg
                              );

        IF v_respcode <> '00' AND v_errmsg <> 'OK'
        THEN
           RAISE exp_main_reject_record;
        END IF;
     EXCEPTION
        WHEN exp_main_reject_record
        THEN
           RAISE;
        WHEN OTHERS
        THEN
           v_respcode := '21';
           v_errmsg :=
                 'Error while logging system initiated card status change '
              || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_main_reject_record;
     END;

  ---------------------------
  --EN :- Added for DFCHOST-311
  ---------------------------

--St Added for DFCCHW-360 on 10/10/2013
 BEGIN
		UPDATE cms_caf_info_entry
		SET cci_kyc_flag        = 'Y',
		  cci_occupation        = p_type_of_employment,
		  CCI_OCCUPATION_OTHERS = p_occupation,
		  cci_id_province       = p_id_province,
		  cci_id_country        = p_id_country,
		  cci_verification_date = DECODE (p_id_type, 'SSN', NULL,'SIN', NULL, TO_DATE (p_id_verification_date, 'mmddyyyy') ),
		  CCI_ID_EXPIRY_DATE    = DECODE (p_id_type, 'SSN', NULL,'SIN', NULL, --Modified for FWR 70
		  TO_DATE (p_id_expiry_date, 'mmddyyyy') ),
		  cci_document_verify         = p_id_type,
		  cci_tax_res_of_canada       = UPPER(p_tax_res_of_canada),
		  cci_tax_payer_id_num        = p_tax_payer_id_number,
		  Cci_Reason_For_No_Tax_Id    = P_Reason_For_No_Tax_Id ,
		  Cci_Reasontype_For_No_Tax_Id=P_Reason_For_No_Tax_Id_type,
		  cci_jurisdiction_of_tax_res = p_jurisdiction_of_tax_res
		WHERE cci_appl_code           = v_appl_code -- Added for performance fix on 13-jan-2014
		AND cci_inst_code             = p_instcode;

		UPDATE cms_cust_mast
		   SET ccm_kyc_flag = 'Y',
		   ccm_kyc_source='04',
		   CCM_GPR_OPTIN = P_GPR_OPTIN,
		   CCM_ID_TYPE = p_id_type,
		   CCM_IDEXPRY_DATE =
			   DECODE (p_id_type,
					   'SSN', Null,'SIN', Null, --Modified for FWR 70
					   TO_DATE (p_id_expiry_date, 'mmddyyyy')
					  ),
		   ccm_occupation = p_type_of_employment,
		   CCM_OCCUPATION_OTHERS = p_occupation,
		   ccm_id_province = p_id_province,
		   ccm_id_country = p_id_country,
		   ccm_verification_date = DECODE (p_id_type,
							   'SSN', Null,'SIN', Null,
							   TO_DATE (p_id_verification_date, 'mmddyyyy')
							  ),
		   ccm_tax_res_of_canada = UPPER(p_tax_res_of_canada),
		   ccm_tax_payer_id_num = p_tax_payer_id_number,
		   ccm_reason_for_no_tax_id = p_reason_for_no_tax_id_type,
		   ccm_reason_for_no_taxid_others = upper(p_reason_for_no_tax_id),
		   ccm_jurisdiction_of_tax_res = p_jurisdiction_of_tax_res,
		   Ccm_Third_Party_Enabled=upper(P_Thirdpartyenabled)
		WHERE  ccm_cust_code = v_cap_cust_code
		AND ccm_inst_code = p_instcode;
    EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'ERROR WHILE UPDATING CMS_CAF_INFO_ENTRY'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
--End Added for DFCCHW-360 on 10/10/2013

if P_Thirdpartyenabled Is Not Null And upper(P_Thirdpartyenabled)='Y'  then

    Begin
    select to_number(gcm_cntry_code) into V_cntryCode
    From Gen_Cntry_Mast
    Where ((Gcm_Switch_Cntry_Code=Upper(P_Thirdpartycountry)) 
        or (GCM_ALPHA_CNTRY_CODE=upper(p_ThirdPartyCountry)))
    and Gcm_Inst_Code=P_INSTCODE;
     EXCEPTION
      When No_Data_Found Then
       V_ERRMSG   := 'Invalid Country Code' ;
       V_RESPCODE := '49';
       Raise Exp_Main_Reject_Record;
        When Others Then
         V_Respcode := '21';
         V_Errmsg   := 'Error while selecting gen_cntry_mast ' || Substr(Sqlerrm, 1, 300);
         Raise Exp_Main_Reject_Record;
    end;
  
    if p_thirdpartytype = '1' and p_thirdpartyoccupationType is not null and p_thirdpartyoccupationType <> '00' then
          begin
           select vom_occu_name into v_occupation_desc
           from vms_occupation_mast 
           where vom_occu_code =p_thirdpartyoccupationtype;
                 
                   exception
                   When No_Data_Found Then
                     V_ERRMSG   := 'Invalid ThirdParty Occupation Code' ;
                     V_RESPCODE := '49';
                     Raise Exp_Main_Reject_Record;
                    when others then 
                     V_Respcode := '21';
                     V_Errmsg   := 'Error while selecting Vms_Occupation_Mast ' || substr(sqlerrm, 1, 300);
                     raise Exp_Main_Reject_Record;
          End;
    End If;
    
    If P_Thirdpartycountry Is Not Null And upper(P_Thirdpartycountry)  In ('US','CA','USA','CAN') Then
   
        Begin

			Select Gsm_Switch_State_Code,GSM_STATE_CODE  
			Into V_State_Switch_Code,V_Third_party_State_Code
			From Gen_State_Mast
			Where GSM_SWITCH_STATE_CODE=upper(P_Thirdpartystate)
			And Gsm_Cntry_Code=v_cntryCode and Gsm_Inst_Code=P_INSTCODE;
        
        EXCEPTION
         When No_Data_Found Then
           V_ERRMSG   := 'Invalid ThirdParty State Code' ;
           V_RESPCODE := '49';
           Raise Exp_Main_Reject_Record;
            When Others Then
             V_Respcode := '89';
             V_Errmsg   := 'Error while selecting Gen_State_Mast ' || Substr(Sqlerrm, 1, 300);
             Raise Exp_Main_Reject_Record;
        end;
    Else
     V_Third_party_State_Code:= NULL;
     V_State_Desc:=P_Thirdpartystate;
    end if;
  
    Begin
    
      Insert Into Vms_Thirdparty_Address 
     (Vta_Inst_Code,Vta_Cust_Code,VTA_THIRDPARTY_TYPE,VTA_FIRST_NAME,VTA_LAST_NAME,VTA_ADDRESS_ONE,VTA_ADDRESS_TWO,VTA_CITY_NAME,VTA_STATE_CODE,VTA_STATE_DESC,VTA_STATE_SWITCH,VTA_CNTRY_CODE,
      Vta_Pin_Code,Vta_Occupation,Vta_Occupation_Others,VTA_NATURE_OF_BUSINESS,VTA_DOB,VTA_NATURE_OF_RELEATIONSHIP,
      VTA_CORPORATION_NAME,VTA_INCORPORATION_NUMBER,Vta_Ins_User ,Vta_Ins_Date ,Vta_Lupd_User ,Vta_Lupd_Date)
      Values (P_Instcode,V_Cust_Code,P_Thirdpartytype,upper(P_Thirdpartyfirstname),upper(P_Thirdpartylastname),upper(P_Thirdpartyaddress1),upper(P_Thirdpartyaddress2),
      Upper(P_Thirdpartycity),V_Third_Party_State_Code,Upper(V_State_Desc),V_State_Switch_Code,V_Cntrycode,P_Thirdpartyzip,P_Thirdpartyoccupationtype,
      Upper(Decode(P_Thirdpartyoccupationtype,'00',P_Thirdpartyoccupation,V_Occupation_Desc)),upper(P_Thirdpartybusiness),to_date(P_Thirdpartydob,'MM/DD/YYYY'),upper(P_Thirdpartynaturerelationship),upper(P_Thirdpartycorporationname),
      upper(p_ThirdPartyCorporation),1,sysdate,1,sysdate);         
    
      EXCEPTION
        When Others Then
         V_Respcode := '21';
         V_ERRMSG   := 'Error while Inserting third party  address details in Vms_Thirdparty_Address ' || SUBSTR(SQLERRM, 1, 300);
         Raise Exp_Main_Reject_Record;
    End ;
  end if;

   -- For Product code and Product category verification.
   BEGIN

      SELECT COUNT (*)
        INTO v_prod_code_count
        FROM cms_prod_cattype
       WHERE cpc_program_id = p_prod_id
       AND cpc_prod_code = v_prod_code AND cpc_card_type = v_card_type; 

      IF v_prod_code_count = 0
      THEN
         v_respcode := '36';
         v_errmsg :=
               'PROFILE DETAILS SENT NOT CORRECT WITH PRODUCT CODE '
            || p_prod_id
            || ' CATG '
            || v_prod_code; 
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '36';
         v_errmsg := 'Error while selecting count from prod_mast '  --Added for DFCHOST-311
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
        v_agecal := (TRUNC(sysdate)-P_dob)/365;
      EXCEPTION
        WHEN OTHERS THEN
          v_respcode := '21';
          v_errmsg  := 'Error while calculating KYC age-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
      END;

      IF v_agecal  < v_min_age_kyc THEN
        v_respcode := '11';
        v_errmsg  := 'Age Limit Verification Failed';
        RAISE exp_main_reject_record;
      END IF;


    BEGIN
            SELECT GCM_CURR_CODE
            INTO v_curr_code
            FROM GEN_CNTRY_MAST
            WHERE GCM_CNTRY_CODE = p_cntry_code
            AND GCM_INST_CODE = p_instcode;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
         v_respcode := '168';
         v_errmsg := 'Invalid Data for Country Code'|| p_cntry_code;
         RAISE exp_main_reject_record;
         WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting country code detail ' ||
             SUBSTR(SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
    END;



       BEGIN
			SELECT GSM_SWITCH_STATE_CODE
			INTO v_phys_switch_state_code
			FROM  GEN_STATE_MAST
			where  GSM_STATE_CODE = p_state
			AND GSM_CNTRY_CODE = p_cntry_code
			AND GSM_INST_CODE = p_instcode;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
         v_respcode := '167';
         v_errmsg := 'Invalid Data for Physical Address State'|| p_state;
         RAISE exp_main_reject_record;
         WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting Physical switch state code detail ' ||
             SUBSTR(SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
        END;

   --Sn Added for FSS-2321
    BEGIN
       INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
            VALUES (p_rrn, p_delivery_channel, p_txn_code, v_cap_cust_code,1);
    EXCEPTION
       WHEN OTHERS THEN
          v_respcode := '21';
          v_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;
    --En Added for FSS-2321

   BEGIN

      SELECT 
	         cam_add_one,
             cam_add_two,
             cam_city_name, 
             cam_pin_code,
             cam_phone_one,
             cam_mobl_one,
             cam_email,
             cam_state_code,cam_cntry_code
        INTO v_addr_lineone,
             v_addr_linetwo,
             v_city_name, 
             v_pin_code,
             v_phone_no, v_mobl_no, v_email, 
             v_state_code,v_ctnry_code
        FROM cms_addr_mast
       WHERE cam_cust_code = v_cust_code
         AND cam_inst_code = p_instcode
         AND cam_addr_flag = 'P';

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg :=
               'NO DATA FOUND IN ADDRMAST FOR'
            || '-'
            || v_cust_code
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'ERROR IN PROFILE UPDATE ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      SELECT nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn), ccm_birth_date, 
             ccm_first_name,
             ccm_mid_name,
             ccm_last_name
        INTO v_ssn, v_birth_date, v_first_name, v_mid_name,
             v_last_name
        FROM cms_cust_mast
       WHERE ccm_cust_code = v_cust_code AND ccm_inst_code = p_instcode;
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg :=
               'NO DATA FOUND IN CUSTMAST FOR'
            || '-'
            || v_cust_code
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'ERROR IN PROFILE UPDATE ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_main_reject_record;
   END;
  
   IF V_ENCRYPT_ENABLE = 'Y' THEN
        V_ZIPCODE := fn_emaps_main(P_ZIP);
        v_encr_addr_lineone := fn_emaps_main(p_addr_lineone);
        v_encr_addr_linetwo := fn_emaps_main(p_addr_linetwo);
        v_encr_city := fn_emaps_main(p_city);
        v_encr_email := fn_emaps_main(p_email);
        v_encr_phone_no := fn_emaps_main(p_phone_no);
        v_encr_mob_one  := fn_emaps_main(p_other_no);
        
     ELSE
        V_ZIPCODE :=P_ZIP;
        v_encr_addr_lineone := p_addr_lineone;
        v_encr_addr_linetwo := p_addr_linetwo;
        v_encr_city := p_city;
        v_encr_email := p_email;
        v_encr_phone_no := p_phone_no;
        v_encr_mob_one  := p_other_no;
    
    End If;


  BEGIN
        UPDATE cms_addr_mast
         SET cam_add_one = v_encr_addr_lineone,
             cam_add_two = v_encr_addr_linetwo,
             cam_city_name = v_encr_city,
             cam_pin_code = V_ZIPCODE,
             cam_phone_one = v_encr_phone_no,
             cam_mobl_one = v_encr_mob_one,
             cam_email = v_encr_email,
             cam_state_code = p_state,
             cam_cntry_code = p_cntry_code,
			 CAM_STATE_SWITCH=v_phys_switch_state_code, --Added For FSS-919 on 11072013
             CAM_ADD_ONE_ENCR = fn_emaps_main(p_addr_lineone) ,
             CAM_ADD_TWO_ENCR = fn_emaps_main(p_addr_linetwo),
             CAM_CITY_NAME_ENCR = fn_emaps_main(p_city) ,
             CAM_PIN_CODE_ENCR = fn_emaps_main(P_ZIP),
             CAM_EMAIL_ENCR = fn_emaps_main(p_email)
       WHERE cam_cust_code = v_cust_code
         AND cam_inst_code = p_instcode
         AND cam_addr_flag = 'P';


         IF SQL%ROWCOUNT =0
		 THEN
			RAISE v_update_excp;
		 END IF;
    EXCEPTION
         WHEN v_update_excp THEN
         v_respcode := '21';
         V_ERRMSG := 'ERROR IN PROFILE UPDATE' || V_CUST_CODE;
          RAISE EXP_MAIN_REJECT_RECORD;
   WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'ERROR IN PROFILE UPDATE ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_main_reject_record;
   END;
   
		BEGIN
			UPDATE CMS_CUST_MAST
				SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
			WHERE CCM_INST_CODE = P_INSTCODE
			AND CCM_CUST_CODE = v_cust_code;
						
		EXCEPTION
			WHEN OTHERS THEN
				V_ERRMSG := 'Exception While Updating Customer Mast ' || SUBSTR (SQLERRM, 1, 200);
				RAISE EXP_MAIN_REJECT_RECORD;
		END;			


        IF     p_mailaddr_lineone IS NOT NULL
		 AND p_mailaddr_city IS NOT NULL
		 AND p_mailaddr_zip IS NOT NULL
		 AND p_mailaddr_state IS NOT NULL
		 AND p_mailaddr_cnrycode IS NOT NULL

        THEN

            BEGIN
                SELECT GCM_CURR_CODE
                INTO v_curr_code
                FROM GEN_CNTRY_MAST
                WHERE GCM_CNTRY_CODE = p_mailaddr_cnrycode
                AND GCM_INST_CODE = p_instcode;
            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
             v_respcode := '6';
             v_errmsg := 'Invalid Data for Mailing Address Country Code'|| p_mailaddr_cnrycode;
             RAISE exp_main_reject_record;
             WHEN OTHERS THEN
             v_respcode := '21';
             v_errmsg := 'Error while selecting mailing country code detail ' ||
                 SUBSTR(SQLERRM, 1, 200);
            RAISE exp_main_reject_record;

            END;

            BEGIN

            SELECT GSM_SWITCH_STATE_CODE
            INTO v_mailing_switch_state_code
            FROM  GEN_STATE_MAST
            WHERE  GSM_STATE_CODE = p_mailaddr_state
            AND GSM_CNTRY_CODE = p_mailaddr_cnrycode
            AND GSM_INST_CODE = p_instcode;

            EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
             v_respcode := '169';
             v_errmsg := 'Invalid Data for Mailing Address State'|| p_mailaddr_state;
             RAISE exp_main_reject_record;
            WHEN OTHERS THEN
            v_respcode := '21';
             v_errmsg := 'Error while selecting mailing switch code detail ' ||
                 SUBSTR(SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
            END;


           BEGIN

            SELECT count(1)
              INTO v_mailing_addr_count
              FROM cms_addr_mast
              WHERE cam_cust_code = V_CUST_CODE
              AND cam_inst_code = P_INSTCODE
              AND cam_addr_flag = 'O';
           EXCEPTION
             WHEN OTHERS THEN
             v_respcode := '21';
             V_ERRMSG := 'Error while selecting mailing address count ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;
           END;
          
        
        
      IF V_ENCRYPT_ENABLE = 'Y' THEN
        V_ZIPCODE := fn_emaps_main(P_MAILADDR_ZIP);
        v_encr_addr_lineone := fn_emaps_main(P_MAILADDR_LINEONE);
        v_encr_addr_linetwo := fn_emaps_main(P_MAILADDR_LINETWO);
        v_encr_city := fn_emaps_main(P_MAILADDR_CITY);
        v_encr_email := fn_emaps_main(p_email);
        v_encr_phone_no := fn_emaps_main(p_phone_no);
        v_encr_mob_one  := fn_emaps_main(p_other_no);
        
     ELSE
        V_ZIPCODE :=P_MAILADDR_ZIP;
        v_encr_addr_lineone := P_MAILADDR_LINEONE;
        v_encr_addr_linetwo := P_MAILADDR_LINETWO;
        v_encr_city := P_MAILADDR_CITY;
        v_encr_email := p_email;
        v_encr_phone_no := p_phone_no;
        v_encr_mob_one  := p_other_no;
         
     END IF;
 
           IF v_mailing_addr_count <> 0

         THEN

            BEGIN
                 UPDATE cms_addr_mast
                 SET cam_add_one = v_encr_addr_lineone,
                     cam_add_two = v_encr_addr_linetwo,
                     cam_city_name = v_encr_city,
                     cam_pin_code = V_ZIPCODE,
                     cam_phone_one = v_encr_phone_no,
                     cam_mobl_one = v_encr_mob_one,
                     cam_email = v_encr_email,
                     cam_state_code = P_MAILADDR_STATE,
                     cam_cntry_code = P_MAILADDR_CNRYCODE,
                     CAM_ADD_ONE_ENCR = fn_emaps_main(P_MAILADDR_LINEONE),
                     CAM_ADD_TWO_ENCR = fn_emaps_main(P_MAILADDR_LINETWO),
                     CAM_CITY_NAME_ENCR = fn_emaps_main(P_MAILADDR_CITY),
                     CAM_PIN_CODE_ENCR = fn_emaps_main(P_MAILADDR_ZIP),
                     CAM_EMAIL_ENCR = fn_emaps_main(p_email)
               WHERE cam_cust_code = V_CUST_CODE
                 AND cam_inst_code = P_INSTCODE
                 AND cam_addr_flag = 'O';

                 IF SQL%ROWCOUNT =0
                 THEN
                    RAISE v_update_excp;
                  END IF;

            EXCEPTION
             WHEN v_update_excp THEN
             v_respcode := '21';
             V_ERRMSG := 'Error while updating mailing address ' || V_CUST_CODE;
              RAISE EXP_MAIN_REJECT_RECORD;
             WHEN OTHERS THEN
             v_respcode := '21';
             V_ERRMSG := 'Error while updating mailing address ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;
            END;

         ELSE
              BEGIN
                     INSERT INTO cms_addr_mast
                                 (cam_inst_code,
                                  cam_cust_code,
                                  cam_addr_code,
                                  cam_add_one,
                                  cam_add_two,
                                  cam_phone_one,
                                  cam_mobl_one,
                                  cam_email,
                                  cam_pin_code,
                                  cam_cntry_code,
                                  cam_city_name,
                                  cam_addr_flag,
                                  cam_state_code,
                                  cam_state_switch,
                                  cam_ins_user,
                                  cam_ins_date,
                                  cam_lupd_user,
                                  cam_lupd_date,
                                  CAM_ADD_ONE_ENCR,                                 
                                  CAM_ADD_TWO_ENCR,
                                  CAM_CITY_NAME_ENCR,
                                  CAM_PIN_CODE_ENCR,
                                  CAM_EMAIL_ENCR
                                 )
                          VALUES (P_INSTCODE,
                                  V_CUST_CODE,
                                  seq_addr_code.NEXTVAL,
                                  v_encr_addr_lineone,
                                  v_encr_addr_linetwo,
                                  v_encr_phone_no,
                                  v_encr_mob_one,
                                  v_encr_email,
                                  V_ZIPCODE,
                                  P_MAILADDR_CNRYCODE,
                                  v_encr_city,
                                  'O',
                                  P_MAILADDR_STATE,
                                  v_mailing_switch_state_code,
                                  1,
                                  SYSDATE,
                                  1,
                                  SYSDATE,
                                  fn_emaps_main(P_MAILADDR_LINEONE),
                                  fn_emaps_main(P_MAILADDR_LINETWO),
                                  fn_emaps_main(P_MAILADDR_CITY),
                                  fn_emaps_main(P_MAILADDR_ZIP),
                                  fn_emaps_main(p_email)
                                  );
                EXCEPTION
                WHEN OTHERS THEN
                V_RESPCODE := '21';
                V_ERRMSG   := 'Error whiling inserting Mailing Address' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_MAIN_REJECT_RECORD;
             END;
         END IF;

         END IF;

      -- En Added on 25-Apr-2013 by MageshKumar.S for Defect Id:DFCHOST-310

       --added on 30-10-2017
  IF  p_id_province IS NOT NULL  AND p_id_country IS NOT NULL
      THEN
       BEGIN
          SELECT gcm_alpha_cntry_code
          INTO v_id_country
          FROM gen_cntry_mast
          WHERE gcm_inst_code   = p_instcode
          AND GCM_SWITCH_CNTRY_CODE = p_id_country;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_respcode := '274';
          V_ERRMSG  := 'Invalid Data for ID Country code';
          RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
        END;


        BEGIN
          SELECT gsm_switch_state_code
          INTO v_id_province
          FROM gen_state_mast
          WHERE gsm_inst_code   = p_instcode
		    AND gsm_alpha_cntry_code = v_id_country
            AND gsm_switch_state_code  = p_id_province;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_respcode := '273';
          V_ERRMSG  := 'Invalid Data for ID Province';
          RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG  := 'Error while selecting state-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
        END;


      END IF;
      --added on 30-10-2017
      IF  p_jurisdiction_of_tax_res IS NOT NULL
      THEN
         BEGIN
          SELECT GCM_SWITCH_CNTRY_CODE
          INTO v_jurisdiction_of_tax_res
          FROM gen_cntry_mast
          WHERE gcm_inst_code   = p_instcode
          AND GCM_SWITCH_CNTRY_CODE = p_jurisdiction_of_tax_res ;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_respcode := '275';
          V_ERRMSG  := 'Invalid Data for Jurisdiction of Tax Residence';
          RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG  := 'Error while selecting Country-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
        END;

       END IF;
       
       
      IF V_ENCRYPT_ENABLE = 'Y' THEN
          v_encr_first_name := fn_emaps_main(p_first_name);
          v_encr_last_name  := fn_emaps_main(p_last_name); 
	  v_encr_mid_name  := fn_emaps_main(p_middle_name); 
       else
          v_encr_first_name := p_first_name;
          v_encr_last_name  := p_last_name;  
	  v_encr_mid_name  := p_middle_name; 
      end if; 
       
      --Sn Added on 05_Feb_13 for multiple SSN Check
       BEGIN
      IF p_txn_code = '68' AND p_delivery_channel = '04'
      THEN
         UPDATE cms_cust_mast
            SET ccm_ssn = fn_maskacct_ssn(p_instcode,p_ssn,0),
                ccm_ssn_encr =fn_emaps_main(p_ssn),
                ccm_id_type =p_id_type,
                ccm_birth_date = p_dob,
                ccm_first_name = v_encr_first_name,
                ccm_mid_name = v_encr_mid_name,
                ccm_last_name = v_encr_last_name,
                CCM_FLNAMEDOB_HASHKEY = V_FLDOB_HASHKEY_ID,
                CCM_BUSINESS_NAME = p_business_name_in,
                ccm_occupation  =  p_type_of_employment,
	             -- ccm_id_reference = p_id_reference,
                ccm_id_province = p_id_province,
                ccm_id_country = p_id_country,
                ccm_idexpry_date =  DECODE (p_id_type,
                                   'SSN', NULL,'SIN', NULL,
                                    TO_DATE (p_id_expiry_date, 'mmddyyyy')
                                     ),
                ccm_verification_date =  DECODE (p_id_type,
                                   'SSN', NULL,'SIN', NULL,
                                    TO_DATE (p_id_verification_date, 'mmddyyyy')
                                     ),
                Ccm_Tax_Res_Of_Canada  = P_Tax_Res_Of_Canada,
                Ccm_Tax_Payer_Id_Num = P_Tax_Payer_Id_Number,
                 Ccm_Reason_For_No_Tax_Id = P_Reason_For_No_Tax_Id_Type,
                    ccm_reason_for_no_taxid_others = upper(p_reason_for_no_tax_id),
                ccm_jurisdiction_of_tax_res = p_jurisdiction_of_tax_res,
                CCM_OCCUPATION_OTHERS = upper(p_occupation),
                CCM_FIRST_NAME_ENCR = fn_emaps_main(p_first_name),
                CCM_LAST_NAME_ENCR  = fn_emaps_main(p_last_name),CCM_MEMBER_ID=p_member_id
          WHERE ccm_cust_code = v_cust_code AND ccm_inst_code = p_instcode;
      ELSE
         --En Added on 05_Feb_13 for multiple SSN Check
         UPDATE cms_cust_mast
            SET ccm_ssn = fn_maskacct_ssn(p_instcode,p_ssn,0),
                ccm_ssn_encr =fn_emaps_main(p_ssn),
                ccm_birth_date = p_dob,
                ccm_first_name = v_encr_first_name,
                ccm_mid_name = v_encr_mid_name,
                ccm_last_name = v_encr_last_name,
                CCM_FLNAMEDOB_HASHKEY = V_FLDOB_HASHKEY_ID,
                ccm_occupation  =  p_type_of_employment,
                ccm_id_type = p_id_type,
              --  ccm_id_reference = p_id_reference,
                ccm_id_province = p_id_province,
                ccm_id_country = p_id_country,
                ccm_idexpry_date =  DECODE (p_id_type,
                                   'SSN', NULL,'SIN', NULL,
                                    TO_DATE (p_id_expiry_date, 'mmddyyyy')
                                     ),
                ccm_verification_date =  DECODE (p_id_type,
                                   'SSN', NULL,'SIN', NULL,
                                    TO_DATE (p_id_verification_date, 'mmddyyyy')
                                     ),
                Ccm_Tax_Res_Of_Canada  = P_Tax_Res_Of_Canada,
                Ccm_Tax_Payer_Id_Num = P_Tax_Payer_Id_Number,
                 Ccm_Reason_For_No_Tax_Id = P_Reason_For_No_Tax_Id_Type,
                    ccm_reason_for_no_taxid_others = p_reason_for_no_tax_id,
                 ccm_jurisdiction_of_tax_res = p_jurisdiction_of_tax_res,
                CCM_OCCUPATION_OTHERS = p_occupation,
                CCM_FIRST_NAME_ENCR = fn_emaps_main(p_first_name),
                CCM_LAST_NAME_ENCR  = fn_emaps_main(p_last_name) 
          WHERE ccm_cust_code = v_cust_code AND ccm_inst_code = p_instcode;
      END IF;                      --Added on 05_Feb_13 for multiple SSN Check

      INSERT INTO cms_cardprofile_hist
                  (ccp_pan_code, ccp_inst_code, ccp_add_one, ccp_add_two,
                   ccp_city_name, ccp_pin_code, ccp_phone_one, ccp_mobl_one,
                   ccp_email, ccp_state_code, ccp_cntry_code, ccp_cust_code,
                   ccp_ssn, ccp_birth_date, ccp_first_name, ccp_mid_name,
                   ccp_last_name, ccp_pan_code_encr, ccp_ins_date,
                   ccp_lupd_date, ccp_mbr_numb, ccp_rrn, ccp_stan,
                   ccp_business_date, ccp_business_time, ccp_terminal_id
                  )
           VALUES (v_hash_pan, p_instcode, v_addr_lineone, v_addr_linetwo,
                   v_city_name, v_pin_code, v_phone_no, v_mobl_no,
                   v_email, v_state_code, v_ctnry_code, v_cust_code,
                   FN_MASKACCT_SSN(p_instcode,v_ssn,0), v_birth_date, v_first_name, v_mid_name,
                   v_last_name, v_encr_pan, SYSDATE,
                   SYSDATE, p_mbr_numb, p_rrn, p_stan,
                   p_trandate, p_trantime, p_terminalid
                  );
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg :=
               'NO DATA FOUND IN ADDRMAST/CUSTMAST FOR'
            || '-'
            || v_cust_code
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'ERROR IN PROFILE UPDATE ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_main_reject_record;
   END;


   --Sm For Debit Card No Need of doing authorization
   IF v_cap_prod_catg = 'P'
   THEN
      /* Start Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
      BEGIN
         IF v_lmtprfl IS NOT NULL AND v_prfl_flag = 'Y'
         THEN
            pkg_limits_check.sp_limits_check (v_hash_pan,
                                              NULL,
                                              NULL,
                                              NULL,             -- p_mcc_code,
                                              p_txn_code,
                                              v_tran_type,
                                              NULL,             -- P_INTERNATIONAL_IND,
                                              NULL,
                                              p_instcode,
                                              NULL,
                                              v_lmtprfl,
                                              p_amount,         -- p_txn_amt,
                                              p_delivery_channel,
                                              v_comb_hash,
                                              v_respcode,
                                              v_respmsg
                                             );
         END IF;

         IF v_respcode <> '00' AND v_respmsg <> 'OK'
         then
     --Sn Added for JH 3012
          if( NVL(SUBSTR(P_REASON_CODE,1,1),0)='F'
          or NVL(SUBSTR(P_REASON_CODE,1,1),0)='T'
          or NVL(SUBSTR(P_REASON_CODE,1,1),0)='A'
          or NVL(SUBSTR(P_REASON_CODE,1,1),0)='R'
          or NVL(SUBSTR(P_REASON_CODE,1,1),0)='S'
          or NVL(SUBSTR(P_REASON_CODE,1,1),0)='0') then

          if V_RESPCODE='79' then
          V_RESPCODE:='231';
          V_ERRMSG:='Denomination below minimal amount permitted';
          RAISE exp_main_reject_record;
          end if;

            if V_RESPCODE='80' then
          V_RESPCODE:='230';
          v_errmsg:='Denomination exceed permitted amount';
          RAISE exp_main_reject_record;
          end if;

         else
     --En Added for JH 3012
            v_errmsg := 'Error from Limit Check Process ' || v_respmsg;
            RAISE exp_main_reject_record;
         end if;
         end if;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   /* End  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */

    END IF;

   ----Sm For Debit Card No Need of doing authorization

   --Sn Selecting Reason code for Initial Load
   BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM cms_spprt_reasons
       WHERE csr_inst_code = p_instcode AND csr_spprt_key = 'INILOAD';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'Initial load reason code is present in master';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Sn create a record in pan spprt
   BEGIN
      INSERT INTO cms_pan_spprt
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,
                   cps_pan_code_encr
                  )
           VALUES (p_instcode, v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'INLOAD', v_resoncode, v_remrk,
                   p_lupduser, p_lupduser, 0,
                   v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En create a record in pan spprt

   --Sn select response code and insert record into txn log dtl
   IF v_respcode <> '00'
   THEN
      BEGIN
         p_errmsg := v_errmsg;
         p_resp_code := v_respcode;

         -- Assign the response code to the out parameter
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg :=
                    'No data available in response master  for' || v_respcode;
            p_resp_code := '89';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
            RAISE exp_main_reject_record;
      END;
   ELSE
      p_resp_code := v_respcode;
   END IF;

   --En select response code and insert record into txn log dtl

   ---Sn Updation of Usage limit and amount
   BEGIN
      SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
        INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
        FROM cms_translimit_check
       WHERE ctc_inst_code = p_instcode
         AND ctc_pan_code = v_hash_pan                             --P_card_no
         AND ctc_mbr_numb = p_mbr_numb;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
               'Cannot get the Transaction Limit Details of the Card'
            || SUBSTR (SQLERRM, 1, 300);
         v_respcode := '21';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting CMS_TRANSLIMIT_CHECK'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   BEGIN
      --Sn Usage limit and amount updation for MMPOS
      IF p_delivery_channel = '04'
      THEN
         IF v_tran_date > v_business_date_tran
         THEN
            v_mmpos_usagelimit := 1;

            BEGIN
               UPDATE cms_translimit_check
                  SET ctc_mmposusage_amt = 0,
                      ctc_mmposusage_limit = v_mmpos_usagelimit,
                      ctc_atmusage_amt = 0,
                      ctc_atmusage_limit = 0,
                      ctc_business_date =
                         TO_DATE (p_trandate || '23:59:59',
                                  'yymmdd' || 'hh24:mi:ss'
                                 ),
                      ctc_preauthusage_limit = 0,
                      ctc_posusage_amt = 0,
                      ctc_posusage_limit = 0
                WHERE ctc_inst_code = p_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = p_mbr_numb;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg :=
                            'updating 1 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE exp_main_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updating 1 CMS_TRANSLIMIT_CHECK'
                     || SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         ELSE
            v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

            BEGIN
               UPDATE cms_translimit_check
                  SET ctc_mmposusage_limit = v_mmpos_usagelimit
                WHERE ctc_inst_code = p_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = p_mbr_numb;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg :=
                            'updating 2 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE exp_main_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updating 2 CMS_TRANSLIMIT_CHECK'
                     || SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         END IF;
      END IF;
   --En Usage limit and amount updation for MMPOS
   END;

   ---En Updation of Usage limit and amount

   --IF errmsg is OK then balance amount will be returned
   IF p_errmsg = 'OK'
   THEN
     --Updated by Ramesh.A on 20/07/2012
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal
		  INTO v_acct_balance, v_ledger_balance
		  FROM cms_acct_mast
		  WHERE cam_acct_no = p_dda_number 
		  AND cam_inst_code = p_instcode;
        EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code := '14';                     --Ineligible Transaction
            v_errmsg := 'Invalid Card ';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            v_errmsg :=
                  'Error while selecting data from card Master for card number '
               || SQLERRM;
            RAISE exp_main_reject_record;
      END;

      --En of Getting  the Acct Balannce
      p_errmsg := TO_CHAR (v_acct_balance);
   END IF;

/* Start  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
   BEGIN
      IF v_lmtprfl IS NOT NULL AND v_prfl_flag = 'Y'
      -- V_PRFL_CODE replaced with v_lmtprfl on 20Dec2012 FSS-847
      THEN
         pkg_limits_check.sp_limitcnt_reset
                   (p_instcode,
                    v_hash_pan,
                    p_amount,                                     --p_txn_amt,
                    v_comb_hash,
                    v_respcode,
                    v_respmsg -- v_errmsg replaced by v_respmsg on 12-Feb-2013
                   );
      END IF;

      IF v_respcode <> '00' AND v_respmsg <> 'OK'
      THEN
         v_errmsg := 'From Procedure sp_limitcnt_reset' || v_respmsg;
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error from Limit Reset Count Process '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
/* End  Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */

  --Sn Added for FSS-4647
   IF v_txn_redmption_flag='Y' AND v_redmption_delay_flag='Y' THEN
    BEGIN
       vmsredemptiondelay.redemption_delay (v_acct_number,
                                            p_rrn,
                                            p_delivery_channel,
                                            p_txn_code,
                                            v_tran_amt,
                                            v_prod_code,
                                            v_card_type,
                                            UPPER (p_merchant_name),
                                            p_merchantZipCode,--added for VMS-622 (redemption_delay zip code validation)
                                            v_errmsg);

       IF v_errmsg <> 'OK'
       THEN
          RAISE exp_main_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_main_reject_record
       THEN
          RAISE;
       WHEN OTHERS
       THEN
          v_errmsg :='Error while calling sp_log_delayed_load: ' || SUBSTR (SQLERRM, 1, 200);
          v_respcode := '21';
          RAISE exp_main_reject_record;
    END;
   END IF;
   --En Added for FSS-4647

 --SantoshP 17 JUL 13 : FSS-1146 : Block added to update  STORE_ID in transactionlog table
   Begin
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
	
       Update Transactionlog
         Set Store_Id = p_StoreID, --Modified by ravi for regarding JH-8
         trans_desc=v_trans_desc, --Added by Ravi for regarding JH-8
         CUSTOMER_STARTER_CARD_NO=V_ENCR_PAN, --Added on 24/09/2013 for mantis id :12449 and 12464
         GPRCARDAPPLICATIONNO=v_appl_code--Added on 24/09/2013 for mantis id :12449 and 12464
         ,terminal_id=p_termid_in
        Where Instcode = P_Instcode
         And Rrn = P_Rrn
         And Customer_Card_No = V_Hash_Pan
         And Business_Date = P_Trandate
         And Txn_Code=P_Txn_Code
         AND delivery_channel = p_delivery_channel;
ELSE
		Update VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         Set Store_Id = p_StoreID, --Modified by ravi for regarding JH-8
         trans_desc=v_trans_desc, --Added by Ravi for regarding JH-8
         CUSTOMER_STARTER_CARD_NO=V_ENCR_PAN, --Added on 24/09/2013 for mantis id :12449 and 12464
         GPRCARDAPPLICATIONNO=v_appl_code--Added on 24/09/2013 for mantis id :12449 and 12464
         ,terminal_id=p_termid_in
        Where Instcode = P_Instcode
         And Rrn = P_Rrn
         And Customer_Card_No = V_Hash_Pan
         And Business_Date = P_Trandate
         And Txn_Code=P_Txn_Code
         AND delivery_channel = p_delivery_channel;
END IF;
		 

    If Sql%Rowcount = 0 Then
       P_ERRMSG   := 'Error while Updating StoreId in Transactionlog table' ||
                  Substr(Sqlerrm, 1, 200);
       V_RESPCODE := '21';
       Raise Exp_Main_Reject_Record;
     END IF;
   EXCEPTION
       WHEN OTHERS THEN
        P_ERRMSG   := 'Error while Updating StoreId in Transactionlog table' ||
                    Substr(Sqlerrm, 1, 200);
        V_RESPCODE := '21';
        Raise Exp_Main_Reject_Record;
   End;

            BEGIN

              select csa_alert_lang_id 
			  INTO L_ALERT_LANG_ID 
			  from CMS_SMSANDEMAIL_ALERT 
			  where CSA_INST_CODE=p_instcode 
			  AND CSA_PAN_CODE=v_hash_pan;

              EXCEPTION

                WHEN NO_DATA_FOUND THEN
                    v_respcode := '21';
                    V_ERRMSG  := 'No Alert Details found for the card '|| FN_MASK(p_acctno,'X',7,6);
              RAISE Exp_Main_Reject_Record;
                WHEN OTHERS THEN
                v_respcode := '21';
                V_ERRMSG  := 'Error while Selecting Alert Details of Card'||SUBSTR(SQLERRM, 1, 200);
              RAISE Exp_Main_Reject_Record;
             END;

          if L_ALERT_LANG_ID is null then

          BEGIN

           SELECT cps_alert_lang_id INTO L_ALERT_LANG_ID  FROM
           cms_prodcatg_smsemail_alerts
           WHERE cps_inst_code = p_instcode
           AND cps_prod_code = V_prod_code
           AND cps_card_type = V_card_type
           AND cps_defalert_lang_flag='Y'
           AND ROWNUM=1;

           EXCEPTION

            WHEN OTHERS THEN
                v_respcode := '21';
                V_ERRMSG  := 'Error while Selecting dafault alert  language id '||SUBSTR(SQLERRM, 1, 200);
              RAISE Exp_Main_Reject_Record;


          END;


          end if;




   --sn Added for 0012337 JH-8
     Begin
     for i1 in ALERTDTLS(p_instcode,v_prod_code, v_card_type,L_ALERT_LANG_ID)
     LOOP
     IF I1.CPS_ALERT_ID='9'
     then
     v_loadcredit_flag:=I1.alert_flag ;
     end if;
     IF I1.CPS_ALERT_ID='10'
      THEN
      v_lowbal_flag:=I1.alert_flag;
    end if;

    IF I1.CPS_ALERT_ID='11'
      THEN
       v_negativebal_flag:=I1.alert_flag;
    end if;

     IF I1.CPS_ALERT_ID='13'
      THEN
       v_incorrectpin_flag:=I1.alert_flag;
    end if;

     IF I1.CPS_ALERT_ID='16'
      THEN
       v_highauthamt_flag:=I1.alert_flag;
    end if;

     IF I1.CPS_ALERT_ID='12'
      THEN
       v_dailybal_flag:=I1.alert_flag;
    end if;

     IF I1.CPS_ALERT_ID='17'
      THEN
       v_insuffund_flag:=I1.alert_flag;
    end if;

     IF I1.CPS_ALERT_ID='21'
      THEN
       v_fast50_flag:=I1.alert_flag;
    end if;

     IF I1.CPS_ALERT_ID='22'
      THEN
       v_federal_flag:=I1.alert_flag;
    end if;

   end loop;


   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        V_RESPCODE := '21'; --Added for code review on 10/10/2013
         v_errmsg :=
               'Invalid product code '
            || v_prod_code
            || ' and card type'
            || v_card_type;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
        V_RESPCODE := '21'; --Added for code review on 10/10/2013
         v_errmsg :=
               'Error while selecting alerts for '
            || v_prod_code
            || ' and '
            || v_card_type;
         RAISE exp_main_reject_record;
   END;
  --en Added for 0012337 JH-8

  BEGIN
  UPDATE CMS_SMSANDEMAIL_ALERT
  SET CSA_LOADORCREDIT_FLAG=DECODE(NVL(v_loadcredit_flag,0),'0','0',V_OPTIN),
      CSA_LOWBAL_FLAG =DECODE(NVL(v_lowbal_flag,0),'0','0',V_OPTIN),
      CSA_NEGBAL_FLAG=DECODE(NVL(v_negativebal_flag,0),'0','0',V_OPTIN),
      CSA_HIGHAUTHAMT_FLAG=DECODE(NVL(v_highauthamt_flag,0),'0','0',V_OPTIN),
          CSA_DAILYBAL_FLAG=DECODE(NVL(v_dailybal_flag,0),'0','0',V_OPTIN),
      CSA_INSUFF_FLAG=DECODE(NVL(v_insuffund_flag,0),'0','0',V_OPTIN),
      CSA_INCORRPIN_FLAG=DECODE(NVL(v_incorrectpin_flag,0),'0','0',V_OPTIN),
      CSA_FAST50_FLAG=DECODE(NVL(v_fast50_flag,0),'0','0',V_OPTIN),-- Added by MageshKUmar.S on 19-09-2013 for JH-6
      CSA_FEDTAX_REFUND_FLAG=DECODE(NVL(v_federal_flag,0),'0','0',V_OPTIN),-- Added by MageshKUmar.S on 19-09-2013 for JH-6
      CSA_LUPD_DATE=sysdate,
      CSA_BEGIN_TIME=NVL(CSA_BEGIN_TIME, 0),
      CSA_END_TIME=NVL(CSA_END_TIME, 0),
      CSA_LOWBAL_AMT=NVL(CSA_LOWBAL_AMT, 0),
      CSA_HIGHAUTHAMT=NVL(CSA_HIGHAUTHAMT, 0),
      CSA_ALERT_LANG_ID=L_ALERT_LANG_ID --Added for FWR-59
      WHERE CSA_INST_CODE=p_instcode AND CSA_PAN_CODE=v_hash_pan;

        IF SQL%ROWCOUNT = 0 THEN
       P_ERRMSG   := 'Error while Updating Optin_alerts in CMS_SMSANDEMAIL_ALERT' ||
                  Substr(Sqlerrm, 1, 200);
       V_RESPCODE := '21';
       Raise Exp_Main_Reject_Record;
     END IF;
     EXCEPTION
      WHEN Exp_Main_Reject_Record THEN
             RAISE Exp_Main_Reject_Record;
       WHEN OTHERS THEN
        P_ERRMSG   := 'Error while Updating Optin_alerts in CMS_SMSANDEMAIL_ALERT table' ||
                    Substr(Sqlerrm, 1, 200);
        V_RESPCODE := '21';
        Raise Exp_Main_Reject_Record;

   END;
   --End set Alerts from CMS_SMSANDEMAIL_ALERT for regarding JH-8

   --Sn logging into Resoncode,optin,taxid into Cms_transaction_log_dtl for regarding JH-8
    BEGIN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET
              CTD_LOCATION_ID=p_terminalid,
              CTD_TAXPREPARE_ID=P_TaxPrepareID,
              CTD_ALERT_OPTIN=P_Optin,
              CTD_REASON_CODE=P_REASON_CODE,
              CTD_GPR_OPTIN=P_GPR_OPTIN --Added for JH 3011
              WHERE CTD_RRN=p_rrn AND CTD_BUSINESS_DATE=p_trandate
              AND CTD_BUSINESS_TIME=p_trantime
              AND CTD_DELIVERY_CHANNEL=p_delivery_channel
              AND CTD_TXN_CODE=p_txn_code
              AND CTD_MSG_TYPE=p_msg_type
              and CTD_INST_CODE=P_INSTCODE
              and CTD_CUSTOMER_CARD_NO=v_hash_pan;--Added for JH 3012
ELSE
			UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST		--Added for VMS-5733/FSP-991
              SET
              CTD_LOCATION_ID=p_terminalid,
              CTD_TAXPREPARE_ID=P_TaxPrepareID,
              CTD_ALERT_OPTIN=P_Optin,
              CTD_REASON_CODE=P_REASON_CODE,
              CTD_GPR_OPTIN=P_GPR_OPTIN --Added for JH 3011
              WHERE CTD_RRN=p_rrn AND CTD_BUSINESS_DATE=p_trandate
              AND CTD_BUSINESS_TIME=p_trantime
              AND CTD_DELIVERY_CHANNEL=p_delivery_channel
              AND CTD_TXN_CODE=p_txn_code
              AND CTD_MSG_TYPE=p_msg_type
              and CTD_INST_CODE=P_INSTCODE
              and CTD_CUSTOMER_CARD_NO=v_hash_pan;--Added for JH 3012
END IF;			  

             IF SQL%ROWCOUNT = 0 THEN
                P_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                V_RESPCODE := '21';
              RAISE Exp_Main_Reject_Record;
             END IF;
             EXCEPTION
             WHEN Exp_Main_Reject_Record THEN
             RAISE Exp_Main_Reject_Record;
               WHEN OTHERS THEN
                V_RESPCODE := '21';
                P_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE Exp_Main_Reject_Record;
            END;
 --En logging into Resoncode,optin,taxid into Cms_transaction_log_dtl for regarding JH-8
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_auth_reject_record
   THEN
      ROLLBACK;
      p_errmsg := v_errmsg;
      p_resp_code := v_respcode;

      ---Sn Updation of Usage limit and amount
      BEGIN
         SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
           INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
           FROM cms_translimit_check
          WHERE ctc_inst_code = p_instcode
            AND ctc_pan_code = v_hash_pan                          --P_card_no
            AND ctc_mbr_numb = p_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Cannot get the Transaction Limit Details of the Card'
               || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting 1 CMS_TRANSLIMIT_CHECK'
               || SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;

      BEGIN
         --Sn Usage limit and amount updation for MMPOS
         IF p_delivery_channel = '04'
         THEN
            IF v_tran_date > v_business_date_tran
            THEN
               v_mmpos_usagelimit := 1;

               BEGIN
                  UPDATE cms_translimit_check
                     SET ctc_mmposusage_amt = 0,
                         ctc_mmposusage_limit = v_mmpos_usagelimit,
                         ctc_atmusage_amt = 0,
                         ctc_atmusage_limit = 0,
                         ctc_business_date =
                            TO_DATE (p_trandate || '23:59:59',
                                     'yymmdd' || 'hh24:mi:ss'
                                    ),
                         ctc_preauthusage_limit = 0,
                         ctc_posusage_amt = 0,
                         ctc_posusage_limit = 0
                   WHERE ctc_inst_code = p_instcode
                     AND ctc_pan_code = v_hash_pan
                     AND ctc_mbr_numb = p_mbr_numb;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating3 CMS_TRANSLIMIT_CHECK'
                        || SUBSTR (SQLERRM, 1, 200);
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
               END;
            ELSE
               v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

               BEGIN
                  UPDATE cms_translimit_check
                     SET ctc_mmposusage_limit = v_mmpos_usagelimit
                   WHERE ctc_inst_code = p_instcode
                     AND ctc_pan_code = v_hash_pan
                     AND ctc_mbr_numb = p_mbr_numb;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating 4 CMS_TRANSLIMIT_CHECK'
                        || SUBSTR (SQLERRM, 1, 200);
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
               END;
            END IF;
         END IF;
      --En Usage limit and amount updation for MMPOS
      END;

      ---En Updation of Usage limit and amount

      --Sn create a entry in txn log
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type,
                      bank_code,
                      total_amount,
                      currencycode, addcharge, productid, categoryid,
                      atm_name_location, auth_id,
                      amount,
                      preauthamount, partialamount, instcode,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance, response_id,
                      cardstatus,    --Added cardstatus insert in transactionlog by srinivasu.k
                      error_msg,     -- Added by Ramesh.A on 03/07/2012
                      trans_desc,    -- FOR Transaction detail report issue
                      merchant_name, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      merchant_city, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      merchant_state,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      store_id,      --SantoshP 17 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
                      TIME_STAMP,fundingaccount,merchant_zip --regarding JH-8
                     )
              VALUES (p_msg_type, p_rrn, p_delivery_channel, p_termid_in,
                      v_business_date, p_txn_code, v_txn_type, p_txn_mode,
                      DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                      p_trandate, SUBSTR (p_trantime, 1, 10), v_hash_pan,
                      NULL, NULL, NULL,
                      p_instcode,
                      TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99')),
                      v_currcode, NULL, v_prod_code, v_card_type,
                      p_termid_in, v_inil_authid,
                      TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99')),
                      NULL, NULL, p_instcode,
                      v_encr_pan, v_encr_pan,
                      v_proxunumber, p_rvsl_code, v_acct_number,
                      v_acct_balance, v_ledger_balance, v_respcode,
                      v_cap_card_stat, --Added cardstatus insert in transactionlog by srinivasu.k
                      p_errmsg,        -- Added by Ramesh.A on 03/07/2012
                      v_trans_desc,    -- FOR Transaction detail report issue
                      p_merchant_name, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      p_merchant_city, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      NULL,            -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
					            p_StoreID,V_TIME_STAMP,p_funding_account-- Updated by Ravi N for regarding JH-8
                     ,p_merchantZipCode--added for VMS-622 (redemption_delay zip code validation)

                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --En create a entry in txn log
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number,
                       CTD_ALERT_OPTIN,CTD_TAXPREPARE_ID,CTD_LOCATION_ID,CTD_REASON_CODE,CTD_HASHKEY_ID -- Add  for regarding JH-8
                     ,CTD_GPR_OPTIN) --Added for JH 3011
              VALUES (p_delivery_channel, p_txn_code, p_msg_type,
                      p_txn_mode, p_trandate, p_trantime,
                      v_hash_pan, p_amount, v_currcode,
                      p_amount, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      v_errmsg, p_rrn, p_instcode,
                      v_encr_pan, v_acct_number,
                       P_OPTIN,P_TAXPREPAREID,P_TERMINALID,P_REASON_CODE,V_HASHKEY_ID  -- Add  for regarding JH-8
                    ,P_GPR_OPTIN ); --Added for JH 3011

         p_errmsg := v_errmsg;
         RETURN;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '22';                            -- Server Declined
            ROLLBACK;
            RETURN;
      END;

      p_errmsg := v_authmsg;
   WHEN exp_main_reject_record
   THEN
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_balance
           FROM cms_acct_mast
          WHERE cam_acct_no =
                   (SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_pan_code = v_hash_pan
                       AND cap_mbr_numb = p_mbr_numb
                       AND cap_inst_code = p_instcode)
            AND cam_inst_code = p_instcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
      END;

      ---Sn Updation of Usage limit and amount
      BEGIN
         SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
           INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
           FROM cms_translimit_check
          WHERE ctc_inst_code = p_instcode
            AND ctc_pan_code = v_hash_pan
            AND ctc_mbr_numb = p_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Cannot get the Transaction Limit Details of the Card'
               || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;

      BEGIN
         --Sn Usage limit and amount updation for MMPOS
         IF p_delivery_channel = '04'
         THEN
            IF v_tran_date > v_business_date_tran
            THEN
               v_mmpos_usagelimit := 1;

               UPDATE cms_translimit_check
                  SET ctc_mmposusage_amt = 0,
                      ctc_mmposusage_limit = v_mmpos_usagelimit,
                      ctc_atmusage_amt = 0,
                      ctc_atmusage_limit = 0,
                      ctc_business_date =
                         TO_DATE (p_trandate || '23:59:59',
                                  'yymmdd' || 'hh24:mi:ss'
                                 ),
                      ctc_preauthusage_limit = 0,
                      ctc_posusage_amt = 0,
                      ctc_posusage_limit = 0
                WHERE ctc_inst_code = p_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = p_mbr_numb;
            ELSE
               v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

               UPDATE cms_translimit_check
                  SET ctc_mmposusage_limit = v_mmpos_usagelimit
                WHERE ctc_inst_code = p_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = p_mbr_numb;
            END IF;
         END IF;
      --En Usage limit and amount updation for MMPOS
      END;

      ---En Updation of Usage limit and amount
      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_inil_authid
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';                            -- Server Declined
      END;

      --En generate auth id

      --Sn select response code and insert record into txn log dtl
      BEGIN
         p_errmsg := v_errmsg;
         p_resp_code := v_respcode;

         -- Assign the response code to the out parameter
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
            --ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
      END;

      --Sn create a entry in txn log
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type,
                      bank_code,
                      total_amount,
                      currencycode, addcharge, productid, categoryid,
                      atm_name_location, auth_id,
                      amount,
                      preauthamount, partialamount, instcode,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance, response_id,
                      cardstatus,    --Added cardstatus insert in transactionlog by srinivasu.k
                      error_msg,     -- Added by Ramesh.A on 03/07/2012,
                      trans_desc,    -- FOR Transaction detail report issue
                      merchant_name, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      merchant_city, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      merchant_state,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      ssn_fail_dtls, --ssn_crd_dtls added on 05-Feb-13 for multiple SSN checks
                      STORE_ID,TIME_STAMP,fundingaccount,merchant_zip  --SantoshP 17 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
                     )
              VALUES (p_msg_type, p_rrn, p_delivery_channel, p_termid_in,
                      v_business_date, p_txn_code, v_txn_type, p_txn_mode,
                      DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                      p_trandate, SUBSTR (p_trantime, 1, 10), v_hash_pan,
                      NULL, NULL, NULL,
                      p_instcode,
                      TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99')),
                      v_currcode, NULL, v_prod_code, v_card_type,
                      p_termid_in, v_inil_authid,
                      TRIM (TO_CHAR (v_tran_amt, '99999999999999999.99')),
                      NULL, NULL, p_instcode,
                      v_encr_pan, v_encr_pan,
                      v_proxunumber, p_rvsl_code, v_acct_number,
                      v_acct_balance, v_ledger_balance, v_respcode,
                      v_cap_card_stat,--Added cardstatus insert in transactionlog by srinivasu.k
                      p_errmsg,       -- Added by Ramesh.A on 03/07/2012
                      v_trans_desc,   -- FOR Transaction detail report issue
                      p_merchant_name,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      p_merchant_city,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      NULL,           -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                      v_ssn_crddtls,  --v_ssn_crddtls added on 05-Feb-13 for multiple SSN checks
					  p_StoreID,V_TIME_STAMP,p_funding_account--Updated by Ravi N for regarding JH-8
                     ,p_merchantZipCode --added for VMS-622 (redemption_delay zip code validation)
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;

      --En create a entry in txn log
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number,
                      CTD_ALERT_OPTIN,CTD_TAXPREPARE_ID,CTD_LOCATION_ID,CTD_REASON_CODE,CTD_HASHKEY_ID -- Add  for regarding JH-8
                     ,CTD_GPR_OPTIN) --Added for JH 3011
              VALUES (p_delivery_channel, p_txn_code, p_msg_type,
                      p_txn_mode, p_trandate, p_trantime,
                      v_hash_pan, p_amount, v_currcode,
                      p_amount, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      v_errmsg, p_rrn, p_instcode,
                      v_encr_pan, v_acct_number,
                      P_OPTIN,P_TAXPREPAREID,P_TERMINALID,P_REASON_CODE,V_HASHKEY_ID  -- Add  for regarding JH-8
                     ,P_GPR_OPTIN); --Added for JH 3011

         p_errmsg := v_errmsg;
         RETURN;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '22';                            -- Server Declined
            ROLLBACK;
            RETURN;
      END;

      p_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      P_ERRMSG := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;

/
show error;