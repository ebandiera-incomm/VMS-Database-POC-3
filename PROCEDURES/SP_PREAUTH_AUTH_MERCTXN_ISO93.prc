create or replace PROCEDURE                      vmscms.SP_PREAUTH_AUTH_MERCTXN_ISO93 (P_INST_CODE         IN NUMBER,
                                         P_MSG               IN VARCHAR2,
                                         P_RRN               VARCHAR2,
                                         P_DELIVERY_CHANNEL  VARCHAR2,
                                         P_TERM_ID           VARCHAR2,
                                         P_TXN_CODE          VARCHAR2,
                                         P_TXN_MODE          VARCHAR2,
                                         P_TRAN_DATE         VARCHAR2,
                                         P_TRAN_TIME         VARCHAR2,
                                         P_CARD_NO           VARCHAR2,
                                         P_BANK_CODE         VARCHAR2,
                                         P_TXN_AMT           NUMBER,
                                         P_CURR_CODE         VARCHAR2,
                                         P_PROD_ID           VARCHAR2,
                                         P_CATG_ID           VARCHAR2,
                                         P_TIP_AMT           VARCHAR2,
                                         P_DECLINE_RULEID    VARCHAR2,
                                         P_ATMNAME_LOC       VARCHAR2,
                                         P_MCCCODE_GROUPID   VARCHAR2,
                                         P_CURRCODE_GROUPID  VARCHAR2,
                                         P_TRANSCODE_GROUPID VARCHAR2,
                                         P_RULES             VARCHAR2,
                                         P_CONSODIUM_CODE    IN VARCHAR2,
                                         P_PARTNER_CODE      IN VARCHAR2,
                                         P_EXPRY_DATE        IN VARCHAR2,
                                         P_STAN              IN VARCHAR2,
                                         P_MBR_NUMB          IN VARCHAR2,
                                         P_RVSL_CODE         IN NUMBER,

                                         P_MERC_ID            IN VARCHAR2,
                                         P_COUNTRY_CODE       IN VARCHAR2,
                                         P_NETWORK_ID         IN VARCHAR2,
                                         P_INTERCHANGE_FEEAMT IN NUMBER,
                                         P_MERCHANT_ZIP       IN VARCHAR2,

                                         P_POS_VERFICATION   IN VARCHAR2,
                                         P_INTERNATIONAL_IND IN VARCHAR2,
                                         P_MCC_CODE          IN VARCHAR2,
                                         p_partial_preauth_ind   IN       VARCHAR2, -- Added for OLS
                                         P_ZIP_CODE            IN VARCHAR2, --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
                                         P_ADDRVERIFY_FLAG     IN VARCHAR2, --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
                                         P_NETWORKID_SWITCH    IN VARCHAR2,
                                         P_NETWORKID_ACQUIRER    IN VARCHAR2,
                                         p_network_setl_date    IN  VARCHAR2,

                                         P_MERCHANT_NAME       IN VARCHAR2,
                                         P_MERCHANT_CITY       IN VARCHAR2,

                                         P_CVV_VERIFICATIONTYPE IN  VARCHAR2,
                                         P_PULSE_TRANSACTIONID        IN       VARCHAR2,
                                         P_VISA_TRANSACTIONID          IN       VARCHAR2,
                                         P_MC_TRACEID                 IN       VARCHAR2,
                                         P_CARDVERIFICATION_RESULT      IN       VARCHAR2,
                                         P_AUTH_ID           OUT VARCHAR2,
                                         P_RESP_CODE         OUT VARCHAR2,
                                         P_RESP_MSG          OUT VARCHAR2,
                                         p_ledger_bal         OUT      VARCHAR2,
                                         P_CAPTURE_DATE      OUT DATE,
                                         p_partialauth_amount OUT      VARCHAR2, -- Added for OLS
                                         P_ADDR_VERFY_RESPONSE OUT VARCHAR2 , --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
                                         P_ISO_RESPCDE        OUT VARCHAR2
                                         ,P_MERC_CNTRYCODE     IN       VARCHAR2 DEFAULT NULL
                                          ,P_MS_PYMNT_TYPE      in     varchar2 default null
                                         ,P_MS_PYMNT_DESC      in      varchar2  default null
                                         ,P_cust_addr      IN VARCHAR2   DEFAULT NULL 
                                          --SN Added by Pankaj S. for DB time logging changes                                                                   
                                         ,P_RESP_TIME OUT VARCHAR2
                                          ,P_RESPTIME_DETAIL OUT VARCHAR2
                                          --EN Added by Pankaj S. for DB time logging changes
										   ,p_surchrg_ind   IN VARCHAR2 DEFAULT '2' --Added for VMS-5856
                                           ,p_resp_id       OUT VARCHAR2 --Added for sending to FSS (VMS-8018)
                                         ) IS
  /************************************************************************************************************


      * Created  by       : Abdul Hameed M.A
     * Created  for      : MVHOST 926
     *  Reason           : To support merchadise return and purchase back adjustment transaction
     * Created Date      : 27-MAY-14
     * Reviewer          : spankaj
     * Build Number      : RI0027.0.1.5_B0003(Certification)


      * Modified by         : Abdul Hameed M.A
      * Modified for         :MVHOST 926
      * Modified Reason     : Modified for ols certification  changes
      * Modified Date      : 03-Jun-2014
      * Reviewer             :
      * Reviewed Date      :
      * Build Number         :
     * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 15120
     * Modified Reason   : Balance impact should not be there for the Merchandise Return Preauth
     * Modified Date     : 12-JUNE-14
     * Reviewer          :
     * Reviewed Date     :
     * Build Number      : .

     * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis id:15165
     * Modified Reason   : Address verification should be done for the auth trasnactions
     * Modified Date     : 20-Jun-2014
     * Build Number      : RI0027.2.2_B0001

      * Modified By      : Abdul Hameed M.A
      * Modified Date    : 03-July-2014
      * Modified for     : Mantis ID 15194
      * Modified Reason  : Merchandise return auth transaction fee issues
      * Reviewer         : Spankaj
      * Build Number     : RI0027.2.2_B0002

      * Modified By      : Saravanakumar
     * Modified Date    : 16-Sep-2014
     * Modified for     : Performance changes
     * Reviewer         : spankaj
     * Build Number     : RI0027.4_B0002

      * Modified Date     : 29-SEP-2014
      * Modified By      : Abdul Hameed M.A
      * Modified for     : FWR 70
      * Reviewer         : Spankaj
      * Release Number   : RI0027.4_B0002 

      * Modified Date    : 16-Oct-2014
      * Modified By      : MageshKumar S
      * Modified for     : OLS Perf Improvement
      * Reviewer         : spankaj
      * Release Number   : RI0027.4.3_B0001

      * Modified Date    : 27-Nov-2014
      * Modified By      : MageshKumar S
      * Modified for     : OLS Perf Improvement removal and keeping Duplicate RRN check commented.
      * Reviewer         : spankaj
      * Release Number   : RI0027.4.3_B0007

      * Modified Date    : 30-DEC-2014
      * Modified By      : Dhinakaran B
      * Modified for     : MVHOST-1080/To Log the Merchant id and CountryCode
      * Reviewer         :
      * Reviewed Date    :
      * Release Number   :

      * Modified by      : MAGESHKUMAR S.
      * Modified Date    : 03-FEB-2015
      * Modified For     : FSS-2065 (2.4.2.4.1 and 2.4.3.1 integration)
      * Reviewer         : PANKAJ S.
      * Build Number     : RI0027.5_B0006

      * Modified By      : MageshKumar S
      * Modified Date    : 11-FEB-2015
      * Modified for     : INSTCODE REMOVAL(2.4.2.4.2 and 2.4.3.1 integration)
      * Reviewer         : Spankaj
      * Release Number   : RI0027.5_B0007

       * Modified By      : Abdul Hameed M.A 
     * Modified Date    : 11-FEB-2015
     * Modified for     : OLS AVS Address check and DFCTNM-4
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0007

           * Modified By      : Pankaj S.
     * Modified Date    : 26-Feb-2015
     * Modified For     : 2.4.2.4.4/2.4.3.3 PERF Changes integration
     * Reviewer         : Sarvanankumar
     * Build Number     : RI0027.5_B0009  

         * Modified By      :  Abdul Hameed M.A
     * Modified For     :  Mantis ID-16035
     * Modified Date    :  26-Feb-2015
     * Reviewer         :  Spankaj
     * Build Number     : RI0027.5_B0009   

       * Modified By      :  Abdul Hameed M.A
     * Modified For     :  DFCTNM-4
     * Modified Date    :  1-Mar-2015
     * Reviewer         :  Spankaj
     * Build Number     : RI0027.5_B0011  

      * Modified By      :  Abdul Hameed M.A
     * Modified For     :  OLS AVS CHANGES
     * Modified Date    :  23-Apr-2015
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.5.2_B0001  

     * Modified By      :  Siva Kumar m
     * Modified For     :   MVCSD-5617
     * Modified Date    :  28-May-2015
     * Reviewer         :  Saravana Kumar A
     * Build Number     : VMSGPRHOSTCSD_3.0.3_B0001

     * Modified by      : Pankaj S.
    * Modified for     : Transactionlog Functional Removal Phase-II changes
    * Modified Date    : 11-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOAT_3.1   

    * Modified by      : Ramesh A
    * Modified for     : FSS-3610
    * Modified Date    : 31-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOST_3.1_B0008

    * Modified by      : MageshKumar S
    * Modified for     : GPR Card Status Check Moved to Java
    * Modified Date    : 27-JAN-2016
    * Reviewer         : Saravanankumar/SPankaj
    * Build Number     : VMSGPRHOST_4.0_B0001

	* Modified by      : Narayanaswamy.T
    * Modified for     : FSS-4119 - ATM withdrawal transactions should contain terminal id and city in the statement
    * Modified Date    : 01-Mar-2016
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOST_4.0_B0001

     * Modified Date    : 02-Sep-2016
     * Modified By      : Sivakaminathan
     * Modified for     : MVHOST-1344
     * Reviewer         : Saravanakumar/Spankaj
     * Release Number   : VMSGPRHOSTCSD4.9_B0001


       * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07

    * Modified By      : Vini Pushkaran
    * Modified Date    : 25/10/2017
    * Purpose          : FSS-5303
    * Reviewer         : Saravanakumar A 
    * Release Number   : VMSGPRHOST17.10_B0004 

	* Modified By      : Vini Pushkaran
    * Modified Date    : 24/11/2017
    * Purpose          : VMS-64
    * Reviewer         : Saravanankumar A
    * Release Number   : VMSGPRHOST17.12

       * Modified by       :Vini
       * Modified Date    : 10-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12.1

    * Modified By      : Sreeja D
    * Modified Date    : 19/02/2018
    * Purpose          : 17.12.3/AVS AMEX
    * Reviewer         : Saravanankumar A
    * Release Number   : VMSGPRHOST17.12.3  

     * Modified By      : DHINAKARAN B
     * Modified Date    : 15-NOV-2018
     * Purpose          : VMS-619 (RULE)
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R08 

     * Modified By      : PUVANESH.N
     * Modified Date    : 03-SEP-2021
     * Purpose          : VMS-4652 - Immediate authorization of MoneySend credit transaction
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R51 - BUILD 1 

	 * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 03-MAR-2022
     * Purpose          : VMS-4821 -  MR RETURN TXN SHOULD NOT DECLINE FOR NEGATIVE BAL.
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R59 - BUILD 1 

	* Modified By      : Karthick/Jey
    * Modified Date    : 05-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991

	* Modified By      : Areshka A.
    * Modified Date    : 03-Nov-2023
    * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
    * Reviewer         : 
    * Release Number   : 
	
	* Modified By      : Mohan E.
    * Modified Date    : 27-DEC-2023
    * Purpose          : VMS-8140 - Ph1: Scale Concurrent Pre-Auth Reversals Logic for Redemptions
    * Reviewer         : Pankaj S.
    * Release Number   : R91

  *****************************************************************************************************************/
  V_ERR_MSG            VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE       NUMBER;
  V_LEDGER_BAL         NUMBER;
  V_TRAN_AMT           NUMBER;
  V_AUTH_ID            VARCHAR2(14);
  V_TOTAL_AMT          NUMBER;
  V_TRAN_DATE          DATE;
  V_FUNC_CODE          CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_PROD_CODE          CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE       CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT            NUMBER;
  V_TOTAL_FEE          NUMBER;
  V_UPD_AMT            NUMBER;
  V_UPD_LEDGER_AMT     NUMBER;
  V_NARRATION          VARCHAR2(300);
  V_FEE_OPENING_BAL    NUMBER;
  V_RESP_CDE           VARCHAR2(3);
  V_EXPRY_DATE         DATE;
  V_DR_CR_FLAG         VARCHAR2(2);
  V_OUTPUT_TYPE        VARCHAR2(2);
  V_APPLPAN_CARDSTAT   CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_ATMONLINE_LIMIT    CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT    CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_PRECHECK_FLAG      NUMBER;
  V_PREAUTH_FLAG       NUMBER;
  V_GL_UPD_FLAG        TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_GL_ERR_MSG         VARCHAR2(500);
  V_SAVEPOINT          NUMBER := 0;
  V_TRAN_FEE           NUMBER;
  V_ERROR              VARCHAR2(500);
  V_BUSINESS_DATE_TRAN DATE;
  V_BUSINESS_TIME      VARCHAR2(5);
  V_CUTOFF_TIME        VARCHAR2(5);
  V_CARD_CURR          VARCHAR2(5);
  V_FEE_CODE           CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_CRGL_CATG      CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRGL_CODE      CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRSUBGL_CODE   CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO      CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG      CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE      CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE   CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO      CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  --st AND cess
  V_SERVICETAX_PERCENT CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CESS_PERCENT       CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_SERVICETAX_AMOUNT  NUMBER;
  V_CESS_AMOUNT        NUMBER;
  V_ST_CALC_FLAG       CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
  V_CESS_CALC_FLAG     CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
  V_ST_CRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
  V_ST_DRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
  V_CESS_CRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
  V_CESS_DRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
  --
  V_WAIV_PERCNT      CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  V_ERR_WAIV         VARCHAR2(300);
  V_LOG_ACTUAL_FEE   NUMBER;
  V_LOG_WAIVER_AMT   NUMBER;
  V_AUTH_SAVEPOINT   NUMBER DEFAULT 0;
  V_ACTUAL_EXPRYDATE DATE;
  V_BUSINESS_DATE    DATE;
  V_TXN_TYPE         NUMBER(1);
  V_MINI_TOTREC      NUMBER(2);
  V_MINISTMT_ERRMSG  VARCHAR2(500);
  V_MINISTMT_OUTPUT  VARCHAR2(900);
  EXP_REJECT_RECORD EXCEPTION;
  V_ATM_USAGEAMNT             CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT             CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  V_ATM_USAGELIMIT            CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT            CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_PREAUTH_DATE              DATE;
  V_PREAUTH_HOLD              VARCHAR2(1);
  V_PREAUTH_PERIOD            NUMBER;
  V_PREAUTH_USAGE_LIMIT       NUMBER;
  V_HOLD_AMOUNT               NUMBER ;
  V_HASH_PAN                  CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN                  CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT                 NUMBER;
  V_TRAN_TYPE                 VARCHAR2(2);
  V_DATE                      DATE;
  V_TIME                      VARCHAR2(10);
  V_MAX_CARD_BAL              NUMBER;
  V_CURR_DATE                 DATE;
  V_PREAUTH_EXP_PERIOD        VARCHAR2(10);
  V_PREAUTH_COUNT             NUMBER;
  V_TRANTYPE                  VARCHAR2(2);
  V_ZIP_CODE                  cms_addr_mast.cam_pin_code%type;
  V_ACC_BAL                   VARCHAR2(15);
  V_INTERNATIONAL_IND         CMS_PROD_CATTYPE.CPC_INTERNATIONAL_CHECK%TYPE;
  V_ADDRVRIFY_FLAG            CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_CHECK%TYPE;
  V_ENCRYPT_ENABLE            CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  V_ADDRVERIFY_RESP           CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_RESPONSE%TYPE;
  V_PROXUNUMBER               CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER               CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_TRANS_DESC                VARCHAR2(50);
  V_AUTH_ID_GEN_FLAG          VARCHAR2(1);
  V_STATUS_CHK                NUMBER;
  V_TRAN_PREAUTH_FLAG         CMS_TRANSACTION_MAST.CTM_PREAUTH_FLAG%TYPE;
  V_PRODUCT_PREAUTH_EXPPERIOD VARCHAR2(15);

  V_HOLD_DAYS   CMS_TXNCODE_RULE.CTR_HOLD_DAYS%TYPE;
  P_HOLD_AMOUNT NUMBER;

