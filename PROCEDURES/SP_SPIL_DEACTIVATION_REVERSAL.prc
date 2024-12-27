create or replace
PROCEDURE        VMSCMS.SP_SPIL_DEACTIVATION_REVERSAL (P_INST_CODE           IN NUMBER,
                                               P_MSG_TYP             IN VARCHAR2,
                                               P_RVSL_CODE           IN VARCHAR2,
                                               P_RRN                 IN VARCHAR2,
                                               P_DELV_CHNL           IN VARCHAR2,
                                               P_TERMINAL_ID         IN VARCHAR2,
                                               P_MERC_ID             IN VARCHAR2,
                                               P_TXN_CODE            IN VARCHAR2,
                                               P_TXN_TYPE            IN VARCHAR2,
                                               P_TXN_MODE            IN VARCHAR2,
                                               P_BUSINESS_DATE       IN VARCHAR2,
                                               P_BUSINESS_TIME       IN VARCHAR2,
                                               P_CARD_NO             IN VARCHAR2,
                                               P_ACTUAL_AMT          IN NUMBER,
                                               P_BANK_CODE           IN VARCHAR2,
                                               P_STAN                IN VARCHAR2,
                                               P_EXPRY_DATE          IN VARCHAR2,
                                               P_TOCUST_CARD_NO      IN VARCHAR2,
                                               P_TOCUST_EXPRY_DATE   IN VARCHAR2,
                                               P_ORGNL_BUSINESS_DATE IN VARCHAR2,
                                               P_ORGNL_BUSINESS_TIME IN VARCHAR2,
                                               P_ORGNL_RRN           IN VARCHAR2,
                                               P_MBR_NUMB            IN VARCHAR2,
                                               P_ORGNL_TERMINAL_ID   IN VARCHAR2,
                                               P_CURR_CODE           IN VARCHAR2,
                                               P_Merchant_Name       In Varchar2,
                                               P_STORE_ID         In varchar2, --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
                                               P_RESP_CDE            OUT VARCHAR2,
                                               P_RESP_MSG            OUT VARCHAR2,
                                               P_RESP_MSG_M24        OUT VARCHAR2,
                                               P_ACCT_BAL            OUT VARCHAR2,
                                               p_POSTBACK_URL_OUT OUT VARCHAR2
                                               ) IS
  /*************************************************
     * Created Date     :  04-Apr-2012
     * Created By       :  Srinivasu
     * PURPOSE          :  For SPIL De-Activation  transaction
     * Modified By      :  Deepa T
     * Modified Date    :  17-Sep-2012
     * Modified Reason  : To change the length of Fee Attach Type
     * Reviewer         :  B.Besky Anand.
     * Reviewed Date    :  17-Sep-2012
     * Release Number     :  CMS3.5.1_RI0017
     
     * Modified by      :  Pankaj S.
     * Modified Reason  :  10871
     * Modified Date    :  18-Apr-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  
     * Build Number     :  RI0024.1_B0013
     
     * Modified by      : MageshKumar.S
     * Modified Date    : 21-Jun-13    
     * Modified For     : FSS-1248 
     * Modified reason  : reversal code logged in txnlog table
     * Reviewer         : Dhiraj 
     * Reviewed Date    : 21-Jun-13    
     * Build Number     : RI0024.2_B0008

      * Modified By      : Santosh P
      * Modified Date    : 12-Jul-2013
      * Modified Reason  : Capture StoreId in transactionlog table
      * Modified for     : FSS-1146 
      * Reviewer         : 
      * Reviewed Date    : 
      * Build Number     : RI0024.3_B0005
      
      * Modified by      : Sachin P.  
      * Modified for     : Mantis Id -11693 
      * Modified Reason  : CR_DR_FLAG in transactionlog table is incorrectly inserted for the Reversal 
                           Transactions(Original transaction's CR_DR flag is inserted)               
      * Modified Date    : 25-Jul-2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19-aug-2013
      * Build Number     : RI0024.4_B0002  
      
      * Modified by      : Sachin P.
      * Modified for     : Mantis Id:11695
                            Mantis Id:11872  
      * Modified Reason  : 11695 :-Reversal Fee details(FeePlan id,FeeCode,Fee amount 
                           and FeeAttach Type) are not logged in transactionlog 
                           table. 
                           11872:-Transactions reversal fee is not debited
      * Modified Date     : 01.08.2013
      * Reviewer          : Dhiraj
      * Reviewed Date     : 19-aug-2013
      * Build Number      : RI0024.4_B0002  
      
      * Modified by       : SIVA ARCOT.
      * Modified for      : Mantis Id:10997 & FWR-11                         
      * Modified Reason   : Handle for Partial reversal Transaction
      * Modified Date     : 11.09.2013
      * Reviewer          : Dhiraj
      * Reviewed Date     : 11.09.2013
      * Build Number      : RI0024.4_B0010 

      * Modified By      : Anil Kumar
      * Modified Date    : 16-SEP-2013
      * Modified Reason  : To Update The Inventory Card Current Stock
      * Modified for     : DFCHOST-345
      * Reviewer         : SAGAR
      * Reviewed Date    : 16-SEP-2013
      * Build Number     : RI0024.4_B0015
      
      * Modified By      : Sai prasad
      * Modified Date    : 23-SEP-2013
      * Modified Reason  : To Cover DFCHOST 345 Review comments
      * Modified for     : DFCHOST-345 (Review)
      * Reviewer         : Dhiraj
      * Reviewed Date    : 23-SEP-2013
      * Build Number     : RI0024.4_B0018      
      
      * Modified by       : Deepa T
      * Modified for      : Mantis ID- 13632                      
      * Modified Reason   : To include the success response code in the Redemption transaction check
      * Modified Date     : 07.Feb.2014
      * Reviewer          : Dhiraj
      * Reviewed Date     : 07.Feb.2014
      * Build Number      : Ri0024.6.6      
      
      * Modified Date    : 31-Jan-2014
      * Modified By      : Sagar More
      * Modified for     : Met-23 - Spil_3.0
      * Modified reason  : msgtype 1200 checked in query to find original transaction                          
      * Reviewer         : Dhiraj 
      * Reviewed Date    : 31-Jan-2014
      * Release Number   : RI0027.1_B0001    
      
      * Modified by       : DHINAKARAN B
      * Modified for      : DFCHOST-344             
      * Modified Date     : 5-MAR-2014
      * Reviewer          : Dhiraj
      * Reviewed Date     : 5-MAR-2014
      * Build Number      : RI0027.2_B0001    
           
      * Modified by       : Pankaj S.
      * Modified for      : Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)         
      * Modified Date     : 24-MAR-2014
      * Reviewer          : Dhiraj
      * Reviewed Date     : 07-April-2014
      * Build Number      : RI0027.2_B0004

      * Modified by       : MageshKumar S.
      * Modified Date     : 25-July-14
      * Modified For      : FWR-48
      * Modified reason   : GL Mapping removal changes
      * Reviewer          : Spankaj
      * Build Number      : RI0027.3.1_B0001

      * Modified by       : MageshKumar.S
      * Modified Date     : 26-August-14
      * Modified For      : FSS-1802
      * Modified reason   : For SPIL revdeact duplicate attempt needs to echo back of original rvsl
      * Build Number      : RI0027.3.2_B0002
      
      * Modified Date     : 29-SEP-2014
      * Modified By       : Abdul Hameed M.A
      * Modified for      : FWR 70
      * Reviewer          : Spankaj
      * Release Number    : RI0027.4_B0002
      
      * Modified by       : MageshKumar.S
      * Modified Date     : 10-Oct-14
      * Modified For      : FSS-1856
      * Modified reason   : For SPIL revdeact duplicate attempt needs to echo back of original rvsl
      * Build Number      : RI0027.4_B0002
      
     * Modified by       : Siva Kumar M
    * Modified Date     : 05-Aug-15
    * Modified For      : FSS-2320
    * Reviewer          : Pankaj S
    * Build Number      : RVMSGPRHOSTCSD_3.1_B0001
    
     * Modified Date         : 07-June-2016
     * Modified By           : Ramesh A
     * Modified for          : Closed Loop Changes
     * Reviewer              : Saravanakumar
     * Release Number        : 4.2_B0001    
     
     * Modified By          :  Pankaj S.
     * Modified Date      :  12-Sep-2016
     * Modified Reason  : Modified for 4.2.2 changes
     * Reviewer              : Saravanakumar
     * Build Number      :   4.2.2 
     
     * Modified by          : Spankaj
     * Modified Date        : 21-Nov-2016
     * Modified For         :FSS-4762:VMS OTC Support for Instant Payroll Card
     * Reviewer             : Saravanakumar
     * Build Number         : VMSGPRHOSTCSD4.11
     
         * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
    
   * Modified By      :Pankaj S.
   * Modified Date    : 24/10/2017
   * Purpose          : FSS-5302:Retail Activation of Anonymous Products 
   * Reviewer         : Saravanan 
   * Release Number   : VMSGPRHOST17.10
   
   * Modified By      : DHINAKARAN B
   * Modified Date    : 09/01/2018
   * Purpose          : VMS-161
   * Reviewer         : Saravanan
   * Release Number   : VMSGPRHOST17.12.1 
     
   * Modified By      : BASKAR K
   * Modified Date    : 21/08/2020
   * Purpose          : VMS-2929
   * Reviewer         : Saravanan
   * Release Number   : VMSGPRHOST_R35_B0001  
   
   * Modified By      : Karthick
    * Modified Date    : 06-28-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST65 for VMS-5739/FSP-991
  *************************************************/
  V_ORGNL_DELIVERY_CHANNEL   TRANSACTIONLOG.DELIVERY_CHANNEL%TYPE;
  V_ORGNL_RESP_CODE          TRANSACTIONLOG.RESPONSE_CODE%TYPE;
  V_ORGNL_TERMINAL_ID        TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_ORGNL_TXN_CODE           TRANSACTIONLOG.TXN_CODE%TYPE;
  V_ORGNL_TXN_TYPE           TRANSACTIONLOG.TXN_TYPE%TYPE;
  V_ORGNL_TXN_MODE           TRANSACTIONLOG.TXN_MODE%TYPE;
  V_ORGNL_BUSINESS_DATE      TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  V_ORGNL_BUSINESS_TIME      TRANSACTIONLOG.BUSINESS_TIME%TYPE;
  V_ORGNL_CUSTOMER_CARD_NO   TRANSACTIONLOG.CUSTOMER_CARD_NO%TYPE;
  V_ORGNL_TOTAL_AMOUNT       TRANSACTIONLOG.AMOUNT%TYPE;
  V_ACTUAL_AMT               NUMBER(9, 2);
  V_REVERSAL_AMT             NUMBER(9, 2);
  V_ORGNL_TXN_FEECODE        CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  --V_ORGNL_TXN_FEEATTACHTYPE  VARCHAR2(1);
  V_ORGNL_TXN_FEEATTACHTYPE  TRANSACTIONLOG.FEEATTACHTYPE%TYPE;--Modified by Deepa on sep-17-2012
  V_ORGNL_TXN_TOTALFEE_AMT   TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  V_ORGNL_TXN_SERVICETAX_AMT TRANSACTIONLOG.SERVICETAX_AMT%TYPE;
  V_ORGNL_TXN_CESS_AMT       TRANSACTIONLOG.CESS_AMT%TYPE;
  V_ORGNL_TRANSACTION_TYPE   TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ACTUAL_DISPATCHED_AMT    TRANSACTIONLOG.AMOUNT%TYPE;
  V_RESP_CDE                 VARCHAR2(3);
  V_FUNC_CODE                CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_DR_CR_FLAG               TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ORGNL_TRANDATE           DATE;
  V_RVSL_TRANDATE            DATE;
  V_ORGNL_TERMID             TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_ORGNL_MCCCODE            TRANSACTIONLOG.MCCODE%TYPE;
  V_ERRMSG                   VARCHAR2(300):='OK'; --Modified for 10871
  V_ACTUAL_FEECODE           TRANSACTIONLOG.FEECODE%TYPE;
  V_ORGNL_TRANFEE_AMT        TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  V_ORGNL_SERVICETAX_AMT     TRANSACTIONLOG.SERVICETAX_AMT%TYPE;
  V_ORGNL_CESS_AMT           TRANSACTIONLOG.CESS_AMT%TYPE;
  V_ORGNL_CR_DR_FLAG         TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ORGNL_TRANFEE_CR_ACCTNO  TRANSACTIONLOG.TRANFEE_CR_ACCTNO%TYPE;
  V_ORGNL_TRANFEE_DR_ACCTNO  TRANSACTIONLOG.TRANFEE_DR_ACCTNO%TYPE;
  V_ORGNL_ST_CALC_FLAG       TRANSACTIONLOG.TRAN_ST_CALC_FLAG%TYPE;
  V_ORGNL_CESS_CALC_FLAG     TRANSACTIONLOG.TRAN_CESS_CALC_FLAG%TYPE;
  V_ORGNL_ST_CR_ACCTNO       TRANSACTIONLOG.TRAN_ST_CR_ACCTNO%TYPE;
  V_ORGNL_ST_DR_ACCTNO       TRANSACTIONLOG.TRAN_ST_DR_ACCTNO%TYPE;
  V_ORGNL_CESS_CR_ACCTNO     TRANSACTIONLOG.TRAN_CESS_CR_ACCTNO%TYPE;
  V_ORGNL_CESS_DR_ACCTNO     TRANSACTIONLOG.TRAN_CESS_DR_ACCTNO%TYPE;
  V_PROD_CODE                CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE                CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_GL_UPD_FLAG              TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_TRAN_REVERSE_FLAG        TRANSACTIONLOG.TRAN_REVERSE_FLAG%TYPE;
  V_SAVEPOINT                NUMBER DEFAULT 1;
  V_CURR_CODE                TRANSACTIONLOG.CURRENCYCODE%TYPE;
  V_AUTH_ID                  TRANSACTIONLOG.AUTH_ID%TYPE;
  V_CUTOFF_TIME              VARCHAR2(5);
  V_BUSINESS_TIME            VARCHAR2(5);
  EXP_RVSL_REJECT_RECORD EXCEPTION;
  V_ATM_USAGEAMNT      CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT      CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  V_CARD_ACCT_NO       VARCHAR2(20);
  V_TRAN_SYSDATE       DATE;
  V_TRAN_CUTOFF        DATE;
  V_HASH_PAN           CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_TRAN_AMT           NUMBER;
  V_DELCHANNEL_CODE    VARCHAR2(2);
  V_CARD_CURR          VARCHAR2(5);
  V_RRN_COUNT          NUMBER;
  V_BASE_CURR          CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CURRCODE           VARCHAR2(3);
  V_ACCT_BALANCE       NUMBER;
  V_TRAN_DESC          CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
  V_ATM_USAGELIMIT     CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT     CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_BUSINESS_DATE_TRAN DATE;
  V_ORGNL_TXN_AMNT     TRANSACTIONLOG.AMOUNT%TYPE;
  V_MMPOS_USAGEAMNT    CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
  V_TXNCNT_AFTERTOPUP  NUMBER;
  V_LEDGER_BALANCE     NUMBER;
  --V_AUTHID_DATE          VARCHAR2(8);
  V_TXN_NARRATION       CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_FEE_NARRATION       CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_CAP_CARD_STAT       CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_FIRSTTIME_TOPUP CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_CAP_MBR_NUMB        CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_TRANCOUNT           VARCHAR2(10);
  --Added by Deepa for the changes to include Merchant name,city and state in statements log
  V_TXN_MERCHNAME  CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_FEE_MERCHNAME  CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_TXN_MERCHCITY  CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_FEE_MERCHCITY  CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_TXN_MERCHSTATE CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;
  V_FEE_MERCHSTATE CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;
  --Sn added by Pankaj S. for 10871 
  v_timestamp    timestamp(3);
  v_acct_type    cms_acct_mast.cam_type_code%TYPE;
  --En added by Pankaj S. for 10871
  V_TXN_TYPE          NUMBER(1); -- added by MageshKumar.S for defect Id: Fss-1248 on 21-06-2013
    --SN  Added on 01.08.2013 for 11872  
  V_TRAN_DATE DATE;  
  V_FEE_PLAN  CMS_FEE_PLAN.CFP_PLAN_ID%TYPE;
  V_FEE_AMT   NUMBER;
  --EN  Added on 01.08.2013 for 11872
  V_FEE_CODE           CMS_FEE_MAST.CFM_FEE_CODE%TYPE; --Added on 01.08.2013 for 11695
  V_FEEATTACH_TYPE     VARCHAR2(2); --Added on 01.08.2013 for 11695
    V_ORGNL_TXN_FEE_PLAN     TRANSACTIONLOG.FEE_PLAN%TYPE; --Added for FWR-11
  v_feecap_flag VARCHAR2(1); --Added for FWR-11
  v_orgnl_fee_amt  CMS_FEE_MAST.CFM_FEE_AMT%TYPE; --Added for FWR-11
  V_REVERSAL_AMT_FLAG VARCHAR2(1) :='F';  ---Added for Mantis Id-0010997
  
  --SN Added for DFCHOST-345
  V_Cmm_Merprodcat_Id Cms_Merinv_Merpan.Cmm_Merprodcat_Id%Type;
  V_ERR_SET           NUMBER(2) := 0;
  V_CMM_MER_ID        CMS_MERINV_MERPAN.CMM_MER_ID%TYPE;
  V_CMM_LOCATION_ID   CMS_MERINV_MERPAN.CMM_LOCATION_ID%TYPE;
  --EN Added for DFCHOST-345
  
  v_cap_acct_id               CMS_APPL_PAN.CAP_ACCT_ID%TYPE; 
  v_cap_cust_code             CMS_APPL_PAN.CAP_CUST_CODE%TYPE; 
  v_gpr_pan                   CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  v_gpr_encr_pan              CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  v_gpr_chk                    VARCHAR2(1); 
  v_pin_ofst                  CMS_CARDISS_PIN_HIST.CCP_PIN_OFF%TYPE;
  v_deact_cardstat            TRANSACTIONLOG.CARDSTATUS%TYPE;  
  v_cardstat_txncode          TRANSACTIONLOG.TXN_CODE%TYPE;    
  
  --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)  
   v_comb_hash              pkg_limits_check.type_hash;
   v_tran_type              cms_transaction_mast.ctm_tran_type%TYPE;
   v_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
   v_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
   --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)  
   
   V_DUPCHK_CARDSTAT TRANSACTIONLOG.CARDSTATUS%TYPE; -- added for handling duplicate request echo back
   V_DUPCHK_ACCTBAL  TRANSACTIONLOG.ACCT_BALANCE%TYPE; -- added for handling duplicate request echo back
   V_DUPCHK_COUNT    NUMBER; -- added for handling duplicate request echo back
   v_dupl_flag number DEFAULT 0; -- added for handling duplicate request echo back
  
  --SN Added for FWR 70
   V_STARTER_CANADA varchar2(1):='N';
   V_CURRENCY_CODE  varchar2(3);
    V_PROFILE_CODE      CMS_PROD_CATTYPE.CPC_PROFILE_CODE%type;
    --EN Added for FWR 70
    
   --SN Added for 4.2 CL changes
  --V_PROD_TYPE     CMS_PRODUCT_PARAM.CPP_PRODUCT_TYPE%TYPE;
  V_UPD_CARD_STAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE; 
  V_APPL_CODE     CMS_APPL_PAN.CAP_APPL_CODE%TYPE;
  V_PROXUNUMBER        CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  --EN Added for 4.2 CL changes
  v_retail_activation  cms_prod_cattype.cpc_retail_activation%TYPE;
  v_cap_old_cardstat cms_appl_pan.cap_old_cardstat%type;
  v_b2b_cardFlag varchar2(10)  :='N';
  v_product_funding      CMS_PROD_CATTYPE.CPC_PRODUCT_FUNDING%TYPE;
  v_prod_fund            CMS_PROD_CATTYPE.CPC_PRODUCT_FUNDING%TYPE;
  v_order_prod_fund       vms_order_lineitem.VOL_PRODUCT_FUNDING%TYPE;
  
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN

  P_RESP_CDE := '00';
  P_RESP_MSG := 'OK';
  p_POSTBACK_URL_OUT :='0~0~0~0~0~0';
  SAVEPOINT V_SAVEPOINT;

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --EN create encr pan

   --Sn find the type of  txn detail
   BEGIN
      SELECT  ctm_credit_debit_flag,ctm_tran_desc,DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1') -- Modified by MageshKumar.S for defect Id:FSS-1248
        INTO  v_dr_cr_flag,v_tran_desc,  --v_dr_cr_flag added by Pankaj S. for 10871
        V_TXN_TYPE -- Modified by MageshKumar.S for defect Id:FSS-1248,value is passed as NULL
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delv_chnl
         AND ctm_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         v_errmsg :=
               'Transaction detail is not found in master for orginal txn code'
            || p_txn_code
            || 'delivery channel '
            || p_delv_chnl;
         RAISE exp_rvsl_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_errmsg :=
               'Problem while selecting debit/credit flag '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_rvsl_reject_record;
   END;

   --Sn Added on 03-Apr-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
  IF P_TXN_CODE in ('28','29') then 

            BEGIN
               SELECT ctm_tran_type,ctm_prfl_flag
                 INTO v_tran_type,v_prfl_flag
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = '26'
                  AND ctm_delivery_channel = p_delv_chnl
                  AND ctm_inst_code = p_inst_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_resp_cde := '21';                          --Ineligible Transaction
                  v_errmsg :=
                        'Transflag  not defined for txn code '
                     || '26'
                     || ' and delivery channel '
                     || p_delv_chnl;
                  RAISE exp_rvsl_reject_record;
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';                            --Ineligible Transaction
                  v_errmsg := 'Error while selecting transaction details';
                  RAISE exp_rvsl_reject_record;
            END;
  
  END IF;  
  --En Added on 03-Apr-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)

  BEGIN

    V_RVSL_TRANDATE := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8),
                         'yyyymmdd');
    
  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '45';
     V_ERRMSG   := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --Sn get date
  BEGIN

    V_RVSL_TRANDATE := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8) || ' ' ||
                         SUBSTR(TRIM(P_BUSINESS_TIME), 1, 8),
                         'yyyymmdd hh24:mi:ss');
     V_TRAN_DATE     := V_RVSL_TRANDATE; --Added on 01.08.2013 for 11872
  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '32';
     V_ERRMSG   := 'Problem while converting transaction Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En get date


  --Sn generate auth id
  BEGIN
    -- SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

    --    SELECT TO_CHAR(SYSDATE, 'YYYYMMDD')  || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
    SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while generating authid ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21'; -- Server Declined
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En generate auth id

  BEGIN
    SELECT CAP_CARD_STAT,
         CAP_FIRSTTIME_TOPUP,
         CAP_MBR_NUMB,
         CAP_PROD_CODE,
         CAP_CARD_TYPE,
         cap_acct_no  --added for 10871
         ,cap_acct_id,cap_cust_code,
         cap_prfl_code, --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
         CAP_APPL_CODE, -- Added for 4.2 CL changes
         CAP_PROXY_NUMBER -- Added for 4.2 CL changes
         ,cap_old_cardstat
     INTO V_CAP_CARD_STAT,
         V_CAP_FIRSTTIME_TOPUP,
         V_CAP_MBR_NUMB,
         V_PROD_CODE,
         V_CARD_TYPE,
         v_card_acct_no --added for 10871
         ,v_cap_acct_id, v_cap_cust_code,
         v_prfl_code, --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
         V_APPL_CODE, -- Added for 4.2 CL changes
         V_PROXUNUMBER -- Added for 4.2 CL changes
         ,v_cap_old_cardstat
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
    BEGIN
  SELECT DECODE(UPPER(VOD_POSTBACK_RESPONSE),'TRUE','1','1','1','0')
    ||'~'
    ||VLI_ORDER_ID
    ||'~'
    ||VLI_LINEITEM_ID
    ||'~'
    ||vod_partner_id
    ||'~'
    ||NVL(VOD_POSTBACK_URL,'0')
    ||'~'
    ||vod_channel_id,VOL_PRODUCT_FUNDING
  INTO p_POSTBACK_URL_OUT,v_order_prod_fund
  FROM vms_order_details,
    vms_line_item_dtl,
    vms_order_lineitem
  WHERE VOD_ORDER_ID=vli_order_id
  AND VOD_PARTNER_ID=VLI_PARTNER_ID
  AND VOD_ORDER_ID=vol_order_id
  AND VOD_PARTNER_ID=Vol_PARTNER_ID
  AND VOL_LINE_ITEM_ID=VLI_LINEITEM_ID
  AND vli_pan_code  =V_HASH_PAN;
 v_b2b_cardFlag   :='Y';
