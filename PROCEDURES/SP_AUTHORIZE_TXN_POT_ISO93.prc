create or replace PROCEDURE                   VMSCMS.SP_AUTHORIZE_TXN_POT_ISO93 (P_INST_CODE          IN NUMBER,
                                              P_MSG                IN VARCHAR2,
                                              P_RRN                VARCHAR2,
                                              P_DELIVERY_CHANNEL   VARCHAR2,
                                              P_TERM_ID            VARCHAR2,
                                              P_TXN_CODE           VARCHAR2,
                                              P_TXN_MODE           VARCHAR2,
                                              P_TRAN_DATE          VARCHAR2,
                                              P_TRAN_TIME          VARCHAR2,
                                              P_CARD_NO            VARCHAR2,
                                              P_BANK_CODE          VARCHAR2,
                                              P_TXN_AMT            NUMBER,
                                              P_MERCHANT_NAME      VARCHAR2,
                                              P_MERCHANT_CITY      VARCHAR2,
                                              P_MCC_CODE           VARCHAR2,
                                              P_CURR_CODE          VARCHAR2,
                                              P_POS_VERFICATION    VARCHAR2, --Modified by Deepa On June 19 2012 for Fees Changes
                                              P_CATG_ID            VARCHAR2,
                                              P_TIP_AMT            VARCHAR2,
                                              P_DECLINE_RULEID     VARCHAR2,
                                              P_ATMNAME_LOC        VARCHAR2,
                                              P_MCCCODE_GROUPID    VARCHAR2,
                                              P_CURRCODE_GROUPID   VARCHAR2,
                                              P_TRANSCODE_GROUPID  VARCHAR2,
                                              P_RULES              VARCHAR2,
                                              P_PREAUTH_DATE       DATE,
                                              P_CONSODIUM_CODE     IN VARCHAR2,
                                              P_PARTNER_CODE       IN VARCHAR2,
                                              P_EXPRY_DATE         IN VARCHAR2,
                                              P_STAN               IN VARCHAR2,
                                              P_MBR_NUMB           IN VARCHAR2,
                                              P_PREAUTH_EXPPERIOD  IN VARCHAR2,
                                              P_INTERNATIONAL_IND  IN VARCHAR2, --Changed the preauth sequence number as international indicator --Sequence no of preAuth transaction
                                              P_RVSL_CODE          IN NUMBER,
                                              P_TRAN_CNT           IN NUMBER,
                                              P_NETWORK_ID         IN VARCHAR2,
                                              P_INTERCHANGE_FEEAMT IN NUMBER,
                                              P_MERCHANT_ZIP       IN VARCHAR2,
                                              P_ADDL_AMT           IN VARCHAR2, -- Added for OLS additional amount Changes
                                              P_NETWORKID_SWITCH    IN VARCHAR2, --Added on 20130626 for the Mantis ID 11344
                                              P_NETWORKID_ACQUIRER    IN VARCHAR2,-- Added on 20130626 for the Mantis ID 11344
                                              p_network_setl_date    IN  VARCHAR2, --Added on 20130626 for the Mantis ID 11123
                                              P_CVV_VERIFICATIONTYPE IN  VARCHAR2, --Added on 17.07.2013 for the Mantis ID 11611
                                              p_partial_preauth_ind           IN       VARCHAR2,--Added on 17.09.2013 for FSS-1313
                                              p_cashbackamount_currencycode   IN       VARCHAR2, --Added by DHINAKARAN B on 23.09.2013 for FSS-1313
                                              P_PULSE_TRANSACTIONID        IN       VARCHAR2,--Added for MVHOST 926
                                              P_VISA_TRANSACTIONID          IN       VARCHAR2,--Added for MVHOST 926
                                              P_MC_TRACEID                 IN       VARCHAR2,--Added for MVHOST 926
                                             -- P_MEDAGATE_RESPVERBIAGE      IN       VARCHAR2,--Added for MVHOST 926
                                              P_CARDVERIFICATION_RESULT      IN       VARCHAR2,--Added for MVHOST 926
                                              P_ADDRVERIFY_FLAG         IN  VARCHAR2,
                                              P_ZIP_CODE              IN VARCHAR2,-- added for MVHOST-926 ON 25/05/14
                                              P_PARTIALCAHBACKFLAG     IN  VARCHAR2, --Added for 2.4.2 ols PPE changes
                                              P_AUTH_ID            OUT VARCHAR2,
                                              P_RESP_CODE          OUT VARCHAR2,
                                              P_RESP_MSG           OUT CLOB,
                                              P_LEDGER_BAL         OUT VARCHAR2,
                                              P_ISO_RESPCDE        OUT VARCHAR2,  --Added on 17.07.2013 for the Mantis ID 11612
                                              p_purchase_amt                  OUT      NUMBER--Added on 19.09.2013 for FSS-1313
                                              ,P_ADDR_VERFY_RESPONSE  out VARCHAR2-- added for MVHOST-926 ON 25/05/14
                                              ,P_MERCHANT_ID IN       VARCHAR2   DEFAULT NULL
                                              ,P_MERCHANT_CNTRYCODE in       varchar2  default null
                                              ,P_cust_addr      IN VARCHAR2   DEFAULT NULL
                                               --SN Added by Pankaj S. for DB time logging changes
                                              ,P_RESP_TIME OUT VARCHAR2
                                              ,P_RESPTIME_DETAIL OUT VARCHAR2
                                              --EN Added by Pankaj S. for DB time logging changes
                                               ,PR_acqinstcntrycode      IN VARCHAR2   DEFAULT NULL
                                              ,p_product_type IN VARCHAR2 default 'O'
                                              ,p_expiry_date_check IN VARCHAR2 default 'Y'
                                              ,p_surchrg_ind   IN VARCHAR2 DEFAULT '2' --Added for VMS-5856
                                              ,p_resp_id OUT VARCHAR2 --Added for sending to FSS (VMS-8018)
                                              ) IS