VT_PREAUTH_HOLD        VARCHAR2(1);
VT_PREAUTH_PERIOD      NUMBER;
vp_preauth_exp_period cms_prod_mast.cpm_pre_auth_exp_date%TYPE ;
VP_PREAUTH_HOLD        VARCHAR2(1);
VP_PREAUTH_PERIOD      NUMBER;
vi_preauth_exp_period  cms_inst_param.cip_param_value%TYPE ;
VI_PREAUTH_HOLD        VARCHAR2(1);
VI_PREAUTH_PERIOD      NUMBER;

  --Added by Deepa On June 19 2012 for Fees Changes
  V_FEEAMNT_TYPE CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES     CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES    CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK     CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN     CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_FREETXN_EXCEED VARCHAR2(1);
  V_DURATION VARCHAR2(20); -- Added  for logging fee of free transactions
  V_FEEATTACH_TYPE  VARCHAR2(2);

  v_acct_type   cms_acct_mast.cam_type_code%TYPE;
  v_timestamp   timestamp(3);

  v_partial_appr                VARCHAR2 (1); --  Added for OLS  changes
   v_cms_iso_respcde             cms_response_mast.cms_iso_respcde%TYPE; --  Added for OLS  changes
   v_txn_nonnumeric_chk    VARCHAR2 (2);  --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
   v_cust_nonnumeric_chk   VARCHAR2 (2);  --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
   v_removespace_txn       VARCHAR2 (10); --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
   v_removespace_cust      VARCHAR2 (10); --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
   v_first3_custzip         cms_addr_mast.cam_pin_code%type; --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
   v_inputzip_length        number(3); --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
   v_numeric_zip            cms_addr_mast.cam_pin_code%type; --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
   v_cap_cust_code          cms_appl_pan.cap_cust_code%type; --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
   V_STAN_COUNT                  NUMBER; -- Added for Duplicate Stan check 0012198


   v_prfl_flag             cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_prfl_code             cms_appl_pan.cap_prfl_code%TYPE;
   v_comb_hash             pkg_limits_check.type_hash;

   V_TRAN_AMT_NOHOLD           NUMBER;
   V_ADJUSTMENT_FLAG        CMS_TRANSACTION_MAST.CTM_ADJUSTMENT_FLAG%TYPE;
   V_PREAUTH_TYPE           CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
    v_zip_code_trimmed VARCHAR2(10);--Added for 15165
    V_FEE_DESC         cms_fee_mast.cfm_fee_desc%TYPE;  -- Added for MVCSD-4471
--SN Added for FWR 70
   v_removespacenum_txn  VARCHAR2 (10);