EXCEPTION
WHEN OTHERS THEN
  NULL;
  END;

  --Sn Getting the Currency cod efor the Currency name from Request

  BEGIN

    SELECT GCM_CURR_CODE
     INTO V_CURRCODE
     FROM GEN_CURR_MAST
    WHERE GCM_CURR_NAME = P_CURR_CODE AND GCM_INST_CODE = P_INST_CODE;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN

     V_RESP_CDE := '65';
     V_ERRMSG   := 'Invalid Currency Code';
     RAISE EXP_RVSL_REJECT_RECORD;

    WHEN OTHERS THEN

     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting the currency code for ' ||
                P_CURR_CODE || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

  END;

  --En Getting the Currency cod efor the Currency name from Request

  --Sn check msg type

  IF (P_MSG_TYP NOT IN ('0400', '0410', '0420', '0430','1400')) OR
    (P_RVSL_CODE = '00') THEN
    V_RESP_CDE := '12';
    V_ERRMSG   := 'Not a valid reversal request';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;

  --En check msg type

  --Sn check orginal transaction    (-- Amount is missing in reversal request)
  BEGIN
    SELECT DELIVERY_CHANNEL,
         TERMINAL_ID,
         RESPONSE_CODE,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         AMOUNT, --Transaction amount
         FEECODE,
          FEE_PLAN, --Added for FWR-11
         FEEATTACHTYPE, -- card level / prod cattype level
         TRANFEE_AMT, --Tranfee  Total    amount
         SERVICETAX_AMT, --Tran servicetax amount
         CESS_AMT, --Tran cess amount
         CR_DR_FLAG,
         TERMINAL_ID,
         MCCODE,
         FEECODE,
         TRANFEE_AMT,
         SERVICETAX_AMT,
         CESS_AMT,
         TRANFEE_CR_ACCTNO,
         TRANFEE_DR_ACCTNO,
         TRAN_ST_CALC_FLAG,
         TRAN_CESS_CALC_FLAG,
         TRAN_ST_CR_ACCTNO,
         TRAN_ST_DR_ACCTNO,
         TRAN_CESS_CR_ACCTNO,
         TRAN_CESS_DR_ACCTNO,
         CURRENCYCODE,
         TRAN_REVERSE_FLAG,
         GL_UPD_FLAG,
         AMOUNT
         ,cardstatus
     INTO V_ORGNL_DELIVERY_CHANNEL,
         V_ORGNL_TERMINAL_ID,
         V_ORGNL_RESP_CODE,
         V_ORGNL_TXN_CODE,
         V_ORGNL_TXN_TYPE,
         V_ORGNL_TXN_MODE,
         V_ORGNL_BUSINESS_DATE,
         V_ORGNL_BUSINESS_TIME,
         V_ORGNL_CUSTOMER_CARD_NO,
         V_ORGNL_TOTAL_AMOUNT,
         V_ORGNL_TXN_FEECODE,
          V_ORGNL_TXN_FEE_PLAN, --Added for FWR-11
         V_ORGNL_TXN_FEEATTACHTYPE,
         V_ORGNL_TXN_TOTALFEE_AMT,
         V_ORGNL_TXN_SERVICETAX_AMT,
         V_ORGNL_TXN_CESS_AMT,
         V_ORGNL_TRANSACTION_TYPE,
         V_ORGNL_TERMID,
         V_ORGNL_MCCCODE,
         V_ACTUAL_FEECODE,
         V_ORGNL_TRANFEE_AMT,
         V_ORGNL_SERVICETAX_AMT,
         V_ORGNL_CESS_AMT,
         V_ORGNL_TRANFEE_CR_ACCTNO,
         V_ORGNL_TRANFEE_DR_ACCTNO,
         V_ORGNL_ST_CALC_FLAG,
         V_ORGNL_CESS_CALC_FLAG,
         V_ORGNL_ST_CR_ACCTNO,
         V_ORGNL_ST_DR_ACCTNO,
         V_ORGNL_CESS_CR_ACCTNO,
         V_ORGNL_CESS_DR_ACCTNO,
         V_CURR_CODE,
         V_TRAN_REVERSE_FLAG,
         V_GL_UPD_FLAG,
         V_ORGNL_TXN_AMNT
         ,v_deact_cardstat
     FROM VMSCMS.TRANSACTIONLOG   --Added for VMS-5739/FSP-991
    WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
         INSTCODE = P_INST_CODE AND MSGTYPE IN ('0200','1200') AND  -- Msgtype 1200 added for Spil_3.0
         TXN_CODE IN ('28', '36') --Transaction code 28 is deactivation trancode 
         AND RESPONSE_CODE = '00' -- Added for FSS-1856
         AND DELIVERY_CHANNEL = P_DELV_CHNL;
		 	IF SQL%ROWCOUNT = 0 THEN
			SELECT DELIVERY_CHANNEL,
         TERMINAL_ID,
         RESPONSE_CODE,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         AMOUNT, --Transaction amount
         FEECODE,
          FEE_PLAN, --Added for FWR-11
         FEEATTACHTYPE, -- card level / prod cattype level
         TRANFEE_AMT, --Tranfee  Total    amount
         SERVICETAX_AMT, --Tran servicetax amount
         CESS_AMT, --Tran cess amount
         CR_DR_FLAG,
         TERMINAL_ID,
         MCCODE,
         FEECODE,
         TRANFEE_AMT,
         SERVICETAX_AMT,
         CESS_AMT,
         TRANFEE_CR_ACCTNO,
         TRANFEE_DR_ACCTNO,
         TRAN_ST_CALC_FLAG,
         TRAN_CESS_CALC_FLAG,
         TRAN_ST_CR_ACCTNO,
         TRAN_ST_DR_ACCTNO,
         TRAN_CESS_CR_ACCTNO,
         TRAN_CESS_DR_ACCTNO,
         CURRENCYCODE,
         TRAN_REVERSE_FLAG,
         GL_UPD_FLAG,
         AMOUNT
         ,cardstatus
     INTO V_ORGNL_DELIVERY_CHANNEL,
         V_ORGNL_TERMINAL_ID,
         V_ORGNL_RESP_CODE,
         V_ORGNL_TXN_CODE,
         V_ORGNL_TXN_TYPE,
         V_ORGNL_TXN_MODE,
         V_ORGNL_BUSINESS_DATE,
         V_ORGNL_BUSINESS_TIME,
         V_ORGNL_CUSTOMER_CARD_NO,
         V_ORGNL_TOTAL_AMOUNT,
         V_ORGNL_TXN_FEECODE,
          V_ORGNL_TXN_FEE_PLAN, --Added for FWR-11
         V_ORGNL_TXN_FEEATTACHTYPE,
         V_ORGNL_TXN_TOTALFEE_AMT,
         V_ORGNL_TXN_SERVICETAX_AMT,
         V_ORGNL_TXN_CESS_AMT,
         V_ORGNL_TRANSACTION_TYPE,
         V_ORGNL_TERMID,
         V_ORGNL_MCCCODE,
         V_ACTUAL_FEECODE,
         V_ORGNL_TRANFEE_AMT,
         V_ORGNL_SERVICETAX_AMT,
         V_ORGNL_CESS_AMT,
         V_ORGNL_TRANFEE_CR_ACCTNO,
         V_ORGNL_TRANFEE_DR_ACCTNO,
         V_ORGNL_ST_CALC_FLAG,
         V_ORGNL_CESS_CALC_FLAG,
         V_ORGNL_ST_CR_ACCTNO,
         V_ORGNL_ST_DR_ACCTNO,
         V_ORGNL_CESS_CR_ACCTNO,
         V_ORGNL_CESS_DR_ACCTNO,
         V_CURR_CODE,
         V_TRAN_REVERSE_FLAG,
         V_GL_UPD_FLAG,
         V_ORGNL_TXN_AMNT
         ,v_deact_cardstat
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST   --Added for VMS-5739/FSP-991
    WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
         INSTCODE = P_INST_CODE AND MSGTYPE IN ('0200','1200') AND  -- Msgtype 1200 added for Spil_3.0
         TXN_CODE IN ('28', '36') --Transaction code 28 is deactivation trancode 
         AND RESPONSE_CODE = '00' -- Added for FSS-1856
         AND DELIVERY_CHANNEL = P_DELV_CHNL;
			END IF;
    IF V_ORGNL_RESP_CODE <> '00' THEN
     V_RESP_CDE := '23';
     V_ERRMSG   := ' The original transaction was not successful';
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;

    IF V_TRAN_REVERSE_FLAG = 'Y' THEN -- Modified by MageshKumar.S for defect Id:FSS-1248
    --Sn - added for handling duplicate request echo back - Fss-1802
    begin
        SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS.TRANSACTIONLOG   --Added for VMS-5739/FSP-991
                WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                DELIVERY_CHANNEL = P_DELV_CHNL
                and ACCT_BALANCE is not null
                order by add_ins_date desc)
        where rownum=1;
		IF SQL%ROWCOUNT = 0 THEN
		    SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5739/FSP-991
                WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                DELIVERY_CHANNEL = P_DELV_CHNL
                and ACCT_BALANCE is not null
                order by add_ins_date desc)
        where rownum=1;
		END IF;

        V_DUPCHK_COUNT:=1;
    exception
        when no_data_found then
            V_DUPCHK_COUNT:=0;
        when others then
            V_RESP_CDE := '21';
            V_ERRMSG   := 'Error while selecting card status and acct balance ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_RVSL_REJECT_RECORD;
    end;

    if V_DUPCHK_COUNT =1 then
        BEGIN
            SELECT CAM_ACCT_BAL
            INTO V_ACCT_BALANCE
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO = v_card_acct_no
                                /*(SELECT CAP_ACCT_NO  FROM CMS_APPL_PAN
                                WHERE CAP_PAN_CODE = V_HASH_PAN
                                AND CAP_MBR_NUMB = P_MBR_NUMB
                                AND CAP_INST_CODE = P_INST_CODE)*/
                                AND
            CAM_INST_CODE = P_INST_CODE;
            
        EXCEPTION
            WHEN OTHERS THEN
                V_RESP_CDE := '12';
                V_ERRMSG   := 'Error while selecting acct balance ' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_RVSL_REJECT_RECORD;
        END;


        V_DUPCHK_COUNT:=0;
            
                   
        if V_DUPCHK_CARDSTAT= V_CAP_CARD_STAT and V_DUPCHK_ACCTBAL=V_ACCT_BALANCE then
            V_DUPCHK_COUNT:=1;
            v_dupl_flag:=1;
            V_RESP_CDE := '52';
            V_ERRMSG   := 'Reversal/Deactivation  already done';
            RAISE EXP_RVSL_REJECT_RECORD;
        end if;
        
    end if; 
    -- V_RESP_CDE := '52';
    -- V_ERRMSG   := 'Reversal/Deactivation  alreday done';
    -- RAISE EXP_RVSL_REJECT_RECORD;
    END IF;