/*************************************************
  * Modified by       : Sagar M.
  * Modified Date     : 04-Feb-13
  * Modified reason   : 1) To subtract surcharge fee (P_INTERCHANGE_FEEAMT) from P_TXN_AMT
                        and pass the same to limit process
                        2) Error message passed into transactionlog table
  * Modified for      : FSS-821
  * Build Number      : CMS3.5.1_RI0019
  * Modified by       : Sagar M.
  * Modified Date     : 09-Feb-13
  * Modified reason   : 1) Product Category spend limit not being adhered to by VMS
                        2) v_resp_cde commented on 2149 on 12-Feb-2013

  * Modified for      : NA
  * Reviewer          : Dhiraj
  * Reviewed Date     : 10-Feb-13
  * Build Number      : CMS3.5.1_RI0023.2_B0001

  * Modified By       : Sagar M.
  * Modified Date     : 17-Apr-2013
  * Modified Reason   : Logging of below details in tranasctionlog and statementlog table
                        1) ledger balance in stateme    ntlog
                        2) Product code,Product cate    gory code,Card status,Acct Type,drcr flag
                        3) Timestamp and Amount valu    es logging correction
  * Reviewer          : Dhiraj
  * Reviewed Date     : 16-Apr-2013
  * Build Number      : RI0024.1_B0007

  * Modified By       : Sagar M.
  * Modified Date     : 06-May-2013
  * Modified Reason   : OLS changes
  * Reviewer          : Dhiraj
  * Reviewed Date     : 06-May-2013
  * Build Number      : RI0024.1.1_B0001

  * Modified By       : MageshKumar.S
  * Modified Date     : 10-May-2013
  * Modified Reason   : OLS additional amount changes
  * Reviewer          : Dhiraj
  * Reviewed Date     : 16-May-2013
  * Build Number      : RI0024.1.1_B0001

   * Modified by      : Ravi N
   * Modified for      : Mantis ID 0011282
   * Modified Reason  : Correction of Insufficient balance spelling mistake
   * Modified Date    : 20-Jun-2013
   * Reviewer         : Dhiraj
   * Reviewed Date    : 20-Jun-2013
   * Build Number     : RI0024.2_B0006

   * Modified by      : Deepa T
   * Modified for     : Mantis ID 11344,11123
   * Modified Reason  : Log the AcquirerNetworkID received in tag 005 and TermFIID received in tag 020 ,
                        Logging of network settlement date for OLS transactions
   * Modified Date    : 26-Jun-2013
   * Reviewer         : Dhiraj
   * Reviewed Date    : 27-06-2013
   * Build Number     : RI0024.2_B0009

   * Modified by      : Sachin P.
   * Modified for     : Mantis ID -11611,11612
   * Modified Reason  : 11611-Input parameters needs to be included for the CVV verification
                        We are doing and it needs to be logged in transactionlog
                        11612-Output parameter needs to be included to return the cms_iso_respcde of cms_response_mast
   * Modified Date    : 17-Jul-2013
   * Reviewer         : Sagarm
   * Reviewed Date    : 22.07.2013
   * Build Number     : RI0024.3_B0005

   * Modified by      : Sagar m.
   * Modified for     : 0012198
   * Modified Reason  : To reject duplicate STAN transaction
   * Modified Date    : 29-Aug-2013
   * Reviewer         : Dhiarj
   * Reviewed Date    : 29-Aug-2013
   * Build Number     : RI0024.3.5_B0001

   * Modified by       :  Sachin P.
   * Modified for      :  FSS-1313 (1.7.3.8 changes merged)
   * Modified Reason   :  Cashback Changes
   * Modified Date     :  17-Sep-2013
   * Reviewer          :  Dhiraj
   * Reviewed Date     :
   * Build Number      :  RI0024.4.1_B0001

   * Modified by       :  DHINAKARAN B
   * Modified for      :  FSS-1313 (1.7.3.8 changes merged)
   * Modified Reason   :  Cashback Changes
   * Modified Date     :  24-Sep-2013
   * Reviewer          :  Dhiraj
   * Reviewed Date     :
   * Build Number      :  RI0024.4.1_B0001

   * Modified by       : Siva Kumar M
   * Modified for      : LYFEHOST-74
   * Modified Date     : 19-sep-2013
   * Reviewer          : Dhiraj
   * Reviewed Date     : 19-sep-2013
   * Build Number      : RI0024.5_B0001

   * Modified by       :  Deepa T
   * Modified for      :  Mantis ID-12736,12739 (Partial approval of Purchase and Purchase Cashback transaction response code Changes)
   * Modified Reason   :  1.7.4.3_B0001 (OLS) changes merged
   * Modified Date     :  17-OCT-2013
   * Reviewer          :  Dhiraj
   * Reviewed Date     :  17-OCT-2013
   * Build Number      :  RI0024.5_B0006

   * Modified by      : Sachin P
   * Modified for     : 12568
   * Modified Reason  : Purchase Transaction with Partial Indiator, Fee and P-4 >
                        Account Bal. is failing with Insufficient Balance.
   * Modified Date    : 29.Oct.2013
   * Reviewer         : Dhiraj
   * Reviewed Date    : 29.Oct.2013
   * Build Number     : RI0024.6_B0004

   * Modified by      : suvin.s
   * Modified for     : 13037
   * Modified Reason  : To integrate the patches of 1.7.3.11 to 1.7.6.1 (To Pass NULL value for International Indicator and POSVerification for the Merchandise Return transactions)
   * Modified Date    : 21.NOV.2013
   * Reviewer         : Dhiraj
   * Reviewed Date    :
   * Build Number     : RI0024.6.1_B0001

   * Modified Date    : 10-Dec-2013
   * Modified By      : Sagar More
   * Modified for     : Defect ID 13160
   * Modified reason  : NVL added for TIP and INTERCHANGE_FEEAMT amount logging
   * Reviewer         : Dhiraj
   * Reviewed Date    : 10-Dec-2013
   * Release Number   : RI0024.7_B0001

   * modified by       : Ramesh A
   * modified Date     : FEB-05-14
   * modified reason   : MVCSD-4471
   * modified reason   :
   * Reviewer          : Dhiraj
   * Reviewed Date     :
   * Build Number      : RI0027.1_B0001

   * Modified by       : Sagar
   * Modified for      :
   * Modified Reason   : Concurrent Processsing Issue
                         (1.7.6.7 changes integarted)
   * Modified Date     : 25-Feb-2014
   * Reviewer          : Dhiarj
   * Reviewed Date     : 25-Feb-2014
   * Build Number      : RI0027.1.1_B0001

 * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13893
     * Modified Reason   : Added card number for duplicate RRN check
     * Modified Date     : 06-Mar-2014
     * Reviewer          : Dhiraj
     * Reviewed Date     : 10-Mar-2014
     * Build Number      : RI0027.2_B0001

     * Modified by       : Dhinakaran B
     * Modified for      : VISA Certtification Changes integration in 2.2.2
     * Modified Date     : 01-JUL-2014
     * Build Number      : RI0027.2.2_B0001

     * Modified by      : Saravanakumar
     * Modified for      : Performance changes
     * Modified Date    : 16-Sep-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.2.6.1

     * Modified Date    : 29-SEP-2014
     * Modified By      : Abdul Hameed M.A
     * Modified for     : FWR 70
     * Reviewer         : Spankaj
     * Release Number   : RI0027.4_B0001

     * Modified Date    : 11-Nov2014
     * Modified By      : Dhinakaran B
     * Modified for     : MVHOST-1041
     * Reviewer         : Spankaj
     * Release Number   : RI0027.4.2.1

     * Modified By      : MageshKumar S
     * Modified Date    : 18-Nov-2014
     * Modified for     : PPE Changes
     * Reviewer         : Saravanakumar
     * Release Number   : RI0027.4.2.2_B0001

     * Modified Date    : 11-DEC-2014
     * Modified By      : MageshKumar S
     * Modified for     : OLS Perf Improvement - Mantis:15855
     * Reviewer         : spankaj
     * Release Number   : RI0027.4.2.4

     * Modified Date    : 30-DEC-2014
     * Modified By      : Dhinakaran B
     * Modified for     : MVHOST-1080/To Log the Merchant id & CountryCode
     * Reviewer         :
     * Reviewed Date    :
     * Release Number   :

     * Modified by      : MAGESHKUMAR S.
     * Modified Date    : 03-FEB-2015
     * Modified For     : 2.4.2.4.1 & 2.4.3.1 integration
     * Reviewer         : PANKAJ S.
     * Build Number     : RI0027.5_B0006

     * Modified By      : MageshKumar S
     * Modified Date    : 11-FEB-2015
     * Modified for     : INSTCODE REMOVAL(2.4.2.4.2 & 2.4.3.1 integration)
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0007

      * Modified By      : Abdul Hameed M.A
     * Modified Date    : 11-FEB-2015
     * Modified for     : OLS AVS Address check
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0007

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 19-FEB-2015
     * Modified for     : Added card load check txn code
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0008

      * Modified By      : Pankaj S.
     * Modified Date    : 26-Feb-2015
     * Modified For     : 2.4.2.4.4/2.4.3.3 PERF Changes integration
     * Reviewer         : Sarvanankumar
     * Build Number     : RI0027.5_B0009

     * Modified Date    : 20-Mar-2015
     * Modified By      : Ramesh A
     * Modified for     : FSS-2281
     * Reviewer         : Spankaj
     * Release Number   : 3.0

     * Modified By      :  Siva Kumar m
     * Modified For     :   VCSD-5617
     * Modified Date    :  28-May-2015
     * Reviewer         :  Saravana Kumar A
     * Build Number     : VMSGPRHOSTCSD_3.0.3_B0001

     * Modified by      : Pankaj S.
     * Modified for     : Transactionlog Functional Removal
     * Modified Date    : 13-May-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOSTCSD_3.0.3_B0001

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

    * Modified by      : Ramesh A
    * Modified for     : FSS-4362
    * Modified Date    : 19-May-2016
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOST_4.1_B0001

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 10-JUN-2016
     * Modified for     : Closed Loop Product Changes
     * Reviewer         : Spankaj
     * Release Number   : VMSGPRHOST_4.2_B0001

     * Modified By      : Saravanakumar A
     * Modified Date    : 08-Aug-2016
     * Modified for     :
     * Reviewer         : Spankaj
     * Release Number   : VMSGPRHOST_4.7_B0001

    * Modified by      : Pankaj S.
    * Modified Date    : 07/Oct/2016
    * PURPOSE          : FSS-4755
    * Review           : Saravana
    * Build Number     : VMSGPRHOST_4.10
        * Modified by      : Saravanakumar
    * Modified Date    : 20-Mar-17
    * Modified For     : FSS-4647
    * Modified reason  : Redemption Delay Changes
    * Reviewer         : Pankaj S.
    * Build Number     : VMSGPRHOST_17.3

      * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07
* Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07
    * Modified By      : MageshKumar S
    * Modified Date    : 18/07/2017
    * Purpose          : FSS-5157
    * Reviewer         : Saravanan/Pankaj S.
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
                   * Modified by       : Akhil
     * Modified Date     : 05-JAN-18
     * Modified For      : VMS-103
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.12
     
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01

     * Modified By      : DHINAKARAN B
     * Modified Date    : 15-NOV-2018
     * Purpose          : VMS-619 (RULE)
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R08 
	 
	 * Modified By      : BASKAR KRISHNAN
     * Modified Date    : 06-MAY-2020
     * Purpose          : VMS-1374 
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R30
     
     * Modified By      : MAGESHKUMAR
     * Modified Date    : 16-JUNE-2020
     * Purpose          : VMS-2709(Refactor MR processing logic to directly enforce limit check without any prior validations)
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : R32_build_1
	 
	 * Modified by      : Pankaj S.
     * Modified for     : VMS-5856
     * Modified Date    : 29-Jun-2022
     * Reviewer         : Venkat S.
     * Build Number     : R65
     
      * Modified By     : Bhavani E
     * Modified Date    : 11-OCT-2022
     * Purpose          : VMS-5546
     * Reviewer         : VENKAT S.
     * Release Number   : VMSGPRHOST R70

	 * Modified by      : Areshka A.
     * Modified for     : VMS-8018: Added new out parameter (response id) for sending to FSS
     * Modified Date    : 03-Nov-2023
     * Reviewer         : 
     * Build Number     : 
**************************************************/
  V_ERR_MSG            VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE       NUMBER;
  V_LEDGER_BAL         NUMBER;
  V_TRAN_AMT           NUMBER;
  V_AUTH_ID            TRANSACTIONLOG.AUTH_ID%TYPE;
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
  V_TRANS_DESC         VARCHAR2(50);
  V_FEE_OPENING_BAL    NUMBER;
  V_RESP_CDE           VARCHAR2(5);
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
  V_ATM_USAGEAMNT       CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT       CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  V_ATM_USAGELIMIT      CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT      CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_MMPOS_USAGEAMNT     CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
  V_MMPOS_USAGELIMIT    CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
  V_PREAUTH_DATE        DATE;
  V_PREAUTH_HOLD        VARCHAR2(1);
  V_PREAUTH_PERIOD      NUMBER;
  V_PREAUTH_USAGE_LIMIT NUMBER;
  V_CARD_ACCT_NO        VARCHAR2(20);
  V_HOLD_AMOUNT         NUMBER                        := 0; -- Modified for OLS Transaction change
  V_HASH_PAN            CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT           NUMBER;
  V_TRAN_TYPE           VARCHAR2(2);
  V_DATE                DATE;
  V_TIME                VARCHAR2(10);
  V_MAX_CARD_BAL        NUMBER;
  V_CURR_DATE           DATE;
  V_PREAUTH_EXP_PERIOD  VARCHAR2(10);
  --V_MINI_STAT_RES       CLOB;
  V_MINI_STAT_VAL       VARCHAR2(100);
  V_INTERNATIONAL_FLAG  cms_prod_cattype.cpc_international_check%TYPE;
 -- V_TRAN_CNT            NUMBER;
  V_PROXUNUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_STATUS_CHK          NUMBER;
  --Added by Deepa On June 19 2012 for Fees Changes
  V_FEEAMNT_TYPE CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES     CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES    CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK     CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN     CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_FREETXN_EXCEED VARCHAR2(1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_DURATION VARCHAR2(20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_FEEATTACH_TYPE  VARCHAR2(2); -- Added by Trivikram on 5th Sept 2012
  V_LIMIT_AMT       number;      -- Added on 04-Feb-2013 to Subtract surcharge fee from txn amount and validate the same using limit package
  V_PRFL_CODE   CMS_APPL_PAN.CAP_PRFL_CODE%type ;
  v_comb_hash                    pkg_limits_check.type_hash;
  V_PRFL_FLAG     CMS_TRANSACTION_MAST.CTM_PRFL_FLAG%TYPE ;
  V_CAM_TYPE_CODE   cms_acct_mast.cam_type_code%type; -- Added on 17-Apr-2013 for defect 10871
  v_timestamp       timestamp;                         -- Added on 17-Apr-2013 for defect 10871
  v_cms_iso_respcde       cms_response_mast.cms_iso_respcde%TYPE;  -- Modified for OLS Transaction change
  V_STAN_COUNT                  NUMBER; -- Added for Duplicate Stan check 0012198
  v_purchase_amt          NUMBER;         --Added on 17.09.2013 for FSS-1313
  v_cashback_amt          NUMBER;         --Added on 17.09.2013 for FSS-1313
  v_partial_appr          VARCHAR2 (1);   --Added on 19.09.2013 for FSS-1313
  V_NETWORKIDCOUNT  number default 0; -- lyfe changes.
  v_partial_appr_cashback VARCHAR2 (1) default 'N'; --Mantis ID-12545,12564
v_fee_desc        cms_fee_mast.cfm_fee_desc%TYPE;  -- Added for MVCSD-4471

--Implement  The VISA Certification Changes
 V_CAP_CUST_CODE    CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
  v_txn_nonnumeric_chk    VARCHAR2 (2);
  v_cust_nonnumeric_chk   VARCHAR2 (2);
  V_ADDRVRIFY_FLAG            CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_CHECK%TYPE;
  V_ENCRYPT_ENABLE           CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  V_ADDRVERIFY_RESP           CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_RESPONSE%TYPE;
  V_ZIP_CODE                 cms_addr_mast.cam_pin_code%type;
  v_first3_custzip         cms_addr_mast.cam_pin_code%type;
  v_inputzip_length        number(3);
  v_numeric_zip            cms_addr_mast.cam_pin_code%type;
  v_removespace_txn       VARCHAR2 (10);
  v_removespace_cust      VARCHAR2 (10);
  v_zip_code_trimmed VARCHAR2(10); --Added for 15165

   --SN Added for FWR 70
     v_removespacenum_txn  VARCHAR2 (10);
V_REMOVESPACENUM_CUST   VARCHAR2 (10);
V_REMOVESPACECHAR_TXN   varchar2 (10);
V_REMOVESPACECHAR_CUST   VARCHAR2 (10);
--EN Added for FWR 70
v_mrlimitbreach_count  number default 0;
v_mrminmaxlmt_ignoreflag  VARCHAR2 (1) default 'N';
V_REPEAT_MSGTYPE           TRANSACTIONLOG.MSGTYPE%TYPE DEFAULT '1201';
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

 V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;

 --Added for FSS-4362
  V_LOGIN_TXN       CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;
  V_ACTUAL_FEE_AMNT NUMBER;
  V_CLAWBACK_AMNT   CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK_COUNT  NUMBER;
  v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE;
  v_chrg_dtl_cnt    NUMBER;
    v_redemption_delay_flag cms_acct_mast.cam_redemption_delay_flag%type;
  v_delayed_amount number:=0;
  V_PROFILE_CODE CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  V_CPC_B2B_LMTPRFL CMS_PROD_CATTYPE.CPC_B2B_LMTPRFL%TYPE;
  v_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   v_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
     v_cnt       number;
         v_card_stat                  cms_appl_pan.cap_card_stat%TYPE   := '12';
            v_enable_flag                VARCHAR2 (20)                          := 'Y';
   v_initialload_amt         cms_acct_mast.cam_new_initialload_amt%type;

 /* CURSOR C_MINI_TRAN IS
    SELECT Z.*
     FROM (SELECT TO_CHAR(CSL_TRANS_DATE, 'MM/DD/YYYY') || ' ' ||
                CSL_TRANS_TYPE || ' ' ||
                TRIM(TO_CHAR(CSL_TRANS_AMOUNT, '99999999999999990.99'))

            FROM CMS_STATEMENTS_LOG
           WHERE CSL_PAN_NO = GETHASH(P_CARD_NO)
           ORDER BY CSL_TRANS_DATE DESC) Z
    WHERE ROWNUM <= V_TRAN_CNT; */

BEGIN
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE := '1';
  -- P_ERR_MSG        := 'OK';
  P_RESP_MSG := 'OK';
  v_partial_appr := 'N';                  --Added on 19.09.2013 for FSS-1313
  v_start_time := systimestamp;   --Added by Pankaj S. for DB time logging changes

  V_LIMIT_AMT := NVL(P_TXN_AMT,0) - NVL(P_INTERCHANGE_FEEAMT,0); --Subtracting surcharge fee from txn amount FSS-821 , added on 04-Feb-2013

  BEGIN
    --SN CREATE HASH PAN
    --Gethash is used to hash the original Pan no
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
    --Fn_Emaps_Main is used for Encrypt the original Pan no
    BEGIN
     V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

      v_timestamp := systimestamp;

       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_CARD_NO||P_RRN||to_char(V_TIMESTAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        V_RESP_CDE := '21';
        V_ERR_MSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     end;


     --Sn find debit and credit flag
    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,CTM_TRAN_DESC,CTM_PRFL_FLAG,CTM_LOGIN_TXN
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_TRANS_DESC,V_PRFL_FLAG,V_LOGIN_TXN
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
       V_RESP_CDE := '21'; --Ineligible Transaction
       V_ERR_MSG  := 'Error while selecting transaction details';
       RAISE EXP_REJECT_RECORD;
    END;

    --En find debit and credit flag

    --Sn generate auth id
    BEGIN
     --     SELECT TO_CHAR(SYSDATE, 'YYYYMMDD')|| LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
     SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Error while generating authid ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21'; -- Server Declined
       RAISE EXP_REJECT_RECORD;
    END;

    --En generate auth id

     --Sn find card detail
    --Moved by saravanakumar on 16-Sep-2014
    BEGIN
     SELECT CAP_PROD_CODE,
           CAP_CARD_TYPE,
           CAP_EXPRY_DATE,
           CAP_CARD_STAT,
           CAP_ATM_ONLINE_LIMIT,
           CAP_POS_ONLINE_LIMIT,
           CAP_PROXY_NUMBER,
           CAP_ACCT_NO,
           CAP_PRFL_CODE -- Added on 06-Feb-2013
           ,CAP_CUST_CODE
       INTO V_PROD_CODE,
           V_PROD_CATTYPE,
           V_EXPRY_DATE,
           V_APPLPAN_CARDSTAT,
           V_ATMONLINE_LIMIT,
           V_ATMONLINE_LIMIT,
           V_PROXUNUMBER,
           V_ACCT_NUMBER,
           V_PRFL_CODE    -- Added on 06-Feb-2013
           ,V_CAP_CUST_CODE
       FROM CMS_APPL_PAN
      WHERE CAP_PAN_CODE = V_HASH_PAN;
     -- AND CAP_INST_CODE = P_INST_CODE; --For Instcode removal of 2.4.2.4.2 release
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
     BEGIN
        SELECT cpc_profile_code, 
               CPC_ADDR_VERIFICATION_CHECK, 
               cpc_international_check, 
	       CPC_ENCRYPT_ENABLE,
	       cpc_badcredit_flag,
	       cpc_badcredit_transgrpid, 
	       NVL(CPC_ADDR_VERIFICATION_RESPONSE, 'U'),
           CPC_B2B_LMTPRFL
        INTO V_PROFILE_CODE, 
             V_ADDRVRIFY_FLAG, 
             V_INTERNATIONAL_FLAG,
	     V_ENCRYPT_ENABLE,
	     v_badcredit_flag,
	     v_badcredit_transgrpid , 
	     V_ADDRVERIFY_RESP,
         v_CPC_B2B_LMTPRFL
        FROM cms_prod_cattype
        WHERE  cpc_inst_code = p_inst_code
           AND cpc_prod_code = v_prod_code
           AND cpc_card_type = V_PROD_CATTYPE;
        EXCEPTION
        WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG :='Profile code not defined for product code ' || v_prod_code|| 'card type '|| V_PROD_CATTYPE ||SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
        END;


    --EN create encr pan
  /*  IF P_DELIVERY_CHANNEL = '07' AND P_TXN_CODE = '04' THEN
     IF P_TRAN_CNT IS NULL THEN

       BEGIN */
          --Commended by saravanakumar on 16-Sep-2014
        /*SELECT CAP_PROD_CODE
          INTO V_PROD_CODE
          FROM CMS_APPL_PAN
         WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;*/

    /*    SELECT TO_NUMBER(CBP_PARAM_VALUE)
          INTO V_TRAN_CNT
          FROM CMS_BIN_PARAM
         WHERE CBP_INST_CODE = P_INST_CODE AND
              CBP_PARAM_NAME = 'TranCount_For_RecentStmt' AND
              CBP_PROFILE_CODE IN
              (SELECT CPM_PROFILE_CODE
                FROM CMS_PROD_MAST
                WHERE CPM_PROD_CODE = V_PROD_CODE);
       EXCEPTION
        WHEN OTHERS THEN
          V_TRAN_CNT := 10;
       END;
     ELSE
       V_TRAN_CNT := P_TRAN_CNT;
     END IF;

    END IF; */

    --sN CHECK INST CODE
    /*BEGIN
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
    END;*/--Commanded by saravanakumar on 16-Sep-2014

    --eN CHECK INST CODE

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

    --En get date
    /*
      -----------------------------------------
      --SN: Added for Duplicate STAN check 0012198
      -----------------------------------------

      BEGIN

        SELECT COUNT(1)
         INTO V_STAN_COUNT
         FROM TRANSACTIONLOG
        WHERE INSTCODE = P_INST_CODE
        AND   CUSTOMER_CARD_NO  = V_HASH_PAN
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
 /*   BEGIN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND --Changed for admin dr cr.
           BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERR_MSG  := 'Duplicate RRN from the Terminal ' || P_TERM_ID ||
                  ' on ' || P_TRAN_DATE;
       RAISE EXP_REJECT_RECORD;
     END IF;
    END;
*/
-- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
/* BEGIN
      sp_dup_rrn_check (v_hash_pan, p_rrn, p_tran_date, p_delivery_channel, p_msg, p_txn_code, v_err_msg );
      IF v_err_msg <> 'OK' THEN
        v_resp_cde := '22';
        RAISE exp_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '22';
      v_err_msg  := 'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END; */ --OLS Perf Improvement
    --En Duplicate RRN Check

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
  /*  BEGIN
     IF P_TXN_CODE = '04' AND P_DELIVERY_CHANNEL = '07' THEN
       IF TO_NUMBER(P_TRAN_CNT) = '0' THEN
        V_RESP_CDE := '90';
        V_ERR_MSG  := 'Minimum Transaction Count should be greater than 0 ';
        RAISE EXP_REJECT_RECORD;
       ELSIF TO_NUMBER(P_TRAN_CNT) > '10' THEN
        V_RESP_CDE := '90';
        V_ERR_MSG  := 'Maximum Transaction Count should not be greater than 10 ';
        RAISE EXP_REJECT_RECORD;
       END IF;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error Occured while finding the service tax' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END; */
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

    --Sn find the tran amt
    IF ((V_TRAN_TYPE = 'F') OR (P_MSG = '0100')) THEN
     IF (P_TXN_AMT >= 0) THEN
       V_TRAN_AMT := P_TXN_AMT;

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
          RAISE EXP_REJECT_RECORD;
        END IF;
       EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
          V_RESP_CDE := '69'; -- Server Declined -220509
          V_ERR_MSG  := 'Error from currency conversion ' ||
                     SUBSTR(SQLERRM, 1, 200);
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



    --En find card detail
IF P_TXN_CODE <> '25' THEN
   IF NOT (p_product_type='C' AND  p_expiry_date_check='N') THEN
    --- st Expiry date validation for ols changes
     BEGIN
     IF P_EXPRY_DATE <> TO_CHAR(V_EXPRY_DATE, 'YYMM') THEN
       -- V_RESP_CDE := '13';   commented -- mvcsd-5617
       -- V_ERR_MSG  := 'EXPIRY DATE NOT EQUAL TO APPL EXPRY DATE ';

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

    END IF;
    -- added for MVHOST-926
END IF;


    v_zip_code_trimmed:=TRIM(P_ZIP_CODE); --Added for 15165

   --St: Added for OLS  changes( AVS and ZIP validation changes)
     IF V_ADDRVRIFY_FLAG = 'Y' AND P_ADDRVERIFY_FLAG in('2','3') then

       if P_ZIP_CODE is null then
           
              IF P_TXN_CODE <> '25' THEN

               V_RESP_CDE := '105';
               V_ERR_MSG  := 'Required Property Not Present : ZIP';
               RAISE EXP_REJECT_RECORD;
              ELSE
                P_ADDR_VERFY_RESPONSE := 'U';
            END IF;

            ELSIF trim(P_ZIP_CODE) is null then   --tag present but value empty or space

               P_ADDR_VERFY_RESPONSE := 'U';

      ELSE

           BEGIN
           
               SELECT decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(CAM_PIN_CODE),CAM_PIN_CODE),
                decode(V_ENCRYPT_ENABLE,'Y',trim(fn_dmaps_main(cam_add_one)),trim(cam_add_one)),
                decode(v_encrypt_enable,'Y',trim(fn_dmaps_main(cam_add_two)),trim(cam_add_two))
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

                    --if  p_zip_code = v_zip_code then -- Commented on 20/12/13 for FSS-1388
             --    IF SUBSTR (p_zip_code, 1, 5) = SUBSTR (v_zip_code, 1, 5) then -- Added on 20/12/13 for FSS-1388


             IF SUBSTR (v_zip_code_trimmed, 1, 5) = SUBSTR (v_zip_code, 1, 5) then   --Modified for 15165

                      P_ADDR_VERFY_RESPONSE := 'W';
                 else
                      P_ADDR_VERFY_RESPONSE := 'N';
                 end if;

        elsif v_txn_nonnumeric_chk <> '0' and v_cust_nonnumeric_chk = '0' then -- It Means txn zip code is aplhanumeric and cust zip code is numeric

              --  if  p_zip_code = v_zip_code then
              IF v_zip_code_trimmed=v_zip_code THEN  --Modified for 15165

                     P_ADDR_VERFY_RESPONSE := 'W';
                else

                      P_ADDR_VERFY_RESPONSE := 'N';
                end if;

        elsif v_txn_nonnumeric_chk = '0' and v_cust_nonnumeric_chk <> '0' then -- It Means txn zip code is numeric and cust zip code is alphanumeric

                   SELECT REGEXP_REPLACE(v_zip_code,'([A-Z ,a-z ])', '') into v_numeric_zip FROM dual;

             --  if  p_zip_code = v_numeric_zip then
               IF v_zip_code_trimmed=v_numeric_zip THEN  --Modified for 15165

                   P_ADDR_VERFY_RESPONSE := 'W';
               else
                   P_ADDR_VERFY_RESPONSE := 'N';

               end if;

        elsif v_txn_nonnumeric_chk <> '0' and v_cust_nonnumeric_chk <> '0' then -- It Means txn zip code and cust zip code is alphanumeric

                  v_inputzip_length := length(p_zip_code);


                 if v_inputzip_length = length(v_zip_code) then  -- both txn and cust zip length is equal

                   --   if  p_zip_code = v_zip_code then
                   IF v_zip_code_trimmed=v_zip_code THEN  --Modified for 15165

                                P_ADDR_VERFY_RESPONSE := 'W';
                      else
                                 P_ADDR_VERFY_RESPONSE := 'N';

                      end if;

                 else

                         SELECT REGEXP_REPLACE(p_zip_code,'([ ])', '') into v_removespace_txn from dual;

                         SELECT REGEXP_REPLACE(v_zip_code,'([ ])', '') into v_removespace_cust from dual;

                         if v_removespace_txn =  v_removespace_cust then

                                   P_ADDR_VERFY_RESPONSE := 'W';

                         --elsif v_inputzip_length >=3 then --Commented for defect : 13297 on 26/12/13
                         elsif length(v_removespace_txn) >=3 then --Added for defect : 13297 on 26/12/13

                         --if substr(p_zip_code,1,3) = v_first3_custzip then  --Commented for defect : 13297 on 26/12/13
                            if substr(v_removespace_txn,1,3) = substr(v_removespace_cust,1,3) then  --Added for defect : 13297 on 26/12/13

                             P_ADDR_VERFY_RESPONSE := 'W';
                               --SN Added for FWR 70
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
                           --EN Added for FWR 70
                          else
                                  P_ADDR_VERFY_RESPONSE := 'N';

                          end if;

                         else  --Added for defect : 13296 on 26/12/13
                          P_ADDR_VERFY_RESPONSE := 'N'; --Added for defect : 13296 on 26/12/13

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

    -- END IF;
    --END Added for OLS  changes( AVS and ZIP validation changes)


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
end if;

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
                     P_POS_VERFICATION,  --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
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
        V_ERR_MSG  := 'EXPIRED CARD ISSUE';
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


    

    --Sn check for Preauth
     IF P_TXN_CODE <> '25' THEN
    IF V_PREAUTH_FLAG = 1 THEN
     BEGIN
       SP_PREAUTHORIZE_TXN(P_CARD_NO,
                       P_MCC_CODE,
                       P_CURR_CODE,
                       V_TRAN_DATE,
                       P_TXN_CODE,
                       P_INST_CODE,
                       P_TRAN_DATE,
                       V_TRAN_AMT,
                       P_DELIVERY_CHANNEL,
                       V_RESP_CDE,
                       V_ERR_MSG,
                       P_MERCHANT_ID,  --Added for FSS-2281
                       P_MERCHANT_CNTRYCODE --Added for FSS-2281
                       ,PR_acqinstcntrycode
                       );

       IF (V_RESP_CDE <> '1' OR TRIM(V_ERR_MSG) <> 'OK') THEN

        RAISE EXP_REJECT_RECORD; --Modified by Deepa on Apr-30 to send separate response for rule
        /*IF (V_RESP_CDE = '70' OR TRIM(V_ERR_MSG) <> 'OK') THEN
            V_RESP_CDE := '70';
            RAISE EXP_REJECT_RECORD;
          ELSE
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          END IF;*/
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
END IF;
    --En check for preauth
--SN - Commented for FWR-48
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
    END;*/
--EN - Commented for FWR-48
    --En find function code attached to txn code
    --Sn find prod code and card type and available balance for the card number
    BEGIN
    -- SN added changes for VMS-5546 by Bhavani
    IF (P_DELIVERY_CHANNEL = '02' AND P_TXN_CODE='31') THEN  -- Added changes for VMS-5546 by Bhavani
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
            CAM_TYPE_CODE,nvl(cam_redemption_delay_flag,'N'),
            nvl(cam_new_initialload_amt,cam_initialload_amt)                               
       INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,
            V_CAM_TYPE_CODE,v_redemption_delay_flag ,v_initialload_amt                              
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER
        AND CAM_INST_CODE = P_INST_CODE;
          -- FOR UPDATE;                        -- Commented for Concurrent Processsing Issue for VMS-5546
     ELSE     
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
            CAM_TYPE_CODE,nvl(cam_redemption_delay_flag,'N'),
            nvl(cam_new_initialload_amt,cam_initialload_amt)                                  -- Added on 17-Apr-2013 for defect 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,
            V_CAM_TYPE_CODE,v_redemption_delay_flag ,v_initialload_amt                               -- Added on 17-Apr-2013 for defect 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER--Modified by saravanakumar on 16-Sep-2014
           /*(SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE)*/ AND
           CAM_INST_CODE = P_INST_CODE
           FOR UPDATE;                      -- Added for Concurrent Processsing Issue
          --FOR UPDATE NOWAIT;                -- Commented for Concurrent Processsing Issue
    END IF;   
     -- EN added changes for VMS-5546 by Bhavani
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14'; --Ineligible Transaction
       V_ERR_MSG  := 'Invalid Card ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12';
       V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;

 IF P_TXN_CODE <> '25' THEN
    if v_redemption_delay_flag='Y' then
            vmsredemptiondelay.check_delayed_load(v_acct_number,v_delayed_amount,v_err_msg);
              if v_err_msg<>'OK' then
                 RAISE exp_reject_record;
              end if;
         if v_delayed_amount>0 then
                v_acct_balance :=v_acct_balance-v_delayed_amount;
         end if;
    end if;
    
END IF;

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
    ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------
      IF P_MSG NOT IN ('1200' ,'1120','1100') THEN  --Added by Pankaj S. for PERF changes
      BEGIN

        SELECT COUNT(1)
         INTO V_STAN_COUNT
         FROM TRANSACTIONLOG
        WHERE --INSTCODE = P_INST_CODE AND    --For Instcode removal of 2.4.2.4.2 release
        CUSTOMER_CARD_NO  = V_HASH_PAN
        AND   BUSINESS_DATE = P_TRAN_DATE
        AND   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND   ADD_INS_DATE BETWEEN TRUNC(SYSDATE-1)  AND SYSDATE
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
       END IF;  --Added by Pankaj S. for PERF changes

  /*  BEGIN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND --Changed for admin dr cr.
           BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERR_MSG  := 'Duplicate RRN from the Terminal ' || P_TERM_ID ||
                  ' on ' || P_TRAN_DATE;
       RAISE EXP_REJECT_RECORD;
     END IF;
    END;
   */
   -- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
 BEGIN
    IF V_REPEAT_MSGTYPE = p_msg THEN
      sp_dup_rrn_check (v_hash_pan, p_rrn, p_tran_date, p_delivery_channel, p_msg, p_txn_code, v_err_msg );
      IF v_err_msg <> 'OK' THEN
        v_resp_cde := '22';
        RAISE exp_reject_record;
      END IF;
    END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '22';
      v_err_msg  := 'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
    END;

    ------------------------------------------------------
        --En Added for Concurrent Processsing Issue
    ------------------------------------------------------


    --SN Added on 17.09.2013 for FSS-1313
      --Added the TO_NUMBER and TRIM function  for FSS-1313
      IF     TO_NUMBER (p_partial_preauth_ind) = 1 THEN --Modified for Mantis ID-12545,12564

         IF  ((UPPER (TRIM (p_networkid_switch)) = 'PULSE')OR  (UPPER (TRIM (p_networkid_switch)) = 'VISANET'))
         AND p_txn_code = '16'
         AND p_delivery_channel = '02'
         THEN

             IF p_addl_amt IS NOT NULL
             THEN
                BEGIN
                   sp_convert_curr (p_inst_code,
                                    p_cashbackamount_currencycode,
                                    p_card_no,
                                    p_addl_amt,
                                    v_tran_date,
                                    v_cashback_amt,
                                    v_card_curr,
                                    v_err_msg,
                                    V_PROD_CODE,
                                    V_PROD_CATTYPE);

                   IF v_err_msg <> 'OK'
                   THEN
                      v_resp_cde := '44';
                      RAISE exp_reject_record;
                   END IF;
                EXCEPTION
                   WHEN exp_reject_record
                   THEN
                      RAISE;
                   WHEN OTHERS
                   THEN
                      v_resp_cde := '69';              -- Server Declined -220509
                      v_err_msg :=
                            'Error from currency conversion 1.1 '
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record;
                END;

                --Added for FSS-1313  to compare  cash back amount with the tran amount
                IF v_tran_amt < v_cashback_amt
                THEN
                   v_resp_cde := '43';
                   v_err_msg := 'Cash back amount is greater than the txn amount';
                   RAISE exp_reject_record;
                END IF;

                IF v_acct_balance < v_tran_amt or P_PARTIALCAHBACKFLAG = 'Y' --Condition added for ols PPE changes
                THEN
                   v_purchase_amt := NVL (v_tran_amt, 0)
                                     - NVL (v_cashback_amt, 0);
                   v_tran_amt := v_purchase_amt;
                   p_purchase_amt := v_purchase_amt;
                   v_partial_appr_cashback := 'Y';--Modified for Mantis ID-12545,12564 := 'Y';
                   V_LIMIT_AMT :=v_tran_amt;
                END IF;
             END IF;
          ELSIF p_txn_code = '14' AND p_delivery_channel = '02'  --Sn Added to support Partial Purchase for Mantis ID-12545,12564
               THEN

                  IF v_acct_balance <= 0
                  THEN
                     v_resp_cde := '15';
                     v_err_msg :=
                                 'Account Balance is Zero or Less Than Zero ';
                     RAISE exp_reject_record;
                  END IF;


                 IF v_tran_amt > v_acct_balance THEN
                   v_tran_amt := v_acct_balance;
                   p_purchase_amt := v_tran_amt;
                   v_partial_appr := 'Y';
                   V_LIMIT_AMT :=v_tran_amt;

                 END IF;
         END IF; --En Added to support Partial Purchase for Mantis ID-12545,12564
      END IF;

      --EN Added on 17.09.2013 for FSS-1313

    --Sn Internation Flag check
IF P_TXN_CODE <> '25' THEN
    IF P_INTERNATIONAL_IND = '1' AND V_INTERNATIONAL_FLAG <> 'Y' THEN
       V_RESP_CDE := '38';
       V_ERR_MSG  := 'International Transaction Not supported';
       RAISE EXP_REJECT_RECORD;
    END IF;
END IF;

     --Added for MVHOST-1041
    BEGIN
       IF p_delivery_channel = '02' AND ( p_txn_code = '25' or  p_txn_code = '35')
       THEN
          SELECT COUNT (1)
            INTO v_mrlimitbreach_count
            FROM cms_mrlimitbreach_merchantname
           WHERE cpt_inst_code = p_inst_code
             AND UPPER (TRIM (p_merchant_name)) LIKE cmm_merchant_name || '%';

          IF v_mrlimitbreach_count > 0
          THEN
             v_mrminmaxlmt_ignoreflag := 'Y';
          END IF;
       END IF;
    EXCEPTION
       WHEN OTHERS
       THEN
          V_RESP_CDE := '21';
          V_ERR_MSG  := 'Error While Occured checking the  limit breach count'|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
    END;
    --End MVHOST-1041
    ---------------------------------------------------------------------------
    --SN:Added on 06-Feb-2013 to validate amount by ignoring surcharge fee
    ---------------------------------------------------------------------------

  

    ---------------------------------------------------------------------------
    --EN:Added on 06-Feb-2013 to validate amount by ignoring surcharge fee
    ---------------------------------------------------------------------------


        --LYFE changes....
       IF p_delivery_channel = '01' THEN
        BEGIN

          SELECT COUNT(*)
          INTO V_NETWORKIDCOUNT
          FROM CMS_PROD_CATTYPE prodCat,
          VMS_PRODCAT_NETWORKID_MAPPING MAPP
          WHERE prodCat.CPC_INST_CODE=MAPP.VPN_INST_CODE
          AND prodCat.CPC_INST_CODE=p_inst_code
          AND prodCat.CPC_NETWORKACQID_FLAG='Y'
          and prodCat.CPC_PROD_CODE=MAPP.VPN_PROD_CODE
          AND UPPER(MAPP.VPN_NETWORK_ID)=UPPER(P_NETWORKID_ACQUIRER)
          AND prodCat.CPC_CARD_TYPE= V_PROD_CATTYPE
          AND prodCat.CPC_CARD_TYPE= MAPP.VPN_CARD_TYPE
          and MAPP.VPN_PROD_CODE=v_prod_code;

        EXCEPTION
        WHEN OTHERS THEN
         v_resp_cde := '21';
            v_err_msg :=
                'Error while selecting product network id ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;

        END;

      END IF;

          --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

     P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 2: ' || v_mili ;
     --EN Added by Pankaj S. for DB time logging changes

       IF V_NETWORKIDCOUNT <> 1 THEN
      --En Internation Flag check
      BEGIN
         sp_tran_fees_cmsauth
                       (p_inst_code,
                        p_card_no,
                        p_delivery_channel,
                        v_txn_type,
                        p_txn_mode,
                        p_txn_code,
                        p_curr_code,
                        p_consodium_code,
                        p_partner_code,
                        v_tran_amt,
                        v_tran_date,
                        p_international_ind, --Added by Deepa for Fees Changes
                        p_pos_verfication,   --Added by Deepa for Fees Changes
                        v_resp_cde,          --Added by Deepa for Fees Changes
                        p_msg,               --Added by Deepa for Fees Changes
                        p_rvsl_code,
                        --Added by Deepa on June 25 2012 for Reversal txn Fee
                        p_mcc_code,
                        --Added by Trivikram on 05-Sep-2012 for merchant catg code
                        v_fee_amt,
                        v_error,
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
                        v_cess_dracct_no,
                        v_feeamnt_type,      --Added by Deepa for Fees Changes
                        v_clawback,          --Added by Deepa for Fees Changes
                        v_fee_plan,          --Added by Deepa for Fees Changes
                        v_per_fees,          --Added by Deepa for Fees Changes
                        v_flat_fees,         --Added by Deepa for Fees Changes
                        v_freetxn_exceed,
                        -- Added by Trivikram for logging fee of free transaction
                        v_duration,
                        -- Added by Trivikram for logging fee of free transaction
                        v_feeattach_type,  -- Added by Trivikram on Sep 05 2012
                        v_fee_desc, -- Added for MVCSD-4471
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
    ELSE
      V_FEE_AMT :=0;
     END IF;
    ---En dynamic fee calculation .

    --Sn calculate waiver on the fee
    BEGIN
     SP_CALCULATE_WAIVER(P_INST_CODE,
                     P_CARD_NO,
                     '000',
                     V_PROD_CODE,
                     V_PROD_CATTYPE,
                     V_FEE_CODE,
                     V_FEE_PLAN, -- Added by Trivikram on 21/aug/2012
                     V_TRAN_DATE,--Added Trivikam on Aug-23-2012 to calculate the waiver based on tran date
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

    --SN Added on 29.10.2013 for 12568
     IF  TO_NUMBER (p_partial_preauth_ind) = 1
     AND p_txn_code = '14' AND p_delivery_channel = '02' and V_TOTAL_FEE <> 0
     THEN
         IF V_TOTAL_FEE >= v_acct_balance THEN

            V_RESP_CDE := '15';
            V_ERR_MSG  := 'Insufficient Balance ';
            RAISE EXP_REJECT_RECORD;

         ELSIF V_TRAN_AMT + V_TOTAL_FEE  > v_acct_balance THEN

            V_TRAN_AMT           := V_ACCT_BALANCE - V_TOTAL_FEE;
            p_purchase_amt := v_tran_amt;
            v_partial_appr := 'Y';
         END IF;

     END IF;
    --EN Added on 29.10.2013 for 12568

    --Sn find total transaction    amount
    IF V_DR_CR_FLAG = 'CR' THEN
     V_TOTAL_AMT      := V_TRAN_AMT - V_TOTAL_FEE;
     V_UPD_AMT        := V_ACCT_BALANCE + V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := V_LEDGER_BAL + V_TOTAL_AMT;
    Elsif V_Dr_Cr_Flag = 'DR' Then
     V_TOTAL_AMT      := V_TRAN_AMT + nvl(V_TOTAL_FEE,0);
     V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := V_LEDGER_BAL - V_TOTAL_AMT;
    ELSIF V_DR_CR_FLAG = 'NA' THEN
     IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
       V_TOTAL_AMT      := V_TRAN_AMT + V_TOTAL_FEE;
       V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
       V_UPD_LEDGER_AMT := V_LEDGER_BAL - V_TOTAL_AMT;
     ELSE
       IF V_TOTAL_FEE = 0 THEN
        V_TOTAL_AMT := 0;
       Else
        V_TOTAL_AMT := nvl(V_TOTAL_FEE,0);
       END IF;

       V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
       V_UPD_LEDGER_AMT := V_LEDGER_BAL - V_TOTAL_AMT;
     END IF;
    ELSE
     V_RESP_CDE := '12'; --Ineligible Transaction
     V_ERR_MSG  := 'Invalid transflag    txn code ' || P_TXN_CODE;
     RAISE EXP_REJECT_RECORD;
    END IF;

    --En find total transaction    amout
    /*Commented for FSS-4362
    --Sn check balance
    IF V_DR_CR_FLAG NOT IN ('NA', 'CR') AND P_TXN_CODE <> '93' -- For credit transaction or Non-Financial transaction Insufficient Balance Check is not required. -- 29th June 2011
    THEN
     IF V_UPD_AMT < 0 THEN
       V_RESP_CDE := '15'; --Ineligible Transaction
       V_ERR_MSG  := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
       RAISE EXP_REJECT_RECORD;
     END IF;
    END IF;
    --En check balance
    */

     --Start  Added for FSS-4362 on 18/05/2016
 IF (V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0)) THEN  --ADDED FOR JIRA MVCHW - 454
   IF V_UPD_AMT < 0 THEN

          --IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK = 'Y' V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0) THEN  commented for JIRA MVCHW - 454
          IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK = 'Y' THEN    --ADDED FOR JIRA MVCHW - 454

                V_ACTUAL_FEE_AMNT := V_TOTAL_FEE;
                --V_CLAWBACK_AMNT   := V_TOTAL_FEE - V_ACCT_BALANCE;
               --   V_FEE_AMT         := V_ACCT_BALANCE;
                --Start  ADDED FOR JIRA MVCHW - 454
                IF (V_ACCT_BALANCE >0) THEN
                  V_CLAWBACK_AMNT   := V_TOTAL_FEE - V_ACCT_BALANCE;
                  V_FEE_AMT         := V_ACCT_BALANCE;
                ELSE
                  V_CLAWBACK_AMNT   := V_TOTAL_FEE;
                  V_FEE_AMT         := 0;
                End IF;
                --ENDED FOR JIRA MVCHW - 454

                    IF V_CLAWBACK_AMNT > 0 THEN

                       -- Added for FWR 64 --
                  begin
                    select cfm_clawback_count into v_tot_clwbck_count from cms_fee_mast where cfm_fee_code=V_FEE_CODE;

                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    V_RESP_CDE := '12';
                    V_ERR_MSG  := 'Clawback count not configured '|| SUBSTR(SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                  END;

                BEGIN
                                SELECT COUNT (*)
                                  INTO v_chrg_dtl_cnt
                                  FROM cms_charge_dtl
                                 WHERE      ccd_inst_code = p_inst_code
                                         AND ccd_delivery_channel = p_delivery_channel
                                         AND ccd_txn_code = p_txn_code
                                         --AND ccd_pan_code = v_hash_pan  --Commented for FSS-4755
                                         AND ccd_acct_no = v_card_acct_no  and CCD_FEE_CODE=V_FEE_CODE
                     and ccd_clawback ='Y';
                            EXCEPTION
                                WHEN OTHERS --SN Exception Block added as per review observations for FSS-1246
                                THEN
                                    V_RESP_CDE := '21';
                                    V_ERR_MSG :=
                                        'Error occured while fetching count from cms_charge_dtl'
                                        || SUBSTR (SQLERRM, 1, 100);
                                    RAISE EXP_REJECT_RECORD;
                            END;
            -- Added for fwr 64
                          BEGIN

                            SELECT COUNT(*)
                             INTO V_CLAWBACK_COUNT
                             FROM CMS_ACCTCLAWBACK_DTL
                            WHERE CAD_INST_CODE = P_INST_CODE AND
                                 CAD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                                 CAD_TXN_CODE = P_TXN_CODE AND
                                 CAD_PAN_CODE = V_HASH_PAN AND
                                 CAD_ACCT_NO = V_CARD_ACCT_NO;

                                IF V_CLAWBACK_COUNT = 0 THEN

                                 INSERT INTO CMS_ACCTCLAWBACK_DTL
                                   (CAD_INST_CODE,
                                    CAD_ACCT_NO,
                                    CAD_PAN_CODE,
                                    CAD_PAN_CODE_ENCR,
                                    CAD_CLAWBACK_AMNT,
                                    CAD_RECOVERY_FLAG,
                                    CAD_INS_DATE,
                                    CAD_LUPD_DATE,
                                    CAD_DELIVERY_CHANNEL,
                                    CAD_TXN_CODE,
                                    CAD_INS_USER,
                                    CAD_LUPD_USER)
                                 VALUES
                                   (P_INST_CODE,
                                    V_CARD_ACCT_NO,
                                    V_HASH_PAN,
                                    V_ENCR_PAN,
                                    ROUND(V_CLAWBACK_AMNT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                    'N',
                                    SYSDATE,
                                    SYSDATE,
                                    P_DELIVERY_CHANNEL,
                                    P_TXN_CODE,
                                    '1',
                                    '1');
                         ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count then  -- Modified for fwr 64

                                 UPDATE CMS_ACCTCLAWBACK_DTL
                                    SET CAD_CLAWBACK_AMNT = ROUND((CAD_CLAWBACK_AMNT +
                                                       V_CLAWBACK_AMNT),2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                       CAD_RECOVERY_FLAG = 'N',
                                       CAD_LUPD_DATE     = SYSDATE
                                  WHERE CAD_INST_CODE = P_INST_CODE AND
                                       CAD_ACCT_NO = V_CARD_ACCT_NO AND
                                       CAD_PAN_CODE = V_HASH_PAN AND
                                       CAD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                                       CAD_TXN_CODE = P_TXN_CODE;

                                END IF;

                          EXCEPTION
                            WHEN OTHERS THEN
                             V_RESP_CDE := '21';
                             V_ERR_MSG  := 'Error while inserting Account ClawBack details' ||
                                        SUBSTR(SQLERRM, 1, 200);
                             RAISE EXP_REJECT_RECORD;

                          END;

                    END IF;

               ELSE
                V_RESP_CDE := '15';
                V_ERR_MSG  := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
                RAISE EXP_REJECT_RECORD;
               END IF;

           V_UPD_AMT        := 0;
           V_UPD_LEDGER_AMT := 0;
           V_TOTAL_AMT      := V_TRAN_AMT + V_FEE_AMT  ;

         END IF;
     END IF; --ADDED FOR JIRA ID : MVCHW-454
    --End Added for FSS-4362 on 18/05/2016


     IF    (v_dr_cr_flag = 'CR' AND p_rvsl_code = '00')         -- IF condition added for OLS changes
         OR (v_dr_cr_flag = 'DR' AND p_rvsl_code <> '00'
            )                                     --Added by Besky on 26/03/13
      THEN
        -- Check for maximum card balance configured for the product profile.
        BEGIN

          SELECT TO_NUMBER(CBP_PARAM_VALUE)           -- Added on 09-Feb-2013 for max card balance check based on product category
           INTO V_MAX_CARD_BAL
           FROM CMS_BIN_PARAM
           WHERE CBP_INST_CODE = P_INST_CODE AND
               CBP_PARAM_NAME = 'Max Card Balance' AND
               cbp_profile_code=V_PROFILE_CODE;

          /*
          SELECT TO_NUMBER(CBP_PARAM_VALUE)         -- Commented on 09-Feb-2013 for max card balance check based on product category
           INTO V_MAX_CARD_BAL
           FROM CMS_BIN_PARAM
           WHERE CBP_INST_CODE = P_INST_CODE AND
               CBP_PARAM_NAME = 'Max Card Balance' AND
               CBP_PROFILE_CODE IN
               (SELECT CPM_PROFILE_CODE
                 FROM CMS_PROD_MAST
                WHERE CPM_PROD_CODE = V_PROD_CODE);
                */

        EXCEPTION
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
        IF v_badcredit_flag = 'Y'
         THEN
            EXECUTE IMMEDIATE    'SELECT  count(*) 
              FROM vms_group_tran_detl
              WHERE vgd_group_id ='
                              || v_badcredit_transgrpid
                              || '
              AND vgd_tran_detl LIKE 
              (''%'
                              || p_delivery_channel
                              || ':'
                              || p_txn_code
                              || '%'')'
                         INTO v_cnt;
            IF v_cnt = 1
            THEN
               v_enable_flag := 'N';
               IF    ((V_UPD_AMT) > v_initialload_amt
                     )                                     --initialloadamount
                  OR ((V_UPD_LEDGER_AMT) > v_initialload_amt
                     )
               THEN                                        --initialloadamount
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = p_inst_code
                     AND cap_pan_code = v_hash_pan;
                  BEGIN
         sp_log_cardstat_chnge (p_inst_code,
                                v_hash_pan,
                                v_encr_pan,
                                V_AUTH_ID,
                                '10',
                                p_rrn,
                                p_tran_date,
                                p_tran_time,
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
            END IF;
         END IF;
        
         IF v_enable_flag = 'Y' AND p_txn_code NOT IN('25','35') -- Code modified for VMS-2709
         THEN
            IF    ((V_UPD_AMT) > v_max_card_bal)
               OR ((V_UPD_LEDGER_AMT) > v_max_card_bal)
            THEN
               v_resp_cde := '30';
               v_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
               RAISE exp_reject_record;
            END IF;
         END IF;
          --Added by Ramkumar.mK , Check the condition Debit flag
         -- IF V_DR_CR_FLAG = 'CR' THEN                             -- IF condition commented for OLS changes
            --Sn check balance
--            IF (V_UPD_LEDGER_AMT > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL) THEN
----             V_RESP_CDE := '30';
----             V_ERR_MSG  := 'EXCEEDING MAXIMUM CARD BALANCE / BAD CREDIT STATUS';
----             RAISE EXP_REJECT_RECORD;
--
--IF V_APPLPAN_CARDSTAT <> '12'
--            THEN
--            IF v_badcredit_flag = 'Y' THEN
--             execute immediate 'SELECT  count(*) 
--                FROM vms_group_tran_detl
--                WHERE vgd_group_id ='|| v_badcredit_transgrpid||'
--                AND vgd_tran_detl LIKE 
--                (''%'||p_delivery_channel ||':'|| p_txn_code||'%'')'
--            into v_cnt;
--                IF v_cnt = 1 THEN
--                     v_card_stat := '18';
--               END IF;    
--            END IF;
--               UPDATE cms_appl_pan
--               SET cap_card_stat = v_card_stat
--                WHERE cap_inst_code = p_inst_code
--                  AND cap_pan_code = v_hash_pan;
--
--               IF SQL%ROWCOUNT = 0
--               THEN
--                  v_err_msg := 'Error while updating the card status';
--                  v_resp_cde := '21';
 --            RAISE EXP_REJECT_RECORD;
 --           END IF;
--            END IF;
--            END IF;
            --En check balance
         -- END IF;

     End if;
     
     
           BEGIN
            begin-- Added for VMS-9160
                if v_prfl_code is null then
                
                    select CPL_LMTPRFL_ID 
                      into v_prfl_code
                      from cms_prdcattype_lmtprfl
                     where CPL_PROD_CODE = v_prod_code
                       and CPL_CARD_TYPE = V_PROD_CATTYPE;
                end if;
                exception
                when no_data_found then
                    begin 
                        select CPL_LMTPRFL_ID 
                        into v_prfl_code
                        from CMS_PROD_LMTPRFL
                        where CPL_PROD_CODE = v_prod_code;
                    exception
                    when others then
                        v_err_msg := 'Error trying to set Limit Profile before sp_limits_check ';
                        RAISE exp_reject_record;
                    end;
                    
                when others then
                    v_err_msg := 'Error trying to set Limit Profile before sp_limits_check ';
                    RAISE exp_reject_record;
                
            end;

            IF V_PRFL_CODE IS NOT NULL AND V_PRFL_FLAG ='Y' THEN
              
            pkg_limits_check.sp_limits_check ( V_HASH_PAN,
                                                NULL,
                                                NULL,
                                                P_MCC_CODE,
                                                P_TXN_CODE,
                                                V_TRAN_TYPE,
                                                case when p_delivery_channel ='02' and (p_txn_code ='25' or p_txn_code ='35')-- Case added for 13037 defect
                                                then null else P_INTERNATIONAL_IND end,
                                                case when p_delivery_channel ='02' and (p_txn_code ='25' or p_txn_code ='35') -- Case added for 13037 defect
                                                then null else p_pos_verfication end,
                                                p_inst_code,
                                                NULL,
                                                V_PRFL_CODE,
                                                V_LIMIT_AMT, --Added on 04-Feb-2013 for FSS-821
                                                --p_txn_amt, -- commented on 04-Feb-2013 for FSS-821
                                                p_delivery_channel,
                                                v_comb_hash,
                                                V_RESP_CDE,
                                                v_error
                                                ,v_mrminmaxlmt_ignoreflag
                                           );
            end if ;

           IF v_error <> 'OK'
           THEN
              --v_resp_cde := '21'; --commented by amit on 26-Jul-12 to pass response code from limit check
              v_err_msg := v_error;--'From Procedure sp_limits_check '||
              
              
              RAISE exp_reject_record;
           END IF;

        EXCEPTION
        WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              v_resp_cde := '21';
              v_err_msg := 'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;


    --Sn create gl entries and acct update
    BEGIN
     SP_UPD_TRANSACTION_ACCNT_AUTH(P_INST_CODE,
                             V_TRAN_DATE,
                             V_PROD_CODE,
                             V_PROD_CATTYPE,
                             V_TRAN_AMT,
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
                             V_CARD_ACCT_NO,
                             ---Card's account no has been passed instead of card no(For Debit card acct_no will be different)
                             V_HOLD_AMOUNT, --For PreAuth Completion transaction
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

    --Sn find narration
    BEGIN

    --Commended by saravanakumar on 16-Sep-2014
     /*SELECT CTM_TRAN_DESC
       INTO V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;*/

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
    --Sn create a entry in statement log
    IF V_DR_CR_FLAG <> 'NA' THEN

     v_timestamp := systimestamp;              -- Added on 17-Apr-2013 for defect 10871


          BEGIN
               V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_CARD_NO||P_RRN||to_char(V_TIMESTAMP,'YYYYMMDDHH24MISSFF5'));
           EXCEPTION
            WHEN OTHERS
            THEN
            V_RESP_CDE := '21';
            V_ERR_MSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
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
         CSL_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
         CSL_INS_USER,
         CSL_INS_DATE,
         CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE,
         CSL_PANNO_LAST4DIGIT,   --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
         CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
         CSL_TIME_STAMP,        -- Added on 17-Apr-2013 for defect 10871
         CSL_PROD_CODE,
         csl_card_type
         )

       VALUES
        (V_HASH_PAN,
         V_LEDGER_BAL,      -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871,
         V_TRAN_AMT,
         V_DR_CR_FLAG,
         V_TRAN_DATE,
         DECODE(V_DR_CR_FLAG,
               'DR',
               V_LEDGER_BAL - V_TRAN_AMT,   -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871,
               'CR',
               V_LEDGER_BAL + V_TRAN_AMT,   -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871,
               'NA',
               V_LEDGER_BAL),               -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871,
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
         V_CARD_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
         1,
         SYSDATE,
         P_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
         P_MERCHANT_CITY,
         P_ATMNAME_LOC,
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),   --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
         v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
         v_timestamp,       -- Added on 17-Apr-2013 for defect 10871
         v_prod_code,
         V_PROD_CATTYPE     -- Added on 17-Apr-2013 for defect 10871
         );

     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Problem while inserting into statement log for tran amt ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

    --Commended by saravanakumar on 16-Sep-2014
     /*BEGIN
       SP_DAILY_BIN_BAL(P_CARD_NO,
                    V_TRAN_DATE,
                    V_TRAN_AMT,
                    V_DR_CR_FLAG,
                    P_INST_CODE,
                    P_BANK_CODE,
                    V_ERR_MSG);

       IF V_ERR_MSG <> 'OK' THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Problem while calling SP_DAILY_BIN_BAL ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
       END IF;

     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Problem while calling SP_DAILY_BIN_BAL ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;*/

    END IF;

    --En create a entry in statement log

    --Sn find fee opening balance
    IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N' THEN -- Modified by Trivikram on 26-July-2012 for logging fee of free transaction
     BEGIN
       SELECT DECODE(V_DR_CR_FLAG,
                  'DR',
                  V_LEDGER_BAL - V_TRAN_AMT,    -- Added on 17-Apr-2013 for defect 10871
                  'CR',
                  V_LEDGER_BAL + V_TRAN_AMT,    -- Added on 17-Apr-2013 for defect 10871
                  'NA',
                  V_LEDGER_BAL)                 -- Added on 17-Apr-2013 for defect 10871
        INTO V_FEE_OPENING_BAL
        FROM DUAL;
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '12';
        V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                    P_CARD_NO;
        RAISE EXP_REJECT_RECORD;
     END;

    -- Added by Trivikram on 27-July-2012 for logging complementary transaction
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
           CSL_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
           CSL_INS_USER,
           CSL_INS_DATE,
           CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
           CSL_MERCHANT_CITY,
           CSL_MERCHANT_STATE,
           CSL_PANNO_LAST4DIGIT,   --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
           CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
           CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
           CSL_PROD_CODE,          -- Added on 17-Apr-2013 for defect 10871
           csl_card_type
           )
        VALUES
          (V_HASH_PAN,
           V_FEE_OPENING_BAL,
           V_TOTAL_FEE,
           'DR',
           V_TRAN_DATE,
           V_FEE_OPENING_BAL - V_TOTAL_FEE,
           --'Complimentary ' || V_DURATION ||' '|| V_NARRATION, -- Modified by Trivikram  on 27-July-2012  -- Commented for MVCSD-4471
           v_fee_desc, -- Added for MVCSD-4471
           P_INST_CODE,
           V_ENCR_PAN,
           P_RRN,
           V_AUTH_ID,
           P_TRAN_DATE,
           P_TRAN_TIME,
           'Y',
           P_DELIVERY_CHANNEL,
           P_TXN_CODE,
           V_CARD_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
           1,
           SYSDATE,
           P_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
           P_MERCHANT_CITY,
           P_ATMNAME_LOC,
           (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),   --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
           v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
           v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
           v_prod_code,        -- Added on 17-Apr-2013 for defect 10871
           V_PROD_CATTYPE
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
      --Added by Deepa on June 19 2012 for Fee changes
         IF V_FEEAMNT_TYPE = 'A' THEN


            -- Added by Trivikram on 23/aug/2012 for logged fixed fee and percentage fee with waiver

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
             CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
             CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
             CSL_PROD_CODE,          -- Added on 17-Apr-2013 for defect 10871
             csl_card_type
             )
           VALUES
            (V_HASH_PAN,
             V_FEE_OPENING_BAL,
             V_FLAT_FEES,
             'DR',
             V_TRAN_DATE,
             V_FEE_OPENING_BAL - V_FLAT_FEES,
             --'Fixed Fee debited for ' || V_NARRATION, -- Commented for MVCSD-4471
             'Fixed Fee debited for ' || v_fee_desc, -- Added for MVCSD-4471
             P_INST_CODE,
             V_ENCR_PAN,
             P_RRN,
             V_AUTH_ID,
             P_TRAN_DATE,
             P_TRAN_TIME,
             'Y',
             P_DELIVERY_CHANNEL,
             P_TXN_CODE,
             V_CARD_ACCT_NO,
             1,
             SYSDATE,
             P_MERCHANT_NAME,
             P_MERCHANT_CITY,
             P_ATMNAME_LOC,
             (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
             v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
             v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
             v_prod_code,        -- Added on 17-Apr-2013 for defect 10871
             V_PROD_CATTYPE
             );
           --En Entry for Fixed Fee
           IF V_PER_FEES <> 0 THEN  --Added for VMS-5856
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
             CSL_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
             CSL_INS_USER,
             CSL_INS_DATE,
             CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
             CSL_MERCHANT_CITY,
             CSL_MERCHANT_STATE,
             CSL_PANNO_LAST4DIGIT,  --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
             CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
             CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
             CSL_PROD_CODE,          -- Added on 17-Apr-2013 for defect 10871
             csl_card_type
             )
           VALUES
            (V_HASH_PAN,
             V_FEE_OPENING_BAL,
             V_PER_FEES,
             'DR',
             V_TRAN_DATE,
             V_FEE_OPENING_BAL - V_PER_FEES,
             --'Percetage Fee debited for ' || V_NARRATION, -- Commented for MVCSD-4471
             'Percentage Fee debited for ' || v_fee_desc, -- Added for MVCSD-4471
             P_INST_CODE,
             V_ENCR_PAN,
             P_RRN,
             V_AUTH_ID,
             P_TRAN_DATE,
             P_TRAN_TIME,
             'Y',
             P_DELIVERY_CHANNEL,
             P_TXN_CODE,
             V_CARD_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
             1,
             SYSDATE,
             P_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
             P_MERCHANT_CITY,
             P_ATMNAME_LOC,
             (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
             v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
             v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
             v_prod_code,        -- Added on 17-Apr-2013 for defect 10871
             V_PROD_CATTYPE
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
               CSL_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
               CSL_INS_USER,
               CSL_INS_DATE,
               CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
               CSL_MERCHANT_CITY,
               CSL_MERCHANT_STATE,
               CSL_PANNO_LAST4DIGIT,   --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
               CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
               CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
               CSL_PROD_CODE,          -- Added on 17-Apr-2013 for defect 10871
               csl_card_type
               )
            VALUES
              (V_HASH_PAN,
               V_FEE_OPENING_BAL,
               V_TOTAL_FEE,
               'DR',
               V_TRAN_DATE,
               V_FEE_OPENING_BAL - V_TOTAL_FEE,
               --'Fee debited for ' || V_NARRATION, -- Commented for MVCSD-4471
                v_fee_desc, -- Added for MVCSD-4471
               P_INST_CODE,
               V_ENCR_PAN,
               P_RRN,
               V_AUTH_ID,
               P_TRAN_DATE,
               P_TRAN_TIME,
               'Y',
               P_DELIVERY_CHANNEL,
               P_TXN_CODE,
               V_CARD_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
               1,
               SYSDATE,
               P_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
               P_MERCHANT_CITY,
               P_ATMNAME_LOC,
               (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),  --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
               v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
               v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
               v_prod_code,        -- Added on 17-Apr-2013 for defect 10871
               V_PROD_CATTYPE
               );

               --Start  Clawback Changes (MVHOST - 346)  on 20/04/2013
                           IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK_AMNT > 0 and v_chrg_dtl_cnt < v_tot_clwbck_count THEN  -- Modified for fwr 64
                           BEGIN
                            INSERT INTO CMS_CHARGE_DTL
                              (CCD_PAN_CODE,
                               CCD_ACCT_NO,
                               CCD_CLAWBACK_AMNT,
                               CCD_GL_ACCT_NO,
                               CCD_PAN_CODE_ENCR,
                               CCD_RRN,
                               CCD_CALC_DATE,
                               CCD_FEE_FREQ,
                               CCD_FILE_STATUS,
                               CCD_CLAWBACK,
                               CCD_INST_CODE,
                               CCD_FEE_CODE,
                               CCD_CALC_AMT,
                               CCD_FEE_PLAN,
                               CCD_DELIVERY_CHANNEL,
                               CCD_TXN_CODE,
                               CCD_DEBITED_AMNT,
                               CCD_MBR_NUMB,
                               CCD_PROCESS_MSG,
                               CCD_FEEATTACHTYPE

                               )
                            VALUES
                              (V_HASH_PAN,
                               V_CARD_ACCT_NO,
                               ROUND(V_CLAWBACK_AMNT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                               V_FEE_CRACCT_NO,
                               V_ENCR_PAN,
                               P_RRN,
                               V_TRAN_DATE,
                               'T',
                               'C',
                               V_CLAWBACK,
                               P_INST_CODE,
                               V_FEE_CODE,
                               ROUND(V_ACTUAL_FEE_AMNT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                               V_FEE_PLAN,
                               P_DELIVERY_CHANNEL,
                               P_TXN_CODE,
                               ROUND(V_FEE_AMT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                               P_MBR_NUMB,
                               DECODE(V_ERR_MSG, 'OK', 'SUCCESS'),
                               V_FEEATTACH_TYPE);

                             EXCEPTION
                            WHEN OTHERS THEN
                              V_RESP_CDE := '21';
                              V_ERR_MSG  := 'Problem while inserting into CMS_CHARGE_DTL ' ||
                                         SUBSTR(SQLERRM, 1, 200);
                              RAISE EXP_REJECT_RECORD;
                           END;
                           END IF;
                      --End  Clawback Changes (MVHOST - 346)  on 20/04/2013

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
        CTD_INTERNATION_IND_RESPONSE,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        CTD_NETWORK_ID,
        CTD_INTERCHANGE_FEEAMT,
        CTD_MERCHANT_ZIP,
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        ctd_ins_user,                               -- Added for OLS changes
        ctd_ins_date                                -- Added for OLS changes
        ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
        CTD_CARDVERIFICATION_RESULT
        ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE,CTD_HASHKEY_ID
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
        P_INTERNATIONAL_IND,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        P_NETWORK_ID,
        P_INTERCHANGE_FEEAMT,
        P_MERCHANT_ZIP,
        /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        1,              -- Added for OLS changes
        sysdate         -- Added for OLS changes
        ,P_PULSE_TRANSACTIONID,
        P_VISA_TRANSACTIONID,
        P_MC_TRACEID,
        P_CARDVERIFICATION_RESULT
        ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE,V_HASHKEY_ID
        );
     --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while inserting in to CMS_TRANSACTION_LOG_DTL ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --En create a entry for successful
    ---Sn update daily and weekly transcounter  and amount
    --Commended by saravanakumar on 16-Sep-2014
    /*BEGIN
     /*SELECT CAT_PAN_CODE
       INTO V_AVAIL_PAN
       FROM CMS_AVAIL_TRANS
      WHERE CAT_PAN_CODE = V_HASH_PAN
           AND CAT_TRAN_CODE = P_TXN_CODE AND
           CAT_TRAN_MODE = P_TXN_MODE;

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

     /*IF SQL%ROWCOUNT = 0 THEN
        V_ERR_MSG  := 'Problem while updating data in avail trans ' ||
                   SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
      END IF;

    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from avail trans ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;*/

    --En update daily and weekly transaction counter and amount
    --Sn create detail for response message
    -- added for mini statement
    IF V_OUTPUT_TYPE = 'B' THEN
     --Balance Inquiry
  /*  IF P_TXN_CODE = '04' AND P_DELIVERY_CHANNEL = '07' THEN

       BEGIN
        OPEN C_MINI_TRAN;
        LOOP
          FETCH C_MINI_TRAN
            INTO V_MINI_STAT_VAL;
          EXIT WHEN C_MINI_TRAN%NOTFOUND;
          V_MINI_STAT_RES := V_MINI_STAT_RES || ' | ' || V_MINI_STAT_VAL;
        END LOOP;
        CLOSE C_MINI_TRAN;
       EXCEPTION
        WHEN OTHERS THEN
          V_ERR_MSG  := 'Problem while selecting data from C_MINI_TRAN cursor' ||
                     SUBSTR(SQLERRM, 1, 300);
          V_RESP_CDE := '21';
          RAISE EXP_REJECT_RECORD;
       END;

       IF (V_MINI_STAT_RES IS NULL) THEN
        V_MINI_STAT_RES := ' ';
       ELSE
        V_MINI_STAT_RES := SUBSTR(V_MINI_STAT_RES,
                             3,
                             LENGTH(V_MINI_STAT_RES));
       END IF;
     ELSE */
       P_RESP_MSG   := TO_CHAR(V_UPD_AMT);
       P_LEDGER_BAL := TO_CHAR(V_UPD_LEDGER_AMT); -- ADDED FOR LEDGER BALANCE FOR mPAY BALANCE ENQUIRY REQUEST.
     --END IF;
    END IF;
    -- added for mini statement
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

     --Commended by saravanakumar on 16-Sep-2014
     /*BEGIN
       IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
        IF P_PREAUTH_EXPPERIOD IS NULL THEN
          SELECT CPM_PRE_AUTH_EXP_DATE
            INTO V_PREAUTH_EXP_PERIOD
            FROM CMS_PROD_MAST
           WHERE CPM_PROD_CODE = V_PROD_CODE;

          IF V_PREAUTH_EXP_PERIOD IS NULL THEN
            SELECT CIP_PARAM_VALUE
             INTO V_PREAUTH_EXP_PERIOD
             FROM CMS_INST_PARAM
            WHERE CIP_INST_CODE = P_INST_CODE AND
                 CIP_PARAM_KEY = 'PRE-AUTH EXP PERIOD';

            V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
            V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
          ELSE
            V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
            V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
          END IF;
        ELSE
          V_PREAUTH_HOLD   := SUBSTR(TRIM(P_PREAUTH_EXPPERIOD), 1, 1);
          V_PREAUTH_PERIOD := SUBSTR(TRIM(P_PREAUTH_EXPPERIOD), 2, 2);

          IF V_PREAUTH_PERIOD = '00' THEN
            SELECT CPM_PRE_AUTH_EXP_DATE
             INTO V_PREAUTH_EXP_PERIOD
             FROM CMS_PROD_MAST
            WHERE CPM_PROD_CODE = V_PROD_CODE;

            IF V_PREAUTH_EXP_PERIOD IS NULL THEN
             SELECT CIP_PARAM_VALUE
               INTO V_PREAUTH_EXP_PERIOD
               FROM CMS_INST_PARAM
              WHERE CIP_INST_CODE = P_INST_CODE AND
                   CIP_PARAM_KEY = 'PRE-AUTH EXP PERIOD';

             V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
             V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
            ELSE
             V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
             V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
            END IF;
          ELSE
            V_PREAUTH_HOLD   := V_PREAUTH_HOLD;
            V_PREAUTH_PERIOD := V_PREAUTH_PERIOD;
          END IF;
        END IF;

        /*
           preauth period will be added with transaction date based on preauth_hold
           IF v_preauth_hold is '0'--'Minute'
           '1'--'Hour'
           '2'--'Day'

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
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '21'; -- Server Declione
        V_ERR_MSG  := 'Problem while inserting preauth transaction details' ||
                    SUBSTR(SQLERRM, 1, 300);
        RAISE EXP_REJECT_RECORD;
     END;*/

     IF V_RESP_CDE = '1' THEN
       --Sn find business date
       V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

       IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
        V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
       ELSE
        V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
       END IF;
--SN - Commented for FWR-48
       --En find businesses date
       /*BEGIN
        SP_CREATE_GL_ENTRIES_CMSAUTH(P_INST_CODE,
                                V_BUSINESS_DATE,
                                V_PROD_CODE,
                                V_PROD_CATTYPE,
                                V_TRAN_AMT,
                                V_FUNC_CODE,
                                P_TXN_CODE,
                                V_DR_CR_FLAG,
                                P_CARD_NO,
                                V_FEE_CODE,
                                V_TOTAL_FEE,
                                V_FEE_CRACCT_NO,
                                V_FEE_DRACCT_NO,
                                V_CARD_ACCT_NO,
                                P_RVSL_CODE,
                                P_MSG,
                                P_DELIVERY_CHANNEL,
                                V_RESP_CDE,
                                V_GL_UPD_FLAG,
                                V_GL_ERR_MSG);

        IF V_GL_ERR_MSG <> 'OK' OR V_GL_UPD_FLAG <> 'Y' THEN
          V_GL_UPD_FLAG := 'N';
          P_RESP_CODE   := V_RESP_CDE;
          V_ERR_MSG     := V_GL_ERR_MSG;
          RAISE EXP_REJECT_RECORD;
        END IF;
       EXCEPTION
        WHEN OTHERS THEN
          V_GL_UPD_FLAG := 'N';
          P_RESP_CODE   := V_RESP_CDE;
          V_ERR_MSG     := V_GL_ERR_MSG;
          RAISE EXP_REJECT_RECORD;
       END;*/
--SN - Commented for FWR-48
       --Sn find prod code and card type and available balance for the card number
       BEGIN
        SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL --Ledger Balance added for defect 10871
          INTO V_ACCT_BALANCE,V_LEDGER_BAL --Ledger Balance added for defect 10871
          FROM CMS_ACCT_MAST
         WHERE CAM_ACCT_NO =V_ACCT_NUMBER--Modified by saravanakumar on 16-Sep-2014
              /*(SELECT CAP_ACCT_NO
                FROM CMS_APPL_PAN
                WHERE CAP_PAN_CODE = V_HASH_PAN AND
                    CAP_MBR_NUMB = P_MBR_NUMB AND
                    CAP_INST_CODE = P_INST_CODE)*/ AND
              CAM_INST_CODE = P_INST_CODE;
           --FOR UPDATE NOWAIT;                         -- Commented for Concurrent Processsing Issue
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_RESP_CDE := '14'; --Ineligible Transaction
          V_ERR_MSG  := 'Invalid Card ';
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          V_RESP_CDE := '12';
          V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                     SQLERRM;
          RAISE EXP_REJECT_RECORD;
       END;

       --En find prod code and card type for the card number
       IF V_OUTPUT_TYPE = 'N' THEN
        --Balance Inquiry
        P_RESP_MSG   := TO_CHAR(V_UPD_AMT+v_delayed_amount);
        P_LEDGER_BAL := TO_CHAR(V_UPD_LEDGER_AMT); -- ADDED FOR LEDGER BALANCE FOR mPAY BALANCE ENQUIRY REQUEST.
       END IF;
     END IF;

     --En create GL ENTRIES

     ---Sn Updation of Usage limit and amount
     --Commended by saravanakumar on 16-Sep-2014
     /*BEGIN
       SELECT CTC_ATMUSAGE_AMT,
            CTC_POSUSAGE_AMT,
            CTC_ATMUSAGE_LIMIT,
            CTC_POSUSAGE_LIMIT,
            CTC_BUSINESS_DATE,
            CTC_PREAUTHUSAGE_LIMIT,
            CTC_MMPOSUSAGE_AMT,
            CTC_MMPOSUSAGE_LIMIT
        INTO V_ATM_USAGEAMNT,
            V_POS_USAGEAMNT,
            V_ATM_USAGELIMIT,
            V_POS_USAGELIMIT,
            V_BUSINESS_DATE_TRAN,
            V_PREAUTH_USAGE_LIMIT,
            V_MMPOS_USAGEAMNT,
            V_MMPOS_USAGELIMIT
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
        V_ERR_MSG  := 'Error while selecting CMS_TRANSLIMIT_CHECK ' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN
       IF P_DELIVERY_CHANNEL = '01' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          IF P_TXN_AMT IS NULL THEN
            V_ATM_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999990.99'));
          ELSE
            V_ATM_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
                                     '99999999999999990.99'));
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
             V_ERR_MSG  := 'Error while updating 1 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 1 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          IF P_TXN_AMT IS NULL THEN
            V_ATM_USAGEAMNT := V_ATM_USAGEAMNT +
                           TRIM(TO_CHAR(0, '99999999999999990.99'));
          ELSE
            V_ATM_USAGEAMNT := V_ATM_USAGEAMNT +
                           TRIM(TO_CHAR(V_TRAN_AMT,
                                     '99999999999999990.99'));
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
             V_ERR_MSG  := 'Error while updating 2 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 2 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;

       IF P_DELIVERY_CHANNEL = '02' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          IF P_TXN_AMT IS NULL THEN
            V_POS_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999990.99'));
          ELSE
            V_POS_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
                                     '99999999999999990.99'));
          END IF;

          V_POS_USAGELIMIT := 1;

          IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
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
                 CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT,
                 CTC_MMPOSUSAGE_AMT     = 0,
                 CTC_MMPOSUSAGE_LIMIT   = 0
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 3 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 3 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

          IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
            V_PREAUTH_USAGE_LIMIT := V_PREAUTH_USAGE_LIMIT + 1;
            V_POS_USAGEAMNT       := V_POS_USAGEAMNT;
          ELSE
            IF P_TXN_AMT IS NULL THEN
             V_POS_USAGEAMNT := V_POS_USAGEAMNT +
                            TRIM(TO_CHAR(0, '99999999999999990.99'));
            ELSE

             IF V_DR_CR_FLAG = 'CR' THEN

               V_POS_USAGEAMNT := V_POS_USAGEAMNT;
             ELSE
               V_POS_USAGEAMNT := V_POS_USAGEAMNT +
                              TRIM(TO_CHAR(V_TRAN_AMT,
                                        '99999999999999990.99'));
             END IF;
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
             V_ERR_MSG  := 'Error while updating 4 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 4 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;

       --Sn Usage limit and amount updation for MMPOS
       IF P_DELIVERY_CHANNEL = '04' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          IF P_TXN_AMT IS NULL THEN
            V_MMPOS_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999990.99'));
          ELSE
            V_MMPOS_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
                                       '99999999999999990.99'));
          END IF;

          V_MMPOS_USAGELIMIT := 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_MMPOSUSAGE_AMT     = V_MMPOS_USAGEAMNT,
                 CTC_MMPOSUSAGE_LIMIT   = V_MMPOS_USAGELIMIT,
                 CTC_ATMUSAGE_AMT       = 0,
                 CTC_ATMUSAGE_LIMIT     = 0,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss'),
                 CTC_PREAUTHUSAGE_LIMIT = 0,
                 CTC_POSUSAGE_AMT       = 0,
                 CTC_POSUSAGE_LIMIT     = 0
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 5 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 5 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;

          IF P_TXN_AMT IS NULL THEN
            V_MMPOS_USAGEAMNT := V_MMPOS_USAGEAMNT +
                            TRIM(TO_CHAR(0, 999999999999999));
          ELSE
            V_MMPOS_USAGEAMNT := V_MMPOS_USAGEAMNT +
                            TRIM(TO_CHAR(V_TRAN_AMT,
                                       '99999999999999990.99'));
          END IF;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_MMPOSUSAGE_AMT   = V_MMPOS_USAGEAMNT,
                 CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 6 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 6 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;
       --En Usage limit and amount updation for MMPOS

     END;*/
    END;

    ---En Updation of Usage limit and amount

     --SN Commented and moved down on 19.09.2013 for FSS-1313
   /* BEGIN
     SELECT CMS_B24_RESPCDE, --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
            cms_iso_respcde             -- Added for OLS changes
       INTO P_RESP_CODE,
            --v_cms_iso_respcde     -- Added for OLS changes --Commented and modified  on 17.07.2013 for the Mantis ID 11612
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
    END;*/
     --EN Commented and moved down on 19.09.2013 for FSS-1313
    ---

    --------------------------------------------
    --SN:Added on 06-Feb-2013 for FSS-821 defect
    --------------------------------------------

        --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

     P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 3: ' || v_mili ;
     --EN Added by Pankaj S. for DB time logging changes

       BEGIN

          if V_PRFL_CODE is not null and V_PRFL_FLAG ='Y'
          then

           pkg_limits_check.sp_limitcnt_reset (p_inst_code,
                                              v_hash_pan,
                                              V_LIMIT_AMT, --Added on 04-Feb-2013 for FSS-821
                                              --p_txn_amt, -- commented on 04-Feb-2013 for FSS-821
                                              v_comb_hash,
                                              v_resp_cde,
                                              v_error
                                             );
          end if  ;

           IF v_error <> 'OK'
           THEN
              --v_resp_cde := '21'; -- Commented on 12-Feb-2013
              v_err_msg :='From Procedure sp_limitcnt_reset'||  v_error;
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
                  'Error from Limit Reset Count Process ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
       END;

    --------------------------------------------
    --EN:Added on 06-Feb-2013 for FSS-821 defect
    --------------------------------------------

          --SN Added on 19.09.2013 for FSS-1313

      IF v_partial_appr = 'Y' AND v_resp_cde = '1'
      THEN
         v_resp_cde := '2';

       ELSIF v_partial_appr_cashback='Y' AND v_resp_cde = '1' THEN --Sn Added to support Partial Purchase for Mantis ID-12545,12564

        v_resp_cde := '3';

      END IF;  --En Added to support Partial Purchase for Mantis ID-12545,12564


      --EN Added on 19.09.2013 for FSS-1313

      p_resp_id := v_resp_cde; --Added for VMS-8018

      --SN Commented and moved here on 19.09.2013 for FSS-1313
      BEGIN
         SELECT cms_b24_respcde,
--Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
                                cms_iso_respcde       -- Added for OLS changes
           INTO p_resp_code,
                            --v_cms_iso_respcde     -- Added for OLS changes --Commented and modified  on 17.07.2013 for the Mantis ID 11612
                            p_iso_respcde
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = TO_NUMBER (v_resp_cde);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Problem while selecting data from response master for respose code'
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;
   --EN Commented and moved here on 19.09.2013 for FSS-1313

  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
              cam_type_code                                 -- Added on 17-Apr-2013 for defect 10871
        INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_ACCT_NUMBER,
             v_cam_type_code                                -- Added on 17-Apr-2013 for defect 10871
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =V_ACCT_NUMBER--Modified by saravanakumar on 16-Sep-2014
            /*(SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_INST_CODE = P_INST_CODE)*/ AND
            CAM_INST_CODE = P_INST_CODE;
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
            CTC_PREAUTHUSAGE_LIMIT,
            CTC_MMPOSUSAGE_LIMIT
        INTO V_ATM_USAGELIMIT,
            V_POS_USAGELIMIT,
            V_BUSINESS_DATE_TRAN,
            V_PREAUTH_USAGE_LIMIT,
            V_MMPOS_USAGELIMIT
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
        V_ERR_MSG  := 'Error while selecting 1 CMS_TRANSLIMIT_CHECK' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN
       IF P_DELIVERY_CHANNEL = '01' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          V_ATM_USAGEAMNT  := 0;
          V_ATM_USAGELIMIT := 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_ATMUSAGE_AMT       = V_ATM_USAGEAMNT,
                 CTC_ATMUSAGE_LIMIT     = V_ATM_USAGELIMIT,
                 CTC_POSUSAGE_AMT       = 0,
                 CTC_POSUSAGE_LIMIT     = 0,
                 CTC_PREAUTHUSAGE_LIMIT = 0,
                 CTC_MMPOSUSAGE_AMT     = 0,
                 CTC_MMPOSUSAGE_LIMIT   = 0,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss')
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 7 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 7 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 8 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 8 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;

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
                 CTC_MMPOSUSAGE_AMT     = 0,
                 CTC_MMPOSUSAGE_LIMIT   = 0,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss'),
                 CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 9 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 9 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
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

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 10 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 10 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;

       --Sn Usage limit updation for MMPOS
       IF P_DELIVERY_CHANNEL = '04' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          V_MMPOS_USAGEAMNT  := 0;
          V_MMPOS_USAGELIMIT := 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_POSUSAGE_AMT       = 0,
                 CTC_POSUSAGE_LIMIT     = 0,
                 CTC_ATMUSAGE_AMT       = 0,
                 CTC_ATMUSAGE_LIMIT     = 0,
                 CTC_MMPOSUSAGE_AMT     = V_MMPOS_USAGEAMNT,
                 CTC_MMPOSUSAGE_LIMIT   = V_MMPOS_USAGELIMIT,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss'),
                 CTC_PREAUTHUSAGE_LIMIT = 0
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 11 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 11 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 12 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 12 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;
       --En Usage limit updation for MMPOS

     END;*/

     --Sn select response code and insert record into txn log dtl
     BEGIN
       IF v_delayed_amount>0 AND v_resp_cde='15' THEN
            v_resp_cde:='1000';
       END IF;
       P_RESP_CODE := V_RESP_CDE;
       P_RESP_MSG  := V_ERR_MSG;
       p_resp_id   := V_RESP_CDE; --Added for VMS-8018
       -- Assign the response code to the out parameter
       SELECT CMS_B24_RESPCDE, --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
              cms_iso_respcde             -- Added for OLS changes
        INTO P_RESP_CODE,
           --v_cms_iso_respcde           -- Added for OLS changes--Commented and modified  on 17.07.2013 for the Mantis ID 11612
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
        p_resp_id   := '69'; --Added for VMS-8018
        ---ISO MESSAGE FOR DATABASE ERROR Server Declined
        ROLLBACK;
     END;

     --Sn Commented for Transactionlog Functional Removal
     /*BEGIN
       IF V_RRN_COUNT > 0 THEN
        IF TO_NUMBER(P_DELIVERY_CHANNEL) = 8 THEN
          BEGIN
            SELECT RESPONSE_CODE
             INTO V_RESP_CDE
             FROM TRANSACTIONLOG A,
                 (SELECT MIN(ADD_INS_DATE) MINDATE
                    FROM TRANSACTIONLOG
                   WHERE RRN = P_RRN) B
            WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN;

            P_RESP_CODE := V_RESP_CDE;

            SELECT ACCT_BALANCE
             INTO V_ACCT_BALANCE
             FROM TRANSACTIONLOG
            WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
                 ROWNUM = 1;

            V_ERR_MSG := TO_CHAR(V_ACCT_BALANCE);

          EXCEPTION
            WHEN OTHERS THEN

             V_ERR_MSG   := 'Problem in selecting the response detail of Original transaction' ||
                         SUBSTR(SQLERRM, 1, 300);
             P_RESP_CODE := '89'; -- Server Declined
             ROLLBACK;
             RETURN;
          END;

        END IF;
       END IF;
     END;*/
     --En Commented for Transactionlog Functional Removal

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
         CTD_INTERNATION_IND_RESPONSE,
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         CTD_NETWORK_ID,
         CTD_INTERCHANGE_FEEAMT,
         CTD_MERCHANT_ZIP,
         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         ctd_ins_user,      -- Added for OLS changes
         ctd_ins_date       -- Added for OLS changes
         ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
         CTD_CARDVERIFICATION_RESULT
         ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE,CTD_HASHKEY_ID
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
         P_INTERNATIONAL_IND,
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         P_NETWORK_ID,
         P_INTERCHANGE_FEEAMT,
         P_MERCHANT_ZIP,
         /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         1, -- Added for OLS changes
         sysdate -- Added for OLS changes
         ,P_PULSE_TRANSACTIONID,
        P_VISA_TRANSACTIONID,
        P_MC_TRACEID ,
       P_CARDVERIFICATION_RESULT
       ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE,V_HASHKEY_ID
         );

       P_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        p_resp_id   := '69'; --Added for VMS-8018
        ROLLBACK;
        RETURN;
     END;

     -----------------------------------------------
       --SN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------

     if V_PROD_CODE is null
     then

         BEGIN

             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
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
              WHERE CTM_TRAN_CODE = P_TXN_CODE
              AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
              AND   CTM_INST_CODE = P_INST_CODE;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;

     -----------------------------------------------
     --EN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------
 
   begin
    
       if P_ISO_RESPCDE in ('L49','L50') and P_TXN_CODE in ('25')  then
       IF v_badcredit_flag = 'Y'
         THEN
             
            EXECUTE IMMEDIATE    'SELECT  count(*)
              FROM vms_group_tran_detl
              WHERE vgd_group_id ='
                              || v_badcredit_transgrpid
                              || '
              AND vgd_tran_detl LIKE
              (''%'
                              || p_delivery_channel
                              || ':'
                              || p_txn_code
                              || '%'')'
                         INTO v_cnt;
                         
            IF v_cnt = 1
            THEN
                 
               v_enable_flag := 'N';
               IF    ((V_UPD_AMT) > v_initialload_amt
                     )                                     --initialloadamount
                  OR ((V_UPD_LEDGER_AMT) > v_initialload_amt
                     )
               THEN 
                
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = p_inst_code
                     AND cap_pan_code = v_hash_pan;
                  BEGIN
         sp_log_cardstat_chnge (p_inst_code,
                                v_hash_pan,
                                v_encr_pan,
                                V_AUTH_ID,
                                '10',
                                p_rrn,
                                p_tran_date,
                                p_tran_time,
                                v_resp_cde,
                                P_RESP_MSG
                               );
         IF v_resp_cde <> '00' AND P_RESP_MSG <> 'OK'
         THEN
             
              v_resp_cde := '21';
            v_err_msg :=
                  'Error while logging system initiated card status change '
               || SUBSTR (SQLERRM, 1, 200);
         END IF;
     
           
            
      END;
               END IF;
            END IF;
         END IF;
     
     
     end if;
    
    end;
  

  WHEN OTHERS THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;

     BEGIN                                                  --SN: Added on 17-Apr-2013 for defect 10871
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
              cam_type_code
        INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_ACCT_NUMBER,
             v_cam_type_code
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =V_ACCT_NUMBER--Modified by saravanakumar on 16-Sep-2014
            /*(SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_INST_CODE = P_INST_CODE)*/ AND
            CAM_INST_CODE = P_INST_CODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;
     END;                                                   --EN: Added on 17-Apr-2013 for defect 10871

    --Commended by saravanakumar on 16-Sep-2014
     /*BEGIN
       SELECT CTC_ATMUSAGE_LIMIT,
            CTC_POSUSAGE_LIMIT,
            CTC_BUSINESS_DATE,
            CTC_PREAUTHUSAGE_LIMIT,
            CTC_MMPOSUSAGE_LIMIT
        INTO V_ATM_USAGELIMIT,
            V_POS_USAGELIMIT,
            V_BUSINESS_DATE_TRAN,
            V_PREAUTH_USAGE_LIMIT,
            V_MMPOS_USAGELIMIT
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
        V_ERR_MSG  := 'Error while selecting 2 CMS_TRANSLIMIT_CHECK ' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN
       IF P_DELIVERY_CHANNEL = '01' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          V_ATM_USAGEAMNT  := 0;
          V_ATM_USAGELIMIT := 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_ATMUSAGE_AMT       = V_ATM_USAGEAMNT,
                 CTC_ATMUSAGE_LIMIT     = V_ATM_USAGELIMIT,
                 CTC_POSUSAGE_AMT       = 0,
                 CTC_POSUSAGE_LIMIT     = 0,
                 CTC_PREAUTHUSAGE_LIMIT = 0,
                 CTC_MMPOSUSAGE_AMT     = 0,
                 CTC_MMPOSUSAGE_LIMIT   = 0,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss')
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 13 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 13 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 14 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 14 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;

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
                 CTC_MMPOSUSAGE_AMT     = 0,
                 CTC_MMPOSUSAGE_LIMIT   = 0,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss'),
                 CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 15 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 15 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
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

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 16 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 16 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;

       --Sn Usage limit updation for MMPOS
       IF P_DELIVERY_CHANNEL = '04' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
          V_MMPOS_USAGEAMNT  := 0;
          V_MMPOS_USAGELIMIT := 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_POSUSAGE_AMT       = 0,
                 CTC_POSUSAGE_LIMIT     = 0,
                 CTC_ATMUSAGE_AMT       = 0,
                 CTC_ATMUSAGE_LIMIT     = 0,
                 CTC_MMPOSUSAGE_AMT     = V_MMPOS_USAGEAMNT,
                 CTC_MMPOSUSAGE_LIMIT   = V_MMPOS_USAGELIMIT,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss'),
                 CTC_PREAUTHUSAGE_LIMIT = 0
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 17 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 17 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
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

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'Error while updating 18 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 18 CMS_TRANSLIMIT_CHECK ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;
       --En Usage limit updation for MMPOS

     END;*/

     --Sn select response code and insert record into txn log dtl
     BEGIN
       SELECT CMS_B24_RESPCDE, --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
              cms_iso_respcde       -- Added for OLD changes
        INTO P_RESP_CODE,
           --v_cms_iso_respcde      -- Added for OLD changes --Commented and modified  on 17.07.2013 for the Mantis ID 11612
             P_ISO_RESPCDE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INST_CODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;

       P_RESP_MSG := V_ERR_MSG;
       p_resp_id  := V_RESP_CDE; --Added for VMS-8018
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        p_resp_id   := '69'; --Added for VMS-8018
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
         CTD_INTERNATION_IND_RESPONSE,
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         CTD_NETWORK_ID,
         CTD_INTERCHANGE_FEEAMT,
         CTD_MERCHANT_ZIP,
         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         ctd_ins_user,  --Added for OLS changes
         ctd_ins_date   --Added for OLS changes
         ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
         CTD_CARDVERIFICATION_RESULT
         ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE,CTD_HASHKEY_ID
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
         P_INTERNATIONAL_IND,
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         P_NETWORK_ID,
         P_INTERCHANGE_FEEAMT,
         P_MERCHANT_ZIP,
         /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         1,
         sysdate
         , P_PULSE_TRANSACTIONID,
        P_VISA_TRANSACTIONID,
        P_MC_TRACEID,
        P_CARDVERIFICATION_RESULT
        ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE,V_HASHKEY_ID
         );
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Decline Response 220509
        p_resp_id   := '69'; --Added for VMS-8018
        ROLLBACK;
        RETURN;
     END;
     --En select response code and insert record into txn log dtl

     -----------------------------------------------
     --SN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------

     if v_prod_code is null
     then

         BEGIN

             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
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
              WHERE CTM_TRAN_CODE = P_TXN_CODE
              AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
              AND   CTM_INST_CODE = P_INST_CODE;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;

     -----------------------------------------------
     --EN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------


  END;

  --- Sn create GL ENTRIES

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
      PROXY_NUMBER,
      REVERSAL_CODE,
      CUSTOMER_ACCT_NO,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      INTERNATION_IND_RESPONSE,
      RESPONSE_ID,
      /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      NETWORK_ID,
      INTERCHANGE_FEEAMT,
      MERCHANT_ZIP,
      /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      FEE_PLAN,
      POS_VERIFICATION, --Added by Deepa on July 03 2012 to log the verification of POS
      FEEATTACHTYPE, -- Added by Trivikram on 05-Sep-2012
         MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      ERROR_MSG,       -- Added by sagar on 06-Feb-2013,same was missing
      ACCT_TYPE,        -- Added on 17-Apr-2013 for defect 10871
      TIME_STAMP,       -- Added on 17-Apr-2013 for defect 10871
      CARDSTATUS,        -- Added on 17-Apr-2013 for defect 10871
      add_ins_user,     -- Added for OLS changes
      ADDL_AMNT ,          -- Added for OLS additional amount Changes
      NETWORKID_SWITCH, --Added on 20130626 for the Mantis ID 11344
      NETWORKID_ACQUIRER, --Added on 20130626 for the Mantis ID 11344
      NETWORK_SETTL_DATE, --Added on 20130626 for the Mantis ID 11123
      CVV_VERIFICATIONTYPE,  --Added on 17.07.2013 for the Mantis ID 11611
      partial_preauth_ind  --Added by DHINAKARAN B on 23.09.2013 for FSS-1313
      ,addr_verify_response ,
      addr_verify_indicator
      ,merchant_id,
      remark, --Added for error msg need to display in CSR(declined by rule)
      surchargefee_ind_ptc	--Added for VMS-5856
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
      --DECODE(P_RESP_CODE, '00', 'C', 'F'),        -- Commented for OLS changes
      --DECODE (v_cms_iso_respcde, '00', 'C', 'F'),   -- Added for OLS changes
      DECODE (P_ISO_RESPCDE , '00', 'C', 'F'),  --Commented and modified  on 17.07.2013 for the Mantis ID 11612
      --P_RESP_CODE,                                -- Commented for OLS changes
      --v_cms_iso_respcde,           -- Added for OLS changes --Commented and modified  on 17.07.2013 for the Mantis ID 11612
      P_ISO_RESPCDE ,
      P_TRAN_DATE,
      P_TRAN_TIME,
      V_HASH_PAN,
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_BANK_CODE,
      TRIM(TO_CHAR(NVL(V_TOTAL_AMT,0), '99999999999999990.99')), -- NVL added on 17-Apr-2013 for defect 10871
      NULL,
      NULL,
      P_MCC_CODE,
      P_CURR_CODE,
      NULL, -- P_add_charge,
      V_PROD_CODE,
      V_PROD_CATTYPE,
      nvl(P_TIP_AMT,0),     --nvl Added on 10-Dec-2013 for 13160
      P_DECLINE_RULEID,
      P_ATMNAME_LOC,
      V_AUTH_ID,
      V_TRANS_DESC,
      TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '99999999999999990.99')), -- NVL added on 17-Apr-2013 for defect 10871
      P_MERCHANT_CNTRYCODE, -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
      '0.00', -- Partial amount (will be given for partial txn) -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
      P_MCCCODE_GROUPID,
      P_CURRCODE_GROUPID,
      P_TRANSCODE_GROUPID,
      P_RULES,
      P_PREAUTH_DATE,
      V_GL_UPD_FLAG,
      P_STAN,
      P_INST_CODE,
      V_FEE_CODE,
      NVL(V_FEE_AMT,0),             -- NVL added on 17-Apr-2013 for defect 10871
      NVL(V_SERVICETAX_AMOUNT,0),   -- NVL added on 17-Apr-2013 for defect 10871
      NVL(V_CESS_AMOUNT,0),         -- NVL added on 17-Apr-2013 for defect 10871
      V_DR_CR_FLAG,
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
      V_PROXUNUMBER,
      P_RVSL_CODE,
      V_ACCT_NUMBER,
      DECODE(P_RESP_CODE, '00',nvl(V_UPD_AMT,0),nvl(V_ACCT_BALANCE,0)),      -- to_char(nvl)) added on 17-Apr-2013 for defect 10871
      DECODE(P_RESP_CODE, '00',nvl(V_UPD_LEDGER_AMT,0),nvl(V_LEDGER_BAL,0)), -- to_char(nvl)) added on 17-Apr-2013 for defect 10871
      P_INTERNATIONAL_IND,
      V_RESP_CDE,
      /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      P_NETWORK_ID,
      nvl(P_INTERCHANGE_FEEAMT,0),      --NVL added on 10-Dec-2013 for 13160
      P_MERCHANT_ZIP,
      /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      V_FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
      P_POS_VERFICATION, --Added by Deepa on July 03 2012 to log the verification of POS
      V_FEEATTACH_TYPE, -- Added by Trivikram on 05-Sep-2012
      P_MERCHANT_NAME,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_ATMNAME_LOC, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      V_ERR_MSG,      -- Added by sagar on 06-Feb-2013,same was missing
      v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
      v_timestamp,       -- Added on 17-Apr-2013 for defect 10871
      v_applpan_cardstat, -- Added on 17-Apr-2013 for defect 10871
      1,                  -- Added for OLS changes
      P_ADDL_AMT,       -- Added for OLS additional amount Changes
      P_NETWORKID_SWITCH , --Added on 20130626 for the Mantis ID 11344
      P_NETWORKID_ACQUIRER,-- Added on 20130626 for the Mantis ID 11344
      p_network_setl_date , --Added on 20130626 for the Mantis ID 11123
      NVL(P_CVV_VERIFICATIONTYPE,'N'),  --Added on 17.07.2013 for the Mantis ID 11611
     p_partial_preauth_ind     --Added by DHINAKARAN B on 23.09.2013 for FSS-1313
     ,P_ADDR_VERFY_RESPONSE,
     P_ADDRVERIFY_FLAG
     ,P_MERCHANT_ID,
     DECODE(v_resp_cde,'1000','Decline due to redemption delay',V_ERR_MSG), --Added for error msg need to display in CSR(declined by rule)
     DECODE(p_surchrg_ind,'2',NULL,p_surchrg_ind) --Added for VMS-5856
      );

    --DBMS_OUTPUT.PUT_LINE('AFTER INSERT IN TRANSACTIONLOG');
    P_AUTH_ID := V_AUTH_ID;
  EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK;
     P_RESP_CODE := '69'; -- Server Declione
     P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                 SUBSTR(SQLERRM, 1, 300);
     p_resp_id   := '69'; --Added for VMS-8018
  END;
  --En create a entry in txn log

      --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

     P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 4: ' || v_mili ;
     P_RESP_TIME := v_mili;
     --EN Added by Pankaj S. for DB time logging changes

 /* IF P_TXN_CODE = '04' AND P_DELIVERY_CHANNEL = '07' AND
    V_MINI_STAT_RES IS NOT NULL THEN
    P_RESP_MSG := V_MINI_STAT_RES;
  ELSIF P_RESP_MSG = 'OK' THEN */
  IF P_RESP_MSG = 'OK' THEN
    P_RESP_MSG   := TO_CHAR(V_UPD_AMT); --added for response data
    P_LEDGER_BAL := TO_CHAR(V_UPD_LEDGER_AMT); -- ADDED FOR LEDGER BALANCE FOR mPAY BALANCE ENQUIRY REQUEST.
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    P_RESP_CODE := '69'; -- Server Declined
    P_RESP_MSG  := 'Main exception from  authorization ' ||
                SUBSTR(SQLERRM, 1, 300);
    p_resp_id   := '69'; --Added for VMS-8018
END;
/
Show error