V_REMOVESPACENUM_CUST   VARCHAR2 (10);
V_REMOVESPACECHAR_TXN   varchar2 (10);
V_REMOVESPACECHAR_CUST   VARCHAR2 (10);
--EN Added for FWR 70
V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%type; 
V_ADDR_ONE CMS_ADDR_MAST.CAM_ADD_ONE%type;
  V_ADDR_TWO CMS_ADDR_MAST.CAM_ADD_TWO%type;
  V_REMOVESPACE_ADDRCUST     VARCHAR2(100);
  V_REMOVESPACE_ADDRTXN      VARCHAR2(20);
  V_REMOVESPACECHAR_ADDRCUST VARCHAR2(100);
  V_REMOVESPACECHAR_ADDRTXN  VARCHAR2(20);
  V_ADDR_VERFY               number;
  V_REMOVESPACECHAR_ADDRONECUST   VARCHAR2(100);
   --SN Added by Pankaj S. for DB time logging changes
 v_start_time timestamp;
 v_mili VARCHAR2(100);
 --EN Added by Pankaj S. for DB time logging changes
  V_MS_PYMNT_TYPE CMS_PAYMENT_TYPE.cpt_payment_type%type;
  v_alpha_cntry_code gen_cntry_mast.gcm_alpha_cntry_code%TYPE;
  V_PARAM_VALUE           	CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_PREAUTH_CR_RELEASE_HRS	CMS_PROD_CATTYPE.CPC_PREAUTH_CR_RELEASE_HRS%TYPE;
  V_UPD_MONEY_SEND_FLAG		VARCHAR2(10);

  v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE := '1';
  P_RESP_MSG := 'OK';
  V_TRAN_AMT := P_TXN_AMT;
  V_PARTIAL_APPR := 'N';
 v_timestamp:=systimestamp;
   v_start_time := systimestamp;   --Added by Pankaj S. for DB time logging changes
 V_MS_PYMNT_TYPE:=P_MS_PYMNT_TYPE;
 V_UPD_MONEY_SEND_FLAG := 'N';
  begin
    --SN CREATE HASH PAN
    BEGIN
     V_HASH_PAN := GETHASH(P_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --EN CREATE HASH PAN

    --SN create encr pan
    BEGIN
     V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --EN create encr pan
     --Start Generate HashKEY value for JH-10
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_CARD_NO||P_RRN||to_char(V_TIMESTAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        V_RESP_CDE := '21';
        V_ERR_MSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     end;
   --End Generate HashKEY value for JH-10

    --Commended by saravanakumar on 16-Sep-2014
    --Sn find narration
    /*BEGIN
     SELECT CTM_TRAN_DESC
       INTO V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_TRANS_DESC := 'Transaction type ' || P_TXN_CODE;
     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error in finding the narration ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;*/


--Sn find card detail
    BEGIN
     SELECT CAP_PROD_CODE,
           CAP_CARD_TYPE,
           CAP_EXPRY_DATE,
           CAP_CARD_STAT,
           CAP_ATM_ONLINE_LIMIT,
           CAP_POS_ONLINE_LIMIT,
           CAP_PROXY_NUMBER,
           CAP_ACCT_NO,
           CAP_CUST_CODE ,
           cap_prfl_code  --Added for enabling limit validation
       INTO V_PROD_CODE,
           V_PROD_CATTYPE,
           V_EXPRY_DATE,
           V_APPLPAN_CARDSTAT,
           V_ATMONLINE_LIMIT,
           V_ATMONLINE_LIMIT,
           V_PROXUNUMBER,
           V_ACCT_NUMBER,
           V_CAP_CUST_CODE,
           v_prfl_code  --Added  for enabling limit validation
       FROM CMS_APPL_PAN
      WHERE CAP_PAN_CODE = V_HASH_PAN;
      --AND CAP_INST_CODE = P_INST_CODE; --For Instcode removal of 2.4.2.4.2 release
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14';
       V_ERR_MSG  := 'CARD NOT FOUND ' || V_HASH_PAN;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Problem while selecting card detail' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En find card detail

    --Sn generate auth id
    BEGIN


     SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

     V_AUTH_ID_GEN_FLAG := 'Y';
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Error while generating authid ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21'; -- Server Declined
       RAISE EXP_REJECT_RECORD;
    END;

    --En generate auth id

    --Commended by saravanakumar on 16-Sep-2014
    --SN CHECK INST CODE
   /* BEGIN
     IF P_INST_CODE IS NULL THEN
       V_RESP_CDE := '12'; -- Invalid Transaction
       V_ERR_MSG  := 'Institute code cannot be null ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '12'; -- Invalid Transaction
       V_ERR_MSG  := 'Institute code cannot be null ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;*/

    --eN CHECK INST CODE

    --En check txn currency
    BEGIN
     V_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '45'; -- Server Declined -220509
       V_ERR_MSG  := 'Problem while converting transaction date ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
     V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                        SUBSTR(TRIM(P_TRAN_TIME), 1, 10),
                        'yyyymmdd hh24:mi:ss');
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '32'; -- Server Declined -220509
       V_ERR_MSG  := 'Problem while converting transaction time ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;

    --Sn find debit and credit flag
    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,
           CTM_PREAUTH_FLAG,
           ctm_prfl_flag
            ,CTM_ADJUSTMENT_FLAG,
            ctm_preauth_type,
            CTM_TRAN_DESC --Added by saravanakumar on 16-Sep-2014
       INTO V_DR_CR_FLAG,
           V_OUTPUT_TYPE,
           V_TXN_TYPE,
           V_TRAN_TYPE,
           V_TRAN_PREAUTH_FLAG,
           v_prfl_flag
           ,V_ADJUSTMENT_FLAG,
           V_PREAUTH_TYPE,
           V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '12'; --Ineligible Transaction
       V_ERR_MSG  := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                  ' and delivery channel ' || P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12'; --Ineligible Transaction
       V_ERR_MSG  := 'Error while selecting  CMS_TRANSACTION_MAST' ||
                  SUBSTR(SQLERRM, 1, 200) || P_TXN_CODE ||
                  ' and delivery channel ' || P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
    END;

    --En find debit and credit flag
--   if V_MS_PYMNT_TYPE is not null then
   --V_TRANS_DESC:='MoneySend'||' '||V_TRANS_DESC;

   if V_MS_PYMNT_TYPE='P' then
   V_MS_PYMNT_TYPE:=null;
   end if;

 --  end if;


      --SN added for VMS_8140 

        BEGIN
          SP_AUTONOMOUS_PREAUTH_LOG(V_AUTH_ID, P_STAN, P_TRAN_DATE,
                V_HASH_PAN,  P_INST_CODE, P_DELIVERY_CHANNEL , V_ERR_MSG);

               IF V_ERR_MSG != 'OK' THEN
               V_RESP_CDE     := '191';
               RAISE EXP_REJECT_RECORD;
               END IF;
        EXCEPTION
          When EXP_REJECT_RECORD Then
          raise;
          When others then
              V_RESP_CDE       := '12';
              V_ERR_MSG         := 'Concurrent check Failed' || SUBSTR(SQLERRM, 1, 200);

              RAISE EXP_REJECT_RECORD;
        END;          
   --EN added for VMS_8140 


/*
      -----------------------------------------
      --SN: Added for Duplicate STAN check 0012198
      -----------------------------------------

      BEGIN

        SELECT COUNT(1)
         INTO V_STAN_COUNT
         FROM TRANSACTIONLOG
        WHERE INSTCODE = P_INST_CODE
        and   CUSTOMER_CARD_NO  = V_HASH_PAN
        AND   BUSINESS_DATE = P_TRAN_DATE
        AND   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND   SYSTEM_TRACE_AUDIT_NO = P_STAN;

        IF V_STAN_COUNT > 0 THEN

         V_RESP_CDE := '191';
         V_ERR_MSG   := 'Duplicate Stan from the Treminal' || P_TERM_ID || 'on' ||
                    P_TRAN_DATE;
         RAISE EXP_REJECT_RECORD;

        END IF;


      EXCEPTION WHEN EXP_REJECT_RECORD
      THEN
            RAISE EXP_REJECT_RECORD;

      WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while checking duplicate STAN ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;

      END;

      -----------------------------------------
      --SN: Added for Duplicate STAN check 0012198
      -----------------------------------------
*/

    --Sn Duplicate RRN Check
  /*  BEGIN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND --Changed for admin dr cr.
           BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERR_MSG  := 'Duplicate RRN from the Terminal' || P_TERM_ID || 'on' ||
                  P_TRAN_DATE;
       RAISE EXP_REJECT_RECORD;
     END IF;
     EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
     RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting RRN ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;
    END; */ -- commented for OLS Perf Improvement

    --En get date


/*
    --Sn Getting BIN Level Configuration details

    BEGIN

     SELECT CBL_INTERNATIONAL_CHECK --, CBL_ADDR_VER_CHECK
       INTO V_INTERNATIONAL_IND --, V_ADDRVRIFY_FLAG
       FROM CMS_BIN_LEVEL_CONFIG
      WHERE CBL_INST_BIN = SUBSTR(P_CARD_NO, 1, 6) AND
           CBL_INST_CODE = P_INST_CODE;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN

       V_INTERNATIONAL_IND := 'Y';
    --   V_ADDRVRIFY_FLAG    := 'Y';

     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting BIN level Configuration' || SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;

    END;

    --En Getting BIN Level Configuration details
*/
	BEGIN

     SELECT  CPC_ADDR_VERIFICATION_CHECK, CPC_INTERNATIONAL_CHECK, CPC_ENCRYPT_ENABLE,NVL(CPC_ADDR_VERIFICATION_RESPONSE, 'U'),NVL(CPC_PREAUTH_CR_RELEASE_HRS,24)
       INTO  V_ADDRVRIFY_FLAG, V_INTERNATIONAL_IND, V_ENCRYPT_ENABLE, V_ADDRVERIFY_RESP,V_PREAUTH_CR_RELEASE_HRS
       FROM CMS_PROD_CATTYPE
      WHERE CPC_INST_CODE = P_INST_CODE AND
            CPC_PROD_CODE = V_PROD_CODE AND
            CPC_CARD_TYPE =  V_PROD_CATTYPE;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN

       V_ADDRVRIFY_FLAG    := 'Y';
       V_INTERNATIONAL_IND := 'Y';
     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting Product Category level Configuration' || SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;

    END;  


    --Sn find service tax
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_SERVICETAX_PERCENT
       FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'SERVICETAX' AND CIP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Service Tax is  not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting service tax from system ';
       RAISE EXP_REJECT_RECORD;
    END;

    --En find service tax

    --Sn find cess
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_CESS_PERCENT
       FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'CESS' AND CIP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Cess is not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting cess from system ';
       RAISE EXP_REJECT_RECORD;
    END;

    --En find cess

    ---Sn find cutoff time
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_CUTOFF_TIME
       FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'CUTOFF' AND CIP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_CUTOFF_TIME := 0;
       V_RESP_CDE    := '21';
       V_ERR_MSG     := 'Cutoff time is not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting cutoff  dtl  from system ';
       RAISE EXP_REJECT_RECORD;
    END;

    ---En find cutoff time
    --Commented as per review comments

   /*  BEGIN          -- Query added for OLS changes

         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                cam_type_code ,CAM_ACCT_NO
           INTO V_ACCT_BALANCE, V_LEDGER_BAL,
                v_acct_type ,V_ACCT_NUMBER
           FROM CMS_ACCT_MAST
          WHERE CAM_ACCT_NO =
               (SELECT CAP_ACCT_NO
                 FROM CMS_APPL_PAN
                WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                     CAP_INST_CODE = P_INST_CODE) AND
               CAM_INST_CODE = P_INST_CODE
               for update;

              v_acc_bal := V_ACCT_BALANCE;
     EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '14'; --Ineligible Transaction
           V_ERR_MSG  := 'Invalid Card ';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                      SQLERRM;
           RAISE EXP_REJECT_RECORD;
     END; */                          -- Query added for OLS changes

    --Sn find the tran amt
    IF ((V_TRAN_TYPE = 'F') OR (V_TRAN_PREAUTH_FLAG = 'Y')) THEN
     IF (P_TXN_AMT >= 0) THEN


       BEGIN
        SP_CONVERT_CURR(P_INST_CODE,
                     P_CURR_CODE,
                     P_CARD_NO,
                     P_TXN_AMT,
                     V_TRAN_DATE,
                     V_TRAN_AMT,
                     V_CARD_CURR,
                     V_ERR_MSG,
                     V_PROD_CODE,
                     V_PROD_CATTYPE);

        IF V_ERR_MSG <> 'OK' THEN
          V_RESP_CDE := '44';
          V_ERR_MSG  := 'ERROR WHILE EXECUTING CONVERT CURRENCY';
          RAISE EXP_REJECT_RECORD;
        END IF;




       EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          V_RESP_CDE := '44';
          V_ERR_MSG  := 'ERROR WHILE CALLING CONVERT CURRENCY';
          RAISE EXP_REJECT_RECORD;
       END;
     ELSE
       -- If transaction Amount is zero - Invalid Amount -220509
       V_RESP_CDE := '43';
       V_ERR_MSG  := 'INVALID AMOUNT';
       RAISE EXP_REJECT_RECORD;
     END IF;
    END IF;

    --En find the tran amt

    --Sn select authorization processe flag
    BEGIN
     SELECT PTP_PARAM_VALUE
       INTO V_PRECHECK_FLAG
       FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE CHECK' AND PTP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21'; --only for master setups
       V_ERR_MSG  := 'Master set up is not done for Authorization Process';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; --only for master setups
       V_ERR_MSG  := 'Error while selecting precheck flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En select authorization process   flag
    --Sn select authorization processe flag
    BEGIN
     SELECT PTP_PARAM_VALUE
       INTO V_PREAUTH_FLAG
       FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE AUTH' AND PTP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Master set up is not done for Authorization Process';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting PCMS_TRANAUTH_PARAM' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En select authorization process   flag



     --Sn Internation Flag check
    IF P_INTERNATIONAL_IND = '1' AND V_INTERNATIONAL_IND <> 'Y'  THEN

       V_RESP_CDE := '38';
       V_ERR_MSG  := 'INTERNATIONAL TRANSACTION NOT SUPPORTED';
       RAISE EXP_REJECT_RECORD;
    END IF;
    --End Sn Internation Flag check

           v_zip_code_trimmed:=TRIM(P_ZIP_CODE);--Added for 15165
    --St: Added for OLS  changes( AVS and ZIP validation changes)
        IF V_ADDRVRIFY_FLAG = 'Y' AND P_ADDRVERIFY_FLAG in('2','3') then

              if P_ZIP_CODE is null then --tag not present

               V_RESP_CDE := '105';
               V_ERR_MSG  := 'Required Property Not Present : ZIP';
               RAISE EXP_REJECT_RECORD;

            ELSIF trim(P_ZIP_CODE) is null then   --tag present but value empty or space

               P_ADDR_VERFY_RESPONSE := 'U';

        ELSE

           BEGIN

				 SELECT decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(CAM_PIN_CODE),CAM_PIN_CODE),
						trim(decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_one),cam_add_one)),
						trim(decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_two),cam_add_two))
				 INTO V_ZIP_CODE,
					  v_addr_one,
					  v_addr_two
				 FROM CMS_ADDR_MAST
				 WHERE CAM_CUST_CODE = V_CAP_CUST_CODE
				 AND CAM_ADDR_FLAG = 'P';

                   v_first3_custzip := SUBSTR(V_ZIP_CODE,1,3);

             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   V_RESP_CDE := '21';
                   V_ERR_MSG  := 'No data found in CMS_ADDR_MAST ' || V_HASH_PAN;
                   RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
                   V_RESP_CDE := '21';
                   V_ERR_MSG  := 'Error while seelcting CMS_ADDR_MAST ' ||SUBSTR(SQLERRM, 1, 200);
                   RAISE EXP_REJECT_RECORD;
             END;

             SELECT REGEXP_instr(p_zip_code,'([A-Z,a-z])') into v_txn_nonnumeric_chk
             FROM dual;

             SELECT REGEXP_instr(V_ZIP_CODE,'([A-Z,a-z])') into v_cust_nonnumeric_chk
             FROM dual;

                if  v_txn_nonnumeric_chk = '0' and v_cust_nonnumeric_chk = '0' then -- It Means txn and cust zip code is numeric


                    --IF SUBSTR (p_zip_code, 1, 5) = SUBSTR (v_zip_code, 1, 5) then
                    --Modified for 15165

                  IF SUBSTR (v_zip_code_trimmed, 1, 5) = SUBSTR (v_zip_code, 1, 5) then
                 P_ADDR_VERFY_RESPONSE := 'W';
                    else
                           P_ADDR_VERFY_RESPONSE := 'N';
                    end if;


                elsif v_txn_nonnumeric_chk <> '0' and v_cust_nonnumeric_chk = '0' then -- It Means txn zip code is aplhanumeric and cust zip code is numeric

                   -- if  p_zip_code = v_zip_code then
                      IF v_zip_code_trimmed=v_zip_code THEN   --Modified for 15165
                P_ADDR_VERFY_RESPONSE := 'W';
                    else
                          P_ADDR_VERFY_RESPONSE := 'N';
                    end if;

                elsif v_txn_nonnumeric_chk = '0' and v_cust_nonnumeric_chk <> '0' then -- It Means txn zip code is numeric and cust zip code is alphanumeric

                    SELECT REGEXP_REPLACE(v_zip_code,'([A-Z ,a-z ])', '') into v_numeric_zip FROM dual;

                  --  if  p_zip_code = v_numeric_zip then
                     IF v_zip_code_trimmed=v_numeric_zip THEN   --Modified for 15165

                P_ADDR_VERFY_RESPONSE := 'W';
                    else
                          P_ADDR_VERFY_RESPONSE := 'N';

                    end if;

                elsif v_txn_nonnumeric_chk <> '0' and v_cust_nonnumeric_chk <> '0' then -- It Means txn zip code and cust zip code is alphanumeric

                     v_inputzip_length := length(p_zip_code);

                     IF v_inputzip_length = LENGTH(v_zip_code) THEN  -- both txn and cust zip length is equal

                      --   if  p_zip_code = v_zip_code then
                      IF v_zip_code_trimmed=v_zip_code THEN   --Modified for 15165

                           P_ADDR_VERFY_RESPONSE := 'W';
                           else
                                 P_ADDR_VERFY_RESPONSE := 'N';

                           end if;

                      else

                 SELECT REGEXP_REPLACE(p_zip_code,'([ ])', '') into v_removespace_txn from dual;
                            SELECT REGEXP_REPLACE(v_zip_code,'([ ])', '') into v_removespace_cust from dual;

                            if v_removespace_txn =  v_removespace_cust then

                                   P_ADDR_VERFY_RESPONSE := 'W';


                  elsif length(v_removespace_txn) >=3 then


                  if substr(v_removespace_txn,1,3) = substr(v_removespace_cust,1,3) then

                     P_ADDR_VERFY_RESPONSE := 'W';

                      ---SN Added for FWR 70
                            ELSIF v_inputzip_length >= 6
                        THEN                         --Added for defect : 13297 on 26/12/13

                         select REGEXP_REPLACE (P_ZIP_CODE, '([0-9 ])', '')
                          INTO v_removespacenum_txn
                          FROM DUAL;

                        select REGEXP_REPLACE (V_ZIP_CODE, '([0-9 ])', '')
                          into V_REMOVESPACENUM_CUST
                          FROM DUAL;

                           select REGEXP_REPLACE (P_ZIP_CODE, '([a-zA-Z ])', '')
                          INTO v_removespacechar_txn
                          FROM DUAL;

                        select REGEXP_REPLACE (V_ZIP_CODE, '([a-zA-Z ])', '')
                          into V_REMOVESPACECHAR_CUST
                          FROM DUAL;
                            --if substr(p_zip_code,1,3) = v_first3_custzip then  --Commented for defect : 13297 on 26/12/13
                            IF SUBSTR (v_removespacenum_txn, 1, 3) =
                                    SUBSTR (V_REMOVESPACENUM_CUST, 1, 3)
                            then                     --Added for defect : 13297 on 26/12/13
                                P_ADDR_VERFY_RESPONSE := 'W';
                            ELSIF  SUBSTR (V_REMOVESPACECHAR_TXN, 1, 3) =
                                    SUBSTR (V_REMOVESPACECHAR_CUST, 1, 3)
                                    then
                                    P_ADDR_VERFY_RESPONSE := 'W';
                            ELSE
                                P_ADDR_VERFY_RESPONSE := 'N';
                            end if;
                            --en --Added for FWR 70
                 else
                          P_ADDR_VERFY_RESPONSE := 'N';

                 end if;


                  else
                  P_ADDR_VERFY_RESPONSE := 'N';

                          end if;
                     end if;
       else
             P_ADDR_VERFY_RESPONSE := 'N';
      end if;

      end if;

    ELSE

         IF P_ADDRVERIFY_FLAG in('2','3') THEN

           P_ADDR_VERFY_RESPONSE := V_ADDRVERIFY_RESP;

         ELSE

           P_ADDR_VERFY_RESPONSE := 'NA';

         END IF;

        END IF;

        --END Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013.

 select REGEXP_REPLACE (v_addr_one||v_addr_TWO,'[^[:digit:]]')
           INTO v_removespacechar_addrcust
          FROM DUAL;


        select REGEXP_REPLACE (V_ADDR_ONE,'[^[:digit:]]')
           into V_REMOVESPACECHAR_ADDRONECUST
          FROM DUAL;


        select REGEXP_REPLACE (P_CUST_ADDR,'[^[:digit:]]')
             INTO V_REMOVESPACECHAR_ADDRTXN
             from DUAL;

          SELECT REGEXP_REPLACE (P_CUST_ADDR, '([ ])', '')
           INTO V_REMOVESPACE_addrtxn
           from DUAL;

          SELECT REGEXP_REPLACE (v_addr_one||v_addr_TWO, '([ ])', '')
           INTO V_REMOVESPACE_addrcust
           from DUAL;
     IF V_ADDRVRIFY_FLAG = 'Y'  then      
    if(P_ADDR_VERFY_RESPONSE  ='W') then

       if(V_REMOVESPACE_ADDRCUST is not null) then

     if(V_REMOVESPACE_ADDRCUST=SUBSTR(V_REMOVESPACE_ADDRTXN,1,length(V_REMOVESPACE_ADDRCUST))) then
     V_ADDR_VERFY:=1;
      elsif(V_REMOVESPACECHAR_ADDRCUST=V_REMOVESPACECHAR_ADDRTXN) then
        V_ADDR_VERFY:=1;
      ELSIF(V_REMOVESPACECHAR_ADDRONECUST=V_REMOVESPACECHAR_ADDRTXN) then
        V_ADDR_VERFY:=1;
        else
        V_ADDR_VERFY:=-1;
        end if;


        IF(V_ADDR_VERFY          =1) THEN
          P_ADDR_VERFY_RESPONSE := 'Y';
        ELSE
          P_ADDR_VERFY_RESPONSE := 'Z';
        END IF;
      ELSE
        P_ADDR_VERFY_RESPONSE := 'Z';
      end if;
    END IF;
     if (UPPER (TRIM(p_networkid_switch)) = 'BANKNET' and P_ADDR_VERFY_RESPONSE = 'Y') then
          P_ADDR_VERFY_RESPONSE := 'Z';
      end if;
      end if;
    --- st Expiry date validation for ols changes
     BEGIN
     IF P_EXPRY_DATE <> TO_CHAR(V_EXPRY_DATE, 'YYMM') THEN
        --V_RESP_CDE := '13';   commented -- mvcsd-5617 
       --- V_ERR_MSG  := 'EXPIRY DATE NOT EQUAL TO APPL EXPRY DATE ';
        V_RESP_CDE := '905';
        V_ERR_MSG  := 'Expiry Date not Matched';
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'ERROR IN EXPIRY DATE CHECK ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

    --- end Expiry date validation for ols changes

    --Sn GPR Card status check
 /*   BEGIN
     SP_STATUS_CHECK_GPR(P_INST_CODE,
                     P_CARD_NO,
                     P_DELIVERY_CHANNEL,
                     V_EXPRY_DATE,
                     V_APPLPAN_CARDSTAT,
                     P_TXN_CODE,
                     P_TXN_MODE,
                     V_PROD_CODE,
                     V_PROD_CATTYPE,
                     P_MSG,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     P_INTERNATIONAL_IND,
                     P_POS_VERFICATION,
                     P_MCC_CODE,
                     V_RESP_CDE,
                     V_ERR_MSG);

     IF ((V_RESP_CDE <> '1' AND V_ERR_MSG <> 'OK') OR
        (V_RESP_CDE <> '0' AND V_ERR_MSG <> 'OK')) THEN
       RAISE EXP_REJECT_RECORD;
     ELSE
       V_STATUS_CHK := V_RESP_CDE;
       V_RESP_CDE   := '1';
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error from GPR Card Status Check ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En GPR Card status check

    IF V_STATUS_CHK = '1' THEN
     -- Expiry Check
     BEGIN
       IF TO_DATE(P_TRAN_DATE, 'YYYYMMDD') >
         LAST_DAY(TO_CHAR(V_EXPRY_DATE, 'DD-MON-YY')) THEN
        V_RESP_CDE := '13';
        V_ERR_MSG  := 'EXPIRED CARD';
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'ERROR IN EXPIRY DATE CHECK ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;*/

     -- End Expiry Check

     --Sn check for precheck
     IF V_PRECHECK_FLAG = 1 THEN
       BEGIN
        SP_PRECHECK_TXN(P_INST_CODE,
                     P_CARD_NO,
                     P_DELIVERY_CHANNEL,
                     V_EXPRY_DATE,
                     V_APPLPAN_CARDSTAT,
                     P_TXN_CODE,
                     P_TXN_MODE,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_TRAN_AMT,
                     V_ATMONLINE_LIMIT,
                     V_POSONLINE_LIMIT,
                     V_RESP_CDE,
                     V_ERR_MSG);

        IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
          RAISE EXP_REJECT_RECORD;
        END IF;
       EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
          V_RESP_CDE := '21';
          V_ERR_MSG  := 'Error from precheck processes ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
       END;
     END IF;

     --En check for Precheck

  --  END IF;

 IF V_PREAUTH_FLAG = 1 THEN
     BEGIN
          BEGIN 
          select gcm_alpha_cntry_code  
          INTO  v_alpha_cntry_code  
          from gen_cntry_mast
          WHERE gcm_curr_code= P_COUNTRY_CODE  AND GCM_INST_CODE=1;
          EXCEPTION 
          WHEN OTHERS THEN 
            v_alpha_cntry_code:=null;
          END;
       /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
       SP_ELAN_PREAUTHORIZE_TXN(P_CARD_NO,
                           P_MCC_CODE,  --Added by Pankaj S. for Mantis ID 11447
                           P_CURR_CODE,
                           V_TRAN_DATE,
                           P_TXN_CODE,
                           P_INST_CODE,
                           P_TRAN_DATE,
                           V_TRAN_AMT,
                           P_DELIVERY_CHANNEL,
                           P_MERC_ID,
                           P_MERC_CNTRYCODE,
                           P_HOLD_AMOUNT,
                           V_HOLD_DAYS,
                           V_RESP_CDE,
                           V_ERR_MSG,
                           v_alpha_cntry_code);

       IF (V_RESP_CDE <> '1' OR TRIM(V_ERR_MSG) <> 'OK') THEN
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Error from pre_auth process ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    END IF;
 --SN -- Commeneted for FWR-48
    --Sn find function code attached to txn code
    /*BEGIN
     SELECT CFM_FUNC_CODE
       INTO V_FUNC_CODE
       FROM CMS_FUNC_MAST
      WHERE CFM_TXN_CODE = P_TXN_CODE AND CFM_TXN_MODE = P_TXN_MODE AND
           CFM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CFM_INST_CODE = P_INST_CODE;
     --TXN mode and delivery channel we need to attach
     --bkz txn code may be same for all type of channels
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '69'; --Ineligible Transaction
       V_ERR_MSG  := 'Function code not defined for txn code ' ||
                  P_TXN_CODE;
       RAISE EXP_REJECT_RECORD;
     WHEN TOO_MANY_ROWS THEN
       V_RESP_CDE := '69';
       V_ERR_MSG  := 'More than one function defined for txn code ' ||
                  P_TXN_CODE;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '69';
       V_ERR_MSG  := 'Error while selecting CMS_FUNC_MAST' ||
                  SUBSTR(SQLERRM, 1, 200) || P_TXN_CODE;
       RAISE EXP_REJECT_RECORD;
    END;*/
     --EN -- Commeneted for FWR-48

    --En find function code attached to txn code
    --Sn find prod code and card type and available balance for the card number
    BEGIN
    SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,cam_type_code--Modified as per review comments
     INTO V_ACCT_BALANCE, V_LEDGER_BAL,v_acct_type
     FROM CMS_ACCT_MAST
    WHERE  CAM_INST_CODE = P_INST_CODE
        AND CAM_ACCT_NO =  V_ACCT_NUMBER
      FOR UPDATE ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '14';
   --  V_ERRMSG   := 'Invalid Card ';
    V_ERR_MSG   := 'Invalid Account No ';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '12';
     V_ERR_MSG   := 'Error while selecting data from card Master for card number ';
     RAISE EXP_REJECT_RECORD;
  END;

    --En find prod code and card type for the card number

    --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

    P_RESPTIME_DETAIL := '1: ' || v_mili ;
    --EN Added by Pankaj S. for DB time logging changes

    --En Check PreAuth Completion txn

     --added for FSS-Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy on 24-Jun-2013 by Arunprasath
        --Sn Duplicate RRN Check
  /*  BEGIN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND --Changed for admin dr cr.
           BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERR_MSG  := 'Duplicate RRN from the Terminal' || P_TERM_ID || 'on' ||
                  P_TRAN_DATE;
       RAISE EXP_REJECT_RECORD;
     END IF;
     EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
     RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting RRN ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;
    END; */  -- commented for OLS Perf Improvement
    --En Duplicate RRN Check

    ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------
      IF P_MSG NOT IN ('1200' ,'1120') THEN  --Added by Pankaj S. for PERF changes 
      BEGIN

		--Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');

	  IF (v_Retdate>v_Retperiod)  THEN                                                 --Added for VMS-5739/FSP-991

        SELECT COUNT(1)
         INTO V_STAN_COUNT
         FROM TRANSACTIONLOG
        WHERE --INSTCODE = P_INST_CODE and    --For Instcode removal of 2.4.2.4.2 release
        CUSTOMER_CARD_NO  = V_HASH_PAN
        AND   BUSINESS_DATE = P_TRAN_DATE
        AND   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND   ADD_INS_DATE BETWEEN TRUNC(SYSDATE-1)  AND SYSDATE
        AND   SYSTEM_TRACE_AUDIT_NO = P_STAN;

	   ELSE

	    SELECT COUNT(1)
         INTO V_STAN_COUNT
         FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                   --Added for VMS-5739/FSP-991
        WHERE --INSTCODE = P_INST_CODE and    --For Instcode removal of 2.4.2.4.2 release
        CUSTOMER_CARD_NO  = V_HASH_PAN
        AND   BUSINESS_DATE = P_TRAN_DATE
        AND   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND   ADD_INS_DATE BETWEEN TRUNC(SYSDATE-1)  AND SYSDATE
        AND   SYSTEM_TRACE_AUDIT_NO = P_STAN;

	   END IF;

        IF V_STAN_COUNT > 0 THEN

         V_RESP_CDE := '191';
         V_ERR_MSG   := 'Duplicate Stan from the Treminal' || P_TERM_ID || 'on' ||
                    P_TRAN_DATE;
         RAISE EXP_REJECT_RECORD;

        END IF;


      EXCEPTION WHEN EXP_REJECT_RECORD
      THEN
            RAISE EXP_REJECT_RECORD;

      WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while checking duplicate STAN ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;

      END; 
      END IF; --Added by Pankaj S. for PERF changes 

    ------------------------------------------------------
        --En Added for Concurrent Processsing Issue
    ------------------------------------------------------
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

     P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 2: ' || v_mili ;
     --EN Added by Pankaj S. for DB time logging changes

    BEGIN
     SP_TRAN_FEES_CMSAUTH(P_INST_CODE,
                      P_CARD_NO,
                      P_DELIVERY_CHANNEL,
                      V_TXN_TYPE,
                      P_TXN_MODE,
                      P_TXN_CODE,
                      P_CURR_CODE,
                      P_CONSODIUM_CODE,
                      P_PARTNER_CODE,
                      V_TRAN_AMT,
                      V_TRAN_DATE,
                      P_INTERNATIONAL_IND, --Added  for Fees Changes
                      P_POS_VERFICATION, --Added for Fees Changes
                      V_RESP_CDE, --Added  for Fees Changes
                      P_MSG, --Added for Fees Changes
                      P_RVSL_CODE, --Added  for Reversal txn Fee
                     P_MCC_CODE,
                      V_FEE_AMT,
                      V_ERROR,
                      V_FEE_CODE,
                      V_FEE_CRGL_CATG,
                      V_FEE_CRGL_CODE,
                      V_FEE_CRSUBGL_CODE,
                      V_FEE_CRACCT_NO,
                      V_FEE_DRGL_CATG,
                      V_FEE_DRGL_CODE,
                      V_FEE_DRSUBGL_CODE,
                      V_FEE_DRACCT_NO,
                      V_ST_CALC_FLAG,
                      V_CESS_CALC_FLAG,
                      V_ST_CRACCT_NO,
                      V_ST_DRACCT_NO,
                      V_CESS_CRACCT_NO,
                      V_CESS_DRACCT_NO,
                      V_FEEAMNT_TYPE, --Added  for Fees Changes
                      V_CLAWBACK, --Added  for Fees Changes
                      V_FEE_PLAN, --Added  for Fees Changes
                      V_PER_FEES, --Added  for Fees Changes
                      V_FLAT_FEES, --Added  for Fees Changes
                      V_FREETXN_EXCEED, -- Added  for logging fee of free transaction
                      V_DURATION, -- Added  for logging fee of free transaction
                      V_FEEATTACH_TYPE,
                      V_FEE_DESC, --Added for MVCSD-4471
                      'N',p_surchrg_ind --Added for VMS-5856
                      );

     IF V_ERROR <> 'OK' THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := V_ERROR;
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error from fee calc process ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    ---En dynamic fee calculation .

    --Sn calculate waiver on the fee
    BEGIN
     SP_CALCULATE_WAIVER(P_INST_CODE,
                     P_CARD_NO,
                     '000',
                     V_PROD_CODE,
                     V_PROD_CATTYPE,
                     V_FEE_CODE,
                     V_FEE_PLAN,
                     V_TRAN_DATE,--Added to calculate the waiver based on tran date
                     V_WAIV_PERCNT,
                     V_ERR_WAIV);

     IF V_ERR_WAIV <> 'OK' THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := V_ERR_WAIV;
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error from waiver calc process ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En calculate waiver on the fee

    --Sn apply waiver on fee amount
    V_LOG_ACTUAL_FEE := V_FEE_AMT; --only used to log in log table
    V_FEE_AMT        := ROUND(V_FEE_AMT -
                        ((V_FEE_AMT * V_WAIV_PERCNT) / 100),
                        2);
    V_LOG_WAIVER_AMT := V_LOG_ACTUAL_FEE - V_FEE_AMT;

    --only used to log in log table

    --En apply waiver on fee amount

    --Sn apply service tax and cess
    IF V_ST_CALC_FLAG = 1 THEN
     V_SERVICETAX_AMOUNT := (V_FEE_AMT * V_SERVICETAX_PERCENT) / 100;
    ELSE
     V_SERVICETAX_AMOUNT := 0;
    END IF;

    IF V_CESS_CALC_FLAG = 1 THEN
     V_CESS_AMOUNT := (V_SERVICETAX_AMOUNT * V_CESS_PERCENT) / 100;
    ELSE
     V_CESS_AMOUNT := 0;
    END IF;

    V_TOTAL_FEE := ROUND(V_FEE_AMT + V_SERVICETAX_AMOUNT + V_CESS_AMOUNT, 2);

    --En apply service tax and cess

    --En find fees amount attached to func code, prod code and card type





     IF  V_TOTAL_FEE <> 0 THEN

          IF V_TOTAL_FEE > v_acct_balance THEN

           V_RESP_CDE := '15';
            V_ERR_MSG  := 'Insufficient Balance ';
            RAISE EXP_REJECT_RECORD;



          END IF;



     END IF;

    --Sn Added  for enabling limit validation
    IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
    BEGIN
          pkg_limits_check.sp_limits_check (v_hash_pan,
                                            NULL,
                                            NULL,
                                            p_mcc_code,
                                            p_txn_code,
                                            v_tran_type,
                                          --  p_international_ind,
                                          --  p_pos_verfication,
                                          null,
                                          null,
                                            p_inst_code,
                                            NULL,
                                            v_prfl_code,
                                            v_tran_amt,
                                            p_delivery_channel,
                                            v_comb_hash,
                                            v_resp_cde,
                                            V_ERR_MSG,
                                            'N',
                                            V_MS_PYMNT_TYPE
                                           );
       IF v_err_msg <> 'OK' THEN
          RAISE exp_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_reject_record THEN
          RAISE;
       WHEN OTHERS    THEN
          v_resp_cde := '21';
          v_err_msg :='Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
    END IF;
    --En Added  for enabling limit validation

    --Sn find total transaction    amount
    IF V_DR_CR_FLAG = 'CR' THEN

     V_TOTAL_AMT      := V_TRAN_AMT - V_TOTAL_FEE;
     V_UPD_AMT        := V_ACCT_BALANCE + V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := V_LEDGER_BAL + V_TOTAL_AMT;

    ELSIF V_DR_CR_FLAG = 'DR' THEN

     V_TOTAL_AMT      := V_TRAN_AMT + V_TOTAL_FEE;
     V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := V_LEDGER_BAL - V_TOTAL_AMT;

    ELSIF V_DR_CR_FLAG = 'NA' THEN

     IF V_TRAN_PREAUTH_FLAG = 'Y' AND V_PREAUTH_TYPE ='C'THEN

       V_TOTAL_AMT := V_TRAN_AMT -V_TOTAL_FEE;
     --  V_UPD_AMT        := V_ACCT_BALANCE ;
     V_UPD_AMT        := V_ACCT_BALANCE -V_TOTAL_FEE;--Modified for ols certification changes
      V_UPD_LEDGER_AMT := V_LEDGER_BAL + V_TOTAL_AMT;

     END IF;

    ELSE
     V_RESP_CDE := '12'; --Ineligible Transaction
     V_ERR_MSG  := 'Invalid transflag    txn code ' || P_TXN_CODE;
     RAISE EXP_REJECT_RECORD;
    END IF;

    --En find total transaction    amout