--En - added for handling duplicate request echo back - Fss-1802
     

  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '53';
     V_ERRMSG   := 'Matching transaction not found';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN TOO_MANY_ROWS THEN
     BEGIN
       SELECT DELIVERY_CHANNEL,
            TERMINAL_ID,
            RESPONSE_CODE,
            TXN_CODE,
            TXN_TYPE,
            TXN_MODE,
            BUSINESS_DATE,
            BUSINESS_TIME,
            CUSTOMER_CARD_NO,
            AMOUNT, --Transaction amount
            FEECODE,
            FEEATTACHTYPE, -- card level / prod cattype level
            TRANFEE_AMT, --Tranfee  Total    amount
            SERVICETAX_AMT, --Tran servicetax amount
            CESS_AMT, --Tran cess amount
            CR_DR_FLAG,
            TERMINAL_ID,
            MCCODE,
            FEECODE,
            TRANFEE_AMT,
            SERVICETAX_AMT,
            CESS_AMT,
            TRANFEE_CR_ACCTNO,
            TRANFEE_DR_ACCTNO,
            TRAN_ST_CALC_FLAG,
            TRAN_CESS_CALC_FLAG,
            TRAN_ST_CR_ACCTNO,
            TRAN_ST_DR_ACCTNO,
            TRAN_CESS_CR_ACCTNO,
            TRAN_CESS_DR_ACCTNO,
            CURRENCYCODE,
            TRAN_REVERSE_FLAG,
            GL_UPD_FLAG,
            AMOUNT
            ,cardstatus
        INTO V_ORGNL_DELIVERY_CHANNEL,
            V_ORGNL_TERMINAL_ID,
            V_ORGNL_RESP_CODE,
            V_ORGNL_TXN_CODE,
            V_ORGNL_TXN_TYPE,
            V_ORGNL_TXN_MODE,
            V_ORGNL_BUSINESS_DATE,
            V_ORGNL_BUSINESS_TIME,
            V_ORGNL_CUSTOMER_CARD_NO,
            V_ORGNL_TOTAL_AMOUNT,
            V_ORGNL_TXN_FEECODE,
            V_ORGNL_TXN_FEEATTACHTYPE,
            V_ORGNL_TXN_TOTALFEE_AMT,
            V_ORGNL_TXN_SERVICETAX_AMT,
            V_ORGNL_TXN_CESS_AMT,
            V_ORGNL_TRANSACTION_TYPE,
            V_ORGNL_TERMID,
            V_ORGNL_MCCCODE,
            V_ACTUAL_FEECODE,
            V_ORGNL_TRANFEE_AMT,
            V_ORGNL_SERVICETAX_AMT,
            V_ORGNL_CESS_AMT,
            V_ORGNL_TRANFEE_CR_ACCTNO,
            V_ORGNL_TRANFEE_DR_ACCTNO,
            V_ORGNL_ST_CALC_FLAG,
            V_ORGNL_CESS_CALC_FLAG,
            V_ORGNL_ST_CR_ACCTNO,
            V_ORGNL_ST_DR_ACCTNO,
            V_ORGNL_CESS_CR_ACCTNO,
            V_ORGNL_CESS_DR_ACCTNO,
            V_CURR_CODE,
            V_TRAN_REVERSE_FLAG,
            V_GL_UPD_FLAG,
            V_ORGNL_TXN_AMNT
            ,v_deact_cardstat
        FROM VMSCMS.TRANSACTIONLOG                  --Added for VMS-5739/FSP-991
        WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
            INSTCODE = P_INST_CODE AND RESPONSE_CODE = '00' AND 
            MSGTYPE IN ('0200','1200') AND TXN_CODE IN('28','36') AND -- Msgtype 1200 added for Spil_3.0
            DELIVERY_CHANNEL = P_DELV_CHNL;
			 IF SQL%ROWCOUNT = 0 THEN
			 SELECT DELIVERY_CHANNEL,
            TERMINAL_ID,
            RESPONSE_CODE,
            TXN_CODE,
            TXN_TYPE,
            TXN_MODE,
            BUSINESS_DATE,
            BUSINESS_TIME,
            CUSTOMER_CARD_NO,
            AMOUNT, --Transaction amount
            FEECODE,
            FEEATTACHTYPE, -- card level / prod cattype level
            TRANFEE_AMT, --Tranfee  Total    amount
            SERVICETAX_AMT, --Tran servicetax amount
            CESS_AMT, --Tran cess amount
            CR_DR_FLAG,
            TERMINAL_ID,
            MCCODE,
            FEECODE,
            TRANFEE_AMT,
            SERVICETAX_AMT,
            CESS_AMT,
            TRANFEE_CR_ACCTNO,
            TRANFEE_DR_ACCTNO,
            TRAN_ST_CALC_FLAG,
            TRAN_CESS_CALC_FLAG,
            TRAN_ST_CR_ACCTNO,
            TRAN_ST_DR_ACCTNO,
            TRAN_CESS_CR_ACCTNO,
            TRAN_CESS_DR_ACCTNO,
            CURRENCYCODE,
            TRAN_REVERSE_FLAG,
            GL_UPD_FLAG,
            AMOUNT
            ,cardstatus
        INTO V_ORGNL_DELIVERY_CHANNEL,
            V_ORGNL_TERMINAL_ID,
            V_ORGNL_RESP_CODE,
            V_ORGNL_TXN_CODE,
            V_ORGNL_TXN_TYPE,
            V_ORGNL_TXN_MODE,
            V_ORGNL_BUSINESS_DATE,
            V_ORGNL_BUSINESS_TIME,
            V_ORGNL_CUSTOMER_CARD_NO,
            V_ORGNL_TOTAL_AMOUNT,
            V_ORGNL_TXN_FEECODE,
            V_ORGNL_TXN_FEEATTACHTYPE,
            V_ORGNL_TXN_TOTALFEE_AMT,
            V_ORGNL_TXN_SERVICETAX_AMT,
            V_ORGNL_TXN_CESS_AMT,
            V_ORGNL_TRANSACTION_TYPE,
            V_ORGNL_TERMID,
            V_ORGNL_MCCCODE,
            V_ACTUAL_FEECODE,
            V_ORGNL_TRANFEE_AMT,
            V_ORGNL_SERVICETAX_AMT,
            V_ORGNL_CESS_AMT,
            V_ORGNL_TRANFEE_CR_ACCTNO,
            V_ORGNL_TRANFEE_DR_ACCTNO,
            V_ORGNL_ST_CALC_FLAG,
            V_ORGNL_CESS_CALC_FLAG,
            V_ORGNL_ST_CR_ACCTNO,
            V_ORGNL_ST_DR_ACCTNO,
            V_ORGNL_CESS_CR_ACCTNO,
            V_ORGNL_CESS_DR_ACCTNO,
            V_CURR_CODE,
            V_TRAN_REVERSE_FLAG,
            V_GL_UPD_FLAG,
            V_ORGNL_TXN_AMNT
            ,v_deact_cardstat
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                   --Added for VMS-5739/FSP-991
        WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
            INSTCODE = P_INST_CODE AND RESPONSE_CODE = '00' AND 
            MSGTYPE IN ('0200','1200') AND TXN_CODE IN('28','36') AND -- Msgtype 1200 added for Spil_3.0
            DELIVERY_CHANNEL = P_DELV_CHNL;
			 END IF;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        BEGIN
          SELECT DELIVERY_CHANNEL,
                TERMINAL_ID,
                RESPONSE_CODE,
                TXN_CODE,
                TXN_TYPE,
                TXN_MODE,
                BUSINESS_DATE,
                BUSINESS_TIME,
                CUSTOMER_CARD_NO,
                AMOUNT, --Transaction amount
                FEECODE,
                FEEATTACHTYPE, -- card level / prod cattype level
                TRANFEE_AMT, --Tranfee  Total    amount
                SERVICETAX_AMT, --Tran servicetax amount
                CESS_AMT, --Tran cess amount
                CR_DR_FLAG,
                TERMINAL_ID,
                MCCODE,
                FEECODE,
                TRANFEE_AMT,
                SERVICETAX_AMT,
                CESS_AMT,
                TRANFEE_CR_ACCTNO,
                TRANFEE_DR_ACCTNO,
                TRAN_ST_CALC_FLAG,
                TRAN_CESS_CALC_FLAG,
                TRAN_ST_CR_ACCTNO,
                TRAN_ST_DR_ACCTNO,
                TRAN_CESS_CR_ACCTNO,
                TRAN_CESS_DR_ACCTNO,
                CURRENCYCODE,
                TRAN_REVERSE_FLAG,
                GL_UPD_FLAG,
                AMOUNT
                ,cardstatus
            INTO V_ORGNL_DELIVERY_CHANNEL,
                V_ORGNL_TERMINAL_ID,
                V_ORGNL_RESP_CODE,
                V_ORGNL_TXN_CODE,
                V_ORGNL_TXN_TYPE,
                V_ORGNL_TXN_MODE,
                V_ORGNL_BUSINESS_DATE,
                V_ORGNL_BUSINESS_TIME,
                V_ORGNL_CUSTOMER_CARD_NO,
                V_ORGNL_TOTAL_AMOUNT,
                V_ORGNL_TXN_FEECODE,
                V_ORGNL_TXN_FEEATTACHTYPE,
                V_ORGNL_TXN_TOTALFEE_AMT,
                V_ORGNL_TXN_SERVICETAX_AMT,
                V_ORGNL_TXN_CESS_AMT,
                V_ORGNL_TRANSACTION_TYPE,
                V_ORGNL_TERMID,
                V_ORGNL_MCCCODE,
                V_ACTUAL_FEECODE,
                V_ORGNL_TRANFEE_AMT,
                V_ORGNL_SERVICETAX_AMT,
                V_ORGNL_CESS_AMT,
                V_ORGNL_TRANFEE_CR_ACCTNO,
                V_ORGNL_TRANFEE_DR_ACCTNO,
                V_ORGNL_ST_CALC_FLAG,
                V_ORGNL_CESS_CALC_FLAG,
                V_ORGNL_ST_CR_ACCTNO,
                V_ORGNL_ST_DR_ACCTNO,
                V_ORGNL_CESS_CR_ACCTNO,
                V_ORGNL_CESS_DR_ACCTNO,
                V_CURR_CODE,
                V_TRAN_REVERSE_FLAG,
                V_GL_UPD_FLAG,
                V_ORGNL_TXN_AMNT
                ,v_deact_cardstat
            FROM VMSCMS.TRANSACTIONLOG    --Added for VMS-5739/FSP-991
           WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                INSTCODE = P_INST_CODE AND RESPONSE_CODE != '00' AND
                MSGTYPE IN ('0200','1200') AND TXN_CODE IN ('28','36') AND   -- Msgtype 1200 added for Spil_3.0
                DELIVERY_CHANNEL = P_DELV_CHNL;
				IF SQL%ROWCOUNT = 0 THEN
				SELECT DELIVERY_CHANNEL,
                TERMINAL_ID,
                RESPONSE_CODE,
                TXN_CODE,
                TXN_TYPE,
                TXN_MODE,
                BUSINESS_DATE,
                BUSINESS_TIME,
                CUSTOMER_CARD_NO,
                AMOUNT, --Transaction amount
                FEECODE,
                FEEATTACHTYPE, -- card level / prod cattype level
                TRANFEE_AMT, --Tranfee  Total    amount
                SERVICETAX_AMT, --Tran servicetax amount
                CESS_AMT, --Tran cess amount
                CR_DR_FLAG,
                TERMINAL_ID,
                MCCODE,
                FEECODE,
                TRANFEE_AMT,
                SERVICETAX_AMT,
                CESS_AMT,
                TRANFEE_CR_ACCTNO,
                TRANFEE_DR_ACCTNO,
                TRAN_ST_CALC_FLAG,
                TRAN_CESS_CALC_FLAG,
                TRAN_ST_CR_ACCTNO,
                TRAN_ST_DR_ACCTNO,
                TRAN_CESS_CR_ACCTNO,
                TRAN_CESS_DR_ACCTNO,
                CURRENCYCODE,
                TRAN_REVERSE_FLAG,
                GL_UPD_FLAG,
                AMOUNT
                ,cardstatus
            INTO V_ORGNL_DELIVERY_CHANNEL,
                V_ORGNL_TERMINAL_ID,
                V_ORGNL_RESP_CODE,
                V_ORGNL_TXN_CODE,
                V_ORGNL_TXN_TYPE,
                V_ORGNL_TXN_MODE,
                V_ORGNL_BUSINESS_DATE,
                V_ORGNL_BUSINESS_TIME,
                V_ORGNL_CUSTOMER_CARD_NO,
                V_ORGNL_TOTAL_AMOUNT,
                V_ORGNL_TXN_FEECODE,
                V_ORGNL_TXN_FEEATTACHTYPE,
                V_ORGNL_TXN_TOTALFEE_AMT,
                V_ORGNL_TXN_SERVICETAX_AMT,
                V_ORGNL_TXN_CESS_AMT,
                V_ORGNL_TRANSACTION_TYPE,
                V_ORGNL_TERMID,
                V_ORGNL_MCCCODE,
                V_ACTUAL_FEECODE,
                V_ORGNL_TRANFEE_AMT,
                V_ORGNL_SERVICETAX_AMT,
                V_ORGNL_CESS_AMT,
                V_ORGNL_TRANFEE_CR_ACCTNO,
                V_ORGNL_TRANFEE_DR_ACCTNO,
                V_ORGNL_ST_CALC_FLAG,
                V_ORGNL_CESS_CALC_FLAG,
                V_ORGNL_ST_CR_ACCTNO,
                V_ORGNL_ST_DR_ACCTNO,
                V_ORGNL_CESS_CR_ACCTNO,
                V_ORGNL_CESS_DR_ACCTNO,
                V_CURR_CODE,
                V_TRAN_REVERSE_FLAG,
                V_GL_UPD_FLAG,
                V_ORGNL_TXN_AMNT
                ,v_deact_cardstat
            FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST   --Added for VMS-5739/FSP-991
           WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                INSTCODE = P_INST_CODE AND RESPONSE_CODE != '00' AND
                MSGTYPE IN ('0200','1200') AND TXN_CODE IN ('28','36') AND   -- Msgtype 1200 added for Spil_3.0
                DELIVERY_CHANNEL = P_DELV_CHNL;
				END IF;

          V_RESP_CDE := '23';
          V_ERRMSG   := ' The original transaction was not successful';
          RAISE EXP_RVSL_REJECT_RECORD;

        EXCEPTION

          WHEN EXP_RVSL_REJECT_RECORD THEN
            RAISE;
          WHEN NO_DATA_FOUND THEN
            V_RESP_CDE := '53';
            V_ERRMSG   := 'Matching transaction not found';
            RAISE EXP_RVSL_REJECT_RECORD;

          WHEN TOO_MANY_ROWS THEN
            V_RESP_CDE := '23';
            V_ERRMSG   := ' The original transaction was not successful';
            RAISE EXP_RVSL_REJECT_RECORD;

          WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERRMSG   := 'Error while selecting master data' ||
                       SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_RVSL_REJECT_RECORD;

        END;

       WHEN TOO_MANY_ROWS THEN
        V_RESP_CDE := '21';
        V_ERRMSG   := 'More than one matching record found in the master';
        RAISE EXP_RVSL_REJECT_RECORD;
       WHEN EXP_RVSL_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERRMSG   := 'Error while selecting master data' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_RVSL_REJECT_RECORD;

     END;

    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting master data' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En check orginal transaction
  --If the redemption transaction and spil value insertion
  --done through that card deactivation is not allowed
   --Comment The card status Check for DFCHost -344
  BEGIN
    --Profile Code of Product
    SELECT CPC_PROFILE_CODE, decode(nvl(cpc_b2b_flag,'N'),'N', cpc_retail_activation,0),CPC_PRODUCT_FUNDING
     INTO V_PROFILE_CODE, v_retail_activation,v_prod_fund
     FROM CMS_PROD_CATTYPE
    WHERE CPC_PROD_CODE = V_PROD_CODE  AND CPC_CARD_TYPE=V_CARD_TYPE AND CPC_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'profile_code not defined ' || V_PROFILE_CODE;
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'profile_code not defined ' || V_PROFILE_CODE;
     RAISE EXP_RVSL_REJECT_RECORD;
  end;
   
  IF v_order_prod_fund is not null THEN
        v_product_funding := v_order_prod_fund;
  ELSE
        v_product_funding := v_prod_fund;
  END IF;
  
  IF V_CAP_CARD_STAT <> 0 AND V_CAP_CARD_STAT <> 9 THEN
    V_RESP_CDE := '21'; --Need ti Change Response code  srinivasuk
    V_ERRMSG   := 'De-Activation not done for this card';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;
    
  IF V_CAP_FIRSTTIME_TOPUP <> 'N' AND (v_b2b_cardFlag='N' OR (v_b2b_cardFlag='Y' AND v_product_funding='2')) THEN
    V_RESP_CDE := '21'; --Need ti Change Response code  srinivasuk
    V_ERRMSG   := 'De-Activation not done for this card';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;

  IF V_ORGNL_CUSTOMER_CARD_NO <> V_HASH_PAN THEN

    V_RESP_CDE := '21';
    V_ERRMSG   := 'Customer card number is not matching in reversal and orginal transaction';
    RAISE EXP_RVSL_REJECT_RECORD;

  END IF;
  --En check card number

  BEGIN
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(V_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
    SELECT COUNT(1)
     INTO V_TXNCNT_AFTERTOPUP
     FROM VMSCMS.TRANSACTIONLOG                   --Added for VMS-5739/FSP-991
    WHERE TO_DATE(BUSINESS_DATE || BUSINESS_TIME, 'yyyymmdd hh24miss') >
         TO_DATE(V_ORGNL_BUSINESS_DATE || V_ORGNL_BUSINESS_TIME,
                'yyyymmdd hh24miss') AND CUSTOMER_CARD_NO = V_HASH_PAN AND
         INSTCODE = P_INST_CODE AND TXN_TYPE = '1'
         AND RESPONSE_CODE='00'; -- Modified by Deepa T to add success response code for 13632 on 07-Feb-2014;;
		 
		 ELSE
		  SELECT COUNT(1)
     INTO V_TXNCNT_AFTERTOPUP
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                   --Added for VMS-5739/FSP-991
    WHERE TO_DATE(BUSINESS_DATE || BUSINESS_TIME, 'yyyymmdd hh24miss') >
         TO_DATE(V_ORGNL_BUSINESS_DATE || V_ORGNL_BUSINESS_TIME,
                'yyyymmdd hh24miss') AND CUSTOMER_CARD_NO = V_HASH_PAN AND
         INSTCODE = P_INST_CODE AND TXN_TYPE = '1'
         AND RESPONSE_CODE='00'; -- Modified by Deepa T to add success response code for 13632 on 07-Feb-2014;;
		 END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_TXNCNT_AFTERTOPUP := 0;

    WHEN OTHERS THEN

     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting data from transactionlog' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

  END;

  IF V_TXNCNT_AFTERTOPUP > 0  THEN

    V_RESP_CDE := '67';
    V_ERRMSG   := 'Card successfully loaded and load amount has been redeemed';
    RAISE EXP_RVSL_REJECT_RECORD;

  END IF;

  --Sn find the converted tran amt
  V_TRAN_AMT := P_ACTUAL_AMT;

  IF (P_ACTUAL_AMT >= 0) THEN

    BEGIN
     SP_CONVERT_CURR(P_INST_CODE,
                  V_CURRCODE,
                  P_CARD_NO,
                  P_ACTUAL_AMT,
                  V_RVSL_TRANDATE,
                  V_TRAN_AMT,
                  V_CARD_CURR,
                  V_ERRMSG,
                  V_PROD_CODE,
                  V_CARD_TYPE
                  );

     IF V_ERRMSG <> 'OK' THEN
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; -- Server Declined -220509
       V_ERRMSG   := 'Error from currency conversion ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
  ELSE
    -- If transaction Amount is zero - Invalid Amount -220509
    V_RESP_CDE := '13';
    V_ERRMSG   := 'INVALID AMOUNT';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;

  --En find the  converted tran amt

  --Sn Check the Original and Reversal txn amount

  IF P_ACTUAL_AMT > V_ORGNL_TXN_AMNT THEN

    V_RESP_CDE := '59';
    V_ERRMSG   := 'Reversal amount exceeds the original transaction amount';
    RAISE EXP_RVSL_REJECT_RECORD;

  END IF;
  --En Check the Original and Reversal txn amount
  
  --Sn check amount with orginal transaction
  IF (V_TRAN_AMT IS NULL OR V_TRAN_AMT = 0) THEN

    V_ACTUAL_DISPATCHED_AMT := 0;
  ELSE
    V_ACTUAL_DISPATCHED_AMT := V_TRAN_AMT;
  END IF;
  --En check amount with orginal transaction
  V_REVERSAL_AMT := V_ORGNL_TOTAL_AMOUNT - V_ACTUAL_DISPATCHED_AMT;
  
  IF V_REVERSAL_AMT < V_ORGNL_TOTAL_AMOUNT THEN   ---Modified For Mantis id-0010997  
    V_REVERSAL_AMT_FLAG :='P';
  END IF;
  -- Sn commented by MageshKumar.S since this is a duplicate

  -- En commented by MageshKumar.S since this is a duplicate
 IF v_retail_activation=1 THEN
      v_reversal_amt:=0;
 ELSE     
  IF V_DR_CR_FLAG = 'NA' THEN
    V_RESP_CDE := '21';
    V_ERRMSG   := 'Not a valid orginal transaction for reversal';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;
  IF V_DR_CR_FLAG <> V_ORGNL_TRANSACTION_TYPE AND v_b2b_cardflag='N' THEN
    V_RESP_CDE := '21';
    V_ERRMSG   := 'Orginal transaction type is not matching with actual transaction type';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;
--SN Added for FWR 70
 END IF;
   
   BEGIN
    select CBP_PARAM_VALUE
     INTO v_currency_code
     from CMS_BIN_PARAM
    WHERE CBP_PROFILE_CODE = V_PROFILE_CODE AND
         CBP_INST_CODE = P_INST_CODE AND CBP_PARAM_NAME = 'Currency';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Currency code is  not specified for the Profile ' ||
                V_PROFILE_CODE;
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error While selecting the Currency code' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  end;
if(V_CURRENCY_CODE='124') then
V_STARTER_CANADA:='Y';
end if;
--EN Added for FWR 70

--SN Added for 4.2 CL changes
--  BEGIN  
--  
--  SELECT UPPER(NVL(CPP_PRODUCT_TYPE,'O')) INTO V_PROD_TYPE 
--  FROM CMS_PRODUCT_PARAM 
--  WHERE CPP_PROD_CODE=V_PROD_CODE AND CPP_INST_CODE=P_INST_CODE;
--  
--  EXCEPTION
--  WHEN OTHERS THEN
--     V_RESP_CDE := '21';
--     V_ERRMSG   := 'Error While selecting the product type' ||
--                SUBSTR(SQLERRM, 1, 200);
--   RAISE EXP_RVSL_REJECT_RECORD;
--  END;

--if V_PROD_TYPE = 'C' then
--  V_STARTER_CANADA:='N';
IF v_retail_activation =1 OR v_retail_activation=2  THEN
     v_upd_card_stat :=1;
ELSE   
     v_upd_card_stat :=v_cap_old_cardstat;
END IF;  
--EN Added for 4.2 CL changes
  --Sn reverse the amount
 IF v_retail_activation=1  OR   V_ORGNL_TXN_CODE='36' THEN
    BEGIN
       SELECT ctm_tran_type, ctm_prfl_flag, ctm_credit_debit_flag,ctm_tran_desc,DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1') 
         INTO v_tran_type, v_prfl_flag,  v_dr_cr_flag,v_tran_desc, v_txn_type
         FROM cms_transaction_mast
        WHERE     ctm_tran_code = '36'
              AND ctm_delivery_channel = p_delv_chnl
              AND ctm_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS
       THEN
          NULL;
    END; 
 END IF;
  
    --Sn Added by Pankaj S. for enabling limit validation   
    IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
    BEGIN
          pkg_limits_check.sp_limits_check (v_hash_pan,
                                            NULL,
                                            NULL,
                                            'NA',--p_mcc_code,
                                            --p_txn_code,
                                            case when p_txn_code in ('28','29') then '26' when p_txn_code in ('36') then '35' end,
                                            v_tran_type,
                                            'NA',--p_international_ind,
                                            'NA',--p_pos_verfication,
                                            p_inst_code,
                                            NULL,
                                            v_prfl_code,
                                             --v_tran_amt, --Commented and modified on 03.04.2014 for enabling limit validation   
                                            v_reversal_amt,
                                            p_delv_chnl,
                                            v_comb_hash,
                                            v_resp_cde,
                                            v_errmsg
                                           );
       IF v_errmsg <> 'OK' THEN
          RAISE exp_rvsl_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_rvsl_reject_record THEN
          RAISE;
       WHEN OTHERS    THEN
          v_resp_cde := '21';
          v_errmsg :='Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
    END;
    END IF;
    --En Added by Pankaj S. for enabling limit validation  

  --Sn update the amount

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
     V_ERRMSG      := 'Cutoff time is not defined in the system';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting cutoff  dtl  from system ';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  ---En find cutoff time

  BEGIN
    SELECT CAM_ACCT_NO,cam_type_code
     INTO V_CARD_ACCT_NO,v_acct_type  --added by Pankaj S. for 10871
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_NO =v_card_acct_no
         /*(SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
           WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                CAP_INST_CODE = P_INST_CODE) */
                AND
         CAM_INST_CODE = P_INST_CODE
      FOR UPDATE NOWAIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '14'; --Ineligible Transaction
     V_ERRMSG   := 'Invalid Card ';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '12';
     V_ERRMSG   := 'Error while selecting data from card Master for card number '|| SUBSTR(SQLERRM, 1, 200);
               -- P_CARD_NO; commented for FSS-2320
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --Sn reverse  the amount
  --Sn find narration

  BEGIN
  
       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE ), 1, 8), 'yyyymmdd');
	   
    IF (v_Retdate>v_Retperiod) THEN                     --Added for VMS-5739/FSP-991
	
      SELECT CSL_TRANS_NARRRATION,                              
         CSL_MERCHANT_NAME,
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE
       INTO V_TXN_NARRATION,
         V_TXN_MERCHNAME,
         V_TXN_MERCHCITY,
         V_TXN_MERCHSTATE --Mofified by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
       FROM CMS_STATEMENTS_LOG
       WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND CSL_RRN = P_RRN AND
         CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
         CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'N';
		 
	ELSE
	 
	    SELECT CSL_TRANS_NARRRATION,                              
         CSL_MERCHANT_NAME,
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE
       INTO V_TXN_NARRATION,
         V_TXN_MERCHNAME,
         V_TXN_MERCHCITY,
         V_TXN_MERCHSTATE --Mofified by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
       FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST              --Added for VMS-5739/FSP-991
       WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND CSL_RRN = P_RRN AND
         CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
         CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'N';
	
    END IF;
	
    IF V_ORGNL_TXN_TOTALFEE_AMT > 0 THEN

     BEGIN
       
	  IF (v_Retdate>v_Retperiod) THEN                  --Added for VMS-5739/FSP-991
	  
         SELECT CSL_TRANS_NARRRATION,
            CSL_MERCHANT_NAME,
            CSL_MERCHANT_CITY,
            CSL_MERCHANT_STATE
         INTO V_FEE_NARRATION,
            V_FEE_MERCHNAME,
            V_FEE_MERCHCITY,
            V_FEE_MERCHSTATE --Mofified by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
         FROM CMS_STATEMENTS_LOG
         WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
            CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
            CSL_RRN = P_RRN AND
            CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
            CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
            CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
            CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';
			
	  ELSE
	    
		 SELECT CSL_TRANS_NARRRATION,
            CSL_MERCHANT_NAME,
            CSL_MERCHANT_CITY,
            CSL_MERCHANT_STATE
         INTO V_FEE_NARRATION,
            V_FEE_MERCHNAME,
            V_FEE_MERCHCITY,
            V_FEE_MERCHSTATE --Mofified by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
         FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST              --Added for VMS-5739/FSP-991
         WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
            CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
            CSL_RRN = P_RRN AND
            CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
            CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
            CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
            CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';
	  			
	  END IF;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_FEE_NARRATION := NULL;
       WHEN OTHERS THEN
        V_FEE_NARRATION := NULL;

     END;

    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_TXN_NARRATION := NULL;
    WHEN OTHERS THEN
     V_TXN_NARRATION := NULL;

  END;

  --En find narration
  v_timestamp:=systimestamp; --added for 10871
 IF v_reversal_amt>0 THEN
  BEGIN
    SP_REVERSE_CARD_AMOUNT(P_INST_CODE,
                      V_FUNC_CODE,
                      P_RRN,
                      P_DELV_CHNL,
                      P_ORGNL_TERMINAL_ID,
                      P_MERC_ID,
                      P_TXN_CODE,
                      V_RVSL_TRANDATE,
                      P_TXN_MODE,
                      P_CARD_NO,
                      V_REVERSAL_AMT,
                      P_ORGNL_RRN,
                      V_CARD_ACCT_NO,
                      P_BUSINESS_DATE,
                      P_BUSINESS_TIME,
                      V_AUTH_ID,
                      V_TXN_NARRATION,
                      P_ORGNL_BUSINESS_DATE,
                      P_ORGNL_BUSINESS_TIME,
                      V_TXN_MERCHNAME, --Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                      V_TXN_MERCHCITY,
                      V_TXN_MERCHSTATE,
                      V_RESP_CDE,
                      V_ERRMSG);
    IF V_RESP_CDE <> '00' OR V_ERRMSG <> 'OK' THEN
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while reversing the amount ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En reverse the amount
 END IF; 
  --Sn reverse the fee
  BEGIN
    SP_DAILY_BIN_BAL(P_CARD_NO,
                 V_RVSL_TRANDATE,
                 V_REVERSAL_AMT,
                 'DR',
                 P_INST_CODE,
                 P_BANK_CODE,
                 V_ERRMSG);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while calling SP_DAILY_BIN_BAL ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  IF V_REVERSAL_AMT_FLAG <>'P' THEN   --Modified For Mantis Id-0010997
    -- SN Added for FWR-11
       Begin 
         select CFM_FEECAP_FLAG,CFM_FEE_AMT into v_feecap_flag,v_orgnl_fee_amt from CMS_FEE_MAST 
         where CFM_INST_CODE = P_INST_CODE and CFM_FEE_CODE = V_ORGNL_TXN_FEECODE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
                v_feecap_flag := '';
          WHEN OTHERS THEN
              V_ERRMSG := 'Error in feecap flag fetch ' || SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_RVSL_REJECT_RECORD;
        End;
        -- EN Added for FWR-11
        
            if v_feecap_flag = 'Y' then 
        BEGIN
            SP_TRAN_FEES_REVCAPCHECK(P_INST_CODE,
                    v_card_acct_no,
                    V_ORGNL_BUSINESS_DATE,
                    V_ORGNL_TRANFEE_AMT,
                    v_orgnl_fee_amt,
                    V_ORGNL_TXN_FEE_PLAN,
                    V_ORGNL_TXN_FEECODE,
                    V_ERRMSG                 
                  ); -- Added for FWR-11
          EXCEPTION
          WHEN OTHERS THEN
          V_RESP_CDE := '21';
          V_ERRMSG   := 'Error while reversing the fee Cap amount ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_RVSL_REJECT_RECORD;
       END;
      End if;
    -- EN Added for FWR-11
  BEGIN
    SP_REVERSE_FEE_AMOUNT(P_INST_CODE,
                     P_RRN,
                     P_DELV_CHNL,
                     P_ORGNL_TERMINAL_ID,
                     P_MERC_ID,
                      CASE WHEN v_retail_activation=1 THEN v_orgnl_txn_code ELSE P_TXN_CODE END,
                     V_RVSL_TRANDATE,
                     P_TXN_MODE,
                     V_ORGNL_TXN_TOTALFEE_AMT,
                     P_CARD_NO,
                     V_ACTUAL_FEECODE,
                     V_ORGNL_TRANFEE_AMT,
                     V_ORGNL_TRANFEE_CR_ACCTNO,
                     V_ORGNL_TRANFEE_DR_ACCTNO,
                     V_ORGNL_ST_CALC_FLAG,
                     V_ORGNL_SERVICETAX_AMT,
                     V_ORGNL_ST_CR_ACCTNO,
                     V_ORGNL_ST_DR_ACCTNO,
                     V_ORGNL_CESS_CALC_FLAG,
                     V_ORGNL_CESS_AMT,
                     V_ORGNL_CESS_CR_ACCTNO,
                     V_ORGNL_CESS_DR_ACCTNO,
                     P_ORGNL_RRN,
                     V_CARD_ACCT_NO,
                     P_BUSINESS_DATE,
                     P_BUSINESS_TIME,
                     V_AUTH_ID,
                     V_FEE_NARRATION,
                     V_FEE_MERCHNAME, --Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                     V_FEE_MERCHCITY,
                     V_FEE_MERCHSTATE,
                     V_RESP_CDE,
                     V_ERRMSG);

    IF V_RESP_CDE <> '00' OR V_ERRMSG <> 'OK' THEN
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;

    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while reversing the fee amount ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  END IF; ----Added For Mantis-Id-0010997

  --En reverse the fee
  --Sn reverse the GL entries

  --Sn get the product code

  IF V_GL_UPD_FLAG = 'Y' THEN

    --Sn find business date
    V_BUSINESS_TIME := TO_CHAR(V_RVSL_TRANDATE, 'HH24:MI');
    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_RVSL_TRANDATE := TRUNC(V_RVSL_TRANDATE) + 1;
    ELSE
     V_RVSL_TRANDATE := TRUNC(V_RVSL_TRANDATE);
    END IF;
    --En find businesses date      

  END IF;
  --En reverse the GL entries
  
   --SN  Added on 01.08.2013 for 11872
   V_RESP_CDE := '1';  

  --Sn reversal Fee Calculation
  BEGIN

    SP_TRAN_REVERSAL_FEES(P_INST_CODE,
                     P_CARD_NO,
                     P_DELV_CHNL,
                     V_ORGNL_TXN_MODE,
                      CASE WHEN v_retail_activation=1 THEN v_orgnl_txn_code ELSE P_TXN_CODE END,
                     P_CURR_CODE,
                     NULL,
                     NULL,
                     V_REVERSAL_AMT,
                     P_BUSINESS_DATE,
                     P_BUSINESS_TIME,
                     NULL,
                     NULL,
                     V_RESP_CDE,
                     P_MSG_TYP,
                     P_MBR_NUMB,
                     P_RRN,
                     P_TERMINAL_ID,
                     V_TXN_MERCHNAME,
                     V_TXN_MERCHCITY,
                     V_AUTH_ID,
                     V_FEE_MERCHSTATE,
                     P_RVSL_CODE,
                     V_TXN_NARRATION,
                     V_TXN_TYPE,
                     V_TRAN_DATE,
                     V_ERRMSG,
                     V_RESP_CDE,
                     V_FEE_AMT,
                     V_FEE_PLAN,
                     V_FEE_CODE,      --Added on 01.08.2013 for 11695
                     V_FEEATTACH_TYPE --Added on 01.08.2013 for 11695                     
                     );

    IF V_ERRMSG <> 'OK' THEN
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;
  END;
  --En reversal Fee Calculation
  --EN  Added on 01.08.2013 for 11872
  

  --Added by srinivasu for Stater card issuance defect fix on 19-June-2012
  IF V_ERRMSG = 'OK' THEN

    BEGIN
     update CMS_APPL_PAN
        set CAP_FIRSTTIME_TOPUP = (CASE WHEN (v_b2b_cardFlag='N' OR (v_b2b_cardFlag='Y' AND v_product_funding='2'))  THEN 'Y' ELSE CAP_FIRSTTIME_TOPUP END),
         CAP_CARD_STAT  = DECODE (V_STARTER_CANADA,'Y',v_deact_cardstat,DECODE (v_b2b_cardFlag,'Y',v_cap_old_cardstat,V_UPD_CARD_STAT)),--Modified for 4.2 CL changes
         cap_pin_off=decode(V_UPD_CARD_STAT,'1','0000',cap_pin_off), -- Added for 4.2 CL changes
         cap_active_date=decode(V_UPD_CARD_STAT,'1',sysdate,cap_active_date) -- Added for 4.2 CL changes
      WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
           CAP_INST_CODE = P_INST_CODE;

     IF SQL%ROWCOUNT = 0 THEN
       V_ERRMSG   := 'Error while Updating first time topup flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;

    EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
       RAISE EXP_RVSL_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while Updating first time topup flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
    
    