/*    --Sn check balance          --- Commented for VMS-4821

    IF V_UPD_AMT < 0 THEN
     V_RESP_CDE := '15'; --Ineligible Transaction
     V_ERR_MSG  := 'Insufficient Balance ';
     RAISE EXP_REJECT_RECORD;

    END IF;

    --En check balance



     --Commented for Mantis ID 15120
  /* IF    (v_dr_cr_flag = 'CR' AND p_rvsl_code = '00')         -- IF condition added for OLS changes
         OR (v_dr_cr_flag = 'DR' AND p_rvsl_code <> '00')
         OR(v_dr_cr_flag = 'NA' AND  p_rvsl_code = '00'  AND V_PREAUTH_TYPE ='C' AND  V_TRAN_PREAUTH_FLAG ='Y')                          --Added by Besky on 26/03/13
      THEN
        -- Check for maximum card balance configured for the product profile.
        BEGIN

          SELECT TO_NUMBER(CBP_PARAM_VALUE)           -- Added  for max card balance check based on product category
           INTO V_MAX_CARD_BAL
           FROM CMS_BIN_PARAM
           WHERE CBP_INST_CODE = P_INST_CODE AND
               CBP_PARAM_NAME = 'Max Card Balance' AND
               cbp_profile_code IN
               (
                SELECT cpc_profile_code
                FROM cms_prod_cattype
                WHERE CPC_INST_CODE = p_inst_code
                and   cpc_prod_code = v_prod_code
                and   CPC_CARD_TYPE = v_prod_cattype
               );


        EXCEPTION
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;



            --Sn check balance
            IF (V_UPD_LEDGER_AMT > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL) THEN
             V_RESP_CDE := '30';
             V_ERR_MSG  := 'EXCEEDING MAXIMUM CARD BALANCE / BAD CREDIT STATUS';
             RAISE EXP_REJECT_RECORD;
            END IF;
            --En check balance


     End if;

    */     --Uncommented for 15194

    --Sn create gl entries and acct update
    BEGIN
     SP_UPD_TRANSACTION_ACCNT_AUTH(P_INST_CODE,
                             V_TRAN_DATE,
                             V_PROD_CODE,
                             V_PROD_CATTYPE,
                             --V_TRAN_AMT,
                             0,--Modified for 15194
                             V_FUNC_CODE,
                             P_TXN_CODE,
                             V_DR_CR_FLAG,
                             P_RRN,
                             P_TERM_ID,
                             P_DELIVERY_CHANNEL,
                             P_TXN_MODE,
                             P_CARD_NO,
                             V_FEE_CODE,
                             V_FEE_AMT,
                             V_FEE_CRACCT_NO,
                             V_FEE_DRACCT_NO,
                             V_ST_CALC_FLAG,
                             V_CESS_CALC_FLAG,
                             V_SERVICETAX_AMOUNT,
                             V_ST_CRACCT_NO,
                             V_ST_DRACCT_NO,
                             V_CESS_AMOUNT,
                             V_CESS_CRACCT_NO,
                             V_CESS_DRACCT_NO,
                             V_ACCT_NUMBER,
                            '0',
                             P_MSG,
                             V_RESP_CDE,
                             V_ERR_MSG);

     IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error from currency conversion ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En create gl entries and acct update

		BEGIN
		SELECT
			NVL(CIP_PARAM_VALUE,'N')
		INTO V_PARAM_VALUE
		FROM
			CMS_INST_PARAM
		WHERE
			CIP_PARAM_KEY = 'VMS_4199_TOGGLE'
			AND CIP_INST_CODE = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				V_PARAM_VALUE := 'N';
			WHEN OTHERS THEN
				V_RESP_CDE := '12';
				V_ERR_MSG := 'Error while selecting data from inst param '|| SUBSTR (SQLERRM, 1, 100);
			 RAISE EXP_REJECT_RECORD;
	   END;

	   IF P_DELIVERY_CHANNEL = '02' AND P_TXN_CODE = '36' AND V_PARAM_VALUE = 'Y' THEN

		BEGIN
             UPDATE CMS_ACCT_MAST
             SET CAM_ACCT_BAL  = CAM_ACCT_BAL+V_TRAN_AMT
                 WHERE CAM_INST_CODE = P_INST_CODE AND CAM_ACCT_NO = V_ACCT_NUMBER;

            IF SQL%ROWCOUNT = 0 THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Problem while updating in account master for transaction tran type.';
				RAISE EXP_REJECT_RECORD;
            END IF;
            EXCEPTION
			 WHEN EXP_REJECT_RECORD THEN
				RAISE;
             WHEN OTHERS THEN
               V_RESP_CDE := '21';
               V_ERR_MSG  := 'Error while updating CMS_ACCT_MAST ' ||
                            SUBSTR(SQLERRM, 1, 250);
			   RAISE EXP_REJECT_RECORD;
        END;

		V_PREAUTH_DATE := V_TRAN_DATE+(V_PREAUTH_CR_RELEASE_HRS * (1/24));

		V_UPD_MONEY_SEND_FLAG := 'Y';

		END IF;

    --Sn find narration
    BEGIN
    --Commended by saravanakumar on 16-Sep-2014
     /*SELECT CTM_TRAN_DESC
       INTO V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;*/

    -- Changed for FSS-4119 BEG	   
	IF TRIM(V_TRANS_DESC) IS NOT NULL THEN

     V_NARRATION := V_TRANS_DESC || '/';

    END IF;

    IF TRIM(P_MERCHANT_NAME) IS NOT NULL THEN

     V_NARRATION := V_NARRATION || P_MERCHANT_NAME || '/';

    END IF;

	 -- Changed for FSS-4119
	IF TRIM(P_TERM_ID) IS NOT NULL THEN

     V_NARRATION := V_NARRATION || P_TERM_ID || '/';

    END IF;

    IF TRIM(P_MERCHANT_CITY) IS NOT NULL THEN

     V_NARRATION := V_NARRATION || P_MERCHANT_CITY || '/';

    END IF;	

    IF TRIM(P_TRAN_DATE) IS NOT NULL THEN

     V_NARRATION := V_NARRATION || P_TRAN_DATE || '/';

    END IF;

    IF TRIM(V_AUTH_ID) IS NOT NULL THEN

     V_NARRATION := V_NARRATION || V_AUTH_ID;

    END IF;         
     -- Changed for FSS-4119 END

    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_TRANS_DESC := 'Transaction type ' || P_TXN_CODE;
     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error in finding the narration ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;

    --En find narration

  --  v_timestamp:=systimestamp;

    --Commented for Mantis ID 15120
/*    --Sn create a entry in statement log
    IF V_DR_CR_FLAG <> 'NA' or v_preauth_type='C' THEN
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
         CSL_ACCT_NO,
         CSL_INS_USER,
         CSL_INS_DATE,
         CSL_MERCHANT_NAME,
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE,
         CSL_PANNO_LAST4DIGIT,
         csl_prod_code,
         csl_acct_type,
         csl_time_stamp

         )
       VALUES
        (V_HASH_PAN,
         v_ledger_bal,
         V_TRAN_AMT,
         DECODE(v_preauth_type,'C','CR',V_DR_CR_FLAG),
         V_TRAN_DATE,
        DECODE(v_preauth_type,'C',v_ledger_bal + V_TRAN_AMT, DECODE(V_DR_CR_FLAG,
               'DR',
               v_ledger_bal - V_TRAN_AMT,
               'CR',
               v_ledger_bal + V_TRAN_AMT,
               'NA',
               v_ledger_bal)),
         V_NARRATION,
         P_INST_CODE,
         V_ENCR_PAN,
         P_RRN,
         V_AUTH_ID,
         P_TRAN_DATE,
         P_TRAN_TIME,
         'N',
         P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_ACCT_NUMBER,
         1,
         SYSDATE,

         P_MERCHANT_NAME,
         P_MERCHANT_CITY,

         P_ATMNAME_LOC,
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
         v_prod_code,
         v_acct_type,
         v_timestamp

         );
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Problem while inserting into statement log for tran amt ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    END IF;

    --En create a entry in statement log
*/
    --Sn find fee opening balance
    IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N' THEN
     BEGIN
     /*  SELECT DECODE(v_preauth_type,'C', v_ledger_bal + V_TRAN_AMT,decode(V_DR_CR_FLAG,
                  'DR',
                  v_ledger_bal - V_TRAN_AMT,
                  'CR',
                  v_ledger_bal + V_TRAN_AMT,
                  'NA',
                  v_ledger_bal))
        INTO V_FEE_OPENING_BAL
        FROM DUAL;*/
            --Modified  for Mantis ID 15120
        SELECT DECODE(V_DR_CR_FLAG,
                  'DR',
                  v_ledger_bal - V_TRAN_AMT,
                  'CR',
                  v_ledger_bal + V_TRAN_AMT,
                  'NA',
                  v_ledger_bal)
        INTO V_FEE_OPENING_BAL
        FROM DUAL;

     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '12';
        V_ERR_MSG  := 'Error in acct balance calculation based on transflag' ||
                    V_DR_CR_FLAG;
        RAISE EXP_REJECT_RECORD;
     END;
     -- Added  for logging complementary transaction
     IF V_FREETXN_EXCEED = 'N' THEN
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
           CSL_ACCT_NO,
           CSL_INS_USER,
           CSL_INS_DATE,
           CSL_MERCHANT_NAME,
           CSL_MERCHANT_CITY,
           CSL_MERCHANT_STATE,
           CSL_PANNO_LAST4DIGIT,

           csl_prod_code,csl_card_type,
           csl_acct_type,
           csl_time_stamp

           )
        VALUES
          (V_HASH_PAN,
           V_FEE_OPENING_BAL,
           V_TOTAL_FEE,
           'DR',
           V_TRAN_DATE,
           V_FEE_OPENING_BAL - V_TOTAL_FEE,
           V_FEE_DESC, --Added for MVCSD-4471--'Complimentary ' || V_DURATION ||' '|| V_NARRATION,
           P_INST_CODE,
           V_ENCR_PAN,
           P_RRN,
           V_AUTH_ID,
           P_TRAN_DATE,
           P_TRAN_TIME,
           'Y',
           P_DELIVERY_CHANNEL,
           P_TXN_CODE,
           V_ACCT_NUMBER,
           1,
           SYSDATE,

           P_MERCHANT_NAME,
           P_MERCHANT_CITY,

           P_ATMNAME_LOC,
           SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO)),
           v_prod_code,V_PROD_CATTYPE,
           v_acct_type,
           v_timestamp

         );
       EXCEPTION
        WHEN OTHERS THEN
          V_RESP_CDE := '21';
          V_ERR_MSG  := 'Problem while inserting into statement log for tran fee ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
       END;

     ELSE
        BEGIN

     --En find fee opening balance
     IF V_FEEAMNT_TYPE = 'A' THEN



        V_FLAT_FEES := ROUND(V_FLAT_FEES -
                            ((V_FLAT_FEES * V_WAIV_PERCNT) / 100),2);


            V_PER_FEES  := ROUND(V_PER_FEES -
                        ((V_PER_FEES * V_WAIV_PERCNT) / 100),2);

       --En Entry for Fixed Fee
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
         CSL_ACCT_NO,
         CSL_INS_USER,
         CSL_INS_DATE,
         CSL_MERCHANT_NAME,
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE,
         CSL_PANNO_LAST4DIGIT,

         csl_prod_code,csl_card_type,
         csl_acct_type,
         csl_time_stamp

         )
       VALUES
        (V_HASH_PAN,
         V_FEE_OPENING_BAL,
         V_FLAT_FEES,
         'DR',
         V_TRAN_DATE,
         V_FEE_OPENING_BAL - V_FLAT_FEES,
         'Fixed Fee debited for ' || V_FEE_DESC, --Added for MVCSD-4471--V_NARRATION,
         P_INST_CODE,
         V_ENCR_PAN,
         P_RRN,
         V_AUTH_ID,
         P_TRAN_DATE,
         P_TRAN_TIME,
         'Y',
         P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_ACCT_NUMBER,
         1,
         SYSDATE,

         P_MERCHANT_NAME,--NULL,
         P_MERCHANT_CITY,--NULL,

         P_ATMNAME_LOC,
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),

         v_prod_code,V_PROD_CATTYPE,
         v_acct_type,
         v_timestamp

         );
       --En Entry for Fixed Fee

	   IF V_PER_FEES <> 0 THEN --Added for VMS-5856
       V_FEE_OPENING_BAL := V_FEE_OPENING_BAL - V_FLAT_FEES;
       --Sn Entry for Percentage Fee

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
         CSL_ACCT_NO,
         CSL_INS_USER,
         CSL_INS_DATE,
         CSL_MERCHANT_NAME,
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE,
         CSL_PANNO_LAST4DIGIT,
         csl_prod_code,csl_card_type,
         csl_acct_type,
         csl_time_stamp

         )
       VALUES
        (V_HASH_PAN,
         V_FEE_OPENING_BAL,
         V_PER_FEES,
         'DR',
         V_TRAN_DATE,
         V_FEE_OPENING_BAL - V_PER_FEES,
         'Percetage Fee debited for ' || V_FEE_DESC, --Added for MVCSD-4471--V_NARRATION,
         P_INST_CODE,
         V_ENCR_PAN,
         P_RRN,
         V_AUTH_ID,
         P_TRAN_DATE,
         P_TRAN_TIME,
         'Y',
         P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_ACCT_NUMBER,
         1,
         SYSDATE,

         P_MERCHANT_NAME,
         P_MERCHANT_CITY,

         P_ATMNAME_LOC,
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),

         v_prod_code,V_PROD_CATTYPE,
         v_acct_type,
         v_timestamp

         );

       --En Entry for Percentage Fee
    END IF;
     ELSE
       --Sn create entries for FEES attached

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
           CSL_ACCT_NO,
           CSL_INS_USER,
           CSL_INS_DATE,
           CSL_MERCHANT_NAME,
           CSL_MERCHANT_CITY,
           CSL_MERCHANT_STATE,
           CSL_PANNO_LAST4DIGIT,
           csl_prod_code,csl_card_type,
           csl_acct_type,
           csl_time_stamp

         )
        VALUES
          (V_HASH_PAN,
           V_FEE_OPENING_BAL,
           V_TOTAL_FEE,
           'DR',
           V_TRAN_DATE,
           V_FEE_OPENING_BAL - V_TOTAL_FEE,
           'Fee debited for ' || V_FEE_DESC, --Added for MVCSD-4471--V_NARRATION,
           P_INST_CODE,
           V_ENCR_PAN,
           P_RRN,
           V_AUTH_ID,
           P_TRAN_DATE,
           P_TRAN_TIME,
           'Y',
           P_DELIVERY_CHANNEL,
           P_TXN_CODE,
           V_ACCT_NUMBER,
           1,
           SYSDATE,

           P_MERCHANT_NAME,
           P_MERCHANT_CITY,

           P_ATMNAME_LOC,
           SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO)),
           v_prod_code,V_PROD_CATTYPE,
           v_acct_type,
           v_timestamp

          );
     END IF;
      EXCEPTION
        WHEN OTHERS THEN
          V_RESP_CDE := '21';
          V_ERR_MSG  := 'Problem while inserting into statement log for tran fee ' ||
                                 SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
      END;
    END IF;
    END IF;

    --En create entries for FEES attached
    --Sn create a entry for successful
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        CTD_ACTUAL_AMOUNT,
        CTD_FEE_AMOUNT,
        CTD_WAIVER_AMOUNT,
        CTD_SERVICETAX_AMOUNT,
        CTD_CESS_AMOUNT,
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_ADDR_VERIFY_RESPONSE,
        CTD_INTERNATION_IND_RESPONSE,

        CTD_NETWORK_ID,
        CTD_INTERCHANGE_FEEAMT,
        CTD_MERCHANT_ZIP,
        CTD_MERCHANT_ID,
        CTD_COUNTRY_CODE,

        ctd_ins_user, -- Added for OLS changes
        ctd_ins_date , -- Added for OLS changes
        CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT
        ,CTD_PAYMENT_TYPE, ctd_hashkey_id 
        )
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_MSG,
        P_TXN_MODE,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        P_TXN_AMT,
        P_CURR_CODE,
        V_TRAN_AMT,
        V_LOG_ACTUAL_FEE,
        V_LOG_WAIVER_AMT,
        V_SERVICETAX_AMOUNT,
        V_CESS_AMOUNT,
        V_TOTAL_AMT,
        V_CARD_CURR,
        'Y',
        'Successful',
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        P_ADDR_VERFY_RESPONSE, -- added for ols changes
        NULL,

        P_NETWORK_ID,
        P_INTERCHANGE_FEEAMT,
        P_MERCHANT_ZIP,
        P_MERC_ID,
        P_MERC_CNTRYCODE,

        1,
        SYSDATE,
        P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
        P_CARDVERIFICATION_RESULT--Added for MVHOST 926
        ,P_MS_PYMNT_DESC,V_HASHKEY_ID
        );
     --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while inserting in CMS_TRANSACTION_LOG_DTL ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --En create a entry for successful
    ---Sn update daily and weekly transcounter  and amount

    --Commended by saravanakumar on 16-Sep-2014
    /*BEGIN

     UPDATE CMS_AVAIL_TRANS
        SET CAT_MAXDAILY_TRANCNT  = DECODE(CAT_MAXDAILY_TRANCNT,
                                    0,
                                    CAT_MAXDAILY_TRANCNT,
                                    CAT_MAXDAILY_TRANCNT - 1),
           CAT_MAXDAILY_TRANAMT  = DECODE(V_DR_CR_FLAG,
                                    'DR',
                                    CAT_MAXDAILY_TRANAMT - V_TRAN_AMT,
                                    CAT_MAXDAILY_TRANAMT),
           CAT_MAXWEEKLY_TRANCNT = DECODE(CAT_MAXWEEKLY_TRANCNT,
                                    0,
                                    CAT_MAXWEEKLY_TRANCNT,
                                    CAT_MAXDAILY_TRANCNT - 1),
           CAT_MAXWEEKLY_TRANAMT = DECODE(V_DR_CR_FLAG,
                                    'DR',
                                    CAT_MAXWEEKLY_TRANAMT -
                                    V_TRAN_AMT,
                                    CAT_MAXWEEKLY_TRANAMT)
      WHERE CAT_INST_CODE = P_INST_CODE AND CAT_PAN_CODE = V_HASH_PAN AND
           CAT_TRAN_CODE = P_TXN_CODE AND CAT_TRAN_MODE = P_TXN_MODE;

    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from avail trans ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;*/

    --En update daily and weekly transaction counter and amount
    --Sn create detail for response message
    IF V_OUTPUT_TYPE = 'B' THEN
     --Balance Inquiry
     P_RESP_MSG := TO_CHAR(V_UPD_AMT);
    END IF;

    --En create detail fro response message
    --Sn mini statement
    IF V_OUTPUT_TYPE = 'M' THEN
     --Mini statement
     BEGIN
       SP_GEN_MINI_STMT(P_INST_CODE,
                    P_CARD_NO,
                    V_MINI_TOTREC,
                    V_MINISTMT_OUTPUT,
                    V_MINISTMT_ERRMSG);

       IF V_MINISTMT_ERRMSG <> 'OK' THEN
        V_ERR_MSG  := V_MINISTMT_ERRMSG;
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       END IF;

       P_RESP_MSG := LPAD(TO_CHAR(V_MINI_TOTREC), 2, '0') ||
                  V_MINISTMT_OUTPUT;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_ERR_MSG  := 'Problem while selecting data for mini statement ' ||
                    SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;
    END IF;

    --En mini statement
    V_RESP_CDE := '1';



    BEGIN
     --Add for PreAuth Transaction of CMSAuth;
     --Sn creating entries for preauth txn
     --if incoming message not contains checking for prod preauth expiry period
     --if preauth expiry period is not configured checking for instution expirty period
     BEGIN
       IF V_TRAN_PREAUTH_FLAG = 'Y' THEN

		IF V_UPD_MONEY_SEND_FLAG = 'N' THEN

            vt_preauth_hold :=TO_NUMBER (SUBSTR (TRIM (NVL (V_PREAUTH_EXP_PERIOD, '000')), 1, 1));
            vt_preauth_period :=TO_NUMBER (SUBSTR (TRIM (NVL (V_PREAUTH_EXP_PERIOD, '000')), 2, 2));

          BEGIN
             SELECT NVL (cpm_pre_auth_exp_date, '000')
               INTO vp_preauth_exp_period
               FROM cms_prod_mast
              WHERE cpm_prod_code = v_prod_code;
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                vp_preauth_exp_period := '000';
             WHEN OTHERS
             THEN
                vp_preauth_exp_period := '000';
          END;

              vp_preauth_hold :=TO_NUMBER (SUBSTR (TRIM (vp_preauth_exp_period), 1, 1));
              vp_preauth_period :=TO_NUMBER (SUBSTR (TRIM (vp_preauth_exp_period), 2, 2));

              IF vt_preauth_hold = vp_preauth_hold
              THEN
                 v_preauth_hold := vt_preauth_hold;

                 SELECT GREATEST (vt_preauth_period, vp_preauth_period)
                   INTO v_preauth_period
                   FROM DUAL;
              ELSE
                 IF vt_preauth_hold > vp_preauth_hold
                 THEN
                    v_preauth_hold := vt_preauth_hold;
                    v_preauth_period := vt_preauth_period;
                 ELSIF vt_preauth_hold < vp_preauth_hold
                 THEN
                    v_preauth_hold := vp_preauth_hold;
                    v_preauth_period := vp_preauth_period;
                 END IF;
              END IF;

            /*Comparing greatest from both with institution peroid Txn Peroid and product peroid  */

              BEGIN
                 SELECT NVL (cip_param_value, '000')
                   INTO vi_preauth_exp_period
                   FROM cms_inst_param
                  WHERE cip_inst_code = p_inst_code
                    AND cip_param_key = 'PRE-AUTH EXP PERIOD';
              EXCEPTION
                 WHEN NO_DATA_FOUND
                 THEN
                    vi_preauth_exp_period := '000';
                 WHEN OTHERS
                 THEN
                    vi_preauth_exp_period := '000';
              END;

              vi_preauth_hold :=TO_NUMBER (SUBSTR (TRIM (vi_preauth_exp_period), 1, 1)); --01122012
              vi_preauth_period :=TO_NUMBER (SUBSTR (TRIM (vi_preauth_exp_period), 2, 2));--01122012

              IF v_preauth_hold = vi_preauth_hold
              THEN
                 v_preauth_hold := v_preauth_hold;

                 SELECT GREATEST (v_preauth_period, vi_preauth_period)
                   INTO v_preauth_period
                   FROM DUAL;
              ELSE
                 IF v_preauth_hold > vi_preauth_hold
                 THEN
                    v_preauth_hold := v_preauth_hold;
                    v_preauth_period := v_preauth_period;
                 ELSIF v_preauth_hold < vi_preauth_hold
                 THEN
                    v_preauth_hold := vi_preauth_hold;
                    v_preauth_period := vi_preauth_period;
                 END IF;
              END IF;



          IF     P_DELIVERY_CHANNEL IN ('01', '02') AND V_TRAN_PREAUTH_FLAG = 'Y'
            AND V_ADJUSTMENT_FLAG = 'N' AND V_DR_CR_FLAG = 'NA' THEN
          IF V_HOLD_DAYS IS NOT NULL
          AND V_HOLD_DAYS <> '0'
          THEN
             IF V_PREAUTH_HOLD in( '0', '1')  THEN
                V_PREAUTH_PERIOD := V_HOLD_DAYS;
                V_PREAUTH_HOLD:='2'  ;
             ELSIF V_PREAUTH_HOLD='2' THEN
               IF V_HOLD_DAYS > V_PREAUTH_PERIOD THEN
                V_PREAUTH_PERIOD := V_HOLD_DAYS;
                V_PREAUTH_HOLD:='2'  ;
               END IF;
             END IF ;
          END IF;
        END IF;




        IF V_PREAUTH_HOLD = '0' THEN
          V_PREAUTH_DATE := V_TRAN_DATE + (V_PREAUTH_PERIOD * (1 / 1440));
        END IF;

        IF V_PREAUTH_HOLD = '1' THEN
          V_PREAUTH_DATE := V_TRAN_DATE + (V_PREAUTH_PERIOD * (1 / 24));
        END IF;

        IF V_PREAUTH_HOLD = '2' THEN
          V_PREAUTH_DATE := V_TRAN_DATE + V_PREAUTH_PERIOD;
        END IF;

	END IF;

        BEGIN
          BEGIN
            INSERT INTO CMS_PREAUTH_TRANSACTION
             (CPT_CARD_NO,
              CPT_TXN_AMNT,
              CPT_EXPIRY_DATE,
              CPT_SEQUENCE_NO,
              CPT_PREAUTH_VALIDFLAG,
              CPT_INST_CODE,
              CPT_MBR_NO,
              CPT_CARD_NO_ENCR,
              CPT_COMPLETION_FLAG,
              CPT_APPROVE_AMT,
              CPT_RRN,
              CPT_TXN_DATE,
              CPT_TXN_TIME,
              CPT_TERMINALID,
              CPT_EXPIRY_FLAG,
              CPT_TOTALHOLD_AMT,
              CPT_TRANSACTION_FLAG,
              CPT_ACCT_NO,
              CPT_MCC_CODE,
              cpt_preauth_type,
              --Sn Added for Transactionlog Functional Removal Phase-II changes
              cpt_delivery_channel,
              cpt_txn_code,
              cpt_merchant_id,
              cpt_merchant_name, 
              cpt_merchant_city,
              cpt_merchant_state, 
              cpt_merchant_zip, 
              cpt_pos_verification, 
              cpt_internation_ind_response
              --En Added for Transactionlog Functional Removal Phase-II changes
              )
            VALUES
             (V_HASH_PAN,
              V_TRAN_AMT,
              V_PREAUTH_DATE,
              '1',
              'Y',
              P_INST_CODE,
              P_MBR_NUMB,
              V_ENCR_PAN,
              'N',
              trim(to_char(nvl(V_TRAN_AMT,0),'999999999999999990.99')),
              P_RRN,
              P_TRAN_DATE,
              P_TRAN_TIME,
              P_TERM_ID,
              'N',
              trim(to_char(nvl(V_TRAN_AMT,0),'999999999999999990.99')),
              'N',
              V_ACCT_NUMBER,
              P_MCC_CODE ,
              v_preauth_type,
              --Sn Added for Transactionlog Functional Removal Phase-II changes
              p_delivery_channel,
              p_txn_code,
              p_merc_id,
              p_merchant_name,
              p_merchant_city,
              p_atmname_loc,
              p_merchant_zip,
              p_pos_verfication,
              p_international_ind
              --En Added for Transactionlog Functional Removal Phase-II changes
              );
          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while inserting  CMS_PREAUTH_TRANSACTION ' ||
                        SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;

          BEGIN
            INSERT INTO CMS_PREAUTH_TRANS_HIST
             (CPH_CARD_NO,
              CPH_TXN_AMNT,
              CPH_EXPIRY_DATE,
              CPH_SEQUENCE_NO,
              CPH_PREAUTH_VALIDFLAG,
              CPH_INST_CODE,
              CPH_MBR_NO,
              CPH_CARD_NO_ENCR,
              CPH_COMPLETION_FLAG,
              CPH_APPROVE_AMT,
              CPH_RRN,
              CPH_TXN_DATE,
              CPH_TERMINALID,
              CPH_EXPIRY_FLAG,
              CPH_TRANSACTION_FLAG,
              CPH_TOTALHOLD_AMT,
              CPH_TRANSACTION_RRN,
              CPH_ACCT_NO,
              CPH_MERCHANT_NAME,
              CPH_MERCHANT_STATE,
              CPH_MERCHANT_CITY

              ,CPH_DELIVERY_CHANNEL
              ,CPH_TRAN_CODE,
              cph_preauth_type ,
              CPH_PANNO_LAST4DIGIT
             )
            VALUES
             (V_HASH_PAN,
              v_tran_amt ,
              V_PREAUTH_DATE,
              p_rrn ,
              'Y',
              P_INST_CODE,
              P_MBR_NUMB,
              V_ENCR_PAN,
              'N',


              TRIM (TO_CHAR (nvl(v_tran_amt,0),'999999999999999990.99')),
              P_RRN,
              P_TRAN_DATE,
              P_TERM_ID,
              'N',
              V_TRANTYPE,
              trim(to_char(nvl(V_TRAN_AMT,0),'999999999999999990.99')),
              P_RRN,
              V_ACCT_NUMBER,
              P_MERCHANT_NAME,
              P_ATMNAME_LOC,
              P_MERCHANT_CITY

              ,P_DELIVERY_CHANNEL
              ,P_TXN_CODE ,
              v_preauth_type,
               SUBSTR(P_CARD_NO,-4)

              );
          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while inserting  CMS_PREAUTH_TRANS_HIST ' ||
                        SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;

        EXCEPTION
          WHEN EXP_REJECT_RECORD THEN
            RAISE;

          WHEN OTHERS THEN
            V_RESP_CDE := '21'; -- Server Declione
            V_ERR_MSG  := 'Problem while inserting preauth transaction details' ||
                       SUBSTR(SQLERRM, 1, 300);
            RAISE EXP_REJECT_RECORD;
        END;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;

       WHEN OTHERS THEN
        V_RESP_CDE := '21'; -- Server Declione
        V_ERR_MSG  := 'Problem while inserting preauth transaction details' ||
                    SUBSTR(SQLERRM, 1, 300);
        RAISE EXP_REJECT_RECORD;
     END;

     ---Sn Updation of Usage limit and amount
     --Commended by saravanakumar on 16-Sep-2014
     /*BEGIN
       SELECT CTC_ATMUSAGE_AMT,
            CTC_POSUSAGE_AMT,
            CTC_ATMUSAGE_LIMIT,
            CTC_POSUSAGE_LIMIT,
            CTC_BUSINESS_DATE,
            CTC_PREAUTHUSAGE_LIMIT
        INTO V_ATM_USAGEAMNT,
            V_POS_USAGEAMNT,
            V_ATM_USAGELIMIT,
            V_POS_USAGELIMIT,
            V_BUSINESS_DATE_TRAN,
            V_PREAUTH_USAGE_LIMIT
        FROM CMS_TRANSLIMIT_CHECK
        WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN --P_card_no
            AND CTC_MBR_NUMB = P_MBR_NUMB;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERR_MSG  := 'Error while selecting CMS_TRANSLIMIT_CHECK' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN
       IF P_DELIVERY_CHANNEL = '01' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          IF P_TXN_AMT IS NULL THEN
            V_ATM_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999999.99'));
          ELSE
            V_ATM_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
                                     '99999999999999999.99'));
          END IF;

          V_ATM_USAGELIMIT := 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_ATMUSAGE_AMT       = V_ATM_USAGEAMNT,
                 CTC_ATMUSAGE_LIMIT     = V_ATM_USAGELIMIT,
                 CTC_POSUSAGE_AMT       = 0,
                 CTC_POSUSAGE_LIMIT     = 0,
                 CTC_PREAUTHUSAGE_LIMIT = 0,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss'),
                 CTC_MMPOSUSAGE_AMT     = 0,
                 CTC_MMPOSUSAGE_LIMIT   = 0
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;
            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK1';
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;
          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK1' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          IF P_TXN_AMT IS NULL THEN
            V_ATM_USAGEAMNT := V_ATM_USAGEAMNT +
                           TRIM(TO_CHAR(0, '99999999999999999.99'));
          ELSE
            V_ATM_USAGEAMNT := V_ATM_USAGEAMNT +
                           TRIM(TO_CHAR(V_TRAN_AMT,
                                     '99999999999999999.99'));
          END IF;

          V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_ATMUSAGE_AMT   = V_ATM_USAGEAMNT,
                 CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;
            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK2';
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;
          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK2' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;

       IF P_DELIVERY_CHANNEL = '02' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          IF P_TXN_AMT IS NULL THEN
            V_POS_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999999.99'));
          ELSE
            V_POS_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
                                     '99999999999999999.99'));
          END IF;

          V_POS_USAGELIMIT := 1;

          IF V_TRAN_PREAUTH_FLAG = 'Y' THEN
            V_PREAUTH_USAGE_LIMIT := 1;
            V_POS_USAGEAMNT       := 0;
          ELSE
            V_PREAUTH_USAGE_LIMIT := 0;
          END IF;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_POSUSAGE_AMT       = V_POS_USAGEAMNT,
                 CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
                 CTC_ATMUSAGE_AMT       = 0,
                 CTC_ATMUSAGE_LIMIT     = 0,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss'),
                 CTC_MMPOSUSAGE_AMT     = 0,
                 CTC_MMPOSUSAGE_LIMIT   = 0,
                 CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;
            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK3';
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK3' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

          IF V_TRAN_PREAUTH_FLAG = 'Y' THEN
            V_PREAUTH_USAGE_LIMIT := V_PREAUTH_USAGE_LIMIT + 1;
            V_POS_USAGEAMNT       := V_POS_USAGEAMNT +
                                TRIM(TO_CHAR(V_TRAN_AMT,
                                          '99999999999999999.99'));
          ELSE
            IF P_TXN_AMT IS NULL THEN
             V_POS_USAGEAMNT := V_POS_USAGEAMNT +
                            TRIM(TO_CHAR(0, '99999999999999999.99'));
            ELSE
             V_POS_USAGEAMNT := V_POS_USAGEAMNT +
                            TRIM(TO_CHAR(V_TRAN_AMT,
                                       '99999999999999999.99'));
            END IF;
          END IF;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_POSUSAGE_AMT       = V_POS_USAGEAMNT,
                 CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
                 CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;
            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK4';
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK4' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK -  INNER LOOP' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;*/
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK -  MAIN' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    ---En Updation of Usage limit and amount
    P_RESP_ID := V_RESP_CDE; --Added for VMS-8018
    BEGIN
     SELECT CMS_B24_RESPCDE, --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
            cms_iso_respcde  -- Added for OLS changes
       INTO P_RESP_CODE,

            P_ISO_RESPCDE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master for respose code' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

        --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

     P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 3: ' || v_mili ;
     --EN Added by Pankaj S. for DB time logging changes

    --Sn Added by Pankaj S. for enabling limit validation
    IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
    BEGIN
          pkg_limits_check.sp_limitcnt_reset (p_inst_code,
                                              v_hash_pan,
                                              v_tran_amt,
                                              v_comb_hash,
                                              v_resp_cde,
                                              v_err_msg
                                             );
       IF v_err_msg <> 'OK' THEN
          v_err_msg := 'From Procedure sp_limitcnt_reset' || v_err_msg;
          RAISE exp_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_reject_record THEN
          RAISE;
       WHEN OTHERS THEN
          v_resp_cde := '21';
          v_err_msg := 'Error from Limit Reset Count Process ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;
    END IF;

   --SN added for VMS_8140    
        BEGIN
            sp_autonomous_preauth_logclear(v_auth_id);
        EXCEPTION
            When others then
            null;
        END;