--SN: Commented for 4.2.2 changes
/*--SN Added for 4.2 CL changes
if(V_PROD_TYPE='C') then
BEGIN

UPDATE CMS_CUST_MAST SET CCM_KYC_FLAG='Y' WHERE CCM_CUST_CODE=v_cap_cust_code AND CCM_INST_CODE=P_INST_CODE;

 IF SQL%ROWCOUNT = 0 THEN
       V_ERRMSG   := 'Kyc flag not updated in cust mast';
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;
    EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
    RAISE;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while Updating kyc flag in cust mast' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
END;

BEGIN

UPDATE CMS_CAF_INFO_ENTRY SET CCI_KYC_FLAG='Y' WHERE CCI_APPL_CODE=to_char(V_APPL_CODE) AND CCI_INST_CODE=P_INST_CODE;

 IF SQL%ROWCOUNT = 0 THEN
       V_ERRMSG   := 'Kyc flag not updated in caf info table';
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;
    EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
    RAISE;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while Updating kyc flag in caf info table' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
END;
END if;
--EN Added for 4.2 CL changes*/
--EN: Commented for 4.2.2 changes

--Added for DFCHOST-345 
    BEGIN
     SELECT  CMM_MER_ID, CMM_LOCATION_ID, CMM_MERPRODCAT_ID
       INTO 
           V_CMM_MER_ID,
           V_CMM_LOCATION_ID,
           V_CMM_MERPRODCAT_ID
       FROM CMS_MERINV_MERPAN
      WHERE CMM_PAN_CODE = V_HASH_PAN
      AND CMM_INST_CODE = P_INST_CODE;
      
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERR_SET := 1;

     When Others Then
       V_ERRMSG   := 'Error while Fetching MerchantDetails From MERPAN ' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;

    IF V_ERR_SET <> 1 THEN
     
      BEGIN
            SELECT cap_pan_code,cap_pan_code_encr
            INTO v_gpr_pan,v_gpr_encr_pan
            FROM (
            SELECT cap_pan_code,cap_pan_code_encr
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code
               AND cap_cust_code = v_cap_cust_code
               AND cap_acct_id = v_cap_acct_id
               AND cap_startercard_flag = 'N'
               ORDER BY CAP_ins_date DESC)
               WHERE ROWNUM=1;

            v_gpr_chk := 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
               v_gpr_chk := 'N';
         WHEN OTHERS
         THEN
               v_errmsg :=
                     'Problem while fetching GPR card '
                  || SUBSTR (SQLERRM, 1, 100);
               v_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
      END;
      
        BEGIN
           SELECT DECODE (nvl(v_deact_cardstat,0),0, '08',
                          1, '01',
                          9, '02',
                          12, '03',
                          8, '04',
                          13, '09',0
                         )
             INTO v_cardstat_txncode
             FROM DUAL;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_errmsg :=
                    'Problem while fetching starter card status of deactivation  '
                 || SUBSTR (SQLERRM, 1, 100);
              v_resp_cde := '21';
              RAISE exp_rvsl_reject_record;
        END;

      IF v_gpr_chk = 'N'
         THEN
        BEGIN
           SELECT ccp_pin_off
             INTO v_pin_ofst
             FROM (SELECT   ccp_pin_off
                       FROM cms_cardiss_pin_hist
                      WHERE ccp_pan_code = v_hash_pan
                   ORDER BY ccp_ins_date DESC)
            WHERE ROWNUM = 1;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            NULL;
           WHEN OTHERS
           THEN
              v_errmsg :=
                    'Problem while fetching starter card pin offset  '
                 || SUBSTR (SQLERRM, 1, 100);
              v_resp_cde := '21';
              RAISE exp_rvsl_reject_record;
        END;   
         
            BEGIN
               UPDATE cms_appl_pan
                  SET cap_card_stat = v_deact_cardstat,
                      cap_firsttime_topup = 'Y',
                      cap_pin_off = nvl(v_pin_ofst,cap_pin_off),
                      cap_pin_flag = DECODE (NVL (v_pin_ofst, 'Y'), 'Y', 'Y','N')
                WHERE cap_inst_code = p_inst_code
                      AND cap_pan_code = v_hash_pan;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg := 'Starer card not updated to inactive status';
                  v_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem while updating starter card to inactive '|| SUBSTR (SQLERRM, 1, 100);
                  v_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
            END;
            
           IF v_cardstat_txncode <> 0 THEN         
            BEGIN
                sp_log_cardstat_chnge (p_inst_code,
                                       v_hash_pan,
                                       v_encr_pan,
                                       v_auth_id,
                                       v_cardstat_txncode,
                                       p_rrn,
                                       p_business_date,
                                       p_business_time,
                                       v_resp_cde,
                                       v_errmsg
                                      );

                IF v_resp_cde <> '00' AND v_errmsg <> 'OK'
                THEN
                   RAISE exp_rvsl_reject_record;
                END IF;
            EXCEPTION
                WHEN exp_rvsl_reject_record
                THEN
                   RAISE;
                WHEN OTHERS
                THEN
                   v_resp_cde := '21';
                   v_errmsg :=
                         'Error while logging system initiated card status change '
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_rvsl_reject_record;
            END; 
           END IF;
              
           
            BEGIN
               UPDATE cms_merinv_merpan
                  SET cmm_activation_flag = 'C'
                WHERE cmm_pan_code = v_hash_pan AND cmm_inst_code = p_inst_code;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg := 'error while updating card activation flag in merpan  1' ||substr(sqlerrm, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN                                    
                  RAISE exp_rvsl_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'error while updating activation flag in merpan'|| SUBSTR (SQLERRM, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
            END;

            BEGIN
               UPDATE cms_merinv_stock
                  SET cms_curr_stock = (cms_curr_stock - 1)
                WHERE cms_inst_code = p_inst_code
                  AND cms_merprodcat_id = v_cmm_merprodcat_id
                  AND cms_location_id = v_cmm_location_id;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg := 'error while updating current stock in merinv stock'|| substr(sqlerrm, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN                                   
                  RAISE exp_rvsl_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'error while updating current stock in merinv stock ' || SUBSTR (SQLERRM, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
            END;
      ELSIF v_gpr_chk = 'Y'
         THEN
            BEGIN
               UPDATE cms_appl_pan
                  SET cap_card_stat = v_deact_cardstat
                WHERE cap_inst_code = p_inst_code
                      AND cap_pan_code = v_hash_pan;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg := 'Starer card not updated to close status';
                  v_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_errmsg :='Problem while updating starter card '|| SUBSTR (SQLERRM, 1, 100);
                  v_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
            END;
          IF  v_cardstat_txncode <> 0 THEN 
             BEGIN
                sp_log_cardstat_chnge (p_inst_code,
                                       v_hash_pan,
                                       v_encr_pan,
                                       v_auth_id,
                                       v_cardstat_txncode,
                                       p_rrn,
                                       p_business_date,
                                       p_business_time,
                                       v_resp_cde,
                                       v_errmsg
                                      );

                IF v_resp_cde <> '00' AND v_errmsg <> 'OK'
                THEN
                   RAISE exp_rvsl_reject_record;
                END IF;
            EXCEPTION
                WHEN exp_rvsl_reject_record
                THEN
                   RAISE;
                WHEN OTHERS
                THEN
                   v_resp_cde := '21';
                   v_errmsg :=
                         'Error while logging system initiated card status change '
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_rvsl_reject_record;
            END;
            
            END IF;

            BEGIN
               UPDATE cms_appl_pan
                  SET cap_card_stat = 0
                WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_gpr_pan;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg := 'GPR card not updated to close status';
                  v_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem while updating GPR card '|| SUBSTR (SQLERRM, 1, 100);
                  v_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
            END;
            
            BEGIN
                sp_log_cardstat_chnge (p_inst_code,
                                       v_gpr_pan,
                                       v_gpr_encr_pan,
                                       v_auth_id,
                                       '08',
                                       p_rrn,
                                       p_business_date,
                                       p_business_time,
                                       v_resp_cde,
                                       v_errmsg
                                      );

                IF v_resp_cde <> '00' AND v_errmsg <> 'OK'
                THEN
                   RAISE exp_rvsl_reject_record;
                END IF;
            EXCEPTION
                WHEN exp_rvsl_reject_record
                THEN
                   RAISE;
                WHEN OTHERS
                THEN
                   v_resp_cde := '21';
                   v_errmsg :=
                         'Error while logging system initiated card status change '
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_rvsl_reject_record;
            END;
            
      END IF;
    END IF;
--End for DFCHOST-345  
  END IF;

  --Sn added by Pankaj S. for 10871
     BEGIN
	 
	  v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date), 1, 8), 'yyyymmdd');    --Added for VMS-5739/FSP-991
	  
	  IF (v_Retdate>v_Retperiod) THEN
	  
        UPDATE cms_statements_log
           SET csl_prod_code = v_prod_code,
               csl_card_type=v_card_type,
               csl_acct_type = v_acct_type,
               csl_time_stamp = v_timestamp
         WHERE csl_inst_code = p_inst_code
           AND csl_pan_no = v_hash_pan
           AND csl_rrn = p_rrn
           AND csl_txn_code = p_txn_code
           AND csl_delivery_channel = p_delv_chnl
           AND csl_business_date = p_business_date
           AND csl_business_time = p_business_time;
	  ELSE
	  
	     UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST             --Added for VMS-5739/FSP-991
           SET csl_prod_code = v_prod_code,
               csl_card_type=v_card_type,
               csl_acct_type = v_acct_type,
               csl_time_stamp = v_timestamp
         WHERE csl_inst_code = p_inst_code
           AND csl_pan_no = v_hash_pan
           AND csl_rrn = p_rrn
           AND csl_txn_code = p_txn_code
           AND csl_delivery_channel = p_delv_chnl
           AND csl_business_date = p_business_date
           AND csl_business_time = p_business_time;
	  	  
	  END IF;
	  
       IF SQL%ROWCOUNT =0
       THEN
         NULL;
       END IF;   
       EXCEPTION
       WHEN OTHERS
       THEN
          v_resp_cde := '21';
          v_errmsg :=
               'Error while updating timestamp in statementlog-' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
    END;
    --Sn added by Pankaj S. for 10871 
    
  --Sn create a entry for successful
  BEGIN

    IF V_ERRMSG = 'OK' THEN

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
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR)
     VALUES
       (P_DELV_CHNL,
         CASE WHEN v_retail_activation=1 THEN v_orgnl_txn_code ELSE P_TXN_CODE END,
    --  P_TXN_TYPE, 
        V_TXN_TYPE, -- Modified by MageshKumar.S for defect Id:FSS-1248,value is passed as NULL
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        P_ACTUAL_AMT, 
        V_CURRCODE,
        V_TRAN_AMT,
        V_REVERSAL_AMT,
        V_CARD_CURR,
        'Y',
        'Successful',
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ENCR_PAN);
    END IF;

    --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Problem while selecting data from response master ';

     V_RESP_CDE := '21';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En create a entry for successful

  --Sn generate response code

  V_RESP_CDE := '1';
  BEGIN
    SELECT CMS_ISO_RESPCDE
     INTO P_RESP_CDE
     FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE = P_INST_CODE AND
         CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
         CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Problem while selecting data from response master for respose code' ||
                V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '69';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En generate response code
  
   BEGIN
       SELECT cap_card_stat
         INTO v_cap_card_stat
         FROM cms_appl_pan
        WHERE cap_pan_code = v_hash_pan
          AND cap_mbr_numb = p_mbr_numb
          AND cap_inst_code = p_inst_code;
    EXCEPTION
       WHEN OTHERS
       THEN
         NULL;
    END;
  
   --Sn Added by MageshKumar.S on 21-06-2013 for FSS-1248
  BEGIN
       SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL -- added by MageshKumar.S on 21-06-2013 for Defect Id : FSS-1248
        INTO V_ACCT_BALANCE,V_LEDGER_BALANCE
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =V_CARD_ACCT_NO
            /*(SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_MBR_NUMB = P_MBR_NUMB AND
                   CAP_INST_CODE = P_INST_CODE)*/
                   AND
            CAM_INST_CODE = P_INST_CODE
         FOR UPDATE NOWAIT;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_RESP_CDE := '14'; --Ineligible Transaction
        V_ERRMSG   := 'Invalid Card ';
        RAISE EXP_RVSL_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESP_CDE := '12';
        V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                    SQLERRM;
        RAISE EXP_RVSL_REJECT_RECORD;
     END;
  --En Added by MageshKumar.S on 21-06-2013 for FSS-1248
    P_ACCT_BAL := V_ACCT_BALANCE;
  -- Sn create a entry in GL
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
      PRODUCTID,
      CATEGORYID,
      TRANFEE_AMT,
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
      FEEATTACHTYPE,
      TRAN_REVERSE_FLAG,
      CUSTOMER_CARD_NO_ENCR,
      TOPUP_CARD_NO_ENCR,
      ORGNL_CARD_NO,
      ORGNL_RRN,
      ORGNL_BUSINESS_DATE,
      ORGNL_BUSINESS_TIME,
      ORGNL_TERMINAL_ID,
      RESPONSE_ID,
      CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
       MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE , -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      --Sn added by Pankaj S. for 10871
      customer_acct_no,
      cr_dr_flag,
      acct_type,
      error_msg,
      time_stamp,
      --En added by Pankaj S. for 10871
      Reversal_Code, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      Acct_Balance, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      Ledger_Balance, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      Add_Ins_User, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      STORE_ID ,    --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES      
      FEE_PLAN , -- Added on 01.08.2013 for 11695
      PROXY_NUMBER
      )
    VALUES
     (P_MSG_TYP,
      P_RRN,
      P_DELV_CHNL,
      P_TERMINAL_ID,
      V_RVSL_TRANDATE,
       CASE WHEN v_retail_activation=1 THEN v_orgnl_txn_code ELSE P_TXN_CODE END,
  --  P_TXN_TYPE, 
      V_TXN_TYPE, -- Modified by MageshKumar.S for defect Id:FSS-1248,value is passed as NULL
      P_TXN_MODE,
      DECODE(P_RESP_CDE, '00', 'C', 'F'),
      P_RESP_CDE,
      P_BUSINESS_DATE,
      SUBSTR(P_BUSINESS_TIME, 1, 6),
      V_HASH_PAN,
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_INST_CODE,
      TRIM(TO_CHAR(V_REVERSAL_AMT, '9999999999990.99')) --formated for 10871
      -- reversal amount will be passed in the table as the same is used in the recon report.
     ,
      NULL,
      NULL,
      P_MERC_ID,
      V_CURR_CODE,
      V_PROD_CODE,
      V_CARD_TYPE,
      --0, -- Commented and modified on 01.08.2013 for 11695
      V_FEE_AMT,
      '0.00', --modified for 10871
      NULL,
      NULL,
      V_AUTH_ID,
      V_TRAN_DESC,
      TRIM(TO_CHAR(V_REVERSAL_AMT, '9999999999990.99')),  --formated for 10871
      -- reversal amount will be passed in the table as the same is used in the recon report.
      '0.00',--modified by Pankaj S. for 10871  --- PRE AUTH AMOUNT
      '0.00',--modified by Pankaj S. for 10871 -- Partial amount (will be given for partial txn)
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      'Y',
      P_STAN,
      P_INST_CODE,
       --NULL,
      V_FEE_CODE, --Added on 01.08.2013 for 11695
      --NULL,
      V_FEEATTACH_TYPE, --Added on 01.08.2013 for 11695
      'N',
      V_ENCR_PAN,
      NULL,
      V_ORGNL_CUSTOMER_CARD_NO,
      P_RRN,
      V_ORGNL_BUSINESS_DATE,
      V_ORGNL_BUSINESS_TIME,
      V_ORGNL_TERMID,
      V_RESP_CDE,
      V_CAP_CARD_STAT, --Added cardstatus insert in transactionlog by srinivasu.k
        V_TXN_MERCHNAME, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         V_TXN_MERCHCITY, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         V_TXN_MERCHSTATE ,-- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      --Sn added by Pankaj S. for 10871
      v_card_acct_no,
       -- v_dr_cr_flag,--Commented and modified on 25.07.2013 for 11693
      decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag),
      v_acct_type,
      V_ERRMSG,
      v_timestamp,
      --En added by Pankaj S. for 10871    
      P_Rvsl_Code, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      V_ACCT_BALANCE, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      V_Ledger_Balance, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      1 ,-- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      P_STORE_ID , --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
      
      V_FEE_PLAN,   -- Added on 01.08.2013 for 11695
      V_PROXUNUMBER
      );

 EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;

    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while inserting records in transaction log ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
    --Sn update reverse flag
    BEGIN
	   
	   --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8), 'yyyymmdd');
	
	IF (v_Retdate>v_Retperiod) THEN          --Added for VMS-5739/FSP-991
	
     UPDATE TRANSACTIONLOG
        SET TRAN_REVERSE_FLAG = 'Y'
      WHERE RRN = P_RRN AND BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
           BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INST_CODE;
		   
	ELSE
	
	  UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5739/FSP-991
        SET TRAN_REVERSE_FLAG = 'Y'
      WHERE RRN = P_RRN AND BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
           BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INST_CODE;
	
	END IF;

     IF SQL%ROWCOUNT = 0 THEN

       V_RESP_CDE := '21';
       V_ERRMSG   := 'Reverse flag is not updated ';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while updating gl flag ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_RVSL_REJECT_RECORD;

    END;
    --En update reverse flag

    BEGIN

     SELECT CTC_ATMUSAGE_AMT,
           CTC_POSUSAGE_AMT,
           CTC_BUSINESS_DATE,
           CTC_MMPOSUSAGE_AMT
       INTO V_ATM_USAGEAMNT,
           V_POS_USAGEAMNT,
           V_BUSINESS_DATE_TRAN,
           V_MMPOS_USAGEAMNT
       FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
           CTC_MBR_NUMB = P_MBR_NUMB;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting 1 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
   
  
    IF V_ERRMSG = 'OK' THEN
     
     P_RESP_MSG := 'Success';

    ELSE

     P_RESP_MSG := V_ERRMSG;

    END IF;
        
      IF v_orgnl_txn_totalfee_amt=0 AND v_orgnl_txn_feecode IS NOT NULL THEN
        BEGIN
           vmsfee.fee_freecnt_reverse (v_card_acct_no, v_orgnl_txn_feecode, v_errmsg);
        
           IF v_errmsg <> 'OK' THEN
              v_resp_cde := '21';
              RAISE exp_rvsl_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_rvsl_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              v_resp_cde := '21';
              v_errmsg :='Error while reversing freefee count-'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_rvsl_reject_record;
        END;
      END IF;    
 
    --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113) 
        v_comb_hash(1).comb_hash :=gethash (   TRIM (v_prfl_code)
                                            || TRIM (p_delv_chnl)
                                            || '26'
                                            || TRIM (v_tran_type)
                                            || 'NA'                --intl_flag
                                            || 'NA'                --pnsign_flag
                                            || 'NA'                --mcc_code
                                            || 'NA'                --fromtrfr_crdacnt
                                           );
    IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
    BEGIN
          pkg_limits_check.sp_limitcnt_reset (p_inst_code,
                                              v_hash_pan,
                                               --v_tran_amt, --Commented and modified on 03.04.2014 for enabling limit validation   
                                              v_reversal_amt,
                                              v_comb_hash,
                                              v_resp_cde,
                                              v_errmsg
                                             );
       IF v_errmsg <> 'OK' THEN
          v_errmsg := 'From Procedure sp_limitcnt_reset' || v_errmsg;
          RAISE exp_rvsl_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_rvsl_reject_record THEN
          RAISE;
       WHEN OTHERS THEN
          v_resp_cde := '21';
          v_errmsg := 'Error from Limit Reset Count Process ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
    END;
    END IF;
    --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113) 