--EN added for VMS_8140   
    

    --En Added  for enabling limit validation

  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =V_ACCT_NUMBER--Modified by saravanakumar on 16-Sep-2014
            /*(SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_INST_CODE = P_INST_CODE)*/ AND
            CAM_INST_CODE = P_INST_CODE
            for update;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;
     END;

     --Commended by saravanakumar on 16-Sep-2014
     /*BEGIN
       SELECT CTC_ATMUSAGE_LIMIT,
            CTC_POSUSAGE_LIMIT,
            CTC_BUSINESS_DATE,
            CTC_PREAUTHUSAGE_LIMIT
        INTO V_ATM_USAGELIMIT,
            V_POS_USAGELIMIT,
            V_BUSINESS_DATE_TRAN,
            V_PREAUTH_USAGE_LIMIT
        FROM CMS_TRANSLIMIT_CHECK
        WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
            CTC_MBR_NUMB = P_MBR_NUMB;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERR_MSG  := 'Error while selecting CMS_TRANSLIMIT_CHECK3' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN

       IF P_DELIVERY_CHANNEL = '02' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          V_POS_USAGEAMNT       := 0;
          V_POS_USAGELIMIT      := 1;
          V_PREAUTH_USAGE_LIMIT := 0;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_POSUSAGE_AMT       = V_POS_USAGEAMNT,
                 CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
                 CTC_ATMUSAGE_AMT       = 0,
                 CTC_ATMUSAGE_LIMIT     = 0,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss'),
                 CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT,
                 CTC_MMPOSUSAGE_AMT     = 0,
                 CTC_MMPOSUSAGE_LIMIT   = 0
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;
          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK4' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;
          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK5' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;

     END;*/

     --Sn select response code and insert record into txn log dtl
     BEGIN
       P_RESP_MSG  := V_ERR_MSG;
       P_RESP_CODE := V_RESP_CDE;
       P_RESP_ID   := V_RESP_CDE; --Added for VMS-8018

       -- Assign the response code to the out parameter
       SELECT CMS_B24_RESPCDE, --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
              cms_iso_respcde  -- Added for OLS changes
        INTO P_RESP_CODE,
             --v_cms_iso_respcde  -- Added for OLS changes
             P_ISO_RESPCDE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INST_CODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69';
        P_RESP_ID   := '69'; --Added for VMS-8018
        ---ISO MESSAGE FOR DATABASE ERROR Server Declined
        ROLLBACK;
     END;

     BEGIN
       INSERT INTO CMS_TRANSACTION_LOG_DTL
        (CTD_DELIVERY_CHANNEL,
         CTD_TXN_CODE,
         CTD_TXN_TYPE,
         CTD_MSG_TYPE,
         CTD_TXN_MODE,
         CTD_BUSINESS_DATE,
         CTD_BUSINESS_TIME,
         CTD_CUSTOMER_CARD_NO,
         CTD_TXN_AMOUNT,
         CTD_TXN_CURR,
         CTD_ACTUAL_AMOUNT,
         CTD_FEE_AMOUNT,
         CTD_WAIVER_AMOUNT,
         CTD_SERVICETAX_AMOUNT,
         CTD_CESS_AMOUNT,
         CTD_BILL_AMOUNT,
         CTD_BILL_CURR,
         CTD_PROCESS_FLAG,
         CTD_PROCESS_MSG,
         CTD_RRN,
         CTD_SYSTEM_TRACE_AUDIT_NO,
         CTD_INST_CODE,
         CTD_CUSTOMER_CARD_NO_ENCR,
         CTD_CUST_ACCT_NUMBER,

         CTD_NETWORK_ID,
         CTD_INTERCHANGE_FEEAMT,
         CTD_MERCHANT_ZIP,
         CTD_MERCHANT_ID,
         CTD_COUNTRY_CODE,

         ctd_ins_user, -- Added for OLS changes
         ctd_ins_date,  -- Added for OLS changes
         CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
         ,CTD_PAYMENT_TYPE,ctd_hashkey_id
         )
       VALUES
        (P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_MSG,
         P_TXN_MODE,
         P_TRAN_DATE,
         P_TRAN_TIME,
         V_HASH_PAN,
         P_TXN_AMT,
         P_CURR_CODE,
         V_TRAN_AMT,
         NULL,
         NULL,
         NULL,
         NULL,
         V_TOTAL_AMT,
         V_CARD_CURR,
         'E',
         V_ERR_MSG,
         P_RRN,
         P_STAN,
         P_INST_CODE,
         V_ENCR_PAN,
         V_ACCT_NUMBER,

         P_NETWORK_ID,
         P_INTERCHANGE_FEEAMT,
         P_MERCHANT_ZIP,
         P_MERC_ID,
         P_MERC_CNTRYCODE,

         1,
         SYSDATE,
         P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
        P_CARDVERIFICATION_RESULT--Added for MVHOST 926
        ,P_MS_PYMNT_DESC,V_HASHKEY_ID
         );

       P_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        P_RESP_ID   := '69'; --Added for VMS-8018
        ROLLBACK;
        RETURN;
     END;

   
--SN added for VMS_8140    
        BEGIN
            sp_autonomous_preauth_logclear(v_auth_id);
        EXCEPTION
            When others then
            null;
        END;
--EN added for VMS_8140   
    

    WHEN OTHERS THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;

     --Commended by saravanakumar on 16-Sep-2014
     /*BEGIN
       SELECT CTC_ATMUSAGE_LIMIT,
            CTC_POSUSAGE_LIMIT,
            CTC_BUSINESS_DATE,
            CTC_PREAUTHUSAGE_LIMIT
        INTO V_ATM_USAGELIMIT,
            V_POS_USAGELIMIT,
            V_BUSINESS_DATE_TRAN,
            V_PREAUTH_USAGE_LIMIT
        FROM CMS_TRANSLIMIT_CHECK
        WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
            CTC_MBR_NUMB = P_MBR_NUMB;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERR_MSG  := 'Error while selecting CMS_TRANSLIMIT_CHECK4' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN

       IF P_DELIVERY_CHANNEL = '02' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          V_POS_USAGEAMNT       := 0;
          V_POS_USAGELIMIT      := 1;
          V_PREAUTH_USAGE_LIMIT := 0;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_POSUSAGE_AMT       = V_POS_USAGEAMNT,
                 CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
                 CTC_ATMUSAGE_AMT       = 0,
                 CTC_ATMUSAGE_LIMIT     = 0,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss'),
                 CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT,
                 CTC_MMPOSUSAGE_AMT     = 0,
                 CTC_MMPOSUSAGE_LIMIT   = 0
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;
          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK6' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;
          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK7' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;
     END;*/

     --Sn select response code and insert record into txn log dtl
     BEGIN
       SELECT CMS_B24_RESPCDE, --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
              cms_iso_respcde
        INTO P_RESP_CODE,

             P_ISO_RESPCDE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INST_CODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;

       P_RESP_MSG := V_ERR_MSG;
       P_RESP_ID  := V_RESP_CDE; --Added for VMS-8018
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        P_RESP_ID   := '69'; --Added for VMS-8018
        ROLLBACK;
     END;

     BEGIN
       INSERT INTO CMS_TRANSACTION_LOG_DTL
        (CTD_DELIVERY_CHANNEL,
         CTD_TXN_CODE,
         CTD_TXN_TYPE,
         CTD_MSG_TYPE,
         CTD_TXN_MODE,
         CTD_BUSINESS_DATE,
         CTD_BUSINESS_TIME,
         CTD_CUSTOMER_CARD_NO,
         CTD_TXN_AMOUNT,
         CTD_TXN_CURR,
         CTD_ACTUAL_AMOUNT,
         CTD_FEE_AMOUNT,
         CTD_WAIVER_AMOUNT,
         CTD_SERVICETAX_AMOUNT,
         CTD_CESS_AMOUNT,
         CTD_BILL_AMOUNT,
         CTD_BILL_CURR,
         CTD_PROCESS_FLAG,
         CTD_PROCESS_MSG,
         CTD_RRN,
         CTD_SYSTEM_TRACE_AUDIT_NO,
         CTD_INST_CODE,
         CTD_CUSTOMER_CARD_NO_ENCR,
         CTD_CUST_ACCT_NUMBER,
         CTD_ADDR_VERIFY_RESPONSE,
         CTD_INTERNATION_IND_RESPONSE,

         CTD_NETWORK_ID,
         CTD_INTERCHANGE_FEEAMT,
         CTD_MERCHANT_ZIP,
         CTD_MERCHANT_ID,
         CTD_COUNTRY_CODE,

         ctd_ins_user, -- Added for OLS changes
         ctd_ins_date,  -- Added for OLS changes
         CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
         ,CTD_PAYMENT_TYPE, ctd_hashkey_id 
         )
       VALUES
        (P_DELIVERY_CHANNEL,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_MSG,
         P_TXN_MODE,
         P_TRAN_DATE,
         P_TRAN_TIME,
         V_HASH_PAN,
         P_TXN_AMT,
         P_CURR_CODE,
         V_TRAN_AMT,
         NULL,
         NULL,
         NULL,
         NULL,
         V_TOTAL_AMT,
         V_CARD_CURR,
         'E',
         V_ERR_MSG,
         P_RRN,
         P_STAN,
         P_INST_CODE,
         V_ENCR_PAN,
         V_ACCT_NUMBER,
         P_ADDR_VERFY_RESPONSE, -- added for OLS Changes
         NULL,

         P_NETWORK_ID,
         P_INTERCHANGE_FEEAMT,
         P_MERCHANT_ZIP,
         P_MERC_ID,
         P_MERC_CNTRYCODE,

         1,
         SYSDATE,
         P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
        P_CARDVERIFICATION_RESULT--Added for MVHOST 926
        ,P_MS_PYMNT_DESC,v_hashkey_id
         );
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Decline Response 220509
        P_RESP_ID   := '69'; --Added for VMS-8018
        ROLLBACK;
        RETURN;
     END;
     --En select response code and insert record into txn log dtl
	 
	 --SN added for VMS_8140    
            BEGIN
                sp_autonomous_preauth_logclear(v_auth_id);
            EXCEPTION
                When others then
                null;
            END;
    --EN added for VMS_8140 
  END;

  --- Sn create GL ENTRIES
  IF V_RESP_CDE = '1' OR v_resp_cde = '2'
  THEN
    SAVEPOINT V_SAVEPOINT;
    --Sn find business date
    V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
    ELSE
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
    END IF;

    --En find businesses date

    --Sn find prod code and card type and available balance for the card number
    BEGIN
     SELECT CAM_ACCT_BAL,
            CAM_LEDGER_BAL  -- Added for OLS
       INTO V_ACCT_BALANCE,
            p_ledger_bal    -- Added for OLS
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER--Modified by saravanakumar on 16-Sep-2014
           /*(SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE)*/ AND
           CAM_INST_CODE = P_INST_CODE
        FOR UPDATE ;                                                    -- Commented for Concurrent Processsing Issue
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14'; --Ineligible Transaction
       V_ERR_MSG  := 'Invalid Card ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;

     V_LEDGER_BAL := p_ledger_bal;

    --En find prod code and card type for the card number
    IF V_OUTPUT_TYPE = 'N' THEN
     --Balance Inquiry
     P_RESP_MSG := TO_CHAR(V_UPD_AMT);
    END IF;
  END IF;

  --En create GL ENTRIES


  IF v_dr_cr_flag IS NULL THEN
  BEGIN
    SELECT ctm_credit_debit_flag,
           TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_type,ctm_tran_desc
      INTO v_dr_cr_flag,
           v_txn_type, v_tran_type,V_TRANS_DESC
      FROM cms_transaction_mast
     WHERE ctm_tran_code = p_txn_code
       AND ctm_delivery_channel = p_delivery_channel
       AND ctm_inst_code = p_inst_code;
  EXCEPTION
     WHEN OTHERS THEN
        NULL;
  END;
 /*  if V_MS_PYMNT_TYPE is not null then
   V_TRANS_DESC:='MoneySend'||' '||V_TRANS_DESC;  
   end if;  */
  end if;


  IF v_prod_code is NULL THEN
  BEGIN
    SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
      INTO v_prod_code, v_prod_cattype, v_applpan_cardstat,v_acct_number
      FROM cms_appl_pan
     WHERE cap_inst_code = p_inst_code
       AND cap_pan_code = gethash (p_card_no);
  EXCEPTION
     WHEN OTHERS THEN
        NULL;
  END;
  END IF;

  IF v_acct_type IS NULL THEN
  BEGIN
   SELECT cam_type_code
    INTO v_acct_type
    FROM cms_acct_mast
   WHERE cam_inst_code = p_inst_code
     AND cam_acct_no = v_acct_number;
  EXCEPTION
     WHEN OTHERS THEN
        NULL;
  END;
  END IF;


  --Sn create a entry in txn log
  BEGIN
    INSERT INTO TRANSACTIONLOG
     (MSGTYPE,
      RRN,
      DELIVERY_CHANNEL,
      TERMINAL_ID,
      DATE_TIME,
      TXN_CODE,
      TXN_TYPE,
      TXN_MODE,
      TXN_STATUS,
      RESPONSE_CODE,
      BUSINESS_DATE,
      BUSINESS_TIME,
      CUSTOMER_CARD_NO,
      TOPUP_CARD_NO,
      TOPUP_ACCT_NO,
      TOPUP_ACCT_TYPE,
      BANK_CODE,
      TOTAL_AMOUNT,
      RULE_INDICATOR,
      RULEGROUPID,
      MCCODE,
      CURRENCYCODE,
      ADDCHARGE,
      PRODUCTID,
      CATEGORYID,
      TIPS,
      DECLINE_RULEID,
      ATM_NAME_LOCATION,
      AUTH_ID,
      TRANS_DESC,
      AMOUNT,
      PREAUTHAMOUNT,
      PARTIALAMOUNT,
      MCCODEGROUPID,
      CURRENCYCODEGROUPID,
      TRANSCODEGROUPID,
      RULES,
      PREAUTH_DATE,
      GL_UPD_FLAG,
      SYSTEM_TRACE_AUDIT_NO,
      INSTCODE,
      FEECODE,
      TRANFEE_AMT,
      SERVICETAX_AMT,
      CESS_AMT,
      CR_DR_FLAG,
      TRANFEE_CR_ACCTNO,
      TRANFEE_DR_ACCTNO,
      TRAN_ST_CALC_FLAG,
      TRAN_CESS_CALC_FLAG,
      TRAN_ST_CR_ACCTNO,
      TRAN_ST_DR_ACCTNO,
      TRAN_CESS_CR_ACCTNO,
      TRAN_CESS_DR_ACCTNO,
      CUSTOMER_CARD_NO_ENCR,
      TOPUP_CARD_NO_ENCR,
      ADDR_VERIFY_RESPONSE,
      PROXY_NUMBER,
      REVERSAL_CODE,
      CUSTOMER_ACCT_NO,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      INTERNATION_IND_RESPONSE,
      RESPONSE_ID,
      CARDSTATUS,
      NETWORK_ID,
      INTERCHANGE_FEEAMT,
      MERCHANT_ZIP,
      MERCHANT_ID,
      COUNTRY_CODE,

      FEE_PLAN,
      POS_VERIFICATION,
      FEEATTACHTYPE,
      acct_type,
      error_msg,
      time_stamp,

      partial_preauth_ind, -- Added for OLS changes
      add_ins_user,         -- Added for OLS changes
      NETWORKID_SWITCH,
      NETWORKID_ACQUIRER,
      NETWORK_SETTL_DATE,
      MERCHANT_NAME,
      MERCHANT_STATE,
      MERCHANT_CITY,

      CVV_VERIFICATIONTYPE,
      remark, --Added for error msg need to display in CSR(declined by rule)
      surchargefee_ind_ptc  --Added for VMS-5856
      )
    VALUES
     (P_MSG,
      P_RRN,
      P_DELIVERY_CHANNEL,
      P_TERM_ID,
      V_BUSINESS_DATE,
      P_TXN_CODE,
      V_TXN_TYPE,
      P_TXN_MODE,

      DECODE (P_ISO_RESPCDE, '00', 'C', 'F'),
      P_ISO_RESPCDE ,
      P_TRAN_DATE,
      P_TRAN_TIME,
      V_HASH_PAN,
      NULL,
      NULL,
      NULL,
      P_BANK_CODE,
      TRIM(TO_CHAR(nvl(V_TOTAL_AMT,0), '999999999999999990.99')),
      NULL,
      NULL,
      P_MCC_CODE,
      P_CURR_CODE,
      NULL,
      V_PROD_CODE,
      V_PROD_CATTYPE,
      nvl(P_TIP_AMT,'0.00'),
      P_DECLINE_RULEID,
      P_ATMNAME_LOC,
      V_AUTH_ID,
      V_TRANS_DESC,
      TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),
      P_MERC_CNTRYCODE,
      '0.00',
      P_MCCCODE_GROUPID,
      P_CURRCODE_GROUPID,
      P_TRANSCODE_GROUPID,
      P_RULES,
      NULL,
      V_GL_UPD_FLAG,
      P_STAN,
      P_INST_CODE,
      V_FEE_CODE,
      nvl(V_FEE_AMT,0),
      nvl(V_SERVICETAX_AMOUNT,0),
      nvl(V_CESS_AMOUNT,0),
   --  DECODE(v_preauth_type,'C','CR', V_DR_CR_FLAG),
   V_DR_CR_FLAG,--    --Modified for Mantis ID 15120
      V_FEE_CRACCT_NO,
      V_FEE_DRACCT_NO,
      V_ST_CALC_FLAG,
      V_CESS_CALC_FLAG,
      V_ST_CRACCT_NO,
      V_ST_DRACCT_NO,
      V_CESS_CRACCT_NO,
      V_CESS_DRACCT_NO,
      V_ENCR_PAN,
      NULL,
      P_ADDR_VERFY_RESPONSE, -- added for ols changes
      V_PROXUNUMBER,
      P_RVSL_CODE,
      V_ACCT_NUMBER,
      V_ACCT_BALANCE,
      V_LEDGER_BAL,
      P_INTERNATIONAL_IND,
      V_RESP_CDE,
      V_APPLPAN_CARDSTAT,

      P_NETWORK_ID,
      P_INTERCHANGE_FEEAMT,
      P_MERCHANT_ZIP,
      P_MERC_ID,
      P_COUNTRY_CODE,

      V_FEE_PLAN,
      P_POS_VERFICATION,
      V_FEEATTACH_TYPE ,
      v_acct_type,
      v_err_msg,
      nvl(v_timestamp,systimestamp),

      p_partial_preauth_ind,
      1,
      P_NETWORKID_SWITCH ,
      P_NETWORKID_ACQUIRER,
      p_network_setl_date,
      P_MERCHANT_NAME,
      P_ATMNAME_LOC,
      P_MERCHANT_CITY,

      NVL(P_CVV_VERIFICATIONTYPE,'N'),
      V_ERR_MSG, --Added for error msg need to display in CSR(declined by rule)
      DECODE(p_surchrg_ind,'2',NULL,p_surchrg_ind) --Added for VMS-5856
      );

    P_CAPTURE_DATE := V_BUSINESS_DATE;
    P_AUTH_ID      := V_AUTH_ID;
  EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK;
     P_RESP_CODE := '69'; -- Server Declione
     P_RESP_ID   := '69'; --Added for VMS-8018
     P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                 SUBSTR(SQLERRM, 1, 300);
  END;
  --En create a entry in txn log
     --SN added by Pankaj S. for DB time logging changes  
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

     P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 4: ' || v_mili ;
     P_RESP_TIME := v_mili;
     --EN added by Pankaj S. for DB time logging changes

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    P_RESP_CODE := '69'; -- Server Declined
    P_RESP_ID   := '69'; --Added for VMS-8018
    P_RESP_MSG  := 'Main exception from  authorization ' ||
                SUBSTR(SQLERRM, 1, 300);
END;
/
show error;