EXCEPTION
  -- << MAIN EXCEPTION>>
  WHEN EXP_RVSL_REJECT_RECORD THEN
    ROLLBACK TO V_SAVEPOINT;
       
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CDE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
     P_RESP_MSG := V_ERRMSG;
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while selecting data from response master ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69';
    END;
    
    --Sn - added for handling duplicate request echo back - Fss-1802
    if v_dupl_flag = 1 then
      BEGIN
     SELECT RESPONSE_CODE
       INTO P_RESP_CDE 
       FROM VMSCMS.TRANSACTIONLOG_VW A,          --Added for VMS-5739/FSP-991     
           (SELECT MIN(ADD_INS_DATE) MINDATE
             FROM VMSCMS.TRANSACTIONLOG_VW            --Added for VMS-5739/FSP-991    
            WHERE RRN = P_RRN and ACCT_BALANCE is not null) B
      WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN and ACCT_BALANCE is not null;
	  
    
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG    := 'Problem in selecting the response detail of Original transaction' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '89'; 
       ROLLBACK;
       RETURN;
    END;
    end if;
    --En - added for handling duplicate request echo back - Fss-1802
   
     --Sn added by Pankaj S. for 10871 
      IF v_dr_cr_flag IS NULL THEN
      BEGIN  
        SELECT ctm_credit_debit_flag, ctm_tran_desc
          INTO v_dr_cr_flag, v_tran_desc
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delv_chnl
           AND ctm_inst_code = p_inst_code;                    
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      
      IF v_prod_code is NULL THEN
      BEGIN  
        SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
          INTO v_prod_code, v_card_type, v_cap_card_stat,v_card_acct_no
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code
           AND cap_pan_code = gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      --En added by Pankaj S. for 10871 
  IF v_acct_type IS NULL THEN
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code --added by Pankaj S. for 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            v_acct_type --added by Pankaj S. for 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO = v_card_acct_no
           /*(SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INST_CODE) */
                 AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;
    END IF;
    P_ACCT_BAL := V_ACCT_BALANCE;  
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
        CURRENCYCODE,
        ADDCHARGE,
        CATEGORYID,
        ATM_NAME_LOCATION,
        AUTH_ID,
        AMOUNT,
        PREAUTHAMOUNT,
        PARTIALAMOUNT,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        TOPUP_CARD_NO_ENCR,
        ORGNL_CARD_NO,
        ORGNL_RRN,
        ORGNL_BUSINESS_DATE,
        ORGNL_BUSINESS_TIME,
        ORGNL_TERMINAL_ID,
        RESPONSE_ID,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        CARDSTATUS ,--Added cardstatus insert in transactionlog by srinivasu.k
        TRANS_DESC,
        MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        MERCHANT_CITY, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        MERCHANT_STATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        --Sn added by Pankaj S. for 10871
        customer_acct_no,         
        productid,
        cr_dr_flag,
        acct_type,
        error_msg,
        Time_Stamp,
        --En added by Pankaj S. for 10871
        Reversal_Code, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
         STORE_ID, --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
         --SN Added on 01.08.2013 for 11695
         FEE_PLAN,
         FEECODE,
         TRANFEE_AMT,
         FEEATTACHTYPE,
         PROXY_NUMBER
         --EN Added on 01.08.2013 for 11695  
        )
     VALUES
       (P_MSG_TYP,
        P_RRN,
        P_DELV_CHNL,
        P_TERMINAL_ID,
        V_RVSL_TRANDATE,
        P_TXN_CODE,
    --  P_TXN_TYPE, 
        V_TXN_TYPE, -- Modified by MageshKumar.S for defect Id:FSS-1248,value is passed as NULL
        P_TXN_MODE,
        DECODE(P_RESP_CDE, '00', 'C', 'F'),
        P_RESP_CDE,
        P_BUSINESS_DATE,
        SUBSTR(P_BUSINESS_TIME, 1, 10),
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        P_INST_CODE,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '9999999999990.99')),  --modified for 10871
        V_CURRCODE,
        NULL,
        v_card_type, --adde by Pankaj S. for 10871
        P_TERMINAL_ID,
        V_AUTH_ID,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '9999999999990.99')),--modified for 10871
        '0.00',--modified by Pankaj S. for 10871 
        '0.00',--modified by Pankaj S. for 10871
        P_INST_CODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_ORGNL_CUSTOMER_CARD_NO,
        P_RRN,
        V_ORGNL_BUSINESS_DATE,
        V_ORGNL_BUSINESS_TIME,
        V_ORGNL_TERMID,
        V_RESP_CDE,
        V_ACCT_BALANCE,
        V_LEDGER_BALANCE,
        V_CAP_CARD_STAT, --Added cardstatus insert in transactionlog by srinivasu.k
        V_TRAN_DESC,
           V_TXN_MERCHNAME, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         V_TXN_MERCHCITY, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         V_TXN_MERCHSTATE, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         --Sn added by Pankaj S. for 10871
         v_card_acct_no,
         v_prod_code,
          -- v_dr_cr_flag,--Commented and modified on 25.07.2013 for 11693
         decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag), 
         v_acct_type,
         v_errmsg,
         Nvl(V_Timestamp,Systimestamp),    
         --En added by Pankaj S. for 10871 
         P_Rvsl_Code ,-- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
         P_STORE_ID,  --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
          --SN Added on 01.08.2013 for 11695
         V_FEE_PLAN,
         V_FEE_CODE,
         V_FEE_AMT,
         V_FEEATTACH_TYPE,
         V_PROXUNUMBER
         --EN Added on 01.08.2013 for 11695  
        );

    EXCEPTION
     WHEN OTHERS THEN

       P_RESP_CDE := '89';
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
    END;
    --En create a entry in txn log

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
        CTD_CUSTOMER_CARD_NO_ENCR)
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
    --  P_TXN_TYPE, 
        V_TXN_TYPE, -- Modified by MageshKumar.S for defect Id:FSS-1248,value is passed as NULL
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        P_ACTUAL_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        P_ACTUAL_AMT,
        V_CARD_CURR,
        'E',
        V_ERRMSG,
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ENCR_PAN);
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69'; -- Server Decline Response 220509
       ROLLBACK;
       RETURN;
    END;

    P_RESP_MSG := V_ERRMSG;
  WHEN OTHERS THEN
    ROLLBACK TO V_SAVEPOINT;
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CDE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
     P_RESP_MSG := V_ERRMSG;
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while selecting data from response master ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69';
    END;
       
      --Sn added by Pankaj S. for 10871 
      IF v_dr_cr_flag IS NULL THEN
      BEGIN  
        SELECT ctm_credit_debit_flag, ctm_tran_desc
          INTO v_dr_cr_flag, v_tran_desc
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delv_chnl
           AND ctm_inst_code = p_inst_code;                    
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      
      IF v_prod_code is NULL THEN
      BEGIN  
        SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
          INTO v_prod_code, v_card_type, v_cap_card_stat,v_card_acct_no
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
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code --added by Pankaj S. for 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            v_acct_type --added by Pankaj S. for 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO = v_card_acct_no           
       AND CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;
   END IF;
   P_ACCT_BAL := V_ACCT_BALANCE;

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
        CURRENCYCODE,
        ADDCHARGE,
        CATEGORYID,
        ATM_NAME_LOCATION,
        AUTH_ID,
        AMOUNT,
        PREAUTHAMOUNT,
        PARTIALAMOUNT,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        TOPUP_CARD_NO_ENCR,
        ORGNL_CARD_NO,
        ORGNL_RRN,
        ORGNL_BUSINESS_DATE,
        ORGNL_BUSINESS_TIME,
        ORGNL_TERMINAL_ID,
        RESPONSE_ID,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
        TRANS_DESC,
        MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        MERCHANT_CITY, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        MERCHANT_STATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        --Sn added by Pankaj S. for 10871
        customer_acct_no,         
        productid,
        cr_dr_flag,
        acct_type,
        error_msg,
        time_stamp,
        --En added by Pankaj S. for 10871
        Reversal_Code ,-- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
        STORE_ID , --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
         --SN Added on 01.08.2013 for 11695
         FEE_PLAN,
         FEECODE,
         TRANFEE_AMT,
         FEEATTACHTYPE,
         PROXY_NUMBER
         --EN Added on 01.08.2013 for 11695  
        )
     VALUES
       (P_MSG_TYP,
        P_RRN,
        P_DELV_CHNL,
        P_TERMINAL_ID,
        V_RVSL_TRANDATE,
        P_TXN_CODE,
    --  P_TXN_TYPE, 
        V_TXN_TYPE, -- Modified by MageshKumar.S for defect Id:FSS-1248,value is passed as NULL
        P_TXN_MODE,
        DECODE(P_RESP_CDE, '00', 'C', 'F'),
        P_RESP_CDE,
        P_BUSINESS_DATE,
        SUBSTR(P_BUSINESS_TIME, 1, 10),
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        P_INST_CODE,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '9999999999990.99')),--modified for 10871
        V_CURRCODE,
        NULL,
        v_card_type,  --added by Pankaj S. for 10871
        P_TERMINAL_ID,
        V_AUTH_ID,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '9999999999990.99')),--modified for 10871
        '0.00',--modified by Pankaj S. for 10871 
        '0.00',--modified by Pankaj S. for 10871
        P_INST_CODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_ORGNL_CUSTOMER_CARD_NO,
        P_RRN,
        V_ORGNL_BUSINESS_DATE,
        V_ORGNL_BUSINESS_TIME,
        V_ORGNL_TERMID,
        V_RESP_CDE,
        V_ACCT_BALANCE,
        V_LEDGER_BALANCE,
        V_CAP_CARD_STAT, --Added cardstatus insert in transactionlog by srinivasu.k
        V_TRAN_DESC,
             V_TXN_MERCHNAME, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         V_TXN_MERCHCITY, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         V_TXN_MERCHSTATE, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         --Sn added by Pankaj S. for 10871
         v_card_acct_no,
         v_prod_code,
          -- v_dr_cr_flag,--Commented and modified on 25.07.2013 for 11693
         decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag),
         v_acct_type,
         v_errmsg,
         nvl(v_timestamp,systimestamp),    
         --En added by Pankaj S. for 10871 
         P_Rvsl_Code ,-- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
        P_STORE_ID , --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
          --SN Added on 01.08.2013 for 11695
         V_FEE_PLAN,
         V_FEE_CODE,
         V_FEE_AMT,
         V_FEEATTACH_TYPE,
         V_PROXUNUMBER
         --EN Added on 01.08.2013 for 11695  
        );

    EXCEPTION
     WHEN OTHERS THEN

       P_RESP_CDE := '89';
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
    END;
    --En create a entry in txn log

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
        CTD_CUSTOMER_CARD_NO_ENCR)
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
    --  P_TXN_TYPE, 
        V_TXN_TYPE, -- Modified by MageshKumar.S for defect Id:FSS-1248,value is passed as NULL
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        P_ACTUAL_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        P_ACTUAL_AMT,
        V_CARD_CURR,
        'E',
        V_ERRMSG,
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ENCR_PAN);
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69'; -- Server Decline Response 220509
       ROLLBACK;
       RETURN;
    END;
    P_RESP_MSG_M24 := V_ERRMSG;
END;
/
show error